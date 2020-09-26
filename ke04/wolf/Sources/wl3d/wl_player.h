/*
 * wl_player.h
 *
 *  Created on: Dec 4, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_WL3D_WL_PLAYER_H_
#define SOURCES_WL3D_WL_PLAYER_H_
#include "../types.h"


struct player_t
{
	s32 score;
	s32 extralife_score;
	s32	x;
	s32	y;
	u16	a;
	u8 health;
	u8 lives;
	u8 floor;
	u8 keys;
	u8 ammo;
	u8 weapon;
	u8 weapons;
};
extern struct player_t player;

extern void wl_player_init();
extern void wl_player_update(u8 joypad);

extern void wl_player_interact();
extern void wl_player_check_pickups();

extern int wl_player_move(s32 dx, s32 dy);
extern int wl_player_hurt(int points);
extern int wl_player_give_health(int points);
extern int wl_player_give_ammo(int points);
extern int wl_player_give_weapon(int weapon);
extern int wl_player_give_points(int points);


#endif /* SOURCES_WL3D_WL_PLAYER_H_ */
