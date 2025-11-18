
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.global _entry
_entry:
    # 为C语言代码设置栈空间
    # stack0声明在start.c中，每个CPU分配4096字节的栈空间
    # 计算公式: sp = stack0基地址 + (硬件线程ID * 4096)
    la sp, stack0        # 加载stack0的基地址到栈指针sp
    80000000:	00004117          	auipc	sp,0x4
    80000004:	69010113          	add	sp,sp,1680 # 80004690 <stack0>
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
    80000016:	00004517          	auipc	a0,0x4
    8000001a:	62a50513          	add	a0,a0,1578 # 80004640 <started>
    la a1, end
    8000001e:	00010597          	auipc	a1,0x10
    80000022:	f0a58593          	add	a1,a1,-246 # 8000ff28 <end>

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
    80000034:	112080e7          	jalr	274(ra) # 80000142 <start>

0000000080000038 <spin>:
spin:
    80000038:	a001                	j	80000038 <spin>

000000008000003a <main>:
struct spinlock start_lock;

// start()函数在管理者模式下跳转到此处，所有CPU都会执行
void
main()
{
    8000003a:	1141                	add	sp,sp,-16
    8000003c:	e406                	sd	ra,8(sp)
    8000003e:	e022                	sd	s0,0(sp)
    80000040:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000042:	00001097          	auipc	ra,0x1
    80000046:	3ac080e7          	jalr	940(ra) # 800013ee <cpuid>
    started = 1;         // 标记系统启动完成
    __sync_synchronize();

  } else {
    //其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000004a:	00004717          	auipc	a4,0x4
    8000004e:	5f670713          	add	a4,a4,1526 # 80004640 <started>
  if(cpuid() == 0){
    80000052:	c139                	beqz	a0,80000098 <main+0x5e>
    while(started == 0)
    80000054:	431c                	lw	a5,0(a4)
    80000056:	2781                	sext.w	a5,a5
    80000058:	dff5                	beqz	a5,80000054 <main+0x1a>
      ;
    
    __sync_synchronize();
    8000005a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000005e:	00001097          	auipc	ra,0x1
    80000062:	390080e7          	jalr	912(ra) # 800013ee <cpuid>
    80000066:	85aa                	mv	a1,a0
    80000068:	00004517          	auipc	a0,0x4
    8000006c:	fb850513          	add	a0,a0,-72 # 80004020 <etext+0x20>
    80000070:	00000097          	auipc	ra,0x0
    80000074:	744080e7          	jalr	1860(ra) # 800007b4 <printf>
    kvminithart();       // 开启分页机制
    80000078:	00001097          	auipc	ra,0x1
    8000007c:	aac080e7          	jalr	-1364(ra) # 80000b24 <kvminithart>
    trapinithart();   // 安装内核陷阱向量
    80000080:	00002097          	auipc	ra,0x2
    80000084:	9c2080e7          	jalr	-1598(ra) # 80001a42 <trapinithart>
    plicinithart();   // 向PLIC请求设备中断
    80000088:	00000097          	auipc	ra,0x0
    8000008c:	414080e7          	jalr	1044(ra) # 8000049c <plicinithart>
  }
  // 所有CPU都进入调度器，开始调度用户进程
  scheduler(); 
    80000090:	00002097          	auipc	ra,0x2
    80000094:	b1c080e7          	jalr	-1252(ra) # 80001bac <scheduler>
    initlock(&start_lock,"start_lock");
    80000098:	00004597          	auipc	a1,0x4
    8000009c:	f7858593          	add	a1,a1,-136 # 80004010 <etext+0x10>
    800000a0:	00004517          	auipc	a0,0x4
    800000a4:	5d050513          	add	a0,a0,1488 # 80004670 <start_lock>
    800000a8:	00001097          	auipc	ra,0x1
    800000ac:	7e8080e7          	jalr	2024(ra) # 80001890 <initlock>
    consoleinit();       // 初始化控制台
    800000b0:	00000097          	auipc	ra,0x0
    800000b4:	3a6080e7          	jalr	934(ra) # 80000456 <consoleinit>
    printfinit();        // 初始化printf功能
    800000b8:	00001097          	auipc	ra,0x1
    800000bc:	8dc080e7          	jalr	-1828(ra) # 80000994 <printfinit>
    printf("\n");
    800000c0:	00004517          	auipc	a0,0x4
    800000c4:	f7050513          	add	a0,a0,-144 # 80004030 <etext+0x30>
    800000c8:	00000097          	auipc	ra,0x0
    800000cc:	6ec080e7          	jalr	1772(ra) # 800007b4 <printf>
    printf("hart %d starting\n", cpuid());
    800000d0:	00001097          	auipc	ra,0x1
    800000d4:	31e080e7          	jalr	798(ra) # 800013ee <cpuid>
    800000d8:	85aa                	mv	a1,a0
    800000da:	00004517          	auipc	a0,0x4
    800000de:	f4650513          	add	a0,a0,-186 # 80004020 <etext+0x20>
    800000e2:	00000097          	auipc	ra,0x0
    800000e6:	6d2080e7          	jalr	1746(ra) # 800007b4 <printf>
    kinit();             // 物理页面分配器初始化
    800000ea:	00001097          	auipc	ra,0x1
    800000ee:	9a0080e7          	jalr	-1632(ra) # 80000a8a <kinit>
    kvminit();           // 创建内核页表
    800000f2:	00001097          	auipc	ra,0x1
    800000f6:	cce080e7          	jalr	-818(ra) # 80000dc0 <kvminit>
    kvminithart();       // 开启分页机制
    800000fa:	00001097          	auipc	ra,0x1
    800000fe:	a2a080e7          	jalr	-1494(ra) # 80000b24 <kvminithart>
    procinit();       // 进程表初始化
    80000102:	00001097          	auipc	ra,0x1
    80000106:	46a080e7          	jalr	1130(ra) # 8000156c <procinit>
    timer_create();      // 陷阱向量(时钟中断）初始化
    8000010a:	00000097          	auipc	ra,0x0
    8000010e:	11c080e7          	jalr	284(ra) # 80000226 <timer_create>
    trapinithart();      // 安装内核陷阱向量
    80000112:	00002097          	auipc	ra,0x2
    80000116:	930080e7          	jalr	-1744(ra) # 80001a42 <trapinithart>
    plicinit();          // 设置中断控制器
    8000011a:	00000097          	auipc	ra,0x0
    8000011e:	36c080e7          	jalr	876(ra) # 80000486 <plicinit>
    plicinithart();      // 向PLIC请求设备中断
    80000122:	00000097          	auipc	ra,0x0
    80000126:	37a080e7          	jalr	890(ra) # 8000049c <plicinithart>
    userinit();   // 创建第一个用户进程 userinit();   
    8000012a:	00001097          	auipc	ra,0x1
    8000012e:	6b2080e7          	jalr	1714(ra) # 800017dc <userinit>
    started = 1;         // 标记系统启动完成
    80000132:	4785                	li	a5,1
    80000134:	00004717          	auipc	a4,0x4
    80000138:	50f72623          	sw	a5,1292(a4) # 80004640 <started>
    __sync_synchronize();
    8000013c:	0ff0000f          	fence
    80000140:	bf81                	j	80000090 <main+0x56>

0000000080000142 <start>:
extern void main();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];


void start() {
    80000142:	1141                	add	sp,sp,-16
    80000144:	e406                	sd	ra,8(sp)
    80000146:	e022                	sd	s0,0(sp)
    80000148:	0800                	add	s0,sp,16

static inline uint64
r_mstatus()
{
  uint64 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000014a:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    8000014e:	7779                	lui	a4,0xffffe
    80000150:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffee8d7>
    80000154:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    80000156:	6705                	lui	a4,0x1
    80000158:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000015c:	8fd9                	or	a5,a5,a4
}

static inline void 
w_mstatus(uint64 x)
{
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000015e:	30079073          	csrw	mstatus,a5
// instruction address to which a return from
// exception will go.
static inline void 
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000162:	00000797          	auipc	a5,0x0
    80000166:	ed878793          	add	a5,a5,-296 # 8000003a <main>
    8000016a:	34179073          	csrw	mepc,a5
// supervisor address translation and protection;
// holds the address of the page table.
static inline void 
w_satp(uint64 x)
{
  asm volatile("csrw satp, %0" : : "r" (x));
    8000016e:	4781                	li	a5,0
    80000170:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000174:	67c1                	lui	a5,0x10
    80000176:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000178:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000017c:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000180:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000184:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000188:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    8000018c:	57fd                	li	a5,-1
    8000018e:	83a9                	srl	a5,a5,0xa
    80000190:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    80000194:	47bd                	li	a5,15
    80000196:	3a079073          	csrw	pmpcfg0,a5
  w_pmpaddr0(0x3fffffffffffffull);  // 设置PMP地址范围
  w_pmpcfg0(0xf);                   // 设置PMP配置(读写执行权限)

  
  // 请求时钟中断服务
  timer_init();
    8000019a:	00000097          	auipc	ra,0x0
    8000019e:	01c080e7          	jalr	28(ra) # 800001b6 <timer_init>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800001a2:	f14027f3          	csrr	a5,mhartid

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    800001a6:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800001a8:	823e                	mv	tp,a5


  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    800001aa:	30200073          	mret
}
    800001ae:	60a2                	ld	ra,8(sp)
    800001b0:	6402                	ld	s0,0(sp)
    800001b2:	0141                	add	sp,sp,16
    800001b4:	8082                	ret

00000000800001b6 <timer_init>:
// 完成以下设置来接收M-Mode下的时钟中断
// 时钟中断会进入到kernelvec.S中的timervec
// 在这之后会将它们转化为软中断进而被trap.c中的devintr接管
void
timer_init()
{
    800001b6:	1141                	add	sp,sp,-16
    800001b8:	e422                	sd	s0,8(sp)
    800001ba:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800001bc:	f14027f3          	csrr	a5,mhartid
  // 每个CPU都有独立的定时器中断源
  int id = r_mhartid();
    800001c0:	0007859b          	sext.w	a1,a5

  // 向CLINT(核心本地中断控制器)请求定时器中断
  int interval = 1000000; // 周期数；在QEMU中大约是1/10秒
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    800001c4:	0037979b          	sllw	a5,a5,0x3
    800001c8:	02004737          	lui	a4,0x2004
    800001cc:	97ba                	add	a5,a5,a4
    800001ce:	0200c737          	lui	a4,0x200c
    800001d2:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    800001d6:	000f4637          	lui	a2,0xf4
    800001da:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    800001de:	9732                	add	a4,a4,a2
    800001e0:	e398                	sd	a4,0(a5)

  // 在scratch[]中为timervec准备信息
  // scratch[0..2] : timervec保存寄存器的空间
  // scratch[3] : CLINT MTIMECMP寄存器地址
  // scratch[4] : 定时器中断之间期望的间隔(周期数)
  uint64 *scratch = &timer_scratch[id][0];
    800001e2:	00259693          	sll	a3,a1,0x2
    800001e6:	96ae                	add	a3,a3,a1
    800001e8:	068e                	sll	a3,a3,0x3
    800001ea:	0000c717          	auipc	a4,0xc
    800001ee:	4a670713          	add	a4,a4,1190 # 8000c690 <timer_scratch>
    800001f2:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    800001f4:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    800001f6:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    800001f8:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    800001fc:	00002797          	auipc	a5,0x2
    80000200:	24478793          	add	a5,a5,580 # 80002440 <timervec>
    80000204:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000208:	300027f3          	csrr	a5,mstatus

  // 设置机器模式的陷阱处理程序
  w_mtvec((uint64)timervec);

  // 启用机器模式中断
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000020c:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000210:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000214:	304027f3          	csrr	a5,mie

  // 启用机器模式定时器中断
  w_mie(r_mie() | MIE_MTIE);
    80000218:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000021c:	30479073          	csrw	mie,a5
}
    80000220:	6422                	ld	s0,8(sp)
    80000222:	0141                	add	sp,sp,16
    80000224:	8082                	ret

0000000080000226 <timer_create>:
static timer_t sys_timer;

// 时钟创建(初始化系统时钟)
// 陷阱初始化函数
void timer_create()
{
    80000226:	1141                	add	sp,sp,-16
    80000228:	e406                	sd	ra,8(sp)
    8000022a:	e022                	sd	s0,0(sp)
    8000022c:	0800                	add	s0,sp,16
    initlock(&sys_timer.lk, "sys_timer");
    8000022e:	00004597          	auipc	a1,0x4
    80000232:	e0a58593          	add	a1,a1,-502 # 80004038 <etext+0x38>
    80000236:	0000c517          	auipc	a0,0xc
    8000023a:	5a250513          	add	a0,a0,1442 # 8000c7d8 <sys_timer+0x8>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	652080e7          	jalr	1618(ra) # 80001890 <initlock>
    sys_timer.ticks = 0;
    80000246:	0000c797          	auipc	a5,0xc
    8000024a:	5807b523          	sd	zero,1418(a5) # 8000c7d0 <sys_timer>
}
    8000024e:	60a2                	ld	ra,8(sp)
    80000250:	6402                	ld	s0,0(sp)
    80000252:	0141                	add	sp,sp,16
    80000254:	8082                	ret

0000000080000256 <timer_update>:

// 时钟更新(ticks++ with lock)
void timer_update()
{
    80000256:	1101                	add	sp,sp,-32
    80000258:	ec06                	sd	ra,24(sp)
    8000025a:	e822                	sd	s0,16(sp)
    8000025c:	e426                	sd	s1,8(sp)
    8000025e:	e04a                	sd	s2,0(sp)
    80000260:	1000                	add	s0,sp,32
    acquire(&sys_timer.lk);
    80000262:	0000c917          	auipc	s2,0xc
    80000266:	42e90913          	add	s2,s2,1070 # 8000c690 <timer_scratch>
    8000026a:	0000c497          	auipc	s1,0xc
    8000026e:	56e48493          	add	s1,s1,1390 # 8000c7d8 <sys_timer+0x8>
    80000272:	8526                	mv	a0,s1
    80000274:	00001097          	auipc	ra,0x1
    80000278:	6ac080e7          	jalr	1708(ra) # 80001920 <acquire>
    sys_timer.ticks++;
    8000027c:	14093783          	ld	a5,320(s2)
    80000280:	0785                	add	a5,a5,1
    80000282:	14f93023          	sd	a5,320(s2)
    // printf("ticks: %d\n", sys_timer.ticks);
    release(&sys_timer.lk);
    80000286:	8526                	mv	a0,s1
    80000288:	00001097          	auipc	ra,0x1
    8000028c:	74c080e7          	jalr	1868(ra) # 800019d4 <release>
}
    80000290:	60e2                	ld	ra,24(sp)
    80000292:	6442                	ld	s0,16(sp)
    80000294:	64a2                	ld	s1,8(sp)
    80000296:	6902                	ld	s2,0(sp)
    80000298:	6105                	add	sp,sp,32
    8000029a:	8082                	ret

000000008000029c <timer_get_ticks>:

// 返回系统时钟ticks
uint64 timer_get_ticks()
{
    8000029c:	1101                	add	sp,sp,-32
    8000029e:	ec06                	sd	ra,24(sp)
    800002a0:	e822                	sd	s0,16(sp)
    800002a2:	e426                	sd	s1,8(sp)
    800002a4:	e04a                	sd	s2,0(sp)
    800002a6:	1000                	add	s0,sp,32
    uint64 xticks;
    acquire(&sys_timer.lk);
    800002a8:	0000c497          	auipc	s1,0xc
    800002ac:	53048493          	add	s1,s1,1328 # 8000c7d8 <sys_timer+0x8>
    800002b0:	8526                	mv	a0,s1
    800002b2:	00001097          	auipc	ra,0x1
    800002b6:	66e080e7          	jalr	1646(ra) # 80001920 <acquire>
    xticks = sys_timer.ticks;
    800002ba:	0000c917          	auipc	s2,0xc
    800002be:	51693903          	ld	s2,1302(s2) # 8000c7d0 <sys_timer>
    release(&sys_timer.lk);
    800002c2:	8526                	mv	a0,s1
    800002c4:	00001097          	auipc	ra,0x1
    800002c8:	710080e7          	jalr	1808(ra) # 800019d4 <release>
    return xticks;
    800002cc:	854a                	mv	a0,s2
    800002ce:	60e2                	ld	ra,24(sp)
    800002d0:	6442                	ld	s0,16(sp)
    800002d2:	64a2                	ld	s1,8(sp)
    800002d4:	6902                	ld	s2,0(sp)
    800002d6:	6105                	add	sp,sp,32
    800002d8:	8082                	ret

00000000800002da <uartinit>:

void uartstart();

void
uartinit(void)
{
    800002da:	1141                	add	sp,sp,-16
    800002dc:	e406                	sd	ra,8(sp)
    800002de:	e022                	sd	s0,0(sp)
    800002e0:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800002e2:	100007b7          	lui	a5,0x10000
    800002e6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800002ea:	f8000713          	li	a4,-128
    800002ee:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800002f2:	470d                	li	a4,3
    800002f4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800002f8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800002fc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000300:	469d                	li	a3,7
    80000302:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000306:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000030a:	00004597          	auipc	a1,0x4
    8000030e:	d3e58593          	add	a1,a1,-706 # 80004048 <etext+0x48>
    80000312:	0000c517          	auipc	a0,0xc
    80000316:	4de50513          	add	a0,a0,1246 # 8000c7f0 <uart_tx_lock>
    8000031a:	00001097          	auipc	ra,0x1
    8000031e:	576080e7          	jalr	1398(ra) # 80001890 <initlock>
}
    80000322:	60a2                	ld	ra,8(sp)
    80000324:	6402                	ld	s0,0(sp)
    80000326:	0141                	add	sp,sp,16
    80000328:	8082                	ret

000000008000032a <uartputc_sync>:
// 不使用中断的uartputc的替换版本
// 用于内核printf和回显字符
// 它会持续等待uart的输出寄存器为空(同步性、阻塞性)
void
uartputc_sync(int c)
{
    8000032a:	1101                	add	sp,sp,-32
    8000032c:	ec06                	sd	ra,24(sp)
    8000032e:	e822                	sd	s0,16(sp)
    80000330:	e426                	sd	s1,8(sp)
    80000332:	1000                	add	s0,sp,32
    80000334:	84aa                	mv	s1,a0
  // 关中断，防止串口中断再次进入造成竞争
  push_off();
    80000336:	00001097          	auipc	ra,0x1
    8000033a:	59e080e7          	jalr	1438(ra) # 800018d4 <push_off>
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    8000033e:	00004797          	auipc	a5,0x4
    80000342:	31a7a783          	lw	a5,794(a5) # 80004658 <panicked>
    for(;;)
      ;
  }

  // 等待LSR中的发送寄存器为空标识被置位
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000346:	10000737          	lui	a4,0x10000
  if(panicked){
    8000034a:	c391                	beqz	a5,8000034e <uartputc_sync+0x24>
    for(;;)
    8000034c:	a001                	j	8000034c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000034e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000352:	0207f793          	and	a5,a5,32
    80000356:	dfe5                	beqz	a5,8000034e <uartputc_sync+0x24>
    ;
  
  // 立即通过UART发送字符
  WriteReg(THR, c);
    80000358:	0ff4f513          	zext.b	a0,s1
    8000035c:	100007b7          	lui	a5,0x10000
    80000360:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
  
  // 恢复之前的中断状态
  pop_off();
    80000364:	00001097          	auipc	ra,0x1
    80000368:	610080e7          	jalr	1552(ra) # 80001974 <pop_off>
}
    8000036c:	60e2                	ld	ra,24(sp)
    8000036e:	6442                	ld	s0,16(sp)
    80000370:	64a2                	ld	s1,8(sp)
    80000372:	6105                	add	sp,sp,32
    80000374:	8082                	ret

0000000080000376 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000376:	1141                	add	sp,sp,-16
    80000378:	e422                	sd	s0,8(sp)
    8000037a:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000037c:	100007b7          	lui	a5,0x10000
    80000380:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000384:	8b85                	and	a5,a5,1
    80000386:	cb81                	beqz	a5,80000396 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000388:	100007b7          	lui	a5,0x10000
    8000038c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000390:	6422                	ld	s0,8(sp)
    80000392:	0141                	add	sp,sp,16
    80000394:	8082                	ret
    return -1;
    80000396:	557d                	li	a0,-1
    80000398:	bfe5                	j	80000390 <uartgetc+0x1a>

000000008000039a <uartintr>:
// 注意两种情况下会触发此函数：
// 1.输入通道RX为满(即键盘有数据输入)
// 2.输出通道TX为空
void
uartintr(void)
{
    8000039a:	1101                	add	sp,sp,-32
    8000039c:	ec06                	sd	ra,24(sp)
    8000039e:	e822                	sd	s0,16(sp)
    800003a0:	e426                	sd	s1,8(sp)
    800003a2:	1000                	add	s0,sp,32
  // release(&uart_tx_lock);
  
  while(1)
  {
    int c = uartgetc();
    if(c == -1) break;
    800003a4:	54fd                	li	s1,-1
    800003a6:	a029                	j	800003b0 <uartintr+0x16>
    consputc(c);
    800003a8:	00000097          	auipc	ra,0x0
    800003ac:	06c080e7          	jalr	108(ra) # 80000414 <consputc>
    int c = uartgetc();
    800003b0:	00000097          	auipc	ra,0x0
    800003b4:	fc6080e7          	jalr	-58(ra) # 80000376 <uartgetc>
    if(c == -1) break;
    800003b8:	fe9518e3          	bne	a0,s1,800003a8 <uartintr+0xe>
  }
}
    800003bc:	60e2                	ld	ra,24(sp)
    800003be:	6442                	ld	s0,16(sp)
    800003c0:	64a2                	ld	s1,8(sp)
    800003c2:	6105                	add	sp,sp,32
    800003c4:	8082                	ret

00000000800003c6 <uart_putc>:


void uart_putc(char c) {
    800003c6:	1141                	add	sp,sp,-16
    800003c8:	e422                	sd	s0,8(sp)
    800003ca:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    800003cc:	10000737          	lui	a4,0x10000
    800003d0:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800003d4:	0207f793          	and	a5,a5,32
    800003d8:	dfe5                	beqz	a5,800003d0 <uart_putc+0xa>
    uart[0] = c;
    800003da:	100007b7          	lui	a5,0x10000
    800003de:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    800003e2:	6422                	ld	s0,8(sp)
    800003e4:	0141                	add	sp,sp,16
    800003e6:	8082                	ret

00000000800003e8 <uart_puts>:

void uart_puts(char *s) {
    800003e8:	1101                	add	sp,sp,-32
    800003ea:	ec06                	sd	ra,24(sp)
    800003ec:	e822                	sd	s0,16(sp)
    800003ee:	e426                	sd	s1,8(sp)
    800003f0:	1000                	add	s0,sp,32
    800003f2:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    800003f4:	00054503          	lbu	a0,0(a0)
    800003f8:	c909                	beqz	a0,8000040a <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	fcc080e7          	jalr	-52(ra) # 800003c6 <uart_putc>
        s++;              // 移动到下一个字符
    80000402:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000404:	0004c503          	lbu	a0,0(s1)
    80000408:	f96d                	bnez	a0,800003fa <uart_puts+0x12>
    }
}
    8000040a:	60e2                	ld	ra,24(sp)
    8000040c:	6442                	ld	s0,16(sp)
    8000040e:	64a2                	ld	s1,8(sp)
    80000410:	6105                	add	sp,sp,32
    80000412:	8082                	ret

0000000080000414 <consputc>:

// 发送一个字符到UART，被(内核)printf调用，以及回显输入字符
// 但不会被write()调用
void
consputc(int c)
{
    80000414:	1141                	add	sp,sp,-16
    80000416:	e406                	sd	ra,8(sp)
    80000418:	e022                	sd	s0,0(sp)
    8000041a:	0800                	add	s0,sp,16
  // 如果当前字符是退格键
  if(c == BACKSPACE){
    8000041c:	07f00793          	li	a5,127
    80000420:	00f50a63          	beq	a0,a5,80000434 <consputc+0x20>

    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    
    // 如果不是退格键，那么按照原样字符输出
    uartputc_sync(c);
    80000424:	00000097          	auipc	ra,0x0
    80000428:	f06080e7          	jalr	-250(ra) # 8000032a <uartputc_sync>
  }
}
    8000042c:	60a2                	ld	ra,8(sp)
    8000042e:	6402                	ld	s0,0(sp)
    80000430:	0141                	add	sp,sp,16
    80000432:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000434:	4521                	li	a0,8
    80000436:	00000097          	auipc	ra,0x0
    8000043a:	ef4080e7          	jalr	-268(ra) # 8000032a <uartputc_sync>
    8000043e:	02000513          	li	a0,32
    80000442:	00000097          	auipc	ra,0x0
    80000446:	ee8080e7          	jalr	-280(ra) # 8000032a <uartputc_sync>
    8000044a:	4521                	li	a0,8
    8000044c:	00000097          	auipc	ra,0x0
    80000450:	ede080e7          	jalr	-290(ra) # 8000032a <uartputc_sync>
    80000454:	bfe1                	j	8000042c <consputc+0x18>

0000000080000456 <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    80000456:	1141                	add	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00004597          	auipc	a1,0x4
    80000462:	bf258593          	add	a1,a1,-1038 # 80004050 <etext+0x50>
    80000466:	0000c517          	auipc	a0,0xc
    8000046a:	3c250513          	add	a0,a0,962 # 8000c828 <cons>
    8000046e:	00001097          	auipc	ra,0x1
    80000472:	422080e7          	jalr	1058(ra) # 80001890 <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	e64080e7          	jalr	-412(ra) # 800002da <uartinit>

  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    8000047e:	60a2                	ld	ra,8(sp)
    80000480:	6402                	ld	s0,0(sp)
    80000482:	0141                	add	sp,sp,16
    80000484:	8082                	ret

0000000080000486 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80000486:	1141                	add	sp,sp,-16
    80000488:	e422                	sd	s0,8(sp)
    8000048a:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    8000048c:	0c0007b7          	lui	a5,0xc000
    80000490:	4705                	li	a4,1
    80000492:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80000494:	c3d8                	sw	a4,4(a5)
}
    80000496:	6422                	ld	s0,8(sp)
    80000498:	0141                	add	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <plicinithart>:

void
plicinithart(void)
{
    8000049c:	1141                	add	sp,sp,-16
    8000049e:	e406                	sd	ra,8(sp)
    800004a0:	e022                	sd	s0,0(sp)
    800004a2:	0800                	add	s0,sp,16
  int hart = cpuid();
    800004a4:	00001097          	auipc	ra,0x1
    800004a8:	f4a080e7          	jalr	-182(ra) # 800013ee <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800004ac:	0085171b          	sllw	a4,a0,0x8
    800004b0:	0c0027b7          	lui	a5,0xc002
    800004b4:	97ba                	add	a5,a5,a4
    800004b6:	40200713          	li	a4,1026
    800004ba:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800004be:	00d5151b          	sllw	a0,a0,0xd
    800004c2:	0c2017b7          	lui	a5,0xc201
    800004c6:	97aa                	add	a5,a5,a0
    800004c8:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800004cc:	60a2                	ld	ra,8(sp)
    800004ce:	6402                	ld	s0,0(sp)
    800004d0:	0141                	add	sp,sp,16
    800004d2:	8082                	ret

00000000800004d4 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800004d4:	1141                	add	sp,sp,-16
    800004d6:	e406                	sd	ra,8(sp)
    800004d8:	e022                	sd	s0,0(sp)
    800004da:	0800                	add	s0,sp,16
  int hart = cpuid();
    800004dc:	00001097          	auipc	ra,0x1
    800004e0:	f12080e7          	jalr	-238(ra) # 800013ee <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800004e4:	00d5151b          	sllw	a0,a0,0xd
    800004e8:	0c2017b7          	lui	a5,0xc201
    800004ec:	97aa                	add	a5,a5,a0
  return irq;
}
    800004ee:	43c8                	lw	a0,4(a5)
    800004f0:	60a2                	ld	ra,8(sp)
    800004f2:	6402                	ld	s0,0(sp)
    800004f4:	0141                	add	sp,sp,16
    800004f6:	8082                	ret

00000000800004f8 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800004f8:	1101                	add	sp,sp,-32
    800004fa:	ec06                	sd	ra,24(sp)
    800004fc:	e822                	sd	s0,16(sp)
    800004fe:	e426                	sd	s1,8(sp)
    80000500:	1000                	add	s0,sp,32
    80000502:	84aa                	mv	s1,a0
  int hart = cpuid();
    80000504:	00001097          	auipc	ra,0x1
    80000508:	eea080e7          	jalr	-278(ra) # 800013ee <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000050c:	00d5151b          	sllw	a0,a0,0xd
    80000510:	0c2017b7          	lui	a5,0xc201
    80000514:	97aa                	add	a5,a5,a0
    80000516:	c3c4                	sw	s1,4(a5)
}
    80000518:	60e2                	ld	ra,24(sp)
    8000051a:	6442                	ld	s0,16(sp)
    8000051c:	64a2                	ld	s1,8(sp)
    8000051e:	6105                	add	sp,sp,32
    80000520:	8082                	ret

0000000080000522 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000522:	1141                	add	sp,sp,-16
    80000524:	e422                	sd	s0,8(sp)
    80000526:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000528:	ca19                	beqz	a2,8000053e <memset+0x1c>
    8000052a:	87aa                	mv	a5,a0
    8000052c:	1602                	sll	a2,a2,0x20
    8000052e:	9201                	srl	a2,a2,0x20
    80000530:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000534:	00b78023          	sb	a1,0(a5) # c201000 <_entry-0x73dff000>
  for(i = 0; i < n; i++){
    80000538:	0785                	add	a5,a5,1
    8000053a:	fee79de3          	bne	a5,a4,80000534 <memset+0x12>
  }
  return dst;
}
    8000053e:	6422                	ld	s0,8(sp)
    80000540:	0141                	add	sp,sp,16
    80000542:	8082                	ret

