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
;       S R A M   D E F I N I T I O N S
; ============================================
;
.DSEG
.ORG  0X0060
; Format: Label: .BYTE N ; reserve N Bytes from Label:
;
; ============================================
;   R E S E T   A N D   I N T   V E C T O R S
; ============================================
;
.CSEG
.ORG $0000
	rjmp Main ; Reset vector
	reti ; Int vector 1
	reti ; Int vector 2
	reti ; Int vector 3
	reti ; Int vector 4
	reti ; Int vector 5
	reti ; Int vector 6
	reti ; Int vector 7
	reti ; Int vector 8
	reti ; Int vector 9
;
; ============================================
;     I N T E R R U P T   S E R V I C E S
; ============================================
;
; [Add all interrupt service routines here]
;
; ============================================
;     M A I N    P R O G R A M    I N I T
; ============================================
;
Main:
; Init stack
	ldi rmp, LOW(RAMEND) ; Init LSB stack
	out SPL,rmp
	ldi rmp,high(RAMEND)
	out SPH, rmp

; Init RAM
	ldi yh, high(SRAM_START)	
	ldi yl, low(SRAM_START)

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

