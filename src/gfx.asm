;-----------------------------------------------
; If we are on an MSX2, call "selectVDPBuffer1InMSX2", otherwise, just return
selectVDPBuffer1InMSX2_ifWeAreOnMSX2:
    ld a,(raycast_use_double_buffer)
    or a
    ret z


;-----------------------------------------------
; These two functions set the VDP to render to the color/pattern tables in the first 16KB of VRAM, 
; and in the second 16KB of VRAM, respectively
; - buffer 1 (default):    CHRTBL2: #0000, CLRTBL2: #2000  (R4 = 00000011, R3 = 11111111, R10 = 00000000)
; since R3 does not change, we don't need to actually touch it
selectVDPBuffer1InMSX2:
    ld c,#99
    ld a,#03
    di
    out (c),a
    ld a,4 + 128    ; Select register 4
    out (c),a

    xor a
    out (c),a
    ld a,10 + 128    ; Select register 10
    out (c),a
    ei
    ret

; - buffer 2:              CHRTBL2: #4000, CLRTBL2: #6000  (R4 = 00001011, R3 = 11111111, R10 = 00000001)
; since R3 does not change, we don't need to actually touch it
selectVDPBuffer2InMSX2:
    ld c,#99
    ld a,#0b
    di
    out (c),a
    ld a,4 + 128    ; Select register 4
    out (c),a

    ld a,1
    out (c),a
    ld a,10 + 128    ; Select register 10
    out (c),a
    ei
    ret


;-----------------------------------------------
; hl: source data
; de: target address in the VDP
; bc: amount to copy
LDIRVM_MSX2:
    ex de,hl
    push de
    push bc
    call NSTWRT
    pop bc
    pop hl
    ; jp copy_to_VDP
    
;-----------------------------------------------
; This is like LDIRVM, but faster, and assumes, we have already called "SETWRT" with the right address
; input: 
; - hl: address to copy from
; - bc: amount fo copy
copy_to_VDP:
    ; get the VDP write register:
    ld e,b
    ld a,c
    or a
    jr z,copy_to_VDP_lsb_0
    inc e
copy_to_VDP_lsb_0:
    ld b,c
    ld a,(VDP.DW)
    ld c,a
    ld a,e
copy_to_VDP_loop2:
copy_to_VDP_loop:
    outi
    jp nz,copy_to_VDP_loop
    dec a
    jp nz,copy_to_VDP_loop2
    ret


