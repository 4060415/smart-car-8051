;=========================================================================
; main_abs.asm  --  **自动生成，请勿手改**
;-------------------------------------------------------------------------
;   来源 : main.src
;   生成 : python tools\c51_link.py main.src
;
;   作用 : 把 C51 生成的 76 个可重定位段拼成**一个绝对地址模块**，
;          这样 A51（评估版无限额）就能直接汇编出最终机器码，
;          再由 tools\lst2hex.py 从清单出 hex ——
;          绕开评估版链接器 BL51 / LX51 的 2048 字节上限。
;
;   布局 : 代码 0010H 起 / 数据 0030H 起 / 位 20H 起 / 栈顶 7FH
;   对应关系 : 每段前面标了原来的段名，段内保留 "; SOURCE LINE # n"
;              可以据此回到 main.c 的对应行。
;=========================================================================

; main.SRC generated from: main.c
; COMPILER INVOKED BY:
;        D:\keli\C51\BIN\C51.EXE main.c SMALL SRC DEFINE(DIAG_IR=1)
$NOMOD51
	NAME	MAIN_ABS
P0	DATA	080H
P1	DATA	090H
P2	DATA	0A0H
P3	DATA	0B0H
T0	BIT	0B0H.4
AC	BIT	0D0H.6
T1	BIT	0B0H.5
T2	BIT	090H.0
EA	BIT	0A8H.7
IE	DATA	0A8H
IR_IN	BIT	0B0H.3
EXF2	BIT	0C8H.6
RD	BIT	0B0H.7
ES	BIT	0A8H.4
IP	DATA	0B8H
RI	BIT	098H.0
INT0	BIT	0B0H.2
CY	BIT	0D0H.7
TI	BIT	098H.1
INT1	BIT	0B0H.3
RCAP2H	DATA	0CBH
TRACK_L	BIT	0B0H.5
PS	BIT	0B8H.4
SP	DATA	081H
T2EX	BIT	090H.1
OV	BIT	0D0H.2
RCAP2L	DATA	0CAH
US_ECHO	BIT	090H.2
TRACK_R	BIT	0B0H.6
C_T2	BIT	0C8H.1
WR	BIT	0B0H.6
RCLK	BIT	0C8H.5
TCLK	BIT	0C8H.4
SBUF	DATA	099H
PCON	DATA	087H
SCON	DATA	098H
TMOD	DATA	089H
TCON	DATA	088H
IE0	BIT	088H.1
IE1	BIT	088H.3
US_TRIG	BIT	090H.3
B	DATA	0F0H
LDR_RIGHT	BIT	090H.0
CP_RL2	BIT	0C8H.0
ACC	DATA	0E0H
ET0	BIT	0A8H.1
ET1	BIT	0A8H.3
TF0	BIT	088H.5
ET2	BIT	0A8H.5
TF1	BIT	088H.7
TF2	BIT	0C8H.7
RB8	BIT	098H.2
TH0	DATA	08CH
EX0	BIT	0A8H.0
IT0	BIT	088H.0
TH1	DATA	08DH
TB8	BIT	098H.3
EX1	BIT	0A8H.2
IT1	BIT	088H.2
TH2	DATA	0CDH
P	BIT	0D0H.0
KEY_S3	BIT	0B0H.4
SM0	BIT	098H.7
TL0	DATA	08AH
KEY_S4	BIT	0B0H.2
SM1	BIT	098H.6
TL1	DATA	08BH
SM2	BIT	098H.5
TL2	DATA	0CCH
PT0	BIT	0B8H.1
PT1	BIT	0B8H.3
RS0	BIT	0D0H.3
PT2	BIT	0B8H.5
TR0	BIT	088H.4
RS1	BIT	0D0H.4
TR1	BIT	088H.6
TR2	BIT	0C8H.2
PX0	BIT	0B8H.0
PX1	BIT	0B8H.2
DPH	DATA	083H
DPL	DATA	082H
EXEN2	BIT	0C8H.3
REN	BIT	098H.4
T2CON	DATA	0C8H
RXD	BIT	0B0H.0
LDR_LEFT	BIT	090H.1
IR_AVOID	BIT	0B0H.7
TXD	BIT	0B0H.1
F0	BIT	0D0H.5
PSW	DATA	0D0H
?PR?timer0_isr?MAIN  SEGMENT CODE
?PR?tick_get?MAIN    SEGMENT CODE
?PR?ms10_get?MAIN    SEGMENT CODE
?PR?d_20ms?MAIN      SEGMENT CODE
?PR?_beep?MAIN       SEGMENT CODE
?PR?_motor_set_core?MAIN                 SEGMENT CODE
?PR?_d3_mix?MAIN     SEGMENT CODE
?DT?_d3_mix?MAIN     SEGMENT DATA OVERLAYABLE
?PR?avoid_off?MAIN   SEGMENT CODE
?PR?apply_gear_core?MAIN                 SEGMENT CODE
?PR?show_state?MAIN  SEGMENT CODE
?PR?show_mode?MAIN   SEGMENT CODE
?PR?key_scan?MAIN    SEGMENT CODE
?PR?k_isfwd?MAIN     SEGMENT CODE
?PR?_key2act?MAIN    SEGMENT CODE
?PR?_key2mode?MAIN   SEGMENT CODE
?PR?_mode_goto?MAIN  SEGMENT CODE
?PR?mode_switch?MAIN SEGMENT CODE
?DT?mode_switch?MAIN SEGMENT DATA OVERLAYABLE
?PR?light_step?MAIN  SEGMENT CODE
?DT?light_step?MAIN  SEGMENT DATA OVERLAYABLE
?PR?track_step?MAIN  SEGMENT CODE
?DT?track_step?MAIN  SEGMENT DATA OVERLAYABLE
?PR?us_init?MAIN     SEGMENT CODE
?PR?us_trigger?MAIN  SEGMENT CODE
?PR?us_read?MAIN     SEGMENT CODE
?PR?ir_det?MAIN      SEGMENT CODE
?PR?ir_brake?MAIN    SEGMENT CODE
?PR?av_gate_hold?MAIN                    SEGMENT CODE
?PR?av_gate?MAIN     SEGMENT CODE
?DT?av_gate?MAIN     SEGMENT DATA OVERLAYABLE
?PR?avoid_toggle?MAIN                    SEGMENT CODE
?PR?meas_level?MAIN  SEGMENT CODE
?PR?ir_reset?MAIN    SEGMENT CODE
?PR?_ir_setbit?MAIN  SEGMENT CODE
?PR?ir_decode_bits?MAIN                  SEGMENT CODE
?PR?ir_decode?MAIN   SEGMENT CODE
?PR?ir_recv?MAIN     SEGMENT CODE
?PR?ir_recv_nb?MAIN  SEGMENT CODE
?PR?stamp_now?MAIN   SEGMENT CODE
?PR?ir_errpr?MAIN    SEGMENT CODE
?PR?do_key?MAIN      SEGMENT CODE
?PR?ir_holdchk?MAIN  SEGMENT CODE
?PR?back_guard?MAIN  SEGMENT CODE
?PR?prox_beep?MAIN   SEGMENT CODE
?PR?rec_halt?MAIN    SEGMENT CODE
?PR?rec_commit?MAIN  SEGMENT CODE
?PR?rec_err?MAIN     SEGMENT CODE
?PR?rec_fullstop?MAIN                    SEGMENT CODE
?DT?rec_fullstop?MAIN                    SEGMENT DATA OVERLAYABLE
?PR?rec_sample?MAIN  SEGMENT CODE
?PR?rec_enter?MAIN   SEGMENT CODE
?PR?rec_exit?MAIN    SEGMENT CODE
?PR?rec_key?MAIN     SEGMENT CODE
?PR?clr_key?MAIN     SEGMENT CODE
?PR?play_load?MAIN   SEGMENT CODE
?PR?play_safety?MAIN SEGMENT CODE
?PR?play_exit?MAIN   SEGMENT CODE
?PR?play_abort?MAIN  SEGMENT CODE
?PR?play_enter?MAIN  SEGMENT CODE
?PR?play_step?MAIN   SEGMENT CODE
?PR?play_key?MAIN    SEGMENT CODE
?PR?manual_step?MAIN SEGMENT CODE
?PR?auto_step?MAIN   SEGMENT CODE
?PR?ml_apply?MAIN    SEGMENT CODE
?PR?diag_keyshow?MAIN                    SEGMENT CODE
?PR?diag_errshow?MAIN                    SEGMENT CODE
?PR?diag_dly?MAIN    SEGMENT CODE
?PR?diag_getval?MAIN SEGMENT CODE
?PR?diag_update?MAIN SEGMENT CODE
?PR?init_all?MAIN    SEGMENT CODE
?PR?main?MAIN        SEGMENT CODE
?DT?main?MAIN        SEGMENT DATA OVERLAYABLE
?CO?MAIN             SEGMENT CODE
?DT?MAIN             SEGMENT DATA
?BI?MAIN             SEGMENT BIT
	PUBLIC	main
	PUBLIC	timer0_isr

;=========================================================================
; 启动代码（替代 Keil 的 ?C_STARTUP）
;   本固件的变量全部在 init_all() 里显式初始化，没有任何静态初值，
;   所以 C 运行期不需要初始化段；这里只做两件事：置栈指针、跳到 main。
;   栈：SP 初值 7FH，压栈先加后存 -> 实际用到 80H 起，
;       80H~FFH 是间接寻址区（只能 MOV @Ri 访问），本工程没往那儿放变量。
;=========================================================================

	CSEG	AT	0000H
		MOV	SP, #7FH
		LJMP	main

;=========================================================================
; 中断向量表
;   这几条是 C51 在 .SRC 里自己生成的（不是本脚本编的），
;   原来由链接器摆放；这里原样接管，所以以后 C 源码里加新的中断函数，
;   向量会自动跟着出来，不用改这个脚本。
;   复位向量在上面（由本脚本的启动代码接管，替代 ?C_STARTUP）。
;=========================================================================

	CSEG	AT	000BH
	LJMP	timer0_isr

;=========================================================================
; 代码：全部函数 + 常量表，按 .SRC 的段序连续摆放
;   段序可以任意 —— 实测 .SRC 里 0 条 ACALL、134 条全 LCALL，
;   跨函数调用都是长调用，不受 2 KB 页限制。
;=========================================================================

	CSEG	AT	0010H

;--------------------------------------------------------------- ?CO?MAIN
gear_tab:
	DB	003H
	DB	09FH
	DB	025H
	DB	00DH
	DB	099H
	DB	049H
duty_tab:
	DB	008H
	DB	00BH
	DB	00EH
	DB	011H
	DB	014H
arc_tab:
	DB	001H
	DB	002H
	DB	002H
	DB	003H
	DB	004H
mode_tab:
	DB	003H
	DB	0E3H
	DB	0E1H
	DB	031H
hex_seg:
	DB	003H
	DB	09FH
	DB	025H
	DB	00DH
	DB	099H
	DB	049H
	DB	041H
	DB	01FH
	DB	001H
	DB	009H
	DB	011H
	DB	081H
	DB	063H
	DB	085H
	DB	061H
	DB	071H

;--------------------------------------------------------------- ?PR?timer0_isr?MAIN
	USING	1
timer0_isr:
	PUSH 	ACC
	PUSH 	PSW
	USING	1
	MOV  	PSW,#08H
			; SOURCE LINE # 544
			; SOURCE LINE # 549
	INC  	tick_l
	MOV  	R7,tick_l
	MOV  	A,R7
	JNZ  	?C0001
			; SOURCE LINE # 550
	INC  	tick_h
?C0001:
			; SOURCE LINE # 553
	INC  	pwm_div
	MOV  	A,pwm_div
	CLR  	C
	SUBB 	A,#05H
	JC   	?C0002
			; SOURCE LINE # 554
	MOV  	pwm_div,#00H
			; SOURCE LINE # 556
	INC  	pwm_cnt
	MOV  	A,pwm_cnt
	SUBB 	A,#014H
	JC   	?C0003
			; SOURCE LINE # 557
	MOV  	pwm_cnt,#00H
?C0003:
			; SOURCE LINE # 559
	MOV  	R7,duty_a
	MOV  	A,pwm_cnt
	CLR  	C
	SUBB 	A,R7
	JNC  	?C0004
	SJMP 	?C0005
?C0004:
	CLR  	C
?C0005:
	MOV  	ena,C
			; SOURCE LINE # 560
	MOV  	R7,duty_b
	MOV  	A,pwm_cnt
	CLR  	C
	SUBB 	A,R7
	JNC  	?C0006
	SJMP 	?C0007
?C0006:
	CLR  	C
?C0007:
	MOV  	enb,C
			; SOURCE LINE # 563
	MOV  	A,buz_left
	JZ   	?C0008
			; SOURCE LINE # 564
	DEC  	buz_left
			; SOURCE LINE # 565
	CPL  	buz_quiet
			; SOURCE LINE # 566
	SJMP 	?C0009
?C0008:
			; SOURCE LINE # 567
	SETB 	buz_quiet
			; SOURCE LINE # 568
?C0009:
			; SOURCE LINE # 571
	MOV  	R7,#080H
			; SOURCE LINE # 572
	MOV  	A,dirbits
	ORL  	AR7,A
			; SOURCE LINE # 573
	JNB  	ena,?C0010
	ORL  	AR7,#010H
?C0010:
			; SOURCE LINE # 574
	JNB  	enb,?C0011
	ORL  	AR7,#020H
?C0011:
			; SOURCE LINE # 575
	JNB  	buz_quiet,?C0012
	ORL  	AR7,#040H
?C0012:
			; SOURCE LINE # 576
	MOV  	P0,R7
			; SOURCE LINE # 577
?C0002:
			; SOURCE LINE # 583
	INC  	ms_div
	MOV  	A,ms_div
	CLR  	C
	SUBB 	A,#064H
	JC   	?C0013
			; SOURCE LINE # 584
	MOV  	ms_div,#00H
			; SOURCE LINE # 585
	INC  	ms10_l
	MOV  	R7,ms10_l
	MOV  	A,R7
	JNZ  	?C0013
			; SOURCE LINE # 586
	INC  	ms10_h
			; SOURCE LINE # 587
