;=========================================================================
; usfollow.asm  --  超声波跟随小车（HC-SR04 型模块）
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name usfollow
; 串口输出 : P3.1(TXD) -> CH340 -> COM7，9600 8N1（每几轮打一行距离/动作）
; 上位机   : powershell -NoProfile -ExecutionPolicy Bypass -File tools\read_com.ps1 -Port COM7 -Seconds 300
;=========================================================================
;
; 一、这个程序干什么
;   跟在一个目标后面走，保持 20~30cm 左右的距离：
;       距离 > 28cm  -> 前进追（追不上就一直追）
;       距离 < 14cm  -> 后退让开（贴太近了）
;       中间         -> 停车保持距离
;   门限带迟滞：正在前进时跌到 <22cm 才停，停着时涨到 >28cm 才走
;   （差 6cm 的迟滞 + 三次测量取中值，免得在门限上"走走停停"发抖）。
;   量不到回波（前面约 4m 内什么都没有）先按"追"处理，
;   连续 30 轮（约 4 秒）都没回波 -> 自动安全停车 + 串口报警 + 蜂鸣器响一声。
;
; 二、超声波模块接在哪
;   Trig -> P1.3（DIP40 第 4 脚，图纸网标号 P13TR）
;   Echo -> P1.2（DIP40 第 3 脚，图纸网标号 P12EC）
;   来历：docs\引脚表_原理图追线.md 第 2 节 —— 这两根网在 MCU 侧和右侧 4 脚
;         接插件侧各有一个同名标号（P13TR / P12EC），是追线 + 真文字标号的
;         结论，不是看图猜的。
;
;   ⚠️ 板子上那个 4 脚插座（CSB1），从图纸矢量数据看是：
;         第1脚 = GND（接 GND 三角符号）
;         第2脚 = Echo  EC（网标号 P12EC -> P1.2）
;         第3脚 = Trig  TR（网标号 P13TR -> P1.3）
;         第4脚 = VCC（接 VCCBAT 电源符号，就是电池轨）
;      而常见 HC-SR04 模块自己的 4 个脚是 **VCC / Trig / Echo / GND**，顺序正好反，
;      所以**不要**把模块直接插到插座上！用杜邦线按标号一根一根接：
;         模块 VCC  -> 插座第 4 脚        模块 GND  -> 插座第 1 脚
;         模块 Trig -> 插座第 3 脚        模块 Echo -> 插座第 2 脚
;      接之前先通电用万用表量一下插座上哪一脚是 VCC、哪一脚是 GND，别赌。
;
;   * Echo 是模块输出、5V 电平，直接进 MCU 没问题（STC89C52 是 5V 器件）。
;   * 若实测发现 Trig/Echo 正好接反了（症状：串口一直打 no echo），
;     把下面 US_TRIG / US_ECHO 两行对调，再按 build.ps1 -Name usfollow 编一次即可。
;
; 三、数码管 / 指示灯 / 蜂鸣器
;   数码管（共阳，段选低电平点亮；段序 a=P2.7 b=P2.6 c=P2.5 d=P2.4 e=P2.3 f=P2.2 g=P2.1）
;     显示**距离的十位**："2" = 20~29cm、"3" = 30~39cm …… 超过 90cm 一律显示 "9"。
;     只有一位数码管，两位数显示不了；精确距离看串口（D=025cm）。
;     ⚠️ 注意 P2.0 不是段选，它是 D3 指示灯，别按 "P2.0=a" 去理解。
;   D3 灯（P2.0，写 0 亮）亮 = 电机在动，灭 = 停着。
;   蜂鸣器（P0.6，S8550 PNP 驱动 + 无源，要方波才响）：
;     开机"滴"一声 = 程序在跑；后退（太近了）时每轮短鸣 = 倒车提示；
;     丢失目标判安全停车时也响一声。
;
; 四、安全（都编在程序里，不是靠操作小心）
;   * 上电先停车，且**必须先量到一次有效回波才允许电机动作** ——
;     模块没插好 / Trig、Echo 接反 / 模块坏了，车就原地不动（而不是瞎冲）；
;   * 量不到回波只允许"追"4 秒，之后安全停车（并打印 !! target lost）；
;   * Echo 脚一直高（模块没插好 / 坏了）也走"没回波"这条路 -> 先不动、再停车；
;   * 开机先读一次 Echo 空闲电平：不是低就串口警告（说明模块/接线有问题）；
;   * STA 值不确定的内部 RAM 全部显式清零；
;   * 调试时把小车架起来，让轮子悬空。
;
; 五、引脚（来自 firmware\car\config.h，原理图矢量追线结论）
;   P0.0~P0.3 = L293D INPUT1~4      P0.4 / P0.5 = ENA / ENB（高 = 使能）
;   P0.6 = 蜂鸣器（低 = 响）         P1.2 / P1.3 = Echo / Trig
;   P2.7~P2.1 = 数码管 a~g           P2.0 = D3 指示灯（写 0 亮）
;   P3.1 = TXD（调试串口）
;   P0 是开漏口：写 1 只是"放开"，靠板上 10K 排阻拉高。本程序只做低速开关，不做 PWM。
;=========================================================================

