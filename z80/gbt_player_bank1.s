;###############################################################################
;#                                                                             #
;#                                                                             #
;#                              GBT PLAYER  3_0_5                              #
;#                                                                             #
;#                                             Contact: antonio_nd@outlook_com #
;###############################################################################

; Copyright (c) 2009-2016, Antonio Niño Díaz (AntonioND)
; All rights reserved_
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; * Redistributions of source code must retain the above copyright notice, this
;  list of conditions and the following disclaimer_
;
; * Redistributions in binary form must reproduce the above copyright notice,
;   this list of conditions and the following disclaimer in the documentation
;   and/or other materials provided with the distribution_
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED_ IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE_

;###############################################################################

.INCLUDE "defines.i"

;###############################################################################

.BANK 1 SLOT SLOT_ROM_BANKED
.ORG $0
.SECTION "GBT_BANK1" SEMIFREE   

;-------------------------------------------------------------------------------

gbt_wave: ; 8 sounds
.DB $A5,$D7,$C9,$E1,$BC,$9A,$76,$31,$0C,$BA,$DE,$60,$1B,$CA,$03,$93 ; random
.DB $F0,$E1,$D2,$C3,$B4,$A5,$96,$87,$78,$69,$5A,$4B,$3C,$2D,$1E,$0F
.DB $FD,$EC,$DB,$CA,$B9,$A8,$97,$86,$79,$68,$57,$46,$35,$24,$13,$02 ; up-downs
.DB $DE,$FE,$DC,$BA,$9A,$A9,$87,$77,$88,$87,$65,$56,$54,$32,$10,$12
.DB $AB,$CD,$EF,$ED,$CB,$A0,$12,$3E,$DC,$BA,$BC,$DE,$FE,$DC,$32,$10 ; tri_ broken
.DB $FF,$EE,$DD,$CC,$BB,$AA,$99,$88,$77,$66,$55,$44,$33,$22,$11,$00 ; triangular
.DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00 ; square
.DB $79,$BC,$DE,$EF,$FF,$EE,$DC,$B9,$75,$43,$21,$10,$00,$11,$23,$45 ; sine

gbt_noise: ; 16 sounds
    ; 7 bit
    .DB  $5F,$5B,$4B,$2F,$3B,$58,$1F,$0F
    ; 15 bit
    .DB  $90,$80,$70,$50,$00
    .DB  $67,$63,$53

gbt_frequencies:
    .DW    44,  156,  262,  363,  457,  547,  631,  710,  786,  854,  923,  986
    .DW  1046, 1102, 1155, 1205, 1253, 1297, 1339, 1379, 1417, 1452, 1486, 1517
    .DW  1546, 1575, 1602, 1627, 1650, 1673, 1694, 1714, 1732, 1750, 1767, 1783
    .DW  1798, 1812, 1825, 1837, 1849, 1860, 1871, 1881, 1890, 1899, 1907, 1915
    .DW  1923, 1930, 1936, 1943, 1949, 1954, 1959, 1964, 1969, 1974, 1978, 1982
    .DW  1985, 1988, 1992, 1995, 1998, 2001, 2004, 2006, 2009, 2011, 2013, 2015

;-------------------------------------------------------------------------------

_gbt_get_freq_from_index: ; a = index, bc = returned freq
    ld      hl,gbt_frequencies
    ld      c,a
    ld      b,$00
    add     hl,bc
    add     hl,bc
    ld      c,[hl]
    inc     hl
    ld      b,[hl]
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 1 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_1_handle: ; de = info

    ld      a,[gbt_channels_enabled]
    and     $01
    jr      nz,_channel1_enabled

    ; Channel is disabled_ Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,_more_bytes1
    bit     6,a
    jr      z,_no_more_bytes_this_channel1

    jr      _one_more_byte1

_more_bytes1:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,_no_more_bytes_this_channel1

_one_more_byte1:

    inc     de

_no_more_bytes_this_channel1:

    ret

_channel1_enabled:

    ; Channel 1 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_has_frequency1

    ; Not frequency

    bit     6,a
    jr      nz,_instr_effects1

    ; Set volume or NOP

    bit     5,a
    jr      nz,_just_set_volume1

    ; NOP

    ret

_just_set_volume1:

    ; Set volume

    and     $0F
    swap    a
    ld      [gbt_vol+0],a

    jr      _refresh_channel1_regs