?C0013:
			; SOURCE LINE # 593
	MOV  	A,us_st
	JZ   	?C0026
			; SOURCE LINE # 594
	MOV  	A,us_st
	CJNE 	A,#01H,?C0016
			; SOURCE LINE # 595
	JNB  	US_ECHO,?C0017
			; SOURCE LINE # 596
	MOV  	us_wid,#00H
			; SOURCE LINE # 597
	MOV  	us_st,#02H
			; SOURCE LINE # 598
	SJMP 	?C0026
?C0017:
	MOV  	A,us_wait
	CLR  	C
	SUBB 	A,#0FAH
	JNC  	?C0389
			; SOURCE LINE # 599
	INC  	us_wait
			; SOURCE LINE # 600
	SJMP 	?C0026
?C0016:
			; SOURCE LINE # 609
	JNB  	US_ECHO,?C0022
			; SOURCE LINE # 610
	MOV  	A,us_wid
	CLR  	C
	SUBB 	A,#0CH
	JNC  	?C0023
			; SOURCE LINE # 611
	INC  	us_wid
			; SOURCE LINE # 612
	SJMP 	?C0026
?C0023:
			; SOURCE LINE # 613
?C0389:
	MOV  	us_st,#00H
			; SOURCE LINE # 614
	MOV  	us_res,#0FFH
			; SOURCE LINE # 615
	SETB 	us_got
			; SOURCE LINE # 619
			; SOURCE LINE # 620
	SJMP 	?C0026
?C0022:
			; SOURCE LINE # 621
	MOV  	us_st,#00H
			; SOURCE LINE # 622
	MOV  	us_res,us_wid
			; SOURCE LINE # 623
	SETB 	us_got
			; SOURCE LINE # 627
			; SOURCE LINE # 628
			; SOURCE LINE # 629
			; SOURCE LINE # 630
?C0026:
	POP  	PSW
	POP  	ACC
	RETI
; END OF timer0_isr

;--------------------------------------------------------------- ?PR?tick_get?MAIN
tick_get:
	USING	0
			; SOURCE LINE # 637
			; SOURCE LINE # 638
			; SOURCE LINE # 640
	CLR  	ET0
			; SOURCE LINE # 641
	MOV  	R7,tick_h
	MOV  	A,R7
	MOV  	R6,A
	MOV  	R5,tick_l
	MOV  	A,R5
	MOV  	R7,A
			; SOURCE LINE # 642
	SETB 	ET0
			; SOURCE LINE # 643
			; SOURCE LINE # 644
?C0027:
	RET
; END OF tick_get

;--------------------------------------------------------------- ?PR?ms10_get?MAIN
ms10_get:
	USING	0
			; SOURCE LINE # 646
			; SOURCE LINE # 647
			; SOURCE LINE # 649
	CLR  	ET0
			; SOURCE LINE # 650
	MOV  	R7,ms10_h
	MOV  	A,R7
	MOV  	R6,A
	MOV  	R5,ms10_l
	MOV  	A,R5
	MOV  	R7,A
			; SOURCE LINE # 651
	SETB 	ET0
			; SOURCE LINE # 652
			; SOURCE LINE # 653
?C0028:
	RET
; END OF ms10_get

;--------------------------------------------------------------- ?PR?d_20ms?MAIN
L?0420:
	USING	0
L?0421:
	MOV  	R7,#018H
	LCALL	_beep
d_20ms:
	USING	0
			; SOURCE LINE # 661
			; SOURCE LINE # 662
			; SOURCE LINE # 663
	LCALL	tick_get
	MOV  	R3,AR7
	MOV  	R2,AR6
?C0029:
			; SOURCE LINE # 664
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,R3
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,R2
	MOV  	R6,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0C8H
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0029
?C0030:
			; SOURCE LINE # 666
?C0031:
	RET
; END OF d_20ms

;--------------------------------------------------------------- ?PR?_beep?MAIN
_beep:
			; SOURCE LINE # 674
			; SOURCE LINE # 675
			; SOURCE LINE # 676
	MOV  	A,R7
	JNZ  	?C0032
			; SOURCE LINE # 677
	CLR  	ET0
			; SOURCE LINE # 678
	MOV  	buz_left,A
			; SOURCE LINE # 679
	SETB 	buz_quiet
			; SOURCE LINE # 680
	SETB 	ET0
	RET
			; SOURCE LINE # 682
?C0032:
			; SOURCE LINE # 683
	CLR  	ET0
			; SOURCE LINE # 684
	MOV  	buz_left,R7
			; SOURCE LINE # 685
	CLR  	buz_quiet
			; SOURCE LINE # 686
	SETB 	ET0
			; SOURCE LINE # 687
?C0033:
	RET
; END OF _beep

;--------------------------------------------------------------- ?PR?_motor_set_core?MAIN
L?0422:
	USING	0
	MOV  	avst,#02H
L?0423:
	CLR  	A
L?0424:
	MOV  	cur_act,A
	MOV  	R5,A
	MOV  	R7,A
_motor_set_core:
	USING	0
			; SOURCE LINE # 808
			; SOURCE LINE # 809
			; SOURCE LINE # 810
	MOV  	A,R5
	JNZ  	?C0034
			; SOURCE LINE # 811
			; SOURCE LINE # 812
			; SOURCE LINE # 813
	SJMP 	?C0391
			; SOURCE LINE # 815
?C0034:
			; SOURCE LINE # 819
	MOV  	A,avst
	CJNE 	A,#04H,?C0036
			; SOURCE LINE # 820
	MOV  	R7,#06H
			; SOURCE LINE # 821
	SJMP 	?C0037
?C0036:
			; SOURCE LINE # 823
	MOV  	A,avst
	CJNE 	A,#01H,?C0038
			; SOURCE LINE # 824
	MOV  	R7,#04H
			; SOURCE LINE # 825
	SJMP 	?C0037
?C0038:
	MOV  	A,avst
	CJNE 	A,#02H,?C0037
			; SOURCE LINE # 826
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 829
?C0390:
			; SOURCE LINE # 830
			; SOURCE LINE # 831
	SJMP 	?C0391
			; SOURCE LINE # 833
?C0037:
			; SOURCE LINE # 838
	CJNE 	R7,#02H,?C0041
	MOV  	A,R5
	SETB 	C
	SUBB 	A,#02H
	JC   	?C0041
			; SOURCE LINE # 839
	MOV  	R5,#02H
?C0041:
			; SOURCE LINE # 841
	MOV  	A,R5
	MOV  	DPTR,#duty_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 842
	MOV  	duty_b,duty_a
			; SOURCE LINE # 847
	CJNE 	R7,#05H,?C0042
			; SOURCE LINE # 848
	MOV  	A,R5
	MOV  	DPTR,#arc_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 849
	SJMP 	?C0393
			; SOURCE LINE # 851
?C0042:
			; SOURCE LINE # 852
	CJNE 	R7,#06H,?C0043
			; SOURCE LINE # 853
	MOV  	A,R5
	MOV  	DPTR,#arc_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_b,A
			; SOURCE LINE # 854
?C0392:
	SJMP 	?C0393
			; SOURCE LINE # 856
?C0043:
			; SOURCE LINE # 858
	MOV  	A,R7
	ADD  	A,#0FEH
	JZ   	?C0046
	DEC  	A
	JZ   	?C0047
	DEC  	A
	JZ   	?C0048
	ADD  	A,#03H
	JNZ  	?C0049
			; SOURCE LINE # 859
?C0045:
?C0393:
	MOV  	dirbits,#05H
	RET
			; SOURCE LINE # 860
?C0046:
	MOV  	dirbits,#0AH
	RET
			; SOURCE LINE # 861
?C0047:
	MOV  	dirbits,#06H
	RET
			; SOURCE LINE # 862
?C0048:
	MOV  	dirbits,#09H
	RET
			; SOURCE LINE # 863
?C0049:
			; SOURCE LINE # 864
	CLR  	A
?C0391:
	MOV  	dirbits,A
			; SOURCE LINE # 865
	MOV  	duty_a,A
			; SOURCE LINE # 866
	MOV  	duty_b,A
			; SOURCE LINE # 867
			; SOURCE LINE # 868
			; SOURCE LINE # 869
?C0035:
	RET
; END OF _motor_set_core

;--------------------------------------------------------------- ?PR?_d3_mix?MAIN
_d3_mix:
	USING	0
			; SOURCE LINE # 916
	MOV  	seg?647,R7
			; SOURCE LINE # 917
			; SOURCE LINE # 918
	LCALL	avoid_off
	MOV  	A,seg?647
	JC   	?C0050
			; SOURCE LINE # 919
	ANL  	A,#0FEH
	MOV  	R7,A
	RET
?C0050:
			; SOURCE LINE # 920
	ORL  	A,#01H
	MOV  	R7,A
			; SOURCE LINE # 921
?C0051:
	RET
; END OF _d3_mix

;--------------------------------------------------------------- ?PR?avoid_off?MAIN
avoid_off:
			; SOURCE LINE # 928
			; SOURCE LINE # 929
			; SOURCE LINE # 930
	JNB  	recon,?C0052
			; SOURCE LINE # 931
	SETB 	C
	RET
?C0052:
			; SOURCE LINE # 932
	JNB  	us_avoid_on,?C0054
			; SOURCE LINE # 933
	CLR  	C
	RET
?C0054:
			; SOURCE LINE # 934
	SETB 	C
			; SOURCE LINE # 935
?C0053:
	RET
; END OF avoid_off

;--------------------------------------------------------------- ?PR?apply_gear_core?MAIN
apply_gear_core:
	USING	0
			; SOURCE LINE # 943
			; SOURCE LINE # 944
			; SOURCE LINE # 945
	MOV  	A,gear
	JZ   	?apply_gear_core?stop
			; SOURCE LINE # 946
?C0055:
			; SOURCE LINE # 949
	MOV  	A,avst
	XRL  	A,#02H
	JZ   	?apply_gear_core?stop
			; SOURCE LINE # 950
?C0057:
			; SOURCE LINE # 954
	MOV  	cur_act,#01H
			; SOURCE LINE # 956
	MOV  	A,gear
	MOV  	DPTR,#duty_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 957
	MOV  	duty_b,duty_a
			; SOURCE LINE # 958
	MOV  	dirbits,#05H
			; SOURCE LINE # 960
	SJMP 	?C0394
			; SOURCE LINE # 963
?apply_gear_core?stop:
			; SOURCE LINE # 964
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 965
	MOV  	duty_a,A
			; SOURCE LINE # 966
	MOV  	duty_b,A
			; SOURCE LINE # 967
	MOV  	dirbits,A
			; SOURCE LINE # 968
?C0394:
	MOV  	A,gear
	MOV  	DPTR,#gear_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 969
?C0058:
	RET
; END OF apply_gear_core

;--------------------------------------------------------------- ?PR?show_state?MAIN
L?0427:
	USING	0
	MOV  	R7,cur_act
	LCALL	_motor_set_core
show_state:
	USING	0
			; SOURCE LINE # 986
			; SOURCE LINE # 987
			; SOURCE LINE # 988
	JNB  	recon,?C0059
	MOV  	R7,#0F5H
	SJMP 	?C0060
?C0059:
	MOV  	A,gear
	MOV  	DPTR,#gear_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
?C0060:
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 989
	RET
; END OF show_state

;--------------------------------------------------------------- ?PR?show_mode?MAIN
show_mode:
	USING	0
			; SOURCE LINE # 992
			; SOURCE LINE # 993
			; SOURCE LINE # 994
	MOV  	A,mode
	JNZ  	?C0062
			; SOURCE LINE # 995
	LJMP 	show_state
			; SOURCE LINE # 997
?C0062:
			; SOURCE LINE # 999
	MOV  	A,mode
	MOV  	DPTR,#mode_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 1000
?C0063:
	RET
; END OF show_mode

;--------------------------------------------------------------- ?PR?key_scan?MAIN
key_scan:
	USING	0
			; SOURCE LINE # 1009
			; SOURCE LINE # 1010
			; SOURCE LINE # 1013
	MOV  	A,klast
	JZ   	?C0064
			; SOURCE LINE # 1014
	XRL  	A,#02H
	JZ   	?C0066
	MOV  	A,klast
	CJNE 	A,#04H,?C0065
?C0066:
			; SOURCE LINE # 1015
	JNB  	KEY_S4,?C0068
			; SOURCE LINE # 1016
	SJMP 	?C0395
?C0065:
			; SOURCE LINE # 1017
	JNB  	KEY_S3,?C0068
?C0395:
	CLR  	A
	MOV  	klast,A
			; SOURCE LINE # 1018
?C0068:
			; SOURCE LINE # 1019
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1020
?C0064:
			; SOURCE LINE # 1022
	JB   	KEY_S3,?C0071
			; SOURCE LINE # 1023
	LCALL	d_20ms
			; SOURCE LINE # 1024
	JNB  	KEY_S3,?C0072
	MOV  	R7,#00H
	RET
?C0072:
			; SOURCE LINE # 1025
	LCALL	tick_get
	MOV  	DPH,R6
	MOV  	DPL,R7
?C0073:
			; SOURCE LINE # 1026
	JB   	KEY_S3,?C0074
			; SOURCE LINE # 1027
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,DPH
	CLR  	C
	SUBB 	A,#027H
	JC   	?C0073
			; SOURCE LINE # 1028
	MOV  	klast,#03H
			; SOURCE LINE # 1029
	MOV  	R7,#03H
	RET
			; SOURCE LINE # 1030
			; SOURCE LINE # 1031
?C0074:
			; SOURCE LINE # 1032
	MOV  	klast,#01H
			; SOURCE LINE # 1033
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1034
?C0071:
			; SOURCE LINE # 1036
	JB   	KEY_S4,?C0076
			; SOURCE LINE # 1037
	LCALL	d_20ms
			; SOURCE LINE # 1038
	JNB  	KEY_S4,?C0077
	MOV  	R7,#00H
	RET
?C0077:
			; SOURCE LINE # 1039
	LCALL	tick_get
	MOV  	DPH,R6
	MOV  	DPL,R7
