;-----------------------------------------------
; copy the player position from the high-res variables to the low-res ones
initializeMemory:
    ;; transfer variables to RAM:
    ld hl,ROMtoRAM_gameStart
    ld de,RAM_gameStart
    ld bc,endROMtoRAM_gameStart-ROMtoRAM_gameStart
    ldir

    ld hl,memoryToClearOnNewGame
    ld de,memoryToClearOnNewGame+1
    xor a
    ld (hl),a
    ld bc,(endOfMemoryToClearOnNewGame - memoryToClearOnNewGame) - 1
    ldir

    ret


;-----------------------------------------------
; updates the game state
Game_Update_Cycle:
    ; game speed control:
    ld hl,game_interrupt_cycle
    ld a,(interrupts_per_game_frame)
    cp (hl)
    ret p
    neg
    add a,(hl)
    and #0f ; make sure the counter does not grow too large
    ld (hl),a

;    out (#2c),a

    call checkInput                     ; ~ 1000 cycles
    
    ld a,(game_state)   ;; check if game state has changed
    cp GAME_STATE_PLAYING
    jr nz,Game_Update_Cycle_change_state

    call updatePlayer                   ; ~ 160 cycles
    call updateKnightSprites            ; ~ 650 cycles  (1 round of optimization done)
Game_Update_Cycle_playerdead:
    call updateArrows
    call updateHourglass
    call checkEvents
    call updateUIMessage                ; ~ 50 cycles 
    call resetSpriteAssignment          ; ~ 732 cycles  (1 round of optimization done)
    call updateAndAssignEnemySprites    ; ~ 5840 cycles
    call assignPickupSprites            ; ~ 2038 cycles (1 round of optimization done)
    call assignArrowSprites
    call drawSprites                    ; ~ 800 cycles  (1 round of optimization done)
    ld hl,game_cycle
    inc (hl)

;    out (#2d),a

    ret

Game_Update_Cycle_change_state:
    pop bc  ; simulate a "ret"
    cp GAME_STATE_ENTER_MAP
    jr z,Game_Update_Cycle_change_state_no_music_stop  ;; do not stop music if we are just changing map
    call StopPlayingMusic
Game_Update_Cycle_change_state_no_music_stop:
    ld a,(game_state)
    jp change_game_state



updateArrows:
    ld hl,arrow_data
    ld a,(hl)
    or a
    call nz,updateArrows_updateArrow
    ld a,(hl)   ;; we make sure the arrow didn't disappear before calling it again
    or a
    call nz,updateArrows_updateArrow    ;; we call each arrow twice, so that they move twice as fast, but we get collision checks every step, so walls are not skipped
    ld a,(hl)
    or a
    call nz,updateArrowsCheckEnemies
    ld hl,arrow_data+ARROW_STRUCT_SIZE
    ld a,(hl)   
    or a
    call nz,updateArrows_updateArrow
    ld a,(hl)   ;; we make sure the arrow didn't disappear before calling it again
    or a
    call nz,updateArrows_updateArrow  ;; we call each arrow twice, so that they move twice as fast, but we get collision checks every step, so walls are not skipped
    ld a,(hl)
    or a
    jp nz,updateArrowsCheckEnemies
    ret

updateArrows_updateArrow
    push hl
    pop ix

    push hl
    ld l,(ix+1)
    ld h,(ix+7)   ;; load precision x in hl
    ld e,(ix+3)
    ld d,(ix+4)   ;; load increment x in de
    add hl,de
    add hl,de   ;; twice the speed of the player
    ld (ix+1),l
    ld (ix+7),h
    ld c,h

    ld l,(ix+2)
    ld h,(ix+8)   ;; load precision y in hl
    ld e,(ix+5)
    ld d,(ix+6)   ;; load increment y in de
    add hl,de
    add hl,de   ;; twice the speed of the player
    ld (ix+2),l
    ld (ix+8),h
    ld b,h

    pop hl
    call getMapPosition
    or a
    jp nz,updateArrows_updateArrow_collision
    ret

updateArrows_updateArrow_collision:
    xor a
    ld (hl),a
    ret


updateArrowsCheckEnemies:
    ; check for arrow to enemy collision:
    ; notice that since this function is always called after updateArrow, "ix" points to the arrow structure
    ld a,(currentMapEnemies)
    ld b,a
    ld hl,currentMapEnemies+1
updateArrowsCheckEnemies_loop:
    ld a,(hl)
    or a
    jp z,updateArrowsCheckEnemies_next
    cp ENEMY_EXPLOSION
    jp z,updateArrowsCheckEnemies_next    
    cp ENEMY_BULLET
    jp z,updateArrowsCheckEnemies_next    

    ld a,(ix+7)
    inc hl
    sub (hl)
    jp p,updateArrowsCheckEnemies_positive_xdiff
    neg
updateArrowsCheckEnemies_positive_xdiff:
    cp 4    ;; compare with the weapon range
    jp p,updateArrowsCheckEnemies_next_x

    ld a,(ix+8)
    inc hl
    sub (hl)
    jp p,updateArrowsCheckEnemies_positive_ydiff
    neg
updateArrowsCheckEnemies_positive_ydiff:
    cp 4    ;; compare with the weapon range
    jp p,updateArrowsCheckEnemies_next_y

    ;; enemy hit!
    push hl
    ld hl,SFX_hit_enemy
    call play_ingame_SFX
    pop hl
    ; make the arrow disappear:
    ld b,(ix)   ; store the type of arrow this was
    xor a
    ld (ix),a

    dec hl
    dec hl
    push hl
    pop iy
    ld a,(hl)   
    cp ENEMY_KNIGHT
    jp z,updateArrowsCheckEnemies_deflect_arrow  ; knights deflect arrows!
    cp ENEMY_MEDUSA_STONE
    jp z,updateArrowsCheckEnemies_deflect_arrow  ; stone medusa deflect arrows!
    cp ENEMY_SWITCH
    jp z,updateArrowsCheckEnemies_activateSwitch
    cp ENEMY_BULLET
    jp z,updateArrowsCheckEnemies_next

    ; effect, depending on the type of arrow:
    ld a,b
    cp ITEM_ICEARROW
    jp z,updateArrowsCheckEnemies_icearrow_hit

    dec (iy+5)  ;; decrease hit points of the enemy in one
    jp nz,updateArrowsCheckEnemies_next
    call killedEnemy
    ld (iy),ENEMY_EXPLOSION
    ld (iy+3),ENEMY_EXPLOSION_SPRITE_PATTERN
    ld (iy+4),ENEMY_EXPLOSION_COLOR
    ld (iy+6),8 ; duration of the explosion

updateArrowsCheckEnemies_next:
    inc hl
updateArrowsCheckEnemies_next_x:
    inc hl
updateArrowsCheckEnemies_next_y:
    ld de,ENEMY_STRUCT_SIZE-2
    add hl,de
    djnz updateArrowsCheckEnemies_loop
    ret
updateArrowsCheckEnemies_icearrow_hit:
    ; mark the enemy as frozen:
    ld (iy+8),48 ; freeze for 48 frames
    ld a,(iy)
    cp #80
    jp p,updateArrowsCheckEnemies_next  ;; if the enemy is ALREADY frozen, then don't do anything else
    or #80
    ld (iy),a
    ld a,(iy+4)
    ld (iy+7),a     ; store the previous color in state2
    ld (iy+4),7     ; make it blue
    jp updateArrowsCheckEnemies_next

updateArrowsCheckEnemies_deflect_arrow:
    ;; play deflect SFX:
    push hl
    ld hl,SFX_hit_deflected
    call play_ingame_SFX
    pop hl
    jp updateArrowsCheckEnemies_next


updateArrowsCheckEnemies_activateSwitch:
    push hl
    ld hl,SFX_door_open
    call play_ingame_SFX
    pop hl

    ld a,(iy+6)
    or a
    jp z,updateArrowsCheckEnemies_activateSwitch_switch_to_1
updateArrowsCheckEnemies_activateSwitch_switch_to_0:
    ld (iy+6),0
    ld (iy+3),ENEMY_SWITCH_RIGHT_SPRITE_PATTERN
    ld a,(iy+7) ; event type
    push bc
    ld c,(iy+8) ; event parameter
    call triggerEvent
    pop bc
    jp updateArrowsCheckEnemies_next
updateArrowsCheckEnemies_activateSwitch_switch_to_1:
    ld (iy+6),1
    ld (iy+3),ENEMY_SWITCH_LEFT_SPRITE_PATTERN
    ld a,(iy+7) ; event type
    push bc
    ld c,(iy+8) ; event parameter
    call triggerEvent
    pop bc
    jp updateArrowsCheckEnemies_next


updateHourglass:
    ld a,(hourglass_timer)
    or a
    ret z
    dec a
    ld (hourglass_timer),a

    or a
    push af
    call z,resumeMusic
    pop af

    and #07
    ret nz
    ld hl,SFX_hourglass
    jp play_ingame_SFX
    ret


;-----------------------------------------------
; Checks whether the main character is over a pickup
checkPickups:
    ld hl,currentMapPickups
    ld a,(hl)
    or a
    ret z   ; if there are no pickups, return
    ld b,a
    inc hl
checkPickups_loop:
    ld a,(hl)
    or a
    jp z,checkPickups_next
    ld a,(player_x)
    inc hl
    sub (hl)
    jp p,checkPickups_positive_xdiff
    neg
checkPickups_positive_xdiff:
    cp 3
    jp p,checkPickups_next_x

    ld a,(player_y)
    inc hl
    sub (hl)
    jp p,checkPickups_positive_ydiff
    neg
checkPickups_positive_ydiff:
    cp 3
    jp p,checkPickups_next_y
    
    ; item pickup!!
    dec hl
    dec hl

    ; pickup the item
    push hl
    push bc
    call pickupItem
    ld hl,SFX_item_pickup
    call play_ingame_SFX
    pop bc

    ; remember which item was picked up, so it does not reappear when re-loading this map:
    ; pickup # is (currentMapPickups) - b
    ld a,(player_map)
    add a,a
    add a,a
    add a,a
    add a,a
    ld c,a
    ld a,(currentMapPickups)
    sub b   ; a = (currentMapPickups) - b
    add a,c
    ld hl,globalState_itemsPickedUp
    ADD_HL_A    ; hl = globalState_itemsPickedUp + (player_map)*16 + (currentMapPickups) - b
    ld (hl),1
    pop hl

    xor a
    ld (hl),a       ; remove the item from the map


checkPickups_next:
    inc hl
checkPickups_next_x:
    inc hl
checkPickups_next_y:
    inc hl
    inc hl
    djnz checkPickups_loop
    ret


;-----------------------------------------------
; effect of picking up the item pointed at by "hl"
pickupItem:
    ld a,(hl)
    dec a
;    cp ITEM_SWORD
    jr z,pickupSword
    dec a
;    cp ITEM_GOLDSWORD
    jr z,pickupGoldsword
    dec a
;    cp ITEM_ARROW
    jr z,pickupArrow
    dec a
;    cp ITEM_ICEARROW
    jr z,pickupIcearrow
    dec a
;    cp ITEM_HOURGLASS
    jr z,pickupHourglass
    dec a
;    cp ITEM_SILVERARMOR
    jr z,pickupSilverArmor
    dec a
;    cp ITEM_GOLDARMOR
    jr z,pickupGoldArmor
    dec a
;    cp ITEM_POTION
    jr z,pickupPotion
    dec a
;    cp ITEM_HEART
    jr z,pickupHeart
    dec a
;    cp ITEM_KEY
    jr z,pickupKey
    ret

pickupGoldArmor:
    ld a,1
    ld (available_armors+2),a
    inc a
    ld (current_armor),a
    jp ChangeArmor_gold

pickupSilverArmor:
    ld a,1
    ld (available_armors+1),a
    ld (current_armor),a
    jp ChangeArmor_silver

pickupHourglass:
    ld a,1
    ld (available_secondary_weapons+3),a
    ld a,3
    ld (current_secondary_weapon),a
    jp ChangeSecondaryWeapon_hourglass

pickupIcearrow:
    ld a,1
    ld (available_secondary_weapons+2),a
    inc a
    ld (current_secondary_weapon),a
    jp ChangeSecondaryWeapon_icearrow

pickupArrow:
    ld a,1
    ld (available_secondary_weapons+1),a
    ld (current_secondary_weapon),a
    jp ChangeSecondaryWeapon_arrow

pickupGoldsword:
    ld a,1
    ld (available_weapons+2),a
    inc a
    ld (current_weapon),a
    jp ChangeWeapon_goldsword

pickupSword:
    ld a,1
    ld (available_weapons+1),a
    ld (current_weapon),a
    jp ChangeWeapon_sword  

pickupPotion:
    ld a,(player_health)
    add a,4
    cp 17
    jp m,pickupPotion_no_overflow
    ld a,16
pickupPotion_no_overflow:
    ld (player_health),a
    jp update_UI_health

pickupHeart:
    ld a,(player_mana)
    inc a
    cp 32
    jp m,pickupHeart_no_overflow
    ld a,31
pickupHeart_no_overflow:
    ld (player_mana),a
    jp update_UI_mana

pickupKey:
    ld a,(player_keys)
    inc a
    ld (player_keys),a
    jp update_UI_keys


;-----------------------------------------------
; checks whether the player has walked into an event
checkEvents:
    ld a,(currentMapEvents)
    or a
    ret z   ; if there are no events, return
    ld b,a
    ld hl,currentMapEvents+1
checkEvents_loop:
    ld d,(hl)
    ld a,(player_x)
    and #f0 ; only the map cell matters
    cp d
    jp nz,checkEvents_next
    inc hl
    ld d,(hl)
    ld a,(player_y)
    and #f0 ; only the map cell matters
    cp d
    jp nz,checkEvents_next_after_x

    ; the player walked into a position labeled with an event!!!
    dec hl
    xor a   
    ld (hl),a   ;; place a 0 in the "x" coordinate of an event, to make sure it does not get triggered
                ;; again, since the coordinate 0 of a map can never be reached (should be wall)

    inc hl
    inc hl
    ld a,(hl)
    inc hl
    push hl
    ld c,0
    call triggerEvent
    pop hl
    djnz checkEvents_loop
    ret

checkEvents_next:
    inc hl
checkEvents_next_after_x:
    inc hl
    inc hl
    djnz checkEvents_loop
    ret


;-----------------------------------------------
; This function is called when an event is triggered
; a : event ID
; c : event parameter
triggerEvent:
    or a
    jp z,triggerEvent_Message1  ; each map can have up to 4 messages
    dec a
    ;cp 1
    jp z,triggerEvent_Message2
    dec a
    ;cp 2
    jp z,triggerEvent_Message3
    dec a
    ;cp 3
    jp z,triggerEvent_Message4
    dec a
;    cp EVENT_OPEN_GATE
    jr z,triggerEvent_OpenGate
    dec a
;    cp EVENT_CHANGE_OTHER_SWITCH
    jr z,triggerEvent_ChangeOtherSwitch
    dec a
;    cp EVENT_OPEN_MEDUSA1_GATE
    jr z,triggerEvent_OpenMedusa1Gate
    dec a
;    cp EVENT_PASSWORD
    jp z,triggerEvent_generatePassword
    ret


triggerEvent_OpenGate:
    push hl
    ld h,currentMap/256
    ld l,c
    ld a,(hl)
    or a
    jp z,triggerEvent_OpenGate_addWall
triggerEvent_OpenGate_removeWall:
    xor a
    ld (hl),a
    pop hl
    ret
triggerEvent_OpenGate_addWall:
    ld (hl),6

    ; check if we are closing a gate on top of the player
    ld hl,player_x
    ld c,(hl)
    inc hl
    ld b,(hl)
    call getMapPosition
    cp 6    ; if this is true, the player is dead...
    jr nz,triggerEvent_OpenGate_addWall_not_ontop_of_player
    xor a
    ld (player_health),a
    ld a,GAME_STATE_GAME_OVER
    ld (game_state),a
    call update_UI_health    

triggerEvent_OpenGate_addWall_not_ontop_of_player:
    pop hl
    ret

triggerEvent_ChangeOtherSwitch:
    push hl
    push iy
    ld hl,currentMapEnemies+1
    ld a,c
    add a,a
    add a,a
    add a,a
    add a,c ; a = c*9
    ADD_HL_A
    push hl
    pop iy
    ld a,(iy+6)
    or a
    jp z,triggerEvent_ChangeOtherSwitch_switch_to_1
triggerEvent_ChangeOtherSwitch_switch_to_0:
    ld (iy+6),0
    ld (iy+3),ENEMY_SWITCH_RIGHT_SPRITE_PATTERN
    jp triggerEvent_ChangeOtherSwitch_done
triggerEvent_ChangeOtherSwitch_switch_to_1:
    ld (iy+6),1
    ld (iy+3),ENEMY_SWITCH_LEFT_SPRITE_PATTERN
triggerEvent_ChangeOtherSwitch_done:
    pop iy
    pop hl
    ret

triggerEvent_OpenMedusa1Gate:
    ;; switches 0 - 4 must be in "SWITCH_STATE_LEFT" (which is "1")
    ld a,(currentMapEnemies+1+6)    ; switch 0
    or a
    ret z
    ld a,(currentMapEnemies+1+6+9)    ; switch 1
    or a
    ret z
    ld a,(currentMapEnemies+1+6+18)    ; switch 2
    or a
    ret z
    ld a,(currentMapEnemies+1+6+27)    ; switch 3
    or a
    ret z
    ld a,(currentMapEnemies+1+6+36)    ; switch 4
    or a
    ret z
    jp triggerEvent_OpenGate

triggerEvent_Message1:
    ld de,currentMapMessages
    jr triggerEvent_Message

triggerEvent_Message2:
    ld de,currentMapMessages+4*22
    jr triggerEvent_Message

triggerEvent_Message3:
    ld de,currentMapMessages+4*22*2
    jr triggerEvent_Message

triggerEvent_Message4:
    ld de,currentMapMessages+4*22*3
;    jp triggerEvent_Message

triggerEvent_Message:
    push de
    ; if we are on an MSX2 and currently showing buffer 2, force switching to buffer 1 (so that I don't need to 
    ; update the rest of the functions that assume we are on an MSX1):
    ld hl,raycast_use_double_buffer
    ld a,(hl)
    or a
    jp z,triggerEvent_Message_msx1
    dec hl  ; hl = raycast_double_buffer
    ld a,(hl)
    or a
    jp z,triggerEvent_Message_msx1
    ; this will render a complete frame, and switch the banks:
    call raycastCompleteRender

triggerEvent_Message_msx1:
    call triggerEvent_drawMessageFrame
    pop de

    ;; display the message, character by character:
    ld hl,CHRTBL2 + 8*8 + 8
    ld c,4  
    xor a
    ld (message_skip),a
triggerEvent_Message_next_line:
    push bc
    ld b,22
triggerEvent_Message_line_loop
    ld a,(de)

    push af
    push de
    push hl
    ; write character in register a to next position
    ; this means, drawing:
    ; - from CHRTBL2+(#800*2)+8*a
    ; - to HL
    ex de,hl    ; now DE has the target position
    push bc
    ld l,a
    ld h,0
    add hl,hl   ; a*2
    add hl,hl   ; a*4
    add hl,hl   ; a*8
    ld bc,CHRTBL2 + (#800*2)
    add hl,bc
    pop bc
;    ld hl,CHRTBL2 + (#800*2) + 48*8  ; just print all '0's
    call copyWhitePatternFromBank3ToBank1
    pop hl
    pop de
    pop af

    cp ' '
    jp z,triggerEvent_Message_line_loop_after_wait

    ld a,(message_skip)
    or a
    jp nz,triggerEvent_Message_line_loop_after_wait

    push bc
    call checkTrigger1updatingPrevious
    pop bc
    or a
    call nz,triggerEvent_Message_set_skip

    halt
    halt
    halt
    halt

triggerEvent_Message_line_loop_after_wait:
    inc de

    ;; make HL to point to the next character:
    push bc
    ld bc,8*8
    add hl,bc
    pop bc

    djnz triggerEvent_Message_line_loop

    ;; next line: make HL point to the first character of the next line
    ld bc,8 - 22*8*8
    add hl,bc

    pop bc
    dec c
    jp nz,triggerEvent_Message_next_line

triggerEvent_Message_wait_for_user:
    halt
    call checkTrigger1updatingPrevious
    or a
    jp z,triggerEvent_Message_wait_for_user
    ;; reset the speed control counter
    ld a,(interrupts_per_game_frame)
    ld (game_interrupt_cycle),a
    jp triggerEvent_clearMessageFrameSides

triggerEvent_Message_set_skip:
    ld a,1
    ld (message_skip),a
    ret


;-----------------------------------------------
; draws the message frame at the top of the screen
triggerEvent_drawMessageFrame:
    ; clear the frame:
    ld hl,CHRTBL2+(#800*2)+8*32
    ld de,CHRTBL2+8+8*8
    ld c,22
triggerEvent_drawMessageFrame_loop1:
    ld b,4
triggerEvent_drawMessageFrame_loop2:
    call copyWhitePatternFromBank3ToBank1

    push hl
    ld hl,8
    add hl,de
    ex de,hl
    pop hl
    djnz triggerEvent_drawMessageFrame_loop2

    push hl
    ld hl,4*8
    add hl,de
    ex de,hl
    pop hl
    dec c
    jr nz,triggerEvent_drawMessageFrame_loop1

    ; draw the four corners:
    ld hl,CHRTBL2+(#800*2)+8*100
    ld de,CHRTBL2
    call copyWhitePatternFromBank3ToBank1
;    ld hl,CHRTBL2+(#800*2)+8*102
    ld l,(CHRTBL2+(#800*2)+8*102)%256
    ld de,CHRTBL2+23*8*8
    call copyWhitePatternFromBank3ToBank1
;    ld hl,CHRTBL2+(#800*2)+8*104
    ld l,(CHRTBL2+(#800*2)+8*104)%256
    ld de,CHRTBL2+5*8
    call copyWhitePatternFromBank3ToBank1
;    ld hl,CHRTBL2+(#800*2)+8*105
    ld l,(CHRTBL2+(#800*2)+8*105)%256
    ld de,CHRTBL2+(23*8+5)*8
    call copyWhitePatternFromBank3ToBank1

    ; draw the top and bottom lines:
    ld hl,CHRTBL2+(#800*2)+8*101
    ld de,CHRTBL2+8*8
    ld b,22
triggerEvent_drawMessageFrame_loop3:
    call copyWhitePatternFromBank3ToBank1
    push bc
    ld bc,5*8
    ex de,hl
    add hl,bc
    ex de,hl
    pop bc
    call copyWhitePatternFromBank3ToBank1
    push bc
    ld bc,3*8
    ex de,hl
    add hl,bc
    ex de,hl
    pop bc
    djnz triggerEvent_drawMessageFrame_loop3

    ; draw the left and right lines:
    ld hl,CHRTBL2+(#800*2)+8*103
    ld de,CHRTBL2+8
    ld b,4
triggerEvent_drawMessageFrame_loop4:
    call copyWhitePatternFromBank3ToBank1
    push bc
    ld bc,23*8*8
    ex de,hl
    add hl,bc
    ex de,hl
    pop bc
    call copyWhitePatternFromBank3ToBank1
    push bc
    ld bc,8 - 23*8*8
    ex de,hl
    add hl,bc
    ex de,hl
    pop bc
    djnz triggerEvent_drawMessageFrame_loop4
    ret


;-----------------------------------------------
; Clears the sides of the message frame that potentially fall outside of the game render area
triggerEvent_clearMessageFrameSides:
    ld a,(amount_of_bytes_to_render)
    add a,a
    ld b,a
    ld a,12
    sub b   ;; a contains the number of columns on each side that must be cleared
    or a
    ret z
    ld d,a
    neg
    add a,32-RAYCAST_SIDE_BORDER*2    ;; a contains column where we need to start clearing on the other side
    call hl_equal_a_times_32
    add hl,hl
    push hl
    pop bc
    ld a,d
    add a,a
    add a,a
    add a,a  ;; a contains the number of characters on each side that must be cleared    
    ld hl,CHRTBL2+(#800*2)+8*32
    ld de,CHRTBL2
triggerEvent_clearMessageFrameSides_loop1:
    push af
    call copyWhitePatternFromBank3ToBank1
    push de
    ex de,hl
    add hl,bc
    ex de,hl
    call copyWhitePatternFromBank3ToBank1
    pop de
    pop af
    push bc
    ld bc,8
    ex de,hl
    add hl,bc
    ex de,hl
    pop bc
    dec a
    jr nz,triggerEvent_clearMessageFrameSides_loop1
    ret


;-----------------------------------------------
; assuming the enemy pointed by iy was killed, 
; this function spawms:
; - with probability 1/16: a health pickup
; - with probability 1/2: a heart
killedEnemy:
    ;; play enemy kill SFX:
    push hl
    ld hl,SFX_enemy_kill
    call play_ingame_SFX

    ; find to see if we have a free pickup slot:
    ld b,0
    ld hl,currentMapPickups
    ld c,(hl)
    inc hl
killedEnemy_spawn_pickup_loop:
    ld a,b
    cp c
    jp z,killedEnemy_spawn_pickup_found_spot_increase
    ld a,(hl)
    or a
    jp z,killedEnemy_spawn_pickup_found_spot
    inc hl
    inc hl
    inc hl
    inc hl  ; move to the next pickup (each pickup is 4 bytes)
    inc b
    ld a,b
    cp MAX_PICKUPS_PER_MAP
    jp nz,killedEnemy_spawn_pickup_loop
    pop hl    
    ret

killedEnemy_spawn_pickup_found_spot_increase:
    inc c
    ld a,c
    ld (currentMapPickups),a
    dec b   ;; if we need to increase by one, we should not increase "b"
killedEnemy_spawn_pickup_found_spot:   
    inc b
    ld a,(iy)
    and #7f ; ignore the "frozen" bit
    cp ENEMY_KER
    jp z,killedEnemy_ker
    cp ENEMY_MEDUSA
    jp z,killedEnemy_medusa
    cp ENEMY_KER2
    jp z,killedEnemy_ker2
    cp ENEMY_KER3
    jp z,killedEnemy_ker3
    ld a,(game_cycle)
    and #0f
    or a
    jr z,killedEnemy_spawn_potion
    and #01
    or a
    jp z,killedEnemy_spawn_heart
    pop hl    
    ret

killedEnemy_spawn_potion:
    ld (hl),ITEM_POTION
    inc hl
    ld a,(iy+1)
    ld (hl),a   ; x
    inc hl
    ld a,(iy+2)
    ld (hl),a   ; y
    inc hl
    ld (hl),SPRITE_PATTERN_POTION
    pop hl
    ret

killedEnemy_spawn_heart:
    ld (hl),ITEM_HEART
    inc hl
    ld a,(iy+1)
    ld (hl),a   ; x
    inc hl
    ld a,(iy+2)
    ld (hl),a   ; y
    inc hl
    ld (hl),SPRITE_PATTERN_HEART
    pop hl
    ret

killedEnemy_ker:
    ld a,1
    ld (globalState_BossesKilled),a
    jr killedEnemy_boss_drop_key

killedEnemy_ker2:
    ld a,1
    ld (globalState_BossesKilled+2),a
    jr killedEnemy_boss_check_for_endgame

killedEnemy_ker3:
    ld a,1
    ld (globalState_BossesKilled+3),a
killedEnemy_boss_check_for_endgame:
    ld hl,globalState_BossesKilled+2
    ld a,(hl)
    inc hl
    and (hl)
    pop hl  ; the function that called this pushed "hl", so, we need to pop it
    ret z

    ; KILLED THE TWO FINAL BOSSES!!! END GAME!!!
    ; FIRST call sprite rendering, so that the enemy kill explosion is rendered
    ld (iy),ENEMY_EXPLOSION
    ld (iy+3),ENEMY_EXPLOSION_SPRITE_PATTERN
    ld (iy+4),ENEMY_EXPLOSION_COLOR
    ld (iy+6),8 ; duration of the explosion
    call resetSpriteAssignment
    call updateAndAssignEnemySprites
    call drawSprites

    ; SECOND wait for a bit to prevent player slamming space from skipping the ending!
    ld b,25
    call waitBhalts

    ; THIRD display the agonizing cry of the Ker:
    call triggerEvent_Message2

    ; FOURTH jump to ending scene
    ld a,GAME_STATE_ENDING
    ld (game_state),a
    ret

killedEnemy_medusa:
    ld a,1
    ld (globalState_BossesKilled+1),a

killedEnemy_boss_drop_key:
    ld (hl),ITEM_KEY
    inc hl
    ld a,(iy+1)
    ld (hl),a   ; x
    inc hl
    ld a,(iy+2)
    ld (hl),a   ; y
    inc hl
    ld (hl),SPRITE_PATTERN_KEY

    ;; change music:
    push iy
        call StopPlayingMusic
        ld a,6
        ld hl,ToPInGameSongPletter
        call PlayCompressedSong
    pop iy

    pop hl  ; the function that called this pushed "hl", so, we need to pop it
    ret


;-----------------------------------------------
; sets a UI message, input parameters:
; - hl: pointer to the text to display
; - c: number of characters in the message
displayUIMessage:
    ; update the variables:
    ld a,16
    ld (current_UI_message_timer),a

    push hl
    push bc
    ld hl,current_UI_message
    ld de,current_UI_message+1
    xor a
    ld (hl),a
    ld bc,31
    ldir
    pop bc
    push bc
    ld a,c
    sra a
    neg
    add a,16
    ld hl,current_UI_message
    ADD_HL_A    ;; hl = current_UI_message + 16 - c/2
    ex de,hl
    pop bc
    pop hl
    ld b,0
    ldir

    ; update the UI:
    ld hl,current_UI_message
    ld bc,32
    ld de,NAMTBL2+256*2
    jp LDIRVM


;-----------------------------------------------
; function called at every game cycle to update the UI message.
; Specifically, this function decrements (current_UI_message_timer), and
; fades out the message when the timer reaches 0
updateUIMessage:
    ld a,(current_UI_message_timer)
    or a
    ret z

    dec a
    ld (current_UI_message_timer),a

    cp 8
    ret p
    
    add a,a
    add a,a
    ld bc,4
    ld hl,NAMTBL2+256*2
    ADD_HL_A
    xor a
    jp FILVRM


;-----------------------------------------------
; The player just walked onto a mirror wall
; check if Popolon is wearing the right armor
walkedIntoAMirrorWall:
    push af
    ld a,(player_map)
    cp MAP_TUNNEL
    jr z,walkedIntoAMirrorWall_silverArmorMap
    cp MAP_FORTRESS1
    jr z,walkedIntoAMirrorWall_silverArmorMap
    cp MAP_FORTRESS2
    jr z,walkedIntoAMirrorWall_goldArmorMap
    cp MAP_MEDUSA1
    jr z,walkedIntoAMirrorWall_goldArmorMap
    pop af
    ret
walkedIntoAMirrorWall_silverArmorMap:
    ld a,(current_armor)
    cp 1    ;; if the player is wearing a silver armor
    jr z,walkedIntoAMirrorWall_rightArmor
    pop af
    ret 
walkedIntoAMirrorWall_goldArmorMap:
    ld a,(current_armor)
    cp 2    ;; if the player is wearing a gold armor
    jr z,walkedIntoAMirrorWall_rightArmor
    pop af
    ret 
walkedIntoAMirrorWall_rightArmor:
    pop af
    xor a   ;; if the player is wearing a silver armor, then walk through the wall (replace "a" by 0)
    ret


;-----------------------------------------------
; The player just walked onto an EXIT tile
; This function loads the new map, and teleports the player there
walkedIntoAnExit:
    ld a,(player_map)
    or a
;    cp MAP_TUNNEL
    ld iy,Exit_tunnel_to_fortress
    jp z,EnterMap_Loop_generic
    dec a
;    cp MAP_FORTRESS1
    jr z,walkedIntoAnExit_Fortress1
    dec a
;    cp MAP_FORTRESS2
    jr z,walkedIntoAnExit_Fortress2
    dec a
;    cp MAP_CATACOMBS1
    jr z,walkedIntoAnExit_Catacombs
    dec a
;    cp MAP_CATACOMBS2
    jp z,EnterMap_Loop_deeper_catacombs_to_catacombs
    dec a
;    cp MAP_MEDUSA1
    jp z,walkedIntoAnExit_Medusa1
    dec a
;    cp MAP_MEDUSA2
    jp z,walkedIntoAnExit_Medusa2
    dec a
;    cp MAP_KERES1
    jp z,walkedIntoAnExit_Keres1
;    cp MAP_KERES2
    jp EnterMap_Loop_keres2_to_keres1


walkedIntoAnExit_done:
    ld a,GAME_STATE_ENTER_MAP
    ld (game_state),a
    pop af  ; the function that calls this (MoveForward) has done a "push af", so, we need
            ; to undo it, to preserve the stack 
    ret


walkedIntoAnExit_Fortress1:
    ld a,(player_x)
    and #80
    ld iy,Exit_fortress_to_tunnel
    or a
    jp z,EnterMap_Loop_generic
    ld a,(player_x)
    and #f0
    cp #80
    jp z,EnterMap_Loop_fortress1_to_fortress2
    jp EnterMap_Loop_fortress_to_catacombs   


walkedIntoAnExit_Fortress2:
    ld a,(player_x)
    and #f0
    cp #70
    jp z,EnterMap_Loop_fortress2_to_fortress1
    ld a,(player_y)
    and #f0
    cp #40
    jp z,EnterMap_Loop_fortress2_to_medusa1
    jp EnterMap_Loop_fortress2_to_keres1


walkedIntoAnExit_Catacombs:
    ld a,(player_x)
    and #80 ; check if the exit was on the left or right half of the map
    or a
    jp nz,EnterMap_Loop_catacombs_to_deeper_catacombs
    jp EnterMap_Loop_catacombs_to_fortress

walkedIntoAnExit_Medusa1:
    ld a,(player_x)
    and #80 ; check if the exit was on the left or right half of the map
    or a
    jp nz,EnterMap_Loop_medusa1_to_medusa2
    jp EnterMap_Loop_medusa1_to_fortress2

walkedIntoAnExit_Medusa2:
    ld a,(player_x)
    and #80 ; check if the exit was on the left or right half of the map
    or a
    jp nz,EnterMap_Loop_medusa2_to_keres1
    jp EnterMap_Loop_medusa2_to_medusa1


walkedIntoAnExit_Keres1:
    ld a,(player_y)
    and #f0
    cp #d0
    jp z,EnterMap_Loop_keres1_to_medusa2
    ld a,(player_x)
    and #f0
    cp #20
    jp z,EnterMap_Loop_keres1_to_fortress2
    jp EnterMap_Loop_keres1_to_keres2



EnterMap_Loop_generic:
    ld a,(iy)
    ld (player_map),a
    ld l,(iy+1)
    ld h,(iy+2)
    push iy
        call loadMap
    pop iy
    ld a,(iy+3)
    ld (player_x),a
    ld a,(iy+4)
    ld (player_y),a
    ld a,(iy+5)
    ld (player_angle),a
    jp walkedIntoAnExit_done

EnterMap_Loop_fortress1_to_fortress2:
    ; set the colors:
    ld e,#a0
    call changeMirrorWallTextureColor
    ld iy,Exit_fortress1_to_fortress2
    jp EnterMap_Loop_generic

EnterMap_Loop_fortress2_to_fortress1:
    ; set the colors:
    ld e,#f0
    call changeMirrorWallTextureColor
    ld iy,Exit_fortress2_to_fortress1
    jp EnterMap_Loop_generic

EnterMap_Loop_fortress_to_catacombs:
    ld iy,Exit_fortress_to_catacombs
    jp EnterMap_Loop_generic

EnterMap_Loop_catacombs_to_fortress:
    ld iy,Exit_catacombs_to_fortress
    jp EnterMap_Loop_generic

EnterMap_Loop_catacombs_to_deeper_catacombs:
    ld a,(globalState_BossesKilled)
    or a
    jp nz,EnterMap_Loop_catacombs_to_deeper_catacombs_nomusic ; if the Ker is killed, do not change music
    push hl
    call StopPlayingMusic
    ld a,6
    ld hl,ToPBossSongPletter
    call PlayCompressedSong
    pop hl
EnterMap_Loop_catacombs_to_deeper_catacombs_nomusic:
    ld iy,Exit_catacombs_to_deeper_catacombs
    jp EnterMap_Loop_generic

EnterMap_Loop_deeper_catacombs_to_catacombs:
    ld a,(globalState_BossesKilled)
    or a
    jp nz,EnterMap_Loop_deeper_catacombs_to_catacombs_nomusic ; if the Ker is killed, do not change music
    push hl
    call StopPlayingMusic
    ld a,6
    ld hl,ToPInGameSongPletter
    call PlayCompressedSong
    pop hl
EnterMap_Loop_deeper_catacombs_to_catacombs_nomusic:
    ld iy,Exit_deeper_catacombs_to_catacombs
    jp EnterMap_Loop_generic

EnterMap_Loop_fortress2_to_medusa1:
    ; set the colors:
    ; ld a,#c0
    ; ld (texture_colors),a   ; green walls
    ; ld a,#e0
    ; ld (texture_colors+6),a ; grey statues
    ld iy,Exit_fortress2_to_medusa1
    jp EnterMap_Loop_generic

EnterMap_Loop_fortress2_to_keres1:
    ; set the colors:
    ; ld a,#d0
    ; ld (texture_colors),a   ; purple walls
    ; ld a,#90
    ; ld (texture_colors+6),a ; red statues    
    ld iy,Exit_fortress2_to_keres1
    jp EnterMap_Loop_generic

EnterMap_Loop_medusa1_to_fortress2:
    ; set the colors:
    ; ld a,#80
    ; ld (texture_colors),a   ; red walls
    ; ld a,#70
    ; ld (texture_colors+6),a ; blue statues
    ld iy,Exit_medusa1_to_fortress2
    jp EnterMap_Loop_generic

EnterMap_Loop_medusa1_to_medusa2:
    ld a,(globalState_BossesKilled+1)
    or a
    jp nz,EnterMap_Loop_medusa1_to_medusa2_nomusic ; if medusa is killed, do not change music
    push hl
    call StopPlayingMusic
    ld a,6
    ld hl,ToPBossSongPletter
    call PlayCompressedSong
    pop hl
EnterMap_Loop_medusa1_to_medusa2_nomusic:
    ld iy,Exit_medusa1_to_medusa2
    jp EnterMap_Loop_generic

EnterMap_Loop_medusa2_to_medusa1:
    ld a,(globalState_BossesKilled+1)
    or a
    jp nz,EnterMap_Loop_medusa2_to_medusa1_nomusic ; if medusa is killed, do not change music
    push hl
    call StopPlayingMusic
    ld a,6
    ld hl,ToPInGameSongPletter
    call PlayCompressedSong
    pop hl
EnterMap_Loop_medusa2_to_medusa1_nomusic:
    ld iy,Exit_medusa2_to_medusa1
    jp EnterMap_Loop_generic

EnterMap_Loop_medusa2_to_keres1:
    ; set the colors:
    ; ld a,#d0
    ; ld (texture_colors),a   ; purple walls
    ; ld a,#90
    ; ld (texture_colors+6),a ; red statues    
    ld iy,Exit_medusa2_to_keres1
    jp EnterMap_Loop_generic

EnterMap_Loop_keres1_to_medusa2:
    ; set the colors:
    ; ld a,#c0
     ;ld (texture_colors),a   ; green walls
     ;ld a,#e0
     ;ld (texture_colors+6),a ; gray statues
    ld iy,Exit_keres1_to_medusa2
    jp EnterMap_Loop_generic

EnterMap_Loop_keres1_to_fortress2:
    ; set the colors:
    ; ld a,#80
    ; ld (texture_colors),a   ; red walls
    ; ld a,#70
    ; ld (texture_colors+6),a ; blue statues
    ld iy,Exit_keres1_to_fortress2
    jp EnterMap_Loop_generic

EnterMap_Loop_keres1_to_keres2:
    push hl
    ; no point on checking this, since it's an impossible condition
;    ld hl,globalState_BossesKilled+2
;    ld a,(hl)
;    inc hl
;    and (hl)
;    jp nz,EnterMap_Loop_keres1_to_keres2_nomusic ; both keres are killed, do not change music
    call StopPlayingMusic
    ld a,6
    ld hl,ToPBossSongPletter
    call PlayCompressedSong
    pop hl
;EnterMap_Loop_keres1_to_keres2_nomusic:
    ld iy,Exit_keres1_to_keres2
    jp EnterMap_Loop_generic

EnterMap_Loop_keres2_to_keres1:
    push hl
    ; no point on checking this, since it's an impossible condition
;    ld hl,globalState_BossesKilled+2
;    ld a,(hl)
;    inc hl
;    and (hl)
;    jp nz,walkedIntoAnExit_done ; both keres are killed, do not change music
    call StopPlayingMusic
    ld a,6
    ld hl,ToPInGameSongPletter
    call PlayCompressedSong
    pop hl
    ld iy,Exit_keres2_to_keres1
    jp EnterMap_Loop_generic


changeMirrorWallTextureColor:
    ld hl,textures+5*16*32
    ld bc,#0002 ; to loop 512 times
changeMirrorWallTextureColor_loop:
    ld a,(hl)
    or a
    jr z,changeMirrorWallTextureColor_skip_pixel
    ld (hl),e
changeMirrorWallTextureColor_skip_pixel:
    djnz changeMirrorWallTextureColor_loop
    dec c
    jr nz,changeMirrorWallTextureColor_loop
    ret


Exit_tunnel_to_fortress:
    db MAP_FORTRESS1
    dw map_fortress1_pletter
    db 1*16+8, 14*16+8, 0

Exit_fortress_to_tunnel:
    db MAP_TUNNEL
    dw map_tunnel1_pletter
    db 14*16+8, 14*16+8, -64

Exit_fortress1_to_fortress2:
    db MAP_FORTRESS2
    dw map_fortress2_pletter
    db 7*16+8, 3*16+8, 64

Exit_fortress2_to_fortress1:
    db MAP_FORTRESS1
    dw map_fortress1_pletter
    db 8*16+8, 8*16+8, -64

Exit_fortress_to_catacombs:
    db MAP_CATACOMBS1
    dw map_catacombs1_pletter
    db 1*16+8, 1*16+8, 0

Exit_catacombs_to_fortress:
    db MAP_FORTRESS1
    dw map_fortress1_pletter
    db 14*16+8, 11*16+8, 64

Exit_catacombs_to_deeper_catacombs:
    db MAP_CATACOMBS2
    dw map_catacombs2_pletter
    db 1*16+8, 7*16+8, 0

Exit_deeper_catacombs_to_catacombs:
    db MAP_CATACOMBS1
    dw map_catacombs1_pletter
    db 14*16+8, 9*16+8, 128

Exit_fortress2_to_medusa1:
    db MAP_MEDUSA1
    dw map_medusa1_pletter
    db 1*16+8, 14*16+8, -64

Exit_fortress2_to_keres1:
    db MAP_KERES1
    dw map_keres1_pletter
    db 2*16+8, 14*16+8, -64

Exit_medusa1_to_fortress2:
    db MAP_FORTRESS2
    dw map_fortress2_pletter
    db 12*16+8, 4*16+8, 128

Exit_medusa1_to_medusa2:
    db MAP_MEDUSA2
    dw map_medusa2_pletter
    db 1*16+8, 7*16+8, 0

Exit_medusa2_to_medusa1:
    db MAP_MEDUSA1
    dw map_medusa1_pletter
    db 14*16+8, 13*16+8, 128

Exit_medusa2_to_keres1:
    db MAP_KERES1
    dw map_keres1_pletter
    db 1*16+8, 13*16+8, 0

Exit_keres1_to_medusa2:
    db MAP_MEDUSA2
    dw map_medusa2_pletter
    db 11*16+8, 7*16+8, 128

Exit_keres1_to_fortress2:
    db MAP_FORTRESS2
    dw map_fortress2_pletter
    db 11*16+8, 7*16+8, 64

Exit_keres1_to_keres2:
    db MAP_KERES2
    dw map_keres2_pletter
    db 1*16+8, 7*16+8, 0

Exit_keres2_to_keres1:
    db MAP_KERES1
    dw map_keres1_pletter
    db 14*16+8, 1*16+8, 128
