			device zxspectrum128

; -----------------------------------------------------------------------------
;			TODO
; -----------------------------------------------------------------------------
; 	1. Use of inventory items fix
;		- magnet	fixed
;		- medkit 	fixed
;		- bomb		fixed
;		- emp		coverage area fix needed
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
;			MEMORY MAP
; -----------------------------------------------------------------------------
;		#6200	code, variables, arrays
;		#B000	text buffer (shadow screen), 1000 bytes
; pageC0	#C000	tilemap buffer 
; page6		#D000	unpacked game map, 8962 bytes
; -----------------------------------------------------------------------------


			org #6200

Vid_page		equ	#80
tiles_page		equ	4
sprites_page		equ	6
TILES0_PAGE		equ	#50
TILES1_PAGE		equ	#50
Sprites_h_page		equ	#58
PAGE_TILEMAP		equ	#c0
PAGE_PETROBOTS		equ	#6

; -----------------------------------------------------------------------------
;                  TEMP MACRO
; -----------------------------------------------------------------------------

		; IN:
		; DE = x
		; a = value
		macro STA_HL_X _abs
			ld hl, _abs
			add hl, de
			ld (hl), a
		endm

		; IN:
		; DE = x
		; OUT:
		; a = (hl+de)
		macro LDA_HL_X _abs
			ld hl, _abs
			add hl, de
			ld a, (hl)
		endm

		macro LDA addr?
			ld a, (addr?)
		endm

		macro STA addr?
			ld (addr?), a
		endm

; -----------------------------------------------------------------------------
;                  PETSCII ROBOTS VARIABLES
; -----------------------------------------------------------------------------

KEY_MOVE_UP		equ 0
KEY_MOVE_DOWN		equ 1
KEY_MOVE_LEFT		equ 2
KEY_MOVE_RIGHT		equ 3
KEY_FIRE_UP		equ 4
KEY_FIRE_DOWN		equ 5
KEY_FIRE_LEFT		equ 6
KEY_FIRE_RIGHT		equ 7
KEY_CYCLE_WEAPONS	equ 8
KEY_CYCLE_ITEMS		equ 9
KEY_USE			equ 10
KEY_SEARCH		equ 11
KEY_MOVE		equ 12
KEY_PAUSE		equ 13

KBD_UP			equ 55
KBD_DOWN		equ 54
KBD_SPACE		equ 32
KBD_ENTER		equ 13

	; Items
ID_NULL			equ 0
ID_BOMB			equ 1
ID_EMP			equ 2
ID_MEDKIT		equ 3
ID_MAGNET		equ 4
EOF_ITEMS		equ 5

	; Weapons
ID_PISTOL		equ 1
ID_PLASMA_GUN		equ 2


	; tiles
ID_FLOOR		equ 9
ID_BIG_CRATE		equ 41
ID_SMALL_CRATE		equ 45
ID_CANNISTER		equ 131	
ID_PI_CRATE		equ 199
ID_WATER		equ 204

	; Objects
ID_KEY			equ 128
ID_KEY_SPADE		equ 1
ID_KEY_HEART		equ 2
ID_KEY_STAR		equ 4
ID_HIDDEN_BOMB		equ 129
ID_HIDDEN_EMP		equ 130
ID_HIDDEN_PISTOL	equ 131
ID_HIDDEN_PLASMA	equ 132
ID_HIDDEN_MEDKIT	equ 133
ID_HIDDEN_MAGNET	equ 134

	; Sounds
SND_EXPLOSION		equ 0
SND_SMALL_EXPLOSION	equ 1
SND_USE_MEDKIT		equ 2
SND_USE_EMP			equ 3
SND_HAYWIRE			equ 4
SND_EVILBOT			equ 5
SND_MOVE_OBJECT		equ 6
SND_ELECTRIC		equ 7		;this is player hit actually
SND_PLASMAGUN		equ 8
SND_PISTOL			equ 9
SND_ITEM_FOUND		equ 10
SND_ERROR			equ 11
SND_CHANGE_WEAPON	equ 12
SND_CHANGE_ITEM		equ 13
SND_DOOR			equ 14
SND_MENU_CURSOR		equ 15
SND_USER_ACTION		equ 16
SND_ELEVATOR		equ 17
SND_MENU_SELECT		equ 18
SND_STEP_L			equ 19
SND_STEP_R			equ 20
SND_WALL_HIT		equ 21
SND_ROBOT_HIT		equ 22
SND_ROBOT_DOWN		equ 23
SND_PLAYER_DOWN		equ 24
SND_TITLE_MUSIC		equ 25
SND_WIN_MUSIC		equ 26
SND_LOSE_MUSIC		equ 27

TEXT_BUFFER		equ #B000
MUSIC_ADDR		equ #4000 ; temporary

			; Start of map ==>
MAP_BEGIN		equ #D000
FILE_LENGTH		equ MAP_BEGIN
UNIT_TYPE		equ FILE_LENGTH + 2
UNIT_LOC_X		equ UNIT_TYPE + 64
UNIT_LOC_Y		equ UNIT_LOC_X + 64
UNIT_A			equ UNIT_LOC_Y + 64
UNIT_B			equ UNIT_A + 64
UNIT_C			equ UNIT_B + 64
UNIT_D			equ UNIT_C + 64
UNIT_HEALTH		equ UNIT_D + 64
MAP			equ UNIT_HEALTH + 64 + (64 * 4)
MAP_END			equ MAP + (1024*8)
			; <== end of map.


start			
			di
			call init_tsconf

			;im 0
			;ei

			;call TILE_LOAD_ROUTINE

			call SET_CONTROLS
			jp INTRO_SCREEN
INIT_GAME
			xor a
			ld (SCREEN_SHAKE), a
			call RESET_KEYS_AMMO
			call DISPLAY_GAME_SCREEN
			call DISPLAY_LOAD_MESSAGE2
			call MAP_LOAD_ROUTINE
			call SET_DIFF_LEVEL
			call ANIMATE_PLAYER
			call CALCULATE_AND_REDRAW

			call DRAW_MAP_WINDOW
			call DISPLAY_PLAYER_HEALTH

			;call CHEATER
			;call DISPLAY_ITEM
			
			call DISPLAY_KEYS
			call DISPLAY_WEAPON
			ld a, 1
			ld (UNIT_TYPE), a
			ld (ANIMATE), a

			call SET_INITIAL_TIMERS
			call PRINT_INTRO_MESSAGE
			ld a, 30
			ld (KEYTIMER), a

MAIN_GAME_LOOP
			halt
			call PET_SCREEN_SHAKE
			call BACKGROUND_TASKS

			ld a, (UNIT_TYPE)
			cp 1 ; Is player unit alive?
			jr z, KY01
			jp GAME_OVER
KY01
			call getin
			and a
			jr z, MAIN_GAME_LOOP
			
			ld hl, KEYTIMER
			ld (hl), 5

			ld hl, TECLADO
CHECK_KBD_UP
			cp (hl)
			jr nz, CHECK_KBD_DOWN
			xor a
			ld (UNIT), a
			ld a, %00000001
			ld (MOVE_TYPE), a
			call REQUEST_WALK_UP
			jp AFTER_MOVE

CHECK_KBD_DOWN
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_LEFT
			xor a
			ld (UNIT), a
			ld a, %00000001
			ld (MOVE_TYPE), a
			call REQUEST_WALK_DOWN
			jp AFTER_MOVE
CHECK_KBD_LEFT
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_RIGHT
			xor a
			ld (UNIT), a
			ld a, %00000001
			ld (MOVE_TYPE), a
			call REQUEST_WALK_LEFT
			jp AFTER_MOVE
CHECK_KBD_RIGHT
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_FIRE_UP
			xor a
			ld (UNIT), a
			ld a, %00000001
			ld (MOVE_TYPE), a
			call REQUEST_WALK_RIGHT
			jp AFTER_MOVE
CHECK_KBD_FIRE_UP
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_FIRE_DOWN
			call FIRE_UP
			ld a, 20
			ld (KEYTIMER), a
			jp MAIN_GAME_LOOP
CHECK_KBD_FIRE_DOWN
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_FIRE_LEFT
			call FIRE_DOWN
			ld a, 20
			ld (KEYTIMER), a
			jp MAIN_GAME_LOOP
CHECK_KBD_FIRE_LEFT
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_FIRE_RIGHT
			call FIRE_LEFT
			ld a, 20
			ld (KEYTIMER), a
			jp MAIN_GAME_LOOP
CHECK_KBD_FIRE_RIGHT
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_CYCLE_WEAPONS
			call FIRE_RIGHT
			ld a, 20
			ld (KEYTIMER), a
			jp MAIN_GAME_LOOP
CHECK_KBD_CYCLE_WEAPONS
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_CYCLE_ITEMS
			call CYCLE_WEAPON
			call CLEAR_KEY_BUFFER
			jp MAIN_GAME_LOOP
CHECK_KBD_CYCLE_ITEMS
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_USE
			call CYCLE_ITEM
			call CLEAR_KEY_BUFFER
			jp MAIN_GAME_LOOP
CHECK_KBD_USE
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_SEARCH
			call USE_ITEM
			call CLEAR_KEY_BUFFER
			jp MAIN_GAME_LOOP
CHECK_KBD_SEARCH
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_MOVE
			call SEARCH_OBJECT
			call CLEAR_KEY_BUFFER
			jp MAIN_GAME_LOOP
CHECK_KBD_MOVE
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_PAUSE
			call MOVE_OBJECT
			call CLEAR_KEY_BUFFER
			jp MAIN_GAME_LOOP
CHECK_KBD_PAUSE
			inc hl
			cp (hl)
			jr nz, CHECK_KBD_MUSIC
			jp PAUSE_GAME
CHECK_KBD_MUSIC
			inc hl
			cp (hl)
			jp nz, MAIN_GAME_LOOP
			call TOGGLE_MUSIC
			call CLEAR_KEY_BUFFER
			jp MAIN_GAME_LOOP

PET_SCREEN_SHAKE:
			ld a, (BGTIMER1)
			or a
			jr nz, PSS4
			ret
PSS4:
			ld hl, SELECT_TIMEOUT
			ld a, (hl)
			and a
			jr z, PSS4A
			dec (hl)
PSS4A			jp PET_BORDER_FLASH

TOGGLE_MUSIC
			ret

GAME_OVER
			; stop game clock
			xor a
			ld (CLOCK_ACTIVE), a
			; disable music

			; TODO music routines
		        
			; Did player die or win?

			ld a, (UNIT_TYPE)
			and a
			jr nz, GMO0
			ld a, 111 ;dead player tile
			ld (UNIT_TILE), a
			ld a, 100
			ld (KEYTIMER), a
GMO0
			call PET_SCREEN_SHAKE
			call BACKGROUND_TASKS
			ld a, (KEYTIMER)
			and a
			jr nz, GMO0

			ld hl, GAMEOVER1
			ld de, TEXT_BUFFER+#173
			ld bc, 11
			ldir

			ld hl, GAMEOVER2
			ld de, TEXT_BUFFER+#19B
			ld bc, 11
			ldir
			
			ld hl, GAMEOVER3
			ld de, TEXT_BUFFER+#1C3
			ld bc, 11
			ldir
			
			call draw_buffer

			ld hl, KEYTIMER
			ld (hl), 100
GMO2
			ld a, (hl)
			and a
			jr nz, GMO2
GMO3
			call getin
			and a
			jr z, GMO3

GMO4
			; TODO music off
			call DISPLAY_ENDGAME_SCREEN
			call DISPLAY_WIN_LOSE
			call draw_buffer
GMO5
			halt
			call getin
			and a
			jr z, GMO5
			jp INTRO_SCREEN

DISPLAY_ENDGAME_SCREEN
			ld hl, SCR_ENDGAME
			ld de, TEXT_BUFFER
			call DecompressApLib
			call CALC_MAP_NAME
			ld de, TEXT_BUFFER+#12E
			ld b, 16
