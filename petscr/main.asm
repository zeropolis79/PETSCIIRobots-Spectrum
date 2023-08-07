    device zxspectrum48


	org #8000
	
begin:

	ld hl,screen_data
	ld de,#c000
	push de
	include "unaplib_small.asm"
	
screen_data:
	incbin "main1.apl"
	
end
	display /d,end-begin
	savesna "test.sna",begin
	savebin "screen.bin",begin,end-begin
	SAVETAP "pet_robots.tap",CODE,"petscr",begin,end-begin
	SAVETAP "gfx_robots.tap",CODE,"petscr",begin,end-begin
	SAVETAP "micro_bots.tap",CODE,"petscr",begin,end-begin
	SAVETAP "color_bots.tap",CODE,"petscr",begin,end-begin