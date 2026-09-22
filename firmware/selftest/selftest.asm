;=========================================================================
; selftest.asm  --  智能移动机器人「全部件自检」程序（串口输出型）
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC，晶振 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name selftest
; 输出通道 : P3.1 (TXD) -> CH340 -> COM7，9600 8N1，用串口助手/终端看日志
;-------------------------------------------------------------------------
; 为什么用串口：引脚表还没确认，不知道哪个脚接数码管/蜂鸣器，
; 所以没法用"闪几下"来报告结果。但下载用的串口是已知的（P3.0/P3.1），
; 用它打印文字日志，测试过程和结果都能直接读，不需要数闪烁次数。
;
; 三个阶段（上电后自动开始，无限循环 B<->C）：
;
;   A 阶段（每个引脚一次，共 24 个引脚，约 60 秒）——"激励+观察"
;     依次对 P1.0~P1.7、P2.0~P2.7、P0.0~P0.7 的每一个引脚输出：
;        ① 4Hz 方波 2 秒   -> 电机会抽动 / 数码管段会闪 / 蜂鸣器会"咔咔"
;        ② 1kHz 方波 0.25 秒 -> 蜂鸣器会发出清晰音调 / 电机轻微高频声
;     每个引脚动作前会先打印 "[序号] P1.0: " 这一行，
;     你看到某个部件动了，就知道是那一行对应的引脚。
;     （先看终端最后一行，再看板子；每个引脚有 2.25 秒，来得及）
;
;   B 阶段（约 40 秒）——"输入扫描"
;     把 P1/P2/P3 当输入反复读（P0 不读：开漏口浮空会乱跳），
;     任何一位变化就打印 "B P1 xx -> yy"。
;     你可以做这些动作，看日志有没有反应：
;        * 按板上 S3 / S4 按键
;        * 用白纸/黑胶带在循迹探头下面过一遍（LM393 输出翻转）
;        * 用手挡住避障探头、遮住光敏电阻
;        * 拧电位器 W1/W2（阈值变化会让比较器输出翻转）
;        * 按遥控器（遥控器的完整解码在 C 阶段）
;
;   C 阶段（约 40 秒）——"红外接收头解码"
;     轮询 P3.2（0038 输出），检测到信号就打印：
;        * 引导码低/高电平时长（tick 数，1 tick ≈ 1.085us @11.0592MHz）
;        * 解码出的 4 个字节 addr / ~addr / cmd / ~cmd
;        * 校验结果（cmd 与 ~cmd 是否互补 = 是否 NEC 协议）
;     按遥控器不同的键，对比 cmd 字节就能得到"键值表"。
;
; 安全说明：
;   * 只激励 P0/P1/P2；P3 只做输入读取，且打印时屏蔽 P3.1（TXD），
;     避免自己的发送动作被当成"输入变化"。
;   * P0 是开漏口，写 1 只是"放开"，所以接在 P0 上的高电平有效负载
;     在 A 阶段不会动，属正常。
;   * 测试时把小车架起来，让轮子悬空。
;=========================================================================

;-------------------------------------------------------------------------
; RAM 变量
;-------------------------------------------------------------------------
IDX     DATA 30H            ; A 阶段：测试序号 1..24
BITIDX  DATA 31H            ; A 阶段：位号 0..7
MLVL    DATA 32H            ; MEAS_LEVEL：0=量低电平，1=量高电平
TSH     DATA 33H            ; 测量起始时刻（Timer0 高字节）
TSL     DATA 34H            ; 测量起始时刻（Timer0 低字节）
MPH     DATA 35H            ; 测量结果高字节
MPL     DATA 36H            ; 测量结果低字节
LEDG_H  DATA 37H            ; 引导码低电平时长
LEDG_L  DATA 38H
LEDH_H  DATA 39H            ; 引导码高电平时长
LEDH_L  DATA 3AH
BITS    DATA 3BH            ; 剩余位数
PTRIDX  DATA 3CH            ; 当前字节序号 0..3
MASKB   DATA 3DH            ; 当前位掩码
IB0     DATA 3EH            ; 解码结果：addr
IB1     DATA 3FH            ;             ~addr
IB2     DATA 40H            ;             cmd
IB3     DATA 41H            ;             ~cmd
LAST1   DATA 42H            ; B 阶段上次读到的端口值
LAST2   DATA 43H
LAST3   DATA 44H
CNT     DATA 45H            ; 通用循环计数

