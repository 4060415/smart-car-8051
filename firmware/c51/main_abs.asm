;=========================================================================
; main_abs.asm  --  **自动生成，请勿手改**
;-------------------------------------------------------------------------
;   来源 : main.src
;   生成 : python tools\c51_link.py main.src
;
;   作用 : 把 C51 生成的 74 个可重定位段拼成**一个绝对地址模块**，
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
;        D:\keli\C51\BIN\C51.EXE main.c SMALL SRC
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
?PR?av_mnv_start?MAIN                    SEGMENT CODE
?PR?av_mnv_step?MAIN SEGMENT CODE
?DT?av_mnv_step?MAIN SEGMENT DATA OVERLAYABLE
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

;--------------------------------------------------------------- ?PR?timer0_isr?MAIN
	USING	1
timer0_isr:
	PUSH 	ACC
	PUSH 	PSW
	USING	1
	MOV  	PSW,#08H
			; SOURCE LINE # 583
			; SOURCE LINE # 588
	INC  	tick_l
	MOV  	R7,tick_l
	MOV  	A,R7
	JNZ  	?C0001
			; SOURCE LINE # 589
	INC  	tick_h
?C0001:
			; SOURCE LINE # 592
	INC  	pwm_div
	MOV  	A,pwm_div
	CLR  	C
	SUBB 	A,#05H
	JC   	?C0002
			; SOURCE LINE # 593
	MOV  	pwm_div,#00H
			; SOURCE LINE # 595
	INC  	pwm_cnt
	MOV  	A,pwm_cnt
	SUBB 	A,#014H
	JC   	?C0003
			; SOURCE LINE # 596
	MOV  	pwm_cnt,#00H
?C0003:
			; SOURCE LINE # 598
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
			; SOURCE LINE # 599
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
			; SOURCE LINE # 602
	MOV  	A,buz_left
	JZ   	?C0008
			; SOURCE LINE # 603
	DEC  	buz_left
			; SOURCE LINE # 604
	CPL  	buz_quiet
			; SOURCE LINE # 605
	SJMP 	?C0009
?C0008:
			; SOURCE LINE # 606
	SETB 	buz_quiet
			; SOURCE LINE # 607
?C0009:
			; SOURCE LINE # 610
	MOV  	R7,#080H
			; SOURCE LINE # 611
	MOV  	A,dirbits
	ORL  	AR7,A
			; SOURCE LINE # 612
	JNB  	ena,?C0010
	ORL  	AR7,#010H
?C0010:
			; SOURCE LINE # 613
	JNB  	enb,?C0011
	ORL  	AR7,#020H
?C0011:
			; SOURCE LINE # 614
	JNB  	buz_quiet,?C0012
	ORL  	AR7,#040H
?C0012:
			; SOURCE LINE # 615
	MOV  	P0,R7
			; SOURCE LINE # 616
?C0002:
			; SOURCE LINE # 622
	INC  	ms_div
	MOV  	A,ms_div
	CLR  	C
	SUBB 	A,#064H
	JC   	?C0013
			; SOURCE LINE # 623
	MOV  	ms_div,#00H
			; SOURCE LINE # 624
	INC  	ms10_l
	MOV  	R7,ms10_l
	MOV  	A,R7
	JNZ  	?C0013
			; SOURCE LINE # 625
	INC  	ms10_h
			; SOURCE LINE # 626
?C0013:
			; SOURCE LINE # 632
	MOV  	A,us_st
	JZ   	?C0026
			; SOURCE LINE # 633
	MOV  	A,us_st
	CJNE 	A,#01H,?C0016
			; SOURCE LINE # 634
	JNB  	US_ECHO,?C0017
			; SOURCE LINE # 635
	MOV  	us_wid,#00H
			; SOURCE LINE # 636
	MOV  	us_st,#02H
			; SOURCE LINE # 637
	SJMP 	?C0026
?C0017:
	MOV  	A,us_wait
	CLR  	C
	SUBB 	A,#0FAH
	JNC  	?C0398
			; SOURCE LINE # 638
	INC  	us_wait
			; SOURCE LINE # 639
	SJMP 	?C0026
?C0016:
			; SOURCE LINE # 648
	JNB  	US_ECHO,?C0022
			; SOURCE LINE # 649
	MOV  	A,us_wid
	CLR  	C
	SUBB 	A,#02DH
	JNC  	?C0023
			; SOURCE LINE # 650
	INC  	us_wid
			; SOURCE LINE # 651
	SJMP 	?C0026
?C0023:
			; SOURCE LINE # 652
?C0398:
	MOV  	us_st,#00H
			; SOURCE LINE # 653
	MOV  	us_res,#0FFH
			; SOURCE LINE # 654
	SETB 	us_got
			; SOURCE LINE # 658
			; SOURCE LINE # 659
	SJMP 	?C0026
?C0022:
			; SOURCE LINE # 660
	MOV  	us_st,#00H
			; SOURCE LINE # 661
	MOV  	us_res,us_wid
			; SOURCE LINE # 662
	SETB 	us_got
			; SOURCE LINE # 666
			; SOURCE LINE # 667
			; SOURCE LINE # 668
			; SOURCE LINE # 669
?C0026:
	POP  	PSW
	POP  	ACC
	RETI
; END OF timer0_isr

;--------------------------------------------------------------- ?PR?tick_get?MAIN
tick_get:
	USING	0
			; SOURCE LINE # 676
			; SOURCE LINE # 677
			; SOURCE LINE # 679
	CLR  	ET0
			; SOURCE LINE # 680
	MOV  	R7,tick_h
	MOV  	A,R7
	MOV  	R6,A
	MOV  	R5,tick_l
	MOV  	A,R5
	MOV  	R7,A
			; SOURCE LINE # 681
	SETB 	ET0
			; SOURCE LINE # 682
			; SOURCE LINE # 683
?C0027:
	RET
; END OF tick_get

;--------------------------------------------------------------- ?PR?ms10_get?MAIN
ms10_get:
	USING	0
			; SOURCE LINE # 686
			; SOURCE LINE # 687
			; SOURCE LINE # 689
	CLR  	ET0
			; SOURCE LINE # 690
	MOV  	R7,ms10_h
	MOV  	A,R7
	MOV  	R6,A
	MOV  	R5,ms10_l
	MOV  	A,R5
	MOV  	R7,A
			; SOURCE LINE # 691
	SETB 	ET0
			; SOURCE LINE # 692
			; SOURCE LINE # 693
?C0028:
	RET
; END OF ms10_get

;--------------------------------------------------------------- ?PR?d_20ms?MAIN
L?0434:
	USING	0
L?0435:
	MOV  	R7,#018H
	LCALL	_beep
d_20ms:
	USING	0
			; SOURCE LINE # 701
			; SOURCE LINE # 702
			; SOURCE LINE # 703
	LCALL	tick_get
	MOV  	R3,AR7
	MOV  	R2,AR6
?C0029:
			; SOURCE LINE # 704
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
			; SOURCE LINE # 706
?C0031:
	RET
; END OF d_20ms

;--------------------------------------------------------------- ?PR?_beep?MAIN
_beep:
			; SOURCE LINE # 719
			; SOURCE LINE # 720
			; SOURCE LINE # 721
	MOV  	A,R7
	JNZ  	?C0032
			; SOURCE LINE # 722
	CLR  	ET0
			; SOURCE LINE # 723
	MOV  	buz_left,A
			; SOURCE LINE # 724
	SETB 	buz_quiet
			; SOURCE LINE # 725
	SETB 	ET0
	RET
			; SOURCE LINE # 727
?C0032:
			; SOURCE LINE # 728
	CLR  	ET0
			; SOURCE LINE # 729
	MOV  	buz_left,R7
			; SOURCE LINE # 730
	CLR  	buz_quiet
			; SOURCE LINE # 731
	SETB 	ET0
			; SOURCE LINE # 732
?C0033:
	RET
; END OF _beep

;--------------------------------------------------------------- ?PR?_motor_set_core?MAIN
_motor_set_core:
	USING	0
			; SOURCE LINE # 853
			; SOURCE LINE # 854
			; SOURCE LINE # 855
	MOV  	A,R5
	JNZ  	?C0034
			; SOURCE LINE # 856
			; SOURCE LINE # 857
			; SOURCE LINE # 858
	SJMP 	?C0400
			; SOURCE LINE # 860
?C0034:
			; SOURCE LINE # 864
	MOV  	A,avst
	CJNE 	A,#04H,?C0036
			; SOURCE LINE # 865
	MOV  	R7,#06H
			; SOURCE LINE # 866
	SJMP 	?C0037
?C0036:
			; SOURCE LINE # 868
	MOV  	A,avst
	CJNE 	A,#01H,?C0038
			; SOURCE LINE # 869
	MOV  	R7,#04H
			; SOURCE LINE # 870
	SJMP 	?C0037
?C0038:
	MOV  	A,avst
	CJNE 	A,#02H,?C0040
			; SOURCE LINE # 871
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 874
?C0399:
			; SOURCE LINE # 875
			; SOURCE LINE # 876
	SJMP 	?C0400
			; SOURCE LINE # 878
?C0040:
	MOV  	A,avst
	CJNE 	A,#05H,?C0042
			; SOURCE LINE # 880
	MOV  	R7,#02H
			; SOURCE LINE # 881
	SJMP 	?C0037
?C0042:
	MOV  	A,avst
	CJNE 	A,#06H,?C0037
			; SOURCE LINE # 882
	MOV  	R7,#04H
			; SOURCE LINE # 883
?C0037:
			; SOURCE LINE # 888
	CJNE 	R7,#02H,?C0045
	MOV  	A,R5
	SETB 	C
	SUBB 	A,#02H
	JC   	?C0045
			; SOURCE LINE # 889
	MOV  	R5,#02H
?C0045:
			; SOURCE LINE # 891
	MOV  	A,R5
	MOV  	DPTR,#duty_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 892
	MOV  	duty_b,duty_a
			; SOURCE LINE # 897
	CJNE 	R7,#05H,?C0046
			; SOURCE LINE # 898
	MOV  	A,R5
	MOV  	DPTR,#arc_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 899
	SJMP 	?C0402
			; SOURCE LINE # 901
?C0046:
			; SOURCE LINE # 902
	CJNE 	R7,#06H,?C0047
			; SOURCE LINE # 903
	MOV  	A,R5
	MOV  	DPTR,#arc_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_b,A
			; SOURCE LINE # 904
?C0401:
	SJMP 	?C0402
			; SOURCE LINE # 906
?C0047:
			; SOURCE LINE # 908
	MOV  	A,R7
	ADD  	A,#0FEH
	JZ   	?C0050
	DEC  	A
	JZ   	?C0051
	DEC  	A
	JZ   	?C0052
	ADD  	A,#03H
	JNZ  	?C0053
			; SOURCE LINE # 909
?C0049:
?C0402:
	MOV  	dirbits,#05H
	RET
			; SOURCE LINE # 910
?C0050:
	MOV  	dirbits,#0AH
	RET
			; SOURCE LINE # 911
?C0051:
	MOV  	dirbits,#06H
	RET
			; SOURCE LINE # 912
?C0052:
	MOV  	dirbits,#09H
	RET
			; SOURCE LINE # 913
?C0053:
			; SOURCE LINE # 914
	CLR  	A
?C0400:
	MOV  	dirbits,A
			; SOURCE LINE # 915
	MOV  	duty_a,A
			; SOURCE LINE # 916
	MOV  	duty_b,A
			; SOURCE LINE # 917
			; SOURCE LINE # 918
			; SOURCE LINE # 919
?C0035:
	RET
; END OF _motor_set_core

;--------------------------------------------------------------- ?PR?_d3_mix?MAIN
_d3_mix:
	USING	0
			; SOURCE LINE # 966
	MOV  	seg?647,R7
			; SOURCE LINE # 967
			; SOURCE LINE # 968
	LCALL	avoid_off
	MOV  	A,seg?647
	JC   	?C0054
			; SOURCE LINE # 969
	ANL  	A,#0FEH
	MOV  	R7,A
	RET
?C0054:
			; SOURCE LINE # 970
	ORL  	A,#01H
	MOV  	R7,A
			; SOURCE LINE # 971
?C0055:
	RET
; END OF _d3_mix

