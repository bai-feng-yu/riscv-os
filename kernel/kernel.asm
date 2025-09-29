
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.global _entry
_entry:
    # 为C语言代码设置栈空间
    # stack0声明在start.c中，每个CPU分配4096字节的栈空间
    # 计算公式: sp = stack0基地址 + (硬件线程ID * 4096)
    la sp, stack0        # 加载stack0的基地址到栈指针sp
    80000000:	00002117          	auipc	sp,0x2
    80000004:	3c010113          	add	sp,sp,960 # 800023c0 <stack0>
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
    80000016:	00002517          	auipc	a0,0x2
    8000001a:	30a50513          	add	a0,a0,778 # 80002320 <kernel_pagetable>
    la a1, end
    8000001e:	0000a597          	auipc	a1,0xa
    80000022:	4a258593          	add	a1,a1,1186 # 8000a4c0 <end>

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
    80000034:	7ac080e7          	jalr	1964(ra) # 800007dc <start>

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
    8000004e:	0000a797          	auipc	a5,0xa
    80000052:	47278793          	add	a5,a5,1138 # 8000a4c0 <end>
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
    8000006a:	7de080e7          	jalr	2014(ra) # 80000844 <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    8000006e:	00002917          	auipc	s2,0x2
    80000072:	2d290913          	add	s2,s2,722 # 80002340 <kmem>
    80000076:	854a                	mv	a0,s2
    80000078:	00000097          	auipc	ra,0x0
    8000007c:	5ae080e7          	jalr	1454(ra) # 80000626 <acquire>
  r->next = kmem.freelist;  //头插
    80000080:	01893783          	ld	a5,24(s2)
    80000084:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000086:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    8000008a:	854a                	mv	a0,s2
    8000008c:	00000097          	auipc	ra,0x0
    80000090:	64e080e7          	jalr	1614(ra) # 800006da <release>
}
    80000094:	60e2                	ld	ra,24(sp)
    80000096:	6442                	ld	s0,16(sp)
    80000098:	64a2                	ld	s1,8(sp)
    8000009a:	6902                	ld	s2,0(sp)
    8000009c:	6105                	add	sp,sp,32
    8000009e:	8082                	ret
    panic("kfree");
    800000a0:	00002517          	auipc	a0,0x2
    800000a4:	f6050513          	add	a0,a0,-160 # 80002000 <etext>
    800000a8:	00001097          	auipc	ra,0x1
    800000ac:	9e4080e7          	jalr	-1564(ra) # 80000a8c <panic>

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
    80000106:	00002597          	auipc	a1,0x2
    8000010a:	f0258593          	add	a1,a1,-254 # 80002008 <etext+0x8>
    8000010e:	00002517          	auipc	a0,0x2
    80000112:	23250513          	add	a0,a0,562 # 80002340 <kmem>
    80000116:	00000097          	auipc	ra,0x0
    8000011a:	480080e7          	jalr	1152(ra) # 80000596 <initlock>
  freerange(end, (void*)PHYSTOP);
    8000011e:	45c5                	li	a1,17
    80000120:	05ee                	sll	a1,a1,0x1b
    80000122:	0000a517          	auipc	a0,0xa
    80000126:	39e50513          	add	a0,a0,926 # 8000a4c0 <end>
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
    80000144:	00002497          	auipc	s1,0x2
    80000148:	1fc48493          	add	s1,s1,508 # 80002340 <kmem>
    8000014c:	8526                	mv	a0,s1
    8000014e:	00000097          	auipc	ra,0x0
    80000152:	4d8080e7          	jalr	1240(ra) # 80000626 <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80000156:	6c84                	ld	s1,24(s1)
  if(r)
    80000158:	c885                	beqz	s1,80000188 <kalloc+0x4e>
    kmem.freelist = r->next;
    8000015a:	609c                	ld	a5,0(s1)
    8000015c:	00002517          	auipc	a0,0x2
    80000160:	1e450513          	add	a0,a0,484 # 80002340 <kmem>
    80000164:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000166:	00000097          	auipc	ra,0x0
    8000016a:	574080e7          	jalr	1396(ra) # 800006da <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    8000016e:	6605                	lui	a2,0x1
    80000170:	4595                	li	a1,5
    80000172:	8526                	mv	a0,s1
    80000174:	00000097          	auipc	ra,0x0
    80000178:	6d0080e7          	jalr	1744(ra) # 80000844 <memset>
  return (void*)r;
}
    8000017c:	8526                	mv	a0,s1
    8000017e:	60e2                	ld	ra,24(sp)
    80000180:	6442                	ld	s0,16(sp)
    80000182:	64a2                	ld	s1,8(sp)
    80000184:	6105                	add	sp,sp,32
    80000186:	8082                	ret
  release(&kmem.lock);
    80000188:	00002517          	auipc	a0,0x2
    8000018c:	1b850513          	add	a0,a0,440 # 80002340 <kmem>
    80000190:	00000097          	auipc	ra,0x0
    80000194:	54a080e7          	jalr	1354(ra) # 800006da <release>
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
    800001a4:	00002797          	auipc	a5,0x2
    800001a8:	17c7b783          	ld	a5,380(a5) # 80002320 <kernel_pagetable>
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
  if(va >= MAXVA)
    800001d6:	57fd                	li	a5,-1
    800001d8:	83e9                	srl	a5,a5,0x1a
    800001da:	02b7e063          	bltu	a5,a1,800001fa <walk+0x38>
    800001de:	84aa                	mv	s1,a0
    800001e0:	89ae                	mv	s3,a1
    800001e2:	8b32                	mv	s6,a2
    panic("walk");

  printf("debug: walk va %p\n\n", va);
    800001e4:	00002517          	auipc	a0,0x2
    800001e8:	e3450513          	add	a0,a0,-460 # 80002018 <etext+0x18>
    800001ec:	00001097          	auipc	ra,0x1
    800001f0:	8ea080e7          	jalr	-1814(ra) # 80000ad6 <printf>
    800001f4:	4af9                	li	s5,30

  for(int level = 2; level > 0; level--) {
    800001f6:	4a09                	li	s4,2
    800001f8:	a88d                	j	8000026a <walk+0xa8>
    panic("walk");
    800001fa:	00002517          	auipc	a0,0x2
    800001fe:	e1650513          	add	a0,a0,-490 # 80002010 <etext+0x10>
    80000202:	00001097          	auipc	ra,0x1
    80000206:	88a080e7          	jalr	-1910(ra) # 80000a8c <panic>
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
      printf("debug: walk level %d va %p pte %p next level pagetable %p\n", level, va, *pte, pagetable);
    } else {  // PTE无效，先判断是否可以写入
      printf("debug: walk level %d not VALID\n", level, va, pte);
    8000020a:	86ca                	mv	a3,s2
    8000020c:	864e                	mv	a2,s3
    8000020e:	85d2                	mv	a1,s4
    80000210:	00002517          	auipc	a0,0x2
    80000214:	e6050513          	add	a0,a0,-416 # 80002070 <etext+0x70>
    80000218:	00001097          	auipc	ra,0x1
    8000021c:	8be080e7          	jalr	-1858(ra) # 80000ad6 <printf>
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
    80000220:	0a0b0b63          	beqz	s6,800002d6 <walk+0x114>
    80000224:	4505                	li	a0,1
    80000226:	00000097          	auipc	ra,0x0
    8000022a:	f14080e7          	jalr	-236(ra) # 8000013a <kalloc>
    8000022e:	84aa                	mv	s1,a0
    80000230:	c941                	beqz	a0,800002c0 <walk+0xfe>
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
    80000232:	6605                	lui	a2,0x1
    80000234:	4581                	li	a1,0
    80000236:	00000097          	auipc	ra,0x0
    8000023a:	60e080e7          	jalr	1550(ra) # 80000844 <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    8000023e:	00c4d693          	srl	a3,s1,0xc
    80000242:	06aa                	sll	a3,a3,0xa
    80000244:	0016e693          	or	a3,a3,1
    80000248:	00d93023          	sd	a3,0(s2)
      printf("debug: walk alloc level %d va %p pte %p next level pagetable %p\n\n", level, va, *pte, pagetable);
    8000024c:	8726                	mv	a4,s1
    8000024e:	864e                	mv	a2,s3
    80000250:	85d2                	mv	a1,s4
    80000252:	00002517          	auipc	a0,0x2
    80000256:	e3e50513          	add	a0,a0,-450 # 80002090 <etext+0x90>
    8000025a:	00001097          	auipc	ra,0x1
    8000025e:	87c080e7          	jalr	-1924(ra) # 80000ad6 <printf>
  for(int level = 2; level > 0; level--) {
    80000262:	3a7d                	addw	s4,s4,-1 # ffffffffffffefff <end+0xffffffff7fff4b3f>
    80000264:	3add                	addw	s5,s5,-9
    80000266:	020a0c63          	beqz	s4,8000029e <walk+0xdc>
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    8000026a:	0159d933          	srl	s2,s3,s5
    8000026e:	1ff97913          	and	s2,s2,511
    80000272:	090e                	sll	s2,s2,0x3
    80000274:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) { // PTE有效
    80000276:	00093683          	ld	a3,0(s2)
    8000027a:	0016f793          	and	a5,a3,1
    8000027e:	d7d1                	beqz	a5,8000020a <walk+0x48>
      pagetable = (pagetable_t)PTE2PA(*pte); 
    80000280:	00a6d493          	srl	s1,a3,0xa
    80000284:	04b2                	sll	s1,s1,0xc
      printf("debug: walk level %d va %p pte %p next level pagetable %p\n", level, va, *pte, pagetable);
    80000286:	8726                	mv	a4,s1
    80000288:	864e                	mv	a2,s3
    8000028a:	85d2                	mv	a1,s4
    8000028c:	00002517          	auipc	a0,0x2
    80000290:	da450513          	add	a0,a0,-604 # 80002030 <etext+0x30>
    80000294:	00001097          	auipc	ra,0x1
    80000298:	842080e7          	jalr	-1982(ra) # 80000ad6 <printf>
    8000029c:	b7d9                	j	80000262 <walk+0xa0>
    }
  }
  printf("debug: walk leaf va %p pte %p pte address %p \n\n ", va,*&pagetable[PX(0, va)] ,&pagetable[PX(0, va)]);
    8000029e:	00c9d793          	srl	a5,s3,0xc
    800002a2:	1ff7f793          	and	a5,a5,511
    800002a6:	078e                	sll	a5,a5,0x3
    800002a8:	94be                	add	s1,s1,a5
    800002aa:	86a6                	mv	a3,s1
    800002ac:	6090                	ld	a2,0(s1)
    800002ae:	85ce                	mv	a1,s3
    800002b0:	00002517          	auipc	a0,0x2
    800002b4:	e2850513          	add	a0,a0,-472 # 800020d8 <etext+0xd8>
    800002b8:	00001097          	auipc	ra,0x1
    800002bc:	81e080e7          	jalr	-2018(ra) # 80000ad6 <printf>
  return &pagetable[PX(0, va)];  
}
    800002c0:	8526                	mv	a0,s1
    800002c2:	70e2                	ld	ra,56(sp)
    800002c4:	7442                	ld	s0,48(sp)
    800002c6:	74a2                	ld	s1,40(sp)
    800002c8:	7902                	ld	s2,32(sp)
    800002ca:	69e2                	ld	s3,24(sp)
    800002cc:	6a42                	ld	s4,16(sp)
    800002ce:	6aa2                	ld	s5,8(sp)
    800002d0:	6b02                	ld	s6,0(sp)
    800002d2:	6121                	add	sp,sp,64
    800002d4:	8082                	ret
        return 0; // 失败返回0
    800002d6:	4481                	li	s1,0
    800002d8:	b7e5                	j	800002c0 <walk+0xfe>

