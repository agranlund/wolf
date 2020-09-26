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


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; constants
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.DEFINE WOLF_FRAMEBUFFER        $A000
.DEFINE WOLF_BGMAPBUFFER        $B000
.DEFINE WOLF_CMDBUFFER_WR       $B400
.DEFINE WOLF_CMDBUFFER_RD       $B800
.DEFINE WOLF_Y_OFFSET           1
.DEFINE WOLF_MAP_OFFSET         (WOLF_Y_OFFSET * 32)
.DEFINE WOLF_NUMTILES_X         20
.DEFINE WOLF_NUMTILES_Y         12
.DEFINE WOLF_LAST_Y_LINE        (((WOLF_Y_OFFSET + WOLF_NUMTILES_Y) * 8) - 1)
.DEFINE WOLF_NUMTILES           (WOLF_NUMTILES_X * WOLF_NUMTILES_Y)
.DEFINE WOLF_VRAM               $8800
.DEFINE WOLF_DMA_COUNT1         112
.DEFINE WOLF_DMA_COUNT2         128
.DEFINE WOLF_TRIGGER_REG        $4000

.DEFINE HUD_DIRTY_LIVES         %10000000
.DEFINE HUD_DIRTY_FLOOR         %01000000
.DEFINE HUD_DIRTY_HEALTH        %00100000
.DEFINE HUD_DIRTY_KEYS          %00010000
.DEFINE HUD_DIRTY_WEAPON        %00001000
.DEFINE HUD_DIRTY_AMMO          %00000100
.DEFINE HUD_DIRTY_HANDS         %00000010

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; variables
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.RAMSECTION "vars" BANK 0 SLOT SLOT_RAM
backbuffer          DB
wolf_lcdc           DB
hud_map_addr        DS 1

tempbuf             DS 16

keys                DS 1
health              DS 1
lives               DS 1
floor               DS 1
ammo                DS 1
guns                DS 1
weapon              DS 1
weapon_frame        DS 1
hud_dirty           DS 1

fade_cnt            DS 1
fade_type           DS 1    ; 1=dmg, 2=in_black, 3=in_red

death_trigger       DS 1
gameover_trigger    DS 1
victory_trigger     DS 1
floordone_trigger   DS 1
floordone_next      DS 1

stat_kill_ratio     DS 1
stat_secret_ratio   DS 1
stat_bonus_ratio    DS 1
stat_score          DS 2

cheat_godmode       DS 1
cheat_guns          DS 1
start_floor         DS 1

pwd_start           DS 1
paused              DS 1
dbg_music           DS 1
.ENDS


.BANK 0 SLOT SLOT_ROM

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; LCD Interrupt
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.org $48
    jp  irq_lcd


.ORG $150
.SECTION "Game" SEMIFREE

irq_lcd:
    di
    push    af
    ldh     a, (R_LY)
    cp      WOLF_LAST_Y_LINE
    jr      nz, +
    ; lcdc interrupt at start of lower hud
    ld      a, (wolf_lcdc)
    or      %00011010
    ldh     (R_LCDC), a     ; select chr data from $8000, enable sprites
+   pop     af
    ei
    reti


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Main loop
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»

game_setup_tiles:
    ; clear all palettes to black
    ld      hl, PAL_BLACK
    ld      bc, 8
    call    gfx_pal_copy_bg
    ld      hl, PAL_BLACK
    ld      bc, 8
    call    gfx_pal_copy_obj

    ; load general sprite chr
    ld      a, 1
    ldh     (R_VBK), a
    ld      a, :HUD_OBJ_CHR
    ld      ($2000), a
    ld      hl, $8000 + (112 * 16)
    ld      de, HUD_OBJ_CHR
    ld      c, 16
    call    gfx_chr_copy
    xor     a
    ldh     (R_VBK), a

    ; load upper hud chr
    ld      hl, $9700
    ld      de, HUD_BG_CHR + (16 * 112)
    ld      c, 16
    call    gfx_chr_copy

    ; load lower hud chr to $8000
    ld      hl, $8000
    ld      de, HUD_BG_CHR
    ld      c, 128
    call    gfx_chr_copy

    ; load upper+lower hud map
    ld      hl, $9800
    ld      de, HUD_BG_MAP
    call    gfx_map_copy_20x18
    ld      hl, $9C00
    ld      de, HUD_BG_MAP
    call    gfx_map_copy_20x18

    ; setup maps for double buffering the wolf graphics
    ; $9800 references tiles from vram bank 0, $8800
    ; $9C00 references tiles from vram bank 1, $8800
    call    wolf_init_map    
    ret

game_setup_interrupts:
    xor     a
    ldh     (R_IF), a
    ld      a, WOLF_LAST_Y_LINE ; interrupt at last line of wolf gfx
    ldh     (R_LYC), a
    ld      a, %00001000        ; hblank interrupt
    ldh     (R_STAT), a
    ld      a, %00000010        ; lcd interrupt
    ldh     (R_IE), a
    call    sys_wait_vbl
    ei    
    ret

game_start_music:
    ld      a, (floor)
    ld      e, a
    ld      d, 0
    ld      hl, game_music_table
    add     hl, de
    ld      a, (hl)
    call    snd_play_music
    ret

game_music_table:
.db 5, 1, 2, 3, 4, 1, 2, 3, 4, 5


game:
game_main:

    ; init variables
    ld      a, (pwd_start)
    cp      0
    jr      z, +
    ; continue
    ld      a, (tempbuf+0)
    call    hud_set_lives
    ld      a, (tempbuf+1)
    call    hud_set_floor
    ld      a, (tempbuf+2)
    call    hud_set_health
    ld      a, (tempbuf+3)
    call    hud_set_guns
    ld      a, (tempbuf+4)
    call    hud_set_ammo
    jr      ++
    ; new game
+   ld      a, 3
    call    hud_set_lives
    ld      a, (start_floor)
    call    hud_set_floor
    ld      a, 100
    call    hud_set_health
    ld      a, 1
    call    hud_set_guns
    ld      a, 8
    call    hud_set_ammo
++  ld      a, 1
    ld      (backbuffer), a
    ld      a, 0
    call    hud_set_keys
    ld      a, 1
    call    hud_set_weapon
    ld      a, 2
    ld      (weapon_frame), a
    ld      a, $FF
    ld      (hud_dirty), a
    xor     a
    ld      (stat_kill_ratio), a
    ld      (stat_bonus_ratio), a
    ld      (stat_secret_ratio), a
    ld      (stat_score), a
    ld      (stat_score+1), a
    ld      a, $1
    ld      (dbg_music), a
    xor     a
    ld      (paused), a

    xor     a
    ld      (death_trigger), a
    ld      (gameover_trigger), a
    ld      (victory_trigger), a
    ld      (floordone_trigger), a
    ld      (floordone_next), a

    ld      a, 0
    ld      (fade_cnt), a
    ld      a, 2
    ld      (fade_type), a


    ; clear sram
    ld      a, $0A
    ld      ($0000), a
    ld      bc, $2000
    ld      hl, $A000
    xor     a
