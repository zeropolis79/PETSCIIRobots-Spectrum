	org 60000

;BeepFX player by Shiru
;You are free to do whatever you want with this code



playBasic:
	ld a,0
play:
	ld hl,sfxData	;address of sound effects data

	di
	push ix
	push iy

	ld b,0
	ld c,a
	add hl,bc
	add hl,bc
	ld e,(hl)
	inc hl
	ld d,(hl)
	push de
	pop ix			;put it into ix

	ld a,(23624)	;get border color from BASIC vars to keep it unchanged
	rra
	rra
	rra
	and 7
	ld (sfxRoutineToneBorder  +1),a
	ld (sfxRoutineNoiseBorder +1),a
	ld (sfxRoutineSampleBorder+1),a


readData:
	ld a,(ix+0)		;read block type
	ld c,(ix+1)		;read duration 1
	ld b,(ix+2)
	ld e,(ix+3)		;read duration 2
	ld d,(ix+4)
	push de
	pop iy

	dec a
	jr z,sfxRoutineTone
	dec a
	jr z,sfxRoutineNoise
	dec a
	jr z,sfxRoutineSample
	pop iy
	pop ix
	ei
	ret

	

;play sample

sfxRoutineSample:
	ex de,hl
sfxRS0:
	ld e,8
	ld d,(hl)
	inc hl
sfxRS1:
	ld a,(ix+5)
sfxRS2:
	dec a
	jr nz,sfxRS2
	rl d
	sbc a,a
	and 16
sfxRoutineSampleBorder:
	or 0
	out (254),a
	dec e
	jr nz,sfxRS1
	dec bc
	ld a,b
	or c
	jr nz,sfxRS0

	ld c,6
	
nextData:
	add ix,bc		;skip to the next block
	jr readData



;generate tone with many parameters

sfxRoutineTone:
	ld e,(ix+5)		;freq
	ld d,(ix+6)
	ld a,(ix+9)		;duty
	ld (sfxRoutineToneDuty+1),a
	ld hl,0

sfxRT0:
	push bc
	push iy
	pop bc
sfxRT1:
	add hl,de
	ld a,h
sfxRoutineToneDuty:
	cp 0
	sbc a,a
	and 16
sfxRoutineToneBorder:
	or 0
	out (254),a

	dec bc
	ld a,b
	or c
	jr nz,sfxRT1

	ld a,(sfxRoutineToneDuty+1)	 ;duty change
	add a,(ix+10)
	ld (sfxRoutineToneDuty+1),a

	ld c,(ix+7)		;slide
	ld b,(ix+8)
	ex de,hl
	add hl,bc
	ex de,hl

	pop bc
	dec bc
	ld a,b
	or c
	jr nz,sfxRT0

	ld c,11
	jr nextData



;generate noise with two parameters

sfxRoutineNoise:
	ld e,(ix+5)		;pitch

	ld d,1
	ld h,d
	ld l,d
sfxRN0:
	push bc
	push iy
	pop bc
sfxRN1:
	ld a,(hl)
	and 16
sfxRoutineNoiseBorder:
	or 0
	out (254),a
	dec d
	jr nz,sfxRN2
	ld d,e
	inc hl
	ld a,h
	and 31
	ld h,a
sfxRN2:
	dec bc
	ld a,b
	or c
	jr nz,sfxRN1

	ld a,e
	add a,(ix+6)	;slide
	ld e,a

	pop bc
	dec bc
	ld a,b
	or c
	jr nz,sfxRN0

	ld c,7
	jr nextData


sfxData:

SoundEffectsData:
	defw SoundEffect0Data
	defw SoundEffect1Data
	defw SoundEffect2Data
	defw SoundEffect3Data
	defw SoundEffect4Data
	defw SoundEffect5Data
	defw SoundEffect6Data
	defw SoundEffect7Data
	defw SoundEffect8Data
	defw SoundEffect9Data
	defw SoundEffect10Data
	defw SoundEffect11Data
	defw SoundEffect12Data
	defw SoundEffect13Data
	defw SoundEffect14Data
	defw SoundEffect15Data
	defw SoundEffect16Data
	defw SoundEffect17Data
	defw SoundEffect18Data
	defw SoundEffect19Data
	defw SoundEffect20Data
	defw SoundEffect21Data
	defw SoundEffect22Data
	defw SoundEffect23Data
	defw SoundEffect24Data
	defw SoundEffect25Data
	defw SoundEffect26Data
	defw SoundEffect27Data
	defw SoundEffect28Data
	defw SoundEffect29Data
	defw SoundEffect30Data

SoundEffect0Data:
	defb 1 ;tone
	defw 4,1000,400,65436,128
	defb 2 ;noise
	defw 1,5000,150
	defb 0
SoundEffect1Data:
	defb 2 ;noise
	defw 8,200,20
	defb 2 ;noise
	defw 4,2000,5220
	defb 0
SoundEffect2Data:
	defb 1 ;tone
	defw 50,200,500,65516,64
	defb 0
SoundEffect3Data:
	defb 1 ;tone
	defw 150,200,3400,10,64
	defb 0
