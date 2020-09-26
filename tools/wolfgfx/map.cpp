//
//  map.cpp
//  wolfgfx
//
//  Created by Anders Granlund on 13/11/16.
//

#include "map.hpp"
#include <string.h>

#define TYPE_OBJ        0
#define TYPE_WALL       1
#define TYPE_DOOR       2
#define TYPE_PWALL      3

enum NPCS
{
    Dog = 0,
    Guard = 1,
    SS,
    Boss,
};

enum OBJS
{
    DoogFood = 1,
    Food,
    FirstAid,
    ExtraLife,
    Ammo,
    Bonus1,
    Bonus2,
    Gun,
    Gun2,
    Key1,
    Key2,
    Ammo2,
    NUM_PICKUPS,
    
    Table1 = NUM_PICKUPS,
    Table2,
    Bones,
    Ceiling_Light_Green,
    Chandalier,
    Green_Plant,
    Brown_Plant,
    Armor,
    Basket,
    Barrel,
    Vase,
    Well_Water,
    Flag,
    Water,
    Hanging_Skeleton,
    Column,
    Sink,
    Utensils_Brown,
    Cage,
    Cage_Skeleton,
    Bed,
    Utensils_Blue,
    Stove,
    Rack,
    Blood,
    Dead_Guard = 60,
    Elevator,
    Elevator_Secret,
    Victory_Trigger,
};




Map::Map()
{
    isLoaded = false;
    Release();
}

Map::~Map()
{
    Release();
}

void Map::Release()
{
    isLoaded = false;
    start_x = 1;
    start_y = 1;
    start_a = 0;
    num_doors = 0;
    num_npcs = 0;
    memset(map, 0, 64*64);
}

bool Map::Load(const char* aFilename)
{
    FILE* f = fopen(aFilename, "rb");
    if (!f)
        return false;
    
    unsigned short buf[64*64*2];
    fread(buf, 2, 64*64*2, f);
    fclose(f);

    //
    unsigned char planes[64*64*2];
    for (int y=0; y<64; ++y)
    {
        for (int x=0; x<64; ++x)
        {
            unsigned char tile0 = (unsigned char) buf[(x*64) + y];
            unsigned char tile1 = (unsigned char) buf[(x*64) + y + (64*64)];
            planes[x + (y*64)] = tile0;
            planes[x + (y*64) + (64*64)] = tile1;
        }
    }
    
    
    // remap tiles
    for (int y=0; y<64; ++y)
    {
        for (int x=0; x<64; ++x)
        {
            unsigned char tile = remap_tile(x, y, &planes[x + (y*64)], &planes[x + (y*64) + (64*64)]);
            map[x + (y*64)] = tile;
        }
    }
    isLoaded = true;
    return isLoaded;
}

void Map::WriteCppPlane(FILE* aFile, int aPlane)
{
    unsigned char compressed_map[64*64*2];
    unsigned int compressed_size = compress(map, compressed_map);

    unsigned char* p = compressed_map;
    
    for (int i=0; i<compressed_size; ++i)
    {
        unsigned char d = p[i];
        if (i != 0)
            fprintf(aFile, ",");
        if (((i) & 63) == 0)
            fprintf(aFile, "\n 0x%02x", d);
        else
            fprintf(aFile, " 0x%02x", d);
    }
}


