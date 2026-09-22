;=========================================================================
; remote.asm  --  智能移动机器人「红外遥控小车」简单版
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1
; 串口输出 : P3.1(TXD) -> CH340 -> COM7，9600 8N1（每收到一个新键打印一行）
;-------------------------------------------------------------------------
; 与 selftest.asm / modtest.asm 的关键区别
;   1) 红外守在 **P3.3**（0038 的真实连接脚 = INT1 = DIP40 第 13 脚）。
;      selftest/modtest 里守的 P3.2 是错的：P3.2 接的是按键 S4。
;   2) 真的驱动电机：5 个功能键 -> 前进 / 后退 / 左转 / 右转 / 停。
;   3) 用 Timer0 方式2 建 100us 系统时基（T0_RELOAD=164，与 car\config.h 一致），
;      红外脉宽和"松键停车"超时都拿它计时，不靠软件延时猜时间。
;
; 遥控器键值（cmd 字节，来自遥控器码值表）
;   前进 46H   后退 15H   左转 44H   右转 43H   暂停 40H
;   收到别的键也照样把键码打出来，方便对照、方便补表。
;
; 工作方式（HOLD_MODE 切换）
;   1 = 松键停车：按住键就一直动（靠 NEC 重复码刷新），松开约 0.3s 自动停
;   0 = 锁定式  ：按一下就一直动，直到按 暂停 或按另一个方向键
;   如果按住键时小车一顿一顿的，说明这只遥控器**不发** NEC 重复码，
;   把 HOLD_MODE 改成 0 重编即可。
;
; 安全
;   * 上电默认停车，开机不动；
;   * 解码异常（引导码不对 / 脉宽超时 / 校验不过）一律当没收到，不动电机；
;   * 不认识的键只打印，不改变运动状态（避免误码让车乱动或突然停）；
;   * 测试时把小车架起来，让轮子悬空。
;
; 引脚（来自 firmware\car\config.h，原理图矢量追线结论，不是看图猜的）
;   P0.0~P0.3 = L293D INPUT1~4      P0.4 / P0.5 = ENA / ENB（高=使能）
;   P0.6 = 蜂鸣器（S8550 PNP 驱动：低电平导通；无源，要给方波才出声）
;   P3.3 = 0038 红外输出            P3.1 = TXD（调试用）
;   P0 是开漏口：写 1 只是"放开"，靠板上 10K 排阻拉高 -> 上升沿偏慢。
;   本程序只做低速开关，不做 PWM。
;
; 电机方向（[中等] 置信度：图纸只给了位号 M1/M2，没说哪个是左轮）
;   若发现左转/右转方向相反，把 PAT_LEFT 和 PAT_RIGHT 对调即可。
;=========================================================================

;-------------------------------------------------------------------------
; 一、常量
;-------------------------------------------------------------------------
; --- 时间基准：Timer0 方式2，256-164 = 92 机器周期 = 99.8us（记作 1 tick）---
T0_RELOAD   EQU 164
HOLD_TMO    EQU 3000            ; 松键停车超时 3000 tick = 300ms
HOLD_TMO_H  EQU 11              ; 3000 = 0BB8H
HOLD_TMO_L  EQU 184

; --- NEC 解码门限（单位 tick = 100us）---
IR_LEAD_MIN EQU 70              ; 引导码低电平 9ms -> 70~120 都收
IR_LEAD_MAX EQU 120
IR_LEADHCAP EQU 60              ; 引导码高电平量到 6ms 就收手（完整帧 4.5ms 会先变低）
IR_LEADH_MIN EQU 25             ; 完整帧的引导码高电平至少 2.5ms，短于此判为噪声
IR_BIT_TH   EQU 11              ; 位高电平 >= 1.1ms -> 位1（位0=0.56ms 位1=1.69ms）
IR_BITCAP   EQU 12              ; 最后一位：只量到 1.2ms 就下结论（后面是空闲高电平）

