# Lab4 实验报告

## 实验目标
围绕操作系统的进程抽象与管理：
- 理解 xv6 风格的 `struct proc` 字段语义与进程状态机；
- 设计并实现一个可扩展的进程管理子系统（含 PID 分配、表组织、创建/销毁接口）；
- 制定测试与调试策略，并讨论性能与扩展（写时复制、轻量级线程）相关的设计权衡。

## 代码仓库

https://github.com/bai-feng-yu/riscv-os/tree/Lab-4

## 实验环境
- 架构：RISC-V 64 (Sv39)
- 工具链：riscv64-unknown-elf-gcc
- 模拟器：qemu-system-riscv64 (virt)
- 参考：xv6-riscv 源码、现代操作系统教材（进程/线程/虚拟内存章节）

## 实验概述

### 任务1：创建第一个用户进程
#### 测试方法
main 函数相关部分如下：
```c
void main()
{
  if(cpuid() == 0){
    ...
    printf("hart %d starting\n", cpuid());
    ...
    started = 1;         // 标记系统启动完成
    proc_make_fisrt();   // 创建第一个用户进程 

    // 第一个进程运行会进入死循环，
    // 如果下面这句被打印则说明第一个进程创建失败，反之成功
    printf("hart %d proc fail\n", cpuid()); 
  } else {
    //其他CPU等待CPU 0完成初始化
    while(started == 0);
    
    printf("hart %d starting\n", cpuid());
    ...
  }
  intr_on();          // 启用中断
  for(;;){}      
}
```
要达到的目的是：完成启动后，0号CPU陷在首进程用户态的死循环中，其余CPU陷在main()末尾的死循环中。
#### 结果展示
![alt text](<屏幕截图 2025-11-03 122407.png>)

## 问题回答

### 任务1：深入理解进程抽象

下面以 xv6 风格的 `struct proc` 为例，逐字段解释并回答问题：

```c
struct proc {
    struct spinlock lock;       // 保护本进程可变字段（state/chan/killed/xstate 等）
    enum procstate state;       // 进程当前状态 (UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE)
    void *chan;                 // 若在等待，chan 指向等待的通道（例如某个锁/事件地址）
    int killed;                 // 非零表示内核请求终止该进程（异步）
    int xstate;                 // 退出状态（exit code）
    int pid;                    // 进程 ID
    pagetable_t pagetable;      // 用户页表（若在用户态）
    struct trapframe *trapframe;// 保存用户态寄存器、返回点等
    struct context context;     // 调度上下文（保存切换到该进程的 callee-saved 寄存器）
    // 其他常见字段：
    struct proc *parent;        // 父进程指针
    struct file *ofile[NOFILE]; // 打开的文件描述符表
    struct inode *cwd;          // 当前工作目录
    char name[16];              // 进程名称（调试用）
};
```

字段作用说明（逐项）
- `lock`：序列化访问本进程所有可变数据（state、chan、killed、xstate、ofile 等）。避免并发操作导致竞争条件。
- `state`：进程当前状态，状态机决定是否可运行或可回收。
- `chan`：进程睡眠时记录等待的事件地址；唤醒者对该地址进行 `wakeup(chan)`。
- `killed`：由内核或其它进程设置以异步请求终止（例如 `kill(pid)`）。在合适点检查并做退出处理。
- `xstate`：由子进程在退出时设置，父通过 `wait()` 读取该值。
- `pid`：唯一标识进程的整数，内核用来做父子关系查找、权限检查等。
- `pagetable`：用户虚拟地址到物理地址的映射；进程切换时需要切换 `satp`。
- `trapframe`：保存陷阱相关的寄存器（sepc、sstatus 以及用户寄存器），以便在用户态/内核态切换时恢复。
- `context`：仅用于内核调度层面的寄存器保存（当进程被抢占或切换时保存寄存器以便下一次返回）。

进程状态转换图（简化）
- UNUSED -> USED : `allocproc()` 分配并初始化结构
- USED -> RUNNABLE : 创建完毕或 fork 后父/子被标记为 RUNNABLE
- RUNNABLE -> RUNNING : 调度器选择并上下文切换到该进程
- RUNNING -> SLEEPING : 进程主动等待（sleep(chan)）或阻塞于 I/O
- SLEEPING -> RUNNABLE : `wakeup(chan)` 唤醒
- RUNNING -> ZOMBIE : 调用 `exit()` 完成退出并等待父 `wait()` 收割
- ZOMBIE -> UNUSED : 父 `wait()` 收集后释放资源

