;=========================================================================
; main_abs.asm  --  **自动生成，请勿手改**
;-------------------------------------------------------------------------
;   来源 : main.src
;   生成 : python tools\c51_link.py main.src
;
;   作用 : 把 C51 生成的 71 个可重定位段拼成**一个绝对地址模块**，
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
?PR?_motor_set?MAIN  SEGMENT CODE
?PR?_d3_mix?MAIN     SEGMENT CODE
?DT?_d3_mix?MAIN     SEGMENT DATA OVERLAYABLE
?PR?avoid_off?MAIN   SEGMENT CODE
?PR?apply_gear?MAIN  SEGMENT CODE
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
	DB	004H
	DB	008H
	DB	00CH
	DB	010H
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
			; SOURCE LINE # 538
			; SOURCE LINE # 543
	INC  	tick_l
	MOV  	R7,tick_l
	MOV  	A,R7
	JNZ  	?C0001
			; SOURCE LINE # 544
	INC  	tick_h
?C0001:
			; SOURCE LINE # 547
	INC  	pwm_div
	MOV  	A,pwm_div
	CLR  	C
	SUBB 	A,#05H
	JC   	?C0002
			; SOURCE LINE # 548
	MOV  	pwm_div,#00H
			; SOURCE LINE # 550
	INC  	pwm_cnt
	MOV  	A,pwm_cnt
	SUBB 	A,#014H
	JC   	?C0003
			; SOURCE LINE # 551
	MOV  	pwm_cnt,#00H
?C0003:
			; SOURCE LINE # 553
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
			; SOURCE LINE # 554
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
			; SOURCE LINE # 557
	MOV  	A,buz_left
	JZ   	?C0008
			; SOURCE LINE # 558
	DEC  	buz_left
			; SOURCE LINE # 559
	CPL  	buz_quiet
			; SOURCE LINE # 560
	SJMP 	?C0009
?C0008:
			; SOURCE LINE # 561
	SETB 	buz_quiet
			; SOURCE LINE # 562
?C0009:
			; SOURCE LINE # 565
	MOV  	R7,#080H
			; SOURCE LINE # 566
	MOV  	A,dirbits
	ORL  	AR7,A
			; SOURCE LINE # 567
	JNB  	ena,?C0010
	ORL  	AR7,#010H
?C0010:
			; SOURCE LINE # 568
	JNB  	enb,?C0011
	ORL  	AR7,#020H
?C0011:
			; SOURCE LINE # 569
	JNB  	buz_quiet,?C0012
	ORL  	AR7,#040H
?C0012:
			; SOURCE LINE # 570
	MOV  	P0,R7
			; SOURCE LINE # 571
?C0002:
			; SOURCE LINE # 577
	INC  	ms_div
	MOV  	A,ms_div
	CLR  	C
	SUBB 	A,#064H
	JC   	?C0013
			; SOURCE LINE # 578
	MOV  	ms_div,#00H
			; SOURCE LINE # 579
	INC  	ms10_l
	MOV  	R7,ms10_l
	MOV  	A,R7
	JNZ  	?C0013
			; SOURCE LINE # 580
	INC  	ms10_h
			; SOURCE LINE # 581
?C0013:
			; SOURCE LINE # 587
	MOV  	A,us_st
	JZ   	?C0026
			; SOURCE LINE # 588
	MOV  	A,us_st
	CJNE 	A,#01H,?C0016
			; SOURCE LINE # 589
	JNB  	US_ECHO,?C0017
			; SOURCE LINE # 590
	MOV  	us_wid,#00H
			; SOURCE LINE # 591
	MOV  	us_st,#02H
			; SOURCE LINE # 592
	SJMP 	?C0026
?C0017:
	MOV  	A,us_wait
	CLR  	C
	SUBB 	A,#0FAH
	JNC  	?C0374
			; SOURCE LINE # 593
	INC  	us_wait
			; SOURCE LINE # 594
	SJMP 	?C0026
?C0016:
			; SOURCE LINE # 603
	JNB  	US_ECHO,?C0022
			; SOURCE LINE # 604
	MOV  	A,us_wid
	CLR  	C
	SUBB 	A,#0CH
	JNC  	?C0023
			; SOURCE LINE # 605
	INC  	us_wid
			; SOURCE LINE # 606
	SJMP 	?C0026
?C0023:
			; SOURCE LINE # 607
?C0374:
	MOV  	us_st,#00H
			; SOURCE LINE # 608
	MOV  	us_res,#0FFH
			; SOURCE LINE # 609
	SETB 	us_got
			; SOURCE LINE # 613
			; SOURCE LINE # 614
	SJMP 	?C0026
?C0022:
			; SOURCE LINE # 615
	MOV  	us_st,#00H
			; SOURCE LINE # 616
	MOV  	us_res,us_wid
			; SOURCE LINE # 617
	SETB 	us_got
			; SOURCE LINE # 621
			; SOURCE LINE # 622
			; SOURCE LINE # 623
			; SOURCE LINE # 624
?C0026:
	POP  	PSW
	POP  	ACC
	RETI
; END OF timer0_isr

;--------------------------------------------------------------- ?PR?tick_get?MAIN
tick_get:
	USING	0
			; SOURCE LINE # 631
			; SOURCE LINE # 632
			; SOURCE LINE # 634
	CLR  	ET0
			; SOURCE LINE # 635
	MOV  	R7,tick_h
	MOV  	A,R7
	MOV  	R6,A
	MOV  	R5,tick_l
	MOV  	A,R5
	MOV  	R7,A
			; SOURCE LINE # 636
	SETB 	ET0
			; SOURCE LINE # 637
			; SOURCE LINE # 638
?C0027:
	RET
; END OF tick_get

;--------------------------------------------------------------- ?PR?ms10_get?MAIN
ms10_get:
	USING	0
			; SOURCE LINE # 640
			; SOURCE LINE # 641
			; SOURCE LINE # 643
	CLR  	ET0
			; SOURCE LINE # 644
	MOV  	R7,ms10_h
	MOV  	A,R7
	MOV  	R6,A
	MOV  	R5,ms10_l
	MOV  	A,R5
	MOV  	R7,A
			; SOURCE LINE # 645
	SETB 	ET0
			; SOURCE LINE # 646
			; SOURCE LINE # 647
?C0028:
	RET
; END OF ms10_get

;--------------------------------------------------------------- ?PR?d_20ms?MAIN
L?0405:
	USING	0
L?0406:
	MOV  	R7,#018H
	LCALL	_beep
d_20ms:
	USING	0
			; SOURCE LINE # 655
			; SOURCE LINE # 656
			; SOURCE LINE # 657
	LCALL	tick_get
	MOV  	R3,AR7
	MOV  	R2,AR6
?C0029:
			; SOURCE LINE # 658
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
			; SOURCE LINE # 660
?C0031:
	RET
; END OF d_20ms

;--------------------------------------------------------------- ?PR?_beep?MAIN
_beep:
			; SOURCE LINE # 668
			; SOURCE LINE # 669
			; SOURCE LINE # 670
	MOV  	A,R7
	JNZ  	?C0032
			; SOURCE LINE # 671
	CLR  	ET0
			; SOURCE LINE # 672
	MOV  	buz_left,A
			; SOURCE LINE # 673
	SETB 	buz_quiet
			; SOURCE LINE # 674
	SETB 	ET0
	RET
			; SOURCE LINE # 676
?C0032:
			; SOURCE LINE # 677
	CLR  	ET0
			; SOURCE LINE # 678
	MOV  	buz_left,R7
			; SOURCE LINE # 679
	CLR  	buz_quiet
			; SOURCE LINE # 680
	SETB 	ET0
			; SOURCE LINE # 681
?C0033:
	RET
; END OF _beep

;--------------------------------------------------------------- ?PR?_motor_set?MAIN
L?0407:
	USING	0
	MOV  	avst,#02H
L?0408:
	CLR  	A
L?0409:
	MOV  	cur_act,A
	MOV  	R5,A
	MOV  	R7,A
_motor_set:
	USING	0
			; SOURCE LINE # 802
			; SOURCE LINE # 803
			; SOURCE LINE # 804
	MOV  	A,R5
	JNZ  	?C0034
			; SOURCE LINE # 805
			; SOURCE LINE # 806
			; SOURCE LINE # 807
	SJMP 	?C0376
			; SOURCE LINE # 809
?C0034:
			; SOURCE LINE # 813
	MOV  	A,avst
	CJNE 	A,#04H,?C0036
			; SOURCE LINE # 814
	MOV  	R7,#06H
			; SOURCE LINE # 815
	SJMP 	?C0037
?C0036:
			; SOURCE LINE # 817
	MOV  	A,avst
	CJNE 	A,#01H,?C0038
			; SOURCE LINE # 818
	MOV  	R7,#04H
			; SOURCE LINE # 819
	SJMP 	?C0037
?C0038:
	MOV  	A,avst
	CJNE 	A,#02H,?C0037
			; SOURCE LINE # 820
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 823
?C0375:
			; SOURCE LINE # 824
			; SOURCE LINE # 825
	SJMP 	?C0376
			; SOURCE LINE # 827
?C0037:
			; SOURCE LINE # 832
	CJNE 	R7,#02H,?C0041
	MOV  	A,R5
	SETB 	C
	SUBB 	A,#02H
	JC   	?C0041
			; SOURCE LINE # 833
	MOV  	R5,#02H
?C0041:
			; SOURCE LINE # 835
	MOV  	A,R5
	MOV  	DPTR,#duty_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 836
	MOV  	duty_b,duty_a
			; SOURCE LINE # 841
	CJNE 	R7,#05H,?C0042
			; SOURCE LINE # 842
	MOV  	A,R5
	MOV  	DPTR,#arc_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 843
	SJMP 	?C0378
			; SOURCE LINE # 845
?C0042:
			; SOURCE LINE # 846
	CJNE 	R7,#06H,?C0043
			; SOURCE LINE # 847
	MOV  	A,R5
	MOV  	DPTR,#arc_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_b,A
			; SOURCE LINE # 848
?C0377:
	SJMP 	?C0378
			; SOURCE LINE # 850
?C0043:
			; SOURCE LINE # 852
	MOV  	A,R7
	ADD  	A,#0FEH
	JZ   	?C0046
	DEC  	A
	JZ   	?C0047
	DEC  	A
	JZ   	?C0048
	ADD  	A,#03H
	JNZ  	?C0049
			; SOURCE LINE # 853
?C0045:
?C0378:
	MOV  	dirbits,#05H
	RET
			; SOURCE LINE # 854
?C0046:
	MOV  	dirbits,#0AH
	RET
			; SOURCE LINE # 855
?C0047:
	MOV  	dirbits,#06H
	RET
			; SOURCE LINE # 856
?C0048:
	MOV  	dirbits,#09H
	RET
			; SOURCE LINE # 857
?C0049:
			; SOURCE LINE # 858
	CLR  	A
?C0376:
	MOV  	dirbits,A
			; SOURCE LINE # 859
	MOV  	duty_a,A
			; SOURCE LINE # 860
	MOV  	duty_b,A
			; SOURCE LINE # 861
			; SOURCE LINE # 862
			; SOURCE LINE # 863
?C0035:
	RET
; END OF _motor_set

;--------------------------------------------------------------- ?PR?_d3_mix?MAIN
_d3_mix:
	USING	0
			; SOURCE LINE # 869
	MOV  	seg?647,R7
			; SOURCE LINE # 870
			; SOURCE LINE # 871
	LCALL	avoid_off
	MOV  	A,seg?647
	JC   	?C0050
			; SOURCE LINE # 872
	ANL  	A,#0FEH
	MOV  	R7,A
	RET
