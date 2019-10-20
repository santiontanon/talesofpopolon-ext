;-----------------------------------------------
; executes one update cycle of the player (Called at each game cycle)
updatePlayer:
    ld a,(player_hit_timmer)
    or a
    jp z,updatePlayer_continue
    dec a
    ld (player_hit_timmer),a
    and #01
    jr z,updatePlayer_flashin
updatePlayer_flashout:
    ld a,8  ;; flash the knight red color
    ld (knight_sprite_attributes+3),a
    jr updatePlayer_continue
updatePlayer_flashin:
    ld a,(current_armor_color)
    ld (knight_sprite_attributes+3),a

updatePlayer_continue:
    ld a,(player_state)
    or a
    jr z,updatePlayer_walking
    dec a
    jr z,updatePlayer_attack
    jr updatePlayer_cooldown

updatePlayer_walking:
    ld a,(player_state_cycle)
    inc a
    ld (player_state_cycle),a
    and #03
    ret nz
    ld a,(knight_animation_frame)
    and 32
    xor 32*1
    ld (knight_animation_frame),a
    ret

updatePlayer_attack:
    ld a,32*2
    ld (knight_animation_frame),a
    ld a,(current_weapon)
    dec a
    call z,updatePlayer_attack_sword
    dec a
    call z,updatePlayer_attack_goldsword
    ld a,(player_state_cycle)
    inc a
    ld (player_state_cycle),a
    cp 3
    jp m,updatePlayer_sword_continue  
    ld a,PLAYER_STATE_COOLDOWN
    ld (player_state),a
    xor a
    ld (player_state_cycle),a
updatePlayer_sword_continue:
    ret
updatePlayer_attack_sword:
    ld a,SWORD_COLOR
    ld (knight_sprite_attributes+11),a
updatePlayer_attack_sword_2:
    ld a,127-40
    ld (knight_sprite_attributes+8),a
    ret
updatePlayer_attack_goldsword:
    ld a,GOLDSWORD_COLOR
    ld (knight_sprite_attributes+11),a
    jr updatePlayer_attack_sword_2

updatePlayer_cooldown:
    ld a,(player_state_cycle)
    inc a
    ld (player_state_cycle),a
    and #01
    ret z
    ld a,(knight_animation_frame)
    and 32
    xor 32*1
    ld (knight_animation_frame),a
    ld a,200
    ld (knight_sprite_attributes+8),a    ; place the sword sprites somewhere outside of the screen
    ld (knight_sprite_attributes+12),a    ; place the sword sprites somewhere outside of the screen
    ld a,PLAYER_STATE_WALKING
    ld (player_state),a
    ret


;-----------------------------------------------
; movement functions of the player
TurnLeft:
    push af
    ld a,(previous_trigger1)
    or a
    jp nz,MoveLeft_nopush
    ld a,(player_angle)
    add a,-4
    ld (player_angle),a
    pop af
    ret

TurnRight:  
    push af
    ld a,(previous_trigger1)
    or a
    jp nz,MoveRight_nopush
    ld a,(player_angle)
    add a,4
    ld (player_angle),a
    pop af
    ret

MoveForward:  
    push af
    ld hl,cos_table
    ld b,0
    ld a,(player_angle)
    ld c,a
    add hl,bc
    add hl,bc
    push hl
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld hl,(player_precision_x)
    add hl,bc
    ld a,(player_y)
    ld b,a
    ld c,h
    call getMapPosition
    cp MAP_TILE_DOOR    
    call z,openDoor   ; after this call, "a" contains the new value of the map position (0 if the door was open, or MAP_TILE_DOOR otherwise)
    cp MAP_TILE_EXIT
    jr z,popHLAndJumpToWalkedIntoAnExit
    cp MAP_TILE_EXIT2
    jr z,popHLAndJumpToWalkedIntoAnExit
    cp MAP_TILE_MIRROR_WALL
    call z,walkedIntoAMirrorWall
    or a
    jr nz,MoveForward_skip_x
    ld (player_precision_x),hl
    ld a,h
    ld (player_x),a
MoveForward_skip_x:
    pop hl
    ld bc,sin_table-cos_table
    add hl,bc