;-----------------------------------------------
disable_VDP_output:
    ld a,(VDP_REGISTER_1)
    and #bf ; reset the BL bit
    di
    out (#99),a
    ld  a,1+128 ; write to register 1
    ei
    out (#99),a
    ret


;-----------------------------------------------
enable_VDP_output:
    ld a,(VDP_REGISTER_1)
    or #40  ; set the BL bit
    di
    out (#99),a
    ld  a,1+128 ; write to register 1
    ei
    out (#99),a
    ret


;-----------------------------------------------
;; clear sprites:
clearAllTheSprites:
    xor a
    ld bc,32*4
    ld hl,SPRATR2
    jp FILVRM

;-----------------------------------------------
; Fills the whole screen with the pattern in register 'a'
FILLSCREEN:
    ld bc,768
    ld hl,NAMTBL2
    jp FILVRM

;-----------------------------------------------
; initializes the sprite data
setupSprites:
    ld hl,knight_sprite_attributes
    ;; knight
    ld (hl),127-32
    inc hl
    ld (hl),128-24
    inc hl
    ld (hl),KNIGHT_SPRITE*4
    inc hl
    ld a,KNIGHT_COLOR
    ld (hl),a
    inc hl
    ld (current_armor_color),a  
    ld (hl),127-34
    inc hl
    ld (hl),128-24
    inc hl
    ld (hl),KNIGHT_OUTLINE_SPRITE*4
    inc hl
    ld (hl),KNIGHT_OUTLINE_COLOR
    inc hl
    ;; sword
    ld (hl),200   ; somewhere away from the main screen
    inc hl
    ld (hl),128-24
    inc hl
    ld (hl),SWORD_SPRITE*4
    inc hl
    ld (hl),0 ;; initially, we set it to transparent

    ld hl,sword_sprite
    ld de,SPRTBL2+SWORD_SPRITE*32
    ld bc,32
    call LDIRVM    

    ; unpack the sprites
    ld hl,base_sprites_pletter
    ld de,raycast_buffer
    call pletter_unpack

    ; set up the arrows + pickup sprites:
    ld hl,raycast_buffer
    ld de,SPRTBL2+SPRITE_PATTERN_ARROW*32
    ld bc,32*20
    jp LDIRVM    


;-----------------------------------------------
; resets the sprite assignment table at the beginning of each frame:
resetSpriteAssignment:
    ld hl,sprites_available_per_depth
    ld a,N_SPRITES_PER_DEPTH
    REPT N_SPRITE_DEPTHS
    ld (hl),a
    inc hl
    ENDM

    ; clear the sprite attributes:
    ld hl,other_sprite_attributes+4*(N_SPRITE_DEPTHS*N_SPRITES_PER_DEPTH)
    ld bc,4*(N_SPRITE_DEPTHS*N_SPRITES_PER_DEPTH)
    xor a
    jp fast_memory_clear

    ;ld hl,other_sprite_attributes
    ;ld de,other_sprite_attributes+1
    ;xor a
    ;ld (hl),a
    ;ld bc,4*(N_SPRITE_DEPTHS*N_SPRITES_PER_DEPTH)-1
    ;ldir
    ;ret


;-----------------------------------------------
; Assigns all the sprites corresponding to the pickups in a map to the sprite table
assignPickupSprites:
    ld ix,currentMapPickups
    ld a,(ix)   ; n pickups
    inc ix
assignPickupSprites_loop:
    or a
    ret z
    push af
    ld a,(ix)
    or a
    jp z,assignPickupSprites_skip
    call assignSprite_prefilter
assignPickupSprites_skip:
    ld bc,4
    add ix,bc
    pop af
    dec a
    jp assignPickupSprites_loop


;-----------------------------------------------
; Assigns all the sprites corresponding to the arrows the player can fire to the sprite table
assignArrowSprites:
    ld hl,arrow_data
    ld a,(hl)
    or a
    call nz,assignArrowSprites_assignArrow
    ld hl,arrow_data+ARROW_STRUCT_SIZE
    ld a,(hl)
    or a
    jp nz,assignArrowSprites_assignArrow
    ret

assignArrowSprites_assignArrow:
    push hl
    pop ix
    ld bc,6     ; if we add 6 to "ix", then (ix+1),(ix+2) is x,y and (ix+3) is the sprite, as expected by assignSprite
    add ix,bc
    jp assignSprite_prefilter
    

;-----------------------------------------------
; this function corresponds to the shared code between the "assignSprite" function 
; in this file, and the "assignEnemySprite" function in the enemies file
assignEnemySprite:
assignSprite_prefilter:
    ; 1) Calculate it's depth and y coordinate: 
    ld a,(last_raycast_camera_x)
    sub (ix+1)
    ld d,a  ;; save the signed version for later use
    or a
    jp p,assignSprite_positive_x_diff
    neg
assignSprite_positive_x_diff:
    cp 64
    ret p   ;; if the difference in x is larger than 64, sprite is too far
    ld c,a

    ld a,(last_raycast_camera_y)
    sub (ix+2)
    ld e,a  ;; save the signed version for later use
    or a
    jp p,assignSprite_positive_y_diff
    neg
assignSprite_positive_y_diff:
    cp 64
    ret p   ;; if the difference in y is larger than 64, sprite is too far

    ;; b,c now contain the difference in x and y coordinates among the player and the sprite:
    ld h,square_div_32_table/256
    ld l,a
    ld a,(hl)
    ld l,c
    add a,(hl)
    dec h ; move to distance_to_y_from_sum_table
    ld l,a
    ld a,(hl)    
    ld (assignSprite_y),a   ; y coordinate in the screen where to render the sprite
    ; y >= 72: bank 0
    ; y >= 64: bank 1
    ; y >= 56: bank 2
    ; bank 3 otherwise
    cp 72
    jp p,assignSprite_bank0
    cp 64
    jp p,assignSprite_bank1
    cp 56
    jp p,assignSprite_bank2
assignSprite_bank3:
    ld a,3
    jp assignSprite_done_with_bank_assignment
assignSprite_bank0:
    xor a
    jp assignSprite_done_with_bank_assignment
assignSprite_bank1:
    ld a,1
    jp assignSprite_done_with_bank_assignment
assignSprite_bank2:
    ld a,2
assignSprite_done_with_bank_assignment:
    ld (assignSprite_bank),a

    ; - see if we have space in the bank:
    ld hl,sprites_available_per_depth
    ADD_HL_A_VIA_BC
    ld a,(hl)
    or a
    ret z   ;; if we don't have space, just return

    ; 2) Calculate it's x position in the screen: 
    ld b,d  ; x
    ld c,e  ; y
    call atan2  ;; a now has the angle
    add a,128   ;; due to the way I calculated the differences, the angle is reversed
    ld b,a
    ld a,(last_raycast_player_angle)
    sub b           ;; a now has the angle with respect to the player angle
    ld b,a

    ;; make sure it's inside of the screen:
    ;; for the 192-pixel wide mode, this is between -24 to 24
    ;; for the 160-pixel wide mode, this is between -20 to 20
    ;; for the 128-pixel wide mode, this is between -16 to 16
    or a
    jp p,assignSprite_positive_angle_diff
    neg
assignSprite_positive_angle_diff:
    ld hl,raycast_sprite_angle_cutoff
    cp (hl)
    ret p

    ld a,b
    neg
    sla a
    sla a
    add a,128-16    ;; 0 degrees of difference correspond to position (128 - 16) in the screen
    ld (assignSprite_x),a

    ; 3) make sure it's not occluded by any wall:    
    call lineOfSightCheck
    ret nz
    ld a,(assigningSpritesForAnEnemy)
    or a
    jp z,assignSprite_continue
    jp assignEnemySprite_continue


;-----------------------------------------------
; - places a sprite in the sprite assignment table for rendering in the next frame
; - parameters:
;   IX: pointer to the item parameters (type, x, y)
;assignSprite:
;    jp assignSprite_prefilter
assignSprite_continue:
    ; 4) get the type of the pickup/enemy, and assign a sprite:
    ld a,(ix+3)
    ;; ice arrows have a fake sprite number, so that we can paint them of different color
    or a
    jp nz,assignSprite_not_an_icearrow
    ld a,SPRITE_PATTERN_ARROW
