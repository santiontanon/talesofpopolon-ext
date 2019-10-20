	include "../constants.asm"

	org #0000

skybox:
    db 0
texture_set:
    db 2
floortypeandcolor:
;    db 0
    db #d0
ceilingtypeandcolor:
;    db 0
    db #40   
map:
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,0,0,0,0,0,0,0,7,7,7,7,7,7,7,7
	db 7,0,0,0,0,0,0,0,7,7,7,7,7,7,7,7
	db 7,0,7,0,0,0,7,0,7,7,7,7,7,7,7,7
	db 5,0,0,0,7,0,0,0,0,0,1,0,4,7,7,7
	db 7,0,7,0,0,0,7,0,7,7,7,7,7,7,7,7
	db 7,0,0,0,0,0,0,0,7,7,7,7,7,7,7,7
	db 7,0,0,0,0,0,0,0,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
pickups_map:
    db 0
enemies_map:
    db 1
    ; enemy type, x, y, sprite, color, hit points, state1, state2, state3
    db ENEMY_MEDUSA, 9*16+8,7*16+8,    ENEMY_MEDUSA_SPRITE_PATTERN,  10, 48,0,0,0
events_map:
    db 0
    ; x, y, event ID (the first 4 IDs are reserved for 4 potential messages below (each of them
    ;                        4 lines of 22 characters each))
messages_map:
    dw 0 ;; length of the message data block below