;-------------------------------------------------------------------------
; 一、常量
;-------------------------------------------------------------------------
; --- 超声波模块 ---
US_TRIG     BIT     P1.3        ; 触发（MCU 输出）—— 与 Echo 接反了就两行对调
US_ECHO     BIT     P1.2        ; 回波（MCU 输入）

TRIG_W      EQU     6           ; 触发脉冲宽度：6*2 = 12 机器周期 ≈ 13us（要求 >10us）

; --- 距离换算 ---
;   机器周期 = 12 / 11.0592MHz = 1.0851us
;   1cm 的距离 = 声波往返 2cm = 约 58us = 约 53.4 个机器周期
;   -> cm = 机器周期数 / 53（比真值大约 0.8%，对跟随门限毫无影响）
;   拿卷尺校一下：若串口显示的系统性偏大/偏小，按同样比例改这个除数
;   （偏大约 5% 就改成 55/56，偏小就改成 51/52）。
CM_DIV      EQU     53
CM_FAR      EQU     255         ; "没有回波"时用的"很远"值（cm）

; --- 跟随门限（cm，带迟滞）---
;   停着时：d >= GO_HI   -> 前进追
;           d <  BACK_HI -> 后退让
;           中间         -> 继续停
;   前进时：d <  HOLD_LO -> 停        （比 GO_HI 低 6cm = 迟滞）
;   后退时：d >= BACK_LO -> 停
GO_HI       EQU     28
HOLD_LO     EQU     22
BACK_HI     EQU     14
BACK_LO     EQU     8

LOST_MAX    EQU     30          ; 连续 30 轮没回波 -> 安全停车（每轮约 90~150ms，约 4 秒）
PRT_DIV     EQU     4           ; 串口每 4 轮打一行（动作变化时立刻打）

; --- 动作码（与 car\config.h / remote.asm 保持一致）---
ACT_STOP    EQU     00H
ACT_FORWARD EQU     01H
ACT_BACK    EQU     02H

; --- P0 输出图案（b0..b3 = IN1..IN4，b4 = ENA，b5 = ENB，b6 = 蜂鸣器 1=静音，b7 = 1）---
;   停车时 ENA/ENB 一起拉低 = 电机断电滑行，比"刹车"更省电、更安全。
PAT_STOP    EQU     0C0H
PAT_FORWARD EQU     0F5H        ; IN1 + IN3 -> 两个轮子同向
PAT_BACK    EQU     0FAH        ; IN2 + IN4

BEEP_CYCLES EQU     12          ; 短鸣 12 个 1kHz 半周期 ≈ 12ms

