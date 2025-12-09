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

// 文件系统相关的系统调用

uint64 sys_open();
uint64 sys_close();
uint64 sys_read();
uint64 sys_write();
uint64 sys_lseek();
uint64 sys_dup();
uint64 sys_fstat();
uint64 sys_getdir();
uint64 sys_mkdir();
uint64 sys_chdir();
uint64 sys_link();
uint64 sys_unlink();

// 用于测试的块管理系统调用
uint64 sys_alloc_block();
uint64 sys_free_block();
#endif