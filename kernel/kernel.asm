
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
    80000004:	2e010113          	add	sp,sp,736 # 800032e0 <stack0>
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
    80000016:	00003517          	auipc	a0,0x3
    8000001a:	22a50513          	add	a0,a0,554 # 80003240 <kernel_pagetable>
    la a1, end
    8000001e:	0000b597          	auipc	a1,0xb
    80000022:	3c258593          	add	a1,a1,962 # 8000b3e0 <end>

0000000080000026 <bss_loop>:
bss_loop:
    sw zero, (a0)
    80000026:	00052023          	sw	zero,0(a0)
    addi a0, a0, 4
    8000002a:	0511                	add	a0,a0,4
    blt a0, a1, bss_loop
    8000002c:	feb54de3          	blt	a0,a1,80000026 <bss_loop>

    call start            # 跳转到 C 代码
    80000030:	00001097          	auipc	ra,0x1
    80000034:	948080e7          	jalr	-1720(ra) # 80000978 <start>

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
    80000052:	39278793          	add	a5,a5,914 # 8000b3e0 <end>
    80000056:	04f56563          	bltu	a0,a5,800000a0 <kfree+0x66>
    8000005a:	47c5                	li	a5,17
    8000005c:	07ee                	sll	a5,a5,0x1b
    8000005e:	04f57163          	bgeu	a0,a5,800000a0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset((char*)page, 1, PGSIZE); 
    80000062:	6605                	lui	a2,0x1
    80000064:	4585                	li	a1,1
    80000066:	00001097          	auipc	ra,0x1
    8000006a:	97a080e7          	jalr	-1670(ra) # 800009e0 <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    8000006e:	00003917          	auipc	s2,0x3
    80000072:	1f290913          	add	s2,s2,498 # 80003260 <kmem>
    80000076:	854a                	mv	a0,s2
    80000078:	00000097          	auipc	ra,0x0
    8000007c:	5fe080e7          	jalr	1534(ra) # 80000676 <acquire>
  r->next = kmem.freelist;  //头插
    80000080:	01893783          	ld	a5,24(s2)
    80000084:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000086:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    8000008a:	854a                	mv	a0,s2
    8000008c:	00000097          	auipc	ra,0x0
    80000090:	69e080e7          	jalr	1694(ra) # 8000072a <release>
}
    80000094:	60e2                	ld	ra,24(sp)
    80000096:	6442                	ld	s0,16(sp)
    80000098:	64a2                	ld	s1,8(sp)
    8000009a:	6902                	ld	s2,0(sp)
    8000009c:	6105                	add	sp,sp,32
    8000009e:	8082                	ret
    panic("kfree");
    800000a0:	00003517          	auipc	a0,0x3
    800000a4:	f6050513          	add	a0,a0,-160 # 80003000 <etext>
    800000a8:	00001097          	auipc	ra,0x1
    800000ac:	b80080e7          	jalr	-1152(ra) # 80000c28 <panic>

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
    80000106:	00003597          	auipc	a1,0x3
    8000010a:	f0258593          	add	a1,a1,-254 # 80003008 <etext+0x8>
    8000010e:	00003517          	auipc	a0,0x3
    80000112:	15250513          	add	a0,a0,338 # 80003260 <kmem>
    80000116:	00000097          	auipc	ra,0x0
    8000011a:	4d0080e7          	jalr	1232(ra) # 800005e6 <initlock>
  freerange(end, (void*)PHYSTOP);
    8000011e:	45c5                	li	a1,17
    80000120:	05ee                	sll	a1,a1,0x1b
    80000122:	0000b517          	auipc	a0,0xb
    80000126:	2be50513          	add	a0,a0,702 # 8000b3e0 <end>
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
    80000144:	00003497          	auipc	s1,0x3
    80000148:	11c48493          	add	s1,s1,284 # 80003260 <kmem>
    8000014c:	8526                	mv	a0,s1
    8000014e:	00000097          	auipc	ra,0x0
    80000152:	528080e7          	jalr	1320(ra) # 80000676 <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80000156:	6c84                	ld	s1,24(s1)
  if(r)
    80000158:	c885                	beqz	s1,80000188 <kalloc+0x4e>
    kmem.freelist = r->next;
    8000015a:	609c                	ld	a5,0(s1)
    8000015c:	00003517          	auipc	a0,0x3
    80000160:	10450513          	add	a0,a0,260 # 80003260 <kmem>
    80000164:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000166:	00000097          	auipc	ra,0x0
    8000016a:	5c4080e7          	jalr	1476(ra) # 8000072a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    8000016e:	6605                	lui	a2,0x1
    80000170:	4595                	li	a1,5
    80000172:	8526                	mv	a0,s1
    80000174:	00001097          	auipc	ra,0x1
    80000178:	86c080e7          	jalr	-1940(ra) # 800009e0 <memset>
  return (void*)r;
}
    8000017c:	8526                	mv	a0,s1
    8000017e:	60e2                	ld	ra,24(sp)
    80000180:	6442                	ld	s0,16(sp)
    80000182:	64a2                	ld	s1,8(sp)
    80000184:	6105                	add	sp,sp,32
    80000186:	8082                	ret
  release(&kmem.lock);
    80000188:	00003517          	auipc	a0,0x3
    8000018c:	0d850513          	add	a0,a0,216 # 80003260 <kmem>
    80000190:	00000097          	auipc	ra,0x0
    80000194:	59a080e7          	jalr	1434(ra) # 8000072a <release>
  if(r)
    80000198:	b7d5                	j	8000017c <kalloc+0x42>

000000008000019a <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    8000019a:	1141                	add	sp,sp,-16
    8000019c:	e422                	sd	s0,8(sp)
    8000019e:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800001a0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800001a4:	00003797          	auipc	a5,0x3
    800001a8:	09c7b783          	ld	a5,156(a5) # 80003240 <kernel_pagetable>
    800001ac:	83b1                	srl	a5,a5,0xc
    800001ae:	577d                	li	a4,-1
    800001b0:	177e                	sll	a4,a4,0x3f
    800001b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800001b4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800001b8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800001bc:	6422                	ld	s0,8(sp)
    800001be:	0141                	add	sp,sp,16
    800001c0:	8082                	ret

00000000800001c2 <walk>:
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc) 
// 虚拟映射查询与建立
// 输入虚拟地址与对应的页表，返回该虚拟地址对应的最低级页表项地址
// alloc为0只查询，为1表示允许在遍历过程中为缺失的中间级页表分配一页。
{
    800001c2:	7139                	add	sp,sp,-64
    800001c4:	fc06                	sd	ra,56(sp)
    800001c6:	f822                	sd	s0,48(sp)
    800001c8:	f426                	sd	s1,40(sp)
    800001ca:	f04a                	sd	s2,32(sp)
    800001cc:	ec4e                	sd	s3,24(sp)
    800001ce:	e852                	sd	s4,16(sp)
    800001d0:	e456                	sd	s5,8(sp)
    800001d2:	e05a                	sd	s6,0(sp)
    800001d4:	0080                	add	s0,sp,64
    800001d6:	84aa                	mv	s1,a0
    800001d8:	89ae                	mv	s3,a1
    800001da:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800001dc:	57fd                	li	a5,-1
    800001de:	83e9                	srl	a5,a5,0x1a
    800001e0:	4a79                	li	s4,30
    panic("walk");
  for(int level = 2; level > 0; level--) {
    800001e2:	4b31                	li	s6,12
  if(va >= MAXVA)
    800001e4:	04b7f363          	bgeu	a5,a1,8000022a <walk+0x68>
    panic("walk");
    800001e8:	00003517          	auipc	a0,0x3
    800001ec:	e2850513          	add	a0,a0,-472 # 80003010 <etext+0x10>
    800001f0:	00001097          	auipc	ra,0x1
    800001f4:	a38080e7          	jalr	-1480(ra) # 80000c28 <panic>
    if(*pte & PTE_V) { // PTE有效
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
    } else {  // PTE无效，先判断是否可以写入
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
    800001f8:	060a8763          	beqz	s5,80000266 <walk+0xa4>
    800001fc:	4505                	li	a0,1
    800001fe:	00000097          	auipc	ra,0x0
    80000202:	f3c080e7          	jalr	-196(ra) # 8000013a <kalloc>
    80000206:	84aa                	mv	s1,a0
    80000208:	c529                	beqz	a0,80000252 <walk+0x90>
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
    8000020a:	6605                	lui	a2,0x1
    8000020c:	4581                	li	a1,0
    8000020e:	00000097          	auipc	ra,0x0
    80000212:	7d2080e7          	jalr	2002(ra) # 800009e0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    80000216:	00c4d793          	srl	a5,s1,0xc
    8000021a:	07aa                	sll	a5,a5,0xa
    8000021c:	0017e793          	or	a5,a5,1
    80000220:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000224:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fff3c17>
    80000226:	036a0063          	beq	s4,s6,80000246 <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    8000022a:	0149d933          	srl	s2,s3,s4
    8000022e:	1ff97913          	and	s2,s2,511
    80000232:	090e                	sll	s2,s2,0x3
    80000234:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) { // PTE有效
    80000236:	00093483          	ld	s1,0(s2)
    8000023a:	0014f793          	and	a5,s1,1
    8000023e:	dfcd                	beqz	a5,800001f8 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte); 
    80000240:	80a9                	srl	s1,s1,0xa
    80000242:	04b2                	sll	s1,s1,0xc
    80000244:	b7c5                	j	80000224 <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];  
    80000246:	00c9d513          	srl	a0,s3,0xc
    8000024a:	1ff57513          	and	a0,a0,511
    8000024e:	050e                	sll	a0,a0,0x3
    80000250:	9526                	add	a0,a0,s1
}
    80000252:	70e2                	ld	ra,56(sp)
    80000254:	7442                	ld	s0,48(sp)
    80000256:	74a2                	ld	s1,40(sp)
    80000258:	7902                	ld	s2,32(sp)
    8000025a:	69e2                	ld	s3,24(sp)
    8000025c:	6a42                	ld	s4,16(sp)
    8000025e:	6aa2                	ld	s5,8(sp)
    80000260:	6b02                	ld	s6,0(sp)
    80000262:	6121                	add	sp,sp,64
    80000264:	8082                	ret
        return 0; // 失败返回0
    80000266:	4501                	li	a0,0
    80000268:	b7ed                	j	80000252 <walk+0x90>

