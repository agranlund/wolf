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

;SECTION "GBT_VAR_1",WRAM0
.RAMSECTION "GBT_VAR_1" BANK 0 SLOT SLOT_RAM_GBTP

;-------------------------------------------------------------------------------

gbt_playing DS 1

; pointer to the pattern pointer array
gbt_pattern_array_ptr  DS 2 ; LSB first
gbt_pattern_array_bank DS 1

; playing speed
gbt_speed DS 1

; Up to 12 bytes per step are copied here to be handled in functions in bank 1
gbt_temp_play_data DS 12

gbt_loop_enabled            DS 1
gbt_ticks_elapsed          DS 1
gbt_current_step           DS 1
gbt_current_pattern        DS 1
gbt_current_step_data_ptr     DS 2 ; pointer to next step data - LSB first
gbt_current_step_data_bank   DS 1 ; bank of current pattern data

gbt_channels_enabled: DS 1

gbt_pan   DS 4*1 ; Ch 1-4
gbt_vol   DS 4*1 ; Ch 1-4
gbt_instr DS 4*1 ; Ch 1-4
gbt_freq  DS 3*2 ; Ch 1-3

gbt_channel3_loaded_instrument DS 1 ; current loaded instrument ($FF if none)

; Arpeggio -> Ch 1-3
gbt_arpeggio_freq_index DS 3*3 ; {base index, base index+x, base index+y} * 3
gbt_arpeggio_enabled    DS 3*1 ; if 0, disabled
gbt_arpeggio_tick       DS 3*1

; Cut note
gbt_cut_note_tick DS 4*1 ; If tick == gbt_cut_note_tick, stop note_

; Last step of last pattern this is set to 1
gbt_have_to_stop_next_step DS 1

gbt_update_pattern_pointers DS 1 ; set to 1 by jump effects
.ENDS

;###############################################################################

.BANK 0 SLOT SLOT_ROM
.ORG $200
.SECTION "GBT_BANK0" SEMIFREE    

;-------------------------------------------------------------------------------

gbt_get_pattern_ptr: ; a = pattern number

    ; loads a pointer to pattern a into gbt_current_step_data_ptr and
    ; gbt_current_step_data_bank

    ld      e,a
    ld      d,0

    ld      a,[gbt_pattern_array_bank]
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank

    ld      hl,gbt_pattern_array_ptr
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ; hl = pointer to list of pointers
    ; de = pattern number

    add     hl,de
    add     hl,de
    add     hl,de

    ; hl = pointer to pattern bank

    ld      a,[hl+]
    ld      [gbt_current_step_data_bank+0],a

    ; hl = pointer to pattern data

    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a

    ld      a,l
    ld      [gbt_current_step_data_ptr],a
    ld      a,h
    ld      [gbt_current_step_data_ptr+1],a

    ret

;-------------------------------------------------------------------------------

