#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc-h/proc.h"
#include "defs.h"
#include "proc-h/cpu.h"
#include "syscall-h/sysfunc.h"
#include "syscall-h/syscall.h"
#include "syscall-h/sysnum.h"

// 系统调用跳转
static uint64 (*syscalls[])(void) = {
    [SYS_print]         sys_print,
    [SYS_brk]           sys_brk,
    [SYS_fork]          sys_fork,
    [SYS_wait]          sys_wait,
    [SYS_exit]          sys_exit,
    [SYS_sleep]         sys_sleep,
    [SYS_kill]          sys_kill,
    [SYS_getpid]        sys_getpid,
    [SYS_debug]         sys_debug,
    [SYS_open]         sys_open,
    [SYS_close]        sys_close,
    [SYS_read]         sys_read,
    [SYS_write]        sys_write,
    [SYS_lseek]        sys_lseek,
    [SYS_dup]          sys_dup,
    [SYS_fstat]        sys_fstat,
    // [SYS_getdir]       sys_getdir,
    [SYS_mkdir]        sys_mkdir,
    [SYS_chdir]        sys_chdir,
    [SYS_link]         sys_link,
    [SYS_unlink]       sys_unlink,
    //测试：
    [SYS_read_block]   sys_read_block,
    [SYS_release_block] sys_release_block,
    [SYS_show_buf]    sys_show_buf,
    [SYS_write_block] sys_write_block,
};

// 系统调用
void syscall(void)
{
    int num;
    struct proc *p = myproc();

    num = p->tf->a7;
    if(num >= 0 && num < NELEM(syscalls) && syscalls[num]) {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->tf->a0 = syscalls[num]();
    } else {
        printf("pid %d: unknown sys call %d\n",
                p->pid, num);
        p->tf->a0 = -1;
    }
}

/*
    其他用于读取传入参数的函数
    参数分为两种,第一种是数据本身,第二种是指针
    第一种使用tf->ax传递
    第二种使用uvm_copyin 和 uvm_copyinstr 进行传递
*/

// 读取 n 号参数,它放在 an 寄存器中
static uint64 arg_raw(int n)
{   
    proc_t* proc = myproc();
    switch(n) {
        case 0:
            return proc->tf->a0;
        case 1:
            return proc->tf->a1;
        case 2:
            return proc->tf->a2;
        case 3:
            return proc->tf->a3;
        case 4:
            return proc->tf->a4;
        case 5:        
            return proc->tf->a5;
        default:
            panic("arg_raw: illegal arg num");
            return -1;
    }
}

// 读取 n 号参数, 作为 uint32 存储
void arg_uint32(int n, uint32* ip)
{
    *ip = arg_raw(n);
}

// 读取 n 号参数, 作为 uint64 存储
void arg_uint64(int n, uint64* ip)
{
    *ip = arg_raw(n);
}

// 读取 n 号参数指向的字符串到 buf, 字符串最大长度是 maxlen
void arg_str(int n, char* buf, int maxlen)
{
    proc_t* p = myproc();
    uint64 addr;
    arg_uint64(n, &addr);

    uvm_copyin_str(p->pgtbl, (uint64)buf, addr, maxlen);
}

int
fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  if(uvm_copyin_str(p->pgtbl, (uint64) buf, addr, max) < 0)
    return -1;
  return strlen(buf);
}

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}
