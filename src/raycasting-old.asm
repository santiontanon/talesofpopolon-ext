    include "top-constants.asm"
    include "../ToP2.sym"

;-----------------------------------------------
; - This code is compressed, and then decompressed to RAM at run time. This is for two main reasons:
; 1) To avoid wait-states when running on a Turbo R (and make the code faster)
; 2) To allow for self-modifying code optimizations that would not be possible otherwise (although these are small)

    org raycast_render_to_buffer

;-----------------------------------------------
; - renders the screen from the point of view of (raycast_camera_x), (raycast_camera_y), 
;   (raycast_player_angle) to raycast_buffer
; - the variables (raycast_first_column) and (raycast_last_column) control which columns
;   to render. This is useful, so I can split the rendering across multiple frames (in each
;   frame only rendering a few columns).

; - ixl: used only during the transition between ceiling to wall to store the type of wall we collided with
; - ixh: (raycast_camera_x)
; - iyl: contais the "raycast_row" (which screen y coordinate we are currently rendering). 
; - iyh: raycast_floor_texture_buffer/16

; - I used double indentation throughout this file when we are using the ghost registers, for clarity

raycast_render_to_buffer_RAM:
    call raycast_update_selfmodifying_ceiling_code
    ld iy,raycast_floor_texture_buffer

    ld a,(raycast_camera_x)
    ld ixh,a

    ; precalculate "(raycast_player_angle)*4"
    ld hl,raycast_player_angle
    ld l,(hl)
    ld h,0
    add hl,hl   ;; hl*4
    add hl,hl
    ld (SELFMODIFY_player_angle+1),hl

    ld a,(raycast_first_column)
    ld (raycast_column),a

raycast_render_next_column:
    ;; render one column
    ;; Get the pixel mask we need for this column:
    ;; a is expected to have (raycast_column)
    ld c,a  ; save the (raycast_column)
    ld hl,pixel_bit_masks
    ld d,0
    and #07
    ld e,a
    add hl,de
    ld a,(hl)
    ld (raycast_column_pixel_mask),a

    ;ld c,a  ; 'c' contains (raycast_column)
    ;ld h,pixel_bit_masks/256
    ;and #07
    ;ld l,a
    ;ld a,(hl)
    ;ld (raycast_column_pixel_mask),a

    jp nz,raycast_render_next_column_skip_bank_offset_recalculation
    ;; compute the offset in the render buffer where this column starts:
    ;; offset = (raycast_column/8)*4*8
    ld a,c  ;; at this point, c still has (raycast_column)
    and #f8
    ld l,a
    xor a
    ld h,a
    add hl,hl
    add hl,hl
    ex de,hl
    ld hl,raycast_buffer
    add hl,de
    ld (raycast_buffer_offset_bank1),hl
    ld hl,raycast_buffer+(32-RAYCAST_SIDE_BORDER*2)*4*8
    add hl,de
    ld (raycast_buffer_offset_bank2),hl
raycast_render_next_column_skip_bank_offset_recalculation:

    ;; hl = (raycast_player_angle)*4 + (raycast_column)
    ld b,0
SELFMODIFY_player_angle:
    ld hl,#0000 ;; <-- this will be substituted by a precomputed (raycast_player_angle)*4
    add hl,bc   ;; hl = (raycast_player_angle)*4 + (raycast_column)
    ;    add hl,bc   ;; hl = (raycast_player_angle)*4 + (raycast_column)

    res 0,l     ;; we should divide the lower byte by 2 (since render angles are between 0 - 127).
                ;; however, we later need to multiply by 32. So, we just clear the lowest bit, and then
                ;; later we will just have to multiply by 16

    ;; The following code is 4 almost exact replicas of each other, one for each of the four quadrants,
    ;; it looks extremely wasteful, but by having it replicated four times, I avoid a few memory accesses,
    ;; and comparisons, saving a lot of CPU time:
    ld a,h
    and #03
    jp z,raycast_render_first_quadrant_precompute
    dec a
    jp z,raycast_render_second_quadrant_precompute
    dec a
    jp z,raycast_render_third_quadrant_precompute

