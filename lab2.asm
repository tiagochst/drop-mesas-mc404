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
.DEF secsct = r21  ;seconds counter
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
	rcall lcd_writetime
	rjmp MAINLOOP  ;volta a "dormir" após serviço da interrupção

; ============================================
;            I N I T    V A L U E S
; ============================================
RESET:
    ldi r, low(RAMEND)
	out	SPL, r
	ldi	r, high(RAMEND)
	out SPH, r

	rcall clockinit

	ldi r,0
	sts EICRA, r		; queremos interromper no nivel baixo do sinal em pd2 (p. 84 datasheet)
	ldi r,5				; sleep power down(SM1=1) & sleep enable SE=1(p 37 datasheet)
	out SMCR,r			; do it 

	ldi r,1			; era out TIMSK0,r no Atmega88 este registrador está fora do espaço de E/S!
	sts PCICR, r               ; Ativa interrup. da porta B
	sts PCMSK0,r               ; Bit 0 da porta B causa interrup.
	sts TIMSK0,r	; enable timer0 overflow interrupt (p.102 datasheet)
	ldi r,1			; set prescalong: 1= no prescaling 5=  CK/1024 pre-scaling (p 102-103 datasheet)
	out TCCR0B,r	; also starts timer0 counting
	sei		; Global Interrupt enable

	rcall lcdinit
	rjmp MAINLOOP

; ============================================
;              F U N C T I O N S
; ============================================
;
; INTERRUPTION routines
count1sec:
	rcall clock
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


;
; HAPSIM functions
lcd_busy:
	; test the busy state
	sbi portc,RW        ; RW high to read
	cbi portc,RS        ; RS low to read

	ldi r16,0			; make port input
	out ddrd,r16
	out portd,r16

	lcd_busy_loop:
		sbi portc,ENABLE    ; begin read sequence
		in r16,pind         ; read it
		cbi portc,ENABLE    ; set enable back to low
		;cbi portc,RW    ; clear the RW back to write mode
		sbrc r16,7          ; test bit 7, skip if clear
	rjmp lcd_busy_loop       ; jump if set

	ldi r16,0xff        ; make port output
	out ddrd,r16
ret

lcd_cmd:
	; lcd_cmd writes the LCD command in r19 to the LCD
	cbi portc,RS    ; RS low for command mode
	cbi portc,RW    ; RW low to write
	sbi portc,ENABLE    ; Enable HIGH
	out portd,lcdinput  ; output
	cbi portc,ENABLE    ; Enable LOW to execute
ret

lcd_write:
	; lcd_write writes the value in r19 to the LCD
	sbi portc,RS    ; RS high
	cbi portc,RW    ; RW low to write
	sbi portc,ENABLE    ; Enable HIGH
	out portd,lcdinput  ; output
	cbi portc,ENABLE    ; Enable LOW to execute
ret

writemsg:
	ld lcdinput,z+      ; load r0 with the character to display          ; increment the string counter
	cpi lcdinput, 0xFF
	breq writedone
	rcall lcd_write
	rcall lcd_busy
	rjmp writemsg
writedone:
ret

lcdinit: 			;initialize LCD
	ldi r16,0xff
	out ddrd,r16 	;portb is the LCD data port, 8 bit mode set for output
	out ddrc,r16	;portc is the LCD control pins set for output
	ldi lcdinput,56  ; init the LCD. 8 bit mode, 2*16
	rcall lcd_cmd    ; execute the command
	rcall lcd_busy   ; test busy
	ldi lcdinput,1		; clear screen
	rcall lcd_cmd
	rcall lcd_busy
	;ldi lcdinput,15 	; show cursor and blink it
	;rcall lcd_cmd
	;rcall lcd_busy
	ldi lcdinput,2      ; cursor home command
	rcall lcd_cmd        ; execute command
	rcall lcd_busy
ret

lcd_writetime:
	ldi lcdinput,2  ; init the LCD. 8 bit mode, 2*16
	ldi zh, high(SRAM_START)
	ldi zl, low(SRAM_START)
	rcall lcd_cmd
	rcall lcd_busy
	rcall writemsg  ; display it
ret
