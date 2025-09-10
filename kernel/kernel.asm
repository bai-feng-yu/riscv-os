
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.section .text
.global _entry
_entry:
    la sp, stack0 + 4096  # 单核直接设置栈
    80000000:	00002117          	auipc	sp,0x2
    80000004:	01010113          	add	sp,sp,16 # 80002010 <end>

    la a0, bss_top        # bss清零
    80000008:	00001517          	auipc	a0,0x1
    8000000c:	00850513          	add	a0,a0,8 # 80001010 <stack0>
    la a1, end
    80000010:	00002597          	auipc	a1,0x2
    80000014:	00058593          	mv	a1,a1

0000000080000018 <bss_loop>:
bss_loop:
    sw zero, (a0)
    80000018:	00052023          	sw	zero,0(a0)
    addi a0, a0, 4
    8000001c:	0511                	add	a0,a0,4
    blt a0, a1, bss_loop
    8000001e:	feb54de3          	blt	a0,a1,80000018 <bss_loop>

    jal start            # 跳转到 C 代码
    80000022:	006000ef          	jal	80000028 <start>

0000000080000026 <spin>:
spin:
    80000026:	a001                	j	80000026 <spin>

0000000080000028 <start>:
#include "defs.h"

__attribute__ ((aligned (16))) char stack0[4096 * 1];

void start() {
    80000028:	1141                	add	sp,sp,-16
    8000002a:	e406                	sd	ra,8(sp)
    8000002c:	e022                	sd	s0,0(sp)
    8000002e:	0800                	add	s0,sp,16
    uart_puts("hello 05\n");  // 输出 'hello 05' 表示进入 C 代码
    80000030:	00001517          	auipc	a0,0x1
    80000034:	fd050513          	add	a0,a0,-48 # 80001000 <_trampoline>
    80000038:	00000097          	auipc	ra,0x0
    8000003c:	02c080e7          	jalr	44(ra) # 80000064 <uart_puts>

    while (1);       // 死循环
    80000040:	a001                	j	80000040 <start+0x18>

0000000080000042 <uart_putc>:
#include "defs.h"

void uart_putc(char c) {
    80000042:	1141                	add	sp,sp,-16
    80000044:	e422                	sd	s0,8(sp)
    80000046:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    80000048:	10000737          	lui	a4,0x10000
    8000004c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000050:	0207f793          	and	a5,a5,32
    80000054:	dfe5                	beqz	a5,8000004c <uart_putc+0xa>
    uart[0] = c;
    80000056:	100007b7          	lui	a5,0x10000
    8000005a:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    8000005e:	6422                	ld	s0,8(sp)
    80000060:	0141                	add	sp,sp,16
    80000062:	8082                	ret

0000000080000064 <uart_puts>:

void uart_puts(char *s) {
    80000064:	1101                	add	sp,sp,-32
    80000066:	ec06                	sd	ra,24(sp)
    80000068:	e822                	sd	s0,16(sp)
    8000006a:	e426                	sd	s1,8(sp)
    8000006c:	1000                	add	s0,sp,32
    8000006e:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000070:	00054503          	lbu	a0,0(a0)
    80000074:	c909                	beqz	a0,80000086 <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    80000076:	00000097          	auipc	ra,0x0
    8000007a:	fcc080e7          	jalr	-52(ra) # 80000042 <uart_putc>
        s++;              // 移动到下一个字符
    8000007e:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000080:	0004c503          	lbu	a0,0(s1)
    80000084:	f96d                	bnez	a0,80000076 <uart_puts+0x12>
    }
}
    80000086:	60e2                	ld	ra,24(sp)
    80000088:	6442                	ld	s0,16(sp)
    8000008a:	64a2                	ld	s1,8(sp)
    8000008c:	6105                	add	sp,sp,32
    8000008e:	8082                	ret
	...
