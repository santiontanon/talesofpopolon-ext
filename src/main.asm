    include "constants.asm"

    org #4000   ; Start in the 2nd slot

;-----------------------------------------------
    db "AB"     ; ROM signature
    dw Execute  ; start address
    db 0,0,0,0,0,0,0,0,0,0,0,0
;-----------------------------------------------


;-----------------------------------------------
; Code that gets executed when the game starts
Execute:
    ; init the stack:
    ld sp,#F380
    ; reset some interrupts to make sure it runs in some MSX computers 
    ; with disk controllers installed in some interrupt handlers
    di
    ld a,#C9
    ld (HKEY),a
;    ld (TIMI),a
    ei

    call setupROMRAMslots

    ; Silence and init keyboard:
    xor a
    ld (MSXTurboRMode),a    ; Z80 mode
    ld (CLIKSW),a
    ; Change background colors:
    ld (BAKCLR),a
    ld (BDRCLR),a
    call CHGCLR
    
    ; Activate Turbo mode in Panasonic MSX2+ WX/WSX/FX models:
    ; Code sent to me by Pitpan, taken from here: http://map.grauw.nl/resources/msx_io_ports.php
    ld a,8
    out (#40),a     ;out the manufacturer code 8 (Panasonic) to I/O port 40h
    in a,(#40)      ;read the value you have just written
    cpl             ;complement all bits of the value
    cp 8            ;if it does not match the value you originally wrote,
    jr nz,Not_WX    ;it is not a WX/WSX/FX.
    xor a           ;write 0 to I/O port 41h
    out (#41),a     ;and the mode changes to high-speed clock    
Not_WX:

    ld a,(CHGCPU)
    cp #C3
    jr nz,Not_TurboR  ; if we are not in a turbo R, just ignore
    ld hl,MSXTurboRMode
    inc (hl)
    ld a,#82       ; R800 DRAM
    call CHGCPU
Not_TurboR:

    call checkAmountOfVRAM
    call CheckIf60Hz
    ld hl,interrupts_per_game_frame
    or a
    jp z,set_game_speed_50hz
set_game_speed_60hz:
    ld (hl),4
    jr game_speed_set
set_game_speed_50hz:
    ld (hl),3
game_speed_set:


    ld a,2      ; Change screen mode
    call CHGMOD

    ;; clear the screen, and load graphics
    xor a
    call FILLSCREEN
    call setupPatterns  ; Note: this overwrites a few raycasting buffers

    call Setup_Game_Interrupt

    xor a
;    ld a,GAME_STATE_SPLASH
;    ld a,GAME_STATE_TITLE
;    ld a,GAME_STATE_STORY
    ld a,GAME_STATE_PLAYING
    jp change_game_state
;    jp Game_Loop


;-----------------------------------------------
; Loads the interrupt hook for keep track of game speed and playing music/SFX:
Setup_Game_Interrupt:
    call StopPlayingMusic
    ld a,8
    ld (MUSIC_tempo),a  ;; default music tempo

    ld  a,JPCODE    ;NEW HOOK SET
    di
    ld  (TIMI),a
    ld  hl,Game_Interrupt
    ld  (TIMI+1),hl
    ei
    ret

Game_Interrupt:
    push hl
    ld hl,game_interrupt_cycle
    inc (hl)

    call update_sound

    pop hl
    ret


;-----------------------------------------------
; additional assembler files
    include "auxiliar.asm"
    include "gamestates.asm"
    include "splash.asm"
    include "title.asm"
    include "story.asm"    
    include "gameloop.asm"
    include "gameplay.asm"
    include "input.asm"
    include "player.asm"
    include "sincostables.asm"
    include "gfx.asm"
    include "raycasting-auxiliar.asm"
    include "maps.asm"
    include "enemies.asm"
    include "sound.asm"
    include "sfx.asm"
    include "password.asm"

ToPStorySongPletter:
  incbin "tocompress/ToPStorySong.plt"

ToPInGameSongPletter: 
  incbin "tocompress/ToPInGameSong.plt"

ToPBossSongPletter:  
  incbin "tocompress/ToPBossSong.plt"

ToPStartSongPletter:
  incbin "tocompress/ToPStartSong.plt"

ToPGameOverSongPletter:  
  incbin "tocompress/ToPGameOverSong.plt"

    include "sprite-data.asm"
    include "raycasting-rayxoffstable.asm"
    include "raycasting-textureverticalratetable.asm"

story_pletter:
    incbin "tocompress/story.plt"
ending_pletter:
    incbin "tocompress/ending.plt"
    
map_tunnel1_pletter:
    incbin "tocompress/map-tunnel1.plt"
map_fortress1_pletter:
    incbin "tocompress/map-fortress1.plt"
map_fortress2_pletter:
    incbin "tocompress/map-fortress2.plt"
map_catacombs1_pletter:
    incbin "tocompress/map-catacombs1.plt"
map_catacombs2_pletter:
    incbin "tocompress/map-catacombs2.plt"
map_medusa1_pletter:
    incbin "tocompress/map-medusa1.plt"
map_medusa2_pletter:
    incbin "tocompress/map-medusa2.plt"
map_keres1_pletter:
    incbin "tocompress/map-keres1.plt"
map_keres2_pletter:
    incbin "tocompress/map-keres2.plt"


base_sprites_pletter:
    incbin "tocompress/base-sprites.plt"

patterns_pletter:
    incbin "tocompress/patterns.plt"

texture_pointers:
    dw textures_B_pletter
    dw textures_C_pletter
    dw textures_D_pletter
    dw textures_E_pletter

textures_A_pletter:
    incbin "tocompress/textures-A.plt"
textures_B_pletter:
    incbin "tocompress/textures-B.plt"
textures_C_pletter:
    incbin "tocompress/textures-C.plt"
textures_D_pletter:
    incbin "tocompress/textures-D.plt"
textures_E_pletter:
    incbin "tocompress/textures-E.plt"

skybox_moon_pletter:
    incbin "tocompress/skybox-moon.plt"

ui:
    incbin "tocompress/ui.plt"

ROM_barehand_weapon_patterns:
    db   0,208,209
    db 210,211,212
    db 213,214,215
ROM_sword_weapon_patterns:
    db 224,225,  0
    db 226,227,228
    db   0,229,230
ROM_goldsword_weapon_patterns:
    db 231,232,  0
    db 233,234,235
    db   0,236,237

ROM_barehand_secondaryweapon_patterns:
    db 216,217,  0
    db 218,219,220
    db 221,222,223
ROM_arrow_secondaryweapon_patterns:
    db 238,239,  0
    db 240,241,242
    db 243,244,245
ROM_icearrow_secondaryweapon_patterns:
    db 246,247,0
    db 248,249,250
    db 251,252,253
ROM_hourglass_secondaryweapon_patterns:
    db 119,120,121
    db 122,123,124
    db 125,126,127


;-----------------------------------------------
; Game variables to be copied to RAM at game start
ROMtoRAM_gameStart:
ROM_player_precision_x:
    dw (1*16+8)*256
ROM_player_precision_y:
    dw (3*16+8)*256
ROM_player_angle:
    db 0
ROM_game_cycle:
    db 0
ROM_player_map:
    db MAP_TUNNEL
ROM_player_x:
    db 1*16+8
ROM_player_y:
    db 3*16+8
ROM_player_health:
    db 6
ROM_available_weapons:
    db 1,0,0
ROM_available_secondary_weapons:
    db 1,0,0,0
ROM_available_armors:
    db 1,0,0
ROM_spritePatternCacheTable:
    db #ff,#ff,#ff,#ff,#ff,#ff,#ff,#ff

;ROM_texture_colors:
;    db #80  ; wall 1 
;    db #40  ; wall 2
;    db #a0  ; door
;    db #f0  ; staircase
;    db #e0  ; face
;    db #f0  ; gate (non - openable door)
;    db #70  ; statue
;    db #f0  ; mirror wall 
;    db #f0  ; staircase
;    db #a0  ; prisoner
;    db #a0  ; prisoner
;    db #40  ; wall 2 with torch

;; these define the columns that will be rendered by the raycasting engine at each
;; sub-frame. The first sub-frame renders 0 - 33, the second 34 - 83, etc.
ROM_initial_rendering_blocks_160:
    db 0    ;; note: this assumes that RAYCAST_SIDE_BORDER = 4
    db 34
    db 84
    db 132
    db 160
    dw CHRTBL2+(8*2+8-RAYCAST_ROWS_PER_BANK)*8
    dw CLRTBL2+(8*2+8-RAYCAST_ROWS_PER_BANK)*8
    dw CHRTBL2+(256*8)+2*8*8
    dw CLRTBL2+(256*8)+2*8*8
    db 5
    db 32-(RAYCAST_SIDE_BORDER+2)*2
    dw (32-(RAYCAST_SIDE_BORDER+2)*2)*4*8
    db 20
endROMtoRAM_gameStart:


ROM_initial_rendering_blocks_192:
    db 0    ;; note: this assumes that RAYCAST_SIDE_BORDER = 4
    db 42
    db 100
    db 158
    db 192
ROM_initial_rendering_address
    dw CHRTBL2+(8-RAYCAST_ROWS_PER_BANK)*8  
    dw CLRTBL2+(8-RAYCAST_ROWS_PER_BANK)*8
    dw CHRTBL2+(256*8)
    dw CLRTBL2+(256*8)
ROM_amount_of_bytes_to_render: ; in units of 256 bytes
    db 6
ROM_raycast_angle_offset:
    db 32-RAYCAST_SIDE_BORDER*2
ROM_raycast_amount_to_clear:
    dw (32-RAYCAST_SIDE_BORDER*2)*4*8
ROM_raycast_sprite_angle_cutoff:
    db 24


ROM_initial_rendering_blocks_128:
    db 0    ;; note: this assumes that RAYCAST_SIDE_BORDER = 4
    db 28
    db 66
    db 104
    db 128
    dw CHRTBL2+(8*4+8-RAYCAST_ROWS_PER_BANK)*8
    dw CLRTBL2+(8*4+8-RAYCAST_ROWS_PER_BANK)*8
    dw CHRTBL2+(256*8)+4*8*8
    dw CLRTBL2+(256*8)+4*8*8
    db 4
    db 32-(RAYCAST_SIDE_BORDER+4)*2
    dw (32-(RAYCAST_SIDE_BORDER+4)*2)*4*8
    db 16


UI_message_equip_barehand:
    db "BARE HANDS"
UI_message_equip_barehand_end:
UI_message_equip_sword:
    db "SWORD"
UI_message_equip_sword_end:
UI_message_equip_goldsword:
    db "GOLD SWORD"
UI_message_equip_goldsword_end:

;UI_message_equip_secondary_barehand:
;    db "BARE HANDS"
;UI_message_equip_secondary_barehand_end:
UI_message_equip_secondary_arrow:
    db "ARROWS"
UI_message_equip_secondary_arrow_end:
UI_message_equip_secondary_icearrow:
    db "ICE ARROWS"
UI_message_equip_secondary_icearrow_end:
UI_message_equip_secondary_hourglass:
    db "HOURGLASS"
UI_message_equip_secondary_hourglass_end:

UI_message_equip_armor_iron:
    db "IRON ARMOR"
UI_message_equip_armor_iron_end:
UI_message_equip_armor_silver:
    db "SILVER ARMOR"
UI_message_equip_armor_silver_end:
UI_message_equip_armor_gold:
    db "GOLD ARMOR"
UI_message_equip_armor_gold_end:

UI_message_z80_mode:
    db "Z80"
UI_message_z80_mode_end:

UI_message_r800smooth_mode:
    db "R800"
UI_message_r800smooth_mode_end:

UI_message_pause:
    db "PAUSE"
UI_message_pause_end:

UI_message_game_over:
    db "GAME OVER"

UI_message_enter_password:
    db "ENTER PASSWORD"
UI_message_enter_password_end:

splash_line2:  ; length 8
    db "PRESENTS"
splash_line1:  ; length 12
    db "BRAIN  GAMES" 

title_press_space:  
    db "SPACE TO PLAY"    
title_press_space_end:

title_m_for_password:  
    db "M FOR PASSWORD"    
title_m_for_password_end:

title_credits1:  ; length 16
    db "EXTENDED VERSION"
title_credits2:  ; length 20
    db "SANTI ONTANON   2019"

fadeInTitleColors:  ; the two zeroes at the beginning and end are sentinels
    db 0,#ff,#ef,#7f,#5f,#4f,0
End:


; this table is also 256 aligned, since the previous three are
pixel_bit_masks:
    ; handle blocks of 2 pixels at a time
    db #c0, #c0, #30, #30, #0c, #0c, #03, #03

;pixel_bit_masks_zero:
;    ; handle blocks of 2 pixels at a time
;    db #3f, #3f, #cf, #cf, #f3, #f3, #fc, #fc


    ; align to byte        
    ; align #100
    ds ((($-1)/#100)+1)*#100-$        
        ;;;;;;;; atan(2^(x/32))*128/pi ;;;;;;;;
atan_tab:   
    db #20,#20,#20,#21,#21,#22,#22,#23,#23,#23,#24,#24,#25,#25,#26,#26
    db #26,#27,#27,#28,#28,#28,#29,#29,#2A,#2A,#2A,#2B,#2B,#2C,#2C,#2C
    db #2D,#2D,#2D,#2E,#2E,#2E,#2F,#2F,#2F,#30,#30,#30,#31,#31,#31,#31
    db #32,#32,#32,#32,#33,#33,#33,#33,#34,#34,#34,#34,#35,#35,#35,#35
    db #36,#36,#36,#36,#36,#37,#37,#37,#37,#37,#37,#38,#38,#38,#38,#38
    db #38,#39,#39,#39,#39,#39,#39,#39,#39,#3A,#3A,#3A,#3A,#3A,#3A,#3A
    db #3A,#3B,#3B,#3B,#3B,#3B,#3B,#3B,#3B,#3B,#3B,#3B,#3C,#3C,#3C,#3C
    db #3C,#3C,#3C,#3C,#3C,#3C,#3C,#3C,#3C,#3D,#3D,#3D,#3D,#3D,#3D,#3D
    db #3D,#3D,#3D,#3D,#3D,#3D,#3D,#3D,#3D,#3D,#3D,#3D,#3E,#3E,#3E,#3E
    db #3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E
    db #3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3E,#3F,#3F,#3F,#3F
    db #3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F
    db #3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F
    db #3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F
    db #3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F
    db #3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F,#3F

    ;;;;;;;; log2(x)*32 ;;;;;;;; 
log2_tab:  
    db #00,#00,#20,#32,#40,#4A,#52,#59,#60,#65,#6A,#6E,#72,#76,#79,#7D
    db #80,#82,#85,#87,#8A,#8C,#8E,#90,#92,#94,#96,#98,#99,#9B,#9D,#9E
    db #A0,#A1,#A2,#A4,#A5,#A6,#A7,#A9,#AA,#AB,#AC,#AD,#AE,#AF,#B0,#B1
    db #B2,#B3,#B4,#B5,#B6,#B7,#B8,#B9,#B9,#BA,#BB,#BC,#BD,#BD,#BE,#BF
    db #C0,#C0,#C1,#C2,#C2,#C3,#C4,#C4,#C5,#C6,#C6,#C7,#C7,#C8,#C9,#C9
    db #CA,#CA,#CB,#CC,#CC,#CD,#CD,#CE,#CE,#CF,#CF,#D0,#D0,#D1,#D1,#D2
    db #D2,#D3,#D3,#D4,#D4,#D5,#D5,#D5,#D6,#D6,#D7,#D7,#D8,#D8,#D9,#D9
    db #D9,#DA,#DA,#DB,#DB,#DB,#DC,#DC,#DD,#DD,#DD,#DE,#DE,#DE,#DF,#DF
    db #DF,#E0,#E0,#E1,#E1,#E1,#E2,#E2,#E2,#E3,#E3,#E3,#E4,#E4,#E4,#E5
    db #E5,#E5,#E6,#E6,#E6,#E7,#E7,#E7,#E7,#E8,#E8,#E8,#E9,#E9,#E9,#EA
    db #EA,#EA,#EA,#EB,#EB,#EB,#EC,#EC,#EC,#EC,#ED,#ED,#ED,#ED,#EE,#EE
    db #EE,#EE,#EF,#EF,#EF,#EF,#F0,#F0,#F0,#F1,#F1,#F1,#F1,#F1,#F2,#F2
    db #F2,#F2,#F3,#F3,#F3,#F3,#F4,#F4,#F4,#F4,#F5,#F5,#F5,#F5,#F5,#F6
    db #F6,#F6,#F6,#F7,#F7,#F7,#F7,#F7,#F8,#F8,#F8,#F8,#F9,#F9,#F9,#F9
    db #F9,#FA,#FA,#FA,#FA,#FA,#FB,#FB,#FB,#FB,#FB,#FC,#FC,#FC,#FC,#FC
    db #FD,#FD,#FD,#FD,#FD,#FD,#FE,#FE,#FE,#FE,#FE,#FF,#FF,#FF,#FF,#FF

    ; 256 bytes aligned
    include "distancetoyfromsumtable.asm"

    ; this goes at the end, so that changes in size do not change the addresses of the rest of the program
raycasting_code_pletter:
    incbin "tocompress/raycasting.plt"


EndofRom:
    ds ((($-1)/#4000)+1)*#4000-$


    include "ram.asm"

