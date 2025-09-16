.section .text
.global _entry
_entry:
    # 为C语言代码设置栈空间
    # stack0声明在start.c中，每个CPU分配4096字节的栈空间
    # 计算公式: sp = stack0基地址 + (硬件线程ID * 4096)
    la sp, stack0        # 加载stack0的基地址到栈指针sp
    li a0, 1024*4        # 加载4096(每个CPU的栈大小)到a0
    csrr a1, mhartid     # 读取当前硬件线程ID到a1
    addi a1, a1, 1       # hartid+1(栈指针初始化到该CPU栈的栈顶)
    mul a0, a0, a1       # 计算偏移量: 4096 * (hartid+1)
    add sp, sp, a0       # 设置当前CPU的栈顶指针

    la a0, bss_top        # bss清零
    la a1, end
bss_loop:
    sw zero, (a0)
    addi a0, a0, 4
    blt a0, a1, bss_loop

    call start            # 跳转到 C 代码
spin:
    j spin