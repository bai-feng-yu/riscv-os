
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.global _entry
_entry:
    # 为C语言代码设置栈空间
    # stack0声明在start.c中，每个CPU分配4096字节的栈空间
    # 计算公式: sp = stack0基地址 + (硬件线程ID * 4096)
    la sp, stack0        # 加载stack0的基地址到栈指针sp
    80000000:	00001117          	auipc	sp,0x1
    80000004:	12010113          	add	sp,sp,288 # 80001120 <stack0>
    li a0, 1024*4        # 加载4096(每个CPU的栈大小)到a0
    80000008:	6505                	lui	a0,0x1
    csrr a1, mhartid     # 读取当前硬件线程ID到a1
    8000000a:	f14025f3          	csrr	a1,mhartid
    addi a1, a1, 1       # hartid+1(栈指针初始化到该CPU栈的栈顶)
    8000000e:	0585                	add	a1,a1,1
    mul a0, a0, a1       # 计算偏移量: 4096 * (hartid+1)
    80000010:	02b50533          	mul	a0,a0,a1
    add sp, sp, a0       # 设置当前CPU的栈顶指针
    80000014:	912a                	add	sp,sp,a0

    la a0, bss_top        # bss清零
    80000016:	00001517          	auipc	a0,0x1
    8000001a:	08a50513          	add	a0,a0,138 # 800010a0 <started>
    la a1, end
    8000001e:	00009597          	auipc	a1,0x9
    80000022:	15a58593          	add	a1,a1,346 # 80009178 <end>

0000000080000026 <bss_loop>:
bss_loop:
    sw zero, (a0)
    80000026:	00052023          	sw	zero,0(a0)
    addi a0, a0, 4
    8000002a:	0511                	add	a0,a0,4
    blt a0, a1, bss_loop
    8000002c:	feb54de3          	blt	a0,a1,80000026 <bss_loop>

    call start            # 跳转到 C 代码
    80000030:	00000097          	auipc	ra,0x0
    80000034:	262080e7          	jalr	610(ra) # 80000292 <start>

0000000080000038 <spin>:
spin:
    80000038:	a001                	j	80000038 <spin>

000000008000003a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000003a:	1141                	add	sp,sp,-16
    8000003c:	e422                	sd	s0,8(sp)
    8000003e:	0800                	add	s0,sp,16
// this core's hartid (core number), the index into cpus[].
static inline uint64
r_tp()
{
  uint64 x;
  asm volatile("mv %0, tp" : "=r" (x) );
    80000040:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80000042:	2501                	sext.w	a0,a0
    80000044:	6422                	ld	s0,8(sp)
    80000046:	0141                	add	sp,sp,16
    80000048:	8082                	ret

000000008000004a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000004a:	1141                	add	sp,sp,-16
    8000004c:	e422                	sd	s0,8(sp)
    8000004e:	0800                	add	s0,sp,16
    80000050:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80000052:	2781                	sext.w	a5,a5
    80000054:	078e                	sll	a5,a5,0x3
  return c;
}
    80000056:	00001517          	auipc	a0,0x1
    8000005a:	06a50513          	add	a0,a0,106 # 800010c0 <cpus>
    8000005e:	953e                	add	a0,a0,a5
    80000060:	6422                	ld	s0,8(sp)
    80000062:	0141                	add	sp,sp,16
    80000064:	8082                	ret

0000000080000066 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000066:	1141                	add	sp,sp,-16
    80000068:	e422                	sd	s0,8(sp)
    8000006a:	0800                	add	s0,sp,16
  lk->name = name;
    8000006c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    8000006e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000072:	00053823          	sd	zero,16(a0)
}
    80000076:	6422                	ld	s0,8(sp)
    80000078:	0141                	add	sp,sp,16
    8000007a:	8082                	ret

000000008000007c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    8000007c:	411c                	lw	a5,0(a0)
    8000007e:	e399                	bnez	a5,80000084 <holding+0x8>
    80000080:	4501                	li	a0,0
  return r;
}
    80000082:	8082                	ret
{
    80000084:	1101                	add	sp,sp,-32
    80000086:	ec06                	sd	ra,24(sp)
    80000088:	e822                	sd	s0,16(sp)
    8000008a:	e426                	sd	s1,8(sp)
    8000008c:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    8000008e:	6904                	ld	s1,16(a0)
    80000090:	00000097          	auipc	ra,0x0
    80000094:	fba080e7          	jalr	-70(ra) # 8000004a <mycpu>
    80000098:	40a48533          	sub	a0,s1,a0
    8000009c:	00153513          	seqz	a0,a0
}
    800000a0:	60e2                	ld	ra,24(sp)
    800000a2:	6442                	ld	s0,16(sp)
    800000a4:	64a2                	ld	s1,8(sp)
    800000a6:	6105                	add	sp,sp,32
    800000a8:	8082                	ret

