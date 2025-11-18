#include "../src/syscall-h/sys.h"

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
    char buf[128];
    long long heap_top = syscall(SYS_brk, 4096);
    itoa(heap_top, buf);
    syscall(SYS_debug, buf);
    heap_top = syscall(SYS_brk, heap_top + 4096 * 10);
    itoa(heap_top, buf);
    syscall(SYS_debug, buf);
    heap_top = syscall(SYS_brk, heap_top - 4096 * 5);
    itoa(heap_top, buf);
    syscall(SYS_debug, buf);
    while(1);
    return 0;
}