00000000800002da <mappages>:
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
    800002da:	715d                	add	sp,sp,-80
    800002dc:	e486                	sd	ra,72(sp)
    800002de:	e0a2                	sd	s0,64(sp)
    800002e0:	fc26                	sd	s1,56(sp)
    800002e2:	f84a                	sd	s2,48(sp)
    800002e4:	f44e                	sd	s3,40(sp)
    800002e6:	f052                	sd	s4,32(sp)
    800002e8:	ec56                	sd	s5,24(sp)
    800002ea:	e85a                	sd	s6,16(sp)
    800002ec:	e45e                	sd	s7,8(sp)
    800002ee:	e062                	sd	s8,0(sp)
    800002f0:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800002f2:	03459793          	sll	a5,a1,0x34
    800002f6:	e3bd                	bnez	a5,8000035c <mappages+0x82>
    800002f8:	8aaa                	mv	s5,a0
    800002fa:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    800002fc:	03461793          	sll	a5,a2,0x34
    80000300:	e7b5                	bnez	a5,8000036c <mappages+0x92>
    panic("mappages: size not aligned");

  if(size == 0)
    80000302:	ce2d                	beqz	a2,8000037c <mappages+0xa2>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
    80000304:	77fd                	lui	a5,0xfffff
    80000306:	963e                	add	a2,a2,a5
    80000308:	00b609b3          	add	s3,a2,a1
  a = va;
    8000030c:	84ae                	mv	s1,a1
    8000030e:	40b68a33          	sub	s4,a3,a1
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
      return -1;
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    printf("debug: mappages successful: va %p pa %p pte %p\n", a, pa, *pte);
    80000312:	00002b97          	auipc	s7,0x2
    80000316:	e5eb8b93          	add	s7,s7,-418 # 80002170 <etext+0x170>
    if(a == last)
      break;
    a += PGSIZE;
    8000031a:	6c05                	lui	s8,0x1
    8000031c:	009a0933          	add	s2,s4,s1
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    80000320:	4605                	li	a2,1
    80000322:	85a6                	mv	a1,s1
    80000324:	8556                	mv	a0,s5
    80000326:	00000097          	auipc	ra,0x0
    8000032a:	e9c080e7          	jalr	-356(ra) # 800001c2 <walk>
    8000032e:	c53d                	beqz	a0,8000039c <mappages+0xc2>
    if(*pte & PTE_V) // 重复映射
    80000330:	611c                	ld	a5,0(a0)
    80000332:	8b85                	and	a5,a5,1
    80000334:	efa1                	bnez	a5,8000038c <mappages+0xb2>
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    80000336:	00c95693          	srl	a3,s2,0xc
    8000033a:	06aa                	sll	a3,a3,0xa
    8000033c:	0166e6b3          	or	a3,a3,s6
    80000340:	0016e693          	or	a3,a3,1
    80000344:	e114                	sd	a3,0(a0)
    printf("debug: mappages successful: va %p pa %p pte %p\n", a, pa, *pte);
    80000346:	864a                	mv	a2,s2
    80000348:	85a6                	mv	a1,s1
    8000034a:	855e                	mv	a0,s7
    8000034c:	00000097          	auipc	ra,0x0
    80000350:	78a080e7          	jalr	1930(ra) # 80000ad6 <printf>
    if(a == last)
    80000354:	07348163          	beq	s1,s3,800003b6 <mappages+0xdc>
    a += PGSIZE;
    80000358:	94e2                	add	s1,s1,s8
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    8000035a:	b7c9                	j	8000031c <mappages+0x42>
    panic("mappages: va not aligned");
    8000035c:	00002517          	auipc	a0,0x2
    80000360:	db450513          	add	a0,a0,-588 # 80002110 <etext+0x110>
    80000364:	00000097          	auipc	ra,0x0
    80000368:	728080e7          	jalr	1832(ra) # 80000a8c <panic>
    panic("mappages: size not aligned");
    8000036c:	00002517          	auipc	a0,0x2
    80000370:	dc450513          	add	a0,a0,-572 # 80002130 <etext+0x130>
    80000374:	00000097          	auipc	ra,0x0
    80000378:	718080e7          	jalr	1816(ra) # 80000a8c <panic>
    panic("mappages: size");
    8000037c:	00002517          	auipc	a0,0x2
    80000380:	dd450513          	add	a0,a0,-556 # 80002150 <etext+0x150>
    80000384:	00000097          	auipc	ra,0x0
    80000388:	708080e7          	jalr	1800(ra) # 80000a8c <panic>
      panic("mappages: remap");
    8000038c:	00002517          	auipc	a0,0x2
    80000390:	dd450513          	add	a0,a0,-556 # 80002160 <etext+0x160>
    80000394:	00000097          	auipc	ra,0x0
    80000398:	6f8080e7          	jalr	1784(ra) # 80000a8c <panic>
      return -1;
    8000039c:	557d                	li	a0,-1
    pa += PGSIZE;
  }

  return 0;
}
    8000039e:	60a6                	ld	ra,72(sp)
    800003a0:	6406                	ld	s0,64(sp)
    800003a2:	74e2                	ld	s1,56(sp)
    800003a4:	7942                	ld	s2,48(sp)
    800003a6:	79a2                	ld	s3,40(sp)
    800003a8:	7a02                	ld	s4,32(sp)
    800003aa:	6ae2                	ld	s5,24(sp)
    800003ac:	6b42                	ld	s6,16(sp)
    800003ae:	6ba2                	ld	s7,8(sp)
    800003b0:	6c02                	ld	s8,0(sp)
    800003b2:	6161                	add	sp,sp,80
    800003b4:	8082                	ret
  return 0;
    800003b6:	4501                	li	a0,0
    800003b8:	b7dd                	j	8000039e <mappages+0xc4>

00000000800003ba <kvmmap>:
{
    800003ba:	1141                	add	sp,sp,-16
    800003bc:	e406                	sd	ra,8(sp)
    800003be:	e022                	sd	s0,0(sp)
    800003c0:	0800                	add	s0,sp,16
    800003c2:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800003c4:	86b2                	mv	a3,a2
    800003c6:	863e                	mv	a2,a5
    800003c8:	00000097          	auipc	ra,0x0
    800003cc:	f12080e7          	jalr	-238(ra) # 800002da <mappages>
    800003d0:	e509                	bnez	a0,800003da <kvmmap+0x20>
}
    800003d2:	60a2                	ld	ra,8(sp)
    800003d4:	6402                	ld	s0,0(sp)
    800003d6:	0141                	add	sp,sp,16
    800003d8:	8082                	ret
    panic("kvmmap");
    800003da:	00002517          	auipc	a0,0x2
    800003de:	dc650513          	add	a0,a0,-570 # 800021a0 <etext+0x1a0>
    800003e2:	00000097          	auipc	ra,0x0
    800003e6:	6aa080e7          	jalr	1706(ra) # 80000a8c <panic>

