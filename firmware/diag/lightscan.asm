;=========================================================================
; lightscan.asm  --  找"寻光 / 光敏"到底接在哪只脚（顺带把用途未定的脚一起扫）
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name lightscan
;-------------------------------------------------------------------------
; 一、为什么需要它
;   《方案设计报告》把"寻光"列为基本功能（左右光敏比较、向光源方向转），
;   但**光敏那一组经 LM393 整形后的输出到底接哪只脚，图纸上只闭合了一路**：
;       P1.1 <- IC3 的 OUTA（光敏比较器 A 通道；追线落在坐标 (3284,1378)）
;   IC3 的 OUTB、以及 P1.6（网标号 P16 -> 传感底板接插件）都还没追到 MCU。
;   而现有程序里**没有一行读过光敏** —— 也就是说这一路"从未上机验证"。
;
;   本程序就是补这个实测：把"用途未定"的脚一起盯着，
;   用手电筒照 / 用手遮住左右光敏，看哪只脚会翻转、往哪个方向翻。
;
; 二、盯着哪 9 只脚（其余脚用途明确，不扫）
;     1=P1.0   2=P1.1   3=P1.4   4=P1.5   5=P1.6   6=P1.7   7=P3.7
;     8=P3.5（已知循迹左探头，当参照）   9=P3.6（已知循迹右探头，当参照）
;
;   不扫 P0     ：电机方向/使能/蜂鸣器都在 P0，本程序全程停车，绝不碰它
;   不扫 P3.0/1 ：串口（TXD 要用来打印）
;   不扫 P3.2/4 ：按键 S4/S3
;   不扫 P3.3   ：红外 0038
;
; 三、怎么读结果（不用串口也能用）
;   数码管数字 = **最后一只发生过变化的脚**（1..9，见上表）；开机时显示 0 = 还没有任何脚动过
;   D3 灯      = **那只脚当前的电平**（亮 = 低电平，灭 = 高电平）—— 每轮都刷新，所以
;                手一盖上/一拿开，D3 会当场跟着变，**直接用它读极性**
;   串口 9600 8N1 每 500ms 打一行 9 只脚的电平快照（"levels 1..9 = 110110011"）
;
;   实测记录（2026-09-18）：
;     盖住**左**光敏 -> 数码管跳 2 -> **P1.1**（图纸追线闭合的 IC3 OUTA，实测盖章）
;     盖住**右**光敏 -> 数码管跳 1 -> **P1.0**（图纸判定"无连线/未使用"，实测是错的！
;                                      再次印证"没找到 != 证明没有"）
;     剩下只差极性：盖住时那只脚是低还是高 —— 看 D3 即可。
;
;   判读例子（数字 = 脚号，D3 = 电平）：
;     盖住左光敏 -> 数码管跳 "2"、D3 亮  -> P1.1 = 低
;     盖住左光敏 -> 数码管跳 "2"、D3 灭  -> P1.1 = 高
;   串口的快照行 "levels 1..9 = 110110011" 按 1..9 顺序给出 9 只脚的电平，
;   可以直接抄进 docs\阶段0实测指南.md 的表格里。
;
; 四、安全
;   * P0 全程 = 0C0H（ENA/ENB 拉低 = 电机断电）：不驱动电机、不响蜂鸣器；
;   * 只**读**这些脚，不往它们写 0（写 1 = 放开 = 输入）；
;   * 写 P2 只用于数码管显示（段选 a~g + D3 灯），别的口不动。
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

PAT_STOP    EQU     0C0H            ; 电机断电（ENA/ENB 一起拉低）

NPINS       EQU     9               ; 候选脚个数

; --- RAM（直接寻址区 40H 起，本程序独立，不与别的程序冲突）---
PREV        DATA    40H             ; 40H..48H：9 只脚上次的电平（0/1）
LID         DATA    49H             ; 最后发生变化的那只脚的槽位（0..8；= NPINS 表示还没有）

            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #PAT_STOP   ; 全程停车
            MOV     P1,     #0FFH       ; 全部放开 = 当输入
            MOV     P2,     #DISP_0
            MOV     P3,     #0FFH

            ; ---- 串口 9600 8N1（Timer1 方式2 做波特率；本程序不用 Timer0）----
            MOV     TMOD,   #20H
            MOV     TH1,    #0FDH       ; 11059200/(384*3) = 9600
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H        ; 方式1，允许接收
            MOV     PCON,   #00H        ; SMOD = 0
            SETB    TR1

            ; ---- PREV 初值取 1（"都当高电平"），这样开机时凡是低的脚会各报一次 ----
            MOV     R0,     #PREV
            MOV     R2,     #NPINS
            MOV     A,      #1
