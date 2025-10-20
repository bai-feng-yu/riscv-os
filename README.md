# WHU 操作系统实践课程代码

## 目录结构
```
document/         实验报告
src/
  boot/           引导相关：entry.S、start.c（M→S 切换）、main.c
  devs/           设备驱动（UART、PLIC、定时器等）
  lib/            公共库（printf、字符串/格式化）
  mm/             内存管理：kalloc/pmem、页表、trampoline、vm 映射
  proc/           进程（后续实验扩展）
  sync/           同步原语（自旋锁等）
  trap/           内核陷阱/中断入口与处理（kernelvec.S、trap.c）
  linker/         链接脚本 kernel.ld
  defs.h          内核对外声明
  types.h         基本类型定义
  param.h         系统参数（NCPU 等）
  riscv.h         RISC-V CSR/位定义与内联汇编
kernel/           构建产物：符号与反汇编（kernel.sym、kernel.asm）
Makefile          构建规则
```
