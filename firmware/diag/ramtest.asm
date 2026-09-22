;=========================================================================
; ramtest.asm  --  片内扩展 RAM（MOVX）能不能用 + 访问它会不会打乱 P0/P2
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name ramtest
;-------------------------------------------------------------------------
; 一、为什么必须先测这一条
;   报告要求 240 B 的动作缓冲区。STC89C52RC 有 512 B RAM，但它是这样分的：
;       128 B 直接寻址(DATA) + 128 B 间接寻址(IDATA) + 256 B 片内扩展(MOVX)
;   其中 DATA 的**用户区只有 30H~7F（80 B）**，扣掉运行变量放不下 240 B；
;   IDATA 只有 128 B，也不够。**唯一能整块放下 240 B 的地方，就是那 256 B 扩展 RAM。**
;
;   但它有两个前提从没验证过：
;     (1) 这片芯片的 MOVX 到底能不能读写到那片扩展 RAM
;         （有些 STC 型号要先动 AUXR 的 EXTRAM 位才行）；
;     (2) 访问它的时候，P0/P2 会不会被当成外部总线的地址/数据线而"抖"
;         —— P2 整口是数码管段选、P0 是电机方向和使能：
;         一旦被抖，显示会花，电机还可能抽一下。
;
; 二、三个阶段
;   ① IDATA 0x80~0xFF 读写校验 —— 对照组，这一片是标准 8052 内部 RAM，应该必过
;   ② XRAM 0x0000~0x00FF 读写校验 —— **两个图案各写一遍、各校验一遍**：
;        图案 A = 地址 XOR 55H ；图案 B = 地址 XOR AAH（即每字节取反）
;      只写一遍图案、换个期望值去比对是**测不出东西**的（那样必然全错）——
;      必须"换图案重写一遍"才能发现"存不住 / 地址别名 / 总线上拉造成的假通过"。
;      若两个图案都没过，程序会再试一次 `AUXR = 0`（有的 STC 型号要用它放开 EXTRAM），
;      还不通过才判失败。
;   ③ 显示干扰测试 —— 数码管固定显示 "1"，同时连续 2 秒反复 MOVX 读写整段：
;        "1" 纹丝不动        = 访问扩展 RAM 不碰 P2 -> 缓冲可以放扩展 RAM
;        "1" 变成一片全亮/闪 = P2 被地址线占了   -> 不能这么放，得改方案
;
; 三、最终数码管（同时也打到串口）
;   8 = XRAM 两个图案全过（错误 0）        -> 240 B 缓冲放扩展 RAM
;   7 = 写完 AUXR=0 才过                   -> 也能用，但**正式固件里必须先 `MOV AUXR,#0`**
;   E = XRAM 仍然有错（IDATA 全过）        -> 缓冲缩到 IDATA+DATA（约 60 条），或外挂 I2C EEPROM
;   F = 连 IDATA 都错                      -> 芯片或工具链有问题，先别往下做固件
;
; 四、修订记录
;   2026-09-18 v1：第一次上机报 E。**原因是本程序的 bug**：第 2 遍只换了期望值、
;                 没有重新写图案，于是每一个地址都"比对失败" -> XERR 满 -> 显示 E。
;                 （用户同时报告"那 2 秒里 1 没变形"，说明 MOVX 并没有驱动 P2，
;                  本来就该是通过的。）本版已修正为"两个图案各写一遍各校验一遍"，
;                 并把"第一个出错地址读到的实际值"也打出来，便于判断是总线悬空(FF)
;                 还是存不住。
;
; ⚠️ 安全（重要）
;   第 ③ 阶段如果这片芯片没有片内扩展 RAM，MOVX 就会变成**真·外部总线访问**：
;   P0 会被当数据线驱动，而 P0.0~P0.5 正是 L293D 的方向与使能脚 —— 电机可能抽一下。
;   **做第 ③ 阶段请把小车架起来、让轮子悬空**；只插 USB、不上电池时电机根本没有 VS，
;   更稳妥（本程序也全程不主动驱动电机：P0 初值 = 0C0H 停车图案）。
;=========================================================================

; --- 数码管段码（共阳：写 0 点亮；bit7..bit1 = a b c d e f g；bit0 = D3 灯，1 = 灭）---
DISP_1      EQU     9FH             ; 显示 "1"（只有 b、c 两段亮 —— 被总线驱动时变化最明显）
DISP_7      EQU     1FH
DISP_8      EQU     01H
DISP_E      EQU     61H             ; "E"
DISP_F      EQU     71H             ; "F"

