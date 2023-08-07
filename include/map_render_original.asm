PRECALC_ROWS
yoff=0
	dup VIEWPORT_TILE_HGT
	db yoff
yoff=yoff+VIEWPORT_TILE_WDT
	edup
			
MAP_CHART
;textoff=TEXT_BUFFER
textoff=TEXT_BUFFER-2
	dup VIEWPORT_TILE_HGT
	dw textoff
textoff=textoff+(SCREEN_WIDTH*3)
	edup
	
	

;This routine checks all units from 0 to 31 and figures out if it should be dislpayed
;on screen, and then grabs that unit's tile and stores it in the MAP_PRECALC array
;so that when the window is drawn, it does not have to search for units during the
;draw, speeding up the display routine.
MAP_PRE_CALCULATE:
	;CLEAR OLD BUFFER
	; LDA	#0
	; LDY	#0
; PREC0	STA MAP_PRECALC,Y
	; INY
	; CPY	#77
	; BNE	PREC0
			ld hl,MAP_PRECALC
			ld bc, MAP_PRECALC_SIZE
			xor a
			call fill_ldir

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
			ld hl,MAP_WINDOW_X
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
			ld hl,MAP_WINDOW_Y
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
			ld hl,MAP_WINDOW_Y
			sub (hl)
			ld d,0
			ld e,a
			ld hl,UNIT_LOC_X
			call offc_abs_x
			ld a,(hl)
			ld hl,MAP_WINDOW_X
			sub (hl)
			ld hl,PRECALC_ROWS
			add hl,de
			add a,(hl)
			ld e,a
			ld hl,UNIT_TILE
			call offc_abs_x
			ld a,(hl)
			cp 130			;is it a bomb
			jr z,PREC6
			cp 134			;is it a magnet
			jr z,PREC6
	
PREC4
	;STA MAP_PRECALC,Y
			ld hl,MAP_PRECALC
			add hl,de
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
			ld hl,MAP_PRECALC
			add hl,de
			ld a,(hl)
			or a
			jr nz,PREC5
			ld hl,UNIT_TILE
			call offc_abs_x
			ld a,(hl)
			jr PREC4
			
			
			
;normal map render with full tiles
; DRAW_MAP_WINDOW:
			; call MAP_PRE_CALCULATE
			; xor a
			; ld (TEMP_X), a
			; ld (TEMP_Y), a
			; ld (REDRAW_WINDOW), a
			; ld (PRECALC_COUNT), a
			
; DM01
			; ld a, (TEMP_X)
			; ld l, a
			; ld a, (MAP_WINDOW_X)
			; add a, l
			; ld l, a

			; ld a, (TEMP_Y)
			; ld h, a
			; ld a, (MAP_WINDOW_Y)
			; add a, h
			; ld h, a

			; sla l
			; srl h
			; rr l
		
			; ld de, MAP
			; add hl, de ; hl = MAP + (128*Y + MAP_WINDOW_Y) + (X + MAP_WINDOW_X)
			; ld (MAP_ADDR), hl

			; ld a, (hl)
			; ld (TILE), a

			; ld a, (TEMP_Y)
			; sla a
			; ld e, a
			; ld d, 0
			; ld hl, MAP_CHART
			; add hl, de
			; ld e, (hl)
			; inc hl
			; ld d, (hl) ; de = screen area

			; ld hl, TEMP_X
			; ld a, (hl)
			; sla a		; x2
			; add a, (hl)	; +1 (x3)
			; ld l, a
			; ld h, 0
			; add hl, de
			; ld (TILE_ADDR), hl

			; call PLOT_TILE
			; ld a, (PRECALC_COUNT)
			; ld e, a
			; ld d, 0
			; ld hl, MAP_PRECALC
			; add hl, de
			; ld a, (hl)
			; and a
			; jr z, DM02
			; ld (TILE), a
			; call PLOT_TRANSPARENT_TILE
; DM02			
			; ld hl, PRECALC_COUNT
			; inc (hl)
			; ld hl, TEMP_X
			; inc (hl)
			; ld a, VIEWPORT_TILE_WDT
			; cp (hl)
			; jr nz, DM01

			; ; Check for cursor
			; ld a, (CURSOR_ON)
			; cp 1
			; jr nz, DM04
			; ld hl, TEMP_Y
			; ld a, (CURSOR_Y)
			; cp (hl)
			; jr nz, DM04
			; call REVERSE_TILE

