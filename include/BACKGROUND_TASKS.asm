
			; input HL array, X is taken directly from UNIT
			; returns HL+UNIT, keeps A unchanged (needed at places)
unit_abs_x:
			exa
			ld a,(UNIT)
			add a,l
			ld l,a
			jr nc,$+3
			inc h
			exa
			ret
	
			; input HL array, X is in C
			; returns HL+C, keeps A unchanged (needed at places)
offc_abs_x:
			exa
			ld a,l
			add a,c
			ld l,a
			jr nc,$+3
			inc h
			exa
			ret
	
BACKGROUND_TASKS:
	; LDA	REDRAW_WINDOW
	; CMP	#1
	; BNE	UNIT_AI
	; LDA	BGTIMER1
	; CMP	#1
	; BNE	UNIT_AI
	; LDA	#0
	; STA	REDRAW_WINDOW
	; JSR	DRAW_MAP_WINDOW
			ld a,(REDRAW_WINDOW)
			or a
			jr z,UNIT_AI
			ld a,(BGTIMER1)
			or a
			jr z,UNIT_AI
			xor a
			ld (REDRAW_WINDOW),a
			call DRAW_MAP_WINDOW
UNIT_AI:
	;Now check to see if it is time to run background tasks
	; LDA	BGTIMER1
	; CMP	#1
	; BEQ	AI000
	; RTS
			ld a,(BGTIMER1)
			or a
			jr nz,AI000
			ret
AI000:
	; LDA	#0
	; STA	BGTIMER1	;RESET BACKGROUND TIMER
			xor a
			ld (BGTIMER1),a		;RESET BACKGROUND TIMER
	;INC	$83C0	;-TROUBLESHOOTING
	; LDX	#$FF	;sh8bit -- this seems to be a leftover
	; STA	UNIT
			ld (UNIT),a
AILP:
	;ALL AI routines must JMP back to here at the end.
	; INC	UNIT
	; LDX	UNIT
	; CPX	#64			;END OF UNITS
	; BNE	AI001
	; RTS			;RETURN CONTROL TO MAIN PROGRAM
			ld hl,UNIT
			inc (hl)
			ld a,(hl)
			cp 64				;END OF UNITS
			jr nz,AI001
			ret				;RETURN CONTROL TO MAIN PROGRAM
AI001:
	; LDA	UNIT_TYPE,X
	; CMP	#0			;Does unit exist?
	; BNE	AI002
	; JMP	AILP
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld a,(hl)
			or a				;Does unit exist?
			jr z,AILP
AI002:
	;Unit found to exist, now check it's timer.
	;unit code won't run until timer hits zero.
	; LDA	UNIT_TIMER_A,X
	; CMP	#0
	; BEQ	AI003
	; DEC	UNIT_TIMER_A,X		;Decrease timer by one.
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr z,AI003
			dec (hl)			;Decrease timer by one.
			jp AILP
AI003:
	;Unit exists and timer has triggered
	;The unit type determines which AI routine is run.
	; LDA	UNIT_TYPE,X
	; CMP	#24			;MAX DIFFERENT UNIT TYPES IN CHART
	; BCS	AILP			;ABORT IF GREATER
	; TAY
	; LDA	AI_ROUTINE_CHART_L,Y
	; STA	AI004+1
	; LDA	AI_ROUTINE_CHART_H,Y
	; STA	AI004+2
; AI004:
	; JMP	$0000	;***self modifying code used here***
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld a,(hl)
			cp 24			;MAX DIFFERENT UNIT TYPES IN CHART
			jr nc,AILP		;ABORT IF GREATER
			ld hl,AI_ROUTINE_CHART
			add a,a
			add a,l
			ld l,a
			jr nc,$+3
			inc h
			ld a,(hl)
			inc hl
			ld h,(hl)
			ld l,a
			jp (hl)				;no self-modifying code used here

AI_ROUTINE_CHART:
			dw DUMMY_ROUTINE		; UNIT TYPE 00	;non-existent unit
			dw DUMMY_ROUTINE		; UNIT TYPE 01	;player unit - can't use
			dw LEFT_RIGHT_DROID		; UNIT TYPE 02
			dw UP_DOWN_DROID		; UNIT TYPE 03
			dw HOVER_ATTACK			; UNIT TYPE 04
			dw WATER_DROID			; UNIT TYPE 05
			dw TIME_BOMB			; UNIT TYPE 06
			dw TRANSPORTER_PAD		; UNIT TYPE 07
			dw DEAD_ROBOT			; UNIT TYPE 08
			dw EVILBOT			; UNIT TYPE 09 
			dw AI_DOOR			; UNIT TYPE 10
			dw SMALL_EXPLOSION		; UNIT TYPE 11
			dw PISTOL_FIRE_UP		; UNIT TYPE 12
			dw PISTOL_FIRE_DOWN		; UNIT TYPE 13
			dw PISTOL_FIRE_LEFT		; UNIT TYPE 14
			dw PISTOL_FIRE_RIGHT		; UNIT TYPE 15
			dw TRASH_COMPACTOR		; UNIT TYPE 16
			dw UP_DOWN_ROLLERBOT		; UNIT TYPE 17
			dw LEFT_RIGHT_ROLLERBOT		; UNIT TYPE 18
			dw ELEVATOR			; UNIT TYPE 19
			dw MAGNET			; UNIT TYPE 20
			dw MAGNETIZED_ROBOT		; UNIT TYPE 21
			dw WATER_RAFT_LR		; UNIT TYPE 22
			dw DEMATERIALIZE		; UNIT TYPE 23

AILP_CHECK_FOR_WINDOW_REDRAW:
			call CHECK_FOR_WINDOW_REDRAW
			jp AILP
	
	;Dummy routine does nothing, but I need it for development.
DUMMY_ROUTINE:
	; JMP	AILP
			jp AILP

WATER_RAFT_LR:
	;LDA	#0		;sh8bit -- seems to be another leftover
	; LDX	UNIT
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	RAFT_RIGHT
	; JMP	RAFT_LEFT
			
			; First check which direction raft is moving.
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr z,RAFT_LEFT
	
RAFT_RIGHT:
	; JSR	RAFT_DELETE
			call RAFT_DELETE
	
	; LDA	UNIT_LOC_X,X	;raft
	; CMP	UNIT_LOC_X	;player
	; BNE	WARF05
	; LDA	UNIT_LOC_Y,X	;raft
	; CMP	UNIT_LOC_Y	;player
	; BNE	WARF05
	; INC	UNIT_LOC_X	;player
	; INC	UNIT_LOC_X,X	;raft
	; JSR	RAFT_PLOT
	; JSR	CACULATE_AND_REDRAW
	; JMP	WARF5B
			
			;Check to see if player is on raft
			ld hl,UNIT_LOC_X
			ld a,(hl)			;player
			call unit_abs_x
			cp (hl)				;raft
			jr nz,WARF05
			ld hl,UNIT_LOC_Y
			ld a,(hl)			;player
			call unit_abs_x
			cp (hl)				;raft
			jr nz,WARF05
			ld hl,UNIT_LOC_X
			inc (hl)			;player
			call unit_abs_x
			inc (hl)			;raft
			call RAFT_PLOT
			call CALCULATE_AND_REDRAW
			jr WARF5B
	
WARF05:
	; INC	UNIT_LOC_X,X	;raft
	; JSR	RAFT_PLOT
			ld hl,UNIT_LOC_X
			call unit_abs_x
			inc (hl)				;raft
			call RAFT_PLOT
	
	; JSR	CHECK_FOR_WINDOW_REDRAW
			
			;Now check if it has reached its destination
			call CHECK_FOR_WINDOW_REDRAW
	
WARF5B:
	; LDX	UNIT
	; LDA	UNIT_LOC_X,X
	; CMP	UNIT_C,X	
	; BEQ	WARF06
	; LDA	#6
	; STA	UNIT_TIMER_A,X
	; JMP	AILP
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_C
			call unit_abs_x
			cp (hl)
			jr z,WARF06
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),RAFT_SPEED
			jp AILP

WARF06:
	; LDA	#100
	; STA	UNIT_TIMER_A,X
	; LDA	#0
	; STA	UNIT_A,X
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),RAFT_WAIT_TIME
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),0
			jp AILP

RAFT_LEFT:
	; JSR	RAFT_DELETE
			call RAFT_DELETE
	
	; LDA	UNIT_LOC_X,X	;raft
	; CMP	UNIT_LOC_X	;player
	; BNE	WARF07
	; LDA	UNIT_LOC_Y,X	;raft
	; CMP	UNIT_LOC_Y	;player
	; BNE	WARF07
	; DEC	UNIT_LOC_X	;player
	; DEC	UNIT_LOC_X,X	;raft
	; JSR	RAFT_PLOT
	; JSR	CACULATE_AND_REDRAW
	; JMP	WARF7B

			;Check to see if player is on raft
			ld hl,UNIT_LOC_X
			ld a,(hl)			;player
			call unit_abs_x
			cp (hl)				;raft
			jr nz,WARF07
			ld hl,UNIT_LOC_Y
			ld a,(hl)			;player
			call unit_abs_x
			cp (hl)				;raft
			jr nz,WARF07
			ld hl,UNIT_LOC_X
			dec (hl)			;player
			call unit_abs_x
			dec (hl)			;raft
			call RAFT_PLOT
			call CALCULATE_AND_REDRAW
			jr WARF7B
	
WARF07:
	; DEC	UNIT_LOC_X,X	;raft
	; JSR	RAFT_PLOT
			ld hl,UNIT_LOC_X
			call unit_abs_x
			dec (hl)			;raft
			call RAFT_PLOT
	; JSR	CHECK_FOR_WINDOW_REDRAW

			;Now check if it has reached its destination
			call CHECK_FOR_WINDOW_REDRAW
	
WARF7B:
	; LDX	UNIT
	; LDA	UNIT_LOC_X,X
	; CMP	UNIT_B,X	
	; BEQ	WARF08
	; LDA	#6
	; STA	UNIT_TIMER_A,X
	; JMP	AILP

			; Now check if it has reached its destination
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_B
			call unit_abs_x
			cp (hl)
			jr z,WARF08
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),RAFT_SPEED
			jp AILP
	
WARF08:
	; LDA	#100
	; STA	UNIT_TIMER_A,X
	; LDA	#1
	; STA	UNIT_A,X
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),RAFT_WAIT_TIME
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),1
			jp AILP

RAFT_DELETE:
			ld a, TILE_WATER	;WATER TILE
			ld (TILE),a
			jr RAFT_PLOT1

RAFT_PLOT:
			ld a, TILE_RAFT	;RAFT TILE
			ld (TILE),a

RAFT_PLOT1:
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; LDA	#242	;RAFT TILE
	; STA	TILE
	; JSR 	PLOT_TILE_TO_MAP
	; RTS
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			jp PLOT_TILE_TO_MAP		;call:ret


MAGNETIZED_ROBOT:
	; LDA	#%00000001
	; STA	MOVE_TYPE
	; JSR	GENERATE_RANDOM_NUMBER
	; LDA	RANDOM
	; AND	#%00000011
	; CMP	#00
	; BEQ	MAGRO1
	; CMP	#01
	; BEQ	MAGRO2
	; CMP	#02
	; BEQ	MAGRO3
	; CMP	#03
	; BEQ	MAGRO4
			ld a,%00000001
			ld (MOVE_TYPE),a
			call GENERATE_RANDOM_NUMBER
			ld a,(RANDOM)
			and %00000011
			cp 1
			jr z,MAGRO2
			cp 2
			jr z,MAGRO3
			cp 3
			jr z,MAGRO4
	
MAGRO1:
	; JSR	REQUEST_WALK_UP
	; JMP	MAGR10
			call REQUEST_WALK_UP
			jr MAGR10
MAGRO2:
	; JSR	REQUEST_WALK_DOWN
	; JMP	MAGR10
			call REQUEST_WALK_DOWN
			jr MAGR10
MAGRO3:
	; JSR	REQUEST_WALK_LEFT
	; JMP	MAGR10
			call REQUEST_WALK_LEFT
			jr MAGR10
MAGRO4:
	; JSR	REQUEST_WALK_RIGHT
			call REQUEST_WALK_RIGHT
MAGR10:
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; LDX	UNIT
	; LDA	#10
	; STA	UNIT_TIMER_A,X
	; DEC	UNIT_TIMER_B,X
	; LDA	UNIT_TIMER_B,X
	; CMP	#0
	; BNE	MAGR11
	; LDA	UNIT_D,X
	; STA	UNIT_TYPE,X
			call CHECK_FOR_WINDOW_REDRAW
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl), HOVERBOT_MOVE_SPD
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			dec (hl)
			; ld a,(hl)
			; or a
			jr nz,MAGR11
			ld hl,UNIT_D
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),a
	
MAGR11:
	; JMP	AILP
			jp AILP

GENERATE_RANDOM_NUMBER:
 	; LDA	RANDOM
	; BEQ 	DOEOR ;added this
	; ASL
	; BCC	NOEOR
; DOEOR:
	; EOR	#$1D
; NOEOR:
	; STA	RANDOM
	; RTS
			ld a,(RANDOM)
			and a
			jr z,DOEOR
			add a,a
			jr nc,NOEOR			;note the difference with asl:bcc
DOEOR:
			xor #1d
NOEOR
			ld (RANDOM),a
			ret

MAGNET:	
	; LDX	UNIT
	; DEC	UNIT_TIMER_B,X
	; LDA	UNIT_TIMER_B,X
	; CMP	#0
	; BNE	MAGN1
	; DEC	UNIT_A,X
	; LDA	UNIT_A,X
	; CMP	#0
	; BNE	MAGN1

			;First let's take care of the timers.  This unit runs
			;every cycle so that it can detect contact with another
			;unit.  But it still needs to count down to terminate
			;So, it uses two timers for a 16-bit value.
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			dec (hl)
			ld a,(hl)
			or a
			jr nz,MAGN1
			ld hl,UNIT_A
			call unit_abs_x
			dec (hl)
			ld a,(hl)
			or a
			jr nz,MAGN1

			;Both timers have reached zero, time to deactivate.	
MAGN0:
	; LDX	UNIT
	; LDA	#0
	; STA	UNIT_TYPE,X
	; STA	MAGNET_ACT
	; JMP	AILP
			ld hl,UNIT_TYPE
			call unit_abs_x
			xor a
			ld (hl),a
			ld (MAGNET_ACT),a
			jp AILP
	
MAGN1:
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	CHECK_FOR_UNIT
	; LDA	UNIT_FIND
	; CMP	#255	;no unit found
	; BEQ	MAGN2
	; CMP	#0	;player unit
	; BEQ	MAGN3
	; JMP	MAGN4

			;Now let's see if another units walks on the magnet.
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255		;no unit found
			jr z,MAGN2
			or a		;player unit
			jr z,MAGN3
			jp MAGN4
	
MAGN2:
	; JMP	AILP
			jp AILP
MAGN3:
	; INC	INV_MAGNET
	; JSR	DISPLAY_ITEM
	; JMP	MAGN0
			ld hl,INV_MAGNET
			inc (hl)
			call DISPLAY_ITEM
			jp MAGN0
	
