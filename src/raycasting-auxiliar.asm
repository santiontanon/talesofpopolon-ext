;-----------------------------------------------
; Copies the render buffer to video memory
raycast_render_buffer:
    ld hl,raycast_use_double_buffer
    ld a,(hl)
    or a
    jp z,raycast_render_buffer_msx1
    dec hl  ; hl = raycast_double_buffer
    ld a,(hl)
    or a
    ; if (raycast_double_buffer) == 0, we need to render on buffer 2 (since we are showing 0 right now)
    jp z,raycast_render_buffer_msx2_buffer2
raycast_render_buffer_msx2_buffer1:
    ; This makes sure the addresses are in the first buffer (in the fisrt 16K of the VRAM)
    ld hl,initial_rendering_address+1
    res 6,(hl)
    ld hl,initial_rendering_address+3
    res 6,(hl)
    ld hl,initial_rendering_address+5
    res 6,(hl)
    ld hl,initial_rendering_address+7
    res 6,(hl)
    jp raycast_render_buffer_buffer_selected
raycast_render_buffer_msx2_buffer2:
    ; This adds #4000 to the addresses, to be in the second buffer
    ld hl,initial_rendering_address+1
    set 6,(hl)
    ld hl,initial_rendering_address+3
    set 6,(hl)
    ld hl,initial_rendering_address+5
    set 6,(hl)
    ld hl,initial_rendering_address+7
    set 6,(hl)
raycast_render_buffer_buffer_selected:

    ld hl,(initial_rendering_address)
    ld de,raycast_buffer
    call raycast_render_buffer_copyloop_msx2
    ld hl,(initial_rendering_address+2)
    ld de,raycast_color_buffer
    call raycast_render_color_buffer_copyloop_msx2
    ld hl,(initial_rendering_address+4)
    ld de,raycast_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
    call raycast_render_buffer_copyloop_msx2
    ld hl,(initial_rendering_address+6)
    ld de,raycast_color_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
    call raycast_render_color_buffer_copyloop_msx2

    ; switch to the right bank after the copy:
    ld hl,raycast_double_buffer
    ld a,(hl)
    or a
    jp z,raycast_switch_buffer_msx2_buffer2
raycast_switch_buffer_msx1_buffer1:
    dec (hl)
    jp selectVDPBuffer1InMSX2
raycast_switch_buffer_msx2_buffer2:
    inc (hl)
    jp selectVDPBuffer2InMSX2


raycast_render_buffer_msx1:
    ld hl,(initial_rendering_address)
    ld de,raycast_buffer
    call raycast_render_buffer_copyloop_msx1
    ld hl,(initial_rendering_address+2)
    ld de,raycast_color_buffer
    call raycast_render_color_buffer_copyloop_msx1
    ld hl,(initial_rendering_address+4)
    ld de,raycast_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
    call raycast_render_buffer_copyloop_msx1
    ld hl,(initial_rendering_address+6)
    ld de,raycast_color_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
;    jp raycast_render_color_buffer_copyloop_msx1

raycast_render_color_buffer_copyloop_msx1:
    push de
        call SETWRT
    pop hl
    ld a,(raycast_floor_texture_color)
    ld d,a
    jp raycast_render_buffer_copyloop_msx1_entrypoint

raycast_render_buffer_copyloop_msx1:
    push de
        call SETWRT
    pop hl
    ld d,0
raycast_render_buffer_copyloop_msx1_entrypoint:
    ld a,(VDP.DW)
    ld c,a
    ld a,(amount_of_bytes_to_render)
raycast_render_buffer_copyloop_msx1_loop1:
    ; NYYRIKKI:
    ld b,128
raycast_render_buffer_copyloop_msx1_loop1_b:
    REPT 16
        ld e,(hl)   ;8
        out (c),e   ;14 = 27
        ld (hl),d   ;8
        inc l       ;5
        out (c),e   ;14 = 27
        dec b       ;5
    ENDM
    jp nz,raycast_render_buffer_copyloop_msx1_loop1_b
    dec l
    inc hl
    dec a
    jp nz, raycast_render_buffer_copyloop_msx1_loop1
    ret

raycast_render_color_buffer_copyloop_msx2:
    push de
        call NSTWRT
    pop hl
    ld a,(raycast_floor_texture_color)
    ld d,a
    jp raycast_render_buffer_copyloop_msx1_entrypoint

raycast_render_buffer_copyloop_msx2:
    push de
        call NSTWRT
    pop hl
    ld d,0
    jp raycast_render_buffer_copyloop_msx1_entrypoint


;-----------------------------------------------
; Reset the VRAM to start ray casting 
; (this is only called once at game start, so it does not need to be fast):
; - sets the default colors to the ground color
; - sets the name table
; - resets the raycast buffer to all 0s
raycast_reset:
    ; set colors
    ld a,#f0
    ld bc,256*8*2
    ld hl,CLRTBL2
    call FILVRM

    xor a
    ld bc,256*8*2
    ld hl,CHRTBL2
    call FILVRM

    ; set the name table (first clear it to "RAYCAST_BORDER_PATTERN")
    IF RAYCAST_SIDE_BORDER > 0
    ld c,8
    ld b,32
    ld hl,raycast_buffer
    ld a,RAYCAST_BORDER_PATTERN
