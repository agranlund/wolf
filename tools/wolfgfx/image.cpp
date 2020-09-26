//
//  image.cpp
//  wolfgfx
//
//  Created by Anders Granlund on 29/10/16.
//

#include "image.hpp"
#include <stdio.h>
#include <string.h>

Image::Image()
{
    buf = nullptr;
    image = nullptr;
}

Image::~Image()
{
    Release();
}

void Image::Release()
{
    if (buf)
        delete[] buf;
    if (image)
        delete [] image;
    buf = nullptr;
}

bool Image::LoadPCX(const char* aFilename, int aPal, bool aAlpha, bool aCompress)
{
    Release();

    struct PCXHeader
    {
        unsigned char   id;
        unsigned char   version;
        unsigned char   encoding;
        unsigned char   bpp;
        unsigned short  x1;
        unsigned short  y1;
        unsigned short  x2;
        unsigned short  y2;
        unsigned short  hres;
        unsigned short  vres;
        unsigned char   pal[16*3];
        unsigned char   reserved;
        unsigned char   num_planes;
        unsigned short  bytes_per_line;
        unsigned short  pal_t;
        unsigned char   filler[58];
    };

    FILE* f = fopen(aFilename, "rb");
    if (!f)
        return false;
    
    fseek(f, 0, SEEK_END);
    size_t fsize = ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char* fdata = new unsigned char[fsize];
    fread(fdata, fsize, 1, f);
    fclose(f);

    PCXHeader* hdr = (PCXHeader*)fdata;

    bool fok = true;
    
    if (hdr->id != 0x0A)
        fok = false;
    if (hdr->encoding != 1)
        fok = false;
    if (hdr->bpp != 8)
        fok = false;

    if (!fok)
    {
        delete[] fdata;
        return false;
    }

    // decompress original image
    width = (unsigned char) (hdr->x2 - hdr->x1 + 1);
    height = (unsigned char) (hdr->y2 - hdr->y1 + 1);
    image = new unsigned char[width * height];
    int src = 128;
    int dst = 0;
    for (int y=0; y<height; ++y)
    {
        for (int x=0; x<hdr->bytes_per_line; )
        {
            unsigned char val = fdata[src++];
            if (val > 192)
            {
                val -= 192;
                unsigned int color = (/*0xFF -*/ (fdata[src++])) & (aAlpha ? 7 : 3);
                for (unsigned char r=0; (r<val) && ((r+x)<width); r++)
                {
                    image[dst] = color;
                    dst++;
                }
                x += val;
            }
            else
            {
                if (x < width)
                {
                    unsigned char color = (/*0xFF -*/ val) & (aAlpha ? 7 : 3);
                    image[dst] = color;
                    dst++;
                }
                x++;
            }
        }
    }
    
    
    // convert to output format
    alpha = aAlpha;
    bpp = 2 + (alpha ? 1 : 0);
    pal = (aPal & 7);

    int numbits = width * height * bpp;
    bufsize = (numbits + 31) / 32;
    buf = new unsigned int[bufsize];
    memset(buf, 0, bufsize*4);
    
    printf("Bitplane size  = %i x %i\n", width, height);
    printf("Bitplane count = %i\n", bpp);
    printf("Image alpha    = %s\n", alpha ? "Yes" : "No");
    printf("Size in bits   = %i\n", numbits);
    printf("Size in bytes  = %i\n", bufsize * 4);
    printf("Size in words  = %i\n", bufsize);

    if (alpha)
    {
        x0 = width;
        x1 = 0;
        y0 = height;
        y1 = 0;
    }
    else
    {
        x0 = 0;
        x1 = width;
        y0 = 0;
        y1 = height;
    }

    memset(xmasks, 0, 16*4);
    memset(ymasks, 0, 16*4);
    
    src = 0;
    int dsta = 0;
    int dst0 = (width * height) * (alpha ? 1 : 0);
    int dst1 = (width * height) * (alpha ? 2 : 1);

    for (int y=0; y<height; ++y)
    {
        for (int x=0; x<width; ++x)
        {
            unsigned char color = image[src++];
            buf[dst0/32] |=  ((color & 1) << (dst0 % 32));
            dst0++;
            buf[dst1/32] |= (((color & 2) >> 1) << (dst1 % 32));
            dst1++;
            if (alpha)
            {
                unsigned int a = (color & 4) >> 2;
                if (a == 0)
                {
                    if (x < x0) x0 = x;
                    if (x > x1) x1 = x;
                    if (y < y0) y0 = y;
                    if (y > y1) y1 = y;
                    xmasks[x/32] |= (1 << (x % 32));
                    ymasks[y/32] |= (1 << (y % 32));
                }
                buf[dsta/32] |= (a << (dsta % 32));
                dsta++;
            }
        }
    }
    /*
    if (alpha)
    {
        for (int y=y0; y<=y1; ++y)
        {
            for (int x=x0; x<=x1; ++x)
            {
                xmasks[x/32] |= (1 << (x%32));
            }
            ymasks[y/32] |= (1 << (y%32));
        }
    }
    */
    
   
    compressed = false;
    if (aCompress)
    {
        unsigned int* cbuf = new unsigned int[bufsize*2];
        unsigned int cbufsize = 0;
        int srcpos = 0;
        while (srcpos < bufsize)
        {
            unsigned int d = buf[srcpos];
            
            unsigned int count = 1;
            for (int i=srcpos+1; i<bufsize; ++i)
            {
                if (buf[i] != d)
                    break;
                count++;
                if (count == 255)
                    break;
            }
            srcpos += count;
            
            if ((count > 1) || ((d >> 8) == 0xAAAAAA))
            {
                cbuf[cbufsize+0] = 0xAAAAAA00 | count;
                cbuf[cbufsize+1] = d;
                cbufsize += 2;
            }
            else
            {
                cbuf[cbufsize] = d;
                cbufsize++;
            }
        }
        
        if (cbufsize < bufsize)
        {
            delete[] buf;
            buf = cbuf;
            bufsize = cbufsize;
            compressed = true;
            printf("Compressed to  = %i\n", bufsize);
        }
    }
    
    delete[] fdata;
    return true;
}