为什么需要锁保护？
- 多核与并发：多个 CPU 或内核线程可能并发操作同一 `proc`（例如父在 `wait`、子在 `exit`、调度器在 `allocproc`/`free`），需要内存可见性与原子性保障。
- 原子性操作：状态转换与资源释放必须保证原子，否则会产生竞争导致双重释放、丢失唤醒或僵尸进程无法回收。

深入思考
- 为什么需要 ZOMBIE 状态？
  - ZOMBIE 允许内核保留子进程的退出码与少量元数据直到父进程调用 `wait()`，从而把父对子进程终止的同步交付父进程处理（父需要知道退出码与是否子已结束）。若没有 ZOMBIE，子进程资源（尤其 pid）可能被立即回收，父无法得知子退出原因。
- 进程表大小限制的影响
  - 上限（NPROC）限制系统可并发进程数量，影响容错与并发吞吐；过小会导致拒绝服务，过大则占用内存且增加调度开销。设计应考虑瓶颈：文件描述符、内存页、PID 空间。
- 如何防止 PID 重复？
  - 常用策略：单调递增计数器 `nextpid++`，分配时跳过仍在使用的 PID；在 PID 用尽时环回并检查空闲位（需要避免把旧 PID 太早分配给新进程）。配合位图或哈希表加速检查。

### 任务2：分析 xv6 的进程创建机制

1) `allocproc()` 关键点（伪流程）
- 在 `proc[]`（进程表）数组中遍历，寻找 `state == UNUSED` 的槽位；找到后先获取该槽位的 `lock` 并把 `state` 设为 USED。
- 为该进程分配 PID：通常用 `nextpid++` 并赋值给 `p->pid`。
- 分配内核栈：用 `kalloc()` 得到一页作为内核栈，设置 `p->kernel_stack`，并在栈上建立初始 `trapframe` / `context` 帧（用于第一次 `swtch` 返回时进入用户态）。
- 初始化 `trapframe`（将寄存器清零、设置返回点等），并准备 `context` 使调度器可以切换到该进程的 `forkret`/`userret`。

实现细节说明：
- 找空闲槽位：线性扫描 `proc[]`，对每个槽位先获取 `proc_table_lock` 或对每个 `proc` 的 `lock`；xv6 中为了简单通常对整个表做一次全局锁或对每个 `proc` 的 lock 做 CAS 风格保护。
- PID 分配：如上，用 `nextpid`；在竞争环境下 `nextpid` 自身需要原子操作（或在持有进程表锁时更新）。
- 用户栈设置：`allocproc` 分配 kernel stack，然后在该栈顶放置初始 `trapframe`；用户栈（用户地址空间）在 `fork()` 的内存复制中由 `uvmcopy()` 或 `uvmcreate()` 完成。
- 陷阱帧初始化：将通用寄存器清零或复制父寄存器的用户态部分；将 `sepc`、`sstatus` 等设置为合适值以便子进程从 `fork()` 返回。

2) `fork()` 的实现要点
- 步骤回顾：
1. 调用 `allocproc()` 得到新的 `struct proc *np`。
2. 复制父的用户内存：`uvmcopy(parent->pagetable, np->pagetable)`，为子构建一份页表与物理页的拷贝（或在 COW 实现中建立写时复制映射）。
3. 复制陷阱帧：把父的 `trapframe` 内容复制到子（注意子需要把 `a0` 设为 0，表示子返回值为 0）。
4. 设置子 `pid`、`parent` 指针、文件描述符的引用计数等。
5. 将 `np->state` 设为 `RUNNABLE`。

关键问题解答：
- 为什么父子进程有不同的返回值？
  - `fork()` 在父进程返回子 PID，在子进程返回 0。这是由内核在创建子时复制陷阱帧并修改子 `trapframe->a0 = 0`，而父进程在 `fork()` 调用处返回时把子 PID 作为返回值。这样父/子应用程序都能分辨自己。