?C0078:
			; SOURCE LINE # 1040
	JB   	KEY_S4,?C0079
			; SOURCE LINE # 1041
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,DPH
	CLR  	C
	SUBB 	A,#027H
	JC   	?C0078
			; SOURCE LINE # 1042
	MOV  	klast,#04H
			; SOURCE LINE # 1043
	MOV  	R7,#04H
	RET
			; SOURCE LINE # 1044
			; SOURCE LINE # 1045
?C0079:
			; SOURCE LINE # 1046
	MOV  	klast,#02H
			; SOURCE LINE # 1047
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1048
?C0076:
			; SOURCE LINE # 1050
	MOV  	R7,#00H
			; SOURCE LINE # 1051
?C0070:
	RET
; END OF key_scan

;--------------------------------------------------------------- ?PR?k_isfwd?MAIN
k_isfwd:
			; SOURCE LINE # 1057
			; SOURCE LINE # 1058
			; SOURCE LINE # 1059
	MOV  	A,cur_act
	CJNE 	A,#01H,?C0081
	SETB 	C
	RET
?C0081:
			; SOURCE LINE # 1060
	MOV  	A,cur_act
	CJNE 	A,#05H,?C0083
	SETB 	C
	RET
?C0083:
			; SOURCE LINE # 1061
	MOV  	A,cur_act
	CJNE 	A,#06H,?C0084
	SETB 	C
	RET
?C0084:
			; SOURCE LINE # 1062
	CLR  	C
			; SOURCE LINE # 1063
?C0082:
	RET
; END OF k_isfwd

;--------------------------------------------------------------- ?PR?_key2act?MAIN
_key2act:
	USING	0
			; SOURCE LINE # 1065
			; SOURCE LINE # 1066
			; SOURCE LINE # 1067
	MOV  	A,R7
	ADD  	A,#0EBH
	JZ   	?C0088
	ADD  	A,#0D5H
	JZ   	?C0095
	ADD  	A,#0FDH
	JZ   	?C0092
	DEC  	A
	JZ   	?C0089
	ADD  	A,#0FEH
	JNZ  	?C0096
			; SOURCE LINE # 1068
?C0086:
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1069
?C0088:
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1070
?C0089:
	LCALL	k_isfwd
	JNC  	?C0090
	MOV  	R7,#05H
	RET
?C0090:
	MOV  	R7,#03H
?C0091:
	RET
			; SOURCE LINE # 1071
?C0092:
	LCALL	k_isfwd
	JNC  	?C0093
	MOV  	R7,#06H
	RET
?C0093:
	MOV  	R7,#04H
?C0094:
	RET
			; SOURCE LINE # 1072
?C0095:
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1073
?C0096:
	MOV  	R7,#0FFH
			; SOURCE LINE # 1074
			; SOURCE LINE # 1075
?C0087:
	RET
; END OF _key2act

;--------------------------------------------------------------- ?PR?_key2mode?MAIN
_key2mode:
	USING	0
			; SOURCE LINE # 1081
			; SOURCE LINE # 1082
			; SOURCE LINE # 1083
	MOV  	A,R7
	ADD  	A,#0E8H
	JZ   	?C0100
	ADD  	A,#0BAH
	JZ   	?C0101
	ADD  	A,#052H
	JNZ  	?C0102
			; SOURCE LINE # 1084
?C0098:
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1085
?C0100:
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1086
?C0101:
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1087
?C0102:
	MOV  	R7,#0FFH
			; SOURCE LINE # 1088
			; SOURCE LINE # 1089
?C0099:
	RET
; END OF _key2mode

;--------------------------------------------------------------- ?PR?_mode_goto?MAIN
_mode_goto:
	USING	0
			; SOURCE LINE # 1095
			; SOURCE LINE # 1096
			; SOURCE LINE # 1097
	MOV  	mode,R7
			; SOURCE LINE # 1098
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 1100
	MOV  	A,R7
	JNZ  	?C0103
			; SOURCE LINE # 1104
	MOV  	A,gear
	JZ   	?C0104
	MOV  	R7,#01H
	SJMP 	?C0105
?C0104:
	MOV  	R7,#00H
?C0105:
	MOV  	cur_act,R7
			; SOURCE LINE # 1105
	MOV  	R5,gear
	LCALL	_motor_set_core
			; SOURCE LINE # 1106
	LCALL	show_state
			; SOURCE LINE # 1107
	SJMP 	?C0106
?C0103:
			; SOURCE LINE # 1108
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 1109
	MOV  	A,gear
	JNZ  	?C0107
			; SOURCE LINE # 1110
	MOV  	gear,#03H
?C0107:
			; SOURCE LINE # 1111
	LCALL	show_mode
			; SOURCE LINE # 1112
?C0106:
			; SOURCE LINE # 1114
	MOV  	R7,#028H
	LJMP 	_beep
; END OF _mode_goto

;--------------------------------------------------------------- ?PR?mode_switch?MAIN
mode_switch:
	USING	0
			; SOURCE LINE # 1117
			; SOURCE LINE # 1118
			; SOURCE LINE # 1119
	MOV  	m?1652,mode
			; SOURCE LINE # 1121
	MOV  	A,m?1652
	CJNE 	A,#03H,?C0109
			; SOURCE LINE # 1122
	CLR  	A
	MOV  	R7,A
	SJMP 	?C0396
			; SOURCE LINE # 1124
?C0109:
			; SOURCE LINE # 1125
	INC  	m?1652
			; SOURCE LINE # 1126
	MOV  	A,m?1652
	CLR  	C
	SUBB 	A,#03H
	JC   	?C0111
			; SOURCE LINE # 1127
	CLR  	A
	MOV  	m?1652,A
?C0111:
			; SOURCE LINE # 1128
	MOV  	R7,m?1652
?C0396:
	LCALL	_mode_goto
			; SOURCE LINE # 1129
?C0110:
	RET
; END OF mode_switch

;--------------------------------------------------------------- ?PR?light_step?MAIN
light_step:
	USING	0
			; SOURCE LINE # 1136
			; SOURCE LINE # 1137
			; SOURCE LINE # 1140
	MOV  	A,gear
	JNZ  	?C0112
			; SOURCE LINE # 1141
	MOV  	act?1753,A
			; SOURCE LINE # 1142
	SJMP 	?C0113
?C0112:
	JB   	LDR_LEFT,?C0114
			; SOURCE LINE # 1143
	JNB  	LDR_RIGHT,?C0115
	MOV  	R7,#03H
	SJMP 	?C0116
?C0115:
	MOV  	R7,#01H
?C0116:
	MOV  	act?1753,R7
			; SOURCE LINE # 1144
	SJMP 	?C0113
?C0114:
			; SOURCE LINE # 1145
	JNB  	LDR_RIGHT,?C0118
	MOV  	R7,#00H
	SJMP 	?C0119
?C0118:
	MOV  	R7,#04H
?C0119:
	MOV  	act?1753,R7
			; SOURCE LINE # 1146
?C0113:
			; SOURCE LINE # 1148
	MOV  	cur_act,act?1753
			; SOURCE LINE # 1149
	MOV  	R5,gear
	MOV  	R7,act?1753
	LCALL	_motor_set_core
			; SOURCE LINE # 1150
	LJMP 	show_mode
; END OF light_step

;--------------------------------------------------------------- ?PR?track_step?MAIN
track_step:
	USING	0
			; SOURCE LINE # 1170
			; SOURCE LINE # 1171
			; SOURCE LINE # 1172
	CLR  	A
	MOV  	R7,A
			; SOURCE LINE # 1175
	JNB  	TRACK_L,?C0121
	MOV  	R7,#02H
?C0121:
			; SOURCE LINE # 1176
	JNB  	TRACK_R,?C0122
	ORL  	AR7,#01H
?C0122:
			; SOURCE LINE # 1178
	CJNE 	R7,#01H,?C0123
	MOV  	act?1855,#04H
	SJMP 	?C0124
?C0123:
			; SOURCE LINE # 1179
	CJNE 	R7,#02H,?C0125
	MOV  	act?1855,#03H
	SJMP 	?C0124
?C0125:
			; SOURCE LINE # 1180
	MOV  	act?1855,#01H
?C0124:
			; SOURCE LINE # 1183
	MOV  	cur_act,act?1855
			; SOURCE LINE # 1184
	MOV  	R5,gear
	MOV  	R7,act?1855
	LCALL	_motor_set_core
			; SOURCE LINE # 1185
	LJMP 	show_mode
; END OF track_step

;--------------------------------------------------------------- ?PR?us_init?MAIN
us_init:
			; SOURCE LINE # 1204
			; SOURCE LINE # 1205
			; SOURCE LINE # 1206
	CLR  	ET0
			; SOURCE LINE # 1207
	CLR  	A
	MOV  	us_st,A
			; SOURCE LINE # 1208
	MOV  	us_wid,A
			; SOURCE LINE # 1209
	MOV  	us_wait,A
			; SOURCE LINE # 1210
	CLR  	us_got
			; SOURCE LINE # 1211
	MOV  	us_res,#0FFH
			; SOURCE LINE # 1212
	CLR  	us_valid
			; SOURCE LINE # 1213
	CLR  	us_seen
			; SOURCE LINE # 1214
	MOV  	us_last10,A
			; SOURCE LINE # 1215
	MOV  	us_last_d,#0FFH
			; SOURCE LINE # 1219
	CLR  	US_TRIG
			; SOURCE LINE # 1220
	SETB 	ET0
			; SOURCE LINE # 1221
	RET
; END OF us_init

;--------------------------------------------------------------- ?PR?us_trigger?MAIN
us_trigger:
			; SOURCE LINE # 1227
			; SOURCE LINE # 1228
			; SOURCE LINE # 1229
	CLR  	US_TRIG
			; SOURCE LINE # 1230
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1231
	SETB 	US_TRIG
			; SOURCE LINE # 1232
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1233
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1234
	CLR  	US_TRIG
			; SOURCE LINE # 1236
	CLR  	A
	MOV  	us_wid,A
			; SOURCE LINE # 1237
	MOV  	us_wait,A
			; SOURCE LINE # 1238
	MOV  	us_st,#01H
			; SOURCE LINE # 1239
	RET
; END OF us_trigger

;--------------------------------------------------------------- ?PR?us_read?MAIN
us_read:
	USING	0
			; SOURCE LINE # 1243
			; SOURCE LINE # 1244
			; SOURCE LINE # 1245
	MOV  	R6,ms10_l
			; SOURCE LINE # 1250
	JNB  	us_got,?C0130
			; SOURCE LINE # 1251
	CLR  	ET0
			; SOURCE LINE # 1252
	MOV  	us_last_d,us_res
			; SOURCE LINE # 1253
	CLR  	us_got
			; SOURCE LINE # 1254
	SETB 	us_valid
			; SOURCE LINE # 1255
	SETB 	ET0
			; SOURCE LINE # 1256
?C0130:
			; SOURCE LINE # 1259
	MOV  	A,us_st
	JZ   	?C0131
			; SOURCE LINE # 1260
	JNB  	us_valid,?C0132
	MOV  	R7,us_last_d
	RET
?C0132:
	MOV  	R7,#0FFH
?C0133:
	RET
?C0131:
			; SOURCE LINE # 1264
	JNB  	us_seen,?C0135
	CLR  	C
	MOV  	A,R6
	SUBB 	A,us_last10
	CLR  	C
	SUBB 	A,#06H
	JNC  	?C0135
			; SOURCE LINE # 1265
	JNB  	us_valid,?C0136
	MOV  	R7,us_last_d
	RET
?C0136:
	MOV  	R7,#0FFH
?C0137:
	RET
?C0135:
			; SOURCE LINE # 1268
	MOV  	us_last10,R6
			; SOURCE LINE # 1269
	SETB 	us_seen
			; SOURCE LINE # 1270
	LCALL	us_trigger
			; SOURCE LINE # 1271
	JNB  	us_valid,?C0138
	MOV  	R7,us_last_d
	SJMP 	?C0139
?C0138:
	MOV  	R7,#0FFH
?C0139:
			; SOURCE LINE # 1272
?C0134:
	RET
; END OF us_read

;--------------------------------------------------------------- ?PR?ir_det?MAIN
ir_det:
			; SOURCE LINE # 1282
			; SOURCE LINE # 1283
			; SOURCE LINE # 1284
	MOV  	A,ir_inv
	JZ   	?C0140
			; SOURCE LINE # 1285
	JNB  	IR_AVOID,?C0141
	SETB 	C
	RET
?C0141:
			; SOURCE LINE # 1286
	CLR  	C
	RET
			; SOURCE LINE # 1287
?C0140:
			; SOURCE LINE # 1288
	JNB  	IR_AVOID,?C0143
	CLR  	C
	RET
?C0143:
			; SOURCE LINE # 1289
	SETB 	C
			; SOURCE LINE # 1290
?C0142:
	RET
; END OF ir_det

;--------------------------------------------------------------- ?PR?ir_brake?MAIN
ir_brake:
	USING	0
			; SOURCE LINE # 1325
			; SOURCE LINE # 1326
			; SOURCE LINE # 1327
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0145
?C0144:
			; SOURCE LINE # 1330
			; SOURCE LINE # 1331
			; SOURCE LINE # 1332
	LCALL	L?0422
			; SOURCE LINE # 1333
	LCALL	show_mode
			; SOURCE LINE # 1334
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1335
	CLR  	A
	MOV  	av_beep_n,A
			; SOURCE LINE # 1340
?C0145:
	RET
; END OF ir_brake

;--------------------------------------------------------------- ?PR?av_gate_hold?MAIN
av_gate_hold:
	USING	0
			; SOURCE LINE # 1348
			; SOURCE LINE # 1349
			; SOURCE LINE # 1350
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0147
?C0146:
			; SOURCE LINE # 1353
	MOV  	A,mode
	CJNE 	A,#01H,?C0148
			; SOURCE LINE # 1356
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 1357
	MOV  	avst,#03H
			; SOURCE LINE # 1358
			; SOURCE LINE # 1359
	LCALL	L?0424
			; SOURCE LINE # 1360
	LCALL	show_mode
			; SOURCE LINE # 1361
	SJMP 	?C0397
			; SOURCE LINE # 1363
