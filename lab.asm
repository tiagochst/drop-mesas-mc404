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
.equ hb_index = 0x00
.equ lb_index = 0x07

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

	ldi xh,high(vetor) ;vector init in SRAM (parameters to clrbitvet)
	ldi xl,low(vetor)  ;vector init in SRAM (parameters to clrbitvet)
	ldi yl,lb_index    ;vector size in bits (parameters to clrbitvet)
	ldi yh,hb_index    ;vector size in bits (parameters to clrbitvet)
	rcall clrbitvet


	ldi xh,high(vetor) ;vector init in SRAM (parameters to setdbit)
	ldi xl,low(vetor)  ;vector init in SRAM (parameters to setbit)
	ldi yl,0x08        ;position to find  (parameters to setbit)
	ldi yh,0x00        ;position to find (parameters to setbit)
	rcall setbit

	ldi xh,high(vetor) ;vector init in SRAM (parameters to clrbit)
	ldi xl,low(vetor)  ;vector init in SRAM (parameters to clrbit)
	ldi yl,lb_index       ;position to find  (parameters to clrbit)
	ldi yh,hb_index        ;position to find (parameters to clrbit)
	rcall clrbit 

	ldi xh,high(vetor) ;vector init in SRAM (parameters to clrbit)
	ldi xl,low(vetor)  ;vector init in SRAM (parameters to clrbit)
	ldi yl,lb_index        ;position to find  (parameters to clrbit)
	ldi yh,hb_index        ;position to find (parameters to clrbit)
	rcall tstbit

	ldi xh,high(vetor) ;vector init in SRAM (parameters to ctabits1)
	ldi xl,low(vetor)  ;vector init in SRAM (parameters to ctabits1)
	rcall ctabits1
	
	ldi xh,high(vetor) ;vector init in SRAM (parameters to clrbitvet)
	ldi xl,low(vetor)  ;vector init in SRAM (parameters to clrbitvet)
	ldi yl,lb_index    ;vector size in bits (parameters to clrbitvet)
	ldi yh,hb_index    ;vector size in bits (parameters to clrbitvet)
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
	mov zh,xh
	mov zl,xl
	
	rcall findbit

	ldi aux1,0x00

	cp zl,xl
	brne clrbitvet_loop
	cp zh,xh
	brne clrbitvet_loop

	rjmp clrbitvet_jump

	clrbitvet_loop:
		st Z+,aux1 ;reset all values of vector
		cp zl,xl
		brne clrbitvet_loop
		cp zh,xh
		brne clrbitvet_loop
	clrbitvet_jump:

	mov aux2,r17;Mask
	com aux2
	sec
	clrbitvet_loop2:
		LD r17,X
		and r17,aux2
		st X,r17
		rol aux2
		cpi aux2,0xFF
		brne clrbitvet_loop2
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

	mov aux1,yl  ;used for byte index
	ldi aux2,0  ;useless
	ldi aux3,3  ;loop
	ldi aux4,0x01 ;compare and skiping  
		
		findbit_loop: ;find position of vector in bytes 
			clc
			ror yh
			ror yl
			dec aux3
		brne findbit_loop

	add xl,yl ;byte init position in SRAM
	adc xh,yh  ;byte init position in SRAM

	ANDI aux1,0x07 ;0x07 used as bit mask
	ldi r17,7
	sub r17,aux1
	inc r17
	clc
	ldi aux2,0x01  ;useless
	ror aux2


		findbit_index_loop: ;find index value of the bit in the byte 
			rol aux2
			dec r17
			clc
		brne findbit_index_loop
		

		mov r17,aux2  ;byte index
ret
;
;
;
setbit: ;given the index of the bits change it to 1

rcall findbit
	mov aux2,r17;Mask
	LD r17,X
	or r17,aux2
	st X,r17
ret
;
;
;
clrbit :

rcall findbit
	mov aux2,r17;Mask
	com aux2
	LD r17,X
	and r17,aux2
	st X,r17
ret
;
;
;
tstbit:
	
rcall findbit
	mov aux2,r17;Mask
	ld r17,X
	and r17,aux2

cpi r17,0x00
breq tstbit_sai
set
ret

tstbit_sai:
clt
ret


vetorflash: .db 0x05, 0xFF,0x0F
