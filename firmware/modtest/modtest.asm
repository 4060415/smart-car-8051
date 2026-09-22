;=========================================================================
; modtest.asm  --  避障探头 + 红外遥控 专项测试（串口文字报告）
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC，晶振 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1
; 输出通道 : P3.1 (TXD) -> CH340 -> COM7，9600 8N1
;-------------------------------------------------------------------------
; 和 selftest.asm 的区别：
;   * **完全不驱动电机**（车轮不会转，架不架空都安全）；
;   * 没有 A/B/C 阶段和 40 秒时间窗，两件事同时持续在做，随时按随时动。
;
; 1) 遥控（一直守 P3.2 = 0038 输出）：按遥控器任意键打印一行
;      IR lo=2066 hi=1033 a=00 ff c=16 e9 [OK: NEC]
;    lo/hi = 引导码低/高电平时长（Timer0 tick，1 tick ≈ 1.085us），
;    四个字节 = addr ~addr cmd ~cmd；[OK: NEC] 表示互补校验通过。
;    按住不放会打印 [REPEAT: key held]。
;
; 2) 避障（一直扫 P1/P2/P3，屏蔽 P3.1 自己的 TXD 和 P3.2 红外信号）：
;    任何一位翻转就打印一行
;      P1.3=0
;    把纸板/手放到小车前端探头前面，看冒出哪一行 -> 那个脚就是避障输出脚。
;    每秒还打印一行原始快照（顺序 P0 P1 P2 P3）
;      HB FF FF 7F BF
;    P0 是开漏口，只有板上确认有上拉时读数才有意义，所以 P0 只进快照、
;    不做变化监视（避障若真接在 P0 上，就从 HB 行里看那一位）。
;
; 安全说明：只读端口、只在 P3.1 上发串口；P0/P1/P2 全程写 1（不激励负载）。
;=========================================================================

;-------------------------------------------------------------------------
; RAM 变量
;-------------------------------------------------------------------------
MLVL    DATA 30H            ; MEAS_LEVEL：0=量低电平，1=量高电平
TSH     DATA 31H            ; 测量起始时刻（Timer0 高字节）
TSL     DATA 32H
MPH     DATA 33H            ; 测量结果
MPL     DATA 34H
LLO_H   DATA 35H            ; 引导码低电平时长
LLO_L   DATA 36H
LHI_H   DATA 37H            ; 引导码高电平时长
LHI_L   DATA 38H
BITS    DATA 39H            ; 剩余位数
PTRIDX  DATA 3AH            ; 当前字节序号 0..3
MASKB   DATA 3BH            ; 位掩码
IB0     DATA 3CH            ; addr
IB1     DATA 3DH            ; ~addr
IB2     DATA 3EH            ; cmd
IB3     DATA 3FH            ; ~cmd
LAST1   DATA 40H            ; P1 上次读到的值
LAST2   DATA 41H            ; P2
LAST3   DATA 42H            ; P3（屏蔽 P3.1/P3.2）
HBCNT   DATA 43H            ; 心跳计数
TMO     DATA 44H            ; MEAS_LEVEL 的超时门限（高字节，单位 256 tick）

;-------------------------------------------------------------------------
            ORG     0000H
            LJMP    MAIN

            ORG     0030H
;=========================================================================
; 主程序
;=========================================================================
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #0FFH           ; 全部写 1 = 只做输入/放开
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH
            MOV     P3,     #0FFH

            ;---- 串口：9600 8N1，Timer1 方式2；Timer0 方式1 作测量时基 ----
            MOV     TMOD,   #21H            ; T1: 方式2(自动重装)  T0: 方式1(16位)
            MOV     TH1,    #0FDH           ; 11059200/(384*3) = 9600
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H            ; 方式1
            MOV     PCON,   #00H            ; SMOD = 0
            SETB    TR1                     ; 启动波特率发生器
            MOV     TH0,    #00H            ; Timer0 自由运行，只读不中断
            MOV     TL0,    #00H
            SETB    TR0

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

            ;---- 初始"上次值" ----
            ; 注意：必须用 MOV A,Px 读（读引脚）；MOV direct,Px 读的是锁存器，
            ; 锁存器一直是 0FFH，变化检测就永远不触发。
            MOV     A,      P1
            MOV     LAST1,  A
            MOV     A,      P2
            MOV     LAST2,  A
            MOV     A,      P3
            ANL     A,      #0F9H           ; 屏蔽 P3.1(TXD) 和 P3.2(IR)
            MOV     LAST3,  A
            MOV     HBCNT,  #40             ; 40 轮 ≈ 1 秒

