@ECHO OFF
"C:\Arquivos de programas\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "H:\windows\lab\labels.tmp" -fI -W+ie -o "H:\windows\lab\lab.hex" -d "H:\windows\lab\lab.obj" -e "H:\windows\lab\lab.eep" -m "H:\windows\lab\lab.map" "H:\windows\lab\lab.asm"
