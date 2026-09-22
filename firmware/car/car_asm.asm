;=========================================================================
; car_asm.asm  --  智能移动机器人 正式固件（红外遥控动作录制与回放）
;-------------------------------------------------------------------------
; 姓名     : 李家乐
; 学号     : 03231312
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1
;-------------------------------------------------------------------------
; 本文件按"一块一块加、每块都能单独上机验证"的方式写。当前进度：
;
;   [x] 块① 电机层：Motor_Set(action, speed) + 软件 PWM + 数码管档位
;               + 蜂鸣器 + 按键调速（S3 加档 / S4 减档）
;   [x] 块② 红外遥控（NEC 解码 + 方向控制 + 前进/后退锁定式 + 遥控调速）
;   [x] 块③ 模式状态机（手动 / 寻光 / 循迹）+ 长按 S3 切模式 + 模式显示
;   [x] 块④ 寻光模式（P1.1 左 / P1.0 右，见光 = 低）
;   [x] 块⑤ 循迹模式（P3.5/P3.6，压黑线 = 高，含脱线超时）
;   [x] 块⑥ 避障（**闸门**，不是模式：超声波测距，近则转向避让 / **太近则刹停交给遥控**；
;               **只作用于 手动/寻光**；S4 长按开关）
;   [x] 块⑦ 动作录制（240 B 缓冲放片内扩展 RAM，`MOVX @DPTR`；同 Action+Gear 合并；满 80 条保护）
;   [x] 块⑧ 动作回放（10 ms 中断节拍 + 非阻塞收帧 + **遇障停车终止、不绕行**）
;           ★ 2026-09-20 写完并编译通过：0 错 0 警告，`code=2740`（块⑦⑧ 合计 +810 B）。
;             ⚠️ 已超 Eval 的 2048 上限 -> hex 由 `tools\lst2hex.py` 回退生成（见 build.ps1）。
;           ✅ **2026-09-20 上机验证通过（用户实测）**：
;               · **基础功能回归 T11 全过**（PWM/音调、遥控方向、加减档、寻光 L、循迹 t、
;                 避障三档、长按 S4 开关、遥控急停）—— 说明这次的大改动没碰坏既有功能
;               · 录制能进能出（响一声+`r` / 响两声+回档位）
;               · **回放能跑起来**并按记录自动停
;               · Stop / 方向键 / 再按 `8` —— 三种方式都能中断回放
;               · ★ **遇障立即停车终止、不绕行**（"安全复现"这条创新点的现场证据）
;               · 空记录按 `8` 被拒绝（闪 `E` + 两声，不进回放、不死机）；按 `9` 清空有效
;           ⏳ **仍未验证**（别写成"已验证"）：同动作合并 / 档位不同不合并（T2/T3）、
;              录满 80 条自动封存（T9）、掉电后记录丢失（T12）、长按方向键后松开转停止（T13）。
;           📌 修过一个**只有上机才暴露**的 bug（编译 0 错 0 警告但一按就飞）：
;              `PLAY_STEP` 是被 MAIN_LOOP 用 `LJMP` 跳进来的，却用 `RET` 收尾
;              -> `RET` 弹出**从没压过**的地址 -> 跳到垃圾地址 -> 表现为"**按 8 完全不回放**"。
;              **栈约定**（务必遵守）见 `PLAY_STEP` 的注释块：LJMP 进来的段**出口必须 LJMP**、
;              子例程**必须 LCALL**。同族陷阱还有 `ACALL` 的 2KB 页限制（见冻结文档 §1.11）。
;
;   ★★ 2026-09-20 **设计冻结已通过**，方案与逐条论证见 docs\示教创新功能设计冻结.md：
;      · 记录单元 3 B = Byte0 `(Action<<4)|Gear` + Byte1/2 时长低/高（单位 10ms）
;      · 80 条 = 240 B 放片内扩展 RAM（**只能 MOVX @DPTR**，MOVX @Ri 会把 P2 当高地址、打花数码管）
;      · 10 ms 基准在 T0_ISR 里（放 `MOV P0,A` 之后，PWM 时序零影响）
;      · 回放走主循环**最前面的独立分支**，**不进 AV_GATE**（避障的"改写成右转"与
;        "遇障停车终止"语义相反，见冻结文档 §1.1 冲突 C1）
;      · 新变量放 21H~2FH + 位区 20H.4~.7（**60H~7FH 是栈，不能用**，见冻结 §1.2 冲突 C2）
;      实施按"增量可验证"推进：地基(10ms 时基) -> 录制层 -> 回放层，每步单独上机验。
;
; 全局功能：遥控「停止」（急停回手动）与「加减档」（数字键 6 / 4）在手动/寻光/循迹下都生效
;
; 整机怎么验证：
;   烧进去 -> 长按 S3 约 1 秒依次切模式：手动(显示档位) -> "L" 寻光 -> "t" 循迹 -> 手动
;   手动：S3 加档 / S4 减档（短按）；遥控方向键；前进/后退按一下持续走，左转/右转按住才转
;   长按 S4 约 1 秒：全局避障开（响两声）/ 关（响一声长）
;   数码管显示档位或模式代号，D3 亮 = 电机在动
;   ⚠️ 第一次跑把车轮架空
;
;   ★★ 块⑦⑧ 示教录制 / 回放 —— 遥控**数字键 7 / 8 / 9**（2026-09-20 实测确认的码值）：
;     7 = 录制 开/关   进：响**一声** + 数码管 "r"；出：响**两声** + 回到档位显示
;     8 = 回放         进：响一声 + 数码管 "P"；播完**自动停**并退回手动
;                      再按 8 / 按「停止」/ 按任意方向键 —— 都退出回放（D6：只退出+停车）
;     9 = 清空记录     只在**车停着且不在回放**时有效（防误触）；响两声
;     ★ **回放中遇到障碍 -> 立即停车并终止回放**（响两声短），**绝不绕开**。
;       这是本功能的定义性行为（"复现示教路径"而不是"自主重新规划"）。
;     ★ 录制中想切模式（遥控 1/2/3 或长按 S3）-> **被拒绝**（响两声、显示不变），
;       否则自主模式的动作会污染记录。
;     ★ 数码管 "E" = 空记录回放被拒绝；"F" = 已录满 80 条并自动停录。
;
; 引脚（全部来自 firmware\car\config.h，已实测确认，不得改）：
;   P0.0~P0.3 = L293D INPUT1~4（方向）      P0.4/P0.5 = ENA/ENB（高 = 使能，PWM 调速）
;   P0.6 = 蜂鸣器（PNP，低 = 发声，无源需方波）   P0.7 = 不用（写 1）
;   P2.7~P2.1 = 数码管 a~g（共阳，写 0 点亮，**顺序是反的**）   P2.0 = D3 灯（写 0 亮）
;   P3.2 = 按键 S4      P3.4 = 按键 S3      P3.1 = TXD（9600 调试）
;
; ★ 架构约定（块①定下，后面所有块都遵守）：
;   1) **主循环永远不直接写 P0**。P0 由 Timer0 中断每 99.8us 组装一次：
;      方向位来自 DIRBITS，ENA/ENB 来自 PWM 比较，蜂鸣器位来自 BUZB。
;      这样"主循环改方向"和"中断打 PWM"不会互相踩。
;   2) 动作码 -> 电机图案的映射只在这一个文件里（MOTOR_SET_ACT / DIRTAB），
;      也就是报告里的 Motor_Set(action, speed) 统一出口。
;   3) 时基：Timer0 方式2（重装 164）≈ 99.8us/tick；20 tick = 2ms = 500Hz PWM；
;      Timer1 方式2 做 9600 波特率（调试用）。红外解码将来也用这同一个 tick。
;=========================================================================

; --- 数码管段码（共阳：写 0 点亮；bit7..bit1 = a b c d e f g；bit0 = D3 灯，1 = 灭）---
DISP_0      EQU     03H
DISP_1      EQU     9FH
DISP_2      EQU     25H
DISP_3      EQU     0DH
DISP_4      EQU     99H
DISP_5      EQU     49H
DISP_6      EQU     41H
DISP_7      EQU     1FH
DISP_L      EQU     0E3H            ; "L" 寻光模式代号
DISP_T      EQU     0E1H            ; "t" 循迹模式代号（d+e+f+g 亮）
DISP_A      EQU     11H             ; "A" 避障模式代号
; --- ★ 块⑦⑧（示教录制/回放）新增段码（2026-09-20 设计冻结 §3.1）---
;   位序同上面：bit7..bit1 = a b c d e f g，写 0 点亮；bit0 = D3（1 = 灭）。
;   ★ 已用 HEXSEG（本文件末尾）交叉验算：E=61H、F=71H 与下面一致，位序没记错。
DISP_R      EQU     0F5H            ; "r" 录制中（只点 e+g）
DISP_P      EQU     031H            ; "P" 回放中（a+b+e+f+g）
DISP_E      EQU     061H            ; "E" 空记录 / 拒绝（= HEXSEG 的 E ✅）
DISP_F      EQU     071H            ; "F" 已满 80 条（= HEXSEG 的 F ✅）

; --- P0 方向位（低 4 位 = IN1..IN4；与 config.h 的 PAT_* 一致）---
DIR_STOP    EQU     00H
DIR_FWD     EQU     05H             ; IN1 + IN3
DIR_BACK    EQU     0AH             ; IN2 + IN4
DIR_LEFT    EQU     06H             ; IN2 + IN3 -> 原地左转
DIR_RIGHT   EQU     09H             ; IN1 + IN4 -> 原地右转

; --- 动作码（与报告表 4 一致）---
ACT_STOP    EQU     00H
ACT_FORWARD EQU     01H
ACT_BACK    EQU     02H
ACT_LEFT    EQU     03H
ACT_RIGHT   EQU     04H
; ★ R9（2026-09-20）：弧线转弯（两轮**都正转**、内外轮差速）
ACT_ARC_L   EQU     05H             ; 弧线左转：左轮慢（内轮）、右轮快（外轮）
ACT_ARC_R   EQU     06H             ; 弧线右转：左轮快（外轮）、右轮慢（内轮）

; --- 避障闸门状态（块⑥；★ R3 2026-09-20 由两态扩成四态）---
AV_FREE     EQU     0               ; 放行（无障碍，或已从"太近"档脱离）
AV_TURN     EQU     1               ; 近区（<21cm）：动作一律改写成"原地右转避让"
AV_HOLD     EQU     2               ; 太近（<10cm）：**刹停 + 锁存**，车不动，交给人
AV_HUMAN    EQU     3               ; 遥控已接管：完全放行；距离回到 ≥10cm 后自动回 AV_FREE

; --- 调试开关（★ 体积开关 + 实时性开关）---
;   1 = 编入串口打印（开发期用）
;   0 = 所有打印变成空操作（省 434 B，而且**红外接收更稳**）
;   ⚠️ 2026-09-18 实测教训：9600 baud 下**每个字符约 1 ms**，打一行 40 字符的
;      调试信息要 42 ms，而一整帧 NEC 只有 67 ms —— 打印期间会**错过下一帧的开头**，
;      于是从帧中间截到数据 -> 引导码不符 -> 被拒 -> 又打印 -> 又错过……
;      表现就是"按遥控器完全没反应"或"按不同键都解出同一个值"。
;      **所以正式用（要真实遥控）时，这个开关必须是 0。**
DEBUG_UART  EQU     0

; --- 诊断版（排查"按遥控没反应"用；定版时改回 0）---
;   1 = 上电响 3 声 + 数码管显示 "8"（证明程序在跑）
;       收到完整红外帧 -> 数码管轮流显示键值 高/低半字节 + 响一声
;       收到重复帧   -> 短响一声（证明"遥控有信号但只有重复帧"）
DIAG_IR     EQU     0
DISP_8      EQU     01H             ; 数码管 "8"（诊断上电提示）

; --- 运行模式（块③ 状态机）---
;   模式切换：**长按 S3 约 1 秒**（短按 S3 仍是加档）。
;   手动模式下数码管显示档位；其它模式显示模式代号。
;   ★ 避障**不是模式**（2026-09-20 改）：它是**全局闸门**，S4 长按开关，见 AV_GATE。
MODE_MANUAL EQU     0               ; 手动/遥控
MODE_LIGHT  EQU     1               ; 寻光（块④）
MODE_TRACK  EQU     2               ; 循迹（块⑤）
NMODES      EQU     3               ; 目前实现到 3；后面加综合/录制/回放时改这里 + MODETAB
; ★★ 块⑧（示教回放）2026-09-20 设计冻结：**MODE_PLAY 故意取 3 == NMODES** ——
;   MODE_SWITCH 的循环是 `INC A -> CJNE A,#NMODES -> CLR A`，从 MODE_TRACK(2) 一 INC 就等于
;   NMODES 就绕回手动了，所以 **长按 S3 的循环永远选不到回放** ⇒ 模式循环行为一个字不改。
;   回放不是"循环里的模式"，而是"遥控数字键 8 直选 + 播完即退"的**独立模式**。
;   ⚠️ 主循环里回放走**最前面的独立分支**，**不进 AV_GATE** —— 因为避障闸门在 5~21cm 的动作是
;      "改写成原地右转绕过去"（见 MOTOR_SET_ACT 的 MSA_TURN），而回放要求的是
;      "遇障**立即停车并终止**、不擅自改变示教路径"，两者**语义相反**（设计冻结 §1.1 冲突 C1）。
MODE_PLAY   EQU     3               ; 示教回放（★ 不在 S3 长按的循环里）

; --- 时基 / PWM / 档位 ---
T0_RELOAD   EQU     164             ; 256-164 = 92 机器周期 ≈ 99.8us
PWM_PER     EQU     20              ; 20 tick = 2ms -> 500Hz
MAXGEAR     EQU     5               ; 档位 0(停) .. 5(100%)
BUZ_DIV     EQU     5               ; 蜂鸣器每 5 tick 翻一次 ≈ 1kHz
BEEP_TICKS  EQU     40              ; 变档提示音：40 个半周期 ≈ 20ms
BEEP_KEY    EQU     24              ; 收到遥控键的提示音 ≈ 12ms
DEBOUNCE_MS EQU     20
LP_TMO_H    EQU     39              ; S3 长按门限：39*256 = 9984 tick ≈ 1.0s（块③ 切模式）
TRK_TMO_H   EQU     19              ; 循迹脱线超时：19*256 ≈ 4864 tick ≈ 0.5s（块⑤）
; --- ★ 块⑦⑧（示教录制/回放）：10ms 软件时间基准（设计冻结 §5.1）---
;   T0_ISR 每 99.83us 加 1 个 tick；每 MS10_DIV=100 个 tick = 9.983ms ≈ 10ms
;   -> 这就是录制/回放的"节拍"，一个时长单位。
;   ★ 为什么**必须**放在中断里：主循环周期 ≈26ms（IR_RECV 等边沿最多阻塞 25.6ms），
;     用它数节拍的话，一个 100ms 的动作会跑成 126ms = **26% 误差**，
;     而报告表 5 要求"每个动作持续时间误差 ≤ ±5%" —— 用主循环数必然不达标。
;   ★ 分频代码放在 T0_ISR 的 `MOV P0,A` **之后** ⇒ P0 写入时刻不变，PWM 时序零影响。
MS10_DIV    EQU     100             ; 100 tick × 99.83us = 9.983ms（报告写 10ms，实差 -0.17%）

; --- ★★ 块⑦⑧（示教录制/回放）常量（设计冻结 §4/§5）---
REC_MAX     EQU     80              ; 80 条 × 3 B = 240 B（与报告一致）
REC_UNIT    EQU     3               ; 每个记录单元 3 字节
ACTPK_MASK  EQU     0F0H            ; Byte0 高 4 位 = Action（动作码）
GEAR_MASK   EQU     00FH            ; Byte0 低 4 位 = Gear（档位 0~5）
RECCAP_H    EQU     0BH             ; ★ D2：单条时长上限，**按高字节判定**
                                    ;   高字节到 0BH -> 0x0B00 = 2816 单位
                                    ;   2816 × 9.983ms ≈ 28.1s（实际落在 28.1~30.7s，≈30s）
                                    ;   ★ 为什么按高字节判：省掉 16 位比较（约 10 字节），
                                    ;     而 D2 要的只是"别让单条无限延长"，精度无所谓
XRAM_BASE   EQU     0000H           ; 记录区起点（MOVX @DPTR，占用 0x0000~0x00EF）
                                    ;   0x00F0~0x00FF 是保留区（冻结 §5.3）
PSF_GAP     EQU     6               ; ★ 块⑧ 回放安全：超声波测距节流 = 6 × 10ms = 60ms
                                    ;   HC-SR04 规格要求测距周期 ≥60ms，太密会被余振误判成回波
; --- 块⑥ 避障（超声波）：门限都用 tick 作单位（1 tick = 100us ≈ 1.72cm）---
;   回波高电平时长 t(us) ≈ 58.3 × 距离(cm)  ->  t(tick) ≈ 0.583 × 距离(cm)
;   所以：距离(cm) ≈ tick × 1.72
US_NEAR     EQU     12              ; 12 tick ≈ 21cm：比这更近 -> 原地右转避让
; ★ R3（2026-09-20 用户需求）：更近的一档 -> 直接刹停，决定权交给遥控
US_STOP     EQU     3               ; ★ R12：3 tick ≈ **5cm**：比这更近 -> 刹停 + 锁存（等遥控）
                                    ;   原值 6 tick ≈ 10cm。用户 2026-09-20 要求"近距离刹车保留、但距离调到最短"。
                                    ;   ⚠️ 只能取 1.72cm 的整数倍；取 3 而不是 2 的原因：
                                    ;     2 tick ≈ 3.4cm 已贴近 HC-SR04 的最小可靠量程（标称 2cm，
                                    ;     实际近距离受余振影响）——而**读不到回波会被当成"够远"**
                                    ;     （失效安全），那就等于不刹车了。**真机上要确认 5cm 还读得准**。
; ★★ R11（2026-09-20 用户实测报的 bug）：**滞回门限** ——
;   "进入"刹停用 US_STOP(≈10cm)，但**"解除"要退到更远** US_CLEAR(≈17cm)。
;   否则读数在 10cm 上下抖动时，锁存会"解除->又触发"反复跳（表现为反复响 + 手感突变）。
US_CLEAR    EQU     7               ; 7 tick ≈ 12cm：退到这儿才停止间歇响 / 解除刹停锁存的"静音"
                                    ;   ★ R12 随 US_STOP 一起收窄（原 10 tick ≈ 17cm）——
                                    ;     刹车门限压到 5cm 后，还要退到 17cm 才静音就不成比例了。
; ★ R4（2026-09-20）：锁存期间"持续间歇响"的间隔 —— 27*256 ≈ 6912 tick ≈ 0.7s
AVBEEP_H    EQU     27
US_MID      EQU     20              ; 20 tick ≈ 34cm：近于此 -> 原地右转绕开；更远 -> 前进
US_UPTO     EQU     20              ; 等回波上升沿的限时：20 tick ≈ 2ms（模块正常 0.5ms 内必回）
GEAR_DEFAULT EQU    3               ; 从 0 档按方向键时自动跳到这一档（60%）

; --- 红外 NEC 解码门限（单位 tick = 100us；直接沿用 remote.asm 实测可用的值）---
IR_LEAD_MIN EQU     70              ; 引导码低电平 9ms -> 70~120 都收
IR_LEAD_MAX EQU     120
IR_LEADHCAP EQU     60              ; 引导码高电平量到 6ms 就收手（完整帧 4.5ms 会先变低）
IR_LEADH_MIN EQU    25              ; 完整帧的引导码高电平至少 2.5ms，短于此判为噪声
IR_REP_MIN  EQU     12              ; 1.2ms <= 引导码高电平 < 2.5ms -> **NEC 重复帧**
                                    ;   （9ms 低 + 2.25ms 高，这是"按住不放"时发的码。
                                    ;    旧写法把它当"帧被拒"，于是松键停车永远刷不到时刻，
                                    ;    表现为按一下动一下就停 —— 本次一并修掉。）