; --- "帧被拒"提示的限流：2000 tick = 200ms 最多报一行，避免刷屏 ---
ERRTMO_H    EQU 7               ; 2000 = 07D0H
ERRTMO_L    EQU 208

; --- 开机默认工作方式 ---
HOLD_MODE   EQU 1               ; 1=松键停车  0=锁定式

; --- 遥控器键值（cmd 字节，用户提供）---
KEY_FORWARD EQU 46H
KEY_BACK    EQU 15H
KEY_LEFT    EQU 44H
KEY_RIGHT   EQU 43H
KEY_STOP    EQU 40H

; --- 动作码（与 car\config.h 的报告定义一致）---
ACT_STOP    EQU 00H
ACT_FORWARD EQU 01H
ACT_BACK    EQU 02H
ACT_LEFT    EQU 03H
ACT_RIGHT   EQU 04H
ACT_NONE    EQU 0FFH

; --- P0 输出图案 ---
;   b0..b3 = IN1..IN4   b4 = ENA   b5 = ENB   b6 = 蜂鸣器(1=静音)   b7 = 1(不用)
;   停车时把 ENA/ENB 一起拉低 = 电机完全断电（滑行），比"刹车"更省电更安全。
PAT_STOP    EQU 0C0H
PAT_FORWARD EQU 0F5H            ; IN1 + IN3 -> M1、M2 同向
PAT_BACK    EQU 0FAH            ; IN2 + IN4
PAT_LEFT    EQU 0F6H            ; M1 反转 + M2 正转 -> 原地左转
PAT_RIGHT   EQU 0F9H            ; M1 正转 + M2 反转 -> 原地右转

BEEP_CYCLES EQU 12              ; 按键提示音：12 个 1kHz 周期 ≈ 12ms
LASTCMD_NONE EQU 0FFH           ; 不可能出现的键值，用来表示"还没收过键"

;-------------------------------------------------------------------------
; 二、RAM 变量（数据区 30H 起）
;-------------------------------------------------------------------------
TICK_L      DATA 30H            ; 系统时基低字节（100us，中断里维护）
TICK_H      DATA 31H            ; 系统时基高字节（65536 tick 溢出 = 6.55s）
STR_H       DATA 32H            ; MEAS_LEVEL 的起始时刻
STR_L       DATA 33H
DUR_H       DATA 34H            ; MEAS_LEVEL 的结果（tick）
DUR_L       DATA 35H
CAP_L       DATA 36H            ; 量脉宽的限时；0 = 用默认 25.6ms 超时
MLVL        DATA 37H            ; 要量的电平：0=低 1=高
BITS        DATA 38H            ; 剩余位数
PTRIDX      DATA 39H            ; 当前字节序号 0..3
MASKB       DATA 3AH            ; 当前位掩码
IB0         DATA 3BH            ; addr
IB1         DATA 3CH            ; ~addr
IB2         DATA 3DH            ; cmd      <- 这就是键值
IB3         DATA 3EH            ; ~cmd
IRSTAT      DATA 3FH            ; 0=完整帧 1=没等到边沿 2=帧被拒 3=重复帧
LASTCMD     DATA 40H            ; 上次处理过的键值
CURACT      DATA 41H            ; 当前动作码
LASTT_H     DATA 42H            ; 最后一次收到红外帧的时刻
LASTT_L     DATA 43H
MOTPAT      DATA 44H            ; 当前 P0 输出图案（蜂鸣器位保持 1=静音）
LEDLO       DATA 45H            ; 诊断：最近量到的引导码低电平（tick，1=100us）
LEDHI       DATA 46H            ; 诊断：最近量到的引导码高电平
LASTERR_H   DATA 47H            ; 上次打印"帧被拒"的时刻（限流用）
LASTERR_L   DATA 48H

;-------------------------------------------------------------------------
; 三、中断向量
;-------------------------------------------------------------------------
            ORG     0000H
            LJMP    MAIN

            ORG     000BH           ; Timer0 中断：只做一件事 = 累加 100us 时基
            LJMP    T0_ISR