?C0148:
			; SOURCE LINE # 1366
			; SOURCE LINE # 1367
			; SOURCE LINE # 1368
	LCALL	L?0422
			; SOURCE LINE # 1369
	LCALL	show_mode
			; SOURCE LINE # 1371
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1375
	MOV  	A,av_beep_n
	JNZ  	?C0147
			; SOURCE LINE # 1376
	MOV  	av_beep_n,#01H
			; SOURCE LINE # 1378
?C0397:
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 1379
			; SOURCE LINE # 1380
?C0147:
	RET
; END OF av_gate_hold

;--------------------------------------------------------------- ?PR?av_gate?MAIN
av_gate:
	USING	0
			; SOURCE LINE # 1392
			; SOURCE LINE # 1393
			; SOURCE LINE # 1422
	LCALL	avoid_off
	JNC  	?C0150
	MOV  	A,avst
	CJNE 	A,#02H,?C0150
			; SOURCE LINE # 1423
	CLR  	A
	MOV  	avst,A
?C0150:
			; SOURCE LINE # 1428
	MOV  	A,avst
	XRL  	A,#02H
	JNZ  	?C0151
			; SOURCE LINE # 1430
	LCALL	ir_det
	JNC  	$ + 5H
	LJMP 	?C0153
?C0152:
			; SOURCE LINE # 1442
	MOV  	A,mode
	CJNE 	A,#02H,?C0154
			; SOURCE LINE # 1443
	SJMP 	?C0398
			; SOURCE LINE # 1445
?C0154:
			; SOURCE LINE # 1448
	LCALL	avoid_off
	JNC  	$ + 5H
	LJMP 	?C0153
?C0155:
			; SOURCE LINE # 1452
	LCALL	us_read
	MOV  	A,R7
	CLR  	C
	SUBB 	A,#07H
	JC   	?C0156
			; SOURCE LINE # 1453
	JB   	av_clear_on,?C0157
			; SOURCE LINE # 1454
	SETB 	av_clear_on
			; SOURCE LINE # 1455
	LCALL	tick_get
	MOV  	av_clear_t,R6
	MOV  	av_clear_t+01H,R7
	RET
			; SOURCE LINE # 1457
?C0157:
			; SOURCE LINE # 1458
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,av_clear_t+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,av_clear_t
	MOV  	R6,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#088H
	MOV  	A,R6
	SUBB 	A,#013H
	JNC  	$ + 5H
	LJMP 	?C0153
			; SOURCE LINE # 1459
	CLR  	A
	MOV  	av_beep_n,A
	RET
			; SOURCE LINE # 1461
?C0156:
			; SOURCE LINE # 1462
	CLR  	av_clear_on
			; SOURCE LINE # 1465
	MOV  	A,av_beep_n
	CLR  	C
	SUBB 	A,#03H
	JC   	$ + 5H
	LJMP 	?C0153
?C0159:
			; SOURCE LINE # 1467
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,av_beep_t+01H
	MOV  	A,R6
	SUBB 	A,av_beep_t
	CLR  	C
	SUBB 	A,#01BH
	JNC  	$ + 5H
	LJMP 	?C0153
			; SOURCE LINE # 1468
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1469
	INC  	av_beep_n
			; SOURCE LINE # 1471
	MOV  	R7,#018H
	LJMP 	_beep
			; SOURCE LINE # 1472
			; SOURCE LINE # 1475
?C0151:
			; SOURCE LINE # 1479
	LCALL	ir_det
	JNC  	?C0161
			; SOURCE LINE # 1480
	LJMP 	ir_brake
			; SOURCE LINE # 1482
?C0161:
			; SOURCE LINE # 1488
	MOV  	A,mode
	CJNE 	A,#02H,?C0162
			; SOURCE LINE # 1489
?C0398:
	CLR  	A
	MOV  	avst,A
	RET
			; SOURCE LINE # 1491
?C0162:
			; SOURCE LINE # 1497
	MOV  	A,cur_act
	CJNE 	A,#02H,?C0163
			; SOURCE LINE # 1498
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1499
	MOV  	R5,gear
	MOV  	R7,#02H
	SJMP 	?C0401
			; SOURCE LINE # 1501
?C0163:
			; SOURCE LINE # 1505
	LCALL	avoid_off
	JNC  	?C0164
			; SOURCE LINE # 1506
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1507
	MOV  	A,cur_act
	JZ   	?C0153
	MOV  	R5,gear
	MOV  	R7,A
?C0399:
	SJMP 	?C0401
			; SOURCE LINE # 1509
?C0164:
			; SOURCE LINE # 1511
	LCALL	us_read
	MOV  	d?2557,R7
			; SOURCE LINE # 1515
	MOV  	A,d?2557
	CLR  	C
	SUBB 	A,#03H
	JNC  	?C0166
			; SOURCE LINE # 1516
	LJMP 	av_gate_hold
			; SOURCE LINE # 1518
?C0166:
			; SOURCE LINE # 1528
	MOV  	A,avst
	XRL  	A,#04H
	JZ   	?C0168
	MOV  	A,avst
	CJNE 	A,#01H,?C0167
?C0168:
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,av_clear_t+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,av_clear_t
	MOV  	R6,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0F0H
	MOV  	A,R6
	SUBB 	A,#0AH
	JNC  	?C0167
			; SOURCE LINE # 1529
	MOV  	A,cur_act
	JZ   	?C0153
?C0169:
			; SOURCE LINE # 1530
	MOV  	R5,gear
	MOV  	R7,cur_act
?C0400:
	SJMP 	?C0401
			; SOURCE LINE # 1532
?C0167:
			; SOURCE LINE # 1535
	LCALL	tick_get
	MOV  	av_clear_t,R6
	MOV  	av_clear_t+01H,R7
			; SOURCE LINE # 1536
	MOV  	A,d?2557
	CLR  	C
	SUBB 	A,#07H
	JNC  	?C0170
			; SOURCE LINE # 1537
	MOV  	avst,#01H
	SJMP 	?C0171
?C0170:
			; SOURCE LINE # 1538
	MOV  	A,d?2557
	CLR  	C
	SUBB 	A,#0CH
	JNC  	?C0172
			; SOURCE LINE # 1539
	MOV  	avst,#04H
	SJMP 	?C0171
?C0172:
			; SOURCE LINE # 1541
	CLR  	A
	MOV  	avst,A
?C0171:
			; SOURCE LINE # 1555
	MOV  	A,cur_act
	JZ   	?C0153
?C0174:
			; SOURCE LINE # 1556
	MOV  	R5,gear
	MOV  	R7,cur_act
?C0401:
	LCALL	_motor_set_core
			; SOURCE LINE # 1557
?C0153:
	RET
; END OF av_gate

;--------------------------------------------------------------- ?PR?avoid_toggle?MAIN
avoid_toggle:
	USING	0
			; SOURCE LINE # 1566
			; SOURCE LINE # 1567
			; SOURCE LINE # 1568
	CPL  	us_avoid_on
			; SOURCE LINE # 1571
	JNB  	us_avoid_on,?C0175
			; SOURCE LINE # 1572
			; SOURCE LINE # 1573
	LCALL	L?0420
			; SOURCE LINE # 1574
	LCALL	d_20ms
			; SOURCE LINE # 1575
	MOV  	R7,#018H
			; SOURCE LINE # 1576
	SJMP 	?C0402
?C0175:
			; SOURCE LINE # 1577
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1578
	MOV  	R7,#028H
?C0402:
	LCALL	_beep
			; SOURCE LINE # 1579
?C0176:
			; SOURCE LINE # 1583
	LJMP 	show_mode
; END OF avoid_toggle

;--------------------------------------------------------------- ?PR?meas_level?MAIN
meas_level:
	USING	0
			; SOURCE LINE # 1597
			; SOURCE LINE # 1598
			; SOURCE LINE # 1603
	CLR  	ET0
			; SOURCE LINE # 1604
	MOV  	R5,tick_h
			; SOURCE LINE # 1605
	MOV  	R4,tick_l
			; SOURCE LINE # 1606
	SETB 	ET0
			; SOURCE LINE # 1608
	MOV  	A,R5
	MOV  	R6,A
	MOV  	A,R4
	MOV  	R3,A
	MOV  	R2,AR6
			; SOURCE LINE # 1610
?C0178:
			; SOURCE LINE # 1611
	CLR  	ET0
			; SOURCE LINE # 1612
	MOV  	R5,tick_h
			; SOURCE LINE # 1613
	MOV  	R4,tick_l
			; SOURCE LINE # 1614
	SETB 	ET0
			; SOURCE LINE # 1615
	MOV  	A,R5
	MOV  	R6,A
	MOV  	A,R4
	MOV  	DPL,A
	MOV  	A,DPL
	CLR  	C
	SUBB 	A,R3
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,R2
	MOV  	R6,A
			; SOURCE LINE # 1617
	MOV  	A,ml_cap
	JZ   	?C0180
			; SOURCE LINE # 1618
	MOV  	DPL,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0183
			; SOURCE LINE # 1619
			; SOURCE LINE # 1620
	SJMP 	?C0403
			; SOURCE LINE # 1621
			; SOURCE LINE # 1622
?C0180:
			; SOURCE LINE # 1623
	SETB 	C
	MOV  	A,R7
	SUBB 	A,#0FFH
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0183
			; SOURCE LINE # 1624
?C0403:
	MOV  	ml_dur,R6
	MOV  	ml_dur+01H,R7
			; SOURCE LINE # 1625
	SETB 	C
	RET
			; SOURCE LINE # 1626
			; SOURCE LINE # 1627
?C0183:
			; SOURCE LINE # 1629
	MOV  	A,ml_level
	JZ   	?C0185
			; SOURCE LINE # 1630
	JB   	IR_IN,?C0178
			; SOURCE LINE # 1631
			; SOURCE LINE # 1632
	SJMP 	?C0404
			; SOURCE LINE # 1633
			; SOURCE LINE # 1634
?C0185:
			; SOURCE LINE # 1635
	JNB  	IR_IN,?C0178
			; SOURCE LINE # 1636
?C0404:
	MOV  	ml_dur,R6
	MOV  	ml_dur+01H,R7
			; SOURCE LINE # 1637
	CLR  	C
			; SOURCE LINE # 1638
			; SOURCE LINE # 1639
			; SOURCE LINE # 1640
			; SOURCE LINE # 1641
?C0182:
	RET
; END OF meas_level

;--------------------------------------------------------------- ?PR?ir_reset?MAIN
ir_reset:
			; SOURCE LINE # 1659
			; SOURCE LINE # 1660
			; SOURCE LINE # 1661
	CLR  	A
	MOV  	ml_cap,A
			; SOURCE LINE # 1662
	MOV  	ir_ledlo,A
			; SOURCE LINE # 1663
	MOV  	ir_ledhi,A
			; SOURCE LINE # 1664
	CLR  	ir_short
			; SOURCE LINE # 1665
	MOV  	irstat,#01H
			; SOURCE LINE # 1666
	RET
; END OF ir_reset

;--------------------------------------------------------------- ?PR?_ir_setbit?MAIN
_ir_setbit:
			; SOURCE LINE # 1669
			; SOURCE LINE # 1670
			; SOURCE LINE # 1671
	MOV  	A,R7
	DEC  	A
	JZ   	?C0192
	DEC  	A
	JZ   	?C0193
	ADD  	A,#02H
	JNZ  	?C0194
			; SOURCE LINE # 1672
?C0191:
	MOV  	A,ir_maskb
	ORL  	ir_ib0,A
	RET
			; SOURCE LINE # 1673
?C0192:
	MOV  	A,ir_maskb
	ORL  	ir_ib1,A
	RET
			; SOURCE LINE # 1674
?C0193:
	MOV  	A,ir_maskb
	ORL  	ir_ib2,A
	RET
			; SOURCE LINE # 1675
?C0194:
	MOV  	A,ir_maskb
	ORL  	ir_ib3,A
			; SOURCE LINE # 1676
			; SOURCE LINE # 1677
?C0195:
	RET
; END OF _ir_setbit

;--------------------------------------------------------------- ?PR?ir_decode_bits?MAIN
ir_decode_bits:
	USING	0
			; SOURCE LINE # 1680
			; SOURCE LINE # 1681
			; SOURCE LINE # 1682
	CLR  	A
	MOV  	ir_ib0,A
			; SOURCE LINE # 1683
	MOV  	ir_ib1,A
			; SOURCE LINE # 1684
	MOV  	ir_ib2,A
			; SOURCE LINE # 1685
	MOV  	ir_ib3,A
			; SOURCE LINE # 1686
	MOV  	ir_bits,#020H
			; SOURCE LINE # 1687
	MOV  	ir_ptridx,A
			; SOURCE LINE # 1688
	MOV  	ir_maskb,#01H
?C0196:
			; SOURCE LINE # 1690
			; SOURCE LINE # 1692
	CLR  	A
	MOV  	ml_level,A
			; SOURCE LINE # 1693
	MOV  	ml_cap,A
			; SOURCE LINE # 1694
	LCALL	meas_level
	JNC  	?C0198
			; SOURCE LINE # 1695
	CLR  	C
	RET
?C0198:
			; SOURCE LINE # 1698
	MOV  	ml_level,#01H
			; SOURCE LINE # 1699
	MOV  	A,ir_bits
	CJNE 	A,#01H,?C0200
			; SOURCE LINE # 1702
	MOV  	ml_cap,#0CH
			; SOURCE LINE # 1703
	LCALL	meas_level
	JNC  	?C0202
			; SOURCE LINE # 1704
			; SOURCE LINE # 1705
	SJMP 	?C0405
?C0200:
			; SOURCE LINE # 1706
	CLR  	A
	MOV  	ml_cap,A
			; SOURCE LINE # 1707
	LCALL	meas_level
	JNC  	?C0203
			; SOURCE LINE # 1708
	CLR  	C
	RET
?C0203:
			; SOURCE LINE # 1709
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0BH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0202
			; SOURCE LINE # 1710
?C0405:
	MOV  	R7,ir_ptridx
	LCALL	_ir_setbit
			; SOURCE LINE # 1711
