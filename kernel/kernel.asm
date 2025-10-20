
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
    80000004:	69010113          	add	sp,sp,1680 # 80003690 <stack0>
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
    8000001a:	21a50513          	add	a0,a0,538 # 80003230 <kernel_pagetable>
    la a1, end
    8000001e:	0000c597          	auipc	a1,0xc
    80000022:	8d258593          	add	a1,a1,-1838 # 8000b8f0 <end>

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
    80000034:	924080e7          	jalr	-1756(ra) # 80000954 <start>

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
    8000004e:	0000c797          	auipc	a5,0xc
    80000052:	8a278793          	add	a5,a5,-1886 # 8000b8f0 <end>
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
    8000006a:	962080e7          	jalr	-1694(ra) # 800009c8 <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    8000006e:	00003917          	auipc	s2,0x3
    80000072:	1e290913          	add	s2,s2,482 # 80003250 <kmem>
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
    800000ac:	b68080e7          	jalr	-1176(ra) # 80000c10 <panic>

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
    80000112:	14250513          	add	a0,a0,322 # 80003250 <kmem>
    80000116:	00000097          	auipc	ra,0x0
    8000011a:	4d0080e7          	jalr	1232(ra) # 800005e6 <initlock>
  freerange(end, (void*)PHYSTOP);
    8000011e:	45c5                	li	a1,17
    80000120:	05ee                	sll	a1,a1,0x1b
    80000122:	0000b517          	auipc	a0,0xb
    80000126:	7ce50513          	add	a0,a0,1998 # 8000b8f0 <end>
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
    80000148:	10c48493          	add	s1,s1,268 # 80003250 <kmem>
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
    80000160:	0f450513          	add	a0,a0,244 # 80003250 <kmem>
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
    80000178:	854080e7          	jalr	-1964(ra) # 800009c8 <memset>
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
    8000018c:	0c850513          	add	a0,a0,200 # 80003250 <kmem>
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
    800001a8:	08c7b783          	ld	a5,140(a5) # 80003230 <kernel_pagetable>
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
    800001f4:	a20080e7          	jalr	-1504(ra) # 80000c10 <panic>
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
    80000212:	7ba080e7          	jalr	1978(ra) # 800009c8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    80000216:	00c4d793          	srl	a5,s1,0xc
    8000021a:	07aa                	sll	a5,a5,0xa
    8000021c:	0017e793          	or	a5,a5,1
    80000220:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000224:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fff3707>
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
    800002de:	936080e7          	jalr	-1738(ra) # 80000c10 <panic>
    panic("mappages: size not aligned");
    800002e2:	00003517          	auipc	a0,0x3
    800002e6:	d5650513          	add	a0,a0,-682 # 80003038 <etext+0x38>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	926080e7          	jalr	-1754(ra) # 80000c10 <panic>
    panic("mappages: size");
    800002f2:	00003517          	auipc	a0,0x3
    800002f6:	d6650513          	add	a0,a0,-666 # 80003058 <etext+0x58>
    800002fa:	00001097          	auipc	ra,0x1
    800002fe:	916080e7          	jalr	-1770(ra) # 80000c10 <panic>
      panic("mappages: remap");
    80000302:	00003517          	auipc	a0,0x3
    80000306:	d6650513          	add	a0,a0,-666 # 80003068 <etext+0x68>
    8000030a:	00001097          	auipc	ra,0x1
    8000030e:	906080e7          	jalr	-1786(ra) # 80000c10 <panic>
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
    8000035a:	8ba080e7          	jalr	-1862(ra) # 80000c10 <panic>

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
    8000037e:	64e080e7          	jalr	1614(ra) # 800009c8 <memset>
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
    80000440:	dea7ba23          	sd	a0,-524(a5) # 80003230 <kernel_pagetable>
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
    80000492:	d2250513          	add	a0,a0,-734 # 800031b0 <etext+0x1b0>
    80000496:	00000097          	auipc	ra,0x0
    8000049a:	7c4080e7          	jalr	1988(ra) # 80000c5a <printf>
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
    800004ca:	794080e7          	jalr	1940(ra) # 80000c5a <printf>
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
    800004e6:	778080e7          	jalr	1912(ra) # 80000c5a <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    800004ea:	00e97913          	and	s2,s2,14
    800004ee:	fa0900e3          	beqz	s2,8000048e <print_pgtbl+0x42>
        printf(" [leaf]\n");
    800004f2:	856a                	mv	a0,s10
    800004f4:	00000097          	auipc	ra,0x0
    800004f8:	766080e7          	jalr	1894(ra) # 80000c5a <printf>
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
    80000540:	71e080e7          	jalr	1822(ra) # 80000c5a <printf>
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
    80000552:	c62b8b93          	add	s7,s7,-926 # 800031b0 <etext+0x1b0>
        printf(" [leaf]\n");
    80000556:	00003b17          	auipc	s6,0x3
    8000055a:	b4ab0b13          	add	s6,s6,-1206 # 800030a0 <etext+0xa0>
  for(int i = 0; i < 512; i++) { // 512个页表项
    8000055e:	20000a13          	li	s4,512
    80000562:	a811                	j	80000576 <print_cur_pgtbl+0x5c>
        printf("\n");
    80000564:	855e                	mv	a0,s7
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	6f4080e7          	jalr	1780(ra) # 80000c5a <printf>
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
    80000590:	6ce080e7          	jalr	1742(ra) # 80000c5a <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000594:	88b9                	and	s1,s1,14
    80000596:	d4f9                	beqz	s1,80000564 <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80000598:	855a                	mv	a0,s6
    8000059a:	00000097          	auipc	ra,0x0
    8000059e:	6c0080e7          	jalr	1728(ra) # 80000c5a <printf>
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
    800005d4:	079e                	sll	a5,a5,0x7
  return c;
}
    800005d6:	00003517          	auipc	a0,0x3
    800005da:	c9a50513          	add	a0,a0,-870 # 80003270 <cpus>
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
    8000064a:	5d3c                	lw	a5,120(a0)
    8000064c:	cf89                	beqz	a5,80000666 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	f7c080e7          	jalr	-132(ra) # 800005ca <mycpu>
    80000656:	5d3c                	lw	a5,120(a0)
    80000658:	2785                	addw	a5,a5,1
    8000065a:	dd3c                	sw	a5,120(a0)
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
    80000672:	dd64                	sw	s1,124(a0)
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
    800006c6:	54e080e7          	jalr	1358(ra) # 80000c10 <panic>

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
    800006e2:	5d3c                	lw	a5,120(a0)
    800006e4:	02f05b63          	blez	a5,8000071a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    800006e8:	37fd                	addw	a5,a5,-1
    800006ea:	0007871b          	sext.w	a4,a5
    800006ee:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    800006f0:	eb09                	bnez	a4,80000702 <pop_off+0x38>
    800006f2:	5d7c                	lw	a5,124(a0)
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
    80000716:	4fe080e7          	jalr	1278(ra) # 80000c10 <panic>
    panic("pop_off");
    8000071a:	00003517          	auipc	a0,0x3
    8000071e:	9e650513          	add	a0,a0,-1562 # 80003100 <etext+0x100>
    80000722:	00000097          	auipc	ra,0x0
    80000726:	4ee080e7          	jalr	1262(ra) # 80000c10 <panic>

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
    8000076e:	4a6080e7          	jalr	1190(ra) # 80000c10 <panic>

0000000080000772 <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    80000772:	1141                	add	sp,sp,-16
    80000774:	e422                	sd	s0,8(sp)
    80000776:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80000778:	00001797          	auipc	a5,0x1
    8000077c:	a1878793          	add	a5,a5,-1512 # 80001190 <kernelvec>
    80000780:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    80000784:	6422                	ld	s0,8(sp)
    80000786:	0141                	add	sp,sp,16
    80000788:	8082                	ret

