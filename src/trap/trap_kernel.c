#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc-h/proc.h"
#include "defs.h"

// 外部汇编函数声明
extern char trampoline[], uservec[], userret[];

// 在 kernelvec.S 中，调用 kerneltrap()。
// 内核中断向量函数，处理内核态的中断和异常
extern void kernelvec();

extern int devintr();

static const char* interrupt_info[16] __attribute__((unused)) = {
    "U-mode software interrupt",      // 0
    "S-mode software interrupt",      // 1
    "reserved-1",                     // 2
    "M-mode software interrupt",      // 3
    "U-mode timer interrupt",         // 4
    "S-mode timer interrupt",         // 5
    "reserved-2",                     // 6
    "M-mode timer interrupt",         // 7
    "U-mode external interrupt",      // 8
    "S-mode external interrupt",      // 9
    "reserved-3",                     // 10
    "M-mode external interrupt",      // 11
    "reserved-4",                     // 12
    "reserved-5",                     // 13
    "reserved-6",                     // 14
    "reserved-7",                     // 15
};

// 异常信息
static const char* exception_info[16] __attribute__((unused)) = {
    "Instruction address misaligned", // 0
    "Instruction access fault",       // 1
    "Illegal instruction",            // 2
    "Breakpoint",                     // 3
    "Load address misaligned",        // 4
    "Load access fault",              // 5
    "Store/AMO address misaligned",   // 6
    "Store/AMO access fault",         // 7
    "Environment call from U-mode",   // 8
    "Environment call from S-mode",   // 9
    "reserved-1",                     // 10
    "Environment call from M-mode",   // 11
    "Instruction page fault",         // 12
    "Load page fault",                // 13
    "reserved-2",                     // 14
    "Store/AMO page fault",           // 15
};

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}

// 内核陷阱处理函数
// 来自内核代码的中断和异常通过 kernelvec 到达这里，
// 在当前内核栈上。
//
// 与用户陷阱的区别：
// - 不需要保存用户状态（已经在内核中）
// - 不需要切换页表
// - 主要处理设备中断和内核错误
//
void 
kerneltrap()
{
  int which_dev = 0;
  
  // 保存重要的处理器状态寄存器
  // 这些可能在中断处理过程中被修改
  uint64 sepc = r_sepc();     // 异常程序计数器
  uint64 sstatus = r_sstatus(); // 状态寄存器
  uint64 scause = r_scause();   // 异常原因
  
  // 安全检查：确保我们在管理员模式
  if((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  // 确保中断被禁用（内核中断处理时不应该嵌套中断）
  if(intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  // 处理设备中断
  if((which_dev = devintr()) == 0){
    // 如果不是设备中断，那就是内核错误
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // 内核中的进程调度
  // 如果这是定时器中断，则让出 CPU。
  // 允许在内核执行过程中进行进程切换
  // if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
  //   yield();

  // 恢复处理器状态
  // yield() 可能导致一些陷阱发生，
  // 所以恢复陷阱寄存器供 kernelvec.S 的 sepc 指令使用。
  w_sepc(sepc);
  w_sstatus(sstatus);
}

// 设备中断处理函数
// 检查是否是外部中断或软件中断，
// 并处理它。
// 如果是定时器中断则返回 2，
// 如果是其他设备则返回 1，
// 如果不识别则返回 0。
//
// RISC-V 中断分类：
// - 外部中断：来自外部设备（UART、磁盘等）
// - 软件中断：由软件触发，常用于核间通信
// - 定时器中断：由定时器硬件产生
//
int
devintr()
{
  uint64 scause = r_scause();

  // 检查是否是外部中断
  // scause 的最高位表示是否是中断（1）还是异常（0）
  // 低8位表示中断/异常的具体类型
  if((scause & 0x8000000000000000L) &&
     (scause & 0xff) == 9){
    // 这是一个管理员外部中断，通过 PLIC。
    // PLIC (Platform-Level Interrupt Controller) 管理外部设备中断

    // irq 指示哪个设备产生了中断。
    int irq = plic_claim();  // 获取中断请求号

    // 根据设备类型分发中断处理
    switch(irq){
    case UART0_IRQ:
      uartintr();           // 处理串口中断
      break;
    default:
      if(irq){
        printf("unexpected interrupt irq=%d\n", irq);
      }
      break;
    }

    // 通知 PLIC 中断处理完成
    // PLIC 允许每个设备一次最多产生一个中断；
    // 告诉 PLIC 现在允许设备再次中断。
    if(irq)
      plic_complete(irq);

    return 1;
  } else 
  if(scause == 0x8000000000000001L){
    // 软件中断处理
    // 来自机器模式定时器中断的软件中断，
    // 由 kernelvec.S 中的 timervec 转发。

    // 只有 CPU 0 负责更新全局时钟
    if(cpuid() == 0){
      timer_update();
    }
    
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
  }
}