;    ld hl,sin_table
;    ld b,0
;    ld a,(player_angle)
;    ld c,a
;    add hl,bc
;    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld hl,(player_precision_y)
    add hl,bc
    ld a,(player_x)
    ld c,a
    ld b,h
    call getMapPosition
    cp MAP_TILE_DOOR    
    call z,openDoor   ; after this call, "a" contains the new value of the map position (0 if the door was open, or MAP_TILE_DOOR otherwise)
    cp MAP_TILE_EXIT
    jp z,walkedIntoAnExit
    cp MAP_TILE_EXIT2
    jp z,walkedIntoAnExit
    cp MAP_TILE_MIRROR_WALL
    call z,walkedIntoAMirrorWall
    or a
    jr nz,MoveForward_skip_y
    ld (player_precision_y),hl
    ld a,h
    ld (player_y),a
MoveForward_skip_y:
    call checkPickups
    pop af
    ret

popHLAndJumpToWalkedIntoAnExit:
    pop hl
    jp walkedIntoAnExit

MoveBackwards:  
    push af
    ld a,(player_angle)
    add a,128
    ld (player_angle),a
    call MoveForward
    ld a,(player_angle)
    add a,128
    ld (player_angle),a
MoveBackwards_do_not_reset_angle:
    pop af
    ret

MoveRight:  
    push af
MoveRight_nopush:
    ld a,(player_angle)
    add a,64
    ld (player_angle),a
    call MoveForward
    ld a,(player_angle)
    add a,-64
    ld (player_angle),a
    pop af
    ret

MoveLeft:  
    push af
MoveLeft_nopush:
    ld a,(player_angle)
    add a,-64
    ld (player_angle),a
    call MoveForward
    ld a,(player_angle)
    add a,64
    ld (player_angle),a
    pop af
    ret

fireArrow:
    push af
    ld a,(player_mana)
    or a
    jr z,fireArrow_continue
    ld hl,arrow_data  ; since there can be at most 2 arrows in screen at a time, we just unroll the search loop:
    ld a,(hl)
    or a
    jr z,fireArrow_slot_found
    ld hl,arrow_data+ARROW_STRUCT_SIZE
    ld a,(hl)
    or a
    jr z,fireArrow_slot_found
    jr fireArrow_continue   

fireArrow_slot_found:
    ld a,(player_mana)  ;; use up one heart:
    dec a
    ld (player_mana),a
    ld (hl),ITEM_ARROW   ; state: arrow
fireArrow_slot_found_continue:
    call update_UI_mana
    ; actually fire the arrow: arrow type, low bytes of x,y, precision x,y direction, high bytes of x,y, sprite (10 bytes)
    inc hl
    ld de,player_precision_x
    ex de,hl
    ldi ; player_precision_x
;    ldi
    inc hl
    ldi ; player_precision_y
;    ldi
    ld hl,cos_table
    ld b,0
    ld a,(player_angle)
    ld c,a
    add hl,bc
    add hl,bc
    push hl
    ldi ; direction_vector_x
    ldi
    pop hl
    ld bc,sin_table-cos_table
    add hl,bc
    ldi ; direction_vector_y
    ldi
    ld a,(player_x)
    ld (de),a
    inc de
    ld a,(player_y)
    ld (de),a
    inc de
    ld a,(current_secondary_weapon)
    dec a
    jr nz,fireArrow_setIceArrowSprite
    ld a,SPRITE_PATTERN_ARROW
    jr fireArrow_spriteSet
fireArrow_setIceArrowSprite:
    ld a,SPRITE_PATTERN_ICEARROW
fireArrow_spriteSet:
    ld (de),a

    ; play SFX:
    ld hl,SFX_fire_arrow
    call play_ingame_SFX

fireArrow_continue:
    pop af
    ret


fireIceArrow:
    push af
    ld a,(player_mana)
    cp 2
    jp m,fireArrow_continue
    ld hl,arrow_data  ; since there can be at most 2 arrows in screen at a time, we just unroll the search loop:
    ld a,(hl)
    or a
    jr z,fireIceArrow_slot_found
    ld hl,arrow_data+ARROW_STRUCT_SIZE
    ld a,(hl)
    or a
    jr z,fireIceArrow_slot_found
    jr fireArrow_continue   

fireIceArrow_slot_found:
    ld a,(player_mana)  ;; use up two hearts:
    dec a
    dec a
    ld (player_mana),a
    ld (hl),ITEM_ICEARROW   ; state: ice arrow
    jr fireArrow_slot_found_continue