;-------------------------------------------------------------------------
; 二、RAM 变量（数据区 30H 起；本程序不用中断，寄存器随便用，但变量要显式清零）
;-------------------------------------------------------------------------
S0          DATA    30H         ; 距离滑动窗口（三次测量，中值滤波用）
S1          DATA    31H
S2          DATA    32H
MED         DATA    33H         ; 中值滤波后的距离（cm）
CURACT      DATA    34H         ; 当前动作码
MOTPAT      DATA    35H         ; 当前 P0 图案（蜂鸣器位保持 1 = 静音）
NOECHO      DATA    36H         ; 本轮有没有回波（1 = 没有）
LOSTCNT     DATA    37H         ; 连续"没回波"的轮数
PRTCNT      DATA    38H         ; 串口打印分频计数
LASTACT     DATA    39H         ; 上一次打印时的动作码（用来"动作一变就打印"）
SCRL        DATA    3AH         ; 临时
TKH         DATA    3BH         ; 本轮 Echo 高电平的机器周期数（高/低字节，诊断用）
TKL         DATA    3CH
VALID       DATA    3DH         ; 有没有成功量到过一次回波（0 = 还没有）

;-------------------------------------------------------------------------
; 三、主程序
;-------------------------------------------------------------------------
            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H

            ; ---- 上电先停车、蜂鸣器静音、灯全灭 ----
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
            MOV     PRTCNT, #1
            MOV     S0,     #CM_FAR
            MOV     S1,     #CM_FAR
            MOV     S2,     #CM_FAR
            MOV     MED,    #CM_FAR
            MOV     TKH,    #0
            MOV     TKL,    #0
            MOV     VALID,  #0

            ; ---- 串口 9600 8N1（Timer1 方式2）----
            ;      TMOD 高半字节管 T1，低半字节管 T0
            ;      T0 方式1（16 位定时器）留给超声波量 Echo 宽度
            MOV     TMOD,   #21H
            MOV     TH1,    #0FDH       ; 11059200/(384*3) = 9600
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H        ; 方式1
            MOV     PCON,   #00H        ; SMOD = 0
            SETB    TR1

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

            ; ---- 开机自检：模块没插好时 Echo 脚会浮空/被拉高 ----
            JB      US_ECHO, M_ECHOHI
            MOV     DPTR,   #MSG_ECHOOK
            ACALL   PRINT_STR
            SJMP    M_BEEP
M_ECHOHI:
            MOV     DPTR,   #MSG_ECHOHI
            ACALL   PRINT_STR
M_BEEP:
            ACALL   BEEP_SHORT          ; 开机"滴"一声 = 程序确实跑起来了

;=========================================================================
; 主循环：测距 -> 中值滤波 -> 决策（带迟滞）-> 电机/数码管/串口 -> 等 60ms
;   HC-SR04 要求两次触发间隔 >= 60ms，所以每轮末尾固定等 60ms。
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
            MOV     SCRL,   A
            MOV     NOECHO, #0
            MOV     LOSTCNT,#0          ; 只要见到回波，丢失计数就清零
            MOV     VALID,  #1          ; 而且从这一刻起才允许电机动
            SJMP    L_FILTER

L_NOECHO:
            MOV     TKH,    #0
            MOV     TKL,    #0
            MOV     SCRL,   #CM_FAR     ; 往窗口里塞一个"很远"
            MOV     NOECHO, #1
            MOV     A,      LOSTCNT
            CJNE    A,      #LOST_MAX, L_LOSTADD
            SJMP    L_FILTER            ; 已经判过安全停车了，不再累加（等回波回来）
L_LOSTADD:
            INC     A
            MOV     LOSTCNT,A
            CJNE    A,      #LOST_MAX, L_FILTER
            ; ---- 刚刚判定"目标丢失"：报警一次 ----
            ;      区分两种情况：跟丢过目标 / 从头到尾一次回波都没量到（接线问题）
            MOV     A,      VALID
            JZ      L_WAITMSG
            MOV     DPTR,   #MSG_SAFE
            SJMP    L_SAY
L_WAITMSG:
            MOV     DPTR,   #MSG_WAIT
L_SAY:
            ACALL   PRINT_STR
            MOV     PRTCNT, #1          ; 顺便让这一轮一定打一行状态
            ACALL   BEEP_SHORT

            ; ---- 2) 三次测量取中值（窗口滑动：S0 最旧，S2 最新）----
