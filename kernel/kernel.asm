
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.global _entry
_entry:
    # 为C语言代码设置栈空间
    # stack0声明在start.c中，每个CPU分配4096字节的栈空间
    # 计算公式: sp = stack0基地址 + (硬件线程ID * 4096)
    la sp, stack0        # 加载stack0的基地址到栈指针sp
    80000000:	00003117          	auipc	sp,0x3
    80000004:	17010113          	add	sp,sp,368 # 80003170 <stack0>
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
    8000001a:	0da50513          	add	a0,a0,218 # 800010f0 <over_2>
    la a1, end
    8000001e:	0000b597          	auipc	a1,0xb
    80000022:	1aa58593          	add	a1,a1,426 # 8000b1c8 <end>

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
    80000034:	4dc080e7          	jalr	1244(ra) # 8000050c <start>

0000000080000038 <spin>:
spin:
    80000038:	a001                	j	80000038 <spin>

000000008000003a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(uint64 page, bool in_kernel)
{
    8000003a:	1101                	add	sp,sp,-32
    8000003c:	ec06                	sd	ra,24(sp)
    8000003e:	e822                	sd	s0,16(sp)
    80000040:	e426                	sd	s1,8(sp)
    80000042:	e04a                	sd	s2,0(sp)
    80000044:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)page % PGSIZE) != 0 || (char*)page < end || (uint64)page >= PHYSTOP) //检测合法性
    80000046:	03451793          	sll	a5,a0,0x34
    8000004a:	ebb9                	bnez	a5,800000a0 <kfree+0x66>
    8000004c:	84aa                	mv	s1,a0
    8000004e:	0000b797          	auipc	a5,0xb
    80000052:	17a78793          	add	a5,a5,378 # 8000b1c8 <end>
    80000056:	04f56563          	bltu	a0,a5,800000a0 <kfree+0x66>
    8000005a:	47c5                	li	a5,17
    8000005c:	07ee                	sll	a5,a5,0x1b
    8000005e:	04f57163          	bgeu	a0,a5,800000a0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset((char*)page, 1, PGSIZE); 
    80000062:	6605                	lui	a2,0x1
    80000064:	4585                	li	a1,1
    80000066:	00000097          	auipc	ra,0x0
    8000006a:	50e080e7          	jalr	1294(ra) # 80000574 <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    8000006e:	00001917          	auipc	s2,0x1
    80000072:	0a290913          	add	s2,s2,162 # 80001110 <kmem>
    80000076:	854a                	mv	a0,s2
    80000078:	00000097          	auipc	ra,0x0
    8000007c:	1de080e7          	jalr	478(ra) # 80000256 <acquire>
  r->next = kmem.freelist;  //头插
    80000080:	01893783          	ld	a5,24(s2)
    80000084:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000086:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    8000008a:	854a                	mv	a0,s2
    8000008c:	00000097          	auipc	ra,0x0
    80000090:	27e080e7          	jalr	638(ra) # 8000030a <release>
}
    80000094:	60e2                	ld	ra,24(sp)
    80000096:	6442                	ld	s0,16(sp)
    80000098:	64a2                	ld	s1,8(sp)
    8000009a:	6902                	ld	s2,0(sp)
    8000009c:	6105                	add	sp,sp,32
    8000009e:	8082                	ret
    panic("kfree");
    800000a0:	00001517          	auipc	a0,0x1
    800000a4:	f6050513          	add	a0,a0,-160 # 80001000 <_trampoline>
    800000a8:	00000097          	auipc	ra,0x0
    800000ac:	714080e7          	jalr	1812(ra) # 800007bc <panic>

00000000800000b0 <freerange>:
{
    800000b0:	7179                	add	sp,sp,-48
    800000b2:	f406                	sd	ra,40(sp)
    800000b4:	f022                	sd	s0,32(sp)
    800000b6:	ec26                	sd	s1,24(sp)
    800000b8:	e84a                	sd	s2,16(sp)
    800000ba:	e44e                	sd	s3,8(sp)
    800000bc:	e052                	sd	s4,0(sp)
    800000be:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start); //可用内存初始地址对齐4KB
    800000c0:	6785                	lui	a5,0x1
    800000c2:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    800000c6:	00e504b3          	add	s1,a0,a4
    800000ca:	777d                	lui	a4,0xfffff
    800000cc:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800000ce:	94be                	add	s1,s1,a5
    800000d0:	0095ef63          	bltu	a1,s1,800000ee <freerange+0x3e>
    800000d4:	892e                	mv	s2,a1
    kfree((uint64)p,true);
    800000d6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800000d8:	6985                	lui	s3,0x1
    kfree((uint64)p,true);
    800000da:	4585                	li	a1,1
    800000dc:	01448533          	add	a0,s1,s4
    800000e0:	00000097          	auipc	ra,0x0
    800000e4:	f5a080e7          	jalr	-166(ra) # 8000003a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800000e8:	94ce                	add	s1,s1,s3
    800000ea:	fe9978e3          	bgeu	s2,s1,800000da <freerange+0x2a>
}
    800000ee:	70a2                	ld	ra,40(sp)
    800000f0:	7402                	ld	s0,32(sp)
    800000f2:	64e2                	ld	s1,24(sp)
    800000f4:	6942                	ld	s2,16(sp)
    800000f6:	69a2                	ld	s3,8(sp)
    800000f8:	6a02                	ld	s4,0(sp)
    800000fa:	6145                	add	sp,sp,48
    800000fc:	8082                	ret

00000000800000fe <kinit>:
{
    800000fe:	1141                	add	sp,sp,-16
    80000100:	e406                	sd	ra,8(sp)
    80000102:	e022                	sd	s0,0(sp)
    80000104:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000106:	00001597          	auipc	a1,0x1
    8000010a:	f0258593          	add	a1,a1,-254 # 80001008 <_trampoline+0x8>
    8000010e:	00001517          	auipc	a0,0x1
    80000112:	00250513          	add	a0,a0,2 # 80001110 <kmem>
    80000116:	00000097          	auipc	ra,0x0
    8000011a:	0b0080e7          	jalr	176(ra) # 800001c6 <initlock>
  freerange(end, (void*)PHYSTOP);
    8000011e:	45c5                	li	a1,17
    80000120:	05ee                	sll	a1,a1,0x1b
    80000122:	0000b517          	auipc	a0,0xb
    80000126:	0a650513          	add	a0,a0,166 # 8000b1c8 <end>
    8000012a:	00000097          	auipc	ra,0x0
    8000012e:	f86080e7          	jalr	-122(ra) # 800000b0 <freerange>
}
    80000132:	60a2                	ld	ra,8(sp)
    80000134:	6402                	ld	s0,0(sp)
    80000136:	0141                	add	sp,sp,16
    80000138:	8082                	ret

000000008000013a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(bool in_kernel)
{
    8000013a:	1101                	add	sp,sp,-32
    8000013c:	ec06                	sd	ra,24(sp)
    8000013e:	e822                	sd	s0,16(sp)
    80000140:	e426                	sd	s1,8(sp)
    80000142:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);  
    80000144:	00001497          	auipc	s1,0x1
    80000148:	fcc48493          	add	s1,s1,-52 # 80001110 <kmem>
    8000014c:	8526                	mv	a0,s1
    8000014e:	00000097          	auipc	ra,0x0
    80000152:	108080e7          	jalr	264(ra) # 80000256 <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80000156:	6c84                	ld	s1,24(s1)
  if(r)
    80000158:	c885                	beqz	s1,80000188 <kalloc+0x4e>
    kmem.freelist = r->next;
    8000015a:	609c                	ld	a5,0(s1)
    8000015c:	00001517          	auipc	a0,0x1
    80000160:	fb450513          	add	a0,a0,-76 # 80001110 <kmem>
    80000164:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000166:	00000097          	auipc	ra,0x0
    8000016a:	1a4080e7          	jalr	420(ra) # 8000030a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    8000016e:	6605                	lui	a2,0x1
    80000170:	4595                	li	a1,5
    80000172:	8526                	mv	a0,s1
    80000174:	00000097          	auipc	ra,0x0
    80000178:	400080e7          	jalr	1024(ra) # 80000574 <memset>
  return (void*)r;
}
    8000017c:	8526                	mv	a0,s1
    8000017e:	60e2                	ld	ra,24(sp)
    80000180:	6442                	ld	s0,16(sp)
    80000182:	64a2                	ld	s1,8(sp)
    80000184:	6105                	add	sp,sp,32
    80000186:	8082                	ret
  release(&kmem.lock);
    80000188:	00001517          	auipc	a0,0x1
    8000018c:	f8850513          	add	a0,a0,-120 # 80001110 <kmem>
    80000190:	00000097          	auipc	ra,0x0
    80000194:	17a080e7          	jalr	378(ra) # 8000030a <release>
  if(r)
    80000198:	b7d5                	j	8000017c <kalloc+0x42>

