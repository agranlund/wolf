/*
 * wl_game.c
 *
 *  Created on: Nov 12, 2016
 *      Author: agranlund
 */

#include "../types.h"
#include "../math.h"
#include "wl_game.h"
#include "wl_player.h"
#include "wl_draw.h"
#include "wl_hud.h"
#include "wl_npc.h"
#include "../../Data/datMaps.h"

u8 map[MAP_SIZE * MAP_SIZE] __attribute__ ((aligned (4)));

u8 doorstate[MAP_MAX_DOORS];
u8 doortimer[MAP_MAX_DOORS];
const struct mapData* level;
const u32* doordata;
u8 init_state;
u32 gameframe;
u8 floor_done;
int floor_bonus;

u32 level_idx;
u32 level_stat_npc;
u32 level_stat_npc_max;
u32 level_stat_bonus;
u32 level_stat_bonus_max;
u32 level_stat_secret;
u32 level_stat_secret_max;
struct player_t level_player_state;

u8 wl_cheat_godmode;

void wl_game_update_doors();
void wl_game_loadmap(int idx);

#define FLOOR_BONUS_BASE			    0
#define FLOOR_BONUS_100PERCENT		10000


//----------------------------------------------------------------------------
// init game
//----------------------------------------------------------------------------
void wl_game_init(u8 floor, u8 godmode, u8 allwpn)
{
	wl_cheat_godmode = godmode;
	gameframe = 0;
	init_state = 1;
	floor_done = 0;
	floor_bonus = 0;

	// init renderer
	wl_draw_init();

	// init player
	wl_player_init();
	player.floor = floor;

	if (allwpn)
	{
		player.weapons = (1<<WPN_KNIFE) | (1<<WPN_GUN) | (1<<WPN_GUN2) | (1<<WPN_GUN3);
		player.ammo = 99;
	}

	// init npcs
	wl_npc_init();

	// init map
	wl_game_loadmap(player.floor);
}


//----------------------------------------------------------------------------
// update game
//----------------------------------------------------------------------------
void wl_game_update(u8 joypad)
{
	if (init_state)
	{
		wl_hud_SetWeapon(player.weapon);
		wl_hud_SetWeaponFrame(0);
		wl_hud_SetAmmo(player.ammo);
		wl_hud_SetHealth(player.health);
		wl_hud_SetLives(player.lives);
		wl_hud_SetFloor(player.floor);
		wl_hud_SetKeys(player.keys);
		wl_hud_SetGuns(player.weapons);
		init_state = 0;
	}

	if (floor_bonus > 0)
	{
		wl_player_give_points(floor_bonus);
		floor_bonus = 0;
	}

	// update player
	wl_player_update(joypad);

	if (floor_done)
	{
		u8 kr = (100 * level_stat_npc) / level_stat_npc_max;
		u8 br = (100 * level_stat_bonus) / level_stat_bonus_max;
		u8 sr = (100 * level_stat_secret) / level_stat_secret_max;

		wl_hud_SetGuns(player.weapons);
		wl_hud_SetKillRatio(kr);
		wl_hud_SetBonusRatio(br);
		wl_hud_SetSecretRatio(sr);
		int score = player.score / 100;
		u8 scoreHi = ((score & 0xFF00) >> 8);
		u8 scoreLo = (score & 0xFF);
		wl_hud_SetScoreHi(scoreHi);
		wl_hud_SetScoreLo(scoreLo);

		// floor bonus points
		floor_bonus = FLOOR_BONUS_BASE;
		if (kr >= 100) floor_bonus += FLOOR_BONUS_100PERCENT;
		if (br >= 100) floor_bonus += FLOOR_BONUS_100PERCENT;
		if (sr >= 100) floor_bonus += FLOOR_BONUS_100PERCENT;

		if (player.floor == 9)
		{
			wl_hud_trigger_victory();
		}
		else
		{
			player.keys = 0;
			if (player.floor == 0)
				player.floor = 2;
			else if (floor_done > 1)
				player.floor = 0;
			else
				player.floor++;

			wl_hud_PlaySound(SND_TOGGLE_SWITCH);
			wl_hud_trigger_floordone(player.floor);
			wl_game_loadmap(player.floor);
		}
		floor_done = 0;
		init_state = 1;
		return;
	}

	// update doors
	wl_game_update_doors();

	// update enemies
	wl_npc_update();

	// check special conditions
	if (player.health == 0)
		wl_game_die();

	gameframe++;
}

//----------------------------------------------------------------------------
// update door states
//----------------------------------------------------------------------------
void wl_game_update_doors()
{
	for (int i=0; i<level->numdoors; ++i)
	{
		u8 state = doorstate[i];
		u8 action = (state >> 6);
		if (action == 0)
			continue;

		s8 pos = (state & 63);
		u8 timer = doortimer[i];
		int x = (doordata[i] >> 16) & 0xFF;
		int y = (doordata[i] >> 8) & 0xFF;
		volatile u32* colmap = (volatile u32*) COLMAP_ALIAS;

		switch (action)
		{
		case 1:
			// opening
			pos+=2;
			if (pos >= 32)
			{
				colmap[x + (y * MAP_SIZE)] = 0;
			}
			if (pos >= 63)
			{
				pos = 63;
				action = 2;
				timer = 0;
			}
			break;
		case 2:
			// waiting
			timer++;
			if (timer >= 128)
			{
				timer = 0;

				// don't close door on npc
				if (wl_npc_at(x, y) >= 0)
					break;

				// dont close if player or npc is blocking the doorway
				int px = player.x >> (FIXED_SHIFT + MAP_GRID_SHIFT);
				int py = player.y >> (FIXED_SHIFT + MAP_GRID_SHIFT);
				if ((px==x) && ((py==y) || ((py-1)==y) || ((py+1)==y)))
					break;
				if ((py==y) && ((px==x) || ((px-1)==x) || ((px+1)==x)))
					break;

				action = 3;
				colmap[x + (y * MAP_SIZE)] = 1;
			}
			break;
		case 3:
			// closing
			pos-=2;
			if (pos <= 0)
			{
				pos = 0;
				action = 0;
			}
			break;
		}

		doortimer[i] = timer;
		doorstate[i] = (action << 6) | pos;
	}
}