000000008000078a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000078a:	14202773          	csrr	a4,scause
  //   if(irq)
  //     plic_complete(irq);

  //   return 1;
  // } else 
  if(scause == 0x8000000000000001L){
    8000078e:	57fd                	li	a5,-1
    80000790:	17fe                	sll	a5,a5,0x3f
    80000792:	0785                	add	a5,a5,1
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    80000794:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    80000796:	00f70363          	beq	a4,a5,8000079c <devintr+0x12>
  }
}
    8000079a:	8082                	ret
{
    8000079c:	1141                	add	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	add	s0,sp,16
    if(cpuid() == 0){
    800007a4:	00000097          	auipc	ra,0x0
    800007a8:	e16080e7          	jalr	-490(ra) # 800005ba <cpuid>
    800007ac:	c919                	beqz	a0,800007c2 <devintr+0x38>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800007ae:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800007b2:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800007b4:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    800007b8:	4509                	li	a0,2
}
    800007ba:	60a2                	ld	ra,8(sp)
    800007bc:	6402                	ld	s0,0(sp)
    800007be:	0141                	add	sp,sp,16
    800007c0:	8082                	ret
      timer_update();
    800007c2:	00000097          	auipc	ra,0x0
    800007c6:	74a080e7          	jalr	1866(ra) # 80000f0c <timer_update>
    800007ca:	b7d5                	j	800007ae <devintr+0x24>

00000000800007cc <kerneltrap>:
{
    800007cc:	7179                	add	sp,sp,-48
    800007ce:	f406                	sd	ra,40(sp)
    800007d0:	f022                	sd	s0,32(sp)
    800007d2:	ec26                	sd	s1,24(sp)
    800007d4:	e84a                	sd	s2,16(sp)
    800007d6:	e44e                	sd	s3,8(sp)
    800007d8:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800007da:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800007de:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800007e2:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800007e6:	1004f793          	and	a5,s1,256
    800007ea:	c78d                	beqz	a5,80000814 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800007ec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800007f0:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    800007f2:	eb8d                	bnez	a5,80000824 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	f96080e7          	jalr	-106(ra) # 8000078a <devintr>
    800007fc:	cd05                	beqz	a0,80000834 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800007fe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000802:	10049073          	csrw	sstatus,s1
}
    80000806:	70a2                	ld	ra,40(sp)
    80000808:	7402                	ld	s0,32(sp)
    8000080a:	64e2                	ld	s1,24(sp)
    8000080c:	6942                	ld	s2,16(sp)
    8000080e:	69a2                	ld	s3,8(sp)
    80000810:	6145                	add	sp,sp,48
    80000812:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80000814:	00003517          	auipc	a0,0x3
    80000818:	8fc50513          	add	a0,a0,-1796 # 80003110 <etext+0x110>
    8000081c:	00000097          	auipc	ra,0x0
    80000820:	3f4080e7          	jalr	1012(ra) # 80000c10 <panic>
    panic("kerneltrap: interrupts enabled");
    80000824:	00003517          	auipc	a0,0x3
    80000828:	91450513          	add	a0,a0,-1772 # 80003138 <etext+0x138>
    8000082c:	00000097          	auipc	ra,0x0
    80000830:	3e4080e7          	jalr	996(ra) # 80000c10 <panic>
    printf("scause %p\n", scause);
    80000834:	85ce                	mv	a1,s3
    80000836:	00003517          	auipc	a0,0x3
    8000083a:	92250513          	add	a0,a0,-1758 # 80003158 <etext+0x158>
    8000083e:	00000097          	auipc	ra,0x0
    80000842:	41c080e7          	jalr	1052(ra) # 80000c5a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80000846:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000084a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000084e:	00003517          	auipc	a0,0x3
    80000852:	91a50513          	add	a0,a0,-1766 # 80003168 <etext+0x168>
    80000856:	00000097          	auipc	ra,0x0
    8000085a:	404080e7          	jalr	1028(ra) # 80000c5a <printf>
    panic("kerneltrap");
    8000085e:	00003517          	auipc	a0,0x3
    80000862:	92250513          	add	a0,a0,-1758 # 80003180 <etext+0x180>
    80000866:	00000097          	auipc	ra,0x0
    8000086a:	3aa080e7          	jalr	938(ra) # 80000c10 <panic>

000000008000086e <main>:
struct spinlock start_lock;

// start()函数在管理者模式下跳转到此处，所有CPU都会执行
void
main()
{
    8000086e:	1141                	add	sp,sp,-16
    80000870:	e406                	sd	ra,8(sp)
    80000872:	e022                	sd	s0,0(sp)
    80000874:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	d44080e7          	jalr	-700(ra) # 800005ba <cpuid>
    // userinit();          // 创建第一个用户进程
    __sync_synchronize();
    started = 1;         // 标记系统启动完成
  } else {
    // 其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000087e:	00003717          	auipc	a4,0x3
    80000882:	9ba70713          	add	a4,a4,-1606 # 80003238 <started>
  if(cpuid() == 0){
    80000886:	c131                	beqz	a0,800008ca <main+0x5c>
    while(started == 0)
    80000888:	431c                	lw	a5,0(a4)
    8000088a:	2781                	sext.w	a5,a5
    8000088c:	dff5                	beqz	a5,80000888 <main+0x1a>
      ;
    
    __sync_synchronize();
    8000088e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000892:	00000097          	auipc	ra,0x0
    80000896:	d28080e7          	jalr	-728(ra) # 800005ba <cpuid>
    8000089a:	85aa                	mv	a1,a0
    8000089c:	00003517          	auipc	a0,0x3
    800008a0:	90450513          	add	a0,a0,-1788 # 800031a0 <etext+0x1a0>
    800008a4:	00000097          	auipc	ra,0x0
    800008a8:	3b6080e7          	jalr	950(ra) # 80000c5a <printf>
    kvminithart();       // 开启分页机制
    800008ac:	00000097          	auipc	ra,0x0
    800008b0:	8ee080e7          	jalr	-1810(ra) # 8000019a <kvminithart>
    trapinithart();   // 安装内核陷阱向量
    800008b4:	00000097          	auipc	ra,0x0
    800008b8:	ebe080e7          	jalr	-322(ra) # 80000772 <trapinithart>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800008bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800008c0:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800008c4:	10079073          	csrw	sstatus,a5
    // plicinithart();   // 向PLIC请求设备中断
  }
  intr_on();          // 启用中断
  // // 所有CPU都进入调度器，开始调度用户进程
  //  scheduler();  
  for(;;){}      
    800008c8:	a001                	j	800008c8 <main+0x5a>
    initlock(&start_lock,"start_lock");
    800008ca:	00003597          	auipc	a1,0x3
    800008ce:	8c658593          	add	a1,a1,-1850 # 80003190 <etext+0x190>
    800008d2:	00003517          	auipc	a0,0x3
    800008d6:	d9e50513          	add	a0,a0,-610 # 80003670 <start_lock>
    800008da:	00000097          	auipc	ra,0x0
    800008de:	d0c080e7          	jalr	-756(ra) # 800005e6 <initlock>
    consoleinit();       // 初始化控制台
    800008e2:	00001097          	auipc	ra,0x1
    800008e6:	80e080e7          	jalr	-2034(ra) # 800010f0 <consoleinit>
    printfinit();        // 初始化printf功能
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	550080e7          	jalr	1360(ra) # 80000e3a <printfinit>
    printf("\n");
    800008f2:	00003517          	auipc	a0,0x3
    800008f6:	8be50513          	add	a0,a0,-1858 # 800031b0 <etext+0x1b0>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	360080e7          	jalr	864(ra) # 80000c5a <printf>
    printf("hart %d starting\n", cpuid());
    80000902:	00000097          	auipc	ra,0x0
    80000906:	cb8080e7          	jalr	-840(ra) # 800005ba <cpuid>
    8000090a:	85aa                	mv	a1,a0
    8000090c:	00003517          	auipc	a0,0x3
    80000910:	89450513          	add	a0,a0,-1900 # 800031a0 <etext+0x1a0>
    80000914:	00000097          	auipc	ra,0x0
    80000918:	346080e7          	jalr	838(ra) # 80000c5a <printf>
    kinit();             // 物理页面分配器初始化
    8000091c:	fffff097          	auipc	ra,0xfffff
    80000920:	7e2080e7          	jalr	2018(ra) # 800000fe <kinit>
    kvminit();           // 创建内核页表
    80000924:	00000097          	auipc	ra,0x0
    80000928:	b08080e7          	jalr	-1272(ra) # 8000042c <kvminit>
    kvminithart();       // 开启分页机制
    8000092c:	00000097          	auipc	ra,0x0
    80000930:	86e080e7          	jalr	-1938(ra) # 8000019a <kvminithart>
    timer_create();           // 陷阱向量(时钟中断）初始化
    80000934:	00000097          	auipc	ra,0x0
    80000938:	5a8080e7          	jalr	1448(ra) # 80000edc <timer_create>
    trapinithart();      // 安装内核陷阱向量
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	e36080e7          	jalr	-458(ra) # 80000772 <trapinithart>
    __sync_synchronize();
    80000944:	0ff0000f          	fence
    started = 1;         // 标记系统启动完成
    80000948:	4785                	li	a5,1
    8000094a:	00003717          	auipc	a4,0x3
    8000094e:	8ef72723          	sw	a5,-1810(a4) # 80003238 <started>
    80000952:	b7ad                	j	800008bc <main+0x4e>

0000000080000954 <start>:
extern void main();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];


void start() {
    80000954:	1141                	add	sp,sp,-16
    80000956:	e406                	sd	ra,8(sp)
    80000958:	e022                	sd	s0,0(sp)
    8000095a:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000095c:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    80000960:	7779                	lui	a4,0xffffe
    80000962:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fff2f0f>
    80000966:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    80000968:	6705                	lui	a4,0x1
    8000096a:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000096e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000970:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000974:	00000797          	auipc	a5,0x0
    80000978:	efa78793          	add	a5,a5,-262 # 8000086e <main>
    8000097c:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80000980:	4781                	li	a5,0
    80000982:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000986:	67c1                	lui	a5,0x10
    80000988:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    8000098a:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000098e:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000992:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000996:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    8000099a:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    8000099e:	57fd                	li	a5,-1
    800009a0:	83a9                	srl	a5,a5,0xa
    800009a2:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800009a6:	47bd                	li	a5,15
    800009a8:	3a079073          	csrw	pmpcfg0,a5
  w_pmpaddr0(0x3fffffffffffffull);  // 设置PMP地址范围
  w_pmpcfg0(0xf);                   // 设置PMP配置(读写执行权限)

  
  // 请求时钟中断服务
  timer_init();
    800009ac:	00000097          	auipc	ra,0x0
    800009b0:	4c0080e7          	jalr	1216(ra) # 80000e6c <timer_init>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800009b4:	f14027f3          	csrr	a5,mhartid

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    800009b8:	2781                	sext.w	a5,a5
  asm volatile("mv tp, %0" : : "r" (x));
    800009ba:	823e                	mv	tp,a5


  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    800009bc:	30200073          	mret
}
    800009c0:	60a2                	ld	ra,8(sp)
    800009c2:	6402                	ld	s0,0(sp)
    800009c4:	0141                	add	sp,sp,16
    800009c6:	8082                	ret

00000000800009c8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800009c8:	1141                	add	sp,sp,-16
    800009ca:	e422                	sd	s0,8(sp)
    800009cc:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800009ce:	ca19                	beqz	a2,800009e4 <memset+0x1c>
    800009d0:	87aa                	mv	a5,a0
    800009d2:	1602                	sll	a2,a2,0x20
    800009d4:	9201                	srl	a2,a2,0x20
    800009d6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800009da:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800009de:	0785                	add	a5,a5,1
    800009e0:	fee79de3          	bne	a5,a4,800009da <memset+0x12>
  }
  return dst;
}
    800009e4:	6422                	ld	s0,8(sp)
    800009e6:	0141                	add	sp,sp,16
    800009e8:	8082                	ret

