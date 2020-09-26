/*
 * wl_hud.h
 *
 *  Created on: Nov 27, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_WL3D_WL_HUD_H_
#define SOURCES_WL3D_WL_HUD_H_

#include "../types.h"

#define SND_ATTACK_KNIFE		0x00
#define SND_ATTACK_GUN			0x01
#define SND_ATTACK_GUN2			0x02
#define SND_ATTACK_GUN3			0x03
#define SND_TAKE_DAMAGE			0x04
#define SND_OPEN_DOOR			0x05
#define SND_OPEN_SECRET			0x06
#define SND_TOGGLE_SWITCH		0x07
#define SND_SCORE_COUNTER		0x08
#define SND_INTERACT_NOTHING	0x09
#define SND_LOCKED_DOOR			0x0A

#define SND_PICKUP_AMMO			0x10
#define SND_PICKUP_MEDKIT		0x11
#define SND_PICKUP_FOOD			0x12
#define SND_PICKUP_GUN			0x13
#define SND_PICKUP_DOGFOOD		0x14
#define SND_PICKUP_EXTRALIFE	0x15
#define SND_PICKUP_BONUS1		0x16
#define SND_PICKUP_BONUS2		0x17
#define SND_PICKUP_KEY			0x18

#define SND_NPC_DOG_ALERT		0x20
#define SND_NPC_DOG_ATTACK		0x21
#define SND_NPC_DOG_WOUND		0x22
#define SND_NPC_DOG_DIE			0x23
#define SND_NPC_GUARD_ALERT		0x24
#define SND_NPC_GUARD_ATTACK	0x25
#define SND_NPC_GUARD_WOUND		0x26
#define SND_NPC_GUARD_DIE		0x27
#define SND_NPC_SS_ALERT		0x28
#define SND_NPC_SS_ATTACK		0x29
#define SND_NPC_SS_WOUND		0x2A
#define SND_NPC_SS_DIE			0x2B
#define SND_NPC_BOSS_ALERT		0x2C
#define SND_NPC_BOSS_ATTACK		0x2D
#define SND_NPC_BOSS_WOUND		0x2E
#define SND_NPC_BOSS_DIE		0x2F








#define SND_DOG_ATTACK			0x21

void wl_hud_init();
void wl_hud_update();

void wl_hud_trigger_death();
void wl_hud_trigger_gameover();
void wl_hud_trigger_victory();
void wl_hud_trigger_floordone(u8 nextfloor);

void wl_hud_PlaySound(u8 sound);
void wl_hud_PlayMusic(u8 song);
void wl_hud_StopMusic();

void wl_hud_SetWeapon(u8 weapon);
void wl_hud_SetWeaponFrame(u8 frame);
void wl_hud_SetHealth(u8 health);
void wl_hud_SetAmmo(u8 ammo);
void wl_hud_SetLives(u8 lives);
void wl_hud_SetFloor(u8 floor);
void wl_hud_SetKeys(u8 keys);
void wl_hud_SetGuns(u8 guns);
void wl_hud_TakeDamage();

void wl_hud_SetKillRatio(u8 count);
void wl_hud_SetBonusRatio(u8 count);
void wl_hud_SetSecretRatio(u8 count);
void wl_hud_SetScoreHi(u8 score);
void wl_hud_SetScoreLo(u8 score);

#endif /* SOURCES_WL3D_WL_HUD_H_ */


