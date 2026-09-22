;=========================================================================
; usfollow2.asm  --  超声波跟随小车：跟在目标后面，保持 5~10cm
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name usfollow2
; 串口输出 : P3.1(TXD) -> CH340 -> COM7，9600 8N1（每几轮打一行，便于标定）
;
; 【本文件是按用户要求重写的版本，不是 usfollow.asm 的补丁】
;   usfollow.asm（v1，保持 20~30cm）保留不动，作为对照与回退。
;-------------------------------------------------------------------------
;
; 一、要做什么（★ 桌面演示 · 保持距离的跟随，距离由你定）
;   把车放好，手伸到车头前你想让它保持的位置，"举着不动约 1.5 秒" ——
;   **那个位置就成为它要跟的距离**（自动零点）。然后：
;
;       手往**后**退（d 变大）  -> 车**前进**追上来
;       手往**前**凑（d 变小）  -> 车**后退**让开
;       手回到那个距离附近（±2cm）-> 车**停**（死区）
;       d < 3cm                 -> **无条件后退**（贴身安全）
;       d > 20cm                -> **无条件停**（不响应，防跑下桌子）
;       没有回波                 -> 原地不动
;
;   ★ 方向反了就改一个常量：MIRROR 0<->1（不用改逻辑）。
;
;   这是"距离保持"控制：车一动就把误差往回拉（负反馈），所以会稳稳地
;   跟着你的手走，不会顶着你的手、也不会跑掉。
;
;   ★ 为什么把范围收这么窄：桌面演示时车一动就是几厘米，
;     如果还按"60cm 以内都追"，它会追着你的手跑出桌沿。收窄到 12cm 以后，
;     它只在手离得很近（10cm 上下）时才动，怎么都不会跑下桌子。
;
; 二、先讲清楚：5~10cm 这个距离不好做，别把正常现象当 bug
;   HC-SR04 标称量程 2~400cm，但**低端 2~5cm 是它的边缘区**：发射余振还没
;   衰减干净，回波容易和余振混在一起，读数会跳。本程序做了两层对策：
;     1) **三次测量取中值** —— 偶尔一次跳变会被中值挡掉；
;     2) **前进/后退各留 2~3cm 迟滞**。
;   如果实测时数字仍在 3↔9 之间乱跳，说明这个模块的低端确实不行，
;   把手在参考位附近的死区（DEAD）调大一些（例如 ±4cm）会稳得多 ——
;   那仍然是"贴近跟"，只是没压到极限。
;
; 三、硬件与引脚（全部出自 docs\引脚表_原理图追线.md，且已上机复核）
;   Trig   = P1.3（DIP40 第 4 脚，图纸网标号 P13TR）
;   Echo   = P1.2（DIP40 第 3 脚，图纸网标号 P12EC）
;   电机   = P0.0~P0.3（L293D INPUT1~4）；使能 P0.4 / P0.5（高 = 使能）
;   蜂鸣器 = P0.6（S8550 PNP 驱动：低 = 导通发声；无源，要给方波）
;   数码管 = P2.7~P2.1（a~g，共阳，写 0 点亮）；P2.0 = D3 指示灯（写 0 亮）
;   串口   = P3.1 TXD
;
;   ⚠️ 板上那个 4 脚插座（CSB1）的顺序是 **1=GND、2=Echo、3=Trig、4=VCC**，
;      而常见 HC-SR04 模块自己是 **VCC / Trig / Echo / GND** —— 顺序正好反！
;      所以**不要直接把模块插上去**，用杜邦线一根一根按标号接：
;          模块 VCC  -> 插座第 4 脚        模块 GND  -> 插座第 1 脚
;          模块 Trig -> 插座第 3 脚        模块 Echo -> 插座第 2 脚
;      接之前最好通电，用万用表量一下插座上哪一脚是 VCC、哪一脚是 GND。
;   * Echo 是模块输出、5V 电平，直接进 MCU 没问题（STC89C52 是 5V 器件）。
;   * 若实测发现 Trig/Echo 恰好接反（症状：串口一直打 no echo），
;     把下面 US_TRIG / US_ECHO 两行对调，重编一次即可。
;
; 四、测距原理与换算
;   给 Trig 一个 >10us 的高脉冲，模块发 8 个 40kHz 脉冲；Echo 随之拉高，
;   收到回波后拉低。**Echo 的高电平宽度 = 声波往返时间**。
;   机器周期 = 12 / 11.0592MHz = 1.0851us
;   往返 1cm 的距离 = 声波走 2cm ≈ 58us ≈ 53.4 个机器周期
;   -> cm = 机器周期数 / 53（比真值大约 0.8%，对跟随门限毫无影响）
;   想标定：卷尺量 5 / 10 / 20 / 30cm，对着串口那行的 T 值看 T/53 差多少，
;           按同样比例改 CM_DIV（偏大就调大，偏小就调小）。
;
; 五、数码管 / 灯 / 蜂鸣器（怎么读数）
;   数码管显示（和 usprobe.hex 同一套读法）：
;     **"-"（只亮中间一横）= 没有回波**；
;     **数字 × 5 = 厘米** —— 1:5~9cm、2:10~14cm、4:20~24cm、9:>=45cm。
;     动作区（3~12cm）对应显示 0~2：0=0~4cm、1=5~9cm、2=10~14cm。
;     显示 2 以上（3~9）就说明目标已经超出 12cm，车不会动。
;     精确距离看串口 D=007cm。
;     -> 跟随带是 5~10cm，所以正常跟随时数码管应该停在 **5~9** 之间。
;     * 注意 P2.0 不是段选，它是 D3 指示灯。
;   D3 灯（P2.0，写 0 亮）：亮 = 电机在动，灭 = 停着。
;   蜂鸣器：开机"滴"一声（证明程序在跑）；倒车时每轮短鸣（倒车提示）；
;           连续丢失目标约 4 秒时也响一声。
;
; 六、安全（都编在程序里，不靠操作小心）
;   * 上电先停车，且**必须先量到一次有效回波才允许电机动作** ——
;     模块没插好 / Trig、Echo 接反 / 模块坏了，车就原地不动，而不是瞎冲；
;   * **没有回波一律当"没目标" -> 停**（Echo 一直低、一直高、超量程都算）；
;   * **距离 > D_FAR(20cm) 也当"没目标" -> 停** —— 这条专门防
;     "前方空旷、模块报一个有效但很远的距离"时车一直往前冲，
;     同时它也是"桌面演示不会跑下桌子"的保证；
;   * 内部 RAM 上电值不确定，凡是被"读"过的变量都显式清零；
;   * 调试时把小车架起来（跟随距离只有 5cm，不架起来会顶到你的手）。
;=========================================================================

