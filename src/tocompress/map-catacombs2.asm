	include "../constants.asm"

	org #0000

skybox:
    db 0
texture_set:
    db 1
floortypeandcolor:
;    db 0
    db #60
ceilingtypeandcolor:
;    db 0
    db #d0   
map:
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 7,7,7,7,7,7,7,7,7,0,0,0,0,0,0,0
	db 7,0,0,0,0,0,0,0,7,0,0,0,0,0,0,0
	db 7,0,7,0,0,0,7,0,7,7,7,7,7,0,0,0
	db 4,0,0,0,7,0,0,0,0,0,1,0,2,0,0,0
	db 7,0,7,0,0,0,7,0,7,7,7,7,7,0,0,0
	db 7,0,0,0,0,0,0,0,7,0,0,0,0,0,0,0
	db 7,7,7,7,7,7,7,7,7,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
pickups_map:
    db 1
    db ITEM_SILVERARMOR , 11*16+8,7*16+8,SPRITE_PATTERN_CHEST     
enemies_map:
    db 1
    ; enemy type, x, y, sprite, color, hit points, state1, state2, state3
    db ENEMY_KER  	, 9*16+8,7*16+8,    ENEMY_KER_SPRITE_PATTERN,  		8, 12,0,0,0
events_map:
    db 1
    ; x, y, event ID (the first 4 IDs are reserved for 4 potential messages below (each of them
    ;                        4 lines of 22 characters each))
    db #B0,#70,0
messages_map:
    dw 22*4 ;; length of the message data block below
    db " THE STONE FACE SAYS: "
    db "WHAT YOU DEFEATED WAS "
    db "A KER! TROUBLESOME IF "
    db "THEY ARE BEHIND THIS! "
