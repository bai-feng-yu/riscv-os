# Lab5 实验报告

## 实验目标
通过分析与模仿 xv6 的系统调用机制，掌握用户态到内核态的“陷阱—分发—执行—返回”完整流程，并在现有内核中设计一套可扩展、可调试、可强化安全性的系统调用框架，支持基础的进程/文件/内存管理调用与参数检查、错误处理策略。

## 代码仓库

https://github.com/bai-feng-yu/riscv-os/tree/Lab-5

## 实验环境
- 架构：RISC-V 64 (Sv39)
- 工具链：riscv64-unknown-elf-gcc
- 模拟器：qemu-system-riscv64 (virt)
- 参考：xv6-riscv 源码、现代操作系统教材（进程/线程/虚拟内存章节）

## 实验测试与结果

### 任务1：实现系统调用brk
#### 测试代码
```c
int main()
{
      //用于返回调试信息
      char buf[128];

      //测试点1，设置堆顶为4096
      long long heap_top = syscall(SYS_brk, 4096);
      itoa(heap_top, buf);
      syscall(SYS_debug, buf);

      //测试点2，设置堆顶为 4096+4096*10 = 45056
      heap_top = syscall(SYS_brk, heap_top + 4096 * 10);
      itoa(heap_top, buf);
      syscall(SYS_debug, buf);

      //测试点3，设置堆顶为 4096+4096*10-4096*5 = 24576
      heap_top = syscall(SYS_brk, heap_top - 4096 * 5);
      itoa(heap_top, buf);
      syscall(SYS_debug, buf);
      while(1);
      return 0;
}
```
期望返回正确的修改后的堆顶

#### 结果展示
<img src="image.png" style="width:40%; height: auto;" />

可以看到返回的堆顶都符合我们测试代码的预期。



## 任务列表与问题解答

### 任务1：理解系统调用实现原理

#### 完整调用链
用户程序调用 → 用户库/桩代码 (a7=号, a0..=参数) → ecall → 硬件进入 S 模式 → stvec=uservec (trampoline) 保存用户寄存器到 trapframe → 切换页表 → 跳入 usertrap (或 trap_user_handler) → 识别 scause=8 → 调用 syscall 分发 → 内核具体实现函数 → 将返回值写入 trapframe->a0 → 准备返回：设置 sepc/sstatus → userret 恢复用户寄存器 → sret 返回用户态。

#### 各环节作用
- 桩代码：设置系统调用号与参数，统一入口 (减少重复汇编)。
- ecall：触发特权级切换，进入内核安全域。
- trampoline：保存用户上下文、切换到内核页表、建立内核栈、跳入 C 处理函数。
- syscall 分发：根据 a7 查表执行对应实现，负责参数提取与返回值写回。
- userret：恢复寄存器、切换回用户页表、执行 sret。

#### 参数传递与返回
- 用户态到内核：a0..a5（或更多通过栈）、系统调用号 a7。
- 返回值：实现函数返回值写入 trapframe->a0；负值常表示错误（可扩展 errno 语义）。

#### RISC-V ecall 机制要点
- ecall 指令本身不带号，号由 a7 承载。
- scause=8 表示 Environment call from U-mode；sepc 指向 ecall 本身，返回时 sepc+4 跳过该指令。
- sstatus.SPP/SPIE 控制返回特权级与中断使能状态。

#### 特权级切换与上下文保存
- 栈切换：trampoline 根据 trapframe->kernel_sp 换到进程的内核栈。
- trapframe 作用：保存所有需要恢复的用户寄存器 + 返回 PC (epc) + 用户页表地址 (通过 kernel_satp 存储)。
- 页表切换：先 sfence.vma 保证旧页表访问完成，再写 satp 安装内核页表；返回时反向操作。

#### 深入思考回答
1. 为什么需要 trapframe？
   - 需要完整保存用户态寄存器集合，以确保内核可安全嵌套使用寄存器并在返回时精确恢复执行现场。它还携带 kernel 进入路径所需元数据（内核栈、页表、hartid）。相比单纯栈保存更加结构化，可供多处代码共享和调试。 