; DM04
			; xor a
			; ld (TEMP_X), a
			; ld hl, TEMP_Y
			; inc (hl)
			; ld a, VIEWPORT_TILE_HGT
			; cp (hl)
			; jp nz, DM01
			; call draw_buffer
			; ret

DRAW_MAP_WINDOW:
			call MAP_PRE_CALCULATE
			xor a
			ld (TEMP_X), a
			ld (TEMP_Y), a
			ld (REDRAW_WINDOW), a
			ld (PRECALC_COUNT), a
	
DM01
			ld a, (TEMP_X)
			ld l, a
			ld a, (MAP_WINDOW_X)
			add a, l
			ld l, a

			ld a, (TEMP_Y)
			ld h, a
			ld a, (MAP_WINDOW_Y)
			add a, h
			ld h, a

			sla l
			srl h
			rr l

			ld de, MAP
			add hl, de ; hl = MAP + (128*Y + MAP_WINDOW_Y) + (X + MAP_WINDOW_X)
			ld (MAP_ADDR), hl

			ld a, (hl)
			ld (TILE), a

			ld a, (TEMP_Y)
			add a,a
			ld e, a
			ld d, 0
			ld hl, MAP_CHART
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl) ; de = screen area

			ld hl, TEMP_X
			ld a, (hl)
			add a,a		; x2
			add a, (hl)	; +1 (x3)
			ld l, a
			ld h, 0
			add hl, de
			ld (TILE_ADDR), hl

			call PLOT_TILE_EX
			ld a, (PRECALC_COUNT)
			ld e, a
			ld d, 0
			ld hl, MAP_PRECALC
			add hl, de
			ld a, (hl)
			and a
			jr z, DM02
			ld (TILE), a
			call PLOT_TRANSPARENT_TILE_EX
DM02			
			ld hl, PRECALC_COUNT
			inc (hl)
			ld hl, TEMP_X
			inc (hl)
			ld a, VIEWPORT_TILE_WDT
			cp (hl)
			jr nz, DM01

			; Check for cursor
			ld a, (CURSOR_ON)
			and a
			jr z, DM04
			ld hl, TEMP_Y
			ld a, (CURSOR_Y)
			cp (hl)
			jr nz, DM04
			call REVERSE_TILE_EX

DM04
			xor a
			ld (TEMP_X), a
			ld hl, TEMP_Y
			inc (hl)
			ld a, VIEWPORT_TILE_HGT
			cp (hl)
			jp nz, DM01
			
	ifndef PETSCII
	
			call MAP_PRE_CALCULATE
			xor a
			ld (TEMP_X), a
			ld (TEMP_Y), a
			ld (PRECALC_COUNT), a
DM01C
			ld a, (TEMP_X)
			or a
			jr z,DM02C
			cp VIEWPORT_TILE_WDT-1
			jr z,DM02C
			
			ld l, a
			ld a, (MAP_WINDOW_X)
			add a, l
			ld l, a

			ld a, (TEMP_Y)
			ld h, a
			ld a, (MAP_WINDOW_Y)
			add a, h
			ld h, a

			sla l
			srl h
			rr l

			ld de, MAP
			add hl, de ; hl = MAP + (128*Y + MAP_WINDOW_Y) + (X + MAP_WINDOW_X)
			ld (MAP_ADDR), hl

			ld a, (hl)
			ld (TILE), a

			ld a, (TEMP_Y)
			add a,a
			ld e, a
			ld d, 0
			ld hl, MAP_CHART
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl) ; de = screen area

			ld hl, TEMP_X
			ld a, (hl)
			add a,a		; x2
			add a, (hl)	; +1 (x3)
			ld l, a
			ld h, 0
			add hl, de
			ld bc,-TEXT_BUFFER+#5800
			add hl,bc
			ld bc,SCREEN_WIDTH-2
			
			push hl
			
			ld a,(CURSOR_ON)
			or a
			jr z,DM101C
			
			ld hl, TEMP_X
			ld a, (CURSOR_X)
			cp (hl)
			jr nz, DM101C
			
			ld hl, TEMP_Y
			ld a, (CURSOR_Y)
			cp (hl)
			jr nz, DM101C
			
