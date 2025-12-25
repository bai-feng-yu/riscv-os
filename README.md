# WHU 操作系统实践课程代码

## 快速开始

### 依赖
- RISC-V 交叉工具链：`riscv64-unknown-elf-gcc` / `riscv64-unknown-elf-ld` / `riscv64-unknown-elf-objcopy`
- QEMU：`qemu-system-riscv64`

### 构建与运行
在仓库根目录执行：

```sh
make qemu
```

该命令会构建内核与用户程序、生成 `fs.img`，并以 `-nographic` 方式启动 QEMU。

### 交互与退出
- 看到 `test>` 提示符表示已 `exec("/test")` 进入用户态测试程序
- 在 QEMU 窗口中输入任意一行并回车，程序会回显输入
- 退出 QEMU：`Ctrl-A` 后按 `X`

## 默认用户程序
当前默认打包进镜像的用户程序由 `Makefile` 的 `UPROGS` 控制，默认包含 `user/_test`，写入镜像后的文件名为 `/test`（前导下划线会被去掉）。

`user/initcode.c` 会 fork 并 `exec("/test")`，用于验证：
- `exec` 系统调用链路
- 标准输入输出与 console 设备
- UART 中断到 console 行缓冲的输入闭环

## 目录结构
核心代码主要在 src/ 与 user/；其余为构建工具、实验文档与构建产物。

- src/: 内核源码（启动/陷入/进程/内存/文件系统/驱动/系统调用等）
- user/: 用户态程序与用户态启动入口（initcode、start.S、链接脚本等）
- mkfs/: 生成文件系统镜像的工具（构建时用于产出 fs.img）
- document/: 实验文档（如 lab8.md）
- build/: 编译产物目录（自动生成，可删除后重建）
- kernel/: 内核最终产物与反汇编输出（自动生成）

简化后的目录概览：

```
.
├── Makefile
├── README.md
├── document/
│   ├── lab7.md
│   └── lab8.md
├── mkfs/
│   └── mkfs.c
├── src/
│   ├── boot/        # entry/start/main 等
│   ├── devs/        # console/uart/timer/virtio 等
│   ├── fs/          # inode/dir/log/pipe 等
│   ├── lib/         # printf/string
│   ├── linker/      # kernel.ld
│   ├── mm/          # kvmem/uvmem/pmem
│   ├── proc/        # proc/swtch/cpu
│   ├── syscall/     # syscall/sysfile/sysfunc
│   └── trap/        # trampoline/trap_kernel/trap_user
└── user/
    ├── initcode.c
    ├── start.S
    └── user.ld
```

## 常见现象
- 运行停在 `test>`：这不是卡死，表示用户程序正在阻塞等待标准输入；在 QEMU 窗口输入一行回车即可。









