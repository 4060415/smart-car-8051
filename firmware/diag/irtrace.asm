;=========================================================================
; irtrace.asm  --  把 P3.3 上的电平时序**逐个打出来**（不看协议、不做任何假设）
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name irtrace
;-------------------------------------------------------------------------
; 一、它干什么
;   监视 P3.3（红外接收头输出），每当电平翻转就把**刚过去的那一段电平时长**
;   打出来（单位 = 100us tick，两位十六进制）。一次按键打出一行，形如：
;
;       B 5A 2D 06 06 11 06 06 06 06 11 ...
;         ^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^
;         低 高 之后就是一位一位的"低+高"
;
;   判读参考（标准 NEC）：
;       5A = 90 tick = 9.00ms  引导码低电平
;       2D = 45 tick = 4.50ms  引导码高电平（完整帧）
;       16 = 22 tick = 2.25ms  引导码高电平（重复帧）
;       06 =  6 tick = 0.56ms  位低电平 / 位0 的高电平
;       11 = 17 tick = 1.69ms  位1 的高电平
;
; 二、为什么要它
;   irprobe 只能证明"有红外活动"；irdecode 是按"标准 NEC"去套，套不上就报失败。
;   本程序**不做任何协议假设**，只报实测时序 —— 协议不对时这是唯一能看清真相的办法。
;
; 三、抗"时机错过"
;   最近一次突发的时序**存在 RAM 里**，空闲时每约 2 秒重打一遍（心跳）。
;   所以**什么时候按键都行**，日志里一定能看到最后那次的时序。
;
; 四、安全
;   P0 恒为 0C0H（ENA/ENB 拉低 = 电机断电），不驱动电机。
;=========================================================================

PAT_STOP    EQU     0C0H
T0_RELOAD   EQU     164             ; 100us tick
MAXEDGE     EQU     24              ; 一次突发最多记这么多段（RAM 限制）
CAP_TK      EQU     200             ; 单段最长 200 tick = 20ms（超过即认为突发结束）
HB_ITER     EQU     40              ; 心跳：空闲每约 40 tick 重打一次（≈2 秒）
BIT_TH      EQU     11              ; 位高电平 >= 1.1ms 判为 1（实测位0≈5、位1≈16~17）

; --- RAM ---
TICK_L      DATA    30H
TICK_H      DATA    31H
STR_H       DATA    32H
STR_L       DATA    33H
DUR_H       DATA    34H
DUR_L       DATA    35H
CAP_L       DATA    36H
MLVL        DATA    37H
NEDGE       DATA    38H
BUFCNT      DATA    39H
HBCNT       DATA    3AH
BUF         DATA    40H             ; 40H..57H：最多 24 段的时长
IB0         DATA    58H             ; 解出来的 4 个字节（addr/~addr/cmd/~cmd）
IB1         DATA    59H
IB2         DATA    5AH
IB3         DATA    5BH
BITS        DATA    5CH             ; 32 位计数
PTRIDX      DATA    5DH             ; 当前字节序号 0..3
MASKB       DATA    5EH             ; 当前位掩码

SVTO        BIT     20H.0           ; SAVE 内部：暂存进位标志

            ORG     0000H
            LJMP    MAIN

            ORG     000BH               ; Timer0：只累加 100us 时基
            LJMP    T0_ISR

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     TICK_L, #0
            MOV     TICK_H, #0
            MOV     BUFCNT, #0
            MOV     HBCNT,  #0
            MOV     P0,     #PAT_STOP
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH
            MOV     P3,     #0FFH

            MOV     TMOD,   #22H        ; T1 方式2（串口） + T0 方式2（100us 时基）
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

;=========================================================================
; 主循环
;   线是高（空闲）时：每 1 tick 累计一次心跳计数；到点重打"最近一次突发"
;   线变低：一次突发开始 -> 逐段量时长存进缓冲区 -> 打完这一行
;=========================================================================
LOOP:
            JB      P3.3,   LOOP_IDLE   ; 高 = 空闲
            MOV     BUFCNT, #0
            MOV     NEDGE,  #0
            MOV     BITS,   #0          ; 同时开始解码这 32 位
            MOV     IB0,    #0
            MOV     IB1,    #0
            MOV     IB2,    #0
            MOV     IB3,    #0
            MOV     PTRIDX, #0
            MOV     MASKB,  #01H
            SJMP    BURST

