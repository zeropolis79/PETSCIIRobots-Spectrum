play_music:
	
	di

	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (.pitch_table),hl
	add hl,de
	push hl
	pop ix

	ld (.old_sp),sp
	
	ld a,1
	ld (.wait),a
	
	ld de,#1000
	ld hl,0
	ld sp,0
	
.frame_loop:

.wait=$+1
	ld a,0
	dec a
	jr nz,.parse2
	
.parse:

	ld a,(ix)
	inc ix
	or a
	jr z,.done
	cp %11000000
	jp c,.parse1
	and %00111111
	ld e,a
	jp .parse
	
.parse1:
	cp %10000000
	jp c,.parse2

.pitch_table=$+1
	ld bc,0
	and 127
	add a,a
	add a,c
	ld c,a
	jr nc,$+3
	inc b
	ld a,(bc)
	ld (.pitch_set+0),a
	inc bc
	ld a,(bc)
	ld (.pitch_set+1),a
.pitch_set=$+1
	ld sp,0
	jp .parse
	
.parse2:
	ld (.wait),a
	
.play_frame:

	ld bc,3500000/50/80		;1/50 of a second

.sound_loop:

	add hl,sp				;11
	jp c,.rlc				;10
	jr .no_rlc				;12
	
.rlc:
	rlc e					;8
	nop						;4
.no_rlc:

	ld a,e					;4
	and d					;4
	out (#fe),a				;11
	nop						;4
	dec bc					;6
	ld a,b					;4
	or c					;4
	jp nz,.sound_loop		;10=80t

	xor a
	in a,(#fe)
	cpl
	and 31
	jr nz,.done
	
	jp .frame_loop
	
.done:

	xor a
	out (#fe),a
	
.old_sp=$+1
	ld sp,0
	
	ei
	ret
	
	
	
music_title:
	incbin "res/music_title.apl"
music_lose:
	incbin "res/music_lose.apl"
music_win:
	incbin "res/music_win.apl"