;-------------------------------------------------------------------------
; 一、常量
;-------------------------------------------------------------------------
US_TRIG     BIT     P1.3        ; 触发（MCU 输出）—— 与 Echo 接反了就两行对调
US_ECHO     BIT     P1.2        ; 回波（MCU 输入）

TRIG_W      EQU     6           ; 触发脉冲宽度：6*2 = 12 机器周期 ≈ 13us（要求 >10us）

; ---------------------------------------------------------------------------
; ★ 交互方式（用户要求，2026-09-17）
;
;   "把手放在车头前 **10cm 左右**的位置；**我的手往前（靠近它），车就往前；
;    我的手往后（远离它），车就往后**。精度高一点。"
;
;   实现：**位置跟随 + 自动零点**
;
;     零点（REF）不是写死的 10cm，而是"车停着且距离稳定"时的当前距离 ——
;     **你的手停在哪，零点就在哪，也就是"你想要它保持的距离"**。
;     这样完全不依赖距离标定准不准（CM_DIV 是算出来的，从没实测校正过）。
;
;     在零点的基础上（★ 方向已按实测修正）：
;       手比零点**远**（d > REF+2cm） -> 车**前进**（追上去）
;       手比零点**近**（d < REF-2cm） -> 车**后退**（让开）
;       就在零点附近（±2cm）          -> 车**停**（死区，防抖）
;
;     ★ 为什么这个方向是对的（也是它稳定的原因）：
;       车往前走 -> 距离变小 -> 又回到"手比零点近" -> 负反馈，自动收敛。
;       反过来（近了前进）是正反馈，车一动就把误差越推越大，
;       会一路顶着你的手停不下来。
;
;   ★ MIRROR 开关：万一装出来方向又反了，改这一个数即可。
;     0 = 手远->前进 / 手近->后退（**现在这个，实测确认是对的**）
;     1 = 手近->前进 / 手远->后退（正反馈，仅作对照）
;
;   ★ MIRROR 开关：万一装出来左右反了，把它改成 0 即可，不用改逻辑。
;     1 = 手靠近 -> 前进（按用户描述）
;     0 = 手靠近 -> 后退（普通跟随：近了退、远了追）
;
;   两个保底限制（桌面演示必须有）：
;       距离 < D_NEAR(3cm)  -> **无条件后退**（贴身安全）
;       距离 > D_FAR(20cm)  -> **无条件停**（手离太远就不响应，防跑下桌子）
;
;   注意这是"位置"控制，不是"速度"控制 —— 车往前开会让距离变小，
;   也就是会往"手比 10cm 近"那一侧推，所以演示时要靠你移动手来保持平衡。
;   死区（±2cm）就是为了让它不至于一有风吹草动就动。
; ---------------------------------------------------------------------------
D_REF       EQU     10          ; 参考位的**初值**（上电先用它，稳定后自动更新，见 REF）
DEAD        EQU     2           ; 死区：参考位 ±2cm 之内不动
D_NEAR      EQU     3           ; d < 3cm  -> 一律后退（贴身安全）
D_FAR       EQU     20          ; d > 20cm -> 一律停（不响应，防跑下桌子）
MIRROR      EQU     0           ; ★ 0 = 手远->前进 / 手近->后退（实测确认的正确方向）
                                ;   1 = 反过来（正反馈，会顶着你的手，仅作对照）
STAB_TH     EQU     2           ; 相邻两轮的中值变化 < 2cm 算"距离稳定"
STAB_N      EQU     10          ; 连续稳定 10 轮（10 x 150ms ≈ 1.5s）就刷新零点
                                ;   -> 玩法：把手停住约 1.5 秒，那个位置就成为新的零点

; --- 距离换算 ---
CM_DIV      EQU     53          ; cm = 机器周期数 / 53（见第四节）
CM_FAR      EQU     255         ; "没有回波 / 超量程"时用的"很远"值

