#ifndef __SYSCALL_H__
#define __SYSCALL_H__

#include "types.h"

// 系统调用主处理函数

void syscall(void);

// 基于参数寄存器编号的读取

void arg_uint32(int n, uint32* ip);
void arg_uint64(int n, uint64* ip);
void arg_str(int n, char* buf, int maxlen);
int argstr(int n, char *buf, int max);

#define argint(n, ip)    arg_uint64(n, (uint64*)(ip))
#define argaddr(n, ip)   arg_uint64(n, (uint64*)(ip))

#endif