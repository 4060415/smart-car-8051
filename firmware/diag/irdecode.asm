;=========================================================================
; irdecode.asm  --  NEC 解码诊断 +  "不用串口读键值"
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name irdecode
;-------------------------------------------------------------------------
; 一、为什么有它
;   irprobe.hex 只证明"P3.3 上有红外活动"，但它不解码。
;   本程序做**真正的 NEC 解码**，并把结果用**数码管 + 蜂鸣器**报出来 ——
;   完全不需要串口。
;
; 二、怎么读（不用串口）
;   数码管**交替显示**最近一次解出的键值：先显示高半字节、再显示低半字节，交替约 0.4 秒：
;       闪 "4" 然后闪 "6"   ->  键值 = 46H = 前进键
;       闪 "4" 然后闪 "0"   ->  键值 = 40H = 暂停键
;       （十六进制：0-9 显示数字，A-F 显示字母 A b C d E F）
;
;   蜂鸣器音型直接区分三种结果：
;       短"嘀"1 声      = **完整帧**（解码成功，键值已更新到数码管上）
;       很短的"嗒"       = **重复帧**（说明这只遥控器**会发 NEC 重复码**，按住不放会响）
;       两声短"嘀"       = **帧被拒**（见到边沿但没解成 NEC —— 解码门限/环境干扰问题）
;       完全没声音       = 连下降沿都没等到（P3.3 上没有活动）
;   D3 灯：收到**完整帧**后亮约 0.3 秒。
;
; 三、判读表（配合 irprobe 的结论用）
;   irprobe 计数会涨 + 本程序只有"两声短嘀"  -> 有红外但不是 NEC：协议不同 或 环境干扰/门限要调
;   irprobe 计数会涨 + 本程序连声音都没有     -> 下降沿等待/时基有问题（要看代码）
;   irprobe 计数会涨 + 本程序短嘀 + 数码管出键值 -> 解码正常，问题在别的模块
;
; 四、安全
;   P0 恒为 0C0H（ENA/ENB 拉低 = 电机断电），**不驱动电机**。
;=========================================================================

; --- 数码管段码（共阳：写 0 点亮；bit7..bit1 = a b c d e f g；bit0 = D3，1 = 灭）---
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
DISP_A      EQU     11H             ; "A"
DISP_B      EQU     0C1H            ; "b"
DISP_C      EQU     63H             ; "C"
DISP_D      EQU     89H             ; "d"
DISP_E      EQU     61H             ; "E"
DISP_F      EQU     71H             ; "F"
DISP_BLANK  EQU     0FFH            ; 全灭（含 D3 灭）

PAT_STOP    EQU     0C0H

; --- 时基/NEC 门限（沿用 remote.asm 实测可用的值）---
T0_RELOAD   EQU     164             ; 100us tick
IR_LEAD_MIN EQU     70
IR_LEAD_MAX EQU     120
IR_LEADHCAP EQU     60
IR_LEADH_MIN EQU    25              ; 完整帧的引导码高电平 >= 2.5ms
IR_REP_MIN  EQU     12              ; 1.2ms <= 引导码高电平 < 2.5ms  -> **NEC 重复帧**
IR_BIT_TH   EQU     11
IR_BITCAP   EQU     12
FLIP_TK     EQU     5000            ; 显示相位间隔：5000 tick = 500ms（每轮：高位→低位→空档）
D3_TK       EQU     3000            ; D3 亮 3000 tick = 300ms
BEEP_OK     EQU     24              ; 完整帧：短嘀
BEEP_REJ    EQU     6               ; 被拒：两声短嘀（每声 6 半周期）
BEEP_RPT    EQU     3               ; 重复帧：很短的嗒

