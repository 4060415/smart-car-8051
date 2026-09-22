;=========================================================================
; tracktest.asm  --  循迹/避障探头（P3.5 / P3.6 / P3.7）实测：极性 + 稳定性
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name tracktest
;-------------------------------------------------------------------------
; 一、为什么需要它
;   报告要"黑线循迹"，而循迹算法的判断方向完全取决于一件事：
;   **探头照到黑线时，节点到底是低电平还是高电平**（极性）。
;   这件事在现有工程里**从来没有实测过** —— config.h 里只写了
;   TRACK_ACTIVE_LOW = 1（"节点低 = 触发"），但"黑线算触发还是白底算触发"没量过，
;   而且从原理图追线看，P3.5/P3.6 上是"光敏管 + 220Ω/15K 分压"的**直接节点**，
;   网的范围够不到 IC5（比较器），也就是说**没有经过比较器整形**。
;   直接节点有可能停在中间电平上 —— 那就需要知道它到底稳不稳。
;
;   本程序一次同时回答两个问题：极性 + 稳不稳。
;
; 二、盯着哪三只脚
;     L = P3.5（网标号 P35LC，左探头，图上带指示灯 D5）
;     R = P3.6（网标号 P36RC，右探头，图上带指示灯 D6）
;     C = P3.7（网标号 P37ZC，7 脚循迹接插件的"中"；目前没追到传感器）
;   低电平 = 检测到反射光（config.h 的 TRACK_ACTIVE_LOW=1 同此），本程序就是去验它。
;
; 三、怎么读结果（不用串口也能用）
;   数码管数字 = L + 2×R + 4×C 的二进制和，**某一位为 1 = 那只脚是低电平**：
;     0 = 三个都高（都没检测到）
;     1 = 只有 L 低        2 = 只有 R 低       3 = L、R 都低
;     4 = 只有 C 低        5 = L、C 低        6 = R、C 低        7 = 三个都低
;   D3 灯 = **采样期间电平不稳定**（亮 = 有抖动，可能是中间电平 / 正好压在翻转边界）
;
;   串口 9600 8N1 每 500ms 打一行，带每只脚的抖动情况：
;     L=0 R=1 C=1  -> digit 1        L 后面的 * 表示这只脚在采样窗口里跳过
;
;   操作：把小车架起来或拿在手里，用**白纸**和**黑胶带**分别在朝下的探头下面过一遍，
;         再把挡板放到朝前的探头前面。看数字怎么变、D3 亮不亮。
;   要记录下来的是：**黑线时 L/R = 0 还是 1**；**白底时 L/R = 0 还是 1**；D3 是否常亮。
;
; 四、安全
;   * **完全不驱动电机**：P0 全程 = 0C0H（ENA/ENB 拉低 = 断电）；
;   * 只**读** P3.5/P3.6/P3.7，从不往它们写 0；
;   * 写 P2 只用于数码管与 D3；P1 全程不碰（保持放开）。
;   * 与 follow.asm 的区别：follow.asm 会驱动电机追着东西跑，这个只显示状态、车不动，
;     适合放在桌面上做极性标定。
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

PAT_STOP    EQU     0C0H            ; 电机断电（ENA/ENB 一起拉低）
NSAMP       EQU     64              ; 每只脚每次采样的次数（看它稳不稳）

; --- RAM（直接寻址区 40H 起）---
LV_L        DATA    40H             ; 左探头电平 0/1
LV_R        DATA    41H             ; 右探头电平 0/1
LV_C        DATA    42H             ; 中探头电平 0/1
NZ_L        DATA    43H             ; 左探头采样抖动次数（非 0 = 不稳定）
NZ_R        DATA    44H
NZ_C        DATA    45H

            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #PAT_STOP   ; 全程停车
            MOV     P1,     #0FFH
            MOV     P2,     #DISP_0
            MOV     P3,     #0FFH

            ; ---- 串口 9600 8N1 ----
            MOV     TMOD,   #20H
            MOV     TH1,    #0FDH
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H
            MOV     PCON,   #00H
            SETB    TR1

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

TT_LOOP:
            ; ---- 采样三次：P3.5 / P3.6 / P3.7 ----
            MOV     R6,     #20H
            ACALL   SAMPLE
            MOV     LV_L,   R4
            MOV     NZ_L,   R7

            MOV     R6,     #40H
            ACALL   SAMPLE
            MOV     LV_R,   R4
            MOV     NZ_R,   R7

            MOV     R6,     #80H
            ACALL   SAMPLE
            MOV     LV_C,   R4
            MOV     NZ_C,   R7

            ; ---- 组装数字：L + 2R + 4C（某位为 1 = 那只脚低电平）----
            MOV     R3,     #0
            MOV     A,      LV_L
            JNZ     TT_N1
            MOV     R3,     #1
TT_N1:
            MOV     A,      LV_R
            JNZ     TT_N2
            MOV     A,      R3
            ORL     A,      #2
            MOV     R3,     A
TT_N2:
            MOV     A,      LV_C
            JNZ     TT_N3
            MOV     A,      R3
            ORL     A,      #4
            MOV     R3,     A
