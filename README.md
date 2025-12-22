# WHU 操作系统实践课程代码

## 目录结构
```
Makefile
README
README.md
document/
  lab7.md
kernel/
  kernel.asm
mkfs/
  mkfs.c
src/
  defs.h
  param.h
  riscv.h
  types.h
  boot/
    entry.S
    initcode.S
    main.c
    start.c
  devs/
    console.c
    plic.c
    timer.c
    timer.h
    uart.c
    virtio_disk.c
    virtio.h
  fs/
    bio.c
    bitmap.c
    buf.h
    dir.c
    elf.h
    fcntl.h
    file.c
    file.h
    fs.c
    fs.h
    inode.c
    log.c
    pipe.c
    ramdisk.c
    stat.h
  lib/
    printf.c
    string.c
  linker/
    kernel.ld
  mm/
    kvmem.c
    memlayout.h
    pmem.c
    uvmem.c
  proc/
    cpu.c
    proc.c
    swtch.S
  proc-h/
    cpu.h
    proc.h
  sync/
    sleeplock.c
    sleeplock.h
    spinlock.c
    spinlock.h
  syscall/
    syscall.c
    sysfile.c
    sysfunc.c
  syscall-h/
    sys.h
    syscall_arch.h
    syscall.h
    sysfunc.h
    sysnum.h
  trap/
    kernelvec.S
    scheduler.c
    trampoline.S
    trap_kernel.c
    trap_user.c
user/
  initcode.c
  start.S
  user.ld
```

## 更新说明
- **Lab7:** 新增 `document/lab7.md`，记录本次实验设计与实现要点。
- 新增 `mkfs/`（`mkfs.c`），用于生成 ramdisk 镜像并支持后续磁盘测试。
- 引入 virtio 磁盘支持：`src/devs/virtio_disk.c` 与 `src/devs/virtio.h`，用于模拟/访问块设备。
- 文件系统与块设备相关改动位于 `src/fs/`（包括 `fs.c`、`inode.c`、`log.c` 等）。
- 同步更新了本 `README.md` 的目录结构以反映当前工程文件。
- 如需详细变更与实验步骤，请参阅 `document/lab7.md`。