raycast_reset_loop1:
    ld (hl),a
    inc hl
    djnz raycast_reset_loop1
    dec c
    jr nz,raycast_reset_loop1
    ENDIF

    ; now set the names for the area that will be drawn
    ld hl,raycast_buffer+RAYCAST_SIDE_BORDER
    ld d,0
raycast_reset_loop2:
    ld b,32-(RAYCAST_SIDE_BORDER*2)
    ld a,d
raycast_reset_loop2_a:
    ld (hl),a
    inc hl
    add a,8
    djnz raycast_reset_loop2_a
    ld bc,RAYCAST_SIDE_BORDER*2
    add hl,bc
    inc d
    ld a,d
    cp 8
    jp nz,raycast_reset_loop2

    ;; reset the top 2 banks:
    ld bc,256
    ld de,NAMTBL2
    ld hl,raycast_buffer
    call LDIRVM

    ld bc,256
    ld de,NAMTBL2+256
    ld hl,raycast_buffer
    call LDIRVM

    ld a,(raycast_use_double_buffer)
    or a
    jr z, raycast_reset_clear_buffer

    xor a
    ld bc,256*8*2
    ld hl,CHRTBL2_SECONDARY
    call BIGFIL

    ; clear the raycast buffers:
raycast_reset_clear_buffer:
    ld bc,(raycast_amount_to_clear)
    push bc
    ld hl,raycast_buffer
    add hl,bc
    xor a
    call fast_memory_clear
    pop bc

    push bc
    ld hl,raycast_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
    add hl,bc
    xor a
    call fast_memory_clear
    pop bc

    push bc
    ld hl,raycast_color_buffer
    add hl,bc
    ld a,(raycast_ceiling_texture_color)
    call fast_memory_clear
    pop bc

    ld hl,raycast_color_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
    add hl,bc
    ld a,(raycast_floor_texture_color)
    call fast_memory_clear

raycast_reset_clear_buffer_set_pointers:
    ; we set the offsets for the first column of rendering:
    ld hl,raycast_buffer
    ld (raycast_buffer_offset_bank1),hl
    ld hl,raycast_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
    ld (raycast_buffer_offset_bank2),hl    

    ld a,(raycast_ceiling_type)
    or a
    ret z


raycast_reset_clear_buffer_render_skybox:

    ; start tile is (angle/4)%64
    ; - only draw tiles that fall in positions between: 0 and (raycast_sprite_angle_cutoff)
    ld a,(raycast_sprite_angle_cutoff)
    add a,12
    ld e,a
    ld a,(raycast_player_angle)
    neg
    add a,12*4
    and #fc ; a = ((-angle/4)%64)*4

    ; rendering address is raycast_buffer + a*8
    exx
        ld h,0
        ld l,a
        add hl,hl
        add hl,hl
        add hl,hl
        ld bc,raycast_buffer-12*8*4 
        add hl,bc   ; address to start rendering
        ex de,hl
        ld hl,skybox_buffer
    exx

    ; divide a by 4 to get ((angle/4 + 16)%64)
    srl a
    srl a

    ld d,12 ; width of the skybox
raycast_reset_clear_buffer_render_skybox_column_loop:
    cp 12
    jp m,raycast_reset_clear_buffer_render_skybox_skip_column
    cp e
    jp p,raycast_reset_clear_buffer_render_skybox_skip_column
    exx
        ; render a column:
        ld bc,16
        ldir
        ld bc,8*4-16
        ex de,hl
        add hl,bc
        ex de,hl
    exx
    inc a
    dec d
    jp nz,raycast_reset_clear_buffer_render_skybox_column_loop
    jp raycast_reset_clear_buffer_render_skybox_color

raycast_reset_clear_buffer_render_skybox_skip_column:
    exx
        ld bc,16
        add hl,bc
        ld bc,8*4
        ex de,hl
        add hl,bc
        ex de,hl
    exx
    inc a
    dec d
    jp nz,raycast_reset_clear_buffer_render_skybox_column_loop

raycast_reset_clear_buffer_render_skybox_color:
    exx
        ld bc,(raycast_color_buffer-raycast_buffer)-12*8*4
        ex de,hl
        add hl,bc
        ex de,hl
    exx

    sub 12
    ld d,12
raycast_reset_clear_buffer_render_skybox_column_loop_color:
    cp 12
    jp m,raycast_reset_clear_buffer_render_skybox_skip_column_color
    cp e
    jp p,raycast_reset_clear_buffer_render_skybox_skip_column_color
    exx
        ; render a column:
        ld bc,16
        ldir
        ld bc,8*4-16
        ex de,hl
        add hl,bc
        ex de,hl
    exx
    inc a
    dec d
    jp nz,raycast_reset_clear_buffer_render_skybox_column_loop_color
    ret

    

raycast_reset_clear_buffer_render_skybox_skip_column_color:
    exx
        ld bc,16
        add hl,bc
        ld bc,8*4
        ex de,hl
        add hl,bc
        ex de,hl
    exx
    inc a
    dec d
    jp nz,raycast_reset_clear_buffer_render_skybox_column_loop_color
    ret



;-----------------------------------------------
; creates a table of divisions by 16, which save a few cycles during raycasting
calculate_divide_by16_table:
    xor a
    ld hl,raycast_divide_by16_table
calculate_divide_by16_table_loop2:
    ld b,16
calculate_divide_by16_table_loop1:
    ld (hl),a
    inc hl
    djnz calculate_divide_by16_table_loop1
    inc a
    cp 16
    jp nz,calculate_divide_by16_table_loop2
    ret
