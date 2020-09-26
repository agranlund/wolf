/*
 * wl_npc.c
 *
 *  Created on: Dec 8, 2016
 *      Author: agranlund
 */

#include "wl_npc.h"
#include "wl_game.h"
#include "wl_player.h"
#include "wl_hud.h"
#include "../math.h"

#define NPC_FRAME_STAND			0
#define NPC_FRAME_WALK_0		1
#define NPC_FRAME_WALK_1		2
#define NPC_FRAME_DIE_0			3
#define NPC_FRAME_DIE_1			4
#define NPC_FRAME_DEAD			5
#define NPC_FRAME_ATTACK_0		6
#define NPC_FRAME_ATTACK_1		7
#define NPC_FRAME_STUN			8
#define NPC_FRAME_COUNT			9

#define NPC_DIR_E				0
#define NPC_DIR_N				2
#define NPC_DIR_W				4
#define NPC_DIR_S				6
#define NPC_DIR_NE				1
#define NPC_DIR_NW				3
#define NPC_DIR_SW				5
#define NPC_DIR_SE				7

#define NPC_MAX_CHASE_TILES		15
#define NPC_MAX_GUARD_TILES		 8
#define NPC_MIN_PLAYER_DIST		64
#define NPC_DOG_ATTACK_DIST		72


const u8 npc_frame_textures[NPC_FRAME_COUNT * 4] =
{
		0, 0, 1, 2, 3, 4, 5, 6, 0,				// dog
		12, 7, 8, 9, 10, 11, 12, 13, 14,		// guard
		20, 15, 16, 17, 18, 19, 20, 21, 22,		// ss
		20, 15, 16, 17, 18, 19, 20, 21, 22,		// boss
};

const u8 npc_start_health[4] =
{
		1,				// dog
		12,				// guard
		50,				// ss
		200,			// boss
};

const s8 npc_dir_speedx[8] = {  1,  1,  0, -1, -1, -1,  0,  1 };
const s8 npc_dir_speedy[8] = {  0, -1, -1, -1,  0,  1,  1,  1 };

const s8 npc_dir_diagonal[4][4] =
{//    e,  n,  w,  s
	{ -1,  1, -1,  7 },	// e
	{  1, -1,  3, -1 },	// n
	{ -1,  3, -1,  5 }, // w
	{  7, -1,  5, -1 }, // s
};

static inline u8 wl_npc_get_texture(u8 type, u8 frame)
{
	return npc_frame_textures[(type * NPC_FRAME_COUNT) + frame];
}

static inline void wl_npc_setstate(struct npc_t* npc, u8 state)
{
	npc->state = state;
	npc->counter = 0;
	if ((state == NPC_STATE_GUARD) || (state == NPC_STATE_AMBUSH))
	{
		// delay before allowed to shoot at player
		npc->shotcnt = (math_random() & 0xFF) >> 6;
	}
}

void wl_npc_state_guard(struct npc_t* npc, u32 npcframe);
void wl_npc_state_chase(struct npc_t* npc, u32 npcframe);
void wl_npc_state_attack(struct npc_t* npc, u32 npcframe);
void wl_npc_state_die(struct npc_t* npc, u32 npcframe);
void wl_npc_state_stun(struct npc_t* npc, u32 npcframe);


struct npc_t npcs[MAP_MAX_NPCS];
u8 num_npcs;

void wl_npc_init()
{
	num_npcs = 0;
}

void wl_npc_update()
{
	for (int i=0; i<num_npcs; ++i)
	{
		struct npc_t* npc = &npcs[i];
		if (npc->state <= NPC_STATE_DEAD)
			continue;

		if (npc->stuncnt > 0)
			npc->stuncnt--;

		u32 npcframe = gameframe + i;
		if (npc->state != NPC_STATE_CHASE)
		{
			if ((npcframe & 3) != 0)
				continue;
		}

		switch (npc->state)
		{
			case NPC_STATE_GUARD:
			case NPC_STATE_AMBUSH:
				wl_npc_state_guard(npc, npcframe);
				break;

			case NPC_STATE_CHASE:
				wl_npc_state_chase(npc, npcframe);
				break;

			case NPC_STATE_ATTACK:
				wl_npc_state_attack(npc, npcframe);
				break;

			case NPC_STATE_DIE:
				wl_npc_state_die(npc, npcframe);
				break;

			case NPC_STATE_STUN:
				wl_npc_state_stun(npc, npcframe);
				break;
		}
		npc->counter++;
	}
}