?C0050:
			; SOURCE LINE # 873
	ORL  	A,#01H
	MOV  	R7,A
			; SOURCE LINE # 874
?C0051:
	RET
; END OF _d3_mix

;--------------------------------------------------------------- ?PR?avoid_off?MAIN
avoid_off:
			; SOURCE LINE # 881
			; SOURCE LINE # 882
			; SOURCE LINE # 883
	JNB  	recon,?C0052
			; SOURCE LINE # 884
	SETB 	C
	RET
?C0052:
			; SOURCE LINE # 885
	JNB  	us_avoid_on,?C0054
			; SOURCE LINE # 886
	CLR  	C
	RET
?C0054:
			; SOURCE LINE # 887
	SETB 	C
			; SOURCE LINE # 888
?C0053:
	RET
; END OF avoid_off

;--------------------------------------------------------------- ?PR?apply_gear?MAIN
apply_gear:
	USING	0
			; SOURCE LINE # 896
			; SOURCE LINE # 897
			; SOURCE LINE # 898
	MOV  	A,gear
	JZ   	?apply_gear?stop
			; SOURCE LINE # 899
?C0055:
			; SOURCE LINE # 902
	MOV  	A,avst
	XRL  	A,#02H
	JZ   	?apply_gear?stop
			; SOURCE LINE # 903
?C0057:
			; SOURCE LINE # 907
	MOV  	cur_act,#01H
			; SOURCE LINE # 909
	MOV  	A,gear
	MOV  	DPTR,#duty_tab-01H
	MOVC 	A,@A+DPTR
	MOV  	duty_a,A
			; SOURCE LINE # 910
	MOV  	duty_b,duty_a
			; SOURCE LINE # 911
	MOV  	dirbits,#05H
			; SOURCE LINE # 913
	SJMP 	?C0379
			; SOURCE LINE # 916
?apply_gear?stop:
			; SOURCE LINE # 917
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 918
	MOV  	duty_a,A
			; SOURCE LINE # 919
	MOV  	duty_b,A
			; SOURCE LINE # 920
	MOV  	dirbits,A
			; SOURCE LINE # 921
?C0379:
	MOV  	A,gear
	MOV  	DPTR,#gear_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 922
?C0058:
	RET
; END OF apply_gear

;--------------------------------------------------------------- ?PR?show_state?MAIN
L?0410:
	USING	0
	MOV  	R7,cur_act
	LCALL	_motor_set
show_state:
	USING	0
			; SOURCE LINE # 929
			; SOURCE LINE # 930
			; SOURCE LINE # 931
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
			; SOURCE LINE # 932
	RET
; END OF show_state

;--------------------------------------------------------------- ?PR?show_mode?MAIN
show_mode:
	USING	0
			; SOURCE LINE # 935
			; SOURCE LINE # 936
			; SOURCE LINE # 937
	MOV  	A,mode
	JNZ  	?C0062
			; SOURCE LINE # 938
	LJMP 	show_state
			; SOURCE LINE # 940
?C0062:
			; SOURCE LINE # 942
	MOV  	A,mode
	MOV  	DPTR,#mode_tab
	MOVC 	A,@A+DPTR
	MOV  	R7,A
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 943
?C0063:
	RET
; END OF show_mode

;--------------------------------------------------------------- ?PR?key_scan?MAIN
key_scan:
	USING	0
			; SOURCE LINE # 952
			; SOURCE LINE # 953
			; SOURCE LINE # 956
	MOV  	A,klast
	JZ   	?C0064
			; SOURCE LINE # 957
	XRL  	A,#02H
	JZ   	?C0066
	MOV  	A,klast
	CJNE 	A,#04H,?C0065
?C0066:
			; SOURCE LINE # 958
	JNB  	KEY_S4,?C0068
			; SOURCE LINE # 959
	SJMP 	?C0380
?C0065:
			; SOURCE LINE # 960
	JNB  	KEY_S3,?C0068
?C0380:
	CLR  	A
	MOV  	klast,A
			; SOURCE LINE # 961
?C0068:
			; SOURCE LINE # 962
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 963
?C0064:
			; SOURCE LINE # 965
	JB   	KEY_S3,?C0071
			; SOURCE LINE # 966
	LCALL	d_20ms
			; SOURCE LINE # 967
	JNB  	KEY_S3,?C0072
	MOV  	R7,#00H
	RET
?C0072:
			; SOURCE LINE # 968
	LCALL	tick_get
	MOV  	DPH,R6
	MOV  	DPL,R7
?C0073:
			; SOURCE LINE # 969
	JB   	KEY_S3,?C0074
			; SOURCE LINE # 970
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,DPH
	CLR  	C
	SUBB 	A,#027H
	JC   	?C0073
			; SOURCE LINE # 971
	MOV  	klast,#03H
			; SOURCE LINE # 972
	MOV  	R7,#03H
	RET
			; SOURCE LINE # 973
			; SOURCE LINE # 974
?C0074:
			; SOURCE LINE # 975
	MOV  	klast,#01H
			; SOURCE LINE # 976
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 977
?C0071:
			; SOURCE LINE # 979
	JB   	KEY_S4,?C0076
			; SOURCE LINE # 980
	LCALL	d_20ms
			; SOURCE LINE # 981
	JNB  	KEY_S4,?C0077
	MOV  	R7,#00H
	RET
?C0077:
			; SOURCE LINE # 982
	LCALL	tick_get
	MOV  	DPH,R6
	MOV  	DPL,R7
?C0078:
			; SOURCE LINE # 983
	JB   	KEY_S4,?C0079
			; SOURCE LINE # 984
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,DPH
	CLR  	C
	SUBB 	A,#027H
	JC   	?C0078
			; SOURCE LINE # 985
	MOV  	klast,#04H
			; SOURCE LINE # 986
	MOV  	R7,#04H
	RET
			; SOURCE LINE # 987
			; SOURCE LINE # 988
?C0079:
			; SOURCE LINE # 989
	MOV  	klast,#02H
			; SOURCE LINE # 990
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 991
?C0076:
			; SOURCE LINE # 993
	MOV  	R7,#00H
			; SOURCE LINE # 994
?C0070:
	RET
; END OF key_scan

;--------------------------------------------------------------- ?PR?k_isfwd?MAIN
k_isfwd:
			; SOURCE LINE # 1000
			; SOURCE LINE # 1001
			; SOURCE LINE # 1002
	MOV  	A,cur_act
	CJNE 	A,#01H,?C0081
	SETB 	C
	RET
?C0081:
			; SOURCE LINE # 1003
	MOV  	A,cur_act
	CJNE 	A,#05H,?C0083
	SETB 	C
	RET
?C0083:
			; SOURCE LINE # 1004
	MOV  	A,cur_act
	CJNE 	A,#06H,?C0084
	SETB 	C
	RET
?C0084:
			; SOURCE LINE # 1005
	CLR  	C
			; SOURCE LINE # 1006
?C0082:
	RET
; END OF k_isfwd

;--------------------------------------------------------------- ?PR?_key2act?MAIN
_key2act:
	USING	0
			; SOURCE LINE # 1008
			; SOURCE LINE # 1009
			; SOURCE LINE # 1010
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
			; SOURCE LINE # 1011
?C0086:
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1012
?C0088:
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1013
?C0089:
	LCALL	k_isfwd
	JNC  	?C0090
	MOV  	R7,#05H
	RET
?C0090:
	MOV  	R7,#03H
?C0091:
	RET
			; SOURCE LINE # 1014
?C0092:
	LCALL	k_isfwd
	JNC  	?C0093
	MOV  	R7,#06H
	RET
?C0093:
	MOV  	R7,#04H
?C0094:
	RET
			; SOURCE LINE # 1015
?C0095:
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1016
?C0096:
	MOV  	R7,#0FFH
			; SOURCE LINE # 1017
			; SOURCE LINE # 1018
?C0087:
	RET
; END OF _key2act

;--------------------------------------------------------------- ?PR?_key2mode?MAIN
_key2mode:
	USING	0
			; SOURCE LINE # 1024
			; SOURCE LINE # 1025
			; SOURCE LINE # 1026
	MOV  	A,R7
	ADD  	A,#0E8H
	JZ   	?C0100
	ADD  	A,#0BAH
	JZ   	?C0101
	ADD  	A,#052H
	JNZ  	?C0102
			; SOURCE LINE # 1027
?C0098:
	MOV  	R7,#00H
	RET
			; SOURCE LINE # 1028
?C0100:
	MOV  	R7,#01H
	RET
			; SOURCE LINE # 1029
?C0101:
	MOV  	R7,#02H
	RET
			; SOURCE LINE # 1030
?C0102:
	MOV  	R7,#0FFH
			; SOURCE LINE # 1031
			; SOURCE LINE # 1032
?C0099:
	RET
; END OF _key2mode

;--------------------------------------------------------------- ?PR?_mode_goto?MAIN
_mode_goto:
	USING	0
			; SOURCE LINE # 1038
			; SOURCE LINE # 1039
			; SOURCE LINE # 1040
	MOV  	mode,R7
			; SOURCE LINE # 1041
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 1043
	MOV  	A,R7
	JNZ  	?C0103
			; SOURCE LINE # 1047
	MOV  	A,gear
	JZ   	?C0104
	MOV  	R7,#01H
	SJMP 	?C0105
?C0104:
	MOV  	R7,#00H
?C0105:
	MOV  	cur_act,R7
			; SOURCE LINE # 1048
	MOV  	R5,gear
	LCALL	_motor_set
			; SOURCE LINE # 1049
	LCALL	show_state
			; SOURCE LINE # 1050
	SJMP 	?C0106
?C0103:
			; SOURCE LINE # 1051
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 1052
	MOV  	A,gear
	JNZ  	?C0107
			; SOURCE LINE # 1053
	MOV  	gear,#03H
?C0107:
			; SOURCE LINE # 1054
	LCALL	tick_get
	MOV  	last_line,R6
	MOV  	last_line+01H,R7
			; SOURCE LINE # 1055
	LCALL	show_mode
			; SOURCE LINE # 1056
?C0106:
			; SOURCE LINE # 1058
	MOV  	R7,#028H
	LJMP 	_beep
; END OF _mode_goto

;--------------------------------------------------------------- ?PR?mode_switch?MAIN
mode_switch:
	USING	0
			; SOURCE LINE # 1061
			; SOURCE LINE # 1062
			; SOURCE LINE # 1063
	MOV  	m?1652,mode
			; SOURCE LINE # 1065
	MOV  	A,m?1652
	CJNE 	A,#03H,?C0109
			; SOURCE LINE # 1066
	CLR  	A
	MOV  	R7,A
	SJMP 	?C0381
			; SOURCE LINE # 1068
?C0109:
			; SOURCE LINE # 1069
	INC  	m?1652
			; SOURCE LINE # 1070
	MOV  	A,m?1652
	CLR  	C
	SUBB 	A,#03H
	JC   	?C0111
			; SOURCE LINE # 1071
	CLR  	A
	MOV  	m?1652,A
?C0111:
			; SOURCE LINE # 1072
	MOV  	R7,m?1652
?C0381:
	LCALL	_mode_goto
			; SOURCE LINE # 1073
?C0110:
	RET
; END OF mode_switch

;--------------------------------------------------------------- ?PR?light_step?MAIN
light_step:
	USING	0
			; SOURCE LINE # 1080
			; SOURCE LINE # 1081
			; SOURCE LINE # 1084
	MOV  	A,gear
	JNZ  	?C0112
			; SOURCE LINE # 1085
	MOV  	act?1753,A
			; SOURCE LINE # 1086
	SJMP 	?C0113