unsigned char Map::remap_tile(unsigned char x, unsigned char y, unsigned char* plane0, unsigned char* plane1)
{
    unsigned char tile0 = *plane0;
    unsigned char tile1 = *plane1;
    
    unsigned char idx = 0;
    unsigned char type = 0;
    
    //------------------------------------
    // plane 1 (objects)
    //------------------------------------
    switch (tile1)
    {
        case 19:
        case 20:
        case 21:
        case 22:
            start_x = x;
            start_y = y;
            start_a = ((1 + (4 - (tile1 - 19))) * 64) & 0xFF;
            return 0;
            break;
            
        case 23:
            idx = OBJS::Water;
            break;
            
        case 25:
            idx = OBJS::Table1;
            break;
            
        case 27:
            idx = OBJS::Chandalier;
            break;
        
        case 28:
            idx = OBJS::Hanging_Skeleton;
            break;
            
        case 29:
            idx = OBJS::DoogFood;
            break;
        
        case 30:
            idx = OBJS::Column;
            break;
            
        case 31:
            idx = OBJS::Green_Plant;
            break;
            
        case 33:
            idx = OBJS::Sink;
            break;
            
        case 34:
            idx = OBJS::Brown_Plant;
            break;
            
        case 35:
            idx = OBJS::Vase;
            break;
            
        case 36:
            idx = OBJS::Table2;
            break;
            
        case 37:
            idx = OBJS::Ceiling_Light_Green;
            break;
            
        case 38:
            idx = OBJS::Utensils_Brown;
            break;
            
        case 39:
            idx = OBJS::Armor;
            break;
            
        case 40:
            idx = OBJS::Cage;
            break;
            
        case 41:
            idx = OBJS::Cage_Skeleton;
            break;
            
        case 42:
        case 57:
        case 64:
        case 65:
        case 66:
        case 32:
            idx = OBJS::Bones;
            break;
            
        case 43:
            idx = OBJS::Key1;
            break;
            
        case 44:
            idx = OBJS::Key2;
            break;
        
        case 45:
            idx = OBJS::Bed;
            break;
        
        case 46:
            idx = OBJS::Basket;
            break;
            
        case 47:
            idx = OBJS::Food;
            break;
            
        case 48:
            idx = OBJS::FirstAid;
            break;
            
        case 49:
            idx = OBJS::Ammo;
            break;
            
        case 50:
            idx = OBJS::Gun;
            break;
            
        case 51:
            idx = OBJS::Gun2;
            break;
            
        case 52:
        case 53:
        case 55:
            idx = OBJS::Bonus1;
            break;
            
        case 54:
            idx = OBJS::Bonus2;
            break;
            
        case 56:
            idx = OBJS::ExtraLife;
            break;
            
        case 58:
        case 24:
            idx = OBJS::Barrel;
            break;
            
        case 59:
        case 60:
            idx = OBJS::Well_Water;
            break;
            
        case 61:
            idx = OBJS::Blood;
            break;
            
        case 62:
            idx = OBJS::Flag;
            break;
            
        case 67:
            idx = OBJS::Utensils_Blue;
            break;
            
        case 68:
            idx = OBJS::Stove;
            break;
            
        case 69:
            idx = OBJS::Rack;
            break;
        
        case 99:
            idx = OBJS::Victory_Trigger;
            break;
            
        case 124:
            idx = OBJS::Dead_Guard;
            break;
            
        case 108:       // guard 1
        case 109:
        case 110:
        case 111:
        case 112:
        case 113:
        case 114:
        case 115:
        case 144:       // guard 3
        case 145:
        case 146:
        case 147:
        case 148:
        case 149:
        case 150:
        case 151:
        /*case 180:       // guard 4
        case 181:
        case 182:
        case 183:
        case 184:
        case 185:
        case 186:
        case 187:*/
            idx = add_npc(NPCS::Guard, x, y);
            break;
            
        case 126:       // ss 1
        case 127:
        case 128:
        case 129:
        case 130:
        case 131:
        case 132:
        case 133:
        case 162:       // ss 3
        case 163:
        case 164:
        case 165:
        case 166:
        case 167:
        case 168:
        case 169:
        /*case 198:       // ss 4
        case 199:
        case 200:
        case 201:
        case 202:
        case 203:
        case 204:
        case 205:*/
            idx = add_npc(NPCS::SS, x, y);
            break;
            
        case 138:       // dog 1
        case 139:
        case 140:
        case 141:
        case 174:       // dog 3
        case 175:
        case 176:
        case 177:
        /*case 210:       // dog 4
        case 211:
        case 212:
        case 213:*/
            idx = add_npc(NPCS::Dog, x, y);
            break;
            
        case 214:       // hans grosse
            idx = add_npc(NPCS::Boss, x, y);
            break;
            
            
    }
    
    if (idx != 0)
        return (type << 6) | idx;

    //------------------------------------
    // elevator
    //------------------------------------
    if (tile0 == 107)
    {
        type = 0;
        idx = OBJS::Elevator_Secret;
        return (type << 6) | idx;
    }
    
    if ((y > 0) && (y < 63))
    {
        if ((*(plane0 - 64) == 21) && (*(plane0+64) == 21))
        {
            type = 0;
            idx = OBJS::Elevator;
            return (type << 6) | idx;
        }
    }
    
    //------------------------------------
    // plane0 (walls / floor)
    //------------------------------------
    if (tile0 >= 106)
        return 0;
    
    if (tile0 > 0)
    {
        // wall
        idx = 1;
        type = TYPE_WALL;
        switch (tile0)
        {
            case 1:
            case 2:
                idx = 1;
                break;
            
            case 3:
                idx = 2;
                break;
            
            case 4:
                idx = 3;
                break;
            
            case 5:
                idx = 4;
                break;
            
            case 6:
                idx = 5;
                break;

            case 7:
                idx = 6;
                break;
           
            case 8:
            case 9:
                idx = 7;
                break;
            
            case 10:
            case 36:
                idx = 10;
                break;
            
            case 11:
            case 35:
                idx = 9;
                break;
            
            case 12:
            case 34:
                idx = 8;
                break;
                
            case 13:
                idx = 14;
                break;
                
            case 16:
                idx = 23;
                break;
                
            case 17:
                idx = 19;
                break;
                
            case 18:
                idx = 20;
                break;
                
            case 19:
            case 25:
                idx = 18;
                break;
                
            case 20:
                idx = 21;
                break;
                
            case 23:
                idx = 22;
                break;
                
            // elevator
            case 21:
            case 22:
            {
                idx = 15;
                if ((*(plane0 - 1 - 64) == tile0) && (*(plane0 - 1 + 64) == tile0))
                    idx++;
                else if ((*(plane0 + 1 - 64) == tile0) && (*(plane0 + 1 + 64) == tile0))
                    idx++;
            }
            break;
                
            // horizontal doors
            case 90:
            case 92:
            case 94:
            case 100:
                idx = add_door(tile0, 0, x, y);
                type = TYPE_DOOR;
                break;
                
            // vertical doors
            case 91:
            case 93:
            case 95:
            case 101:
                idx = add_door(tile0, 1, x, y);
                type = TYPE_DOOR;
                break;
        }
    }
    
    // secret walls
    if ((type == TYPE_WALL) && (tile1 == 98))
        type = TYPE_PWALL;
    
    return (type << 6) | idx;
}

