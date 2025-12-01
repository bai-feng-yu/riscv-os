#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc-h/proc.h"
#include "defs.h"
#include "proc-h/cpu.h"
//#include "mem/mmap.h"
#include "devs/timer.h"
#include "syscall-h/sysfunc.h"
#include "syscall-h/syscall.h"
#include "syscall-h/sysnum.h"

// 堆伸缩
// uint64 new_heap_top 新的堆顶 (如果是0代表查询, 返回旧的堆顶)
// 成功返回新的堆顶 失败返回-1
uint64 sys_brk()
{
    uint64 new_addr;
    uint64 old_addr = myproc()->sz;  // 保存原始堆顶

    arg_uint64(0, &new_addr);  // 正确读取64位地址
    
    if(new_addr == old_addr || new_addr == 0) {
        return old_addr;  // 无变化，返回当前堆顶
    }
    
    int diff = (int)(new_addr - old_addr);
    
    // 检查是否溢出
    if((uint64)diff != (new_addr - old_addr)) {
        return -1;  // 差值太大，int无法表示
    }

    if(growproc(diff) < 0) {
        return -1;  // 扩展失败
    }
    
    return new_addr;  // 返回扩展前的地址
}

uint64
sys_kill(void)
{
  uint64 pid;

  arg_uint64(0, &pid);
  return kill(pid);
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}
// 打印字符
// uint64 addr
uint64 sys_print()
{
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));

    printf("%s", buf);
    return 0;
}

// 进程复制
uint64 sys_fork()
{
    return fork();
}

// 进程等待
// uint64 addr  子进程退出时的exit_state需要放到这里 
uint64 sys_wait()
{
    uint64 p;
    arg_uint64(0, &p);
    return wait(p);
}

// 进程退出
// int exit_state
uint64 sys_exit()
{
    uint64 n;
    arg_uint64(0, &n);
    exit(n);
    return 0;  // not reached
}

extern timer_t sys_timer;

// 进程睡眠一段时间
// uint32 second 睡眠时间
// 成功返回0, 失败返回-1
uint64 sys_sleep()
{
    uint64 n;
    uint ticks0;

    arg_uint64(0, &n);
    acquire(& sys_timer.lk);
    ticks0 = sys_timer.ticks;
    while(sys_timer.ticks - ticks0 < n){
        if(killed(myproc())){
        release(&sys_timer.lk);
        return -1;
        }
        sleep(&sys_timer.ticks, &sys_timer.lk);
    }
    release(& sys_timer.lk);
    return 0;
}


uint64 sys_debug(void)
{
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));

    printf("[debug] %s \n", buf);
    return 0;
}