;--------------------------------------------------------------- ?PR?avoid_off?MAIN
avoid_off:
			; SOURCE LINE # 978
			; SOURCE LINE # 979
			; SOURCE LINE # 980
	JNB  	recon,?C0056
			; SOURCE LINE # 981
	SETB 	C
	RET
?C0056:
			; SOURCE LINE # 982
	JNB  	us_avoid_on,?C0058
			; SOURCE LINE # 983
	CLR  	C
	RET
?C0058:
			; SOURCE LINE # 984
	SETB 	C
			; SOURCE LINE # 985
?C0057:
	RET
; END OF avoid_off

;--------------------------------------------------------------- ?PR?apply_gear_core?MAIN
apply_gear_core:
	USING	0
			; SOURCE LINE # 993
			; SOURCE LINE # 994
			; SOURCE LINE # 997
	JB   	av_mnv,?C0060
?C0059:
			; SOURCE LINE # 1000
	MOV  	A,gear
	JZ   	?apply_gear_core?stop
			; SOURCE LINE # 1001
?C0061:
			; SOURCE LINE # 1004
	MOV  	A,avst
	XRL  	A,#02H
	JZ   	?apply_gear_core?stop
			; SOURCE LINE # 1005
?C0063:
			; SOURCE LINE # 1009
	MOV  	cur_act,#01H
			; SOURCE LINE # 1011
	MOV  	A,gear
	MOV  	DPTR,#duty_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 1012
	MOV  	duty_b,duty_a
			; SOURCE LINE # 1013
	MOV  	dirbits,#05H
			; SOURCE LINE # 1015
	SJMP 	?C0403
			; SOURCE LINE # 1018
?apply_gear_core?stop:
			; SOURCE LINE # 1019
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 1020
	MOV  	duty_a,A
			; SOURCE LINE # 1021
	MOV  	duty_b,A
			; SOURCE LINE # 1022
	MOV  	dirbits,A
			; SOURCE LINE # 1023
?C0403:
	MOV  	A,gear
	MOV  	DPTR,#gear_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 1024
?C0060:
	RET
; END OF apply_gear_core

;--------------------------------------------------------------- ?PR?show_state?MAIN
L?0438:
	USING	0
	MOV  	R7,cur_act
	LCALL	_motor_set_core
show_state:
	USING	0
			; SOURCE LINE # 1041
			; SOURCE LINE # 1042
			; SOURCE LINE # 1043
	JNB  	recon,?C0064
	MOV  	R7,#0F5H
	SJMP 	?C0065
?C0064:
	MOV  	A,gear
	MOV  	DPTR,#gear_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
?C0065:
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 1044
	RET
; END OF show_state

;--------------------------------------------------------------- ?PR?show_mode?MAIN
L?0436:
	USING	0
	MOV  	avst,#02H
	CLR  	A
L?0437:
	MOV  	cur_act,A
	MOV  	R5,A
	MOV  	R7,A
	LCALL	_motor_set_core
show_mode:
	USING	0
			; SOURCE LINE # 1047
			; SOURCE LINE # 1048
			; SOURCE LINE # 1049
	MOV  	A,mode
	JNZ  	?C0067
			; SOURCE LINE # 1050
	LJMP 	show_state
			; SOURCE LINE # 1052
?C0067:
			; SOURCE LINE # 1054
	MOV  	A,mode
	MOV  	DPTR,#mode_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 1055
?C0068:
	RET
; END OF show_mode

;--------------------------------------------------------------- ?PR?key_scan?MAIN
key_scan:
	USING	0
			; SOURCE LINE # 1064
			; SOURCE LINE # 1065
			; SOURCE LINE # 1068
	MOV  	A,klast
	JZ   	?C0069
			; SOURCE LINE # 1069
	XRL  	A,#02H
	JZ   	?C0071
	MOV  	A,klast
	CJNE 	A,#04H,?C0070
?C0071:
			; SOURCE LINE # 1070
	JNB  	KEY_S4,?C0073
			; SOURCE LINE # 1071
	SJMP 	?C0404
?C0070:
			; SOURCE LINE # 1072
	JNB  	KEY_S3,?C0073
?C0404:
	CLR  	A
	MOV  	klast,A
			; SOURCE LINE # 1073
?C0073:
			; SOURCE LINE # 1074
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1075
?C0069:
			; SOURCE LINE # 1077
	JB   	KEY_S3,?C0076
			; SOURCE LINE # 1078
	LCALL	d_20ms
			; SOURCE LINE # 1079
	JNB  	KEY_S3,?C0077
	MOV  	R7,#00H
	RET
?C0077:
			; SOURCE LINE # 1080
	LCALL	tick_get
	MOV  	DPH,R6
	MOV  	DPL,R7
?C0078:
			; SOURCE LINE # 1081
	JB   	KEY_S3,?C0079
			; SOURCE LINE # 1082
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,DPH
	CLR  	C
	SUBB 	A,#027H
	JC   	?C0078
			; SOURCE LINE # 1083
	MOV  	klast,#03H
			; SOURCE LINE # 1084
	MOV  	R7,#03H
	RET
			; SOURCE LINE # 1085
			; SOURCE LINE # 1086
?C0079:
			; SOURCE LINE # 1087
	MOV  	klast,#01H
			; SOURCE LINE # 1088
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1089
?C0076:
			; SOURCE LINE # 1091
	JB   	KEY_S4,?C0081
			; SOURCE LINE # 1092
	LCALL	d_20ms
			; SOURCE LINE # 1093
	JNB  	KEY_S4,?C0082
	MOV  	R7,#00H
	RET
?C0082:
			; SOURCE LINE # 1094
	LCALL	tick_get
	MOV  	DPH,R6
	MOV  	DPL,R7
?C0083:
			; SOURCE LINE # 1095
	JB   	KEY_S4,?C0084
			; SOURCE LINE # 1096
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,DPH
	CLR  	C
	SUBB 	A,#027H
	JC   	?C0083
			; SOURCE LINE # 1097
	MOV  	klast,#04H
			; SOURCE LINE # 1098
	MOV  	R7,#04H
	RET
			; SOURCE LINE # 1099
			; SOURCE LINE # 1100
?C0084:
			; SOURCE LINE # 1101
	MOV  	klast,#02H
			; SOURCE LINE # 1102
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1103
?C0081:
			; SOURCE LINE # 1105
	MOV  	R7,#00H
			; SOURCE LINE # 1106
?C0075:
	RET
; END OF key_scan

;--------------------------------------------------------------- ?PR?k_isfwd?MAIN
k_isfwd:
			; SOURCE LINE # 1122
			; SOURCE LINE # 1123
			; SOURCE LINE # 1124
	MOV  	A,cur_act
	CJNE 	A,#01H,?C0086
	SETB 	C
	RET
?C0086:
			; SOURCE LINE # 1125
	MOV  	A,cur_act
	CJNE 	A,#05H,?C0088
	SETB 	C
	RET
?C0088:
			; SOURCE LINE # 1126
	MOV  	A,cur_act
	CJNE 	A,#06H,?C0089
	SETB 	C
	RET
?C0089:
			; SOURCE LINE # 1127
	CLR  	C
			; SOURCE LINE # 1128
?C0087:
	RET
; END OF k_isfwd

;--------------------------------------------------------------- ?PR?_key2act?MAIN
_key2act:
	USING	0
			; SOURCE LINE # 1130
			; SOURCE LINE # 1131
			; SOURCE LINE # 1132
	MOV  	A,R7
	ADD  	A,#0EBH
	JZ   	?C0093
	ADD  	A,#0D5H
	JZ   	?C0100
	ADD  	A,#0FDH
	JZ   	?C0097
	DEC  	A
	JZ   	?C0094
	ADD  	A,#0FEH
	JNZ  	?C0101
			; SOURCE LINE # 1133
?C0091:
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1134
?C0093:
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1135
?C0094:
	LCALL	k_isfwd
	JNC  	?C0095
	MOV  	R7,#05H
	RET
?C0095:
	MOV  	R7,#03H
?C0096:
	RET
			; SOURCE LINE # 1136
?C0097:
	LCALL	k_isfwd
	JNC  	?C0098
	MOV  	R7,#06H
	RET
?C0098:
	MOV  	R7,#04H
?C0099:
	RET
			; SOURCE LINE # 1137
?C0100:
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1138
?C0101:
	MOV  	R7,#0FFH
			; SOURCE LINE # 1139
			; SOURCE LINE # 1140
?C0092:
	RET
; END OF _key2act

;--------------------------------------------------------------- ?PR?_key2mode?MAIN
_key2mode:
	USING	0
			; SOURCE LINE # 1146
			; SOURCE LINE # 1147
			; SOURCE LINE # 1148
	MOV  	A,R7
	ADD  	A,#0E8H
	JZ   	?C0105
	ADD  	A,#0BAH
	JZ   	?C0106
	ADD  	A,#052H
	JNZ  	?C0107
			; SOURCE LINE # 1149
?C0103:
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1150
?C0105:
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1151
?C0106:
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1152
?C0107:
	MOV  	R7,#0FFH
			; SOURCE LINE # 1153
			; SOURCE LINE # 1154
?C0104:
	RET
; END OF _key2mode

;--------------------------------------------------------------- ?PR?_mode_goto?MAIN
_mode_goto:
	USING	0
			; SOURCE LINE # 1160
			; SOURCE LINE # 1161
			; SOURCE LINE # 1162
	MOV  	mode,R7
			; SOURCE LINE # 1163
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 1165
	MOV  	A,R7
	JNZ  	?C0108
			; SOURCE LINE # 1169
	MOV  	A,gear
	JZ   	?C0109
	MOV  	R7,#01H
	SJMP 	?C0110
?C0109:
	MOV  	R7,#00H
?C0110:
	MOV  	cur_act,R7
			; SOURCE LINE # 1170
	MOV  	R5,gear
	LCALL	_motor_set_core
			; SOURCE LINE # 1171
	LCALL	show_state
			; SOURCE LINE # 1172
	SJMP 	?C0111
?C0108:
			; SOURCE LINE # 1173
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 1174
	MOV  	A,gear
	JNZ  	?C0112
			; SOURCE LINE # 1175
	MOV  	gear,#03H
?C0112:
			; SOURCE LINE # 1176
	LCALL	show_mode
			; SOURCE LINE # 1177
?C0111:
			; SOURCE LINE # 1179
	MOV  	R7,#028H
	LJMP 	_beep
; END OF _mode_goto

;--------------------------------------------------------------- ?PR?mode_switch?MAIN
mode_switch:
	USING	0
			; SOURCE LINE # 1183
			; SOURCE LINE # 1184
			; SOURCE LINE # 1185
	MOV  	m?1652,mode
			; SOURCE LINE # 1187
	MOV  	A,m?1652
	CJNE 	A,#03H,?C0114
			; SOURCE LINE # 1188
	CLR  	A
	MOV  	R7,A
	SJMP 	?C0405
			; SOURCE LINE # 1190
?C0114:
			; SOURCE LINE # 1191
	INC  	m?1652
			; SOURCE LINE # 1192
	MOV  	A,m?1652
	CLR  	C
	SUBB 	A,#03H
	JC   	?C0116
			; SOURCE LINE # 1193
	CLR  	A
	MOV  	m?1652,A
?C0116:
			; SOURCE LINE # 1194
	MOV  	R7,m?1652
?C0405:
	LCALL	_mode_goto
			; SOURCE LINE # 1195
?C0115:
	RET
; END OF mode_switch

;--------------------------------------------------------------- ?PR?light_step?MAIN
light_step:
	USING	0
			; SOURCE LINE # 1202
			; SOURCE LINE # 1203
			; SOURCE LINE # 1206
	MOV  	A,gear
	JNZ  	?C0117
			; SOURCE LINE # 1207
	MOV  	act?1753,A
			; SOURCE LINE # 1208
	SJMP 	?C0118
?C0117:
	JB   	LDR_LEFT,?C0119
			; SOURCE LINE # 1209
	JNB  	LDR_RIGHT,?C0120
	MOV  	R7,#03H
	SJMP 	?C0121
?C0120:
	MOV  	R7,#01H
?C0121:
	MOV  	act?1753,R7
			; SOURCE LINE # 1210
	SJMP 	?C0118
?C0119:
			; SOURCE LINE # 1211
	JNB  	LDR_RIGHT,?C0123
	MOV  	R7,#00H
	SJMP 	?C0124