void wl_npc_spawn(u8 type, u8 x, u8 y)
{
	if (num_npcs >= MAP_MAX_NPCS)
		return;

	struct npc_t* npc = &npcs[num_npcs];
	npc->xpos 		= (x << MAP_GRID_SHIFT) + (MAP_GRID_SIZE >> 1);
	npc->ypos 		= (y << MAP_GRID_SHIFT) + (MAP_GRID_SIZE >> 1);
	npc->tilex 		= x;
	npc->tiley 		= y;
	npc->state 		= NPC_STATE_GUARD;
	npc->counter 	= 0;
	npc->type  		= type;
	npc->tex   		= wl_npc_get_texture(type, NPC_FRAME_STAND);
	npc->health 	= npc_start_health[type];
	npc->dist		= 0;
	npc->dir		= 0;
	npc->stuncnt	= 0;
	npc->visible	= 0;
	num_npcs++;
}

void wl_npc_spawn_dead(u8 type, u8 x, u8 y)
{
	if (num_npcs >= MAP_MAX_NPCS)
		return;

	struct npc_t* npc = &npcs[num_npcs];
	npc->xpos 		= (x << MAP_GRID_SHIFT) + (MAP_GRID_SIZE >> 1);
	npc->ypos 		= (y << MAP_GRID_SHIFT) + (MAP_GRID_SIZE >> 1);
	npc->tilex 		= x;
	npc->tiley 		= y;
	npc->state 		= NPC_STATE_DEAD;
	npc->counter 	= 0;
	npc->type  		= type;
	npc->tex   		= wl_npc_get_texture(type, NPC_FRAME_DEAD);
	npc->health 	= npc_start_health[type];
	npc->dist		= 0;
	npc->dir		= 0;
	npc->stuncnt	= 0;
	num_npcs++;
}

void wl_npc_alert(struct npc_t* npc)
{
	u8 snd = SND_NPC_DOG_ALERT + (npc->type << 2);
	wl_hud_PlaySound(snd);
	wl_npc_setstate(npc, NPC_STATE_CHASE);
}

void wl_npc_hurt(struct npc_t* npc, u8 points)
{
	if ((npc->state == NPC_STATE_GUARD) || (npc->state == NPC_STATE_AMBUSH))
		wl_npc_alert(npc);

	// todo: notify nearby npcs

	int hp = npc->health;
	hp -= points;
	if (hp <= 0)
	{
		npc->health = 0;
		wl_npc_setstate(npc, NPC_STATE_DIE);
	}
	else
	{
		npc->health = hp;
		if (npc->type != NPC_TYPE_DOG)
		{
			if (npc->stuncnt == 0)
			{
				npc->stuncnt = 12;
				wl_npc_setstate(npc, NPC_STATE_STUN);
			}
		}
	}
}

int wl_npc_at(u8 x, u8 y)
{
	for (int i=0; i<num_npcs; ++i)
		if ((npcs[i].state > NPC_STATE_DEAD) && (npcs[i].tilex == x) && (npcs[i].tiley == y))
			return i;
	return -1;
}

int wl_npc_lineofsight(int x0, int y0, int x1, int y1)
{
	#define NPC_LOS_STEP 2

	x0 >>= (MAP_GRID_SHIFT - NPC_LOS_STEP);
	y0 >>= (MAP_GRID_SHIFT - NPC_LOS_STEP);
	x1 >>= (MAP_GRID_SHIFT - NPC_LOS_STEP);
	y1 >>= (MAP_GRID_SHIFT - NPC_LOS_STEP);

	if ((x0 == x1) && (y0 == y1))
		return 1;

	int dx = x1 - x0;
	int dy = y1 - y0;
	int sx = 1;
	int sy = 1;
	if (dx < 0)
	{
		dx = -dx;
		sx = -sx;
	}
	if (dy < 0)
	{
		dy = -dy;
		sy = -sy;
	}
	int err = ((dx > dy) ? dx : -dy) >> 1;
	int e2;
	for(;;)
	{
		if ((x0 == x1) && (y0 == y1))
			return 1;

		e2 = err;
		if (e2 >-dx)
		{
			err -= dy;
			x0 += sx;
		}
		if (e2 < dy)
		{
			err += dx;
			y0 += sy;
		}

		int xt = x0 >> NPC_LOS_STEP;
		int yt = y0 >> NPC_LOS_STEP;

		int offs = xt + (yt * MAP_SIZE);
		u8 tile = map[offs];
		u8 type = tile >> 6;
		if (type != 0)
		{
			volatile u32* colmap = (volatile u32*) COLMAP_ALIAS;
			if (colmap[offs] != 0)
				return 0;
		}
	}
}



