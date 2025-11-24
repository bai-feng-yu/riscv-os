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
      //用于返回调试信息
      char buf[128];

      //测试点1，查询当前堆顶
      long long heap_top = syscall(SYS_brk, 0);
      itoa(heap_top, buf);
      syscall(SYS_debug, buf);

      //测试点2，设置堆顶为 4096+4096*10 = 45056
      heap_top = syscall(SYS_brk, heap_top + 4096 * 10);
      itoa(heap_top, buf);
      syscall(SYS_debug, buf);

      //测试点3，设置堆顶为 4096+4096*10-4096*5 = 24576
      heap_top = syscall(SYS_brk, heap_top - 4096 * 5);
      itoa(heap_top, buf);
      syscall(SYS_debug, buf);
      while(1);
      return 0;

}