#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "spinlock.h"

volatile static int started = 0;
struct spinlock start_lock;

// start()函数在管理者模式下跳转到此处，所有CPU都会执行
void
main()
{
  if(cpuid() == 0){
    initlock(&start_lock,"start_lock");
    // 只有CPU 0(引导处理器)执行系统初始化
    consoleinit();       // 初始化控制台
    printfinit();        // 初始化printf功能
    printfinit();
    printf("\n");
    printf("hart %d starting\n", cpuid());
    kinit();             // 物理页面分配器初始化
    // kvminit();           // 创建内核页表
    // vminithart();       // 开启分页机制

    pagetable_t test_pgtbl = (pagetable_t)kalloc(true);
      memset(test_pgtbl, 0, PGSIZE);
      if(test_pgtbl == 0){
        printf("test_pgtbl alloc failed\n");
        panic("no mem");
      }

      void *pages[5];
      for(int i = 0; i < 5; i++){
        pages[i] = kalloc(true); // 分配并清零测试物理页
        if(pages[i] == 0){
          printf("page[%d] alloc failed\n", i);
          panic("no mem");
        }
      }

      // 重要：mappages 的第二、第三、第四参数依次是 (va, size, pa)
      // 必须保证 size 为页对齐，这里全部使用 PGSIZE
      mappages(test_pgtbl, 0, PGSIZE, (uint64)pages[0], PTE_R | PTE_W);
      if(mappages(test_pgtbl, 10*PGSIZE, PGSIZE, (uint64)pages[1], PTE_R) != 0)
        printf("map va=10*PGSIZE failed\n");
      kvmmap(test_pgtbl, 512*PGSIZE, (uint64)pages[2], PGSIZE, PTE_R | PTE_X);
      if(mappages(test_pgtbl, 512ULL*512*PGSIZE, PGSIZE, (uint64)pages[3], PTE_R | PTE_W) != 0)
        printf("map va=512^2*PGSIZE failed\n");
      if(mappages(test_pgtbl, MAXVA - PGSIZE, PGSIZE, (uint64)pages[4], PTE_R | PTE_W) != 0)
        printf("map va=MAXVA-PGSIZE failed\n");

      printf("test_pgtbl：\n");
      print_pgtbl(test_pgtbl, 0);
      // ============ 自定义页表测试结束 ============

    // procinit();          // 进程表初始化
    // trapinit();          // 陷阱向量初始化
    // trapinithart();      // 安装内核陷阱向量
    // plicinit();          // 设置中断控制器
    // plicinithart();      // 向PLIC请求设备中断
    // userinit();          // 创建第一个用户进程
    __sync_synchronize();
    started = 1;         // 标记系统启动完成
  } else {
    // 其他CPU等待CPU 0完成初始化
    while(started == 0)
      ;
    
    __sync_synchronize();
    printf("hart %d starting\n", cpuid());
    kvminithart();       // 开启分页机制
    // trapinithart();   // 安装内核陷阱向量
    // plicinithart();   // 向PLIC请求设备中断
  }
  while(1);
  // // 所有CPU都进入调度器，开始调度用户进程
  // scheduler();        
}
