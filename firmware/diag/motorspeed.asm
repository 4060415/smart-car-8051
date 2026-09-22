;=========================================================================
; motorspeed.asm  --  变速（软件 PWM）+ 不同幅度转弯 的基准程序
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name motorspeed
;-------------------------------------------------------------------------
; 一、这个程序解决什么
;   报告要求"变速前进后退 + 以不同幅度转弯"，而现有工程**一行 PWM 都没有**
;   （remote.asm / usfollow.asm 里都写着"本程序只做低速开关，不做 PWM"）。
;   在把它写进正式固件之前，必须先回答三个问题 —— 本程序就是去量这三件事：
;     (1) **软件 PWM 到底转不转得动**？P0 是开漏口、靠板上 10K 排阻上拉，
;         上升沿偏慢；所以要从最低档试到最高档，看**哪一档是"真的能动"的下限**。
;     (2) **M1/M2 与左右轮到底怎么对应**？图纸只给了 M1/M2 位号，没说左右
;         （config.h 里 LEFT_REVERSE / RIGHT_REVERSE 就是为这个留的）。
;         看第 6、9 步的"原地左转/右转"是不是真的往左/往右。
;     (3) **不同幅度转弯能不能做**？同向两轮给不同占空比 = 差速小转弯
;         （第 7、8 步）。
;
; 二、PWM 是怎么做的（也是正式固件要用的做法）
;   Timer0 方式2 硬件重装 -> 每 99.8us 进一次中断，中断里：
;       PWMC 自增 0..19（周期 20 tick ≈ 2ms -> **500Hz**）
;       ENA = (PWMC < DUTY_A)、ENB = (PWMC < DUTY_B)
;       把 P0 整个字节"组装"出来写下去
;   ★ 关键约定：**主循环永远不直接写 P0**，只改 DIRBITS（方向位）与 DUTY_A/B；
;     P0 由中断每 100us 重写一次。这样就不会出现"主循环写 P0 把 PWM 关掉"的竞争。
;     另外 P0.6（蜂鸣器）在中断里恒置 1 = 静音，P0.7 恒置 1。
;
;   周期/分辨率的取舍：20 tick = 2ms = 500Hz，占空比 5% 一档（0..100% 共 21 级）。
;   再快没必要（有刷减速电机机械时间常数 100ms 量级），再慢会听到抖动。
;
; 三、跑起来看到什么
;   九步循环，每步保持 1.5 秒，然后停车 1.5 秒，再从头：
;     步 1~5：**前进**，两轮同占空比 20% / 40% / 60% / 80% / 100%   <- 找"能动的最低档"
;     步 6  ：**原地左转**（M1 反转 + M2 正转，都 100%）
;     步 7  ：**向左画弧**（左 100% / 右 60%）
;     步 8  ：**向右画弧**（左 60% / 右 100%）
;     步 9  ：**原地右转**（M1 正转 + M2 反转，都 100%）
;   数码管显示步号 1..9；串口 9600 8N1 每步打一行，带实际占空比百分数。
;
; 四、安全
;   * 上电初始 = 停车图案（DIRBITS=0、两路占空比 0），不会一上电就窜出去；
;   * **第一次跑请把小车架起来让轮子悬空**，先看轮子转向对不对，再落地跑；
;   * 本程序不读任何传感器、不响蜂鸣器。
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
DISP_8      EQU     01H
DISP_9      EQU     09H

; --- P0 方向图案（低 4 位 = IN1..IN4；与 config.h 的 PAT_* 一致）---
DIR_STOP    EQU     00H             ; 04 位全 0 = 两路断电
DIR_FWD     EQU     05H             ; IN1 + IN3  -> 同向正转（= PAT_FORWARD F5H 的低4位）
DIR_LEFT    EQU     06H             ; IN2 + IN3  -> 原地左转（= PAT_LEFT    F6H 的低4位）
DIR_RIGHT   EQU     09H             ; IN1 + IN4  -> 原地右转（= PAT_RIGHT   F9H 的低4位）
DIR_BACK    EQU     0AH             ; IN2 + IN4  -> 后退

; --- 时基与 PWM ---
T0_RELOAD   EQU     164             ; 256-164 = 92 机器周期 ≈ 99.8us @11.0592MHz
PWM_PER     EQU     20              ; 20 × 99.8us ≈ 2ms -> 500Hz
NSTEP       EQU     9               ; 九步循环

