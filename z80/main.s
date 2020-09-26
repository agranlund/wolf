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

.include "defines.i"

.BANK 0 SLOT SLOT_ROM

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Main entry point
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.ORG $150
.SECTION "Main" SEMIFREE
MAIN:
    ; compatability check
    ld      a, (g_console_type)
    or      a
    jp      z, display_compatability_error

    ; setup
    call    gfx_init
    call    snd_init

    ; clear palette, map & chr
    call    gfx_pal_clear
    call    gfx_map_clear
    call    gfx_chr_clear

    ; no password
    xor     a
    ld      (pwd_start), a

    ; no cheats
    xor     a
    ld      (cheat_godmode), a
    ld      (cheat_guns), a
    ld      a, 1
    ld      (start_floor), a

    ; hold start to skip directly into game
    ;call    sys_update_joypad
    ;ld      a, (g_joypad_status)
    ;bit     3, a
    ;jr      nz, +

    ;jr +

    ; intro
    call    intro

    ; main menu
-   call    title

    ; game
+   call    game
    jr      -


display_compatability_error:
    ld      a, :gbc_only_tile_data
    ld      ($2000), a
    ld      hl, $8000
    ld      de, gbc_only_tile_data
    ld      c, 127
    call    gfx_chr_copy        ; copy chr
    ld      hl, $9800
    ld      de, gbc_only_map_data
    call    gfx_map_copy_20x18  ; copy map
    ld      a, %11100100        ; copy palette
    ldh     (R_BGP), a
    ld      a, %10010001        ; enable bg
    ldh     (R_LCDC), a
-   halt
    jr -
.ENDS


; Data for compatability warning
.BANK 3 SLOT SLOT_ROM_BANKED
.SECTION "gbc_only_data" SEMIFREE
.INCLUDE "gfx/gbc_only.s"
.ENDS





