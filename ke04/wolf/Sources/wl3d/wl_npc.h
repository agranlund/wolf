/*
 * wl_npc.h
 *
 *  Created on: Dec 8, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_WL3D_WL_NPC_H_
#define SOURCES_WL3D_WL_NPC_H_

#include "../types.h"

#define NPC_MAP_IDX			48
#define MAP_MAX_NPCS		75

#define NPC_TYPE_DOG		0
#define NPC_TYPE_GUARD		1
#define NPC_TYPE_SS			2
#define NPC_TYPE_BOSS		3
#define NPC_TYPE_COUNT		4

#define NPC_STATE_REMOVED	0
#define NPC_STATE_DEAD		1
#define NPC_STATE_GUARD		2		// guard, react to sound and sight
#define NPC_STATE_AMBUSH	3		// same as guard, but do not react to sound
#define NPC_STATE_CHASE		4		// chase player
#define NPC_STATE_ATTACK	5		// attack player
#define NPC_STATE_DIE		6		// die
#define NPC_STATE_STUN		7		// stunned


struct npc_t
{
	u32		xpos 	: 12; 		// current xpos
	u32		ypos 	: 12;		// current ypos
	u32		tilex 	: 6;		// x tile
	u32		tiley 	: 6;		// y tile
	u32		type 	: 2;		// type
	u32		state 	: 3;		// state
	u32		counter : 6;		// state counter
	u32		tex		: 6;		// texture
	u32		health	: 8;		// health
	u32		dist	: 6;		// move distance
	u32		dir		: 4;		// move direction. clockwise. 0 = east.
	u32		stuncnt	: 4;		// stun counter
	u32		shotcnt : 4;
	u32		visible	: 1;		// visible
};

extern struct npc_t npcs[MAP_MAX_NPCS];
extern u8 num_npcs;

void wl_npc_init();
void wl_npc_update();
void wl_npc_spawn(u8 type, u8 x, u8 y);
void wl_npc_spawn_dead(u8 type, u8 x, u8 y);

void wl_npc_hurt(struct npc_t* npc, u8 points);

int  wl_npc_at(u8 x, u8 y);


#endif /* SOURCES_WL3D_WL_NPC_H_ */