-   ldi     (hl), a
    dec     c
    jr      nz, -
    dec     b
    jr      nz, -
    ld      ($0000), a

    call    game_setup_tiles

    ; setup display parameters
    LD      a, %10000011
    ldh     (R_LCDC), a     ; screen on
                            ; window map $9800-$9BFF
                            ; window off
                            ; bg chr data $8800-97FF
                            ; bg map data $9800-9BFF
                            ; obj size 8x8
                            ; obj off
                            ; bg on

    ld      (wolf_lcdc), a

    ; cpu speed
    call    sys_cpu_2mhz

    ; init wolf chip
    call    wolf_init

    ; start game
    ld      a, $0A                  ; enable sram
    ld      ($0000), a
    ld      hl, WOLF_CMDBUFFER_WR

    ld      a, (cheat_godmode)
    sla     a
    sla     a
    ld      b, a
    ld      a, (cheat_guns)
    sla     a
    ld      c, a
    ld      a, 1
    or      b                       ; cheat_guns
    or      c                       ; cheat_godmode
    ldi     (hl), a
    ld      a, (lives)
    ldi     (hl), a
    ld      a, (floor)
    ldi     (hl), a
    ld      a, (health)
    ldi     (hl), a
    ld      a, (guns)
    ldi     (hl), a
    ld      a, (ammo)
    ldi     (hl), a
    ld      a, (backbuffer)
    ldi     (hl), a
    ld      a, 0
    ldi     (hl), a
    ld      hl, WOLF_CMDBUFFER_RD   ; clear rd buffer
    xor     a
    ldi     (hl), a
    ld      (hl), a
    ld      ($0000), a
    call    wolf_trigger            ; trigger wolf
    ld      bc, 2
    call    sys_delay               ; wait for result
    call    wolf_get_result         ; handle reponse from wolf
    ld      a, $FF                  ; update hud
    ld      (hud_dirty), a
    call    hud_update

    call    game_setup_interrupts

    call    game_start_music

_main_loop:

    ; gameover
    ld      a, (gameover_trigger)
    cp      0
    jr      z, +
    xor     a
    ld      (fade_cnt), a
    ld      (gameover_trigger), a
    call    snd_stop_music
    call    hud_fade_gameover
    jp      gameover
    ; death
+   ld      a, (death_trigger)
    cp      0
    jr      z, +
    xor     a
    ld      (fade_cnt), a
    ld      (death_trigger), a
    call    snd_stop_music
    call    hud_fade_death
    ; victory
+   ld      a, (victory_trigger)
    cp      0
    jr      z, +
    xor     a
    ld      (fade_cnt), a
    ld      (victory_trigger), a
    call    snd_stop_music
    call    hud_fade_victory
    jp      victory
    ; floor complete
+   ld      a, (floordone_trigger)
    cp      0
    jr      z, +
    xor     a
    ld      (fade_cnt), a
    ld      (floordone_trigger), a
    call    snd_stop_music
    call    hud_fade_floordone
    call    elevator
    call    game_setup_tiles
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a 
    call    game_setup_interrupts
    ld      a, 2
    ld      (fade_type), a
+

    ;--------------------------------------
    ; frame 0
    ;--------------------------------------

    ; update joypad
    call    sys_update_joypad

    ; --- debug ---
    jr      +++
    ld      a, (g_joypad_trigger)
    bit     2, a
    jr      z, ++
    ld      a, (dbg_music)
    inc     a
    cp      6
    jr      c, +
    xor     a
+   ld      (dbg_music), a
    call    snd_play_music
++  ld      a, (g_joypad_trigger)
    bit     0, a
    jr      z, +
    ld      a, $1
    call    snd_play_fx
+   ld      a, (g_joypad_trigger)
    bit     1, a
    jr      z, +++
    ld      a, $10
    call    snd_play_fx
+++

    ; pause
    ld      a, (g_joypad_trigger)
    bit     3, a
    call    nz, pause

    ; send command buffer
    ld      a, $0A                  ; enable sram
    ld      ($0000), a
    ld      hl, WOLF_CMDBUFFER_WR
    ld      a, 0                    ; WOLF_CMDBUFFER + 0 : init game
    ldi     (hl), a
    ld      a, (backbuffer)         ; WOLF_CMDBUFFER + 1 : backbuffer index
    ldi     (hl), a
    ld      a, (g_joypad_status)    ; WOLF_CMDBUFFER + 2 : joypad status
    ldi     (hl), a
    ; prepare read buffer
    ld      hl, WOLF_CMDBUFFER_RD
    xor     a
    ldi     (hl), a
    ld      (hl), a
    ; disable sram
    ld      ($0000), a

    ; wake the wolf
    call    wolf_trigger

    ; update sound
    call    snd_update

    ; update fade
    call    hud_update_fade1

    ; update hud
    call    hud_update

    call    sys_wait_vbl

    ;--------------------------------------
    ; vblank1
    ;--------------------------------------
    di
    ; restore wolf tile numbering
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    ; set backbuffer vram bank
    ld      de, backbuffer
    ld      a, (de)
    ld      b, a
    ldh     (R_VBK), a
    ; enable sram
    ld      a, $0A
    ld      ($0000), a
    ; dma bg tiles 0-111 = ~965us
    ld      hl, WOLF_FRAMEBUFFER
    ld      a, h
    ldh     (R_HDMA1), a
    ld      a, l
    and     %11111000
    ldh     (R_HDMA2), a
    ld      hl, WOLF_VRAM - $8000
    ld      a, h
    and     %00011111
    ldh     (R_HDMA3), a
    ld      a, l
    ldh     (R_HDMA4), a
    ld      a, WOLF_DMA_COUNT1-1
    ldh     (R_HDMA5), a
    ; disable sram
    xor     a
    ld      ($0000), a

    ; dma oam attributes = ~200us
    call    gfx_oam_update


    ;--------------------------------------
    ; frame1 
    ;--------------------------------------
    ; vram bank 1 (map attributes)
    ld      a, 1
    ldh     (R_VBK), a
    ; enable sram
    ld      a, $0A
    ld      ($0000), a
    ; dma map attributes: ~24 scanlines (32*12 = 384 bytes)
    ld      hl, WOLF_BGMAPBUFFER
    ld      a, h
    ldh     (R_HDMA1), a
    ld      a, l
    and     %11111000
    ldh     (R_HDMA2), a
    ld      hl, $9800 + WOLF_MAP_OFFSET
    ld      a, (de)
    or      a
    jr      z, +
    ld      hl, $9C00 + WOLF_MAP_OFFSET
+   ld      a, h
    and     %00011111
    ldh     (R_HDMA3), a
    ld      a, l
    ldh     (R_HDMA4), a
    ld      a, $97          ; bit7=1, bit0:6 = 23 ((32*12) / 16) - 1
    ldh     (R_HDMA5), a
    ; wait for dma completion
-   ldh     a, (R_HDMA5)
    and     %10000000
    jr      z, -
    ; disable sram
    xor     a
    ld      ($0000), a
    ; restore vram bank
    xor     a
    ldh     (R_VBK), a
    ei

    ; update sound
    call    snd_update

    ; update fade
    call    hud_update_fade2

    ; read wolf result
    call    wolf_get_result

    call    sys_wait_vbl

    ;--------------------------------------
    ; vblank2
    ;--------------------------------------
    di
    ; restore wolf tile numbering
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    ; set backbuffer vram bank
    ld      de, backbuffer
    ld      a, (de)
    ld      b, a
    ldh     (R_VBK), a
    ; enable sram
    ld      a, $0A
    ld      ($0000), a
    ; dma bg tiles 112-239 = ~1087us
    ld      hl, WOLF_FRAMEBUFFER + (WOLF_DMA_COUNT1 * 16)
    ld      a, h
    ldh     (R_HDMA1), a
    ld      a, l
    and     %11111000
    ldh     (R_HDMA2), a
    ld      hl, WOLF_VRAM - $8000 + (WOLF_DMA_COUNT1 * 16)
    ld      a, h
    and     %00011111
    ldh     (R_HDMA3), a
    ld      a, l
    ldh     (R_HDMA4), a
    ld      a, WOLF_DMA_COUNT2-1
    ldh     (R_HDMA5), a
    ; disable sram
    xor     a
    ld      ($0000), a
    ; restore vram bank
    xor     a
    ldh     (R_VBK), a
    ; swap front and back buffers
    ld      a, b
    inc     a
    and     %00000001
    ld      (de),a
    ld      hl, wolf_lcdc
    ld      a, (hl)
    and     %11110111
    sla     b
    sla     b
    sla     b
    or      b
    ldh     (R_LCDC), a
    ld      (hl), a
    ei
	jp     _main_loop