2. 系统调用与中断的相同与不同？
   - 相同：都通过陷阱向量进入内核；保存上下文；可能切换页表和栈；需要最终恢复用户态。
   - 不同：系统调用是同步、由用户显式触发；中断是异步、由硬件设备或定时器触发；系统调用号在 a7，设备中断号需通过 PLIC 或 scause 解码；错误返回语义不同。 

### 任务2：分析 xv6 分发机制

#### 系统调用号的传递
用户桩在进入内核前将号放入 a7；分发函数读取 `p->trapframe->a7`。简单、直接、无需额外栈空间。

#### 返回值位置
分发后将实现函数返回值写入 `p->trapframe->a0`（用户态恢复时加载到 a0）。

#### 错误处理
若号越界或表项为空：打印错误信息、将 `p->trapframe->a0 = -1`。可扩展：增加统计、审计或安全事件记录。

#### 参数提取函数原理
1. `argint(n, &ip)`: 从 trapframe 保存的用户寄存器或用户栈读取第 n 个整型参数。
2. `argaddr(n, &uptr)`: 读取整型后视为用户地址（指针）。
3. `argstr(n, buf, max)`: 利用地址参数，通过 `copyin` 从用户页表将字符串拷贝进内核缓冲区，检查终止条件与最大长度。

来源：参数最初在用户调用点处位于寄存器或栈；ecall 不改变 a0..a5 内容，trampoline 保存后供分发阶段解析。

#### 不同类型参数与边界检查
- 整型：直接取值；检查数值范围（如 fd >=0 && fd<NOFILE）。
- 指针：必须验证其位于合法用户虚拟地址区间、且页表中映射有效且权限允许（读/写）。
- 字符串：迭代 copyin，遇到 '\0' 或超长则停止；防止越界或未终止字符串造成泄漏。

#### 用户内存访问：copyin/copyout
- 目的：通过页表翻译 + 权限检查安全访问用户空间，避免内核直接解引用用户指针造成：
  - 内核崩溃（访问未映射区域）
  - 安全绕过（伪造指针指向内核地址）
- 防护：逐字节/逐页检查，捕获非法访问返回错误码。

#### 用户恶意指针防范
- 全流程只接受“用户地址”经过 copyin/copyout 进入内核；禁止直接 `*(char*)user_ptr`。
- 加入指针区间验证：0 <= va < MAXVA 且不在内核保留区；利用 `walkaddr` 判断映射有效且具备需要的读/写权限。

### 任务3：设计系统调用框架

#### 设计目标
- 可扩展（新增调用无需修改核心调度逻辑）；
- 可调试（名称、参数个数、统计）；
- 安全（统一入口做指针/权限检测）；
- 支持可变参数与权限检查。

#### 描述符与表
```c
struct syscall_desc {
  int  (*func)(void);   // 实现函数（统一无参，内部用提取器）
  const char *name;     // 名称，用于调试/跟踪
  int  arg_count;       // 参数数量（基本类型）
  // 可扩展：参数类型数组、权限位、审计级别
};

extern struct syscall_desc syscall_table[]; // 以编号索引
```

#### 分发器
```c
void syscall_dispatch(void) {
  struct proc *p = myproc();
  int num = p->tf->a7; // 保存的系统调用号
  if(num > 0 && num < SYSCALL_MAX && syscall_table[num].func) {
    long ret = syscall_table[num].func();
    p->tf->a0 = ret; // 返回值
  } else {
    p->tf->a0 = -1; // 无效调用
    if(debug_syscalls) printf("PID %d invalid syscall %d\n", p->pid, num);
  }
}
```

#### 参数提取接口
```c
int get_syscall_arg(int n, long *val);            // 通用整数/地址载入
int get_user_ptr(int n, uint64 *uaddr);           // 只做基本范围检查
int get_user_string(int n, char *buf, int max);   // copyin + 终止检查
int get_user_buffer(int n, void *buf, int size);  // copyin/copyout 前置
```