;=========================================================================
; 主程序
;=========================================================================
            ORG     0030H
MAIN:
            MOV     SP,     #60H

            ; ---- 上电先停车，并且把蜂鸣器关掉 ----
            MOV     MOTPAT, #PAT_STOP
            MOV     P0,     #PAT_STOP   ; 写整个字节：电机全关 + 蜂鸣器静音
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH

            MOV     CURACT, #ACT_STOP
            MOV     LASTCMD, #LASTCMD_NONE
            MOV     IRSTAT, #1
            ; 单片机内部 RAM 上电是不确定的，凡是被"读"过的变量都要显式清零，
            ; 否则第一次比较可能拿着随机值（尤其这几个是 16 位时刻：不清零
            ; 就可能算出个巨大的 delta，一开机就误判超时）。
            MOV     TICK_L, #0
            MOV     TICK_H, #0
            MOV     LASTT_H, #0
            MOV     LASTT_L, #0
            MOV     LASTERR_H, #0
            MOV     LASTERR_L, #0

            ; ---- 串口 9600 8N1（Timer1 方式2）----
            ;      TMOD 高半字节管 T1，低半字节管 T0
            MOV     TMOD,   #22H        ; T1 方式2(波特率) + T0 方式2(100us 时基)
            MOV     TH1,    #0FDH       ; 11059200/(384*3) = 9600
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H        ; 方式1，允许接收
            MOV     PCON,   #00H        ; SMOD = 0
            SETB    TR1

            ; ---- 系统时基：先装重装值再开中断，避免第一个周期乱掉 ----
            MOV     TH0,    #T0_RELOAD
            MOV     TL0,    #T0_RELOAD
            SETB    TR0
            SETB    ET0
            SETB    EA

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;=========================================================================
; 主循环：收一帧红外 -> 处理 -> 检查松键停车 -> 再来
;   最坏一轮约 25.6ms（没信号时等边沿的超时），所以停车超时的
;   判定粒度约 26ms，对 300ms 的门限完全够用。
;=========================================================================
LOOP:
            ACALL   IR_RECV             ; 收一帧
            MOV     A,     IRSTAT
            JZ      L_FULL              ; 0 = 完整帧
            CJNE    A,     #3,      L_NOTRPT
            ; ---- 3 = 重复帧：只刷新时刻（这就是"还按着"的凭据）----
            ACALL   STAMP_NOW
            SJMP    LOOP_CHK
L_NOTRPT:
            CJNE    A,     #2,      LOOP_CHK   ; 1 = 没信号，静默
            ; ---- 2 = 见到边沿但没解成 NEC 帧：限流报一行，带实测脉宽 ----
            ;      这是给"红外链路从没上机测过"准备的诊断：
            ;      按遥控器如果只冒出这行，就看 lo/hi 两个数——
            ;      NEC 应该是 lo≈90、hi≈45（重复帧 hi≈22），单位 100us。
            ACALL   TICK_GET
            MOV     A,     R5
            CLR     C
            SUBB    A,     LASTERR_L
            MOV     R6,     A
            MOV     A,     R4
            SUBB    A,     LASTERR_H
            MOV     R7,     A            ; R7:R6 = 距上次报错过了多久
            MOV     A,     R7
            CLR     C
            SUBB    A,     #ERRTMO_H
            JC      LOOP_CHK            ; 还没到 200ms -> 不重复刷屏
            JNZ     L_ERRPR
            MOV     A,     R6
            CLR     C
            SUBB    A,     #ERRTMO_L
            JC      LOOP_CHK
L_ERRPR:
            MOV     LASTERR_H, R4
            MOV     LASTERR_L, R5
            MOV     DPTR,   #MSG_IRERR
            ACALL   PRINT_STR
            MOV     A,     LEDLO
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_IRERR2
            ACALL   PRINT_STR
            MOV     A,     LEDHI
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_CRLF
            ACALL   PRINT_STR
            SJMP    LOOP_CHK

