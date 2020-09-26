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

.RAMSECTION "password_vars" BANK 0 SLOT SLOT_RAM
vpw_buf      DS 6
vpw_len      DS 1
vpw_xpos     DS 1
vpw_ypos     DS 1
.ENDS



.BANK 0 SLOT SLOT_ROM
.ORG $200
.SECTION "Code_Screens" SEMIFREE

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Common screen init
; hl = palette
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
msg_screen_init:
    push    de
    push    hl
    ld      ($2000), a
    ; init all palettes
    pop     hl
    ld      bc, 8
    push    hl
    call    gfx_pal_copy_bg
    pop     hl
    ld      bc, 8
    call    gfx_pal_copy_obj
    ; init screen and interrupts
    di
    xor     a
    ldh     (R_IF), a
    ldh     (R_IE), a
    ld      a, %10010001
    ldh     (R_LCDC), a
    ; copy map data
    pop     de
    ld      hl, $9800
    call    gfx_map_copy_20x18
    ; copy chr data
    ld      a, :msg_chr
    ld      ($2000), a
    ld      hl, $8000
    ld      de, msg_chr
    ld      c, 103
    call    gfx_chr_copy
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Fade in
;   hl = source pal
;   de = dest pal
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
msg_screen_fade:
    xor     a
-   push    af
    push    hl
    push    de
    ld      bc, 4
    call    gfx_pal_fade_bg
    ld      bc, 1
    call    sys_delay
    call    snd_update
    pop     de
    pop     hl
    pop     af
    add     4
    cp      129
    jr      c, -    
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Game over
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gameover:
    call    snd_stop_music
    call    snd_stop_fx
    ld      a, :msg_map_gameover
    ld      de, msg_map_gameover
    ld      hl, PAL_RED
    call    msg_screen_init
    ; fade in
    ld      hl, PAL_RED
    ld      de, msg_pal
    call    msg_screen_fade
    ; wait for any key or timeout
    ld      de, 60 * 20
-   push    de
    ld      bc, 1
    call    sys_delay
    call    sys_update_joypad
    pop     de
    ld      a, (g_joypad_trigger)
    and     %00001111
    jr      nz, +
    dec     de
    ld      a, d
    or      e
    jr      nz, -
    ; fade out
+   ld      hl, msg_pal
    ld      de, PAL_BLACK
    call    msg_screen_fade    
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Victory
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
victory:
    call    snd_stop_music
    call    snd_stop_fx
    ld      a, :msg_map_victory
    ld      de, msg_map_victory
    ld      hl, PAL_WHITE
    call    msg_screen_init
    ; fade in
    ld      hl, PAL_WHITE
    ld      de, msg_pal
    call    msg_screen_fade
    ; wait for any key or timeout
    ld      de, 60 * 20
-   push    de
    ld      bc, 1
    call    sys_delay
    call    sys_update_joypad
    pop     de
    ld      a, (g_joypad_trigger)
    and     %00001111
    jr      nz, +
    dec     de
    ld      a, d
    or      e
    jr      nz, -
    ; fade out
+   ld      hl, msg_pal
    ld      de, PAL_BLACK
    call    msg_screen_fade    
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Elevator
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
elevator:
    call    snd_stop_music
    call    snd_stop_fx
    ld      a, :msg_map_elevator
    ld      de, msg_map_elevator
    ld      hl, PAL_BLACK
    call    msg_screen_init
    ; print floor number
    ld      a, (floor)
    inc     a
    ld      b, a
    ld      hl, $9830
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      (hl), b
    ; print password
    call    elevator_print_password
    ; fade in
    ld      hl, PAL_BLACK
    ld      de, msg_pal
    call    msg_screen_fade
    ; kills
    call    elevator_delay
    ld      a, (stat_kill_ratio)
    call    elevator_print_kill_ratio
    ; treasures
    call    elevator_delay
    ld      a, (stat_bonus_ratio)
    call    elevator_print_bonus_ratio
    ; secrets
    call    elevator_delay
    ld      a, (stat_secret_ratio)
    call    elevator_print_secret_ratio
    ; GET PSYCHED!
    call    elevator_delay
    call    elevator_print_psyched
    ; wait for any key or timeout
    ld      de, 60 * 20
-   push    de
    ld      bc, 1
    call    sys_delay
    call    sys_update_joypad
    call    snd_update
    pop     de
    ld      a, (g_joypad_trigger)
    and     %00001111
    jr      nz, +
    dec     de
    ld      a, d
    or      e
    ;jr      nz, -
    jr      -
    ; fade out