;-------------------------------------------------------------------------
            ORG     0000H
            LJMP    MAIN

            ORG     0030H
;=========================================================================
; 主程序
;=========================================================================
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #0FFH           ; 开漏口：写 1 = 放开
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH

            ;---- 串口：9600 8N1，Timer1 方式2，T0 方式1 作测量时基 ----
            MOV     TMOD,   #21H            ; T1: 方式2(自动重装)  T0: 方式1(16位)
            MOV     TH1,    #0FDH           ; 11059200/(384*3) = 9600
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H            ; 方式1，允许接收
            MOV     PCON,   #00H            ; SMOD = 0
            SETB    TR1                     ; 启动波特率发生器
            MOV     TH0,    #00H            ; Timer0 自由运行，只读不中断
            MOV     TL0,    #00H
            SETB    TR0

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;---- A 阶段：逐引脚激励 ----
PHASE_A:
            MOV     DPTR,   #MSG_A
            ACALL   PRINT_STR
            MOV     IDX,    #0

            MOV     R6,     #1              ; P1 组
            ACALL   EXCITE_PORT
            MOV     R6,     #2              ; P2 组
            ACALL   EXCITE_PORT
            MOV     R6,     #0              ; P0 组（开漏）
            ACALL   EXCITE_PORT

            MOV     DPTR,   #MSG_A_DONE
            ACALL   PRINT_STR

;---- B/C 阶段无限循环 ----
MAIN_LOOP:
            ACALL   PHASE_B
            ACALL   PHASE_C
            SJMP    MAIN_LOOP

;=========================================================================
; A 阶段：对 R6 指定的端口逐个引脚做激励
;   入口 R6 = 端口号 (0=P0,1=P1,2=P2)
;   使用 R7 位掩码 / R5 输出图案 / R4 延时计数 / BITIDX / IDX
;=========================================================================
EXCITE_PORT:
            MOV     R7,     #01H
            MOV     BITIDX, #0
EP_BIT:
            INC     IDX
            ACALL   PRINT_PREFIX            ; 打印 "[序号] P<n>.<bit>: "

            ;---- ① 4Hz 方波 2 秒：目标位为 0，其余为 1 ----
            MOV     A,      #0FFH
            XRL     A,      R7
            MOV     R5,     A
            MOV     R4,     #8              ; 8 个周期（半周期 ~130ms）
EP_LOOP:
            MOV     A,      R5
            ACALL   PORT_OUT
            ACALL   D_HALF
            MOV     A,      #0FFH
            ACALL   PORT_OUT
            ACALL   D_HALF
            DJNZ    R4,     EP_LOOP

            ;---- ② 1kHz 方波 0.25 秒：蜂鸣器会响，电机轻微高频声 ----
            MOV     R4,     #250            ; 250 个周期 × 1ms = 0.25s
EP_BEEP:
            MOV     A,      R5
            ACALL   PORT_OUT
            ACALL   D_500US
            MOV     A,      #0FFH
            ACALL   PORT_OUT
            ACALL   D_500US
            DJNZ    R4,     EP_BEEP

            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR

            MOV     A,      R7
            RL      A
            MOV     R7,     A
            INC     BITIDX
            MOV     A,      BITIDX
            CJNE    A,      #8,     EP_BIT
            RET

