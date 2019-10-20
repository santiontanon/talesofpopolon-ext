	include "../constants.asm"

	org #0000

skybox:
    db 0
texture_set:
    db 0
floortypeandcolor:
;    db 0
    db #e0
ceilingtypeandcolor:
;    db 0
    db #f0   
map:
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,5,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,9,8,0,8,9,8,8,8,8,8,8
    db 8,8,8,8,2,0,0,0,0,0,3,0,0,4,8,8
    db 8,8,8,8,8,8,0,0,0,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,6,8,8,8,4,8,8,8,8
    db 8,8,8,8,8,8,0,0,0,8,8,0,8,8,8,8
    db 8,8,8,8,2,0,0,0,0,0,0,0,8,8,8,8
    db 8,8,8,8,8,9,8,8,8,9,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
    db 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
pickups:
    db 0
    ; item type, x, y, sprite
enemies:
    db 2
    ; enemy type, x, y, sprite, color, hit points, state1, state2, state3
    db ENEMY_SWITCH     ,5*16+8, 4*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_OPEN_GATE,10+4*16
    db ENEMY_SWITCH     ,12*16+8, 4*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,  15, 1,SWITCH_STATE_RIGHT,EVENT_OPEN_GATE,10+4*16

events_map:
    db 2
    ; x, y, event ID (the first 4 IDs are reserved for 4 potential messages below (each of them
    ;                        4 lines of 22 characters each))
    db #50,#40,1
    db #50,#80,EVENT_PASSWORD
messages_map:
    dw 22*8 ;; length of the message data block below
    db " THE STONE FACE SAYS: "
    db "                      "
    db "                      "
    db "                      "

    db " THE STONE FACE SAYS: "
    db "THE KERES CAPTURED A  "
    db "GORGON TO GUARD THEIR "
    db "LAIR! BE CAREFUL!     "