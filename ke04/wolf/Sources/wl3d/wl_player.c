/*
 * wl_player.c
 *
 *  Created on: Dec 4, 2016
 *      Author: agranlund
 */
#include "wl_player.h"
#include "wl_game.h"
#include "wl_hud.h"
#include "wl_npc.h"
#include "wl_draw.h"
#include "../types.h"
#include "../math.h"

#define JOYPAD_BUTTON_A			(1<<0)
#define JOYPAD_BUTTON_B			(1<<1)
#define JOYPAD_BUTTON_SELECT	(1<<2)
#define JOYPAD_BUTTON_START		(1<<3)
#define JOYPAD_BUTTON_LEFT		(1<<4)
#define JOYPAD_BUTTON_RIGHT		(1<<5)
#define JOYPAD_BUTTON_UP		(1<<6)
#define JOYPAD_BUTTON_DOWN		(1<<7)

#define EXTRALIFE_POINTS		40000
#define PLAYER_WALL_COL_SIZE	24
#define PLAYER_NPC_COL_SIZE		48

u8 joypad_old;
u8 weapon_frame;
u16 weapon_anim;
const u8 weapon_frames[5] = { 0, 1, 2, 3, 1 };
struct player_t player;
u32 next_extralife_points;

void wl_player_attack();

//----------------------------------------------------------------------------
// init player
//----------------------------------------------------------------------------
void wl_player_init()
{
	joypad_old = 0;

	weapon_anim = 0;
	weapon_frame = 0;

	player.score = 0;
	player.extralife_score = EXTRALIFE_POINTS;
	player.health = 100;
	player.weapon = 1;
	player.ammo = 8; //99;
	player.lives = 3;
	player.floor = 1;
	player.keys = 0;
	player.weapons = (1<<WPN_KNIFE) | (1<<WPN_GUN);// | (1<<WPN_GUN2) | (1<<WPN_GUN3);
}

//----------------------------------------------------------------------------
// update player
//----------------------------------------------------------------------------
void wl_player_update(u8 joypad)
{
	// update player
	s32 turn_speed = (2<<FIXED_SHIFT) + (1<<(FIXED_SHIFT-1));
	s32 player_dx = 0;
	s32 player_dy = 0;

	u8 joypad_trig = joypad & (joypad ^ joypad_old);

	// START - test
	if (joypad_trig & JOYPAD_BUTTON_START)
	{
		//wl_game_trigger_elevator(0);
		//wl_game_restart_map();
		//wl_game_trigger_victory();
	}

	// SELECT - change weapon
	if (joypad_trig & JOYPAD_BUTTON_SELECT)
	{
		if ((weapon_anim == 0) && (player.ammo > 0))
		{
			while (1)
			{
				player.weapon++;
				if (player.weapons & (1<<player.weapon))
				{
					wl_hud_SetWeapon(player.weapon);
					break;
				}
			}
		}
	}

	// A - fire weapon
	if (((player.weapon > WPN_GUN) && (joypad & JOYPAD_BUTTON_A)) || (joypad_trig & JOYPAD_BUTTON_A))
	{
		if ((weapon_anim == 0) && ((player.ammo > 0) || (player.weapon == WPN_KNIFE)))
		{
			weapon_anim = 1;
			weapon_frame = 0;
		}
	}

	// B - interact
	if (joypad_trig & JOYPAD_BUTTON_B)
	{
		wl_player_interact();
	}

	// Move
	if (joypad & JOYPAD_BUTTON_RIGHT)
	{
		if (joypad & JOYPAD_BUTTON_B)
		{
			player_dx += -math_sin(player.a);
			player_dy += -math_cos(player.a);
		}
		else
		{
			player.a += turn_speed;
		}
	}
	if (joypad & JOYPAD_BUTTON_LEFT)
	{
		if (joypad & JOYPAD_BUTTON_B)
		{
			player_dx += math_sin(player.a);
			player_dy += math_cos(player.a);
		}
		else
		{
			player.a -= turn_speed;
		}
	}

	if (joypad & JOYPAD_BUTTON_UP)
	{
		player_dx += math_cos(player.a);
		player_dy += -math_sin(player.a);
	}
	else if (joypad & JOYPAD_BUTTON_DOWN)
	{
		player_dx += -math_cos(player.a);
		player_dy += math_sin(player.a);
	}

	if (wl_player_move(player_dx, player_dy))
	{
		wl_player_check_pickups();
	}

	// update weapon anim
	if (weapon_anim > 0)
	{
		weapon_anim += (1<<7);
		if (weapon_anim >= (6<<8))
		{
			weapon_anim = 0;
		}
		else
		{
			if ((player.weapon == WPN_GUN2) || (player.weapon == WPN_GUN3))
			{
				if ((joypad & JOYPAD_BUTTON_A) && (weapon_anim >= (5<<8)))
				{
					weapon_anim = (2<<8) + (1<<6);
				}
			}
		}
	}

	u8 new_weapon_frame = weapon_frames[weapon_anim>>8];
	if (new_weapon_frame != weapon_frame)
	{
		weapon_frame = new_weapon_frame;
		wl_hud_SetWeaponFrame(weapon_frame);

		if ((weapon_frame == 2) || ((weapon_frame == 3) && (player.weapon == WPN_GUN3)))
		{
			wl_player_attack();
		}
	}

	joypad_old = joypad;
}

