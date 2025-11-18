#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc-h/proc.h"
#include "defs.h"
#include "proc-h/cpu.h"
//#include "mem/mmap.h"
#include "syscall-h/sysfunc.h"
#include "syscall-h/syscall.h"
#include "syscall-h/sysnum.h"

// 堆伸缩
// uint64 new_heap_top 新的堆顶 (如果是0代表查询, 返回旧的堆顶)
// 成功返回新的堆顶 失败返回-1
uint64 sys_brk()
{
    uint64 new_addr;
    uint64 old_addr = myproc()->sz;  // 保存原始堆顶

    arg_uint64(0, &new_addr);  // 正确读取64位地址
    
    if(new_addr == old_addr) {
        return old_addr;  // 无变化，返回当前堆顶
    }
    
    int diff = (int)(new_addr - old_addr);
    
    // 检查是否溢出
    if((uint64)diff != (new_addr - old_addr)) {
        return -1;  // 差值太大，int无法表示
    }

    if(growproc(diff) < 0) {
        return -1;  // 扩展失败
    }
    
    return new_addr;  // 返回扩展前的地址
}

// copyin 测试 (int 数组)
// uint64 addr
// uint32 len
// 返回 0
uint64 sys_copyin()
{
    proc_t* p = myproc();
    uint64 addr;
    uint32 len;

    arg_uint64(0, &addr);
    arg_uint32(1, &len);

    int tmp;
    for(int i = 0; i < len; i++) {
        uvm_copyin(p->pgtbl, (uint64)&tmp, addr + i * sizeof(int), sizeof(int));
        printf("get a number from user: %d\n", tmp);
    }

    return 0;
}

// copyout 测试 (int 数组)
// uint64 addr
// 返回数组元素数量
uint64 sys_copyout()
{
    int L[5] = {1, 2, 3, 4, 5};
    proc_t* p = myproc();
    uint64 addr;

    arg_uint64(0, &addr);
    uvm_copyout(p->pgtbl, addr, (uint64)L, sizeof(int) * 5);

    return 5;
}

// copyinstr测试
// uint64 addr
// 成功返回0
uint64 sys_copyinstr()
{
    char s[64];

    arg_str(0, s, 64);
    printf("get str from user: %s\n", s);

    return 0;
}

uint64 sys_debug(void)
{
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));

    printf("[debug] %s \n", buf);
    return 0;
}