000000008000019a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000019a:	1141                	add	sp,sp,-16
    8000019c:	e422                	sd	s0,8(sp)
    8000019e:	0800                	add	s0,sp,16
// this core's hartid (core number), the index into cpus[].
static inline uint64
r_tp()
{
  uint64 x;
  asm volatile("mv %0, tp" : "=r" (x) );
    800001a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800001a2:	2501                	sext.w	a0,a0
    800001a4:	6422                	ld	s0,8(sp)
    800001a6:	0141                	add	sp,sp,16
    800001a8:	8082                	ret

00000000800001aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800001aa:	1141                	add	sp,sp,-16
    800001ac:	e422                	sd	s0,8(sp)
    800001ae:	0800                	add	s0,sp,16
    800001b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800001b2:	2781                	sext.w	a5,a5
    800001b4:	078e                	sll	a5,a5,0x3
  return c;
}
    800001b6:	00001517          	auipc	a0,0x1
    800001ba:	f7a50513          	add	a0,a0,-134 # 80001130 <cpus>
    800001be:	953e                	add	a0,a0,a5
    800001c0:	6422                	ld	s0,8(sp)
    800001c2:	0141                	add	sp,sp,16
    800001c4:	8082                	ret

00000000800001c6 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    800001c6:	1141                	add	sp,sp,-16
    800001c8:	e422                	sd	s0,8(sp)
    800001ca:	0800                	add	s0,sp,16
  lk->name = name;
    800001cc:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800001ce:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800001d2:	00053823          	sd	zero,16(a0)
}
    800001d6:	6422                	ld	s0,8(sp)
    800001d8:	0141                	add	sp,sp,16
    800001da:	8082                	ret

00000000800001dc <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    800001dc:	411c                	lw	a5,0(a0)
    800001de:	e399                	bnez	a5,800001e4 <holding+0x8>
    800001e0:	4501                	li	a0,0
  return r;
}
    800001e2:	8082                	ret
{
    800001e4:	1101                	add	sp,sp,-32
    800001e6:	ec06                	sd	ra,24(sp)
    800001e8:	e822                	sd	s0,16(sp)
    800001ea:	e426                	sd	s1,8(sp)
    800001ec:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    800001ee:	6904                	ld	s1,16(a0)
    800001f0:	00000097          	auipc	ra,0x0
    800001f4:	fba080e7          	jalr	-70(ra) # 800001aa <mycpu>
    800001f8:	40a48533          	sub	a0,s1,a0
    800001fc:	00153513          	seqz	a0,a0
}
    80000200:	60e2                	ld	ra,24(sp)
    80000202:	6442                	ld	s0,16(sp)
    80000204:	64a2                	ld	s1,8(sp)
    80000206:	6105                	add	sp,sp,32
    80000208:	8082                	ret

000000008000020a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    8000020a:	1101                	add	sp,sp,-32
    8000020c:	ec06                	sd	ra,24(sp)
    8000020e:	e822                	sd	s0,16(sp)
    80000210:	e426                	sd	s1,8(sp)
    80000212:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000214:	100024f3          	csrr	s1,sstatus
    80000218:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000021c:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000021e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000222:	00000097          	auipc	ra,0x0
    80000226:	f88080e7          	jalr	-120(ra) # 800001aa <mycpu>
    8000022a:	411c                	lw	a5,0(a0)
    8000022c:	cf89                	beqz	a5,80000246 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    8000022e:	00000097          	auipc	ra,0x0
    80000232:	f7c080e7          	jalr	-132(ra) # 800001aa <mycpu>
    80000236:	411c                	lw	a5,0(a0)
    80000238:	2785                	addw	a5,a5,1
    8000023a:	c11c                	sw	a5,0(a0)
}
    8000023c:	60e2                	ld	ra,24(sp)
    8000023e:	6442                	ld	s0,16(sp)
    80000240:	64a2                	ld	s1,8(sp)
    80000242:	6105                	add	sp,sp,32
    80000244:	8082                	ret
    mycpu()->intena = old;
    80000246:	00000097          	auipc	ra,0x0
    8000024a:	f64080e7          	jalr	-156(ra) # 800001aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    8000024e:	8085                	srl	s1,s1,0x1
    80000250:	8885                	and	s1,s1,1
    80000252:	c144                	sw	s1,4(a0)
    80000254:	bfe9                	j	8000022e <push_off+0x24>

0000000080000256 <acquire>:
{
    80000256:	1101                	add	sp,sp,-32
    80000258:	ec06                	sd	ra,24(sp)
    8000025a:	e822                	sd	s0,16(sp)
    8000025c:	e426                	sd	s1,8(sp)
    8000025e:	1000                	add	s0,sp,32
    80000260:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000262:	00000097          	auipc	ra,0x0
    80000266:	fa8080e7          	jalr	-88(ra) # 8000020a <push_off>
  if(holding(lk))
    8000026a:	8526                	mv	a0,s1
    8000026c:	00000097          	auipc	ra,0x0
    80000270:	f70080e7          	jalr	-144(ra) # 800001dc <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000274:	4705                	li	a4,1
  if(holding(lk))
    80000276:	e115                	bnez	a0,8000029a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000278:	87ba                	mv	a5,a4
    8000027a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    8000027e:	2781                	sext.w	a5,a5
    80000280:	ffe5                	bnez	a5,80000278 <acquire+0x22>
  __sync_synchronize();
    80000282:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000286:	00000097          	auipc	ra,0x0
    8000028a:	f24080e7          	jalr	-220(ra) # 800001aa <mycpu>
    8000028e:	e888                	sd	a0,16(s1)
}
    80000290:	60e2                	ld	ra,24(sp)
    80000292:	6442                	ld	s0,16(sp)
    80000294:	64a2                	ld	s1,8(sp)
    80000296:	6105                	add	sp,sp,32
    80000298:	8082                	ret
    panic("acquire");
    8000029a:	00001517          	auipc	a0,0x1
    8000029e:	d7650513          	add	a0,a0,-650 # 80001010 <_trampoline+0x10>
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	51a080e7          	jalr	1306(ra) # 800007bc <panic>

00000000800002aa <pop_off>:

void
pop_off(void)
{
    800002aa:	1141                	add	sp,sp,-16
    800002ac:	e406                	sd	ra,8(sp)
    800002ae:	e022                	sd	s0,0(sp)
    800002b0:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    800002b2:	00000097          	auipc	ra,0x0
    800002b6:	ef8080e7          	jalr	-264(ra) # 800001aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800002ba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800002be:	8b89                	and	a5,a5,2
  if(intr_get())
    800002c0:	e78d                	bnez	a5,800002ea <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    800002c2:	411c                	lw	a5,0(a0)
    800002c4:	02f05b63          	blez	a5,800002fa <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    800002c8:	37fd                	addw	a5,a5,-1
    800002ca:	0007871b          	sext.w	a4,a5
    800002ce:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    800002d0:	eb09                	bnez	a4,800002e2 <pop_off+0x38>
    800002d2:	415c                	lw	a5,4(a0)
    800002d4:	c799                	beqz	a5,800002e2 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800002d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800002da:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800002de:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800002e2:	60a2                	ld	ra,8(sp)
    800002e4:	6402                	ld	s0,0(sp)
    800002e6:	0141                	add	sp,sp,16
    800002e8:	8082                	ret
    panic("pop_off - interruptible");
    800002ea:	00001517          	auipc	a0,0x1
    800002ee:	d2e50513          	add	a0,a0,-722 # 80001018 <_trampoline+0x18>
    800002f2:	00000097          	auipc	ra,0x0
    800002f6:	4ca080e7          	jalr	1226(ra) # 800007bc <panic>
    panic("pop_off");
    800002fa:	00001517          	auipc	a0,0x1
    800002fe:	d3650513          	add	a0,a0,-714 # 80001030 <_trampoline+0x30>
    80000302:	00000097          	auipc	ra,0x0
    80000306:	4ba080e7          	jalr	1210(ra) # 800007bc <panic>

000000008000030a <release>:
{
    8000030a:	1101                	add	sp,sp,-32
    8000030c:	ec06                	sd	ra,24(sp)
    8000030e:	e822                	sd	s0,16(sp)
    80000310:	e426                	sd	s1,8(sp)
    80000312:	1000                	add	s0,sp,32
    80000314:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000316:	00000097          	auipc	ra,0x0
    8000031a:	ec6080e7          	jalr	-314(ra) # 800001dc <holding>
    8000031e:	c115                	beqz	a0,80000342 <release+0x38>
  lk->cpu = 0;
    80000320:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000324:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000328:	0f50000f          	fence	iorw,ow
    8000032c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000330:	00000097          	auipc	ra,0x0
    80000334:	f7a080e7          	jalr	-134(ra) # 800002aa <pop_off>
}
    80000338:	60e2                	ld	ra,24(sp)
    8000033a:	6442                	ld	s0,16(sp)
    8000033c:	64a2                	ld	s1,8(sp)
    8000033e:	6105                	add	sp,sp,32
    80000340:	8082                	ret
    panic("release");
    80000342:	00001517          	auipc	a0,0x1
    80000346:	cf650513          	add	a0,a0,-778 # 80001038 <_trampoline+0x38>
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	472080e7          	jalr	1138(ra) # 800007bc <panic>

0000000080000352 <main>:
volatile static int over_1 = 0, over_2 = 0;

static int* mem[1024];

int main()
{
    80000352:	7139                	add	sp,sp,-64
    80000354:	fc06                	sd	ra,56(sp)
    80000356:	f822                	sd	s0,48(sp)
    80000358:	f426                	sd	s1,40(sp)
    8000035a:	f04a                	sd	s2,32(sp)
    8000035c:	ec4e                	sd	s3,24(sp)
    8000035e:	e852                	sd	s4,16(sp)
    80000360:	e456                	sd	s5,8(sp)
    80000362:	0080                	add	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80000364:	8a92                	mv	s5,tp
    int cpuid = r_tp();
    80000366:	2a81                	sext.w	s5,s5
            kfree((uint64)mem[i], true);
        printf("cpu %d free over\n", cpuid);

    } else {

        while(started == 0);
    80000368:	00001717          	auipc	a4,0x1
    8000036c:	d9070713          	add	a4,a4,-624 # 800010f8 <started>
    if(cpuid == 0) {
    80000370:	0c0a8363          	beqz	s5,80000436 <main+0xe4>
        while(started == 0);
    80000374:	431c                	lw	a5,0(a4)
    80000376:	2781                	sext.w	a5,a5
    80000378:	dff5                	beqz	a5,80000374 <main+0x22>
        __sync_synchronize();
    8000037a:	0ff0000f          	fence
        printf("cpu %d is booting!\n", cpuid);
    8000037e:	85d6                	mv	a1,s5
    80000380:	00001517          	auipc	a0,0x1
    80000384:	cc050513          	add	a0,a0,-832 # 80001040 <_trampoline+0x40>
    80000388:	00000097          	auipc	ra,0x0
    8000038c:	47e080e7          	jalr	1150(ra) # 80000806 <printf>
        
        for(int i = 512; i < 1024; i++) {
    80000390:	00002917          	auipc	s2,0x2
    80000394:	de090913          	add	s2,s2,-544 # 80002170 <mem+0x1000>
    80000398:	00003997          	auipc	s3,0x3
    8000039c:	dd898993          	add	s3,s3,-552 # 80003170 <stack0>
        printf("cpu %d is booting!\n", cpuid);
    800003a0:	84ca                	mv	s1,s2
            mem[i] = kalloc(true);
            memset(mem[i], 1, PGSIZE);
            printf("mem = %p, data = %d\n", mem[i], mem[i][0]);
    800003a2:	00001a17          	auipc	s4,0x1
    800003a6:	cb6a0a13          	add	s4,s4,-842 # 80001058 <_trampoline+0x58>
            mem[i] = kalloc(true);
    800003aa:	4505                	li	a0,1
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	d8e080e7          	jalr	-626(ra) # 8000013a <kalloc>
    800003b4:	e088                	sd	a0,0(s1)
            memset(mem[i], 1, PGSIZE);
    800003b6:	6605                	lui	a2,0x1
    800003b8:	4585                	li	a1,1
    800003ba:	00000097          	auipc	ra,0x0
    800003be:	1ba080e7          	jalr	442(ra) # 80000574 <memset>
            printf("mem = %p, data = %d\n", mem[i], mem[i][0]);
    800003c2:	608c                	ld	a1,0(s1)
    800003c4:	4190                	lw	a2,0(a1)
    800003c6:	8552                	mv	a0,s4
    800003c8:	00000097          	auipc	ra,0x0
    800003cc:	43e080e7          	jalr	1086(ra) # 80000806 <printf>
        for(int i = 512; i < 1024; i++) {
    800003d0:	04a1                	add	s1,s1,8
    800003d2:	fd349ce3          	bne	s1,s3,800003aa <main+0x58>
        }
        printf("cpu %d alloc over\n", cpuid);
    800003d6:	85d6                	mv	a1,s5
    800003d8:	00001517          	auipc	a0,0x1
    800003dc:	c9850513          	add	a0,a0,-872 # 80001070 <_trampoline+0x70>
    800003e0:	00000097          	auipc	ra,0x0
    800003e4:	426080e7          	jalr	1062(ra) # 80000806 <printf>
        over_2 = 1;
    800003e8:	4785                	li	a5,1
    800003ea:	00001717          	auipc	a4,0x1
    800003ee:	d0f72323          	sw	a5,-762(a4) # 800010f0 <over_2>

        while(over_1 == 0 || over_2 == 0);
    800003f2:	00001717          	auipc	a4,0x1
    800003f6:	d0270713          	add	a4,a4,-766 # 800010f4 <over_1>
    800003fa:	00001697          	auipc	a3,0x1
    800003fe:	cf668693          	add	a3,a3,-778 # 800010f0 <over_2>
    80000402:	431c                	lw	a5,0(a4)
    80000404:	2781                	sext.w	a5,a5
    80000406:	dff5                	beqz	a5,80000402 <main+0xb0>
    80000408:	429c                	lw	a5,0(a3)
    8000040a:	2781                	sext.w	a5,a5
    8000040c:	dbfd                	beqz	a5,80000402 <main+0xb0>

        for(int i = 512; i < 1024; i++)
            kfree((uint64)mem[i], true);
    8000040e:	4585                	li	a1,1
    80000410:	00093503          	ld	a0,0(s2)
    80000414:	00000097          	auipc	ra,0x0
    80000418:	c26080e7          	jalr	-986(ra) # 8000003a <kfree>
        for(int i = 512; i < 1024; i++)
    8000041c:	0921                	add	s2,s2,8
    8000041e:	ff3918e3          	bne	s2,s3,8000040e <main+0xbc>
        printf("cpu %d free over\n", cpuid);        
    80000422:	85d6                	mv	a1,s5
    80000424:	00001517          	auipc	a0,0x1
    80000428:	c6450513          	add	a0,a0,-924 # 80001088 <_trampoline+0x88>
    8000042c:	00000097          	auipc	ra,0x0
    80000430:	3da080e7          	jalr	986(ra) # 80000806 <printf>
 
    }
    while (1);    
    80000434:	a001                	j	80000434 <main+0xe2>
        printfinit();
    80000436:	00000097          	auipc	ra,0x0
    8000043a:	5b0080e7          	jalr	1456(ra) # 800009e6 <printfinit>
        kinit();
    8000043e:	00000097          	auipc	ra,0x0
    80000442:	cc0080e7          	jalr	-832(ra) # 800000fe <kinit>
        printf("cpu %d is booting!\n", cpuid);
    80000446:	4581                	li	a1,0
    80000448:	00001517          	auipc	a0,0x1
    8000044c:	bf850513          	add	a0,a0,-1032 # 80001040 <_trampoline+0x40>
    80000450:	00000097          	auipc	ra,0x0
    80000454:	3b6080e7          	jalr	950(ra) # 80000806 <printf>
        __sync_synchronize();
    80000458:	0ff0000f          	fence
        started = 1;
    8000045c:	4785                	li	a5,1
    8000045e:	00001717          	auipc	a4,0x1
    80000462:	c8f72d23          	sw	a5,-870(a4) # 800010f8 <started>
        for(int i = 0; i < 512; i++) {
    80000466:	00001917          	auipc	s2,0x1
    8000046a:	d0a90913          	add	s2,s2,-758 # 80001170 <mem>
    8000046e:	00002997          	auipc	s3,0x2
    80000472:	d0298993          	add	s3,s3,-766 # 80002170 <mem+0x1000>
        started = 1;
    80000476:	84ca                	mv	s1,s2
            printf("mem = %p, data = %d\n", mem[i], mem[i][0]);
    80000478:	00001a17          	auipc	s4,0x1
    8000047c:	be0a0a13          	add	s4,s4,-1056 # 80001058 <_trampoline+0x58>
            mem[i] = kalloc(true);
    80000480:	4505                	li	a0,1
    80000482:	00000097          	auipc	ra,0x0
    80000486:	cb8080e7          	jalr	-840(ra) # 8000013a <kalloc>
    8000048a:	e088                	sd	a0,0(s1)
            memset(mem[i], 1, PGSIZE);
    8000048c:	6605                	lui	a2,0x1
    8000048e:	4585                	li	a1,1
    80000490:	00000097          	auipc	ra,0x0
    80000494:	0e4080e7          	jalr	228(ra) # 80000574 <memset>
            printf("mem = %p, data = %d\n", mem[i], mem[i][0]);
    80000498:	608c                	ld	a1,0(s1)
    8000049a:	4190                	lw	a2,0(a1)
    8000049c:	8552                	mv	a0,s4
    8000049e:	00000097          	auipc	ra,0x0
    800004a2:	368080e7          	jalr	872(ra) # 80000806 <printf>
        for(int i = 0; i < 512; i++) {
    800004a6:	04a1                	add	s1,s1,8
    800004a8:	fd349ce3          	bne	s1,s3,80000480 <main+0x12e>
        printf("cpu %d alloc over\n", cpuid);
    800004ac:	4581                	li	a1,0
    800004ae:	00001517          	auipc	a0,0x1
    800004b2:	bc250513          	add	a0,a0,-1086 # 80001070 <_trampoline+0x70>
    800004b6:	00000097          	auipc	ra,0x0
    800004ba:	350080e7          	jalr	848(ra) # 80000806 <printf>
        over_1 = 1;
    800004be:	4785                	li	a5,1
    800004c0:	00001717          	auipc	a4,0x1
    800004c4:	c2f72a23          	sw	a5,-972(a4) # 800010f4 <over_1>
        while(over_1 == 0 || over_2 == 0);
    800004c8:	00001717          	auipc	a4,0x1
    800004cc:	c2c70713          	add	a4,a4,-980 # 800010f4 <over_1>
    800004d0:	00001697          	auipc	a3,0x1
    800004d4:	c2068693          	add	a3,a3,-992 # 800010f0 <over_2>
    800004d8:	431c                	lw	a5,0(a4)
    800004da:	2781                	sext.w	a5,a5
    800004dc:	dff5                	beqz	a5,800004d8 <main+0x186>
    800004de:	429c                	lw	a5,0(a3)
    800004e0:	2781                	sext.w	a5,a5
    800004e2:	dbfd                	beqz	a5,800004d8 <main+0x186>
            kfree((uint64)mem[i], true);
    800004e4:	4585                	li	a1,1
    800004e6:	00093503          	ld	a0,0(s2)
    800004ea:	00000097          	auipc	ra,0x0
    800004ee:	b50080e7          	jalr	-1200(ra) # 8000003a <kfree>
        for(int i = 0; i < 512; i++)
    800004f2:	0921                	add	s2,s2,8
    800004f4:	ff3918e3          	bne	s2,s3,800004e4 <main+0x192>
        printf("cpu %d free over\n", cpuid);
    800004f8:	4581                	li	a1,0
    800004fa:	00001517          	auipc	a0,0x1
    800004fe:	b8e50513          	add	a0,a0,-1138 # 80001088 <_trampoline+0x88>
    80000502:	00000097          	auipc	ra,0x0
    80000506:	304080e7          	jalr	772(ra) # 80000806 <printf>
    8000050a:	b72d                	j	80000434 <main+0xe2>

000000008000050c <start>:
void main();
void timerinit();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

void start() {
    8000050c:	1141                	add	sp,sp,-16
    8000050e:	e422                	sd	s0,8(sp)
    80000510:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000512:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    80000516:	7779                	lui	a4,0xffffe
    80000518:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fff3637>
    8000051c:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    8000051e:	6705                	lui	a4,0x1
    80000520:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80000524:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000526:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    8000052a:	00000797          	auipc	a5,0x0
    8000052e:	e2878793          	add	a5,a5,-472 # 80000352 <main>
    80000532:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80000536:	4781                	li	a5,0
    80000538:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    8000053c:	67c1                	lui	a5,0x10
    8000053e:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000540:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000544:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000548:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    8000054c:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000550:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    80000554:	57fd                	li	a5,-1
    80000556:	83a9                	srl	a5,a5,0xa
    80000558:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    8000055c:	47bd                	li	a5,15
    8000055e:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000562:	f14027f3          	csrr	a5,mhartid
//   timerinit();

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    80000566:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    80000568:	823e                	mv	tp,a5
  
  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    8000056a:	30200073          	mret
}
    8000056e:	6422                	ld	s0,8(sp)
    80000570:	0141                	add	sp,sp,16
    80000572:	8082                	ret

0000000080000574 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000574:	1141                	add	sp,sp,-16
    80000576:	e422                	sd	s0,8(sp)
    80000578:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    8000057a:	ca19                	beqz	a2,80000590 <memset+0x1c>
    8000057c:	87aa                	mv	a5,a0
    8000057e:	1602                	sll	a2,a2,0x20
    80000580:	9201                	srl	a2,a2,0x20
    80000582:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000586:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    8000058a:	0785                	add	a5,a5,1
    8000058c:	fee79de3          	bne	a5,a4,80000586 <memset+0x12>
  }
  return dst;
}
    80000590:	6422                	ld	s0,8(sp)
    80000592:	0141                	add	sp,sp,16
    80000594:	8082                	ret

0000000080000596 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000596:	1141                	add	sp,sp,-16
    80000598:	e422                	sd	s0,8(sp)
    8000059a:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    8000059c:	ca05                	beqz	a2,800005cc <memcmp+0x36>
    8000059e:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    800005a2:	1682                	sll	a3,a3,0x20
    800005a4:	9281                	srl	a3,a3,0x20
    800005a6:	0685                	add	a3,a3,1
    800005a8:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    800005aa:	00054783          	lbu	a5,0(a0)
    800005ae:	0005c703          	lbu	a4,0(a1)
    800005b2:	00e79863          	bne	a5,a4,800005c2 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    800005b6:	0505                	add	a0,a0,1
    800005b8:	0585                	add	a1,a1,1
  while(n-- > 0){
    800005ba:	fed518e3          	bne	a0,a3,800005aa <memcmp+0x14>
  }

  return 0;
    800005be:	4501                	li	a0,0
    800005c0:	a019                	j	800005c6 <memcmp+0x30>
      return *s1 - *s2;
    800005c2:	40e7853b          	subw	a0,a5,a4
}
    800005c6:	6422                	ld	s0,8(sp)
    800005c8:	0141                	add	sp,sp,16
    800005ca:	8082                	ret
  return 0;
    800005cc:	4501                	li	a0,0
    800005ce:	bfe5                	j	800005c6 <memcmp+0x30>

00000000800005d0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800005d0:	1141                	add	sp,sp,-16
    800005d2:	e422                	sd	s0,8(sp)
    800005d4:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    800005d6:	c205                	beqz	a2,800005f6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    800005d8:	02a5e263          	bltu	a1,a0,800005fc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800005dc:	1602                	sll	a2,a2,0x20
    800005de:	9201                	srl	a2,a2,0x20
    800005e0:	00c587b3          	add	a5,a1,a2
{
    800005e4:	872a                	mv	a4,a0
      *d++ = *s++;
    800005e6:	0585                	add	a1,a1,1
    800005e8:	0705                	add	a4,a4,1
    800005ea:	fff5c683          	lbu	a3,-1(a1)
    800005ee:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800005f2:	fef59ae3          	bne	a1,a5,800005e6 <memmove+0x16>

  return dst;
}
    800005f6:	6422                	ld	s0,8(sp)
    800005f8:	0141                	add	sp,sp,16
    800005fa:	8082                	ret
  if(s < d && s + n > d){
    800005fc:	02061693          	sll	a3,a2,0x20
    80000600:	9281                	srl	a3,a3,0x20
    80000602:	00d58733          	add	a4,a1,a3
    80000606:	fce57be3          	bgeu	a0,a4,800005dc <memmove+0xc>
    d += n;
    8000060a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    8000060c:	fff6079b          	addw	a5,a2,-1
    80000610:	1782                	sll	a5,a5,0x20
    80000612:	9381                	srl	a5,a5,0x20
    80000614:	fff7c793          	not	a5,a5
    80000618:	97ba                	add	a5,a5,a4
      *--d = *--s;
    8000061a:	177d                	add	a4,a4,-1
    8000061c:	16fd                	add	a3,a3,-1
    8000061e:	00074603          	lbu	a2,0(a4)
    80000622:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000626:	fee79ae3          	bne	a5,a4,8000061a <memmove+0x4a>
    8000062a:	b7f1                	j	800005f6 <memmove+0x26>

000000008000062c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000062c:	1141                	add	sp,sp,-16
    8000062e:	e406                	sd	ra,8(sp)
    80000630:	e022                	sd	s0,0(sp)
    80000632:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000634:	00000097          	auipc	ra,0x0
    80000638:	f9c080e7          	jalr	-100(ra) # 800005d0 <memmove>
}
    8000063c:	60a2                	ld	ra,8(sp)
    8000063e:	6402                	ld	s0,0(sp)
    80000640:	0141                	add	sp,sp,16
    80000642:	8082                	ret

0000000080000644 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000644:	1141                	add	sp,sp,-16
    80000646:	e422                	sd	s0,8(sp)
    80000648:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000064a:	ce11                	beqz	a2,80000666 <strncmp+0x22>
    8000064c:	00054783          	lbu	a5,0(a0)
    80000650:	cf89                	beqz	a5,8000066a <strncmp+0x26>
    80000652:	0005c703          	lbu	a4,0(a1)
    80000656:	00f71a63          	bne	a4,a5,8000066a <strncmp+0x26>
    n--, p++, q++;
    8000065a:	367d                	addw	a2,a2,-1
    8000065c:	0505                	add	a0,a0,1
    8000065e:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000660:	f675                	bnez	a2,8000064c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000662:	4501                	li	a0,0
    80000664:	a809                	j	80000676 <strncmp+0x32>
    80000666:	4501                	li	a0,0
    80000668:	a039                	j	80000676 <strncmp+0x32>
  if(n == 0)
    8000066a:	ca09                	beqz	a2,8000067c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000066c:	00054503          	lbu	a0,0(a0)
    80000670:	0005c783          	lbu	a5,0(a1)
    80000674:	9d1d                	subw	a0,a0,a5
}
    80000676:	6422                	ld	s0,8(sp)
    80000678:	0141                	add	sp,sp,16
    8000067a:	8082                	ret
    return 0;
    8000067c:	4501                	li	a0,0
    8000067e:	bfe5                	j	80000676 <strncmp+0x32>

0000000080000680 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000680:	1141                	add	sp,sp,-16
    80000682:	e422                	sd	s0,8(sp)
    80000684:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000686:	87aa                	mv	a5,a0
    80000688:	86b2                	mv	a3,a2
    8000068a:	367d                	addw	a2,a2,-1
    8000068c:	00d05963          	blez	a3,8000069e <strncpy+0x1e>
    80000690:	0785                	add	a5,a5,1
    80000692:	0005c703          	lbu	a4,0(a1)
    80000696:	fee78fa3          	sb	a4,-1(a5)
    8000069a:	0585                	add	a1,a1,1
    8000069c:	f775                	bnez	a4,80000688 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000069e:	873e                	mv	a4,a5
    800006a0:	9fb5                	addw	a5,a5,a3
    800006a2:	37fd                	addw	a5,a5,-1
    800006a4:	00c05963          	blez	a2,800006b6 <strncpy+0x36>
    *s++ = 0;
    800006a8:	0705                	add	a4,a4,1
    800006aa:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    800006ae:	40e786bb          	subw	a3,a5,a4
    800006b2:	fed04be3          	bgtz	a3,800006a8 <strncpy+0x28>
  return os;
}
    800006b6:	6422                	ld	s0,8(sp)
    800006b8:	0141                	add	sp,sp,16
    800006ba:	8082                	ret

