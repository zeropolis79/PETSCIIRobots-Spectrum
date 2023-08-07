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
	xor a
	jr .done

.keyset:

	ld a,(hl)

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