MAGN4:
	; LDA	#4		;HAYWIRE SOUND
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT_FIND
	; LDA	UNIT_TYPE,X
	; STA	UNIT_D,X	;make backup of unit type
	; LDA	#21	;Crazy robot AI
	; STA	UNIT_TYPE,X
	; LDA	#60
	; STA	UNIT_TIMER_B,X
	; LDX	UNIT
	; JMP	MAGN0

			;Collision with robot detected.
			ld a, SND_HAYWIRE	;HAYWIRE SOUND
			call PLAY_SOUND		;SOUND PLAY
			ld a,(UNIT_FIND)
			ld c,a
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			ld (hl), AI_CRAZY_ROBOT			;Crazy robot AI
			ld hl,UNIT_D
			call offc_abs_x
			ld (hl),a			;make backup of unit type
			ld hl,UNIT_TIMER_B
			call offc_abs_x
			ld (hl), MAGNET_EFFECT_DURATION
			jp MAGN0

DEAD_ROBOT:
	; LDX	UNIT
	; LDA	#0
	; STA	UNIT_TYPE,X
	; JMP	AILP
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),0
			jp AILP

UP_DOWN_ROLLERBOT:
	; LDX	UNIT
	; LDA	#7
	; STA	UNIT_TIMER_A,X
	; JSR	ROLLERBOT_ANIMATE
	; LDX	UNIT
	; LDA	UNIT_A,X		;GET DIRECTION
	; CMP	#1	;0=UP 1=DOWN
	; BEQ	UDR01
	; LDA	#%00000001
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_UP
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	UDR02
	; LDA	#1
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
	; JSR	ROLLERBOT_FIRE_DETECT
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl), ROLLERBOT_MOVE_SPD
			call ROLLERBOT_ANIMATE
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)		;GET DIRECTION
			or a			;0=UP 1=DOWN
			jr nz,UDR01
			ld a,%00000001
			ld (MOVE_TYPE),a
			call REQUEST_WALK_UP
			;ld a,(MOVE_RESULT)
			or a
			jr nz,UDR02
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),1		;CHANGE DIRECTION
			call ROLLERBOT_FIRE_DETECT
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
UDR01:
	; LDA	#%00000001
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_DOWN
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	UDR02
	; LDA	#0
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
			ld a,%00000001
			ld (MOVE_TYPE),a
			call REQUEST_WALK_DOWN
			;ld a,(MOVE_RESULT)
			or a
			jr nz,UDR02
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),0		;CHANGE DIRECTION
	
UDR02:
	; JSR	ROLLERBOT_FIRE_DETECT
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			call ROLLERBOT_FIRE_DETECT
			jp AILP_CHECK_FOR_WINDOW_REDRAW

LEFT_RIGHT_ROLLERBOT:
	; LDX	UNIT
	; LDA	#7
	; STA	UNIT_TIMER_A,X
	; JSR	ROLLERBOT_ANIMATE
	; LDX	UNIT
	; LDA	UNIT_A,X		;GET DIRECTION
	; CMP	#1	;0=LEFT 1=RIGHT
	; BEQ	LRR01
	; LDA	#%00000001
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_LEFT
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	LRR02
	; LDA	#1
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
	; JSR	ROLLERBOT_FIRE_DETECT
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),ROLLERBOT_MOVE_SPD
			call ROLLERBOT_ANIMATE
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)		;GET DIRECTION
			or a			;0=LEFT 1=RIGHT
			jr nz,LRR01
			ld a,%00000001
			ld (MOVE_TYPE),a
			call REQUEST_WALK_LEFT
			;ld a,(MOVE_RESULT)
			or a
			jr nz,LRR02
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),1		;CHANGE DIRECTION
			call ROLLERBOT_FIRE_DETECT
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
LRR01:
	; LDA	#%00000001
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_RIGHT
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	LRR02
	; LDA	#0
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
			ld a,%00000001
			ld (MOVE_TYPE), a
			call REQUEST_WALK_RIGHT
			;ld a,(MOVE_RESULT)
			or a
			jr nz,LRR02
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),0		;CHANGE DIRECTION
	
LRR02:
	; JSR	ROLLERBOT_FIRE_DETECT
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			call ROLLERBOT_FIRE_DETECT
			jp AILP_CHECK_FOR_WINDOW_REDRAW

ROLLERBOT_FIRE_DETECT:
	; LDA	UNIT_LOC_X,X
	; STA	TEMP_A
	; LDA	UNIT_LOC_Y,X
	; STA	TEMP_B
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (TEMP_A),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (TEMP_B),a
	
	; LDA	UNIT_LOC_Y,X	;robot
	; CMP	UNIT_LOC_Y	;player
	; BNE	RFDE2
	; JMP	ROLLERBOT_FIRE_LR
			
			;See if we're lined up vertically
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)			;robot
			ld hl,UNIT_LOC_Y
			cp (hl)				;player
			jp z,ROLLERBOT_FIRE_LR
	; jr RFDE2
	
RFDE2:
	; LDA	UNIT_LOC_X,X	;robot
	; CMP	UNIT_LOC_X	;player
	; BNE	RFDE3
	; JMP	ROLLERBOT_FIRE_UD
			
			; See if we're lined up horizontally
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)			;robot
			ld hl,UNIT_LOC_X
			cp (hl)				;player
			jr z,ROLLERBOT_FIRE_UD
	;jr RFDE3

RFDE3:
	; RTS
			ret

ROLLERBOT_FIRE_LR:
	; LDA	UNIT_LOC_X,X
	; CMP	UNIT_LOC_X
	; BCC	RBFLR2
	; JMP	ROLLERBOT_FIRE_LEFT
; RBFLR2:
	; JMP	ROLLERBOT_FIRE_RIGHT
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_LOC_X
			cp (hl)
			jr c,ROLLERBOT_FIRE_RIGHT
			; jr ROLLERBOT_FIRE_LEFT

ROLLERBOT_FIRE_LEFT:
	; LDA	UNIT_LOC_X,X	;robot
	; SEC
	; SBC	UNIT_LOC_X	;player
	; CMP	#6
	; BCC	RFL0
	; RTS
	
			; Check to see if distance is less than 5
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)			;robot
			ld hl,UNIT_LOC_X
			sub (hl)			;player
			cp 6
			ret nc
	
RFL0:
	; LDX	#28
			ld c,28
RFL1:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	RFL2
	; INX
	; CPX	#32
	; BNE	RFL1
	; RTS
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,RFL2
			inc c
			ld a,c
			cp 32
			jr nz,RFL1
			ret
RFL2:
	; LDA	#14	;pistol fire left AI
	; STA	UNIT_TYPE,X
	; LDA	#245	;tile for horizontal weapons fire
	; JMP	ROLLERBOT_AFTER_FIRE
			ld hl, UNIT_TYPE
			call offc_abs_x
			ld (hl), AI_PISTOL_LEFT			;pistol fire left AI
			ld a, TILE_PISTOL_HORZ		;tile for horizontal weapons fire
			jp ROLLERBOT_AFTER_FIRE
	
ROLLERBOT_FIRE_RIGHT:
	; LDA	UNIT_LOC_X	;player
	; SEC
	; SBC	UNIT_LOC_X,X	;robot
	; CMP	#6
	; BCC	RFR0
	; RTS	

			;Check to see if distance is less than 5
			ld hl,UNIT_LOC_X
			ld a,(hl)			;player
			call unit_abs_x
			sub (hl)			;robot
			cp 6
			ret nc
	
RFR0:
	; LDX	#28
			ld c,28
RFR1:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	RFR2
	; INX
	; CPX	#32
	; BNE	RFR1
	; RTS
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,RFR2
			inc c
			ld a,c
			cp 32
			jr nz,RFR1
			ret
RFR2:
	; LDA	#15	;pistol fire RIGHT AI
	; STA	UNIT_TYPE,X
	; LDA	#245	;tile for horizontal weapons fire
	; JMP	ROLLERBOT_AFTER_FIRE
	; RTS
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl), AI_PISTOL_RIGHT			;pistol fire RIGHT AI
			ld a, TILE_PISTOL_HORZ			;tile for horizontal weapons fire
			jp ROLLERBOT_AFTER_FIRE

ROLLERBOT_FIRE_UD:
	; LDA	UNIT_LOC_Y,X
	; CMP	UNIT_LOC_Y
	; BCC	RBFUD2
	; JMP	ROLLERBOT_FIRE_UP
; RBFUD2:
	; JMP	ROLLERBOT_FIRE_DOWN
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_LOC_Y
			cp (hl)
			jr c,ROLLERBOT_FIRE_DOWN
	
ROLLERBOT_FIRE_UP:
	; LDA	UNIT_LOC_Y,X	;robot
	; SEC
	; SBC	UNIT_LOC_Y	;player
	; CMP	#4
	; BCC	RFU0
	; RTS	

			;Check to see if distance is less than 5
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)			;robot
			ld hl,UNIT_LOC_Y
			sub (hl)			;player
			cp 4
			ret nc
	
RFU0:
	; LDX	#28
			ld c,28
RFU1:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	RFU2
	; INX
	; CPX	#32
	; BNE	RFU1
	; RTS
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,RFU2
			inc c
			ld a,c
			cp 32
			jr nz,RFU1
			ret
	
RFU2:
	; LDA	#12	;pistol fire UP AI
	; STA	UNIT_TYPE,X
	; LDA	#244	;tile for horizontal weapons fire
	; JMP	ROLLERBOT_AFTER_FIRE
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl),AI_PISTOL_UP		;pistol fire UP AI
			ld a,TILE_PISTOL_VERT		;tile for VERTICAL weapons fire
			jp ROLLERBOT_AFTER_FIRE
	
ROLLERBOT_FIRE_DOWN:
	;Check to see if distance is less than 5
	; LDA	UNIT_LOC_Y	;player
	; SEC
	; SBC	UNIT_LOC_Y,X	;robot
	; CMP	#4
	; BCC	RFD0
	; RTS
			ld hl,UNIT_LOC_Y
			ld a,(hl)			;player
			call unit_abs_x
			sub (hl)			;robot
			cp 4
			ret nc
	
RFD0:
	; LDX	#28
			ld c,28
RFD1:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	RFD2
	; INX
	; CPX	#32
	; BNE	RFD1
	; RTS
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,RFD2
			inc c
			ld a,c
			cp 32
			jr nc,RFD1
			ret
	
RFD2:
	; LDA	#13	;pistol fire DOWN AI
	; STA	UNIT_TYPE,X
	; LDA	#244	;tile for horizontal weapons fire
	; JMP	ROLLERBOT_AFTER_FIRE

			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl), AI_PISTOL_DOWN	;pistol fire DOWN AI
			ld a, TILE_PISTOL_VERT	;tile for VERTICAL weapons fire
			;jp ROLLERBOT_AFTER_FIRE

ROLLERBOT_AFTER_FIRE:
	; STA	UNIT_TILE,X
	; LDA	#5		;travel distance.
	; STA	UNIT_A,X
	; LDA	#0		;weapon-type = pistol
	; STA	UNIT_B,X
	; STA	UNIT_TIMER_A,X
	; LDA	TEMP_A
	; STA	UNIT_LOC_X,X
	; LDA	TEMP_B
	; STA	UNIT_LOC_Y,X
	; LDA	#9		;PISTOL SOUND
	; JSR	PLAY_SOUND	;SOUND PLAY
	; RTS
			ld hl,UNIT_TILE
			call offc_abs_x
			ld (hl),a		;travel distance.
			ld hl,UNIT_A
			call offc_abs_x
			ld (hl),5		;weapon-type = pistol
			xor a
			ld hl,UNIT_B
			call offc_abs_x
			ld (hl),a
			ld hl,UNIT_TIMER_A
			call offc_abs_x
			ld (hl),a
			ld a,(TEMP_A)
			ld hl,UNIT_LOC_X
			call offc_abs_x
			ld (hl),a
			ld a,(TEMP_B)
			ld hl,UNIT_LOC_Y
			call offc_abs_x
			ld (hl),a
			ld a, SND_ROBOT_GUN
			jp PLAY_SOUND	;call:rts

ROLLERBOT_ANIMATE:
	; LDA	UNIT_TIMER_B,X
	; CMP	#0
	; BEQ	ROLAN2
	; DEC	UNIT_TIMER_B,X
	; RTS
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld a,(hl)
			or a
			jr z,ROLAN2
			dec (hl)
			ret
ROLAN2:
	; LDA	#3
	; STA	UNIT_TIMER_B,X	;RESET ANIMATE TIMER
	; LDA	UNIT_TILE,X
	; CMP	#164
	; BNE	ROLAN1
	; LDA	#165		;ROLLERBOT TILE
	; STA	UNIT_TILE,X
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; RTS
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld (hl),ROLLERBOT_ANIM_SPEED			;RESET ANIMATE TIMER
			ld hl,UNIT_TILE
			call unit_abs_x
			ld a,(hl)
			cp TILE_ROLLERBOT_A
			jr nz,ROLAN1
			ld (hl), TILE_ROLLERBOT_B			;ROLLERBOT TILE
			jp CHECK_FOR_WINDOW_REDRAW	;call:ret
	
ROLAN1:
	; LDA	#164		;ROLLERBOT TILE
	; STA	UNIT_TILE,X
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; RTS
			ld hl,UNIT_TILE
			call unit_abs_x
			ld (hl), TILE_ROLLERBOT_A		;ROLLERBOT TILE
			jp CHECK_FOR_WINDOW_REDRAW	;call:ret


;UNIT_A: 0=always active	1=only active when all robots are dead
;UNIT_B: 0=completes level 1=send to coordinates
;UNIT_C: X-coordinate
;UNIT_D: Y-coordinate

;The "DEMATERIALIZE" part of this AI routine has to be in the main 
;source for each individual computer, because the screen effects
;are created uniquely for each one.

TRANSPORTER_PAD:
	; LDX	UNIT
	; LDA	UNIT_LOC_X,X
	; CMP	UNIT_LOC_X
	; BNE	TRP01
	; LDA	UNIT_LOC_Y,X
	; CMP	UNIT_LOC_Y
	; BNE	TRP01
	; JMP	TRANS_PLAYER_PRESENT

			;first determine if the player is standing here
			ld hl,UNIT_LOC_X
			ld a,(hl)
			call unit_abs_x
			cp (hl)
			jr nz,TRP01
			ld hl,UNIT_LOC_Y
			ld a,(hl)
			call unit_abs_x
			cp (hl)
			jr nz,TRP01
			jp TRANS_PLAYER_PRESENT
	
TRP01:
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	TRP02
	; JMP	TRANS_ACTIVE

			;player not present
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			cp 1
			jp nz,TRANS_ACTIVE
	
TRP02:
	; LDX	#1
			;test if all robots are dead
			ld c,1
TRP03:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BNE	TRP04
	; INX
	; CPX	#28
	; BNE	TRP03
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,TRP04a
			cp AI_DEAD_ROBOT
			jr nz, TRP04
TRP04a:
			inc c
			ld a,c
			cp 28
			jr nz,TRP03
	; LDX	UNIT
	; LDA	#0
	; STA	UNIT_A,X	;make unit active
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),0		;make unit active
	