bool Image::SaveCPP(const char* aFilename, const char* aSymbol)
{
    if (!IsLoaded())
        return false;
    
    FILE* f = fopen(aFilename, "w");
    if (!f)
        return false;
    
   
    fprintf(f, "const unsigned int %s[] = {\n", aSymbol);
    WriteCppData(f);
    fprintf(f, "\n};\n\n");
    fclose(f);
    return false;
}

void Image::WriteCppData(FILE* f)
{
    unsigned int flags = 0;

    if (alpha)
        flags |= (1<<0);
    if (compressed)
        flags |= (1<<1);

    unsigned char xwords = (width+31) / 32;
    unsigned char ywords = (height+31) / 32;
    unsigned char imgoffs = 4 + (alpha ? (xwords + ywords) : 0);
    
    unsigned int hdr0 = ((width & 0xFF) << 24) | ((height & 0xFF) << 16) | (bufsize & 0xFFFF);
    unsigned int hdr1 = ((x0 & 0xFF) << 24) | ((x1 & 0xFF) << 16) | ((y0 & 0xFF) << 8) | ((y1 & 0xFF) << 0);
    unsigned int hdr2 = ((pal & 0xFF) << 24) | ((bpp & 0xFF) << 16) | ((imgoffs & 0xFF) << 8) | ((flags & 0xFF) << 0);
    unsigned int hdr3 = ((xwords & 0xFF) << 24) | ((ywords & 0xFF) << 16);
    
    fprintf(f, "  0x%08x, 0x%08x, 0x%08x, 0x%08x", hdr0, hdr1, hdr2, hdr3);
    if (alpha)
    {
        for (int x=0; x<xwords; ++x)
            fprintf(f, ", 0x%08x", xmasks[x]);
        for (int y=0; y<ywords; ++y)
            fprintf(f, ", 0x%08x", ymasks[y]);
    }
    for (int i=0; i<bufsize; ++i)
    {
        unsigned int d = buf[i];
        if (((i) & 7) == 0)
            fprintf(f, ",\n  0x%08x", d);
        else
            fprintf(f, ", 0x%08x", d);
    }
}

