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
.DEF aux1 = R20
.DEF aux2 = R21
.DEF aux3 = R22
.DEF aux4 = R23
.DEF e2proml = R24
.DEF e2promh = R25
;
;
.equ vetorflash_sz = 4
;
.equ vetor_sz = vetorflash_sz
.equ hb_index = 0x00
.equ lb_index = 0x0F
;
; ============================================
;           M A I N    P R O G R A M
; ============================================
;
rjmp Reset
Main:
	rcall toe2prom

	ldi xh,0x00      ; vector init in eeprom (parameters to clrbitvet)
	ldi xl,0x00      ; vector init in eeprom (parameters to clrbitvet)
	ldi yl,lb_index  ; vector size in bits (parameters to clrbitvet)
	ldi yh,hb_index  ; vector size in bits (parameters to clrbitvet)
	rcall clrbitvet

	ldi xh,0x00      ; vector init in eeprom (parameters to setbit)
	ldi xl,0x00      ; vector init in eeprom (parameters to setbit)
	ldi yl,0x08      ; position to find (parameters to setbit)
	ldi yh,0x00      ; position to find (parameters to setbit)
	rcall setbit

	ldi xh,0x00      ; vector init in eeprom (parameters to clrbit)
	ldi xl,0x00      ; vector init in eeprom (parameters to clrbit)
	ldi yl,lb_index  ; position to find (parameters to clrbit)
	ldi yh,hb_index  ; position to find (parameters to clrbit)
	rcall clrbit 

	ldi xh,0x00      ; vector init in eeprom (parameters to tstbit)
	ldi xl,0x00      ; vector init in eeprom (parameters to tstbit)
	ldi yl,lb_index  ; position to find (parameters to tstbit)
	ldi yh,hb_index  ; position to find (parameters to tstbit)
	rcall tstbit

	ldi xh,0x00      ; vector init in eeprom (parameters to ctabits1)
	ldi xl,0x00      ; vector init in eeprom (parameters to ctabits1)
	rcall ctabits1

	rjmp PC
;
;
; ============================================
;            I N I T    V A L U E S
; ============================================
;
Reset:
	ldi aux1,LOW(RAMEND)  ; Init LSB stack
	out SPL,aux1
	ldi aux1,HIGH(RAMEND) ; Init LSB stack
	out SPH,aux1

	ldi e2proml,0x00    ; eeprom address init
	ldi e2promh,0x00    ; eeprom address init

	rjmp Main
;
; ============================================
;              F U N C T I O N S
; ============================================
;
;
;********************************************************************************
;toe2prom   ;copies a vector from vetorflash, in program memory, with vetorflash_sz
            ;bytes to e2prom, writing in the position e2prom pointer is
            ;input:
            ;output:
;********************************************************************************
toe2prom:
	ldi zh,high(vetorflash*2); multiplied by 2 for bytewise access
	ldi zl,low(vetorflash*2) ; multiplied by 2 for bytewise access

	ldi aux1,vetor_sz
	toe2prom_loop:
		lpm r16,Z+
		rcall wtbyte
		adiw e2promh:e2proml, 1
		dec aux1
		brne toe2prom_loop
ret
;
;
;
;********************************************************************************
;ctabits1   ;given the inicial address of a vector
            ;count the number of bits one in the vector
            ;input:
                        ; xh:xl: eeprom initial address
            ;output:
                        ; yh:yl: number of ones
                        ; changes aux1,aux2,aux3,e2promh,e2proml,r16
;********************************************************************************
ctabits1:
	ldi aux1,vetor_sz
	ldi aux2,0   ; set aux2 = 0
	ldi yh,0x00  ; reset number of bits one
	ldi yl,0x00  ; reset number of bits one

	mov e2promh,xh
	mov e2proml,xl

	ctabits1_loop:
		rcall rdbyte
		adiw e2promh:e2proml, 1

		ldi aux3,8           ; 1 byte
		ctabits1_loop_byte:  ; put the leftmost bit of the byte in carry
			clc
			rol r16
			adc yl,aux2  ; sum carry to yl
			adc yh,aux2  ; sum carry to yh
			dec aux3
			brne ctabits1_loop_byte

		dec aux1             ; number of missing bytes to be visited
		brne ctabits1_loop
ret
;
;
;
;********************************************************************************
;clrbitvet  ;given the length of a vector and its inicial address
            ;every bit between the initial address and this address added
            ;the given length is cleared
            ;input:
                        ; yh:yl: vector length 
                        ; xh:xl: eeprom initial address
            ; changes aux2,e2promh,e2proml,r16