assignSprite_not_an_icearrow:
    ld hl,assignSprite_bank
    ld b,(hl)
    add a,b
    add a,a
    add a,a
    ld (assignSprite_sprite),a

    ld a,(ix+3)
    srl a
    srl a
    ld hl,item_sprite_colors
    ADD_HL_A
    ld a,(hl)
    ld (assignSprite_color),a

    ; 5) assign the sprite to the table:
    ld a,b  ; b still contains (assignSprite_bank)
    ld hl,sprites_available_per_depth
    ADD_HL_A
    dec (hl)
    ld a,(hl)
    sla b
    sla b   ;; note: this assumes that N_SPRITES_PER_DEPTH = 4
    add a,b
    ld de,other_sprite_attributes
    add a,a   
    add a,a   
    ADD_DE_A
    ld hl,assignSprite_y
    ldi
    ldi
    ldi
    ldi
    ret


;-----------------------------------------------
; sets the proper sprites for the knight and outline
updateKnightSprites:
    ld b,0
    ld a,(knight_animation_frame) ;; (knight_animation_frame) is the offset of the sprite
    ld hl,knight_animation_frame_in_vdp
    cp (hl)
    ret z
    ld (hl),a
    push af
    ld hl,SPRTBL2+KNIGHT_SPRITE*32
    call SETWRT
    pop af
    ld c,a
    ld hl,knight_sprites
    add hl,bc
    ld b,32
    ld a,(VDP.DW)
    ld c,a
    push bc
updateKnightSprites_loop1: 
    outi
    jp nz,updateKnightSprites_loop1

    ;; outline sprite follows knight sprite:	
    ld bc,knight_sprites_outline-knight_sprites-32	
    add hl,bc
    pop bc
updateKnightSprites_loop2:
    outi
    jp nz,updateKnightSprites_loop2
    ret


;-----------------------------------------------
; Updates all the sprite attribute tables to draw all the sprites
drawSprites:
    ld hl,SPRATR2+KNIGHT_SPRITE*4
    call SETWRT
    
    ;; draw knight + knight_outline + sword + all the sprites in the assignment table