; --- RAM（直接寻址区 40H 起）---
PWMC        DATA    40H             ; PWM 计数 0..19（中断里维护）
DIRBITS     DATA    41H             ; 方向位（主循环写、中断读）
DUTY_A      DATA    42H             ; ENA(P0.4) 占空比档 0..20
DUTY_B      DATA    43H             ; ENB(P0.5) 占空比档 0..20

ENAB        BIT     20H.0           ; 中断内部临时位
ENBB        BIT     20H.1

            ORG     0000H
            LJMP    MAIN

            ORG     000BH               ; Timer0 中断向量
            LJMP    T0_ISR

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     DIRBITS,#DIR_STOP
            MOV     DUTY_A, #0
            MOV     DUTY_B, #0
            MOV     PWMC,   #0
            MOV     P0,     #0C0H       ; 上电先停车（中断起来后由 DIRBITS 决定）
            MOV     P1,     #0FFH
            MOV     P2,     #DISP_0
            MOV     P3,     #0FFH

            ; ---- 串口 9600 8N1（T1 方式2）+ T0 方式2 做 100us 时基 ----
            MOV     TMOD,   #22H        ; 高半字节 = T1 方式2，低半字节 = T0 方式2
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

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;=========================================================================
; 主循环：九步走一遍，每步 1.5 秒
;=========================================================================
MS_START:
            MOV     R7,     #0
MS_LOOP:
            ; ---- 从 STEPTAB 取三字节：[方向位, 占空比A, 占空比B] ----
            MOV     A,      R7
            MOV     B,      #3
            MUL     AB
            MOV     R6,     A
            MOV     DPTR,   #STEPTAB
            MOV     A,      R6
            MOVC    A,      @A+DPTR
            MOV     DIRBITS,A
            MOV     A,      R6
            INC     A
            MOVC    A,      @A+DPTR
            MOV     DUTY_A, A
            MOV     A,      R6
            ADD     A,      #2
            MOVC    A,      @A+DPTR
            MOV     DUTY_B, A

            ; ---- 数码管显示步号 1..9 ----
            MOV     A,      R7
            MOV     DPTR,   #GEARTAB
            MOVC    A,      @A+DPTR
            MOV     P2,     A

            ; ---- 串口一行：step n  duty L/R = xx/xx% ----
            MOV     DPTR,   #MSG_STEP
            ACALL   PRINT_STR
            MOV     A,      R7
            INC     A
            ADD     A,      #30H
            ACALL   PUTCHAR
            MOV     DPTR,   #MSG_DUTY
            ACALL   PRINT_STR
            MOV     A,      DUTY_A
            ACALL   PRT_PCT
            MOV     A,      #2FH            ; '/'
            ACALL   PUTCHAR
            MOV     A,      DUTY_B
            ACALL   PRT_PCT
            MOV     DPTR,   #MSG_PCT
            ACALL   PRINT_STR

            ACALL   D_1500MS
            INC     R7
            MOV     A,      R7
            CJNE    A,      #NSTEP, MS_LOOP

            ; ---- 一轮走完：停车 1.5 秒，再从头 ----
            MOV     DIRBITS,#DIR_STOP
            MOV     DUTY_A, #0
            MOV     DUTY_B, #0
            MOV     P2,     #DISP_0
            MOV     DPTR,   #MSG_CYCLE
            ACALL   PRINT_STR
            ACALL   D_1500MS
            LJMP    MS_START

;=========================================================================
; Timer0 中断：每 99.8us 一次，做软件 PWM 并组装 P0
;   注意：只动 ACC 与 PSW 之外什么都不用（所以只 PUSH ACC/PSW），
;         主循环的 R0~R7 / B 不受影响。
;=========================================================================
T0_ISR:
            PUSH    PSW
            PUSH    ACC

            INC     PWMC
            MOV     A,      PWMC
            CJNE    A,      #PWM_PER, T0_NR
            MOV     PWMC,   #0
T0_NR:
            MOV     A,      PWMC
            CLR     C
            SUBB    A,      DUTY_A          ; C=1 -> PWMC < DUTY_A -> 本 tick 使能 A
            MOV     ENAB,   C
            MOV     A,      PWMC
            CLR     C
            SUBB    A,      DUTY_B
            MOV     ENBB,   C

            MOV     A,      DIRBITS
            ORL     A,      #0C0H           ; bit7=1（不用）；bit6=1 = 蜂鸣器静音
            MOV     C,      ENAB
            MOV     ACC.4,  C               ; ENA
            MOV     C,      ENBB
            MOV     ACC.5,  C               ; ENB
            MOV     P0,     A

            POP     ACC
            POP     PSW
            RETI

