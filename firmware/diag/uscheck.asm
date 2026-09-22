;=========================================================================
; uscheck.asm  --  超声波接线自检（结果直接显示在数码管上，不用串口）
;-------------------------------------------------------------------------
; 目标器件 : STC89C52RC @ 11.0592MHz
; 生成工具 : Keil A51 + BL51 + OH51   ->  build.ps1 -Name uscheck
;
; 一、为什么要它
;   跟随小车不动，怀疑超声波接线。MCU 侧那两个脚
;   （Trig=P1.3 网标号 P13TR、Echo=P1.2 网标号 P12EC）是从原理图追出来的，
;   但**插座上的线序**极容易接错：
;       板上插座 CSB1 顺序 = 1:GND  2:Echo  3:Trig  4:VCC
;       HC-SR04 模块自己的顺序 = VCC  Trig  Echo  GND      <- 正好反！
;   直接把模块插上去 = **电源接反**，模块不工作，甚至可能已经损坏。
;
; 二、判据（利用一个硬件事实）
;   HC-SR04 的 Echo 是**推挽输出**，空闲时被模块**主动拉低**；
;   而 Trig 是模块的输入，高阻，只靠 8051 内部弱上拉。
;   所以把 P1.2 / P1.3 都当输入（写 1 放开），等一小会儿再读：
;       接在 Echo 上的那根 -> 读到 0
;       接在 Trig 上的那根 -> 读到 1
;
;   四种结果（数码管显示）：
;     P1.2=0 P1.3=1 -> **1**  与图纸一致（Echo=P1.2, Trig=P1.3）
;     P1.2=1 P1.3=0 -> **2**  **接反了**（Echo=P1.3, Trig=P1.2）
;     P1.2=1 P1.3=1 -> **0**  Echo 那根线上没有模块在驱动（线没插 / 没供电 / 模块坏）
;     P1.2=0 P1.3=0 -> **9**  两个都低（反常，可能线接错把两个都拽低了）
;
;   判定完再做一次**主动测距**：往 Trig 发一个 ~13us 脉冲，看 Echo 会不会跳高。
;       收到回波 -> **D3 灯亮**；没收到 -> D3 灯灭。
;
; 三、安全性（重要）
;   本程序**永远不会去驱动 Echo 那根线**：哪根是 Echo 是靠上面的电平判出来的，
;   只驱动判为 Trig 的那根（模块的输入、高阻）。所以不存在
;   "MCU 输出和模块输出顶牛"的风险 —— 就算 Trig/Echo 接反了也一样安全。
;
; 四、怎么用它
;   烧 uscheck.hex -> 冷启动 -> 看数码管那一位数字：
;     1  -> 接线正确。若 D3 灯不亮，说明模块收到了触发但没回波 -> 模块本身的问题
;     2  -> 把 usfollow2.asm 里 US_TRIG / US_ECHO 两行对调，重编
;     0  -> 检查插座供电和杜邦线（重点：插座 4 脚是不是 VCC、1 脚是不是 GND）
;     9  -> 线序完全不对，按标号重新一根一根接
;
; 五、引脚
;   P1.2 / P1.3 = 待判定的两个脚
;   P2.7~P2.1 = 数码管 a~g（共阳，写 0 点亮）；P2.0 = D3 灯（写 0 亮）
;   P0 = 全程停车（本程序不驱动电机）
;   P3.1 = TXD（9600 8N1，有串口就同时打印详细结论）
;=========================================================================

; --- 数码管段码（共阳：写 0 点亮；bit7..bit1 = a b c d e f g；bit0 = D3 灯，1 = 灭）---
DISP_0      EQU     03H         ; "0"
DISP_1      EQU     9FH         ; "1"
DISP_2      EQU     25H         ; "2"
DISP_9      EQU     09H         ; "9"

PAT_STOP    EQU     0C0H        ; 电机断电（ENA/ENB 一起拉低）

TRIGW       EQU     6           ; 触发高电平：6*2 = 12 机器周期 ≈ 13us
ECHO_WAIT   EQU     60          ; 等回波上限：60 × 1ms = 60ms

            ORG     0000H
            LJMP    MAIN

            ORG     0030H
MAIN:
            MOV     SP,     #60H
            MOV     P0,     #PAT_STOP   ; 全程停车，不碰电机
            MOV     P1,     #0FFH
            MOV     P2,     #0FFH

            ; ---- 串口 9600 8N1（有就打印详细结论，没有也不影响数码管）----
            MOV     TMOD,   #20H
            MOV     TH1,    #0FDH
            MOV     TL1,    #0FDH
            MOV     SCON,   #50H
            MOV     PCON,   #00H
            SETB    TR1
            MOV     DPTR,   #MSG_BOOT
            ACALL   PRINT_STR

;=========================================================================
; 主循环：读电平 -> 判定 -> 显示 -> 主动测距 -> 再显示
;=========================================================================
ULOOP:
            ; ---- 1) 两个脚都当输入（写 1 放开），读空闲电平 ----
            MOV     P1,     #0FFH
            ACALL   D_2MS
            MOV     A,      P1
            ANL     A,      #0CH        ; 只留 P1.3(bit3) 和 P1.2(bit2)
            ;   A = 08H -> P1.3=1 P1.2=0   (与图纸一致)
            ;   A = 04H -> P1.3=0 P1.2=1   (接反)
            ;   A = 0CH -> 两个都高
            ;   A = 00H -> 两个都低

            ; ---- 2) 判定并显示 ----
            CJNE    A,      #08H,    U_T2
            ; ---- 与图纸一致 ----
            MOV     DPTR,   #MSG_OK
            ACALL   PRINT_STR
            MOV     R4,     #DISP_1
            MOV     R6,     #0          ; 0 = Trig 用 P1.3 / Echo 用 P1.2
            LJMP    U_ACT

