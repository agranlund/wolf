#ifndef _datMaps
#define _datMaps

struct mapData
{
  unsigned char start_x;
  unsigned char start_y;
  unsigned char start_a;
  const unsigned char numdoors;
  const unsigned char* plane0;
  const unsigned int doors[48];
};

#define NUM_MAPS 10
extern const struct mapData mapDatas[NUM_MAPS];


#endif //_datMaps
