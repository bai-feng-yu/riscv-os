#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc-h/proc.h"
#include "proc-h/cpu.h"
#include "defs.h"

// in trampoline.S
extern char trampoline[];       // 内核和用户切换的代码
extern char uservec[];          // 用户触发trap进入内核
extern char userret[];          // trap处理完毕返回用户


// 在 kernelvec.S 中，调用 kerneltrap()。
// 内核中断向量函数，处理内核态的中断和异常
extern void kernelvec();

// in trap_kernel.c
extern char* interrupt_info[16]; // 中断错误信息
extern char* exception_info[16]; // 异常错误信息

// 在user_vector()里面调用
// 用户态trap处理的核心逻辑
void trap_user_handler()
{
    uint64 sepc = r_sepc();          // 记录了发生异常时的pc值
    uint64 sstatus = r_sstatus();    // 与特权模式和中断相关的状态信息
    uint64 scause = r_scause();      // 引发trap的原因
    uint64 stval = r_stval();        // 发生trap时保存的附加信息(不同trap不一样)
    proc_t* p = myproc();

    // 确认trap来自U-mode
    if(sstatus & SSTATUS_SPP)
        panic("trap_user_handler: not from u-mode");

    // 当前阶段未使用到的变量，先显式标记避免 -Werror
    (void)sepc; (void)scause; (void)stval; (void)p;

    int which_dev = 0;  // 用于标识设备中断类型

  // 重要：重新设置陷阱向量
  // 将中断和异常发送到 kerneltrap()，
  // 因为我们现在在内核中。
  // 如果在处理用户陷阱时发生内核陷阱（如定时器中断），
  // 应该由 kerneltrap 而不是 usertrap 处理
  w_stvec((uint64)kernelvec);
  
  // 保存用户程序计数器。
  // sepc 寄存器包含发生陷阱时的 PC 值
  p->tf->epc = sepc;
  //printf("usertrap: scause %p pid=%d\n", scause, p->pid);
  // 判断陷阱类型并分别处理
  if(scause == 8){
    // 系统调用处理
    // scause == 8 表示这是一个来自用户模式的 ecall 指令

    // 检查进程是否被标记为需要杀死
    // if(killed(p))
    //   exit(-1);

    // 重要：调整返回地址
    // sepc 指向 ecall 指令，
    // 但我们想返回到下一条指令。
    // RISC-V 指令都是 4 字节，所以 +4
    p->tf->epc += 4;

    // 启用中断
    // 中断会改变 sepc、scause 和 sstatus，
    // 所以只有在我们完成这些寄存器的操作后才启用中断。
    intr_on();
    printf("get a syscall from proc %d\n", myproc()->pid);

    // 调用系统调用处理函数
    // syscall();
  } else if((which_dev = devintr()) != 0){
    printf("usertrap: devintr which_dev=%d\n", which_dev);
    // 设备中断处理
    // devintr() 返回非零值表示这是一个设备中断
    // 正常
  } else {
    // 未知陷阱类型 - 这通常表示程序错误
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    printf("            sepc=%p stval=%p\n", sepc, stval);
    // setkilled(p);  // 标记进程需要被杀死
  }

  // 检查进程是否在陷阱处理过程中被杀死
//   if(killed(p))
//     exit(-1);

  // 进程调度检查
  // 如果这是定时器中断，则让出 CPU。
  // which_dev == 2 表示定时器中断
  // 这是实现抢占式多任务的关键机制
  if(which_dev == 2)
    yield();  // 让出 CPU，调度其他进程

  // 返回用户空间
  trap_user_return();
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
  //printf("trap_user_return\n");
  struct proc *p = myproc();

  // 关闭中断，防止在准备过程中被打断
  // 我们即将将陷阱的目标从 kerneltrap() 切换到 usertrap()，
  // 所以关闭中断直到我们回到用户空间，在那里 usertrap() 是正确的。
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid

  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}