000000008000026a <mappages>:
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
    8000026a:	715d                	add	sp,sp,-80
    8000026c:	e486                	sd	ra,72(sp)
    8000026e:	e0a2                	sd	s0,64(sp)
    80000270:	fc26                	sd	s1,56(sp)
    80000272:	f84a                	sd	s2,48(sp)
    80000274:	f44e                	sd	s3,40(sp)
    80000276:	f052                	sd	s4,32(sp)
    80000278:	ec56                	sd	s5,24(sp)
    8000027a:	e85a                	sd	s6,16(sp)
    8000027c:	e45e                	sd	s7,8(sp)
    8000027e:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80000280:	03459793          	sll	a5,a1,0x34
    80000284:	e7b9                	bnez	a5,800002d2 <mappages+0x68>
    80000286:	8aaa                	mv	s5,a0
    80000288:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000028a:	03461793          	sll	a5,a2,0x34
    8000028e:	ebb1                	bnez	a5,800002e2 <mappages+0x78>
    panic("mappages: size not aligned");

  if(size == 0)
    80000290:	c22d                	beqz	a2,800002f2 <mappages+0x88>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
    80000292:	77fd                	lui	a5,0xfffff
    80000294:	963e                	add	a2,a2,a5
    80000296:	00b609b3          	add	s3,a2,a1
  a = va;
    8000029a:	892e                	mv	s2,a1
    8000029c:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    if(a == last)
      break;
    a += PGSIZE;
    800002a0:	6b85                	lui	s7,0x1
    800002a2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    800002a6:	4605                	li	a2,1
    800002a8:	85ca                	mv	a1,s2
    800002aa:	8556                	mv	a0,s5
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	f16080e7          	jalr	-234(ra) # 800001c2 <walk>
    800002b4:	cd39                	beqz	a0,80000312 <mappages+0xa8>
    if(*pte & PTE_V) // 重复映射
    800002b6:	611c                	ld	a5,0(a0)
    800002b8:	8b85                	and	a5,a5,1
    800002ba:	e7a1                	bnez	a5,80000302 <mappages+0x98>
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    800002bc:	80b1                	srl	s1,s1,0xc
    800002be:	04aa                	sll	s1,s1,0xa
    800002c0:	0164e4b3          	or	s1,s1,s6
    800002c4:	0014e493          	or	s1,s1,1
    800002c8:	e104                	sd	s1,0(a0)
    if(a == last)
    800002ca:	07390063          	beq	s2,s3,8000032a <mappages+0xc0>
    a += PGSIZE;
    800002ce:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    800002d0:	bfc9                	j	800002a2 <mappages+0x38>
    panic("mappages: va not aligned");
    800002d2:	00003517          	auipc	a0,0x3
    800002d6:	d4650513          	add	a0,a0,-698 # 80003018 <etext+0x18>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	94e080e7          	jalr	-1714(ra) # 80000c28 <panic>
    panic("mappages: size not aligned");
    800002e2:	00003517          	auipc	a0,0x3
    800002e6:	d5650513          	add	a0,a0,-682 # 80003038 <etext+0x38>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	93e080e7          	jalr	-1730(ra) # 80000c28 <panic>
    panic("mappages: size");
    800002f2:	00003517          	auipc	a0,0x3
    800002f6:	d6650513          	add	a0,a0,-666 # 80003058 <etext+0x58>
    800002fa:	00001097          	auipc	ra,0x1
    800002fe:	92e080e7          	jalr	-1746(ra) # 80000c28 <panic>
      panic("mappages: remap");
    80000302:	00003517          	auipc	a0,0x3
    80000306:	d6650513          	add	a0,a0,-666 # 80003068 <etext+0x68>
    8000030a:	00001097          	auipc	ra,0x1
    8000030e:	91e080e7          	jalr	-1762(ra) # 80000c28 <panic>
      return -1;
    80000312:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80000314:	60a6                	ld	ra,72(sp)
    80000316:	6406                	ld	s0,64(sp)
    80000318:	74e2                	ld	s1,56(sp)
    8000031a:	7942                	ld	s2,48(sp)
    8000031c:	79a2                	ld	s3,40(sp)
    8000031e:	7a02                	ld	s4,32(sp)
    80000320:	6ae2                	ld	s5,24(sp)
    80000322:	6b42                	ld	s6,16(sp)
    80000324:	6ba2                	ld	s7,8(sp)
    80000326:	6161                	add	sp,sp,80
    80000328:	8082                	ret
  return 0;
    8000032a:	4501                	li	a0,0
    8000032c:	b7e5                	j	80000314 <mappages+0xaa>

000000008000032e <kvmmap>:
{
    8000032e:	1141                	add	sp,sp,-16
    80000330:	e406                	sd	ra,8(sp)
    80000332:	e022                	sd	s0,0(sp)
    80000334:	0800                	add	s0,sp,16
    80000336:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80000338:	86b2                	mv	a3,a2
    8000033a:	863e                	mv	a2,a5
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f2e080e7          	jalr	-210(ra) # 8000026a <mappages>
    80000344:	e509                	bnez	a0,8000034e <kvmmap+0x20>
}
    80000346:	60a2                	ld	ra,8(sp)
    80000348:	6402                	ld	s0,0(sp)
    8000034a:	0141                	add	sp,sp,16
    8000034c:	8082                	ret
    panic("kvmmap");
    8000034e:	00003517          	auipc	a0,0x3
    80000352:	d2a50513          	add	a0,a0,-726 # 80003078 <etext+0x78>
    80000356:	00001097          	auipc	ra,0x1
    8000035a:	8d2080e7          	jalr	-1838(ra) # 80000c28 <panic>

000000008000035e <kvmmake>:
{
    8000035e:	1101                	add	sp,sp,-32
    80000360:	ec06                	sd	ra,24(sp)
    80000362:	e822                	sd	s0,16(sp)
    80000364:	e426                	sd	s1,8(sp)
    80000366:	e04a                	sd	s2,0(sp)
    80000368:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc(true);
    8000036a:	4505                	li	a0,1
    8000036c:	00000097          	auipc	ra,0x0
    80000370:	dce080e7          	jalr	-562(ra) # 8000013a <kalloc>
    80000374:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE); //关键清零
    80000376:	6605                	lui	a2,0x1
    80000378:	4581                	li	a1,0
    8000037a:	00000097          	auipc	ra,0x0
    8000037e:	666080e7          	jalr	1638(ra) # 800009e0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80000382:	4719                	li	a4,6
    80000384:	6685                	lui	a3,0x1
    80000386:	10000637          	lui	a2,0x10000
    8000038a:	100005b7          	lui	a1,0x10000
    8000038e:	8526                	mv	a0,s1
    80000390:	00000097          	auipc	ra,0x0
    80000394:	f9e080e7          	jalr	-98(ra) # 8000032e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80000398:	4719                	li	a4,6
    8000039a:	6685                	lui	a3,0x1
    8000039c:	10001637          	lui	a2,0x10001
    800003a0:	100015b7          	lui	a1,0x10001
    800003a4:	8526                	mv	a0,s1
    800003a6:	00000097          	auipc	ra,0x0
    800003aa:	f88080e7          	jalr	-120(ra) # 8000032e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800003ae:	4719                	li	a4,6
    800003b0:	004006b7          	lui	a3,0x400
    800003b4:	0c000637          	lui	a2,0xc000
    800003b8:	0c0005b7          	lui	a1,0xc000
    800003bc:	8526                	mv	a0,s1
    800003be:	00000097          	auipc	ra,0x0
    800003c2:	f70080e7          	jalr	-144(ra) # 8000032e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800003c6:	00003917          	auipc	s2,0x3
    800003ca:	c3a90913          	add	s2,s2,-966 # 80003000 <etext>
    800003ce:	4729                	li	a4,10
    800003d0:	80003697          	auipc	a3,0x80003
    800003d4:	c3068693          	add	a3,a3,-976 # 3000 <_entry-0x7fffd000>
    800003d8:	4605                	li	a2,1
    800003da:	067e                	sll	a2,a2,0x1f
    800003dc:	85b2                	mv	a1,a2
    800003de:	8526                	mv	a0,s1
    800003e0:	00000097          	auipc	ra,0x0
    800003e4:	f4e080e7          	jalr	-178(ra) # 8000032e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800003e8:	4719                	li	a4,6
    800003ea:	46c5                	li	a3,17
    800003ec:	06ee                	sll	a3,a3,0x1b
    800003ee:	412686b3          	sub	a3,a3,s2
    800003f2:	864a                	mv	a2,s2
    800003f4:	85ca                	mv	a1,s2
    800003f6:	8526                	mv	a0,s1
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	f36080e7          	jalr	-202(ra) # 8000032e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80000400:	4729                	li	a4,10
    80000402:	6685                	lui	a3,0x1
    80000404:	00002617          	auipc	a2,0x2
    80000408:	bfc60613          	add	a2,a2,-1028 # 80002000 <_trampoline>
    8000040c:	040005b7          	lui	a1,0x4000
    80000410:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80000412:	05b2                	sll	a1,a1,0xc
    80000414:	8526                	mv	a0,s1
    80000416:	00000097          	auipc	ra,0x0
    8000041a:	f18080e7          	jalr	-232(ra) # 8000032e <kvmmap>
}
    8000041e:	8526                	mv	a0,s1
    80000420:	60e2                	ld	ra,24(sp)
    80000422:	6442                	ld	s0,16(sp)
    80000424:	64a2                	ld	s1,8(sp)
    80000426:	6902                	ld	s2,0(sp)
    80000428:	6105                	add	sp,sp,32
    8000042a:	8082                	ret

000000008000042c <kvminit>:
{
    8000042c:	1141                	add	sp,sp,-16
    8000042e:	e406                	sd	ra,8(sp)
    80000430:	e022                	sd	s0,0(sp)
    80000432:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80000434:	00000097          	auipc	ra,0x0
    80000438:	f2a080e7          	jalr	-214(ra) # 8000035e <kvmmake>
    8000043c:	00003797          	auipc	a5,0x3
    80000440:	e0a7b223          	sd	a0,-508(a5) # 80003240 <kernel_pagetable>
}
    80000444:	60a2                	ld	ra,8(sp)
    80000446:	6402                	ld	s0,0(sp)
    80000448:	0141                	add	sp,sp,16
    8000044a:	8082                	ret

000000008000044c <print_pgtbl>:

