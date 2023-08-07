@echo off
set path=%path%;..\..\sjasmplus
copy /Y ..\res\pet_robots.tap %cd%
copy /Y ..\res\gfx_robots.tap %cd%
copy /Y ..\res\micro_bots.tap %cd%
copy /Y ..\res\color_bots.tap %cd%
sjasmplus main1.asm
..\tools\apultra -c main1.bin main1.apl
sjasmplus main.asm
