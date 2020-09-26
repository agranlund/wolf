//
//  main.cpp
//  wolfgfx
//
//  Created by Anders Granlund on 29/10/16.
//

#include <string.h>
#include <stdio.h>
#include "image.hpp"
#include "map.hpp"

int convert_gfx(const char* aFilename, const char* aSymbol, bool aAlpha, bool aCompress);
int convert_maps(const char* aFilename, const char* aSymbol);


int print_usage()
{
    printf("Usage:\n");
    printf("-gfx <s>:       input file\n");
    printf("-gfx_alpha:     add third alpha bitplane\n");
    printf("-cpp <s>:       output cpp symbol\n");
    return 0;
}

int main(int argc, const char * argv[])
{
    bool alpha = false;
    bool compress = false;
    const char* gfxFilename = nullptr;
    const char* mapFilename = nullptr;
    const char* outCppSymbol = nullptr;

    // command line arguments
    for (int i=1; i<argc; ++i)
    {
        if ((argc>(i+1)) && strcmp(argv[i], "-gfx") == 0)
        {
            gfxFilename = argv[i+1];
        }
        if ((argc>(i+1)) && strcmp(argv[i], "-map") == 0)
        {
            mapFilename = argv[i+1];
        }
        if ((argc>(i+1)) && strcmp(argv[i], "-cpp") == 0)
        {
            outCppSymbol = argv[i+1];
        }
        if (strcmp(argv[i], "-alpha") == 0)
        {
            alpha = true;
        }
        if (strcmp(argv[i], "-compress") == 0)
        {
            compress = true;
        }
    }
    
    if (gfxFilename)
    {
        convert_gfx(gfxFilename, outCppSymbol, alpha, compress);
        return 0;
    }

    if (mapFilename)
    {
        convert_maps(mapFilename, outCppSymbol);
        return 0;
    }
    
    return -1;
}


int convert_gfx(const char* aFilename, const char* aSymbol, bool aAlpha, bool aCompress)
{
    FILE* f = fopen(aFilename, "r");
    if (!f)
    {
        printf("Failed to open %s", aFilename);
        return 0;
    }
    
    // load images
    Image images[256];
    int imageCount = 0;
    char fname[256];
    while (!feof(f))
    {
        int palette;
        int idx;
        if (fscanf(f, "%i\t%s %i", &palette, fname, &idx) < 2)
            continue;

        printf("* Loading image %s...\n", fname);
        
        Image* img = &images[imageCount];
        img->LoadPCX(fname, palette, aAlpha, aCompress);
        if (!img->IsLoaded())
        {
            printf("### ERROR Failed to load %s\n", fname);
            fclose(f);
            return 0;
        }
        
        imageCount++;
    }
    fclose(f);

    if (imageCount == 0)
    {
        printf("### ERROR: No images loaded\n");
        return 0;
    }
    
    // save header
    char fnamehpp[256];
    sprintf(fnamehpp, "%s.h", aSymbol);
    
    FILE* fhpp = fopen(fnamehpp, "w");
    if (!fhpp)
    {
        printf("Failed to open %s\n", fnamehpp);
        fclose(fhpp);
        return 0;
    }
    
    //int imageSize = images[0].WordSize();
    unsigned int numWords = 0;
    for (int i=0; i<imageCount; ++i)
        numWords += images[i].WordSize();

    fprintf(fhpp, "#ifndef _%s\n", aSymbol);
    fprintf(fhpp, "#define _%s\n\n", aSymbol);
    fprintf(fhpp, "#define %s_count     %i\n", aSymbol, imageCount);
    fprintf(fhpp, "#define %s_bytes     %i\n", aSymbol, numWords * 4);
    fprintf(fhpp, "\nextern const unsigned int* %s_data[%s_count];\n", aSymbol, aSymbol);
    fprintf(fhpp, "\n#endif //_%s\n", aSymbol);
    fclose(fhpp);

    // save source file
    char fnamecpp[256];
    sprintf(fnamecpp, "%s.c", aSymbol);
    FILE* fcpp = fopen(fnamecpp, "w");
    if (!fcpp)
    {
        printf("Failed to open %s\n", fnamecpp);
        fclose(fcpp);
        return 0;
    }

    
    fprintf(fcpp, "#include \"%s.h\"\n\n", aSymbol);

    fprintf(fcpp, "// alpha = %i, compress = %i\n\n", aAlpha, aCompress);
    
    for (int i=0; i<imageCount; ++i)
    {
        fprintf(fcpp, "// %i\n", i);
        fprintf(fcpp, "const unsigned int %s_data_%i[] = {\n", aSymbol, i);
        images[i].WriteCppData(fcpp);
        fprintf(fcpp, "\n};\n\n");
    }
    
    fprintf(fcpp, "\n\nconst unsigned int* %s_data[%s_count] = {\n", aSymbol, aSymbol);
    for (int i=0; i<imageCount; ++i)
    {
        fprintf(fcpp, "  &%s_data_%i[0]", aSymbol, i);
        if (i+1<imageCount)
            fprintf(fcpp, ",\n");
    }
    fprintf(fcpp, "\n};\n");
    
    fclose(fcpp);

    return imageCount;
}


