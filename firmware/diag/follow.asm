;=========================================================================
; follow.asm  --  跟随小车：跟着前面的东西走
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name follow
;-------------------------------------------------------------------------
; 探头用的是哪两个脚
;   左探头 V2 -> P3.5（DIP40 第15脚，网标号 P35LC）
;   右探头 V3 -> P3.6（DIP40 第16脚，网标号 P36RC）
;   这两个脚在 docs\引脚表_原理图追线.md 里是 [确定] 级，来历清楚。
;
;   它们是**红外反射式探头**：发射管 + 光敏管。装朝下 = 循迹，
;   装朝前 = 避障/跟随 —— 同一套硬件两种用法（PPT 里"红外循迹"和
;   "红外避障"就是并列的两个功能）。
;   正前方有东西反射回来 -> 光敏管导通 -> 节点被拉低
;   所以：**低电平 = 检测到东西**（config.h 的 TRACK_ACTIVE_LOW=1 同此）
;
; 行为（跟随 + 对准）
;   左有 右有  -> 停（东西已经在跟前了，保持距离）
;   左有 右无  -> 原地左转（东西偏左，转过去对准它）
;   左无 右有  -> 原地右转
;   左无 右无  -> 前进（东西跑远了，追上去）
;
;   ⚠️ 安全：**前方什么都没有的时候它会一直往前追**。
;      所以连续 3 秒完全没检测到东西 -> 自动停车待机（数码管显示 0）。
;      再把东西靠近探头，它会自己恢复。
;
; 数码管 = 探头状态实时显示（这一段是给你验证探头的）
;   "3"  = 两个探头都检测到        -> 停车
;   "2"  = 只有左探头检测到        -> 左转
;   "1"  = 只有右探头检测到        -> 右转
;   灭   = 都没检测到（D3 灯亮）   -> 前进追
;   "0"  = 丢失目标超过 3 秒，安全停车
;
;   D3 灯（P2.0）：亮 = 电机正在动，灭 = 停着
;   -> 把手放到探头前面晃一晃，看数码管数字变不变，就知道探头通不通。
;      数字完全不跳 = 探头没接在这两个脚上（或极性相反），告诉我，我们再做一次
;      "哪个脚有反应"的排查。
;
; 引脚（来自 firmware\car\config.h）
;   P3.5 = V2 左探头   P3.6 = V3 右探头（低 = 检测到）
;   P0.0~P0.3 = L293D INPUT1~4   P0.4/P0.5 = ENA/ENB（高=使能）
;   P2.7~P2.1 = 数码管段选 a~g（共阳：写 0 点亮）   P2.0 = D3 指示灯（写 0 亮）
;=========================================================================

; --- 动作码 ---
ACT_STOP    EQU 00H
ACT_FORWARD EQU 01H
ACT_LEFT    EQU 03H
ACT_RIGHT   EQU 04H

; --- P0 输出图案（b0..b3=IN1..IN4, b4=ENA, b5=ENB, b6=蜂鸣器 1=静音, b7=1）---
PAT_STOP    EQU 0C0H
PAT_FORWARD EQU 0F5H
PAT_LEFT    EQU 0F6H            ; M1 反转 + M2 正转 = 原地左转
PAT_RIGHT   EQU 0F9H            ; M1 正转 + M2 反转 = 原地右转

; --- 数码管图案（共阳，写 0 点亮；bit0 = D3 灯，0 = 亮）---
;   bit7..bit1 = a b c d e f g
DISP_BOTH   EQU 0DH             ; "3"，D3 灭（停车）
DISP_LEFT   EQU 24H             ; "2"，D3 亮（在动）
DISP_RIGHT  EQU 9EH             ; "1"，D3 亮（在动）
DISP_CHASE  EQU 0FEH            ; 段全灭、只要 D3 亮（在追）
DISP_SAFE   EQU 03H             ; "0"，D3 灭（安全停车）

LOST_MAX    EQU 100             ; 连续 100 轮 × 30ms = 3 秒没目标 -> 安全停车

