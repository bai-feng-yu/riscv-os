<!-- 实验报告头部（与 Lab1 保持一致的结构） -->
# Lab2 实验报告

## 实验目标
围绕 RISC-V Sv39 虚拟内存与内核内存管理：
- 深入理解 Sv39 虚拟地址分解与 PTE 格式，掌握多级页表的工作机理。
- 读懂并分析 xv6 的物理内存分配器与页表管理接口。
- 设计并给出你自己的物理内存管理器与页表管理系统的接口与实现思路。
- 在内核中启用虚拟内存（内核态）并完成分层测试与调试要点梳理。

## 代码仓库

https://github.com/bai-feng-yu/riscv-os/tree/Lab-2

## 实验环境
- RISC-V: Sv39 模式（64 位）
- 交叉工具链: riscv64-unknown-elf-gcc
- 模拟器: qemu-system-riscv64（virt 机器）

## 实验原理概述
- Sv39 将虚拟地址分为 3 级索引（每级 9 位）与 4KB 页内偏移（12 位），硬件按级读取 PTE 完成地址变换。
- PTE 低位标志位控制有效性与权限，高位 PPN 指向物理页框。
- 多级页表在内存中以 4KB 为单位存放，每个页表页可容纳 512 个 PTE（8 字节），由 satp 提供根页表 PPN。

## 实验概述

- 本实验围绕 RISC-V Sv39 分页与页表，在理解硬件规范的基础上，阅读 xv6 相关实现并设计自己的 PMM/PT 框架。
- 通过逐步回答任务清单中的问题，完成从物理分配器到页表映射再到启用内核虚拟内存的闭环，并给出调试与测试策略。

## 实验概述与问题回答

### 任务1：深入理解 Sv39 页表机制

#### 1) 39 位虚拟地址的分解（VPN/offset）
- 结构：VA[38:30] = VPN[2]，VA[29:21] = VPN[1]，VA[20:12] = VPN[0]，VA[11:0] = offset（页内偏移）。
- 每个 VPN 段的作用：
  - VPN[2]/VPN[1]/VPN[0] 分别作为第 3/2/1 级页表的索引（自根开始逐级索引）。
  - 通过逐级查找，最终在叶子 PTE 获得物理页号（PPN）与权限，组合 offset 得到物理地址。
- 为什么每级是 9 位：
  - 4KB 页大小 → 每个页表页大小 4KB，PTE 为 8B → 每页 4096/8 = 512 项；log2(512)=9 位索引。
  - 三个 9 位索引 + 12 位偏移 → 9×3+12 = 39 位虚拟地址覆盖范围。

#### 2) 页表项（PTE）格式与字段
- 布局（Sv39 常见定义）：
  - [63:54] 保留/实现相关， [53:28] PPN[2]（26 位），[27:19] PPN[1]（9 位），[18:10] PPN[0]（9 位），
  - [9:8] RSW（软件保留），[7] D（已写），[6] A（已访），[5] G（全局），[4] U（用户），[3] X（执行），[2] W（写），[1] R（读），[0] V（有效）。
- V 位：PTE 是否有效；无效则该项不能用于翻译。
- R/W/X 位：读/写/执行权限；叶子 PTE 至少应有一位为 1 才算映射。
- U 位：是否允许 U 态访问；0 仅 S/M 态可用（结合 SUM 等状态位）。
- PPN 的提取：`PTE_PA(pte) = ((pte >> 10) << 12)`，等价于取 PPN 字段再左移 12 位组成物理页基址。

#### 深入思考
- 为什么选择三级页表而不是二级或四级？
  - 2 级：地址位宽仅 9×2+12 = 30 位，覆盖范围不足；
  - 3 级：恰好覆盖 39 位 VA，页表开销与步数适中；
  - 4 级：可达 48 位，但多一层带来访存与内存开销，超出本实验需求。
- 中间级页表项的 R/W/X 应如何设置？
  - 中间级（非叶子）必须 V=1 且 R=W=X=0，用于指向下一级页表；
  - 叶子项才设置权限位（R/W/X 至少一位为 1）。
- 如何理解“页表也存储在物理内存中”？
  - 页表本身就是一页页的物理内存（4KB），硬件以 satp 的根 PPN 开始，按物理地址读取各级 PTE；
  - OS 若要操作页表，需要保证这些页表页对内核可达（恒等映射或相应内核映射）。

