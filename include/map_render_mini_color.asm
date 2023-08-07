PRECALC_ROWS
yoff=0
	dup VIEWPORT_TILE_HGT
	dw yoff
;yoff=yoff+VIEWPORT_TILE_WDT
yoff=yoff+SCREEN_WIDTH
	edup

	
MAP_WINDOW_X_CLIP:	db 0
MAP_WINDOW_Y_CLIP:	db 0


		
;This routine checks all units from 0 to 31 and figures out if it should be dislpayed
;on screen, and then grabs that unit's tile and stores it in the MAP_PRECALC array
;so that when the window is drawn, it does not have to search for units during the
;draw, speeding up the display routine.
MAP_PRE_CALCULATE:

	;clip map view
	
	ld a, (MAP_WINDOW_X)
	cp -VIEWPORT_TILE_WDT
	jr c,.clip_x_right
	xor a
	jr .clip_x_done
.clip_x_right
	cp MAP_WIDTH-VIEWPORT_TILE_WDT
	jr c,.clip_x_done
	ld a,MAP_WIDTH-VIEWPORT_TILE_WDT
.clip_x_done
	ld (MAP_WINDOW_X_CLIP),a
	
	ld a, (MAP_WINDOW_Y)
	cp -VIEWPORT_TILE_HGT
	jr c,.clip_y_bottom
	xor a
	jr .clip_y_done
.clip_y_bottom
	cp MAP_HEIGHT-VIEWPORT_TILE_HGT
	jr c,.clip_y_done
	ld a,MAP_HEIGHT-VIEWPORT_TILE_HGT
.clip_y_done
	ld (MAP_WINDOW_Y_CLIP),a
	
	ret
	
	
MAP_RENDER_UNITS:
	
	;CLEAR OLD BUFFER
	; LDA	#0
	; LDY	#0
; PREC0	STA MAP_PRECALC,Y
	; INY
	; CPY	#77
	; BNE	PREC0
			; ld hl,MAP_PRECALC
			; ld bc, MAP_PRECALC_SIZE
			; xor a
			; call fill_ldir
			; LDX	#0
			; JMP	PREC2	;skip the check for unit zero, always draw it.
			ld c,0
			jr PREC2
	
PREC1
	;CHECK THAT UNIT EXISTS
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	PREC5
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,PREC5
	
	;CHECK HORIZONTAL POSITION
	; LDA	UNIT_LOC_X,X
	; CMP	MAP_WINDOW_X
	; BCC	PREC5
	; LDA	MAP_WINDOW_X
	; CLC
	; ADC	#10
	; CMP	UNIT_LOC_X,X
	; BCC	PREC5
			ld hl,UNIT_LOC_X
			call offc_abs_x
			ex de,hl
			ld a,(de)
			ld hl,MAP_WINDOW_X_CLIP
			cp (hl)
			jr c,PREC5
			ld a,(hl)
			add a,(VIEWPORT_TILE_WDT-1)
			ex de,hl
			cp (hl)
			jr c,PREC5

	;NOW CHECK VERTICAL
	; LDA	UNIT_LOC_Y,X
	; CMP	MAP_WINDOW_Y
	; BCC	PREC5
	; LDA	MAP_WINDOW_Y
	; CLC
	; ADC	#6
	; CMP	UNIT_LOC_Y,X
	; BCC	PREC5
			ld hl,UNIT_LOC_Y
			call offc_abs_x
			ex de,hl
			ld a,(de)
			ld hl,MAP_WINDOW_Y_CLIP
			cp (hl)
			jr c,PREC5
			ld a,(hl)
			add a,(VIEWPORT_TILE_HGT-1)
			ex de,hl
			cp (hl)
			jr c,PREC5

	;Unit found in map window, now add that unit's
	;tile to the precalc map.
PREC2
	; LDA	UNIT_LOC_Y,X
	; SEC
	; SBC	MAP_WINDOW_Y
	; TAY
	; LDA	UNIT_LOC_X,X
	; SEC
	; SBC	MAP_WINDOW_X
	; CLC
	; ADC	PRECALC_ROWS,Y	
	; TAY
	; LDA	UNIT_TILE,X
	; CMP	#130	;is it a bomb
	; BEQ	PREC6
	; CMP	#134	;is it a magnet
	; BEQ	PREC6
			ld hl,UNIT_LOC_Y
			call offc_abs_x
			ld a,(hl)
			ld hl,MAP_WINDOW_Y_CLIP
			sub (hl)
			ld d,0
			ld e,a
			ld hl,UNIT_LOC_X
			call offc_abs_x
			ld a,(hl)
			ld hl,MAP_WINDOW_X_CLIP
			sub (hl)
			ld hl,PRECALC_ROWS
			add hl,de
			add hl,de
			add a,(hl)
			ld e,a
			inc hl
			ld d,(hl)
			jr nc,$+3
			inc d
			ld hl,UNIT_TILE
			call offc_abs_x
			ld a,(hl)
			cp 130			;is it a bomb
			jr z,PREC6
			cp 134			;is it a magnet
			jr z,PREC6
	