TRP04:
	; LDX	UNIT
	; LDA	#30
	; STA	UNIT_TIMER_A,X
	; JMP	AILP	
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),30
			jp AILP


TRANS_PLAYER_PRESENT:
	; LDX	UNIT
	; LDA	UNIT_A,X
	; CMP	#0	;unit active
	; BEQ	TRPL1
	; LDA	#<MSG_TRANS1
	; STA	$FB
	; LDA	#>MSG_TRANS1
	; STA	$FC
	; JSR	PRINT_INFO
	; LDA	#11		;error-SOUND
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT
	; LDA	#100
	; STA	UNIT_TIMER_A,X
	; JMP	AILP
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a			;unit active
			jr z,TRPL1
			ld hl,MSG_TRANS1
			call PRINT_INFO
			ld a, SND_ERROR			;error-SOUND
			call PLAY_SOUND
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),100
			jp AILP
	
TRPL1:
	; LDA	#23	;Convert to different AI
	; STA	UNIT_TYPE,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; LDA	#0
	; STA	UNIT_TIMER_B,X
	; JMP	AILP
			
			;start transport process
			ld a, TRUE
			ld (DISABLE_CONTROLS), a
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl), AI_DEMATERIALIZE	; Convert to different AI
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),5
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld (hl),0
			jp AILP

TRANS_ACTIVE:
	; LDA	UNIT_TIMER_B,X
	; CMP	#1
	; BEQ	TRAC1
	; LDA	#1
	; STA	UNIT_TIMER_B,X
	; LDA	#30
	; STA	TILE
	; JMP	TRAC2
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld a,(hl)
			cp 1
			jr z,TRAC1
			ld (hl),1
			ld a,30
			ld (TILE),a
			jp TRAC2
	
TRAC1:
	; LDA	#0
	; STA	UNIT_TIMER_B,X
	; LDA	#31
	; STA	TILE
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld (hl),0
			ld a,31
			ld (TILE),a
	
TRAC2:
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	PLOT_TILE_TO_MAP
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; LDA	#30
	; STA	UNIT_TIMER_A,X
	; JMP	AILP
			        
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call PLOT_TILE_TO_MAP
			call CHECK_FOR_WINDOW_REDRAW
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),30
			jp AILP

TIME_BOMB:
	; LDX	UNIT
	; LDA	UNIT_A,X
	; CMP	#0
	; BNE	TB01
	; JMP	BIG_EXP_PHASE1
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jp z,BIG_EXP_PHASE1
	
TB01:
	; CMP	#1
	; BNE	TB02
	; JMP	BIG_EXP_PHASE2
			cp 1
			jp z,BIG_EXP_PHASE2
TB02:
	; JMP	AILP
			jp AILP

;This is the large explosion used by the time-bomb
;and plasma gun, and maybe others.  This is the first
;phase of the explosion, which stores the tiles to
;a buffer and then changes each tile to an explosion.

BIG_EXP_PHASE1:
	; LDA	BIG_EXP_ACT
	; CMP	#0	;Check that no other explosion active.
	; BEQ	BEX001
	; LDX	UNIT
	; LDA	#10
	; STA	UNIT_TIMER_A,X
	; JMP	AILP	;wait for existing explosion to finish.
			ld a,(BIG_EXP_ACT)
			or a		;Check that no other explosion active.
			jr z,BEX001
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),10
			jp AILP		;wait for existing explosion to finish.
	
BEX001:
	; LDA	#1		;Set flag so no other explosions
	; STA	BIG_EXP_ACT	;can begin until this one ends.
	; STA	SCREEN_SHAKE
	; LDA	#0	;explosion-sound
	; JSR	PLAY_SOUND	;SOUND PLAY
	; JSR	BEX_PART1	;check center piece for unit
	; JSR	BEXCEN		;check center piece for unit
	; JSR	BEX1_NORTH
	; JSR	BEX1_SOUTH
	; JSR	BEX1_EAST
	; JSR	BEX1_WEST
	; JSR	BEX1_NE
	; JSR	BEX1_NW
	; JSR	BEX1_SE
	; JSR	BEX1_SW
	; LDX	UNIT
	; LDA	#246		;explosion tile
	; STA	UNIT_TILE,X
	; LDA	#1		;move to next phase of explosion.
	; STA	UNIT_A,X
	; LDA	#12
	; STA	UNIT_TIMER_A,X
	; LDA	#1
	; STA	REDRAW_WINDOW
	; JMP	AILP
			ld a,2
			ld (SCREEN_SHAKE),a
			ld a,1
			ld (BIG_EXP_ACT),a
			call BEX_PART1	;check center piece for unit
			call BEXCEN		;check center piece for unit

			ld ix,EXP_BUFFER	
			ld iy,BEX_DIR_DATA
			ld b,8
.l0
			push bc
			call BEX_PART1
			push ix
			push iy
			call BEX_STORE_TILE
			pop iy
			pop ix
			inc ix
			jr nz,.l1
			push ix
			push iy
			call BEX_STORE_TILE
			pop iy
			pop ix
.l1			
			inc ix
			pop bc
			inc iy
			djnz .l0

			ld hl,UNIT_TILE
			call unit_abs_x
			ld (hl),TILE_EXPLOSION		;explosion tile
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),1		;move to next phase of explosion.
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),BOMB_ANIM_DELAY
			ld a,TRUE
			ld (REDRAW_WINDOW),a
			call DRAW_MAP_WINDOW
			call draw_buffer
			ld a, SND_EXPLOSION			;explosion-sound
			call PLAY_SOUND
			jp AILP

BEX_PART1:
	; LDX	UNIT
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; RTS
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			ret

BEX_PART2:
	; JSR	GET_TILE_FROM_MAP
	; LDY	TILE
	; LDA	TILE_ATTRIB,Y
	; AND	#%00010000	;can see through tile?
	; CMP	#%00010000
	; RTS
			call GET_TILE_FROM_MAP
			ld hl,TILE_ATTRIB
			add a,l
			ld l,a
			jr nc,$+3
			inc h
			ld a,(hl)
			and %00010000	;can see through tile?
			cp %00010000
			ret

BEX_PART3:
	; LDA	#246
	; LDY	#0
	; STA	($FD),Y
			ld hl,(MAP_ADDR)
			ld (hl), TILE_EXPLOSION
	
BEXCEN:
	; JSR	CHECK_FOR_UNIT
	; LDA	UNIT_FIND
	; CMP	#255
	; BEQ	EPT2	
	; LDA	#11
	; STA	TEMP_A
	; JSR	INFLICT_DAMAGE
;EPT2:
	; RTS
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255
			ret z
			ld a,11
			ld (TEMP_A),a
			jp INFLICT_DAMAGE ; call:ret

BIG_EXP_PHASE2:
	;Do the center tile first.
	; JSR	BEX_PART1
	; JSR	GET_TILE_FROM_MAP
	; LDA	#246
	; STA	($FD),Y
	; LDA	TILE
	; STA	TEMP_A
	; JSR	RESTORE_TILE
			call BEX_PART1
			call GET_TILE_FROM_MAP
			ld hl,(MAP_ADDR)
			ld (hl), TILE_EXPLOSION
			ld (TEMP_A),a
			call RESTORE_TILE	
			
			ld ix,EXP_BUFFER	
			ld iy,BEX_DIR_DATA
			ld b,8
.l0
			push bc
			call BEX_PART1
			push ix
			push iy
			call BEX_RESTORE_TILE
			pop iy
			pop ix
			inc ix
			jr nz,.l1
			push ix
			push iy
			call BEX_RESTORE_TILE
			pop iy
			pop ix
.l1			
			inc ix
			pop bc
			inc iy
			djnz .l0
	
	; LDA	#1
	; STA	REDRAW_WINDOW
	; LDX	UNIT
	; LDA	#0
	; STA	UNIT_TYPE,X	;Deactivate this AI
	; STA	BIG_EXP_ACT
	; STA	SCREEN_SHAKE
	; JMP	AILP
	
			ld a,TRUE
			ld (REDRAW_WINDOW), a
			
			ld hl,UNIT_TYPE
			call unit_abs_x
			xor a
			ld (hl),a		;Deactivate this AI
			ld (BIG_EXP_ACT),a
			ld (SCREEN_SHAKE),a
			jp AILP



BEX_DIR_DATA:
			db %00000100	;tile #0,1 north
			db %00001000	;tile #2,3 south
			db %00000010	;tile #4,5 east
			db %00000001	;tile #6,7 west
			db %00000110	;tile #8,9 northeast
			db %00000101	;tile #10,11 northwest
			db %00001010	;tile #12,13 southeast
			db %00001001	;tile #14,15 southwest

BEX_TRACE:
			ld d,(iy)	;Pp00YyXx	P=part1 x=dec x X=inc x y=dec y Y=inc y
			ld hl,MAP_X
			bit 0,d
			jr z,.l0
			dec (hl)
.l0
			bit 1,d
			jr z,.l1
			inc (hl)
.l1
			ld hl,MAP_Y
			bit 2,d
			jr z,.l2
			dec (hl)
.l2
			bit 3,d
			jr z,.l3
			inc (hl)
.l3
			ret
			
BEX_STORE_TILE:
			
			call BEX_TRACE
			call BEX_PART2
			ret nz
			
			ld a,(TILE)
			ld (ix),a
			jp BEX_PART3	;call:ret


BEX_RESTORE_TILE:
			call BEX_TRACE
			ld a,(ix)
			ld (TEMP_A),a

RESTORE_TILE:
	; JSR	GET_TILE_FROM_MAP
	; LDA	TILE
	; CMP	#246
	; BEQ	REST0
	; RTS
			call GET_TILE_FROM_MAP
			cp TILE_EXPLOSION
			ret nz
	
REST0:
	; LDY	TEMP_A
	; CPY	#131	;Cannister tile
	; BEQ	REST3
	; LDA	TILE_ATTRIB,Y
	; AND	#%00001000	;can it be destroyed?
	; CMP	#%00001000
	; BNE	REST2
	; LDA	DESTRUCT_PATH,Y
	; LDY	#0
	; STA	($FD),Y
	; RTS
			ld a,(TEMP_A)
			cp TILE_CANNISTER	;Cannister tile
			jr z,REST3
			ld b,0
			ld c,a
			ld hl,TILE_ATTRIB
			add hl,bc
			ld a,(hl)
			and %00001000	;can it be destroyed?
			jr z,REST2
			ld hl,DESTRUCT_PATH
			add hl,bc
			ld a,(hl)
			ld hl,(MAP_ADDR)
			ld (hl),a
			xor a			;set Z flag
			ret
	
REST2:
	; LDA	TEMP_A
	; LDY	#0
	; STA	($FD),Y
	; RTS
			ld a,(TEMP_A)
			ld hl,(MAP_ADDR)
			ld (hl),a
			xor a			;set Z flag
			ret
	
REST3:
	; LDA	#135	;Blown cannister
	; LDY	#0
	; STA	($FD),Y
	; LDX	#28	;Start of weapons units
		
			;What to do if we encounter an explosive cannister
			ld a,TILE_BLOWN_CANNISTER		;Blown cannister
			ld hl,(MAP_ADDR)
			ld (hl),a
			ld c,28			;Start of weapons units
	
REST4:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	REST5
	; INX
	; CPX	#32
	; BNE	REST4
	; RTS	;no slots available right now, abort.
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,REST5
			inc c
			ld a,c
			cp 32
			jr nz,REST4
			xor a			;set Z flag
			ret			;no slots available right now, abort.
	
REST5:
	; LDA	#6	;bomb AI
	; STA	UNIT_TYPE,X
	; LDA	#131	;Cannister tile
	; STA	UNIT_TILE,X
	; LDA	MAP_X
	; STA	UNIT_LOC_X,X
	; LDA	MAP_Y
	; STA	UNIT_LOC_Y,X
	; LDA	#10		;How long until exposion?
	; STA	UNIT_TIMER_A,X
	; LDA	#0
	; STA	UNIT_A,X
	; RTS
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl),6			;bomb AI
			ld hl,UNIT_TILE
			call offc_abs_x
			ld (hl),TILE_CANNISTER			;Cannister tile
			ld hl,UNIT_LOC_X
			call offc_abs_x
			ld a,(MAP_X)
			ld (hl),a
			ld hl,UNIT_LOC_Y
			call offc_abs_x
			ld a,(MAP_Y)
			ld (hl),a
			ld hl,UNIT_TIMER_A
			call offc_abs_x
			ld (hl),CHAIN_EXPLODE_DELAY			;How long until exposion?
			ld hl,UNIT_A
			call offc_abs_x
			xor a			;set Z flag
			ld (hl),a
			ret
	

TRASH_COMPACTOR:
	; LDX	UNIT	
	; LDA	UNIT_A,X
	; CMP	#0	;OPEN
	; BNE	TRS01
	; JMP	TC_OPEN_STATE

; TRS01:
	; CMP	#1	;MID-CLOSING STATE
	; BNE	TRS02
	; JMP	TC_MID_CLOSING
	
; TRS02:
	; CMP	#2	;CLOSED STATE
	; BNE	TRS03
	; JMP	TC_CLOSED_STATE
	
; TRS03:
	; CMP	#3	;MID-OPENING STATE
	; BNE	TRS04
	; JMP	TC_MID_OPENING
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a				;OPEN
			jr z,TC_OPEN_STATE
			cp 1				;MID-CLOSING STATE
			jp z,TC_MID_CLOSING
			cp 2				;CLOSED STATE
			jp z,TC_CLOSED_STATE
			cp 3				;MID-OPENING STATE
			jp z,TC_MID_OPENING
	
TRS04:
	; JMP	AILP	;should never get here.	
			jp AILP
	
TC_OPEN_STATE:
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	GET_TILE_FROM_MAP
	; CMP	#148	;Usual tile for trash compactor danger zone
	; BNE	TRS15
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call GET_TILE_FROM_MAP
			cp TILE_TRASH_ZONE	;Usual tile for trash compactor danger zone
			jr nz,TRS15
	
TRS10:
	; INY	
	; LDA	($FD),Y
	; CMP	#148	;Usual tile for trash compactor danger zone
	; BNE	TRS15
	; LDA	#20
	; STA	UNIT_TIMER_A,X
			ld hl,(MAP_ADDR)
			inc hl
			ld a,(hl)
			cp TILE_TRASH_ZONE				;Usual tile for trash compactor danger zone
			jr nz,TRS15
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),20
	
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	CHECK_FOR_UNIT
	; LDA	UNIT_FIND
	; CMP	#255
	; BNE	TRS15
	; JMP	AILP	;Nothing found, do nothing.
	
			;now check for units in the compactor
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255
			jp z,AILP			;Nothing found, do nothing.
	
