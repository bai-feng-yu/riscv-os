OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    /* 程序从地址 0x0 开始 */
    . = 0x0;

    /* 入口代码和 initcode 可以都放在 .text */
    .text : {
        *(.text*)
        *(.rodata*)
    }

    /* 数据段 */
    .data : {
        *(.data*)
    }

    /* BSS 段 */
    .bss : {
        *(.bss*)
        *(COMMON)
    }
}