#### 核心问题回答
1. 如何验证用户指针？
   - 检查地址范围、页表映射有效、权限位正确（读/写）、访问长度不越界（跨页时逐页核实）。
2. 如何处理失败？
   - 返回统一负值（如 -1 或 -EFAULT），并在分发层记录调试信息；必要时设置进程 killed 防止继续执行危险路径。
3. 可变参数支持？
   - 通过约定：a0 存储参数个数或某些系统调用使用结构体指针；或设计描述符中类型数组驱动提取逻辑；复杂调用使用用户传递的指向数组的指针。
4. 权限检查？
   - 在具体实现函数中：检查当前用户/进程凭据（UID/GID/权限位）与资源控制块上的访问掩码。若未来支持用户态权限，加入凭据结构。

### 任务4：实现基础系统调用（策略与示例）

#### 进程类
```c
int sys_getpid(void) { return myproc()->pid; }
int sys_kill(void) { int pid; if(get_syscall_arg(0,&pid)<0) return -1; return kill(pid); }
```
`fork/exit/wait` 需与进程管理子系统结合：
- `sys_fork`: 调用 `fork()`，错误返回 -1。
- `sys_exit`: 参数为状态码，调用 `exit(code)`，不返回（noreturn）。
- `sys_wait`: 提取指针参数用于写回子状态（安全 copyout）。

#### 文件类（示例：write）
```c
int sys_write(void) {
  int fd, count; char *ubuf;
  if(get_syscall_arg(0,(long*)&fd)<0 || get_user_ptr(1,(uint64*)&ubuf)<0 || get_syscall_arg(2,(long*)&count)<0)
    return -1;
  if(fd<0 || fd>=NOFILE || count<0) return -1;
  return filewrite(myproc()->ofile[fd], ubuf, count);
}
```

#### 内存类
```c
void* sys_sbrk(void){ long inc; if(get_syscall_arg(0,&inc)<0) return (void*)-1; return growproc(inc); }
```

#### 关键实现策略
- 参数提取统一由辅助函数完成，减少重复边界检查代码。
- 返回错误使用负值，后续可与 errno 映射。
- 所有用户缓冲区访问经 copyin/copyout 封装，避免直接解引用。

### 任务5：用户态接口与桩

#### 桩代码格式
```asm
.global write
write:
  li a7, SYS_write
  ecall
  ret
```
批量生成：脚本 (如 xv6 的 usys.pl) 根据 syscall 列表输出对应汇编，减少手写重复。

#### 用户库封装
```c
int write(int fd, const void *buf, int n){ int r; r = __write(fd, buf, n); if(r<0){ /* 可设 errno */ } return r; }
```
错误处理策略：若返回负值，设置全局 `errno` 或直接返回 -1；高级接口可抛出统一错误对象（在类 Unix C 环境通常保留 errno）。

#### 是否需要 errno？
- 可选。简化版本：直接使用 -1；增强版：在内核为不同错误场景分配具体负值（-EFAULT/-EINVAL/-EPERM），用户库映射为标准 errno。

### 任务6：安全性设计

#### 指针验证
```c
int check_user_ptr(uint64 ptr, int size, int write){
  if(ptr >= MAXVA || ptr+size >= MAXVA) return -1;
  // 跨页检查
  for(uint64 a = PGROUNDDOWN(ptr); a < ptr+size; a += PGSIZE){
    uint64 pa = walkaddr(myproc()->pagetable, a);
    if(pa == 0) return -1; // 未映射
    // 可扩展：权限检查，若写则需 PTE_W
  }
  return 0;
}
```

#### 缓冲区与字符串保护
- 长度上限：调用方提供 max，内核强制截断。
- 字符串遍历过程中检测到未终止并且超过 max 则返回错误。
- 多次 copyin 防止单次大请求导致阻塞或过度 CPU 消耗（可分块）。

#### 权限检查
- 文件：校验文件描述符有效并具有所需访问模式。
- 进程操作：仅允许拥有相同会话/父子关系或具备权限位的进程发送信号/kill。
- 资源：对内存申请、文件打开数做配额限制（防止 DoS）。

