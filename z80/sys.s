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
; sys_update_joypad
; sys_cpu_1mhz
; sys_cpu_2mhz
; sys_wait_vbl
; mul_8x8	: DE = B * C
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.INCLUDE "defines.i"



;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Variables
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.RAMSECTION "SysVars" BANK 0 SLOT SLOT_RAM
g_console_type:		DB	; 0 = dmg, 1 = gbc, 2 = gba
g_joypad_status:	DB	; down.up.right.left.start.select.b.a
g_joypad_trigger:	DB	; down.up.right.left.start.select.b.a
temp_div16:		DS 2
temp_div16count:	DB
.ENDS


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Header
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.BANK 0 SLOT SLOT_ROM
.ORG $100
	.SYM "Start"
	NOP
	JP $150

	.SYM "Header"
	.DB $CE $ED $66 $66 $CC $0D $00 $0B $03 $73 $00 $83 $00 $0C $00 $0D
	.DB $00 $08 $11 $1F $88 $89 $00 $0E $DC $CC $6E $E6 $DD $DD $D9 $99
	.DB $BB $BB $67 $63 $6E $0E $EC $CC $DD $DC $99 $9F $BB $B9 $33 $3E


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; Entry point
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
.ORG $150
	.SYM "Entry"

	;------------------------------------------
	; identify console type (DMG / GBC / GBA)
	;------------------------------------------
	ld	c, 0
	sub	$11			; A = 0x11 on GBC/GBA
	jr	nz, + 
	inc	c
	rrc	b			; bit 0 of B is 1 on GBA
	jr	nc, +
	inc	c
+	ld	hl, g_console_type
	ld	(hl), c

reset:

	;------------------------------------------
	; init DMG
	;------------------------------------------
	di				    ; disable interrupts
	ld 	sp, $FFFE		; set stack pointer

    ld  a, 1
    ld  ($2000), a      ; ROM bank 1

	ld	a, %10010000	; disable window + bg + obj
	ldh	(R_LCDC), a

	xor 	a
	ldh	(R_IF), a		; clear irq request flags
	ldh	(R_IE), a		; disable all interrupt types
	ldh	(R_SCY), a		; scroll-Y
	ldh	(R_SCX), a		; scroll-X
	ldh	(R_NR52), a		; sound circuit disable
	ldh	(R_BGP), a		; clear bg palette
	ldh	(R_OBP0), a		; clear obj0 palette
	ldh	(R_OBP1), a		; clear obj1 palette

	ld	a, 7
	ldh	(R_WX),a		; window X position
	ld	a, 144
	ldh	(R_WY), a		; window Y position

	ld	a, (g_console_type)
	or	a
	jp	z, MAIN


	;------------------------------------------
	; init CGB
	;------------------------------------------
-	ldh	a, (R_LY)		; wait vbl
	cp	$90
	jr	nz, -

	ld	b, 8			; clear cgb bg palette
	ld	a, %10000000
-	ldh	(R_BCPS), a
	ld	c, a
	ld	a, %11111111
	ldh	(R_BCPD), a
	ldh	(R_BCPD), a
	ldh	(R_BCPD), a
	ldh	(R_BCPD), a
	ldh	(R_BCPD), a
	ldh	(R_BCPD), a
	ldh	(R_BCPD), a
	ldh	(R_BCPD), a
	ld	a, c
	add	8
	dec	b
	jr	nz, -

	ld	b, 8			; clear cgb obj palette
	ld	a, %10000000
-	ldh	(R_OCPS), a
	ld	c, a
	ld	a, %11111111
	ldh	(R_OCPD), a
	ldh	(R_OCPD), a
	ldh	(R_OCPD), a
	ldh	(R_OCPD), a
	ldh	(R_OCPD), a
	ldh	(R_OCPD), a
	ldh	(R_OCPD), a
	ldh	(R_OCPD), a
	ld	a, c
	add	8
	dec	b
	jr	nz, -

	xor     a
    ldh     (R_VBK), a		; vram bank 0

	jp	MAIN

.SECTION "sys_code" SEMIFREE

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; update joypad
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
sys_update_joypad:
    ld      a, $20
    ldh     (R_P1), a
    ldh     a, (R_P1)
    ldh     a, (R_P1)
    cpl
    and     %00001111
    swap    a
    ld      b, a
    ld      a, $10
    ldh     (R_P1), a
    ldh     a, (R_P1)
    ldh     a, (R_P1)
    ldh     a, (R_P1)
    ldh     a, (R_P1)
    ldh     a, (R_P1)
    ldh     a, (R_P1)
    cpl
    and     %00001111
    or      b
    ld      d, a
    ld      bc, g_joypad_trigger
    ld      hl, g_joypad_status
    ld      a, (hl)
    xor     d
    and     d
    ld      (bc), a
    ld      (hl), d
    ld      a, $30
    ldh     (R_P1), a
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; cpu speed
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
sys_cpu_1mhz:
    ld      a, (KEY1)
    rlca 
    ret     nc
    jr      +
sys_cpu_2mhz:
    ld      a, (KEY1)
    rlca 
    ret     c