void wl_npc_state_guard(struct npc_t* npc, u32 npcframe)
{
	npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_STAND);

	int nx = npc->xpos;
	int ny = npc->ypos;
	int px = player.x >> FIXED_SHIFT;
	int py = player.y >> FIXED_SHIFT;

	int dx = (px > nx) ? px - nx : nx - px;
	int dy = (py > ny) ? py - ny : ny - py;
	int dist = (dx > dy) ? dx : dy;

	if (dist > (NPC_MAX_GUARD_TILES << MAP_GRID_SHIFT))
		return;

	if (wl_npc_lineofsight(nx, ny, px, py))
		wl_npc_alert(npc);
}

int wl_npc_trymove(struct npc_t* npc, s8 dir)
{
	u8 tx = npc->tilex;
	u8 ty = npc->tiley;
	switch (dir)
	{
	case NPC_DIR_E:
		tx++;
		break;
	case NPC_DIR_NE:
		tx++;
		ty--;
		break;
	case NPC_DIR_N:
		ty--;
		break;
	case NPC_DIR_NW:
		tx--;
		ty--;
		break;
	case NPC_DIR_W:
		tx--;
		break;
	case NPC_DIR_SW:
		tx--;
		ty++;
		break;
	case NPC_DIR_S:
		ty++;
		break;
	case NPC_DIR_SE:
		tx++;
		ty++;
		break;
	default:
		return 0;
		break;
	}

	volatile u32* colmap = (volatile u32*) COLMAP_ALIAS;
	int offs = tx + (ty * MAP_SIZE);
	if (colmap[offs] == 1)
		return 0;

	if (dir & 1)
	{
		if (colmap[tx + (npc->tiley * MAP_SIZE)] == 1)
			return 0;
		if (colmap[npc->tilex + (ty * MAP_SIZE)] == 1)
			return 0;
	}

	if (wl_npc_at(tx, ty) >= 0)
		return 0;

	npc->dir = dir;
	npc->dist = 63;
	npc->tilex = tx;
	npc->tiley = ty;
	return 1;
}