_instr_effects1:

    ; Set instrument and effect

    ld      b,a ; save byte

    and     $30
    add     a
    add     a
    ld      [gbt_instr+0],a ; Instrument

    ld      a,b ; restore byte

    and     $0F ; a = effect

    call    gbt_channel_1_set_effect

    jr      _refresh_channel1_regs

_has_frequency1:

    ; Has frequency

    and     $7F
    ld      [gbt_arpeggio_freq_index+0*3],a
    ; This destroys hl and     a_ Returns freq in bc
    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Get frequency

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_freq_instr_and_effect1

    ; Freq + Instr + Volume

    ld      b,a ; save byte

    and     $30
    add     a
    add     a
    ld      [gbt_instr+0],a ; Instrument

    ld      a,b ; restore byte

    and     $0F ; a = volume

    swap    a
    ld      [gbt_vol+0],a

    jr      _refresh_channel1_regs

_freq_instr_and_effect1:

    ; Freq + Instr + Effect

    ld      b,a ; save byte

    and     $30
    add     a
    add     a
    ld      [gbt_instr+0],a ; Instrument

    ld      a,b ; restore byte

    and     $0F ; a = effect

    call    gbt_channel_1_set_effect

    ;jr      _refresh_channel1_regs

_refresh_channel1_regs:

    ; fall through!!!!!

; -----------------

channel1_refresh_registers:

    xor     a
    ld      [NR10],a
    ld      a,[gbt_instr+0]
    ld      [NR11],a
    ld      a,[gbt_vol+0]
    ld      [NR12],a
    ld      a,[gbt_freq+0*2+0]
    ld      [NR13],a
    ld      a,[gbt_freq+0*2+1]
    or      $80 ; start
    ld      [NR14],a

    ret

; ------------------

channel1_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+0]
    ld      hl,gbt_ticks_elapsed
    cp      [hl]
    jp      nz,_dont_cut1

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+0],a ; disable cut note

    xor     a ; vol = 0
    ld      [NR12],a
    ld      a,$80 ; start
    ld      [NR14],a

_dont_cut1:

    ; Arpeggio
    ; --------

    ld      a,[gbt_arpeggio_enabled+0]
    and     a
    ret     z ; a is 0, return 0

    ; If enabled arpeggio, handle it

    ld      a,[gbt_arpeggio_tick+0]
    and     a
    jr      nz,_not_tick_01

    ; Tick 0 - Set original frequency

    ld      a,[gbt_arpeggio_freq_index+0*3+0]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Set frequency

    ld      a,1
    ld      [gbt_arpeggio_tick+0],a

    ret ; ret 1

_not_tick_01:

    cp      1
    jr      nz,_not_tick_11

    ; Tick 1

    ld      a,[gbt_arpeggio_freq_index+0*3+1]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Set frequency

    ld      a,2
    ld      [gbt_arpeggio_tick+0],a

    dec     a
    ret ; ret 1

_not_tick_11:

    ; Tick 2

    ld      a,[gbt_arpeggio_freq_index+0*3+2]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+0*2+0],a
    ld      a,b
    ld      [gbt_freq+0*2+1],a ; Set frequency

    xor     a
    ld      [gbt_arpeggio_tick+0],a

    inc     a ; ret 1
    ret

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_1_set_effect: ; a = effect, de = pointer to data_

    ld      hl,_gbt_ch1_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

_gbt_ch1_jump_table:
    .DW  _gbt_ch1_pan
    .DW  _gbt_ch1_arpeggio
    .DW  _gbt_ch1_cut_note
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_jump_pattern
    .DW  gbt_ch1234_jump_position
    .DW  gbt_ch1234_speed
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop

_gbt_ch1_pan:
    and     $11
    ld      [gbt_pan+0],a
    ld      a,1
    ret ; ret 1

_gbt_ch1_arpeggio:
    ld      b,a ; b = params

    ld      hl,gbt_arpeggio_freq_index+0*3
    ld      c,[hl] ; c = base index
    inc     hl

    ld      a,b
    swap    a
    and     $0F
    add     c

    ld      [hl+],a ; save first increment

    ld      a,b
    and     $0F
    add     c

    ld      [hl],a ; save second increment

    ld      a,1
    ld      [gbt_arpeggio_enabled+0],a
    ld      [gbt_arpeggio_tick+0],a

    ret ; ret 1