?C0202:
			; SOURCE LINE # 1714
	MOV  	A,ir_maskb
	ADD  	A,ACC
	MOV  	ir_maskb,A
			; SOURCE LINE # 1715
	JNZ  	?C0205
			; SOURCE LINE # 1716
	MOV  	ir_maskb,#01H
			; SOURCE LINE # 1717
	INC  	ir_ptridx
			; SOURCE LINE # 1718
?C0205:
			; SOURCE LINE # 1719
	DJNZ 	ir_bits,?C0196
			; SOURCE LINE # 1720
?C0197:
			; SOURCE LINE # 1723
	MOV  	A,ir_ib0
	CPL  	A
	XRL  	A,ir_ib1
	JZ   	?C0206
	CLR  	C
	RET
?C0206:
			; SOURCE LINE # 1724
	MOV  	A,ir_ib2
	CPL  	A
	XRL  	A,ir_ib3
	JZ   	?C0207
	CLR  	C
	RET
?C0207:
			; SOURCE LINE # 1725
	SETB 	C
			; SOURCE LINE # 1726
?C0199:
	RET
; END OF ir_decode_bits

;--------------------------------------------------------------- ?PR?ir_decode?MAIN
ir_decode:
	USING	0
			; SOURCE LINE # 1729
			; SOURCE LINE # 1730
			; SOURCE LINE # 1732
	CLR  	A
	MOV  	ml_level,A
			; SOURCE LINE # 1733
	MOV  	ml_cap,A
			; SOURCE LINE # 1734
	LCALL	meas_level
	JNC  	?C0208
			; SOURCE LINE # 1735
	SJMP 	?C0408
			; SOURCE LINE # 1737
?C0208:
			; SOURCE LINE # 1738
	MOV  	ir_ledlo,ml_dur+01H
			; SOURCE LINE # 1739
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0FFH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0210
			; SOURCE LINE # 1740
?C0406:
	SJMP 	?C0408
			; SOURCE LINE # 1742
?C0210:
			; SOURCE LINE # 1743
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#046H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0212
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#078H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0211
?C0212:
			; SOURCE LINE # 1744
?C0407:
	SJMP 	?C0408
			; SOURCE LINE # 1746
?C0211:
			; SOURCE LINE # 1753
	MOV  	ml_level,#01H
			; SOURCE LINE # 1754
	MOV  	ml_cap,#03CH
			; SOURCE LINE # 1755
	LCALL	meas_level
	JNC  	?C0213
			; SOURCE LINE # 1756
	MOV  	ir_ledhi,ml_dur+01H
			; SOURCE LINE # 1757
	SJMP 	?C0409
			; SOURCE LINE # 1759
?C0213:
			; SOURCE LINE # 1760
	MOV  	ir_ledhi,ml_dur+01H
			; SOURCE LINE # 1761
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0FFH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0214
			; SOURCE LINE # 1762
?C0409:
	MOV  	irstat,#03H
	RET
			; SOURCE LINE # 1764
?C0214:
			; SOURCE LINE # 1765
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0CH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JNC  	?C0215
			; SOURCE LINE # 1766
?C0408:
	MOV  	irstat,#02H
	RET
			; SOURCE LINE # 1768
?C0215:
			; SOURCE LINE # 1769
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#019H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JNC  	?C0216
			; SOURCE LINE # 1770
	SETB 	ir_short
?C0216:
			; SOURCE LINE # 1773
	LCALL	ir_decode_bits
	JNC  	?C0217
			; SOURCE LINE # 1774
	CLR  	A
	MOV  	irstat,A
	RET
			; SOURCE LINE # 1776
?C0217:
			; SOURCE LINE # 1779
	JNB  	ir_short,?C0218
	MOV  	R7,#03H
	SJMP 	?C0219
?C0218:
	MOV  	R7,#02H
?C0219:
	MOV  	irstat,R7
			; SOURCE LINE # 1780
?C0209:
	RET
; END OF ir_decode

;--------------------------------------------------------------- ?PR?ir_recv?MAIN
ir_recv:
	USING	0
			; SOURCE LINE # 1787
			; SOURCE LINE # 1788
			; SOURCE LINE # 1791
	LCALL	ir_reset
			; SOURCE LINE # 1794
	LCALL	tick_get
	MOV  	R3,AR7
	MOV  	R2,AR6
?C0220:
			; SOURCE LINE # 1795
	JNB  	IR_IN,?C0221
			; SOURCE LINE # 1796
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,R3
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,R2
	MOV  	R6,A
	SETB 	C
	MOV  	A,R7
	SUBB 	A,#0FFH
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0220
	RET
?C0221:
			; SOURCE LINE # 1800
	LCALL	ir_decode
			; SOURCE LINE # 1801
?C0223:
	RET
; END OF ir_recv

;--------------------------------------------------------------- ?PR?ir_recv_nb?MAIN
ir_recv_nb:
	USING	0
			; SOURCE LINE # 1808
			; SOURCE LINE # 1809
			; SOURCE LINE # 1810
	LCALL	ir_reset
			; SOURCE LINE # 1811
	JB   	IR_IN,?C0225
?C0224:
			; SOURCE LINE # 1813
	LCALL	ir_decode
			; SOURCE LINE # 1814
?C0225:
	RET
; END OF ir_recv_nb

;--------------------------------------------------------------- ?PR?stamp_now?MAIN
stamp_now:
	USING	0
			; SOURCE LINE # 1817
			; SOURCE LINE # 1818
			; SOURCE LINE # 1819
	LCALL	tick_get
	MOV  	lastt,R6
	MOV  	lastt+01H,R7
			; SOURCE LINE # 1820
	RET
; END OF stamp_now

;--------------------------------------------------------------- ?PR?ir_errpr?MAIN
ir_errpr:
			; SOURCE LINE # 1823
			; SOURCE LINE # 1824
			; SOURCE LINE # 1842
	RET
; END OF ir_errpr

;--------------------------------------------------------------- ?PR?do_key?MAIN
do_key:
	USING	0
			; SOURCE LINE # 1847
			; SOURCE LINE # 1848
			; SOURCE LINE # 1854
	MOV  	A,avst
	CJNE 	A,#02H,?C0228
			; SOURCE LINE # 1855
	MOV  	avst,#03H
?C0228:
			; SOURCE LINE # 1859
	MOV  	A,ir_ib2
	CJNE 	A,#042H,?C0229
	LJMP 	rec_key
?C0229:
			; SOURCE LINE # 1860
	MOV  	A,ir_ib2
	CJNE 	A,#04AH,?C0231
	LJMP 	clr_key
?C0231:
			; SOURCE LINE # 1861
	MOV  	A,ir_ib2
	CJNE 	A,#052H,?C0232
	LJMP 	play_key
?C0232:
			; SOURCE LINE # 1869
	MOV  	A,ir_ib2
	CJNE 	A,#01CH,?C0233
			; SOURCE LINE # 1870
	LJMP 	avoid_toggle
			; SOURCE LINE # 1872
?C0233:
			; SOURCE LINE # 1875
	MOV  	R7,ir_ib2
	LCALL	_key2mode
	MOV  	R4,AR7
			; SOURCE LINE # 1876
	MOV  	A,R4
	CPL  	A
	JZ   	?C0234
			; SOURCE LINE # 1877
	JNB  	recon,?C0235
			; SOURCE LINE # 1880
			; SOURCE LINE # 1881
	LCALL	L?0420
			; SOURCE LINE # 1882
	SJMP 	?C0413
			; SOURCE LINE # 1884
?C0235:
			; SOURCE LINE # 1885
	MOV  	A,R4
	CJNE 	A,mode,?C0236
			; SOURCE LINE # 1886
?C0410:
	SJMP 	?C0413
			; SOURCE LINE # 1888
?C0236:
			; SOURCE LINE # 1889
	MOV  	R7,AR4
	LJMP 	_mode_goto
			; SOURCE LINE # 1891
?C0234:
			; SOURCE LINE # 1894
	MOV  	A,ir_ib2
	CJNE 	A,#05AH,?C0237
			; SOURCE LINE # 1895
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0230
?C0238:
			; SOURCE LINE # 1897
	INC  	gear
			; SOURCE LINE # 1898
	SJMP 	?C0239
?C0237:
	MOV  	A,ir_ib2
	CJNE 	A,#08H,?C0240
			; SOURCE LINE # 1899
	MOV  	A,gear
	JZ   	?C0230
?C0241:
			; SOURCE LINE # 1901
	DEC  	gear
			; SOURCE LINE # 1902
	SJMP 	?C0239
?C0240:
			; SOURCE LINE # 1906
	MOV  	R7,ir_ib2
	LCALL	_key2act
			; SOURCE LINE # 1908
	MOV  	A,R7
	CPL  	A
	JZ   	?C0230
			; SOURCE LINE # 1911
?C0243:
			; SOURCE LINE # 1913
	MOV  	A,R7
	JNZ  	?C0244
			; SOURCE LINE # 1914
	MOV  	cur_act,A
			; SOURCE LINE # 1915
	MOV  	R5,A
	MOV  	R7,A
			; SOURCE LINE # 1916
	SJMP 	?C0412
?C0244:
			; SOURCE LINE # 1917
	MOV  	A,gear
	JNZ  	?C0246
			; SOURCE LINE # 1918
	MOV  	gear,#03H
?C0246:
			; SOURCE LINE # 1919
	MOV  	cur_act,R7
			; SOURCE LINE # 1920
	MOV  	R5,gear
?C0412:
	LCALL	_motor_set_core
			; SOURCE LINE # 1921
?C0245:
			; SOURCE LINE # 1923
	LCALL	show_state
			; SOURCE LINE # 1925
?C0411:
	SJMP 	?C0413
			; SOURCE LINE # 1927
?C0239:
			; SOURCE LINE # 1930
	MOV  	A,cur_act
	JZ   	?C0247
			; SOURCE LINE # 1931
	MOV  	R5,gear
	MOV  	R7,A
	LCALL	_motor_set_core
?C0247:
			; SOURCE LINE # 1932
	LCALL	show_state
			; SOURCE LINE # 1933
?C0413:
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 1935
?C0230:
	RET
; END OF do_key

;--------------------------------------------------------------- ?PR?ir_holdchk?MAIN
ir_holdchk:
	USING	0
			; SOURCE LINE # 1945
			; SOURCE LINE # 1946
			; SOURCE LINE # 1949
	MOV  	A,cur_act
	JZ   	?C0249
?C0248:
			; SOURCE LINE # 1952
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0250
	JB   	recon,?C0250
			; SOURCE LINE # 1953
	MOV  	A,cur_act
	XRL  	A,#01H
	JZ   	?C0249
?C0251:
			; SOURCE LINE # 1955
?C0250:
			; SOURCE LINE # 1957
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,lastt+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,lastt
	MOV  	R6,A
			; SOURCE LINE # 1958
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0B8H
	MOV  	A,R6
	SUBB 	A,#0BH
	JC   	?C0249
?C0252:
			; SOURCE LINE # 1963
	JB   	recon,?C0253
	MOV  	A,cur_act
	XRL  	A,#05H
	JZ   	?C0254
	MOV  	A,cur_act
	CJNE 	A,#06H,?C0253
?C0254:
			; SOURCE LINE # 1964
	MOV  	cur_act,#01H
	SJMP 	?C0255
?C0253:
			; SOURCE LINE # 1966
	CLR  	A
	MOV  	cur_act,A
?C0255:
			; SOURCE LINE # 1968
	MOV  	A,cur_act
	JNZ  	?C0256
	MOV  	R5,A
	SJMP 	?C0257
?C0256:
	MOV  	R7,gear
	MOV  	R5,AR7
?C0257:
			; SOURCE LINE # 1969
	LCALL	L?0427
			; SOURCE LINE # 1970
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 1972
	MOV  	A,avst
	CJNE 	A,#03H,?C0249
			; SOURCE LINE # 1973
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1975
?C0249:
	RET
; END OF ir_holdchk

;--------------------------------------------------------------- ?PR?back_guard?MAIN
back_guard:
	USING	0
			; SOURCE LINE # 1982
			; SOURCE LINE # 1983
			; SOURCE LINE # 1984
	MOV  	A,mode
	JNZ  	?C0260
?C0259:
			; SOURCE LINE # 1987
	MOV  	A,cur_act
	XRL  	A,#02H
	JZ   	?C0261
			; SOURCE LINE # 1988
	CLR  	back_on
	RET
			; SOURCE LINE # 1990
?C0261:
			; SOURCE LINE # 1992
	JB   	back_on,?C0262
			; SOURCE LINE # 1993
	SETB 	back_on
			; SOURCE LINE # 1994
	LCALL	tick_get
	MOV  	back_t0,R6
	MOV  	back_t0+01H,R7
	RET
			; SOURCE LINE # 1996
?C0262:
			; SOURCE LINE # 1998
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,back_t0+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,back_t0
	MOV  	R6,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#030H
	MOV  	A,R6
	SUBB 	A,#075H
	JC   	?C0260
?C0263:
			; SOURCE LINE # 2002
	CLR  	back_on
			; SOURCE LINE # 2003
			; SOURCE LINE # 2004
	LCALL	L?0423
			; SOURCE LINE # 2005
	LCALL	show_state
			; SOURCE LINE # 2007
			; SOURCE LINE # 2008
	LCALL	L?0421
			; SOURCE LINE # 2009
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2010
?C0260:
	RET
; END OF back_guard

;--------------------------------------------------------------- ?PR?prox_beep?MAIN
prox_beep:
	USING	0
			; SOURCE LINE # 2024
			; SOURCE LINE # 2025
			; SOURCE LINE # 2028
	LCALL	avoid_off
	JC   	$ + 5H
	LJMP 	?C0265
?C0264:
			; SOURCE LINE # 2030
	MOV  	A,mode
	XRL  	A,#03H
	JNZ  	$ + 5H
	LJMP 	?C0265
	MOV  	A,mode
	XRL  	A,#02H
	JNZ  	$ + 5H
	LJMP 	?C0265
?C0266:
			; SOURCE LINE # 2034
	MOV  	A,cur_act
	CJNE 	A,#02H,?C0268
			; SOURCE LINE # 2035
	CLR  	prox_moving
			; SOURCE LINE # 2036
	CLR  	prox_hold
	RET
			; SOURCE LINE # 2038