triggerHourglass:
    push af
    ld a,(player_mana)
    cp 4
    jp m,triggerHourglass_continue
    ld a,(hourglass_timer)
    or a
    jr nz,triggerHourglass_continue

;    call pauseMusic

    ld a,HOURGLASS_TIME
    ld (hourglass_timer),a
    ld a,(player_mana)
    sub 4
    ld (player_mana),a
    call update_UI_mana
triggerHourglass_continue:
    pop af
    ret


;-----------------------------------------------
; Changes the current weapon of the player to the next available one
; Specifically, this function:
; - sets (current_weapon) to the next available weapon
; - updates the UI to reflect the change
ChangeWeapon:
    ;; find the next available weapon:
    ld hl,SFX_weapon_switch
    call play_ingame_SFX

    ld de,current_weapon
    ld a,(de)
    inc a
ChangeWeapon_next_loop:
    ld (de),a
    cp N_WEAPONS
    jr z,ChangeWeapon_overflow
    ld hl,available_weapons
    ADD_HL_A
    ld a,(hl)
    or a
    jr nz,ChangeWeapon_next_found
    jr ChangeWeapon
ChangeWeapon_overflow:
    xor a
    jr ChangeWeapon_next_loop
ChangeWeapon_next_found:
    ld a,(current_weapon)
    or a
    jr z,ChangeWeapon_barehands
    dec a
    jr z,ChangeWeapon_sword
;    dec a
    jr ChangeWeapon_goldsword
    ;; we should never reach here
;    ret
ChangeWeapon_barehands:
    ld hl,UI_message_equip_barehand
    ld c,UI_message_equip_barehand_end-UI_message_equip_barehand
    call displayUIMessage
    ld hl,ROM_barehand_weapon_patterns
    jr ChangeWeapon_change_ui
ChangeWeapon_sword:
    ld hl,UI_message_equip_sword
    ld c,UI_message_equip_sword_end-UI_message_equip_sword
    call displayUIMessage
    ld hl,ROM_sword_weapon_patterns
    call ChangeWeapon_change_ui
    ld hl,sword_sprite
    ld de,SPRTBL2+SWORD_SPRITE*32
    ld bc,32
    jp LDIRVM    
ChangeWeapon_goldsword:
    ld hl,UI_message_equip_goldsword
    ld c,UI_message_equip_goldsword_end-UI_message_equip_goldsword
    call displayUIMessage
    ld hl,ROM_goldsword_weapon_patterns
    call ChangeWeapon_change_ui
    ld hl,goldsword_sprite
    ld de,SPRTBL2+SWORD_SPRITE*32
    ld bc,32
    jp LDIRVM    


ChangeWeapon_change_ui:
    ld de,NAMTBL2+256*2+17+3*32
;    jp ChangeWeapon_change_ui_generic

ChangeWeapon_change_ui_generic:
    push hl
    push de
    ld bc,3
    call LDIRVM
    ld bc,3
    pop de
    pop hl
    add hl,bc
    ld a,e
    add a,32
    ld e,a
    push hl
    push de
    call LDIRVM
    ld bc,3
    pop de
    pop hl
    add hl,bc
    ld a,e
    add a,32
    ld e,a
    jp LDIRVM

ChangeSecondaryWeapon_change_ui:
    ld de,NAMTBL2+256*2+21+3*32
    jr ChangeWeapon_change_ui_generic


;-----------------------------------------------
; Changes the current secondary weapon of the player to the next available one
; Specifically, this function:
; - sets (current_secondary_weapon) to the next available weapon
; - updates the UI to reflect the change
ChangeSecondaryWeapon:
    ld hl,SFX_weapon_switch
    call play_ingame_SFX

    ;; find the next available secondary weapon:
    ld de,current_secondary_weapon
    ld a,(de)
    inc a
ChangeSecondaryWeapon_next_loop:
    ld (de),a
    cp N_SECONDARY_WEAPONS
    jr z,ChangeSecondaryWeapon_overflow
    ld hl,available_secondary_weapons
    ADD_HL_A
    ld a,(hl)
    or a
    jr nz,ChangeSecondaryWeapon_next_found
    jr ChangeSecondaryWeapon