00000000800000aa <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800000aa:	1101                	add	sp,sp,-32
    800000ac:	ec06                	sd	ra,24(sp)
    800000ae:	e822                	sd	s0,16(sp)
    800000b0:	e426                	sd	s1,8(sp)
    800000b2:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800000b4:	100024f3          	csrr	s1,sstatus
    800000b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800000bc:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800000be:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800000c2:	00000097          	auipc	ra,0x0
    800000c6:	f88080e7          	jalr	-120(ra) # 8000004a <mycpu>
    800000ca:	411c                	lw	a5,0(a0)
    800000cc:	cf89                	beqz	a5,800000e6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800000ce:	00000097          	auipc	ra,0x0
    800000d2:	f7c080e7          	jalr	-132(ra) # 8000004a <mycpu>
    800000d6:	411c                	lw	a5,0(a0)
    800000d8:	2785                	addw	a5,a5,1
    800000da:	c11c                	sw	a5,0(a0)
}
    800000dc:	60e2                	ld	ra,24(sp)
    800000de:	6442                	ld	s0,16(sp)
    800000e0:	64a2                	ld	s1,8(sp)
    800000e2:	6105                	add	sp,sp,32
    800000e4:	8082                	ret
    mycpu()->intena = old;
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f64080e7          	jalr	-156(ra) # 8000004a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    800000ee:	8085                	srl	s1,s1,0x1
    800000f0:	8885                	and	s1,s1,1
    800000f2:	c144                	sw	s1,4(a0)
    800000f4:	bfe9                	j	800000ce <push_off+0x24>

00000000800000f6 <acquire>:
{
    800000f6:	1101                	add	sp,sp,-32
    800000f8:	ec06                	sd	ra,24(sp)
    800000fa:	e822                	sd	s0,16(sp)
    800000fc:	e426                	sd	s1,8(sp)
    800000fe:	1000                	add	s0,sp,32
    80000100:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000102:	00000097          	auipc	ra,0x0
    80000106:	fa8080e7          	jalr	-88(ra) # 800000aa <push_off>
  if(holding(lk))
    8000010a:	8526                	mv	a0,s1
    8000010c:	00000097          	auipc	ra,0x0
    80000110:	f70080e7          	jalr	-144(ra) # 8000007c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000114:	4705                	li	a4,1
  if(holding(lk))
    80000116:	e115                	bnez	a0,8000013a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000118:	87ba                	mv	a5,a4
    8000011a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    8000011e:	2781                	sext.w	a5,a5
    80000120:	ffe5                	bnez	a5,80000118 <acquire+0x22>
  __sync_synchronize();
    80000122:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000126:	00000097          	auipc	ra,0x0
    8000012a:	f24080e7          	jalr	-220(ra) # 8000004a <mycpu>
    8000012e:	e888                	sd	a0,16(s1)
}
    80000130:	60e2                	ld	ra,24(sp)
    80000132:	6442                	ld	s0,16(sp)
    80000134:	64a2                	ld	s1,8(sp)
    80000136:	6105                	add	sp,sp,32
    80000138:	8082                	ret
    panic("acquire");
    8000013a:	00001517          	auipc	a0,0x1
    8000013e:	ec650513          	add	a0,a0,-314 # 80001000 <_trampoline>
    80000142:	00000097          	auipc	ra,0x0
    80000146:	25c080e7          	jalr	604(ra) # 8000039e <panic>

000000008000014a <pop_off>:

void
pop_off(void)
{
    8000014a:	1141                	add	sp,sp,-16
    8000014c:	e406                	sd	ra,8(sp)
    8000014e:	e022                	sd	s0,0(sp)
    80000150:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000152:	00000097          	auipc	ra,0x0
    80000156:	ef8080e7          	jalr	-264(ra) # 8000004a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000015a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000015e:	8b89                	and	a5,a5,2
  if(intr_get())
    80000160:	e78d                	bnez	a5,8000018a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000162:	411c                	lw	a5,0(a0)
    80000164:	02f05b63          	blez	a5,8000019a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000168:	37fd                	addw	a5,a5,-1
    8000016a:	0007871b          	sext.w	a4,a5
    8000016e:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    80000170:	eb09                	bnez	a4,80000182 <pop_off+0x38>
    80000172:	415c                	lw	a5,4(a0)
    80000174:	c799                	beqz	a5,80000182 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000176:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000017a:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000017e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000182:	60a2                	ld	ra,8(sp)
    80000184:	6402                	ld	s0,0(sp)
    80000186:	0141                	add	sp,sp,16
    80000188:	8082                	ret
    panic("pop_off - interruptible");
    8000018a:	00001517          	auipc	a0,0x1
    8000018e:	e7e50513          	add	a0,a0,-386 # 80001008 <_trampoline+0x8>
    80000192:	00000097          	auipc	ra,0x0
    80000196:	20c080e7          	jalr	524(ra) # 8000039e <panic>
    panic("pop_off");
    8000019a:	00001517          	auipc	a0,0x1
    8000019e:	e8650513          	add	a0,a0,-378 # 80001020 <_trampoline+0x20>
    800001a2:	00000097          	auipc	ra,0x0
    800001a6:	1fc080e7          	jalr	508(ra) # 8000039e <panic>

00000000800001aa <release>:
{
    800001aa:	1101                	add	sp,sp,-32
    800001ac:	ec06                	sd	ra,24(sp)
    800001ae:	e822                	sd	s0,16(sp)
    800001b0:	e426                	sd	s1,8(sp)
    800001b2:	1000                	add	s0,sp,32
    800001b4:	84aa                	mv	s1,a0
  if(!holding(lk))
    800001b6:	00000097          	auipc	ra,0x0
    800001ba:	ec6080e7          	jalr	-314(ra) # 8000007c <holding>
    800001be:	c115                	beqz	a0,800001e2 <release+0x38>
  lk->cpu = 0;
    800001c0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800001c4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800001c8:	0f50000f          	fence	iorw,ow
    800001cc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    800001d0:	00000097          	auipc	ra,0x0
    800001d4:	f7a080e7          	jalr	-134(ra) # 8000014a <pop_off>
}
    800001d8:	60e2                	ld	ra,24(sp)
    800001da:	6442                	ld	s0,16(sp)
    800001dc:	64a2                	ld	s1,8(sp)
    800001de:	6105                	add	sp,sp,32
    800001e0:	8082                	ret
    panic("release");
    800001e2:	00001517          	auipc	a0,0x1
    800001e6:	e4650513          	add	a0,a0,-442 # 80001028 <_trampoline+0x28>
    800001ea:	00000097          	auipc	ra,0x0
    800001ee:	1b4080e7          	jalr	436(ra) # 8000039e <panic>

00000000800001f2 <main>:
struct spinlock start_lock;

// start()函数在管理者模式下跳转到此处，所有CPU都会执行
void
main()
{
    800001f2:	1141                	add	sp,sp,-16
    800001f4:	e406                	sd	ra,8(sp)
    800001f6:	e022                	sd	s0,0(sp)
    800001f8:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    800001fa:	00000097          	auipc	ra,0x0
    800001fe:	e40080e7          	jalr	-448(ra) # 8000003a <cpuid>
    // userinit();          // 创建第一个用户进程
    __sync_synchronize();
    started = 1;         // 标记系统启动完成
  } else {
    // 其他CPU等待CPU 0完成初始化
    while(started == 0)
    80000202:	00001717          	auipc	a4,0x1
    80000206:	e9e70713          	add	a4,a4,-354 # 800010a0 <started>
  if(cpuid() == 0){
    8000020a:	c51d                	beqz	a0,80000238 <main+0x46>
    while(started == 0)
    8000020c:	431c                	lw	a5,0(a4)
    8000020e:	2781                	sext.w	a5,a5
    80000210:	dff5                	beqz	a5,8000020c <main+0x1a>
      ;
    
    __sync_synchronize();
    80000212:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000216:	00000097          	auipc	ra,0x0
    8000021a:	e24080e7          	jalr	-476(ra) # 8000003a <cpuid>
    8000021e:	85aa                	mv	a1,a0
    80000220:	00001517          	auipc	a0,0x1
    80000224:	e2050513          	add	a0,a0,-480 # 80001040 <_trampoline+0x40>
    80000228:	00000097          	auipc	ra,0x0
    8000022c:	1c0080e7          	jalr	448(ra) # 800003e8 <printf>
    // plicinithart();   // 向PLIC请求设备中断
  }

  // // 所有CPU都进入调度器，开始调度用户进程
  // scheduler();        
}
    80000230:	60a2                	ld	ra,8(sp)
    80000232:	6402                	ld	s0,0(sp)
    80000234:	0141                	add	sp,sp,16
    80000236:	8082                	ret
    initlock(&start_lock,"start_lock");
    80000238:	00001597          	auipc	a1,0x1
    8000023c:	df858593          	add	a1,a1,-520 # 80001030 <_trampoline+0x30>
    80000240:	00001517          	auipc	a0,0x1
    80000244:	ec050513          	add	a0,a0,-320 # 80001100 <start_lock>
    80000248:	00000097          	auipc	ra,0x0
    8000024c:	e1e080e7          	jalr	-482(ra) # 80000066 <initlock>
    printfinit();
    80000250:	00000097          	auipc	ra,0x0
    80000254:	378080e7          	jalr	888(ra) # 800005c8 <printfinit>
    printf("\n");
    80000258:	00001517          	auipc	a0,0x1
    8000025c:	df850513          	add	a0,a0,-520 # 80001050 <_trampoline+0x50>
    80000260:	00000097          	auipc	ra,0x0
    80000264:	188080e7          	jalr	392(ra) # 800003e8 <printf>
    printf("hart %d starting\n", cpuid());
    80000268:	00000097          	auipc	ra,0x0
    8000026c:	dd2080e7          	jalr	-558(ra) # 8000003a <cpuid>
    80000270:	85aa                	mv	a1,a0
    80000272:	00001517          	auipc	a0,0x1
    80000276:	dce50513          	add	a0,a0,-562 # 80001040 <_trampoline+0x40>
    8000027a:	00000097          	auipc	ra,0x0
    8000027e:	16e080e7          	jalr	366(ra) # 800003e8 <printf>
    __sync_synchronize();
    80000282:	0ff0000f          	fence
    started = 1;         // 标记系统启动完成
    80000286:	4785                	li	a5,1
    80000288:	00001717          	auipc	a4,0x1
    8000028c:	e0f72c23          	sw	a5,-488(a4) # 800010a0 <started>
    80000290:	b745                	j	80000230 <main+0x3e>

0000000080000292 <start>:
void main();
void timerinit();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

void start() {
    80000292:	1141                	add	sp,sp,-16
    80000294:	e422                	sd	s0,8(sp)
    80000296:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000298:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    8000029c:	7779                	lui	a4,0xffffe
    8000029e:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fff5687>
    800002a2:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    800002a4:	6705                	lui	a4,0x1
    800002a6:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800002aa:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800002ac:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800002b0:	00000797          	auipc	a5,0x0
    800002b4:	f4278793          	add	a5,a5,-190 # 800001f2 <main>
    800002b8:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800002bc:	4781                	li	a5,0
    800002be:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800002c2:	67c1                	lui	a5,0x10
    800002c4:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800002c6:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800002ca:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800002ce:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800002d2:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800002d6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800002da:	57fd                	li	a5,-1
    800002dc:	83a9                	srl	a5,a5,0xa
    800002de:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800002e2:	47bd                	li	a5,15
    800002e4:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800002e8:	f14027f3          	csrr	a5,mhartid
//   timerinit();

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    800002ec:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800002ee:	823e                	mv	tp,a5
  
  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    800002f0:	30200073          	mret
}
    800002f4:	6422                	ld	s0,8(sp)
    800002f6:	0141                	add	sp,sp,16
    800002f8:	8082                	ret

00000000800002fa <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800002fa:	7179                	add	sp,sp,-48
    800002fc:	f406                	sd	ra,40(sp)
    800002fe:	f022                	sd	s0,32(sp)
    80000300:	ec26                	sd	s1,24(sp)
    80000302:	e84a                	sd	s2,16(sp)
    80000304:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000306:	c219                	beqz	a2,8000030c <printint+0x12>
    80000308:	08054763          	bltz	a0,80000396 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    8000030c:	2501                	sext.w	a0,a0
    8000030e:	4881                	li	a7,0
    80000310:	fd040693          	add	a3,s0,-48

  i = 0;
    80000314:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000316:	2581                	sext.w	a1,a1
    80000318:	00001617          	auipc	a2,0x1
    8000031c:	d6860613          	add	a2,a2,-664 # 80001080 <digits>
    80000320:	883a                	mv	a6,a4
    80000322:	2705                	addw	a4,a4,1
    80000324:	02b577bb          	remuw	a5,a0,a1
    80000328:	1782                	sll	a5,a5,0x20
    8000032a:	9381                	srl	a5,a5,0x20
    8000032c:	97b2                	add	a5,a5,a2
    8000032e:	0007c783          	lbu	a5,0(a5)
    80000332:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000336:	0005079b          	sext.w	a5,a0
    8000033a:	02b5553b          	divuw	a0,a0,a1
    8000033e:	0685                	add	a3,a3,1
    80000340:	feb7f0e3          	bgeu	a5,a1,80000320 <printint+0x26>

  if(sign)
    80000344:	00088c63          	beqz	a7,8000035c <printint+0x62>
    buf[i++] = '-';
    80000348:	fe070793          	add	a5,a4,-32
    8000034c:	00878733          	add	a4,a5,s0
    80000350:	02d00793          	li	a5,45
    80000354:	fef70823          	sb	a5,-16(a4)
    80000358:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    8000035c:	02e05763          	blez	a4,8000038a <printint+0x90>
    80000360:	fd040793          	add	a5,s0,-48
    80000364:	00e784b3          	add	s1,a5,a4
    80000368:	fff78913          	add	s2,a5,-1
    8000036c:	993a                	add	s2,s2,a4
    8000036e:	377d                	addw	a4,a4,-1
    80000370:	1702                	sll	a4,a4,0x20
    80000372:	9301                	srl	a4,a4,0x20
    80000374:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000378:	fff4c503          	lbu	a0,-1(s1)
    8000037c:	00000097          	auipc	ra,0x0
    80000380:	38c080e7          	jalr	908(ra) # 80000708 <consputc>
  while(--i >= 0)
    80000384:	14fd                	add	s1,s1,-1
    80000386:	ff2499e3          	bne	s1,s2,80000378 <printint+0x7e>
}
    8000038a:	70a2                	ld	ra,40(sp)
    8000038c:	7402                	ld	s0,32(sp)
    8000038e:	64e2                	ld	s1,24(sp)
    80000390:	6942                	ld	s2,16(sp)
    80000392:	6145                	add	sp,sp,48
    80000394:	8082                	ret
    x = -xx;
    80000396:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000039a:	4885                	li	a7,1
    x = -xx;
    8000039c:	bf95                	j	80000310 <printint+0x16>

