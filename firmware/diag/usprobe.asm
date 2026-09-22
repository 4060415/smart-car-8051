;=========================================================================
; usprobe.asm  --  超声波模块体检：把"有没有回波、大概多远"直接显示 + 发声
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name usprobe
;
; 一、为什么要单独做这个工具
;   usfollow / usfollow2 的数码管只显示一位，之前"距离 >= 9cm"和"没有回波"
;   都显示 9，导致"到底有没有回波"根本分不出来，排查一直卡在这一步。
;   这个工具把两件事分开，而且给**两个互相独立的证据通道**：
;
;     通道 1（看）—— 数码管
;         "-"（只亮中间一横） = **完全没有回波**
;         数字 0~9           = **有回波**，距离 = 数字 × 5 厘米
;                              0:0~4  1:5~9  2:10~14  3:15~19  4:20~24
;                              5:25~29  6:30~34  7:35~39  8:40~44  9:>=45cm
;     通道 2（听）—— 蜂鸣器
;         **每收到一次回波就"嘀"一声**；没有回波时**完全不响**。
;         所以就算数码管看不明白，光靠耳朵也能判断：
;             手在模块前面移动 -> "嘀嘀嘀"响个不停 = 有回波
;             一直安静               = 没有回波
;
; 二、怎么用它判断（这才是重点）
;   把小车架起来（本程序不驱动电机），手在模块正前方 5~40cm 慢慢来回移动：
;
;     A. 数字跟着手变 + 一直"嘀嘀嘀"
;          -> 模块完全正常。车不跟随是别的原因（跟随逻辑/门限/电机）。
;     B. 一直显示 "-" + 一直不响
;          -> 模块没有在回波。下面三选一：
;             (1) Trig 线没接好（插座第 3 脚）
;             (2) 模块电源接反/没供电（插座 1=GND、4=VCC）—— 注意：电源接反时，
;                 模块的 ESD 保护二极管也会把 Echo 线拽低，所以之前 uscheck
;                 显示"1"并不能证明供电是对的
;             (3) 模块（或其换能器）已经损坏
;     C. 数字固定不变（比如一直是 9）
;          -> 有回波但不跟着手走：波束没对准（HC-SR04 波束约 ±15°），
;             或者模块前方有固定的反射物（车体/支架/线）
;
; 三、接线（同 usfollow2）
;   Trig = P1.3（DIP40 第 4 脚，网标号 P13TR）
;   Echo = P1.2（DIP40 第 3 脚，网标号 P12EC）
;   ⚠️ 板上插座 CSB1 是 1:GND 2:Echo 3:Trig 4:VCC，
;      而 HC-SR04 模块自己是 VCC/Trig/Echo/GND —— **顺序正好反，别直接插！**
;
; 四、安全
;   本程序**不驱动电机**（P0 全程停车），可以随便架着测。
;   串口会同时打印原始数据，便于标定。
;=========================================================================

; --- 引脚 ---
US_TRIG     BIT     P1.3        ; 触发（MCU 输出）
US_ECHO     BIT     P1.2        ; 回波（MCU 输入）

; --- 常量 ---
TRIG_W      EQU     6           ; 触发高电平 ≈ 13us（要求 >10us）
CM_DIV      EQU     53          ; cm = 机器周期数 / 53
CM_FAR      EQU     255         ; 没回波时的"很远"值
CM_PER_DIG  EQU     5           ; 数码管每一格 = 5cm

PAT_STOP    EQU     0C0H        ; 电机断电
DISP_DASH   EQU     0FDH        ; "-"：只点亮段 g（bit1=0，其余全 1）
BEEP_CYCLES EQU     8           ; "嘀"一声 = 8 个 1kHz 半周期 ≈ 8ms（短促，适合连响）

            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #PAT_STOP   ; 全程停车，不碰电机
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH
            CLR     US_TRIG

            ; ---- 串口 9600 8N1（T1 做波特率；T0 方式1 量回波）----
            MOV     TMOD,   #21H
            MOV     TH1,    #0FDH
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H
            MOV     PCON,   #00H
            SETB    TR1

            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR
            ACALL   BEEP_LONG           ; 开机"嘀——"一声，证明程序在跑