;; -------------------------------------
;; ---- CEILING RENDERING (FOURTH QUADRANT) STARTS HERE ----
;; -------------------------------------
raycast_render_fourth_quadrant_precompute:
    ;; cache the offset to the ray_x_offs_table and ray_y_offs_table tables:
    ld h,0
    ld a,254
    sub l
    ld l,a
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,(ray_x_offs_table+(8-RAYCAST_ROWS_PER_BANK)*4)-1
    add hl,de
    push hl
    ld b,h
    ld c,l

    ld hl,raycast_camera_y   ;; we store (raycast_camera_y) in the alternate "e"
    ld e,(hl)

    ;; get the mask we should apply to the pixel:
    ld hl,raycast_column_pixel_mask
    ld d,(hl)  ;; d now has the mask we should apply to every pixel along the wall

    ld hl,(ray_x_offs_table+ray_y_offs_table-32)-1
    xor a
    sbc hl,bc

    ld bc,(raycast_buffer_offset_bank1)
    exx
        pop hl  ; we recover the value of (raycast_column_x_offs_table_xangle_times_32)
        ld iyl,a    ;; iyl contains the raycast row 
        ld b,currentMap/256

raycast_render_next_pixel_ceiling_fourth_quadrant:
        ;; at this point, a and e contain (raycast_row)
        ;; do not consider the middle pixels (visibility is too far)
        cp RAYCAST_DISTANCE_THRESHOLD
        jp p,raycast_render_bg

        ld a,ixh
        inc hl
        add a,(hl)  ;; a = raycast_camera_x + ray_x_offs_table[xangle(bc)*32+y(e)]

        ld e,a      ; e = raycast_ray_x
        ld d,raycast_divide_by16_table/256
        ld a,(de)
        ld c,a
    exx
    ld a,e  ; e contains (raycast_camera_y)
    ; the alternate HL register has the value of (raycast_column_y_offs_table_xangle_times_32)
    inc hl  ; we increase it at each row, so, we don't have to actually add "DE"
    sub (hl)  ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld d,a
        ;; a = currentMap[(raycast_ray_x/16)+(raycast_ray_y/16)*16];
        and #f0
        add a,c
        ld c,a
        ld a,(bc)   ; b still contains currentMap/256

        or a ; same as cp 0, but faster
        jr nz,raycast_render_wall_from_fourth_quadrant

        ;; render one pixel of ceiling texture:
        ; precalculate the floor texture for later use during floor rendering: 
        ; e contains (raycast_ray_x), and d contains (raycast_ray_y)
        ld a,e
        xor d
        and #08
        ld (iy),a

SELFMODIFY_ceiling_texture_4th:
        ld a,e
        and d
        and #04
    exx
    jp z,raycast_render_done_with_ceiling_pixel_fourth_quadrant
    ld a,(bc)   ;; texture is 1, render pixel:
    or d
    ld (bc),a   ;; render pixel
raycast_render_done_with_ceiling_pixel_fourth_quadrant:
    inc bc
    exx
        inc iyl
        ld a,iyl  ;; since 'raycast_render_next_pixel_ceiling' expects the (raycast_row) to be in a
        jp raycast_render_next_pixel_ceiling_fourth_quadrant


;; re-calculate the map position where the previous ray hit (it's faster to recalculate it
;; than to store it at each iteration):
raycast_render_wall_from_fourth_quadrant:
        ld ixl,a
        ld a,ixh
        dec hl
        add a,(hl)  ;; a = raycast_camera_x + ray_x_offs_table[xangle(bc)*32+y(e)]
        ld h,b
        ld c,a

        ld b,raycast_divide_by16_table/256
        ld a,(bc)
        ld l,a

    exx
    ld a,e  ; e contains (raycast_camera_y)
    dec hl
    sub (hl)  ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld b,a
        jp raycast_render_wall