0000000080000544 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000544:	1141                	add	sp,sp,-16
    80000546:	e422                	sd	s0,8(sp)
    80000548:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    8000054a:	ca05                	beqz	a2,8000057a <memcmp+0x36>
    8000054c:	fff6069b          	addw	a3,a2,-1
    80000550:	1682                	sll	a3,a3,0x20
    80000552:	9281                	srl	a3,a3,0x20
    80000554:	0685                	add	a3,a3,1
    80000556:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000558:	00054783          	lbu	a5,0(a0)
    8000055c:	0005c703          	lbu	a4,0(a1)
    80000560:	00e79863          	bne	a5,a4,80000570 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000564:	0505                	add	a0,a0,1
    80000566:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000568:	fed518e3          	bne	a0,a3,80000558 <memcmp+0x14>
  }

  return 0;
    8000056c:	4501                	li	a0,0
    8000056e:	a019                	j	80000574 <memcmp+0x30>
      return *s1 - *s2;
    80000570:	40e7853b          	subw	a0,a5,a4
}
    80000574:	6422                	ld	s0,8(sp)
    80000576:	0141                	add	sp,sp,16
    80000578:	8082                	ret
  return 0;
    8000057a:	4501                	li	a0,0
    8000057c:	bfe5                	j	80000574 <memcmp+0x30>

000000008000057e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    8000057e:	1141                	add	sp,sp,-16
    80000580:	e422                	sd	s0,8(sp)
    80000582:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000584:	c205                	beqz	a2,800005a4 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000586:	02a5e263          	bltu	a1,a0,800005aa <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    8000058a:	1602                	sll	a2,a2,0x20
    8000058c:	9201                	srl	a2,a2,0x20
    8000058e:	00c587b3          	add	a5,a1,a2
{
    80000592:	872a                	mv	a4,a0
      *d++ = *s++;
    80000594:	0585                	add	a1,a1,1
    80000596:	0705                	add	a4,a4,1
    80000598:	fff5c683          	lbu	a3,-1(a1)
    8000059c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800005a0:	fef59ae3          	bne	a1,a5,80000594 <memmove+0x16>

  return dst;
}
    800005a4:	6422                	ld	s0,8(sp)
    800005a6:	0141                	add	sp,sp,16
    800005a8:	8082                	ret
  if(s < d && s + n > d){
    800005aa:	02061693          	sll	a3,a2,0x20
    800005ae:	9281                	srl	a3,a3,0x20
    800005b0:	00d58733          	add	a4,a1,a3
    800005b4:	fce57be3          	bgeu	a0,a4,8000058a <memmove+0xc>
    d += n;
    800005b8:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800005ba:	fff6079b          	addw	a5,a2,-1
    800005be:	1782                	sll	a5,a5,0x20
    800005c0:	9381                	srl	a5,a5,0x20
    800005c2:	fff7c793          	not	a5,a5
    800005c6:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800005c8:	177d                	add	a4,a4,-1
    800005ca:	16fd                	add	a3,a3,-1
    800005cc:	00074603          	lbu	a2,0(a4)
    800005d0:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800005d4:	fee79ae3          	bne	a5,a4,800005c8 <memmove+0x4a>
    800005d8:	b7f1                	j	800005a4 <memmove+0x26>

00000000800005da <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800005da:	1141                	add	sp,sp,-16
    800005dc:	e406                	sd	ra,8(sp)
    800005de:	e022                	sd	s0,0(sp)
    800005e0:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    800005e2:	00000097          	auipc	ra,0x0
    800005e6:	f9c080e7          	jalr	-100(ra) # 8000057e <memmove>
}
    800005ea:	60a2                	ld	ra,8(sp)
    800005ec:	6402                	ld	s0,0(sp)
    800005ee:	0141                	add	sp,sp,16
    800005f0:	8082                	ret

00000000800005f2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800005f2:	1141                	add	sp,sp,-16
    800005f4:	e422                	sd	s0,8(sp)
    800005f6:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800005f8:	ce11                	beqz	a2,80000614 <strncmp+0x22>
    800005fa:	00054783          	lbu	a5,0(a0)
    800005fe:	cf89                	beqz	a5,80000618 <strncmp+0x26>
    80000600:	0005c703          	lbu	a4,0(a1)
    80000604:	00f71a63          	bne	a4,a5,80000618 <strncmp+0x26>
    n--, p++, q++;
    80000608:	367d                	addw	a2,a2,-1
    8000060a:	0505                	add	a0,a0,1
    8000060c:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000060e:	f675                	bnez	a2,800005fa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000610:	4501                	li	a0,0
    80000612:	a809                	j	80000624 <strncmp+0x32>
    80000614:	4501                	li	a0,0
    80000616:	a039                	j	80000624 <strncmp+0x32>
  if(n == 0)
    80000618:	ca09                	beqz	a2,8000062a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000061a:	00054503          	lbu	a0,0(a0)
    8000061e:	0005c783          	lbu	a5,0(a1)
    80000622:	9d1d                	subw	a0,a0,a5
}
    80000624:	6422                	ld	s0,8(sp)
    80000626:	0141                	add	sp,sp,16
    80000628:	8082                	ret
    return 0;
    8000062a:	4501                	li	a0,0
    8000062c:	bfe5                	j	80000624 <strncmp+0x32>

000000008000062e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    8000062e:	1141                	add	sp,sp,-16
    80000630:	e422                	sd	s0,8(sp)
    80000632:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000634:	87aa                	mv	a5,a0
    80000636:	86b2                	mv	a3,a2
    80000638:	367d                	addw	a2,a2,-1
    8000063a:	00d05963          	blez	a3,8000064c <strncpy+0x1e>
    8000063e:	0785                	add	a5,a5,1
    80000640:	0005c703          	lbu	a4,0(a1)
    80000644:	fee78fa3          	sb	a4,-1(a5)
    80000648:	0585                	add	a1,a1,1
    8000064a:	f775                	bnez	a4,80000636 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000064c:	873e                	mv	a4,a5
    8000064e:	9fb5                	addw	a5,a5,a3
    80000650:	37fd                	addw	a5,a5,-1
    80000652:	00c05963          	blez	a2,80000664 <strncpy+0x36>
    *s++ = 0;
    80000656:	0705                	add	a4,a4,1
    80000658:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    8000065c:	40e786bb          	subw	a3,a5,a4
    80000660:	fed04be3          	bgtz	a3,80000656 <strncpy+0x28>
  return os;
}
    80000664:	6422                	ld	s0,8(sp)
    80000666:	0141                	add	sp,sp,16
    80000668:	8082                	ret

000000008000066a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000066a:	1141                	add	sp,sp,-16
    8000066c:	e422                	sd	s0,8(sp)
    8000066e:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000670:	02c05363          	blez	a2,80000696 <safestrcpy+0x2c>
    80000674:	fff6069b          	addw	a3,a2,-1
    80000678:	1682                	sll	a3,a3,0x20
    8000067a:	9281                	srl	a3,a3,0x20
    8000067c:	96ae                	add	a3,a3,a1
    8000067e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000680:	00d58963          	beq	a1,a3,80000692 <safestrcpy+0x28>
    80000684:	0585                	add	a1,a1,1
    80000686:	0785                	add	a5,a5,1
    80000688:	fff5c703          	lbu	a4,-1(a1)
    8000068c:	fee78fa3          	sb	a4,-1(a5)
    80000690:	fb65                	bnez	a4,80000680 <safestrcpy+0x16>
    ;
  *s = 0;
    80000692:	00078023          	sb	zero,0(a5)
  return os;
}
    80000696:	6422                	ld	s0,8(sp)
    80000698:	0141                	add	sp,sp,16
    8000069a:	8082                	ret

000000008000069c <strlen>:

int
strlen(const char *s)
{
    8000069c:	1141                	add	sp,sp,-16
    8000069e:	e422                	sd	s0,8(sp)
    800006a0:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800006a2:	00054783          	lbu	a5,0(a0)
    800006a6:	cf91                	beqz	a5,800006c2 <strlen+0x26>
    800006a8:	0505                	add	a0,a0,1
    800006aa:	87aa                	mv	a5,a0
    800006ac:	86be                	mv	a3,a5
    800006ae:	0785                	add	a5,a5,1
    800006b0:	fff7c703          	lbu	a4,-1(a5)
    800006b4:	ff65                	bnez	a4,800006ac <strlen+0x10>
    800006b6:	40a6853b          	subw	a0,a3,a0
    800006ba:	2505                	addw	a0,a0,1
    ;
  return n;
}
    800006bc:	6422                	ld	s0,8(sp)
    800006be:	0141                	add	sp,sp,16
    800006c0:	8082                	ret
  for(n = 0; s[n]; n++)
    800006c2:	4501                	li	a0,0
    800006c4:	bfe5                	j	800006bc <strlen+0x20>

00000000800006c6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800006c6:	7179                	add	sp,sp,-48
    800006c8:	f406                	sd	ra,40(sp)
    800006ca:	f022                	sd	s0,32(sp)
    800006cc:	ec26                	sd	s1,24(sp)
    800006ce:	e84a                	sd	s2,16(sp)
    800006d0:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800006d2:	c219                	beqz	a2,800006d8 <printint+0x12>
    800006d4:	08054763          	bltz	a0,80000762 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800006d8:	2501                	sext.w	a0,a0
    800006da:	4881                	li	a7,0
    800006dc:	fd040693          	add	a3,s0,-48

  i = 0;
    800006e0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800006e2:	2581                	sext.w	a1,a1
    800006e4:	00004617          	auipc	a2,0x4
    800006e8:	99c60613          	add	a2,a2,-1636 # 80004080 <digits>
    800006ec:	883a                	mv	a6,a4
    800006ee:	2705                	addw	a4,a4,1
    800006f0:	02b577bb          	remuw	a5,a0,a1
    800006f4:	1782                	sll	a5,a5,0x20
    800006f6:	9381                	srl	a5,a5,0x20
    800006f8:	97b2                	add	a5,a5,a2
    800006fa:	0007c783          	lbu	a5,0(a5)
    800006fe:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000702:	0005079b          	sext.w	a5,a0
    80000706:	02b5553b          	divuw	a0,a0,a1
    8000070a:	0685                	add	a3,a3,1
    8000070c:	feb7f0e3          	bgeu	a5,a1,800006ec <printint+0x26>

  if(sign)
    80000710:	00088c63          	beqz	a7,80000728 <printint+0x62>
    buf[i++] = '-';
    80000714:	fe070793          	add	a5,a4,-32
    80000718:	00878733          	add	a4,a5,s0
    8000071c:	02d00793          	li	a5,45
    80000720:	fef70823          	sb	a5,-16(a4)
    80000724:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    80000728:	02e05763          	blez	a4,80000756 <printint+0x90>
    8000072c:	fd040793          	add	a5,s0,-48
    80000730:	00e784b3          	add	s1,a5,a4
    80000734:	fff78913          	add	s2,a5,-1
    80000738:	993a                	add	s2,s2,a4
    8000073a:	377d                	addw	a4,a4,-1
    8000073c:	1702                	sll	a4,a4,0x20
    8000073e:	9301                	srl	a4,a4,0x20
    80000740:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000744:	fff4c503          	lbu	a0,-1(s1)
    80000748:	00000097          	auipc	ra,0x0
    8000074c:	ccc080e7          	jalr	-820(ra) # 80000414 <consputc>
  while(--i >= 0)
    80000750:	14fd                	add	s1,s1,-1
    80000752:	ff2499e3          	bne	s1,s2,80000744 <printint+0x7e>
}
    80000756:	70a2                	ld	ra,40(sp)
    80000758:	7402                	ld	s0,32(sp)
    8000075a:	64e2                	ld	s1,24(sp)
    8000075c:	6942                	ld	s2,16(sp)
    8000075e:	6145                	add	sp,sp,48
    80000760:	8082                	ret
    x = -xx;
    80000762:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000766:	4885                	li	a7,1
    x = -xx;
    80000768:	bf95                	j	800006dc <printint+0x16>

000000008000076a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000076a:	1101                	add	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	add	s0,sp,32
    80000774:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000776:	0000c797          	auipc	a5,0xc
    8000077a:	1607a923          	sw	zero,370(a5) # 8000c8e8 <pr+0x18>
  printf("panic: ");
    8000077e:	00004517          	auipc	a0,0x4
    80000782:	8da50513          	add	a0,a0,-1830 # 80004058 <etext+0x58>
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	02e080e7          	jalr	46(ra) # 800007b4 <printf>
  printf(s);
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	024080e7          	jalr	36(ra) # 800007b4 <printf>
  printf("\n");
    80000798:	00004517          	auipc	a0,0x4
    8000079c:	89850513          	add	a0,a0,-1896 # 80004030 <etext+0x30>
    800007a0:	00000097          	auipc	ra,0x0
    800007a4:	014080e7          	jalr	20(ra) # 800007b4 <printf>
  panicked = 1; // freeze uart output from other CPUs
    800007a8:	4785                	li	a5,1
    800007aa:	00004717          	auipc	a4,0x4
    800007ae:	eaf72723          	sw	a5,-338(a4) # 80004658 <panicked>
  for(;;)
    800007b2:	a001                	j	800007b2 <panic+0x48>

00000000800007b4 <printf>:
{
    800007b4:	7131                	add	sp,sp,-192
    800007b6:	fc86                	sd	ra,120(sp)
    800007b8:	f8a2                	sd	s0,112(sp)
    800007ba:	f4a6                	sd	s1,104(sp)
    800007bc:	f0ca                	sd	s2,96(sp)
    800007be:	ecce                	sd	s3,88(sp)
    800007c0:	e8d2                	sd	s4,80(sp)
    800007c2:	e4d6                	sd	s5,72(sp)
    800007c4:	e0da                	sd	s6,64(sp)
    800007c6:	fc5e                	sd	s7,56(sp)
    800007c8:	f862                	sd	s8,48(sp)
    800007ca:	f466                	sd	s9,40(sp)
    800007cc:	f06a                	sd	s10,32(sp)
    800007ce:	ec6e                	sd	s11,24(sp)
    800007d0:	0100                	add	s0,sp,128
    800007d2:	8a2a                	mv	s4,a0
    800007d4:	e40c                	sd	a1,8(s0)
    800007d6:	e810                	sd	a2,16(s0)
    800007d8:	ec14                	sd	a3,24(s0)
    800007da:	f018                	sd	a4,32(s0)
    800007dc:	f41c                	sd	a5,40(s0)
    800007de:	03043823          	sd	a6,48(s0)
    800007e2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800007e6:	0000cd97          	auipc	s11,0xc
    800007ea:	102dad83          	lw	s11,258(s11) # 8000c8e8 <pr+0x18>
  if(locking)
    800007ee:	020d9b63          	bnez	s11,80000824 <printf+0x70>
  if (fmt == 0)
    800007f2:	040a0263          	beqz	s4,80000836 <printf+0x82>
  va_start(ap, fmt);
    800007f6:	00840793          	add	a5,s0,8
    800007fa:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800007fe:	000a4503          	lbu	a0,0(s4)
    80000802:	14050f63          	beqz	a0,80000960 <printf+0x1ac>
    80000806:	4981                	li	s3,0
    if(c != '%'){
    80000808:	02500a93          	li	s5,37
    switch(c){
    8000080c:	07000b93          	li	s7,112
  consputc('x');
    80000810:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000812:	00004b17          	auipc	s6,0x4
    80000816:	86eb0b13          	add	s6,s6,-1938 # 80004080 <digits>
    switch(c){
    8000081a:	07300c93          	li	s9,115
    8000081e:	06400c13          	li	s8,100
    80000822:	a82d                	j	8000085c <printf+0xa8>
    acquire(&pr.lock);
    80000824:	0000c517          	auipc	a0,0xc
    80000828:	0ac50513          	add	a0,a0,172 # 8000c8d0 <pr>
    8000082c:	00001097          	auipc	ra,0x1
    80000830:	0f4080e7          	jalr	244(ra) # 80001920 <acquire>
    80000834:	bf7d                	j	800007f2 <printf+0x3e>
    panic("null fmt");
    80000836:	00004517          	auipc	a0,0x4
    8000083a:	83250513          	add	a0,a0,-1998 # 80004068 <etext+0x68>
    8000083e:	00000097          	auipc	ra,0x0
    80000842:	f2c080e7          	jalr	-212(ra) # 8000076a <panic>
      consputc(c);
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	bce080e7          	jalr	-1074(ra) # 80000414 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000084e:	2985                	addw	s3,s3,1
    80000850:	013a07b3          	add	a5,s4,s3
    80000854:	0007c503          	lbu	a0,0(a5)
    80000858:	10050463          	beqz	a0,80000960 <printf+0x1ac>
    if(c != '%'){
    8000085c:	ff5515e3          	bne	a0,s5,80000846 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000860:	2985                	addw	s3,s3,1
    80000862:	013a07b3          	add	a5,s4,s3
    80000866:	0007c783          	lbu	a5,0(a5)
    8000086a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000086e:	cbed                	beqz	a5,80000960 <printf+0x1ac>
    switch(c){
    80000870:	05778a63          	beq	a5,s7,800008c4 <printf+0x110>
    80000874:	02fbf663          	bgeu	s7,a5,800008a0 <printf+0xec>
    80000878:	09978863          	beq	a5,s9,80000908 <printf+0x154>
    8000087c:	07800713          	li	a4,120
    80000880:	0ce79563          	bne	a5,a4,8000094a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000884:	f8843783          	ld	a5,-120(s0)
    80000888:	00878713          	add	a4,a5,8
    8000088c:	f8e43423          	sd	a4,-120(s0)
    80000890:	4605                	li	a2,1
    80000892:	85ea                	mv	a1,s10
    80000894:	4388                	lw	a0,0(a5)
    80000896:	00000097          	auipc	ra,0x0
    8000089a:	e30080e7          	jalr	-464(ra) # 800006c6 <printint>
      break;
    8000089e:	bf45                	j	8000084e <printf+0x9a>
    switch(c){
    800008a0:	09578f63          	beq	a5,s5,8000093e <printf+0x18a>
    800008a4:	0b879363          	bne	a5,s8,8000094a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    800008a8:	f8843783          	ld	a5,-120(s0)
    800008ac:	00878713          	add	a4,a5,8
    800008b0:	f8e43423          	sd	a4,-120(s0)
    800008b4:	4605                	li	a2,1
    800008b6:	45a9                	li	a1,10
    800008b8:	4388                	lw	a0,0(a5)
    800008ba:	00000097          	auipc	ra,0x0
    800008be:	e0c080e7          	jalr	-500(ra) # 800006c6 <printint>
      break;
    800008c2:	b771                	j	8000084e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800008c4:	f8843783          	ld	a5,-120(s0)
    800008c8:	00878713          	add	a4,a5,8
    800008cc:	f8e43423          	sd	a4,-120(s0)
    800008d0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800008d4:	03000513          	li	a0,48
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	b3c080e7          	jalr	-1220(ra) # 80000414 <consputc>
  consputc('x');
    800008e0:	07800513          	li	a0,120
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	b30080e7          	jalr	-1232(ra) # 80000414 <consputc>
    800008ec:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800008ee:	03c95793          	srl	a5,s2,0x3c
    800008f2:	97da                	add	a5,a5,s6
    800008f4:	0007c503          	lbu	a0,0(a5)
    800008f8:	00000097          	auipc	ra,0x0
    800008fc:	b1c080e7          	jalr	-1252(ra) # 80000414 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000900:	0912                	sll	s2,s2,0x4
    80000902:	34fd                	addw	s1,s1,-1
    80000904:	f4ed                	bnez	s1,800008ee <printf+0x13a>
    80000906:	b7a1                	j	8000084e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000908:	f8843783          	ld	a5,-120(s0)
    8000090c:	00878713          	add	a4,a5,8
    80000910:	f8e43423          	sd	a4,-120(s0)
    80000914:	6384                	ld	s1,0(a5)
    80000916:	cc89                	beqz	s1,80000930 <printf+0x17c>
      for(; *s; s++)
    80000918:	0004c503          	lbu	a0,0(s1)
    8000091c:	d90d                	beqz	a0,8000084e <printf+0x9a>
        consputc(*s);
    8000091e:	00000097          	auipc	ra,0x0
    80000922:	af6080e7          	jalr	-1290(ra) # 80000414 <consputc>
      for(; *s; s++)
    80000926:	0485                	add	s1,s1,1
    80000928:	0004c503          	lbu	a0,0(s1)
    8000092c:	f96d                	bnez	a0,8000091e <printf+0x16a>
    8000092e:	b705                	j	8000084e <printf+0x9a>
        s = "(null)";
    80000930:	00003497          	auipc	s1,0x3
    80000934:	73048493          	add	s1,s1,1840 # 80004060 <etext+0x60>
      for(; *s; s++)
    80000938:	02800513          	li	a0,40
    8000093c:	b7cd                	j	8000091e <printf+0x16a>
      consputc('%');
    8000093e:	8556                	mv	a0,s5
    80000940:	00000097          	auipc	ra,0x0
    80000944:	ad4080e7          	jalr	-1324(ra) # 80000414 <consputc>
      break;
    80000948:	b719                	j	8000084e <printf+0x9a>
      consputc('%');
    8000094a:	8556                	mv	a0,s5
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ac8080e7          	jalr	-1336(ra) # 80000414 <consputc>
      consputc(c);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	abe080e7          	jalr	-1346(ra) # 80000414 <consputc>
      break;
    8000095e:	bdc5                	j	8000084e <printf+0x9a>
  if(locking)
    80000960:	020d9163          	bnez	s11,80000982 <printf+0x1ce>
}
    80000964:	70e6                	ld	ra,120(sp)
    80000966:	7446                	ld	s0,112(sp)
    80000968:	74a6                	ld	s1,104(sp)
    8000096a:	7906                	ld	s2,96(sp)
    8000096c:	69e6                	ld	s3,88(sp)
    8000096e:	6a46                	ld	s4,80(sp)
    80000970:	6aa6                	ld	s5,72(sp)
    80000972:	6b06                	ld	s6,64(sp)
    80000974:	7be2                	ld	s7,56(sp)
    80000976:	7c42                	ld	s8,48(sp)
    80000978:	7ca2                	ld	s9,40(sp)
    8000097a:	7d02                	ld	s10,32(sp)
    8000097c:	6de2                	ld	s11,24(sp)
    8000097e:	6129                	add	sp,sp,192
    80000980:	8082                	ret
    release(&pr.lock);
    80000982:	0000c517          	auipc	a0,0xc
    80000986:	f4e50513          	add	a0,a0,-178 # 8000c8d0 <pr>
    8000098a:	00001097          	auipc	ra,0x1
    8000098e:	04a080e7          	jalr	74(ra) # 800019d4 <release>
}
    80000992:	bfc9                	j	80000964 <printf+0x1b0>

0000000080000994 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    8000099e:	0000c497          	auipc	s1,0xc
    800009a2:	f3248493          	add	s1,s1,-206 # 8000c8d0 <pr>
    800009a6:	00003597          	auipc	a1,0x3
    800009aa:	6d258593          	add	a1,a1,1746 # 80004078 <etext+0x78>
    800009ae:	8526                	mv	a0,s1
    800009b0:	00001097          	auipc	ra,0x1
    800009b4:	ee0080e7          	jalr	-288(ra) # 80001890 <initlock>
  pr.locking = 1;
    800009b8:	4785                	li	a5,1
    800009ba:	cc9c                	sw	a5,24(s1)
}
    800009bc:	60e2                	ld	ra,24(sp)
    800009be:	6442                	ld	s0,16(sp)
    800009c0:	64a2                	ld	s1,8(sp)
    800009c2:	6105                	add	sp,sp,32
    800009c4:	8082                	ret

00000000800009c6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(uint64 page, bool in_kernel)
{
    800009c6:	1101                	add	sp,sp,-32
    800009c8:	ec06                	sd	ra,24(sp)
    800009ca:	e822                	sd	s0,16(sp)
    800009cc:	e426                	sd	s1,8(sp)
    800009ce:	e04a                	sd	s2,0(sp)
    800009d0:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)page % PGSIZE) != 0 || (char*)page < end || (uint64)page >= PHYSTOP) //检测合法性
    800009d2:	03451793          	sll	a5,a0,0x34
    800009d6:	ebb9                	bnez	a5,80000a2c <kfree+0x66>
    800009d8:	84aa                	mv	s1,a0
    800009da:	0000f797          	auipc	a5,0xf
    800009de:	54e78793          	add	a5,a5,1358 # 8000ff28 <end>
    800009e2:	04f56563          	bltu	a0,a5,80000a2c <kfree+0x66>
    800009e6:	47c5                	li	a5,17
    800009e8:	07ee                	sll	a5,a5,0x1b
    800009ea:	04f57163          	bgeu	a0,a5,80000a2c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset((char*)page, 1, PGSIZE); 
    800009ee:	6605                	lui	a2,0x1
    800009f0:	4585                	li	a1,1
    800009f2:	00000097          	auipc	ra,0x0
    800009f6:	b30080e7          	jalr	-1232(ra) # 80000522 <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    800009fa:	0000c917          	auipc	s2,0xc
    800009fe:	ef690913          	add	s2,s2,-266 # 8000c8f0 <kmem>
    80000a02:	854a                	mv	a0,s2
    80000a04:	00001097          	auipc	ra,0x1
    80000a08:	f1c080e7          	jalr	-228(ra) # 80001920 <acquire>
  r->next = kmem.freelist;  //头插
    80000a0c:	01893783          	ld	a5,24(s2)
    80000a10:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a12:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a16:	854a                	mv	a0,s2
    80000a18:	00001097          	auipc	ra,0x1
    80000a1c:	fbc080e7          	jalr	-68(ra) # 800019d4 <release>
}
    80000a20:	60e2                	ld	ra,24(sp)
    80000a22:	6442                	ld	s0,16(sp)
    80000a24:	64a2                	ld	s1,8(sp)
    80000a26:	6902                	ld	s2,0(sp)
    80000a28:	6105                	add	sp,sp,32
    80000a2a:	8082                	ret
    panic("kfree");
    80000a2c:	00003517          	auipc	a0,0x3
    80000a30:	66c50513          	add	a0,a0,1644 # 80004098 <digits+0x18>
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	d36080e7          	jalr	-714(ra) # 8000076a <panic>

0000000080000a3c <freerange>:
{
    80000a3c:	7179                	add	sp,sp,-48
    80000a3e:	f406                	sd	ra,40(sp)
    80000a40:	f022                	sd	s0,32(sp)
    80000a42:	ec26                	sd	s1,24(sp)
    80000a44:	e84a                	sd	s2,16(sp)
    80000a46:	e44e                	sd	s3,8(sp)
    80000a48:	e052                	sd	s4,0(sp)
    80000a4a:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start); //可用内存初始地址对齐4KB
    80000a4c:	6785                	lui	a5,0x1
    80000a4e:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a52:	00e504b3          	add	s1,a0,a4
    80000a56:	777d                	lui	a4,0xfffff
    80000a58:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a5a:	94be                	add	s1,s1,a5
    80000a5c:	0095ef63          	bltu	a1,s1,80000a7a <freerange+0x3e>
    80000a60:	892e                	mv	s2,a1
    kfree((uint64)p,true);
    80000a62:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a64:	6985                	lui	s3,0x1
    kfree((uint64)p,true);
    80000a66:	4585                	li	a1,1
    80000a68:	01448533          	add	a0,s1,s4
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	f5a080e7          	jalr	-166(ra) # 800009c6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a74:	94ce                	add	s1,s1,s3
    80000a76:	fe9978e3          	bgeu	s2,s1,80000a66 <freerange+0x2a>
}
    80000a7a:	70a2                	ld	ra,40(sp)
    80000a7c:	7402                	ld	s0,32(sp)
    80000a7e:	64e2                	ld	s1,24(sp)
    80000a80:	6942                	ld	s2,16(sp)
    80000a82:	69a2                	ld	s3,8(sp)
    80000a84:	6a02                	ld	s4,0(sp)
    80000a86:	6145                	add	sp,sp,48
    80000a88:	8082                	ret