gbt_play: ; de = data, bc = bank, a = speed

    ld      hl,gbt_pattern_array_ptr
    ld      [hl],e
    inc     hl
    ld      [hl],d

    ld      [gbt_speed],a

    ld      a,c
    ld      [gbt_pattern_array_bank+0],a

    ld      a,0
    call    gbt_get_pattern_ptr

    xor     a
    ld      [gbt_current_step],a
    ld      [gbt_current_pattern],a
    ld      [gbt_ticks_elapsed],a
    ld      [gbt_loop_enabled],a
    ld      [gbt_have_to_stop_next_step],a
    ld      [gbt_update_pattern_pointers],a

    ld      a,$FF
    ld      [gbt_channel3_loaded_instrument],a

    ld      a,$0F
    ld      [gbt_channels_enabled],a

    ld      hl,gbt_pan
    ld      a,$11 ; L and R
    ld      [hl+],a
    add     a
    ld      [hl+],a
    add     a
    ld      [hl+],a
    add     a
    ld      [hl],a

    ld      hl,gbt_vol
    ld      a,$F0 ; 100%
    ld      [hl+],a
    ld      [hl+],a
    ld      a,$20 ; 100%
    ld      [hl+],a
    ld      a,$F0 ; 100%
    ld      [hl+],a

    ld      a,0

    ld      hl,gbt_instr
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      hl,gbt_freq
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a

    ld      [gbt_arpeggio_enabled+0],a
    ld      [gbt_arpeggio_enabled+1],a
    ld      [gbt_arpeggio_enabled+2],a

    ld      a,$FF
    ld      [gbt_cut_note_tick+0],a
    ld      [gbt_cut_note_tick+1],a
    ld      [gbt_cut_note_tick+2],a
    ld      [gbt_cut_note_tick+3],a

    ld      a,$80
    ld      [NR52],a
    ld      a,$00
    ld      [NR51],a
    ld      a,$00 ; 0%
    ld      [NR50],a

    xor     a
    ld      [NR10],a
    ld      [NR11],a
    ld      [NR12],a
    ld      [NR13],a
    ld      [NR14],a
    ld      [NR21],a
    ld      [NR22],a
    ld      [NR23],a
    ld      [NR24],a
    ld      [NR30],a
    ld      [NR31],a
    ld      [NR32],a
    ld      [NR33],a
    ld      [NR34],a
    ld      [NR41],a
    ld      [NR42],a
    ld      [NR43],a
    ld      [NR44],a

    ld      a,$77 ; 100%
    ld      [NR50],a

    ld      a,$01
    ld      [gbt_playing],a

    ret

;-------------------------------------------------------------------------------

gbt_pause: ; a = pause/unpause
    ld      [gbt_playing],a
    or      a
    ret     z
    xor     a
    ld      [NR50],a
    ret

;-------------------------------------------------------------------------------

gbt_loop: ; a = loop/don't loop
    ld      [gbt_loop_enabled],a
    ret

;-------------------------------------------------------------------------------

gbt_stop:
    xor     a
    ld      [gbt_playing],a
    ld      [NR50],a
    ld      [NR51],a
    ld      [NR52],a
    ret

;-------------------------------------------------------------------------------

gbt_enable_channels: ; a = channel flags (channel flag = (1<<(channel_num-1)))
    ld      [gbt_channels_enabled],a
    ret

;-------------------------------------------------------------------------------

    ;GLOBAL  gbt_update_bank1

gbt_update:

    ld      a,[gbt_playing]
    or      a
    ret     z ; If not playing, return

    ; Handle tick counter

    ld      hl,gbt_ticks_elapsed
    ld      a,[gbt_speed] ; a = total ticks
    ld      b,[hl] ; b = ticks elapsed
    inc     b
    ld      [hl],b
    cp      b
    jr      z,_dontexit

    ; Tick != Speed, update effects and exit
    ld      a,$01
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
    ; Call update function in bank 1 (in gbt_player_bank1_s)
    call    gbt_update_effects_bank1

    ret

_dontexit:
    ld      [hl],$00 ; reset tick counter

    ; Clear tick-based effects
    ; ------------------------

    xor     a
    ld      hl,gbt_arpeggio_enabled ; Disable arpeggio
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl],a
    dec     a ; a = $FF
    ld      hl,gbt_cut_note_tick ; Disable cut note
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl+],a
    ld      [hl],a

    ; Update effects
    ; --------------

    ld      a,$01
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
    ; Call update function in bank 1 (in gbt_player_bank1_s)
    call    gbt_update_effects_bank1

    ; Check if last step
    ; ------------------

    ld      a,[gbt_have_to_stop_next_step]
    or      a
    jr      z,_dont_stop

    call    gbt_stop
    ld      a,0
    ld      [gbt_have_to_stop_next_step],a
    ret

_dont_stop:

    ; Get this step data
    ; ------------------

    ; Change to bank with song data

    ld      a,[gbt_current_step_data_bank]
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank

    ; Get step data

    ld      a,[gbt_current_step_data_ptr]
    ld      l,a
    ld      a,[gbt_current_step_data_ptr+1]
    ld      h,a ; hl = pointer to data

    ld      de,gbt_temp_play_data

    ld      b,4
