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

// 第一个进程
static proc_t proczero;


// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
// 注意：参数 trapframe_pa 应该是 trapframe 的物理地址（PA），
// 调用处需传入 V2P(p->tf)（或你项目中的等价宏）。
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // trampoline 映射必须用物理地址 (trampoline 是 kernel 符号，需 V2P)
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  // trapframe 映射必须用物理地址
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
void proc_make_fisrt()
{
    struct proc *p = &proczero;
    memset(p, 0, sizeof(*p));

    p->pid = allocpid();

    // Allocate a trapframe page. （注意：确认你的 kalloc 接口是 kalloc(1) 还是 kalloc()）
    if((p->tf = (struct trapframe *)kalloc(1)) == 0){
        panic("proc_make_first: kalloc trapframe failed");
        return ;
    }
    // 清零整页（trapframe 占一页）
    memset(p->tf, 0, PGSIZE);

    // prepare for the very first "return" from kernel to user.
    p->tf->epc = 0;      // user program counter

    // pagetable 初始化：传入 trapframe 的物理地址
    p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    if (p->pgtbl == 0) {
        panic("proc_make_first: proc_pgtbl_init failed");
    }

    // ---- 用户栈映射 ----
    uint64 ustack_va = 2 * PGSIZE;          // virtual address of stack page base
    char *ustack_pa = kalloc(1);
    if (ustack_pa == 0) {
        panic("proc_make_first: kalloc ustack failed");
    }
    // zero the newly allocated physical page
    memset(ustack_pa, 0, PGSIZE);

    // 注意：mappages 期望的 pa 是物理地址，因此传 V2P(ustack_pa)
    if (mappages(p->pgtbl, ustack_va, PGSIZE, (uint64)(ustack_pa), PTE_R | PTE_W | PTE_U) < 0) {
        panic("proc_make_first: mappages ustack failed");
    }
    p->ustack_pages = 1;

    // kernel stack
    p->kstack = KSTACK(0);

    // user stack pointer：栈顶在 ustack_va + PGSIZE
    p->tf->sp = ustack_va + PGSIZE; // = 3 * PGSIZE

    // data + code 映射：用 initcode_len 作为长度（比 sizeof(initcode) 更保险）
    uvmfirst(p->pgtbl, initcode, initcode_len);

    if(initcode_len > PGSIZE){
        panic("proc_make_first: initcode too big\n");
    }

    // 设置 heap_top / p->sz，供 sbrk/growproc 使用
    p->heap_top = 2 * PGSIZE;

    // 初始化上下文
    memset(&p->ctx, 0, sizeof(p->ctx));
    printf("[proc_make_first] first process created: pid=%d\n", p->pid);

    // 上下文返回点设置为 trap_user_return
    p->ctx.ra = (uint64)trap_user_return;
    p->ctx.sp = p->kstack + PGSIZE;


    // 把该进程关联到当前 CPU 并切换上下文
    struct cpu* c = mycpu();
    c->proc = p;
    swtch(&c->context, &p->ctx);

    // 当该进程回到内核（exit/yield）时，调度器/其他代码应清理 c->proc
}
