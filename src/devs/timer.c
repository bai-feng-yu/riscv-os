#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc-h/proc.h"
#include "defs.h"

// 计时器
typedef struct timer {
    uint64 ticks;
    struct spinlock lk;
} timer_t;

/*-------------------- 工作在M-mode --------------------*/


// 每个CPU的机器模式定时器中断的临时存储区域
// 每个CPU需要5个64位字的空间来保存中断处理时的上下文
uint64 timer_scratch[NCPU][5];

// kernelvec.S中的汇编代码，用于处理机器模式的定时器中断
extern void timervec();

// 时钟初始化
// called in start.c
// 完成以下设置来接收M-Mode下的时钟中断
// 时钟中断会进入到kernelvec.S中的timervec
// 在这之后会将它们转化为软中断进而被trap.c中的devintr接管
void
timer_init()
{
  // 每个CPU都有独立的定时器中断源
  int id = r_mhartid();

  // 向CLINT(核心本地中断控制器)请求定时器中断
  int interval = 1000000; // 周期数；在QEMU中大约是1/10秒
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;

  // 在scratch[]中为timervec准备信息
  // scratch[0..2] : timervec保存寄存器的空间
  // scratch[3] : CLINT MTIMECMP寄存器地址
  // scratch[4] : 定时器中断之间期望的间隔(周期数)
  uint64 *scratch = &timer_scratch[id][0];
  scratch[3] = CLINT_MTIMECMP(id);
  scratch[4] = interval;
  w_mscratch((uint64)scratch);

  // 设置机器模式的陷阱处理程序
  w_mtvec((uint64)timervec);

  // 启用机器模式中断
  w_mstatus(r_mstatus() | MSTATUS_MIE);

  // 启用机器模式定时器中断
  w_mie(r_mie() | MIE_MTIE);
}

/*--------------------- 工作在S-mode --------------------*/

// 系统时钟
static timer_t sys_timer;

// 时钟创建(初始化系统时钟)
// 陷阱初始化函数
void timer_create()
{
    initlock(&sys_timer.lk, "sys_timer");
    sys_timer.ticks = 0;
}

// 时钟更新(ticks++ with lock)
void timer_update()
{
    acquire(&sys_timer.lk);
    sys_timer.ticks++;
    // printf("ticks: %d\n", sys_timer.ticks);
    release(&sys_timer.lk);
}

// 返回系统时钟ticks
uint64 timer_get_ticks()
{
    uint64 xticks;
    acquire(&sys_timer.lk);
    xticks = sys_timer.ticks;
    release(&sys_timer.lk);
    return xticks;
}