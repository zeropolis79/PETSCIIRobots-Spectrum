DELAY_FIRST=5
DELAY_NEXT=0

getin:

	push bc
	push de
	push hl

	ld hl,keycodes
	ld bc,#7ffe
	
.loop0

	ld e,5
	in a,(c)
	
.loop1

	rra
	jr nc,.keyset
	inc hl
	dec e
	jr nz,.loop1
	
	rr b
	jr c,.loop0
	ld a,DELAY_FIRST
	ld (.delay),a
	xor a
	ld (.rep),a
	jr .done

.keyset:

	ld a,(hl)
.rep=$+1
	cp 0
	ld (.rep),a
	jr nz,.done

.decrep
.delay=$+1
	ld a,DELAY_FIRST
	or a
	jr z,.dorep
	dec a
	ld (.delay),a
	xor a
	jr .done
.dorep:
	ld a,DELAY_NEXT
	ld (.delay),a
	ld a,(.rep)

.done:

	pop hl
	pop de
	pop bc
	
	ret
	

	
keycodes:

	db 32,2,"MNB"	;7f
	db 13,"LKJH"	;bf
	db "POIUY"		;df
	db "09876"		;ef
	db "12345"		;f7
	db "QWERT"		;fb
	db "ASDFG"		;fd
	db 1,"ZXCV"		;fe