00000000800009ea <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800009ea:	1141                	add	sp,sp,-16
    800009ec:	e422                	sd	s0,8(sp)
    800009ee:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800009f0:	ca05                	beqz	a2,80000a20 <memcmp+0x36>
    800009f2:	fff6069b          	addw	a3,a2,-1
    800009f6:	1682                	sll	a3,a3,0x20
    800009f8:	9281                	srl	a3,a3,0x20
    800009fa:	0685                	add	a3,a3,1 # 1001 <_entry-0x7fffefff>
    800009fc:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    800009fe:	00054783          	lbu	a5,0(a0)
    80000a02:	0005c703          	lbu	a4,0(a1)
    80000a06:	00e79863          	bne	a5,a4,80000a16 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000a0a:	0505                	add	a0,a0,1
    80000a0c:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000a0e:	fed518e3          	bne	a0,a3,800009fe <memcmp+0x14>
  }

  return 0;
    80000a12:	4501                	li	a0,0
    80000a14:	a019                	j	80000a1a <memcmp+0x30>
      return *s1 - *s2;
    80000a16:	40e7853b          	subw	a0,a5,a4
}
    80000a1a:	6422                	ld	s0,8(sp)
    80000a1c:	0141                	add	sp,sp,16
    80000a1e:	8082                	ret
  return 0;
    80000a20:	4501                	li	a0,0
    80000a22:	bfe5                	j	80000a1a <memcmp+0x30>

0000000080000a24 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000a24:	1141                	add	sp,sp,-16
    80000a26:	e422                	sd	s0,8(sp)
    80000a28:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000a2a:	c205                	beqz	a2,80000a4a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000a2c:	02a5e263          	bltu	a1,a0,80000a50 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000a30:	1602                	sll	a2,a2,0x20
    80000a32:	9201                	srl	a2,a2,0x20
    80000a34:	00c587b3          	add	a5,a1,a2
{
    80000a38:	872a                	mv	a4,a0
      *d++ = *s++;
    80000a3a:	0585                	add	a1,a1,1
    80000a3c:	0705                	add	a4,a4,1
    80000a3e:	fff5c683          	lbu	a3,-1(a1)
    80000a42:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000a46:	fef59ae3          	bne	a1,a5,80000a3a <memmove+0x16>

  return dst;
}
    80000a4a:	6422                	ld	s0,8(sp)
    80000a4c:	0141                	add	sp,sp,16
    80000a4e:	8082                	ret
  if(s < d && s + n > d){
    80000a50:	02061693          	sll	a3,a2,0x20
    80000a54:	9281                	srl	a3,a3,0x20
    80000a56:	00d58733          	add	a4,a1,a3
    80000a5a:	fce57be3          	bgeu	a0,a4,80000a30 <memmove+0xc>
    d += n;
    80000a5e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000a60:	fff6079b          	addw	a5,a2,-1
    80000a64:	1782                	sll	a5,a5,0x20
    80000a66:	9381                	srl	a5,a5,0x20
    80000a68:	fff7c793          	not	a5,a5
    80000a6c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000a6e:	177d                	add	a4,a4,-1
    80000a70:	16fd                	add	a3,a3,-1
    80000a72:	00074603          	lbu	a2,0(a4)
    80000a76:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000a7a:	fee79ae3          	bne	a5,a4,80000a6e <memmove+0x4a>
    80000a7e:	b7f1                	j	80000a4a <memmove+0x26>

0000000080000a80 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000a80:	1141                	add	sp,sp,-16
    80000a82:	e406                	sd	ra,8(sp)
    80000a84:	e022                	sd	s0,0(sp)
    80000a86:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f9c080e7          	jalr	-100(ra) # 80000a24 <memmove>
}
    80000a90:	60a2                	ld	ra,8(sp)
    80000a92:	6402                	ld	s0,0(sp)
    80000a94:	0141                	add	sp,sp,16
    80000a96:	8082                	ret

