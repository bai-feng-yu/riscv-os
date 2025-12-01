# Lab6 进程管理与调度实验报告

学号：2023302111017  姓名：白峰瑜



## 实验目标

通过深入分析 xv6 的进程管理机制，理解操作系统如何调度进程，实现完整的进程生命周期管理（创建、执行、切换、睡眠、唤醒、退出）和简单的调度算法，并掌握上下文切换的底层细节与同步原语的实现。



## 实验环境

- 架构：RISC-V 64 (Sv39)
- 工具链：riscv64-unknown-elf-gcc
- 模拟器：qemu-system-riscv64 (virt)



## 代码仓库

https://github.com/bai-feng-yu/riscv-os/tree/Lab-6



## 实验测试与结果



### 任务：实现进程管理与调度

#### 测试代码

```c
int main()
{
    syscall(SYS_print, "\nuser begin\n");
    
    // 测试HEAP区域
    long long top = syscall(SYS_brk, 0);
    str2 = (char*)top;
    syscall(SYS_brk, top + PGSIZE);

    str2[0] = 'H';
    str2[1] = 'E';
    str2[2] = 'A';
    str2[3] = 'P';
    str2[4] = '\n';
    str2[5] = '\0';

    int pid = syscall(SYS_fork);

    if(pid == 0) { // 子进程
        for(int i = 0; i < 100000000; i++);
        syscall(SYS_print, "child: hello\n");
        syscall(SYS_print, str2);

        syscall(SYS_kill, syscall(SYS_getpid)); 
        syscall(SYS_print, "child: never back\n");  //测试点1，kill后不打印
    } else {       // 父进程
        int exit_state;        
        syscall(SYS_wait, &exit_state); //测试点2，发现子进程为僵尸进程后重回该进程，证明调度没有问题
        if(exit_state == 1)
            syscall(SYS_print, "parent: hello\n");
        else
            syscall(SYS_print, "parent: error\n"); //因为子进程是被kill的，故返回状态不是1，期待这个返回
    }

    while(1);
    return 0;
}
```

#### 结果展示

<img src="image-3.png" style="width:40%; height: auto;" />

可以看到返回输出都符合我们测试代码的预期。



## 任务列表与问题解答

### 任务1：实现上下文切换机制

#### 上下文切换的本质

上下文切换是指 CPU 从一个进程（或线程）的执行环境切换到另一个的过程。在 xv6 中，这特指内核线程之间的切换（例如从进程 A 的内核态切换到 CPU 调度器，再从调度器切换到进程 B 的内核态）。

1. **哪些寄存器需要保存？**
   - 必须保存 **Callee-saved（被调用者保存）** 寄存器：`s0-s11`, `ra` (返回地址), `sp` (栈指针)。
   - 不需要保存 Caller-saved（调用者保存）寄存器（`t0-t6`, `a0-a7`），因为 `swtch` 是一个普通的 C 函数调用，编译器在调用 `swtch` 之前已经处理好了调用者保存寄存器（如果后续还需要用的话）。

2. **为什么不保存所有寄存器？**
   - 效率：保存所有 32 个通用寄存器 + 浮点寄存器开销太大。
   - 约定：遵循 RISC-V 调用约定（ABI），`swtch` 作为一个函数，只需保证返回时 Callee-saved 寄存器不变，Caller-saved 寄存器由调用方负责。

3. **调用者保存 vs 被调用者保存的区别**
   - **Caller-saved**：函数调用前，如果调用者在函数返回后还需要用到该寄存器的值，必须自己保存；函数内部可以随意修改。
   - **Callee-saved**：函数被调用时，如果函数内部要使用这些寄存器，必须先保存旧值，并在返回前恢复；调用者可以假定调用前后这些寄存器值不变。

#### 栈的切换

- **内核栈 vs 用户栈**：`swtch` 仅涉及 **内核栈** 的切换。每个进程有一个独立的内核栈（`p->kstack`），调度器也有自己的栈（在启动时分配）。用户栈的切换发生在 `trampoline.S` 的 `userret/uservec` 阶段，与 `swtch` 无关。
- **栈指针的保存**：`sp` 寄存器被保存在 `struct context` 中。当 `swtch` 加载新上下文的 `sp` 时，CPU 就切换到了新进程的内核栈上。
- **栈溢出预防**：xv6 在每个内核栈下方设置一个 **Guard Page**（PTE_V 无效页），一旦溢出访问该页会触发缺页异常（Page Fault）导致 panic，而不是静默破坏其他数据。

