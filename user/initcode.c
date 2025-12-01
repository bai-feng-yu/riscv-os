#include "../src/syscall-h/sys.h"

// 与内核保持一致
#define VA_MAX       (1ul << 38)
#define PGSIZE       4096
#define MMAP_END     (VA_MAX - 34 * PGSIZE)
#define MMAP_BEGIN   (MMAP_END - 8096 * PGSIZE) 

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
    syscall(SYS_print, "\nuser begin\n");
    
    // 测试HEAP区域
    long long top = syscall(SYS_brk, 0);
    str2 = (char*)top;
    syscall(SYS_brk, top + PGSIZE);

    str2[0] = 'H';
    str2[1] = 'E';
    str2[2] = 'A';
    str2[3] = 'P';
    str2[4] = '\n';
    str2[5] = '\0';

    int pid = syscall(SYS_fork);

    if(pid == 0) { // 子进程
        for(int i = 0; i < 100000000; i++);
        syscall(SYS_print, "child: hello\n");
        syscall(SYS_print, str2);

        syscall(SYS_kill, syscall(SYS_getpid));
        syscall(SYS_print, "child: never back\n");
    } else {       // 父进程
        int exit_state;        
        syscall(SYS_wait, &exit_state);
        if(exit_state == 1)
            syscall(SYS_print, "parent: hello\n");
        else
            syscall(SYS_print, "parent: error\n");
    }

    while(1);
    return 0;
}