0000000080000a98 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000a98:	1141                	add	sp,sp,-16
    80000a9a:	e422                	sd	s0,8(sp)
    80000a9c:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000a9e:	ce11                	beqz	a2,80000aba <strncmp+0x22>
    80000aa0:	00054783          	lbu	a5,0(a0)
    80000aa4:	cf89                	beqz	a5,80000abe <strncmp+0x26>
    80000aa6:	0005c703          	lbu	a4,0(a1)
    80000aaa:	00f71a63          	bne	a4,a5,80000abe <strncmp+0x26>
    n--, p++, q++;
    80000aae:	367d                	addw	a2,a2,-1
    80000ab0:	0505                	add	a0,a0,1
    80000ab2:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ab4:	f675                	bnez	a2,80000aa0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ab6:	4501                	li	a0,0
    80000ab8:	a809                	j	80000aca <strncmp+0x32>
    80000aba:	4501                	li	a0,0
    80000abc:	a039                	j	80000aca <strncmp+0x32>
  if(n == 0)
    80000abe:	ca09                	beqz	a2,80000ad0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ac0:	00054503          	lbu	a0,0(a0)
    80000ac4:	0005c783          	lbu	a5,0(a1)
    80000ac8:	9d1d                	subw	a0,a0,a5
}
    80000aca:	6422                	ld	s0,8(sp)
    80000acc:	0141                	add	sp,sp,16
    80000ace:	8082                	ret
    return 0;
    80000ad0:	4501                	li	a0,0
    80000ad2:	bfe5                	j	80000aca <strncmp+0x32>

0000000080000ad4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ad4:	1141                	add	sp,sp,-16
    80000ad6:	e422                	sd	s0,8(sp)
    80000ad8:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ada:	87aa                	mv	a5,a0
    80000adc:	86b2                	mv	a3,a2
    80000ade:	367d                	addw	a2,a2,-1
    80000ae0:	00d05963          	blez	a3,80000af2 <strncpy+0x1e>
    80000ae4:	0785                	add	a5,a5,1
    80000ae6:	0005c703          	lbu	a4,0(a1)
    80000aea:	fee78fa3          	sb	a4,-1(a5)
    80000aee:	0585                	add	a1,a1,1
    80000af0:	f775                	bnez	a4,80000adc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000af2:	873e                	mv	a4,a5
    80000af4:	9fb5                	addw	a5,a5,a3
    80000af6:	37fd                	addw	a5,a5,-1
    80000af8:	00c05963          	blez	a2,80000b0a <strncpy+0x36>
    *s++ = 0;
    80000afc:	0705                	add	a4,a4,1
    80000afe:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000b02:	40e786bb          	subw	a3,a5,a4
    80000b06:	fed04be3          	bgtz	a3,80000afc <strncpy+0x28>
  return os;
}
    80000b0a:	6422                	ld	s0,8(sp)
    80000b0c:	0141                	add	sp,sp,16
    80000b0e:	8082                	ret

0000000080000b10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000b10:	1141                	add	sp,sp,-16
    80000b12:	e422                	sd	s0,8(sp)
    80000b14:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000b16:	02c05363          	blez	a2,80000b3c <safestrcpy+0x2c>
    80000b1a:	fff6069b          	addw	a3,a2,-1
    80000b1e:	1682                	sll	a3,a3,0x20
    80000b20:	9281                	srl	a3,a3,0x20
    80000b22:	96ae                	add	a3,a3,a1
    80000b24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000b26:	00d58963          	beq	a1,a3,80000b38 <safestrcpy+0x28>
    80000b2a:	0585                	add	a1,a1,1
    80000b2c:	0785                	add	a5,a5,1
    80000b2e:	fff5c703          	lbu	a4,-1(a1)
    80000b32:	fee78fa3          	sb	a4,-1(a5)
    80000b36:	fb65                	bnez	a4,80000b26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000b38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000b3c:	6422                	ld	s0,8(sp)
    80000b3e:	0141                	add	sp,sp,16
    80000b40:	8082                	ret

0000000080000b42 <strlen>:

int
strlen(const char *s)
{
    80000b42:	1141                	add	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000b48:	00054783          	lbu	a5,0(a0)
    80000b4c:	cf91                	beqz	a5,80000b68 <strlen+0x26>
    80000b4e:	0505                	add	a0,a0,1
    80000b50:	87aa                	mv	a5,a0
    80000b52:	86be                	mv	a3,a5
    80000b54:	0785                	add	a5,a5,1
    80000b56:	fff7c703          	lbu	a4,-1(a5)
    80000b5a:	ff65                	bnez	a4,80000b52 <strlen+0x10>
    80000b5c:	40a6853b          	subw	a0,a3,a0
    80000b60:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000b62:	6422                	ld	s0,8(sp)
    80000b64:	0141                	add	sp,sp,16
    80000b66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000b68:	4501                	li	a0,0
    80000b6a:	bfe5                	j	80000b62 <strlen+0x20>

0000000080000b6c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000b6c:	7179                	add	sp,sp,-48
    80000b6e:	f406                	sd	ra,40(sp)
    80000b70:	f022                	sd	s0,32(sp)
    80000b72:	ec26                	sd	s1,24(sp)
    80000b74:	e84a                	sd	s2,16(sp)
    80000b76:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000b78:	c219                	beqz	a2,80000b7e <printint+0x12>
    80000b7a:	08054763          	bltz	a0,80000c08 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    80000b7e:	2501                	sext.w	a0,a0
    80000b80:	4881                	li	a7,0
    80000b82:	fd040693          	add	a3,s0,-48

  i = 0;
    80000b86:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000b88:	2581                	sext.w	a1,a1
    80000b8a:	00002617          	auipc	a2,0x2
    80000b8e:	65660613          	add	a2,a2,1622 # 800031e0 <digits>
    80000b92:	883a                	mv	a6,a4
    80000b94:	2705                	addw	a4,a4,1
    80000b96:	02b577bb          	remuw	a5,a0,a1
    80000b9a:	1782                	sll	a5,a5,0x20
    80000b9c:	9381                	srl	a5,a5,0x20
    80000b9e:	97b2                	add	a5,a5,a2
    80000ba0:	0007c783          	lbu	a5,0(a5)
    80000ba4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000ba8:	0005079b          	sext.w	a5,a0
    80000bac:	02b5553b          	divuw	a0,a0,a1
    80000bb0:	0685                	add	a3,a3,1
    80000bb2:	feb7f0e3          	bgeu	a5,a1,80000b92 <printint+0x26>

  if(sign)
    80000bb6:	00088c63          	beqz	a7,80000bce <printint+0x62>
    buf[i++] = '-';
    80000bba:	fe070793          	add	a5,a4,-32
    80000bbe:	00878733          	add	a4,a5,s0
    80000bc2:	02d00793          	li	a5,45
    80000bc6:	fef70823          	sb	a5,-16(a4)
    80000bca:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    80000bce:	02e05763          	blez	a4,80000bfc <printint+0x90>
    80000bd2:	fd040793          	add	a5,s0,-48
    80000bd6:	00e784b3          	add	s1,a5,a4
    80000bda:	fff78913          	add	s2,a5,-1
    80000bde:	993a                	add	s2,s2,a4
    80000be0:	377d                	addw	a4,a4,-1
    80000be2:	1702                	sll	a4,a4,0x20
    80000be4:	9301                	srl	a4,a4,0x20
    80000be6:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000bea:	fff4c503          	lbu	a0,-1(s1)
    80000bee:	00000097          	auipc	ra,0x0
    80000bf2:	4c0080e7          	jalr	1216(ra) # 800010ae <consputc>
  while(--i >= 0)
    80000bf6:	14fd                	add	s1,s1,-1
    80000bf8:	ff2499e3          	bne	s1,s2,80000bea <printint+0x7e>
}
    80000bfc:	70a2                	ld	ra,40(sp)
    80000bfe:	7402                	ld	s0,32(sp)
    80000c00:	64e2                	ld	s1,24(sp)
    80000c02:	6942                	ld	s2,16(sp)
    80000c04:	6145                	add	sp,sp,48
    80000c06:	8082                	ret
    x = -xx;
    80000c08:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000c0c:	4885                	li	a7,1
    x = -xx;
    80000c0e:	bf95                	j	80000b82 <printint+0x16>