SoundEffect4Data:
	defb 1 ;tone
	defw 5,200,200,8,128
	defb 1 ;tone
	defw 8,200,2000,8,128
	defb 1 ;pause
	defw 1,2000,0,0,0
	defb 1 ;tone
	defw 5,200,400,6,32
	defb 1 ;tone
	defw 9,200,4000,6,32
	defb 1 ;pause
	defw 1,2000,0,0,0
	defb 1 ;tone
	defw 5,200,300,65528,16
	defb 1 ;tone
	defw 10,200,3000,65528,16
	defb 1 ;pause
	defw 1,2000,0,0,0
	defb 1 ;tone
	defw 5,200,250,0,8
	defb 1 ;tone
	defw 10,200,2500,0,8
	defb 0
SoundEffect5Data:
	defb 2 ;noise
	defw 50,250,2561
	defb 0
SoundEffect6Data:
	defb 2 ;noise
	defw 1,1000,20
	defb 1 ;pause
	defw 1,1000,0,0,0
	defb 2 ;noise
	defw 1,2000,1
	defb 0
SoundEffect7Data:
	defb 1 ;tone
	defw 40,40,1000,8,40191
	defb 1 ;tone
	defw 400,20,100,20000,62464
	defb 0
SoundEffect8Data:
	defb 1 ;tone
	defw 2,1000,400,100,64
	defb 1 ;tone
	defw 2,1000,400,100,64
	defb 1 ;tone
	defw 2,1000,400,100,64
	defb 1 ;tone
	defw 2,1000,400,100,8
	defb 0
SoundEffect9Data:
	defb 2 ;noise
	defw 50,20,200
	defb 1 ;pause
	defw 10,50,0,0,0
	defb 2 ;noise
	defw 4,1000,62986
	defb 0
SoundEffect10Data:
	defb 1 ;tone
	defw 4,1000,500,100,640
	defb 1 ;tone
	defw 4,1000,500,100,576
	defb 1 ;tone
	defw 4,1000,500,100,528
	defb 0
SoundEffect11Data:
	defb 1 ;tone
	defw 300,10,100,0,25616
	defb 0
SoundEffect12Data:
	defb 1 ;tone
	defw 4,1000,1000,65136,128
	defb 0
SoundEffect13Data:
	defb 1 ;tone
	defw 4,1000,2000,64736,128
	defb 0
SoundEffect14Data:
	defb 1 ;tone
	defw 1000,10,1,0,3200
	defb 0
SoundEffect15Data:
	defb 1 ;tone
	defw 1,1000,2000,0,64
	defb 1 ;pause
	defw 1,1000,0,0,0
	defb 1 ;tone
	defw 1,1000,1500,0,64
	defb 0
SoundEffect16Data:
	defb 2 ;noise
	defw 1,1000,4
	defb 1 ;tone
	defw 1,1000,2000,0,128
	defb 0
SoundEffect17Data:
	defb 1 ;tone
	defw 64,500,500,16384,257
	defb 0
SoundEffect18Data:
	defb 1 ;tone
	defw 1,2000,400,0,128
	defb 1 ;pause
	defw 1,2000,0,0,0
	defb 1 ;tone
	defw 1,2000,800,0,128
	defb 1 ;tone
	defw 1,2000,400,0,16
	defb 0
SoundEffect19Data:
	defb 1 ;tone
	defw 10,10,100,100,48
	defb 0
SoundEffect20Data:
	defb 1 ;tone
	defw 10,10,100,100,16
	defb 0
SoundEffect21Data:
	defb 1 ;tone
	defw 5,100,200,70,2112
	defb 2 ;noise
	defw 20,100,32769
	defb 0
SoundEffect22Data:
	defb 1 ;tone
	defw 100,10,7000,0,2176
	defb 2 ;noise
	defw 1,500,10
	defb 1 ;tone
	defw 20,100,400,65526,128
	defb 2 ;noise
	defw 1,1000,1
	defb 0
SoundEffect23Data:
	defb 1 ;tone
	defw 10,500,9806,6800,25728
	defb 2 ;noise
	defw 5,1000,5124
	defb 1 ;tone
	defw 50,100,200,65534,128
	defb 2 ;noise
	defw 500,20,266
	defb 0
SoundEffect24Data:
	defb 1 ;tone
	defw 20,960,460,10,2049
	defb 2 ;noise
	defw 200,200,264
	defb 0
SoundEffect25Data:
	defb 1 ;tone
	defw 100,20,2000,65446,23041
	defb 1 ;tone
	defw 300,10,100,0,25728
	defb 0
SoundEffect26Data:
	defb 1 ;tone
	defw 15,200,350,65535,25728
	defb 0
SoundEffect27Data:
	defb 2 ;noise
	defw 100,100,2049
	defb 1 ;tone
	defw 50,200,350,1,25728
	defb 0
SoundEffect28Data:
	defb 1 ;tone
	defw 10,100,200,80,8
	defb 0
SoundEffect29Data:
	defb 1 ;tone
	defw 25,100,1500,1000,8
	defb 0
SoundEffect30Data:
	defb 1 ;tone
	defw 100,100,1500,20,32
	defb 1 ;tone
	defw 100,100,1500,20,16
	defb 1 ;tone
	defw 100,100,1500,20,8
	defb 1 ;tone
	defw 100,100,1500,20,4
	defb 1 ;tone
	defw 100,100,1500,20,2
	defb 0