LOOP_IDLE:
            ACALL   D_TICK              ; 等 1 tick（100us），别空转
            INC     HBCNT
            MOV     A,      HBCNT
            CJNE    A,      #HB_ITER, LOOP
            MOV     HBCNT,  #0
            ACALL   PRT_BUF             ; 心跳：重打最近一次时序 + 解码结果
            SJMP    LOOP

BURST:
            ; ---- 量低电平 ----
            MOV     MLVL,   #0
            MOV     CAP_L,  #CAP_TK
            ACALL   MEAS_LEVEL
            ACALL   SAVE
            JC      BURST_END

            ; ---- 量高电平 ----
            MOV     MLVL,   #1
            MOV     CAP_L,  #CAP_TK
            ACALL   MEAS_LEVEL
            ACALL   SAVE
            JC      BURST_END

            ; ---- 顺手解码：第 3 段（索引 2）起才是数据位 ----
            MOV     A,      BUFCNT
            CJNE    A,      #2,     BR_BIT      ; 前两段是引导码低/高，跳过
            SJMP    BR_NEXT
BR_BIT:
            MOV     A,      BITS
            CJNE    A,      #32,    BR_BIT2
            SJMP    BR_NEXT             ; 已经收满 32 位
BR_BIT2:
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #BIT_TH
            JC      BR_NEXT             ; 高电平 < 1.1ms -> 位0
            ACALL   SETBIT              ; >= 1.1ms -> 位1
BR_NEXT:
            INC     NEDGE
            MOV     A,      NEDGE
            CJNE    A,      #MAXEDGE, BURST

BURST_END:
            ACALL   PRT_BUF
            MOV     HBCNT,  #0
            SJMP    LOOP

;-------------------------------------------------------------------------
; SETBIT —— 把当前位（位1）写进 IB0..IB3（NEC 低位在前）
;-------------------------------------------------------------------------
SETBIT:
            MOV     A,      PTRIDX
            CJNE    A,      #0,     SB_1
            MOV     A,      MASKB
            ORL     A,      IB0
            MOV     IB0,    A
            SJMP    SB_NEXT
SB_1:       CJNE    A,      #1,     SB_2
            MOV     A,      MASKB
            ORL     A,      IB1
            MOV     IB1,    A
            SJMP    SB_NEXT
SB_2:       CJNE    A,      #2,     SB_3
            MOV     A,      MASKB
            ORL     A,      IB2
            MOV     IB2,    A
            SJMP    SB_NEXT
SB_3:
            MOV     A,      MASKB
            ORL     A,      IB3
            MOV     IB3,    A
SB_NEXT:
            MOV     A,      MASKB
            RL      A
            MOV     MASKB,  A
            JNZ     SB_DONE
            MOV     MASKB,  #01H
            INC     PTRIDX
SB_DONE:
            INC     BITS                ; 每收一位 +1
            RET

;-------------------------------------------------------------------------
; D_TICK —— 等一个 100us tick
;-------------------------------------------------------------------------
D_TICK:
            ACALL   TICK_GET
            MOV     A,      R5          ; 8051 没有 MOV Rn,Rn，得走 ACC
            MOV     R6,     A           ; 基准
DT_1:
            ACALL   TICK_GET
            MOV     A,      R5
            XRL     A,      R6
            JZ      DT_1
            RET

;-------------------------------------------------------------------------
; SAVE —— 把 DUR_L 存进缓冲区；把"是否超时"（进位）原样透传给调用者
;   注意：不能用 ADD 之外的方式算地址，但 ADD 会改进位 -> 先把进位存进位变量
;-------------------------------------------------------------------------
SAVE:
            MOV     SVTO,   C           ; 先存住超时标志
            MOV     A,      BUFCNT
            CJNE    A,      #MAXEDGE, SV_OK
            SETB    C                   ; 缓冲区满 -> 也当结束
            RET
SV_OK:
            ADD     A,      #BUF
            MOV     R0,     A
            MOV     A,      DUR_L
            MOV     @R0,    A
            INC     BUFCNT
            MOV     C,      SVTO        ; 还回超时标志
            RET

;-------------------------------------------------------------------------
; PRT_BUF —— 打印"最近一次突发"：一个 B，然后每段两位十六进制，每 8 段换行
;   寄存器：R1 = 指针，R7 = 剩余段数，R6 = 本行计数
;   （PUT_HEX 会用 R2，所以这里绝不能用 R2！）
;-------------------------------------------------------------------------
PRT_BUF:
            ACALL   CRLF
            MOV     A,      #42H            ; 'B'
            ACALL   PUTCHAR
            MOV     R1,     #BUF
            MOV     A,      BUFCNT
            MOV     R7,     A
            MOV     R6,     #0