+   ld      hl, msg_pal
    ld      de, PAL_BLACK
    call    msg_screen_fade    
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Elevator - delay
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
elevator_delay:
    ld      c, 60
-   push    bc
    ld      bc, 1
    call    sys_delay
    call    snd_update
    pop     bc
    dec     c
    jr      nz, -
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Elevator - print psyched
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
elevator_print_psyched:
    ld      a, 1
    call    snd_play_fx
    ld      hl, $99E4
    ld      de, elevator_psyched_string
    ld      c, 12
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -    
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     c
    jr      nz, -
    ret
elevator_psyched_string:
.db 17, 15, 30, 0, 26, 29, 35, 13, 18, 15, 14, 40

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Elevator - print password
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
elevator_print_password:
    ld      hl, vpw_buf
    ld      a, (lives)
    ldi     (hl), a     ; vpw_buf + 0 = lives
    ld      b, a
    ld      a, (floordone_next)
    ldi     (hl), a     ; vpw_buf + 1 = floor
    add     b
    ld      b, a
    ld      a, (health)
    ldi     (hl), a     ; vpw_buf + 2 = health
    add     b
    ld      b, a
    ld      a, (guns)
    ldi     (hl), a     ; vpw_buf + 3 = guns
    add     b
    ld      b, a
    ld      a, (ammo)
    ldi     (hl), a     ; vpw_buf + 4 = ammo
    add     b
    ld      (hl), a     ; vpw_buf + 5 = checksum
    ld      hl, tempbuf
    ld      b, 0
    ld      a, (vpw_buf + 5)    ; c1
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; f1
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; l0
    sla     a
    sla     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h5
    sra     a
    sra     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; f4
    and     %00010000
    or      b
    ldi     (hl), a             ; tempbuf+0
    ld      b, 0
    ld      a, (vpw_buf + 4)    ; a4
    sra     a
    sra     a
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; l4
    sra     a
    sra     a
    sra     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; f3
    sra     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; f2
    sla     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; a0
    sla     a
    sla     a
    sla     a
    sla     a
    and     %00010000
    or      b
    ldi     (hl), a             ; tempbuf+1
    ld      b, 0
    ld      a, (vpw_buf + 3)    ; g2
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h1
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 3)    ; g0
    sla     a
    sla     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h6
    sra     a
    sra     a
    sra     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; a6
    sra     a
    sra     a
    and     %00010000
    or      b
    ldi     (hl), a             ; tempbuf+2
    ld      b, 0
    ld      a, (vpw_buf + 2)    ; h4
    sra     a
    sra     a
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; l2
    sra     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h2
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 3)    ; g1
    sla     a
    sla     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; a2
    sla     a
    sla     a
    and     %00010000
    or      b
    ldi     (hl), a             ; tempbuf+3
    ld      b, 0
    ld      a, (vpw_buf + 0)    ; l3
    sra     a
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h0
    sla     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 5)    ; c0
    sla     a
    sla     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; a3
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; f0
    sla     a
    sla     a
    sla     a
    sla     a
    and     %00010000
    or      b
    ldi     (hl), a             ; tempbuf+4
    ld      b, 0
    ld      a, (vpw_buf + 5)    ; c2
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; a5
    sra     a
    sra     a
    sra     a
    sra     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h3
    sra     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; l1
    sla     a
    sla     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; a1
    sla     a
    sla     a
    sla     a
    and     %00010000
    or      b
    ld      (hl), a             ; tempbuf+5
    ; convert to chr
    ld      b, 6
    ld      de, tempbuf
