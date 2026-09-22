;=========================================================================
; probecheck.asm -- 循迹/寻光 输入脚"死活"监视程序
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 串口     : P3.1 TXD -> CH340 -> COM7, 9600 8N1
;-------------------------------------------------------------------------
; 干什么：
;   电机默认**不转**。每约 0.25s 打一行 4 个输入脚的读数：
;       M=0 P35=64 P36=00 P10=00 P11=00
;   M = 电机状态（0 = 停，1 = 开 60%）。
;   每个数是"100 次采样里读到低电平的次数"（十六进制，00..64 = 0..100%）。
;
;   引脚： P3.5 / P3.6 = 循迹探头（低 = 检测到反射）
;          P1.0 / P1.1 = 光敏（寻光，见光 = 低）
;
; 怎么用（关键就在"边动边看"）：
;   1) 先看 M=0（电机停）：
;        - 拿**白纸**从左侧探头下面慢慢过 -> P35 应该往 64 走
;        - 拿**黑胶带**从左侧探头下面慢慢过 -> P35 应该往 00 走
;        右侧同理看 P36。**两边都不动 = 这两路探头/接线有问题**（不是软件问题）。
;   2) 按一下板上 **S3**（P3.4）-> 电机开 60%（M=1），再按一下 -> 停（M=0）。
;        电机转着时，把探头**完全捂黑**（黑胶带盖严）：
;          - P35 还是 64（一直低） -> 是**电气干扰**（跟光照无关）
;          - P35 变 00              -> 是**光学反射**（车轮/齿轮把红外反回来了）
;   3) 寻光两路（P10/P11）如果一直在乱跳（00/27/64 之间），说明 LM393
;      的 W1/W2 阈值没调好、或开集电极输出缺上拉 —— 这与电机无关。
;
; 警告：按 S3 后电机会真的转，车轮架空！
;=========================================================================

T0_RELOAD   EQU     164             ; 256-164 = 92 机器周期 约为 99.8us
PWM_PER     EQU     20              ; 20 tick = 2ms = 500Hz
NSAMP       EQU     100             ; 每行采样点数（同时是百分比满量程）
DIR_FWD     EQU     05H             ; IN1 + IN3 -> 两轮同向
DUTY_ON     EQU     12              ; 开电机时用 60%

PWMC        DATA    30H
DUTY        DATA    31H
DIRBITS     DATA    32H
TICK_L      DATA    33H
TICK_H      DATA    34H
MOTORON     DATA    35H
SAMP        DATA    36H
C35         DATA    37H
C36         DATA    38H
C10         DATA    39H
C11         DATA    3AH

ENAB        BIT     20H.0
ENBB        BIT     20H.1
KEY_S3      BIT     P3.4            ; 低 = 按下

            ORG     0000H
            LJMP    MAIN

            ORG     000BH               ; Timer0：100us 时基 + 软件 PWM
            LJMP    T0_ISR

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     PWMC,   #0
            MOV     DUTY,   #0          ; 上电电机停
            MOV     DIRBITS,#0
            MOV     TICK_L, #0
            MOV     TICK_H, #0
            MOV     MOTORON,#0
            MOV     P0,     #0C0H       ; 停车 + 蜂鸣器静音
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH
            MOV     P3,     #0FFH

            MOV     TMOD,   #22H        ; T1 方式2(波特率) + T0 方式2(时基)
            MOV     TH1,    #0FDH
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

PC_LOOP:
            ACALL   KEYCHK              ; S3 -> 翻转电机开关
            ACALL   SETMOT
            ACALL   MEASURE             ; 采 100 点
            ACALL   PRINT_LINE
            ACALL   D_150MS
            LJMP    PC_LOOP

;-------------------------------------------------------------------------
; SETMOT：按 MOTORON 设置占空比与方向
;-------------------------------------------------------------------------
SETMOT:
            MOV     A,      MOTORON
            JZ      SM_OFF
            MOV     DUTY,   #DUTY_ON
            MOV     DIRBITS,#DIR_FWD
            RET
SM_OFF:
            MOV     DUTY,   #0
            MOV     DIRBITS,#0
            RET

;-------------------------------------------------------------------------
; KEYCHK：S3(P3.4) 每按一下翻转一次 MOTORON（带 20ms 去抖 + 等松手）
;-------------------------------------------------------------------------
KEYCHK:
            JB      KEY_S3, KC_DONE     ; 没按
            ACALL   D_20MS
            JB      KEY_S3, KC_DONE     ; 抖动，不算
            MOV     A,      MOTORON
            CPL     A
            ANL     A,      #01H
            MOV     MOTORON,A
KC_REL:
            JNB     KEY_S3, KC_REL      ; 等松手
            ACALL   D_20MS
KC_DONE:
            RET

;-------------------------------------------------------------------------
; MEASURE：采 NSAMP 个点，统计 4 个输入脚各自的低电平点数
;-------------------------------------------------------------------------
MEASURE:
            MOV     C35,    #0
            MOV     C36,    #0
            MOV     C10,    #0
            MOV     C11,    #0
            MOV     SAMP,   #NSAMP
MS_LOOP:
            JNB     P3.5,   MS_35
            SJMP    MS_36
MS_35:
            INC     C35
MS_36:
            JNB     P3.6,   MS_36B
            SJMP    MS_10
