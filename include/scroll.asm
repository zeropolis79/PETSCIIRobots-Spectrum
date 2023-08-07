SCROLL_OFF=2		;pixels, 1..7

scroll_buf:		ds 32*SCROLL_OFF,#ff

scroll_up_down:

	call scroll_store_up
	call scroll_up
	call scroll_clear_down
	halt
	halt
	call scroll_down
	jp scroll_restore_up

	
scroll_down_up:

	call scroll_store_down
	call scroll_down
	call scroll_clear_up
	halt
	halt
	call scroll_up
	jp scroll_restore_down
	
	
scroll_store_up:

	ld b,SCROLL_OFF
	ld hl,#4000
	ld de,scroll_buf
.l10:
	push bc
	push hl
	ld bc,32
	ldir
	pop hl
	call down_hl_line
	pop bc
	djnz .l10
	ret
	
	
scroll_store_down:

	ld b,SCROLL_OFF
	ld hl,#5800-32-256*(SCROLL_OFF-1)
	ld de,scroll_buf
.l10:
	push bc
	push hl
	ld bc,32
	ldir
	pop hl
	call down_hl_line
	pop bc
	djnz .l10
	ret
	
	
scroll_restore_down:
	
	ld b,SCROLL_OFF
	ld hl,scroll_buf
	ld de,#5800-32-256*(SCROLL_OFF-1)
.l1:
	push bc
	push de
	ld bc,32
	ldir
	pop de
	ex de,hl
	call down_hl_line
	ex de,hl
	pop bc
	djnz .l1
	ret
	
	
scroll_restore_up:

	ld b,SCROLL_OFF
	ld hl,scroll_buf
	ld de,#4000
.l1:
	push bc
	push de
	ld bc,32
	ldir
	pop de
	ex de,hl
	call down_hl_line
	ex de,hl
	pop bc
	djnz .l1
	ret
	
	
	
scroll_clear_down:
	
	ld b,SCROLL_OFF
	ld de,#5800-32-256*(SCROLL_OFF-1)
.l1:
	push bc
	push de
	ld l,e
	ld h,d
	
	inc de
	ld bc,31
	ld (hl),#ff
	ldir
	pop de
	ex de,hl
	call down_hl_line
	ex de,hl
	pop bc
	djnz .l1
	ret
	
	
scroll_clear_up:

	ld b,SCROLL_OFF
	ld de,#4000
.l1:
	push bc
	push de
	ld l,e
	ld h,d
	inc de
	ld bc,31
	ld (hl),#ff
	ldir
	pop de
	ex de,hl
	call down_hl_line
	ex de,hl
	pop bc
	djnz .l1
	ret
	
	
	
scroll_up:

	ld b,192-SCROLL_OFF
	ld hl,#4000+256*SCROLL_OFF
	ld de,#4000
.l0:
	push bc
	push de
	push hl
	ld bc,32
	ldir
	pop hl
	call down_hl_line
	pop de
	ex de,hl
	call down_hl_line
	ex de,hl
	pop bc
	djnz .l0

	ret
	

	
scroll_down:
	
	ld b,192-SCROLL_OFF
	ld hl,#5800-32-256*SCROLL_OFF
	ld de,#5800-32
.l0:
	push bc
	push de
	push hl
	ld bc,32
	ldir
	pop hl
	call up_hl_line
	pop de
	ex de,hl
	call up_hl_line
	ex de,hl
	pop bc
	djnz .l0

	ret


	
down_hl_line:

	inc h
	ld a,h
	and 7
	ret nz
	ld a,l
	add a,32
	ld l,a
	ret c
	ld a,h
	sub 8
	ld h,a
	ret



up_hl_line:

	ld a,h
	and 7
	jr nz,.done
	ld a,l
	sub 32
	ld l,a
	jr c,.done
	ld a,h
	add a,8
	ld h,a
.done:
	dec h
	ret