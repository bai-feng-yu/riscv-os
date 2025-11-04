#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "spinlock.h"
#include "proc-h/proc.h"

///
///  内核页表
///
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld中设置该变量为内核代码段的结束地址
extern char trampoline[]; // trampoline.S

// Make a direct-map page table for the kernel.
pagetable_t
kvmmake(void)
{
  pagetable_t kpgtbl;

  kpgtbl = (pagetable_t) kalloc(true);
  memset(kpgtbl, 0, PGSIZE); //关键清零

  // uart寄存器
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio磁盘接口
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // PLIC
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // 映射内核代码段为可执行和只读
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);

  // 映射内核数据段和我们将使用的物理RAM
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);

  // 将trampoline页面映射到trap入口/出口，
  // 位于内核的最高虚拟地址
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // // 为每个进程分配并映射一个内核栈
  // proc_mapstacks(kpgtbl);

  return kpgtbl;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void
kvmmap(pagetable_t kpgtbl, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
  pagetable_t pagetable = (pagetable_t)kalloc(true);
  if(pagetable)
    memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Initialize the kernel_pagetable, shared by all CPUs.
void
kvminit(void)
{
  kernel_pagetable = kvmmake();
}

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));

  // flush stale entries from the TLB.
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc) 
// 虚拟映射查询与建立
// 输入虚拟地址与对应的页表，返回该虚拟地址对应的最低级页表项地址
// alloc为0只查询，为1表示允许在遍历过程中为缺失的中间级页表分配一页。
{
  if(va >= MAXVA)
    panic("walk");
  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    if(*pte & PTE_V) { // PTE有效
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
    } else {  // PTE无效，先判断是否可以写入
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    }
  }
  return &pagetable[PX(0, va)];  
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa.
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    panic("mappages: size not aligned");

  if(size == 0)
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
      return -1;
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

void print_pgtbl(pagetable_t pagetable, int level) {
  //递归打印页表
  for(int i = 0; i < 512; i++) { // 512个页表项
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      for(int j = 0; j < level; j++)
        printf("  ");

      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
        print_pgtbl((pagetable_t)PTE2PA(pte), level + 1);
      }
    }
  }
}

void print_cur_pgtbl(pagetable_t pagetable) {
  //打印当前层页表
  printf("page table %p\n", pagetable);
  for(int i = 0; i < 512; i++) { // 512个页表项
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
      }
    }
  }
}

void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if (sz >= PGSIZE)
    panic("uvmfirst: more than a page");
  mem = kalloc(1);
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
  memmove(mem, src, sz);
}