; --- 其它 ---
LOST_MAX    EQU     30          ; 连续 30 轮无回波 -> 报一次"目标丢失"（每轮 150ms，约 4.5 秒）
PRT_DIV     EQU     4           ; 串口每 4 轮打一行（动作变化时立刻打）
BEEP_CYCLES EQU     12          ; 短鸣 12 个 1kHz 半周期 ≈ 12ms

; --- 动作码 ---
ACT_STOP    EQU     00H
ACT_FORWARD EQU     01H
ACT_BACK    EQU     02H

; --- P0 输出图案（b0..b3 = IN1..IN4，b4 = ENA，b5 = ENB，b6 = 蜂鸣器 1=静音，b7 = 1）---
;   停车时 ENA/ENB 一起拉低 = 电机断电滑行，比"刹车"更省电、更安全。
PAT_STOP    EQU     0C0H
PAT_FORWARD EQU     0F5H        ; IN1 + IN3 -> 两个轮子同向
PAT_BACK    EQU     0FAH        ; IN2 + IN4

; --- 数码管"没有回波"符号 ---
;   只点亮中间那一横（段 g），看起来是个 "-"。
;   段序 a~g = bit7~bit1（写 0 点亮），bit0 = D3 灯（1 = 灭）
;   只有 g(bit1) = 0、其余全 1 -> 1111_1101 = 0FDH
;   为什么要这个：如果"没回波"和"距离 >=9cm"都显示 9，就分不清是
;   "模块没在回波"还是"前面真的有 9cm 以上的东西"，接线问题没法排查。
DISP_DASH   EQU     0FDH

;-------------------------------------------------------------------------
; 二、RAM 变量（数据区 30H 起；本程序不用中断，寄存器随便用，但变量要显式清零）
;-------------------------------------------------------------------------
S0          DATA    30H         ; 距离滑动窗口（三个值取中值，S0 最旧、S2 最新）
S1          DATA    31H
S2          DATA    32H
MED         DATA    33H         ; 中值滤波后的距离（cm）
DIST        DATA    34H         ; 本轮量到的距离（cm）
CURACT      DATA    35H         ; 当前动作码
MOTPAT      DATA    36H         ; 当前 P0 图案（蜂鸣器位保持 1 = 静音）
NOECHO      DATA    37H         ; 本轮有没有回波（1 = 没有）
LOSTCNT     DATA    38H         ; 连续"无回波"的轮数
VALID       DATA    39H         ; 有没有成功量到过一次回波（0 = 还没有 -> 不许动）
PRTCNT      DATA    3AH         ; 串口打印分频计数
LASTACT     DATA    3BH         ; 上次打印时的动作码
TKH         DATA    3CH         ; 本轮 Echo 高电平的机器周期数（高/低字节，诊断/标定用）
TKL         DATA    3DH
SCRL        DATA    3EH         ; 临时
; 中值排序用的**副本**（绝不能动 S0/S1/S2，见 MED3）。
; 注意：别叫 T0/T1 —— 那是 A51 的保留符号（定时器），会报"重复定义"。
CP0         DATA    3FH
CP1         DATA    40H
CP2         DATA    41H
REF         DATA    42H         ; ★ 自动零点：参考位（车停稳时的距离）
REFLO       DATA    43H         ; REF - DEAD（预先算好，省得每轮做减法）
REFHI       DATA    44H         ; REF + DEAD
STABC       DATA    45H         ; "距离稳定"的连续轮数
DPREV       DATA    46H         ; 上一轮的中值（判断稳不稳用）

;-------------------------------------------------------------------------
; 三、主程序
;-------------------------------------------------------------------------
            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H

            ; ---- 上电先停车、蜂鸣器静音、数码管全灭 ----
            MOV     MOTPAT, #PAT_STOP
            MOV     P0,     #PAT_STOP
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH
            CLR     US_TRIG             ; 触发脚先拉低，等会儿发干净的高脉冲

            ; ---- 内部 RAM 上电值不确定，凡是被"读"过的都要显式清零 ----
            MOV     CURACT, #ACT_STOP
            MOV     LASTACT,#0FFH       ; 0FFH = 不可能的动作码 -> 第一轮一定打印
            MOV     NOECHO, #1
            MOV     LOSTCNT,#0
            MOV     VALID,  #0
            MOV     PRTCNT, #1
            MOV     S0,     #CM_FAR
            MOV     S1,     #CM_FAR
            MOV     S2,     #CM_FAR
            MOV     MED,    #CM_FAR
            MOV     DIST,   #CM_FAR
            MOV     TKH,    #0
            MOV     TKL,    #0
            ; ---- 自动零点：上电先用 D_REF 当参考位，车停稳后会自动更新 ----
            MOV     REF,    #D_REF
            MOV     REFLO,  #(D_REF - DEAD)
            MOV     REFHI,  #(D_REF + DEAD)
            MOV     STABC,  #0
            MOV     DPREV,  #CM_FAR

            ; ---- 串口 9600 8N1：T1 方式2 做波特率；T0 方式1 留给超声波量回声宽度 ----
            MOV     TMOD,   #21H
            MOV     TH1,    #0FDH       ; 11059200/(384*3) = 9600
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H        ; 方式1
            MOV     PCON,   #00H        ; SMOD = 0
            SETB    TR1

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

            ; ---- 开机自检：模块没插好时 Echo 脚会浮空/被拉高 ----
            JB      US_ECHO, M_ECKHI
            MOV     DPTR,   #MSG_ECKOK
            ACALL   PRINT_STR
            SJMP    M_BEEP