PAT_STOP    EQU     0C0H            ; 电机断电（ENA/ENB 一起拉低）
PAT_A       EQU     55H             ; 图案 A
PAT_B       EQU     0AAH            ; 图案 B
AUXR        EQU     8EH             ; STC 的辅助寄存器（标准 8052 上这是空地址，写它无害）

; --- RAM（直接寻址区 40H 起）---
IERR        DATA    40H             ; IDATA 错误计数（封顶 255）
XERR        DATA    41H             ; XRAM 错误计数（封顶 255）
XHAS        DATA    42H             ; 是否已经记过第一个错误地址
BADH        DATA    43H             ; 第一个出错地址高字节
BADL        DATA    44H             ; 第一个出错地址低字节
BADV        DATA    45H             ; 第一个出错地址"实际读到"的值

            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #PAT_STOP
            MOV     P1,     #0FFH
            MOV     P2,     #DISP_1
            MOV     P3,     #0FFH

            ; ---- 串口 9600 8N1 ----
            MOV     TMOD,   #20H
            MOV     TH1,    #0FDH
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H
            MOV     PCON,   #00H
            SETB    TR1

            MOV     XHAS,   #0
            MOV     BADH,   #0
            MOV     BADL,   #0
            MOV     BADV,   #0

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;=========================================================================
; 阶段 ①：IDATA 0x80~0xFF（对照组，用 @R0 间接寻址）
;=========================================================================
            MOV     R0,     #80H
PI_W:
            MOV     A,      R0
            XRL     A,      #0A5H
            MOV     @R0,    A
            INC     R0
            CJNE    R0,     #00H,   PI_W    ; 从 80H 数到 FFH，回绕到 00H 结束

            MOV     IERR,   #0
            MOV     R0,     #80H
PI_V:
            MOV     A,      R0
            XRL     A,      #0A5H
            XRL     A,      @R0
            JZ      PI_OK
            ACALL   INC_IERR
PI_OK:
            INC     R0
            CJNE    R0,     #00H,   PI_V

            MOV     DPTR,   #MSG_P1
            ACALL   PRINT_STR
            MOV     A,      IERR
            ACALL   PUT_HEX
            ACALL   CRLF

;=========================================================================
; 阶段 ②：XRAM 0x0000~0x00FF（MOVX @DPTR），两个图案各写一遍各校验一遍
;=========================================================================
            MOV     XERR,   #0
            MOV     XHAS,   #0

            ; ---- 图案 A：写 地址 XOR 55H ----
            MOV     DPH,    #00H
            MOV     DPL,    #00H
PX_WA:
            MOV     A,      DPL
            XRL     A,      #PAT_A
            MOVX    @DPTR,  A
            INC     DPTR
            MOV     A,      DPH
            JZ      PX_WA

            MOV     DPH,    #00H
            MOV     DPL,    #00H
PX_VA:
            MOV     A,      DPL
            XRL     A,      #PAT_A
            MOV     R7,     A               ; 期望值
            MOVX    A,      @DPTR
            MOV     R6,     A               ; 实际读到的值（出错时要记下来）
            XRL     A,      R7
            JZ      PX_VAOK
            ACALL   XFAIL
PX_VAOK:
            INC     DPTR
            MOV     A,      DPH
            JZ      PX_VA

            ; ---- 图案 B：**重写**成 地址 XOR AAH，再校验（关键的一步）----
            MOV     DPH,    #00H
            MOV     DPL,    #00H
PX_WB:
            MOV     A,      DPL
            XRL     A,      #PAT_B
            MOVX    @DPTR,  A
            INC     DPTR
            MOV     A,      DPH
            JZ      PX_WB

            MOV     DPH,    #00H
            MOV     DPL,    #00H
PX_VB:
            MOV     A,      DPL
            XRL     A,      #PAT_B
            MOV     R7,     A
            MOVX    A,      @DPTR
            MOV     R6,     A
            XRL     A,      R7
            JZ      PX_VBOK
            ACALL   XFAIL
PX_VBOK:
            INC     DPTR
            MOV     A,      DPH
            JZ      PX_VB

            MOV     DPTR,   #MSG_P2
            ACALL   PRINT_STR
            MOV     A,      XERR
            ACALL   PUT_HEX
            MOV     A,      XHAS
            JZ      PX_NOPRINT
            MOV     DPTR,   #MSG_FIRST
            ACALL   PRINT_STR
            MOV     A,      BADH
            ACALL   PUT_HEX
            MOV     A,      BADL
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_VAL
            ACALL   PRINT_STR
            MOV     A,      BADV
            ACALL   PUT_HEX