TRS15:
	; LDA	#146
	; STA	TCPIECE1
	; LDA	#147
	; STA	TCPIECE2
	; LDA	#150
	; STA	TCPIECE3
	; LDA	#151
	; STA	TCPIECE4
	; JSR	DRAW_TRASH_COMPACTOR
	; INC	UNIT_A,X
	; LDA	#10
	; STA	UNIT_TIMER_A,X	
	; LDA	#14		;door sound
	; JSR	PLAY_SOUND	;SOUND PLAY
	; JMP	AILP

			;Object has been detected in TC, start closing.
			ld a,#92	;146
			ld (TCPIECE1),a
			ld a,#93	;147
			ld (TCPIECE2),a
			ld a,#96	;150
			ld (TCPIECE3),a
			ld a,#97	;151
			ld (TCPIECE4),a
			call DRAW_TRASH_COMPACTOR
			ld hl,UNIT_A
			call unit_abs_x
			inc (hl)
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),COMPACTOR_2ND_DELAY
			ld a, SND_TRASH_CLOSE
			call PLAY_SOUND
			jp AILP


TC_MID_CLOSING:
	; LDA	#152
	; STA	TCPIECE1
	; LDA	#153
	; STA	TCPIECE2
	; LDA	#156
	; STA	TCPIECE3
	; LDA	#157
	; STA	TCPIECE4
	; JSR	DRAW_TRASH_COMPACTOR
	; INC	UNIT_A,X
	; LDA	#50
	; STA	UNIT_TIMER_A,X
			ld a,#98	;152
			ld (TCPIECE1),a
			ld a,#99	;153
			ld (TCPIECE2),a
			ld a,#9c	;156
			ld (TCPIECE3),a
			ld a,#9d	;157
			ld (TCPIECE4),a
			call DRAW_TRASH_COMPACTOR
			ld hl,UNIT_A
			call unit_abs_x
			inc (hl)
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),COMPACTOR_3RD_DELAY
	
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	CHECK_FOR_UNIT
	; LDA	UNIT_FIND
	; CMP	#255
	; BNE	TCMC1
	; INC	MAP_X	;check second tile
	; JSR	CHECK_FOR_UNIT
	; LDA	UNIT_FIND
	; CMP	#255
	; BNE	TCMC1
	; JMP	AILP
	
			;Now check for any live units in the compactor
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255
			jr nz,TCMC1
			ld hl,MAP_X	;check second tile
			inc (hl)
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255
			jp z,AILP
			;jr TCMC1
	
TCMC1:
	; LDA	#<MSG_TERMINATED
	; STA	$FB
	; LDA	#>MSG_TERMINATED
	; STA	$FC
	; JSR	PRINT_INFO
	; LDA	#0	;EXPLOSION sound
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT_FIND
	; LDA	#0
	; STA	UNIT_TYPE,X
	; STA	UNIT_HEALTH,X
	; LDX	#28	;start of weapons

			;Found unit in compactor, kill it.
			ld hl,MSG_TERMINATED
			call PRINT_INFO
			ld a, SND_EXPLOSION		;EXPLOSION sound
			call PLAY_SOUND
			ld a,(UNIT_FIND)
			ld c,a
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl),0
			ld hl,UNIT_HEALTH
			call offc_abs_x
			ld (hl),0
			ld c,28			;start of weapons
	
TCMC2:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	TCMC3
	; INX
	; CPX	#32
	; BNE	TCMC2
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,TCMC3
			inc c
			ld a,c
			cp 32
			jr nz,TCMC2
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
TCMC3:
	; LDA	#11	;SMALL EXPLOSION
	; STA	UNIT_TYPE,X
	; LDA	#248	;first tile for explosion
	; STA	UNIT_TILE,X
	; LDY	UNIT
	; LDA	UNIT_LOC_X,Y
	; STA	UNIT_LOC_X,X
	; LDA	UNIT_LOC_Y,Y
	; STA	UNIT_LOC_Y,X
	; LDA	UNIT_FIND
	; CMP	#0	;is it the player?
	; BNE	TCMC4
	; LDA	#10
	; STA	BORDER
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl),11			;SMALL EXPLOSION
			ld hl,UNIT_TILE
			call offc_abs_x
			ld (hl),248			;first tile for explosion
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_LOC_X
			call offc_abs_x
			ld (hl),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_LOC_Y
			call offc_abs_x
			ld (hl),a
			ld a,(UNIT_FIND)
			or a				;is it the player?
			jr nz,TCMC4
			call DISPLAY_PLAYER_HEALTH
			ld a,SND_PLAYER_DOWN
			call PLAY_SOUND
			ld a,10
			ld (BORDER_FLASH),a
	
TCMC4:
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
	jp AILP_CHECK_FOR_WINDOW_REDRAW

TC_CLOSED_STATE:
	; LDA	#146
	; STA	TCPIECE1
	; LDA	#147
	; STA	TCPIECE2
	; LDA	#150
	; STA	TCPIECE3
	; LDA	#151
	; STA	TCPIECE4
	; JSR	DRAW_TRASH_COMPACTOR
	; INC	UNIT_A,X
	; LDA	#10
	; STA	UNIT_TIMER_A,X	
	; JMP	AILP
			ld a,#92	;146
			ld (TCPIECE1),a
			ld a,#93	;147
			ld (TCPIECE2),a
			ld a,#96	;150
			ld (TCPIECE3),a
			ld a,#97	;151
			ld (TCPIECE4),a
			call DRAW_TRASH_COMPACTOR
			ld hl,UNIT_A
			call unit_abs_x
			inc (hl)
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),COMPACTOR_2ND_DELAY
			jp AILP

TC_MID_OPENING:
	; LDA	#144
	; STA	TCPIECE1
	; LDA	#145
	; STA	TCPIECE2
	; LDA	#148
	; STA	TCPIECE3
	; LDA	#148
	; STA	TCPIECE4
	; JSR	DRAW_TRASH_COMPACTOR	
	; LDA	#0
	; STA	UNIT_A,X
	; LDA	#20
	; STA	UNIT_TIMER_A,X
	; LDA	#14		;door sound
	; JSR	PLAY_SOUND	;SOUND PLAY	
	; JMP	AILP
			ld a,#90	;144
			ld (TCPIECE1),a
			ld a,#91	;145
			ld (TCPIECE2),a
			ld a,#94	;148
			ld (TCPIECE3),a
			ld a,#94	;148
			ld (TCPIECE4),a
			call DRAW_TRASH_COMPACTOR	
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),0
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),COMPACTOR_COOLDOWN
			ld a, SND_TRASH_OPEN
			call PLAY_SOUND
			jp AILP

DRAW_TRASH_COMPACTOR:
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; DEC	MAP_Y	;start one tile above
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	TCPIECE1
	; STA	TILE
	; JSR	PLOT_TILE_TO_MAP
	; INY
	; LDA	TCPIECE2
	; STA	($FD),Y	
	; TYA
	; CLC
	; ADC	#127
	; TAY
	; LDA	TCPIECE3
	; STA	($FD),Y
	; LDA	TCPIECE4
	; INY	
	; STA	($FD),Y
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; RTS
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			dec a				;start one tile above
			ld (MAP_Y),a
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld a,(TCPIECE1)
			ld (TILE),a
			call PLOT_TILE_TO_MAP
			ld hl,(MAP_ADDR)
			inc hl
			ld a,(TCPIECE2)
			ld (hl),a
			ld bc,127
			add hl,bc
			ld a,(TCPIECE3)
			ld (hl),a
			inc hl
			ld a,(TCPIECE4)
			ld (hl),a
			jp CHECK_FOR_WINDOW_REDRAW		;call:ret
	
; TCPIECE1:	!BYTE 00
; TCPIECE2:	!BYTE 00
; TCPIECE3:	!BYTE 00
; TCPIECE4:	!BYTE 00
TCPIECE1:		db 0
TCPIECE2:		db 0
TCPIECE3:		db 0
TCPIECE4:		db 0


WATER_DROID:
	; LDX	UNIT
	; INC	UNIT_TILE,X
	; LDA	UNIT_TILE,X
	; CMP	#143
	; BNE	WD01
	; LDA	#140
	; STA	UNIT_TILE,X

			;first rotate the tiles
			ld hl,UNIT_TILE
			call unit_abs_x
			inc (hl)
			ld a,(hl)
			cp TILE_WATERDROID_END
			jr nz,WD01
			ld (hl), TILE_WATERDROID_BEGIN
	
WD01:
	; DEC	UNIT_A,X
	; LDA	UNIT_A,X
	; CMP	#0
	; BEQ	WD02
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jp z,AILP_CHECK_FOR_WINDOW_REDRAW
	
WD02:
	; LDA	#08	;Dead robot type
	; STA	UNIT_TYPE,X
	; LDA	#255
	; STA	UNIT_TIMER_A,X
	; LDA	#115	;dead robot tile
	; STA	UNIT_TILE,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			;kill unit after countdown reaches zero. 
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),AI_DEAD_ROBOT			;Dead robot type
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),255
			ld hl,UNIT_TILE
			call unit_abs_x
			ld (hl),TILE_DEAD_ROBOT			;dead robot tile
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
PISTOL_FIRE_UP:
	; LDX	UNIT	
	; LDA	UNIT_A,X
	; CMP	#0
	; BNE	PFU02
	
			;Check if it has reached limits.
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,PFU02
	
	; JSR	DEACTIVATE_WEAPON
	; JMP	PFU05

			;if it has reached max range, then it vanishes.
			call DEACTIVATE_WEAPON
			;jr PFU05
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
PFU02:
	; DEC	UNIT_LOC_Y,X	;move it up one.
	; JMP	PISTOL_AI_COMMON
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			dec (hl)				;move it up one.
			jr PISTOL_AI_COMMON
	
;PFU05:
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
;	jp AILP_CHECK_FOR_WINDOW_REDRAW

PISTOL_FIRE_DOWN:
	;Check if it has reached limits.
	; LDX	UNIT	
	; LDA	UNIT_A,X
	; CMP	#0
	; BNE	PFD02
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,PFD02
	
	; JSR	DEACTIVATE_WEAPON
	; JMP	PFD05

			;if it has reached max range, then it vanishes.
			call DEACTIVATE_WEAPON
			;jr PFD05
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
PFD02:
	; INC	UNIT_LOC_Y,X	;move it down one.
	; JMP	PISTOL_AI_COMMON
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			inc (hl)				;move it down one.
			jr PISTOL_AI_COMMON
	
;PFD05:
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
;	jp AILP_CHECK_FOR_WINDOW_REDRAW

PISTOL_FIRE_LEFT:
	; LDX	UNIT	
	; LDA	UNIT_A,X
	; CMP	#0
	; BNE	PFL02

			;Check if it has reached limits.
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,PFL02
	
	; JSR	DEACTIVATE_WEAPON
	; JMP	PFL05

			;if it has reached max range, then it vanishes.
			call DEACTIVATE_WEAPON
			;jr PFL05
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
PFL02:
	; DEC	UNIT_LOC_X,X	;move it left one.
	; JMP	PISTOL_AI_COMMON
			ld hl,UNIT_LOC_X
			call unit_abs_x
			dec (hl)				;move it left one.
			jr PISTOL_AI_COMMON
	
;PFL05:
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
;	jp AILP_CHECK_FOR_WINDOW_REDRAW

PISTOL_FIRE_RIGHT:
	; LDX	UNIT	
	; LDA	UNIT_A,X
	; CMP	#0
	; BNE	PFR02

			;Check if it has reached limits.
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,PFR02
	
	; JSR	DEACTIVATE_WEAPON
	; JMP	PFR05

			;if it has reached max range, then it vanishes.
			call DEACTIVATE_WEAPON
			;jr PFR05
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
PFR02:
	; INC	UNIT_LOC_X,X	;move it right one.
	; JMP	PISTOL_AI_COMMON
			ld hl,UNIT_LOC_X
			call unit_abs_x
			inc (hl)				;move it right one.
			jr PISTOL_AI_COMMON
	
;PFR05:
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
;	jp AILP_CHECK_FOR_WINDOW_REDRAW

DEACTIVATE_WEAPON:
	; LDA	#0
	; STA	UNIT_TYPE,X
	; LDA	UNIT_B,X
	; CMP	#1
	; BNE	DEW1
	; LDA	#0
	; STA	UNIT_B,X
	; STA	PLASMA_ACT
; DEW1:
	; RTS
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),0
			ld hl,UNIT_B
			call unit_abs_x
			ld a,(hl)
			cp 1
			ret nz
			xor a
			ld (hl),a
			ld (PLASMA_ACT),a
			ret

PISTOL_AI_COMMON:
	; LDA	UNIT_B,X	;is it pistol or plasma?
	; CMP	#0
	; BEQ	PAIC02
	; JMP	PLASMA_AI_COMMON
			ld hl,UNIT_B
			call unit_abs_x
			ld a,(hl)
			or a				;is it pistol or plasma?
			jp nz,PLASMA_AI_COMMON
	
PAIC02:
	; DEC	UNIT_A,X	;reduce range by one
			ld hl,UNIT_A
			call unit_abs_x
			dec (hl)			;reduce range by one
	
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	GET_TILE_FROM_MAP
	; LDY	TILE
	; CMP	#131	;explosive cannister
	; BNE	PAIC04

			;Now check what map object it is on.
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call GET_TILE_FROM_MAP
			cp TILE_CANNISTER		;explosive cannister
			jr nz,PAIC04	;uses A further
	
	; LDA	#135	;Blown cannister
	; LDY	#0
	; STA	($FD),Y
	; LDX	UNIT
	; LDA	#6	;bomb AI
	; STA	UNIT_TYPE,X
	; LDA	#131	;Cannister tile
	; STA	UNIT_TILE,X
	; LDA	MAP_X
	; STA	UNIT_LOC_X,X
	; LDA	MAP_Y
	; STA	UNIT_LOC_Y,X
	; LDA	#5		;How long until exposion?
	; STA	UNIT_TIMER_A,X
	; LDA	#0
	; STA	UNIT_A,X
	; JMP	AILP

			;hit an explosive cannister
			ld hl,(MAP_ADDR)
			ld (hl),TILE_BLOWN_CANNISTER	;Blown cannister
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),AI_BOMB		;bomb AI
			ld hl,UNIT_TILE
			call unit_abs_x
			ld (hl),TILE_CANNISTER		;Cannister tile
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(MAP_X)
			ld (hl),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(MAP_Y)
			ld (hl),a
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),5		;How long until exposion?
			ld hl,UNIT_A
			call unit_abs_x
			ld (hl),0
			jp AILP

PAIC04:
	; LDA	TILE_ATTRIB,Y
	; ;AND 	#%00000010	;Check, can hover on this?
	; ;CMP	#%00000010
	; AND 	#%00010000	;can see through tile?
	; CMP	#%00010000
	; BEQ	PAIC05
			ld hl,TILE_ATTRIB
			add a,l
			ld l,a
			jr nc,$+3
			inc h
			ld a,(hl)
			and %00010000	;can see through tile?
			jr nz,PAIC05
			
			ld a,SND_WALL_HIT
			call PLAY_SOUND
	; LDA	#11	;SMALL EXPLOSION
	; STA	UNIT_TYPE,X
	; LDA	#248	;first tile for explosion
	; STA	UNIT_TILE,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP

			;Hit object that can't pass through, convert to explosion
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),11		;SMALL EXPLOSION
			ld hl,UNIT_TILE
			call unit_abs_x
			ld (hl),248		;first tile for explosion
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
PAIC05:
	; JSR	CHECK_FOR_UNIT
	; LDA	UNIT_FIND
	; CMP	#255	;NO UNIT ENCOUNTERED.
	; BNE	PAIC06
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP

			;check if it encountered a robot/human
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255			;NO UNIT ENCOUNTERED.
			jp z,AILP_CHECK_FOR_WINDOW_REDRAW