?C0268:
			; SOURCE LINE # 2041
	MOV  	A,cur_act
	JNZ  	?C0269
			; SOURCE LINE # 2042
	JNB  	prox_moving,?C0270
			; SOURCE LINE # 2043
	CLR  	prox_moving
			; SOURCE LINE # 2044
	SETB 	prox_hold
			; SOURCE LINE # 2045
	LCALL	tick_get
	MOV  	prox_stop_t,R6
	MOV  	prox_stop_t+01H,R7
			; SOURCE LINE # 2046
?C0270:
			; SOURCE LINE # 2047
	JNB  	prox_hold,?C0271
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,prox_stop_t+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,prox_stop_t
	MOV  	R6,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#020H
	MOV  	A,R6
	SUBB 	A,#04EH
	JC   	?C0271
			; SOURCE LINE # 2048
	CLR  	prox_hold
?C0271:
			; SOURCE LINE # 2049
	JB   	prox_hold,?C0273
	RET
?C0269:
			; SOURCE LINE # 2052
	SETB 	prox_moving
			; SOURCE LINE # 2053
	CLR  	prox_hold
			; SOURCE LINE # 2054
?C0273:
			; SOURCE LINE # 2056
	LCALL	us_read
	MOV  	R6,#00H
			; SOURCE LINE # 2057
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0CH
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0265
?C0274:
			; SOURCE LINE # 2060
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#03H
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0275
	MOV  	A,cur_act
	JZ   	?C0275
			; SOURCE LINE # 2062
	MOV  	R7,#0C8H
	SJMP 	?C0414
			; SOURCE LINE # 2064
?C0275:
			; SOURCE LINE # 2070
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#03H
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0276
			; SOURCE LINE # 2071
	MOV  	R2,#03H
	MOV  	R3,#0E8H
	SJMP 	?C0277
?C0276:
			; SOURCE LINE # 2073
	MOV  	A,R7
	ADD  	A,#0FDH
	MOV  	R7,A
	MOV  	A,R7
	ADD  	A,ACC
	MOV  	R6,A
	CLR  	A
	ADD  	A,#0E8H
	MOV  	R3,A
	MOV  	A,R6
	ADDC 	A,#03H
	MOV  	R2,A
?C0277:
			; SOURCE LINE # 2074
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,prox_t+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,prox_t
	MOV  	R6,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,R3
	MOV  	A,R6
	SUBB 	A,R2
	JC   	?C0265
?C0278:
			; SOURCE LINE # 2076
	LCALL	tick_get
	MOV  	prox_t,R6
	MOV  	prox_t+01H,R7
			; SOURCE LINE # 2078
	MOV  	R7,#018H
?C0414:
	LCALL	_beep
			; SOURCE LINE # 2079
?C0265:
	RET
; END OF prox_beep

;--------------------------------------------------------------- ?PR?rec_halt?MAIN
rec_halt:
	USING	0
			; SOURCE LINE # 2092
			; SOURCE LINE # 2093
			; SOURCE LINE # 2094
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 2095
	MOV  	R5,A
	MOV  	R7,A
	LJMP 	_motor_set_core
; END OF rec_halt

;--------------------------------------------------------------- ?PR?rec_commit?MAIN
rec_commit:
	USING	0
			; SOURCE LINE # 2102
			; SOURCE LINE # 2103
			; SOURCE LINE # 2106
	MOV  	A,pack
	ANL  	A,#0F0H
	JNZ  	?C0280
	MOV  	A,recn
	JNZ  	?C0280
			; SOURCE LINE # 2107
			; SOURCE LINE # 2108
	SJMP 	?C0415
			; SOURCE LINE # 2109
?C0280:
			; SOURCE LINE # 2111
	MOV  	A,recn
	CLR  	C
	SUBB 	A,#050H
	JC   	?C0282
			; SOURCE LINE # 2112
	SETB 	recfull
			; SOURCE LINE # 2113
	RET
			; SOURCE LINE # 2114
?C0282:
			; SOURCE LINE # 2116
	MOV  	A,recn
	MOV  	R5,A
	MOV  	R4,#00H
	ADD  	A,ACC
	MOV  	R7,A
	MOV  	A,R4
	RLC  	A
	MOV  	R6,A
	MOV  	A,R7
	ADD  	A,R5
	MOV  	R7,A
	MOV  	A,R4
	ADDC 	A,R6
	MOV  	R5,AR7
	MOV  	R4,A
			; SOURCE LINE # 2117
	MOV  	DPL,R5
	MOV  	DPH,A
	MOV  	A,pack
	MOVX 	@DPTR,A
			; SOURCE LINE # 2118
	INC  	DPTR
	MOV  	A,cur_dur+01H
	MOVX 	@DPTR,A
			; SOURCE LINE # 2119
	MOV  	A,cur_dur
	MOV  	DPL,R5
	MOV  	DPH,R4
	INC  	DPTR
	INC  	DPTR
	MOVX 	@DPTR,A
			; SOURCE LINE # 2121
	INC  	recn
			; SOURCE LINE # 2122
	MOV  	A,recn
	CLR  	C
	SUBB 	A,#050H
	JC   	?C0283
			; SOURCE LINE # 2123
	SETB 	recfull
?C0283:
			; SOURCE LINE # 2125
	CLR  	A
?C0415:
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2126
	SETB 	C
			; SOURCE LINE # 2127
?C0281:
	RET
; END OF rec_commit

;--------------------------------------------------------------- ?PR?rec_err?MAIN
rec_err:
	USING	0
			; SOURCE LINE # 2130
			; SOURCE LINE # 2131
			; SOURCE LINE # 2132
	MOV  	R7,#061H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2133
			; SOURCE LINE # 2134
	LCALL	L?0421
			; SOURCE LINE # 2135
	LCALL	d_20ms
			; SOURCE LINE # 2136
			; SOURCE LINE # 2137
	LCALL	L?0421
			; SOURCE LINE # 2138
	LCALL	d_20ms
			; SOURCE LINE # 2139
	LJMP 	show_state
; END OF rec_err

;--------------------------------------------------------------- ?PR?rec_fullstop?MAIN
rec_fullstop:
	USING	0
			; SOURCE LINE # 2144
			; SOURCE LINE # 2145
			; SOURCE LINE # 2148
	CLR  	recon
			; SOURCE LINE # 2149
	CLR  	A
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2150
	LCALL	rec_halt
			; SOURCE LINE # 2152
	CLR  	A
	MOV  	i?4370,A
?C0285:
			; SOURCE LINE # 2153
	MOV  	R7,#071H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2154
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2155
	LCALL	d_20ms
			; SOURCE LINE # 2156
	INC  	i?4370
	MOV  	A,i?4370
	CLR  	C
	SUBB 	A,#014H
	JC   	?C0285
?C0286:
			; SOURCE LINE # 2157
	LJMP 	show_state
; END OF rec_fullstop

;--------------------------------------------------------------- ?PR?rec_sample?MAIN
rec_sample:
	USING	0
			; SOURCE LINE # 2166
			; SOURCE LINE # 2167
			; SOURCE LINE # 2171
	JNB  	recfull,?C0289
			; SOURCE LINE # 2172
	LJMP 	rec_fullstop
			; SOURCE LINE # 2174
?C0289:
			; SOURCE LINE # 2176
	LCALL	ms10_get
			; SOURCE LINE # 2177
	CLR  	C
	MOV  	A,R7
	SUBB 	A,samp+01H
	MOV  	R5,A
	MOV  	A,R6
	SUBB 	A,samp
	MOV  	R4,A
			; SOURCE LINE # 2178
	ORL  	A,R5
	JZ   	?C0290
?C0291:
			; SOURCE LINE # 2180
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2182
	MOV  	A,cur_act
	SWAP 	A
	ANL  	A,#0F0H
	MOV  	R7,A
	MOV  	A,gear
	ANL  	A,#0FH
	ORL  	A,R7
	MOV  	R1,A
			; SOURCE LINE # 2184
	CJNE 	A,pack,?C0292
			; SOURCE LINE # 2185
	MOV  	A,cur_dur+01H
	ADD  	A,R5
	MOV  	R7,A
	MOV  	A,cur_dur
	ADDC 	A,R4
	MOV  	R6,A
			; SOURCE LINE # 2186
	CLR  	C
	MOV  	A,R7
	SUBB 	A,cur_dur+01H
	MOV  	A,R6
	SUBB 	A,cur_dur
	JNC  	?C0293
			; SOURCE LINE # 2187
	SJMP 	?C0416
			; SOURCE LINE # 2189
?C0293:
			; SOURCE LINE # 2190
	MOV  	cur_dur,R6
	MOV  	cur_dur+01H,R7
			; SOURCE LINE # 2191
	MOV  	A,cur_dur
	CLR  	C
	SUBB 	A,#0BH
	CLR  	A
	SUBB 	A,#00H
	JC   	?C0290
			; SOURCE LINE # 2192
?C0416:
	LJMP 	rec_commit
			; SOURCE LINE # 2194
?C0292:
			; SOURCE LINE # 2197
	LCALL	rec_commit
	JNC  	?C0290
			; SOURCE LINE # 2198
	MOV  	pack,R1
			; SOURCE LINE # 2199
?C0290:
	RET
; END OF rec_sample

;--------------------------------------------------------------- ?PR?rec_enter?MAIN
rec_enter:
	USING	0
			; SOURCE LINE # 2202
			; SOURCE LINE # 2203
			; SOURCE LINE # 2204
	LCALL	rec_halt
			; SOURCE LINE # 2205
	CLR  	A
	MOV  	recn,A
			; SOURCE LINE # 2206
	CLR  	recfull
			; SOURCE LINE # 2207
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2208
	LCALL	ms10_get
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2209
	MOV  	A,gear
	ANL  	A,#0FH
	MOV  	pack,A
			; SOURCE LINE # 2210
	SETB 	recon
			; SOURCE LINE # 2211
	LCALL	show_state
			; SOURCE LINE # 2212
	MOV  	R7,#028H
	LJMP 	_beep
; END OF rec_enter

;--------------------------------------------------------------- ?PR?rec_exit?MAIN
rec_exit:
	USING	0
			; SOURCE LINE # 2216
			; SOURCE LINE # 2217
			; SOURCE LINE # 2218
	MOV  	A,cur_dur+01H
	ORL  	A,cur_dur
	JZ   	?C0297
			; SOURCE LINE # 2219
	LCALL	rec_commit
?C0297:
			; SOURCE LINE # 2220
	CLR  	recon
			; SOURCE LINE # 2221
	CLR  	A
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2222
	LCALL	show_state
			; SOURCE LINE # 2223
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2224
	LCALL	d_20ms
			; SOURCE LINE # 2225
	MOV  	R7,#028H
	LJMP 	_beep
; END OF rec_exit

;--------------------------------------------------------------- ?PR?rec_key?MAIN
rec_key:
	USING	0
			; SOURCE LINE # 2229
			; SOURCE LINE # 2230
			; SOURCE LINE # 2231
	JNB  	recon,?C0299
	LJMP 	rec_exit
?C0299:
			; SOURCE LINE # 2232
	LCALL	rec_enter
			; SOURCE LINE # 2233
?C0301:
	RET
; END OF rec_key

;--------------------------------------------------------------- ?PR?clr_key?MAIN
clr_key:
	USING	0
			; SOURCE LINE # 2237
			; SOURCE LINE # 2238
			; SOURCE LINE # 2239
	MOV  	A,mode
	XRL  	A,#03H
	JZ   	?C0303
?C0302:
			; SOURCE LINE # 2241
	MOV  	A,cur_act
	JNZ  	?C0303
?C0304:
			; SOURCE LINE # 2244
	CLR  	recon
			; SOURCE LINE # 2245
	CLR  	A
	MOV  	recn,A
			; SOURCE LINE # 2246
	CLR  	recfull
			; SOURCE LINE # 2247
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2248
	LCALL	show_state
			; SOURCE LINE # 2249
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2250
	LCALL	d_20ms
			; SOURCE LINE # 2251
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2252
?C0303:
	RET
; END OF clr_key

;--------------------------------------------------------------- ?PR?play_load?MAIN
play_load:
	USING	0
			; SOURCE LINE # 2265
			; SOURCE LINE # 2266
			; SOURCE LINE # 2267
	MOV  	A,playidx
	MOV  	R5,A
	MOV  	R4,#00H
	ADD  	A,ACC
	MOV  	R7,A
	MOV  	A,R4
	RLC  	A
	MOV  	R6,A
	MOV  	A,R7
	ADD  	A,R5
	MOV  	R7,A
	MOV  	A,R4
	ADDC 	A,R6
	MOV  	R5,AR7
	MOV  	R4,A
			; SOURCE LINE # 2268
	MOV  	DPL,R5
	MOV  	DPH,A
	MOVX 	A,@DPTR
	MOV  	R3,A
			; SOURCE LINE # 2271
	INC  	DPTR
	INC  	DPTR
	MOVX 	A,@DPTR
	MOV  	R6,A
	MOV  	DPL,R5
	MOV  	DPH,R4
	INC  	DPTR
	MOVX 	A,@DPTR
	MOV  	R5,A
	MOV  	A,R6
	MOV  	play_dur,A
	MOV  	A,R5
	MOV  	play_dur+01H,A
			; SOURCE LINE # 2273
	MOV  	A,R3
	ANL  	A,#0FH
	MOV  	gear,A
			; SOURCE LINE # 2274
	MOV  	A,R3
	SWAP 	A
	ANL  	A,#0FH
	MOV  	cur_act,A
			; SOURCE LINE # 2276
	MOV  	R5,gear
	MOV  	R7,A
	LCALL	_motor_set_core
			; SOURCE LINE # 2277
	LCALL	ms10_get
	MOV  	play_t0,R6
	MOV  	play_t0+01H,R7
			; SOURCE LINE # 2278
	RET
; END OF play_load

;--------------------------------------------------------------- ?PR?play_safety?MAIN
play_safety:
	USING	0
			; SOURCE LINE # 2285
			; SOURCE LINE # 2286
			; SOURCE LINE # 2289
	LCALL	ir_det
	JNC  	?C0306
			; SOURCE LINE # 2290
	RET