IR_BIT_TH   EQU     11              ; 位高电平 >= 1.1ms -> 位1（位0=0.56ms 位1=1.69ms）
IR_BITCAP   EQU     12              ; 最后一位：只量到 1.2ms 就下结论（后面是空闲高电平）

; --- 松键停车：最后一次收帧后 3000 tick = 300ms 内没新帧 -> 视为松手，停车 ---
HOLD_TMO_H  EQU     11              ; 3000 = 0BB8H
HOLD_TMO_L  EQU     184
HOLD_MODE   EQU     1               ; 1 = 松键停车；0 = 锁定式（按一下持续动）
                                    ; 如果按住键时小车一颠一颠的，说明这只遥控器**不发
                                    ; NEC 重复帧** -> 把这里改成 0 重编即可

; --- "帧被拒"诊断行的限流：2000 tick = 200ms 最多报一行，避免刷屏 ---
ERRTMO_H    EQU     7
ERRTMO_L    EQU     208

; --- 遥控器键值（前 5 个已上机确认）---
KEY_FORWARD EQU     46H
KEY_BACK    EQU     15H
KEY_LEFT    EQU     44H
KEY_RIGHT   EQU     43H
KEY_STOP    EQU     40H
; ★★ 2026-09-20 **T0 实测确认**（烧 diag\irdecode.hex + tools\read_com_stream.ps1 抓串口）：
;    数字键 **7 = 42H** / **8 = 52H** / **9 = 4AH**
;    同一轮里顺带解出 `K=08`（数字键 4 = 减档），与 2026-09-19 的已知值吻合
;    -> 证明这次读数可信。原始日志：firmware\_serial_read.log
;    ⚠️ 这三个常量**目前还没有任何代码引用**（块⑦⑧ 未写），所以先填上**不花一个字节**。
;    ⚠️ 别再靠"码值表行序"推断按键名 —— 见下面 KEY_M1 的前车之鉴。
KEY_SPD_UP  EQU     5AH             ; 遥控数字键 "6" -> 加档（2026-09-19 上机验证 ✅）
KEY_SPD_DN  EQU     08H             ; 遥控数字键 "4" -> 减档（2026-09-19 上机验证 ✅）
KEY_MODE    EQU     1CH             ; 遥控数字键 "5" -> ★ R14 起**不再切模式**（功能已取消，见 KEY2MODE）
; ★★ R14（2026-09-20 用户需求）：**数字键 1/2/3 直接选三个模式**
KEY_M1      EQU     0CH             ; 数字键 "1" -> 手动模式
KEY_M2      EQU     18H             ; 数字键 "2" -> 寻光 L
KEY_M3      EQU     5EH             ; 数字键 "3" -> 循迹 t
; ⚠️ 这三个码值是**推断的**（不是实测）：依据是码值表第 6 行 `08/1c/5a` 已实测确认是
;    数字键 4/5/6（列 1/2/3）-> 数字键区按行排 -> 1/2/3 应为第 5 行 `0c/18/5e`。
;    **核实只要 30 秒**：烧 `diag\irdecode.hex`，点一下数字键 1 -> 数码管闪 `0` `c` 即对。
;    认错的后果很轻：不认识的键只走"不认识的键"分支（打印 + 电机不动，不会乱跑）。
; ⚠️ 注意：面板按键名不要照 docs\遥控器码值表.md 的"行↔按键"推断抄，那张表的行序是错的
;    （实测 `08/1c/5a` 对应面板 `4/5/6`，不是 `7/8/9`）。码值本身没问题，按键名以实测为准。
KEY_REC     EQU     42H             ; 数字键 "7" -> 块⑦ 录制开始/结束  ★ 2026-09-20 **实测确认**
KEY_PLAY    EQU     52H             ; 数字键 "8" -> 块⑧ 回放          ★ 2026-09-20 **实测确认**
KEY_CLR     EQU     4AH             ; 数字键 "9" -> 清空记录          ★ 2026-09-20 **实测确认**

ACT_NONE    EQU     0FFH            ; KEY2ACT 用：不认识的键
LASTCMD_NONE EQU    0FFH            ; "还没收过键"的哨兵值

; --- RAM（直接寻址区 30H 起；240 B 动作缓冲将来放片内扩展 RAM，不占这里）---
PWMC        DATA    30H             ; PWM 计数 0..19（中断维护）
DIRBITS     DATA    31H             ; 方向位（主循环写、中断读）
DUTY_A      DATA    32H             ; ENA 占空比 0..20
DUTY_B      DATA    33H             ; ENB 占空比 0..20
BUZP        DATA    34H             ; 蜂鸣器分频计数
BUZLEFT     DATA    35H             ; 蜂鸣器还剩几个半周期
GEAR        DATA    36H             ; 当前档位 0..5
KLAST       DATA    37H             ; 按键去抖状态：0 = 都松开，1 = S3 按着，2 = S4 按着
; --- 块②（红外）新增：38H 起 ---
TICK_L      DATA    38H             ; 系统时基低字节（100us，中断里维护）
TICK_H      DATA    39H             ; 系统时基高字节（65536 tick 溢出 = 6.55s）
STR_H       DATA    3AH             ; MEAS_LEVEL 的起始时刻
STR_L       DATA    3BH
DUR_H       DATA    3CH             ; MEAS_LEVEL 量到的时长（tick）
DUR_L       DATA    3DH
CAP_L       DATA    3EH             ; 量脉宽的限时；0 = 用默认 25.6ms
MLVL        DATA    3FH             ; 要量的电平：0=低 1=高
BITS        DATA    40H             ; 剩余位数
PTRIDX      DATA    41H             ; 当前字节序号 0..3
MASKB       DATA    42H             ; 当前位掩码
IB0         DATA    43H             ; addr
IB1         DATA    44H             ; ~addr
IB2         DATA    45H             ; cmd   <- 键值
IB3         DATA    46H             ; ~cmd
IRSTAT      DATA    47H             ; 0=完整帧 1=没等到边沿 2=帧被拒 3=重复帧
LASTCMD     DATA    48H             ; 上次处理过的键值
CURACT      DATA    49H             ; 当前动作码
LASTT_H     DATA    4AH             ; 最后一次收到红外帧的时刻
LASTT_L     DATA    4BH
LEDLO       DATA    4CH             ; 诊断：最近量到的引导码低电平（tick）
LEDHI       DATA    4DH             ; 诊断：最近量到的引导码高电平
LASTERR_H   DATA    4EH             ; 上次打印"帧被拒"的时刻（限流用）
LASTERR_L   DATA    4FH
; --- 块③④：模式状态机 / 寻光 ---
MODE        DATA    50H             ; 当前运行模式（MODE_*）
SHORTL      DATA    51H             ; 1 = 本次引导码高电平是"短的"（1.2~2.5ms）

DIAGCMD     DATA    52H             ; diag: key value to display
DIAGON      DATA    53H             ; diag: 0=off 1=show key 2=show reject list
DIAGT_H     DATA    54H             ; diag: step start tick
DIAGT_L     DATA    55H
DIAGSEQ     DATA    56H             ; diag: 0..7 = 半字节(bit0) + 值序号(bits1-2)
; --- 块③：S3 长按计时 ---
KPRESS_H    DATA    57H             ; S3 按下时刻（判断短按 / 长按）
KPRESS_L    DATA    58H
; --- 块⑤：循迹脱线计时 ---
LASTLN_H    DATA    59H             ; 最后一次"探头看到黑线"的时刻
LASTLN_L    DATA    5AH
; --- 块⑥（改全局）：避障开关状态 ---
AVOIDON     DATA    5BH             ; 1 = 全局避障已开启（S4 长按切换）
AVST        DATA    5CH             ; 避障闸门状态 AV_*（0 放行 / 1 右转避让 / 2 刹停锁存 / 3 遥控已接管）
; --- 块⑥ R4：锁存期间"持续间歇响"的计时 ---
BEEPT_H     DATA    5DH             ; 上一次"刹停提示音"的时刻（高字节）
BEEPT_L     DATA    5EH
ENAB        BIT     20H.0           ; 中断内部临时位
ENBB        BIT     20H.1
BUZB        BIT     20H.2           ; 1 = 蜂鸣器静音（PNP 高电平不导通）
DIAGNIB     BIT     20H.3           ; diag: 0=高半字节 1=低半字节

KEY_S3      BIT     P3.4            ; 低 = 按下（加档）
KEY_S4      BIT     P3.2            ; 低 = 按下（减档）
IR_IN       BIT     P3.3            ; 红外 0038 输出：空闲高，收到载波为低
LDR_LEFT    BIT     P1.1            ; 左光敏：见光 = 低（2026-09-18 实测，块④ 寻光用）
LDR_RIGHT   BIT     P1.0            ; 右光敏：见光 = 低
TRACK_L     BIT     P3.5            ; 循迹左探头 V2：压黑线 = 高（2026-09-18 实测，块⑤）
TRACK_R     BIT     P3.6            ; 循迹右探头 V3：压黑线 = 高
US_TRIG     BIT     P1.3            ; 超声波 HC-SR04 触发（输出，≥10us 高脉冲，块⑥）
US_ECHO     BIT     P1.2            ; 超声波回波（输入，高电平宽度 ∝ 距离）
; ★★ R13（2026-09-20）：**车头红外近距避障（冗余通道）**
;   车头那对红外对管（位号 V7/V4 —— **报告点名的"避障对管"**）。
;   ✅ **脚位已实测确认：`P3.7`**（2026-09-20 用户实测：烧 `diag\lightscan.hex`，
;      白纸贴车头那对管前 → 数码管跳 **`7`** = `P3.7`）。
;      ★ 这个脚原本被记为"未接传感器（实测不翻转）" —— **推翻**：当初是用黑胶带在
;        **循迹探头下面**试的，**从没在车头那对管子前面反射过**。
;        这是本项目"**没找到 ≠ 证明没有**"的第 3 次应验（前两次：P1.0 寻光、P1.0/P1.1 实测）。
;   ⚠️ 极性：这一类反射式探头"**有反射 = 低**"（与循迹探头 V2/V3 同族，已实测确认）。
;      若实测相反（贴上去不响、拿开才响）→ 把 AV_GATE 里两处 `JNB IR_AVOID` 改成 `JB`。
IR_AVOID    BIT     P3.7            ; 车头红外对管节点（极性由 IR_INV 上电校准，见下）
IR_INV      DATA    5FH             ; ★ R13b：0 = "低电平表示检测到"；1 = "高电平表示检测到"
                                    ;   由**上电时读一次 P3.7** 自动定（见初始化里的 IRC_DONE）

;=========================================================================
; ★★ 块⑦⑧（示教录制/回放）：新增 RAM（2026-09-20 设计冻结 §5.2）
;-------------------------------------------------------------------------
; ★★★ 关键：**绝不能放 60H~7FH** —— MAIN 里 `MOV SP,#60H`，8051 的栈**向上增长**，
;      61H 起立刻被 ACALL / 中断的 PUSH 占用。文档里"60H~7FH 还剩 32B"的说法**是错的**。
;      真正空闲的直接寻址区 = **21H~2FH（15 字节）+ 位区 20H.4~20H.7（4 位）**，
;      本块把它们**恰好用满**（对照表见设计冻结 §5.2）。
;      将来若还要加变量，只能用 XRAM 保留区 0x00F0~0x00FF，**别再往 30H~5FH 挤**。
;      也**不要用 IDATA 80H~FFH**：栈从 60H 向上长，深度超 31 字节就会踩进 80H。
; ⚠️ 240 B 的动作记录**不在这里**，在片内扩展 RAM（MOVX @DPTR），见块⑦。
;=========================================================================
; --- 20H 位区（20H.0~.3 已被 ENAB / ENBB / BUZB / DIAGNIB 占用）---
RECON       BIT     20H.4           ; 1 = 正在录制（**手动模式上的叠加位**，不是模式）
PLAYERR     BIT     20H.5           ; 1 = 上次回放因"安全"终止（供提示/诊断）
RECFULL     BIT     20H.6           ; 1 = 已到 80 条上限
SPARE0      BIT     20H.7           ; 保留
; --- 21H 起：10ms 时基（**中断里维护**，主循环只读，且必须用 MS10_GET 原子读）---
MSDIV       DATA    21H             ; 10ms 分频计数 0..99（T0_ISR 里 ++）
MS10_L      DATA    22H             ; 10ms 时基低字节（自由运行）
MS10_H      DATA    23H             ; 10ms 时基高字节（65536×9.983ms ≈ 654s 回绕）
; --- 24H 起：录制层 ---
PACK        DATA    24H             ; 待提交记录的 (Action<<4)|Gear，**合并判定只看这一个字节**
CUR_DUR_L   DATA    25H             ; 当前记录**已累计**时长（低字节）
CUR_DUR_H   DATA    26H             ; 当前记录已累计时长（高字节）
SAMP_L      DATA    27H             ; 上次采样时刻（低）
SAMP_H      DATA    28H             ; 上次采样时刻（高）
RECN        DATA    29H             ; 已提交记录数 0..80
; --- 2AH 起：回放层 ---
PLAYIDX     DATA    2AH             ; 回放索引 0..79
PLAY_DUR_L  DATA    2BH             ; 当前回放条目时长（低）
PLAY_DUR_H  DATA    2CH             ; 当前回放条目时长（高）
PLAY_T0_L   DATA    2DH             ; 当前回放条目起始时刻（低）
PLAY_T0_H   DATA    2EH             ; 当前回放条目起始时刻（高）
PLAY_GEAR0  DATA    2FH             ; 进入回放前的档位（退出时恢复，见设计冻结 §3.3）

            ORG     0000H
            LJMP    MAIN

            ORG     000BH               ; Timer0 中断向量
            LJMP    T0_ISR

            ORG     0030H
;=========================================================================
; 初始化
;=========================================================================
MAIN:
            MOV     SP,     #60H
            MOV     PWMC,   #0
            MOV     DIRBITS,#DIR_STOP
            MOV     DUTY_A, #0
            MOV     DUTY_B, #0
            MOV     BUZP,   #0
            MOV     BUZLEFT,#0
            SETB    BUZB                ; 上电静音
            MOV     GEAR,   #0
            MOV     KLAST,  #0
            MOV     TICK_L, #0          ; 时基从 0 开始
            MOV     TICK_H, #0
            MOV     IRSTAT, #1
            MOV     LASTCMD,#LASTCMD_NONE
            MOV     CURACT, #ACT_STOP
            MOV     MODE,   #MODE_MANUAL ; ★ 必清零：内部 RAM 上电是随机值，不清可能一开机就在别的模式
            MOV     AVOIDON,#1          ; 全局避障上电默认开启（长按 S4 可关）
            MOV     AVST,   #AV_FREE    ; 避障闸门状态（开机先放行，主循环第一趟就会刷新）
            MOV     BEEPT_H, #0         ; R4：锁存提示音计时（被读的变量一律显式清零）
            MOV     BEEPT_L, #0
            MOV     DIAGON,   #0        ; diag: 初始不显示
            MOV     LASTERR_H, #0
            MOV     LASTERR_L, #0
            MOV     LEDLO,  #0
            MOV     LEDHI,  #0
            MOV     P0,     #0C0H       ; 上电先停车（ENA/ENB 拉低）
            MOV     P1,     #0FFH
            MOV     P2,     #DISP_0
            MOV     P3,     #0FFH

            ; ---- ★★ R13b（2026-09-20）：**上电自动校准红外极性** ----
            ;   为什么：车头那对红外对管（P3.7）的极性**改了两版都不对**（v20 用 JNB、
            ;   v21 用 JB，都出现"车不动"）—— 与其继续猜硬件，不如**上电时自己测一次**：
            ;   以"**上电那一刻 P3.7 的电平**"作为"**无反射（前面没东西）**"的参考电平，
            ;   之后 **"检测到" ⇔ 当前电平与参考相反**。
            ;   ⇒ 不管硬件是"有反射=低"还是"有反射=高"，**都自动正确**。
            ;   ★ 前提：**上电时车头 1~2cm 内没有东西**（正常摆放就是如此）。
            ;   ★ 最坏情况（上电时正好贴着东西）：红外这一项**失效**，
            ;     而**不会把车锁死** —— 失效方向是安全的 ✅
            MOV     IR_INV, #0          ; 默认：上电读到高 -> 高=无反射 -> 检测到=低
            JB      IR_AVOID, IRC_DONE  ; 上电读到高 -> 保持 IR_INV=0
            MOV     IR_INV, #1          ; 上电读到低 -> 低=无反射 -> 检测到=高
IRC_DONE:

            ; ---- ★★ 块⑦⑧（示教录制/回放）：新变量一律**显式清零** ----
            ;   项目铁律：内部 RAM 上电是随机值，**凡是被"读"的变量都要显式清零**
            ;   （历史上 `MODE` / `AVOIDON` / `AVBLK` 都因漏清踩过坑）。
            ;   ★ 这里不清的具体后果：上电可能直接就"在录制"或"在回放"，
            ;     而且 `RECN` 是随机值 -> 回放会去读 XRAM 里的垃圾（虽不越界，但车会乱跑）。
            ;   ⚠️ 必须在 `SETB EA` / `SETB TR0` **之前**清，否则中断已经在改 MSDIV/MS10。
            CLR     RECON
            CLR     PLAYERR
            CLR     RECFULL
            CLR     SPARE0
            MOV     MSDIV,      #0
            MOV     MS10_L,     #0
            MOV     MS10_H,     #0
            MOV     PACK,       #0
            MOV     CUR_DUR_L,  #0
            MOV     CUR_DUR_H,  #0
            MOV     SAMP_L,     #0
            MOV     SAMP_H,     #0
            MOV     RECN,       #0
            MOV     PLAYIDX,    #0
            MOV     PLAY_DUR_L, #0
            MOV     PLAY_DUR_H, #0
            MOV     PLAY_T0_L,  #0
            MOV     PLAY_T0_H,  #0
            MOV     PLAY_GEAR0, #0

            ; ---- 串口 9600 8N1（T1 方式2）+ T0 方式2 做 100us 时基 ----
            MOV     TMOD,   #22H        ; 高半字节 T1 方式2，低半字节 T0 方式2
            MOV     TH1,    #0FDH       ; 11059200/(384*3) = 9600
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H
            MOV     PCON,   #00H
            SETB    TR1
            MOV     TH0,    #T0_RELOAD
            MOV     TL0,    #T0_RELOAD
            SETB    ET0
            SETB    EA
            SETB    TR0
            ACALL   STAMP_NOW           ; 让松键超时从"现在"开始算

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR
            ACALL   APPLY_GEAR
    IF DIAG_IR
            MOV     P2,     #DISP_8     ; 上电提示：显示 "8"
            MOV     A,      #BEEP_TICKS
            ACALL   BEEP
            ACALL   DIAG_DLY
            MOV     A,      #BEEP_TICKS
            ACALL   BEEP
            ACALL   DIAG_DLY
            MOV     A,      #BEEP_TICKS
            ACALL   BEEP
            ACALL   DIAG_DLY
            ACALL   SHOW_STATE          ; 恢复档位显示
    ENDIF          ; 档位 0 = 停车 + 显示 "0"

;=========================================================================
; 主循环：红外遥控（块②）+ 板载按键调速（块①）
;   顺序很重要：IR_RECV 最多阻塞 25.6ms（等下降沿），这期间按键不响应，
;   但 25ms 量级的延迟对按键手感没有影响，而"一直在听红外"是必须的
;   （否则会从引导码中间才开始量，脉宽偏短，整帧被拒）。
;=========================================================================
MAIN_LOOP:
    IF DIAG_IR
            ACALL   DIAG_UPDATE         ; diag: 推进键值显示阶段
    ENDIF
            ; ---- ★★ M1b（块⑧）：**回放走最前面的独立分支** ----
            ;   ★★ 为什么必须在 AV_GATE **之前**就跳走（设计冻结 §1.1 冲突 C1）：
            ;      AV_GATE 在 5~21cm 的动作是"把动作**改写成原地右转**绕过去"，
            ;      而回放要求"**遇障立即停车并终止、不擅自改变示教路径**" —— **语义正好相反**。
            ;      走独立分支 ⇒ **AV_GATE 一行都不用改**，回放自己用 PLAY_SAFETY 判。
            ;   ★ 顺带也绕开了 IR_KEYSCAN/KEY_SCAN（长按判定会阻塞最多 1s，会毁掉节拍）。
            ;   ★ MODE≠PLAY 时只多两条指令，**行为与改动前逐条一致**。
            MOV     A,      MODE
            CJNE    A,      #MODE_PLAY, ML_NOPLAY
            LJMP    PLAY_STEP
