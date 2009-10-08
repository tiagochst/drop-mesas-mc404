;
; *********************************************
; * [Atividade 1 MC404 - Unicamp]             *
; * [Class project] 			      *
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
;
; ============================================
;               M A C R O S
; ============================================
;

.macro clrbitvet ; reset vector 
		 ; Input Parameters
		 ; @0 e @1: vector adress, vector length (números para multiplcar)
		 
.endmacro

.macro ctabits1 ;find how many 1 there are in the vector 
		; Input Parameters
		; @0 e @1: vector adress,output
.endmacro

;
; ============================================
;     M A I N    P R O G R A M    I N I T
; ============================================
;
Init:
; Init stack
	ldi rmp, LOW(RAMEND) ; Init LSB stack
	out SPL,rmp
	ldi rmp,high(RAMEND)
	out SPH, rmp

; Init RAM
	ldi yh, high(SRAM_START)	
	ldi yl, low(SRAM_START)
ret
;
; ============================================
;         P R O G R A M    L O O P
; ============================================
;

Loop:
	sleep ; go to sleep
	nop ; dummy for wake up
	rjmp loop ; go back to loop
;
; End of source code
;