00000000800003ea <kvmmake>:
{
    800003ea:	1101                	add	sp,sp,-32
    800003ec:	ec06                	sd	ra,24(sp)
    800003ee:	e822                	sd	s0,16(sp)
    800003f0:	e426                	sd	s1,8(sp)
    800003f2:	e04a                	sd	s2,0(sp)
    800003f4:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc(true);
    800003f6:	4505                	li	a0,1
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	d42080e7          	jalr	-702(ra) # 8000013a <kalloc>
    80000400:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80000402:	6605                	lui	a2,0x1
    80000404:	4581                	li	a1,0
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	43e080e7          	jalr	1086(ra) # 80000844 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000040e:	4719                	li	a4,6
    80000410:	6685                	lui	a3,0x1
    80000412:	10000637          	lui	a2,0x10000
    80000416:	100005b7          	lui	a1,0x10000
    8000041a:	8526                	mv	a0,s1
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	f9e080e7          	jalr	-98(ra) # 800003ba <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80000424:	4719                	li	a4,6
    80000426:	6685                	lui	a3,0x1
    80000428:	10001637          	lui	a2,0x10001
    8000042c:	100015b7          	lui	a1,0x10001
    80000430:	8526                	mv	a0,s1
    80000432:	00000097          	auipc	ra,0x0
    80000436:	f88080e7          	jalr	-120(ra) # 800003ba <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    8000043a:	4719                	li	a4,6
    8000043c:	040006b7          	lui	a3,0x4000
    80000440:	0c000637          	lui	a2,0xc000
    80000444:	0c0005b7          	lui	a1,0xc000
    80000448:	8526                	mv	a0,s1
    8000044a:	00000097          	auipc	ra,0x0
    8000044e:	f70080e7          	jalr	-144(ra) # 800003ba <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80000452:	00002917          	auipc	s2,0x2
    80000456:	bae90913          	add	s2,s2,-1106 # 80002000 <etext>
    8000045a:	4729                	li	a4,10
    8000045c:	80002697          	auipc	a3,0x80002
    80000460:	ba468693          	add	a3,a3,-1116 # 2000 <_entry-0x7fffe000>
    80000464:	4605                	li	a2,1
    80000466:	067e                	sll	a2,a2,0x1f
    80000468:	85b2                	mv	a1,a2
    8000046a:	8526                	mv	a0,s1
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	f4e080e7          	jalr	-178(ra) # 800003ba <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80000474:	4719                	li	a4,6
    80000476:	46c5                	li	a3,17
    80000478:	06ee                	sll	a3,a3,0x1b
    8000047a:	412686b3          	sub	a3,a3,s2
    8000047e:	864a                	mv	a2,s2
    80000480:	85ca                	mv	a1,s2
    80000482:	8526                	mv	a0,s1
    80000484:	00000097          	auipc	ra,0x0
    80000488:	f36080e7          	jalr	-202(ra) # 800003ba <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000048c:	4729                	li	a4,10
    8000048e:	6685                	lui	a3,0x1
    80000490:	00001617          	auipc	a2,0x1
    80000494:	b7060613          	add	a2,a2,-1168 # 80001000 <_trampoline>
    80000498:	040005b7          	lui	a1,0x4000
    8000049c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000049e:	05b2                	sll	a1,a1,0xc
    800004a0:	8526                	mv	a0,s1
    800004a2:	00000097          	auipc	ra,0x0
    800004a6:	f18080e7          	jalr	-232(ra) # 800003ba <kvmmap>
}
    800004aa:	8526                	mv	a0,s1
    800004ac:	60e2                	ld	ra,24(sp)
    800004ae:	6442                	ld	s0,16(sp)
    800004b0:	64a2                	ld	s1,8(sp)
    800004b2:	6902                	ld	s2,0(sp)
    800004b4:	6105                	add	sp,sp,32
    800004b6:	8082                	ret

00000000800004b8 <kvminit>:
{
    800004b8:	1141                	add	sp,sp,-16
    800004ba:	e406                	sd	ra,8(sp)
    800004bc:	e022                	sd	s0,0(sp)
    800004be:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    800004c0:	00000097          	auipc	ra,0x0
    800004c4:	f2a080e7          	jalr	-214(ra) # 800003ea <kvmmake>
    800004c8:	00002797          	auipc	a5,0x2
    800004cc:	e4a7bc23          	sd	a0,-424(a5) # 80002320 <kernel_pagetable>
}
    800004d0:	60a2                	ld	ra,8(sp)
    800004d2:	6402                	ld	s0,0(sp)
    800004d4:	0141                	add	sp,sp,16
    800004d6:	8082                	ret

00000000800004d8 <testvmmap>:

void testvmmap()
{
    800004d8:	1101                	add	sp,sp,-32
    800004da:	ec06                	sd	ra,24(sp)
    800004dc:	e822                	sd	s0,16(sp)
    800004de:	e426                	sd	s1,8(sp)
    800004e0:	1000                	add	s0,sp,32
  pagetable_t kpgtbl;

  kpgtbl = (pagetable_t) kalloc(true);
    800004e2:	4505                	li	a0,1
    800004e4:	00000097          	auipc	ra,0x0
    800004e8:	c56080e7          	jalr	-938(ra) # 8000013a <kalloc>
    800004ec:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800004ee:	6605                	lui	a2,0x1
    800004f0:	4581                	li	a1,0
    800004f2:	00000097          	auipc	ra,0x0
    800004f6:	352080e7          	jalr	850(ra) # 80000844 <memset>

  printf("\n UART0映射前执行查询: walk(kpgtbl, UART0, 0); \n\n");
    800004fa:	00002517          	auipc	a0,0x2
    800004fe:	cae50513          	add	a0,a0,-850 # 800021a8 <etext+0x1a8>
    80000502:	00000097          	auipc	ra,0x0
    80000506:	5d4080e7          	jalr	1492(ra) # 80000ad6 <printf>
  walk(kpgtbl, UART0, 0); // 查询
    8000050a:	4601                	li	a2,0
    8000050c:	100005b7          	lui	a1,0x10000
    80000510:	8526                	mv	a0,s1
    80000512:	00000097          	auipc	ra,0x0
    80000516:	cb0080e7          	jalr	-848(ra) # 800001c2 <walk>

  //建立
  // uart registers
  printf("\n 进行UART0映射: kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W); \n\n");
    8000051a:	00002517          	auipc	a0,0x2
    8000051e:	cce50513          	add	a0,a0,-818 # 800021e8 <etext+0x1e8>
    80000522:	00000097          	auipc	ra,0x0
    80000526:	5b4080e7          	jalr	1460(ra) # 80000ad6 <printf>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000052a:	4719                	li	a4,6
    8000052c:	6685                	lui	a3,0x1
    8000052e:	10000637          	lui	a2,0x10000
    80000532:	100005b7          	lui	a1,0x10000
    80000536:	8526                	mv	a0,s1
    80000538:	00000097          	auipc	ra,0x0
    8000053c:	e82080e7          	jalr	-382(ra) # 800003ba <kvmmap>

  printf("\n UART0映射后执行查询: walk(kpgtbl, UART0, 0); \n\n");
    80000540:	00002517          	auipc	a0,0x2
    80000544:	cf850513          	add	a0,a0,-776 # 80002238 <etext+0x238>
    80000548:	00000097          	auipc	ra,0x0
    8000054c:	58e080e7          	jalr	1422(ra) # 80000ad6 <printf>
  walk(kpgtbl, UART0, 0); // 查询
    80000550:	4601                	li	a2,0
    80000552:	100005b7          	lui	a1,0x10000
    80000556:	8526                	mv	a0,s1
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	c6a080e7          	jalr	-918(ra) # 800001c2 <walk>
    80000560:	60e2                	ld	ra,24(sp)
    80000562:	6442                	ld	s0,16(sp)
    80000564:	64a2                	ld	s1,8(sp)
    80000566:	6105                	add	sp,sp,32
    80000568:	8082                	ret

000000008000056a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000056a:	1141                	add	sp,sp,-16
    8000056c:	e422                	sd	s0,8(sp)
    8000056e:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80000570:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80000572:	2501                	sext.w	a0,a0
    80000574:	6422                	ld	s0,8(sp)
    80000576:	0141                	add	sp,sp,16
    80000578:	8082                	ret

000000008000057a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000057a:	1141                	add	sp,sp,-16
    8000057c:	e422                	sd	s0,8(sp)
    8000057e:	0800                	add	s0,sp,16
    80000580:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80000582:	2781                	sext.w	a5,a5
    80000584:	078e                	sll	a5,a5,0x3
  return c;
}
    80000586:	00002517          	auipc	a0,0x2
    8000058a:	dda50513          	add	a0,a0,-550 # 80002360 <cpus>
    8000058e:	953e                	add	a0,a0,a5
    80000590:	6422                	ld	s0,8(sp)
    80000592:	0141                	add	sp,sp,16
    80000594:	8082                	ret

0000000080000596 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000596:	1141                	add	sp,sp,-16
    80000598:	e422                	sd	s0,8(sp)
    8000059a:	0800                	add	s0,sp,16
  lk->name = name;
    8000059c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    8000059e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800005a2:	00053823          	sd	zero,16(a0)
}
    800005a6:	6422                	ld	s0,8(sp)
    800005a8:	0141                	add	sp,sp,16
    800005aa:	8082                	ret

00000000800005ac <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    800005ac:	411c                	lw	a5,0(a0)
    800005ae:	e399                	bnez	a5,800005b4 <holding+0x8>
    800005b0:	4501                	li	a0,0
  return r;
}
    800005b2:	8082                	ret
{
    800005b4:	1101                	add	sp,sp,-32
    800005b6:	ec06                	sd	ra,24(sp)
    800005b8:	e822                	sd	s0,16(sp)
    800005ba:	e426                	sd	s1,8(sp)
    800005bc:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    800005be:	6904                	ld	s1,16(a0)
    800005c0:	00000097          	auipc	ra,0x0
    800005c4:	fba080e7          	jalr	-70(ra) # 8000057a <mycpu>
    800005c8:	40a48533          	sub	a0,s1,a0
    800005cc:	00153513          	seqz	a0,a0
}
    800005d0:	60e2                	ld	ra,24(sp)
    800005d2:	6442                	ld	s0,16(sp)
    800005d4:	64a2                	ld	s1,8(sp)
    800005d6:	6105                	add	sp,sp,32
    800005d8:	8082                	ret