;; -------------------------------------
;; ---- CEILING RENDERING (FIRST QUADRANT) STARTS HERE ----
;; -------------------------------------
raycast_render_first_quadrant_precompute:
    ld h,a  ; a is 0 here
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,(ray_x_offs_table+(8-RAYCAST_ROWS_PER_BANK)*4)-1
    add hl,de
    push hl
    ld b,h
    ld c,l

    ld hl,raycast_camera_y   ;; we store (raycast_camera_y) in the alternate "e"
    ld e,(hl)

    ;; get the mask we should apply to the pixel:
    ld hl,raycast_column_pixel_mask
    ld d,(hl)  ;; d now has the mask we should apply to every pixel along the wall

    ld hl,(ray_x_offs_table+ray_y_offs_table-32)-1
    xor a
    sbc hl,bc

    ld bc,(raycast_buffer_offset_bank1)
    exx
        pop hl  ; we recover the value of (raycast_column_x_offs_table_xangle_times_32)
        ld iyl,a    ;; iyl contains the raycast row 
        ld b,currentMap/256

raycast_render_next_pixel_ceiling_first_quadrant:
        ;; at this point, a and e contain (raycast_row)
        ;; do not consider the middle pixels (visibility is too far)
        cp RAYCAST_DISTANCE_THRESHOLD
        jp p,raycast_render_bg

        ld a,ixh
        inc hl
        add a,(hl)  ;; a = raycast_camera_x + ray_x_offs_table[xangle(bc)*32+y(e)]

        ld e,a      ; e = raycast_ray_x
        ld d,raycast_divide_by16_table/256
        ld a,(de)
        ld c,a

    exx
    ld a,e  ; e contains (raycast_camera_y)
    ; the alternate HL register has the value of (raycast_column_y_offs_table_xangle_times_32)
    inc hl  ; we increase it at each row, so, we don't have to actually add "DE"
    add a,(hl)  ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld d,a
        ;; a = currentMap[(raycast_ray_x/16)+(raycast_ray_y/16)*16];
        and #f0
        add a,c
        ld c,a
        ld a,(bc)   ; b still contains currentMap/256

        or a ; same as cp 0, but faster
        jr nz,raycast_render_wall_from_first_quadrant

        ;; --------------------------------
        ;; render one pixel of ceiling texture:
        ; precalculate the floor texture for later on:
        ; e contains (raycast_ray_x), and d contains (raycast_ray_y)
        ld a,e
        xor d
        and #08
        ;; store the texture for later use during floor rendering
        ld (iy),a

SELFMODIFY_ceiling_texture_1st:
        ld a,e
        and d
        and #04
    exx
    jp z,raycast_render_done_with_ceiling_pixel_first_quadrant
    ;; texture is 1, render pixel:
    ld a,(bc)
    or d
    ld (bc),a   ;; render pixel
raycast_render_done_with_ceiling_pixel_first_quadrant:
    inc bc
    exx
        inc iyl
        ld a,iyl  ;; since 'raycast_render_next_pixel_ceiling' expects the (raycast_row) to be in a
        jp raycast_render_next_pixel_ceiling_first_quadrant


;; re-calculate the map position where the previous ray hit (it's faster to recalculate it
;; than to store it at each iteration):
raycast_render_wall_from_first_quadrant:
        ld ixl,a
        ld a,ixh
        dec hl
        add a,(hl)  ;; a = raycast_camera_x + ray_x_offs_table[xangle(bc)*32+y(e)]
        ld h,b
        ld c,a

        ld b,raycast_divide_by16_table/256
        ld a,(bc)
        ld l,a

    exx
    ld a,e  ; e contains (raycast_camera_y)
    dec hl
    add a,(hl)  ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld b,a
        jp raycast_render_wall