0000000080000a8a <kinit>:
{
    80000a8a:	1141                	add	sp,sp,-16
    80000a8c:	e406                	sd	ra,8(sp)
    80000a8e:	e022                	sd	s0,0(sp)
    80000a90:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a92:	00003597          	auipc	a1,0x3
    80000a96:	60e58593          	add	a1,a1,1550 # 800040a0 <digits+0x20>
    80000a9a:	0000c517          	auipc	a0,0xc
    80000a9e:	e5650513          	add	a0,a0,-426 # 8000c8f0 <kmem>
    80000aa2:	00001097          	auipc	ra,0x1
    80000aa6:	dee080e7          	jalr	-530(ra) # 80001890 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aaa:	45c5                	li	a1,17
    80000aac:	05ee                	sll	a1,a1,0x1b
    80000aae:	0000f517          	auipc	a0,0xf
    80000ab2:	47a50513          	add	a0,a0,1146 # 8000ff28 <end>
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	f86080e7          	jalr	-122(ra) # 80000a3c <freerange>
}
    80000abe:	60a2                	ld	ra,8(sp)
    80000ac0:	6402                	ld	s0,0(sp)
    80000ac2:	0141                	add	sp,sp,16
    80000ac4:	8082                	ret

0000000080000ac6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(bool in_kernel)
{
    80000ac6:	1101                	add	sp,sp,-32
    80000ac8:	ec06                	sd	ra,24(sp)
    80000aca:	e822                	sd	s0,16(sp)
    80000acc:	e426                	sd	s1,8(sp)
    80000ace:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);  
    80000ad0:	0000c497          	auipc	s1,0xc
    80000ad4:	e2048493          	add	s1,s1,-480 # 8000c8f0 <kmem>
    80000ad8:	8526                	mv	a0,s1
    80000ada:	00001097          	auipc	ra,0x1
    80000ade:	e46080e7          	jalr	-442(ra) # 80001920 <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80000ae2:	6c84                	ld	s1,24(s1)
  if(r)
    80000ae4:	c885                	beqz	s1,80000b14 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000ae6:	609c                	ld	a5,0(s1)
    80000ae8:	0000c517          	auipc	a0,0xc
    80000aec:	e0850513          	add	a0,a0,-504 # 8000c8f0 <kmem>
    80000af0:	ed1c                	sd	a5,24(a0)
  else 
    panic("kalloc: out of memory");
  release(&kmem.lock);
    80000af2:	00001097          	auipc	ra,0x1
    80000af6:	ee2080e7          	jalr	-286(ra) # 800019d4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000afa:	6605                	lui	a2,0x1
    80000afc:	4595                	li	a1,5
    80000afe:	8526                	mv	a0,s1
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	a22080e7          	jalr	-1502(ra) # 80000522 <memset>
  return (void*)r;
}
    80000b08:	8526                	mv	a0,s1
    80000b0a:	60e2                	ld	ra,24(sp)
    80000b0c:	6442                	ld	s0,16(sp)
    80000b0e:	64a2                	ld	s1,8(sp)
    80000b10:	6105                	add	sp,sp,32
    80000b12:	8082                	ret
    panic("kalloc: out of memory");
    80000b14:	00003517          	auipc	a0,0x3
    80000b18:	59450513          	add	a0,a0,1428 # 800040a8 <digits+0x28>
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	c4e080e7          	jalr	-946(ra) # 8000076a <panic>

0000000080000b24 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000b24:	1141                	add	sp,sp,-16
    80000b26:	e422                	sd	s0,8(sp)
    80000b28:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000b2a:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000b2e:	00004797          	auipc	a5,0x4
    80000b32:	b327b783          	ld	a5,-1230(a5) # 80004660 <kernel_pagetable>
    80000b36:	83b1                	srl	a5,a5,0xc
    80000b38:	577d                	li	a4,-1
    80000b3a:	177e                	sll	a4,a4,0x3f
    80000b3c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000b3e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000b42:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000b46:	6422                	ld	s0,8(sp)
    80000b48:	0141                	add	sp,sp,16
    80000b4a:	8082                	ret

0000000080000b4c <walk>:
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc) 
// 虚拟映射查询与建立
// 输入虚拟地址与对应的页表，返回该虚拟地址对应的最低级页表项地址
// alloc为0只查询，为1表示允许在遍历过程中为缺失的中间级页表分配一页。
{
    80000b4c:	7139                	add	sp,sp,-64
    80000b4e:	fc06                	sd	ra,56(sp)
    80000b50:	f822                	sd	s0,48(sp)
    80000b52:	f426                	sd	s1,40(sp)
    80000b54:	f04a                	sd	s2,32(sp)
    80000b56:	ec4e                	sd	s3,24(sp)
    80000b58:	e852                	sd	s4,16(sp)
    80000b5a:	e456                	sd	s5,8(sp)
    80000b5c:	e05a                	sd	s6,0(sp)
    80000b5e:	0080                	add	s0,sp,64
    80000b60:	84aa                	mv	s1,a0
    80000b62:	89ae                	mv	s3,a1
    80000b64:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000b66:	57fd                	li	a5,-1
    80000b68:	83e9                	srl	a5,a5,0x1a
    80000b6a:	4a79                	li	s4,30
    panic("walk");
  for(int level = 2; level > 0; level--) {
    80000b6c:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000b6e:	04b7f363          	bgeu	a5,a1,80000bb4 <walk+0x68>
    panic("walk");
    80000b72:	00003517          	auipc	a0,0x3
    80000b76:	54e50513          	add	a0,a0,1358 # 800040c0 <digits+0x40>
    80000b7a:	00000097          	auipc	ra,0x0
    80000b7e:	bf0080e7          	jalr	-1040(ra) # 8000076a <panic>
    if(*pte & PTE_V) { // PTE有效
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
    } else {  // PTE无效，先判断是否可以写入
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
    80000b82:	060a8763          	beqz	s5,80000bf0 <walk+0xa4>
    80000b86:	4505                	li	a0,1
    80000b88:	00000097          	auipc	ra,0x0
    80000b8c:	f3e080e7          	jalr	-194(ra) # 80000ac6 <kalloc>
    80000b90:	84aa                	mv	s1,a0
    80000b92:	c529                	beqz	a0,80000bdc <walk+0x90>
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
    80000b94:	6605                	lui	a2,0x1
    80000b96:	4581                	li	a1,0
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	98a080e7          	jalr	-1654(ra) # 80000522 <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    80000ba0:	00c4d793          	srl	a5,s1,0xc
    80000ba4:	07aa                	sll	a5,a5,0xa
    80000ba6:	0017e793          	or	a5,a5,1
    80000baa:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000bae:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffef0cf>
    80000bb0:	036a0063          	beq	s4,s6,80000bd0 <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    80000bb4:	0149d933          	srl	s2,s3,s4
    80000bb8:	1ff97913          	and	s2,s2,511
    80000bbc:	090e                	sll	s2,s2,0x3
    80000bbe:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) { // PTE有效
    80000bc0:	00093483          	ld	s1,0(s2)
    80000bc4:	0014f793          	and	a5,s1,1
    80000bc8:	dfcd                	beqz	a5,80000b82 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte); 
    80000bca:	80a9                	srl	s1,s1,0xa
    80000bcc:	04b2                	sll	s1,s1,0xc
    80000bce:	b7c5                	j	80000bae <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];  
    80000bd0:	00c9d513          	srl	a0,s3,0xc
    80000bd4:	1ff57513          	and	a0,a0,511
    80000bd8:	050e                	sll	a0,a0,0x3
    80000bda:	9526                	add	a0,a0,s1
}
    80000bdc:	70e2                	ld	ra,56(sp)
    80000bde:	7442                	ld	s0,48(sp)
    80000be0:	74a2                	ld	s1,40(sp)
    80000be2:	7902                	ld	s2,32(sp)
    80000be4:	69e2                	ld	s3,24(sp)
    80000be6:	6a42                	ld	s4,16(sp)
    80000be8:	6aa2                	ld	s5,8(sp)
    80000bea:	6b02                	ld	s6,0(sp)
    80000bec:	6121                	add	sp,sp,64
    80000bee:	8082                	ret
        return 0; // 失败返回0
    80000bf0:	4501                	li	a0,0
    80000bf2:	b7ed                	j	80000bdc <walk+0x90>

0000000080000bf4 <mappages>:
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
    80000bf4:	715d                	add	sp,sp,-80
    80000bf6:	e486                	sd	ra,72(sp)
    80000bf8:	e0a2                	sd	s0,64(sp)
    80000bfa:	fc26                	sd	s1,56(sp)
    80000bfc:	f84a                	sd	s2,48(sp)
    80000bfe:	f44e                	sd	s3,40(sp)
    80000c00:	f052                	sd	s4,32(sp)
    80000c02:	ec56                	sd	s5,24(sp)
    80000c04:	e85a                	sd	s6,16(sp)
    80000c06:	e45e                	sd	s7,8(sp)
    80000c08:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80000c0a:	03459793          	sll	a5,a1,0x34
    80000c0e:	e7b9                	bnez	a5,80000c5c <mappages+0x68>
    80000c10:	8aaa                	mv	s5,a0
    80000c12:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80000c14:	03461793          	sll	a5,a2,0x34
    80000c18:	ebb1                	bnez	a5,80000c6c <mappages+0x78>
    panic("mappages: size not aligned");

  if(size == 0)
    80000c1a:	c22d                	beqz	a2,80000c7c <mappages+0x88>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
    80000c1c:	77fd                	lui	a5,0xfffff
    80000c1e:	963e                	add	a2,a2,a5
    80000c20:	00b609b3          	add	s3,a2,a1
  a = va;
    80000c24:	892e                	mv	s2,a1
    80000c26:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    if(a == last)
      break;
    a += PGSIZE;
    80000c2a:	6b85                	lui	s7,0x1
    80000c2c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    80000c30:	4605                	li	a2,1
    80000c32:	85ca                	mv	a1,s2
    80000c34:	8556                	mv	a0,s5
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	f16080e7          	jalr	-234(ra) # 80000b4c <walk>
    80000c3e:	cd39                	beqz	a0,80000c9c <mappages+0xa8>
    if(*pte & PTE_V) // 重复映射
    80000c40:	611c                	ld	a5,0(a0)
    80000c42:	8b85                	and	a5,a5,1
    80000c44:	e7a1                	bnez	a5,80000c8c <mappages+0x98>
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    80000c46:	80b1                	srl	s1,s1,0xc
    80000c48:	04aa                	sll	s1,s1,0xa
    80000c4a:	0164e4b3          	or	s1,s1,s6
    80000c4e:	0014e493          	or	s1,s1,1
    80000c52:	e104                	sd	s1,0(a0)
    if(a == last)
    80000c54:	07390063          	beq	s2,s3,80000cb4 <mappages+0xc0>
    a += PGSIZE;
    80000c58:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    80000c5a:	bfc9                	j	80000c2c <mappages+0x38>
    panic("mappages: va not aligned");
    80000c5c:	00003517          	auipc	a0,0x3
    80000c60:	46c50513          	add	a0,a0,1132 # 800040c8 <digits+0x48>
    80000c64:	00000097          	auipc	ra,0x0
    80000c68:	b06080e7          	jalr	-1274(ra) # 8000076a <panic>
    panic("mappages: size not aligned");
    80000c6c:	00003517          	auipc	a0,0x3
    80000c70:	47c50513          	add	a0,a0,1148 # 800040e8 <digits+0x68>
    80000c74:	00000097          	auipc	ra,0x0
    80000c78:	af6080e7          	jalr	-1290(ra) # 8000076a <panic>
    panic("mappages: size");
    80000c7c:	00003517          	auipc	a0,0x3
    80000c80:	48c50513          	add	a0,a0,1164 # 80004108 <digits+0x88>
    80000c84:	00000097          	auipc	ra,0x0
    80000c88:	ae6080e7          	jalr	-1306(ra) # 8000076a <panic>
      panic("mappages: remap");
    80000c8c:	00003517          	auipc	a0,0x3
    80000c90:	48c50513          	add	a0,a0,1164 # 80004118 <digits+0x98>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	ad6080e7          	jalr	-1322(ra) # 8000076a <panic>
      return -1;
    80000c9c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80000c9e:	60a6                	ld	ra,72(sp)
    80000ca0:	6406                	ld	s0,64(sp)
    80000ca2:	74e2                	ld	s1,56(sp)
    80000ca4:	7942                	ld	s2,48(sp)
    80000ca6:	79a2                	ld	s3,40(sp)
    80000ca8:	7a02                	ld	s4,32(sp)
    80000caa:	6ae2                	ld	s5,24(sp)
    80000cac:	6b42                	ld	s6,16(sp)
    80000cae:	6ba2                	ld	s7,8(sp)
    80000cb0:	6161                	add	sp,sp,80
    80000cb2:	8082                	ret
  return 0;
    80000cb4:	4501                	li	a0,0
    80000cb6:	b7e5                	j	80000c9e <mappages+0xaa>

0000000080000cb8 <kvmmap>:
{
    80000cb8:	1141                	add	sp,sp,-16
    80000cba:	e406                	sd	ra,8(sp)
    80000cbc:	e022                	sd	s0,0(sp)
    80000cbe:	0800                	add	s0,sp,16
    80000cc0:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80000cc2:	86b2                	mv	a3,a2
    80000cc4:	863e                	mv	a2,a5
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	f2e080e7          	jalr	-210(ra) # 80000bf4 <mappages>
    80000cce:	e509                	bnez	a0,80000cd8 <kvmmap+0x20>
}
    80000cd0:	60a2                	ld	ra,8(sp)
    80000cd2:	6402                	ld	s0,0(sp)
    80000cd4:	0141                	add	sp,sp,16
    80000cd6:	8082                	ret
    panic("kvmmap");
    80000cd8:	00003517          	auipc	a0,0x3
    80000cdc:	45050513          	add	a0,a0,1104 # 80004128 <digits+0xa8>
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	a8a080e7          	jalr	-1398(ra) # 8000076a <panic>

0000000080000ce8 <kvmmake>:
{
    80000ce8:	1101                	add	sp,sp,-32
    80000cea:	ec06                	sd	ra,24(sp)
    80000cec:	e822                	sd	s0,16(sp)
    80000cee:	e426                	sd	s1,8(sp)
    80000cf0:	e04a                	sd	s2,0(sp)
    80000cf2:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc(true);
    80000cf4:	4505                	li	a0,1
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	dd0080e7          	jalr	-560(ra) # 80000ac6 <kalloc>
    80000cfe:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE); //关键清零
    80000d00:	6605                	lui	a2,0x1
    80000d02:	4581                	li	a1,0
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	81e080e7          	jalr	-2018(ra) # 80000522 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80000d0c:	4719                	li	a4,6
    80000d0e:	6685                	lui	a3,0x1
    80000d10:	10000637          	lui	a2,0x10000
    80000d14:	100005b7          	lui	a1,0x10000
    80000d18:	8526                	mv	a0,s1
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	f9e080e7          	jalr	-98(ra) # 80000cb8 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80000d22:	4719                	li	a4,6
    80000d24:	6685                	lui	a3,0x1
    80000d26:	10001637          	lui	a2,0x10001
    80000d2a:	100015b7          	lui	a1,0x10001
    80000d2e:	8526                	mv	a0,s1
    80000d30:	00000097          	auipc	ra,0x0
    80000d34:	f88080e7          	jalr	-120(ra) # 80000cb8 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80000d38:	4719                	li	a4,6
    80000d3a:	004006b7          	lui	a3,0x400
    80000d3e:	0c000637          	lui	a2,0xc000
    80000d42:	0c0005b7          	lui	a1,0xc000
    80000d46:	8526                	mv	a0,s1
    80000d48:	00000097          	auipc	ra,0x0
    80000d4c:	f70080e7          	jalr	-144(ra) # 80000cb8 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    80000d50:	00003917          	auipc	s2,0x3
    80000d54:	2b090913          	add	s2,s2,688 # 80004000 <etext>
    80000d58:	4729                	li	a4,10
    80000d5a:	80003697          	auipc	a3,0x80003
    80000d5e:	2a668693          	add	a3,a3,678 # 4000 <_entry-0x7fffc000>
    80000d62:	4605                	li	a2,1
    80000d64:	067e                	sll	a2,a2,0x1f
    80000d66:	85b2                	mv	a1,a2
    80000d68:	8526                	mv	a0,s1
    80000d6a:	00000097          	auipc	ra,0x0
    80000d6e:	f4e080e7          	jalr	-178(ra) # 80000cb8 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    80000d72:	4719                	li	a4,6
    80000d74:	46c5                	li	a3,17
    80000d76:	06ee                	sll	a3,a3,0x1b
    80000d78:	412686b3          	sub	a3,a3,s2
    80000d7c:	864a                	mv	a2,s2
    80000d7e:	85ca                	mv	a1,s2
    80000d80:	8526                	mv	a0,s1
    80000d82:	00000097          	auipc	ra,0x0
    80000d86:	f36080e7          	jalr	-202(ra) # 80000cb8 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80000d8a:	4729                	li	a4,10
    80000d8c:	6685                	lui	a3,0x1
    80000d8e:	00002617          	auipc	a2,0x2
    80000d92:	27260613          	add	a2,a2,626 # 80003000 <_trampoline>
    80000d96:	040005b7          	lui	a1,0x4000
    80000d9a:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80000d9c:	05b2                	sll	a1,a1,0xc
    80000d9e:	8526                	mv	a0,s1
    80000da0:	00000097          	auipc	ra,0x0
    80000da4:	f18080e7          	jalr	-232(ra) # 80000cb8 <kvmmap>
  proc_mapstacks(kpgtbl);//TODO
    80000da8:	8526                	mv	a0,s1
    80000daa:	00000097          	auipc	ra,0x0
    80000dae:	72a080e7          	jalr	1834(ra) # 800014d4 <proc_mapstacks>
}
    80000db2:	8526                	mv	a0,s1
    80000db4:	60e2                	ld	ra,24(sp)
    80000db6:	6442                	ld	s0,16(sp)
    80000db8:	64a2                	ld	s1,8(sp)
    80000dba:	6902                	ld	s2,0(sp)
    80000dbc:	6105                	add	sp,sp,32
    80000dbe:	8082                	ret

0000000080000dc0 <kvminit>:
{
    80000dc0:	1141                	add	sp,sp,-16
    80000dc2:	e406                	sd	ra,8(sp)
    80000dc4:	e022                	sd	s0,0(sp)
    80000dc6:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80000dc8:	00000097          	auipc	ra,0x0
    80000dcc:	f20080e7          	jalr	-224(ra) # 80000ce8 <kvmmake>
    80000dd0:	00004797          	auipc	a5,0x4
    80000dd4:	88a7b823          	sd	a0,-1904(a5) # 80004660 <kernel_pagetable>
}
    80000dd8:	60a2                	ld	ra,8(sp)
    80000dda:	6402                	ld	s0,0(sp)
    80000ddc:	0141                	add	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    80000de0:	57fd                	li	a5,-1
    80000de2:	83e9                	srl	a5,a5,0x1a
    80000de4:	00b7f463          	bgeu	a5,a1,80000dec <walkaddr+0xc>
    return 0;
    80000de8:	4501                	li	a0,0
  if (!is_user_accessible_page(*pte))
    return 0;

  pa = PTE2PA(*pte);
  return pa;
}
    80000dea:	8082                	ret
{
    80000dec:	1141                	add	sp,sp,-16
    80000dee:	e406                	sd	ra,8(sp)
    80000df0:	e022                	sd	s0,0(sp)
    80000df2:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000df4:	4601                	li	a2,0
    80000df6:	00000097          	auipc	ra,0x0
    80000dfa:	d56080e7          	jalr	-682(ra) # 80000b4c <walk>
  if (pte == 0)
    80000dfe:	cd19                	beqz	a0,80000e1c <walkaddr+0x3c>
  if (!is_user_accessible_page(*pte))
    80000e00:	611c                	ld	a5,0(a0)
  return (pte & PTE_V) && (pte & PTE_U);
    80000e02:	0117f693          	and	a3,a5,17
  if (!is_user_accessible_page(*pte))
    80000e06:	4745                	li	a4,17
    return 0;
    80000e08:	4501                	li	a0,0
  if (!is_user_accessible_page(*pte))
    80000e0a:	00e69563          	bne	a3,a4,80000e14 <walkaddr+0x34>
  pa = PTE2PA(*pte);
    80000e0e:	83a9                	srl	a5,a5,0xa
    80000e10:	00c79513          	sll	a0,a5,0xc
}
    80000e14:	60a2                	ld	ra,8(sp)
    80000e16:	6402                	ld	s0,0(sp)
    80000e18:	0141                	add	sp,sp,16
    80000e1a:	8082                	ret
    return 0;
    80000e1c:	4501                	li	a0,0
    80000e1e:	bfdd                	j	80000e14 <walkaddr+0x34>