?C0123:
	MOV  	R7,#04H
?C0124:
	MOV  	act?1753,R7
			; SOURCE LINE # 1212
?C0118:
			; SOURCE LINE # 1214
	MOV  	cur_act,act?1753
			; SOURCE LINE # 1215
	MOV  	R5,gear
	MOV  	R7,act?1753
	LCALL	_motor_set_core
			; SOURCE LINE # 1216
	LJMP 	show_mode
; END OF light_step

;--------------------------------------------------------------- ?PR?track_step?MAIN
track_step:
	USING	0
			; SOURCE LINE # 1226
			; SOURCE LINE # 1227
			; SOURCE LINE # 1228
	CLR  	A
	MOV  	R7,A
			; SOURCE LINE # 1231
	JNB  	TRACK_L,?C0126
	MOV  	R7,#02H
?C0126:
			; SOURCE LINE # 1232
	JNB  	TRACK_R,?C0127
	ORL  	AR7,#01H
?C0127:
			; SOURCE LINE # 1234
	CJNE 	R7,#01H,?C0128
	MOV  	act?1855,#04H
	SJMP 	?C0129
?C0128:
			; SOURCE LINE # 1235
	CJNE 	R7,#02H,?C0130
	MOV  	act?1855,#03H
	SJMP 	?C0129
?C0130:
			; SOURCE LINE # 1236
	MOV  	act?1855,#01H
?C0129:
			; SOURCE LINE # 1239
	MOV  	cur_act,act?1855
			; SOURCE LINE # 1240
	MOV  	R5,gear
	MOV  	R7,act?1855
	LCALL	_motor_set_core
			; SOURCE LINE # 1241
	LJMP 	show_mode
; END OF track_step

;--------------------------------------------------------------- ?PR?us_init?MAIN
us_init:
			; SOURCE LINE # 1260
			; SOURCE LINE # 1261
			; SOURCE LINE # 1262
	CLR  	ET0
			; SOURCE LINE # 1263
	CLR  	A
	MOV  	us_st,A
			; SOURCE LINE # 1264
	MOV  	us_wid,A
			; SOURCE LINE # 1265
	MOV  	us_wait,A
			; SOURCE LINE # 1266
	CLR  	us_got
			; SOURCE LINE # 1267
	MOV  	us_res,#0FFH
			; SOURCE LINE # 1268
	CLR  	us_valid
			; SOURCE LINE # 1269
	CLR  	us_seen
			; SOURCE LINE # 1270
	MOV  	us_last10,A
			; SOURCE LINE # 1271
	MOV  	us_last_d,#0FFH
			; SOURCE LINE # 1275
	CLR  	US_TRIG
			; SOURCE LINE # 1276
	SETB 	ET0
			; SOURCE LINE # 1277
	RET
; END OF us_init

;--------------------------------------------------------------- ?PR?us_trigger?MAIN
us_trigger:
			; SOURCE LINE # 1283
			; SOURCE LINE # 1284
			; SOURCE LINE # 1285
	CLR  	US_TRIG
			; SOURCE LINE # 1286
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1287
	SETB 	US_TRIG
			; SOURCE LINE # 1288
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1289
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1290
	CLR  	US_TRIG
			; SOURCE LINE # 1292
	CLR  	A
	MOV  	us_wid,A
			; SOURCE LINE # 1293
	MOV  	us_wait,A
			; SOURCE LINE # 1294
	MOV  	us_st,#01H
			; SOURCE LINE # 1295
	RET
; END OF us_trigger

;--------------------------------------------------------------- ?PR?us_read?MAIN
us_read:
	USING	0
			; SOURCE LINE # 1299
			; SOURCE LINE # 1300
			; SOURCE LINE # 1301
	MOV  	R6,ms10_l
			; SOURCE LINE # 1306
	JNB  	us_got,?C0135
			; SOURCE LINE # 1307
	CLR  	ET0
			; SOURCE LINE # 1308
	MOV  	us_last_d,us_res
			; SOURCE LINE # 1309
	CLR  	us_got
			; SOURCE LINE # 1310
	SETB 	us_valid
			; SOURCE LINE # 1311
	SETB 	ET0
			; SOURCE LINE # 1312
?C0135:
			; SOURCE LINE # 1315
	MOV  	A,us_st
	JZ   	?C0136
			; SOURCE LINE # 1316
	JNB  	us_valid,?C0137
	MOV  	R7,us_last_d
	RET
?C0137:
	MOV  	R7,#0FFH
?C0138:
	RET
?C0136:
			; SOURCE LINE # 1320
	JNB  	us_seen,?C0140
	CLR  	C
	MOV  	A,R6
	SUBB 	A,us_last10
	CLR  	C
	SUBB 	A,#06H
	JNC  	?C0140
			; SOURCE LINE # 1321
	JNB  	us_valid,?C0141
	MOV  	R7,us_last_d
	RET
?C0141:
	MOV  	R7,#0FFH
?C0142:
	RET
?C0140:
			; SOURCE LINE # 1324
	MOV  	us_last10,R6
			; SOURCE LINE # 1325
	SETB 	us_seen
			; SOURCE LINE # 1326
	LCALL	us_trigger
			; SOURCE LINE # 1327
	JNB  	us_valid,?C0143
	MOV  	R7,us_last_d
	SJMP 	?C0144
?C0143:
	MOV  	R7,#0FFH
?C0144:
			; SOURCE LINE # 1328
?C0139:
	RET
; END OF us_read

;--------------------------------------------------------------- ?PR?ir_det?MAIN
ir_det:
			; SOURCE LINE # 1336
			; SOURCE LINE # 1337
			; SOURCE LINE # 1338
	MOV  	A,ir_inv
	JZ   	?C0145
			; SOURCE LINE # 1339
	JNB  	IR_AVOID,?C0146
	SETB 	C
	RET
?C0146:
			; SOURCE LINE # 1340
	CLR  	C
	RET
			; SOURCE LINE # 1341
?C0145:
			; SOURCE LINE # 1342
	JNB  	IR_AVOID,?C0148
	CLR  	C
	RET
?C0148:
			; SOURCE LINE # 1343
	SETB 	C
			; SOURCE LINE # 1344
?C0147:
	RET
; END OF ir_det

;--------------------------------------------------------------- ?PR?ir_brake?MAIN
ir_brake:
	USING	0
			; SOURCE LINE # 1380
			; SOURCE LINE # 1381
			; SOURCE LINE # 1382
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0150
?C0149:
			; SOURCE LINE # 1385
			; SOURCE LINE # 1386
			; SOURCE LINE # 1387
			; SOURCE LINE # 1388
	LCALL	L?0436
			; SOURCE LINE # 1389
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1390
	CLR  	A
	MOV  	av_beep_n,A
			; SOURCE LINE # 1395
?C0150:
	RET
; END OF ir_brake

;--------------------------------------------------------------- ?PR?av_gate_hold?MAIN
av_gate_hold:
	USING	0
			; SOURCE LINE # 1403
			; SOURCE LINE # 1404
			; SOURCE LINE # 1405
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0152
?C0151:
			; SOURCE LINE # 1408
	MOV  	A,mode
	CJNE 	A,#01H,?C0153
			; SOURCE LINE # 1411
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 1412
	MOV  	avst,#03H
			; SOURCE LINE # 1413
			; SOURCE LINE # 1414
			; SOURCE LINE # 1415
	LCALL	L?0437
			; SOURCE LINE # 1416
	SJMP 	?C0406
			; SOURCE LINE # 1418
?C0153:
			; SOURCE LINE # 1421
			; SOURCE LINE # 1422
			; SOURCE LINE # 1423
			; SOURCE LINE # 1424
	LCALL	L?0436
			; SOURCE LINE # 1426
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1430
	MOV  	A,av_beep_n
	JNZ  	?C0152
			; SOURCE LINE # 1431
	MOV  	av_beep_n,#01H
			; SOURCE LINE # 1433
?C0406:
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 1434
			; SOURCE LINE # 1435
?C0152:
	RET
; END OF av_gate_hold

;--------------------------------------------------------------- ?PR?av_mnv_start?MAIN
av_mnv_start:
	USING	0
			; SOURCE LINE # 1457
			; SOURCE LINE # 1458
			; SOURCE LINE # 1469
	JNB  	recon,?C0155
			; SOURCE LINE # 1470
	LJMP 	ir_brake
			; SOURCE LINE # 1472
?C0155:
			; SOURCE LINE # 1474
	SETB 	av_mnv
			; SOURCE LINE # 1475
	MOV  	avst,#05H
			; SOURCE LINE # 1476
	LCALL	tick_get
	MOV  	back_t0,R6
	MOV  	back_t0+01H,R7
			; SOURCE LINE # 1477
	CLR  	A
	MOV  	av_beep_n,A
			; SOURCE LINE # 1478
	MOV  	R5,#02H
	MOV  	R7,#02H
	LCALL	_motor_set_core
			; SOURCE LINE # 1479
	LCALL	show_mode
			; SOURCE LINE # 1480
?C0156:
	RET
; END OF av_mnv_start

;--------------------------------------------------------------- ?PR?av_mnv_step?MAIN
av_mnv_step:
	USING	0
			; SOURCE LINE # 1482
			; SOURCE LINE # 1483
			; SOURCE LINE # 1484
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,back_t0+01H
	MOV  	el?2657+01H,A
	MOV  	A,R6
	SUBB 	A,back_t0
	MOV  	el?2657,A
			; SOURCE LINE # 1488
	LCALL	us_read
			; SOURCE LINE # 1490
	MOV  	A,avst
	XRL  	A,#05H
	JNZ  	?C0157
			; SOURCE LINE # 1493
	CLR  	C
	MOV  	A,el?2657+01H
	SUBB 	A,#088H
	MOV  	A,el?2657
	SUBB 	A,#013H
	JC   	?C0158
			; SOURCE LINE # 1494
	MOV  	avst,#06H
			; SOURCE LINE # 1495
	LCALL	tick_get
	MOV  	back_t0,R6
	MOV  	back_t0+01H,R7
			; SOURCE LINE # 1496
	MOV  	A,gear
	JZ   	?C0159
	MOV  	R5,A
	SJMP 	?C0160
?C0159:
	MOV  	R5,#03H
?C0160:
	MOV  	R7,#04H
			; SOURCE LINE # 1497
	SJMP 	?C0409
			; SOURCE LINE # 1499
?C0158:
			; SOURCE LINE # 1500
	MOV  	R5,#02H
	MOV  	R7,#02H
	SJMP 	?C0408
			; SOURCE LINE # 1502
?C0157:
			; SOURCE LINE # 1505
	CLR  	C
	MOV  	A,el?2657+01H
	SUBB 	A,#010H
	MOV  	A,el?2657
	SUBB 	A,#027H
	JNC  	?C0162
			; SOURCE LINE # 1506
	MOV  	A,gear
	JZ   	?C0163
	MOV  	R5,A
	SJMP 	?C0164
?C0163:
	MOV  	R5,#03H
?C0164:
	MOV  	R7,#04H
?C0408:
	LJMP 	_motor_set_core
			; SOURCE LINE # 1508
?C0162:
			; SOURCE LINE # 1512
	LCALL	ir_det
	JNC  	?C0165
			; SOURCE LINE # 1513
	INC  	av_beep_n
			; SOURCE LINE # 1514
	MOV  	A,av_beep_n
	CLR  	C
	SUBB 	A,#03H
	JNC  	?C0166
			; SOURCE LINE # 1515
	MOV  	avst,#05H
			; SOURCE LINE # 1516
	LCALL	tick_get
	MOV  	back_t0,R6
	MOV  	back_t0+01H,R7
			; SOURCE LINE # 1517
	MOV  	R5,#02H
	MOV  	R7,#02H
?C0407:
			; SOURCE LINE # 1518
	SJMP 	?C0409
			; SOURCE LINE # 1520
?C0166:
			; SOURCE LINE # 1521
	CLR  	av_mnv
			; SOURCE LINE # 1522
	LJMP 	ir_brake
			; SOURCE LINE # 1524
?C0165:
			; SOURCE LINE # 1525
	CLR  	av_mnv
			; SOURCE LINE # 1526
	CLR  	A
	MOV  	av_beep_n,A
			; SOURCE LINE # 1527
	MOV  	avst,A
			; SOURCE LINE # 1531
	MOV  	A,cur_act
	JNZ  	?C0167
	MOV  	R5,A
	SJMP 	?C0168