- 内存复制如何实现？
  - 传统实现：`uvmcopy()` 为子分配新的物理页并把父页内容 memcpy 到子页，建立独立页表映射；缺点是成本高（fork 大量内存时代价显著）。
  - 优化：写时复制（COW）——父子共享只读映射，写时触发页故障由内核为写入方分配新页并复制内容，从而避免不必要的拷贝。
- 失败时资源清理策略：
  - 如果在 `fork()` 的任何一步失败（例如内存不足），需要回滚：释放 `np` 的已分配内核栈、释放已分配的用户物理页/页表、关闭/恢复文件引用计数，并把 `np->state` 设为 `UNUSED`。

3) 进程退出机制分析
- `exit(status)`：
  - 关闭该进程打开的文件（递减引用计数），释放当前工作目录引用；
  - 将状态写入 `p->xstate = status`；把 `p->state` 设为 `ZOMBIE`；唤醒父进程（`wakeup(parent)`)；
  - 将子进程（如果有）的 `parent` 指向 init 进程（PID 1），以防孤儿无法被收割。
- `wait(&status)`：
  - 遍历子进程表寻找 `p->parent == current` 且 `p->state == ZOMBIE` 的进程；若找到则收集 `p->xstate`，释放进程资源（内核栈、页表、proc 结构），返回子 PID；否则阻塞直到子退出或没有子进程。

资源回收时机与方式：
- 只有当父调用 `wait()` 或通过其他收割机制时，才释放 ZOMBIE 的 `proc` 条目；物理内存与文件句柄在 `exit()` 中释放或在收割时彻底清理（视实现细节）。
- 孤儿进程处理：将孤儿 reparent 给 init 进程（PID 1），由 init 定期 `wait()` 并收割这些僵尸。

关键问题：
- `fork()` 的性能瓶颈在哪里？
  - 主要在完整内存复制（`uvmcopy`）上；当进程拥有大量页时，`fork()` 代价高。
  - 另外，创建/初始化页表、复制文件描述符表（引用计数调整）、TLB 与缓存抖动也是开销来源。
- 如何实现写时复制（COW）优化？
  - 在 `fork()` 时：把父的页表标记为只读并在子共享相同物理页（不再复制物理页），把映射类型设为 COW（清写权限）；
  - 在发生写时页故障（store page fault）时，内核为触发写的进程分配新页并 memcpy，然后更新页表恢复写权限；
  - 需要跟踪引用计数（每个物理页），以在最后一个引用释放时真正回收物理内存。

### 任务3：设计你的进程管理系统

设计目标
- 简洁、线程安全、便于调试；后期能无缝扩展到支持线程/轻量级任务与 COW。

1) 进程结构体（建议）
```c
typedef struct proc {
  struct spinlock lock;     // 保护本结构
  int pid;
  enum procstate state;
  struct proc *parent;
  void *chan;
  int killed;
  int xstate;
  pagetable_t pagetable;
  struct trapframe *trapframe;
  struct context context;
  struct file *ofile[NOFILE];
  struct inode *cwd;
  char name[16];
  /* 扩展字段 */
  int exit_signal;
  int pgrp;                 // 进程组 id
} proc_t;
```

2) 进程表组织方式
- 推荐：固定大小数组 `proc[NPROC]`（便于索引、局部性好）+ 空闲链表或位图用于快速分配空槽；同时维护一个 PID->proc 指针哈希表（小型散列表或直接数组，如果 PID 范围小）。

优点/缺点：
- 数组：O(N) 扫描寻找空槽（可用空闲链表优化为 O(1)）；简单且内存连贯。
- 链表：便于动态伸缩，但随机访问（按 PID 查找）较慢；需额外哈希支持。

3) PID 分配策略
- 使用单调递增 `nextpid`（64-bit 或 32-bit）避免频繁重复；当上溢则环回并检查是否空闲；结合位图/哈希避免分配到仍在使用的 PID。

核心接口设计（草案）
```c
struct proc* alloc_process(void);
void free_process(struct proc *p);
int create_process(void (*entry)(void));
void exit_process(int status);
int wait_process(int *status);
```