;; -------------------------------------
;; ---- CEILING RENDERING (SECOND QUADRANT) STARTS HERE ----
;; -------------------------------------
raycast_render_second_quadrant_precompute:
    ;; cache the offset to the ray_x_offs_table and ray_y_offs_table tables:
    ld h,a  ; a is 0 here
    ld a,254
    sub l
    ld l,a
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,(ray_x_offs_table+(8-RAYCAST_ROWS_PER_BANK)*4)-1
    add hl,de
    push hl
    ld b,h
    ld c,l

    ld hl,raycast_camera_y   ;; we store (raycast_camera_y) in the alternate "e"
    ld e,(hl)

    ;; get the mask we should apply to the pixel:
    ld hl,raycast_column_pixel_mask
    ld d,(hl)  ;; d now has the mask we should apply to every pixel along the wall

    ld hl,(ray_x_offs_table+ray_y_offs_table-32)-1
    xor a
    sbc hl,bc
    
    ld bc,(raycast_buffer_offset_bank1)
    exx
        pop hl  ; we recover the value of (raycast_column_x_offs_table_xangle_times_32)
        ld iyl,a    ;; iyl contains the raycast row 
        ld b,currentMap/256

raycast_render_next_pixel_ceiling_second_quadrant:
        ;; at this point, a and e contain (raycast_row)
        ;; do not consider the middle pixels (visibility is too far)
        cp RAYCAST_DISTANCE_THRESHOLD
        jp p,raycast_render_bg

        inc hl
        ld a,ixh
        sub (hl)       ;; a = raycast_camera_x - ray_x_offs_table[xangle(bc)*32+y(e)]

        ld e,a      ; e = raycast_ray_x
        ld d,raycast_divide_by16_table/256
        ld a,(de)
        ld c,a

    exx
    ld a,e  ; e contains (raycast_camera_y)
    ; the alternate HL register has the value of (raycast_column_y_offs_table_xangle_times_32)
    inc hl  ; we increase it at each row, so, we don't have to actually add "DE"
    add a,(hl)  ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld d,a
        ;; a = currentMap[(raycast_ray_x/16)+(raycast_ray_y/16)*16];
        and #f0
        add a,c
        ld c,a
        ld a,(bc)   ; b still contains currentMap/256

        or a ; same as cp 0, but faster
        jr nz,raycast_render_wall_from_second_quadrant

        ;; --------------------------------
        ;; render one pixel of ceiling texture:
        ; precalculate the floor texture for later on:
        ; e contains (raycast_ray_x), and d contains (raycast_ray_y)
        ld a,e
        xor d
        and #08
        ;; store the texture for later use during floor rendering
        ld (iy),a

SELFMODIFY_ceiling_texture_2nd:
        ld a,e
        and d
        and #04
    exx
    jp z,raycast_render_done_with_ceiling_pixel_second_quadrant
    ;; texture is 1, render pixel:
    ld a,(bc)
    or d
    ld (bc),a   ;; render pixel
raycast_render_done_with_ceiling_pixel_second_quadrant:
    inc bc
    exx
        inc iyl
        ld a,iyl  ;; since 'raycast_render_next_pixel_ceiling' expects the (raycast_row) to be in a
        jp raycast_render_next_pixel_ceiling_second_quadrant


;; re-calculate the map position where the previous ray hit (it's faster to recalculate it
;; than to store it at each iteration):
raycast_render_wall_from_second_quadrant:
        ld ixl,a
        dec hl
        ld a,ixh
        sub (hl)       ;; a = raycast_camera_x - ray_x_offs_table[xangle(bc)*32+y(e)]
        ld h,b
        ld c,a

        ld b,raycast_divide_by16_table/256
        ld a,(bc)
        ld l,a

    exx
    dec hl
    ld a,e  ; e contains (raycast_camera_y)
    add a,(hl)  ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld b,a
        jp raycast_render_wall


;; -------------------------------------
;; ---- CEILING RENDERING (THIRD QUADRANT) STARTS HERE ----
;; -------------------------------------
raycast_render_third_quadrant_precompute:
    ld h,a  ; a is 0 here
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,(ray_x_offs_table+(8-RAYCAST_ROWS_PER_BANK)*4)-1
    add hl,de
    push hl
    ld b,h
    ld c,l

    ld hl,raycast_camera_y   ;; we store (raycast_camera_y) in the alternate "e"
    ld e,(hl)

    ;; get the mask we should apply to the pixel:
    ld hl,raycast_column_pixel_mask
    ld d,(hl)  ;; d now has the mask we should apply to every pixel along the wall

    ld hl,(ray_x_offs_table+ray_y_offs_table-32)-1
    xor a
    sbc hl,bc

    ld bc,(raycast_buffer_offset_bank1)
    exx
        pop hl  ; we recover the value of (raycast_column_x_offs_table_xangle_times_32)
        ld iyl,a    ;; iyl contains the raycast row 
        ld b,currentMap/256

