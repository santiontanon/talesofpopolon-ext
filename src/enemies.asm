;-----------------------------------------------
; Assigns all the sprites corresponding to enemies to the sprite table
updateAndAssignEnemySprites:
    ld ix,currentMapEnemies
    ld a,(ix)   ; n enemies
    or a
    ret z
    inc ix
    ld b,a
    ld a,1
    ld (assigningSpritesForAnEnemy),a
updateAndAssignEnemySprites_loop:
    ld a,(ix)
    or a
    jr z,updateAndAssignEnemySprites_skip

    push bc
    call updateEnemy
    call assignEnemySprite
    pop bc

updateAndAssignEnemySprites_skip:
    ld de,ENEMY_STRUCT_SIZE
    add ix,de
    djnz updateAndAssignEnemySprites_loop
    xor a
    ld (assigningSpritesForAnEnemy),a
    ret

;-----------------------------------------------
; Determines if the player is closer than a certain distance to the enemy:
; - ix: pointer to enemy
; - b: maximum distance
; return value is:
; - in the "p" condition (p to true is if player is too far)
; - e,d: have the differences in x and y
isPlayerCloseToEnemy:
    ld a,(player_x)
    sub (ix+1)
    ld e,a
    jp p,isPlayerCloseToEnemy_positive_xdiff
    neg
isPlayerCloseToEnemy_positive_xdiff:
    cp b    ;; only update enemies that are inside of a radius of 4 tiles
    ret p
    ld a,(player_y)
    sub (ix+2)
    ld d,a
    jp p,isPlayerCloseToEnemy_positive_ydiff
    neg
isPlayerCloseToEnemy_positive_ydiff:
    cp b    ;; only update enemies that are inside of a radius of 4 tiles
    ret


;-----------------------------------------------
; Executes one update cycle of an enemy
; - parameters:
;   IX: pointer to the enemy parameters (type, x, y, sprite, color, ...)
updateEnemy:
    ld a,(hourglass_timer)
    or a
    ret nz  ;; if the hourglass is in use, do not update enemies

    ; if they are too far, also do not update them:
    ld b,64
    call isPlayerCloseToEnemy
    ret p

updateEnemy_check_which_enemy:
    ld a,(ix)
    bit 7,a
    jr nz,updateFrozenEnemy

    dec a
;    cp ENEMY_EXPLOSION
    jp z,updateExplosion
    dec a
;    cp ENEMY_RAT_H
    jp z,updateEnemyRatH
    dec a
;    cp ENEMY_RAT_V
    jp z,updateEnemyRatV
    dec a
;    cp ENEMY_BLOB
    jp z,updateEnemyBlob
    dec a
;    cp ENEMY_SKELETON
    jp z,updateEnemySkeleton
    dec a
;    cp ENEMY_KNIGHT
    jp z,updateEnemyKnight
    dec a
;    cp ENEMY_SNAKE
    jp z,updateEnemySnake
    dec a
;    cp ENEMY_MEDUSA
    jp z,updateEnemyMedusa
    dec a
;    cp ENEMY_MEDUSA_STONE
    jp z,updateEnemyMedusa
    dec a
    ; cp ENEMY_KER
    jp z,updateEnemyKer
    dec a
    ;cp ENEMY_KER2
    jp z,updateEnemyKer
    dec a
    ; cp ENEMY_KER3
    jp z,updateEnemyKer
    dec a
    ;; cp ENEMY_SWITCH
    ;; nothing to do for a switch (and yes, "switches" are handled as if they were enemies...)
    ret z
    ;dec a
;    cp ENEMY_BULLET
;    jp z,updateEnemyBullet
    jp updateEnemyBullet
;    ret


updateFrozenEnemy:
    dec (ix+8)
    ret nz
    ; unfreeze!
    ld a,(ix)
    and #7f
    ld (ix),a
    ld a,(ix+7)
    ld (ix+4),a ; restore the old enemy color
    xor a
    ld (ix+6),a
    ld (ix+7),a
    ;ld (ix+8),a    ; no need to set this to 0, since we already know it is
    ret


checkEnemyHitPlayer:
    ld a,(player_hit_timmer)
    or a
    ret nz  ;; players cannot be hit when player_hit_timmer > 0

    ld b,4
    call isPlayerCloseToEnemy
    ret p
    