M_ECKHI:
            MOV     DPTR,   #MSG_ECKHI
            ACALL   PRINT_STR
M_BEEP:
            ACALL   BEEP_SHORT          ; 开机"滴"一声 = 程序确实跑起来了

;=========================================================================
; 主循环：测距 -> 中值滤波 -> 决策（带迟滞）-> 电机/数码管/串口 -> 等 150ms
;
;   ★ 触发间隔用 150ms，**不用**数据手册的"最小 60ms"。
;     实测教训：用 60ms 时回波"时有时无"（成功率大约只有 1/3），
;     中值被"没回波"的占位值 255 顶住 -> 数码管老是封顶显示 9、车也不动。
;     同一个模块在 usprobe.hex 里用 150ms 就完全正常 —— 说明就是间隔太贴边。
;     150ms 对跟随来说响应完全够（一秒测 6~7 次）。
;   另外：数码管显示的是**本轮实测值 DIST**，不是中值 MED ——
;     两者若不一致，就说明回波在丢，一眼能看出来。
;=========================================================================
LOOP:
            ; ---- 1) 量一次 ----
            ACALL   US_MEASURE          ; C=0 成功（R6:R7 = 机器周期数）；C=1 没回波
            JC      L_NOECHO
            MOV     A,      R6          ; 收到 0 个周期 = 无效测量，也当没回波
            ORL     A,      R7
            JZ      L_NOECHO

            MOV     TKH,    R6
            MOV     TKL,    R7
            ACALL   TICKS2CM            ; A = cm
            MOV     DIST,   A
            MOV     NOECHO, #0
            MOV     LOSTCNT,#0          ; 只要见到回波，"丢失计数"就清零
            MOV     VALID,  #1          ; 而且从这一刻起才允许电机动
            LJMP    L_FILTER

L_NOECHO:
            MOV     TKH,    #0
            MOV     TKL,    #0
            MOV     DIST,   #CM_FAR
            MOV     NOECHO, #1
            ACALL   LOST_TICK

            ; ---- 2) 三次测量取中值（窗口滑动：S0 最旧，S2 最新）----
L_FILTER:
            MOV     A,      S1
            MOV     S0,     A
            MOV     A,      S2
            MOV     S1,     A
            MOV     A,      DIST
            MOV     S2,     A
            ACALL   MED3                ; -> MED

            ; ---- 2.5) ★ 自动零点：车停稳了就刷新参考位 ----
            ;   条件：本轮有回波 + 车停着 + 距离连续 STAB_N 轮几乎不变。
            ;   这样"手放在哪，零点就在哪"，不依赖距离标定准不准。
            ;   车在动的时候**绝不**刷新 —— 否则车自己走出来的距离
            ;   会被当成新的零点，控制就散了。
            MOV     A,      NOECHO
            JNZ     AZ_END              ; 没回波 -> 不碰零点，也不更新 DPREV

            MOV     A,      CURACT
            JNZ     AZ_BAD              ; 车在动 -> 本轮不算稳定

            ; |MED - DPREV| < STAB_TH ?
            MOV     A,      MED
            CLR     C
            SUBB    A,      DPREV
            JNC     AZ_POS              ; MED >= DPREV，差值已在 A 里
            MOV     A,      DPREV       ; MED < DPREV -> 取反向差值
            CLR     C
            SUBB    A,      MED
AZ_POS:
            CLR     C
            SUBB    A,      #STAB_TH
            JNC     AZ_BAD              ; 差值 >= STAB_TH -> 不稳

            ; ---- 稳定：累加，到 STAB_N 就刷新零点 ----
            MOV     A,      STABC
            CJNE    A,      #STAB_N, AZ_CNT
            SJMP    AZ_SET              ; 已经到顶 -> 每轮都刷新（零点跟着手走）
AZ_CNT:
            INC     STABC
            MOV     A,      STABC
            CJNE    A,      #STAB_N, AZ_END
AZ_SET:
            MOV     A,      MED         ; ★ 零点 = 当前距离
            MOV     REF,    A
            CLR     C
            SUBB    A,      #DEAD
            MOV     REFLO,  A
            MOV     A,      REF
            ADD     A,      #DEAD
            MOV     REFHI,  A
            SJMP    AZ_END

AZ_BAD:
            MOV     STABC,  #0

AZ_END:
            MOV     A,      MED
            MOV     DPREV,  A           ; 记下本轮中值（没回波那条路已经跳过了）

            ; ---- 3) 决策 ----
            MOV     A,      VALID
            JNZ     L_CHKLOST
            ; 一次有效回波都还没量到（模块没插好 / Trig、Echo 接反 / 坏了）
            ; -> 一律停车。宁可不动，也不能"因为量不到就往前冲"。
            MOV     A,      #ACT_STOP
            LJMP    L_APPLY
L_CHKLOST:
            MOV     A,      LOSTCNT
            CJNE    A,      #LOST_MAX, L_DECIDE
            MOV     A,      #ACT_STOP   ; 丢失太久：安全停车待机
            LJMP    L_APPLY
L_DECIDE:
            ACALL   VDECIDE             ; 距离 -> 动作码（位置镜像，见 VDECIDE）

            ; ---- 4) 动作落地 ----
