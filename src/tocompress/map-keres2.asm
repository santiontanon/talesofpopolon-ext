	include "../constants.asm"

	org #0000

skybox:
    db 0
texture_set:
    db 2
floortypeandcolor:
;    db 0
    db #e0
ceilingtypeandcolor:
;    db 0
    db #40   
map:
	db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	db 8,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8
	db 8,0,8,0,0,0,8,0,8,8,8,8,8,8,8,8
	db 8,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8
	db 5,0,0,0,8,0,0,0,8,8,8,8,8,8,8,8
	db 8,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8
	db 8,0,8,0,0,0,8,0,8,8,8,8,8,8,8,8
	db 8,0,0,0,0,0,0,0,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
pickups_map:
    db 0
enemies_map:
    db 2
    ; enemy type, x, y, sprite, color, hit points, state1, state2, state3
    db ENEMY_KER2, 7*16+8,5*16+8,    ENEMY_KER_SPRITE_PATTERN,  9, 48,0,0,0
    db ENEMY_KER3, 7*16+8,9*16+8,    ENEMY_KER_SPRITE_PATTERN,  9, 48,0,0,0
events_map:
    db 1
    ; x, y, event ID (the first 4 IDs are reserved for 4 potential messages below (each of them
    ;                        4 lines of 22 characters each))
    db #10, #70, 0
messages_map:
    dw 22*8 ;; length of the message data block below
    db " YOU HEAR A VOICE:    "
    db "POPOLON! IT WAS YOU!  "
    db "YOU KILLED OUR GORGON!"
    db "NOW DIE!              "
    db " THE DYING KER SAYS:  "
    db "NOOOO!!! YOU WILL PAY "
    db "FOR THIS POPOLON!     "
    db "                      "
