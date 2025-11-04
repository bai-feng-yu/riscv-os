#ifndef __CPU_H__
#define __CPU_H__

#include "types.h"
#include "param.h"
#include "proc-h/proc.h"
#include "spinlock.h"

extern int nextpid;
extern struct spinlock pid_lock;

typedef struct cpu {
    int noff;       // 关中断的深度
    int intena;                 // Were interrupts enabled before push_off()?
    proc_t* proc;   // cpu上运行的进程
    context_t context;  // 内核上下文暂存
} cpu_t;

int     mycpuid(void);
cpu_t*  mycpu(void);
proc_t* myproc(void);
int     allocpid(void);
#endif