?C0167:
	MOV  	R7,gear
	MOV  	R5,AR7
?C0168:
	MOV  	R7,cur_act
?C0409:
	LCALL	_motor_set_core
			; SOURCE LINE # 1532
	LCALL	show_mode
			; SOURCE LINE # 1533
?C0161:
	RET
; END OF av_mnv_step

;--------------------------------------------------------------- ?PR?av_gate?MAIN
av_gate:
	USING	0
			; SOURCE LINE # 1539
			; SOURCE LINE # 1540
			; SOURCE LINE # 1568
	MOV  	A,mode
	CJNE 	A,#01H,?C0169
			; SOURCE LINE # 1569
	CLR  	av_mnv
			; SOURCE LINE # 1570
	LJMP 	?C0411
			; SOURCE LINE # 1572
?C0169:
			; SOURCE LINE # 1577
	JNB  	av_mnv,?C0171
			; SOURCE LINE # 1578
	LJMP 	av_mnv_step
			; SOURCE LINE # 1580
?C0171:
			; SOURCE LINE # 1586
	LCALL	avoid_off
	JNC  	?C0172
	MOV  	A,avst
	CJNE 	A,#02H,?C0172
			; SOURCE LINE # 1587
	CLR  	A
	MOV  	avst,A
?C0172:
			; SOURCE LINE # 1592
	MOV  	A,avst
	XRL  	A,#02H
	JNZ  	?C0173
			; SOURCE LINE # 1594
	LCALL	ir_det
	JNC  	$ + 5H
	LJMP 	?C0170
?C0174:
			; SOURCE LINE # 1602
	MOV  	A,mode
	CJNE 	A,#02H,?C0175
			; SOURCE LINE # 1603
?C0410:
	SJMP 	?C0411
			; SOURCE LINE # 1605
?C0175:
			; SOURCE LINE # 1608
	LCALL	avoid_off
	JNC  	$ + 5H
	LJMP 	?C0170
?C0176:
			; SOURCE LINE # 1612
	LCALL	us_read
	MOV  	A,R7
	CLR  	C
	SUBB 	A,#07H
	JC   	?C0177
			; SOURCE LINE # 1613
	JB   	av_clear_on,?C0178
			; SOURCE LINE # 1614
	SETB 	av_clear_on
			; SOURCE LINE # 1615
	LCALL	tick_get
	MOV  	av_clear_t,R6
	MOV  	av_clear_t+01H,R7
	RET
			; SOURCE LINE # 1617
?C0178:
			; SOURCE LINE # 1618
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
	LJMP 	?C0170
			; SOURCE LINE # 1619
	CLR  	A
	MOV  	av_beep_n,A
	RET
			; SOURCE LINE # 1621
?C0177:
			; SOURCE LINE # 1622
	CLR  	av_clear_on
			; SOURCE LINE # 1625
	MOV  	A,av_beep_n
	CLR  	C
	SUBB 	A,#03H
	JC   	$ + 5H
	LJMP 	?C0170
?C0180:
			; SOURCE LINE # 1627
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,av_beep_t+01H
	MOV  	A,R6
	SUBB 	A,av_beep_t
	CLR  	C
	SUBB 	A,#01BH
	JNC  	$ + 5H
	LJMP 	?C0170
			; SOURCE LINE # 1628
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1629
	INC  	av_beep_n
			; SOURCE LINE # 1631
	MOV  	R7,#018H
	LJMP 	_beep
			; SOURCE LINE # 1632
			; SOURCE LINE # 1635
?C0173:
			; SOURCE LINE # 1639
	LCALL	ir_det
	JNC  	?C0182
			; SOURCE LINE # 1640
	LJMP 	av_mnv_start
			; SOURCE LINE # 1642
?C0182:
			; SOURCE LINE # 1648
	MOV  	A,mode
	CJNE 	A,#02H,?C0183
			; SOURCE LINE # 1649
?C0411:
	CLR  	A
	MOV  	avst,A
	RET
			; SOURCE LINE # 1651
?C0183:
			; SOURCE LINE # 1657
	MOV  	A,cur_act
	CJNE 	A,#02H,?C0184
			; SOURCE LINE # 1658
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1659
	MOV  	R5,gear
	MOV  	R7,#02H
	LJMP 	?C0414
			; SOURCE LINE # 1661
?C0184:
			; SOURCE LINE # 1665
	LCALL	avoid_off
	JNC  	?C0185
			; SOURCE LINE # 1666
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1667
	MOV  	A,cur_act
	JZ   	?C0170
	MOV  	R5,gear
	MOV  	R7,A
?C0412:
	SJMP 	?C0414
			; SOURCE LINE # 1669
?C0185:
			; SOURCE LINE # 1671
	LCALL	us_read
	MOV  	d?2758,R7
			; SOURCE LINE # 1675
	MOV  	A,d?2758
	CLR  	C
	SUBB 	A,#03H
	JNC  	?C0187
			; SOURCE LINE # 1676
	LJMP 	av_gate_hold
			; SOURCE LINE # 1678
?C0187:
			; SOURCE LINE # 1688
	MOV  	A,avst
	XRL  	A,#04H
	JZ   	?C0189
	MOV  	A,avst
	CJNE 	A,#01H,?C0188
?C0189:
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
	JNC  	?C0188
			; SOURCE LINE # 1689
	MOV  	A,cur_act
	JZ   	?C0170
?C0190:
			; SOURCE LINE # 1690
	MOV  	R5,gear
	MOV  	R7,cur_act
?C0413:
	SJMP 	?C0414
			; SOURCE LINE # 1692
?C0188:
			; SOURCE LINE # 1695
	LCALL	tick_get
	MOV  	av_clear_t,R6
	MOV  	av_clear_t+01H,R7
			; SOURCE LINE # 1696
	MOV  	A,d?2758
	CLR  	C
	SUBB 	A,#0AH
	JNC  	?C0191
			; SOURCE LINE # 1697
	MOV  	avst,#01H
	SJMP 	?C0192
?C0191:
			; SOURCE LINE # 1698
	MOV  	A,d?2758
	CLR  	C
	SUBB 	A,#0EH
	JNC  	?C0193
			; SOURCE LINE # 1699
	SJMP 	?C0415
?C0193:
			; SOURCE LINE # 1702
	MOV  	A,avst
	JZ   	?C0196
	XRL  	A,#03H
	JZ   	?C0196
	MOV  	A,d?2758
	CLR  	C
	SUBB 	A,#028H
	JC   	?C0195
?C0196:
			; SOURCE LINE # 1703
	CLR  	A
	MOV  	avst,A
	SJMP 	?C0192
?C0195:
			; SOURCE LINE # 1705
?C0415:
	MOV  	avst,#04H
?C0192:
			; SOURCE LINE # 1719
	MOV  	A,cur_act
	JZ   	?C0170
?C0198:
			; SOURCE LINE # 1720
	MOV  	R5,gear
	MOV  	R7,cur_act
?C0414:
	LCALL	_motor_set_core
			; SOURCE LINE # 1721
?C0170:
	RET
; END OF av_gate

;--------------------------------------------------------------- ?PR?avoid_toggle?MAIN
avoid_toggle:
	USING	0
			; SOURCE LINE # 1730
			; SOURCE LINE # 1731
			; SOURCE LINE # 1732
	CPL  	us_avoid_on
			; SOURCE LINE # 1735
	JNB  	us_avoid_on,?C0199
			; SOURCE LINE # 1736
			; SOURCE LINE # 1737
	LCALL	L?0434
			; SOURCE LINE # 1738
	LCALL	d_20ms
			; SOURCE LINE # 1739
	MOV  	R7,#018H
			; SOURCE LINE # 1740
	SJMP 	?C0416
?C0199:
			; SOURCE LINE # 1741
	JB   	av_mnv,?C0201
			; SOURCE LINE # 1743
	CLR  	A
	MOV  	avst,A
?C0201:
			; SOURCE LINE # 1744
	MOV  	R7,#028H
?C0416:
	LCALL	_beep
			; SOURCE LINE # 1745
?C0200:
			; SOURCE LINE # 1749
	LJMP 	show_mode
; END OF avoid_toggle

;--------------------------------------------------------------- ?PR?meas_level?MAIN
meas_level:
	USING	0
			; SOURCE LINE # 1763
			; SOURCE LINE # 1764
			; SOURCE LINE # 1769
	CLR  	ET0
			; SOURCE LINE # 1770
	MOV  	R5,tick_h
			; SOURCE LINE # 1771
	MOV  	R4,tick_l
			; SOURCE LINE # 1772
	SETB 	ET0
			; SOURCE LINE # 1774
	MOV  	A,R5
	MOV  	R6,A
	MOV  	A,R4
	MOV  	R3,A
	MOV  	R2,AR6
			; SOURCE LINE # 1776
?C0203:
			; SOURCE LINE # 1777
	CLR  	ET0
			; SOURCE LINE # 1778
	MOV  	R5,tick_h
			; SOURCE LINE # 1779
	MOV  	R4,tick_l
			; SOURCE LINE # 1780
	SETB 	ET0
			; SOURCE LINE # 1781
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
			; SOURCE LINE # 1783
	MOV  	A,ml_cap
	JZ   	?C0205
			; SOURCE LINE # 1784
	MOV  	DPL,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0208
			; SOURCE LINE # 1785
			; SOURCE LINE # 1786
	SJMP 	?C0417
			; SOURCE LINE # 1787
			; SOURCE LINE # 1788
?C0205:
			; SOURCE LINE # 1789
	SETB 	C
	MOV  	A,R7
	SUBB 	A,#0FFH
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0208
			; SOURCE LINE # 1790
?C0417:
	MOV  	ml_dur,R6
	MOV  	ml_dur+01H,R7
			; SOURCE LINE # 1791
	SETB 	C
	RET
			; SOURCE LINE # 1792
			; SOURCE LINE # 1793
?C0208:
			; SOURCE LINE # 1795
	MOV  	A,ml_level
	JZ   	?C0210
			; SOURCE LINE # 1796
	JB   	IR_IN,?C0203
			; SOURCE LINE # 1797
			; SOURCE LINE # 1798
	SJMP 	?C0418
			; SOURCE LINE # 1799
			; SOURCE LINE # 1800
?C0210:
			; SOURCE LINE # 1801
	JNB  	IR_IN,?C0203
			; SOURCE LINE # 1802
?C0418:
	MOV  	ml_dur,R6
	MOV  	ml_dur+01H,R7
			; SOURCE LINE # 1803
	CLR  	C
			; SOURCE LINE # 1804
			; SOURCE LINE # 1805
			; SOURCE LINE # 1806
			; SOURCE LINE # 1807
?C0207:
	RET
; END OF meas_level

;--------------------------------------------------------------- ?PR?ir_reset?MAIN
ir_reset:
			; SOURCE LINE # 1825
			; SOURCE LINE # 1826
			; SOURCE LINE # 1827
	CLR  	A
	MOV  	ml_cap,A
			; SOURCE LINE # 1828
	MOV  	ir_ledlo,A
			; SOURCE LINE # 1829
	MOV  	ir_ledhi,A
			; SOURCE LINE # 1830
	CLR  	ir_short
			; SOURCE LINE # 1831
	MOV  	irstat,#01H
			; SOURCE LINE # 1832
	RET
; END OF ir_reset

;--------------------------------------------------------------- ?PR?_ir_setbit?MAIN
_ir_setbit:
			; SOURCE LINE # 1835
			; SOURCE LINE # 1836
			; SOURCE LINE # 1837
	MOV  	A,R7
	DEC  	A
	JZ   	?C0217
	DEC  	A
	JZ   	?C0218
	ADD  	A,#02H
	JNZ  	?C0219
			; SOURCE LINE # 1838
?C0216:
	MOV  	A,ir_maskb
	ORL  	ir_ib0,A
	RET
			; SOURCE LINE # 1839
?C0217:
	MOV  	A,ir_maskb
	ORL  	ir_ib1,A
	RET
			; SOURCE LINE # 1840
?C0218:
	MOV  	A,ir_maskb
	ORL  	ir_ib2,A
	RET
			; SOURCE LINE # 1841
?C0219:
	MOV  	A,ir_maskb
	ORL  	ir_ib3,A
			; SOURCE LINE # 1842
			; SOURCE LINE # 1843
