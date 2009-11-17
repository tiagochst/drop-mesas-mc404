; *********************************************
; * [Atividade 2 MC404 - Unicamp]             *
; * [Class project]                           *
; * (C)2009 by Alexandre Nobuo Kunieda 080523 *   
; *            Tiago Cheadraoui Silva  082941 *
; *********************************************

; Included header file for target AVR type
.NOLIST
.INCLUDE "m88def.inc"
.LIST

; ============================================
;            D E F I N I T I O N S
; ============================================
;
; [Add all register names here, include info on
;  all used registers without specific names]
.DEF r = r16
.DEF tmp = r17
.DEF lcdinput = r19

.EQU LCDDATA = PORTD
.EQU LCDCTL = PORTC
.EQU ENABLE = 0
.EQU RS = 1
.EQU RW = 2


rjmp RESET  ;reset handle

.org 0x003
	rjmp toggle_clock	;vetor de interrupção INT0 em 0x01
.org 0x010
	rjmp count1sec		;go to timer0 overflow counter interrupt routine

; ============================================
;           M A I N    P R O G R A M
; ============================================
MAINLOOP:
	sleep  ;"dorme", e acorda via interrupção
	rjmp MAINLOOP  ;volta a "dormir" após serviço da interrupção

; ============================================
;            I N I T    V A L U E S
; ============================================
RESET:
    ldi r, low(RAMEND)
	out	SPL, r
	ldi	r, high(RAMEND)
	out SPH, r

	clr xh ;interruption counter
	clr xl
	rcall clockinit

	ldi r,0
	sts EICRA, r  ;queremos interromper no nivel baixo do sinal em pd2
	ldi r,5  ;sleep power down(SM1=1) & sleep enable SE=1
	out SMCR,r  ;do it 

	ldi r,1  ;era out TIMSK0,r no Atmega88 este registrador está fora do espaço de E/S!
	sts PCICR, r  ;Ativa interrup. da porta B
	sts PCMSK0,r  ;Bit 0 da porta B causa interrup
	sts TIMSK0,r  ;enable timer0 overflow interrupt
	ldi r,1  ;set prescalong: 1= no prescaling 5=  CK/1024 pre-scaling
	out TCCR0B,r  ;also starts timer0 counting

	sei  ;Global Interrupt enable

	rjmp MAINLOOP

; ============================================
;              F U N C T I O N S
; ============================================
;
; INTERRUPTION routines
count1sec:
	adiw X, 1

	ldi r, 0x0F
	cpi xl, 0x42
	cpc xh, r
	brne count1sec_exit

	clr xh
	clr xl
	rcall clock

	count1sec_exit:
reti

toggle_clock:  ; rotina de interrupcao INT0
	in r, TCCR0B
	ldi tmp, 1
	eor r, tmp
	out TCCR0B, r  ; toggle timer0 counter
reti  ; retorna com interrupções habilitadas/desabilitadas (inverso do que entrou)


;
; CLOCK functions
clock:
	ldi yh, high(SRAM_START+6) ;seta Y para o final do cronometro
	ldi yl, low(SRAM_START+6)

	ldi tmp, 3
	clock_loop:
		ld r, -Y
		cpi r, '9'
		brne inc_sai
		ldi r, '0'
		st Y, r

		ld r, -Y
		cpi r, '5'
		brne inc_sai
		ldi r, '0'
		st Y, r

		dec tmp
	brne clock_loop

	inc_sai:
	inc r
	st Y, r

	rcall chk24h
ret

chk24h:
	ldi yh, high(SRAM_START+6) ;seta Y para o final do cronometro
	ldi yl, low(SRAM_START+6)

	ldi tmp, 4
	chk24h_loop:
		ld r, -Y
		cpi r, '0'
		brne sai
		dec tmp
	brne chk24h_loop

	ld r, -Y
	cpi r, '4'
	brne sai

	ld r, -Y
	cpi r, '2'
	brne sai

	ldi r, '0'
	st Y+, r
	st Y+, r

	sai:
ret

clockinit:
	ldi yh, high(SRAM_START)
	ldi yl, low(SRAM_START)
	ldi r, '0'
	st Y+, r
	st Y+, r
	st Y+, r
	st Y+, r
	st Y+, r
	st Y+, r
ret