?C0112:
	JB   	LDR_LEFT,?C0114
			; SOURCE LINE # 1087
	JNB  	LDR_RIGHT,?C0115
	MOV  	R7,#03H
	SJMP 	?C0116
?C0115:
	MOV  	R7,#01H
?C0116:
	MOV  	act?1753,R7
			; SOURCE LINE # 1088
	SJMP 	?C0113
?C0114:
			; SOURCE LINE # 1089
	JNB  	LDR_RIGHT,?C0118
	MOV  	R7,#00H
	SJMP 	?C0119
?C0118:
	MOV  	R7,#04H
?C0119:
	MOV  	act?1753,R7
			; SOURCE LINE # 1090
?C0113:
			; SOURCE LINE # 1092
	MOV  	cur_act,act?1753
			; SOURCE LINE # 1093
	MOV  	R5,gear
	MOV  	R7,act?1753
	LCALL	_motor_set
			; SOURCE LINE # 1094
	LJMP 	show_mode
; END OF light_step

;--------------------------------------------------------------- ?PR?track_step?MAIN
track_step:
	USING	0
			; SOURCE LINE # 1104
			; SOURCE LINE # 1105
			; SOURCE LINE # 1106
	CLR  	A
	MOV  	R4,A
			; SOURCE LINE # 1109
	JNB  	TRACK_L,?C0121
	MOV  	R4,#02H
?C0121:
			; SOURCE LINE # 1110
	JNB  	TRACK_R,?C0122
	ORL  	AR4,#01H
?C0122:
			; SOURCE LINE # 1112
	MOV  	A,R4
	JNZ  	?C0123
			; SOURCE LINE # 1113
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,last_line+01H
	MOV  	A,R6
	SUBB 	A,last_line
	CLR  	C
	SUBB 	A,#013H
	JC   	?C0382
			; SOURCE LINE # 1114
	CLR  	A
	MOV  	act?1855,A
	SJMP 	?C0126
?C0123:
			; SOURCE LINE # 1118
	LCALL	tick_get
	MOV  	last_line,R6
	MOV  	last_line+01H,R7
			; SOURCE LINE # 1119
	CJNE 	R4,#01H,?C0127
	MOV  	act?1855,#04H
	SJMP 	?C0126
?C0127:
			; SOURCE LINE # 1120
	CJNE 	R4,#02H,?C0129
	MOV  	act?1855,#03H
	SJMP 	?C0126
?C0129:
			; SOURCE LINE # 1121
?C0382:
	MOV  	act?1855,#01H
			; SOURCE LINE # 1122
?C0126:
			; SOURCE LINE # 1124
	MOV  	cur_act,act?1855
			; SOURCE LINE # 1125
	MOV  	R5,gear
	MOV  	R7,act?1855
	LCALL	_motor_set
			; SOURCE LINE # 1126
	LJMP 	show_mode
; END OF track_step

;--------------------------------------------------------------- ?PR?us_init?MAIN
us_init:
			; SOURCE LINE # 1145
			; SOURCE LINE # 1146
			; SOURCE LINE # 1147
	CLR  	ET0
			; SOURCE LINE # 1148
	CLR  	A
	MOV  	us_st,A
			; SOURCE LINE # 1149
	MOV  	us_wid,A
			; SOURCE LINE # 1150
	MOV  	us_wait,A
			; SOURCE LINE # 1151
	CLR  	us_got
			; SOURCE LINE # 1152
	MOV  	us_res,#0FFH
			; SOURCE LINE # 1153
	CLR  	us_valid
			; SOURCE LINE # 1154
	CLR  	us_seen
			; SOURCE LINE # 1155
	MOV  	us_last10,A
			; SOURCE LINE # 1156
	MOV  	us_last_d,#0FFH
			; SOURCE LINE # 1160
	CLR  	US_TRIG
			; SOURCE LINE # 1161
	SETB 	ET0
			; SOURCE LINE # 1162
	RET
; END OF us_init

;--------------------------------------------------------------- ?PR?us_trigger?MAIN
us_trigger:
			; SOURCE LINE # 1168
			; SOURCE LINE # 1169
			; SOURCE LINE # 1170
	CLR  	US_TRIG
			; SOURCE LINE # 1171
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1172
	SETB 	US_TRIG
			; SOURCE LINE # 1173
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1174
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
			; SOURCE LINE # 1175
	CLR  	US_TRIG
			; SOURCE LINE # 1177
	CLR  	A
	MOV  	us_wid,A
			; SOURCE LINE # 1178
	MOV  	us_wait,A
			; SOURCE LINE # 1179
	MOV  	us_st,#01H
			; SOURCE LINE # 1180
	RET
; END OF us_trigger

;--------------------------------------------------------------- ?PR?us_read?MAIN
us_read:
	USING	0
			; SOURCE LINE # 1184
			; SOURCE LINE # 1185
			; SOURCE LINE # 1186
	MOV  	R6,ms10_l
			; SOURCE LINE # 1191
	JNB  	us_got,?C0134
			; SOURCE LINE # 1192
	CLR  	ET0
			; SOURCE LINE # 1193
	MOV  	us_last_d,us_res
			; SOURCE LINE # 1194
	CLR  	us_got
			; SOURCE LINE # 1195
	SETB 	us_valid
			; SOURCE LINE # 1196
	SETB 	ET0
			; SOURCE LINE # 1197
?C0134:
			; SOURCE LINE # 1200
	MOV  	A,us_st
	JZ   	?C0135
			; SOURCE LINE # 1201
	JNB  	us_valid,?C0136
	MOV  	R7,us_last_d
	RET
?C0136:
	MOV  	R7,#0FFH
?C0137:
	RET
?C0135:
			; SOURCE LINE # 1205
	JNB  	us_seen,?C0139
	CLR  	C
	MOV  	A,R6
	SUBB 	A,us_last10
	CLR  	C
	SUBB 	A,#06H
	JNC  	?C0139
			; SOURCE LINE # 1206
	JNB  	us_valid,?C0140
	MOV  	R7,us_last_d
	RET
?C0140:
	MOV  	R7,#0FFH
?C0141:
	RET
?C0139:
			; SOURCE LINE # 1209
	MOV  	us_last10,R6
			; SOURCE LINE # 1210
	SETB 	us_seen
			; SOURCE LINE # 1211
	LCALL	us_trigger
			; SOURCE LINE # 1212
	JNB  	us_valid,?C0142
	MOV  	R7,us_last_d
	SJMP 	?C0143
?C0142:
	MOV  	R7,#0FFH
?C0143:
			; SOURCE LINE # 1213
?C0138:
	RET
; END OF us_read

;--------------------------------------------------------------- ?PR?ir_det?MAIN
ir_det:
			; SOURCE LINE # 1223
			; SOURCE LINE # 1224
			; SOURCE LINE # 1225
	MOV  	A,ir_inv
	JZ   	?C0144
			; SOURCE LINE # 1226
	JNB  	IR_AVOID,?C0145
	SETB 	C
	RET
?C0145:
			; SOURCE LINE # 1227
	CLR  	C
	RET
			; SOURCE LINE # 1228
?C0144:
			; SOURCE LINE # 1229
	JNB  	IR_AVOID,?C0147
	CLR  	C
	RET
?C0147:
			; SOURCE LINE # 1230
	SETB 	C
			; SOURCE LINE # 1231
?C0146:
	RET
; END OF ir_det

;--------------------------------------------------------------- ?PR?ir_brake?MAIN
ir_brake:
	USING	0
			; SOURCE LINE # 1266
			; SOURCE LINE # 1267
			; SOURCE LINE # 1268
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0149
?C0148:
			; SOURCE LINE # 1271
			; SOURCE LINE # 1272
			; SOURCE LINE # 1273
	LCALL	L?0407
			; SOURCE LINE # 1274
	LCALL	show_mode
			; SOURCE LINE # 1275
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1276
	CLR  	A
	MOV  	av_beep_n,A
			; SOURCE LINE # 1281
?C0149:
	RET
; END OF ir_brake

;--------------------------------------------------------------- ?PR?av_gate_hold?MAIN
av_gate_hold:
	USING	0
			; SOURCE LINE # 1289
			; SOURCE LINE # 1290
			; SOURCE LINE # 1291
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0151
?C0150:
			; SOURCE LINE # 1294
	MOV  	A,mode
	CJNE 	A,#01H,?C0152
			; SOURCE LINE # 1297
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 1298
	MOV  	avst,#03H
			; SOURCE LINE # 1299
			; SOURCE LINE # 1300
	LCALL	L?0409
			; SOURCE LINE # 1301
	LCALL	show_mode
			; SOURCE LINE # 1302
	SJMP 	?C0383
			; SOURCE LINE # 1304
?C0152:
			; SOURCE LINE # 1307
			; SOURCE LINE # 1308
			; SOURCE LINE # 1309
	LCALL	L?0407
			; SOURCE LINE # 1310
	LCALL	show_mode
			; SOURCE LINE # 1312
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1316
	MOV  	A,av_beep_n
	JNZ  	?C0151
			; SOURCE LINE # 1317
	MOV  	av_beep_n,#01H
			; SOURCE LINE # 1319
?C0383:
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 1320
			; SOURCE LINE # 1321
?C0151:
	RET
; END OF av_gate_hold

;--------------------------------------------------------------- ?PR?av_gate?MAIN
av_gate:
	USING	0
			; SOURCE LINE # 1333
			; SOURCE LINE # 1334
			; SOURCE LINE # 1363
	LCALL	avoid_off
	JNC  	?C0154
	MOV  	A,avst
	CJNE 	A,#02H,?C0154
			; SOURCE LINE # 1364
	CLR  	A
	MOV  	avst,A
?C0154:
			; SOURCE LINE # 1369
	MOV  	A,avst
	XRL  	A,#02H
	JNZ  	?C0155
			; SOURCE LINE # 1371
	LCALL	ir_det
	JNC  	$ + 5H
	LJMP 	?C0157
?C0156:
			; SOURCE LINE # 1377
	LCALL	avoid_off
	JNC  	$ + 5H
	LJMP 	?C0157
	MOV  	A,mode
	XRL  	A,#02H
	JNZ  	$ + 5H
	LJMP 	?C0157
?C0158:
			; SOURCE LINE # 1381
	LCALL	us_read
	MOV  	A,R7
	CLR  	C
	SUBB 	A,#07H
	JC   	?C0160
			; SOURCE LINE # 1382
	JB   	av_clear_on,?C0161
			; SOURCE LINE # 1383
	SETB 	av_clear_on
			; SOURCE LINE # 1384
	LCALL	tick_get
	MOV  	av_clear_t,R6
	MOV  	av_clear_t+01H,R7
	RET
			; SOURCE LINE # 1386
?C0161:
			; SOURCE LINE # 1387
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
	LJMP 	?C0157
			; SOURCE LINE # 1388
	CLR  	A
	MOV  	av_beep_n,A
	RET
			; SOURCE LINE # 1390
?C0160:
			; SOURCE LINE # 1391
	CLR  	av_clear_on
			; SOURCE LINE # 1394
	MOV  	A,av_beep_n
	CLR  	C
	SUBB 	A,#03H
	JC   	$ + 5H
	LJMP 	?C0157
