/*
 * math.c
 *
 *  Created on: Nov 05, 2016
 *      Author: agranlund
 */

#include "math.h"

#define TABLE_SHIFT    (FIXED_SHIFT-2)

u32 rand_seed = 45841;
u16 math_random()
{
	rand_seed = (214013 * rand_seed + 2531011);
	return (rand_seed>>16) & 0x7FFF;
}

u32 math_dist_approx1(s32 dx, s32 dy)
{
    u32 min, max, approx;

    if ( dx < 0 ) dx = -dx;
    if ( dy < 0 ) dy = -dy;

    if ( dx < dy )
    {
        min = dx;
        max = dy;
    }
    else
    {
        min = dy;
        max = dx;
    }

    approx = ( max * 1007 ) + ( min * 441 );
    if ( max < ( min << 4 ))
        approx -= ( max * 40 );

    return (( approx + 512 ) >> 10 );
}

u32 math_dist_approx2(s32 dx, s32 dy)
{
    if (dx < 0) dx = -dx;
    if (dy < 0) dy = -dy;

    u32 w;
    if ( dy < dx )
    {
        w = dy >> 2;
        return (dx + w + (w >> 1));
    }
    else
    {
        w = dx >> 2;
        return (dy + w + (w >> 1));
    }
}

s32 math_sin(s32 angle)
{
    s32 res;
    if(angle <= ANG_180)
    {
        if(angle < ANG_90)
            res = (s32)sin_table[angle >> TABLE_SHIFT];
        else
            res = (s32)sin_table[(ANG_180 - angle) >> TABLE_SHIFT];
    }
    else
    {
        if(angle <= ANG_270)
            res = -((s32)sin_table[(angle - ANG_180) >> TABLE_SHIFT]);
        else
            res = -((s32)sin_table[(ANG_360 - angle) >> TABLE_SHIFT]);
    }

    return(res);
}

s32 math_div_sin(s32 angle)
{
    s32 res;
    if(angle <= ANG_180)
    {
        if(angle < ANG_90)
            res = (s32)div_sin_table[angle >> TABLE_SHIFT];
        else
            res = (s32)div_sin_table[(ANG_180 - angle) >> TABLE_SHIFT];
    }
    else
    {
        if(angle <= ANG_270)
            res = -((s32)div_sin_table[(angle - ANG_180) >> TABLE_SHIFT]);
        else
            res = -((s32)div_sin_table[(ANG_360 - angle) >> TABLE_SHIFT]);
    }

    return(res);
}

s32 math_cos(s32 angle)
{
    s32 res;

    if(angle <= ANG_180)
    {
        if(angle < ANG_90)
            res = (s32)sin_table[(ANG_90 - angle) >> TABLE_SHIFT];
        else
        {
        	int idx = (angle - ANG_90) >> TABLE_SHIFT;
            res = -((s32)sin_table[(angle - ANG_90) >> TABLE_SHIFT]);
        }
    }
    else
    {
        if(angle < ANG_270)
            res = -((s32)sin_table[(ANG_270 - angle) >> TABLE_SHIFT]);
        else
            res = (s32)sin_table[(angle - ANG_270) >> TABLE_SHIFT];
    }

    return(res);
}

s32 math_div_cos(s32 angle)
{
    s32 res;

    if(angle <= ANG_180)
    {
        if(angle < ANG_90)
            res = (s32)div_sin_table[(ANG_90 - angle) >> TABLE_SHIFT];
        else
            res = -((s32)div_sin_table[(angle - ANG_90) >> TABLE_SHIFT]);
    }
    else
    {
        if(angle < ANG_270)
            res = -((s32)div_sin_table[(ANG_270 - angle) >> TABLE_SHIFT]);
        else
            res = (s32)div_sin_table[(angle - ANG_270) >> TABLE_SHIFT];
    }

    return(res);
}

s32 math_tan(s32 angle)
{
    s32 res;

    if(angle <= ANG_180)
    {
        if(angle <= ANG_90)
            res = (s32)tan_table[angle >> TABLE_SHIFT];
        else
            res = -((s32)tan_table[(ANG_180 - angle) >> TABLE_SHIFT]);
    }
    else
    {
        if(angle <= ANG_270)
            res = (s32)tan_table[(angle - ANG_180) >> TABLE_SHIFT];
        else
            res = -((s32)tan_table[(ANG_360 - angle) >> TABLE_SHIFT]);
    }

    return res;
}

s32 math_div_tan(s32 angle)
{
    s32 res;

    if(angle <= ANG_180)
    {
        if(angle <= ANG_90)
            res = (s32)tan_table[ANGLE_SIZE - (angle >> TABLE_SHIFT)];
        else
            res = -((s32)tan_table[ANGLE_SIZE - ((ANG_180 - angle) >> TABLE_SHIFT)]);
    }
    else
    {
        if(angle <= ANG_270)
            res = (s32)tan_table[ANGLE_SIZE - ((angle - ANG_180) >> TABLE_SHIFT)];
        else
            res = -((s32)tan_table[ANGLE_SIZE - ((ANG_360 - angle) >> TABLE_SHIFT)]);
    }

    return(res);
}

s32 math_atan(s32 y, s32 x)
{
    s32 tanval;
    s32 angle;

    if(x == 0)
    {
        angle = ANGLE_SIZE;
    }
    else if(y == 0)
    {
        angle = 0;
    }
    else
    {
    	tanval = ((y << FIXED_SHIFT) / x);
    	if (tanval < 0)
    		tanval = -tanval;
        angle = 0;

        while(angle <= ANGLE_SIZE)
        {
            if((s32)tan_table[angle] > tanval)
                break;
            angle++;
        }
    }
    angle <<= TABLE_SHIFT;

    if(x < 0)
    {
        if(y > 0)
            angle = ANG_180 - angle;
        else
            angle = ANG_180 + angle;
    }
    else
    {
        if(y < 0)
            angle = ANG_360 - angle;
    }

    return angle;
}


u32 math_one_over(u32 x)
{
	if (x < 512)
		return div_table[x];
	return (1<<16) / x;
}

s32 math_point_to_line_distance(s32 x, s32 y, s32 a)
{
	s32 sina = math_sin(a);
	s32 cosa = math_cos(a);
	s32 d = (((x >> FIXED_SHIFT) * sina) - ((y >> FIXED_SHIFT) * cosa)) >> FIXED_SHIFT;
	return d;
}
s32 math_line_length_to_point(s32 x, s32 y, s32 a)
{
	s32 sina = math_sin(a);
	s32 cosa = math_cos(a);
	s32 d = (((x >> FIXED_SHIFT) * cosa) + ((y >> FIXED_SHIFT) * sina)) >> FIXED_SHIFT;
	return d;
}