00000000800005da <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800005da:	1101                	add	sp,sp,-32
    800005dc:	ec06                	sd	ra,24(sp)
    800005de:	e822                	sd	s0,16(sp)
    800005e0:	e426                	sd	s1,8(sp)
    800005e2:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800005e4:	100024f3          	csrr	s1,sstatus
    800005e8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800005ec:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800005ee:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	f88080e7          	jalr	-120(ra) # 8000057a <mycpu>
    800005fa:	411c                	lw	a5,0(a0)
    800005fc:	cf89                	beqz	a5,80000616 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f7c080e7          	jalr	-132(ra) # 8000057a <mycpu>
    80000606:	411c                	lw	a5,0(a0)
    80000608:	2785                	addw	a5,a5,1
    8000060a:	c11c                	sw	a5,0(a0)
}
    8000060c:	60e2                	ld	ra,24(sp)
    8000060e:	6442                	ld	s0,16(sp)
    80000610:	64a2                	ld	s1,8(sp)
    80000612:	6105                	add	sp,sp,32
    80000614:	8082                	ret
    mycpu()->intena = old;
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f64080e7          	jalr	-156(ra) # 8000057a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    8000061e:	8085                	srl	s1,s1,0x1
    80000620:	8885                	and	s1,s1,1
    80000622:	c144                	sw	s1,4(a0)
    80000624:	bfe9                	j	800005fe <push_off+0x24>

0000000080000626 <acquire>:
{
    80000626:	1101                	add	sp,sp,-32
    80000628:	ec06                	sd	ra,24(sp)
    8000062a:	e822                	sd	s0,16(sp)
    8000062c:	e426                	sd	s1,8(sp)
    8000062e:	1000                	add	s0,sp,32
    80000630:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000632:	00000097          	auipc	ra,0x0
    80000636:	fa8080e7          	jalr	-88(ra) # 800005da <push_off>
  if(holding(lk))
    8000063a:	8526                	mv	a0,s1
    8000063c:	00000097          	auipc	ra,0x0
    80000640:	f70080e7          	jalr	-144(ra) # 800005ac <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000644:	4705                	li	a4,1
  if(holding(lk))
    80000646:	e115                	bnez	a0,8000066a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000648:	87ba                	mv	a5,a4
    8000064a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    8000064e:	2781                	sext.w	a5,a5
    80000650:	ffe5                	bnez	a5,80000648 <acquire+0x22>
  __sync_synchronize();
    80000652:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	f24080e7          	jalr	-220(ra) # 8000057a <mycpu>
    8000065e:	e888                	sd	a0,16(s1)
}
    80000660:	60e2                	ld	ra,24(sp)
    80000662:	6442                	ld	s0,16(sp)
    80000664:	64a2                	ld	s1,8(sp)
    80000666:	6105                	add	sp,sp,32
    80000668:	8082                	ret
    panic("acquire");
    8000066a:	00002517          	auipc	a0,0x2
    8000066e:	c0e50513          	add	a0,a0,-1010 # 80002278 <etext+0x278>
    80000672:	00000097          	auipc	ra,0x0
    80000676:	41a080e7          	jalr	1050(ra) # 80000a8c <panic>

000000008000067a <pop_off>:

void
pop_off(void)
{
    8000067a:	1141                	add	sp,sp,-16
    8000067c:	e406                	sd	ra,8(sp)
    8000067e:	e022                	sd	s0,0(sp)
    80000680:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000682:	00000097          	auipc	ra,0x0
    80000686:	ef8080e7          	jalr	-264(ra) # 8000057a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000068a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000068e:	8b89                	and	a5,a5,2
  if(intr_get())
    80000690:	e78d                	bnez	a5,800006ba <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000692:	411c                	lw	a5,0(a0)
    80000694:	02f05b63          	blez	a5,800006ca <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000698:	37fd                	addw	a5,a5,-1
    8000069a:	0007871b          	sext.w	a4,a5
    8000069e:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    800006a0:	eb09                	bnez	a4,800006b2 <pop_off+0x38>
    800006a2:	415c                	lw	a5,4(a0)
    800006a4:	c799                	beqz	a5,800006b2 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800006a6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800006aa:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800006ae:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800006b2:	60a2                	ld	ra,8(sp)
    800006b4:	6402                	ld	s0,0(sp)
    800006b6:	0141                	add	sp,sp,16
    800006b8:	8082                	ret
    panic("pop_off - interruptible");
    800006ba:	00002517          	auipc	a0,0x2
    800006be:	bc650513          	add	a0,a0,-1082 # 80002280 <etext+0x280>
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	3ca080e7          	jalr	970(ra) # 80000a8c <panic>
    panic("pop_off");
    800006ca:	00002517          	auipc	a0,0x2
    800006ce:	bce50513          	add	a0,a0,-1074 # 80002298 <etext+0x298>
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	3ba080e7          	jalr	954(ra) # 80000a8c <panic>

00000000800006da <release>:
{
    800006da:	1101                	add	sp,sp,-32
    800006dc:	ec06                	sd	ra,24(sp)
    800006de:	e822                	sd	s0,16(sp)
    800006e0:	e426                	sd	s1,8(sp)
    800006e2:	1000                	add	s0,sp,32
    800006e4:	84aa                	mv	s1,a0
  if(!holding(lk))
    800006e6:	00000097          	auipc	ra,0x0
    800006ea:	ec6080e7          	jalr	-314(ra) # 800005ac <holding>
    800006ee:	c115                	beqz	a0,80000712 <release+0x38>
  lk->cpu = 0;
    800006f0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800006f4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800006f8:	0f50000f          	fence	iorw,ow
    800006fc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000700:	00000097          	auipc	ra,0x0
    80000704:	f7a080e7          	jalr	-134(ra) # 8000067a <pop_off>
}
    80000708:	60e2                	ld	ra,24(sp)
    8000070a:	6442                	ld	s0,16(sp)
    8000070c:	64a2                	ld	s1,8(sp)
    8000070e:	6105                	add	sp,sp,32
    80000710:	8082                	ret
    panic("release");
    80000712:	00002517          	auipc	a0,0x2
    80000716:	b8e50513          	add	a0,a0,-1138 # 800022a0 <etext+0x2a0>
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	372080e7          	jalr	882(ra) # 80000a8c <panic>

0000000080000722 <main>:
struct spinlock start_lock;

// start()函数在管理者模式下跳转到此处，所有CPU都会执行
void
main()
{
    80000722:	1141                	add	sp,sp,-16
    80000724:	e406                	sd	ra,8(sp)
    80000726:	e022                	sd	s0,0(sp)
    80000728:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	e40080e7          	jalr	-448(ra) # 8000056a <cpuid>
    // userinit();          // 创建第一个用户进程
    __sync_synchronize();
    started = 1;         // 标记系统启动完成
  } else {
    // 其他CPU等待CPU 0完成初始化
    while(started == 0)
    80000732:	00002717          	auipc	a4,0x2
    80000736:	bf670713          	add	a4,a4,-1034 # 80002328 <started>
  if(cpuid() == 0){
    8000073a:	c505                	beqz	a0,80000762 <main+0x40>
    while(started == 0)
    8000073c:	431c                	lw	a5,0(a4)
    8000073e:	2781                	sext.w	a5,a5
    80000740:	dff5                	beqz	a5,8000073c <main+0x1a>
      ;
    
    __sync_synchronize();
    80000742:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	e24080e7          	jalr	-476(ra) # 8000056a <cpuid>
    8000074e:	85aa                	mv	a1,a0
    80000750:	00002517          	auipc	a0,0x2
    80000754:	b6850513          	add	a0,a0,-1176 # 800022b8 <etext+0x2b8>
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	37e080e7          	jalr	894(ra) # 80000ad6 <printf>
    //kvminithart();       // 开启分页机制
    // trapinithart();   // 安装内核陷阱向量
    // plicinithart();   // 向PLIC请求设备中断
  }
  while(1);
    80000760:	a001                	j	80000760 <main+0x3e>
    initlock(&start_lock,"start_lock");
    80000762:	00002597          	auipc	a1,0x2
    80000766:	b4658593          	add	a1,a1,-1210 # 800022a8 <etext+0x2a8>
    8000076a:	00002517          	auipc	a0,0x2
    8000076e:	c3650513          	add	a0,a0,-970 # 800023a0 <start_lock>
    80000772:	00000097          	auipc	ra,0x0
    80000776:	e24080e7          	jalr	-476(ra) # 80000596 <initlock>
    consoleinit();       // 初始化控制台
    8000077a:	00000097          	auipc	ra,0x0
    8000077e:	6be080e7          	jalr	1726(ra) # 80000e38 <consoleinit>
    printfinit();        // 初始化printf功能
    80000782:	00000097          	auipc	ra,0x0
    80000786:	534080e7          	jalr	1332(ra) # 80000cb6 <printfinit>
    printfinit();
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	52c080e7          	jalr	1324(ra) # 80000cb6 <printfinit>
    printf("\n");
    80000792:	00002517          	auipc	a0,0x2
    80000796:	93e50513          	add	a0,a0,-1730 # 800020d0 <etext+0xd0>
    8000079a:	00000097          	auipc	ra,0x0
    8000079e:	33c080e7          	jalr	828(ra) # 80000ad6 <printf>
    printf("hart %d starting\n", cpuid());
    800007a2:	00000097          	auipc	ra,0x0
    800007a6:	dc8080e7          	jalr	-568(ra) # 8000056a <cpuid>
    800007aa:	85aa                	mv	a1,a0
    800007ac:	00002517          	auipc	a0,0x2
    800007b0:	b0c50513          	add	a0,a0,-1268 # 800022b8 <etext+0x2b8>
    800007b4:	00000097          	auipc	ra,0x0
    800007b8:	322080e7          	jalr	802(ra) # 80000ad6 <printf>
    kinit();             // 物理页面分配器初始化
    800007bc:	00000097          	auipc	ra,0x0
    800007c0:	942080e7          	jalr	-1726(ra) # 800000fe <kinit>
    testvmmap();         // 测试虚拟页表功能
    800007c4:	00000097          	auipc	ra,0x0
    800007c8:	d14080e7          	jalr	-748(ra) # 800004d8 <testvmmap>
    __sync_synchronize();
    800007cc:	0ff0000f          	fence
    started = 1;         // 标记系统启动完成
    800007d0:	4785                	li	a5,1
    800007d2:	00002717          	auipc	a4,0x2
    800007d6:	b4f72b23          	sw	a5,-1194(a4) # 80002328 <started>
    800007da:	b759                	j	80000760 <main+0x3e>

00000000800007dc <start>:
void main();
void timerinit();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];

void start() {
    800007dc:	1141                	add	sp,sp,-16
    800007de:	e422                	sd	s0,8(sp)
    800007e0:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800007e2:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    800007e6:	7779                	lui	a4,0xffffe
    800007e8:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fff433f>
    800007ec:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    800007ee:	6705                	lui	a4,0x1
    800007f0:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800007f4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800007f6:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800007fa:	00000797          	auipc	a5,0x0
    800007fe:	f2878793          	add	a5,a5,-216 # 80000722 <main>
    80000802:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80000806:	4781                	li	a5,0
    80000808:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    8000080c:	67c1                	lui	a5,0x10
    8000080e:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000810:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000814:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000818:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    8000081c:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000820:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    80000824:	57fd                	li	a5,-1
    80000826:	83a9                	srl	a5,a5,0xa
    80000828:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    8000082c:	47bd                	li	a5,15
    8000082e:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000832:	f14027f3          	csrr	a5,mhartid
//   timerinit();

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    80000836:	2781                	sext.w	a5,a5
  asm volatile("mv tp, %0" : : "r" (x));
    80000838:	823e                	mv	tp,a5
  
  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    8000083a:	30200073          	mret
}
    8000083e:	6422                	ld	s0,8(sp)
    80000840:	0141                	add	sp,sp,16
    80000842:	8082                	ret

0000000080000844 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000844:	1141                	add	sp,sp,-16
    80000846:	e422                	sd	s0,8(sp)
    80000848:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    8000084a:	ca19                	beqz	a2,80000860 <memset+0x1c>
    8000084c:	87aa                	mv	a5,a0
    8000084e:	1602                	sll	a2,a2,0x20
    80000850:	9201                	srl	a2,a2,0x20
    80000852:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000856:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    8000085a:	0785                	add	a5,a5,1
    8000085c:	fee79de3          	bne	a5,a4,80000856 <memset+0x12>
  }
  return dst;
}
    80000860:	6422                	ld	s0,8(sp)
    80000862:	0141                	add	sp,sp,16
    80000864:	8082                	ret