+   di
    ld      hl, IE
    ld      a, (hl)
    push    af
    xor     a
    ld      (hl), a
    ld      (IF), a
    ld      a, $30
    ld      (P1), a
    ld      a, 1
    ld      (KEY1), a
    stop
    nop
    pop     af
    ld      (hl), a
    ei
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; wait for vblank
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
sys_wait_vbl:
    ldh		a, (R_LY)
    cp      $90
    jr 	    nz, sys_wait_vbl
    ret

;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; delay BC frames
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
sys_delay:
--  ldh     a, (R_LY)
    cp      $90
    jr      nz, --
-   ldh     a, (R_LY)
    cp      $0
    jr      nz, -
    dec     bc
    ld      a, b
    or      c
    jr      nz, --
    ret



;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; divide 16/16 -> 16
; DE = DE / BC
; BC remainder
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
sys_div_16x16:
	ld      hl, temp_div16
    ld      (hl), c
    inc     hl
    ld      (hl), b
    inc     hl
    ld      (hl), 17
    ld      bc, 0
-   ld      hl, temp_div16count
    ld      a, e
    rla
    ld      e, a
    ld      a, d
    rla
    ld      d, a
    dec     (hl)
    ret     z
    ld      a, c
    rla
    ld      c, a
    ld      a, b
    rla
    ld      b, a
    dec     hl
    dec     hl
    ld      a, c
    sub     (hl)
    ld      c, a
    inc     hl
    ld      a, b
    sbc     (hl)
    ld      b, a
    jr      nc,+
    dec     hl
    ld      a, c
    add     (hl)
    ld      c, a
    inc     hl
    ld      a, b
    adc     (hl)
    ld      b, a
+   ccf
    jr      -


;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
; multiply 8x8->16
; DE = B * C
;»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
sys_mul_8x8:
    ld      l, c
    ld      h, 2
    ld      d, (hl)          ; d = 32 * log_2(c)
    ld      l, b
    ld      a, (hl)          ; a = 32 * log_2(b)
    add     d
    ld      l, a
    ld      a, 0
    adc     0
    ld      h, a             ; hl = d + a
    add     hl, hl
    set     2, h             ; hl = hl + $0400
    ld      e, (hl)
    inc     hl
    ld      d, (hl)          ; de = 2^([hl]/32)
    ret    

.ENDS


.ORG $200
_log_table:
 .db 0 , 0 , 32 , 50 , 64 , 74 , 82 , 89 , 96 , 101 , 106 , 110 , 114 , 118 , 121
 .db 125 , 128 , 130 , 133 , 135 , 138 , 140 , 142 , 144 , 146 , 148 , 150 , 152
 .db 153 , 155 , 157 , 158 , 160 , 161 , 162 , 164 , 165 , 166 , 167 , 169 , 170
 .db 171 , 172 , 173 , 174 , 175 , 176 , 177 , 178 , 179 , 180 , 181 , 182 , 183
 .db 184 , 185 , 185 , 186 , 187 , 188 , 189 , 189 , 190 , 191 , 192 , 192 , 193
 .db 194 , 194 , 195 , 196 , 196 , 197 , 198 , 198 , 199 , 199 , 200 , 201 , 201
 .db 202 , 202 , 203 , 204 , 204 , 205 , 205 , 206 , 206 , 207 , 207 , 208 , 208
 .db 209 , 209 , 210 , 210 , 211 , 211 , 212 , 212 , 213 , 213 , 213 , 214 , 214
 .db 215 , 215 , 216 , 216 , 217 , 217 , 217 , 218 , 218 , 219 , 219 , 219 , 220
 .db 220 , 221 , 221 , 221 , 222 , 222 , 222 , 223 , 223 , 224 , 224 , 224 , 225
 .db 225 , 225 , 226 , 226 , 226 , 227 , 227 , 227 , 228 , 228 , 228 , 229 , 229
 .db 229 , 230 , 230 , 230 , 231 , 231 , 231 , 231 , 232 , 232 , 232 , 233 , 233
 .db 233 , 234 , 234 , 234 , 234 , 235 , 235 , 235 , 236 , 236 , 236 , 236 , 237
 .db 237 , 237 , 237 , 238 , 238 , 238 , 238 , 239 , 239 , 239 , 239 , 240 , 240
 .db 240 , 241 , 241 , 241 , 241 , 241 , 242 , 242 , 242 , 242 , 243 , 243 , 243
 .db 243 , 244 , 244 , 244 , 244 , 245 , 245 , 245 , 245 , 245 , 246 , 246 , 246
 .db 246 , 247 , 247 , 247 , 247 , 247 , 248 , 248 , 248 , 248 , 249 , 249 , 249
 .db 249 , 249 , 250 , 250 , 250 , 250 , 250 , 251 , 251 , 251 , 251 , 251 , 252
 .db 252 , 252 , 252 , 252 , 253 , 253 , 253 , 253 , 253 , 253 , 254 , 254 , 254
 .db 254 , 254 , 255 , 255 , 255 , 255 , 255

 .ORG $400	
