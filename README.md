# WHU 操作系统实践课程代码

## 目录结构
```
document/         实验报告
src/
  boot/           引导相关：entry.S、start/主入口、临时测试 main.c
  devs/           设备驱动（UART 等）
  lib/            公共库（printf、字符串/格式化）
  mm/             内存管理：页表、kalloc、trampoline、vm 相关实现
  proc/           进程（后续实验扩展）
  sync/           同步原语（自旋锁等）
  syscall/        系统调用框架（占位）
  trap/           trap/中断向量与处理（部分待扩展）
  linker/         链接脚本 kernel.ld
kernel/           构建输出：ELF、符号、反汇编
build/            中间文件（.o/.d）
Makefile          构建规则
```