00000000800006bc <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800006bc:	1141                	add	sp,sp,-16
    800006be:	e422                	sd	s0,8(sp)
    800006c0:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800006c2:	02c05363          	blez	a2,800006e8 <safestrcpy+0x2c>
    800006c6:	fff6069b          	addw	a3,a2,-1
    800006ca:	1682                	sll	a3,a3,0x20
    800006cc:	9281                	srl	a3,a3,0x20
    800006ce:	96ae                	add	a3,a3,a1
    800006d0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800006d2:	00d58963          	beq	a1,a3,800006e4 <safestrcpy+0x28>
    800006d6:	0585                	add	a1,a1,1
    800006d8:	0785                	add	a5,a5,1
    800006da:	fff5c703          	lbu	a4,-1(a1)
    800006de:	fee78fa3          	sb	a4,-1(a5)
    800006e2:	fb65                	bnez	a4,800006d2 <safestrcpy+0x16>
    ;
  *s = 0;
    800006e4:	00078023          	sb	zero,0(a5)
  return os;
}
    800006e8:	6422                	ld	s0,8(sp)
    800006ea:	0141                	add	sp,sp,16
    800006ec:	8082                	ret

00000000800006ee <strlen>:

int
strlen(const char *s)
{
    800006ee:	1141                	add	sp,sp,-16
    800006f0:	e422                	sd	s0,8(sp)
    800006f2:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800006f4:	00054783          	lbu	a5,0(a0)
    800006f8:	cf91                	beqz	a5,80000714 <strlen+0x26>
    800006fa:	0505                	add	a0,a0,1
    800006fc:	87aa                	mv	a5,a0
    800006fe:	86be                	mv	a3,a5
    80000700:	0785                	add	a5,a5,1
    80000702:	fff7c703          	lbu	a4,-1(a5)
    80000706:	ff65                	bnez	a4,800006fe <strlen+0x10>
    80000708:	40a6853b          	subw	a0,a3,a0
    8000070c:	2505                	addw	a0,a0,1
    ;
  return n;
}
    8000070e:	6422                	ld	s0,8(sp)
    80000710:	0141                	add	sp,sp,16
    80000712:	8082                	ret
  for(n = 0; s[n]; n++)
    80000714:	4501                	li	a0,0
    80000716:	bfe5                	j	8000070e <strlen+0x20>