DM100C:
			ld a,(SCREEN_COLOR)
			jr DM102C
DM101C:
			ld a,(SCREEN_COLOR_INV)	
DM102C:
			pop hl
			
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a
			add hl,bc
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a
			add hl,bc
			ld (hl),a
			inc hl
			ld (hl),a
			inc hl
			ld (hl),a
			
DM02C
			ld hl, PRECALC_COUNT
			inc (hl)
			ld hl, TEMP_X
			inc (hl)
			ld a, VIEWPORT_TILE_WDT
			cp (hl)
			jp nz, DM01C
			
			xor a
			ld (TEMP_X), a
			ld hl, TEMP_Y
			inc (hl)
			ld a, VIEWPORT_TILE_HGT
			cp (hl)
			jp nz, DM01C
	endif
	
			jp draw_buffer		;call:ret
			
			
			
; This routine plots a 3x3 tile from the tile database anywhere
; on screen.  But first you must define the tile number in the
; TILE variable, as well as the starting screen address must
; be defined in TILE_ADDR.

PLOT_TILE_LEFT
			ld a, (TILE)
			ld e, a
			ld d, 0
			ld hl, TILE_DATA_TL
			add hl, de
			ex de, hl
			ld hl, (TILE_ADDR)
			ld bc, SCREEN_WIDTH-2+2

			; Draw the top 3 characters

			inc d
			inc hl
			inc d
			inc hl
			ld a, (de)
			ld (hl), a
			inc d

			; Draw the middle 3 characters
			add hl, bc

			inc d
			;inc hl
			inc d
			;inc hl
			ld a, (de)
			ld (hl), a
			inc d

			; Draw the bottom 3 characters
			add hl, bc

			inc d
			;inc hl
			inc d
			;inc hl
			ld a, (de)
			ld (hl), a
	
			ret

PLOT_TILE_RIGHT	
			ld a, (TILE)
			ld e, a
			ld d, 0
			ld hl, TILE_DATA_TL
			add hl, de
			ex de, hl
			ld hl, (TILE_ADDR)
			ld bc, SCREEN_WIDTH-2+2

			; Draw the top 3 characters
			ld a, (de)
			ld (hl), a
			inc d
			;inc hl
			inc d
			;inc hl
			inc d

			; Draw the middle 3 characters
			add hl, bc
			ld a, (de)
			ld (hl), a
			inc d
			;inc hl
			inc d
			;inc hl
			inc d

			; Draw the bottom 3 characters
			add hl, bc
			ld a, (de)
			ld (hl), a
			;inc d
			;inc hl
			;inc d
			;inc hl

			ret
		
PLOT_TILE_EX
			ld a,(TEMP_X)
			or a
			jr z,PLOT_TILE_LEFT
			cp (VIEWPORT_TILE_WDT-1)
			jr z,PLOT_TILE_RIGHT
			;jr PLOT_TILE
			
PLOT_TILE		
			ld a, (TILE)
			ld e, a
			ld d, 0
			ld hl, TILE_DATA_TL
			add hl, de
			ex de, hl
			ld hl, (TILE_ADDR)
			ld bc, SCREEN_WIDTH-2

			; Draw the top 3 characters
			ld a, (de)
			ld (hl), a
			inc d
			inc hl

			ld a, (de)
			ld (hl), a
			inc d
			inc hl

			ld a, (de)
			ld (hl), a
			inc d

			; Draw the middle 3 characters
			add hl, bc
			ld a, (de)
			ld (hl), a
			inc d
			inc hl

			ld a, (de)
			ld (hl), a
			inc d
			inc hl

			ld a, (de)
			ld (hl), a
			inc d

			; Draw the bottom 3 characters
			add hl, bc
			ld a, (de)
			ld (hl), a
			inc d
			inc hl

			ld a, (de)
			ld (hl), a
			inc d
			inc hl

			ld a, (de)
			ld (hl), a

			ret
			
