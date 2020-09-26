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

.EMPTYFILL $FF
.COMPUTEGBCHECKSUM
.COMPUTEGBCOMPLEMENTCHECK

.NAME "WOLFENSTEIN 3D  "
.LICENSEECODENEW "AG"
.ROMGBC

.CARTRIDGETYPE 	2		; ROM+MBC1+RAM
.ROMBANKSIZE	$4000		; ROM Banks are 16Kb each
.ROMBANKS	8		; 128Kb ROM, 8 Banks
.RAMSIZE 	2		;   8Kb RAM, 1 bank


.DEFINE ENABLE_SOUND	1


.EQU SLOT_ROM		0
.EQU SLOT_ROM_BANKED	1
.EQU SLOT_RAM_DONTUSE	2
.EQU SLOT_RAM_BANKED	3
.EQU SLOT_SRAM		4
.EQU SLOT_RAM		5
.EQU SLOT_RAM1		6
.EQU SLOT_RAM_GBTP	7
.EQU SLOT_RAM_CARILLION	8
.EQU SLOT_RAM_FXHAMMER	9
.EQU SLOT_RAM_OAM	10

.MEMORYMAP
DEFAULTSLOT 0
SLOT SLOT_ROM 		START $0000 SIZE $4000	; ROM Bank 0
SLOT SLOT_ROM_BANKED	START $4000 SIZE $4000	; ROM Bank 1-x
SLOT SLOT_RAM_DONTUSE	START $C000 SIZE $1000	; RAM Bank 0
SLOT SLOT_RAM_BANKED	START $D000 SIZE $1000	; RAM Bank 1-x
SLOT SLOT_SRAM		START $A000 SIZE $2000	; External RAM

; split ram bank 0 into multiple slots to accomodate:
; GBTPlayer: $C770 - C7B1	(0x41)
; Carillion: $C7C0 - C7EC	(0x2C)
; FXHammer:  $C7EC - C7EF	(0x04)
; OAM:       $C800 - C88F	(0x8F)
SLOT SLOT_RAM		START $C000 SIZE $0770	; RAM Bank 0, part 1
SLOT SLOT_RAM1		START $C8A0 SIZE $0760	; RAM Bank 0, part 2

SLOT SLOT_RAM_GBTP	START $C770 SIZE $0050	; GBT Player
SLOT SLOT_RAM_CARILLION	START $C7C0 SIZE $0021	; Carillion
SLOT SLOT_RAM_FXHAMMER	START $C7EC SIZE $0004 	; FXHammer
SLOT SLOT_RAM_OAM	START $C800 SIZE $00A0  ; OAM
.ENDME

.INCLUDE "cgb_hardware.i"