000000008000039e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000039e:	1101                	add	sp,sp,-32
    800003a0:	ec06                	sd	ra,24(sp)
    800003a2:	e822                	sd	s0,16(sp)
    800003a4:	e426                	sd	s1,8(sp)
    800003a6:	1000                	add	s0,sp,32
    800003a8:	84aa                	mv	s1,a0
  pr.locking = 0;
    800003aa:	00009797          	auipc	a5,0x9
    800003ae:	d807a723          	sw	zero,-626(a5) # 80009138 <pr+0x18>
  printf("panic: ");
    800003b2:	00001517          	auipc	a0,0x1
    800003b6:	ca650513          	add	a0,a0,-858 # 80001058 <_trampoline+0x58>
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	02e080e7          	jalr	46(ra) # 800003e8 <printf>
  printf(s);
    800003c2:	8526                	mv	a0,s1
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	024080e7          	jalr	36(ra) # 800003e8 <printf>
  printf("\n");
    800003cc:	00001517          	auipc	a0,0x1
    800003d0:	c8450513          	add	a0,a0,-892 # 80001050 <_trampoline+0x50>
    800003d4:	00000097          	auipc	ra,0x0
    800003d8:	014080e7          	jalr	20(ra) # 800003e8 <printf>
  panicked = 1; // freeze uart output from other CPUs
    800003dc:	4785                	li	a5,1
    800003de:	00001717          	auipc	a4,0x1
    800003e2:	ccf72323          	sw	a5,-826(a4) # 800010a4 <panicked>
  for(;;)
    800003e6:	a001                	j	800003e6 <panic+0x48>