;=========================================================================
; B 阶段：输入扫描，端口值变化就打印
;=========================================================================
PHASE_B:
            MOV     DPTR,   #MSG_B
            ACALL   PRINT_STR
            MOV     P0,     #0FFH
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH
            MOV     LAST1,  P1
            MOV     LAST2,  P2
            MOV     A,      P3
            ANL     A,      #0FDH           ; 屏蔽 TXD(P3.1)：自己的发送不算输入
            MOV     LAST3,  A

            MOV     CNT,    #200            ; 200 × 200ms = 40 秒
PB_LOOP:
            ;---- P1 ----
            MOV     A,      P1
            MOV     R2,     A
            XRL     A,      LAST1
            JZ      PB_CHK2
            MOV     LAST1,  R2
            MOV     DPTR,   #MSG_IN1
            ACALL   PRINT_STR
            MOV     A,      R2
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
PB_CHK2:
            ;---- P2 ----
            MOV     A,      P2
            MOV     R2,     A
            XRL     A,      LAST2
            JZ      PB_CHK3
            MOV     LAST2,  R2
            MOV     DPTR,   #MSG_IN2
            ACALL   PRINT_STR
            MOV     A,      R2
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
PB_CHK3:
            ;---- P3（屏蔽 P3.1）----
            MOV     A,      P3
            ANL     A,      #0FDH
            MOV     R2,     A
            XRL     A,      LAST3
            JZ      PB_WAIT
            MOV     LAST3,  R2
            MOV     DPTR,   #MSG_IN3
            ACALL   PRINT_STR
            MOV     A,      R2
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
PB_WAIT:
            ACALL   D_100MS
            ACALL   D_100MS                 ; 采样周期 200ms
            DEC     CNT
            MOV     A,      CNT
            JNZ     PB_LOOP
            RET

;=========================================================================
; C 阶段：红外接收解码（轮询 P3.2）
;=========================================================================
PHASE_C:
            MOV     DPTR,   #MSG_C
            ACALL   PRINT_STR
            MOV     CNT,    #150            ; 150 轮
PC_LOOP:
            ACALL   IR_ATTEMPT
            ACALL   D_100MS
            ACALL   D_100MS
            DEC     CNT
            MOV     A,      CNT
            JNZ     PC_LOOP
            RET

;=========================================================================
; IR_ATTEMPT：尝试接收并解码一帧红外
;   没有信号时很快返回（等边沿超时约 30ms）
;=========================================================================
IR_ATTEMPT:
            ;---- 1) 等 0038 输出出现下降沿（遥控信号开始）----
            ACALL   WAIT_LOW_EDGE
            JNC     IRA_LEADER              ; 接到下降沿
            RET                             ; 超时：无信号，直接返回
IRA_LEADER:

            ;---- 2) 引导码：低电平（应 ~9ms）----
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            JNC     IRA_LEAD_LO
            LJMP    IRA_ERR                 ; 脉冲超时（JC/SJMP 只有 ±128 字节，故用 LJMP）
IRA_LEAD_LO:
            MOV     LEDG_H, MPH
            MOV     LEDG_L, MPL

            ;---- 3) 引导码：高电平（应 ~4.5ms）----
            MOV     MLVL,   #1
            ACALL   MEAS_LEVEL
            JNC     IRA_LEAD_HI
            LJMP    IRA_ERR
IRA_LEAD_HI:
            MOV     LEDH_H, MPH
            MOV     LEDH_L, MPL

            ;---- 4) 打印引导码 ----
            MOV     DPTR,   #MSG_IR
            ACALL   PRINT_STR
            MOV     A,      LEDG_H
            ACALL   PUT_HEX
            MOV     A,      LEDG_L
            ACALL   PUT_HEX
            MOV     A,      #'/'
            ACALL   PUTCHAR
            MOV     A,      LEDH_H
            ACALL   PUT_HEX
            MOV     A,      LEDH_L
            ACALL   PUT_HEX

            ;---- 5) 收 32 位 ----
            MOV     IB0,    #0
            MOV     IB1,    #0
            MOV     IB2,    #0
            MOV     IB3,    #0
            MOV     BITS,   #32
            MOV     PTRIDX, #0
            MOV     MASKB,  #01H