;This routine plots a transparent tile from the tile database
;anywhere on screen.  But first you must define the tile number
;in the TILE variable, as well as the starting screen address must
;be defined in TILE_ADDR.  Also, this routine is slower than the usual
;tile routine, so is only used for sprites.  The ":" character ($3A)
;is not drawn.

PLOT_TRANSPARENT_TILE_EX
			ld a,(TEMP_X)
			or a
			jr z,PLOT_TRANSPARENT_TILE_LEFT
			cp (VIEWPORT_TILE_WDT-1)
			jr z,PLOT_TRANSPARENT_TILE_RIGHT
			jr PLOT_TRANSPARENT_TILE
	
PLOT_TRANSPARENT_TILE_LEFT
			ld a, (TILE)
			ld e, a
			ld d, 0
			ld hl, TILE_DATA_TL
			add hl, de
			ex de, hl
			ld hl, (TILE_ADDR)
			ld bc, SCREEN_WIDTH-2

			; Draw the top 3 characters
			;ld a, (de)
			;cp #3A
			;jr z, PTT01
			;ld (hl), a
;PTT01
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT02
			;ld (hl), a
;PTT02
			inc d
			inc hl

			ld a, (de)
			cp #3A
			jr z, PTT03L
			ld (hl), a
PTT03L
			inc d

			; Draw the middle 3 characters
			add hl, bc
			;ld a, (de)
			;cp #3A
			;jr z, PTT04
			;ld (hl), a
;PTT04
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT05
			;ld (hl), a
;PTT05
			inc d
			inc hl

			ld a, (de)
			cp #3A
			jr z, PTT06L
			ld (hl), a
PTT06L
			inc d

			; Draw the bottom 3 characters
			add hl, bc
			;ld a, (de)
			;cp #3A
			;jr z, PTT07
			;ld (hl), a
;PTT07
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT08
			;ld (hl), a
;PTT08
			inc d
			inc hl

			ld a, (de)
			cp #3A
			ret z
			ld (hl), a
			ret


PLOT_TRANSPARENT_TILE_RIGHT
			ld a, (TILE)
			ld e, a
			ld d, 0
			ld hl, TILE_DATA_TL
			add hl, de
			ex de, hl
			ld hl, (TILE_ADDR)
			ld bc, SCREEN_WIDTH-2

			; Draw the top 3 characters
			ld a, (de)
			cp #3A
			jr z, PTT01R
			ld (hl), a
PTT01R
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT02
			;ld (hl), a
;PTT02
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT03
			;ld (hl), a
;PTT03
			inc d

			; Draw the middle 3 characters
			add hl, bc
			ld a, (de)
			cp #3A
			jr z, PTT04R
			ld (hl), a
PTT04R
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT05
			;ld (hl), a
;PTT05
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT06
			;ld (hl), a
;PTT06
			inc d

			; Draw the bottom 3 characters
			add hl, bc
			ld a, (de)
			cp #3A
			jr z, PTT07R
			ld (hl), a
PTT07R
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;jr z, PTT08
			;ld (hl), a
;PTT08
			inc d
			inc hl

			;ld a, (de)
			;cp #3A
			;ret z
			;ld (hl), a
			ret


PLOT_TRANSPARENT_TILE	
			ld a, (TILE)
			ld e, a
			ld d, 0
			ld hl, TILE_DATA_TL
			add hl, de
			ex de, hl
			ld hl, (TILE_ADDR)
			ld bc, SCREEN_WIDTH-2

			; Draw the top 3 characters
			ld a, (de)
			cp #3A
			jr z, PTT01
			ld (hl), a
PTT01
			inc d
			inc hl

			ld a, (de)
			cp #3A
			jr z, PTT02
			ld (hl), a
PTT02
			inc d
			inc hl

			ld a, (de)
			cp #3A
			jr z, PTT03
			ld (hl), a
PTT03
			inc d

			; Draw the middle 3 characters
			add hl, bc
			ld a, (de)
			cp #3A
			jr z, PTT04
			ld (hl), a
PTT04
			inc d
			inc hl

			ld a, (de)
			cp #3A
			jr z, PTT05
			ld (hl), a
PTT05
			inc d
			inc hl

			ld a, (de)
			cp #3A
			jr z, PTT06
			ld (hl), a
