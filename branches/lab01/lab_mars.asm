.nolist
.include "m88def.inc"
.list

.equ tam=2

vetor: .db 0x04, 0x23

rjmp start

;Soma ao registrador @0 o valor do carry
;Estraga carry
.macro somacarry
push r0
clr r0
adc @0, r0

pop r0
.endmacro

;Recebe em X o inicio do vetor e devolve em Y a qtde de bits 1
;Estraga r16, r1
ctabits1:
ldi r16,tam
clr yh
clr yl

cta_loop:
tst r16
brne PC+2
rjmp cta_saida

dec r16
ld r1, X+

clc
ror r1
somacarry yl
somacarry yh
clc
ror r1
somacarry yl
somacarry yh
clc
ror r1
somacarry yl
somacarry yh
clc
ror r1
somacarry yl
somacarry yh
clc
ror r1
somacarry yl
somacarry yh
clc
ror r1
somacarry yl
somacarry yh
clc
ror r1
somacarry yl
somacarry yh
clc
ror r1
somacarry yl
somacarry yh

rjmp cta_loop

cta_saida:
ret

;Rotina para copia de um vetor de tamanho tam
;na flash (endereco Z) para a RAM (endereco Y) 
copia_vetor:
push r16
push r0
ldi r16, tam

cpv_loop:
tst r16
breq cpv_saida

dec r16
lpm r0,Z+
st Y+, r0

rjmp cpv_loop

cpv_saida:
pop r0
pop r16
ret

start:
ldi r16, low(RAMEND)
out SPL, r16
ldi r16, high(RAMEND)
out SPH, r16

ldi zl, low(vetor)
ldi zh, high(vetor)
ldi yl, low(SRAM_START)
ldi yh, high(SRAM_START)

rcall copia_vetor

ldi xl, low(SRAM_START)
ldi xh, high(SRAM_START)
rcall ctabits1

rjmp pc