?C0163:
			; SOURCE LINE # 1396
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,av_beep_t+01H
	MOV  	A,R6
	SUBB 	A,av_beep_t
	CLR  	C
	SUBB 	A,#01BH
	JNC  	$ + 5H
	LJMP 	?C0157
			; SOURCE LINE # 1397
	LCALL	tick_get
	MOV  	av_beep_t,R6
	MOV  	av_beep_t+01H,R7
			; SOURCE LINE # 1398
	INC  	av_beep_n
			; SOURCE LINE # 1400
	MOV  	R7,#018H
	LJMP 	_beep
			; SOURCE LINE # 1401
			; SOURCE LINE # 1404
?C0155:
			; SOURCE LINE # 1408
	LCALL	ir_det
	JNC  	?C0165
			; SOURCE LINE # 1409
	LJMP 	ir_brake
			; SOURCE LINE # 1411
?C0165:
			; SOURCE LINE # 1417
	MOV  	A,mode
	CJNE 	A,#02H,?C0166
			; SOURCE LINE # 1418
	CLR  	A
	MOV  	avst,A
	RET
			; SOURCE LINE # 1420
?C0166:
			; SOURCE LINE # 1426
	MOV  	A,cur_act
	CJNE 	A,#02H,?C0167
			; SOURCE LINE # 1427
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1428
	MOV  	R5,gear
	MOV  	R7,#02H
	SJMP 	?C0386
			; SOURCE LINE # 1430
?C0167:
			; SOURCE LINE # 1434
	LCALL	avoid_off
	JNC  	?C0168
			; SOURCE LINE # 1435
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1436
	MOV  	A,cur_act
	JZ   	?C0157
	MOV  	R5,gear
	MOV  	R7,A
?C0384:
	SJMP 	?C0386
			; SOURCE LINE # 1438
?C0168:
			; SOURCE LINE # 1440
	LCALL	us_read
	MOV  	d?2557,R7
			; SOURCE LINE # 1444
	MOV  	A,d?2557
	CLR  	C
	SUBB 	A,#03H
	JNC  	?C0170
			; SOURCE LINE # 1445
	LJMP 	av_gate_hold
			; SOURCE LINE # 1447
?C0170:
			; SOURCE LINE # 1457
	MOV  	A,avst
	XRL  	A,#04H
	JZ   	?C0172
	MOV  	A,avst
	CJNE 	A,#01H,?C0171
?C0172:
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
	JNC  	?C0171
			; SOURCE LINE # 1458
	MOV  	A,cur_act
	JZ   	?C0157
?C0173:
			; SOURCE LINE # 1459
	MOV  	R5,gear
	MOV  	R7,cur_act
?C0385:
	SJMP 	?C0386
			; SOURCE LINE # 1461
?C0171:
			; SOURCE LINE # 1464
	LCALL	tick_get
	MOV  	av_clear_t,R6
	MOV  	av_clear_t+01H,R7
			; SOURCE LINE # 1465
	MOV  	A,d?2557
	CLR  	C
	SUBB 	A,#07H
	JNC  	?C0174
			; SOURCE LINE # 1466
	MOV  	avst,#01H
	SJMP 	?C0175
?C0174:
			; SOURCE LINE # 1467
	MOV  	A,d?2557
	CLR  	C
	SUBB 	A,#0CH
	JNC  	?C0176
			; SOURCE LINE # 1468
	MOV  	avst,#04H
	SJMP 	?C0175
?C0176:
			; SOURCE LINE # 1470
	CLR  	A
	MOV  	avst,A
?C0175:
			; SOURCE LINE # 1484
	MOV  	A,cur_act
	JZ   	?C0157
?C0178:
			; SOURCE LINE # 1485
	MOV  	R5,gear
	MOV  	R7,cur_act
?C0386:
	LCALL	_motor_set
			; SOURCE LINE # 1486
?C0157:
	RET
; END OF av_gate

;--------------------------------------------------------------- ?PR?avoid_toggle?MAIN
avoid_toggle:
	USING	0
			; SOURCE LINE # 1495
			; SOURCE LINE # 1496
			; SOURCE LINE # 1497
	CPL  	us_avoid_on
			; SOURCE LINE # 1500
	JNB  	us_avoid_on,?C0179
			; SOURCE LINE # 1501
			; SOURCE LINE # 1502
	LCALL	L?0405
			; SOURCE LINE # 1503
	LCALL	d_20ms
			; SOURCE LINE # 1504
	MOV  	R7,#018H
			; SOURCE LINE # 1505
	SJMP 	?C0387
?C0179:
			; SOURCE LINE # 1506
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1507
	MOV  	R7,#028H
?C0387:
	LCALL	_beep
			; SOURCE LINE # 1508
?C0180:
			; SOURCE LINE # 1512
	LJMP 	show_mode
; END OF avoid_toggle

;--------------------------------------------------------------- ?PR?meas_level?MAIN
meas_level:
	USING	0
			; SOURCE LINE # 1526
			; SOURCE LINE # 1527
			; SOURCE LINE # 1532
	CLR  	ET0
			; SOURCE LINE # 1533
	MOV  	R5,tick_h
			; SOURCE LINE # 1534
	MOV  	R4,tick_l
			; SOURCE LINE # 1535
	SETB 	ET0
			; SOURCE LINE # 1537
	MOV  	A,R5
	MOV  	R6,A
	MOV  	A,R4
	MOV  	R3,A
	MOV  	R2,AR6
			; SOURCE LINE # 1539
?C0182:
			; SOURCE LINE # 1540
	CLR  	ET0
			; SOURCE LINE # 1541
	MOV  	R5,tick_h
			; SOURCE LINE # 1542
	MOV  	R4,tick_l
			; SOURCE LINE # 1543
	SETB 	ET0
			; SOURCE LINE # 1544
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
			; SOURCE LINE # 1546
	MOV  	A,ml_cap
	JZ   	?C0184
			; SOURCE LINE # 1547
	MOV  	DPL,A
	CLR  	C
	MOV  	A,R7
	SUBB 	A,DPL
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0187
			; SOURCE LINE # 1548
			; SOURCE LINE # 1549
	SJMP 	?C0388
			; SOURCE LINE # 1550
			; SOURCE LINE # 1551
?C0184:
			; SOURCE LINE # 1552
	SETB 	C
	MOV  	A,R7
	SUBB 	A,#0FFH
	MOV  	A,R6
	SUBB 	A,#00H
	JC   	?C0187
			; SOURCE LINE # 1553
?C0388:
	MOV  	ml_dur,R6
	MOV  	ml_dur+01H,R7
			; SOURCE LINE # 1554
	SETB 	C
	RET
			; SOURCE LINE # 1555
			; SOURCE LINE # 1556
?C0187:
			; SOURCE LINE # 1558
	MOV  	A,ml_level
	JZ   	?C0189
			; SOURCE LINE # 1559
	JB   	IR_IN,?C0182
			; SOURCE LINE # 1560
			; SOURCE LINE # 1561
	SJMP 	?C0389
			; SOURCE LINE # 1562
			; SOURCE LINE # 1563
?C0189:
			; SOURCE LINE # 1564
	JNB  	IR_IN,?C0182
			; SOURCE LINE # 1565
?C0389:
	MOV  	ml_dur,R6
	MOV  	ml_dur+01H,R7
			; SOURCE LINE # 1566
	CLR  	C
			; SOURCE LINE # 1567
			; SOURCE LINE # 1568
			; SOURCE LINE # 1569
			; SOURCE LINE # 1570
?C0186:
	RET
; END OF meas_level

;--------------------------------------------------------------- ?PR?ir_reset?MAIN
ir_reset:
			; SOURCE LINE # 1588
			; SOURCE LINE # 1589
			; SOURCE LINE # 1590
	CLR  	A
	MOV  	ml_cap,A
			; SOURCE LINE # 1591
	MOV  	ir_ledlo,A
			; SOURCE LINE # 1592
	MOV  	ir_ledhi,A
			; SOURCE LINE # 1593
	CLR  	ir_short
			; SOURCE LINE # 1594
	MOV  	irstat,#01H
			; SOURCE LINE # 1595
	RET
; END OF ir_reset

;--------------------------------------------------------------- ?PR?_ir_setbit?MAIN
_ir_setbit:
			; SOURCE LINE # 1598
			; SOURCE LINE # 1599
			; SOURCE LINE # 1600
	MOV  	A,R7
	DEC  	A
	JZ   	?C0196
	DEC  	A
	JZ   	?C0197
	ADD  	A,#02H
	JNZ  	?C0198
			; SOURCE LINE # 1601
?C0195:
	MOV  	A,ir_maskb
	ORL  	ir_ib0,A
	RET
			; SOURCE LINE # 1602
?C0196:
	MOV  	A,ir_maskb
	ORL  	ir_ib1,A
	RET
			; SOURCE LINE # 1603
?C0197:
	MOV  	A,ir_maskb
	ORL  	ir_ib2,A
	RET
			; SOURCE LINE # 1604
?C0198:
	MOV  	A,ir_maskb
	ORL  	ir_ib3,A
			; SOURCE LINE # 1605
			; SOURCE LINE # 1606
?C0199:
	RET
; END OF _ir_setbit

;--------------------------------------------------------------- ?PR?ir_decode_bits?MAIN
ir_decode_bits:
	USING	0
			; SOURCE LINE # 1609
			; SOURCE LINE # 1610
			; SOURCE LINE # 1611
	CLR  	A
	MOV  	ir_ib0,A
			; SOURCE LINE # 1612
	MOV  	ir_ib1,A
			; SOURCE LINE # 1613
	MOV  	ir_ib2,A
			; SOURCE LINE # 1614
	MOV  	ir_ib3,A
			; SOURCE LINE # 1615
	MOV  	ir_bits,#020H
			; SOURCE LINE # 1616
	MOV  	ir_ptridx,A
			; SOURCE LINE # 1617
	MOV  	ir_maskb,#01H
?C0200:
			; SOURCE LINE # 1619
			; SOURCE LINE # 1621
	CLR  	A
	MOV  	ml_level,A
			; SOURCE LINE # 1622
	MOV  	ml_cap,A
			; SOURCE LINE # 1623
	LCALL	meas_level
	JNC  	?C0202
			; SOURCE LINE # 1624
	CLR  	C
	RET
?C0202:
			; SOURCE LINE # 1627
	MOV  	ml_level,#01H
			; SOURCE LINE # 1628
	MOV  	A,ir_bits
	CJNE 	A,#01H,?C0204
			; SOURCE LINE # 1631
	MOV  	ml_cap,#0CH
			; SOURCE LINE # 1632
	LCALL	meas_level
	JNC  	?C0206
			; SOURCE LINE # 1633
			; SOURCE LINE # 1634
	SJMP 	?C0390
?C0204:
			; SOURCE LINE # 1635
	CLR  	A
	MOV  	ml_cap,A
			; SOURCE LINE # 1636
	LCALL	meas_level
	JNC  	?C0207
			; SOURCE LINE # 1637
	CLR  	C
	RET
?C0207:
			; SOURCE LINE # 1638
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0BH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0206
			; SOURCE LINE # 1639
?C0390:
	MOV  	R7,ir_ptridx
	LCALL	_ir_setbit
			; SOURCE LINE # 1640
?C0206:
			; SOURCE LINE # 1643
	MOV  	A,ir_maskb
	ADD  	A,ACC
	MOV  	ir_maskb,A
			; SOURCE LINE # 1644
	JNZ  	?C0209
			; SOURCE LINE # 1645
	MOV  	ir_maskb,#01H
			; SOURCE LINE # 1646
	INC  	ir_ptridx
			; SOURCE LINE # 1647
?C0209:
			; SOURCE LINE # 1648
	DJNZ 	ir_bits,?C0200
			; SOURCE LINE # 1649
