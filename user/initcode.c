#include "../src/syscall-h/sys.h"
#include "types.h"
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

        uint64 block_num_1 = syscall(SYS_alloc_block);
        uint64 block_num_2 = syscall(SYS_alloc_block);
        uint64 block_num_3 = syscall(SYS_alloc_block);


        syscall(SYS_free_block, block_num_2);
        syscall(SYS_free_block, block_num_1);
        syscall(SYS_free_block, block_num_3);
        
        while(1);
        return 0;

}