; --- RAM ---
TICK_L      DATA    30H
TICK_H      DATA    31H
STR_H       DATA    32H
STR_L       DATA    33H
DUR_H       DATA    34H
DUR_L       DATA    35H
CAP_L       DATA    36H
MLVL        DATA    37H
BITS        DATA    38H
PTRIDX      DATA    39H
MASKB       DATA    3AH
IB0         DATA    3BH
IB1         DATA    3CH
IB2         DATA    3DH             ; cmd = 键值
IB3         DATA    3EH
IRSTAT      DATA    3FH             ; 0=完整帧 1=静默 2=被拒 3=重复帧
LASTKEY     DATA    40H             ; 最近一次解出的键值
PHASE       DATA    41H             ; 0=显示高半字节 1=显示低半字节
FLIPT_H     DATA    42H             ; 上次切换显示的时刻
FLIPT_L     DATA    43H
OKT_H       DATA    44H             ; 上次收到完整帧的时刻（控制 D3）
OKT_L       DATA    45H
BUZP        DATA    46H
BUZLEFT     DATA    47H
LEDLO       DATA    48H             ; 诊断：最近量到的引导码低电平（tick）
LEDHI       DATA    49H             ; 诊断：最近量到的引导码高电平
SHORTL      DATA    4AH             ; 1 = 本次引导码高电平是"短的"（1.2~2.5ms）
HBCNT       DATA    4BH             ; 心跳计数（每 80 轮打一行）
HBSTAT      DATA    4CH             ; 最近一帧的类别：'*'=完整帧  '!'=短引导码数据失败

BUZB        BIT     20H.0           ; 1 = 蜂鸣器静音

            ORG     0000H
            LJMP    MAIN

            ORG     000BH               ; Timer0：只累加 100us 时基
            LJMP    T0_ISR

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     TICK_L, #0
            MOV     TICK_H, #0
            MOV     LASTKEY,#0
            MOV     PHASE,  #0
            MOV     HBCNT,  #0
            MOV     FLIPT_H,#0
            MOV     FLIPT_L,#0
            MOV     OKT_H,  #0
            MOV     OKT_L,  #0
            MOV     BUZP,   #0
            MOV     BUZLEFT,#0
            SETB    BUZB                ; 静音
            MOV     P0,     #PAT_STOP
            MOV     P1,     #0FFH
            MOV     P2,     #DISP_BLANK
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
            ACALL   TICK_GET
            MOV     FLIPT_H,R4
            MOV     FLIPT_L,R5
            MOV     OKT_H,  R4
            MOV     OKT_L,  R5

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;=========================================================================
; 主循环：收一帧 -> 按结果出声/更新键值 -> 刷新显示
;=========================================================================
LOOP:
            ACALL   IR_RECV
            MOV     A,      IRSTAT
            JZ      L_OK                ; 0 = 完整帧
            CJNE    A,      #3,     L_NOTREP
            ; ---- 重复帧：很短的"嗒"（证明遥控器会发重复码）----
            MOV     A,      #BEEP_RPT
            ACALL   BEEP
            SJMP    L_SHOW
L_NOTREP:
            CJNE    A,      #2,     L_CHK4      ; 1 = 静默，什么都不做
            ; ---- 2 声：引导码**低**电平不合格 ----
            MOV     A,      LEDLO
            MOV     LASTKEY,A
            MOV     A,      #2
            ACALL   REJN
            SJMP    L_SHOW
L_CHK4:
            MOV     A,      IRSTAT
            ; ★★ 2026-09-20 修 BUG（实测踩到）：这里原来跳 `L_CHK5`，
            ;   于是 **`L_CHK6` 整块成了死代码** —— 没有任何一条路能走到它。
            ;   而 `IRSTAT=6`（"短引导码 + 数据段没过"）**正好是这颗遥控器的失败方式**
            ;   （它发的是短引导码变体）。后果：这一帧被当成"静默"吞掉 ——
            ;   **不响、不设 HBSTAT、不打原始 4 字节**，心跳永远显示 '?'，
            ;   看日志完全查不出问题。改成跳 L_CHK6，让它接住 6。
            CJNE    A,      #4,     L_CHK6
            ; ---- 3 声：引导码**高**电平太短（2.25ms 型）----
            MOV     A,      LEDHI
            MOV     LASTKEY,A
            MOV     A,      #3
            ACALL   REJN
            SJMP    L_SHOW
