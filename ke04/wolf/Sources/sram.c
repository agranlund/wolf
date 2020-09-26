/*
 * sram.c
 *
 *  Created on: Oct 30, 2016
 *      Author: agranlund
 */

#include "GPIO1.h"
#include "sram.h"

#define SRAM_IO_MASK	(GPIO1_IO_ADDR_MASK | GPIO1_IO_DATA_MASK | GPIO1_IO_OE_MASK | GPIO1_IO_RW_MASK | GPIO1_IO_CE_MASK)

void sram_write(u32 addr, u32 size, u8* data)
{
	// data pins are outputs
    FGPIOA_PDDR |= GPIO1_IO_DATA_MASK;

    // enable sram (OE=1, RW=1, CE=0)
	u32 base = (FGPIOA_PDOR & ~SRAM_IO_MASK) | (1 << GPIO1_IO_OE_START_BIT);
	u32 baseOff = base | (1 << GPIO1_IO_RW_START_BIT);
	FGPIOA_PDOR = baseOff;

	// write to sram
	u32 end = (addr + size) << GPIO1_IO_ADDR_START_BIT;
	addr <<= GPIO1_IO_ADDR_START_BIT;
	u32 out = 0;
	while (addr != end)
	{
		// write address (RW=1)
		FGPIOA_PDOR = baseOff | out;
		out = addr | (((u32)*data++) << GPIO1_IO_DATA_START_BIT);
		// write data (RW=0)
		FGPIOA_PDOR = base | out;
		addr += (1 << GPIO1_IO_ADDR_START_BIT);
	}

	// disable sram (OE=1, RW=1, CE=1)
	FGPIOA_PDOR = baseOff | (1 << GPIO1_IO_CE_START_BIT);
}


void sram_read(u32 addr, u32 size, u8* data)
{
	// data pins are inputs
    FGPIOA_PDDR &= ~GPIO1_IO_DATA_MASK;
    FGPIOA_PIDR &= ~GPIO1_IO_DATA_MASK;

    // enable sram (OE=0, RW=1, CE=0)
    u32 base = (FGPIOA_PDOR & ~SRAM_IO_MASK) | (1 << GPIO1_IO_RW_START_BIT);
	FGPIOA_PDOR = base;

	// write to sram
	u32 end = (addr + size) << GPIO1_IO_ADDR_START_BIT;
	addr <<= GPIO1_IO_ADDR_START_BIT;
	while (addr != end)
	{
		// read address
		__asm("NOP");
		__asm("NOP");
		__asm("NOP");
		__asm("NOP");
		FGPIOA_PDOR = base | addr;
		__asm("NOP");
		__asm("NOP");
		__asm("NOP");
		__asm("NOP");
		// read data
		*data++ = (FGPIOA_PDIR >> GPIO1_IO_DATA_START_BIT); // & GPIO1_IO_DATA_MASK; // <-- no need since data is at 0xFF000000
		addr += (1 << GPIO1_IO_ADDR_START_BIT);
	}

	// disable sram (OE=1, RW=1, CE=1)
	FGPIOA_PDOR = base | (1 << GPIO1_IO_OE_START_BIT) | (1 << GPIO1_IO_CE_START_BIT);
}