PAIC06:
	; LDX	UNIT
	; LDA	#11	;SMALL EXPLOSION
	; STA	UNIT_TYPE,X
	; LDA	#248	;first tile for explosion
	; STA	UNIT_TILE,X
	; LDA	#1	;set damage for pistol
	; STA	TEMP_A	
	; JSR	INFLICT_DAMAGE
	; JSR	ALTER_AI
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
		
			;struck a robot/human
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),AI_SMALL_EXPLOSION	;SMALL EXPLOSION
			ld hl,UNIT_TILE
			call unit_abs_x
			ld (hl),248		;first tile for explosion
			ld a,1			;set damage for pistol
			ld (TEMP_A),a
			call INFLICT_DAMAGE
			call ALTER_AI
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	

PLASMA_AI_COMMON:
	; DEC	UNIT_A,X	;reduce range by one
			ld hl,UNIT_A
			call unit_abs_x
			dec (hl)		;reduce range by one
	
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	GET_TILE_FROM_MAP
	; LDY	TILE
	; CPY	#131	;cannister tile
	; BEQ	PLAI11
	; LDA	TILE_ATTRIB,Y
	; AND 	#%00010000	;can see through tile?
	; CMP	#%00010000
	; BEQ	PLAI05
	; JMP	PLAI11

			;find what tile we are over
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call GET_TILE_FROM_MAP
			cp TILE_CANNISTER			;cannister tile
			jr z,PLAI11
			ld hl,TILE_ATTRIB
			add a,l
			ld l,a
			jr nc,$+3
			inc h
			ld a,(hl)
			and %00010000	;can see through tile?
			jr z,PLAI11
			; jr PLAI05

PLAI05:
	; JSR	CHECK_FOR_UNIT
	; LDA	UNIT_FIND
	; CMP	#255	;NO UNIT ENCOUNTERED.
	; BNE	PLAI11

			;check if it encountered a human/robot
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255		;NO UNIT ENCOUNTERED.
			;jr nz,PLAI11
			jp z,AILP_CHECK_FOR_WINDOW_REDRAW
	
;PLAI10:
	;no impacts detected:
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
;	jp AILP_CHECK_FOR_WINDOW_REDRAW
	
PLAI11:
	; LDX	UNIT
	; LDA	#6	;bomb AI
	; STA	UNIT_TYPE,X
	; LDA	#1		;How long until exposion?
	; STA	UNIT_TIMER_A,X
	; LDA	#0
	; STA	UNIT_A,X
	; STA	PLASMA_ACT
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP

			;impact detected. convert to explosion
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),AI_BOMB		;bomb AI
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),1		;How long until exposion?
			ld hl,UNIT_A
			call unit_abs_x
			xor a
			ld (hl),a
			ld (PLASMA_ACT),a
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
;This routine checks to see if the robot being shot
;is a hoverbot, if so it will alter it's AI to attack 
;mode.
ALTER_AI:
	; LDX	UNIT_FIND
	; LDA	UNIT_TYPE,X
	; CMP	#2	;hoverbot left/right
	; BEQ	ATKMOD
	; CMP	#3	;hoverbot UP/DOWN
	; BEQ	ATKMOD
	; RTS
			ld a,(UNIT_FIND)
			ld c,a
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			cp AI_DROID_LEFT_RIGHT 			;hoverbot left/right
			jr z,ATKMOD
			cp AI_DROID_UP_DOWN			;hoverbot UP/DOWN
			jr z,ATKMOD
			ret
	
ATKMOD:
	; LDA	#4	;Attack AI
	; STA	UNIT_TYPE,X
	; RTS
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl), AI_HOVER_ATTACK		;Attack AI
			ret

	

;This routine will inflict damage on whatever is defined in
;UNIT_FIND in the amount set in TEMP_A.  If the damage is more
;than the health of that unit, it will delete the unit.
INFLICT_DAMAGE:
	; LDX	UNIT_FIND
	; LDA	UNIT_HEALTH,X
	; SEC
	; SBC	TEMP_A
	; STA	UNIT_HEALTH,X
	; BCC	UNIT_DEAD
	; CMP	#0
	; BEQ	UNIT_DEAD
	; CPX	#0	;IS IT THE PLAYER?
	; BNE	IND1
	; JSR	DISPLAY_PLAYER_HEALTH
	; LDA	#10
	; STA	BORDER
; IND1:
	; RTS
			ld a,(UNIT_FIND)
			or a
			jr z,INFLICT_DAMAGE_PLAYER
	
INFLICT_DAMAGE_UNIT:

			ld c,a
			ld hl,UNIT_HEALTH
			call offc_abs_x
			ld a,(TEMP_A)
			ld b,a
			ld a,(hl)
			sub b
			ld (hl),a
			jr z,UNIT_DEAD
			jr c,UNIT_DEAD

			ld a,SND_ROBOT_HIT
			jp PLAY_SOUND_D	;call:ret
	
UNIT_DEAD:
	; LDA	#0
	; STA	UNIT_HEALTH,X
	; CPX	#0	;Is it the player that is dead?
	; BEQ	UD01
	; LDA	#08	;Dead robot type
	; CMP	UNIT_TYPE,X	;is it a dead robot already?
	; BEQ	UD0A
	; STA	UNIT_TYPE,X
	; LDA	#255
	; STA	UNIT_TIMER_A,X
	; LDA	#115	;dead robot tile
	; STA	UNIT_TILE,X
; UD0A:
	; RTS
			ld hl,UNIT_HEALTH
			call offc_abs_x
			ld (hl),0
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld b, AI_DEAD_ROBOT				;Dead robot type
			ld a,(hl)
			cp b				;is it a dead robot already?
			jr z,UD0A_
			ld (hl),b
			ld hl,UNIT_TIMER_A
			call offc_abs_x
			ld (hl),DEAD_ROBOT_TIMEOUT
			ld hl,UNIT_TILE
			call offc_abs_x
			ld (hl),TILE_DEAD_ROBOT			;dead robot tile
			
			ld a,SND_ROBOT_DOWN
			jp PLAY_SOUND_D		;call:ret
UD0A_
			ld a,SND_WALL_HIT
			jp PLAY_SOUND_D		;call:ret
	
	
INFLICT_DAMAGE_PLAYER:
	
			ld a,(UNIT_HEALTH)		;don't hurt killed player
			or a
			ret z

			call CREATE_PLAYER_EXPLOSION
			call CALCULATE_AND_REDRAW
			call DRAW_MAP_WINDOW
			call draw_buffer
			
			; Now PLAY_SOUND will blink a border
		ifdef OPT_COLOR
			ld a,COLOR_RED
		else
			ld a,(SCREEN_COLOR)
			and 7
			or COLOR_BLACK
		endif
			ld (sfxBorderColor), a
					
			ld a,(UNIT_HEALTH)
			or a
			ld a, SND_PLAYER_DOWN
			jr z,$+4
			ld a, SND_ELECTRIC
			call PLAY_SOUND_D
								
			ld c,0
			ld hl,UNIT_HEALTH
			call offc_abs_x
			ld a,(TEMP_A)
			ld b,a
			ld a,(hl)
			sub b
			ld (hl),a
			jr z,PLAYER_DOWN
			jr c,PLAYER_DOWN
			
			ld a, 10
			ld (BORDER_FLASH), a

			jp DISPLAY_PLAYER_HEALTH		;call:ret

PLAYER_DOWN:

			xor a
			ld (UNIT_HEALTH),a
			ld (UNIT_TYPE),a
			ld a,SND_PLAYER_DOWN
			call PLAY_SOUND
			call DISPLAY_PLAYER_HEALTH
			jp draw_buffer				;call:ret
	
	
SMALL_EXPLOSION:
	; LDA	#0
	; STA	UNIT_TIMER_A,X
	; INC	UNIT_TILE,X
	; LDA	UNIT_TILE,X
	; CMP	#252
	; BEQ	SEXP1
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),0
			ld hl,UNIT_TILE
			call unit_abs_x
			inc (hl)
			ld a,(hl)
			cp 252
			jp nz,AILP_CHECK_FOR_WINDOW_REDRAW
	
SEXP1:
	; LDA	#0
	; STA	UNIT_TYPE,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP		
			ld hl,UNIT_TYPE
			call unit_abs_x
			ld (hl),0
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
HOVER_ATTACK:
	; LDX	UNIT
			ld a, (UNIT)
			ld e, a
			ld d, 0
	; LDA	#0
	; STA	UNIT_TIMER_B,X
	; JSR	HOVERBOT_ANIMATE
	; LDA	#7
	; STA	UNIT_TIMER_A,X
	; LDA	#%00000010	;HOVER
	; STA	MOVE_TYPE
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld (hl),0
			call HOVERBOT_ANIMATE
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),HOVERBOT_ATTACK_SPD
			ld a, %00000010		;HOVER
			ld (MOVE_TYPE),a
	
	; LDA	UNIT_LOC_X,X
	; CMP	UNIT_LOC_X
	; BEQ	HOAT13
	; BCC	HOAT12
	; JSR	REQUEST_WALK_LEFT
	; JMP	HOAT13

			;CHECK FOR HORIZONTAL MOVEMENT
			;ld hl,UNIT_LOC_X
			;call unit_abs_x
			;ld a,(hl)
			LDA_HL_X UNIT_LOC_X
			ld hl,UNIT_LOC_X
			cp (hl)
			jr z,HOAT13
			jr c,HOAT12
			call REQUEST_WALK_LEFT
			jr HOAT13
	
HOAT12:
	; JSR	REQUEST_WALK_RIGHT
			call REQUEST_WALK_RIGHT
	
HOAT13:
	;NOW CHECK FOR VERITCAL MOVEMENT
	; LDA	UNIT_LOC_Y,X
	; CMP	UNIT_LOC_Y
	; BEQ	HOAT20
	; BCC	HOAT14
	; JSR	REQUEST_WALK_UP
	; JMP	HOAT20
			;ld hl,UNIT_LOC_Y
			;call unit_abs_x
			;ld a,(hl)
			LDA_HL_X UNIT_LOC_Y

			ld hl,UNIT_LOC_Y
			cp (hl)
			jr z,HOAT20
			jr c,HOAT14
			call REQUEST_WALK_UP
			jr HOAT20
	
HOAT14:
	; JSR	REQUEST_WALK_DOWN	
			call REQUEST_WALK_DOWN
	
HOAT20:
	; JSR	ROBOT_ATTACK_RANGE
	; LDA	PROX_DETECT
	; CMP	#1	;1=Robot next to player 0=not
	; BNE	HOAT21	
	; LDA	#1	;amount of damage it will inflict
	; STA	TEMP_A	
	; LDA	#0	;unit to inflict damage on.
	; STA	UNIT_FIND
	; JSR	INFLICT_DAMAGE
	; JSR	CREATE_PLAYER_EXPLOSION
	; LDA	#07		;electric shock
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT
	; LDA	#30		;rate of attack on player.
	; STA	UNIT_TIMER_A,X
			call ROBOT_ATTACK_RANGE
			;ld a,(PROX_DETECT)
			or a					;1=Robot next to player 0=not
			jr z,HOAT21	
			ld a,1					;amount of damage it will inflict
			ld (TEMP_A),a
			xor a					;unit to inflict damage on.
			ld (UNIT_FIND),a
			call INFLICT_DAMAGE
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),30				;rate of attack on player.
	
	;add some code here to create explosion
HOAT21:
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			jp AILP_CHECK_FOR_WINDOW_REDRAW

CREATE_PLAYER_EXPLOSION:
	; LDX	#28
			ld c,28
TE01:
	; LDA	UNIT_TYPE,X
	; CMP	#0
	; BEQ	TE02
	; INX
	; CPX	#32	;max unit for weaponsfire
	; BNE	TE01	
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld a,(hl)
			or a
			jr z,TE02
			inc c
			ld a,c
			cp 32			;max unit for weaponsfire
			jr nz,TE01
			ret				;sh8bit -- seems kinda like a bug, explosion shouldn't be added when there is no free slot
			
	
TE02:
	; LDA	#11	;Small explosion AI type
	; STA	UNIT_TYPE,X
	; LDA	#248	;first tile for explosion
	; STA	UNIT_TILE,X
	; LDA	#1
	; STA	UNIT_TIMER_A,X
	; LDA	UNIT_LOC_X
	; STA	UNIT_LOC_X,X
	; LDA	UNIT_LOC_Y
	; STA	UNIT_LOC_Y,X
	; RTS	
			ld hl,UNIT_TYPE
			call offc_abs_x
			ld (hl),AI_SMALL_EXPLOSION			;Small explosion AI type
			ld hl,UNIT_TILE
			call offc_abs_x
			ld (hl),248			;first tile for explosion
			ld hl,UNIT_TIMER_A
			call offc_abs_x
			ld (hl),1
			ld hl,UNIT_LOC_X
			call offc_abs_x
			ld a,(UNIT_LOC_X)
			ld (hl),a
			ld hl,UNIT_LOC_Y
			call offc_abs_x
			ld a,(UNIT_LOC_Y)
			ld (hl),a
			ret

EVILBOT:
	; LDX	UNIT
	; LDA	#5
	; STA	UNIT_TIMER_A,X
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),EVILBOT_ANIM_SPD
	
	;first animate evilbot
	; LDA	UNIT_TILE,X
	; CMP	#100
	; BNE	EVIL1
	; INC	UNIT_TILE,X
	; JMP	EVIL10
			ld hl,UNIT_TILE
			call unit_abs_x
			ld a,(hl)
			cp TILE_EVILBOT_A
			jr nz,EVIL1
			inc (hl)
			jr EVIL10
	
EVIL1:
	; CMP	#101
	; BNE	EVIL2
	; INC	UNIT_TILE,X
	; JMP	EVIL10
			cp TILE_EVILBOT_B
			jr nz,EVIL2
			inc (hl)
			jr EVIL10
	
EVIL2:
	; CMP	#102
	; BNE	EVIL3
	; INC	UNIT_TILE,X
	; JMP	EVIL10
			cp TILE_EVILBOT_C
			jr nz,EVIL3
			inc (hl)
			jr EVIL10
	
EVIL3:
	; LDA	#100
	; STA	UNIT_TILE,X
			ld hl,UNIT_TILE
			call unit_abs_x
			ld (hl),TILE_EVILBOT_A
	