#### 竞态与 TOCTTOU
- 在使用用户指针多次访问时先 copyin 完整数据到内核缓冲区，再基于副本做检查与操作，避免用户态并发修改导致“检查通过、使用危险”。
- 临界区内使用锁保护共享资源（文件表、进程表）。

### 测试与调试策略

#### 基础功能测试示例（回答：如何验证）
```c
void test_basic_syscalls(void){
  printf("Testing basic system calls...\n");
  int pid = getpid(); printf("PID=%d\n", pid);
  int c = fork();
  if(c==0){ printf("Child PID=%d\n", getpid()); exit(42); }
  else if(c>0){ int status; wait(&status); printf("Child exited status=%d\n", status); }
}
```

#### 参数传递测试
验证边界与错误路径：fd 越界、NULL 指针、负长度；期望全部返回 -1。

#### 安全性测试
- 伪造指针到未映射区域：write(1, (char*)0x10000000, 10) → 返回 -1。
- 读超小缓冲区：read(0, small, 1000) → 应截断或报错。
- 权限：对只读文件调用写、对不可访问进程调用 kill。

#### 性能测试
重复调用轻量系统调用（如 getpid）统计循环次数 / cycle 计数；
优化点：减少分发层多余条件检查、避免频繁 sfence.vma、考虑合并用户/内核页表部分（需谨慎）。

#### 调试与跟踪
在分发处：
```c
if(debug_syscalls){ printf("PID %d: syscall %d (%s)\n", p->pid, num, syscall_table[num].name); }
```
在参数提取失败时：
```c
if(debug_args){ printf("arg %d invalid for syscall %s\n", n, syscall_table[num].name); }
```
可记录频次用于热路径分析。

### 思考题与回答

1. 系统调用数量应如何确定？
   - 根据最小可用集合（进程/文件/内存/时间/信号）逐步扩展；遵循“80% 常用功能 + 扩展保留空间”原则，避免过早引入过细粒度导致维护复杂度上升。 
2. 如何平衡功能与安全？
   - 先实现最小接口并确保指针/权限/边界检查完善，再增量添加复杂功能；禁止未经审计的可变参数或内核指针暴露。 
3. 系统调用的主要开销在哪里？
   - 特权级切换、TLB/流水线扰动、保存/恢复寄存器、页表切换与 copyin/copyout 内存访问。小调用频繁时上下文切换成本占主导。 
4. 如何减少用户态/内核态切换开销？
   - 批处理（readv/writev）、共享页（vdso 用于时间相关调用）、减少不必要的内核页表刷新；合并多个逻辑调用成单次接口。 
5. 如何防止系统调用被滥用？
   - 配额：文件数/内存页/锁数量；速率限制：某些调用（如 fork）单进程速率；审计日志：记录高风险调用。 
6. 如何设计安全的参数传递机制？
   - 强制所有指针经统一验证函数；使用 copyin 到临时缓冲区后处理；引入类型标记与长度；禁止用户传入内核地址范围。 
7. 如何添加新的系统调用并保持向后兼容？
   - 在末尾追加编号，不重用旧号；旧接口不删除而在文档标记 deprecated；用户态通过特性检测或版本号查询决定使用。 
8. 错误处理策略？
   - 内核返回统一负错误码；用户库映射 errno；严重错误（非法指针、破坏性行为）可设置 `killed` 标志令进程尽快退出。 
9. 如何报告详细错误信息？
   - 扩展：增加 `sys_last_error` 查询接口或通过 errno；调试模式下在内核日志打印原因，生产模式仅返回码。 

## 设计与实现总结
本实验分析了 xv6 的系统调用路径，从 ecall 到 trampoline，再到分发与返回过程，明确了寄存器与 trapframe 的角色。基于此给出一个描述符驱动的分发表设计，统一参数提取与验证，强调安全（指针/权限/竞态）与可扩展性（增加描述符字段）。同时回答了安全性、性能与扩展性方面的思考题，提出测试/调试/分析方法，为后续添加更丰富系统调用（如 mmap、信号、管道、线程）奠定基础。