?C0306:
			; SOURCE LINE # 2292
	LCALL	ms10_get
			; SOURCE LINE # 2293
	CLR  	C
	MOV  	A,R7
	SUBB 	A,samp+01H
	MOV  	R5,A
	MOV  	A,R6
	SUBB 	A,samp
	MOV  	R4,A
	CLR  	C
	MOV  	A,R5
	SUBB 	A,#06H
	MOV  	A,R4
	SUBB 	A,#00H
	JNC  	?C0308
			; SOURCE LINE # 2294
	CLR  	C
	RET
?C0308:
			; SOURCE LINE # 2295
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2297
	LCALL	us_read
	MOV  	A,R7
	CLR  	C
	SUBB 	A,#03H
	JNC  	?C0309
			; SOURCE LINE # 2298
	RET
?C0309:
			; SOURCE LINE # 2299
	CLR  	C
			; SOURCE LINE # 2300
?C0307:
	RET
; END OF play_safety

;--------------------------------------------------------------- ?PR?play_exit?MAIN
play_exit:
	USING	0
			; SOURCE LINE # 2303
			; SOURCE LINE # 2304
			; SOURCE LINE # 2305
	LCALL	rec_halt
			; SOURCE LINE # 2306
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 2307
	MOV  	gear,play_gear0
			; SOURCE LINE # 2308
	MOV  	avst,A
			; SOURCE LINE # 2309
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2310
	MOV  	playidx,A
			; SOURCE LINE # 2311
	LJMP 	show_state
; END OF play_exit

;--------------------------------------------------------------- ?PR?play_abort?MAIN
play_abort:
	USING	0
			; SOURCE LINE # 2316
			; SOURCE LINE # 2317
			; SOURCE LINE # 2318
	SETB 	playerr
			; SOURCE LINE # 2319
	LCALL	rec_halt
			; SOURCE LINE # 2320
			; SOURCE LINE # 2321
	LCALL	L?0421
			; SOURCE LINE # 2322
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2323
	LJMP 	play_exit
; END OF play_abort

;--------------------------------------------------------------- ?PR?play_enter?MAIN
play_enter:
	USING	0
			; SOURCE LINE # 2327
			; SOURCE LINE # 2328
			; SOURCE LINE # 2329
	MOV  	A,recn
	JNZ  	?C0312
			; SOURCE LINE # 2330
	LJMP 	rec_err
			; SOURCE LINE # 2332
?C0312:
			; SOURCE LINE # 2334
	MOV  	play_gear0,gear
			; SOURCE LINE # 2337
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 2338
	MOV  	playidx,A
			; SOURCE LINE # 2339
	MOV  	cur_act,A
			; SOURCE LINE # 2340
	MOV  	mode,#03H
			; SOURCE LINE # 2341
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2342
	LCALL	play_load
			; SOURCE LINE # 2343
	LCALL	show_mode
			; SOURCE LINE # 2344
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2345
?C0313:
	RET
; END OF play_enter

;--------------------------------------------------------------- ?PR?play_step?MAIN
play_step:
	USING	0
			; SOURCE LINE # 2351
			; SOURCE LINE # 2352
			; SOURCE LINE # 2355
	LCALL	play_safety
	JNC  	?C0314
			; SOURCE LINE # 2356
	LJMP 	play_abort
			; SOURCE LINE # 2358
?C0314:
			; SOURCE LINE # 2360
	LCALL	ir_recv_nb
			; SOURCE LINE # 2361
	MOV  	A,irstat
	JNZ  	?C0316
			; SOURCE LINE # 2362
	MOV  	A,ir_ib2
	CJNE 	A,#052H,?C0317
			; SOURCE LINE # 2363
	SJMP 	?C0418
			; SOURCE LINE # 2365
?C0317:
			; SOURCE LINE # 2368
	MOV  	R7,ir_ib2
	LCALL	_key2act
	MOV  	A,R7
	CPL  	A
	JZ   	?C0316
			; SOURCE LINE # 2369
?C0417:
	SJMP 	?C0418
			; SOURCE LINE # 2371
			; SOURCE LINE # 2372
?C0316:
			; SOURCE LINE # 2375
	LCALL	ms10_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,play_t0+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,play_t0
	MOV  	R6,A
			; SOURCE LINE # 2376
	CLR  	C
	MOV  	A,R7
	SUBB 	A,play_dur+01H
	MOV  	A,R6
	SUBB 	A,play_dur
	JC   	?C0315
?C0319:
			; SOURCE LINE # 2379
	INC  	playidx
			; SOURCE LINE # 2380
	MOV  	A,playidx
	CLR  	C
	SUBB 	A,recn
	JC   	?C0320
			; SOURCE LINE # 2381
?C0418:
	LJMP 	play_exit
			; SOURCE LINE # 2383
?C0320:
			; SOURCE LINE # 2384
	LCALL	play_load
			; SOURCE LINE # 2385
?C0315:
	RET
; END OF play_step

;--------------------------------------------------------------- ?PR?play_key?MAIN
play_key:
	USING	0
			; SOURCE LINE # 2389
			; SOURCE LINE # 2390
			; SOURCE LINE # 2391
	JNB  	recon,?C0321
			; SOURCE LINE # 2392
	LCALL	rec_exit
	SJMP 	?C0322
?C0321:
			; SOURCE LINE # 2393
	MOV  	A,mode
	CJNE 	A,#03H,?C0322
			; SOURCE LINE # 2394
	LJMP 	play_exit
			; SOURCE LINE # 2396
?C0322:
			; SOURCE LINE # 2397
	LCALL	play_enter
			; SOURCE LINE # 2398
?C0324:
	RET
; END OF play_key

;--------------------------------------------------------------- ?PR?manual_step?MAIN
manual_step:
	USING	0
			; SOURCE LINE # 2403
			; SOURCE LINE # 2404
			; SOURCE LINE # 2405
	LCALL	ir_recv
			; SOURCE LINE # 2407
	MOV  	A,irstat
	JNZ  	?C0325
			; SOURCE LINE # 2408
	LCALL	stamp_now
			; SOURCE LINE # 2409
	MOV  	lastcmd,ir_ib2
			; SOURCE LINE # 2410
	LCALL	do_key
			; SOURCE LINE # 2411
	SJMP 	?C0326
?C0325:
	MOV  	A,irstat
	CJNE 	A,#03H,?C0327
			; SOURCE LINE # 2412
	LCALL	stamp_now
			; SOURCE LINE # 2413
	SJMP 	?C0326
?C0327:
	MOV  	A,irstat
	CJNE 	A,#02H,?C0326
			; SOURCE LINE # 2414
	LCALL	ir_errpr
			; SOURCE LINE # 2416
	LCALL	diag_errshow
			; SOURCE LINE # 2418
?C0326:
			; SOURCE LINE # 2423
	MOV  	A,irstat
	JNZ  	?C0330
			; SOURCE LINE # 2424
	LCALL	diag_keyshow
?C0330:
			; SOURCE LINE # 2427
			; SOURCE LINE # 2428
	LJMP 	ir_holdchk
; END OF manual_step

;--------------------------------------------------------------- ?PR?auto_step?MAIN
auto_step:
	USING	0
			; SOURCE LINE # 2436
			; SOURCE LINE # 2437
			; SOURCE LINE # 2440
	LCALL	ir_recv
			; SOURCE LINE # 2441
	MOV  	A,irstat
	JNZ  	?C0334
?C0333:
			; SOURCE LINE # 2444
	MOV  	A,ir_ib2
	CJNE 	A,#040H,?C0335
			; SOURCE LINE # 2445
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 2446
			; SOURCE LINE # 2447
	LCALL	L?0424
			; SOURCE LINE # 2448
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2449
	LCALL	show_state
			; SOURCE LINE # 2450
	MOV  	R7,#028H
	LJMP 	_beep
			; SOURCE LINE # 2452
?C0335:
			; SOURCE LINE # 2454
	MOV  	R7,ir_ib2
	LCALL	_key2mode
			; SOURCE LINE # 2455
	MOV  	A,R7
	CPL  	A
	JZ   	?C0336
			; SOURCE LINE # 2456
	MOV  	A,R7
	XRL  	A,mode
	JZ   	?C0334
			; SOURCE LINE # 2457
	LJMP 	_mode_goto
			; SOURCE LINE # 2459
?C0336:
			; SOURCE LINE # 2462
	MOV  	A,ir_ib2
	CJNE 	A,#01CH,?C0338
			; SOURCE LINE # 2463
	LJMP 	avoid_toggle
			; SOURCE LINE # 2465
?C0338:
			; SOURCE LINE # 2467
	MOV  	A,ir_ib2
	CJNE 	A,#05AH,?C0339
			; SOURCE LINE # 2468
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0334
			; SOURCE LINE # 2469
	INC  	gear
			; SOURCE LINE # 2470
			; SOURCE LINE # 2471
			; SOURCE LINE # 2472
	SJMP 	?C0419
?C0339:
	MOV  	A,ir_ib2
	CJNE 	A,#08H,?C0334
			; SOURCE LINE # 2473
	MOV  	A,gear
	SETB 	C
	SUBB 	A,#00H
	JC   	?C0334
			; SOURCE LINE # 2474
	DEC  	gear
			; SOURCE LINE # 2475
?C0419:
	LCALL	ml_apply
			; SOURCE LINE # 2476
			; SOURCE LINE # 2477
			; SOURCE LINE # 2478
?C0334:
	RET
; END OF auto_step

;--------------------------------------------------------------- ?PR?ml_apply?MAIN
ml_apply:
	USING	0
			; SOURCE LINE # 2485
			; SOURCE LINE # 2486
			; SOURCE LINE # 2488
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2490
	MOV  	A,mode
	JZ   	?C0344
			; SOURCE LINE # 2491
	LJMP 	show_mode
			; SOURCE LINE # 2494
?C0344:
			; SOURCE LINE # 2496
	MOV  	A,gear
	JZ   	?C0347
	MOV  	A,cur_act
	JNZ  	?C0346
?C0347:
			; SOURCE LINE # 2497
	LJMP 	apply_gear_core
			; SOURCE LINE # 2498
?C0346:
			; SOURCE LINE # 2499
	MOV  	R5,gear
			; SOURCE LINE # 2500
	LCALL	L?0427
			; SOURCE LINE # 2501
			; SOURCE LINE # 2503
?C0345:
	RET
; END OF ml_apply

;--------------------------------------------------------------- ?PR?diag_keyshow?MAIN
diag_keyshow:
			; SOURCE LINE # 2515
			; SOURCE LINE # 2516
			; SOURCE LINE # 2517
	MOV  	diag_cmd,ir_ib2
			; SOURCE LINE # 2518
	MOV  	diag_on,#01H
			; SOURCE LINE # 2519
	CLR  	A
	MOV  	diag_seq,A
			; SOURCE LINE # 2520
	RET
; END OF diag_keyshow

;--------------------------------------------------------------- ?PR?diag_errshow?MAIN
diag_errshow:
	USING	0
			; SOURCE LINE # 2522
			; SOURCE LINE # 2523
			; SOURCE LINE # 2524
			; SOURCE LINE # 2525
	LCALL	L?0421
			; SOURCE LINE # 2526
	LCALL	d_20ms
			; SOURCE LINE # 2527
	LCALL	d_20ms
			; SOURCE LINE # 2528
	LCALL	d_20ms
			; SOURCE LINE # 2529
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2530
	MOV  	diag_on,#02H
			; SOURCE LINE # 2531
	CLR  	A
	MOV  	diag_seq,A
			; SOURCE LINE # 2532
	RET
; END OF diag_errshow

;--------------------------------------------------------------- ?PR?diag_dly?MAIN
L?0425:
	USING	0
L?0426:
	MOV  	R7,#028H
	LCALL	_beep
diag_dly:
	USING	0
			; SOURCE LINE # 2534
			; SOURCE LINE # 2535
			; SOURCE LINE # 2537
	CLR  	A
	MOV  	R4,A
?C0351:
			; SOURCE LINE # 2538
	LCALL	d_20ms
	INC  	R4
	CJNE 	R4,#08H,?C0351
			; SOURCE LINE # 2539
?C0354:
	RET
; END OF diag_dly

;--------------------------------------------------------------- ?PR?diag_getval?MAIN
diag_getval:
	USING	0
			; SOURCE LINE # 2541
			; SOURCE LINE # 2542
			; SOURCE LINE # 2543
	MOV  	A,diag_on
	XRL  	A,#02H
	JZ   	?C0355
			; SOURCE LINE # 2544
	MOV  	R7,diag_cmd
	RET
?C0355:
			; SOURCE LINE # 2545
	MOV  	A,diag_seq
	ANL  	A,#06H
	ADD  	A,#0FEH
	JZ   	?C0359
	ADD  	A,#0FEH
	JZ   	?C0360
	ADD  	A,#04H
	JNZ  	?C0361
			; SOURCE LINE # 2546
?C0358:
	MOV  	R7,ir_ledlo
	RET
			; SOURCE LINE # 2547
?C0359:
	MOV  	R7,ir_ledhi
	RET
			; SOURCE LINE # 2548
?C0360:
	MOV  	R7,ir_ib2
	RET
			; SOURCE LINE # 2549
?C0361:
	MOV  	R7,ir_ib3
			; SOURCE LINE # 2550
			; SOURCE LINE # 2551
?C0356:
	RET
; END OF diag_getval

;--------------------------------------------------------------- ?PR?diag_update?MAIN
diag_update:
	USING	0
			; SOURCE LINE # 2553
			; SOURCE LINE # 2554
			; SOURCE LINE # 2560
	MOV  	A,diag_on
	JNZ  	?C0362
			; SOURCE LINE # 2561
	LCALL	tick_get
	MOV  	diag_t0,R6
	MOV  	diag_t0+01H,R7
	RET
			; SOURCE LINE # 2563
?C0362:
			; SOURCE LINE # 2564
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,diag_t0+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,diag_t0
	MOV  	R6,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#070H
	MOV  	A,R6
	SUBB 	A,#017H
	JC   	?C0364
			; SOURCE LINE # 2565
	LCALL	tick_get
	MOV  	diag_t0,R6
	MOV  	diag_t0+01H,R7
			; SOURCE LINE # 2566
	MOV  	A,diag_seq
	INC  	A
	ANL  	A,#07H
	MOV  	diag_seq,A
			; SOURCE LINE # 2567
