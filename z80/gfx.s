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



;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; gfx_init              :
; gfx_oam_update        :
; gfx_chr_copy     	    : HL=dest, DE=source, C=num tiles
; gfx_map_copy_20x18    : HL=dest, DE=source
; gfx_map_clear    	    :  
; gfx_pal_copy_bg  	    : HL=source, B=dst index, C=count
; gfx_pal_copy_obj 	    : HL=source, B=dst index, C=count
; gfx_pal_clear         :
; gfx_pal_fade_bg       ; HL=source, DE=dst, B=dst index, C=count, A=val (1.7 fixed point)
; gfx_pal_fade_obj      ; HL=source, DE=dst, B=dst index, C=count, A=val (1.7 fixed point)
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.INCLUDE "defines.i"


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; constants
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.EQU gfx_oam_copy   $FF80

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Variables
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.RAMSECTION "lib_gfx_vars" BANK 0 SLOT SLOT_RAM
temp_pal_dh     DB
temp_pal_dl     DB
temp_pal_data   DS 3*4*8
.ENDS

.STRUCT oam_entry
ypos    DB
xpos    DB
tile    DB
flag    DB
.ENDST

.RAMSECTION "lib_gfx_oam", BANK 0 SLOT SLOT_RAM_OAM
oam             DS 4*40
.ENDS


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Code
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 0 SLOT SLOT_ROM
.SECTION "lib_gfx" SEMIFREE


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; oam dma
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
_gfx_oam_copy_start:
    ld      a, oam / $100
    ldh     (R_DMA), a
    ld      a, $28
-   dec     a
    jr      nz, -
    ret
_gfx_oam_copy_end:


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; init gfx lib
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_init:
    ; clear oam
    ld      hl, oam
    ld      b, 4*40
    xor     a
-   ldi     (hl), a
    dec     b
    jr      nz, -
    ; copy oam routine to hram
    ld      hl, _gfx_oam_copy_start
    ld      bc, _gfx_oam_copy_end - _gfx_oam_copy_start
    ld      de, gfx_oam_copy
-   ldi     a, (hl)
    ld      (de), a
    inc     de
    dec     bc
    ld      a, b
    or      c
    jr      nz, -
    ret


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; update sprite oam
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_oam_update:
    jp  gfx_oam_copy    


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; copy tiles to vram (dmg compatible)
; HL = destination
; DE = source
; C  = number of tiles
; destroys: A, BC, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_chr_copy:
--  ld      b, 16
-   ldh     a, (R_STAT)     ; wait vram
    and     $02
    jr      nz, -
    ld      a, (de)         ; copy byte
    inc     de
    ldi     (hl), a
    dec     b               ; loop tile
    jr      nz, -
    dec     c               ; loop count
    jr      nz, --
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; clear chr at 9800 & 9C00
; destroys: A, BC, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_chr_clear:
    ld      hl, sp+0        ; bank0
    ld      sp, $9800
    ld      de, $0000
    ld      bc, 768
    xor     a
    ldh     (R_VBK), a
--  di
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    push    de
    push    de
    push    de
    push    de
    ei
    dec     c
    jr      nz, --
    dec     b
    jr      nz, --
    ld      sp, $9800
    ld      de, $0000
    ld      bc, 768
    ld      a, 1
    ldh     (R_VBK), a
--  di
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    push    de
    push    de
    push    de
    push    de
    ei
    dec     c
    jr      nz, --
    dec     b
    jr      nz, --
    xor     a               ; done
    ldh     (R_VBK), a
    ld      sp, hl
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; copy 20x18 map+attr to vram (dmg compatible)
; HL = destination
; DE = source
; destroys: A, BC, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_map_copy_20x18:
    ; tile numbers
    push    hl
    ld      b, 18
--  ld      c, 20
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     c
    jr      nz, -
    push    bc
    ld      bc, 12
    add     hl, bc
    pop     bc
    dec     b
    jr      nz, --
    ; attributes
    pop     hl
    ld      a, (g_console_type)
    or      a
    ret     z
    ld      a, 1
    ldh     (R_VBK), a
    ld      b, 18
--  ld      c, 20
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (de)
    ldi     (hl), a
    inc     de
    dec     c
    jr      nz, -
    push    bc
    ld      bc, 12
    add     hl, bc
    pop     bc
    dec     b
    jr      nz, --
    xor     a
    ldh     (R_VBK), a
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; clear maps at 9800 & 9C00
; destroys: A, BC, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_map_clear:
    ld      hl, sp+0
    ld      sp, $9800+2048
    ld      de, $0000
    ld      bc, 2048/8
--  di
-   ldh     a, (R_STAT)     ; wait vram
    and     $02
    jr      nz, -
    push    de              ; clear 8 bytes
    push    de
    push    de
    push    de
    ei
    dec     c               ; loop
    jr      nz, --
    dec     b
    jr      nz, --
    ld      sp, hl
    ret


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; copy bg palette to vram
; HL = source
; B = dst index
; C = count
; destroys: A, BC, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_pal_copy_bg:
    ld      a, b
    sla     a
    sla     a
    sla     a
    or      %10000000
--- ldh     (R_BCPS), a
    push    af
    ld      b, 4
