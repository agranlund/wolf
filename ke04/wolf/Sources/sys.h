/*
 * sys.h
 *
 *  Created on: Oct 30, 2016
 *      Author: agranlund
 */

#ifndef SOURCES_SYS_H_
#define SOURCES_SYS_H_

#define PROFILE_BEGIN()		profile_start()
#define PROFILE_END()		profile_end()


void profile_start();		// start profiling
uint32 profile_end();		// end profiling, register r0 contains time in us

void Sleep();				// sleep until interrupt/event
void DeepSleep();			// deep sleep until interrupt/event


#endif /* SOURCES_SYS_H_ */