;---- 主循环：扫引脚 -> 心跳快照 -> 试着收一帧红外 ----
MAIN_LOOP:
            ACALL   SCAN
            ACALL   HB
            ACALL   IR_ATTEMPT
            SJMP    MAIN_LOOP

;=========================================================================
; SCAN：读 P1/P2/P3，哪一位变了就打印 "P<n>.<bit>=<0|1>"
;   P0 不扫（开漏口，浮空会乱跳），只在 HB 快照里给出。
;=========================================================================
SCAN:
            ;---- P1 ----
            MOV     A,      P1
            MOV     R2,     A               ; 新值
            MOV     A,      LAST1
            MOV     R5,     A               ; 旧值
            MOV     A,      R2
            XRL     A,      R5
            JZ      SC_P2
            MOV     LAST1,  R2
            MOV     R6,     #'1'
            MOV     A,      R5
            MOV     R7,     A
            MOV     A,      R2
            MOV     R3,     A
            ACALL   REPORT_BITS
SC_P2:
            ;---- P2 ----
            MOV     A,      P2
            MOV     R2,     A
            MOV     A,      LAST2
            MOV     R5,     A
            MOV     A,      R2
            XRL     A,      R5
            JZ      SC_P3
            MOV     LAST2,  R2
            MOV     R6,     #'2'
            MOV     A,      R5
            MOV     R7,     A
            MOV     A,      R2
            MOV     R3,     A
            ACALL   REPORT_BITS
SC_P3:
            ;---- P3（屏蔽 P3.1 TXD、P3.2 IR）----
            MOV     A,      P3
            ANL     A,      #0F9H
            MOV     R2,     A
            MOV     A,      LAST3
            MOV     R5,     A
            MOV     A,      R2
            XRL     A,      R5
            JZ      SC_DONE
            MOV     LAST3,  R2
            MOV     R6,     #'3'
            MOV     A,      R5
            MOV     R7,     A
            MOV     A,      R2
            MOV     R3,     A
            ACALL   REPORT_BITS
SC_DONE:
            RET

;=========================================================================
; REPORT_BITS：把 R7(旧) 与 R3(新) 之间变化的位逐位打印
;   入口：R6 = 端口字符('0'/'1'/'2'/'3')，R7 = 旧值，R3 = 新值
;   用 IDX 当位号、MASKB 当掩码（此刻红外解码没在跑，可共用）
;=========================================================================
REPORT_BITS:
            MOV     MASKB,  #01H
            MOV     R1,     #0              ; R1 = 位号 0..7
RB_LOOP:
            MOV     A,      MASKB
            ANL     A,      R7
            MOV     R0,     A               ; 旧值该位
            MOV     A,      MASKB
            ANL     A,      R3
            XRL     A,      R0
            JZ      RB_NEXT                 ; 没变
            ;---- 打印 "P<n>.<bit>=" ----
            MOV     A,      #'P'
            ACALL   PUTCHAR
            MOV     A,      R6
            ACALL   PUTCHAR
            MOV     A,      #'.'
            ACALL   PUTCHAR
            MOV     A,      R1
            ADD     A,      #'0'
            ACALL   PUTCHAR
            MOV     A,      #'='
            ACALL   PUTCHAR
            ;---- 打印新值这一位 ----
            MOV     A,      MASKB
            ANL     A,      R3
            JZ      RB_ZERO
            MOV     A,      #'1'
            SJMP    RB_PUT
RB_ZERO:
            MOV     A,      #'0'
RB_PUT:
            ACALL   PUTCHAR
            ACALL   CRLF