L_CHK6:
            MOV     A,      IRSTAT
            CJNE    A,      #6,     L_CHK5
            ; ---- 短引导码但数据段没过：**把原始 4 个字节打出来**（串口），
            ;      数码管显示已经解到的那部分（IB2）——它如果随按键变化，说明只差一点 ----
            MOV     A,      IB2
            MOV     LASTKEY,A
            MOV     HBSTAT, #21H        ; '!'
            MOV     A,      #BEEP_RPT
            ACALL   BEEP
            ACALL   PRT_IB4
            SJMP    L_SHOW
L_CHK5:
            MOV     A,      IRSTAT
            CJNE    A,      #5,     L_SHOW      ; ★ 1 = 静默：什么都不做（不能落到下面去响！）
            ; ---- 4 声：数据段 / 互补校验不合格 ----
            MOV     A,      LEDHI
            MOV     LASTKEY,A
            MOV     A,      #4
            ACALL   REJN
            SJMP    L_SHOW

L_OK:
            ; ---- 完整帧：存键值 + 短嘀 + 刷新 D3 时刻 ----
            MOV     A,      IB2
            MOV     LASTKEY,A
            MOV     HBSTAT, #2AH        ; '*'
            ACALL   TICK_GET
            MOV     OKT_H,  R4
            MOV     OKT_L,  R5
            MOV     A,      #BEEP_OK
            ACALL   BEEP
            MOV     DPTR,   #MSG_KEY
            ACALL   PRINT_STR
            MOV     A,      LASTKEY
            ACALL   PUT_HEX
            ACALL   CRLF

L_SHOW:
            ACALL   SHOW                ; 数码管：交替显示键值的高/低半字节
            ; ---- 心跳：每约 80 轮（≈2 秒）打一行 **带数据的** 记录 ----
            ;   这样"什么时候按键"都不怕：按键后最多 2 秒，日志里就会出现那一帧的 4 个字节。
            INC     HBCNT
            MOV     A,      HBCNT
            CJNE    A,      #80,    L_NOBEAT
            MOV     HBCNT,  #0
            ACALL   PRT_HB
L_NOBEAT:
            SJMP    LOOP

;=========================================================================
; SHOW —— 数码管交替显示 LASTKEY 的高/低半字节；D3 = 最近 300ms 内收到过完整帧
;=========================================================================
SHOW:
            ; ---- 到点就切换显示相位 ----
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      FLIPT_L
            MOV     R6,     A
            MOV     A,      R4
            SUBB    A,      FLIPT_H
            MOV     R7,     A
            MOV     A,      R7
            CLR     C
            SUBB    A,      #HIGH(FLIP_TK)
            JC      SH_NEXT
            JNZ     SH_FLIP
            MOV     A,      R6
            CLR     C
            SUBB    A,      #LOW(FLIP_TK)
            JC      SH_NEXT
SH_FLIP:
            MOV     FLIPT_H,R4
            MOV     FLIPT_L,R5
            MOV     A,      PHASE
            INC     A
            CJNE    A,      #3,     SH_FSET
            CLR     A
SH_FSET:
            MOV     PHASE,  A

SH_NEXT:
            ; ---- 取要显示的半字节；三轮一循环：高位 -> 低位 -> 全灭（空档分隔）----
            MOV     A,      PHASE
            CJNE    A,      #2,     SH_NOTBLANK
            MOV     P2,     #DISP_BLANK     ; 空档：让"这一组两位"和下一轮分开
            RET
SH_NOTBLANK:
            JNZ     SH_LOW
            MOV     A,      LASTKEY
            SWAP    A                   ; 高半字节
            SJMP    SH_MASK
SH_LOW:
            MOV     A,      LASTKEY
SH_MASK:
            ANL     A,      #0FH
            MOV     DPTR,   #HEXTAB
            MOVC    A,      @A+DPTR
            MOV     R6,     A

            ; ---- D3：最近 300ms 收到过完整帧就亮 ----
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      OKT_L
            MOV     A,      R4
            SUBB    A,      OKT_H
            JNZ     SH_D3OFF            ; 差的高字节非 0（>25.6ms 以上都算旧）
            MOV     A,      R5
            CLR     C
            SUBB    A,      OKT_L
            CLR     C
            SUBB    A,      #LOW(D3_TK)
            JNC     SH_D3OFF
            ; 差 < 300ms -> 亮
            MOV     A,      R6
            CLR     ACC.0
            MOV     P2,     A
            RET