00000000800003e8 <printf>:
{
    800003e8:	7131                	add	sp,sp,-192
    800003ea:	fc86                	sd	ra,120(sp)
    800003ec:	f8a2                	sd	s0,112(sp)
    800003ee:	f4a6                	sd	s1,104(sp)
    800003f0:	f0ca                	sd	s2,96(sp)
    800003f2:	ecce                	sd	s3,88(sp)
    800003f4:	e8d2                	sd	s4,80(sp)
    800003f6:	e4d6                	sd	s5,72(sp)
    800003f8:	e0da                	sd	s6,64(sp)
    800003fa:	fc5e                	sd	s7,56(sp)
    800003fc:	f862                	sd	s8,48(sp)
    800003fe:	f466                	sd	s9,40(sp)
    80000400:	f06a                	sd	s10,32(sp)
    80000402:	ec6e                	sd	s11,24(sp)
    80000404:	0100                	add	s0,sp,128
    80000406:	8a2a                	mv	s4,a0
    80000408:	e40c                	sd	a1,8(s0)
    8000040a:	e810                	sd	a2,16(s0)
    8000040c:	ec14                	sd	a3,24(s0)
    8000040e:	f018                	sd	a4,32(s0)
    80000410:	f41c                	sd	a5,40(s0)
    80000412:	03043823          	sd	a6,48(s0)
    80000416:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000041a:	00009d97          	auipc	s11,0x9
    8000041e:	d1edad83          	lw	s11,-738(s11) # 80009138 <pr+0x18>
  if(locking)
    80000422:	020d9b63          	bnez	s11,80000458 <printf+0x70>
  if (fmt == 0)
    80000426:	040a0263          	beqz	s4,8000046a <printf+0x82>
  va_start(ap, fmt);
    8000042a:	00840793          	add	a5,s0,8
    8000042e:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000432:	000a4503          	lbu	a0,0(s4)
    80000436:	14050f63          	beqz	a0,80000594 <printf+0x1ac>
    8000043a:	4981                	li	s3,0
    if(c != '%'){
    8000043c:	02500a93          	li	s5,37
    switch(c){
    80000440:	07000b93          	li	s7,112
  consputc('x');
    80000444:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000446:	00001b17          	auipc	s6,0x1
    8000044a:	c3ab0b13          	add	s6,s6,-966 # 80001080 <digits>
    switch(c){
    8000044e:	07300c93          	li	s9,115
    80000452:	06400c13          	li	s8,100
    80000456:	a82d                	j	80000490 <printf+0xa8>
    acquire(&pr.lock);
    80000458:	00009517          	auipc	a0,0x9
    8000045c:	cc850513          	add	a0,a0,-824 # 80009120 <pr>
    80000460:	00000097          	auipc	ra,0x0
    80000464:	c96080e7          	jalr	-874(ra) # 800000f6 <acquire>
    80000468:	bf7d                	j	80000426 <printf+0x3e>
    panic("null fmt");
    8000046a:	00001517          	auipc	a0,0x1
    8000046e:	bfe50513          	add	a0,a0,-1026 # 80001068 <_trampoline+0x68>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	f2c080e7          	jalr	-212(ra) # 8000039e <panic>
      consputc(c);
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	28e080e7          	jalr	654(ra) # 80000708 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000482:	2985                	addw	s3,s3,1
    80000484:	013a07b3          	add	a5,s4,s3
    80000488:	0007c503          	lbu	a0,0(a5)
    8000048c:	10050463          	beqz	a0,80000594 <printf+0x1ac>
    if(c != '%'){
    80000490:	ff5515e3          	bne	a0,s5,8000047a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000494:	2985                	addw	s3,s3,1
    80000496:	013a07b3          	add	a5,s4,s3
    8000049a:	0007c783          	lbu	a5,0(a5)
    8000049e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    800004a2:	cbed                	beqz	a5,80000594 <printf+0x1ac>
    switch(c){
    800004a4:	05778a63          	beq	a5,s7,800004f8 <printf+0x110>
    800004a8:	02fbf663          	bgeu	s7,a5,800004d4 <printf+0xec>
    800004ac:	09978863          	beq	a5,s9,8000053c <printf+0x154>
    800004b0:	07800713          	li	a4,120
    800004b4:	0ce79563          	bne	a5,a4,8000057e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    800004b8:	f8843783          	ld	a5,-120(s0)
    800004bc:	00878713          	add	a4,a5,8
    800004c0:	f8e43423          	sd	a4,-120(s0)
    800004c4:	4605                	li	a2,1
    800004c6:	85ea                	mv	a1,s10
    800004c8:	4388                	lw	a0,0(a5)
    800004ca:	00000097          	auipc	ra,0x0
    800004ce:	e30080e7          	jalr	-464(ra) # 800002fa <printint>
      break;
    800004d2:	bf45                	j	80000482 <printf+0x9a>
    switch(c){
    800004d4:	09578f63          	beq	a5,s5,80000572 <printf+0x18a>
    800004d8:	0b879363          	bne	a5,s8,8000057e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    800004dc:	f8843783          	ld	a5,-120(s0)
    800004e0:	00878713          	add	a4,a5,8
    800004e4:	f8e43423          	sd	a4,-120(s0)
    800004e8:	4605                	li	a2,1
    800004ea:	45a9                	li	a1,10
    800004ec:	4388                	lw	a0,0(a5)
    800004ee:	00000097          	auipc	ra,0x0
    800004f2:	e0c080e7          	jalr	-500(ra) # 800002fa <printint>
      break;
    800004f6:	b771                	j	80000482 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800004f8:	f8843783          	ld	a5,-120(s0)
    800004fc:	00878713          	add	a4,a5,8
    80000500:	f8e43423          	sd	a4,-120(s0)
    80000504:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000508:	03000513          	li	a0,48
    8000050c:	00000097          	auipc	ra,0x0
    80000510:	1fc080e7          	jalr	508(ra) # 80000708 <consputc>
  consputc('x');
    80000514:	07800513          	li	a0,120
    80000518:	00000097          	auipc	ra,0x0
    8000051c:	1f0080e7          	jalr	496(ra) # 80000708 <consputc>
    80000520:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000522:	03c95793          	srl	a5,s2,0x3c
    80000526:	97da                	add	a5,a5,s6
    80000528:	0007c503          	lbu	a0,0(a5)
    8000052c:	00000097          	auipc	ra,0x0
    80000530:	1dc080e7          	jalr	476(ra) # 80000708 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000534:	0912                	sll	s2,s2,0x4
    80000536:	34fd                	addw	s1,s1,-1
    80000538:	f4ed                	bnez	s1,80000522 <printf+0x13a>
    8000053a:	b7a1                	j	80000482 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    8000053c:	f8843783          	ld	a5,-120(s0)
    80000540:	00878713          	add	a4,a5,8
    80000544:	f8e43423          	sd	a4,-120(s0)
    80000548:	6384                	ld	s1,0(a5)
    8000054a:	cc89                	beqz	s1,80000564 <printf+0x17c>
      for(; *s; s++)
    8000054c:	0004c503          	lbu	a0,0(s1)
    80000550:	d90d                	beqz	a0,80000482 <printf+0x9a>
        consputc(*s);
    80000552:	00000097          	auipc	ra,0x0
    80000556:	1b6080e7          	jalr	438(ra) # 80000708 <consputc>
      for(; *s; s++)
    8000055a:	0485                	add	s1,s1,1
    8000055c:	0004c503          	lbu	a0,0(s1)
    80000560:	f96d                	bnez	a0,80000552 <printf+0x16a>
    80000562:	b705                	j	80000482 <printf+0x9a>
        s = "(null)";
    80000564:	00001497          	auipc	s1,0x1
    80000568:	afc48493          	add	s1,s1,-1284 # 80001060 <_trampoline+0x60>
      for(; *s; s++)
    8000056c:	02800513          	li	a0,40
    80000570:	b7cd                	j	80000552 <printf+0x16a>
      consputc('%');
    80000572:	8556                	mv	a0,s5
    80000574:	00000097          	auipc	ra,0x0
    80000578:	194080e7          	jalr	404(ra) # 80000708 <consputc>
      break;
    8000057c:	b719                	j	80000482 <printf+0x9a>
      consputc('%');
    8000057e:	8556                	mv	a0,s5
    80000580:	00000097          	auipc	ra,0x0
    80000584:	188080e7          	jalr	392(ra) # 80000708 <consputc>
      consputc(c);
    80000588:	8526                	mv	a0,s1
    8000058a:	00000097          	auipc	ra,0x0
    8000058e:	17e080e7          	jalr	382(ra) # 80000708 <consputc>
      break;
    80000592:	bdc5                	j	80000482 <printf+0x9a>
  if(locking)
    80000594:	020d9163          	bnez	s11,800005b6 <printf+0x1ce>
}
    80000598:	70e6                	ld	ra,120(sp)
    8000059a:	7446                	ld	s0,112(sp)
    8000059c:	74a6                	ld	s1,104(sp)
    8000059e:	7906                	ld	s2,96(sp)
    800005a0:	69e6                	ld	s3,88(sp)
    800005a2:	6a46                	ld	s4,80(sp)
    800005a4:	6aa6                	ld	s5,72(sp)
    800005a6:	6b06                	ld	s6,64(sp)
    800005a8:	7be2                	ld	s7,56(sp)
    800005aa:	7c42                	ld	s8,48(sp)
    800005ac:	7ca2                	ld	s9,40(sp)
    800005ae:	7d02                	ld	s10,32(sp)
    800005b0:	6de2                	ld	s11,24(sp)
    800005b2:	6129                	add	sp,sp,192
    800005b4:	8082                	ret
    release(&pr.lock);
    800005b6:	00009517          	auipc	a0,0x9
    800005ba:	b6a50513          	add	a0,a0,-1174 # 80009120 <pr>
    800005be:	00000097          	auipc	ra,0x0
    800005c2:	bec080e7          	jalr	-1044(ra) # 800001aa <release>
}
    800005c6:	bfc9                	j	80000598 <printf+0x1b0>

00000000800005c8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800005c8:	1101                	add	sp,sp,-32
    800005ca:	ec06                	sd	ra,24(sp)
    800005cc:	e822                	sd	s0,16(sp)
    800005ce:	e426                	sd	s1,8(sp)
    800005d0:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    800005d2:	00009497          	auipc	s1,0x9
    800005d6:	b4e48493          	add	s1,s1,-1202 # 80009120 <pr>
    800005da:	00001597          	auipc	a1,0x1
    800005de:	a9e58593          	add	a1,a1,-1378 # 80001078 <_trampoline+0x78>
    800005e2:	8526                	mv	a0,s1
    800005e4:	00000097          	auipc	ra,0x0
    800005e8:	a82080e7          	jalr	-1406(ra) # 80000066 <initlock>
  pr.locking = 1;
    800005ec:	4785                	li	a5,1
    800005ee:	cc9c                	sw	a5,24(s1)
}
    800005f0:	60e2                	ld	ra,24(sp)
    800005f2:	6442                	ld	s0,16(sp)
    800005f4:	64a2                	ld	s1,8(sp)
    800005f6:	6105                	add	sp,sp,32
    800005f8:	8082                	ret

00000000800005fa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800005fa:	1141                	add	sp,sp,-16
    800005fc:	e406                	sd	ra,8(sp)
    800005fe:	e022                	sd	s0,0(sp)
    80000600:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000602:	100007b7          	lui	a5,0x10000
    80000606:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000060a:	f8000713          	li	a4,-128
    8000060e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000612:	470d                	li	a4,3
    80000614:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000618:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000061c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000620:	469d                	li	a3,7
    80000622:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000626:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000062a:	00001597          	auipc	a1,0x1
    8000062e:	a6e58593          	add	a1,a1,-1426 # 80001098 <digits+0x18>
    80000632:	00009517          	auipc	a0,0x9
    80000636:	b0e50513          	add	a0,a0,-1266 # 80009140 <uart_tx_lock>
    8000063a:	00000097          	auipc	ra,0x0
    8000063e:	a2c080e7          	jalr	-1492(ra) # 80000066 <initlock>
}
    80000642:	60a2                	ld	ra,8(sp)
    80000644:	6402                	ld	s0,0(sp)
    80000646:	0141                	add	sp,sp,16
    80000648:	8082                	ret

000000008000064a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000064a:	1101                	add	sp,sp,-32
    8000064c:	ec06                	sd	ra,24(sp)
    8000064e:	e822                	sd	s0,16(sp)
    80000650:	e426                	sd	s1,8(sp)
    80000652:	1000                	add	s0,sp,32
    80000654:	84aa                	mv	s1,a0
  push_off();
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	a54080e7          	jalr	-1452(ra) # 800000aa <push_off>

  if(panicked){
    8000065e:	00001797          	auipc	a5,0x1
    80000662:	a467a783          	lw	a5,-1466(a5) # 800010a4 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000666:	10000737          	lui	a4,0x10000
  if(panicked){
    8000066a:	c391                	beqz	a5,8000066e <uartputc_sync+0x24>
    for(;;)
    8000066c:	a001                	j	8000066c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000066e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000672:	0207f793          	and	a5,a5,32
    80000676:	dfe5                	beqz	a5,8000066e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000678:	0ff4f513          	zext.b	a0,s1
    8000067c:	100007b7          	lui	a5,0x10000
    80000680:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000684:	00000097          	auipc	ra,0x0
    80000688:	ac6080e7          	jalr	-1338(ra) # 8000014a <pop_off>
}
    8000068c:	60e2                	ld	ra,24(sp)
    8000068e:	6442                	ld	s0,16(sp)
    80000690:	64a2                	ld	s1,8(sp)
    80000692:	6105                	add	sp,sp,32
    80000694:	8082                	ret

0000000080000696 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000696:	1141                	add	sp,sp,-16
    80000698:	e422                	sd	s0,8(sp)
    8000069a:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000069c:	100007b7          	lui	a5,0x10000
    800006a0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800006a4:	8b85                	and	a5,a5,1
    800006a6:	cb81                	beqz	a5,800006b6 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800006a8:	100007b7          	lui	a5,0x10000
    800006ac:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800006b0:	6422                	ld	s0,8(sp)
    800006b2:	0141                	add	sp,sp,16
    800006b4:	8082                	ret
    return -1;
    800006b6:	557d                	li	a0,-1
    800006b8:	bfe5                	j	800006b0 <uartgetc+0x1a>

00000000800006ba <uart_putc>:
//   uartstart();
//   release(&uart_tx_lock);
// }


void uart_putc(char c) {
    800006ba:	1141                	add	sp,sp,-16
    800006bc:	e422                	sd	s0,8(sp)
    800006be:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    800006c0:	10000737          	lui	a4,0x10000
    800006c4:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800006c8:	0207f793          	and	a5,a5,32
    800006cc:	dfe5                	beqz	a5,800006c4 <uart_putc+0xa>
    uart[0] = c;
    800006ce:	100007b7          	lui	a5,0x10000
    800006d2:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    800006d6:	6422                	ld	s0,8(sp)
    800006d8:	0141                	add	sp,sp,16
    800006da:	8082                	ret

00000000800006dc <uart_puts>:

void uart_puts(char *s) {
    800006dc:	1101                	add	sp,sp,-32
    800006de:	ec06                	sd	ra,24(sp)
    800006e0:	e822                	sd	s0,16(sp)
    800006e2:	e426                	sd	s1,8(sp)
    800006e4:	1000                	add	s0,sp,32
    800006e6:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    800006e8:	00054503          	lbu	a0,0(a0)
    800006ec:	c909                	beqz	a0,800006fe <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	fcc080e7          	jalr	-52(ra) # 800006ba <uart_putc>
        s++;              // 移动到下一个字符
    800006f6:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	f96d                	bnez	a0,800006ee <uart_puts+0x12>
    }
}
    800006fe:	60e2                	ld	ra,24(sp)
    80000700:	6442                	ld	s0,16(sp)
    80000702:	64a2                	ld	s1,8(sp)
    80000704:	6105                	add	sp,sp,32
    80000706:	8082                	ret

0000000080000708 <consputc>:
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    80000708:	1141                	add	sp,sp,-16
    8000070a:	e406                	sd	ra,8(sp)
    8000070c:	e022                	sd	s0,0(sp)
    8000070e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000710:	10000793          	li	a5,256
    80000714:	00f50a63          	beq	a0,a5,80000728 <consputc+0x20>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	f32080e7          	jalr	-206(ra) # 8000064a <uartputc_sync>
  }
}
    80000720:	60a2                	ld	ra,8(sp)
    80000722:	6402                	ld	s0,0(sp)
    80000724:	0141                	add	sp,sp,16
    80000726:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000728:	4521                	li	a0,8
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	f20080e7          	jalr	-224(ra) # 8000064a <uartputc_sync>
    80000732:	02000513          	li	a0,32
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	f14080e7          	jalr	-236(ra) # 8000064a <uartputc_sync>
    8000073e:	4521                	li	a0,8
    80000740:	00000097          	auipc	ra,0x0
    80000744:	f0a080e7          	jalr	-246(ra) # 8000064a <uartputc_sync>
    80000748:	bfe1                	j	80000720 <consputc+0x18>
	...