RB_NEXT:
            MOV     A,      MASKB
            RL      A
            MOV     MASKB,  A
            INC     R1
            MOV     A,      R1
            CJNE    A,      #8,     RB_LOOP
            RET

;=========================================================================
; HB：每秒打印一行原始快照  "HB <P0> <P1> <P2> <P3>"（P3 只屏蔽 TXD）
;=========================================================================
HB:
            DJNZ    HBCNT,  HB_RET
            MOV     HBCNT,  #40
            MOV     DPTR,   #MSG_HB
            ACALL   PRINT_STR
            MOV     A,      P0
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      P1
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      P2
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      P3
            ANL     A,      #0FDH           ; 只屏蔽自己的 TXD(P3.1)
            ACALL   PUT_HEX
            ACALL   CRLF
HB_RET:
            RET

;=========================================================================
; IR_ATTEMPT：等一帧红外并解码
;   1) 等 P3.2 的下降沿（空闲时约 30ms 超时，返回什么都不打印）
;   2) 引导码低电平必须够长（>= 7.5ms），否则判为"没对上帧头"
;      —— 因为边沿检测有 1ms 粒度，实测 9ms 会读成 8~9ms
;   3) 引导码高电平：< 3ms = NEC 重复帧（遥控器按住不放）
;   4) 收 32 位，先收完再打印（打印会占 40ms，中途不能解码）
;=========================================================================
IR_ATTEMPT:
            ACALL   WAIT_LOW_EDGE
            JNC     IA_EDGE
            RET                             ; 超时：没信号，什么都不打印
IA_EDGE:
            ;---- 引导码低电平 ----
            MOV     TMO,    #40H            ; 9ms 一定在 17.8ms 内结束
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            JNC     IA_HASLO
            LJMP    IRA_ERR
IA_HASLO:
            MOV     LLO_H,  MPH
            MOV     LLO_L,  MPL
            ;---- 够不够 7.2ms（0x1A00 tick）----
            ; 边沿检测有 1ms 粒度，真正 9ms 的引导码会读成 8~9ms，留足余量。
            ; （JC/SJMP 只有 ±128 字节，跨过下面一长段解码+打印必须用 LJMP）
            MOV     A,      MPH
            CLR     C
            SUBB    A,      #1AH
            JNC     IA_LEADOK
            LJMP    IRA_SYNC
IA_LEADOK:
            ;---- 引导码高电平 ----
            MOV     TMO,    #40H
            MOV     MLVL,   #1
            ACALL   MEAS_LEVEL
            JNC     IA_HASHI
            LJMP    IRA_ERR
IA_HASHI:
            MOV     LHI_H,  MPH
            MOV     LHI_L,  MPL
            ;---- < 3.06ms（0x0B00）= NEC 重复帧（遥控器按住不放）----
            MOV     A,      LHI_H
            CLR     C
            SUBB    A,      #0BH
            JNC     IA_DATA
            LJMP    IRA_REPEAT
IA_DATA:
            ;---- 收 32 位 ----
            MOV     IB0,    #0
            MOV     IB1,    #0
            MOV     IB2,    #0
            MOV     IB3,    #0
            MOV     BITS,   #32
            MOV     PTRIDX, #0
            MOV     MASKB,  #01H
IRA_BIT:
            MOV     TMO,    #40H            ; 先量 0.56ms 的低电平（一定会结束）
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            JNC     IA_BL
            LJMP    IRA_ERR
IA_BL:
            ; 再量高电平：0.56ms=位0，1.69ms=位1。
            ; 门限取 1.36ms：量到超时说明高电平已经 >1.36ms -> 位1；
            ; 正常结束说明是高电平被下一个低电平打断了 -> 按 1.085ms 比较。
            ; 这一招同时解决了"最后一位"：整帧发完后线路一直保持高电平，
            ; 高电平永远不会"结束"，只能靠超时判成位1（NEC 的最后一字节是
            ; ~cmd，本遥控器的键值都 <0x80，所以 ~cmd 最高位本来就是 1）。
            MOV     TMO,    #05H
            MOV     MLVL,   #1
            ACALL   MEAS_LEVEL
            JC      IA_BIT1                 ; 超时 -> 位1
            MOV     A,      MPH             ; >= 1000(0x03E8) tick 判 1
            CLR     C
            SUBB    A,      #03H
            JC      IA_NEXT
            JNZ     IA_BIT1
            MOV     A,      MPL
            CLR     C
            SUBB    A,      #0E8H
            JC      IA_NEXT
