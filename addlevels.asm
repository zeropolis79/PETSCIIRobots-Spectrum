	;define PETSCII
	
	device zxspectrum48

	org #6200

file_level_a
			incbin "res/level-a.apl"
file_level_b
			incbin "res/level-b.apl"
file_level_c
			incbin "res/level-c.apl"
file_level_d
			incbin "res/level-d.apl"
file_level_e
			incbin "res/level-e.apl"
file_level_f
			incbin "res/level-f.apl"
file_level_g
			incbin "res/level-g.apl"
file_level_h
			incbin "res/level-h.apl"
file_level_i
			incbin "res/level-i.apl"
file_level_j
			incbin "res/level-j.apl"
end
			
			SAVETAP "pet_robots48k.tap",CODE,"level-a",file_level_a,file_level_b-file_level_a
			SAVETAP "pet_robots48k.tap",CODE,"level-b",file_level_b,file_level_c-file_level_b
			SAVETAP "pet_robots48k.tap",CODE,"level-c",file_level_c,file_level_d-file_level_c
			SAVETAP "pet_robots48k.tap",CODE,"level-d",file_level_d,file_level_e-file_level_d
			SAVETAP "pet_robots48k.tap",CODE,"level-e",file_level_e,file_level_f-file_level_e
			SAVETAP "pet_robots48k.tap",CODE,"level-f",file_level_f,file_level_g-file_level_f
			SAVETAP "pet_robots48k.tap",CODE,"level-g",file_level_g,file_level_h-file_level_g
			SAVETAP "pet_robots48k.tap",CODE,"level-h",file_level_h,file_level_i-file_level_h
			SAVETAP "pet_robots48k.tap",CODE,"level-i",file_level_i,file_level_j-file_level_i
			SAVETAP "pet_robots48k.tap",CODE,"level-j",file_level_j,end-file_level_j
