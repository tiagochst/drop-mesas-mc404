; *********************************************
; * [Atividade 2 MC404 - Unicamp]             *
; * [Class project]                           *
; * (C)2009 by Alexandre Nobuo Kunieda 080523 *   
; *            Tiago Cheadraoui Silva  082941 *
; *********************************************
;
; Included header file for target AVR type
;.NOLIST
;.INCLUDE "m88def.inc"
;.LIST
;
; ============================================
;   R E G I S T E R   D E F I N I T I O N S
; ============================================
;
; [Add all register names here, include info on
;  all used registers without specific names]
;.DEF aux1 = R20
;.DEF aux2 = R21
;.DEF aux3 = R22
;.DEF aux4 = R23
;
;
;
; ============================================
;           M A I N    P R O G R A M
; ============================================
;
;rjmp Reset
;Main:
;	rjmp PC
;
;
; ============================================
;            I N I T    V A L U E S
; ============================================
;
;Reset:
;	ldi aux1,LOW(RAMEND)  ; Init LSB stack
;	out SPL,aux1
;	ldi aux1,HIGH(RAMEND) ; Init LSB stack
;	out SPH,aux1
;
;	rjmp Main
;
; ============================================
;              F U N C T I O N S
; ============================================
;
;

.nolist
.include "m88def.inc"
.list
.def    secsct  = r21		;seconds counter
.def	r	=r16
.def	tmp	=r17

rjmp	RESET		;reset handle

.org	0x01
	rjmp    stop_count	;vetor de interrupção INT0 em 0x01
.org	0x10
	rjmp count1sec		; go to timer0 overflow counter interrupt routine

RESET:
    ldi r, low(RAMEND)
	out	SPL,r		;initialize Stack Pointer to last RAM address
	ldi	r,high(RAMEND)
	out SPH,r

	rcall clockinit

	;não tô entendendo nada
	cbi DDRD,pd2		; configura p/ entrada no pino 4 (int0)
	sbi DDRD,pd0		; saída: vamos ligar um led no pino 2 da CPU (pd0)
	sbi PORTD,pd2		; ativa resistor de pull up; deveria colocar o bit PD2 de PIND em 1
	ldi r,0
	sts EICRA, r		; queremos interromper no nivel baixo do sinal em pd2 (p. 84 datasheet)
	sbi eimsk,int0		; habilita interrupção INT0
	ldi r,5				; sleep power down(SM1=1) & sleep enable SE=1(p 37 datasheet)
	out SMCR,r			; do it 
	;END não tô entendendo nada

	ldi r,1			; era out TIMSK0,r no Atmega88 este registrador está fora do espaço de E/S!
	sts TIMSK0,r	; enable timer0 overflow interrupt (p.102 datasheet)
	ldi r,1			; set prescalong: 1= no prescaling 5=  CK/1024 pre-scaling (p 102-103 datasheet)
	out TCCR0B,r	; also starts timer0 counting
	out SMCR,r		; SMCR=1 selects idle mode sleep and enables sleep (p 37-38 datasheet)
	sei		; Global Interrupt enable

loop:
	ldi r,1			; set prescalong: 1= no prescaling 5=  CK/1024 pre-scaling (p 102-103 datasheet)
	out TCCR0B,r	; also starts timer0 counting

	sleep				; "dorme" no modo power down: só acorda via interrupção externa
	rjmp loop			; volta a "dormir" após serviço da interrupção


;**************************
count1sec:
	rcall clock
reti

stop_count:				; rotina de interrupcao INT0
	clr r
	out TCCR0B, r		; stop timer0 counter: no more interrupts
reti					; retorna com interrupções habilitadas

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