?C0220:
	RET
; END OF _ir_setbit

;--------------------------------------------------------------- ?PR?ir_decode_bits?MAIN
ir_decode_bits:
	USING	0
			; SOURCE LINE # 1846
			; SOURCE LINE # 1847
			; SOURCE LINE # 1848
	CLR  	A
	MOV  	ir_ib0,A
			; SOURCE LINE # 1849
	MOV  	ir_ib1,A
			; SOURCE LINE # 1850
	MOV  	ir_ib2,A
			; SOURCE LINE # 1851
	MOV  	ir_ib3,A
			; SOURCE LINE # 1852
	MOV  	ir_bits,#020H
			; SOURCE LINE # 1853
	MOV  	ir_ptridx,A
			; SOURCE LINE # 1854
	MOV  	ir_maskb,#01H
?C0221:
			; SOURCE LINE # 1856
			; SOURCE LINE # 1858
	CLR  	A
	MOV  	ml_level,A
			; SOURCE LINE # 1859
	MOV  	ml_cap,A
			; SOURCE LINE # 1860
	LCALL	meas_level
	JNC  	?C0223
			; SOURCE LINE # 1861
	CLR  	C
	RET
?C0223:
			; SOURCE LINE # 1864
	MOV  	ml_level,#01H
			; SOURCE LINE # 1865
	MOV  	A,ir_bits
	CJNE 	A,#01H,?C0225
			; SOURCE LINE # 1868
	MOV  	ml_cap,#0CH
			; SOURCE LINE # 1869
	LCALL	meas_level
	JNC  	?C0227
			; SOURCE LINE # 1870
			; SOURCE LINE # 1871
	SJMP 	?C0419
?C0225:
			; SOURCE LINE # 1872
	CLR  	A
	MOV  	ml_cap,A
			; SOURCE LINE # 1873
	LCALL	meas_level
	JNC  	?C0228
			; SOURCE LINE # 1874
	CLR  	C
	RET
?C0228:
			; SOURCE LINE # 1875
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0BH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0227
			; SOURCE LINE # 1876
?C0419:
	MOV  	R7,ir_ptridx
	LCALL	_ir_setbit
			; SOURCE LINE # 1877
?C0227:
			; SOURCE LINE # 1880
	MOV  	A,ir_maskb
	ADD  	A,ACC
	MOV  	ir_maskb,A
			; SOURCE LINE # 1881
	JNZ  	?C0230
			; SOURCE LINE # 1882
	MOV  	ir_maskb,#01H
			; SOURCE LINE # 1883
	INC  	ir_ptridx
			; SOURCE LINE # 1884
?C0230:
			; SOURCE LINE # 1885
	DJNZ 	ir_bits,?C0221
			; SOURCE LINE # 1886
?C0222:
			; SOURCE LINE # 1889
	MOV  	A,ir_ib0
	CPL  	A
	XRL  	A,ir_ib1
	JZ   	?C0231
	CLR  	C
	RET
?C0231:
			; SOURCE LINE # 1890
	MOV  	A,ir_ib2
	CPL  	A
	XRL  	A,ir_ib3
	JZ   	?C0232
	CLR  	C
	RET
?C0232:
			; SOURCE LINE # 1891
	SETB 	C
			; SOURCE LINE # 1892
?C0224:
	RET
; END OF ir_decode_bits

;--------------------------------------------------------------- ?PR?ir_decode?MAIN
ir_decode:
	USING	0
			; SOURCE LINE # 1895
			; SOURCE LINE # 1896
			; SOURCE LINE # 1898
	CLR  	A
	MOV  	ml_level,A
			; SOURCE LINE # 1899
	MOV  	ml_cap,A
			; SOURCE LINE # 1900
	LCALL	meas_level
	JNC  	?C0233
			; SOURCE LINE # 1901
	SJMP 	?C0422
			; SOURCE LINE # 1903
?C0233:
			; SOURCE LINE # 1904
	MOV  	ir_ledlo,ml_dur+01H
			; SOURCE LINE # 1905
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0FFH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0235
			; SOURCE LINE # 1906
?C0420:
	SJMP 	?C0422
			; SOURCE LINE # 1908
?C0235:
			; SOURCE LINE # 1909
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#046H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0237
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#078H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0236
?C0237:
			; SOURCE LINE # 1910
?C0421:
	SJMP 	?C0422
			; SOURCE LINE # 1912
?C0236:
			; SOURCE LINE # 1919
	MOV  	ml_level,#01H
			; SOURCE LINE # 1920
	MOV  	ml_cap,#03CH
			; SOURCE LINE # 1921
	LCALL	meas_level
	JNC  	?C0238
			; SOURCE LINE # 1922
	MOV  	ir_ledhi,ml_dur+01H
			; SOURCE LINE # 1923
	SJMP 	?C0423
			; SOURCE LINE # 1925
?C0238:
			; SOURCE LINE # 1926
	MOV  	ir_ledhi,ml_dur+01H
			; SOURCE LINE # 1927
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0FFH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0239
			; SOURCE LINE # 1928
?C0423:
	MOV  	irstat,#03H
	RET
			; SOURCE LINE # 1930
?C0239:
			; SOURCE LINE # 1931
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0CH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JNC  	?C0240
			; SOURCE LINE # 1932
?C0422:
	MOV  	irstat,#02H
	RET
			; SOURCE LINE # 1934
?C0240:
			; SOURCE LINE # 1935
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#019H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JNC  	?C0241
			; SOURCE LINE # 1936
	SETB 	ir_short
?C0241:
			; SOURCE LINE # 1939
	LCALL	ir_decode_bits
	JNC  	?C0242
			; SOURCE LINE # 1940
	CLR  	A
	MOV  	irstat,A
	RET
			; SOURCE LINE # 1942
?C0242:
			; SOURCE LINE # 1945
	JNB  	ir_short,?C0243
	MOV  	R7,#03H
	SJMP 	?C0244
?C0243:
	MOV  	R7,#02H
?C0244:
	MOV  	irstat,R7
			; SOURCE LINE # 1946
?C0234:
	RET
; END OF ir_decode

;--------------------------------------------------------------- ?PR?ir_recv?MAIN
ir_recv:
	USING	0
			; SOURCE LINE # 1953
			; SOURCE LINE # 1954
			; SOURCE LINE # 1957
	LCALL	ir_reset
			; SOURCE LINE # 1960
	LCALL	tick_get
	MOV  	R3,AR7
	MOV  	R2,AR6
?C0245:
			; SOURCE LINE # 1961
	JNB  	IR_IN,?C0246
			; SOURCE LINE # 1962
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
	JC   	?C0245
	RET
?C0246:
			; SOURCE LINE # 1966
	LCALL	ir_decode
			; SOURCE LINE # 1967
?C0248:
	RET
; END OF ir_recv

;--------------------------------------------------------------- ?PR?ir_recv_nb?MAIN
ir_recv_nb:
	USING	0
			; SOURCE LINE # 1974
			; SOURCE LINE # 1975
			; SOURCE LINE # 1976
	LCALL	ir_reset
			; SOURCE LINE # 1977
	JB   	IR_IN,?C0250
?C0249:
			; SOURCE LINE # 1979
	LCALL	ir_decode
			; SOURCE LINE # 1980
?C0250:
	RET
; END OF ir_recv_nb

;--------------------------------------------------------------- ?PR?stamp_now?MAIN
stamp_now:
	USING	0
			; SOURCE LINE # 1983
			; SOURCE LINE # 1984
			; SOURCE LINE # 1985
	LCALL	tick_get
	MOV  	lastt,R6
	MOV  	lastt+01H,R7
			; SOURCE LINE # 1986
	RET
; END OF stamp_now

;--------------------------------------------------------------- ?PR?ir_errpr?MAIN
ir_errpr:
			; SOURCE LINE # 1989
			; SOURCE LINE # 1990
			; SOURCE LINE # 2008
	RET
; END OF ir_errpr

;--------------------------------------------------------------- ?PR?do_key?MAIN
do_key:
	USING	0
			; SOURCE LINE # 2013
			; SOURCE LINE # 2014
			; SOURCE LINE # 2020
	MOV  	A,avst
	CJNE 	A,#02H,?C0253
			; SOURCE LINE # 2021
	MOV  	avst,#03H
?C0253:
			; SOURCE LINE # 2028
	MOV  	A,ir_ib2
	CJNE 	A,#042H,?C0254
	LJMP 	rec_key
?C0254:
			; SOURCE LINE # 2029
	MOV  	A,ir_ib2
	CJNE 	A,#04AH,?C0256
	LJMP 	clr_key
?C0256:
			; SOURCE LINE # 2030
	MOV  	A,ir_ib2
	CJNE 	A,#052H,?C0257
	LJMP 	play_key
?C0257:
			; SOURCE LINE # 2038
	MOV  	A,ir_ib2
	CJNE 	A,#01CH,?C0258
			; SOURCE LINE # 2039
	LJMP 	avoid_toggle
			; SOURCE LINE # 2041
?C0258:
			; SOURCE LINE # 2044
	MOV  	R7,ir_ib2
	LCALL	_key2mode
	MOV  	R4,AR7
			; SOURCE LINE # 2045
	MOV  	A,R4
	CPL  	A
	JZ   	?C0259
			; SOURCE LINE # 2046
	JNB  	recon,?C0260
			; SOURCE LINE # 2049
			; SOURCE LINE # 2050
	LCALL	L?0434
			; SOURCE LINE # 2051
	SJMP 	?C0427
			; SOURCE LINE # 2053
?C0260:
			; SOURCE LINE # 2054
	MOV  	A,R4
	CJNE 	A,mode,?C0261
			; SOURCE LINE # 2055
?C0424:
	SJMP 	?C0427
			; SOURCE LINE # 2057
?C0261:
			; SOURCE LINE # 2058
	MOV  	R7,AR4
	LJMP 	_mode_goto
			; SOURCE LINE # 2060
?C0259:
			; SOURCE LINE # 2063
	MOV  	A,ir_ib2
	CJNE 	A,#05AH,?C0262
			; SOURCE LINE # 2064
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0255
?C0263:
			; SOURCE LINE # 2066
	INC  	gear
			; SOURCE LINE # 2067
	SJMP 	?C0264
?C0262:
	MOV  	A,ir_ib2
	CJNE 	A,#08H,?C0265
			; SOURCE LINE # 2068
	MOV  	A,gear
	JZ   	?C0255
?C0266:
			; SOURCE LINE # 2070
	DEC  	gear
			; SOURCE LINE # 2071
	SJMP 	?C0264
?C0265:
			; SOURCE LINE # 2075
	MOV  	R7,ir_ib2
	LCALL	_key2act
			; SOURCE LINE # 2077
	MOV  	A,R7
	CPL  	A
	JZ   	?C0255
			; SOURCE LINE # 2080
?C0268:
			; SOURCE LINE # 2083
	JNB  	av_mnv,?C0269
			; SOURCE LINE # 2084
	CLR  	av_mnv
			; SOURCE LINE # 2085
	MOV  	avst,#03H
			; SOURCE LINE # 2086
?C0269:
			; SOURCE LINE # 2088
	MOV  	A,R7
	JNZ  	?C0270
			; SOURCE LINE # 2089
	MOV  	cur_act,A
			; SOURCE LINE # 2090
	MOV  	R5,A
	MOV  	R7,A
			; SOURCE LINE # 2091
	SJMP 	?C0426
?C0270:
			; SOURCE LINE # 2092
	MOV  	A,gear
	JNZ  	?C0272
			; SOURCE LINE # 2093
	MOV  	gear,#03H
?C0272:
			; SOURCE LINE # 2094
	MOV  	cur_act,R7
			; SOURCE LINE # 2095
	MOV  	R5,gear
?C0426:
	LCALL	_motor_set_core
			; SOURCE LINE # 2096
?C0271:
			; SOURCE LINE # 2098
	LCALL	show_state
			; SOURCE LINE # 2100
?C0425:
	SJMP 	?C0427
			; SOURCE LINE # 2102
?C0264:
			; SOURCE LINE # 2105
	MOV  	A,cur_act
	JZ   	?C0273
			; SOURCE LINE # 2106
	MOV  	R5,gear
	MOV  	R7,A
	LCALL	_motor_set_core