---

### 任务2：分析 xv6 的物理内存分配器

#### 1) kalloc.c 核心数据结构
```c
struct run {
  struct run *next;
};
```
- 设计巧妙之处：
  - 复用空闲页自身作为链表节点存放 `next` 指针，无需额外元数据页；
  - O(1) 头插/头取，简单高效，缓存局部性好。
- 为什么不需要额外元数据存储？
  - 空闲页内容无效，直接占用其开头若干字节存 `next` 即可；被分配后，该页由上层使用覆盖。

#### 2) kinit() 初始化过程
- 如何确定可分配内存范围？
  - 由链接脚本符号（如 `end`）至 `PHYSTOP`（或平台上限）之间的物理内存；
  - 按页对齐，从 `PGROUNDUP(end)` 开始。
- 空闲页链表如何构建？
  - 逐页遍历，将每个 4KB 页用 `struct run` 头插到 `freelist`。
- 为什么要按页对齐？
  - 确保每个块恰是页框，避免跨页覆盖；硬件/页表均以页为基本单位。

#### 3) kalloc()/kfree() 的实现
- 分配算法时间复杂度：
  - 取头结点 O(1)；释放头插 O(1)。
- 如何防止 double-free？
  - xv6 简洁实现主要依赖不变量与调试：对地址范围/页对齐做断言并在 kfree() 里填充模式（如 1 字节）便于调试；
  - 更严格可选：维护已分配集合/引用计数或加“在空闲链中重复检测”（代价更高）。
- 这种设计的优缺点：
  - 优点：实现简单、常数开销小、速度快；
  - 缺点：仅支持页粒度，无法避免外部碎片；不支持不同尺寸、统计/泄漏检测弱。

#### 设计思考（扩展）
- 内存统计如何扩展？
  - 维护 `free_pages`、`total_pages` 计数；kalloc/kfree 时自增自减；可暴露 `/proc` 风格接口或调试打印。
- 如何检测内存泄漏？
  - 维护分配账本（如哈希表）记录分配回溯或序号；关机/阶段性检查未归还项；
  - 编译期宏切换以减少发布版开销。
- 更高效的分配算法：
  - 伙伴系统（buddy）用于页级分配，支持连续多页且合并/拆分高效；
  - slab/obj cache 支持对象级（小块）分配，减少内部碎片与构造/析构成本。

---

### 任务3：设计你的物理内存管理器

#### 设计要求与接口（建议）
```c
// 必选接口
void   pmm_init(void);
void*  alloc_page(void);
void   free_page(void* page);
// 可选：连续分配
void*  alloc_pages(int n);
```
- 1) 如何确定可用内存范围？
  - 读取设备树/引导信息或固定平台常量（如从 `end` 到 `PHYSTOP`）；
  - 统一向上页对齐作为起始；过滤设备/保留区间。
- 2) 如何处理内存碎片？
  - 初版：页粒度 free-list 足够；
  - 进阶：采用伙伴系统合并相邻空闲块，`alloc_pages(n)` 支持连续页需求；
  - 长期：小对象用 slab，降低内部碎片。
- 3) 是否支持不同大小的分配？
  - 视需求启用 slab 或 kmalloc/kfree 风格接口，在页级 PMM 之上叠加。

#### 实现策略（建议）
- 步骤 1：实现最简单的单链表（与 xv6 类似），完成 pmm_init/kalloc/kfree；
- 步骤 2：添加错误检查（越界/未对齐/double-free 粗检——比如在空闲页写入魔数并在释放时校验）；
- 步骤 3：若需性能与功能，切换/叠加伙伴系统与 slab。

---

### 任务4：理解 xv6 的页表管理

#### 1) walk() 的逐级遍历
- 如何从虚拟地址提取各级索引？
  - 使用宏：`PX(level, va) = (va >> (12 + 9*level)) & 0x1FF`；level=2/1/0。
- 遇到无效页表项如何处理？
  - 若 `alloc==0` 则返回空指针；若 `alloc==1` 则分配新的页表页、清零并写入中间 PTE（V=1, R/W/X=0）。
- 为什么需要 alloc 参数？
  - 为了在建立映射时可按需创建中间级页表；查询时则不必分配。

