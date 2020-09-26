//
//  map.hpp
//  wolfgfx
//
//  Created by Anders Granlund on 13/11/16.
//

#ifndef map_hpp
#define map_hpp

#include <stdio.h>

#define MAP_MAX_DOORS   48
#define MAP_DOOR_GFX    12

class Map
{
public:
    Map();
    ~Map();
    void Release();
    bool IsLoaded() { return isLoaded; }
    
    bool Load(const char* aFilename);
    void WriteCppPlane(FILE* aFile, int aPlane);
    
//private:
    unsigned char add_door(unsigned char tile, unsigned short orientation, unsigned char x, unsigned char y);
    unsigned char add_npc(unsigned char npc, unsigned char x, unsigned char y);
    unsigned char remap_tile(unsigned char x, unsigned char y, unsigned char* plane0, unsigned char* plane1);
    
    int compress(unsigned char* src, unsigned char* dst);
    void uncompress(unsigned char* src, unsigned char* dst);
    
    bool isLoaded;
    unsigned char map[64*64];
    unsigned char start_x;
    unsigned char start_y;
    unsigned char start_a;
    
    unsigned int doors[MAP_MAX_DOORS];
    //00000000 00xxxxxx 00yyyyyy 00ollttt
    //x:xpos, y:ypos, o:orientatio, l:lock, t:type
        
    unsigned char num_doors;
    unsigned int num_npcs;
};

#endif /* map_hpp */