void wl_npc_state_chase(struct npc_t* npc, u32 npcframe)
{
	// attack player
	s32 dx = (player.x >> FIXED_SHIFT) - npc->xpos;
	s32 dy = (player.y >> FIXED_SHIFT) - npc->ypos;
	if (dx < 0) dx = -dx;
	if (dy < 0) dy = -dy;
	s32 dist = (dx > dy) ? dx : dy;
	u8 nomove = 0;

	if (npc->type == NPC_TYPE_DOG)
	{
		if (dist < NPC_DOG_ATTACK_DIST)
		{
			wl_npc_setstate(npc, NPC_STATE_ATTACK);
		}
	}
	else if (npc->shotcnt == 0)
	{
		s32 tiledist = dist >> MAP_GRID_SHIFT;
		s32 chance = 256;
		if (tiledist > 1)
			chance = math_one_over(tiledist<<2) >> (FIXED_SHIFT + 1);
		if ((math_random() & 0xFF) < chance)
		{
			if (wl_npc_lineofsight(npc->xpos, npc->ypos, player.x >> FIXED_SHIFT, player.y >> FIXED_SHIFT) != 0)
			{
				wl_npc_setstate(npc, NPC_STATE_ATTACK);
				return;
			}
		}
	}
	if (npc->shotcnt > 0)
		npc->shotcnt--;

	// choose target tile to move to
	if ((npc->dist == 0) && (nomove == 0))
	{
		int player_tile_x = player.x >> (FIXED_SHIFT + MAP_GRID_SHIFT);
		int player_tile_y = player.y >> (FIXED_SHIFT + MAP_GRID_SHIFT);
		int dx = player_tile_x - npc->tilex;
		int dy = player_tile_y - npc->tiley;
		int absdx = (dx < 0) ? -dx : dx;
		int absdy = (dy < 0) ? -dy : dy;

		if ((absdx > NPC_MAX_CHASE_TILES) || (absdy > NPC_MAX_CHASE_TILES))
		{
			wl_npc_setstate(npc, NPC_STATE_GUARD);
			return;
		}

		s8 dirs[5];
		s8 temp;

		if (dx > 0)
		{
			dirs[1] = NPC_DIR_E;
			dirs[3] = NPC_DIR_W;
		}
		else
		{
			dirs[1] = NPC_DIR_W;
			dirs[3] = NPC_DIR_E;
		}
		if (dy > 0)
		{
			dirs[2] = NPC_DIR_S;
			dirs[4] = NPC_DIR_N;
		}
		else
		{
			dirs[2] = NPC_DIR_N;
			dirs[4] = NPC_DIR_S;
		}
		if (absdx > absdy)
		{
			temp = dirs[1]; dirs[1] = dirs[2]; dirs[2] = temp;
			temp = dirs[3]; dirs[3] = dirs[4]; dirs[4] = temp;
		}
		u8 rand = math_random() & 0xFF;
		if (rand < 128)
		{
			temp = dirs[1]; dirs[1] = dirs[2]; dirs[2] = temp;
			temp = dirs[3]; dirs[3] = dirs[4]; dirs[4] = temp;
		}

		dirs[0] = npc_dir_diagonal[dirs[1]>>1][dirs[2]>>1];
		for (int i=0; i<5; ++i)
		{
			if (wl_npc_trymove(npc, dirs[i]) == 1)
			{
				break;
			}
		}
	}

	// move
	int moving = 0;
	if (npc->dist > 0)
	{
		int dist = npc->dist;
		u8 speed = (npc->type == NPC_TYPE_DOG) ? 4 : 3;
		int newx = npc->xpos + (speed * npc_dir_speedx[npc->dir]);
		int newy = npc->ypos + (speed * npc_dir_speedy[npc->dir]);

		// check collision with player
		int dx = (player.x >> FIXED_SHIFT) - newx;
		int dy = (player.y >> FIXED_SHIFT) - newy;
		if (dx < 0) dx = -dx;
		if (dy < 0) dy = -dy;
		if (!((dx < NPC_MIN_PLAYER_DIST) && (dy < NPC_MIN_PLAYER_DIST)))
		{
			moving = 1;
			npc->xpos = newx;
			npc->ypos = newy;
			dist -= speed;
			if (dist <= 0)
			{
				dist = 0;
				npc->xpos = (npc->xpos & ~MAP_GRID_MASK) + (MAP_GRID_SIZE >> 1);
				npc->ypos = (npc->ypos & ~MAP_GRID_MASK) + (MAP_GRID_SIZE >> 1);
			}
		}
		npc->dist = dist;
	}

	// animate
	if (moving == 0)
		npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_STAND);
	else if ((npcframe & 15) < 8)
		npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_WALK_0);
	else
		npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_WALK_1);

}

void wl_npc_shoot(struct npc_t* npc, int dmgshift)
{
	int px = player.x >> FIXED_SHIFT;
	int py = player.y >> FIXED_SHIFT;
	int nx = npc->xpos;
	int ny = npc->ypos;
	int dx = (px > nx) ? px - nx : nx - px;
	int dy = (py > ny) ? py - ny : ny - py;
	int dist = (dx > dy) ? dx : dy;

	u8 points = 0;
	if (npc->type == NPC_TYPE_DOG)
	{
		if (dist < NPC_DOG_ATTACK_DIST)
		{
			if ((math_random() & 0xFF) < 180)
			{
				points = (math_random() & 0xFF) >> (4 + dmgshift);
				if (points == 0)
					points = 1;
			}
		}
	}
	else
	{
		dist >>= MAP_GRID_SHIFT;
		int hitchance = 256;
		if ((npc->type == NPC_TYPE_SS) || (npc->type == NPC_TYPE_BOSS))
			dist = dist - (dist>>2);

		// todo: reduce hit chance if guard is visible by player
		hitchance -= dist * 16;
		//hitchance -= dist * 8;
		if ((math_random() & 0xFF) < hitchance)
		{
			points = (math_random() & 0xFF) >> dmgshift;
			if (dist < 2)
				points >>= 2;
			else if (dist < 4)
				points >>= 3;
			else
				points >>= 4;

			if (points == 0)
				points = 1;
		}
	}

	u8 snd = SND_NPC_DOG_ATTACK + (npc->type << 2);
	wl_hud_PlaySound(snd);

	if (points > 0)
		wl_player_hurt(points);
}