_gbt_ch1_cut_note:
    ld      [gbt_cut_note_tick+0],a
    xor     a ; ret 0
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 2 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_2_handle: ; de = info

    ld      a,[gbt_channels_enabled]
    and     $02
    jr      nz,_channel2_enabled

    ; Channel is disabled_ Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,_more_bytes2
    bit     6,a
    jr      z,_no_more_bytes_this_channel2

    jr      _one_more_byte2

_more_bytes2:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,_no_more_bytes_this_channel2

_one_more_byte2:

    inc     de

_no_more_bytes_this_channel2:

    ret

_channel2_enabled:

    ; Channel 2 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_has_frequency2

    ; Not frequency

    bit     6,a
    jr      nz,_instr_effects2

    ; Set volume or NOP

    bit     5,a
    jr      nz,_just_set_volume2

    ; NOP

    ret

_just_set_volume2:

    ; Set volume

    and     $0F
    swap    a
    ld      [gbt_vol+1],a

    jr      _refresh_channel2_regs

_instr_effects2:

    ; Set instrument and effect

    ld      b,a ; save byte

    and     $30
    add     a
    add     a
    ld      [gbt_instr+1],a ; Instrument

    ld      a,b ; restore byte

    and     $0F ; a = effect

    call    gbt_channel_2_set_effect

    jr      _refresh_channel2_regs

_has_frequency2:

    ; Has frequency

    and     $7F
    ld      [gbt_arpeggio_freq_index+1*3],a
    ; This destroys hl and a_ Returns freq in bc
    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Get frequency

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_freq_instr_and_effect2

    ; Freq + Instr + Volume

    ld      b,a ; save byte

    and     $30
    add     a
    add     a
    ld      [gbt_instr+1],a ; Instrument

    ld      a,b ; restore byte

    and     $0F ; a = volume

    swap    a
    ld      [gbt_vol+1],a

    jr      _refresh_channel2_regs

_freq_instr_and_effect2:

    ; Freq + Instr + Effect

    ld      b,a ; save byte

    and     $30
    add     a
    add     a
    ld      [gbt_instr+1],a ; Instrument

    ld      a,b ; restore byte

    and     $0F ; a = effect

    call    gbt_channel_2_set_effect

    ;jr      _refresh_channel2_regs

_refresh_channel2_regs:

    ; fall through!!!!!

; -----------------

channel2_refresh_registers:

    ld      a,[gbt_instr+1]
    ld      [NR21],a
    ld      a,[gbt_vol+1]
    ld      [NR22],a
    ld      a,[gbt_freq+1*2+0]
    ld      [NR23],a
    ld      a,[gbt_freq+1*2+1]
    or      $80 ; start
    ld      [NR24],a

    ret

; ------------------

channel2_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+1]
    ld      hl,gbt_ticks_elapsed
    cp      [hl]
    jp      nz,_dont_cut2

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+1],a ; disable cut note

    xor     a ; vol = 0
    ld      [NR22],a
    ld      a,$80 ; start
    ld      [NR24],a

_dont_cut2:

    ; Arpeggio
    ; --------

    ld      a,[gbt_arpeggio_enabled+1]
    and     a
    ret     z ; a is 0, return 0

    ; If enabled arpeggio, handle it

    ld      a,[gbt_arpeggio_tick+1]
    and     a
    jr      nz,_not_tick_02

    ; Tick 0 - Set original frequency

    ld      a,[gbt_arpeggio_freq_index+1*3+0]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Set frequency

    ld      a,1
    ld      [gbt_arpeggio_tick+1],a

    ret ; ret 1

_not_tick_02:

    cp      1
    jr      nz,_not_tick_12

    ; Tick 1

    ld      a,[gbt_arpeggio_freq_index+1*3+1]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Set frequency

    ld      a,2
    ld      [gbt_arpeggio_tick+1],a

    dec     a
    ret ; ret 1

_not_tick_12:

    ; Tick 2

    ld      a,[gbt_arpeggio_freq_index+1*3+2]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+1*2+0],a
    ld      a,b
    ld      [gbt_freq+1*2+1],a ; Set frequency

    xor     a
    ld      [gbt_arpeggio_tick+1],a

    inc     a ; ret 1
    ret

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_2_set_effect: ; a = effect, de = pointer to data

    ld      hl,_gbt_ch2_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