TT_N3:
            ; ---- 数字 -> 段码 ----
            MOV     A,      R3
            MOV     DPTR,   #DIGTAB
            MOVC    A,      @A+DPTR
            MOV     R6,     A

            ; ---- D3：有抖动就亮（bit0 = 0）----
            MOV     A,      NZ_L
            ORL     A,      NZ_R
            ORL     A,      NZ_C
            JZ      TT_QUIET
            MOV     A,      R6
            CLR     ACC.0
            SJMP    TT_SET
TT_QUIET:
            MOV     A,      R6
            SETB    ACC.0
TT_SET:
            MOV     P2,     A

            ; ---- 串口打一行：L=x R=x C=x  -> digit n ----
            ACALL   CRLF
            MOV     A,      #4CH            ; 'L'
            MOV     R4,     LV_L
            MOV     R7,     NZ_L
            ACALL   PRT_ONE
            MOV     A,      #20H            ; ' '
            ACALL   PUTCHAR
            MOV     A,      #52H            ; 'R'
            MOV     R4,     LV_R
            MOV     R7,     NZ_R
            ACALL   PRT_ONE
            MOV     A,      #20H
            ACALL   PUTCHAR
            MOV     A,      #43H            ; 'C'
            MOV     R4,     LV_C
            MOV     R7,     NZ_C
            ACALL   PRT_ONE

            MOV     DPTR,   #MSG_DIG
            ACALL   PRINT_STR
            MOV     A,      R3
            ADD     A,      #30H
            ACALL   PUTCHAR
            MOV     A,      NZ_L
            ORL     A,      NZ_R
            ORL     A,      NZ_C
            JZ      TT_TAIL
            MOV     DPTR,   #MSG_NOISY
            ACALL   PRINT_STR
TT_TAIL:
            ACALL   D_500MS                 ; 注意：D_2MS 会用 R3，R3 已经用完了
            LJMP    TT_LOOP

;-------------------------------------------------------------------------
; SAMPLE —— 采样一只脚 NSAMP 次，给出最终电平与抖动次数
;   入 : R6 = 位掩码（20H / 40H / 80H）   出 : R4 = 电平(0/1)、R7 = 抖动次数
;   用 P3 一次读一位：剩下的位都被掩码 AND 掉，所以别的脚不影响判定。
;-------------------------------------------------------------------------
SAMPLE:
            MOV     R7,     #0
            MOV     R2,     #NSAMP
            MOV     A,      P3
            ANL     A,      R6
            MOV     R4,     A               ; 第一次样本作为基准
SM_1:
            MOV     A,      P3
            ANL     A,      R6
            XRL     A,      R4
            JZ      SM_2
            INC     R7                      ; 与基准不一致 -> 记一次抖动
SM_2:
            DJNZ    R2,     SM_1
            MOV     A,      R4
            JZ      SM_LOW
            MOV     R4,     #1
            RET
SM_LOW:
            MOV     R4,     #0
            RET

;-------------------------------------------------------------------------
; PRT_ONE —— 打印一只脚："L=0" 或 "R=1*"（有抖动就加一个 *）
;   入 : A = 标签字符、R4 = 电平、R7 = 抖动次数
;-------------------------------------------------------------------------
PRT_ONE:
            ACALL   PUTCHAR                 ; 标签
            MOV     A,      #3DH            ; '='
            ACALL   PUTCHAR
            MOV     A,      R4
            ADD     A,      #30H
            ACALL   PUTCHAR
            MOV     A,      R7
            JZ      PO_DONE
            MOV     A,      #2AH            ; '*'
            ACALL   PUTCHAR
PO_DONE:
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

CRLF:
            MOV     A,      #0DH
            ACALL   PUTCHAR
            MOV     A,      #0AH
            ACALL   PUTCHAR
            RET

;=========================================================================
; 延时（机器周期 = 1.085us）：D_1MS 用 R1/R2，D_2MS 用 R3，D_500MS 用 R5
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
DIGTAB:
            DB  DISP_0, DISP_1, DISP_2, DISP_3, DISP_4, DISP_5, DISP_6, DISP_7

;=========================================================================
; 字符串（串口用纯 ASCII）
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== TRACK / AVOID PROBE TEST (tracktest) ===',0DH,0AH
            DB  'probes: L=P3.5 (P35LC)  R=P3.6 (P36RC)  C=P3.7 (P37ZC)',0DH,0AH
            DB  'low level = reflection detected (this is what we are verifying).',0DH,0AH
            DB  '7seg digit = L + 2*R + 4*C   (bit set = that pin is LOW)',0DH,0AH
            DB  '  0=none  1=only L  2=only R  3=L+R  4=only C  5=L+C  6=R+C  7=all',0DH,0AH
            DB  'D3 lit = a probe was UNSTABLE during sampling (mid level/chatter).',0DH,0AH
            DB  'DO: pass WHITE PAPER then BLACK TAPE under the downward probes;',0DH,0AH
            DB  '    put a board in front of the forward-facing probes.',0DH,0AH
            DB  'RECORD: level of L/R on black line, on white, and whether D3 is lit.',0DH,0AH
            DB  'Motors are never driven (P0 = stop pattern).',0DH,0AH,0
MSG_DIG:
            DB  '  -> digit ',0
MSG_NOISY:
            DB  '  [UNSTABLE]',0

            END