#### 实现挑战与设计

```c
// 上下文结构体设计
struct context {
  uint64 ra;    // 返回地址：切换回来后从哪里继续执行（通常是 swtch 调用的下一行）
  uint64 sp;    // 栈指针：指向该进程内核栈的当前栈顶
  // Callee-saved registers
  uint64 s0;
  uint64 s1;
  uint64 s2;
  uint64 s3;
  uint64 s4;
  uint64 s5;
  uint64 s6;
  uint64 s7;
  uint64 s8;
  uint64 s9;
  uint64 s10;
  uint64 s11;
};
```

**关键技术点：**

- **原子性**：`swtch` 期间必须持有进程锁（`p->lock`），防止其他 CPU 同时调度该进程。
- **中断管理**：`swtch` 必须在 **关中断** 状态下执行，防止切换过程中发生中断导致状态不一致或死锁。
- **多级栈**：从用户栈 -> 陷阱帧 -> 内核栈 -> 调度器栈，每一层都有明确的切换点。

### 任务2：实现调度器

#### 分析 scheduler() 函数

1. **轮转调度 (Round Robin)**：
   - 调度器在一个无限循环中遍历进程表 `proc[]`。
   - 找到 `RUNNABLE` 的进程后，将其状态设为 `RUNNING`，切换上下文执行。
   - 当进程时间片耗尽（时钟中断触发 `yield`）或主动放弃 CPU（`sleep`）时，状态变回 `RUNNABLE` 或 `SLEEPING`，`swtch` 返回调度器，循环继续。

2. **如何避免忙等待？**
   - 如果遍历一圈没有找到可运行进程，现代 OS 会利用 `wfi` (Wait For Interrupt) 指令让 CPU 进入低功耗休眠状态，直到中断到来。xv6 简化实现中可能只是空转或开启中断等待。

3. **为什么需要开启中断？**
   - 在调度循环内部（`swtch` 之前）必须开启中断（`intr_on`）。
   - 原因：如果所有进程都阻塞（如等待磁盘 I/O），且调度器关中断空转，那么磁盘中断永远无法被处理，进程永远无法被唤醒，系统死锁。

#### 调度时机

- **主动调度**：进程调用 `sleep()`, `exit()`, `wait()` 或 `yield()`。
- **抢占调度**：时钟中断处理程序 (`usertrap` / `kerneltrap`) 检查 `which_dev == 2`，调用 `yield()`。
- **yield() 作用**：将当前进程状态设为 `RUNNABLE`，调用 `sched()` 切换回调度器上下文。

#### 调度器设计考虑

```c
void scheduler(void) {
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  for(;;) {
    intr_on(); // 必须开中断，避免死锁
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);
        // 进程运行... 直到 swtch 返回
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}
```

**算法思考：**

1. **选择下一个进程**：当前是简单的轮询（Round Robin）。
2. **优先级**：可给 `proc` 增加 `priority` 字段，遍历时寻找优先级最高的 `RUNNABLE` 进程。
3. **避免饥饿**：
   - 简单优先级可能导致低优先级饥饿。
   - 解决方案：**老化 (Aging)** 技术（等待越久优先级越高）或 **多级反馈队列 (MLFQ)**。
4. **公平性与效率**：
   - 轮转调度最公平但缓存亲和性差。
   - CFS（完全公平调度）通过虚拟运行时间（vruntime）红黑树平衡公平性与响应速度。

### 任务3：实现进程同步原语

#### 条件变量 (Sleep/Wakeup)

xv6 使用 `sleep(chan, lock)` 和 `wakeup(chan)` 实现同步。`chan` 是一个不透明的地址值（通常是全局数据结构的地址）。

1. **sleep(chan, lk)**：
   - 获取进程锁 `p->lock`。
   - 释放传入的互斥锁 `lk`（原子性关键：持有 `p->lock` 保证了 `lk` 释放后到状态改变前不会被中断）。
   - 修改状态 `p->state = SLEEPING`，记录 `p->chan = chan`。
   - 调用 `sched()` 切换进程。
   - 被唤醒后：重新获取 `lk`，恢复执行。