_anti_log_table:
 .dw 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 2
 .dw 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 2
 .dw 2 , 2 , 2 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 3 , 4 , 4
 .dw 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 5 , 6
 .dw 6 , 6 , 6 , 6 , 6 , 6 , 6 , 7 , 7 , 7 , 7 , 7 , 7 , 7 , 8 , 8 , 8 , 8 , 8 , 9
 .dw 9 , 9 , 9 , 9 , 10 , 10 , 10 , 10 , 10 , 11 , 11 , 11 , 11 , 12 , 12 , 12 , 12
 .dw 13 , 13 , 13 , 13 , 14 , 14 , 14 , 15 , 15 , 15 , 16 , 16 , 16 , 17 , 17 , 17
 .dw 18 , 18 , 19 , 19 , 19 , 20 , 20 , 21 , 21 , 22 , 22 , 23 , 23 , 24 , 24 , 25
 .dw 25 , 26 , 26 , 27 , 27 , 28 , 29 , 29 , 30 , 31 , 31 , 32 , 33 , 33 , 34 , 35
 .dw 36 , 36 , 37 , 38 , 39 , 40 , 41 , 41 , 42 , 43 , 44 , 45 , 46 , 47 , 48 , 49
 .dw 50 , 52 , 53 , 54 , 55 , 56 , 57 , 59 , 60 , 61 , 63 , 64 , 65 , 67 , 68 , 70
 .dw 71 , 73 , 74 , 76 , 78 , 79 , 81 , 83 , 85 , 87 , 89 , 91 , 92 , 95 , 97 , 99
 .dw 101 , 103 , 105 , 108 , 110 , 112 , 115 , 117 , 120 , 123 , 125 , 128 , 131
 .dw 134 , 137 , 140 , 143 , 146 , 149 , 152 , 156 , 159 , 162 , 166 , 170 , 173
 .dw 177 , 181 , 185 , 189 , 193 , 197 , 202 , 206 , 211 , 215 , 220 , 225 , 230
 .dw 235 , 240 , 245 , 251 , 256 , 262 , 267 , 273 , 279 , 285 , 292 , 298 , 304
 .dw 311 , 318 , 325 , 332 , 339 , 347 , 354 , 362 , 370 , 378 , 386 , 395 , 403
 .dw 412 , 421 , 431 , 440 , 450 , 459 , 470 , 480 , 490 , 501 , 512 , 523 , 535
 .dw 546 , 558 , 571 , 583 , 596 , 609 , 622 , 636 , 650 , 664 , 679 , 693 , 709
 .dw 724 , 740 , 756 , 773 , 790 , 807 , 825 , 843 , 861 , 880 , 899 , 919 , 939
 .dw 960 , 981 , 1002 , 1024 , 1046 , 1069 , 1093 , 1117 , 1141 , 1166 , 1192
 .dw 1218 , 1244 , 1272 , 1300 , 1328 , 1357 , 1387 , 1417 , 1448 , 1480 , 1512
 .dw 1545 , 1579 , 1614 , 1649 , 1685 , 1722 , 1760 , 1798 , 1838 , 1878 , 1919
 .dw 1961 , 2004 , 2048 , 2093 , 2139 , 2186 , 2233 , 2282 , 2332 , 2383 , 2435
 .dw 2489 , 2543 , 2599 , 2656 , 2714 , 2774 , 2834 , 2896 , 2960 , 3025 , 3091
 .dw 3158 , 3228 , 3298 , 3371 , 3444 , 3520 , 3597 , 3676 , 3756 , 3838 , 3922
 .dw 4008 , 4096 , 4186 , 4277 , 4371 , 4467 , 4565 , 4664 , 4767 , 4871 , 4978
 .dw 5087 , 5198 , 5312 , 5428 , 5547 , 5668 , 5793 , 5919 , 6049 , 6182 , 6317
 .dw 6455 , 6597 , 6741 , 6889 , 7039 , 7194 , 7351 , 7512 , 7677 , 7845 , 8016
 .dw 8192 , 8371 , 8555 , 8742 , 8933 , 9129 , 9329 , 9533 , 9742 , 9955 , 10173
 .dw 10396 , 10624 , 10856 , 11094 , 11337 , 11585 , 11839 , 12098 , 12363 , 12634
 .dw 12910 , 13193 , 13482 , 13777 , 14079 , 14387 , 14702 , 15024 , 15353 , 15689
 .dw 16033 , 16384 , 16743 , 17109 , 17484 , 17867 , 18258 , 18658 , 19066 , 19484
 .dw 19911 , 20347 , 20792 , 21247 , 21713 , 22188 , 22674 , 23170 , 23678 , 24196
 .dw 24726 , 25268 , 25821 , 26386 , 26964 , 27554 , 28158 , 28774 , 29404 , 30048
 .dw 30706 , 31379 , 32066 , 32768 , 33485 , 34219 , 34968 , 35734 , 36516 , 37316
 .dw 38133 , 38968 , 39821 , 40693 , 41584 , 42495 , 43425 , 44376 , 45348 , 46341
 .dw 47356 , 48393 , 49452 , 50535 , 51642 , 52772 , 53928 , 55109 , 56316 , 57549
 .dw  58809 , 60097 , 61413 , 62757	