EVIL10:
	;now figure out movement
	; LDA	UNIT_TIMER_B,X
	; CMP	#0
	; BEQ	EVIL11
	; DEC	UNIT_TIMER_B,X
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld a,(hl)
			or a
			jr z,EVIL11
			dec (hl)
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
EVIL11:
	; LDA	#1	;Reset timer B
	; STA	UNIT_TIMER_B,X
	; LDA	#%00000001	;WALK
	; STA	MOVE_TYPE
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld (hl),1			;Reset timer B
			ld a, %00000001		;WALK
			ld (MOVE_TYPE),a
	
	;CHECK FOR HORIZONTAL MOVEMENT
	; LDA	UNIT_LOC_X,X
	; CMP	UNIT_LOC_X
	; BEQ	EVIL13
	; BCC	EVIL12
	; JSR	REQUEST_WALK_LEFT
	; JMP	EVIL13

			ld a, (UNIT)
			ld e, a
			ld d, 0

			LDA_HL_X UNIT_LOC_X
			ld hl,UNIT_LOC_X
			cp (hl)
			jr z,EVIL13
			jr c,EVIL12
			call REQUEST_WALK_LEFT
			jr EVIL13
	
EVIL12:
	; JSR	REQUEST_WALK_RIGHT
			call REQUEST_WALK_RIGHT
	
EVIL13:
	; LDA	UNIT_LOC_Y,X
	; CMP	UNIT_LOC_Y
	; BEQ	EVIL20
	; BCC	EVIL14
	; JSR	REQUEST_WALK_UP
	; JMP	EVIL20
			;NOW CHECK FOR VERITCAL MOVEMENT
			LDA_HL_X UNIT_LOC_Y
			ld hl,UNIT_LOC_Y
			cp (hl)
			jr z,EVIL20
			jr c,EVIL14
			call REQUEST_WALK_UP
			jr EVIL20
	
	
EVIL14:
	; JSR	REQUEST_WALK_DOWN	
			call REQUEST_WALK_DOWN
	
EVIL20:
	; JSR	ROBOT_ATTACK_RANGE
	; LDA	PROX_DETECT
	; CMP	#1	;1=Robot next to player 0=not
	; BNE	EVIL21	
	; LDA	#5	;amount of damage it will inflict
	; STA	TEMP_A	
	; LDA	#0	;unit to inflict damage on.
	; STA	UNIT_FIND
	; JSR	INFLICT_DAMAGE
	; JSR	CREATE_PLAYER_EXPLOSION
	; LDA	#07		;electric shock sound
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT
	; LDA	#15		;rate of attack on player.
	; STA	UNIT_TIMER_A,X
			call ROBOT_ATTACK_RANGE
			;ld a,(PROX_DETECT)
			or a					;1=Robot next to player 0=not
			jr z,EVIL21	
			ld a,5					;amount of damage it will inflict
			ld (TEMP_A),a
			xor a						;unit to inflict damage on.
			ld (UNIT_FIND),a
			call INFLICT_DAMAGE
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),15				;rate of attack on player.
	
EVIL21:
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			jp AILP_CHECK_FOR_WINDOW_REDRAW

;This routine handles automatic sliding doors.
;UNIT_B register means:
;0=opening-A 1=opening-B 2=OPEN 3=closing-A 4=closing-B 5-CLOSED
AI_DOOR:
	; LDX	UNIT
	; LDA	UNIT_B,X
	; CMP	#06	;make sure number is in bounds
	; BCS	DOORA
	; TAY
	; LDA	AIDB_L,Y
	; STA	DOORJ+1
	; LDA	AIDB_H,Y
	; STA	DOORJ+2
; DOORJ:	JMP	$0000	;self modifying code
; DOORA:	JMP	AILP	;-SHOULD NEVER NEED TO HAPPEN
			ld hl,UNIT_B
			call unit_abs_x
			ld a,(hl)
			cp 6				;make sure number is in bounds
			jp nc,AILP			;-SHOULD NEVER NEED TO HAPPEN
			ld hl,AIDB
			add a,a
			add a,l
			ld l,a
			jr nc,$+3
			inc h
			ld a,(hl)
			inc hl
			ld h,(hl)
			ld l,a
			jp (hl)				;no self modifying code
	
AIDB:	
			dw DOOR_OPEN_A
			dw DOOR_OPEN_B
			dw DOOR_OPEN_FULL
			dw DOOR_CLOSE_A
			dw DOOR_CLOSE_B
			dw DOOR_CLOSE_FULL

DOOR_OPEN_A:
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	DOA1
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,DOA1
	
	; LDA	#88
	; STA	DOORPIECE1
	; LDA	#89
	; STA	DOORPIECE2
	; LDA	#86
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; JMP	DOA2
			;HORIZONTAL DOOR
			ld a,#58	;88
			ld (DOORPIECE1),a
			ld a,#59	;89
			ld (DOORPIECE2),a
			ld a,#56	;86
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			jr DOA2
	
DOA1:
	; LDA	#70
	; STA	DOORPIECE1
	; LDA	#74
	; STA	DOORPIECE2
	; LDA	#78
	; STA	DOORPIECE3
	; JSR	DRAW_VERTICAL_DOOR
			;VERTICAL DOOR
			ld a,#46	;70
			ld (DOORPIECE1),a
			ld a,#4a	;74
			ld (DOORPIECE2),a
			ld a,#4e	;78
			ld (DOORPIECE3),a
			call DRAW_VERTICAL_DOOR
	
DOA2:

	; LDY	UNIT		;sh8bit -- seems to be a but, LDX intended?
	; LDA	#1
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),1
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW

DOOR_OPEN_B:
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	DOB1
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,DOB1
	
	; LDA	#17
	; STA	DOORPIECE1
	; LDA	#09
	; STA	DOORPIECE2
	; LDA	#91
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; JMP	DOB2
			;HORIZONTAL DOOR
			ld a,#11	;17
			ld (DOORPIECE1),a
			ld a,#09	;9
			ld (DOORPIECE2),a
			ld a,#5b	;91
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			jr DOB2
	
DOB1:
	; LDA	#27
	; STA	DOORPIECE1
	; LDA	#09
	; STA	DOORPIECE2
	; LDA	#15
	; STA	DOORPIECE3
	; JSR	DRAW_VERTICAL_DOOR
			;VERTICAL DOOR
			ld a,#1b	;27
			ld (DOORPIECE1),a
			ld a,#09	;9
			ld (DOORPIECE2),a
			ld a,#0f	;15
			ld (DOORPIECE3),a
			call DRAW_VERTICAL_DOOR
	
DOB2:
	; LDX	UNIT
	; LDA	#2
	; STA	UNIT_B,X
	; LDA	#30
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),2
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),OPENED_DOOR_DELAY
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
DOOR_OPEN_FULL:
	; LDX	UNIT
	; JSR	DOOR_CHECK_PROXIMITY	
	; LDA	PROX_DETECT
	; CMP	#1
	; BNE	DOF1
	; LDA	#30
	; STA	UNIT_TIMER_B,X	;RESET TIMER
	; JMP	AILP
			call DOOR_CHECK_PROXIMITY
			;ld a,(PROX_DETECT)
			or a
			jr z,DOF1
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld (hl),OPENED_DOOR_DELAY				;RESET TIMER
			jp AILP
	
DOF1:
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	GET_TILE_FROM_MAP
	; LDA	TILE
	; CMP	#09	;FLOOR-TILE
	; BEQ	DOFB
			;if nobody near door, lets close it.
			;check for object in the way first.
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call GET_TILE_FROM_MAP
			cp TILE_FLOOR			;FLOOR-TILE
			jr z,DOFB
	; LDA	#35
	; STA	UNIT_TIMER_A,X
	; JMP	AILP
			;SOMETHING IN THE WAY, ABORT
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),BLOCKED_DOOR_DELAY
			jp AILP
	
DOFB:
	; LDA	#14		;DOOR-SOUND
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	DOF2
	;ld a, SND_DOOR			;DOOR-SOUND
	;call PLAY_SOUND
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,DOF2
	
	; LDA	#88
	; STA	DOORPIECE1
	; LDA	#89
	; STA	DOORPIECE2
	; LDA	#86
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; JMP	DOF3
			;HORIZONTAL_DOOR
			ld a,#58	;88
			ld (DOORPIECE1),a
			ld a,#59	;89
			ld (DOORPIECE2),a
			ld a,#56	;86
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			jr DOF3
	
DOF2:
	; LDA	#70
	; STA	DOORPIECE1
	; LDA	#74
	; STA	DOORPIECE2
	; LDA	#78
	; STA	DOORPIECE3
	; JSR	DRAW_VERTICAL_DOOR
			;VERTICAL DOOR
			ld a,#46	;70
			ld (DOORPIECE1),a
			ld a,#4a	;74
			ld (DOORPIECE2),a
			ld a,#4e	;78
			ld (DOORPIECE3),a
			call DRAW_VERTICAL_DOOR
	
DOF3:
	; LDY	UNIT		;sh8bit -- seems to be a bug again, LDX intended?
	; LDA	#3
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),3
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW

DOOR_CLOSE_A:
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	DCA2
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			cp 1
			jr z,DCA2
	
	; LDA	#84
	; STA	DOORPIECE1
	; LDA	#85
	; STA	DOORPIECE2
	; LDA	#86
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; JMP	DCA3
			;HORIZONTAL DOOR
			ld a,#54	;84
			ld (DOORPIECE1),a
			ld a,#55	;85
			ld (DOORPIECE2),a
			ld a,#56	;86
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			jr DCA3
	
DCA2:
	; LDA	#69
	; STA	DOORPIECE1
	; LDA	#73
	; STA	DOORPIECE2
	; LDA	#77
	; STA	DOORPIECE3
	; JSR	DRAW_VERTICAL_DOOR
			;VERTICAL DOOR
			ld a,#45	;69
			ld (DOORPIECE1),a
			ld a,#49	;73
			ld (DOORPIECE2),a
			ld a,#4d	;77
			ld (DOORPIECE3),a
			call DRAW_VERTICAL_DOOR
	
DCA3:
	; LDY	UNIT			;sh8bit - another LDX intended?
	; LDA	#4
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),4
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW

DOOR_CLOSE_B:
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	DCB2
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,DCB2
	
	; LDA	#80
	; STA	DOORPIECE1
	; LDA	#81
	; STA	DOORPIECE2
	; LDA	#82
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; JMP	DCB3
			;HORIZONTAL DOOR
			ld a,#50	;80
			ld (DOORPIECE1),a
			ld a,#51	;81
			ld (DOORPIECE2),a
			ld a,#52	;82
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			jr DCB3
	
DCB2:
	; LDA	#68
	; STA	DOORPIECE1
	; LDA	#72
	; STA	DOORPIECE2
	; LDA	#76
	; STA	DOORPIECE3
	; JSR	DRAW_VERTICAL_DOOR
			;VERTICAL DOOR
			ld a,#44	;68
			ld (DOORPIECE1),a
			ld a,#48	;72
			ld (DOORPIECE2),a
			ld a,#4c	;76
			ld (DOORPIECE3),a
			call DRAW_VERTICAL_DOOR
	
DCB3:
	; LDY	UNIT		;sh8bit - another LDX intended?
	; LDA	#5
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),5
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
DOOR_CLOSE_FULL:
	; LDX	UNIT
	; JSR	DOOR_CHECK_PROXIMITY	
	; LDA	PROX_DETECT
	; CMP	#0
	; BNE	DCF1
			call DOOR_CHECK_PROXIMITY
			;ld a,(PROX_DETECT)
			or a
			jr nz,DCF1
	
DCF0:
	; LDA	#20
	; STA	UNIT_TIMER_A,X	;RESET TIMER
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),CLOSED_DOOR_DELAY				;RESET TIMER
			jp AILP
	
DCF1:
	; LDA	UNIT_C,X	;Lock status
	; CMP	#0	;UNLOCKED
	; BEQ	DCFZ
	; CMP	#1	;SPADE KEY
	; BNE	DCFB		
	; LDA	KEYS
	; AND	#%00000001	;CHECK FOR SPADE KEY
	; CMP	#%00000001
	; BEQ	DCFZ
	; JMP	DCF0
			;if player near door, lets open it.
			;first check if locked
			ld hl,UNIT_C		;Lock status
			call unit_abs_x
			ld a,(hl)
			or a				;UNLOCKED
			jr z,DCFZ
			cp 1				;SPADE KEY
			jr nz,DCFB
			ld a,(KEYS)
			and %00000001		;CHECK FOR SPADE KEY
			jr nz,DCFZ
			jr DCF0
	
DCFB:
	; CMP	#2	;HEART KEY
	; BNE	DCFC		
	; LDA	KEYS
	; AND	#%00000010	;CHECK FOR HEART KEY
	; CMP	#%00000010
	; BEQ	DCFZ
	; JMP	DCF0
			cp 2				;HEART KEY
			jr nz,DCFC
			ld a,(KEYS)
			and %00000010		;CHECK FOR HEART KEY
			jr nz,DCFZ
			jr DCF0
	
DCFC:
	; CMP	#3	;STAR KEY
	; BNE	DCF0	;SHOULD NEVER HAPPEN	
	; LDA	KEYS
	; AND	#%00000100	;CHECK FOR STAR KEY
	; CMP	#%00000100
	; BEQ	DCFZ
	; JMP	DCF0
			cp 3				;STAR KEY
			jr nz,DCF0			;SHOULD NEVER HAPPEN	
			ld a,(KEYS)
			and %00000100		;CHECK FOR STAR KEY
			jr nz,DCFZ
			jr DCF0
	
DCFZ:
	; LDA	#14		;DOOR-SOUND
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT
	; LDA	UNIT_A,X
	; CMP	#1
	; BEQ	DCF2
			;Start open door process
			ld a, SND_DOOR		;DOOR-SOUND
			call PLAY_SOUND
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)
			or a
			jr nz,DCF2
	
	; LDA	#84
	; STA	DOORPIECE1
	; LDA	#85
	; STA	DOORPIECE2
	; LDA	#86
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; JMP	DCF3
			;HORIZONTAL DOOR
			ld a,#54	;84
			ld (DOORPIECE1),a
			ld a,#55	;85
			ld (DOORPIECE2),a
			ld a,#56	;86
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			jr DCF3
	
			;VERTICAL DOOR
DCF2:
	; LDA	#69
	; STA	DOORPIECE1
	; LDA	#73
	; STA	DOORPIECE2
	; LDA	#77
	; STA	DOORPIECE3
	; JSR	DRAW_VERTICAL_DOOR
			ld a,#45	;69
			ld (DOORPIECE1),a
			ld a,#49	;73
			ld (DOORPIECE2),a
			ld a,#4d	;77
			ld (DOORPIECE3),a
			call DRAW_VERTICAL_DOOR
	
DCF3:
	; LDY	UNIT			;sh8bit - another LDX intended?
	; LDA	#0
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),0
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
DRAW_VERTICAL_DOOR:
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; DEC	MAP_Y
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	DOORPIECE1
	; STA	TILE
	; JSR	PLOT_TILE_TO_MAP
	; LDA	$FD
	; CLC
	; ADC	#128
	; STA	$FD
	; LDA	$FE
	; ADC	#$00
	; STA	$FE
	; LDA	DOORPIECE2
	; STA	($FD),Y
	; LDA	$FD
	; CLC
	; ADC	#128
	; STA	$FD
	; LDA	$FE
	; ADC	#$00
	; STA	$FE
	; LDA	DOORPIECE3
	; STA	($FD),Y	
	; RTS
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			dec a
			ld (MAP_Y),a
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld a,(DOORPIECE1)
			ld (TILE),a
			call PLOT_TILE_TO_MAP
			ld hl,(MAP_ADDR)
			ld de,MAP_WIDTH
			add hl,de
			ld a,(DOORPIECE2)
			ld (hl),a
			add hl,de
			ld a,(DOORPIECE3)
			ld (hl),a
			ret