PTT06
			inc d

			; Draw the bottom 3 characters
			add hl, bc
			ld a, (de)
			cp #3A
			jr z, PTT07
			ld (hl), a
PTT07
			inc d
			inc hl

			ld a, (de)
			cp #3A
			jr z, PTT08
			ld (hl), a
PTT08
			inc d
			inc hl

			ld a, (de)
			cp #3A
			ret z
			ld (hl), a
			ret

REVERSE_TILE_LEFT:
	ifndef OPT_USE_ATTR
			ld a, (CURSOR_Y)
			add a,a
			ld e, a
			ld d, 0
			ld hl, MAP_CHART
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl)

			ld hl, CURSOR_X
			ld a, (hl)
			add a,a
			add a, (hl)
			ld l, a
			ld h, 0
			add hl, de
			
			ld bc, SCREEN_WIDTH-2

			inc hl
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
			add hl, bc

			inc hl
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
			add hl, bc

			inc hl
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
	endif
			ret
			
REVERSE_TILE_RIGHT:
	ifndef OPT_USE_ATTR
			ld a, (CURSOR_Y)
			add a,a
			ld e, a
			ld d, 0
			ld hl, MAP_CHART
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl)

			ld hl, CURSOR_X
			ld a, (hl)
			add a,a
			add a, (hl)
			ld l, a
			ld h, 0
			add hl, de

			ld bc, SCREEN_WIDTH-2

			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			inc hl
			add hl, bc

			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			inc hl
			add hl, bc

			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			inc hl
	endif
			ret
		
REVERSE_TILE_EX:
			ld a,(TEMP_X)
			or a
			jr z,REVERSE_TILE_LEFT
			cp (VIEWPORT_TILE_WDT-1)
			jr z,REVERSE_TILE_RIGHT
			;jr REVERSE_TILE
	
REVERSE_TILE:
	ifndef OPT_USE_ATTR
			ld a, (CURSOR_Y)
			add a,a
			ld e, a
			ld d, 0
			ld hl, MAP_CHART
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl)

			ld hl, CURSOR_X
			ld a, (hl)
			add a,a
			add a, (hl)
			ld l, a
			ld h, 0
			add hl, de
			
			ld bc, SCREEN_WIDTH-2

			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
			add hl, bc

			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
			add hl, bc

			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			ld a, (hl)
			xor #80
			ld (hl), a
	endif
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
			STA WATER_TIMER

			LDA TILE_DATA_BR+204
			STA WATER_TEMP1
			LDA TILE_DATA_MM+204
			STA TILE_DATA_BR+204
			STA TILE_DATA_BR+221
			LDA TILE_DATA_TL+204
			STA TILE_DATA_MM+204
			LDA WATER_TEMP1
			STA TILE_DATA_TL+204

			LDA TILE_DATA_BL+204
			STA WATER_TEMP1
			LDA TILE_DATA_MR+204
			STA TILE_DATA_BL+204
			STA TILE_DATA_BL+221
			LDA TILE_DATA_TM+204
			STA TILE_DATA_MR+204
			LDA WATER_TEMP1
			STA TILE_DATA_TM+204
			STA TILE_DATA_TM+221

			LDA TILE_DATA_BM+204
			STA WATER_TEMP1
			LDA TILE_DATA_ML+204
			STA TILE_DATA_BM+204
			STA TILE_DATA_BM+221
			LDA TILE_DATA_TR+204
			STA TILE_DATA_ML+204
			LDA WATER_TEMP1
			STA TILE_DATA_TR+204
			STA TILE_DATA_TR+221

			; trash compactor

			LDA TILE_DATA_TR+148
			STA WATER_TEMP1
			LDA TILE_DATA_TM+148
			STA TILE_DATA_TR+148
			LDA TILE_DATA_TL+148
			STA TILE_DATA_TM+148
			LDA WATER_TEMP1
			STA TILE_DATA_TL+148

			LDA TILE_DATA_MR+148
			STA WATER_TEMP1
			LDA TILE_DATA_MM+148
			STA TILE_DATA_MR+148
			LDA TILE_DATA_ML+148
			STA TILE_DATA_MM+148
			LDA WATER_TEMP1
			STA TILE_DATA_ML+148

			LDA TILE_DATA_BR+148
			STA WATER_TEMP1
			LDA TILE_DATA_BM+148
			STA TILE_DATA_BR+148
			LDA TILE_DATA_BL+148
			STA TILE_DATA_BM+148
			LDA WATER_TEMP1
			STA TILE_DATA_BL+148

	;Now do HVAC fan
			LDA HVAC_STATE
			and a
			jr z, HVAC1
			ld a, #CD
			STA TILE_DATA_MM+196
			STA TILE_DATA_TL+201
			ld a, #CE
			STA TILE_DATA_ML+197
			STA TILE_DATA_TM+200
			ld a, #A0
			STA TILE_DATA_MR+196
			STA TILE_DATA_BM+196
			STA TILE_DATA_BL+197
			STA TILE_DATA_TR+200
			xor a
			STA HVAC_STATE
			jr	HVAC2