IA_BIT1:
            ACALL   IR_SETBIT
IA_NEXT:
            DEC     BITS
            MOV     A,      BITS
            JNZ     IRA_BIT

            ;---- 打印 "IR lo=.... hi=.... a=.. .. c=.. .." ----
            MOV     DPTR,   #MSG_LO
            ACALL   PRINT_STR
            MOV     A,      LLO_H
            ACALL   PUT_HEX
            MOV     A,      LLO_L
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_HI
            ACALL   PRINT_STR
            MOV     A,      LHI_H
            ACALL   PUT_HEX
            MOV     A,      LHI_L
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_A
            ACALL   PRINT_STR
            MOV     A,      IB0
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      IB1
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_C
            ACALL   PRINT_STR
            MOV     A,      IB2
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      IB3
            ACALL   PUT_HEX
            ;---- cmd 与 ~cmd 是否互补 ----
            MOV     A,      IB2
            CPL     A
            XRL     A,      IB3
            JZ      IRA_OK
            MOV     DPTR,   #MSG_BAD
            ACALL   PRINT_STR
            ACALL   CRLF
            RET
IRA_OK:
            MOV     DPTR,   #MSG_OK
            ACALL   PRINT_STR
            ACALL   CRLF
IRA_RET:
            RET

IRA_REPEAT:                             ; 重复帧：只报引导码，不用收数据
            MOV     DPTR,   #MSG_LO
            ACALL   PRINT_STR
            MOV     A,      LLO_H
            ACALL   PUT_HEX
            MOV     A,      LLO_L
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_HI
            ACALL   PRINT_STR
            MOV     A,      LHI_H
            ACALL   PUT_HEX
            MOV     A,      LHI_L
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_REP
            ACALL   PRINT_STR
            ACALL   CRLF
            RET

IRA_SYNC:                               ; 帧头长度不对：多半是打印期间错过了帧头
            MOV     DPTR,   #MSG_SYNC
            ACALL   PRINT_STR
            MOV     A,      LLO_H
            ACALL   PUT_HEX
            MOV     A,      LLO_L
            ACALL   PUT_HEX
            ACALL   CRLF
            RET

IRA_ERR:                                ; 收到一半断了
            MOV     DPTR,   #MSG_ERR
            ACALL   PRINT_STR
            ACALL   CRLF
            RET

;-------------------------------------------------------------------------
; IR_SETBIT：把当前位（1）写进 IB0..IB3 的对应位置
;   PTRIDX = 字节序号，MASKB = 位掩码
;-------------------------------------------------------------------------
IR_SETBIT:
            MOV     A,      PTRIDX
            CJNE    A,      #0,     ISB_1
            MOV     A,      MASKB
            ORL     A,      IB0
            MOV     IB0,    A
            SJMP    ISB_NEXT
ISB_1:
            CJNE    A,      #1,     ISB_2
            MOV     A,      MASKB
            ORL     A,      IB1
            MOV     IB1,    A
            SJMP    ISB_NEXT
ISB_2:
            CJNE    A,      #2,     ISB_3
            MOV     A,      MASKB
            ORL     A,      IB2
            MOV     IB2,    A
            SJMP    ISB_NEXT
ISB_3:
            MOV     A,      MASKB
            ORL     A,      IB3
            MOV     IB3,    A
ISB_NEXT:
            MOV     A,      MASKB
            RL      A
            MOV     MASKB,  A
            JNZ     ISB_DONE
            MOV     MASKB,  #01H
            INC     PTRIDX
ISB_DONE:
            RET

;=========================================================================
; WAIT_LOW_EDGE：等 P3.2 出现真正的"高->低"跳变
;   先等它变高（防止接收头输出被卡在低电平），再等它变低。
;   出口：C=0 检测到跳变；C=1 超时（每段约 30ms）
;=========================================================================
WAIT_LOW_EDGE:
            MOV     R3,     #0
