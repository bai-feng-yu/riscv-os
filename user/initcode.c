#include "../src/syscall-h/sys.h"
#include "types.h"
// 与内核保持一致
#define VA_MAX       (1ul << 38)
#define PGSIZE       4096
#define MMAP_END     (VA_MAX - 34 * PGSIZE)
#define MMAP_BEGIN   (MMAP_END - 8096 * PGSIZE) 
#define BSIZE 1024

char *str1, *str2;

void itoa(int x, char *buf) {
    int i = 0, neg = 0;

    if (x < 0) {
        neg = 1;
        x = -x;
    }

    do {
        buf[i++] = '0' + x % 10;
        x /= 10;
    } while (x);

    if (neg)
        buf[i++] = '-';

    buf[i] = 0;

    // reverse
    for (int l = 0, r = i - 1; l < r; l++, r--) {
        char t = buf[l];
        buf[l] = buf[r];
        buf[r] = t;
    }
}

int main()
{
    // fs.img 里默认只包含 user/_test（见 Makefile 的 UPROGS）
    char path[] = "/test";
    char* argv[] = {"test", "hello", "world", 0};

    int pid = syscall(SYS_fork);
    if(pid < 0) { // 失败
        // SYS_write: (fd, userbuf, n)
        syscall(SYS_write, 1, (uint64)"initcode: fork fail\n", 20);
    } else if(pid == 0) { // 子进程
        syscall(SYS_write, 1, (uint64)"\n-----test start-----\n", 22);
        int rc = syscall(SYS_exec, (uint64)path, (uint64)argv);
        // exec 失败则打印并退出子进程
        if(rc < 0)
            syscall(SYS_write, 1, (uint64)"initcode: exec failed\n", 23);
        syscall(SYS_exit, 1);
    } else { // 父进程
        syscall(SYS_wait, 0);
        syscall(SYS_write, 1, (uint64)"\n-----test over-----\n", 21);
        // init 进程不能退出（内核里会 panic("init exiting")），用 sleep 循环避免忙等
        while(1)
            syscall(SYS_sleep, 1000000);
    }
    return 0;
}