0000000080000e20 <print_pgtbl>:


void print_pgtbl(pagetable_t pagetable, int level) {
    80000e20:	711d                	add	sp,sp,-96
    80000e22:	ec86                	sd	ra,88(sp)
    80000e24:	e8a2                	sd	s0,80(sp)
    80000e26:	e4a6                	sd	s1,72(sp)
    80000e28:	e0ca                	sd	s2,64(sp)
    80000e2a:	fc4e                	sd	s3,56(sp)
    80000e2c:	f852                	sd	s4,48(sp)
    80000e2e:	f456                	sd	s5,40(sp)
    80000e30:	f05a                	sd	s6,32(sp)
    80000e32:	ec5e                	sd	s7,24(sp)
    80000e34:	e862                	sd	s8,16(sp)
    80000e36:	e466                	sd	s9,8(sp)
    80000e38:	e06a                	sd	s10,0(sp)
    80000e3a:	1080                	add	s0,sp,96
    80000e3c:	8aae                	mv	s5,a1
  //递归打印页表
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000e3e:	8a2a                	mv	s4,a0
    80000e40:	4981                	li	s3,0
    if(pte & PTE_V) {// 打印有效的页表项

      for(int j = 0; j < level; j++)
        printf("  ");

      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    80000e42:	00003c17          	auipc	s8,0x3
    80000e46:	2f6c0c13          	add	s8,s8,758 # 80004138 <digits+0xb8>

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
    80000e4a:	00003d17          	auipc	s10,0x3
    80000e4e:	306d0d13          	add	s10,s10,774 # 80004150 <digits+0xd0>
      for(int j = 0; j < level; j++)
    80000e52:	4c81                	li	s9,0
        printf("  ");
    80000e54:	00003b17          	auipc	s6,0x3
    80000e58:	2dcb0b13          	add	s6,s6,732 # 80004130 <digits+0xb0>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000e5c:	20000b93          	li	s7,512
    80000e60:	a025                	j	80000e88 <print_pgtbl+0x68>
      } 
      else {
        printf("\n");
    80000e62:	00003517          	auipc	a0,0x3
    80000e66:	1ce50513          	add	a0,a0,462 # 80004030 <etext+0x30>
    80000e6a:	00000097          	auipc	ra,0x0
    80000e6e:	94a080e7          	jalr	-1718(ra) # 800007b4 <printf>
        print_pgtbl((pagetable_t)PTE2PA(pte), level + 1);
    80000e72:	001a859b          	addw	a1,s5,1
    80000e76:	8526                	mv	a0,s1
    80000e78:	00000097          	auipc	ra,0x0
    80000e7c:	fa8080e7          	jalr	-88(ra) # 80000e20 <print_pgtbl>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000e80:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    80000e82:	0a21                	add	s4,s4,8
    80000e84:	05798763          	beq	s3,s7,80000ed2 <print_pgtbl+0xb2>
    pte_t pte = pagetable[i];
    80000e88:	000a3903          	ld	s2,0(s4)
    if(pte & PTE_V) {// 打印有效的页表项
    80000e8c:	00197793          	and	a5,s2,1
    80000e90:	dbe5                	beqz	a5,80000e80 <print_pgtbl+0x60>
      for(int j = 0; j < level; j++)
    80000e92:	01505b63          	blez	s5,80000ea8 <print_pgtbl+0x88>
    80000e96:	84e6                	mv	s1,s9
        printf("  ");
    80000e98:	855a                	mv	a0,s6
    80000e9a:	00000097          	auipc	ra,0x0
    80000e9e:	91a080e7          	jalr	-1766(ra) # 800007b4 <printf>
      for(int j = 0; j < level; j++)
    80000ea2:	2485                	addw	s1,s1,1
    80000ea4:	fe9a9ae3          	bne	s5,s1,80000e98 <print_pgtbl+0x78>
      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    80000ea8:	00a95493          	srl	s1,s2,0xa
    80000eac:	04b2                	sll	s1,s1,0xc
    80000eae:	86a6                	mv	a3,s1
    80000eb0:	864a                	mv	a2,s2
    80000eb2:	85ce                	mv	a1,s3
    80000eb4:	8562                	mv	a0,s8
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	8fe080e7          	jalr	-1794(ra) # 800007b4 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000ebe:	00e97913          	and	s2,s2,14
    80000ec2:	fa0900e3          	beqz	s2,80000e62 <print_pgtbl+0x42>
        printf(" [leaf]\n");
    80000ec6:	856a                	mv	a0,s10
    80000ec8:	00000097          	auipc	ra,0x0
    80000ecc:	8ec080e7          	jalr	-1812(ra) # 800007b4 <printf>
    80000ed0:	bf45                	j	80000e80 <print_pgtbl+0x60>
      }
    }
  }
}
    80000ed2:	60e6                	ld	ra,88(sp)
    80000ed4:	6446                	ld	s0,80(sp)
    80000ed6:	64a6                	ld	s1,72(sp)
    80000ed8:	6906                	ld	s2,64(sp)
    80000eda:	79e2                	ld	s3,56(sp)
    80000edc:	7a42                	ld	s4,48(sp)
    80000ede:	7aa2                	ld	s5,40(sp)
    80000ee0:	7b02                	ld	s6,32(sp)
    80000ee2:	6be2                	ld	s7,24(sp)
    80000ee4:	6c42                	ld	s8,16(sp)
    80000ee6:	6ca2                	ld	s9,8(sp)
    80000ee8:	6d02                	ld	s10,0(sp)
    80000eea:	6125                	add	sp,sp,96
    80000eec:	8082                	ret

0000000080000eee <print_cur_pgtbl>:

void print_cur_pgtbl(pagetable_t pagetable) {
    80000eee:	715d                	add	sp,sp,-80
    80000ef0:	e486                	sd	ra,72(sp)
    80000ef2:	e0a2                	sd	s0,64(sp)
    80000ef4:	fc26                	sd	s1,56(sp)
    80000ef6:	f84a                	sd	s2,48(sp)
    80000ef8:	f44e                	sd	s3,40(sp)
    80000efa:	f052                	sd	s4,32(sp)
    80000efc:	ec56                	sd	s5,24(sp)
    80000efe:	e85a                	sd	s6,16(sp)
    80000f00:	e45e                	sd	s7,8(sp)
    80000f02:	0880                	add	s0,sp,80
    80000f04:	89aa                	mv	s3,a0
  //打印当前层页表
  printf("page table %p\n", pagetable);
    80000f06:	85aa                	mv	a1,a0
    80000f08:	00003517          	auipc	a0,0x3
    80000f0c:	25850513          	add	a0,a0,600 # 80004160 <digits+0xe0>
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	8a4080e7          	jalr	-1884(ra) # 800007b4 <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f18:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000f1a:	00003a97          	auipc	s5,0x3
    80000f1e:	256a8a93          	add	s5,s5,598 # 80004170 <digits+0xf0>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
    80000f22:	00003b97          	auipc	s7,0x3
    80000f26:	10eb8b93          	add	s7,s7,270 # 80004030 <etext+0x30>
        printf(" [leaf]\n");
    80000f2a:	00003b17          	auipc	s6,0x3
    80000f2e:	226b0b13          	add	s6,s6,550 # 80004150 <digits+0xd0>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f32:	20000a13          	li	s4,512
    80000f36:	a811                	j	80000f4a <print_cur_pgtbl+0x5c>
        printf("\n");
    80000f38:	855e                	mv	a0,s7
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	87a080e7          	jalr	-1926(ra) # 800007b4 <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f42:	2905                	addw	s2,s2,1
    80000f44:	09a1                	add	s3,s3,8
    80000f46:	03490963          	beq	s2,s4,80000f78 <print_cur_pgtbl+0x8a>
    pte_t pte = pagetable[i];
    80000f4a:	0009b483          	ld	s1,0(s3)
    if(pte & PTE_V) {// 打印有效的页表项
    80000f4e:	0014f793          	and	a5,s1,1
    80000f52:	dbe5                	beqz	a5,80000f42 <print_cur_pgtbl+0x54>
      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000f54:	00a4d693          	srl	a3,s1,0xa
    80000f58:	06b2                	sll	a3,a3,0xc
    80000f5a:	8626                	mv	a2,s1
    80000f5c:	85ca                	mv	a1,s2
    80000f5e:	8556                	mv	a0,s5
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	854080e7          	jalr	-1964(ra) # 800007b4 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000f68:	88b9                	and	s1,s1,14
    80000f6a:	d4f9                	beqz	s1,80000f38 <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80000f6c:	855a                	mv	a0,s6
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	846080e7          	jalr	-1978(ra) # 800007b4 <printf>
    80000f76:	b7f1                	j	80000f42 <print_cur_pgtbl+0x54>
      }
    }
  }
    80000f78:	60a6                	ld	ra,72(sp)
    80000f7a:	6406                	ld	s0,64(sp)
    80000f7c:	74e2                	ld	s1,56(sp)
    80000f7e:	7942                	ld	s2,48(sp)
    80000f80:	79a2                	ld	s3,40(sp)
    80000f82:	7a02                	ld	s4,32(sp)
    80000f84:	6ae2                	ld	s5,24(sp)
    80000f86:	6b42                	ld	s6,16(sp)
    80000f88:	6ba2                	ld	s7,8(sp)
    80000f8a:	6161                	add	sp,sp,80
    80000f8c:	8082                	ret

0000000080000f8e <uvmcreate>:


// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
    80000f8e:	1101                	add	sp,sp,-32
    80000f90:	ec06                	sd	ra,24(sp)
    80000f92:	e822                	sd	s0,16(sp)
    80000f94:	e426                	sd	s1,8(sp)
    80000f96:	1000                	add	s0,sp,32
  pagetable_t pagetable = (pagetable_t)kalloc(true);
    80000f98:	4505                	li	a0,1
    80000f9a:	00000097          	auipc	ra,0x0
    80000f9e:	b2c080e7          	jalr	-1236(ra) # 80000ac6 <kalloc>
    80000fa2:	84aa                	mv	s1,a0
  if(pagetable)
    80000fa4:	c519                	beqz	a0,80000fb2 <uvmcreate+0x24>
    memset(pagetable, 0, PGSIZE);
    80000fa6:	6605                	lui	a2,0x1
    80000fa8:	4581                	li	a1,0
    80000faa:	fffff097          	auipc	ra,0xfffff
    80000fae:	578080e7          	jalr	1400(ra) # 80000522 <memset>
  return pagetable;
}
    80000fb2:	8526                	mv	a0,s1
    80000fb4:	60e2                	ld	ra,24(sp)
    80000fb6:	6442                	ld	s0,16(sp)
    80000fb8:	64a2                	ld	s1,8(sp)
    80000fba:	6105                	add	sp,sp,32
    80000fbc:	8082                	ret

0000000080000fbe <uvmfirst>:

void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80000fbe:	7179                	add	sp,sp,-48
    80000fc0:	f406                	sd	ra,40(sp)
    80000fc2:	f022                	sd	s0,32(sp)
    80000fc4:	ec26                	sd	s1,24(sp)
    80000fc6:	e84a                	sd	s2,16(sp)
    80000fc8:	e44e                	sd	s3,8(sp)
    80000fca:	e052                	sd	s4,0(sp)
    80000fcc:	1800                	add	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80000fce:	6785                	lui	a5,0x1
    80000fd0:	04f67963          	bgeu	a2,a5,80001022 <uvmfirst+0x64>
    80000fd4:	8a2a                	mv	s4,a0
    80000fd6:	89ae                	mv	s3,a1
    80000fd8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc(1);
    80000fda:	4505                	li	a0,1
    80000fdc:	00000097          	auipc	ra,0x0
    80000fe0:	aea080e7          	jalr	-1302(ra) # 80000ac6 <kalloc>
    80000fe4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80000fe6:	6605                	lui	a2,0x1
    80000fe8:	4581                	li	a1,0
    80000fea:	fffff097          	auipc	ra,0xfffff
    80000fee:	538080e7          	jalr	1336(ra) # 80000522 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80000ff2:	4779                	li	a4,30
    80000ff4:	86ca                	mv	a3,s2
    80000ff6:	6605                	lui	a2,0x1
    80000ff8:	4581                	li	a1,0
    80000ffa:	8552                	mv	a0,s4
    80000ffc:	00000097          	auipc	ra,0x0
    80001000:	bf8080e7          	jalr	-1032(ra) # 80000bf4 <mappages>
  memmove(mem, src, sz);
    80001004:	8626                	mv	a2,s1
    80001006:	85ce                	mv	a1,s3
    80001008:	854a                	mv	a0,s2
    8000100a:	fffff097          	auipc	ra,0xfffff
    8000100e:	574080e7          	jalr	1396(ra) # 8000057e <memmove>
}
    80001012:	70a2                	ld	ra,40(sp)
    80001014:	7402                	ld	s0,32(sp)
    80001016:	64e2                	ld	s1,24(sp)
    80001018:	6942                	ld	s2,16(sp)
    8000101a:	69a2                	ld	s3,8(sp)
    8000101c:	6a02                	ld	s4,0(sp)
    8000101e:	6145                	add	sp,sp,48
    80001020:	8082                	ret
    panic("uvmfirst: more than a page");
    80001022:	00003517          	auipc	a0,0x3
    80001026:	16e50513          	add	a0,a0,366 # 80004190 <digits+0x110>
    8000102a:	fffff097          	auipc	ra,0xfffff
    8000102e:	740080e7          	jalr	1856(ra) # 8000076a <panic>

0000000080001032 <uvmunmap>:

// 从va开始移除npages个映射。va必须是
// 页面对齐的。映射必须存在。
// 可选择释放物理内存
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001032:	715d                	add	sp,sp,-80
    80001034:	e486                	sd	ra,72(sp)
    80001036:	e0a2                	sd	s0,64(sp)
    80001038:	fc26                	sd	s1,56(sp)
    8000103a:	f84a                	sd	s2,48(sp)
    8000103c:	f44e                	sd	s3,40(sp)
    8000103e:	f052                	sd	s4,32(sp)
    80001040:	ec56                	sd	s5,24(sp)
    80001042:	e85a                	sd	s6,16(sp)
    80001044:	e45e                	sd	s7,8(sp)
    80001046:	0880                	add	s0,sp,80
  return (addr % PGSIZE) == 0;
    80001048:	03459793          	sll	a5,a1,0x34
  uint64 current_va;
  pte_t *pte;

  if (!is_page_aligned(va))
    8000104c:	e795                	bnez	a5,80001078 <uvmunmap+0x46>
    8000104e:	8a2a                	mv	s4,a0
    80001050:	892e                	mv	s2,a1
    80001052:	8ab6                	mv	s5,a3
    panic("uvmunmap: address not page aligned");

  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    80001054:	0632                	sll	a2,a2,0xc
    80001056:	00b609b3          	add	s3,a2,a1
  if (PTE_FLAGS(pte) == PTE_V)
    8000105a:	4b05                	li	s6,1
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    8000105c:	6b85                	lui	s7,0x1
    8000105e:	0735e263          	bltu	a1,s3,800010c2 <uvmunmap+0x90>
      free_physical_page_from_pte(*pte);
    }

    clear_pte(pte);
  }
}
    80001062:	60a6                	ld	ra,72(sp)
    80001064:	6406                	ld	s0,64(sp)
    80001066:	74e2                	ld	s1,56(sp)
    80001068:	7942                	ld	s2,48(sp)
    8000106a:	79a2                	ld	s3,40(sp)
    8000106c:	7a02                	ld	s4,32(sp)
    8000106e:	6ae2                	ld	s5,24(sp)
    80001070:	6b42                	ld	s6,16(sp)
    80001072:	6ba2                	ld	s7,8(sp)
    80001074:	6161                	add	sp,sp,80
    80001076:	8082                	ret
    panic("uvmunmap: address not page aligned");
    80001078:	00003517          	auipc	a0,0x3
    8000107c:	13850513          	add	a0,a0,312 # 800041b0 <digits+0x130>
    80001080:	fffff097          	auipc	ra,0xfffff
    80001084:	6ea080e7          	jalr	1770(ra) # 8000076a <panic>
      panic("uvmunmap: walk failed");
    80001088:	00003517          	auipc	a0,0x3
    8000108c:	15050513          	add	a0,a0,336 # 800041d8 <digits+0x158>
    80001090:	fffff097          	auipc	ra,0xfffff
    80001094:	6da080e7          	jalr	1754(ra) # 8000076a <panic>
    panic("uvmunmap: page not mapped");
    80001098:	00003517          	auipc	a0,0x3
    8000109c:	15850513          	add	a0,a0,344 # 800041f0 <digits+0x170>
    800010a0:	fffff097          	auipc	ra,0xfffff
    800010a4:	6ca080e7          	jalr	1738(ra) # 8000076a <panic>
    panic("uvmunmap: not a leaf page");
    800010a8:	00003517          	auipc	a0,0x3
    800010ac:	16850513          	add	a0,a0,360 # 80004210 <digits+0x190>
    800010b0:	fffff097          	auipc	ra,0xfffff
    800010b4:	6ba080e7          	jalr	1722(ra) # 8000076a <panic>
  *pte = 0;
    800010b8:	0004b023          	sd	zero,0(s1)
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    800010bc:	995e                	add	s2,s2,s7
    800010be:	fb3972e3          	bgeu	s2,s3,80001062 <uvmunmap+0x30>
    pte = walk(pagetable, current_va, 0);
    800010c2:	4601                	li	a2,0
    800010c4:	85ca                	mv	a1,s2
    800010c6:	8552                	mv	a0,s4
    800010c8:	00000097          	auipc	ra,0x0
    800010cc:	a84080e7          	jalr	-1404(ra) # 80000b4c <walk>
    800010d0:	84aa                	mv	s1,a0
    if (pte == 0)
    800010d2:	d95d                	beqz	a0,80001088 <uvmunmap+0x56>
    validate_page_mapping(*pte);
    800010d4:	611c                	ld	a5,0(a0)
  return (pte & PTE_V) != 0;
    800010d6:	0017f713          	and	a4,a5,1
  if (!is_pte_valid(pte))
    800010da:	df5d                	beqz	a4,80001098 <uvmunmap+0x66>
  if (PTE_FLAGS(pte) == PTE_V)
    800010dc:	3ff7f713          	and	a4,a5,1023
    800010e0:	fd6704e3          	beq	a4,s6,800010a8 <uvmunmap+0x76>
    if (do_free)
    800010e4:	fc0a8ae3          	beqz	s5,800010b8 <uvmunmap+0x86>
  uint64 pa = PTE2PA(pte);
    800010e8:	83a9                	srl	a5,a5,0xa
  kfree(pa,0);
    800010ea:	4581                	li	a1,0
    800010ec:	00c79513          	sll	a0,a5,0xc
    800010f0:	00000097          	auipc	ra,0x0
    800010f4:	8d6080e7          	jalr	-1834(ra) # 800009c6 <kfree>
}
    800010f8:	b7c1                	j	800010b8 <uvmunmap+0x86>

00000000800010fa <uvmdealloc>:
{
    800010fa:	1101                	add	sp,sp,-32
    800010fc:	ec06                	sd	ra,24(sp)
    800010fe:	e822                	sd	s0,16(sp)
    80001100:	e426                	sd	s1,8(sp)
    80001102:	1000                	add	s0,sp,32
    return oldsz;
    80001104:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    80001106:	00b67d63          	bgeu	a2,a1,80001120 <uvmdealloc+0x26>
    8000110a:	84b2                	mv	s1,a2
  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    8000110c:	6785                	lui	a5,0x1
    8000110e:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001110:	00f60733          	add	a4,a2,a5
    80001114:	76fd                	lui	a3,0xfffff
    80001116:	8f75                	and	a4,a4,a3
    80001118:	97ae                	add	a5,a5,a1
    8000111a:	8ff5                	and	a5,a5,a3
    8000111c:	00f76863          	bltu	a4,a5,8000112c <uvmdealloc+0x32>
}
    80001120:	8526                	mv	a0,s1
    80001122:	60e2                	ld	ra,24(sp)
    80001124:	6442                	ld	s0,16(sp)
    80001126:	64a2                	ld	s1,8(sp)
    80001128:	6105                	add	sp,sp,32
    8000112a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000112c:	8f99                	sub	a5,a5,a4
    8000112e:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001130:	4685                	li	a3,1
    80001132:	0007861b          	sext.w	a2,a5
    80001136:	85ba                	mv	a1,a4
    80001138:	00000097          	auipc	ra,0x0
    8000113c:	efa080e7          	jalr	-262(ra) # 80001032 <uvmunmap>
    80001140:	b7c5                	j	80001120 <uvmdealloc+0x26>

0000000080001142 <uvmalloc>:
  if (newsz < oldsz)
    80001142:	0ab66763          	bltu	a2,a1,800011f0 <uvmalloc+0xae>
{
    80001146:	7139                	add	sp,sp,-64
    80001148:	fc06                	sd	ra,56(sp)
    8000114a:	f822                	sd	s0,48(sp)
    8000114c:	f426                	sd	s1,40(sp)
    8000114e:	f04a                	sd	s2,32(sp)
    80001150:	ec4e                	sd	s3,24(sp)
    80001152:	e852                	sd	s4,16(sp)
    80001154:	e456                	sd	s5,8(sp)
    80001156:	e05a                	sd	s6,0(sp)
    80001158:	0080                	add	s0,sp,64
    8000115a:	8aaa                	mv	s5,a0
    8000115c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000115e:	6785                	lui	a5,0x1
    80001160:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001162:	95be                	add	a1,a1,a5
    80001164:	77fd                	lui	a5,0xfffff
    80001166:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000116a:	08c9f563          	bgeu	s3,a2,800011f4 <uvmalloc+0xb2>
    8000116e:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001170:	0126eb13          	or	s6,a3,18
    mem = kalloc(0);
    80001174:	4501                	li	a0,0
    80001176:	00000097          	auipc	ra,0x0
    8000117a:	950080e7          	jalr	-1712(ra) # 80000ac6 <kalloc>
    8000117e:	84aa                	mv	s1,a0
    if (mem == 0)
    80001180:	c51d                	beqz	a0,800011ae <uvmalloc+0x6c>
    memset(mem, 0, PGSIZE);
    80001182:	6605                	lui	a2,0x1
    80001184:	4581                	li	a1,0
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	39c080e7          	jalr	924(ra) # 80000522 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    8000118e:	875a                	mv	a4,s6
    80001190:	86a6                	mv	a3,s1
    80001192:	6605                	lui	a2,0x1
    80001194:	85ca                	mv	a1,s2
    80001196:	8556                	mv	a0,s5
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	a5c080e7          	jalr	-1444(ra) # 80000bf4 <mappages>
    800011a0:	e90d                	bnez	a0,800011d2 <uvmalloc+0x90>
  for (a = oldsz; a < newsz; a += PGSIZE)
    800011a2:	6785                	lui	a5,0x1
    800011a4:	993e                	add	s2,s2,a5
    800011a6:	fd4967e3          	bltu	s2,s4,80001174 <uvmalloc+0x32>
  return newsz;
    800011aa:	8552                	mv	a0,s4
    800011ac:	a809                	j	800011be <uvmalloc+0x7c>
      uvmdealloc(pagetable, a, oldsz);
    800011ae:	864e                	mv	a2,s3
    800011b0:	85ca                	mv	a1,s2
    800011b2:	8556                	mv	a0,s5
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f46080e7          	jalr	-186(ra) # 800010fa <uvmdealloc>
      return 0;
    800011bc:	4501                	li	a0,0
}
    800011be:	70e2                	ld	ra,56(sp)
    800011c0:	7442                	ld	s0,48(sp)
    800011c2:	74a2                	ld	s1,40(sp)
    800011c4:	7902                	ld	s2,32(sp)
    800011c6:	69e2                	ld	s3,24(sp)
    800011c8:	6a42                	ld	s4,16(sp)
    800011ca:	6aa2                	ld	s5,8(sp)
    800011cc:	6b02                	ld	s6,0(sp)
    800011ce:	6121                	add	sp,sp,64
    800011d0:	8082                	ret
      kfree((uint64)mem,0);
    800011d2:	4581                	li	a1,0
    800011d4:	8526                	mv	a0,s1
    800011d6:	fffff097          	auipc	ra,0xfffff
    800011da:	7f0080e7          	jalr	2032(ra) # 800009c6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800011de:	864e                	mv	a2,s3
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8556                	mv	a0,s5
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f16080e7          	jalr	-234(ra) # 800010fa <uvmdealloc>
      return 0;
    800011ec:	4501                	li	a0,0
    800011ee:	bfc1                	j	800011be <uvmalloc+0x7c>
    return oldsz;
    800011f0:	852e                	mv	a0,a1
}
    800011f2:	8082                	ret
  return newsz;
    800011f4:	8532                	mv	a0,a2
    800011f6:	b7e1                	j	800011be <uvmalloc+0x7c>