checkEnemyHitPlayer_playerBeingHit:
    ;; player being hit: iron armor: -3hp, silver armor: -2hp, gold armor: -1hp
    ld a,(player_health)
    or a
    jr z,checkEnemyHitPlayer_player_dead

    push hl
    ld hl,SFX_playerhit    
    call play_ingame_SFX
    pop hl

    ld hl,player_health
    ld a,(current_armor)
    dec a
    jr z,checkEnemyHitPlayer_lose2hp
    dec a
    jr z,checkEnemyHitPlayer_lose1hp
checkEnemyHitPlayer_lose3hp:
    dec (hl)
    jr z,checkEnemyHitPlayer_player_dead
checkEnemyHitPlayer_lose2hp:
    dec (hl)
    jr z,checkEnemyHitPlayer_player_dead
checkEnemyHitPlayer_lose1hp:
    dec (hl)
    jr nz,checkEnemyHitPlayer_player_not_dead
checkEnemyHitPlayer_player_dead:
    ld a,GAME_STATE_GAME_OVER
    ld (game_state),a
    jp update_UI_health

checkEnemyHitPlayer_player_not_dead:
;    ld (player_health),a
    ld a,16
    ld (player_hit_timmer),a
    jp update_UI_health


updateExplosion:
    dec (ix+6)
    ret nz
    ld (ix),0     ;; make the explosion disappear
    ret

updateEnemyRatH:
    call checkEnemyHitPlayer
    ld a,(game_cycle)
    and #01
    jr z,updateEnemyRat_animation  ;; move only once every 2 cycles
    ld a,(ix+7)   ; state 2 (moving left or right)
    or a
    jr z,updateEnemyRatH_left
updateEnemyRatH_right:
    inc (ix+1)
    ld c,(ix+1)
    ld b,(ix+2)
    call getMapPosition
    or a
    jr z,updateEnemyRat_animation
    ; (collision) change direction
    dec (ix+1)
    xor a
    ld (ix+7),a
    jr updateEnemyRat_animation

updateEnemyRatH_left:
    dec (ix+1)
    ld c,(ix+1)
    ld b,(ix+2)
    call getMapPosition
    or a
    jr z,updateEnemyRat_animation
    ; (collision) change direction
    inc (ix+1)
    ld (ix+7),1

updateEnemyRat_animation:
    ld a,(game_cycle)
    and #02
    jr z,updateEnemyRat_sprite2
    ld (ix+3),ENEMY_RAT_SPRITE_PATTERN
    ret
updateEnemyRat_sprite2:
    ld (ix+3),ENEMY_RAT_SPRITE_PATTERN+4
    ret

updateEnemyRatV:
    call checkEnemyHitPlayer
    ld a,(game_cycle)
    and #01
    jr z,updateEnemyRat_animation  ;; move only once every 2 cycles
    ld a,(ix+7)   ; state 2 (moving up or down)
    or a
    jr z,updateEnemyRatV_up
updateEnemyRatH_down:
    inc (ix+2)
    ld c,(ix+1)
    ld b,(ix+2)
    call getMapPosition
    or a
    jr z,updateEnemyRat_animation
    ; (collision) change direction
    dec (ix+2)
    xor a
    ld (ix+7),a
    jr updateEnemyRat_animation

updateEnemyRatV_up:
    dec (ix+2)
    ld c,(ix+1)
    ld b,(ix+2)
    call getMapPosition
    or a
    jr z,updateEnemyRat_animation
    ; (collision) change direction
    inc (ix+2)
    ld (ix+7),1
    jr updateEnemyRat_animation


updateEnemyBlob:
    ld b,24
    call isPlayerCloseToEnemy
    jp p,updateEnemyBlob_animation

    ; move toward the player:
    ld a,(game_cycle)
    and #03
    call z,moveEnemyTowardED

    ; if the player is close, then check if we are touching the player
    call checkEnemyHitPlayer

updateEnemyBlob_animation
    ld a,(game_cycle)
    and #02
    jr z,updateEnemyBlob_sprite2
    ld (ix+3),ENEMY_BLOB_SPRITE_PATTERN
    ret
updateEnemyBlob_sprite2:
    ld (ix+3),ENEMY_BLOB_SPRITE_PATTERN+4
    ret


