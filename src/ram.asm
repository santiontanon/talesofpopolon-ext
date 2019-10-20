    org #c000   ; RAM goes to the 4th slot
RAM:    

; ----------------------------------------------------------------
; RAM that is shared acorss all game states:
; ----------------------------------------------------------------

; Music variables:
MUSIC_tempo:                        ds virtual 1
beginning_of_sound_variables_except_tempo:
MUSIC_play:                         ds virtual 1
MUSIC_tempo_counter:                ds virtual 1
MUSIC_instruments:                  ds virtual N_MUSIC_CHANNELS
MUSIC_channel3_instrument_buffer:   ds virtual 1    ;; this stores the instrument of channel 3, which is special, since SFX might overwrite it
MUSIC_start_pointer:                ds virtual 2  
SFX_pointer:                        ds virtual 2
MUSIC_pointer:                      ds virtual 2
MUSIC_repeat_stack_ptr:             ds virtual 2    
MUSIC_repeat_stack:                 ds virtual 4*3  
MUSIC_instrument_envelope_ptr:      ds virtual N_MUSIC_CHANNELS*2  
SFX_priority:                       ds virtual 1    ; the SFX from the game have more priority than those triggered by music
;MUSIC_transpose:                    ds virtual 1
MUSIC_time_step_required:           ds virtual 1    
end_of_sound_variables:
music_buffer:                       ds virtual 1152  ; size of the longest song


game_state:             			ds virtual 1
;; stores which exit the player entered, to know which map to load in the inter-map state
exit_entered: 
;; temporary variable used in the title screen for storing animation state
title_state:            			ds virtual 1
title_state2:           			ds virtual 1
story_skip:                         ds virtual 1

