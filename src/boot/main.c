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
    // // 只有CPU 0(引导处理器)执行系统初始化
    // consoleinit();       // 初始化控制台
    // printfinit();        // 初始化printf功能
    printfinit();
    printf("\n");
    printf("hart %d starting\n", cpuid());
    // kinit();             // 物理页面分配器初始化
    // kvminit();           // 创建内核页表
    // kvminithart();       // 开启分页机制
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
    
    // kvminithart();    // 开启分页机制
    // trapinithart();   // 安装内核陷阱向量
    // plicinithart();   // 向PLIC请求设备中断
  }

  // // 所有CPU都进入调度器，开始调度用户进程
  // scheduler();        
}
