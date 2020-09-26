/*
 * wl_game.h
 *
 *  Created on: Nov 12, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_WL3D_WL_GAME_H_
#define SOURCES_WL3D_WL_GAME_H_

#include "wl_player.h"
#include "../gfx.h"

#define MAP_SIZE        		64
#define MAP_GRID_SIZE       	64
#define MAP_GRID_MASK       	(MAP_GRID_SIZE-1)
#define MAP_GRID_SHIFT  	 	6
#define MAP_MAX_DOORS			48

#define WPN_KNIFE				0
#define WPN_GUN					1
#define WPN_GUN2				2
#define	WPN_GUN3				3

#define NUM_PICKUPS				12

#define	COLMAP_ADDR				0x20002E00
#define COLMAP_ALIAS			GFX_ADDR_TO_ALIAS(COLMAP_ADDR)

extern u8			map[MAP_SIZE * MAP_SIZE];
extern u8			doorstate[MAP_MAX_DOORS];
extern const u32* 	doordata;
extern u32			gameframe;

extern u32 level_stat_npc;
extern u32 level_stat_npc_max;
extern u32 level_stat_bonus;
extern u32 level_stat_bonus_max;
extern u32 level_stat_secret;
extern u32 level_stat_secret_max;

extern u8 wl_cheat_godmode;

// doorstate:
// xxyyyyyy
// x = action (0: inactive, 1: opening, 2: waiting, 3: closing)
// y = counter

// doordata:
// xxxxxyyyyyalliii
// x = xpos
// y = ypos
// a = orientation (1: horizontal, 0: vertical)
// l = lock (0-3)
// i = gfx (0-7)


void wl_game_init(u8 floor, u8 godmode, u8 allwpn);
void wl_game_update(u8 joypad);
void wl_game_restart_map();
void wl_game_die();
void wl_game_trigger_elevator(u8 secret);
void wl_game_trigger_victory();

#endif /* SOURCES_WL3D_WL_GAME_H_ */