_copy_loop: ; copy as bytes as needed for this step

    ld      a,[hl+]
    ld      [de],a
    inc     de
    bit     7,a
    jr      nz,_more_bytes
    bit     6,a
    jr      z,_no_more_bytes_this_channel

    jr      _one_more_byte

_more_bytes:

    ld      a,[hl+]
    ld      [de],a
    inc     de
    bit     7,a
    jr      z,_no_more_bytes_this_channel

_one_more_byte:

    ld      a,[hl+]
    ld      [de],a
    inc     de

_no_more_bytes_this_channel:
    dec     b
    jr      nz,_copy_loop

    ld      a,l
    ld      [gbt_current_step_data_ptr],a
    ld      a,h
    ld      [gbt_current_step_data_ptr+1],a ; save pointer to data

    ; Increment step/pattern
    ; ----------------------

    ; Increment step

    ld      a,[gbt_current_step]
    inc     a
    ld      [gbt_current_step],a
    cp      64
    jr      nz,_dont_increment_pattern

    ; Increment pattern

    ld      a,0
    ld      [gbt_current_step],a ; Step 0

    ld      a,[gbt_current_pattern]
    inc     a
    ld      [gbt_current_pattern],a

    call    gbt_get_pattern_ptr

    ld      a,[gbt_current_step_data_ptr]
    ld      b,a
    ld      a,[gbt_current_step_data_ptr+1]
    or      b
    jr      nz,_not_ended ; if pointer is 0, song has ended

    ld      a,[gbt_loop_enabled]
    and     a

    jr      z,_loop_disabled

    ; If loop is enabled, jump to pattern 0

    ld      a,0
    ld      [gbt_current_pattern],a

    call    gbt_get_pattern_ptr

    jr      _end_handling_steps_pattern

_loop_disabled:

    ; If loop is disabled, stop song
    ; Stop it next step, if not this step won't be played

    ld      a,1
    ld      [gbt_have_to_stop_next_step],a

_not_ended:

_dont_increment_pattern:

_end_handling_steps_pattern:

    ld      a,$01
    ld      [$2000],a ; MBC1, MBC3, MBC5 - Set bank 1
    ; Call update function in bank 1 (in gbt_player_bank1_s)
    call    gbt_update_bank1

    ; Check if any effect has changed the pattern or step

    ld      a,[gbt_update_pattern_pointers]
    and     a
    ret     z
    ; if any effect has changed the pattern or step, update

    xor     a
    ld      [gbt_update_pattern_pointers],a ; clear update flag

    ld      [gbt_have_to_stop_next_step],a ; clear stop flag

    ld      a,[gbt_current_pattern]
    call    gbt_get_pattern_ptr ; set ptr to start of the pattern

    ; Search the step

    ; Change to bank with song data

    ld      a,[gbt_pattern_array_bank+0]
    ld      [$2000],a ; MBC1, MBC3, MBC5

    ld      a,[gbt_current_step_data_ptr]
    ld      l,a
    ld      a,[gbt_current_step_data_ptr+1]
    ld      h,a ; hl = pointer to data

    ld      a,[gbt_current_step]
    and     a
    ret     z ; if changing to step 0, exit

    add     a
    add     a
    ld      b,a ; b = iterations = step * 4 (number of channels)
_next_channel:

    ld      a,[hl+]
    bit     7,a
    jr      nz,_next_channel_more_bytes
    bit     6,a
    jr      z,_next_channel_no_more_bytes_this_channel

    jr      _next_channel_one_more_byte

_next_channel_more_bytes:

    ld      a,[hl+]
    bit     7,a
    jr      z,_next_channel_no_more_bytes_this_channel

_next_channel_one_more_byte:

    ld      a,[hl+]

_next_channel_no_more_bytes_this_channel:
    dec     b
    jr      nz,_next_channel

    ld      a,l
    ld      [gbt_current_step_data_ptr],a
    ld      a,h
    ld      [gbt_current_step_data_ptr+1],a ; save pointer to data

    ret
.ENDS
;###############################################################################