?C0273:
			; SOURCE LINE # 2107
	LCALL	show_state
			; SOURCE LINE # 2108
?C0427:
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2110
?C0255:
	RET
; END OF do_key

;--------------------------------------------------------------- ?PR?ir_holdchk?MAIN
ir_holdchk:
	USING	0
			; SOURCE LINE # 2120
			; SOURCE LINE # 2121
			; SOURCE LINE # 2124
	MOV  	A,cur_act
	JZ   	?C0275
?C0274:
			; SOURCE LINE # 2127
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0276
	JB   	recon,?C0276
			; SOURCE LINE # 2128
	MOV  	A,cur_act
	XRL  	A,#01H
	JZ   	?C0275
?C0277:
			; SOURCE LINE # 2130
?C0276:
			; SOURCE LINE # 2132
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,lastt+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,lastt
	MOV  	R6,A
			; SOURCE LINE # 2133
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0B8H
	MOV  	A,R6
	SUBB 	A,#0BH
	JC   	?C0275
?C0278:
			; SOURCE LINE # 2139
	JNB  	av_mnv,?C0279
			; SOURCE LINE # 2140
	CLR  	A
	MOV  	cur_act,A
	RET
			; SOURCE LINE # 2143
?C0279:
			; SOURCE LINE # 2147
	JB   	recon,?C0280
	MOV  	A,cur_act
	XRL  	A,#05H
	JZ   	?C0281
	MOV  	A,cur_act
	CJNE 	A,#06H,?C0280
?C0281:
			; SOURCE LINE # 2148
	MOV  	cur_act,#01H
	SJMP 	?C0282
?C0280:
			; SOURCE LINE # 2150
	CLR  	A
	MOV  	cur_act,A
?C0282:
			; SOURCE LINE # 2152
	MOV  	A,cur_act
	JNZ  	?C0283
	MOV  	R5,A
	SJMP 	?C0284
?C0283:
	MOV  	R7,gear
	MOV  	R5,AR7
?C0284:
			; SOURCE LINE # 2153
	LCALL	L?0438
			; SOURCE LINE # 2154
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2156
	MOV  	A,avst
	CJNE 	A,#03H,?C0275
			; SOURCE LINE # 2157
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 2159
?C0275:
	RET
; END OF ir_holdchk

;--------------------------------------------------------------- ?PR?back_guard?MAIN
back_guard:
	USING	0
			; SOURCE LINE # 2166
			; SOURCE LINE # 2167
			; SOURCE LINE # 2168
	JB   	av_mnv,?C0287
?C0286:
			; SOURCE LINE # 2171
	MOV  	A,mode
	JNZ  	?C0287
?C0288:
			; SOURCE LINE # 2174
	MOV  	A,cur_act
	XRL  	A,#02H
	JZ   	?C0289
			; SOURCE LINE # 2175
	CLR  	back_on
	RET
			; SOURCE LINE # 2177
?C0289:
			; SOURCE LINE # 2179
	JB   	back_on,?C0290
			; SOURCE LINE # 2180
	SETB 	back_on
			; SOURCE LINE # 2181
	LCALL	tick_get
	MOV  	back_t0,R6
	MOV  	back_t0+01H,R7
	RET
			; SOURCE LINE # 2183
?C0290:
			; SOURCE LINE # 2185
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
	JC   	?C0287
?C0291:
			; SOURCE LINE # 2189
	CLR  	back_on
			; SOURCE LINE # 2190
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 2191
	MOV  	R5,A
	MOV  	R7,A
	LCALL	_motor_set_core
			; SOURCE LINE # 2192
	LCALL	show_state
			; SOURCE LINE # 2194
			; SOURCE LINE # 2195
	LCALL	L?0435
			; SOURCE LINE # 2196
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2197
?C0287:
	RET
; END OF back_guard

;--------------------------------------------------------------- ?PR?prox_beep?MAIN
prox_beep:
	USING	0
			; SOURCE LINE # 2211
			; SOURCE LINE # 2212
			; SOURCE LINE # 2215
	JNB  	av_mnv,$ + 6H
	LJMP 	?C0293
?C0292:
			; SOURCE LINE # 2218
	LCALL	avoid_off
	JC   	$ + 5H
	LJMP 	?C0293
?C0294:
			; SOURCE LINE # 2221
	MOV  	A,mode
	XRL  	A,#01H
	JNZ  	$ + 5H
	LJMP 	?C0293
?C0295:
			; SOURCE LINE # 2224
	MOV  	A,mode
	XRL  	A,#03H
	JNZ  	$ + 5H
	LJMP 	?C0293
	MOV  	A,mode
	XRL  	A,#02H
	JNZ  	$ + 5H
	LJMP 	?C0293
?C0296:
			; SOURCE LINE # 2228
	MOV  	A,cur_act
	CJNE 	A,#02H,?C0298
			; SOURCE LINE # 2229
	CLR  	prox_moving
			; SOURCE LINE # 2230
	CLR  	prox_hold
	RET
			; SOURCE LINE # 2232
?C0298:
			; SOURCE LINE # 2235
	MOV  	A,cur_act
	JNZ  	?C0299
			; SOURCE LINE # 2236
	JNB  	prox_moving,?C0300
			; SOURCE LINE # 2237
	CLR  	prox_moving
			; SOURCE LINE # 2238
	SETB 	prox_hold
			; SOURCE LINE # 2239
	LCALL	tick_get
	MOV  	prox_stop_t,R6
	MOV  	prox_stop_t+01H,R7
			; SOURCE LINE # 2240
?C0300:
			; SOURCE LINE # 2241
	JNB  	prox_hold,?C0301
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
	JC   	?C0301
			; SOURCE LINE # 2242
	CLR  	prox_hold
?C0301:
			; SOURCE LINE # 2243
	JB   	prox_hold,?C0303
	RET
?C0299:
			; SOURCE LINE # 2246
	SETB 	prox_moving
			; SOURCE LINE # 2247
	CLR  	prox_hold
			; SOURCE LINE # 2248
?C0303:
			; SOURCE LINE # 2250
	LCALL	us_read
	MOV  	R6,#00H
			; SOURCE LINE # 2251
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0EH
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0293
?C0304:
			; SOURCE LINE # 2254
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#03H
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0305
	MOV  	A,cur_act
	JZ   	?C0305
			; SOURCE LINE # 2256
	MOV  	R7,#0C8H
	SJMP 	?C0428
			; SOURCE LINE # 2258
?C0305:
			; SOURCE LINE # 2264
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#03H
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0306
			; SOURCE LINE # 2265
	MOV  	R2,#03H
	MOV  	R3,#0E8H
	SJMP 	?C0307
?C0306:
			; SOURCE LINE # 2267
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
?C0307:
			; SOURCE LINE # 2268
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
	JC   	?C0293
?C0308:
			; SOURCE LINE # 2270
	LCALL	tick_get
	MOV  	prox_t,R6
	MOV  	prox_t+01H,R7
			; SOURCE LINE # 2272
	MOV  	R7,#018H
?C0428:
	LCALL	_beep
			; SOURCE LINE # 2273
?C0293:
	RET
; END OF prox_beep

;--------------------------------------------------------------- ?PR?rec_halt?MAIN
rec_halt:
	USING	0
			; SOURCE LINE # 2286
			; SOURCE LINE # 2287
			; SOURCE LINE # 2288
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 2289
	MOV  	R5,A
	MOV  	R7,A
	LJMP 	_motor_set_core
; END OF rec_halt

;--------------------------------------------------------------- ?PR?rec_commit?MAIN
rec_commit:
	USING	0
			; SOURCE LINE # 2296
			; SOURCE LINE # 2297
			; SOURCE LINE # 2300
	MOV  	A,pack
	ANL  	A,#0F0H
	JNZ  	?C0310
	MOV  	A,recn
	JNZ  	?C0310
			; SOURCE LINE # 2301
			; SOURCE LINE # 2302
	SJMP 	?C0429
			; SOURCE LINE # 2303
?C0310:
			; SOURCE LINE # 2305
	MOV  	A,recn
	CLR  	C
	SUBB 	A,#050H
	JC   	?C0312
			; SOURCE LINE # 2306
	SETB 	recfull
			; SOURCE LINE # 2307
	RET
			; SOURCE LINE # 2308
?C0312:
			; SOURCE LINE # 2310
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
			; SOURCE LINE # 2311
	MOV  	DPL,R5
	MOV  	DPH,A
	MOV  	A,pack
	MOVX 	@DPTR,A
			; SOURCE LINE # 2312
	INC  	DPTR
	MOV  	A,cur_dur+01H
	MOVX 	@DPTR,A
			; SOURCE LINE # 2313
	MOV  	A,cur_dur
	MOV  	DPL,R5
	MOV  	DPH,R4
	INC  	DPTR
	INC  	DPTR
	MOVX 	@DPTR,A
			; SOURCE LINE # 2315
	INC  	recn
			; SOURCE LINE # 2316
	MOV  	A,recn
	CLR  	C
	SUBB 	A,#050H
	JC   	?C0313
			; SOURCE LINE # 2317
	SETB 	recfull
?C0313:
			; SOURCE LINE # 2319
	CLR  	A
?C0429:
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2320
	SETB 	C
			; SOURCE LINE # 2321
?C0311:
	RET
; END OF rec_commit

;--------------------------------------------------------------- ?PR?rec_err?MAIN
rec_err:
	USING	0
			; SOURCE LINE # 2324
			; SOURCE LINE # 2325
			; SOURCE LINE # 2326
	MOV  	R7,#061H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2327
			; SOURCE LINE # 2328
	LCALL	L?0435
			; SOURCE LINE # 2329
	LCALL	d_20ms
			; SOURCE LINE # 2330
			; SOURCE LINE # 2331
	LCALL	L?0435
			; SOURCE LINE # 2332
	LCALL	d_20ms
			; SOURCE LINE # 2333
	LJMP 	show_state
; END OF rec_err

;--------------------------------------------------------------- ?PR?rec_fullstop?MAIN
rec_fullstop:
	USING	0
			; SOURCE LINE # 2338
			; SOURCE LINE # 2339
			; SOURCE LINE # 2342
	CLR  	recon
			; SOURCE LINE # 2343
	CLR  	A
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2344
	LCALL	rec_halt
			; SOURCE LINE # 2346
	CLR  	A
	MOV  	i?4571,A
?C0315:
			; SOURCE LINE # 2347
	MOV  	R7,#071H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2348
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2349
	LCALL	d_20ms
			; SOURCE LINE # 2350
	INC  	i?4571
	MOV  	A,i?4571
	CLR  	C
	SUBB 	A,#014H
	JC   	?C0315
?C0316:
			; SOURCE LINE # 2351
	LJMP 	show_state
; END OF rec_fullstop

;--------------------------------------------------------------- ?PR?rec_sample?MAIN
rec_sample:
	USING	0
			; SOURCE LINE # 2360
			; SOURCE LINE # 2361
			; SOURCE LINE # 2365
	JNB  	recfull,?C0319
			; SOURCE LINE # 2366
	LJMP 	rec_fullstop
			; SOURCE LINE # 2368
?C0319:
			; SOURCE LINE # 2370
	LCALL	ms10_get
			; SOURCE LINE # 2371
	CLR  	C
	MOV  	A,R7
	SUBB 	A,samp+01H
	MOV  	R5,A
	MOV  	A,R6
	SUBB 	A,samp
	MOV  	R4,A
			; SOURCE LINE # 2372
	ORL  	A,R5
	JZ   	?C0320
?C0321:
			; SOURCE LINE # 2374
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2376
	MOV  	A,cur_act
	SWAP 	A
	ANL  	A,#0F0H
	MOV  	R7,A
	MOV  	A,gear
	ANL  	A,#0FH
	ORL  	A,R7
	MOV  	R1,A
			; SOURCE LINE # 2378
	CJNE 	A,pack,?C0322
			; SOURCE LINE # 2379
	MOV  	A,cur_dur+01H
	ADD  	A,R5
	MOV  	R7,A
	MOV  	A,cur_dur
	ADDC 	A,R4
	MOV  	R6,A
			; SOURCE LINE # 2380
	CLR  	C
	MOV  	A,R7
	SUBB 	A,cur_dur+01H
	MOV  	A,R6
	SUBB 	A,cur_dur
	JNC  	?C0323
			; SOURCE LINE # 2381
	SJMP 	?C0430
			; SOURCE LINE # 2383
