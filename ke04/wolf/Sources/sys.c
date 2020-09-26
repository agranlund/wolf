/*
 * sys.c
 *
 *  Created on: Oct 30, 2016
 *      Author: agranlund
 */
#include "Cpu.h"

void Sleep()
{
	__asm("CPSID i");						// disable interrupts
	SCB_SCR &= ~SCB_SCR_SLEEPDEEP_MASK;		// normal sleep
	__asm("wfi");							// enter sleep mode
	__asm("CPSIE i");						// enable interrupts
}


void DeepSleep()
{
	__asm("CPSID i");						// disable interrupts
	SCB_SCR |= SCB_SCR_SLEEPDEEP_MASK;		// deep sleep
	__asm("wfi");							// enter sleep mode
	__asm("CPSIE i");						// enable interrupts
}


void  profile_start()
{
	SYST_RVR = 4800000;		// max time = 100ms
	SYST_CVR = 0;			// reset value
	SYST_CSR = 0x5;			// processor clock + enable
}


uint32 profile_end()
{
	register uint32 v __asm("r0") = (4800000 - SYST_CVR) / 48;
	SYST_CSR = 0;					// disable
	return v;
}


