/*
 * gfx.h
 *
 *  Created on: Oct 30, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_GFX_H_
#define SOURCES_GFX_H_

// framebuffer:		20001600 - 20002500		: 0xF00 (3840)
// texcache:		200025C0 - 20002C00 	: 0x640 (1600, 512*3 + 64)
// vismap:			20002C00 - 20002E00		: 0x200 (512)
// colmap:			20002E00 - 20003000		: 0x200 (512)



#define		GFX_POOL_ADDR				0x200025C0
#define		GFX_BASE_ADDR				0x20001600
#define		GFX_SRAM_TILE_ADDR			0x0000
#define		GFX_SRAM_ATTR_ADDR			0x1000

#define		GFX_TILES_X					20
#define 	GFX_TILES_Y					12
#define		GFX_WIDTH					(GFX_TILES_X * 8)
#define		GFX_HEIGHT					(GFX_TILES_Y * 8)
#define		GFX_BITPLANE_BITS			(GFX_WIDTH * GFX_HEIGHT)
#define		GFX_BITPLANE_BYTES			(GFX_BITPLANE_BITS / 8)
#define		GFX_BITPLANE_WORDS			(GFX_BITPLANE_BITS / 32)
#define		GFX_WIDTH_WORDS				(GFX_WIDTH / 32)

#define		GFX_ADDR_TO_ALIAS(x)		(0x22000000 + ((x - 0x20000000) * 32))
#define		GFX_BASE_ALIAS				GFX_ADDR_TO_ALIAS(GFX_BASE_ADDR)

#define		GFX_BITPLANE0_ADDR			(GFX_BASE_ADDR)
#define		GFX_BITPLANE1_ADDR			(GFX_BITPLANE0_ADDR + (GFX_BITPLANE_WORDS*4))
#define		GFX_BITPLANE0_ALIAS			GFX_ADDR_TO_ALIAS(GFX_BITPLANE0_ADDR)
#define		GFX_BITPLANE1_ALIAS			GFX_ADDR_TO_ALIAS(GFX_BITPLANE1_ADDR)
#define		GFX_BITPLANE1_ALIAS_OFFSET	(GFX_BITPLANE_BITS)

#define		GFX_COLOR0(x)				(x & 1)
#define		GFX_COLOR1(x)				((x & 2) >> 1)



#include "types.h"
void gfx_init();
void gfx_clear(u32 color);
void gfx_send_to_sram(u32 gb_tile_bank);

extern u8 gb_map_attrib[GFX_TILES_X * GFX_TILES_Y];

struct gfx_texture
{
	volatile u32*	vram_alias;
	const u32*		rom_addr;
	u32				words 		: 12;
	u32				pal   		:  4;
	u32				pool  		:  1;
	u32				alpha 		:  1;
	u32				compressed 	:  1;
	u32				offs		:  5;
	u32				xwords		:  4;
	u32				ywords		:  4;
} __attribute__ ((aligned (4)));

void gfx_create_texture_pool(int index, int count, u32 entry_size_in_words);
void gfx_init_texture(struct gfx_texture* texture, const u32* rom_addr, u8 pool);
void _gfx_load_texture(struct gfx_texture* texture);

#define gfx_load_texture(x) { if (!x->vram_alias) _gfx_load_texture(x); }




#endif /* SOURCES_GFX_H_ */