LS_INIT:
            MOV     @R0,    A
            INC     R0
            DJNZ    R2,     LS_INIT
            MOV     LID,    #NPINS          ; 还没有任何脚变过

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;=========================================================================
; 主循环：把 9 只脚逐个读一遍并比较；再每 500ms 打一行快照
;=========================================================================
LS_LOOP:
            MOV     R5,     #0
            MOV     R6,     #DISP_1
            MOV     R7,     #1
            MOV     R4,     #1
            JNB     P1.0,   LS_P1L
            SJMP    LS_P1G
LS_P1L:     MOV     R4,     #0
LS_P1G:     ACALL   CHECKONE

            MOV     R5,     #1
            MOV     R6,     #DISP_2
            MOV     R7,     #2
            MOV     R4,     #1
            JNB     P1.1,   LS_P2L
            SJMP    LS_P2G
LS_P2L:     MOV     R4,     #0
LS_P2G:     ACALL   CHECKONE

            MOV     R5,     #2
            MOV     R6,     #DISP_3
            MOV     R7,     #3
            MOV     R4,     #1
            JNB     P1.4,   LS_P3L
            SJMP    LS_P3G
LS_P3L:     MOV     R4,     #0
LS_P3G:     ACALL   CHECKONE

            MOV     R5,     #3
            MOV     R6,     #DISP_4
            MOV     R7,     #4
            MOV     R4,     #1
            JNB     P1.5,   LS_P4L
            SJMP    LS_P4G
LS_P4L:     MOV     R4,     #0
LS_P4G:     ACALL   CHECKONE

            MOV     R5,     #4
            MOV     R6,     #DISP_5
            MOV     R7,     #5
            MOV     R4,     #1
            JNB     P1.6,   LS_P5L
            SJMP    LS_P5G
LS_P5L:     MOV     R4,     #0
LS_P5G:     ACALL   CHECKONE

            MOV     R5,     #5
            MOV     R6,     #DISP_6
            MOV     R7,     #6
            MOV     R4,     #1
            JNB     P1.7,   LS_P6L
            SJMP    LS_P6G
LS_P6L:     MOV     R4,     #0
LS_P6G:     ACALL   CHECKONE

            MOV     R5,     #6
            MOV     R6,     #DISP_7
            MOV     R7,     #7
            MOV     R4,     #1
            JNB     P3.7,   LS_P7L
            SJMP    LS_P7G
LS_P7L:     MOV     R4,     #0
LS_P7G:     ACALL   CHECKONE

            MOV     R5,     #7
            MOV     R6,     #DISP_8
            MOV     R7,     #8
            MOV     R4,     #1
            JNB     P3.5,   LS_P8L
            SJMP    LS_P8G
LS_P8L:     MOV     R4,     #0
LS_P8G:     ACALL   CHECKONE

            MOV     R5,     #8
            MOV     R6,     #DISP_9
            MOV     R7,     #9
            MOV     R4,     #1
            JNB     P3.6,   LS_P9L
            SJMP    LS_P9G
LS_P9L:     MOV     R4,     #0
LS_P9G:     ACALL   CHECKONE

            ; ---- 显示：最后变过的那只脚（数字），D3 = 它**当前**的电平 ----
            ;      PREV 每轮都被刷新，所以 PREV[LID] 就是那只脚的实时电平；
            ;      D3 每轮重贴一次 -> 手一盖/一拿开，D3 当场跟着变（直接读极性）。
            MOV     A,      LID
            CJNE    A,      #NPINS, LS_HAVE
            MOV     P2,     #DISP_0         ; 还没有任何脚变过
            SJMP    LS_TAIL
LS_HAVE:
            MOV     DPTR,   #DIGTAB
            MOVC    A,      @A+DPTR         ; 槽位 -> 段码
            MOV     R6,     A
            MOV     A,      LID
            ADD     A,      #PREV
            MOV     R0,     A
            MOV     A,      @R0             ; 该脚当前电平
            MOV     C,      ACC.0
            MOV     A,      R6
            MOV     ACC.0,  C
            MOV     P2,     A