L_FULL:
            ACALL   STAMP_NOW
            MOV     A,     IB2
            CJNE    A,     LASTCMD, L_NEWKEY
            SJMP    LOOP_CHK            ; 同一个键的重复帧，不重复打印/动作
L_NEWKEY:
            MOV     LASTCMD, A
            ACALL   REPORT_KEY

;-------------------------------------------------------------------------
; 松键停车（HOLD_MODE=1 才编进来）
;-------------------------------------------------------------------------
LOOP_CHK:
    IF HOLD_MODE
            MOV     A,     CURACT
            JZ      LOOP                ; 本来就在停 -> 不用管
            ACALL   TICK_GET            ; R4:R5 = 现在
            MOV     A,     R5
            CLR     C
            SUBB    A,     LASTT_L
            MOV     R6,    A
            MOV     A,     R4
            SUBB    A,     LASTT_H
            MOV     R7,    A            ; R7:R6 = 距上次收帧的 tick 数
            MOV     A,     R7           ; 跟 3000 (0BB8H) 比
            CLR     C
            SUBB    A,     #HOLD_TMO_H
            JC      LOOP                ; 高字节更小 -> 还没到
            JNZ     L_TIMEOUT           ; 高字节更大 -> 超了
            MOV     A,     R6
            CLR     C
            SUBB    A,     #HOLD_TMO_L
            JC      LOOP
L_TIMEOUT:
            MOV     CURACT, #ACT_STOP
            ACALL   MOTOR_SET_ACT       ; 停车
            MOV     LASTCMD, #LASTCMD_NONE   ; 允许同一个键再按一次
            MOV     DPTR,   #MSG_RELEASE
            ACALL   PRINT_STR
    ENDIF
            SJMP    LOOP

;=========================================================================
; REPORT_KEY：处理一个"新键"（打印 + 查表 + 动作 + 提示音）
;   入口：IB2 = 键值
;=========================================================================
REPORT_KEY:
            MOV     DPTR,   #MSG_KEY    ; "K="
            ACALL   PRINT_STR
            MOV     A,     IB2
            ACALL   PUT_HEX             ; 键值原始字节

            MOV     A,     IB2
            ACALL   KEY2ACT             ; A = 动作码
            CJNE    A,     #ACT_NONE, RK_KNOWN
            MOV     DPTR,   #MSG_UNK    ; 不认识的键：只打印，不动
            ACALL   PRINT_STR
            RET

RK_KNOWN:
            MOV     CURACT, A
            ACALL   MOTOR_SET_ACT       ; 立刻动作
            ACALL   PRT_ACTNAME
            ACALL   BEEP_SHORT          ; 响一声，不用看串口也知道收到了
            RET

;=========================================================================
; KEY2ACT：键值 -> 动作码（A 进 A 出）
;=========================================================================
KEY2ACT:
            CJNE    A,     #KEY_FORWARD, K2A_1
            MOV     A,     #ACT_FORWARD
            RET
K2A_1:      CJNE    A,     #KEY_BACK,  K2A_2
            MOV     A,     #ACT_BACK
            RET
K2A_2:      CJNE    A,     #KEY_LEFT,  K2A_3
            MOV     A,     #ACT_LEFT
            RET
K2A_3:      CJNE    A,     #KEY_RIGHT, K2A_4
            MOV     A,     #ACT_RIGHT
            RET
K2A_4:      CJNE    A,     #KEY_STOP,  K2A_NONE
            MOV     A,     #ACT_STOP
            RET
K2A_NONE:
            MOV     A,     #ACT_NONE
            RET

;=========================================================================
; MOTOR_SET_ACT：动作码 -> P0 输出图案（A = 动作码）
;=========================================================================
MOTOR_SET_ACT:
            CJNE    A,     #ACT_FORWARD, MSA_1
            MOV     MOTPAT, #PAT_FORWARD
            SJMP    MSA_DO