ChangeSecondaryWeapon_overflow:
    xor a
    jr ChangeSecondaryWeapon_next_loop
ChangeSecondaryWeapon_next_found:
    ld a,(current_secondary_weapon)
    or a
    jr z,ChangeSecondaryWeapon_barehands
    dec a
    jr z,ChangeSecondaryWeapon_arrow
    dec a
    jr z,ChangeSecondaryWeapon_icearrow
    jr ChangeSecondaryWeapon_hourglass
ChangeSecondaryWeapon_barehands:
    ld hl,UI_message_equip_barehand
    ld c,UI_message_equip_barehand_end-UI_message_equip_barehand
    call displayUIMessage
    ld hl,ROM_barehand_secondaryweapon_patterns
    jr ChangeSecondaryWeapon_change_ui
ChangeSecondaryWeapon_arrow:
    ld hl,UI_message_equip_secondary_arrow
    ld c,UI_message_equip_secondary_arrow_end-UI_message_equip_secondary_arrow
    call displayUIMessage
    ld hl,ROM_arrow_secondaryweapon_patterns
    jr ChangeSecondaryWeapon_change_ui
ChangeSecondaryWeapon_icearrow:
    ld hl,UI_message_equip_secondary_icearrow
    ld c,UI_message_equip_secondary_icearrow_end-UI_message_equip_secondary_icearrow
    call displayUIMessage
    ld hl,ROM_icearrow_secondaryweapon_patterns
    jr ChangeSecondaryWeapon_change_ui
ChangeSecondaryWeapon_hourglass:
    ld hl,UI_message_equip_secondary_hourglass
    ld c,UI_message_equip_secondary_hourglass_end-UI_message_equip_secondary_hourglass
    call displayUIMessage
    ld hl,ROM_hourglass_secondaryweapon_patterns
    jr ChangeSecondaryWeapon_change_ui

;-----------------------------------------------
; Changes the current armor of the player to the next available one
; Specifically, this function:
; - sets (current_armor) to the next available weapon
; - updates the knight sprite color to reflect the change
ChangeArmor:
    ld hl,SFX_weapon_switch
    call play_ingame_SFX

    ;; find the next available armor:
    ld de,current_armor
    ld a,(de)
    inc a
ChangeArmor_next_loop:
    ld (de),a
    cp N_ARMORS
    jr z,ChangeArmor_overflow
    ld hl,available_armors
    ADD_HL_A
    ld a,(hl)
    or a
    jr nz,ChangeArmor_next_found
    jr ChangeArmor
ChangeArmor_overflow:
    xor a
    jr ChangeArmor_next_loop
ChangeArmor_next_found:
    ld a,(current_armor)    ;; I do not reuse "de" here, since "ChangeArmor_next_found" can be called by the password decoding code
    or a
    jr z,ChangeArmor_default
    dec a
    jr z,ChangeArmor_silver
    jr ChangeArmor_gold
ChangeArmor_default:
    ld hl,UI_message_equip_armor_iron
    ld c,UI_message_equip_armor_iron_end-UI_message_equip_armor_iron
    call displayUIMessage
    ld a,KNIGHT_COLOR
    ld (knight_sprite_attributes+3),a
    ld (current_armor_color),a
    ret
ChangeArmor_silver:
    ld hl,UI_message_equip_armor_silver
    ld c,UI_message_equip_armor_silver_end-UI_message_equip_armor_silver
    call displayUIMessage
    ld a,KNIGHT_SILVER_COLOR
    ld (knight_sprite_attributes+3),a
    ld (current_armor_color),a
    ret
ChangeArmor_gold:
    ld hl,UI_message_equip_armor_gold
    ld c,UI_message_equip_armor_gold_end-UI_message_equip_armor_gold
    call displayUIMessage
    ld a,KNIGHT_GOLD_COLOR
    ld (knight_sprite_attributes+3),a
    ld (current_armor_color),a
    ret


;-----------------------------------------------
; checks if there is an enemy in range of the main weapon, and deals damage
; enemy structures are: (type, x, y, sprite, color, hit points, state1, state2)
playerWeaponSwing:
    ld hl,SFX_sword_swing
    call play_ingame_SFX

    ld a,(current_weapon)
    or a
    jp z,playerWeaponSwing_barehands
    dec a
    jp z,playerWeaponSwing_sword
    ; gold sword:
    ld c,14  ;; long range
    jp playerWeaponSwing_continue