?C0364:
			; SOURCE LINE # 2569
	LCALL	diag_getval
			; SOURCE LINE # 2570
	MOV  	A,diag_seq
	JNB  	ACC.0,?C0365
			; SOURCE LINE # 2571
	ANL  	AR7,#0FH
	SJMP 	?C0366
?C0365:
			; SOURCE LINE # 2573
	MOV  	A,R7
	SWAP 	A
	ANL  	A,#0FH
	MOV  	R7,A
?C0366:
			; SOURCE LINE # 2574
	MOV  	A,R7
	MOV  	DPTR,#hex_seg
	MOVC 	A,@A+DPTR
	MOV  	R7,A
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2575
?C0363:
	RET
; END OF diag_update

;--------------------------------------------------------------- ?PR?init_all?MAIN
init_all:
	USING	0
			; SOURCE LINE # 2585
			; SOURCE LINE # 2586
			; SOURCE LINE # 2588
	CLR  	A
	MOV  	pwm_div,A
			; SOURCE LINE # 2589
	MOV  	pwm_cnt,A
			; SOURCE LINE # 2590
	MOV  	buz_left,A
			; SOURCE LINE # 2591
	SETB 	buz_quiet
			; SOURCE LINE # 2592
	MOV  	dirbits,A
			; SOURCE LINE # 2593
	MOV  	duty_a,A
			; SOURCE LINE # 2594
	MOV  	duty_b,A
			; SOURCE LINE # 2595
	MOV  	gear,A
			; SOURCE LINE # 2596
	MOV  	klast,A
			; SOURCE LINE # 2597
	MOV  	cur_act,A
			; SOURCE LINE # 2598
	CLR  	back_on
			; SOURCE LINE # 2599
	MOV  	back_t0,A
	MOV  	back_t0+01H,A
			; SOURCE LINE # 2600
	MOV  	prox_t,A
	MOV  	prox_t+01H,A
			; SOURCE LINE # 2601
	CLR  	prox_moving
			; SOURCE LINE # 2602
	CLR  	prox_hold
			; SOURCE LINE # 2603
	MOV  	prox_stop_t,A
	MOV  	prox_stop_t+01H,A
			; SOURCE LINE # 2604
	MOV  	av_beep_n,A
			; SOURCE LINE # 2605
	CLR  	av_clear_on
			; SOURCE LINE # 2606
	MOV  	av_clear_t,A
	MOV  	av_clear_t+01H,A
			; SOURCE LINE # 2609
	MOV  	tick_l,A
			; SOURCE LINE # 2610
	MOV  	tick_h,A
			; SOURCE LINE # 2611
	MOV  	irstat,#01H
			; SOURCE LINE # 2612
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2613
	MOV  	lastt,A
	MOV  	lastt+01H,A
			; SOURCE LINE # 2614
	MOV  	last_err,A
	MOV  	last_err+01H,A
			; SOURCE LINE # 2615
	MOV  	ir_ledlo,A
			; SOURCE LINE # 2616
	MOV  	ir_ledhi,A
			; SOURCE LINE # 2619
	MOV  	mode,A
			; SOURCE LINE # 2620
	SETB 	us_avoid_on
			; SOURCE LINE # 2621
	MOV  	avst,A
			; SOURCE LINE # 2622
	MOV  	av_beep_t,A
	MOV  	av_beep_t+01H,A
			; SOURCE LINE # 2625
	CLR  	recon
			; SOURCE LINE # 2626
	CLR  	playerr
			; SOURCE LINE # 2627
	CLR  	recfull
			; SOURCE LINE # 2628
	MOV  	ms_div,A
			; SOURCE LINE # 2629
	MOV  	ms10_l,A
			; SOURCE LINE # 2630
	MOV  	ms10_h,A
			; SOURCE LINE # 2631
	MOV  	pack,A
			; SOURCE LINE # 2632
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2633
	MOV  	samp,A
	MOV  	samp+01H,A
			; SOURCE LINE # 2634
	MOV  	recn,A
			; SOURCE LINE # 2635
	MOV  	playidx,A
			; SOURCE LINE # 2636
	MOV  	play_dur,A
	MOV  	play_dur+01H,A
			; SOURCE LINE # 2637
	MOV  	play_t0,A
	MOV  	play_t0+01H,A
			; SOURCE LINE # 2638
	MOV  	play_gear0,A
			; SOURCE LINE # 2641
	MOV  	diag_on,A
			; SOURCE LINE # 2642
	MOV  	diag_seq,A
			; SOURCE LINE # 2643
	MOV  	diag_cmd,A
			; SOURCE LINE # 2647
	MOV  	P0,#0C0H
			; SOURCE LINE # 2648
	MOV  	P1,#0FFH
			; SOURCE LINE # 2649
	MOV  	R7,#03H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2650
	MOV  	P3,#0FFH
			; SOURCE LINE # 2653
	LCALL	us_init
			; SOURCE LINE # 2659
	JNB  	IR_AVOID,?C0367
			; SOURCE LINE # 2660
	CLR  	A
	MOV  	ir_inv,A
	SJMP 	?C0368
?C0367:
			; SOURCE LINE # 2662
	MOV  	ir_inv,#01H
?C0368:
			; SOURCE LINE # 2665
	MOV  	TMOD,#022H
			; SOURCE LINE # 2666
	MOV  	TH1,#0FDH
			; SOURCE LINE # 2667
	MOV  	TL1,#0FDH
			; SOURCE LINE # 2668
	MOV  	SCON,#050H
			; SOURCE LINE # 2669
	CLR  	A
	MOV  	PCON,A
			; SOURCE LINE # 2670
	SETB 	TR1
			; SOURCE LINE # 2672
	MOV  	TH0,#0A4H
			; SOURCE LINE # 2673
	MOV  	TL0,#0A4H
			; SOURCE LINE # 2674
	SETB 	ET0
			; SOURCE LINE # 2675
	SETB 	EA
			; SOURCE LINE # 2676
	SETB 	TR0
			; SOURCE LINE # 2678
	LCALL	tick_get
	MOV  	lastt,R6
	MOV  	lastt+01H,R7
			; SOURCE LINE # 2679
	LCALL	tick_get
	MOV  	prox_stop_t,R6
	MOV  	prox_stop_t+01H,R7
			; SOURCE LINE # 2681
	LCALL	apply_gear_core
			; SOURCE LINE # 2685
	MOV  	R7,#01H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2686
	LCALL	L?0425
			; SOURCE LINE # 2687
	LCALL	L?0425
			; SOURCE LINE # 2688
	LCALL	L?0426
			; SOURCE LINE # 2689
	LJMP 	show_state
; END OF init_all

;--------------------------------------------------------------- ?PR?main?MAIN
main:
	USING	0
			; SOURCE LINE # 2767
			; SOURCE LINE # 2768
			; SOURCE LINE # 2771
	LCALL	init_all
?C0370:
			; SOURCE LINE # 2773
			; SOURCE LINE # 2775
	LCALL	diag_update
			; SOURCE LINE # 2778
	MOV  	A,mode
	CJNE 	A,#03H,?C0372
			; SOURCE LINE # 2779
	LCALL	play_step
			; SOURCE LINE # 2780
	SJMP 	?C0370
			; SOURCE LINE # 2781
?C0372:
			; SOURCE LINE # 2784
	LCALL	av_gate
			; SOURCE LINE # 2787
	JNB  	recon,?C0373
			; SOURCE LINE # 2788
	LCALL	rec_sample
?C0373:
			; SOURCE LINE # 2791
	MOV  	A,mode
	JNZ  	?C0374
			; SOURCE LINE # 2792
	LCALL	manual_step
			; SOURCE LINE # 2793
	SJMP 	?C0375
?C0374:
			; SOURCE LINE # 2794
	MOV  	A,mode
	CJNE 	A,#01H,?C0376
			; SOURCE LINE # 2795
	LCALL	light_step
	SJMP 	?C0377
?C0376:
			; SOURCE LINE # 2796
	MOV  	A,mode
	CJNE 	A,#02H,?C0377
			; SOURCE LINE # 2797
	LCALL	track_step
?C0377:
			; SOURCE LINE # 2798
	LCALL	auto_step
			; SOURCE LINE # 2799
?C0375:
			; SOURCE LINE # 2802
	LCALL	back_guard
			; SOURCE LINE # 2805
	LCALL	prox_beep
			; SOURCE LINE # 2808
	LCALL	key_scan
	MOV  	k?6582,R7
			; SOURCE LINE # 2810
	MOV  	A,k?6582
	CJNE 	A,#03H,?C0379
			; SOURCE LINE # 2811
	JNB  	recon,?C0380
			; SOURCE LINE # 2813
			; SOURCE LINE # 2814
	LCALL	L?0421
			; SOURCE LINE # 2815
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2816
	SJMP 	?C0370
?C0380:
			; SOURCE LINE # 2817
	LCALL	mode_switch
			; SOURCE LINE # 2818
			; SOURCE LINE # 2819
	SJMP 	?C0370
			; SOURCE LINE # 2820
?C0379:
			; SOURCE LINE # 2821
	MOV  	A,k?6582
	CJNE 	A,#04H,?C0382
			; SOURCE LINE # 2822
	LCALL	avoid_toggle
			; SOURCE LINE # 2823
	SJMP 	?C0370
			; SOURCE LINE # 2824
?C0382:
			; SOURCE LINE # 2825
	MOV  	A,k?6582
	CJNE 	A,#01H,?C0383
			; SOURCE LINE # 2826
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0370
			; SOURCE LINE # 2827
?C0384:
			; SOURCE LINE # 2828
	INC  	gear
			; SOURCE LINE # 2829
	LCALL	ml_apply
			; SOURCE LINE # 2830
	SJMP 	?C0370
?C0383:
	MOV  	A,k?6582
	XRL  	A,#02H
	JNZ  	?C0370
			; SOURCE LINE # 2831
	MOV  	A,gear
	JZ   	?C0370
			; SOURCE LINE # 2832
?C0387:
			; SOURCE LINE # 2833
	DEC  	gear
			; SOURCE LINE # 2834
	LCALL	ml_apply
			; SOURCE LINE # 2835
			; SOURCE LINE # 2836
	LJMP 	?C0370
; END OF main

;=========================================================================
; 数据段：直接寻址区（原 ?DT? 段）
;   放进 30H 起，剩下的留给栈。
;   ⚠️ 段内的 ORG 已由本脚本翻成绝对地址（C51 在可重定位段里
;      用 ORG 表示"段内偏移"，照搬进绝对段会撞到段基址以下）。
;=========================================================================

	DSEG	AT	0030H

;--------------------------------------------------------------- ?DT?rec_fullstop?MAIN
?rec_fullstop?BYTE:
         i?4370:   DS   1

;--------------------------------------------------------------- ?DT?mode_switch?MAIN
?mode_switch?BYTE:
         m?1652:   DS   1

;--------------------------------------------------------------- ?DT?main?MAIN
?main?BYTE:
         k?6582:   DS   1

;--------------------------------------------------------------- ?DT?track_step?MAIN
?track_step?BYTE:
       act?1855:   DS   1

;--------------------------------------------------------------- ?DT?light_step?MAIN
?light_step?BYTE:
       act?1753:   DS   1

;--------------------------------------------------------------- ?DT?_d3_mix?MAIN
?_d3_mix?BYTE:
        seg?647:   DS   1

;--------------------------------------------------------------- ?DT?av_gate?MAIN
?av_gate?BYTE:
         d?2557:   DS   1

;--------------------------------------------------------------- ?DT?MAIN
        playidx:   DS   1
        us_wait:   DS   1
         ms_div:   DS   1
         ml_dur:   DS   2
         duty_a:   DS   1
         ir_inv:   DS   1
         duty_b:   DS   1
         ms10_h:   DS   1
         us_wid:   DS   1
         ms10_l:   DS   1
         us_res:   DS   1
     av_clear_t:   DS   2
        back_t0:   DS   2
         irstat:   DS   1
        diag_t0:   DS   2
         prox_t:   DS   2
           pack:   DS   1
           gear:   DS   1
          klast:   DS   1
      av_beep_n:   DS   1
           mode:   DS   1
           recn:   DS   1
      av_beep_t:   DS   2
          lastt:   DS   2
       diag_cmd:   DS   1
          us_st:   DS   1
           samp:   DS   2
         ir_ib0:   DS   1
         ir_ib1:   DS   1
         ir_ib2:   DS   1
         ir_ib3:   DS   1
        play_t0:   DS   2
           avst:   DS   1
       diag_seq:   DS   1
      us_last_d:   DS   1
       ir_ledhi:   DS   1
    prox_stop_t:   DS   2
       ir_maskb:   DS   1
       ir_ledlo:   DS   1
        diag_on:   DS   1
       ml_level:   DS   1
      ir_ptridx:   DS   1
       buz_left:   DS   1
       last_err:   DS   2
      us_last10:   DS   1
       play_dur:   DS   2
        cur_act:   DS   1
     play_gear0:   DS   1
        lastcmd:   DS   1
         ml_cap:   DS   1
        ir_bits:   DS   1
        dirbits:   DS   1
         tick_h:   DS   1
        cur_dur:   DS   2
         tick_l:   DS   1
        pwm_div:   DS   1
        pwm_cnt:   DS   1

;=========================================================================
; 位段：位寻址区（原 ?BI? 段）
;   位地址 0 就是内部 RAM 20H.0，位寻址范围 00H~7FH = 20H~2FH。
;=========================================================================

	BSEG	AT	0000H

;--------------------------------------------------------------- ?BI?MAIN
    av_clear_on:   DBIT   1
        playerr:   DBIT   1
         us_got:   DBIT   1
          recon:   DBIT   1
    us_avoid_on:   DBIT   1
            ena:   DBIT   1
            enb:   DBIT   1
    prox_moving:   DBIT   1
        back_on:   DBIT   1
      prox_hold:   DBIT   1
       us_valid:   DBIT   1
      buz_quiet:   DBIT   1
       ir_short:   DBIT   1
        recfull:   DBIT   1
        us_seen:   DBIT   1

	END
