;-----------------------------------------------
; pletter v0.5c msx unpacker
; call unpack with hl pointing to some pletter5 data, and de pointing to the destination.
; changes all registers

GETBIT:  MACRO 
  add a,a
  call z,pletter_getbit
  ENDM

GETBITEXX:  MACRO 
  add a,a
  call z,pletter_getbitexx
  ENDM

pletter_unpack:
  ld a,(hl)
  inc hl
  exx
  ld de,0
  add a,a
  inc a
  rl e
  add a,a
  rl e
  add a,a
  rl e
  rl e
  ld hl,pletter_modes
  add hl,de
  ld e,(hl)
  ld ixl,e
  inc hl
  ld e,(hl)
  ld ixh,e
  ld e,1
  exx
  ld iy,pletter_loop
pletter_literal:
  ldi
pletter_loop:
  GETBIT
  jr nc,pletter_literal
  exx
  ld h,d
  ld l,e
pletter_getlen:
  GETBITEXX
  jr nc,pletter_lenok
pletter_lus:
  GETBITEXX
  adc hl,hl
  ret c
  GETBITEXX
  jr nc,pletter_lenok
  GETBITEXX
  adc hl,hl
  ret c
  GETBITEXX
  jp c,pletter_lus
pletter_lenok:
  inc hl
  exx
  ld c,(hl)
  inc hl
  ld b,0
  bit 7,c
  jp z,pletter_offsok
  jp ix

pletter_mode6:
  GETBIT
  rl b
pletter_mode5:
  GETBIT
  rl b
pletter_mode4:
  GETBIT
  rl b
pletter_mode3:
  GETBIT
  rl b
pletter_mode2:
  GETBIT
  rl b
  GETBIT
  jr nc,pletter_offsok
  or a
  inc b
  res 7,c
pletter_offsok:
  inc bc
  push hl
  exx
  push hl
  exx
  ld l,e
  ld h,d
  sbc hl,bc
  pop bc
  ldir
  pop hl
  jp iy

pletter_getbit:
  ld a,(hl)
  inc hl
  rla
  ret

pletter_getbitexx:
  exx
  ld a,(hl)
  inc hl
  exx
  rla
  ret

pletter_modes:
  dw pletter_offsok
  dw pletter_mode2
  dw pletter_mode3
  dw pletter_mode4
  dw pletter_mode5
  dw pletter_mode6


