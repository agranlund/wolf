/*
 * game.c
 *
 *  Created on: Nov 6, 2016
 *      Author: agranlund
 */

#include "math.h"
#include "gfx.h"
#include "../Data/gfxTextures.h"

extern u8 gb_map_attrib[];


#define MAP_SIZE        		16
#define MAP_GRID_SIZE       	64
#define MAP_GRID_MASK       	(MAP_GRID_SIZE-1)
#define MAP_GRID_SHIFT     	 	6
#define SCREEN_WIDTH    		GFX_WIDTH
#define SCREEN_HEIGHT   		GFX_HEIGHT

#define ANG_VIEW        		ANG_DEG(60)
#define ANG_STEP        		(ANG_VIEW / SCREEN_WIDTH)
#define VIEW_DIST       		35472     /* fixedpoint: (SCREEN_WIDTH/2) / tan(ANG_VIEW / 2) */


#define WALL_TEX_SIZE        	64
#define WALL_TEX_SHIFT       	10
#define WALL_TEX_SHIFT_MASK		0xFFFF0000
#define WALL_TEX_WORDS			((WALL_TEX_SIZE*WALL_TEX_SIZE*2) / 32)

#define OBJ_TEX_SIZE			64
#define OBJ_TEX_SHIFT			0
#define OBJ_TEX_WORDS			((WALL_TEX_SIZE*WALL_TEX_SIZE*3) / 32)

#define FLOOR_TEX_SIZE			32
#define FLOOR_TEX_SHIFT			1
#define FLOOR_TEX_WORDS			((FLOOR_TEX_SIZE*FLOOR_TEX_SIZE*2) / 32)


// floor bpp	             2           1
// walls: 				 6.5ms		 6.5ms
// walls+floor:			  			14.4ms
// walls+floor+ceil:				17.0ms
#define DRAW_FLOOR				0
#define DRAW_CEIL				0
#define FLOOR_BPP				1


const u8 map[]=
{
    1,1,1,1,1,1,1,1,1,2,3,4,1,1,1,1,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,
    1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,
    1,1,1,1,0,0,1,0,0,0,0,2,0,0,0,4,
    1,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1,
    1,0,0,0,0,0,1,0,1,1,0,1,1,0,0,1,
    1,0,0,0,0,0,1,0,1,0,0,1,0,0,0,1,
    1,0,1,0,0,0,1,1,1,0,0,1,1,0,0,1,
    1,0,1,1,1,0,0,1,0,0,0,0,0,0,0,1,
    1,0,0,0,1,0,0,1,1,1,1,1,2,0,0,2,
    1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,1,
    1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,
    1,0,1,1,1,0,1,0,0,0,0,0,0,0,0,1,
    1,0,0,0,0,0,1,1,1,0,0,1,1,0,0,1,
    1,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
};