_gbt_ch2_jump_table:
    .DW  _gbt_ch2_pan
    .DW  _gbt_ch2_arpeggio
    .DW  _gbt_ch2_cut_note
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_jump_pattern
    .DW  gbt_ch1234_jump_position
    .DW  gbt_ch1234_speed
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop

_gbt_ch2_pan:
    and     $22
    ld      [gbt_pan+1],a
    ld      a,1
    ret ; ret 1

_gbt_ch2_arpeggio:
    ld      b,a ; b = params

    ld      hl,gbt_arpeggio_freq_index+1*3
    ld      c,[hl] ; c = base index
    inc     hl

    ld      a,b
    swap    a
    and     $0F
    add     c

    ld      [hl+],a ; save first increment

    ld      a,b
    and     $0F
    add     c

    ld      [hl],a ; save second increment

    ld      a,1
    ld      [gbt_arpeggio_enabled+1],a
    ld      [gbt_arpeggio_tick+1],a

    ret ; ret 1

_gbt_ch2_cut_note:
    ld      [gbt_cut_note_tick+1],a
    xor     a ; ret 0
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 3 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_3_handle: ; de = info

    ld      a,[gbt_channels_enabled]
    and     $04
    jr      nz,_channel3_enabled

    ; Channel is disabled_ Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,_more_bytes3
    bit     6,a
    jr      z,_no_more_bytes_this_channel3

    jr      _one_more_byte3

_more_bytes3:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,_no_more_bytes_this_channel3

_one_more_byte3:

    inc     de

_no_more_bytes_this_channel3:

    ret

_channel3_enabled:

    ; Channel 3 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_has_frequency3

    ; Not frequency

    bit     6,a
    jr      nz,_effects3

    ; Set volume or NOP

    bit     5,a
    jr      nz,_just_set_volume3

    ; NOP

    ret

_just_set_volume3:

    ; Set volume

    and     $0F
    swap    a
    ld      [gbt_vol+2],a

    jr      _refresh_channel3_regs

_effects3:

    ; Set effect

    and     $0F ; a = effect

    call    gbt_channel_3_set_effect
    and     a
    ret     z ; if 0, don't refresh registers

    jr      _refresh_channel3_regs

_has_frequency3:

    ; Has frequency

    and     $7F
    ld      [gbt_arpeggio_freq_index+2*3],a
    ; This destroys hl and     a_ Returns freq in bc
    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Get frequency

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_freq_instr_and_effect3

    ; Freq + Instr + Volume

    ld      b,a ; save byte

    and     $0F
    ld      [gbt_instr+2],a ; Instrument

    ld      a,b ; restore byte

    and     $30 ; a = volume
    add     a
    ld      [gbt_vol+2],a

    jr      _refresh_channel3_regs

_freq_instr_and_effect3:

    ; Freq + Instr + Effect

    ld      b,a ; save byte

    and     $0F
    ld      [gbt_instr+2],a ; Instrument

    ld      a,b ; restore byte

    and     $70
    swap    a    ; a = effect (only 0-7 allowed here)

    call    gbt_channel_3_set_effect

    ;jr      _refresh_channel3_regs

_refresh_channel3_regs:

    ; fall through!!!!!

; -----------------

channel3_refresh_registers:

    xor     a
    ld      [NR30],a ; disable

    ld      a,[gbt_channel3_loaded_instrument]
    ld      b,a
    ld      a,[gbt_instr+2]
    cp      b
    call    nz,gbt_channel3_load_instrument ; a = instrument

    ld      a,$80
    ld      [NR30],a ; enable

    xor     a
    ld      [NR31],a
    ld      a,[gbt_vol+2]
    ld      [NR32],a
    ld      a,[gbt_freq+2*2+0]
    ld      [NR33],a
    ld      a,[gbt_freq+2*2+1]
    or      $80 ; start
    ld      [NR34],a

    ret

; ------------------

gbt_channel3_load_instrument:

    ld      [gbt_channel3_loaded_instrument],a

    swap    a ; a = a * 16
    ld      c,a
    ld      b,0
    ld      hl,gbt_wave
    add     hl,bc

    ld      c,$30
    ld      b,16
_loop3:
    ld      a,[hl+]
    ld      [$FF00+c],a
    inc     c
    dec     b
    jr      nz,_loop3

    ret