L_APPLY:
            MOV     CURACT, A
            ACALL   MOTOR_SET           ; 动作码 -> P0
            ACALL   SHOW                ; 距离 -> 数码管 + D3 灯
            ACALL   REPORT              ; 串口打印（节流）

            ; ---- 5) 太近了就边退边鸣（倒车提示）----
            MOV     A,      CURACT
            CJNE    A,      #ACT_BACK, L_CYCLE
            ACALL   BEEP_SHORT
L_CYCLE:
            ACALL   D_150MS             ; 触发间隔 150ms（原因见上面的说明）
            LJMP    LOOP

;=========================================================================
; US_MEASURE：发一次触发脉冲，量 Echo 高电平宽度（单位：机器周期）
;   出：C = 0 成功，R6:R7 = Echo 高电平的机器周期数（1 周期 = 1.0851us）
;       C = 1 没有回波（等上升沿超时，或高电平一直不结束）
;   用 Timer0 方式1（16 位）。T1 还是串口波特率，TMOD 只能改低半字节。
;   Timer0 溢出 = 65536 周期 = 71ms，正好当"等不到"的超时：
;   71ms 对应 12m，远超模块量程（约 4m），所以超时就是"前面没东西"。
;=========================================================================
US_MEASURE:
            ; ---- 1) 触发脉冲：先拉低几个周期，再拉高 ~13us ----
            CLR     US_TRIG
            MOV     R2,     #4
USM_LOW:
            DJNZ    R2,     USM_LOW
            SETB    US_TRIG
            MOV     R2,     #TRIG_W
USM_HI:
            DJNZ    R2,     USM_HI
            CLR     US_TRIG

            ; ---- 2) 计时器归零，等 Echo 变高 ----
            MOV     TH0,    #0
            MOV     TL0,    #0
            CLR     TF0
            SETB    TR0
USM_RISE:
            JB      US_ECHO, USM_UP     ; Echo 已经高了
            JNB     TF0,    USM_RISE
            CLR     TR0                 ; 71ms 都没变高 -> 没回波
            SETB    C
            RET

            ; ---- 3) 上升沿到了：计时器清零重开，量的就是脉冲宽度本身 ----
USM_UP:
            CLR     TR0
            MOV     TH0,    #0
            MOV     TL0,    #0
            CLR     TF0
            SETB    TR0
USM_FALL:
            JNB     US_ECHO, USM_DOWN
            JNB     TF0,    USM_FALL
            CLR     TR0                 ; 高电平超过 71ms -> 模块没接好/坏了
            SETB    C
            RET
USM_DOWN:
            CLR     TR0                 ; 先停表再读数，两个字节一定是同一时刻的
            MOV     R6,     TH0
            MOV     R7,     TL0
            CLR     C
            RET

;=========================================================================
; TICKS2CM：机器周期数 -> 厘米
;   入：R6:R7（机器周期数）      出：A = 距离（cm），超过 255 给 255
;   原理：cm = 机器周期数 / 53（见第四节）
;   用"反复减 53、数次数"的除法：够直观、够便宜。最坏情况（65535 周期）
;   也就 1236 次减法，一轮里最多出一次，无所谓。
;=========================================================================
TICKS2CM:
            MOV     R4,     #0          ; 商高字节（只要不为 0 就说明 > 255cm）
            MOV     R5,     #0          ; 商低字节
T2C_LOOP:
            MOV     A,      R6
            JNZ     T2C_SUB             ; 高字节非 0 -> 至少 256 > 53，还能减
            MOV     A,      R7
            CLR     C
            SUBB    A,      #CM_DIV
            JC      T2C_DONE            ; 余数不够 53 了 -> 结束
T2C_SUB:
            CLR     C
            MOV     A,      R7
            SUBB    A,      #CM_DIV
            MOV     R7,     A
            MOV     A,      R6
            SUBB    A,      #0
            MOV     R6,     A
            INC     R5
            MOV     A,      R5
            JNZ     T2C_LOOP            ; 商低字节没回绕，继续
            INC     R4
            MOV     A,      R4
            JNZ     T2C_CAP             ; 商超过 255 -> 直接给上限
            LJMP    T2C_LOOP
T2C_CAP:
            MOV     A,      #CM_FAR
            RET
T2C_DONE:
            MOV     A,      R5
            RET

;=========================================================================
; VDECIDE：距离 -> 动作码（位置镜像，用户要的交互）
;   入：MED（cm）   出：A = 动作码
;
;   按顺序判断，前面两条是保底：
;     1) MED < D_NEAR(3cm)      -> **无条件后退**（贴身安全）
;     2) MED > D_FAR(20cm)      -> **无条件停**（手太远不响应，防跑下桌子）
;     3) MED < D_REF-DEAD(8cm)  -> 手比参考位 10cm **近** -> 按 MIRROR 定方向
;     4) MED > D_REF+DEAD(12cm) -> 手比参考位 10cm **远** -> 按 MIRROR 定方向
;     5) 落在 8~12cm 死区里      -> 停
;
;   为什么用 MED（三轮中值）而不是 DIST：位置控制要的是"稳"，
;   中值正好把抖动滤掉，免得车在死区边界上来回抽。
;   （MIRROR=0：手比零点远->前进、手比零点近->后退 = 距离保持的跟随，
;     实测确认的正确方向；MIRROR=1 是反的，会顶着你的手。）
;=========================================================================
VDECIDE:
            ; ---- 1) 保底：太近，无条件后退 ----
            MOV     A,      MED
            CLR     C
            SUBB    A,      #D_NEAR
            JC      VD_BACK

            ; ---- 2) 保底：太远，无条件停 ----
            MOV     A,      MED
            CLR     C
            SUBB    A,      #D_FAR
            JNC     VD_STOP

            ; ---- 3) 手比零点近？ ----
            MOV     A,      MED
            CLR     C
            SUBB    A,      REFLO
            JC      VD_NEAR

            ; ---- 4) 手比零点远？ ----
            MOV     A,      MED
            CLR     C
            SUBB    A,      REFHI
            JNC     VD_FAR

            ; ---- 5) 落在死区里：停 ----
