/*
 * gfx.c
 *
 *  Created on: Oct 30, 2016
 *      Author: agranlund
 */
#include "Cpu.h"
#include "GPIO1.h"
#include "GPIO2.h"
#include "gfx.h"

u8 gb_map_attrib[GFX_TILES_X * GFX_TILES_Y];

#define GFX_MAX_TEXTURES_IN_POOL	1
#define GFX_MAX_TEXTURE_POOLS		4
struct gfx_texture_pool
{
	struct gfx_texture* cached_texture;
	u32* vram_addr;
	u32 entry_count;
	u32 entry_words;
};

struct gfx_texture_pool gfx_texture_pools[GFX_MAX_TEXTURE_POOLS];
u8 gfx_num_pools = 0;
u32* gfx_texture_pool_next_addr;

void gfx_init()
{
	gfx_num_pools = 0;
	gfx_texture_pool_next_addr = (u32*) GFX_POOL_ADDR;
}

void gfx_create_texture_pool(int index, int count, u32 entry_size_in_words)
{
	struct gfx_texture_pool* pool = &gfx_texture_pools[index];
	pool->entry_words = entry_size_in_words;
	pool->entry_count = 0;
	pool->vram_addr = gfx_texture_pool_next_addr;
	gfx_texture_pool_next_addr += (count * entry_size_in_words);
	for (int i=0; i<count; ++i)
	{
		pool->cached_texture = 0;
	}
}

void gfx_init_texture(struct gfx_texture* texture, const u32* rom_addr, u8 pool)
{
	// hdr0 = xxxxxxxx.yyyyyyyy.0000ssss.ssssssss	x=width, y=height, s=words
	// hdr1 = aaaaaaaa.bbbbbbbb.cccccccc.dddddddd	a=x0, b=x1, c=y0, d=y1
	// hdr2 = 00000ppp.000000bb.00000000.ffffffff	p=pal, b=bpp, f=flags
	u32 hdr0 = rom_addr[0];
	u32 hdr1 = rom_addr[1];
	u32 hdr2 = rom_addr[2];
	u32 hdr3 = rom_addr[3];
	u32 width  = (hdr0 & 0xFF000000) >> 24;
	u32 height = (hdr0 & 0x00FF0000) >> 16;

	texture->words = (hdr0 & 0x00000FFF);
	texture->pal   = ((hdr2 >> 24) & 7);
	texture->alpha = (hdr2 & 1);
	texture->compressed = ((hdr2 >> 1) & 1);
	texture->offs = (hdr2 & 0x0000FF00) >> 8;

	//texture->x0 = (hdr1 >> 24);
	//texture->x1 = (hdr1 & 0x00FF0000) >> 16;
	//texture->y0 = (hdr1 & 0x0000FF00) >> 8;
	texture->xwords = (hdr3 & 0xFF000000) >> 24;
	texture->ywords = (hdr3 & 0x00FF0000) >> 16;

	texture->rom_addr = rom_addr;
	texture->vram_alias = 0;
	texture->pool = pool;
}

void _gfx_load_texture(struct gfx_texture* texture)
{
	// already in vram?
	if (texture->vram_alias)
		return;

	struct gfx_texture_pool* pool = &gfx_texture_pools[texture->pool];
	if (pool->cached_texture)
	{
		pool->cached_texture->vram_alias = 0;
	}

	// todo: get a cache location in vram
	volatile u32* vram_addr = pool->vram_addr;
	texture->vram_alias = (volatile u32*) GFX_ADDR_TO_ALIAS((u32)vram_addr);
	pool->cached_texture = texture;

	volatile u32* dst = vram_addr;
	if (texture->alpha)
	{
		for (uint32 i=0; i<texture->xwords + texture->ywords; ++i)
			*dst++ = texture->rom_addr[4 + i];
	}

	// copy to vram
	if (!texture->compressed)
	{
		// uncompressed
		const u32* src = &texture->rom_addr[texture->offs];
		for(uint32 i=texture->words; i!=0; --i)
			*dst++ = *src++;
	}
	else
	{
		// compressed
		const u32* src = &texture->rom_addr[texture->offs];
		for(int i=0; i<texture->words; )
		{
			u32 d = src[i++];
			if ((d >> 8) != 0xAAAAAA)
			{
				*dst++ = d;
			}
			else
			{
				int count = (d & 0xFF);
				d = src[i++];
				for (int j=count; j!=0; --j)
					*dst++ = d;
			}
		}
	}
}