0000000080000866 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000866:	1141                	add	sp,sp,-16
    80000868:	e422                	sd	s0,8(sp)
    8000086a:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    8000086c:	ca05                	beqz	a2,8000089c <memcmp+0x36>
    8000086e:	fff6069b          	addw	a3,a2,-1 # fffffff <_entry-0x70000001>
    80000872:	1682                	sll	a3,a3,0x20
    80000874:	9281                	srl	a3,a3,0x20
    80000876:	0685                	add	a3,a3,1 # 1001 <_entry-0x7fffefff>
    80000878:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    8000087a:	00054783          	lbu	a5,0(a0)
    8000087e:	0005c703          	lbu	a4,0(a1)
    80000882:	00e79863          	bne	a5,a4,80000892 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000886:	0505                	add	a0,a0,1
    80000888:	0585                	add	a1,a1,1
  while(n-- > 0){
    8000088a:	fed518e3          	bne	a0,a3,8000087a <memcmp+0x14>
  }

  return 0;
    8000088e:	4501                	li	a0,0
    80000890:	a019                	j	80000896 <memcmp+0x30>
      return *s1 - *s2;
    80000892:	40e7853b          	subw	a0,a5,a4
}
    80000896:	6422                	ld	s0,8(sp)
    80000898:	0141                	add	sp,sp,16
    8000089a:	8082                	ret
  return 0;
    8000089c:	4501                	li	a0,0
    8000089e:	bfe5                	j	80000896 <memcmp+0x30>

00000000800008a0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800008a0:	1141                	add	sp,sp,-16
    800008a2:	e422                	sd	s0,8(sp)
    800008a4:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    800008a6:	c205                	beqz	a2,800008c6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    800008a8:	02a5e263          	bltu	a1,a0,800008cc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800008ac:	1602                	sll	a2,a2,0x20
    800008ae:	9201                	srl	a2,a2,0x20
    800008b0:	00c587b3          	add	a5,a1,a2
{
    800008b4:	872a                	mv	a4,a0
      *d++ = *s++;
    800008b6:	0585                	add	a1,a1,1
    800008b8:	0705                	add	a4,a4,1
    800008ba:	fff5c683          	lbu	a3,-1(a1)
    800008be:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800008c2:	fef59ae3          	bne	a1,a5,800008b6 <memmove+0x16>

  return dst;
}
    800008c6:	6422                	ld	s0,8(sp)
    800008c8:	0141                	add	sp,sp,16
    800008ca:	8082                	ret
  if(s < d && s + n > d){
    800008cc:	02061693          	sll	a3,a2,0x20
    800008d0:	9281                	srl	a3,a3,0x20
    800008d2:	00d58733          	add	a4,a1,a3
    800008d6:	fce57be3          	bgeu	a0,a4,800008ac <memmove+0xc>
    d += n;
    800008da:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800008dc:	fff6079b          	addw	a5,a2,-1
    800008e0:	1782                	sll	a5,a5,0x20
    800008e2:	9381                	srl	a5,a5,0x20
    800008e4:	fff7c793          	not	a5,a5
    800008e8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800008ea:	177d                	add	a4,a4,-1
    800008ec:	16fd                	add	a3,a3,-1
    800008ee:	00074603          	lbu	a2,0(a4)
    800008f2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800008f6:	fee79ae3          	bne	a5,a4,800008ea <memmove+0x4a>
    800008fa:	b7f1                	j	800008c6 <memmove+0x26>

00000000800008fc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800008fc:	1141                	add	sp,sp,-16
    800008fe:	e406                	sd	ra,8(sp)
    80000900:	e022                	sd	s0,0(sp)
    80000902:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000904:	00000097          	auipc	ra,0x0
    80000908:	f9c080e7          	jalr	-100(ra) # 800008a0 <memmove>
}
    8000090c:	60a2                	ld	ra,8(sp)
    8000090e:	6402                	ld	s0,0(sp)
    80000910:	0141                	add	sp,sp,16
    80000912:	8082                	ret

0000000080000914 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000914:	1141                	add	sp,sp,-16
    80000916:	e422                	sd	s0,8(sp)
    80000918:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000091a:	ce11                	beqz	a2,80000936 <strncmp+0x22>
    8000091c:	00054783          	lbu	a5,0(a0)
    80000920:	cf89                	beqz	a5,8000093a <strncmp+0x26>
    80000922:	0005c703          	lbu	a4,0(a1)
    80000926:	00f71a63          	bne	a4,a5,8000093a <strncmp+0x26>
    n--, p++, q++;
    8000092a:	367d                	addw	a2,a2,-1
    8000092c:	0505                	add	a0,a0,1
    8000092e:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000930:	f675                	bnez	a2,8000091c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000932:	4501                	li	a0,0
    80000934:	a809                	j	80000946 <strncmp+0x32>
    80000936:	4501                	li	a0,0
    80000938:	a039                	j	80000946 <strncmp+0x32>
  if(n == 0)
    8000093a:	ca09                	beqz	a2,8000094c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000093c:	00054503          	lbu	a0,0(a0)
    80000940:	0005c783          	lbu	a5,0(a1)
    80000944:	9d1d                	subw	a0,a0,a5
}
    80000946:	6422                	ld	s0,8(sp)
    80000948:	0141                	add	sp,sp,16
    8000094a:	8082                	ret
    return 0;
    8000094c:	4501                	li	a0,0
    8000094e:	bfe5                	j	80000946 <strncmp+0x32>

0000000080000950 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000950:	1141                	add	sp,sp,-16
    80000952:	e422                	sd	s0,8(sp)
    80000954:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000956:	87aa                	mv	a5,a0
    80000958:	86b2                	mv	a3,a2
    8000095a:	367d                	addw	a2,a2,-1
    8000095c:	00d05963          	blez	a3,8000096e <strncpy+0x1e>
    80000960:	0785                	add	a5,a5,1
    80000962:	0005c703          	lbu	a4,0(a1)
    80000966:	fee78fa3          	sb	a4,-1(a5)
    8000096a:	0585                	add	a1,a1,1
    8000096c:	f775                	bnez	a4,80000958 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000096e:	873e                	mv	a4,a5
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	37fd                	addw	a5,a5,-1
    80000974:	00c05963          	blez	a2,80000986 <strncpy+0x36>
    *s++ = 0;
    80000978:	0705                	add	a4,a4,1
    8000097a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    8000097e:	40e786bb          	subw	a3,a5,a4
    80000982:	fed04be3          	bgtz	a3,80000978 <strncpy+0x28>
  return os;
}
    80000986:	6422                	ld	s0,8(sp)
    80000988:	0141                	add	sp,sp,16
    8000098a:	8082                	ret

000000008000098c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000098c:	1141                	add	sp,sp,-16
    8000098e:	e422                	sd	s0,8(sp)
    80000990:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000992:	02c05363          	blez	a2,800009b8 <safestrcpy+0x2c>
    80000996:	fff6069b          	addw	a3,a2,-1
    8000099a:	1682                	sll	a3,a3,0x20
    8000099c:	9281                	srl	a3,a3,0x20
    8000099e:	96ae                	add	a3,a3,a1
    800009a0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800009a2:	00d58963          	beq	a1,a3,800009b4 <safestrcpy+0x28>
    800009a6:	0585                	add	a1,a1,1
    800009a8:	0785                	add	a5,a5,1
    800009aa:	fff5c703          	lbu	a4,-1(a1)
    800009ae:	fee78fa3          	sb	a4,-1(a5)
    800009b2:	fb65                	bnez	a4,800009a2 <safestrcpy+0x16>
    ;
  *s = 0;
    800009b4:	00078023          	sb	zero,0(a5)
  return os;
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	add	sp,sp,16
    800009bc:	8082                	ret

