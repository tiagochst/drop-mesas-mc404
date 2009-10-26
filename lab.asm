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
.DEF rmp = R16
.DEF e2proml = R24
.DEF e2promh = R25
.DEF output = R19
.DEF aux1 = R20
.DEF aux2 = R21
.DEF aux3 = R22
.DEF aux4 = R23
;
;
.equ vetorflash_sz=4
;
.equ vetor_sz=vetorflash_sz
.equ hb_index = 0x00
.equ lb_index = 0x0F
;
; ============================================
;         P R O G R A M    L O O P
; ============================================
;
rjmp Reset
Main:
	rcall toe2prom

	ldi xh,0x00      ;XX vector init in SRAM (parameters to clrbitvet)
	ldi xl,0x00      ;XX vector init in SRAM (parameters to clrbitvet)
	ldi yl,lb_index  ;vector size in bits (parameters to clrbitvet)
	ldi yh,hb_index  ;vector size in bits (parameters to clrbitvet)
	rcall clrbitvet


	ldi xh,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
	ldi xl,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
	ldi yl,0x08        ;position to find  (parameters to setbit)
	ldi yh,0x00        ;position to find (parameters to setbit)
	rcall setbit

	ldi xh,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
	ldi xl,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
	ldi yl,lb_index       ;position to find  (parameters to clrbit)
	ldi yh,hb_index        ;position to find (parameters to clrbit)
	rcall clrbit 

	ldi xh,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
	ldi xl,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
	ldi yl,lb_index        ;position to find  (parameters to clrbit)
	ldi yh,hb_index        ;position to find (parameters to clrbit)
	rcall tstbit

	ldi xh,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
	ldi xl,0x00   ;XX vector init in SRAM (parameters to clrbitvet)
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

	ldi e2proml, 0x00
	ldi e2promh, 0x00

	rjmp Main
;
; ============================================
;              F U N C T I O N S
; ============================================
;
;

;********************************************************************************
;ctabits1	;given a the inicial vector's address
            ;count how many bits ones is there in the vector 
            ;input:
			; xh:xl:eeprom's address init 
            ;output:
			;yh,:yl: number of ones
			; changes aux1,aux2,e2promh,e2proml,r16,aux3
;********************************************************************************
ctabits1: ;find how many 1 there are in the vector 

	ldi aux1,vetor_sz
	ldi aux2,0
	ldi yh,0x00
	ldi yl,0x00

	mov e2promh,xh
	mov e2proml,xl

	ctabits1_loop:
		rcall rdbyte
		adiw e2promh:e2proml, 1

		ldi aux3,8  ;1 byte
		ctabits1_loop_byte:
			clc
			rol r16
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
;********************************************************************************
;clrbitvet	;given a length of the vector plus its inicial address
            ;every bit is cleared through the initial address 
			;and the address added by the length
            ;input:
			; yh:yl:vector length 
			; xh:xl:eeprom's address init 
            ; changes e2promh,e2proml,r16,aux2
;********************************************************************************
clrbitvet: ; reset vector 
	mov e2promh,xh
	mov e2proml,xl

	rcall findbit

	ldi aux1,0x00

	cp e2proml,xl
	brne clrbitvet_loop
	cp e2promh,xh
	brne clrbitvet_loop

	rjmp clrbitvet_jump

	clrbitvet_loop:
		mov r16,aux1
		rcall wtbyte ;reset all values of vector
		adiw e2promh:e2proml, 1

		cp e2proml,xl
		brne clrbitvet_loop
		cp e2promh,xh
		brne clrbitvet_loop
	clrbitvet_jump:

	;neste ponto, e2prom=X
	mov r16,r17 ;pega valor calculado em findbit
	mov aux2,r16;Mask
	com aux2
	sec
	clrbitvet_loop2:
		rcall rdbyte
		and r16,aux2
		rcall wtbyte
		rol aux2
		cpi aux2,0xFF
		brne clrbitvet_loop2
ret
;
;
;
toe2prom:
	ldi zh,high(vetorflash*2); multiplied by 2 for bytewise access
	ldi zl,low(vetorflash*2) ; multiplied by 2 for bytewise access

	ldi aux1,vetor_sz
	toe2prom_loop:
		lpm r16,Z+
		rcall wtbyte
		adiw e2promh:e2proml,0x01
		dec aux1
		brne toe2prom_loop
ret
;
;
;
;********************************************************************************
;find	    ;given the index of the bit in the vector and the init address of eemprom
            ;find the bit and put an index (r17) of the bit in its byte 
            ;input:
			; yh:hl:index of the bit 
			; xh:xl:eeprom's address init 
            ;output:
			; r17 index of the bit in its byte
			; changes aux1,aux2,aux3,aux4,r17
;********************************************************************************
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

;********************************************************************************
;setbit	    ;given the index of the bits change it to 1
            ;input:
			; yh:hl:index of the bit 
			; changes r16,aux2
;********************************************************************************
setbit:
	rcall findbit
	mov r16,r17

	mov aux2,r16;Mask
	rcall rdbyte
	or r16,aux2
	rcall wtbyte
ret
;
;
;
;********************************************************************************
;clrbit		;clear one bit in EEPROM
            ;input:
			; yh:hl:index of the bit 
			; changes r16,aux2
;********************************************************************************	
clrbit :
	rcall findbit
	mov r16,r17

	mov aux2,r16;Mask
	com aux2
	rcall rdbyte
	and r16,aux2
	rcall wtbyte
ret
;
;
;
;********************************************************************************
;tstbit 	;copy to the register T the bit of a given index
            ;input:
			; yh:hl:index of the bit 
			; changes r16,aux2
;********************************************************************************
tstbit:
	rcall findbit
	mov r16,r17

	mov aux2,r16;Mask
	rcall rdbyte
	and r16,aux2

	cpi r16,0x00
	breq tstbit_sai
	set
	ret

	tstbit_sai:
	clt
ret
;
;
;
;
;********************************************************************************

;wtbyte		;write one byte in EEPROM
            ;input:
			; r25, r24 (high, low) byte's address to be written
			; r16 byte to be written
			; changes EECR, EEARH, EEARL
;********************************************************************	

wtbyte:
	sbic EECR,EEPE           ;Wait for completion of previous write
	rjmp wtbyte
	out EEARH, R25            ;Set up address (r25:r24) in address register
	out EEARL, R24
	out EEDR,r16               ; Write data (r16) to Data Register
	cli                        ; disable interrupts
	sbi EECR,EEMPE             ; Write logical one to EEMPE
	sbi EECR,EEPE              ; Start eeprom write by setting EEPE
	sei                         ; enable interrupts
	ret



;********************************************************************************
;   rdbyte: read one byte in eeprom
; 	input: r25:r24   eeprom's address(high,low) of the byte to be read  
;	output:	   r16   read byte 
;   detroy: none
;********************************************************************************

rdbyte:
    sbic EECR,EEPE      ; Wait for completion of previous write
    rjmp rdbyte 
    out EEARH, R25      ; Set up address (r25:r24) in address register
    out EEARL, R24
    sbi EECR,EERE       ; Start eeprom read by writing EERE
    in r16,EEDR         ; Read data from Data Register
    ret

;********************************************************************************

vetorflash:.db 0x05, 0xFF,0x0F,0x08