VD_STOP:
            MOV     A,      #ACT_STOP
            RET

VD_BACK:
            MOV     A,      #ACT_BACK
            RET

VD_NEAR:                                ; 手比 10cm 近
    IF MIRROR
            MOV     A,      #ACT_FORWARD
    ELSE
            MOV     A,      #ACT_BACK
    ENDIF
            RET

VD_FAR:                                 ; 手比 10cm 远
    IF MIRROR
            MOV     A,      #ACT_BACK
    ELSE
            MOV     A,      #ACT_FORWARD
    ENDIF
            RET

;=========================================================================
; MED3：S0/S1/S2 三个数取中值 -> MED
;
;   ★★ 必须排序在**副本** T0/T1/T2 上做，绝不能就地排 S0/S1/S2 ★★
;
;   为什么（这是 v2 实测踩过的大坑，原件 usfollow.asm 也中招）：
;     如果在 S0/S1/S2 上就地排序，排完它们就变成「小/中/大」的顺序，
;     而滑动窗口是靠**位置**来表示新旧的（S0 最旧、S2 最新）：
;         下一轮移位 S0<-S1、S1<-S2、S2<-新值
;     排过序之后再移位，丢掉的永远是**最小值**，窗口里始终留着最大的两个。
;     初始值又是 CM_FAR(255)，于是中值被永久顶在 255 ->
;     车永远判成"太远（超过 D_FAR）" -> **数码管数字正常，车却一动不动**。
;   （原件那句"排序只是换顺序，不改变集合，所以滑动窗口不受影响"是错的：
;     集合确实没变，但**窗口的演化**变了。）
;
;   现在排序只动副本，S0/S1/S2 保持严格的先进先出。
;=========================================================================
MED3:
            MOV     A,      S0
            MOV     CP0,    A
            MOV     A,      S1
            MOV     CP1,    A
            MOV     A,      S2
            MOV     CP2,    A

            MOV     R0,     #CP0
            MOV     R1,     #CP1
            ACALL   SWAPGT
            MOV     R0,     #CP1
            MOV     R1,     #CP2
            ACALL   SWAPGT
            MOV     R0,     #CP0
            MOV     R1,     #CP1
            ACALL   SWAPGT

            MOV     A,      CP1         ; 排序后 CP1 就是中值
            MOV     MED,    A
            RET

;-------------------------------------------------------------------------
; SWAPGT：若 @R0 > @R1 就交换这两个字节（用 XCH 省一个寄存器）
;-------------------------------------------------------------------------
SWAPGT:
            MOV     A,      @R0
            CLR     C
            SUBB    A,      @R1
            JC      SWGT_DONE           ; 前者 <= 后者，不用换
            MOV     A,      @R1
            XCH     A,      @R0
            MOV     @R1,    A
SWGT_DONE:
            RET

;=========================================================================
; MOTOR_SET：动作码（A）-> P0 输出图案
;=========================================================================
MOTOR_SET:
            CJNE    A,      #ACT_FORWARD, MS_1
            MOV     MOTPAT, #PAT_FORWARD
            SJMP    MS_DO
MS_1:
            CJNE    A,      #ACT_BACK, MS_2
            MOV     MOTPAT, #PAT_BACK
            SJMP    MS_DO
MS_2:
            MOV     MOTPAT, #PAT_STOP   ; ACT_STOP 及任何意外值都当停车
MS_DO:
            MOV     P0,     MOTPAT
            RET

;=========================================================================
; SHOW：把 MED（cm）显示到数码管；D3 灯亮 = 电机在动
;   共阳数码管：段写 0 点亮；段序 a=P2.7 b=P2.6 c=P2.5 d=P2.4 e=P2.3 f=P2.2 g=P2.1
;   P2.0 = D3 指示灯（写 0 亮），不是段选
;
;   显示规则（和 usprobe.hex 完全一致 —— 读法一样，不用记两套）：
;     没回波 -> **只点亮中间那一横（"-"）**
;     有回波 -> **距离 / 5**，也就是 **数字 × 5 = 厘米**
;               0:0-4   1:5-9   2:10-14  3:15-19  4:20-24
;               5:25-29 6:30-34  7:35-39  8:40-44  9:>=45cm
;   （动作区 3~12cm 正好是 0~2；显示 3 以上就说明目标超出 12cm，车不会动。）
;
;   为什么不用"厘米数本身"：一位数码管到 9 就到头了，10cm 和 60cm 都显示 9，
;   根本分不出"没跟到"和"已经跟到 10cm" —— v2 第一次实测就是被这一点误导的。
;=========================================================================
SHOW:
            MOV     A,      NOECHO
            JZ      SH_DIST
            MOV     A,      #DISP_DASH  ; 没回波 -> 显示 "-"
            SJMP    SH_HAVE