MSA_1:      CJNE    A,     #ACT_BACK,  MSA_2
            MOV     MOTPAT, #PAT_BACK
            SJMP    MSA_DO
MSA_2:      CJNE    A,     #ACT_LEFT,  MSA_3
            MOV     MOTPAT, #PAT_LEFT
            SJMP    MSA_DO
MSA_3:      CJNE    A,     #ACT_RIGHT, MSA_4
            MOV     MOTPAT, #PAT_RIGHT
            SJMP    MSA_DO
MSA_4:      MOV     MOTPAT, #PAT_STOP  ; ACT_STOP 及任何意外值都当停车
MSA_DO:
            MOV     P0,     MOTPAT
            RET

;=========================================================================
; PRT_ACTNAME：把当前动作名打到串口（CURACT）
;=========================================================================
PRT_ACTNAME:
            MOV     A,     CURACT
            CJNE    A,     #ACT_FORWARD, PAN_1
            MOV     DPTR,   #MSG_FWD
            SJMP    PAN_PR
PAN_1:      CJNE    A,     #ACT_BACK,  PAN_2
            MOV     DPTR,   #MSG_BCK
            SJMP    PAN_PR
PAN_2:      CJNE    A,     #ACT_LEFT,  PAN_3
            MOV     DPTR,   #MSG_LFT
            SJMP    PAN_PR
PAN_3:      CJNE    A,     #ACT_RIGHT, PAN_4
            MOV     DPTR,   #MSG_RGT
            SJMP    PAN_PR
PAN_4:      MOV     DPTR,   #MSG_STP
PAN_PR:
            ACALL   PRINT_STR
            RET

;=========================================================================
; BEEP_SHORT：短鸣一声（无源蜂鸣器要靠方波才出声：
;   P0.6 拉低 500us -> S8550 导通 -> 拉高 500us -> 截止，交替 12 次 ≈ 1kHz、12ms）
;   注意：MOTPAT 的蜂鸣器位是 1（静音），清掉那一位就是响。
;   鸣叫期间不守红外，所以只给 12ms，不会错过 NEC 的重复码（每 108ms 一帧）。
;   只用 R7，不碰延时子程序要用的 R0~R3。
;=========================================================================
BEEP_SHORT:
            MOV     R7,     #BEEP_CYCLES
BS_LOOP:
            MOV     A,     MOTPAT
            ANL     A,     #0BFH        ; b6=0 -> S8550 导通 -> 响
            MOV     P0,     A
            ACALL   D_500US
            MOV     P0,     MOTPAT      ; b6=1 -> 静音
            ACALL   D_500US
            DJNZ    R7,     BS_LOOP
            RET

;=========================================================================
; IR_RECV：尝试接收一帧 NEC 红外（轮询 P3.3）
;   出口：IRSTAT = 0 完整帧（IB2 = 键值）
;                  1 连下降沿都没等到（静默）
;                  2 见到边沿了，但没解成 NEC 帧（主循环报实测脉宽）
;                  3 重复帧（只表示"还按着"）
;   另外把量到的引导码脉宽留在 LEDLO/LEDHI 里，给主循环做诊断用。
;=========================================================================
IR_RECV:
            MOV     CAP_L,  #0
            MOV     LEDLO,  #0          ; 诊断用：先清掉上次量到的引导码脉宽
            MOV     LEDHI,  #0
            MOV     IRSTAT, #1          ; 先当"连下降沿都没等到"
            SJMP    IR_START

; ---- 两个失败出口 ----
;      为什么放这儿：Jxx 只有 +/-128 字节射程，函数末尾的 IR_BAD 离
;      引导码检查太远跳不过去，所以在靠近的地方再开两个出口。
IR_SILENT:
            RET                         ; 连边沿都没有：保持 IRSTAT=1，静默

IR_REJECT:
            MOV     IRSTAT, #2          ; 见到边沿但引导码不像 NEC：报实测脉宽
            RET

IR_START:
            ; ---- 1) 等 P3.3 下降沿（超时约 25.6ms）----
            ACALL   TICK_GET
            MOV     STR_H, R4
            MOV     STR_L, R5