WLE_HI:
            JB      P3.2,   WLE_HIOK        ; 已经是高电平
            ACALL   D_1MS
            INC     R3
            MOV     A,      R3
            CJNE    A,      #30,    WLE_HI
            SETB    C
            RET
WLE_HIOK:
            MOV     R3,     #0
WLE_LO:
            JNB     P3.2,   WLE_OK          ; 等到下降沿
            ACALL   D_1MS
            INC     R3
            MOV     A,      R3
            CJNE    A,      #30,    WLE_LO
            SETB    C
            RET
WLE_OK:
            CLR     C
            RET

;=========================================================================
; MEAS_LEVEL：测量 P3.2 保持 MLVL 指定电平的时长（Timer0 tick）
;   入口：MLVL = 0(量低) / 1(量高)；TMO = 超时门限高字节
;         （TMO=0x40 -> 约 17.8ms；TMO=0x05 -> 约 1.36ms）
;   出口：C=0 电平换了，MPH:MPL = tick 数；C=1 到门限还没换电平
;   只用 R1/R2 作临时
;=========================================================================
MEAS_LEVEL:
            MOV     TSH,    TH0
            MOV     TSL,    TL0
ML_LOOP:
            MOV     R2,     TH0
            MOV     R1,     TL0
            MOV     A,      R1
            CLR     C
            SUBB    A,      TSL
            MOV     MPL,    A
            MOV     A,      R2
            SUBB    A,      TSH
            MOV     MPH,    A
            MOV     A,      MPH
            CLR     C
            SUBB    A,      TMO
            JNC     ML_TIMEOUT
            MOV     A,      MLVL
            JZ      ML_FIN_ON_HIGH
ML_FIN_ON_LOW:
            JNB     P3.2,   ML_DONE         ; 量低：等到变高
            SJMP    ML_LOOP
ML_FIN_ON_HIGH:
            JB      P3.2,   ML_DONE         ; 量高：等到变低
            SJMP    ML_LOOP
ML_DONE:
            CLR     C
            RET
ML_TIMEOUT:
            SETB    C
            RET

;=========================================================================
; 输出辅助
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

CRLF:
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
            RET

PUT_HEX:                                ; 把 A 打印成两位十六进制
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

;=========================================================================
; 延时（只用 R0~R3，不碰 R4~R7）
;   机器周期 = 12/11059200 = 1.085us
;=========================================================================
D_1MS:                                  ; ~1ms
            MOV     R2,     #2
D1M1:
            MOV     R1,     #230
D1M2:
            DJNZ    R1,     D1M2
            DJNZ    R2,     D1M1
            RET

;=========================================================================
; 字符串（存于代码空间）
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== MODTEST v1  obstacle probe + IR remote  STC89C52 @11.0592MHz ===',0DH,0AH
            DB  'no motor drive at all.  Press a remote key / block the front probes.',0DH,0AH
            DB  'IR : <lo=.... hi=.... a=.. .. c=.. ..>  [OK: NEC] = decode good',0DH,0AH
            DB  'PIN: <P1.3=0> style line = that pin just changed',0DH,0AH
            DB  'HB : 1/s snapshot = P0 P1 P2 P3 hex (P3 has TXD masked)',0DH,0AH,0

MSG_HB:     DB  'HB ',0
MSG_LO:     DB  'IR lo=',0
MSG_HI:     DB  ' hi=',0
MSG_A:      DB  ' a=',0
MSG_C:      DB  ' c=',0
MSG_OK:     DB  ' [OK: NEC]',0
MSG_BAD:    DB  ' [cmd/~cmd NOT complementary]',0
MSG_REP:    DB  ' [REPEAT: key held]',0
MSG_ERR:    DB  'IR pulse timeout (frame cut short)',0
MSG_SYNC:   DB  'IR no 9ms leader, lo=',0
MSG_CRLF:   DB  0DH,0AH,0

HEXTAB:     DB  '0123456789ABCDEF'

            END