;-------------------------------------------------------------------------
; RAM / 位变量
;-------------------------------------------------------------------------
LOSTCNT     DATA 30H            ; 连续"什么都没检测到"的轮数

F_LEFT      BIT  20H            ; 左探头这一轮的状态（1 = 检测到）
F_RIGHT     BIT  21H            ; 右探头

            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #PAT_STOP
            MOV     P1,     #0FFH
            MOV     P2,     #DISP_SAFE
            MOV     LOSTCNT, #0

;=========================================================================
; 主循环：读探头 -> 决定动作 -> 设电机和数码管 -> 30ms 一轮
;   JNB <脚>, 标号 = 该脚是低就跳（低 = 检测到东西）
;=========================================================================
FOL_LOOP:
            ; ---- 读左探头 P3.5 ----
            CLR     F_LEFT
            JNB     P3.5,   F_LEFT_ON
            SJMP    F_READ_R
F_LEFT_ON:
            SETB    F_LEFT

            ; ---- 读右探头 P3.6 ----
F_READ_R:
            CLR     F_RIGHT
            JNB     P3.6,   F_RIGHT_ON
            SJMP    F_DECIDE
F_RIGHT_ON:
            SETB    F_RIGHT

;-------------------------------------------------------------------------
; 决策
;-------------------------------------------------------------------------
F_DECIDE:
            JNB     F_LEFT,  F_NO_LEFT
            JNB     F_RIGHT, F_TURN_L       ; 左有右无 -> 左转

            ; ---- 两个都有：停 ----
            MOV     LOSTCNT, #0
            MOV     A,      #ACT_STOP
            MOV     P2,     #DISP_BOTH
            SJMP    F_APPLY

F_NO_LEFT:
            JNB     F_RIGHT, F_NONE         ; 都没有 -> 去追
            ; ---- 只有右：右转 ----
            MOV     LOSTCNT, #0
            MOV     A,      #ACT_RIGHT
            MOV     P2,     #DISP_RIGHT
            SJMP    F_APPLY

F_TURN_L:
            MOV     LOSTCNT, #0
            MOV     A,      #ACT_LEFT
            MOV     P2,     #DISP_LEFT
            SJMP    F_APPLY

F_NONE:
            ; ---- 什么都没检测到 ----
            MOV     A,      LOSTCNT
            CJNE    A,      #LOST_MAX, F_CHASE
            ; 丢失太久 -> 安全停车（不再累加，等检测到东西再清零）
            MOV     A,      #ACT_STOP
            MOV     P2,     #DISP_SAFE
            SJMP    F_APPLY

F_CHASE:
            INC     LOSTCNT
            MOV     A,      #ACT_FORWARD
            MOV     P2,     #DISP_CHASE
            SJMP    F_APPLY

;-------------------------------------------------------------------------
; 动作码 -> P0（A = 动作码）
;-------------------------------------------------------------------------
F_APPLY:
            CJNE    A,      #ACT_FORWARD, FA_1
            MOV     P0,     #PAT_FORWARD
            SJMP    F_WAIT
FA_1:       CJNE    A,      #ACT_LEFT,    FA_2
            MOV     P0,     #PAT_LEFT
            SJMP    F_WAIT
FA_2:       CJNE    A,      #ACT_RIGHT,   FA_3
            MOV     P0,     #PAT_RIGHT
            SJMP    F_WAIT
FA_3:       MOV     P0,     #PAT_STOP

F_WAIT:
            ACALL   D_30MS                  ; 30ms 一轮：顺便滤掉探头的毛刺
            SJMP    FOL_LOOP

;=========================================================================
; 延时：D_1MS 用 R1/R2，D_30MS 用 R5
;   机器周期 = 12/11059200 = 1.085us
;=========================================================================
D_1MS:
            MOV     R2,     #2
D1M_1:      MOV     R1,     #230
D1M_2:      DJNZ    R1,     D1M_2
            DJNZ    R2,     D1M_1
            RET

D_30MS:
            MOV     R5,     #30
D30_1:      ACALL   D_1MS
            DJNZ    R5,     D30_1
            RET

            END