LS_TAIL:
            ACALL   SNAP_ALL
            ACALL   D_500MS
            LJMP    LS_LOOP                 ; 主循环在 127 字节以外，必须用 LJMP

;-------------------------------------------------------------------------
; CHECKONE —— 比较一只脚的电平，变了就打印 + 显示
;   入 : R4 = 当前电平(0/1)  R5 = 槽位(0..8)  R6 = 段码  R7 = 脚号(1..9)
;   出 : 无（R0 被用作指针）
;-------------------------------------------------------------------------
CHECKONE:
            MOV     A,      R5
            ADD     A,      #PREV
            MOV     R0,     A
            MOV     A,      @R0             ; 上次电平
            XRL     A,      R4
            JZ      CO_SAME                 ; 没变，什么都不做

            MOV     A,      R4
            MOV     @R0,    A               ; 更新
            MOV     LID,    R5              ; 记住"最后变过的是哪只脚"（显示要用）

            ; ---- 打印 "-> pin id n = x" ----
            MOV     DPTR,   #MSG_CHG
            ACALL   PRINT_STR
            MOV     A,      R7
            ACALL   PUT_DIG
            MOV     DPTR,   #MSG_EQ
            ACALL   PRINT_STR
            MOV     A,      R4
            ADD     A,      #30H
            ACALL   PUTCHAR
            ACALL   CRLF

            ; ---- 显示：段码 + D3 = 该脚电平（低电平 -> D3 亮）----
            MOV     A,      R4
            MOV     C,      ACC.0
            MOV     A,      R6
            MOV     ACC.0,  C
            MOV     P2,     A

CO_SAME:
            RET

;-------------------------------------------------------------------------
; SNAP_ALL —— 打印 9 只脚的电平快照（顺序 1..9）
;-------------------------------------------------------------------------
SNAP_ALL:
            MOV     DPTR,   #MSG_NOW
            ACALL   PRINT_STR
            MOV     R0,     #PREV
            MOV     R2,     #NPINS
SN_1:
            MOV     A,      @R0
            ADD     A,      #30H
            ACALL   PUTCHAR
            INC     R0
            DJNZ    R2,     SN_1
            ACALL   CRLF
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

PUT_DIG:                                ; A = 0..9 -> '0'..'9'
            ADD     A,      #30H
            ACALL   PUTCHAR
            RET

CRLF:
            MOV     A,      #0DH
            ACALL   PUTCHAR
            MOV     A,      #0AH
            ACALL   PUTCHAR
            RET

;=========================================================================
; 延时（机器周期 = 1.085us）
;   D_1MS 用 R1/R2，D_2MS 用 R3，D_500MS 用 R5。
;   R4/R6/R7 是显示与脚号，调用点之外不冲突（D_500MS 在 CHECKONE 之后才调）。
;=========================================================================
D_1MS:
            MOV     R2,     #2
D1M_1:      MOV     R1,     #230
D1M_2:      DJNZ    R1,     D1M_2
            DJNZ    R2,     D1M_1
            RET                             ; 约 930 周期 ≈ 1.01ms

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
; 常量表
;=========================================================================
DIGTAB:                                 ; 槽位 0..8 -> 数字 1..9 的段码
            DB  DISP_1, DISP_2, DISP_3, DISP_4, DISP_5, DISP_6, DISP_7, DISP_8, DISP_9

;=========================================================================
; 字符串（串口用纯 ASCII，避免终端编码问题）
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== LIGHT SENSOR PIN SCAN (lightscan) ===',0DH,0AH
            DB  '7seg digit = id of the pin CHANGED last; D3 lit = that pin is LOW.',0DH,0AH
            DB  'digit 0 = nothing changed for 5s (program is alive).',0DH,0AH
            DB  'id map: 1=P1.0 2=P1.1 3=P1.4 4=P1.5 5=P1.6 6=P1.7 7=P3.7',0DH,0AH
            DB  '        8=P3.5 (track-left ref)  9=P3.6 (track-right ref)',0DH,0AH
            DB  'DO: shade then torch the LEFT and RIGHT LDR, note which id jumps.',0DH,0AH
            DB  'P0 held at stop pattern: motors never driven.',0DH,0AH,0
MSG_CHG:
            DB  0DH,0AH,'-> pin id ',0
MSG_EQ:
            DB  ' = ',0
MSG_NOW:
            DB  0DH,0AH,'levels 1..9 = ',0

            END