ML_NOPLAY:
            ; ---- ★ 避障闸门（块⑥）：先测一次，只更新 AVST ----
            ;   ★ 作用范围：手动 / 寻光（循迹模式不参与，见 AV_GATE 里的 R2 说明）
            ;   ★ 三档（R3）：≥21cm 放行 / 10~21cm 右转避让 / <10cm 刹停+锁存（等遥控）
            ;   ★ 不跳过任何输入处理：遥控/按键照常响应（响铃、显示、记动作），
            ;     由 MOTOR_SET_ACT 统一在出口决定"改写动作 / 刹停 / 放行" —— 否则有障碍时遥控就"聋"了。
            ACALL   AV_GATE

            ; ---- ★★ M1a（块⑦）：**录制采样**，每趟主循环做一次 ----
            ;   位置：放在 AV_GATE **之后**、模式分派**之前** ——
            ;   这样录到的是"避障闸门已经作用过一轮"的现场，也保证手动/寻光/循迹
            ;   任何模式下只要 RECON=1 都会被采样。
            ;   ★ RECON=0 时只多一条 JNB，**行为与改动前逐条一致**。
            ;   ⚠️ REC_SAMPLE 自己按 10ms 时基判断"到点了没有"，
            ;      不需要（也不能）依赖主循环周期 —— 主循环 ≈26ms，靠它数节拍会差 26%。
            ;   ⚠️ RECON 是**位**（BIT 20H.4），只能用 JB/JNB/SETB/CLR，**不能 MOV A,RECON**。
            JNB     RECON,  ML_NOREC
            LCALL   REC_SAMPLE          ; ★ 必须 LCALL：块⑦ 在文件最后，已跨过 2KB 边界，
ML_NOREC:                               ;   ACALL 只在本页内跳（跨页会报 TARGET OUT OF RANGE）

            MOV     A,      MODE
            JZ      ML_MANUAL           ; 手动模式 -> 收红外遥控
            ; ---- 非手动模式（块③④⑤）：跑模式动作；遥控方向键不参与 ----
            CJNE    A,      #MODE_LIGHT, ML_NM2
            ACALL   LIGHT_STEP          ; 块④ 寻光一步
            SJMP    ML_NOMODE
ML_NM2:
            CJNE    A,      #MODE_TRACK, ML_NOMODE
            ACALL   TRACK_STEP          ; 块⑤ 循迹一步
ML_NOMODE:
            ; ---- ★ 停止最高优先：非手动模式下仍收听遥控，只认"停止"键 ----
            ACALL   IR_RECV
            MOV     A,      IRSTAT
            JNZ     ML_NM_KS            ; 不是完整帧 -> 不管
            MOV     A,      IB2
            CJNE    A,      #KEY_STOP, ML_NM_SPD
            MOV     MODE,   #MODE_MANUAL    ; 急停 -> 回手动（模式动作不再驱动电机）
            MOV     CURACT, #ACT_STOP
            MOV     R7,     #0
            MOV     A,      #ACT_STOP
            ACALL   MOTOR_SET_ACT
            MOV     LASTCMD,#LASTCMD_NONE
            ACALL   SHOW_STATE
            MOV     A,      #BEEP_TICKS
            ACALL   BEEP
            SJMP    ML_NM_KS
            ; ---- ★ 遥控加减档（全局功能）：非手动模式下也能调档 ----
            ;     复用板载按键那条变档路径 ML_APPLY（它会做提示音 + 非手动模式刷新模式代号）
ML_NM_SPD:
            ; ★★ R14：数字键 1/2/3 **直接选模式**（非手动模式下也生效 —— 可以直接按 1 退回手动）
            ACALL   KEY2MODE
            JNC     ML_NM_SPD0
            CJNE    A,      MODE, ML_NM_GOTO
            SJMP    ML_NM_KS            ; 已经就是这个模式 -> 什么都不做
ML_NM_GOTO: LJMP    MODE_GOTO
ML_NM_SPD0:
            CJNE    A,      #KEY_SPD_UP, ML_NM_SPD2
            MOV     A,      GEAR
            CJNE    A,      #MAXGEAR, ML_NM_UP
            SJMP    ML_NM_KS            ; 已最高档
ML_NM_UP:
            INC     GEAR
            LJMP    ML_APPLY
ML_NM_SPD2:
            CJNE    A,      #KEY_SPD_DN, ML_NM_KS
            MOV     A,      GEAR
            JZ      ML_NM_KS            ; 已 0 档
            DEC     GEAR
            LJMP    ML_APPLY
ML_NM_KS:
            LJMP    IR_KEYSCAN          ; 按键处理（长按 S3 也能切模式）
ML_MANUAL:
            ACALL   IR_RECV             ; 收一帧（出口 IRSTAT 见 IR_RECV 注释）
            MOV     A,      IRSTAT
            JZ      IR_FULL             ; 0 = 完整帧
            CJNE    A,      #3,     IR_NOTRPT
            ACALL   STAMP_NOW
    IF DIAG_IR
            MOV     A,      #BEEP_KEY
            ACALL   BEEP                ; diag: 证明收到了重复帧
    ENDIF           ; 3 = 重复帧：只刷新"还按着"的时刻
            LJMP    IR_HOLDCHK
IR_NOTRPT:
            CJNE    A,      #2,     IR_HOLDCHK
            ACALL   IR_ERRPR            ; 2 = 见到边沿但没解成 NEC：限流报实测脉宽
    IF DIAG_IR
            ACALL   DIAG_ERRSHOW        ; diag: 2 声短响 + 显示引导码低电平
    ENDIF
            LJMP    IR_HOLDCHK

; ---- 完整帧：解出键值 -> 动作 ----
IR_FULL:
            ACALL   STAMP_NOW
            ; ★★ 2026-09-20 修 BUG（用户实测报的）：这里**不再做"同键去重"**。
            ;   原写法是：
            ;       MOV  A, IB2 / CJNE A, LASTCMD, IR_NEWKEY / LJMP IR_HOLDCHK
            ;   —— 它把"**同一个键的第二次真按键**"也当成重复帧跳过了（DO_KEY 根本不执行）。
            ;   **实测症状**：遥控加/减档（数字键 6 / 4）**只能调一次**，
            ;   必须按一下别的键（比如"前进"）才能再调；模式键连按同理也失效。
            ;
            ; ★ 为什么可以放心去掉：**重复帧根本到不了这里** ——
            ;   "按住不放"时遥控器发的是 NEC 重复帧（9ms 低 + 2.25ms 高，之后不再变低），
            ;   IR_RECV 里靠"引导码高电平会不会变低"就把它判成 IRSTAT = 3，
            ;   走上面 `JZ IR_FULL` 之前那条 `LJMP IR_HOLDCHK`（见 IR_REPEAT）。
            ;   所以**能进 IR_FULL 的，必定是"完整的、刚按下去的"帧**。
            ;   （"按住才转"能正常工作本身就证明了重复帧被单独识别 —— 否则按住会连发。）
            ;
            ; ★ 这也正是 R5 想要的区分，而且是**更干净的实现**：
            ;     · **按住不放**（IRSTAT=3，到不了这里）-> 不会误解除刹停锁存
            ;     · **松开再按**  （完整帧，到这里）    -> 解除锁存、照遥控走
            ;   所以 R5 当时加的 `AVST == AV_HOLD` 特判**一并删掉**（不再必要）。
            MOV     A,      IB2
            MOV     LASTCMD, A          ; 仍记下来（诊断/兼容用；已不参与去重）
            ACALL   DO_KEY
    IF DIAG_IR
            ACALL   DIAG_KEYSHOW        ; diag: 记录键值，开始轮流显示
    ENDIF              ; 打印 + 按键值动作 + 提示音

; ---- 松键停车（HOLD_MODE=1）：300ms 内没有新帧就视为松手 ----
;   ★ 2026-09-20 按用户要求：**前进/后退豁免这个超时** —— 按一下就一直走，
;     直到按「停止」或按别的方向键（左转/右转仍是"按住才转"，松手就停）。
IR_HOLDCHK:
    IF HOLD_MODE
            MOV     A,      CURACT
            JZ      IR_KEYSCAN          ; 本来就在停 -> 不用管
            ; ---- ★ R6（2026-09-20 用户需求）：**刹停接管后，前进/后退也改成"按住才走"** ----
            ;   `AV_HUMAN` = "太近刹停锁存已被遥控解除、但还没脱离 ≤10cm 的危险区"
            ;   （距离回到 ≥ US_STOP 才会变回 AV_FREE）。
            ;   在这段时间里取消"锁定式豁免" -> 前进/后退松手约 0.3s 就停（更安全）；
            ;   一旦脱离危险区，恢复正常锁定式（按一下就一直走）。
            MOV     A,      AVST
            CJNE    A,      #AV_HUMAN, HC_LOCK
            LJMP    HC_TMO              ; ★ 接管中 -> 直接去判 0.3s 超时
HC_LOCK:
            MOV     A,      CURACT
            ; ★★ R10（2026-09-20 用户需求）：**"锁定式"只留给"前进"了** ——
            ;   用户要求"倒车改为按住倒车"，所以 **后退不再豁免** 0.3s 超时。
            ;   于是现在：**前进 = 按一下一直走**；**后退 = 按住才走、松手约 0.3s 停**；
            ;   左转/右转 = 按住才转（本来就是）；弧线 = 按住才画（见 R9）。
            ;   ★ 顺带的好处：「遥控没电/超范围时车不会自己停」这个老副作用（风险 4）
            ;     现在**只影响"前进"**了，后退松开就停。
            CJNE    A,      #ACT_FORWARD, HC_TMO
            LJMP    IR_KEYSCAN          ; 前进：锁定式，不因松手停车
HC_TMO:
            ACALL   TICK_GET            ; R4:R5 = 现在
            MOV     A,      R5
            CLR     C
            SUBB    A,      LASTT_L
            MOV     R6,     A
            MOV     A,      R4
            SUBB    A,      LASTT_H
            MOV     R7,     A            ; R7:R6 = 距上次收帧的 tick 数
            MOV     A,      R7
            CLR     C
            SUBB    A,      #HOLD_TMO_H
            JC      IR_KEYSCAN          ; 还没到 300ms
            JNZ     IR_TIMEOUT
            MOV     A,      R6
            CLR     C
            SUBB    A,      #HOLD_TMO_L
            JC      IR_KEYSCAN
IR_TIMEOUT:
            ; ---- ★ R9（2026-09-20）：弧线转弯"松手" -> **回到前进**，不是停车 ----
            ;   理由：前进是**锁定式**（按一下就一直走），弧线只是临时叠加；
            ;   所以画完弧松手应该继续直行（用户选的）。其余动作照旧 -> 停车。
            MOV     A,      CURACT
            CJNE    A,      #ACT_ARC_L, IT_CHK2
            MOV     A,      #ACT_FORWARD
            SJMP    IT_GO
IT_CHK2:
            MOV     A,      CURACT
            CJNE    A,      #ACT_ARC_R, IT_CHK3
            MOV     A,      #ACT_FORWARD
            SJMP    IT_GO
IT_CHK3:
            MOV     A,      #ACT_STOP
IT_GO:
            MOV     CURACT, A
            MOV     R7,     #0
            CJNE    A,      #ACT_STOP, IT_RUN
            SJMP    IT_APPLY
IT_RUN:
            MOV     R7,     GEAR            ; 弧线松手 -> 用当前档位继续前进
IT_APPLY:
            ACALL   MOTOR_SET_ACT
            ACALL   SHOW_STATE          ; 显示也要跟着更新（否则 D3 还亮着"在动"）
            MOV     LASTCMD,#LASTCMD_NONE   ; 允许同一个键再按一次
            ; ---- ★★ R11（2026-09-20 用户实测报的 bug）：R6 的"接管后按住才走"**只用一次** ----
            ;   症状："前进偶尔会中断、不响、按住不放就能一直走"。
            ;   机理：`AVST == AV_HUMAN` 时前进**失去锁定豁免** -> 松手 0.3s 就停；
            ;   而 `AV_HUMAN` 要等距离回到 ≥ US_STOP 才清除 —— 只要车前方那个读数
            ;   **一直在 10cm 以下**（台架上很容易是墙/盒子/显示器），它就**永不清除**
            ;   -> 前进从此永久变成"按住才走"，而且因为是 AV_HUMAN 所以**不响**。
            ;   ★ R6 的本意是"**刚被刹停、你要挪开时小心点**"，不是"前方有东西就永久改手感"。
            ;     所以这里在**本次动作结束**（松手超时）时把它收回 AV_FREE -> 避障重新武装。
            ;   ★ 之后若前方**确实**还有 <10cm 的东西，再按前进会**响一声 + 刹停锁存**
            ;     （明确、不静默）—— 这才是"太近就刹停"该有的样子。
            MOV     A,      AVST
            CJNE    A,      #AV_HUMAN, IT_NORST
            MOV     AVST,   #AV_FREE
IT_NORST:
            MOV     DPTR,   #MSG_RELEASE
            ACALL   PRINT_STR
    ENDIF

; ---- 板载按键（块①）：S3 短按加档 / S4 短按减档；S3 长按切模式 / S4 长按避障开关 ----
IR_KEYSCAN:
            ACALL   KEY_SCAN            ; 出: A = 0 无 / 1 S3短(加档) / 2 S4短(减档) / 3 S3长(切模式) / 4 S4长(避障开关)
            JNZ     KS_NOTNONE
            LJMP    MAIN_LOOP           ; 无事件（MAIN_LOOP 太远，短跳不够射程）
KS_NOTNONE:
            CJNE    A,      #3,     KS_NOTLONG
            ; ★★ M7（决定 D3）：**录制中长按 S3 也不许切模式**（遥控 1/2/3 那条已在 DO_KEY 拦掉）
            JB      RECON,  KS_BLKMS
            LJMP    MODE_SWITCH         ; 块③：S3 长按 -> 切模式
KS_BLKMS:
            MOV     A,      #BEEP_KEY   ; 录制中：拒绝，响两声
            ACALL   BEEP
            LCALL   D_20MS              ; ★ LCALL：已跨 2KB 页
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            LJMP    MAIN_LOOP
KS_NOTLONG:
            CJNE    A,      #4,     KS_NOT4
            ACALL   AVOID_TOGGLE        ; 块⑥：S4 长按 -> 全局避障开/关
            LJMP    MAIN_LOOP
KS_NOT4:
    IF DIAG_IR
            ; 诊断显示时，S3/S4 当翻页键用：S3 下一个半字节，S4 上一个半字节
            MOV     R6,     A               ; 暂存按键
            MOV     A,      DIAGON
            JZ      KS_GEAR
            MOV     A,      R6
            CJNE    A,      #1,     KS_BACK
            MOV     A,      DIAGSEQ         ; S3 = 前进
            INC     A
            ANL     A,      #07H
            MOV     DIAGSEQ, A
            SJMP    KS_BEEP
KS_BACK:
            MOV     A,      DIAGSEQ         ; S4 = 后退
            DEC     A
            ANL     A,      #07H
            MOV     DIAGSEQ, A
KS_BEEP:
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            LJMP    MAIN_LOOP
KS_GEAR:
            MOV     A,      R6
    ENDIF

            CJNE    A,      #1,     ML_DOWN
            MOV     A,      GEAR
            CJNE    A,      #MAXGEAR, ML_UP
            LJMP    MAIN_LOOP           ; 已经最高档
ML_UP:
            INC     GEAR
            SJMP    ML_APPLY

ML_DOWN:
            MOV     A,      GEAR
            JNZ     ML_DEC
            LJMP    MAIN_LOOP           ; 已经 0 档，不动
ML_DEC:
            DEC     GEAR

ML_APPLY:
            MOV     A,      #BEEP_TICKS
            ACALL   BEEP                ; 变档提示音

            MOV     A,      MODE
            JNZ     ML_MODEGE           ; 非手动模式：档位交给模式动作用，这里不动电机
            MOV     A,      GEAR
            JZ      ML_GEAR0            ; ★ P4：档位 0 -> 走 APPLY_GEAR 的停车出口（它会清 CURACT）
            MOV     A,      CURACT
            JNZ     ML_ACT              ; 遥控动作正在跑 -> 只换速度，不改方向
            ; ---- 没有遥控动作：本地档位就是"前进"（块① 的验证方式保持不变）----
ML_GEAR0:
            ACALL   APPLY_GEAR
            SJMP    ML_PRINT
ML_ACT:
            MOV     R7,     GEAR
            ACALL   MOTOR_SET_ACT       ; 用新档位重新套用当前动作
            ACALL   SHOW_STATE
            SJMP    ML_PRINT
ML_MODEGE:
            ACALL   SHOW_MODE           ; 非手动模式：数码管仍显示模式代号
ML_PRINT:
            ACALL   PRT_GEAR            ; 串口打一行（调试用）
            LJMP    MAIN_LOOP

;=========================================================================
; APPLY_GEAR —— 把当前档位套用到电机 + 数码管
;   档位 0   -> 停车（ENA/ENB 都拉低），数码管 "0"，D3 灭
;   档位 1~5 -> 前进，占空比 20/40/60/80/100%，数码管显示档位，D3 亮
;=========================================================================
APPLY_GEAR:
            MOV     A,      GEAR
            JZ      AG_STOP

            ; ★ R3：刹停锁存期间（AV_HOLD），**本地加档也不许把车开起来** ——
            ;   锁存的语义是"决定权在遥控手里"，所以只有遥控能解除它。
            MOV     A,      AVST
            CJNE    A,      #AV_HOLD, AGP_GO
            SJMP    AG_STOP             ; 只更新档位显示（D3 灭 = 没在动）
AGP_GO:

            ; ★★ 2026-09-20 联调 P4：这里必须同时维护 CURACT！
            ;   AV_GATE 用 "CURACT != 0" 判断"本来就在动"，来决定要不要主动避让。
            ;   原来这段直接写电机寄存器、从不设 CURACT -> 手动模式用"档位即前进"
            ;   驱动时 CURACT 恒为 0 -> 避障闸门直接放行（实测：车不躲，见联调 P4）。
            ;   写电机的只有 APPLY_GEAR 和 MOTOR_SET_ACT 两处，这里补上就闭环了。
            MOV     CURACT, #ACT_FORWARD

            ; ---- 前进 + 该档占空比 ----
            MOV     A,      GEAR
            DEC     A                   ; 1..5 -> 0..4
            MOV     DPTR,   #DUTYTAB
            MOVC    A,      @A+DPTR
            MOV     DUTY_A, A
            MOV     DUTY_B, A
            MOV     DIRBITS,#DIR_FWD

            ; ---- 数码管显示档位，D3 亮（bit0 = 0）----
            MOV     A,      GEAR
            MOV     DPTR,   #GEARTAB
            MOVC    A,      @A+DPTR
            CLR     ACC.0
            MOV     P2,     A
            RET

AG_STOP:
            MOV     CURACT, #ACT_STOP   ; ★ P4：真停车了就要清掉，否则 D3 会误亮"在动"
            MOV     DUTY_A, #0
            MOV     DUTY_B, #0
            MOV     DIRBITS,#DIR_STOP
            MOV     A,      GEAR
            MOV     DPTR,   #GEARTAB
            MOVC    A,      @A+DPTR
            MOV     P2,     A           ; 档位 0 的段码 bit0 已经是 1 = D3 灭
            RET

