## Wolfenstein 3D for Gameboy Color
 (c)2017 Anders Granlund, www.happydaze.se

------------------------------------------------------------------------------

 This hardware and software is free; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 It is being distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 The Z80 binary is using FX-Hammer and GBP Player. The authors of
 these must be credited and any of their respective copyright 
 notices and/or disclaimers must be included.

 The KE04 binary uses and/or takes inspiration from parts of
 Wolf4SDL source code by Moritz "Ripper" Kroll (http://www.chaos-software.de.vu)
 which was in turn based on Wolfenstein 3D sources released by id Software.

 Some data files are derivate from the Wolfenstein 3D shareware package.

------------------------------------------------------------------------------

![Alt text](cart.jpg?raw=true "")


### Youtube: https://www.youtube.com/watch?v=3j6W-UF_7X0

[![alt-text](https://img.youtube.com/vi/JfMpG3RW_kU/0.jpg)](https://www.youtube.com/watch?v=3j6W-UF_7X0)


## A rough description of what is included:

## /z80/
- ASM sourcecode for the Gameboy side, compile with WLA-DX (http://www.villehelin.com/wla.htm)
- Burn using a Gameboy flash cart programmer that support programming an AM29F040 chip via the AudioIn pin.
- I use the open-source C3 programmer from Jeff Frohwein
(https://reinerziegler.de.mirrors.gg8.se/readplus.htm#C3)
I'm sure there are more modern options out there but this is what have had since back when those things were the latest and greatest :)
Alternatively, burn the chip with a generic eprom programmer before soldering to board

## /z80/tools/
- mod2gbt, part of GBP Player 3.0.5. Built for Mac OSX.
- wla-gb, part of WLA-DX. Built for Mac OSX
- wlalink, part of WLA-DX. Built for Mac OSX

## /ke04/
- C sourcecode for MKE04Z128VLD4
- Build data using wolfgfx (makefile inside /ke04/test2/Data)
- Compile source+data with Kinetis Design Studio
- Burn with Segger J-link cable connected to SWI pins on cartridge

## /tools/wolfgfx/
- C++ source code for the map & graphics converter, with XCode project.

## /hardware/mbc/
- MBC1 clone for ATF1502AS(L)
- Compile with Atmel WinCUPL
- Burn with Atmel ATDH1150SUB cable connected to JTAG pins on cartridge

## /hardware/cart/
- Eagle & Gerber files for cartridge boards
- Rev.C use Nintendo MBC1 chip
- Rev.D use ATF1502 to clone MBC1 functionality
- Both are otherwise functionally identical
- Manufacture the board in 0.8mm height

## /hardware/link/
- Eagle & Gerber files for cartridge <-> JTAG & SWI cables
- Optional adapter to make connecting programming cables more convenient


## External libraries and credits

### Wolf4SDL:
Portions of this software derivate from Wolf4SDL by Moritz "Ripper" Kroll
(http://www.chaos-software.de.vu)

Wolf4SDL is in turned based on Wolfenstein 3D by id Software.
(http://www.idsoftware.com)


### FX HAMMER:
This software is using FX Hammer by Aleksi Eeben for generating and playing
sound effects. https://aleksieeben.myportfolio.com/portfolio


### GBT PLAYER:
This software is using GBT PLAYER v3.0.5 for music playback and for converting the
midis to runtime format. https://github.com/AntonioND/gbt-player

The converter tool in z80/tools/mod2gbt was built for MacOSX. Please see
the official GBT-Player Github page if you need to build it for another
operating system.