; pause
pause:
    xor     a
    ld      [NR51], a
    ld      hl, HUD_PAUSE_PAL
    ld      bc, 6
    call    gfx_pal_copy_bg
    ld      hl, HUD_PAUSE_PAL
    ld      bc, 4
    call    gfx_pal_copy_obj    
    ld      a, 1
    ld      (paused), a
    xor     a
    ld      (tempbuf+0), a
    ld      a, 1
    ld      (tempbuf+1), a
-   call    sys_update_joypad
    ld      a, (g_joypad_trigger)
    bit     3, a
    jr      z, +
    xor     a
    ld      (paused), a
    ld      (tempbuf+0), a
    ld      (tempbuf+1), a
+   ld      a, (tempbuf+0)
    inc     a
    cp      60
    jr      c, +
    ld      hl, tempbuf+1
    inc     (hl)
    xor     a
+   ld      (tempbuf+0), a
    ld      de, 4
    ld      a, (tempbuf+1)
    and     1
    cp      0
    jr      z, +
    ld      a, 64
+   ld      hl, oam + (30 * 4) + 0
.REPT 6
    ld      (hl), a
    add     hl, de
.ENDR
    ld      hl, oam + (30 * 4) + 1
    ld      a, 64
.REPT 6
    ld      (hl), a
    add     hl, de
    add     8
.ENDR
    ld      hl, oam + (30 * 4) + 2
    ld      a, 115
.REPT 6
    ld      (hl), a
    inc     a
    add     hl, de
.ENDR
    ld      hl, oam + (30 * 4) + 3
    ld      a, %00001111
.REPT 6
    ld      (hl), a
    add     hl, de
.ENDR
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    gfx_oam_update
    ld      a, (paused)
    or      a
    jp      nz, -
    ; restore palette
    ld      hl, HUD_BG_PAL
    ld      bc, 8
    call    gfx_pal_copy_bg
    ld      hl, HUD_OBJ_PAL
    ld      bc, 8
    call    gfx_pal_copy_obj
    ret


; set weapon. A = weapon index
hud_set_weapon:
    and     3
    ld      (weapon), a
    ld      a, (hud_dirty)
    or      HUD_DIRTY_WEAPON | HUD_DIRTY_AMMO | HUD_DIRTY_HANDS
    ld      (hud_dirty), a
    ret

; set weapon frame. A = frame index
hud_set_weapon_frame:
    ld      (weapon_frame), a
    ld      a, (hud_dirty)
    or      HUD_DIRTY_HANDS
    ld      (hud_dirty), a
    ret

; set keys. A = key bitfield
hud_set_keys:
    and     $3
    ld      (keys), a
    ld      a, (hud_dirty)
    or      HUD_DIRTY_KEYS
    ld      (hud_dirty), a
    ret

; a = weapon index, de = ammo count
hud_set_ammo:
    cp      99
    jr      c, +
    ld      a, 99
+   ld      (ammo), a
    ld      a, (hud_dirty)
    or      HUD_DIRTY_AMMO
    ld      (hud_dirty), a
    ret

; a = gun mask (1=gun, 2=machinegun, 4=minigun)
hud_set_guns:
    ld      (guns), a
    ret

; a = health
hud_set_health:
    cp      100
    jr      c, +
    ld      a, 100
+   ld      (health), a
    ld      a, (hud_dirty)
    or      HUD_DIRTY_HEALTH
    ld      (hud_dirty), a
    ret

; a = lives
hud_set_lives:
    cp      9
    jr      c, +
    ld      a, 9
+   ld      (lives), a
    ld      a, (hud_dirty)
    or      HUD_DIRTY_LIVES
    ld      (hud_dirty), a
    ret

; a = floor
hud_set_floor:
    cp      9
    jr      c, +
    ld      a, 9
+   ld      (floor), a
    ld      a, (hud_dirty)
    or      HUD_DIRTY_FLOOR
    ld      (hud_dirty), a
    call    game_start_music
    ret

hud_update:
    ld      a, (hud_dirty)
    cp      0
    ret     z
    and     HUD_DIRTY_LIVES
    call    nz, hud_update_lives
    ld      a, (hud_dirty)
    and     HUD_DIRTY_FLOOR
    call    nz, hud_update_floor
    ld      a, (hud_dirty)
    and     HUD_DIRTY_HEALTH
    call    nz, hud_update_health
    ld      a, (hud_dirty)
    and     HUD_DIRTY_KEYS
    call    nz, hud_update_keys
    ld      a, (hud_dirty)
    and     HUD_DIRTY_WEAPON
    call    nz, hud_update_weapon
    ld      a, (hud_dirty)
    and     HUD_DIRTY_AMMO
    call    nz, hud_update_ammo
    ld      a, (hud_dirty)
    and     HUD_DIRTY_HANDS
    call    nz, hud_update_hands

    xor     a
    ld      (hud_dirty), a
    ret



hud_update_hands:
    ld      a, (weapon)
    sla     a
    sla     a
    sla     a
    ld      e, a
    ld      a, (weapon_frame)
    sla     a
    add     e
    ld      e, a
    ld      d, 0
    ld      hl, WPN_FRAME_TABLE
    add     hl, de
    ldi     a, (hl)
    ld      h, (hl)
    ld      l, a        ; hl = weapon tiles
    ldi     a, (hl)
    ld      c, a        ; c = num oam entries
    ; hide unused sprites
    ld      a, 32
    sub     c
    ld      b, a
    xor     a
    ld      de, oam + (31 * 4)
-   ld      (de), a
    dec     de
    dec     de
    dec     de
    dec     de
    dec     b
    jr      nz, -
    ; assign used sprites
    ld      de, oam
-   ldi     a, (hl)     ; ypos
    ld      (de), a
    inc     de
    ldi     a, (hl)     ; xpos
    ld      (de), a
    inc     de
    ldi     a, (hl)     ; tile
    ld      (de), a
    inc     de
    ldi     a, (hl)     ; attr
    ld      (de), a
    inc     de
    dec     c
    jr      nz, -
    ret

hud_update_lives:
    ld      a, (hud_dirty)
    and     HUD_DIRTY_LIVES
    ret     z
    ld      hl, $9800 + 2
    ld      de, $9C00 - $9800
    ld      a, (lives)
    add     115
    ld      b, a
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, b
    ld      (hl), a
    add     hl, de
    ld      (hl), a
    ret

hud_update_floor:
    ld      hl, $9800 + 18
    ld      de, $9C00 - $9800
    ld      a, (floor)
    add     115
    ld      b, a
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, b
    ld      (hl), a
    add     hl, de
    ld      (hl), a
    ret

hud_update_health:
    ld      a, (health)
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
    ld      hl, $9C00 + 5 + (15 * 32)
    ld      b, 0
    ld      c, 3
--  ld      a, (de)
    or      b
    jr      nz, +
    ld      a, 14           ; bank tile = 14+15
    jr      ++
