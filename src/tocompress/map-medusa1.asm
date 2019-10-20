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
    db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
    db 7,7,7,0,0,0,7,0,7,7,7,0,0,0,7,7
    db 7,7,7,0,7,0,7,0,7,7,7,0,7,7,7,7 
    db 7,7,7,0,7,0,3,0,7,7,7,0,7,7,7,7 
    db 7,7,7,0,7,7,7,7,7,7,7,0,7,7,7,7
    db 7,7,0,0,0,7,7,7,7,7,7,3,7,7,7,7
    db 7,0,0,0,0,0,0,0,9,0,0,0,0,0,9,7
    db 7,7,0,0,0,7,7,7,7,0,0,0,0,0,7,7
    db 7,7,7,0,7,7,7,7,7,0,0,0,0,0,7,7
    db 7,7,7,0,0,0,0,7,9,0,0,0,0,0,9,7
    db 7,7,7,7,7,7,0,7,7,7,7,0,7,7,7,7
    db 7,0,7,7,9,7,3,7,7,9,7,0,7,7,7,7
    db 7,6,7,7,0,0,0,0,7,0,0,0,0,7,7,7
    db 7,0,0,0,0,0,0,0,1,0,0,0,0,1,0,4
    db 7,0,7,7,0,0,0,0,7,9,7,0,7,7,7,7
    db 7,5,7,7,9,7,7,7,7,7,7,2,7,7,7,7
pickups:
    db 4
    ; item type, x, y, sprite
    db ITEM_KEY   , 7*16+8,1*16+8,SPRITE_PATTERN_KEY
    db ITEM_KEY   ,13*16+8,1*16+8,SPRITE_PATTERN_KEY
    db ITEM_GOLDSWORD , 1*16+8,11*16+8,SPRITE_PATTERN_CHEST     
    db ITEM_ICEARROW , 11*16+8,14*16+8,SPRITE_PATTERN_CHEST     
enemies:
    db 14
    ; enemy type, x, y, sprite, color, hit points, state1, state2, state3
    ; switch puzzle:
    db ENEMY_SWITCH , 9*16+8, 7*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_CHANGE_OTHER_SWITCH,2
    db ENEMY_SWITCH ,10*16+8, 7*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_CHANGE_OTHER_SWITCH,0
    db ENEMY_SWITCH ,11*16+8, 7*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_CHANGE_OTHER_SWITCH,4
    db ENEMY_SWITCH ,12*16+8, 7*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_CHANGE_OTHER_SWITCH,2
    db ENEMY_SWITCH ,13*16+8, 7*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_OPEN_MEDUSA1_GATE,11+5*16

    db ENEMY_SWITCH , 7*16+8,12*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_OPEN_GATE,6+11*16
    db ENEMY_SWITCH , 7*16+8, 6*16+8,    ENEMY_SWITCH_RIGHT_SPRITE_PATTERN,   15, 1,SWITCH_STATE_RIGHT,EVENT_OPEN_GATE,6+3*16

    db ENEMY_SKELETON   , 6*16+4,14*16+8,    ENEMY_SKELETON_SPRITE_PATTERN,   15, 2,0,0,0       
    db ENEMY_SKELETON   , 6*16+4,12*16+8,    ENEMY_SKELETON_SPRITE_PATTERN,   15, 2,0,0,0       
    db ENEMY_KNIGHT     , 1*16+4, 6*16+8,    ENEMY_KNIGHT_SPRITE_PATTERN,      7, 3,0,0,0       
    db ENEMY_KNIGHT     , 6*16+4, 6*16+8,    ENEMY_KNIGHT_SPRITE_PATTERN,      7, 3,0,0,0       
    db ENEMY_KNIGHT     , 3*16+4, 1*16+8,    ENEMY_KNIGHT_SPRITE_PATTERN,      7, 3,0,0,0       
    db ENEMY_KNIGHT     , 7*16+4, 1*16+8,    ENEMY_KNIGHT_SPRITE_PATTERN,      7, 3,0,0,0       
    db ENEMY_SKELETON   ,11*16+4, 1*16+8,    ENEMY_SKELETON_SPRITE_PATTERN,   11, 4,0,0,0       

events_map:
    db 0
    ; x, y, event ID (the first 4 IDs are reserved for 4 potential messages below (each of them
    ;                        4 lines of 22 characters each))
;    db #b0, #e0, 0
messages_map:
    dw 0 ;; length of the message data block below