raycast_render_next_pixel_ceiling_third_quadrant:
        ;; at this point, a and e contain (raycast_row)
        ;; do not consider the middle pixels (visibility is too far)
        cp RAYCAST_DISTANCE_THRESHOLD
        jp p,raycast_render_bg

        inc hl
        ld a,ixh
        sub (hl)       ;; a = raycast_camera_x - ray_x_offs_table[xangle(bc)*32+y(e)]

        ld e,a      ; e = raycast_ray_x
        ld d,raycast_divide_by16_table/256
        ld a,(de)
        ld c,a

    exx
    ld a,e  ; e contains (raycast_camera_y)
    ; the alternate HL register has the value of (raycast_column_y_offs_table_xangle_times_32)
    inc hl      ;; we increase it at each row, so, we don't have to actually add "DE"
    sub (hl)    ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld d,a
        ;; a = currentMap[(raycast_ray_x/16)+(raycast_ray_y/16)*16];
        and #f0
        add a,c
        ld c,a
        ld a,(bc)   ; b still contains currentMap/256

        or a ; same as cp 0, but faster
        jr nz,raycast_render_wall_from_third_quadrant

        ;; --------------------------------
        ;; render one pixel of ceiling texture:
        ; precalculate the floor texture for later on:
        ; e contains (raycast_ray_x), and d contains (raycast_ray_y)
        ld a,e
        xor d
        and #08
        ;; store the texture for later use during floor rendering
        ld (iy),a

SELFMODIFY_ceiling_texture_3rd:
        ld a,e
        and d
        and #04
    exx
    jp z,raycast_render_done_with_ceiling_pixel_third_quadrant
    ;; texture is not 0, render pixel:
    ld a,(bc)
    or d
    ld (bc),a   ;; render pixel
raycast_render_done_with_ceiling_pixel_third_quadrant:
    inc bc
    exx
        inc iyl
        ld a,iyl  ;; since 'raycast_render_next_pixel_ceiling' expects the (raycast_row) to be in a
        jp raycast_render_next_pixel_ceiling_third_quadrant


;; -------------------------------------
;; ---- BACKGROUND RENDERING STARTS HERE ----
;; -------------------------------------

    ;; Skips all the middle pixels (those that are too far to render)
raycast_render_bg:
    exx
    ld hl,(raycast_buffer_offset_bank2)
    ld bc,RAYCAST_ROWS_PER_BANK*4-RAYCAST_DISTANCE_THRESHOLD
    add hl,bc
    ld a,RAYCAST_ROWS_PER_BANK*4*2-RAYCAST_DISTANCE_THRESHOLD
    jp raycast_render_start_floor


;; -------------------------------------
;; ---- WALL RENDERING STARTS HERE ----
;; -------------------------------------

; when calling "raycast_render_wall_from_first_quadrant", "raycast_render_wall_from_second_quadrant", etc. we know that:
; - b, c: currentMap/256, (raycast_ray_x/16)+(raycast_ray_y/16)*16
; - d, e: raycast_ray_y, raycast_ray_x
; - iyl: raycast_row


;; re-calculate the map position where the previous ray hit (it's faster to recalculate it
;; than to store it at each iteration):
raycast_render_wall_from_third_quadrant:
        ld ixl,a
        dec hl
        ld a,ixh
        sub (hl)       ;; a = raycast_camera_x - ray_x_offs_table[xangle(bc)*32+y(e)]
        ld h,b
        ld c,a

        ld b,raycast_divide_by16_table/256
        ld a,(bc)
        ld l,a

    exx
    ld a,e  ; e contains (raycast_camera_y)
    dec hl
    sub (hl)  ;; a = raycast_camera_y + ray_y_offs_table[xangle(bc)*32+y(e)]
    exx
        ld b,a
        ; jp raycast_render_wall


    ;; --------------------------------
    ;; render a whole vertical wall line of pixels:
    ;; at this point h points to the current map
    ; - e, d: raycast_ray_x, raycast_ray_y
    ; - c, b: raycast_previous_ray_x, raycast_previous_ray_y
    ; - h: currentMap/256
    ; - iyl: raycast_row