playerWeaponSwing_barehands:
    ld c,8
    jp playerWeaponSwing_continue
playerWeaponSwing_sword:
    ld c,11
playerWeaponSwing_continue:
    ld hl,currentMapEnemies
    ld b,(hl)
    inc hl
playerWeaponSwing_loop:
    ld a,(hl)
    or a
    jp z,playerWeaponSwing_next
    cp ENEMY_EXPLOSION
    jp z,playerWeaponSwing_next    

    ld a,(player_x)
    inc hl
    sub (hl)
    ld e,a
    jp p,playerWeaponSwing_positive_xdiff
    neg
playerWeaponSwing_positive_xdiff:
    cp c    ;; compare with the weapon range
    jp p,playerWeaponSwing_next_x

    ld a,(player_y)
    inc hl
    sub (hl)
    ld d,a
    jp p,playerWeaponSwing_positive_ydiff
    neg
playerWeaponSwing_positive_ydiff:
    cp c    ;; compare with the weapon range
    jp p,playerWeaponSwing_next_y

    ;; check the angle:
    push bc
    push hl
    ld b,e  ; xdiff
    ld c,d  ; ydiff
    call atan2
    add a,128
    ld b,a
    ld a,(player_angle)
    sub b
    pop hl
    pop bc
    jp p,playerWeaponSwing_positive_anglediff
    neg
playerWeaponSwing_positive_anglediff:
    cp 24    ; a +-24 angle degree range
    jp p,playerWeaponSwing_next_y

    dec hl
    dec hl
    ld a,(hl)   ;; we get the enemy type again

    cp ENEMY_MEDUSA_STONE
    jp z,playerWeaponSwing_deflect  ; medusa is invulnerable! (play SFX though)

    cp ENEMY_SWITCH
    jp z,playerWeaponSwing_activateSwitch

    cp ENEMY_BULLET
    jp z,playerWeaponSwing_next
    jp playerWeaponSwing_hitEnemy

playerWeaponSwing_next:
    inc hl
playerWeaponSwing_next_x:
    inc hl
playerWeaponSwing_next_y:
    ld de,ENEMY_STRUCT_SIZE-2
    add hl,de
    djnz playerWeaponSwing_loop
    ret


playerWeaponSwing_hitEnemy:
    ;; enemy hit!
    push hl
    ;; play enemy hit SFX (this will overwrite any previous SFX played):
    ld hl,SFX_hit_enemy
    call play_ingame_SFX
    pop hl

    push hl
    pop iy
    ld a,(iy+5)
    dec a
    ld (iy+5),a
    jp nz,playerWeaponSwing_next
    call killedEnemy
    ld (iy),ENEMY_EXPLOSION
    ld (iy+3),ENEMY_EXPLOSION_SPRITE_PATTERN
    ld (iy+4),ENEMY_EXPLOSION_COLOR
    ld (iy+6),8 ; duration of the explosion
    jp playerWeaponSwing_next


playerWeaponSwing_deflect:
    ;; play enemy deflect SFX (this will overwrite any previous SFX played):
    push hl
    ld hl,SFX_hit_deflected
    call play_ingame_SFX
    pop hl
    jp playerWeaponSwing_next


playerWeaponSwing_activateSwitch:
    push hl
    ld hl,SFX_door_open
    call play_ingame_SFX
    pop hl

    push hl
    pop iy
    ld a,(iy+6)
    or a
    jp z,playerWeaponSwing_activateSwitch_switch_to_1
playerWeaponSwing_activateSwitch_switch_to_0:
    ld (iy+6),0
    ld (iy+3),ENEMY_SWITCH_RIGHT_SPRITE_PATTERN
    ld a,(iy+7)
    push bc
    ld c,(iy+8)
    call triggerEvent
    pop bc
    jp playerWeaponSwing_next
playerWeaponSwing_activateSwitch_switch_to_1:
    ld (iy+6),1
    ld (iy+3),ENEMY_SWITCH_LEFT_SPRITE_PATTERN
    ld a,(iy+7)
    push bc
    ld c,(iy+8)
    call triggerEvent
    pop bc
    jp playerWeaponSwing_next