00000000800011f8 <uvm_copyin>:
// 成功返回0，失败返回-1
int uvm_copyin(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    800011f8:	cebd                	beqz	a3,80001276 <uvm_copyin+0x7e>
{
    800011fa:	711d                	add	sp,sp,-96
    800011fc:	ec86                	sd	ra,88(sp)
    800011fe:	e8a2                	sd	s0,80(sp)
    80001200:	e4a6                	sd	s1,72(sp)
    80001202:	e0ca                	sd	s2,64(sp)
    80001204:	fc4e                	sd	s3,56(sp)
    80001206:	f852                	sd	s4,48(sp)
    80001208:	f456                	sd	s5,40(sp)
    8000120a:	f05a                	sd	s6,32(sp)
    8000120c:	ec5e                	sd	s7,24(sp)
    8000120e:	e862                	sd	s8,16(sp)
    80001210:	e466                	sd	s9,8(sp)
    80001212:	e06a                	sd	s10,0(sp)
    80001214:	1080                	add	s0,sp,96
    80001216:	8b2a                	mv	s6,a0
    80001218:	89ae                	mv	s3,a1
    8000121a:	84b2                	mv	s1,a2
    8000121c:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(srcva);
    8000121e:	7bfd                	lui	s7,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001220:	6a85                	lui	s5,0x1
    80001222:	fffa8c13          	add	s8,s5,-1 # fff <_entry-0x7ffff001>
    80001226:	a015                	j	8000124a <uvm_copyin+0x52>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove((void *)dst, (void *)(page_pa + src_offset), bytes_to_copy);
    80001228:	000c8d1b          	sext.w	s10,s9
    8000122c:	866a                	mv	a2,s10
    8000122e:	009505b3          	add	a1,a0,s1
    80001232:	854e                	mv	a0,s3
    80001234:	fffff097          	auipc	ra,0xfffff
    80001238:	34a080e7          	jalr	842(ra) # 8000057e <memmove>

    len -= bytes_to_copy;
    8000123c:	41a9093b          	subw	s2,s2,s10
    dst += bytes_to_copy;
    80001240:	99e6                	add	s3,s3,s9
    srcva = page_va + PGSIZE; // 移到下一页
    80001242:	015a04b3          	add	s1,s4,s5
  while (len > 0)
    80001246:	02090663          	beqz	s2,80001272 <uvm_copyin+0x7a>
    page_va = PGROUNDDOWN(srcva);
    8000124a:	0174fa33          	and	s4,s1,s7
    page_pa = walkaddr(pgtbl, page_va);
    8000124e:	85d2                	mv	a1,s4
    80001250:	855a                	mv	a0,s6
    80001252:	00000097          	auipc	ra,0x0
    80001256:	b8e080e7          	jalr	-1138(ra) # 80000de0 <walkaddr>
    if (page_pa == 0)
    8000125a:	c105                	beqz	a0,8000127a <uvm_copyin+0x82>
  uint64 page_offset = va - PGROUNDDOWN(va);
    8000125c:	0184f4b3          	and	s1,s1,s8
    bytes_to_copy = bytes_to_copy_in_page(srcva, len);
    80001260:	02091793          	sll	a5,s2,0x20
    80001264:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001266:	409a8cb3          	sub	s9,s5,s1
    8000126a:	fb97ffe3          	bgeu	a5,s9,80001228 <uvm_copyin+0x30>
    8000126e:	8cbe                	mv	s9,a5
    80001270:	bf65                	j	80001228 <uvm_copyin+0x30>
  }
  return 0;
    80001272:	4501                	li	a0,0
    80001274:	a021                	j	8000127c <uvm_copyin+0x84>
    80001276:	4501                	li	a0,0
}
    80001278:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    8000127a:	557d                	li	a0,-1
}
    8000127c:	60e6                	ld	ra,88(sp)
    8000127e:	6446                	ld	s0,80(sp)
    80001280:	64a6                	ld	s1,72(sp)
    80001282:	6906                	ld	s2,64(sp)
    80001284:	79e2                	ld	s3,56(sp)
    80001286:	7a42                	ld	s4,48(sp)
    80001288:	7aa2                	ld	s5,40(sp)
    8000128a:	7b02                	ld	s6,32(sp)
    8000128c:	6be2                	ld	s7,24(sp)
    8000128e:	6c42                	ld	s8,16(sp)
    80001290:	6ca2                	ld	s9,8(sp)
    80001292:	6d02                	ld	s10,0(sp)
    80001294:	6125                	add	sp,sp,96
    80001296:	8082                	ret

0000000080001298 <uvm_copyout>:
// 成功返回0，失败返回-1
int uvm_copyout(pgtbl_t pgtbl, uint64 dstva, uint64 src, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001298:	ceb5                	beqz	a3,80001314 <uvm_copyout+0x7c>
{
    8000129a:	711d                	add	sp,sp,-96
    8000129c:	ec86                	sd	ra,88(sp)
    8000129e:	e8a2                	sd	s0,80(sp)
    800012a0:	e4a6                	sd	s1,72(sp)
    800012a2:	e0ca                	sd	s2,64(sp)
    800012a4:	fc4e                	sd	s3,56(sp)
    800012a6:	f852                	sd	s4,48(sp)
    800012a8:	f456                	sd	s5,40(sp)
    800012aa:	f05a                	sd	s6,32(sp)
    800012ac:	ec5e                	sd	s7,24(sp)
    800012ae:	e862                	sd	s8,16(sp)
    800012b0:	e466                	sd	s9,8(sp)
    800012b2:	e06a                	sd	s10,0(sp)
    800012b4:	1080                	add	s0,sp,96
    800012b6:	8baa                	mv	s7,a0
    800012b8:	84ae                	mv	s1,a1
    800012ba:	89b2                	mv	s3,a2
    800012bc:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(dstva);
    800012be:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    800012c0:	6b05                	lui	s6,0x1
    800012c2:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    800012c6:	a00d                	j	800012e8 <uvm_copyout+0x50>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), (void *)src, bytes_to_copy);
    800012c8:	000d0a9b          	sext.w	s5,s10
    800012cc:	8656                	mv	a2,s5
    800012ce:	85ce                	mv	a1,s3
    800012d0:	9526                	add	a0,a0,s1
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	2ac080e7          	jalr	684(ra) # 8000057e <memmove>

    len -= bytes_to_copy;
    800012da:	4159093b          	subw	s2,s2,s5
    src += bytes_to_copy;
    800012de:	99ea                	add	s3,s3,s10
    dstva = page_va + PGSIZE; // 移到下一页
    800012e0:	016a04b3          	add	s1,s4,s6
  while (len > 0)
    800012e4:	02090663          	beqz	s2,80001310 <uvm_copyout+0x78>
    page_va = PGROUNDDOWN(dstva);
    800012e8:	0184fa33          	and	s4,s1,s8
    page_pa = walkaddr(pgtbl, page_va);
    800012ec:	85d2                	mv	a1,s4
    800012ee:	855e                	mv	a0,s7
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	af0080e7          	jalr	-1296(ra) # 80000de0 <walkaddr>
    if (page_pa == 0)
    800012f8:	c105                	beqz	a0,80001318 <uvm_copyout+0x80>
  uint64 page_offset = va - PGROUNDDOWN(va);
    800012fa:	0194f4b3          	and	s1,s1,s9
    bytes_to_copy = bytes_to_copy_in_page(dstva, len);
    800012fe:	02091793          	sll	a5,s2,0x20
    80001302:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001304:	409b0d33          	sub	s10,s6,s1
    80001308:	fda7f0e3          	bgeu	a5,s10,800012c8 <uvm_copyout+0x30>
    8000130c:	8d3e                	mv	s10,a5
    8000130e:	bf6d                	j	800012c8 <uvm_copyout+0x30>
  }
  return 0;
    80001310:	4501                	li	a0,0
    80001312:	a021                	j	8000131a <uvm_copyout+0x82>
    80001314:	4501                	li	a0,0
}
    80001316:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001318:	557d                	li	a0,-1
}
    8000131a:	60e6                	ld	ra,88(sp)
    8000131c:	6446                	ld	s0,80(sp)
    8000131e:	64a6                	ld	s1,72(sp)
    80001320:	6906                	ld	s2,64(sp)
    80001322:	79e2                	ld	s3,56(sp)
    80001324:	7a42                	ld	s4,48(sp)
    80001326:	7aa2                	ld	s5,40(sp)
    80001328:	7b02                	ld	s6,32(sp)
    8000132a:	6be2                	ld	s7,24(sp)
    8000132c:	6c42                	ld	s8,16(sp)
    8000132e:	6ca2                	ld	s9,8(sp)
    80001330:	6d02                	ld	s10,0(sp)
    80001332:	6125                	add	sp,sp,96
    80001334:	8082                	ret

0000000080001336 <uvm_copyin_str>:
int uvm_copyin_str(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 maxlen)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && maxlen > 0)
    80001336:	c6dd                	beqz	a3,800013e4 <uvm_copyin_str+0xae>
{
    80001338:	715d                	add	sp,sp,-80
    8000133a:	e486                	sd	ra,72(sp)
    8000133c:	e0a2                	sd	s0,64(sp)
    8000133e:	fc26                	sd	s1,56(sp)
    80001340:	f84a                	sd	s2,48(sp)
    80001342:	f44e                	sd	s3,40(sp)
    80001344:	f052                	sd	s4,32(sp)
    80001346:	ec56                	sd	s5,24(sp)
    80001348:	e85a                	sd	s6,16(sp)
    8000134a:	e45e                	sd	s7,8(sp)
    8000134c:	0880                	add	s0,sp,80
    8000134e:	8aaa                	mv	s5,a0
    80001350:	89ae                	mv	s3,a1
    80001352:	8bb2                	mv	s7,a2
    80001354:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001356:	7b7d                	lui	s6,0xfffff
    pa0 = walkaddr(pgtbl, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001358:	6a05                	lui	s4,0x1
    8000135a:	a02d                	j	80001384 <uvm_copyin_str+0x4e>
        *(char*)dst = *p;
      }
      --n;
      --maxlen;
      p++;
      dst++;
    8000135c:	87ba                	mv	a5,a4
      if (*p == '\0')
    8000135e:	00f60733          	add	a4,a2,a5
    80001362:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffef0d8>
    80001366:	cb31                	beqz	a4,800013ba <uvm_copyin_str+0x84>
        *(char*)dst = *p;
    80001368:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      dst++;
    8000136c:	00178713          	add	a4,a5,1
    while (n > 0)
    80001370:	fee696e3          	bne	a3,a4,8000135c <uvm_copyin_str+0x26>
    80001374:	34fd                	addw	s1,s1,-1
    80001376:	013484bb          	addw	s1,s1,s3
      --maxlen;
    8000137a:	9c9d                	subw	s1,s1,a5
      dst++;
    8000137c:	89ba                	mv	s3,a4
    }

    srcva = va0 + PGSIZE;
    8000137e:	01490bb3          	add	s7,s2,s4
  while (got_null == 0 && maxlen > 0)
    80001382:	cca9                	beqz	s1,800013dc <uvm_copyin_str+0xa6>
    va0 = PGROUNDDOWN(srcva);
    80001384:	016bf933          	and	s2,s7,s6
    pa0 = walkaddr(pgtbl, va0);
    80001388:	85ca                	mv	a1,s2
    8000138a:	8556                	mv	a0,s5
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	a54080e7          	jalr	-1452(ra) # 80000de0 <walkaddr>
    if (pa0 == 0)
    80001394:	c531                	beqz	a0,800013e0 <uvm_copyin_str+0xaa>
    n = PGSIZE - (srcva - va0);
    80001396:	417906b3          	sub	a3,s2,s7
    if (n > maxlen)
    8000139a:	02049793          	sll	a5,s1,0x20
    8000139e:	9381                	srl	a5,a5,0x20
    800013a0:	96d2                	add	a3,a3,s4
    800013a2:	00d7f363          	bgeu	a5,a3,800013a8 <uvm_copyin_str+0x72>
    800013a6:	86be                	mv	a3,a5
    char *p = (char *)(pa0 + (srcva - va0));
    800013a8:	955e                	add	a0,a0,s7
    800013aa:	41250533          	sub	a0,a0,s2
    while (n > 0)
    800013ae:	dae1                	beqz	a3,8000137e <uvm_copyin_str+0x48>
    800013b0:	87ce                	mv	a5,s3
      if (*p == '\0')
    800013b2:	41350633          	sub	a2,a0,s3
    while (n > 0)
    800013b6:	96ce                	add	a3,a3,s3
    800013b8:	b75d                	j	8000135e <uvm_copyin_str+0x28>
        *(char*)dst = '\0';
    800013ba:	00078023          	sb	zero,0(a5)
    800013be:	4785                	li	a5,1
  }
  if (got_null)
    800013c0:	37fd                	addw	a5,a5,-1
    800013c2:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
    800013c6:	60a6                	ld	ra,72(sp)
    800013c8:	6406                	ld	s0,64(sp)
    800013ca:	74e2                	ld	s1,56(sp)
    800013cc:	7942                	ld	s2,48(sp)
    800013ce:	79a2                	ld	s3,40(sp)
    800013d0:	7a02                	ld	s4,32(sp)
    800013d2:	6ae2                	ld	s5,24(sp)
    800013d4:	6b42                	ld	s6,16(sp)
    800013d6:	6ba2                	ld	s7,8(sp)
    800013d8:	6161                	add	sp,sp,80
    800013da:	8082                	ret
    800013dc:	4781                	li	a5,0
    800013de:	b7cd                	j	800013c0 <uvm_copyin_str+0x8a>
      return -1;
    800013e0:	557d                	li	a0,-1
    800013e2:	b7d5                	j	800013c6 <uvm_copyin_str+0x90>
  int got_null = 0;
    800013e4:	4781                	li	a5,0
  if (got_null)
    800013e6:	37fd                	addw	a5,a5,-1
    800013e8:	0007851b          	sext.w	a0,a5
    800013ec:	8082                	ret

00000000800013ee <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800013ee:	1141                	add	sp,sp,-16
    800013f0:	e422                	sd	s0,8(sp)
    800013f2:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800013f4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800013f6:	2501                	sext.w	a0,a0
    800013f8:	6422                	ld	s0,8(sp)
    800013fa:	0141                	add	sp,sp,16
    800013fc:	8082                	ret

00000000800013fe <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800013fe:	1141                	add	sp,sp,-16
    80001400:	e422                	sd	s0,8(sp)
    80001402:	0800                	add	s0,sp,16
    80001404:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001406:	2781                	sext.w	a5,a5
    80001408:	079e                	sll	a5,a5,0x7
  return c;
}
    8000140a:	0000b517          	auipc	a0,0xb
    8000140e:	50650513          	add	a0,a0,1286 # 8000c910 <cpus>
    80001412:	953e                	add	a0,a0,a5
    80001414:	6422                	ld	s0,8(sp)
    80001416:	0141                	add	sp,sp,16
    80001418:	8082                	ret

000000008000141a <myproc>:


proc_t* myproc(void)
{
    8000141a:	1101                	add	sp,sp,-32
    8000141c:	ec06                	sd	ra,24(sp)
    8000141e:	e822                	sd	s0,16(sp)
    80001420:	e426                	sd	s1,8(sp)
    80001422:	1000                	add	s0,sp,32
  push_off();
    80001424:	00000097          	auipc	ra,0x0
    80001428:	4b0080e7          	jalr	1200(ra) # 800018d4 <push_off>
    8000142c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000142e:	2781                	sext.w	a5,a5
    80001430:	079e                	sll	a5,a5,0x7
    80001432:	0000b717          	auipc	a4,0xb
    80001436:	4de70713          	add	a4,a4,1246 # 8000c910 <cpus>
    8000143a:	97ba                	add	a5,a5,a4
    8000143c:	6784                	ld	s1,8(a5)
  pop_off();
    8000143e:	00000097          	auipc	ra,0x0
    80001442:	536080e7          	jalr	1334(ra) # 80001974 <pop_off>
  return p;
}
    80001446:	8526                	mv	a0,s1
    80001448:	60e2                	ld	ra,24(sp)
    8000144a:	6442                	ld	s0,16(sp)
    8000144c:	64a2                	ld	s1,8(sp)
    8000144e:	6105                	add	sp,sp,32
    80001450:	8082                	ret

0000000080001452 <allocpid>:

int
allocpid()
{
    80001452:	1101                	add	sp,sp,-32
    80001454:	ec06                	sd	ra,24(sp)
    80001456:	e822                	sd	s0,16(sp)
    80001458:	e426                	sd	s1,8(sp)
    8000145a:	e04a                	sd	s2,0(sp)
    8000145c:	1000                	add	s0,sp,32
  int pid;
  
  acquire(&pid_lock);
    8000145e:	0000c917          	auipc	s2,0xc
    80001462:	8b290913          	add	s2,s2,-1870 # 8000cd10 <pid_lock>
    80001466:	854a                	mv	a0,s2
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	4b8080e7          	jalr	1208(ra) # 80001920 <acquire>
  pid = nextpid;
    80001470:	00003797          	auipc	a5,0x3
    80001474:	1c078793          	add	a5,a5,448 # 80004630 <nextpid>
    80001478:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    8000147a:	0014871b          	addw	a4,s1,1
    8000147e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001480:	854a                	mv	a0,s2
    80001482:	00000097          	auipc	ra,0x0
    80001486:	552080e7          	jalr	1362(ra) # 800019d4 <release>

  return pid;
    8000148a:	8526                	mv	a0,s1
    8000148c:	60e2                	ld	ra,24(sp)
    8000148e:	6442                	ld	s0,16(sp)
    80001490:	64a2                	ld	s1,8(sp)
    80001492:	6902                	ld	s2,0(sp)
    80001494:	6105                	add	sp,sp,32
    80001496:	8082                	ret

0000000080001498 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001498:	1141                	add	sp,sp,-16
    8000149a:	e406                	sd	ra,8(sp)
    8000149c:	e022                	sd	s0,0(sp)
    8000149e:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	f7a080e7          	jalr	-134(ra) # 8000141a <myproc>
    800014a8:	0521                	add	a0,a0,8
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	52a080e7          	jalr	1322(ra) # 800019d4 <release>

  if (first) {
    800014b2:	00003797          	auipc	a5,0x3
    800014b6:	1827a783          	lw	a5,386(a5) # 80004634 <first.0>
    800014ba:	c789                	beqz	a5,800014c4 <forkret+0x2c>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    800014bc:	00003797          	auipc	a5,0x3
    800014c0:	1607ac23          	sw	zero,376(a5) # 80004634 <first.0>
    // fsinit(ROOTDEV); //初始化文件系统
  }

  trap_user_return();
    800014c4:	00001097          	auipc	ra,0x1
    800014c8:	878080e7          	jalr	-1928(ra) # 80001d3c <trap_user_return>
}
    800014cc:	60a2                	ld	ra,8(sp)
    800014ce:	6402                	ld	s0,0(sp)
    800014d0:	0141                	add	sp,sp,16
    800014d2:	8082                	ret

00000000800014d4 <proc_mapstacks>:
{
    800014d4:	7139                	add	sp,sp,-64
    800014d6:	fc06                	sd	ra,56(sp)
    800014d8:	f822                	sd	s0,48(sp)
    800014da:	f426                	sd	s1,40(sp)
    800014dc:	f04a                	sd	s2,32(sp)
    800014de:	ec4e                	sd	s3,24(sp)
    800014e0:	e852                	sd	s4,16(sp)
    800014e2:	e456                	sd	s5,8(sp)
    800014e4:	e05a                	sd	s6,0(sp)
    800014e6:	0080                	add	s0,sp,64
    800014e8:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800014ea:	0000c497          	auipc	s1,0xc
    800014ee:	83e48493          	add	s1,s1,-1986 # 8000cd28 <proc>
    uint64 va = KSTACK((int) (p - proc));
    800014f2:	8b26                	mv	s6,s1
    800014f4:	00003a97          	auipc	s5,0x3
    800014f8:	b0ca8a93          	add	s5,s5,-1268 # 80004000 <etext>
    800014fc:	04000937          	lui	s2,0x4000
    80001500:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001502:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001504:	0000fa17          	auipc	s4,0xf
    80001508:	a24a0a13          	add	s4,s4,-1500 # 8000ff28 <end>
    char *pa = kalloc(1);
    8000150c:	4505                	li	a0,1
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	5b8080e7          	jalr	1464(ra) # 80000ac6 <kalloc>
    80001516:	862a                	mv	a2,a0
    if(pa == 0)
    80001518:	c131                	beqz	a0,8000155c <proc_mapstacks+0x88>
    uint64 va = KSTACK((int) (p - proc));
    8000151a:	416485b3          	sub	a1,s1,s6
    8000151e:	858d                	sra	a1,a1,0x3
    80001520:	000ab783          	ld	a5,0(s5)
    80001524:	02f585b3          	mul	a1,a1,a5
    80001528:	2585                	addw	a1,a1,1
    8000152a:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000152e:	4719                	li	a4,6
    80001530:	6685                	lui	a3,0x1
    80001532:	40b905b3          	sub	a1,s2,a1
    80001536:	854e                	mv	a0,s3
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	780080e7          	jalr	1920(ra) # 80000cb8 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001540:	0c848493          	add	s1,s1,200
    80001544:	fd4494e3          	bne	s1,s4,8000150c <proc_mapstacks+0x38>
}
    80001548:	70e2                	ld	ra,56(sp)
    8000154a:	7442                	ld	s0,48(sp)
    8000154c:	74a2                	ld	s1,40(sp)
    8000154e:	7902                	ld	s2,32(sp)
    80001550:	69e2                	ld	s3,24(sp)
    80001552:	6a42                	ld	s4,16(sp)
    80001554:	6aa2                	ld	s5,8(sp)
    80001556:	6b02                	ld	s6,0(sp)
    80001558:	6121                	add	sp,sp,64
    8000155a:	8082                	ret
      panic("kalloc");
    8000155c:	00003517          	auipc	a0,0x3
    80001560:	cd450513          	add	a0,a0,-812 # 80004230 <digits+0x1b0>
    80001564:	fffff097          	auipc	ra,0xfffff
    80001568:	206080e7          	jalr	518(ra) # 8000076a <panic>

000000008000156c <procinit>:
{
    8000156c:	7139                	add	sp,sp,-64
    8000156e:	fc06                	sd	ra,56(sp)
    80001570:	f822                	sd	s0,48(sp)
    80001572:	f426                	sd	s1,40(sp)
    80001574:	f04a                	sd	s2,32(sp)
    80001576:	ec4e                	sd	s3,24(sp)
    80001578:	e852                	sd	s4,16(sp)
    8000157a:	e456                	sd	s5,8(sp)
    8000157c:	e05a                	sd	s6,0(sp)
    8000157e:	0080                	add	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001580:	00003597          	auipc	a1,0x3
    80001584:	cb858593          	add	a1,a1,-840 # 80004238 <digits+0x1b8>
    80001588:	0000b517          	auipc	a0,0xb
    8000158c:	78850513          	add	a0,a0,1928 # 8000cd10 <pid_lock>
    80001590:	00000097          	auipc	ra,0x0
    80001594:	300080e7          	jalr	768(ra) # 80001890 <initlock>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001598:	0000b497          	auipc	s1,0xb
    8000159c:	79048493          	add	s1,s1,1936 # 8000cd28 <proc>
      initlock(&p->lock, "proc");
    800015a0:	00003b17          	auipc	s6,0x3
    800015a4:	ca0b0b13          	add	s6,s6,-864 # 80004240 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    800015a8:	8aa6                	mv	s5,s1
    800015aa:	00003a17          	auipc	s4,0x3
    800015ae:	a56a0a13          	add	s4,s4,-1450 # 80004000 <etext>
    800015b2:	04000937          	lui	s2,0x4000
    800015b6:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800015b8:	0932                	sll	s2,s2,0xc
    for(p = proc; p < &proc[NPROC]; p++) {
    800015ba:	0000f997          	auipc	s3,0xf
    800015be:	96e98993          	add	s3,s3,-1682 # 8000ff28 <end>
      initlock(&p->lock, "proc");
    800015c2:	85da                	mv	a1,s6
    800015c4:	00848513          	add	a0,s1,8
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	2c8080e7          	jalr	712(ra) # 80001890 <initlock>
      p->state = UNUSED;
    800015d0:	0204a023          	sw	zero,32(s1)
      p->kstack = KSTACK((int) (p - proc));
    800015d4:	415487b3          	sub	a5,s1,s5
    800015d8:	878d                	sra	a5,a5,0x3
    800015da:	000a3703          	ld	a4,0(s4)
    800015de:	02e787b3          	mul	a5,a5,a4
    800015e2:	2785                	addw	a5,a5,1
    800015e4:	00d7979b          	sllw	a5,a5,0xd
    800015e8:	40f907b3          	sub	a5,s2,a5
    800015ec:	e8bc                	sd	a5,80(s1)
    for(p = proc; p < &proc[NPROC]; p++) {
    800015ee:	0c848493          	add	s1,s1,200
    800015f2:	fd3498e3          	bne	s1,s3,800015c2 <procinit+0x56>
}
    800015f6:	70e2                	ld	ra,56(sp)
    800015f8:	7442                	ld	s0,48(sp)
    800015fa:	74a2                	ld	s1,40(sp)
    800015fc:	7902                	ld	s2,32(sp)
    800015fe:	69e2                	ld	s3,24(sp)
    80001600:	6a42                	ld	s4,16(sp)
    80001602:	6aa2                	ld	s5,8(sp)
    80001604:	6b02                	ld	s6,0(sp)
    80001606:	6121                	add	sp,sp,64
    80001608:	8082                	ret

000000008000160a <proc_freepagetable>:

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    8000160a:	1141                	add	sp,sp,-16
    8000160c:	e422                	sd	s0,8(sp)
    8000160e:	0800                	add	s0,sp,16
  // uvmunmap(pagetable, TRAMPOLINE, 1, 0); //TODO
  // uvmunmap(pagetable, TRAPFRAME, 1, 0);
  // uvmfree(pagetable, sz);
}
    80001610:	6422                	ld	s0,8(sp)
    80001612:	0141                	add	sp,sp,16
    80001614:	8082                	ret

0000000080001616 <freeproc>:

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
void freeproc(struct proc *p)
{
    80001616:	1101                	add	sp,sp,-32
    80001618:	ec06                	sd	ra,24(sp)
    8000161a:	e822                	sd	s0,16(sp)
    8000161c:	e426                	sd	s1,8(sp)
    8000161e:	1000                	add	s0,sp,32
    80001620:	84aa                	mv	s1,a0
  if(p->tf)
    80001622:	6128                	ld	a0,64(a0)
    80001624:	c511                	beqz	a0,80001630 <freeproc+0x1a>
    kfree((uint64)p->tf,1);
    80001626:	4585                	li	a1,1
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	39e080e7          	jalr	926(ra) # 800009c6 <kfree>
  p->tf = 0;
    80001630:	0404b023          	sd	zero,64(s1)
  if(p->pgtbl)
    proc_freepagetable(p->pgtbl, p->sz);
  if(p->kstack)
    80001634:	68a8                	ld	a0,80(s1)
    80001636:	e105                	bnez	a0,80001656 <freeproc+0x40>
    kfree((uint64)p->kstack,1); 
  p->kstack = 0;
    80001638:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    8000163c:	0404b423          	sd	zero,72(s1)
  p->pgtbl = 0;
    80001640:	0204b423          	sd	zero,40(s1)
  p->pid = 0;
    80001644:	0004a023          	sw	zero,0(s1)
  p->state = UNUSED;
    80001648:	0204a023          	sw	zero,32(s1)
}
    8000164c:	60e2                	ld	ra,24(sp)
    8000164e:	6442                	ld	s0,16(sp)
    80001650:	64a2                	ld	s1,8(sp)
    80001652:	6105                	add	sp,sp,32
    80001654:	8082                	ret
    kfree((uint64)p->kstack,1); 
    80001656:	4585                	li	a1,1
    80001658:	fffff097          	auipc	ra,0xfffff
    8000165c:	36e080e7          	jalr	878(ra) # 800009c6 <kfree>
    80001660:	bfe1                	j	80001638 <freeproc+0x22>

0000000080001662 <proc_pgtbl_init>:

// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
    80001662:	1101                	add	sp,sp,-32
    80001664:	ec06                	sd	ra,24(sp)
    80001666:	e822                	sd	s0,16(sp)
    80001668:	e426                	sd	s1,8(sp)
    8000166a:	e04a                	sd	s2,0(sp)
    8000166c:	1000                	add	s0,sp,32
    8000166e:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    80001670:	00000097          	auipc	ra,0x0
    80001674:	91e080e7          	jalr	-1762(ra) # 80000f8e <uvmcreate>
    80001678:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000167a:	cd1d                	beqz	a0,800016b8 <proc_pgtbl_init+0x56>
    return 0;

  
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    8000167c:	4729                	li	a4,10
    8000167e:	00002697          	auipc	a3,0x2
    80001682:	98268693          	add	a3,a3,-1662 # 80003000 <_trampoline>
    80001686:	6605                	lui	a2,0x1
    80001688:	040005b7          	lui	a1,0x4000
    8000168c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000168e:	05b2                	sll	a1,a1,0xc
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	564080e7          	jalr	1380(ra) # 80000bf4 <mappages>
    80001698:	02054763          	bltz	a0,800016c6 <proc_pgtbl_init+0x64>
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000169c:	4719                	li	a4,6
    8000169e:	86ca                	mv	a3,s2
    800016a0:	6605                	lui	a2,0x1
    800016a2:	020005b7          	lui	a1,0x2000
    800016a6:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800016a8:	05b6                	sll	a1,a1,0xd
    800016aa:	8526                	mv	a0,s1
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	548080e7          	jalr	1352(ra) # 80000bf4 <mappages>
    800016b4:	02054163          	bltz	a0,800016d6 <proc_pgtbl_init+0x74>
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}
    800016b8:	8526                	mv	a0,s1
    800016ba:	60e2                	ld	ra,24(sp)
    800016bc:	6442                	ld	s0,16(sp)
    800016be:	64a2                	ld	s1,8(sp)
    800016c0:	6902                	ld	s2,0(sp)
    800016c2:	6105                	add	sp,sp,32
    800016c4:	8082                	ret
    panic("proc_pgtbl_init: mappages trampoline failed");
    800016c6:	00003517          	auipc	a0,0x3
    800016ca:	b8250513          	add	a0,a0,-1150 # 80004248 <digits+0x1c8>
    800016ce:	fffff097          	auipc	ra,0xfffff
    800016d2:	09c080e7          	jalr	156(ra) # 8000076a <panic>
    panic("proc_pgtbl_init: mappages trapframe failed");
    800016d6:	00003517          	auipc	a0,0x3
    800016da:	ba250513          	add	a0,a0,-1118 # 80004278 <digits+0x1f8>
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	08c080e7          	jalr	140(ra) # 8000076a <panic>