PREC4
	;STA MAP_PRECALC,Y
			ld hl,TEXT_BUFFER;MAP_PRECALC
			add hl,de
			ld (hl),a
			ld hl,TEXT_ATTR
			add hl,de
			ld d,tileset_color_data/256
			ld e,a
			ld a,(de)
			ld (hl),a
	
PREC5
	;continue search
	; INX	
	; CPX	#32
	; BNE	PREC1
	; RTS
			inc c
			ld a,c
			cp 32
			jr nz,PREC1
			ret
	
PREC6

	;What to do in case of bomb or magnet that should
	;go underneath the unit or robot.
	; LDA	MAP_PRECALC,Y
	; CMP	#0
	; BNE	PREC5
	; LDA	UNIT_TILE,X
	; JMP	PREC4	
			ld hl,TEXT_BUFFER;MAP_PRECALC
			add hl,de
			ld l,(hl)
			ld h,tile_flag_table/256
			ld a,(hl)
			and 2
			jr nz,PREC5
			ld hl,UNIT_TILE
			call offc_abs_x
			ld a,(hl)
			jr PREC4
			
				
		
DRAW_MAP_WINDOW:
	
	ld a,font_pixels/256
	ld (render_font),a
	
	call draw_buffer
	
	call MAP_PRE_CALCULATE
	xor a
	ld (REDRAW_WINDOW), a
	ld (PRECALC_COUNT), a
	
	;render map and attributes all at once
			
	ld a,(MAP_WINDOW_X_CLIP)
	ld l,a
	ld a,(MAP_WINDOW_Y_CLIP)
	ld h,a

	sla l
	srl h
	rr l

	ld de,MAP
	add hl,de
	ex de,hl
	
	exx
	ld hl,TEXT_ATTR
	ld d,tileset_color_data/256
	exx

	ld hl,TEXT_BUFFER
	;ld ix,MAP_PRECALC
	ld b,VIEWPORT_TILE_HGT
	
DM01:

	push bc

	ld b,VIEWPORT_TILE_WDT
	
DM02:

	;ld a,(ix)
	;or a
	;jr nz,DM03
	ld a,(de)
;DM03:
	ld (hl),a
	
	inc e
	inc l
	;inc ix
	
	exx
	ld e,a
	ld a,(de)
	ld (hl),a
	inc l
	exx

	djnz DM02
	
	ex de,hl
	dec l
	ld bc,MAP_WIDTH-VIEWPORT_TILE_WDT+1
	add hl,bc
	ex de,hl
	
	ld bc,SCREEN_WIDTH-VIEWPORT_TILE_WDT
	add hl,bc

	exx
	ld bc,SCREEN_WIDTH-VIEWPORT_TILE_WDT
	add hl,bc
	exx

	pop bc
	djnz DM01
		
		
;render units over the map

	call MAP_RENDER_UNITS
	
;project cursor tile if enabled
	
	ld hl,TEXT_ATTR
	
	ld a,(CURSOR_ON)
	or a
	jr z,.nocursor
	
	ld a,(MAP_WINDOW_Y)
	ld c,a
	ld a,(MAP_WINDOW_Y_CLIP)
	sub c
	ld c,a
	ld a,(CURSOR_Y)
	sub c
	or a
	jr z,.nomul
	
	ld de,32
	ld b,a
	
.mul
	add hl,de
	djnz .mul
	
.nomul
	
	ld a,(MAP_WINDOW_X)
	ld c,a
	ld a,(MAP_WINDOW_X_CLIP)
	sub c
	ld c,a
	ld a,(CURSOR_X)
	sub c

	ld d,0
	ld e,a
	add hl,de
	
	ld a,(SCREEN_COLOR)
	ld (hl),a

.nocursor


	call force_anim_update
	
	
	ld a,TILE_DATA_TL/256
	ld (render_font),a
	
	call draw_buffer
	
	ld a,font_pixels/256
	ld (render_font),a
	
	ret



;This routine plots a transparent tile, but it can be ignored, as the viewport redraw will show up the reversed tile anyways

REVERSE_TILE:
	ret
	
	
	
ANIMATE_TILES:
			ld a, (ANIMATE)
			cp 1
			jr z, AW00
			ret
AW00
			ld hl, WATER_TIMER
			inc (hl)
			ld a, (hl)
			cp 20
			ret nz

			xor a
			ld (WATER_TIMER),a

	ld hl,WATER_TEMP1
	ld a,(hl)
	xor 1
	and a
	ld (hl),a
	jr z,.frame1

.frame0:

	; water
	ld hl,anim_tiles+(0+0)*8
	ld de,TILE_DATA_TL+204
	call copy_anim_tile
		
	; trash
	ld hl,anim_tiles+(0+5)*8
	ld de,TILE_DATA_TL+148
	call copy_anim_tile
	
	jr .frame2

.frame1:

	; water
	ld hl,anim_tiles+(8+0)*8
	ld de,TILE_DATA_TL+204
	call copy_anim_tile
		
	; trash
	ld hl,anim_tiles+(8+5)*8
	ld de,TILE_DATA_TL+148
	call copy_anim_tile
	