updateEnemySkeleton:
    ld b,48
    call isPlayerCloseToEnemy
    jp p,updateEnemySkeleton_animation

    ld a,(game_cycle)
    and #7f
    call z,enemyFireBullet  ; fire a bullet every once in a while    

    ; move toward the player:
    ld a,(game_cycle)
    and #03
    call z,moveEnemyTowardED

    ; if the player is close, then check if we are touching the player
    call checkEnemyHitPlayer

updateEnemySkeleton_animation
    ld a,(game_cycle)
    and #02   
    jr nz,updateEnemySkeleton_sprite2
    ld a,(game_cycle)
    and #04
    jr z,updateEnemySkeleton_sprite3
    ld (ix+3),ENEMY_SKELETON_SPRITE_PATTERN
    ret
updateEnemySkeleton_sprite2:
    ld (ix+3),ENEMY_SKELETON_SPRITE_PATTERN+4
    ret
updateEnemySkeleton_sprite3:
    ld (ix+3),ENEMY_SKELETON_SPRITE_PATTERN+8
    ret


updateEnemyKnight:
    ld b,48
    call isPlayerCloseToEnemy
    jp p,updateEnemyKnight_animation

    ld a,(game_cycle)
    and #7f
    call z,enemyFireBullet  ; fire a bullet every once in a while    

    ; move toward the player:
    ld a,(game_cycle)
    and #03
    call z,moveEnemyTowardED

    ; if the player is close, then check if we are touching the player
    call checkEnemyHitPlayer

updateEnemyKnight_animation
    ld a,(game_cycle)
    and #02   
    jr nz,updateEnemyKnight_sprite2
    ld a,(game_cycle)
    and #04
    jr z,updateEnemyKnight_sprite3
    ld (ix+3),ENEMY_KNIGHT_SPRITE_PATTERN
    ret
updateEnemyKnight_sprite2:
    ld (ix+3),ENEMY_KNIGHT_SPRITE_PATTERN+4
    ret
updateEnemyKnight_sprite3:
    ld (ix+3),ENEMY_KNIGHT_SPRITE_PATTERN+8
    ret


updateEnemySnake:
    ld b,48
    call isPlayerCloseToEnemy
    jp p,updateEnemySnake_animation

    ; move toward the player:
    ld a,(game_cycle)
    and #01
    call z,moveEnemyTowardED

    ; if the player is close, then check if we are touching the player
    call checkEnemyHitPlayer

updateEnemySnake_animation
    ld a,(game_cycle)
    and #02   
    jr nz,updateEnemySnake_sprite2
    ld a,(game_cycle)
    ld (ix+3),ENEMY_SNAKE_SPRITE_PATTERN
    ret
updateEnemySnake_sprite2:
    ld (ix+3),ENEMY_SNAKE_SPRITE_PATTERN+4
    ret


updateEnemyMedusa:
    inc (ix+8)
    ld a,(ix+8) ; state 3  < 64 medusa moves toward player, 64 - 128 stone, then reset
    and #7f
    cp 64
    jp p,updateEnemyMedusa_stone

    ; set medusa to skin color, and set it back to normal medusa:
    ld (ix+4),9
    ld (ix),ENEMY_MEDUSA

    ; check if player is close (no point, since this is larger than the 64 above):
;    ld b,80
;    call isPlayerCloseToEnemy
;    jp p,updateEnemyMedusa_animation

    ; move toward the player:
    ld a,(game_cycle)
    and #01
    call z,moveEnemyTowardED

    ; if the player is close, then check if we are touching the player
    call checkEnemyHitPlayer

updateEnemyMedusa_animation
    ld a,(game_cycle)
    and #02   
    jr nz,updateEnemyMedusa_sprite2
    ld (ix+3),ENEMY_MEDUSA_SPRITE_PATTERN
    ret
updateEnemyMedusa_sprite2:
    ld (ix+3),ENEMY_MEDUSA_SPRITE_PATTERN+8
    ret


updateEnemyMedusa_stone:
    call z,updateEnemyMedusa_spawn_snake    ; spawn a snake when it turns to stone

    ; set medusa to stone color, and make her invulnerable:
    ld (ix+4),14
    ld (ix),ENEMY_MEDUSA_STONE

    jp checkEnemyHitPlayer

