# WHU 操作系统实践课程代码

## 目录结构
```
Makefile                 顶层构建脚本
README.md                项目说明
document/                实验文档 (lab4.md, lab5.md 等)
kernel/                  构建产物：kernel(ELF)、kernel.asm、kernel.sym
user/                    用户态测试/引导代码 (initcode.c, start.S, user.ld)

src/                     内核源码根目录
  defs.h                 全局函数/类型声明入口
  types.h                基础类型定义
  param.h                系统参数 (NCPU 等)
  riscv.h                RISC-V CSR 访问、位定义、内联辅助

  boot/                  早期引导与第一进程准备
    entry.S              进入内核的第一条汇编（设置栈/清 bss 等）
    start.c              M 模式初始化、委托与 mret 到 main
    main.c               CPU0 初始化 + 启动第一个用户进程
    initcode.S           （若存在）初始用户代码的汇编版本

  devs/                  设备与中断相关驱动
    uart.c               串口输出/输入驱动
    console.c            控制台抽象 (printf 输出落地)
    plic.c               PLIC 中断控制器初始化/分发
    timer.c,timer.h      时钟中断与 ticks 维护

  lib/                   基础库与工具函数
    printf.c             简易 printf/格式化实现
    string.c             常用字符串/内存操作

  mm/                    内存管理
    memlayout.h          物理/虚拟布局常量 (KERNBASE, TRAMPOLINE 等)
    pmem.c               物理页分配器 (kalloc/kfree)
    kvmem.c              内核页表构建/映射 (kvmmake/kvminithart)
    uvmem.c              用户页表相关 (uvmcreate, uvmfirst 等)

  proc/                  进程最小实现与上下文切换
    cpu.c                CPU 结构、mycpu/myproc、PID 分配
    proc.c               创建首个用户进程、页表初始化
    swtch.S              上下文切换保存/恢复 (callee-saved)
  proc-h/                进程/CPU 相关头文件
    cpu.h                CPU 结构与字段声明
    proc.h               进程结构、trapframe/context 定义

  sync/                  同步原语
    spinlock.c/.h        自旋锁实现、push_off/pop_off 中断层次控制

  syscall/               系统调用框架与分发 (Lab5 新增/扩展)
    syscall.c            分发入口 (读取 a7, 写回 a0)
    sysfunc.c            具体内核侧实现函数集合 (包装真正 sys_* 接口)
  syscall-h/             系统调用相关头文件
    sys.h                用户态调用封装/原型
    syscall_arch.h       体系结构特定 ecall 宏与内联汇编
    syscall.h            内核侧声明/分发结构
    sysfunc.h            单个 sys_* 函数原型
    sysnum.h             系统调用号定义 (SYS_* 枚举)

  trap/                  陷阱/中断处理与用户态切换
    kernelvec.S          内核态陷阱向量入口 (跳 kerneltrap)
    trap_kernel.c        内核陷阱处理 (kerneltrap/devintr)
    trap_user.c          用户态陷阱路径/返回逻辑 (usertrap/userret)
    scheduler.c          （预留/扩展）调度器相关实现
    trampoline.S         通用陷阱跳板：保存用户寄存器 + 切换页表 + 返回

  linker/                链接与地址布局
    kernel.ld            链接脚本，控制段、符号、对齐
```

> 说明：`build/` 目录在构建过程中临时生成对象文件，不在此总览中列出；`kernel/` 保留最终产物与符号/反汇编方便调试。

## 更新说明
- **Lab6:** 实现进程管理与调度，包括上下文切换（`swtch.S`）、轮转调度器、`sleep/wakeup` 同步原语。
- 已添加并记录 `document/lab6.md`，包含实现说明、测试代码与运行结果截图。
- 主要修改模块：`src/proc/`（`proc.c`, `cpu.c`, `swtch.S`）、`src/proc-h/`（`proc.h`, `cpu.h`）、`src/trap/`（`trap_kernel.c`, `trap_user.c`, `kernelvec.S`, `trampoline.S`）、`src/sync/`（锁与条件等待实现）、以及用户态测试程序（`user/`）。
- 增强了调度与同步的测试用例（进程切换、僵尸回收、互斥/条件等待验证）。
- 如需更详细的实现细节与调试步骤，请参阅 `document/lab6.md`。