//----------------------------------------------------------------------------
// attack
//----------------------------------------------------------------------------
void wl_player_attack()
{
	wl_hud_PlaySound(SND_ATTACK_KNIFE + player.weapon);
	if (player.weapon != WPN_KNIFE)
	{
		player.ammo--;
		wl_hud_SetAmmo(player.ammo);
		if (player.ammo == 0)
		{
			player.weapon = WPN_KNIFE;
			weapon_frame = 0;
			weapon_anim = 0;
			wl_hud_SetWeapon(player.weapon);
			wl_hud_SetWeaponFrame(0);
		}
	}

	s32 px = player.x;
	s32 py = player.y;
	s32 pa = player.a;
	s32 maxty = (MAP_GRID_SIZE - (MAP_GRID_SIZE>>2)) << FIXED_SHIFT;

	s32 sina = math_sin(pa);
	s32 cosa = math_cos(pa);

	struct npc_t* npc_target = 0;
	s32 npc_dist = 0x7fffffff;

	for (int i=0; i<num_npcs; ++i)
	{
		struct npc_t* npc = &npcs[i];
		if (npc->visible == 0)
			continue;

		if ((npc->state <= NPC_STATE_DEAD) || (npc->state == NPC_STATE_DIE))
			continue;

		s32 nx = npc->xpos << FIXED_SHIFT;
		s32 ny = npc->ypos << FIXED_SHIFT;
		s32 dx = nx - px;
		s32 dy = ny - py;

	    s32 ty = (((dx) * sina) >> FIXED_SHIFT) + (((dy) * cosa) >> FIXED_SHIFT);
	    if ((ty > maxty) || (ty < -maxty))
	    	continue;

	    s32 tx = (((dx) * cosa) >> FIXED_SHIFT) - (((dy) * sina) >> FIXED_SHIFT);
	    if ((tx < 0) || (tx > npc_dist))
	    	continue;

		npc_dist = tx;
		npc_target = npc;
	}

	if (npc_target == 0)
		return;


	if (player.weapon == WPN_KNIFE)
	{
		// stab
		s32 dx = (npc_target->xpos) - (px >> (FIXED_SHIFT));
		s32 dy = (npc_target->ypos) - (py >> (FIXED_SHIFT));
		if (dx < 0) dx = -dx;
		if (dy < 0) dy = -dy;
		s32 dist = (dx > dy) ? dx : dy;
		if (dist > (MAP_GRID_SIZE + (MAP_GRID_SIZE>>1)))
			return;

		u8 dmg = (math_random() & 0xFF) >> 5;
		if (dmg == 0)
			dmg = 1;
		wl_npc_hurt(npc_target, dmg);
	}
	else
	{
		// shoot
		s32 dx = (npc_target->xpos >> MAP_GRID_SHIFT) - (px >> (FIXED_SHIFT + MAP_GRID_SHIFT));
		s32 dy = (npc_target->ypos >> MAP_GRID_SHIFT) - (py >> (FIXED_SHIFT + MAP_GRID_SHIFT));
		if (dx < 0) dx = -dx;
		if (dy < 0) dy = -dy;
		s32 dist = (dx > dy) ? dx : dy;

		u8 dmg = math_random() & 0xFF;
		if (dist < 2)
			dmg = dmg >> 2;
		else if (dist < 4)
			dmg = dmg / 6;
		else
		{
			if ((dmg / 12) < dist)
				return;
			dmg = dmg / 6;
		}

		dmg >>= 1;
		if (dmg == 0)
			dmg = 1;

		wl_npc_hurt(npc_target, dmg);
	}
}