#### 2) mappages() 的映射建立
- 如何处理地址对齐？
  - VA 与 PA 均以页为对齐单位：`PGROUNDDOWN` 与 `PGROUNDUP` 处理区间端点；
  - 对区间内的每一页调用 walk(alloc=1) 获取叶子项。
- 权限位如何设置？
  - 在叶子 PTE 设置 R/W/X/U/V，其中 U 依据是否用户可达；
  - 遵循“不可同时 W=1 且 X=1”的 W^X 政策（如需）。
- 映射失败时如何清理？
  - 回滚：对已建立的条目逐页清除并释放中间页表（必要时）。

#### 3) 地址转换定义
```c
#define PGROUNDUP(sz)  (((sz)+PGSIZE-1) & ~(PGSIZE-1))
#define PGROUNDDOWN(a) ((a) & ~(PGSIZE-1))
#define PTE_PA(pte)    (((pte) >> 10) << 12)
```
- 作用：页对齐/还原物理地址，确保页表步进与权限判断正确。

#### 实现挑战与对策
- 如何避免页表遍历中的无限递归？
  - walk 使用迭代或有限层递归（最多 3 层）；严格在 level∈{2,1,0} 内循环；
  - 对非法/保留 VA 直接返回错误。
- 映射过程中的分配失败如何恢复？
  - 统一的错误路径：回滚已创建项并释放中间页表页；保证函数以“要么全成，要么全不成”结束。
- 如何确保页表一致性？
  - 修改页表后执行 `sfence.vma`（或针对 VA 的局部刷新）；
  - 多核场景下在恰当位置加锁或停核，避免并发修改导致的可见性问题。

---

### 任务5：实现你的页表管理系统（接口与步骤）

#### 核心类型与接口（建议）
```c
// 页表类型定义
typedef uint64* pagetable_t;

// 基本操作接口
pagetable_t create_pagetable(void);
int         map_page(pagetable_t pt, uint64 va, uint64 pa, int perm);
void        destroy_pagetable(pagetable_t pt);

// 辅助函数（内部使用）
pte_t*      walk_create(pagetable_t pt, uint64 va);
pte_t*      walk_lookup(pagetable_t pt, uint64 va);
```

#### 实现步骤
1) 地址解析实现
```c
// 从虚拟地址提取各级索引
#define VPN_SHIFT(level) (12 + 9 * (level))
#define VPN_MASK(va, level) (((va) >> VPN_SHIFT(level)) & 0x1FF)
```
2) 页表遍历实现
- 从根页表开始逐级查找（level=2→1→0）；
- 每级检查 PTE.V；无效且需要时分配中间级页表；
- 返回叶子级 PTE 指针。

3) 映射建立实现
- 确保 VA/PA 对齐；
- 正确设置权限位（R/W/X/U/V）；
- 处理映射冲突（已映射则返回错误或按策略更新）。

#### 调试检查点
```c
// 实现页表打印功能用于调试
void dump_pagetable(pagetable_t pt, int level) {
    // 递归打印页表内容
    // 显示虚拟地址到物理地址的映射关系
    // 标明权限位设置
}
```

TODO: 页表打印输出示例截图

---

### 任务6：启用虚拟内存（内核态）

#### 参考 xv6 的初始化路径
- kvminit() 创建并填充内核页表：
  - 映射内核代码段（R+X）、数据段（R+W）、设备内存（UART 等，R+W）。
  - 采用恒等映射（VA=PA）便于早期调试与设备访问。
- kvminithart() 激活页表：
  - satp = MODE(Sv39, 8) | 根页表 PPN；
  - 执行 `sfence.vma` 刷新 TLB；
  - 注意在切换前栈/代码/设备必须可达。

#### 代码骨架（示例）
```c
void kvminit(void) {
    // 1. 创建内核页表
    kernel_pagetable = create_pagetable();

    // 2. 映射内核代码段（R+X 权限）
    map_region(kernel_pagetable, KERNBASE, KERNBASE,
               (uint64)etext - KERNBASE, PTE_R | PTE_X);

    // 3. 映射内核数据段（R+W 权限）
    map_region(kernel_pagetable, (uint64)etext, (uint64)etext,
               PHYSTOP - (uint64)etext, PTE_R | PTE_W);

    // 4. 映射设备（UART 等）
    map_region(kernel_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
}

void kvminithart(void) {
    // 激活内核页表
    w_satp(MAKE_SATP(kernel_pagetable));
    sfence_vma();
}
```