void wl_npc_state_attack(struct npc_t* npc, u32 npcframe)
{
	if (npc->type == NPC_TYPE_DOG)
	{
		switch (npc->counter)
		{
		case 0:
			npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_ATTACK_0);
			break;
		case 1:
			npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_ATTACK_1);
			break;
		case 3:
			npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_ATTACK_0);
			wl_npc_shoot(npc, 0);
			break;
		case 4:
			wl_npc_setstate(npc, NPC_STATE_CHASE);
			break;
		}
	}
	else
	{
		switch (npc->counter)
		{
		case 0:
			npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_ATTACK_0);
			break;
		case 2:
			npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_ATTACK_1);
			break;
		case 3:
			if ((npc->type == NPC_TYPE_SS) || (npc->type == NPC_TYPE_BOSS))
				wl_npc_shoot(npc, 1);
			else
				wl_npc_shoot(npc, 0);
			break;
		case 4:
			if (npc->type == NPC_TYPE_BOSS)
				wl_npc_shoot(npc, 1);
			break;
		case 5:
			npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_ATTACK_0);
			if ((npc->type == NPC_TYPE_SS) || (npc->type == NPC_TYPE_BOSS))
				wl_npc_shoot(npc, 1);
			break;
		case 8:
			wl_npc_setstate(npc, NPC_STATE_CHASE);
			break;
		}
	}
}

void wl_npc_state_die(struct npc_t* npc, u32 npcframe)
{
	npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_DIE_0 + npc->counter);
	if (npc->counter == 0)
	{
		u8 snd = SND_NPC_DOG_DIE + (npc->type << 2);
		wl_hud_PlaySound(snd);
	}
	if (npc->counter >= 2)
	{
		wl_npc_setstate(npc, NPC_STATE_DEAD);
		npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_DEAD);
		level_stat_npc++;

		if (npc->type == NPC_TYPE_DOG)
		{
			wl_player_give_points(200);
			return;
		}

		u8 tx = npc->xpos >> MAP_GRID_SHIFT;
		u8 ty = npc->ypos >> MAP_GRID_SHIFT;
		s32 offs = tx + (ty * MAP_SIZE);

		switch (npc->type)
		{
		case NPC_TYPE_DOG:
			wl_player_give_points(200);
			break;
		case NPC_TYPE_GUARD:
			wl_player_give_points(100);
			if (map[offs] == 0)
				map[offs] = 12;	// small ammo
			break;
		case NPC_TYPE_SS:
			wl_player_give_points(500);
			if (map[offs] == 0)
			{
				if ((player.weapons & (1<<WPN_GUN2)) == 0)
					map[offs] = 8;	// machine gun
				else
					map[offs] = 12;	// small ammo
			}
			break;
		case NPC_TYPE_BOSS:
			{
				wl_player_give_points(5000);

				int key_spawned = 0;

				if ((map[offs] >> 2) == 0)
					map[offs] = 10;
				else if ((map[offs - MAP_SIZE] >> 2) == 0)
					map[offs - MAP_SIZE] = 10;
				else if ((map[offs + MAP_SIZE] >> 2) == 0)
					map[offs + MAP_SIZE] = 10;
				else
				{
					// give key directly if there is no space to drop it
					player.keys |= 1;
					wl_hud_PlaySound(SND_PICKUP_KEY);
					wl_hud_SetKeys(player.keys);
				}
				break;
			}
		}
	}
}

void wl_npc_state_stun(struct npc_t* npc, u32 npcframe)
{
	npc->tex = wl_npc_get_texture(npc->type, NPC_FRAME_STUN);
	wl_npc_setstate(npc, NPC_STATE_CHASE);
}