//----------------------------------------------------------------------------
// test npc collision
//----------------------------------------------------------------------------
int wl_player_check_col()
{
	// check against map
	s32 xpos = player.x >> FIXED_SHIFT;
	s32 ypos = player.y >> FIXED_SHIFT;
	s32 xt0 = (xpos - PLAYER_WALL_COL_SIZE) >> MAP_GRID_SHIFT;
	s32 xt1 = (xpos + PLAYER_WALL_COL_SIZE) >> MAP_GRID_SHIFT;
	s32 yt0 = (ypos - PLAYER_WALL_COL_SIZE) >> MAP_GRID_SHIFT;
	s32 yt1 = (ypos + PLAYER_WALL_COL_SIZE) >> MAP_GRID_SHIFT;
	volatile u32* colmap = (volatile u32*) COLMAP_ALIAS;
	for (int y=yt0; y<=yt1; ++y)
		for (int x=xt0; x<=xt1; ++x)
			if (colmap[x + (y * MAP_SIZE)] != 0)
				return 1;


	// check against npcs
	for (int i=0; i<num_npcs; ++i)
	{
		struct npc_t* npc = &npcs[i];
		if (npc == 0)
			continue;

		if ((npc->state <= NPC_STATE_DEAD) || (npc->state == NPC_STATE_DIE))
			continue;

		s32 dx = npc->xpos - xpos;
		if (dx < -PLAYER_NPC_COL_SIZE || dx > PLAYER_NPC_COL_SIZE)
			continue;

	    s32 dy = npc->ypos - ypos;
	    if (dy < -PLAYER_NPC_COL_SIZE || dy > PLAYER_NPC_COL_SIZE)
	    	continue;

		return 1;
	}
	return 0;
}

//----------------------------------------------------------------------------
// move
//----------------------------------------------------------------------------
int wl_player_move(s32 dx, s32 dy)
{
	s32 oldx = player.x;
	s32 oldy = player.y;

	s32 move_speed = (8<<FIXED_SHIFT);
	s32 movex = (dx * move_speed) >> FIXED_SHIFT;
	s32 movey = (dy * move_speed) >> FIXED_SHIFT;

	player.x = oldx + movex;
	player.y = oldy + movey;
	if (wl_player_check_col() == 0)
		return 1;

	player.x = oldx + movex;
	player.y = oldy;
	if (wl_player_check_col() == 0)
		return 1;

	player.x = oldx;
	player.y = oldy + movey;
	if (wl_player_check_col() == 0)
		return 1;

	player.x = oldx;
	player.y = oldy;
	return 0;
}