; ------------------

channel3_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+2]
    ld      hl,gbt_ticks_elapsed
    cp      [hl]
    jp      nz,_dont_cut3

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+2],a ; disable cut note

    ld      a,$80
    ld      [NR30],a ; enable

    xor     a ; vol = 0
    ld      [NR32],a
    ld      a,$80 ; start
    ld      [NR34],a

_dont_cut3:

    ; Arpeggio
    ; --------

    ld      a,[gbt_arpeggio_enabled+2]
    and     a
    ret     z ; a is 0, return 0

    ; If enabled arpeggio, handle it

    ld      a,[gbt_arpeggio_tick+2]
    and     a
    jr      nz,_not_tick_03

    ; Tick 0 - Set original frequency

    ld      a,[gbt_arpeggio_freq_index+2*3+0]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Set frequency

    ld      a,1
    ld      [gbt_arpeggio_tick+2],a

    ret ; ret 1

_not_tick_03:

    cp      1
    jr      nz,_not_tick_13

    ; Tick 1

    ld      a,[gbt_arpeggio_freq_index+2*3+1]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Set frequency

    ld      a,2
    ld      [gbt_arpeggio_tick+2],a

    dec     a
    ret ; ret 1

_not_tick_13:

    ; Tick 2

    ld      a,[gbt_arpeggio_freq_index+2*3+2]

    call    _gbt_get_freq_from_index

    ld      a,c
    ld      [gbt_freq+2*2+0],a
    ld      a,b
    ld      [gbt_freq+2*2+1],a ; Set frequency

    xor     a
    ld      [gbt_arpeggio_tick+2],a

    inc     a
    ret ; ret 1

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_3_set_effect: ; a = effect, de = pointer to data

    ld      hl,_gbt_ch3_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

_gbt_ch3_jump_table:
    .DW  _gbt_ch3_pan
    .DW  _gbt_ch3_arpeggio
    .DW  _gbt_ch3_cut_note
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_jump_pattern
    .DW  gbt_ch1234_jump_position
    .DW  gbt_ch1234_speed
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop

_gbt_ch3_pan:
    and     $44
    ld      [gbt_pan+2],a
    ld      a,1
    ret ; ret 1

_gbt_ch3_arpeggio:
    ld      b,a ; b = params

    ld      hl,gbt_arpeggio_freq_index+2*3
    ld      c,[hl] ; c = base index
    inc     hl

    ld      a,b
    swap    a
    and     $0F
    add     c

    ld      [hl+],a ; save first increment

    ld      a,b
    and     $0F
    add     c

    ld      [hl],a ; save second increment

    ld      a,1
    ld      [gbt_arpeggio_enabled+2],a
    ld      [gbt_arpeggio_tick+2],a

    ret ; ret 1

_gbt_ch3_cut_note:
    ld      [gbt_cut_note_tick+2],a
    xor     a ; ret 0
    ret

;-------------------------------------------------------------------------------
; ---------------------------------- Channel 4 ---------------------------------
;-------------------------------------------------------------------------------

gbt_channel_4_handle: ; de = info

    ld      a,[gbt_channels_enabled]
    and     $08
    jr      nz,_channel4_enabled

    ; Channel is disabled_ Increment pointer as needed

    ld      a,[de]
    inc     de
    bit     7,a
    jr      nz,_more_bytes4
    bit     6,a
    jr      z,_no_more_bytes_this_channel4

    jr      _one_more_byte4

_more_bytes4:

    ld      a,[de]
    inc     de
    bit     7,a
    jr      z,_no_more_bytes_this_channel4

_one_more_byte4:

    inc     de

_no_more_bytes_this_channel4:

    ret

_channel4_enabled:

    ; Channel 4 is enabled

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_has_instrument4

    ; Not instrument

    bit     6,a
    jr      nz,_effects4

    ; Set volume or NOP

    bit     5,a
    jr      nz,_just_set_volume4

    ; NOP

    ret

_just_set_volume4:

    ; Set volume

    and     $0F
    swap    a
    ld      [gbt_vol+3],a

    jr      _refresh_channel4_regs

_effects4:

    ; Set effect

    and     $0F ; a = effect

    call    gbt_channel_4_set_effect
    and     a
    ret     z ; if 0, don't refresh registers

    jr      _refresh_channel4_regs