?C0201:
			; SOURCE LINE # 1652
	MOV  	A,ir_ib0
	CPL  	A
	XRL  	A,ir_ib1
	JZ   	?C0210
	CLR  	C
	RET
?C0210:
			; SOURCE LINE # 1653
	MOV  	A,ir_ib2
	CPL  	A
	XRL  	A,ir_ib3
	JZ   	?C0211
	CLR  	C
	RET
?C0211:
			; SOURCE LINE # 1654
	SETB 	C
			; SOURCE LINE # 1655
?C0203:
	RET
; END OF ir_decode_bits

;--------------------------------------------------------------- ?PR?ir_decode?MAIN
ir_decode:
	USING	0
			; SOURCE LINE # 1658
			; SOURCE LINE # 1659
			; SOURCE LINE # 1661
	CLR  	A
	MOV  	ml_level,A
			; SOURCE LINE # 1662
	MOV  	ml_cap,A
			; SOURCE LINE # 1663
	LCALL	meas_level
	JNC  	?C0212
			; SOURCE LINE # 1664
	SJMP 	?C0393
			; SOURCE LINE # 1666
?C0212:
			; SOURCE LINE # 1667
	MOV  	ir_ledlo,ml_dur+01H
			; SOURCE LINE # 1668
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0FFH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0214
			; SOURCE LINE # 1669
?C0391:
	SJMP 	?C0393
			; SOURCE LINE # 1671
?C0214:
			; SOURCE LINE # 1672
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#046H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0216
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#078H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0215
?C0216:
			; SOURCE LINE # 1673
?C0392:
	SJMP 	?C0393
			; SOURCE LINE # 1675
?C0215:
			; SOURCE LINE # 1682
	MOV  	ml_level,#01H
			; SOURCE LINE # 1683
	MOV  	ml_cap,#03CH
			; SOURCE LINE # 1684
	LCALL	meas_level
	JNC  	?C0217
			; SOURCE LINE # 1685
	MOV  	ir_ledhi,ml_dur+01H
			; SOURCE LINE # 1686
	SJMP 	?C0394
			; SOURCE LINE # 1688
?C0217:
			; SOURCE LINE # 1689
	MOV  	ir_ledhi,ml_dur+01H
			; SOURCE LINE # 1690
	SETB 	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0FFH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JC   	?C0218
			; SOURCE LINE # 1691
?C0394:
	MOV  	irstat,#03H
	RET
			; SOURCE LINE # 1693
?C0218:
			; SOURCE LINE # 1694
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#0CH
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JNC  	?C0219
			; SOURCE LINE # 1695
?C0393:
	MOV  	irstat,#02H
	RET
			; SOURCE LINE # 1697
?C0219:
			; SOURCE LINE # 1698
	CLR  	C
	MOV  	A,ml_dur+01H
	SUBB 	A,#019H
	MOV  	A,ml_dur
	SUBB 	A,#00H
	JNC  	?C0220
			; SOURCE LINE # 1699
	SETB 	ir_short
?C0220:
			; SOURCE LINE # 1702
	LCALL	ir_decode_bits
	JNC  	?C0221
			; SOURCE LINE # 1703
	CLR  	A
	MOV  	irstat,A
	RET
			; SOURCE LINE # 1705
?C0221:
			; SOURCE LINE # 1708
	JNB  	ir_short,?C0222
	MOV  	R7,#03H
	SJMP 	?C0223
?C0222:
	MOV  	R7,#02H
?C0223:
	MOV  	irstat,R7
			; SOURCE LINE # 1709
?C0213:
	RET
; END OF ir_decode

;--------------------------------------------------------------- ?PR?ir_recv?MAIN
ir_recv:
	USING	0
			; SOURCE LINE # 1716
			; SOURCE LINE # 1717
			; SOURCE LINE # 1720
	LCALL	ir_reset
			; SOURCE LINE # 1723
	LCALL	tick_get
	MOV  	R3,AR7
	MOV  	R2,AR6
?C0224:
			; SOURCE LINE # 1724
	JNB  	IR_IN,?C0225
			; SOURCE LINE # 1725
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
	JC   	?C0224
	RET
?C0225:
			; SOURCE LINE # 1729
	LCALL	ir_decode
			; SOURCE LINE # 1730
?C0227:
	RET
; END OF ir_recv

;--------------------------------------------------------------- ?PR?ir_recv_nb?MAIN
ir_recv_nb:
	USING	0
			; SOURCE LINE # 1737
			; SOURCE LINE # 1738
			; SOURCE LINE # 1739
	LCALL	ir_reset
			; SOURCE LINE # 1740
	JB   	IR_IN,?C0229
?C0228:
			; SOURCE LINE # 1742
	LCALL	ir_decode
			; SOURCE LINE # 1743
?C0229:
	RET
; END OF ir_recv_nb

;--------------------------------------------------------------- ?PR?stamp_now?MAIN
stamp_now:
	USING	0
			; SOURCE LINE # 1746
			; SOURCE LINE # 1747
			; SOURCE LINE # 1748
	LCALL	tick_get
	MOV  	lastt,R6
	MOV  	lastt+01H,R7
			; SOURCE LINE # 1749
	RET
; END OF stamp_now

;--------------------------------------------------------------- ?PR?ir_errpr?MAIN
ir_errpr:
			; SOURCE LINE # 1752
			; SOURCE LINE # 1753
			; SOURCE LINE # 1771
	RET
; END OF ir_errpr

;--------------------------------------------------------------- ?PR?do_key?MAIN
do_key:
	USING	0
			; SOURCE LINE # 1776
			; SOURCE LINE # 1777
			; SOURCE LINE # 1783
	MOV  	A,avst
	CJNE 	A,#02H,?C0232
			; SOURCE LINE # 1784
	MOV  	avst,#03H
?C0232:
			; SOURCE LINE # 1788
	MOV  	A,ir_ib2
	CJNE 	A,#042H,?C0233
	LJMP 	rec_key
?C0233:
			; SOURCE LINE # 1789
	MOV  	A,ir_ib2
	CJNE 	A,#04AH,?C0235
	LJMP 	clr_key
?C0235:
			; SOURCE LINE # 1790
	MOV  	A,ir_ib2
	CJNE 	A,#052H,?C0236
	LJMP 	play_key
?C0236:
			; SOURCE LINE # 1798
	MOV  	A,ir_ib2
	CJNE 	A,#01CH,?C0237
			; SOURCE LINE # 1799
	LJMP 	avoid_toggle
			; SOURCE LINE # 1801
?C0237:
			; SOURCE LINE # 1804
	MOV  	R7,ir_ib2
	LCALL	_key2mode
	MOV  	R4,AR7
			; SOURCE LINE # 1805
	MOV  	A,R4
	CPL  	A
	JZ   	?C0238
			; SOURCE LINE # 1806
	JNB  	recon,?C0239
			; SOURCE LINE # 1809
			; SOURCE LINE # 1810
	LCALL	L?0405
			; SOURCE LINE # 1811
	SJMP 	?C0398
			; SOURCE LINE # 1813
?C0239:
			; SOURCE LINE # 1814
	MOV  	A,R4
	CJNE 	A,mode,?C0240
			; SOURCE LINE # 1815
?C0395:
	SJMP 	?C0398
			; SOURCE LINE # 1817
?C0240:
			; SOURCE LINE # 1818
	MOV  	R7,AR4
	LJMP 	_mode_goto
			; SOURCE LINE # 1820
?C0238:
			; SOURCE LINE # 1823
	MOV  	A,ir_ib2
	CJNE 	A,#05AH,?C0241
			; SOURCE LINE # 1824
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0234
?C0242:
			; SOURCE LINE # 1826
	INC  	gear
			; SOURCE LINE # 1827
	SJMP 	?C0243
?C0241:
	MOV  	A,ir_ib2
	CJNE 	A,#08H,?C0244
			; SOURCE LINE # 1828
	MOV  	A,gear
	JZ   	?C0234
?C0245:
			; SOURCE LINE # 1830
	DEC  	gear
			; SOURCE LINE # 1831
	SJMP 	?C0243
?C0244:
			; SOURCE LINE # 1835
	MOV  	R7,ir_ib2
	LCALL	_key2act
			; SOURCE LINE # 1837
	MOV  	A,R7
	CPL  	A
	JZ   	?C0234
			; SOURCE LINE # 1840
?C0247:
			; SOURCE LINE # 1842
	MOV  	A,R7
	JNZ  	?C0248
			; SOURCE LINE # 1843
	MOV  	cur_act,A
			; SOURCE LINE # 1844
	MOV  	R5,A
	MOV  	R7,A
			; SOURCE LINE # 1845
	SJMP 	?C0397
?C0248:
			; SOURCE LINE # 1846
	MOV  	A,gear
	JNZ  	?C0250
			; SOURCE LINE # 1847
	MOV  	gear,#03H
?C0250:
			; SOURCE LINE # 1848
	MOV  	cur_act,R7
			; SOURCE LINE # 1849
	MOV  	R5,gear
?C0397:
	LCALL	_motor_set
			; SOURCE LINE # 1850
?C0249:
			; SOURCE LINE # 1852
	LCALL	show_state
			; SOURCE LINE # 1854
?C0396:
	SJMP 	?C0398
			; SOURCE LINE # 1856
?C0243:
			; SOURCE LINE # 1859
	MOV  	A,cur_act
	JZ   	?C0251
			; SOURCE LINE # 1860
	MOV  	R5,gear
	MOV  	R7,A
	LCALL	_motor_set
?C0251:
			; SOURCE LINE # 1861
	LCALL	show_state
			; SOURCE LINE # 1862
?C0398:
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 1864
?C0234:
	RET
; END OF do_key

;--------------------------------------------------------------- ?PR?ir_holdchk?MAIN
ir_holdchk:
	USING	0
			; SOURCE LINE # 1874
			; SOURCE LINE # 1875
			; SOURCE LINE # 1878
	MOV  	A,cur_act
	JZ   	?C0253
?C0252:
			; SOURCE LINE # 1881
	MOV  	A,avst
	XRL  	A,#03H
	JZ   	?C0254
	JB   	recon,?C0254
			; SOURCE LINE # 1882
	MOV  	A,cur_act
	XRL  	A,#01H
	JZ   	?C0253
?C0255:
			; SOURCE LINE # 1884
?C0254:
			; SOURCE LINE # 1886
	LCALL	tick_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,lastt+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,lastt
	MOV  	R6,A
			; SOURCE LINE # 1887
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0B8H
	MOV  	A,R6
	SUBB 	A,#0BH
	JC   	?C0253
?C0256:
			; SOURCE LINE # 1892
	JB   	recon,?C0257
	MOV  	A,cur_act
	XRL  	A,#05H
	JZ   	?C0258
	MOV  	A,cur_act
	CJNE 	A,#06H,?C0257
?C0258:
			; SOURCE LINE # 1893
	MOV  	cur_act,#01H
	SJMP 	?C0259
?C0257:
			; SOURCE LINE # 1895
	CLR  	A
	MOV  	cur_act,A
?C0259:
			; SOURCE LINE # 1897
	MOV  	A,cur_act
	JNZ  	?C0260
	MOV  	R5,A
	SJMP 	?C0261
?C0260:
	MOV  	R7,gear
	MOV  	R5,AR7
?C0261:
			; SOURCE LINE # 1898
	LCALL	L?0410
			; SOURCE LINE # 1899
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 1901
	MOV  	A,avst
	CJNE 	A,#03H,?C0253
			; SOURCE LINE # 1902
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 1904
?C0253:
	RET
