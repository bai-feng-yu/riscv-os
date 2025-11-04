#ifndef DEFS_H
#define DEFS_H

struct buf;
struct context;
struct pipe;
struct proc;
struct spinlock;
struct sleeplock;
struct stat;

// console.c
void            consoleinit(void);
void            consoleintr(int);
void            consputc(int);
int             consoleread(int user_dst, uint64 dst, int n);
int             consolewrite(int user_src, uint64 src, int n);

// kalloc.c
void*           kalloc(bool in_kernel);
void            kfree(uint64 page, bool in_kernel);
void            kinit(void);

// timer.c
void   timer_init();       // 时钟初始化
void   timer_create();     // 时钟创建
void   timer_update();     // 时钟更新(ticks++)
uint64 timer_get_ticks();  // 获取时钟的tick

// trap.c
void            trapinit(void);
void            trapinithart(void);
void            usertrapret(void);
void            trap_user_handler();
void            trap_user_return();
int             devintr();

// uart.c
void            uartinit(void);
void            uartintr(void);
void            uartputc(int);
void            uartputc_sync(int);
int             uartgetc(void);
void            uart_putc(char );
void            uart_puts(char *);

// vm.c
void            kvminit(void);
void            kvminithart(void);
void            kvmmap(pagetable_t, uint64, uint64, uint64, int);
int             mappages(pagetable_t, uint64, uint64, uint64, int);
void            uvmfirst(pagetable_t, uchar *src, uint sz);
pagetable_t     uvmcreate(void);
uint64          uvmalloc(pagetable_t, uint64, uint64, int);
uint64          uvmdealloc(pagetable_t, uint64, uint64);
int             uvmcopy(pagetable_t, pagetable_t, uint64);
void            uvmfree(pagetable_t, uint64);
void            uvmunmap(pagetable_t, uint64, uint64, int);
void            uvmclear(pagetable_t, uint64);
pte_t *         walk(pagetable_t, uint64, int);
uint64          walkaddr(pagetable_t, uint64);
int             copyout(pagetable_t, uint64, char *, uint64);
int             copyin(pagetable_t, char *, uint64, uint64);
int             copyinstr(pagetable_t, char *, uint64, uint64);
int             ismapped(pagetable_t, uint64);
uint64          vmfault(pagetable_t, uint64, int);
void            print_pgtbl(pagetable_t pagetable, int level) ;
void            print_cur_pgtbl(pagetable_t pagetable);


// plic.c
void            plicinit(void);
void            plicinithart(void);
int             plic_claim(void);
void            plic_complete(int);

// printf.c
void            printf(char*, ...);
void            panic(char*) __attribute__((noreturn));
void            printfinit(void);

// proc.c
int             cpuid(void);
void            exit(int);
int             fork(void);
int             growproc(int);
void            proc_mapstacks(pagetable_t);
pagetable_t     proc_pagetable(struct proc *);
void            proc_freepagetable(pagetable_t, uint64);
int             kill(int);
int             killed(struct proc*);
void            setkilled(struct proc*);
struct cpu*     mycpu(void);
struct cpu*     getmycpu(void);
struct proc*    myproc();
void            procinit(void);
void            sleep(void*, struct spinlock*);
void            userinit(void);
int             wait(uint64);
void            wakeup(void*);
int             either_copyout(int user_dst, uint64 dst, void *src, uint64 len);
int             either_copyin(void *dst, int user_src, uint64 src, uint64 len);
void            procdump(void);

// swtch.S
void            swtch(struct context*, struct context*);

// scheduler.c
void            scheduler(void) __attribute__((noreturn));
void            sched(void);
void            yield(void);

// spinlock.c
void            acquire(struct spinlock*);
int             holding(struct spinlock*);
void            initlock(struct spinlock*, char*);
void            release(struct spinlock*);
void            push_off(void);
void            pop_off(void);

// string.c
int             memcmp(const void*, const void*, uint);
void*           memmove(void*, const void*, uint);
void*           memset(void*, int, uint);
char*           safestrcpy(char*, const char*, int);
int             strlen(const char*);
int             strncmp(const char*, const char*, uint);
char*           strncpy(char*, const char*, int);

// number of elements in fixed-size array
#define NELEM(x) (sizeof(x)/sizeof((x)[0]))

#endif