;    ld bc,4*(3+N_SPRITE_DEPTHS*N_SPRITES_PER_DEPTH)*256 + VDP_DATA
    ld b,4*(3+N_SPRITE_DEPTHS*N_SPRITES_PER_DEPTH)

    ld a,(sprites_available_per_depth+3)
    cp N_SPRITES_PER_DEPTH
    jp nz,drawSprites_amount_set
    ld b,4*(3+3*N_SPRITES_PER_DEPTH)

    ld a,(sprites_available_per_depth+2)
    cp N_SPRITES_PER_DEPTH
    jp nz,drawSprites_amount_set
    ld b,4*(3+2*N_SPRITES_PER_DEPTH)

    ld a,(sprites_available_per_depth+1)
    cp N_SPRITES_PER_DEPTH
    jp nz,drawSprites_amount_set
    ld b,4*(3+1*N_SPRITES_PER_DEPTH)

    ld a,(sprites_available_per_depth)
    cp N_SPRITES_PER_DEPTH
    jp nz,drawSprites_amount_set
    ld b,4*3
drawSprites_amount_set:
    ld hl,n_sprites_uploaded_last_cycle
    ld a,(hl)
    ld (hl),b
    cp b
    jp m,drawSprites_amount_set2
    ld b,a
drawSprites_amount_set2:
    ld a,(VDP.DW)
    ld c,a
    ld hl,knight_sprite_attributes
drawSprites_loop:
    outi
    jp nz,drawSprites_loop
    ret


;-----------------------------------------------
; Decodes the graphic patterns, and copies them to video memory
setupPatterns:
    xor a
    ld hl,NAMTBL2
    ld bc,256*3
    call FILVRM
;    jp decodePatternsToAllBanks


;-----------------------------------------------
; Decodes the graphics to all 3 banks:
; This function overwrites a few raycasting buffers, including textures, etc.
decodePatternsToAllBanks:
    ld hl,patterns_pletter
    ld de,raycast_buffer
    call pletter_unpack

    ld hl,raycast_buffer
    ld de,CHRTBL2
    ld bc,256*8
    push bc
    push hl
    call LDIRVM

    pop hl
    pop bc
    ld de,CHRTBL2+256*8
    push bc
    push hl
    call LDIRVM
    pop hl
    pop bc

    ld de,CHRTBL2+256*8*2
    push bc
    call LDIRVM

    pop bc
    ld hl,raycast_buffer+2048
    ld de,CLRTBL2
    push bc
    push hl
    call LDIRVM

    pop hl
    pop bc
    ld de,CLRTBL2+256*8
    push bc
    push hl
    call LDIRVM

    pop hl
    pop bc
    ld de,CLRTBL2+256*8*2
    call LDIRVM

    ; Copy the patterns also to the 3rd bank of the secondary buffer in machines with more than 16KB of VRAM:
    ld a,(raycast_use_double_buffer)
    or a
    ret z

    ld hl,raycast_buffer
    ld de,CHRTBL2_SECONDARY+256*8*2
    ld bc,256*8
    push bc
    call LDIRVM_MSX2
    pop bc
    ld hl,raycast_buffer+2048
    ld de,CLRTBL2_SECONDARY+256*8*2
    jp LDIRVM_MSX2


;-----------------------------------------------
; Decodes the UI graphics, and renders the initial UI frame
setupUIPatterns:
    ; clear all the patterns of the first 2 banks:
    xor a
    ld hl,CHRTBL2
    ld bc,256*8*2
    call FILVRM

    ; copy name table:
    ld hl,ui
    ld de,raycast_buffer
    call pletter_unpack

    ld hl,raycast_buffer
    ld de,NAMTBL2+32*8*2
    ld bc,32*8
    call LDIRVM

    ld a,(raycast_use_double_buffer)
    or a
    ret z

    xor a
    ld hl,CLRTBL2_SECONDARY
    ld bc,256*8*2
    push bc
    call BIGFIL 
    pop bc

    xor a
    ld hl,CHRTBL2_SECONDARY
    jp BIGFIL 


;-----------------------------------------------
; updates the UI when the player picks up or uses a key:
; destroys af
update_UI_keys:
    ; clear keys:
    push hl
    push bc
    ld a,141
    ld bc,4
    ld hl,NAMTBL2+21*32+25
    call FILVRM

    ; draw keys:
    ld a,(player_keys)
    or a
    jp z,update_UI_keys_nokeys
    ld b,0
    ld c,a
    ld hl,NAMTBL2+21*32+25
    ld a,191
    call FILVRM
