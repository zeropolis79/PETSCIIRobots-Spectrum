@echo off
set path=%path%;..\sjasmplus
set path=%path%;d:\z80\unreal
del main.sna
@echo on
sjasmplus --msg=err main.asm --sym=labels.txt
rem sjasmplus loading_screen.asm --sym=labels.txt

@echo off
main.sna
