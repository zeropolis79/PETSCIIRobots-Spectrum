@echo off
set path=%path%;..\sjasmplus
del main.sna
del labels.txt

rem set options="--sym=labels.txt"

if %1 == 1 goto petmono
if %1 == 2 goto c64mono
if %1 == 3 goto minimono
if %1 == 4 goto minicolor
goto end

@echo on

:petmono
set name="pet_robots"
set name2="01 - PET Robots"
sjasmplus --msg=err include/vPET.asm main.asm
@if exist main.bin goto noerr
goto end

:c64mono
set name="gfx_robots"
set name2="02 - GFX Robots"
sjasmplus --msg=err include/vC64.asm main.asm
@if exist main.bin goto noerr
goto end

:minimono
set name="micro_bots"
set name2="03 - Micro Bots"
sjasmplus --msg=err include/vMiniMono.asm main.asm
@if exist main.bin goto noerr
goto end

:minicolor
set name="color_bots"
set name2="04 - Color Bots"
sjasmplus --msg=err include/vMiniColor.asm main.asm
@if exist main.bin goto noerr
goto end

rem ----------------------------

:noerr
tools\hrust13 -depacker -ei -start 25088 -depackto 25088 -dadr 65200 main.bin main.hrs
copy /Y petscr\%name%.tap %cd%\pet_robots48k.tap
sjasmplus addcode.asm
sjasmplus addlevels.asm
@if exist %name%.tap del %name%.tap
del %name2%.tap
ren pet_robots48k.tap %name%.tap
ren %name%.tap %name2%.tap

:end
del main.bin
del main.hrs