//----------------------------------------------------------------------------
// loose hp
//----------------------------------------------------------------------------
int wl_player_hurt(int points)
{
	if (wl_cheat_godmode)
	{
		wl_hud_TakeDamage();
		return 0;
	}

	if (player.health > 0)
	{
		int health = player.health;
		health -= points;
		if (health <= 0)
		{
			health = 0;
		}
		player.health = health;
		wl_hud_SetHealth(player.health);
		wl_hud_TakeDamage();
		return 1;
	}
	return 0;
}

//----------------------------------------------------------------------------
// gain hp
//----------------------------------------------------------------------------
int wl_player_give_health(int points)
{
	if (player.health < 100)
	{
		player.health += points;
		if (player.health > 100)
			player.health = 100;
		return 1;
	}
	return 0;
}

//----------------------------------------------------------------------------
// gain ammo
//----------------------------------------------------------------------------
int wl_player_give_ammo(int points)
{
	if (player.ammo < 99)
	{
		player.ammo += points;
		if (player.ammo > 99)
			player.ammo = 99;
		return 1;
	}
	return 0;
}

//----------------------------------------------------------------------------
// gain weapon
//----------------------------------------------------------------------------
int wl_player_give_weapon(int weapon)
{
	wl_player_give_ammo(6);
	player.weapons |= (1 << weapon);
	if (player.weapon < weapon)
	{
		player.weapon = weapon;
		weapon_anim = 0;
		weapon_frame = 0;
	}
	return 1;
}

//----------------------------------------------------------------------------
// gain points
//----------------------------------------------------------------------------
int wl_player_give_points(int points)
{
	player.score += points;
	int lives = player.lives;

	while (player.score >= player.extralife_score)
	{
		player.extralife_score += EXTRALIFE_POINTS;
		if (player.lives < 9)
			player.lives++;
	}
	if (player.lives != lives)
	{
		wl_hud_PlaySound(SND_PICKUP_EXTRALIFE);
		wl_hud_SetLives(player.lives);
		return 0;
	}
	return 1;
}


//----------------------------------------------------------------------------
// interact with world
//----------------------------------------------------------------------------
void wl_player_interact()
{
	s32 tilex = (player.x >> (FIXED_SHIFT + MAP_GRID_SHIFT));
	s32 tiley = (player.y >> (FIXED_SHIFT + MAP_GRID_SHIFT));
	u32 offs = tilex + (tiley * MAP_SIZE);
	u8 curtile = map[offs];

	u16 ang = player.a;
	if ((ang < ANG_45) || (ang > (ANG_270+ANG_45)))
		tilex++;
	else if (ang < (ANG_90+ANG_45))
		tiley--;
	else if (ang < (ANG_180+ANG_45))
		tilex--;
	else if (ang < (ANG_270+ANG_45))
		tiley++;

	offs = tilex + (tiley * MAP_SIZE);
	u8 tile = map[offs];
	u8 type = tile >> 6;
	u8 idx = tile & 0x3F;
	if (type == 1)
	{
		// elevator
		if ((idx == 16) && ((curtile == 61) || (curtile == 62)))
		{
			wl_game_trigger_elevator(curtile - 61);
		}
	}
	if (type == 2)
	{
		// door
		u8 action = doorstate[idx] >> 6;
		if ((action == 0) || (action == 3))
		{
			u8 lock = (doordata[idx] >> 3) & 0x3;
			if (lock && ((lock & player.keys) == 0))
			{
				wl_hud_PlaySound(SND_LOCKED_DOOR);
			}
			else
			{
				doorstate[idx] = (doorstate[idx] & 0x3F) | (1 << 6);
				wl_hud_PlaySound(SND_OPEN_DOOR);
			}
		}
	}
	else if (type == 3)
	{
		// secret wall
		volatile u32* colmap = (volatile u32*) COLMAP_ALIAS;
		map[offs] = 0;
		colmap[offs] = 0;
		wl_hud_PlaySound(SND_OPEN_SECRET);
		level_stat_secret++;
	}

}

