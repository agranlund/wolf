/*
 * wl_draw.h
 *
 *  Created on: Nov 12, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_WL3D_WL_DRAW_H_
#define SOURCES_WL3D_WL_DRAW_H_

#include "../gfx.h"

#define	VISMAP_ADDR				0x20002C00
#define VISMAP_ALIAS			GFX_ADDR_TO_ALIAS(VISMAP_ADDR)

void wl_draw_init();
void wl_draw_update();

#endif /* SOURCES_WL3D_WL_DRAW_H_ */