;=========================================================================
; 主循环：触发 -> 量回波 -> 显示 + 发声 -> 等 150ms
;   150ms 一轮，既有足够间隔（HC-SR04 要求 >60ms），
;   又能让"每回波一声"连成明显的"嘀嘀嘀"，耳朵容易分辨。
;=========================================================================
LOOP:
            ACALL   US_MEASURE          ; C=0 成功（R6:R7 周期数）；C=1 无回波
            JC      P_NOECHO
            MOV     A,      R6
            ORL     A,      R7
            JZ      P_NOECHO            ; 0 个周期 = 无效测量

            ; ---- 有回波 ----
            MOV     TKH,    R6
            MOV     TKL,    R7
            ACALL   TICKS2CM            ; A = cm
            MOV     DIST,   A
            ACALL   SHOW5               ; A = 距离 / 5（0..9）
            MOV     DPTR,   #DIGIT
            MOVC    A,      @A+DPTR
            MOV     P2,     A           ; D3 灭（bit0=1）
            ACALL   BEEP_TICK           ; ★ 每回波一声：用耳朵确认
            ACALL   PRINT_OK
            SJMP    P_NEXT

P_NOECHO:
            MOV     TKH,    #0
            MOV     TKL,    #0
            MOV     DIST,   #CM_FAR
            MOV     P2,     #DISP_DASH  ; "-"：没有回波
            ; ★ 没有回波时**不响**，安静就是"没回波"
            ACALL   PRINT_NO

P_NEXT:
            ACALL   D_150MS
            LJMP    LOOP

;=========================================================================
; US_MEASURE：发一次触发脉冲，量 Echo 高电平宽度（单位：机器周期）
;   出：C = 0 成功，R6:R7 = 周期数；C = 1 没有回波
;   Timer0 方式1 溢出 = 65536 周期 = 71ms（对应 12m），远超模块量程，
;   所以"等不到"就是"前面没有东西"。
;=========================================================================
US_MEASURE:
            ; ---- 触发脉冲：先拉低几个周期，再拉高 ~13us ----
            CLR     US_TRIG
            MOV     R2,     #4
USM_LOW:
            DJNZ    R2,     USM_LOW
            SETB    US_TRIG
            MOV     R2,     #TRIG_W
USM_HI:
            DJNZ    R2,     USM_HI
            CLR     US_TRIG

            ; ---- 等 Echo 上升沿 ----
            MOV     TH0,    #0
            MOV     TL0,    #0
            CLR     TF0
            SETB    TR0
USM_RISE:
            JB      US_ECHO, USM_UP
            JNB     TF0,    USM_RISE
            CLR     TR0
            SETB    C
            RET

            ; ---- 上升沿到了：清零重开，量的就是脉冲宽度本身 ----
USM_UP:
            CLR     TR0
            MOV     TH0,    #0
            MOV     TL0,    #0
            CLR     TF0
            SETB    TR0
USM_FALL:
            JNB     US_ECHO, USM_DOWN
            JNB     TF0,    USM_FALL
            CLR     TR0                 ; 高电平超过 71ms -> 模块没接好/坏了
            SETB    C
            RET
USM_DOWN:
            CLR     TR0
            MOV     R6,     TH0
            MOV     R7,     TL0
            CLR     C
            RET

;=========================================================================
; TICKS2CM：机器周期数 -> 厘米（反复减 53，数次数）
;   入：R6:R7   出：A = cm（超过 255 给 255）
;=========================================================================
TICKS2CM:
            MOV     R4,     #0
            MOV     R5,     #0
T2C_LOOP:
            MOV     A,      R6
            JNZ     T2C_SUB
            MOV     A,      R7
            CLR     C
            SUBB    A,      #CM_DIV
            JC      T2C_DONE
T2C_SUB:
            CLR     C
            MOV     A,      R7
            SUBB    A,      #CM_DIV
            MOV     R7,     A
            MOV     A,      R6
            SUBB    A,      #0
            MOV     R6,     A
            INC     R5
            MOV     A,      R5
            JNZ     T2C_LOOP
            INC     R4
            MOV     A,      R4
            JNZ     T2C_CAP
            LJMP    T2C_LOOP
T2C_CAP:
            MOV     A,      #CM_FAR
            RET
T2C_DONE:
            MOV     A,      R5
            RET

;=========================================================================
; SHOW5：距离（cm）-> 数码管数字，每 5cm 一格，封顶 9
;   入：DIST   出：A = 0..9
;   例：7cm -> 1、18cm -> 3、47cm -> 9
;=========================================================================
SHOW5:
            MOV     R3,     #0
            MOV     A,      DIST
