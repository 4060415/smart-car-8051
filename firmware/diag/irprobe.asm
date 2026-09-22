;=========================================================================
; irprobe.asm  --  "我的红外遥控到底活不活？" 专用诊断
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name irprobe
;-------------------------------------------------------------------------
; 一、它回答什么问题
;   遥控器按下去到底有没有反应？—— 不要求是 NEC、不要求校验通过、不需要串口，
;   只要 **0038 接收头有解调输出（P3.3 上有电平活动）** 就会记一次。
;   所以换任何遥控器（NEC / 别的协议）都能用它判断"遥控器 + 接收头 + 接线"这一条链通不通。
;
; 二、怎么读（不用串口）
;   每按一次遥控器（任何键）：
;     数码管计数 +1（显示 1..9、0 循环）   <- 数字在涨 = 收到红外了
;     D3 灯亮起（一直到这次红外活动结束）
;     活动结束（连续 20ms 没有边沿）后蜂鸣器"嘀"一声
;   什么都不动 / 数字不涨 = P3.3 上根本没有红外活动。
;
; 三、判据表
;   数字在涨        -> 遥控器、接收头、接线都是好的（问题在解码或键值上）
;   数字不涨        -> 往下分层查（见 docs\开发工作前置信息.md 那类文档 / 或问开发者）：
;                      ① 手机摄像头对着遥控器发射管按按键，看不到紫白色闪光 -> 遥控器/电池问题
;                      ② 遥控器有闪光但数字不涨 -> 接收头没供电/没接对脚/被遮挡
;                      ③ 环境干扰：阳光直射、白炽灯/荧光灯（含红外成分）会让接收头饱和
;                      ④ 距离/角度：0038 约 ±45°、5~8m 以内，要对着接收头
;
; 四、安全
;   P0 恒为 0C0H（ENA/ENB 拉低 = 电机断电），**不驱动电机**；蜂鸣器只在"嘀"的时候响。
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

PAT_STOP    EQU     0C0H            ; 电机断电
T0_RELOAD   EQU     164             ; 100us tick（方式2 硬件自动重装）
SILENT_TK   EQU     200             ; 连续 200 tick = 20ms 没有边沿 -> 这次活动结束
BEEP_CYC    EQU     12              ; 提示音：12 个 1kHz 周期 ≈ 12ms

; --- RAM ---
COUNT       DATA    30H             ; 收到的红外活动次数（只用来显示 0..9）
SIL         DATA    31H             ; 连续高电平的 tick 计数

IR_IN       BIT     P3.3            ; 0038 输出：空闲高，收到 38kHz 载波为低

            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     COUNT,  #0
            MOV     P0,     #PAT_STOP   ; 全程停车
            MOV     P1,     #0FFH
            MOV     P2,     #DISP_0
            MOV     P3,     #0FFH

            ; ---- 串口 9600 8N1；T0 方式2 只做 100us tick（不用中断，轮询 TF0）----
            MOV     TMOD,   #22H
            MOV     TH1,    #0FDH
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H
            MOV     PCON,   #00H
            SETB    TR1
            MOV     TH0,    #T0_RELOAD
            MOV     TL0,    #T0_RELOAD
            SETB    TR0

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;=========================================================================
; 主循环：等一次"红外活动"
;=========================================================================
MAIN_LOOP:
            ; ---- 1) 等下降沿（一直等，不超时）----
            JB      IR_IN,  MAIN_LOOP

            ; ---- 2) 记一次活动：计数 + 数码管 + D3 亮 ----
            INC     COUNT
            MOV     A,      COUNT
            CJNE    A,      #10,    M_CNT_OK
            MOV     COUNT,  #0          ; 0..9 循环
            MOV     A,      COUNT
M_CNT_OK:
            MOV     DPTR,   #DIGTAB
            MOVC    A,      @A+DPTR
            CLR     ACC.0               ; D3 亮
            MOV     P2,     A

            MOV     DPTR,   #MSG_HIT
            ACALL   PRINT_STR
            MOV     A,      COUNT
            ADD     A,      #30H
            ACALL   PUTCHAR

            ; ---- 3) 等这次活动结束：连续 20ms 没有边沿 ----
            MOV     SIL,    #SILENT_TK
M_WAIT:
            ACALL   D_TICK              ; 等 100us
            JB      IR_IN,  M_HIGH
            MOV     SIL,    #SILENT_TK  ; 又出现边沿 -> 重新计时
            SJMP    M_WAIT
M_HIGH:
            DEC     SIL
            MOV     A,      SIL
            JNZ     M_WAIT

            ; ---- 4) 活动结束：D3 灭 + 一声"嘀" ----
            MOV     A,      COUNT
            MOV     DPTR,   #DIGTAB
            MOVC    A,      @A+DPTR
            MOV     P2,     A           ; 段码 bit0 = 1 -> D3 灭
            ACALL   BEEP_SHORT
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
            SJMP    MAIN_LOOP

;=========================================================================
; D_TICK —— 等一个 100us tick（轮询 TF0；方式2 要软件清标志）
;=========================================================================
D_TICK:
            CLR     TF0
            JNB     TF0,    $
            CLR     TF0
            RET

;=========================================================================
; BEEP_SHORT —— 阻塞式短鸣（诊断程序不需要非阻塞；P0.6 低 = 响）
;   P0 其余位保持停车图案：只动 P0.6，用的是位操作，不会碰方向/使能。
;=========================================================================
BEEP_SHORT:
            MOV     R3,     #BEEP_CYC
BS_LOOP:
            CLR     P0.6                ; 导通 -> 响
            ACALL   D_500US
            SETB    P0.6                ; 截止 -> 停
            ACALL   D_500US
            DJNZ    R3,     BS_LOOP
            RET

; 约 500us 的延时（粗算：机器周期 1.085us）
D_500US:
            MOV     R4,     #230
DS_1:       DJNZ    R4,     DS_1
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

;=========================================================================
; 常量表与字符串
;=========================================================================
DIGTAB:
            DB  DISP_0, DISP_1, DISP_2, DISP_3, DISP_4
            DB  DISP_5, DISP_6, DISP_7, DISP_8, DISP_9

MSG_BOOT:
            DB  0DH,0AH,'=== IR ACTIVITY PROBE (jumper-free, protocol-free) ===',0DH,0AH
            DB  'Press ANY remote key. 7seg counter must go up, D3 lights,',0DH,0AH
            DB  'then a short beep when the burst ends.',0DH,0AH
            DB  'counter not moving = no IR activity reaches P3.3 at all.',0DH,0AH
            DB  'Motors stay off (P0 = stop pattern).',0DH,0AH,0
MSG_HIT:
            DB  0DH,0AH,'IR activity #',0
MSG_CRLF:
            DB  0DH,0AH,0

            END