void print_pgtbl(pagetable_t pagetable, int level) {
    8000044c:	711d                	add	sp,sp,-96
    8000044e:	ec86                	sd	ra,88(sp)
    80000450:	e8a2                	sd	s0,80(sp)
    80000452:	e4a6                	sd	s1,72(sp)
    80000454:	e0ca                	sd	s2,64(sp)
    80000456:	fc4e                	sd	s3,56(sp)
    80000458:	f852                	sd	s4,48(sp)
    8000045a:	f456                	sd	s5,40(sp)
    8000045c:	f05a                	sd	s6,32(sp)
    8000045e:	ec5e                	sd	s7,24(sp)
    80000460:	e862                	sd	s8,16(sp)
    80000462:	e466                	sd	s9,8(sp)
    80000464:	e06a                	sd	s10,0(sp)
    80000466:	1080                	add	s0,sp,96
    80000468:	8aae                	mv	s5,a1
  //递归打印页表
  for(int i = 0; i < 512; i++) { // 512个页表项
    8000046a:	8a2a                	mv	s4,a0
    8000046c:	4981                	li	s3,0
    if(pte & PTE_V) {// 打印有效的页表项

      for(int j = 0; j < level; j++)
        printf("  ");

      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    8000046e:	00003c17          	auipc	s8,0x3
    80000472:	c1ac0c13          	add	s8,s8,-998 # 80003088 <etext+0x88>

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
    80000476:	00003d17          	auipc	s10,0x3
    8000047a:	c2ad0d13          	add	s10,s10,-982 # 800030a0 <etext+0xa0>
      for(int j = 0; j < level; j++)
    8000047e:	4c81                	li	s9,0
        printf("  ");
    80000480:	00003b17          	auipc	s6,0x3
    80000484:	c00b0b13          	add	s6,s6,-1024 # 80003080 <etext+0x80>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000488:	20000b93          	li	s7,512
    8000048c:	a025                	j	800004b4 <print_pgtbl+0x68>
      } 
      else {
        printf("\n");
    8000048e:	00003517          	auipc	a0,0x3
    80000492:	ca250513          	add	a0,a0,-862 # 80003130 <etext+0x130>
    80000496:	00000097          	auipc	ra,0x0
    8000049a:	7dc080e7          	jalr	2012(ra) # 80000c72 <printf>
        print_pgtbl((pagetable_t)PTE2PA(pte), level + 1);
    8000049e:	001a859b          	addw	a1,s5,1
    800004a2:	8526                	mv	a0,s1
    800004a4:	00000097          	auipc	ra,0x0
    800004a8:	fa8080e7          	jalr	-88(ra) # 8000044c <print_pgtbl>
  for(int i = 0; i < 512; i++) { // 512个页表项
    800004ac:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    800004ae:	0a21                	add	s4,s4,8
    800004b0:	05798763          	beq	s3,s7,800004fe <print_pgtbl+0xb2>
    pte_t pte = pagetable[i];
    800004b4:	000a3903          	ld	s2,0(s4)
    if(pte & PTE_V) {// 打印有效的页表项
    800004b8:	00197793          	and	a5,s2,1
    800004bc:	dbe5                	beqz	a5,800004ac <print_pgtbl+0x60>
      for(int j = 0; j < level; j++)
    800004be:	01505b63          	blez	s5,800004d4 <print_pgtbl+0x88>
    800004c2:	84e6                	mv	s1,s9
        printf("  ");
    800004c4:	855a                	mv	a0,s6
    800004c6:	00000097          	auipc	ra,0x0
    800004ca:	7ac080e7          	jalr	1964(ra) # 80000c72 <printf>
      for(int j = 0; j < level; j++)
    800004ce:	2485                	addw	s1,s1,1
    800004d0:	fe9a9ae3          	bne	s5,s1,800004c4 <print_pgtbl+0x78>
      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    800004d4:	00a95493          	srl	s1,s2,0xa
    800004d8:	04b2                	sll	s1,s1,0xc
    800004da:	86a6                	mv	a3,s1
    800004dc:	864a                	mv	a2,s2
    800004de:	85ce                	mv	a1,s3
    800004e0:	8562                	mv	a0,s8
    800004e2:	00000097          	auipc	ra,0x0
    800004e6:	790080e7          	jalr	1936(ra) # 80000c72 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    800004ea:	00e97913          	and	s2,s2,14
    800004ee:	fa0900e3          	beqz	s2,8000048e <print_pgtbl+0x42>
        printf(" [leaf]\n");
    800004f2:	856a                	mv	a0,s10
    800004f4:	00000097          	auipc	ra,0x0
    800004f8:	77e080e7          	jalr	1918(ra) # 80000c72 <printf>
    800004fc:	bf45                	j	800004ac <print_pgtbl+0x60>
      }
    }
  }
}
    800004fe:	60e6                	ld	ra,88(sp)
    80000500:	6446                	ld	s0,80(sp)
    80000502:	64a6                	ld	s1,72(sp)
    80000504:	6906                	ld	s2,64(sp)
    80000506:	79e2                	ld	s3,56(sp)
    80000508:	7a42                	ld	s4,48(sp)
    8000050a:	7aa2                	ld	s5,40(sp)
    8000050c:	7b02                	ld	s6,32(sp)
    8000050e:	6be2                	ld	s7,24(sp)
    80000510:	6c42                	ld	s8,16(sp)
    80000512:	6ca2                	ld	s9,8(sp)
    80000514:	6d02                	ld	s10,0(sp)
    80000516:	6125                	add	sp,sp,96
    80000518:	8082                	ret

000000008000051a <print_cur_pgtbl>:

void print_cur_pgtbl(pagetable_t pagetable) {
    8000051a:	715d                	add	sp,sp,-80
    8000051c:	e486                	sd	ra,72(sp)
    8000051e:	e0a2                	sd	s0,64(sp)
    80000520:	fc26                	sd	s1,56(sp)
    80000522:	f84a                	sd	s2,48(sp)
    80000524:	f44e                	sd	s3,40(sp)
    80000526:	f052                	sd	s4,32(sp)
    80000528:	ec56                	sd	s5,24(sp)
    8000052a:	e85a                	sd	s6,16(sp)
    8000052c:	e45e                	sd	s7,8(sp)
    8000052e:	0880                	add	s0,sp,80
    80000530:	89aa                	mv	s3,a0
  //打印当前层页表
  printf("page table %p\n", pagetable);
    80000532:	85aa                	mv	a1,a0
    80000534:	00003517          	auipc	a0,0x3
    80000538:	b7c50513          	add	a0,a0,-1156 # 800030b0 <etext+0xb0>
    8000053c:	00000097          	auipc	ra,0x0
    80000540:	736080e7          	jalr	1846(ra) # 80000c72 <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000544:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000546:	00003a97          	auipc	s5,0x3
    8000054a:	b7aa8a93          	add	s5,s5,-1158 # 800030c0 <etext+0xc0>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
    8000054e:	00003b97          	auipc	s7,0x3
    80000552:	be2b8b93          	add	s7,s7,-1054 # 80003130 <etext+0x130>
        printf(" [leaf]\n");
    80000556:	00003b17          	auipc	s6,0x3
    8000055a:	b4ab0b13          	add	s6,s6,-1206 # 800030a0 <etext+0xa0>
  for(int i = 0; i < 512; i++) { // 512个页表项
    8000055e:	20000a13          	li	s4,512
    80000562:	a811                	j	80000576 <print_cur_pgtbl+0x5c>
        printf("\n");
    80000564:	855e                	mv	a0,s7
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	70c080e7          	jalr	1804(ra) # 80000c72 <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    8000056e:	2905                	addw	s2,s2,1
    80000570:	09a1                	add	s3,s3,8
    80000572:	03490963          	beq	s2,s4,800005a4 <print_cur_pgtbl+0x8a>
    pte_t pte = pagetable[i];
    80000576:	0009b483          	ld	s1,0(s3)
    if(pte & PTE_V) {// 打印有效的页表项
    8000057a:	0014f793          	and	a5,s1,1
    8000057e:	dbe5                	beqz	a5,8000056e <print_cur_pgtbl+0x54>
      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000580:	00a4d693          	srl	a3,s1,0xa
    80000584:	06b2                	sll	a3,a3,0xc
    80000586:	8626                	mv	a2,s1
    80000588:	85ca                	mv	a1,s2
    8000058a:	8556                	mv	a0,s5
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	6e6080e7          	jalr	1766(ra) # 80000c72 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000594:	88b9                	and	s1,s1,14
    80000596:	d4f9                	beqz	s1,80000564 <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80000598:	855a                	mv	a0,s6
    8000059a:	00000097          	auipc	ra,0x0
    8000059e:	6d8080e7          	jalr	1752(ra) # 80000c72 <printf>
    800005a2:	b7f1                	j	8000056e <print_cur_pgtbl+0x54>
      }
    }
  }
    800005a4:	60a6                	ld	ra,72(sp)
    800005a6:	6406                	ld	s0,64(sp)
    800005a8:	74e2                	ld	s1,56(sp)
    800005aa:	7942                	ld	s2,48(sp)
    800005ac:	79a2                	ld	s3,40(sp)
    800005ae:	7a02                	ld	s4,32(sp)
    800005b0:	6ae2                	ld	s5,24(sp)
    800005b2:	6b42                	ld	s6,16(sp)
    800005b4:	6ba2                	ld	s7,8(sp)
    800005b6:	6161                	add	sp,sp,80
    800005b8:	8082                	ret

00000000800005ba <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800005ba:	1141                	add	sp,sp,-16
    800005bc:	e422                	sd	s0,8(sp)
    800005be:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800005c0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800005c2:	2501                	sext.w	a0,a0
    800005c4:	6422                	ld	s0,8(sp)
    800005c6:	0141                	add	sp,sp,16
    800005c8:	8082                	ret

00000000800005ca <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800005ca:	1141                	add	sp,sp,-16
    800005cc:	e422                	sd	s0,8(sp)
    800005ce:	0800                	add	s0,sp,16
    800005d0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800005d2:	2781                	sext.w	a5,a5
    800005d4:	078e                	sll	a5,a5,0x3
  return c;
}
    800005d6:	00003517          	auipc	a0,0x3
    800005da:	caa50513          	add	a0,a0,-854 # 80003280 <cpus>
    800005de:	953e                	add	a0,a0,a5
    800005e0:	6422                	ld	s0,8(sp)
    800005e2:	0141                	add	sp,sp,16
    800005e4:	8082                	ret

00000000800005e6 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    800005e6:	1141                	add	sp,sp,-16
    800005e8:	e422                	sd	s0,8(sp)
    800005ea:	0800                	add	s0,sp,16
  lk->name = name;
    800005ec:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800005ee:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800005f2:	00053823          	sd	zero,16(a0)
}
    800005f6:	6422                	ld	s0,8(sp)
    800005f8:	0141                	add	sp,sp,16
    800005fa:	8082                	ret

00000000800005fc <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    800005fc:	411c                	lw	a5,0(a0)
    800005fe:	e399                	bnez	a5,80000604 <holding+0x8>
    80000600:	4501                	li	a0,0
  return r;
}
    80000602:	8082                	ret
{
    80000604:	1101                	add	sp,sp,-32
    80000606:	ec06                	sd	ra,24(sp)
    80000608:	e822                	sd	s0,16(sp)
    8000060a:	e426                	sd	s1,8(sp)
    8000060c:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    8000060e:	6904                	ld	s1,16(a0)
    80000610:	00000097          	auipc	ra,0x0
    80000614:	fba080e7          	jalr	-70(ra) # 800005ca <mycpu>
    80000618:	40a48533          	sub	a0,s1,a0
    8000061c:	00153513          	seqz	a0,a0
}
    80000620:	60e2                	ld	ra,24(sp)
    80000622:	6442                	ld	s0,16(sp)
    80000624:	64a2                	ld	s1,8(sp)
    80000626:	6105                	add	sp,sp,32
    80000628:	8082                	ret

000000008000062a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    8000062a:	1101                	add	sp,sp,-32
    8000062c:	ec06                	sd	ra,24(sp)
    8000062e:	e822                	sd	s0,16(sp)
    80000630:	e426                	sd	s1,8(sp)
    80000632:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000634:	100024f3          	csrr	s1,sstatus
    80000638:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000063c:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000063e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000642:	00000097          	auipc	ra,0x0
    80000646:	f88080e7          	jalr	-120(ra) # 800005ca <mycpu>
    8000064a:	411c                	lw	a5,0(a0)
    8000064c:	cf89                	beqz	a5,80000666 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	f7c080e7          	jalr	-132(ra) # 800005ca <mycpu>
    80000656:	411c                	lw	a5,0(a0)
    80000658:	2785                	addw	a5,a5,1
    8000065a:	c11c                	sw	a5,0(a0)
}
    8000065c:	60e2                	ld	ra,24(sp)
    8000065e:	6442                	ld	s0,16(sp)
    80000660:	64a2                	ld	s1,8(sp)
    80000662:	6105                	add	sp,sp,32
    80000664:	8082                	ret
    mycpu()->intena = old;
    80000666:	00000097          	auipc	ra,0x0
    8000066a:	f64080e7          	jalr	-156(ra) # 800005ca <mycpu>
  return (x & SSTATUS_SIE) != 0;
    8000066e:	8085                	srl	s1,s1,0x1
    80000670:	8885                	and	s1,s1,1
    80000672:	c144                	sw	s1,4(a0)
    80000674:	bfe9                	j	8000064e <push_off+0x24>