PX_NOPRINT:
            ACALL   CRLF

;=========================================================================
; 阶段 ③：显示干扰测试（数码管显示 "1"，同时连续 MOVX 约 2 秒）
;=========================================================================
            MOV     DPTR,   #MSG_P3
            ACALL   PRINT_STR
            MOV     P2,     #DISP_1         ; 这一步之后**不再重写 P2**：
                                            ; 如果 P2 被地址线驱动，显示会当场变样
            MOV     R5,     #10              ; 外层 10 次
PX_P3OUT:
            MOV     R6,     #100             ; 内层 100 遍整段扫描
PX_P3S:
            MOV     DPH,    #00H
            MOV     DPL,    #00H
PX_P3R:
            MOVX    A,      @DPTR
            INC     DPTR
            MOV     A,      DPH
            JZ      PX_P3R
            DJNZ    R6,     PX_P3S
            DJNZ    R5,     PX_P3OUT         ; 10 × 100 × 256 次 MOVX ≈ 2 秒（每字节约 7 个机器周期）

            MOV     DPTR,   #MSG_P3DONE
            ACALL   PRINT_STR

;=========================================================================
; 结论：显示 8 / 7 / E / F
;=========================================================================
            MOV     A,      IERR
            JZ      RM_XCHK
            MOV     DPTR,   #MSG_VF
            ACALL   PRINT_STR
            MOV     P2,     #DISP_F
            LJMP    RM_END

RM_XCHK:
            MOV     A,      XERR
            JZ      RM_ALL8

            ; ---- XRAM 没通过：再试一次 AUXR=0（有的 STC 型号要用它放开 EXTRAM）----
            MOV     DPTR,   #MSG_TRYAUXR
            ACALL   PRINT_STR
            MOV     AUXR,   #00H
            ACALL   XR_AGAIN
            JNC     RM_STILLBAD
            MOV     DPTR,   #MSG_V7
            ACALL   PRINT_STR
            MOV     P2,     #DISP_7
            LJMP    RM_END

RM_STILLBAD:
            MOV     DPTR,   #MSG_VE
            ACALL   PRINT_STR
            MOV     P2,     #DISP_E
            LJMP    RM_END

RM_ALL8:
            MOV     DPTR,   #MSG_V8
            ACALL   PRINT_STR
            MOV     P2,     #DISP_8

RM_END:
            ACALL   CRLF
RM_HOLD:
            ; ---- 结论每 0.5 秒重复打一次：这样抓串口不必卡时间点 ----
            MOV     DPTR,   #MSG_RPT
            ACALL   PRINT_STR
            MOV     A,      IERR
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_XR
            ACALL   PRINT_STR
            MOV     A,      XERR
            ACALL   PUT_HEX
            ACALL   CRLF
            ACALL   D_500MS
            LJMP    RM_HOLD                 ; 结果留在数码管上，不再刷新显示

;-------------------------------------------------------------------------
; XR_AGAIN —— AUXR=0 之后重测一遍图案 A（只测一遍，够判断"是不是 EXTRAM 没放开"）
;   出：C = 1 表示这次全过；XERR 被重置为这次的错误数
;-------------------------------------------------------------------------
XR_AGAIN:
            MOV     XERR,   #0
            MOV     XHAS,   #0
            MOV     DPH,    #00H
            MOV     DPL,    #00H
XRA_W:
            MOV     A,      DPL
            XRL     A,      #PAT_A
            MOVX    @DPTR,  A
            INC     DPTR
            MOV     A,      DPH
            JZ      XRA_W

            MOV     DPH,    #00H
            MOV     DPL,    #00H
XRA_V:
            MOV     A,      DPL
            XRL     A,      #PAT_A
            MOV     R7,     A
            MOVX    A,      @DPTR
            MOV     R6,     A
            XRL     A,      R7
            JZ      XRA_OK
            ACALL   XFAIL
XRA_OK:
            INC     DPTR
            MOV     A,      DPH
            JZ      XRA_V

            MOV     DPTR,   #MSG_P2B
            ACALL   PRINT_STR
            MOV     A,      XERR
            ACALL   PUT_HEX
            ACALL   CRLF

            MOV     A,      XERR
            JZ      XRA_YES
            CLR     C
            RET
