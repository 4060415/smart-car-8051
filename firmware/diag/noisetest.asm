;=========================================================================
; noisetest.asm -- 电机干扰定位程序（判断哪个输入脚被干扰、干扰多强）
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 串口     : P3.1 TXD -> CH340 -> COM7, 9600 8N1（每档打一行）
;-------------------------------------------------------------------------
; 干什么：
;   电机档位自动扫 0..5（占空比 0/20/40/60/80/100%），每一档：
;     1) 等约 0.5s 让电机转稳；
;     2) 以约 200us 间隔采 100 个点；
;     3) 统计 4 个输入脚各自"被读到低电平"的点数（也就是百分比 0..100）；
;     4) 打一行：  G=3 P35=4C P36=00 P10=2D P11=2E
;   计数用两位十六进制（00..64 = 0..100%）。整张表约 3 秒重复一次。
;
;   引脚： P3.5 / P3.6 = 循迹探头（低 = 检测到反射）
;          P1.0 / P1.1 = 光敏（寻光，见光 = 低）
;
; 怎么判读：
;   * G=0 那一行（电机停）是基线。
;   * 某个脚的计数随档位升高而升高  -> 该脚被电机干扰。
;   * 只有 P35/P36 涨   -> 干扰是从"探头那个高阻节点 / 那根排线"进来的。
;   * P10/P11 也一起涨  -> 干扰是全局的（电源 / 地 / EMI），不是探头独有。
;   * 计数冲到 64(=100%) -> 被"拉死"成低电平（直流偏移，不是闪烁）；
;     计数落在中间（如 15~40） -> 是跟着 500Hz PWM 一起闪的噪声。
;
; 想进一步定位再做这两条（做完更好判断）：
;   A) 把两个电机的接线拔掉，只让 ENA/ENB 照常 PWM：
;      计数不再涨 -> 干扰来自"电机电流"；照涨 -> 来自 MCU/走线本身。
;   B) 电机定速时把探头排线挪远/挪近电机：
;      计数明显变化 = 辐射耦合；几乎不变 = 传导耦合（地/电源）。
;
; 警告：车轮必须架空！电机会真的转。
;=========================================================================

T0_RELOAD   EQU     164             ; 256-164 = 92 机器周期 约为 99.8us
PWM_PER     EQU     20              ; 20 tick = 2ms = 500Hz
NSAMP       EQU     100             ; 每档采样点数（同时是百分比满量程）
DIR_FWD     EQU     05H             ; IN1 + IN3 -> 两轮同向

PWMC        DATA    30H
DUTY        DATA    31H
DIRBITS     DATA    32H
TICK_L      DATA    33H
TICK_H      DATA    34H
GEAR        DATA    35H
SAMP        DATA    36H
C35         DATA    37H
C36         DATA    38H
C10         DATA    39H
C11         DATA    3AH

ENAB        BIT     20H.0
ENBB        BIT     20H.1

            ORG     0000H
            LJMP    MAIN

            ORG     000BH               ; Timer0：100us 时基 + 软件 PWM
            LJMP    T0_ISR

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     PWMC,   #0
            MOV     DUTY,   #0
            MOV     DIRBITS,#0
            MOV     TICK_L, #0
            MOV     TICK_H, #0
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

SWEEP:
            MOV     GEAR,   #0
SW_LOOP:
            MOV     A,      GEAR        ; 按档位取占空比
            MOV     DPTR,   #DUTYTAB
            MOVC    A,      @A+DPTR
            MOV     DUTY,   A
            MOV     A,      GEAR
            JZ      SW_HOLD
            MOV     DIRBITS,#DIR_FWD
            SJMP    SW_WAIT
SW_HOLD:
            MOV     DIRBITS,#0
SW_WAIT:
            ACALL   WAIT_500MS          ; 让电机转稳
            ACALL   MEASURE             ; 采 100 点
            ACALL   PRINT_LINE
            INC     GEAR
            MOV     A,      GEAR
            CJNE    A,      #6,     SW_LOOP
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
            LJMP    SWEEP               ; 整轮重来

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
; PRINT_LINE：G=n P35=xx P36=xx P10=xx P11=xx
;-------------------------------------------------------------------------
PRINT_LINE:
            MOV     DPTR,   #MSG_G
            ACALL   PRINT_STR
            MOV     A,      GEAR
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
            MOV     A,      R5          ; 8051 不能 MOV R7,R5，必须过 ACC
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
; WAIT_500MS：等时基前进约 5000 tick（高字节 >= 19 即约 486~512ms）
;-------------------------------------------------------------------------
WAIT_500MS:
            ACALL   TICK_GET
            MOV     A,      R4          ; 8051 不能 MOV Rn,Rn，必须过 ACC
            MOV     R6,     A
            MOV     A,      R5
            MOV     R7,     A
W5_LOOP:
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      R7
            MOV     A,      R4
            SUBB    A,      R6
            CLR     C
            SUBB    A,      #19
            JC      W5_LOOP
            RET

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
; 常量 / 字符串
;-------------------------------------------------------------------------
DUTYTAB:
            DB      0, 4, 8, 12, 16, 20     ; 档位 0..5 -> 0/20/40/60/80/100%

MSG_BOOT:
            DB      0DH,0AH,'=== NOISE TEST: motor gear sweep vs input pins ===',0DH,0AH
            DB      'P35/P36 = tracking probe, P10/P11 = LDR (low = active)',0DH,0AH
            DB      'counts are HEX (00..64 = 0..100%) over 100 samples @200us',0DH,0AH
            DB      'G=0 means motor off = baseline. Wheels MUST be off ground!',0DH,0AH,0

MSG_G:      DB      'G=',0
MSG_35:     DB      ' P35=',0
MSG_36:     DB      ' P36=',0
MSG_10:     DB      ' P10=',0
MSG_11:     DB      ' P11=',0
MSG_CRLF:   DB      0DH,0AH,0

            END