.DES0			ld a, (hl)
			call pet_char
			ld (de), a
			inc hl
			inc de
			djnz .DES0

			ld a, (HOURS)
			ld hl, TEXT_BUFFER+#17D
			call DECWRITE
			ld a, (MINUTES)
			ld hl, TEXT_BUFFER+#180
			call DECWRITE
			ld a, (SECONDS)
			ld hl, TEXT_BUFFER+#183
			call DECWRITE

			ld a, " "	; space
			ld (TEXT_BUFFER+#17D), a
			ld a, ":"
			ld (TEXT_BUFFER+#180), a
			ld (TEXT_BUFFER+#183), a

			; count robots remaining

			ld hl, UNIT_TYPE+1
			ld b, 27
			ld c, 0
.DES1
			ld a, (hl)
			and a
			jr z, .DES2
			inc c
.DES2
			inc hl
			djnz .DES1
			ld a, c
			ld hl, TEXT_BUFFER+#1CE
			call DECWRITE

			; Count secrets remaining

			ld de, 48
			ld c, 0
.DES3
			LDA_HL_X UNIT_TYPE
			and a
			jr z, .DES4
			inc c
.DES4
			inc de
			ld a, 64
			cp e
			jr nz, .DES3
			ld a, c
			ld hl, TEXT_BUFFER+#21E
			call DECWRITE

			; display difficulty level

			ld a, (DIFF_LEVEL)
			ld e, a
			ld d, 0
			ld hl, DIFF_LEVEL_LEN
			add hl, de
			ld a, (hl)
			ld e, a
			ld hl, DIFF_LEVEL_WORDS
			add hl, de
			ld de, TEXT_BUFFER+#26E
.DES5
			ld a, (hl)
			and a
			ret z
			call pet_char
			ld (de), a
			inc hl
			inc de
			jr .DES5
			ret

DIFF_LEVEL_WORDS
			db "easy",0,"normal",0,"hard",0
DIFF_LEVEL_LEN
			db 0,5,12

;So, it doesn't really flash the PET border, instead it
;flashes the health screen.
PET_BORDER_FLASH:
			ld a, (BORDER_FLASH)
			and a
			jr nz, PBF10
			ld a, (FLASH_STATE)
			and a
			ret z
			jr PBF20
PBF10:
			ld a, (FLASH_STATE)
			cp 1
			ret z

			ld hl, OUCH1
			ld de, TEXT_BUFFER+#2F2
			ld bc, 6
			ldir

			ld hl, OUCH2
			ld de, TEXT_BUFFER+#31A
			ld bc, 6
			ldir

			ld hl, OUCH3
			ld de, TEXT_BUFFER+#342
			ld bc, 6
			ldir

			ld a, 1
			ld (FLASH_STATE), a
			ret

PBF20:
			ld hl, TEXT_BUFFER+#2F2
			ld de, TEXT_BUFFER+#2F2+1
			ld (hl), 32
			ld bc, 5
			ldir 
			ld hl, TEXT_BUFFER+#31A
			ld de, TEXT_BUFFER+#31A+1
			ld (hl), 32
			ld bc, 5
			ldir 
			ld hl, TEXT_BUFFER+#342
			ld de, TEXT_BUFFER+#342+1
			ld (hl), 32
			ld bc, 5
			ldir 
			ld a, 0
			ld (FLASH_STATE), a
			ret

FLASH_STATE		db 00
BORDER_FLASH		db 00
OUCH1			db #CD,#A0,#A0,#A0,#A0,#CE
OUCH2			db #A0,#8F,#95,#83,#88,#A0
OUCH3			db #CE,#A0,#A0,#A0,#A0,#CD

DISPLAY_WIN_LOSE
			call STOP_SONG
			ld a, (UNIT_TYPE)
			and a
			jr z, DISPLAY_LOSE

			; Win message
			ld hl, WIN_MSG
			ld de, TEXT_BUFFER+#88
			ld b, 8
			call DISPLAY_WIN_LOSE00
			ld a, SND_WIN_MUSIC	; Win music
			call PLAY_SOUND
			ret
DISPLAY_LOSE
			; Lose message
			ld hl, LOS_MSG
			ld de, TEXT_BUFFER+#88
			ld b, 9
			call DISPLAY_WIN_LOSE00
			ld a, SND_LOSE_MUSIC	; Lose music
			call PLAY_SOUND
			ret
DISPLAY_WIN_LOSE00
			ld a, (hl)
			call pet_char
			ld (de), a
			inc hl
			inc de
			djnz DISPLAY_WIN_LOSE00
			ret
WIN_MSG			db "you win!"
LOS_MSG			db "you lose!"

PLAY_SOUND:
			ld hl,music_title
			cp SND_TITLE_MUSIC
			jr z,play_music_all
			ld hl,music_win
			cp SND_WIN_MUSIC
			jr z,play_music_all
			ld hl,music_lose
			cp SND_LOSE_MUSIC
			jr nc,play_music_all
			jp play_sound
play_music_all:
		;ret
			ld de,MUSIC_ADDR ;beeper music needs a ~6K buffer
			push de
			call DecompressApLib
			pop hl
			jp play_music
			
STOP_SONG
			ret

KEY_REPEAT
			ret


AFTER_MOVE
			ld a, (MOVE_RESULT)
			or a
			jr z, AM01
			call ANIMATE_PLAYER
			call CALCULATE_AND_REDRAW
			
	;sh8bit -- would be nice to reset the alternate_steps to 0 when the player does not move for a few frames
alternate_steps=$+1
	ld a,0
	inc a
	and 7
	ld (alternate_steps),a
	ld c,SND_STEP_L
	;or a
	jr z,play_step_sound
	ld c,SND_STEP_R
	cp 4
	jr z,play_step_sound
	ld c,0
play_step_sound:
	ld a,c
	or a
	call nz,PLAY_SOUND

AM01
			ld a, (KEY_FAST)
			and a
			jr nz, KEYR3
			ld a, 13
			ld (KEYTIMER), a
			ld hl, KEY_FAST
			inc (hl)
KEYR4
			jp MAIN_GAME_LOOP
KEYR3
			ld a, 6
			ld (KEYTIMER), a
			jp MAIN_GAME_LOOP

CYCLE_WEAPON:
			ld a, SND_CHANGE_WEAPON
			call PLAY_SOUND
			ld a, (SELECT_TIMEOUT)
			and a
			jr z, CYWE0
			ret
CYWE0
			ld a, 3
			ld (SELECT_TIMEOUT), a
			ld a, 20
			ld (KEYTIMER), a
			ld hl, SELECTED_WEAPON
			inc (hl)
			ld a, (hl)
			cp 2
			jr nz, CYWE1
			jp DISPLAY_WEAPON
CYWE1
			ld (hl), 0
			jp DISPLAY_WEAPON


CYCLE_ITEM:
			ld a, SND_CHANGE_ITEM
			call PLAY_SOUND
			ld a, (SELECT_TIMEOUT)
			and a
			jr z, CYIT0
			ret
CYIT0
			ld a, 3
			ld (SELECT_TIMEOUT), a
			ld a, 20
			ld (KEYTIMER), a
			ld hl, SELECTED_ITEM
			inc (hl)
			ld a, (hl)
			cp EOF_ITEMS
			jr z, CYIT1
			jp DISPLAY_ITEM
CYIT1
			ld (hl), ID_NULL

			jp DISPLAY_ITEM

USE_ITEM
			ld a, (SELECT_TIMEOUT)
			and a
			jr z, UI01
			ret
UI01
			ld a, (SELECTED_ITEM)
			cp ID_BOMB
			jr nz, UI02
			jp USE_BOMB
UI02
			cp ID_EMP
			jr nz, UI03
			jp USE_EMP
UI03
			cp ID_MEDKIT
			jr nz, UI04
			jp USE_MEDKIT
UI04
			cp ID_MAGNET
			ret nz
			jp USE_MAGNET

USE_BOMB
			call USER_SELECT_OBJECT
			; NOW TEST TO SEE IF THAT SPOT IS OPEN
			call BOMB_MAGNET_COMMON1
			jr z, BM30
			jr BM3A	; If not, then exit routine.
BM30			; Now scan for any units at that location:
			call CHECK_FOR_UNIT
			ld a, (UNIT_FIND)
			cp #ff	; 255 means no unit found.
			jr z, BM31
BM3A
			jp BOMB_MAGNET_COMMON2
BM31
			ld e, 28 ; Start of weapons units
			ld b, 4
BOMB1
			LDA_HL_X UNIT_TYPE
			and a
			jr z, BOMB2
			inc e
			djnz BOMB1
			ret ; no slots available right now, abort.
BOMB2
			ld a, 6 ; bomb AI
			ld (hl), a
			
			ld a, 130	; bomb tile

			ld d, 0		; init D for macro
			STA_HL_X UNIT_TILE
			ld a, (MAP_X)
			STA_HL_X UNIT_LOC_X
			ld a, (MAP_Y)
			STA_HL_X UNIT_LOC_Y
			ld a, 100
			STA_HL_X UNIT_TIMER_A
			xor a
			STA_HL_X UNIT_A
			ld hl, INV_BOMBS
			dec (hl)
			call DISPLAY_ITEM
			ld hl, REDRAW_WINDOW
			ld (hl), 1
			ld hl, SELECT_TIMEOUT
			ld (hl), 3

			ld a, SND_MOVE_OBJECT
			call PLAY_SOUND
			ret


BOMB_MAGNET_COMMON1
			ld hl, CURSOR_ON
			ld (hl), 0
			call DRAW_MAP_WINDOW
			ld a, (CURSOR_X)
			ld hl, MAP_WINDOW_X
			add a, (hl)
			ld (MAP_X), a
			ld (MOVTEMP_UX), a

			ld a, (CURSOR_Y)
			ld hl, MAP_WINDOW_Y
			add a, (hl)
			ld (MAP_Y), a
			ld (MOVTEMP_UY), a
			call GET_TILE_FROM_MAP
			ld e, a
			ld d, 0
			ld hl, TILE_ATTRIB
			add hl, de
			ld a, (hl)
			and 1
			cp 1
			ret

BOMB_MAGNET_COMMON2
			ld hl, MSG_BLOCKED
			call PRINT_INFO
			ld a, SND_ERROR
			call PLAY_SOUND
			ret

USE_MAGNET
			ld a, (MAGNET_ACT)
			and a	; only one magnet active at a time.
			jr z, MG32
			ret
MG32
			call USER_SELECT_OBJECT
			; Now test to see if that spot is open
			call BOMB_MAGNET_COMMON1
			jr z, MG31
			jp BOMB_MAGNET_COMMON2
MG31
			ld hl, UNIT_TYPE+28 ; Start of weapons units
			ld e, 28
			ld b, 4
MAG1
			ld a, (hl)
			and a
			jr z, MAG2
			inc hl
			inc e
			djnz MAG1
			ret ; no slots available right now, abort.
MAG2
			ld a, 20 ; magnet AI
			ld (hl), a
			
			ld a, 134	; magnet tile

			ld d, 0		; init D for macro
			STA_HL_X UNIT_TILE
			ld a, (MAP_X)
			STA_HL_X UNIT_LOC_X
			ld a, (MAP_Y)
			STA_HL_X UNIT_LOC_Y
			ld a, 1
			STA_HL_X UNIT_TIMER_A
			ld a, #ff
			STA_HL_X UNIT_TIMER_B
			ld a, 3
			STA_HL_X UNIT_A
			ld a, 1
			ld (MAGNET_ACT), a
			ld hl, INV_MAGNET
			dec (hl)
			call DISPLAY_ITEM
			ld hl, REDRAW_WINDOW
			ld (hl), 1

			ld a, SND_MOVE_OBJECT
			call PLAY_SOUND
			ret


USE_EMP
			call EMP_FLASH
			xor a
			ld (REDRAW_WINDOW), a

			ld a, SND_USE_EMP
			call PLAY_SOUND

			ld hl, INV_EMP
			dec (hl)
			call DISPLAY_ITEM

			ld de, 1
EMP1
			LDA_HL_X UNIT_TYPE
			ld a, (hl)
			and a
			jr z, EMP5

			; ..--== 6502 ==--..
			; BCC: if cmp > a
			; BCS: if cmp <= a
			
			; ..--==  z80 ==--..
			; jr c if cp > a
			; jr nc if cp <= a

			
			; Check horizontal position
			LDA_HL_X UNIT_LOC_X
			ld hl, MAP_WINDOW_X
			cp (hl)
			jr c, EMP5

			ld a, (MAP_WINDOW_X)
			add 10
			LDA_HL_X UNIT_LOC_X
			cp (hl)
			jr c, EMP5

			; Now check vertical
			LDA_HL_X UNIT_LOC_Y
			ld hl, MAP_WINDOW_Y
			cp (hl)
			jr c, EMP5
			ld a, (MAP_WINDOW_Y)
			add 6
			LDA_HL_X UNIT_LOC_Y
			cp (hl)
			jr c, EMP5

			ld a, #ff
			STA_HL_X UNIT_TIMER_A
			; test to see if unit is above water
			LDA_HL_X UNIT_LOC_X
			ld (MAP_X), a
			LDA_HL_X UNIT_LOC_Y
			ld (MAP_Y), a
			call GET_TILE_FROM_MAP
			cp ID_WATER	; Water
			jr nz, EMP5
			ld a, 5
			STA_HL_X UNIT_TYPE
			STA_HL_X UNIT_TIMER_A
			ld a, 60
			STA_HL_X UNIT_A
			ld a, 140
			STA_HL_X UNIT_TILE
EMP5
			inc e
			ld a, e
			cp 28
			jr nz, EMP1

			ld hl, MSG_EMPUSED
			call PRINT_INFO
			ld a, 3
			ld (SELECT_TIMEOUT), a
			ret

EMP_FLASH
			; TODO
			ret

USE_MEDKIT
			ld a, (UNIT_HEALTH)
			cp 12 ; Do we even need the medkit?
			jr nz, UMK1
			ret
UMK1			; Now figure out how many HP we need to be healthy.
			ld a, 12
			ld hl, UNIT_HEALTH
			sub (hl)
			ld (TEMP_A), a
			ld hl, TEMP_A
			ld a, (INV_MEDKIT)
			sub (hl)
			jr c, UMK2
			; we had more than we need, so go to full health.
			ld a, 12
			ld (UNIT_HEALTH), a
			ld a, (INV_MEDKIT)
			sub (hl)
			ld (INV_MEDKIT), a
			jr UMK3
UMK2
			ld a, (INV_MEDKIT)
			ld hl, UNIT_HEALTH
			add a, (hl)
			ld (UNIT_HEALTH), a
			xor a
			ld (INV_MEDKIT), a
UMK3
			call DISPLAY_PLAYER_HEALTH
			call DISPLAY_ITEM

			ld a, SND_USE_MEDKIT
			call PLAY_SOUND
			ld hl, MSG_MUCHBET
			jp PRINT_INFO


MOVE_OBJECT
			call USER_SELECT_OBJECT
			ld a, (UNIT)
			; now test that object to see if it
			; is allowed to be moved.
MV10
			xor a
			ld (CURSOR_ON), a
			call DRAW_MAP_WINDOW
			call CALC_COORDINATES
			call CHECK_FOR_HIDDEN_UNIT
			ld a, (UNIT_FIND)
			ld (MOVTEMP_U), a
			call GET_TILE_FROM_MAP
			ld e, a
			ld d, 0
			ld hl, TILE_ATTRIB
			add hl, de
			ld a, (hl)
			and %00000100
			jr nz, MV11
			ld hl, MSG_CANTMOVE
			call PRINT_INFO
			ld a, SND_ERROR
			call PLAY_SOUND
			ret
MV11:
			ld a, (TILE)
			ld (MOVTEMP_O), a
			ld a, (MAP_X)
			ld (MOVTEMP_X), a
			ld a, (MAP_Y)
			ld (MOVTEMP_Y), a
			ld a, 1
			ld (CURSOR_ON), a
			call REVERSE_TILE
MV15			; Now ask the user which direction to move it to
			call PET_SCREEN_SHAKE
			call BACKGROUND_TASKS
			ld a, (UNIT_TYPE)
			and a	; Did player die wile moving something?
			jr nz, MVCONT2
			xor a
			ld (CURSOR_ON), a
			ret
MVCONT2
			call getin
			and a
			jr z, MV15
			ld hl, TECLADO

			cp (hl)		; check up
			jr nz, MV17
			ld hl, CURSOR_Y
			dec (hl)
			jp MV25
MV17
			inc hl
			cp (hl)
			jr nz, MV18
			ld hl, CURSOR_Y
			inc (hl)
			jp MV25
MV18
			inc hl
			cp (hl)
			jr nz, MV19
			ld hl, CURSOR_X
			dec (hl)
			jp MV25
MV19
			inc hl
			cp (hl)
			jr nz, MV15
			ld hl, CURSOR_X
			inc (hl)
			jp MV25

MV25
			xor a
			ld (CURSOR_ON), a
			call DRAW_MAP_WINDOW ; Erase the cursor
			ld a, (CURSOR_X)
			ld hl, MAP_WINDOW_X
			add a, (hl)
			ld (MAP_X), a
			ld (MOVTEMP_UX), a
			ld a, (CURSOR_Y)
			ld hl, MAP_WINDOW_Y
			add a, (hl)
			ld (MAP_Y), a
			ld (MOVTEMP_UY), a
			call GET_TILE_FROM_MAP
			ld e, a
			ld d, 0
			ld hl, TILE_ATTRIB
			add hl, de
			ld a, (hl)
			and %00100000	; is that spot available
					; for something to move onto it?
			jr nz, MV30
			jr MV3A
MV30
			; Now scan for any units at that location:
			call CHECK_FOR_UNIT
			ld a, (UNIT_FIND)
			cp #ff
			jr z, MV31
MV3A
			ld hl, MSG_BLOCKED
			call PRINT_INFO
			ld a, SND_ERROR
			call PLAY_SOUND
			ret
MV31
			ld a, SND_MOVE_OBJECT
			call PLAY_SOUND
			ld hl, (MAP_ADDR)
			ld a, (hl)
			ld (MOVTEMP_D), a
			ld a, (MOVTEMP_O)
			ld (hl), a
			ld a, (MOVTEMP_X)
			ld (MAP_X), a
			ld a, (MOVTEMP_Y)
			ld (MAP_Y), a
			call GET_TILE_FROM_MAP
			ld a, (MOVTEMP_D)
			cp 148
			jr nz, MV31A
			ld a, 9
MV31A
			ld hl, (MAP_ADDR)
			ld (hl), a
			ld a, 1
			ld (REDRAW_WINDOW), a
			ld a, (MOVTEMP_U)
			cp #ff
			jr nz, MV32
			ret
MV32
			ld a, (MOVTEMP_U)
			ld c, a
			ld b, 0
			ld a, (MOVTEMP_UX)
			ld hl, UNIT_LOC_X
			add hl, bc
			ld (hl), a
			ld a, (MOVTEMP_UY)
			ld hl, UNIT_LOC_Y
			add hl, bc
			ld (hl), a
			ret

;combines cursor location with window location
;to determine coordinates for MAP_X and MAP_Y
CALC_COORDINATES
			ld a, (CURSOR_X)
			ld hl, MAP_WINDOW_X
			add a, (hl)
			ld (MAP_X), a
			ld a, (CURSOR_Y)
			ld hl, MAP_WINDOW_Y
			add a, (hl)
			ld (MAP_Y), a
			ret

CLEAR_KEY_BUFFER
			ld a, 20
			ld (KEYTIMER), a
			ret

; This routine is invoked when the user requests search
; an object such as a crate, chair, or plant.
SEARCH_OBJECT
			call USER_SELECT_OBJECT
			ld a, 1
			ld (REDRAW_WINDOW), a
CHS1
			; first check of object is searchable
			call CALC_COORDINATES
			call GET_TILE_FROM_MAP
			ld e, a
			ld d, 0
			ld hl, TILE_ATTRIB
			add hl, de
			ld a, (hl)
			and %01000000
			jr nz, CHS2
			xor a
			ld (CURSOR_ON), a
			jr CHS3
CHS2
			; Is the tile a crate?
			ld a, (hl)
			cp ID_BIG_CRATE
			jr z, CHS2B
			cp ID_SMALL_CRATE
			jr z, CHS2B
			cp ID_PI_CRATE
			jr z, CHS2B
			jr CHS2C
CHS2B
			ld e, a
			ld d, 0
			ld hl, DESTRUCT_PATH
			add hl, de
			ld a, (hl)
			ld (TILE), a
			call PLOT_TILE_TO_MAP
CHS2C
			; Now check if there is an object there.
			xor a
			ld (SEARCHBAR), a
			ld hl, MSG_SEARCHING
			call PRINT_INFO
SOBJ1
			ld a, 18	; delay time between search periods
			ld (BGTIMER2), a
SOBJ2
			call PET_SCREEN_SHAKE
			call BACKGROUND_TASKS
			ld a, (BGTIMER2)
			and a
			jr nz, SOBJ2
			ld a, (SEARCHBAR)
			ld e, a
			ld d, 0
			ld hl, TEXT_BUFFER+#3C9
			add hl, de
			ld (hl), 46	; Period
			inc a
			ld (SEARCHBAR), a
			cp 8
			jr nz, SOBJ1
			xor a
			ld (CURSOR_ON), a
			call DRAW_MAP_WINDOW
			call CALC_COORDINATES
			call CHECK_FOR_HIDDEN_UNIT
			ld a, (UNIT_FIND)
			cp #ff
			jr nz, SOBJ5
CHS3
			ld hl, MSG_NOTFOUND
			call PRINT_INFO
			ret
SOBJ5
			ld a, (UNIT_FIND)
			ld e, a
			ld d, 0
			ld hl, UNIT_TYPE
			add hl, de
			ld a, (hl)
			ld (TEMP_A), a	; store object type
			ld hl, UNIT_A
			add hl, de
			ld a, (hl)
			ld (TEMP_B), a	; store secondary info
			; Delete item once found
			ld hl, UNIT_TYPE
			add hl, de
			ld (hl), ID_NULL

			ld a, SND_ITEM_FOUND
			call PLAY_SOUND

			ld a, (TEMP_A)
			cp ID_KEY
			jr z, SOBJ10
			jr SOBJ15
SOBJ10
			ld a, (TEMP_B)
			and a
			jr nz, SOBJK1
			ld a, (KEYS)
			or ID_KEY_SPADE
			ld (KEYS), a
			jr SOBJ12
SOBJK1
			cp 1
			jr nz, SOBJK2
			ld a, (KEYS)
			or ID_KEY_HEART
			ld (KEYS), a
			jr SOBJ12
SOBJK2
			ld a, (KEYS)
			or ID_KEY_STAR
			ld (KEYS), a
SOBJ12
			ld hl, MSG_FOUNDKEY
			call PRINT_INFO
			call DISPLAY_KEYS
			ret
SOBJ15
			cp ID_HIDDEN_BOMB
			jr nz, SOBJ17
			ld a, (TEMP_B)
			ld hl, INV_BOMBS
			add a, (hl)
			ld (hl), a
			ld hl, MSG_FOUNDBOMB
			call PRINT_INFO
			call DISPLAY_ITEM
			ret
SOBJ17
			cp ID_HIDDEN_EMP
			jr nz, SOBJ20
			ld a, (TEMP_B)
			ld hl, INV_BOMBS
			add a, (hl)
			ld (hl), a
			ld hl, MSG_FOUNDEMP
			call PRINT_INFO
			call DISPLAY_ITEM
			ret
SOBJ20
			cp ID_HIDDEN_PISTOL
			jr nz, SOBJ21
			ld a, (TEMP_B)
			ld hl, AMMO_PISTOL
			add a, (hl)
			jr nc, SOBJ2A
			ld a, #ff
SOBJ2A
			ld (hl), a
			ld hl, MSG_FOUNDGUN
			call PRINT_INFO
			call DISPLAY_WEAPON
			ret
SOBJ21
			cp ID_HIDDEN_PLASMA
			jr nz, SOBJ22
			ld a, (TEMP_B)
			ld hl, AMMO_PLASMA
			add a, (hl)
			ld (hl), a
			ld hl, MSG_FOUNDPLAS
			call PRINT_INFO
			call DISPLAY_WEAPON
			ret
SOBJ22
			cp ID_HIDDEN_MEDKIT
			jr nz, SOBJ23
			ld a, (TEMP_B)
			ld hl, INV_MEDKIT
			add a, (hl)
			ld (hl), a
			ld hl, MSG_FOUNDMED
			call PRINT_INFO
			call DISPLAY_ITEM
			ret
SOBJ23
			cp ID_HIDDEN_MAGNET
			ret nz
			ld a, (TEMP_B)
			ld hl, INV_MAGNET
			add a, (hl)
			ld (hl), a
			ld hl, MSG_FOUNDMAG
			call PRINT_INFO
			call DISPLAY_ITEM
			ret

FIRE_UP
			ld a, (SELECTED_WEAPON)
			and a
			ret z
			cp 1
			jr nz, FIRE_UP_PLASMA

			; Fire up pistol

			ld a, (AMMO_PISTOL)
			and a
			ret z

			call fire_search_slot
			ret nz
			ld bc, data_fire_up_pistol
			jp AFTER_FIRE

			; Fire up plasma
FIRE_UP_PLASMA
			ld a, (BIG_EXP_ACT)
			cp 1
			ret z
			ld a, (PLASMA_ACT)
			cp 1
			ret z
			ld a, (AMMO_PLASMA)
			and a
			ret z
			
			call fire_search_slot
			ret nz
			ld bc, data_fire_up_plasma
			jp AFTER_FIRE


FIRE_DOWN
			ld a, (SELECTED_WEAPON)
			and a
			ret z
			cp 1
			jr nz, FIRE_DOWN_PLASMA

			; Fire down pistol

			ld a, (AMMO_PISTOL)
			and a
			ret z

			call fire_search_slot
			ret nz
			ld bc, data_fire_down_pistol
			jp AFTER_FIRE

			; Fire down plasma
FIRE_DOWN_PLASMA
			ld a, (BIG_EXP_ACT)
			cp 1
			ret z
			ld a, (PLASMA_ACT)
			cp 1
			ret z
			ld a, (AMMO_PLASMA)
			and a
			ret z
			
			call fire_search_slot
			ret nz
			ld bc, data_fire_down_plasma
			jp AFTER_FIRE

FIRE_LEFT
			ld a, (SELECTED_WEAPON)
			and a
			ret z
			cp 1
			jr nz, FIRE_LEFT_PLASMA

			; Fire left pistol

			ld a, (AMMO_PISTOL)
			and a
			ret z

			call fire_search_slot
			ret nz
			ld bc, data_fire_left_pistol
			jp AFTER_FIRE

			; Fire left plasma
FIRE_LEFT_PLASMA
			ld a, (BIG_EXP_ACT)
			cp 1
			ret z
			ld a, (PLASMA_ACT)
			cp 1
			ret z
			ld a, (AMMO_PLASMA)
			and a
			ret z
			
			call fire_search_slot
			ret nz
			ld bc, data_fire_left_plasma
			jp AFTER_FIRE

FIRE_RIGHT
			ld a, (SELECTED_WEAPON)
			and a
			ret z
			cp 1
			jr nz, FIRE_RIGHT_PLASMA

			; Fire right pistol

			ld a, (AMMO_PISTOL)
			and a
			ret z

			call fire_search_slot
			ret nz
			ld bc, data_fire_right_pistol
			jp AFTER_FIRE

			; Fire right plasma
FIRE_RIGHT_PLASMA
			ld a, (BIG_EXP_ACT)
			cp 1
			ret z
			ld a, (PLASMA_ACT)
			cp 1
			ret z
			ld a, (AMMO_PLASMA)
			and a
			ret z
			
			call fire_search_slot
			ret nz
			ld bc, data_fire_right_plasma
			jp AFTER_FIRE

fire_search_slot
			ld e, 28
			ld hl, UNIT_TYPE+28
.a1			ld a, (hl)
			and a
			ret z ; slot found, return Z flag
			inc hl
			inc e
			ld a, 32
			cp e
			jr nz, .a1
			; slot not found, flip Z to NZ
			ld a, 1
			and a 
			ret

			; Fire type data blocks 
			; AI routine ID, tile number, travel distance, weapon type
data_fire_up_pistol
			db 12, 244, 3, 0
data_fire_up_plasma
			db 12, 240, 3, 1
data_fire_down_pistol
			db 13, 244, 3, 0
data_fire_down_plasma
			db 13, 240, 3, 1
data_fire_left_pistol
			db 14, 245, 5, 0
data_fire_left_plasma
			db 14, 241, 5, 1
data_fire_right_pistol
			db 15, 245, 5, 0
data_fire_right_plasma
			db 15, 241, 5, 1

AFTER_FIRE
			ld d, 0
			ld a, (bc)
			STA_HL_X UNIT_TYPE
			inc bc
			ld a, (bc)
			STA_HL_X UNIT_TILE
			inc bc
			ld a, (bc)
			STA_HL_X UNIT_A
			inc bc
			ld a, (bc)
			STA_HL_X UNIT_B
			ld (PLASMA_ACT), a
			xor a
			STA_HL_X UNIT_TIMER_A
			ld a, (UNIT_LOC_X)
			STA_HL_X UNIT_LOC_X
			ld a, (UNIT_LOC_Y)
			STA_HL_X UNIT_LOC_Y
			ld a, e
			ld (UNIT), a
			ld a, (SELECTED_WEAPON)
			cp 2
			jr z, AF01

			ld a, SND_PISTOL
			call PLAY_SOUND

			ld hl, AMMO_PISTOL
			dec (hl)
			jp DISPLAY_WEAPON
AF01
			ld a, SND_PLASMAGUN
			call PLAY_SOUND
			ld hl, AMMO_PLASMA
			dec (hl)
			jp DISPLAY_WEAPON


PAUSE_GAME
			ld a, SND_MENU_SELECT
			call PLAY_SOUND
			xor a
			ld (CLOCK_ACTIVE), a
			; display message
			call SCROLL_INFO
			ld hl, MSG_PAUSED
			call PRINT_INFO
			xor a
			ld (BGTIMER1), a
PG0
			ld a, (BGTIMER1)
			or a
			jr z, PG0
			call CLEAR_KEY_BUFFER
			call draw_buffer
PG1
			call getin
			and a
			jr z, PG1
			cp "N"
			jr z, PG5
			cp "Y"
			jr z, PG6
			jr PG1
PG5
			call SCROLL_INFO
			call SCROLL_INFO
			call SCROLL_INFO
			call CLEAR_KEY_BUFFER
			ld a, 1
			ld (CLOCK_ACTIVE), a
			ld a, SND_MENU_SELECT
			call PLAY_SOUND
			jp MAIN_GAME_LOOP
PG6
			xor a
			ld (UNIT_TYPE), a
			ld a, SND_MENU_SELECT
TESTLAB:
			call PLAY_SOUND
			        ld a,7
			        out (#fe),a
			        
			jp GMO4


DISPLAY_ITEM:
			call PRESELECT_ITEM
DSIT00:
			ld a, (SELECTED_ITEM)
			and a
			ret z
DSIT01:
			cp EOF_ITEMS
			jr nz, DSIT0A
			xor a
			ld (SELECTED_ITEM), a
			ret
DSIT0A:
			cp ID_BOMB
			jr nz, DSIT03
			ld a, (INV_BOMBS)
			and a
			jr nz, DSIT02
			ld  hl, SELECTED_ITEM
			inc (hl)
			jr DSIT00
DSIT02:
			call DISPLAY_TIMEBOMB
			ret
DSIT03:
			cp ID_EMP
			jr nz, DSIT05
			ld a, (INV_EMP)
			and a
			jr nz, DSIT04
			ld  hl, SELECTED_ITEM
			inc (hl)
			jr DSIT00			
DSIT04:
			call DISPLAY_EMP
			ret
DSIT05:
			cp ID_MEDKIT
			jr nz, DSIT07
			ld a, (INV_MEDKIT)
			and a
			jr nz, DSIT06
			ld  hl, SELECTED_ITEM
			inc (hl)
			jr DSIT00
DSIT06:
			call DISPLAY_MEDKIT
			ret
DSIT07:
			cp ID_MAGNET
			jr nz, DSIT09
			ld a, (INV_MAGNET)
			and a
			jr nz, DSIT08
			ld  hl, SELECTED_ITEM
			inc (hl)
			jr DSIT09
DSIT08:
			call DISPLAY_MAGNET
			ret
DSIT09:
			xor a
			ld (SELECTED_ITEM), a
			call PRESELECT_ITEM
			jr DISPLAY_ITEM			


;This routine checks to see if currently selected
;item is zero.  And if it is, then it checks inventories
;of other items to decide which item to automatically
;select for the user.

PRESELECT_ITEM:
			ld hl, SELECTED_ITEM
			ld a, (hl)
			and a
			jr z, PRSI01

			ret
PRSI01
			ld a, (INV_BOMBS)
			and a
			jr z, PRSI02
			ld (hl), ID_BOMB
			ret
PRSI02
			ld a, (INV_EMP)
			and a
			jr z, PRSI03
			ld (hl), ID_EMP
			ret
PRSI03
			ld a, (INV_MEDKIT)
			and a
			jr z, PRSI04
			ld (hl), ID_MEDKIT
			ret
PRSI04
			ld a, (INV_MAGNET)
			and a
			jr z, PRSI05
			ld (hl), ID_MAGNET
			ret
PRSI05
			ld (hl), ID_NULL
			call DISPLAY_BLANK_ITEM
			ret

DISPLAY_TIMEBOMB
			ld hl, TBOMB1A
			ld de, TEXT_BUFFER+#162
			ld bc, 6
			ldir
			ld hl, TBOMB1B
			ld de, TEXT_BUFFER+#18A
			ld bc, 6
			ldir
			ld hl, TBOMB1C
			ld de, TEXT_BUFFER+#1B2
			ld bc, 6
			ldir
			ld hl, TBOMB1D
			ld de, TEXT_BUFFER+#1DA
			ld bc, 6
			ldir
			ld a, (INV_BOMBS)
			ld hl, TEXT_BUFFER+#205
			jp DECWRITE

DISPLAY_EMP
			ld hl, EMP1A
			ld de, TEXT_BUFFER+#162
			ld bc, 6
			ldir
			ld hl, EMP1B
			ld de, TEXT_BUFFER+#18A
			ld bc, 6
			ldir
			ld hl, EMP1C
			ld de, TEXT_BUFFER+#1B2
			ld bc, 6
			ldir
			ld hl, EMP1D
			ld de, TEXT_BUFFER+#1DA
			ld bc, 6
			ldir
			ld a, (INV_EMP)
			ld hl, TEXT_BUFFER+#205
			jp DECWRITE

DISPLAY_MEDKIT
			ld hl, MED1A
			ld de, TEXT_BUFFER+#162
			ld bc, 6
			ldir
			ld hl, MED1B
			ld de, TEXT_BUFFER+#18A
			ld bc, 6
			ldir
			ld hl, MED1C
			ld de, TEXT_BUFFER+#1B2
			ld bc, 6
			ldir
			ld hl, MED1D
			ld de, TEXT_BUFFER+#1DA
			ld bc, 6
			ldir
			ld a, (INV_MEDKIT)
			ld hl, TEXT_BUFFER+#205
			jp DECWRITE

DISPLAY_MAGNET
			ld hl, MAG1A
			ld de, TEXT_BUFFER+#162
			ld bc, 6
			ldir
			ld hl, MAG1B
			ld de, TEXT_BUFFER+#18A
			ld bc, 6
			ldir
			ld hl, MAG1C
			ld de, TEXT_BUFFER+#1B2
			ld bc, 6
			ldir
			ld hl, MAG1D
			ld de, TEXT_BUFFER+#1DA
			ld bc, 6
			ldir
			ld a, (INV_MAGNET)
			ld hl, TEXT_BUFFER+#205
			jp DECWRITE

DISPLAY_BLANK_ITEM
			ld hl, TEXT_BUFFER+#162
			ld de, TEXT_BUFFER+#162+1
			ld bc, 5
			ld (hl), 32
			ldir
			ld hl, TEXT_BUFFER+#18A
			ld de, TEXT_BUFFER+#18A+1
			ld bc, 5
			ld (hl), 32
			ldir
			ld hl, TEXT_BUFFER+#1B2
			ld de, TEXT_BUFFER+#1B2+1
			ld bc, 5
			ld (hl), 32
			ldir
			ld hl, TEXT_BUFFER+#1DA
			ld de, TEXT_BUFFER+#1DA+1
			ld bc, 5
			ld (hl), 32
			ldir
			ld hl, TEXT_BUFFER+#202
			ld de, TEXT_BUFFER+#202+1
			ld bc, 5
			ld (hl), 32
			ldir
			ret

;This routine is called by routines such as the move, search,
;or use commands.  It displays a cursor and allows the user
;to pick a direction of an object.
USER_SELECT_OBJECT
			ld a, SND_USER_ACTION
			call PLAY_SOUND

			ld a, 5
			ld (CURSOR_X), a
			ld a, 3
			ld (CURSOR_Y), a
			ld a, 1
			ld (CURSOR_ON), a
			call REVERSE_TILE

			; First ask user which object to move
SEL_OBJ01
			call PET_SCREEN_SHAKE
			call BACKGROUND_TASKS
			ld a, (UNIT_TYPE)
			and a	; Did player die wile moving something?
			jr nz, SEL_OBJ_CONT
			xor a
			ld (CURSOR_ON), a
			ret
SEL_OBJ_CONT
			call getin
			ld hl, TECLADO

			; check key up
			cp (hl)
			jr nz, SEL_OBJ_DOWN
			ld hl, CURSOR_Y
			dec (hl)
			ret
SEL_OBJ_DOWN
			inc hl
			cp (hl)
			jr nz, SEL_OBJ_LEFT
			ld hl, CURSOR_Y
			inc (hl)
			ret
SEL_OBJ_LEFT
			inc hl
			cp (hl)
			jr nz, SEL_OBJ_RIGHT
			ld hl, CURSOR_X
			dec (hl)
			ret
SEL_OBJ_RIGHT
			inc hl
			cp (hl)
			jr nz, SEL_OBJ01
			ld hl, CURSOR_X
			inc (hl)
			ret

; !!!!!!!!!!!!!!! eof new block to translate !!!!!!!!!!!!!!




INTRO_SCREEN:
			call DISPLAY_INTRO_SCREEN
			call DISPLAY_MAP_NAME
			call CHANGE_DIFFICULTY_LEVEL

			xor a
			ld (MENUY), a
			call REVERSE_MENU_OPTION
			call draw_buffer

			call START_INTRO_MUSIC
			call SETUP_INTERRUPT
			ei
ISLOOP
			halt
			call draw_buffer
			call getin
			and a
			jr z, ISLOOP
			cp KBD_DOWN
			jr nz, IS001
IS001A
			ld a, (MENUY)
			cp 3
			jr z, ISLOOP
			call REVERSE_MENU_OPTION
			ld hl, MENUY
			inc (hl)
			call REVERSE_MENU_OPTION

			ld a, SND_MENU_CURSOR
			call PLAY_SOUND

			jr ISLOOP
IS001
			cp KBD_UP
			jr nz, IS002
IS002A
			ld a, (MENUY)
			and a
			jr z, ISLOOP
			call REVERSE_MENU_OPTION
			ld hl, MENUY
			dec (hl)
			call REVERSE_MENU_OPTION
			ld a, SND_MENU_CURSOR
			call PLAY_SOUND
			jr ISLOOP
IS002
			cp KBD_SPACE
			jr nz, IS006
			jp EXEC_COMMAND
IS006
			jr ISLOOP
			; EOF INTRO_SCREEN SUB


REVERSE_MENU_OPTION
			ld hl, MENU_CHART_L
			ld a, (MENUY)
			add a, l
			jr nc, $+3 : inc h
			ld l, a

			ld l, (hl)
			ld h, #B0
			
			ld b, 10
RMO1
			ld a, (hl)
			xor #80
			ld (hl), a
			inc hl
			djnz RMO1
			ret

MENUY			db 0
MENU_CHART_L
			db $54,$7C,$A4,$CC


EXEC_COMMAND
			ld a, (MENUY)
			and a ; START GAME
			jr nz, EXEC1
			call SET_CONTROLS
			
			; TODO turn off sound
			ld a, SND_MENU_SELECT
			call PLAY_SOUND

			jp INIT_GAME
EXEC1
			cp 2 ; DIFF LEVEL
			jr nz, EXEC05
			ld hl, DIFF_LEVEL
			inc (hl)
			ld a, (hl)
			cp 3
			jr nz, EXEC02
			xor a
			ld (DIFF_LEVEL), a
EXEC02
			call CHANGE_DIFFICULTY_LEVEL

			ld a, SND_MENU_SELECT
			call PLAY_SOUND

			jp ISLOOP
EXEC05

			cp 1 ; CYCLE MAP
			jr nz, EXEC06

			ld a, SND_MENU_SELECT
			call PLAY_SOUND

			call CYCLE_MAP
			jp ISLOOP

EXEC06
			cp 3
			jr nz, EXEC07
			call CYCLE_CONTROLS

			ld a, SND_MENU_SELECT
			call PLAY_SOUND

EXEC07
			jp ISLOOP


CYCLE_CONTROLS
			xor a
			ld (KEYS_DEFINED), a
			ld hl, CONTROL
			inc (hl)
			ld a, (hl)
			cp 3
			jr nz, CCON2
			xor a
			ld (hl), a
CCON2
			; display control method on screen
			ld hl, CONTROLSTART
			add a, l
			jr nc,$+3 : inc h
			ld l, a
			ld a, (hl)
			ld de, CONTROLTEXT
			add a, e
			jr nc,$+3 : inc d
			ld e, a
			; Put text
			ld b,10
			ld hl, TEXT_BUFFER + #CC
CCON3
			ld a, (de)
			call pet_char
			xor #80
			ld (hl), a
			inc hl
			inc de
			djnz CCON3
			ret
KEYS_DEFINED		db 0	;DEFAULT 0
CONTROLSTART		db 0, 10, 20
CONTROLTEXT		db "keyboard  "
			db "custom key"
			db "snes pad  "

CYCLE_MAP
			ld hl, SELECTED_MAP
			inc (hl)
			ld a, (hl)
			cp 10 ; Max number of maps
			jr nz, CYM1
			xor a
			ld (SELECTED_MAP), a
CYM1
			call DISPLAY_MAP_NAME

			ret

SET_CONTROLS
			ld a, (CONTROL)
			cp 1 ; CUSTOM KEYS
			jr nz, SETC1
			call SET_CUSTOM_KEYS
			ret
SETC1
			ld hl, STANDARD_CONTROLS
			ld de, TECLADO
			ld bc, 15
			ldir
			ret

SET_CUSTOM_KEYS
			ld a, (KEYS_DEFINED)
			and a
			jr z, SCK00
			ret
SCK00
			; Clear keyset
			ld hl, TECLADO
			ld de, TECLADO+1
			ld bc, 13
			ld (hl), 0
			ldir

			; Show "redefine keys" screen
			ld hl, SCR_CUSTOM_KEYS
			ld de, TEXT_BUFFER
			call DecompressApLib
			call draw_buffer

			ld ix, TEXT_BUFFER+#129
			ld iy, TECLADO
			ld a, 14
			ld (TEMP_A), a
SCK01
			halt
			call draw_buffer
			call getin
			and a
			jr z, SCK01
			ld hl, LASTKEY
			cp (hl)
			jr z, SCK01
			ld (hl), a
			call CHECK_DEFINED_KEY
			jr z, SCK01
			ld (iy), a
			inc iy
			call PRINT_DEFINED_KEY
			ld bc, 40
			add ix, bc
			ld a, (TEMP_A)
			dec a
			ld (TEMP_A), a
			and a
			jr nz, SCK01
			ld a, 1
			ld (KEYS_DEFINED), a
			ld hl, KEYS_DEFINED_STR
			ld de, TEXT_BUFFER+(40*22+2)
			ld b, 32
SCK02
			ld a, (hl)
			call pet_char
			ld (de), a
			inc hl			
			inc de
			djnz SCK02			
SCKDONE
			halt
			call draw_buffer
			call getin
			and a
			jr z, SCKDONE
			ret
LASTKEY			db 255
KEYS_DEFINED_STR	db "done! press any key to continue."

PRINT_DEFINED_KEY:
			cp 32	; SPACE
			jr nz, PDK_ENTER
			ld hl, str_key_space
			jr PDK_PRINT_STRING
PDK_ENTER:
			cp 13	; ENTER
			jr nz, PDK_SSHIFT
			ld hl, str_key_enter
			jr PDK_PRINT_STRING
PDK_SSHIFT:
			cp 2	; SYMBOL SHIFT
			jr nz, PDK_CSHIFT
			ld hl, str_key_sshift
			jr PDK_PRINT_STRING
PDK_CSHIFT:
			cp 1	; CAPS SHIFT
			jr nz, PDK_CHAR
			ld hl, str_key_cshift
			jr PDK_PRINT_STRING
PDK_CHAR:
			call pet_char
			ld (ix), a
			ret
PDK_PRINT_STRING:
			push ix
PDK_PRINT_STRING0:
			ld a, (hl)
			and a
			jr z, PDK_PRINT_STRING1
			call pet_char
			ld (ix), a
			inc ix
			inc hl
			jr PDK_PRINT_STRING0
PDK_PRINT_STRING1:
			pop ix
			ret


str_key_enter		db "enter",0
str_key_space		db "space",0
str_key_cshift		db "caps shift",0
str_key_sshift		db "symbol shift",0

CHECK_DEFINED_KEY:
			push ix
			ld ix, TECLADO
			ld b, 14
CDK0:
			cp (ix+0)
			jr z, CDK1
			inc ix
			djnz CDK0
CDK1:
			pop ix
			ret

DISPLAY_INTRO_SCREEN
			ld hl, INTRO_TEXT
			ld de, TEXT_BUFFER
			call DecompressApLib
			ret

DISPLAY_MAP_NAME
			call CALC_MAP_NAME
			ld de, TEXT_BUFFER + #16a
			ld b, 16
DMN1
			ld a, (hl)
			call pet_char
			ld (de), a
			inc de
			inc hl
			djnz DMN1

			ld a, (SELECTED_MAP)
			add 65+32
			ld (MAPNAME+6), a

			ret

CHANGE_DIFFICULTY_LEVEL
			ld a, (DIFF_LEVEL)
			ld l, a
			ld h,0
			add hl, hl
			add hl, hl
			add hl, hl
			ld bc, ROBOT_FACE
			add hl, bc
			ld a, (hl)
			ld (TEXT_BUFFER+#DD), a
			inc hl
			ld a, (hl)
			ld (TEXT_BUFFER+#DE), a
			inc hl
			ld a, (hl)
			ld (TEXT_BUFFER+#DF), a
			inc hl
			ld a, (hl)
			ld (TEXT_BUFFER+#E1), a
			inc hl
			ld a, (hl)
			ld (TEXT_BUFFER+#E2), a
			inc hl
			ld a, (hl)
			ld (TEXT_BUFFER+#E3), a
			inc hl
			ld a, (hl)
			ld (TEXT_BUFFER+#107), a
			inc hl
			ld a, (hl)
			ld (TEXT_BUFFER+#109), a
			ret

DIFF_LEVEL		db 1	; Initialized, default medium

ROBOT_FACE
			db $3A,$43,$49,$55,$43,$3A,$49,$55	;EASY LEVEL
			db $40,$40,$6E,$70,$40,$40,$49,$55	;MEDIUM LEVEL
			db $3A,$4D,$3A,$3A,$4E,$3A,$4D,$4E	;HARD LEVEL

START_INTRO_MUSIC:
			ld a,SND_TITLE_MUSIC
			jp PLAY_SOUND		;call:ret


CALC_MAP_NAME
			ld a, (SELECTED_MAP)
			ld l, a
			ld h, 0
			add hl, hl
			add hl, hl
			add hl, hl
			add hl, hl
			ld bc, MAP_NAMES
			add hl, bc

			ret

RESET_KEYS_AMMO
			xor a
			ld (KEYS), a
			ld (AMMO_PISTOL), a
			ld (AMMO_PLASMA), a
			ld (INV_BOMBS), a
			ld (INV_EMP), a
			ld (INV_MEDKIT), a
			ld (INV_MAGNET), a
			ld (SELECTED_WEAPON), a
			ld (SELECTED_ITEM), a
			ld (MAGNET_ACT), a
			ld (PLASMA_ACT), a
			ld (BIG_EXP_ACT), a
			ld (CYCLES), a
			ld (SECONDS), a
			ld (MINUTES), a
			ld (HOURS), a
			ret

DISPLAY_GAME_SCREEN
			ld hl, SCR_TEXT
			ld de, TEXT_BUFFER
			call DecompressApLib
			ret

DISPLAY_LOAD_MESSAGE2
			ld de, TEXT_BUFFER + #190
			ld hl, LOAD_MSG2
			ld b, 12
.DLM1			ld a, (hl)
			call pet_char
			ld (de), a
			inc hl
			inc de
			djnz .DLM1
			call CALC_MAP_NAME
			ld b, 16
.DLM2			ld a, (hl)
			call pet_char
			ld (de), a
			inc hl
			inc de
			djnz .DLM2
			ret
LOAD_MSG2		db "loading map:"

MAP_LOAD_ROUTINE
			ld a, (SELECTED_MAP)
			ld l, a
			ld h, 0
			add hl, hl
			ld bc, LEVEL_POINTER
			add hl, bc
			ld e, (hl)
			inc hl
			ld d, (hl)
			ex de, hl
			ld de,MAP_BEGIN
			call DecompressApLib
			; unit_type, UNIT_B
			; 32-47
			; door = 0a
			ld de, 32
close_doors:
			LDA_HL_X UNIT_TYPE
			cp 10
			jr nz, not_door
			ld a, 3
			STA_HL_X UNIT_B
not_door:
			inc e
			ld a, 48
			cp e
			jr nz, close_doors

			ret

SET_DIFF_LEVEL
			ld a, (DIFF_LEVEL)
			and a
			jr nz, SDLE1
			jp SET_DIFF_EASY
SDLE1
			cp 2
			jr nz, SDLE2
			jp SET_DIFF_HARD
SDLE2
			ret

SET_DIFF_EASY
			; Find all hidden items and double the quantity.
			ld de, UNIT_TYPE + 48
			ld hl, UNIT_A + 48
			ld b, 64 - 48
SDE1
			ld a, (de)
			and a
			jr z, SDE2
			cp 128 ; KEY
			jr z, SDE2
			sla (hl)	; double item quantity
SDE2
			inc hl
			inc de
			djnz SDE1
			ret

SET_DIFF_HARD
			; Find all hoverbots and change AI
			ld hl, UNIT_TYPE
			ld b, 28
SDH1
			ld a, (hl)
			cp 2		; hoverbot left/right
			jr z, SDH4
			cp 3 		; hoverbot up/down
			jr z, SDH4
SDH2
			inc hl
			djnz SDH1
			ret
SDH4
			ld a, 4		; hoverbot attack mode
			ld (hl), a
			jr SDH2

ANIMATE_PLAYER
			ld a, (UNIT_TILE)
			cp 97
			jr nz, ANP2
			ld a, 96
			ld (UNIT_TILE), a
			ret
ANP2
			ld a, 97
			ld (UNIT_TILE), a
			ret


CALCULATE_AND_REDRAW
			ld a, (UNIT_LOC_X)	; no index needed since it's player unit
			sub 5
			ld (MAP_WINDOW_X), a
			ld a, (UNIT_LOC_Y)	; no index needed since it's player unit
			sub 3
			ld (MAP_WINDOW_Y), a
			ld a, 1
			ld (REDRAW_WINDOW), a
			ret

;This routine checks all units from 0 to 31 and figures out if it should be dislpayed
;on screen, and then grabs that unit's tile and stores it in the MAP_PRECALC array
;so that when the window is drawn, it does not have to search for units during the
;draw, speeding up the display routine.
MAP_PRE_CALCULATE
	;CLEAR OLD BUFFER
	; LDA	#0
	; LDY	#0
; PREC0	STA	MAP_PRECALC,Y
	; INY
	; CPY	#77
	; BNE	PREC0
	ld hl,MAP_PRECALC
	ld de,MAP_PRECALC+1
	ld bc, 77-1
	ld (hl), 0
	ldir
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
	add a,10
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
	add a,6
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
	;STA	MAP_PRECALC,Y
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

PRECALC_ROWS	db 0,11,22,33,44,55,66

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
			sla a
			ld e, a
			ld d, 0
			ld hl, MAP_CHART
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl) ; de = screen area

			ld hl, TEMP_X
			ld a, (hl)
			sla a		; x2
			add a, (hl)	; +1 (x3)
			ld l, a
			ld h, 0
			add hl, de
			ld (TILE_ADDR), hl

			call PLOT_TILE
			ld a, (PRECALC_COUNT)
			ld e, a
			ld d, 0
			ld hl, MAP_PRECALC
			add hl, de
			ld a, (hl)
			and a
			jr z, DM02
			ld (TILE), a
			call PLOT_TRANSPARENT_TILE
DM02			
			ld hl, PRECALC_COUNT
			inc (hl)
			ld hl, TEMP_X
			inc (hl)
			ld a, 11
			cp (hl)
			jr nz, DM01

			; Check for cursor
			ld a, (CURSOR_ON)
			cp 1
			jr nz, DM04
			ld hl, TEMP_Y
			ld a, (CURSOR_Y)
			cp (hl)
			jr nz, DM04
			call REVERSE_TILE

DM04
			xor a
			ld (TEMP_X), a
			ld hl, TEMP_Y
			inc (hl)
			ld a, 7
			cp (hl)
			jp nz, DM01
			call draw_buffer
			ret


SCREEN_WIDTH		equ 40
MAP_CHART
			dw TEXT_BUFFER
			dw TEXT_BUFFER+(SCREEN_WIDTH*3)
			dw TEXT_BUFFER+(SCREEN_WIDTH*3*2)
			dw TEXT_BUFFER+(SCREEN_WIDTH*3*3)
			dw TEXT_BUFFER+(SCREEN_WIDTH*3*4)
			dw TEXT_BUFFER+(SCREEN_WIDTH*3*5)
			dw TEXT_BUFFER+(SCREEN_WIDTH*3*6)

; This routine plots a 3x3 tile from the tile database anywhere
; on screen.  But first you must define the tile number in the
; TILE variable, as well as the starting screen address must
; be defined in TILE_ADDR.
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

REVERSE_TILE
			ld a, (CURSOR_Y)
			sla a
			ld e, a
			ld d, 0
			ld hl, MAP_CHART
			add hl, de
			ld e, (hl)
			inc hl
			ld d, (hl)

			ld hl, CURSOR_X
			ld a, (hl)
			sla a
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

			ret

DISPLAY_PLAYER_HEALTH
			ld a, (UNIT_HEALTH)
			srl a
			ld c, a
			ld b, 0
			ld hl, TEXT_BUFFER + #3BA
DPH01
			ld a, b
			cp c
			jr z, DPH02
			ld a, #66
			ld (hl), a
			inc hl
			inc b
			jr DPH01
DPH02			
			ld a, (UNIT_HEALTH)
			and 1
			cp 1
			jr nz, DPH03
			ld a, #5c
			ld (hl), a
			inc hl
			inc b
DPH03
			ld a, b
			cp 6
			jr z, DPH04
			ld a, #20
			ld (hl), a
			inc hl
			inc b
			jr DPH03
DPH04
			ret

DISPLAY_KEYS
			ld a, #20
			ld (TEXT_BUFFER+#27A), a
			ld (TEXT_BUFFER+#27B), a
			ld (TEXT_BUFFER+#27C), a
			ld (TEXT_BUFFER+#27D), a
			ld (TEXT_BUFFER+#27E), a
			ld (TEXT_BUFFER+#27F), a
			ld (TEXT_BUFFER+#2A2), a
			ld (TEXT_BUFFER+#2A3), a
			ld (TEXT_BUFFER+#2A4), a
			ld (TEXT_BUFFER+#2A5), a
			ld (TEXT_BUFFER+#2A6), a
			ld (TEXT_BUFFER+#2A7), a
			ld a, (KEYS)
			and 1
			cp 1
			jr nz, DKS1
			ld a, #63
			ld (TEXT_BUFFER+#27A), a
			ld a, #4D
			ld (TEXT_BUFFER+#27B), a
			ld a, #41
			ld (TEXT_BUFFER+#2A2), a
			ld a, #67
			ld (TEXT_BUFFER+#2A3), a
DKS1
			ld a, (KEYS)
			and 2
			cp 2
			jr nz, DKS2
			ld a, #63
			ld (TEXT_BUFFER+#27C), a
			ld a, #4D
			ld (TEXT_BUFFER+#27D), a
			ld a, #53
			ld (TEXT_BUFFER+#2A4), a
			ld a, #67
			ld (TEXT_BUFFER+#2A5), a
DKS2
			ld a, (KEYS)
			and 4
			cp 4
			jr nz, DKS3
			ld a, #63
			ld (TEXT_BUFFER+#27E), a
			ld a, #4D
			ld (TEXT_BUFFER+#27F), a
			ld a, #2A
			ld (TEXT_BUFFER+#2A6), a
			ld a, #67
			ld (TEXT_BUFFER+#2A7), a
DKS3
			ret

DISPLAY_WEAPON
			call PRESELECT_WEAPON
			ld a, (SELECTED_WEAPON)
			and a
			jr nz, DSWP01
			; no weapon to show
			ret
DSWP01
			cp ID_PISTOL
			jr nz, DSWP03
			ld a, (AMMO_PISTOL)
			and a
			jr nz, DSWP02
			xor a
			ld (SELECTED_WEAPON), a
			jr DISPLAY_WEAPON
DSWP02
			call DISPLAY_PISTOL
			ret
DSWP03
			cp ID_PLASMA_GUN
			jr nz, DSWP05
			ld a, (AMMO_PLASMA)
			and a
			jr nz, DSWP04
			xor a
			ld (SELECTED_WEAPON), a
			jr DISPLAY_WEAPON
DSWP04
			call DISPLAY_PLASMA_GUN
			ret
DSWP05
			xor a
			ld (SELECTED_WEAPON), a
			jr DISPLAY_WEAPON

; This routine checks to see if currently selected
; weapon is zero.  And if it is, then it checks inventories
; of other weapons to decide which item to automatically
; select for the user.
PRESELECT_WEAPON
			ld a, (SELECTED_WEAPON)
			and a
			jr z, PRSW01
			ret
PRSW01
			ld a, (AMMO_PISTOL)
			and a
			jr z, PRSW02
			ld a, 1 ; Pistol
			ld (SELECTED_WEAPON), a
			ret
PRSW02
			ld a, (AMMO_PLASMA)
			and a
			jr z, PRSW04
			ld a, 2 ; Plasma gun
			ld (SELECTED_WEAPON), a
			ret
PRSW04
	;Nothing found in inventory at this point, so set
	;selected-item to zero.
			xor a
			ld (SELECTED_WEAPON), a
			call DISPLAY_BLANK_WEAPON
			ret

DISPLAY_PLASMA_GUN
			ld hl, WEAPON1A
			ld de, TEXT_BUFFER+#4A
			ld bc, 6
			ldir

			ld hl, WEAPON1B
			ld de, TEXT_BUFFER+#72
			ld bc, 6
			ldir
			
			ld hl, WEAPON1C
			ld de, TEXT_BUFFER+#9A
			ld bc, 6
			ldir
			
			ld hl, WEAPON1D
			ld de, TEXT_BUFFER+#C2
			ld bc, 6
			ldir

			ld a, (AMMO_PLASMA)
			ld hl, TEXT_BUFFER+#ED
			call DECWRITE
			ret

DISPLAY_PISTOL
			ld hl, PISTOL1A
			ld de, TEXT_BUFFER+#4A
			ld bc, 6
			ldir

			ld hl, PISTOL1B
			ld de, TEXT_BUFFER+#72
			ld bc, 6
			ldir
			
			ld hl, PISTOL1C
			ld de, TEXT_BUFFER+#9A
			ld bc, 6
			ldir
			
			ld hl, PISTOL1D
			ld de, TEXT_BUFFER+#C2
			ld bc, 6
			ldir

			ld a, (AMMO_PISTOL)
			ld hl, TEXT_BUFFER+#ED
			call DECWRITE
			ret

DISPLAY_BLANK_WEAPON
			ld hl, TEXT_BUFFER+#4A
			ld de, TEXT_BUFFER+#4B
			ld (hl), #20
			ld bc, 5
			ldir

			ld hl, TEXT_BUFFER+#72
			ld de, TEXT_BUFFER+#73
			ld (hl), #20
			ld bc, 5
			ldir
			
			ld hl, TEXT_BUFFER+#9A
			ld de, TEXT_BUFFER+#9B
			ld (hl), #20
			ld bc, 5
			ldir
			
			ld hl, TEXT_BUFFER+#C2
			ld de, TEXT_BUFFER+#C3
			ld (hl), #20
			ld bc, 5
			ldir

			ld hl, TEXT_BUFFER+#EA
			ld de, TEXT_BUFFER+#EB
			ld (hl), #20
			ld bc, 5
			ldir
			ret

CHECK_FOR_WINDOW_REDRAW
			; ..--== 6502 ==--..
			; BCC: if cmp > a
			; BCS: if cmp <= a
			
			; ..--==  z80 ==--..
			; jr c if cp > a
			; jr nc if cp <= a

			ld a, (UNIT)
			ld e, a
			ld d, 0
			; Check horizontal position
			LDA_HL_X UNIT_LOC_X
			ld hl, MAP_WINDOW_X
			cp (hl)
			ret c

			ld a, (MAP_WINDOW_X)
			add 10
			ld hl, UNIT_LOC_X
			add hl, de
			cp (hl)
			ret c

			; Now check vertical

			LDA_HL_X UNIT_LOC_Y
			ld hl, MAP_WINDOW_Y
			cp (hl)
			ret c
			ld a, (MAP_WINDOW_Y)
			add 6
			ld hl, UNIT_LOC_Y
			add hl, de
			cp (hl)
			ret c
			ld a, 1
			ld (REDRAW_WINDOW), a
			ret




DECWRITE	; TODO replace with optimized one
		; Print 8 bit number
		; In: A = number, HL = text buffer address
			ld c, -100
			call .DW1
			ld c, -10
			call .DW1
			ld c, -1
.DW1
			ld b, '0'-1
.DW2
			inc b
			add a, c
			jr c, .DW2
			sub c
			push af
			ld a, b
			ld (hl), a
			inc hl
			pop af
			ret

;PLASMA Gun (PET / C64)
WEAPON1A		db $2c,$20,$20,$20,$20,$2c
WEAPON1B		db $e2,$f9,$ef,$e4,$66,$66
WEAPON1C		db $20,$20,$20,$20,$5f,$df
WEAPON1D		db $20,$20,$20,$20,$20,$20

;PISTOL (PET / C64)
PISTOL1A		db $20,$20,$20,$20,$20,$20
PISTOL1B		db $20,$68,$62,$62,$62,$20
PISTOL1C		db $20,$20,$20,$5f,$df,$20
PISTOL1D		db $20,$20,$20,$20,$20,$20

;Time Bomb  (PET / C64)
TBOMB1A			db $20,$20,$55,$2a,$20,$20
TBOMB1B			db $20,$55,$66,$49,$20,$20
TBOMB1C			db $20,$42,$20,$48,$20,$20
TBOMB1D			db $20,$4a,$46,$4b,$20,$20

;EMP (PET / C64)
EMP1A			db $20,$55,$43,$43,$49,$20
EMP1B			db $66,$df,$55,$49,$e9,$66
EMP1C			db $66,$69,$4a,$4b,$5f,$66
EMP1D			db $20,$4a,$46,$46,$4b,$20

;Magnet (PET / C64)
MAG1A			db $4d,$70,$6e,$70,$6e,$4e
MAG1B			db $20,$42,$42,$48,$48,$20
MAG1C			db $63,$42,$4a,$4b,$48,$63
MAG1D			db $4e,$4a,$46,$46,$4b,$4d

;Medkit	(PET / C64)
MED1A			db $20,$55,$43,$43,$49,$20
MED1B			db $20,$A0,$A0,$A0,$A0,$20
MED1C			db $20,$A0,$EB,$F3,$A0,$20
MED1D			db $20,$E4,$E4,$E4,$E4,$20



SET_INITIAL_TIMERS:
			ld a,1
			ld (CLOCK_ACTIVE),a
			ld de,UNIT_TIMER_A
			ld hl,UNIT_TIMER_B
SIT1
			inc hl
			inc de
			ld (de),a
			ld (hl),0
			inc a
			cp 48
			jr nz,SIT1
			ret

PRINT_INTRO_MESSAGE
			ld hl, INTRO_MESSAGE
			call PRINT_INFO
			ret

INTRO_MESSAGE		db "welcome to pet-robots!",255
			db "by david murray 2021",0
MSG_BLOCKED		db "blocked!",0
MSG_EMPUSED		db "emp activated!",255
			db "nearby robots are rebooting.",0
MSG_CANTMOVE		db "can't move that!",0
MSG_SEARCHING		db "searching",0
MSG_NOTFOUND		db "nothing found here.",0
MSG_FOUNDKEY		db "you found a key card!",0
MSG_FOUNDGUN		db "you found a pistol!",0
MSG_FOUNDEMP		db "you found an emp device!",0
MSG_FOUNDBOMB		db "you found a timebomb!",0
MSG_FOUNDPLAS		db "you found a plasma gun!",0
MSG_FOUNDMED		db "you found a medkit!",0
MSG_FOUNDMAG		db "you found a magnet!",0
MSG_MUCHBET		db "ahhh, much better!",0
MSG_TERMINATED		db "you're terminated!",0
MSG_TRANS1		db "transporter will not activate",255
			db "until all robots destroyed.",0
MSG_ELEVATOR		db "[ elevator panel ]  down",255
			db "[  select level  ]  opens",0
MSG_LEVELS		db "[                ]  door",0
MSG_PAUSED		db "game paused.",255
			db "exit game (y/n)",0
MSG_MUSICON		db "music on.",0
MSG_MUSICOFF		db "music off.",0

GAMEOVER1		db $70,$40,$40,$40,$40,$40,$40,$40,$40,$40,$6e
GAMEOVER2		db $5d,$07,$01,$0d,$05,$20,$0f,$16,$05,$12,$5d
GAMEOVER3		db $6d,$40,$40,$40,$40,$40,$40,$40,$40,$40,$7d


PRINT_INFO
			call SCROLL_INFO
			ld de, TEXT_BUFFER+#3C0
PI01
			ld a, (hl)
			and a
			jr nz, PI02
			ret
PI02
			cp #ff
			jr nz, PI03
			ld de, TEXT_BUFFER+#3C0
			call SCROLL_INFO
			jr PI04
PI03
			call pet_char
			ld (de), a
			inc de
PI04
			inc hl
			jr PI01

SCROLL_INFO
			push af
			push hl
			push de
			ld hl, TEXT_BUFFER+#398
			ld de, TEXT_BUFFER+#370
			ld bc, 33
			ldir
			ld hl, TEXT_BUFFER+#3C0
			ld de, TEXT_BUFFER+#398
			ld bc, 33
			ldir
			ld a, #20
			ld hl, TEXT_BUFFER+#3C0
			ld de, TEXT_BUFFER+#3C1
			ld (hl), a
			ld bc, 32
			ldir

			pop de
			pop hl
			pop af
			ret			

CHEATER
			ld a, 7
			ld (KEYS), a
			ld a, 100
			ld (AMMO_PISTOL), a
			ld (AMMO_PLASMA), a
			ld (INV_BOMBS), a
			ld (INV_EMP), a
			ld (INV_MEDKIT), a
			ld (INV_MAGNET), a
			ld a, 1
			ld (SELECTED_WEAPON), a
			ld (SELECTED_ITEM), a
			ret

UPDATE_GAME_CLOCK
			ld a, (CLOCK_ACTIVE)
			cp 1
			ret nz
			ld hl, CYCLES
			inc (hl)
			ld a, (hl)
			cp 50
			ret nz
			xor a
			ld (hl), a
			ld hl, SECONDS
			inc (hl)
			ld a, (hl)
			cp 60
			ret nz
			xor a
			ld (hl), a
			ld hl, MINUTES
			inc (hl)
			ld a, (hl)
			cp 60
			ret nz
			xor a
			ld (hl), a
			ld (SECONDS), a
			ld hl, HOURS
			inc (hl)
			ret

ELEVATOR_SELECT
			call DRAW_MAP_WINDOW
			ld a, (UNIT)
			ld e, a
			ld d, 0
			LDA_HL_X UNIT_D		; get max levels
			ld (ELEVATOR_MAX_FLOOR), a
			; Now draw available levels on screen
			ld b, a
			ld a, #31
			ld hl, TEXT_BUFFER+#3C6
ELS1
			ld (hl), a
			inc a
			djnz ELS1

			LDA_HL_X UNIT_C ; what level are we on now?
			ld (ELEVATOR_CURRENT_FLOOR), a
			;Now highlight current level
			call ELEVATOR_INVERT
ELS5
			call getin
			and a
			jr z, ELS5
			ld hl, TECLADO+KEY_MOVE_DOWN
			cp (hl)	; Down?
			jr nz, ELS7
			call SCROLL_INFO
			call SCROLL_INFO
			call SCROLL_INFO
			ret

ELS7
			inc hl
			cp (hl) ; Left?
			jr nz, ELS6
			call ELEVATOR_DEC
			jr ELS5
ELS6
			inc hl
			cp (hl)		; Right?
			jr nz, ELS5
			call ELEVATOR_INC
			jr ELS5

ELEVATOR_INC
			ld a, (ELEVATOR_CURRENT_FLOOR)
			ld b, a
			ld a, (ELEVATOR_MAX_FLOOR)
			cp b
			ret z
			call ELEVATOR_INVERT
			ld hl, ELEVATOR_CURRENT_FLOOR
			inc (hl)
			call ELEVATOR_INVERT
			call ELEVATOR_FIND_XY
			ret

ELEVATOR_DEC
			ld a, (ELEVATOR_CURRENT_FLOOR)
			cp 1
			ret z
			call ELEVATOR_INVERT
			ld hl, ELEVATOR_CURRENT_FLOOR
			dec (hl)
			call ELEVATOR_INVERT
			call ELEVATOR_FIND_XY
			ret

ELEVATOR_INVERT
			ld a, (ELEVATOR_CURRENT_FLOOR)
			ld e, a
			ld d, 0
			add hl, de
			ld a, (hl)
			xor #80
			ld (hl), a
			ret

ELEVATOR_FIND_XY
			ld de, UNIT_TYPE+32
			ld hl, UNIT_C+32
			ld b, 32
ELXY1
			ld a, (de)
			cp 19
			jr nz, ELXY5
			ld c, (hl)
			ld a, (ELEVATOR_CURRENT_FLOOR)
			cp c
			jr nz, ELXY5
			jr ELXY10
ELXY5
			inc hl
			inc de
			inc b
			ld a, 48
			cp b
			jr nz, ELXY1
			ret
ELXY10
			ld e, b
			ld d, 0
			LDA_HL_X UNIT_LOC_X	; new elevator location
			ld (UNIT_LOC_X), a
			sub 5
			ld (MAP_WINDOW_X), a

			LDA_HL_X UNIT_LOC_Y	; new elevator location
			ld (UNIT_LOC_Y), a
			ld hl, UNIT_LOC_Y
			dec (hl)
			sub 4
			ld (MAP_WINDOW_Y), a
			call DRAW_MAP_WINDOW
			ld a, SND_ELEVATOR
			call PLAY_SOUND
			ret

ANIMATE_WATER
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
			STA	TILE_DATA_MR+196
			STA	TILE_DATA_BM+196
			STA	TILE_DATA_BL+197
			STA	TILE_DATA_TR+200
			xor a
			STA	HVAC_STATE
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
			ld a, 1
			ld (REDRAW_WINDOW), a
			ret
WATER_TEMP1		db 0
WATER_TIMER		db 0
HVAC_STATE		db 0

			; [Re]defined keys
TECLADO			ds 13

UNIT_TIMER_A		ds 64	; Primary timer for units (64 bytes)
UNIT_TIMER_B		ds 64	; Secondary timer for units (64 bytes)
UNIT_TILE		ds 32	; Current tile assigned to unit (32 bytes)
EXP_BUFFER		ds 16	; Explosion Buffer (16 bytes)
MAP_PRECALC		ds 77	; Stores pre-calculated objects for map window (77 bytes)

ANIMATE			db 0

RANDOM			ds 1
TILE_ADDR		ds 2
KEYS			ds 1
AMMO_PISTOL		ds 1
AMMO_PLASMA		ds 1
INV_BOMBS		ds 1
INV_EMP			ds 1
INV_MEDKIT		ds 1
INV_MAGNET		ds 1
SELECTED_WEAPON		ds 1
SELECTED_ITEM		ds 1
SELECT_TIMEOUT		ds 1
MAGNET_ACT		ds 1
PLASMA_ACT		ds 1
BIG_EXP_ACT		ds 1
CYCLES			ds 1
SECONDS			ds 1
MINUTES			ds 1
HOURS			ds 1
SCREEN_SHAKE		ds 1

SELECTED_MAP		ds 1

CONTROL			ds 1

BGTIMER1		ds 1
BGTIMER2		ds 1
KEYTIMER		ds 1	; Used for repeat of movement

KEY_FAST		ds 1

CLOCK_ACTIVE		ds 1

MAP_WINDOW_X		db 0	; Top left location of what is displayed in map window
MAP_WINDOW_Y		db 0	; Top left location of what is displayed in map window
CURSOR_X		ds 1	; For on-screen cursor
CURSOR_Y		ds 1	; For on-screen cursor
MAP_X			ds 1	; Current X location on map
MAP_Y			ds 1	; Current Y location on map
REDRAW_WINDOW		ds 1	; 1=yes 0=no
TEMP_X			ds 1	; Temporarily used for loops
TEMP_Y			ds 1	; Temporarily used for loops
PRECALC_COUNT		ds 1	; part of screen draw routine
UNIT			ds 1	; Current unit being processed
MOVE_TYPE		ds 1	; %00000001=WALK %00000010=HOVER
TILE			ds 1	; The tile number to be plotted
CURSOR_ON		ds 1	; Is cursor active or not? 1=yes 0=no
MOVE_RESULT		ds 1	; 1=Move request success, 0=fail.
UNIT_FIND		ds 1	; 255=no unit present.
SEARCHBAR		ds 1
TEMP_A			ds 1	; used within some routines
TEMP_B			ds 1	; used within some routines

;ATTRIB			ds 1	; Tile attribute value
;TEMP_C			ds 1	; used within some routines
;TEMP_D			ds 1	; used within some routines

MOVTEMP_O		ds 1	; origin tile
MOVTEMP_D		ds 1	; destination tile
MOVTEMP_X		ds 1	; x-coordinate
MOVTEMP_Y		ds 1	; y-coordinate
MOVTEMP_U		ds 1	; unit number (255=none)
MOVTEMP_UX		ds 1
MOVTEMP_UY		ds 1
MAP_ADDR		ds 2

ELEVATOR_MAX_FLOOR	ds 1
ELEVATOR_CURRENT_FLOOR	ds 1

MAP_NAMES		db "01-research lab "
			db "02-headquarters "
			db "03-the village  "
			db "04-the islands  "
			db "05-downtown     "
			db "06-pi university"
			db "07-more islands "
			db "08-robot hotel  "
			db "09-forest moon  "
			db "10-death tower  "

MAPNAME  	
			db "level-a"

INTRO_TEXT
			incbin "res/intro_text.apl"
SCR_CUSTOM_KEYS	
			incbin "res/scr_custom_keys.apl"
SCR_ENDGAME
			incbin "res/scr_endgame.apl"
SCR_TEXT
			incbin "res/scr_text.apl"

; ----------------------------------------------------------------------------------------------------------------------------------------
;			CODE INCLUDES
; ----------------------------------------------------------------------------------------------------------------------------------------
; DecompressApLib		equ DEC40
			include "include/getin.asm"
			include "include/unaplib_small.asm"
			;include "include/unmegalz.asm"
			include "include/BACKGROUND_TASKS.asm"
			include "include/play_sound_48.asm"
			include "include/play_music_48.asm"
			include "STANDARD_CONTROLS.asm"
; ----------------------------------------------------------------------------------------------------------------------------------------

pet_char
			cp 'a'
			jr c,.l1
			cp 'z'+1
			jr nc,.l1
			sub 32
.l1
			sub 32
			xor 32
			ret

LEVEL_POINTER
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a
			dw file_level_a

; ----------------------------------------------------------------------------------------------------------------------------------------
;                       TSCONF RELATED
; ----------------------------------------------------------------------------------------------------------------------------------------

SYSRQ
			push af
			push bc
			push de
			push hl
			;call draw_buffer
			call UPDATE_GAME_CLOCK
			call ANIMATE_WATER
			ld a, 1
			ld (BGTIMER1), a
			ld hl, BGTIMER2
			ld a, (hl)
			and a
			jr z, SYSRQ1
			dec (hl)
SYSRQ1
			ld hl, KEYTIMER
			ld a, (hl)
			and a
			jr z, SYSRQ2
			dec (hl)
SYSRQ2
			ld hl, BORDER_FLASH
			ld a, (hl)
			and a
			jr z, SYSRQ3
			dec (hl)
SYSRQ3
			pop hl
			pop de
			pop bc
			pop af
			ei
			ret

SETUP_INTERRUPT
			xor a
			ld bc,HSINT
			out (c),a
			
			ld bc,VSINTH
			out (c),a

			ld bc,VSINTL
			out (c),a
			

			ld a,#be
			ld i,a
			ld hl,SYSRQ
			ld (#beff),hl


			im 2
			ret

draw_buffer
			; switch ram window
			ld a, PAGE_TILEMAP
			ld bc,PAGE3
			out (c),a

			ld de, TEXT_BUFFER
			ld hl, #c000

drbuf1
			ld a, (de)
			ld (hl), a
			inc de
			inc hl
			inc hl
			ld a, l
			cp 80
			jr nz, drbuf1
			ld l, 0
			inc h
			ld a, h
			cp #D9
			jr nz, drbuf1

			; restore ram window
			ld a, PAGE_PETROBOTS
			ld bc,PAGE3
			out (c),a
			ret

init_tsconf
			ld bc,SYSCONFIG
			ld a, SYS_ZCLK3_5
			out (c),a

			ld hl,init_ts
			call set_ports

			ld hl,init_palette
			call set_ports

			ld b,4
			ld a,Vid_page
clrscr:			push bc

			ld bc,PAGE3
			out (c),a

			ld hl,#c000
			ld de,#c001
			ld bc,#4000
			ld (hl),0
			ldir

			inc a

			pop bc
			djnz clrscr

			ld hl,init_tiles
			call set_ports

			ld a, 0
			ld bc, BORDER
			out (c), a

			ld a,PAGE_TILEMAP						
			ld bc,PAGE3
			out (c),a

			ld hl,#C000
			ld de,#C001
			ld bc,#4000
			ld (hl),0
			ldir

			ret
			
			align 2
init_ts
			db high VCONFIG,VID_16C+VID_320X200
			db high VPAGE,Vid_page
			db high TSCONFIG, TSU_T0EN + TSU_T0ZEN + TSU_SEN 
			db high SGPAGE,Sprites_h_page
			db high TMPAGE, PAGE_TILEMAP
			db high T0GPAGE,TILES0_PAGE
			db high T1GPAGE,TILES1_PAGE
			db high PALSEL,0
			db #ff
			
			align 2
init_palette
			db #1a,low palettes
			db #1b,high palettes
			db #1c,5
			db #1d,0
			db #1e,0
			db #1f,0
			db #26,#20
			db #28,0
			db #27,DMA_RAM_CRAM
			db #ff

			align 2
init_tiles
			db #1a,0
		 	db #1b,0
			db #1c,tiles_page
		 	db #1d,0
		 	db #1e,0
		 	db #1f,TILES0_PAGE
		 	db #26,512/4-1
		 	db #28,64-1
			db #27,DMA_RAM + DMA_DALGN
			db #ff



set_ports		ld c,#AF
.m1			ld b,(hl) 
			inc hl
			inc b
			jr z,dma_stats
			outi
			jr .m1
dma_stats		ld b,high DMASTATUS
			in a,(c)
			and #80
			jr nz,$-4
			ret


			; align 256
file_tileset
			incbin "res/tileset.pet"
			; Destruct path array (256 bytes)
DESTRUCT_PATH		equ file_tileset+2
			; Tile attrib array (256 bytes)
TILE_ATTRIB		equ DESTRUCT_PATH + 256
			; Tile character top-left (256 bytes)
TILE_DATA_TL		equ TILE_ATTRIB + 256
			; Tile character top-middle (256 bytes)
TILE_DATA_TM		equ TILE_DATA_TL + 256
			; Tile character top-right (256 bytes)
TILE_DATA_TR		equ TILE_DATA_TM + 256
			; Tile character middle-left (256 bytes)
TILE_DATA_ML		equ TILE_DATA_TR + 256
			; Tile character middle-middle (256 bytes)
TILE_DATA_MM		equ TILE_DATA_ML + 256
			; Tile character middle-right (256 bytes)
TILE_DATA_MR		equ TILE_DATA_MM + 256
			; Tile character bottom-left (256 bytes)
TILE_DATA_BL		equ TILE_DATA_MR + 256
			; Tile character bottom-middle (256 bytes)
TILE_DATA_BM		equ TILE_DATA_BL + 256
			; Tile character bottom-right (256 bytes)
TILE_DATA_BR		equ TILE_DATA_BM + 256


end

			page 4
			org #c000
			incbin "gfx/tileset.tga.pix4"

			page 5
			org #c000
palettes
			; Tsconf palette format:
			; 15 14 13 12 11 10  9 8 7 6 5  4 3 2 1 0
			; x  R[4:0]          G[4:0]     B[4:0]				 
			dw #0000		; Color 0
			dw %0011011101101011	; Color 1
			dw #0180		; Color 2
			dw #3180		; Color 3
			dw #000C		; Color 4
			dw #300C		; Color 5
			dw #018C		; Color 6
			dw #4E73		; Color 7
			dw #318C		; Color 8
			dw #6000		; Color 9
			dw #0300		; Color 10
			dw #6300		; Color 11
			dw #0018		; Color 12
			dw #6018		; Color 13
			dw #0318		; Color 14
			dw #6318		; Color 15


			page 6
			org #c000
file_level_a
			incbin "res/level-a.apl"
file_level_b
			incbin "res/level-b.apl"

			include "include/tsconfig.inc"
			
			display "Code length:  ",/d,end-start
			savesna "main.sna",#6200