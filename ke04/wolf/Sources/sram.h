/*
 * sram.h
 *
 *  Created on: Oct 30, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_SRAM_H_
#define SOURCES_SRAM_H_

#include "types.h"

void sram_write(u32 addr, u32 size, u8* data);
void sram_read(u32 addr, u32 size, u8* data);

#endif /* SOURCES_SRAM_H_ */