IRA_BIT:
            ; 每位：先低电平（~0.56ms），再高电平（0.56ms=0 / 1.69ms=1）
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            JC      IRA_ERR
            MOV     MLVL,   #1
            ACALL   MEAS_LEVEL
            JC      IRA_ERR

            ; 高电平 >= 1000 tick（约 1.09ms）判为 1
            MOV     A,      MPH
            CLR     C
            SUBB    A,      #03H
            JC      IRA_NEXT                ; MPH < 3 -> 位 = 0
            JNZ     IRA_SET1                ; MPH > 3 -> 位 = 1
            MOV     A,      MPL
            CLR     C
            SUBB    A,      #0E8H           ; 1000 = 03E8H
            JC      IRA_NEXT

IRA_SET1:
            ACALL   IR_SETBIT
IRA_NEXT:
            DEC     BITS
            MOV     A,      BITS
            JNZ     IRA_BIT

            ;---- 6) 打印 4 个字节 ----
            MOV     DPTR,   #MSG_IR_DATA
            ACALL   PRINT_STR
            MOV     A,      IB0
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      IB1
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      IB2
            ACALL   PUT_HEX
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      IB3
            ACALL   PUT_HEX

            ;---- 7) 校验 cmd 与 ~cmd 是否互补 ----
            MOV     A,      IB2
            CPL     A
            XRL     A,      IB3
            JZ      IRA_OK
            MOV     DPTR,   #MSG_IR_BAD
            ACALL   PRINT_STR
            SJMP    IRA_RET
IRA_OK:
            MOV     DPTR,   #MSG_IR_OK
            ACALL   PRINT_STR
IRA_RET:
            RET
IRA_ERR:
            MOV     DPTR,   #MSG_IR_ERR
            ACALL   PRINT_STR
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
            JNZ     ISB_DONE                ; 掩码还没溢出 -> 同字节下一位
            MOV     MASKB,  #01H            ; 溢出 -> 下一个字节
            INC     PTRIDX
ISB_DONE:
            RET

;=========================================================================
; WAIT_LOW_EDGE：等 P3.2 出现下降沿
;   出口：C=0 检测到；C=1 超时（约 30ms）
;=========================================================================
WAIT_LOW_EDGE:
            MOV     R3,     #0
WLE_LOOP:
            JNB     P3.2,   WLE_OK          ; 已经变低
            ACALL   D_1MS
            INC     R3
            MOV     A,      R3
            CJNE    A,      #30,    WLE_LOOP
            SETB    C
            RET
WLE_OK:
            CLR     C
            RET

;=========================================================================
; MEAS_LEVEL：测量 P3.2 保持 MLVL 指定电平的时长（Timer0 tick）
;   入口：MLVL = 0(量低) / 1(量高)
;   出口：C=0 成功，MPH:MPL = tick 数；C=1 超时（约 18ms）
;   只用 R1/R2 作临时，不破坏 R4~R7
;=========================================================================
MEAS_LEVEL:
            MOV     TSH,    TH0
            MOV     TSL,    TL0
ML_LOOP:
            MOV     R2,     TH0
            MOV     R1,     TL0
            ; delta = now - start
            MOV     A,      R1
            CLR     C
            SUBB    A,      TSL
            MOV     MPL,    A
            MOV     A,      R2
            SUBB    A,      TSH
            MOV     MPH,    A
            ; 超时判断：MPH >= 40H（约 18ms）就放弃
            MOV     A,      MPH
            CLR     C
            SUBB    A,      #40H
            JNC     ML_TIMEOUT
            ; 电平是否已经变化（注意：名字按"结束条件"取，
            ; 量低电平时要等到变高才算结束，量高电平则等到变低）
            MOV     A,      MLVL
            JZ      ML_FIN_ON_HIGH
ML_FIN_ON_LOW:
            JNB     P3.2,   ML_DONE
            SJMP    ML_LOOP