HVAC1:
			ld a, #A0
			STA TILE_DATA_MM+196
			STA TILE_DATA_TL+201
			STA TILE_DATA_ML+197
			STA TILE_DATA_TM+200
			ld a, #C2
			STA TILE_DATA_MR+196
			STA TILE_DATA_TR+200
			ld a, #C0
			STA TILE_DATA_BM+196	
			STA TILE_DATA_BL+197
			ld a, 1
			STA HVAC_STATE
HVAC2:
		;now do cinema screen tiles
		;FIRST COPY OLD LETTERS TO THE LEFT.

	LDA TILE_DATA_MR+20	;#2
	STA TILE_DATA_MM+20	;#1
	LDA TILE_DATA_ML+21	;#3
	STA TILE_DATA_MR+20	;#2
	LDA TILE_DATA_MM+21	;#4
	STA TILE_DATA_ML+21	;#3
	LDA TILE_DATA_MR+21	;#5
	STA TILE_DATA_MM+21	;#4
	LDA TILE_DATA_ML+22	;#6
	STA TILE_DATA_MR+21	;#5
	;now insert new character.
	;LDY	CINEMA_STATE
	;LDA	CINEMA_MESSAGE,Y
	;STA	TILE_DATA_ML+22	;#6
	;INC	CINEMA_STATE
	;LDA	CINEMA_STATE
	;CMP	#197
	;BNE	CINE2
	;LDA	#0
	;STA	CINEMA_STATE

	ld a, (CINEMA_STATE)
	ld e, a
	ld d, 0
	LDA_HL_X CINEMA_MESSAGE
	call pet_char
	STA TILE_DATA_ML+22	;#6
	ld hl, CINEMA_STATE
	inc (hl)
	ld a, (hl)
	cp 197
	jr nz, CINE2
	ld (hl), 0

CINE2:	;Now animate light on server computers
	;LDA	TILE_DATA_MR+143
	;CMP	#$D7
	;BNE	CINE3
	;LDA	#$D1
	;JMP	CINE4
	LDA	TILE_DATA_MR+143
	cp #D7
	jr nz, CINE3
	ld a, #D1
	jr CINE4
CINE3:	
	;LDA	#$D7
	ld a, #D7
CINE4:	
	;STA	TILE_DATA_MR+143
	STA	TILE_DATA_MR+143


			ld a, 1
			ld (REDRAW_WINDOW), a
			ret
CINEMA_MESSAGE:
	db "coming soon: space balls 2 - the search for more money, "
	db "attack of the paperclips: clippy's revenge, "
	db "it came from planet earth, "
	db "rocky 5000, all my circuits the movie, "
	db "conan the librarian, and more! " 

CINEMA_STATE	db 0	
			
			
			
; Render text buffer to the screen
draw_buffer:

			ld de,#4000
render_font=$+1
			ld l,font_pixels/256
			ld h,7
			exx
			ld de,TEXT_BUFFER
			ld hl,TEXT_BUFFER_PREV
			
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

			dup 8
			ld a,(bc)
			ld (de),a
			inc b
			inc d
			edup
			org $-2
			ld a,d
			sub h
			ld d,a
			
			exx
1

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
			
			dup 8
			ld a,(bc)
			ld (de),a
			inc b
			inc d
			edup	
			org $-2
			ld a,d
			sub h
			ld d,a

			exx
			
2

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
			ld hl,#5800
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
			ret