PB_1:
            MOV     A,      R7
            JZ      PB_DONE
            MOV     A,      #20H
            ACALL   PUTCHAR
            MOV     A,      @R1
            ACALL   PUT_HEX
            INC     R1
            INC     R6
            MOV     A,      R6
            ANL     A,      #07H
            JNZ     PB_2
            ACALL   CRLF
            MOV     A,      #20H
            ACALL   PUTCHAR
PB_2:
            DEC     R7
            SJMP    PB_1
PB_DONE:
            ; ---- 再打一行：这 32 位解出来的 4 个字节（addr/~addr/cmd/~cmd）----
            ACALL   CRLF
            MOV     A,      #20H
            ACALL   PUTCHAR
            MOV     DPTR,   #MSG_IB
            ACALL   PRINT_STR
            MOV     A,      IB0
            ACALL   PUT_HEX
            MOV     A,      #20H
            ACALL   PUTCHAR
            MOV     A,      IB1
            ACALL   PUT_HEX
            MOV     A,      #20H
            ACALL   PUTCHAR
            MOV     A,      IB2
            ACALL   PUT_HEX
            MOV     A,      #20H
            ACALL   PUTCHAR
            MOV     A,      IB3
            ACALL   PUT_HEX
            RET

;=========================================================================
; MEAS_LEVEL —— 量 P3.3 保持 MLVL 指定电平的长度（单位 tick）
;   入：MLVL = 0 量低（等它变高）/ 1 量高（等它变低）；CAP_L = 限时 tick
;   出：C = 0 已变化，DUR_L = 时长；C = 1 到限时还没变
;=========================================================================
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
            MOV     A,      DUR_H
            JNZ     ML_TIMEOUT          ; > 25.6ms
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      CAP_L
            JC      ML_LEVEL
            SJMP    ML_TIMEOUT
ML_LEVEL:
            MOV     A,      MLVL
            JZ      ML_WAIT_HI
            JNB     P3.3,   ML_DONE
            SJMP    ML_LOOP
ML_WAIT_HI:
            JB      P3.3,   ML_DONE
            SJMP    ML_LOOP
ML_DONE:
            CLR     C
            RET
ML_TIMEOUT:
            SETB    C
            RET

;=========================================================================
; TICK_GET —— 原子读 16 位时基 -> R4:R5
;=========================================================================
TICK_GET:
            CLR     EA
            MOV     R4,     TICK_H
            MOV     R5,     TICK_L
            SETB    EA
            RET

;=========================================================================
; Timer0 中断：只累加 100us 时基
;=========================================================================
T0_ISR:
            PUSH    PSW
            PUSH    ACC
            INC     TICK_L
            MOV     A,      TICK_L
            JNZ     T0_END
            INC     TICK_H
T0_END:
            POP     ACC
            POP     PSW
            RETI

;=========================================================================
; 串口输出辅助
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

PUT_HEX:
            MOV     R2,     A
            SWAP    A
            ANL     A,      #0FH
            ACALL   PUT_NIB
            MOV     A,      R2
            ANL     A,      #0FH
            ACALL   PUT_NIB
            RET

PUT_NIB:
            ADD     A,      #30H
            CJNE    A,      #3AH,   PN_OUT
PN_OUT:
            JC      PN_SEND
            ADD     A,      #7
PN_SEND:
            ACALL   PUTCHAR
            RET

CRLF:
            MOV     A,      #0DH
            ACALL   PUTCHAR
            MOV     A,      #0AH
            ACALL   PUTCHAR
            RET

;=========================================================================
; 字符串
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== IR EDGE TIMING TRACE + NEC DECODE ===',0DH,0AH
            DB  'Line 1: B then every level run in 100us ticks, hex, LOW/HIGH alternating.',0DH,0AH
            DB  'Line 2: the 4 bytes decoded from those bits (addr ~addr cmd ~cmd).',0DH,0AH
            DB  'NEC reference: 5A=9ms leader low | 2C/2D=4.5ms leader high(full frame)',0DH,0AH
            DB  '  15/16=2.25ms (repeat frame) | 05=0.56ms bit low / bit-0 high | 10/11=1.69ms bit-1',0DH,0AH
            DB  'The last burst is re-printed about every 2s, so timing does not matter.',0DH,0AH
            DB  'Motors stay off (P0 = stop pattern).',0DH,0AH,0
MSG_IB:
            DB  'IB=',0

            END
