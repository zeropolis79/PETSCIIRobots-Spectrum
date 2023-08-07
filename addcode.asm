	;define PETSCII
	
	device zxspectrum48

	org #6200

code
			incbin "main.hrs"
endcode

end
			
			;EMPTYTAP "pet_robots48k.tap"
			SAVETAP "pet_robots48k.tap",CODE,"petrobo",code,endcode-code