//----------------------------------------------------------------------------
// player died
//----------------------------------------------------------------------------
void wl_game_die()
{
	if (player.lives > 0)
	{
		player = level_player_state;
		player.lives--;
		init_state = 1;
		wl_game_loadmap(player.floor);
		wl_hud_trigger_death();
	}
	else
	{
		wl_hud_trigger_gameover();
	}
}

//----------------------------------------------------------------------------
// elevator
//----------------------------------------------------------------------------
void wl_game_trigger_elevator(u8 secret)
{
	floor_done = (1 + secret);
}

//----------------------------------------------------------------------------
// victory
//----------------------------------------------------------------------------
void wl_game_trigger_victory()
{
	floor_done = 1;
}


//----------------------------------------------------------------------------
// restart map
//----------------------------------------------------------------------------
void wl_game_restart_map()
{
	player = level_player_state;
	init_state = 1;
	wl_game_loadmap(player.floor);
}

//----------------------------------------------------------------------------
// prepare map
//----------------------------------------------------------------------------
void wl_game_loadmap(int mapidx)
{
	level_idx = mapidx;
	level_stat_npc = 0;
	level_stat_secret = 0;
	level_stat_bonus = 0;
	level_stat_npc_max = 0;
	level_stat_bonus_max = 0;
	level_stat_secret_max = 0;
	level_player_state = player;

	level = &mapDatas[mapidx];

	// start position
	player.x = ((((s32)level->start_x) * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
	player.y = ((((s32)level->start_y) * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
	player.a = ((u16)level->start_a) << FIXED_SHIFT;

	// doors
	doordata = &level->doors[0];
	for (int i=0; i<MAP_MAX_DOORS; ++i)
	{
		doorstate[i] = 0;
		doortimer[i] = 0;
	}

	// decompress map from rom -> ram
	u8* map_dst = map;
	const u8* map_src = level->plane0;
    int mapsize = 0;
    while (mapsize < (MAP_SIZE*MAP_SIZE))
    {
        u8 control_byte = *map_src++;
        u8 count = control_byte & 0x7F;
        mapsize += count;
        if (control_byte & (1<<7))
        {
            u8 d = *map_src++;
            for (int i=0; i<count; ++i)
                *map_dst++ = d;
        }
        else
        {
            for (int i=0; i<count; ++i)
                *map_dst++ = *map_src++;
        }
    }

    // initialize collision map
    volatile u32* colmap = (volatile u32*) COLMAP_ALIAS;
    for (int i=0; i<MAP_SIZE*MAP_SIZE; ++i)
    {
    	u8 tile = map[i];
    	u8 type = tile >> 6;
    	u8 idx  = tile & 0x3F;
    	if (type > 0)
    	{
			*colmap++ = 1;
    		if (type == 3)
    			level_stat_secret_max++;
    	}
    	else
    	{
    		if ((idx == 6) || (idx == 7))
    			level_stat_bonus_max++;

    		if (idx <= NUM_PICKUPS)		// pickups
    			*colmap++ = 0;
    		else if (idx == 15)			// bones
    			*colmap++ = 0;
    		else if (idx == 16)			// ceiling light
    			*colmap++ = 0;
    		else if (idx == 17)			// chandalier
    			*colmap++ = 0;
    		else if (idx == 21)			// basket
    			*colmap++ = 0;
    		else if (idx == 26)			// pool of water
    			*colmap++ = 0;
    		else if (idx == 37)			// pool of blood
    			*colmap++ = 0;
    		else if (idx == 63)			// victory trigger
    			*colmap++ = 0;
    		else if (idx == 62)			// secret elevator
    			*colmap++ = 0;
    		else if (idx == 61)			// elevator
    			*colmap++ = 0;
    		else if (idx == 60)			// dead guard
    			*colmap++ = 0;
    		else
    			*colmap++ = 1;
    	}
    }

    // initialize npcs
    wl_npc_init();

    colmap = (volatile u32*) COLMAP_ALIAS;
    for (int y=0; y<MAP_SIZE; ++y)
    {
    	for (int x=0; x<MAP_SIZE; ++x)
    	{
    		int offs = x + (y * MAP_SIZE);
        	u8 tile = map[offs];
        	u8 type = tile >> 6;
        	u8 idx  = tile & 0x3F;
        	if (type == 0)
        	{
				if ((idx >= NPC_MAP_IDX) && (idx < (NPC_MAP_IDX + NPC_TYPE_COUNT)))
				{
					u8 npc_type = idx - NPC_MAP_IDX;
					wl_npc_spawn(npc_type, x, y);
					map[offs] = 0;
					colmap[offs] = 0;
					level_stat_npc_max++;
				}
				else if (idx == 60)
				{
					wl_npc_spawn_dead(NPC_TYPE_GUARD, x, y);
					map[offs] = 0;
					colmap[offs] = 0;
				}
        	}
    	}
    }
}

