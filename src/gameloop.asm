;-----------------------------------------------
; setup all the necessary variables to start a new game!
initializeGame:
    call clearScreenLeftToRight
    call initializeMemory

    ld hl,skybox_moon_pletter
    ld de,skybox_buffer
    call pletter_unpack

    ld hl,raycasting_code_pletter
    ld de,raycast_renderer
    call pletter_unpack

    ld bc,#e301  ;; write #e2 in VDP register #01 (activate sprites, generate interrupts, 16x16 sprites with magnification)
    call WRTVDP

    call StopPlayingMusic

    ; load common textures:
    ld hl,textures_A_pletter
    ld de,textures
    call pletter_unpack

    ld a,6
    ld hl,ToPInGameSongPletter
    call PlayCompressedSong

    call setupSprites

    ld hl,knight_animation_frame_in_vdp
    ld (hl),#ff
    ld hl,n_sprites_uploaded_last_cycle
    ld (hl),0

    call calculate_divide_by16_table

    jp setupUIPatterns


;-----------------------------------------------
; Main game loop!
Game_Loop:    
    call initializeGame
    ; load the first map:
    ld hl,map_tunnel1_pletter
    ; ld hl,map_fortress1_pletter
    ; ld hl,map_catacombs1_pletter
    ; ld hl,map_medusa1_pletter

    ; ld a,1
    ; ld (available_armors+1),a ; start with silver armor

Game_Loop_after_setting_map:
    call loadMap

    call update_UI_keys
    call update_UI_health
    call update_UI_mana
    call raycast_reset  
    call raycast_update_selfmodifying_ceiling_code_entry_point  

    call raycastCompleteRender
    
    ;; reset the speed control counter
    ld a,(interrupts_per_game_frame)
    ld (game_interrupt_cycle),a

Game_Loop_loop:

    out (#2c),a    

    ld a,150
    ld (SCNCNT),a ; NYYRIKKI: Pause keyboard scan, play queue handling etc. for 3 sec.

    ;; ---- SUBFRAME 1 ----
    call Game_Update_Cycle
    call Game_updateRaycastVariables
    call raycast_reset_clear_buffer
    ld hl,initial_rendering_blocks
    ld de,raycast_first_column
    push de
    ldi
    ldi
    call raycast_render_to_buffer

    ;; ---- SUBFRAME 2 ----
    call Game_Update_Cycle
    ld hl,initial_rendering_blocks+1
    pop de
    push de
    ldi
    ldi
    call raycast_render_to_buffer

    ;; ---- SUBFRAME 3 ----
    call Game_Update_Cycle
    ld hl,initial_rendering_blocks+2
    pop de
    push de
    ldi
    ldi
    call raycast_render_to_buffer

    ;; ---- SUBFRAME 4 ----
    call Game_Update_Cycle
    ld hl,initial_rendering_blocks+3
    pop de
    ldi
    ldi
    call raycast_render_to_buffer
    call raycast_render_buffer

    ld a,(raycast_screen_size_change_requested)
    or a
    call nz,Game_trigger_screen_size_change
    ld a,(CPUmode_change_requested)
    or a
    call nz,Game_trigger_CPUmode_change
    xor a
    ld (raycast_screen_size_change_requested),a
    ld (CPUmode_change_requested),a

    call saveLastRaycastVariables

    out (#2d),a    

    jr Game_Loop_loop


raycastCompleteRender:
    call Game_updateRaycastVariables
    call raycast_reset_clear_buffer
    ld a,(initial_rendering_blocks)
    ld (raycast_first_column),a
    ld a,(initial_rendering_blocks+4)
    ld (raycast_last_column),a
    call raycast_render_to_buffer
    call raycast_render_buffer
saveLastRaycastVariables:
    ld a,(raycast_camera_x)
    ld (last_raycast_camera_x),a
    ld a,(raycast_camera_y)
    ld (last_raycast_camera_y),a
    ld a,(raycast_angle_offset)
    ld b,a
    ld a,(raycast_player_angle)
    add a,b
    ld (last_raycast_player_angle),a
    ret


Game_updateRaycastVariables:
    ;; angle:
    ld de,player_angle
    ld a,(de)
    ld hl,raycast_angle_offset
    sub (hl)
    ld (raycast_player_angle),a

    ;; position:
    ld hl,cos_table_x12
    ld b,0
    ld a,(de)
    add a,128
    ld c,a
    add hl,bc
    add hl,bc
    push hl
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld hl,(player_precision_x)
    add hl,bc
    ld a,h
    ld (raycast_camera_x),a

    pop hl
    ld bc,sin_table_x12-cos_table_x12
    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld hl,(player_precision_y)
    add hl,bc
    ld a,h
    ld (raycast_camera_y),a

    ret


Game_trigger_screen_size_change:
    ld a,(initial_rendering_blocks+4)
    cp 192
    ld hl,ROM_initial_rendering_blocks_160
    jr z,Game_trigger_screen_size_change2
    cp 160
    ld hl,ROM_initial_rendering_blocks_128
    jr z,Game_trigger_screen_size_change2
    ld hl,ROM_initial_rendering_blocks_192

Game_trigger_screen_size_change2:
    ld de,initial_rendering_blocks
    ld bc,18
    ldir
    jp raycast_reset
    

;-----------------------------------------------
; modes are:
; 0: Z80
; 1: R800 smooth
Game_trigger_CPUmode_change:
    ld a,(CHGCPU)
    cp #C3
    ret nz  ; if we are not in a turbo R, just ignore
    ld hl,MSXTurboRMode
    ld a,(hl)
    inc a
    and #01
    ld (hl),a
    jr z,Game_trigger_CPUmode_change_z80
Game_trigger_CPUmode_change_r800_smooth:
    ld hl,UI_message_r800smooth_mode
    ld c,UI_message_r800smooth_mode_end-UI_message_r800smooth_mode
    call displayUIMessage
    ld a,#82       ; R800 DRAM
    jp CHGCPU
Game_trigger_CPUmode_change_z80:
    ld hl,UI_message_z80_mode
    ld c,UI_message_z80_mode_end-UI_message_z80_mode
    call displayUIMessage
    ld a,#80       ; Z80 DRAM
    jp CHGCPU