void gfx_clear(u32 color)
{
	// write directly to bitband region
	volatile uint32* vram = (volatile uint32*)GFX_BASE_ADDR;

	// bitplane0
	uint32 c0 = (color & 1) ? 0xFFFFFFFF : 0x00000000;
	for (int i=0; i<GFX_BITPLANE_WORDS; ++i)
	{
		*vram = c0;
		vram++;
	}

	// bitplane1
	uint32 c1 = (color & 2) ? 0xFFFFFFFF : 0x00000000;
	for (int i=0; i<GFX_BITPLANE_WORDS; ++i)
	{
		*vram = c1;
		vram++;
	}

	// map attributes
	for (int i=0; i<(GFX_TILES_X * GFX_TILES_Y); ++i)
	{
		gb_map_attrib[i] = 1;
	}
}


void gfx_clear_sram()
{
	// data pins are outputs
    FGPIOA_PDDR |= GPIO1_IO_DATA_MASK;

    // enable sram (OE=1, RW=1, CE=0)
	uint32 sram_set_data = (FGPIOA_PDOR & ~(GPIO1_IO_ADDR_MASK | GPIO1_IO_DATA_MASK | GPIO1_IO_OE_MASK | GPIO1_IO_RW_MASK | GPIO1_IO_CE_MASK)) | (1 << GPIO1_IO_OE_START_BIT);
	uint32 sram_set_addr = sram_set_data | (1 << GPIO1_IO_RW_START_BIT);
	FGPIOA_PDOR = sram_set_addr;

	// write to sram in tiled format (~1.1ms)
	uint32 out;
	uint32 addr = GFX_SRAM_TILE_ADDR << GPIO1_IO_ADDR_START_BIT;

	uint32 color = 1;
	uint32 c0 = ((color & 1) ? 0xFF : 0x00) << 24;
	uint32 c1 = ((color & 2) ? 0xFF : 0x00) << 24;
	for(int i=0; i<GFX_BITPLANE_BYTES; ++i)
	{
		out = addr | (c0);
		FGPIOA_PDOR = sram_set_addr | out;
		FGPIOA_PDOR = sram_set_data | out;
		FGPIOA_PDOR = sram_set_addr | out;
		addr += (1 << GPIO1_IO_ADDR_START_BIT);

		out = addr | (c1);
		FGPIOA_PDOR = sram_set_addr | out;
		FGPIOA_PDOR = sram_set_data | out;
		FGPIOA_PDOR = sram_set_addr | out;
		addr += (1 << GPIO1_IO_ADDR_START_BIT);
	}
	FGPIOA_PDOR = sram_set_addr | (1 << GPIO1_IO_CE_START_BIT);
}