IRW_EDGE:
            JNB     P3.3,   IR_EDGE     ; 已经变低 = 下降沿
            ACALL   TICK_GET
            MOV     A,     R5
            CLR     C
            SUBB    A,     STR_L
            MOV     A,     R4
            SUBB    A,     STR_H        ; A = 已等的高字节
            JNZ     IR_SILENT           ; 超过 25.6ms 还没边沿 -> 真没信号
            SJMP    IRW_EDGE

IR_EDGE:
            ; ---- 2) 引导码低电平，应为 9ms ----
            MOV     MLVL,  #0
            ACALL   MEAS_LEVEL          ; 量到它变高为止
            MOV     LEDLO,  DUR_L       ; 先存下来：不合格时要用它报诊断
            JC      IR_REJECT           ; 低电平一直不结束
            MOV     A,     DUR_H
            JNZ     IR_REJECT           ; 低电平 > 25.6ms -> 不是 NEC
            MOV     A,     DUR_L
            CLR     C
            SUBB    A,     #IR_LEAD_MIN
            JC      IR_REJECT           ; 太短
            MOV     A,     DUR_L
            CLR     C
            SUBB    A,     #IR_LEAD_MAX
            JNC     IR_REJECT           ; 太长

            ; ---- 3) 引导码高电平：靠"会不会变低"区分完整帧和重复帧 ----
            ;   完整帧 : 9ms 低 + 4.5ms 高，紧接着就是第 1 位的低电平 -> 会变低
            ;   重复帧 : 9ms 低 + 2.25ms 高，之后是空闲高电平     -> 不会再变低
            ;   所以这里量到 6ms 就收手：提前变低 = 完整帧，到点还高着 = 重复帧。
            ;   （关键：不能像量低电平那样死等它变低。重复帧要等到下一帧才变低，
            ;     死等必然超时 -> 被当成解码失败 -> "松键停车"永远刷不到时刻，
            ;     结果就是按住键不松、车却自己停了。）
            MOV     MLVL,  #1
            MOV     CAP_L, #IR_LEADHCAP
            ACALL   MEAS_LEVEL
            MOV     LEDHI,  DUR_L
            JC      IR_REPEAT           ; 6ms 还高着 -> 重复帧
            MOV     A,     DUR_H
            JNZ     IR_REPEAT
            MOV     A,     DUR_L
            CLR     C
            SUBB    A,     #IR_LEADH_MIN
            JC      IR_REJECT           ; 高电平太短 -> 不是引导码

            ; ---- 4) 收 32 位（NEC 低位在前）----
            MOV     IB0,    #0
            MOV     IB1,    #0
            MOV     IB2,    #0
            MOV     IB3,    #0
            MOV     BITS,   #32
            MOV     PTRIDX, #0
            MOV     MASKB,  #01H

IR_BITLOOP:
            ; 每位：先一段低电平（约 0.56ms）
            MOV     CAP_L,  #0
            MOV     MLVL,   #0
            ACALL   MEAS_LEVEL
            JC      IR_BAD              ; 引导码之后每位的低电平都该结束

            ; 再一段高电平：0.56ms = 位0，1.69ms = 位1
            MOV     MLVL,   #1
            MOV     A,     BITS
            CJNE    A,     #1,      IR_MIDBIT
            ; ---- 最后一位特殊处理 ----
            ; 它后面是空闲高电平（不是下一位的低电平），所以不能等它变低，
            ; 只量到 1.2ms 就下结论：提前变低=位0，到点了还没变=位1。
            MOV     CAP_L,  #IR_BITCAP
            ACALL   MEAS_LEVEL
            JNC     IR_NEXTBIT          ; 1.2ms 内变低 -> 位0
            SJMP    IR_SET1             ; 到点还高着 -> 位1