2. **wakeup(chan)**：
   - 遍历进程表，找到所有 `state == SLEEPING && p->chan == chan` 的进程。
   - 将其状态设为 `RUNNABLE`。

#### 典型使用模式

- **生产者-消费者**：
  - 生产者：`acquire(lock)`; `while(full) sleep(cond_full, lock)`; `produce()`; `wakeup(cond_empty)`; `release(lock)`;
  - 消费者：`acquire(lock)`; `while(empty) sleep(cond_empty, lock)`; `consume()`; `wakeup(cond_full)`; `release(lock)`;
- **Lost Wakeup 问题**：
  - 如果 `sleep` 在释放锁 `lk` 和设置 `SLEEPING` 状态之间存在时间窗口，且此时 `wakeup` 发生，则唤醒信号丢失，进程可能永久睡眠。
  - 解决：xv6 要求 `sleep` 调用时必须持有 `lk`，并在函数内部原子地交换锁（获取 `p->lock` 后才释放 `lk`）。

### 测试与调试策略

#### 调度器测试

- **计算密集型任务**：创建多个死循环进行纯计算的进程，观察控制台输出交替情况或统计运行时间。
- **验证公平性**：记录每个进程获得的 CPU 时间片数量（可在 `trap` 中统计）。

#### 同步机制测试

- **共享缓冲区**：实现一个环形缓冲区，多进程并发读写，验证数据完整性（无覆盖、无重复读取）。
- **死锁检测**：故意构造循环等待场景，观察系统是否卡死（或触发死锁检测器 panic）。

#### 调试建议

- **进程表转储**：实现 `Ctrl+P` 功能，打印所有进程的 PID、状态、名称、PC 指针。
- **调度延迟分析**：在 `p->trapframe` 中记录进入 `RUNNABLE` 的时间戳，在 `scheduler` 选中时计算差值。
- **内存泄漏**：在 `allocproc` 和 `freeproc` 中增加计数器，确保 `fork` 和 `exit` 次数长期平衡。

### 思考题与回答

1. **调度策略**
   - **轮转调度的公平性**：在时间片粒度上是公平的，每个进程都有机会运行。但对于 I/O 密集型进程（频繁放弃 CPU）不公平，因为它们用不完时间片，而计算密集型进程总是占满。
   - **实时调度**：需要 **可抢占内核** 和 **确定性调度延迟**。实现策略包括：优先级继承（解决优先级反转）、硬实时调度算法（如 RMS, EDF）。

2. **性能优化**
   - **fork() 瓶颈**：内存拷贝 (`uvmcopy`)。解决：**COW (Copy-On-Write)**，父子共享物理页，仅在写入时复制。
   - **上下文切换开销**：减少寄存器保存数量（硬件优化）、使用轻量级线程（共享地址空间，切换不刷 TLB）。

3. **资源管理**
   - **资源限制**：在 `struct proc` 中增加 `rlimit` 字段（如最大文件数、最大 CPU 时间、最大内存），在 `sys_sbrk`, `sys_open` 等处检查。
   - **资源泄漏**：`exit()` 必须负责关闭所有打开文件、释放页表和物理内存；父进程 `wait()` 负责释放子进程的内核栈和 `proc` 结构。孤儿进程由 `init` 进程接管并回收。

4. **扩展性**
   - **多核调度**：每个 CPU 一个调度器线程。需要处理 **负载均衡**（Work Stealing：空闲 CPU 从忙碌 CPU 的队列中偷取进程）和 **锁竞争**（细粒度锁，避免全局 `proc` 锁）。
   - **负载均衡**：定期检查各 CPU 运行队列长度，迁移进程以平衡负载，同时考虑 **CPU 亲和性**（尽量保持进程在同一 CPU 运行以利用缓存）。

## 实验总结

本实验通过实现上下文切换汇编、轮转调度器及同步原语，构建了操作系统的核心多任务引擎。理解了“关中断+自旋锁”在保护调度临界区中的关键作用，以及 `sleep/wakeup` 机制如何高效解决同步等待问题。为后续实现更复杂的调度算法（如 MLFQ）和多核扩展打下了基础。