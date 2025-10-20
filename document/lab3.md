# Lab3 实验报告

## 实验目标
围绕 RISC-V 中断子系统与时钟调度：
- 理解 RISC-V 下 Machine/Supervisor 两级中断/异常委托与寄存器体系。
- 阅读 xv6 的 trap / timer 初始化流程，掌握内核中断向量、上下文保存与分发机制。
- 设计并实现最小可运行的中断处理框架与时钟中断驱动（tick 推进 + 调度触发）。
- 初步建立异常分类处理（系统调用、页故障等）与测试、调试策略。

## 代码仓库

https://github.com/bai-feng-yu/riscv-os/tree/Lab-3

## 实验环境
- 架构：RISC-V 64 (Sv39)
- 工具链：riscv64-unknown-elf-gcc
- 模拟器：qemu-system-riscv64 (virt)
- 参考：RISC-V 特权级规范 / SBI Timer 扩展 / xv6-riscv 源码

## 实验概述
- 分析中断委托：medeleg / mideleg 选择性地将某些异常/中断交给 S 模式，提高内核（S）对硬件事件的直接处理能力，减少频繁进出 M 模式开销。
- 计时与调度：利用 SBI 提供的 `sbi_set_timer()` 设置下一次时钟中断，建立周期 tick；在 tick 里更新内核时间并触发调度点。
- 中断分发：通过 scause 判定是“中断/异常”以及具体来源（时钟、外部、软件），调用对应处理器函数；异常则使用统一表或 switch 进行分类。
- 上下文保存：内核态入口（如 kernelvec.S）保存需要的寄存器集合到栈或 trapframe，保证可重入与 C 处理逻辑安全执行。

## 实验概述与问题回答

### 任务1：理解 RISC-V 中断架构

#### 1) 中断特权级委托
- Machine → Supervisor 通过 mideleg（中断）与 medeleg（异常）寄存器进行委托。
- medeleg：位图，决定哪些异常（例如环境调用、页故障）直接在 S 处理。
- mideleg：位图，决定哪些中断（例如定时器、外部中断）在 S 处理。
- 为什么需要委托：
  - 降低从硬件事件到 OS 处理路径的特权切换层数（避免频繁 M→S→M）；
  - 让 S 模式内核可以直接响应常见事件（时钟、外部设备），M 模式保持最小化（类似“固件”）。
- 应该委托哪些中断：
  - S 态自身要处理的：Supervisor Timer Interrupt (STI)、Supervisor External Interrupt (SEI)、Supervisor Software Interrupt (SSI)；
  - Machine Timer 通常在 M 产生，再通过委托 / 或 M 代码改写为 S 计划（xv6 通过 M 模式的 timervec 设置下一次时钟并后跳 S）。

#### 2) 中断寄存器组合
- mie/sie：中断使能寄存器（M/S 对应级别可使能具体来源位）。
- mip/sip：中断挂起状态寄存器（硬件置位，软件可读清某些软中断）。
- mtvec/stvec：异常 / 中断向量表基地址；MODE 决定 direct 或 vectored。
- mcause/scause：记录 trap 原因（最高位=1 表示中断，低位编码具体类型）。

#### 深入思考
- 时钟中断为什么在 M 产生却在 S 处理：
  - 硬件定时器（CLINT/SBI 层）通常以 M 模式接口呈现，M 负责最底层与固件协作，再委托给 S 简化 OS 实现。
- “中断是异步，异常是同步”理解：
  - 异常：由当前执行指令自身引起（非法指令、页故障）→ 与该指令同步。
  - 中断：外部事件（定时器、I/O）异步到来，打断当前指令流。

---

### 任务2：分析 xv6 的中断处理流程

#### 1) start.c 中机器模式设置
代码逻辑（概念化）：
```c
// 委托 S 处理的异常 / 中断位
w_mideleg(r_mideleg() | (1 << IRQ_S_TIMER));
w_medeleg(r_medeleg() | EXC_ECALL_U | EXC_INST_PAGE | EXC_LOAD_PAGE | EXC_STORE_PAGE);

// 设置机器模式 trap 向量 (timervec)
w_mtvec((uint64)timervec);
```
- 时钟中断特殊处理原因：需要 M/S 协作设置下一次触发时间，并委托后续常规处理给 S（内核调度在 S 态）。
- timervec 作用：
  - M 模式 trap 入口；
  - 保存最小上下文；
  - 调用 SBI 设置下一次时钟；
  - 切换回 S 模式（或跳转到在 S 的 trap 入口）。