;-----------------------------------------------
; Source: (thanks to ARTRAG) https://www.msx.org/forum/msx-talk/development/memory-pages-again
; Sets the memory pages to : BIOS, ROM, ROM, RAM
setupROMRAMslots:
    call RSLREG     ; Reads the primary slot register
    rrca
    rrca
    and #03         ; keep the two bits for page 1
    ld c,a
    add a,#C1       
    ld l,a
    ld h,#FC        ; HL = EXPTBL + a
    ld a,(hl)
    and #80         ; keep just the most significant bit (expanded or not)
    or c
    ld c,a          ; c = a || c (a had #80 if slot was expanded, and #00 otherwise)
    inc l           
    inc l
    inc l
    inc l           ; increment 4, in order to get to the corresponding SLTTBL
    ld a,(hl)       
    and #0C         
    or c            ; in A the rom slotvar 
    ld h,#80        ; move page 1 of the ROM to page 2 in main memory
    jp ENASLT       
    
;-----------------------------------------------
; Source: https://www.msx.org/forum/msx-talk/development/8-bit-atan2?page=0
; 8-bit atan2
; Calculate the angle, in a 256-degree circle.
; The trick is to use logarithmic division to get the y/x ratio and
; integrate the power function into the atan table. 
;   input
;   B = x, C = y    in -128,127
;
;   output
;   A = angle       in 0-255
;      |
;  q1  |  q0
;------+-------
;  q3  |  q2
;      |
atan2:  
        ld  de,#8000           
        
        ld  a,c
        add a,d
        rl  e               ; y-                    
        
        ld  a,b
        add a,d
        rl  e               ; x-                    
        
        dec e
        jp  z,atan2_q1
        dec e
        jp  z,atan2_q2
        dec e
        jp  z,atan2_q3
        
atan2_q0:         
        ld  h,log2_tab / 256
        ld  l,b
        
        ld  a,(hl)          ; 32*log2(x)
        ld  l,c
        
        sub (hl)          ; 32*log2(x/y)
        
        jr  nc,atan2_1f           ; |x|>|y|
        neg             ; |x|<|y|   A = 32*log2(y/x)
atan2_1f:      
        ld  l,a

        ld  h,atan_tab / 256
        ld  a,(hl)
        ret c           ; |x|<|y|
        
        neg
        and #3F            ; |x|>|y|
        ret
                
atan2_q1:     
        ld  a,b
        neg
        ld  b,a
        call    atan2_q0
        neg
        and #7F
        ret
        
atan2_q2:     
        ld  a,c
        neg
        ld  c,a
        call    atan2_q0
        neg
        ret     
        
atan2_q3:     
        ld  a,b
        neg
        ld  b,a
        ld  a,c
        neg
        ld  c,a
        call    atan2_q0
        add a,128
        ret



;-----------------------------------------------
; calls "halt" "b" times
waitBhalts:
    halt
    djnz waitBhalts
    ret


;-----------------------------------------------
; hl = a*32
hl_equal_a_times_32:
    ld h,0
    ld l,a
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ret


;-----------------------------------------------
; clears an area of memory to 0s very fast (faster than with ldir) by using the stack. 
; Method inspired in this idea: http://www.cpcwiki.eu/index.php/Programming:Filling_memory_with_a_byte#Using_the_stack
; - Interrupts are disabled, since we are messing with the SP register temporarily
; - can clear up to 4096 bytes (could be extended easily, but not needed for this game)
; - input: 
;   - hl: last memory address to clear + 1
;   - bc: amount of memory to clear
;   - a: byte to write
fast_memory_clear:
    di
    ld (SP_buffer_for_fast_memory_clear),sp 
    ld sp,hl    ; 1 byte beyond the last position to set to 0
    sla c
    rl b   
    sla c
    rl b   
    sla c
    rl b   
    sla c
    rl b   
    ld h,a                ; data we will write
    ld l,a
    ; Fill the memory
fast_memory_clear_loop:
    push hl                ; write 2 bytes
    push hl                ; write 2 bytes
    push hl                ; write 2 bytes
    push hl                ; write 2 bytes
    push hl                ; write 2 bytes
    push hl                ; write 2 bytes
    push hl                ; write 2 bytes
    push hl                ; write 2 bytes
    djnz fast_memory_clear_loop
    ld sp,(SP_buffer_for_fast_memory_clear)
    ei   
    ret 


;-----------------------------------------------
; Check the amount of VRAM
checkAmountOfVRAM:
    xor a
    ld hl,raycast_double_buffer
    ld (hl),a
    inc hl  ; hl = raycast_use_double_buffer
    ld (hl),a
    ld a,(MODE)
    and #06
    ret z
    inc (hl)
    ret


;-----------------------------------------------
; source: https://www.msx.org/forum/development/msx-development/how-0?page=0
; returns 1 in a and clears z flag if vdp is 60Hz
CheckIf60Hz:
    di
    in      a,(#99)
    nop
    nop
    nop
CheckIf60Hz_vdpSync:
    in      a,(#99)
    and     #80
    jr      z,CheckIf60Hz_vdpSync
    
    ld      hl,#900
CheckIf60Hz_vdpLoop:
    dec     hl
    ld      a,h
    or      l
    jr      nz,CheckIf60Hz_vdpLoop
    
    in      a,(#99)
    rlca
    and     1
    ei
    ret


;-----------------------------------------------
; A couple of useful macros for adding 16 and 8 bit numbers

ADD_HL_A: MACRO 
    add a,l
    ld l,a
    jr nc, $+3
    inc h
    ENDM

ADD_DE_A: MACRO 
    add a,e
    ld e,a
    jr nc, $+3
    inc d
    ENDM    

ADD_HL_A_VIA_BC: MACRO
    ld b,0
    ld c,a
    add hl,bc
    ENDM


;-----------------------------------------------
; macro to print a debug character to screen
;DEBUG: MACRO ?character,?position
;    push hl
;    push af
;    ld hl,NAMTBL2+256+256+7*32
;    ld a,?position
;    ADD_HL_A
;    ld a,?character
;    call WRTVRM
;    pop af
;    pop hl
;    ENDM