updateEnemyMedusa_spawn_snake:
    call enemyFireBullet
    ; enemy type, x, y, sprite, color, hit points, state1, state2, state3
    ld (hl),ENEMY_SNAKE
    inc hl
    inc hl
    inc hl
    ld (hl),ENEMY_SNAKE_SPRITE_PATTERN
    inc hl
    ld (hl),2 ;; color
    ret


updateEnemyKer:
    inc (ix+8)

    ; check if player is close (no point since this is larger than the 64 above):
;    ld b,80
;    call isPlayerCloseToEnemy
;    jp p,updateEnemyKer_animation

    ld a,(game_cycle)
    and #3f
    call z,enemyFireBullet  ; fire a bullet every once in a while    

    ; move toward the player:
    ld a,(ix+8) ; state 3  < 64 ker moves toward player, 64 - 128 freezes
    and #7f
;    cp 104
;    jp p,updateEnemyKer_dash
    cp 64
    jp p,updateEnemyKer_movement_done

updateEnemyKer_dash_regular_movement:
    ld a,(game_cycle)
    and #01
    call z,moveEnemyTowardED
;    jp updateEnemyKer_movement_done

;updateEnemyKer_dash:
;    push de
;    call moveEnemyTowardED
;    pop de
;    jp updateEnemyKer_dash_regular_movement

updateEnemyKer_movement_done:
    ; if the player is close, then check if we are touching the player
    call checkEnemyHitPlayer

updateEnemyKer_animation
    ld a,(game_cycle)
    and #02   
    jr nz,updateEnemyKer_sprite2
    ld (ix+3),ENEMY_KER_SPRITE_PATTERN
    ret
updateEnemyKer_sprite2:
    ld (ix+3),ENEMY_KER_SPRITE_PATTERN+8
    ret


updateEnemyBullet:
    ; state 1 is the angle at which they move
moveEnemyBullet:
    ; move in the desired direction:
    ld hl,cos_table
    ld b,0
    ld c,(ix+8) ;; angle of movement of the bullet
    add hl,bc
    add hl,bc
    push hl
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld h,(ix+1)     ; (ix+1),(ix+6) for the 16bit high precision coordinates of the enemy
    ld l,(ix+6)
    add hl,bc
    ld (ix+1),h
    ld (ix+6),l
    pop hl
    ld bc,sin_table - cos_table
    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld h,(ix+2)     ; (ix+2),(ix+7) for the 16bit high precision coordinates of the enemy
    ld l,(ix+7)
    add hl,bc
    ld (ix+2),h
    ld (ix+7),l

    ld c,(ix+1)
    ld b,(ix+2)
    call getMapPosition
    or a    
    ; make bullet disappear:
    jr z,updateEnemyBullet_noWallHit
    ld (ix),0
    ret
updateEnemyBullet_noWallHit:
    ld a,(player_hit_timmer)
    or a
    ret nz  ;; players cannot be hit when player_hit_timmer > 0

    ld b,2
    call isPlayerCloseToEnemy
    jp m,checkEnemyHitPlayer_playerBeingHit
    ret


;-----------------------------------------------
; Fires a bullet if possible, input:
; - d,e: difference in y,x of the player position
; - at the end, hl contains the pointer to the new bullet
enemyFireBullet:
    ; find available enemy spot:
    ld hl,currentMapEnemies
    ld b,(hl)
    inc hl
enemyFireBullet_loop:
    ld a,(hl)
    or a
    jr z,enemyFireBullet_foundspot
    ld de,ENEMY_STRUCT_SIZE
    add hl,de
    dec b
    jr nz,enemyFireBullet_loop
    ld a,(currentMapEnemies)
    cp MAX_ENEMIES_PER_MAP
    jp m,enemyFireBullet_newspot
    ret
enemyFireBullet_newspot:
    ld a,(currentMapEnemies)
    inc a
    ld (currentMapEnemies),a