MSXTurboRMode:                      ds virtual 1
; I ended up not using this, since I don't have enough bytes in the ROM to support it...
raycast_double_buffer:		    	ds virtual 1	;; This variable is only used in MSX2 or higher for using double buffering, and remove flickering when rendering
													;; if "raycast_double_buffer =  0", we are showing in the usual VDP addresses
													;; if "raycast_double_buffer != 0", we are showing the secondary buffer (usual addresses + #4000)
raycast_use_double_buffer:	    	ds virtual 1	;; this is 0 if the MSX only has 16KB of VRAM, and 1 otherwise, so we can use double buffering
interrupts_per_game_frame:			ds virtual 1

SP_buffer_for_fast_memory_clear:	ds virtual 2

previous_keymatrix0:    ds virtual 1
game_interrupt_cycle: 	ds virtual 1

END_OF_COMMON_RAM:


; ----------------------------------------------------------------
; RAM that is needed during gameplay:
; ----------------------------------------------------------------
	org END_OF_COMMON_RAM
; Space for ROMtoRAM:

RAM_gameStart:
player_precision_x:     ds virtual 2
player_precision_y:     ds virtual 2
player_angle:           ds virtual 1
; game state variables:
game_cycle:             ds virtual 1
player_map:             ds virtual 1
player_x:               ds virtual 1
player_y:               ds virtual 1
player_health:          ds virtual 1
available_weapons:      ds virtual N_WEAPONS
available_secondary_weapons:    ds virtual N_SECONDARY_WEAPONS
available_armors:       ds virtual N_ARMORS
;; Table that stores which patterns are currently loaded on the VDP sprite 
;; patterns 24 - 31.
;; the number here indexes the list of enemy sprite patterns (enemySpritePatterns)
spritePatternCacheTable:        ds virtual 8
; texture_colors:         ds virtual 11
initial_rendering_blocks:   ds virtual 5
initial_rendering_address:  ds virtual 8
amount_of_bytes_to_render: ds virtual 1
raycast_angle_offset:       ds virtual 1
raycast_amount_to_clear:    ds virtual 2
raycast_sprite_angle_cutoff: ds virtual 1
EndOfRAM_gameStart:


memoryToClearOnNewGame:
game_over_cycle:        ds virtual 1
player_hit_timmer:      ds virtual 1
player_mana:            ds virtual 1
player_keys:            ds virtual 1
player_state:           ds virtual 1
player_state_cycle:     ds virtual 1
spritePatternCacheTableNextToErase:     ds virtual 1

; sprites:
knight_sprite_attributes:           ds virtual 4
knight_sprite_outline_attributes:   ds virtual 4
sword_sprite_attributes:            ds virtual 4
other_sprite_attributes:            ds virtual 4*(N_SPRITE_DEPTHS*N_SPRITES_PER_DEPTH)
knight_animation_frame:             ds virtual 1
knight_animation_frame_in_vdp:		ds virtual 1	; so that if this is the same as knight_animation_frame, we don't need to upload it again

n_sprites_uploaded_last_cycle:		ds virtual 1
sprites_available_per_depth:        ds virtual N_SPRITE_DEPTHS
assignSprite_y:                     ds virtual 1
assignSprite_x:                     ds virtual 1
assignSprite_sprite:                ds virtual 1
assignSprite_color:                 ds virtual 1
assignSprite_bank:                  ds virtual 1
assigningSpritesForAnEnemy:         ds virtual 1

; position of the camera in the frame that is currently rendered in the screen:
last_raycast_camera_x:              ds virtual 1
last_raycast_camera_y:              ds virtual 1
last_raycast_player_angle:          ds virtual 1

;; global game state:
globalState_doorsOpen:              ds virtual N_MAPS*MAX_DOORS_PER_MAP
globalState_itemsPickedUp:          ds virtual N_MAPS*MAX_PICKUPS_PER_MAP
globalState_BossesKilled:           ds virtual 4
current_weapon:                     ds virtual 1
current_secondary_weapon:           ds virtual 1
current_armor:                      ds virtual 1
current_armor_color:                ds virtual 1
arrow_data:                         ds virtual ARROW_STRUCT_SIZE*MAX_ARROWS
hourglass_timer:                    ds virtual 1
current_UI_message:                 ds virtual 32
current_UI_message_timer:           ds virtual 1
; whether SPACE/TRIGGER1 or M/TRIGGER2 were pressed in the previous game cycle or not
previous_trigger1:                  ds virtual 1
previous_trigger2:                  ds virtual 1

raycast_screen_size_change_requested:   ds virtual 1
CPUmode_change_requested:           ds virtual 1    

endOfMemoryToClearOnNewGame:

message_skip:                         ds virtual 1

; raycast variables:
raycast_player_x:                   ds virtual 1
raycast_player_y:                   ds virtual 1
raycast_camera_x:                   ds virtual 1
raycast_camera_y:                   ds virtual 1
raycast_player_angle:               ds virtual 1
raycast_first_column:               ds virtual 1
raycast_last_column:                ds virtual 1
raycast_column:                     ds virtual 1
raycast_camera_offset:              ds virtual 1
raycast_buffer_offset_bank1:        ds virtual 2
raycast_buffer_offset_bank2:        ds virtual 2
raycast_column_pixel_mask:          ds virtual 1
raycast_ceiling_type:				ds virtual 1	; 0: ceiling, 1: skybox
raycast_texture_set:				ds virtual 1
raycast_floor_texture_color:        ds virtual 1
raycast_ceiling_texture_color:      ds virtual 1
raycast_column_x_offs_table_xangle_times_32:    ds virtual 2

patternCopyBuffer2:
password_buffer:                    ds virtual 32

skybox_buffer:						ds virtual 384

    ;; 256 - align several buffers, so that I can address them directly by 
    ;; modifying the low byte of the registers
    ds virtual ((($-1)/#100)+1)*#100-$
textures_before:

raycast_divide_by16_table:			ds virtual 256	; 256-alignned

textures:                           ds virtual 16*32*MAX_TEXTURES	; 256-alignned

currentMap:                         ds virtual 16*16	; 256-alignned

raycast_buffer:                     ds virtual (32-RAYCAST_SIDE_BORDER*2)*4*16	; 256-alignned
raycast_color_buffer:               ds virtual (32-RAYCAST_SIDE_BORDER*2)*4*16	; 256-alignned

patternCopyBuffer:                  ; this is used as an intermediate buffer, to copy patterns from one page of VDP to another
;; stores the texture of the floor (calculated in the ceiling)
raycast_floor_texture_buffer:       ds virtual 32

currentMapPickups:                  ds virtual 1+4*MAX_PICKUPS_PER_MAP
currentMapEnemies:                  ds virtual 1+ENEMY_STRUCT_SIZE*MAX_ENEMIES_PER_MAP
currentMapEvents:                   ds virtual 1+3*MAX_EVENTS_PER_MAP
currentMapMessages:                 ds virtual 4*22*MAX_MESSAGES_PER_MAP

currentMapDoorLocations:            ds virtual MAX_DOORS_PER_MAP

raycast_renderer:					ds virtual 932	; space where the raycasting routine will be decompressed
raycast_update_selfmodifying_ceiling_code_entry_point:	equ raycast_renderer
raycast_render_to_buffer:			equ raycast_renderer+3

endOfRAM:

