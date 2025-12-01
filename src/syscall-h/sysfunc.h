#ifndef __SYSFUNC_H__
#define __SYSFUNC_H__

#include "types.h"

uint64 sys_print();
uint64 sys_brk();
uint64 sys_kill();
uint64 sys_getpid();
uint64 sys_fork();
uint64 sys_wait();
uint64 sys_exit();
uint64 sys_sleep();

uint64 sys_debug(void);

#endif