SH_D3OFF:
            MOV     A,      R6
            SETB    ACC.0
            MOV     P2,     A
            RET

;=========================================================================
; IR_RECV / IR_START / IR_EDGE / IR_BITLOOP / IR_SETBIT / MEAS_LEVEL
;   —— 与 remote.asm / car_asm.asm 里那套完全一致（已上机验证过的实现）
;   出口 IRSTAT：0 完整帧  1 静默  2 被拒  3 重复帧
;=========================================================================
IR_RECV:
            MOV     CAP_L,  #0
            MOV     LEDLO,  #0
            MOV     LEDHI,  #0
            MOV     SHORTL, #0
            MOV     IRSTAT, #1
IR_START:
            ACALL   TICK_GET
            MOV     STR_H,  R4
            MOV     STR_L,  R5
IRW_EDGE:
            JNB     P3.3,   IR_EDGE
            ACALL   TICK_GET
            MOV     A,      R5
            CLR     C
            SUBB    A,      STR_L
            MOV     A,      R4
            SUBB    A,      STR_H
            JNZ     IR_SILENT
            SJMP    IRW_EDGE
IR_SILENT:
            RET
; ---- 三个不同的失败出口（用**响几声**区分，不用看串口）----
IR_REJECT_L:
            MOV     IRSTAT, #2          ; 2 声：引导码**低**电平不合格（显示 LEDLO）
            RET
IR_REJECT_H:
            MOV     IRSTAT, #4          ; 3 声：引导码**高**电平太短（<1.2ms，噪声）
            RET                         ;        （显示 LEDHI）
IR_REP_N:
            MOV     IRSTAT, #3          ; 很短一"嗒"：**NEC 重复帧**（9ms 低 + 2.25ms 高）
            RET
IR_EDGE:
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            MOV     LEDLO,  DUR_L
            JC      IR_REJECT_L
            MOV     A,      DUR_H
            JNZ     IR_REJECT_L
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_LEAD_MIN
            JC      IR_REJECT_L
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_LEAD_MAX
            JNC     IR_REJECT_L
            MOV     MLVL,   #1
            MOV     CAP_L,  #IR_LEADHCAP
            ACALL   MEAS_LEVEL
            MOV     LEDHI,  DUR_L
            JC      IR_REPEAT
            MOV     A,      DUR_H
            JNZ     IR_REPEAT
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_REP_MIN
            JC      IR_REJECT_H          ; < 1.2ms -> 噪声，判帧被拒
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_LEADH_MIN
            JNC     LEAD_GO              ; >= 2.5ms -> 标准 NEC 完整帧的引导码
            ; ---- 1.2~2.5ms：**不急着下结论** ----
            ;   可能①：这是这颗遥控器"完整帧"的短引导码（有些遥控器就这么发）
            ;   可能②：这是 NEC 重复帧（9ms 低 + 2.25ms 高，后面只有 0.56ms 的短脉冲）
            ;   两者只能靠"后面有没有 32 位合法数据"区分 -> 打标记继续解，解不出来才算重复帧。
            MOV     SHORTL, #1
LEAD_GO:
            ; ---- 收 32 位（NEC 低位在前）----
            MOV     IB0,    #0
            MOV     IB1,    #0
            MOV     IB2,    #0
            MOV     IB3,    #0
            MOV     BITS,   #32
            MOV     PTRIDX, #0
            MOV     MASKB,  #01H
IR_BITLOOP:
            MOV     CAP_L,  #0
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            JC      IR_BAD
            MOV     MLVL,   #1
            MOV     A,      BITS
            CJNE    A,      #1,     IR_MIDBIT
            MOV     CAP_L,  #IR_BITCAP
            ACALL   MEAS_LEVEL
            JNC     IR_NEXTBIT
            SJMP    IR_SET1
IR_MIDBIT:
            MOV     CAP_L,  #0
            ACALL   MEAS_LEVEL
            JC      IR_BAD
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      #IR_BIT_TH
            JC      IR_NEXTBIT
IR_SET1:
            ACALL   IR_SETBIT
