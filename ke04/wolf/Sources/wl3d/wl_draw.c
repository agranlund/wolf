/*
 * wl_draw.c
 *
 *  Created on: Nov 12, 2016
 *      Author: agranlund
 */

#include "../types.h"
#include "../gfx.h"
#include "../math.h"
#include "../math_tables.h"
#include "../../Data/datWalls.h"
#include "../../Data/datObjs.h"
#include "../../Data/datNpcs.h"

#include "wl_game.h"
#include "wl_npc.h"
#include "wl_draw.h"


#define SCREEN_WIDTH    		GFX_WIDTH
#define SCREEN_HEIGHT   		GFX_HEIGHT
#define ANG_VIEW        		ANG_DEG(60)
#define ANG_STEP        		(ANG_VIEW / SCREEN_WIDTH)
#define VIEW_DIST       		38000		/* 35472: (SCREEN_WIDTH/2) / tan(ANG_VIEW / 2) */
#define HEIGHT_SCALE			40

#define WALL_TEX_SIZE        	64
#define WALL_TEX_SHIFT       	10
#define WALL_TEX_SHIFT_MASK		0xFFFF0000
#define WALL_TEX_WORDS			((WALL_TEX_SIZE*WALL_TEX_SIZE*2) / 32)

#define OBJ_TEX_SIZE			64
#define OBJ_TEX_SHIFT			0
#define OBJ_TEX_WORDS			((WALL_TEX_SIZE*WALL_TEX_SIZE*3) / 32)

#define TEX_POOL_ID				0
#define TEX_POOL_WORDS			(((WALL_TEX_SIZE*WALL_TEX_SIZE*3) / 32) + 16)

#ifdef _DEBUG
#define MAX_ACTIVE_SPRITES		46	// less sprites in debug because of memory issues
#else
#define MAX_ACTIVE_SPRITES		64
#endif

#define TILE_WALL_MASK			63
#define TILE_IS_WALL(x)			((x >> 6) & 1)
#define TILE_IS_DOOR(x)			((x >> 6) == 2)
#define TILE_DOOR_GFX			12
#define TILE_DOOR_GFX_SIDE		11

struct gfx_texture wall_textures[datWalls_count];
struct gfx_texture obj_textures[datObjs_count];
struct gfx_texture npc_textures[datNpcs_count];

struct sprite
{
	struct gfx_texture* texture;
	struct npc_t* npc;
	s32 x;
	s32 y;
};

s32 view_cos;
s32 view_sin;
u8 zbuffer[SCREEN_WIDTH];								// 1D zbuffer
struct sprite active_sprites[MAX_ACTIVE_SPRITES];		// sprite queue
u8 num_active_sprites = 0;								// number of sprites in queue

//----------------------------------------------------------------------------
// fast division
//----------------------------------------------------------------------------
static inline u32 one_over(u32 x)
{
	if (x < 512)
		return (u32)div_table[x];
	return (1<<16) / x;
}


//----------------------------------------------------------------------------
// queue sprite for rendering
//----------------------------------------------------------------------------
void queue_sprite(struct gfx_texture* texture, s32 sprite_x, s32 sprite_y)
{
	if (num_active_sprites >= MAX_ACTIVE_SPRITES)
		return;

	struct sprite* s = &active_sprites[num_active_sprites];
	s->texture = texture;
	s->npc = 0;
	s->x = sprite_x;
	s->y = sprite_y;
	num_active_sprites++;
}