raycast_render_wall:
        ; recalculate (raycast_ray_x/16)+(raycast_ray_y/16)*16
        and #f0
        add a,l
        ld l,a

        ;; check if the wall is too close to be rendered:
        ld a,iyl
        or a
        ; jp z,raycast_render_done_with_column
        jp z,raycast_render_wall_too_close

        ;; determine the side of the wall we are colliding with, and the x coordinate of the texture:
        ;; We are going to cast a ray from (raycast_previous_ray_x),(raycast_previous_ray_y), which is in d,e to b,c
raycast_render_wall_determine_texture_and_column:
        ld a,c
        cp e
        jp z,raycast_render_wall_do_not_move_in_x
        jp m,raycast_render_wall_increase_x
raycast_render_wall_decrease_x:
        ld a,c
        dec c
        xor c
        and #10  ;; check if we need to change the map offset
        jp z,raycast_render_wall_done_with_x
        dec l
        ld a,(hl)
        or a
        jp z,raycast_render_wall_done_with_x

raycast_render_wall_collision_moving_in_x:
        ld a,b
        and #0f
        ld c,a  ; x offset in the texture
        ld a,(hl)
        jp raycast_render_wall_texture_and_column_determined

raycast_render_wall_increase_x:
        inc c
        ld a,c
        and #0f ;; check if we need to change the map offset
        jp nz,raycast_render_wall_done_with_x
        inc l
        ld a,(hl)
        or a
        jp nz,raycast_render_wall_collision_moving_in_x
        ; jp raycast_render_wall_done_with_x


raycast_render_wall_done_with_x:
        ld a,b
        cp d
        jp z,raycast_render_wall_do_not_move_in_y
        jp m,raycast_render_wall_increase_y
raycast_render_wall_decrease_y:
        ld a,b
        dec b
        xor b
        and #10  ;; check if we need to change the map offset
        jp z,raycast_render_wall_determine_texture_and_column
        ld a,l
        sub 16
        ld l,a
        ld a,(hl)
        or a
        jp nz,raycast_render_wall_collision_moving_in_y
        jp raycast_render_wall_determine_texture_and_column
raycast_render_wall_increase_y:
        inc b
        ld a,b
        and #0f  ;; check if we need to change the map offset
        jp nz,raycast_render_wall_determine_texture_and_column
        ld a,l
        add a,16
        ld l,a
        ld a,(hl)
        or a
        jp nz,raycast_render_wall_collision_moving_in_y
        jp raycast_render_wall_determine_texture_and_column


; special case that we do not have to move in "Y", we know the collision is in "X":
; so, we just need to calculate the right "hl"
raycast_render_wall_do_not_move_in_y:
        ld a,b
        and #0f
        ld c,a  ; x offset in the texture
        ld a,ixl
        jp raycast_render_wall_texture_and_column_determined


; special case that we do not have to move in "X", we know the collision is in "Y":
; so, we just need to calculate the right "hl"
raycast_render_wall_do_not_move_in_x:
        ld a,c
        and #0f
        ld c,a  ; x offset in the texture
        ld a,ixl
        jp raycast_render_wall_texture_and_column_determined

raycast_render_wall_collision_moving_in_y:
        ld a,c
        and #0f
        ld c,a  ; x offset in the texture
        ld a,(hl)
    ;    jp raycast_render_wall_texture_and_column_determined


; - c: the texture x coordinate
; - a: the texture ID
; - iyl: raycast_row
raycast_render_wall_texture_and_column_determined:
        ; animation of texture 10 (alternates 10 and 11):
        bit 7,a
        jp z,raycast_render_wall_texture_and_column_determined_next
        and #7f
        ld hl,game_cycle
        bit 2,(hl)
        jp z,raycast_render_wall_texture_and_column_determined_next
        inc a   ;; second frame in the animation