+   ld      a, (de)
    ld      b, $FF
    sla     a
    add     32              ; tile = 32 + (digit * 2)
++  push    hl
    push    de
    push    af
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    pop     af
    ld      (hl), a
    ld      de, 32
    add     hl, de
    inc     a
    ld      (hl), a
    pop     de
    pop     hl
    inc     de
    inc     hl
    dec     c
    jr      nz, --
    ret

hud_update_weapon:
    ; reset animation
    xor     a
    ld      (weapon_frame), a
    ; temporarily disable sprites
    ld      a, (wolf_lcdc)
    and     %11111101
    ldh     (R_LCDC), a
    ; copy weapons graphics to vram
+   ld      a, (weapon)
    sla     a
    sla     a
    ld      c, a
    ld      b, 0
    ld      hl, WPN_CHR_TABLE
    add     hl, bc
    ldi     a, (hl)         ; src addr_l
    ldh     (R_HDMA2), a
    ldi     a, (hl)         ; src_addr_h
    ldh     (R_HDMA1), a
    ldi     a, (hl)         ; bank
    ld      ($2000), a
    ld      c, (hl)         ; c = tile count
    ld      a, 1
    ldh     (R_VBK), a      ; vram bank 1
    ld      hl, $8000
    ld      a, h
    and     %00011111
    ldh     (R_HDMA3), a    ; dst addr_h
    ld      a, l
    ldh     (R_HDMA4), a    ; dst_addr_l
    ld      a, %10000000
    dec     c
    or      c
    ldh     (R_HDMA5), a    ; start dma
-   ldh     a, (R_HDMA5)    ; wait for dma completion
    and     %10000000
    jr      z, -
    xor     a
    ldh     (R_VBK), a      ; vram bank 0
    ret

hud_update_ammo:
    ld      a, (weapon)
    or      a
    jr      nz, +
    ld      de, 0
    jr      ++
+   ld      hl, ammo
    ld      e, (hl)
    ld      d, 0
++  ld      bc, 10
    call    sys_div_16x16   ; de = ammo/10, bc = ammo%10
    ld      hl, tempbuf
    ld      a, e
    ldi     (hl), a
    ld      a, c
    ldd     (hl), a
    ld      de, $9C00 + 13 + (16 * 32)
    ld      b, 0
    ld      c, 2
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, (hl)
    or      b
    jr      nz, +
    ld      a, 9
    jr      ++
+   ld      a, (hl)
    ld      b, $FF
    add     16
++  ld      (de), a
    inc     de
    inc     hl
    dec     c
    jr      nz, -
    ret

hud_update_keys:
    ; hide keys
    xor     a
    ld      (oam + (36*4)), a
    ld      (oam + (37*4)), a
    ld      (oam + (38*4)), a
    ld      (oam + (39*4)), a
    ; gold key
    ld      a, (keys)
    ld      b, a
    bit     0, b
    jr      z, +
    ld      hl, oam + (36*4)
    ld      a, 136
    ldi     (hl), a
    ld      a, 88
    ldi     (hl), a
    ld      a, 112+1
    ldi     (hl), a
    ld      a, %00001101
    ldi     (hl), a
    ld      a, 144
    ldi     (hl), a
    ld      a, 88
    ldi     (hl), a
    ld      a, 112+2
    ldi     (hl), a
    ld      a, %00001101
    ldi     (hl), a        
    ; silver key
+   bit     1, b
    ret     z
    ld      hl, oam + (38*4)
    ld      a, 136
    ldi     (hl), a
    ld      a, 96
    ldi     (hl), a
    ld      a, 112+1
    ldi     (hl), a
    ld      a, %00001100
    ldi     (hl), a
    ld      a, 144
    ldi     (hl), a
    ld      a, 96
    ldi     (hl), a
    ld      a, 112+2
    ldi     (hl), a
    ld      a, %00001100
    ldi     (hl), a
    ret


hud_update_fade1:
    ld      a, (fade_type)
    cp      2
    jr      z, hud_update_fadein_black1
    cp      3
    jr      z, hud_update_fadein_red1
    ret

hud_update_fade2:
    ld      a, (fade_type)
    cp      1
    jr      z, hud_update_fade_dmg
    cp      2
    jr      z, hud_update_fadein_black2    
    cp      3
    jr      z, hud_update_fadein_red2    
    ret

hud_update_fadein_black1:
    ld      a, (fade_cnt)
-   push    af
    ld      hl, PAL_BLACK
    ld      de, HUD_OBJ_PAL
    ld      bc, 8
    call    gfx_pal_fade_obj
    pop     af
    ret

hud_update_fadein_black2:
    ld      a, (fade_cnt)
-   push    af
    ld      hl, PAL_BLACK
    ld      de, HUD_BG_PAL
    ld      bc, 8
    call    gfx_pal_fade_bg
    pop     af
    add     8
    cp      129
    jr      c, +
    xor     a
    ld      (fade_type), a
+   ld      (fade_cnt), a   
    ret

hud_update_fadein_red1:
    ld      a, (fade_cnt)
-   push    af
    ld      hl, PAL_RED
    ld      de, HUD_OBJ_PAL
    ld      bc, 8
    call    gfx_pal_fade_obj
    pop     af
    ret

hud_update_fadein_red2:
    ld      a, (fade_cnt)
-   push    af
    ld      hl, PAL_RED
    ld      de, HUD_BG_PAL
    ld      bc, 8
    call    gfx_pal_fade_bg
    pop     af
    add     8
    cp      129
    jr      c, +
    xor     a
    ld      (fade_type), a
+   ld      (fade_cnt), a   
    ret

hud_update_fade_dmg:
    ld      a, (fade_cnt)
    inc     a
    cp      8
    jr      nz, +
    xor     a
    ld      (fade_type), a
+   ld      (fade_cnt), a
    ld      c, a
    ld      b, 0
    ld      hl, damagefadetable
    add     hl, bc
    ld      a, (hl)
    push    af
    ld      hl, HUD_BG_PAL
    ld      de, PAL_RED
    ld      b, 0
    ld      c, 6
    call    gfx_pal_fade_bg
    pop     af
    ld      hl, HUD_OBJ_PAL
    ld      de, PAL_RED
    ld      b, 0
    ld      c, 4
    call    gfx_pal_fade_obj
    ret
damagefadetable:
    .db     0, 16, 32, 64, 96, 64, 32, 16

hud_fade_death:
    ld      a, (fade_cnt)
-   push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_BG_PAL
    ld      de, PAL_RED
    ld      bc, 8
    push    af
    call    gfx_pal_fade_bg
    pop     af
    push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_OBJ_PAL
    ld      de, PAL_RED
    ld      bc, 8
    push    af
    call    gfx_pal_fade_obj
    pop     af
    add     4
    cp      129
    jr      c, -
    ld      bc, 40
    call    sys_delay
    xor     a
    ld      (fade_cnt), a
    ld      a, 3
    ld      (fade_type), a
    ret

hud_fade_floordone:
    ld      a, (fade_cnt)
-   push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_BG_PAL
    ld      de, PAL_BLACK
    ld      bc, 8
    push    af
    call    gfx_pal_fade_bg
    pop     af
    push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_OBJ_PAL
    ld      de, PAL_BLACK
    ld      bc, 8
    push    af
    call    gfx_pal_fade_obj
    pop     af
    add     4
    cp      129
    jr      c, -
    ld      bc, 40
    call    sys_delay
    xor     a
    ld      (fade_cnt), a
    ld      (fade_type), a
    ; temp
    ld      a, 2
    ld      (fade_type), a
    ret

hud_fade_gameover:
    ld      a, (fade_cnt)