SH_DIST:
            MOV     A,      DIST        ; ★ 显示**本轮实测值**，不是中值 MED
            ACALL   DIST_DIGIT          ; A = 距离/5（0..9）
            MOV     DPTR,   #DIGIT
            MOVC    A,      @A+DPTR     ; 段码（bit0 = 1 -> D3 灭）
SH_HAVE:
            MOV     SCRL,   A
            MOV     A,      CURACT
            JZ      SH_OFF              ; 动作码 0 = 停 -> D3 灭
            MOV     A,      SCRL
            ANL     A,      #0FEH       ; bit0 = 0 -> D3 亮（在动）
            MOV     P2,     A
            RET
SH_OFF:
            MOV     P2,     SCRL
            RET

;=========================================================================
; DIST_DIGIT：距离（cm）-> 数码管数字，每 2cm 一格，封顶 9
;   入：A = 距离（cm，可能到 255）   出：A = 0..9
;   读法：**数字 × 2 = 厘米** —— 0:0~1  1:2~3  2:4~5  3:6~7  4:8~9
;                                    5:10~11  6:12~13 … 9:>=18cm
;   ★ 每格 2cm（不是 5cm）：交互的参考位是 10cm、死区只有 ±2cm，
;     每格 5cm 太粗，看不出"手在参考位哪一边"。
;   用 R3 当商计数器（本程序其它地方不用 R3）
;=========================================================================
DIST_DIGIT:
            MOV     R3,     #0
DGD_LP:
            CJNE    R3,     #9, DGD_SUB ; 还没到 9 格 -> 继续减
            MOV     A,      #9          ; 已经 9 格 -> 封顶
            RET
DGD_SUB:
            CLR     C
            SUBB    A,      #2
            JC      DGD_DN              ; 不够减了 -> 商就是 R3
            INC     R3
            SJMP    DGD_LP
DGD_DN:
            MOV     A,      R3
            RET

;=========================================================================
; LOST_TICK：连续无回波计数；刚到 LOST_MAX 那一轮报一次警
;   （电机的安全停车不靠它 —— 没回波时 MED=255 > D_FAR，本来就停着）
;=========================================================================
LOST_TICK:
            MOV     A,      LOSTCNT
            CJNE    A,      #LOST_MAX, LT_ADD
            RET                         ; 已经判过了，不再累加
LT_ADD:
            INC     A
            MOV     LOSTCNT,A
            CJNE    A,      #LOST_MAX, LT_RET
            ; ---- 刚判定"目标丢失"：报警一次 ----
            ;      区分两种情况：跟丢过目标 / 从头到尾一次回波都没量到（接线问题）
            MOV     A,      VALID
            JZ      LT_NEVER
            MOV     DPTR,   #MSG_LOST
            LJMP    LT_SAY
LT_NEVER:
            MOV     DPTR,   #MSG_NEVER
LT_SAY:
            ACALL   PRINT_STR
            MOV     PRTCNT, #1          ; 顺便让这一轮一定打一行状态
            ACALL   BEEP_SHORT
LT_RET:
            RET

;=========================================================================
; REPORT：串口打印（节流）
;   动作变化 -> 立刻打一行；否则每 PRT_DIV 轮打一行
;=========================================================================
REPORT:
            MOV     A,      CURACT
            CJNE    A,      LASTACT, RP_NOW
            DJNZ    PRTCNT, RP_RET
RP_NOW:
            MOV     PRTCNT, #PRT_DIV
            MOV     A,      CURACT
            MOV     LASTACT,A
            ACALL   PRINT_LINE
RP_RET:
            RET

;-------------------------------------------------------------------------
; PRINT_LINE：D=007cm T=017F A=FWD
;              D=---cm (no echo)  A=STOP      （没有回波时）
;   T 是本轮 Echo 高电平的机器周期数（4 位十六进制），用来：
;     1) 手工标定距离：cm ≈ T/53；2) 判断模块到底有没有在回波。
;-------------------------------------------------------------------------
PRINT_LINE:
            MOV     DPTR,   #MSG_D
            ACALL   PRINT_STR
            MOV     A,      NOECHO
            JNZ     PL_NOECHO
            MOV     A,      MED
            ACALL   PUT_DEC3
            MOV     DPTR,   #MSG_CM
            ACALL   PRINT_STR
            MOV     A,      TKH
            ACALL   PUT_HEX
            MOV     A,      TKL
            ACALL   PUT_HEX
            SJMP    PL_ACT
PL_NOECHO:
            MOV     DPTR,   #MSG_NOECHO
            ACALL   PRINT_STR
PL_ACT:
            MOV     DPTR,   #MSG_A
            ACALL   PRINT_STR
            MOV     A,      CURACT
            ACALL   PRT_ACTNAME
            RET

;-------------------------------------------------------------------------
; PRT_ACTNAME：动作名（A = 动作码）
;-------------------------------------------------------------------------
PRT_ACTNAME:
            CJNE    A,      #ACT_FORWARD, PAN_1
            MOV     DPTR,   #MSG_FWD
            SJMP    PAN_PR
PAN_1:
            CJNE    A,      #ACT_BACK, PAN_2
            MOV     DPTR,   #MSG_BCK
            SJMP    PAN_PR