#### 2) kernelvec.S 上下文切换
- 保存哪些寄存器：一般保存 caller-saved + callee-saved (通用寄存器) 以便 C 代码安全使用；xv6 保存 ra、sp、gp、tp、t0–t6、s0–s11、a0–a7。
- 为什么不保存所有：CSR 只在需要读取/修改时单独处理；浮点/向量寄存器未启用或延迟保存策略。
- 栈使用策略：进入内核后使用当前 hart 的内核栈；若来自用户态，则通过 trapframe 指向进程的内核栈再切换。

#### 3) trap.c 中断分发（概念示例）
```c
void kerneltrap(void){
  uint64 sc = r_scause();
  if(sc & (1ULL<<63)){ // 中断
    if((sc & 0xff) == SCAUSE_TIMER) handle_timer();
    else if((sc & 0xff) == SCAUSE_EXT) handle_external();
    else if((sc & 0xff) == SCAUSE_SOFT) handle_soft();
  }else{ // 异常
    handle_exception(sc, r_stval());
  }
}
```
- 中断重入：通常在进入后清/屏蔽同级中断（sie 清位），处理完再开；或避免长时间持锁。
- 处理过长后果：
  - 延迟其它高优先级中断响应；
  - 调度粒度变粗；
  - 可能导致“丢 Tick”或软实时失准。

---

### 任务3：设计你的中断处理框架

#### 设计接口
```c
typedef void (*interrupt_handler_t)(void);

void trap_init(void);                      // 初始化全局中断框架 (设置 stvec, 开启 sie 指定位)
void register_interrupt(int irq, interrupt_handler_t h); // 注册
void enable_interrupt(int irq);
void disable_interrupt(int irq);
```

#### 关键设计点
- 中断向量表：数组 `handlers[IRQ_MAX]`；未注册时指向默认处理（打印 & 统计）。
- 优先级：简单版按 IRQ 编号先后；进阶可添加优先队列或多数组（高优先级单独快速路径）。
- 中断嵌套：初版禁用（进入后清 sie）；后续支持：在保存完上下文后，允许更高优先级打开。
- 共享中断：采用链表或多播数组；所有 handler 依次执行，若某 handler 声明“已处理”则可提前结束。

#### 实现策略
1. 最小实现：只支持时钟中断（IRQ_TIMER），其它都忽略/统计。
2. 增量：加入外设（如 UART）中断 → 注册 + 读写寄存器清 pending。
3. 性能：
   - 减少在入口保存的寄存器（有明确 ABI 区分）。
   - 使用 `likely()/unlikely()` 分支提示。

---

### 任务4：实现上下文保存与恢复

#### 必须保存的寄存器集合
- 通用寄存器 x1–x31（除零寄存器）；确保 C 代码自由使用。
- CSR：sepc / sstatus 需在进入时保存，在返回前恢复（或修改以实现返回位置/特权切换）。
- a0–a7：可能携带系统调用参数，必须保留在 trapframe 供处理使用。

#### 栈管理
- 为每个 hart/进程准备内核栈；用户态 trap 时切换到内核栈。
- 中断栈溢出防护：可在栈底放哨兵（magic），调试期周期检测；或在页表为栈下方映射一个不可访问页造成早期触发。
- 多级中断：初版关闭嵌套；若开启，进入后快速恢复 sie 允许高优先级抢占。

#### 汇编入口框架（示意）
```asm
kernelvec:
  addi  sp, sp, -SWITCH_FRAME_SIZE
  sd    ra, 0(sp)
  sd    sp, 8(sp)       # 可选：若需要链式栈帧
  sd    gp, 16(sp)
  sd    t0, 24(sp)
  # ... 保存其余寄存器 ...
  csrr  t0, sepc
  sd    t0, OFFSET_SEPC(sp)
  csrr  t0, sstatus
  sd    t0, OFFSET_SSTATUS(sp)
  call  kerneltrap
  # 恢复 sepc/sstatus
  ld    t0, OFFSET_SEPC(sp)
  csrw  sepc, t0
  ld    t0, OFFSET_SSTATUS(sp)
  csrw  sstatus, t0
  # ... 恢复寄存器 ...
  addi  sp, sp, SWITCH_FRAME_SIZE
  sret
```

---

### 任务5：实现时钟中断与调度

#### 时钟中断流程
1. S 态中断入口识别 `scause` 为 S-Timer。
2. 读取 `time`（SBI call 或内存映射 CLINT）。
3. `sbi_set_timer(current_time + interval)` 设置下一次 tick。
4. `ticks++` & 更新系统时间源。
5. 若到达调度周期（如 ticks % SCHED_SLICE == 0），设置调度标志或直接调用 `yield()`。

