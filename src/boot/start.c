#include "defs.h"

__attribute__ ((aligned (16))) char stack0[4096 * 1];

void start() {
    uart_puts("hello 05\n");  // 输出 'hello 05' 表示进入 C 代码

    while (1);       // 死循环
}