update_UI_keys_nokeys:
    pop bc
    pop hl
    ret


;-----------------------------------------------
; updates the UI when the health of the player changes
; destroys af
update_UI_health:
    push hl
    push bc
    xor a
    ld bc,8
    ld hl,NAMTBL2+19*32+7
    call FILVRM
    ld a,(player_health)
    or a
    jp z,update_UI_health_done
    srl a   ; divide by two
    or a
    jp z,update_UI_health_last_bar
    ld b,0
    ld c,a
    ld hl,NAMTBL2+19*32+7
    ld a,192
    call FILVRM
update_UI_health_last_bar:
    ld a,(player_health)
    and #01
    or a
    jp z,update_UI_health_done
    ld hl,NAMTBL2+19*32+7
    ld a,(player_health)
    srl a
    ADD_HL_A
    ld a,193
    ld bc,1
    call FILVRM

update_UI_health_done:
    pop bc
    pop hl
    ret


;-----------------------------------------------
; updates the UI when the mana of the player changes
; destroys af
update_UI_mana:
    push hl
    push bc
    xor a
    ld bc,8
    ld hl,NAMTBL2+21*32+7
    call FILVRM
    ld a,(player_mana)
    or a
    jp z,update_UI_mana_done
    srl a   ; divide by four
    srl a
    or a
    jp z,update_UI_mana_last_tile
    ld b,0
    ld c,a
    ld hl,NAMTBL2+21*32+7
    ld a,194
    call FILVRM

    ld hl,NAMTBL2+21*32+7
    ld a,(player_mana)
    srl a   ; divide by four
    srl a
    ADD_HL_A

update_UI_mana_last_tile:
    ld a,(player_mana)
    and #03
    or a
    jp z,update_UI_mana_done
    dec a
    jp z,update_UI_mana_one
    dec a
    jp z,update_UI_mana_two
update_UI_mana_three:  
    ld a,118
    call WRTVRM
    jp update_UI_mana_done
update_UI_mana_two:  
    ld a,255
    call WRTVRM
    jp update_UI_mana_done
update_UI_mana_one:  
    ld a,195
    call WRTVRM

update_UI_mana_done:
    pop bc
    pop hl
    ret


;-----------------------------------------------
; Clears the screen left to right
clearScreenLeftToRight:
    call clearAllTheSprites

    ;; make sure character 0 is empty on the top two banks:
    xor a
    ld bc,8
    ld hl,CLRTBL2
    call FILVRM
    xor a
    ld bc,8
    ld hl,CLRTBL2+256*8
    call FILVRM

    ld a,32
    ld bc,0
clearScreenLeftToRightExternalLoop
    push af
    push bc
    ld a,24
    ld hl,NAMTBL2
    add hl,bc
clearScreenLeftToRightLoop:
    push hl
    push af
    xor a
    ld bc,1
    call FILVRM
    pop af
    pop hl
    ld bc,32
    add hl,bc
    dec a
    jr nz,clearScreenLeftToRightLoop
    pop bc
    pop af
    inc bc
    dec a
    halt
    jr nz,clearScreenLeftToRightExternalLoop
    ret    


;-----------------------------------------------
; Copies a pattern from bank 3 to bank1, and sets it to white over black
; preserves all the registers
; hl: source pattern
; de: target pattern
copyWhitePatternFromBank3ToBank1:
    push hl
    push de
    push bc

    push de
    push hl
    ; copy the pattern to a buffer: hl -> patternCopyBuffer
    ld de,patternCopyBuffer
    ld bc,8
    call LDIRMV
    pop hl
    ; copy the attributes to a buffer: hl + (CLRTBL2-CHRTBL2) -> patternCopyBuffer2
    ld bc,CLRTBL2-CHRTBL2
    add hl,bc
    ld de,patternCopyBuffer2
    ld bc,8
    call LDIRMV
    pop de
    ; copy the patter to bank 1: patternCopyBuffer -> de
    ld hl,patternCopyBuffer
    ld bc,8
    push de
    call LDIRVM    
    pop hl
    ; copy the attributes to bank 1: patternCopyBuffer2 -> de + (CLRTBL2-CHRTBL2) 
    ld bc,CLRTBL2-CHRTBL2
    add hl,bc
    ex de,hl
    ld hl,patternCopyBuffer2
    ld bc,8
    call LDIRVM    

    pop bc
    pop de
    pop hl
    ret