; END OF ir_holdchk

;--------------------------------------------------------------- ?PR?back_guard?MAIN
back_guard:
	USING	0
			; SOURCE LINE # 1911
			; SOURCE LINE # 1912
			; SOURCE LINE # 1913
	MOV  	A,mode
	JNZ  	?C0264
?C0263:
			; SOURCE LINE # 1916
	MOV  	A,cur_act
	XRL  	A,#02H
	JZ   	?C0265
			; SOURCE LINE # 1917
	CLR  	back_on
	RET
			; SOURCE LINE # 1919
?C0265:
			; SOURCE LINE # 1921
	JB   	back_on,?C0266
			; SOURCE LINE # 1922
	SETB 	back_on
			; SOURCE LINE # 1923
	LCALL	tick_get
	MOV  	back_t0,R6
	MOV  	back_t0+01H,R7
	RET
			; SOURCE LINE # 1925
?C0266:
			; SOURCE LINE # 1927
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
	JC   	?C0264
?C0267:
			; SOURCE LINE # 1931
	CLR  	back_on
			; SOURCE LINE # 1932
			; SOURCE LINE # 1933
	LCALL	L?0408
			; SOURCE LINE # 1934
	LCALL	show_state
			; SOURCE LINE # 1936
			; SOURCE LINE # 1937
	LCALL	L?0406
			; SOURCE LINE # 1938
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 1939
?C0264:
	RET
; END OF back_guard

;--------------------------------------------------------------- ?PR?prox_beep?MAIN
prox_beep:
	USING	0
			; SOURCE LINE # 1953
			; SOURCE LINE # 1954
			; SOURCE LINE # 1957
	LCALL	avoid_off
	JC   	$ + 5H
	LJMP 	?C0269
?C0268:
			; SOURCE LINE # 1959
	MOV  	A,mode
	XRL  	A,#03H
	JNZ  	$ + 5H
	LJMP 	?C0269
	MOV  	A,mode
	XRL  	A,#02H
	JNZ  	$ + 5H
	LJMP 	?C0269
?C0270:
			; SOURCE LINE # 1963
	MOV  	A,cur_act
	CJNE 	A,#02H,?C0272
			; SOURCE LINE # 1964
	CLR  	prox_moving
			; SOURCE LINE # 1965
	CLR  	prox_hold
	RET
			; SOURCE LINE # 1967
?C0272:
			; SOURCE LINE # 1970
	MOV  	A,cur_act
	JNZ  	?C0273
			; SOURCE LINE # 1971
	JNB  	prox_moving,?C0274
			; SOURCE LINE # 1972
	CLR  	prox_moving
			; SOURCE LINE # 1973
	SETB 	prox_hold
			; SOURCE LINE # 1974
	LCALL	tick_get
	MOV  	prox_stop_t,R6
	MOV  	prox_stop_t+01H,R7
			; SOURCE LINE # 1975
?C0274:
			; SOURCE LINE # 1976
	JNB  	prox_hold,?C0275
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
	JC   	?C0275
			; SOURCE LINE # 1977
	CLR  	prox_hold
?C0275:
			; SOURCE LINE # 1978
	JB   	prox_hold,?C0277
	RET
?C0273:
			; SOURCE LINE # 1981
	SETB 	prox_moving
			; SOURCE LINE # 1982
	CLR  	prox_hold
			; SOURCE LINE # 1983
?C0277:
			; SOURCE LINE # 1985
	LCALL	us_read
	MOV  	R6,#00H
			; SOURCE LINE # 1986
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#0CH
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0269
?C0278:
			; SOURCE LINE # 1989
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#03H
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0279
	MOV  	A,cur_act
	JZ   	?C0279
			; SOURCE LINE # 1991
	MOV  	R7,#0C8H
	SJMP 	?C0399
			; SOURCE LINE # 1993
?C0279:
			; SOURCE LINE # 1999
	CLR  	C
	MOV  	A,R7
	SUBB 	A,#03H
	MOV  	A,R6
	SUBB 	A,#00H
	JNC  	?C0280
			; SOURCE LINE # 2000
	MOV  	R2,#03H
	MOV  	R3,#0E8H
	SJMP 	?C0281
?C0280:
			; SOURCE LINE # 2002
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
?C0281:
			; SOURCE LINE # 2003
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
	JC   	?C0269
?C0282:
			; SOURCE LINE # 2005
	LCALL	tick_get
	MOV  	prox_t,R6
	MOV  	prox_t+01H,R7
			; SOURCE LINE # 2007
	MOV  	R7,#018H
?C0399:
	LCALL	_beep
			; SOURCE LINE # 2008
?C0269:
	RET
; END OF prox_beep

;--------------------------------------------------------------- ?PR?rec_halt?MAIN
rec_halt:
	USING	0
			; SOURCE LINE # 2021
			; SOURCE LINE # 2022
			; SOURCE LINE # 2023
	CLR  	A
	MOV  	cur_act,A
			; SOURCE LINE # 2024
	MOV  	R5,A
	MOV  	R7,A
	LJMP 	_motor_set
; END OF rec_halt

;--------------------------------------------------------------- ?PR?rec_commit?MAIN
rec_commit:
	USING	0
			; SOURCE LINE # 2031
			; SOURCE LINE # 2032
			; SOURCE LINE # 2035
	MOV  	A,pack
	ANL  	A,#0F0H
	JNZ  	?C0284
	MOV  	A,recn
	JNZ  	?C0284
			; SOURCE LINE # 2036
			; SOURCE LINE # 2037
	SJMP 	?C0400
			; SOURCE LINE # 2038
?C0284:
			; SOURCE LINE # 2040
	MOV  	A,recn
	CLR  	C
	SUBB 	A,#050H
	JC   	?C0286
			; SOURCE LINE # 2041
	SETB 	recfull
			; SOURCE LINE # 2042
	RET
			; SOURCE LINE # 2043
?C0286:
			; SOURCE LINE # 2045
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
			; SOURCE LINE # 2046
	MOV  	DPL,R5
	MOV  	DPH,A
	MOV  	A,pack
	MOVX 	@DPTR,A
			; SOURCE LINE # 2047
	INC  	DPTR
	MOV  	A,cur_dur+01H
	MOVX 	@DPTR,A
			; SOURCE LINE # 2048
	MOV  	A,cur_dur
	MOV  	DPL,R5
	MOV  	DPH,R4
	INC  	DPTR
	INC  	DPTR
	MOVX 	@DPTR,A
			; SOURCE LINE # 2050
	INC  	recn
			; SOURCE LINE # 2051
	MOV  	A,recn
	CLR  	C
	SUBB 	A,#050H
	JC   	?C0287
			; SOURCE LINE # 2052
	SETB 	recfull
?C0287:
			; SOURCE LINE # 2054
	CLR  	A
?C0400:
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2055
	SETB 	C
			; SOURCE LINE # 2056
?C0285:
	RET
; END OF rec_commit

;--------------------------------------------------------------- ?PR?rec_err?MAIN
rec_err:
	USING	0
			; SOURCE LINE # 2059
			; SOURCE LINE # 2060
			; SOURCE LINE # 2061
	MOV  	R7,#061H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2062
			; SOURCE LINE # 2063
	LCALL	L?0406
			; SOURCE LINE # 2064
	LCALL	d_20ms
			; SOURCE LINE # 2065
			; SOURCE LINE # 2066
	LCALL	L?0406
			; SOURCE LINE # 2067
	LCALL	d_20ms
			; SOURCE LINE # 2068
	LJMP 	show_state
; END OF rec_err

;--------------------------------------------------------------- ?PR?rec_fullstop?MAIN
rec_fullstop:
	USING	0
			; SOURCE LINE # 2073
			; SOURCE LINE # 2074
			; SOURCE LINE # 2077
	CLR  	recon
			; SOURCE LINE # 2078
	CLR  	A
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2079
	LCALL	rec_halt
			; SOURCE LINE # 2081
	CLR  	A
	MOV  	i?4370,A
?C0289:
			; SOURCE LINE # 2082
	MOV  	R7,#071H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2083
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2084
	LCALL	d_20ms
			; SOURCE LINE # 2085
	INC  	i?4370
	MOV  	A,i?4370
	CLR  	C
	SUBB 	A,#014H
	JC   	?C0289
?C0290:
			; SOURCE LINE # 2086
	LJMP 	show_state
; END OF rec_fullstop

;--------------------------------------------------------------- ?PR?rec_sample?MAIN
rec_sample:
	USING	0
			; SOURCE LINE # 2095
			; SOURCE LINE # 2096
			; SOURCE LINE # 2100
	JNB  	recfull,?C0293
			; SOURCE LINE # 2101
	LJMP 	rec_fullstop
			; SOURCE LINE # 2103
?C0293:
			; SOURCE LINE # 2105
	LCALL	ms10_get
			; SOURCE LINE # 2106
	CLR  	C
	MOV  	A,R7
	SUBB 	A,samp+01H
	MOV  	R5,A
	MOV  	A,R6
	SUBB 	A,samp
	MOV  	R4,A
			; SOURCE LINE # 2107
	ORL  	A,R5
	JZ   	?C0294
?C0295:
			; SOURCE LINE # 2109
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2111
	MOV  	A,cur_act
	SWAP 	A
	ANL  	A,#0F0H
	MOV  	R7,A
	MOV  	A,gear
	ANL  	A,#0FH
	ORL  	A,R7
	MOV  	R1,A
			; SOURCE LINE # 2113
	CJNE 	A,pack,?C0296
			; SOURCE LINE # 2114
	MOV  	A,cur_dur+01H
	ADD  	A,R5
	MOV  	R7,A
	MOV  	A,cur_dur
	ADDC 	A,R4
	MOV  	R6,A
			; SOURCE LINE # 2115
	CLR  	C
	MOV  	A,R7
	SUBB 	A,cur_dur+01H
	MOV  	A,R6
	SUBB 	A,cur_dur
	JNC  	?C0297
			; SOURCE LINE # 2116
	SJMP 	?C0401
			; SOURCE LINE # 2118
?C0297:
			; SOURCE LINE # 2119
	MOV  	cur_dur,R6
	MOV  	cur_dur+01H,R7
			; SOURCE LINE # 2120
	MOV  	A,cur_dur
	CLR  	C
	SUBB 	A,#0BH
	CLR  	A
	SUBB 	A,#00H
	JC   	?C0294
			; SOURCE LINE # 2121
?C0401:
	LJMP 	rec_commit
			; SOURCE LINE # 2123
?C0296:
			; SOURCE LINE # 2126
	LCALL	rec_commit
	JNC  	?C0294
			; SOURCE LINE # 2127
	MOV  	pack,R1
			; SOURCE LINE # 2128
?C0294:
	RET
; END OF rec_sample

;--------------------------------------------------------------- ?PR?rec_enter?MAIN
rec_enter:
	USING	0
			; SOURCE LINE # 2131
			; SOURCE LINE # 2132
			; SOURCE LINE # 2133
	LCALL	rec_halt
			; SOURCE LINE # 2134
	CLR  	A
	MOV  	recn,A
			; SOURCE LINE # 2135
	CLR  	recfull
			; SOURCE LINE # 2136
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2137
	LCALL	ms10_get
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2138
	MOV  	A,gear
	ANL  	A,#0FH
	MOV  	pack,A
			; SOURCE LINE # 2139
	SETB 	recon
			; SOURCE LINE # 2140
	LCALL	show_state
			; SOURCE LINE # 2141
	MOV  	R7,#028H
	LJMP 	_beep
; END OF rec_enter

