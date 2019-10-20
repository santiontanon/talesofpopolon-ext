;-----------------------------------------------
; checks for the status of trigger 1
checkTrigger1:
    ld a,#08    ;; get the status of the 8th keyboard row (to get SPACE and arrow keys)
    call SNSMAT
    cpl 
    and #01
    ret nz
    call readJoystick1Status
    and #10
    ret


;-----------------------------------------------
; checks for the status of trigger 2
checkTrigger2:
    ld a,#04    ;; get the status of the 4th keyboard row (to get M key)
    call SNSMAT
    cpl 
    and #04
    ret nz
    call readJoystick1Status
    and #20
    ret


;-----------------------------------------------
readJoystick1Status:
    ld a,15 ; read the joystick 1 status:
    call RDPSG
    and #bf
    ld e,a
    ld a,15
    call WRTPSG
    dec a
    call RDPSG
    cpl ; invert the bits (so that '1' means direction pressed)
    ret


;-----------------------------------------------
; checks for the status of trigger 1, sets 'a' to 1 if trigger 1 was just pressed,
; and updates (previous_trigger1) with the latest state of trigger 1
; - modifies bc 
checkTrigger1updatingPrevious:
    push hl
    push de
    call checkTrigger1
    ld hl,previous_trigger1
    ld b,(hl)
    ld (hl),a
    pop de
    pop hl
    or a
    ret z
    xor b
    ret


chheckInput_get_P:
    ld a,#04    ;; get the status of the 4th keyboard row (to get the P key)
    call SNSMAT 
    bit 5,a ;; "P"
    ret

checkInput_pause:
    ; pause music:
    xor a
    ld (MUSIC_play),a
    call clear_PSG_volume
    ld hl,SFX_item_pickup
    call play_ingame_SFX
    ; display pause message:
    ld hl,UI_message_pause
    ld c,UI_message_pause_end-UI_message_pause
    call displayUIMessage

checkInput_pause_loop:
    call chheckInput_get_P
    jr nz,checkInput_pause_p_released
    halt
    jr checkInput_pause_loop
checkInput_pause_p_released:
    call chheckInput_get_P
    jr z,checkInput_pause_p_pressed_again
    halt
    jr checkInput_pause_p_released
checkInput_pause_p_pressed_again:
    call chheckInput_get_P
    jr nz,checkInput_pause_resume_game
    halt
    jr checkInput_pause_p_pressed_again
checkInput_pause_resume_game:
    ; resume music:
    ld a,1
    ld (MUSIC_play),a
    ret


;-----------------------------------------------
; checks all the player input (left/right/thrust/fire)
checkInput:
    ld a,(previous_keymatrix0)
    ld b,a
    xor a       ;; get the status of the 0th keyboard row (to get status of "1", "2" and "3")
    call SNSMAT
    ld (previous_keymatrix0),a
    xor b   ;; we have a 1 on those that have changed
    and b   ;; we have a 1 on those that have changed, and that were not pressed before
    bit 0,a ;; "0"
    call nz,checkInput_request_screen_size_change
    bit 1,a ;; "1"
    call nz,ChangeWeapon
    bit 2,a ;; "2"
    call nz,ChangeSecondaryWeapon
    bit 3,a ;; "3"
    call nz,ChangeArmor

    ld a,#04    ;; get the status of the 4th keyboard row (to get the M, R and P key)
    call SNSMAT 
    cpl
    bit 7,a ;; "R"
    call nz,checkInput_request_CPUmode_change
    bit 5,a ;; "P"
    call nz,checkInput_pause
    and #04     ;; we keep the status of M
    ld b,a
    ld a,#08    ;; get the status of the 8th keyboard row (to get SPACE and arrow keys)
    call SNSMAT 
    cpl
    and #f1     ;; keep only the arrow keys and space
    or b        ;; we bring the state of M from before
    jr z,Readjoystick   ;; if no key was pressed, then check the joystick
    bit 0,a
    call nz,Trigger1Pressed    ;; when trigger 1 is hold, movement changes, so, we have a different function
    bit 2,a
    call nz,Trigger2Pressed
    bit 7,a
    call nz,TurnRight
    bit 4,a
    call nz,TurnLeft
    bit 5,a
    call nz,MoveForward
    bit 6,a
    call nz,MoveBackwards

    ld hl,previous_trigger1
    bit 0,a
    jr nz,checkInput_trigger1WasPressed
    ld (hl),0
    jr checkInput_checkTrigger2
checkInput_trigger1WasPressed:
    ld (hl),1
checkInput_checkTrigger2:
    ld hl,previous_trigger2
    bit 2,a
    jr nz,checkInput_trigger2WasPressed
    ld (hl),0
    ret
checkInput_trigger2WasPressed:
    ld (hl),1
    ret

Readjoystick:   
    ;; Using BIOS calls:
    call readJoystick1Status
    bit 4,a
    call nz,Trigger1Pressed    ;; when trigger 1 is hold, movement changes, so, we have a different function
    bit 5,a
    call nz,Trigger2Pressed
    bit 3,a
    call nz,TurnRight
    bit 2,a
    call nz,TurnLeft
    bit 0,a
    call nz,MoveForward
    bit 1,a
    call nz,MoveBackwards

    ld hl,previous_trigger1
    bit 4,a
    jr nz,Readjoystick_trigger1WasPressed
    ld (hl),0
    jr Readjoystick_checkTrigger2
Readjoystick_trigger1WasPressed:
    ld (hl),1
Readjoystick_checkTrigger2:
    ld hl,previous_trigger2
    bit 5,a
    jr nz,Readjoystick_trigger2WasPressed
    ld (hl),0
    ret
Readjoystick_trigger2WasPressed:
    ld (hl),1
    ret


checkInput_request_screen_size_change:
    ld hl,raycast_screen_size_change_requested
    ld (hl),1
    ret

checkInput_request_CPUmode_change:
    push af
    ld hl,CPUmode_change_requested
    ld (hl),1
checkInput_request_CPUmode_change_wait_for_R_released:
    call chheckInput_get_P    
    bit 7,a 
    jr z,checkInput_request_CPUmode_change_wait_for_R_released   
    pop af
    ret


Trigger1Pressed:
    push af
    ld a,(previous_trigger1)
    or a
    jr nz,Trigger1Pressed_continue
    ld a,(player_state)
    cp PLAYER_STATE_WALKING
    jr nz,Trigger1Pressed_continue
    ld a,PLAYER_STATE_ATTACK
    ld (player_state),a
    xor a
    ld (player_state_cycle),a
    call playerWeaponSwing

Trigger1Pressed_continue:
    pop af
    ret

Trigger2Pressed:
    push af
    ld a,(previous_trigger2)
    or a
    jr nz,Trigger2Pressed_continue

    ;; fire arrow:
    ld a,(current_secondary_weapon)
    or a
    jr z,Trigger2Pressed_continue   ;; if no secondary weapon selected
    dec a
    call z,fireArrow   ;; if arrows are selected
    dec a
    call z,fireIceArrow   ;; if ice arrows are selected
    dec a
    call z,triggerHourglass   ;; if hourglass is selected
Trigger2Pressed_continue:
    pop af
    ret