;********************************************************************************
clrbitvet:
	mov e2promh,xh
	mov e2proml,xl
	rcall findbit

	cp e2proml,xl
	brne clrbitvet_loop
	cp e2promh,xh
	brne clrbitvet_loop
	rjmp clrbitvet_jump

	ldi r16,0x00
	clrbitvet_loop:
		rcall wtbyte ; reset all values of vector
		adiw e2promh:e2proml, 1

		cp e2proml,xl
		brne clrbitvet_loop
		cp e2promh,xh
		brne clrbitvet_loop

	clrbitvet_jump:
	; at this point we have e2prom=X

	mov aux2,r17 ; r17 was calculated at findbit
	com aux2     ; generates a bit mask
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
;********************************************************************************
;findbit    ;given the index of the bit in the vector and the init address of eemprom
            ;find the bit and put an index (r17) of the bit in its byte 
            ;input:
                        ; yh:yl: index of the bit 
                        ; xh:xl: initial address of the vector in eeprom
            ;output:
                        ; r17:   index of the bit in its byte
                        ; xh:xl: final address of the vector in eeprom
                        ; changes aux1,aux2
;********************************************************************************
findbit:
	mov aux1,yl  ;used for byte index
	ldi aux2,3   ;loop

	findbit_loop: ; find position of vector in bytes 
		clc
		ror yh
		ror yl
		dec aux2
		brne findbit_loop

	add xl,yl   ; byte init position in SRAM
	adc xh,yh   ; byte init position in SRAM

	andi aux1,7 ; 7 used as bit mask
	ldi r17,7
	sub r17,aux1
	inc r17

	ldi aux2,1
	clc
	ror aux2

	findbit_index_loop: ; find index value of the bit in the byte
		rol aux2
		clc
		dec r17
		brne findbit_index_loop

	mov r17,aux2  ; bit index
ret
;
;
;
;********************************************************************************
;setbit	    ;given the index of the bit change it to 1
            ;input:
                        ; yh:yl: index of the bit 
                        ; xh:xl: initial address of the vector in eeprom
                        ; changes r16,r17
;********************************************************************************
setbit:
	rcall findbit

	rcall rdbyte
	or r16,r17  ; r17 is a bit mask calculated in findbit
	rcall wtbyte
ret
;
;
;
;********************************************************************************
;clrbit	    ;clear one bit in EEPROM
            ;input:
                        ; yh:yl: index of the bit 
                        ; xh:xl: initial address of the vector in eeprom
                        ; changes r16,r17
;********************************************************************************	
clrbit :
	rcall findbit
	com r17

	rcall rdbyte
	and r16,r17
	rcall wtbyte
ret
;
;
;
;********************************************************************************
;tstbit     ;copy to the status register T the bit of a given index
            ;input:
                        ; yh:yl: index of the bit
                        ; xh:xl: initial address of the vector in eeprom
                        ; changes r16,r17
;********************************************************************************
tstbit:
	rcall findbit

	rcall rdbyte
	and r16,r17  ; r17 is a bit mask calculated in findbit

	cpi r16,0
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
;wtbyte     ;write one byte in EEPROM
            ;input:
                        ; r25, r24 (high, low) byte's address to be written
                        ; r16 byte to be written
                        ; changes EECR, EEARH, EEARL
;********************************************************************************
wtbyte:
	sbic EECR,EEPE             ; Wait for completion of previous write
	rjmp wtbyte
	out EEARH, e2promh         ; Set up address (r25:r24) in address register
	out EEARL, e2proml
	out EEDR,r16               ; Write data (r16) to Data Register
	cli                        ; disable interrupts
	sbi EECR,EEMPE             ; Write logical one to EEMPE
	sbi EECR,EEPE              ; Start eeprom write by setting EEPE
	sei                        ; enable interrupts
ret
;
;
;
;********************************************************************************
;rdbyte     ;read one byte in EEPROM
            ;input:
                        ; r25, r24 (high, low) byte's address to be read
            ;output:
                        ; r16 byte read
                        ; changes EECR, EEARH, EEARL
;********************************************************************************
rdbyte:
	sbic EECR,EEPE      ; Wait for completion of previous write
	rjmp rdbyte
	out EEARH, e2promh  ; Set up address (r25:r24) in address register
	out EEARL, e2proml
	sbi EECR,EERE       ; Start eeprom read by writing EERE
	in r16,EEDR         ; Read data from Data Register
ret
;
;
;
;********************************************************************************
vetorflash:.db 0x05, 0xFF,0x0F,0x08