--  ldi     a, (hl)
    ld      e, a
    ldi     a, (hl)
    ld      d, a
    rrc     a
    rrc     a
    rrc     a
    and     %11100000
    or      e
    ld      e, a
    srl     d
    srl     d
    srl     d
    ldi     a, (hl)
    sla     a
    sla     a
    or      d
    ld      d, a
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, e
    ldh     (R_BCPD), a
    ld      a, d
    ldh     (R_BCPD), a
    dec     b
    jr      nz, --
    pop     af
    add     8
    dec     c
    jr      nz, ---
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; copy obj palette to vram
; HL = source
; B = dst index
; C = count
; destroys: A, B, C, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_pal_copy_obj:
    ld      a, b
    sla     a
    sla     a
    sla     a
    or      %10000000
--- ldh     (R_OCPS), a
    push    af
    ld      b, 4
--  ldi     a, (hl)
    ld      e, a
    ldi     a, (hl)
    ld      d, a
    rrc     a
    rrc     a
    rrc     a
    and     %11100000
    or      e
    ld      e, a
    srl     d
    srl     d
    srl     d
    ldi     a, (hl)
    sla     a
    sla     a
    or      d
    ld      d, a
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, e
    ldh     (R_OCPD), a
    ld      a, d
    ldh     (R_OCPD), a
    dec     b
    jr      nz, --
    pop     af
    add     8
    dec     c
    jr      nz, ---
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; clear bg + obj palette
; destroys: A, B, C, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_pal_clear:
    ; bg pal
    ld      c, 8
    ld      a, %10000000
--  ldh     (R_BCPS), a
    push    af
    ld      b, 4
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, %11111111
    ldh     (R_BCPD), a
    ldh     (R_BCPD), a
    dec     b
    jr      nz, -
    pop     af
    add     8
    dec     c
    jr      nz, --
    ; obj pal
    ld      c, 8
    ld      a, %10000000
--  ldh     (R_OCPS), a
    push    af
    ld      b, 4
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, %11111111
    ldh     (R_OCPD), a
    ldh     (R_OCPD), a
    dec     b
    jr      nz, -
    pop     af
    add     8
    dec     c
    jr      nz, --
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; fade palette
; HL=src, DE=dst, B=dst index, C=count, A=val (0:s, 128:d)
; destroys: A, B, C, DE, HL
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
gfx_pal_fade_bg:
    cp      0
    jp      z, gfx_pal_copy_bg
    cp      128
    jr      nz, +
    ld      l, e
    ld      h, d
    jp      gfx_pal_copy_bg
+   call    _gfx_pal_fade
    jp      gfx_pal_copy_bg

gfx_pal_fade_obj:
    cp      0
    jp      z, gfx_pal_copy_obj
    cp      128
    jr      nz, +
    ld      l, e
    ld      h, d
    jp      gfx_pal_copy_obj
+   call    _gfx_pal_fade
    jp      gfx_pal_copy_obj

_gfx_pal_fade:
    push    bc
    push    af
    sla     c
    sla     c
    ld      a, c
    sla     c
    add     c
    ld      c, a            ; c = number of bytes (count * 12)
    
    push    hl
    ld      hl, temp_pal_data
    ld      a, l
    ld      (temp_pal_dl), a
    ld      a, h
    ld      (temp_pal_dh), a
    pop     hl

    pop     af
    ld      b, a            ; b = val
-   push    bc
    ld      a, (de)
    inc     de
    ld      c, (hl)
    cp      c
    jr      c, ++

    ; fade up
    sub     c
    ld      c, a
    sla     c               ; c = abs(dst - src) << 1            
    push    de
    push    hl
    call    sys_mul_8x8     ; d = color
    ld      a, d
    pop     hl
    add     (hl)
    cp      32
    jr      c, +
    ld      a, 31
+   ld      b, a            ; b = src + (((dst - src) * (val<<1)) >> 8)
    jr      +++

    ; fade down
++  ld      c, a
    ld      a, (hl)
    sub     c
    ld      c, a            ; c = abs(dst-src)
    sla     c
    push    de
    push    hl
    call    sys_mul_8x8     ; d = color
    pop     hl
    ld      a, (hl)
    sub     d
    cp      32
    jr      c, +
    ld      a, 0
+   ld      b, a            ; b = src - (((dst - src) * (val<<1)) >> 8)

    ; save to temp
+++ inc     hl
    push    hl

    ld      a, (temp_pal_dl)
    ld      l, a
    ld      a, (temp_pal_dh)
    ld      h, a
    ld      a, b
    ld      (hl), a
    inc     hl
    ld      a, l
    ld      (temp_pal_dl), a
    ld      a, h
    ld      (temp_pal_dh), a

    ; loop
    pop     hl
    pop     de
    pop     bc
    dec     c
    jr      nz, -

    ; return hl = temp_palette
    pop     bc
    ld      hl, temp_pal_data
    ret


.ENDS



;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Data
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 0 SLOT 0
.SECTION "lib_gfx_data" SEMIFREE

PAL_WHITE:
.REPT 4*8
.db 31, 31, 31
.db 31, 31, 31
.db 31, 31, 31
.ENDR
PAL_BLACK:
.REPT 4*8
.db 0, 0, 0
.db 0, 0, 0
.db 0, 0, 0
.ENDR
PAL_RED:
.REPT 4*8
.db 31, 0, 0
.db 31, 0, 0
.db 31, 0, 0
.ENDR

.ENDS



