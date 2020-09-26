/*
 * wl_hud.c
 *
 *  Created on: Nov 27, 2016
 *      Author: agranlund
 */

#include "wl_hud.h"
#include "../sram.h"

#define HUD_CMD_BUF_SIZE 64
u8 hud_cmd_buf[HUD_CMD_BUF_SIZE+1];
u8 hud_cmd_idx = 0;

void wl_hud_init()
{
	hud_cmd_idx = 0;
}

void wl_hud_update()
{
	if (hud_cmd_idx == 0)
		hud_cmd_buf[hud_cmd_idx++] = 0;

	hud_cmd_buf[hud_cmd_idx++] = 0;
	sram_write(0x1800, hud_cmd_idx, hud_cmd_buf);

	wl_hud_init();
}

static inline void wl_hud_cmd(u8 cmd, u8 arg)
{
	if (hud_cmd_idx < (HUD_CMD_BUF_SIZE-1))
	{
		hud_cmd_buf[hud_cmd_idx++] = cmd;
		hud_cmd_buf[hud_cmd_idx++] = arg;
	}
}

void wl_hud_PlayMusic(u8 song)
{
	wl_hud_cmd(1, song);
}

void wl_hud_PlaySound(u8 sound)
{
	wl_hud_cmd(2, sound);
}

void wl_hud_StopMusic()
{
	wl_hud_cmd(3, 0);
}

void wl_hud_SetWeapon(u8 weapon)
{
	wl_hud_cmd(6, weapon);
}

void wl_hud_SetWeaponFrame(u8 frame)
{
	wl_hud_cmd(7, frame);
}

void wl_hud_SetAmmo(u8 ammo)
{
	wl_hud_cmd(8, ammo);
}

void wl_hud_SetHealth(u8 health)
{
	wl_hud_cmd(9, health);
}

void wl_hud_SetLives(u8 lives)
{
	wl_hud_cmd(10, lives);
}

void wl_hud_SetFloor(u8 floor)
{
	wl_hud_cmd(11, floor);
}

void wl_hud_SetKeys(u8 keys)
{
	wl_hud_cmd(12, keys);
}

void wl_hud_SetGuns(u8 guns)
{
	wl_hud_cmd(13, (guns>>1));
}

void wl_hud_TakeDamage()
{
	wl_hud_cmd(14, 0);
}

void wl_hud_trigger_death()
{
	wl_hud_cmd(15, 0);
}

void wl_hud_trigger_gameover()
{
	wl_hud_cmd(16, 0);
}

void wl_hud_trigger_victory()
{
	wl_hud_cmd(17, 0);
}

void wl_hud_trigger_floordone(u8 nextfloor)
{
	wl_hud_cmd(18, nextfloor);
}

void wl_hud_SetKillRatio(u8 count)
{
	wl_hud_cmd(19, count);
}

void wl_hud_SetBonusRatio(u8 count)
{
	wl_hud_cmd(20, count);
}

void wl_hud_SetSecretRatio(u8 count)
{
	wl_hud_cmd(21, count);
}

void wl_hud_SetScoreHi(u8 score)
{
	wl_hud_cmd(22, score);
}

void wl_hud_SetScoreLo(u8 score)
{
	wl_hud_cmd(23, score);
}