0000000080000718 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000718:	7179                	add	sp,sp,-48
    8000071a:	f406                	sd	ra,40(sp)
    8000071c:	f022                	sd	s0,32(sp)
    8000071e:	ec26                	sd	s1,24(sp)
    80000720:	e84a                	sd	s2,16(sp)
    80000722:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000724:	c219                	beqz	a2,8000072a <printint+0x12>
    80000726:	08054763          	bltz	a0,800007b4 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    8000072a:	2501                	sext.w	a0,a0
    8000072c:	4881                	li	a7,0
    8000072e:	fd040693          	add	a3,s0,-48

  i = 0;
    80000732:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000734:	2581                	sext.w	a1,a1
    80000736:	00001617          	auipc	a2,0x1
    8000073a:	99260613          	add	a2,a2,-1646 # 800010c8 <digits>
    8000073e:	883a                	mv	a6,a4
    80000740:	2705                	addw	a4,a4,1
    80000742:	02b577bb          	remuw	a5,a0,a1
    80000746:	1782                	sll	a5,a5,0x20
    80000748:	9381                	srl	a5,a5,0x20
    8000074a:	97b2                	add	a5,a5,a2
    8000074c:	0007c783          	lbu	a5,0(a5)
    80000750:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000754:	0005079b          	sext.w	a5,a0
    80000758:	02b5553b          	divuw	a0,a0,a1
    8000075c:	0685                	add	a3,a3,1
    8000075e:	feb7f0e3          	bgeu	a5,a1,8000073e <printint+0x26>

  if(sign)
    80000762:	00088c63          	beqz	a7,8000077a <printint+0x62>
    buf[i++] = '-';
    80000766:	fe070793          	add	a5,a4,-32
    8000076a:	00878733          	add	a4,a5,s0
    8000076e:	02d00793          	li	a5,45
    80000772:	fef70823          	sb	a5,-16(a4)
    80000776:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    8000077a:	02e05763          	blez	a4,800007a8 <printint+0x90>
    8000077e:	fd040793          	add	a5,s0,-48
    80000782:	00e784b3          	add	s1,a5,a4
    80000786:	fff78913          	add	s2,a5,-1
    8000078a:	993a                	add	s2,s2,a4
    8000078c:	377d                	addw	a4,a4,-1
    8000078e:	1702                	sll	a4,a4,0x20
    80000790:	9301                	srl	a4,a4,0x20
    80000792:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000796:	fff4c503          	lbu	a0,-1(s1)
    8000079a:	00000097          	auipc	ra,0x0
    8000079e:	38c080e7          	jalr	908(ra) # 80000b26 <consputc>
  while(--i >= 0)
    800007a2:	14fd                	add	s1,s1,-1
    800007a4:	ff2499e3          	bne	s1,s2,80000796 <printint+0x7e>
}
    800007a8:	70a2                	ld	ra,40(sp)
    800007aa:	7402                	ld	s0,32(sp)
    800007ac:	64e2                	ld	s1,24(sp)
    800007ae:	6942                	ld	s2,16(sp)
    800007b0:	6145                	add	sp,sp,48
    800007b2:	8082                	ret
    x = -xx;
    800007b4:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    800007b8:	4885                	li	a7,1
    x = -xx;
    800007ba:	bf95                	j	8000072e <printint+0x16>