;=========================================================================
; MOTOR_SET_ACT —— 报告里的 Motor_Set(action) 统一出口
;   入：A = 动作码（ACT_*）；R7 = 速度档 1..5（0 = 停）
;   出：无（只改 DIRBITS / DUTY_A / DUTY_B，真正的输出由中断完成）
;   用 R6 暂存动作码（不用 PUSH/POP，避免任何路径漏掉 POP 把栈搞歪）
;   ★ 两轮同速；**差速只用在"弧线转弯"**（ACT_ARC_L / ACT_ARC_R，2026-09-20 R9），
;     即"两轮都正转 + 内轮占空比按 `ARCTAB` 调小"，其余动作仍是两轮同速。
;=========================================================================
MOTOR_SET_ACT:
            MOV     R6,     A               ; 动作码暂存到 R6
            MOV     A,      R7
            JZ      MSA_IDLE                ; 速度 0 -> 停（本来就没让动，避障也不用管）
            ; ---- ★ 避障闸门（块⑥）：按 AVST 四态决定要不要改写动作 ----
            MOV     A,      AVST
            JZ      MSA_DO                  ; 0 = AV_FREE  放行，按原动作
            DEC     A
            JZ      MSA_TURN                ; 1 = AV_TURN  近区 -> 改写成"原地右转避让"
            DEC     A
            JZ      MSA_HOLD                ; 2 = AV_HOLD  太近 -> 强制刹停（锁存）
            SJMP    MSA_DO                  ; 3 = AV_HUMAN 遥控已接管 -> 放行
MSA_TURN:
            MOV     R6,     #ACT_RIGHT
MSA_DO:
            MOV     A,      R7
            DEC     A                       ; 1..5 -> 0..4
            MOV     DPTR,   #DUTYTAB
            MOVC    A,      @A+DPTR
            MOV     DUTY_A, A
            MOV     DUTY_B, A

            ; ---- ★ R9：弧线转弯 = 两轮都正转 + 内外轮不同占空比 ----
            ;   上面已把 DUTY_A / DUTY_B 都设成"外轮 = 当前档位"，
            ;   这里只把**内轮**按 `ARCTAB` 调小（当前 = 外轮 3/4）；DIRBITS 用 **DIR_FWD**（不是原地转的 DIR_LEFT/RIGHT）。
            ;   左右轮映射：DUTY_A = 左轮（ENA / IN1-IN2）、DUTY_B = 右轮（ENB / IN3-IN4），
            ;   由 DIR_LEFT = IN2+IN3（原地左转 = 左轮反转 + 右轮正转）推得。
            MOV     A,      R6
            CJNE    A,      #ACT_ARC_L, MSA_ARC2
            MOV     A,      R7              ; 左弧线：内轮 = 左轮（DUTY_A）
            DEC     A
            MOV     DPTR,   #ARCTAB
            MOVC    A,      @A+DPTR
            MOV     DUTY_A, A
            MOV     DIRBITS,#DIR_FWD
            RET
MSA_ARC2:
            CJNE    A,      #ACT_ARC_R, MSA_ARCEND
            MOV     A,      R7              ; 右弧线：内轮 = 右轮（DUTY_B）
            DEC     A
            MOV     DPTR,   #ARCTAB
            MOVC    A,      @A+DPTR
            MOV     DUTY_B, A
            MOV     DIRBITS,#DIR_FWD
            RET
MSA_ARCEND:
            MOV     A,      R6
            CJNE    A,      #ACT_FORWARD, MSA_2
            MOV     DIRBITS,#DIR_FWD
            RET
MSA_2:
            CJNE    A,      #ACT_BACK,    MSA_3
            MOV     DIRBITS,#DIR_BACK
            RET
MSA_3:
            CJNE    A,      #ACT_LEFT,    MSA_4
            MOV     DIRBITS,#DIR_LEFT
            RET
MSA_4:
            CJNE    A,      #ACT_RIGHT,   MSA_IDLE
            MOV     DIRBITS,#DIR_RIGHT
            RET

MSA_HOLD:                               ; ★ R3：太近 -> 刹停（锁存，等遥控）
            MOV     CURACT, #ACT_STOP   ; ★ 真停了：CURACT 也要归零，
                                        ;   否则 寻光/循迹 每趟都会把 CURACT 设回动作码，
                                        ;   虽然车不动但 D3 会误亮"在动"
MSA_IDLE:                               ; 停止：两路断电
            MOV     DIRBITS,#DIR_STOP
            MOV     DUTY_A, #0
            MOV     DUTY_B, #0
            RET

;=========================================================================
; KEY_SCAN —— 按键扫描（带 20ms 去抖 + 松手才认下一次）
;   出：A = 0 无事件 / 1 加档（S3 短按）/ 2 减档（S4）/ 3 = S3 长按（块③ 切模式）
;   ★ 块③：S3 按下后**计时等松手** —— 松手 <1s = 短按加档；按住 ≥1s = 长按切模式。
;     （不是"按下就加档"：否则长按切模式会顺带多加一档。）
;=========================================================================
KEY_SCAN:
            MOV     A,      KLAST
            JNZ     KS_RELWAIT          ; 上一次还按着 -> 先等松手

            JNB     KEY_S3, KS_S3
            JNB     KEY_S4, KS_S4
            CLR     A
            RET

KS_S3:
            LCALL   D_20MS              ; ★ LCALL：加了块⑦⑧ 之后已跨 2KB 页，ACALL 够不着
            JB      KEY_S3, KS_NONE     ; 20ms 后已经松开 -> 抖动，不算
            ACALL   TICK_GET            ; 记下按下时刻
            MOV     KPRESS_H, R4
            MOV     KPRESS_L, R5
KS_S3_WAIT:
            JB      KEY_S3, KS_S3_SHORT ; 松手 -> 短按
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      KPRESS_L
            MOV     A,      R4
            SUBB    A,      KPRESS_H
            CLR     C
            SUBB    A,      #LP_TMO_H
            JC      KS_S3_WAIT          ; 还没到 1s
            MOV     KLAST,  #3          ; 长按：标记，等松手才复位
            MOV     A,      #3
            RET
KS_S3_SHORT:
            MOV     KLAST,  #1
            MOV     A,      #1          ; 短按 = 加档
            RET

KS_S4:
            LCALL   D_20MS              ; ★ LCALL：已跨 2KB 页
            JB      KEY_S4, KS_NONE     ; 20ms 后已经松开 -> 抖动，不算
            ACALL   TICK_GET            ; 记下按下时刻
            MOV     KPRESS_H, R4
            MOV     KPRESS_L, R5
KS_S4_WAIT:
            JB      KEY_S4, KS_S4_SHORT ; 松手 -> 短按
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      KPRESS_L
            MOV     A,      R4
            SUBB    A,      KPRESS_H
            CLR     C
            SUBB    A,      #LP_TMO_H
            JC      KS_S4_WAIT          ; 还没到 1s
            MOV     KLAST,  #4          ; 长按：标记，等松手才复位
            MOV     A,      #4
            RET
KS_S4_SHORT:
            MOV     KLAST,  #2
            MOV     A,      #2          ; 短按 = 减档
            RET

KS_RELWAIT:                             ; 等松手（KLAST=2/4 等 S4；1/3 等 S3）
            MOV     A,      KLAST
            CJNE    A,      #2,     KS_RW_C4
            SJMP    KS_RW_S4
KS_RW_C4:
            CJNE    A,      #4,     KS_RW_S3
KS_RW_S4:
            JB      KEY_S4, KS_RELOK
            CLR     A
            RET
KS_RW_S3:
            JB      KEY_S3, KS_RELOK
            CLR     A
            RET
KS_RELOK:
            MOV     KLAST,  #0
KS_NONE:
            CLR     A
            RET

;=========================================================================
; BEEP —— 入：A = 半周期个数（每半周期 = BUZ_DIV tick ≈ 0.5ms）
;   真正翻转由 Timer0 中断做，主循环不阻塞。
;   改 BUZLEFT/BUZB 时短暂关中断：免得中断正好读到"改了一半"的状态。
;=========================================================================
BEEP:
            JZ      BEEP_OFF
            CLR     EA
            MOV     BUZLEFT, A
            CLR     BUZB                ; 低电平 -> PNP 导通 -> 开始发声
            SETB    EA
            RET
BEEP_OFF:
            CLR     EA
            MOV     BUZLEFT, #0
            SETB    BUZB
            SETB    EA
            RET

;=========================================================================
; Timer0 中断：每 99.8us 一次
;   ⓪ 16 位系统时基 +1（红外脉宽测量、松键超时、将来的 10ms 节拍都靠它）
;   ① 软件 PWM（PWMC 0..19 与 DUTY_A/B 比较）-> ENA/ENB
;   ② 蜂鸣器方波（每 BUZ_DIV tick 翻一次）
;   ③ 把上面两者 + DIRBITS 组装成一个字节写进 P0
;   只用到 ACC / PSW（所以只 PUSH 这两个），主循环的 R0~R7、B 不受影响。
;=========================================================================
T0_ISR:
            PUSH    PSW
            PUSH    ACC

            ; ---- ⓪ 系统时基 ----
            INC     TICK_L
            MOV     A,      TICK_L
            JNZ     T0_TICKOK
            INC     TICK_H
T0_TICKOK:

            ; ---- ① PWM 计数与比较 ----
            INC     PWMC
            MOV     A,      PWMC
            CJNE    A,      #PWM_PER, T0_NR
            MOV     PWMC,   #0
T0_NR:
            MOV     A,      PWMC
            CLR     C
            SUBB    A,      DUTY_A          ; C = 1 -> 本 tick 使能 A
            MOV     ENAB,   C
            MOV     A,      PWMC
            CLR     C
            SUBB    A,      DUTY_B
            MOV     ENBB,   C

            ; ---- ② 蜂鸣器方波 ----
            INC     BUZP
            MOV     A,      BUZP
            CJNE    A,      #BUZ_DIV, T0_P0
            MOV     BUZP,   #0
            MOV     A,      BUZLEFT
            JZ      T0_MUTE
            DEC     BUZLEFT
            CPL     BUZB
            SJMP    T0_P0
T0_MUTE:
            SETB    BUZB                ; 用完了 -> 静音

            ; ---- ③ 组装 P0 ----
T0_P0:
            MOV     A,      DIRBITS
            ORL     A,      #080H       ; bit7 恒 1
            MOV     C,      ENAB
            MOV     ACC.4,  C
            MOV     C,      ENBB
            MOV     ACC.5,  C
            MOV     C,      BUZB
            MOV     ACC.6,  C
            MOV     P0,     A

            ; ---- ★★ 块⑦⑧：10ms 软件时间基准（2026-09-20 设计冻结 §5.1）----
            ;   ★★ 位置是刻意的：放在 `MOV P0,A` **之后** ⇒ P0 的写入时刻一个字都不变
            ;      ⇒ **PWM 占空比 / 蜂鸣器音调完全不受影响**（这是"改既有模块"的第一道回归判据）。
            ;   为什么必须在中断里：主循环周期 ≈26ms（IR_RECV 等边沿最长 25.6ms），
            ;   用它数 10ms 节拍会有 ±26ms 误差 -> 100ms 的动作跑成 126ms = 26%，远超 ±5%。
            ;   开销：99/100 个 tick 只走 3 条指令（≈4.3us），每 100 个 tick 多走 ~7 条。
            ;   ISR 由 ≈60us 变 ≈64us，仍远小于 99.83us 的中断间隔（余量 ≈36us）。
            ;   ⚠️ 只用到 ACC（本 ISR 已在出口 POP ACC 恢复），不碰 R0~R7 / B / DPTR。
            INC     MSDIV
            MOV     A,      MSDIV
            CJNE    A,      #MS10_DIV, T0_END
            MOV     MSDIV,  #0
            INC     MS10_L
            MOV     A,      MS10_L
            JNZ     T0_END
            INC     MS10_H
T0_END:

            POP     ACC
            POP     PSW
            RETI

;=========================================================================
; 串口输出辅助（9600 8N1，P3.1）
;   ★ DEBUG_UART = 0 时，这一整段 + 所有字符串都不编进去，只留 RET 桩，
;     调用点照旧能汇编 —— 这是给"2048 B 上限"腾空间的开关（见文件头说明）。
;=========================================================================
    IF DEBUG_UART
PUTCHAR:
            MOV     SBUF,   A
            JNB     TI,     $
            CLR     TI
            RET

PRINT_STR:
            CLR     A
            MOVC    A,      @A+DPTR
            JZ      PS_DONE
            INC     DPTR
            ACALL   PUTCHAR
            SJMP    PRINT_STR
PS_DONE:
            RET

PUT_DIG:                                ; A = 0..9 -> '0'..'9'
            ADD     A,      #30H
            ACALL   PUTCHAR
            RET

; PRT_PCT —— 入：A = 占空比档 0..20 -> 打印百分数（0/20/.../100）
PRT_PCT:
            MOV     B,      #5
            MUL     AB                      ; A = 0..100
            MOV     R2,     #0              ; 十位
PP_10:
            CJNE    A,      #10, PP_C
PP_C:
            JC      PP_ONES
            SUBB    A,      #10
            INC     R2
            SJMP    PP_10
PP_ONES:
            MOV     R3,     A               ; 个位
            MOV     A,      R2
            JZ      PP_NOTENS
            ADD     A,      #30H
            ACALL   PUTCHAR
PP_NOTENS:
            MOV     A,      R3
            ADD     A,      #30H
            ACALL   PUTCHAR
            RET

; PRT_GEAR —— 串口打一行 "gear N  duty=XX%"（调试用；验收版可关掉）
PRT_GEAR:
            MOV     DPTR,   #MSG_GEAR
            ACALL   PRINT_STR
            MOV     A,      GEAR
            ACALL   PUT_DIG
            MOV     DPTR,   #MSG_DUTY
            ACALL   PRINT_STR
            MOV     A,      DUTY_A
            ACALL   PRT_PCT
            MOV     DPTR,   #MSG_PCT
            ACALL   PRINT_STR
            RET

CRLF:
            MOV     A,      #0DH
            ACALL   PUTCHAR
            MOV     A,      #0AH
            ACALL   PUTCHAR
            RET
    ELSE
; ---- DEBUG_UART = 0：打印全部变成空操作（调用点不动，只占 1 字节 RET）----
PUTCHAR:    RET
PRINT_STR:  RET
PUT_DIG:    RET
PRT_PCT:    RET
PRT_GEAR:   RET
CRLF:       RET
    ENDIF

;=========================================================================
; 块②：红外遥控（NEC 解码）
;   守 IR_IN = P3.3（0038 输出：空闲高，收到 38kHz 载波为低）
;   整套流程与门限直接沿用 firmware\remote\remote.asm —— 那份**已在实物上验证过**
;   （5 个键值全部解对、电机四方向正常），所以这里只做"搬 + 接上 Motor_Set"，
;   不重新设计协议。
;
; 出口 IRSTAT：
;   0 = 完整帧（IB2 = 键值）      1 = 连下降沿都没等到（静默）
;   2 = 见到边沿但没解成 NEC 帧   3 = 重复帧（只表示"还按着"）
;=========================================================================
IR_RECV:
            MOV     CAP_L,  #0
            MOV     LEDLO,  #0          ; 诊断：清掉上次量到的引导码脉宽
            MOV     LEDHI,  #0
            MOV     SHORTL, #0
            MOV     IRSTAT, #1          ; 先当"连下降沿都没等到"

IR_START:
            ; ---- 1) 等 IR_IN 下降沿（超时约 25.6ms）----
            ACALL   TICK_GET
            MOV     STR_H,  R4
            MOV     STR_L,  R5
IRW_EDGE:
            JNB     IR_IN,  IR_EDGE     ; 已经变低 = 下降沿
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      STR_L
            MOV     A,      R4
            SUBB    A,      STR_H       ; A = 已等的高字节
            JNZ     IR_SILENT           ; 超过 25.6ms 还没边沿 -> 真没信号
            SJMP    IRW_EDGE

IR_SILENT:
            RET                         ; 保持 IRSTAT=1

IR_REJECT:
            MOV     IRSTAT, #2          ; 见到边沿但引导码不像 NEC：报实测脉宽
            RET

IR_EDGE:
            ; ---- 2) 引导码低电平，应为 9ms ----
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL          ; 量到它变高为止
            MOV     LEDLO,  DUR_L       ; 先存下来：不合格时要用它报诊断
            JC      IR_REJECT           ; 低电平一直不结束
            MOV     A,      DUR_H
            JNZ     IR_REJECT           ; 低电平 > 25.6ms -> 不是 NEC
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_LEAD_MIN
            JC      IR_REJECT           ; 太短
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_LEAD_MAX
            JNC     IR_REJECT           ; 太长

            ; ---- 3) 引导码高电平：靠"会不会变低"区分完整帧和重复帧 ----
            ;   完整帧: 9ms 低 + 4.5ms 高，紧接着第 1 位的低电平 -> 会变低
            ;   重复帧: 9ms 低 + 2.25ms 高，之后是空闲高电平     -> 不会再变低
            ;   所以量到 6ms 就收手：提前变低 = 完整帧，到点还高 = 重复帧。
            ;   ⚠️ 不能像量低电平那样死等它变低：重复帧要等到下一帧才变低，
            ;      死等必然超时 -> 被当成解码失败 -> "松键停车"永远刷不到时刻。
            MOV     MLVL,   #1
            MOV     CAP_L,  #IR_LEADHCAP
            ACALL   MEAS_LEVEL
            MOV     LEDHI,  DUR_L
            JC      IR_REPEAT           ; 6ms 还高着 -> 重复帧
            MOV     A,      DUR_H
            JNZ     IR_REPEAT
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_REP_MIN
            JC      IR_REJECT           ; < 1.2ms -> 噪声，不是引导码
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_LEADH_MIN
            JNC     IR_LEADOK           ; >= 2.5ms -> 标准 NEC 完整帧的引导码
            ; ---- 1.2~2.5ms：**不急着下结论** ----
            ;   ① 可能是这颗遥控器"完整帧"的短引导码（实测它发的就是这种）
            ;   ② 也可能是 NEC 重复帧（9ms 低 + 2.25ms 高，后面只有 0.56ms 短脉冲）
            ;   只能靠"后面有没有 32 位合法数据"区分：
            ;   -> 打标记继续解，解出来就是完整帧，解不出来才算重复帧。
            ;   （★ 2026-09-18 修：旧写法在这里直接当重复帧返回，
            ;      于是这颗遥控器的首帧数据被整帧丢掉 -> car_asm.hex 完全没反应。）
            MOV     SHORTL, #1
IR_LEADOK:

            ; ---- 4) 收 32 位（NEC 低位在前）----
            MOV     IB0,    #0
            MOV     IB1,    #0
            MOV     IB2,    #0
            MOV     IB3,    #0
            MOV     BITS,   #32
            MOV     PTRIDX, #0
            MOV     MASKB,  #01H

IR_BITLOOP:
            ; 每位：先一段低电平（约 0.56ms）
            MOV     CAP_L,  #0
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            JC      IR_BAD              ; 引导码之后每位的低电平都该结束

            ; 再一段高电平：0.56ms = 位0，1.69ms = 位1
            MOV     MLVL,   #1
            MOV     A,      BITS
            CJNE    A,      #1,     IR_MIDBIT
            ; ---- 最后一位特殊处理：后面是空闲高电平，不能等它变低 ----
            MOV     CAP_L,  #IR_BITCAP
            ACALL   MEAS_LEVEL
            JNC     IR_NEXTBIT          ; 1.2ms 内变低 -> 位0
            SJMP    IR_SET1             ; 到点还高着 -> 位1

IR_MIDBIT:
            MOV     CAP_L,  #0
            ACALL   MEAS_LEVEL
            JC      IR_BAD
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_BIT_TH
            JC      IR_NEXTBIT          ; < 1.1ms -> 位0

IR_SET1:
            ACALL   IR_SETBIT
IR_NEXTBIT:
            MOV     A,      MASKB           ; 每收一位（含 0 位）都推进掩码
            CLR     C
            RLC     A
            MOV     MASKB,  A
            JNC     IR_NB_CONT              ; 没溢出 -> 同一字节
            MOV     MASKB,  #01H            ; 溢出 -> 换下一字节
            INC     PTRIDX