;--------------------------------------------------------------- ?PR?rec_exit?MAIN
rec_exit:
	USING	0
			; SOURCE LINE # 2145
			; SOURCE LINE # 2146
			; SOURCE LINE # 2147
	MOV  	A,cur_dur+01H
	ORL  	A,cur_dur
	JZ   	?C0301
			; SOURCE LINE # 2148
	LCALL	rec_commit
?C0301:
			; SOURCE LINE # 2149
	CLR  	recon
			; SOURCE LINE # 2150
	CLR  	A
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2151
	LCALL	show_state
			; SOURCE LINE # 2152
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2153
	LCALL	d_20ms
			; SOURCE LINE # 2154
	MOV  	R7,#028H
	LJMP 	_beep
; END OF rec_exit

;--------------------------------------------------------------- ?PR?rec_key?MAIN
rec_key:
	USING	0
			; SOURCE LINE # 2158
			; SOURCE LINE # 2159
			; SOURCE LINE # 2160
	JNB  	recon,?C0303
	LJMP 	rec_exit
?C0303:
			; SOURCE LINE # 2161
	LCALL	rec_enter
			; SOURCE LINE # 2162
?C0305:
	RET
; END OF rec_key

;--------------------------------------------------------------- ?PR?clr_key?MAIN
clr_key:
	USING	0
			; SOURCE LINE # 2166
			; SOURCE LINE # 2167
			; SOURCE LINE # 2168
	MOV  	A,mode
	XRL  	A,#03H
	JZ   	?C0307
?C0306:
			; SOURCE LINE # 2170
	MOV  	A,cur_act
	JNZ  	?C0307
?C0308:
			; SOURCE LINE # 2173
	CLR  	recon
			; SOURCE LINE # 2174
	CLR  	A
	MOV  	recn,A
			; SOURCE LINE # 2175
	CLR  	recfull
			; SOURCE LINE # 2176
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2177
	LCALL	show_state
			; SOURCE LINE # 2178
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2179
	LCALL	d_20ms
			; SOURCE LINE # 2180
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2181
?C0307:
	RET
; END OF clr_key

;--------------------------------------------------------------- ?PR?play_load?MAIN
play_load:
	USING	0
			; SOURCE LINE # 2194
			; SOURCE LINE # 2195
			; SOURCE LINE # 2196
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
			; SOURCE LINE # 2197
	MOV  	DPL,R5
	MOV  	DPH,A
	MOVX 	A,@DPTR
	MOV  	R3,A
			; SOURCE LINE # 2200
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
			; SOURCE LINE # 2202
	MOV  	A,R3
	ANL  	A,#0FH
	MOV  	gear,A
			; SOURCE LINE # 2203
	MOV  	A,R3
	SWAP 	A
	ANL  	A,#0FH
	MOV  	cur_act,A
			; SOURCE LINE # 2205
	MOV  	R5,gear
	MOV  	R7,A
	LCALL	_motor_set
			; SOURCE LINE # 2206
	LCALL	ms10_get
	MOV  	play_t0,R6
	MOV  	play_t0+01H,R7
			; SOURCE LINE # 2207
	RET
; END OF play_load

;--------------------------------------------------------------- ?PR?play_safety?MAIN
play_safety:
	USING	0
			; SOURCE LINE # 2214
			; SOURCE LINE # 2215
			; SOURCE LINE # 2218
	LCALL	ir_det
	JNC  	?C0310
			; SOURCE LINE # 2219
	RET
?C0310:
			; SOURCE LINE # 2221
	LCALL	ms10_get
			; SOURCE LINE # 2222
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
	JNC  	?C0312
			; SOURCE LINE # 2223
	CLR  	C
	RET
?C0312:
			; SOURCE LINE # 2224
	MOV  	samp,R6
	MOV  	samp+01H,R7
			; SOURCE LINE # 2226
	LCALL	us_read
	MOV  	A,R7
	CLR  	C
	SUBB 	A,#03H
	JNC  	?C0313
			; SOURCE LINE # 2227
	RET
?C0313:
			; SOURCE LINE # 2228
	CLR  	C
			; SOURCE LINE # 2229
?C0311:
	RET
; END OF play_safety

;--------------------------------------------------------------- ?PR?play_exit?MAIN
play_exit:
	USING	0
			; SOURCE LINE # 2232
			; SOURCE LINE # 2233
			; SOURCE LINE # 2234
	LCALL	rec_halt
			; SOURCE LINE # 2235
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 2236
	MOV  	gear,play_gear0
			; SOURCE LINE # 2237
	MOV  	avst,A
			; SOURCE LINE # 2238
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2239
	MOV  	playidx,A
			; SOURCE LINE # 2240
	LJMP 	show_state
; END OF play_exit

;--------------------------------------------------------------- ?PR?play_abort?MAIN
play_abort:
	USING	0
			; SOURCE LINE # 2245
			; SOURCE LINE # 2246
			; SOURCE LINE # 2247
	SETB 	playerr
			; SOURCE LINE # 2248
	LCALL	rec_halt
			; SOURCE LINE # 2249
			; SOURCE LINE # 2250
	LCALL	L?0406
			; SOURCE LINE # 2251
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2252
	LJMP 	play_exit
; END OF play_abort

;--------------------------------------------------------------- ?PR?play_enter?MAIN
play_enter:
	USING	0
			; SOURCE LINE # 2256
			; SOURCE LINE # 2257
			; SOURCE LINE # 2258
	MOV  	A,recn
	JNZ  	?C0316
			; SOURCE LINE # 2259
	LJMP 	rec_err
			; SOURCE LINE # 2261
?C0316:
			; SOURCE LINE # 2263
	MOV  	play_gear0,gear
			; SOURCE LINE # 2266
	CLR  	A
	MOV  	avst,A
			; SOURCE LINE # 2267
	MOV  	playidx,A
			; SOURCE LINE # 2268
	MOV  	cur_act,A
			; SOURCE LINE # 2269
	MOV  	mode,#03H
			; SOURCE LINE # 2270
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2271
	LCALL	play_load
			; SOURCE LINE # 2272
	LCALL	show_mode
			; SOURCE LINE # 2273
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2274
?C0317:
	RET
; END OF play_enter

;--------------------------------------------------------------- ?PR?play_step?MAIN
play_step:
	USING	0
			; SOURCE LINE # 2280
			; SOURCE LINE # 2281
			; SOURCE LINE # 2284
	LCALL	play_safety
	JNC  	?C0318
			; SOURCE LINE # 2285
	LJMP 	play_abort
			; SOURCE LINE # 2287
?C0318:
			; SOURCE LINE # 2289
	LCALL	ir_recv_nb
			; SOURCE LINE # 2290
	MOV  	A,irstat
	JNZ  	?C0320
			; SOURCE LINE # 2291
	MOV  	A,ir_ib2
	CJNE 	A,#052H,?C0321
			; SOURCE LINE # 2292
	SJMP 	?C0403
			; SOURCE LINE # 2294
?C0321:
			; SOURCE LINE # 2297
	MOV  	R7,ir_ib2
	LCALL	_key2act
	MOV  	A,R7
	CPL  	A
	JZ   	?C0320
			; SOURCE LINE # 2298
?C0402:
	SJMP 	?C0403
			; SOURCE LINE # 2300
			; SOURCE LINE # 2301
?C0320:
			; SOURCE LINE # 2304
	LCALL	ms10_get
	CLR  	C
	MOV  	A,R7
	SUBB 	A,play_t0+01H
	MOV  	R7,A
	MOV  	A,R6
	SUBB 	A,play_t0
	MOV  	R6,A
			; SOURCE LINE # 2305
	CLR  	C
	MOV  	A,R7
	SUBB 	A,play_dur+01H
	MOV  	A,R6
	SUBB 	A,play_dur
	JC   	?C0319
?C0323:
			; SOURCE LINE # 2308
	INC  	playidx
			; SOURCE LINE # 2309
	MOV  	A,playidx
	CLR  	C
	SUBB 	A,recn
	JC   	?C0324
			; SOURCE LINE # 2310
?C0403:
	LJMP 	play_exit
			; SOURCE LINE # 2312
?C0324:
			; SOURCE LINE # 2313
	LCALL	play_load
			; SOURCE LINE # 2314
?C0319:
	RET
; END OF play_step

;--------------------------------------------------------------- ?PR?play_key?MAIN
play_key:
	USING	0
			; SOURCE LINE # 2318
			; SOURCE LINE # 2319
			; SOURCE LINE # 2320
	JNB  	recon,?C0325
			; SOURCE LINE # 2321
	LCALL	rec_exit
	SJMP 	?C0326
?C0325:
			; SOURCE LINE # 2322
	MOV  	A,mode
	CJNE 	A,#03H,?C0326
			; SOURCE LINE # 2323
	LJMP 	play_exit
			; SOURCE LINE # 2325
?C0326:
			; SOURCE LINE # 2326
	LCALL	play_enter
			; SOURCE LINE # 2327
?C0328:
	RET
; END OF play_key

;--------------------------------------------------------------- ?PR?manual_step?MAIN
manual_step:
	USING	0
			; SOURCE LINE # 2332
			; SOURCE LINE # 2333
			; SOURCE LINE # 2334
	LCALL	ir_recv
			; SOURCE LINE # 2336
	MOV  	A,irstat
	JNZ  	?C0329
			; SOURCE LINE # 2337
	LCALL	stamp_now
			; SOURCE LINE # 2338
	MOV  	lastcmd,ir_ib2
			; SOURCE LINE # 2339
	LCALL	do_key
			; SOURCE LINE # 2340
	SJMP 	?C0330
?C0329:
	MOV  	A,irstat
	CJNE 	A,#03H,?C0331
			; SOURCE LINE # 2341
	LCALL	stamp_now
			; SOURCE LINE # 2342
	SJMP 	?C0330
?C0331:
	MOV  	A,irstat
	CJNE 	A,#02H,?C0330
			; SOURCE LINE # 2343
	LCALL	ir_errpr
			; SOURCE LINE # 2347
?C0330:
			; SOURCE LINE # 2356
			; SOURCE LINE # 2357
	LJMP 	ir_holdchk
; END OF manual_step

;--------------------------------------------------------------- ?PR?auto_step?MAIN
auto_step:
	USING	0
			; SOURCE LINE # 2365
			; SOURCE LINE # 2366
			; SOURCE LINE # 2369
	LCALL	ir_recv
			; SOURCE LINE # 2370
	MOV  	A,irstat
	JNZ  	?C0337
?C0336:
			; SOURCE LINE # 2373
	MOV  	A,ir_ib2
	CJNE 	A,#040H,?C0338
			; SOURCE LINE # 2374
	CLR  	A
	MOV  	mode,A
			; SOURCE LINE # 2375
			; SOURCE LINE # 2376
	LCALL	L?0409
			; SOURCE LINE # 2377
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2378
	LCALL	show_state
			; SOURCE LINE # 2379
	MOV  	R7,#028H
	LJMP 	_beep
			; SOURCE LINE # 2381
?C0338:
			; SOURCE LINE # 2383
	MOV  	R7,ir_ib2
	LCALL	_key2mode
			; SOURCE LINE # 2384
	MOV  	A,R7
	CPL  	A
	JZ   	?C0339
			; SOURCE LINE # 2385
	MOV  	A,R7
	XRL  	A,mode
	JZ   	?C0337
			; SOURCE LINE # 2386
	LJMP 	_mode_goto
			; SOURCE LINE # 2388
?C0339:
			; SOURCE LINE # 2391
	MOV  	A,ir_ib2
	CJNE 	A,#01CH,?C0341
			; SOURCE LINE # 2392
	LJMP 	avoid_toggle
			; SOURCE LINE # 2394