IR_MIDBIT:
            MOV     CAP_L,  #0
            ACALL   MEAS_LEVEL
            JC      IR_BAD
            ; 说明：这里不需要再查 DUR_H。MEAS_LEVEL 在 CAP_L=0 时
            ; 只要 DUR_H 非 0 就直接返回 C=1，所以走到这儿 DUR_H 必然是 0，
            ; 只管比低字节就够了。
            MOV     A,     DUR_L
            CLR     C
            SUBB    A,     #IR_BIT_TH
            JC      IR_NEXTBIT          ; < 1.1ms -> 位0

IR_SET1:
            ACALL   IR_SETBIT
IR_NEXTBIT:
            DEC     BITS
            MOV     A,     BITS
            JNZ     IR_BITLOOP

            ; ---- 5) 校验：NEC 的 addr/~addr、cmd/~cmd 必须互补 ----
            MOV     A,     IB0
            CPL     A
            XRL     A,     IB1
            JNZ     IR_BAD
            MOV     A,     IB2
            CPL     A
            XRL     A,     IB3
            JNZ     IR_BAD

            MOV     IRSTAT, #0          ; 完整帧，IB2 = 键值
            RET

IR_REPEAT:
            MOV     IRSTAT, #3          ; 重复帧
            RET

IR_BAD:
            MOV     IRSTAT, #2          ; 数据段出错（脉宽不对/校验不过）：同样报
            RET

;=========================================================================
; IR_SETBIT：把当前位（1）写进 IB0..IB3
;   用 PTRIDX（字节序号）+ MASKB（位掩码），每收一位掩码左移，
;   溢出说明一个字节收满了，序号 +1。NEC 是低位在前，所以从 01H 起。
;=========================================================================
IR_SETBIT:
            MOV     A,     PTRIDX
            CJNE    A,     #0,      ISB_1
            MOV     A,     MASKB
            ORL     A,     IB0
            MOV     IB0,    A
            SJMP    ISB_NEXT
ISB_1:      CJNE    A,     #1,      ISB_2
            MOV     A,     MASKB
            ORL     A,     IB1
            MOV     IB1,    A
            SJMP    ISB_NEXT
ISB_2:      CJNE    A,     #2,      ISB_3
            MOV     A,     MASKB
            ORL     A,     IB2
            MOV     IB2,    A
            SJMP    ISB_NEXT
ISB_3:
            MOV     A,     MASKB
            ORL     A,     IB3
            MOV     IB3,    A
ISB_NEXT:
            MOV     A,     MASKB
            RL      A
            MOV     MASKB,  A
            JNZ     ISB_DONE            ; 掩码没溢出 -> 同一字节的下一位
            MOV     MASKB,  #01H        ; 溢出 -> 换下一个字节
            INC     PTRIDX
ISB_DONE:
            RET

;=========================================================================
; MEAS_LEVEL：量 P3.3 保持 MLVL 指定电平的长度（单位 tick = 100us）
;   入口：MLVL = 0 量低电平（等它变高）
;          MLVL = 1 量高电平（等它变低）
;          CAP_L = 限时（tick），0 = 用默认上限 25.6ms
;   出口：C = 0 电平已经变化，DUR_H:DUR_L = 时长
;          C = 1 到限时了电平还没变（超时）
;   只用 R4/R5（TICK_GET 的出口寄存器）
;=========================================================================
MEAS_LEVEL:
            ACALL   TICK_GET
            MOV     STR_H, R4
            MOV     STR_L, R5
ML_LOOP:
            ACALL   TICK_GET
            ; delta = now - start （16 位借位减法）
            MOV     A,     R5
            CLR     C
            SUBB    A,     STR_L
            MOV     DUR_L,  A
            MOV     A,     R4
            SUBB    A,     STR_H
            MOV     DUR_H,  A
            ; ---- 限时判定 ----
            MOV     A,     CAP_L
            JZ      ML_DEFCAP
            MOV     A,     DUR_H        ; 有 CAP：DUR >= CAP 就算到点
            JNZ     ML_TIMEOUT
            MOV     A,     DUR_L
            CLR     C
            SUBB    A,     CAP_L
            JC      ML_LEVEL            ; 还没到 CAP
            SJMP    ML_TIMEOUT
