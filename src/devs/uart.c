#include "defs.h"

void uart_putc(char c) {
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    uart[0] = c;
}

void uart_puts(char *s) {
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
        uart_putc(*s);    // 输出当前字符
        s++;              // 移动到下一个字符
    }
}