IR_NB_CONT:
            DEC     BITS
            MOV     A,      BITS
            JNZ     IR_BITLOOP

            ; ---- 5) 校验：NEC 的 addr/~addr、cmd/~cmd 必须互补 ----
            MOV     A,      IB0
            CPL     A
            XRL     A,      IB1
            JNZ     IR_BAD
            MOV     A,      IB2
            CPL     A
            XRL     A,      IB3
            JNZ     IR_BAD

            MOV     IRSTAT, #0          ; 完整帧，IB2 = 键值
            RET

IR_REPEAT:
            MOV     IRSTAT, #3          ; 重复帧
            RET

IR_BAD:
            ; ---- 32 位没解出来：区分"短引导码的帧解失败"和"重复帧" ----
            MOV     A,      SHORTL
            JZ      IR_BAD_HARD
            MOV     IRSTAT, #3          ; 短引导码 + 没有 32 位数据 = 重复帧（还按着）
            RET
IR_BAD_HARD:
            MOV     IRSTAT, #2          ; 标准引导码但数据段/校验不合格
            RET

;-------------------------------------------------------------------------
; IR_SETBIT：把当前位（1）写进 IB0..IB3（PTRIDX 选字节，MASKB 选位）
;-------------------------------------------------------------------------
IR_SETBIT:
            MOV     A,      PTRIDX
            CJNE    A,      #0,     ISB_1
            MOV     A,      MASKB
            ORL     A,      IB0
            MOV     IB0,    A
            RET
ISB_1:      CJNE    A,      #1,     ISB_2
            MOV     A,      MASKB
            ORL     A,      IB1
            MOV     IB1,    A
            RET
ISB_2:      CJNE    A,      #2,     ISB_3
            MOV     A,      MASKB
            ORL     A,      IB2
            MOV     IB2,    A
            RET
ISB_3:
            MOV     A,      MASKB
            ORL     A,      IB3
            MOV     IB3,    A
            RET

;-------------------------------------------------------------------------
; MEAS_LEVEL：量 IR_IN 保持 MLVL 指定电平的长度（单位 tick = 100us）
;   入：MLVL = 0 量低（等它变高）；1 量高（等它变低）；CAP_L = 限时 tick，0 = 默认 25.6ms
;   出：C = 0 已变化，DUR_H:DUR_L = 时长；C = 1 到限时还没变
;-------------------------------------------------------------------------
MEAS_LEVEL:
            ACALL   TICK_GET
            MOV     STR_H,  R4
            MOV     STR_L,  R5
ML_LOOP:
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      STR_L
            MOV     DUR_L,  A
            MOV     A,      R4
            SUBB    A,      STR_H
            MOV     DUR_H,  A
            MOV     A,      CAP_L
            JZ      ML_DEFCAP
            MOV     A,      DUR_H       ; 有 CAP：DUR >= CAP 就算到点
            JNZ     ML_TIMEOUT
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      CAP_L
            JC      ML_LEVEL
            SJMP    ML_TIMEOUT
ML_DEFCAP:
            MOV     A,      DUR_H       ; 没 CAP：高字节非 0（>25.6ms）就算到点
            JNZ     ML_TIMEOUT
ML_LEVEL:
            MOV     A,      MLVL
            JZ      ML_WAIT_HI
            JNB     IR_IN,  ML_DONE     ; 量高 -> 等它变低
            SJMP    ML_LOOP
ML_WAIT_HI:
            JB      IR_IN,  ML_DONE     ; 量低 -> 等它变高
            SJMP    ML_LOOP
ML_DONE:
            CLR     C
            RET
ML_TIMEOUT:
            SETB    C
            RET

;-------------------------------------------------------------------------
; STAMP_NOW：把"最后一次收到红外帧的时刻"更新为现在
;-------------------------------------------------------------------------
STAMP_NOW:
            ACALL   TICK_GET
            MOV     LASTT_H, R4
            MOV     LASTT_L, R5
            RET

;-------------------------------------------------------------------------
; TICK_GET：原子地读出 16 位系统时基 -> R4:R5
;   读两个字节中间不能被打断，否则可能读到半新半旧的组合（00FF -> 0100）。
;   关中断只有几个机器周期，远小于 92 个机器周期的中断间隔，不会丢 tick。
;-------------------------------------------------------------------------
TICK_GET:
            CLR     EA
            MOV     R4,     TICK_H
            MOV     R5,     TICK_L
            SETB    EA
            RET

;-------------------------------------------------------------------------
; MS10_GET —— 原子地读出 16 位 **10ms 时基** -> R4:R5（★ 块⑦⑧ 新增）
;   与 TICK_GET 同款：读两个字节中间不能被打断（否则可能读到 00FF -> 0100 的半新半旧组合）。
;   关中断只有几个机器周期，远小于 99.83us 的中断间隔，不会丢 tick。
;   ★ 录制/回放的"到点了没有"**一律用它**，不要直接分两次读 MS10_L / MS10_H。
;   破坏：R4、R5
;-------------------------------------------------------------------------
MS10_GET:
            CLR     EA
            MOV     R4,     MS10_H
            MOV     R5,     MS10_L
            SETB    EA
            RET

;-------------------------------------------------------------------------
; IR_ERRPR —— "见到边沿但没解成 NEC" 时打一行实测脉宽（200ms 限流）
;   判读：NEC 应该是 lo≈90、hi≈45（重复帧 hi≈22），单位 100us
;-------------------------------------------------------------------------
IR_ERRPR:
    IF DEBUG_UART
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      LASTERR_L
            MOV     R6,     A
            MOV     A,      R4
            SUBB    A,      LASTERR_H
            MOV     R7,     A            ; R7:R6 = 距上次报错过了多久
            MOV     A,      R7
            CLR     C
            SUBB    A,      #ERRTMO_H
            JC      IE_DONE             ; 还没到 200ms -> 不刷屏
            JNZ     IE_PRINT
            MOV     A,      R6
            CLR     C
            SUBB    A,      #ERRTMO_L
            JC      IE_DONE
IE_PRINT:
            MOV     LASTERR_H, R4
            MOV     LASTERR_L, R5
            MOV     DPTR,   #MSG_IRERR
            ACALL   PRINT_STR
            MOV     A,      LEDLO
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_IRERR2
            ACALL   PRINT_STR
            MOV     A,      LEDHI
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_IRERR3
            ACALL   PRINT_STR
            MOV     A,      IB0
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_IRERR4
            ACALL   PRINT_STR
            MOV     A,      IB1
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_IRERR5
            ACALL   PRINT_STR
            MOV     A,      IB2
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_IRERR6
            ACALL   PRINT_STR
            MOV     A,      IB3
            ACALL   PUT_HEX
            ACALL   CRLF
IE_DONE:
    ENDIF
            RET

;=========================================================================
; DO_KEY —— 处理一个"新键"：打印 + 查表 + 动作 + 显示 + 提示音
;   入：IB2 = 键值
;=========================================================================
DO_KEY:
            ; ★★ R3（2026-09-20 用户需求）：**遥控一按，决定权就交回给人** ——
            ;   若避障闸门正处在"太近刹停"锁存态（AV_HOLD），就地解除（-> AV_HUMAN）。
            ;   放在最前面，所以**任意**遥控键（方向/停止/加减档/模式键）都算"人来接管"。
            ;   之后 AV_GATE 放行（不刹停、也不改写成右转），直到距离回到 ≥10cm
            ;   才自动回 AV_FREE、避障重新武装。
            MOV     A,      AVST
            CJNE    A,      #AV_HOLD, DK_TAKEOVER
            MOV     AVST,   #AV_HUMAN
DK_TAKEOVER:
            ; ---- ★★ M4（块⑦⑧）：三个功能键优先处理（设计冻结 §7.2 M4）----
            ;   位置：放在"AV_HOLD 接管"**之后** -> 这三个键同样算"人来接管"，与 R3 一致。
            ;   ⚠️ 用 LJMP 不用 SJMP：新例程写在文件后面，短跳够不着
            ;      （本项目为此踩过 2 次 TARGET OUT OF RANGE）。
            ;   ⚠️ 这三个键**不再往下走** DO_KEY 的常规流程：不进 KEY2MODE、
            ;      不进 KEY2ACT（所以不会驱动电机，也不会被当成"不认识的键"）。
            MOV     A,      IB2
            CJNE    A,      #KEY_REC,  DK_NREC
            LJMP    REC_KEY
DK_NREC:
            MOV     A,      IB2
            CJNE    A,      #KEY_CLR,  DK_NCLR
            LJMP    CLR_KEY
DK_NCLR:
            MOV     A,      IB2
            CJNE    A,      #KEY_PLAY, DK_NPLAY
            LJMP    PLAY_KEY
DK_NPLAY:
            MOV     DPTR,   #MSG_KEY    ; "K="
            ACALL   PRINT_STR
            MOV     A,      IB2
            LCALL   PUT_HEX             ; 原始键值字节（**测其余键值就靠这一行**）★ LCALL：已跨 2KB 页

            ; ---- ★★ R14：遥控**数字键 1 / 2 / 3 直接选模式**（全局）----
            ;   1 -> 手动 / 2 -> 寻光 L / 3 -> 循迹 t
            ;   ★ 原来这里是"模式键（数字键 5）循环切换"，**R14 起取消**（用户要求）；
            ;     **长按 S3 的循环保留**（遥控没电时的后路）。
            MOV     A,      IB2
            ACALL   KEY2MODE
            JNC     DK_NOTMODE          ; 不是 1/2/3 -> 继续看是不是调速键
            ; ★★ M7（决定 D3）：**录制中禁止切模式**
            ;   理由：录制中切到寻光/循迹这类**自主模式**没有合理语义（它们不能被"示教"），
            ;   而且模式动作会改写 CURACT -> 记录直接被污染。
            ;   ⇒ 拒绝并响两声（与"进入录制"的一声、"退出录制"的两声区分开：
            ;      这里也是两声，但**数码管不会变**，靠这点区分）。
            JB      RECON,  DK_BLKMD
            CJNE    A,      MODE, DK_GOTO
            MOV     A,      #BEEP_KEY   ; 已经就是这个模式 -> 只响一声、不做动作
            ACALL   BEEP                ;   （免得重复触发切模式那套副作用）
            LJMP    DK_END
DK_BLKMD:
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            LCALL   D_20MS              ; ★ LCALL：已跨 2KB 页
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            LJMP    DK_END
DK_GOTO:
            LJMP    MODE_GOTO
DK_NOTMODE:

            ; ---- 先看是不是"遥控调速"键（候选码，见 docs\遥控器码值表.md）----
            MOV     A,      IB2
            CJNE    A,      #KEY_SPD_UP, DK_NOTUP
            MOV     A,      GEAR
            CJNE    A,      #MAXGEAR, DK_UP1
            LJMP    DK_END              ; 已最高档：只打印，不动
DK_UP1:
            INC     GEAR
            SJMP    DK_SPD
DK_NOTUP:
            MOV     A,      IB2
            CJNE    A,      #KEY_SPD_DN, DK_ACTKEY
            MOV     A,      GEAR
            JZ      DK_END              ; 已 0 档：不动
            DEC     GEAR
DK_SPD:
            ; 改档后：如果正在动，用新档位重新套用当前动作（否则只改档位显示）
            MOV     A,      CURACT
            JZ      DK_SPD_SHOW
            MOV     R7,     GEAR
            ACALL   MOTOR_SET_ACT
DK_SPD_SHOW:
            ACALL   SHOW_STATE
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            ACALL   PRT_GEAR
DK_END:
            ACALL   CRLF
            RET

DK_ACTKEY:
            MOV     A,      IB2
            ACALL   KEY2ACT             ; A = 动作码
            CJNE    A,      #ACT_NONE, DK_KNOWN
            MOV     DPTR,   #MSG_UNK    ; 不认识的键：只打印，不动电机
            ACALL   PRINT_STR
            RET

DK_KNOWN:
            CJNE    A,      #ACT_STOP, DK_MOVE
            ; ---- 停止键：最高优先级 ----
            MOV     CURACT, #ACT_STOP
            MOV     R7,     #0
            ACALL   MOTOR_SET_ACT
            SJMP    DK_SHOW
DK_MOVE:
            MOV     R5,     A           ; 动作码暂存
            MOV     A,      GEAR
            JNZ     DK_SET              ; 档位非 0 -> 用它
            MOV     GEAR,   #GEAR_DEFAULT   ; 从 0 档按方向键 -> 自动跳默认档，否则车不动
DK_SET:
            MOV     A,      R5
            MOV     CURACT, A
            MOV     R7,     GEAR
            ACALL   MOTOR_SET_ACT
DK_SHOW:
            ACALL   SHOW_STATE          ; 数码管显示档位，D3 亮 = 正在动
            LCALL   PRT_ACTNAME         ; 串口打动作名   ★ LCALL：已跨 2KB 页
            MOV     A,      #BEEP_KEY
            ACALL   BEEP                ; 响一声（不用看串口也知道收到了）
            RET

;=========================================================================
; KEY2ACT —— 键值 -> 动作码（A 进 A 出）
;   目前只认 5 个方向键（已实测确认）。遥控调速/录制/回放/清空要等
;   KEY_SPD_UP / KEY_SPD_DN / KEY_REC / KEY_PLAY / KEY_CLR 实测填上后再接。
;=========================================================================
KEY2ACT:
            CJNE    A,      #KEY_FORWARD, K2A_1
            MOV     A,      #ACT_FORWARD
            RET
K2A_1:      CJNE    A,      #KEY_BACK,  K2A_2
            MOV     A,      #ACT_BACK
            RET
K2A_2:      CJNE    A,      #KEY_LEFT,  K2A_3
            ; ★ R9：**正在"向前跑" -> 左弧线；否则原地左转**（原地转保留）
            ACALL   K_ISFWD             ; C = 1 -> 正在前进 / 弧线中
            JC      K2A_LARC
            MOV     A,      #ACT_LEFT
            RET
K2A_LARC:   MOV     A,      #ACT_ARC_L
            RET
K2A_3:      CJNE    A,      #KEY_RIGHT, K2A_4
            ACALL   K_ISFWD
            JC      K2A_RARC
            MOV     A,      #ACT_RIGHT
            RET
K2A_RARC:   MOV     A,      #ACT_ARC_R
            RET
K2A_4:      CJNE    A,      #KEY_STOP,  K2A_NONE
            MOV     A,      #ACT_STOP
            RET
K2A_NONE:   MOV     A,      #ACT_NONE
            RET

;=========================================================================
; KEY2MODE —— ★★ R14：遥控键 -> **目标模式**（数字键 1/2/3 直选模式）
;   入：A = 键值
;   出：**C = 1** -> A = 目标模式（0 手动 / 1 寻光 / 2 循迹）；**C = 0** -> 不是模式直选键（A 不变）
;   ★ 为什么用 C 返回：调用方还要用 A 装键值继续往下判（比如接着看是不是调速键）。
;   ★ 原来的"模式键（数字键 5 = `1C`）循环切换"已在 R14 取消（用户要求）；
;     长按 S3 的循环保留，两条路都落到 `MODE_GOTO` 共用副作用。
;   破坏：A、C
;=========================================================================
KEY2MODE:
            CJNE    A,      #KEY_M1, K2M_1
            MOV     A,      #MODE_MANUAL
            SETB    C
            RET
K2M_1:
            CJNE    A,      #KEY_M2, K2M_2
            MOV     A,      #MODE_LIGHT
            SETB    C
            RET
K2M_2:
            CJNE    A,      #KEY_M3, K2M_3
            MOV     A,      #MODE_TRACK
            SETB    C
            RET
K2M_3:
            CLR     C
            RET

;=========================================================================
; K_ISFWD —— ★ R9："车现在是不是在**向前跑**"（前进 或 弧线中）
;   出：**C = 1** 是（-> 左/右键走弧线）；**C = 0** 否（-> 原地转）
;   ★ 为什么把"弧线中"也算进去：按住左转画弧时若**松开再按**，
;     此刻 CURACT 还是 ACT_ARC_L；若不算，就会突然掉回"原地转"，手感突变。
;   ★ 用 C 返回而不是 A —— 因为调用方（KEY2ACT）还要用 A 装动作码。
;   破坏：A、C（其余不动）
;=========================================================================
K_ISFWD:
            MOV     A,      CURACT
            CJNE    A,      #ACT_FORWARD, KIF_1
            SETB    C
            RET
KIF_1:
            CJNE    A,      #ACT_ARC_L, KIF_2
            SETB    C
            RET
KIF_2:
            CJNE    A,      #ACT_ARC_R, KIF_3
            SETB    C
            RET
KIF_3:
            CLR     C
            RET

;=========================================================================
; SHOW_STATE —— 数码管显示当前档位；D3 亮 = 正在动（CURACT != 0）
;   注意：会用到 R6（调用方不要指望 R6 还能用）
;=========================================================================
SHOW_STATE:
            ; ★★ M9（块⑦）：**录制中数码管固定显示 'r'**（设计冻结 §3.1 S1）
            ;   为什么在这里拦而在 REC_SAMPLE 里刷：调 SHOW_STATE 的地方很多
            ;   （DO_KEY 的动作/调速分支、ML_APPLY、IT_APPLY…），在出口统一拦一道最省事，
            ;   也保证 'r' 不会被档位数字盖掉。
            ;   ★ 段码换成 'r' 之后**照常走 D3 逻辑**，所以"电机在动"这个指示不丢。
            ;   ★ RECON=0 时行为与改动前**逐条一致**（只多一条 JNB）。
            ;   ⚠️ RECON 是**位**（BIT 20H.4），只能用 JB/JNB，**不能 MOV A,RECON**。
            JNB     RECON,  SS_NORMAL
            MOV     R6,     #DISP_R     ; 录制中：段码用 'r'
            SJMP    SS_D3
SS_NORMAL:
            MOV     A,      GEAR
            MOV     DPTR,   #GEARTAB
            MOVC    A,      @A+DPTR
            MOV     R6,     A
SS_D3:
            MOV     A,      CURACT
            JZ      SS_OFF
            MOV     A,      R6
            CLR     ACC.0               ; D3 亮 = 电机在动
            MOV     P2,     A
            RET
SS_OFF:
            MOV     P2,     R6          ; 段码 bit0 本来就是 1 = D3 灭
            RET

;=========================================================================
; SHOW_MODE —— 按模式刷新数码管：手动 = 显示档位；其它模式 = 显示模式代号
;   D3（段码 bit0）在任何模式下都表示"电机在动"（CURACT != 0）
;   （避障是"转向避让"不是刹车，所以避让时车确实在动 -> D3 该亮）
;   注意：会用到 R6（调用方不要指望 R6 还能用）
;=========================================================================
SHOW_MODE:
            MOV     A,      MODE
            JZ      SHOW_STATE          ; 手动模式 -> 档位 + D3（尾调用）
            MOV     DPTR,   #MODETAB
            MOVC    A,      @A+DPTR
            MOV     R6,     A
            MOV     A,      CURACT
            JZ      SM_OFF
            MOV     A,      R6
            CLR     ACC.0               ; D3 亮 = 在动
            MOV     P2,     A
            RET
SM_OFF:
            MOV     P2,     R6          ; 段码 bit0 本来就是 1 = D3 灭
            RET

;=========================================================================
; MODE_SWITCH —— **S3 长按**：切到"下一个"模式（循环，块③）
;   ★ R14（2026-09-20 用户需求）：**遥控上的"模式键（数字键 5）"不再循环切换了** ——
;     改成**数字键 1 / 2 / 3 直接选模式**（见 DO_KEY 里的 `KEY2MODE`）。
;     **长按 S3 的循环保留**（遥控没电/丢失时的后路）。
;   实现上把"算下一个"和"跳到指定模式"拆开了：
;       MODE_SWITCH -> 算出下一个 -> 落到 MODE_GOTO
;       KEY2MODE    -> 直接给出目标 -> 也落到 MODE_GOTO
;   两边共用同一套副作用（清动作 / 补默认档 / 刷新 LASTLN / 刷显示 / 响一声）。
;=========================================================================
MODE_SWITCH:
            ; ★★ M8（决定 D7）防御性加固：MODE_PLAY(3) 时下面 `INC A` 会得到 4，
            ;   而 NMODES=3 -> `CJNE A,#NMODES` 不等 -> MODE_GOTO(4) -> **MODETAB[4] 越表**
            ;   （读出垃圾段码，显示乱码）。当前不可达（回放路径不调 KEY_SCAN），
            ;   但这 4 条指令买断"将来有人动主循环"带来的隐患。
            MOV     A,      MODE
            CJNE    A,      #MODE_PLAY, MSW_N
            CLR     A                   ; 在回放中 -> 直接回手动
            SJMP    MODE_GOTO
