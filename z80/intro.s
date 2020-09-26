; Wolfenstein 3D for Gameboy Color
; (c) 2017, Anders Granlund
; www.happydaze.se
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

.INCLUDE "defines.i"


.RAMSECTION "intro_vars" BANK 0 SLOT SLOT_RAM
mm_ypos      DS 1
.ENDS

.BANK 0 SLOT SLOT_ROM
.ORG $200
.SECTION "Code_Intro" SEMIFREE

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Legal screen
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
intro:
    ; copy legal screen chr & map
    ld      a, :legal_tile_data
    ld      ($2000), a
    ld      hl, $8000
    ld      de, legal_tile_data
    ld      c, 127
    call    gfx_chr_copy
    ld      hl, $9800
    ld      de, legal_map_data
    call    gfx_map_copy_20x18

    ; enable bg
    ld      a, %10010001
    ldh     (R_LCDC), a

    ; fade in
    xor     a
-   push    af
    ld      hl, PAL_WHITE
    ld      de, legal_pal_data
    ld      bc, 1
    call    gfx_pal_fade_bg
    pop     af
    inc     a
    cp      129
    jr      nz, -

    ; pause a while
    ld      bc, 60 * 4
    call    sys_delay

    ; fade out
    xor     a
-   push    af
    ld      hl, legal_pal_data
    ld      de, PAL_BLACK
    ld      bc, 1
    call    gfx_pal_fade_bg
    pop     af
    inc     a
    cp      129
    jr      nz, -

    ret


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Title screen
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
title:
    xor     a
    ld      (cheat_godmode), a
    ld      (cheat_guns), a
    ld      a, 1
    ld      (start_floor), a
    xor     a
    ld      (mm_ypos), a
    ld      (pwd_start), a
  
    ; stop music and sound
    call    snd_stop_music
    call    snd_stop_fx

    ; clear all palettes to black
    ld      hl, PAL_BLACK
    ld      bc, 8
    call    gfx_pal_copy_bg
    ld      hl, PAL_BLACK
    ld      bc, 8
    call    gfx_pal_copy_obj

    ; init screen and interrupts
    di
    xor     a
    ldh     (R_IF), a
    ldh     (R_IE), a
    ld      a, %10010001
    ldh     (R_LCDC), a

    ; copy title screen chr & map
    ld      a, :title_tile_data
    ld      ($2000), a
    ld      hl, $8000
    ld      de, title_tile_data
    ld      c, 127
    call    gfx_chr_copy
    ld      hl, $9800
    ld      de, title_map_data
    call    gfx_map_copy_20x18
    ; copy font
    ld      a, :msg_chr
    ld      ($2000), a
    ld      hl, $8500
    ld      de, msg_chr
    ld      c, 48
    call    gfx_chr_copy
    ; prepare menu
    call    sys_wait_vbl
    ld      a, 1
    ldh     (R_VBK), a
    ld      hl, $99C4
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ld      hl, $99E4
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ld      a, %00100001
    ld      hl, $99CE
    ld      (hl), a
    ld      hl, $99EE
    ld      (hl), a
    xor     a
    ldh     (R_VBK), a

    ; start music
    ld      a, 0
    call    snd_play_music

    ; fade in
    xor     a
-   push    af
    ld      bc, 1
    call    sys_delay
    call    snd_update
    ld      a, :title_pal_data
    ld      ($2000), a
    pop     af
    ld      hl, PAL_BLACK
    ld      de, title_pal_data
    ld      bc, 2
    push    af
    call    gfx_pal_fade_bg
    pop     af
    inc     a
    cp      129
    jr      c, -

    call    title_print_menu
    ld      a, $7C
    call    title_print_cursor
-   call    sys_wait_vbl

    ; play music, check start button
+   call    snd_update
    call    sys_update_joypad

    ld      a, (g_joypad_trigger)
    and     %11000000
    jr      z, +
    xor     a
    call    title_print_cursor
    ld      a, (mm_ypos)
    inc     a
    and     1
    ld      (mm_ypos), a
    ld      a, $7C
    call    title_print_cursor
+   ld      a, (g_joypad_trigger)
    and     %00000001
    jr      z, -
 
    ld      a, (mm_ypos)
    and     %00000001
    jp      nz, title_to_password_screen

    ; go to cheat menu   
    ld      a, (g_joypad_status)
    and     %00000100
    jp      nz, title_to_cheat_menu

    ; play sound effect
    call    snd_stop_music
    ld      a, $1
    call    snd_play_fx
    ld      c, 1
-   push    bc
    call    snd_update
    ld      bc, 1
    call    sys_delay
    pop     bc
    dec     c
    jr      nz, -
    
    ; fade out
    xor     a
-   push    af
    ld      bc, 1
    call    sys_delay
    call    snd_update
    ld      a, :title_pal_data
    ld      ($2000), a
    pop     af
    ld      hl, title_pal_data
    ld      de, PAL_BLACK
    ld      bc, 2
    push    af
    call    gfx_pal_fade_bg
    pop     af
    add     4
    cp      129
    jr      c, -    
    ld      bc, 20
    call    sys_delay
    ret

title_print_menu:
    ld      hl, $99C6
    ld      de, title_menu1
    ld      b, 8
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     b
    jr      nz, -
    ld      hl, $99E6
    ld      de, title_menu2
    ld      b, 8
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     b
    jr      nz, -
    ret

title_print_cursor:
    ld      b, a
    ld      hl, $99C5
    ld      a, (mm_ypos)
    sla     a
    sla     a
    sla     a
    sla     a
    sla     a
    ld      e, a
    ld      d, 0
    add     hl, de
    ld      de, 9
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      (hl), b
    add     hl, de
    ;ld      (hl), b    
    ret


title_to_cheat_menu:
    xor     a
-   push    af
    ld      bc, 1
    call    sys_delay
    call    snd_update
    ld      a, :title_pal_data
    ld      ($2000), a
    pop     af
    ld      hl, title_pal_data
    ld      de, PAL_RED
    ld      bc, 2
    push    af
    call    gfx_pal_fade_bg
    pop     af
    add     4
    cp      129
    jr      c, -    
    ld      bc, 20
    jp      cheatmenu


title_to_password_screen:
    xor     a
-   push    af
    ld      bc, 1
    call    sys_delay
    call    snd_update
    ld      a, :title_pal_data
    ld      ($2000), a
    pop     af
    ld      hl, title_pal_data
    ld      de, PAL_RED
    ld      bc, 2
    push    af
    call    gfx_pal_fade_bg
    pop     af
    add     4
    cp      129
    jr      c, -    
    ld      bc, 20
    call    password
    ld      a, (pwd_start)
    or      a
    jp      z, title
    ret


title_menu1:
.DB $68, $5F, $71, $00, $61, $5B, $67, $5F
title_menu2:
.DB $5D, $69, $68, $6E, $63, $68, $6F, $5F
.ENDS


.BANK 3 SLOT SLOT_ROM_BANKED
.SECTION "intro_data" SEMIFREE
; Data for legal screen
.INCLUDE "gfx/legal.s"
legal_pal_data:
.db 20,  0,  0
.db 13,  0,  0
.db  7,  0,  0
.db 25, 25, 25

; Data for title screen
.INCLUDE "gfx/title.s"
title_pal_data:
.db 31, 31, 31
.db 25, 15, 15
.db 20,  0,  0
.db  0,  0,  0

.db 20,  0,  0
.db 20,  0,  0
.db 20,  0,  0
.db 31, 31, 31
.ENDS


