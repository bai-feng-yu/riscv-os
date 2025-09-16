# riscv-os

## 仓库结构概览
- document/: 实验文档
- src/
  - boot/: 启动入口 `entry.S` 与早期 C 初始化 `start.c`、示例 `main.c`
  - devs/: 设备驱动（UART、console）
  - lib/: 基础库（printf 等）
  - mm/: 内存与地址布局头文件
  - proc/: 进程子系统雏形
  - sync/: 自旋锁等同步原语
  - linker/: 链接脚本 `kernel.ld`
- kernel/: 构建产物（内核 ELF、符号表等）
- build/: 中间文件