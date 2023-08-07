    device zxspectrum48


	org #c000
	
begin:

	ld hl,#5800
	ld de,#5801
	ld bc,767
	xor a
	halt
	out (#fe),a
	ld (hl),a
	ldir

	ld hl,text_data
	ld de,#4000
	ld b,24
.l0
	push bc
	push de
	ld b,32
.l1
	push bc
	push de
	push hl
	ld l,(hl)
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	ld bc,font_data
	add hl,bc
	ld b,8
.l2
	ld a,(hl)
	ld (de),a
	inc hl
	inc d
	djnz .l2
	pop hl
	pop de
	pop bc
	inc hl
	inc de
	djnz .l1
	pop de

    ld a,e		;down de
    sub #e0
    ld e,a
    sbc a,a
    and #f8
    add a,d
    add a,8
    ld d,a
	
	pop bc
	djnz .l0
	
	ld hl,#5800
	ld de,#5801
	ld bc,767
	ld a,#44
	halt
	ld (hl),a
	ldir
	or #80
	ld hl,22528+16*32+12
	ld b,5
.l3
	ld (hl),a
	inc hl
	djnz .l3
	ld hl,22528+17*32+12
	ld b,5
.l4
	ld (hl),a
	inc hl
	djnz .l4

	ret
	
	
font_data:
	incbin "font.bin"
text_data:
	incbin "text.bin"
	
end
	display /d,end-begin

	savebin "main1.bin",begin,end-begin