s32  player_x = ((7 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
s32  player_y = ((2 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
u16  player_a = ANG_0;

u16 wall_dist[SCREEN_WIDTH];
u8 wall_palettes[(SCREEN_WIDTH/8)*8];
struct gfx_texture wall_textures[4];
struct gfx_texture floor_textures[2];
struct gfx_texture obj_textures[7];


static inline u32 one_over(u32 x)
{
	if (x < 512)
		return (u32)div_table[x];
	return (1<<16) / x;
}

#if DRAW_FLOOR || DRAW_CEIL
u16 dist_for_y[SCREEN_HEIGHT>>1];	// todo: put this in rom

static inline u32 floor_weight(int scanline, u32 raylen)
{
	u32 dist = (u32) dist_for_y[scanline - (SCREEN_HEIGHT/2)];
    u32 weight = (dist * one_over(raylen)) >> FIXED_SHIFT;
    return weight;
}
#endif

#define TEX_POOL_WALLS	0
#define TEX_POOL_FLOOR	1
#define TEX_POOL_CEIL	2
#define TEX_POOL_OBJ	3

void game_init()
{
	extern u32 gfxWallTest[];

	gfx_init();

	// wall textures
	gfx_create_texture_pool(TEX_POOL_WALLS, 1, WALL_TEX_WORDS);
	gfx_init_texture(&wall_textures[0], gfxWall00, 0, TEX_POOL_WALLS);
	gfx_init_texture(&wall_textures[1], gfxWall01, 1, TEX_POOL_WALLS);
	gfx_init_texture(&wall_textures[2], gfxWall02, 5, TEX_POOL_WALLS);
	gfx_init_texture(&wall_textures[3], gfxWall03, 4, TEX_POOL_WALLS);

	// sprites
	gfx_create_texture_pool(TEX_POOL_OBJ, 1, OBJ_TEX_WORDS);
	gfx_init_texture(&obj_textures[0], gfxObj00, 2, TEX_POOL_OBJ);
	gfx_init_texture(&obj_textures[1], gfxObj01, 0, TEX_POOL_OBJ);
	gfx_init_texture(&obj_textures[2], gfxObj02, 1, TEX_POOL_OBJ);
	gfx_init_texture(&obj_textures[3], gfxObj03, 4, TEX_POOL_OBJ);
	gfx_init_texture(&obj_textures[4], gfxObj04, 4, TEX_POOL_OBJ);
	gfx_init_texture(&obj_textures[5], gfxObj05, 3, TEX_POOL_OBJ);
	gfx_init_texture(&obj_textures[6], gfxNpc00, 4, TEX_POOL_OBJ);


#if DRAW_FLOOR
	// floor textures
	gfx_create_texture_pool(TEX_POOL_FLOOR, 1, FLOOR_TEX_WORDS);
	gfx_init_texture(&floor_textures[0], gfxFloor01, 0, TEX_POOL_FLOOR);
#endif

#if DRAW_CEIL
	// ceiling textures
	gfx_create_texture_pool(TEX_POOL_CEIL,  1, FLOOR_TEX_WORDS);
	gfx_init_texture(&floor_textures[1], gfxFloor00, 0, TEX_POOL_CEIL);
#endif

#if DRAW_FLOOR || DRAW_CEIL
	// floor precalc tables
	for (int y=1; y<SCREEN_HEIGHT>>1; ++y)
	{
		int line = y + (SCREEN_HEIGHT >> 1);
		s32 dist = (MAP_GRID_SIZE * 128) / ((line<<1) - SCREEN_HEIGHT);
		dist_for_y[y] = dist;
	}
	dist_for_y[0] = dist_for_y[1];
#endif
}

struct sprite
{
	struct gfx_texture* texture;
	s32 px;
	s32 py;
	s32 tx;
	s32 ty;
	s32 sx;
	s32 sy;
};

#define MAX_ACTIVE_SPRITES	64

struct sprite active_sprites[MAX_ACTIVE_SPRITES];
int num_active_sprites = 0;

void queue_sprite(struct gfx_texture* texture, s32 sprite_x, s32 sprite_y)
{
	if (num_active_sprites >= MAX_ACTIVE_SPRITES)
		return;
	struct sprite* s = &active_sprites[num_active_sprites];
	s->texture = texture;
	s->px = sprite_x;
	s->py = sprite_y;
	num_active_sprites++;
}

void draw_sprites()
{
	struct sprite* visible_sprites[MAX_ACTIVE_SPRITES];
	u8 num_visible_sprites = 0;

    s32 view_cos = math_cos(player_a); // todo: cache this per frame
    s32 view_sin = math_sin(player_a);

	// transform and cull
	for (int i=0; i<num_active_sprites; ++i)
	{
		struct sprite* s = &active_sprites[i];
		s32 dx = s->px - player_x;
	    s32 dy = s->py - player_y;

	    s->tx = (((dx) * view_cos) >> 8) - (((dy) * view_sin) >> 8);
	    if (s->tx < 0)
	    	continue;

	    s->ty = (((dx) * view_sin) >> 8) + (((dy) * view_cos) >> 8);
	    visible_sprites[num_visible_sprites] = s;
	    num_visible_sprites++;
	}
	num_active_sprites = 0;

	// sort
	for (int i=0; i<num_visible_sprites-1; ++i)
	{
		for (int j=0; j<num_visible_sprites-1-i; ++j)
		{
			struct sprite* s1 = visible_sprites[j];
			struct sprite* s2 = visible_sprites[j+1];
			if (s1->tx < s2->tx)
			{
				visible_sprites[j] = s2;
				visible_sprites[j+1] = s1;
			}
		}
	}

	// draw
	for (int i=0; i<num_visible_sprites; ++i)
	{
		struct sprite* s = visible_sprites[i];

		s32 tx = s->tx;
		s32 ty = s->ty;

	    s32 height = (32 * one_over(tx>>8)) >> 8;
	    if (height < 2)
	    	continue;

	    s32 screen_x = ((ty>>8) * VIEW_DIST) >> 8;
	    screen_x *= one_over(tx>>8);
	    screen_x >>= 16;
	    screen_x += (SCREEN_WIDTH / 2);

	    s32 y0 = (SCREEN_HEIGHT >> 1) - (height >> 1);
	    s32 y1 = y0 + height;
	    s32 x0 = screen_x - (height >> 1);
	    s32 x1 = x0 + height;
	    if ((y1 < 0) || (x1 < 0))
	        continue;

	    s32 u0 = 0;
	    s32 v0 = 0;
	    s32 du = one_over(x1 - x0) >> 2;
	    s32 dv = one_over(y1 - y0) >> 2;

	    if (y0 < 0)
	    {
	    	s32 offs = -y0;
	        v0 += (dv * offs);
	        y0 = 0;
	    }
	    if (x0 < 0)
	    {
	    	s32 offs = -x0;
	        u0 += (du * offs);
	        x0 = 0;
	    }
	    if (y1 > SCREEN_HEIGHT)
	        y1 = SCREEN_HEIGHT;
	    if (x1 > SCREEN_WIDTH)
	        x1 = SCREEN_WIDTH;

	    gfx_load_texture(s->texture);
	    volatile u32* texture_vram = s->texture->vram_alias;
	    u8 palette = s->texture->pal;
	    volatile u32* dst_base = ((volatile u32*)GFX_BASE_ALIAS) + (y0 * SCREEN_WIDTH);

	    u16 ztest = (tx>>8);

	    s32 u = u0;
	    for (int x=x0; x<x1; ++x)
	    {
	    	if (wall_dist[x] > ztest)
	    	{
	    		s32 v = v0;
	    	    volatile u32* src_base = texture_vram + (u>>FIXED_SHIFT);
	    		volatile u32* dst = dst_base + x;

		        for (int y=y0; y<y1; ++y)
	    		{
		    		volatile u32* src = src_base + ((v>>FIXED_SHIFT) * 64);
		        	if (*src == 0)
					{
						u32 c0 = *(src + (64 * 64 * 1));
						u32 c1 = *(src + (64 * 64 * 2));

						if ((c0 + c1) == 0)
						{
							gb_map_attrib[(x>>3) + ((y>>3)*20)] = palette;
						}
						*dst = c0;
						*(dst + GFX_BITPLANE_BITS) = c1;
					}
		            v += dv;
		    		dst += SCREEN_WIDTH;
	        	}
	        }
	        u += du;
	    }
	}
}


void game_update(u8 joypad)
{
	s32 move_speed = (6<<FIXED_SHIFT);
	s32 turn_speed = (2<<FIXED_SHIFT);

	s32 player_dx = 0;
	s32 player_dy = 0;

	if (joypad & 0x20)
	{
		if (joypad & 0x01)
		{
			player_dx = -math_sin(player_a);
			player_dy = -math_cos(player_a);
		}
		else
		{
			player_a += turn_speed;
		}
	}
	if (joypad & 0x10)
	{
		if (joypad & 0x01)
		{
			player_dx = math_sin(player_a);
			player_dy = math_cos(player_a);
		}
		else
		{
			player_a -= turn_speed;
		}
	}

	if (joypad & 0x40)
	{
		player_dx = math_cos(player_a);
		player_dy = -math_sin(player_a);
	}
	else if (joypad & 0x80)
	{
		player_dx = -math_cos(player_a);
		player_dy = math_sin(player_a);
	}
	player_x += (player_dx * move_speed) >> FIXED_SHIFT;
	player_y += (player_dy * move_speed) >> FIXED_SHIFT;


	for (int i=0; i<SCREEN_WIDTH; ++i)
		wall_palettes[i] = 0;

    s32 pa = player_a;
    s32 px = player_x;
    s32 py = player_y;

    // clear floor + ceiling
    u32* dst = (u32*) GFX_BASE_ADDR;
    for (int y=0; y<GFX_BITPLANE_WORDS/2; ++y)
    {
    	*dst = 0xFFFFFFFF;
    	*(dst+GFX_BITPLANE_WORDS) = 0;//0xFFFFFFFF;
    	dst++;
    }
    for (int y=0; y<GFX_BITPLANE_WORDS/2; ++y)
    {
    	*dst = 0x00000000;
    	*(dst+GFX_BITPLANE_WORDS) = 0xFFFFFFFF;
    	dst++;
    }


    u16 ang = (pa + (ANG_VIEW / 2)) & ANGLE_MASK;

    for (int x=0; x<SCREEN_WIDTH; ++x)
    {
        s32 tanAng = math_tan(ang);
        s32 divTanAng = math_div_tan(ang);

        s32 horizontal_x;
        s32 horizontal_y;
        s32 horizontal_step_x;
        s32 horizontal_step_y;
        s32 horizontal_len = 16000;
        s32 vertical_x;
        s32 vertical_y;
        s32 vertical_step_x;
        s32 vertical_step_y;
        s32 vertical_len = 16000;
        s32 first_hit;
        u8 vertical_tile = 0;
        u8 horizontal_tile = 0;

        #define GRID_ALIGN_MASK 0xFFFFC000

        // setup trace parameters
        if (ang < ANG_90)
        {
            // horizontal
            horizontal_y = (py & GRID_ALIGN_MASK) - 1;
            first_hit = ((py - horizontal_y)>>FIXED_SHIFT) * divTanAng;
            horizontal_x = px + first_hit;
            horizontal_step_y = -(MAP_GRID_SIZE<<FIXED_SHIFT);
            horizontal_step_x = (MAP_GRID_SIZE * divTanAng);

            // vertical
            vertical_x = (px & GRID_ALIGN_MASK) + (MAP_GRID_SIZE<<FIXED_SHIFT);
            first_hit = ((px - vertical_x)>>FIXED_SHIFT) * tanAng;
            vertical_y = py + first_hit;
            vertical_step_x = MAP_GRID_SIZE<<FIXED_SHIFT;
            vertical_step_y = -(MAP_GRID_SIZE * tanAng);
        }
        else if (ang < ANG_180)
        {
            // horizontal
            horizontal_y = (py & GRID_ALIGN_MASK) - 1;
            first_hit = ((py - horizontal_y)>>FIXED_SHIFT) * divTanAng;
            horizontal_x = px + first_hit;
            horizontal_step_y = -(MAP_GRID_SIZE<<FIXED_SHIFT);
            horizontal_step_x = (MAP_GRID_SIZE * divTanAng);

            //vertical
            vertical_x = (px & GRID_ALIGN_MASK) - 1;
            first_hit = ((px - vertical_x)>>FIXED_SHIFT) * tanAng;
            vertical_y = py + first_hit;
            vertical_step_x = -(MAP_GRID_SIZE<<FIXED_SHIFT);
            vertical_step_y = (MAP_GRID_SIZE * tanAng);
        }
        else if (ang < ANG_270)
        {
            // horizontal
            horizontal_y = (py & GRID_ALIGN_MASK) + (MAP_GRID_SIZE<<FIXED_SHIFT);
            first_hit = ((py - horizontal_y)>>FIXED_SHIFT) * divTanAng;
            horizontal_x = px + first_hit;
            horizontal_step_y = MAP_GRID_SIZE<<FIXED_SHIFT;
            horizontal_step_x = -(MAP_GRID_SIZE * divTanAng);

            //vertical
            vertical_x = (px & GRID_ALIGN_MASK) - 1;
            first_hit = ((px - vertical_x)>>FIXED_SHIFT) * tanAng;
            vertical_y = py + first_hit;
            vertical_step_x = -(MAP_GRID_SIZE<<FIXED_SHIFT);
            vertical_step_y = (MAP_GRID_SIZE * tanAng);
        }
        else
        {
            // horizontal
            horizontal_y = (py & GRID_ALIGN_MASK) + (MAP_GRID_SIZE<<FIXED_SHIFT);
            first_hit = ((py - horizontal_y)>>FIXED_SHIFT) * divTanAng;
            horizontal_x = px + first_hit;
            horizontal_step_y = MAP_GRID_SIZE<<FIXED_SHIFT;
            horizontal_step_x = -(MAP_GRID_SIZE * divTanAng);

            //vertical
            vertical_x = (px & GRID_ALIGN_MASK) + (MAP_GRID_SIZE<<FIXED_SHIFT);
            first_hit = ((px - vertical_x)>>FIXED_SHIFT) * tanAng;
            vertical_y = py + first_hit;
            vertical_step_x = MAP_GRID_SIZE<<FIXED_SHIFT;
            vertical_step_y = -(MAP_GRID_SIZE * tanAng);
        }

        // trace horizontal
        while (1)
        {
            int tile_x = horizontal_x >> (MAP_GRID_SHIFT + FIXED_SHIFT);
            int tile_y = horizontal_y >> (MAP_GRID_SHIFT + FIXED_SHIFT);
            if (tile_x < 0 || tile_x >= MAP_SIZE)
                break;
            horizontal_tile = map[tile_x + (tile_y * MAP_SIZE)];
            if (horizontal_tile != 0)
            {
                horizontal_len = (((horizontal_y - py) >> FIXED_SHIFT) * math_div_sin(ang)) >> FIXED_SHIFT;
                if (horizontal_len < 0)
                    horizontal_len = -horizontal_len;
                break;
            }
            horizontal_x += horizontal_step_x;
            horizontal_y += horizontal_step_y;
        }

        // trace vertical
        while(1)
        {
            int tile_x = vertical_x >> (MAP_GRID_SHIFT + FIXED_SHIFT);
            int tile_y = vertical_y >> (MAP_GRID_SHIFT + FIXED_SHIFT);
            if (tile_y < 0 || tile_y >= MAP_SIZE)
                break;

            vertical_tile = map[tile_x + (tile_y * MAP_SIZE)];
            if (vertical_tile != 0)
            {
                vertical_len = (((vertical_x - px) >> FIXED_SHIFT) * math_div_cos(ang)) >> FIXED_SHIFT;
                if (vertical_len < 0)
                    vertical_len = -vertical_len;
                break;
            }
            vertical_x += vertical_step_x;
            vertical_y += vertical_step_y;
        }

        u8 tile;
        int len;
        int u;
        int v = 0;
        u8 c;
        s32 wall_x;
        s32 wall_y;
        u32 shade;
        if (horizontal_len < vertical_len)
        {
        	tile = horizontal_tile;
            wall_x = horizontal_x;
            wall_y = horizontal_y;
            len = horizontal_len;
            u = (horizontal_x >> FIXED_SHIFT) & MAP_GRID_MASK;
            shade = 0;
        }
        else
        {
        	tile = vertical_tile;
            wall_x = vertical_x;
            wall_y = vertical_y;
            len = vertical_len;
            u = (vertical_y >> FIXED_SHIFT) & MAP_GRID_MASK;
            shade = 1;
        }

        if (tile == 0)
        	continue;

        // fix distortion
        len = (len * distort_table[x]) >> FIXED_SHIFT;
        if (len == 0)
            len = 1;

        // fill zbuffer
        wall_dist[x] = len;

        // find wall height
        int height = (32 * one_over(len)) >> 8;
        if (height == 0)
            height = 1;

        // prepare texture
        struct gfx_texture* tex = &wall_textures[tile - 1];
        gfx_load_texture(tex);

        // increase palette reference
        wall_palettes[(x & ~7) | tex->pal]++;

        // texture step
        int step_v = (u32) WALL_TEX_SIZE * one_over(height);

        // draw line
        if (height > SCREEN_HEIGHT)
        {
            v += ((height - SCREEN_HEIGHT) >> 1) * step_v;
            height = SCREEN_HEIGHT;
        }
        int y0 = (SCREEN_HEIGHT >> 1) - (height >> 1);
        int y1 = (SCREEN_HEIGHT >> 1) + (height >> 1);

        volatile u32* src = (tex->vram_alias + u);
        u32* dst = (u32*) GFX_BASE_ALIAS;
        dst += (x + (y0 * GFX_WIDTH));

        for (int y = y0; y<y1; ++y)
        {
        	u32 voffs = ((v & WALL_TEX_SHIFT_MASK) >> WALL_TEX_SHIFT);
        	u32 c0 = *(src + voffs);
        	u32 c1 = *(src + voffs + (WALL_TEX_SIZE * WALL_TEX_SIZE));

        	if (shade)
        	{
        		if (c0 != c1)
        		{
        			c0 = !c0;
        			c1 = 1;
        		}
        	}

        	*dst = c0;
        	*(dst + GFX_BITPLANE_BITS) = c1;

            dst += SCREEN_WIDTH;
            v += step_v;
        }

        // floor and ceiling
#if DRAW_FLOOR || DRAW_CEIL

        u32* dst_floor = dst;
        u32* dst_ceil = ((u32*) GFX_BASE_ALIAS) + x + ((y0-1) * GFX_WIDTH);

        s32 wall_x_shifted = wall_x >> FIXED_SHIFT;
        s32 wall_y_shifted = wall_y >> FIXED_SHIFT;
        s32 px_shifted = px >> FIXED_SHIFT;
        s32 py_shifted = py >> FIXED_SHIFT;

        for (int y=y1; y<SCREEN_HEIGHT; ++y)
        {
        	s32 weight = floor_weight(y, len);
            s32 one_minus_weight = (1<<FIXED_SHIFT) - weight;

            s32 floor_x = ((weight * wall_x_shifted) + (one_minus_weight * px_shifted)) >> FIXED_SHIFT;
            s32 floor_y = ((weight * wall_y_shifted) + (one_minus_weight * py_shifted)) >> FIXED_SHIFT;

            s32 tile_x = floor_x >> MAP_GRID_SHIFT;
            s32 tile_y = floor_y >> MAP_GRID_SHIFT;

            //if (tile_x >= 0 && tile_x < MAP_SIZE && tile_y >= 0 && tile_y < MAP_SIZE)
            {
                //if (map[tile_x + (tile_y * MAP_SIZE)] == 2)
                {
                    s32 u = (floor_y & ((MAP_GRID_SIZE>>FLOOR_TEX_SHIFT)-1));// >> FLOOR_TEX_SHIFT;
                    s32 v = (floor_x & ((MAP_GRID_SIZE>>FLOOR_TEX_SHIFT)-1));// >> FLOOR_TEX_SHIFT;
				#if DRAW_FLOOR
                    tex = &floor_textures[0];
                    gfx_load_texture(tex);
                    src = tex->vram_alias + u + (v * FLOOR_TEX_SIZE);
                    *(dst_floor) = *src;
				#if FLOOR_BPP > 1
                    *(dst_floor + GFX_BITPLANE_BITS) = *(src + FLOOR_TEX_SIZE * FLOOR_TEX_SIZE);
				#endif
				#endif
                #if DRAW_CEIL
                    tex = &floor_textures[1];
                    gfx_load_texture(tex);
                    src = tex->vram_alias + u + (v * FLOOR_TEX_SIZE);
                    *(dst_ceil) = *src;
				#if FLOOR_BPP > 1
                    *(dst_ceil + GFX_BITPLANE_BITS) = *(src + FLOOR_TEX_SIZE * FLOOR_TEX_SIZE);
				#endif
				#endif
                }
            }

            dst_ceil -= SCREEN_WIDTH;
            dst_floor += SCREEN_WIDTH;
        }
#endif
        ang = (ang - ANG_STEP);
    }


    // find best matching palette for each tile
    u8* pal_src = wall_palettes;
    for (int x=0; x<GFX_TILES_X; x++)
    {
    	u8 best_pal = 5;
    	if (pal_src[4] > pal_src[best_pal]) { best_pal = 4; }
    	if (pal_src[3] > pal_src[best_pal]) { best_pal = 3; }
    	if (pal_src[2] > pal_src[best_pal]) { best_pal = 2; }
    	if (pal_src[1] > pal_src[best_pal]) { best_pal = 1; }
    	if (pal_src[best_pal] == 0)    		{ best_pal = 0; }

    	u8* pal_dst = &gb_map_attrib[x];
    	for (int y=0; y<GFX_TILES_Y; ++y)
    	{
    		*pal_dst = best_pal;
    		pal_dst += GFX_TILES_X;
    	}
    	pal_src += 8;
    }

    s32 sx = ((11 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    s32 sy = ((1 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    queue_sprite(&obj_textures[0], sx, sy);

    sx = ((14 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    sy = ((1 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    queue_sprite(&obj_textures[2], sx, sy);

    sx = ((10 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    sy = ((2 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    queue_sprite(&obj_textures[5], sx, sy);

    sx = ((9 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    sy = ((4 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    queue_sprite(&obj_textures[4], sx, sy);

    sx = ((8 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    sy = ((4 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    queue_sprite(&obj_textures[3], sx, sy);

    sx = ((7 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    sy = ((1 * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
    queue_sprite(&obj_textures[6], sx, sy);

    draw_sprites();

}