-   push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_BG_PAL
    ld      de, PAL_RED
    ld      bc, 8
    push    af
    call    gfx_pal_fade_bg
    pop     af
    push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_OBJ_PAL
    ld      de, PAL_RED
    ld      bc, 8
    push    af
    call    gfx_pal_fade_obj
    pop     af
    add     4
    cp      129
    jr      c, -
    ld      bc, 40
    call    sys_delay
    xor     a
    ld      (fade_type), a
    ld      (fade_cnt), a
    ret
    ; to black
+   ld      a, 0
-   push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, PAL_RED
    ld      de, PAL_BLACK
    ld      bc, 8
    push    af
    call    gfx_pal_fade_bg
    pop     af
    push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, PAL_RED
    ld      de, PAL_BLACK
    ld      bc, 8
    push    af
    call    gfx_pal_fade_obj
    pop     af
    add     16
    cp      129
    jr      c, -
    ld      bc, 40
    call    sys_delay
    xor     a
    ld      (fade_type), a
    ld      (fade_cnt), a
    ret

hud_fade_victory:
    ld      a, (fade_cnt)
-   push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_BG_PAL
    ld      de, PAL_WHITE
    ld      bc, 8
    push    af
    call    gfx_pal_fade_bg
    pop     af
    push    af
    call    sys_wait_vbl
    ld      a, (wolf_lcdc)
    ldh     (R_LCDC), a
    call    snd_update
    pop     af
    ld      hl, HUD_OBJ_PAL
    ld      de, PAL_WHITE
    ld      bc, 8
    push    af
    call    gfx_pal_fade_obj
    pop     af
    add     4
    cp      129
    jr      c, -
    ld      bc, 40
    call    sys_delay
    xor     a
    ld      (fade_type), a
    ld      (fade_cnt), a
    ret


wolf_init:
    ; set RAM banking mode so EA0 and EA1 are stable
    ld      a, 1
    ld      ($6000), a
    xor     a
    ld      ($4000), a
    ret

wolf_trigger:
    ; wake up KE04 from sleep mode by setting EA0 to high
    ld      a, 2
    ld      ($4000), a
    xor     a
    ld      ($4000), a
    ret

wolf_init_map:
    ; setup maps for double buffering the wolf graphics
    ; $9800 references tiles from vram bank 0, $8800
    ; $9C00 references tiles from vram bank 1, $8800
    ld      a, %00000000
    ld      hl, $9800 + WOLF_MAP_OFFSET
    call    +
    ld      a, %00001000
    ld      hl, $9C00 + WOLF_MAP_OFFSET
    call    +
    ret
+   ld      d, -128
    ld      e, a
    xor     a
    ldh     (R_VBK), a
    ld      b, WOLF_NUMTILES_Y
--  ld      c, WOLF_NUMTILES_X
-   ldh     a, (R_STAT)
    and     $02
    jr      nz, -
    ld      a, d
    ld      (hl), a
    ld      a, 1
    ldh     (R_VBK), a
    ld      a, (hl)
    or      e
    ldi     (hl), a
    xor     a
    ldh     (R_VBK), a
    inc     d
    dec     c
    jr      nz, -
    push    bc
    ld      bc, 32 - WOLF_NUMTILES_X
    add     hl, bc
    pop     bc
    dec     b
    jr      nz, --
    ret

wolf_get_result:
    ; enable sram
    ld      a, $0A
    ld      ($0000), a
    ; process commands from wolf
    ld      hl, WOLF_CMDBUFFER_RD
-   ldi     a, (hl)
    cp      0
    jr      z, ++
    sla     a
    ld      e, a
    ld      d, 0            ; de = cmd
    ldi     a, (hl)
    ld      b, a            ; b = arg
    push    hl
    ld      hl, +
    push    hl
    ld      hl, wolfcmd_jumptable
    add     hl, de
    ldi     a, (hl)
    ld      h, (hl)
    ld      l, a
    ld      a, b
    jp      hl
+   pop     hl
    jr      -
    ; disable sram
++  xor     a
    ld      ($0000), a
    ret

wolfcmd_jumptable:
    .dw wolfcmd_nop             ;  0
    .dw snd_play_music          ;  1 (a = song)
    .dw snd_play_fx             ;  2 (a = effect)
    .dw snd_stop_music          ;  3
    .dw wolfcmd_nop             ;  4
    .dw wolfcmd_nop             ;  5
    .dw hud_set_weapon          ;  6 (a = weapon)
    .dw hud_set_weapon_frame    ;  7 (a = frame)
    .dw hud_set_ammo            ;  8 (a = ammo)
    .dw hud_set_health          ;  9 (a = health)
    .dw hud_set_lives           ; 10 (a = lives)
    .dw hud_set_floor           ; 11 (a = floor)
    .dw hud_set_keys            ; 12 (a = key bitfield)
    .dw hud_set_guns            ; 13 (a = gun bitfield)
    .dw wolfcmd_damage          ; 14
    .dw wolfcmd_death           ; 15
    .dw wolfcmd_gameover        ; 16
    .dw wolfcmd_victory         ; 17
    .dw wolfcmd_floordone       ; 18 (a = next floor)
    .dw wolfcmd_killratio       ; 19 (a = kill %)
    .dw wolfcmd_bonusratio      ; 20 (a = bonus %)
    .dw wolfcmd_secretratio     ; 21 (a = secret %)
    .dw wolfcmd_scorehi         ; 22 (a = score HI)
    .dw wolfcmd_scorelo         ; 23 (a = score LO)

wolfcmd_damage:
    ld      a, 1
    ld      (fade_type), a
    xor     a
    ld      (fade_cnt), a
    ret

wolfcmd_death:
    ld      a, 1
    ld      (death_trigger), a
    ret

wolfcmd_gameover:
    xor     a
    ld      (death_trigger), a
    ld      a, 1
    ld      (gameover_trigger), a
    ret

wolfcmd_victory:
    ld      a, 1
    ld      (victory_trigger), a
    ret

wolfcmd_floordone:
    ld      (floordone_next), a
    ld      a, 1
    ld      (floordone_trigger), a
    ret

wolfcmd_killratio:
    ld      (stat_kill_ratio), a
    ret

wolfcmd_bonusratio:
    ld      (stat_bonus_ratio), a
    ret

wolfcmd_secretratio:
    ld      (stat_secret_ratio), a
    ret

wolfcmd_scorehi:
    ld      (stat_score), a
    ret

wolfcmd_scorelo:
    ld      (stat_score+1), a
    ret


wolfcmd_nop:
    ret

.ENDS


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; data in bank 1
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 1 SLOT SLOT_ROM_BANKED
.SECTION "game_data_bank1" SEMIFREE
HUD_OBJ_CHR:
.INCBIN "gfx/obj_chr.bin"
HUD_BG_CHR:
.INCBIN "gfx/bg_chr.bin"    
HUD_BG_MAP:
.INCBIN "gfx/bg_map.bin"
.ENDS

.BANK 1 SLOT SLOT_ROM_BANKED
.SECTION "game_data_wpn0" ALIGN 16 SEMIFREE 
HUD_KNIFE_CHR:
.INCBIN "gfx/chr_knife.bin"
.ENDS

.BANK 1 SLOT SLOT_ROM_BANKED
.SECTION "game_data_wpn1" ALIGN 16 SEMIFREE 
HUD_GUN_CHR:
.INCBIN "gfx/chr_gun.bin"
.ENDS

.BANK 1 SLOT SLOT_ROM_BANKED
.SECTION "game_data_wpn2" ALIGN 16 SEMIFREE 
HUD_GUN2_CHR:
.INCBIN "gfx/chr_gun2.bin"
.ENDS