XRA_YES:
            SETB    C
            RET

;-------------------------------------------------------------------------
; INC_IERR —— IDATA 错误计数 +1（封顶 FFH，避免回绕成 0 看不懂）
;-------------------------------------------------------------------------
INC_IERR:
            MOV     A,      IERR
            CJNE    A,      #0FFH,  II_GO
            RET
II_GO:
            INC     IERR
            RET

;-------------------------------------------------------------------------
; XFAIL —— XRAM 校验失败：计数 +1、并记下第一个出错地址与"实际读到的值"
;   入口约定：DPH/DPL = 当前地址；R6 = 实际读到的字节（内部会用到 A）
;-------------------------------------------------------------------------
XFAIL:
            MOV     A,      XHAS
            JNZ     XF_CNT
            MOV     XHAS,   #1
            MOV     A,      DPH
            MOV     BADH,   A
            MOV     A,      DPL
            MOV     BADL,   A
            MOV     A,      R6
            MOV     BADV,   A
XF_CNT:
            MOV     A,      XERR
            CJNE    A,      #0FFH,  XF_INC
            RET
XF_INC:
            INC     XERR
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

PUT_HEX:                                ; A -> 两个十六进制字符
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

CRLF:
            MOV     A,      #0DH
            ACALL   PUTCHAR
            MOV     A,      #0AH
            ACALL   PUTCHAR
            RET

;=========================================================================
; 延时（机器周期 = 1.085us）：D_1MS 用 R1/R2，D_2MS 用 R3，D_500MS 用 R5
;   注意：PUT_HEX 用 R2，所以"打印"和"延时"不要互相嵌套（本程序里是先后调用）
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

;=========================================================================
; 字符串（串口用纯 ASCII）
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== ON-CHIP EXTENDED RAM TEST (ramtest v2) ===',0DH,0AH
            DB  'phase1: IDATA 0x80-0xFF  (control group, must pass)',0DH,0AH
            DB  'phase2: XRAM  0x0000-0x00FF, pattern A then pattern B (rewritten)',0DH,0AH
            DB  'phase3: the 7seg shows "1" while MOVX runs flat out for ~2s.',0DH,0AH
            DB  '        "1" must stay a "1". If it turns into an all-lit blob',0DH,0AH
            DB  '        or flickers, P2 is being driven by the bus.',0DH,0AH
            DB  'verdict codes: 8=XRAM ok  7=ok after AUXR=0  E=XRAM bad  F=IDATA bad',0DH,0AH
            DB  '!! LIFT THE CAR SO THE WHEELS SPIN FREE BEFORE PHASE 3 !!',0DH,0AH,0
MSG_P1:
            DB  0DH,0AH,'[1] IDATA 0x80-0xFF : errors = ',0
MSG_P2:
            DB  0DH,0AH,'[2] XRAM  0x0000-0x00FF : errors = ',0
MSG_FIRST:
            DB  '   first bad addr = 0x',0
MSG_VAL:
            DB  '  read = 0x',0
MSG_P3:
            DB  0DH,0AH,'[3] display test running: WATCH THE 7SEG NOW (~2s) ...',0
MSG_P3DONE:
            DB  '  done.',0DH,0AH,0
MSG_TRYAUXR:
            DB  0DH,0AH,'[2b] retrying after AUXR=0 ...',0
MSG_P2B:
            DB  0DH,0AH,'[2b] XRAM pattern A after AUXR=0 : errors = ',0
MSG_V8:
            DB  'verdict: 7seg=8  XRAM usable, 0 errors -> put the 240B buffer in XRAM.',0DH,0AH,0
MSG_V7:
            DB  'verdict: 7seg=7  XRAM usable ONLY after AUXR=0 ->',0DH,0AH
            DB  '         the final firmware MUST do MOV AUXR,#0 before using XRAM.',0DH,0AH,0
MSG_VE:
            DB  'verdict: 7seg=E  XRAM still bad -> shrink the buffer to IDATA+DATA',0DH,0AH
            DB  '         (about 60 units) or use an external I2C EEPROM.',0DH,0AH,0
MSG_VF:
            DB  'verdict: 7seg=F  IDATA is bad too -> chip/toolchain problem, stop here.',0DH,0AH,0
MSG_RPT:
            DB  0DH,0AH,'[hold] IDATA err=',0
MSG_XR:
            DB  '  XRAM err=',0

            END