00000000800007bc <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    800007bc:	1101                	add	sp,sp,-32
    800007be:	ec06                	sd	ra,24(sp)
    800007c0:	e822                	sd	s0,16(sp)
    800007c2:	e426                	sd	s1,8(sp)
    800007c4:	1000                	add	s0,sp,32
    800007c6:	84aa                	mv	s1,a0
  pr.locking = 0;
    800007c8:	0000b797          	auipc	a5,0xb
    800007cc:	9c07a023          	sw	zero,-1600(a5) # 8000b188 <pr+0x18>
  printf("panic: ");
    800007d0:	00001517          	auipc	a0,0x1
    800007d4:	8d050513          	add	a0,a0,-1840 # 800010a0 <_trampoline+0xa0>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	02e080e7          	jalr	46(ra) # 80000806 <printf>
  printf(s);
    800007e0:	8526                	mv	a0,s1
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	024080e7          	jalr	36(ra) # 80000806 <printf>
  printf("\n");
    800007ea:	00001517          	auipc	a0,0x1
    800007ee:	8ae50513          	add	a0,a0,-1874 # 80001098 <_trampoline+0x98>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	014080e7          	jalr	20(ra) # 80000806 <printf>
  panicked = 1; // freeze uart output from other CPUs
    800007fa:	4785                	li	a5,1
    800007fc:	00001717          	auipc	a4,0x1
    80000800:	90f72023          	sw	a5,-1792(a4) # 800010fc <panicked>
  for(;;)
    80000804:	a001                	j	80000804 <panic+0x48>