?C0323:
			; SOURCE LINE # 2384
	MOV  	cur_dur,R6
	MOV  	cur_dur+01H,R7
			; SOURCE LINE # 2385
	MOV  	A,cur_dur
	CLR  	C
	SUBB 	A,#0BH
	CLR  	A
	SUBB 	A,#00H
	JC   	?C0320
			; SOURCE LINE # 2386
?C0430:
	LJMP 	rec_commit
			; SOURCE LINE # 2388
?C0322:
			; SOURCE LINE # 2391
	LCALL	rec_commit
	JNC  	?C0320
			; SOURCE LINE # 2392
	MOV  	pack,R1
			; SOURCE LINE # 2393
?C0320:
	RET
; END OF rec_sample

;--------------------------------------------------------------- ?PR?rec_enter?MAIN
rec_enter:
	USING	0
			; SOURCE LINE # 2396
			; SOURCE LINE # 2397
			; SOURCE LINE # 2398
	LCALL	rec_halt
			; SOURCE LINE # 2399
	CLR  	A
	MOV  	recn,A
			; SOURCE LINE # 2400
	CLR  	recfull
			; SOURCE LINE # 2401
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2402
	LCALL	ms10_get
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2403
	MOV  	A,gear
	ANL  	A,#0FH
	MOV  	pack,A
			; SOURCE LINE # 2404
	SETB 	recon
			; SOURCE LINE # 2405
	LCALL	show_state
			; SOURCE LINE # 2406
	MOV  	R7,#028H
	LJMP 	_beep
; END OF rec_enter

;--------------------------------------------------------------- ?PR?rec_exit?MAIN
rec_exit:
	USING	0
			; SOURCE LINE # 2410
			; SOURCE LINE # 2411
			; SOURCE LINE # 2412
	MOV  	A,cur_dur+01H
	ORL  	A,cur_dur
	JZ   	?C0327
			; SOURCE LINE # 2413
	LCALL	rec_commit
?C0327:
			; SOURCE LINE # 2414
	CLR  	recon
			; SOURCE LINE # 2415
	CLR  	A
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2416
	LCALL	show_state
			; SOURCE LINE # 2417
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2418
	LCALL	d_20ms
			; SOURCE LINE # 2419
	MOV  	R7,#028H
	LJMP 	_beep
; END OF rec_exit

;--------------------------------------------------------------- ?PR?rec_key?MAIN
rec_key:
	USING	0
			; SOURCE LINE # 2423
			; SOURCE LINE # 2424
			; SOURCE LINE # 2425
	JNB  	recon,?C0329
	LJMP 	rec_exit
?C0329:
			; SOURCE LINE # 2426
	LCALL	rec_enter
			; SOURCE LINE # 2427
?C0331:
	RET
; END OF rec_key

;--------------------------------------------------------------- ?PR?clr_key?MAIN
clr_key:
	USING	0
			; SOURCE LINE # 2431
			; SOURCE LINE # 2432
			; SOURCE LINE # 2433
	MOV  	A,mode
	XRL  	A,#03H
	JZ   	?C0333
?C0332:
			; SOURCE LINE # 2435
	MOV  	A,cur_act
	JNZ  	?C0333
?C0334:
			; SOURCE LINE # 2438
	CLR  	recon
			; SOURCE LINE # 2439
	CLR  	A
	MOV  	recn,A
			; SOURCE LINE # 2440
	CLR  	recfull
			; SOURCE LINE # 2441
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2442
	LCALL	show_state
			; SOURCE LINE # 2443
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2444
	LCALL	d_20ms
			; SOURCE LINE # 2445
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2446
?C0333:
	RET
; END OF clr_key

;--------------------------------------------------------------- ?PR?play_load?MAIN
play_load:
	USING	0
			; SOURCE LINE # 2459
			; SOURCE LINE # 2460
			; SOURCE LINE # 2461
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
			; SOURCE LINE # 2462
	MOV  	DPL,R5
	MOV  	DPH,A
	MOVX 	A,@DPTR
	MOV  	R3,A
			; SOURCE LINE # 2465
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
			; SOURCE LINE # 2467
	MOV  	A,R3
	ANL  	A,#0FH
	MOV  	gear,A
			; SOURCE LINE # 2468
	MOV  	A,R3
	SWAP 	A
	ANL  	A,#0FH
	MOV  	cur_act,A
			; SOURCE LINE # 2470
	MOV  	R5,gear
	MOV  	R7,A
	LCALL	_motor_set_core
			; SOURCE LINE # 2471
	LCALL	ms10_get
	MOV  	play_t0,R6
	MOV  	play_t0+01H,R7
			; SOURCE LINE # 2472
	RET
; END OF play_load

;--------------------------------------------------------------- ?PR?play_safety?MAIN
play_safety:
	USING	0
			; SOURCE LINE # 2479
			; SOURCE LINE # 2480
			; SOURCE LINE # 2483
	LCALL	ir_det
	JNC  	?C0336
			; SOURCE LINE # 2484
	RET
?C0336:
			; SOURCE LINE # 2486
	LCALL	ms10_get
			; SOURCE LINE # 2487
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
	JNC  	?C0338
			; SOURCE LINE # 2488
	CLR  	C
	RET
?C0338:
			; SOURCE LINE # 2489
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2491
	LCALL	us_read
	MOV  	A,R7
	CLR  	C
	SUBB 	A,#03H
	JNC  	?C0339
			; SOURCE LINE # 2492
	RET
?C0339:
			; SOURCE LINE # 2493
	CLR  	C
			; SOURCE LINE # 2494
?C0337:
	RET
; END OF play_safety

;--------------------------------------------------------------- ?PR?play_exit?MAIN
play_exit:
	USING	0
			; SOURCE LINE # 2497
			; SOURCE LINE # 2498
			; SOURCE LINE # 2499
	LCALL	rec_halt
			; SOURCE LINE # 2500
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 2501
	MOV  	gear,play_gear0
			; SOURCE LINE # 2502
	MOV  	avst,A
			; SOURCE LINE # 2503
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2504
	MOV  	playidx,A
			; SOURCE LINE # 2505
	LJMP 	show_state
; END OF play_exit

;--------------------------------------------------------------- ?PR?play_abort?MAIN
play_abort:
	USING	0
			; SOURCE LINE # 2510
			; SOURCE LINE # 2511
			; SOURCE LINE # 2512
	SETB 	playerr
			; SOURCE LINE # 2513
	LCALL	rec_halt
			; SOURCE LINE # 2514
			; SOURCE LINE # 2515
	LCALL	L?0435
			; SOURCE LINE # 2516
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2517
	LJMP 	play_exit
; END OF play_abort

;--------------------------------------------------------------- ?PR?play_enter?MAIN
play_enter:
	USING	0
			; SOURCE LINE # 2521
			; SOURCE LINE # 2522
			; SOURCE LINE # 2523
	MOV  	A,recn
	JNZ  	?C0342
			; SOURCE LINE # 2524
	LJMP 	rec_err
			; SOURCE LINE # 2526
?C0342:
			; SOURCE LINE # 2528
	MOV  	play_gear0,gear
			; SOURCE LINE # 2531
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 2532
	MOV  	playidx,A
			; SOURCE LINE # 2533
	MOV  	cur_act,A
			; SOURCE LINE # 2534
	MOV  	mode,#03H
			; SOURCE LINE # 2535
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2536
	LCALL	play_load
			; SOURCE LINE # 2537
	LCALL	show_mode
			; SOURCE LINE # 2538
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2539
?C0343:
	RET
; END OF play_enter

;--------------------------------------------------------------- ?PR?play_step?MAIN
play_step:
	USING	0
			; SOURCE LINE # 2545
			; SOURCE LINE # 2546
			; SOURCE LINE # 2549
	LCALL	play_safety
	JNC  	?C0344
			; SOURCE LINE # 2550
	LJMP 	play_abort
			; SOURCE LINE # 2552
?C0344:
			; SOURCE LINE # 2554
	LCALL	ir_recv_nb
			; SOURCE LINE # 2555
	MOV  	A,irstat
	JNZ  	?C0346
			; SOURCE LINE # 2556
	MOV  	A,ir_ib2
	CJNE 	A,#052H,?C0347
			; SOURCE LINE # 2557
	SJMP 	?C0432
			; SOURCE LINE # 2559
?C0347:
			; SOURCE LINE # 2562
	MOV  	R7,ir_ib2
	LCALL	_key2act
	MOV  	A,R7
	CPL  	A
	JZ   	?C0346
			; SOURCE LINE # 2563
?C0431:
	SJMP 	?C0432
			; SOURCE LINE # 2565
			; SOURCE LINE # 2566
?C0346:
			; SOURCE LINE # 2569
	LCALL	ms10_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,play_t0+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,play_t0
	MOV  	R6,A
			; SOURCE LINE # 2570
	CLR  	C
	MOV  	A,R7
	SUBB 	A,play_dur+01H
	MOV  	A,R6
	SUBB 	A,play_dur
	JC   	?C0345
?C0349:
			; SOURCE LINE # 2573
	INC  	playidx
			; SOURCE LINE # 2574
	MOV  	A,playidx
	CLR  	C
	SUBB 	A,recn
	JC   	?C0350
			; SOURCE LINE # 2575
?C0432:
	LJMP 	play_exit
			; SOURCE LINE # 2577
?C0350:
			; SOURCE LINE # 2578
	LCALL	play_load
			; SOURCE LINE # 2579
?C0345:
	RET
; END OF play_step

;--------------------------------------------------------------- ?PR?play_key?MAIN
play_key:
	USING	0
			; SOURCE LINE # 2583
			; SOURCE LINE # 2584
			; SOURCE LINE # 2585
	JNB  	recon,?C0351
			; SOURCE LINE # 2586
	LCALL	rec_exit
	SJMP 	?C0352
?C0351:
			; SOURCE LINE # 2587
	MOV  	A,mode
	CJNE 	A,#03H,?C0352
			; SOURCE LINE # 2588
	LJMP 	play_exit
			; SOURCE LINE # 2590
?C0352:
			; SOURCE LINE # 2591
	LCALL	play_enter
			; SOURCE LINE # 2592
?C0354:
	RET
; END OF play_key

;--------------------------------------------------------------- ?PR?manual_step?MAIN
manual_step:
	USING	0
			; SOURCE LINE # 2597
			; SOURCE LINE # 2598
			; SOURCE LINE # 2599
	LCALL	ir_recv
			; SOURCE LINE # 2601
	MOV  	A,irstat
	JNZ  	?C0355
			; SOURCE LINE # 2602
	LCALL	stamp_now
			; SOURCE LINE # 2603
	MOV  	lastcmd,ir_ib2
			; SOURCE LINE # 2604
	LCALL	do_key
			; SOURCE LINE # 2605
	SJMP 	?C0356
?C0355:
	MOV  	A,irstat
	CJNE 	A,#03H,?C0357
			; SOURCE LINE # 2606
	LCALL	stamp_now
			; SOURCE LINE # 2607
	SJMP 	?C0356
?C0357:
	MOV  	A,irstat
	CJNE 	A,#02H,?C0356
			; SOURCE LINE # 2608
	LCALL	ir_errpr
			; SOURCE LINE # 2612
?C0356:
			; SOURCE LINE # 2621
			; SOURCE LINE # 2622
	LJMP 	ir_holdchk
; END OF manual_step

;--------------------------------------------------------------- ?PR?auto_step?MAIN
auto_step:
	USING	0
			; SOURCE LINE # 2630
			; SOURCE LINE # 2631
			; SOURCE LINE # 2634
	LCALL	ir_recv
			; SOURCE LINE # 2635
	MOV  	A,irstat
	JNZ  	?C0363
?C0362:
			; SOURCE LINE # 2638
	MOV  	A,ir_ib2
	CJNE 	A,#040H,?C0364
			; SOURCE LINE # 2639
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 2640
	MOV  	cur_act,A
			; SOURCE LINE # 2641
	MOV  	R5,A
	MOV  	R7,A
	LCALL	_motor_set_core
			; SOURCE LINE # 2642
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2643
	LCALL	show_state
			; SOURCE LINE # 2644
	MOV  	R7,#028H
	LJMP 	_beep
			; SOURCE LINE # 2646