U_T2:
            CJNE    A,      #04H,    U_T3
            ; ---- 接反了 ----
            MOV     DPTR,   #MSG_SWAP
            ACALL   PRINT_STR
            MOV     R4,     #DISP_2
            MOV     R6,     #1          ; 1 = Trig 用 P1.2 / Echo 用 P1.3
            LJMP    U_ACT

U_T3:
            CJNE    A,      #0CH,    U_T4
            ; ---- 两个都高：Echo 线上没有模块在驱动 ----
            MOV     DPTR,   #MSG_NONE
            ACALL   PRINT_STR
            MOV     R4,     #DISP_0
            LJMP    U_SHOW

U_T4:
            ; ---- 两个都低 ----
            MOV     DPTR,   #MSG_BOTH
            ACALL   PRINT_STR
            MOV     R4,     #DISP_9
            LJMP    U_SHOW

;-------------------------------------------------------------------------
; 3) 主动测距：往 Trig 发一个 ~13us 脉冲，看 Echo 会不会跳高
;    只驱动判为 Trig 的那根（模块输入、高阻），绝不驱动 Echo
;
;    ⚠️⚠️ 2026-09-21 修 bug：原来这里只写 `SETB P1.3` 就直接延时 ——
;        可本程序在 ULOOP 开头刚做过 `MOV P1,#0FFH`，**Trig 早就是高了**，
;        所以那条 SETB 等于**什么都没做** ⇒ **根本没有上升沿** ⇒
;        HC-SR04 靠上升沿触发 ⇒ 模块不测距 ⇒ Echo 永远不变高 ⇒
;        **D3 永远是灭的**（"没回波"这个结论完全不成立，害得排查方向都错了）。
;        别的程序（usprobe.asm / car_asm.asm）都是 CLR → SETB 两步，那才叫脉冲。
;        现在补上 `CLR`，和它们对齐。
;-------------------------------------------------------------------------
U_ACT:
            MOV     A,      R6
            JNZ     U_ACT_SW

            ; ---- Trig = P1.3, Echo = P1.2 ----
            CLR     P1.3                ; ★ 先拉低：制造上升沿（少了这句就是废的）
            SETB    P1.3                ; ★ 再拉高 = 触发
            MOV     R7,     #TRIGW
U_AL:       DJNZ    R7,     U_AL
            CLR     P1.3
            MOV     R7,     #ECHO_WAIT
U_AW:       JB      P1.2,   U_GOT
            ACALL   D_1MS
            DJNZ    R7,     U_AW
            LJMP    U_NOECHO

U_ACT_SW:
            ; ---- Trig = P1.2, Echo = P1.3 ----
            CLR     P1.2                ; ★ 同上：先拉低
            SETB    P1.2
            MOV     R7,     #TRIGW
U_BL:       DJNZ    R7,     U_BL
            CLR     P1.2
            MOV     R7,     #ECHO_WAIT
U_BW:       JB      P1.3,   U_GOT
            ACALL   D_1MS
            DJNZ    R7,     U_BW
            LJMP    U_NOECHO

U_GOT:
            ; ---- 收到回波：D3 灯亮 ----
            MOV     DPTR,   #MSG_GOT
            ACALL   PRINT_STR
            MOV     A,      R4
            ANL     A,      #0FEH       ; bit0 = 0 -> D3 亮
            MOV     P2,     A
            LJMP    U_NEXT

U_NOECHO:
            ; ---- 没收到回波：只显示数字，D3 灭 ----
            MOV     DPTR,   #MSG_NONE2
            ACALL   PRINT_STR
U_SHOW:
            MOV     P2,     R4          ; R4 的 bit0 = 1 -> D3 灭

U_NEXT:
            ACALL   D_500MS
            LJMP    ULOOP

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
; 延时（机器周期 = 1.085us）
;   D_1MS 用 R1/R2；D_2MS 用 R3；D_500MS 用 R5。
;   R4(显示码) / R6(朝向) / R7(计数) 在调用点之外，不冲突。
;=========================================================================
D_1MS:
            MOV     R2,     #2
D1M_1:      MOV     R1,     #230
D1M_2:      DJNZ    R1,     D1M_2       ; 230*2 = 460 周期
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
; 字符串
;=========================================================================
MSG_BOOT:
            DB  0DH,0AH,'=== ULTRASONIC WIRING CHECK ===',0DH,0AH
            DB  '7seg: 1=ok(P1.2 Echo/P1.3 Trig) 2=SWAPPED 0=no module 9=both low',0DH,0AH
            DB  'D3 LED: lit = a valid echo came back.',0DH,0AH,0
MSG_OK:
            DB  0DH,0AH,'-> [1] P1.2=0 P1.3=1 : matches schematic (Echo=P1.2 Trig=P1.3)',0DH,0AH,0
MSG_SWAP:
            DB  0DH,0AH,'-> [2] P1.2=1 P1.3=0 : TRIG/ECHO ARE SWAPPED (Echo=P1.3 Trig=P1.2)',0DH,0AH,0
MSG_NONE:
            DB  0DH,0AH,'-> [0] both HIGH : nothing is driving the Echo line',0DH,0AH
            DB  '     (module not plugged / not powered / dead)',0DH,0AH,0
MSG_BOTH:
            DB  0DH,0AH,'-> [9] both LOW : abnormal (wiring pulls both down?)',0DH,0AH,0
MSG_GOT:
            DB  '  + echo received (D3 lit) -> module is alive',0DH,0AH,0
MSG_NONE2:
            DB  '  - no echo within 60ms (D3 off)',0DH,0AH,0

            END