int convert_maps(const char* aFilename, const char* aSymbol)
{
    FILE* f = fopen(aFilename, "r");
    if (!f)
    {
        printf("Failed to open %s", aFilename);
        return 0;
    }
    
    // load maps
    Map maps[16];
    int mapCount = 0;
    char fname[256];
    while (!feof(f))
    {
        if (fscanf(f, "%s", fname) < 1)
            continue;
        
        printf("* Loading map %s...\n", fname);
        
        Map* map = &maps[mapCount];
        map->Load(fname);
        if (!map->IsLoaded())
        {
            printf("### ERROR Failed to load %s\n", fname);
            fclose(f);
            return 0;
        }
        
        mapCount++;
    }
    fclose(f);
    
    if (mapCount == 0)
    {
        printf("### ERROR: No maps loaded\n");
        return 0;
    }
    
    // save header
    char fnamehpp[256];
    sprintf(fnamehpp, "%s.h", aSymbol);
    
    FILE* fhpp = fopen(fnamehpp, "w");
    if (!fhpp)
    {
        printf("Failed to open %s\n", fnamehpp);
        fclose(fhpp);
        return 0;
    }
    
    fprintf(fhpp, "#ifndef _%s\n", aSymbol);
    fprintf(fhpp, "#define _%s\n\n", aSymbol);
    
    fprintf(fhpp, "struct mapData\n");
    fprintf(fhpp, "{\n");
    fprintf(fhpp, "  unsigned char start_x;\n");
    fprintf(fhpp, "  unsigned char start_y;\n");
    fprintf(fhpp, "  unsigned char start_a;\n");
    fprintf(fhpp, "  const unsigned char numdoors;\n");
    fprintf(fhpp, "  const unsigned char* plane0;\n");
    fprintf(fhpp, "  const unsigned int doors[%i];\n", MAP_MAX_DOORS);
    fprintf(fhpp, "};\n\n");
    fprintf(fhpp, "#define NUM_MAPS %i\n", mapCount);
    fprintf(fhpp, "extern const struct mapData mapDatas[NUM_MAPS];\n\n");
    fprintf(fhpp, "\n#endif //_%s\n", aSymbol);
    fclose(fhpp);
    
    
    // save source file
    char fnamecpp[256];
    sprintf(fnamecpp, "%s.c", aSymbol);
    FILE* fcpp = fopen(fnamecpp, "w");
    if (!fcpp)
    {
        printf("Failed to open %s\n", fnamecpp);
        fclose(fcpp);
        return 0;
    }

    fprintf(fcpp, "#include \"%s.h\"\n\n", aSymbol);
    
    for (int i=0; i<mapCount; ++i)
    {
        Map* map = &maps[i];
        fprintf(fcpp, "const unsigned char map_%i_plane0[] = {\n", i);
        map->WriteCppPlane(fcpp, 0);
        fprintf(fcpp, "\n};\n");
    }
    
    fprintf(fcpp, "const struct mapData mapDatas[NUM_MAPS] = {\n");
    for (int i=0; i<mapCount; ++i)
    {
        Map* map = &maps[i];
        fprintf(fcpp, "{\n");
        fprintf(fcpp, "  %i, %i, %i, %i,\n", map->start_x, map->start_y, map->start_a, map->num_doors);
        fprintf(fcpp, "  &map_%i_plane0[0],\n", i);

        fprintf(fcpp, "  { ");
        for (int i=0; i<MAP_MAX_DOORS-1; ++i)
            fprintf(fcpp, "0x%08x,", map->doors[i]);
        fprintf(fcpp, "0x%08x}\n", map->doors[MAP_MAX_DOORS-1]);
        fprintf(fcpp, "}\n");
        if (i+1 < mapCount)
            fprintf(fcpp, ",");
    }
    fprintf(fcpp, "};\n");
    
    fclose(fcpp);
    
    return mapCount;
}