MSW_N:
            MOV     A,      MODE
            INC     A
            CJNE    A,      #NMODES, MODE_GOTO
            CLR     A                   ; 绕回手动
; ---- MODE_GOTO：入 A = 目标模式（0 手动 / 1 寻光 / 2 循迹）----
MODE_GOTO:
            MOV     MODE,   A
            MOV     LASTCMD,#LASTCMD_NONE
            MOV     A,      MODE
            JNZ     MS_NONMAN
            ; ---- 回手动：★ 2026-09-20 按用户要求改成"不停车、继续走" ----
            ;   原行为是"停车 + 显示档位、不自动前进"，用户联调中要求
            ;   模式绕圈回到手动档时**运动不断流**（联调记录 R1）。
            ;   手动模式的既有语义本来就是"档位非 0 = 前进"（块① APPLY_GEAR），
            ;   所以这里按当前档位继续前进；档位 0 则照旧停。
            ;   ★★ 必须同时把 CURACT 也置上：AV_GATE 用 CURACT != 0 判断
            ;      "本来就在动"，若车在走而 CURACT = 0，避障会直接放行不躲
            ;      （联调问题 P4 的同一类隐患）。
            MOV     A,      GEAR
            JNZ     MS_HFWD
            MOV     CURACT, #ACT_STOP   ; 档位 0：照旧停车
            SJMP    MS_HGO
MS_HFWD:
            MOV     CURACT, #ACT_FORWARD
MS_HGO:
            MOV     R7,     GEAR
            MOV     A,      CURACT
            ACALL   MOTOR_SET_ACT       ; R7 = 0 时这个出口就是停车
            ACALL   SHOW_STATE
            SJMP    MS_BEEP
MS_NONMAN:
            MOV     CURACT, #ACT_STOP   ; 进非手动：先清掉遥控动作，下一趟由模式动作接管
            ; ---- 进非手动模式：档位 0 时给个默认档，否则车不会动 ----
            MOV     A,      GEAR
            JNZ     MS_STAMP
            MOV     GEAR,   #GEAR_DEFAULT
MS_STAMP:
            ACALL   TICK_GET            ; 刷新"最后看到线"的时刻（循迹脱线超时的基准）
            MOV     LASTLN_H, R4
            MOV     LASTLN_L, R5
            ACALL   SHOW_MODE
MS_BEEP:
            MOV     A,      #BEEP_TICKS
            ACALL   BEEP                ; 切模式提示音
            LJMP    MAIN_LOOP

;=========================================================================
; LIGHT_STEP —— 块④ 寻光：读两路光敏（见光 = 低），朝有光的一侧走
;   P1.1 = 左光敏，P1.0 = 右光敏（2026-09-18 实测：见光 = 0，遮住 = 1）
;   每趟主循环调一次；速度用当前档位，档位 0 = 不动。
;   两边都见光 -> 直走；只有一边 -> 朝那边转；都遮住 -> 停。
;=========================================================================
LIGHT_STEP:
            MOV     A,      GEAR
            JNZ     LS_GO
            MOV     A,      #ACT_STOP       ; ★ 档位 0 必须显式停车（不能直接 RET，否则保持上次动作）
            SJMP    LS_APPLY
LS_GO:
            JB      LDR_LEFT,  LS_NOLEFT    ; 左边没见光？
            JB      LDR_RIGHT, LS_TURNL     ; 右边也没 -> 只有左边亮 -> 左转
            MOV     A,      #ACT_FORWARD    ; 两边都亮 -> 直走
            SJMP    LS_APPLY
LS_TURNL:
            MOV     A,      #ACT_LEFT
            SJMP    LS_APPLY
LS_NOLEFT:
            JB      LDR_RIGHT, LS_STOPIT    ; 两边都没光 -> 停
            MOV     A,      #ACT_RIGHT      ; 只有右边亮 -> 右转
            SJMP    LS_APPLY
LS_STOPIT:
            MOV     A,      #ACT_STOP
LS_APPLY:
            MOV     CURACT, A               ; 记下当前动作，SHOW_MODE 靠它点 D3
            MOV     R7,     GEAR
            ACALL   MOTOR_SET_ACT           ; A=ACT_STOP 时这个出口就是停车
            ACALL   SHOW_MODE               ; 每趟刷新（模式代号 + D3 动/停）
            RET

;=========================================================================
; TRACK_STEP —— 块⑤ 循迹：两个反射探头压在黑线上就修正方向
;   P3.5 = 左探头 V2，P3.6 = 右探头 V3
;   实测极性（2026-09-18）：白纸/有反射 = 低(0)，压黑线 = 高(1)
;   ★ 转向规则（按几何推，别凭手感记）：
;     正常是"骑线"跑 —— 两个探头都压线 = 11 -> 直走（线宽 1.5~2cm 才成立）。
;       只有**左**探头压线（10）= 线在车左下方 = 车偏到线的**右边** -> 要**左转**修正；
;       只有**右**探头压线（01）= 线在车右下方 = 车偏到线的**左边** -> 要**右转**修正。
;   ★★ 修正史（别再来回翻）：
;     2026-09-20 曾把这两条对调过，并在 8.1b 记成"方向已按实测翻正" —— **那一次翻错了**，
;     实物表现是"朝远离线的方向转"，用户 2026-09-20 联调中再次反馈"左右写反了"。
;     现按上面的几何规则改回来（几何规则与手感无关，可复核）。
;   两个都白 = 脱线 -> 先直走找线，超过 TRK_TMO（≈0.5s）就停车。
;   速度用当前档位；档位 0 时 MOTOR_SET_ACT 自己会停车。
;   入口：无；出口：无（改 CURACT / 电机 / 数码管）
;=========================================================================
TRACK_STEP:
            CLR     A
            MOV     C,      TRACK_L
            RLC     A                       ; bit1 = 左探头
            MOV     C,      TRACK_R
            RLC     A                       ; bit0 = 右探头
            JZ      TS_LOST                 ; 00 = 两个都白 -> 脱线
            ; ---- 至少一路压线：刷新"最后看到线"的时刻 ----
            MOV     R6,     A
            ACALL   TICK_GET
            MOV     LASTLN_H, R4
            MOV     LASTLN_L, R5
            MOV     A,      R6
            CJNE    A,      #1,     TS_CHK2
            MOV     A,      #ACT_RIGHT      ; 01 = 左白右黑（右探头压线）-> 车偏在线左边 -> 右转修正
            SJMP    TS_APPLY
TS_CHK2:
            CJNE    A,      #2,     TS_BOTH
            MOV     A,      #ACT_LEFT       ; 10 = 左黑右白（左探头压线）-> 车偏在线右边 -> 左转修正
            SJMP    TS_APPLY
TS_BOTH:
            MOV     A,      #ACT_FORWARD    ; 11 = 两个都压线 -> 直走
            SJMP    TS_APPLY
TS_LOST:
            ACALL   TICK_GET                ; 脱线：看离开线多久了
            MOV     A,      R5
            CLR     C
            SUBB    A,      LASTLN_L
            MOV     A,      R4
            SUBB    A,      LASTLN_H
            CLR     C
            SUBB    A,      #TRK_TMO_H
            JC      TS_HOLD
            MOV     A,      #ACT_STOP       ; 脱线超时 -> 停车
            SJMP    TS_APPLY
TS_HOLD:
            MOV     A,      #ACT_FORWARD    ; 刚脱线 -> 先直走找回来
TS_APPLY:
            MOV     CURACT, A
            MOV     R7,     GEAR
            ACALL   MOTOR_SET_ACT
            ACALL   SHOW_MODE
            RET

;=========================================================================
; 块⑥ 避障（2026-09-20：改闸门 → R2 收窄为**只作用于 手动/寻光** → **R3 加"太近刹停"**）
;   超声波 HC-SR04：US_TRIG = P1.3（输出），US_ECHO = P1.2（输入，高电平宽度 ∝ 距离）
;   ★ 计时用系统 100us tick：Timer0 方式2 不能改成方式1（它还在打 PWM/蜂鸣器/红外），
;     所以分辨率 ≈ 1.72cm/tick —— 只做"门限比较"，不做 cm 换算。
;   开关：**S4 长按 1 秒**（短按 S4 仍是减档）；上电默认开启。
;   行为：在**手动 / 寻光**模式下分三档（R3，2026-09-20）——
;         ≥ 21cm            -> 放行（不介入）
;         10cm ~ 21cm       -> **原地右转避让**（不刹车）
;         **< 10cm（太近）** -> **刹停 + 锁存**：车停住不动，**决定权交给遥控**；
;                              障碍自己移开也不会让它重新动，必须按遥控键才解除。
;         （旧注释写的"强制停车（只刹车、不抢方向）"是过期描述，别再被它误导。）
;         ★ **循迹模式不参与避障**（用户需求 R2，见 AV_GATE 里的说明）。
;=========================================================================
; US_READ —— 测一次距离。出：R5 = 回波高电平 tick 数（≈1.72cm/tick）
;                              255 = 没回波 / 太远（>255 tick ≈ 4.4m）
;   寄存器：破坏 R2 / R5 / R6 / R7
;=========================================================================
US_READ:
            ; ---- 1) 发 ≥10us 的干净触发脉冲 ----
            CLR     US_TRIG
            SETB    US_TRIG
            MOV     R2,     #6              ; 6*2 = 12 机器周期 ≈ 13us
US_TG:      DJNZ    R2,     US_TG
            CLR     US_TRIG

            ; ---- 2) 等 Echo 上升沿（限时 US_UPTO ≈ 2ms）----
            ACALL   TICK_GET
            MOV     A,      R4              ; ★ 8051 不能 MOV Rn,Rn，必须过 ACC
            MOV     R6,     A
            MOV     A,      R5
            MOV     R7,     A
US_W1:      JB      US_ECHO, US_UP
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      R7
            MOV     A,      R4
            SUBB    A,      R6
            CLR     C
            SUBB    A,      #US_UPTO
            JC      US_W1
            MOV     R5,     #0FFH           ; 等不到回波 -> 当"够远"
            RET

            ; ---- 3) 量 Echo 高电平时长 ----
US_UP:
            ACALL   TICK_GET
            MOV     A,      R4              ; ★ 同上：过 ACC 转存
            MOV     R6,     A
            MOV     A,      R5
            MOV     R7,     A
            MOV     R5,     #0              ; 已过 tick 低字节，从 0 起算
US_W2:      JNB     US_ECHO, US_DONE
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      R7
            MOV     R5,     A
            MOV     A,      R4
            SUBB    A,      R6
            JNZ     US_FAR                  ; 已过 255 tick（>4.4m）-> 够远
            MOV     A,      R5
            CLR     C
            SUBB    A,      #US_NEAR
            JNC     US_FAR                  ; 已经够远，不必再等回波结束
            SJMP    US_W2
US_FAR:
            MOV     R5,     #0FFH
US_DONE:
            RET

;=========================================================================
; AV_GATE —— 避障闸门（块⑥：改闸门 → 转向避让 → R2 收窄 → R3 加"太近刹停" → **R4 手动去掉转向避让**）
;   作用范围：**手动 / 寻光**（循迹不参与，R2）。
;   **分档行为（R3 + R4 之后，2026-09-20）**：
;     距离 ≥ US_NEAR(≈21cm)   -> AV_FREE  放行，并把原动作重新套上
;     US_STOP ≤ d < US_NEAR   -> AV_TURN  改写成"原地右转避让"
;                                        ★ **只在寻光模式**（R4：手动模式这一档直接放行）
;     d < US_STOP(≈10cm)      -> AV_HOLD  **刹停 + 锁存 + 间歇响**，决定权交给遥控
;   ★ R4：**手动（遥控）模式没有"自动转向避让"** —— 只保留"太近刹停 + 手动接管"。
;     寻光保留转向避让（它是自主模式，避障是它的安全保障）。
;   ★ AV_HOLD 是**锁存**：只有**遥控按键**能解除（-> AV_HUMAN）；
;     障碍自己移开也**不会**让车重新动起来（用户要求"由遥控来决定"）。
;   ★ AV_HOLD 期间**持续间歇响**（每 ≈0.7s 一声，`AVBEEP_H`），
;     停响条件：① 遥控接管，② 障碍移开（回到 ≥ US_STOP）。注意 ② 只停响，**车仍停着**。
;   ★ AV_HUMAN：完全放行（不再刹停、也不再改写动作），等距离回到 ≥ US_STOP
;     之后才自动回到 AV_FREE —— 也就是"避障重新武装"。
;   ★ 不拦输入：遥控/按键照常响应（响铃、显示、记动作）—— 否则有障碍时遥控就"聋"了。
;   ★ 只有"本来就在动"（CURACT != 0）才主动避让，免得车停着自己拐走；
;     障碍解除后要把原动作重新套上（否则会一直右转下去）。
;   出：无（改 AVST / 电机 / 蜂鸣器）
;=========================================================================
AV_GATE:
            MOV     A,      AVOIDON
            JNZ     AG_ON                   ; 开着 -> 正常判档
            ; ⚠️ 这里到 AG_FREE 已超 ±127 字节（R7 加代码后）—— 短跳放不下，
            ;    按本项目的老规矩改写成"反向短跳 + LJMP"。
            LJMP    AG_FREE                 ; 没开避障 -> 放行（顺带把锁存也解掉）
AG_ON:
            ; ★★ R2：**循迹模式不参与避障**（理由见 docs\联调记录.md 第 0.2 节）
            ;   ★ 必须显式清 AVST：否则它会卡在 AV_TURN，MOTOR_SET_ACT 把循迹的
            ;     每一个动作都改写成"右转" -> 车一直原地转，循迹彻底废掉。
            MOV     A,      MODE
            CJNE    A,      #MODE_TRACK, AG_CHK
            MOV     AVST,   #AV_FREE
            RET
AG_CHK:
            MOV     A,      AVST
            CJNE    A,      #AV_HOLD, AG_M0
            ; ---- ★ R4：锁存期间**持续间歇响**，提醒"车停着，等你" ----
            ;   BEEP 是**非阻塞**的（真正翻转由 Timer0 中断做，见 BEEP 的注释），
            ;   所以这里反复响**不会**拖慢主循环、也**不会**错过红外帧。
            ;   什么时候停响（两个条件）：
            ;     ① 按遥控接管（-> AV_HUMAN）；② 障碍移开（**退到 ≥ US_CLEAR**）。
            ;   ⚠️ 注意 ② 只**停响**，车**仍然停着等遥控** —— 锁存不解除（R3）。
            ;   ★ R11：这里用 **US_CLEAR(≈17cm)** 而不是 US_STOP(≈10cm) —— 滞回，
            ;     否则读数在 10cm 附近抖动会让它"静音->又响"反复跳。
            ACALL   US_READ
            MOV     A,      R5
            CLR     C
            SUBB    A,      #US_CLEAR
            JC      AG_BEEPCHK              ; 还太近 -> 该响
            ; ★ R13：车头红外还"贴着" -> 也继续响（它与超声波是**冗余**关系）
            ACALL   IR_DET
            JC      AG_BEEPCHK
            RET                             ; 障碍走远了 -> 静音（但车不动）
AG_BEEPCHK:
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      BEEPT_L
            MOV     A,      R4
            SUBB    A,      BEEPT_H
            CLR     C
            SUBB    A,      #AVBEEP_H
            JC      AG_RET                  ; 还没到间隔 -> 这一趟不响
            MOV     BEEPT_H, R4
            MOV     BEEPT_L, R5
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            RET
AG_M0:
            ; ---- ★★ R13 / R13b：**车头红外近距避障（冗余通道）** ----
            ;   车头那对红外对管（位号 **V7/V4**，就是**报告点名的"避障对管"**）。
            ;   量程只有 **1~2cm** —— 所以它一旦检测到，就等于"**已经贴上了**"，
            ;   因此与超声波的"< US_STOP"**同等对待**，走同一条 AG_HOLDNOW 路径：
            ;     · 手动模式 -> 刹停 + 锁存 + 间歇响
            ;     · 寻光模式 -> 退回手动模式（R7）
            ;   ★★ 它**不替代**超声波：超声波管的是 **5~21cm 的远距避让**，
            ;      红外只兜"**最后 1~2cm**"（超声波在极近处/软目标上可能漏检，这就是冗余的意义）。
            ;   ✅ **脚位已实测确认 = `P3.7`**（2026-09-20：烧 `diag\lightscan.hex`，
            ;      白纸贴车头那对管前 → 数码管跳 `7`）。
            ;      ★ 这个脚原记"未接传感器（实测不翻转）" —— **推翻**（当初只在循迹探头下面试过）。
            ;   ✅ **极性不用猜**：由 `IR_INV` **上电自动校准**（见初始化 IRC_DONE）——
            ;      因为 v20(`JNB`) / v21(`JB`) 两种写法都出现过"车不动"，与其继续猜硬件，
            ;      不如上电时把当时的 P3.7 电平当作"无反射"参考。这里统一走 `IR_DET`。
            ACALL   IR_DET
            JC      AG_TOOCLOSE_NOW     ; 检测到 -> 直接当"太近"
            ACALL   US_READ
            MOV     A,      R5
            CLR     C
            SUBB    A,      #US_STOP
            JNC     AG_NOTCLOSE             ; ≥ US_STOP 且红外没反应 -> 不在"太近"档
            ; ---- ★ R3：太近 -> 刹停 + 锁存 ----
AG_TOOCLOSE_NOW:
            MOV     A,      AVST
            JZ      AG_HOLDNOW              ; AV_FREE  -> 触发
            DEC     A
            JZ      AG_HOLDNOW              ; AV_TURN  -> 触发
            RET                             ; AV_HUMAN -> 遥控已接管，不再反复刹停
AG_HOLDNOW:
            ; ---- ★★ R7（2026-09-20 用户需求）：**寻光模式下"太近"不刹车，而是退回手动模式** ----
            ;   理由：寻光是**自主模式**，过近时应该把控制权**交还给人**，
            ;   而不是像手动模式那样"原地刹停 + 锁存着等遥控"。
            ;   ★ 这里用 `AV_HUMAN`（不是 `AV_HOLD`）正是关键：
            ;     `AV_HUMAN` = "已交给遥控 / 放行"状态 -> **不锁存、不间歇响**，
            ;     而且距离回到 ≥ US_STOP 后 AV_GATE 会自动把它变回 AV_FREE（避障重新武装）。
            ;   ★ 手动模式保持不变（仍是"刹停 + 锁存 + 间歇响"，见 R3/R4），只改寻光。
            MOV     A,      MODE
            CJNE    A,      #MODE_LIGHT, AG_HOLD_M
            MOV     MODE,   #MODE_MANUAL    ; ★ R7：退回手动模式
            MOV     AVST,   #AV_HUMAN       ; ★ 放行态：不锁存、不响
            SJMP    AG_HOLD_STOP
AG_HOLD_M:
            MOV     AVST,   #AV_HOLD        ; 手动：锁存（R3/R4 原行为）
AG_HOLD_STOP:
            MOV     CURACT, #ACT_STOP
            MOV     R7,     #0
            MOV     A,      #ACT_STOP
            ACALL   MOTOR_SET_ACT           ; 停车（R7=0 时这个出口就是停车）
            ACALL   SHOW_STATE              ; 显示档位（两路最后都是手动模式）
            MOV     A,      AVST
            CJNE    A,      #AV_HOLD, AG_HOLD_BEEP
            ACALL   TICK_GET                ; ★ R4：只有"锁存"才记时刻、之后间歇续响
            MOV     BEEPT_H, R4             ;   之后由 AG_CHK 按 AVBEEP_H 的间隔继续响
            MOV     BEEPT_L, R5