0000000080000c10 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000c10:	1101                	add	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	add	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000c1c:	0000b797          	auipc	a5,0xb
    80000c20:	a807a623          	sw	zero,-1396(a5) # 8000b6a8 <pr+0x18>
  printf("panic: ");
    80000c24:	00002517          	auipc	a0,0x2
    80000c28:	59450513          	add	a0,a0,1428 # 800031b8 <etext+0x1b8>
    80000c2c:	00000097          	auipc	ra,0x0
    80000c30:	02e080e7          	jalr	46(ra) # 80000c5a <printf>
  printf(s);
    80000c34:	8526                	mv	a0,s1
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	024080e7          	jalr	36(ra) # 80000c5a <printf>
  printf("\n");
    80000c3e:	00002517          	auipc	a0,0x2
    80000c42:	57250513          	add	a0,a0,1394 # 800031b0 <etext+0x1b0>
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	014080e7          	jalr	20(ra) # 80000c5a <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000c4e:	4785                	li	a5,1
    80000c50:	00002717          	auipc	a4,0x2
    80000c54:	5ef72623          	sw	a5,1516(a4) # 8000323c <panicked>
  for(;;)
    80000c58:	a001                	j	80000c58 <panic+0x48>

0000000080000c5a <printf>:
{
    80000c5a:	7131                	add	sp,sp,-192
    80000c5c:	fc86                	sd	ra,120(sp)
    80000c5e:	f8a2                	sd	s0,112(sp)
    80000c60:	f4a6                	sd	s1,104(sp)
    80000c62:	f0ca                	sd	s2,96(sp)
    80000c64:	ecce                	sd	s3,88(sp)
    80000c66:	e8d2                	sd	s4,80(sp)
    80000c68:	e4d6                	sd	s5,72(sp)
    80000c6a:	e0da                	sd	s6,64(sp)
    80000c6c:	fc5e                	sd	s7,56(sp)
    80000c6e:	f862                	sd	s8,48(sp)
    80000c70:	f466                	sd	s9,40(sp)
    80000c72:	f06a                	sd	s10,32(sp)
    80000c74:	ec6e                	sd	s11,24(sp)
    80000c76:	0100                	add	s0,sp,128
    80000c78:	8a2a                	mv	s4,a0
    80000c7a:	e40c                	sd	a1,8(s0)
    80000c7c:	e810                	sd	a2,16(s0)
    80000c7e:	ec14                	sd	a3,24(s0)
    80000c80:	f018                	sd	a4,32(s0)
    80000c82:	f41c                	sd	a5,40(s0)
    80000c84:	03043823          	sd	a6,48(s0)
    80000c88:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000c8c:	0000bd97          	auipc	s11,0xb
    80000c90:	a1cdad83          	lw	s11,-1508(s11) # 8000b6a8 <pr+0x18>
  if(locking)
    80000c94:	020d9b63          	bnez	s11,80000cca <printf+0x70>
  if (fmt == 0)
    80000c98:	040a0263          	beqz	s4,80000cdc <printf+0x82>
  va_start(ap, fmt);
    80000c9c:	00840793          	add	a5,s0,8
    80000ca0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000ca4:	000a4503          	lbu	a0,0(s4)
    80000ca8:	14050f63          	beqz	a0,80000e06 <printf+0x1ac>
    80000cac:	4981                	li	s3,0
    if(c != '%'){
    80000cae:	02500a93          	li	s5,37
    switch(c){
    80000cb2:	07000b93          	li	s7,112
  consputc('x');
    80000cb6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000cb8:	00002b17          	auipc	s6,0x2
    80000cbc:	528b0b13          	add	s6,s6,1320 # 800031e0 <digits>
    switch(c){
    80000cc0:	07300c93          	li	s9,115
    80000cc4:	06400c13          	li	s8,100
    80000cc8:	a82d                	j	80000d02 <printf+0xa8>
    acquire(&pr.lock);
    80000cca:	0000b517          	auipc	a0,0xb
    80000cce:	9c650513          	add	a0,a0,-1594 # 8000b690 <pr>
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	9a4080e7          	jalr	-1628(ra) # 80000676 <acquire>
    80000cda:	bf7d                	j	80000c98 <printf+0x3e>
    panic("null fmt");
    80000cdc:	00002517          	auipc	a0,0x2
    80000ce0:	4ec50513          	add	a0,a0,1260 # 800031c8 <etext+0x1c8>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	f2c080e7          	jalr	-212(ra) # 80000c10 <panic>
      consputc(c);
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	3c2080e7          	jalr	962(ra) # 800010ae <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000cf4:	2985                	addw	s3,s3,1
    80000cf6:	013a07b3          	add	a5,s4,s3
    80000cfa:	0007c503          	lbu	a0,0(a5)
    80000cfe:	10050463          	beqz	a0,80000e06 <printf+0x1ac>
    if(c != '%'){
    80000d02:	ff5515e3          	bne	a0,s5,80000cec <printf+0x92>
    c = fmt[++i] & 0xff;
    80000d06:	2985                	addw	s3,s3,1
    80000d08:	013a07b3          	add	a5,s4,s3
    80000d0c:	0007c783          	lbu	a5,0(a5)
    80000d10:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000d14:	cbed                	beqz	a5,80000e06 <printf+0x1ac>
    switch(c){
    80000d16:	05778a63          	beq	a5,s7,80000d6a <printf+0x110>
    80000d1a:	02fbf663          	bgeu	s7,a5,80000d46 <printf+0xec>
    80000d1e:	09978863          	beq	a5,s9,80000dae <printf+0x154>
    80000d22:	07800713          	li	a4,120
    80000d26:	0ce79563          	bne	a5,a4,80000df0 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000d2a:	f8843783          	ld	a5,-120(s0)
    80000d2e:	00878713          	add	a4,a5,8
    80000d32:	f8e43423          	sd	a4,-120(s0)
    80000d36:	4605                	li	a2,1
    80000d38:	85ea                	mv	a1,s10
    80000d3a:	4388                	lw	a0,0(a5)
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	e30080e7          	jalr	-464(ra) # 80000b6c <printint>
      break;
    80000d44:	bf45                	j	80000cf4 <printf+0x9a>
    switch(c){
    80000d46:	09578f63          	beq	a5,s5,80000de4 <printf+0x18a>
    80000d4a:	0b879363          	bne	a5,s8,80000df0 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000d4e:	f8843783          	ld	a5,-120(s0)
    80000d52:	00878713          	add	a4,a5,8
    80000d56:	f8e43423          	sd	a4,-120(s0)
    80000d5a:	4605                	li	a2,1
    80000d5c:	45a9                	li	a1,10
    80000d5e:	4388                	lw	a0,0(a5)
    80000d60:	00000097          	auipc	ra,0x0
    80000d64:	e0c080e7          	jalr	-500(ra) # 80000b6c <printint>
      break;
    80000d68:	b771                	j	80000cf4 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000d6a:	f8843783          	ld	a5,-120(s0)
    80000d6e:	00878713          	add	a4,a5,8
    80000d72:	f8e43423          	sd	a4,-120(s0)
    80000d76:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000d7a:	03000513          	li	a0,48
    80000d7e:	00000097          	auipc	ra,0x0
    80000d82:	330080e7          	jalr	816(ra) # 800010ae <consputc>
  consputc('x');
    80000d86:	07800513          	li	a0,120
    80000d8a:	00000097          	auipc	ra,0x0
    80000d8e:	324080e7          	jalr	804(ra) # 800010ae <consputc>
    80000d92:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000d94:	03c95793          	srl	a5,s2,0x3c
    80000d98:	97da                	add	a5,a5,s6
    80000d9a:	0007c503          	lbu	a0,0(a5)
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	310080e7          	jalr	784(ra) # 800010ae <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000da6:	0912                	sll	s2,s2,0x4
    80000da8:	34fd                	addw	s1,s1,-1
    80000daa:	f4ed                	bnez	s1,80000d94 <printf+0x13a>
    80000dac:	b7a1                	j	80000cf4 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000dae:	f8843783          	ld	a5,-120(s0)
    80000db2:	00878713          	add	a4,a5,8
    80000db6:	f8e43423          	sd	a4,-120(s0)
    80000dba:	6384                	ld	s1,0(a5)
    80000dbc:	cc89                	beqz	s1,80000dd6 <printf+0x17c>
      for(; *s; s++)
    80000dbe:	0004c503          	lbu	a0,0(s1)
    80000dc2:	d90d                	beqz	a0,80000cf4 <printf+0x9a>
        consputc(*s);
    80000dc4:	00000097          	auipc	ra,0x0
    80000dc8:	2ea080e7          	jalr	746(ra) # 800010ae <consputc>
      for(; *s; s++)
    80000dcc:	0485                	add	s1,s1,1
    80000dce:	0004c503          	lbu	a0,0(s1)
    80000dd2:	f96d                	bnez	a0,80000dc4 <printf+0x16a>
    80000dd4:	b705                	j	80000cf4 <printf+0x9a>
        s = "(null)";
    80000dd6:	00002497          	auipc	s1,0x2
    80000dda:	3ea48493          	add	s1,s1,1002 # 800031c0 <etext+0x1c0>
      for(; *s; s++)
    80000dde:	02800513          	li	a0,40
    80000de2:	b7cd                	j	80000dc4 <printf+0x16a>
      consputc('%');
    80000de4:	8556                	mv	a0,s5
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	2c8080e7          	jalr	712(ra) # 800010ae <consputc>
      break;
    80000dee:	b719                	j	80000cf4 <printf+0x9a>
      consputc('%');
    80000df0:	8556                	mv	a0,s5
    80000df2:	00000097          	auipc	ra,0x0
    80000df6:	2bc080e7          	jalr	700(ra) # 800010ae <consputc>
      consputc(c);
    80000dfa:	8526                	mv	a0,s1
    80000dfc:	00000097          	auipc	ra,0x0
    80000e00:	2b2080e7          	jalr	690(ra) # 800010ae <consputc>
      break;
    80000e04:	bdc5                	j	80000cf4 <printf+0x9a>
  if(locking)
    80000e06:	020d9163          	bnez	s11,80000e28 <printf+0x1ce>
}
    80000e0a:	70e6                	ld	ra,120(sp)
    80000e0c:	7446                	ld	s0,112(sp)
    80000e0e:	74a6                	ld	s1,104(sp)
    80000e10:	7906                	ld	s2,96(sp)
    80000e12:	69e6                	ld	s3,88(sp)
    80000e14:	6a46                	ld	s4,80(sp)
    80000e16:	6aa6                	ld	s5,72(sp)
    80000e18:	6b06                	ld	s6,64(sp)
    80000e1a:	7be2                	ld	s7,56(sp)
    80000e1c:	7c42                	ld	s8,48(sp)
    80000e1e:	7ca2                	ld	s9,40(sp)
    80000e20:	7d02                	ld	s10,32(sp)
    80000e22:	6de2                	ld	s11,24(sp)
    80000e24:	6129                	add	sp,sp,192
    80000e26:	8082                	ret
    release(&pr.lock);
    80000e28:	0000b517          	auipc	a0,0xb
    80000e2c:	86850513          	add	a0,a0,-1944 # 8000b690 <pr>
    80000e30:	00000097          	auipc	ra,0x0
    80000e34:	8fa080e7          	jalr	-1798(ra) # 8000072a <release>
}
    80000e38:	bfc9                	j	80000e0a <printf+0x1b0>

0000000080000e3a <printfinit>:
    ;
}

void
printfinit(void)
{
    80000e3a:	1101                	add	sp,sp,-32
    80000e3c:	ec06                	sd	ra,24(sp)
    80000e3e:	e822                	sd	s0,16(sp)
    80000e40:	e426                	sd	s1,8(sp)
    80000e42:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000e44:	0000b497          	auipc	s1,0xb
    80000e48:	84c48493          	add	s1,s1,-1972 # 8000b690 <pr>
    80000e4c:	00002597          	auipc	a1,0x2
    80000e50:	38c58593          	add	a1,a1,908 # 800031d8 <etext+0x1d8>
    80000e54:	8526                	mv	a0,s1
    80000e56:	fffff097          	auipc	ra,0xfffff
    80000e5a:	790080e7          	jalr	1936(ra) # 800005e6 <initlock>
  pr.locking = 1;
    80000e5e:	4785                	li	a5,1
    80000e60:	cc9c                	sw	a5,24(s1)
}
    80000e62:	60e2                	ld	ra,24(sp)
    80000e64:	6442                	ld	s0,16(sp)
    80000e66:	64a2                	ld	s1,8(sp)
    80000e68:	6105                	add	sp,sp,32
    80000e6a:	8082                	ret

0000000080000e6c <timer_init>:
// 完成以下设置来接收M-Mode下的时钟中断
// 时钟中断会进入到kernelvec.S中的timervec
// 在这之后会将它们转化为软中断进而被trap.c中的devintr接管
void
timer_init()
{
    80000e6c:	1141                	add	sp,sp,-16
    80000e6e:	e422                	sd	s0,8(sp)
    80000e70:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000e72:	f14027f3          	csrr	a5,mhartid
  // 每个CPU都有独立的定时器中断源
  int id = r_mhartid();
    80000e76:	0007859b          	sext.w	a1,a5

  // 向CLINT(核心本地中断控制器)请求定时器中断
  int interval = 1000000; // 周期数；在QEMU中大约是1/10秒
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000e7a:	0037979b          	sllw	a5,a5,0x3
    80000e7e:	02004737          	lui	a4,0x2004
    80000e82:	97ba                	add	a5,a5,a4
    80000e84:	0200c737          	lui	a4,0x200c
    80000e88:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000e8c:	000f4637          	lui	a2,0xf4
    80000e90:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000e94:	9732                	add	a4,a4,a2
    80000e96:	e398                	sd	a4,0(a5)

  // 在scratch[]中为timervec准备信息
  // scratch[0..2] : timervec保存寄存器的空间
  // scratch[3] : CLINT MTIMECMP寄存器地址
  // scratch[4] : 定时器中断之间期望的间隔(周期数)
  uint64 *scratch = &timer_scratch[id][0];
    80000e98:	00259693          	sll	a3,a1,0x2
    80000e9c:	96ae                	add	a3,a3,a1
    80000e9e:	068e                	sll	a3,a3,0x3
    80000ea0:	0000b717          	auipc	a4,0xb
    80000ea4:	81070713          	add	a4,a4,-2032 # 8000b6b0 <timer_scratch>
    80000ea8:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    80000eaa:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000eac:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000eae:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000eb2:	00000797          	auipc	a5,0x0
    80000eb6:	36e78793          	add	a5,a5,878 # 80001220 <timervec>
    80000eba:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000ebe:	300027f3          	csrr	a5,mstatus

  // 设置机器模式的陷阱处理程序
  w_mtvec((uint64)timervec);

  // 启用机器模式中断
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000ec2:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000ec6:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000eca:	304027f3          	csrr	a5,mie

  // 启用机器模式定时器中断
  w_mie(r_mie() | MIE_MTIE);
    80000ece:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000ed2:	30479073          	csrw	mie,a5
}
    80000ed6:	6422                	ld	s0,8(sp)
    80000ed8:	0141                	add	sp,sp,16
    80000eda:	8082                	ret

0000000080000edc <timer_create>:
static timer_t sys_timer;

// 时钟创建(初始化系统时钟)
// 陷阱初始化函数
void timer_create()
{
    80000edc:	1141                	add	sp,sp,-16
    80000ede:	e406                	sd	ra,8(sp)
    80000ee0:	e022                	sd	s0,0(sp)
    80000ee2:	0800                	add	s0,sp,16
    initlock(&sys_timer.lk, "sys_timer");
    80000ee4:	00002597          	auipc	a1,0x2
    80000ee8:	31458593          	add	a1,a1,788 # 800031f8 <digits+0x18>
    80000eec:	0000b517          	auipc	a0,0xb
    80000ef0:	90c50513          	add	a0,a0,-1780 # 8000b7f8 <sys_timer+0x8>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	6f2080e7          	jalr	1778(ra) # 800005e6 <initlock>
    sys_timer.ticks = 0;
    80000efc:	0000b797          	auipc	a5,0xb
    80000f00:	8e07ba23          	sd	zero,-1804(a5) # 8000b7f0 <sys_timer>
}
    80000f04:	60a2                	ld	ra,8(sp)
    80000f06:	6402                	ld	s0,0(sp)
    80000f08:	0141                	add	sp,sp,16
    80000f0a:	8082                	ret

0000000080000f0c <timer_update>:

// 时钟更新(ticks++ with lock)
void timer_update()
{
    80000f0c:	1101                	add	sp,sp,-32
    80000f0e:	ec06                	sd	ra,24(sp)
    80000f10:	e822                	sd	s0,16(sp)
    80000f12:	e426                	sd	s1,8(sp)
    80000f14:	e04a                	sd	s2,0(sp)
    80000f16:	1000                	add	s0,sp,32
    acquire(&sys_timer.lk);
    80000f18:	0000a917          	auipc	s2,0xa
    80000f1c:	79890913          	add	s2,s2,1944 # 8000b6b0 <timer_scratch>
    80000f20:	0000b497          	auipc	s1,0xb
    80000f24:	8d848493          	add	s1,s1,-1832 # 8000b7f8 <sys_timer+0x8>
    80000f28:	8526                	mv	a0,s1
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	74c080e7          	jalr	1868(ra) # 80000676 <acquire>
    sys_timer.ticks++;
    80000f32:	14093583          	ld	a1,320(s2)
    80000f36:	0585                	add	a1,a1,1
    80000f38:	14b93023          	sd	a1,320(s2)
    printf("ticks: %d\n", sys_timer.ticks);
    80000f3c:	00002517          	auipc	a0,0x2
    80000f40:	2cc50513          	add	a0,a0,716 # 80003208 <digits+0x28>
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	d16080e7          	jalr	-746(ra) # 80000c5a <printf>
    release(&sys_timer.lk);
    80000f4c:	8526                	mv	a0,s1
    80000f4e:	fffff097          	auipc	ra,0xfffff
    80000f52:	7dc080e7          	jalr	2012(ra) # 8000072a <release>
}
    80000f56:	60e2                	ld	ra,24(sp)
    80000f58:	6442                	ld	s0,16(sp)
    80000f5a:	64a2                	ld	s1,8(sp)
    80000f5c:	6902                	ld	s2,0(sp)
    80000f5e:	6105                	add	sp,sp,32
    80000f60:	8082                	ret

0000000080000f62 <timer_get_ticks>:

// 返回系统时钟ticks
uint64 timer_get_ticks()
{
    80000f62:	1101                	add	sp,sp,-32
    80000f64:	ec06                	sd	ra,24(sp)
    80000f66:	e822                	sd	s0,16(sp)
    80000f68:	e426                	sd	s1,8(sp)
    80000f6a:	e04a                	sd	s2,0(sp)
    80000f6c:	1000                	add	s0,sp,32
    uint64 xticks;
    acquire(&sys_timer.lk);
    80000f6e:	0000b497          	auipc	s1,0xb
    80000f72:	88a48493          	add	s1,s1,-1910 # 8000b7f8 <sys_timer+0x8>
    80000f76:	8526                	mv	a0,s1
    80000f78:	fffff097          	auipc	ra,0xfffff
    80000f7c:	6fe080e7          	jalr	1790(ra) # 80000676 <acquire>
    xticks = sys_timer.ticks;
    80000f80:	0000b917          	auipc	s2,0xb
    80000f84:	87093903          	ld	s2,-1936(s2) # 8000b7f0 <sys_timer>
    release(&sys_timer.lk);
    80000f88:	8526                	mv	a0,s1
    80000f8a:	fffff097          	auipc	ra,0xfffff
    80000f8e:	7a0080e7          	jalr	1952(ra) # 8000072a <release>
    return xticks;
    80000f92:	854a                	mv	a0,s2
    80000f94:	60e2                	ld	ra,24(sp)
    80000f96:	6442                	ld	s0,16(sp)
    80000f98:	64a2                	ld	s1,8(sp)
    80000f9a:	6902                	ld	s2,0(sp)
    80000f9c:	6105                	add	sp,sp,32
    80000f9e:	8082                	ret

0000000080000fa0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000fa0:	1141                	add	sp,sp,-16
    80000fa2:	e406                	sd	ra,8(sp)
    80000fa4:	e022                	sd	s0,0(sp)
    80000fa6:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000fa8:	100007b7          	lui	a5,0x10000
    80000fac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000fb0:	f8000713          	li	a4,-128
    80000fb4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000fb8:	470d                	li	a4,3
    80000fba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000fbe:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000fc2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000fc6:	469d                	li	a3,7
    80000fc8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000fcc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000fd0:	00002597          	auipc	a1,0x2
    80000fd4:	24858593          	add	a1,a1,584 # 80003218 <digits+0x38>
    80000fd8:	0000b517          	auipc	a0,0xb
    80000fdc:	83850513          	add	a0,a0,-1992 # 8000b810 <uart_tx_lock>
    80000fe0:	fffff097          	auipc	ra,0xfffff
    80000fe4:	606080e7          	jalr	1542(ra) # 800005e6 <initlock>
}
    80000fe8:	60a2                	ld	ra,8(sp)
    80000fea:	6402                	ld	s0,0(sp)
    80000fec:	0141                	add	sp,sp,16
    80000fee:	8082                	ret

0000000080000ff0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000ff0:	1101                	add	sp,sp,-32
    80000ff2:	ec06                	sd	ra,24(sp)
    80000ff4:	e822                	sd	s0,16(sp)
    80000ff6:	e426                	sd	s1,8(sp)
    80000ff8:	1000                	add	s0,sp,32
    80000ffa:	84aa                	mv	s1,a0
  push_off();
    80000ffc:	fffff097          	auipc	ra,0xfffff
    80001000:	62e080e7          	jalr	1582(ra) # 8000062a <push_off>

  if(panicked){
    80001004:	00002797          	auipc	a5,0x2
    80001008:	2387a783          	lw	a5,568(a5) # 8000323c <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000100c:	10000737          	lui	a4,0x10000
  if(panicked){
    80001010:	c391                	beqz	a5,80001014 <uartputc_sync+0x24>
    for(;;)
    80001012:	a001                	j	80001012 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80001014:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80001018:	0207f793          	and	a5,a5,32
    8000101c:	dfe5                	beqz	a5,80001014 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000101e:	0ff4f513          	zext.b	a0,s1
    80001022:	100007b7          	lui	a5,0x10000
    80001026:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000102a:	fffff097          	auipc	ra,0xfffff
    8000102e:	6a0080e7          	jalr	1696(ra) # 800006ca <pop_off>
}
    80001032:	60e2                	ld	ra,24(sp)
    80001034:	6442                	ld	s0,16(sp)
    80001036:	64a2                	ld	s1,8(sp)
    80001038:	6105                	add	sp,sp,32
    8000103a:	8082                	ret

000000008000103c <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000103c:	1141                	add	sp,sp,-16
    8000103e:	e422                	sd	s0,8(sp)
    80001040:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80001042:	100007b7          	lui	a5,0x10000
    80001046:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000104a:	8b85                	and	a5,a5,1
    8000104c:	cb81                	beqz	a5,8000105c <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    8000104e:	100007b7          	lui	a5,0x10000
    80001052:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80001056:	6422                	ld	s0,8(sp)
    80001058:	0141                	add	sp,sp,16
    8000105a:	8082                	ret
    return -1;
    8000105c:	557d                	li	a0,-1
    8000105e:	bfe5                	j	80001056 <uartgetc+0x1a>

0000000080001060 <uart_putc>:
//   uartstart();
//   release(&uart_tx_lock);
// }


void uart_putc(char c) {
    80001060:	1141                	add	sp,sp,-16
    80001062:	e422                	sd	s0,8(sp)
    80001064:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    80001066:	10000737          	lui	a4,0x10000
    8000106a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000106e:	0207f793          	and	a5,a5,32
    80001072:	dfe5                	beqz	a5,8000106a <uart_putc+0xa>
    uart[0] = c;
    80001074:	100007b7          	lui	a5,0x10000
    80001078:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    8000107c:	6422                	ld	s0,8(sp)
    8000107e:	0141                	add	sp,sp,16
    80001080:	8082                	ret

0000000080001082 <uart_puts>:

void uart_puts(char *s) {
    80001082:	1101                	add	sp,sp,-32
    80001084:	ec06                	sd	ra,24(sp)
    80001086:	e822                	sd	s0,16(sp)
    80001088:	e426                	sd	s1,8(sp)
    8000108a:	1000                	add	s0,sp,32
    8000108c:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    8000108e:	00054503          	lbu	a0,0(a0)
    80001092:	c909                	beqz	a0,800010a4 <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    80001094:	00000097          	auipc	ra,0x0
    80001098:	fcc080e7          	jalr	-52(ra) # 80001060 <uart_putc>
        s++;              // 移动到下一个字符
    8000109c:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    8000109e:	0004c503          	lbu	a0,0(s1)
    800010a2:	f96d                	bnez	a0,80001094 <uart_puts+0x12>
    }
}
    800010a4:	60e2                	ld	ra,24(sp)
    800010a6:	6442                	ld	s0,16(sp)
    800010a8:	64a2                	ld	s1,8(sp)
    800010aa:	6105                	add	sp,sp,32
    800010ac:	8082                	ret

00000000800010ae <consputc>:
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    800010ae:	1141                	add	sp,sp,-16
    800010b0:	e406                	sd	ra,8(sp)
    800010b2:	e022                	sd	s0,0(sp)
    800010b4:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    800010b6:	10000793          	li	a5,256
    800010ba:	00f50a63          	beq	a0,a5,800010ce <consputc+0x20>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    800010be:	00000097          	auipc	ra,0x0
    800010c2:	f32080e7          	jalr	-206(ra) # 80000ff0 <uartputc_sync>
  }
}
    800010c6:	60a2                	ld	ra,8(sp)
    800010c8:	6402                	ld	s0,0(sp)
    800010ca:	0141                	add	sp,sp,16
    800010cc:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800010ce:	4521                	li	a0,8
    800010d0:	00000097          	auipc	ra,0x0
    800010d4:	f20080e7          	jalr	-224(ra) # 80000ff0 <uartputc_sync>
    800010d8:	02000513          	li	a0,32
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	f14080e7          	jalr	-236(ra) # 80000ff0 <uartputc_sync>
    800010e4:	4521                	li	a0,8
    800010e6:	00000097          	auipc	ra,0x0
    800010ea:	f0a080e7          	jalr	-246(ra) # 80000ff0 <uartputc_sync>
    800010ee:	bfe1                	j	800010c6 <consputc+0x18>

00000000800010f0 <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    800010f0:	1141                	add	sp,sp,-16
    800010f2:	e406                	sd	ra,8(sp)
    800010f4:	e022                	sd	s0,0(sp)
    800010f6:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    800010f8:	00002597          	auipc	a1,0x2
    800010fc:	12858593          	add	a1,a1,296 # 80003220 <digits+0x40>
    80001100:	0000a517          	auipc	a0,0xa
    80001104:	74850513          	add	a0,a0,1864 # 8000b848 <cons>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	4de080e7          	jalr	1246(ra) # 800005e6 <initlock>

  uartinit();
    80001110:	00000097          	auipc	ra,0x0
    80001114:	e90080e7          	jalr	-368(ra) # 80000fa0 <uartinit>

  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    80001118:	60a2                	ld	ra,8(sp)
    8000111a:	6402                	ld	s0,0(sp)
    8000111c:	0141                	add	sp,sp,16
    8000111e:	8082                	ret

0000000080001120 <swtch>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    80001120:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    80001124:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    80001128:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    8000112a:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    8000112c:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    80001130:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    80001134:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    80001138:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    8000113c:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    80001140:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    80001144:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    80001148:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    8000114c:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    80001150:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    80001154:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)      # 恢复栈指针
    80001158:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    8000115c:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    8000115e:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    80001160:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    80001164:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    80001168:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    8000116c:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    80001170:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    80001174:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    80001178:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    8000117c:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    80001180:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    80001184:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    80001188:	8082                	ret
    8000118a:	0000                	unimp
    8000118c:	0000                	unimp
	...

0000000080001190 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    80001190:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    80001192:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80001194:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80001196:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80001198:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    8000119a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000119c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000119e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    800011a0:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    800011a2:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    800011a4:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800011a6:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800011a8:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800011aa:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800011ac:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800011ae:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800011b0:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800011b2:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    800011b4:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    800011b6:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    800011b8:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    800011ba:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    800011bc:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    800011be:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    800011c0:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    800011c2:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    800011c4:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    800011c6:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    800011c8:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800011ca:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800011cc:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800011ce:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    800011d0:	fffff097          	auipc	ra,0xfffff
    800011d4:	5fc080e7          	jalr	1532(ra) # 800007cc <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    800011d8:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    800011da:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    800011dc:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    800011de:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800011e0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800011e2:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    800011e4:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    800011e6:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    800011e8:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800011ea:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800011ec:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800011ee:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800011f0:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800011f2:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800011f4:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800011f6:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    800011f8:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    800011fa:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    800011fc:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    800011fe:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    80001200:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    80001202:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    80001204:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    80001206:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    80001208:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    8000120a:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    8000120c:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    8000120e:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80001210:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80001212:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    80001214:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    80001216:	10200073          	sret
    8000121a:	0001                	nop
    8000121c:	00000013          	nop

0000000080001220 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    80001220:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    80001224:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    80001226:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    80001228:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    8000122a:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    8000122c:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    8000122e:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    80001230:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    80001232:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    80001234:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    80001236:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    8000123a:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    8000123c:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    8000123e:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80001240:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    80001244:	30200073          	mret
    80001248:	00000013          	nop
    8000124c:	00000013          	nop
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
