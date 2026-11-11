/* =====================================================================
 * 避障 module --- verbatim extract from firmware/c51/main.c
 * source main.c SHA256 : D98AB440752B74495C3DBE649BA61DB4651678B3AADA59D3CE4F7BC82F72C47B
 * source main.hex SHA256: D5C645AF664310A294E2B977421DD62ECE95536482E6D0DBC7759831C83DB251   code = 3504 B
 * every line below is copied as-is; "L###-###" = line numbers in main.c
 * NOT a compilation unit --- for reading / acceptance only
 * ===================================================================== */

/* ---- L68-90  AV_SCOPE / AV_L1 (avoidance grade switch) --------------------- */
/* 超声波自测版：只反复运行本文件里的 us_read()，把结果直接显示在数码管
 * 上，用来分清到底是测距本身不行，还是避障逻辑没用上。 */
#ifndef AV_SCOPE
#define AV_SCOPE    0
#endif

/* 松键停车：1 = 除了前进以外，松手约 0.3s 自动停；
 * 0 = 全部改成按一下就一直动。
 * 如果按住遥控键时小车一颠一颠的，说明这只遥控器不发重复帧，
 * 把这里改成 0 重新编译即可。 */
#define HOLD_MODE   1

/* 避障分级（L1 方案；本轮改动编号 C17（避障分级：弧线档 + 决策保持））：
 * 1 = 12~21cm 走弧线右绕、5~12cm 才原地右转，
 * 而且一次避让决定至少管 280ms 再重判，不拿同一份旧读数每趟改动作；
 * 0 = 退回原来的行为（5~21cm 一律原地右转、每趟主循环都重判）。
 * 这个开关只影响这一处：设成 0 重编，得到的应当是逐字节相同的旧 hex。
 * 新增开销：RAM 0 字节（计时复用 av_clear_t）、code 约 70 字节。
 * 实施与验收见 docs\正式固件开发记录.md 的 §C17（避障分级）一节。
 * 用 #ifndef 包起来是为了能在编译命令行里临时关掉，不用翻源码改。 */
#ifndef AV_L1
#define AV_L1       1
#endif

/* ---- L147-161  timing thresholds --------------------------------------------- */
#define AVBEEP_TICKS   6912     /* 刹停锁存期间间歇响的间隔 27×256 ≈ 0.69s */
#define AV_DEC_TICKS   2800     /* 避障分级：一次避让决定至少保持 2800 tick ≈ 280ms 才重判 */
/* 锁存的提醒音只响 AVBEEP_N 声就安静下来（含刹停那一声）。
 * 车还是照旧停着等遥控操作，只是不一直响了。
 * 想恢复成一直响到有人接管，把这个值改大即可。 */
#define AVBEEP_N       3
/* 障碍要持续退到 US_CLEAR 之外这么久，才算真的让开了。
 * 加这段是因为超声波贴得很近时读数会抖：一会儿读到很近，一会儿读不到
 * 回波，锁存会被反复重立，听起来就像过一会儿又响一声。 */
#define AV_CLEAR_TICKS 5000

/* 车头红外这一路的提示音是否静音（刹车功能保留）。
 * 1 = 静音（当前用这个）；0 = 也让红外这一路参与锁存提醒。
 * 注意这只影响声音，红外刹车仍然是全局的、关不掉的。 */
#define IR_BEEP_SILENT 1

/* ---- L206-216  AV_* gate states + distance thresholds ------------------------ */
#define AV_FREE       0         /* 放行：无障碍 */
#define AV_TURN       1         /* 近区：动作一律改写成"原地右转避让" */
#define AV_HOLD       2         /* 太近：刹停 + 锁存，车不动，决定权交给遥控 */
#define AV_HUMAN      3         /* 遥控已接管：完全放行；距离回到安全值后自动回 AV_FREE */
#define AV_ARC        4         /* 中区：动作改写成"弧线右绕"，车不停、保留前进分量 */

/* 超声波门限（1 tick ≈ 1.72cm：回波高电平 ≈ 58.3us/cm） */
#define US_NEAR       12        /* 12 tick ≈ 21cm：更近 -> 转向避让 */
#define US_STOP       3         /* 3 tick ≈ 5cm：更近 -> 刹停锁存 */
#define US_CLEAR      7         /* 7 tick ≈ 12cm：退到这儿才停止间歇响（滞回，防止抖动） */
#define AV_SPIN       7         /* 7 tick ≈ 12cm：比这更近就从弧线降级为原地右转 */