L_FILTER:
            MOV     A,      S1
            MOV     S0,     A
            MOV     A,      S2
            MOV     S1,     A
            MOV     S2,     SCRL
            ACALL   MED3                ; -> MED

            ; ---- 3) 决策 ----
            MOV     A,      VALID
            JNZ     L_CHKLOST
            ; 一次有效回波都还没量到（模块没插好 / Trig、Echo 接反 / 坏了）
            ; -> 一律停车。宁可不动，也不能"因为量不到就往前冲"。
            MOV     A,      #ACT_STOP
            SJMP    L_APPLY
L_CHKLOST:
            MOV     A,      LOSTCNT
            CJNE    A,      #LOST_MAX, L_DECIDE
            MOV     A,      #ACT_STOP   ; 丢失太久：安全停车待机
            SJMP    L_APPLY
L_DECIDE:
            ACALL   DECIDE              ; MED -> A = 动作码（带迟滞）

            ; ---- 4) 动作落地 ----
L_APPLY:
            MOV     CURACT, A
            ACALL   MOTOR_SET_ACT       ; 动作码 -> P0
            ACALL   SHOW_DIST           ; 距离 -> 数码管 + D3 灯
            ACALL   REPORT              ; 串口打印（节流）

            ; ---- 5) 太近了就边退边鸣（倒车提示）----
            MOV     A,      CURACT
            CJNE    A,      #ACT_BACK, L_CYCLE
            ACALL   BEEP_SHORT
L_CYCLE:
            ACALL   D_60MS              ; 两次触发之间至少 60ms
            SJMP    LOOP

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
;   原理：cm = 机器周期数 / 53（见常量区的换算说明）
;   用"反复减 53、数次数"的除法：够直观、够便宜。最坏情况（65535 周期）
;   也就 1236 次减法约 15ms，一轮里出一次，无所谓。
;=========================================================================
TICKS2CM:
            MOV     R4,     #0          ; 商高字节（只要不是 0 就说明 > 255cm）
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
            SJMP    T2C_LOOP
T2C_CAP:
            MOV     A,      #255
            RET
T2C_DONE:
            MOV     A,      R5
            RET

;=========================================================================
; DECIDE：中值距离 -> 动作码（带迟滞）
;   入：MED（cm）  出：A = 动作码
;=========================================================================
DECIDE:
            MOV     A,      CURACT
            CJNE    A,      #ACT_FORWARD, DC_1
            ; ---- 正在前进：跌到 HOLD_LO 以下就停，否则继续追 ----
            MOV     A,      MED
            CLR     C
            SUBB    A,      #HOLD_LO
            JC      DC_STOP
            MOV     A,      #ACT_FORWARD
            RET
DC_1:
            CJNE    A,      #ACT_BACK, DC_2
            ; ---- 正在后退：退到 BACK_LO 以上就停 ----
            MOV     A,      MED
            CLR     C
            SUBB    A,      #BACK_LO
            JC      DC_BACK
            MOV     A,      #ACT_STOP
            RET
DC_2:
            ; ---- 停着（或上电初值）：远了追、近了退、中间保持 ----
            MOV     A,      MED
            CLR     C
            SUBB    A,      #GO_HI
            JNC     DC_FWD              ; d >= 28 -> 前进
            MOV     A,      MED
            CLR     C
            SUBB    A,      #BACK_HI
            JC      DC_BACK             ; d < 14 -> 后退
            MOV     A,      #ACT_STOP
            RET
DC_FWD:
            MOV     A,      #ACT_FORWARD
            RET
DC_BACK:
            MOV     A,      #ACT_BACK
            RET
DC_STOP:
            MOV     A,      #ACT_STOP
            RET

;=========================================================================
; MED3：S0/S1/S2 三个数排序，中间那个就是中值 -> MED
;   三次比较交换（冒泡的前三趟，3 个数一定排好）。
;   排序只是换顺序，不改变这三个数的集合，所以不影响滑动窗口。
;   只会动到 MED，S0/S1/S2 的顺序会被改成升序（无所谓）。
;=========================================================================
MED3:
            MOV     R0,     #S0
            MOV     R1,     #S1
            ACALL   SWAPGT
            MOV     R0,     #S1
            MOV     R1,     #S2
            ACALL   SWAPGT
            MOV     R0,     #S0
            MOV     R1,     #S1
            ACALL   SWAPGT
            MOV     A,      S1
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
; MOTOR_SET_ACT：动作码（A）-> P0 输出图案
;=========================================================================
MOTOR_SET_ACT:
            CJNE    A,      #ACT_FORWARD, MSA_1
            MOV     MOTPAT, #PAT_FORWARD
            SJMP    MSA_DO