enemyFireBullet_foundspot:
;    push hl
;    ld hl,SFX_fire_bullet_enemy
;    call playSFX
;    pop hl
    ; enemy type, x, y, sprite, color, hit points, state1, state2, state3
    push hl
    ld (hl),ENEMY_BULLET
    ld a,(ix+1)
    inc hl
    ld (hl),a
    inc hl
    ld a,(ix+2)
    ld (hl),a
    inc hl
    ld (hl),ENEMY_BULLET_SPRITE_PATTERN
    inc hl
    ld (hl),10    ; color
    inc hl
    ld (hl),1     ; hp
    inc hl
    xor a
    ld (hl),a     ; state 1
    inc hl
    ld (hl),a     ; state 2
    inc hl
    push hl
    ; angle between enemy and player:
    ld a,(player_x)
    sub (ix+1)
    ld b,a
    ld a,(player_y)
    sub (ix+2)
    ld c,a
    call atan2
    pop hl
    ld (hl),a   ; state 3
    pop hl  ; we recover the pointer to the beginning of the bullet
    ret


;-----------------------------------------------
; moves the enemy pointed at by ix toward the direction pointed by (e,d) as a vector
; this function assumes that the two state bytes are used to store the lower bytes of the x and y precision coordinates
moveEnemyTowardED:
    ; get the angle toward the desired direction:
    ld b,e  ; xdiff
    ld c,d  ; ydiff
    call atan2

    ; move in the desired direction:
    ld hl,cos_table
    ld b,0
    ld c,a
    add hl,bc
    add hl,bc
    push hl
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld h,(ix+1)     ; (ix+1),(ix+6) for the 16bit high precision coordinates of the enemy
    ld l,(ix+6)
    add hl,bc
    ld b,(ix+2)
    ld c,h
    call getMapPosition
    or a
    jr nz,moveEnemyTowardED_skip_x
    ld (ix+1),h
    ld (ix+6),l
moveEnemyTowardED_skip_x:
    pop hl
    ld bc,sin_table-cos_table
    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld h,(ix+2)     ; (ix+2),(ix+7) for the 16bit high precision coordinates of the enemy
    ld l,(ix+7)
    add hl,bc
    ld c,(ix+1)
    ld b,h
    call getMapPosition
    or a
    ret nz
    ld (ix+2),h
    ld (ix+7),l
    ret


;-----------------------------------------------
; - places an enemy sprite in the sprite assignment table for rendering in the next frame
; - parameters:
;   IX: pointer to the enemy parameters (type, x, y, sprite, color, ...)
;assignEnemySprite:
;    jp assignSprite_prefilter
assignEnemySprite_continue:
    ; 4) assign the sprite to the table:
    ld a,(assignSprite_bank)
    ld b,a
    ld hl,sprites_available_per_depth
    ADD_HL_A
    dec (hl)
    ld a,(hl)
    sla b
    sla b   ;; note: this assumes that N_SPRITES_PER_DEPTH = 4
    add a,b ; a = bank*4 + slot inside the bank
    ld de,other_sprite_attributes
    add a,a   
    add a,a   
    ADD_DE_A
    ld a,(ix)
    and #7f ; ignore the MSB (which stores whether the enemy is frozen or not)
    cp ENEMY_MEDUSA
    jp z,assignEnemySprite_medusa
    cp ENEMY_MEDUSA_STONE
    jp z,assignEnemySprite_medusa
    cp ENEMY_KER
    jp z,assignEnemySprite_ker
    cp ENEMY_KER2
    jp z,assignEnemySprite_ker
    cp ENEMY_KER3
    jp z,assignEnemySprite_ker
    ld hl,assignSprite_y
    ldi
    ldi
    push de
    ld a,(assignSprite_bank)
    add a,(ix+3)
    call getOrLoadEnemySpritePattern
    pop de
    ld (de),a
    inc de
    ld a,(ix+4)
    ld (de),a
    ret


assignEnemySprite_medusa:
    ; if bank == 1: y+=2
    ; if bank == 2: y+=6
    ; if bank == 3: y+=11
    ld a,(assignSprite_bank)
    dec a
    jr z,assignEnemySprite_medusa_bank1
    dec a
    jr z,assignEnemySprite_medusa_bank2
    dec a
    jr z,assignEnemySprite_medusa_bank3