ML_FIN_ON_HIGH:
            JB      P3.2,   ML_DONE
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
PORT_OUT:                               ; A -> R6 指定的端口
            CJNE    R6,     #0,     PO_P1
            MOV     P0,     A
            RET
PO_P1:
            CJNE    R6,     #1,     PO_P2
            MOV     P1,     A
            RET
PO_P2:
            MOV     P2,     A
            RET

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

PRINT_PREFIX:                           ; 打印 "[序号] P<n>.<bit>: "
            MOV     A,      #'['
            ACALL   PUTCHAR
            MOV     A,      IDX
            ACALL   PUT_HEX
            MOV     A,      #']'
            ACALL   PUTCHAR
            MOV     A,      #' '
            ACALL   PUTCHAR
            MOV     A,      #'P'
            ACALL   PUTCHAR
            MOV     A,      R6
            ADD     A,      #'0'
            ACALL   PUTCHAR
            MOV     A,      #'.'
            ACALL   PUTCHAR
            MOV     A,      BITIDX
            ADD     A,      #'0'
            ACALL   PUTCHAR
            MOV     A,      #':'
            ACALL   PUTCHAR
            MOV     A,      #' '
            ACALL   PUTCHAR
            RET

;=========================================================================
; 延时（只用 R1/R2/R3/R0，不碰 R4~R7）
;   机器周期 = 12/11059200 = 1.085us
;=========================================================================
D_HALF:                                 ; ~130ms
            MOV     R1,     #250
DH1:
            MOV     R2,     #238
DH2:
            DJNZ    R2,     DH2
            DJNZ    R1,     DH1
            RET

D_1MS:                                  ; ~1ms
            MOV     R2,     #2
D1M1:
            MOV     R1,     #230
D1M2:
            DJNZ    R1,     D1M2
            DJNZ    R2,     D1M1
            RET

D_100MS:                                ; ~100ms
            MOV     R3,     #100
D100:
            ACALL   D_1MS
            DJNZ    R3,     D100
            RET

D_500US:                                ; ~0.5ms（1kHz 半周期）
            MOV     R0,     #229
D500:
            DJNZ    R0,     D500
            RET

;=========================================================================
; 字符串（存于代码空间）
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== SELFTEST v1  STC89C52 @11.0592MHz  UART 9600 8N1 ===',0DH,0AH
            DB  'A: per-pin excitation  -> find motors / buzzer / 7-seg',0DH,0AH
            DB  'B: input scan          -> buttons / IR sensors / LDR / pot',0DH,0AH
            DB  'C: IR receiver decode  -> NEC on P3.2 (0038)',0DH,0AH,0

MSG_A:
            DB  0DH,0AH,'--- A: exciting every pin: 4Hz x2s then 1kHz x0.25s ---',0DH,0AH
            DB  'watch which part reacts, note the [n] number printed before it',0DH,0AH,0

MSG_A_DONE:
            DB  0DH,0AH,'--- A done (24 pins) ---',0DH,0AH,0

MSG_B:
            DB  0DH,0AH,'--- B: input scan 40s --- press S3/S4, slide paper under the',0DH,0AH
            DB  'line sensors, block the obstacle/LDR, turn W1/W2, press the remote',0DH,0AH,0

MSG_C:
            DB  0DH,0AH,'--- C: IR decode 40s --- press any key on the remote',0DH,0AH,0

MSG_IN1:    DB  'B P1 ',0
MSG_IN2:    DB  'B P2 ',0
MSG_IN3:    DB  'B P3 ',0
MSG_IR:     DB  'C IR leader lo/hi = ',0
MSG_IR_DATA:DB  '  data ',0
MSG_IR_OK:  DB  '  [OK: NEC]',0DH,0AH,0
MSG_IR_BAD: DB  '  [cmd/~cmd not complementary]',0DH,0AH,0
MSG_IR_ERR: DB  'C IR pulse timeout (signal too long/short)',0DH,0AH,0
MSG_CRLF:   DB  0DH,0AH,0

HEXTAB:     DB  '0123456789ABCDEF'

            END