IR_NEXTBIT:
            ; ---- ★★ 2026-09-20 修 BUG：掩码/字节推进必须**每一位都做**，
            ;      不能像原来那样只在"这一位=1"时做（见下面 IR_SETBIT 的说明）。
            ;      写法与 `car_asm.asm`（**已上机验证可用**的解码器）完全一致：RLC + JNC。
            MOV     A,      MASKB
            CLR     C
            RLC     A                       ; 80H -> 00H 且 C=1（进位 = 该换字节了）
            MOV     MASKB,  A
            JNC     IR_NB_CONT
            MOV     MASKB,  #01H
            INC     PTRIDX
IR_NB_CONT:
            DEC     BITS
            MOV     A,      BITS
            JNZ     IR_BITLOOP
            MOV     A,      IB0
            CPL     A
            XRL     A,      IB1
            JNZ     IR_BAD
            MOV     A,      IB2
            CPL     A
            XRL     A,      IB3
            JNZ     IR_BAD
            MOV     IRSTAT, #0
            RET
IR_REPEAT:
            MOV     IRSTAT, #3
            RET
IR_BAD:
            ; ---- 32 位没解出来：区分"短引导码的帧解失败"和"重复帧" ----
            MOV     A,      SHORTL
            JZ      IR_BAD_HARD
            MOV     IRSTAT, #6          ; 短引导码 + 数据段没过
            RET                         ;   （主循环会把原始 4 字节打出来，且显示 IB2）
IR_BAD_HARD:
            MOV     IRSTAT, #5          ; 标准引导码但数据段/校验不合格
            RET

IR_SETBIT:
            MOV     A,      PTRIDX
            CJNE    A,      #0,     ISB_1
            MOV     A,      MASKB
            ORL     A,      IB0
            MOV     IB0,    A
            SJMP    ISB_NEXT
ISB_1:      CJNE    A,      #1,     ISB_2
            MOV     A,      MASKB
            ORL     A,      IB1
            MOV     IB1,    A
            SJMP    ISB_NEXT
ISB_2:      CJNE    A,      #2,     ISB_3
            MOV     A,      MASKB
            ORL     A,      IB2
            MOV     IB2,    A
            SJMP    ISB_NEXT
ISB_3:
            MOV     A,      MASKB
            ORL     A,      IB3
            MOV     IB3,    A
ISB_NEXT:
ISB_DONE:
            RET                         ; ★ 掩码推进已移到 IR_NEXTBIT（见那里的说明）：
                                        ;   原来在这里用 `RL A` + `JNZ ISB_DONE`，而 RL 把
                                        ;   80H 转成 01H **永远不为 0** -> JNZ 恒成立 ->
                                        ;   `INC PTRIDX` 是死代码 -> 32 位全挤进 IB0，
                                        ;   解出来只会是 FF 00 00 00 / 00 00 00 00（实测如此）。

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
            MOV     A,      DUR_H
            JNZ     ML_TIMEOUT
            MOV     A,      DUR_L
            CLR     C
            SUBB    A,      CAP_L
            JC      ML_LEVEL
            SJMP    ML_TIMEOUT
ML_DEFCAP:
            MOV     A,      DUR_H
            JNZ     ML_TIMEOUT
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
; Timer0 中断：只累加 100us 时基；另外顺手产生蜂鸣器方波
;   （本程序不用 PWM，电机全程断电）
;=========================================================================
T0_ISR:
            PUSH    PSW
            PUSH    ACC
            INC     TICK_L
            MOV     A,      TICK_L
            JNZ     T0_T
            INC     TICK_H
T0_T:
            INC     BUZP
            MOV     A,      BUZP
            CJNE    A,      #5,     T0_END
            MOV     BUZP,   #0
            MOV     A,      BUZLEFT
            JZ      T0_MUTE
            DEC     BUZLEFT
            CPL     BUZB
            SJMP    T0_OUT
T0_MUTE:
            SETB    BUZB
T0_OUT:
            MOV     P0,     #PAT_STOP
            MOV     C,      BUZB
            MOV     ACC.6,  C           ; P0.6 = 蜂鸣器位
            MOV     P0,     A
T0_END:
            POP     ACC
            POP     PSW
            RETI