00000000800009be <strlen>:

int
strlen(const char *s)
{
    800009be:	1141                	add	sp,sp,-16
    800009c0:	e422                	sd	s0,8(sp)
    800009c2:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800009c4:	00054783          	lbu	a5,0(a0)
    800009c8:	cf91                	beqz	a5,800009e4 <strlen+0x26>
    800009ca:	0505                	add	a0,a0,1
    800009cc:	87aa                	mv	a5,a0
    800009ce:	86be                	mv	a3,a5
    800009d0:	0785                	add	a5,a5,1
    800009d2:	fff7c703          	lbu	a4,-1(a5)
    800009d6:	ff65                	bnez	a4,800009ce <strlen+0x10>
    800009d8:	40a6853b          	subw	a0,a3,a0
    800009dc:	2505                	addw	a0,a0,1
    ;
  return n;
}
    800009de:	6422                	ld	s0,8(sp)
    800009e0:	0141                	add	sp,sp,16
    800009e2:	8082                	ret
  for(n = 0; s[n]; n++)
    800009e4:	4501                	li	a0,0
    800009e6:	bfe5                	j	800009de <strlen+0x20>

00000000800009e8 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800009e8:	7179                	add	sp,sp,-48
    800009ea:	f406                	sd	ra,40(sp)
    800009ec:	f022                	sd	s0,32(sp)
    800009ee:	ec26                	sd	s1,24(sp)
    800009f0:	e84a                	sd	s2,16(sp)
    800009f2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800009f4:	c219                	beqz	a2,800009fa <printint+0x12>
    800009f6:	08054763          	bltz	a0,80000a84 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800009fa:	2501                	sext.w	a0,a0
    800009fc:	4881                	li	a7,0
    800009fe:	fd040693          	add	a3,s0,-48

  i = 0;
    80000a02:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000a04:	2581                	sext.w	a1,a1
    80000a06:	00002617          	auipc	a2,0x2
    80000a0a:	8f260613          	add	a2,a2,-1806 # 800022f8 <digits>
    80000a0e:	883a                	mv	a6,a4
    80000a10:	2705                	addw	a4,a4,1
    80000a12:	02b577bb          	remuw	a5,a0,a1
    80000a16:	1782                	sll	a5,a5,0x20
    80000a18:	9381                	srl	a5,a5,0x20
    80000a1a:	97b2                	add	a5,a5,a2
    80000a1c:	0007c783          	lbu	a5,0(a5)
    80000a20:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000a24:	0005079b          	sext.w	a5,a0
    80000a28:	02b5553b          	divuw	a0,a0,a1
    80000a2c:	0685                	add	a3,a3,1
    80000a2e:	feb7f0e3          	bgeu	a5,a1,80000a0e <printint+0x26>

  if(sign)
    80000a32:	00088c63          	beqz	a7,80000a4a <printint+0x62>
    buf[i++] = '-';
    80000a36:	fe070793          	add	a5,a4,-32
    80000a3a:	00878733          	add	a4,a5,s0
    80000a3e:	02d00793          	li	a5,45
    80000a42:	fef70823          	sb	a5,-16(a4)
    80000a46:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    80000a4a:	02e05763          	blez	a4,80000a78 <printint+0x90>
    80000a4e:	fd040793          	add	a5,s0,-48
    80000a52:	00e784b3          	add	s1,a5,a4
    80000a56:	fff78913          	add	s2,a5,-1
    80000a5a:	993a                	add	s2,s2,a4
    80000a5c:	377d                	addw	a4,a4,-1
    80000a5e:	1702                	sll	a4,a4,0x20
    80000a60:	9301                	srl	a4,a4,0x20
    80000a62:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000a66:	fff4c503          	lbu	a0,-1(s1)
    80000a6a:	00000097          	auipc	ra,0x0
    80000a6e:	38c080e7          	jalr	908(ra) # 80000df6 <consputc>
  while(--i >= 0)
    80000a72:	14fd                	add	s1,s1,-1
    80000a74:	ff2499e3          	bne	s1,s2,80000a66 <printint+0x7e>
}
    80000a78:	70a2                	ld	ra,40(sp)
    80000a7a:	7402                	ld	s0,32(sp)
    80000a7c:	64e2                	ld	s1,24(sp)
    80000a7e:	6942                	ld	s2,16(sp)
    80000a80:	6145                	add	sp,sp,48
    80000a82:	8082                	ret
    x = -xx;
    80000a84:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000a88:	4885                	li	a7,1
    x = -xx;
    80000a8a:	bf95                	j	800009fe <printint+0x16>

0000000080000a8c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000a8c:	1101                	add	sp,sp,-32
    80000a8e:	ec06                	sd	ra,24(sp)
    80000a90:	e822                	sd	s0,16(sp)
    80000a92:	e426                	sd	s1,8(sp)
    80000a94:	1000                	add	s0,sp,32
    80000a96:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000a98:	0000a797          	auipc	a5,0xa
    80000a9c:	9407a023          	sw	zero,-1728(a5) # 8000a3d8 <pr+0x18>
  printf("panic: ");
    80000aa0:	00002517          	auipc	a0,0x2
    80000aa4:	83050513          	add	a0,a0,-2000 # 800022d0 <etext+0x2d0>
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	02e080e7          	jalr	46(ra) # 80000ad6 <printf>
  printf(s);
    80000ab0:	8526                	mv	a0,s1
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	024080e7          	jalr	36(ra) # 80000ad6 <printf>
  printf("\n");
    80000aba:	00001517          	auipc	a0,0x1
    80000abe:	61650513          	add	a0,a0,1558 # 800020d0 <etext+0xd0>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	014080e7          	jalr	20(ra) # 80000ad6 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000aca:	4785                	li	a5,1
    80000acc:	00002717          	auipc	a4,0x2
    80000ad0:	86f72023          	sw	a5,-1952(a4) # 8000232c <panicked>
  for(;;)
    80000ad4:	a001                	j	80000ad4 <panic+0x48>