assignEnemySprite_medusa_y_adjusted:    
    ld hl,assignSprite_y
    ldi
    ldi
    push de
    ld a,(assignSprite_bank)
    add a,(ix+3)
    add a,4
    call getOrLoadEnemySpritePattern
    pop de
    ld (de),a
    inc de
    ld a,12 ; tail is always green
    ld (de),a

    ;; ensure we have space for the second sprite:
    ld a,(assignSprite_bank)
    ld hl,sprites_available_per_depth
    ADD_HL_A
    ld a,(hl)
    or a
    ret z   ;; if we don't have space, just return
    dec (hl)
    ex de,hl

    ld bc,-7
    add hl,bc
    ld a,(assignSprite_y)
    add a,-32
    ld (hl),a
    inc hl
    ld a,(assignSprite_x)
    ld (hl),a
    inc hl
    ; get which sprite to use
    push hl
    ld a,(assignSprite_bank)
    add a,(ix+3)
    call getOrLoadEnemySpritePattern
    pop hl
    ld (hl),a
    inc hl
    ld a,(ix+4)
    ld (hl),a
    ret

assignEnemySprite_medusa_bank1:
    ld a,(assignSprite_y)
    add a,2
    ld (assignSprite_y),a
    jp assignEnemySprite_medusa_y_adjusted
assignEnemySprite_medusa_bank2:
    ld a,(assignSprite_y)
    add a,6
    ld (assignSprite_y),a
    jp assignEnemySprite_medusa_y_adjusted
assignEnemySprite_medusa_bank3:
    ld a,(assignSprite_y)
    add a,11
    ld (assignSprite_y),a
    jp assignEnemySprite_medusa_y_adjusted


assignEnemySprite_ker:
    ld hl,assignSprite_y
    ld a,(assignSprite_bank)
    and #02
    ld a,(hl)
    jr nz,assignEnemySprite_ker_noyupdate
    sub 16
assignEnemySprite_ker_noyupdate:
    ld (de),a
    inc de
    inc hl
    ldi
    ; get which sprite to use
    push de
    ld a,(assignSprite_bank)
    add a,(ix+3)
    call getOrLoadEnemySpritePattern
    pop de
    ld (de),a
    inc de
    ld a,(ix+4)
    ld (de),a

    ;; ensure we have space for the second sprite:
    ld a,(assignSprite_bank)
    ld hl,sprites_available_per_depth
    ADD_HL_A
    ld a,(hl)
    or a
    ret z   ;; if we don't have space, just return
    dec (hl)
    ex de,hl
    ld bc,-7
    add hl,bc
    ex de,hl
    ld hl,assignSprite_y
    ldi
    ldi
    ; get which sprite to use
    push de
    ld a,(assignSprite_bank)
    add a,(ix+3)
    add a,4
    call getOrLoadEnemySpritePattern
    pop hl
    ld (hl),a
    inc hl
    ld a,15 ; body is always white
    ld (hl),a
    ret


;-----------------------------------------------
; Checks if the sprite pattern identified in 'a' is loaded in the 'spritePatternCacheTable'
; if it is, it returns its index (+24), and if it's not, it loads it into the table, and returns
; the index (+24) where it has been loaded
getOrLoadEnemySpritePattern:
    ; check to see if we have it already loaded in the VDP:
    ld b,a
    ld c,24
    ld hl,spritePatternCacheTable
getOrLoadEnemySpritePattern_loop:
    ld a,(hl)
    cp b
    jr z,getOrLoadEnemySpritePattern_found
    inc hl
    inc c
    ld a,c
    cp 32
    jr nz,getOrLoadEnemySpritePattern_loop

getOrLoadEnemySpritePattern_not_found:
    ; mark the table so that in position (spritePatternCacheTableNextToErase) we now have the new sprite:
    ld hl,spritePatternCacheTable
    ld a,(spritePatternCacheTableNextToErase)
    ADD_HL_A
    ld (hl),b
    ; load pattern 'b' onto position 'a+24'
    ld a,(spritePatternCacheTableNextToErase)
    add a,24
    add a,a
    add a,a
    push af ;; save the index for later
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl      ;; hl = a*32
    ld de,SPRTBL2
    add hl,de
    ex de,hl

    ld l,b
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl      ;; hl = b*32
    ld bc,enemySpritePatterns
    add hl,bc
    ld bc,32
    call LDIRVM

    ; increment the erasing pointer:
    ld hl,spritePatternCacheTableNextToErase
    ld a,(hl)
    inc a
    and #07
    ld (hl),a

    pop af  ;; retrieve the index
    ret

getOrLoadEnemySpritePattern_found:
    ld a,c
    add a,a
    add a,a
    ret