unsigned char Map::add_npc(unsigned char npc, unsigned char x, unsigned char y)
{
    num_npcs++;
    unsigned char idx = 48 + npc;
    return idx;
}

unsigned char Map::add_door(unsigned char tile, unsigned short orientation, unsigned char x, unsigned char y)
{
    if (num_doors >= MAP_MAX_DOORS)
        return 64;

    unsigned char idx = num_doors;
    
    unsigned int data = 0;
    unsigned int lock = 0;
    unsigned int gfx = 12;
    switch (tile)
    {
        case 92:
        case 93:
            gfx = 13;
            lock = 1;
            break;
            
        case 94:
        case 95:
            gfx = 13;
            lock = 2;
            break;

        case 100:
        case 101:
            gfx = 14;
            break;
    };
    
    data |= (gfx - MAP_DOOR_GFX);
    data |= (lock << 3);
    data |= (orientation << 5);
    data |= (y << 8);
    data |= (x << 16);
    doors[num_doors] = data;
    num_doors++;
    return idx;
}


int Map::compress(unsigned char* src, unsigned char* dst)
{
    unsigned int compressed_size = 0;
    unsigned int original_size = 64*64;
    int srcpos = 0;
    while (srcpos < original_size)
    {
        unsigned char d = src[srcpos];
        unsigned char same = 0;
        if (srcpos+1 < original_size)
        {
            if(src[srcpos+1] != d)
                same = 0;
            else
                same = 1;
        }

        unsigned int count = 1;
        for (int i=srcpos+1; i<original_size; ++i)
        {
            if (same)
            {
                if (same && (src[i] != d))
                    break;
                if (!same && (src[i] == d))
                    break;
                count++;
                if (count == 127)
                    break;
            }
        }
        dst[compressed_size] = (same << 7) | count;
        compressed_size++;
        if (same)
        {
            dst[compressed_size] = d;
            compressed_size++;
            srcpos += count;
        }
        else
        {
            for (int i=0; i<count; ++i)
            {
                dst[compressed_size] = src[srcpos];
                compressed_size++;
                srcpos++;
            }
        }
    }

    printf("Compressed to = %i\n", compressed_size);
    printf("Doors = %i\n", num_doors);
    printf("Npcs = %i\n", num_npcs);
    return compressed_size;
}

void Map::uncompress(unsigned char* src, unsigned char* dst)
{
    int total_count = 0;
    while (total_count < (64*64))
    {
        unsigned char control_byte = *src++;
        unsigned char count = control_byte & 0x7F;
        total_count += count;
        if (control_byte & (1<<7))
        {
            unsigned char d = *src++;
            for (int i=0; i<count; ++i)
                *dst++ = d;
        }
        else
        {
            for (int i=0; i<count; ++i)
                *dst++ = *src++;
        }
    }
}

