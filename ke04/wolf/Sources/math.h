/*
 * math.h
 *
 *  Created on: Nov 05, 2016
 *      Author: agranlund
 */

#ifndef math_h
#define math_h

#include "types.h"
#include "math_tables.h"

#define FIXED_SHIFT         8
#define FLOAT_TO_FIXED(x)   (((float)(x)) * (float)(1<<FIXED_SHIFT))
#define FIXED_TO_FLOAT(x)   (float)(((float)(x)) / (float)(1<<FIXED_SHIFT))
#define FIXED_TO_INT        ((x)>>FIXED_SHIFT)
#define INT_TO_FIXED        ((x)<<FIXED_SHIFT)

#define ANGLE_SIZE          256
#define ANGLE_MASK          ((ANGLE_SIZE<<FIXED_SHIFT)-1)

#define ANG_0               0
#define ANG_90              ((ANGLE_SIZE<<FIXED_SHIFT) / 4)
#define ANG_180             (ANG_90 * 2)
#define ANG_270             (ANG_90 * 3)
#define ANG_360             (ANG_90 * 4)
#define ANG_45				(ANG_90 / 2)

#define ANG_DEG(x)          ((x * (ANGLE_SIZE<<FIXED_SHIFT) / 360))

#define PI                  3.14157f
#define FIXED_PI            804

#define ANGLE_TO_RAD(x)     (((float)x * 2.0f * PI) / (float)(ANGLE_SIZE<<FIXED_SHIFT))



void math_init();

u16 math_random();

u32 math_dist_approx1(s32 dx, s32 dy);
u32 math_dist_approx2(s32 dx, s32 dy);

s32 math_sin(s32 angle);
s32 math_cos(s32 angle);
s32 math_tan(s32 angle);
s32 math_div_sin(s32 angle);
s32 math_div_cos(s32 angle);
s32 math_div_tan(s32 angle);
s32 math_atan(s32 y, s32 x);

u32 math_one_over(u32 x);

s32 math_point_to_line_distance(s32 x, s32 y, s32 a);
s32 math_line_length_to_point(s32 x, s32 y, s32 a);


#endif /* math_h */