00000000800016e6 <allocproc>:
{
    800016e6:	7179                	add	sp,sp,-48
    800016e8:	f406                	sd	ra,40(sp)
    800016ea:	f022                	sd	s0,32(sp)
    800016ec:	ec26                	sd	s1,24(sp)
    800016ee:	e84a                	sd	s2,16(sp)
    800016f0:	e44e                	sd	s3,8(sp)
    800016f2:	1800                	add	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    800016f4:	0000b497          	auipc	s1,0xb
    800016f8:	63448493          	add	s1,s1,1588 # 8000cd28 <proc>
    800016fc:	0000f997          	auipc	s3,0xf
    80001700:	82c98993          	add	s3,s3,-2004 # 8000ff28 <end>
    acquire(&p->lock);
    80001704:	00848913          	add	s2,s1,8
    80001708:	854a                	mv	a0,s2
    8000170a:	00000097          	auipc	ra,0x0
    8000170e:	216080e7          	jalr	534(ra) # 80001920 <acquire>
    if(p->state == UNUSED) {
    80001712:	509c                	lw	a5,32(s1)
    80001714:	cf81                	beqz	a5,8000172c <allocproc+0x46>
      release(&p->lock);
    80001716:	854a                	mv	a0,s2
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	2bc080e7          	jalr	700(ra) # 800019d4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001720:	0c848493          	add	s1,s1,200
    80001724:	ff3490e3          	bne	s1,s3,80001704 <allocproc+0x1e>
  return 0;
    80001728:	4481                	li	s1,0
    8000172a:	a889                	j	8000177c <allocproc+0x96>
  p->pid = allocpid();
    8000172c:	00000097          	auipc	ra,0x0
    80001730:	d26080e7          	jalr	-730(ra) # 80001452 <allocpid>
    80001734:	c088                	sw	a0,0(s1)
  p->state = USED;
    80001736:	4785                	li	a5,1
    80001738:	d09c                	sw	a5,32(s1)
  if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    8000173a:	4505                	li	a0,1
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	38a080e7          	jalr	906(ra) # 80000ac6 <kalloc>
    80001744:	89aa                	mv	s3,a0
    80001746:	e0a8                	sd	a0,64(s1)
    80001748:	c131                	beqz	a0,8000178c <allocproc+0xa6>
  p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    8000174a:	00000097          	auipc	ra,0x0
    8000174e:	f18080e7          	jalr	-232(ra) # 80001662 <proc_pgtbl_init>
    80001752:	89aa                	mv	s3,a0
    80001754:	f488                	sd	a0,40(s1)
  if(p->pgtbl == 0){ 
    80001756:	cd39                	beqz	a0,800017b4 <allocproc+0xce>
  memset(&p->ctx, 0, sizeof(p->ctx));
    80001758:	07000613          	li	a2,112
    8000175c:	4581                	li	a1,0
    8000175e:	05848513          	add	a0,s1,88
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	dc0080e7          	jalr	-576(ra) # 80000522 <memset>
  p->ctx.ra = (uint64)forkret;
    8000176a:	00000797          	auipc	a5,0x0
    8000176e:	d2e78793          	add	a5,a5,-722 # 80001498 <forkret>
    80001772:	ecbc                	sd	a5,88(s1)
  p->ctx.sp = p->kstack+PGSIZE;
    80001774:	68bc                	ld	a5,80(s1)
    80001776:	6705                	lui	a4,0x1
    80001778:	97ba                	add	a5,a5,a4
    8000177a:	f0bc                	sd	a5,96(s1)
}
    8000177c:	8526                	mv	a0,s1
    8000177e:	70a2                	ld	ra,40(sp)
    80001780:	7402                	ld	s0,32(sp)
    80001782:	64e2                	ld	s1,24(sp)
    80001784:	6942                	ld	s2,16(sp)
    80001786:	69a2                	ld	s3,8(sp)
    80001788:	6145                	add	sp,sp,48
    8000178a:	8082                	ret
    freeproc(p);
    8000178c:	8526                	mv	a0,s1
    8000178e:	00000097          	auipc	ra,0x0
    80001792:	e88080e7          	jalr	-376(ra) # 80001616 <freeproc>
    printf("allocproc: kalloc trapframe failed\n");
    80001796:	00003517          	auipc	a0,0x3
    8000179a:	b1250513          	add	a0,a0,-1262 # 800042a8 <digits+0x228>
    8000179e:	fffff097          	auipc	ra,0xfffff
    800017a2:	016080e7          	jalr	22(ra) # 800007b4 <printf>
    release(&p->lock);
    800017a6:	854a                	mv	a0,s2
    800017a8:	00000097          	auipc	ra,0x0
    800017ac:	22c080e7          	jalr	556(ra) # 800019d4 <release>
    return 0;
    800017b0:	84ce                	mv	s1,s3
    800017b2:	b7e9                	j	8000177c <allocproc+0x96>
    freeproc(p);
    800017b4:	8526                	mv	a0,s1
    800017b6:	00000097          	auipc	ra,0x0
    800017ba:	e60080e7          	jalr	-416(ra) # 80001616 <freeproc>
    printf("allocproc: proc_pgtbl_init failed\n");
    800017be:	00003517          	auipc	a0,0x3
    800017c2:	b1250513          	add	a0,a0,-1262 # 800042d0 <digits+0x250>
    800017c6:	fffff097          	auipc	ra,0xfffff
    800017ca:	fee080e7          	jalr	-18(ra) # 800007b4 <printf>
    release(&p->lock);
    800017ce:	854a                	mv	a0,s2
    800017d0:	00000097          	auipc	ra,0x0
    800017d4:	204080e7          	jalr	516(ra) # 800019d4 <release>
    return 0;
    800017d8:	84ce                	mv	s1,s3
    800017da:	b74d                	j	8000177c <allocproc+0x96>

00000000800017dc <userinit>:
//__attribute__ ((aligned (16))) char proc0stack[8192];

// Set up first user process.
void
userinit(void)
{
    800017dc:	1101                	add	sp,sp,-32
    800017de:	ec06                	sd	ra,24(sp)
    800017e0:	e822                	sd	s0,16(sp)
    800017e2:	e426                	sd	s1,8(sp)
    800017e4:	1000                	add	s0,sp,32
  struct proc *p;

  p = allocproc();
    800017e6:	00000097          	auipc	ra,0x0
    800017ea:	f00080e7          	jalr	-256(ra) # 800016e6 <allocproc>
    800017ee:	84aa                	mv	s1,a0
  proczero = p;
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pgtbl, (uchar*)initcode_start, (uint64)(initcode_end - initcode_start));
    800017f0:	00001597          	auipc	a1,0x1
    800017f4:	9e258593          	add	a1,a1,-1566 # 800021d2 <initcode_start>
    800017f8:	00001617          	auipc	a2,0x1
    800017fc:	b4760613          	add	a2,a2,-1209 # 8000233f <initcode_end>
    80001800:	9e0d                	subw	a2,a2,a1
    80001802:	7508                	ld	a0,40(a0)
    80001804:	fffff097          	auipc	ra,0xfffff
    80001808:	7ba080e7          	jalr	1978(ra) # 80000fbe <uvmfirst>
  p->sz = PGSIZE;
    8000180c:	6785                	lui	a5,0x1
    8000180e:	e4bc                	sd	a5,72(s1)

  // prepare for the very first "return" from kernel to user.
  p->tf->epc = 0;      // user program counter
    80001810:	60b8                	ld	a4,64(s1)
    80001812:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001816:	60b8                	ld	a4,64(s1)
    80001818:	fb1c                	sd	a5,48(a4)

  // safestrcpy(p->name, "initcode", sizeof(p->name));
  //p->cwd = namei("/");

  p->state = RUNNABLE;
    8000181a:	478d                	li	a5,3
    8000181c:	d09c                	sw	a5,32(s1)

  release(&p->lock);
    8000181e:	00848513          	add	a0,s1,8
    80001822:	00000097          	auipc	ra,0x0
    80001826:	1b2080e7          	jalr	434(ra) # 800019d4 <release>
}
    8000182a:	60e2                	ld	ra,24(sp)
    8000182c:	6442                	ld	s0,16(sp)
    8000182e:	64a2                	ld	s1,8(sp)
    80001830:	6105                	add	sp,sp,32
    80001832:	8082                	ret

0000000080001834 <growproc>:

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
    80001834:	1101                	add	sp,sp,-32
    80001836:	ec06                	sd	ra,24(sp)
    80001838:	e822                	sd	s0,16(sp)
    8000183a:	e426                	sd	s1,8(sp)
    8000183c:	e04a                	sd	s2,0(sp)
    8000183e:	1000                	add	s0,sp,32
    80001840:	892a                	mv	s2,a0
  uint64 sz;
  struct proc *p = myproc();
    80001842:	00000097          	auipc	ra,0x0
    80001846:	bd8080e7          	jalr	-1064(ra) # 8000141a <myproc>
    8000184a:	84aa                	mv	s1,a0

  sz = p->sz;
    8000184c:	652c                	ld	a1,72(a0)
  if(n > 0){
    8000184e:	01204c63          	bgtz	s2,80001866 <growproc+0x32>
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    80001852:	02094663          	bltz	s2,8000187e <growproc+0x4a>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
  }
  p->sz = sz;
    80001856:	e4ac                	sd	a1,72(s1)
  return 0;
    80001858:	4501                	li	a0,0
}
    8000185a:	60e2                	ld	ra,24(sp)
    8000185c:	6442                	ld	s0,16(sp)
    8000185e:	64a2                	ld	s1,8(sp)
    80001860:	6902                	ld	s2,0(sp)
    80001862:	6105                	add	sp,sp,32
    80001864:	8082                	ret
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
    80001866:	4691                	li	a3,4
    80001868:	00b90633          	add	a2,s2,a1
    8000186c:	7508                	ld	a0,40(a0)
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	8d4080e7          	jalr	-1836(ra) # 80001142 <uvmalloc>
    80001876:	85aa                	mv	a1,a0
    80001878:	fd79                	bnez	a0,80001856 <growproc+0x22>
      return -1;
    8000187a:	557d                	li	a0,-1
    8000187c:	bff9                	j	8000185a <growproc+0x26>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
    8000187e:	00b90633          	add	a2,s2,a1
    80001882:	7508                	ld	a0,40(a0)
    80001884:	00000097          	auipc	ra,0x0
    80001888:	876080e7          	jalr	-1930(ra) # 800010fa <uvmdealloc>
    8000188c:	85aa                	mv	a1,a0
    8000188e:	b7e1                	j	80001856 <growproc+0x22>

0000000080001890 <initlock>:
#include "proc-h/cpu.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80001890:	1141                	add	sp,sp,-16
    80001892:	e422                	sd	s0,8(sp)
    80001894:	0800                	add	s0,sp,16
  lk->name = name;
    80001896:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80001898:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    8000189c:	00053823          	sd	zero,16(a0)
}
    800018a0:	6422                	ld	s0,8(sp)
    800018a2:	0141                	add	sp,sp,16
    800018a4:	8082                	ret

00000000800018a6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    800018a6:	411c                	lw	a5,0(a0)
    800018a8:	e399                	bnez	a5,800018ae <holding+0x8>
    800018aa:	4501                	li	a0,0
  return r;
}
    800018ac:	8082                	ret
{
    800018ae:	1101                	add	sp,sp,-32
    800018b0:	ec06                	sd	ra,24(sp)
    800018b2:	e822                	sd	s0,16(sp)
    800018b4:	e426                	sd	s1,8(sp)
    800018b6:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    800018b8:	6904                	ld	s1,16(a0)
    800018ba:	00000097          	auipc	ra,0x0
    800018be:	b44080e7          	jalr	-1212(ra) # 800013fe <mycpu>
    800018c2:	40a48533          	sub	a0,s1,a0
    800018c6:	00153513          	seqz	a0,a0
}
    800018ca:	60e2                	ld	ra,24(sp)
    800018cc:	6442                	ld	s0,16(sp)
    800018ce:	64a2                	ld	s1,8(sp)
    800018d0:	6105                	add	sp,sp,32
    800018d2:	8082                	ret

00000000800018d4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800018d4:	1101                	add	sp,sp,-32
    800018d6:	ec06                	sd	ra,24(sp)
    800018d8:	e822                	sd	s0,16(sp)
    800018da:	e426                	sd	s1,8(sp)
    800018dc:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800018de:	100024f3          	csrr	s1,sstatus
    800018e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800018e6:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800018e8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800018ec:	00000097          	auipc	ra,0x0
    800018f0:	b12080e7          	jalr	-1262(ra) # 800013fe <mycpu>
    800018f4:	411c                	lw	a5,0(a0)
    800018f6:	cf89                	beqz	a5,80001910 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800018f8:	00000097          	auipc	ra,0x0
    800018fc:	b06080e7          	jalr	-1274(ra) # 800013fe <mycpu>
    80001900:	411c                	lw	a5,0(a0)
    80001902:	2785                	addw	a5,a5,1 # 1001 <_entry-0x7fffefff>
    80001904:	c11c                	sw	a5,0(a0)
}
    80001906:	60e2                	ld	ra,24(sp)
    80001908:	6442                	ld	s0,16(sp)
    8000190a:	64a2                	ld	s1,8(sp)
    8000190c:	6105                	add	sp,sp,32
    8000190e:	8082                	ret
    mycpu()->intena = old;
    80001910:	00000097          	auipc	ra,0x0
    80001914:	aee080e7          	jalr	-1298(ra) # 800013fe <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80001918:	8085                	srl	s1,s1,0x1
    8000191a:	8885                	and	s1,s1,1
    8000191c:	c144                	sw	s1,4(a0)
    8000191e:	bfe9                	j	800018f8 <push_off+0x24>

0000000080001920 <acquire>:
{
    80001920:	1101                	add	sp,sp,-32
    80001922:	ec06                	sd	ra,24(sp)
    80001924:	e822                	sd	s0,16(sp)
    80001926:	e426                	sd	s1,8(sp)
    80001928:	1000                	add	s0,sp,32
    8000192a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    8000192c:	00000097          	auipc	ra,0x0
    80001930:	fa8080e7          	jalr	-88(ra) # 800018d4 <push_off>
  if(holding(lk))
    80001934:	8526                	mv	a0,s1
    80001936:	00000097          	auipc	ra,0x0
    8000193a:	f70080e7          	jalr	-144(ra) # 800018a6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    8000193e:	4705                	li	a4,1
  if(holding(lk))
    80001940:	e115                	bnez	a0,80001964 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80001942:	87ba                	mv	a5,a4
    80001944:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80001948:	2781                	sext.w	a5,a5
    8000194a:	ffe5                	bnez	a5,80001942 <acquire+0x22>
  __sync_synchronize();
    8000194c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80001950:	00000097          	auipc	ra,0x0
    80001954:	aae080e7          	jalr	-1362(ra) # 800013fe <mycpu>
    80001958:	e888                	sd	a0,16(s1)
}
    8000195a:	60e2                	ld	ra,24(sp)
    8000195c:	6442                	ld	s0,16(sp)
    8000195e:	64a2                	ld	s1,8(sp)
    80001960:	6105                	add	sp,sp,32
    80001962:	8082                	ret
    panic("acquire");
    80001964:	00003517          	auipc	a0,0x3
    80001968:	99450513          	add	a0,a0,-1644 # 800042f8 <digits+0x278>
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	dfe080e7          	jalr	-514(ra) # 8000076a <panic>

0000000080001974 <pop_off>:

void
pop_off(void)
{
    80001974:	1141                	add	sp,sp,-16
    80001976:	e406                	sd	ra,8(sp)
    80001978:	e022                	sd	s0,0(sp)
    8000197a:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    8000197c:	00000097          	auipc	ra,0x0
    80001980:	a82080e7          	jalr	-1406(ra) # 800013fe <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001984:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001988:	8b89                	and	a5,a5,2
  if(intr_get())
    8000198a:	e78d                	bnez	a5,800019b4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    8000198c:	411c                	lw	a5,0(a0)
    8000198e:	02f05b63          	blez	a5,800019c4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80001992:	37fd                	addw	a5,a5,-1
    80001994:	0007871b          	sext.w	a4,a5
    80001998:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    8000199a:	eb09                	bnez	a4,800019ac <pop_off+0x38>
    8000199c:	415c                	lw	a5,4(a0)
    8000199e:	c799                	beqz	a5,800019ac <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800019a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800019a4:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800019a8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800019ac:	60a2                	ld	ra,8(sp)
    800019ae:	6402                	ld	s0,0(sp)
    800019b0:	0141                	add	sp,sp,16
    800019b2:	8082                	ret
    panic("pop_off - interruptible");
    800019b4:	00003517          	auipc	a0,0x3
    800019b8:	94c50513          	add	a0,a0,-1716 # 80004300 <digits+0x280>
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	dae080e7          	jalr	-594(ra) # 8000076a <panic>
    panic("pop_off");
    800019c4:	00003517          	auipc	a0,0x3
    800019c8:	95450513          	add	a0,a0,-1708 # 80004318 <digits+0x298>
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	d9e080e7          	jalr	-610(ra) # 8000076a <panic>

00000000800019d4 <release>:
{
    800019d4:	1101                	add	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	e04a                	sd	s2,0(sp)
    800019de:	1000                	add	s0,sp,32
    800019e0:	84aa                	mv	s1,a0
  if(!holding(lk))
    800019e2:	00000097          	auipc	ra,0x0
    800019e6:	ec4080e7          	jalr	-316(ra) # 800018a6 <holding>
    800019ea:	c11d                	beqz	a0,80001a10 <release+0x3c>
  lk->cpu = 0;
    800019ec:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800019f0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800019f4:	0f50000f          	fence	iorw,ow
    800019f8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    800019fc:	00000097          	auipc	ra,0x0
    80001a00:	f78080e7          	jalr	-136(ra) # 80001974 <pop_off>
}
    80001a04:	60e2                	ld	ra,24(sp)
    80001a06:	6442                	ld	s0,16(sp)
    80001a08:	64a2                	ld	s1,8(sp)
    80001a0a:	6902                	ld	s2,0(sp)
    80001a0c:	6105                	add	sp,sp,32
    80001a0e:	8082                	ret
    printf("release lock %s at %p, cpu%d\n", lk->name, lk, cpuid());
    80001a10:	0084b903          	ld	s2,8(s1)
    80001a14:	00000097          	auipc	ra,0x0
    80001a18:	9da080e7          	jalr	-1574(ra) # 800013ee <cpuid>
    80001a1c:	86aa                	mv	a3,a0
    80001a1e:	8626                	mv	a2,s1
    80001a20:	85ca                	mv	a1,s2
    80001a22:	00003517          	auipc	a0,0x3
    80001a26:	8fe50513          	add	a0,a0,-1794 # 80004320 <digits+0x2a0>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	d8a080e7          	jalr	-630(ra) # 800007b4 <printf>
    panic("release");
    80001a32:	00003517          	auipc	a0,0x3
    80001a36:	90e50513          	add	a0,a0,-1778 # 80004340 <digits+0x2c0>
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	d30080e7          	jalr	-720(ra) # 8000076a <panic>

0000000080001a42 <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    80001a42:	1141                	add	sp,sp,-16
    80001a44:	e422                	sd	s0,8(sp)
    80001a46:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001a48:	00001797          	auipc	a5,0x1
    80001a4c:	96878793          	add	a5,a5,-1688 # 800023b0 <kernelvec>
    80001a50:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    80001a54:	6422                	ld	s0,8(sp)
    80001a56:	0141                	add	sp,sp,16
    80001a58:	8082                	ret

0000000080001a5a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001a5a:	142027f3          	csrr	a5,scause
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    80001a5e:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80001a60:	0807d763          	bgez	a5,80001aee <devintr+0x94>
{
    80001a64:	1101                	add	sp,sp,-32
    80001a66:	ec06                	sd	ra,24(sp)
    80001a68:	e822                	sd	s0,16(sp)
    80001a6a:	e426                	sd	s1,8(sp)
    80001a6c:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80001a6e:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80001a72:	46a5                	li	a3,9
    80001a74:	00d70d63          	beq	a4,a3,80001a8e <devintr+0x34>
  if(scause == 0x8000000000000001L){
    80001a78:	577d                	li	a4,-1
    80001a7a:	177e                	sll	a4,a4,0x3f
    80001a7c:	0705                	add	a4,a4,1
    return 0;  // 未识别的中断类型
    80001a7e:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    80001a80:	04e78663          	beq	a5,a4,80001acc <devintr+0x72>
  }
}
    80001a84:	60e2                	ld	ra,24(sp)
    80001a86:	6442                	ld	s0,16(sp)
    80001a88:	64a2                	ld	s1,8(sp)
    80001a8a:	6105                	add	sp,sp,32
    80001a8c:	8082                	ret
    int irq = plic_claim();  // 获取中断请求号
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	a46080e7          	jalr	-1466(ra) # 800004d4 <plic_claim>
    80001a96:	84aa                	mv	s1,a0
    switch(irq){
    80001a98:	47a9                	li	a5,10
    80001a9a:	02f50463          	beq	a0,a5,80001ac2 <devintr+0x68>
    return 1;
    80001a9e:	4505                	li	a0,1
      if(irq){
    80001aa0:	d0f5                	beqz	s1,80001a84 <devintr+0x2a>
        printf("unexpected interrupt irq=%d\n", irq);
    80001aa2:	85a6                	mv	a1,s1
    80001aa4:	00003517          	auipc	a0,0x3
    80001aa8:	8a450513          	add	a0,a0,-1884 # 80004348 <digits+0x2c8>
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	d08080e7          	jalr	-760(ra) # 800007b4 <printf>
      plic_complete(irq);
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	a42080e7          	jalr	-1470(ra) # 800004f8 <plic_complete>
    return 1;
    80001abe:	4505                	li	a0,1
    80001ac0:	b7d1                	j	80001a84 <devintr+0x2a>
      uartintr();           // 处理串口中断
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	8d8080e7          	jalr	-1832(ra) # 8000039a <uartintr>
    if(irq)
    80001aca:	b7ed                	j	80001ab4 <devintr+0x5a>
    if(cpuid() == 0){
    80001acc:	00000097          	auipc	ra,0x0
    80001ad0:	922080e7          	jalr	-1758(ra) # 800013ee <cpuid>
    80001ad4:	c901                	beqz	a0,80001ae4 <devintr+0x8a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80001ad6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80001ada:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80001adc:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    80001ae0:	4509                	li	a0,2
    80001ae2:	b74d                	j	80001a84 <devintr+0x2a>
      timer_update();
    80001ae4:	ffffe097          	auipc	ra,0xffffe
    80001ae8:	772080e7          	jalr	1906(ra) # 80000256 <timer_update>
    80001aec:	b7ed                	j	80001ad6 <devintr+0x7c>
}
    80001aee:	8082                	ret

0000000080001af0 <kerneltrap>:
{
    80001af0:	7179                	add	sp,sp,-48
    80001af2:	f406                	sd	ra,40(sp)
    80001af4:	f022                	sd	s0,32(sp)
    80001af6:	ec26                	sd	s1,24(sp)
    80001af8:	e84a                	sd	s2,16(sp)
    80001afa:	e44e                	sd	s3,8(sp)
    80001afc:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001afe:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b02:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001b06:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80001b0a:	1004f793          	and	a5,s1,256
    80001b0e:	cb85                	beqz	a5,80001b3e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b10:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001b14:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80001b16:	ef85                	bnez	a5,80001b4e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80001b18:	00000097          	auipc	ra,0x0
    80001b1c:	f42080e7          	jalr	-190(ra) # 80001a5a <devintr>
    80001b20:	cd1d                	beqz	a0,80001b5e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 /*&& myproc()->state == RUNNING*/)
    80001b22:	4789                	li	a5,2
    80001b24:	06f50a63          	beq	a0,a5,80001b98 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001b28:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001b2c:	10049073          	csrw	sstatus,s1
}
    80001b30:	70a2                	ld	ra,40(sp)
    80001b32:	7402                	ld	s0,32(sp)
    80001b34:	64e2                	ld	s1,24(sp)
    80001b36:	6942                	ld	s2,16(sp)
    80001b38:	69a2                	ld	s3,8(sp)
    80001b3a:	6145                	add	sp,sp,48
    80001b3c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80001b3e:	00003517          	auipc	a0,0x3
    80001b42:	82a50513          	add	a0,a0,-2006 # 80004368 <digits+0x2e8>
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	c24080e7          	jalr	-988(ra) # 8000076a <panic>
    panic("kerneltrap: interrupts enabled");
    80001b4e:	00003517          	auipc	a0,0x3
    80001b52:	84250513          	add	a0,a0,-1982 # 80004390 <digits+0x310>
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	c14080e7          	jalr	-1004(ra) # 8000076a <panic>
    printf("scause %p\n", scause);
    80001b5e:	85ce                	mv	a1,s3
    80001b60:	00003517          	auipc	a0,0x3
    80001b64:	85050513          	add	a0,a0,-1968 # 800043b0 <digits+0x330>
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	c4c080e7          	jalr	-948(ra) # 800007b4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001b70:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001b74:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80001b78:	00003517          	auipc	a0,0x3
    80001b7c:	84850513          	add	a0,a0,-1976 # 800043c0 <digits+0x340>
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	c34080e7          	jalr	-972(ra) # 800007b4 <printf>
    panic("kerneltrap");
    80001b88:	00003517          	auipc	a0,0x3
    80001b8c:	85050513          	add	a0,a0,-1968 # 800043d8 <digits+0x358>
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	bda080e7          	jalr	-1062(ra) # 8000076a <panic>
  if(which_dev == 2 && myproc() != 0 /*&& myproc()->state == RUNNING*/)
    80001b98:	00000097          	auipc	ra,0x0
    80001b9c:	882080e7          	jalr	-1918(ra) # 8000141a <myproc>
    80001ba0:	d541                	beqz	a0,80001b28 <kerneltrap+0x38>
    yield();
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	154080e7          	jalr	340(ra) # 80001cf6 <yield>
    80001baa:	bfbd                	j	80001b28 <kerneltrap+0x38>

0000000080001bac <scheduler>:
//  - 选择一个进程运行
//  - 通过swtch切换到该进程开始运行
//  - 最终该进程通过swtch将控制权交回给调度器
void
scheduler(void)
{
    80001bac:	715d                	add	sp,sp,-80
    80001bae:	e486                	sd	ra,72(sp)
    80001bb0:	e0a2                	sd	s0,64(sp)
    80001bb2:	fc26                	sd	s1,56(sp)
    80001bb4:	f84a                	sd	s2,48(sp)
    80001bb6:	f44e                	sd	s3,40(sp)
    80001bb8:	f052                	sd	s4,32(sp)
    80001bba:	ec56                	sd	s5,24(sp)
    80001bbc:	e85a                	sd	s6,16(sp)
    80001bbe:	e45e                	sd	s7,8(sp)
    80001bc0:	0880                	add	s0,sp,80
  struct proc *p;
  struct cpu *c = mycpu();
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	83c080e7          	jalr	-1988(ra) # 800013fe <mycpu>
    80001bca:	8aaa                	mv	s5,a0
  
  c->proc = 0;
    80001bcc:	00053423          	sd	zero,8(a0)
    intr_on();

    // 遍历进程表，寻找可运行的进程
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
    80001bd0:	4a0d                	li	s4,3
        
        // 切换到选中的进程。进程有责任释放其锁
        // 然后在跳回调度器之前重新获取锁
        p->state = RUNNING;
    80001bd2:	4b91                	li	s7,4
        c->proc = p;
        
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    80001bd4:	01050b13          	add	s6,a0,16
    for(p = proc; p < &proc[NPROC]; p++) {
    80001bd8:	0000e997          	auipc	s3,0xe
    80001bdc:	35098993          	add	s3,s3,848 # 8000ff28 <end>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001be0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001be4:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001be8:	10079073          	csrw	sstatus,a5
    80001bec:	0000b497          	auipc	s1,0xb
    80001bf0:	13c48493          	add	s1,s1,316 # 8000cd28 <proc>
    80001bf4:	a811                	j	80001c08 <scheduler+0x5c>
        // 进程暂时运行完毕
        // 它应该在返回之前改变了p->state
        c->proc = 0;
      }
      release(&p->lock);
    80001bf6:	854a                	mv	a0,s2
    80001bf8:	00000097          	auipc	ra,0x0
    80001bfc:	ddc080e7          	jalr	-548(ra) # 800019d4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001c00:	0c848493          	add	s1,s1,200
    80001c04:	fd348ee3          	beq	s1,s3,80001be0 <scheduler+0x34>
      acquire(&p->lock);
    80001c08:	00848913          	add	s2,s1,8
    80001c0c:	854a                	mv	a0,s2
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	d12080e7          	jalr	-750(ra) # 80001920 <acquire>
      if(p->state == RUNNABLE) {
    80001c16:	509c                	lw	a5,32(s1)
    80001c18:	fd479fe3          	bne	a5,s4,80001bf6 <scheduler+0x4a>
        p->state = RUNNING;
    80001c1c:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    80001c20:	009ab423          	sd	s1,8(s5)
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    80001c24:	05848593          	add	a1,s1,88
    80001c28:	855a                	mv	a0,s6
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	716080e7          	jalr	1814(ra) # 80002340 <swtch>
        c->proc = 0;
    80001c32:	000ab423          	sd	zero,8(s5)
    80001c36:	b7c1                	j	80001bf6 <scheduler+0x4a>

0000000080001c38 <sched>:
// 并且已经改变了proc->state。
// 因为intena是这个内核线程的属性，而不是这个CPU的属性。
// 因此此处需要保存和恢复intena
void
sched(void)
{
    80001c38:	1101                	add	sp,sp,-32
    80001c3a:	ec06                	sd	ra,24(sp)
    80001c3c:	e822                	sd	s0,16(sp)
    80001c3e:	e426                	sd	s1,8(sp)
    80001c40:	e04a                	sd	s2,0(sp)
    80001c42:	1000                	add	s0,sp,32
  int intena;
  struct proc *p = myproc();
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	7d6080e7          	jalr	2006(ra) # 8000141a <myproc>
    80001c4c:	84aa                	mv	s1,a0

  if(!holding(&p->lock))
    80001c4e:	0521                	add	a0,a0,8
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	c56080e7          	jalr	-938(ra) # 800018a6 <holding>
    80001c58:	cd39                	beqz	a0,80001cb6 <sched+0x7e>
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	7a4080e7          	jalr	1956(ra) # 800013fe <mycpu>
    80001c62:	4118                	lw	a4,0(a0)
    80001c64:	4785                	li	a5,1
    80001c66:	06f71063          	bne	a4,a5,80001cc6 <sched+0x8e>
    panic("sched locks");
  if(p->state == RUNNING)
    80001c6a:	5098                	lw	a4,32(s1)
    80001c6c:	4791                	li	a5,4
    80001c6e:	06f70463          	beq	a4,a5,80001cd6 <sched+0x9e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001c72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001c76:	8b89                	and	a5,a5,2
    panic("sched running");
  if(intr_get())
    80001c78:	e7bd                	bnez	a5,80001ce6 <sched+0xae>
    panic("sched interruptible");

  intena = mycpu()->intena;
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	784080e7          	jalr	1924(ra) # 800013fe <mycpu>
    80001c82:	00452903          	lw	s2,4(a0)
  swtch(&p->ctx, &mycpu()->context);  // 切换到调度器上下文
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	778080e7          	jalr	1912(ra) # 800013fe <mycpu>
    80001c8e:	01050593          	add	a1,a0,16
    80001c92:	05848513          	add	a0,s1,88
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	6aa080e7          	jalr	1706(ra) # 80002340 <swtch>
  mycpu()->intena = intena;
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	760080e7          	jalr	1888(ra) # 800013fe <mycpu>
    80001ca6:	01252223          	sw	s2,4(a0)
}
    80001caa:	60e2                	ld	ra,24(sp)
    80001cac:	6442                	ld	s0,16(sp)
    80001cae:	64a2                	ld	s1,8(sp)
    80001cb0:	6902                	ld	s2,0(sp)
    80001cb2:	6105                	add	sp,sp,32
    80001cb4:	8082                	ret
    panic("sched p->lock");
    80001cb6:	00002517          	auipc	a0,0x2
    80001cba:	73250513          	add	a0,a0,1842 # 800043e8 <digits+0x368>
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	aac080e7          	jalr	-1364(ra) # 8000076a <panic>
    panic("sched locks");
    80001cc6:	00002517          	auipc	a0,0x2
    80001cca:	73250513          	add	a0,a0,1842 # 800043f8 <digits+0x378>
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	a9c080e7          	jalr	-1380(ra) # 8000076a <panic>
    panic("sched running");
    80001cd6:	00002517          	auipc	a0,0x2
    80001cda:	73250513          	add	a0,a0,1842 # 80004408 <digits+0x388>
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	a8c080e7          	jalr	-1396(ra) # 8000076a <panic>
    panic("sched interruptible");
    80001ce6:	00002517          	auipc	a0,0x2
    80001cea:	73250513          	add	a0,a0,1842 # 80004418 <digits+0x398>
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	a7c080e7          	jalr	-1412(ra) # 8000076a <panic>

0000000080001cf6 <yield>:

// 用于进程放弃CPU, 重新进入调度
void
yield(void)
{
    80001cf6:	1101                	add	sp,sp,-32
    80001cf8:	ec06                	sd	ra,24(sp)
    80001cfa:	e822                	sd	s0,16(sp)
    80001cfc:	e426                	sd	s1,8(sp)
    80001cfe:	e04a                	sd	s2,0(sp)
    80001d00:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	718080e7          	jalr	1816(ra) # 8000141a <myproc>
    80001d0a:	84aa                	mv	s1,a0
  acquire(&p->lock);     // 获取进程锁
    80001d0c:	00850913          	add	s2,a0,8
    80001d10:	854a                	mv	a0,s2
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	c0e080e7          	jalr	-1010(ra) # 80001920 <acquire>
  p->state = RUNNABLE;   // 将进程状态设为可运行
    80001d1a:	478d                	li	a5,3
    80001d1c:	d09c                	sw	a5,32(s1)
  sched();               // 调用sched()切换到调度器
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	f1a080e7          	jalr	-230(ra) # 80001c38 <sched>
  release(&p->lock);     // 释放进程锁
    80001d26:	854a                	mv	a0,s2
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	cac080e7          	jalr	-852(ra) # 800019d4 <release>
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6902                	ld	s2,0(sp)
    80001d38:	6105                	add	sp,sp,32
    80001d3a:	8082                	ret

0000000080001d3c <trap_user_return>:
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
    80001d3c:	1141                	add	sp,sp,-16
    80001d3e:	e406                	sd	ra,8(sp)
    80001d40:	e022                	sd	s0,0(sp)
    80001d42:	0800                	add	s0,sp,16
  //printf("trap_user_return\n");
  struct proc *p = myproc();
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	6d6080e7          	jalr	1750(ra) # 8000141a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d4c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001d50:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001d52:	10079073          	csrw	sstatus,a5
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80001d56:	00001697          	auipc	a3,0x1
    80001d5a:	2aa68693          	add	a3,a3,682 # 80003000 <_trampoline>
    80001d5e:	00001717          	auipc	a4,0x1
    80001d62:	2a270713          	add	a4,a4,674 # 80003000 <_trampoline>
    80001d66:	8f15                	sub	a4,a4,a3
    80001d68:	040007b7          	lui	a5,0x4000
    80001d6c:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001d6e:	07b2                	sll	a5,a5,0xc
    80001d70:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001d72:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
    80001d76:	6138                	ld	a4,64(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80001d78:	18002673          	csrr	a2,satp
    80001d7c:	e310                	sd	a2,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
    80001d7e:	6130                	ld	a2,64(a0)
    80001d80:	6938                	ld	a4,80(a0)
    80001d82:	6585                	lui	a1,0x1
    80001d84:	972e                	add	a4,a4,a1
    80001d86:	e618                	sd	a4,8(a2)
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
    80001d88:	6138                	ld	a4,64(a0)
    80001d8a:	00000617          	auipc	a2,0x0
    80001d8e:	04860613          	add	a2,a2,72 # 80001dd2 <trap_user_handler>
    80001d92:	eb10                	sd	a2,16(a4)
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid
    80001d94:	6138                	ld	a4,64(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d96:	8612                	mv	a2,tp
    80001d98:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001d9a:	10002773          	csrr	a4,sstatus
  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
    80001d9e:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
    80001da2:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001da6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);
    80001daa:	6138                	ld	a4,64(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001dac:	6f18                	ld	a4,24(a4)
    80001dae:	14171073          	csrw	sepc,a4

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);
    80001db2:	7508                	ld	a0,40(a0)
    80001db4:	8131                	srl	a0,a0,0xc

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001db6:	00001717          	auipc	a4,0x1
    80001dba:	2e670713          	add	a4,a4,742 # 8000309c <userret>
    80001dbe:	8f15                	sub	a4,a4,a3
    80001dc0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001dc2:	577d                	li	a4,-1
    80001dc4:	177e                	sll	a4,a4,0x3f
    80001dc6:	8d59                	or	a0,a0,a4
    80001dc8:	9782                	jalr	a5
    80001dca:	60a2                	ld	ra,8(sp)
    80001dcc:	6402                	ld	s0,0(sp)
    80001dce:	0141                	add	sp,sp,16
    80001dd0:	8082                	ret

0000000080001dd2 <trap_user_handler>:
{
    80001dd2:	7139                	add	sp,sp,-64
    80001dd4:	fc06                	sd	ra,56(sp)
    80001dd6:	f822                	sd	s0,48(sp)
    80001dd8:	f426                	sd	s1,40(sp)
    80001dda:	f04a                	sd	s2,32(sp)
    80001ddc:	ec4e                	sd	s3,24(sp)
    80001dde:	e852                	sd	s4,16(sp)
    80001de0:	e456                	sd	s5,8(sp)
    80001de2:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001de4:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001de8:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001dec:	14202a73          	csrr	s4,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001df0:	14302af3          	csrr	s5,stval
    proc_t* p = myproc();
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	626080e7          	jalr	1574(ra) # 8000141a <myproc>
    if(sstatus & SSTATUS_SPP)
    80001dfc:	10097913          	and	s2,s2,256
    80001e00:	04091463          	bnez	s2,80001e48 <trap_user_handler+0x76>
    80001e04:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001e06:	00000797          	auipc	a5,0x0
    80001e0a:	5aa78793          	add	a5,a5,1450 # 800023b0 <kernelvec>
    80001e0e:	10579073          	csrw	stvec,a5
  p->tf->epc = sepc;
    80001e12:	613c                	ld	a5,64(a0)
    80001e14:	0137bc23          	sd	s3,24(a5)
  if(scause == 8){
    80001e18:	47a1                	li	a5,8
    80001e1a:	02fa0f63          	beq	s4,a5,80001e58 <trap_user_handler+0x86>
  } else if((which_dev = devintr()) != 0){
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	c3c080e7          	jalr	-964(ra) # 80001a5a <devintr>
    80001e26:	c921                	beqz	a0,80001e76 <trap_user_handler+0xa4>
  if(which_dev == 2)
    80001e28:	4789                	li	a5,2
    80001e2a:	08f50763          	beq	a0,a5,80001eb8 <trap_user_handler+0xe6>
  trap_user_return();
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	f0e080e7          	jalr	-242(ra) # 80001d3c <trap_user_return>
}
    80001e36:	70e2                	ld	ra,56(sp)
    80001e38:	7442                	ld	s0,48(sp)
    80001e3a:	74a2                	ld	s1,40(sp)
    80001e3c:	7902                	ld	s2,32(sp)
    80001e3e:	69e2                	ld	s3,24(sp)
    80001e40:	6a42                	ld	s4,16(sp)
    80001e42:	6aa2                	ld	s5,8(sp)
    80001e44:	6121                	add	sp,sp,64
    80001e46:	8082                	ret
        panic("trap_user_handler: not from u-mode");
    80001e48:	00002517          	auipc	a0,0x2
    80001e4c:	5e850513          	add	a0,a0,1512 # 80004430 <digits+0x3b0>
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	91a080e7          	jalr	-1766(ra) # 8000076a <panic>
    p->tf->epc += 4;
    80001e58:	6138                	ld	a4,64(a0)
    80001e5a:	6f1c                	ld	a5,24(a4)
    80001e5c:	0791                	add	a5,a5,4
    80001e5e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e64:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e68:	10079073          	csrw	sstatus,a5
    syscall();
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	0be080e7          	jalr	190(ra) # 80001f2a <syscall>
  if(which_dev == 2)
    80001e74:	bf6d                	j	80001e2e <trap_user_handler+0x5c>
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    80001e76:	4090                	lw	a2,0(s1)
    80001e78:	85d2                	mv	a1,s4
    80001e7a:	00002517          	auipc	a0,0x2
    80001e7e:	5de50513          	add	a0,a0,1502 # 80004458 <digits+0x3d8>
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	932080e7          	jalr	-1742(ra) # 800007b4 <printf>
    printf("            sepc=%p stval=%p\n", sepc, stval);
    80001e8a:	8656                	mv	a2,s5
    80001e8c:	85ce                	mv	a1,s3
    80001e8e:	00002517          	auipc	a0,0x2
    80001e92:	5fa50513          	add	a0,a0,1530 # 80004488 <digits+0x408>
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	91e080e7          	jalr	-1762(ra) # 800007b4 <printf>
    print_cur_pgtbl(p->pgtbl);
    80001e9e:	7488                	ld	a0,40(s1)
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	04e080e7          	jalr	78(ra) # 80000eee <print_cur_pgtbl>
    panic("usertrap");
    80001ea8:	00002517          	auipc	a0,0x2
    80001eac:	60050513          	add	a0,a0,1536 # 800044a8 <digits+0x428>
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	8ba080e7          	jalr	-1862(ra) # 8000076a <panic>
    yield();  // 让出 CPU，调度其他进程
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	e3e080e7          	jalr	-450(ra) # 80001cf6 <yield>
    80001ec0:	b7bd                	j	80001e2e <trap_user_handler+0x5c>

0000000080001ec2 <arg_raw>:
    第二种使用uvm_copyin 和 uvm_copyinstr 进行传递
*/

// 读取 n 号参数,它放在 an 寄存器中
static uint64 arg_raw(int n)
{   
    80001ec2:	1101                	add	sp,sp,-32
    80001ec4:	ec06                	sd	ra,24(sp)
    80001ec6:	e822                	sd	s0,16(sp)
    80001ec8:	e426                	sd	s1,8(sp)
    80001eca:	1000                	add	s0,sp,32
    80001ecc:	84aa                	mv	s1,a0
    proc_t* proc = myproc();
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	54c080e7          	jalr	1356(ra) # 8000141a <myproc>
    switch(n) {
    80001ed6:	4795                	li	a5,5
    80001ed8:	0497e163          	bltu	a5,s1,80001f1a <arg_raw+0x58>
    80001edc:	048a                	sll	s1,s1,0x2
    80001ede:	00002717          	auipc	a4,0x2
    80001ee2:	61a70713          	add	a4,a4,1562 # 800044f8 <digits+0x478>
    80001ee6:	94ba                	add	s1,s1,a4
    80001ee8:	409c                	lw	a5,0(s1)
    80001eea:	97ba                	add	a5,a5,a4
    80001eec:	8782                	jr	a5
        case 0:
            return proc->tf->a0;
    80001eee:	613c                	ld	a5,64(a0)
    80001ef0:	7ba8                	ld	a0,112(a5)
            return proc->tf->a5;
        default:
            panic("arg_raw: illegal arg num");
            return -1;
    }
}
    80001ef2:	60e2                	ld	ra,24(sp)
    80001ef4:	6442                	ld	s0,16(sp)
    80001ef6:	64a2                	ld	s1,8(sp)
    80001ef8:	6105                	add	sp,sp,32
    80001efa:	8082                	ret
            return proc->tf->a1;
    80001efc:	613c                	ld	a5,64(a0)
    80001efe:	7fa8                	ld	a0,120(a5)
    80001f00:	bfcd                	j	80001ef2 <arg_raw+0x30>
            return proc->tf->a2;
    80001f02:	613c                	ld	a5,64(a0)
    80001f04:	63c8                	ld	a0,128(a5)
    80001f06:	b7f5                	j	80001ef2 <arg_raw+0x30>
            return proc->tf->a3;
    80001f08:	613c                	ld	a5,64(a0)
    80001f0a:	67c8                	ld	a0,136(a5)
    80001f0c:	b7dd                	j	80001ef2 <arg_raw+0x30>
            return proc->tf->a4;
    80001f0e:	613c                	ld	a5,64(a0)
    80001f10:	6bc8                	ld	a0,144(a5)
    80001f12:	b7c5                	j	80001ef2 <arg_raw+0x30>
            return proc->tf->a5;
    80001f14:	613c                	ld	a5,64(a0)
    80001f16:	6fc8                	ld	a0,152(a5)
    80001f18:	bfe9                	j	80001ef2 <arg_raw+0x30>
            panic("arg_raw: illegal arg num");
    80001f1a:	00002517          	auipc	a0,0x2
    80001f1e:	59e50513          	add	a0,a0,1438 # 800044b8 <digits+0x438>
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	848080e7          	jalr	-1976(ra) # 8000076a <panic>

0000000080001f2a <syscall>:
{
    80001f2a:	1101                	add	sp,sp,-32
    80001f2c:	ec06                	sd	ra,24(sp)
    80001f2e:	e822                	sd	s0,16(sp)
    80001f30:	e426                	sd	s1,8(sp)
    80001f32:	e04a                	sd	s2,0(sp)
    80001f34:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	4e4080e7          	jalr	1252(ra) # 8000141a <myproc>
    80001f3e:	84aa                	mv	s1,a0
    num = p->tf->a7;
    80001f40:	04053903          	ld	s2,64(a0)
    80001f44:	0a893783          	ld	a5,168(s2)
    80001f48:	0007861b          	sext.w	a2,a5
    if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80001f4c:	37fd                	addw	a5,a5,-1
    80001f4e:	4759                	li	a4,22
    80001f50:	00f76f63          	bltu	a4,a5,80001f6e <syscall+0x44>
    80001f54:	00361713          	sll	a4,a2,0x3
    80001f58:	00002797          	auipc	a5,0x2
    80001f5c:	5b878793          	add	a5,a5,1464 # 80004510 <syscalls>
    80001f60:	97ba                	add	a5,a5,a4
    80001f62:	639c                	ld	a5,0(a5)
    80001f64:	c789                	beqz	a5,80001f6e <syscall+0x44>
        p->tf->a0 = syscalls[num]();
    80001f66:	9782                	jalr	a5
    80001f68:	06a93823          	sd	a0,112(s2)
    80001f6c:	a829                	j	80001f86 <syscall+0x5c>
        printf("pid %d: unknown sys call %d\n",
    80001f6e:	408c                	lw	a1,0(s1)
    80001f70:	00002517          	auipc	a0,0x2
    80001f74:	56850513          	add	a0,a0,1384 # 800044d8 <digits+0x458>
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	83c080e7          	jalr	-1988(ra) # 800007b4 <printf>
        p->tf->a0 = -1;
    80001f80:	60bc                	ld	a5,64(s1)
    80001f82:	577d                	li	a4,-1
    80001f84:	fbb8                	sd	a4,112(a5)
}
    80001f86:	60e2                	ld	ra,24(sp)
    80001f88:	6442                	ld	s0,16(sp)
    80001f8a:	64a2                	ld	s1,8(sp)
    80001f8c:	6902                	ld	s2,0(sp)
    80001f8e:	6105                	add	sp,sp,32
    80001f90:	8082                	ret

0000000080001f92 <arg_uint32>:

// 读取 n 号参数, 作为 uint32 存储
void arg_uint32(int n, uint32* ip)
{
    80001f92:	1101                	add	sp,sp,-32
    80001f94:	ec06                	sd	ra,24(sp)
    80001f96:	e822                	sd	s0,16(sp)
    80001f98:	e426                	sd	s1,8(sp)
    80001f9a:	1000                	add	s0,sp,32
    80001f9c:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	f24080e7          	jalr	-220(ra) # 80001ec2 <arg_raw>
    80001fa6:	c088                	sw	a0,0(s1)
}
    80001fa8:	60e2                	ld	ra,24(sp)
    80001faa:	6442                	ld	s0,16(sp)
    80001fac:	64a2                	ld	s1,8(sp)
    80001fae:	6105                	add	sp,sp,32
    80001fb0:	8082                	ret

0000000080001fb2 <arg_uint64>:

// 读取 n 号参数, 作为 uint64 存储
void arg_uint64(int n, uint64* ip)
{
    80001fb2:	1101                	add	sp,sp,-32
    80001fb4:	ec06                	sd	ra,24(sp)
    80001fb6:	e822                	sd	s0,16(sp)
    80001fb8:	e426                	sd	s1,8(sp)
    80001fba:	1000                	add	s0,sp,32
    80001fbc:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	f04080e7          	jalr	-252(ra) # 80001ec2 <arg_raw>
    80001fc6:	e088                	sd	a0,0(s1)
}
    80001fc8:	60e2                	ld	ra,24(sp)
    80001fca:	6442                	ld	s0,16(sp)
    80001fcc:	64a2                	ld	s1,8(sp)
    80001fce:	6105                	add	sp,sp,32
    80001fd0:	8082                	ret

0000000080001fd2 <arg_str>:

// 读取 n 号参数指向的字符串到 buf, 字符串最大长度是 maxlen
void arg_str(int n, char* buf, int maxlen)
{
    80001fd2:	7139                	add	sp,sp,-64
    80001fd4:	fc06                	sd	ra,56(sp)
    80001fd6:	f822                	sd	s0,48(sp)
    80001fd8:	f426                	sd	s1,40(sp)
    80001fda:	f04a                	sd	s2,32(sp)
    80001fdc:	ec4e                	sd	s3,24(sp)
    80001fde:	e852                	sd	s4,16(sp)
    80001fe0:	0080                	add	s0,sp,64
    80001fe2:	8a2a                	mv	s4,a0
    80001fe4:	892e                	mv	s2,a1
    80001fe6:	89b2                	mv	s3,a2
    proc_t* p = myproc();
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	432080e7          	jalr	1074(ra) # 8000141a <myproc>
    80001ff0:	84aa                	mv	s1,a0
    uint64 addr;
    arg_uint64(n, &addr);
    80001ff2:	fc840593          	add	a1,s0,-56
    80001ff6:	8552                	mv	a0,s4
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	fba080e7          	jalr	-70(ra) # 80001fb2 <arg_uint64>

    uvm_copyin_str(p->pgtbl, (uint64)buf, addr, maxlen);
    80002000:	86ce                	mv	a3,s3
    80002002:	fc843603          	ld	a2,-56(s0)
    80002006:	85ca                	mv	a1,s2
    80002008:	7488                	ld	a0,40(s1)
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	32c080e7          	jalr	812(ra) # 80001336 <uvm_copyin_str>
    80002012:	70e2                	ld	ra,56(sp)
    80002014:	7442                	ld	s0,48(sp)
    80002016:	74a2                	ld	s1,40(sp)
    80002018:	7902                	ld	s2,32(sp)
    8000201a:	69e2                	ld	s3,24(sp)
    8000201c:	6a42                	ld	s4,16(sp)
    8000201e:	6121                	add	sp,sp,64
    80002020:	8082                	ret

0000000080002022 <sys_brk>:

// 堆伸缩
// uint64 new_heap_top 新的堆顶 (如果是0代表查询, 返回旧的堆顶)
// 成功返回新的堆顶 失败返回-1
uint64 sys_brk()
{
    80002022:	7179                	add	sp,sp,-48
    80002024:	f406                	sd	ra,40(sp)
    80002026:	f022                	sd	s0,32(sp)
    80002028:	ec26                	sd	s1,24(sp)
    8000202a:	1800                	add	s0,sp,48
    uint64 new_addr;
    uint64 old_addr = myproc()->sz;  // 保存原始堆顶
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	3ee080e7          	jalr	1006(ra) # 8000141a <myproc>
    80002034:	6524                	ld	s1,72(a0)

    arg_uint64(0, &new_addr);  // 正确读取64位地址
    80002036:	fd840593          	add	a1,s0,-40
    8000203a:	4501                	li	a0,0
    8000203c:	00000097          	auipc	ra,0x0
    80002040:	f76080e7          	jalr	-138(ra) # 80001fb2 <arg_uint64>
    
    if(new_addr == old_addr) {
    80002044:	fd843783          	ld	a5,-40(s0)
    80002048:	00978863          	beq	a5,s1,80002058 <sys_brk+0x36>
        return old_addr;  // 无变化，返回当前堆顶
    }
    
    int diff = (int)(new_addr - old_addr);
    8000204c:	4097853b          	subw	a0,a5,s1
    
    // 检查是否溢出
    if((uint64)diff != (new_addr - old_addr)) {
    80002050:	8f85                	sub	a5,a5,s1
        return -1;  // 差值太大，int无法表示
    80002052:	54fd                	li	s1,-1
    if((uint64)diff != (new_addr - old_addr)) {
    80002054:	00f50863          	beq	a0,a5,80002064 <sys_brk+0x42>
    if(growproc(diff) < 0) {
        return -1;  // 扩展失败
    }
    
    return new_addr;  // 返回扩展前的地址
}
    80002058:	8526                	mv	a0,s1
    8000205a:	70a2                	ld	ra,40(sp)
    8000205c:	7402                	ld	s0,32(sp)
    8000205e:	64e2                	ld	s1,24(sp)
    80002060:	6145                	add	sp,sp,48
    80002062:	8082                	ret
    if(growproc(diff) < 0) {
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	7d0080e7          	jalr	2000(ra) # 80001834 <growproc>
    8000206c:	00054563          	bltz	a0,80002076 <sys_brk+0x54>
    return new_addr;  // 返回扩展前的地址
    80002070:	fd843483          	ld	s1,-40(s0)
    80002074:	b7d5                	j	80002058 <sys_brk+0x36>
        return -1;  // 扩展失败
    80002076:	54fd                	li	s1,-1
    80002078:	b7c5                	j	80002058 <sys_brk+0x36>

000000008000207a <sys_copyin>:
// copyin 测试 (int 数组)
// uint64 addr
// uint32 len
// 返回 0
uint64 sys_copyin()
{
    8000207a:	7139                	add	sp,sp,-64
    8000207c:	fc06                	sd	ra,56(sp)
    8000207e:	f822                	sd	s0,48(sp)
    80002080:	f426                	sd	s1,40(sp)
    80002082:	f04a                	sd	s2,32(sp)
    80002084:	ec4e                	sd	s3,24(sp)
    80002086:	0080                	add	s0,sp,64
    proc_t* p = myproc();
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	392080e7          	jalr	914(ra) # 8000141a <myproc>
    80002090:	892a                	mv	s2,a0
    uint64 addr;
    uint32 len;

    arg_uint64(0, &addr);
    80002092:	fc840593          	add	a1,s0,-56
    80002096:	4501                	li	a0,0
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	f1a080e7          	jalr	-230(ra) # 80001fb2 <arg_uint64>
    arg_uint32(1, &len);
    800020a0:	fc440593          	add	a1,s0,-60
    800020a4:	4505                	li	a0,1
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	eec080e7          	jalr	-276(ra) # 80001f92 <arg_uint32>

    int tmp;
    for(int i = 0; i < len; i++) {
    800020ae:	fc442783          	lw	a5,-60(s0)
    800020b2:	c3b1                	beqz	a5,800020f6 <sys_copyin+0x7c>
    800020b4:	4481                	li	s1,0
        uvm_copyin(p->pgtbl, (uint64)&tmp, addr + i * sizeof(int), sizeof(int));
        printf("get a number from user: %d\n", tmp);
    800020b6:	00002997          	auipc	s3,0x2
    800020ba:	51a98993          	add	s3,s3,1306 # 800045d0 <syscalls+0xc0>
        uvm_copyin(p->pgtbl, (uint64)&tmp, addr + i * sizeof(int), sizeof(int));
    800020be:	00249613          	sll	a2,s1,0x2
    800020c2:	4691                	li	a3,4
    800020c4:	fc843783          	ld	a5,-56(s0)
    800020c8:	963e                	add	a2,a2,a5
    800020ca:	fc040593          	add	a1,s0,-64
    800020ce:	02893503          	ld	a0,40(s2)
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	126080e7          	jalr	294(ra) # 800011f8 <uvm_copyin>
        printf("get a number from user: %d\n", tmp);
    800020da:	fc042583          	lw	a1,-64(s0)
    800020de:	854e                	mv	a0,s3
    800020e0:	ffffe097          	auipc	ra,0xffffe
    800020e4:	6d4080e7          	jalr	1748(ra) # 800007b4 <printf>
    for(int i = 0; i < len; i++) {
    800020e8:	0485                	add	s1,s1,1
    800020ea:	fc442703          	lw	a4,-60(s0)
    800020ee:	0004879b          	sext.w	a5,s1
    800020f2:	fce7e6e3          	bltu	a5,a4,800020be <sys_copyin+0x44>
    }

    return 0;
}
    800020f6:	4501                	li	a0,0
    800020f8:	70e2                	ld	ra,56(sp)
    800020fa:	7442                	ld	s0,48(sp)
    800020fc:	74a2                	ld	s1,40(sp)
    800020fe:	7902                	ld	s2,32(sp)
    80002100:	69e2                	ld	s3,24(sp)
    80002102:	6121                	add	sp,sp,64
    80002104:	8082                	ret

0000000080002106 <sys_copyout>:

// copyout 测试 (int 数组)
// uint64 addr
// 返回数组元素数量
uint64 sys_copyout()
{
    80002106:	7139                	add	sp,sp,-64
    80002108:	fc06                	sd	ra,56(sp)
    8000210a:	f822                	sd	s0,48(sp)
    8000210c:	f426                	sd	s1,40(sp)
    8000210e:	0080                	add	s0,sp,64
    int L[5] = {1, 2, 3, 4, 5};
    80002110:	00002797          	auipc	a5,0x2
    80002114:	50878793          	add	a5,a5,1288 # 80004618 <syscalls+0x108>
    80002118:	6398                	ld	a4,0(a5)
    8000211a:	fce43423          	sd	a4,-56(s0)
    8000211e:	6798                	ld	a4,8(a5)
    80002120:	fce43823          	sd	a4,-48(s0)
    80002124:	4b9c                	lw	a5,16(a5)
    80002126:	fcf42c23          	sw	a5,-40(s0)
    proc_t* p = myproc();
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	2f0080e7          	jalr	752(ra) # 8000141a <myproc>
    80002132:	84aa                	mv	s1,a0
    uint64 addr;

    arg_uint64(0, &addr);
    80002134:	fc040593          	add	a1,s0,-64
    80002138:	4501                	li	a0,0
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	e78080e7          	jalr	-392(ra) # 80001fb2 <arg_uint64>
    uvm_copyout(p->pgtbl, addr, (uint64)L, sizeof(int) * 5);
    80002142:	46d1                	li	a3,20
    80002144:	fc840613          	add	a2,s0,-56
    80002148:	fc043583          	ld	a1,-64(s0)
    8000214c:	7488                	ld	a0,40(s1)
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	14a080e7          	jalr	330(ra) # 80001298 <uvm_copyout>

    return 5;
}
    80002156:	4515                	li	a0,5
    80002158:	70e2                	ld	ra,56(sp)
    8000215a:	7442                	ld	s0,48(sp)
    8000215c:	74a2                	ld	s1,40(sp)
    8000215e:	6121                	add	sp,sp,64
    80002160:	8082                	ret

0000000080002162 <sys_copyinstr>:

// copyinstr测试
// uint64 addr
// 成功返回0
uint64 sys_copyinstr()
{
    80002162:	715d                	add	sp,sp,-80
    80002164:	e486                	sd	ra,72(sp)
    80002166:	e0a2                	sd	s0,64(sp)
    80002168:	0880                	add	s0,sp,80
    char s[64];

    arg_str(0, s, 64);
    8000216a:	04000613          	li	a2,64
    8000216e:	fb040593          	add	a1,s0,-80
    80002172:	4501                	li	a0,0
    80002174:	00000097          	auipc	ra,0x0
    80002178:	e5e080e7          	jalr	-418(ra) # 80001fd2 <arg_str>
    printf("get str from user: %s\n", s);
    8000217c:	fb040593          	add	a1,s0,-80
    80002180:	00002517          	auipc	a0,0x2
    80002184:	47050513          	add	a0,a0,1136 # 800045f0 <syscalls+0xe0>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	62c080e7          	jalr	1580(ra) # 800007b4 <printf>

    return 0;
}
    80002190:	4501                	li	a0,0
    80002192:	60a6                	ld	ra,72(sp)
    80002194:	6406                	ld	s0,64(sp)
    80002196:	6161                	add	sp,sp,80
    80002198:	8082                	ret

000000008000219a <sys_debug>:

uint64 sys_debug(void)
{
    8000219a:	7175                	add	sp,sp,-144
    8000219c:	e506                	sd	ra,136(sp)
    8000219e:	e122                	sd	s0,128(sp)
    800021a0:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    800021a2:	08000613          	li	a2,128
    800021a6:	f7040593          	add	a1,s0,-144
    800021aa:	4501                	li	a0,0
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	e26080e7          	jalr	-474(ra) # 80001fd2 <arg_str>

    printf("[debug] %s \n", buf);
    800021b4:	f7040593          	add	a1,s0,-144
    800021b8:	00002517          	auipc	a0,0x2
    800021bc:	45050513          	add	a0,a0,1104 # 80004608 <syscalls+0xf8>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	5f4080e7          	jalr	1524(ra) # 800007b4 <printf>
    return 0;
}
    800021c8:	4501                	li	a0,0
    800021ca:	60aa                	ld	ra,136(sp)
    800021cc:	640a                	ld	s0,128(sp)
    800021ce:	6149                	add	sp,sp,144
    800021d0:	8082                	ret

00000000800021d2 <initcode_start>:
    800021d2:	00000097          	.word	0x00000097
    800021d6:	0bc080e7          	.word	0x0bc080e7
    800021da:	0000a001          	.word	0x0000a001
    800021de:	ff010113          	.word	0xff010113
    800021e2:	00813423          	.word	0x00813423
    800021e6:	01010413          	.word	0x01010413
    800021ea:	00000313          	.word	0x00000313
    800021ee:	08054a63          	.word	0x08054a63
    800021f2:	00058693          	.word	0x00058693
    800021f6:	00058613          	.word	0x00058613
    800021fa:	00000793          	.word	0x00000793
    800021fe:	00a00813          	.word	0x00a00813
    80002202:	00078893          	.word	0x00078893
    80002206:	0017879b          	.word	0x0017879b
    8000220a:	0305673b          	.word	0x0305673b
    8000220e:	0307071b          	.word	0x0307071b
    80002212:	00e60023          	.word	0x00e60023
    80002216:	0305453b          	.word	0x0305453b
    8000221a:	00160613          	.word	0x00160613
    8000221e:	fe0512e3          	.word	0xfe0512e3
    80002222:	00030a63          	.word	0x00030a63
    80002226:	00f587b3          	.word	0x00f587b3
    8000222a:	02d00713          	.word	0x02d00713
    8000222e:	00e78023          	.word	0x00e78023
    80002232:	0028879b          	.word	0x0028879b
    80002236:	00f58733          	.word	0x00f58733
    8000223a:	00070023          	.word	0x00070023
    8000223e:	fff7871b          	.word	0xfff7871b
    80002242:	02e05a63          	.word	0x02e05a63
    80002246:	00e585b3          	.word	0x00e585b3
    8000224a:	fff7879b          	.word	0xfff7879b
    8000224e:	0006c703          	.word	0x0006c703
    80002252:	0005c603          	.word	0x0005c603
    80002256:	00c68023          	.word	0x00c68023
    8000225a:	00e58023          	.word	0x00e58023
    8000225e:	0015071b          	.word	0x0015071b
    80002262:	0007051b          	.word	0x0007051b
    80002266:	00168693          	.word	0x00168693
    8000226a:	fff58593          	.word	0xfff58593
    8000226e:	40e7873b          	.word	0x40e7873b
    80002272:	fce54ee3          	.word	0xfce54ee3
    80002276:	00813403          	.word	0x00813403
    8000227a:	01010113          	.word	0x01010113
    8000227e:	00008067          	.word	0x00008067
    80002282:	40a0053b          	.word	0x40a0053b
    80002286:	00100313          	.word	0x00100313
    8000228a:	f69ff06f          	.word	0xf69ff06f
    8000228e:	f6010113          	.word	0xf6010113
    80002292:	08113c23          	.word	0x08113c23
    80002296:	08813823          	.word	0x08813823
    8000229a:	08913423          	.word	0x08913423
    8000229e:	0a010413          	.word	0x0a010413
    800022a2:	00100893          	.word	0x00100893
    800022a6:	00001537          	.word	0x00001537
    800022aa:	00000073          	.word	0x00000073
    800022ae:	00050493          	.word	0x00050493
    800022b2:	f6040593          	.word	0xf6040593
    800022b6:	0005051b          	.word	0x0005051b
    800022ba:	00000097          	.word	0x00000097
    800022be:	f24080e7          	.word	0xf24080e7
    800022c2:	01700893          	.word	0x01700893
    800022c6:	f6040513          	.word	0xf6040513
    800022ca:	00000073          	.word	0x00000073
    800022ce:	00000517          	.word	0x00000517
    800022d2:	06c50513          	.word	0x06c50513
    800022d6:	00000073          	.word	0x00000073
    800022da:	00100893          	.word	0x00100893
    800022de:	0000a537          	.word	0x0000a537
    800022e2:	00a48533          	.word	0x00a48533
    800022e6:	00000073          	.word	0x00000073
    800022ea:	00050493          	.word	0x00050493
    800022ee:	f6040593          	.word	0xf6040593
    800022f2:	0005051b          	.word	0x0005051b
    800022f6:	00000097          	.word	0x00000097
    800022fa:	ee8080e7          	.word	0xee8080e7
    800022fe:	01700893          	.word	0x01700893
    80002302:	f6040513          	.word	0xf6040513
    80002306:	00000073          	.word	0x00000073
    8000230a:	00100893          	.word	0x00100893
    8000230e:	ffffb537          	.word	0xffffb537
    80002312:	00a48533          	.word	0x00a48533
    80002316:	00000073          	.word	0x00000073
    8000231a:	f6040593          	.word	0xf6040593
    8000231e:	0005051b          	.word	0x0005051b
    80002322:	00000097          	.word	0x00000097
    80002326:	ebc080e7          	.word	0xebc080e7
    8000232a:	01700893          	.word	0x01700893
    8000232e:	f6040513          	.word	0xf6040513
    80002332:	00000073          	.word	0x00000073
    80002336:	0000006f          	.word	0x0000006f
    8000233a:	68686868          	.word	0x68686868
	...

000000008000233f <initcode_end>:
	...

0000000080002340 <swtch>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    80002340:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    80002344:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    80002348:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    8000234a:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    8000234c:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    80002350:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    80002354:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    80002358:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    8000235c:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    80002360:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    80002364:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    80002368:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    8000236c:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    80002370:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    80002374:	0005b083          	ld	ra,0(a1) # 1000 <_entry-0x7ffff000>
        ld sp, 8(a1)      # 恢复栈指针
    80002378:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    8000237c:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    8000237e:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    80002380:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    80002384:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    80002388:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    8000238c:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    80002390:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    80002394:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    80002398:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    8000239c:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    800023a0:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    800023a4:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    800023a8:	8082                	ret
    800023aa:	0000                	unimp
    800023ac:	0000                	unimp
	...

00000000800023b0 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    800023b0:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    800023b2:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    800023b4:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    800023b6:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800023b8:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800023ba:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800023bc:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800023be:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    800023c0:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    800023c2:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    800023c4:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800023c6:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800023c8:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800023ca:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800023cc:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800023ce:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800023d0:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800023d2:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    800023d4:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    800023d6:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    800023d8:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    800023da:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    800023dc:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    800023de:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    800023e0:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    800023e2:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    800023e4:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    800023e6:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    800023e8:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800023ea:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800023ec:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800023ee:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	700080e7          	jalr	1792(ra) # 80001af0 <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    800023f8:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    800023fa:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    800023fc:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    800023fe:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80002400:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80002402:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    80002404:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    80002406:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    80002408:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    8000240a:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    8000240c:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000240e:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    80002410:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    80002412:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80002414:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80002416:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    80002418:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    8000241a:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    8000241c:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    8000241e:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    80002420:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    80002422:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    80002424:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    80002426:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    80002428:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    8000242a:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    8000242c:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    8000242e:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80002430:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80002432:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    80002434:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    80002436:	10200073          	sret
    8000243a:	0001                	nop
    8000243c:	00000013          	nop

0000000080002440 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    80002440:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    80002444:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    80002446:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    80002448:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    8000244a:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    8000244c:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    8000244e:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    80002450:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    80002452:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    80002454:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    80002456:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    8000245a:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    8000245c:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    8000245e:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80002460:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    80002464:	30200073          	mret
    80002468:	00000013          	nop
    8000246c:	00000013          	nop
	...

0000000080003000 <_trampoline>:
    80003000:	14051073          	csrw	sscratch,a0
    80003004:	02000537          	lui	a0,0x2000
    80003008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000300a:	0536                	sll	a0,a0,0xd
    8000300c:	02153423          	sd	ra,40(a0)
    80003010:	02253823          	sd	sp,48(a0)
    80003014:	02353c23          	sd	gp,56(a0)
    80003018:	04453023          	sd	tp,64(a0)
    8000301c:	04553423          	sd	t0,72(a0)
    80003020:	04653823          	sd	t1,80(a0)
    80003024:	04753c23          	sd	t2,88(a0)
    80003028:	f120                	sd	s0,96(a0)
    8000302a:	f524                	sd	s1,104(a0)
    8000302c:	fd2c                	sd	a1,120(a0)
    8000302e:	e150                	sd	a2,128(a0)
    80003030:	e554                	sd	a3,136(a0)
    80003032:	e958                	sd	a4,144(a0)
    80003034:	ed5c                	sd	a5,152(a0)
    80003036:	0b053023          	sd	a6,160(a0)
    8000303a:	0b153423          	sd	a7,168(a0)
    8000303e:	0b253823          	sd	s2,176(a0)
    80003042:	0b353c23          	sd	s3,184(a0)
    80003046:	0d453023          	sd	s4,192(a0)
    8000304a:	0d553423          	sd	s5,200(a0)
    8000304e:	0d653823          	sd	s6,208(a0)
    80003052:	0d753c23          	sd	s7,216(a0)
    80003056:	0f853023          	sd	s8,224(a0)
    8000305a:	0f953423          	sd	s9,232(a0)
    8000305e:	0fa53823          	sd	s10,240(a0)
    80003062:	0fb53c23          	sd	s11,248(a0)
    80003066:	11c53023          	sd	t3,256(a0)
    8000306a:	11d53423          	sd	t4,264(a0)
    8000306e:	11e53823          	sd	t5,272(a0)
    80003072:	11f53c23          	sd	t6,280(a0)
    80003076:	140022f3          	csrr	t0,sscratch
    8000307a:	06553823          	sd	t0,112(a0)
    8000307e:	00853103          	ld	sp,8(a0)
    80003082:	02053203          	ld	tp,32(a0)
    80003086:	01053283          	ld	t0,16(a0)
    8000308a:	00053303          	ld	t1,0(a0)
    8000308e:	12000073          	sfence.vma
    80003092:	18031073          	csrw	satp,t1
    80003096:	12000073          	sfence.vma
    8000309a:	9282                	jalr	t0

000000008000309c <userret>:
    8000309c:	12000073          	sfence.vma
    800030a0:	18051073          	csrw	satp,a0
    800030a4:	12000073          	sfence.vma
    800030a8:	02000537          	lui	a0,0x2000
    800030ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800030ae:	0536                	sll	a0,a0,0xd
    800030b0:	02853083          	ld	ra,40(a0)
    800030b4:	03053103          	ld	sp,48(a0)
    800030b8:	03853183          	ld	gp,56(a0)
    800030bc:	04053203          	ld	tp,64(a0)
    800030c0:	04853283          	ld	t0,72(a0)
    800030c4:	05053303          	ld	t1,80(a0)
    800030c8:	05853383          	ld	t2,88(a0)
    800030cc:	7120                	ld	s0,96(a0)
    800030ce:	7524                	ld	s1,104(a0)
    800030d0:	7d2c                	ld	a1,120(a0)
    800030d2:	6150                	ld	a2,128(a0)
    800030d4:	6554                	ld	a3,136(a0)
    800030d6:	6958                	ld	a4,144(a0)
    800030d8:	6d5c                	ld	a5,152(a0)
    800030da:	0a053803          	ld	a6,160(a0)
    800030de:	0a853883          	ld	a7,168(a0)
    800030e2:	0b053903          	ld	s2,176(a0)
    800030e6:	0b853983          	ld	s3,184(a0)
    800030ea:	0c053a03          	ld	s4,192(a0)
    800030ee:	0c853a83          	ld	s5,200(a0)
    800030f2:	0d053b03          	ld	s6,208(a0)
    800030f6:	0d853b83          	ld	s7,216(a0)
    800030fa:	0e053c03          	ld	s8,224(a0)
    800030fe:	0e853c83          	ld	s9,232(a0)
    80003102:	0f053d03          	ld	s10,240(a0)
    80003106:	0f853d83          	ld	s11,248(a0)
    8000310a:	10053e03          	ld	t3,256(a0)
    8000310e:	10853e83          	ld	t4,264(a0)
    80003112:	11053f03          	ld	t5,272(a0)
    80003116:	11853f83          	ld	t6,280(a0)
    8000311a:	7928                	ld	a0,112(a0)
    8000311c:	10200073          	sret
	...