//----------------------------------------------------------------------------
// queue sprites for rendering
//----------------------------------------------------------------------------
void queue_sprites()
{
    u8* mapptr = &map[0];
    volatile u32* vismap_ptr = (volatile u32*) VISMAP_ALIAS;

    s32 num_sprites = 0;

	// npcs
    for (int i=0; i<num_npcs; ++i)
    {
    	struct npc_t* npc = &npcs[i];
    	npc->visible = 0;

    	if (npc->state == NPC_STATE_REMOVED)
    		continue;

    	int xtile = npc->xpos >> MAP_GRID_SHIFT;
    	int ytile = npc->ypos >> MAP_GRID_SHIFT;
    	volatile u32* vis = &vismap_ptr[xtile + (ytile * MAP_SIZE)];

    	u32 visible = *(vis) | *(vis-1) | *(vis+1) | *(vis-MAP_SIZE) | *(vis-MAP_SIZE-1) | *(vis-MAP_SIZE+1) | *(vis+MAP_SIZE) | *(vis+MAP_SIZE+1) | *(vis+MAP_SIZE+1);
    	if (visible == 0)
    		continue;

		struct sprite* s = &active_sprites[num_active_sprites];
		s->texture = &npc_textures[npc->tex];
		s->npc = npc;
		s->x = npc->xpos << FIXED_SHIFT;
		s->y = npc->ypos << FIXED_SHIFT;
		num_sprites++;
		num_active_sprites++;
		if (num_active_sprites >= MAX_ACTIVE_SPRITES)
			return;
    }

    // static objects
    for (int y=0; y<MAP_SIZE; ++y)
    {
    	for (int x=0; x<MAP_SIZE; ++x)
    	{
    		u32 vis = *vismap_ptr++;
    		if (vis == 0)
    		{
    			mapptr++;
    			continue;
    		}

    		u8 tile = *mapptr++;
    		if (tile == 0)
    			continue;

    		if (tile < 48)
    		{
    			if (num_active_sprites < MAX_ACTIVE_SPRITES)
    			{
					struct sprite* s = &active_sprites[num_active_sprites];
					s->texture = &obj_textures[tile-1];
					s->npc = 0;
					s->x = ((x * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
					s->y = ((y * MAP_GRID_SIZE) + (MAP_GRID_SIZE / 2)) << FIXED_SHIFT;
					num_active_sprites++;
					//if (num_active_sprites >= MAX_ACTIVE_SPRITES)
						//return;
    			}
				num_sprites++;
    		}
    	}
    }
}

//----------------------------------------------------------------------------
// flush sprite queue
//----------------------------------------------------------------------------
void draw_sprites()
{
	struct sprite* visible_sprites[MAX_ACTIVE_SPRITES];
	u8 num_visible_sprites = 0;

	// transform and cull
	for (int i=0; i<num_active_sprites; ++i)
	{
		struct sprite* s = &active_sprites[i];
		s32 dx = s->x - player.x;
	    s32 dy = s->y - player.y;

	    s->x = (((dx) * view_cos) >> FIXED_SHIFT) - (((dy) * view_sin) >> FIXED_SHIFT);
	    if (s->x < 0)
	    	continue;

	    s->y = (((dx) * view_sin) >> FIXED_SHIFT) + (((dy) * view_cos) >> FIXED_SHIFT);
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
			if (s1->x < s2->x)
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

		s32 tx = s->x;
		s32 ty = s->y;

	    s32 height = (HEIGHT_SCALE * one_over(tx >> FIXED_SHIFT)) >> FIXED_SHIFT;
	    if (height < 2)
	    	continue;

	    s32 screen_x = ((ty >> FIXED_SHIFT) * VIEW_DIST) >> FIXED_SHIFT;
	    screen_x *= one_over(tx >> FIXED_SHIFT);
	    screen_x >>= (FIXED_SHIFT * 2);
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
		volatile u32* texture_xmask = s->texture->vram_alias;
		volatile u32* texture_ymask = texture_xmask + (s->texture->xwords << 5);
		volatile u32* texture_vram  = texture_ymask + (s->texture->ywords << 5);

	    u8 palette = s->texture->pal;
	    volatile u32* dst_base = ((volatile u32*)GFX_BASE_ALIAS) + (y0 * SCREEN_WIDTH);

	    u8 ztest = (height < 256) ? height : 255;
	    u32 visible = 0;

	    s32 u = u0;
	    for (int x=x0; x<x1; ++x)
	    {
	    	if (texture_xmask[u>>FIXED_SHIFT])
	    	{
				if (zbuffer[x] <= ztest)
				{
					s32 v = v0;
					volatile u32* src_base = texture_vram + (u >> FIXED_SHIFT);
					volatile u32* dst = dst_base + x;
					visible = 1;
					for (int y=y0; y<y1; ++y)
					{
						if (texture_ymask[v>>FIXED_SHIFT])
						{
							volatile u32* src = src_base + ((v >> FIXED_SHIFT) * OBJ_TEX_SIZE);
							if (*src == 0)
							{
								u32 c0 = *(src + (OBJ_TEX_SIZE * OBJ_TEX_SIZE * 1));
								u32 c1 = *(src + (OBJ_TEX_SIZE * OBJ_TEX_SIZE * 2));

								//c0 = 1;
								//c1 = 1;

								if ((c0 + c1) == 0)
								{
									gb_map_attrib[(x>>3) + ((y>>3) * GFX_TILES_X)] = palette;
								}
								*dst = c0;
								*(dst + GFX_BITPLANE_BITS) = c1;
							}
						}
						v += dv;
						dst += SCREEN_WIDTH;
					}
				}
	    	}
	        u += du;
	        /*if (u > uend)
	        	break;
	        	*/
	    }

	    if (visible && s->npc)
	    	s->npc->visible = 1;
	}
}


//----------------------------------------------------------------------------
// draw world
//----------------------------------------------------------------------------
void draw_world()
{
	u8 wall_palettes[(SCREEN_WIDTH/8)*8];

    // clear palette + zbuffer
	for (int i=0; i<SCREEN_WIDTH; ++i)
	{
		zbuffer[i] = 0;
		wall_palettes[i] = 0;
	}

	// clear vismap
	volatile u32* vismap = (volatile u32*) VISMAP_ADDR;
	for (int i=0; i<MAP_SIZE*MAP_SIZE/32; ++i)
		*vismap++ = 0;
	vismap = (volatile u32*) VISMAP_ALIAS;

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

    s32 pa = player.a;
    s32 px = player.x;
    s32 py = player.y;
    u16 ang = (pa + (ANG_VIEW / 2)) & ANGLE_MASK;

    struct hit_t
    {
    	s32 len;
    	s32 xpos;
    	s32 ypos;
    	u8 	tile;
    	u8	u;
    };

    int allow_shade = 1;

    for (int x=0; x<SCREEN_WIDTH; ++x)
    {
    	s32 tanAng = math_tan(ang);
        s32 divTanAng = math_div_tan(ang);

        u8 horizontal_u;
        s32 horizontal_x;
        s32 horizontal_y;
        s32 horizontal_step_x;
        s32 horizontal_step_y;
        s32 horizontal_len = 0x7FFFFFFF;
        u8 vertical_u;
        s32 vertical_x;
        s32 vertical_y;
        s32 vertical_step_x;
        s32 vertical_step_y;
        s32 vertical_len = 0x7FFFFFFF;
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
            vertical_y = py + first_hit - 1;
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
            if ((tile_x & ~(MAP_SIZE-1)) || (tile_y & ~(MAP_SIZE-1)))
            	break;
            u32 offs = tile_x + (tile_y * MAP_SIZE);
            horizontal_tile = map[offs];
            vismap[offs] = 1;
            if (TILE_IS_DOOR(horizontal_tile))
            {
            	u8 doorid = horizontal_tile & 63;
            	horizontal_tile = TILE_DOOR_GFX + (doordata[doorid] & 7);
            	s32 vx = horizontal_x + (horizontal_step_x >> 1);
            	s32 vy = horizontal_y + (horizontal_step_y >> 1);
            	vx -= ((doorstate[doorid] & 63) << FIXED_SHIFT);
                int tx = vx >> (MAP_GRID_SHIFT + FIXED_SHIFT);
                int ty = vy >> (MAP_GRID_SHIFT + FIXED_SHIFT);
                if ((tx == tile_x) && (ty == tile_y))
                {
                	horizontal_x = vx;
                	horizontal_y = vy;
                	horizontal_u = (horizontal_x >> FIXED_SHIFT) & MAP_GRID_MASK;

                	s32 d = ((horizontal_y - py) >> FIXED_SHIFT);
                	if (d>-16 && d<16)
            			horizontal_len = (horizontal_x - px);
                	else
                		horizontal_len = (d * math_div_sin(ang));

                	if (horizontal_len < 0)
                        horizontal_len = -horizontal_len;
                    break;
                }
            }
            else if (TILE_IS_WALL(horizontal_tile))
            {
            	if (TILE_IS_DOOR(map[offs-MAP_SIZE]) || TILE_IS_DOOR(map[offs+MAP_SIZE]))
            		horizontal_tile = TILE_DOOR_GFX_SIDE;

            	horizontal_tile &= TILE_WALL_MASK;
            	if (horizontal_step_y < 0)
            		horizontal_u = (horizontal_x >> FIXED_SHIFT) & MAP_GRID_MASK;
            	else
               		horizontal_u = (MAP_GRID_SIZE-1) - ((horizontal_x >> FIXED_SHIFT) & MAP_GRID_MASK);

            	s32 d = ((horizontal_y - py) >> FIXED_SHIFT);
            	if (d>-16 && d<16)
        			horizontal_len = (horizontal_x - px);
            	else
            		horizontal_len = (d * math_div_sin(ang));

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
            if ((tile_x & ~(MAP_SIZE-1)) || (tile_y & ~(MAP_SIZE-1)))
            	break;

            u32 offs = tile_x + (tile_y * MAP_SIZE);
            vertical_tile = map[offs];
            vismap[offs] = 1;

            if (TILE_IS_DOOR(vertical_tile))
            {
            	u8 doorid = vertical_tile & 63;
            	vertical_tile = TILE_DOOR_GFX + (doordata[doorid] & 7);
            	s32 vx = vertical_x + (vertical_step_x >> 1);
            	s32 vy = vertical_y + (vertical_step_y >> 1);
            	vy -= ((doorstate[doorid] & 63) << FIXED_SHIFT);
                int tx = vx >> (MAP_GRID_SHIFT + FIXED_SHIFT);
                int ty = vy >> (MAP_GRID_SHIFT + FIXED_SHIFT);
                if ((tx == tile_x) && (ty == tile_y))
                {
                	vertical_y = vy;
                	vertical_x = vx;
            		vertical_u = (vertical_y >> FIXED_SHIFT) & MAP_GRID_MASK;

                	s32 d = ((vertical_x - px) >> FIXED_SHIFT);
                	if (d>-16 && d<16)
                		vertical_len = (vertical_y - py);
                	else
                		vertical_len = (((vertical_x - px) >> FIXED_SHIFT) * math_div_cos(ang));

                	if (vertical_len < 0)
                        vertical_len = -vertical_len;
                    break;
                }
            }
            else if (TILE_IS_WALL(vertical_tile))
            {
            	if (TILE_IS_DOOR(map[offs-1]) || TILE_IS_DOOR(map[offs+1]))
            		vertical_tile = TILE_DOOR_GFX_SIDE;

            	vertical_tile &= TILE_WALL_MASK;
            	if (vertical_step_x > 0)
            		vertical_u = (vertical_y >> FIXED_SHIFT) & MAP_GRID_MASK;
            	else
            		vertical_u = (MAP_GRID_SIZE-1) - ((vertical_y >> FIXED_SHIFT) & MAP_GRID_MASK);

            	s32 d = ((vertical_x - px) >> FIXED_SHIFT);
            	if (d>-16 && d<16)
            		vertical_len = (vertical_y - py);
            	else
            		vertical_len = (((vertical_x - px) >> FIXED_SHIFT) * math_div_cos(ang));

            	if (vertical_len < 0)
                    vertical_len = -vertical_len;
                break;
            }

            vertical_x += vertical_step_x;
            vertical_y += vertical_step_y;
        }

        int shade;
        struct hit_t hit;

        if (horizontal_len <= vertical_len)
        {
        	hit.tile = horizontal_tile;
        	hit.xpos = horizontal_x;
        	hit.ypos = horizontal_y;
        	hit.len  = horizontal_len >> FIXED_SHIFT;
        	hit.u	 = horizontal_u;
            shade 	 = allow_shade;
        }
        else
        {
        	hit.tile = vertical_tile;
        	hit.xpos = vertical_x;
        	hit.ypos = vertical_y;
        	hit.len  = vertical_len >> FIXED_SHIFT;
        	hit.u	 = vertical_u;
            shade 	 = 0;
        }

        if (hit.tile == 0)
        	continue;

        // don't shade landscape tile
        if (hit.tile == 23)
        	shade = 0;

        // fix distortion
        hit.len = (hit.len * distort_table[x]) >> FIXED_SHIFT;
        if (hit.len == 0)
            hit.len = 1;

        // find wall height
        int height = (HEIGHT_SCALE * one_over(hit.len)) >> 8;
        if (height == 0)
            height = 1;

        // fill zbuffer
        zbuffer[x] = (height < 256) ? height : 255;

        // prepare texture
        struct gfx_texture* tex = &wall_textures[hit.tile - 1];
        gfx_load_texture(tex);

        // increase palette reference
        wall_palettes[(x & ~7) | tex->pal]++;

        // texture step
        int step_v = (u32) WALL_TEX_SIZE * one_over(height);

        // draw line
        int v = 0;
        if (height > SCREEN_HEIGHT)
        {
            v += ((height - SCREEN_HEIGHT) >> 1) * step_v;
            height = SCREEN_HEIGHT;
        }
        int y0 = (SCREEN_HEIGHT >> 1) - (height >> 1);
        int y1 = (SCREEN_HEIGHT >> 1) + (height >> 1);

        volatile u32* src = (tex->vram_alias + hit.u);
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
}


//----------------------------------------------------------------------------
// init renderer
//----------------------------------------------------------------------------
void wl_draw_init()
{
	gfx_init();

	// texture pool
	gfx_create_texture_pool(TEX_POOL_ID, 1, TEX_POOL_WORDS);

	// wall textures
	for (int i=0; i<datWalls_count; ++i)
		gfx_init_texture(&wall_textures[i], datWalls_data[i], TEX_POOL_ID);

	// obj textures
	for (int i=0; i<datObjs_count; ++i)
		gfx_init_texture(&obj_textures[i], datObjs_data[i], TEX_POOL_ID);

	// npc textures
	for (int i=0; i<datNpcs_count; ++i)
		gfx_init_texture(&npc_textures[i], datNpcs_data[i], TEX_POOL_ID);
}


//----------------------------------------------------------------------------
// update renderer
//----------------------------------------------------------------------------
void wl_draw_update()
{
    view_cos = math_cos(player.a);
    view_sin = math_sin(player.a);

    // draw world
    draw_world();

    // draw sprites
    queue_sprites();
    draw_sprites();
}