.frame2:

	; fan
	
	ld a,(HVAC_STATE)
	and a
	jr z,HVAC1
	xor a
	ld (HVAC_STATE),a

	ld hl,anim_tiles+(0+1)*8
	ld de,TILE_DATA_TL+196
	call copy_anim_tile
	ld hl,anim_tiles+(0+2)*8
	ld de,TILE_DATA_TL+197
	call copy_anim_tile
	ld hl,anim_tiles+(0+3)*8
	ld de,TILE_DATA_TL+200
	call copy_anim_tile
	ld hl,anim_tiles+(0+4)*8
	ld de,TILE_DATA_TL+201
	call copy_anim_tile
	
	jr	HVAC2
	
HVAC1:

	ld hl,anim_tiles+(8+1)*8
	ld de,TILE_DATA_TL+196
	call copy_anim_tile
	ld hl,anim_tiles+(8+2)*8
	ld de,TILE_DATA_TL+197
	call copy_anim_tile
	ld hl,anim_tiles+(8+3)*8
	ld de,TILE_DATA_TL+200
	call copy_anim_tile
	ld hl,anim_tiles+(8+4)*8
	ld de,TILE_DATA_TL+201
	call copy_anim_tile
	
	ld a, 1
	ld (HVAC_STATE),a
	
HVAC2:
	
	ld a,(SERVER_STATE)
	or a
	jr z,SERV1
	ld hl,anim_tiles+(0+6)*8
	ld de,TILE_DATA_TL+143
	call copy_anim_tile
	xor a
	jr SERV2
SERV1:
	ld hl,anim_tiles+(8+6)*8
	ld de,TILE_DATA_TL+143
	call copy_anim_tile
	ld a,1
SERV2:
	ld (SERVER_STATE),a
	
	ld a, 1
	ld (REDRAW_WINDOW), a
	ret
	

SERVER_STATE:	db 0	
		
		
copy_anim_tile:
	ld b,8
.l0:
	ld a,(hl)
	xor #ff
	ld (de),a
	inc hl
	inc d
	djnz .l0
	ret
	
	

force_anim_update:

	ld hl,TEXT_BUFFER_PREV
	ld d,tile_flag_table/256
	ld bc,VIEWPORT_TILE_HGT*256+1
.l0
	push bc
	dup VIEWPORT_TILE_WDT

	ld e,(hl)
	ld a,(de)
	and c
	jp z,$+4
	ld (hl),a

	inc l
	edup
	ld bc,SCREEN_WIDTH-VIEWPORT_TILE_WDT
	add hl,bc
	pop bc
	dec b
	jp nz,.l0
	ret
	
	

anim_tiles:
	incbin "..\res\small_tiles_anim.bin"
		
	
; Render text buffer to the screen
draw_buffer:

			ld de,#4000
render_font=$+1
			ld l,font_pixels/256
			exx
			ld de,TEXT_BUFFER
			ld hl,TEXT_BUFFER_PREV
			
			ld ix,TEXT_ATTR
			ld iy,#5800
			
			ld a,24
	
render_loop_0:

			exa
			exx
			push de
			exx

			dup 16

			ld a,(de)
			cp (hl)
			jr z,1F
			ld (hl),a
			
			exx
			ld b,l
			ld c,a

			ld h,d
			dup 8
			ld a,(bc)
			ld (de),a
			inc b
			inc d
			edup
			org $-2
			ld d,h
			
			exx
1

	ld a,(ix)		;always apply color
	ld (iy),a
	inc ix
	inc iy

			inc l
			inc e
			exx
			inc e
			exx

			ld a,(de)
			cp (hl)
			jr z,2F
			ld (hl),a

			exx
			ld b,l
			ld c,a
			
			ld h,d
			dup 8
			ld a,(bc)
			ld (de),a
			inc b
			inc d
			edup	
			org $-2
			ld d,h
			
			exx
			
2

	ld a,(ix)		;color
	ld (iy),a
	inc ix
	inc iy

			inc l
			inc e
			exx
			inc e
			exx

			edup

			org $-5
			inc hl
			inc de

			exx
			pop de
			
down_de:
			ld a,e
			sub #e0
			ld e,a
			sbc a,a
			and #f8
			add a,d
			add a,8
			ld d,a
			exx
			
			exa
			dec a
			jp nz,render_loop_0

			ret



set_attributes:

			ld a,(SCREEN_COLOR_INV)
			ld e,a
			ld a,(SCREEN_COLOR)
			ld d,a
			ld hl,TEXT_ATTR
			ld bc,#300
			halt
.l0
			ld a,(hl)
			and #07
			ld a,e
			jr z,$+3
			ld a,d
			ld (hl),a
			inc hl
			dec bc
			ld a,b
			or c
			jr nz,.l0
			
			ld hl,TEXT_BUFFER_PREV
			ld de,TEXT_BUFFER_PREV+1
			ld bc,#2ff
			ld (hl),c
			ldir

			ret