raycast_render_wall_texture_and_column_determined_next:

    ;; get the proper texture:
    exx
    add a,a
    add a,(textures/256)-2   ; we subtract 2, since texture IDs start at 1 (and each 2 is 1 texture since they are 512 bytes each)
    ld d,a   
    ld a,(raycast_column_pixel_mask)
    ; self modify the code with the masks to "or"
    ld (SELFMODIFY_or_mask1+1),a    
    ld (SELFMODIFY_or_mask2+1),a
    ld (SELFMODIFY_or_mask3+1),a
    exx

        ld d,0
        ld a,iyl
        ld e,a
        ld hl,texture_vertical_rate_table+(8-RAYCAST_ROWS_PER_BANK)*4*2
        add hl,de
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)   ; de now contains the increment at which we have to move vertically through the texture

        ;; height of the wall is (32-y)*2: (we should only enter here if (raycast_row) is < 32, so, we can safely use (raycast_row) as "y")
        cpl
        add a,RAYCAST_ROWS_PER_BANK*4+1    ;; a = 32-(raycast_row)
        ld b,a        ;; b has the height of the wall/2
        push bc

    exx
raycast_render_wall_loop_start:    
        ; bc still contains (raycast_buffer_offset_bank1)
    ld hl,raycast_color_buffer-raycast_buffer
    add hl,bc
    exx
        ld a,iyl  ;; we advance the (raycast_row) to after the wall is rendered
        add a,b
        add a,b
        ld iyl,a

        ld h,0

raycast_render_wall_loop_top_half:
        ;; get the texture pixel:
        ld a,h
        and #f0
        add a,c     ; c contains the x offset of the texture
        add hl,de   ; we move to the next position in the texture
    exx 
    ld e,a  ; d has (textures/256)
    ld a,(de)

    ;; if the texture is 0, skip pixel
    or a ; same as cp 0, but faster
    jp z,raycast_render_wall_loop_top_half_continue
    ld (hl),a ;; render color
    ld a,(bc)
SELFMODIFY_or_mask1:
    or #00      ;; <-- this will be substituted by the proper mas to or
    ld (bc),a   ;; render pixel
raycast_render_wall_loop_top_half_continue:
    inc hl
    inc bc
    exx
        djnz raycast_render_wall_loop_top_half

raycast_render_wall_loop_bottom_half_pre:
        pop bc  ; we get the height of the wall, and the texture x coordinate again
        ld h,0
    exx
    ld bc,(raycast_buffer_offset_bank2)
    ld hl,raycast_color_buffer-raycast_buffer
    add hl,bc
    inc d   ; we move to the bottom part of the texture
    exx
raycast_render_wall_loop_bottom_half:
        ;; get the texture pixel:
        ld a,h
        add hl,de
        and #f0
        add a,c ; c contains the x offset of the texture
    exx 
    ld e,a  ; e has (raycast_texture_ptr)
    ld a,(de)

    ;; if the texture is 0, skip pixel
    or a ; same as cp 0, but faster
    jp z,raycast_render_wall_loop_bottom_half_continue
    ld (hl),a ;; render color
    ld a,(bc)
SELFMODIFY_or_mask2:
    or #00      ;; <-- this will be substituted by the proper mask to or
    ld (bc),a ;; render pixel
raycast_render_wall_loop_bottom_half_continue:
    inc hl
    inc bc
    exx
        djnz raycast_render_wall_loop_bottom_half
;       jp raycast_render_start_floor_from_wall


;; -------------------------------------
;; ---- FLOOR RENDERING STARTS HERE ----
;; -------------------------------------

raycast_render_start_floor_from_wall:
        ;; make the connection between wall and floor always black, to minimize color clash
        ld a,iyl
        add a,2
    exx
    ld hl,2
    add hl,bc
