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
; snd_init		:
; snd_update		:
; snd_play_music	: A=song
; snd_stop_music	:
; snd_pause_music	: A=status (1 = paused, 0 = resume)
; snd_play_fx		: A=effect
; snd_stop_fx		:
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.INCLUDE "defines.i"


.IF ENABLE_SOUND == 1
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Sound FX data
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 2 SLOT SLOT_ROM_BANKED
.ORG $0000
.SECTION "!SOUND_DATA" FREE
SoundFX_Bank:
.INCBIN  "sound/fxbank.bin"
.ENDS
	
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Music data
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 3 SLOT SLOT_ROM_BANKED
.ORG $0000
.SECTION "!MUSIC_MENU" SEMIFREE
.INCLUDE "music/mus_menu.s"
.ENDS
.BANK 4 SLOT SLOT_ROM_BANKED
.ORG $0000
.SECTION "!MUSIC_MAP1" SEMIFREE
.INCLUDE "music/mus_map1.s"
.ENDS
.BANK 4 SLOT SLOT_ROM_BANKED
.ORG $0000
.SECTION "!MUSIC_MAP2" SEMIFREE
.INCLUDE "music/mus_map2.s"
.ENDS
.BANK 5 SLOT SLOT_ROM_BANKED
.ORG $0000
.SECTION "!MUSIC_MAP3" SEMIFREE
.INCLUDE "music/mus_map3.s"
.ENDS
.BANK 6 SLOT SLOT_ROM_BANKED
.ORG $0000
.SECTION "!MUSIC_MAP4" SEMIFREE
.INCLUDE "music/mus_map4.s"
.ENDS
.BANK 5 SLOT SLOT_ROM_BANKED
.ORG $0000
.SECTION "!MUSIC_MAP0" SEMIFREE
.INCLUDE "music/mus_map0.s"
.ENDS	

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Song list
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.MACRO SONG
.DW :\1, \1
.ENDM
.BANK 0 SLOT 0
.SECTION "!SONG_LIST", FREE
song_list:
	SONG mus_menu_data		; 0 - Menu
	SONG mus_map1_data		; 1 - Map1_1
	SONG mus_map2_data		; 2 - Map1_2
	SONG mus_map3_data		; 3 - Map1_3
	SONG mus_map4_data		; 4 - Map1_4
	;SONG mus_map9_data		; 5 - Map1_9
	SONG mus_map0_data		; 5 - Map1_0
.ENDS
.ENDIF

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; variables
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.RAMSECTION "sound_vars" BANK 0 SLOT SLOT_RAM
snd_fxplaying	DB
.ENDS	

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; FXHammer variables
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.RAMSECTION "GBT_VAR_1" BANK 0 SLOT SLOT_RAM_FXHAMMER
FXCurrentPri	DB	; current prio ($00 = lowest)
FXSoundCount	DB	; countdown
FXSoundP	DB	; current step
FXSoundH	DB	; current sound + $44
.ENDS
	
.EQU SoundFX_Trig	$4000
.EQU SoundFX_Stop	$4003
.EQU SoundFX_Update	$4006



;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Sound code
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 0 SLOT SLOT_ROM
.ORG $200
.SECTION "sound_code" FREE

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; init sound engine
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
snd_init:
	xor	a
	ld	(snd_fxplaying), a
	.IF ENABLE_SOUND == 1
	call	gbt_enable_channels
	call	snd_stop_music
	.ENDIF
	ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; update sound engine, call at 60hz
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
snd_update:
	.IF ENABLE_SOUND == 1
	; update music
	call	gbt_update
	; update soundFX
	ld	a, :SoundFX_Bank
	ld	($2000), a
	call	SoundFX_Update
	; enable music on all channels after soundfx has finished
	ld	a, (snd_fxplaying)
	or	a
	ret	z
	ld	a, (FXSoundCount)
	or	a
	ret	nz
    	xor     a
	ld	(snd_fxplaying), a
	ld	a, %00001111
	call	gbt_enable_channels
	.ENDIF
	ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; play music, A = song number
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
snd_play_music:
	.IF ENABLE_SOUND == 1
	push	af
	call	snd_stop_music
	ld	a, %00001111
	call	gbt_enable_channels
	xor	a
	call	snd_pause_music
	pop	af
	ld	b, 0
	ld	c, a
	sla	c
	sla	c
	ld	hl, song_list
	add	hl, bc
	ldi	a, (hl)
	ld	c, a
	ldi	a, (hl)
	ld	b, a		; bc = bank
	ldi	a, (hl)
	ld	e, a
	ldi	a, (hl)
	ld	d, a		; de = addr
	ld	a, 2		; a = default speed
	call	gbt_play
	ld	a, 1		; loop enable
	call	gbt_loop
	.ENDIF
	ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; pause music, A = state (1 = pause, 0 = resume)
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
snd_pause_music:
	push	af
	.IF ENABLE_SOUND == 1
	call	gbt_pause
	.ENDIF
	pop	af
	cp	0
	jr	z, +
	xor	a
	ld	[NR50], a
	ret
+	ld	a, $77
	ld	[NR50], a
	ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; stop music
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
snd_stop_music:
	.IF ENABLE_SOUND == 1
	call	gbt_stop
    	ld      a,$80
    	ld      [NR52],a
    	ld      a,$00
    	ld      [NR51],a
    	ld      a,$00
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
    	ld      a,$77
    	ld      [NR50],a
    	.ENDIF
	ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; play effect, A = effect number
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
snd_play_fx:
	.IF ENABLE_SOUND == 1
	ld	b, a
	ld	a, :SoundFX_Bank
	ld	($2000), a
	ld	a, %00000101		; disable music on channels 2+4
	call	gbt_enable_channels
    	ld      a,%01010101
    	ld      (NR51), a
	ld	a, b
	call	SoundFX_Trig
	ld	a, 1
	ld	(snd_fxplaying), a
	.ENDIF
	ret


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; stop effect
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
snd_stop_fx:
	.IF ENABLE_SOUND == 1
	ld	a, :SoundFX_Bank
	ld	($2000), a
	call	SoundFX_Stop
	ld	a, %00001111		; enable music on all channels
	call	gbt_enable_channels
	xor	a
	ld	(snd_fxplaying), a
	.ENDIF
	ret

.ENDS	