-   ld      a, (de)
    push    de
    ld      e, a
    ld      d, 0
    ld      hl, password_val_to_chr
    add     hl, de
    pop     de
    ld      a, (hl)
    ld      (de), a
    inc     de
    dec     b
    jr      nz, -
    ; print to screen
    ld      de, tempbuf
    ld      hl, $98CB
    ld      b, 6
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     b
    jr      nz, -
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Elevator - print score
;   de = score
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
elevator_print_score:
    ld      a, 1
    push    de
    call    snd_play_fx
    pop     de
    ld      bc, 10000
    call    sys_div_16x16   ; de = health/10000, bc = remainder
    ld      a, e
    ld      (tempbuf), a
    ld      d, b
    ld      e, c
    ld      bc, 1000
    call    sys_div_16x16   ; de = health/1000, bc = remainder
    ld      a, e
    ld      (tempbuf+1), a
    ld      d, b
    ld      e, c
    ld      bc, 100
    call    sys_div_16x16   ; de = health/100, bc = remainder
    ld      a, e
    ld      (tempbuf+2), a
    ld      d, b
    ld      e, c
    ld      bc, 10
    call    sys_div_16x16   ; de = health/10, bc = remainder
    ld      a, e
    ld      (tempbuf+3), a
    ld      a, c
    ld      (tempbuf+4), a
    xor     a
    ld      (tempbuf+5), a
    ld      (tempbuf+6), a
    ld      a, $1D
    ld      (tempbuf+8), a
    ld      a, $0D
    ld      (tempbuf+9), a
    ld      a, $19
    ld      (tempbuf+10), a
    ld      a, $1C
    ld      (tempbuf+11), a
    ld      a, $0F
    ld      (tempbuf+12), a
    ld      hl, $99E4
    ld      de, tempbuf+8
    ld      c, 5
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     c
    jr      nz, -
    ld      hl, $99EA
    ld      de, tempbuf+1
    ld      b, 0
    ld      c, 6
--  ld      a, (de)
    ld      b, $FF
    add     1               ; tile = 1 + digit
++  push    hl
    push    de
    push    af
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    pop     af
    ld      (hl), a
    pop     de
    pop     hl
    inc     de
    inc     hl
    dec     c
    jr      nz, --
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Elevator - print ratio
;   a = ratio
;   hl = map addr
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
elevator_print_kill_ratio:
    ld      hl, $994F
    jr      elevator_print_ratio
elevator_print_bonus_ratio:
    ld      hl, $996F
    jr      elevator_print_ratio
elevator_print_secret_ratio:
    ld      hl, $998F
    jr      elevator_print_ratio
elevator_print_ratio:
    push    hl
    push    af
    ld      a, 1
    call    snd_play_fx
    pop     af
    ld      e, a
    ld      d, 0
    ld      bc, 100
    call    sys_div_16x16   ; de = health/100, bc = remainder
    ld      a, e
    ld      (tempbuf), a
    ld      d, b
    ld      e, c
    ld      bc, 10
    call    sys_div_16x16   ; de = health/10, bc = remainder
    ld      hl, tempbuf+1
    ld      a, e
    ldi     (hl), a
    ld      a, c
    ldd     (hl), a
    dec     hl
    ld      d, h
    ld      e, l
    pop     hl
    ld      b, 0
    ld      c, 3
--  ld      a, (de)
    or      b
    jr      nz, +
    ld      a, c
    cp      1
    jr      z, +
    xor     a               ; blank tile = 0
    jr      ++
+   ld      a, (de)
    ld      b, $FF
    add     1               ; tile = 1 + digit
++  push    hl
    push    de
    push    af
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    pop     af
    ld      (hl), a
    pop     de
    pop     hl
    inc     de
    inc     hl
    dec     c
    jr      nz, --
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Cheat menu
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
cheatmenu:
    ld      a, :msg_map_cheat
    ld      de, msg_map_cheat
    ld      hl, PAL_RED
    call    msg_screen_init
    call    snd_update
    xor     a
    ld      (tempbuf+0), a     ; menu position
    ld      b, $2C
    call    cheatmenu_draw_cursor
    call    cheatmenu_redraw
    ; fade in
    ld      hl, PAL_RED
    ld      de, msg_pal
    call    msg_screen_fade
    ; wait for any key or timeout
-   ld      bc, 1
    call    sys_delay
    call    snd_update
    call    sys_update_joypad
    ; up
    ld      a, (g_joypad_trigger)
    bit     6, a
    jr      z, +
    ld      a, (tempbuf+0)
    cp      0
    jr      z, +
    ld      b, 0
    call    cheatmenu_draw_cursor
    dec     a
    ld      (tempbuf+0), a
    ld      b, $2C
    call    cheatmenu_draw_cursor
    ; down
+   ld      a, (g_joypad_trigger)
    bit     7, a
    jr      z, +
    ld      a, (tempbuf+0)
    cp      3
    jr      z, +
    ld      b, 0
    call    cheatmenu_draw_cursor
    inc     a
    ld      (tempbuf+0), a
    ld      b, $2C
    call    cheatmenu_draw_cursor
    ; start game