//----------------------------------------------------------------------------
// check collision against pickups
//----------------------------------------------------------------------------
void wl_player_check_pickups()
{
	int tilex = player.x >> (FIXED_SHIFT + MAP_GRID_SHIFT);
	int tiley = player.y >> (FIXED_SHIFT + MAP_GRID_SHIFT);
	int offs = tilex + (tiley * MAP_SIZE);
	u8 tile = map[offs];
	if ((tile >> 6) == 0)
	{
		tile &= 0x3F;
		if ((tile != 0) && (tile <= NUM_PICKUPS))
		{
			switch (tile)
			{
			case 1:		// dog food
				if (wl_player_give_health(4))
				{
					wl_hud_PlaySound(SND_PICKUP_DOGFOOD);
					wl_hud_SetHealth(player.health);
					map[offs] = 0;
				}
				break;
			case 2:		// food
				if (wl_player_give_health(10))
				{
					wl_hud_PlaySound(SND_PICKUP_FOOD);
					wl_hud_SetHealth(player.health);
					map[offs] = 0;
				}
				break;
			case 3:		// first aid
				if (wl_player_give_health(25))
				{
					wl_hud_PlaySound(SND_PICKUP_MEDKIT);
					wl_hud_SetHealth(player.health);
					map[offs] = 0;
				}
				break;
			case 4:		// extra life
			{
				int used = 0;
				if (player.lives < 9)
				{
					player.lives++;
					used |= 1;
				}
				used |= wl_player_give_health(99);
				used |= wl_player_give_ammo(25);
				if (used)
				{
					wl_hud_PlaySound(SND_PICKUP_EXTRALIFE);
					wl_hud_SetHealth(player.health);
					wl_hud_SetLives(player.lives);
					wl_hud_SetAmmo(player.ammo);
					map[offs] = 0;
				}
			}
			break;
			case 5:		// ammo
				if (wl_player_give_ammo(8))
				{
					wl_hud_PlaySound(SND_PICKUP_AMMO);
					wl_hud_SetAmmo(player.ammo);
					map[offs] = 0;
				}
				break;
			case 6:		// bonus 1
				level_stat_bonus++;
				if (wl_player_give_points(250))
					wl_hud_PlaySound(SND_PICKUP_BONUS1);
				map[offs] = 0;
				break;
			case 7:		// bonus 2
				level_stat_bonus++;
				if (wl_player_give_points(1000))
					wl_hud_PlaySound(SND_PICKUP_BONUS2);
				map[offs] = 0;
				break;
			case 8:		// machinegun
				wl_hud_PlaySound(SND_PICKUP_GUN);
				wl_player_give_weapon(WPN_GUN2);
				wl_hud_SetAmmo(player.ammo);
				wl_hud_SetWeapon(player.weapon);
				wl_hud_SetWeaponFrame(0);
				wl_hud_SetGuns(player.weapons);
				map[offs] = 0;
				break;
			case 9:		// minigun
				wl_hud_PlaySound(SND_PICKUP_GUN);
				wl_player_give_weapon(WPN_GUN3);
				wl_hud_SetAmmo(player.ammo);
				wl_hud_SetWeapon(player.weapon);
				wl_hud_SetWeaponFrame(0);
				wl_hud_SetGuns(player.weapons);
				map[offs] = 0;
				break;
			case 10:	// gold key
				player.keys |= 1;
				wl_hud_PlaySound(SND_PICKUP_KEY);
				wl_hud_SetKeys(player.keys);
				map[offs] = 0;
				break;
			case 11:	// silver key
				player.keys |= 2;
				wl_hud_PlaySound(SND_PICKUP_KEY);
				wl_hud_SetKeys(player.keys);
				map[offs] = 0;
				break;
			case 12:	// small ammo
				if (wl_player_give_ammo(4))
				{
					wl_hud_PlaySound(SND_PICKUP_AMMO);
					wl_hud_SetAmmo(player.ammo);
					map[offs] = 0;
				}
				break;
			}
		}
		else if (tile == 63)
		{
			wl_game_trigger_victory();
		}
	}
}