.BANK 1 SLOT SLOT_ROM_BANKED
.SECTION "game_data_wpn3" ALIGN 16 SEMIFREE 
HUD_GUN3_CHR:
.INCBIN "gfx/chr_gun3.bin"
.ENDS


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; data in bank 0
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 0 SLOT SLOT_ROM
.SECTION "game_data_bank0" SEMIFREE

; WPNTILE tile, pal, xtile, ytile, xpos
.DEFINE WPN_YPOS        WOLF_LAST_Y_LINE
.DEFINE WPN_XPOS_KNIFE  88
.DEFINE WPN_XPOS_GUN    72
.DEFINE WPN_XPOS_GUN2   72
.DEFINE WPN_XPOS_GUN3   64

WPN_CHR_TABLE:
    .DW HUD_KNIFE_CHR
    .DB :HUD_KNIFE_CHR
    .DB 46
    .DW HUD_GUN_CHR
    .DB :HUD_GUN_CHR
    .DB 68
    .DW HUD_GUN2_CHR
    .DB :HUD_GUN2_CHR
    .DB 57
    .DW HUD_GUN3_CHR
    .DB :HUD_GUN3_CHR
    .DB 86

WPN_FRAME_TABLE:
    .DW WPN_KNIFE_TILES_0        ; knife
    .DW WPN_KNIFE_TILES_1
    .DW WPN_KNIFE_TILES_2
    .DW WPN_KNIFE_TILES_3
    .DW WPN_GUN_TILES_0          ; gun
    .DW WPN_GUN_TILES_1
    .DW WPN_GUN_TILES_2
    .DW WPN_GUN_TILES_3
    .DW WPN_GUN2_TILES_0        ; machinegun
    .DW WPN_GUN2_TILES_1
    .DW WPN_GUN2_TILES_2
    .DW WPN_GUN2_TILES_3
    .DW WPN_GUN3_TILES_0        ; minigun
    .DW WPN_GUN3_TILES_1
    .DW WPN_GUN3_TILES_2
    .DW WPN_GUN3_TILES_3

.MACRO WPNTILE
.DB WPN_YPOS + 9 - (\4 * 8)
.DB \5 + (\3 * 8)
.DB \1
.DB \2 | %00001000
.ENDM


WPN_KNIFE_TILES_0:  ; knife sprites
    .DB 3
    WPNTILE 15, 0, 1, 0, WPN_XPOS_KNIFE
    WPNTILE 16, 0, 2, 0, WPN_XPOS_KNIFE
    WPNTILE 17, 0, 1, 1, WPN_XPOS_KNIFE
WPN_KNIFE_TILES_1:
    .DB 5
    WPNTILE 18, 2, 1, 0, WPN_XPOS_KNIFE
    WPNTILE 19, 2, 2, 0, WPN_XPOS_KNIFE
    WPNTILE 20, 0, 1, 0, WPN_XPOS_KNIFE
    WPNTILE 21, 0, 2, 0, WPN_XPOS_KNIFE
    WPNTILE 22, 0, 1, 1, WPN_XPOS_KNIFE
WPN_KNIFE_TILES_2:
    .DB 11
    WPNTILE 23, 3, 1, 0, WPN_XPOS_KNIFE
    WPNTILE 24, 3, 2, 0, WPN_XPOS_KNIFE
    WPNTILE 25, 2, 0, 0, WPN_XPOS_KNIFE
    WPNTILE 26, 2, 1, 0, WPN_XPOS_KNIFE
    WPNTILE 27, 2, 2, 0, WPN_XPOS_KNIFE
    WPNTILE 28, 2, 1, 1, WPN_XPOS_KNIFE
    WPNTILE 29, 0, 0, 0, WPN_XPOS_KNIFE
    WPNTILE 30, 0, 0, 1, WPN_XPOS_KNIFE
    WPNTILE 31, 0, 1, 1, WPN_XPOS_KNIFE
    WPNTILE 32, 0, 2, 1, WPN_XPOS_KNIFE
    WPNTILE 33, 0, 0, 2, WPN_XPOS_KNIFE
WPN_KNIFE_TILES_3:
    .DB 12
    WPNTILE 34, 3, 1, 0, WPN_XPOS_KNIFE-3
    WPNTILE 35, 3, 2, 0, WPN_XPOS_KNIFE-3
    WPNTILE 36, 3, 3, 0, WPN_XPOS_KNIFE-3
    WPNTILE 37, 3, 1, 1, WPN_XPOS_KNIFE-3
    WPNTILE 38, 3, 2, 1, WPN_XPOS_KNIFE-3
    WPNTILE 39, 2, 0, 0, WPN_XPOS_KNIFE-3
    WPNTILE 40, 2, 0, 1, WPN_XPOS_KNIFE-3
    WPNTILE 41, 2, 1, 1, WPN_XPOS_KNIFE-3
    WPNTILE 42, 0, 0, 1, WPN_XPOS_KNIFE-3
    WPNTILE 43, 0, 1, 1, WPN_XPOS_KNIFE-3
    WPNTILE 44, 0, 0, 2, WPN_XPOS_KNIFE-3
    WPNTILE 45, 0, 1, 2, WPN_XPOS_KNIFE-3

WPN_GUN_TILES_0:    ; gun sprites
    .DB 8
    WPNTILE 15, 2, 1, 0, WPN_XPOS_GUN
    WPNTILE 16, 2, 2, 0, WPN_XPOS_GUN
    WPNTILE 17, 0, 1, 0, WPN_XPOS_GUN
    WPNTILE 18, 0, 2, 0, WPN_XPOS_GUN
    WPNTILE 19, 0, 1, 1, WPN_XPOS_GUN
    WPNTILE 20, 0, 2, 1, WPN_XPOS_GUN
    WPNTILE 21, 0, 1, 2, WPN_XPOS_GUN
    WPNTILE 22, 0, 2, 2, WPN_XPOS_GUN
WPN_GUN_TILES_1:
    .DB 12
    WPNTILE 23, 3, 0, 0, WPN_XPOS_GUN-1
    WPNTILE 24, 3, 1, 0, WPN_XPOS_GUN-1
    WPNTILE 25, 3, 2, 0, WPN_XPOS_GUN-1
    WPNTILE 26, 3, 3, 0, WPN_XPOS_GUN-1
    WPNTILE 27, 2, 1, 0, WPN_XPOS_GUN-1
    WPNTILE 28, 2, 2, 0, WPN_XPOS_GUN-1
    WPNTILE 29, 2, 1, 1, WPN_XPOS_GUN-1
    WPNTILE 30, 2, 2, 1, WPN_XPOS_GUN-1
    WPNTILE 31, 0, 1, 1, WPN_XPOS_GUN-1
    WPNTILE 32, 0, 2, 1, WPN_XPOS_GUN-1
    WPNTILE 33, 0, 1, 2, WPN_XPOS_GUN-1
    WPNTILE 34, 0, 2, 2, WPN_XPOS_GUN-1
