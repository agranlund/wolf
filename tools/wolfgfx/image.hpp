//
//  image.hpp
//  wolfgfx
//
//  Created by Anders Granlund on 29/10/16.
//

#ifndef image_hpp
#define image_hpp

#include <stdio.h>

class Image
{
public:
    Image();
    ~Image();
    void Release();
    bool IsLoaded() { return buf ? true : false; }
    
    bool LoadPCX(const char* aFilename, int aPal = 0, bool aAlpha = false, bool aCompress = false);
    bool SaveCPP(const char* aFilename, const char* aSymbol);
    void WriteCppData(FILE* f);
    
    unsigned int BufSize()          { return IsLoaded() ? bufsize : 0; }
    unsigned int WordSize()         { return BufSize() + 3; }
    
private:
    unsigned int width;
    unsigned int height;
    unsigned int bufsize;
    unsigned int* buf;
    unsigned char* image;
    bool alpha;
    bool compressed;
    unsigned int bpp;
    unsigned int pal;
    unsigned int x0;
    unsigned int x1;
    unsigned int y0;
    unsigned int y1;
    unsigned int xmasks[16];
    unsigned int ymasks[16];
};

#endif /* image_hpp */