DRAW_HORIZONTAL_DOOR:
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; DEC	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; LDA	DOORPIECE1
	; STA	TILE
	; JSR	PLOT_TILE_TO_MAP
	; INY
	; LDA	DOORPIECE2
	; STA	($FD),Y
	; INY
	; LDA	DOORPIECE3
	; STA	($FD),Y
	; RTS
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			dec a
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			ld a,(DOORPIECE1)
			ld (TILE),a
			call PLOT_TILE_TO_MAP
			ld hl,(MAP_ADDR)
			inc hl
			ld a,(DOORPIECE2)
			ld (hl),a
			inc hl
			ld a,(DOORPIECE3)
			ld (hl),a
			ret
	
; DOORPIECE1	!BYTE	00
; DOORPIECE2	!BYTE	00
; DOORPIECE3	!BYTE	00
DOORPIECE1		db 0
DOORPIECE2		db 0
DOORPIECE3		db 0

ROBOT_ATTACK_RANGE:
	; LDA	UNIT_LOC_X,X	;ROBOT UNIT
	; SEC 	;always set carry before subtraction
	; SBC 	UNIT_LOC_X	;PLAYER UNIT
	; BCC 	RAR1 ;if carry cleared then its negative
	; JMP	RAR2
			;First check horizontal proximity to door
			;ld hl,UNIT_LOC_X		;ROBOT UNIT
			;call unit_abs_x
			;ld a,(hl)
			LDA_HL_X UNIT_LOC_X
			ld hl,UNIT_LOC_X		;PLAYER UNIT
			sub (hl)
			jr nc,RAR2
			; jr RAR1
	
RAR1:
			; EOR 	#$FF ;convert two's comp back to positive
			; ADC 	#$01 ;no need for CLC here, already cleared
			neg
	
RAR2:
	; CMP	#1	;1 HORIZONTAL TILE FROM PLAYER
	; BCC	RAR3
	; LDA	#0	;player not detected
	; STA	PROX_DETECT
	; RTS	
			cp 1		; 1 HORIZONTAL TILE FROM PLAYER
			jr c,RAR3
			xor a		;player not detected
			;ld (PROX_DETECT),a
			ret
	; ..--== 6502 ==--..
	; BCC: if cmp > a
	; BCS: if cmp <= a
	
	; ..--==  z80 ==--..
	; jr c if cp > a
	; jr nc if cp <= a
	
RAR3:
	; LDA	UNIT_LOC_Y,X	;DOOR UNIT
	; SEC 	;always set carry before subtraction
	; SBC 	UNIT_LOC_Y	;PLAYER UNIT
	; BCC 	RAR4 ;if carry cleared then its negative
	; JMP	RAR5
			;Now check vertical proximity
			;ld hl,UNIT_LOC_Y		;ROBOT UNIT
			;call unit_abs_x
			;ld a,(hl)
			LDA_HL_X UNIT_LOC_Y
			ld hl,UNIT_LOC_Y		;PLAYER UNIT
			sub (hl)
			jr nc,RAR5
			; jr RAR4
	
RAR4:
	; EOR 	#$FF ;convert two's comp back to positive
	; ADC 	#$01 ;no need for CLC here, already cleared
			neg
	
RAR5:
	; CMP	#1	;1 VERTICAL TILE FROM PLAYER
	; BCC	RAR6
	; LDA	#0	;player not detected
	; STA	PROX_DETECT
	; RTS		
			cp 1
			jr c,RAR6
			xor a		;player not detected
			;ld (PROX_DETECT),a
			ret
	
RAR6:
	;PLAYER DETECTED, CHANGE DOOR MODE.
	; LDA	#1
	; STA	PROX_DETECT
	; RTS
			ld a,TRUE
			;ld (PROX_DETECT),a
			ret

DOOR_CHECK_PROXIMITY:
	; LDA	UNIT_LOC_X,X	;DOOR UNIT
	; SEC 	;always set carry before subtraction
	; SBC 	UNIT_LOC_X	;PLAYER UNIT
	; BCC 	PRD1 ;if carry cleared then its negative
	; JMP	PRD2
			;First check horizontal proximity to door
			ld hl,UNIT_LOC_X		;DOOR UNIT
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_LOC_X		;PLAYER UNIT
			sub (hl)
			jr nc,PRD2
			; jr PRD1
	
PRD1:
	; EOR 	#$FF ;convert two's comp back to positive
	; ADC 	#$01 ;no need for CLC here, already cleared
			neg
	
PRD2:
	; CMP	#2	;2 HORIZONTAL TILES FROM PLAYER
	; BCC	PRD3
	; LDA	#0	;player not detected
	; STA	PROX_DETECT
	; RTS	
			cp 2		;2 HORIZONTAL TILES FROM PLAYER
			jr c,PRD3
			xor a		;player not detected
			;ld (PROX_DETECT),a
			ret
	
PRD3:
	;Now check vertical proximity
	; LDA	UNIT_LOC_Y,X	;DOOR UNIT
	; SEC 	;always set carry before subtraction
	; SBC 	UNIT_LOC_Y	;PLAYER UNIT
	; BCC 	PRD4 ;if carry cleared then its negative
	; JMP	PRD5
			ld hl,UNIT_LOC_Y		;DOOR UNIT
			call unit_abs_x
			ld a,(hl)
			ld hl,UNIT_LOC_Y		;PLAYER UNIT
			sub (hl)
			jr nc,PRD5
			; jr PRD4
	
PRD4:
	; EOR 	#$FF ;convert two's comp back to positive
	; ADC 	#$01 ;no need for CLC here, already cleared
			neg
	
PRD5:
	; CMP	#2	;2 VERTICAL TILES FROM PLAYER
	; BCC	PRD6
	; LDA	#0	;player not detected
	; STA	PROX_DETECT
	; RTS
			cp 2		;2 VERTICAL TILES FROM PLAYER
			jr c,PRD6
			xor a		;player not detected
			;ld (PROX_DETECT),a
			ret
	
PRD6:
	;PLAYER DETECTED, CHANGE DOOR MODE.
	; LDA	#1
	; STA	PROX_DETECT
	; RTS
			ld a,TRUE
			;ld (PROX_DETECT),a
			ret
	
; PROX_DETECT	!BYTE	00	;0=NO 1=YES
;PROX_DETECT		db FALSE	;0=NO 1=YES

;This routine handles automatic sliding doors.
;UNIT_B register means:
;0=opening-A 1=opening-B 2=OPEN 3=closing-A 4=closing-B 5-CLOSED
ELEVATOR:
	; LDX	UNIT
	; LDA	UNIT_B,X
	; CMP	#06	;make sure number is in bounds
	; BCS	ELEVA
	; TAY
	; LDA	ELDB_L,Y
	; STA	ELEVJ+1
	; LDA	ELDB_H,Y
	; STA	ELEVJ+2
; ELEVJ:	JMP	$0000	;self modifying code
; ELEVA:	JMP	AILP	;-SHOULD NEVER NEED TO HAPPEN
			ld hl,UNIT_B
			call unit_abs_x
			ld a,(hl)
			cp 6				;make sure number is in bounds
			jr nc,ELEVA
			ld hl,ELDB
			add a,a
			add a,l
			ld l,a
			jr nc,$+3
			inc h
			ld a,(hl)
			inc hl
			ld h,(hl)
			ld l,a
			jp (hl)				;no self modifying code
ELEVA
			jp AILP

ELDB:	
			dw ELEV_OPEN_A
			dw ELEV_OPEN_B
			dw ELEV_OPEN_FULL
			dw ELEV_CLOSE_A
			dw ELEV_CLOSE_B
			dw ELEV_CLOSE_FULL

ELEV_OPEN_A:
	; LDA	#181
	; STA	DOORPIECE1
	; LDA	#89
	; STA	DOORPIECE2
	; LDA	#173
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; LDY	UNIT				;sh8bit -- LDX?
	; LDA	#1
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld a,#b5	;181
			ld (DOORPIECE1),a
			ld a,#59	;89
			ld (DOORPIECE2),a
			ld a,#ad	;173
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),1
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW
	
ELEV_OPEN_B:
	; LDA	#182
	; STA	DOORPIECE1
	; LDA	#09
	; STA	DOORPIECE2
	; LDA	#172
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; LDX	UNIT
	; LDA	#2
	; STA	UNIT_B,X
	; LDA	#50
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld a,#b6	;182
			ld (DOORPIECE1),a
			ld a,#09	;9
			ld (DOORPIECE2),a
			ld a,#ac	;172
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),2
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),50
			jp AILP_CHECK_FOR_WINDOW_REDRAW

ELEV_OPEN_FULL:
	; LDX	UNIT
; EVOF1:
	;CLOSE DOOR
	;check for object in the way first.
	; LDA	UNIT_LOC_X,X
	; STA	MAP_X
	; LDA	UNIT_LOC_Y,X
	; STA	MAP_Y
	; JSR	GET_TILE_FROM_MAP
	; LDA	TILE
	; CMP	#09	;FLOOR-TILE
	; BEQ	EVOF3
			ld hl,UNIT_LOC_X
			call unit_abs_x
			ld a,(hl)
			ld (MAP_X),a
			ld hl,UNIT_LOC_Y
			call unit_abs_x
			ld a,(hl)
			ld (MAP_Y),a
			call GET_TILE_FROM_MAP
			;ld a,(TILE)
			cp TILE_FLOOR			;FLOOR-TILE
			jr z,EVOF3
	
			;SOMETHING IN THE WAY, ABORT
EVOF2:
	; LDA	#35
	; STA	UNIT_TIMER_A,X
	; JMP	AILP
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),BLOCKED_ELEVATOR_DELAY
			jp AILP
	
EVOF3:
	; JSR	CHECK_FOR_UNIT
	; LDX	UNIT
	; LDA	UNIT_FIND	
	; CMP	#255
	; BNE	EVOF2
			;check for player or robot in the way
			call CHECK_FOR_UNIT
			ld a,(UNIT_FIND)
			cp 255
			jr nz,EVOF2
	
EVOFB:
	; LDA	#14		;DOOR SOUND
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT
	; LDA	#181
	; STA	DOORPIECE1
	; LDA	#89
	; STA	DOORPIECE2
	; LDA	#173
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; LDX	UNIT
	; LDA	#3
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
	;ld a, SND_DOOR		;DOOR SOUND
	;call PLAY_SOUND	
			;START TO CLOSE ELEVATOR DOOR
			ld a,#b5	;181
			ld (DOORPIECE1),a
			ld a,#59	;89
			ld (DOORPIECE2),a
			ld a,#ad	;173
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),3
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW

ELEV_CLOSE_A:
	; LDA	#84
	; STA	DOORPIECE1
	; LDA	#85
	; STA	DOORPIECE2
	; LDA	#173
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; LDY	UNIT					;sh8bit -- LDX?
	; LDA	#4
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			ld a,#54	;84
			ld (DOORPIECE1),a
			ld a,#55	;85
			ld (DOORPIECE2),a
			ld a,#ad	;173
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),4
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW

ELEV_CLOSE_B:
	; LDA	#80
	; STA	DOORPIECE1
	; LDA	#81
	; STA	DOORPIECE2
	; LDA	#174
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; LDY	UNIT					;sh8bit -- LDX?
	; LDA	#5
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JSR	ELEVATOR_PANEL
	; JMP	AILP
			ld a,#50	;80
			ld (DOORPIECE1),a
			ld a,#51	;81
			ld (DOORPIECE2),a
			ld a,#ae	;174
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),5
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			call CHECK_FOR_WINDOW_REDRAW
			call ELEVATOR_PANEL
			jp AILP
	
ELEV_CLOSE_FULL:
	; LDX	UNIT
	; JSR	DOOR_CHECK_PROXIMITY	
	; LDA	PROX_DETECT
	; CMP	#0
	; BNE	EVF1
	; LDA	#20
	; STA	UNIT_TIMER_A,X	;RESET TIMER
	; JMP	AILP
			call DOOR_CHECK_PROXIMITY	
			;ld a,(PROX_DETECT)
			or a
			jr nz,EVF1
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),CLOSED_ELEVATOR_DELAY			;RESET TIMER
			jp AILP
	
EVF1:
	; LDA	#14		;DOOR SOUND
	; JSR	PLAY_SOUND	;SOUND PLAY
	; LDX	UNIT
	; LDA	#84
	; STA	DOORPIECE1
	; LDA	#85
	; STA	DOORPIECE2
	; LDA	#173
	; STA	DOORPIECE3
	; JSR	DRAW_HORIZONTAL_DOOR
	; LDY	UNIT					;sh8bit -- LDX?
	; LDA	#0
	; STA	UNIT_B,X
	; LDA	#5
	; STA	UNIT_TIMER_A,X
	; JSR	CHECK_FOR_WINDOW_REDRAW	
	; JMP	AILP
			;Start open door process
			ld a, SND_DOOR		;DOOR SOUND
			call PLAY_SOUND
			ld a,#54	;84
			ld (DOORPIECE1),a
			ld a,#55	;85
			ld (DOORPIECE2),a
			ld a,#ad	;173
			ld (DOORPIECE3),a
			call DRAW_HORIZONTAL_DOOR
			ld hl,UNIT_B
			call unit_abs_x
			ld (hl),0
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl),DOOR_SPEED
			jp AILP_CHECK_FOR_WINDOW_REDRAW	

ELEVATOR_PANEL:
	; LDX	UNIT
	; LDA	UNIT_LOC_X,X	;elevator X location
	; CMP	UNIT_LOC_X	;player X location
	; BEQ	ELPN1
	; RTS
			;Check to see if player is standing in the
			;elevator first.
			ld hl,UNIT_LOC_X		;elevator X location
			call unit_abs_x
			ld a,(UNIT_LOC_X)		;player X location
			cp (hl)
			ret nz
	
ELPN1:
	; LDA	UNIT_LOC_Y,X	;elevator Y location
	; SEC
	; SBC	#01
	; CMP	UNIT_LOC_Y	;player Y location
	; BEQ	ELPN2
	; RTS
			ld hl,UNIT_LOC_Y		;elevator Y location
			call unit_abs_x
			ld a,(hl)
			dec a
			ld hl,UNIT_LOC_Y		;player Y location
			cp (hl)
			ret nz
	
ELPN2:
	; LDA	#<MSG_ELEVATOR
	; STA	$FB
	; LDA	#>MSG_ELEVATOR
	; STA	$FC
	; JSR	PRINT_INFO
	; LDA	#<MSG_LEVELS
	; STA	$FB
	; LDA	#>MSG_LEVELS
	; STA	$FC
	; JSR	PRINT_INFO
	; JSR	ELEVATOR_SELECT
	; RTS
			;PLAYER DETECTED, START ELEVATOR PANEL
			ld hl,MSG_ELEVATOR
			call PRINT_INFO
			ld hl,MSG_LEVELS
			call PRINT_INFO
			jp ELEVATOR_SELECT		;call:ret
	