;=========================================================================
; PRT_PCT —— 入: A = 占空比档 0..20；打印它的百分数（0/20/40/.../100）
;=========================================================================
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

;=========================================================================
; 串口输出辅助（9600 8N1，P3.1）
;=========================================================================
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

;=========================================================================
; 延时（机器周期 = 1.085us）；中断仍在后台跑 PWM，所以"延时"不影响电机转
;   D_1MS 用 R1/R2，D_2MS 用 R3，D_500MS 用 R5；都不碰 R6/R7。
;=========================================================================
D_1MS:
            MOV     R2,     #2
D1M_1:      MOV     R1,     #230
D1M_2:      DJNZ    R1,     D1M_2
            DJNZ    R2,     D1M_1
            RET                             ; ≈ 1.01ms

D_2MS:
            MOV     R3,     #2
D2M_1:      ACALL   D_1MS
            DJNZ    R3,     D2M_1
            RET

D_500MS:
            MOV     R5,     #250
D500M_1:    ACALL   D_2MS
            DJNZ    R5,     D500M_1
            RET                             ; 250 × 2ms = 500ms

D_1500MS:
            ACALL   D_500MS
            ACALL   D_500MS
            ACALL   D_500MS
            RET

;=========================================================================
; 常量表
;=========================================================================
GEARTAB:                                ; 步号 1..9 的段码
            DB  DISP_1, DISP_2, DISP_3, DISP_4, DISP_5
            DB  DISP_6, DISP_7, DISP_8, DISP_9

STEPTAB:                                ; 每步 3 字节：方向位, 占空比A, 占空比B
            DB  DIR_FWD,   4,   4       ; 1: 前进 20%
            DB  DIR_FWD,   8,   8       ; 2: 前进 40%
            DB  DIR_FWD,  12,  12       ; 3: 前进 60%
            DB  DIR_FWD,  16,  16       ; 4: 前进 80%
            DB  DIR_FWD,  20,  20       ; 5: 前进 100%
            DB  DIR_LEFT, 20,  20       ; 6: 原地左转
            DB  DIR_FWD,  20,  12       ; 7: 向左画弧（左快右慢）
            DB  DIR_FWD,  12,  20       ; 8: 向右画弧（左慢右快）
            DB  DIR_RIGHT,20,  20       ; 9: 原地右转

;=========================================================================
; 字符串（串口用纯 ASCII）
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== MOTOR SPEED / DIFFERENTIAL TEST (motorspeed) ===',0DH,0AH
            DB  'software PWM on ENA/ENB (P0.4/P0.5) from the Timer0 100us tick.',0DH,0AH
            DB  'PWM period = 20 ticks ~ 2ms (500Hz), duty step = 5%.',0DH,0AH
            DB  'step 1-5 : FORWARD  20/40/60/80/100%  (both wheels equal)',0DH,0AH
            DB  'step 6   : spin LEFT  (M1 rev + M2 fwd, both 100%)',0DH,0AH
            DB  'step 7   : curve LEFT (left 100%, right 60%)',0DH,0AH
            DB  'step 8   : curve RIGHT(left 60%, right 100%)',0DH,0AH
            DB  'step 9   : spin RIGHT (M1 fwd + M2 rev, both 100%)',0DH,0AH
            DB  'Each step holds 1.5s, then 1.5s stop, then it repeats.',0DH,0AH
            DB  '7seg = step number. 9600 8N1 prints the real duty.',0DH,0AH
            DB  'RECORD: (a) lowest duty that actually turns the wheels,',0DH,0AH
            DB  '        (b) does step 6/9 really turn left/right or swapped?',0DH,0AH
            DB  'LIFT THE CAR so the wheels spin free on the first run.',0DH,0AH,0
MSG_STEP:
            DB  0DH,0AH,'step ',0
MSG_DUTY:
            DB  '  duty L/R = ',0
MSG_PCT:
            DB  '%',0
MSG_CYCLE:
            DB  0DH,0AH,'--- one cycle done, stopping 1.5s ---',0

            END