;=========================================================================
; BEEP —— 入：A = 半周期个数
;=========================================================================
BEEP:
            JZ      BEEP_OFF
            CLR     EA
            MOV     BUZLEFT, A
            CLR     BUZB
            SETB    EA
            RET
BEEP_OFF:
            CLR     EA
            MOV     BUZLEFT, #0
            SETB    BUZB
            SETB    EA
            RET

;=========================================================================
; PRT_IB4 —— 打印"短引导码但数据段没过"时解出来的原始 4 个字节
;   判读：标准 NEC 应该是 IB0/~IB0、IB2/~IB2 两对互补
;         例：IB=00 FF 46 B9  -> 完全正常（那就是校验逻辑的问题）
;             IB=00 00 00 00  -> 位采样没工作（门限/极性不对）
;=========================================================================
;=========================================================================
; PRT_HB —— 心跳行：带最近一帧的原始 4 个字节
;   格式： CRLF + "[" + 状态字符 + "IB=xx xx xx xx" + "]"
;   状态字符：'*' = 完整帧（32 位 + 互补校验通过）
;             '!' = 短引导码但数据段没过
;             '?' = 还没收到过任何帧
;   有了它，"按键的时机"就不重要了 —— 按键后最多 2 秒这一行就会出现。
;=========================================================================
PRT_HB:
            MOV     DPTR,   #MSG_HB
            ACALL   PRINT_STR
            MOV     A,      HBSTAT
            JNZ     PH_STAT
            MOV     A,      #3FH            ; '?'
PH_STAT:
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
            MOV     A,      #5DH            ; ']'
            ACALL   PUTCHAR
            RET

PRT_IB4:
            MOV     DPTR,   #MSG_SL
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
            ACALL   CRLF
            RET

;=========================================================================
; REJN —— 入：A = 响几声（每声一个短"嘀"，间隔 60ms）
;=========================================================================
REJN:
            MOV     R5,     A
RN_1:
            MOV     A,      #BEEP_REJ
            ACALL   BEEP
            ACALL   D_60MS
            DJNZ    R5,     RN_1
            RET

D_60MS:
            MOV     R3,     #30
D60_1:      MOV     R2,     #230
D60_2:      DJNZ    R2,     D60_2
            DJNZ    R3,     D60_1
            RET

;=========================================================================
; 串口输出辅助（能看到串口的话，这里会同时打出键值/被拒脉宽）
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
; 常量表与字符串
;=========================================================================
HEXTAB:
            DB  DISP_0, DISP_1, DISP_2, DISP_3, DISP_4, DISP_5
            DB  DISP_6, DISP_7, DISP_8, DISP_9, DISP_A, DISP_B
            DB  DISP_C, DISP_D, DISP_E, DISP_F

MSG_BOOT:
            DB  0DH,0AH,'=== NEC DECODE PROBE (no serial needed) ===',0DH,0AH
            DB  'TAP the key (do not hold), wait 1s after power-up.',0DH,0AH
            DB  '1 short beep = FULL FRAME ok. 7seg then repeats this cycle:',0DH,0AH
            DB  '   [high nibble] 500ms, [low nibble] 500ms, [blank] 500ms',0DH,0AH
            DB  '   e.g. 4 . 6 . (blank) 4 . 6 .  = key code 0x46',0DH,0AH
            DB  '   hex digits A-F are shown as  A b C d E F',0DH,0AH
            DB  'very short tick = repeat frame | 2/3/4 beeps = frame rejected',0DH,0AH
            DB  'silent = no IR edge at all.',0DH,0AH
            DB  'The same data is printed on the serial port as "K=xx".',0DH,0AH
            DB  'Motors stay off (P0 = stop pattern).',0DH,0AH,0
MSG_KEY:
            DB  0DH,0AH,'K=',0
MSG_REJ:
            DB  0DH,0AH,'! rejected, lead lo=',0
MSG_REJ2:
            DB  ' hi=',0
MSG_SL:
            DB  0DH,0AH,'short-leader, data failed, IB=',0
MSG_HB:
            DB  0DH,0AH,'[',0
MSG_IB:
            DB  'IB=',0

            END