PAN_2:
            MOV     DPTR,   #MSG_STP
PAN_PR:
            ACALL   PRINT_STR
            RET

;=========================================================================
; BEEP_SHORT：短鸣一声
;   无源蜂鸣器 + S8550(PNP)：P0.6 拉低 -> 导通，拉高 -> 截止，
;   交替 12 次 ≈ 1kHz、12ms。MOTPAT 的蜂鸣器位本来就是 1（静音），
;   清掉那一位就是响；响完再写回 MOTPAT，电机状态不受影响。
;   只用 R7（D_500US 用 R1）。
;=========================================================================
BEEP_SHORT:
            MOV     R7,     #BEEP_CYCLES
BS_LOOP:
            MOV     A,      MOTPAT
            ANL     A,      #0BFH       ; b6 = 0 -> 响
            MOV     P0,     A
            ACALL   D_500US
            MOV     P0,     MOTPAT      ; b6 = 1 -> 静音
            ACALL   D_500US
            DJNZ    R7,     BS_LOOP
            RET

;=========================================================================
; 串口输出辅助（9600 8N1，P3.1）
;=========================================================================
PUTCHAR:                                ; 发送 A 里的字符
            MOV     SBUF,   A
            JNB     TI,     $
            CLR     TI
            RET

PRINT_STR:                              ; 打印 DPTR 指向的 0 结尾字符串
            CLR     A
            MOVC    A,      @A+DPTR
            JZ      PS_DONE
            INC     DPTR
            ACALL   PUTCHAR
            SJMP    PRINT_STR
PS_DONE:
            RET

PUT_HEX:                                ; A -> 两位十六进制
            PUSH    ACC
            SWAP    A
            ANL     A,      #0FH
            MOV     DPTR,   #HEXTAB
            MOVC    A,      @A+DPTR
            ACALL   PUTCHAR
            POP     ACC
            ANL     A,      #0FH
            MOVC    A,      @A+DPTR
            ACALL   PUTCHAR
            RET

PUT_DEC3:                               ; A（0..255）-> 三位十进制（带前导零）
            MOV     B,      #100
            DIV     AB                  ; A = 百位，B = 余数
            ADD     A,      #'0'
            ACALL   PUTCHAR
            MOV     A,      B
            MOV     B,      #10
            DIV     AB                  ; A = 十位，B = 个位
            ADD     A,      #'0'
            ACALL   PUTCHAR
            MOV     A,      B
            ADD     A,      #'0'
            ACALL   PUTCHAR
            RET

;=========================================================================
; 延时（机器周期 = 1.085us）
;   D_500US 用 R1；D_1MS 用 R1/R2；D_150MS 用 R5。
;   测距结果在 R6/R7，除法在 R4/R5 —— 都在调用点之外，不冲突。
;=========================================================================
D_500US:
            MOV     R1,     #229
D500:
            DJNZ    R1,     D500        ; 229*2 = 458 周期 ≈ 497us
            RET

D_1MS:
            MOV     R2,     #2
D1M_1:
            MOV     R1,     #230
D1M_2:
            DJNZ    R1,     D1M_2       ; 230*2 = 460 周期
            DJNZ    R2,     D1M_1
            RET                         ; 约 930 周期 ≈ 1.01ms

D_150MS:
            MOV     R5,     #150
D150_1:
            ACALL   D_1MS
            DJNZ    R5,     D150_1
            RET

;=========================================================================
; 字符串与码表
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== ULTRASONIC FOLLOW CAR v2  STC89C52 @11.0592MHz ===',0DH,0AH
            DB  'Trig=P1.3  Echo=P1.2 (schematic net labels P13TR / P12EC)',0DH,0AH
            DB  'motors P0.0-P0.5 via L293D | 7seg: digit x5 = cm, "-" = no echo',0DH,0AH
            DB  'follow: hand>zero -> FWD | hand<zero -> BACK | hold 1.5s = new zero',0DH,0AH
            DB  'no echo -> STOP. UART 9600 8N1, line: D=cm T=ticks A=action.',0DH,0AH,0
MSG_ECKOK:
            DB  'self-check: Echo idle = LOW  (ok)',0DH,0AH,0
MSG_ECKHI:
            DB  '! self-check: Echo reads HIGH while idle -> check module/wiring',0DH,0AH,0
MSG_LOST:
            DB  0DH,0AH,'!! target lost -> STOP (bring something within 12cm to resume)',0DH,0AH,0
MSG_NEVER:
            DB  0DH,0AH,'!! never got a single echo -> check module wiring',0DH,0AH
            DB  '   (VCC->pin4 GND->pin1 Trig->pin3 Echo->pin2 ; Trig/Echo swapped?)',0DH,0AH,0
MSG_D:      DB  0DH,0AH,'D=',0
MSG_CM:     DB  'cm T=',0
MSG_NOECHO: DB  '---cm (no echo)     T=----',0
MSG_A:      DB  '  A=',0
MSG_FWD:    DB  'FWD',0
MSG_BCK:    DB  'BACK',0
MSG_STP:    DB  'STOP',0

; 共阳数码管段码：bit7..bit1 = a b c d e f g（写 0 点亮），bit0 = D3 灯（1 = 灭）
DIGIT:      DB  03H,9FH,25H,0DH,99H,49H,41H,1FH,01H,09H
HEXTAB:     DB  '0123456789ABCDEF'

            END