AG_HOLD_BEEP:
            MOV     A,      #BEEP_KEY
            ACALL   BEEP                    ; ★ 响一声：手动=刹停锁存；寻光=退回手动（切模式提示）
            RET
AG_NOTCLOSE:
            ; ---- ≥ US_STOP：已脱离"太近"档 -> 解除"遥控接管"态，避障重新武装 ----
            ;   （AV_HOLD 不会走到这里：它在 AG_CHK 就 RET 了，必须等遥控来解）
            MOV     AVST,   #AV_FREE
            ; ★★ R12（2026-09-20 用户需求）：**手动模式恢复"自动转向避让"** ——
            ;   这是**撤销 R4**（R4 曾把 10~21cm 这一档从手动模式里去掉，只留寻光）。
            ;   现在**手动和寻光在这一档上完全一样**：10~21cm -> 原地右转避让。
            ;   ★ 两者仍有的区别只在下一条档（<10cm）：
            ;       手动 -> 刹停 + 锁存 + 间歇响（R3/R4）
            ;       寻光 -> 退回手动模式（R7）
            ;   ⚠️ R4 当时是用户主动要求的（理由推测：手动模式下自主转向会干扰操作）。
            ;     若恢复后又觉得"车自己乱转很烦"，说一声即可改回（把下面这段的 MODE 判断加回来）。
            MOV     A,      R5
            CLR     C
            SUBB    A,      #US_NEAR
            JNC     AG_FREE                 ; ≥ US_NEAR -> 够远，放行 + 恢复原动作
            ; ---- US_STOP ~ US_NEAR：原地右转避让（★ R12 起：手动 / 寻光 都走这里）----
            MOV     AVST,   #AV_TURN
            MOV     A,      CURACT
            JZ      AG_RET                  ; 本来就没在动 -> 别自己窜出去
            MOV     R7,     GEAR
            MOV     A,      #ACT_RIGHT
            ACALL   MOTOR_SET_ACT           ; 原地右转避让
AG_RET:
            RET
AG_FREE:
            MOV     AVST,   #AV_FREE
            MOV     A,      CURACT
            JZ      AG_RET                  ; 没在动 -> 不用恢复
            MOV     R7,     GEAR
            ACALL   MOTOR_SET_ACT           ; 障碍解除 -> 恢复原动作（否则会一直右转）
            RET

;=========================================================================
; IR_DET —— ★ R13b：判"车头红外有没有检测到"，**极性已按 `IR_INV` 归一**
;   出：**C = 1** -> 检测到（贴上了）；C = 0 -> 没东西
;   ★ 为什么要这个函数：车头那对管子（`V7`/`V4`）的极性试了两版都不对
;     （v20 `JNB`、v21 `JB` 都出现"车不动"），所以改成**上电自动校准**：
;     初始化时以当时的 `P3.7` 电平为"无反射"参考，存进 `IR_INV`；
;     之后"检测到" ⇔ 电平与参考相反。不管硬件是哪种极性，这里都自动对。
;   破坏：A、C
;=========================================================================
IR_DET:
            MOV     C,      IR_AVOID
            MOV     A,      IR_INV
            JZ      IRD_INV0
            RET                         ; IR_INV=1：高电平=检测到，C 已经正确
IRD_INV0:
            CPL     C                   ; IR_INV=0：低电平=检测到，取反
            RET

;=========================================================================
; AVOID_TOGGLE —— S4 长按：全局避障开/关
;   开 -> 响两声；关 -> 响一声长的
;=========================================================================
AVOID_TOGGLE:
            MOV     A,      AVOIDON
            XRL     A,      #1              ; 取反
            MOV     AVOIDON, A
            JZ      AT_OFF
            MOV     A,      #BEEP_KEY       ; 开：两声短响
            ACALL   BEEP
            LCALL   D_20MS                  ; ★ LCALL：已跨 2KB 页
            LCALL   D_20MS
            MOV     A,      #BEEP_KEY
            LCALL   BEEP                    ; ★ LCALL：本处在 0x0805 = 第 1 页，
            RET                             ;   而 BEEP 在 0x034D = 第 0 页 -> ACALL 够不着
AT_OFF:
            MOV     A,      #BEEP_TICKS     ; 关：一声长响
            LCALL   BEEP                    ; ★ LCALL：已跨 2KB 页
            RET

;=========================================================================
; 诊断：DIAG_KEYSHOW / DIAG_ERRSHOW / DIAG_UPDATE / DIAG_DLY（DIAG_IR=1 时编入）
;   收到完整帧 -> 数码管持续交替显示键值 IB2 的高/低半字节（每 0.6s 换）
;   帧被拒   -> 两声短响，然后依次轮播 4 个值（每值 1.2s，高/低半字节各 0.6s）：
;                 LEDLO(引导码低) -> LEDHI(引导码高) -> IB2(cmd) -> IB3(~cmd) -> 循环
;   全程不看串口也能读出。拔电复位即可回到正常档位显示。
;=========================================================================
    IF DIAG_IR
DIAG_KEYSHOW:
            MOV     DIAGCMD, IB2
            MOV     DIAGON,  #1
            SJMP    DIAG_START

DIAG_ERRSHOW:
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            MOV     A,      #BEEP_KEY
            ACALL   BEEP
            MOV     DIAGON,  #2
DIAG_START:
            MOV     DIAGSEQ, #0
            RET

DIAG_UPDATE:
            MOV     A,      DIAGON
            JZ      DU_RET
            ACALL   DU_GETVAL               ; R6 = 要显示的值
            MOV     A,      DIAGSEQ
            ANL     A,      #01H            ; bit0 = 半字节选择
            JNZ     DU_LO
            MOV     A,      R6
            SWAP    A
            SJMP    DU_HI
DU_LO:
            MOV     A,      R6
DU_HI:
            ANL     A,      #0FH
            MOV     DPTR,   #HEXSEG
            MOVC    A,      @A+DPTR
            MOV     P2,     A
DU_RET:
            RET

; 选要显示的值 -> R6（mode1 = 键值；mode2 = LEDLO/LEDHI/IB2/IB3 轮播）
DU_GETVAL:
            MOV     A,      DIAGON
            CJNE    A,      #2,     DGV_KEY
            MOV     A,      DIAGSEQ
            ANL     A,      #06H            ; 值序号 = bits2-1
            CJNE    A,      #0,     DGV_1
            MOV     R6,     LEDLO
            RET
DGV_1:
            CJNE    A,      #2,     DGV_2
            MOV     R6,     LEDHI
            RET
DGV_2:
            CJNE    A,      #4,     DGV_3
            MOV     R6,     IB2
            RET
DGV_3:
            MOV     R6,     IB3
            RET
DGV_KEY:
            MOV     R6,     DIAGCMD
            RET

DIAG_DLY:
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            ACALL   D_20MS
            RET
    ENDIF

; PRT_ACTNAME —— 串口打动作名（调试用）
PRT_ACTNAME:
    IF DEBUG_UART
            MOV     A,      CURACT
            CJNE    A,      #ACT_FORWARD, PAN_1
            MOV     DPTR,   #MSG_FWD
            SJMP    PAN_PR
PAN_1:      CJNE    A,      #ACT_BACK,  PAN_2
            MOV     DPTR,   #MSG_BCK
            SJMP    PAN_PR
PAN_2:      CJNE    A,      #ACT_LEFT,  PAN_3
            MOV     DPTR,   #MSG_LFT
            SJMP    PAN_PR
PAN_3:      CJNE    A,      #ACT_RIGHT, PAN_4
            MOV     DPTR,   #MSG_RGT
            SJMP    PAN_PR
PAN_4:      MOV     DPTR,   #MSG_STP
PAN_PR:
            ACALL   PRINT_STR
    ENDIF
            RET

; PUT_HEX —— A -> 两个十六进制字符（测键值/看脉宽用）
    IF DEBUG_UART
PUT_HEX:
            MOV     R2,     A
            SWAP    A
            ANL     A,      #0FH
            ACALL   PUT_NIB
            MOV     A,      R2
            ANL     A,      #0FH
            ACALL   PUT_NIB
            RET

PUT_NIB:                                ; A = 0..15 -> '0'..'F'
            ADD     A,      #30H
            CJNE    A,      #3AH,   PN_OUT
PN_OUT:
            JC      PN_SEND
            ADD     A,      #7
PN_SEND:
            ACALL   PUTCHAR
            RET
    ELSE
PUT_HEX:    RET
PUT_NIB:    RET
    ENDIF

;=========================================================================
; 延时（机器周期 = 1.085us）；中断仍在后台跑 PWM/蜂鸣器，不影响电机
;   D_1MS 用 R1/R2；D_20MS 用 R3。都不碰主循环的 R7。
;=========================================================================
D_1MS:
            MOV     R2,     #2
D1M_1:      MOV     R1,     #230
D1M_2:      DJNZ    R1,     D1M_2
            DJNZ    R2,     D1M_1
            RET                             ; ≈ 1.01ms

D_20MS:
            MOV     R3,     #10
D20M_1:     ACALL   D_1MS
            DJNZ    R3,     D20M_1
            RET

;=========================================================================
; 常量表
;=========================================================================
GEARTAB:                                ; 档位 0..5 的段码（bit0 = D3）
            DB  DISP_0, DISP_1, DISP_2, DISP_3, DISP_4, DISP_5

DUTYTAB:                                ; 档位 1..5 的 PWM 占空比档（0..20 = 0..100%）
            DB  4, 8, 12, 16, 20

ARCTAB:                                 ; ★ R9：弧线转弯的"内轮"占空比（外轮的 **40%**）
            DB  2, 3, 5, 6, 8           ; 档位 1..5；外轮是 DUTYTAB 的 4/8/12/16/20
                                        ; （= v12"一半"与 v14"1/4"的**中间值**；用户两次反馈后的取值）
                                        ; ★ **转弯半径就是这个表的函数**：
                                        ;   内轮越**接近**外轮 -> 半径越**大**（弯越缓）；
                                        ;   内轮越**小**           -> 半径越**小**（弯越急）。
                                        ;   ⚠️ 内轮 = 0 时这一轮不走 -> 车**绕着它原地转**（最急的"弧线"）。
                                        ;   想再调，直接改下面那一行（备选都列好了）。
; -- 备选（把上面那行 DB 换成下面任意一行即可）-------------------------
;   最急  DB  0, 0, 0, 0, 0     绕"不转的那个轮"原地转
;   很急  DB  1, 2, 3, 4, 5     （v14，用户反馈"太急"）
;   较急  DB  2, 3, 5, 6, 8     <== **当前**（≈外轮 40%，两次反馈的中间值）
;   中    DB  2, 4, 6, 8, 10    （v12，用户反馈"半径太大"）
;   较缓  DB  3, 6, 9, 12, 15   （v13，方向调反那次）
;   很缓  DB  4, 7, 11, 15, 19  接近直行微调
; ---------------------------------------------------------------------

MODETAB:                                ; 模式代号段码（索引 = MODE_*，块③）
            DB  DISP_0, DISP_L, DISP_T  ; 0=手动, 1=寻光"L", 2=循迹"t"（避障已改成全局闸门，不是模式）
            DB  DISP_P                  ; ★ 块⑧：3 = 回放"P"
                                        ;   注意 MODE_PLAY==3==NMODES，**不在 S3 长按的循环里**，
                                        ;   只能靠遥控数字键 8 直选进入（见 MODE_PLAY 的说明）。

    IF DIAG_IR
HEXSEG:                                 ; 0..F 段码（共阳，bit0 = D3 = 1 灭）
            DB  03H,9FH,25H,0DH,99H,49H,41H,1FH   ; 0 1 2 3 4 5 6 7
            DB  01H,09H,11H,81H,63H,85H,61H,71H   ; 8 9 A b C d E F
    ENDIF        ; 20 / 40 / 60 / 80 / 100%

;=========================================================================
; 字符串（串口用纯 ASCII）
;   DEBUG_UART = 0 时只保留调用点还引用得到的 4 个（定义成空串），其余整段不编进去。
;=========================================================================
    IF DEBUG_UART
MSG_BOOT:
            DB  0DH,0AH,'=== CAR FW b2: motor + gear + IR (P3.3) ===',0DH,0AH
            DB  'IR 46F 15B 44L 43R 40S | S3/S4 gear | 7seg=gear D3=moving',0DH,0AH,0
MSG_KEY:
            DB  0DH,0AH,'K=',0
MSG_FWD:    DB  ' FWD',0
MSG_BCK:    DB  ' BCK',0
MSG_LFT:    DB  ' LFT',0
MSG_RGT:    DB  ' RGT',0
MSG_STP:    DB  ' STP',0
MSG_UNK:    DB  ' UNKNOWN KEY (no motor change)',0
MSG_RELEASE:
            DB  0DH,0AH,'(key released -> STOP)',0
MSG_IRERR:
            DB  0DH,0AH,'! IR rej lo=',0
MSG_IRERR2: DB  ' hi=',0
MSG_IRERR3: DB  ' a=',0
MSG_IRERR4: DB  ' b=',0
MSG_IRERR5: DB  ' c=',0
MSG_IRERR6: DB  ' d=',0
MSG_GEAR:
            DB  0DH,0AH,'gear ',0
MSG_DUTY:
            DB  '  duty=',0
MSG_PCT:
            DB  '%',0
    ELSE
MSG_BOOT:   DB  0
MSG_KEY:    DB  0
MSG_UNK:    DB  0
MSG_RELEASE: DB 0
    ENDIF

;=========================================================================
; ★★★ 块⑦ 示教录制（2026-09-20 设计冻结通过）
;-------------------------------------------------------------------------
;   记录单元 3 B（与报告表 3 一致）：
;       Byte0 = (Action << 4) | (Gear & 0x0F)
;       Byte1 = Duration 低 8 位
;       Byte2 = Duration 高 8 位      单位 = 10ms（实为 9.983ms）
;   记录区：片内扩展 RAM 0x0000~0x00EF（80 条 × 3 B = 240 B）
;   ★★ 只能用 MOVX @DPTR —— MOVX @Ri 会拿 P2 当高 8 位地址，而 P2 整口是数码管段选，
;      一用就把显示打花（config.h 里有实测记录）。
;
;   录制 = **叠加在手动模式上的一个标志**（RECON），**不是模式**：
;   因为录制时遥控键仍然要驱动电机（人得把车"开"给车看）。
;
;   ★ 记什么：每 10ms 采一次 (CURACT, GEAR) —— 记的是"**操作意图**"。
;     所以避障把动作改写成"原地右转"时，记录里仍是人的原动作。
;     ⇒ **演示示教时请保持前方畅通**：录制时车会绕障，但回放时不会（回放遇障是停车终止）。
;
;   ⚠️ 本段整体放在文件**最后**（字符串之后、END 之前）—— 这样**前面所有既有标号都不移位**，
;      既有的 SJMP/ACALL 一个都不会因为变远而报 TARGET OUT OF RANGE。
;   ⚠️ 因此本段调既有例程**一律用 LCALL**：本段跨过了 2KB 边界，ACALL 只能在本页内跳。
;=========================================================================

;-------------------------------------------------------------------------
; REC_KEY —— 录制键（数字键 7 = 42H）：录制中 -> 退出；否则 -> 进入
;-------------------------------------------------------------------------
REC_KEY:
            JNB     RECON,  RK_ENTER
            LJMP    REC_EXIT
RK_ENTER:
            LJMP    REC_ENTER

;-------------------------------------------------------------------------
; REC_ENTER —— 进入录制（T1）
;   停车 -> 清空上一段 -> 复位累计/基准 -> RECON=1 -> 显示 'r' + 响 **一声**
;-------------------------------------------------------------------------
REC_ENTER:
            LCALL   REC_HALT            ; 先停车：录制从静止开始
            MOV     RECN,   #0          ; 清空上一段未保存记录（报告 §3.3 第 1 条）
            CLR     RECFULL
            MOV     CUR_DUR_L, #0
            MOV     CUR_DUR_H, #0
            LCALL   MS10_GET            ; 采样基准 = 现在
            MOV     SAMP_H, R4
            MOV     SAMP_L, R5
            MOV     A,      GEAR        ; PACK = (STOP<<4) | 当前档位
            ANL     A,      #GEAR_MASK
            MOV     PACK,   A
            SETB    RECON
            LCALL   SHOW_STATE          ; RECON=1 -> 显示 'r'（见 SHOW_STATE 的 M9）
            MOV     A,      #BEEP_TICKS
            LCALL   BEEP
            RET

;-------------------------------------------------------------------------
; REC_EXIT —— 退出录制（T4：再按一次录制键）：封存余量 -> 回档位显示 + 响 **两声**
;-------------------------------------------------------------------------
REC_EXIT:
            MOV     A,      CUR_DUR_L   ; 最后一段还有内容就封存
            ORL     A,      CUR_DUR_H
            JZ      REC_EXIT_NOW
            LCALL   REC_COMMIT
REC_EXIT_NOW:
            CLR     RECON
            MOV     CUR_DUR_L, #0
            MOV     CUR_DUR_H, #0
            LCALL   SHOW_STATE          ; RECON 已清 -> 显示档位
            MOV     A,      #BEEP_TICKS ; 退出：**两声**（与进入的一声区分）
            LCALL   BEEP
            LCALL   D_20MS
            MOV     A,      #BEEP_TICKS
            LCALL   BEEP
            RET

;-------------------------------------------------------------------------
; REC_SAMPLE —— 录制采样（每趟主循环调用；内部按 10ms 时基判断）
;   ① delta = 10ms 时基 - SAMP；delta==0 -> 直接返回（还没到下一个 10ms）
;   ② 打包当前 (CURACT, GEAR) 与 PACK 比：
;        相同 -> CUR_DUR += delta  （**累计**，所以主循环偶发阻塞也不丢时间）
;        不同 -> 提交上一条，PACK 换新，CUR_DUR 归零
;   ③ 单条时长上限（D2）到 / 16 位溢出 -> 拆条（同 PACK 再起一条，**总时长守恒**）
;   破坏：A、B、DPTR、R4~R7、C
;-------------------------------------------------------------------------
REC_SAMPLE:
            JNB     RECFULL, RS_GO      ; 已满 -> 不再采，去收尾
            LJMP    REC_FULLSTOP
RS_GO:
            LCALL   MS10_GET            ; R4:R5 = now
            MOV     A,      R5
            CLR     C
            SUBB    A,      SAMP_L
            MOV     R6,     A            ; R6 = delta 低
            MOV     A,      R4
            SUBB    A,      SAMP_H
            MOV     R7,     A            ; R7 = delta 高
            MOV     A,      R7
            ORL     A,      R6
            JZ      RS_DONE              ; delta==0 -> 还不到一个 10ms
            MOV     SAMP_H, R4           ; 基准推进到"现在"
            MOV     SAMP_L, R5

            MOV     A,      CURACT       ; ---- 打包当前 (Action,Gear) ----
            SWAP    A
            ANL     A,      #ACTPK_MASK
            MOV     R5,     A
            MOV     A,      GEAR
            ANL     A,      #GEAR_MASK
            ORL     A,      R5
            MOV     R5,     A            ; R5 = 当前打包值
            CJNE    A,      PACK, RS_CHANGED

            MOV     A,      CUR_DUR_L    ; ---- 同一条：累加时长 ----
            ADD     A,      R6
            MOV     CUR_DUR_L, A
            MOV     A,      CUR_DUR_H
            ADDC    A,      R7
            MOV     CUR_DUR_H, A
            JC      RS_SPLIT             ; 16 位溢出 -> 拆条
            MOV     A,      CUR_DUR_H    ; ---- 单条上限（D2，按高字节判）----
            CJNE    A,      #RECCAP_H, RS_CAPCHK
            SJMP    RS_SPLIT             ; 正好到上限 -> 拆
RS_CAPCHK:
            JNC     RS_SPLIT             ; 超上限 -> 拆
RS_DONE:
            RET

