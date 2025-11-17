#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "memlayout.h"
#include "proc-h/proc.h"
#include "proc-h/cpu.h"
#include "proc-h/initcode.h"

// in trampoline.S
extern char trampoline[];

// in swtch.S
extern void swtch(context_t* old, context_t* new);

// in trap_user.c
extern void trap_user_return();

extern struct proc proc[NPROC];

// 第一个进程
static struct proc* proczero;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc(1);
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

void procinit(void)
{
    struct proc *p;

    initlock(&pid_lock, "nextpid");

    for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    }
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    // fsinit(ROOTDEV); //初始化文件系统
  }

  trap_user_return();
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    freeproc(p);
    printf("allocproc: kalloc trapframe failed\n");
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
  if(p->pgtbl == 0){ 
    freeproc(p);
    printf("allocproc: proc_pgtbl_init failed\n");
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->ctx, 0, sizeof(p->ctx));
  p->ctx.ra = (uint64)forkret;
  p->ctx.sp = p->kstack+PGSIZE;

  return p;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  // uvmunmap(pagetable, TRAMPOLINE, 1, 0); //TODO
  // uvmunmap(pagetable, TRAPFRAME, 1, 0);
  // uvmfree(pagetable, sz);
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
void freeproc(struct proc *p)
{
  if(p->tf)
    kfree((uint64)p->tf,1);
  p->tf = 0;
  if(p->pgtbl)
    proc_freepagetable(p->pgtbl, p->sz);
  if(p->kstack)
    kfree((uint64)p->kstack,1); 
  p->kstack = 0;
  p->sz = 0;
  p->pgtbl = 0;
  p->pid = 0;
  p->state = UNUSED;
}

// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              trapframe_pa, PTE_R | PTE_W) < 0){
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}

/*
    第一个用户态进程的创建
    它的代码和数据位于 initcode.h 的 initcode 数组

    用户地址空间布局（你的注释）：
    page 0: unmapped (lowest)
    page 1: code+data (initcode)
    page 2: ustack
    ... heap between code+data and ustack (heap_top = 2*PGSIZE)
    TRAPFRAME / TRAMPOLINE 映射在高地址 (TRAPFRAME/TRAMPOLINE 常量)
*/

//__attribute__ ((aligned (16))) char proc0stack[8192];

// Set up first user process.
void
userinit(void)
{
  struct proc *p;

  p = allocproc();
  proczero = p;
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pgtbl, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->tf->epc = 0;      // user program counter
  p->tf->sp = PGSIZE;  // user stack pointer

  // safestrcpy(p->name, "initcode", sizeof(p->name));
  //p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// void proc_make_fisrt()
// {
  
//     struct proc *p = &proczero;
//     memset(p, 0, sizeof(*p));

//     p->pid = allocpid();

//     // Allocate a trapframe page. （注意：确认你的 kalloc 接口是 kalloc(1) 还是 kalloc()）
//     if((p->tf = (struct trapframe *)kalloc(1)) == 0){
//         panic("proc_make_first: kalloc trapframe failed");
//         return ;
//     }
//     // 清零整页（trapframe 占一页）
//     memset(p->tf, 0, PGSIZE);

//     // prepare for the very first "return" from kernel to user.
//     p->tf->epc = 0;      // user program counter

//     // pagetable 初始化：传入 trapframe 的物理地址
//     p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
//     if (p->pgtbl == 0) {
//         panic("proc_make_first: proc_pgtbl_init failed");
//     }

//     // ---- 用户栈映射 ----
//     uint64 ustack_va = 2 * PGSIZE;          // virtual address of stack page base
//     char *ustack_pa = kalloc(1);
//     if (ustack_pa == 0) {
//         panic("proc_make_first: kalloc ustack failed");
//     }
//     // zero the newly allocated physical page
//     memset(ustack_pa, 0, PGSIZE);

//     // 注意：mappages 期望的 pa 是物理地址，因此传 V2P(ustack_pa)
//     if (mappages(p->pgtbl, ustack_va, PGSIZE, (uint64)(ustack_pa), PTE_R | PTE_W | PTE_U) < 0) {
//         panic("proc_make_first: mappages ustack failed");
//     }
//     p->ustack_pages = 1;

//     // kernel stack
//     // 暂时只有一个进程，分配固定大小的进程栈
//     // p->kstack = (uint64)proc0stack;
//     p->kstack =ustack_va + PGSIZE;
//     // user stack pointer：栈顶在 ustack_va + PGSIZE
//     p->tf->sp = ustack_va + PGSIZE; // = 3 * PGSIZE

//     // data + code 映射：用 initcode_len 作为长度（比 sizeof(initcode) 更保险）
//     uvmfirst(p->pgtbl, initcode, initcode_len);

//     if(initcode_len > PGSIZE){
//         panic("proc_make_first: initcode too big\n");
//     }

//     // 设置 heap_top / p->sz，供 sbrk/growproc 使用
//     p->heap_top = 2 * PGSIZE;

//     // 初始化上下文
//     memset(&p->ctx, 0, sizeof(p->ctx));
    
    

//     // 上下文返回点设置为 trap_user_return
//     p->ctx.ra = (uint64)trap_user_return;
//     p->ctx.sp = p->kstack +2*PGSIZE; // 内核栈顶

//     // 把该进程关联到当前 CPU 并切换上下文
//     struct cpu* c = mycpu();
//     c->proc = p;

//     printf("[proc_make_first] first process created: pid=%d\n", p->pid);

//     swtch(&c->context, &p->ctx);
    

//     // 当该进程回到内核（exit/yield）时，调度器/其他代码应清理 c->proc
// }