void gfx_send_to_sram(u32 gb_tile_bank)
{
	// reverse all bits in bitband region (~0.8ms)
	volatile uint32* vram = (volatile uint32*) GFX_BASE_ADDR;
	for (int i=0; i<GFX_BITPLANE_WORDS*2; ++i)
	{
		uint32 n = *vram;
		n = (n >>  1) & 0x55555555 | (n <<  1) & 0xaaaaaaaa;
		n = (n >>  2) & 0x33333333 | (n <<  2) & 0xcccccccc;
		n = (n >>  4) & 0x0f0f0f0f | (n <<  4) & 0xf0f0f0f0;
		n = (n >>  8) & 0x00ff00ff | (n <<  8) & 0xff00ff00;
		n = (n >> 16) & 0x0000ffff | (n << 16) & 0xffff0000;
		*vram++ = n;
	}

	// data pins are outputs
    FGPIOA_PDDR |= GPIO1_IO_DATA_MASK;

    // enable sram (OE=1, RW=1, CE=0)
	uint32 sram_set_data = (FGPIOA_PDOR & ~(GPIO1_IO_ADDR_MASK | GPIO1_IO_DATA_MASK | GPIO1_IO_OE_MASK | GPIO1_IO_RW_MASK | GPIO1_IO_CE_MASK)) | (1 << GPIO1_IO_OE_START_BIT);
	uint32 sram_set_addr = sram_set_data | (1 << GPIO1_IO_RW_START_BIT);
	FGPIOA_PDOR = sram_set_addr;

	// write to sram in tiled format (~1.1ms)
	uint32 out;
	uint32 addr = GFX_SRAM_TILE_ADDR << GPIO1_IO_ADDR_START_BIT;
	volatile uint32* a = (volatile uint32*) GFX_BITPLANE0_ADDR;
	volatile uint32* b = (volatile uint32*) GFX_BITPLANE1_ADDR;

	#define DATA_OUT(d) \
		FGPIOA_PDOR = sram_set_addr | out; \
		out = addr | (d); \
		FGPIOA_PDOR = sram_set_data | out; \
		addr += (1 << GPIO1_IO_ADDR_START_BIT);

	for (int y=0; y<GFX_TILES_Y; ++y)
	{
		for (int x=0; x<GFX_TILES_X/4; ++x)
		{
			// tile0
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 0)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 0)) & 0xFF000000);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 1)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 1)) & 0xFF000000);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 2)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 2)) & 0xFF000000);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 3)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 3)) & 0xFF000000);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 4)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 4)) & 0xFF000000);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 5)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 5)) & 0xFF000000);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 6)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 6)) & 0xFF000000);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 7)) & 0xFF000000);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 7)) & 0xFF000000);

			// tile1
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 0)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 0)) << 8) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 1)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 1)) << 8) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 2)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 2)) << 8) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 3)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 3)) << 8) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 4)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 4)) << 8) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 5)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 5)) << 8) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 6)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 6)) << 8) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 7)) << 8) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 7)) << 8) & 0xFF000000);
			// tile2
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 0)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 0)) << 16) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 1)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 1)) << 16) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 2)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 2)) << 16) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 3)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 3)) << 16) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 4)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 4)) << 16) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 5)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 5)) << 16) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 6)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 6)) << 16) & 0xFF000000);
			DATA_OUT((*(a + (GFX_WIDTH_WORDS * 7)) << 16) & 0xFF000000);
			DATA_OUT((*(b + (GFX_WIDTH_WORDS * 7)) << 16) & 0xFF000000);
			// tile3
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 0)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 0)) << 24);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 1)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 1)) << 24);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 2)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 2)) << 24);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 3)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 3)) << 24);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 4)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 4)) << 24);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 5)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 5)) << 24);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 6)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 6)) << 24);
			DATA_OUT(*(a + (GFX_WIDTH_WORDS * 7)) << 24);
			DATA_OUT(*(b + (GFX_WIDTH_WORDS * 7)) << 24);

			// next 4 columns
			a++;
			b++;
		}
		// next row
		a += (GFX_WIDTH_WORDS*7);
		b += (GFX_WIDTH_WORDS*7);
	}

	// write tilemap attributes (palette + tile bank)
	uint32 bank_mask = ((gb_tile_bank & 1) << 3);
	addr = GFX_SRAM_ATTR_ADDR << GPIO1_IO_ADDR_START_BIT;
	for (int y=0; y<GFX_TILES_Y; ++y)
	{
		for (int x=0; x<GFX_TILES_X; ++x)
		{
			uint32 attrib = (bank_mask | (uint32)gb_map_attrib[x + (y*GFX_TILES_X)])<<24;
			DATA_OUT(attrib);
		}
		for (int x=GFX_TILES_X; x<32; ++x)
		{
			DATA_OUT(bank_mask);
		}
	}

	// disable sram (OE=1, RW=1, CE=1)
	FGPIOA_PDOR = sram_set_addr | (1 << GPIO1_IO_CE_START_BIT);
}