WPN_GUN_TILES_2:
    .DB 17
    WPNTILE 35, 3, 1, 0, WPN_XPOS_GUN-2
    WPNTILE 36, 3, 2, 0, WPN_XPOS_GUN-2
    WPNTILE 37, 3, 3, 0, WPN_XPOS_GUN-2
    WPNTILE 38, 2, 1, 0, WPN_XPOS_GUN-2
    WPNTILE 39, 2, 2, 0, WPN_XPOS_GUN-2
    WPNTILE 40, 2, 3, 0, WPN_XPOS_GUN-2
    WPNTILE 41, 2, 1, 1, WPN_XPOS_GUN-2
    WPNTILE 42, 2, 2, 1, WPN_XPOS_GUN-2
    WPNTILE 43, 2, 3, 1, WPN_XPOS_GUN-2
    WPNTILE 44, 0, 1, 1, WPN_XPOS_GUN-2
    WPNTILE 45, 0, 2, 1, WPN_XPOS_GUN-2
    WPNTILE 46, 0, 1, 2, WPN_XPOS_GUN-2
    WPNTILE 47, 0, 2, 2, WPN_XPOS_GUN-2
    WPNTILE 48, 1, 1, 2, WPN_XPOS_GUN-2
    WPNTILE 49, 1, 2, 2, WPN_XPOS_GUN-2
    WPNTILE 50, 1, 1, 3, WPN_XPOS_GUN-2
    WPNTILE 51, 1, 2, 3, WPN_XPOS_GUN-2
WPN_GUN_TILES_3:
    .DB 16
    WPNTILE 52, 3, 1, 0, WPN_XPOS_GUN-3
    WPNTILE 53, 3, 2, 0, WPN_XPOS_GUN-3
    WPNTILE 54, 3, 3, 0, WPN_XPOS_GUN-3
    WPNTILE 55, 2, 1, 0, WPN_XPOS_GUN-3
    WPNTILE 56, 2, 2, 0, WPN_XPOS_GUN-3
    WPNTILE 57, 2, 3, 0, WPN_XPOS_GUN-3
    WPNTILE 58, 2, 1, 1, WPN_XPOS_GUN-3
    WPNTILE 59, 2, 2, 1, WPN_XPOS_GUN-3
    WPNTILE 60, 2, 3, 1, WPN_XPOS_GUN-3
    WPNTILE 61, 2, 1, 2, WPN_XPOS_GUN-3
    WPNTILE 62, 2, 3, 2, WPN_XPOS_GUN-3
    WPNTILE 63, 0, 1, 1, WPN_XPOS_GUN-3
    WPNTILE 64, 0, 2, 1, WPN_XPOS_GUN-3
    WPNTILE 65, 0, 1, 2, WPN_XPOS_GUN-3
    WPNTILE 66, 0, 2, 2, WPN_XPOS_GUN-3
    WPNTILE 67, 0, 2, 3, WPN_XPOS_GUN-3
WPN_GUN2_TILES_0:  ; machinegun sprites
    .DB 4
    WPNTILE 15, 0, 1, 0, WPN_XPOS_GUN2
    WPNTILE 16, 0, 2, 0, WPN_XPOS_GUN2
    WPNTILE 17, 0, 1, 1, WPN_XPOS_GUN2
    WPNTILE 18, 0, 2, 1, WPN_XPOS_GUN2
WPN_GUN2_TILES_1:
    .DB 9
    WPNTILE 19, 3, 0, 0, WPN_XPOS_GUN2-1
    WPNTILE 20, 3, 1, 0, WPN_XPOS_GUN2-1
    WPNTILE 21, 2, 1, 0, WPN_XPOS_GUN2-1
    WPNTILE 22, 0, 1, 0, WPN_XPOS_GUN2-1
    WPNTILE 23, 0, 2, 0, WPN_XPOS_GUN2-1
    WPNTILE 24, 0, 3, 0, WPN_XPOS_GUN2-1
    WPNTILE 25, 0, 1, 1, WPN_XPOS_GUN2-1
    WPNTILE 26, 0, 2, 1, WPN_XPOS_GUN2-1
    WPNTILE 27, 0, 2, 2, WPN_XPOS_GUN2-1
WPN_GUN2_TILES_2:
    .DB 20
    WPNTILE 28, 3, 0, 0, WPN_XPOS_GUN2-2
    WPNTILE 29, 3, 1, 0, WPN_XPOS_GUN2-2
    WPNTILE 30, 2, 1, 0, WPN_XPOS_GUN2-2
    WPNTILE 31, 0, 1, 0, WPN_XPOS_GUN2-2
    WPNTILE 32, 0, 2, 0, WPN_XPOS_GUN2-2
    WPNTILE 33, 0, 3, 0, WPN_XPOS_GUN2-2
    WPNTILE 34, 0, 1, 1, WPN_XPOS_GUN2-2
    WPNTILE 35, 0, 2, 1, WPN_XPOS_GUN2-2
    WPNTILE 36, 0, 2, 2, WPN_XPOS_GUN2-2
    WPNTILE 37, 1, 0, 1, WPN_XPOS_GUN2-2
    WPNTILE 38, 1, 1, 1, WPN_XPOS_GUN2-2
    WPNTILE 39, 1, 2, 1, WPN_XPOS_GUN2-2
    WPNTILE 40, 1, 3, 1, WPN_XPOS_GUN2-2
    WPNTILE 41, 1, 4, 1, WPN_XPOS_GUN2-2
    WPNTILE 42, 1, 0, 2, WPN_XPOS_GUN2-2
    WPNTILE 43, 1, 1, 2, WPN_XPOS_GUN2-2
    WPNTILE 44, 1, 2, 2, WPN_XPOS_GUN2-2
    WPNTILE 45, 1, 3, 2, WPN_XPOS_GUN2-2
    WPNTILE 46, 1, 4, 2, WPN_XPOS_GUN2-2
    WPNTILE 47, 1, 2, 3, WPN_XPOS_GUN2-2
WPN_GUN2_TILES_3:
    .DB 9
    WPNTILE 48, 3, 0, 0, WPN_XPOS_GUN2-3
    WPNTILE 49, 3, 1, 0, WPN_XPOS_GUN2-3
    WPNTILE 50, 2, 1, 0, WPN_XPOS_GUN2-3
    WPNTILE 51, 0, 1, 0, WPN_XPOS_GUN2-3
    WPNTILE 52, 0, 2, 0, WPN_XPOS_GUN2-3
    WPNTILE 53, 0, 3, 0, WPN_XPOS_GUN2-3
    WPNTILE 54, 0, 1, 1, WPN_XPOS_GUN2-3
    WPNTILE 55, 0, 2, 1, WPN_XPOS_GUN2-3
    WPNTILE 56, 0, 2, 2, WPN_XPOS_GUN2-3
WPN_GUN3_TILES_0:  ; minigun sprites
    .DB 6
    WPNTILE 15, 0, 1, 0, WPN_XPOS_GUN3
    WPNTILE 16, 0, 2, 0, WPN_XPOS_GUN3
    WPNTILE 17, 0, 3, 0, WPN_XPOS_GUN3
    WPNTILE 18, 0, 4, 0, WPN_XPOS_GUN3
    WPNTILE 19, 0, 2, 1, WPN_XPOS_GUN3
    WPNTILE 20, 0, 3, 1, WPN_XPOS_GUN3
WPN_GUN3_TILES_1:  ; minigun sprites
    .DB 12
    WPNTILE 21, 0, 1, 0, WPN_XPOS_GUN3-1
    WPNTILE 22, 0, 2, 0, WPN_XPOS_GUN3-1
    WPNTILE 23, 0, 3, 0, WPN_XPOS_GUN3-1
    WPNTILE 24, 0, 4, 0, WPN_XPOS_GUN3-1
    WPNTILE 25, 0, 5, 0, WPN_XPOS_GUN3-1
    WPNTILE 26, 0, 1, 1, WPN_XPOS_GUN3-1
    WPNTILE 27, 0, 2, 1, WPN_XPOS_GUN3-1
    WPNTILE 28, 0, 3, 1, WPN_XPOS_GUN3-1
    WPNTILE 29, 0, 4, 1, WPN_XPOS_GUN3-1
    WPNTILE 30, 0, 2, 2, WPN_XPOS_GUN3-1
    WPNTILE 31, 0, 3, 2, WPN_XPOS_GUN3-1
    WPNTILE 32, 0, 4, 2, WPN_XPOS_GUN3-1