#### 关键技术细节
- SATP 格式：`MODE[63:60] | ASID[59:44] | PPN[43:0]`，其中 MODE=8 表示 Sv39；
- `sfence.vma` 刷新 TLB，保证新映射生效；
- 多核时每个 hart 都需加载 satp 并 sfence。

TODO: 启用前后串口输出/访存验证截图

---

## 测试与调试策略（分层）

### 1) 物理内存分配器测试
```c
void test_physical_memory(void) {
    void *page1 = alloc_page();
    void *page2 = alloc_page();
    assert(page1 != page2);
    assert(((uint64)page1 & 0xFFF) == 0); // 页对齐

    *(int*)page1 = 0x12345678;
    assert(*(int*)page1 == 0x12345678);

    free_page(page1);
    void *page3 = alloc_page();
    free_page(page2);
    free_page(page3);
}
```

### 2) 页表功能测试
```c
void test_pagetable(void) {
    pagetable_t pt = create_pagetable();

    uint64 va = 0x10000000;
    uint64 pa = (uint64)alloc_page();
    assert(map_page(pt, va, pa, PTE_R | PTE_W) == 0);

    pte_t *pte = walk_lookup(pt, va);
    assert(pte != 0 && (*pte & PTE_V));
    assert(PTE_PA(*pte) == pa);

    assert(*pte & PTE_R);
    assert(*pte & PTE_W);
    assert(!(*pte & PTE_X));
}
```

### 3) 虚拟内存激活测试
```c
void test_virtual_memory(void) {
    printf("Before enabling paging...\n");
    kvminit();
    kvminithart();
    printf("After enabling paging...\n");
    // 测试代码/数据/设备访问
}
```

### 常见问题诊断
- 启用分页后系统崩溃：
  - 检查代码段/数据段/栈是否映射；设备地址是否映射；
  - 在启用前后打印关键地址映射状态。
- 页表映射失败：
  - 检查 VA/PA 对齐；中间页表是否分配成功；权限位冲突或重复映射。
- 地址转换错误：
  - 核对 VPN 提取算法与 PTE 格式；确认物理地址计算是否正确。

### GDB 调试技巧（示例）
```bash
# 查看页表内容（根据调试环境替换命令）
(gdb) x/64gx $satp_register_content
# 查看特定虚拟地址映射（qemu monitor）
(gdb) monitor info mem
# 跟踪页表遍历
(gdb) b walk_create
(gdb) watch $a0
```

### 性能优化考虑
- 内存分配：批量分配、伙伴系统、slab、小缓存池；
- 页表：TLB 友好布局、大页映射（2MB/1GB）、延迟映射按需创建。

---

## 思考题（回答）
1) 设计对比：你的物理分配器与 xv6 有何不同？为何选择？
- 回答：在页级沿用 free-list 简洁模型，若需连续页则引入伙伴系统；权衡了实现复杂度与性能/碎片之间的关系。

2) 内存安全：如何防止分配器被恶意利用？页表权限的安全考虑？
- 回答：对输入严格校验（对齐/范围），调试版启用账本与 canary；页表遵循最小权限原则，内核区分 RX 与 RW，禁止 W^X 冲突，用户映射严格 U 位与边界检查。

3) 性能分析：瓶颈与优化？
- 回答：热点在分配/释放与页表 miss；采用伙伴系统减少外部碎片与遍历，使用大页降低 TLB miss，按需/批量分配减少开销。

4) 扩展性：支持用户进程需要什么修改？共享/写时复制如何做？
- 回答：为每进程创建独立页表，提供 `copyin/copyout` 与 `uvmcopy`；共享用同一 PPN 并增引用计数，写时复制在缺页时分配新页并更新 PTE。

5) 错误恢复：页表创建失败如何清理？如何检测/处理内存泄漏？
- 回答：映射失败统一回滚并释放中间页表；泄漏通过分配账本与关机自检，或在调试期对未释放项报警。

---

## 实验小结
本实验从 Sv39 机制出发，系统回答了多级页表与 PTE 的关键问题；结合 xv6 的 kalloc 与 walk/mappages 等接口，给出了可落地的 PMM/PT 设计与实现策略；最后通过 satp/sfence.vma 启用内核页表，并提供了分层测试与调试路径，为后续用户态与进程地址空间打下基础。
