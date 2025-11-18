#ifndef __SYSFUNC_H__
#define __SYSFUNC_H__

#include "types.h"

uint64 sys_brk();
uint64 sys_copyin();
uint64 sys_copyout();
uint64 sys_copyinstr();

uint64 sys_debug(void);

#endif