WPN_GUN3_TILES_2:  ; minigun sprites
    .DB 28
    WPNTILE 33, 0, 1, 0, WPN_XPOS_GUN3-2
    WPNTILE 34, 0, 2, 0, WPN_XPOS_GUN3-2
    WPNTILE 35, 0, 3, 0, WPN_XPOS_GUN3-2
    WPNTILE 36, 0, 4, 0, WPN_XPOS_GUN3-2
    WPNTILE 37, 0, 5, 0, WPN_XPOS_GUN3-2
    WPNTILE 39, 0, 2, 1, WPN_XPOS_GUN3-2
    WPNTILE 40, 0, 3, 1, WPN_XPOS_GUN3-2
    WPNTILE 41, 0, 4, 1, WPN_XPOS_GUN3-2
    WPNTILE 42, 0, 2, 2, WPN_XPOS_GUN3-2
    WPNTILE 43, 0, 3, 2, WPN_XPOS_GUN3-2
    WPNTILE 38, 0, 4, 2, WPN_XPOS_GUN3-2
    WPNTILE 44, 1, 0, 1, WPN_XPOS_GUN3-2
    WPNTILE 45, 1, 1, 1, WPN_XPOS_GUN3-2
    WPNTILE 46, 1, 2, 1, WPN_XPOS_GUN3-2
    WPNTILE 47, 1, 4, 1, WPN_XPOS_GUN3-2
    WPNTILE 48, 1, 5, 1, WPN_XPOS_GUN3-2
    WPNTILE 49, 1, 6, 1, WPN_XPOS_GUN3-2
    WPNTILE 50, 1, 0, 2, WPN_XPOS_GUN3-2
    WPNTILE 51, 1, 1, 2, WPN_XPOS_GUN3-2
    WPNTILE 52, 1, 2, 2, WPN_XPOS_GUN3-2
    WPNTILE 53, 1, 3, 2, WPN_XPOS_GUN3-2
    WPNTILE 54, 1, 4, 2, WPN_XPOS_GUN3-2
    WPNTILE 55, 1, 5, 2, WPN_XPOS_GUN3-2
    WPNTILE 56, 1, 1, 3, WPN_XPOS_GUN3-2
    WPNTILE 57, 1, 2, 3, WPN_XPOS_GUN3-2
    WPNTILE 58, 1, 3, 3, WPN_XPOS_GUN3-2
    WPNTILE 59, 1, 4, 3, WPN_XPOS_GUN3-2
    WPNTILE 60, 1, 3, 4, WPN_XPOS_GUN3-2
WPN_GUN3_TILES_3:  ; minigun sprites
    .DB 25
    WPNTILE 61, 0, 1, 0, WPN_XPOS_GUN3-3
    WPNTILE 62, 0, 2, 0, WPN_XPOS_GUN3-3
    WPNTILE 63, 0, 3, 0, WPN_XPOS_GUN3-3
    WPNTILE 64, 0, 4, 0, WPN_XPOS_GUN3-3
    WPNTILE 65, 0, 5, 0, WPN_XPOS_GUN3-3
    WPNTILE 66, 0, 2, 1, WPN_XPOS_GUN3-3
    WPNTILE 67, 0, 3, 1, WPN_XPOS_GUN3-3
    WPNTILE 68, 0, 4, 1, WPN_XPOS_GUN3-3
    WPNTILE 69, 0, 2, 2, WPN_XPOS_GUN3-3
    WPNTILE 70, 0, 3, 2, WPN_XPOS_GUN3-3
    WPNTILE 71, 0, 4, 2, WPN_XPOS_GUN3-3
    WPNTILE 72, 1, 0, 1, WPN_XPOS_GUN3-3
    WPNTILE 73, 1, 1, 1, WPN_XPOS_GUN3-3
    WPNTILE 74, 1, 2, 1, WPN_XPOS_GUN3-3
    WPNTILE 75, 1, 4, 1, WPN_XPOS_GUN3-3
    WPNTILE 76, 1, 5, 1, WPN_XPOS_GUN3-3
    WPNTILE 77, 1, 1, 2, WPN_XPOS_GUN3-3
    WPNTILE 78, 1, 2, 2, WPN_XPOS_GUN3-3
    WPNTILE 79, 1, 3, 2, WPN_XPOS_GUN3-3
    WPNTILE 80, 1, 4, 2, WPN_XPOS_GUN3-3
    WPNTILE 81, 1, 5, 2, WPN_XPOS_GUN3-3
    WPNTILE 82, 1, 2, 3, WPN_XPOS_GUN3-3
    WPNTILE 83, 1, 3, 3, WPN_XPOS_GUN3-3
    WPNTILE 84, 1, 4, 3, WPN_XPOS_GUN3-3
    WPNTILE 85, 1, 3, 4, WPN_XPOS_GUN3-3


; Paused palette
HUD_PAUSE_PAL:
.REPT 8
.db 15, 15, 15
.db 10, 10, 10
.db  5,  5,  5
.db  0,  0,  0
.ENDR

; Background palettes
HUD_BG_PAL:
.db 31, 31, 31  ; 0 gray
.db 20, 20, 20
.db 10, 10, 10
.db  0,  0,  0
.db 31,  0,  0  ; 1 red
.db 20, 20, 20
.db 10, 10, 10
.db  0,  0,  0
.db  0, 31,  0  ; 2 green
.db 20, 20, 20
.db 10, 10, 10
.db  0,  0,  0
.db  0,  0, 31  ; 3 blue
.db 20, 20, 20
.db 10, 10, 10
.db  0,  0,  0
.db 31, 19, 13  ; 4 skin
.db 20, 20, 20
.db 10, 10, 10
.db  0,  0,  0
.db 25, 22,  2  ; 5 gold
.db 20, 20, 20
.db 10, 10, 10
.db  0,  0,  0
.db 31, 31, 31  ; 6 HUD BG
.db 20, 25, 31
.db  5, 10, 31
.db  0,  0,  0
.db 30, 25, 22  ; HUD Face
.db 31, 21, 11
.db 10, 10, 10
.db 22,  8,  0

; Sprite palettes
HUD_OBJ_PAL:
.db 31,  0, 31  ; 0 gun
.db 31, 31, 31
.db 15, 15, 15
.db  0,  0,  0
.db 31,  0, 31  ; 1 fire
.db 31, 31,  0
.db 31,  0,  0
.db 10,  0,  0
.db 31,  0, 31  ; 2 hand
.db 30, 21, 17
.db 31, 19,  8
.db 17,  9,  0
.db 31,  0, 31  ; 3 sleeve
.db 22, 31, 11
.db 21, 28,  0
.db  3,  8,  1
.db 31,  0, 31  ; 4 key1
.db 31, 31, 31
.db 19, 30, 28
.db  0,  0,  0
.db 31,  0, 31  ; 5 key2
.db 31, 31, 31
.db 31, 24,  2
.db  0,  0,  0
.db 31,  0, 31  ; 6 blood
.db 31,  0,  0
.db 22,  0,  0
.db 10,  0,  0
.db 31,  0, 31  ; 7 pause
.db 31, 31,  0
.db 31,  0,  0
.db  0,  0,  0

.ENDS