接口实现要点
- `alloc_process()`：从空闲链表弹出一个 `proc`，初始化字段、分配 kernel stack，并返回；若无空闲则返回 NULL。
- `free_process()`：确保关闭所有文件、释放页表、归还内核栈、将表项回收到空闲链表。
- `create_process(entry)`：调用 `alloc_process()`，设置 `pagetable`（用户栈/文本映像等），设置 `trapframe` 的初始 pc 为 `entry`，并把 `state=RUNNABLE`。
- `exit_process(status)`：设置 `xstate`，关闭资源，唤醒父进程，reparent 子进程到 init，最后设 `state=ZOMBIE`。
- `wait_process()`：阻塞直到任一子进程变为 ZOMBIE，收割并返回其 pid/status。

是否需要进程组/会话？
- 建议支持（简单实现）：为信号与作业控制、终端管理提供基础。初期可不实现；后期可增加 `pgrp` 字段与关系维护函数。

如何处理资源限制？
- 在 `alloc_process()` 或 `create_process()` 中检查资源配额（最大文件数、进程数、最大内存等），返回错误码给用户态。

实现策略（分阶段）
1. 基本功能：实现 `proc` 表、`alloc_process`/`free_process`、`create_process`（内核线程/用户进程两种）、`exit`/`wait`。
2. 父子关系：跟踪父/子链表，确保 `reparent` 正确执行；实现 `waitpid` 等扩展。
3. 优化：引入 COW、页表共享、PID 哈希表、空闲链表并发访问优化（局部锁/分段锁）。

测试与调试策略

进程创建测试（参考用户提供）并补充：
```c
void test_process_creation(void) {
  printf("Testing process creation...\n");
  int pid = create_process(simple_task);
  assert(pid > 0);

  int pids[NPROC]; int count = 0;
  for (int i = 0; i < NPROC + 5; i++) {
    int pid = create_process(simple_task);
    if (pid > 0) pids[count++] = pid;
    else break;
  }
  printf("Created %d processes\n", count);

  // 检查 PID 唯一性
  for (int i = 0; i < count; i++)
    for (int j = i+1; j < count; j++)
      assert(pids[i] != pids[j]);

  // 清理
  for (int i = 0; i < count; i++) wait_process(NULL);
}
```

更多测试项：
- `fork()` 的大内存进程测试（触发并测量 `uvmcopy` 成本）
- COW 正确性：父子并发写同页，触发写时复制并验证数据隔离
- `exit()`/`wait()` 的并发：父在等待子退出，同时子又 fork 出孙子并 exit（检查 reparent 给 init）

思考题
1) 为什么选择这种进程结构设计？
- 选择理由：结构清晰、职责分明（调度相关与用户空间相关字段区分）、利于调试与扩展（添加线程或信号只需扩展字段）。每个字段都与进程管理、调度或资源管理直接对应，便于写出正确且可维护的内核代码。

2) 如何支持轻量级线程？
- 轻量级线程（用户线程）通常共享地址空间但有独立的执行上下文（栈 + context）。内核级线程（LWP）可实现为：
  - 把 `pagetable` 设为共享指针；
  - 让每个线程拥有自己的 `context`（调度上下文）和内核栈；
  - 在调度器中以线程为调度单位；
  - 资源如文件描述符/信号/进程组按需共享或按策略隔离。

实现要点与挑战：
- 共享地址空间导致栈/局部变量冲突；必须为每个线程分配独立用户栈。
- 信号与线程同步语义需清晰（例如 POSIX 线程的行为与信号交互）。

---

## 实验小结
本实验从 `proc` 的每个字段出发，厘清了进程生命周期与状态转换的触发条件，解析了 `allocproc()`、`fork()`、`exit()`、`wait()` 的关键实现点并讨论了故障回滚与性能瓶颈（尤其是内存拷贝）。基于分析给出了一套可扩展的进程管理设计（数组 + 空闲链表 + PID 单调计数 + PID->proc 哈希），并提出了必要的测试用例、COW 优化路线与对轻量级线程的支持策略。

如果你愿意，我可以：
- 基于本设计为仓库添加一个 `proc_manager.c` 的参考实现（含单元测试），或
- 在现有 xv6 风格实现上添加 COW 支持并给出性能比较数据。