SH5_LP:
            CJNE    R3,     #9, SH5_SUB ; 还没到 9 -> 继续减
            MOV     A,      #9          ; 已经 9 格了 -> 封顶
            RET
SH5_SUB:
            CLR     C
            SUBB    A,      #CM_PER_DIG
            JC      SH5_DN              ; 不够减了 -> 商就是 R3
            INC     R3
            SJMP    SH5_LP
SH5_DN:
            MOV     A,      R3
            RET

;=========================================================================
; 蜂鸣器：P0.6 拉低 -> S8550 导通 -> 响（无源，给方波）
;   BEEP_TICK = 短促一声（每回波一次）
;   BEEP_LONG = 开机长一声
;   只用 R7；D_500US 只用 R1。
;=========================================================================
BEEP_TICK:
            MOV     R7,     #BEEP_CYCLES
            SJMP    BEEP_GO
BEEP_LONG:
            MOV     R7,     #60         ; 60 个周期 ≈ 60ms，明显的一声
BEEP_GO:
            MOV     A,      #PAT_STOP
            ANL     A,      #0BFH       ; b6 = 0 -> 响
            MOV     P0,     A
            ACALL   D_500US
            MOV     P0,     #PAT_STOP   ; b6 = 1 -> 静音
            ACALL   D_500US
            DJNZ    R7,     BEEP_GO
            RET

;=========================================================================
; 串口输出
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

PUT_HEX:                                ; A -> 两位十六进制
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

PUT_DEC3:                               ; A（0..255）-> 三位十进制
            MOV     B,      #100
            DIV     AB
            ADD     A,      #'0'
            ACALL   PUTCHAR
            MOV     A,      B
            MOV     B,      #10
            DIV     AB
            ADD     A,      #'0'
            ACALL   PUTCHAR
            MOV     A,      B
            ADD     A,      #'0'
            ACALL   PUTCHAR
            RET

PRINT_OK:
            MOV     DPTR,   #MSG_D
            ACALL   PRINT_STR
            MOV     A,      DIST
            ACALL   PUT_DEC3
            MOV     DPTR,   #MSG_CM
            ACALL   PRINT_STR
            MOV     A,      TKH
            ACALL   PUT_HEX
            MOV     A,      TKL
            ACALL   PUT_HEX
            MOV     DPTR,   #MSG_OK
            ACALL   PRINT_STR
            RET

PRINT_NO:
            MOV     DPTR,   #MSG_NO
            ACALL   PRINT_STR
            RET

;=========================================================================
; 延时
;=========================================================================
D_500US:
            MOV     R1,     #229
D500:
            DJNZ    R1,     D500
            RET

D_1MS:
            MOV     R2,     #2
D1M_1:
            MOV     R1,     #230
D1M_2:
            DJNZ    R1,     D1M_2
            DJNZ    R2,     D1M_1
            RET

D_150MS:
            MOV     R5,     #150
D150_1:
            ACALL   D_1MS
            DJNZ    R5,     D150_1
            RET

;=========================================================================
; 数据区与字符串
;=========================================================================
TKH         DATA    30H
TKL         DATA    31H
DIST        DATA    32H

MSG_BOOT:
            DB  0DH,0AH,'=== ULTRASONIC PROBE ===',0DH,0AH
            DB  '7seg: "-" = NO ECHO | digit x5 = cm  (1=5-9cm 4=20-24cm 9=45cm+)',0DH,0AH
            DB  'buzzer: one tick per echo -> silence means NO echo.',0DH,0AH
            DB  'Trigger=P1.3  Echo=P1.2. Move your hand 5-40cm in front.',0DH,0AH,0
MSG_D:      DB  0DH,0AH,'D=',0
MSG_CM:     DB  'cm T=',0
MSG_OK:     DB  '  echo OK',0DH,0AH,0
MSG_NO:     DB  0DH,0AH,'--- no echo (buzzer silent) ---',0DH,0AH,0

; 共阳数码管段码：bit7..bit1 = a b c d e f g（写 0 点亮），bit0 = D3 灯（1 = 灭）
DIGIT:      DB  03H,9FH,25H,0DH,99H,49H,41H,1FH,01H,09H
HEXTAB:     DB  '0123456789ABCDEF'

            END
