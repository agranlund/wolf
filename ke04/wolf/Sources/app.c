/*
 * app.c
 *
 *  Created on: Oct 30, 2016
 *      Author: agranlund
 */

#include "Cpu.h"
#include "GPIO1.h"
#include "GPIO2.h"
#include "types.h"
#include "sys.h"
#include "sram.h"
#include "gfx.h"
#include "wl3d/wl_game.h"
#include "wl3d/wl_draw.h"
#include "wl3d/wl_hud.h"

void AppMain()
{
	GPIO2_SetFieldValue(GPIO2_DeviceData, IO_DBGOUT1, 1);

	wl_game_init(1, 0, 0);

	u32 bank = 0;
	char cmdBuf[16];
	for(;;)
	{
		// sleep until z80 triggers EA0
		GPIO2_SetFieldValue(GPIO2_DeviceData, IO_DBGOUT2, 0);
		DeepSleep();
		GPIO2_SetFieldValue(GPIO2_DeviceData, IO_DBGOUT2, 1);

		// send previous frame to z80 (~2.5ms)
		PROFILE_BEGIN();
		gfx_send_to_sram(bank);
		PROFILE_END();

		GPIO2_SetFieldValue(GPIO2_DeviceData, IO_DBGOUT2, 2);

		// fetch command buffer from z80 (sram address $1400 (z80: $B400))
		sram_read(0x1400, 16, cmdBuf);


		u8* cmd = &cmdBuf[0];
		u8 init = *cmd++;
		if (init & 1)
		{
			u8 lives = *cmd++;
			u8 floor = *cmd++;
			u8 health = *cmd++;
			u8 guns = *cmd++;
			u8 ammo = *cmd++;

			// .....bcd (b = godmode, c = weapons, d = init)
			u8 godmode = (init & 0x4) ? 1 : 0;
			u8 allwpn  = (init & 0x2) ? 1 : 0;
			wl_game_init(floor, godmode, allwpn);

			player.lives = lives;
			player.health = health;
			if (allwpn == 0)
			{
				player.weapons = (guns << 1) | 3;
				player.ammo = ammo;
			}
		}

		bank = (u32) (((*cmd) + 1) & 1);
		cmd++;
		u8 pad = *cmd;

		// update game
		wl_game_update(pad);

		// update hud
		wl_hud_update();

		// render next frame
		PROFILE_BEGIN();
		wl_draw_update();
		PROFILE_END();
	}
}