_has_instrument4:

    ; Has instrument

    and     $1F
    ld      hl,gbt_noise
    ld      c,a
    ld      b,0
    add     hl,bc
    ld      a,[hl] ; a = instrument data

    ld      [gbt_instr+3],a

    ld      a,[de]
    inc     de

    bit     7,a
    jr      nz,_instr_and_effect4

    ; Instr + Volume

    and     $0F ; a = volume

    swap    a
    ld      [gbt_vol+3],a

    jr      _refresh_channel4_regs

_instr_and_effect4:

    ; Instr + Effect

    and     $0F ; a = effect

    call    gbt_channel_4_set_effect

    ;jr      _refresh_channel4_regs

_refresh_channel4_regs:

    ; fall through!!!!!

; -----------------

channel4_refresh_registers:

    xor     a
    ld      [NR41],a
    ld      a,[gbt_vol+3]
    ld      [NR42],a
    ld      a,[gbt_instr+3]
    ld      [NR43],a
    ld      a,$80 ; start
    ld      [NR44],a

    ret

; ------------------

channel4_update_effects: ; returns 1 in a if it needed to update sound registers

    ; Cut note
    ; --------

    ld      a,[gbt_cut_note_tick+3]
    ld      hl,gbt_ticks_elapsed
    cp      [hl]
    jp      nz,_dont_cut4

    dec     a ; a = $FF
    ld      [gbt_cut_note_tick+3],a ; disable cut note

    xor     a ; vol = 0
    ld      [NR42],a
    ld      a,$80 ; start
    ld      [NR44],a

_dont_cut4:

    xor     a
    ret ; a is 0, return 0

; -----------------

; returns a = 1 if needed to update registers, 0 if not
gbt_channel_4_set_effect: ; a = effect, de = pointer to data

    ld      hl,_gbt_ch4_jump_table
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,[de] ; load args
    inc     de

    jp      hl

_gbt_ch4_jump_table:
    .DW  _gbt_ch4_pan
    .DW  gbt_ch1234_nop ; gbt_ch4_arpeggio
    .DW  _gbt_ch4_cut_note
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_jump_pattern
    .DW  gbt_ch1234_jump_position
    .DW  gbt_ch1234_speed
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop
    .DW  gbt_ch1234_nop

_gbt_ch4_pan:
    and     $44
    ld      [gbt_pan+3],a
    ld      a,1
    ret ; ret 1

_gbt_ch4_cut_note:
    ld      [gbt_cut_note_tick+3],a
    xor     a ; ret 0
    ret

;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

; Common effects go here:

gbt_ch1234_nop:
    xor     a ;ret 0
    ret

gbt_ch1234_jump_pattern:
    ld      [gbt_current_pattern],a
    xor     a
    ld      [gbt_current_step],a
    ld      [gbt_have_to_stop_next_step],a ; clear stop flag
    ld      a,1
    ld      [gbt_update_pattern_pointers],a
    xor     a ;ret 0
    ret

gbt_ch1234_jump_position:
    ld      [gbt_current_step],a
    ld      hl,gbt_current_pattern
    inc     [hl]
    ld      a,1
    ld      [gbt_update_pattern_pointers],a
    xor     a ;ret 0
    ret

gbt_ch1234_speed:
    ld      [gbt_speed],a
    xor     a
    ld      [gbt_ticks_elapsed],a
    ret ;ret 0

;-------------------------------------------------------------------------------

gbt_update_bank1:

    ld      de,gbt_temp_play_data

    ; each function will return in de the pointer to next byte

    call    gbt_channel_1_handle

    call    gbt_channel_2_handle

    call    gbt_channel_3_handle

    call    gbt_channel_4_handle

    ; end of channel handling

    ld      hl,gbt_pan
    ld      a,[hl+]
    or      [hl]
    inc     hl
    or      [hl]
    inc     hl
    or      [hl]
    ld      [NR51],a ; handle panning___

    ret

;-------------------------------------------------------------------------------

gbt_update_effects_bank1:

    call    channel1_update_effects
    and     a
    call    nz,channel1_refresh_registers

    call    channel2_update_effects
    and     a
    call    nz,channel2_refresh_registers

    call    channel3_update_effects
    and     a
    call    nz,channel3_refresh_registers

    call    channel4_update_effects
    and     a
    call    nz,channel4_refresh_registers

    ret

.ENDS
;###############################################################################