0000000080000ad6 <printf>:
{
    80000ad6:	7131                	add	sp,sp,-192
    80000ad8:	fc86                	sd	ra,120(sp)
    80000ada:	f8a2                	sd	s0,112(sp)
    80000adc:	f4a6                	sd	s1,104(sp)
    80000ade:	f0ca                	sd	s2,96(sp)
    80000ae0:	ecce                	sd	s3,88(sp)
    80000ae2:	e8d2                	sd	s4,80(sp)
    80000ae4:	e4d6                	sd	s5,72(sp)
    80000ae6:	e0da                	sd	s6,64(sp)
    80000ae8:	fc5e                	sd	s7,56(sp)
    80000aea:	f862                	sd	s8,48(sp)
    80000aec:	f466                	sd	s9,40(sp)
    80000aee:	f06a                	sd	s10,32(sp)
    80000af0:	ec6e                	sd	s11,24(sp)
    80000af2:	0100                	add	s0,sp,128
    80000af4:	8a2a                	mv	s4,a0
    80000af6:	e40c                	sd	a1,8(s0)
    80000af8:	e810                	sd	a2,16(s0)
    80000afa:	ec14                	sd	a3,24(s0)
    80000afc:	f018                	sd	a4,32(s0)
    80000afe:	f41c                	sd	a5,40(s0)
    80000b00:	03043823          	sd	a6,48(s0)
    80000b04:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000b08:	0000ad97          	auipc	s11,0xa
    80000b0c:	8d0dad83          	lw	s11,-1840(s11) # 8000a3d8 <pr+0x18>
  if(locking)
    80000b10:	020d9b63          	bnez	s11,80000b46 <printf+0x70>
  if (fmt == 0)
    80000b14:	040a0263          	beqz	s4,80000b58 <printf+0x82>
  va_start(ap, fmt);
    80000b18:	00840793          	add	a5,s0,8
    80000b1c:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000b20:	000a4503          	lbu	a0,0(s4)
    80000b24:	14050f63          	beqz	a0,80000c82 <printf+0x1ac>
    80000b28:	4981                	li	s3,0
    if(c != '%'){
    80000b2a:	02500a93          	li	s5,37
    switch(c){
    80000b2e:	07000b93          	li	s7,112
  consputc('x');
    80000b32:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000b34:	00001b17          	auipc	s6,0x1
    80000b38:	7c4b0b13          	add	s6,s6,1988 # 800022f8 <digits>
    switch(c){
    80000b3c:	07300c93          	li	s9,115
    80000b40:	06400c13          	li	s8,100
    80000b44:	a82d                	j	80000b7e <printf+0xa8>
    acquire(&pr.lock);
    80000b46:	0000a517          	auipc	a0,0xa
    80000b4a:	87a50513          	add	a0,a0,-1926 # 8000a3c0 <pr>
    80000b4e:	00000097          	auipc	ra,0x0
    80000b52:	ad8080e7          	jalr	-1320(ra) # 80000626 <acquire>
    80000b56:	bf7d                	j	80000b14 <printf+0x3e>
    panic("null fmt");
    80000b58:	00001517          	auipc	a0,0x1
    80000b5c:	78850513          	add	a0,a0,1928 # 800022e0 <etext+0x2e0>
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	f2c080e7          	jalr	-212(ra) # 80000a8c <panic>
      consputc(c);
    80000b68:	00000097          	auipc	ra,0x0
    80000b6c:	28e080e7          	jalr	654(ra) # 80000df6 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000b70:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    80000b72:	013a07b3          	add	a5,s4,s3
    80000b76:	0007c503          	lbu	a0,0(a5)
    80000b7a:	10050463          	beqz	a0,80000c82 <printf+0x1ac>
    if(c != '%'){
    80000b7e:	ff5515e3          	bne	a0,s5,80000b68 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000b82:	2985                	addw	s3,s3,1
    80000b84:	013a07b3          	add	a5,s4,s3
    80000b88:	0007c783          	lbu	a5,0(a5)
    80000b8c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000b90:	cbed                	beqz	a5,80000c82 <printf+0x1ac>
    switch(c){
    80000b92:	05778a63          	beq	a5,s7,80000be6 <printf+0x110>
    80000b96:	02fbf663          	bgeu	s7,a5,80000bc2 <printf+0xec>
    80000b9a:	09978863          	beq	a5,s9,80000c2a <printf+0x154>
    80000b9e:	07800713          	li	a4,120
    80000ba2:	0ce79563          	bne	a5,a4,80000c6c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000ba6:	f8843783          	ld	a5,-120(s0)
    80000baa:	00878713          	add	a4,a5,8
    80000bae:	f8e43423          	sd	a4,-120(s0)
    80000bb2:	4605                	li	a2,1
    80000bb4:	85ea                	mv	a1,s10
    80000bb6:	4388                	lw	a0,0(a5)
    80000bb8:	00000097          	auipc	ra,0x0
    80000bbc:	e30080e7          	jalr	-464(ra) # 800009e8 <printint>
      break;
    80000bc0:	bf45                	j	80000b70 <printf+0x9a>
    switch(c){
    80000bc2:	09578f63          	beq	a5,s5,80000c60 <printf+0x18a>
    80000bc6:	0b879363          	bne	a5,s8,80000c6c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000bca:	f8843783          	ld	a5,-120(s0)
    80000bce:	00878713          	add	a4,a5,8
    80000bd2:	f8e43423          	sd	a4,-120(s0)
    80000bd6:	4605                	li	a2,1
    80000bd8:	45a9                	li	a1,10
    80000bda:	4388                	lw	a0,0(a5)
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	e0c080e7          	jalr	-500(ra) # 800009e8 <printint>
      break;
    80000be4:	b771                	j	80000b70 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000be6:	f8843783          	ld	a5,-120(s0)
    80000bea:	00878713          	add	a4,a5,8
    80000bee:	f8e43423          	sd	a4,-120(s0)
    80000bf2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000bf6:	03000513          	li	a0,48
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	1fc080e7          	jalr	508(ra) # 80000df6 <consputc>
  consputc('x');
    80000c02:	07800513          	li	a0,120
    80000c06:	00000097          	auipc	ra,0x0
    80000c0a:	1f0080e7          	jalr	496(ra) # 80000df6 <consputc>
    80000c0e:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000c10:	03c95793          	srl	a5,s2,0x3c
    80000c14:	97da                	add	a5,a5,s6
    80000c16:	0007c503          	lbu	a0,0(a5)
    80000c1a:	00000097          	auipc	ra,0x0
    80000c1e:	1dc080e7          	jalr	476(ra) # 80000df6 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000c22:	0912                	sll	s2,s2,0x4
    80000c24:	34fd                	addw	s1,s1,-1
    80000c26:	f4ed                	bnez	s1,80000c10 <printf+0x13a>
    80000c28:	b7a1                	j	80000b70 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000c2a:	f8843783          	ld	a5,-120(s0)
    80000c2e:	00878713          	add	a4,a5,8
    80000c32:	f8e43423          	sd	a4,-120(s0)
    80000c36:	6384                	ld	s1,0(a5)
    80000c38:	cc89                	beqz	s1,80000c52 <printf+0x17c>
      for(; *s; s++)
    80000c3a:	0004c503          	lbu	a0,0(s1)
    80000c3e:	d90d                	beqz	a0,80000b70 <printf+0x9a>
        consputc(*s);
    80000c40:	00000097          	auipc	ra,0x0
    80000c44:	1b6080e7          	jalr	438(ra) # 80000df6 <consputc>
      for(; *s; s++)
    80000c48:	0485                	add	s1,s1,1
    80000c4a:	0004c503          	lbu	a0,0(s1)
    80000c4e:	f96d                	bnez	a0,80000c40 <printf+0x16a>
    80000c50:	b705                	j	80000b70 <printf+0x9a>
        s = "(null)";
    80000c52:	00001497          	auipc	s1,0x1
    80000c56:	68648493          	add	s1,s1,1670 # 800022d8 <etext+0x2d8>
      for(; *s; s++)
    80000c5a:	02800513          	li	a0,40
    80000c5e:	b7cd                	j	80000c40 <printf+0x16a>
      consputc('%');
    80000c60:	8556                	mv	a0,s5
    80000c62:	00000097          	auipc	ra,0x0
    80000c66:	194080e7          	jalr	404(ra) # 80000df6 <consputc>
      break;
    80000c6a:	b719                	j	80000b70 <printf+0x9a>
      consputc('%');
    80000c6c:	8556                	mv	a0,s5
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	188080e7          	jalr	392(ra) # 80000df6 <consputc>
      consputc(c);
    80000c76:	8526                	mv	a0,s1
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	17e080e7          	jalr	382(ra) # 80000df6 <consputc>
      break;
    80000c80:	bdc5                	j	80000b70 <printf+0x9a>
  if(locking)
    80000c82:	020d9163          	bnez	s11,80000ca4 <printf+0x1ce>
}
    80000c86:	70e6                	ld	ra,120(sp)
    80000c88:	7446                	ld	s0,112(sp)
    80000c8a:	74a6                	ld	s1,104(sp)
    80000c8c:	7906                	ld	s2,96(sp)
    80000c8e:	69e6                	ld	s3,88(sp)
    80000c90:	6a46                	ld	s4,80(sp)
    80000c92:	6aa6                	ld	s5,72(sp)
    80000c94:	6b06                	ld	s6,64(sp)
    80000c96:	7be2                	ld	s7,56(sp)
    80000c98:	7c42                	ld	s8,48(sp)
    80000c9a:	7ca2                	ld	s9,40(sp)
    80000c9c:	7d02                	ld	s10,32(sp)
    80000c9e:	6de2                	ld	s11,24(sp)
    80000ca0:	6129                	add	sp,sp,192
    80000ca2:	8082                	ret
    release(&pr.lock);
    80000ca4:	00009517          	auipc	a0,0x9
    80000ca8:	71c50513          	add	a0,a0,1820 # 8000a3c0 <pr>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	a2e080e7          	jalr	-1490(ra) # 800006da <release>
}
    80000cb4:	bfc9                	j	80000c86 <printf+0x1b0>

0000000080000cb6 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000cb6:	1101                	add	sp,sp,-32
    80000cb8:	ec06                	sd	ra,24(sp)
    80000cba:	e822                	sd	s0,16(sp)
    80000cbc:	e426                	sd	s1,8(sp)
    80000cbe:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000cc0:	00009497          	auipc	s1,0x9
    80000cc4:	70048493          	add	s1,s1,1792 # 8000a3c0 <pr>
    80000cc8:	00001597          	auipc	a1,0x1
    80000ccc:	62858593          	add	a1,a1,1576 # 800022f0 <etext+0x2f0>
    80000cd0:	8526                	mv	a0,s1
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	8c4080e7          	jalr	-1852(ra) # 80000596 <initlock>
  pr.locking = 1;
    80000cda:	4785                	li	a5,1
    80000cdc:	cc9c                	sw	a5,24(s1)
}
    80000cde:	60e2                	ld	ra,24(sp)
    80000ce0:	6442                	ld	s0,16(sp)
    80000ce2:	64a2                	ld	s1,8(sp)
    80000ce4:	6105                	add	sp,sp,32
    80000ce6:	8082                	ret

0000000080000ce8 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000ce8:	1141                	add	sp,sp,-16
    80000cea:	e406                	sd	ra,8(sp)
    80000cec:	e022                	sd	s0,0(sp)
    80000cee:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000cf0:	100007b7          	lui	a5,0x10000
    80000cf4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000cf8:	f8000713          	li	a4,-128
    80000cfc:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000d00:	470d                	li	a4,3
    80000d02:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000d06:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000d0a:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000d0e:	469d                	li	a3,7
    80000d10:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000d14:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000d18:	00001597          	auipc	a1,0x1
    80000d1c:	5f858593          	add	a1,a1,1528 # 80002310 <digits+0x18>
    80000d20:	00009517          	auipc	a0,0x9
    80000d24:	6c050513          	add	a0,a0,1728 # 8000a3e0 <uart_tx_lock>
    80000d28:	00000097          	auipc	ra,0x0
    80000d2c:	86e080e7          	jalr	-1938(ra) # 80000596 <initlock>
}
    80000d30:	60a2                	ld	ra,8(sp)
    80000d32:	6402                	ld	s0,0(sp)
    80000d34:	0141                	add	sp,sp,16
    80000d36:	8082                	ret

0000000080000d38 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000d38:	1101                	add	sp,sp,-32
    80000d3a:	ec06                	sd	ra,24(sp)
    80000d3c:	e822                	sd	s0,16(sp)
    80000d3e:	e426                	sd	s1,8(sp)
    80000d40:	1000                	add	s0,sp,32
    80000d42:	84aa                	mv	s1,a0
  push_off();
    80000d44:	00000097          	auipc	ra,0x0
    80000d48:	896080e7          	jalr	-1898(ra) # 800005da <push_off>

  if(panicked){
    80000d4c:	00001797          	auipc	a5,0x1
    80000d50:	5e07a783          	lw	a5,1504(a5) # 8000232c <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000d54:	10000737          	lui	a4,0x10000
  if(panicked){
    80000d58:	c391                	beqz	a5,80000d5c <uartputc_sync+0x24>
    for(;;)
    80000d5a:	a001                	j	80000d5a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000d5c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000d60:	0207f793          	and	a5,a5,32
    80000d64:	dfe5                	beqz	a5,80000d5c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000d66:	0ff4f513          	zext.b	a0,s1
    80000d6a:	100007b7          	lui	a5,0x10000
    80000d6e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000d72:	00000097          	auipc	ra,0x0
    80000d76:	908080e7          	jalr	-1784(ra) # 8000067a <pop_off>
}
    80000d7a:	60e2                	ld	ra,24(sp)
    80000d7c:	6442                	ld	s0,16(sp)
    80000d7e:	64a2                	ld	s1,8(sp)
    80000d80:	6105                	add	sp,sp,32
    80000d82:	8082                	ret

0000000080000d84 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000d84:	1141                	add	sp,sp,-16
    80000d86:	e422                	sd	s0,8(sp)
    80000d88:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000d8a:	100007b7          	lui	a5,0x10000
    80000d8e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000d92:	8b85                	and	a5,a5,1
    80000d94:	cb81                	beqz	a5,80000da4 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000d96:	100007b7          	lui	a5,0x10000
    80000d9a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	add	sp,sp,16
    80000da2:	8082                	ret
    return -1;
    80000da4:	557d                	li	a0,-1
    80000da6:	bfe5                	j	80000d9e <uartgetc+0x1a>

0000000080000da8 <uart_putc>:
//   uartstart();
//   release(&uart_tx_lock);
// }


void uart_putc(char c) {
    80000da8:	1141                	add	sp,sp,-16
    80000daa:	e422                	sd	s0,8(sp)
    80000dac:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    80000dae:	10000737          	lui	a4,0x10000
    80000db2:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000db6:	0207f793          	and	a5,a5,32
    80000dba:	dfe5                	beqz	a5,80000db2 <uart_putc+0xa>
    uart[0] = c;
    80000dbc:	100007b7          	lui	a5,0x10000
    80000dc0:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    80000dc4:	6422                	ld	s0,8(sp)
    80000dc6:	0141                	add	sp,sp,16
    80000dc8:	8082                	ret

0000000080000dca <uart_puts>:

void uart_puts(char *s) {
    80000dca:	1101                	add	sp,sp,-32
    80000dcc:	ec06                	sd	ra,24(sp)
    80000dce:	e822                	sd	s0,16(sp)
    80000dd0:	e426                	sd	s1,8(sp)
    80000dd2:	1000                	add	s0,sp,32
    80000dd4:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	c909                	beqz	a0,80000dec <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    80000ddc:	00000097          	auipc	ra,0x0
    80000de0:	fcc080e7          	jalr	-52(ra) # 80000da8 <uart_putc>
        s++;              // 移动到下一个字符
    80000de4:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000de6:	0004c503          	lbu	a0,0(s1)
    80000dea:	f96d                	bnez	a0,80000ddc <uart_puts+0x12>
    }
}
    80000dec:	60e2                	ld	ra,24(sp)
    80000dee:	6442                	ld	s0,16(sp)
    80000df0:	64a2                	ld	s1,8(sp)
    80000df2:	6105                	add	sp,sp,32
    80000df4:	8082                	ret

0000000080000df6 <consputc>:
// called by printf(), and to echo input characters,
// but not from write().
//
void
consputc(int c)
{
    80000df6:	1141                	add	sp,sp,-16
    80000df8:	e406                	sd	ra,8(sp)
    80000dfa:	e022                	sd	s0,0(sp)
    80000dfc:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000dfe:	10000793          	li	a5,256
    80000e02:	00f50a63          	beq	a0,a5,80000e16 <consputc+0x20>
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
    80000e06:	00000097          	auipc	ra,0x0
    80000e0a:	f32080e7          	jalr	-206(ra) # 80000d38 <uartputc_sync>
  }
}
    80000e0e:	60a2                	ld	ra,8(sp)
    80000e10:	6402                	ld	s0,0(sp)
    80000e12:	0141                	add	sp,sp,16
    80000e14:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000e16:	4521                	li	a0,8
    80000e18:	00000097          	auipc	ra,0x0
    80000e1c:	f20080e7          	jalr	-224(ra) # 80000d38 <uartputc_sync>
    80000e20:	02000513          	li	a0,32
    80000e24:	00000097          	auipc	ra,0x0
    80000e28:	f14080e7          	jalr	-236(ra) # 80000d38 <uartputc_sync>
    80000e2c:	4521                	li	a0,8
    80000e2e:	00000097          	auipc	ra,0x0
    80000e32:	f0a080e7          	jalr	-246(ra) # 80000d38 <uartputc_sync>
    80000e36:	bfe1                	j	80000e0e <consputc+0x18>

0000000080000e38 <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    80000e38:	1141                	add	sp,sp,-16
    80000e3a:	e406                	sd	ra,8(sp)
    80000e3c:	e022                	sd	s0,0(sp)
    80000e3e:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000e40:	00001597          	auipc	a1,0x1
    80000e44:	4d858593          	add	a1,a1,1240 # 80002318 <digits+0x20>
    80000e48:	00009517          	auipc	a0,0x9
    80000e4c:	5d050513          	add	a0,a0,1488 # 8000a418 <cons>
    80000e50:	fffff097          	auipc	ra,0xfffff
    80000e54:	746080e7          	jalr	1862(ra) # 80000596 <initlock>

  uartinit();
    80000e58:	00000097          	auipc	ra,0x0
    80000e5c:	e90080e7          	jalr	-368(ra) # 80000ce8 <uartinit>

  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    80000e60:	60a2                	ld	ra,8(sp)
    80000e62:	6402                	ld	s0,0(sp)
    80000e64:	0141                	add	sp,sp,16
    80000e66:	8082                	ret
	...

0000000080001000 <_trampoline>:
    80001000:	14051073          	csrw	sscratch,a0
    80001004:	02000537          	lui	a0,0x2000
    80001008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000100a:	0536                	sll	a0,a0,0xd
    8000100c:	02153423          	sd	ra,40(a0)
    80001010:	02253823          	sd	sp,48(a0)
    80001014:	02353c23          	sd	gp,56(a0)
    80001018:	04453023          	sd	tp,64(a0)
    8000101c:	04553423          	sd	t0,72(a0)
    80001020:	04653823          	sd	t1,80(a0)
    80001024:	04753c23          	sd	t2,88(a0)
    80001028:	f120                	sd	s0,96(a0)
    8000102a:	f524                	sd	s1,104(a0)
    8000102c:	fd2c                	sd	a1,120(a0)
    8000102e:	e150                	sd	a2,128(a0)
    80001030:	e554                	sd	a3,136(a0)
    80001032:	e958                	sd	a4,144(a0)
    80001034:	ed5c                	sd	a5,152(a0)
    80001036:	0b053023          	sd	a6,160(a0)
    8000103a:	0b153423          	sd	a7,168(a0)
    8000103e:	0b253823          	sd	s2,176(a0)
    80001042:	0b353c23          	sd	s3,184(a0)
    80001046:	0d453023          	sd	s4,192(a0)
    8000104a:	0d553423          	sd	s5,200(a0)
    8000104e:	0d653823          	sd	s6,208(a0)
    80001052:	0d753c23          	sd	s7,216(a0)
    80001056:	0f853023          	sd	s8,224(a0)
    8000105a:	0f953423          	sd	s9,232(a0)
    8000105e:	0fa53823          	sd	s10,240(a0)
    80001062:	0fb53c23          	sd	s11,248(a0)
    80001066:	11c53023          	sd	t3,256(a0)
    8000106a:	11d53423          	sd	t4,264(a0)
    8000106e:	11e53823          	sd	t5,272(a0)
    80001072:	11f53c23          	sd	t6,280(a0)
    80001076:	140022f3          	csrr	t0,sscratch
    8000107a:	06553823          	sd	t0,112(a0)
    8000107e:	00853103          	ld	sp,8(a0)
    80001082:	02053203          	ld	tp,32(a0)
    80001086:	01053283          	ld	t0,16(a0)
    8000108a:	00053303          	ld	t1,0(a0)
    8000108e:	12000073          	sfence.vma
    80001092:	18031073          	csrw	satp,t1
    80001096:	12000073          	sfence.vma
    8000109a:	9282                	jalr	t0

000000008000109c <userret>:
    8000109c:	12000073          	sfence.vma
    800010a0:	18051073          	csrw	satp,a0
    800010a4:	12000073          	sfence.vma
    800010a8:	02000537          	lui	a0,0x2000
    800010ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800010ae:	0536                	sll	a0,a0,0xd
    800010b0:	02853083          	ld	ra,40(a0)
    800010b4:	03053103          	ld	sp,48(a0)
    800010b8:	03853183          	ld	gp,56(a0)
    800010bc:	04053203          	ld	tp,64(a0)
    800010c0:	04853283          	ld	t0,72(a0)
    800010c4:	05053303          	ld	t1,80(a0)
    800010c8:	05853383          	ld	t2,88(a0)
    800010cc:	7120                	ld	s0,96(a0)
    800010ce:	7524                	ld	s1,104(a0)
    800010d0:	7d2c                	ld	a1,120(a0)
    800010d2:	6150                	ld	a2,128(a0)
    800010d4:	6554                	ld	a3,136(a0)
    800010d6:	6958                	ld	a4,144(a0)
    800010d8:	6d5c                	ld	a5,152(a0)
    800010da:	0a053803          	ld	a6,160(a0)
    800010de:	0a853883          	ld	a7,168(a0)
    800010e2:	0b053903          	ld	s2,176(a0)
    800010e6:	0b853983          	ld	s3,184(a0)
    800010ea:	0c053a03          	ld	s4,192(a0)
    800010ee:	0c853a83          	ld	s5,200(a0)
    800010f2:	0d053b03          	ld	s6,208(a0)
    800010f6:	0d853b83          	ld	s7,216(a0)
    800010fa:	0e053c03          	ld	s8,224(a0)
    800010fe:	0e853c83          	ld	s9,232(a0)
    80001102:	0f053d03          	ld	s10,240(a0)
    80001106:	0f853d83          	ld	s11,248(a0)
    8000110a:	10053e03          	ld	t3,256(a0)
    8000110e:	10853e83          	ld	t4,264(a0)
    80001112:	11053f03          	ld	t5,272(a0)
    80001116:	11853f83          	ld	t6,280(a0)
    8000111a:	7928                	ld	a0,112(a0)
    8000111c:	10200073          	sret
	...
