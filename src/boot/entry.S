.section .text
.global _entry
_entry:
    la sp, stack0 + 4096  # 单核直接设置栈

    la a0, bss_top        # bss清零
    la a1, end
bss_loop:
    sw zero, (a0)
    addi a0, a0, 4
    blt a0, a1, bss_loop

    call start            # 跳转到 C 代码
spin:
    j spin