+   ld      a, (g_joypad_trigger)
    bit     3, a
    jr      nz, cheatmenu_startgame
    bit     0, a
    jr      z, +
    ld      a, (tempbuf+0)
    cp      3
    jr      nz, +
    jr      cheatmenu_startgame
    ; options
+   ld      a, (tempbuf+0)
    cp      0
    call    z, cheatmenu_handle_floor
    ld      a, (tempbuf+0)
    cp      1
    call    z, cheatmenu_handle_godmode
    ld      a, (tempbuf+0)
    cp      2
    call    z, cheatmenu_handle_guns
    ; refresh
    call    cheatmenu_redraw
    jr      -
    ; fadeout
cheatmenu_startgame:
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
    ld      a, 1
    call    snd_play_fx
+   ld      hl, msg_pal
    ld      de, PAL_BLACK
    call    msg_screen_fade    
    ret
   ret

cheatmenu_handle_floor:
    ld      a, (g_joypad_trigger)
    and     %00010001
    jr      z, ++
    ld      a, (start_floor)
    inc     a
    cp      10
    jr      c, +
    xor     a
+   ld      (start_floor), a
++  ld      a, (g_joypad_trigger)
    and     %00100010
    ret     z
    ld      a, (start_floor)
    dec     a
    cp      255
    jr      nz, +
    ld      a, 9
+   ld      (start_floor), a
    ret

cheatmenu_handle_godmode:
    ld      a, (g_joypad_trigger)
    and     %00110011
    ret     z
    ld      a, (cheat_godmode)
    inc     a
    and     1
    ld      (cheat_godmode), a
    ret

cheatmenu_handle_guns:
    ld      a, (g_joypad_trigger)
    and     %00110011
    ret     z
    ld      a, (cheat_guns)
    inc     a
    and     1
    ld      (cheat_guns), a
    ret

cheatmenu_redraw:
    ; floor
    ld      a, (start_floor)
    inc     a
    ld      b, a
    ld      hl, $98D0
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      (hl), b
    ; godmode
    ld      hl, $9910
    ld      de, cheatmenu_string_no
    ld      a, (cheat_godmode)
    or      a
    jr      z, +
    ld      de, cheatmenu_string_yes
+   call    cheatmenu_draw_string
    ; guns
    ld      hl, $9950
    ld      de, cheatmenu_string_no
    ld      a, (cheat_guns)
    or      a
    jr      z, +
    ld      de, cheatmenu_string_yes
+   call    cheatmenu_draw_string    
    ret

cheatmenu_draw_string:
    ld      c, 3
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     c
    jr      nz, -
    ret

cheatmenu_draw_cursor:
    push    af
    ld      a, (tempbuf+0)
    sla     a
    ld      hl, cheatmenu_ypos
    ld      e, a
    ld      d, 0
    add     hl, de
    ldi     a, (hl)
    ld      h, (hl)
    ld      l, a
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -    
    ld      (hl), b
    pop     af
    ret

cheatmenu_string_yes:
    .db 35, 15, 29
cheatmenu_string_no:
    .db 24, 25, 0
cheatmenu_ypos:
    .dw $98C1, $9901, $9941, $99A1


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Password screen
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.EQU PASSWORD_CURSOR    $27
password:
    ; load screen
    ld      a, :msg_map_password
    ld      de, msg_map_password
    ld      hl, PAL_RED
    call    msg_screen_init
    call    snd_update
    ; fade in
    ld      hl, PAL_RED
    ld      de, msg_pal
    call    msg_screen_fade
    ; init vars
    xor     a
    ld      hl, vpw_buf
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ld      (vpw_len), a
    ld      (vpw_ypos), a
    ld      (vpw_xpos), a
    ; draw cursor
    ld      a, PASSWORD_CURSOR
    call    password_draw_cursor
    ; update sound & joypad
-   ld      bc, 1
    call    sys_delay
    call    snd_update
    call    sys_update_joypad
    ; update cursor
    ld      a, (g_joypad_trigger)
    bit     6, a
    call    nz, password_up
    bit     7, a
    call    nz, password_down
    bit     4, a
    call    nz, password_right
    bit     5, a
    call    nz, password_left
    bit     0, a
    call    nz, password_a
    bit     1, a
    call    nz, password_b
    ld      a, (vpw_len)
    cp      6
    jr      z, password_try
    jr      -

