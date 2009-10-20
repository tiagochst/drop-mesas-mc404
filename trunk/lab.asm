;; *********************************************
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
.DEF aux1 = R21
.DEF aux2 = R22
.DEF aux3 = R23
.DEF aux4 = R24


;
;
.equ vetorflash_sz=3
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

	rcall setbit
	rcall findbit
	rcall ctabits1
	rcall clrbitvet

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

	ldi aux1,vetor_sz
	ldi aux2,0
	ldi yh,0x00
	ldi yl,0x00
		

	ctabits1_loop:
		ld r17,X+

		ldi aux3,8  ;1 byte
		ctabits1_loop_byte:
			clc
			rol r17
			adc yl,aux2 ;aux2 = 0
			adc yh,aux2 ;aux2 = 0

			dec aux3
			brne ctabits1_loop_byte

		dec aux1
		brne ctabits1_loop
ret
;
;
;
clrbitvet: ; reset vector 

	ldi xh,high(vetor) ;vector init in SRAM
	ldi xl,low(vetor)  ;vector init in SRAM

	ldi yl,vetor_sz 
	ldi aux1,0

	clrbitvet_loop:

		st X+,aux1 ;reset all values of vector
		dec yl   ;ends when equal to zero 
		brne clrbitvet_loop
ret
;
;
;
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
;
;
;
findbit:   ;input : vector adress,index [vector]
		   ;output : bytes adress, index [byte]

	ldi xh,high(vetor) ;vector init in SRAM
	ldi xl,low(vetor)  ;vector init in SRAM
	ldi yl,0x0C ;position to find 
	ldi yh,0x00 ;position to find 

	mov aux1,yl  ;used for byte index
	ldi aux2,0  ;useless
	ldi aux3,3  ;loop
	ldi aux4,0x01 ;compare and skiping  
		
		findbit_loop: ;find position of vector 
			clc
			ror yh
			ror yl
			dec aux3
		brne findbit_loop

	add xl,yl ;byte init position in SRAM
	adc xh,yh  ;byte init position in SRAM

	ANDI aux1,0x07
	ldi r17,7
	sub r17,aux1	
	ldi aux2,0x01  ;useless

		findbit_index_loop: ;find position of vector 
			clc
			rol aux2
			dec r17
		brne findbit_index_loop

		mov r17,aux2  ;byte index
ret
;
;
;
setbit: ;given the index of the bits change it to 1

rcall findbit

	ldi aux2,r17;Mask
	LD r17,X
	or r17,aux2
	st x,r17

ret
;
;
;
clrbit :
ret
;
;
;
tstbit:
ret


vetorflash: .db 0x05, 0x15,0x20