RS_CHANGED:
            ; 动作/档位变了：提交上一条，再开新的一条
            ; ★ 新打包值在 R5；REC_COMMIT 不碰 R5（只用 A/B/DPTR）
            LCALL   REC_COMMIT
            JNC     RS_DONE              ; 缓冲区满 -> 交给下一趟的 RECFULL 收尾
            MOV     PACK,   R5
            RET

RS_SPLIT:
            ; 到上限/溢出：提交当前条，**同一 PACK** 再起一条。
            ; ★ 两条相邻同 (Action,Gear) 的记录**回放时与一条长记录完全等价**
            ;   （MOTOR_SET_ACT 幂等、两条之间不停车无间隙）⇒ 演示看不出差别，且总时长守恒。
            LCALL   REC_COMMIT
            RET

;-------------------------------------------------------------------------
; REC_COMMIT —— 把 (PACK, CUR_DUR) 写入 XRAM 第 RECN 条
;   出：C=1 写入成功（RECN 已 ++，CUR_DUR 已清零）；C=0 已满（未写入）
;   破坏：A、B、DPTR、C
;   ★ 前导停止不记录：一条都还没录到时，动作=STOP 的片段直接丢弃（省记录、演示干净）
;-------------------------------------------------------------------------
REC_COMMIT:
            MOV     A,      PACK        ; ---- 前导 STOP 过滤 ----
            ANL     A,      #ACTPK_MASK
            JNZ     RC_GO
            MOV     A,      RECN
            JNZ     RC_GO               ; 已有记录 -> STOP 也要记（报告表 5 要求序列含"停止"）
            MOV     CUR_DUR_L, #0       ; 前导 STOP -> 丢弃
            MOV     CUR_DUR_H, #0
            SETB    C
            RET
RC_GO:
            MOV     A,      RECN
            CJNE    A,      #REC_MAX, RC_ROOM
            SETB    RECFULL             ; 已满 80 条
            CLR     C
            RET
RC_ROOM:
            MOV     B,      #REC_UNIT   ; ---- DPTR = RECN × 3（MUL AB，工程里有先例）----
            MUL     AB
            MOV     DPL,    A
            MOV     DPH,    B
            MOV     A,      PACK        ; ---- 写 3 字节 ----
            MOVX    @DPTR,  A
            INC     DPTR
            MOV     A,      CUR_DUR_L
            MOVX    @DPTR,  A
            INC     DPTR
            MOV     A,      CUR_DUR_H
            MOVX    @DPTR,  A
            INC     RECN                ; ---- 计数 +1；到 80 置满 ----
            MOV     A,      RECN
            CJNE    A,      #REC_MAX, RC_RESET
            SETB    RECFULL
RC_RESET:
            MOV     CUR_DUR_L, #0
            MOV     CUR_DUR_H, #0
            SETB    C
            RET

;-------------------------------------------------------------------------
; REC_HALT —— 立刻停车（录制/回放的公共出口）
;   破坏：A、R6、R7（MOTOR_SET_ACT 内部用 R6 暂存动作码）
;-------------------------------------------------------------------------
REC_HALT:
            MOV     CURACT, #ACT_STOP
            MOV     R7,     #0
            MOV     A,      #ACT_STOP
            LCALL   MOTOR_SET_ACT
            RET

;-------------------------------------------------------------------------
; REC_FULLSTOP —— 录到 80 条上限：自动停录 + 停车 + 显示 'F' + 长响约 400ms（T6）
;   ★ 已录数据**保留**（仍可按回放键放这 80 条）
;-------------------------------------------------------------------------
REC_FULLSTOP:
            CLR     RECON
            MOV     CUR_DUR_L, #0
            MOV     CUR_DUR_H, #0
            LCALL   REC_HALT
            MOV     R6,     #20          ; 20 × 20ms = 400ms
RF_LOOP:
            MOV     P2,     #DISP_F
            MOV     A,      #BEEP_TICKS
            LCALL   BEEP
            LCALL   D_20MS
            DJNZ    R6,     RF_LOOP
            LCALL   SHOW_STATE
            RET

;-------------------------------------------------------------------------
; REC_ERR —— 空记录 / 非法操作提示：闪 'E' + 两声短响（T8）
;   破坏：A、R6
;-------------------------------------------------------------------------
REC_ERR:
            MOV     P2,     #DISP_E
            MOV     A,      #BEEP_KEY
            LCALL   BEEP
            LCALL   D_20MS
            LCALL   D_20MS
            MOV     A,      #BEEP_KEY
            LCALL   BEEP
            LCALL   D_20MS
            LCALL   D_20MS
            LCALL   SHOW_STATE
            RET

;-------------------------------------------------------------------------
; CLR_KEY —— 清空键（数字键 9 = 4AH）
;   ★ 决定 D5：**只允许"车停着"且"不在回放"时清空**（防误触）；
;     录制中按也可以（= 丢弃整段并退出录制）。
;-------------------------------------------------------------------------
CLR_KEY:
            MOV     A,      MODE
            CJNE    A,      #MODE_PLAY, CK_CHK
            RET                         ; 回放中 -> 忽略（先退出回放再清）
CK_CHK:
            MOV     A,      CURACT
            JZ      CK_DO
            RET                         ; 车在动 -> 忽略（防误清）
CK_DO:
            CLR     RECON               ; 录制中也允许（丢弃整段）
            MOV     RECN,   #0
            CLR     RECFULL
            MOV     CUR_DUR_L, #0
            MOV     CUR_DUR_H, #0
            LCALL   SHOW_STATE
            MOV     A,      #BEEP_TICKS ; 清空：**两声**（与"进入录制"的一声区分）
            LCALL   BEEP
            LCALL   D_20MS
            MOV     A,      #BEEP_TICKS
            LCALL   BEEP
            RET

;=========================================================================
; ★★★ 块⑧ 示教回放（2026-09-20 设计冻结通过）
;-------------------------------------------------------------------------
;   ★★ 回放走 MAIN_LOOP **最前面的独立分支** -> **不进 AV_GATE**、**不进 KEY_SCAN**。
;      原因见 M1b 的说明（避障闸门是"改写成右转绕过去"，与"遇障停车终止"语义相反）。
;   ★ 节拍：用 MS10（Timer0 中断里维护的 10ms 时基）。
;      **不用主循环数节拍** —— 主循环周期不是常数，靠它会差 26%（远超报告 ±5%）。
;   ★ 回放期间收遥控用 IR_RECV_NB（不阻塞），主循环周期 ≈1~3ms
;     -> 人工停止/方向键响应 ≤3ms，动作切换抖动 ≤3ms。
;   ★ 档位：**恢复记录里的档位**（决定 D8）—— 不恢复则"复现"不完整（速度直接决定落点）。
;     退出回放时再把档位恢复成进入前的值（PLAY_GEAR0）。
;=========================================================================

;-------------------------------------------------------------------------
; IR_RECV_NB —— **非阻塞**收一帧（回放专用）
;   与 IR_RECV 的唯一区别：把"阻塞等下降沿（最长 25.6ms）"换成**一次判断**，
;   其余解码流程**直接跳进原有的 IR_EDGE**，一行不改。
;   出口 IRSTAT 与 IR_RECV 完全一样（0=完整帧 / 1=静默 / 2=被拒 / 3=重复帧 / 5 / 6）。
;   ★ 可行性：引导码低电平有 9ms 宽，而回放主循环 ≈1~3ms -> 最多晚 3ms 才进解码，
;     量到的引导码低电平 ≈6~9ms，仍在 IR_LEAD_MIN(70)~IR_LEAD_MAX(120) = 7~12ms 窗口内 ✅
;-------------------------------------------------------------------------
IR_RECV_NB:
            MOV     CAP_L,  #0
            MOV     LEDLO,  #0
            MOV     LEDHI,  #0
            MOV     SHORTL, #0
            MOV     IRSTAT, #1
            JB      IR_IN,  IRNB_OUT    ; 空闲高 -> 没有帧，立刻返回（**不阻塞**）
            LJMP    IR_EDGE             ; 已在下降沿 -> 走原有解码流程
IRNB_OUT:
            RET

;-------------------------------------------------------------------------
; PLAY_KEY —— 回放键（数字键 8 = 52H）
;   ★ 录制中按 -> 先封存录制（T7），再进回放
;   ★ 已在回放中按 -> 退出回放
;-------------------------------------------------------------------------
PLAY_KEY:
            JB      RECON,  PK_STOPREC
            MOV     A,      MODE
            CJNE    A,      #MODE_PLAY, PK_EN
            LCALL   PLAY_EXIT           ; 已在回放 -> 再按一次 = 退出
            RET                         ; ★ 本段是从 DO_KEY 用 LJMP 跳进来的（栈上留着
                                        ;   `ACALL DO_KEY` 的返回地址），所以用 RET 收尾
                                        ;   = 等价于 DO_KEY 正常返回，**这是对的**（别改成 LJMP）
PK_STOPREC:
            LCALL   REC_EXIT            ; 录制中 -> 先封存（T7）
PK_EN:
            LJMP    PLAY_ENTER          ; PLAY_ENTER 以 RET 结尾，同样借 DO_KEY 的返回地址收尾 ✓

;-------------------------------------------------------------------------
; PLAY_ENTER —— 进入回放（T2）
;   空记录 -> 拒绝（闪 'E' + 两声，**不进回放**）
;   否则：存档位 -> AVST 放行 -> PLAYIDX=0 -> MODE=MODE_PLAY -> 装载第 0 条 -> 显示 'P'
;-------------------------------------------------------------------------
PLAY_ENTER:
            MOV     A,      RECN
            JNZ     PE_GO
            LCALL   REC_ERR             ; RECN==0 -> 拒绝回放（T8，不死循环）
            RET
PE_GO:
            MOV     PLAY_GEAR0, GEAR    ; 记下进入前的档位（退出时恢复）
            ; ★★ 关键：回放不进 AV_GATE，但 MOTOR_SET_ACT 会读 AVST 决定要不要改写动作。
            ;    若 AVST 停在 AV_TURN，回放的**每一个动作**都会被改写成"原地右转"。
            ;    所以进回放必须显式放行。
            MOV     AVST,   #AV_FREE
            MOV     PLAYIDX, #0
            MOV     CURACT, #ACT_STOP
            MOV     MODE,   #MODE_PLAY
            MOV     LASTCMD,#LASTCMD_NONE
            LCALL   PLAY_LOAD           ; 装载第 0 条（内部会设 PLAY_T0）
            LCALL   SHOW_MODE           ; MODETAB[3] = 'P'
            MOV     A,      #BEEP_TICKS
            LCALL   BEEP
            RET

;-------------------------------------------------------------------------
; PLAY_LOAD —— 读 XRAM 第 PLAYIDX 条 -> 拆包 -> 设档位 + MOTOR_SET_ACT + 记起始时刻
;   破坏：A、B、DPTR、R5、R6、R7、C
;-------------------------------------------------------------------------
PLAY_LOAD:
            MOV     A,      PLAYIDX     ; ---- DPTR = PLAYIDX × 3 ----
            MOV     B,      #REC_UNIT
            MUL     AB
            MOV     DPL,    A
            MOV     DPH,    B
            MOVX    A,      @DPTR       ; Byte0 = (Action<<4) | Gear
            MOV     R6,     A
            INC     DPTR
            MOVX    A,      @DPTR       ; Byte1 = 时长低
            MOV     PLAY_DUR_L, A
            INC     DPTR
            MOVX    A,      @DPTR       ; Byte2 = 时长高
            MOV     PLAY_DUR_H, A
            MOV     A,      R6          ; ---- 拆档位（低 4 位）----
            ANL     A,      #GEAR_MASK
            MOV     GEAR,   A           ; ★ D8：恢复记录里的档位
            MOV     A,      R6          ; ---- 拆动作（高 4 位）----
            SWAP    A
            ANL     A,      #0FH        ; 换到低 4 位后**只能掩 0FH**（用 ACTPK_MASK 会清零）
            MOV     CURACT, A
            MOV     R7,     GEAR
            LCALL   MOTOR_SET_ACT       ; ★ 唯一电机出口（会碰 R6，所以上面先用完）
            LCALL   MS10_GET            ; ---- 本条起始时刻 ----
            MOV     PLAY_T0_H, R4
            MOV     PLAY_T0_L, R5
            RET

;-------------------------------------------------------------------------
; PLAY_SAFETY —— 回放安全检测（设计冻结 §3.4，**优先级最高**）
;   出：**C=1 = 危险**（调用方停车 + 终止回放）；C=0 = 安全
;   ★★★ 与手动/寻光的避障**语义不同**：这里只判"要不要终止"，
;        **绝不改写路径、不绕行** —— 这正是"复现示教路径"与"自主重新规划"的定义性差别。
;   ★ 车头红外（P3.7）**每趟**查：零成本、量程 1~2cm，兜"已经贴上了"的最后一道。
;   ★ 超声波**每 ≥60ms 一次**：HC-SR04 规格要求测距周期 ≥60ms，
;     太密会让上一次的余振被当成回波 -> 误报 -> 回放被无端终止。
;   ⚠️ 节流计时**复用 SAMP_L/H**：录制与回放互斥（回放时 RECON=0，REC_SAMPLE 不会跑），
;      所以这两字节在回放期间是空闲的 —— 这是**有意复用**，不是笔误。
;   破坏：A、C、R5、R6、R7（US_READ 还会碰 R2）
;-------------------------------------------------------------------------
PLAY_SAFETY:
            LCALL   IR_DET
            JC      PSF_DANGER          ; 车头红外"贴上了" -> 立刻危险
            LCALL   MS10_GET            ; R4:R5 = now
            MOV     A,      R5
            CLR     C
            SUBB    A,      SAMP_L
            MOV     R6,     A
            MOV     A,      R4
            SUBB    A,      SAMP_H
            MOV     R7,     A            ; R7:R6 = 距上次测距的 10ms 数
            MOV     A,      R7
            JNZ     PSF_MEAS            ; 高字节非 0 -> 早就超过 60ms 了
            MOV     A,      R6
            CLR     C
            SUBB    A,      #PSF_GAP
            JC      PSF_SAFE            ; 还没到 60ms -> 这次不测（留给红外兜底）
PSF_MEAS:
            MOV     SAMP_H, R4          ; 记下本次测距时刻
            MOV     SAMP_L, R5
            LCALL   US_READ             ; 出 R5 = 回波 tick（≈1.72cm/tick，0FFH = 够远）
            MOV     A,      R5
            CLR     C
            SUBB    A,      #US_STOP    ; < US_STOP(≈5cm) -> 太近
            JC      PSF_DANGER
PSF_SAFE:
            CLR     C
            RET
PSF_DANGER:
            SETB    C
            RET

;-------------------------------------------------------------------------
; PLAY_ABORT —— 回放被**安全**终止（T12）：停车 + 标记 + 两声短响 + 退出
;   ★ 这里**不绕行、不续播** —— 就是设计要的"安全复现"。
;-------------------------------------------------------------------------
PLAY_ABORT:
            SETB    PLAYERR
            LCALL   REC_HALT            ; 停车
            MOV     A,      #BEEP_KEY   ; 两声短响（与"正常播完"区分）
            LCALL   BEEP
            LCALL   D_20MS
            MOV     A,      #BEEP_KEY
            LCALL   BEEP
            LJMP    PLAY_EXIT

;-------------------------------------------------------------------------
; PLAY_EXIT —— 退出回放（设计冻结 §3.3 的 7 步收尾；三个出口共用）
;-------------------------------------------------------------------------
PLAY_EXIT:
            LCALL   REC_HALT            ; ① 停车（并清 CURACT）
            MOV     MODE,   #MODE_MANUAL ; ② 回手动
            MOV     GEAR,   PLAY_GEAR0  ; ③ 恢复进入回放前的档位
            MOV     AVST,   #AV_FREE    ; ④ 避障重新武装（下一趟 AV_GATE 自己重算）
            MOV     LASTCMD,#LASTCMD_NONE ; ⑤ 允许同一个键再按一次
            MOV     PLAYIDX, #0         ; ⑥ 索引归零
            LCALL   SHOW_STATE          ; ⑦ 刷回档位显示
            RET

;-------------------------------------------------------------------------
; PLAY_STEP —— 回放一步（MAIN_LOOP 最前面的独立分支调用）
;   ① 安全（最高优先）：危险 -> 立刻停车 + 终止（**不等待本条播完**）
;   ② 遥控（非阻塞）：停止键 / 任意方向键 / 回放键 -> 人工终止
;   ③ 计时：本条到点 -> 下一条；索引到头 -> 正常播完
;   破坏：A、B、DPTR、R4~R7、C
;
;   ★★★ 栈约定（2026-09-20 修 bug，务必遵守）：
;     本段是 MAIN_LOOP 用 **`LJMP`** 跳进来的（不是 ACALL），**栈上没有返回地址**，
;     所以**所有出口必须是 `LJMP MAIN_LOOP`，绝不能 `RET`**；
;     所有子例程必须用 **`LCALL`**（不能 LJMP 到一个以 RET 结尾的例程再指望它回来）。
;     ⚠️ 原来的写法是 `RET` —— 它会从栈里弹出一个**根本没压过**的地址 -> 跳到垃圾地址
;        -> 表现为"**按 8 完全不会回放**"（程序跳飞/复位）。这是实测暴露的根因。
;-------------------------------------------------------------------------
PLAY_STEP:
            LCALL   PLAY_SAFETY
            JNC     PS_KEY
            LCALL   PLAY_ABORT          ; ★ 危险 -> 停车终止（**不绕行**）
            LJMP    MAIN_LOOP           ; ★ 出口一律 LJMP MAIN_LOOP（见上面的栈约定）

PS_KEY:
            LCALL   IR_RECV_NB
            MOV     A,      IRSTAT
            JNZ     PS_TIME             ; 不是完整帧（静默/重复/被拒）-> 不管
            MOV     A,      IB2
            CJNE    A,      #KEY_PLAY, PS_K1
            LCALL   PLAY_EXIT           ; 再按回放键 = 退出
            LJMP    MAIN_LOOP
PS_K1:
            ; ---- 停止键与任意方向键都算"人工终止"（停止最高人工优先）----
            ;   用现成的 KEY2ACT 判：方向键/停止键给动作码，其余键给 ACT_NONE。
            ;   （比逐键 CJNE 省一半字节，而且与手动模式的口径完全一致）
            MOV     A,      IB2
            LCALL   KEY2ACT
            CJNE    A,      #ACT_NONE, PS_HUMAN
            SJMP    PS_TIME
PS_HUMAN:
            LCALL   PLAY_EXIT           ; ★ D6：只退出 + 停车，**不顺便执行该方向**
            LJMP    MAIN_LOOP

PS_TIME:
            LCALL   MS10_GET            ; ---- 本条到点了吗（R7:R6 = 已播时长）----
            MOV     A,      R5
            CLR     C
            SUBB    A,      PLAY_T0_L
            MOV     R6,     A
            MOV     A,      R4
            SUBB    A,      PLAY_T0_H
            MOV     R7,     A
            MOV     A,      R7
            CLR     C
            SUBB    A,      PLAY_DUR_H
            JC      PS_RET              ; 高字节还小 -> 没到
            JNZ     PS_NEXT             ; 高字节已大 -> 到了
            MOV     A,      R6          ; 高字节相等 -> 比低字节
            CLR     C
            SUBB    A,      PLAY_DUR_L
            JC      PS_RET              ; 低字节还小 -> 没到
PS_NEXT:
            INC     PLAYIDX
            MOV     A,      RECN        ; ---- 索引到头了吗（先判后读，绝不越界）----
            CLR     C
            SUBB    A,      PLAYIDX
            JZ      PS_END              ; PLAYIDX == RECN -> 播完
            JC      PS_END              ; PLAYIDX >  RECN -> 防御性结束（不该发生）
            LCALL   PLAY_LOAD
PS_RET:
            LJMP    MAIN_LOOP           ; ★★★ 原来的 `RET` 就是"按 8 不回放"的根因
PS_END:
            LCALL   PLAY_EXIT           ; 播完 -> 正常结束（T8/T10）
            LJMP    MAIN_LOOP

            END