PLOT_TILE_TO_MAP:
	; LDY	#0
	; LDA	MAP_Y
	; CLC
	; ROR
	; PHP
	; CLC
	; ADC	#>MAP
	; STA	$FE	;HIGH BYTE OF MAP SOURCE
	; LDA	#$0
	; PLP
	; ROR
	; ORA	MAP_X
	; STA	$FD	;LOW BYTE OF MAP SOURCE
	; LDA	TILE
	; STA	($FD),Y
	; RTS
			ld a,(MAP_Y)
			ld h,a
			srl h
			ld a,(MAP_X)
			jr nc,$+4
			or MAP_WIDTH
			ld l,a
			ld de,MAP
			add hl,de
			ld (MAP_ADDR),hl
			ld a,(TILE)
			ld (hl),a
			ret

;In this AI routine, the droid simply goes left until it
;hits an object, and then reverses direction and does the
;same, bouncing back and forth.
LEFT_RIGHT_DROID:
	; LDX	UNIT
	; JSR	HOVERBOT_ANIMATE
	; LDA	#10		;reset timer to 10
	; STA	UNIT_TIMER_A,X	
	; LDA	UNIT_A,X		;GET DIRECTION
	; CMP	#1	;0=LEFT 1=RIGHT
	; BEQ	LRD01
	; LDA	#%00000010
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_LEFT
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	LRD02
	; LDA	#1
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			call HOVERBOT_ANIMATE
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl), HOVERBOT_MOVE_SPD			;reset timer to 10
			ld hl,UNIT_A
			call unit_abs_x	
			ld a,(hl)			;GET DIRECTION
			or a				;0=LEFT 1=RIGHT
			jr nz,LRD01
			ld a,%00000010
			ld (MOVE_TYPE),a
			call REQUEST_WALK_LEFT
			;ld a,(MOVE_RESULT)
			or a
			jr nz,LRD02
			ld hl,UNIT_A
			call unit_abs_x	
			ld (hl),1			;CHANGE DIRECTION
			jp AILP_CHECK_FOR_WINDOW_REDRAW	
	
LRD01:
	; LDA	#%00000010
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_RIGHT
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	LRD02
	; LDA	#0
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
			ld a,%00000010
			ld (MOVE_TYPE),a
			call REQUEST_WALK_RIGHT
			;ld a,(MOVE_RESULT)
			or a
			jr nz,LRD02
			ld hl,UNIT_A
			call unit_abs_x	
			ld (hl),0			;CHANGE DIRECTION
	
LRD02:
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			jp AILP_CHECK_FOR_WINDOW_REDRAW	

;In this AI routine, the droid simply goes UP until it
;hits an object, and then reverses direction and does the
;same, bouncing back and forth.
UP_DOWN_DROID:
	; LDX	UNIT
	; JSR	HOVERBOT_ANIMATE
	; LDA	#10		;reset timer to 10
	; STA	UNIT_TIMER_A,X	
	; LDA	UNIT_A,X		;GET DIRECTION
	; CMP	#1	;0=UP 1=DOWN
	; BEQ	UDD01
	; LDA	#%00000010
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_UP
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	UDD02
	; LDA	#1
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			call HOVERBOT_ANIMATE
			ld hl,UNIT_TIMER_A
			call unit_abs_x
			ld (hl), HOVERBOT_MOVE_SPD			;reset timer to 10
			ld hl,UNIT_A
			call unit_abs_x
			ld a,(hl)			;GET DIRECTION
			or a				;0=UP 1=DOWN
			jr nz,UDD01
			ld a,%00000010
			ld (MOVE_TYPE),a
			call REQUEST_WALK_UP
			;ld a,(MOVE_RESULT)
			or a
			jr nz,UDD02
			ld hl,UNIT_A
			call unit_abs_x	
			ld (hl),1			;CHANGE DIRECTION
			jp AILP_CHECK_FOR_WINDOW_REDRAW	
	
UDD01:
	; LDA	#%00000010
	; STA	MOVE_TYPE
	; JSR	REQUEST_WALK_DOWN
	; LDA	MOVE_RESULT
	; CMP	#1
	; BEQ	UDD02
	; LDA	#0
	; LDX	UNIT
	; STA	UNIT_A,X	;CHANGE DIRECTION
			ld a,%00000010
			ld (MOVE_TYPE),a
			call REQUEST_WALK_DOWN
			;ld a,(MOVE_RESULT)
			or a
			jr nz,UDD02
			ld hl,UNIT_A
			call unit_abs_x	
			ld (hl),0			;CHANGE DIRECTION
	
UDD02:
	; JSR	CHECK_FOR_WINDOW_REDRAW
	; JMP	AILP
			jp AILP_CHECK_FOR_WINDOW_REDRAW	

HOVERBOT_ANIMATE:
	; LDA	UNIT_TIMER_B,X
	; CMP	#0
	; BEQ	HOVAN2
	; DEC	UNIT_TIMER_B,X
	; RTS
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld a,(hl)
			or a
			jp z,HOVAN2
			dec (hl)
			ret
	
HOVAN2:
	; LDA	#3
	; STA	UNIT_TIMER_B,X	;RESET ANIMATE TIMER
	; LDA	UNIT_TILE,X
	; CMP	#98
	; BNE	HOVAN1
	; LDA	#99		;HOVERBOT TILE
	; STA	UNIT_TILE,X
	; RTS
			ld hl,UNIT_TIMER_B
			call unit_abs_x
			ld (hl),HOVERBOT_ANIM_SPEED	;RESET ANIMATE TIMER
			ld hl,UNIT_TILE
			call unit_abs_x
			ld a,(hl)
			cp TILE_HOVERBOT_A
			jr nz,HOVAN1
			ld (hl),TILE_HOVERBOT_B			;HOVERBOT TILE
			ret
	
HOVAN1:
			; LDA	#98		;HOVERBOT TILE
			; STA	UNIT_TILE,X
			; RTS
			ld (hl),TILE_HOVERBOT_A		;HOVERBOT TILE
			ret
		
REQUEST_WALK_UP
			ld a, (UNIT)
			ld c, a
			ld hl, UNIT_LOC_Y
			call offc_abs_x
			ld a, (hl)
			cp 3
			jr z, MGU01
			ld hl, MAP_Y
			ld (hl), a
			dec (hl)
			ld hl, UNIT_LOC_X
			call offc_abs_x
			ld a, (hl)
			ld (MAP_X), a
			call GET_TILE_FROM_MAP
			ld c, a
			ld hl, TILE_ATTRIB
			call offc_abs_x
			ld a, (hl)
			ld hl, MOVE_TYPE
			and (hl)
			cp (hl)
			jr nz, MGU01
			call CHECK_FOR_UNIT
			ld a, (UNIT_FIND)
			cp #ff
			jr nz, MGU01
			ld a, (UNIT)
			ld e, a
			ld d, 0
			ld hl, UNIT_LOC_Y
			add hl, de
			dec (hl)
			ld a, TRUE
			;ld (MOVE_RESULT), a
			ret
MGU01
			xor a
			;ld (MOVE_RESULT), a
			ret

REQUEST_WALK_DOWN
			ld a, (UNIT)
			ld c, a
			ld hl, UNIT_LOC_Y
			call offc_abs_x
			ld a, (hl)
			cp 60
			jr z, MGD01
			ld hl, MAP_Y
			ld (hl), a
			inc (hl)
			ld hl, UNIT_LOC_X
			call offc_abs_x
			ld a, (hl)
			ld (MAP_X), a
			call GET_TILE_FROM_MAP
			ld c, a
			ld hl, TILE_ATTRIB
			call offc_abs_x
			ld a, (hl)
			ld hl, MOVE_TYPE
			and (hl)
			cp (hl)
			jr nz, MGD01
			call CHECK_FOR_UNIT
			ld a, (UNIT_FIND)
			cp #ff
			jr nz, MGD01
			ld a, (UNIT)
			ld e, a
			ld d, 0
			ld hl, UNIT_LOC_Y
			add hl, de
			inc (hl)
			ld a, TRUE
			;ld (MOVE_RESULT), a
			ret
MGD01
			xor a
			;ld (MOVE_RESULT), a
			ret


REQUEST_WALK_RIGHT
			ld a, (UNIT)
			ld c, a
			ld hl, UNIT_LOC_X
			call offc_abs_x
			ld a, (hl)
			cp 122
			jr z, MGR01
			ld hl, MAP_X
			ld (hl), a
			inc (hl)
			ld hl, UNIT_LOC_Y
			call offc_abs_x
			ld a, (hl)
			ld (MAP_Y), a
			call GET_TILE_FROM_MAP
			ld c, a
			ld hl, TILE_ATTRIB
			call offc_abs_x
			ld a, (hl)
			ld hl, MOVE_TYPE
			and (hl)
			cp (hl)
			jr nz, MGR01
			call CHECK_FOR_UNIT
			ld a, (UNIT_FIND)
			cp #ff
			jr nz, MGR01
			ld a, (UNIT)
			ld e, a
			ld d, 0
			ld hl, UNIT_LOC_X
			add hl, de
			inc (hl)
			ld a, TRUE
			;ld (MOVE_RESULT), a
			ret
MGR01
			xor a
			;ld (MOVE_RESULT), a
			ret

REQUEST_WALK_LEFT
			ld a, (UNIT)
			ld c, a
			ld hl, UNIT_LOC_X
			call offc_abs_x
			ld a, (hl)
			cp 5
			jr z, MGL01
			ld hl, MAP_X
			ld (hl), a
			dec (hl)
			ld hl, UNIT_LOC_Y
			call offc_abs_x
			ld a, (hl)
			ld (MAP_Y), a
			call GET_TILE_FROM_MAP
			ld c, a
			ld hl, TILE_ATTRIB
			call offc_abs_x
			ld a, (hl)
			ld hl, MOVE_TYPE
			and (hl)
			cp (hl)
			jr nz, MGL01
			call CHECK_FOR_UNIT
			ld a, (UNIT_FIND)
			cp #ff
			jr nz, MGL01
			ld a, (UNIT)
			ld e, a
			ld d, 0
			ld hl, UNIT_LOC_X
			add hl, de
			dec (hl)
			ld a, TRUE
			;ld (MOVE_RESULT), a
			ret
MGL01
			xor a
			;ld (MOVE_RESULT), a
			ret


;This routine checks a specific place on the map specified
;in MAP_X and MAP_Y to see if there is a unit present at 
;that spot. If so, the unit# will be stored in UNIT_FIND
;otherwise 255 will be stored. 
CHECK_FOR_UNIT:
			ld b, 28
			ld de, 0
			ld hl, UNIT_TYPE
CFU00
			ld a, (hl)
			and a
			jr nz, CFU02
CFU01
			inc hl
			inc e
			djnz CFU00
			ld a, #ff
			ld (UNIT_FIND), a
			ret
CFU02
			push hl
			LDA_HL_X UNIT_LOC_X
			ld hl, MAP_X
			cp (hl)
			pop hl
			jr nz, CFU01
			push hl
			LDA_HL_X UNIT_LOC_Y
			ld hl, MAP_Y
			cp (hl)
			pop hl
			jr nz, CFU01
			ld a, e
			ld (UNIT_FIND), a
			ret

;This routine checks a specific place on the map specified
;in MAP_X and MAP_Y to see if there is a hidden unit present 
;at that spot. If so, the unit# will be stored in UNIT_FIND
;otherwise 255 will be stored. 
CHECK_FOR_HIDDEN_UNIT
			ld de, 48
CFH00
			LDA_HL_X UNIT_TYPE
			and a

			call nz, CFH02
			and a
			ret nz

			inc e
			ld a, 64
			cp e
			jr nz, CFH00
			ld a, #ff
			ld (UNIT_FIND), a
			ret
CFH02
			LDA_HL_X UNIT_LOC_X
			ld hl, MAP_X
			cp (hl)
			jr z, CFH05
			jr c, CFH03
CFH02exit
			xor a
			ret
CFH03
			ld hl, UNIT_C
			add hl, de
			add a, (hl)
			ld hl, MAP_X
			cp (hl)
			jr c, CFH02exit
CFH05
			LDA_HL_X UNIT_LOC_Y
			ld hl, MAP_Y
			cp (hl)
			jr z, CFH10
			jr c, CFH06
			xor a
			ret
CFH06
			ld hl, UNIT_D
			add hl, de
			add a, (hl)
			ld hl, MAP_Y
			cp (hl)
			jr c, CFH02exit
CFH10
			ld a, e
			ld (UNIT_FIND), a
			ret 


;This routine will return the tile for a specific X/Y
;on the map.  You must first define MAP_X and MAP-Y.
;The result is stored in TILE.
GET_TILE_FROM_MAP:
			ld a,(MAP_Y)
			ld h,a
			srl h
			ld a,(MAP_X)
			jr nc,$+4
			or MAP_WIDTH
			ld l,a
			ld bc,MAP
			add hl,bc
			ld (MAP_ADDR),hl
			ld a,(hl)
			ld (TILE),a
			ret


;NOTES ABOUT UNIT TYPES
;----------------------
;000=no unit (does not exist)
;001=player unit
;002=hoverbot left-to-right
;003=hoverbot up-down
;004=hoverbot attack mode
;005=hoverbot chase player
;006=
;007=transporter
;008=
;009=evilbot chase player
;010=door
;011=small explosion
;012=pistol fire up
;013=pistol fire down
;014=pistol fire left
;015=pistol fire right
;016=trash compactor
;017=
;018=
;019=
;020=

;NOTES ABOUT UNIT NUMBERING SCHEME
;---------------------------------
;0 = player unit
;1-27 = enemy robots	(max 28 units)
;28-31 = weapons fire
;32-47 = doors and other units that don't have sprites (max 16 units)
;48-63 = hidden objects to be found (max 16 units)

;NOTES ABOUT DOORS.
;-------------------
;A-0=horitzonal 1=vertical
;B-0=opening-A 1=opening-B 2=OPEN / 3=closing-A 4=closing-B 5-CLOSED
;C-0=unlocked / 1=locked spade 2=locked heart 3=locked star
;D-0=automatic / 0=manual

;HIDDEN OBJECTS
;--------------
;UNIT_TYPE:128=key UNIT_A: 0=SPADE 1=HEART 2=STAR
;UNIT_TYPE:129=time bomb
;UNIT_TYPE:130=EMP
;UNIT_TYPE:131=pistol
;UNIT_TYPE:132=charged plasma gun
;UNIT_TYPE:133=medkit
;UNIT_TYPE:134=magnet

;NOTES ABOUT TRANSPORTER
;----------------------
;UNIT_A: 0=always active	1=only active when all robots are dead
;UNIT_B:	0=completes level 1=send to coordinates
;UNIT_C:	X-coordinate
;UNIT_D:	Y-coordinate

;Sound Effects
;----------------------
;0 explosion
;1 small explosion
;2 medkit
;3 emp
;4 haywire
;5 evilbot
;6 move
;7 electric shock
;8 plasma gun
;9 fire pistol
;10 item found
;11 error
;12 change weapons
;13 change items
;14 door
;15 menu beep
;16 walk
;17 sfx (short beep)
;18 sfx