0000000080000676 <acquire>:
{
    80000676:	1101                	add	sp,sp,-32
    80000678:	ec06                	sd	ra,24(sp)
    8000067a:	e822                	sd	s0,16(sp)
    8000067c:	e426                	sd	s1,8(sp)
    8000067e:	1000                	add	s0,sp,32
    80000680:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000682:	00000097          	auipc	ra,0x0
    80000686:	fa8080e7          	jalr	-88(ra) # 8000062a <push_off>
  if(holding(lk))
    8000068a:	8526                	mv	a0,s1
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	f70080e7          	jalr	-144(ra) # 800005fc <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000694:	4705                	li	a4,1
  if(holding(lk))
    80000696:	e115                	bnez	a0,800006ba <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000698:	87ba                	mv	a5,a4
    8000069a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    8000069e:	2781                	sext.w	a5,a5
    800006a0:	ffe5                	bnez	a5,80000698 <acquire+0x22>
  __sync_synchronize();
    800006a2:	0ff0000f          	fence
  lk->cpu = mycpu();
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	f24080e7          	jalr	-220(ra) # 800005ca <mycpu>
    800006ae:	e888                	sd	a0,16(s1)
}
    800006b0:	60e2                	ld	ra,24(sp)
    800006b2:	6442                	ld	s0,16(sp)
    800006b4:	64a2                	ld	s1,8(sp)
    800006b6:	6105                	add	sp,sp,32
    800006b8:	8082                	ret
    panic("acquire");
    800006ba:	00003517          	auipc	a0,0x3
    800006be:	a2650513          	add	a0,a0,-1498 # 800030e0 <etext+0xe0>
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	566080e7          	jalr	1382(ra) # 80000c28 <panic>

00000000800006ca <pop_off>:

void
pop_off(void)
{
    800006ca:	1141                	add	sp,sp,-16
    800006cc:	e406                	sd	ra,8(sp)
    800006ce:	e022                	sd	s0,0(sp)
    800006d0:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	ef8080e7          	jalr	-264(ra) # 800005ca <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800006da:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800006de:	8b89                	and	a5,a5,2
  if(intr_get())
    800006e0:	e78d                	bnez	a5,8000070a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    800006e2:	411c                	lw	a5,0(a0)
    800006e4:	02f05b63          	blez	a5,8000071a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    800006e8:	37fd                	addw	a5,a5,-1
    800006ea:	0007871b          	sext.w	a4,a5
    800006ee:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    800006f0:	eb09                	bnez	a4,80000702 <pop_off+0x38>
    800006f2:	415c                	lw	a5,4(a0)
    800006f4:	c799                	beqz	a5,80000702 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800006f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800006fa:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800006fe:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000702:	60a2                	ld	ra,8(sp)
    80000704:	6402                	ld	s0,0(sp)
    80000706:	0141                	add	sp,sp,16
    80000708:	8082                	ret
    panic("pop_off - interruptible");
    8000070a:	00003517          	auipc	a0,0x3
    8000070e:	9de50513          	add	a0,a0,-1570 # 800030e8 <etext+0xe8>
    80000712:	00000097          	auipc	ra,0x0
    80000716:	516080e7          	jalr	1302(ra) # 80000c28 <panic>
    panic("pop_off");
    8000071a:	00003517          	auipc	a0,0x3
    8000071e:	9e650513          	add	a0,a0,-1562 # 80003100 <etext+0x100>
    80000722:	00000097          	auipc	ra,0x0
    80000726:	506080e7          	jalr	1286(ra) # 80000c28 <panic>

000000008000072a <release>:
{
    8000072a:	1101                	add	sp,sp,-32
    8000072c:	ec06                	sd	ra,24(sp)
    8000072e:	e822                	sd	s0,16(sp)
    80000730:	e426                	sd	s1,8(sp)
    80000732:	1000                	add	s0,sp,32
    80000734:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	ec6080e7          	jalr	-314(ra) # 800005fc <holding>
    8000073e:	c115                	beqz	a0,80000762 <release+0x38>
  lk->cpu = 0;
    80000740:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000744:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000748:	0f50000f          	fence	iorw,ow
    8000074c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000750:	00000097          	auipc	ra,0x0
    80000754:	f7a080e7          	jalr	-134(ra) # 800006ca <pop_off>
}
    80000758:	60e2                	ld	ra,24(sp)
    8000075a:	6442                	ld	s0,16(sp)
    8000075c:	64a2                	ld	s1,8(sp)
    8000075e:	6105                	add	sp,sp,32
    80000760:	8082                	ret
    panic("release");
    80000762:	00003517          	auipc	a0,0x3
    80000766:	9a650513          	add	a0,a0,-1626 # 80003108 <etext+0x108>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	4be080e7          	jalr	1214(ra) # 80000c28 <panic>

0000000080000772 <main>:
struct spinlock start_lock;

// start()函数在管理者模式下跳转到此处，所有CPU都会执行
void
main()
{
    80000772:	711d                	add	sp,sp,-96
    80000774:	ec86                	sd	ra,88(sp)
    80000776:	e8a2                	sd	s0,80(sp)
    80000778:	e4a6                	sd	s1,72(sp)
    8000077a:	e0ca                	sd	s2,64(sp)
    8000077c:	fc4e                	sd	s3,56(sp)
    8000077e:	f852                	sd	s4,48(sp)
    80000780:	1080                	add	s0,sp,96
  if(cpuid() == 0){
    80000782:	00000097          	auipc	ra,0x0
    80000786:	e38080e7          	jalr	-456(ra) # 800005ba <cpuid>
    // userinit();          // 创建第一个用户进程
    __sync_synchronize();
    started = 1;         // 标记系统启动完成
  } else {
    // 其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000078a:	00003717          	auipc	a4,0x3
    8000078e:	abe70713          	add	a4,a4,-1346 # 80003248 <started>
  if(cpuid() == 0){
    80000792:	c905                	beqz	a0,800007c2 <main+0x50>
    while(started == 0)
    80000794:	431c                	lw	a5,0(a4)
    80000796:	2781                	sext.w	a5,a5
    80000798:	dff5                	beqz	a5,80000794 <main+0x22>
      ;
    
    __sync_synchronize();
    8000079a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000079e:	00000097          	auipc	ra,0x0
    800007a2:	e1c080e7          	jalr	-484(ra) # 800005ba <cpuid>
    800007a6:	85aa                	mv	a1,a0
    800007a8:	00003517          	auipc	a0,0x3
    800007ac:	97850513          	add	a0,a0,-1672 # 80003120 <etext+0x120>
    800007b0:	00000097          	auipc	ra,0x0
    800007b4:	4c2080e7          	jalr	1218(ra) # 80000c72 <printf>
    kvminithart();       // 开启分页机制
    800007b8:	00000097          	auipc	ra,0x0
    800007bc:	9e2080e7          	jalr	-1566(ra) # 8000019a <kvminithart>
    // trapinithart();   // 安装内核陷阱向量
    // plicinithart();   // 向PLIC请求设备中断
  }
  while(1);
    800007c0:	a001                	j	800007c0 <main+0x4e>
    800007c2:	84aa                	mv	s1,a0
    initlock(&start_lock,"start_lock");
    800007c4:	00003597          	auipc	a1,0x3
    800007c8:	94c58593          	add	a1,a1,-1716 # 80003110 <etext+0x110>
    800007cc:	00003517          	auipc	a0,0x3
    800007d0:	af450513          	add	a0,a0,-1292 # 800032c0 <start_lock>
    800007d4:	00000097          	auipc	ra,0x0
    800007d8:	e12080e7          	jalr	-494(ra) # 800005e6 <initlock>
    consoleinit();       // 初始化控制台
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	7f8080e7          	jalr	2040(ra) # 80000fd4 <consoleinit>
    printfinit();        // 初始化printf功能
    800007e4:	00000097          	auipc	ra,0x0
    800007e8:	66e080e7          	jalr	1646(ra) # 80000e52 <printfinit>
    printfinit();
    800007ec:	00000097          	auipc	ra,0x0
    800007f0:	666080e7          	jalr	1638(ra) # 80000e52 <printfinit>
    printf("\n");
    800007f4:	00003517          	auipc	a0,0x3
    800007f8:	93c50513          	add	a0,a0,-1732 # 80003130 <etext+0x130>
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	476080e7          	jalr	1142(ra) # 80000c72 <printf>
    printf("hart %d starting\n", cpuid());
    80000804:	00000097          	auipc	ra,0x0
    80000808:	db6080e7          	jalr	-586(ra) # 800005ba <cpuid>
    8000080c:	85aa                	mv	a1,a0
    8000080e:	00003517          	auipc	a0,0x3
    80000812:	91250513          	add	a0,a0,-1774 # 80003120 <etext+0x120>
    80000816:	00000097          	auipc	ra,0x0
    8000081a:	45c080e7          	jalr	1116(ra) # 80000c72 <printf>
    kinit();             // 物理页面分配器初始化
    8000081e:	00000097          	auipc	ra,0x0
    80000822:	8e0080e7          	jalr	-1824(ra) # 800000fe <kinit>
    pagetable_t test_pgtbl = (pagetable_t)kalloc(true);
    80000826:	4505                	li	a0,1
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	912080e7          	jalr	-1774(ra) # 8000013a <kalloc>
    80000830:	89aa                	mv	s3,a0
      memset(test_pgtbl, 0, PGSIZE);
    80000832:	6605                	lui	a2,0x1
    80000834:	4581                	li	a1,0
    80000836:	00000097          	auipc	ra,0x0
    8000083a:	1aa080e7          	jalr	426(ra) # 800009e0 <memset>
      if(test_pgtbl == 0){
    8000083e:	fa840913          	add	s2,s0,-88
      for(int i = 0; i < 5; i++){
    80000842:	4a15                	li	s4,5
      if(test_pgtbl == 0){
    80000844:	0a098e63          	beqz	s3,80000900 <main+0x18e>
        pages[i] = kalloc(true); // 分配并清零测试物理页
    80000848:	4505                	li	a0,1
    8000084a:	00000097          	auipc	ra,0x0
    8000084e:	8f0080e7          	jalr	-1808(ra) # 8000013a <kalloc>
    80000852:	00a93023          	sd	a0,0(s2)
        if(pages[i] == 0){
    80000856:	c569                	beqz	a0,80000920 <main+0x1ae>
      for(int i = 0; i < 5; i++){
    80000858:	2485                	addw	s1,s1,1
    8000085a:	0921                	add	s2,s2,8
    8000085c:	ff4496e3          	bne	s1,s4,80000848 <main+0xd6>
      mappages(test_pgtbl, 0, PGSIZE, (uint64)pages[0], PTE_R | PTE_W);
    80000860:	4719                	li	a4,6
    80000862:	fa843683          	ld	a3,-88(s0)
    80000866:	6605                	lui	a2,0x1
    80000868:	4581                	li	a1,0
    8000086a:	854e                	mv	a0,s3
    8000086c:	00000097          	auipc	ra,0x0
    80000870:	9fe080e7          	jalr	-1538(ra) # 8000026a <mappages>
      if(mappages(test_pgtbl, 10*PGSIZE, PGSIZE, (uint64)pages[1], PTE_R) != 0)
    80000874:	4709                	li	a4,2
    80000876:	fb043683          	ld	a3,-80(s0)
    8000087a:	6605                	lui	a2,0x1
    8000087c:	65a9                	lui	a1,0xa
    8000087e:	854e                	mv	a0,s3
    80000880:	00000097          	auipc	ra,0x0
    80000884:	9ea080e7          	jalr	-1558(ra) # 8000026a <mappages>
    80000888:	ed4d                	bnez	a0,80000942 <main+0x1d0>
      kvmmap(test_pgtbl, 512*PGSIZE, (uint64)pages[2], PGSIZE, PTE_R | PTE_X);
    8000088a:	4729                	li	a4,10
    8000088c:	6685                	lui	a3,0x1
    8000088e:	fb843603          	ld	a2,-72(s0)
    80000892:	002005b7          	lui	a1,0x200
    80000896:	854e                	mv	a0,s3
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	a96080e7          	jalr	-1386(ra) # 8000032e <kvmmap>
      if(mappages(test_pgtbl, 512ULL*512*PGSIZE, PGSIZE, (uint64)pages[3], PTE_R | PTE_W) != 0)
    800008a0:	4719                	li	a4,6
    800008a2:	fc043683          	ld	a3,-64(s0)
    800008a6:	6605                	lui	a2,0x1
    800008a8:	400005b7          	lui	a1,0x40000
    800008ac:	854e                	mv	a0,s3
    800008ae:	00000097          	auipc	ra,0x0
    800008b2:	9bc080e7          	jalr	-1604(ra) # 8000026a <mappages>
    800008b6:	ed59                	bnez	a0,80000954 <main+0x1e2>
      if(mappages(test_pgtbl, MAXVA - PGSIZE, PGSIZE, (uint64)pages[4], PTE_R | PTE_W) != 0)
    800008b8:	4719                	li	a4,6
    800008ba:	fc843683          	ld	a3,-56(s0)
    800008be:	6605                	lui	a2,0x1
    800008c0:	040005b7          	lui	a1,0x4000
    800008c4:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800008c6:	05b2                	sll	a1,a1,0xc
    800008c8:	854e                	mv	a0,s3
    800008ca:	00000097          	auipc	ra,0x0
    800008ce:	9a0080e7          	jalr	-1632(ra) # 8000026a <mappages>
    800008d2:	e951                	bnez	a0,80000966 <main+0x1f4>
      printf("test_pgtbl：\n");
    800008d4:	00003517          	auipc	a0,0x3
    800008d8:	90450513          	add	a0,a0,-1788 # 800031d8 <etext+0x1d8>
    800008dc:	00000097          	auipc	ra,0x0
    800008e0:	396080e7          	jalr	918(ra) # 80000c72 <printf>
      print_pgtbl(test_pgtbl, 0);
    800008e4:	4581                	li	a1,0
    800008e6:	854e                	mv	a0,s3
    800008e8:	00000097          	auipc	ra,0x0
    800008ec:	b64080e7          	jalr	-1180(ra) # 8000044c <print_pgtbl>
    __sync_synchronize();
    800008f0:	0ff0000f          	fence
    started = 1;         // 标记系统启动完成
    800008f4:	4785                	li	a5,1
    800008f6:	00003717          	auipc	a4,0x3
    800008fa:	94f72923          	sw	a5,-1710(a4) # 80003248 <started>
    800008fe:	b5c9                	j	800007c0 <main+0x4e>
        printf("test_pgtbl alloc failed\n");
    80000900:	00003517          	auipc	a0,0x3
    80000904:	83850513          	add	a0,a0,-1992 # 80003138 <etext+0x138>
    80000908:	00000097          	auipc	ra,0x0
    8000090c:	36a080e7          	jalr	874(ra) # 80000c72 <printf>
        panic("no mem");
    80000910:	00003517          	auipc	a0,0x3
    80000914:	84850513          	add	a0,a0,-1976 # 80003158 <etext+0x158>
    80000918:	00000097          	auipc	ra,0x0
    8000091c:	310080e7          	jalr	784(ra) # 80000c28 <panic>
          printf("page[%d] alloc failed\n", i);
    80000920:	85a6                	mv	a1,s1
    80000922:	00003517          	auipc	a0,0x3
    80000926:	83e50513          	add	a0,a0,-1986 # 80003160 <etext+0x160>
    8000092a:	00000097          	auipc	ra,0x0
    8000092e:	348080e7          	jalr	840(ra) # 80000c72 <printf>
          panic("no mem");
    80000932:	00003517          	auipc	a0,0x3
    80000936:	82650513          	add	a0,a0,-2010 # 80003158 <etext+0x158>
    8000093a:	00000097          	auipc	ra,0x0
    8000093e:	2ee080e7          	jalr	750(ra) # 80000c28 <panic>
        printf("map va=10*PGSIZE failed\n");
    80000942:	00003517          	auipc	a0,0x3
    80000946:	83650513          	add	a0,a0,-1994 # 80003178 <etext+0x178>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	328080e7          	jalr	808(ra) # 80000c72 <printf>
    80000952:	bf25                	j	8000088a <main+0x118>
        printf("map va=512^2*PGSIZE failed\n");
    80000954:	00003517          	auipc	a0,0x3
    80000958:	84450513          	add	a0,a0,-1980 # 80003198 <etext+0x198>
    8000095c:	00000097          	auipc	ra,0x0
    80000960:	316080e7          	jalr	790(ra) # 80000c72 <printf>
    80000964:	bf91                	j	800008b8 <main+0x146>
        printf("map va=MAXVA-PGSIZE failed\n");
    80000966:	00003517          	auipc	a0,0x3
    8000096a:	85250513          	add	a0,a0,-1966 # 800031b8 <etext+0x1b8>
    8000096e:	00000097          	auipc	ra,0x0
    80000972:	304080e7          	jalr	772(ra) # 80000c72 <printf>
    80000976:	bfb9                	j	800008d4 <main+0x162>

0000000080000978 <start>:
void main();
void timerinit();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

void start() {
    80000978:	1141                	add	sp,sp,-16
    8000097a:	e422                	sd	s0,8(sp)
    8000097c:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000097e:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    80000982:	7779                	lui	a4,0xffffe
    80000984:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fff341f>
    80000988:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    8000098a:	6705                	lui	a4,0x1
    8000098c:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80000990:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000992:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000996:	00000797          	auipc	a5,0x0
    8000099a:	ddc78793          	add	a5,a5,-548 # 80000772 <main>
    8000099e:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800009a2:	4781                	li	a5,0
    800009a4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800009a8:	67c1                	lui	a5,0x10
    800009aa:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800009ac:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800009b0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800009b4:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800009b8:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800009bc:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800009c0:	57fd                	li	a5,-1
    800009c2:	83a9                	srl	a5,a5,0xa
    800009c4:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800009c8:	47bd                	li	a5,15
    800009ca:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800009ce:	f14027f3          	csrr	a5,mhartid
//   timerinit();

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    800009d2:	2781                	sext.w	a5,a5
  asm volatile("mv tp, %0" : : "r" (x));
    800009d4:	823e                	mv	tp,a5
  
  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    800009d6:	30200073          	mret
}
    800009da:	6422                	ld	s0,8(sp)
    800009dc:	0141                	add	sp,sp,16
    800009de:	8082                	ret

00000000800009e0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800009e0:	1141                	add	sp,sp,-16
    800009e2:	e422                	sd	s0,8(sp)
    800009e4:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800009e6:	ca19                	beqz	a2,800009fc <memset+0x1c>
    800009e8:	87aa                	mv	a5,a0
    800009ea:	1602                	sll	a2,a2,0x20
    800009ec:	9201                	srl	a2,a2,0x20
    800009ee:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800009f2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800009f6:	0785                	add	a5,a5,1
    800009f8:	fee79de3          	bne	a5,a4,800009f2 <memset+0x12>
  }
  return dst;
}
    800009fc:	6422                	ld	s0,8(sp)
    800009fe:	0141                	add	sp,sp,16
    80000a00:	8082                	ret

0000000080000a02 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000a02:	1141                	add	sp,sp,-16
    80000a04:	e422                	sd	s0,8(sp)
    80000a06:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000a08:	ca05                	beqz	a2,80000a38 <memcmp+0x36>
    80000a0a:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000a0e:	1682                	sll	a3,a3,0x20
    80000a10:	9281                	srl	a3,a3,0x20
    80000a12:	0685                	add	a3,a3,1 # 1001 <_entry-0x7fffefff>
    80000a14:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000a16:	00054783          	lbu	a5,0(a0)
    80000a1a:	0005c703          	lbu	a4,0(a1)
    80000a1e:	00e79863          	bne	a5,a4,80000a2e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000a22:	0505                	add	a0,a0,1
    80000a24:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000a26:	fed518e3          	bne	a0,a3,80000a16 <memcmp+0x14>
  }

  return 0;
    80000a2a:	4501                	li	a0,0
    80000a2c:	a019                	j	80000a32 <memcmp+0x30>
      return *s1 - *s2;
    80000a2e:	40e7853b          	subw	a0,a5,a4
}
    80000a32:	6422                	ld	s0,8(sp)
    80000a34:	0141                	add	sp,sp,16
    80000a36:	8082                	ret
  return 0;
    80000a38:	4501                	li	a0,0
    80000a3a:	bfe5                	j	80000a32 <memcmp+0x30>

0000000080000a3c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000a3c:	1141                	add	sp,sp,-16
    80000a3e:	e422                	sd	s0,8(sp)
    80000a40:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000a42:	c205                	beqz	a2,80000a62 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000a44:	02a5e263          	bltu	a1,a0,80000a68 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000a48:	1602                	sll	a2,a2,0x20
    80000a4a:	9201                	srl	a2,a2,0x20
    80000a4c:	00c587b3          	add	a5,a1,a2
{
    80000a50:	872a                	mv	a4,a0
      *d++ = *s++;
    80000a52:	0585                	add	a1,a1,1
    80000a54:	0705                	add	a4,a4,1
    80000a56:	fff5c683          	lbu	a3,-1(a1)
    80000a5a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000a5e:	fef59ae3          	bne	a1,a5,80000a52 <memmove+0x16>

  return dst;
}
    80000a62:	6422                	ld	s0,8(sp)
    80000a64:	0141                	add	sp,sp,16
    80000a66:	8082                	ret
  if(s < d && s + n > d){
    80000a68:	02061693          	sll	a3,a2,0x20
    80000a6c:	9281                	srl	a3,a3,0x20
    80000a6e:	00d58733          	add	a4,a1,a3
    80000a72:	fce57be3          	bgeu	a0,a4,80000a48 <memmove+0xc>
    d += n;
    80000a76:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000a78:	fff6079b          	addw	a5,a2,-1
    80000a7c:	1782                	sll	a5,a5,0x20
    80000a7e:	9381                	srl	a5,a5,0x20
    80000a80:	fff7c793          	not	a5,a5
    80000a84:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000a86:	177d                	add	a4,a4,-1
    80000a88:	16fd                	add	a3,a3,-1
    80000a8a:	00074603          	lbu	a2,0(a4)
    80000a8e:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000a92:	fee79ae3          	bne	a5,a4,80000a86 <memmove+0x4a>
    80000a96:	b7f1                	j	80000a62 <memmove+0x26>

0000000080000a98 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000a98:	1141                	add	sp,sp,-16
    80000a9a:	e406                	sd	ra,8(sp)
    80000a9c:	e022                	sd	s0,0(sp)
    80000a9e:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f9c080e7          	jalr	-100(ra) # 80000a3c <memmove>
}
    80000aa8:	60a2                	ld	ra,8(sp)
    80000aaa:	6402                	ld	s0,0(sp)
    80000aac:	0141                	add	sp,sp,16
    80000aae:	8082                	ret

0000000080000ab0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ab0:	1141                	add	sp,sp,-16
    80000ab2:	e422                	sd	s0,8(sp)
    80000ab4:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ab6:	ce11                	beqz	a2,80000ad2 <strncmp+0x22>
    80000ab8:	00054783          	lbu	a5,0(a0)
    80000abc:	cf89                	beqz	a5,80000ad6 <strncmp+0x26>
    80000abe:	0005c703          	lbu	a4,0(a1)
    80000ac2:	00f71a63          	bne	a4,a5,80000ad6 <strncmp+0x26>
    n--, p++, q++;
    80000ac6:	367d                	addw	a2,a2,-1
    80000ac8:	0505                	add	a0,a0,1
    80000aca:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000acc:	f675                	bnez	a2,80000ab8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ace:	4501                	li	a0,0
    80000ad0:	a809                	j	80000ae2 <strncmp+0x32>
    80000ad2:	4501                	li	a0,0
    80000ad4:	a039                	j	80000ae2 <strncmp+0x32>
  if(n == 0)
    80000ad6:	ca09                	beqz	a2,80000ae8 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ad8:	00054503          	lbu	a0,0(a0)
    80000adc:	0005c783          	lbu	a5,0(a1)
    80000ae0:	9d1d                	subw	a0,a0,a5
}
    80000ae2:	6422                	ld	s0,8(sp)
    80000ae4:	0141                	add	sp,sp,16
    80000ae6:	8082                	ret
    return 0;
    80000ae8:	4501                	li	a0,0
    80000aea:	bfe5                	j	80000ae2 <strncmp+0x32>

0000000080000aec <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000aec:	1141                	add	sp,sp,-16
    80000aee:	e422                	sd	s0,8(sp)
    80000af0:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000af2:	87aa                	mv	a5,a0
    80000af4:	86b2                	mv	a3,a2
    80000af6:	367d                	addw	a2,a2,-1
    80000af8:	00d05963          	blez	a3,80000b0a <strncpy+0x1e>
    80000afc:	0785                	add	a5,a5,1
    80000afe:	0005c703          	lbu	a4,0(a1)
    80000b02:	fee78fa3          	sb	a4,-1(a5)
    80000b06:	0585                	add	a1,a1,1
    80000b08:	f775                	bnez	a4,80000af4 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000b0a:	873e                	mv	a4,a5
    80000b0c:	9fb5                	addw	a5,a5,a3
    80000b0e:	37fd                	addw	a5,a5,-1
    80000b10:	00c05963          	blez	a2,80000b22 <strncpy+0x36>
    *s++ = 0;
    80000b14:	0705                	add	a4,a4,1
    80000b16:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000b1a:	40e786bb          	subw	a3,a5,a4
    80000b1e:	fed04be3          	bgtz	a3,80000b14 <strncpy+0x28>
  return os;
}
    80000b22:	6422                	ld	s0,8(sp)
    80000b24:	0141                	add	sp,sp,16
    80000b26:	8082                	ret

0000000080000b28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000b28:	1141                	add	sp,sp,-16
    80000b2a:	e422                	sd	s0,8(sp)
    80000b2c:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000b2e:	02c05363          	blez	a2,80000b54 <safestrcpy+0x2c>
    80000b32:	fff6069b          	addw	a3,a2,-1
    80000b36:	1682                	sll	a3,a3,0x20
    80000b38:	9281                	srl	a3,a3,0x20
    80000b3a:	96ae                	add	a3,a3,a1
    80000b3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000b3e:	00d58963          	beq	a1,a3,80000b50 <safestrcpy+0x28>
    80000b42:	0585                	add	a1,a1,1
    80000b44:	0785                	add	a5,a5,1
    80000b46:	fff5c703          	lbu	a4,-1(a1)
    80000b4a:	fee78fa3          	sb	a4,-1(a5)
    80000b4e:	fb65                	bnez	a4,80000b3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000b50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000b54:	6422                	ld	s0,8(sp)
    80000b56:	0141                	add	sp,sp,16
    80000b58:	8082                	ret

0000000080000b5a <strlen>:

int
strlen(const char *s)
{
    80000b5a:	1141                	add	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000b60:	00054783          	lbu	a5,0(a0)
    80000b64:	cf91                	beqz	a5,80000b80 <strlen+0x26>
    80000b66:	0505                	add	a0,a0,1
    80000b68:	87aa                	mv	a5,a0
    80000b6a:	86be                	mv	a3,a5
    80000b6c:	0785                	add	a5,a5,1
    80000b6e:	fff7c703          	lbu	a4,-1(a5)
    80000b72:	ff65                	bnez	a4,80000b6a <strlen+0x10>
    80000b74:	40a6853b          	subw	a0,a3,a0
    80000b78:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000b7a:	6422                	ld	s0,8(sp)
    80000b7c:	0141                	add	sp,sp,16
    80000b7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000b80:	4501                	li	a0,0
    80000b82:	bfe5                	j	80000b7a <strlen+0x20>

0000000080000b84 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000b84:	7179                	add	sp,sp,-48
    80000b86:	f406                	sd	ra,40(sp)
    80000b88:	f022                	sd	s0,32(sp)
    80000b8a:	ec26                	sd	s1,24(sp)
    80000b8c:	e84a                	sd	s2,16(sp)
    80000b8e:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000b90:	c219                	beqz	a2,80000b96 <printint+0x12>
    80000b92:	08054763          	bltz	a0,80000c20 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    80000b96:	2501                	sext.w	a0,a0
    80000b98:	4881                	li	a7,0
    80000b9a:	fd040693          	add	a3,s0,-48

  i = 0;
    80000b9e:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000ba0:	2581                	sext.w	a1,a1
    80000ba2:	00002617          	auipc	a2,0x2
    80000ba6:	66e60613          	add	a2,a2,1646 # 80003210 <digits>
    80000baa:	883a                	mv	a6,a4
    80000bac:	2705                	addw	a4,a4,1
    80000bae:	02b577bb          	remuw	a5,a0,a1
    80000bb2:	1782                	sll	a5,a5,0x20
    80000bb4:	9381                	srl	a5,a5,0x20
    80000bb6:	97b2                	add	a5,a5,a2
    80000bb8:	0007c783          	lbu	a5,0(a5)
    80000bbc:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000bc0:	0005079b          	sext.w	a5,a0
    80000bc4:	02b5553b          	divuw	a0,a0,a1
    80000bc8:	0685                	add	a3,a3,1
    80000bca:	feb7f0e3          	bgeu	a5,a1,80000baa <printint+0x26>

  if(sign)
    80000bce:	00088c63          	beqz	a7,80000be6 <printint+0x62>
    buf[i++] = '-';
    80000bd2:	fe070793          	add	a5,a4,-32
    80000bd6:	00878733          	add	a4,a5,s0
    80000bda:	02d00793          	li	a5,45
    80000bde:	fef70823          	sb	a5,-16(a4)
    80000be2:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    80000be6:	02e05763          	blez	a4,80000c14 <printint+0x90>
    80000bea:	fd040793          	add	a5,s0,-48
    80000bee:	00e784b3          	add	s1,a5,a4
    80000bf2:	fff78913          	add	s2,a5,-1
    80000bf6:	993a                	add	s2,s2,a4
    80000bf8:	377d                	addw	a4,a4,-1
    80000bfa:	1702                	sll	a4,a4,0x20
    80000bfc:	9301                	srl	a4,a4,0x20
    80000bfe:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000c02:	fff4c503          	lbu	a0,-1(s1)
    80000c06:	00000097          	auipc	ra,0x0
    80000c0a:	38c080e7          	jalr	908(ra) # 80000f92 <consputc>
  while(--i >= 0)
    80000c0e:	14fd                	add	s1,s1,-1
    80000c10:	ff2499e3          	bne	s1,s2,80000c02 <printint+0x7e>
}
    80000c14:	70a2                	ld	ra,40(sp)
    80000c16:	7402                	ld	s0,32(sp)
    80000c18:	64e2                	ld	s1,24(sp)
    80000c1a:	6942                	ld	s2,16(sp)
    80000c1c:	6145                	add	sp,sp,48
    80000c1e:	8082                	ret
    x = -xx;
    80000c20:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000c24:	4885                	li	a7,1
    x = -xx;
    80000c26:	bf95                	j	80000b9a <printint+0x16>

0000000080000c28 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000c28:	1101                	add	sp,sp,-32
    80000c2a:	ec06                	sd	ra,24(sp)
    80000c2c:	e822                	sd	s0,16(sp)
    80000c2e:	e426                	sd	s1,8(sp)
    80000c30:	1000                	add	s0,sp,32
    80000c32:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000c34:	0000a797          	auipc	a5,0xa
    80000c38:	6c07a223          	sw	zero,1732(a5) # 8000b2f8 <pr+0x18>
  printf("panic: ");
    80000c3c:	00002517          	auipc	a0,0x2
    80000c40:	5ac50513          	add	a0,a0,1452 # 800031e8 <etext+0x1e8>
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	02e080e7          	jalr	46(ra) # 80000c72 <printf>
  printf(s);
    80000c4c:	8526                	mv	a0,s1
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	024080e7          	jalr	36(ra) # 80000c72 <printf>
  printf("\n");
    80000c56:	00002517          	auipc	a0,0x2
    80000c5a:	4da50513          	add	a0,a0,1242 # 80003130 <etext+0x130>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	014080e7          	jalr	20(ra) # 80000c72 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000c66:	4785                	li	a5,1
    80000c68:	00002717          	auipc	a4,0x2
    80000c6c:	5ef72223          	sw	a5,1508(a4) # 8000324c <panicked>
  for(;;)
    80000c70:	a001                	j	80000c70 <panic+0x48>

0000000080000c72 <printf>:
{
    80000c72:	7131                	add	sp,sp,-192
    80000c74:	fc86                	sd	ra,120(sp)
    80000c76:	f8a2                	sd	s0,112(sp)
    80000c78:	f4a6                	sd	s1,104(sp)
    80000c7a:	f0ca                	sd	s2,96(sp)
    80000c7c:	ecce                	sd	s3,88(sp)
    80000c7e:	e8d2                	sd	s4,80(sp)
    80000c80:	e4d6                	sd	s5,72(sp)
    80000c82:	e0da                	sd	s6,64(sp)
    80000c84:	fc5e                	sd	s7,56(sp)
    80000c86:	f862                	sd	s8,48(sp)
    80000c88:	f466                	sd	s9,40(sp)
    80000c8a:	f06a                	sd	s10,32(sp)
    80000c8c:	ec6e                	sd	s11,24(sp)
    80000c8e:	0100                	add	s0,sp,128
    80000c90:	8a2a                	mv	s4,a0
    80000c92:	e40c                	sd	a1,8(s0)
    80000c94:	e810                	sd	a2,16(s0)
    80000c96:	ec14                	sd	a3,24(s0)
    80000c98:	f018                	sd	a4,32(s0)
    80000c9a:	f41c                	sd	a5,40(s0)
    80000c9c:	03043823          	sd	a6,48(s0)
    80000ca0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000ca4:	0000ad97          	auipc	s11,0xa
    80000ca8:	654dad83          	lw	s11,1620(s11) # 8000b2f8 <pr+0x18>
  if(locking)
    80000cac:	020d9b63          	bnez	s11,80000ce2 <printf+0x70>
  if (fmt == 0)
    80000cb0:	040a0263          	beqz	s4,80000cf4 <printf+0x82>
  va_start(ap, fmt);
    80000cb4:	00840793          	add	a5,s0,8
    80000cb8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000cbc:	000a4503          	lbu	a0,0(s4)
    80000cc0:	14050f63          	beqz	a0,80000e1e <printf+0x1ac>
    80000cc4:	4981                	li	s3,0
    if(c != '%'){
    80000cc6:	02500a93          	li	s5,37
    switch(c){
    80000cca:	07000b93          	li	s7,112
  consputc('x');
    80000cce:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000cd0:	00002b17          	auipc	s6,0x2
    80000cd4:	540b0b13          	add	s6,s6,1344 # 80003210 <digits>
    switch(c){
    80000cd8:	07300c93          	li	s9,115
    80000cdc:	06400c13          	li	s8,100
    80000ce0:	a82d                	j	80000d1a <printf+0xa8>
    acquire(&pr.lock);
    80000ce2:	0000a517          	auipc	a0,0xa
    80000ce6:	5fe50513          	add	a0,a0,1534 # 8000b2e0 <pr>
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	98c080e7          	jalr	-1652(ra) # 80000676 <acquire>
    80000cf2:	bf7d                	j	80000cb0 <printf+0x3e>
    panic("null fmt");
    80000cf4:	00002517          	auipc	a0,0x2
    80000cf8:	50450513          	add	a0,a0,1284 # 800031f8 <etext+0x1f8>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	f2c080e7          	jalr	-212(ra) # 80000c28 <panic>
      consputc(c);
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	28e080e7          	jalr	654(ra) # 80000f92 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000d0c:	2985                	addw	s3,s3,1
    80000d0e:	013a07b3          	add	a5,s4,s3
    80000d12:	0007c503          	lbu	a0,0(a5)
    80000d16:	10050463          	beqz	a0,80000e1e <printf+0x1ac>
    if(c != '%'){
    80000d1a:	ff5515e3          	bne	a0,s5,80000d04 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000d1e:	2985                	addw	s3,s3,1
    80000d20:	013a07b3          	add	a5,s4,s3
    80000d24:	0007c783          	lbu	a5,0(a5)
    80000d28:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000d2c:	cbed                	beqz	a5,80000e1e <printf+0x1ac>
    switch(c){
    80000d2e:	05778a63          	beq	a5,s7,80000d82 <printf+0x110>
    80000d32:	02fbf663          	bgeu	s7,a5,80000d5e <printf+0xec>
    80000d36:	09978863          	beq	a5,s9,80000dc6 <printf+0x154>
    80000d3a:	07800713          	li	a4,120
    80000d3e:	0ce79563          	bne	a5,a4,80000e08 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000d42:	f8843783          	ld	a5,-120(s0)
    80000d46:	00878713          	add	a4,a5,8
    80000d4a:	f8e43423          	sd	a4,-120(s0)
    80000d4e:	4605                	li	a2,1
    80000d50:	85ea                	mv	a1,s10
    80000d52:	4388                	lw	a0,0(a5)
    80000d54:	00000097          	auipc	ra,0x0
    80000d58:	e30080e7          	jalr	-464(ra) # 80000b84 <printint>
      break;
    80000d5c:	bf45                	j	80000d0c <printf+0x9a>
    switch(c){
    80000d5e:	09578f63          	beq	a5,s5,80000dfc <printf+0x18a>
    80000d62:	0b879363          	bne	a5,s8,80000e08 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000d66:	f8843783          	ld	a5,-120(s0)
    80000d6a:	00878713          	add	a4,a5,8
    80000d6e:	f8e43423          	sd	a4,-120(s0)
    80000d72:	4605                	li	a2,1
    80000d74:	45a9                	li	a1,10
    80000d76:	4388                	lw	a0,0(a5)
    80000d78:	00000097          	auipc	ra,0x0
    80000d7c:	e0c080e7          	jalr	-500(ra) # 80000b84 <printint>
      break;
    80000d80:	b771                	j	80000d0c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000d82:	f8843783          	ld	a5,-120(s0)
    80000d86:	00878713          	add	a4,a5,8
    80000d8a:	f8e43423          	sd	a4,-120(s0)
    80000d8e:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000d92:	03000513          	li	a0,48
    80000d96:	00000097          	auipc	ra,0x0
    80000d9a:	1fc080e7          	jalr	508(ra) # 80000f92 <consputc>
  consputc('x');
    80000d9e:	07800513          	li	a0,120
    80000da2:	00000097          	auipc	ra,0x0
    80000da6:	1f0080e7          	jalr	496(ra) # 80000f92 <consputc>
    80000daa:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000dac:	03c95793          	srl	a5,s2,0x3c
    80000db0:	97da                	add	a5,a5,s6
    80000db2:	0007c503          	lbu	a0,0(a5)
    80000db6:	00000097          	auipc	ra,0x0
    80000dba:	1dc080e7          	jalr	476(ra) # 80000f92 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000dbe:	0912                	sll	s2,s2,0x4
    80000dc0:	34fd                	addw	s1,s1,-1
    80000dc2:	f4ed                	bnez	s1,80000dac <printf+0x13a>
    80000dc4:	b7a1                	j	80000d0c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000dc6:	f8843783          	ld	a5,-120(s0)
    80000dca:	00878713          	add	a4,a5,8
    80000dce:	f8e43423          	sd	a4,-120(s0)
    80000dd2:	6384                	ld	s1,0(a5)
    80000dd4:	cc89                	beqz	s1,80000dee <printf+0x17c>
      for(; *s; s++)
    80000dd6:	0004c503          	lbu	a0,0(s1)
    80000dda:	d90d                	beqz	a0,80000d0c <printf+0x9a>
        consputc(*s);
    80000ddc:	00000097          	auipc	ra,0x0
    80000de0:	1b6080e7          	jalr	438(ra) # 80000f92 <consputc>
      for(; *s; s++)
    80000de4:	0485                	add	s1,s1,1
    80000de6:	0004c503          	lbu	a0,0(s1)
    80000dea:	f96d                	bnez	a0,80000ddc <printf+0x16a>
    80000dec:	b705                	j	80000d0c <printf+0x9a>
        s = "(null)";
    80000dee:	00002497          	auipc	s1,0x2
    80000df2:	40248493          	add	s1,s1,1026 # 800031f0 <etext+0x1f0>
      for(; *s; s++)
    80000df6:	02800513          	li	a0,40
    80000dfa:	b7cd                	j	80000ddc <printf+0x16a>
      consputc('%');
    80000dfc:	8556                	mv	a0,s5
    80000dfe:	00000097          	auipc	ra,0x0
    80000e02:	194080e7          	jalr	404(ra) # 80000f92 <consputc>
      break;
    80000e06:	b719                	j	80000d0c <printf+0x9a>
      consputc('%');
    80000e08:	8556                	mv	a0,s5
    80000e0a:	00000097          	auipc	ra,0x0
    80000e0e:	188080e7          	jalr	392(ra) # 80000f92 <consputc>
      consputc(c);
    80000e12:	8526                	mv	a0,s1
    80000e14:	00000097          	auipc	ra,0x0
    80000e18:	17e080e7          	jalr	382(ra) # 80000f92 <consputc>
      break;
    80000e1c:	bdc5                	j	80000d0c <printf+0x9a>
  if(locking)
    80000e1e:	020d9163          	bnez	s11,80000e40 <printf+0x1ce>
}
    80000e22:	70e6                	ld	ra,120(sp)
    80000e24:	7446                	ld	s0,112(sp)
    80000e26:	74a6                	ld	s1,104(sp)
    80000e28:	7906                	ld	s2,96(sp)
    80000e2a:	69e6                	ld	s3,88(sp)
    80000e2c:	6a46                	ld	s4,80(sp)
    80000e2e:	6aa6                	ld	s5,72(sp)
    80000e30:	6b06                	ld	s6,64(sp)
    80000e32:	7be2                	ld	s7,56(sp)
    80000e34:	7c42                	ld	s8,48(sp)
    80000e36:	7ca2                	ld	s9,40(sp)
    80000e38:	7d02                	ld	s10,32(sp)
    80000e3a:	6de2                	ld	s11,24(sp)
    80000e3c:	6129                	add	sp,sp,192
    80000e3e:	8082                	ret
    release(&pr.lock);
    80000e40:	0000a517          	auipc	a0,0xa
    80000e44:	4a050513          	add	a0,a0,1184 # 8000b2e0 <pr>
    80000e48:	00000097          	auipc	ra,0x0
    80000e4c:	8e2080e7          	jalr	-1822(ra) # 8000072a <release>
}
    80000e50:	bfc9                	j	80000e22 <printf+0x1b0>

0000000080000e52 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000e52:	1101                	add	sp,sp,-32
    80000e54:	ec06                	sd	ra,24(sp)
    80000e56:	e822                	sd	s0,16(sp)
    80000e58:	e426                	sd	s1,8(sp)
    80000e5a:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000e5c:	0000a497          	auipc	s1,0xa
    80000e60:	48448493          	add	s1,s1,1156 # 8000b2e0 <pr>
    80000e64:	00002597          	auipc	a1,0x2
    80000e68:	3a458593          	add	a1,a1,932 # 80003208 <etext+0x208>
    80000e6c:	8526                	mv	a0,s1
    80000e6e:	fffff097          	auipc	ra,0xfffff
    80000e72:	778080e7          	jalr	1912(ra) # 800005e6 <initlock>
  pr.locking = 1;
    80000e76:	4785                	li	a5,1
    80000e78:	cc9c                	sw	a5,24(s1)
}
    80000e7a:	60e2                	ld	ra,24(sp)
    80000e7c:	6442                	ld	s0,16(sp)
    80000e7e:	64a2                	ld	s1,8(sp)
    80000e80:	6105                	add	sp,sp,32
    80000e82:	8082                	ret

0000000080000e84 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000e84:	1141                	add	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000e8c:	100007b7          	lui	a5,0x10000
    80000e90:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000e94:	f8000713          	li	a4,-128
    80000e98:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000e9c:	470d                	li	a4,3
    80000e9e:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000ea2:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000ea6:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000eaa:	469d                	li	a3,7
    80000eac:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000eb0:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000eb4:	00002597          	auipc	a1,0x2
    80000eb8:	37458593          	add	a1,a1,884 # 80003228 <digits+0x18>
    80000ebc:	0000a517          	auipc	a0,0xa
    80000ec0:	44450513          	add	a0,a0,1092 # 8000b300 <uart_tx_lock>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	722080e7          	jalr	1826(ra) # 800005e6 <initlock>
}
    80000ecc:	60a2                	ld	ra,8(sp)
    80000ece:	6402                	ld	s0,0(sp)
    80000ed0:	0141                	add	sp,sp,16
    80000ed2:	8082                	ret

0000000080000ed4 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000ed4:	1101                	add	sp,sp,-32
    80000ed6:	ec06                	sd	ra,24(sp)
    80000ed8:	e822                	sd	s0,16(sp)
    80000eda:	e426                	sd	s1,8(sp)
    80000edc:	1000                	add	s0,sp,32
    80000ede:	84aa                	mv	s1,a0
  push_off();
    80000ee0:	fffff097          	auipc	ra,0xfffff
    80000ee4:	74a080e7          	jalr	1866(ra) # 8000062a <push_off>

  if(panicked){
    80000ee8:	00002797          	auipc	a5,0x2
    80000eec:	3647a783          	lw	a5,868(a5) # 8000324c <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000ef0:	10000737          	lui	a4,0x10000
  if(panicked){
    80000ef4:	c391                	beqz	a5,80000ef8 <uartputc_sync+0x24>
    for(;;)
    80000ef6:	a001                	j	80000ef6 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000ef8:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000efc:	0207f793          	and	a5,a5,32
    80000f00:	dfe5                	beqz	a5,80000ef8 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000f02:	0ff4f513          	zext.b	a0,s1
    80000f06:	100007b7          	lui	a5,0x10000
    80000f0a:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	7bc080e7          	jalr	1980(ra) # 800006ca <pop_off>
}
    80000f16:	60e2                	ld	ra,24(sp)
    80000f18:	6442                	ld	s0,16(sp)
    80000f1a:	64a2                	ld	s1,8(sp)
    80000f1c:	6105                	add	sp,sp,32
    80000f1e:	8082                	ret

0000000080000f20 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000f20:	1141                	add	sp,sp,-16
    80000f22:	e422                	sd	s0,8(sp)
    80000f24:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000f26:	100007b7          	lui	a5,0x10000
    80000f2a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000f2e:	8b85                	and	a5,a5,1
    80000f30:	cb81                	beqz	a5,80000f40 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000f32:	100007b7          	lui	a5,0x10000
    80000f36:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000f3a:	6422                	ld	s0,8(sp)
    80000f3c:	0141                	add	sp,sp,16
    80000f3e:	8082                	ret
    return -1;
    80000f40:	557d                	li	a0,-1
    80000f42:	bfe5                	j	80000f3a <uartgetc+0x1a>

0000000080000f44 <uart_putc>:
//   uartstart();
//   release(&uart_tx_lock);
// }


void uart_putc(char c) {
    80000f44:	1141                	add	sp,sp,-16
    80000f46:	e422                	sd	s0,8(sp)
    80000f48:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    80000f4a:	10000737          	lui	a4,0x10000
    80000f4e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000f52:	0207f793          	and	a5,a5,32
    80000f56:	dfe5                	beqz	a5,80000f4e <uart_putc+0xa>
    uart[0] = c;
    80000f58:	100007b7          	lui	a5,0x10000
    80000f5c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    80000f60:	6422                	ld	s0,8(sp)
    80000f62:	0141                	add	sp,sp,16
    80000f64:	8082                	ret

0000000080000f66 <uart_puts>:

void uart_puts(char *s) {
    80000f66:	1101                	add	sp,sp,-32
    80000f68:	ec06                	sd	ra,24(sp)
    80000f6a:	e822                	sd	s0,16(sp)
    80000f6c:	e426                	sd	s1,8(sp)
    80000f6e:	1000                	add	s0,sp,32
    80000f70:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000f72:	00054503          	lbu	a0,0(a0)
    80000f76:	c909                	beqz	a0,80000f88 <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	fcc080e7          	jalr	-52(ra) # 80000f44 <uart_putc>
        s++;              // 移动到下一个字符
    80000f80:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000f82:	0004c503          	lbu	a0,0(s1)
    80000f86:	f96d                	bnez	a0,80000f78 <uart_puts+0x12>
    }
}
    80000f88:	60e2                	ld	ra,24(sp)
    80000f8a:	6442                	ld	s0,16(sp)
    80000f8c:	64a2                	ld	s1,8(sp)
    80000f8e:	6105                	add	sp,sp,32
    80000f90:	8082                	ret

0000000080000f92 <consputc>:
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    80000f92:	1141                	add	sp,sp,-16
    80000f94:	e406                	sd	ra,8(sp)
    80000f96:	e022                	sd	s0,0(sp)
    80000f98:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000f9a:	10000793          	li	a5,256
    80000f9e:	00f50a63          	beq	a0,a5,80000fb2 <consputc+0x20>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    80000fa2:	00000097          	auipc	ra,0x0
    80000fa6:	f32080e7          	jalr	-206(ra) # 80000ed4 <uartputc_sync>
  }
}
    80000faa:	60a2                	ld	ra,8(sp)
    80000fac:	6402                	ld	s0,0(sp)
    80000fae:	0141                	add	sp,sp,16
    80000fb0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000fb2:	4521                	li	a0,8
    80000fb4:	00000097          	auipc	ra,0x0
    80000fb8:	f20080e7          	jalr	-224(ra) # 80000ed4 <uartputc_sync>
    80000fbc:	02000513          	li	a0,32
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	f14080e7          	jalr	-236(ra) # 80000ed4 <uartputc_sync>
    80000fc8:	4521                	li	a0,8
    80000fca:	00000097          	auipc	ra,0x0
    80000fce:	f0a080e7          	jalr	-246(ra) # 80000ed4 <uartputc_sync>
    80000fd2:	bfe1                	j	80000faa <consputc+0x18>

0000000080000fd4 <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    80000fd4:	1141                	add	sp,sp,-16
    80000fd6:	e406                	sd	ra,8(sp)
    80000fd8:	e022                	sd	s0,0(sp)
    80000fda:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000fdc:	00002597          	auipc	a1,0x2
    80000fe0:	25458593          	add	a1,a1,596 # 80003230 <digits+0x20>
    80000fe4:	0000a517          	auipc	a0,0xa
    80000fe8:	35450513          	add	a0,a0,852 # 8000b338 <cons>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	5fa080e7          	jalr	1530(ra) # 800005e6 <initlock>

  uartinit();
    80000ff4:	00000097          	auipc	ra,0x0
    80000ff8:	e90080e7          	jalr	-368(ra) # 80000e84 <uartinit>

  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    80000ffc:	60a2                	ld	ra,8(sp)
    80000ffe:	6402                	ld	s0,0(sp)
    80001000:	0141                	add	sp,sp,16
    80001002:	8082                	ret
	...

0000000080002000 <_trampoline>:
    80002000:	14051073          	csrw	sscratch,a0
    80002004:	02000537          	lui	a0,0x2000
    80002008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000200a:	0536                	sll	a0,a0,0xd
    8000200c:	02153423          	sd	ra,40(a0)
    80002010:	02253823          	sd	sp,48(a0)
    80002014:	02353c23          	sd	gp,56(a0)
    80002018:	04453023          	sd	tp,64(a0)
    8000201c:	04553423          	sd	t0,72(a0)
    80002020:	04653823          	sd	t1,80(a0)
    80002024:	04753c23          	sd	t2,88(a0)
    80002028:	f120                	sd	s0,96(a0)
    8000202a:	f524                	sd	s1,104(a0)
    8000202c:	fd2c                	sd	a1,120(a0)
    8000202e:	e150                	sd	a2,128(a0)
    80002030:	e554                	sd	a3,136(a0)
    80002032:	e958                	sd	a4,144(a0)
    80002034:	ed5c                	sd	a5,152(a0)
    80002036:	0b053023          	sd	a6,160(a0)
    8000203a:	0b153423          	sd	a7,168(a0)
    8000203e:	0b253823          	sd	s2,176(a0)
    80002042:	0b353c23          	sd	s3,184(a0)
    80002046:	0d453023          	sd	s4,192(a0)
    8000204a:	0d553423          	sd	s5,200(a0)
    8000204e:	0d653823          	sd	s6,208(a0)
    80002052:	0d753c23          	sd	s7,216(a0)
    80002056:	0f853023          	sd	s8,224(a0)
    8000205a:	0f953423          	sd	s9,232(a0)
    8000205e:	0fa53823          	sd	s10,240(a0)
    80002062:	0fb53c23          	sd	s11,248(a0)
    80002066:	11c53023          	sd	t3,256(a0)
    8000206a:	11d53423          	sd	t4,264(a0)
    8000206e:	11e53823          	sd	t5,272(a0)
    80002072:	11f53c23          	sd	t6,280(a0)
    80002076:	140022f3          	csrr	t0,sscratch
    8000207a:	06553823          	sd	t0,112(a0)
    8000207e:	00853103          	ld	sp,8(a0)
    80002082:	02053203          	ld	tp,32(a0)
    80002086:	01053283          	ld	t0,16(a0)
    8000208a:	00053303          	ld	t1,0(a0)
    8000208e:	12000073          	sfence.vma
    80002092:	18031073          	csrw	satp,t1
    80002096:	12000073          	sfence.vma
    8000209a:	9282                	jalr	t0

000000008000209c <userret>:
    8000209c:	12000073          	sfence.vma
    800020a0:	18051073          	csrw	satp,a0
    800020a4:	12000073          	sfence.vma
    800020a8:	02000537          	lui	a0,0x2000
    800020ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800020ae:	0536                	sll	a0,a0,0xd
    800020b0:	02853083          	ld	ra,40(a0)
    800020b4:	03053103          	ld	sp,48(a0)
    800020b8:	03853183          	ld	gp,56(a0)
    800020bc:	04053203          	ld	tp,64(a0)
    800020c0:	04853283          	ld	t0,72(a0)
    800020c4:	05053303          	ld	t1,80(a0)
    800020c8:	05853383          	ld	t2,88(a0)
    800020cc:	7120                	ld	s0,96(a0)
    800020ce:	7524                	ld	s1,104(a0)
    800020d0:	7d2c                	ld	a1,120(a0)
    800020d2:	6150                	ld	a2,128(a0)
    800020d4:	6554                	ld	a3,136(a0)
    800020d6:	6958                	ld	a4,144(a0)
    800020d8:	6d5c                	ld	a5,152(a0)
    800020da:	0a053803          	ld	a6,160(a0)
    800020de:	0a853883          	ld	a7,168(a0)
    800020e2:	0b053903          	ld	s2,176(a0)
    800020e6:	0b853983          	ld	s3,184(a0)
    800020ea:	0c053a03          	ld	s4,192(a0)
    800020ee:	0c853a83          	ld	s5,200(a0)
    800020f2:	0d053b03          	ld	s6,208(a0)
    800020f6:	0d853b83          	ld	s7,216(a0)
    800020fa:	0e053c03          	ld	s8,224(a0)
    800020fe:	0e853c83          	ld	s9,232(a0)
    80002102:	0f053d03          	ld	s10,240(a0)
    80002106:	0f853d83          	ld	s11,248(a0)
    8000210a:	10053e03          	ld	t3,256(a0)
    8000210e:	10853e83          	ld	t4,264(a0)
    80002112:	11053f03          	ld	t5,272(a0)
    80002116:	11853f83          	ld	t6,280(a0)
    8000211a:	7928                	ld	a0,112(a0)
    8000211c:	10200073          	sret
	...