password_try:
    ; lives (tempbuf+0)
    ld      b, 0
    ld      a, (vpw_buf + 0)    ; l0
    srl     a
    srl     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 5)    ; l1
    srl     a
    srl     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 3)    ; l2
    sla     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; l3
    sla     a
    sla     a
    sla     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; l4
    sla     a
    sla     a
    sla     a
    and     %00010000
    or      b
    ld      (tempbuf + 0), a
    ; floor (tempbuf+1)
    ld      b, 0
    ld      a, (vpw_buf + 4)    ; f0
    sra     a
    sra     a
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; f1
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; f2
    sra     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; f3
    sla     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; f4
    and     %00010000
    or      b
    ld      (tempbuf + 1), a
    ; health (tempbuf+2)
    ld      b, 0
    ld      a, (vpw_buf + 4)    ; h0
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h1
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 3)    ; h2
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 5)    ; h3
    sla     a
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 3)    ; h4
    sla     a
    sla     a
    sla     a
    sla     a
    and     %00010000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; h5
    sla     a
    sla     a
    and     %00100000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; h6
    sla     a
    sla     a
    sla     a
    and     %01000000
    or      b
    ld      (tempbuf + 2), a
    ; guns (tempbuf + 3)
    ld      b, 0
    ld      a, (vpw_buf + 2)    ; g0
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 3)    ; g1
    sra     a
    sra     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; g2
    sla     a
    sla     a
    and     %00000100
    or      b
    ld      (tempbuf + 3), a
    ; ammo (tempbuf + 4)
    ld      b, 0
    ld      a, (vpw_buf + 1)    ; a0
    sra     a
    sra     a
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 5)    ; a1
    sra     a
    sra     a
    sra     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 3)    ; a2
    sra     a
    sra     a
    and     %00000100
    or      b
    ld      b, a
    ld      a, (vpw_buf + 4)    ; a3
    and     %00001000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 1)    ; a4
    sla     a
    sla     a
    sla     a
    sla     a
    and     %00010000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 5)    ; a5
    sla     a
    sla     a
    sla     a
    sla     a
    and     %00100000
    or      b
    ld      b, a
    ld      a, (vpw_buf + 2)    ; a6
    sla     a
    sla     a
    and     %01000000
    or      b
    ld      (tempbuf + 4), a
    ; checksum (tempbuf + 5)
    ld      b, 0
    ld      a, (vpw_buf + 4)    ; c0
    sra     a
    sra     a
    and     %00000001
    or      b
    ld      b, a
    ld      a, (vpw_buf + 0)    ; c1
    sla     a
    and     %00000010
    or      b
    ld      b, a
    ld      a, (vpw_buf + 5)    ; c2
    sla     a
    sla     a
    and     %00000100
    or      b
    ld      (tempbuf + 5), a
    ; stop music
    call    snd_stop_music
    call    snd_update
    ; verify password
    xor     a
    ld      (pwd_start), a
    ld      hl, tempbuf
    call    password_verify
    ld      b, $A
    cp      0
    jr      z, +
    ; valid password
    ld      a, 1
    ld      (pwd_start), a
    ld      b, $15
+   ld      a, b
    call    snd_play_fx
    ld      c, 40
-   push    bc
    call    snd_update
    ld      bc, 1
    call    sys_delay
    pop     bc
    dec     c
    jr      nz, -
+   ld      hl, msg_pal
    ld      de, PAL_BLACK
    call    msg_screen_fade
    ret


password_verify:
    push    hl
    xor     a
    add     (hl)    ; lives
    inc     hl
    add     (hl)    ; floor
    inc     hl
    add     (hl)    ; health
    inc     hl
    add     (hl)    ; guns
    inc     hl
    add     (hl)    ; ammo
    inc     hl
    and     %00000111
    ld      b, a    ; b = calculated checksum
    ld      a, (hl) ; a = stored checksum
    pop     hl
    cp      b
    jr      z, +
    xor     a
    ret
+   ldi     a, (hl) ; lives
    cp      10
    jr      c, +
    xor     a
    ret
+   ldi     a, (hl) ; floor
    cp      10
    jr      c, +
    xor     a
    ret
+   ldi     a, (hl) ; health
    cp      0
    jr      z, +
    cp      101
    jr      c, ++
+   xor     a
    ret
++  ldi     a, (hl) ; guns
    ldi     a, (hl) ; ammo
    cp      100
    jr      c, +
    xor     a
    ret
+   ld      a, 1
    ret