MS_36B:
            INC     C36
MS_10:
            JNB     P1.0,   MS_10B
            SJMP    MS_11
MS_10B:
            INC     C10
MS_11:
            JNB     P1.1,   MS_11B
            SJMP    MS_DLY
MS_11B:
            INC     C11
MS_DLY:
            ACALL   WAIT_2TICK          ; 采样间隔约 200us
            DJNZ    SAMP,   MS_LOOP
            RET

;-------------------------------------------------------------------------
; PRINT_LINE：M=n P35=xx P36=xx P10=xx P11=xx
;-------------------------------------------------------------------------
PRINT_LINE:
            MOV     DPTR,   #MSG_M
            ACALL   PRINT_STR
            MOV     A,      MOTORON
            ACALL   PUT_DIG
            MOV     DPTR,   #MSG_35
            ACALL   PRINT_STR
            MOV     A,      C35
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_36
            ACALL   PRINT_STR
            MOV     A,      C36
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_10
            ACALL   PRINT_STR
            MOV     A,      C10
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_11
            ACALL   PRINT_STR
            MOV     A,      C11
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
            RET

;-------------------------------------------------------------------------
; WAIT_2TICK：等到时基前进 >= 2 tick（约 200us）
;-------------------------------------------------------------------------
WAIT_2TICK:
            ACALL   TICK_GET
            MOV     A,      R5          ; 8051 不能 MOV Rn,Rn，必须过 ACC
            MOV     R7,     A
W2_LOOP:
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      R7
            CLR     C
            SUBB    A,      #2
            JC      W2_LOOP
            RET

;-------------------------------------------------------------------------
; 软件延时（只用 R2/R3，不碰主循环的 R4~R7）
;-------------------------------------------------------------------------
D_150MS:
            MOV     R3,     #250
D150_1:     MOV     R2,     #230
D150_2:     DJNZ    R2,     D150_2
            DJNZ    R3,     D150_1
            RET                             ; 约 125ms（机器周期 1.085us）

D_20MS:
            MOV     R3,     #30
D20_1:      MOV     R2,     #250
D20_2:      DJNZ    R2,     D20_2
            DJNZ    R3,     D20_1
            RET                             ; 约 24ms

;-------------------------------------------------------------------------
; TICK_GET：原子读 16 位时基 -> R4:R5
;-------------------------------------------------------------------------
TICK_GET:
            CLR     EA
            MOV     R4,     TICK_H
            MOV     R5,     TICK_L
            SETB    EA
            RET

;-------------------------------------------------------------------------
; 串口输出（9600 8N1，P3.1）
;-------------------------------------------------------------------------
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

PUT_DIG:
            ADD     A,      #30H
            ACALL   PUTCHAR
            RET

PUT_HEX:
            PUSH    ACC
            SWAP    A
            ANL     A,      #0FH
            ACALL   PUT_NIB
            POP     ACC
            ANL     A,      #0FH
            ACALL   PUT_NIB
            RET

PUT_NIB:
            ADD     A,      #30H
            CJNE    A,      #3AH,  PN_C
PN_C:
            JC      PN_S
            ADD     A,      #7
PN_S:
            ACALL   PUTCHAR
            RET

;-------------------------------------------------------------------------
; Timer0 中断：100us 时基 + 软件 PWM（ENA/ENB）+ 组装 P0
;   只用 ACC / PSW / 直接寻址 RAM，不碰 R0~R7
;-------------------------------------------------------------------------
T0_ISR:
            PUSH    PSW
            PUSH    ACC
            INC     TICK_L
            MOV     A,      TICK_L
            JNZ     TI_T
            INC     TICK_H
TI_T:
            INC     PWMC
            MOV     A,      PWMC
            CJNE    A,      #PWM_PER, TI_NR
            MOV     PWMC,   #0
TI_NR:
            MOV     A,      PWMC
            CLR     C
            SUBB    A,      DUTY
            MOV     ENAB,   C
            MOV     A,      PWMC
            CLR     C
            SUBB    A,      DUTY
            MOV     ENBB,   C
            MOV     A,      DIRBITS
            ORL     A,      #0C0H       ; bit7 = 1；bit6 = 1 = 蜂鸣器静音
            MOV     C,      ENAB
            MOV     ACC.4,  C
            MOV     C,      ENBB
            MOV     ACC.5,  C
            MOV     P0,     A
            POP     ACC
            POP     PSW
            RETI

;-------------------------------------------------------------------------
; 字符串
;-------------------------------------------------------------------------
MSG_BOOT:
            DB      0DH,0AH,'=== PROBE CHECK: watch P35/P36 while moving white/black ===',0DH,0AH
            DB      'M=0 motor OFF (default). Press S3 = motor ON 60%, press again = OFF',0DH,0AH
            DB      'each count = samples reading LOW out of 100 (HEX 00..64)',0DH,0AH
            DB      'P35/P36 = tracking, P10/P11 = LDR. Wheels MUST be off ground!',0DH,0AH,0

MSG_M:      DB      'M=',0
MSG_35:     DB      ' P35=',0
MSG_36:     DB      ' P36=',0
MSG_10:     DB      ' P10=',0
MSG_11:     DB      ' P11=',0
MSG_CRLF:   DB      0DH,0AH,0

            END