/* ---- L248-256  KEY_AVOID (remote digit 5) ------------------------------------ */
#define KEY_M1        0x0C      /* 数字键 1 -> 手动 */
#define KEY_M2        0x18      /* 数字键 2 -> 寻光 */
#define KEY_M3        0x5E      /* 数字键 3 -> 循迹 */
/* 数字键 5：超声波避障开关，和长按 S4 是一个功能（遥控上够得着，
 * 用起来方便）。它只管超声波，车头红外是全局的，这个键关不掉。
 * 遥控没电时还可以长按 S4 开关，两条路都在。 */
#define KEY_AVOID     0x1C      /* 数字键 5 -> 超声波避障开/关 */
#define KEY_REC       0x42      /* 数字键 7 -> 录制开/关 */
#define KEY_PLAY      0x52      /* 数字键 8 -> 回放 */

/* ---- L306-321  duty_tab / arc_tab (speed ladder used by avoidance) ----------- */
    DISP_0, DISP_1, DISP_2, DISP_3, DISP_4, DISP_5
};

static const unsigned char code duty_tab[5] = {     /* 档位 1..5 -> PWM 档 0..20 */
    8, 11, 14, 17, 20                                /* 40/55/70/85/100%（原 20% 的 1 挡太慢，已去掉，
                                                      * 整条速度梯整体上移，顶档仍是 100% = 最高速）*/
};

/* 弧线转弯时内轮的占空比（外轮还是按 duty_tab 给）。
 * 内轮和外轮差别越小，转弯半径越大；内轮越小，弯越急。
 * 现在取的是外轮的 12%~20%（duty_tab 整体上移后比例比原先略小，
 * 弧线弯更急一点）；之前取 40% 时感觉转弯太慢，就调小了。 */
static const unsigned char code arc_tab[5] = { 1, 2, 2, 3, 4 };