MSA_1:
            CJNE    A,      #ACT_BACK, MSA_2
            MOV     MOTPAT, #PAT_BACK
            SJMP    MSA_DO
MSA_2:
            MOV     MOTPAT, #PAT_STOP   ; ACT_STOP 及任何意外值都当停车
MSA_DO:
            MOV     P0,     MOTPAT
            RET

;=========================================================================
; SHOW_DIST：把 MED（cm）的十位显示到数码管；D3 灯亮 = 电机在动
;   共阳数码管：段写 0 点亮；段序 a=P2.7 b=P2.6 c=P2.5 d=P2.4 e=P2.3 f=P2.2 g=P2.1
;   P2.0 = D3 指示灯（写 0 亮），不是段选
;=========================================================================
SHOW_DIST:
            MOV     A,      MED
            ACALL   TENS                ; A = 十位数字 0..9
            MOV     DPTR,   #DIGIT
            MOVC    A,      @A+DPTR     ; 段码（bit0 = 1 -> D3 灭）
            MOV     SCRL,   A
            MOV     A,      CURACT
            JZ      SD_OFF              ; 动作码 0 = 停 -> D3 灭
            MOV     A,      SCRL
            ANL     A,      #0FEH       ; bit0 = 0 -> D3 亮（在动）
            MOV     P2,     A
            RET
SD_OFF:
            MOV     P2,     SCRL
            RET

;=========================================================================
; TENS：A = 距离（cm）-> A = 十位数字（0..9）
;   超过 90cm 一律给 9（一位数码管显示不了两位）
;=========================================================================
TENS:
            MOV     R3,     #0
TENS_LP:
            CLR     C
            SUBB    A,      #10
            JC      TENS_DN             ; 借位了 -> 减不动了，R3 就是十位
            INC     R3
            MOV     R4,     A
            MOV     A,      R3
            CJNE    A,      #9, TENS_NX
            MOV     A,      #9
            RET
TENS_NX:
            MOV     A,      R4
            SJMP    TENS_LP
TENS_DN:
            MOV     A,      R3
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
; PRINT_LINE：D=025cm T=0D2A  A=FWD
;              D=---cm  (no echo)  A=STOP      （没有回波时）
;   T 是本轮 Echo 高电平的机器周期数（4 位十六进制），用来：
;     1) 手工校距离：cm ≈ T/53；2) 判断模块到底有没有在回波。
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
;   只用 R7（D_500US 用 R1），不碰测距要用的 R2/R6/R7 之外的东西。
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
;   D_500US 用 R1；D_1MS 用 R1/R2；D_60MS 用 R5。
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

D_60MS:
            MOV     R5,     #60
D60_1:
            ACALL   D_1MS
            DJNZ    R5,     D60_1
            RET

;=========================================================================
; 字符串与码表
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== ULTRASONIC FOLLOW CAR v1  STC89C52 @11.0592MHz ===',0DH,0AH
            DB  'Trig=P1.3  Echo=P1.2 (schematic net labels P13TR / P12EC)',0DH,0AH
            DB  'motors P0.0-P0.5 via L293D | 7seg = tens digit of distance',0DH,0AH
            DB  'follow: >28cm FWD | <14cm BACK | between = HOLD (20-30cm)',0DH,0AH
            DB  'no echo for ~4s -> SAFE STOP. UART 9600 8N1, D=cm T=ticks.',0DH,0AH,0
MSG_ECHOOK:
            DB  'self-check: Echo idle = LOW  (ok)',0DH,0AH,0
MSG_ECHOHI:
            DB  '! self-check: Echo reads HIGH while idle -> check module/wiring',0DH,0AH,0
MSG_SAFE:
            DB  0DH,0AH,'!! target lost -> SAFE STOP (move something in front to resume)',0DH,0AH,0
MSG_WAIT:
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