?C0364:
			; SOURCE LINE # 2648
	MOV  	R7,ir_ib2
	LCALL	_key2mode
			; SOURCE LINE # 2649
	MOV  	A,R7
	CPL  	A
	JZ   	?C0365
			; SOURCE LINE # 2650
	MOV  	A,R7
	XRL  	A,mode
	JZ   	?C0363
			; SOURCE LINE # 2651
	LJMP 	_mode_goto
			; SOURCE LINE # 2653
?C0365:
			; SOURCE LINE # 2656
	MOV  	A,ir_ib2
	CJNE 	A,#01CH,?C0367
			; SOURCE LINE # 2657
	LJMP 	avoid_toggle
			; SOURCE LINE # 2659
?C0367:
			; SOURCE LINE # 2661
	MOV  	A,ir_ib2
	CJNE 	A,#05AH,?C0368
			; SOURCE LINE # 2662
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0363
			; SOURCE LINE # 2663
	INC  	gear
			; SOURCE LINE # 2664
			; SOURCE LINE # 2665
			; SOURCE LINE # 2666
	SJMP 	?C0433
?C0368:
	MOV  	A,ir_ib2
	CJNE 	A,#08H,?C0363
			; SOURCE LINE # 2667
	MOV  	A,gear
	SETB 	C
	SUBB 	A,#00H
	JC   	?C0363
			; SOURCE LINE # 2668
	DEC  	gear
			; SOURCE LINE # 2669
?C0433:
	LCALL	ml_apply
			; SOURCE LINE # 2670
			; SOURCE LINE # 2671
			; SOURCE LINE # 2672
?C0363:
	RET
; END OF auto_step

;--------------------------------------------------------------- ?PR?ml_apply?MAIN
ml_apply:
	USING	0
			; SOURCE LINE # 2679
			; SOURCE LINE # 2680
			; SOURCE LINE # 2682
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2684
	MOV  	A,mode
	JZ   	?C0373
			; SOURCE LINE # 2685
	LJMP 	show_mode
			; SOURCE LINE # 2688
?C0373:
			; SOURCE LINE # 2690
	MOV  	A,gear
	JZ   	?C0376
	MOV  	A,cur_act
	JNZ  	?C0375
?C0376:
			; SOURCE LINE # 2691
	LJMP 	apply_gear_core
			; SOURCE LINE # 2692
?C0375:
			; SOURCE LINE # 2693
	MOV  	R5,gear
			; SOURCE LINE # 2694
	LCALL	L?0438
			; SOURCE LINE # 2695
			; SOURCE LINE # 2697
?C0374:
	RET
; END OF ml_apply

;--------------------------------------------------------------- ?PR?init_all?MAIN
init_all:
	USING	0
			; SOURCE LINE # 2782
			; SOURCE LINE # 2783
			; SOURCE LINE # 2785
	CLR  	A
	MOV  	pwm_div,A
			; SOURCE LINE # 2786
	MOV  	pwm_cnt,A
			; SOURCE LINE # 2787
	MOV  	buz_left,A
			; SOURCE LINE # 2788
	SETB 	buz_quiet
			; SOURCE LINE # 2789
	MOV  	dirbits,A
			; SOURCE LINE # 2790
	MOV  	duty_a,A
			; SOURCE LINE # 2791
	MOV  	duty_b,A
			; SOURCE LINE # 2792
	MOV  	gear,A
			; SOURCE LINE # 2793
	MOV  	klast,A
			; SOURCE LINE # 2794
	MOV  	cur_act,A
			; SOURCE LINE # 2795
	CLR  	back_on
			; SOURCE LINE # 2796
	MOV  	back_t0,A
	MOV  	back_t0+01H,A
			; SOURCE LINE # 2797
	MOV  	prox_t,A
	MOV  	prox_t+01H,A
			; SOURCE LINE # 2798
	CLR  	prox_moving
			; SOURCE LINE # 2799
	CLR  	prox_hold
			; SOURCE LINE # 2800
	MOV  	prox_stop_t,A
	MOV  	prox_stop_t+01H,A
			; SOURCE LINE # 2801
	MOV  	av_beep_n,A
			; SOURCE LINE # 2802
	CLR  	av_clear_on
			; SOURCE LINE # 2803
	MOV  	av_clear_t,A
	MOV  	av_clear_t+01H,A
			; SOURCE LINE # 2806
	MOV  	tick_l,A
			; SOURCE LINE # 2807
	MOV  	tick_h,A
			; SOURCE LINE # 2808
	MOV  	irstat,#01H
			; SOURCE LINE # 2809
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2810
	MOV  	lastt,A
	MOV  	lastt+01H,A
			; SOURCE LINE # 2811
	MOV  	last_err,A
	MOV  	last_err+01H,A
			; SOURCE LINE # 2812
	MOV  	ir_ledlo,A
			; SOURCE LINE # 2813
	MOV  	ir_ledhi,A
			; SOURCE LINE # 2816
	MOV  	mode,A
			; SOURCE LINE # 2817
	SETB 	us_avoid_on
			; SOURCE LINE # 2818
	MOV  	avst,A
			; SOURCE LINE # 2819
	MOV  	av_beep_t,A
	MOV  	av_beep_t+01H,A
			; SOURCE LINE # 2822
	CLR  	recon
			; SOURCE LINE # 2823
	CLR  	playerr
			; SOURCE LINE # 2824
	CLR  	recfull
			; SOURCE LINE # 2825
	MOV  	ms_div,A
			; SOURCE LINE # 2826
	MOV  	ms10_l,A
			; SOURCE LINE # 2827
	MOV  	ms10_h,A
			; SOURCE LINE # 2828
	MOV  	pack,A
			; SOURCE LINE # 2829
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2830
	MOV  	samp,A
	MOV  	samp+01H,A
			; SOURCE LINE # 2831
	MOV  	recn,A
			; SOURCE LINE # 2832
	MOV  	playidx,A
			; SOURCE LINE # 2833
	MOV  	play_dur,A
	MOV  	play_dur+01H,A
			; SOURCE LINE # 2834
	MOV  	play_t0,A
	MOV  	play_t0+01H,A
			; SOURCE LINE # 2835
	MOV  	play_gear0,A
			; SOURCE LINE # 2844
	MOV  	P0,#0C0H
			; SOURCE LINE # 2845
	MOV  	P1,#0FFH
			; SOURCE LINE # 2846
	MOV  	R7,#03H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2847
	MOV  	P3,#0FFH
			; SOURCE LINE # 2850
	LCALL	us_init
			; SOURCE LINE # 2863
	CLR  	A
	MOV  	ir_inv,A
			; SOURCE LINE # 2867
	MOV  	TMOD,#022H
			; SOURCE LINE # 2868
	MOV  	TH1,#0FDH
			; SOURCE LINE # 2869
	MOV  	TL1,#0FDH
			; SOURCE LINE # 2870
	MOV  	SCON,#050H
			; SOURCE LINE # 2871
	MOV  	PCON,A
			; SOURCE LINE # 2872
	SETB 	TR1
			; SOURCE LINE # 2874
	MOV  	TH0,#0A4H
			; SOURCE LINE # 2875
	MOV  	TL0,#0A4H
			; SOURCE LINE # 2876
	SETB 	ET0
			; SOURCE LINE # 2877
	SETB 	EA
			; SOURCE LINE # 2878
	SETB 	TR0
			; SOURCE LINE # 2880
	LCALL	tick_get
	MOV  	lastt,R6
	MOV  	lastt+01H,R7
			; SOURCE LINE # 2881
	LCALL	tick_get
	MOV  	prox_stop_t,R6
	MOV  	prox_stop_t+01H,R7
			; SOURCE LINE # 2883
	LJMP 	apply_gear_core
; END OF init_all

;--------------------------------------------------------------- ?PR?main?MAIN
main:
	USING	0
			; SOURCE LINE # 2969
			; SOURCE LINE # 2970
			; SOURCE LINE # 2973
	LCALL	init_all
?C0379:
			; SOURCE LINE # 2975
			; SOURCE LINE # 2980
	MOV  	A,mode
	CJNE 	A,#03H,?C0381
			; SOURCE LINE # 2981
	LCALL	play_step
			; SOURCE LINE # 2982
	SJMP 	?C0379
			; SOURCE LINE # 2983
?C0381:
			; SOURCE LINE # 2986
	LCALL	av_gate
			; SOURCE LINE # 2989
	JNB  	recon,?C0382
			; SOURCE LINE # 2990
	LCALL	rec_sample
?C0382:
			; SOURCE LINE # 2993
	MOV  	A,mode
	JNZ  	?C0383
			; SOURCE LINE # 2994
	LCALL	manual_step
			; SOURCE LINE # 2995
	SJMP 	?C0384
?C0383:
			; SOURCE LINE # 2996
	MOV  	A,mode
	CJNE 	A,#01H,?C0385
			; SOURCE LINE # 2997
	LCALL	light_step
	SJMP 	?C0386
?C0385:
			; SOURCE LINE # 2998
	MOV  	A,mode
	CJNE 	A,#02H,?C0386
			; SOURCE LINE # 2999
	LCALL	track_step
?C0386:
			; SOURCE LINE # 3000
	LCALL	auto_step
			; SOURCE LINE # 3001
?C0384:
			; SOURCE LINE # 3004
	LCALL	back_guard
			; SOURCE LINE # 3007
	LCALL	prox_beep
			; SOURCE LINE # 3010
	LCALL	key_scan
	MOV  	k?6281,R7
			; SOURCE LINE # 3012
	MOV  	A,k?6281
	CJNE 	A,#03H,?C0388
			; SOURCE LINE # 3013
	JNB  	recon,?C0389
			; SOURCE LINE # 3015
			; SOURCE LINE # 3016
	LCALL	L?0435
			; SOURCE LINE # 3017
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 3018
	SJMP 	?C0379
?C0389:
			; SOURCE LINE # 3019
	LCALL	mode_switch
			; SOURCE LINE # 3020
			; SOURCE LINE # 3021
	SJMP 	?C0379
			; SOURCE LINE # 3022
?C0388:
			; SOURCE LINE # 3023
	MOV  	A,k?6281
	CJNE 	A,#04H,?C0391
			; SOURCE LINE # 3024
	LCALL	avoid_toggle
			; SOURCE LINE # 3025
	SJMP 	?C0379
			; SOURCE LINE # 3026
?C0391:
			; SOURCE LINE # 3027
	MOV  	A,k?6281
	CJNE 	A,#01H,?C0392
			; SOURCE LINE # 3028
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0379
			; SOURCE LINE # 3029
?C0393:
			; SOURCE LINE # 3030
	INC  	gear
			; SOURCE LINE # 3031
	LCALL	ml_apply
			; SOURCE LINE # 3032
	SJMP 	?C0379
?C0392:
	MOV  	A,k?6281
	XRL  	A,#02H
	JNZ  	?C0379
			; SOURCE LINE # 3033
	MOV  	A,gear
	JZ   	?C0379
			; SOURCE LINE # 3034
?C0396:
			; SOURCE LINE # 3035
	DEC  	gear
			; SOURCE LINE # 3036
	LCALL	ml_apply
			; SOURCE LINE # 3037
			; SOURCE LINE # 3038
	LJMP 	?C0379
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
         i?4571:   DS   1

;--------------------------------------------------------------- ?DT?mode_switch?MAIN
?mode_switch?BYTE:
         m?1652:   DS   1

;--------------------------------------------------------------- ?DT?main?MAIN
?main?BYTE:
         k?6281:   DS   1

;--------------------------------------------------------------- ?DT?av_mnv_step?MAIN
?av_mnv_step?BYTE:
        el?2657:   DS   2

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
         d?2758:   DS   1

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
         prox_t:   DS   2
           pack:   DS   1
           gear:   DS   1
          klast:   DS   1
      av_beep_n:   DS   1
           mode:   DS   1
           recn:   DS   1
      av_beep_t:   DS   2
          lastt:   DS   2
          us_st:   DS   1
           samp:   DS   2
         ir_ib0:   DS   1
         ir_ib1:   DS   1
         ir_ib2:   DS   1
         ir_ib3:   DS   1
        play_t0:   DS   2
           avst:   DS   1
      us_last_d:   DS   1
       ir_ledhi:   DS   1
    prox_stop_t:   DS   2
       ir_maskb:   DS   1
       ir_ledlo:   DS   1
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
         av_mnv:   DBIT   1
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
