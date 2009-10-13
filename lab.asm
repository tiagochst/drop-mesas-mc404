;
; *********************************************
; * [Atividade 1 MC404 - Unicamp]             *
; * [Class project]                           *
; * (C)2009 by Alexandre Nobuo Kunieda 080523 *   
; *            Tiago Cheadraoui Silva  082941 *
; *********************************************
;
; Included header file for target AVR type
.NOLIST
.INCLUDE "m88def.inc"
.LIST
;
; ============================================
;   R E G I S T E R   D E F I N I T I O N S
; ============================================
;
; [Add all register names here, include info on
;  all used registers without specific names]
; Format: .DEF rmp = R16
.DEF rmp = R16
.DEF input1 = R18
.DEF input2 = R19
.DEF output = R20
;
;
.equ vetorflash_sz=2
;
.equ vetor_sz=vetorflash_sz
.dseg vetor: .byte vetor_sz
.cseg
;
; ============================================
;         P R O G R A M    L O O P
; ============================================
;
rjmp Reset
Main:
	rcall toram

	ldi input1, high(vetor)
	ldi input2, low(vetor)
	rcall ctabits1

	rjmp PC
;
;
; ============================================
;     M A I N    P R O G R A M    I N I T
; ============================================
;
Reset:
; Init stack
	ldi rmp, LOW(RAMEND) ; Init LSB stack
	out SPL,rmp
	ldi rmp,high(RAMEND)
	out SPH, rmp

; Init RAM
	ldi yh, high(SRAM_START)	
	ldi yl, low(SRAM_START)

	rjmp Main
;
; ============================================
;              F U N C T I O N S
; ============================================
;
;
ctabits1: ;find how many 1 there are in the vector 
	mov xh,input1
	mov xl,input2

	ldi r16,vetor_sz
	ldi r18,0
	ldi output,0
	ctabits1_loop:
		ld r17,X+

		ldi r19,8
		ctabits1_loop_byte:
			clc
			rol r17
			adc output,r18 ;r18 = 0
			dec r19
			brne ctabits1_loop_byte

		dec r16
		brne ctabits1_loop
ret

clrbitvet: ; reset vector 
ret

toram:
	ldi zh,high(vetorflash*2); multiplied by 2 for bytewise access
	ldi zl,low(vetorflash*2) ; multiplied by 2 for bytewise access
	ldi xh,high(vetor)
	ldi xl,low(vetor)

	ldi r16,vetor_sz
	toram_loop:
		lpm r17,Z+
		st X+,r17
		dec r16
		brne toram_loop
ret

vetorflash: .db 0x04, 0x23