?C0341:
			; SOURCE LINE # 2396
	MOV  	A,ir_ib2
	CJNE 	A,#05AH,?C0342
			; SOURCE LINE # 2397
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0337
			; SOURCE LINE # 2398
	INC  	gear
			; SOURCE LINE # 2399
			; SOURCE LINE # 2400
			; SOURCE LINE # 2401
	SJMP 	?C0404
?C0342:
	MOV  	A,ir_ib2
	CJNE 	A,#08H,?C0337
			; SOURCE LINE # 2402
	MOV  	A,gear
	SETB 	C
	SUBB 	A,#00H
	JC   	?C0337
			; SOURCE LINE # 2403
	DEC  	gear
			; SOURCE LINE # 2404
?C0404:
	LCALL	ml_apply
			; SOURCE LINE # 2405
			; SOURCE LINE # 2406
			; SOURCE LINE # 2407
?C0337:
	RET
; END OF auto_step

;--------------------------------------------------------------- ?PR?ml_apply?MAIN
ml_apply:
	USING	0
			; SOURCE LINE # 2414
			; SOURCE LINE # 2415
			; SOURCE LINE # 2417
	MOV  	R7,#028H
	LCALL	_beep
			; SOURCE LINE # 2419
	MOV  	A,mode
	JZ   	?C0347
			; SOURCE LINE # 2420
	LJMP 	show_mode
			; SOURCE LINE # 2423
?C0347:
			; SOURCE LINE # 2425
	MOV  	A,gear
	JZ   	?C0350
	MOV  	A,cur_act
	JNZ  	?C0349
?C0350:
			; SOURCE LINE # 2426
	LJMP 	apply_gear
			; SOURCE LINE # 2427
?C0349:
			; SOURCE LINE # 2428
	MOV  	R5,gear
			; SOURCE LINE # 2429
	LCALL	L?0410
			; SOURCE LINE # 2430
			; SOURCE LINE # 2432
?C0348:
	RET
; END OF ml_apply

;--------------------------------------------------------------- ?PR?init_all?MAIN
init_all:
	USING	0
			; SOURCE LINE # 2514
			; SOURCE LINE # 2515
			; SOURCE LINE # 2517
	CLR  	A
	MOV  	pwm_div,A
			; SOURCE LINE # 2518
	MOV  	pwm_cnt,A
			; SOURCE LINE # 2519
	MOV  	buz_left,A
			; SOURCE LINE # 2520
	SETB 	buz_quiet
			; SOURCE LINE # 2521
	MOV  	dirbits,A
			; SOURCE LINE # 2522
	MOV  	duty_a,A
			; SOURCE LINE # 2523
	MOV  	duty_b,A
			; SOURCE LINE # 2524
	MOV  	gear,A
			; SOURCE LINE # 2525
	MOV  	klast,A
			; SOURCE LINE # 2526
	MOV  	cur_act,A
			; SOURCE LINE # 2527
	CLR  	back_on
			; SOURCE LINE # 2528
	MOV  	back_t0,A
	MOV  	back_t0+01H,A
			; SOURCE LINE # 2529
	MOV  	prox_t,A
	MOV  	prox_t+01H,A
			; SOURCE LINE # 2530
	CLR  	prox_moving
			; SOURCE LINE # 2531
	CLR  	prox_hold
			; SOURCE LINE # 2532
	MOV  	prox_stop_t,A
	MOV  	prox_stop_t+01H,A
			; SOURCE LINE # 2533
	MOV  	av_beep_n,A
			; SOURCE LINE # 2534
	CLR  	av_clear_on
			; SOURCE LINE # 2535
	MOV  	av_clear_t,A
	MOV  	av_clear_t+01H,A
			; SOURCE LINE # 2538
	MOV  	tick_l,A
			; SOURCE LINE # 2539
	MOV  	tick_h,A
			; SOURCE LINE # 2540
	MOV  	irstat,#01H
			; SOURCE LINE # 2541
	MOV  	lastcmd,#0FFH
			; SOURCE LINE # 2542
	MOV  	lastt,A
	MOV  	lastt+01H,A
			; SOURCE LINE # 2543
	MOV  	last_err,A
	MOV  	last_err+01H,A
			; SOURCE LINE # 2544
	MOV  	ir_ledlo,A
			; SOURCE LINE # 2545
	MOV  	ir_ledhi,A
			; SOURCE LINE # 2548
	MOV  	mode,A
			; SOURCE LINE # 2549
	SETB 	us_avoid_on
			; SOURCE LINE # 2550
	MOV  	avst,A
			; SOURCE LINE # 2551
	MOV  	av_beep_t,A
	MOV  	av_beep_t+01H,A
			; SOURCE LINE # 2552
	MOV  	last_line,A
	MOV  	last_line+01H,A
			; SOURCE LINE # 2555
	CLR  	recon
			; SOURCE LINE # 2556
	CLR  	playerr
			; SOURCE LINE # 2557
	CLR  	recfull
			; SOURCE LINE # 2558
	MOV  	ms_div,A
			; SOURCE LINE # 2559
	MOV  	ms10_l,A
			; SOURCE LINE # 2560
	MOV  	ms10_h,A
			; SOURCE LINE # 2561
	MOV  	pack,A
			; SOURCE LINE # 2562
	MOV  	cur_dur,A
	MOV  	cur_dur+01H,A
			; SOURCE LINE # 2563
	MOV  	samp,A
	MOV  	samp+01H,A
			; SOURCE LINE # 2564
	MOV  	recn,A
			; SOURCE LINE # 2565
	MOV  	playidx,A
			; SOURCE LINE # 2566
	MOV  	play_dur,A
	MOV  	play_dur+01H,A
			; SOURCE LINE # 2567
	MOV  	play_t0,A
	MOV  	play_t0+01H,A
			; SOURCE LINE # 2568
	MOV  	play_gear0,A
			; SOURCE LINE # 2577
	MOV  	P0,#0C0H
			; SOURCE LINE # 2578
	MOV  	P1,#0FFH
			; SOURCE LINE # 2579
	MOV  	R7,#03H
	LCALL	_d3_mix
	MOV  	P2,R7
			; SOURCE LINE # 2580
	MOV  	P3,#0FFH
			; SOURCE LINE # 2583
	LCALL	us_init
			; SOURCE LINE # 2589
	JNB  	IR_AVOID,?C0352
			; SOURCE LINE # 2590
	CLR  	A
	MOV  	ir_inv,A
	SJMP 	?C0353
?C0352:
			; SOURCE LINE # 2592
	MOV  	ir_inv,#01H
?C0353:
			; SOURCE LINE # 2595
	MOV  	TMOD,#022H
			; SOURCE LINE # 2596
	MOV  	TH1,#0FDH
			; SOURCE LINE # 2597
	MOV  	TL1,#0FDH
			; SOURCE LINE # 2598
	MOV  	SCON,#050H
			; SOURCE LINE # 2599
	CLR  	A
	MOV  	PCON,A
			; SOURCE LINE # 2600
	SETB 	TR1
			; SOURCE LINE # 2602
	MOV  	TH0,#0A4H
			; SOURCE LINE # 2603
	MOV  	TL0,#0A4H
			; SOURCE LINE # 2604
	SETB 	ET0
			; SOURCE LINE # 2605
	SETB 	EA
			; SOURCE LINE # 2606
	SETB 	TR0
			; SOURCE LINE # 2608
	LCALL	tick_get
	MOV  	lastt,R6
	MOV  	lastt+01H,R7
			; SOURCE LINE # 2609
	LCALL	tick_get
	MOV  	prox_stop_t,R6
	MOV  	prox_stop_t+01H,R7
			; SOURCE LINE # 2611
	LJMP 	apply_gear
; END OF init_all

;--------------------------------------------------------------- ?PR?main?MAIN
main:
	USING	0
			; SOURCE LINE # 2697
			; SOURCE LINE # 2698
			; SOURCE LINE # 2701
	LCALL	init_all
?C0355:
			; SOURCE LINE # 2703
			; SOURCE LINE # 2708
	MOV  	A,mode
	CJNE 	A,#03H,?C0357
			; SOURCE LINE # 2709
	LCALL	play_step
			; SOURCE LINE # 2710
	SJMP 	?C0355
			; SOURCE LINE # 2711
?C0357:
			; SOURCE LINE # 2714
	LCALL	av_gate
			; SOURCE LINE # 2717
	JNB  	recon,?C0358
			; SOURCE LINE # 2718
	LCALL	rec_sample
?C0358:
			; SOURCE LINE # 2721
	MOV  	A,mode
	JNZ  	?C0359
			; SOURCE LINE # 2722
	LCALL	manual_step
			; SOURCE LINE # 2723
	SJMP 	?C0360
?C0359:
			; SOURCE LINE # 2724
	MOV  	A,mode
	CJNE 	A,#01H,?C0361
			; SOURCE LINE # 2725
	LCALL	light_step
	SJMP 	?C0362
?C0361:
			; SOURCE LINE # 2726
	MOV  	A,mode
	CJNE 	A,#02H,?C0362
			; SOURCE LINE # 2727
	LCALL	track_step
?C0362:
			; SOURCE LINE # 2728
	LCALL	auto_step
			; SOURCE LINE # 2729
?C0360:
			; SOURCE LINE # 2732
	LCALL	back_guard
			; SOURCE LINE # 2735
	LCALL	prox_beep
			; SOURCE LINE # 2738
	LCALL	key_scan
	MOV  	k?6080,R7
			; SOURCE LINE # 2740
	MOV  	A,k?6080
	CJNE 	A,#03H,?C0364
			; SOURCE LINE # 2741
	JNB  	recon,?C0365
			; SOURCE LINE # 2743
			; SOURCE LINE # 2744
	LCALL	L?0406
			; SOURCE LINE # 2745
	MOV  	R7,#018H
	LCALL	_beep
			; SOURCE LINE # 2746
	SJMP 	?C0355
?C0365:
			; SOURCE LINE # 2747
	LCALL	mode_switch
			; SOURCE LINE # 2748
			; SOURCE LINE # 2749
	SJMP 	?C0355
			; SOURCE LINE # 2750
?C0364:
			; SOURCE LINE # 2751
	MOV  	A,k?6080
	CJNE 	A,#04H,?C0367
			; SOURCE LINE # 2752
	LCALL	avoid_toggle
			; SOURCE LINE # 2753
	SJMP 	?C0355
			; SOURCE LINE # 2754
?C0367:
			; SOURCE LINE # 2755
	MOV  	A,k?6080
	CJNE 	A,#01H,?C0368
			; SOURCE LINE # 2756
	MOV  	A,gear
	CLR  	C
	SUBB 	A,#05H
	JNC  	?C0355
			; SOURCE LINE # 2757
?C0369:
			; SOURCE LINE # 2758
	INC  	gear
			; SOURCE LINE # 2759
	LCALL	ml_apply
			; SOURCE LINE # 2760
	SJMP 	?C0355
?C0368:
	MOV  	A,k?6080
	XRL  	A,#02H
	JNZ  	?C0355
			; SOURCE LINE # 2761
	MOV  	A,gear
	JZ   	?C0355
			; SOURCE LINE # 2762
?C0372:
			; SOURCE LINE # 2763
	DEC  	gear
			; SOURCE LINE # 2764
	LCALL	ml_apply
			; SOURCE LINE # 2765
			; SOURCE LINE # 2766
	LJMP 	?C0355
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
         k?6080:   DS   1

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
      last_line:   DS   2
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