SELFMODIFY_or_mask3:
    ld d,#00    ;; <-- this will be substituted by the proper mask to or

raycast_render_start_floor:
    ;; a contains (raycast_row)
    ;; d contains the mask we should apply to the pixel
    cp RAYCAST_ROWS_PER_BANK*8-1   ;; we cut it one pixel short
    jp p,raycast_render_done_with_column

    ;; from this point, on, we forget about updating raycast_row, and just keep 63-raycast_row in "c"
    cpl
    add a,(RAYCAST_ROWS_PER_BANK*8-1)+1
    ld b,raycast_floor_texture_buffer/256
    ld c,a

    ;; if the mask is #c0, that means we don;t need to "or" it, and we can just write it directly, 
    ;; So, we jump to a different loop that is a bit faster:
    bit 7,d
    jp nz,raycast_render_next_pixel_floor_first_column

raycast_render_next_pixel_floor:
    ;; retrieve the texture offset stored during ceiling rendering:
    ld a,(bc)
    or a ; same as cp 0, but faster
    jr z,raycast_render_done_with_floor_pixel   ; this one is a jr, since it's chosen 50% of the times, and in average, it's faster than jp
    ld a,(hl)   ;; texture is 1, render pixel:
    or d
    ld (hl),a   ;; render pixel
raycast_render_done_with_floor_pixel:
    inc hl
    dec c
    jp nz,raycast_render_next_pixel_floor

raycast_render_done_with_column:
    ld hl,raycast_column
    ld a,(hl)
    add a,2
    ld (hl),a
    ld hl,raycast_last_column
    cp (hl)
    jp nz,raycast_render_next_column
    ret
    

raycast_render_next_pixel_floor_first_column:
    ;; retrieve the texture offset stored during ceiling rendering:
    ld a,(bc)
    or a ; same as cp 0, but faster
    jr z,raycast_render_done_with_floor_pixel_first_column   ; this one is a jr, since it's chosen 50% of the times, and in average, it's faster than jp
    ;; texture is 1, render pixel:
    ld (hl),d   ;; render pixel
raycast_render_done_with_floor_pixel_first_column:
    inc hl
    dec c
    jp nz,raycast_render_next_pixel_floor_first_column
    jp raycast_render_done_with_column


raycast_render_wall_too_close:
    ; if the wall is too close, we clear the top part, just in case we have a skybox (to clear it):
    exx
        ld hl,raycast_color_buffer-raycast_buffer
        add hl,bc
        xor a
        ld b,32
raycast_render_wall_too_close_loop:
        ld (hl),a
        inc hl
        djnz raycast_render_wall_too_close_loop
    exx
    jp raycast_render_done_with_column


raycast_update_selfmodifying_ceiling_code:
    ld hl,SELFMODIFY_ceiling_texture_1st
    call raycast_update_selfmodifying_ceiling_code_sub
    ld hl,SELFMODIFY_ceiling_texture_2nd
    call raycast_update_selfmodifying_ceiling_code_sub
    ld hl,SELFMODIFY_ceiling_texture_3rd
    call raycast_update_selfmodifying_ceiling_code_sub
    ld hl,SELFMODIFY_ceiling_texture_4th
;    call raycast_update_selfmodifying_ceiling_code_sub

raycast_update_selfmodifying_ceiling_code_sub:
    ld a,(raycast_ceiling_type)
    or a
    jr z,raycast_update_selfmodifying_ceiling_code_sub_ceiling
raycast_update_selfmodifying_ceiling_code_sub_skybox:
    ld (hl),#d9 ; exx
    inc hl
    ld (hl),#18 ; jr raycast_render_done_with_ceiling_pixel_first_quadrant
    inc hl
    ;ld (hl),raycast_render_done_with_ceiling_pixel_first_quadrant-SELFMODIFY_ceiling_texture_1st
    ld (hl),8
    ret

raycast_update_selfmodifying_ceiling_code_sub_ceiling:
    ld (hl),#7b ; ld a,e
    inc hl
    ld (hl),#a2 ; and d
    inc hl
    ld (hl),#e6 ; first byte of and #04
    ret