#### 关键函数示例
```c
void timer_interrupt(void){
  uint64 now = get_time();
  sbi_set_timer(now + TICK_INTERVAL);
  ticks++;
  run_timer_callbacks(); // 可选：定时事件
  if(ticks % SCHED_SLICE == 0)
    yield(); // 或设置 need_resched 标志，返回后在 trap 尾部调度
}
```

#### 调度的原子性
- 在修改调度标志期间临时关闭本地中断；
- 或使用自旋锁保护 `ticks` 与回调队列。

---

### 任务6：异常处理机制

#### 常见异常分类（部分编码示例）
| 异常 | 说明 |
|------|------|
| 0 | 指令地址未对齐 |
| 1 | 指令访问故障 |
| 2 | 非法指令 |
| 3 | 断点 |
| 4 | 加载地址未对齐 |
| 5 | 加载访问故障 |
| 6 | 存储地址未对齐 |
| 7 | 存储访问故障 |
| 8 | 环境调用 U 模式 (ECALL from U) |
| 9 | 环境调用 S 模式 |
| 12 | 指令页故障 |
| 13 | 加载页故障 |
| 15 | 存储/AMO 页故障 |

#### 处理框架
```c
void handle_exception(struct trapframe *tf){
  uint64 cause = r_scause();
  switch(cause){
    case 8:  handle_syscall(tf); break;
    case 12: handle_instruction_page_fault(tf); break;
    case 13: handle_load_page_fault(tf); break;
    case 15: handle_store_page_fault(tf); break;
    default: panic("Unknown exception");
  }
}
```

#### 设计要点
- 系统调用：调整 sepc（跳过 ecall）、设置返回寄存器。
- 页故障：判断是否合法需求（按需分配 / COW / 直接杀进程）。
- 非法指令：打印上下文后终止进程（或 panic）。

---

## 测试与调试策略

### 1) 中断功能测试
```c
void test_timer_interrupt(void){
  printf("Testing timer interrupt...\n");
  uint64 start = get_time();
  extern volatile int ticks; int base = ticks;
  while(ticks < base + 5){ /* busy wait or low-power */ }
  uint64 end = get_time();
  printf("Got %d ticks in %lu cycles\n", ticks-base, end-start);
}
```

### 2) 异常处理测试
- 触发非法指令：内联 `.word 0xFFFFFFFF`。
- 访问未映射地址：读写一个明确超界指针。
- 系统调用：执行 `ecall` 并检查返回值。

### 3) 性能测试
```c
void test_interrupt_overhead(void){
  uint64 t0 = get_time();
  int n = 1000; for(int i=0;i<n;i++){ __asm__ volatile("ecall"); }
  uint64 t1 = get_time();
  printf("%d syscalls cost %lu cycles\n", n, t1-t0);
}
```

### 分阶段调试
1. 基础设置：确认 stvec 对齐、sie 中 STIE 位置 1、mideleg/mideleg 设置。
2. 触发测试：在 timer 中断 handler 打印一次并迅速关闭打印避免淹没输出。
3. 上下文校验：比对进入/退出时 a0~a7、sepc 是否保持或按预期变化。

### 常见问题
| 问题 | 排查 |
|------|------|
| 中断无响应 | sie/stie 未开；mideleg 未委托；stvec 错误 |
| 时钟频率异常 | interval 计算溢出；未重设下一次 sbi_set_timer |
| 返回后崩溃 | sepc/sstatus 恢复错误；栈破坏；保存集合不足 |
| 重入死锁 | 在中断中获取已持有锁；未禁止嵌套 |

---

## 思考题回答
1) 为什么时钟中断先在 M 处理再到 S：底层硬件/固件接口在 M；S 保持通用 OS 逻辑。优先级体系：可通过多级寄存器位掩码或软件优先队列实现。
2) 开销与优化：热点在保存/恢复上下文、频繁的 CSR 访问、TLB/I-cache 干扰；可减少保存集合、合并延迟处理、批量调度。
3) 安全性：限制中断 handler 运行时间；禁止阻塞调用；校验来源；异常路径防止越界访问；未识别中断统计后屏蔽。
4) 扩展性：向量表抽象 + 注册接口；共享中断使用链表派发；动态路由基于设备树或 ACPI-like 描述。
5) 实时性：减少关中断窗口；精确定时器（使用 64 位时间源）；支持优先级抢占与高精度 tickless 设计（设置最早事件时间）。

---

## 实验小结
本实验构建了从中断委托、向量入口、上下文保存、分发到时钟驱动调度的一条完整链路，并回答了架构/设计/性能/扩展/实时等关键问题；为后续用户态、系统调用与进程调度奠定基础。
