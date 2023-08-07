DELAY_FIRST=2
DELAY_NEXT=1

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
	jr z,.decrep
	push af
	ld a,DELAY_FIRST
	ld (.delay),a
	pop af
	jr .done

.decrep
.delay=$+1
	ld a,0
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
	
	; если новый код 0, устанавливаем счётчик в максимум, выходим
	; если код не равен коду повтора, устанавливаем счётчик в максимум
	; запоминаем код для повтора, выходим
	; если новый код равен коду повтора, декрементим счётчик, по 0 выдаем код повтора и переустанавливаем счётчик
	
	
keycodes:

	db 32,2,"MNB"	;7f
	db 13,"LKJH"	;bf
	db "POIUY"		;df
	db "09876"		;ef
	db "12345"		;f7
	db "QWERT"		;fb
	db "ASDFG"		;fd
	db 1,"ZXCV"		;fe