0000000080000806 <printf>:
{
    80000806:	7131                	add	sp,sp,-192
    80000808:	fc86                	sd	ra,120(sp)
    8000080a:	f8a2                	sd	s0,112(sp)
    8000080c:	f4a6                	sd	s1,104(sp)
    8000080e:	f0ca                	sd	s2,96(sp)
    80000810:	ecce                	sd	s3,88(sp)
    80000812:	e8d2                	sd	s4,80(sp)
    80000814:	e4d6                	sd	s5,72(sp)
    80000816:	e0da                	sd	s6,64(sp)
    80000818:	fc5e                	sd	s7,56(sp)
    8000081a:	f862                	sd	s8,48(sp)
    8000081c:	f466                	sd	s9,40(sp)
    8000081e:	f06a                	sd	s10,32(sp)
    80000820:	ec6e                	sd	s11,24(sp)
    80000822:	0100                	add	s0,sp,128
    80000824:	8a2a                	mv	s4,a0
    80000826:	e40c                	sd	a1,8(s0)
    80000828:	e810                	sd	a2,16(s0)
    8000082a:	ec14                	sd	a3,24(s0)
    8000082c:	f018                	sd	a4,32(s0)
    8000082e:	f41c                	sd	a5,40(s0)
    80000830:	03043823          	sd	a6,48(s0)
    80000834:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000838:	0000bd97          	auipc	s11,0xb
    8000083c:	950dad83          	lw	s11,-1712(s11) # 8000b188 <pr+0x18>
  if(locking)
    80000840:	020d9b63          	bnez	s11,80000876 <printf+0x70>
  if (fmt == 0)
    80000844:	040a0263          	beqz	s4,80000888 <printf+0x82>
  va_start(ap, fmt);
    80000848:	00840793          	add	a5,s0,8
    8000084c:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000850:	000a4503          	lbu	a0,0(s4)
    80000854:	14050f63          	beqz	a0,800009b2 <printf+0x1ac>
    80000858:	4981                	li	s3,0
    if(c != '%'){
    8000085a:	02500a93          	li	s5,37
    switch(c){
    8000085e:	07000b93          	li	s7,112
  consputc('x');
    80000862:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000864:	00001b17          	auipc	s6,0x1
    80000868:	864b0b13          	add	s6,s6,-1948 # 800010c8 <digits>
    switch(c){
    8000086c:	07300c93          	li	s9,115
    80000870:	06400c13          	li	s8,100
    80000874:	a82d                	j	800008ae <printf+0xa8>
    acquire(&pr.lock);
    80000876:	0000b517          	auipc	a0,0xb
    8000087a:	8fa50513          	add	a0,a0,-1798 # 8000b170 <pr>
    8000087e:	00000097          	auipc	ra,0x0
    80000882:	9d8080e7          	jalr	-1576(ra) # 80000256 <acquire>
    80000886:	bf7d                	j	80000844 <printf+0x3e>
    panic("null fmt");
    80000888:	00001517          	auipc	a0,0x1
    8000088c:	82850513          	add	a0,a0,-2008 # 800010b0 <_trampoline+0xb0>
    80000890:	00000097          	auipc	ra,0x0
    80000894:	f2c080e7          	jalr	-212(ra) # 800007bc <panic>
      consputc(c);
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	28e080e7          	jalr	654(ra) # 80000b26 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800008a0:	2985                	addw	s3,s3,1
    800008a2:	013a07b3          	add	a5,s4,s3
    800008a6:	0007c503          	lbu	a0,0(a5)
    800008aa:	10050463          	beqz	a0,800009b2 <printf+0x1ac>
    if(c != '%'){
    800008ae:	ff5515e3          	bne	a0,s5,80000898 <printf+0x92>
    c = fmt[++i] & 0xff;
    800008b2:	2985                	addw	s3,s3,1
    800008b4:	013a07b3          	add	a5,s4,s3
    800008b8:	0007c783          	lbu	a5,0(a5)
    800008bc:	0007849b          	sext.w	s1,a5
    if(c == 0)
    800008c0:	cbed                	beqz	a5,800009b2 <printf+0x1ac>
    switch(c){
    800008c2:	05778a63          	beq	a5,s7,80000916 <printf+0x110>
    800008c6:	02fbf663          	bgeu	s7,a5,800008f2 <printf+0xec>
    800008ca:	09978863          	beq	a5,s9,8000095a <printf+0x154>
    800008ce:	07800713          	li	a4,120
    800008d2:	0ce79563          	bne	a5,a4,8000099c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    800008d6:	f8843783          	ld	a5,-120(s0)
    800008da:	00878713          	add	a4,a5,8
    800008de:	f8e43423          	sd	a4,-120(s0)
    800008e2:	4605                	li	a2,1
    800008e4:	85ea                	mv	a1,s10
    800008e6:	4388                	lw	a0,0(a5)
    800008e8:	00000097          	auipc	ra,0x0
    800008ec:	e30080e7          	jalr	-464(ra) # 80000718 <printint>
      break;
    800008f0:	bf45                	j	800008a0 <printf+0x9a>
    switch(c){
    800008f2:	09578f63          	beq	a5,s5,80000990 <printf+0x18a>
    800008f6:	0b879363          	bne	a5,s8,8000099c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    800008fa:	f8843783          	ld	a5,-120(s0)
    800008fe:	00878713          	add	a4,a5,8
    80000902:	f8e43423          	sd	a4,-120(s0)
    80000906:	4605                	li	a2,1
    80000908:	45a9                	li	a1,10
    8000090a:	4388                	lw	a0,0(a5)
    8000090c:	00000097          	auipc	ra,0x0
    80000910:	e0c080e7          	jalr	-500(ra) # 80000718 <printint>
      break;
    80000914:	b771                	j	800008a0 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000916:	f8843783          	ld	a5,-120(s0)
    8000091a:	00878713          	add	a4,a5,8
    8000091e:	f8e43423          	sd	a4,-120(s0)
    80000922:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000926:	03000513          	li	a0,48
    8000092a:	00000097          	auipc	ra,0x0
    8000092e:	1fc080e7          	jalr	508(ra) # 80000b26 <consputc>
  consputc('x');
    80000932:	07800513          	li	a0,120
    80000936:	00000097          	auipc	ra,0x0
    8000093a:	1f0080e7          	jalr	496(ra) # 80000b26 <consputc>
    8000093e:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000940:	03c95793          	srl	a5,s2,0x3c
    80000944:	97da                	add	a5,a5,s6
    80000946:	0007c503          	lbu	a0,0(a5)
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	1dc080e7          	jalr	476(ra) # 80000b26 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000952:	0912                	sll	s2,s2,0x4
    80000954:	34fd                	addw	s1,s1,-1
    80000956:	f4ed                	bnez	s1,80000940 <printf+0x13a>
    80000958:	b7a1                	j	800008a0 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    8000095a:	f8843783          	ld	a5,-120(s0)
    8000095e:	00878713          	add	a4,a5,8
    80000962:	f8e43423          	sd	a4,-120(s0)
    80000966:	6384                	ld	s1,0(a5)
    80000968:	cc89                	beqz	s1,80000982 <printf+0x17c>
      for(; *s; s++)
    8000096a:	0004c503          	lbu	a0,0(s1)
    8000096e:	d90d                	beqz	a0,800008a0 <printf+0x9a>
        consputc(*s);
    80000970:	00000097          	auipc	ra,0x0
    80000974:	1b6080e7          	jalr	438(ra) # 80000b26 <consputc>
      for(; *s; s++)
    80000978:	0485                	add	s1,s1,1
    8000097a:	0004c503          	lbu	a0,0(s1)
    8000097e:	f96d                	bnez	a0,80000970 <printf+0x16a>
    80000980:	b705                	j	800008a0 <printf+0x9a>
        s = "(null)";
    80000982:	00000497          	auipc	s1,0x0
    80000986:	72648493          	add	s1,s1,1830 # 800010a8 <_trampoline+0xa8>
      for(; *s; s++)
    8000098a:	02800513          	li	a0,40
    8000098e:	b7cd                	j	80000970 <printf+0x16a>
      consputc('%');
    80000990:	8556                	mv	a0,s5
    80000992:	00000097          	auipc	ra,0x0
    80000996:	194080e7          	jalr	404(ra) # 80000b26 <consputc>
      break;
    8000099a:	b719                	j	800008a0 <printf+0x9a>
      consputc('%');
    8000099c:	8556                	mv	a0,s5
    8000099e:	00000097          	auipc	ra,0x0
    800009a2:	188080e7          	jalr	392(ra) # 80000b26 <consputc>
      consputc(c);
    800009a6:	8526                	mv	a0,s1
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	17e080e7          	jalr	382(ra) # 80000b26 <consputc>
      break;
    800009b0:	bdc5                	j	800008a0 <printf+0x9a>
  if(locking)
    800009b2:	020d9163          	bnez	s11,800009d4 <printf+0x1ce>
}
    800009b6:	70e6                	ld	ra,120(sp)
    800009b8:	7446                	ld	s0,112(sp)
    800009ba:	74a6                	ld	s1,104(sp)
    800009bc:	7906                	ld	s2,96(sp)
    800009be:	69e6                	ld	s3,88(sp)
    800009c0:	6a46                	ld	s4,80(sp)
    800009c2:	6aa6                	ld	s5,72(sp)
    800009c4:	6b06                	ld	s6,64(sp)
    800009c6:	7be2                	ld	s7,56(sp)
    800009c8:	7c42                	ld	s8,48(sp)
    800009ca:	7ca2                	ld	s9,40(sp)
    800009cc:	7d02                	ld	s10,32(sp)
    800009ce:	6de2                	ld	s11,24(sp)
    800009d0:	6129                	add	sp,sp,192
    800009d2:	8082                	ret
    release(&pr.lock);
    800009d4:	0000a517          	auipc	a0,0xa
    800009d8:	79c50513          	add	a0,a0,1948 # 8000b170 <pr>
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	92e080e7          	jalr	-1746(ra) # 8000030a <release>
}
    800009e4:	bfc9                	j	800009b6 <printf+0x1b0>

00000000800009e6 <printfinit>:
    ;
}

void
printfinit(void)
{
    800009e6:	1101                	add	sp,sp,-32
    800009e8:	ec06                	sd	ra,24(sp)
    800009ea:	e822                	sd	s0,16(sp)
    800009ec:	e426                	sd	s1,8(sp)
    800009ee:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    800009f0:	0000a497          	auipc	s1,0xa
    800009f4:	78048493          	add	s1,s1,1920 # 8000b170 <pr>
    800009f8:	00000597          	auipc	a1,0x0
    800009fc:	6c858593          	add	a1,a1,1736 # 800010c0 <_trampoline+0xc0>
    80000a00:	8526                	mv	a0,s1
    80000a02:	fffff097          	auipc	ra,0xfffff
    80000a06:	7c4080e7          	jalr	1988(ra) # 800001c6 <initlock>
  pr.locking = 1;
    80000a0a:	4785                	li	a5,1
    80000a0c:	cc9c                	sw	a5,24(s1)
}
    80000a0e:	60e2                	ld	ra,24(sp)
    80000a10:	6442                	ld	s0,16(sp)
    80000a12:	64a2                	ld	s1,8(sp)
    80000a14:	6105                	add	sp,sp,32
    80000a16:	8082                	ret

0000000080000a18 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000a18:	1141                	add	sp,sp,-16
    80000a1a:	e406                	sd	ra,8(sp)
    80000a1c:	e022                	sd	s0,0(sp)
    80000a1e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000a20:	100007b7          	lui	a5,0x10000
    80000a24:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000a28:	f8000713          	li	a4,-128
    80000a2c:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000a30:	470d                	li	a4,3
    80000a32:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000a36:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000a3a:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000a3e:	469d                	li	a3,7
    80000a40:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000a44:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000a48:	00000597          	auipc	a1,0x0
    80000a4c:	69858593          	add	a1,a1,1688 # 800010e0 <digits+0x18>
    80000a50:	0000a517          	auipc	a0,0xa
    80000a54:	74050513          	add	a0,a0,1856 # 8000b190 <uart_tx_lock>
    80000a58:	fffff097          	auipc	ra,0xfffff
    80000a5c:	76e080e7          	jalr	1902(ra) # 800001c6 <initlock>
}
    80000a60:	60a2                	ld	ra,8(sp)
    80000a62:	6402                	ld	s0,0(sp)
    80000a64:	0141                	add	sp,sp,16
    80000a66:	8082                	ret

0000000080000a68 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000a68:	1101                	add	sp,sp,-32
    80000a6a:	ec06                	sd	ra,24(sp)
    80000a6c:	e822                	sd	s0,16(sp)
    80000a6e:	e426                	sd	s1,8(sp)
    80000a70:	1000                	add	s0,sp,32
    80000a72:	84aa                	mv	s1,a0
  push_off();
    80000a74:	fffff097          	auipc	ra,0xfffff
    80000a78:	796080e7          	jalr	1942(ra) # 8000020a <push_off>

  if(panicked){
    80000a7c:	00000797          	auipc	a5,0x0
    80000a80:	6807a783          	lw	a5,1664(a5) # 800010fc <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000a84:	10000737          	lui	a4,0x10000
  if(panicked){
    80000a88:	c391                	beqz	a5,80000a8c <uartputc_sync+0x24>
    for(;;)
    80000a8a:	a001                	j	80000a8a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000a8c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000a90:	0207f793          	and	a5,a5,32
    80000a94:	dfe5                	beqz	a5,80000a8c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000a96:	0ff4f513          	zext.b	a0,s1
    80000a9a:	100007b7          	lui	a5,0x10000
    80000a9e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000aa2:	00000097          	auipc	ra,0x0
    80000aa6:	808080e7          	jalr	-2040(ra) # 800002aa <pop_off>
}
    80000aaa:	60e2                	ld	ra,24(sp)
    80000aac:	6442                	ld	s0,16(sp)
    80000aae:	64a2                	ld	s1,8(sp)
    80000ab0:	6105                	add	sp,sp,32
    80000ab2:	8082                	ret

0000000080000ab4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000ab4:	1141                	add	sp,sp,-16
    80000ab6:	e422                	sd	s0,8(sp)
    80000ab8:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000aba:	100007b7          	lui	a5,0x10000
    80000abe:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000ac2:	8b85                	and	a5,a5,1
    80000ac4:	cb81                	beqz	a5,80000ad4 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000ac6:	100007b7          	lui	a5,0x10000
    80000aca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000ace:	6422                	ld	s0,8(sp)
    80000ad0:	0141                	add	sp,sp,16
    80000ad2:	8082                	ret
    return -1;
    80000ad4:	557d                	li	a0,-1
    80000ad6:	bfe5                	j	80000ace <uartgetc+0x1a>

0000000080000ad8 <uart_putc>:
//   uartstart();
//   release(&uart_tx_lock);
// }


void uart_putc(char c) {
    80000ad8:	1141                	add	sp,sp,-16
    80000ada:	e422                	sd	s0,8(sp)
    80000adc:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    80000ade:	10000737          	lui	a4,0x10000
    80000ae2:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000ae6:	0207f793          	and	a5,a5,32
    80000aea:	dfe5                	beqz	a5,80000ae2 <uart_putc+0xa>
    uart[0] = c;
    80000aec:	100007b7          	lui	a5,0x10000
    80000af0:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    80000af4:	6422                	ld	s0,8(sp)
    80000af6:	0141                	add	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <uart_puts>:

void uart_puts(char *s) {
    80000afa:	1101                	add	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	add	s0,sp,32
    80000b04:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000b06:	00054503          	lbu	a0,0(a0)
    80000b0a:	c909                	beqz	a0,80000b1c <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	fcc080e7          	jalr	-52(ra) # 80000ad8 <uart_putc>
        s++;              // 移动到下一个字符
    80000b14:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000b16:	0004c503          	lbu	a0,0(s1)
    80000b1a:	f96d                	bnez	a0,80000b0c <uart_puts+0x12>
    }
}
    80000b1c:	60e2                	ld	ra,24(sp)
    80000b1e:	6442                	ld	s0,16(sp)
    80000b20:	64a2                	ld	s1,8(sp)
    80000b22:	6105                	add	sp,sp,32
    80000b24:	8082                	ret

0000000080000b26 <consputc>:
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    80000b26:	1141                	add	sp,sp,-16
    80000b28:	e406                	sd	ra,8(sp)
    80000b2a:	e022                	sd	s0,0(sp)
    80000b2c:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000b2e:	10000793          	li	a5,256
    80000b32:	00f50a63          	beq	a0,a5,80000b46 <consputc+0x20>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	f32080e7          	jalr	-206(ra) # 80000a68 <uartputc_sync>
  }
}
    80000b3e:	60a2                	ld	ra,8(sp)
    80000b40:	6402                	ld	s0,0(sp)
    80000b42:	0141                	add	sp,sp,16
    80000b44:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000b46:	4521                	li	a0,8
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f20080e7          	jalr	-224(ra) # 80000a68 <uartputc_sync>
    80000b50:	02000513          	li	a0,32
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	f14080e7          	jalr	-236(ra) # 80000a68 <uartputc_sync>
    80000b5c:	4521                	li	a0,8
    80000b5e:	00000097          	auipc	ra,0x0
    80000b62:	f0a080e7          	jalr	-246(ra) # 80000a68 <uartputc_sync>
    80000b66:	bfe1                	j	80000b3e <consputc+0x18>
	...