password_draw:
    ; translate
    ld      hl, tempbuf
    ld      a, $25
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ldi     (hl), a
    ld      hl, tempbuf
    ld      de, vpw_buf
    ld      a, (vpw_len)
    cp      0
    jr      z, +
    ld      b, a
-   push    hl
    push    bc
    ld      a, (de)
    inc     de
    ld      hl, password_val_to_chr
    ld      c, a
    ld      b, 0
    add     hl, bc
    ld      a, (hl)
    pop     bc
    pop     hl
    ldi     (hl), a
    dec     b
    jr      nz, -
    ; print
+   ld      hl, $98E7
    ld      de, tempbuf
    ld      b, 6
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -   
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     b
    jr      nz, -
    ret

password_val_to_chr:
.DB $0C, $0D, $0E, $10, $11, $12, $13, $14
.DB $15, $16, $17, $18, $1A, $1B, $1C, $1D
.DB $1E, $20, $21, $22, $23, $24, $01, $02
.DB $03, $04, $05, $06, $07, $08, $09, $0A


password_draw_cursor:
    push    af
    ld      hl, $9942
    ld      a, (vpw_ypos)
    sla     a
    sla     a
    sla     a
    sla     a
    sla     a
    sla     a
    ld      e, a
    ld      a, (vpw_xpos)
    sla     a
    add     e
    ld      e, a
    ld      d, 0
    add     hl, de
    pop     af
    ld      b, a
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -    
    ld      (hl), b
    ret

password_up:
    push    af
    ld      a, 0
    call    password_draw_cursor
    ld      a, (vpw_ypos)
    dec     a
    and     3
    ld      (vpw_ypos), a
    ld      a, PASSWORD_CURSOR
    call    password_draw_cursor
    pop     af
    ret
password_down:
    push    af
    ld      a, 0
    call    password_draw_cursor
    ld      a, (vpw_ypos)
    inc     a
    and     3
    ld      (vpw_ypos), a
    ld      a, PASSWORD_CURSOR
    call    password_draw_cursor
    pop     af
    ret
password_left:
    push    af
    ld      a, 0
    call    password_draw_cursor
    ld      a, (vpw_xpos)
    dec     a
    and     7
    ld      (vpw_xpos), a
    ld      a, PASSWORD_CURSOR
    call    password_draw_cursor
    pop     af
    ret
password_right:
    push    af
    ld      a, 0
    call    password_draw_cursor
    ld      a, (vpw_xpos)
    inc     a
    and     7
    ld      (vpw_xpos), a
    ld      a, PASSWORD_CURSOR
    call    password_draw_cursor
    pop     af
    ret
password_b:
    push    af
    ld      a, (vpw_len)
    cp      0
    jr      z, +
    dec     a
    ld      (vpw_len), a
    call    password_draw
+   pop     af
    ret
password_a:
    push    af
    ld      hl, vpw_buf
    ld      a, (vpw_len)
    cp      6
    jr      nc, +
    ld      e, a
    ld      d, 0
    add     hl, de
    ld      a, (vpw_ypos)
    sla     a
    sla     a
    sla     a
    ld      b, a
    ld      a, (vpw_xpos)
    add     b
    ld      (hl), a
    ld      a, (vpw_len)
    inc     a
    ld      (vpw_len), a
    call    password_draw
+   pop     af
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Palette data
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
msg_pal:
    .db 20,  0,  0
    .db 10,  0,  0
    .db 30, 10, 10
    .db 25, 25, 25
    .db  0,  0,  5
    .db 10,  5,  0
    .db 25, 15,  0
    .db 20, 20, 20
    .db  0,  0,  5
    .db 10,  5,  0
    .db 25, 15,  0
    .db 15, 15, 15
    .db  0,  0,  5
    .db 10,  5,  0
    .db 20, 20, 20
    .db 15, 15, 15
.ENDS

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Map data
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 1 SLOT SLOT_ROM_BANKED
.SECTION "msg_screen_data" SEMIFREE
; gameover
msg_map_gameover:
.INCBIN "gfx/msg_defeat_map.bin"
; victory
msg_map_victory:
.INCBIN "gfx/msg_victory_map.bin"
; elevator
msg_map_elevator:
.INCBIN "gfx/msg_floordone_map.bin"
; cheat menu
msg_map_cheat:
.INCBIN "gfx/msg_cheat_map.bin"
; password
msg_map_password:
.INCBIN "gfx/msg_password_map.bin"
; chr data
msg_chr:
.INCBIN "gfx/msg_chr.bin"
.ENDS