ML_DEFCAP:
            MOV     A,     DUR_H        ; 没 CAP：高字节非 0（>25.6ms）就算到点
            JNZ     ML_TIMEOUT
ML_LEVEL:
            MOV     A,     MLVL
            JZ      ML_WAIT_HI
            JNB     P3.3,   ML_DONE     ; 量高 -> 等它变低
            SJMP    ML_LOOP
ML_WAIT_HI:
            JB      P3.3,   ML_DONE     ; 量低 -> 等它变高
            SJMP    ML_LOOP
ML_DONE:
            CLR     C
            RET
ML_TIMEOUT:
            SETB    C
            RET

;=========================================================================
; STAMP_NOW：把"最后一次收到红外帧的时刻"更新为现在
;=========================================================================
STAMP_NOW:
            ACALL   TICK_GET
            MOV     LASTT_H, R4
            MOV     LASTT_L, R5
            RET

;=========================================================================
; TICK_GET：原子地读出 16 位系统时基 -> R4:R5
;   时基由 Timer0 中断维护，读两个字节中间不能被中断，否则会读到
;   半新半旧的组合（例如 00FF -> 0100 之间）。关中断只有几个机器周期，
;   远小于 92 个机器周期的中断间隔，不会丢 tick。
;=========================================================================
TICK_GET:
            CLR     EA
            MOV     R4,     TICK_H
            MOV     R5,     TICK_L
            SETB    EA
            RET

;=========================================================================
; Timer0 中断：每 99.8us 把 16 位时基 +1（方式2 硬件自动重装，TF0 硬件清）
;   只碰 ACC，不动任何工作寄存器。
;=========================================================================
T0_ISR:
            PUSH    ACC
            PUSH    PSW
            INC     TICK_L
            MOV     A,     TICK_L
            JNZ     T0I_RET
            INC     TICK_H
T0I_RET:
            POP     PSW
            POP     ACC
            RETI

;=========================================================================
; 串口输出辅助
;=========================================================================
PUTCHAR:                                ; 发送 A 里的字符，等发完才返回
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

;=========================================================================
; 延时（只用 R0~R3，绝不碰 R4~R7：R4/R5 是时基出口，R7 是蜂鸣器计数）
;   机器周期 = 12/11059200 = 1.085us
;=========================================================================
D_500US:                                ; 约 500us（1kHz 半周期）
            MOV     R0,     #229
D500:
            DJNZ    R0,     D500
            RET

;=========================================================================
; 字符串（代码空间）
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== IR REMOTE CAR v1  STC89C52 @11.0592MHz ===',0DH,0AH
            DB  'IR 0038 on P3.3 (NEC) | motors P0.0-P0.5 via L293D',0DH,0AH
            DB  'keys: 46=FWD 15=BCK 44=LFT 43=RGT 40=STOP',0DH,0AH
            DB  'UART 9600 8N1. Press any key; every new key prints here.',0DH,0AH,0

MSG_KEY:    DB  0DH,0AH,'K=',0
MSG_FWD:    DB  ' FWD',0DH,0AH,0
MSG_BCK:    DB  ' BCK',0DH,0AH,0
MSG_LFT:    DB  ' LFT',0DH,0AH,0
MSG_RGT:    DB  ' RGT',0DH,0AH,0
MSG_STP:    DB  ' STP',0DH,0AH,0
MSG_UNK:    DB  ' UNKNOWN KEY (no motor change)',0DH,0AH,0
MSG_RELEASE:
            DB  0DH,0AH,'-- release -> STOP --',0DH,0AH,0
MSG_IRERR:  DB  0DH,0AH,'! IR frame rejected, lead lo=',0
MSG_IRERR2: DB  ' hi=',0
MSG_CRLF:   DB  0DH,0AH,0

HEXTAB:     DB  '0123456789ABCDEF'

            END