static const unsigned char code mode_tab[4] = {     /* 索引 = 模式号 */
    DISP_0, DISP_L, DISP_T, DISP_P                   /* 0 手动 / 1 寻光 / 2 循迹 / 3 回放 */

/* ---- L412-422  state variables ----------------------------------------------- */
static unsigned int  last_err;              /* 上次打印"帧被拒"的时刻（限流） */
static bit ir_short;                        /* 1 = 本次引导码高电平是"短的"（1.2~2.5ms，待定） */
static unsigned char ir_inv;                /* 车头红外极性：0 = 低电平表示检测到 */
static bit us_avoid_on;                     /* 超声波避障开关，上电默认打开。
                                             * 它只管超声波；车头红外是全局的，关不掉。 */
static unsigned char avst;                  /* 避障闸门状态 AV_* */
static unsigned int  av_beep_t;             /* 上次"刹停提示音"的时刻 */
static unsigned char av_beep_n;             /* 本次锁存已经响了几声（到 AVBEEP_N 就安静）*/
static bit av_clear_on;                     /* 是否已开始计"障碍退远"的时间 */
/* av_clear_t —— 避障用的共用计时器（一个变量两种用途，两边互斥）：
 *   · 刹停锁存期间（avst == AV_HOLD）：记"障碍开始退远"的时刻，

/* ---- L486-496  forward declarations ------------------------------------------ */
static void          track_step(void);

static void          us_init(void);
static void          us_trigger(void);
static unsigned char us_read(void);
static bit           ir_det(void);
static void          av_gate(void);
static void          av_gate_hold(void);
static void          ir_brake(void);
static void          avoid_toggle(void);


/* ---- L808-869  motor_set_core() --- execution layer: rewrite action / brake --- */
static void motor_set_core(unsigned char act, unsigned char g)
{
    if (g == 0) {                           /* 速度 0 -> 停（本来就没让动，闸门不用管）*/
        dirbits = DIR_STOP;
        duty_a = 0;
        duty_b = 0;
        return;
    }

    /* ---- 避障闸门：按状态决定要不要改写动作 ---- */
#if AV_L1
    if (avst == AV_ARC) {
        act = ACT_ARC_R;                    /* 中区：弧线右绕，车继续走、不丢前进分量 */
    } else
#endif
    if (avst == AV_TURN) {
        act = ACT_RIGHT;                    /* 近区：一律改写成原地右转绕开 */
    } else if (avst == AV_HOLD) {           /* 太近：强制刹停（锁存，等遥控决定）*/
        cur_act = ACT_STOP;                 /* 真的停车了，当前动作也要清掉，
                                             * 否则寻光和循迹每趟都会把动作码设回来，
                                             * 车虽然不动，指示灯却还亮着 */
        dirbits = DIR_STOP;
        duty_a = 0;
        duty_b = 0;
        return;
    }
    /* AV_FREE / AV_HUMAN -> 放行，按原动作走 */

    /* ---- 倒车限速（放在闸门之后，按最终动作判断）----
     * 数码管显示的还是用户设的档位，这里只把实际出力封顶。 */
    if (act == ACT_BACK && g > BACK_GEAR_MAX)
        g = BACK_GEAR_MAX;

    duty_a = duty_tab[g - 1];               /* 1..5 -> 40/55/70/85/100% */
    duty_b = duty_a;                        /* 默认两轮同速 */

    /* ---- 弧线转弯：两个轮子都正转，只把内轮的占空比调小 ----
     * 左轮的占空比是 duty_a，右轮是 duty_b；
     * 方向位用前进，而不是原地转的那两个方向。 */
    if (act == ACT_ARC_L) {
        duty_a = arc_tab[g - 1];            /* 左弧线：内轮 = 左轮 */
        dirbits = DIR_FWD;
        return;
    }
    if (act == ACT_ARC_R) {
        duty_b = arc_tab[g - 1];            /* 右弧线：内轮 = 右轮 */
        dirbits = DIR_FWD;
        return;
    }

    switch (act) {
    case ACT_FORWARD: dirbits = DIR_FWD;   break;
    case ACT_BACK:    dirbits = DIR_BACK;  break;
    case ACT_LEFT:    dirbits = DIR_LEFT;  break;
    case ACT_RIGHT:   dirbits = DIR_RIGHT; break;
    default:                                /* ACT_STOP 及任何意外值都当停车 */
        dirbits = DIR_STOP;
        duty_a = 0;
        duty_b = 0;
        break;
    }
}

/* ---- L883-910  motor_set() debug wrapper (only -Debug) ----------------------- */
#if DEBUG_UART
static unsigned char ms_p_act, ms_p_dir, ms_p_a, ms_p_b;
static bit           ms_p_seen;

static void ms_dbg(void)
{
    if (ms_p_seen && ms_p_act == cur_act && ms_p_dir == dirbits &&
        ms_p_a == duty_a && ms_p_b == duty_b)
        return;
    ms_p_seen = 1;
    ms_p_act  = cur_act;
    ms_p_dir  = dirbits;
    ms_p_a    = duty_a;
    ms_p_b    = duty_b;
    prt_str("\r\n! MS act="); prt_hex(cur_act);
    prt_str(" dir=");         prt_hex(dirbits);
    prt_str(" A=");           prt_hex(duty_a);
    prt_str(" B=");           prt_hex(duty_b);
}

static void motor_set(unsigned char act, unsigned char g)
{
    motor_set_core(act, g);
    ms_dbg();
}
#else
#define motor_set(act, g)       motor_set_core((act), (g))
#endif

/* ---- L928-935  avoid_off() --------------------------------------------------- */
static bit avoid_off(void)
{
    if (recon)
        return 1;                           /* 录制中 -> 超声波这一路不参与 */
    if (us_avoid_on)
        return 0;
    return 1;                               /* 用户把开关关了 */
}

/* ---- L943-953  apply_gear_core() --- no upshift while latched ---------------- */
static void apply_gear_core(void)
{
    if (gear == 0)
        goto stop;

    /* 刹停锁存期间，本地加档也不许把车开起来 —— 锁存的意思是"决定权在遥控手里" */
    if (avst == AV_HOLD)
        goto stop;

    /* 这里必须同时把 cur_act 也设上：避障用 cur_act 判断车本来在不在动，
     * 如果车在走而 cur_act 是 0，避障会以为车停着，就不躲了。 */

/* ---- L1243-1272  us_read() --- ultrasonic distance ----------------------------- */
static unsigned char us_read(void)
{
    unsigned char t10 = ms10_l;             /* 10ms 计数（8 位够：60ms 内不会绕回）*/

    /* ---- 1) 中断刚量完，先把结果取走 ----
     * 取结果和清标志一起做（中间关一下中断），免得出现取了值没清标志，
     * 或者清了标志没取值的半截情况。 */
    if (us_got) {
        ET0 = 0;
        us_last_d = us_res;
        us_got    = 0;
        us_valid  = 1;
        ET0 = 1;
    }

    /* ---- 2) 正在测：先把上次的结果给出去，绝不在这里等 ---- */
    if (us_st != US_ST_IDLE)
        return us_valid ? us_last_d : US_FAR;

    /* ---- 3) 两次测距之间要留间隔，间隔不够就沿用上次的结果 ----
     * 触发太密模块会不响应，那样每次都白等一回，车看起来就像不动。 */
    if (us_seen && (unsigned char)(t10 - us_last10) < US_GAP_MS10)
        return us_valid ? us_last_d : US_FAR;

    /* ---- 4) 空闲且够久：发一次触发，然后立刻返回 ---- */
    us_last10 = t10;
    us_seen   = 1;
    us_trigger();
    return us_valid ? us_last_d : US_FAR;   /* 本次不给新值，等下一次来取 */
}

/* ---- L1282-1290  ir_det() --- front IR pair ------------------------------------ */
static bit ir_det(void)
{
    if (ir_inv) {                           /* 1 = 高电平表示检测到 */
        if (IR_AVOID) return 1;
        return 0;
    }
    if (IR_AVOID) return 0;                 /* 0 = 低电平表示检测到 */
    return 1;
}

/* ---- L1325-1340  ir_brake() --- IR touch: brake + latch ------------------------ */
static void ir_brake(void)
{
    if (avst == AV_HUMAN)
        return;                             /* 遥控已接管 -> 放行，别再压住*/

    avst = AV_HOLD;                         /* 锁存：决定权交回遥控 */
    cur_act = ACT_STOP;
    motor_set(ACT_STOP, 0);
    show_mode();                            /* 这里用 show_mode，循迹时能保住显示的模式代号 */
    av_beep_t = tick_get();                 /* 之后由 av_gate 按间隔继续响（若允许）*/
    av_beep_n = 0;                          /* 本次锁存的已响次数从 0 起算 */
#if !IR_BEEP_SILENT
    av_beep_n = 1;                          /* 入口这一声也算一次 */
    beep(BEEP_KEY);                         /* 静音时不出这一声 */
#endif
}

/* ---- L1348-1380  av_gate_hold() --- ultrasonic too close ----------------------- */
static void av_gate_hold(void)
{
    if (avst == AV_HUMAN)
        return;                             /* 遥控已接管，不再反复刹停 */

    if (mode == MODE_LIGHT) {
        /* 寻光是自动跑的模式，离得太近时应该把控制权交回给人，而不是原地
         * 锁死等人来按。所以这里不锁存、也不间歇响。 */
        mode = MODE_MANUAL;
        avst = AV_HUMAN;
        cur_act = ACT_STOP;
        motor_set(ACT_STOP, 0);
        show_mode();
        beep(BEEP_KEY);                     /* 寻光：退回手动，响一声*/
        return;
    }

    /* ---- 手动：刹停 + 锁存 ---- */
    avst = AV_HOLD;
    cur_act = ACT_STOP;
    motor_set(ACT_STOP, 0);
    show_mode();

    av_beep_t = tick_get();                 /* 之后由 av_gate 按间隔继续响 */
    /* 声音只在“新一次遇到障碍”的时候响。读数抖动会让锁存反复解除又重立，
     * 每次都响的话听起来就是隔一会儿又响一声。
     * 计数只在障碍真的退远以后才清零。 */
    if (av_beep_n == 0) {
        av_beep_n = 1;                      /* 这声算第 1 声 */
        beepwhy('H');                       /* 诊断：刹停入口那一声 */
        beep(BEEP_KEY);                     /* 响一声：手动 = 刹停锁存 */
    }
}

/* ---- L1392-1557  av_gate() --- main avoidance decision ------------------------- */
static void av_gate(void)
{
    unsigned char d;

#if DEBUG_UART
    {
        unsigned char ir = ir_det() ? 1 : 0;
        if (!av_dbg_seen || ir != av_dbg_ir || avst != av_dbg_st ||
            (avoid_off() ? 0 : 1) != av_dbg_of || mode != av_dbg_md ||
            (unsigned int)(tick_get() - av_dbg_t) >= 5000) {    /* 5000 tick ≈ 0.5s */
            av_dbg_t  = tick_get();
            av_dbg_seen = 1;
            av_dbg_ir = ir;
            av_dbg_st = avst;
            av_dbg_of = avoid_off() ? 0 : 1;
            av_dbg_md = mode;
            prt_str("\r\n! IR="); put_char((char)('0' + ir));
            prt_str(" AV=");      put_char((char)('0' + avst));
            prt_str(" D=");       prt_hex(av_dbg_d);
            prt_str(" OF=");      put_char((char)('0' + (avoid_off() ? 0 : 1)));
            prt_str(" M=");       put_char((char)('0' + mode));
            prt_str(" T=");       prt_hex4(ms10_get());   /* 开机计时：突然变小 = 复位过 */
        }
    }
#endif

    /* ---- 超声波这一路不参与的时候，要顺手把旧的锁存解开 ----
     * 录制中或者用户关掉了开关时它不参与，但如果状态还停在锁存上，
     * 驱动出口会一直把车按住，表现就是一进录制车就走不动。
     * 车头红外不受影响，紧接着那一步还是会刹停。 */
    if (avoid_off() && avst == AV_HOLD)
        avst = AV_FREE;

    /* ---- 锁存状态要放在最前面判断 ----
     * 否则每趟都调用一次刹车，会变成连续鸣叫，而不是隔一会儿响一声。
     * 锁存期间这里只管要不要继续响。 */
    if (avst == AV_HOLD) {
#if IR_BEEP_SILENT
        if (ir_det())
            return;                         /* 红外贴着就静音 */
#endif
        /* ---- 到这里说明车头红外没有贴着 ---- */

        /* ---- ★ 循迹模式：前方空了就自动解锁 ----
         *   锁存本来是为"手动模式下车停住、等遥控来接管"设计的；而循迹是
         *   无人干预的自动模式，没人会来按键。原来循迹走到这里也是直接
         *   return，于是**车头红外只要有一瞬间误触发，就把车永久钉死**，
         *   表现正是"循迹跑一段就自己停下、数码管还显示 t、怎么都不动"。
         *   参考工程（`巡线ok`）在巡线期间**根本不看 P3.7**；这里取其中间
         *   路线：贴着就刹（保住车头红外这道保命闸门），一离开就放行。 */
        if (mode == MODE_TRACK) {
            avst = AV_FREE;
            return;
        }

        /* ① 超声波不参与的情形 -> 没有该响的理由 */
        if (avoid_off())
            return;

        /* ② 障碍退远了：要持续一段时间才算真的让开（防止读数抖动） */
        if (us_read() >= US_CLEAR) {
            if (!av_clear_on) {             /* 刚开始"退远"计时 */
                av_clear_on = 1;
                av_clear_t = tick_get();
                return;
            }
            if ((unsigned int)(tick_get() - av_clear_t) >= AV_CLEAR_TICKS)
                av_beep_n = 0;              /* 真走了 -> 下次再靠近才会重新提醒 */
            return;                         /* 退到安全距离 -> 静音 */
        }
        av_clear_on = 0;                    /* 又近了 -> 撤销"已退远"的计时 */

        /* ③ 提醒音：一次遇到障碍总共响 AVBEEP_N 声（含刹停那一声） */
        if (av_beep_n >= AVBEEP_N)
            return;                         /* 提醒够了就安静，锁存不变，车还停着等遥控 */
        if ((unsigned int)(tick_get() - av_beep_t) >= AVBEEP_TICKS) {
            av_beep_t = tick_get();
            av_beep_n++;                    /* 记数，响够 AVBEEP_N 声就停 */
            beepwhy('L');                   /* 诊断：锁存期间的间歇提醒 */
            beep(BEEP_KEY);
        }
        return;
    /* 只是不响了，车还停着等遥控操作，锁存没有解除 */
    }

    /* ---- ① 车头红外：全局生效，触发就直接刹车 ----
     * 放在这里、而且在循迹早退之前，这样循迹也受它保护。 */
    if (ir_det()) {
        ir_brake();
        return;
    }

    /* ---- ② 循迹模式不参与超声波避障 ----
     * 要显式把状态清掉，否则它会卡在转向避让上，把循迹的每个动作都改成
     * 原地右转，车就一直打转。
     * 循迹并不是没有避障，它还有车头红外刹车这一道。 */
    if (mode == MODE_TRACK) {
        avst = AV_FREE;
        return;
    }

    /* ---- 倒车的时候超声波不参与 ----
     * 超声波朝前，倒车时它的读数没有意义：按近区改写会让车倒着倒着突然
     * 原地打转，按太近刹停又会拦住“倒着离开前方障碍”这种正常动作。
     * 倒车的安全交给限速和限时兜底。车头红外在上面已经处理过，照旧生效。 */
    if (cur_act == ACT_BACK) {
        avst = AV_FREE;
        motor_set(ACT_BACK, gear);          /* 把可能残留的"原地右转"改写回来 */
        return;
    }

    /* ---- ③ 超声波：受手动开关控制（长按 S4 或遥控数字键 5）；
     *      录制中一律不参与 ---- */
    if (avoid_off()) {
        avst = AV_FREE;
        if (cur_act != 0) motor_set(cur_act, gear);
        return;
    }

    d = us_read();
#if DEBUG_UART
    av_dbg_d = d;                           /* 诊断：记下这次实测的距离 */
#endif
    if (d < US_STOP) {                      /* 太近（< 5cm）*/
        av_gate_hold();
        return;
    }

#if AV_L1
    /* 决策保持：刚做过的决定要认账，别拿同一份旧读数每趟主循环都改一次动作。
     *   只有"正在避让"（弧线 / 原地转）才需要保持；
     *   本来就在放行（AV_FREE）时，一发现障碍立刻进避让，反应不延迟。
     *   比 US_STOP 更近的那一档在上面就处理掉了（立即刹停锁存），
     *   所以这里保持住的只是"中区还是近区"这个选择，不会拖慢刹车。
     *   计时用的是那个共用计时器 av_clear_t（AV_HOLD 那一支不会走到这里）。 */
    if ((avst == AV_ARC || avst == AV_TURN) &&
        (unsigned int)(tick_get() - av_clear_t) < AV_DEC_TICKS) {
        if (cur_act == 0) return;           /* 本来就没在动 -> 别自己窜出去 */
        motor_set(cur_act, gear);           /* 由驱动出口按 avst 改成弧线 / 原地转 */
        return;
    }

    /* ---- 重新分档：每 AV_DEC_TICKS 才重判一次 ---- */
    av_clear_t = tick_get();                /* 共用计时器：这里当作"上次分档的时刻" */
    if (d < AV_SPIN)
        avst = AV_TURN;                     /* 近区：原地右转避让（急转让开） */
    else if (d < US_NEAR)
        avst = AV_ARC;                      /* 中区：弧线右绕，车不停 */
    else
        avst = AV_FREE;                     /* 已经够远：放行 */
#else
    /* ---- 已经不近了：解除接管状态，避障重新生效 ---- */
    avst = AV_FREE;

    if (d < US_NEAR) {                      /* 近区：原地右转避让 */
        avst = AV_TURN;
        if (cur_act == 0) return;           /* 本来就没在动 -> 别自己窜出去 */
        motor_set(ACT_RIGHT, gear);
        return;
    }
#endif

    /* ---- 距离够远：放行，并把原来的动作重新套上，免得一直右转 ---- */
    if (cur_act == 0) return;
    motor_set(cur_act, gear);
}

/* ---- L1566-1584  avoid_toggle() --- S4 long press / remote 5 ------------------- */
static void avoid_toggle(void)
{
    us_avoid_on = !us_avoid_on;
    beepwhy('T');                           /* 诊断：避障开关被触发 */

    if (us_avoid_on) {
        beep(BEEP_KEY);                     /* 开：两声短响 */
        d_20ms();
        d_20ms();
        beep(BEEP_KEY);
    } else {
        avst = AV_FREE;                     /* 关：解开锁存（理由见上面）*/
        beep(BEEP_TICKS);                   /*     一声长响 */
    }

    /* 立刻刷新一下 D3。车停着的时候没有别的地方写 P2，
     * 不刷的话指示灯会停在旧状态上。 */
    show_mode();
}

/* ---- L1849-1874  do_key() --- any key takes over the latch --------------------- */
    unsigned char tgt, act;

    /* ---- ① 遥控一按，就把决定权交回给人 ----
     * 如果正处在停车锁存状态，就地解除。放在最前面，
     * 所以按任意键都算人来接管。 */
    if (avst == AV_HOLD)
        avst = AV_HUMAN;

    /* ---- ② 三个功能键优先处理，且不再往下走常规流程 ----
     *（不进 key2mode、不进 key2act，所以不会驱动电机，也不会被当成"不认识的键"）*/
    if (ir_ib2 == KEY_REC)  { rec_key();  return; }
    if (ir_ib2 == KEY_CLR)  { clr_key();  return; }
    if (ir_ib2 == KEY_PLAY) { play_key(); return; }

    prt_key();                              /* 打印原始键值（测其余键值就靠这一行）*/

    /* ---- 遥控数字键 5 = 超声波避障开关（和长按 S4 是一个功能）----
     * 放在打印键值之后，这样诊断版能把它打出来，排查“按了没反应”就靠它。
     * 这里不限制录制中不能按：录制记的是人的操作意图，避障开关不进记录。
     * 回放中按它不生效，回放只认停止、方向和回放键。 */
    if (ir_ib2 == KEY_AVOID) {
        avoid_toggle();
        return;
    }

    /* ---- ③ 遥控数字键 1/2/3 直接选模式 ---- */

/* ---- L1945-1976  ir_holdchk() --- hand over / release -------------------------- */
static void ir_holdchk(void)
{
    unsigned int d;

    if (cur_act == ACT_STOP)
        return;                             /* 本来就在停 -> 不用管 */

    if (avst != AV_HUMAN && !recon) {       /* 录制中不做“前进按一下一直走”那一套 */
        if (cur_act == ACT_FORWARD)
            return;                         /* 前进：锁定式，不因松手停车 */
    }

    d = (unsigned int)(tick_get() - lastt);
    if (d < HOLD_TMO_TICKS)
        return;                             /* 还没到 300ms */

    /* 超时了，说明松手了。弧线松手回到前进（前进本来就是按一下一直走），
     * 其它动作松手就停车。 */
    if (!recon && (cur_act == ACT_ARC_L || cur_act == ACT_ARC_R))
        cur_act = ACT_FORWARD;
    else
        cur_act = ACT_STOP;

    motor_set(cur_act, cur_act == ACT_STOP ? 0 : gear);
    show_state();                           /* 显示也要跟着更新，否则 D3 还亮着"在动" */
    lastcmd = LASTCMD_NONE;                 /* 允许同一个键再按一次 */

    if (avst == AV_HUMAN)
        avst = AV_FREE;                     /* 接管只用一次 -> 避障重新武装 */
    prt_release();
}


/* ---- L2024-2079  prox_beep() --- reversing-sensor beep ------------------------- */
static void prox_beep(void)
{
    unsigned int d, wait;

    if (avoid_off() == 0)                   /* 避障在参与 -> 不响（避障自己负责）*/
        return;                             /* 录制中也算不参与，所以提示音照响 */
    if (mode == MODE_PLAY || mode == MODE_TRACK)
        return;

    /* ---- 倒车的时候不响，顺便把状态清掉，免得停车以后又接着响 ---- */
    if (cur_act == ACT_BACK) {
        prox_moving = 0;
        prox_hold = 0;                      /* 倒车不算"停车宽限" */
        return;
    }

    /* ---- 停车以后只再响约 2 秒：停下的瞬间还能听出离墙有多远 ---- */
    if (cur_act == ACT_STOP) {
        if (prox_moving) {                  /* 刚从"动"变成"停"：开始 2s 宽限 */
            prox_moving = 0;
            prox_hold = 1;
            prox_stop_t = tick_get();
        }
        if (prox_hold && (unsigned int)(tick_get() - prox_stop_t) >= PROX_HOLD_TICKS)
            prox_hold = 0;                  /* 宽限到点 -> 永久静音 */
        if (!prox_hold)
            return;                         /* 停稳超过 2s -> 一声都不响 */
    } else {
        prox_moving = 1;
        prox_hold = 0;                      /* 又动了 -> 撤销静音（重新武装）*/
    }

    d = us_read();                          /* 非阻塞；内部已做 ≥60ms 节流 */
    if (d >= US_NEAR)                       /* 够远 / 读不到(US_FAR) -> 不响 */
        return;

    if (d < US_STOP && cur_act != ACT_STOP) {   /* 最近档 且正在动 -> 连续响 */
        beepwhy('P');                       /* 诊断：近距连续响 */
        beep(PROX_SOLID);
        return;
    }

    /* 响的间隔：越近间隔越短。
     * 算间隔用移位，不用乘法 —— 乘法会让编译器去调库函数，
     * 本工程是手工排地址的，能少一个外部符号就少一个。
     * 车停着的时候最近档也不长鸣，用最急的间歇，免得停在墙前一直叫。 */
    if (d < US_STOP)
        wait = PROX_INT_MIN;
    else
        wait = PROX_INT_MIN + ((unsigned int)(d - US_STOP) << PROX_INT_SH);
    if ((unsigned int)(tick_get() - prox_t) < wait)
        return;
    prox_t = tick_get();
    beepwhy('Q');                           /* 诊断：近距间歇响 */
    beep(BEEP_KEY);
}

/* ---- L2302-2313  play_exit() --- release on leaving playback ------------------- */
/* 退出回放：停车 -> 回手动 -> 恢复进入前的档位 -> 避障重新武装 -> 刷显示 */
static void play_exit(void)
{
    rec_halt();
    mode = MODE_MANUAL;
    gear = play_gear0;
    avst = AV_FREE;
    lastcmd = LASTCMD_NONE;                 /* 允许同一个键再按一次 */
    playidx = 0;
    show_state();
}


/* ---- L2330-2341  play_enter() --- release before playback ---------------------- */
        rec_err();
        return;
    }

    play_gear0 = gear;                      /* 记下进入前的档位（退出时恢复）*/
    /* 进回放要显式放行：回放不走避障判断，但驱动电机的地方会看避障状态，
     * 如果它停在转向避让上，回放的每个动作都会被改成原地右转。 */
    avst = AV_FREE;
    playidx = 0;
    cur_act = ACT_STOP;
    mode = MODE_PLAY;
    lastcmd = LASTCMD_NONE;

/* ---- L2455-2465  KEY_AVOID in non-manual modes --------------------------------- */
    if (tgt != 0xFF) {
        if (tgt != mode)
            mode_goto(tgt);
        return;
    }

    /* 遥控数字键 5 在这里也生效：非手动模式下同样能开关超声波避障。 */
    if (ir_ib2 == KEY_AVOID) {
        avoid_toggle();
        return;
    }

/* ---- L2612-2624  init_all() --- power-on defaults ------------------------------ */
    lastcmd = LASTCMD_NONE;
    lastt = 0;
    last_err = 0;
    ir_ledlo = 0;
    ir_ledhi = 0;

    /* ---- 模式与避障 ---- */
    mode = MODE_MANUAL;
    us_avoid_on = 1;                        /* 超声波避障上电默认开启（长按 S4 / 按 5 可关）*/
    avst = AV_FREE;                         /* 开机先放行，主循环第一趟就会刷新 */
    av_beep_t = 0;

    /* ---- 录制 / 回放 ---- */

/* ---- L2652-2664  ir_inv auto-calibration --------------------------------------- */
    /* ---- 超声波状态机（必须放在 P1 配好之后：us_init 会把触发脚拉低）---- */
    us_init();

    /* ---- 车头红外的极性：上电自动校准 ----
     * 把上电那一刻 P3.7 的电平当作“前面没有东西”的基准，之后和基准相反
     * 就算检测到。这样不管模块是哪种极性都对。
     * 前提是上电时车头 1~2cm 内不要有东西。 */
    if (IR_AVOID)
        ir_inv = 0;                         /* 上电读到高 -> 高 = 无反射 -> 检测到 = 低 */
    else
        ir_inv = 1;                         /* 上电读到低 -> 低 = 无反射 -> 检测到 = 高 */

    /* ---- 串口 9600 8N1（T1 方式2）+ T0 方式2 做 100us 时基 ---- */

/* ---- L2777-2806  main loop call sites ------------------------------------------ */
        /* ---- ① 回放中：走独立分支，不碰闸门也不碰按键扫描 ---- */
        if (mode == MODE_PLAY) {
            play_step();
            continue;
        }

        /* ---- ② 避障闸门 ---- */
        av_gate();

        /* ---- ③ 录制采样 ---- */
        if (recon)
            rec_sample();

        /* ---- ④ 模式分派 ---- */
        if (mode == MODE_MANUAL) {
            manual_step();
        } else {
            if (mode == MODE_LIGHT)
                light_step();
            else if (mode == MODE_TRACK)
                track_step();
            auto_step();
        }

        /* ---- A：倒车限时（只在手动/录制里生效，回放不受影响）---- */
        back_guard();

        /* ---- 避障关闭时的超声近距提示音（"倒车雷达"）---- */
        prox_beep();


/* ---- L2816-2826  on-board S4 long press ---------------------------------------- */
            } else {
                mode_switch();
            }
            continue;
        }
        if (k == 4) {                       /* S4 长按 -> 避障开关 */
            avoid_toggle();
            continue;
        }
        if (k == 1) {                       /* S3 短按 -> 加档 */
            if (gear >= MAXGEAR)

