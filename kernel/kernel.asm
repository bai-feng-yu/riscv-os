
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.global _entry
_entry:
    # 为C语言代码设置栈空间
    # stack0声明在start.c中，每个CPU分配4096字节的栈空间
    # 计算公式: sp = stack0基地址 + (硬件线程ID * 4096)
    la sp, stack0        # 加载stack0的基地址到栈指针sp
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ed010113          	add	sp,sp,-304 # 80008ed0 <stack0>
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
    80000016:	00009517          	auipc	a0,0x9
    8000001a:	e6a50513          	add	a0,a0,-406 # 80008e80 <started>
    la a1, end
    8000001e:	00022597          	auipc	a1,0x22
    80000022:	32a58593          	add	a1,a1,810 # 80022348 <end>

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
    80000034:	132080e7          	jalr	306(ra) # 80000162 <start>

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
    80000042:	00002097          	auipc	ra,0x2
    80000046:	0a0080e7          	jalr	160(ra) # 800020e2 <cpuid>
    started = 1;         // 标记系统启动完成
    __sync_synchronize();

  } else {
    //其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000004a:	00009717          	auipc	a4,0x9
    8000004e:	e3670713          	add	a4,a4,-458 # 80008e80 <started>
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
    8000005e:	00002097          	auipc	ra,0x2
    80000062:	084080e7          	jalr	132(ra) # 800020e2 <cpuid>
    80000066:	85aa                	mv	a1,a0
    80000068:	00008517          	auipc	a0,0x8
    8000006c:	fb850513          	add	a0,a0,-72 # 80008020 <etext+0x20>
    80000070:	00001097          	auipc	ra,0x1
    80000074:	1ba080e7          	jalr	442(ra) # 8000122a <printf>
    kvminithart();       // 开启分页机制
    80000078:	00001097          	auipc	ra,0x1
    8000007c:	522080e7          	jalr	1314(ra) # 8000159a <kvminithart>
    trapinithart();   // 安装内核陷阱向量
    80000080:	00003097          	auipc	ra,0x3
    80000084:	f90080e7          	jalr	-112(ra) # 80003010 <trapinithart>
    plicinithart();   // 向PLIC请求设备中断
    80000088:	00001097          	auipc	ra,0x1
    8000008c:	940080e7          	jalr	-1728(ra) # 800009c8 <plicinithart>
  }
  // 所有CPU都进入调度器，开始调度用户进程
  scheduler(); 
    80000090:	00003097          	auipc	ra,0x3
    80000094:	124080e7          	jalr	292(ra) # 800031b4 <scheduler>
    initlock(&start_lock,"start_lock");
    80000098:	00008597          	auipc	a1,0x8
    8000009c:	f7858593          	add	a1,a1,-136 # 80008010 <etext+0x10>
    800000a0:	00009517          	auipc	a0,0x9
    800000a4:	e1050513          	add	a0,a0,-496 # 80008eb0 <start_lock>
    800000a8:	00003097          	auipc	ra,0x3
    800000ac:	db6080e7          	jalr	-586(ra) # 80002e5e <initlock>
    consoleinit();       // 初始化控制台
    800000b0:	00001097          	auipc	ra,0x1
    800000b4:	8b6080e7          	jalr	-1866(ra) # 80000966 <consoleinit>
    printfinit();        // 初始化printf功能
    800000b8:	00001097          	auipc	ra,0x1
    800000bc:	352080e7          	jalr	850(ra) # 8000140a <printfinit>
    printf("\n");
    800000c0:	00009517          	auipc	a0,0x9
    800000c4:	be850513          	add	a0,a0,-1048 # 80008ca8 <syscalls+0x540>
    800000c8:	00001097          	auipc	ra,0x1
    800000cc:	162080e7          	jalr	354(ra) # 8000122a <printf>
    printf("hart %d starting\n", cpuid());
    800000d0:	00002097          	auipc	ra,0x2
    800000d4:	012080e7          	jalr	18(ra) # 800020e2 <cpuid>
    800000d8:	85aa                	mv	a1,a0
    800000da:	00008517          	auipc	a0,0x8
    800000de:	f4650513          	add	a0,a0,-186 # 80008020 <etext+0x20>
    800000e2:	00001097          	auipc	ra,0x1
    800000e6:	148080e7          	jalr	328(ra) # 8000122a <printf>
    kinit();             // 物理页面分配器初始化
    800000ea:	00001097          	auipc	ra,0x1
    800000ee:	416080e7          	jalr	1046(ra) # 80001500 <kinit>
    kvminit();           // 创建内核页表
    800000f2:	00001097          	auipc	ra,0x1
    800000f6:	744080e7          	jalr	1860(ra) # 80001836 <kvminit>
    kvminithart();       // 开启分页机制
    800000fa:	00001097          	auipc	ra,0x1
    800000fe:	4a0080e7          	jalr	1184(ra) # 8000159a <kvminithart>
    procinit();       // 进程表初始化
    80000102:	00002097          	auipc	ra,0x2
    80000106:	16a080e7          	jalr	362(ra) # 8000226c <procinit>
    timer_create();      // 陷阱向量(时钟中断）初始化
    8000010a:	00000097          	auipc	ra,0x0
    8000010e:	13c080e7          	jalr	316(ra) # 80000246 <timer_create>
    trapinithart();      // 安装内核陷阱向量
    80000112:	00003097          	auipc	ra,0x3
    80000116:	efe080e7          	jalr	-258(ra) # 80003010 <trapinithart>
    plicinit();          // 设置中断控制器
    8000011a:	00001097          	auipc	ra,0x1
    8000011e:	898080e7          	jalr	-1896(ra) # 800009b2 <plicinit>
    plicinithart();      // 向PLIC请求设备中断
    80000122:	00001097          	auipc	ra,0x1
    80000126:	8a6080e7          	jalr	-1882(ra) # 800009c8 <plicinithart>
    binit();             // 缓冲区缓存初始化
    8000012a:	00005097          	auipc	ra,0x5
    8000012e:	fa0080e7          	jalr	-96(ra) # 800050ca <binit>
    iinit();             // inode表初始化
    80000132:	00004097          	auipc	ra,0x4
    80000136:	6a6080e7          	jalr	1702(ra) # 800047d8 <iinit>
    fileinit();          // 文件表初始化
    8000013a:	00006097          	auipc	ra,0x6
    8000013e:	89a080e7          	jalr	-1894(ra) # 800059d4 <fileinit>
    virtio_disk_init();  // 虚拟硬盘初始化
    80000142:	00001097          	auipc	ra,0x1
    80000146:	98e080e7          	jalr	-1650(ra) # 80000ad0 <virtio_disk_init>
    userinit();   // 创建第一个用户进程 userinit();   
    8000014a:	00002097          	auipc	ra,0x2
    8000014e:	41a080e7          	jalr	1050(ra) # 80002564 <userinit>
    started = 1;         // 标记系统启动完成
    80000152:	4785                	li	a5,1
    80000154:	00009717          	auipc	a4,0x9
    80000158:	d2f72623          	sw	a5,-724(a4) # 80008e80 <started>
    __sync_synchronize();
    8000015c:	0ff0000f          	fence
    80000160:	bf05                	j	80000090 <main+0x56>

0000000080000162 <start>:
extern void main();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];


void start() {
    80000162:	1141                	add	sp,sp,-16
    80000164:	e406                	sd	ra,8(sp)
    80000166:	e022                	sd	s0,0(sp)
    80000168:	0800                	add	s0,sp,16

static inline uint64
r_mstatus()
{
  uint64 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000016a:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    8000016e:	7779                	lui	a4,0xffffe
    80000170:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc4b7>
    80000174:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    80000176:	6705                	lui	a4,0x1
    80000178:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000017c:	8fd9                	or	a5,a5,a4
}

static inline void 
w_mstatus(uint64 x)
{
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000017e:	30079073          	csrw	mstatus,a5
// instruction address to which a return from
// exception will go.
static inline void 
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000182:	00000797          	auipc	a5,0x0
    80000186:	eb878793          	add	a5,a5,-328 # 8000003a <main>
    8000018a:	34179073          	csrw	mepc,a5
// supervisor address translation and protection;
// holds the address of the page table.
static inline void 
w_satp(uint64 x)
{
  asm volatile("csrw satp, %0" : : "r" (x));
    8000018e:	4781                	li	a5,0
    80000190:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000194:	67c1                	lui	a5,0x10
    80000196:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000198:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000019c:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800001a0:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800001a4:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800001a8:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800001ac:	57fd                	li	a5,-1
    800001ae:	83a9                	srl	a5,a5,0xa
    800001b0:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800001b4:	47bd                	li	a5,15
    800001b6:	3a079073          	csrw	pmpcfg0,a5
  w_pmpaddr0(0x3fffffffffffffull);  // 设置PMP地址范围
  w_pmpcfg0(0xf);                   // 设置PMP配置(读写执行权限)

  
  // 请求时钟中断服务
  timer_init();
    800001ba:	00000097          	auipc	ra,0x0
    800001be:	01c080e7          	jalr	28(ra) # 800001d6 <timer_init>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800001c2:	f14027f3          	csrr	a5,mhartid

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    800001c6:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800001c8:	823e                	mv	tp,a5


  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    800001ca:	30200073          	mret
}
    800001ce:	60a2                	ld	ra,8(sp)
    800001d0:	6402                	ld	s0,0(sp)
    800001d2:	0141                	add	sp,sp,16
    800001d4:	8082                	ret

00000000800001d6 <timer_init>:
// 完成以下设置来接收M-Mode下的时钟中断
// 时钟中断会进入到kernelvec.S中的timervec
// 在这之后会将它们转化为软中断进而被trap.c中的devintr接管
void
timer_init()
{
    800001d6:	1141                	add	sp,sp,-16
    800001d8:	e422                	sd	s0,8(sp)
    800001da:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800001dc:	f14027f3          	csrr	a5,mhartid
  // 每个CPU都有独立的定时器中断源
  int id = r_mhartid();
    800001e0:	0007859b          	sext.w	a1,a5

  // 向CLINT(核心本地中断控制器)请求定时器中断
  int interval = 1000000; // 周期数；在QEMU中大约是1/10秒
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    800001e4:	0037979b          	sllw	a5,a5,0x3
    800001e8:	02004737          	lui	a4,0x2004
    800001ec:	97ba                	add	a5,a5,a4
    800001ee:	0200c737          	lui	a4,0x200c
    800001f2:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    800001f6:	000f4637          	lui	a2,0xf4
    800001fa:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    800001fe:	9732                	add	a4,a4,a2
    80000200:	e398                	sd	a4,0(a5)

  // 在scratch[]中为timervec准备信息
  // scratch[0..2] : timervec保存寄存器的空间
  // scratch[3] : CLINT MTIMECMP寄存器地址
  // scratch[4] : 定时器中断之间期望的间隔(周期数)
  uint64 *scratch = &timer_scratch[id][0];
    80000202:	00259693          	sll	a3,a1,0x2
    80000206:	96ae                	add	a3,a3,a1
    80000208:	068e                	sll	a3,a3,0x3
    8000020a:	00011717          	auipc	a4,0x11
    8000020e:	cc670713          	add	a4,a4,-826 # 80010ed0 <timer_scratch>
    80000212:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    80000214:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000216:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000218:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000021c:	00007797          	auipc	a5,0x7
    80000220:	ce478793          	add	a5,a5,-796 # 80006f00 <timervec>
    80000224:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000228:	300027f3          	csrr	a5,mstatus

  // 设置机器模式的陷阱处理程序
  w_mtvec((uint64)timervec);

  // 启用机器模式中断
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000022c:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000230:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000234:	304027f3          	csrr	a5,mie

  // 启用机器模式定时器中断
  w_mie(r_mie() | MIE_MTIE);
    80000238:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000023c:	30479073          	csrw	mie,a5
}
    80000240:	6422                	ld	s0,8(sp)
    80000242:	0141                	add	sp,sp,16
    80000244:	8082                	ret

0000000080000246 <timer_create>:
timer_t sys_timer;

// 时钟创建(初始化系统时钟)
// 陷阱初始化函数
void timer_create()
{
    80000246:	1141                	add	sp,sp,-16
    80000248:	e406                	sd	ra,8(sp)
    8000024a:	e022                	sd	s0,0(sp)
    8000024c:	0800                	add	s0,sp,16
    initlock(&sys_timer.lk, "sys_timer");
    8000024e:	00008597          	auipc	a1,0x8
    80000252:	dea58593          	add	a1,a1,-534 # 80008038 <etext+0x38>
    80000256:	00011517          	auipc	a0,0x11
    8000025a:	dc250513          	add	a0,a0,-574 # 80011018 <sys_timer+0x8>
    8000025e:	00003097          	auipc	ra,0x3
    80000262:	c00080e7          	jalr	-1024(ra) # 80002e5e <initlock>
    sys_timer.ticks = 0;
    80000266:	00011797          	auipc	a5,0x11
    8000026a:	da07b523          	sd	zero,-598(a5) # 80011010 <sys_timer>
}
    8000026e:	60a2                	ld	ra,8(sp)
    80000270:	6402                	ld	s0,0(sp)
    80000272:	0141                	add	sp,sp,16
    80000274:	8082                	ret

0000000080000276 <timer_update>:

// 时钟更新(ticks++ with lock)
void timer_update()
{
    80000276:	1101                	add	sp,sp,-32
    80000278:	ec06                	sd	ra,24(sp)
    8000027a:	e822                	sd	s0,16(sp)
    8000027c:	e426                	sd	s1,8(sp)
    8000027e:	e04a                	sd	s2,0(sp)
    80000280:	1000                	add	s0,sp,32
    acquire(&sys_timer.lk);
    80000282:	00011917          	auipc	s2,0x11
    80000286:	c4e90913          	add	s2,s2,-946 # 80010ed0 <timer_scratch>
    8000028a:	00011497          	auipc	s1,0x11
    8000028e:	d8e48493          	add	s1,s1,-626 # 80011018 <sys_timer+0x8>
    80000292:	8526                	mv	a0,s1
    80000294:	00003097          	auipc	ra,0x3
    80000298:	c5a080e7          	jalr	-934(ra) # 80002eee <acquire>
    sys_timer.ticks++;
    8000029c:	14093783          	ld	a5,320(s2)
    800002a0:	0785                	add	a5,a5,1
    800002a2:	14f93023          	sd	a5,320(s2)
    // printf("ticks: %d\n", sys_timer.ticks);
    release(&sys_timer.lk);
    800002a6:	8526                	mv	a0,s1
    800002a8:	00003097          	auipc	ra,0x3
    800002ac:	cfa080e7          	jalr	-774(ra) # 80002fa2 <release>
}
    800002b0:	60e2                	ld	ra,24(sp)
    800002b2:	6442                	ld	s0,16(sp)
    800002b4:	64a2                	ld	s1,8(sp)
    800002b6:	6902                	ld	s2,0(sp)
    800002b8:	6105                	add	sp,sp,32
    800002ba:	8082                	ret

00000000800002bc <timer_get_ticks>:

// 返回系统时钟ticks
uint64 timer_get_ticks()
{
    800002bc:	1101                	add	sp,sp,-32
    800002be:	ec06                	sd	ra,24(sp)
    800002c0:	e822                	sd	s0,16(sp)
    800002c2:	e426                	sd	s1,8(sp)
    800002c4:	e04a                	sd	s2,0(sp)
    800002c6:	1000                	add	s0,sp,32
    uint64 xticks;
    acquire(&sys_timer.lk);
    800002c8:	00011497          	auipc	s1,0x11
    800002cc:	d5048493          	add	s1,s1,-688 # 80011018 <sys_timer+0x8>
    800002d0:	8526                	mv	a0,s1
    800002d2:	00003097          	auipc	ra,0x3
    800002d6:	c1c080e7          	jalr	-996(ra) # 80002eee <acquire>
    xticks = sys_timer.ticks;
    800002da:	00011917          	auipc	s2,0x11
    800002de:	d3693903          	ld	s2,-714(s2) # 80011010 <sys_timer>
    release(&sys_timer.lk);
    800002e2:	8526                	mv	a0,s1
    800002e4:	00003097          	auipc	ra,0x3
    800002e8:	cbe080e7          	jalr	-834(ra) # 80002fa2 <release>
    return xticks;
    800002ec:	854a                	mv	a0,s2
    800002ee:	60e2                	ld	ra,24(sp)
    800002f0:	6442                	ld	s0,16(sp)
    800002f2:	64a2                	ld	s1,8(sp)
    800002f4:	6902                	ld	s2,0(sp)
    800002f6:	6105                	add	sp,sp,32
    800002f8:	8082                	ret

00000000800002fa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800002fa:	1141                	add	sp,sp,-16
    800002fc:	e406                	sd	ra,8(sp)
    800002fe:	e022                	sd	s0,0(sp)
    80000300:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000302:	100007b7          	lui	a5,0x10000
    80000306:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000030a:	f8000713          	li	a4,-128
    8000030e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000312:	470d                	li	a4,3
    80000314:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000318:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000031c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000320:	469d                	li	a3,7
    80000322:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000326:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000032a:	00008597          	auipc	a1,0x8
    8000032e:	d1e58593          	add	a1,a1,-738 # 80008048 <etext+0x48>
    80000332:	00011517          	auipc	a0,0x11
    80000336:	cfe50513          	add	a0,a0,-770 # 80011030 <uart_tx_lock>
    8000033a:	00003097          	auipc	ra,0x3
    8000033e:	b24080e7          	jalr	-1244(ra) # 80002e5e <initlock>
}
    80000342:	60a2                	ld	ra,8(sp)
    80000344:	6402                	ld	s0,0(sp)
    80000346:	0141                	add	sp,sp,16
    80000348:	8082                	ret

000000008000034a <uartputc_sync>:
// 不使用中断的uartputc的替换版本
// 用于内核printf和回显字符
// 它会持续等待uart的输出寄存器为空(同步性、阻塞性)
void
uartputc_sync(int c)
{
    8000034a:	1101                	add	sp,sp,-32
    8000034c:	ec06                	sd	ra,24(sp)
    8000034e:	e822                	sd	s0,16(sp)
    80000350:	e426                	sd	s1,8(sp)
    80000352:	1000                	add	s0,sp,32
    80000354:	84aa                	mv	s1,a0
  // 关中断，防止串口中断再次进入造成竞争
  push_off();
    80000356:	00003097          	auipc	ra,0x3
    8000035a:	b4c080e7          	jalr	-1204(ra) # 80002ea2 <push_off>
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    8000035e:	00009797          	auipc	a5,0x9
    80000362:	b3a7a783          	lw	a5,-1222(a5) # 80008e98 <panicked>
    for(;;)
      ;
  }

  // 等待LSR中的发送寄存器为空标识被置位
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000366:	10000737          	lui	a4,0x10000
  if(panicked){
    8000036a:	c391                	beqz	a5,8000036e <uartputc_sync+0x24>
    for(;;)
    8000036c:	a001                	j	8000036c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000036e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000372:	0207f793          	and	a5,a5,32
    80000376:	dfe5                	beqz	a5,8000036e <uartputc_sync+0x24>
    ;
  
  // 立即通过UART发送字符
  WriteReg(THR, c);
    80000378:	0ff4f513          	zext.b	a0,s1
    8000037c:	100007b7          	lui	a5,0x10000
    80000380:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
  
  // 恢复之前的中断状态
  pop_off();
    80000384:	00003097          	auipc	ra,0x3
    80000388:	bbe080e7          	jalr	-1090(ra) # 80002f42 <pop_off>
}
    8000038c:	60e2                	ld	ra,24(sp)
    8000038e:	6442                	ld	s0,16(sp)
    80000390:	64a2                	ld	s1,8(sp)
    80000392:	6105                	add	sp,sp,32
    80000394:	8082                	ret

0000000080000396 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000396:	00009797          	auipc	a5,0x9
    8000039a:	af27b783          	ld	a5,-1294(a5) # 80008e88 <uart_tx_r>
    8000039e:	00009717          	auipc	a4,0x9
    800003a2:	af273703          	ld	a4,-1294(a4) # 80008e90 <uart_tx_w>
    800003a6:	06f70a63          	beq	a4,a5,8000041a <uartstart+0x84>
{
    800003aa:	7139                	add	sp,sp,-64
    800003ac:	fc06                	sd	ra,56(sp)
    800003ae:	f822                	sd	s0,48(sp)
    800003b0:	f426                	sd	s1,40(sp)
    800003b2:	f04a                	sd	s2,32(sp)
    800003b4:	ec4e                	sd	s3,24(sp)
    800003b6:	e852                	sd	s4,16(sp)
    800003b8:	e456                	sd	s5,8(sp)
    800003ba:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800003bc:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800003c0:	00011a17          	auipc	s4,0x11
    800003c4:	c70a0a13          	add	s4,s4,-912 # 80011030 <uart_tx_lock>
    uart_tx_r += 1;
    800003c8:	00009497          	auipc	s1,0x9
    800003cc:	ac048493          	add	s1,s1,-1344 # 80008e88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800003d0:	00009997          	auipc	s3,0x9
    800003d4:	ac098993          	add	s3,s3,-1344 # 80008e90 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800003d8:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800003dc:	02077713          	and	a4,a4,32
    800003e0:	c705                	beqz	a4,80000408 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800003e2:	01f7f713          	and	a4,a5,31
    800003e6:	9752                	add	a4,a4,s4
    800003e8:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    800003ec:	0785                	add	a5,a5,1
    800003ee:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800003f0:	8526                	mv	a0,s1
    800003f2:	00002097          	auipc	ra,0x2
    800003f6:	4b8080e7          	jalr	1208(ra) # 800028aa <wakeup>
    
    WriteReg(THR, c);
    800003fa:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800003fe:	609c                	ld	a5,0(s1)
    80000400:	0009b703          	ld	a4,0(s3)
    80000404:	fcf71ae3          	bne	a4,a5,800003d8 <uartstart+0x42>
  }
}
    80000408:	70e2                	ld	ra,56(sp)
    8000040a:	7442                	ld	s0,48(sp)
    8000040c:	74a2                	ld	s1,40(sp)
    8000040e:	7902                	ld	s2,32(sp)
    80000410:	69e2                	ld	s3,24(sp)
    80000412:	6a42                	ld	s4,16(sp)
    80000414:	6aa2                	ld	s5,8(sp)
    80000416:	6121                	add	sp,sp,64
    80000418:	8082                	ret
    8000041a:	8082                	ret

000000008000041c <uartputc>:
{
    8000041c:	7179                	add	sp,sp,-48
    8000041e:	f406                	sd	ra,40(sp)
    80000420:	f022                	sd	s0,32(sp)
    80000422:	ec26                	sd	s1,24(sp)
    80000424:	e84a                	sd	s2,16(sp)
    80000426:	e44e                	sd	s3,8(sp)
    80000428:	e052                	sd	s4,0(sp)
    8000042a:	1800                	add	s0,sp,48
    8000042c:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    8000042e:	00011517          	auipc	a0,0x11
    80000432:	c0250513          	add	a0,a0,-1022 # 80011030 <uart_tx_lock>
    80000436:	00003097          	auipc	ra,0x3
    8000043a:	ab8080e7          	jalr	-1352(ra) # 80002eee <acquire>
  if(panicked){
    8000043e:	00009797          	auipc	a5,0x9
    80000442:	a5a7a783          	lw	a5,-1446(a5) # 80008e98 <panicked>
    80000446:	e7c9                	bnez	a5,800004d0 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000448:	00009717          	auipc	a4,0x9
    8000044c:	a4873703          	ld	a4,-1464(a4) # 80008e90 <uart_tx_w>
    80000450:	00009797          	auipc	a5,0x9
    80000454:	a387b783          	ld	a5,-1480(a5) # 80008e88 <uart_tx_r>
    80000458:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000045c:	00011997          	auipc	s3,0x11
    80000460:	bd498993          	add	s3,s3,-1068 # 80011030 <uart_tx_lock>
    80000464:	00009497          	auipc	s1,0x9
    80000468:	a2448493          	add	s1,s1,-1500 # 80008e88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000046c:	00009917          	auipc	s2,0x9
    80000470:	a2490913          	add	s2,s2,-1500 # 80008e90 <uart_tx_w>
    80000474:	00e79f63          	bne	a5,a4,80000492 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000478:	85ce                	mv	a1,s3
    8000047a:	8526                	mv	a0,s1
    8000047c:	00002097          	auipc	ra,0x2
    80000480:	3c0080e7          	jalr	960(ra) # 8000283c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000484:	00093703          	ld	a4,0(s2)
    80000488:	609c                	ld	a5,0(s1)
    8000048a:	02078793          	add	a5,a5,32
    8000048e:	fee785e3          	beq	a5,a4,80000478 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000492:	00011497          	auipc	s1,0x11
    80000496:	b9e48493          	add	s1,s1,-1122 # 80011030 <uart_tx_lock>
    8000049a:	01f77793          	and	a5,a4,31
    8000049e:	97a6                	add	a5,a5,s1
    800004a0:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800004a4:	0705                	add	a4,a4,1
    800004a6:	00009797          	auipc	a5,0x9
    800004aa:	9ee7b523          	sd	a4,-1558(a5) # 80008e90 <uart_tx_w>
  uartstart();
    800004ae:	00000097          	auipc	ra,0x0
    800004b2:	ee8080e7          	jalr	-280(ra) # 80000396 <uartstart>
  release(&uart_tx_lock);
    800004b6:	8526                	mv	a0,s1
    800004b8:	00003097          	auipc	ra,0x3
    800004bc:	aea080e7          	jalr	-1302(ra) # 80002fa2 <release>
}
    800004c0:	70a2                	ld	ra,40(sp)
    800004c2:	7402                	ld	s0,32(sp)
    800004c4:	64e2                	ld	s1,24(sp)
    800004c6:	6942                	ld	s2,16(sp)
    800004c8:	69a2                	ld	s3,8(sp)
    800004ca:	6a02                	ld	s4,0(sp)
    800004cc:	6145                	add	sp,sp,48
    800004ce:	8082                	ret
    for(;;)
    800004d0:	a001                	j	800004d0 <uartputc+0xb4>

00000000800004d2 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800004d2:	1141                	add	sp,sp,-16
    800004d4:	e422                	sd	s0,8(sp)
    800004d6:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800004d8:	100007b7          	lui	a5,0x10000
    800004dc:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800004e0:	8b85                	and	a5,a5,1
    800004e2:	cb81                	beqz	a5,800004f2 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800004e4:	100007b7          	lui	a5,0x10000
    800004e8:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800004ec:	6422                	ld	s0,8(sp)
    800004ee:	0141                	add	sp,sp,16
    800004f0:	8082                	ret
    return -1;
    800004f2:	557d                	li	a0,-1
    800004f4:	bfe5                	j	800004ec <uartgetc+0x1a>

00000000800004f6 <uartintr>:
// 注意两种情况下会触发此函数：
// 1.输入通道RX为满(即键盘有数据输入)
// 2.输出通道TX为空
void
uartintr(void)
{
    800004f6:	1101                	add	sp,sp,-32
    800004f8:	ec06                	sd	ra,24(sp)
    800004fa:	e822                	sd	s0,16(sp)
    800004fc:	e426                	sd	s1,8(sp)
    800004fe:	1000                	add	s0,sp,32
  // release(&uart_tx_lock);
  
  while(1)
  {
    int c = uartgetc();
    if(c == -1) break;
    80000500:	54fd                	li	s1,-1
    80000502:	a029                	j	8000050c <uartintr+0x16>
    consputc(c);
    80000504:	00000097          	auipc	ra,0x0
    80000508:	1e4080e7          	jalr	484(ra) # 800006e8 <consputc>
    int c = uartgetc();
    8000050c:	00000097          	auipc	ra,0x0
    80000510:	fc6080e7          	jalr	-58(ra) # 800004d2 <uartgetc>
    if(c == -1) break;
    80000514:	fe9518e3          	bne	a0,s1,80000504 <uartintr+0xe>
  }
}
    80000518:	60e2                	ld	ra,24(sp)
    8000051a:	6442                	ld	s0,16(sp)
    8000051c:	64a2                	ld	s1,8(sp)
    8000051e:	6105                	add	sp,sp,32
    80000520:	8082                	ret

0000000080000522 <uart_putc>:


void uart_putc(char c) {
    80000522:	1141                	add	sp,sp,-16
    80000524:	e422                	sd	s0,8(sp)
    80000526:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    80000528:	10000737          	lui	a4,0x10000
    8000052c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000530:	0207f793          	and	a5,a5,32
    80000534:	dfe5                	beqz	a5,8000052c <uart_putc+0xa>
    uart[0] = c;
    80000536:	100007b7          	lui	a5,0x10000
    8000053a:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    8000053e:	6422                	ld	s0,8(sp)
    80000540:	0141                	add	sp,sp,16
    80000542:	8082                	ret

0000000080000544 <uart_puts>:

void uart_puts(char *s) {
    80000544:	1101                	add	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	add	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000550:	00054503          	lbu	a0,0(a0)
    80000554:	c909                	beqz	a0,80000566 <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	fcc080e7          	jalr	-52(ra) # 80000522 <uart_putc>
        s++;              // 移动到下一个字符
    8000055e:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000560:	0004c503          	lbu	a0,0(s1)
    80000564:	f96d                	bnez	a0,80000556 <uart_puts+0x12>
    }
}
    80000566:	60e2                	ld	ra,24(sp)
    80000568:	6442                	ld	s0,16(sp)
    8000056a:	64a2                	ld	s1,8(sp)
    8000056c:	6105                	add	sp,sp,32
    8000056e:	8082                	ret

0000000080000570 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000570:	715d                	add	sp,sp,-80
    80000572:	e486                	sd	ra,72(sp)
    80000574:	e0a2                	sd	s0,64(sp)
    80000576:	fc26                	sd	s1,56(sp)
    80000578:	f84a                	sd	s2,48(sp)
    8000057a:	f44e                	sd	s3,40(sp)
    8000057c:	f052                	sd	s4,32(sp)
    8000057e:	ec56                	sd	s5,24(sp)
    80000580:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000582:	04c05763          	blez	a2,800005d0 <consolewrite+0x60>
    80000586:	8a2a                	mv	s4,a0
    80000588:	84ae                	mv	s1,a1
    8000058a:	89b2                	mv	s3,a2
    8000058c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000058e:	5afd                	li	s5,-1
    80000590:	4685                	li	a3,1
    80000592:	8626                	mv	a2,s1
    80000594:	85d2                	mv	a1,s4
    80000596:	fbf40513          	add	a0,s0,-65
    8000059a:	00002097          	auipc	ra,0x2
    8000059e:	744080e7          	jalr	1860(ra) # 80002cde <either_copyin>
    800005a2:	01550d63          	beq	a0,s5,800005bc <consolewrite+0x4c>
      break;
    uartputc(c);
    800005a6:	fbf44503          	lbu	a0,-65(s0)
    800005aa:	00000097          	auipc	ra,0x0
    800005ae:	e72080e7          	jalr	-398(ra) # 8000041c <uartputc>
  for(i = 0; i < n; i++){
    800005b2:	2905                	addw	s2,s2,1
    800005b4:	0485                	add	s1,s1,1
    800005b6:	fd299de3          	bne	s3,s2,80000590 <consolewrite+0x20>
    800005ba:	894e                	mv	s2,s3
  }

  return i;
}
    800005bc:	854a                	mv	a0,s2
    800005be:	60a6                	ld	ra,72(sp)
    800005c0:	6406                	ld	s0,64(sp)
    800005c2:	74e2                	ld	s1,56(sp)
    800005c4:	7942                	ld	s2,48(sp)
    800005c6:	79a2                	ld	s3,40(sp)
    800005c8:	7a02                	ld	s4,32(sp)
    800005ca:	6ae2                	ld	s5,24(sp)
    800005cc:	6161                	add	sp,sp,80
    800005ce:	8082                	ret
  for(i = 0; i < n; i++){
    800005d0:	4901                	li	s2,0
    800005d2:	b7ed                	j	800005bc <consolewrite+0x4c>

00000000800005d4 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    800005d4:	711d                	add	sp,sp,-96
    800005d6:	ec86                	sd	ra,88(sp)
    800005d8:	e8a2                	sd	s0,80(sp)
    800005da:	e4a6                	sd	s1,72(sp)
    800005dc:	e0ca                	sd	s2,64(sp)
    800005de:	fc4e                	sd	s3,56(sp)
    800005e0:	f852                	sd	s4,48(sp)
    800005e2:	f456                	sd	s5,40(sp)
    800005e4:	f05a                	sd	s6,32(sp)
    800005e6:	ec5e                	sd	s7,24(sp)
    800005e8:	1080                	add	s0,sp,96
    800005ea:	8aaa                	mv	s5,a0
    800005ec:	8a2e                	mv	s4,a1
    800005ee:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    800005f0:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    800005f4:	00011517          	auipc	a0,0x11
    800005f8:	a7450513          	add	a0,a0,-1420 # 80011068 <cons>
    800005fc:	00003097          	auipc	ra,0x3
    80000600:	8f2080e7          	jalr	-1806(ra) # 80002eee <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000604:	00011497          	auipc	s1,0x11
    80000608:	a6448493          	add	s1,s1,-1436 # 80011068 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000060c:	00011917          	auipc	s2,0x11
    80000610:	af490913          	add	s2,s2,-1292 # 80011100 <cons+0x98>
  while(n > 0){
    80000614:	09305263          	blez	s3,80000698 <consoleread+0xc4>
    while(cons.r == cons.w){
    80000618:	0984a783          	lw	a5,152(s1)
    8000061c:	09c4a703          	lw	a4,156(s1)
    80000620:	02f71763          	bne	a4,a5,8000064e <consoleread+0x7a>
      if(killed(myproc())){
    80000624:	00002097          	auipc	ra,0x2
    80000628:	aea080e7          	jalr	-1302(ra) # 8000210e <myproc>
    8000062c:	00002097          	auipc	ra,0x2
    80000630:	3ac080e7          	jalr	940(ra) # 800029d8 <killed>
    80000634:	ed2d                	bnez	a0,800006ae <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    80000636:	85a6                	mv	a1,s1
    80000638:	854a                	mv	a0,s2
    8000063a:	00002097          	auipc	ra,0x2
    8000063e:	202080e7          	jalr	514(ra) # 8000283c <sleep>
    while(cons.r == cons.w){
    80000642:	0984a783          	lw	a5,152(s1)
    80000646:	09c4a703          	lw	a4,156(s1)
    8000064a:	fcf70de3          	beq	a4,a5,80000624 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    8000064e:	00011717          	auipc	a4,0x11
    80000652:	a1a70713          	add	a4,a4,-1510 # 80011068 <cons>
    80000656:	0017869b          	addw	a3,a5,1
    8000065a:	08d72c23          	sw	a3,152(a4)
    8000065e:	07f7f693          	and	a3,a5,127
    80000662:	9736                	add	a4,a4,a3
    80000664:	01874703          	lbu	a4,24(a4)
    80000668:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    8000066c:	4691                	li	a3,4
    8000066e:	06db8463          	beq	s7,a3,800006d6 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000672:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000676:	4685                	li	a3,1
    80000678:	faf40613          	add	a2,s0,-81
    8000067c:	85d2                	mv	a1,s4
    8000067e:	8556                	mv	a0,s5
    80000680:	00002097          	auipc	ra,0x2
    80000684:	608080e7          	jalr	1544(ra) # 80002c88 <either_copyout>
    80000688:	57fd                	li	a5,-1
    8000068a:	00f50763          	beq	a0,a5,80000698 <consoleread+0xc4>
      break;

    dst++;
    8000068e:	0a05                	add	s4,s4,1
    --n;
    80000690:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000692:	47a9                	li	a5,10
    80000694:	f8fb90e3          	bne	s7,a5,80000614 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000698:	00011517          	auipc	a0,0x11
    8000069c:	9d050513          	add	a0,a0,-1584 # 80011068 <cons>
    800006a0:	00003097          	auipc	ra,0x3
    800006a4:	902080e7          	jalr	-1790(ra) # 80002fa2 <release>

  return target - n;
    800006a8:	413b053b          	subw	a0,s6,s3
    800006ac:	a811                	j	800006c0 <consoleread+0xec>
        release(&cons.lock);
    800006ae:	00011517          	auipc	a0,0x11
    800006b2:	9ba50513          	add	a0,a0,-1606 # 80011068 <cons>
    800006b6:	00003097          	auipc	ra,0x3
    800006ba:	8ec080e7          	jalr	-1812(ra) # 80002fa2 <release>
        return -1;
    800006be:	557d                	li	a0,-1
}
    800006c0:	60e6                	ld	ra,88(sp)
    800006c2:	6446                	ld	s0,80(sp)
    800006c4:	64a6                	ld	s1,72(sp)
    800006c6:	6906                	ld	s2,64(sp)
    800006c8:	79e2                	ld	s3,56(sp)
    800006ca:	7a42                	ld	s4,48(sp)
    800006cc:	7aa2                	ld	s5,40(sp)
    800006ce:	7b02                	ld	s6,32(sp)
    800006d0:	6be2                	ld	s7,24(sp)
    800006d2:	6125                	add	sp,sp,96
    800006d4:	8082                	ret
      if(n < target){
    800006d6:	0009871b          	sext.w	a4,s3
    800006da:	fb677fe3          	bgeu	a4,s6,80000698 <consoleread+0xc4>
        cons.r--;
    800006de:	00011717          	auipc	a4,0x11
    800006e2:	a2f72123          	sw	a5,-1502(a4) # 80011100 <cons+0x98>
    800006e6:	bf4d                	j	80000698 <consoleread+0xc4>

00000000800006e8 <consputc>:
{
    800006e8:	1141                	add	sp,sp,-16
    800006ea:	e406                	sd	ra,8(sp)
    800006ec:	e022                	sd	s0,0(sp)
    800006ee:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    800006f0:	07f00793          	li	a5,127
    800006f4:	00f50a63          	beq	a0,a5,80000708 <consputc+0x20>
    uartputc_sync(c);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	c52080e7          	jalr	-942(ra) # 8000034a <uartputc_sync>
}
    80000700:	60a2                	ld	ra,8(sp)
    80000702:	6402                	ld	s0,0(sp)
    80000704:	0141                	add	sp,sp,16
    80000706:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000708:	4521                	li	a0,8
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	c40080e7          	jalr	-960(ra) # 8000034a <uartputc_sync>
    80000712:	02000513          	li	a0,32
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	c34080e7          	jalr	-972(ra) # 8000034a <uartputc_sync>
    8000071e:	4521                	li	a0,8
    80000720:	00000097          	auipc	ra,0x0
    80000724:	c2a080e7          	jalr	-982(ra) # 8000034a <uartputc_sync>
    80000728:	bfe1                	j	80000700 <consputc+0x18>

000000008000072a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000072a:	715d                	add	sp,sp,-80
    8000072c:	e486                	sd	ra,72(sp)
    8000072e:	e0a2                	sd	s0,64(sp)
    80000730:	fc26                	sd	s1,56(sp)
    80000732:	f84a                	sd	s2,48(sp)
    80000734:	f44e                	sd	s3,40(sp)
    80000736:	f052                	sd	s4,32(sp)
    80000738:	ec56                	sd	s5,24(sp)
    8000073a:	e85a                	sd	s6,16(sp)
    8000073c:	e45e                	sd	s7,8(sp)
    8000073e:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80000740:	00008517          	auipc	a0,0x8
    80000744:	56850513          	add	a0,a0,1384 # 80008ca8 <syscalls+0x540>
    80000748:	00001097          	auipc	ra,0x1
    8000074c:	ae2080e7          	jalr	-1310(ra) # 8000122a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80000750:	00011497          	auipc	s1,0x11
    80000754:	f5848493          	add	s1,s1,-168 # 800116a8 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80000758:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000075a:	00008997          	auipc	s3,0x8
    8000075e:	8f698993          	add	s3,s3,-1802 # 80008050 <etext+0x50>
    // printf("%d %s %s", p->pid, state, p->name);
    printf("%d %s", p->pid, state);
    80000762:	00008a97          	auipc	s5,0x8
    80000766:	8f6a8a93          	add	s5,s5,-1802 # 80008058 <etext+0x58>
    printf("\n");
    8000076a:	00008a17          	auipc	s4,0x8
    8000076e:	53ea0a13          	add	s4,s4,1342 # 80008ca8 <syscalls+0x540>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80000772:	00008b97          	auipc	s7,0x8
    80000776:	926b8b93          	add	s7,s7,-1754 # 80008098 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    8000077a:	00017917          	auipc	s2,0x17
    8000077e:	92e90913          	add	s2,s2,-1746 # 800170a8 <wait_lock>
    80000782:	a005                	j	800007a2 <procdump+0x78>
    printf("%d %s", p->pid, state);
    80000784:	408c                	lw	a1,0(s1)
    80000786:	8556                	mv	a0,s5
    80000788:	00001097          	auipc	ra,0x1
    8000078c:	aa2080e7          	jalr	-1374(ra) # 8000122a <printf>
    printf("\n");
    80000790:	8552                	mv	a0,s4
    80000792:	00001097          	auipc	ra,0x1
    80000796:	a98080e7          	jalr	-1384(ra) # 8000122a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000079a:	16848493          	add	s1,s1,360
    8000079e:	03248063          	beq	s1,s2,800007be <procdump+0x94>
    if(p->state == UNUSED)
    800007a2:	509c                	lw	a5,32(s1)
    800007a4:	dbfd                	beqz	a5,8000079a <procdump+0x70>
      state = "???";
    800007a6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800007a8:	fcfb6ee3          	bltu	s6,a5,80000784 <procdump+0x5a>
    800007ac:	02079713          	sll	a4,a5,0x20
    800007b0:	01d75793          	srl	a5,a4,0x1d
    800007b4:	97de                	add	a5,a5,s7
    800007b6:	6390                	ld	a2,0(a5)
    800007b8:	f671                	bnez	a2,80000784 <procdump+0x5a>
      state = "???";
    800007ba:	864e                	mv	a2,s3
    800007bc:	b7e1                	j	80000784 <procdump+0x5a>
  }
}
    800007be:	60a6                	ld	ra,72(sp)
    800007c0:	6406                	ld	s0,64(sp)
    800007c2:	74e2                	ld	s1,56(sp)
    800007c4:	7942                	ld	s2,48(sp)
    800007c6:	79a2                	ld	s3,40(sp)
    800007c8:	7a02                	ld	s4,32(sp)
    800007ca:	6ae2                	ld	s5,24(sp)
    800007cc:	6b42                	ld	s6,16(sp)
    800007ce:	6ba2                	ld	s7,8(sp)
    800007d0:	6161                	add	sp,sp,80
    800007d2:	8082                	ret

00000000800007d4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800007d4:	1101                	add	sp,sp,-32
    800007d6:	ec06                	sd	ra,24(sp)
    800007d8:	e822                	sd	s0,16(sp)
    800007da:	e426                	sd	s1,8(sp)
    800007dc:	e04a                	sd	s2,0(sp)
    800007de:	1000                	add	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	88650513          	add	a0,a0,-1914 # 80011068 <cons>
    800007ea:	00002097          	auipc	ra,0x2
    800007ee:	704080e7          	jalr	1796(ra) # 80002eee <acquire>

  switch(c){
    800007f2:	47d5                	li	a5,21
    800007f4:	0af48663          	beq	s1,a5,800008a0 <consoleintr+0xcc>
    800007f8:	0297ca63          	blt	a5,s1,8000082c <consoleintr+0x58>
    800007fc:	47a1                	li	a5,8
    800007fe:	0ef48763          	beq	s1,a5,800008ec <consoleintr+0x118>
    80000802:	47c1                	li	a5,16
    80000804:	10f49a63          	bne	s1,a5,80000918 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000808:	00000097          	auipc	ra,0x0
    8000080c:	f22080e7          	jalr	-222(ra) # 8000072a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000810:	00011517          	auipc	a0,0x11
    80000814:	85850513          	add	a0,a0,-1960 # 80011068 <cons>
    80000818:	00002097          	auipc	ra,0x2
    8000081c:	78a080e7          	jalr	1930(ra) # 80002fa2 <release>
}
    80000820:	60e2                	ld	ra,24(sp)
    80000822:	6442                	ld	s0,16(sp)
    80000824:	64a2                	ld	s1,8(sp)
    80000826:	6902                	ld	s2,0(sp)
    80000828:	6105                	add	sp,sp,32
    8000082a:	8082                	ret
  switch(c){
    8000082c:	07f00793          	li	a5,127
    80000830:	0af48e63          	beq	s1,a5,800008ec <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000834:	00011717          	auipc	a4,0x11
    80000838:	83470713          	add	a4,a4,-1996 # 80011068 <cons>
    8000083c:	0a072783          	lw	a5,160(a4)
    80000840:	09872703          	lw	a4,152(a4)
    80000844:	9f99                	subw	a5,a5,a4
    80000846:	07f00713          	li	a4,127
    8000084a:	fcf763e3          	bltu	a4,a5,80000810 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000084e:	47b5                	li	a5,13
    80000850:	0cf48763          	beq	s1,a5,8000091e <consoleintr+0x14a>
      consputc(c);
    80000854:	8526                	mv	a0,s1
    80000856:	00000097          	auipc	ra,0x0
    8000085a:	e92080e7          	jalr	-366(ra) # 800006e8 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000085e:	00011797          	auipc	a5,0x11
    80000862:	80a78793          	add	a5,a5,-2038 # 80011068 <cons>
    80000866:	0a07a683          	lw	a3,160(a5)
    8000086a:	0016871b          	addw	a4,a3,1
    8000086e:	0007061b          	sext.w	a2,a4
    80000872:	0ae7a023          	sw	a4,160(a5)
    80000876:	07f6f693          	and	a3,a3,127
    8000087a:	97b6                	add	a5,a5,a3
    8000087c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000880:	47a9                	li	a5,10
    80000882:	0cf48563          	beq	s1,a5,8000094c <consoleintr+0x178>
    80000886:	4791                	li	a5,4
    80000888:	0cf48263          	beq	s1,a5,8000094c <consoleintr+0x178>
    8000088c:	00011797          	auipc	a5,0x11
    80000890:	8747a783          	lw	a5,-1932(a5) # 80011100 <cons+0x98>
    80000894:	9f1d                	subw	a4,a4,a5
    80000896:	08000793          	li	a5,128
    8000089a:	f6f71be3          	bne	a4,a5,80000810 <consoleintr+0x3c>
    8000089e:	a07d                	j	8000094c <consoleintr+0x178>
    while(cons.e != cons.w &&
    800008a0:	00010717          	auipc	a4,0x10
    800008a4:	7c870713          	add	a4,a4,1992 # 80011068 <cons>
    800008a8:	0a072783          	lw	a5,160(a4)
    800008ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800008b0:	00010497          	auipc	s1,0x10
    800008b4:	7b848493          	add	s1,s1,1976 # 80011068 <cons>
    while(cons.e != cons.w &&
    800008b8:	4929                	li	s2,10
    800008ba:	f4f70be3          	beq	a4,a5,80000810 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800008be:	37fd                	addw	a5,a5,-1
    800008c0:	07f7f713          	and	a4,a5,127
    800008c4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800008c6:	01874703          	lbu	a4,24(a4)
    800008ca:	f52703e3          	beq	a4,s2,80000810 <consoleintr+0x3c>
      cons.e--;
    800008ce:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800008d2:	07f00513          	li	a0,127
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	e12080e7          	jalr	-494(ra) # 800006e8 <consputc>
    while(cons.e != cons.w &&
    800008de:	0a04a783          	lw	a5,160(s1)
    800008e2:	09c4a703          	lw	a4,156(s1)
    800008e6:	fcf71ce3          	bne	a4,a5,800008be <consoleintr+0xea>
    800008ea:	b71d                	j	80000810 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800008ec:	00010717          	auipc	a4,0x10
    800008f0:	77c70713          	add	a4,a4,1916 # 80011068 <cons>
    800008f4:	0a072783          	lw	a5,160(a4)
    800008f8:	09c72703          	lw	a4,156(a4)
    800008fc:	f0f70ae3          	beq	a4,a5,80000810 <consoleintr+0x3c>
      cons.e--;
    80000900:	37fd                	addw	a5,a5,-1
    80000902:	00011717          	auipc	a4,0x11
    80000906:	80f72323          	sw	a5,-2042(a4) # 80011108 <cons+0xa0>
      consputc(BACKSPACE);
    8000090a:	07f00513          	li	a0,127
    8000090e:	00000097          	auipc	ra,0x0
    80000912:	dda080e7          	jalr	-550(ra) # 800006e8 <consputc>
    80000916:	bded                	j	80000810 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000918:	ee048ce3          	beqz	s1,80000810 <consoleintr+0x3c>
    8000091c:	bf21                	j	80000834 <consoleintr+0x60>
      consputc(c);
    8000091e:	4529                	li	a0,10
    80000920:	00000097          	auipc	ra,0x0
    80000924:	dc8080e7          	jalr	-568(ra) # 800006e8 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000928:	00010797          	auipc	a5,0x10
    8000092c:	74078793          	add	a5,a5,1856 # 80011068 <cons>
    80000930:	0a07a703          	lw	a4,160(a5)
    80000934:	0017069b          	addw	a3,a4,1
    80000938:	0006861b          	sext.w	a2,a3
    8000093c:	0ad7a023          	sw	a3,160(a5)
    80000940:	07f77713          	and	a4,a4,127
    80000944:	97ba                	add	a5,a5,a4
    80000946:	4729                	li	a4,10
    80000948:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000094c:	00010797          	auipc	a5,0x10
    80000950:	7ac7ac23          	sw	a2,1976(a5) # 80011104 <cons+0x9c>
        wakeup(&cons.r);
    80000954:	00010517          	auipc	a0,0x10
    80000958:	7ac50513          	add	a0,a0,1964 # 80011100 <cons+0x98>
    8000095c:	00002097          	auipc	ra,0x2
    80000960:	f4e080e7          	jalr	-178(ra) # 800028aa <wakeup>
    80000964:	b575                	j	80000810 <consoleintr+0x3c>

0000000080000966 <consoleinit>:

void
consoleinit(void)
{
    80000966:	1141                	add	sp,sp,-16
    80000968:	e406                	sd	ra,8(sp)
    8000096a:	e022                	sd	s0,0(sp)
    8000096c:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    8000096e:	00007597          	auipc	a1,0x7
    80000972:	6f258593          	add	a1,a1,1778 # 80008060 <etext+0x60>
    80000976:	00010517          	auipc	a0,0x10
    8000097a:	6f250513          	add	a0,a0,1778 # 80011068 <cons>
    8000097e:	00002097          	auipc	ra,0x2
    80000982:	4e0080e7          	jalr	1248(ra) # 80002e5e <initlock>

  uartinit();
    80000986:	00000097          	auipc	ra,0x0
    8000098a:	974080e7          	jalr	-1676(ra) # 800002fa <uartinit>

  devsw[CONSOLE].read = consoleread;
    8000098e:	00021797          	auipc	a5,0x21
    80000992:	94278793          	add	a5,a5,-1726 # 800212d0 <devsw>
    80000996:	00000717          	auipc	a4,0x0
    8000099a:	c3e70713          	add	a4,a4,-962 # 800005d4 <consoleread>
    8000099e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800009a0:	00000717          	auipc	a4,0x0
    800009a4:	bd070713          	add	a4,a4,-1072 # 80000570 <consolewrite>
    800009a8:	ef98                	sd	a4,24(a5)
}
    800009aa:	60a2                	ld	ra,8(sp)
    800009ac:	6402                	ld	s0,0(sp)
    800009ae:	0141                	add	sp,sp,16
    800009b0:	8082                	ret

00000000800009b2 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800009b2:	1141                	add	sp,sp,-16
    800009b4:	e422                	sd	s0,8(sp)
    800009b6:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800009b8:	0c0007b7          	lui	a5,0xc000
    800009bc:	4705                	li	a4,1
    800009be:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800009c0:	c3d8                	sw	a4,4(a5)
}
    800009c2:	6422                	ld	s0,8(sp)
    800009c4:	0141                	add	sp,sp,16
    800009c6:	8082                	ret

00000000800009c8 <plicinithart>:

void
plicinithart(void)
{
    800009c8:	1141                	add	sp,sp,-16
    800009ca:	e406                	sd	ra,8(sp)
    800009cc:	e022                	sd	s0,0(sp)
    800009ce:	0800                	add	s0,sp,16
  int hart = cpuid();
    800009d0:	00001097          	auipc	ra,0x1
    800009d4:	712080e7          	jalr	1810(ra) # 800020e2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800009d8:	0085171b          	sllw	a4,a0,0x8
    800009dc:	0c0027b7          	lui	a5,0xc002
    800009e0:	97ba                	add	a5,a5,a4
    800009e2:	40200713          	li	a4,1026
    800009e6:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800009ea:	00d5151b          	sllw	a0,a0,0xd
    800009ee:	0c2017b7          	lui	a5,0xc201
    800009f2:	97aa                	add	a5,a5,a0
    800009f4:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800009f8:	60a2                	ld	ra,8(sp)
    800009fa:	6402                	ld	s0,0(sp)
    800009fc:	0141                	add	sp,sp,16
    800009fe:	8082                	ret

0000000080000a00 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80000a00:	1141                	add	sp,sp,-16
    80000a02:	e406                	sd	ra,8(sp)
    80000a04:	e022                	sd	s0,0(sp)
    80000a06:	0800                	add	s0,sp,16
  int hart = cpuid();
    80000a08:	00001097          	auipc	ra,0x1
    80000a0c:	6da080e7          	jalr	1754(ra) # 800020e2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80000a10:	00d5151b          	sllw	a0,a0,0xd
    80000a14:	0c2017b7          	lui	a5,0xc201
    80000a18:	97aa                	add	a5,a5,a0
  return irq;
}
    80000a1a:	43c8                	lw	a0,4(a5)
    80000a1c:	60a2                	ld	ra,8(sp)
    80000a1e:	6402                	ld	s0,0(sp)
    80000a20:	0141                	add	sp,sp,16
    80000a22:	8082                	ret

0000000080000a24 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80000a24:	1101                	add	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	1000                	add	s0,sp,32
    80000a2e:	84aa                	mv	s1,a0
  int hart = cpuid();
    80000a30:	00001097          	auipc	ra,0x1
    80000a34:	6b2080e7          	jalr	1714(ra) # 800020e2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80000a38:	00d5151b          	sllw	a0,a0,0xd
    80000a3c:	0c2017b7          	lui	a5,0xc201
    80000a40:	97aa                	add	a5,a5,a0
    80000a42:	c3c4                	sw	s1,4(a5)
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6105                	add	sp,sp,32
    80000a4c:	8082                	ret

0000000080000a4e <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80000a4e:	1141                	add	sp,sp,-16
    80000a50:	e406                	sd	ra,8(sp)
    80000a52:	e022                	sd	s0,0(sp)
    80000a54:	0800                	add	s0,sp,16
  if(i >= NUM)
    80000a56:	479d                	li	a5,7
    80000a58:	04a7cc63          	blt	a5,a0,80000ab0 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80000a5c:	00010797          	auipc	a5,0x10
    80000a60:	6b478793          	add	a5,a5,1716 # 80011110 <disk>
    80000a64:	97aa                	add	a5,a5,a0
    80000a66:	0187c783          	lbu	a5,24(a5)
    80000a6a:	ebb9                	bnez	a5,80000ac0 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80000a6c:	00451693          	sll	a3,a0,0x4
    80000a70:	00010797          	auipc	a5,0x10
    80000a74:	6a078793          	add	a5,a5,1696 # 80011110 <disk>
    80000a78:	6398                	ld	a4,0(a5)
    80000a7a:	9736                	add	a4,a4,a3
    80000a7c:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80000a80:	6398                	ld	a4,0(a5)
    80000a82:	9736                	add	a4,a4,a3
    80000a84:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80000a88:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80000a8c:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80000a90:	97aa                	add	a5,a5,a0
    80000a92:	4705                	li	a4,1
    80000a94:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80000a98:	00010517          	auipc	a0,0x10
    80000a9c:	69050513          	add	a0,a0,1680 # 80011128 <disk+0x18>
    80000aa0:	00002097          	auipc	ra,0x2
    80000aa4:	e0a080e7          	jalr	-502(ra) # 800028aa <wakeup>
}
    80000aa8:	60a2                	ld	ra,8(sp)
    80000aaa:	6402                	ld	s0,0(sp)
    80000aac:	0141                	add	sp,sp,16
    80000aae:	8082                	ret
    panic("free_desc 1");
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	61850513          	add	a0,a0,1560 # 800080c8 <states.0+0x30>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	728080e7          	jalr	1832(ra) # 800011e0 <panic>
    panic("free_desc 2");
    80000ac0:	00007517          	auipc	a0,0x7
    80000ac4:	61850513          	add	a0,a0,1560 # 800080d8 <states.0+0x40>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	718080e7          	jalr	1816(ra) # 800011e0 <panic>

0000000080000ad0 <virtio_disk_init>:
{
    80000ad0:	1101                	add	sp,sp,-32
    80000ad2:	ec06                	sd	ra,24(sp)
    80000ad4:	e822                	sd	s0,16(sp)
    80000ad6:	e426                	sd	s1,8(sp)
    80000ad8:	e04a                	sd	s2,0(sp)
    80000ada:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80000adc:	00007597          	auipc	a1,0x7
    80000ae0:	60c58593          	add	a1,a1,1548 # 800080e8 <states.0+0x50>
    80000ae4:	00010517          	auipc	a0,0x10
    80000ae8:	75450513          	add	a0,a0,1876 # 80011238 <disk+0x128>
    80000aec:	00002097          	auipc	ra,0x2
    80000af0:	372080e7          	jalr	882(ra) # 80002e5e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80000af4:	100017b7          	lui	a5,0x10001
    80000af8:	4398                	lw	a4,0(a5)
    80000afa:	2701                	sext.w	a4,a4
    80000afc:	747277b7          	lui	a5,0x74727
    80000b00:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80000b04:	14f71863          	bne	a4,a5,80000c54 <virtio_disk_init+0x184>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80000b08:	100017b7          	lui	a5,0x10001
    80000b0c:	479c                	lw	a5,8(a5)
    80000b0e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80000b10:	4709                	li	a4,2
    80000b12:	14e79163          	bne	a5,a4,80000c54 <virtio_disk_init+0x184>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80000b16:	100017b7          	lui	a5,0x10001
    80000b1a:	47d8                	lw	a4,12(a5)
    80000b1c:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80000b1e:	554d47b7          	lui	a5,0x554d4
    80000b22:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80000b26:	12f71763          	bne	a4,a5,80000c54 <virtio_disk_init+0x184>
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b2a:	100017b7          	lui	a5,0x10001
    80000b2e:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b32:	4705                	li	a4,1
    80000b34:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b36:	470d                	li	a4,3
    80000b38:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80000b3a:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80000b3c:	c7ffe6b7          	lui	a3,0xc7ffe
    80000b40:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc417>
    80000b44:	8f75                	and	a4,a4,a3
    80000b46:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b48:	472d                	li	a4,11
    80000b4a:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80000b4c:	5bbc                	lw	a5,112(a5)
    80000b4e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80000b52:	8ba1                	and	a5,a5,8
    80000b54:	10078863          	beqz	a5,80000c64 <virtio_disk_init+0x194>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80000b58:	100017b7          	lui	a5,0x10001
    80000b5c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80000b60:	43fc                	lw	a5,68(a5)
    80000b62:	2781                	sext.w	a5,a5
    80000b64:	10079863          	bnez	a5,80000c74 <virtio_disk_init+0x1a4>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80000b68:	100017b7          	lui	a5,0x10001
    80000b6c:	5bdc                	lw	a5,52(a5)
    80000b6e:	2781                	sext.w	a5,a5
  if(max == 0)
    80000b70:	10078a63          	beqz	a5,80000c84 <virtio_disk_init+0x1b4>
  if(max < NUM)
    80000b74:	471d                	li	a4,7
    80000b76:	10f77f63          	bgeu	a4,a5,80000c94 <virtio_disk_init+0x1c4>
  disk.desc = kalloc(1);
    80000b7a:	4505                	li	a0,1
    80000b7c:	00001097          	auipc	ra,0x1
    80000b80:	9c0080e7          	jalr	-1600(ra) # 8000153c <kalloc>
    80000b84:	00010497          	auipc	s1,0x10
    80000b88:	58c48493          	add	s1,s1,1420 # 80011110 <disk>
    80000b8c:	e088                	sd	a0,0(s1)
  disk.avail = kalloc(1);
    80000b8e:	4505                	li	a0,1
    80000b90:	00001097          	auipc	ra,0x1
    80000b94:	9ac080e7          	jalr	-1620(ra) # 8000153c <kalloc>
    80000b98:	e488                	sd	a0,8(s1)
  disk.used = kalloc(1);
    80000b9a:	4505                	li	a0,1
    80000b9c:	00001097          	auipc	ra,0x1
    80000ba0:	9a0080e7          	jalr	-1632(ra) # 8000153c <kalloc>
    80000ba4:	87aa                	mv	a5,a0
    80000ba6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80000ba8:	6088                	ld	a0,0(s1)
    80000baa:	cd6d                	beqz	a0,80000ca4 <virtio_disk_init+0x1d4>
    80000bac:	00010717          	auipc	a4,0x10
    80000bb0:	56c73703          	ld	a4,1388(a4) # 80011118 <disk+0x8>
    80000bb4:	cb65                	beqz	a4,80000ca4 <virtio_disk_init+0x1d4>
    80000bb6:	c7fd                	beqz	a5,80000ca4 <virtio_disk_init+0x1d4>
  memset(disk.desc, 0, PGSIZE);
    80000bb8:	6605                	lui	a2,0x1
    80000bba:	4581                	li	a1,0
    80000bbc:	00000097          	auipc	ra,0x0
    80000bc0:	3dc080e7          	jalr	988(ra) # 80000f98 <memset>
  memset(disk.avail, 0, PGSIZE);
    80000bc4:	00010497          	auipc	s1,0x10
    80000bc8:	54c48493          	add	s1,s1,1356 # 80011110 <disk>
    80000bcc:	6605                	lui	a2,0x1
    80000bce:	4581                	li	a1,0
    80000bd0:	6488                	ld	a0,8(s1)
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	3c6080e7          	jalr	966(ra) # 80000f98 <memset>
  memset(disk.used, 0, PGSIZE);
    80000bda:	6605                	lui	a2,0x1
    80000bdc:	4581                	li	a1,0
    80000bde:	6888                	ld	a0,16(s1)
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	3b8080e7          	jalr	952(ra) # 80000f98 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80000be8:	100017b7          	lui	a5,0x10001
    80000bec:	4721                	li	a4,8
    80000bee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80000bf0:	4098                	lw	a4,0(s1)
    80000bf2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80000bf6:	40d8                	lw	a4,4(s1)
    80000bf8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80000bfc:	6498                	ld	a4,8(s1)
    80000bfe:	0007069b          	sext.w	a3,a4
    80000c02:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80000c06:	9701                	sra	a4,a4,0x20
    80000c08:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80000c0c:	6898                	ld	a4,16(s1)
    80000c0e:	0007069b          	sext.w	a3,a4
    80000c12:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80000c16:	9701                	sra	a4,a4,0x20
    80000c18:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80000c1c:	4705                	li	a4,1
    80000c1e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80000c20:	00e48c23          	sb	a4,24(s1)
    80000c24:	00e48ca3          	sb	a4,25(s1)
    80000c28:	00e48d23          	sb	a4,26(s1)
    80000c2c:	00e48da3          	sb	a4,27(s1)
    80000c30:	00e48e23          	sb	a4,28(s1)
    80000c34:	00e48ea3          	sb	a4,29(s1)
    80000c38:	00e48f23          	sb	a4,30(s1)
    80000c3c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80000c40:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80000c44:	0727a823          	sw	s2,112(a5)
}
    80000c48:	60e2                	ld	ra,24(sp)
    80000c4a:	6442                	ld	s0,16(sp)
    80000c4c:	64a2                	ld	s1,8(sp)
    80000c4e:	6902                	ld	s2,0(sp)
    80000c50:	6105                	add	sp,sp,32
    80000c52:	8082                	ret
    panic("could not find virtio disk");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	4a450513          	add	a0,a0,1188 # 800080f8 <states.0+0x60>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	584080e7          	jalr	1412(ra) # 800011e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	4b450513          	add	a0,a0,1204 # 80008118 <states.0+0x80>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	574080e7          	jalr	1396(ra) # 800011e0 <panic>
    panic("virtio disk should not be ready");
    80000c74:	00007517          	auipc	a0,0x7
    80000c78:	4c450513          	add	a0,a0,1220 # 80008138 <states.0+0xa0>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	564080e7          	jalr	1380(ra) # 800011e0 <panic>
    panic("virtio disk has no queue 0");
    80000c84:	00007517          	auipc	a0,0x7
    80000c88:	4d450513          	add	a0,a0,1236 # 80008158 <states.0+0xc0>
    80000c8c:	00000097          	auipc	ra,0x0
    80000c90:	554080e7          	jalr	1364(ra) # 800011e0 <panic>
    panic("virtio disk max queue too short");
    80000c94:	00007517          	auipc	a0,0x7
    80000c98:	4e450513          	add	a0,a0,1252 # 80008178 <states.0+0xe0>
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	544080e7          	jalr	1348(ra) # 800011e0 <panic>
    panic("virtio disk kalloc");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	4f450513          	add	a0,a0,1268 # 80008198 <states.0+0x100>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	534080e7          	jalr	1332(ra) # 800011e0 <panic>

0000000080000cb4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80000cb4:	7159                	add	sp,sp,-112
    80000cb6:	f486                	sd	ra,104(sp)
    80000cb8:	f0a2                	sd	s0,96(sp)
    80000cba:	eca6                	sd	s1,88(sp)
    80000cbc:	e8ca                	sd	s2,80(sp)
    80000cbe:	e4ce                	sd	s3,72(sp)
    80000cc0:	e0d2                	sd	s4,64(sp)
    80000cc2:	fc56                	sd	s5,56(sp)
    80000cc4:	f85a                	sd	s6,48(sp)
    80000cc6:	f45e                	sd	s7,40(sp)
    80000cc8:	f062                	sd	s8,32(sp)
    80000cca:	ec66                	sd	s9,24(sp)
    80000ccc:	e86a                	sd	s10,16(sp)
    80000cce:	1880                	add	s0,sp,112
    80000cd0:	8a2a                	mv	s4,a0
    80000cd2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80000cd4:	00c52c83          	lw	s9,12(a0)
    80000cd8:	001c9c9b          	sllw	s9,s9,0x1
    80000cdc:	1c82                	sll	s9,s9,0x20
    80000cde:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80000ce2:	00010517          	auipc	a0,0x10
    80000ce6:	55650513          	add	a0,a0,1366 # 80011238 <disk+0x128>
    80000cea:	00002097          	auipc	ra,0x2
    80000cee:	204080e7          	jalr	516(ra) # 80002eee <acquire>
  for(int i = 0; i < 3; i++){
    80000cf2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80000cf4:	44a1                	li	s1,8
      disk.free[i] = 0;
    80000cf6:	00010b17          	auipc	s6,0x10
    80000cfa:	41ab0b13          	add	s6,s6,1050 # 80011110 <disk>
  for(int i = 0; i < 3; i++){
    80000cfe:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80000d00:	00010c17          	auipc	s8,0x10
    80000d04:	538c0c13          	add	s8,s8,1336 # 80011238 <disk+0x128>
    80000d08:	a095                	j	80000d6c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80000d0a:	00fb0733          	add	a4,s6,a5
    80000d0e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80000d12:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80000d14:	0207c563          	bltz	a5,80000d3e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80000d18:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80000d1a:	0591                	add	a1,a1,4
    80000d1c:	05560d63          	beq	a2,s5,80000d76 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80000d20:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80000d22:	00010717          	auipc	a4,0x10
    80000d26:	3ee70713          	add	a4,a4,1006 # 80011110 <disk>
    80000d2a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80000d2c:	01874683          	lbu	a3,24(a4)
    80000d30:	fee9                	bnez	a3,80000d0a <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80000d32:	2785                	addw	a5,a5,1
    80000d34:	0705                	add	a4,a4,1
    80000d36:	fe979be3          	bne	a5,s1,80000d2c <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80000d3a:	57fd                	li	a5,-1
    80000d3c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80000d3e:	00c05e63          	blez	a2,80000d5a <virtio_disk_rw+0xa6>
    80000d42:	060a                	sll	a2,a2,0x2
    80000d44:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80000d48:	0009a503          	lw	a0,0(s3)
    80000d4c:	00000097          	auipc	ra,0x0
    80000d50:	d02080e7          	jalr	-766(ra) # 80000a4e <free_desc>
      for(int j = 0; j < i; j++)
    80000d54:	0991                	add	s3,s3,4
    80000d56:	ffa999e3          	bne	s3,s10,80000d48 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80000d5a:	85e2                	mv	a1,s8
    80000d5c:	00010517          	auipc	a0,0x10
    80000d60:	3cc50513          	add	a0,a0,972 # 80011128 <disk+0x18>
    80000d64:	00002097          	auipc	ra,0x2
    80000d68:	ad8080e7          	jalr	-1320(ra) # 8000283c <sleep>
  for(int i = 0; i < 3; i++){
    80000d6c:	f9040993          	add	s3,s0,-112
{
    80000d70:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80000d72:	864a                	mv	a2,s2
    80000d74:	b775                	j	80000d20 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80000d76:	f9042503          	lw	a0,-112(s0)
    80000d7a:	00a50713          	add	a4,a0,10
    80000d7e:	0712                	sll	a4,a4,0x4

  if(write)
    80000d80:	00010797          	auipc	a5,0x10
    80000d84:	39078793          	add	a5,a5,912 # 80011110 <disk>
    80000d88:	00e786b3          	add	a3,a5,a4
    80000d8c:	01703633          	snez	a2,s7
    80000d90:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80000d92:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80000d96:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80000d9a:	f6070613          	add	a2,a4,-160
    80000d9e:	6394                	ld	a3,0(a5)
    80000da0:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80000da2:	00870593          	add	a1,a4,8
    80000da6:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80000da8:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80000daa:	0007b803          	ld	a6,0(a5)
    80000dae:	9642                	add	a2,a2,a6
    80000db0:	46c1                	li	a3,16
    80000db2:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80000db4:	4585                	li	a1,1
    80000db6:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80000dba:	f9442683          	lw	a3,-108(s0)
    80000dbe:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80000dc2:	0692                	sll	a3,a3,0x4
    80000dc4:	9836                	add	a6,a6,a3
    80000dc6:	058a0613          	add	a2,s4,88
    80000dca:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80000dce:	0007b803          	ld	a6,0(a5)
    80000dd2:	96c2                	add	a3,a3,a6
    80000dd4:	40000613          	li	a2,1024
    80000dd8:	c690                	sw	a2,8(a3)
  if(write)
    80000dda:	001bb613          	seqz	a2,s7
    80000dde:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80000de2:	00166613          	or	a2,a2,1
    80000de6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80000dea:	f9842603          	lw	a2,-104(s0)
    80000dee:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80000df2:	00250693          	add	a3,a0,2
    80000df6:	0692                	sll	a3,a3,0x4
    80000df8:	96be                	add	a3,a3,a5
    80000dfa:	58fd                	li	a7,-1
    80000dfc:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80000e00:	0612                	sll	a2,a2,0x4
    80000e02:	9832                	add	a6,a6,a2
    80000e04:	f9070713          	add	a4,a4,-112
    80000e08:	973e                	add	a4,a4,a5
    80000e0a:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80000e0e:	6398                	ld	a4,0(a5)
    80000e10:	9732                	add	a4,a4,a2
    80000e12:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80000e14:	4609                	li	a2,2
    80000e16:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80000e1a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80000e1e:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80000e22:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80000e26:	6794                	ld	a3,8(a5)
    80000e28:	0026d703          	lhu	a4,2(a3)
    80000e2c:	8b1d                	and	a4,a4,7
    80000e2e:	0706                	sll	a4,a4,0x1
    80000e30:	96ba                	add	a3,a3,a4
    80000e32:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80000e36:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80000e3a:	6798                	ld	a4,8(a5)
    80000e3c:	00275783          	lhu	a5,2(a4)
    80000e40:	2785                	addw	a5,a5,1
    80000e42:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80000e46:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80000e4a:	100017b7          	lui	a5,0x10001
    80000e4e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80000e52:	004a2783          	lw	a5,4(s4)
    // printf("virtio_disk_rw: sleeping on buf %p\n", b);
    sleep(b, &disk.vdisk_lock);
    80000e56:	00010917          	auipc	s2,0x10
    80000e5a:	3e290913          	add	s2,s2,994 # 80011238 <disk+0x128>
  while(b->disk == 1) {
    80000e5e:	4485                	li	s1,1
    80000e60:	00b79c63          	bne	a5,a1,80000e78 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80000e64:	85ca                	mv	a1,s2
    80000e66:	8552                	mv	a0,s4
    80000e68:	00002097          	auipc	ra,0x2
    80000e6c:	9d4080e7          	jalr	-1580(ra) # 8000283c <sleep>
  while(b->disk == 1) {
    80000e70:	004a2783          	lw	a5,4(s4)
    80000e74:	fe9788e3          	beq	a5,s1,80000e64 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80000e78:	f9042903          	lw	s2,-112(s0)
    80000e7c:	00290713          	add	a4,s2,2
    80000e80:	0712                	sll	a4,a4,0x4
    80000e82:	00010797          	auipc	a5,0x10
    80000e86:	28e78793          	add	a5,a5,654 # 80011110 <disk>
    80000e8a:	97ba                	add	a5,a5,a4
    80000e8c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80000e90:	00010997          	auipc	s3,0x10
    80000e94:	28098993          	add	s3,s3,640 # 80011110 <disk>
    80000e98:	00491713          	sll	a4,s2,0x4
    80000e9c:	0009b783          	ld	a5,0(s3)
    80000ea0:	97ba                	add	a5,a5,a4
    80000ea2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80000ea6:	854a                	mv	a0,s2
    80000ea8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80000eac:	00000097          	auipc	ra,0x0
    80000eb0:	ba2080e7          	jalr	-1118(ra) # 80000a4e <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80000eb4:	8885                	and	s1,s1,1
    80000eb6:	f0ed                	bnez	s1,80000e98 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80000eb8:	00010517          	auipc	a0,0x10
    80000ebc:	38050513          	add	a0,a0,896 # 80011238 <disk+0x128>
    80000ec0:	00002097          	auipc	ra,0x2
    80000ec4:	0e2080e7          	jalr	226(ra) # 80002fa2 <release>
}
    80000ec8:	70a6                	ld	ra,104(sp)
    80000eca:	7406                	ld	s0,96(sp)
    80000ecc:	64e6                	ld	s1,88(sp)
    80000ece:	6946                	ld	s2,80(sp)
    80000ed0:	69a6                	ld	s3,72(sp)
    80000ed2:	6a06                	ld	s4,64(sp)
    80000ed4:	7ae2                	ld	s5,56(sp)
    80000ed6:	7b42                	ld	s6,48(sp)
    80000ed8:	7ba2                	ld	s7,40(sp)
    80000eda:	7c02                	ld	s8,32(sp)
    80000edc:	6ce2                	ld	s9,24(sp)
    80000ede:	6d42                	ld	s10,16(sp)
    80000ee0:	6165                	add	sp,sp,112
    80000ee2:	8082                	ret

0000000080000ee4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80000ee4:	1101                	add	sp,sp,-32
    80000ee6:	ec06                	sd	ra,24(sp)
    80000ee8:	e822                	sd	s0,16(sp)
    80000eea:	e426                	sd	s1,8(sp)
    80000eec:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    80000eee:	00010497          	auipc	s1,0x10
    80000ef2:	22248493          	add	s1,s1,546 # 80011110 <disk>
    80000ef6:	00010517          	auipc	a0,0x10
    80000efa:	34250513          	add	a0,a0,834 # 80011238 <disk+0x128>
    80000efe:	00002097          	auipc	ra,0x2
    80000f02:	ff0080e7          	jalr	-16(ra) # 80002eee <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80000f06:	10001737          	lui	a4,0x10001
    80000f0a:	533c                	lw	a5,96(a4)
    80000f0c:	8b8d                	and	a5,a5,3
    80000f0e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80000f10:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80000f14:	689c                	ld	a5,16(s1)
    80000f16:	0204d703          	lhu	a4,32(s1)
    80000f1a:	0027d783          	lhu	a5,2(a5)
    80000f1e:	04f70863          	beq	a4,a5,80000f6e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80000f22:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80000f26:	6898                	ld	a4,16(s1)
    80000f28:	0204d783          	lhu	a5,32(s1)
    80000f2c:	8b9d                	and	a5,a5,7
    80000f2e:	078e                	sll	a5,a5,0x3
    80000f30:	97ba                	add	a5,a5,a4
    80000f32:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80000f34:	00278713          	add	a4,a5,2
    80000f38:	0712                	sll	a4,a4,0x4
    80000f3a:	9726                	add	a4,a4,s1
    80000f3c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80000f40:	e721                	bnez	a4,80000f88 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80000f42:	0789                	add	a5,a5,2
    80000f44:	0792                	sll	a5,a5,0x4
    80000f46:	97a6                	add	a5,a5,s1
    80000f48:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80000f4a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	95c080e7          	jalr	-1700(ra) # 800028aa <wakeup>

    disk.used_idx += 1;
    80000f56:	0204d783          	lhu	a5,32(s1)
    80000f5a:	2785                	addw	a5,a5,1
    80000f5c:	17c2                	sll	a5,a5,0x30
    80000f5e:	93c1                	srl	a5,a5,0x30
    80000f60:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80000f64:	6898                	ld	a4,16(s1)
    80000f66:	00275703          	lhu	a4,2(a4)
    80000f6a:	faf71ce3          	bne	a4,a5,80000f22 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80000f6e:	00010517          	auipc	a0,0x10
    80000f72:	2ca50513          	add	a0,a0,714 # 80011238 <disk+0x128>
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	02c080e7          	jalr	44(ra) # 80002fa2 <release>
}
    80000f7e:	60e2                	ld	ra,24(sp)
    80000f80:	6442                	ld	s0,16(sp)
    80000f82:	64a2                	ld	s1,8(sp)
    80000f84:	6105                	add	sp,sp,32
    80000f86:	8082                	ret
      panic("virtio_disk_intr status");
    80000f88:	00007517          	auipc	a0,0x7
    80000f8c:	22850513          	add	a0,a0,552 # 800081b0 <states.0+0x118>
    80000f90:	00000097          	auipc	ra,0x0
    80000f94:	250080e7          	jalr	592(ra) # 800011e0 <panic>

0000000080000f98 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000f98:	1141                	add	sp,sp,-16
    80000f9a:	e422                	sd	s0,8(sp)
    80000f9c:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000f9e:	ca19                	beqz	a2,80000fb4 <memset+0x1c>
    80000fa0:	87aa                	mv	a5,a0
    80000fa2:	1602                	sll	a2,a2,0x20
    80000fa4:	9201                	srl	a2,a2,0x20
    80000fa6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000faa:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000fae:	0785                	add	a5,a5,1
    80000fb0:	fee79de3          	bne	a5,a4,80000faa <memset+0x12>
  }
  return dst;
}
    80000fb4:	6422                	ld	s0,8(sp)
    80000fb6:	0141                	add	sp,sp,16
    80000fb8:	8082                	ret

0000000080000fba <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000fba:	1141                	add	sp,sp,-16
    80000fbc:	e422                	sd	s0,8(sp)
    80000fbe:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000fc0:	ca05                	beqz	a2,80000ff0 <memcmp+0x36>
    80000fc2:	fff6069b          	addw	a3,a2,-1
    80000fc6:	1682                	sll	a3,a3,0x20
    80000fc8:	9281                	srl	a3,a3,0x20
    80000fca:	0685                	add	a3,a3,1
    80000fcc:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000fce:	00054783          	lbu	a5,0(a0)
    80000fd2:	0005c703          	lbu	a4,0(a1)
    80000fd6:	00e79863          	bne	a5,a4,80000fe6 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000fda:	0505                	add	a0,a0,1
    80000fdc:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000fde:	fed518e3          	bne	a0,a3,80000fce <memcmp+0x14>
  }

  return 0;
    80000fe2:	4501                	li	a0,0
    80000fe4:	a019                	j	80000fea <memcmp+0x30>
      return *s1 - *s2;
    80000fe6:	40e7853b          	subw	a0,a5,a4
}
    80000fea:	6422                	ld	s0,8(sp)
    80000fec:	0141                	add	sp,sp,16
    80000fee:	8082                	ret
  return 0;
    80000ff0:	4501                	li	a0,0
    80000ff2:	bfe5                	j	80000fea <memcmp+0x30>

0000000080000ff4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ff4:	1141                	add	sp,sp,-16
    80000ff6:	e422                	sd	s0,8(sp)
    80000ff8:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ffa:	c205                	beqz	a2,8000101a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ffc:	02a5e263          	bltu	a1,a0,80001020 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001000:	1602                	sll	a2,a2,0x20
    80001002:	9201                	srl	a2,a2,0x20
    80001004:	00c587b3          	add	a5,a1,a2
{
    80001008:	872a                	mv	a4,a0
      *d++ = *s++;
    8000100a:	0585                	add	a1,a1,1
    8000100c:	0705                	add	a4,a4,1
    8000100e:	fff5c683          	lbu	a3,-1(a1)
    80001012:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80001016:	fef59ae3          	bne	a1,a5,8000100a <memmove+0x16>

  return dst;
}
    8000101a:	6422                	ld	s0,8(sp)
    8000101c:	0141                	add	sp,sp,16
    8000101e:	8082                	ret
  if(s < d && s + n > d){
    80001020:	02061693          	sll	a3,a2,0x20
    80001024:	9281                	srl	a3,a3,0x20
    80001026:	00d58733          	add	a4,a1,a3
    8000102a:	fce57be3          	bgeu	a0,a4,80001000 <memmove+0xc>
    d += n;
    8000102e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80001030:	fff6079b          	addw	a5,a2,-1
    80001034:	1782                	sll	a5,a5,0x20
    80001036:	9381                	srl	a5,a5,0x20
    80001038:	fff7c793          	not	a5,a5
    8000103c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    8000103e:	177d                	add	a4,a4,-1
    80001040:	16fd                	add	a3,a3,-1
    80001042:	00074603          	lbu	a2,0(a4)
    80001046:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    8000104a:	fee79ae3          	bne	a5,a4,8000103e <memmove+0x4a>
    8000104e:	b7f1                	j	8000101a <memmove+0x26>

0000000080001050 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001050:	1141                	add	sp,sp,-16
    80001052:	e406                	sd	ra,8(sp)
    80001054:	e022                	sd	s0,0(sp)
    80001056:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	f9c080e7          	jalr	-100(ra) # 80000ff4 <memmove>
}
    80001060:	60a2                	ld	ra,8(sp)
    80001062:	6402                	ld	s0,0(sp)
    80001064:	0141                	add	sp,sp,16
    80001066:	8082                	ret

0000000080001068 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001068:	1141                	add	sp,sp,-16
    8000106a:	e422                	sd	s0,8(sp)
    8000106c:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000106e:	ce11                	beqz	a2,8000108a <strncmp+0x22>
    80001070:	00054783          	lbu	a5,0(a0)
    80001074:	cf89                	beqz	a5,8000108e <strncmp+0x26>
    80001076:	0005c703          	lbu	a4,0(a1)
    8000107a:	00f71a63          	bne	a4,a5,8000108e <strncmp+0x26>
    n--, p++, q++;
    8000107e:	367d                	addw	a2,a2,-1
    80001080:	0505                	add	a0,a0,1
    80001082:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001084:	f675                	bnez	a2,80001070 <strncmp+0x8>
  if(n == 0)
    return 0;
    80001086:	4501                	li	a0,0
    80001088:	a809                	j	8000109a <strncmp+0x32>
    8000108a:	4501                	li	a0,0
    8000108c:	a039                	j	8000109a <strncmp+0x32>
  if(n == 0)
    8000108e:	ca09                	beqz	a2,800010a0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80001090:	00054503          	lbu	a0,0(a0)
    80001094:	0005c783          	lbu	a5,0(a1)
    80001098:	9d1d                	subw	a0,a0,a5
}
    8000109a:	6422                	ld	s0,8(sp)
    8000109c:	0141                	add	sp,sp,16
    8000109e:	8082                	ret
    return 0;
    800010a0:	4501                	li	a0,0
    800010a2:	bfe5                	j	8000109a <strncmp+0x32>

00000000800010a4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800010a4:	1141                	add	sp,sp,-16
    800010a6:	e422                	sd	s0,8(sp)
    800010a8:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800010aa:	87aa                	mv	a5,a0
    800010ac:	86b2                	mv	a3,a2
    800010ae:	367d                	addw	a2,a2,-1
    800010b0:	00d05963          	blez	a3,800010c2 <strncpy+0x1e>
    800010b4:	0785                	add	a5,a5,1
    800010b6:	0005c703          	lbu	a4,0(a1)
    800010ba:	fee78fa3          	sb	a4,-1(a5)
    800010be:	0585                	add	a1,a1,1
    800010c0:	f775                	bnez	a4,800010ac <strncpy+0x8>
    ;
  while(n-- > 0)
    800010c2:	873e                	mv	a4,a5
    800010c4:	9fb5                	addw	a5,a5,a3
    800010c6:	37fd                	addw	a5,a5,-1
    800010c8:	00c05963          	blez	a2,800010da <strncpy+0x36>
    *s++ = 0;
    800010cc:	0705                	add	a4,a4,1
    800010ce:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    800010d2:	40e786bb          	subw	a3,a5,a4
    800010d6:	fed04be3          	bgtz	a3,800010cc <strncpy+0x28>
  return os;
}
    800010da:	6422                	ld	s0,8(sp)
    800010dc:	0141                	add	sp,sp,16
    800010de:	8082                	ret

00000000800010e0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800010e0:	1141                	add	sp,sp,-16
    800010e2:	e422                	sd	s0,8(sp)
    800010e4:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800010e6:	02c05363          	blez	a2,8000110c <safestrcpy+0x2c>
    800010ea:	fff6069b          	addw	a3,a2,-1
    800010ee:	1682                	sll	a3,a3,0x20
    800010f0:	9281                	srl	a3,a3,0x20
    800010f2:	96ae                	add	a3,a3,a1
    800010f4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800010f6:	00d58963          	beq	a1,a3,80001108 <safestrcpy+0x28>
    800010fa:	0585                	add	a1,a1,1
    800010fc:	0785                	add	a5,a5,1
    800010fe:	fff5c703          	lbu	a4,-1(a1)
    80001102:	fee78fa3          	sb	a4,-1(a5)
    80001106:	fb65                	bnez	a4,800010f6 <safestrcpy+0x16>
    ;
  *s = 0;
    80001108:	00078023          	sb	zero,0(a5)
  return os;
}
    8000110c:	6422                	ld	s0,8(sp)
    8000110e:	0141                	add	sp,sp,16
    80001110:	8082                	ret

0000000080001112 <strlen>:

int
strlen(const char *s)
{
    80001112:	1141                	add	sp,sp,-16
    80001114:	e422                	sd	s0,8(sp)
    80001116:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001118:	00054783          	lbu	a5,0(a0)
    8000111c:	cf91                	beqz	a5,80001138 <strlen+0x26>
    8000111e:	0505                	add	a0,a0,1
    80001120:	87aa                	mv	a5,a0
    80001122:	86be                	mv	a3,a5
    80001124:	0785                	add	a5,a5,1
    80001126:	fff7c703          	lbu	a4,-1(a5)
    8000112a:	ff65                	bnez	a4,80001122 <strlen+0x10>
    8000112c:	40a6853b          	subw	a0,a3,a0
    80001130:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80001132:	6422                	ld	s0,8(sp)
    80001134:	0141                	add	sp,sp,16
    80001136:	8082                	ret
  for(n = 0; s[n]; n++)
    80001138:	4501                	li	a0,0
    8000113a:	bfe5                	j	80001132 <strlen+0x20>

000000008000113c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000113c:	7179                	add	sp,sp,-48
    8000113e:	f406                	sd	ra,40(sp)
    80001140:	f022                	sd	s0,32(sp)
    80001142:	ec26                	sd	s1,24(sp)
    80001144:	e84a                	sd	s2,16(sp)
    80001146:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80001148:	c219                	beqz	a2,8000114e <printint+0x12>
    8000114a:	08054763          	bltz	a0,800011d8 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    8000114e:	2501                	sext.w	a0,a0
    80001150:	4881                	li	a7,0
    80001152:	fd040693          	add	a3,s0,-48

  i = 0;
    80001156:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80001158:	2581                	sext.w	a1,a1
    8000115a:	00007617          	auipc	a2,0x7
    8000115e:	09660613          	add	a2,a2,150 # 800081f0 <digits>
    80001162:	883a                	mv	a6,a4
    80001164:	2705                	addw	a4,a4,1
    80001166:	02b577bb          	remuw	a5,a0,a1
    8000116a:	1782                	sll	a5,a5,0x20
    8000116c:	9381                	srl	a5,a5,0x20
    8000116e:	97b2                	add	a5,a5,a2
    80001170:	0007c783          	lbu	a5,0(a5)
    80001174:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80001178:	0005079b          	sext.w	a5,a0
    8000117c:	02b5553b          	divuw	a0,a0,a1
    80001180:	0685                	add	a3,a3,1
    80001182:	feb7f0e3          	bgeu	a5,a1,80001162 <printint+0x26>

  if(sign)
    80001186:	00088c63          	beqz	a7,8000119e <printint+0x62>
    buf[i++] = '-';
    8000118a:	fe070793          	add	a5,a4,-32
    8000118e:	00878733          	add	a4,a5,s0
    80001192:	02d00793          	li	a5,45
    80001196:	fef70823          	sb	a5,-16(a4)
    8000119a:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    8000119e:	02e05763          	blez	a4,800011cc <printint+0x90>
    800011a2:	fd040793          	add	a5,s0,-48
    800011a6:	00e784b3          	add	s1,a5,a4
    800011aa:	fff78913          	add	s2,a5,-1
    800011ae:	993a                	add	s2,s2,a4
    800011b0:	377d                	addw	a4,a4,-1
    800011b2:	1702                	sll	a4,a4,0x20
    800011b4:	9301                	srl	a4,a4,0x20
    800011b6:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    800011ba:	fff4c503          	lbu	a0,-1(s1)
    800011be:	fffff097          	auipc	ra,0xfffff
    800011c2:	52a080e7          	jalr	1322(ra) # 800006e8 <consputc>
  while(--i >= 0)
    800011c6:	14fd                	add	s1,s1,-1
    800011c8:	ff2499e3          	bne	s1,s2,800011ba <printint+0x7e>
}
    800011cc:	70a2                	ld	ra,40(sp)
    800011ce:	7402                	ld	s0,32(sp)
    800011d0:	64e2                	ld	s1,24(sp)
    800011d2:	6942                	ld	s2,16(sp)
    800011d4:	6145                	add	sp,sp,48
    800011d6:	8082                	ret
    x = -xx;
    800011d8:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    800011dc:	4885                	li	a7,1
    x = -xx;
    800011de:	bf95                	j	80001152 <printint+0x16>

00000000800011e0 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    800011e0:	1101                	add	sp,sp,-32
    800011e2:	ec06                	sd	ra,24(sp)
    800011e4:	e822                	sd	s0,16(sp)
    800011e6:	e426                	sd	s1,8(sp)
    800011e8:	1000                	add	s0,sp,32
    800011ea:	84aa                	mv	s1,a0
  pr.locking = 0;
    800011ec:	00010797          	auipc	a5,0x10
    800011f0:	0607ae23          	sw	zero,124(a5) # 80011268 <pr+0x18>
  printf("panic: ");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	fd450513          	add	a0,a0,-44 # 800081c8 <states.0+0x130>
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	02e080e7          	jalr	46(ra) # 8000122a <printf>
  printf(s);
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	024080e7          	jalr	36(ra) # 8000122a <printf>
  printf("\n");
    8000120e:	00008517          	auipc	a0,0x8
    80001212:	a9a50513          	add	a0,a0,-1382 # 80008ca8 <syscalls+0x540>
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	014080e7          	jalr	20(ra) # 8000122a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000121e:	4785                	li	a5,1
    80001220:	00008717          	auipc	a4,0x8
    80001224:	c6f72c23          	sw	a5,-904(a4) # 80008e98 <panicked>
  for(;;)
    80001228:	a001                	j	80001228 <panic+0x48>

000000008000122a <printf>:
{
    8000122a:	7131                	add	sp,sp,-192
    8000122c:	fc86                	sd	ra,120(sp)
    8000122e:	f8a2                	sd	s0,112(sp)
    80001230:	f4a6                	sd	s1,104(sp)
    80001232:	f0ca                	sd	s2,96(sp)
    80001234:	ecce                	sd	s3,88(sp)
    80001236:	e8d2                	sd	s4,80(sp)
    80001238:	e4d6                	sd	s5,72(sp)
    8000123a:	e0da                	sd	s6,64(sp)
    8000123c:	fc5e                	sd	s7,56(sp)
    8000123e:	f862                	sd	s8,48(sp)
    80001240:	f466                	sd	s9,40(sp)
    80001242:	f06a                	sd	s10,32(sp)
    80001244:	ec6e                	sd	s11,24(sp)
    80001246:	0100                	add	s0,sp,128
    80001248:	8a2a                	mv	s4,a0
    8000124a:	e40c                	sd	a1,8(s0)
    8000124c:	e810                	sd	a2,16(s0)
    8000124e:	ec14                	sd	a3,24(s0)
    80001250:	f018                	sd	a4,32(s0)
    80001252:	f41c                	sd	a5,40(s0)
    80001254:	03043823          	sd	a6,48(s0)
    80001258:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000125c:	00010d97          	auipc	s11,0x10
    80001260:	00cdad83          	lw	s11,12(s11) # 80011268 <pr+0x18>
  if(locking)
    80001264:	020d9b63          	bnez	s11,8000129a <printf+0x70>
  if (fmt == 0)
    80001268:	040a0263          	beqz	s4,800012ac <printf+0x82>
  va_start(ap, fmt);
    8000126c:	00840793          	add	a5,s0,8
    80001270:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80001274:	000a4503          	lbu	a0,0(s4)
    80001278:	14050f63          	beqz	a0,800013d6 <printf+0x1ac>
    8000127c:	4981                	li	s3,0
    if(c != '%'){
    8000127e:	02500a93          	li	s5,37
    switch(c){
    80001282:	07000b93          	li	s7,112
  consputc('x');
    80001286:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80001288:	00007b17          	auipc	s6,0x7
    8000128c:	f68b0b13          	add	s6,s6,-152 # 800081f0 <digits>
    switch(c){
    80001290:	07300c93          	li	s9,115
    80001294:	06400c13          	li	s8,100
    80001298:	a82d                	j	800012d2 <printf+0xa8>
    acquire(&pr.lock);
    8000129a:	00010517          	auipc	a0,0x10
    8000129e:	fb650513          	add	a0,a0,-74 # 80011250 <pr>
    800012a2:	00002097          	auipc	ra,0x2
    800012a6:	c4c080e7          	jalr	-948(ra) # 80002eee <acquire>
    800012aa:	bf7d                	j	80001268 <printf+0x3e>
    panic("null fmt");
    800012ac:	00007517          	auipc	a0,0x7
    800012b0:	f2c50513          	add	a0,a0,-212 # 800081d8 <states.0+0x140>
    800012b4:	00000097          	auipc	ra,0x0
    800012b8:	f2c080e7          	jalr	-212(ra) # 800011e0 <panic>
      consputc(c);
    800012bc:	fffff097          	auipc	ra,0xfffff
    800012c0:	42c080e7          	jalr	1068(ra) # 800006e8 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800012c4:	2985                	addw	s3,s3,1
    800012c6:	013a07b3          	add	a5,s4,s3
    800012ca:	0007c503          	lbu	a0,0(a5)
    800012ce:	10050463          	beqz	a0,800013d6 <printf+0x1ac>
    if(c != '%'){
    800012d2:	ff5515e3          	bne	a0,s5,800012bc <printf+0x92>
    c = fmt[++i] & 0xff;
    800012d6:	2985                	addw	s3,s3,1
    800012d8:	013a07b3          	add	a5,s4,s3
    800012dc:	0007c783          	lbu	a5,0(a5)
    800012e0:	0007849b          	sext.w	s1,a5
    if(c == 0)
    800012e4:	cbed                	beqz	a5,800013d6 <printf+0x1ac>
    switch(c){
    800012e6:	05778a63          	beq	a5,s7,8000133a <printf+0x110>
    800012ea:	02fbf663          	bgeu	s7,a5,80001316 <printf+0xec>
    800012ee:	09978863          	beq	a5,s9,8000137e <printf+0x154>
    800012f2:	07800713          	li	a4,120
    800012f6:	0ce79563          	bne	a5,a4,800013c0 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    800012fa:	f8843783          	ld	a5,-120(s0)
    800012fe:	00878713          	add	a4,a5,8
    80001302:	f8e43423          	sd	a4,-120(s0)
    80001306:	4605                	li	a2,1
    80001308:	85ea                	mv	a1,s10
    8000130a:	4388                	lw	a0,0(a5)
    8000130c:	00000097          	auipc	ra,0x0
    80001310:	e30080e7          	jalr	-464(ra) # 8000113c <printint>
      break;
    80001314:	bf45                	j	800012c4 <printf+0x9a>
    switch(c){
    80001316:	09578f63          	beq	a5,s5,800013b4 <printf+0x18a>
    8000131a:	0b879363          	bne	a5,s8,800013c0 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000131e:	f8843783          	ld	a5,-120(s0)
    80001322:	00878713          	add	a4,a5,8
    80001326:	f8e43423          	sd	a4,-120(s0)
    8000132a:	4605                	li	a2,1
    8000132c:	45a9                	li	a1,10
    8000132e:	4388                	lw	a0,0(a5)
    80001330:	00000097          	auipc	ra,0x0
    80001334:	e0c080e7          	jalr	-500(ra) # 8000113c <printint>
      break;
    80001338:	b771                	j	800012c4 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000133a:	f8843783          	ld	a5,-120(s0)
    8000133e:	00878713          	add	a4,a5,8
    80001342:	f8e43423          	sd	a4,-120(s0)
    80001346:	0007b903          	ld	s2,0(a5)
  consputc('0');
    8000134a:	03000513          	li	a0,48
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	39a080e7          	jalr	922(ra) # 800006e8 <consputc>
  consputc('x');
    80001356:	07800513          	li	a0,120
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	38e080e7          	jalr	910(ra) # 800006e8 <consputc>
    80001362:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80001364:	03c95793          	srl	a5,s2,0x3c
    80001368:	97da                	add	a5,a5,s6
    8000136a:	0007c503          	lbu	a0,0(a5)
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	37a080e7          	jalr	890(ra) # 800006e8 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80001376:	0912                	sll	s2,s2,0x4
    80001378:	34fd                	addw	s1,s1,-1
    8000137a:	f4ed                	bnez	s1,80001364 <printf+0x13a>
    8000137c:	b7a1                	j	800012c4 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    8000137e:	f8843783          	ld	a5,-120(s0)
    80001382:	00878713          	add	a4,a5,8
    80001386:	f8e43423          	sd	a4,-120(s0)
    8000138a:	6384                	ld	s1,0(a5)
    8000138c:	cc89                	beqz	s1,800013a6 <printf+0x17c>
      for(; *s; s++)
    8000138e:	0004c503          	lbu	a0,0(s1)
    80001392:	d90d                	beqz	a0,800012c4 <printf+0x9a>
        consputc(*s);
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	354080e7          	jalr	852(ra) # 800006e8 <consputc>
      for(; *s; s++)
    8000139c:	0485                	add	s1,s1,1
    8000139e:	0004c503          	lbu	a0,0(s1)
    800013a2:	f96d                	bnez	a0,80001394 <printf+0x16a>
    800013a4:	b705                	j	800012c4 <printf+0x9a>
        s = "(null)";
    800013a6:	00007497          	auipc	s1,0x7
    800013aa:	e2a48493          	add	s1,s1,-470 # 800081d0 <states.0+0x138>
      for(; *s; s++)
    800013ae:	02800513          	li	a0,40
    800013b2:	b7cd                	j	80001394 <printf+0x16a>
      consputc('%');
    800013b4:	8556                	mv	a0,s5
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	332080e7          	jalr	818(ra) # 800006e8 <consputc>
      break;
    800013be:	b719                	j	800012c4 <printf+0x9a>
      consputc('%');
    800013c0:	8556                	mv	a0,s5
    800013c2:	fffff097          	auipc	ra,0xfffff
    800013c6:	326080e7          	jalr	806(ra) # 800006e8 <consputc>
      consputc(c);
    800013ca:	8526                	mv	a0,s1
    800013cc:	fffff097          	auipc	ra,0xfffff
    800013d0:	31c080e7          	jalr	796(ra) # 800006e8 <consputc>
      break;
    800013d4:	bdc5                	j	800012c4 <printf+0x9a>
  if(locking)
    800013d6:	020d9163          	bnez	s11,800013f8 <printf+0x1ce>
}
    800013da:	70e6                	ld	ra,120(sp)
    800013dc:	7446                	ld	s0,112(sp)
    800013de:	74a6                	ld	s1,104(sp)
    800013e0:	7906                	ld	s2,96(sp)
    800013e2:	69e6                	ld	s3,88(sp)
    800013e4:	6a46                	ld	s4,80(sp)
    800013e6:	6aa6                	ld	s5,72(sp)
    800013e8:	6b06                	ld	s6,64(sp)
    800013ea:	7be2                	ld	s7,56(sp)
    800013ec:	7c42                	ld	s8,48(sp)
    800013ee:	7ca2                	ld	s9,40(sp)
    800013f0:	7d02                	ld	s10,32(sp)
    800013f2:	6de2                	ld	s11,24(sp)
    800013f4:	6129                	add	sp,sp,192
    800013f6:	8082                	ret
    release(&pr.lock);
    800013f8:	00010517          	auipc	a0,0x10
    800013fc:	e5850513          	add	a0,a0,-424 # 80011250 <pr>
    80001400:	00002097          	auipc	ra,0x2
    80001404:	ba2080e7          	jalr	-1118(ra) # 80002fa2 <release>
}
    80001408:	bfc9                	j	800013da <printf+0x1b0>

000000008000140a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000140a:	1101                	add	sp,sp,-32
    8000140c:	ec06                	sd	ra,24(sp)
    8000140e:	e822                	sd	s0,16(sp)
    80001410:	e426                	sd	s1,8(sp)
    80001412:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80001414:	00010497          	auipc	s1,0x10
    80001418:	e3c48493          	add	s1,s1,-452 # 80011250 <pr>
    8000141c:	00007597          	auipc	a1,0x7
    80001420:	dcc58593          	add	a1,a1,-564 # 800081e8 <states.0+0x150>
    80001424:	8526                	mv	a0,s1
    80001426:	00002097          	auipc	ra,0x2
    8000142a:	a38080e7          	jalr	-1480(ra) # 80002e5e <initlock>
  pr.locking = 1;
    8000142e:	4785                	li	a5,1
    80001430:	cc9c                	sw	a5,24(s1)
}
    80001432:	60e2                	ld	ra,24(sp)
    80001434:	6442                	ld	s0,16(sp)
    80001436:	64a2                	ld	s1,8(sp)
    80001438:	6105                	add	sp,sp,32
    8000143a:	8082                	ret

000000008000143c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(uint64 page, bool in_kernel)
{
    8000143c:	1101                	add	sp,sp,-32
    8000143e:	ec06                	sd	ra,24(sp)
    80001440:	e822                	sd	s0,16(sp)
    80001442:	e426                	sd	s1,8(sp)
    80001444:	e04a                	sd	s2,0(sp)
    80001446:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)page % PGSIZE) != 0 || (char*)page < end || (uint64)page >= PHYSTOP) //检测合法性
    80001448:	03451793          	sll	a5,a0,0x34
    8000144c:	ebb9                	bnez	a5,800014a2 <kfree+0x66>
    8000144e:	84aa                	mv	s1,a0
    80001450:	00021797          	auipc	a5,0x21
    80001454:	ef878793          	add	a5,a5,-264 # 80022348 <end>
    80001458:	04f56563          	bltu	a0,a5,800014a2 <kfree+0x66>
    8000145c:	47c5                	li	a5,17
    8000145e:	07ee                	sll	a5,a5,0x1b
    80001460:	04f57163          	bgeu	a0,a5,800014a2 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset((char*)page, 1, PGSIZE); 
    80001464:	6605                	lui	a2,0x1
    80001466:	4585                	li	a1,1
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	b30080e7          	jalr	-1232(ra) # 80000f98 <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    80001470:	00010917          	auipc	s2,0x10
    80001474:	e0090913          	add	s2,s2,-512 # 80011270 <kmem>
    80001478:	854a                	mv	a0,s2
    8000147a:	00002097          	auipc	ra,0x2
    8000147e:	a74080e7          	jalr	-1420(ra) # 80002eee <acquire>
  r->next = kmem.freelist;  //头插
    80001482:	01893783          	ld	a5,24(s2)
    80001486:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80001488:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    8000148c:	854a                	mv	a0,s2
    8000148e:	00002097          	auipc	ra,0x2
    80001492:	b14080e7          	jalr	-1260(ra) # 80002fa2 <release>
}
    80001496:	60e2                	ld	ra,24(sp)
    80001498:	6442                	ld	s0,16(sp)
    8000149a:	64a2                	ld	s1,8(sp)
    8000149c:	6902                	ld	s2,0(sp)
    8000149e:	6105                	add	sp,sp,32
    800014a0:	8082                	ret
    panic("kfree");
    800014a2:	00007517          	auipc	a0,0x7
    800014a6:	d6650513          	add	a0,a0,-666 # 80008208 <digits+0x18>
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	d36080e7          	jalr	-714(ra) # 800011e0 <panic>

00000000800014b2 <freerange>:
{
    800014b2:	7179                	add	sp,sp,-48
    800014b4:	f406                	sd	ra,40(sp)
    800014b6:	f022                	sd	s0,32(sp)
    800014b8:	ec26                	sd	s1,24(sp)
    800014ba:	e84a                	sd	s2,16(sp)
    800014bc:	e44e                	sd	s3,8(sp)
    800014be:	e052                	sd	s4,0(sp)
    800014c0:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start); //可用内存初始地址对齐4KB
    800014c2:	6785                	lui	a5,0x1
    800014c4:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    800014c8:	00e504b3          	add	s1,a0,a4
    800014cc:	777d                	lui	a4,0xfffff
    800014ce:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800014d0:	94be                	add	s1,s1,a5
    800014d2:	0095ef63          	bltu	a1,s1,800014f0 <freerange+0x3e>
    800014d6:	892e                	mv	s2,a1
    kfree((uint64)p,true);
    800014d8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800014da:	6985                	lui	s3,0x1
    kfree((uint64)p,true);
    800014dc:	4585                	li	a1,1
    800014de:	01448533          	add	a0,s1,s4
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	f5a080e7          	jalr	-166(ra) # 8000143c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800014ea:	94ce                	add	s1,s1,s3
    800014ec:	fe9978e3          	bgeu	s2,s1,800014dc <freerange+0x2a>
}
    800014f0:	70a2                	ld	ra,40(sp)
    800014f2:	7402                	ld	s0,32(sp)
    800014f4:	64e2                	ld	s1,24(sp)
    800014f6:	6942                	ld	s2,16(sp)
    800014f8:	69a2                	ld	s3,8(sp)
    800014fa:	6a02                	ld	s4,0(sp)
    800014fc:	6145                	add	sp,sp,48
    800014fe:	8082                	ret

0000000080001500 <kinit>:
{
    80001500:	1141                	add	sp,sp,-16
    80001502:	e406                	sd	ra,8(sp)
    80001504:	e022                	sd	s0,0(sp)
    80001506:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80001508:	00007597          	auipc	a1,0x7
    8000150c:	d0858593          	add	a1,a1,-760 # 80008210 <digits+0x20>
    80001510:	00010517          	auipc	a0,0x10
    80001514:	d6050513          	add	a0,a0,-672 # 80011270 <kmem>
    80001518:	00002097          	auipc	ra,0x2
    8000151c:	946080e7          	jalr	-1722(ra) # 80002e5e <initlock>
  freerange(end, (void*)PHYSTOP);
    80001520:	45c5                	li	a1,17
    80001522:	05ee                	sll	a1,a1,0x1b
    80001524:	00021517          	auipc	a0,0x21
    80001528:	e2450513          	add	a0,a0,-476 # 80022348 <end>
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	f86080e7          	jalr	-122(ra) # 800014b2 <freerange>
}
    80001534:	60a2                	ld	ra,8(sp)
    80001536:	6402                	ld	s0,0(sp)
    80001538:	0141                	add	sp,sp,16
    8000153a:	8082                	ret

000000008000153c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(bool in_kernel)
{
    8000153c:	1101                	add	sp,sp,-32
    8000153e:	ec06                	sd	ra,24(sp)
    80001540:	e822                	sd	s0,16(sp)
    80001542:	e426                	sd	s1,8(sp)
    80001544:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);  
    80001546:	00010497          	auipc	s1,0x10
    8000154a:	d2a48493          	add	s1,s1,-726 # 80011270 <kmem>
    8000154e:	8526                	mv	a0,s1
    80001550:	00002097          	auipc	ra,0x2
    80001554:	99e080e7          	jalr	-1634(ra) # 80002eee <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80001558:	6c84                	ld	s1,24(s1)
  if(r)
    8000155a:	c885                	beqz	s1,8000158a <kalloc+0x4e>
    kmem.freelist = r->next;
    8000155c:	609c                	ld	a5,0(s1)
    8000155e:	00010517          	auipc	a0,0x10
    80001562:	d1250513          	add	a0,a0,-750 # 80011270 <kmem>
    80001566:	ed1c                	sd	a5,24(a0)
  else 
    panic("kalloc: out of memory");
  release(&kmem.lock);
    80001568:	00002097          	auipc	ra,0x2
    8000156c:	a3a080e7          	jalr	-1478(ra) # 80002fa2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80001570:	6605                	lui	a2,0x1
    80001572:	4595                	li	a1,5
    80001574:	8526                	mv	a0,s1
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	a22080e7          	jalr	-1502(ra) # 80000f98 <memset>
  return (void*)r;
}
    8000157e:	8526                	mv	a0,s1
    80001580:	60e2                	ld	ra,24(sp)
    80001582:	6442                	ld	s0,16(sp)
    80001584:	64a2                	ld	s1,8(sp)
    80001586:	6105                	add	sp,sp,32
    80001588:	8082                	ret
    panic("kalloc: out of memory");
    8000158a:	00007517          	auipc	a0,0x7
    8000158e:	c8e50513          	add	a0,a0,-882 # 80008218 <digits+0x28>
    80001592:	00000097          	auipc	ra,0x0
    80001596:	c4e080e7          	jalr	-946(ra) # 800011e0 <panic>

000000008000159a <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    8000159a:	1141                	add	sp,sp,-16
    8000159c:	e422                	sd	s0,8(sp)
    8000159e:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800015a0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800015a4:	00008797          	auipc	a5,0x8
    800015a8:	8fc7b783          	ld	a5,-1796(a5) # 80008ea0 <kernel_pagetable>
    800015ac:	83b1                	srl	a5,a5,0xc
    800015ae:	577d                	li	a4,-1
    800015b0:	177e                	sll	a4,a4,0x3f
    800015b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800015b4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800015b8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800015bc:	6422                	ld	s0,8(sp)
    800015be:	0141                	add	sp,sp,16
    800015c0:	8082                	ret

00000000800015c2 <walk>:
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc) 
// 虚拟映射查询与建立
// 输入虚拟地址与对应的页表，返回该虚拟地址对应的最低级页表项地址
// alloc为0只查询，为1表示允许在遍历过程中为缺失的中间级页表分配一页。
{
    800015c2:	7139                	add	sp,sp,-64
    800015c4:	fc06                	sd	ra,56(sp)
    800015c6:	f822                	sd	s0,48(sp)
    800015c8:	f426                	sd	s1,40(sp)
    800015ca:	f04a                	sd	s2,32(sp)
    800015cc:	ec4e                	sd	s3,24(sp)
    800015ce:	e852                	sd	s4,16(sp)
    800015d0:	e456                	sd	s5,8(sp)
    800015d2:	e05a                	sd	s6,0(sp)
    800015d4:	0080                	add	s0,sp,64
    800015d6:	84aa                	mv	s1,a0
    800015d8:	89ae                	mv	s3,a1
    800015da:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800015dc:	57fd                	li	a5,-1
    800015de:	83e9                	srl	a5,a5,0x1a
    800015e0:	4a79                	li	s4,30
    panic("walk");
  for(int level = 2; level > 0; level--) {
    800015e2:	4b31                	li	s6,12
  if(va >= MAXVA)
    800015e4:	04b7f363          	bgeu	a5,a1,8000162a <walk+0x68>
    panic("walk");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	c4850513          	add	a0,a0,-952 # 80008230 <digits+0x40>
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	bf0080e7          	jalr	-1040(ra) # 800011e0 <panic>
    if(*pte & PTE_V) { // PTE有效
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
    } else {  // PTE无效，先判断是否可以写入
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
    800015f8:	060a8763          	beqz	s5,80001666 <walk+0xa4>
    800015fc:	4505                	li	a0,1
    800015fe:	00000097          	auipc	ra,0x0
    80001602:	f3e080e7          	jalr	-194(ra) # 8000153c <kalloc>
    80001606:	84aa                	mv	s1,a0
    80001608:	c529                	beqz	a0,80001652 <walk+0x90>
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
    8000160a:	6605                	lui	a2,0x1
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	98a080e7          	jalr	-1654(ra) # 80000f98 <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    80001616:	00c4d793          	srl	a5,s1,0xc
    8000161a:	07aa                	sll	a5,a5,0xa
    8000161c:	0017e793          	or	a5,a5,1
    80001620:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001624:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdccaf>
    80001626:	036a0063          	beq	s4,s6,80001646 <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    8000162a:	0149d933          	srl	s2,s3,s4
    8000162e:	1ff97913          	and	s2,s2,511
    80001632:	090e                	sll	s2,s2,0x3
    80001634:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) { // PTE有效
    80001636:	00093483          	ld	s1,0(s2)
    8000163a:	0014f793          	and	a5,s1,1
    8000163e:	dfcd                	beqz	a5,800015f8 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte); 
    80001640:	80a9                	srl	s1,s1,0xa
    80001642:	04b2                	sll	s1,s1,0xc
    80001644:	b7c5                	j	80001624 <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];  
    80001646:	00c9d513          	srl	a0,s3,0xc
    8000164a:	1ff57513          	and	a0,a0,511
    8000164e:	050e                	sll	a0,a0,0x3
    80001650:	9526                	add	a0,a0,s1
}
    80001652:	70e2                	ld	ra,56(sp)
    80001654:	7442                	ld	s0,48(sp)
    80001656:	74a2                	ld	s1,40(sp)
    80001658:	7902                	ld	s2,32(sp)
    8000165a:	69e2                	ld	s3,24(sp)
    8000165c:	6a42                	ld	s4,16(sp)
    8000165e:	6aa2                	ld	s5,8(sp)
    80001660:	6b02                	ld	s6,0(sp)
    80001662:	6121                	add	sp,sp,64
    80001664:	8082                	ret
        return 0; // 失败返回0
    80001666:	4501                	li	a0,0
    80001668:	b7ed                	j	80001652 <walk+0x90>

000000008000166a <mappages>:
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
    8000166a:	715d                	add	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001680:	03459793          	sll	a5,a1,0x34
    80001684:	e7b9                	bnez	a5,800016d2 <mappages+0x68>
    80001686:	8aaa                	mv	s5,a0
    80001688:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000168a:	03461793          	sll	a5,a2,0x34
    8000168e:	ebb1                	bnez	a5,800016e2 <mappages+0x78>
    panic("mappages: size not aligned");

  if(size == 0)
    80001690:	c22d                	beqz	a2,800016f2 <mappages+0x88>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
    80001692:	77fd                	lui	a5,0xfffff
    80001694:	963e                	add	a2,a2,a5
    80001696:	00b609b3          	add	s3,a2,a1
  a = va;
    8000169a:	892e                	mv	s2,a1
    8000169c:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    if(a == last)
      break;
    a += PGSIZE;
    800016a0:	6b85                	lui	s7,0x1
    800016a2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    800016a6:	4605                	li	a2,1
    800016a8:	85ca                	mv	a1,s2
    800016aa:	8556                	mv	a0,s5
    800016ac:	00000097          	auipc	ra,0x0
    800016b0:	f16080e7          	jalr	-234(ra) # 800015c2 <walk>
    800016b4:	cd39                	beqz	a0,80001712 <mappages+0xa8>
    if(*pte & PTE_V) // 重复映射
    800016b6:	611c                	ld	a5,0(a0)
    800016b8:	8b85                	and	a5,a5,1
    800016ba:	e7a1                	bnez	a5,80001702 <mappages+0x98>
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    800016bc:	80b1                	srl	s1,s1,0xc
    800016be:	04aa                	sll	s1,s1,0xa
    800016c0:	0164e4b3          	or	s1,s1,s6
    800016c4:	0014e493          	or	s1,s1,1
    800016c8:	e104                	sd	s1,0(a0)
    if(a == last)
    800016ca:	07390063          	beq	s2,s3,8000172a <mappages+0xc0>
    a += PGSIZE;
    800016ce:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    800016d0:	bfc9                	j	800016a2 <mappages+0x38>
    panic("mappages: va not aligned");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	b6650513          	add	a0,a0,-1178 # 80008238 <digits+0x48>
    800016da:	00000097          	auipc	ra,0x0
    800016de:	b06080e7          	jalr	-1274(ra) # 800011e0 <panic>
    panic("mappages: size not aligned");
    800016e2:	00007517          	auipc	a0,0x7
    800016e6:	b7650513          	add	a0,a0,-1162 # 80008258 <digits+0x68>
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	af6080e7          	jalr	-1290(ra) # 800011e0 <panic>
    panic("mappages: size");
    800016f2:	00007517          	auipc	a0,0x7
    800016f6:	b8650513          	add	a0,a0,-1146 # 80008278 <digits+0x88>
    800016fa:	00000097          	auipc	ra,0x0
    800016fe:	ae6080e7          	jalr	-1306(ra) # 800011e0 <panic>
      panic("mappages: remap");
    80001702:	00007517          	auipc	a0,0x7
    80001706:	b8650513          	add	a0,a0,-1146 # 80008288 <digits+0x98>
    8000170a:	00000097          	auipc	ra,0x0
    8000170e:	ad6080e7          	jalr	-1322(ra) # 800011e0 <panic>
      return -1;
    80001712:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001714:	60a6                	ld	ra,72(sp)
    80001716:	6406                	ld	s0,64(sp)
    80001718:	74e2                	ld	s1,56(sp)
    8000171a:	7942                	ld	s2,48(sp)
    8000171c:	79a2                	ld	s3,40(sp)
    8000171e:	7a02                	ld	s4,32(sp)
    80001720:	6ae2                	ld	s5,24(sp)
    80001722:	6b42                	ld	s6,16(sp)
    80001724:	6ba2                	ld	s7,8(sp)
    80001726:	6161                	add	sp,sp,80
    80001728:	8082                	ret
  return 0;
    8000172a:	4501                	li	a0,0
    8000172c:	b7e5                	j	80001714 <mappages+0xaa>

000000008000172e <kvmmap>:
{
    8000172e:	1141                	add	sp,sp,-16
    80001730:	e406                	sd	ra,8(sp)
    80001732:	e022                	sd	s0,0(sp)
    80001734:	0800                	add	s0,sp,16
    80001736:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001738:	86b2                	mv	a3,a2
    8000173a:	863e                	mv	a2,a5
    8000173c:	00000097          	auipc	ra,0x0
    80001740:	f2e080e7          	jalr	-210(ra) # 8000166a <mappages>
    80001744:	e509                	bnez	a0,8000174e <kvmmap+0x20>
}
    80001746:	60a2                	ld	ra,8(sp)
    80001748:	6402                	ld	s0,0(sp)
    8000174a:	0141                	add	sp,sp,16
    8000174c:	8082                	ret
    panic("kvmmap");
    8000174e:	00007517          	auipc	a0,0x7
    80001752:	b4a50513          	add	a0,a0,-1206 # 80008298 <digits+0xa8>
    80001756:	00000097          	auipc	ra,0x0
    8000175a:	a8a080e7          	jalr	-1398(ra) # 800011e0 <panic>

000000008000175e <kvmmake>:
{
    8000175e:	1101                	add	sp,sp,-32
    80001760:	ec06                	sd	ra,24(sp)
    80001762:	e822                	sd	s0,16(sp)
    80001764:	e426                	sd	s1,8(sp)
    80001766:	e04a                	sd	s2,0(sp)
    80001768:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc(true);
    8000176a:	4505                	li	a0,1
    8000176c:	00000097          	auipc	ra,0x0
    80001770:	dd0080e7          	jalr	-560(ra) # 8000153c <kalloc>
    80001774:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE); //关键清零
    80001776:	6605                	lui	a2,0x1
    80001778:	4581                	li	a1,0
    8000177a:	00000097          	auipc	ra,0x0
    8000177e:	81e080e7          	jalr	-2018(ra) # 80000f98 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001782:	4719                	li	a4,6
    80001784:	6685                	lui	a3,0x1
    80001786:	10000637          	lui	a2,0x10000
    8000178a:	100005b7          	lui	a1,0x10000
    8000178e:	8526                	mv	a0,s1
    80001790:	00000097          	auipc	ra,0x0
    80001794:	f9e080e7          	jalr	-98(ra) # 8000172e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001798:	4719                	li	a4,6
    8000179a:	6685                	lui	a3,0x1
    8000179c:	10001637          	lui	a2,0x10001
    800017a0:	100015b7          	lui	a1,0x10001
    800017a4:	8526                	mv	a0,s1
    800017a6:	00000097          	auipc	ra,0x0
    800017aa:	f88080e7          	jalr	-120(ra) # 8000172e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800017ae:	4719                	li	a4,6
    800017b0:	004006b7          	lui	a3,0x400
    800017b4:	0c000637          	lui	a2,0xc000
    800017b8:	0c0005b7          	lui	a1,0xc000
    800017bc:	8526                	mv	a0,s1
    800017be:	00000097          	auipc	ra,0x0
    800017c2:	f70080e7          	jalr	-144(ra) # 8000172e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800017c6:	00007917          	auipc	s2,0x7
    800017ca:	83a90913          	add	s2,s2,-1990 # 80008000 <etext>
    800017ce:	4729                	li	a4,10
    800017d0:	80007697          	auipc	a3,0x80007
    800017d4:	83068693          	add	a3,a3,-2000 # 8000 <_entry-0x7fff8000>
    800017d8:	4605                	li	a2,1
    800017da:	067e                	sll	a2,a2,0x1f
    800017dc:	85b2                	mv	a1,a2
    800017de:	8526                	mv	a0,s1
    800017e0:	00000097          	auipc	ra,0x0
    800017e4:	f4e080e7          	jalr	-178(ra) # 8000172e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800017e8:	4719                	li	a4,6
    800017ea:	46c5                	li	a3,17
    800017ec:	06ee                	sll	a3,a3,0x1b
    800017ee:	412686b3          	sub	a3,a3,s2
    800017f2:	864a                	mv	a2,s2
    800017f4:	85ca                	mv	a1,s2
    800017f6:	8526                	mv	a0,s1
    800017f8:	00000097          	auipc	ra,0x0
    800017fc:	f36080e7          	jalr	-202(ra) # 8000172e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001800:	4729                	li	a4,10
    80001802:	6685                	lui	a3,0x1
    80001804:	00005617          	auipc	a2,0x5
    80001808:	7fc60613          	add	a2,a2,2044 # 80007000 <_trampoline>
    8000180c:	040005b7          	lui	a1,0x4000
    80001810:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001812:	05b2                	sll	a1,a1,0xc
    80001814:	8526                	mv	a0,s1
    80001816:	00000097          	auipc	ra,0x0
    8000181a:	f18080e7          	jalr	-232(ra) # 8000172e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000181e:	8526                	mv	a0,s1
    80001820:	00001097          	auipc	ra,0x1
    80001824:	9b4080e7          	jalr	-1612(ra) # 800021d4 <proc_mapstacks>
}
    80001828:	8526                	mv	a0,s1
    8000182a:	60e2                	ld	ra,24(sp)
    8000182c:	6442                	ld	s0,16(sp)
    8000182e:	64a2                	ld	s1,8(sp)
    80001830:	6902                	ld	s2,0(sp)
    80001832:	6105                	add	sp,sp,32
    80001834:	8082                	ret

0000000080001836 <kvminit>:
{
    80001836:	1141                	add	sp,sp,-16
    80001838:	e406                	sd	ra,8(sp)
    8000183a:	e022                	sd	s0,0(sp)
    8000183c:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    8000183e:	00000097          	auipc	ra,0x0
    80001842:	f20080e7          	jalr	-224(ra) # 8000175e <kvmmake>
    80001846:	00007797          	auipc	a5,0x7
    8000184a:	64a7bd23          	sd	a0,1626(a5) # 80008ea0 <kernel_pagetable>
}
    8000184e:	60a2                	ld	ra,8(sp)
    80001850:	6402                	ld	s0,0(sp)
    80001852:	0141                	add	sp,sp,16
    80001854:	8082                	ret

0000000080001856 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    80001856:	57fd                	li	a5,-1
    80001858:	83e9                	srl	a5,a5,0x1a
    8000185a:	00b7f463          	bgeu	a5,a1,80001862 <walkaddr+0xc>
    return 0;
    8000185e:	4501                	li	a0,0
  if (!is_user_accessible_page(*pte))
    return 0;

  pa = PTE2PA(*pte);
  return pa;
}
    80001860:	8082                	ret
{
    80001862:	1141                	add	sp,sp,-16
    80001864:	e406                	sd	ra,8(sp)
    80001866:	e022                	sd	s0,0(sp)
    80001868:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000186a:	4601                	li	a2,0
    8000186c:	00000097          	auipc	ra,0x0
    80001870:	d56080e7          	jalr	-682(ra) # 800015c2 <walk>
  if (pte == 0)
    80001874:	cd19                	beqz	a0,80001892 <walkaddr+0x3c>
  if (!is_user_accessible_page(*pte))
    80001876:	611c                	ld	a5,0(a0)
  return (pte & PTE_V) && (pte & PTE_U);
    80001878:	0117f693          	and	a3,a5,17
  if (!is_user_accessible_page(*pte))
    8000187c:	4745                	li	a4,17
    return 0;
    8000187e:	4501                	li	a0,0
  if (!is_user_accessible_page(*pte))
    80001880:	00e69563          	bne	a3,a4,8000188a <walkaddr+0x34>
  pa = PTE2PA(*pte);
    80001884:	83a9                	srl	a5,a5,0xa
    80001886:	00c79513          	sll	a0,a5,0xc
}
    8000188a:	60a2                	ld	ra,8(sp)
    8000188c:	6402                	ld	s0,0(sp)
    8000188e:	0141                	add	sp,sp,16
    80001890:	8082                	ret
    return 0;
    80001892:	4501                	li	a0,0
    80001894:	bfdd                	j	8000188a <walkaddr+0x34>

0000000080001896 <freewalk>:
#define PAGE_TABLE_ENTRIES 512

// 递归释放页表页面
// 所有叶子映射必须已经被移除
void freewalk(pagetable_t pagetable)
{
    80001896:	7179                	add	sp,sp,-48
    80001898:	f406                	sd	ra,40(sp)
    8000189a:	f022                	sd	s0,32(sp)
    8000189c:	ec26                	sd	s1,24(sp)
    8000189e:	e84a                	sd	s2,16(sp)
    800018a0:	e44e                	sd	s3,8(sp)
    800018a2:	e052                	sd	s4,0(sp)
    800018a4:	1800                	add	s0,sp,48
    800018a6:	8a2a                	mv	s4,a0
  // 遍历页表中的所有PTE
  for (int i = 0; i < PAGE_TABLE_ENTRIES; i++)
    800018a8:	6905                	lui	s2,0x1
    800018aa:	992a                	add	s2,s2,a0
{
    800018ac:	84aa                	mv	s1,a0
    800018ae:	a821                	j	800018c6 <freewalk+0x30>
      pagetable[i] = 0;
    }
    else if (is_pte_valid(pte))
    {
      // 发现叶子页面，应该已经被清理
      panic("freewalk: found unexpected leaf page");
    800018b0:	00007517          	auipc	a0,0x7
    800018b4:	9f050513          	add	a0,a0,-1552 # 800082a0 <digits+0xb0>
    800018b8:	00000097          	auipc	ra,0x0
    800018bc:	928080e7          	jalr	-1752(ra) # 800011e0 <panic>
  for (int i = 0; i < PAGE_TABLE_ENTRIES; i++)
    800018c0:	04a1                	add	s1,s1,8
    800018c2:	03248363          	beq	s1,s2,800018e8 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800018c6:	609c                	ld	a5,0(s1)
  return (pte & PTE_V) != 0;
    800018c8:	0017f713          	and	a4,a5,1
  return is_pte_valid(pte) && !is_pte_leaf(pte);
    800018cc:	db75                	beqz	a4,800018c0 <freewalk+0x2a>
  return (pte & (PTE_R | PTE_W | PTE_X)) != 0;
    800018ce:	00e7f713          	and	a4,a5,14
  return is_pte_valid(pte) && !is_pte_leaf(pte);
    800018d2:	ff79                	bnez	a4,800018b0 <freewalk+0x1a>
  return PTE2PA(pte);
    800018d4:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child_pa);
    800018d6:	00c79513          	sll	a0,a5,0xc
    800018da:	00000097          	auipc	ra,0x0
    800018de:	fbc080e7          	jalr	-68(ra) # 80001896 <freewalk>
      pagetable[i] = 0;
    800018e2:	0004b023          	sd	zero,0(s1)
    800018e6:	bfe9                	j	800018c0 <freewalk+0x2a>
    }
  }

  // 释放当前页表页面
  kfree((uint64)pagetable, true);
    800018e8:	4585                	li	a1,1
    800018ea:	8552                	mv	a0,s4
    800018ec:	00000097          	auipc	ra,0x0
    800018f0:	b50080e7          	jalr	-1200(ra) # 8000143c <kfree>
}
    800018f4:	70a2                	ld	ra,40(sp)
    800018f6:	7402                	ld	s0,32(sp)
    800018f8:	64e2                	ld	s1,24(sp)
    800018fa:	6942                	ld	s2,16(sp)
    800018fc:	69a2                	ld	s3,8(sp)
    800018fe:	6a02                	ld	s4,0(sp)
    80001900:	6145                	add	sp,sp,48
    80001902:	8082                	ret

0000000080001904 <print_pgtbl>:

void print_pgtbl(pagetable_t pagetable, int level) {
    80001904:	711d                	add	sp,sp,-96
    80001906:	ec86                	sd	ra,88(sp)
    80001908:	e8a2                	sd	s0,80(sp)
    8000190a:	e4a6                	sd	s1,72(sp)
    8000190c:	e0ca                	sd	s2,64(sp)
    8000190e:	fc4e                	sd	s3,56(sp)
    80001910:	f852                	sd	s4,48(sp)
    80001912:	f456                	sd	s5,40(sp)
    80001914:	f05a                	sd	s6,32(sp)
    80001916:	ec5e                	sd	s7,24(sp)
    80001918:	e862                	sd	s8,16(sp)
    8000191a:	e466                	sd	s9,8(sp)
    8000191c:	e06a                	sd	s10,0(sp)
    8000191e:	1080                	add	s0,sp,96
    80001920:	8aae                	mv	s5,a1
  //递归打印页表
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001922:	8a2a                	mv	s4,a0
    80001924:	4981                	li	s3,0
    if(pte & PTE_V) {// 打印有效的页表项

      for(int j = 0; j < level; j++)
        printf("  ");

      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    80001926:	00007c17          	auipc	s8,0x7
    8000192a:	9aac0c13          	add	s8,s8,-1622 # 800082d0 <digits+0xe0>

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
    8000192e:	00007d17          	auipc	s10,0x7
    80001932:	9bad0d13          	add	s10,s10,-1606 # 800082e8 <digits+0xf8>
      for(int j = 0; j < level; j++)
    80001936:	4c81                	li	s9,0
        printf("  ");
    80001938:	00007b17          	auipc	s6,0x7
    8000193c:	990b0b13          	add	s6,s6,-1648 # 800082c8 <digits+0xd8>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001940:	20000b93          	li	s7,512
    80001944:	a025                	j	8000196c <print_pgtbl+0x68>
      } 
      else {
        printf("\n");
    80001946:	00007517          	auipc	a0,0x7
    8000194a:	36250513          	add	a0,a0,866 # 80008ca8 <syscalls+0x540>
    8000194e:	00000097          	auipc	ra,0x0
    80001952:	8dc080e7          	jalr	-1828(ra) # 8000122a <printf>
        print_pgtbl((pagetable_t)PTE2PA(pte), level + 1);
    80001956:	001a859b          	addw	a1,s5,1
    8000195a:	8526                	mv	a0,s1
    8000195c:	00000097          	auipc	ra,0x0
    80001960:	fa8080e7          	jalr	-88(ra) # 80001904 <print_pgtbl>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001964:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    80001966:	0a21                	add	s4,s4,8
    80001968:	05798763          	beq	s3,s7,800019b6 <print_pgtbl+0xb2>
    pte_t pte = pagetable[i];
    8000196c:	000a3903          	ld	s2,0(s4)
    if(pte & PTE_V) {// 打印有效的页表项
    80001970:	00197793          	and	a5,s2,1
    80001974:	dbe5                	beqz	a5,80001964 <print_pgtbl+0x60>
      for(int j = 0; j < level; j++)
    80001976:	01505b63          	blez	s5,8000198c <print_pgtbl+0x88>
    8000197a:	84e6                	mv	s1,s9
        printf("  ");
    8000197c:	855a                	mv	a0,s6
    8000197e:	00000097          	auipc	ra,0x0
    80001982:	8ac080e7          	jalr	-1876(ra) # 8000122a <printf>
      for(int j = 0; j < level; j++)
    80001986:	2485                	addw	s1,s1,1
    80001988:	fe9a9ae3          	bne	s5,s1,8000197c <print_pgtbl+0x78>
      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    8000198c:	00a95493          	srl	s1,s2,0xa
    80001990:	04b2                	sll	s1,s1,0xc
    80001992:	86a6                	mv	a3,s1
    80001994:	864a                	mv	a2,s2
    80001996:	85ce                	mv	a1,s3
    80001998:	8562                	mv	a0,s8
    8000199a:	00000097          	auipc	ra,0x0
    8000199e:	890080e7          	jalr	-1904(ra) # 8000122a <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    800019a2:	00e97913          	and	s2,s2,14
    800019a6:	fa0900e3          	beqz	s2,80001946 <print_pgtbl+0x42>
        printf(" [leaf]\n");
    800019aa:	856a                	mv	a0,s10
    800019ac:	00000097          	auipc	ra,0x0
    800019b0:	87e080e7          	jalr	-1922(ra) # 8000122a <printf>
    800019b4:	bf45                	j	80001964 <print_pgtbl+0x60>
      }
    }
  }
}
    800019b6:	60e6                	ld	ra,88(sp)
    800019b8:	6446                	ld	s0,80(sp)
    800019ba:	64a6                	ld	s1,72(sp)
    800019bc:	6906                	ld	s2,64(sp)
    800019be:	79e2                	ld	s3,56(sp)
    800019c0:	7a42                	ld	s4,48(sp)
    800019c2:	7aa2                	ld	s5,40(sp)
    800019c4:	7b02                	ld	s6,32(sp)
    800019c6:	6be2                	ld	s7,24(sp)
    800019c8:	6c42                	ld	s8,16(sp)
    800019ca:	6ca2                	ld	s9,8(sp)
    800019cc:	6d02                	ld	s10,0(sp)
    800019ce:	6125                	add	sp,sp,96
    800019d0:	8082                	ret

00000000800019d2 <print_cur_pgtbl>:

void print_cur_pgtbl(pagetable_t pagetable) {
    800019d2:	715d                	add	sp,sp,-80
    800019d4:	e486                	sd	ra,72(sp)
    800019d6:	e0a2                	sd	s0,64(sp)
    800019d8:	fc26                	sd	s1,56(sp)
    800019da:	f84a                	sd	s2,48(sp)
    800019dc:	f44e                	sd	s3,40(sp)
    800019de:	f052                	sd	s4,32(sp)
    800019e0:	ec56                	sd	s5,24(sp)
    800019e2:	e85a                	sd	s6,16(sp)
    800019e4:	e45e                	sd	s7,8(sp)
    800019e6:	0880                	add	s0,sp,80
    800019e8:	89aa                	mv	s3,a0
  //打印当前层页表
  printf("page table %p\n", pagetable);
    800019ea:	85aa                	mv	a1,a0
    800019ec:	00007517          	auipc	a0,0x7
    800019f0:	90c50513          	add	a0,a0,-1780 # 800082f8 <digits+0x108>
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	836080e7          	jalr	-1994(ra) # 8000122a <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    800019fc:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    800019fe:	00007a97          	auipc	s5,0x7
    80001a02:	90aa8a93          	add	s5,s5,-1782 # 80008308 <digits+0x118>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
    80001a06:	00007b97          	auipc	s7,0x7
    80001a0a:	2a2b8b93          	add	s7,s7,674 # 80008ca8 <syscalls+0x540>
        printf(" [leaf]\n");
    80001a0e:	00007b17          	auipc	s6,0x7
    80001a12:	8dab0b13          	add	s6,s6,-1830 # 800082e8 <digits+0xf8>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001a16:	20000a13          	li	s4,512
    80001a1a:	a811                	j	80001a2e <print_cur_pgtbl+0x5c>
        printf("\n");
    80001a1c:	855e                	mv	a0,s7
    80001a1e:	00000097          	auipc	ra,0x0
    80001a22:	80c080e7          	jalr	-2036(ra) # 8000122a <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001a26:	2905                	addw	s2,s2,1 # 1001 <_entry-0x7fffefff>
    80001a28:	09a1                	add	s3,s3,8
    80001a2a:	03490963          	beq	s2,s4,80001a5c <print_cur_pgtbl+0x8a>
    pte_t pte = pagetable[i];
    80001a2e:	0009b483          	ld	s1,0(s3)
    if(pte & PTE_V) {// 打印有效的页表项
    80001a32:	0014f793          	and	a5,s1,1
    80001a36:	dbe5                	beqz	a5,80001a26 <print_cur_pgtbl+0x54>
      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80001a38:	00a4d693          	srl	a3,s1,0xa
    80001a3c:	06b2                	sll	a3,a3,0xc
    80001a3e:	8626                	mv	a2,s1
    80001a40:	85ca                	mv	a1,s2
    80001a42:	8556                	mv	a0,s5
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	7e6080e7          	jalr	2022(ra) # 8000122a <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80001a4c:	88b9                	and	s1,s1,14
    80001a4e:	d4f9                	beqz	s1,80001a1c <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80001a50:	855a                	mv	a0,s6
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	7d8080e7          	jalr	2008(ra) # 8000122a <printf>
    80001a5a:	b7f1                	j	80001a26 <print_cur_pgtbl+0x54>
      }
    }
  }
    80001a5c:	60a6                	ld	ra,72(sp)
    80001a5e:	6406                	ld	s0,64(sp)
    80001a60:	74e2                	ld	s1,56(sp)
    80001a62:	7942                	ld	s2,48(sp)
    80001a64:	79a2                	ld	s3,40(sp)
    80001a66:	7a02                	ld	s4,32(sp)
    80001a68:	6ae2                	ld	s5,24(sp)
    80001a6a:	6b42                	ld	s6,16(sp)
    80001a6c:	6ba2                	ld	s7,8(sp)
    80001a6e:	6161                	add	sp,sp,80
    80001a70:	8082                	ret

0000000080001a72 <uvmcreate>:


// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
    80001a72:	1101                	add	sp,sp,-32
    80001a74:	ec06                	sd	ra,24(sp)
    80001a76:	e822                	sd	s0,16(sp)
    80001a78:	e426                	sd	s1,8(sp)
    80001a7a:	1000                	add	s0,sp,32
  pagetable_t pagetable = (pagetable_t)kalloc(true);
    80001a7c:	4505                	li	a0,1
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	abe080e7          	jalr	-1346(ra) # 8000153c <kalloc>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable)
    80001a88:	c519                	beqz	a0,80001a96 <uvmcreate+0x24>
    memset(pagetable, 0, PGSIZE);
    80001a8a:	6605                	lui	a2,0x1
    80001a8c:	4581                	li	a1,0
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	50a080e7          	jalr	1290(ra) # 80000f98 <memset>
  return pagetable;
}
    80001a96:	8526                	mv	a0,s1
    80001a98:	60e2                	ld	ra,24(sp)
    80001a9a:	6442                	ld	s0,16(sp)
    80001a9c:	64a2                	ld	s1,8(sp)
    80001a9e:	6105                	add	sp,sp,32
    80001aa0:	8082                	ret

0000000080001aa2 <uvmfirst>:

void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001aa2:	7179                	add	sp,sp,-48
    80001aa4:	f406                	sd	ra,40(sp)
    80001aa6:	f022                	sd	s0,32(sp)
    80001aa8:	ec26                	sd	s1,24(sp)
    80001aaa:	e84a                	sd	s2,16(sp)
    80001aac:	e44e                	sd	s3,8(sp)
    80001aae:	e052                	sd	s4,0(sp)
    80001ab0:	1800                	add	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001ab2:	6785                	lui	a5,0x1
    80001ab4:	04f67963          	bgeu	a2,a5,80001b06 <uvmfirst+0x64>
    80001ab8:	8a2a                	mv	s4,a0
    80001aba:	89ae                	mv	s3,a1
    80001abc:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc(1);
    80001abe:	4505                	li	a0,1
    80001ac0:	00000097          	auipc	ra,0x0
    80001ac4:	a7c080e7          	jalr	-1412(ra) # 8000153c <kalloc>
    80001ac8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001aca:	6605                	lui	a2,0x1
    80001acc:	4581                	li	a1,0
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	4ca080e7          	jalr	1226(ra) # 80000f98 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001ad6:	4779                	li	a4,30
    80001ad8:	86ca                	mv	a3,s2
    80001ada:	6605                	lui	a2,0x1
    80001adc:	4581                	li	a1,0
    80001ade:	8552                	mv	a0,s4
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	b8a080e7          	jalr	-1142(ra) # 8000166a <mappages>
  memmove(mem, src, sz);
    80001ae8:	8626                	mv	a2,s1
    80001aea:	85ce                	mv	a1,s3
    80001aec:	854a                	mv	a0,s2
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	506080e7          	jalr	1286(ra) # 80000ff4 <memmove>
}
    80001af6:	70a2                	ld	ra,40(sp)
    80001af8:	7402                	ld	s0,32(sp)
    80001afa:	64e2                	ld	s1,24(sp)
    80001afc:	6942                	ld	s2,16(sp)
    80001afe:	69a2                	ld	s3,8(sp)
    80001b00:	6a02                	ld	s4,0(sp)
    80001b02:	6145                	add	sp,sp,48
    80001b04:	8082                	ret
    panic("uvmfirst: more than a page");
    80001b06:	00007517          	auipc	a0,0x7
    80001b0a:	82250513          	add	a0,a0,-2014 # 80008328 <digits+0x138>
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	6d2080e7          	jalr	1746(ra) # 800011e0 <panic>

0000000080001b16 <uvmunmap>:

// 从va开始移除npages个映射。va必须是
// 页面对齐的。映射必须存在。
// 可选择释放物理内存
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001b16:	715d                	add	sp,sp,-80
    80001b18:	e486                	sd	ra,72(sp)
    80001b1a:	e0a2                	sd	s0,64(sp)
    80001b1c:	fc26                	sd	s1,56(sp)
    80001b1e:	f84a                	sd	s2,48(sp)
    80001b20:	f44e                	sd	s3,40(sp)
    80001b22:	f052                	sd	s4,32(sp)
    80001b24:	ec56                	sd	s5,24(sp)
    80001b26:	e85a                	sd	s6,16(sp)
    80001b28:	e45e                	sd	s7,8(sp)
    80001b2a:	0880                	add	s0,sp,80
  return (addr % PGSIZE) == 0;
    80001b2c:	03459793          	sll	a5,a1,0x34
  uint64 current_va;
  pte_t *pte;

  if (!is_page_aligned(va))
    80001b30:	e795                	bnez	a5,80001b5c <uvmunmap+0x46>
    80001b32:	8a2a                	mv	s4,a0
    80001b34:	892e                	mv	s2,a1
    80001b36:	8ab6                	mv	s5,a3
    panic("uvmunmap: address not page aligned");

  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    80001b38:	0632                	sll	a2,a2,0xc
    80001b3a:	00b609b3          	add	s3,a2,a1
  if (PTE_FLAGS(pte) == PTE_V)
    80001b3e:	4b05                	li	s6,1
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    80001b40:	6b85                	lui	s7,0x1
    80001b42:	0735e263          	bltu	a1,s3,80001ba6 <uvmunmap+0x90>
      free_physical_page_from_pte(*pte);
    }

    clear_pte(pte);
  }
}
    80001b46:	60a6                	ld	ra,72(sp)
    80001b48:	6406                	ld	s0,64(sp)
    80001b4a:	74e2                	ld	s1,56(sp)
    80001b4c:	7942                	ld	s2,48(sp)
    80001b4e:	79a2                	ld	s3,40(sp)
    80001b50:	7a02                	ld	s4,32(sp)
    80001b52:	6ae2                	ld	s5,24(sp)
    80001b54:	6b42                	ld	s6,16(sp)
    80001b56:	6ba2                	ld	s7,8(sp)
    80001b58:	6161                	add	sp,sp,80
    80001b5a:	8082                	ret
    panic("uvmunmap: address not page aligned");
    80001b5c:	00006517          	auipc	a0,0x6
    80001b60:	7ec50513          	add	a0,a0,2028 # 80008348 <digits+0x158>
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	67c080e7          	jalr	1660(ra) # 800011e0 <panic>
      panic("uvmunmap: walk failed");
    80001b6c:	00007517          	auipc	a0,0x7
    80001b70:	80450513          	add	a0,a0,-2044 # 80008370 <digits+0x180>
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	66c080e7          	jalr	1644(ra) # 800011e0 <panic>
    panic("uvmunmap: page not mapped");
    80001b7c:	00007517          	auipc	a0,0x7
    80001b80:	80c50513          	add	a0,a0,-2036 # 80008388 <digits+0x198>
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	65c080e7          	jalr	1628(ra) # 800011e0 <panic>
    panic("uvmunmap: not a leaf page");
    80001b8c:	00007517          	auipc	a0,0x7
    80001b90:	81c50513          	add	a0,a0,-2020 # 800083a8 <digits+0x1b8>
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	64c080e7          	jalr	1612(ra) # 800011e0 <panic>
  *pte = 0;
    80001b9c:	0004b023          	sd	zero,0(s1)
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    80001ba0:	995e                	add	s2,s2,s7
    80001ba2:	fb3972e3          	bgeu	s2,s3,80001b46 <uvmunmap+0x30>
    pte = walk(pagetable, current_va, 0);
    80001ba6:	4601                	li	a2,0
    80001ba8:	85ca                	mv	a1,s2
    80001baa:	8552                	mv	a0,s4
    80001bac:	00000097          	auipc	ra,0x0
    80001bb0:	a16080e7          	jalr	-1514(ra) # 800015c2 <walk>
    80001bb4:	84aa                	mv	s1,a0
    if (pte == 0)
    80001bb6:	d95d                	beqz	a0,80001b6c <uvmunmap+0x56>
    validate_page_mapping(*pte);
    80001bb8:	611c                	ld	a5,0(a0)
  return (pte & PTE_V) != 0;
    80001bba:	0017f713          	and	a4,a5,1
  if (!is_pte_valid(pte))
    80001bbe:	df5d                	beqz	a4,80001b7c <uvmunmap+0x66>
  if (PTE_FLAGS(pte) == PTE_V)
    80001bc0:	3ff7f713          	and	a4,a5,1023
    80001bc4:	fd6704e3          	beq	a4,s6,80001b8c <uvmunmap+0x76>
    if (do_free)
    80001bc8:	fc0a8ae3          	beqz	s5,80001b9c <uvmunmap+0x86>
  uint64 pa = PTE2PA(pte);
    80001bcc:	83a9                	srl	a5,a5,0xa
  kfree(pa,0);
    80001bce:	4581                	li	a1,0
    80001bd0:	00c79513          	sll	a0,a5,0xc
    80001bd4:	00000097          	auipc	ra,0x0
    80001bd8:	868080e7          	jalr	-1944(ra) # 8000143c <kfree>
}
    80001bdc:	b7c1                	j	80001b9c <uvmunmap+0x86>

0000000080001bde <uvmdealloc>:
{
    80001bde:	1101                	add	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	1000                	add	s0,sp,32
    return oldsz;
    80001be8:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    80001bea:	00b67d63          	bgeu	a2,a1,80001c04 <uvmdealloc+0x26>
    80001bee:	84b2                	mv	s1,a2
  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001bf0:	6785                	lui	a5,0x1
    80001bf2:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001bf4:	00f60733          	add	a4,a2,a5
    80001bf8:	76fd                	lui	a3,0xfffff
    80001bfa:	8f75                	and	a4,a4,a3
    80001bfc:	97ae                	add	a5,a5,a1
    80001bfe:	8ff5                	and	a5,a5,a3
    80001c00:	00f76863          	bltu	a4,a5,80001c10 <uvmdealloc+0x32>
}
    80001c04:	8526                	mv	a0,s1
    80001c06:	60e2                	ld	ra,24(sp)
    80001c08:	6442                	ld	s0,16(sp)
    80001c0a:	64a2                	ld	s1,8(sp)
    80001c0c:	6105                	add	sp,sp,32
    80001c0e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001c10:	8f99                	sub	a5,a5,a4
    80001c12:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001c14:	4685                	li	a3,1
    80001c16:	0007861b          	sext.w	a2,a5
    80001c1a:	85ba                	mv	a1,a4
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	efa080e7          	jalr	-262(ra) # 80001b16 <uvmunmap>
    80001c24:	b7c5                	j	80001c04 <uvmdealloc+0x26>

0000000080001c26 <uvmalloc>:
  if (newsz < oldsz)
    80001c26:	0ab66763          	bltu	a2,a1,80001cd4 <uvmalloc+0xae>
{
    80001c2a:	7139                	add	sp,sp,-64
    80001c2c:	fc06                	sd	ra,56(sp)
    80001c2e:	f822                	sd	s0,48(sp)
    80001c30:	f426                	sd	s1,40(sp)
    80001c32:	f04a                	sd	s2,32(sp)
    80001c34:	ec4e                	sd	s3,24(sp)
    80001c36:	e852                	sd	s4,16(sp)
    80001c38:	e456                	sd	s5,8(sp)
    80001c3a:	e05a                	sd	s6,0(sp)
    80001c3c:	0080                	add	s0,sp,64
    80001c3e:	8aaa                	mv	s5,a0
    80001c40:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001c42:	6785                	lui	a5,0x1
    80001c44:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001c46:	95be                	add	a1,a1,a5
    80001c48:	77fd                	lui	a5,0xfffff
    80001c4a:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001c4e:	08c9f563          	bgeu	s3,a2,80001cd8 <uvmalloc+0xb2>
    80001c52:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001c54:	0126eb13          	or	s6,a3,18
    mem = kalloc(0);
    80001c58:	4501                	li	a0,0
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	8e2080e7          	jalr	-1822(ra) # 8000153c <kalloc>
    80001c62:	84aa                	mv	s1,a0
    if (mem == 0)
    80001c64:	c51d                	beqz	a0,80001c92 <uvmalloc+0x6c>
    memset(mem, 0, PGSIZE);
    80001c66:	6605                	lui	a2,0x1
    80001c68:	4581                	li	a1,0
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	32e080e7          	jalr	814(ra) # 80000f98 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001c72:	875a                	mv	a4,s6
    80001c74:	86a6                	mv	a3,s1
    80001c76:	6605                	lui	a2,0x1
    80001c78:	85ca                	mv	a1,s2
    80001c7a:	8556                	mv	a0,s5
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	9ee080e7          	jalr	-1554(ra) # 8000166a <mappages>
    80001c84:	e90d                	bnez	a0,80001cb6 <uvmalloc+0x90>
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001c86:	6785                	lui	a5,0x1
    80001c88:	993e                	add	s2,s2,a5
    80001c8a:	fd4967e3          	bltu	s2,s4,80001c58 <uvmalloc+0x32>
  return newsz;
    80001c8e:	8552                	mv	a0,s4
    80001c90:	a809                	j	80001ca2 <uvmalloc+0x7c>
      uvmdealloc(pagetable, a, oldsz);
    80001c92:	864e                	mv	a2,s3
    80001c94:	85ca                	mv	a1,s2
    80001c96:	8556                	mv	a0,s5
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	f46080e7          	jalr	-186(ra) # 80001bde <uvmdealloc>
      return 0;
    80001ca0:	4501                	li	a0,0
}
    80001ca2:	70e2                	ld	ra,56(sp)
    80001ca4:	7442                	ld	s0,48(sp)
    80001ca6:	74a2                	ld	s1,40(sp)
    80001ca8:	7902                	ld	s2,32(sp)
    80001caa:	69e2                	ld	s3,24(sp)
    80001cac:	6a42                	ld	s4,16(sp)
    80001cae:	6aa2                	ld	s5,8(sp)
    80001cb0:	6b02                	ld	s6,0(sp)
    80001cb2:	6121                	add	sp,sp,64
    80001cb4:	8082                	ret
      kfree((uint64)mem,0);
    80001cb6:	4581                	li	a1,0
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	782080e7          	jalr	1922(ra) # 8000143c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001cc2:	864e                	mv	a2,s3
    80001cc4:	85ca                	mv	a1,s2
    80001cc6:	8556                	mv	a0,s5
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	f16080e7          	jalr	-234(ra) # 80001bde <uvmdealloc>
      return 0;
    80001cd0:	4501                	li	a0,0
    80001cd2:	bfc1                	j	80001ca2 <uvmalloc+0x7c>
    return oldsz;
    80001cd4:	852e                	mv	a0,a1
}
    80001cd6:	8082                	ret
  return newsz;
    80001cd8:	8532                	mv	a0,a2
    80001cda:	b7e1                	j	80001ca2 <uvmalloc+0x7c>

0000000080001cdc <uvm_copyin>:
// 成功返回0，失败返回-1
int uvm_copyin(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001cdc:	cebd                	beqz	a3,80001d5a <uvm_copyin+0x7e>
{
    80001cde:	711d                	add	sp,sp,-96
    80001ce0:	ec86                	sd	ra,88(sp)
    80001ce2:	e8a2                	sd	s0,80(sp)
    80001ce4:	e4a6                	sd	s1,72(sp)
    80001ce6:	e0ca                	sd	s2,64(sp)
    80001ce8:	fc4e                	sd	s3,56(sp)
    80001cea:	f852                	sd	s4,48(sp)
    80001cec:	f456                	sd	s5,40(sp)
    80001cee:	f05a                	sd	s6,32(sp)
    80001cf0:	ec5e                	sd	s7,24(sp)
    80001cf2:	e862                	sd	s8,16(sp)
    80001cf4:	e466                	sd	s9,8(sp)
    80001cf6:	e06a                	sd	s10,0(sp)
    80001cf8:	1080                	add	s0,sp,96
    80001cfa:	8b2a                	mv	s6,a0
    80001cfc:	89ae                	mv	s3,a1
    80001cfe:	84b2                	mv	s1,a2
    80001d00:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(srcva);
    80001d02:	7bfd                	lui	s7,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001d04:	6a85                	lui	s5,0x1
    80001d06:	fffa8c13          	add	s8,s5,-1 # fff <_entry-0x7ffff001>
    80001d0a:	a015                	j	80001d2e <uvm_copyin+0x52>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove((void *)dst, (void *)(page_pa + src_offset), bytes_to_copy);
    80001d0c:	000c8d1b          	sext.w	s10,s9
    80001d10:	866a                	mv	a2,s10
    80001d12:	009505b3          	add	a1,a0,s1
    80001d16:	854e                	mv	a0,s3
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	2dc080e7          	jalr	732(ra) # 80000ff4 <memmove>

    len -= bytes_to_copy;
    80001d20:	41a9093b          	subw	s2,s2,s10
    dst += bytes_to_copy;
    80001d24:	99e6                	add	s3,s3,s9
    srcva = page_va + PGSIZE; // 移到下一页
    80001d26:	015a04b3          	add	s1,s4,s5
  while (len > 0)
    80001d2a:	02090663          	beqz	s2,80001d56 <uvm_copyin+0x7a>
    page_va = PGROUNDDOWN(srcva);
    80001d2e:	0174fa33          	and	s4,s1,s7
    page_pa = walkaddr(pgtbl, page_va);
    80001d32:	85d2                	mv	a1,s4
    80001d34:	855a                	mv	a0,s6
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	b20080e7          	jalr	-1248(ra) # 80001856 <walkaddr>
    if (page_pa == 0)
    80001d3e:	c105                	beqz	a0,80001d5e <uvm_copyin+0x82>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001d40:	0184f4b3          	and	s1,s1,s8
    bytes_to_copy = bytes_to_copy_in_page(srcva, len);
    80001d44:	02091793          	sll	a5,s2,0x20
    80001d48:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001d4a:	409a8cb3          	sub	s9,s5,s1
    80001d4e:	fb97ffe3          	bgeu	a5,s9,80001d0c <uvm_copyin+0x30>
    80001d52:	8cbe                	mv	s9,a5
    80001d54:	bf65                	j	80001d0c <uvm_copyin+0x30>
  }
  return 0;
    80001d56:	4501                	li	a0,0
    80001d58:	a021                	j	80001d60 <uvm_copyin+0x84>
    80001d5a:	4501                	li	a0,0
}
    80001d5c:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001d5e:	557d                	li	a0,-1
}
    80001d60:	60e6                	ld	ra,88(sp)
    80001d62:	6446                	ld	s0,80(sp)
    80001d64:	64a6                	ld	s1,72(sp)
    80001d66:	6906                	ld	s2,64(sp)
    80001d68:	79e2                	ld	s3,56(sp)
    80001d6a:	7a42                	ld	s4,48(sp)
    80001d6c:	7aa2                	ld	s5,40(sp)
    80001d6e:	7b02                	ld	s6,32(sp)
    80001d70:	6be2                	ld	s7,24(sp)
    80001d72:	6c42                	ld	s8,16(sp)
    80001d74:	6ca2                	ld	s9,8(sp)
    80001d76:	6d02                	ld	s10,0(sp)
    80001d78:	6125                	add	sp,sp,96
    80001d7a:	8082                	ret

0000000080001d7c <uvm_copyout>:
// 成功返回0，失败返回-1
int uvm_copyout(pgtbl_t pgtbl, uint64 dstva, uint64 src, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001d7c:	ceb5                	beqz	a3,80001df8 <uvm_copyout+0x7c>
{
    80001d7e:	711d                	add	sp,sp,-96
    80001d80:	ec86                	sd	ra,88(sp)
    80001d82:	e8a2                	sd	s0,80(sp)
    80001d84:	e4a6                	sd	s1,72(sp)
    80001d86:	e0ca                	sd	s2,64(sp)
    80001d88:	fc4e                	sd	s3,56(sp)
    80001d8a:	f852                	sd	s4,48(sp)
    80001d8c:	f456                	sd	s5,40(sp)
    80001d8e:	f05a                	sd	s6,32(sp)
    80001d90:	ec5e                	sd	s7,24(sp)
    80001d92:	e862                	sd	s8,16(sp)
    80001d94:	e466                	sd	s9,8(sp)
    80001d96:	e06a                	sd	s10,0(sp)
    80001d98:	1080                	add	s0,sp,96
    80001d9a:	8baa                	mv	s7,a0
    80001d9c:	84ae                	mv	s1,a1
    80001d9e:	89b2                	mv	s3,a2
    80001da0:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(dstva);
    80001da2:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001da4:	6b05                	lui	s6,0x1
    80001da6:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    80001daa:	a00d                	j	80001dcc <uvm_copyout+0x50>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), (void *)src, bytes_to_copy);
    80001dac:	000d0a9b          	sext.w	s5,s10
    80001db0:	8656                	mv	a2,s5
    80001db2:	85ce                	mv	a1,s3
    80001db4:	9526                	add	a0,a0,s1
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	23e080e7          	jalr	574(ra) # 80000ff4 <memmove>

    len -= bytes_to_copy;
    80001dbe:	4159093b          	subw	s2,s2,s5
    src += bytes_to_copy;
    80001dc2:	99ea                	add	s3,s3,s10
    dstva = page_va + PGSIZE; // 移到下一页
    80001dc4:	016a04b3          	add	s1,s4,s6
  while (len > 0)
    80001dc8:	02090663          	beqz	s2,80001df4 <uvm_copyout+0x78>
    page_va = PGROUNDDOWN(dstva);
    80001dcc:	0184fa33          	and	s4,s1,s8
    page_pa = walkaddr(pgtbl, page_va);
    80001dd0:	85d2                	mv	a1,s4
    80001dd2:	855e                	mv	a0,s7
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	a82080e7          	jalr	-1406(ra) # 80001856 <walkaddr>
    if (page_pa == 0)
    80001ddc:	c105                	beqz	a0,80001dfc <uvm_copyout+0x80>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001dde:	0194f4b3          	and	s1,s1,s9
    bytes_to_copy = bytes_to_copy_in_page(dstva, len);
    80001de2:	02091793          	sll	a5,s2,0x20
    80001de6:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001de8:	409b0d33          	sub	s10,s6,s1
    80001dec:	fda7f0e3          	bgeu	a5,s10,80001dac <uvm_copyout+0x30>
    80001df0:	8d3e                	mv	s10,a5
    80001df2:	bf6d                	j	80001dac <uvm_copyout+0x30>
  }
  return 0;
    80001df4:	4501                	li	a0,0
    80001df6:	a021                	j	80001dfe <uvm_copyout+0x82>
    80001df8:	4501                	li	a0,0
}
    80001dfa:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001dfc:	557d                	li	a0,-1
}
    80001dfe:	60e6                	ld	ra,88(sp)
    80001e00:	6446                	ld	s0,80(sp)
    80001e02:	64a6                	ld	s1,72(sp)
    80001e04:	6906                	ld	s2,64(sp)
    80001e06:	79e2                	ld	s3,56(sp)
    80001e08:	7a42                	ld	s4,48(sp)
    80001e0a:	7aa2                	ld	s5,40(sp)
    80001e0c:	7b02                	ld	s6,32(sp)
    80001e0e:	6be2                	ld	s7,24(sp)
    80001e10:	6c42                	ld	s8,16(sp)
    80001e12:	6ca2                	ld	s9,8(sp)
    80001e14:	6d02                	ld	s10,0(sp)
    80001e16:	6125                	add	sp,sp,96
    80001e18:	8082                	ret

0000000080001e1a <uvm_copyin_str>:
int uvm_copyin_str(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 maxlen)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && maxlen > 0)
    80001e1a:	c6dd                	beqz	a3,80001ec8 <uvm_copyin_str+0xae>
{
    80001e1c:	715d                	add	sp,sp,-80
    80001e1e:	e486                	sd	ra,72(sp)
    80001e20:	e0a2                	sd	s0,64(sp)
    80001e22:	fc26                	sd	s1,56(sp)
    80001e24:	f84a                	sd	s2,48(sp)
    80001e26:	f44e                	sd	s3,40(sp)
    80001e28:	f052                	sd	s4,32(sp)
    80001e2a:	ec56                	sd	s5,24(sp)
    80001e2c:	e85a                	sd	s6,16(sp)
    80001e2e:	e45e                	sd	s7,8(sp)
    80001e30:	0880                	add	s0,sp,80
    80001e32:	8aaa                	mv	s5,a0
    80001e34:	89ae                	mv	s3,a1
    80001e36:	8bb2                	mv	s7,a2
    80001e38:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001e3a:	7b7d                	lui	s6,0xfffff
    pa0 = walkaddr(pgtbl, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001e3c:	6a05                	lui	s4,0x1
    80001e3e:	a02d                	j	80001e68 <uvm_copyin_str+0x4e>
        *(char*)dst = *p;
      }
      --n;
      --maxlen;
      p++;
      dst++;
    80001e40:	87ba                	mv	a5,a4
      if (*p == '\0')
    80001e42:	00f60733          	add	a4,a2,a5
    80001e46:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdccb8>
    80001e4a:	cb31                	beqz	a4,80001e9e <uvm_copyin_str+0x84>
        *(char*)dst = *p;
    80001e4c:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      dst++;
    80001e50:	00178713          	add	a4,a5,1
    while (n > 0)
    80001e54:	fee696e3          	bne	a3,a4,80001e40 <uvm_copyin_str+0x26>
    80001e58:	34fd                	addw	s1,s1,-1
    80001e5a:	013484bb          	addw	s1,s1,s3
      --maxlen;
    80001e5e:	9c9d                	subw	s1,s1,a5
      dst++;
    80001e60:	89ba                	mv	s3,a4
    }

    srcva = va0 + PGSIZE;
    80001e62:	01490bb3          	add	s7,s2,s4
  while (got_null == 0 && maxlen > 0)
    80001e66:	cca9                	beqz	s1,80001ec0 <uvm_copyin_str+0xa6>
    va0 = PGROUNDDOWN(srcva);
    80001e68:	016bf933          	and	s2,s7,s6
    pa0 = walkaddr(pgtbl, va0);
    80001e6c:	85ca                	mv	a1,s2
    80001e6e:	8556                	mv	a0,s5
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	9e6080e7          	jalr	-1562(ra) # 80001856 <walkaddr>
    if (pa0 == 0)
    80001e78:	c531                	beqz	a0,80001ec4 <uvm_copyin_str+0xaa>
    n = PGSIZE - (srcva - va0);
    80001e7a:	417906b3          	sub	a3,s2,s7
    if (n > maxlen)
    80001e7e:	02049793          	sll	a5,s1,0x20
    80001e82:	9381                	srl	a5,a5,0x20
    80001e84:	96d2                	add	a3,a3,s4
    80001e86:	00d7f363          	bgeu	a5,a3,80001e8c <uvm_copyin_str+0x72>
    80001e8a:	86be                	mv	a3,a5
    char *p = (char *)(pa0 + (srcva - va0));
    80001e8c:	955e                	add	a0,a0,s7
    80001e8e:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001e92:	dae1                	beqz	a3,80001e62 <uvm_copyin_str+0x48>
    80001e94:	87ce                	mv	a5,s3
      if (*p == '\0')
    80001e96:	41350633          	sub	a2,a0,s3
    while (n > 0)
    80001e9a:	96ce                	add	a3,a3,s3
    80001e9c:	b75d                	j	80001e42 <uvm_copyin_str+0x28>
        *(char*)dst = '\0';
    80001e9e:	00078023          	sb	zero,0(a5)
    80001ea2:	4785                	li	a5,1
  }
  if (got_null)
    80001ea4:	37fd                	addw	a5,a5,-1
    80001ea6:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001eaa:	60a6                	ld	ra,72(sp)
    80001eac:	6406                	ld	s0,64(sp)
    80001eae:	74e2                	ld	s1,56(sp)
    80001eb0:	7942                	ld	s2,48(sp)
    80001eb2:	79a2                	ld	s3,40(sp)
    80001eb4:	7a02                	ld	s4,32(sp)
    80001eb6:	6ae2                	ld	s5,24(sp)
    80001eb8:	6b42                	ld	s6,16(sp)
    80001eba:	6ba2                	ld	s7,8(sp)
    80001ebc:	6161                	add	sp,sp,80
    80001ebe:	8082                	ret
    80001ec0:	4781                	li	a5,0
    80001ec2:	b7cd                	j	80001ea4 <uvm_copyin_str+0x8a>
      return -1;
    80001ec4:	557d                	li	a0,-1
    80001ec6:	b7d5                	j	80001eaa <uvm_copyin_str+0x90>
  int got_null = 0;
    80001ec8:	4781                	li	a5,0
  if (got_null)
    80001eca:	37fd                	addw	a5,a5,-1
    80001ecc:	0007851b          	sext.w	a0,a5
}
    80001ed0:	8082                	ret

0000000080001ed2 <uvmfree>:
  return PGROUNDUP(size) / PGSIZE;
}

// 释放用户内存页面，然后释放页表页面
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001ed2:	1101                	add	sp,sp,-32
    80001ed4:	ec06                	sd	ra,24(sp)
    80001ed6:	e822                	sd	s0,16(sp)
    80001ed8:	e426                	sd	s1,8(sp)
    80001eda:	1000                	add	s0,sp,32
    80001edc:	84aa                	mv	s1,a0
  if (sz > 0)
    80001ede:	e999                	bnez	a1,80001ef4 <uvmfree+0x22>
  {
    uint64 npages = calculate_pages_needed(sz);
    uvmunmap(pagetable, 0, npages, 1);
  }
  freewalk(pagetable);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	9b4080e7          	jalr	-1612(ra) # 80001896 <freewalk>
}
    80001eea:	60e2                	ld	ra,24(sp)
    80001eec:	6442                	ld	s0,16(sp)
    80001eee:	64a2                	ld	s1,8(sp)
    80001ef0:	6105                	add	sp,sp,32
    80001ef2:	8082                	ret
  return PGROUNDUP(size) / PGSIZE;
    80001ef4:	6785                	lui	a5,0x1
    80001ef6:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001ef8:	95be                	add	a1,a1,a5
    uvmunmap(pagetable, 0, npages, 1);
    80001efa:	4685                	li	a3,1
    80001efc:	00c5d613          	srl	a2,a1,0xc
    80001f00:	4581                	li	a1,0
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	c14080e7          	jalr	-1004(ra) # 80001b16 <uvmunmap>
    80001f0a:	bfd9                	j	80001ee0 <uvmfree+0xe>

0000000080001f0c <copyout>:
// 成功返回0，错误返回-1
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001f0c:	caad                	beqz	a3,80001f7e <copyout+0x72>
{
    80001f0e:	711d                	add	sp,sp,-96
    80001f10:	ec86                	sd	ra,88(sp)
    80001f12:	e8a2                	sd	s0,80(sp)
    80001f14:	e4a6                	sd	s1,72(sp)
    80001f16:	e0ca                	sd	s2,64(sp)
    80001f18:	fc4e                	sd	s3,56(sp)
    80001f1a:	f852                	sd	s4,48(sp)
    80001f1c:	f456                	sd	s5,40(sp)
    80001f1e:	f05a                	sd	s6,32(sp)
    80001f20:	ec5e                	sd	s7,24(sp)
    80001f22:	e862                	sd	s8,16(sp)
    80001f24:	e466                	sd	s9,8(sp)
    80001f26:	1080                	add	s0,sp,96
    80001f28:	8baa                	mv	s7,a0
    80001f2a:	84ae                	mv	s1,a1
    80001f2c:	8a32                	mv	s4,a2
    80001f2e:	89b6                	mv	s3,a3
  {
    page_va = PGROUNDDOWN(dstva);
    80001f30:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001f32:	6b05                	lui	s6,0x1
    80001f34:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    80001f38:	a005                	j	80001f58 <copyout+0x4c>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), src, bytes_to_copy);
    80001f3a:	0009061b          	sext.w	a2,s2
    80001f3e:	85d2                	mv	a1,s4
    80001f40:	9526                	add	a0,a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	0b2080e7          	jalr	178(ra) # 80000ff4 <memmove>

    len -= bytes_to_copy;
    80001f4a:	412989b3          	sub	s3,s3,s2
    src += bytes_to_copy;
    80001f4e:	9a4a                	add	s4,s4,s2
    dstva = page_va + PGSIZE; // 移到下一页
    80001f50:	016a84b3          	add	s1,s5,s6
  while (len > 0)
    80001f54:	02098363          	beqz	s3,80001f7a <copyout+0x6e>
    page_va = PGROUNDDOWN(dstva);
    80001f58:	0184fab3          	and	s5,s1,s8
    page_pa = walkaddr(pagetable, page_va);
    80001f5c:	85d6                	mv	a1,s5
    80001f5e:	855e                	mv	a0,s7
    80001f60:	00000097          	auipc	ra,0x0
    80001f64:	8f6080e7          	jalr	-1802(ra) # 80001856 <walkaddr>
    if (page_pa == 0)
    80001f68:	cd09                	beqz	a0,80001f82 <copyout+0x76>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001f6a:	0194f4b3          	and	s1,s1,s9
  uint64 bytes_in_page = PGSIZE - page_offset;
    80001f6e:	409b0933          	sub	s2,s6,s1
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001f72:	fd29f4e3          	bgeu	s3,s2,80001f3a <copyout+0x2e>
    80001f76:	894e                	mv	s2,s3
    80001f78:	b7c9                	j	80001f3a <copyout+0x2e>
  }
  return 0;
    80001f7a:	4501                	li	a0,0
    80001f7c:	a021                	j	80001f84 <copyout+0x78>
    80001f7e:	4501                	li	a0,0
}
    80001f80:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001f82:	557d                	li	a0,-1
}
    80001f84:	60e6                	ld	ra,88(sp)
    80001f86:	6446                	ld	s0,80(sp)
    80001f88:	64a6                	ld	s1,72(sp)
    80001f8a:	6906                	ld	s2,64(sp)
    80001f8c:	79e2                	ld	s3,56(sp)
    80001f8e:	7a42                	ld	s4,48(sp)
    80001f90:	7aa2                	ld	s5,40(sp)
    80001f92:	7b02                	ld	s6,32(sp)
    80001f94:	6be2                	ld	s7,24(sp)
    80001f96:	6c42                	ld	s8,16(sp)
    80001f98:	6ca2                	ld	s9,8(sp)
    80001f9a:	6125                	add	sp,sp,96
    80001f9c:	8082                	ret

0000000080001f9e <copyin>:
// 成功返回0，错误返回-1
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001f9e:	cab5                	beqz	a3,80002012 <copyin+0x74>
{
    80001fa0:	711d                	add	sp,sp,-96
    80001fa2:	ec86                	sd	ra,88(sp)
    80001fa4:	e8a2                	sd	s0,80(sp)
    80001fa6:	e4a6                	sd	s1,72(sp)
    80001fa8:	e0ca                	sd	s2,64(sp)
    80001faa:	fc4e                	sd	s3,56(sp)
    80001fac:	f852                	sd	s4,48(sp)
    80001fae:	f456                	sd	s5,40(sp)
    80001fb0:	f05a                	sd	s6,32(sp)
    80001fb2:	ec5e                	sd	s7,24(sp)
    80001fb4:	e862                	sd	s8,16(sp)
    80001fb6:	e466                	sd	s9,8(sp)
    80001fb8:	1080                	add	s0,sp,96
    80001fba:	8baa                	mv	s7,a0
    80001fbc:	8a2e                	mv	s4,a1
    80001fbe:	84b2                	mv	s1,a2
    80001fc0:	89b6                	mv	s3,a3
  {
    page_va = PGROUNDDOWN(srcva);
    80001fc2:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001fc4:	6b05                	lui	s6,0x1
    80001fc6:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    80001fca:	a00d                	j	80001fec <copyin+0x4e>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove(dst, (void *)(page_pa + src_offset), bytes_to_copy);
    80001fcc:	0009061b          	sext.w	a2,s2
    80001fd0:	009505b3          	add	a1,a0,s1
    80001fd4:	8552                	mv	a0,s4
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	01e080e7          	jalr	30(ra) # 80000ff4 <memmove>

    len -= bytes_to_copy;
    80001fde:	412989b3          	sub	s3,s3,s2
    dst += bytes_to_copy;
    80001fe2:	9a4a                	add	s4,s4,s2
    srcva = page_va + PGSIZE; // 移到下一页
    80001fe4:	016a84b3          	add	s1,s5,s6
  while (len > 0)
    80001fe8:	02098363          	beqz	s3,8000200e <copyin+0x70>
    page_va = PGROUNDDOWN(srcva);
    80001fec:	0184fab3          	and	s5,s1,s8
    page_pa = walkaddr(pagetable, page_va);
    80001ff0:	85d6                	mv	a1,s5
    80001ff2:	855e                	mv	a0,s7
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	862080e7          	jalr	-1950(ra) # 80001856 <walkaddr>
    if (page_pa == 0)
    80001ffc:	cd09                	beqz	a0,80002016 <copyin+0x78>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001ffe:	0194f4b3          	and	s1,s1,s9
  uint64 bytes_in_page = PGSIZE - page_offset;
    80002002:	409b0933          	sub	s2,s6,s1
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80002006:	fd29f3e3          	bgeu	s3,s2,80001fcc <copyin+0x2e>
    8000200a:	894e                	mv	s2,s3
    8000200c:	b7c1                	j	80001fcc <copyin+0x2e>
  }
  return 0;
    8000200e:	4501                	li	a0,0
    80002010:	a021                	j	80002018 <copyin+0x7a>
    80002012:	4501                	li	a0,0
}
    80002014:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80002016:	557d                	li	a0,-1
}
    80002018:	60e6                	ld	ra,88(sp)
    8000201a:	6446                	ld	s0,80(sp)
    8000201c:	64a6                	ld	s1,72(sp)
    8000201e:	6906                	ld	s2,64(sp)
    80002020:	79e2                	ld	s3,56(sp)
    80002022:	7a42                	ld	s4,48(sp)
    80002024:	7aa2                	ld	s5,40(sp)
    80002026:	7b02                	ld	s6,32(sp)
    80002028:	6be2                	ld	s7,24(sp)
    8000202a:	6c42                	ld	s8,16(sp)
    8000202c:	6ca2                	ld	s9,8(sp)
    8000202e:	6125                	add	sp,sp,96
    80002030:	8082                	ret

0000000080002032 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80002032:	c2dd                	beqz	a3,800020d8 <copyinstr+0xa6>
{
    80002034:	715d                	add	sp,sp,-80
    80002036:	e486                	sd	ra,72(sp)
    80002038:	e0a2                	sd	s0,64(sp)
    8000203a:	fc26                	sd	s1,56(sp)
    8000203c:	f84a                	sd	s2,48(sp)
    8000203e:	f44e                	sd	s3,40(sp)
    80002040:	f052                	sd	s4,32(sp)
    80002042:	ec56                	sd	s5,24(sp)
    80002044:	e85a                	sd	s6,16(sp)
    80002046:	e45e                	sd	s7,8(sp)
    80002048:	0880                	add	s0,sp,80
    8000204a:	8a2a                	mv	s4,a0
    8000204c:	8b2e                	mv	s6,a1
    8000204e:	8bb2                	mv	s7,a2
    80002050:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80002052:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80002054:	6985                	lui	s3,0x1
    80002056:	a02d                	j	80002080 <copyinstr+0x4e>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80002058:	00078023          	sb	zero,0(a5)
    8000205c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    8000205e:	37fd                	addw	a5,a5,-1
    80002060:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80002064:	60a6                	ld	ra,72(sp)
    80002066:	6406                	ld	s0,64(sp)
    80002068:	74e2                	ld	s1,56(sp)
    8000206a:	7942                	ld	s2,48(sp)
    8000206c:	79a2                	ld	s3,40(sp)
    8000206e:	7a02                	ld	s4,32(sp)
    80002070:	6ae2                	ld	s5,24(sp)
    80002072:	6b42                	ld	s6,16(sp)
    80002074:	6ba2                	ld	s7,8(sp)
    80002076:	6161                	add	sp,sp,80
    80002078:	8082                	ret
    srcva = va0 + PGSIZE;
    8000207a:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    8000207e:	c8a9                	beqz	s1,800020d0 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80002080:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80002084:	85ca                	mv	a1,s2
    80002086:	8552                	mv	a0,s4
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	7ce080e7          	jalr	1998(ra) # 80001856 <walkaddr>
    if (pa0 == 0)
    80002090:	c131                	beqz	a0,800020d4 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80002092:	417906b3          	sub	a3,s2,s7
    80002096:	96ce                	add	a3,a3,s3
    80002098:	00d4f363          	bgeu	s1,a3,8000209e <copyinstr+0x6c>
    8000209c:	86a6                	mv	a3,s1
    char *p = (char *)(pa0 + (srcva - va0));
    8000209e:	955e                	add	a0,a0,s7
    800020a0:	41250533          	sub	a0,a0,s2
    while (n > 0)
    800020a4:	daf9                	beqz	a3,8000207a <copyinstr+0x48>
    800020a6:	87da                	mv	a5,s6
    800020a8:	885a                	mv	a6,s6
      if (*p == '\0')
    800020aa:	41650633          	sub	a2,a0,s6
    while (n > 0)
    800020ae:	96da                	add	a3,a3,s6
    800020b0:	85be                	mv	a1,a5
      if (*p == '\0')
    800020b2:	00f60733          	add	a4,a2,a5
    800020b6:	00074703          	lbu	a4,0(a4)
    800020ba:	df59                	beqz	a4,80002058 <copyinstr+0x26>
        *dst = *p;
    800020bc:	00e78023          	sb	a4,0(a5)
      dst++;
    800020c0:	0785                	add	a5,a5,1
    while (n > 0)
    800020c2:	fed797e3          	bne	a5,a3,800020b0 <copyinstr+0x7e>
    800020c6:	14fd                	add	s1,s1,-1
    800020c8:	94c2                	add	s1,s1,a6
      --max;
    800020ca:	8c8d                	sub	s1,s1,a1
      dst++;
    800020cc:	8b3e                	mv	s6,a5
    800020ce:	b775                	j	8000207a <copyinstr+0x48>
    800020d0:	4781                	li	a5,0
    800020d2:	b771                	j	8000205e <copyinstr+0x2c>
      return -1;
    800020d4:	557d                	li	a0,-1
    800020d6:	b779                	j	80002064 <copyinstr+0x32>
  int got_null = 0;
    800020d8:	4781                	li	a5,0
  if (got_null)
    800020da:	37fd                	addw	a5,a5,-1
    800020dc:	0007851b          	sext.w	a0,a5
}
    800020e0:	8082                	ret

00000000800020e2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800020e2:	1141                	add	sp,sp,-16
    800020e4:	e422                	sd	s0,8(sp)
    800020e6:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800020e8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800020ea:	2501                	sext.w	a0,a0
    800020ec:	6422                	ld	s0,8(sp)
    800020ee:	0141                	add	sp,sp,16
    800020f0:	8082                	ret

00000000800020f2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800020f2:	1141                	add	sp,sp,-16
    800020f4:	e422                	sd	s0,8(sp)
    800020f6:	0800                	add	s0,sp,16
    800020f8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800020fa:	2781                	sext.w	a5,a5
    800020fc:	079e                	sll	a5,a5,0x7
  return c;
}
    800020fe:	0000f517          	auipc	a0,0xf
    80002102:	19250513          	add	a0,a0,402 # 80011290 <cpus>
    80002106:	953e                	add	a0,a0,a5
    80002108:	6422                	ld	s0,8(sp)
    8000210a:	0141                	add	sp,sp,16
    8000210c:	8082                	ret

000000008000210e <myproc>:


proc_t* myproc(void)
{
    8000210e:	1101                	add	sp,sp,-32
    80002110:	ec06                	sd	ra,24(sp)
    80002112:	e822                	sd	s0,16(sp)
    80002114:	e426                	sd	s1,8(sp)
    80002116:	1000                	add	s0,sp,32
  push_off();
    80002118:	00001097          	auipc	ra,0x1
    8000211c:	d8a080e7          	jalr	-630(ra) # 80002ea2 <push_off>
    80002120:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002122:	2781                	sext.w	a5,a5
    80002124:	079e                	sll	a5,a5,0x7
    80002126:	0000f717          	auipc	a4,0xf
    8000212a:	16a70713          	add	a4,a4,362 # 80011290 <cpus>
    8000212e:	97ba                	add	a5,a5,a4
    80002130:	6784                	ld	s1,8(a5)
  pop_off();
    80002132:	00001097          	auipc	ra,0x1
    80002136:	e10080e7          	jalr	-496(ra) # 80002f42 <pop_off>
  return p;
}
    8000213a:	8526                	mv	a0,s1
    8000213c:	60e2                	ld	ra,24(sp)
    8000213e:	6442                	ld	s0,16(sp)
    80002140:	64a2                	ld	s1,8(sp)
    80002142:	6105                	add	sp,sp,32
    80002144:	8082                	ret

0000000080002146 <allocpid>:

int
allocpid()
{
    80002146:	1101                	add	sp,sp,-32
    80002148:	ec06                	sd	ra,24(sp)
    8000214a:	e822                	sd	s0,16(sp)
    8000214c:	e426                	sd	s1,8(sp)
    8000214e:	e04a                	sd	s2,0(sp)
    80002150:	1000                	add	s0,sp,32
  int pid;
  
  acquire(&pid_lock);
    80002152:	0000f917          	auipc	s2,0xf
    80002156:	53e90913          	add	s2,s2,1342 # 80011690 <pid_lock>
    8000215a:	854a                	mv	a0,s2
    8000215c:	00001097          	auipc	ra,0x1
    80002160:	d92080e7          	jalr	-622(ra) # 80002eee <acquire>
  pid = nextpid;
    80002164:	00007797          	auipc	a5,0x7
    80002168:	cec78793          	add	a5,a5,-788 # 80008e50 <nextpid>
    8000216c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    8000216e:	0014871b          	addw	a4,s1,1
    80002172:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80002174:	854a                	mv	a0,s2
    80002176:	00001097          	auipc	ra,0x1
    8000217a:	e2c080e7          	jalr	-468(ra) # 80002fa2 <release>

  return pid;
    8000217e:	8526                	mv	a0,s1
    80002180:	60e2                	ld	ra,24(sp)
    80002182:	6442                	ld	s0,16(sp)
    80002184:	64a2                	ld	s1,8(sp)
    80002186:	6902                	ld	s2,0(sp)
    80002188:	6105                	add	sp,sp,32
    8000218a:	8082                	ret

000000008000218c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000218c:	1141                	add	sp,sp,-16
    8000218e:	e406                	sd	ra,8(sp)
    80002190:	e022                	sd	s0,0(sp)
    80002192:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80002194:	00000097          	auipc	ra,0x0
    80002198:	f7a080e7          	jalr	-134(ra) # 8000210e <myproc>
    8000219c:	0521                	add	a0,a0,8
    8000219e:	00001097          	auipc	ra,0x1
    800021a2:	e04080e7          	jalr	-508(ra) # 80002fa2 <release>

  if (first) {
    800021a6:	00007797          	auipc	a5,0x7
    800021aa:	cae7a783          	lw	a5,-850(a5) # 80008e54 <first.0>
    800021ae:	eb89                	bnez	a5,800021c0 <forkret+0x34>
    first = 0;
    fsinit(ROOTDEV); //初始化文件系统
    // printf("proc %d: first user process init done\n", myproc()->pid);
  }

  trap_user_return();
    800021b0:	00001097          	auipc	ra,0x1
    800021b4:	194080e7          	jalr	404(ra) # 80003344 <trap_user_return>
}
    800021b8:	60a2                	ld	ra,8(sp)
    800021ba:	6402                	ld	s0,0(sp)
    800021bc:	0141                	add	sp,sp,16
    800021be:	8082                	ret
    first = 0;
    800021c0:	00007797          	auipc	a5,0x7
    800021c4:	c807aa23          	sw	zero,-876(a5) # 80008e54 <first.0>
    fsinit(ROOTDEV); //初始化文件系统
    800021c8:	4505                	li	a0,1
    800021ca:	00004097          	auipc	ra,0x4
    800021ce:	6e6080e7          	jalr	1766(ra) # 800068b0 <fsinit>
    800021d2:	bff9                	j	800021b0 <forkret+0x24>

00000000800021d4 <proc_mapstacks>:
{
    800021d4:	7139                	add	sp,sp,-64
    800021d6:	fc06                	sd	ra,56(sp)
    800021d8:	f822                	sd	s0,48(sp)
    800021da:	f426                	sd	s1,40(sp)
    800021dc:	f04a                	sd	s2,32(sp)
    800021de:	ec4e                	sd	s3,24(sp)
    800021e0:	e852                	sd	s4,16(sp)
    800021e2:	e456                	sd	s5,8(sp)
    800021e4:	e05a                	sd	s6,0(sp)
    800021e6:	0080                	add	s0,sp,64
    800021e8:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800021ea:	0000f497          	auipc	s1,0xf
    800021ee:	4be48493          	add	s1,s1,1214 # 800116a8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    800021f2:	8b26                	mv	s6,s1
    800021f4:	00006a97          	auipc	s5,0x6
    800021f8:	e0ca8a93          	add	s5,s5,-500 # 80008000 <etext>
    800021fc:	04000937          	lui	s2,0x4000
    80002200:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80002202:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002204:	00015a17          	auipc	s4,0x15
    80002208:	ea4a0a13          	add	s4,s4,-348 # 800170a8 <wait_lock>
    char *pa = kalloc(1);
    8000220c:	4505                	li	a0,1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	32e080e7          	jalr	814(ra) # 8000153c <kalloc>
    80002216:	862a                	mv	a2,a0
    if(pa == 0)
    80002218:	c131                	beqz	a0,8000225c <proc_mapstacks+0x88>
    uint64 va = KSTACK((int) (p - proc));
    8000221a:	416485b3          	sub	a1,s1,s6
    8000221e:	858d                	sra	a1,a1,0x3
    80002220:	000ab783          	ld	a5,0(s5)
    80002224:	02f585b3          	mul	a1,a1,a5
    80002228:	2585                	addw	a1,a1,1
    8000222a:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000222e:	4719                	li	a4,6
    80002230:	6685                	lui	a3,0x1
    80002232:	40b905b3          	sub	a1,s2,a1
    80002236:	854e                	mv	a0,s3
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	4f6080e7          	jalr	1270(ra) # 8000172e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002240:	16848493          	add	s1,s1,360
    80002244:	fd4494e3          	bne	s1,s4,8000220c <proc_mapstacks+0x38>
}
    80002248:	70e2                	ld	ra,56(sp)
    8000224a:	7442                	ld	s0,48(sp)
    8000224c:	74a2                	ld	s1,40(sp)
    8000224e:	7902                	ld	s2,32(sp)
    80002250:	69e2                	ld	s3,24(sp)
    80002252:	6a42                	ld	s4,16(sp)
    80002254:	6aa2                	ld	s5,8(sp)
    80002256:	6b02                	ld	s6,0(sp)
    80002258:	6121                	add	sp,sp,64
    8000225a:	8082                	ret
      panic("kalloc");
    8000225c:	00006517          	auipc	a0,0x6
    80002260:	16c50513          	add	a0,a0,364 # 800083c8 <digits+0x1d8>
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	f7c080e7          	jalr	-132(ra) # 800011e0 <panic>

000000008000226c <procinit>:
{
    8000226c:	7139                	add	sp,sp,-64
    8000226e:	fc06                	sd	ra,56(sp)
    80002270:	f822                	sd	s0,48(sp)
    80002272:	f426                	sd	s1,40(sp)
    80002274:	f04a                	sd	s2,32(sp)
    80002276:	ec4e                	sd	s3,24(sp)
    80002278:	e852                	sd	s4,16(sp)
    8000227a:	e456                	sd	s5,8(sp)
    8000227c:	e05a                	sd	s6,0(sp)
    8000227e:	0080                	add	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80002280:	00006597          	auipc	a1,0x6
    80002284:	15058593          	add	a1,a1,336 # 800083d0 <digits+0x1e0>
    80002288:	0000f517          	auipc	a0,0xf
    8000228c:	40850513          	add	a0,a0,1032 # 80011690 <pid_lock>
    80002290:	00001097          	auipc	ra,0x1
    80002294:	bce080e7          	jalr	-1074(ra) # 80002e5e <initlock>
    initlock(&wait_lock, "wait_lock");
    80002298:	00006597          	auipc	a1,0x6
    8000229c:	14058593          	add	a1,a1,320 # 800083d8 <digits+0x1e8>
    800022a0:	00015517          	auipc	a0,0x15
    800022a4:	e0850513          	add	a0,a0,-504 # 800170a8 <wait_lock>
    800022a8:	00001097          	auipc	ra,0x1
    800022ac:	bb6080e7          	jalr	-1098(ra) # 80002e5e <initlock>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b0:	0000f497          	auipc	s1,0xf
    800022b4:	3f848493          	add	s1,s1,1016 # 800116a8 <proc>
      initlock(&p->lock, "proc");
    800022b8:	00006b17          	auipc	s6,0x6
    800022bc:	130b0b13          	add	s6,s6,304 # 800083e8 <digits+0x1f8>
      p->kstack = KSTACK((int) (p - proc));
    800022c0:	8aa6                	mv	s5,s1
    800022c2:	00006a17          	auipc	s4,0x6
    800022c6:	d3ea0a13          	add	s4,s4,-706 # 80008000 <etext>
    800022ca:	04000937          	lui	s2,0x4000
    800022ce:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800022d0:	0932                	sll	s2,s2,0xc
    for(p = proc; p < &proc[NPROC]; p++) {
    800022d2:	00015997          	auipc	s3,0x15
    800022d6:	dd698993          	add	s3,s3,-554 # 800170a8 <wait_lock>
      initlock(&p->lock, "proc");
    800022da:	85da                	mv	a1,s6
    800022dc:	00848513          	add	a0,s1,8
    800022e0:	00001097          	auipc	ra,0x1
    800022e4:	b7e080e7          	jalr	-1154(ra) # 80002e5e <initlock>
      p->state = UNUSED;
    800022e8:	0204a023          	sw	zero,32(s1)
      p->kstack = KSTACK((int) (p - proc));
    800022ec:	415487b3          	sub	a5,s1,s5
    800022f0:	878d                	sra	a5,a5,0x3
    800022f2:	000a3703          	ld	a4,0(s4)
    800022f6:	02e787b3          	mul	a5,a5,a4
    800022fa:	2785                	addw	a5,a5,1
    800022fc:	00d7979b          	sllw	a5,a5,0xd
    80002300:	40f907b3          	sub	a5,s2,a5
    80002304:	f8fc                	sd	a5,240(s1)
    for(p = proc; p < &proc[NPROC]; p++) {
    80002306:	16848493          	add	s1,s1,360
    8000230a:	fd3498e3          	bne	s1,s3,800022da <procinit+0x6e>
}
    8000230e:	70e2                	ld	ra,56(sp)
    80002310:	7442                	ld	s0,48(sp)
    80002312:	74a2                	ld	s1,40(sp)
    80002314:	7902                	ld	s2,32(sp)
    80002316:	69e2                	ld	s3,24(sp)
    80002318:	6a42                	ld	s4,16(sp)
    8000231a:	6aa2                	ld	s5,8(sp)
    8000231c:	6b02                	ld	s6,0(sp)
    8000231e:	6121                	add	sp,sp,64
    80002320:	8082                	ret

0000000080002322 <proc_freepagetable>:

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    80002322:	1101                	add	sp,sp,-32
    80002324:	ec06                	sd	ra,24(sp)
    80002326:	e822                	sd	s0,16(sp)
    80002328:	e426                	sd	s1,8(sp)
    8000232a:	e04a                	sd	s2,0(sp)
    8000232c:	1000                	add	s0,sp,32
    8000232e:	84aa                	mv	s1,a0
    80002330:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0); 
    80002332:	4681                	li	a3,0
    80002334:	4605                	li	a2,1
    80002336:	040005b7          	lui	a1,0x4000
    8000233a:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000233c:	05b2                	sll	a1,a1,0xc
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	7d8080e7          	jalr	2008(ra) # 80001b16 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002346:	4681                	li	a3,0
    80002348:	4605                	li	a2,1
    8000234a:	020005b7          	lui	a1,0x2000
    8000234e:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80002350:	05b6                	sll	a1,a1,0xd
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	7c2080e7          	jalr	1986(ra) # 80001b16 <uvmunmap>
  uvmfree(pagetable, sz);
    8000235c:	85ca                	mv	a1,s2
    8000235e:	8526                	mv	a0,s1
    80002360:	00000097          	auipc	ra,0x0
    80002364:	b72080e7          	jalr	-1166(ra) # 80001ed2 <uvmfree>
}
    80002368:	60e2                	ld	ra,24(sp)
    8000236a:	6442                	ld	s0,16(sp)
    8000236c:	64a2                	ld	s1,8(sp)
    8000236e:	6902                	ld	s2,0(sp)
    80002370:	6105                	add	sp,sp,32
    80002372:	8082                	ret

0000000080002374 <freeproc>:

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
void freeproc(struct proc *p)
{
    80002374:	1101                	add	sp,sp,-32
    80002376:	ec06                	sd	ra,24(sp)
    80002378:	e822                	sd	s0,16(sp)
    8000237a:	e426                	sd	s1,8(sp)
    8000237c:	1000                	add	s0,sp,32
    8000237e:	84aa                	mv	s1,a0
  if(p->tf)
    80002380:	6d28                	ld	a0,88(a0)
    80002382:	c511                	beqz	a0,8000238e <freeproc+0x1a>
    kfree((uint64)p->tf,1);
    80002384:	4585                	li	a1,1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	0b6080e7          	jalr	182(ra) # 8000143c <kfree>
  p->tf = 0;
    8000238e:	0404bc23          	sd	zero,88(s1)
  if(p->pgtbl)
    80002392:	64a8                	ld	a0,72(s1)
    80002394:	c511                	beqz	a0,800023a0 <freeproc+0x2c>
    proc_freepagetable(p->pgtbl, p->sz);
    80002396:	74ec                	ld	a1,232(s1)
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	f8a080e7          	jalr	-118(ra) # 80002322 <proc_freepagetable>

  p->pgtbl = 0;
    800023a0:	0404b423          	sd	zero,72(s1)
  p->parent = 0;
    800023a4:	0204b423          	sd	zero,40(s1)
  p->chan = 0;
    800023a8:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    800023ac:	0204ac23          	sw	zero,56(s1)
  p->exit_state = 0;
    800023b0:	0204ae23          	sw	zero,60(s1)
  p->sleep_space = 0;
    800023b4:	0404b023          	sd	zero,64(s1)
  p->ustack_pages = 0;
    800023b8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800023bc:	0e04b423          	sd	zero,232(s1)
  p->pid = 0;
    800023c0:	0004a023          	sw	zero,0(s1)
  
  memset(&p->ctx, 0, sizeof(p->ctx));
    800023c4:	07000613          	li	a2,112
    800023c8:	4581                	li	a1,0
    800023ca:	0f848513          	add	a0,s1,248
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	bca080e7          	jalr	-1078(ra) # 80000f98 <memset>

  p->state = UNUSED;
    800023d6:	0204a023          	sw	zero,32(s1)
}
    800023da:	60e2                	ld	ra,24(sp)
    800023dc:	6442                	ld	s0,16(sp)
    800023de:	64a2                	ld	s1,8(sp)
    800023e0:	6105                	add	sp,sp,32
    800023e2:	8082                	ret

00000000800023e4 <proc_pgtbl_init>:

// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
    800023e4:	1101                	add	sp,sp,-32
    800023e6:	ec06                	sd	ra,24(sp)
    800023e8:	e822                	sd	s0,16(sp)
    800023ea:	e426                	sd	s1,8(sp)
    800023ec:	e04a                	sd	s2,0(sp)
    800023ee:	1000                	add	s0,sp,32
    800023f0:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	680080e7          	jalr	1664(ra) # 80001a72 <uvmcreate>
    800023fa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800023fc:	cd1d                	beqz	a0,8000243a <proc_pgtbl_init+0x56>
    return 0;

  
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800023fe:	4729                	li	a4,10
    80002400:	00005697          	auipc	a3,0x5
    80002404:	c0068693          	add	a3,a3,-1024 # 80007000 <_trampoline>
    80002408:	6605                	lui	a2,0x1
    8000240a:	040005b7          	lui	a1,0x4000
    8000240e:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80002410:	05b2                	sll	a1,a1,0xc
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	258080e7          	jalr	600(ra) # 8000166a <mappages>
    8000241a:	02054763          	bltz	a0,80002448 <proc_pgtbl_init+0x64>
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000241e:	4719                	li	a4,6
    80002420:	86ca                	mv	a3,s2
    80002422:	6605                	lui	a2,0x1
    80002424:	020005b7          	lui	a1,0x2000
    80002428:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    8000242a:	05b6                	sll	a1,a1,0xd
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	23c080e7          	jalr	572(ra) # 8000166a <mappages>
    80002436:	02054163          	bltz	a0,80002458 <proc_pgtbl_init+0x74>
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}
    8000243a:	8526                	mv	a0,s1
    8000243c:	60e2                	ld	ra,24(sp)
    8000243e:	6442                	ld	s0,16(sp)
    80002440:	64a2                	ld	s1,8(sp)
    80002442:	6902                	ld	s2,0(sp)
    80002444:	6105                	add	sp,sp,32
    80002446:	8082                	ret
    panic("proc_pgtbl_init: mappages trampoline failed");
    80002448:	00006517          	auipc	a0,0x6
    8000244c:	fa850513          	add	a0,a0,-88 # 800083f0 <digits+0x200>
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	d90080e7          	jalr	-624(ra) # 800011e0 <panic>
    panic("proc_pgtbl_init: mappages trapframe failed");
    80002458:	00006517          	auipc	a0,0x6
    8000245c:	fc850513          	add	a0,a0,-56 # 80008420 <digits+0x230>
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	d80080e7          	jalr	-640(ra) # 800011e0 <panic>

0000000080002468 <allocproc>:
{
    80002468:	7179                	add	sp,sp,-48
    8000246a:	f406                	sd	ra,40(sp)
    8000246c:	f022                	sd	s0,32(sp)
    8000246e:	ec26                	sd	s1,24(sp)
    80002470:	e84a                	sd	s2,16(sp)
    80002472:	e44e                	sd	s3,8(sp)
    80002474:	1800                	add	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80002476:	0000f497          	auipc	s1,0xf
    8000247a:	23248493          	add	s1,s1,562 # 800116a8 <proc>
    8000247e:	00015997          	auipc	s3,0x15
    80002482:	c2a98993          	add	s3,s3,-982 # 800170a8 <wait_lock>
    acquire(&p->lock);
    80002486:	00848913          	add	s2,s1,8
    8000248a:	854a                	mv	a0,s2
    8000248c:	00001097          	auipc	ra,0x1
    80002490:	a62080e7          	jalr	-1438(ra) # 80002eee <acquire>
    if(p->state == UNUSED) {
    80002494:	509c                	lw	a5,32(s1)
    80002496:	cf81                	beqz	a5,800024ae <allocproc+0x46>
      release(&p->lock);
    80002498:	854a                	mv	a0,s2
    8000249a:	00001097          	auipc	ra,0x1
    8000249e:	b08080e7          	jalr	-1272(ra) # 80002fa2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a2:	16848493          	add	s1,s1,360
    800024a6:	ff3490e3          	bne	s1,s3,80002486 <allocproc+0x1e>
  return 0;
    800024aa:	4481                	li	s1,0
    800024ac:	a8a1                	j	80002504 <allocproc+0x9c>
  p->pid = allocpid();
    800024ae:	00000097          	auipc	ra,0x0
    800024b2:	c98080e7          	jalr	-872(ra) # 80002146 <allocpid>
    800024b6:	c088                	sw	a0,0(s1)
  p->state = USED;
    800024b8:	4785                	li	a5,1
    800024ba:	d09c                	sw	a5,32(s1)
  p->sz=4096;
    800024bc:	6785                	lui	a5,0x1
    800024be:	f4fc                	sd	a5,232(s1)
  if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    800024c0:	4505                	li	a0,1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	07a080e7          	jalr	122(ra) # 8000153c <kalloc>
    800024ca:	89aa                	mv	s3,a0
    800024cc:	eca8                	sd	a0,88(s1)
    800024ce:	c139                	beqz	a0,80002514 <allocproc+0xac>
  p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	f14080e7          	jalr	-236(ra) # 800023e4 <proc_pgtbl_init>
    800024d8:	89aa                	mv	s3,a0
    800024da:	e4a8                	sd	a0,72(s1)
  if(p->pgtbl == 0){ 
    800024dc:	c125                	beqz	a0,8000253c <allocproc+0xd4>
  memset(&p->ctx, 0, sizeof(p->ctx));
    800024de:	07000613          	li	a2,112
    800024e2:	4581                	li	a1,0
    800024e4:	0f848513          	add	a0,s1,248
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	ab0080e7          	jalr	-1360(ra) # 80000f98 <memset>
  p->ctx.ra = (uint64)forkret;
    800024f0:	00000797          	auipc	a5,0x0
    800024f4:	c9c78793          	add	a5,a5,-868 # 8000218c <forkret>
    800024f8:	fcfc                	sd	a5,248(s1)
  p->ctx.sp = p->kstack+PGSIZE;
    800024fa:	78fc                	ld	a5,240(s1)
    800024fc:	6705                	lui	a4,0x1
    800024fe:	97ba                	add	a5,a5,a4
    80002500:	10f4b023          	sd	a5,256(s1)
}
    80002504:	8526                	mv	a0,s1
    80002506:	70a2                	ld	ra,40(sp)
    80002508:	7402                	ld	s0,32(sp)
    8000250a:	64e2                	ld	s1,24(sp)
    8000250c:	6942                	ld	s2,16(sp)
    8000250e:	69a2                	ld	s3,8(sp)
    80002510:	6145                	add	sp,sp,48
    80002512:	8082                	ret
    freeproc(p);
    80002514:	8526                	mv	a0,s1
    80002516:	00000097          	auipc	ra,0x0
    8000251a:	e5e080e7          	jalr	-418(ra) # 80002374 <freeproc>
    printf("allocproc: kalloc trapframe failed\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	f3250513          	add	a0,a0,-206 # 80008450 <digits+0x260>
    80002526:	fffff097          	auipc	ra,0xfffff
    8000252a:	d04080e7          	jalr	-764(ra) # 8000122a <printf>
    release(&p->lock);
    8000252e:	854a                	mv	a0,s2
    80002530:	00001097          	auipc	ra,0x1
    80002534:	a72080e7          	jalr	-1422(ra) # 80002fa2 <release>
    return 0;
    80002538:	84ce                	mv	s1,s3
    8000253a:	b7e9                	j	80002504 <allocproc+0x9c>
    freeproc(p);
    8000253c:	8526                	mv	a0,s1
    8000253e:	00000097          	auipc	ra,0x0
    80002542:	e36080e7          	jalr	-458(ra) # 80002374 <freeproc>
    printf("allocproc: proc_pgtbl_init failed\n");
    80002546:	00006517          	auipc	a0,0x6
    8000254a:	f3250513          	add	a0,a0,-206 # 80008478 <digits+0x288>
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	cdc080e7          	jalr	-804(ra) # 8000122a <printf>
    release(&p->lock);
    80002556:	854a                	mv	a0,s2
    80002558:	00001097          	auipc	ra,0x1
    8000255c:	a4a080e7          	jalr	-1462(ra) # 80002fa2 <release>
    return 0;
    80002560:	84ce                	mv	s1,s3
    80002562:	b74d                	j	80002504 <allocproc+0x9c>

0000000080002564 <userinit>:
//__attribute__ ((aligned (16))) char proc0stack[8192];

// Set up first user process.
void
userinit(void)
{
    80002564:	1101                	add	sp,sp,-32
    80002566:	ec06                	sd	ra,24(sp)
    80002568:	e822                	sd	s0,16(sp)
    8000256a:	e426                	sd	s1,8(sp)
    8000256c:	1000                	add	s0,sp,32
  struct proc *p;

  p = allocproc();
    8000256e:	00000097          	auipc	ra,0x0
    80002572:	efa080e7          	jalr	-262(ra) # 80002468 <allocproc>
    80002576:	84aa                	mv	s1,a0
  proczero = p;
    80002578:	00007797          	auipc	a5,0x7
    8000257c:	92a7b823          	sd	a0,-1744(a5) # 80008ea8 <proczero>
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pgtbl, (uchar*)initcode_start, (uint64)(initcode_end - initcode_start));
    80002580:	00004597          	auipc	a1,0x4
    80002584:	64858593          	add	a1,a1,1608 # 80006bc8 <initcode_start>
    80002588:	00005617          	auipc	a2,0x5
    8000258c:	87260613          	add	a2,a2,-1934 # 80006dfa <initcode_end>
    80002590:	9e0d                	subw	a2,a2,a1
    80002592:	6528                	ld	a0,72(a0)
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	50e080e7          	jalr	1294(ra) # 80001aa2 <uvmfirst>
  p->sz = PGSIZE;
    8000259c:	6785                	lui	a5,0x1
    8000259e:	f4fc                	sd	a5,232(s1)

  // prepare for the very first "return" from kernel to user.
  p->tf->epc = 0;      // user program counter
    800025a0:	6cb8                	ld	a4,88(s1)
    800025a2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    800025a6:	6cb8                	ld	a4,88(s1)
    800025a8:	fb1c                	sd	a5,48(a4)
  

  // safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
    800025aa:	00006517          	auipc	a0,0x6
    800025ae:	ef650513          	add	a0,a0,-266 # 800084a0 <digits+0x2b0>
    800025b2:	00004097          	auipc	ra,0x4
    800025b6:	b98080e7          	jalr	-1128(ra) # 8000614a <namei>
    800025ba:	f0e8                	sd	a0,224(s1)

  p->state = RUNNABLE;
    800025bc:	478d                	li	a5,3
    800025be:	d09c                	sw	a5,32(s1)

  release(&p->lock);
    800025c0:	00848513          	add	a0,s1,8
    800025c4:	00001097          	auipc	ra,0x1
    800025c8:	9de080e7          	jalr	-1570(ra) # 80002fa2 <release>
}
    800025cc:	60e2                	ld	ra,24(sp)
    800025ce:	6442                	ld	s0,16(sp)
    800025d0:	64a2                	ld	s1,8(sp)
    800025d2:	6105                	add	sp,sp,32
    800025d4:	8082                	ret

00000000800025d6 <growproc>:

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
    800025d6:	1101                	add	sp,sp,-32
    800025d8:	ec06                	sd	ra,24(sp)
    800025da:	e822                	sd	s0,16(sp)
    800025dc:	e426                	sd	s1,8(sp)
    800025de:	e04a                	sd	s2,0(sp)
    800025e0:	1000                	add	s0,sp,32
    800025e2:	892a                	mv	s2,a0
  uint64 sz;
  struct proc *p = myproc();
    800025e4:	00000097          	auipc	ra,0x0
    800025e8:	b2a080e7          	jalr	-1238(ra) # 8000210e <myproc>
    800025ec:	84aa                	mv	s1,a0

  sz = p->sz;
    800025ee:	756c                	ld	a1,232(a0)
  if(n > 0){
    800025f0:	01204c63          	bgtz	s2,80002608 <growproc+0x32>
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    800025f4:	02094663          	bltz	s2,80002620 <growproc+0x4a>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
  }
  p->sz = sz;
    800025f8:	f4ec                	sd	a1,232(s1)
  return 0;
    800025fa:	4501                	li	a0,0
}
    800025fc:	60e2                	ld	ra,24(sp)
    800025fe:	6442                	ld	s0,16(sp)
    80002600:	64a2                	ld	s1,8(sp)
    80002602:	6902                	ld	s2,0(sp)
    80002604:	6105                	add	sp,sp,32
    80002606:	8082                	ret
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
    80002608:	4691                	li	a3,4
    8000260a:	00b90633          	add	a2,s2,a1
    8000260e:	6528                	ld	a0,72(a0)
    80002610:	fffff097          	auipc	ra,0xfffff
    80002614:	616080e7          	jalr	1558(ra) # 80001c26 <uvmalloc>
    80002618:	85aa                	mv	a1,a0
    8000261a:	fd79                	bnez	a0,800025f8 <growproc+0x22>
      return -1;
    8000261c:	557d                	li	a0,-1
    8000261e:	bff9                	j	800025fc <growproc+0x26>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
    80002620:	00b90633          	add	a2,s2,a1
    80002624:	6528                	ld	a0,72(a0)
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	5b8080e7          	jalr	1464(ra) # 80001bde <uvmdealloc>
    8000262e:	85aa                	mv	a1,a0
    80002630:	b7e1                	j	800025f8 <growproc+0x22>

0000000080002632 <uvmcopy>:
  pte_t *pte;
  uint64 pa, current_va;
  uint flags;
  char *mem;

  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    80002632:	ca69                	beqz	a2,80002704 <uvmcopy+0xd2>
{
    80002634:	715d                	add	sp,sp,-80
    80002636:	e486                	sd	ra,72(sp)
    80002638:	e0a2                	sd	s0,64(sp)
    8000263a:	fc26                	sd	s1,56(sp)
    8000263c:	f84a                	sd	s2,48(sp)
    8000263e:	f44e                	sd	s3,40(sp)
    80002640:	f052                	sd	s4,32(sp)
    80002642:	ec56                	sd	s5,24(sp)
    80002644:	e85a                	sd	s6,16(sp)
    80002646:	e45e                	sd	s7,8(sp)
    80002648:	0880                	add	s0,sp,80
    8000264a:	8b2a                	mv	s6,a0
    8000264c:	8a2e                	mv	s4,a1
    8000264e:	8ab2                	mv	s5,a2
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    80002650:	4981                	li	s3,0
  {
    pte = walk(old, current_va, 0);
    80002652:	4601                	li	a2,0
    80002654:	85ce                	mv	a1,s3
    80002656:	855a                	mv	a0,s6
    80002658:	fffff097          	auipc	ra,0xfffff
    8000265c:	f6a080e7          	jalr	-150(ra) # 800015c2 <walk>
    if (pte == 0)
    80002660:	c539                	beqz	a0,800026ae <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");

    if (!is_pte_valid(*pte))
    80002662:	6118                	ld	a4,0(a0)
  return (pte & PTE_V) != 0;
    80002664:	00177793          	and	a5,a4,1
    if (!is_pte_valid(*pte))
    80002668:	cbb9                	beqz	a5,800026be <uvmcopy+0x8c>
      panic("uvmcopy: page not present");

    pa = PTE2PA(*pte);
    8000266a:	00a75593          	srl	a1,a4,0xa
    8000266e:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80002672:	3ff77913          	and	s2,a4,1023
  *dest_mem = kalloc(1);
    80002676:	4505                	li	a0,1
    80002678:	fffff097          	auipc	ra,0xfffff
    8000267c:	ec4080e7          	jalr	-316(ra) # 8000153c <kalloc>
    80002680:	84aa                	mv	s1,a0
  if (*dest_mem == 0)
    80002682:	cd21                	beqz	a0,800026da <uvmcopy+0xa8>
  memmove(*dest_mem, (char *)src_pa, PGSIZE);
    80002684:	6605                	lui	a2,0x1
    80002686:	85de                	mv	a1,s7
    80002688:	fffff097          	auipc	ra,0xfffff
    8000268c:	96c080e7          	jalr	-1684(ra) # 80000ff4 <memmove>

    if (copy_physical_page(pa, &mem) != 0)
      goto err;

    if (mappages(new, current_va, PGSIZE, (uint64)mem, flags) != 0)
    80002690:	874a                	mv	a4,s2
    80002692:	86a6                	mv	a3,s1
    80002694:	6605                	lui	a2,0x1
    80002696:	85ce                	mv	a1,s3
    80002698:	8552                	mv	a0,s4
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	fd0080e7          	jalr	-48(ra) # 8000166a <mappages>
    800026a2:	e515                	bnez	a0,800026ce <uvmcopy+0x9c>
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    800026a4:	6785                	lui	a5,0x1
    800026a6:	99be                	add	s3,s3,a5
    800026a8:	fb59e5e3          	bltu	s3,s5,80002652 <uvmcopy+0x20>
    800026ac:	a089                	j	800026ee <uvmcopy+0xbc>
      panic("uvmcopy: pte should exist");
    800026ae:	00006517          	auipc	a0,0x6
    800026b2:	dfa50513          	add	a0,a0,-518 # 800084a8 <digits+0x2b8>
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	b2a080e7          	jalr	-1238(ra) # 800011e0 <panic>
      panic("uvmcopy: page not present");
    800026be:	00006517          	auipc	a0,0x6
    800026c2:	e0a50513          	add	a0,a0,-502 # 800084c8 <digits+0x2d8>
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	b1a080e7          	jalr	-1254(ra) # 800011e0 <panic>
    {
      kfree((uint64)mem,1);
    800026ce:	4585                	li	a1,1
    800026d0:	8526                	mv	a0,s1
    800026d2:	fffff097          	auipc	ra,0xfffff
    800026d6:	d6a080e7          	jalr	-662(ra) # 8000143c <kfree>
  uvmunmap(new_table, 0, npages, 1);
    800026da:	4685                	li	a3,1
    800026dc:	00c9d613          	srl	a2,s3,0xc
    800026e0:	4581                	li	a1,0
    800026e2:	8552                	mv	a0,s4
    800026e4:	fffff097          	auipc	ra,0xfffff
    800026e8:	432080e7          	jalr	1074(ra) # 80001b16 <uvmunmap>
  }
  return 0;

err:
  cleanup_partial_copy(new, current_va);
  return -1;
    800026ec:	557d                	li	a0,-1
}
    800026ee:	60a6                	ld	ra,72(sp)
    800026f0:	6406                	ld	s0,64(sp)
    800026f2:	74e2                	ld	s1,56(sp)
    800026f4:	7942                	ld	s2,48(sp)
    800026f6:	79a2                	ld	s3,40(sp)
    800026f8:	7a02                	ld	s4,32(sp)
    800026fa:	6ae2                	ld	s5,24(sp)
    800026fc:	6b42                	ld	s6,16(sp)
    800026fe:	6ba2                	ld	s7,8(sp)
    80002700:	6161                	add	sp,sp,80
    80002702:	8082                	ret
  return 0;
    80002704:	4501                	li	a0,0
}
    80002706:	8082                	ret

0000000080002708 <fork>:

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
    80002708:	7139                	add	sp,sp,-64
    8000270a:	fc06                	sd	ra,56(sp)
    8000270c:	f822                	sd	s0,48(sp)
    8000270e:	f426                	sd	s1,40(sp)
    80002710:	f04a                	sd	s2,32(sp)
    80002712:	ec4e                	sd	s3,24(sp)
    80002714:	e852                	sd	s4,16(sp)
    80002716:	e456                	sd	s5,8(sp)
    80002718:	0080                	add	s0,sp,64
  int i; 
  int pid;
  struct proc *np;
  struct proc *p = myproc();
    8000271a:	00000097          	auipc	ra,0x0
    8000271e:	9f4080e7          	jalr	-1548(ra) # 8000210e <myproc>
    80002722:	8aaa                	mv	s5,a0

  // Allocate process.
  if((np = allocproc()) == 0){
    80002724:	00000097          	auipc	ra,0x0
    80002728:	d44080e7          	jalr	-700(ra) # 80002468 <allocproc>
    8000272c:	10050663          	beqz	a0,80002838 <fork+0x130>
    80002730:	8a2a                	mv	s4,a0
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pgtbl, np->pgtbl, p->sz) < 0){
    80002732:	0e8ab603          	ld	a2,232(s5)
    80002736:	652c                	ld	a1,72(a0)
    80002738:	048ab503          	ld	a0,72(s5)
    8000273c:	00000097          	auipc	ra,0x0
    80002740:	ef6080e7          	jalr	-266(ra) # 80002632 <uvmcopy>
    80002744:	04054863          	bltz	a0,80002794 <fork+0x8c>
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
    80002748:	0e8ab783          	ld	a5,232(s5)
    8000274c:	0efa3423          	sd	a5,232(s4)

  // copy saved user registers.
  *(np->tf) = *(p->tf);
    80002750:	058ab683          	ld	a3,88(s5)
    80002754:	87b6                	mv	a5,a3
    80002756:	058a3703          	ld	a4,88(s4)
    8000275a:	12068693          	add	a3,a3,288
    8000275e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002762:	6788                	ld	a0,8(a5)
    80002764:	6b8c                	ld	a1,16(a5)
    80002766:	6f90                	ld	a2,24(a5)
    80002768:	01073023          	sd	a6,0(a4)
    8000276c:	e708                	sd	a0,8(a4)
    8000276e:	eb0c                	sd	a1,16(a4)
    80002770:	ef10                	sd	a2,24(a4)
    80002772:	02078793          	add	a5,a5,32
    80002776:	02070713          	add	a4,a4,32
    8000277a:	fed792e3          	bne	a5,a3,8000275e <fork+0x56>

  // Cause fork to return 0 in the child.
  np->tf->a0 = 0;
    8000277e:	058a3783          	ld	a5,88(s4)
    80002782:	0607b823          	sd	zero,112(a5)

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++) 
    80002786:	060a8493          	add	s1,s5,96
    8000278a:	060a0913          	add	s2,s4,96
    8000278e:	0e0a8993          	add	s3,s5,224
    80002792:	a015                	j	800027b6 <fork+0xae>
    freeproc(np);
    80002794:	8552                	mv	a0,s4
    80002796:	00000097          	auipc	ra,0x0
    8000279a:	bde080e7          	jalr	-1058(ra) # 80002374 <freeproc>
    release(&np->lock);
    8000279e:	008a0513          	add	a0,s4,8
    800027a2:	00001097          	auipc	ra,0x1
    800027a6:	800080e7          	jalr	-2048(ra) # 80002fa2 <release>
    return -1;
    800027aa:	59fd                	li	s3,-1
    800027ac:	a8a5                	j	80002824 <fork+0x11c>
  for(i = 0; i < NOFILE; i++) 
    800027ae:	04a1                	add	s1,s1,8
    800027b0:	0921                	add	s2,s2,8
    800027b2:	01348b63          	beq	s1,s3,800027c8 <fork+0xc0>
    if(p->ofile[i])
    800027b6:	6088                	ld	a0,0(s1)
    800027b8:	d97d                	beqz	a0,800027ae <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    800027ba:	00003097          	auipc	ra,0x3
    800027be:	2ac080e7          	jalr	684(ra) # 80005a66 <filedup>
    800027c2:	00a93023          	sd	a0,0(s2)
    800027c6:	b7e5                	j	800027ae <fork+0xa6>
  np->cwd = idup(p->cwd);
    800027c8:	0e0ab503          	ld	a0,224(s5)
    800027cc:	00002097          	auipc	ra,0x2
    800027d0:	282080e7          	jalr	642(ra) # 80004a4e <idup>
    800027d4:	0eaa3023          	sd	a0,224(s4)

  //safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;
    800027d8:	000a2983          	lw	s3,0(s4)

  release(&np->lock);
    800027dc:	008a0493          	add	s1,s4,8
    800027e0:	8526                	mv	a0,s1
    800027e2:	00000097          	auipc	ra,0x0
    800027e6:	7c0080e7          	jalr	1984(ra) # 80002fa2 <release>

  acquire(&wait_lock);
    800027ea:	00015917          	auipc	s2,0x15
    800027ee:	8be90913          	add	s2,s2,-1858 # 800170a8 <wait_lock>
    800027f2:	854a                	mv	a0,s2
    800027f4:	00000097          	auipc	ra,0x0
    800027f8:	6fa080e7          	jalr	1786(ra) # 80002eee <acquire>
  np->parent = p;
    800027fc:	035a3423          	sd	s5,40(s4)
  release(&wait_lock);
    80002800:	854a                	mv	a0,s2
    80002802:	00000097          	auipc	ra,0x0
    80002806:	7a0080e7          	jalr	1952(ra) # 80002fa2 <release>

  acquire(&np->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	6e2080e7          	jalr	1762(ra) # 80002eee <acquire>
  np->state = RUNNABLE;
    80002814:	478d                	li	a5,3
    80002816:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    8000281a:	8526                	mv	a0,s1
    8000281c:	00000097          	auipc	ra,0x0
    80002820:	786080e7          	jalr	1926(ra) # 80002fa2 <release>

  return pid;
}
    80002824:	854e                	mv	a0,s3
    80002826:	70e2                	ld	ra,56(sp)
    80002828:	7442                	ld	s0,48(sp)
    8000282a:	74a2                	ld	s1,40(sp)
    8000282c:	7902                	ld	s2,32(sp)
    8000282e:	69e2                	ld	s3,24(sp)
    80002830:	6a42                	ld	s4,16(sp)
    80002832:	6aa2                	ld	s5,8(sp)
    80002834:	6121                	add	sp,sp,64
    80002836:	8082                	ret
    return -1;
    80002838:	59fd                	li	s3,-1
    8000283a:	b7ed                	j	80002824 <fork+0x11c>

000000008000283c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000283c:	7179                	add	sp,sp,-48
    8000283e:	f406                	sd	ra,40(sp)
    80002840:	f022                	sd	s0,32(sp)
    80002842:	ec26                	sd	s1,24(sp)
    80002844:	e84a                	sd	s2,16(sp)
    80002846:	e44e                	sd	s3,8(sp)
    80002848:	e052                	sd	s4,0(sp)
    8000284a:	1800                	add	s0,sp,48
    8000284c:	89aa                	mv	s3,a0
    8000284e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002850:	00000097          	auipc	ra,0x0
    80002854:	8be080e7          	jalr	-1858(ra) # 8000210e <myproc>
    80002858:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000285a:	00850a13          	add	s4,a0,8
    8000285e:	8552                	mv	a0,s4
    80002860:	00000097          	auipc	ra,0x0
    80002864:	68e080e7          	jalr	1678(ra) # 80002eee <acquire>
  release(lk);
    80002868:	854a                	mv	a0,s2
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	738080e7          	jalr	1848(ra) # 80002fa2 <release>

  // Go to sleep.
  p->chan = chan;
    80002872:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002876:	4789                	li	a5,2
    80002878:	d09c                	sw	a5,32(s1)

  sched();
    8000287a:	00001097          	auipc	ra,0x1
    8000287e:	9c6080e7          	jalr	-1594(ra) # 80003240 <sched>

  // Tidy up.
  p->chan = 0;
    80002882:	0204b823          	sd	zero,48(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002886:	8552                	mv	a0,s4
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	71a080e7          	jalr	1818(ra) # 80002fa2 <release>
  acquire(lk);
    80002890:	854a                	mv	a0,s2
    80002892:	00000097          	auipc	ra,0x0
    80002896:	65c080e7          	jalr	1628(ra) # 80002eee <acquire>
}
    8000289a:	70a2                	ld	ra,40(sp)
    8000289c:	7402                	ld	s0,32(sp)
    8000289e:	64e2                	ld	s1,24(sp)
    800028a0:	6942                	ld	s2,16(sp)
    800028a2:	69a2                	ld	s3,8(sp)
    800028a4:	6a02                	ld	s4,0(sp)
    800028a6:	6145                	add	sp,sp,48
    800028a8:	8082                	ret

00000000800028aa <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028aa:	7139                	add	sp,sp,-64
    800028ac:	fc06                	sd	ra,56(sp)
    800028ae:	f822                	sd	s0,48(sp)
    800028b0:	f426                	sd	s1,40(sp)
    800028b2:	f04a                	sd	s2,32(sp)
    800028b4:	ec4e                	sd	s3,24(sp)
    800028b6:	e852                	sd	s4,16(sp)
    800028b8:	e456                	sd	s5,8(sp)
    800028ba:	e05a                	sd	s6,0(sp)
    800028bc:	0080                	add	s0,sp,64
    800028be:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800028c0:	0000f497          	auipc	s1,0xf
    800028c4:	de848493          	add	s1,s1,-536 # 800116a8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800028c8:	4a09                	li	s4,2
        p->state = RUNNABLE;
    800028ca:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800028cc:	00014997          	auipc	s3,0x14
    800028d0:	7dc98993          	add	s3,s3,2012 # 800170a8 <wait_lock>
    800028d4:	a811                	j	800028e8 <wakeup+0x3e>
      }
      release(&p->lock);
    800028d6:	854a                	mv	a0,s2
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	6ca080e7          	jalr	1738(ra) # 80002fa2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800028e0:	16848493          	add	s1,s1,360
    800028e4:	03348863          	beq	s1,s3,80002914 <wakeup+0x6a>
    if(p != myproc()){
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	826080e7          	jalr	-2010(ra) # 8000210e <myproc>
    800028f0:	fea488e3          	beq	s1,a0,800028e0 <wakeup+0x36>
      acquire(&p->lock);
    800028f4:	00848913          	add	s2,s1,8
    800028f8:	854a                	mv	a0,s2
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	5f4080e7          	jalr	1524(ra) # 80002eee <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002902:	509c                	lw	a5,32(s1)
    80002904:	fd4799e3          	bne	a5,s4,800028d6 <wakeup+0x2c>
    80002908:	789c                	ld	a5,48(s1)
    8000290a:	fd5796e3          	bne	a5,s5,800028d6 <wakeup+0x2c>
        p->state = RUNNABLE;
    8000290e:	0364a023          	sw	s6,32(s1)
    80002912:	b7d1                	j	800028d6 <wakeup+0x2c>
    }
  }
}
    80002914:	70e2                	ld	ra,56(sp)
    80002916:	7442                	ld	s0,48(sp)
    80002918:	74a2                	ld	s1,40(sp)
    8000291a:	7902                	ld	s2,32(sp)
    8000291c:	69e2                	ld	s3,24(sp)
    8000291e:	6a42                	ld	s4,16(sp)
    80002920:	6aa2                	ld	s5,8(sp)
    80002922:	6b02                	ld	s6,0(sp)
    80002924:	6121                	add	sp,sp,64
    80002926:	8082                	ret

0000000080002928 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002928:	7179                	add	sp,sp,-48
    8000292a:	f406                	sd	ra,40(sp)
    8000292c:	f022                	sd	s0,32(sp)
    8000292e:	ec26                	sd	s1,24(sp)
    80002930:	e84a                	sd	s2,16(sp)
    80002932:	e44e                	sd	s3,8(sp)
    80002934:	e052                	sd	s4,0(sp)
    80002936:	1800                	add	s0,sp,48
    80002938:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000293a:	0000f497          	auipc	s1,0xf
    8000293e:	d6e48493          	add	s1,s1,-658 # 800116a8 <proc>
    80002942:	00014a17          	auipc	s4,0x14
    80002946:	766a0a13          	add	s4,s4,1894 # 800170a8 <wait_lock>
    acquire(&p->lock);
    8000294a:	00848913          	add	s2,s1,8
    8000294e:	854a                	mv	a0,s2
    80002950:	00000097          	auipc	ra,0x0
    80002954:	59e080e7          	jalr	1438(ra) # 80002eee <acquire>
    if(p->pid == pid){
    80002958:	409c                	lw	a5,0(s1)
    8000295a:	01378d63          	beq	a5,s3,80002974 <kill+0x4c>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000295e:	854a                	mv	a0,s2
    80002960:	00000097          	auipc	ra,0x0
    80002964:	642080e7          	jalr	1602(ra) # 80002fa2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002968:	16848493          	add	s1,s1,360
    8000296c:	fd449fe3          	bne	s1,s4,8000294a <kill+0x22>
  }
  return -1;
    80002970:	557d                	li	a0,-1
    80002972:	a829                	j	8000298c <kill+0x64>
      p->killed = 1;
    80002974:	4785                	li	a5,1
    80002976:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002978:	5098                	lw	a4,32(s1)
    8000297a:	4789                	li	a5,2
    8000297c:	02f70063          	beq	a4,a5,8000299c <kill+0x74>
      release(&p->lock);
    80002980:	854a                	mv	a0,s2
    80002982:	00000097          	auipc	ra,0x0
    80002986:	620080e7          	jalr	1568(ra) # 80002fa2 <release>
      return 0;
    8000298a:	4501                	li	a0,0
}
    8000298c:	70a2                	ld	ra,40(sp)
    8000298e:	7402                	ld	s0,32(sp)
    80002990:	64e2                	ld	s1,24(sp)
    80002992:	6942                	ld	s2,16(sp)
    80002994:	69a2                	ld	s3,8(sp)
    80002996:	6a02                	ld	s4,0(sp)
    80002998:	6145                	add	sp,sp,48
    8000299a:	8082                	ret
        p->state = RUNNABLE;
    8000299c:	478d                	li	a5,3
    8000299e:	d09c                	sw	a5,32(s1)
    800029a0:	b7c5                	j	80002980 <kill+0x58>

00000000800029a2 <setkilled>:

void
setkilled(struct proc *p)
{
    800029a2:	1101                	add	sp,sp,-32
    800029a4:	ec06                	sd	ra,24(sp)
    800029a6:	e822                	sd	s0,16(sp)
    800029a8:	e426                	sd	s1,8(sp)
    800029aa:	e04a                	sd	s2,0(sp)
    800029ac:	1000                	add	s0,sp,32
    800029ae:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800029b0:	00850913          	add	s2,a0,8
    800029b4:	854a                	mv	a0,s2
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	538080e7          	jalr	1336(ra) # 80002eee <acquire>
  p->killed = 1;
    800029be:	4785                	li	a5,1
    800029c0:	dc9c                	sw	a5,56(s1)
  release(&p->lock);
    800029c2:	854a                	mv	a0,s2
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	5de080e7          	jalr	1502(ra) # 80002fa2 <release>
}
    800029cc:	60e2                	ld	ra,24(sp)
    800029ce:	6442                	ld	s0,16(sp)
    800029d0:	64a2                	ld	s1,8(sp)
    800029d2:	6902                	ld	s2,0(sp)
    800029d4:	6105                	add	sp,sp,32
    800029d6:	8082                	ret

00000000800029d8 <killed>:

int
killed(struct proc *p)
{
    800029d8:	1101                	add	sp,sp,-32
    800029da:	ec06                	sd	ra,24(sp)
    800029dc:	e822                	sd	s0,16(sp)
    800029de:	e426                	sd	s1,8(sp)
    800029e0:	e04a                	sd	s2,0(sp)
    800029e2:	1000                	add	s0,sp,32
    800029e4:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800029e6:	00850913          	add	s2,a0,8
    800029ea:	854a                	mv	a0,s2
    800029ec:	00000097          	auipc	ra,0x0
    800029f0:	502080e7          	jalr	1282(ra) # 80002eee <acquire>
  k = p->killed;
    800029f4:	5c84                	lw	s1,56(s1)
  release(&p->lock);
    800029f6:	854a                	mv	a0,s2
    800029f8:	00000097          	auipc	ra,0x0
    800029fc:	5aa080e7          	jalr	1450(ra) # 80002fa2 <release>
  return k;
}
    80002a00:	8526                	mv	a0,s1
    80002a02:	60e2                	ld	ra,24(sp)
    80002a04:	6442                	ld	s0,16(sp)
    80002a06:	64a2                	ld	s1,8(sp)
    80002a08:	6902                	ld	s2,0(sp)
    80002a0a:	6105                	add	sp,sp,32
    80002a0c:	8082                	ret

0000000080002a0e <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
    80002a0e:	711d                	add	sp,sp,-96
    80002a10:	ec86                	sd	ra,88(sp)
    80002a12:	e8a2                	sd	s0,80(sp)
    80002a14:	e4a6                	sd	s1,72(sp)
    80002a16:	e0ca                	sd	s2,64(sp)
    80002a18:	fc4e                	sd	s3,56(sp)
    80002a1a:	f852                	sd	s4,48(sp)
    80002a1c:	f456                	sd	s5,40(sp)
    80002a1e:	f05a                	sd	s6,32(sp)
    80002a20:	ec5e                	sd	s7,24(sp)
    80002a22:	e862                	sd	s8,16(sp)
    80002a24:	e466                	sd	s9,8(sp)
    80002a26:	1080                	add	s0,sp,96
    80002a28:	8baa                	mv	s7,a0
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();
    80002a2a:	fffff097          	auipc	ra,0xfffff
    80002a2e:	6e4080e7          	jalr	1764(ra) # 8000210e <myproc>
    80002a32:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002a34:	00014517          	auipc	a0,0x14
    80002a38:	67450513          	add	a0,a0,1652 # 800170a8 <wait_lock>
    80002a3c:	00000097          	auipc	ra,0x0
    80002a40:	4b2080e7          	jalr	1202(ra) # 80002eee <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002a44:	4c01                	li	s8,0
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
    80002a46:	4a95                	li	s5,5
        havekids = 1;
    80002a48:	4b05                	li	s6,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002a4a:	00014997          	auipc	s3,0x14
    80002a4e:	65e98993          	add	s3,s3,1630 # 800170a8 <wait_lock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002a52:	00014c97          	auipc	s9,0x14
    80002a56:	656c8c93          	add	s9,s9,1622 # 800170a8 <wait_lock>
    80002a5a:	a8f1                	j	80002b36 <wait+0x128>
          printf("wait: found zombie pid=%d\n", pp->pid);
    80002a5c:	408c                	lw	a1,0(s1)
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	a8a50513          	add	a0,a0,-1398 # 800084e8 <digits+0x2f8>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	7c4080e7          	jalr	1988(ra) # 8000122a <printf>
          pid = pp->pid;
    80002a6e:	0004a983          	lw	s3,0(s1)
          if(addr != 0 && uvm_copyout(p->pgtbl, addr, (uint64)&pp->exit_state,
    80002a72:	000b8e63          	beqz	s7,80002a8e <wait+0x80>
    80002a76:	4691                	li	a3,4
    80002a78:	03c48613          	add	a2,s1,60
    80002a7c:	85de                	mv	a1,s7
    80002a7e:	04893503          	ld	a0,72(s2)
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	2fa080e7          	jalr	762(ra) # 80001d7c <uvm_copyout>
    80002a8a:	04054263          	bltz	a0,80002ace <wait+0xc0>
          freeproc(pp);
    80002a8e:	8526                	mv	a0,s1
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	8e4080e7          	jalr	-1820(ra) # 80002374 <freeproc>
          release(&pp->lock);
    80002a98:	8552                	mv	a0,s4
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	508080e7          	jalr	1288(ra) # 80002fa2 <release>
          release(&wait_lock);
    80002aa2:	00014517          	auipc	a0,0x14
    80002aa6:	60650513          	add	a0,a0,1542 # 800170a8 <wait_lock>
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	4f8080e7          	jalr	1272(ra) # 80002fa2 <release>
  }
}
    80002ab2:	854e                	mv	a0,s3
    80002ab4:	60e6                	ld	ra,88(sp)
    80002ab6:	6446                	ld	s0,80(sp)
    80002ab8:	64a6                	ld	s1,72(sp)
    80002aba:	6906                	ld	s2,64(sp)
    80002abc:	79e2                	ld	s3,56(sp)
    80002abe:	7a42                	ld	s4,48(sp)
    80002ac0:	7aa2                	ld	s5,40(sp)
    80002ac2:	7b02                	ld	s6,32(sp)
    80002ac4:	6be2                	ld	s7,24(sp)
    80002ac6:	6c42                	ld	s8,16(sp)
    80002ac8:	6ca2                	ld	s9,8(sp)
    80002aca:	6125                	add	sp,sp,96
    80002acc:	8082                	ret
            release(&pp->lock);
    80002ace:	8552                	mv	a0,s4
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	4d2080e7          	jalr	1234(ra) # 80002fa2 <release>
            release(&wait_lock);
    80002ad8:	00014517          	auipc	a0,0x14
    80002adc:	5d050513          	add	a0,a0,1488 # 800170a8 <wait_lock>
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	4c2080e7          	jalr	1218(ra) # 80002fa2 <release>
            return -1;
    80002ae8:	59fd                	li	s3,-1
    80002aea:	b7e1                	j	80002ab2 <wait+0xa4>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002aec:	16848493          	add	s1,s1,360
    80002af0:	03348663          	beq	s1,s3,80002b1c <wait+0x10e>
      if(pp->parent == p){
    80002af4:	749c                	ld	a5,40(s1)
    80002af6:	ff279be3          	bne	a5,s2,80002aec <wait+0xde>
        acquire(&pp->lock);
    80002afa:	00848a13          	add	s4,s1,8
    80002afe:	8552                	mv	a0,s4
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	3ee080e7          	jalr	1006(ra) # 80002eee <acquire>
        if(pp->state == ZOMBIE){
    80002b08:	509c                	lw	a5,32(s1)
    80002b0a:	f55789e3          	beq	a5,s5,80002a5c <wait+0x4e>
        release(&pp->lock);
    80002b0e:	8552                	mv	a0,s4
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	492080e7          	jalr	1170(ra) # 80002fa2 <release>
        havekids = 1;
    80002b18:	875a                	mv	a4,s6
    80002b1a:	bfc9                	j	80002aec <wait+0xde>
    if(!havekids || killed(p)){
    80002b1c:	c31d                	beqz	a4,80002b42 <wait+0x134>
    80002b1e:	854a                	mv	a0,s2
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	eb8080e7          	jalr	-328(ra) # 800029d8 <killed>
    80002b28:	ed09                	bnez	a0,80002b42 <wait+0x134>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b2a:	85e6                	mv	a1,s9
    80002b2c:	854a                	mv	a0,s2
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	d0e080e7          	jalr	-754(ra) # 8000283c <sleep>
    havekids = 0;
    80002b36:	8762                	mv	a4,s8
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b38:	0000f497          	auipc	s1,0xf
    80002b3c:	b7048493          	add	s1,s1,-1168 # 800116a8 <proc>
    80002b40:	bf55                	j	80002af4 <wait+0xe6>
      release(&wait_lock);
    80002b42:	00014517          	auipc	a0,0x14
    80002b46:	56650513          	add	a0,a0,1382 # 800170a8 <wait_lock>
    80002b4a:	00000097          	auipc	ra,0x0
    80002b4e:	458080e7          	jalr	1112(ra) # 80002fa2 <release>
      return -1;
    80002b52:	59fd                	li	s3,-1
    80002b54:	bfb9                	j	80002ab2 <wait+0xa4>

0000000080002b56 <reparent>:

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
    80002b56:	7179                	add	sp,sp,-48
    80002b58:	f406                	sd	ra,40(sp)
    80002b5a:	f022                	sd	s0,32(sp)
    80002b5c:	ec26                	sd	s1,24(sp)
    80002b5e:	e84a                	sd	s2,16(sp)
    80002b60:	e44e                	sd	s3,8(sp)
    80002b62:	e052                	sd	s4,0(sp)
    80002b64:	1800                	add	s0,sp,48
    80002b66:	892a                	mv	s2,a0
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b68:	0000f497          	auipc	s1,0xf
    80002b6c:	b4048493          	add	s1,s1,-1216 # 800116a8 <proc>
    if(pp->parent == p){
      pp->parent = proczero;
    80002b70:	00006a17          	auipc	s4,0x6
    80002b74:	338a0a13          	add	s4,s4,824 # 80008ea8 <proczero>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b78:	00014997          	auipc	s3,0x14
    80002b7c:	53098993          	add	s3,s3,1328 # 800170a8 <wait_lock>
    80002b80:	a029                	j	80002b8a <reparent+0x34>
    80002b82:	16848493          	add	s1,s1,360
    80002b86:	01348d63          	beq	s1,s3,80002ba0 <reparent+0x4a>
    if(pp->parent == p){
    80002b8a:	749c                	ld	a5,40(s1)
    80002b8c:	ff279be3          	bne	a5,s2,80002b82 <reparent+0x2c>
      pp->parent = proczero;
    80002b90:	000a3503          	ld	a0,0(s4)
    80002b94:	f488                	sd	a0,40(s1)
      wakeup(proczero);
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	d14080e7          	jalr	-748(ra) # 800028aa <wakeup>
    80002b9e:	b7d5                	j	80002b82 <reparent+0x2c>
    }
  }
}
    80002ba0:	70a2                	ld	ra,40(sp)
    80002ba2:	7402                	ld	s0,32(sp)
    80002ba4:	64e2                	ld	s1,24(sp)
    80002ba6:	6942                	ld	s2,16(sp)
    80002ba8:	69a2                	ld	s3,8(sp)
    80002baa:	6a02                	ld	s4,0(sp)
    80002bac:	6145                	add	sp,sp,48
    80002bae:	8082                	ret

0000000080002bb0 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
    80002bb0:	7179                	add	sp,sp,-48
    80002bb2:	f406                	sd	ra,40(sp)
    80002bb4:	f022                	sd	s0,32(sp)
    80002bb6:	ec26                	sd	s1,24(sp)
    80002bb8:	e84a                	sd	s2,16(sp)
    80002bba:	e44e                	sd	s3,8(sp)
    80002bbc:	e052                	sd	s4,0(sp)
    80002bbe:	1800                	add	s0,sp,48
    80002bc0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	54c080e7          	jalr	1356(ra) # 8000210e <myproc>
    80002bca:	89aa                	mv	s3,a0

  if(p == proczero)
    80002bcc:	00006797          	auipc	a5,0x6
    80002bd0:	2dc7b783          	ld	a5,732(a5) # 80008ea8 <proczero>
    80002bd4:	06050493          	add	s1,a0,96
    80002bd8:	0e050913          	add	s2,a0,224
    80002bdc:	02a79363          	bne	a5,a0,80002c02 <exit+0x52>
    panic("init exiting");
    80002be0:	00006517          	auipc	a0,0x6
    80002be4:	92850513          	add	a0,a0,-1752 # 80008508 <digits+0x318>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	5f8080e7          	jalr	1528(ra) # 800011e0 <panic>

  // Close all open files. 
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
    80002bf0:	00003097          	auipc	ra,0x3
    80002bf4:	ec8080e7          	jalr	-312(ra) # 80005ab8 <fileclose>
      p->ofile[fd] = 0;
    80002bf8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002bfc:	04a1                	add	s1,s1,8
    80002bfe:	01248563          	beq	s1,s2,80002c08 <exit+0x58>
    if(p->ofile[fd]){
    80002c02:	6088                	ld	a0,0(s1)
    80002c04:	f575                	bnez	a0,80002bf0 <exit+0x40>
    80002c06:	bfdd                	j	80002bfc <exit+0x4c>
    }
  }

  begin_op();
    80002c08:	00003097          	auipc	ra,0x3
    80002c0c:	b16080e7          	jalr	-1258(ra) # 8000571e <begin_op>
  iput(p->cwd);
    80002c10:	0e09b503          	ld	a0,224(s3)
    80002c14:	00002097          	auipc	ra,0x2
    80002c18:	032080e7          	jalr	50(ra) # 80004c46 <iput>
  end_op();
    80002c1c:	00003097          	auipc	ra,0x3
    80002c20:	b7c080e7          	jalr	-1156(ra) # 80005798 <end_op>
  p->cwd = 0;
    80002c24:	0e09b023          	sd	zero,224(s3)

  acquire(&wait_lock);
    80002c28:	00014497          	auipc	s1,0x14
    80002c2c:	48048493          	add	s1,s1,1152 # 800170a8 <wait_lock>
    80002c30:	8526                	mv	a0,s1
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	2bc080e7          	jalr	700(ra) # 80002eee <acquire>

  // Give any children to init.
  reparent(p);
    80002c3a:	854e                	mv	a0,s3
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	f1a080e7          	jalr	-230(ra) # 80002b56 <reparent>

  // Parent might be sleeping in wait().
  wakeup(p->parent);
    80002c44:	0289b503          	ld	a0,40(s3)
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	c62080e7          	jalr	-926(ra) # 800028aa <wakeup>
  
  acquire(&p->lock);
    80002c50:	00898513          	add	a0,s3,8
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	29a080e7          	jalr	666(ra) # 80002eee <acquire>

  p->exit_state = status;
    80002c5c:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    80002c60:	4795                	li	a5,5
    80002c62:	02f9a023          	sw	a5,32(s3)

  release(&wait_lock);
    80002c66:	8526                	mv	a0,s1
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	33a080e7          	jalr	826(ra) # 80002fa2 <release>

  // Jump into the scheduler, never to return.
  sched();
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	5d0080e7          	jalr	1488(ra) # 80003240 <sched>
  panic("zombie exit");
    80002c78:	00006517          	auipc	a0,0x6
    80002c7c:	8a050513          	add	a0,a0,-1888 # 80008518 <digits+0x328>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	560080e7          	jalr	1376(ra) # 800011e0 <panic>

0000000080002c88 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002c88:	7179                	add	sp,sp,-48
    80002c8a:	f406                	sd	ra,40(sp)
    80002c8c:	f022                	sd	s0,32(sp)
    80002c8e:	ec26                	sd	s1,24(sp)
    80002c90:	e84a                	sd	s2,16(sp)
    80002c92:	e44e                	sd	s3,8(sp)
    80002c94:	e052                	sd	s4,0(sp)
    80002c96:	1800                	add	s0,sp,48
    80002c98:	84aa                	mv	s1,a0
    80002c9a:	892e                	mv	s2,a1
    80002c9c:	89b2                	mv	s3,a2
    80002c9e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	46e080e7          	jalr	1134(ra) # 8000210e <myproc>
  if(user_dst){
    80002ca8:	c08d                	beqz	s1,80002cca <either_copyout+0x42>
    return copyout(p->pgtbl, dst, src, len);
    80002caa:	86d2                	mv	a3,s4
    80002cac:	864e                	mv	a2,s3
    80002cae:	85ca                	mv	a1,s2
    80002cb0:	6528                	ld	a0,72(a0)
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	25a080e7          	jalr	602(ra) # 80001f0c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002cba:	70a2                	ld	ra,40(sp)
    80002cbc:	7402                	ld	s0,32(sp)
    80002cbe:	64e2                	ld	s1,24(sp)
    80002cc0:	6942                	ld	s2,16(sp)
    80002cc2:	69a2                	ld	s3,8(sp)
    80002cc4:	6a02                	ld	s4,0(sp)
    80002cc6:	6145                	add	sp,sp,48
    80002cc8:	8082                	ret
    memmove((char *)dst, src, len);
    80002cca:	000a061b          	sext.w	a2,s4
    80002cce:	85ce                	mv	a1,s3
    80002cd0:	854a                	mv	a0,s2
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	322080e7          	jalr	802(ra) # 80000ff4 <memmove>
    return 0;
    80002cda:	8526                	mv	a0,s1
    80002cdc:	bff9                	j	80002cba <either_copyout+0x32>

0000000080002cde <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002cde:	7179                	add	sp,sp,-48
    80002ce0:	f406                	sd	ra,40(sp)
    80002ce2:	f022                	sd	s0,32(sp)
    80002ce4:	ec26                	sd	s1,24(sp)
    80002ce6:	e84a                	sd	s2,16(sp)
    80002ce8:	e44e                	sd	s3,8(sp)
    80002cea:	e052                	sd	s4,0(sp)
    80002cec:	1800                	add	s0,sp,48
    80002cee:	892a                	mv	s2,a0
    80002cf0:	84ae                	mv	s1,a1
    80002cf2:	89b2                	mv	s3,a2
    80002cf4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	418080e7          	jalr	1048(ra) # 8000210e <myproc>
  if(user_src){
    80002cfe:	c08d                	beqz	s1,80002d20 <either_copyin+0x42>
    return copyin(p->pgtbl, dst, src, len);
    80002d00:	86d2                	mv	a3,s4
    80002d02:	864e                	mv	a2,s3
    80002d04:	85ca                	mv	a1,s2
    80002d06:	6528                	ld	a0,72(a0)
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	296080e7          	jalr	662(ra) # 80001f9e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002d10:	70a2                	ld	ra,40(sp)
    80002d12:	7402                	ld	s0,32(sp)
    80002d14:	64e2                	ld	s1,24(sp)
    80002d16:	6942                	ld	s2,16(sp)
    80002d18:	69a2                	ld	s3,8(sp)
    80002d1a:	6a02                	ld	s4,0(sp)
    80002d1c:	6145                	add	sp,sp,48
    80002d1e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002d20:	000a061b          	sext.w	a2,s4
    80002d24:	85ce                	mv	a1,s3
    80002d26:	854a                	mv	a0,s2
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	2cc080e7          	jalr	716(ra) # 80000ff4 <memmove>
    return 0;
    80002d30:	8526                	mv	a0,s1
    80002d32:	bff9                	j	80002d10 <either_copyin+0x32>

0000000080002d34 <initsleeplock>:
#include "proc-h/proc.h"
#include "proc-h/cpu.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80002d34:	1101                	add	sp,sp,-32
    80002d36:	ec06                	sd	ra,24(sp)
    80002d38:	e822                	sd	s0,16(sp)
    80002d3a:	e426                	sd	s1,8(sp)
    80002d3c:	e04a                	sd	s2,0(sp)
    80002d3e:	1000                	add	s0,sp,32
    80002d40:	84aa                	mv	s1,a0
    80002d42:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80002d44:	00005597          	auipc	a1,0x5
    80002d48:	7e458593          	add	a1,a1,2020 # 80008528 <digits+0x338>
    80002d4c:	0521                	add	a0,a0,8
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	110080e7          	jalr	272(ra) # 80002e5e <initlock>
  lk->name = name;
    80002d56:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80002d5a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80002d5e:	0204a423          	sw	zero,40(s1)
}
    80002d62:	60e2                	ld	ra,24(sp)
    80002d64:	6442                	ld	s0,16(sp)
    80002d66:	64a2                	ld	s1,8(sp)
    80002d68:	6902                	ld	s2,0(sp)
    80002d6a:	6105                	add	sp,sp,32
    80002d6c:	8082                	ret

0000000080002d6e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80002d6e:	1101                	add	sp,sp,-32
    80002d70:	ec06                	sd	ra,24(sp)
    80002d72:	e822                	sd	s0,16(sp)
    80002d74:	e426                	sd	s1,8(sp)
    80002d76:	e04a                	sd	s2,0(sp)
    80002d78:	1000                	add	s0,sp,32
    80002d7a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80002d7c:	00850913          	add	s2,a0,8
    80002d80:	854a                	mv	a0,s2
    80002d82:	00000097          	auipc	ra,0x0
    80002d86:	16c080e7          	jalr	364(ra) # 80002eee <acquire>

  // printf("acquiresleep: trying to acquire lock %p\n", lk);


  while (lk->locked) {
    80002d8a:	409c                	lw	a5,0(s1)
    80002d8c:	cb89                	beqz	a5,80002d9e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80002d8e:	85ca                	mv	a1,s2
    80002d90:	8526                	mv	a0,s1
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	aaa080e7          	jalr	-1366(ra) # 8000283c <sleep>
  while (lk->locked) {
    80002d9a:	409c                	lw	a5,0(s1)
    80002d9c:	fbed                	bnez	a5,80002d8e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80002d9e:	4785                	li	a5,1
    80002da0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	36c080e7          	jalr	876(ra) # 8000210e <myproc>
    80002daa:	411c                	lw	a5,0(a0)
    80002dac:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80002dae:	854a                	mv	a0,s2
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	1f2080e7          	jalr	498(ra) # 80002fa2 <release>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	64a2                	ld	s1,8(sp)
    80002dbe:	6902                	ld	s2,0(sp)
    80002dc0:	6105                	add	sp,sp,32
    80002dc2:	8082                	ret

0000000080002dc4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80002dc4:	1101                	add	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	e426                	sd	s1,8(sp)
    80002dcc:	e04a                	sd	s2,0(sp)
    80002dce:	1000                	add	s0,sp,32
    80002dd0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80002dd2:	00850913          	add	s2,a0,8
    80002dd6:	854a                	mv	a0,s2
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	116080e7          	jalr	278(ra) # 80002eee <acquire>
  lk->locked = 0;
    80002de0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80002de4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80002de8:	8526                	mv	a0,s1
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	ac0080e7          	jalr	-1344(ra) # 800028aa <wakeup>
  release(&lk->lk);
    80002df2:	854a                	mv	a0,s2
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	1ae080e7          	jalr	430(ra) # 80002fa2 <release>
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6902                	ld	s2,0(sp)
    80002e04:	6105                	add	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80002e08:	7179                	add	sp,sp,-48
    80002e0a:	f406                	sd	ra,40(sp)
    80002e0c:	f022                	sd	s0,32(sp)
    80002e0e:	ec26                	sd	s1,24(sp)
    80002e10:	e84a                	sd	s2,16(sp)
    80002e12:	e44e                	sd	s3,8(sp)
    80002e14:	1800                	add	s0,sp,48
    80002e16:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80002e18:	00850913          	add	s2,a0,8
    80002e1c:	854a                	mv	a0,s2
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	0d0080e7          	jalr	208(ra) # 80002eee <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80002e26:	409c                	lw	a5,0(s1)
    80002e28:	ef99                	bnez	a5,80002e46 <holdingsleep+0x3e>
    80002e2a:	4481                	li	s1,0
  release(&lk->lk);
    80002e2c:	854a                	mv	a0,s2
    80002e2e:	00000097          	auipc	ra,0x0
    80002e32:	174080e7          	jalr	372(ra) # 80002fa2 <release>
  return r;
}
    80002e36:	8526                	mv	a0,s1
    80002e38:	70a2                	ld	ra,40(sp)
    80002e3a:	7402                	ld	s0,32(sp)
    80002e3c:	64e2                	ld	s1,24(sp)
    80002e3e:	6942                	ld	s2,16(sp)
    80002e40:	69a2                	ld	s3,8(sp)
    80002e42:	6145                	add	sp,sp,48
    80002e44:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80002e46:	0284a983          	lw	s3,40(s1)
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	2c4080e7          	jalr	708(ra) # 8000210e <myproc>
    80002e52:	4104                	lw	s1,0(a0)
    80002e54:	413484b3          	sub	s1,s1,s3
    80002e58:	0014b493          	seqz	s1,s1
    80002e5c:	bfc1                	j	80002e2c <holdingsleep+0x24>

0000000080002e5e <initlock>:
#include "proc-h/cpu.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80002e5e:	1141                	add	sp,sp,-16
    80002e60:	e422                	sd	s0,8(sp)
    80002e62:	0800                	add	s0,sp,16
  lk->name = name;
    80002e64:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80002e66:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80002e6a:	00053823          	sd	zero,16(a0)
}
    80002e6e:	6422                	ld	s0,8(sp)
    80002e70:	0141                	add	sp,sp,16
    80002e72:	8082                	ret

0000000080002e74 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80002e74:	411c                	lw	a5,0(a0)
    80002e76:	e399                	bnez	a5,80002e7c <holding+0x8>
    80002e78:	4501                	li	a0,0
  return r;
}
    80002e7a:	8082                	ret
{
    80002e7c:	1101                	add	sp,sp,-32
    80002e7e:	ec06                	sd	ra,24(sp)
    80002e80:	e822                	sd	s0,16(sp)
    80002e82:	e426                	sd	s1,8(sp)
    80002e84:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80002e86:	6904                	ld	s1,16(a0)
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	26a080e7          	jalr	618(ra) # 800020f2 <mycpu>
    80002e90:	40a48533          	sub	a0,s1,a0
    80002e94:	00153513          	seqz	a0,a0
}
    80002e98:	60e2                	ld	ra,24(sp)
    80002e9a:	6442                	ld	s0,16(sp)
    80002e9c:	64a2                	ld	s1,8(sp)
    80002e9e:	6105                	add	sp,sp,32
    80002ea0:	8082                	ret

0000000080002ea2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80002ea2:	1101                	add	sp,sp,-32
    80002ea4:	ec06                	sd	ra,24(sp)
    80002ea6:	e822                	sd	s0,16(sp)
    80002ea8:	e426                	sd	s1,8(sp)
    80002eaa:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eac:	100024f3          	csrr	s1,sstatus
    80002eb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002eb4:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eb6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	238080e7          	jalr	568(ra) # 800020f2 <mycpu>
    80002ec2:	411c                	lw	a5,0(a0)
    80002ec4:	cf89                	beqz	a5,80002ede <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	22c080e7          	jalr	556(ra) # 800020f2 <mycpu>
    80002ece:	411c                	lw	a5,0(a0)
    80002ed0:	2785                	addw	a5,a5,1
    80002ed2:	c11c                	sw	a5,0(a0)
}
    80002ed4:	60e2                	ld	ra,24(sp)
    80002ed6:	6442                	ld	s0,16(sp)
    80002ed8:	64a2                	ld	s1,8(sp)
    80002eda:	6105                	add	sp,sp,32
    80002edc:	8082                	ret
    mycpu()->intena = old;
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	214080e7          	jalr	532(ra) # 800020f2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80002ee6:	8085                	srl	s1,s1,0x1
    80002ee8:	8885                	and	s1,s1,1
    80002eea:	c144                	sw	s1,4(a0)
    80002eec:	bfe9                	j	80002ec6 <push_off+0x24>

0000000080002eee <acquire>:
{
    80002eee:	1101                	add	sp,sp,-32
    80002ef0:	ec06                	sd	ra,24(sp)
    80002ef2:	e822                	sd	s0,16(sp)
    80002ef4:	e426                	sd	s1,8(sp)
    80002ef6:	1000                	add	s0,sp,32
    80002ef8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	fa8080e7          	jalr	-88(ra) # 80002ea2 <push_off>
  if(holding(lk))
    80002f02:	8526                	mv	a0,s1
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	f70080e7          	jalr	-144(ra) # 80002e74 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80002f0c:	4705                	li	a4,1
  if(holding(lk))
    80002f0e:	e115                	bnez	a0,80002f32 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80002f10:	87ba                	mv	a5,a4
    80002f12:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80002f16:	2781                	sext.w	a5,a5
    80002f18:	ffe5                	bnez	a5,80002f10 <acquire+0x22>
  __sync_synchronize();
    80002f1a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	1d4080e7          	jalr	468(ra) # 800020f2 <mycpu>
    80002f26:	e888                	sd	a0,16(s1)
}
    80002f28:	60e2                	ld	ra,24(sp)
    80002f2a:	6442                	ld	s0,16(sp)
    80002f2c:	64a2                	ld	s1,8(sp)
    80002f2e:	6105                	add	sp,sp,32
    80002f30:	8082                	ret
    panic("acquire");
    80002f32:	00005517          	auipc	a0,0x5
    80002f36:	60650513          	add	a0,a0,1542 # 80008538 <digits+0x348>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	2a6080e7          	jalr	678(ra) # 800011e0 <panic>

0000000080002f42 <pop_off>:

void
pop_off(void)
{
    80002f42:	1141                	add	sp,sp,-16
    80002f44:	e406                	sd	ra,8(sp)
    80002f46:	e022                	sd	s0,0(sp)
    80002f48:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	1a8080e7          	jalr	424(ra) # 800020f2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f52:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f56:	8b89                	and	a5,a5,2
  if(intr_get())
    80002f58:	e78d                	bnez	a5,80002f82 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80002f5a:	411c                	lw	a5,0(a0)
    80002f5c:	02f05b63          	blez	a5,80002f92 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80002f60:	37fd                	addw	a5,a5,-1
    80002f62:	0007871b          	sext.w	a4,a5
    80002f66:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    80002f68:	eb09                	bnez	a4,80002f7a <pop_off+0x38>
    80002f6a:	415c                	lw	a5,4(a0)
    80002f6c:	c799                	beqz	a5,80002f7a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f72:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f76:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80002f7a:	60a2                	ld	ra,8(sp)
    80002f7c:	6402                	ld	s0,0(sp)
    80002f7e:	0141                	add	sp,sp,16
    80002f80:	8082                	ret
    panic("pop_off - interruptible");
    80002f82:	00005517          	auipc	a0,0x5
    80002f86:	5be50513          	add	a0,a0,1470 # 80008540 <digits+0x350>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	256080e7          	jalr	598(ra) # 800011e0 <panic>
    panic("pop_off");
    80002f92:	00005517          	auipc	a0,0x5
    80002f96:	5c650513          	add	a0,a0,1478 # 80008558 <digits+0x368>
    80002f9a:	ffffe097          	auipc	ra,0xffffe
    80002f9e:	246080e7          	jalr	582(ra) # 800011e0 <panic>

0000000080002fa2 <release>:
{
    80002fa2:	1101                	add	sp,sp,-32
    80002fa4:	ec06                	sd	ra,24(sp)
    80002fa6:	e822                	sd	s0,16(sp)
    80002fa8:	e426                	sd	s1,8(sp)
    80002faa:	e04a                	sd	s2,0(sp)
    80002fac:	1000                	add	s0,sp,32
    80002fae:	84aa                	mv	s1,a0
  if(!holding(lk))
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	ec4080e7          	jalr	-316(ra) # 80002e74 <holding>
    80002fb8:	c11d                	beqz	a0,80002fde <release+0x3c>
  lk->cpu = 0;
    80002fba:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80002fbe:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80002fc2:	0f50000f          	fence	iorw,ow
    80002fc6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	f78080e7          	jalr	-136(ra) # 80002f42 <pop_off>
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	64a2                	ld	s1,8(sp)
    80002fd8:	6902                	ld	s2,0(sp)
    80002fda:	6105                	add	sp,sp,32
    80002fdc:	8082                	ret
    printf("release lock %s at %p, cpu%d\n", lk->name, lk, cpuid());
    80002fde:	0084b903          	ld	s2,8(s1)
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	100080e7          	jalr	256(ra) # 800020e2 <cpuid>
    80002fea:	86aa                	mv	a3,a0
    80002fec:	8626                	mv	a2,s1
    80002fee:	85ca                	mv	a1,s2
    80002ff0:	00005517          	auipc	a0,0x5
    80002ff4:	57050513          	add	a0,a0,1392 # 80008560 <digits+0x370>
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	232080e7          	jalr	562(ra) # 8000122a <printf>
    panic("release");
    80003000:	00005517          	auipc	a0,0x5
    80003004:	58050513          	add	a0,a0,1408 # 80008580 <digits+0x390>
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	1d8080e7          	jalr	472(ra) # 800011e0 <panic>

0000000080003010 <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    80003010:	1141                	add	sp,sp,-16
    80003012:	e422                	sd	s0,8(sp)
    80003014:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003016:	00004797          	auipc	a5,0x4
    8000301a:	e5a78793          	add	a5,a5,-422 # 80006e70 <kernelvec>
    8000301e:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    80003022:	6422                	ld	s0,8(sp)
    80003024:	0141                	add	sp,sp,16
    80003026:	8082                	ret

0000000080003028 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003028:	142027f3          	csrr	a5,scause
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    8000302c:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    8000302e:	0807df63          	bgez	a5,800030cc <devintr+0xa4>
{
    80003032:	1101                	add	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	e426                	sd	s1,8(sp)
    8000303a:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    8000303c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80003040:	46a5                	li	a3,9
    80003042:	00d70d63          	beq	a4,a3,8000305c <devintr+0x34>
  if(scause == 0x8000000000000001L){
    80003046:	577d                	li	a4,-1
    80003048:	177e                	sll	a4,a4,0x3f
    8000304a:	0705                	add	a4,a4,1
    return 0;  // 未识别的中断类型
    8000304c:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    8000304e:	04e78e63          	beq	a5,a4,800030aa <devintr+0x82>
  }
}
    80003052:	60e2                	ld	ra,24(sp)
    80003054:	6442                	ld	s0,16(sp)
    80003056:	64a2                	ld	s1,8(sp)
    80003058:	6105                	add	sp,sp,32
    8000305a:	8082                	ret
    int irq = plic_claim();  // 获取中断请求号
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	9a4080e7          	jalr	-1628(ra) # 80000a00 <plic_claim>
    80003064:	84aa                	mv	s1,a0
    switch(irq){
    80003066:	4785                	li	a5,1
    80003068:	02f50063          	beq	a0,a5,80003088 <devintr+0x60>
    8000306c:	47a9                	li	a5,10
    8000306e:	02f51263          	bne	a0,a5,80003092 <devintr+0x6a>
      uartintr();           // 处理串口中断
    80003072:	ffffd097          	auipc	ra,0xffffd
    80003076:	484080e7          	jalr	1156(ra) # 800004f6 <uartintr>
      plic_complete(irq);
    8000307a:	8526                	mv	a0,s1
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	9a8080e7          	jalr	-1624(ra) # 80000a24 <plic_complete>
    return 1;
    80003084:	4505                	li	a0,1
    80003086:	b7f1                	j	80003052 <devintr+0x2a>
      virtio_disk_intr();   // 处理虚拟磁盘中断
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	e5c080e7          	jalr	-420(ra) # 80000ee4 <virtio_disk_intr>
    if(irq)
    80003090:	b7ed                	j	8000307a <devintr+0x52>
    return 1;
    80003092:	4505                	li	a0,1
      if(irq){
    80003094:	dcdd                	beqz	s1,80003052 <devintr+0x2a>
        printf("unexpected interrupt irq=%d\n", irq);
    80003096:	85a6                	mv	a1,s1
    80003098:	00005517          	auipc	a0,0x5
    8000309c:	4f050513          	add	a0,a0,1264 # 80008588 <digits+0x398>
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	18a080e7          	jalr	394(ra) # 8000122a <printf>
    if(irq)
    800030a8:	bfc9                	j	8000307a <devintr+0x52>
    if(cpuid() == 0){
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	038080e7          	jalr	56(ra) # 800020e2 <cpuid>
    800030b2:	c901                	beqz	a0,800030c2 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030b4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800030b8:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800030ba:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    800030be:	4509                	li	a0,2
    800030c0:	bf49                	j	80003052 <devintr+0x2a>
      timer_update();
    800030c2:	ffffd097          	auipc	ra,0xffffd
    800030c6:	1b4080e7          	jalr	436(ra) # 80000276 <timer_update>
    800030ca:	b7ed                	j	800030b4 <devintr+0x8c>
}
    800030cc:	8082                	ret

00000000800030ce <kerneltrap>:
{
    800030ce:	7179                	add	sp,sp,-48
    800030d0:	f406                	sd	ra,40(sp)
    800030d2:	f022                	sd	s0,32(sp)
    800030d4:	ec26                	sd	s1,24(sp)
    800030d6:	e84a                	sd	s2,16(sp)
    800030d8:	e44e                	sd	s3,8(sp)
    800030da:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030dc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030e0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030e4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800030e8:	1004f793          	and	a5,s1,256
    800030ec:	cb85                	beqz	a5,8000311c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030ee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030f2:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    800030f4:	ef85                	bnez	a5,8000312c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	f32080e7          	jalr	-206(ra) # 80003028 <devintr>
    800030fe:	cd1d                	beqz	a0,8000313c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003100:	4789                	li	a5,2
    80003102:	08f50763          	beq	a0,a5,80003190 <kerneltrap+0xc2>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003106:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000310a:	10049073          	csrw	sstatus,s1
}
    8000310e:	70a2                	ld	ra,40(sp)
    80003110:	7402                	ld	s0,32(sp)
    80003112:	64e2                	ld	s1,24(sp)
    80003114:	6942                	ld	s2,16(sp)
    80003116:	69a2                	ld	s3,8(sp)
    80003118:	6145                	add	sp,sp,48
    8000311a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000311c:	00005517          	auipc	a0,0x5
    80003120:	48c50513          	add	a0,a0,1164 # 800085a8 <digits+0x3b8>
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	0bc080e7          	jalr	188(ra) # 800011e0 <panic>
    panic("kerneltrap: interrupts enabled");
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	4a450513          	add	a0,a0,1188 # 800085d0 <digits+0x3e0>
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	0ac080e7          	jalr	172(ra) # 800011e0 <panic>
    printf("scause %p\n", scause);
    8000313c:	85ce                	mv	a1,s3
    8000313e:	00005517          	auipc	a0,0x5
    80003142:	4b250513          	add	a0,a0,1202 # 800085f0 <digits+0x400>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	0e4080e7          	jalr	228(ra) # 8000122a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000314e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003152:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003156:	00005517          	auipc	a0,0x5
    8000315a:	4aa50513          	add	a0,a0,1194 # 80008600 <digits+0x410>
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	0cc080e7          	jalr	204(ra) # 8000122a <printf>
    printf("current process: %p\n", myproc());
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	fa8080e7          	jalr	-88(ra) # 8000210e <myproc>
    8000316e:	85aa                	mv	a1,a0
    80003170:	00005517          	auipc	a0,0x5
    80003174:	4a850513          	add	a0,a0,1192 # 80008618 <digits+0x428>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	0b2080e7          	jalr	178(ra) # 8000122a <printf>
    panic("kerneltrap");
    80003180:	00005517          	auipc	a0,0x5
    80003184:	4b050513          	add	a0,a0,1200 # 80008630 <digits+0x440>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	058080e7          	jalr	88(ra) # 800011e0 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003190:	fffff097          	auipc	ra,0xfffff
    80003194:	f7e080e7          	jalr	-130(ra) # 8000210e <myproc>
    80003198:	d53d                	beqz	a0,80003106 <kerneltrap+0x38>
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	f74080e7          	jalr	-140(ra) # 8000210e <myproc>
    800031a2:	5118                	lw	a4,32(a0)
    800031a4:	4791                	li	a5,4
    800031a6:	f6f710e3          	bne	a4,a5,80003106 <kerneltrap+0x38>
     yield();
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	154080e7          	jalr	340(ra) # 800032fe <yield>
    800031b2:	bf91                	j	80003106 <kerneltrap+0x38>

00000000800031b4 <scheduler>:
//  - 选择一个进程运行
//  - 通过swtch切换到该进程开始运行
//  - 最终该进程通过swtch将控制权交回给调度器
void
scheduler(void)
{
    800031b4:	715d                	add	sp,sp,-80
    800031b6:	e486                	sd	ra,72(sp)
    800031b8:	e0a2                	sd	s0,64(sp)
    800031ba:	fc26                	sd	s1,56(sp)
    800031bc:	f84a                	sd	s2,48(sp)
    800031be:	f44e                	sd	s3,40(sp)
    800031c0:	f052                	sd	s4,32(sp)
    800031c2:	ec56                	sd	s5,24(sp)
    800031c4:	e85a                	sd	s6,16(sp)
    800031c6:	e45e                	sd	s7,8(sp)
    800031c8:	0880                	add	s0,sp,80
  struct proc *p;
  struct cpu *c = mycpu();
    800031ca:	fffff097          	auipc	ra,0xfffff
    800031ce:	f28080e7          	jalr	-216(ra) # 800020f2 <mycpu>
    800031d2:	8aaa                	mv	s5,a0
  
  c->proc = 0;
    800031d4:	00053423          	sd	zero,8(a0)
    intr_on();

    // 遍历进程表，寻找可运行的进程
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
    800031d8:	4a0d                	li	s4,3
        // printf(" running process %d\n", p->pid);
        // 切换到选中的进程。进程有责任释放其锁
        // 然后在跳回调度器之前重新获取锁
        p->state = RUNNING;
    800031da:	4b91                	li	s7,4
        c->proc = p;
        
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    800031dc:	01050b13          	add	s6,a0,16
    for(p = proc; p < &proc[NPROC]; p++) {
    800031e0:	00014997          	auipc	s3,0x14
    800031e4:	ec898993          	add	s3,s3,-312 # 800170a8 <wait_lock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031e8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800031ec:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031f0:	10079073          	csrw	sstatus,a5
    800031f4:	0000e497          	auipc	s1,0xe
    800031f8:	4b448493          	add	s1,s1,1204 # 800116a8 <proc>
    800031fc:	a811                	j	80003210 <scheduler+0x5c>
        // 进程暂时运行完毕
        // 它应该在返回之前改变了p->state
        c->proc = 0;
        // printf(" process %d finished running\n", p->pid);
      }
      release(&p->lock);
    800031fe:	854a                	mv	a0,s2
    80003200:	00000097          	auipc	ra,0x0
    80003204:	da2080e7          	jalr	-606(ra) # 80002fa2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80003208:	16848493          	add	s1,s1,360
    8000320c:	fd348ee3          	beq	s1,s3,800031e8 <scheduler+0x34>
      acquire(&p->lock);
    80003210:	00848913          	add	s2,s1,8
    80003214:	854a                	mv	a0,s2
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	cd8080e7          	jalr	-808(ra) # 80002eee <acquire>
      if(p->state == RUNNABLE) {
    8000321e:	509c                	lw	a5,32(s1)
    80003220:	fd479fe3          	bne	a5,s4,800031fe <scheduler+0x4a>
        p->state = RUNNING;
    80003224:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    80003228:	009ab423          	sd	s1,8(s5)
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    8000322c:	0f848593          	add	a1,s1,248
    80003230:	855a                	mv	a0,s6
    80003232:	00004097          	auipc	ra,0x4
    80003236:	bc8080e7          	jalr	-1080(ra) # 80006dfa <initcode_end>
        c->proc = 0;
    8000323a:	000ab423          	sd	zero,8(s5)
    8000323e:	b7c1                	j	800031fe <scheduler+0x4a>

0000000080003240 <sched>:
// 并且已经改变了proc->state。
// 因为intena是这个内核线程的属性，而不是这个CPU的属性。
// 因此此处需要保存和恢复intena
void
sched(void)
{
    80003240:	1101                	add	sp,sp,-32
    80003242:	ec06                	sd	ra,24(sp)
    80003244:	e822                	sd	s0,16(sp)
    80003246:	e426                	sd	s1,8(sp)
    80003248:	e04a                	sd	s2,0(sp)
    8000324a:	1000                	add	s0,sp,32
  int intena;
  struct proc *p = myproc();
    8000324c:	fffff097          	auipc	ra,0xfffff
    80003250:	ec2080e7          	jalr	-318(ra) # 8000210e <myproc>
    80003254:	84aa                	mv	s1,a0

  if(!holding(&p->lock))
    80003256:	0521                	add	a0,a0,8
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	c1c080e7          	jalr	-996(ra) # 80002e74 <holding>
    80003260:	cd39                	beqz	a0,800032be <sched+0x7e>
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    80003262:	fffff097          	auipc	ra,0xfffff
    80003266:	e90080e7          	jalr	-368(ra) # 800020f2 <mycpu>
    8000326a:	4118                	lw	a4,0(a0)
    8000326c:	4785                	li	a5,1
    8000326e:	06f71063          	bne	a4,a5,800032ce <sched+0x8e>
    panic("sched locks");
  if(p->state == RUNNING)
    80003272:	5098                	lw	a4,32(s1)
    80003274:	4791                	li	a5,4
    80003276:	06f70463          	beq	a4,a5,800032de <sched+0x9e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000327a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000327e:	8b89                	and	a5,a5,2
    panic("sched running");
  if(intr_get())
    80003280:	e7bd                	bnez	a5,800032ee <sched+0xae>
    panic("sched interruptible");

  intena = mycpu()->intena;
    80003282:	fffff097          	auipc	ra,0xfffff
    80003286:	e70080e7          	jalr	-400(ra) # 800020f2 <mycpu>
    8000328a:	00452903          	lw	s2,4(a0)
  swtch(&p->ctx, &mycpu()->context);  // 切换到调度器上下文
    8000328e:	fffff097          	auipc	ra,0xfffff
    80003292:	e64080e7          	jalr	-412(ra) # 800020f2 <mycpu>
    80003296:	01050593          	add	a1,a0,16
    8000329a:	0f848513          	add	a0,s1,248
    8000329e:	00004097          	auipc	ra,0x4
    800032a2:	b5c080e7          	jalr	-1188(ra) # 80006dfa <initcode_end>
  mycpu()->intena = intena;
    800032a6:	fffff097          	auipc	ra,0xfffff
    800032aa:	e4c080e7          	jalr	-436(ra) # 800020f2 <mycpu>
    800032ae:	01252223          	sw	s2,4(a0)
}
    800032b2:	60e2                	ld	ra,24(sp)
    800032b4:	6442                	ld	s0,16(sp)
    800032b6:	64a2                	ld	s1,8(sp)
    800032b8:	6902                	ld	s2,0(sp)
    800032ba:	6105                	add	sp,sp,32
    800032bc:	8082                	ret
    panic("sched p->lock");
    800032be:	00005517          	auipc	a0,0x5
    800032c2:	38250513          	add	a0,a0,898 # 80008640 <digits+0x450>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	f1a080e7          	jalr	-230(ra) # 800011e0 <panic>
    panic("sched locks");
    800032ce:	00005517          	auipc	a0,0x5
    800032d2:	38250513          	add	a0,a0,898 # 80008650 <digits+0x460>
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	f0a080e7          	jalr	-246(ra) # 800011e0 <panic>
    panic("sched running");
    800032de:	00005517          	auipc	a0,0x5
    800032e2:	38250513          	add	a0,a0,898 # 80008660 <digits+0x470>
    800032e6:	ffffe097          	auipc	ra,0xffffe
    800032ea:	efa080e7          	jalr	-262(ra) # 800011e0 <panic>
    panic("sched interruptible");
    800032ee:	00005517          	auipc	a0,0x5
    800032f2:	38250513          	add	a0,a0,898 # 80008670 <digits+0x480>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	eea080e7          	jalr	-278(ra) # 800011e0 <panic>

00000000800032fe <yield>:

// 用于进程放弃CPU, 重新进入调度
void
yield(void)
{
    800032fe:	1101                	add	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	e04a                	sd	s2,0(sp)
    80003308:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    8000330a:	fffff097          	auipc	ra,0xfffff
    8000330e:	e04080e7          	jalr	-508(ra) # 8000210e <myproc>
    80003312:	84aa                	mv	s1,a0
  acquire(&p->lock);     // 获取进程锁
    80003314:	00850913          	add	s2,a0,8
    80003318:	854a                	mv	a0,s2
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	bd4080e7          	jalr	-1068(ra) # 80002eee <acquire>
  p->state = RUNNABLE;   // 将进程状态设为可运行
    80003322:	478d                	li	a5,3
    80003324:	d09c                	sw	a5,32(s1)
  sched();               // 调用sched()切换到调度器
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	f1a080e7          	jalr	-230(ra) # 80003240 <sched>
  release(&p->lock);     // 释放进程锁
    8000332e:	854a                	mv	a0,s2
    80003330:	00000097          	auipc	ra,0x0
    80003334:	c72080e7          	jalr	-910(ra) # 80002fa2 <release>
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	64a2                	ld	s1,8(sp)
    8000333e:	6902                	ld	s2,0(sp)
    80003340:	6105                	add	sp,sp,32
    80003342:	8082                	ret

0000000080003344 <trap_user_return>:
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
    80003344:	1141                	add	sp,sp,-16
    80003346:	e406                	sd	ra,8(sp)
    80003348:	e022                	sd	s0,0(sp)
    8000334a:	0800                	add	s0,sp,16
  //printf("trap_user_return\n");
  struct proc *p = myproc();
    8000334c:	fffff097          	auipc	ra,0xfffff
    80003350:	dc2080e7          	jalr	-574(ra) # 8000210e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003354:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003358:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000335a:	10079073          	csrw	sstatus,a5
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000335e:	00004697          	auipc	a3,0x4
    80003362:	ca268693          	add	a3,a3,-862 # 80007000 <_trampoline>
    80003366:	00004717          	auipc	a4,0x4
    8000336a:	c9a70713          	add	a4,a4,-870 # 80007000 <_trampoline>
    8000336e:	8f15                	sub	a4,a4,a3
    80003370:	040007b7          	lui	a5,0x4000
    80003374:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80003376:	07b2                	sll	a5,a5,0xc
    80003378:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000337a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
    8000337e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003380:	18002673          	csrr	a2,satp
    80003384:	e310                	sd	a2,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
    80003386:	6d30                	ld	a2,88(a0)
    80003388:	7978                	ld	a4,240(a0)
    8000338a:	6585                	lui	a1,0x1
    8000338c:	972e                	add	a4,a4,a1
    8000338e:	e618                	sd	a4,8(a2)
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
    80003390:	6d38                	ld	a4,88(a0)
    80003392:	00000617          	auipc	a2,0x0
    80003396:	04860613          	add	a2,a2,72 # 800033da <trap_user_handler>
    8000339a:	eb10                	sd	a2,16(a4)
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid
    8000339c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000339e:	8612                	mv	a2,tp
    800033a0:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033a2:	10002773          	csrr	a4,sstatus
  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
    800033a6:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
    800033aa:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033ae:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);
    800033b2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800033b4:	6f18                	ld	a4,24(a4)
    800033b6:	14171073          	csrw	sepc,a4

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);
    800033ba:	6528                	ld	a0,72(a0)
    800033bc:	8131                	srl	a0,a0,0xc

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800033be:	00004717          	auipc	a4,0x4
    800033c2:	cde70713          	add	a4,a4,-802 # 8000709c <userret>
    800033c6:	8f15                	sub	a4,a4,a3
    800033c8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800033ca:	577d                	li	a4,-1
    800033cc:	177e                	sll	a4,a4,0x3f
    800033ce:	8d59                	or	a0,a0,a4
    800033d0:	9782                	jalr	a5
    800033d2:	60a2                	ld	ra,8(sp)
    800033d4:	6402                	ld	s0,0(sp)
    800033d6:	0141                	add	sp,sp,16
    800033d8:	8082                	ret

00000000800033da <trap_user_handler>:
{
    800033da:	7139                	add	sp,sp,-64
    800033dc:	fc06                	sd	ra,56(sp)
    800033de:	f822                	sd	s0,48(sp)
    800033e0:	f426                	sd	s1,40(sp)
    800033e2:	f04a                	sd	s2,32(sp)
    800033e4:	ec4e                	sd	s3,24(sp)
    800033e6:	e852                	sd	s4,16(sp)
    800033e8:	e456                	sd	s5,8(sp)
    800033ea:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033ec:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033f0:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033f4:	14202a73          	csrr	s4,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    800033f8:	14302af3          	csrr	s5,stval
    proc_t* p = myproc();
    800033fc:	fffff097          	auipc	ra,0xfffff
    80003400:	d12080e7          	jalr	-750(ra) # 8000210e <myproc>
    if(sstatus & SSTATUS_SPP)
    80003404:	10097913          	and	s2,s2,256
    80003408:	04091b63          	bnez	s2,8000345e <trap_user_handler+0x84>
    8000340c:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000340e:	00004797          	auipc	a5,0x4
    80003412:	a6278793          	add	a5,a5,-1438 # 80006e70 <kernelvec>
    80003416:	10579073          	csrw	stvec,a5
  p->tf->epc = sepc;
    8000341a:	6d3c                	ld	a5,88(a0)
    8000341c:	0137bc23          	sd	s3,24(a5)
  if(scause == 8){
    80003420:	47a1                	li	a5,8
    80003422:	04fa0663          	beq	s4,a5,8000346e <trap_user_handler+0x94>
  } else if((which_dev = devintr()) != 0){
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	c02080e7          	jalr	-1022(ra) # 80003028 <devintr>
    8000342e:	892a                	mv	s2,a0
    80003430:	c549                	beqz	a0,800034ba <trap_user_handler+0xe0>
  if(killed(p))
    80003432:	8526                	mv	a0,s1
    80003434:	fffff097          	auipc	ra,0xfffff
    80003438:	5a4080e7          	jalr	1444(ra) # 800029d8 <killed>
    8000343c:	e13d                	bnez	a0,800034a2 <trap_user_handler+0xc8>
  if(which_dev == 2)
    8000343e:	4789                	li	a5,2
    80003440:	0af90963          	beq	s2,a5,800034f2 <trap_user_handler+0x118>
  trap_user_return();
    80003444:	00000097          	auipc	ra,0x0
    80003448:	f00080e7          	jalr	-256(ra) # 80003344 <trap_user_return>
}
    8000344c:	70e2                	ld	ra,56(sp)
    8000344e:	7442                	ld	s0,48(sp)
    80003450:	74a2                	ld	s1,40(sp)
    80003452:	7902                	ld	s2,32(sp)
    80003454:	69e2                	ld	s3,24(sp)
    80003456:	6a42                	ld	s4,16(sp)
    80003458:	6aa2                	ld	s5,8(sp)
    8000345a:	6121                	add	sp,sp,64
    8000345c:	8082                	ret
        panic("trap_user_handler: not from u-mode");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	22a50513          	add	a0,a0,554 # 80008688 <digits+0x498>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	d7a080e7          	jalr	-646(ra) # 800011e0 <panic>
    if(killed(p))
    8000346e:	fffff097          	auipc	ra,0xfffff
    80003472:	56a080e7          	jalr	1386(ra) # 800029d8 <killed>
    80003476:	ed05                	bnez	a0,800034ae <trap_user_handler+0xd4>
    p->tf->epc += 4;
    80003478:	6cb8                	ld	a4,88(s1)
    8000347a:	6f1c                	ld	a5,24(a4)
    8000347c:	0791                	add	a5,a5,4
    8000347e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003480:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003484:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003488:	10079073          	csrw	sstatus,a5
    syscall();
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	0d8080e7          	jalr	216(ra) # 80003564 <syscall>
  if(killed(p))
    80003494:	8526                	mv	a0,s1
    80003496:	fffff097          	auipc	ra,0xfffff
    8000349a:	542080e7          	jalr	1346(ra) # 800029d8 <killed>
    8000349e:	d15d                	beqz	a0,80003444 <trap_user_handler+0x6a>
    int which_dev = 0;  // 用于标识设备中断类型
    800034a0:	4901                	li	s2,0
    exit(-1);
    800034a2:	557d                	li	a0,-1
    800034a4:	fffff097          	auipc	ra,0xfffff
    800034a8:	70c080e7          	jalr	1804(ra) # 80002bb0 <exit>
    800034ac:	bf49                	j	8000343e <trap_user_handler+0x64>
      exit(-1);
    800034ae:	557d                	li	a0,-1
    800034b0:	fffff097          	auipc	ra,0xfffff
    800034b4:	700080e7          	jalr	1792(ra) # 80002bb0 <exit>
    800034b8:	b7c1                	j	80003478 <trap_user_handler+0x9e>
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    800034ba:	4090                	lw	a2,0(s1)
    800034bc:	85d2                	mv	a1,s4
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	1f250513          	add	a0,a0,498 # 800086b0 <digits+0x4c0>
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	d64080e7          	jalr	-668(ra) # 8000122a <printf>
    printf("            sepc=%p stval=%p\n", sepc, stval);
    800034ce:	8656                	mv	a2,s5
    800034d0:	85ce                	mv	a1,s3
    800034d2:	00005517          	auipc	a0,0x5
    800034d6:	20e50513          	add	a0,a0,526 # 800086e0 <digits+0x4f0>
    800034da:	ffffe097          	auipc	ra,0xffffe
    800034de:	d50080e7          	jalr	-688(ra) # 8000122a <printf>
    panic("usertrap");
    800034e2:	00005517          	auipc	a0,0x5
    800034e6:	21e50513          	add	a0,a0,542 # 80008700 <digits+0x510>
    800034ea:	ffffe097          	auipc	ra,0xffffe
    800034ee:	cf6080e7          	jalr	-778(ra) # 800011e0 <panic>
    yield();  // 让出 CPU，调度其他进程
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	e0c080e7          	jalr	-500(ra) # 800032fe <yield>
    800034fa:	b7a9                	j	80003444 <trap_user_handler+0x6a>

00000000800034fc <arg_raw>:
    第二种使用uvm_copyin 和 uvm_copyinstr 进行传递
*/

// 读取 n 号参数,它放在 an 寄存器中
static uint64 arg_raw(int n)
{   
    800034fc:	1101                	add	sp,sp,-32
    800034fe:	ec06                	sd	ra,24(sp)
    80003500:	e822                	sd	s0,16(sp)
    80003502:	e426                	sd	s1,8(sp)
    80003504:	1000                	add	s0,sp,32
    80003506:	84aa                	mv	s1,a0
    proc_t* proc = myproc();
    80003508:	fffff097          	auipc	ra,0xfffff
    8000350c:	c06080e7          	jalr	-1018(ra) # 8000210e <myproc>
    switch(n) {
    80003510:	4795                	li	a5,5
    80003512:	0497e163          	bltu	a5,s1,80003554 <arg_raw+0x58>
    80003516:	048a                	sll	s1,s1,0x2
    80003518:	00005717          	auipc	a4,0x5
    8000351c:	23870713          	add	a4,a4,568 # 80008750 <digits+0x560>
    80003520:	94ba                	add	s1,s1,a4
    80003522:	409c                	lw	a5,0(s1)
    80003524:	97ba                	add	a5,a5,a4
    80003526:	8782                	jr	a5
        case 0:
            return proc->tf->a0;
    80003528:	6d3c                	ld	a5,88(a0)
    8000352a:	7ba8                	ld	a0,112(a5)
            return proc->tf->a5;
        default:
            panic("arg_raw: illegal arg num");
            return -1;
    }
}
    8000352c:	60e2                	ld	ra,24(sp)
    8000352e:	6442                	ld	s0,16(sp)
    80003530:	64a2                	ld	s1,8(sp)
    80003532:	6105                	add	sp,sp,32
    80003534:	8082                	ret
            return proc->tf->a1;
    80003536:	6d3c                	ld	a5,88(a0)
    80003538:	7fa8                	ld	a0,120(a5)
    8000353a:	bfcd                	j	8000352c <arg_raw+0x30>
            return proc->tf->a2;
    8000353c:	6d3c                	ld	a5,88(a0)
    8000353e:	63c8                	ld	a0,128(a5)
    80003540:	b7f5                	j	8000352c <arg_raw+0x30>
            return proc->tf->a3;
    80003542:	6d3c                	ld	a5,88(a0)
    80003544:	67c8                	ld	a0,136(a5)
    80003546:	b7dd                	j	8000352c <arg_raw+0x30>
            return proc->tf->a4;
    80003548:	6d3c                	ld	a5,88(a0)
    8000354a:	6bc8                	ld	a0,144(a5)
    8000354c:	b7c5                	j	8000352c <arg_raw+0x30>
            return proc->tf->a5;
    8000354e:	6d3c                	ld	a5,88(a0)
    80003550:	6fc8                	ld	a0,152(a5)
    80003552:	bfe9                	j	8000352c <arg_raw+0x30>
            panic("arg_raw: illegal arg num");
    80003554:	00005517          	auipc	a0,0x5
    80003558:	1bc50513          	add	a0,a0,444 # 80008710 <digits+0x520>
    8000355c:	ffffe097          	auipc	ra,0xffffe
    80003560:	c84080e7          	jalr	-892(ra) # 800011e0 <panic>

0000000080003564 <syscall>:
{
    80003564:	1101                	add	sp,sp,-32
    80003566:	ec06                	sd	ra,24(sp)
    80003568:	e822                	sd	s0,16(sp)
    8000356a:	e426                	sd	s1,8(sp)
    8000356c:	e04a                	sd	s2,0(sp)
    8000356e:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    80003570:	fffff097          	auipc	ra,0xfffff
    80003574:	b9e080e7          	jalr	-1122(ra) # 8000210e <myproc>
    80003578:	84aa                	mv	s1,a0
    num = p->tf->a7;
    8000357a:	05853903          	ld	s2,88(a0)
    8000357e:	0a892603          	lw	a2,168(s2)
    if(num >= 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003582:	47fd                	li	a5,31
    80003584:	00c7ef63          	bltu	a5,a2,800035a2 <syscall+0x3e>
    80003588:	00361713          	sll	a4,a2,0x3
    8000358c:	00005797          	auipc	a5,0x5
    80003590:	1dc78793          	add	a5,a5,476 # 80008768 <syscalls>
    80003594:	97ba                	add	a5,a5,a4
    80003596:	639c                	ld	a5,0(a5)
    80003598:	c789                	beqz	a5,800035a2 <syscall+0x3e>
        p->tf->a0 = syscalls[num]();
    8000359a:	9782                	jalr	a5
    8000359c:	06a93823          	sd	a0,112(s2)
    800035a0:	a829                	j	800035ba <syscall+0x56>
        printf("pid %d: unknown sys call %d\n",
    800035a2:	408c                	lw	a1,0(s1)
    800035a4:	00005517          	auipc	a0,0x5
    800035a8:	18c50513          	add	a0,a0,396 # 80008730 <digits+0x540>
    800035ac:	ffffe097          	auipc	ra,0xffffe
    800035b0:	c7e080e7          	jalr	-898(ra) # 8000122a <printf>
        p->tf->a0 = -1;
    800035b4:	6cbc                	ld	a5,88(s1)
    800035b6:	577d                	li	a4,-1
    800035b8:	fbb8                	sd	a4,112(a5)
}
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6902                	ld	s2,0(sp)
    800035c2:	6105                	add	sp,sp,32
    800035c4:	8082                	ret

00000000800035c6 <arg_uint32>:

// 读取 n 号参数, 作为 uint32 存储
void arg_uint32(int n, uint32* ip)
{
    800035c6:	1101                	add	sp,sp,-32
    800035c8:	ec06                	sd	ra,24(sp)
    800035ca:	e822                	sd	s0,16(sp)
    800035cc:	e426                	sd	s1,8(sp)
    800035ce:	1000                	add	s0,sp,32
    800035d0:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	f2a080e7          	jalr	-214(ra) # 800034fc <arg_raw>
    800035da:	c088                	sw	a0,0(s1)
}
    800035dc:	60e2                	ld	ra,24(sp)
    800035de:	6442                	ld	s0,16(sp)
    800035e0:	64a2                	ld	s1,8(sp)
    800035e2:	6105                	add	sp,sp,32
    800035e4:	8082                	ret

00000000800035e6 <arg_uint64>:

// 读取 n 号参数, 作为 uint64 存储
void arg_uint64(int n, uint64* ip)
{
    800035e6:	1101                	add	sp,sp,-32
    800035e8:	ec06                	sd	ra,24(sp)
    800035ea:	e822                	sd	s0,16(sp)
    800035ec:	e426                	sd	s1,8(sp)
    800035ee:	1000                	add	s0,sp,32
    800035f0:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	f0a080e7          	jalr	-246(ra) # 800034fc <arg_raw>
    800035fa:	e088                	sd	a0,0(s1)
}
    800035fc:	60e2                	ld	ra,24(sp)
    800035fe:	6442                	ld	s0,16(sp)
    80003600:	64a2                	ld	s1,8(sp)
    80003602:	6105                	add	sp,sp,32
    80003604:	8082                	ret

0000000080003606 <arg_str>:

// 读取 n 号参数指向的字符串到 buf, 字符串最大长度是 maxlen
void arg_str(int n, char* buf, int maxlen)
{
    80003606:	7139                	add	sp,sp,-64
    80003608:	fc06                	sd	ra,56(sp)
    8000360a:	f822                	sd	s0,48(sp)
    8000360c:	f426                	sd	s1,40(sp)
    8000360e:	f04a                	sd	s2,32(sp)
    80003610:	ec4e                	sd	s3,24(sp)
    80003612:	e852                	sd	s4,16(sp)
    80003614:	0080                	add	s0,sp,64
    80003616:	8a2a                	mv	s4,a0
    80003618:	892e                	mv	s2,a1
    8000361a:	89b2                	mv	s3,a2
    proc_t* p = myproc();
    8000361c:	fffff097          	auipc	ra,0xfffff
    80003620:	af2080e7          	jalr	-1294(ra) # 8000210e <myproc>
    80003624:	84aa                	mv	s1,a0
    uint64 addr;
    arg_uint64(n, &addr);
    80003626:	fc840593          	add	a1,s0,-56
    8000362a:	8552                	mv	a0,s4
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	fba080e7          	jalr	-70(ra) # 800035e6 <arg_uint64>

    uvm_copyin_str(p->pgtbl, (uint64)buf, addr, maxlen);
    80003634:	86ce                	mv	a3,s3
    80003636:	fc843603          	ld	a2,-56(s0)
    8000363a:	85ca                	mv	a1,s2
    8000363c:	64a8                	ld	a0,72(s1)
    8000363e:	ffffe097          	auipc	ra,0xffffe
    80003642:	7dc080e7          	jalr	2012(ra) # 80001e1a <uvm_copyin_str>
}
    80003646:	70e2                	ld	ra,56(sp)
    80003648:	7442                	ld	s0,48(sp)
    8000364a:	74a2                	ld	s1,40(sp)
    8000364c:	7902                	ld	s2,32(sp)
    8000364e:	69e2                	ld	s3,24(sp)
    80003650:	6a42                	ld	s4,16(sp)
    80003652:	6121                	add	sp,sp,64
    80003654:	8082                	ret

0000000080003656 <fetchstr>:

int
fetchstr(uint64 addr, char *buf, int max)
{
    80003656:	7179                	add	sp,sp,-48
    80003658:	f406                	sd	ra,40(sp)
    8000365a:	f022                	sd	s0,32(sp)
    8000365c:	ec26                	sd	s1,24(sp)
    8000365e:	e84a                	sd	s2,16(sp)
    80003660:	e44e                	sd	s3,8(sp)
    80003662:	1800                	add	s0,sp,48
    80003664:	892a                	mv	s2,a0
    80003666:	84ae                	mv	s1,a1
    80003668:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000366a:	fffff097          	auipc	ra,0xfffff
    8000366e:	aa4080e7          	jalr	-1372(ra) # 8000210e <myproc>
  if(uvm_copyin_str(p->pgtbl, (uint64) buf, addr, max) < 0)
    80003672:	86ce                	mv	a3,s3
    80003674:	864a                	mv	a2,s2
    80003676:	85a6                	mv	a1,s1
    80003678:	6528                	ld	a0,72(a0)
    8000367a:	ffffe097          	auipc	ra,0xffffe
    8000367e:	7a0080e7          	jalr	1952(ra) # 80001e1a <uvm_copyin_str>
    80003682:	00054e63          	bltz	a0,8000369e <fetchstr+0x48>
    return -1;
  return strlen(buf);
    80003686:	8526                	mv	a0,s1
    80003688:	ffffe097          	auipc	ra,0xffffe
    8000368c:	a8a080e7          	jalr	-1398(ra) # 80001112 <strlen>
}
    80003690:	70a2                	ld	ra,40(sp)
    80003692:	7402                	ld	s0,32(sp)
    80003694:	64e2                	ld	s1,24(sp)
    80003696:	6942                	ld	s2,16(sp)
    80003698:	69a2                	ld	s3,8(sp)
    8000369a:	6145                	add	sp,sp,48
    8000369c:	8082                	ret
    return -1;
    8000369e:	557d                	li	a0,-1
    800036a0:	bfc5                	j	80003690 <fetchstr+0x3a>

00000000800036a2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800036a2:	7179                	add	sp,sp,-48
    800036a4:	f406                	sd	ra,40(sp)
    800036a6:	f022                	sd	s0,32(sp)
    800036a8:	ec26                	sd	s1,24(sp)
    800036aa:	e84a                	sd	s2,16(sp)
    800036ac:	1800                	add	s0,sp,48
    800036ae:	84ae                	mv	s1,a1
    800036b0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800036b2:	fd840593          	add	a1,s0,-40
    800036b6:	00000097          	auipc	ra,0x0
    800036ba:	f30080e7          	jalr	-208(ra) # 800035e6 <arg_uint64>
  return fetchstr(addr, buf, max);
    800036be:	864a                	mv	a2,s2
    800036c0:	85a6                	mv	a1,s1
    800036c2:	fd843503          	ld	a0,-40(s0)
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	f90080e7          	jalr	-112(ra) # 80003656 <fetchstr>
}
    800036ce:	70a2                	ld	ra,40(sp)
    800036d0:	7402                	ld	s0,32(sp)
    800036d2:	64e2                	ld	s1,24(sp)
    800036d4:	6942                	ld	s2,16(sp)
    800036d6:	6145                	add	sp,sp,48
    800036d8:	8082                	ret

00000000800036da <sys_brk>:

// 堆伸缩
// uint64 new_heap_top 新的堆顶 (如果是0代表查询, 返回旧的堆顶)
// 成功返回新的堆顶 失败返回-1
uint64 sys_brk()
{
    800036da:	7179                	add	sp,sp,-48
    800036dc:	f406                	sd	ra,40(sp)
    800036de:	f022                	sd	s0,32(sp)
    800036e0:	ec26                	sd	s1,24(sp)
    800036e2:	1800                	add	s0,sp,48
    uint64 new_addr;
    uint64 old_addr = myproc()->sz;  // 保存原始堆顶
    800036e4:	fffff097          	auipc	ra,0xfffff
    800036e8:	a2a080e7          	jalr	-1494(ra) # 8000210e <myproc>
    800036ec:	7564                	ld	s1,232(a0)

    arg_uint64(0, &new_addr);  // 正确读取64位地址
    800036ee:	fd840593          	add	a1,s0,-40
    800036f2:	4501                	li	a0,0
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	ef2080e7          	jalr	-270(ra) # 800035e6 <arg_uint64>
    
    if(new_addr == old_addr || new_addr == 0) {
    800036fc:	fd843783          	ld	a5,-40(s0)
    80003700:	00978963          	beq	a5,s1,80003712 <sys_brk+0x38>
    80003704:	c799                	beqz	a5,80003712 <sys_brk+0x38>
        return old_addr;  // 无变化，返回当前堆顶
    }
    
    int diff = (int)(new_addr - old_addr);
    80003706:	4097853b          	subw	a0,a5,s1
    
    // 检查是否溢出
    if((uint64)diff != (new_addr - old_addr)) {
    8000370a:	8f85                	sub	a5,a5,s1
        return -1;  // 差值太大，int无法表示
    8000370c:	54fd                	li	s1,-1
    if((uint64)diff != (new_addr - old_addr)) {
    8000370e:	00f50863          	beq	a0,a5,8000371e <sys_brk+0x44>
    if(growproc(diff) < 0) {
        return -1;  // 扩展失败
    }
    
    return new_addr;  // 返回扩展前的地址
}
    80003712:	8526                	mv	a0,s1
    80003714:	70a2                	ld	ra,40(sp)
    80003716:	7402                	ld	s0,32(sp)
    80003718:	64e2                	ld	s1,24(sp)
    8000371a:	6145                	add	sp,sp,48
    8000371c:	8082                	ret
    if(growproc(diff) < 0) {
    8000371e:	fffff097          	auipc	ra,0xfffff
    80003722:	eb8080e7          	jalr	-328(ra) # 800025d6 <growproc>
    80003726:	00054563          	bltz	a0,80003730 <sys_brk+0x56>
    return new_addr;  // 返回扩展前的地址
    8000372a:	fd843483          	ld	s1,-40(s0)
    8000372e:	b7d5                	j	80003712 <sys_brk+0x38>
        return -1;  // 扩展失败
    80003730:	54fd                	li	s1,-1
    80003732:	b7c5                	j	80003712 <sys_brk+0x38>

0000000080003734 <sys_kill>:

uint64
sys_kill(void)
{
    80003734:	1101                	add	sp,sp,-32
    80003736:	ec06                	sd	ra,24(sp)
    80003738:	e822                	sd	s0,16(sp)
    8000373a:	1000                	add	s0,sp,32
  uint64 pid;

  arg_uint64(0, &pid);
    8000373c:	fe840593          	add	a1,s0,-24
    80003740:	4501                	li	a0,0
    80003742:	00000097          	auipc	ra,0x0
    80003746:	ea4080e7          	jalr	-348(ra) # 800035e6 <arg_uint64>
  return kill(pid);
    8000374a:	fe842503          	lw	a0,-24(s0)
    8000374e:	fffff097          	auipc	ra,0xfffff
    80003752:	1da080e7          	jalr	474(ra) # 80002928 <kill>
}
    80003756:	60e2                	ld	ra,24(sp)
    80003758:	6442                	ld	s0,16(sp)
    8000375a:	6105                	add	sp,sp,32
    8000375c:	8082                	ret

000000008000375e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000375e:	1141                	add	sp,sp,-16
    80003760:	e406                	sd	ra,8(sp)
    80003762:	e022                	sd	s0,0(sp)
    80003764:	0800                	add	s0,sp,16
  return myproc()->pid;
    80003766:	fffff097          	auipc	ra,0xfffff
    8000376a:	9a8080e7          	jalr	-1624(ra) # 8000210e <myproc>
}
    8000376e:	4108                	lw	a0,0(a0)
    80003770:	60a2                	ld	ra,8(sp)
    80003772:	6402                	ld	s0,0(sp)
    80003774:	0141                	add	sp,sp,16
    80003776:	8082                	ret

0000000080003778 <sys_print>:
// 打印字符
// uint64 addr
uint64 sys_print()
{
    80003778:	7175                	add	sp,sp,-144
    8000377a:	e506                	sd	ra,136(sp)
    8000377c:	e122                	sd	s0,128(sp)
    8000377e:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    80003780:	08000613          	li	a2,128
    80003784:	f7040593          	add	a1,s0,-144
    80003788:	4501                	li	a0,0
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	e7c080e7          	jalr	-388(ra) # 80003606 <arg_str>

    printf("%s", buf);
    80003792:	f7040593          	add	a1,s0,-144
    80003796:	00005517          	auipc	a0,0x5
    8000379a:	0d250513          	add	a0,a0,210 # 80008868 <syscalls+0x100>
    8000379e:	ffffe097          	auipc	ra,0xffffe
    800037a2:	a8c080e7          	jalr	-1396(ra) # 8000122a <printf>
    return 0;
}
    800037a6:	4501                	li	a0,0
    800037a8:	60aa                	ld	ra,136(sp)
    800037aa:	640a                	ld	s0,128(sp)
    800037ac:	6149                	add	sp,sp,144
    800037ae:	8082                	ret

00000000800037b0 <sys_fork>:

// 进程复制
uint64 sys_fork()
{
    800037b0:	1141                	add	sp,sp,-16
    800037b2:	e406                	sd	ra,8(sp)
    800037b4:	e022                	sd	s0,0(sp)
    800037b6:	0800                	add	s0,sp,16
    return fork();
    800037b8:	fffff097          	auipc	ra,0xfffff
    800037bc:	f50080e7          	jalr	-176(ra) # 80002708 <fork>
}
    800037c0:	60a2                	ld	ra,8(sp)
    800037c2:	6402                	ld	s0,0(sp)
    800037c4:	0141                	add	sp,sp,16
    800037c6:	8082                	ret

00000000800037c8 <sys_wait>:

// 进程等待
// uint64 addr  子进程退出时的exit_state需要放到这里 
uint64 sys_wait()
{
    800037c8:	1101                	add	sp,sp,-32
    800037ca:	ec06                	sd	ra,24(sp)
    800037cc:	e822                	sd	s0,16(sp)
    800037ce:	1000                	add	s0,sp,32
    uint64 p;
    arg_uint64(0, &p);
    800037d0:	fe840593          	add	a1,s0,-24
    800037d4:	4501                	li	a0,0
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	e10080e7          	jalr	-496(ra) # 800035e6 <arg_uint64>
    return wait(p);
    800037de:	fe843503          	ld	a0,-24(s0)
    800037e2:	fffff097          	auipc	ra,0xfffff
    800037e6:	22c080e7          	jalr	556(ra) # 80002a0e <wait>
}
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	6105                	add	sp,sp,32
    800037f0:	8082                	ret

00000000800037f2 <sys_exit>:

// 进程退出
// int exit_state
uint64 sys_exit()
{
    800037f2:	1101                	add	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	1000                	add	s0,sp,32
    uint64 n;
    arg_uint64(0, &n);
    800037fa:	fe840593          	add	a1,s0,-24
    800037fe:	4501                	li	a0,0
    80003800:	00000097          	auipc	ra,0x0
    80003804:	de6080e7          	jalr	-538(ra) # 800035e6 <arg_uint64>
    exit(n);
    80003808:	fe842503          	lw	a0,-24(s0)
    8000380c:	fffff097          	auipc	ra,0xfffff
    80003810:	3a4080e7          	jalr	932(ra) # 80002bb0 <exit>
    return 0;  // not reached
}
    80003814:	4501                	li	a0,0
    80003816:	60e2                	ld	ra,24(sp)
    80003818:	6442                	ld	s0,16(sp)
    8000381a:	6105                	add	sp,sp,32
    8000381c:	8082                	ret

000000008000381e <sys_sleep>:

// 进程睡眠一段时间
// uint32 second 睡眠时间
// 成功返回0, 失败返回-1
uint64 sys_sleep()
{
    8000381e:	7139                	add	sp,sp,-64
    80003820:	fc06                	sd	ra,56(sp)
    80003822:	f822                	sd	s0,48(sp)
    80003824:	f426                	sd	s1,40(sp)
    80003826:	f04a                	sd	s2,32(sp)
    80003828:	ec4e                	sd	s3,24(sp)
    8000382a:	0080                	add	s0,sp,64
    uint64 n;
    uint ticks0;

    arg_uint64(0, &n);
    8000382c:	fc840593          	add	a1,s0,-56
    80003830:	4501                	li	a0,0
    80003832:	00000097          	auipc	ra,0x0
    80003836:	db4080e7          	jalr	-588(ra) # 800035e6 <arg_uint64>
    acquire(& sys_timer.lk);
    8000383a:	0000d517          	auipc	a0,0xd
    8000383e:	7de50513          	add	a0,a0,2014 # 80011018 <sys_timer+0x8>
    80003842:	fffff097          	auipc	ra,0xfffff
    80003846:	6ac080e7          	jalr	1708(ra) # 80002eee <acquire>
    ticks0 = sys_timer.ticks;
    8000384a:	0000d797          	auipc	a5,0xd
    8000384e:	7c67b783          	ld	a5,1990(a5) # 80011010 <sys_timer>
    while(sys_timer.ticks - ticks0 < n){
    80003852:	02079913          	sll	s2,a5,0x20
    80003856:	02095913          	srl	s2,s2,0x20
    8000385a:	412787b3          	sub	a5,a5,s2
    8000385e:	fc843703          	ld	a4,-56(s0)
    80003862:	04e7f063          	bgeu	a5,a4,800038a2 <sys_sleep+0x84>
        if(killed(myproc())){
        release(&sys_timer.lk);
        return -1;
        }
        sleep(&sys_timer.ticks, &sys_timer.lk);
    80003866:	0000d997          	auipc	s3,0xd
    8000386a:	7b298993          	add	s3,s3,1970 # 80011018 <sys_timer+0x8>
    8000386e:	0000d497          	auipc	s1,0xd
    80003872:	7a248493          	add	s1,s1,1954 # 80011010 <sys_timer>
        if(killed(myproc())){
    80003876:	fffff097          	auipc	ra,0xfffff
    8000387a:	898080e7          	jalr	-1896(ra) # 8000210e <myproc>
    8000387e:	fffff097          	auipc	ra,0xfffff
    80003882:	15a080e7          	jalr	346(ra) # 800029d8 <killed>
    80003886:	ed15                	bnez	a0,800038c2 <sys_sleep+0xa4>
        sleep(&sys_timer.ticks, &sys_timer.lk);
    80003888:	85ce                	mv	a1,s3
    8000388a:	8526                	mv	a0,s1
    8000388c:	fffff097          	auipc	ra,0xfffff
    80003890:	fb0080e7          	jalr	-80(ra) # 8000283c <sleep>
    while(sys_timer.ticks - ticks0 < n){
    80003894:	609c                	ld	a5,0(s1)
    80003896:	412787b3          	sub	a5,a5,s2
    8000389a:	fc843703          	ld	a4,-56(s0)
    8000389e:	fce7ece3          	bltu	a5,a4,80003876 <sys_sleep+0x58>
    }
    release(& sys_timer.lk);
    800038a2:	0000d517          	auipc	a0,0xd
    800038a6:	77650513          	add	a0,a0,1910 # 80011018 <sys_timer+0x8>
    800038aa:	fffff097          	auipc	ra,0xfffff
    800038ae:	6f8080e7          	jalr	1784(ra) # 80002fa2 <release>
    return 0;
    800038b2:	4501                	li	a0,0
}
    800038b4:	70e2                	ld	ra,56(sp)
    800038b6:	7442                	ld	s0,48(sp)
    800038b8:	74a2                	ld	s1,40(sp)
    800038ba:	7902                	ld	s2,32(sp)
    800038bc:	69e2                	ld	s3,24(sp)
    800038be:	6121                	add	sp,sp,64
    800038c0:	8082                	ret
        release(&sys_timer.lk);
    800038c2:	0000d517          	auipc	a0,0xd
    800038c6:	75650513          	add	a0,a0,1878 # 80011018 <sys_timer+0x8>
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	6d8080e7          	jalr	1752(ra) # 80002fa2 <release>
        return -1;
    800038d2:	557d                	li	a0,-1
    800038d4:	b7c5                	j	800038b4 <sys_sleep+0x96>

00000000800038d6 <sys_debug>:


uint64 sys_debug(void)
{
    800038d6:	7175                	add	sp,sp,-144
    800038d8:	e506                	sd	ra,136(sp)
    800038da:	e122                	sd	s0,128(sp)
    800038dc:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    800038de:	08000613          	li	a2,128
    800038e2:	f7040593          	add	a1,s0,-144
    800038e6:	4501                	li	a0,0
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	d1e080e7          	jalr	-738(ra) # 80003606 <arg_str>

    printf("[debug] %s \n", buf);
    800038f0:	f7040593          	add	a1,s0,-144
    800038f4:	00005517          	auipc	a0,0x5
    800038f8:	f7c50513          	add	a0,a0,-132 # 80008870 <syscalls+0x108>
    800038fc:	ffffe097          	auipc	ra,0xffffe
    80003900:	92e080e7          	jalr	-1746(ra) # 8000122a <printf>
    return 0;
}
    80003904:	4501                	li	a0,0
    80003906:	60aa                	ld	ra,136(sp)
    80003908:	640a                	ld	s0,128(sp)
    8000390a:	6149                	add	sp,sp,144
    8000390c:	8082                	ret

000000008000390e <argfd>:
#include "buf.h"
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000390e:	7179                	add	sp,sp,-48
    80003910:	f406                	sd	ra,40(sp)
    80003912:	f022                	sd	s0,32(sp)
    80003914:	ec26                	sd	s1,24(sp)
    80003916:	e84a                	sd	s2,16(sp)
    80003918:	1800                	add	s0,sp,48
    8000391a:	892e                	mv	s2,a1
    8000391c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000391e:	fdc40593          	add	a1,s0,-36
    80003922:	00000097          	auipc	ra,0x0
    80003926:	cc4080e7          	jalr	-828(ra) # 800035e6 <arg_uint64>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000392a:	fdc42703          	lw	a4,-36(s0)
    8000392e:	47bd                	li	a5,15
    80003930:	02e7eb63          	bltu	a5,a4,80003966 <argfd+0x58>
    80003934:	ffffe097          	auipc	ra,0xffffe
    80003938:	7da080e7          	jalr	2010(ra) # 8000210e <myproc>
    8000393c:	fdc42703          	lw	a4,-36(s0)
    80003940:	00c70793          	add	a5,a4,12
    80003944:	078e                	sll	a5,a5,0x3
    80003946:	953e                	add	a0,a0,a5
    80003948:	611c                	ld	a5,0(a0)
    8000394a:	c385                	beqz	a5,8000396a <argfd+0x5c>
    return -1;
  if(pfd)
    8000394c:	00090463          	beqz	s2,80003954 <argfd+0x46>
    *pfd = fd;
    80003950:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80003954:	4501                	li	a0,0
  if(pf)
    80003956:	c091                	beqz	s1,8000395a <argfd+0x4c>
    *pf = f;
    80003958:	e09c                	sd	a5,0(s1)
}
    8000395a:	70a2                	ld	ra,40(sp)
    8000395c:	7402                	ld	s0,32(sp)
    8000395e:	64e2                	ld	s1,24(sp)
    80003960:	6942                	ld	s2,16(sp)
    80003962:	6145                	add	sp,sp,48
    80003964:	8082                	ret
    return -1;
    80003966:	557d                	li	a0,-1
    80003968:	bfcd                	j	8000395a <argfd+0x4c>
    8000396a:	557d                	li	a0,-1
    8000396c:	b7fd                	j	8000395a <argfd+0x4c>

000000008000396e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000396e:	1101                	add	sp,sp,-32
    80003970:	ec06                	sd	ra,24(sp)
    80003972:	e822                	sd	s0,16(sp)
    80003974:	e426                	sd	s1,8(sp)
    80003976:	1000                	add	s0,sp,32
    80003978:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000397a:	ffffe097          	auipc	ra,0xffffe
    8000397e:	794080e7          	jalr	1940(ra) # 8000210e <myproc>
    80003982:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80003984:	06050793          	add	a5,a0,96
    80003988:	4501                	li	a0,0
    8000398a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000398c:	6398                	ld	a4,0(a5)
    8000398e:	cb19                	beqz	a4,800039a4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80003990:	2505                	addw	a0,a0,1
    80003992:	07a1                	add	a5,a5,8
    80003994:	fed51ce3          	bne	a0,a3,8000398c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80003998:	557d                	li	a0,-1
}
    8000399a:	60e2                	ld	ra,24(sp)
    8000399c:	6442                	ld	s0,16(sp)
    8000399e:	64a2                	ld	s1,8(sp)
    800039a0:	6105                	add	sp,sp,32
    800039a2:	8082                	ret
      p->ofile[fd] = f;
    800039a4:	00c50793          	add	a5,a0,12
    800039a8:	078e                	sll	a5,a5,0x3
    800039aa:	963e                	add	a2,a2,a5
    800039ac:	e204                	sd	s1,0(a2)
      return fd;
    800039ae:	b7f5                	j	8000399a <fdalloc+0x2c>

00000000800039b0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800039b0:	715d                	add	sp,sp,-80
    800039b2:	e486                	sd	ra,72(sp)
    800039b4:	e0a2                	sd	s0,64(sp)
    800039b6:	fc26                	sd	s1,56(sp)
    800039b8:	f84a                	sd	s2,48(sp)
    800039ba:	f44e                	sd	s3,40(sp)
    800039bc:	f052                	sd	s4,32(sp)
    800039be:	ec56                	sd	s5,24(sp)
    800039c0:	e85a                	sd	s6,16(sp)
    800039c2:	0880                	add	s0,sp,80
    800039c4:	8b2e                	mv	s6,a1
    800039c6:	89b2                	mv	s3,a2
    800039c8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800039ca:	fb040593          	add	a1,s0,-80
    800039ce:	00002097          	auipc	ra,0x2
    800039d2:	79a080e7          	jalr	1946(ra) # 80006168 <nameiparent>
    800039d6:	84aa                	mv	s1,a0
    800039d8:	14050b63          	beqz	a0,80003b2e <create+0x17e>
    return 0;

  ilock(dp);
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	0b0080e7          	jalr	176(ra) # 80004a8c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800039e4:	4601                	li	a2,0
    800039e6:	fb040593          	add	a1,s0,-80
    800039ea:	8526                	mv	a0,s1
    800039ec:	00002097          	auipc	ra,0x2
    800039f0:	49e080e7          	jalr	1182(ra) # 80005e8a <dirlookup>
    800039f4:	8aaa                	mv	s5,a0
    800039f6:	c921                	beqz	a0,80003a46 <create+0x96>
    iunlockput(dp);
    800039f8:	8526                	mv	a0,s1
    800039fa:	00001097          	auipc	ra,0x1
    800039fe:	2f4080e7          	jalr	756(ra) # 80004cee <iunlockput>
    ilock(ip);
    80003a02:	8556                	mv	a0,s5
    80003a04:	00001097          	auipc	ra,0x1
    80003a08:	088080e7          	jalr	136(ra) # 80004a8c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80003a0c:	4789                	li	a5,2
    80003a0e:	02fb1563          	bne	s6,a5,80003a38 <create+0x88>
    80003a12:	044ad783          	lhu	a5,68(s5)
    80003a16:	37f9                	addw	a5,a5,-2
    80003a18:	17c2                	sll	a5,a5,0x30
    80003a1a:	93c1                	srl	a5,a5,0x30
    80003a1c:	4705                	li	a4,1
    80003a1e:	00f76d63          	bltu	a4,a5,80003a38 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80003a22:	8556                	mv	a0,s5
    80003a24:	60a6                	ld	ra,72(sp)
    80003a26:	6406                	ld	s0,64(sp)
    80003a28:	74e2                	ld	s1,56(sp)
    80003a2a:	7942                	ld	s2,48(sp)
    80003a2c:	79a2                	ld	s3,40(sp)
    80003a2e:	7a02                	ld	s4,32(sp)
    80003a30:	6ae2                	ld	s5,24(sp)
    80003a32:	6b42                	ld	s6,16(sp)
    80003a34:	6161                	add	sp,sp,80
    80003a36:	8082                	ret
    iunlockput(ip);
    80003a38:	8556                	mv	a0,s5
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	2b4080e7          	jalr	692(ra) # 80004cee <iunlockput>
    return 0;
    80003a42:	4a81                	li	s5,0
    80003a44:	bff9                	j	80003a22 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80003a46:	85da                	mv	a1,s6
    80003a48:	4088                	lw	a0,0(s1)
    80003a4a:	00001097          	auipc	ra,0x1
    80003a4e:	eaa080e7          	jalr	-342(ra) # 800048f4 <ialloc>
    80003a52:	8a2a                	mv	s4,a0
    80003a54:	c529                	beqz	a0,80003a9e <create+0xee>
  ilock(ip);
    80003a56:	00001097          	auipc	ra,0x1
    80003a5a:	036080e7          	jalr	54(ra) # 80004a8c <ilock>
  ip->major = major;
    80003a5e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80003a62:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80003a66:	4905                	li	s2,1
    80003a68:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80003a6c:	8552                	mv	a0,s4
    80003a6e:	00001097          	auipc	ra,0x1
    80003a72:	f52080e7          	jalr	-174(ra) # 800049c0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80003a76:	032b0b63          	beq	s6,s2,80003aac <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80003a7a:	004a2603          	lw	a2,4(s4)
    80003a7e:	fb040593          	add	a1,s0,-80
    80003a82:	8526                	mv	a0,s1
    80003a84:	00002097          	auipc	ra,0x2
    80003a88:	614080e7          	jalr	1556(ra) # 80006098 <dirlink>
    80003a8c:	06054f63          	bltz	a0,80003b0a <create+0x15a>
  iunlockput(dp);
    80003a90:	8526                	mv	a0,s1
    80003a92:	00001097          	auipc	ra,0x1
    80003a96:	25c080e7          	jalr	604(ra) # 80004cee <iunlockput>
  return ip;
    80003a9a:	8ad2                	mv	s5,s4
    80003a9c:	b759                	j	80003a22 <create+0x72>
    iunlockput(dp);
    80003a9e:	8526                	mv	a0,s1
    80003aa0:	00001097          	auipc	ra,0x1
    80003aa4:	24e080e7          	jalr	590(ra) # 80004cee <iunlockput>
    return 0;
    80003aa8:	8ad2                	mv	s5,s4
    80003aaa:	bfa5                	j	80003a22 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80003aac:	004a2603          	lw	a2,4(s4)
    80003ab0:	00005597          	auipc	a1,0x5
    80003ab4:	dd058593          	add	a1,a1,-560 # 80008880 <syscalls+0x118>
    80003ab8:	8552                	mv	a0,s4
    80003aba:	00002097          	auipc	ra,0x2
    80003abe:	5de080e7          	jalr	1502(ra) # 80006098 <dirlink>
    80003ac2:	04054463          	bltz	a0,80003b0a <create+0x15a>
    80003ac6:	40d0                	lw	a2,4(s1)
    80003ac8:	00005597          	auipc	a1,0x5
    80003acc:	dc058593          	add	a1,a1,-576 # 80008888 <syscalls+0x120>
    80003ad0:	8552                	mv	a0,s4
    80003ad2:	00002097          	auipc	ra,0x2
    80003ad6:	5c6080e7          	jalr	1478(ra) # 80006098 <dirlink>
    80003ada:	02054863          	bltz	a0,80003b0a <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80003ade:	004a2603          	lw	a2,4(s4)
    80003ae2:	fb040593          	add	a1,s0,-80
    80003ae6:	8526                	mv	a0,s1
    80003ae8:	00002097          	auipc	ra,0x2
    80003aec:	5b0080e7          	jalr	1456(ra) # 80006098 <dirlink>
    80003af0:	00054d63          	bltz	a0,80003b0a <create+0x15a>
    dp->nlink++;  // for ".."
    80003af4:	04a4d783          	lhu	a5,74(s1)
    80003af8:	2785                	addw	a5,a5,1
    80003afa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80003afe:	8526                	mv	a0,s1
    80003b00:	00001097          	auipc	ra,0x1
    80003b04:	ec0080e7          	jalr	-320(ra) # 800049c0 <iupdate>
    80003b08:	b761                	j	80003a90 <create+0xe0>
  ip->nlink = 0;
    80003b0a:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80003b0e:	8552                	mv	a0,s4
    80003b10:	00001097          	auipc	ra,0x1
    80003b14:	eb0080e7          	jalr	-336(ra) # 800049c0 <iupdate>
  iunlockput(ip);
    80003b18:	8552                	mv	a0,s4
    80003b1a:	00001097          	auipc	ra,0x1
    80003b1e:	1d4080e7          	jalr	468(ra) # 80004cee <iunlockput>
  iunlockput(dp);
    80003b22:	8526                	mv	a0,s1
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	1ca080e7          	jalr	458(ra) # 80004cee <iunlockput>
  return 0;
    80003b2c:	bddd                	j	80003a22 <create+0x72>
    return 0;
    80003b2e:	8aaa                	mv	s5,a0
    80003b30:	bdcd                	j	80003a22 <create+0x72>

0000000080003b32 <sys_dup>:
{
    80003b32:	7179                	add	sp,sp,-48
    80003b34:	f406                	sd	ra,40(sp)
    80003b36:	f022                	sd	s0,32(sp)
    80003b38:	ec26                	sd	s1,24(sp)
    80003b3a:	e84a                	sd	s2,16(sp)
    80003b3c:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80003b3e:	fd840613          	add	a2,s0,-40
    80003b42:	4581                	li	a1,0
    80003b44:	4501                	li	a0,0
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	dc8080e7          	jalr	-568(ra) # 8000390e <argfd>
    return -1;
    80003b4e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80003b50:	02054363          	bltz	a0,80003b76 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80003b54:	fd843903          	ld	s2,-40(s0)
    80003b58:	854a                	mv	a0,s2
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	e14080e7          	jalr	-492(ra) # 8000396e <fdalloc>
    80003b62:	84aa                	mv	s1,a0
    return -1;
    80003b64:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80003b66:	00054863          	bltz	a0,80003b76 <sys_dup+0x44>
  filedup(f);
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	00002097          	auipc	ra,0x2
    80003b70:	efa080e7          	jalr	-262(ra) # 80005a66 <filedup>
  return fd;
    80003b74:	87a6                	mv	a5,s1
}
    80003b76:	853e                	mv	a0,a5
    80003b78:	70a2                	ld	ra,40(sp)
    80003b7a:	7402                	ld	s0,32(sp)
    80003b7c:	64e2                	ld	s1,24(sp)
    80003b7e:	6942                	ld	s2,16(sp)
    80003b80:	6145                	add	sp,sp,48
    80003b82:	8082                	ret

0000000080003b84 <sys_read>:
{
    80003b84:	7179                	add	sp,sp,-48
    80003b86:	f406                	sd	ra,40(sp)
    80003b88:	f022                	sd	s0,32(sp)
    80003b8a:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80003b8c:	fd840593          	add	a1,s0,-40
    80003b90:	4505                	li	a0,1
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	a54080e7          	jalr	-1452(ra) # 800035e6 <arg_uint64>
  argint(2, &n);
    80003b9a:	fe440593          	add	a1,s0,-28
    80003b9e:	4509                	li	a0,2
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	a46080e7          	jalr	-1466(ra) # 800035e6 <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    80003ba8:	fe840613          	add	a2,s0,-24
    80003bac:	4581                	li	a1,0
    80003bae:	4501                	li	a0,0
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	d5e080e7          	jalr	-674(ra) # 8000390e <argfd>
    80003bb8:	87aa                	mv	a5,a0
    return -1;
    80003bba:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80003bbc:	0007cc63          	bltz	a5,80003bd4 <sys_read+0x50>
  return fileread(f, p, n);
    80003bc0:	fe442603          	lw	a2,-28(s0)
    80003bc4:	fd843583          	ld	a1,-40(s0)
    80003bc8:	fe843503          	ld	a0,-24(s0)
    80003bcc:	00002097          	auipc	ra,0x2
    80003bd0:	026080e7          	jalr	38(ra) # 80005bf2 <fileread>
}
    80003bd4:	70a2                	ld	ra,40(sp)
    80003bd6:	7402                	ld	s0,32(sp)
    80003bd8:	6145                	add	sp,sp,48
    80003bda:	8082                	ret

0000000080003bdc <sys_write>:
{
    80003bdc:	7179                	add	sp,sp,-48
    80003bde:	f406                	sd	ra,40(sp)
    80003be0:	f022                	sd	s0,32(sp)
    80003be2:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80003be4:	fd840593          	add	a1,s0,-40
    80003be8:	4505                	li	a0,1
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	9fc080e7          	jalr	-1540(ra) # 800035e6 <arg_uint64>
  argint(2, &n);
    80003bf2:	fe440593          	add	a1,s0,-28
    80003bf6:	4509                	li	a0,2
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	9ee080e7          	jalr	-1554(ra) # 800035e6 <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    80003c00:	fe840613          	add	a2,s0,-24
    80003c04:	4581                	li	a1,0
    80003c06:	4501                	li	a0,0
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	d06080e7          	jalr	-762(ra) # 8000390e <argfd>
    80003c10:	87aa                	mv	a5,a0
    return -1;
    80003c12:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80003c14:	0007cc63          	bltz	a5,80003c2c <sys_write+0x50>
  return filewrite(f, p, n);
    80003c18:	fe442603          	lw	a2,-28(s0)
    80003c1c:	fd843583          	ld	a1,-40(s0)
    80003c20:	fe843503          	ld	a0,-24(s0)
    80003c24:	00002097          	auipc	ra,0x2
    80003c28:	090080e7          	jalr	144(ra) # 80005cb4 <filewrite>
}
    80003c2c:	70a2                	ld	ra,40(sp)
    80003c2e:	7402                	ld	s0,32(sp)
    80003c30:	6145                	add	sp,sp,48
    80003c32:	8082                	ret

0000000080003c34 <sys_close>:
{
    80003c34:	1101                	add	sp,sp,-32
    80003c36:	ec06                	sd	ra,24(sp)
    80003c38:	e822                	sd	s0,16(sp)
    80003c3a:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80003c3c:	fe040613          	add	a2,s0,-32
    80003c40:	fec40593          	add	a1,s0,-20
    80003c44:	4501                	li	a0,0
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	cc8080e7          	jalr	-824(ra) # 8000390e <argfd>
    return -1;
    80003c4e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80003c50:	02054463          	bltz	a0,80003c78 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80003c54:	ffffe097          	auipc	ra,0xffffe
    80003c58:	4ba080e7          	jalr	1210(ra) # 8000210e <myproc>
    80003c5c:	fec42783          	lw	a5,-20(s0)
    80003c60:	07b1                	add	a5,a5,12
    80003c62:	078e                	sll	a5,a5,0x3
    80003c64:	953e                	add	a0,a0,a5
    80003c66:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80003c6a:	fe043503          	ld	a0,-32(s0)
    80003c6e:	00002097          	auipc	ra,0x2
    80003c72:	e4a080e7          	jalr	-438(ra) # 80005ab8 <fileclose>
  return 0;
    80003c76:	4781                	li	a5,0
}
    80003c78:	853e                	mv	a0,a5
    80003c7a:	60e2                	ld	ra,24(sp)
    80003c7c:	6442                	ld	s0,16(sp)
    80003c7e:	6105                	add	sp,sp,32
    80003c80:	8082                	ret

0000000080003c82 <sys_fstat>:
{
    80003c82:	1101                	add	sp,sp,-32
    80003c84:	ec06                	sd	ra,24(sp)
    80003c86:	e822                	sd	s0,16(sp)
    80003c88:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80003c8a:	fe040593          	add	a1,s0,-32
    80003c8e:	4505                	li	a0,1
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	956080e7          	jalr	-1706(ra) # 800035e6 <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    80003c98:	fe840613          	add	a2,s0,-24
    80003c9c:	4581                	li	a1,0
    80003c9e:	4501                	li	a0,0
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	c6e080e7          	jalr	-914(ra) # 8000390e <argfd>
    80003ca8:	87aa                	mv	a5,a0
    return -1;
    80003caa:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80003cac:	0007ca63          	bltz	a5,80003cc0 <sys_fstat+0x3e>
  return filestat(f, st);
    80003cb0:	fe043583          	ld	a1,-32(s0)
    80003cb4:	fe843503          	ld	a0,-24(s0)
    80003cb8:	00002097          	auipc	ra,0x2
    80003cbc:	ec8080e7          	jalr	-312(ra) # 80005b80 <filestat>
}
    80003cc0:	60e2                	ld	ra,24(sp)
    80003cc2:	6442                	ld	s0,16(sp)
    80003cc4:	6105                	add	sp,sp,32
    80003cc6:	8082                	ret

0000000080003cc8 <sys_link>:
{
    80003cc8:	7169                	add	sp,sp,-304
    80003cca:	f606                	sd	ra,296(sp)
    80003ccc:	f222                	sd	s0,288(sp)
    80003cce:	ee26                	sd	s1,280(sp)
    80003cd0:	ea4a                	sd	s2,272(sp)
    80003cd2:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80003cd4:	08000613          	li	a2,128
    80003cd8:	ed040593          	add	a1,s0,-304
    80003cdc:	4501                	li	a0,0
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	9c4080e7          	jalr	-1596(ra) # 800036a2 <argstr>
    return -1;
    80003ce6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80003ce8:	10054e63          	bltz	a0,80003e04 <sys_link+0x13c>
    80003cec:	08000613          	li	a2,128
    80003cf0:	f5040593          	add	a1,s0,-176
    80003cf4:	4505                	li	a0,1
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	9ac080e7          	jalr	-1620(ra) # 800036a2 <argstr>
    return -1;
    80003cfe:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80003d00:	10054263          	bltz	a0,80003e04 <sys_link+0x13c>
  begin_op();
    80003d04:	00002097          	auipc	ra,0x2
    80003d08:	a1a080e7          	jalr	-1510(ra) # 8000571e <begin_op>
  if((ip = namei(old)) == 0){
    80003d0c:	ed040513          	add	a0,s0,-304
    80003d10:	00002097          	auipc	ra,0x2
    80003d14:	43a080e7          	jalr	1082(ra) # 8000614a <namei>
    80003d18:	84aa                	mv	s1,a0
    80003d1a:	c551                	beqz	a0,80003da6 <sys_link+0xde>
  ilock(ip);
    80003d1c:	00001097          	auipc	ra,0x1
    80003d20:	d70080e7          	jalr	-656(ra) # 80004a8c <ilock>
  if(ip->type == T_DIR){
    80003d24:	04449703          	lh	a4,68(s1)
    80003d28:	4785                	li	a5,1
    80003d2a:	08f70463          	beq	a4,a5,80003db2 <sys_link+0xea>
  ip->nlink++;
    80003d2e:	04a4d783          	lhu	a5,74(s1)
    80003d32:	2785                	addw	a5,a5,1
    80003d34:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80003d38:	8526                	mv	a0,s1
    80003d3a:	00001097          	auipc	ra,0x1
    80003d3e:	c86080e7          	jalr	-890(ra) # 800049c0 <iupdate>
  iunlock(ip);
    80003d42:	8526                	mv	a0,s1
    80003d44:	00001097          	auipc	ra,0x1
    80003d48:	e0a080e7          	jalr	-502(ra) # 80004b4e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80003d4c:	fd040593          	add	a1,s0,-48
    80003d50:	f5040513          	add	a0,s0,-176
    80003d54:	00002097          	auipc	ra,0x2
    80003d58:	414080e7          	jalr	1044(ra) # 80006168 <nameiparent>
    80003d5c:	892a                	mv	s2,a0
    80003d5e:	c935                	beqz	a0,80003dd2 <sys_link+0x10a>
  ilock(dp);
    80003d60:	00001097          	auipc	ra,0x1
    80003d64:	d2c080e7          	jalr	-724(ra) # 80004a8c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80003d68:	00092703          	lw	a4,0(s2)
    80003d6c:	409c                	lw	a5,0(s1)
    80003d6e:	04f71d63          	bne	a4,a5,80003dc8 <sys_link+0x100>
    80003d72:	40d0                	lw	a2,4(s1)
    80003d74:	fd040593          	add	a1,s0,-48
    80003d78:	854a                	mv	a0,s2
    80003d7a:	00002097          	auipc	ra,0x2
    80003d7e:	31e080e7          	jalr	798(ra) # 80006098 <dirlink>
    80003d82:	04054363          	bltz	a0,80003dc8 <sys_link+0x100>
  iunlockput(dp);
    80003d86:	854a                	mv	a0,s2
    80003d88:	00001097          	auipc	ra,0x1
    80003d8c:	f66080e7          	jalr	-154(ra) # 80004cee <iunlockput>
  iput(ip);
    80003d90:	8526                	mv	a0,s1
    80003d92:	00001097          	auipc	ra,0x1
    80003d96:	eb4080e7          	jalr	-332(ra) # 80004c46 <iput>
  end_op();
    80003d9a:	00002097          	auipc	ra,0x2
    80003d9e:	9fe080e7          	jalr	-1538(ra) # 80005798 <end_op>
  return 0;
    80003da2:	4781                	li	a5,0
    80003da4:	a085                	j	80003e04 <sys_link+0x13c>
    end_op();
    80003da6:	00002097          	auipc	ra,0x2
    80003daa:	9f2080e7          	jalr	-1550(ra) # 80005798 <end_op>
    return -1;
    80003dae:	57fd                	li	a5,-1
    80003db0:	a891                	j	80003e04 <sys_link+0x13c>
    iunlockput(ip);
    80003db2:	8526                	mv	a0,s1
    80003db4:	00001097          	auipc	ra,0x1
    80003db8:	f3a080e7          	jalr	-198(ra) # 80004cee <iunlockput>
    end_op();
    80003dbc:	00002097          	auipc	ra,0x2
    80003dc0:	9dc080e7          	jalr	-1572(ra) # 80005798 <end_op>
    return -1;
    80003dc4:	57fd                	li	a5,-1
    80003dc6:	a83d                	j	80003e04 <sys_link+0x13c>
    iunlockput(dp);
    80003dc8:	854a                	mv	a0,s2
    80003dca:	00001097          	auipc	ra,0x1
    80003dce:	f24080e7          	jalr	-220(ra) # 80004cee <iunlockput>
  ilock(ip);
    80003dd2:	8526                	mv	a0,s1
    80003dd4:	00001097          	auipc	ra,0x1
    80003dd8:	cb8080e7          	jalr	-840(ra) # 80004a8c <ilock>
  ip->nlink--;
    80003ddc:	04a4d783          	lhu	a5,74(s1)
    80003de0:	37fd                	addw	a5,a5,-1
    80003de2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80003de6:	8526                	mv	a0,s1
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	bd8080e7          	jalr	-1064(ra) # 800049c0 <iupdate>
  iunlockput(ip);
    80003df0:	8526                	mv	a0,s1
    80003df2:	00001097          	auipc	ra,0x1
    80003df6:	efc080e7          	jalr	-260(ra) # 80004cee <iunlockput>
  end_op();
    80003dfa:	00002097          	auipc	ra,0x2
    80003dfe:	99e080e7          	jalr	-1634(ra) # 80005798 <end_op>
  return -1;
    80003e02:	57fd                	li	a5,-1
}
    80003e04:	853e                	mv	a0,a5
    80003e06:	70b2                	ld	ra,296(sp)
    80003e08:	7412                	ld	s0,288(sp)
    80003e0a:	64f2                	ld	s1,280(sp)
    80003e0c:	6952                	ld	s2,272(sp)
    80003e0e:	6155                	add	sp,sp,304
    80003e10:	8082                	ret

0000000080003e12 <sys_unlink>:
{
    80003e12:	7151                	add	sp,sp,-240
    80003e14:	f586                	sd	ra,232(sp)
    80003e16:	f1a2                	sd	s0,224(sp)
    80003e18:	eda6                	sd	s1,216(sp)
    80003e1a:	e9ca                	sd	s2,208(sp)
    80003e1c:	e5ce                	sd	s3,200(sp)
    80003e1e:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80003e20:	08000613          	li	a2,128
    80003e24:	f3040593          	add	a1,s0,-208
    80003e28:	4501                	li	a0,0
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	878080e7          	jalr	-1928(ra) # 800036a2 <argstr>
    80003e32:	18054163          	bltz	a0,80003fb4 <sys_unlink+0x1a2>
  begin_op();
    80003e36:	00002097          	auipc	ra,0x2
    80003e3a:	8e8080e7          	jalr	-1816(ra) # 8000571e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80003e3e:	fb040593          	add	a1,s0,-80
    80003e42:	f3040513          	add	a0,s0,-208
    80003e46:	00002097          	auipc	ra,0x2
    80003e4a:	322080e7          	jalr	802(ra) # 80006168 <nameiparent>
    80003e4e:	84aa                	mv	s1,a0
    80003e50:	c979                	beqz	a0,80003f26 <sys_unlink+0x114>
  ilock(dp);
    80003e52:	00001097          	auipc	ra,0x1
    80003e56:	c3a080e7          	jalr	-966(ra) # 80004a8c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80003e5a:	00005597          	auipc	a1,0x5
    80003e5e:	a2658593          	add	a1,a1,-1498 # 80008880 <syscalls+0x118>
    80003e62:	fb040513          	add	a0,s0,-80
    80003e66:	00002097          	auipc	ra,0x2
    80003e6a:	00a080e7          	jalr	10(ra) # 80005e70 <namecmp>
    80003e6e:	14050a63          	beqz	a0,80003fc2 <sys_unlink+0x1b0>
    80003e72:	00005597          	auipc	a1,0x5
    80003e76:	a1658593          	add	a1,a1,-1514 # 80008888 <syscalls+0x120>
    80003e7a:	fb040513          	add	a0,s0,-80
    80003e7e:	00002097          	auipc	ra,0x2
    80003e82:	ff2080e7          	jalr	-14(ra) # 80005e70 <namecmp>
    80003e86:	12050e63          	beqz	a0,80003fc2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80003e8a:	f2c40613          	add	a2,s0,-212
    80003e8e:	fb040593          	add	a1,s0,-80
    80003e92:	8526                	mv	a0,s1
    80003e94:	00002097          	auipc	ra,0x2
    80003e98:	ff6080e7          	jalr	-10(ra) # 80005e8a <dirlookup>
    80003e9c:	892a                	mv	s2,a0
    80003e9e:	12050263          	beqz	a0,80003fc2 <sys_unlink+0x1b0>
  ilock(ip);
    80003ea2:	00001097          	auipc	ra,0x1
    80003ea6:	bea080e7          	jalr	-1046(ra) # 80004a8c <ilock>
  if(ip->nlink < 1)
    80003eaa:	04a91783          	lh	a5,74(s2)
    80003eae:	08f05263          	blez	a5,80003f32 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80003eb2:	04491703          	lh	a4,68(s2)
    80003eb6:	4785                	li	a5,1
    80003eb8:	08f70563          	beq	a4,a5,80003f42 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80003ebc:	4641                	li	a2,16
    80003ebe:	4581                	li	a1,0
    80003ec0:	fc040513          	add	a0,s0,-64
    80003ec4:	ffffd097          	auipc	ra,0xffffd
    80003ec8:	0d4080e7          	jalr	212(ra) # 80000f98 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ecc:	4741                	li	a4,16
    80003ece:	f2c42683          	lw	a3,-212(s0)
    80003ed2:	fc040613          	add	a2,s0,-64
    80003ed6:	4581                	li	a1,0
    80003ed8:	8526                	mv	a0,s1
    80003eda:	00001097          	auipc	ra,0x1
    80003ede:	f5e080e7          	jalr	-162(ra) # 80004e38 <writei>
    80003ee2:	47c1                	li	a5,16
    80003ee4:	0af51563          	bne	a0,a5,80003f8e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80003ee8:	04491703          	lh	a4,68(s2)
    80003eec:	4785                	li	a5,1
    80003eee:	0af70863          	beq	a4,a5,80003f9e <sys_unlink+0x18c>
  iunlockput(dp);
    80003ef2:	8526                	mv	a0,s1
    80003ef4:	00001097          	auipc	ra,0x1
    80003ef8:	dfa080e7          	jalr	-518(ra) # 80004cee <iunlockput>
  ip->nlink--;
    80003efc:	04a95783          	lhu	a5,74(s2)
    80003f00:	37fd                	addw	a5,a5,-1
    80003f02:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80003f06:	854a                	mv	a0,s2
    80003f08:	00001097          	auipc	ra,0x1
    80003f0c:	ab8080e7          	jalr	-1352(ra) # 800049c0 <iupdate>
  iunlockput(ip);
    80003f10:	854a                	mv	a0,s2
    80003f12:	00001097          	auipc	ra,0x1
    80003f16:	ddc080e7          	jalr	-548(ra) # 80004cee <iunlockput>
  end_op();
    80003f1a:	00002097          	auipc	ra,0x2
    80003f1e:	87e080e7          	jalr	-1922(ra) # 80005798 <end_op>
  return 0;
    80003f22:	4501                	li	a0,0
    80003f24:	a84d                	j	80003fd6 <sys_unlink+0x1c4>
    end_op();
    80003f26:	00002097          	auipc	ra,0x2
    80003f2a:	872080e7          	jalr	-1934(ra) # 80005798 <end_op>
    return -1;
    80003f2e:	557d                	li	a0,-1
    80003f30:	a05d                	j	80003fd6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80003f32:	00005517          	auipc	a0,0x5
    80003f36:	95e50513          	add	a0,a0,-1698 # 80008890 <syscalls+0x128>
    80003f3a:	ffffd097          	auipc	ra,0xffffd
    80003f3e:	2a6080e7          	jalr	678(ra) # 800011e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80003f42:	04c92703          	lw	a4,76(s2)
    80003f46:	02000793          	li	a5,32
    80003f4a:	f6e7f9e3          	bgeu	a5,a4,80003ebc <sys_unlink+0xaa>
    80003f4e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f52:	4741                	li	a4,16
    80003f54:	86ce                	mv	a3,s3
    80003f56:	f1840613          	add	a2,s0,-232
    80003f5a:	4581                	li	a1,0
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	00001097          	auipc	ra,0x1
    80003f62:	de2080e7          	jalr	-542(ra) # 80004d40 <readi>
    80003f66:	47c1                	li	a5,16
    80003f68:	00f51b63          	bne	a0,a5,80003f7e <sys_unlink+0x16c>
    if(de.inum != 0)
    80003f6c:	f1845783          	lhu	a5,-232(s0)
    80003f70:	e7a1                	bnez	a5,80003fb8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80003f72:	29c1                	addw	s3,s3,16
    80003f74:	04c92783          	lw	a5,76(s2)
    80003f78:	fcf9ede3          	bltu	s3,a5,80003f52 <sys_unlink+0x140>
    80003f7c:	b781                	j	80003ebc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80003f7e:	00005517          	auipc	a0,0x5
    80003f82:	92a50513          	add	a0,a0,-1750 # 800088a8 <syscalls+0x140>
    80003f86:	ffffd097          	auipc	ra,0xffffd
    80003f8a:	25a080e7          	jalr	602(ra) # 800011e0 <panic>
    panic("unlink: writei");
    80003f8e:	00005517          	auipc	a0,0x5
    80003f92:	93250513          	add	a0,a0,-1742 # 800088c0 <syscalls+0x158>
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	24a080e7          	jalr	586(ra) # 800011e0 <panic>
    dp->nlink--;
    80003f9e:	04a4d783          	lhu	a5,74(s1)
    80003fa2:	37fd                	addw	a5,a5,-1
    80003fa4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80003fa8:	8526                	mv	a0,s1
    80003faa:	00001097          	auipc	ra,0x1
    80003fae:	a16080e7          	jalr	-1514(ra) # 800049c0 <iupdate>
    80003fb2:	b781                	j	80003ef2 <sys_unlink+0xe0>
    return -1;
    80003fb4:	557d                	li	a0,-1
    80003fb6:	a005                	j	80003fd6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80003fb8:	854a                	mv	a0,s2
    80003fba:	00001097          	auipc	ra,0x1
    80003fbe:	d34080e7          	jalr	-716(ra) # 80004cee <iunlockput>
  iunlockput(dp);
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	00001097          	auipc	ra,0x1
    80003fc8:	d2a080e7          	jalr	-726(ra) # 80004cee <iunlockput>
  end_op();
    80003fcc:	00001097          	auipc	ra,0x1
    80003fd0:	7cc080e7          	jalr	1996(ra) # 80005798 <end_op>
  return -1;
    80003fd4:	557d                	li	a0,-1
}
    80003fd6:	70ae                	ld	ra,232(sp)
    80003fd8:	740e                	ld	s0,224(sp)
    80003fda:	64ee                	ld	s1,216(sp)
    80003fdc:	694e                	ld	s2,208(sp)
    80003fde:	69ae                	ld	s3,200(sp)
    80003fe0:	616d                	add	sp,sp,240
    80003fe2:	8082                	ret

0000000080003fe4 <sys_open>:

uint64
sys_open(void)
{
    80003fe4:	7131                	add	sp,sp,-192
    80003fe6:	fd06                	sd	ra,184(sp)
    80003fe8:	f922                	sd	s0,176(sp)
    80003fea:	f526                	sd	s1,168(sp)
    80003fec:	f14a                	sd	s2,160(sp)
    80003fee:	ed4e                	sd	s3,152(sp)
    80003ff0:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80003ff2:	f4c40593          	add	a1,s0,-180
    80003ff6:	4505                	li	a0,1
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	5ee080e7          	jalr	1518(ra) # 800035e6 <arg_uint64>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004000:	08000613          	li	a2,128
    80004004:	f5040593          	add	a1,s0,-176
    80004008:	4501                	li	a0,0
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	698080e7          	jalr	1688(ra) # 800036a2 <argstr>
    80004012:	87aa                	mv	a5,a0
    return -1;
    80004014:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004016:	0a07c863          	bltz	a5,800040c6 <sys_open+0xe2>

  begin_op();
    8000401a:	00001097          	auipc	ra,0x1
    8000401e:	704080e7          	jalr	1796(ra) # 8000571e <begin_op>

  if(omode & O_CREATE){
    80004022:	f4c42783          	lw	a5,-180(s0)
    80004026:	2007f793          	and	a5,a5,512
    8000402a:	cbdd                	beqz	a5,800040e0 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000402c:	4681                	li	a3,0
    8000402e:	4601                	li	a2,0
    80004030:	4589                	li	a1,2
    80004032:	f5040513          	add	a0,s0,-176
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	97a080e7          	jalr	-1670(ra) # 800039b0 <create>
    8000403e:	84aa                	mv	s1,a0
    if(ip == 0){
    80004040:	c951                	beqz	a0,800040d4 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004042:	04449703          	lh	a4,68(s1)
    80004046:	478d                	li	a5,3
    80004048:	00f71763          	bne	a4,a5,80004056 <sys_open+0x72>
    8000404c:	0464d703          	lhu	a4,70(s1)
    80004050:	47a5                	li	a5,9
    80004052:	0ce7ec63          	bltu	a5,a4,8000412a <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80004056:	00002097          	auipc	ra,0x2
    8000405a:	9a6080e7          	jalr	-1626(ra) # 800059fc <filealloc>
    8000405e:	892a                	mv	s2,a0
    80004060:	c56d                	beqz	a0,8000414a <sys_open+0x166>
    80004062:	00000097          	auipc	ra,0x0
    80004066:	90c080e7          	jalr	-1780(ra) # 8000396e <fdalloc>
    8000406a:	89aa                	mv	s3,a0
    8000406c:	0c054a63          	bltz	a0,80004140 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80004070:	04449703          	lh	a4,68(s1)
    80004074:	478d                	li	a5,3
    80004076:	0ef70563          	beq	a4,a5,80004160 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000407a:	4789                	li	a5,2
    8000407c:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80004080:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80004084:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80004088:	f4c42783          	lw	a5,-180(s0)
    8000408c:	0017c713          	xor	a4,a5,1
    80004090:	8b05                	and	a4,a4,1
    80004092:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80004096:	0037f713          	and	a4,a5,3
    8000409a:	00e03733          	snez	a4,a4
    8000409e:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800040a2:	4007f793          	and	a5,a5,1024
    800040a6:	c791                	beqz	a5,800040b2 <sys_open+0xce>
    800040a8:	04449703          	lh	a4,68(s1)
    800040ac:	4789                	li	a5,2
    800040ae:	0cf70063          	beq	a4,a5,8000416e <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800040b2:	8526                	mv	a0,s1
    800040b4:	00001097          	auipc	ra,0x1
    800040b8:	a9a080e7          	jalr	-1382(ra) # 80004b4e <iunlock>
  end_op();
    800040bc:	00001097          	auipc	ra,0x1
    800040c0:	6dc080e7          	jalr	1756(ra) # 80005798 <end_op>

  return fd;
    800040c4:	854e                	mv	a0,s3
}
    800040c6:	70ea                	ld	ra,184(sp)
    800040c8:	744a                	ld	s0,176(sp)
    800040ca:	74aa                	ld	s1,168(sp)
    800040cc:	790a                	ld	s2,160(sp)
    800040ce:	69ea                	ld	s3,152(sp)
    800040d0:	6129                	add	sp,sp,192
    800040d2:	8082                	ret
      end_op();
    800040d4:	00001097          	auipc	ra,0x1
    800040d8:	6c4080e7          	jalr	1732(ra) # 80005798 <end_op>
      return -1;
    800040dc:	557d                	li	a0,-1
    800040de:	b7e5                	j	800040c6 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800040e0:	f5040513          	add	a0,s0,-176
    800040e4:	00002097          	auipc	ra,0x2
    800040e8:	066080e7          	jalr	102(ra) # 8000614a <namei>
    800040ec:	84aa                	mv	s1,a0
    800040ee:	c905                	beqz	a0,8000411e <sys_open+0x13a>
    ilock(ip);
    800040f0:	00001097          	auipc	ra,0x1
    800040f4:	99c080e7          	jalr	-1636(ra) # 80004a8c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800040f8:	04449703          	lh	a4,68(s1)
    800040fc:	4785                	li	a5,1
    800040fe:	f4f712e3          	bne	a4,a5,80004042 <sys_open+0x5e>
    80004102:	f4c42783          	lw	a5,-180(s0)
    80004106:	dba1                	beqz	a5,80004056 <sys_open+0x72>
      iunlockput(ip);
    80004108:	8526                	mv	a0,s1
    8000410a:	00001097          	auipc	ra,0x1
    8000410e:	be4080e7          	jalr	-1052(ra) # 80004cee <iunlockput>
      end_op();
    80004112:	00001097          	auipc	ra,0x1
    80004116:	686080e7          	jalr	1670(ra) # 80005798 <end_op>
      return -1;
    8000411a:	557d                	li	a0,-1
    8000411c:	b76d                	j	800040c6 <sys_open+0xe2>
      end_op();
    8000411e:	00001097          	auipc	ra,0x1
    80004122:	67a080e7          	jalr	1658(ra) # 80005798 <end_op>
      return -1;
    80004126:	557d                	li	a0,-1
    80004128:	bf79                	j	800040c6 <sys_open+0xe2>
    iunlockput(ip);
    8000412a:	8526                	mv	a0,s1
    8000412c:	00001097          	auipc	ra,0x1
    80004130:	bc2080e7          	jalr	-1086(ra) # 80004cee <iunlockput>
    end_op();
    80004134:	00001097          	auipc	ra,0x1
    80004138:	664080e7          	jalr	1636(ra) # 80005798 <end_op>
    return -1;
    8000413c:	557d                	li	a0,-1
    8000413e:	b761                	j	800040c6 <sys_open+0xe2>
      fileclose(f);
    80004140:	854a                	mv	a0,s2
    80004142:	00002097          	auipc	ra,0x2
    80004146:	976080e7          	jalr	-1674(ra) # 80005ab8 <fileclose>
    iunlockput(ip);
    8000414a:	8526                	mv	a0,s1
    8000414c:	00001097          	auipc	ra,0x1
    80004150:	ba2080e7          	jalr	-1118(ra) # 80004cee <iunlockput>
    end_op();
    80004154:	00001097          	auipc	ra,0x1
    80004158:	644080e7          	jalr	1604(ra) # 80005798 <end_op>
    return -1;
    8000415c:	557d                	li	a0,-1
    8000415e:	b7a5                	j	800040c6 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80004160:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80004164:	04649783          	lh	a5,70(s1)
    80004168:	02f91223          	sh	a5,36(s2)
    8000416c:	bf21                	j	80004084 <sys_open+0xa0>
    itrunc(ip);
    8000416e:	8526                	mv	a0,s1
    80004170:	00001097          	auipc	ra,0x1
    80004174:	a2a080e7          	jalr	-1494(ra) # 80004b9a <itrunc>
    80004178:	bf2d                	j	800040b2 <sys_open+0xce>

000000008000417a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000417a:	7175                	add	sp,sp,-144
    8000417c:	e506                	sd	ra,136(sp)
    8000417e:	e122                	sd	s0,128(sp)
    80004180:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80004182:	00001097          	auipc	ra,0x1
    80004186:	59c080e7          	jalr	1436(ra) # 8000571e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000418a:	08000613          	li	a2,128
    8000418e:	f7040593          	add	a1,s0,-144
    80004192:	4501                	li	a0,0
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	50e080e7          	jalr	1294(ra) # 800036a2 <argstr>
    8000419c:	02054963          	bltz	a0,800041ce <sys_mkdir+0x54>
    800041a0:	4681                	li	a3,0
    800041a2:	4601                	li	a2,0
    800041a4:	4585                	li	a1,1
    800041a6:	f7040513          	add	a0,s0,-144
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	806080e7          	jalr	-2042(ra) # 800039b0 <create>
    800041b2:	cd11                	beqz	a0,800041ce <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800041b4:	00001097          	auipc	ra,0x1
    800041b8:	b3a080e7          	jalr	-1222(ra) # 80004cee <iunlockput>
  end_op();
    800041bc:	00001097          	auipc	ra,0x1
    800041c0:	5dc080e7          	jalr	1500(ra) # 80005798 <end_op>
  return 0;
    800041c4:	4501                	li	a0,0
}
    800041c6:	60aa                	ld	ra,136(sp)
    800041c8:	640a                	ld	s0,128(sp)
    800041ca:	6149                	add	sp,sp,144
    800041cc:	8082                	ret
    end_op();
    800041ce:	00001097          	auipc	ra,0x1
    800041d2:	5ca080e7          	jalr	1482(ra) # 80005798 <end_op>
    return -1;
    800041d6:	557d                	li	a0,-1
    800041d8:	b7fd                	j	800041c6 <sys_mkdir+0x4c>

00000000800041da <sys_mknod>:

uint64
sys_mknod(void)
{
    800041da:	7135                	add	sp,sp,-160
    800041dc:	ed06                	sd	ra,152(sp)
    800041de:	e922                	sd	s0,144(sp)
    800041e0:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800041e2:	00001097          	auipc	ra,0x1
    800041e6:	53c080e7          	jalr	1340(ra) # 8000571e <begin_op>
  argint(1, &major);
    800041ea:	f6c40593          	add	a1,s0,-148
    800041ee:	4505                	li	a0,1
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	3f6080e7          	jalr	1014(ra) # 800035e6 <arg_uint64>
  argint(2, &minor);
    800041f8:	f6840593          	add	a1,s0,-152
    800041fc:	4509                	li	a0,2
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	3e8080e7          	jalr	1000(ra) # 800035e6 <arg_uint64>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004206:	08000613          	li	a2,128
    8000420a:	f7040593          	add	a1,s0,-144
    8000420e:	4501                	li	a0,0
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	492080e7          	jalr	1170(ra) # 800036a2 <argstr>
    80004218:	02054b63          	bltz	a0,8000424e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000421c:	f6841683          	lh	a3,-152(s0)
    80004220:	f6c41603          	lh	a2,-148(s0)
    80004224:	458d                	li	a1,3
    80004226:	f7040513          	add	a0,s0,-144
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	786080e7          	jalr	1926(ra) # 800039b0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004232:	cd11                	beqz	a0,8000424e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004234:	00001097          	auipc	ra,0x1
    80004238:	aba080e7          	jalr	-1350(ra) # 80004cee <iunlockput>
  end_op();
    8000423c:	00001097          	auipc	ra,0x1
    80004240:	55c080e7          	jalr	1372(ra) # 80005798 <end_op>
  return 0;
    80004244:	4501                	li	a0,0
}
    80004246:	60ea                	ld	ra,152(sp)
    80004248:	644a                	ld	s0,144(sp)
    8000424a:	610d                	add	sp,sp,160
    8000424c:	8082                	ret
    end_op();
    8000424e:	00001097          	auipc	ra,0x1
    80004252:	54a080e7          	jalr	1354(ra) # 80005798 <end_op>
    return -1;
    80004256:	557d                	li	a0,-1
    80004258:	b7fd                	j	80004246 <sys_mknod+0x6c>

000000008000425a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000425a:	7135                	add	sp,sp,-160
    8000425c:	ed06                	sd	ra,152(sp)
    8000425e:	e922                	sd	s0,144(sp)
    80004260:	e526                	sd	s1,136(sp)
    80004262:	e14a                	sd	s2,128(sp)
    80004264:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80004266:	ffffe097          	auipc	ra,0xffffe
    8000426a:	ea8080e7          	jalr	-344(ra) # 8000210e <myproc>
    8000426e:	892a                	mv	s2,a0
  
  begin_op();
    80004270:	00001097          	auipc	ra,0x1
    80004274:	4ae080e7          	jalr	1198(ra) # 8000571e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80004278:	08000613          	li	a2,128
    8000427c:	f6040593          	add	a1,s0,-160
    80004280:	4501                	li	a0,0
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	420080e7          	jalr	1056(ra) # 800036a2 <argstr>
    8000428a:	04054b63          	bltz	a0,800042e0 <sys_chdir+0x86>
    8000428e:	f6040513          	add	a0,s0,-160
    80004292:	00002097          	auipc	ra,0x2
    80004296:	eb8080e7          	jalr	-328(ra) # 8000614a <namei>
    8000429a:	84aa                	mv	s1,a0
    8000429c:	c131                	beqz	a0,800042e0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	7ee080e7          	jalr	2030(ra) # 80004a8c <ilock>
  if(ip->type != T_DIR){
    800042a6:	04449703          	lh	a4,68(s1)
    800042aa:	4785                	li	a5,1
    800042ac:	04f71063          	bne	a4,a5,800042ec <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800042b0:	8526                	mv	a0,s1
    800042b2:	00001097          	auipc	ra,0x1
    800042b6:	89c080e7          	jalr	-1892(ra) # 80004b4e <iunlock>
  iput(p->cwd);
    800042ba:	0e093503          	ld	a0,224(s2)
    800042be:	00001097          	auipc	ra,0x1
    800042c2:	988080e7          	jalr	-1656(ra) # 80004c46 <iput>
  end_op();
    800042c6:	00001097          	auipc	ra,0x1
    800042ca:	4d2080e7          	jalr	1234(ra) # 80005798 <end_op>
  p->cwd = ip;
    800042ce:	0e993023          	sd	s1,224(s2)
  return 0;
    800042d2:	4501                	li	a0,0
}
    800042d4:	60ea                	ld	ra,152(sp)
    800042d6:	644a                	ld	s0,144(sp)
    800042d8:	64aa                	ld	s1,136(sp)
    800042da:	690a                	ld	s2,128(sp)
    800042dc:	610d                	add	sp,sp,160
    800042de:	8082                	ret
    end_op();
    800042e0:	00001097          	auipc	ra,0x1
    800042e4:	4b8080e7          	jalr	1208(ra) # 80005798 <end_op>
    return -1;
    800042e8:	557d                	li	a0,-1
    800042ea:	b7ed                	j	800042d4 <sys_chdir+0x7a>
    iunlockput(ip);
    800042ec:	8526                	mv	a0,s1
    800042ee:	00001097          	auipc	ra,0x1
    800042f2:	a00080e7          	jalr	-1536(ra) # 80004cee <iunlockput>
    end_op();
    800042f6:	00001097          	auipc	ra,0x1
    800042fa:	4a2080e7          	jalr	1186(ra) # 80005798 <end_op>
    return -1;
    800042fe:	557d                	li	a0,-1
    80004300:	bfd1                	j	800042d4 <sys_chdir+0x7a>

0000000080004302 <sys_pipe>:
//   return -1;
// }

uint64
sys_pipe(void)
{
    80004302:	7139                	add	sp,sp,-64
    80004304:	fc06                	sd	ra,56(sp)
    80004306:	f822                	sd	s0,48(sp)
    80004308:	f426                	sd	s1,40(sp)
    8000430a:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000430c:	ffffe097          	auipc	ra,0xffffe
    80004310:	e02080e7          	jalr	-510(ra) # 8000210e <myproc>
    80004314:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80004316:	fd840593          	add	a1,s0,-40
    8000431a:	4501                	li	a0,0
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	2ca080e7          	jalr	714(ra) # 800035e6 <arg_uint64>
  if(pipealloc(&rf, &wf) < 0)
    80004324:	fc840593          	add	a1,s0,-56
    80004328:	fd040513          	add	a0,s0,-48
    8000432c:	00002097          	auipc	ra,0x2
    80004330:	06a080e7          	jalr	106(ra) # 80006396 <pipealloc>
    return -1;
    80004334:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80004336:	0c054463          	bltz	a0,800043fe <sys_pipe+0xfc>
  fd0 = -1;
    8000433a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000433e:	fd043503          	ld	a0,-48(s0)
    80004342:	fffff097          	auipc	ra,0xfffff
    80004346:	62c080e7          	jalr	1580(ra) # 8000396e <fdalloc>
    8000434a:	fca42223          	sw	a0,-60(s0)
    8000434e:	08054b63          	bltz	a0,800043e4 <sys_pipe+0xe2>
    80004352:	fc843503          	ld	a0,-56(s0)
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	618080e7          	jalr	1560(ra) # 8000396e <fdalloc>
    8000435e:	fca42023          	sw	a0,-64(s0)
    80004362:	06054863          	bltz	a0,800043d2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pgtbl, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80004366:	4691                	li	a3,4
    80004368:	fc440613          	add	a2,s0,-60
    8000436c:	fd843583          	ld	a1,-40(s0)
    80004370:	64a8                	ld	a0,72(s1)
    80004372:	ffffe097          	auipc	ra,0xffffe
    80004376:	b9a080e7          	jalr	-1126(ra) # 80001f0c <copyout>
    8000437a:	02054063          	bltz	a0,8000439a <sys_pipe+0x98>
     copyout(p->pgtbl, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000437e:	4691                	li	a3,4
    80004380:	fc040613          	add	a2,s0,-64
    80004384:	fd843583          	ld	a1,-40(s0)
    80004388:	0591                	add	a1,a1,4
    8000438a:	64a8                	ld	a0,72(s1)
    8000438c:	ffffe097          	auipc	ra,0xffffe
    80004390:	b80080e7          	jalr	-1152(ra) # 80001f0c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80004394:	4781                	li	a5,0
  if(copyout(p->pgtbl, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80004396:	06055463          	bgez	a0,800043fe <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000439a:	fc442783          	lw	a5,-60(s0)
    8000439e:	07b1                	add	a5,a5,12
    800043a0:	078e                	sll	a5,a5,0x3
    800043a2:	97a6                	add	a5,a5,s1
    800043a4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800043a8:	fc042783          	lw	a5,-64(s0)
    800043ac:	07b1                	add	a5,a5,12
    800043ae:	078e                	sll	a5,a5,0x3
    800043b0:	94be                	add	s1,s1,a5
    800043b2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800043b6:	fd043503          	ld	a0,-48(s0)
    800043ba:	00001097          	auipc	ra,0x1
    800043be:	6fe080e7          	jalr	1790(ra) # 80005ab8 <fileclose>
    fileclose(wf);
    800043c2:	fc843503          	ld	a0,-56(s0)
    800043c6:	00001097          	auipc	ra,0x1
    800043ca:	6f2080e7          	jalr	1778(ra) # 80005ab8 <fileclose>
    return -1;
    800043ce:	57fd                	li	a5,-1
    800043d0:	a03d                	j	800043fe <sys_pipe+0xfc>
    if(fd0 >= 0)
    800043d2:	fc442783          	lw	a5,-60(s0)
    800043d6:	0007c763          	bltz	a5,800043e4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800043da:	07b1                	add	a5,a5,12
    800043dc:	078e                	sll	a5,a5,0x3
    800043de:	97a6                	add	a5,a5,s1
    800043e0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800043e4:	fd043503          	ld	a0,-48(s0)
    800043e8:	00001097          	auipc	ra,0x1
    800043ec:	6d0080e7          	jalr	1744(ra) # 80005ab8 <fileclose>
    fileclose(wf);
    800043f0:	fc843503          	ld	a0,-56(s0)
    800043f4:	00001097          	auipc	ra,0x1
    800043f8:	6c4080e7          	jalr	1732(ra) # 80005ab8 <fileclose>
    return -1;
    800043fc:	57fd                	li	a5,-1
}
    800043fe:	853e                	mv	a0,a5
    80004400:	70e2                	ld	ra,56(sp)
    80004402:	7442                	ld	s0,48(sp)
    80004404:	74a2                	ld	s1,40(sp)
    80004406:	6121                	add	sp,sp,64
    80004408:	8082                	ret

000000008000440a <sys_lseek>:
// int fd
// uint32 offset
// int flags (见LSEEK_xxx)
// 成功返回新的偏移量, 失败返回-1
uint64 sys_lseek()
{
    8000440a:	1101                	add	sp,sp,-32
    8000440c:	ec06                	sd	ra,24(sp)
    8000440e:	e822                	sd	s0,16(sp)
    80004410:	1000                	add	s0,sp,32
    struct file* file;
    uint32 offset;
    int flags;

    if(argfd(0, 0, &file) < 0)
    80004412:	fe840613          	add	a2,s0,-24
    80004416:	4581                	li	a1,0
    80004418:	4501                	li	a0,0
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	4f4080e7          	jalr	1268(ra) # 8000390e <argfd>
    80004422:	87aa                	mv	a5,a0
        return -1;
    80004424:	557d                	li	a0,-1
    if(argfd(0, 0, &file) < 0)
    80004426:	0207cc63          	bltz	a5,8000445e <sys_lseek+0x54>
    arg_uint32(1, &offset);
    8000442a:	fe440593          	add	a1,s0,-28
    8000442e:	4505                	li	a0,1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	196080e7          	jalr	406(ra) # 800035c6 <arg_uint32>
    arg_uint32(2, (uint32*)(&flags));
    80004438:	fe040593          	add	a1,s0,-32
    8000443c:	4509                	li	a0,2
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	188080e7          	jalr	392(ra) # 800035c6 <arg_uint32>

    return file_lseek(file, offset, flags);
    80004446:	fe042603          	lw	a2,-32(s0)
    8000444a:	fe442583          	lw	a1,-28(s0)
    8000444e:	fe843503          	ld	a0,-24(s0)
    80004452:	00002097          	auipc	ra,0x2
    80004456:	992080e7          	jalr	-1646(ra) # 80005de4 <file_lseek>
    8000445a:	1502                	sll	a0,a0,0x20
    8000445c:	9101                	srl	a0,a0,0x20
}
    8000445e:	60e2                	ld	ra,24(sp)
    80004460:	6442                	ld	s0,16(sp)
    80004462:	6105                	add	sp,sp,32
    80004464:	8082                	ret

0000000080004466 <sys_alloc_block>:
//     inode_unlock(file->ip);

//     return len;
// }

uint64 sys_alloc_block(void) {
    80004466:	1101                	add	sp,sp,-32
    80004468:	ec06                	sd	ra,24(sp)
    8000446a:	e822                	sd	s0,16(sp)
    8000446c:	e426                	sd	s1,8(sp)
    8000446e:	e04a                	sd	s2,0(sp)
    80004470:	1000                	add	s0,sp,32
    begin_op();
    80004472:	00001097          	auipc	ra,0x1
    80004476:	2ac080e7          	jalr	684(ra) # 8000571e <begin_op>
    
    // 使用根目录而不是当前目录
    struct inode *root = namei("/");
    8000447a:	00004517          	auipc	a0,0x4
    8000447e:	02650513          	add	a0,a0,38 # 800084a0 <digits+0x2b0>
    80004482:	00002097          	auipc	ra,0x2
    80004486:	cc8080e7          	jalr	-824(ra) # 8000614a <namei>
    if(root == 0) {
    8000448a:	c921                	beqz	a0,800044da <sys_alloc_block+0x74>
    8000448c:	84aa                	mv	s1,a0
        end_op();
        return -1;
    }
    
    ilock(root);  // 加锁
    8000448e:	00000097          	auipc	ra,0x0
    80004492:	5fe080e7          	jalr	1534(ra) # 80004a8c <ilock>
    
    uint bn = balloc(root->dev);
    80004496:	4088                	lw	a0,0(s1)
    80004498:	00002097          	auipc	ra,0x2
    8000449c:	232080e7          	jalr	562(ra) # 800066ca <balloc>
    800044a0:	0005091b          	sext.w	s2,a0
    printf(COLOR_GREEN "sys_alloc_block: allocated block %d\n" COLOR_RESET, bn);
    800044a4:	85ca                	mv	a1,s2
    800044a6:	00004517          	auipc	a0,0x4
    800044aa:	42a50513          	add	a0,a0,1066 # 800088d0 <syscalls+0x168>
    800044ae:	ffffd097          	auipc	ra,0xffffd
    800044b2:	d7c080e7          	jalr	-644(ra) # 8000122a <printf>
    
    iunlockput(root);
    800044b6:	8526                	mv	a0,s1
    800044b8:	00001097          	auipc	ra,0x1
    800044bc:	836080e7          	jalr	-1994(ra) # 80004cee <iunlockput>
    end_op();
    800044c0:	00001097          	auipc	ra,0x1
    800044c4:	2d8080e7          	jalr	728(ra) # 80005798 <end_op>
    return bn;
    800044c8:	02091513          	sll	a0,s2,0x20
    800044cc:	9101                	srl	a0,a0,0x20
}
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6902                	ld	s2,0(sp)
    800044d6:	6105                	add	sp,sp,32
    800044d8:	8082                	ret
        end_op();
    800044da:	00001097          	auipc	ra,0x1
    800044de:	2be080e7          	jalr	702(ra) # 80005798 <end_op>
        return -1;
    800044e2:	557d                	li	a0,-1
    800044e4:	b7ed                	j	800044ce <sys_alloc_block+0x68>

00000000800044e6 <sys_free_block>:

// 释放一个数据块
uint64 sys_free_block(void) {
    800044e6:	7179                	add	sp,sp,-48
    800044e8:	f406                	sd	ra,40(sp)
    800044ea:	f022                	sd	s0,32(sp)
    800044ec:	ec26                	sd	s1,24(sp)
    800044ee:	1800                	add	s0,sp,48
    uint bn;
    
    // 检查参数
    argint(0, (int*)&bn) ;
    800044f0:	fdc40593          	add	a1,s0,-36
    800044f4:	4501                	li	a0,0
    800044f6:	fffff097          	auipc	ra,0xfffff
    800044fa:	0f0080e7          	jalr	240(ra) # 800035e6 <arg_uint64>
    
    printf(COLOR_GREEN "sys_free_block: freeing block %d\n" COLOR_RESET , bn);
    800044fe:	fdc42583          	lw	a1,-36(s0)
    80004502:	00004517          	auipc	a0,0x4
    80004506:	3fe50513          	add	a0,a0,1022 # 80008900 <syscalls+0x198>
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	d20080e7          	jalr	-736(ra) # 8000122a <printf>
    
    begin_op();
    80004512:	00001097          	auipc	ra,0x1
    80004516:	20c080e7          	jalr	524(ra) # 8000571e <begin_op>
    
    // 使用根目录
    struct inode *root = namei("/");
    8000451a:	00004517          	auipc	a0,0x4
    8000451e:	f8650513          	add	a0,a0,-122 # 800084a0 <digits+0x2b0>
    80004522:	00002097          	auipc	ra,0x2
    80004526:	c28080e7          	jalr	-984(ra) # 8000614a <namei>
    if(root == 0) {
    8000452a:	cd05                	beqz	a0,80004562 <sys_free_block+0x7c>
    8000452c:	84aa                	mv	s1,a0
        end_op();
        return -1;
    }
    
    // 锁定根目录
    ilock(root);
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	55e080e7          	jalr	1374(ra) # 80004a8c <ilock>
    
    // 释放块
    bfree(root->dev, bn);
    80004536:	fdc42583          	lw	a1,-36(s0)
    8000453a:	4088                	lw	a0,0(s1)
    8000453c:	00002097          	auipc	ra,0x2
    80004540:	2c0080e7          	jalr	704(ra) # 800067fc <bfree>
    
    // 解锁
    iunlockput(root);
    80004544:	8526                	mv	a0,s1
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	7a8080e7          	jalr	1960(ra) # 80004cee <iunlockput>
    
    end_op();
    8000454e:	00001097          	auipc	ra,0x1
    80004552:	24a080e7          	jalr	586(ra) # 80005798 <end_op>
    
    return 0;
    80004556:	4501                	li	a0,0
}
    80004558:	70a2                	ld	ra,40(sp)
    8000455a:	7402                	ld	s0,32(sp)
    8000455c:	64e2                	ld	s1,24(sp)
    8000455e:	6145                	add	sp,sp,48
    80004560:	8082                	ret
        printf(COLOR_RED "sys_free_block: root not found\n" COLOR_RESET);
    80004562:	00004517          	auipc	a0,0x4
    80004566:	3ce50513          	add	a0,a0,974 # 80008930 <syscalls+0x1c8>
    8000456a:	ffffd097          	auipc	ra,0xffffd
    8000456e:	cc0080e7          	jalr	-832(ra) # 8000122a <printf>
        end_op();
    80004572:	00001097          	auipc	ra,0x1
    80004576:	226080e7          	jalr	550(ra) # 80005798 <end_op>
        return -1;
    8000457a:	557d                	li	a0,-1
    8000457c:	bff1                	j	80004558 <sys_free_block+0x72>

000000008000457e <sys_show_buf>:

uint64 sys_show_buf(void) {
    8000457e:	1141                	add	sp,sp,-16
    80004580:	e406                	sd	ra,8(sp)
    80004582:	e022                	sd	s0,0(sp)
    80004584:	0800                	add	s0,sp,16
    buf_print();
    80004586:	00001097          	auipc	ra,0x1
    8000458a:	e16080e7          	jalr	-490(ra) # 8000539c <buf_print>
    return 0;
}
    8000458e:	4501                	li	a0,0
    80004590:	60a2                	ld	ra,8(sp)
    80004592:	6402                	ld	s0,0(sp)
    80004594:	0141                	add	sp,sp,16
    80004596:	8082                	ret

0000000080004598 <sys_write_block>:

uint64 sys_write_block(void) {
    80004598:	7179                	add	sp,sp,-48
    8000459a:	f406                	sd	ra,40(sp)
    8000459c:	f022                	sd	s0,32(sp)
    8000459e:	ec26                	sd	s1,24(sp)
    800045a0:	1800                	add	s0,sp,48
    uint64 buf_handle;
    uint64 addr;
    struct buf *b;

    argaddr(0, &buf_handle);
    800045a2:	fd840593          	add	a1,s0,-40
    800045a6:	4501                	li	a0,0
    800045a8:	fffff097          	auipc	ra,0xfffff
    800045ac:	03e080e7          	jalr	62(ra) # 800035e6 <arg_uint64>
    argaddr(1, &addr);
    800045b0:	fd040593          	add	a1,s0,-48
    800045b4:	4505                	li	a0,1
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	030080e7          	jalr	48(ra) # 800035e6 <arg_uint64>

    b = (struct buf*)buf_handle;
    800045be:	fd843483          	ld	s1,-40(s0)
    if(b == 0) return -1;
    800045c2:	557d                	li	a0,-1
    800045c4:	c0a1                	beqz	s1,80004604 <sys_write_block+0x6c>

    begin_op(); // Need op for bwrite? bwrite calls virtio_disk_rw. log_write calls bwrite.
    800045c6:	00001097          	auipc	ra,0x1
    800045ca:	158080e7          	jalr	344(ra) # 8000571e <begin_op>
    // If we use logging, we should use log_write. But here we use bwrite directly.
    // bwrite expects b to be locked. It is locked.
    
    if(copyin(myproc()->pgtbl, (char*)b->data, addr, BSIZE) < 0){
    800045ce:	ffffe097          	auipc	ra,0xffffe
    800045d2:	b40080e7          	jalr	-1216(ra) # 8000210e <myproc>
    800045d6:	40000693          	li	a3,1024
    800045da:	fd043603          	ld	a2,-48(s0)
    800045de:	05848593          	add	a1,s1,88
    800045e2:	6528                	ld	a0,72(a0)
    800045e4:	ffffe097          	auipc	ra,0xffffe
    800045e8:	9ba080e7          	jalr	-1606(ra) # 80001f9e <copyin>
    800045ec:	02054163          	bltz	a0,8000460e <sys_write_block+0x76>
        end_op();
        return -1;
    }
    bwrite(b);
    800045f0:	8526                	mv	a0,s1
    800045f2:	00001097          	auipc	ra,0x1
    800045f6:	c58080e7          	jalr	-936(ra) # 8000524a <bwrite>
    end_op();
    800045fa:	00001097          	auipc	ra,0x1
    800045fe:	19e080e7          	jalr	414(ra) # 80005798 <end_op>
    return 0;
    80004602:	4501                	li	a0,0
}
    80004604:	70a2                	ld	ra,40(sp)
    80004606:	7402                	ld	s0,32(sp)
    80004608:	64e2                	ld	s1,24(sp)
    8000460a:	6145                	add	sp,sp,48
    8000460c:	8082                	ret
        end_op();
    8000460e:	00001097          	auipc	ra,0x1
    80004612:	18a080e7          	jalr	394(ra) # 80005798 <end_op>
        return -1;
    80004616:	557d                	li	a0,-1
    80004618:	b7f5                	j	80004604 <sys_write_block+0x6c>

000000008000461a <sys_read_block>:


uint64 sys_read_block(void) {
    8000461a:	7179                	add	sp,sp,-48
    8000461c:	f406                	sd	ra,40(sp)
    8000461e:	f022                	sd	s0,32(sp)
    80004620:	ec26                	sd	s1,24(sp)
    80004622:	1800                	add	s0,sp,48
    uint64 blockno;
    uint64 addr;
    struct buf *b;
    
    argint(0, &blockno);
    80004624:	fd840593          	add	a1,s0,-40
    80004628:	4501                	li	a0,0
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	fbc080e7          	jalr	-68(ra) # 800035e6 <arg_uint64>
    argaddr(1, &addr);
    80004632:	fd040593          	add	a1,s0,-48
    80004636:	4505                	li	a0,1
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	fae080e7          	jalr	-82(ra) # 800035e6 <arg_uint64>

    printf(COLOR_BLUE"sys_read_block: reading block %d into addr %p\n"COLOR_RESET, (int)blockno, (void*)addr);
    80004640:	fd043603          	ld	a2,-48(s0)
    80004644:	fd842583          	lw	a1,-40(s0)
    80004648:	00004517          	auipc	a0,0x4
    8000464c:	31850513          	add	a0,a0,792 # 80008960 <syscalls+0x1f8>
    80004650:	ffffd097          	auipc	ra,0xffffd
    80004654:	bda080e7          	jalr	-1062(ra) # 8000122a <printf>

    b = bread(ROOTDEV, (uint)blockno);
    80004658:	fd842583          	lw	a1,-40(s0)
    8000465c:	4505                	li	a0,1
    8000465e:	00001097          	auipc	ra,0x1
    80004662:	afa080e7          	jalr	-1286(ra) # 80005158 <bread>
    80004666:	84aa                	mv	s1,a0
    if(copyout(myproc()->pgtbl, addr, (char*)b->data, BSIZE) < 0) {
    80004668:	ffffe097          	auipc	ra,0xffffe
    8000466c:	aa6080e7          	jalr	-1370(ra) # 8000210e <myproc>
    80004670:	40000693          	li	a3,1024
    80004674:	05848613          	add	a2,s1,88
    80004678:	fd043583          	ld	a1,-48(s0)
    8000467c:	6528                	ld	a0,72(a0)
    8000467e:	ffffe097          	auipc	ra,0xffffe
    80004682:	88e080e7          	jalr	-1906(ra) # 80001f0c <copyout>
        brelse(b);
        return 0;
    }
    // Return buffer pointer to user, keeping it locked.
    return (uint64)b;
    80004686:	87a6                	mv	a5,s1
    if(copyout(myproc()->pgtbl, addr, (char*)b->data, BSIZE) < 0) {
    80004688:	00054863          	bltz	a0,80004698 <sys_read_block+0x7e>
}
    8000468c:	853e                	mv	a0,a5
    8000468e:	70a2                	ld	ra,40(sp)
    80004690:	7402                	ld	s0,32(sp)
    80004692:	64e2                	ld	s1,24(sp)
    80004694:	6145                	add	sp,sp,48
    80004696:	8082                	ret
        brelse(b);
    80004698:	8526                	mv	a0,s1
    8000469a:	00001097          	auipc	ra,0x1
    8000469e:	bee080e7          	jalr	-1042(ra) # 80005288 <brelse>
        return 0;
    800046a2:	4781                	li	a5,0
    800046a4:	b7e5                	j	8000468c <sys_read_block+0x72>

00000000800046a6 <sys_release_block>:

uint64 sys_release_block(void) {
    800046a6:	7179                	add	sp,sp,-48
    800046a8:	f406                	sd	ra,40(sp)
    800046aa:	f022                	sd	s0,32(sp)
    800046ac:	ec26                	sd	s1,24(sp)
    800046ae:	1800                	add	s0,sp,48
    uint64 buf_handle;
    argaddr(0, &buf_handle);
    800046b0:	fd840593          	add	a1,s0,-40
    800046b4:	4501                	li	a0,0
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	f30080e7          	jalr	-208(ra) # 800035e6 <arg_uint64>
    
    struct buf *b = (struct buf*)buf_handle;
    800046be:	fd843483          	ld	s1,-40(s0)
    if(b == 0) return -1;
    800046c2:	557d                	li	a0,-1
    800046c4:	c085                	beqz	s1,800046e4 <sys_release_block+0x3e>
    
    printf(COLOR_BLUE"sys_release_block: releasing buf_id=%p\n"COLOR_RESET, (void*)b);
    800046c6:	85a6                	mv	a1,s1
    800046c8:	00004517          	auipc	a0,0x4
    800046cc:	2d050513          	add	a0,a0,720 # 80008998 <syscalls+0x230>
    800046d0:	ffffd097          	auipc	ra,0xffffd
    800046d4:	b5a080e7          	jalr	-1190(ra) # 8000122a <printf>
    brelse(b);
    800046d8:	8526                	mv	a0,s1
    800046da:	00001097          	auipc	ra,0x1
    800046de:	bae080e7          	jalr	-1106(ra) # 80005288 <brelse>
    return 0;
    800046e2:	4501                	li	a0,0
    800046e4:	70a2                	ld	ra,40(sp)
    800046e6:	7402                	ld	s0,32(sp)
    800046e8:	64e2                	ld	s1,24(sp)
    800046ea:	6145                	add	sp,sp,48
    800046ec:	8082                	ret

00000000800046ee <bmap>:
  iput(ip);
}

static uint
bmap(struct inode *ip, uint bn)
{
    800046ee:	7179                	add	sp,sp,-48
    800046f0:	f406                	sd	ra,40(sp)
    800046f2:	f022                	sd	s0,32(sp)
    800046f4:	ec26                	sd	s1,24(sp)
    800046f6:	e84a                	sd	s2,16(sp)
    800046f8:	e44e                	sd	s3,8(sp)
    800046fa:	e052                	sd	s4,0(sp)
    800046fc:	1800                	add	s0,sp,48
    800046fe:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if (bn < NDIRECT)
    80004700:	47ad                	li	a5,11
    80004702:	02b7e863          	bltu	a5,a1,80004732 <bmap+0x44>
  {
    if ((addr = ip->addrs[bn]) == 0)
    80004706:	02059793          	sll	a5,a1,0x20
    8000470a:	01e7d593          	srl	a1,a5,0x1e
    8000470e:	00b504b3          	add	s1,a0,a1
    80004712:	0504a903          	lw	s2,80(s1)
    80004716:	06091e63          	bnez	s2,80004792 <bmap+0xa4>
    {
      addr = balloc(ip->dev);
    8000471a:	4108                	lw	a0,0(a0)
    8000471c:	00002097          	auipc	ra,0x2
    80004720:	fae080e7          	jalr	-82(ra) # 800066ca <balloc>
    80004724:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80004728:	06090563          	beqz	s2,80004792 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000472c:	0524a823          	sw	s2,80(s1)
    80004730:	a08d                	j	80004792 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80004732:	ff45849b          	addw	s1,a1,-12
    80004736:	0004871b          	sext.w	a4,s1

  if (bn < NINDIRECT)
    8000473a:	0ff00793          	li	a5,255
    8000473e:	08e7e563          	bltu	a5,a4,800047c8 <bmap+0xda>
  {
    if ((addr = ip->addrs[NDIRECT]) == 0)
    80004742:	08052903          	lw	s2,128(a0)
    80004746:	00091d63          	bnez	s2,80004760 <bmap+0x72>
    {
      addr = balloc(ip->dev);
    8000474a:	4108                	lw	a0,0(a0)
    8000474c:	00002097          	auipc	ra,0x2
    80004750:	f7e080e7          	jalr	-130(ra) # 800066ca <balloc>
    80004754:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80004758:	02090d63          	beqz	s2,80004792 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000475c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80004760:	85ca                	mv	a1,s2
    80004762:	0009a503          	lw	a0,0(s3)
    80004766:	00001097          	auipc	ra,0x1
    8000476a:	9f2080e7          	jalr	-1550(ra) # 80005158 <bread>
    8000476e:	8a2a                	mv	s4,a0
    a = (uint *)bp->data;
    80004770:	05850793          	add	a5,a0,88
    if ((addr = a[bn]) == 0)
    80004774:	02049713          	sll	a4,s1,0x20
    80004778:	01e75593          	srl	a1,a4,0x1e
    8000477c:	00b784b3          	add	s1,a5,a1
    80004780:	0004a903          	lw	s2,0(s1)
    80004784:	02090063          	beqz	s2,800047a4 <bmap+0xb6>
      {
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80004788:	8552                	mv	a0,s4
    8000478a:	00001097          	auipc	ra,0x1
    8000478e:	afe080e7          	jalr	-1282(ra) # 80005288 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004792:	854a                	mv	a0,s2
    80004794:	70a2                	ld	ra,40(sp)
    80004796:	7402                	ld	s0,32(sp)
    80004798:	64e2                	ld	s1,24(sp)
    8000479a:	6942                	ld	s2,16(sp)
    8000479c:	69a2                	ld	s3,8(sp)
    8000479e:	6a02                	ld	s4,0(sp)
    800047a0:	6145                	add	sp,sp,48
    800047a2:	8082                	ret
      addr = balloc(ip->dev);
    800047a4:	0009a503          	lw	a0,0(s3)
    800047a8:	00002097          	auipc	ra,0x2
    800047ac:	f22080e7          	jalr	-222(ra) # 800066ca <balloc>
    800047b0:	0005091b          	sext.w	s2,a0
      if (addr)
    800047b4:	fc090ae3          	beqz	s2,80004788 <bmap+0x9a>
        a[bn] = addr;
    800047b8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800047bc:	8552                	mv	a0,s4
    800047be:	00001097          	auipc	ra,0x1
    800047c2:	132080e7          	jalr	306(ra) # 800058f0 <log_write>
    800047c6:	b7c9                	j	80004788 <bmap+0x9a>
  panic("bmap: out of range");
    800047c8:	00004517          	auipc	a0,0x4
    800047cc:	20850513          	add	a0,a0,520 # 800089d0 <syscalls+0x268>
    800047d0:	ffffd097          	auipc	ra,0xffffd
    800047d4:	a10080e7          	jalr	-1520(ra) # 800011e0 <panic>

00000000800047d8 <iinit>:
{
    800047d8:	7179                	add	sp,sp,-48
    800047da:	f406                	sd	ra,40(sp)
    800047dc:	f022                	sd	s0,32(sp)
    800047de:	ec26                	sd	s1,24(sp)
    800047e0:	e84a                	sd	s2,16(sp)
    800047e2:	e44e                	sd	s3,8(sp)
    800047e4:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800047e6:	00004597          	auipc	a1,0x4
    800047ea:	20258593          	add	a1,a1,514 # 800089e8 <syscalls+0x280>
    800047ee:	00013517          	auipc	a0,0x13
    800047f2:	8d250513          	add	a0,a0,-1838 # 800170c0 <itable>
    800047f6:	ffffe097          	auipc	ra,0xffffe
    800047fa:	668080e7          	jalr	1640(ra) # 80002e5e <initlock>
  for (i = 0; i < NINODE; i++)
    800047fe:	00013497          	auipc	s1,0x13
    80004802:	8ea48493          	add	s1,s1,-1814 # 800170e8 <itable+0x28>
    80004806:	00014997          	auipc	s3,0x14
    8000480a:	37298993          	add	s3,s3,882 # 80018b78 <bcache+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000480e:	00004917          	auipc	s2,0x4
    80004812:	1e290913          	add	s2,s2,482 # 800089f0 <syscalls+0x288>
    80004816:	85ca                	mv	a1,s2
    80004818:	8526                	mv	a0,s1
    8000481a:	ffffe097          	auipc	ra,0xffffe
    8000481e:	51a080e7          	jalr	1306(ra) # 80002d34 <initsleeplock>
  for (i = 0; i < NINODE; i++)
    80004822:	08848493          	add	s1,s1,136
    80004826:	ff3498e3          	bne	s1,s3,80004816 <iinit+0x3e>
}
    8000482a:	70a2                	ld	ra,40(sp)
    8000482c:	7402                	ld	s0,32(sp)
    8000482e:	64e2                	ld	s1,24(sp)
    80004830:	6942                	ld	s2,16(sp)
    80004832:	69a2                	ld	s3,8(sp)
    80004834:	6145                	add	sp,sp,48
    80004836:	8082                	ret

0000000080004838 <iget>:
{
    80004838:	7179                	add	sp,sp,-48
    8000483a:	f406                	sd	ra,40(sp)
    8000483c:	f022                	sd	s0,32(sp)
    8000483e:	ec26                	sd	s1,24(sp)
    80004840:	e84a                	sd	s2,16(sp)
    80004842:	e44e                	sd	s3,8(sp)
    80004844:	e052                	sd	s4,0(sp)
    80004846:	1800                	add	s0,sp,48
    80004848:	89aa                	mv	s3,a0
    8000484a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000484c:	00013517          	auipc	a0,0x13
    80004850:	87450513          	add	a0,a0,-1932 # 800170c0 <itable>
    80004854:	ffffe097          	auipc	ra,0xffffe
    80004858:	69a080e7          	jalr	1690(ra) # 80002eee <acquire>
  empty = 0;
    8000485c:	4901                	li	s2,0
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    8000485e:	00013497          	auipc	s1,0x13
    80004862:	87a48493          	add	s1,s1,-1926 # 800170d8 <itable+0x18>
    80004866:	00014697          	auipc	a3,0x14
    8000486a:	30268693          	add	a3,a3,770 # 80018b68 <bcache>
    8000486e:	a039                	j	8000487c <iget+0x44>
    if (empty == 0 && ip->ref == 0)
    80004870:	02090b63          	beqz	s2,800048a6 <iget+0x6e>
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80004874:	08848493          	add	s1,s1,136
    80004878:	02d48a63          	beq	s1,a3,800048ac <iget+0x74>
    if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    8000487c:	449c                	lw	a5,8(s1)
    8000487e:	fef059e3          	blez	a5,80004870 <iget+0x38>
    80004882:	4098                	lw	a4,0(s1)
    80004884:	ff3716e3          	bne	a4,s3,80004870 <iget+0x38>
    80004888:	40d8                	lw	a4,4(s1)
    8000488a:	ff4713e3          	bne	a4,s4,80004870 <iget+0x38>
      ip->ref++;
    8000488e:	2785                	addw	a5,a5,1
    80004890:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004892:	00013517          	auipc	a0,0x13
    80004896:	82e50513          	add	a0,a0,-2002 # 800170c0 <itable>
    8000489a:	ffffe097          	auipc	ra,0xffffe
    8000489e:	708080e7          	jalr	1800(ra) # 80002fa2 <release>
      return ip;
    800048a2:	8926                	mv	s2,s1
    800048a4:	a03d                	j	800048d2 <iget+0x9a>
    if (empty == 0 && ip->ref == 0)
    800048a6:	f7f9                	bnez	a5,80004874 <iget+0x3c>
    800048a8:	8926                	mv	s2,s1
    800048aa:	b7e9                	j	80004874 <iget+0x3c>
  if (empty == 0)
    800048ac:	02090c63          	beqz	s2,800048e4 <iget+0xac>
  ip->dev = dev;
    800048b0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800048b4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800048b8:	4785                	li	a5,1
    800048ba:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800048be:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800048c2:	00012517          	auipc	a0,0x12
    800048c6:	7fe50513          	add	a0,a0,2046 # 800170c0 <itable>
    800048ca:	ffffe097          	auipc	ra,0xffffe
    800048ce:	6d8080e7          	jalr	1752(ra) # 80002fa2 <release>
}
    800048d2:	854a                	mv	a0,s2
    800048d4:	70a2                	ld	ra,40(sp)
    800048d6:	7402                	ld	s0,32(sp)
    800048d8:	64e2                	ld	s1,24(sp)
    800048da:	6942                	ld	s2,16(sp)
    800048dc:	69a2                	ld	s3,8(sp)
    800048de:	6a02                	ld	s4,0(sp)
    800048e0:	6145                	add	sp,sp,48
    800048e2:	8082                	ret
    panic("iget: no inodes");
    800048e4:	00004517          	auipc	a0,0x4
    800048e8:	11450513          	add	a0,a0,276 # 800089f8 <syscalls+0x290>
    800048ec:	ffffd097          	auipc	ra,0xffffd
    800048f0:	8f4080e7          	jalr	-1804(ra) # 800011e0 <panic>

00000000800048f4 <ialloc>:
{
    800048f4:	7139                	add	sp,sp,-64
    800048f6:	fc06                	sd	ra,56(sp)
    800048f8:	f822                	sd	s0,48(sp)
    800048fa:	f426                	sd	s1,40(sp)
    800048fc:	f04a                	sd	s2,32(sp)
    800048fe:	ec4e                	sd	s3,24(sp)
    80004900:	e852                	sd	s4,16(sp)
    80004902:	e456                	sd	s5,8(sp)
    80004904:	e05a                	sd	s6,0(sp)
    80004906:	0080                	add	s0,sp,64
  for (inum = 1; inum < sb.ninodes; inum++)
    80004908:	0001e717          	auipc	a4,0x1e
    8000490c:	a2c72703          	lw	a4,-1492(a4) # 80022334 <sb+0xc>
    80004910:	4785                	li	a5,1
    80004912:	04e7f863          	bgeu	a5,a4,80004962 <ialloc+0x6e>
    80004916:	8aaa                	mv	s5,a0
    80004918:	8b2e                	mv	s6,a1
    8000491a:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000491c:	0001ea17          	auipc	s4,0x1e
    80004920:	a0ca0a13          	add	s4,s4,-1524 # 80022328 <sb>
    80004924:	00495593          	srl	a1,s2,0x4
    80004928:	018a2783          	lw	a5,24(s4)
    8000492c:	9dbd                	addw	a1,a1,a5
    8000492e:	8556                	mv	a0,s5
    80004930:	00001097          	auipc	ra,0x1
    80004934:	828080e7          	jalr	-2008(ra) # 80005158 <bread>
    80004938:	84aa                	mv	s1,a0
    dip = (struct dinode *)bp->data + inum % IPB;
    8000493a:	05850993          	add	s3,a0,88
    8000493e:	00f97793          	and	a5,s2,15
    80004942:	079a                	sll	a5,a5,0x6
    80004944:	99be                	add	s3,s3,a5
    if (dip->type == 0)
    80004946:	00099783          	lh	a5,0(s3)
    8000494a:	cf9d                	beqz	a5,80004988 <ialloc+0x94>
    brelse(bp);
    8000494c:	00001097          	auipc	ra,0x1
    80004950:	93c080e7          	jalr	-1732(ra) # 80005288 <brelse>
  for (inum = 1; inum < sb.ninodes; inum++)
    80004954:	0905                	add	s2,s2,1
    80004956:	00ca2703          	lw	a4,12(s4)
    8000495a:	0009079b          	sext.w	a5,s2
    8000495e:	fce7e3e3          	bltu	a5,a4,80004924 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80004962:	00004517          	auipc	a0,0x4
    80004966:	0a650513          	add	a0,a0,166 # 80008a08 <syscalls+0x2a0>
    8000496a:	ffffd097          	auipc	ra,0xffffd
    8000496e:	8c0080e7          	jalr	-1856(ra) # 8000122a <printf>
  return 0;
    80004972:	4501                	li	a0,0
}
    80004974:	70e2                	ld	ra,56(sp)
    80004976:	7442                	ld	s0,48(sp)
    80004978:	74a2                	ld	s1,40(sp)
    8000497a:	7902                	ld	s2,32(sp)
    8000497c:	69e2                	ld	s3,24(sp)
    8000497e:	6a42                	ld	s4,16(sp)
    80004980:	6aa2                	ld	s5,8(sp)
    80004982:	6b02                	ld	s6,0(sp)
    80004984:	6121                	add	sp,sp,64
    80004986:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004988:	04000613          	li	a2,64
    8000498c:	4581                	li	a1,0
    8000498e:	854e                	mv	a0,s3
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	608080e7          	jalr	1544(ra) # 80000f98 <memset>
      dip->type = type;
    80004998:	01699023          	sh	s6,0(s3)
      log_write(bp);
    8000499c:	8526                	mv	a0,s1
    8000499e:	00001097          	auipc	ra,0x1
    800049a2:	f52080e7          	jalr	-174(ra) # 800058f0 <log_write>
      brelse(bp);
    800049a6:	8526                	mv	a0,s1
    800049a8:	00001097          	auipc	ra,0x1
    800049ac:	8e0080e7          	jalr	-1824(ra) # 80005288 <brelse>
      return iget(dev, inum);
    800049b0:	0009059b          	sext.w	a1,s2
    800049b4:	8556                	mv	a0,s5
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	e82080e7          	jalr	-382(ra) # 80004838 <iget>
    800049be:	bf5d                	j	80004974 <ialloc+0x80>

00000000800049c0 <iupdate>:
{
    800049c0:	1101                	add	sp,sp,-32
    800049c2:	ec06                	sd	ra,24(sp)
    800049c4:	e822                	sd	s0,16(sp)
    800049c6:	e426                	sd	s1,8(sp)
    800049c8:	e04a                	sd	s2,0(sp)
    800049ca:	1000                	add	s0,sp,32
    800049cc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800049ce:	415c                	lw	a5,4(a0)
    800049d0:	0047d79b          	srlw	a5,a5,0x4
    800049d4:	0001e597          	auipc	a1,0x1e
    800049d8:	96c5a583          	lw	a1,-1684(a1) # 80022340 <sb+0x18>
    800049dc:	9dbd                	addw	a1,a1,a5
    800049de:	4108                	lw	a0,0(a0)
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	778080e7          	jalr	1912(ra) # 80005158 <bread>
    800049e8:	892a                	mv	s2,a0
  dip = (struct dinode *)bp->data + ip->inum % IPB;
    800049ea:	05850793          	add	a5,a0,88
    800049ee:	40d8                	lw	a4,4(s1)
    800049f0:	8b3d                	and	a4,a4,15
    800049f2:	071a                	sll	a4,a4,0x6
    800049f4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800049f6:	04449703          	lh	a4,68(s1)
    800049fa:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800049fe:	04649703          	lh	a4,70(s1)
    80004a02:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80004a06:	04849703          	lh	a4,72(s1)
    80004a0a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80004a0e:	04a49703          	lh	a4,74(s1)
    80004a12:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80004a16:	44f8                	lw	a4,76(s1)
    80004a18:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004a1a:	03400613          	li	a2,52
    80004a1e:	05048593          	add	a1,s1,80
    80004a22:	00c78513          	add	a0,a5,12
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	5ce080e7          	jalr	1486(ra) # 80000ff4 <memmove>
  log_write(bp);
    80004a2e:	854a                	mv	a0,s2
    80004a30:	00001097          	auipc	ra,0x1
    80004a34:	ec0080e7          	jalr	-320(ra) # 800058f0 <log_write>
  brelse(bp);
    80004a38:	854a                	mv	a0,s2
    80004a3a:	00001097          	auipc	ra,0x1
    80004a3e:	84e080e7          	jalr	-1970(ra) # 80005288 <brelse>
}
    80004a42:	60e2                	ld	ra,24(sp)
    80004a44:	6442                	ld	s0,16(sp)
    80004a46:	64a2                	ld	s1,8(sp)
    80004a48:	6902                	ld	s2,0(sp)
    80004a4a:	6105                	add	sp,sp,32
    80004a4c:	8082                	ret

0000000080004a4e <idup>:
{
    80004a4e:	1101                	add	sp,sp,-32
    80004a50:	ec06                	sd	ra,24(sp)
    80004a52:	e822                	sd	s0,16(sp)
    80004a54:	e426                	sd	s1,8(sp)
    80004a56:	1000                	add	s0,sp,32
    80004a58:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004a5a:	00012517          	auipc	a0,0x12
    80004a5e:	66650513          	add	a0,a0,1638 # 800170c0 <itable>
    80004a62:	ffffe097          	auipc	ra,0xffffe
    80004a66:	48c080e7          	jalr	1164(ra) # 80002eee <acquire>
  ip->ref++;
    80004a6a:	449c                	lw	a5,8(s1)
    80004a6c:	2785                	addw	a5,a5,1
    80004a6e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004a70:	00012517          	auipc	a0,0x12
    80004a74:	65050513          	add	a0,a0,1616 # 800170c0 <itable>
    80004a78:	ffffe097          	auipc	ra,0xffffe
    80004a7c:	52a080e7          	jalr	1322(ra) # 80002fa2 <release>
}
    80004a80:	8526                	mv	a0,s1
    80004a82:	60e2                	ld	ra,24(sp)
    80004a84:	6442                	ld	s0,16(sp)
    80004a86:	64a2                	ld	s1,8(sp)
    80004a88:	6105                	add	sp,sp,32
    80004a8a:	8082                	ret

0000000080004a8c <ilock>:
{
    80004a8c:	1101                	add	sp,sp,-32
    80004a8e:	ec06                	sd	ra,24(sp)
    80004a90:	e822                	sd	s0,16(sp)
    80004a92:	e426                	sd	s1,8(sp)
    80004a94:	e04a                	sd	s2,0(sp)
    80004a96:	1000                	add	s0,sp,32
  if (ip == 0 || ip->ref < 1)
    80004a98:	c115                	beqz	a0,80004abc <ilock+0x30>
    80004a9a:	84aa                	mv	s1,a0
    80004a9c:	451c                	lw	a5,8(a0)
    80004a9e:	00f05f63          	blez	a5,80004abc <ilock+0x30>
  acquiresleep(&ip->lock);
    80004aa2:	0541                	add	a0,a0,16
    80004aa4:	ffffe097          	auipc	ra,0xffffe
    80004aa8:	2ca080e7          	jalr	714(ra) # 80002d6e <acquiresleep>
  if (ip->valid == 0)
    80004aac:	40bc                	lw	a5,64(s1)
    80004aae:	cf99                	beqz	a5,80004acc <ilock+0x40>
}
    80004ab0:	60e2                	ld	ra,24(sp)
    80004ab2:	6442                	ld	s0,16(sp)
    80004ab4:	64a2                	ld	s1,8(sp)
    80004ab6:	6902                	ld	s2,0(sp)
    80004ab8:	6105                	add	sp,sp,32
    80004aba:	8082                	ret
    panic("ilock");
    80004abc:	00004517          	auipc	a0,0x4
    80004ac0:	f6450513          	add	a0,a0,-156 # 80008a20 <syscalls+0x2b8>
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	71c080e7          	jalr	1820(ra) # 800011e0 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004acc:	40dc                	lw	a5,4(s1)
    80004ace:	0047d79b          	srlw	a5,a5,0x4
    80004ad2:	0001e597          	auipc	a1,0x1e
    80004ad6:	86e5a583          	lw	a1,-1938(a1) # 80022340 <sb+0x18>
    80004ada:	9dbd                	addw	a1,a1,a5
    80004adc:	4088                	lw	a0,0(s1)
    80004ade:	00000097          	auipc	ra,0x0
    80004ae2:	67a080e7          	jalr	1658(ra) # 80005158 <bread>
    80004ae6:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + ip->inum % IPB;
    80004ae8:	05850593          	add	a1,a0,88
    80004aec:	40dc                	lw	a5,4(s1)
    80004aee:	8bbd                	and	a5,a5,15
    80004af0:	079a                	sll	a5,a5,0x6
    80004af2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004af4:	00059783          	lh	a5,0(a1)
    80004af8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004afc:	00259783          	lh	a5,2(a1)
    80004b00:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004b04:	00459783          	lh	a5,4(a1)
    80004b08:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004b0c:	00659783          	lh	a5,6(a1)
    80004b10:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004b14:	459c                	lw	a5,8(a1)
    80004b16:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004b18:	03400613          	li	a2,52
    80004b1c:	05b1                	add	a1,a1,12
    80004b1e:	05048513          	add	a0,s1,80
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	4d2080e7          	jalr	1234(ra) # 80000ff4 <memmove>
    brelse(bp);
    80004b2a:	854a                	mv	a0,s2
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	75c080e7          	jalr	1884(ra) # 80005288 <brelse>
    ip->valid = 1;
    80004b34:	4785                	li	a5,1
    80004b36:	c0bc                	sw	a5,64(s1)
    if (ip->type == 0)
    80004b38:	04449783          	lh	a5,68(s1)
    80004b3c:	fbb5                	bnez	a5,80004ab0 <ilock+0x24>
      panic("ilock: no type");
    80004b3e:	00004517          	auipc	a0,0x4
    80004b42:	eea50513          	add	a0,a0,-278 # 80008a28 <syscalls+0x2c0>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	69a080e7          	jalr	1690(ra) # 800011e0 <panic>

0000000080004b4e <iunlock>:
{
    80004b4e:	1101                	add	sp,sp,-32
    80004b50:	ec06                	sd	ra,24(sp)
    80004b52:	e822                	sd	s0,16(sp)
    80004b54:	e426                	sd	s1,8(sp)
    80004b56:	e04a                	sd	s2,0(sp)
    80004b58:	1000                	add	s0,sp,32
  if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004b5a:	c905                	beqz	a0,80004b8a <iunlock+0x3c>
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	01050913          	add	s2,a0,16
    80004b62:	854a                	mv	a0,s2
    80004b64:	ffffe097          	auipc	ra,0xffffe
    80004b68:	2a4080e7          	jalr	676(ra) # 80002e08 <holdingsleep>
    80004b6c:	cd19                	beqz	a0,80004b8a <iunlock+0x3c>
    80004b6e:	449c                	lw	a5,8(s1)
    80004b70:	00f05d63          	blez	a5,80004b8a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004b74:	854a                	mv	a0,s2
    80004b76:	ffffe097          	auipc	ra,0xffffe
    80004b7a:	24e080e7          	jalr	590(ra) # 80002dc4 <releasesleep>
}
    80004b7e:	60e2                	ld	ra,24(sp)
    80004b80:	6442                	ld	s0,16(sp)
    80004b82:	64a2                	ld	s1,8(sp)
    80004b84:	6902                	ld	s2,0(sp)
    80004b86:	6105                	add	sp,sp,32
    80004b88:	8082                	ret
    panic("iunlock");
    80004b8a:	00004517          	auipc	a0,0x4
    80004b8e:	eae50513          	add	a0,a0,-338 # 80008a38 <syscalls+0x2d0>
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	64e080e7          	jalr	1614(ra) # 800011e0 <panic>

0000000080004b9a <itrunc>:

void itrunc(struct inode *ip)
{
    80004b9a:	7179                	add	sp,sp,-48
    80004b9c:	f406                	sd	ra,40(sp)
    80004b9e:	f022                	sd	s0,32(sp)
    80004ba0:	ec26                	sd	s1,24(sp)
    80004ba2:	e84a                	sd	s2,16(sp)
    80004ba4:	e44e                	sd	s3,8(sp)
    80004ba6:	e052                	sd	s4,0(sp)
    80004ba8:	1800                	add	s0,sp,48
    80004baa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for (i = 0; i < NDIRECT; i++)
    80004bac:	05050493          	add	s1,a0,80
    80004bb0:	08050913          	add	s2,a0,128
    80004bb4:	a021                	j	80004bbc <itrunc+0x22>
    80004bb6:	0491                	add	s1,s1,4
    80004bb8:	01248d63          	beq	s1,s2,80004bd2 <itrunc+0x38>
  {
    if (ip->addrs[i])
    80004bbc:	408c                	lw	a1,0(s1)
    80004bbe:	dde5                	beqz	a1,80004bb6 <itrunc+0x1c>
    {
      bfree(ip->dev, ip->addrs[i]);
    80004bc0:	0009a503          	lw	a0,0(s3)
    80004bc4:	00002097          	auipc	ra,0x2
    80004bc8:	c38080e7          	jalr	-968(ra) # 800067fc <bfree>
      ip->addrs[i] = 0;
    80004bcc:	0004a023          	sw	zero,0(s1)
    80004bd0:	b7dd                	j	80004bb6 <itrunc+0x1c>
    }
  }

  if (ip->addrs[NDIRECT])
    80004bd2:	0809a583          	lw	a1,128(s3)
    80004bd6:	e185                	bnez	a1,80004bf6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004bd8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004bdc:	854e                	mv	a0,s3
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	de2080e7          	jalr	-542(ra) # 800049c0 <iupdate>
}
    80004be6:	70a2                	ld	ra,40(sp)
    80004be8:	7402                	ld	s0,32(sp)
    80004bea:	64e2                	ld	s1,24(sp)
    80004bec:	6942                	ld	s2,16(sp)
    80004bee:	69a2                	ld	s3,8(sp)
    80004bf0:	6a02                	ld	s4,0(sp)
    80004bf2:	6145                	add	sp,sp,48
    80004bf4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004bf6:	0009a503          	lw	a0,0(s3)
    80004bfa:	00000097          	auipc	ra,0x0
    80004bfe:	55e080e7          	jalr	1374(ra) # 80005158 <bread>
    80004c02:	8a2a                	mv	s4,a0
    for (j = 0; j < NINDIRECT; j++)
    80004c04:	05850493          	add	s1,a0,88
    80004c08:	45850913          	add	s2,a0,1112
    80004c0c:	a021                	j	80004c14 <itrunc+0x7a>
    80004c0e:	0491                	add	s1,s1,4
    80004c10:	01248b63          	beq	s1,s2,80004c26 <itrunc+0x8c>
      if (a[j])
    80004c14:	408c                	lw	a1,0(s1)
    80004c16:	dde5                	beqz	a1,80004c0e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004c18:	0009a503          	lw	a0,0(s3)
    80004c1c:	00002097          	auipc	ra,0x2
    80004c20:	be0080e7          	jalr	-1056(ra) # 800067fc <bfree>
    80004c24:	b7ed                	j	80004c0e <itrunc+0x74>
    brelse(bp);
    80004c26:	8552                	mv	a0,s4
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	660080e7          	jalr	1632(ra) # 80005288 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004c30:	0809a583          	lw	a1,128(s3)
    80004c34:	0009a503          	lw	a0,0(s3)
    80004c38:	00002097          	auipc	ra,0x2
    80004c3c:	bc4080e7          	jalr	-1084(ra) # 800067fc <bfree>
    ip->addrs[NDIRECT] = 0;
    80004c40:	0809a023          	sw	zero,128(s3)
    80004c44:	bf51                	j	80004bd8 <itrunc+0x3e>

0000000080004c46 <iput>:
{
    80004c46:	1101                	add	sp,sp,-32
    80004c48:	ec06                	sd	ra,24(sp)
    80004c4a:	e822                	sd	s0,16(sp)
    80004c4c:	e426                	sd	s1,8(sp)
    80004c4e:	e04a                	sd	s2,0(sp)
    80004c50:	1000                	add	s0,sp,32
    80004c52:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004c54:	00012517          	auipc	a0,0x12
    80004c58:	46c50513          	add	a0,a0,1132 # 800170c0 <itable>
    80004c5c:	ffffe097          	auipc	ra,0xffffe
    80004c60:	292080e7          	jalr	658(ra) # 80002eee <acquire>
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80004c64:	4498                	lw	a4,8(s1)
    80004c66:	4785                	li	a5,1
    80004c68:	02f70363          	beq	a4,a5,80004c8e <iput+0x48>
  ip->ref--;
    80004c6c:	449c                	lw	a5,8(s1)
    80004c6e:	37fd                	addw	a5,a5,-1
    80004c70:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004c72:	00012517          	auipc	a0,0x12
    80004c76:	44e50513          	add	a0,a0,1102 # 800170c0 <itable>
    80004c7a:	ffffe097          	auipc	ra,0xffffe
    80004c7e:	328080e7          	jalr	808(ra) # 80002fa2 <release>
}
    80004c82:	60e2                	ld	ra,24(sp)
    80004c84:	6442                	ld	s0,16(sp)
    80004c86:	64a2                	ld	s1,8(sp)
    80004c88:	6902                	ld	s2,0(sp)
    80004c8a:	6105                	add	sp,sp,32
    80004c8c:	8082                	ret
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80004c8e:	40bc                	lw	a5,64(s1)
    80004c90:	dff1                	beqz	a5,80004c6c <iput+0x26>
    80004c92:	04a49783          	lh	a5,74(s1)
    80004c96:	fbf9                	bnez	a5,80004c6c <iput+0x26>
    acquiresleep(&ip->lock);
    80004c98:	01048913          	add	s2,s1,16
    80004c9c:	854a                	mv	a0,s2
    80004c9e:	ffffe097          	auipc	ra,0xffffe
    80004ca2:	0d0080e7          	jalr	208(ra) # 80002d6e <acquiresleep>
    release(&itable.lock);
    80004ca6:	00012517          	auipc	a0,0x12
    80004caa:	41a50513          	add	a0,a0,1050 # 800170c0 <itable>
    80004cae:	ffffe097          	auipc	ra,0xffffe
    80004cb2:	2f4080e7          	jalr	756(ra) # 80002fa2 <release>
    itrunc(ip);
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	00000097          	auipc	ra,0x0
    80004cbc:	ee2080e7          	jalr	-286(ra) # 80004b9a <itrunc>
    ip->type = 0;
    80004cc0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	00000097          	auipc	ra,0x0
    80004cca:	cfa080e7          	jalr	-774(ra) # 800049c0 <iupdate>
    ip->valid = 0;
    80004cce:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004cd2:	854a                	mv	a0,s2
    80004cd4:	ffffe097          	auipc	ra,0xffffe
    80004cd8:	0f0080e7          	jalr	240(ra) # 80002dc4 <releasesleep>
    acquire(&itable.lock);
    80004cdc:	00012517          	auipc	a0,0x12
    80004ce0:	3e450513          	add	a0,a0,996 # 800170c0 <itable>
    80004ce4:	ffffe097          	auipc	ra,0xffffe
    80004ce8:	20a080e7          	jalr	522(ra) # 80002eee <acquire>
    80004cec:	b741                	j	80004c6c <iput+0x26>

0000000080004cee <iunlockput>:
{
    80004cee:	1101                	add	sp,sp,-32
    80004cf0:	ec06                	sd	ra,24(sp)
    80004cf2:	e822                	sd	s0,16(sp)
    80004cf4:	e426                	sd	s1,8(sp)
    80004cf6:	1000                	add	s0,sp,32
    80004cf8:	84aa                	mv	s1,a0
  iunlock(ip);
    80004cfa:	00000097          	auipc	ra,0x0
    80004cfe:	e54080e7          	jalr	-428(ra) # 80004b4e <iunlock>
  iput(ip);
    80004d02:	8526                	mv	a0,s1
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	f42080e7          	jalr	-190(ra) # 80004c46 <iput>
}
    80004d0c:	60e2                	ld	ra,24(sp)
    80004d0e:	6442                	ld	s0,16(sp)
    80004d10:	64a2                	ld	s1,8(sp)
    80004d12:	6105                	add	sp,sp,32
    80004d14:	8082                	ret

0000000080004d16 <stati>:

void stati(struct inode *ip, struct stat *st)
{
    80004d16:	1141                	add	sp,sp,-16
    80004d18:	e422                	sd	s0,8(sp)
    80004d1a:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80004d1c:	411c                	lw	a5,0(a0)
    80004d1e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004d20:	415c                	lw	a5,4(a0)
    80004d22:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004d24:	04451783          	lh	a5,68(a0)
    80004d28:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004d2c:	04a51783          	lh	a5,74(a0)
    80004d30:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004d34:	04c56783          	lwu	a5,76(a0)
    80004d38:	e99c                	sd	a5,16(a1)
}
    80004d3a:	6422                	ld	s0,8(sp)
    80004d3c:	0141                	add	sp,sp,16
    80004d3e:	8082                	ret

0000000080004d40 <readi>:
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80004d40:	457c                	lw	a5,76(a0)
    80004d42:	0ed7e963          	bltu	a5,a3,80004e34 <readi+0xf4>
{
    80004d46:	7159                	add	sp,sp,-112
    80004d48:	f486                	sd	ra,104(sp)
    80004d4a:	f0a2                	sd	s0,96(sp)
    80004d4c:	eca6                	sd	s1,88(sp)
    80004d4e:	e8ca                	sd	s2,80(sp)
    80004d50:	e4ce                	sd	s3,72(sp)
    80004d52:	e0d2                	sd	s4,64(sp)
    80004d54:	fc56                	sd	s5,56(sp)
    80004d56:	f85a                	sd	s6,48(sp)
    80004d58:	f45e                	sd	s7,40(sp)
    80004d5a:	f062                	sd	s8,32(sp)
    80004d5c:	ec66                	sd	s9,24(sp)
    80004d5e:	e86a                	sd	s10,16(sp)
    80004d60:	e46e                	sd	s11,8(sp)
    80004d62:	1880                	add	s0,sp,112
    80004d64:	8b2a                	mv	s6,a0
    80004d66:	8bae                	mv	s7,a1
    80004d68:	8a32                	mv	s4,a2
    80004d6a:	84b6                	mv	s1,a3
    80004d6c:	8aba                	mv	s5,a4
  if (off > ip->size || off + n < off)
    80004d6e:	9f35                	addw	a4,a4,a3
    return 0;
    80004d70:	4501                	li	a0,0
  if (off > ip->size || off + n < off)
    80004d72:	0ad76063          	bltu	a4,a3,80004e12 <readi+0xd2>
  if (off + n > ip->size)
    80004d76:	00e7f463          	bgeu	a5,a4,80004d7e <readi+0x3e>
    n = ip->size - off;
    80004d7a:	40d78abb          	subw	s5,a5,a3

  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80004d7e:	0a0a8963          	beqz	s5,80004e30 <readi+0xf0>
    80004d82:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80004d84:	40000c93          	li	s9,1024
    if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80004d88:	5c7d                	li	s8,-1
    80004d8a:	a82d                	j	80004dc4 <readi+0x84>
    80004d8c:	020d1d93          	sll	s11,s10,0x20
    80004d90:	020ddd93          	srl	s11,s11,0x20
    80004d94:	05890613          	add	a2,s2,88
    80004d98:	86ee                	mv	a3,s11
    80004d9a:	963a                	add	a2,a2,a4
    80004d9c:	85d2                	mv	a1,s4
    80004d9e:	855e                	mv	a0,s7
    80004da0:	ffffe097          	auipc	ra,0xffffe
    80004da4:	ee8080e7          	jalr	-280(ra) # 80002c88 <either_copyout>
    80004da8:	05850d63          	beq	a0,s8,80004e02 <readi+0xc2>
    {
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004dac:	854a                	mv	a0,s2
    80004dae:	00000097          	auipc	ra,0x0
    80004db2:	4da080e7          	jalr	1242(ra) # 80005288 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80004db6:	013d09bb          	addw	s3,s10,s3
    80004dba:	009d04bb          	addw	s1,s10,s1
    80004dbe:	9a6e                	add	s4,s4,s11
    80004dc0:	0559f763          	bgeu	s3,s5,80004e0e <readi+0xce>
    uint addr = bmap(ip, off / BSIZE);
    80004dc4:	00a4d59b          	srlw	a1,s1,0xa
    80004dc8:	855a                	mv	a0,s6
    80004dca:	00000097          	auipc	ra,0x0
    80004dce:	924080e7          	jalr	-1756(ra) # 800046ee <bmap>
    80004dd2:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80004dd6:	cd85                	beqz	a1,80004e0e <readi+0xce>
    bp = bread(ip->dev, addr);
    80004dd8:	000b2503          	lw	a0,0(s6)
    80004ddc:	00000097          	auipc	ra,0x0
    80004de0:	37c080e7          	jalr	892(ra) # 80005158 <bread>
    80004de4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80004de6:	3ff4f713          	and	a4,s1,1023
    80004dea:	40ec87bb          	subw	a5,s9,a4
    80004dee:	413a86bb          	subw	a3,s5,s3
    80004df2:	8d3e                	mv	s10,a5
    80004df4:	2781                	sext.w	a5,a5
    80004df6:	0006861b          	sext.w	a2,a3
    80004dfa:	f8f679e3          	bgeu	a2,a5,80004d8c <readi+0x4c>
    80004dfe:	8d36                	mv	s10,a3
    80004e00:	b771                	j	80004d8c <readi+0x4c>
      brelse(bp);
    80004e02:	854a                	mv	a0,s2
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	484080e7          	jalr	1156(ra) # 80005288 <brelse>
      tot = -1;
    80004e0c:	59fd                	li	s3,-1
  }
  return tot;
    80004e0e:	0009851b          	sext.w	a0,s3
}
    80004e12:	70a6                	ld	ra,104(sp)
    80004e14:	7406                	ld	s0,96(sp)
    80004e16:	64e6                	ld	s1,88(sp)
    80004e18:	6946                	ld	s2,80(sp)
    80004e1a:	69a6                	ld	s3,72(sp)
    80004e1c:	6a06                	ld	s4,64(sp)
    80004e1e:	7ae2                	ld	s5,56(sp)
    80004e20:	7b42                	ld	s6,48(sp)
    80004e22:	7ba2                	ld	s7,40(sp)
    80004e24:	7c02                	ld	s8,32(sp)
    80004e26:	6ce2                	ld	s9,24(sp)
    80004e28:	6d42                	ld	s10,16(sp)
    80004e2a:	6da2                	ld	s11,8(sp)
    80004e2c:	6165                	add	sp,sp,112
    80004e2e:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80004e30:	89d6                	mv	s3,s5
    80004e32:	bff1                	j	80004e0e <readi+0xce>
    return 0;
    80004e34:	4501                	li	a0,0
}
    80004e36:	8082                	ret

0000000080004e38 <writei>:
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80004e38:	457c                	lw	a5,76(a0)
    80004e3a:	10d7e863          	bltu	a5,a3,80004f4a <writei+0x112>
{
    80004e3e:	7159                	add	sp,sp,-112
    80004e40:	f486                	sd	ra,104(sp)
    80004e42:	f0a2                	sd	s0,96(sp)
    80004e44:	eca6                	sd	s1,88(sp)
    80004e46:	e8ca                	sd	s2,80(sp)
    80004e48:	e4ce                	sd	s3,72(sp)
    80004e4a:	e0d2                	sd	s4,64(sp)
    80004e4c:	fc56                	sd	s5,56(sp)
    80004e4e:	f85a                	sd	s6,48(sp)
    80004e50:	f45e                	sd	s7,40(sp)
    80004e52:	f062                	sd	s8,32(sp)
    80004e54:	ec66                	sd	s9,24(sp)
    80004e56:	e86a                	sd	s10,16(sp)
    80004e58:	e46e                	sd	s11,8(sp)
    80004e5a:	1880                	add	s0,sp,112
    80004e5c:	8aaa                	mv	s5,a0
    80004e5e:	8bae                	mv	s7,a1
    80004e60:	8a32                	mv	s4,a2
    80004e62:	8936                	mv	s2,a3
    80004e64:	8b3a                	mv	s6,a4
  if (off > ip->size || off + n < off)
    80004e66:	00e687bb          	addw	a5,a3,a4
    80004e6a:	0ed7e263          	bltu	a5,a3,80004f4e <writei+0x116>
    return -1;
  if (off + n > MAXFILE * BSIZE)
    80004e6e:	00043737          	lui	a4,0x43
    80004e72:	0ef76063          	bltu	a4,a5,80004f52 <writei+0x11a>
    return -1;

  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80004e76:	0c0b0863          	beqz	s6,80004f46 <writei+0x10e>
    80004e7a:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    80004e7c:	40000c93          	li	s9,1024
    if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    80004e80:	5c7d                	li	s8,-1
    80004e82:	a091                	j	80004ec6 <writei+0x8e>
    80004e84:	020d1d93          	sll	s11,s10,0x20
    80004e88:	020ddd93          	srl	s11,s11,0x20
    80004e8c:	05848513          	add	a0,s1,88
    80004e90:	86ee                	mv	a3,s11
    80004e92:	8652                	mv	a2,s4
    80004e94:	85de                	mv	a1,s7
    80004e96:	953a                	add	a0,a0,a4
    80004e98:	ffffe097          	auipc	ra,0xffffe
    80004e9c:	e46080e7          	jalr	-442(ra) # 80002cde <either_copyin>
    80004ea0:	07850263          	beq	a0,s8,80004f04 <writei+0xcc>
    {
      brelse(bp);
      break;
    }
    log_write(bp);
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	00001097          	auipc	ra,0x1
    80004eaa:	a4a080e7          	jalr	-1462(ra) # 800058f0 <log_write>
    brelse(bp);
    80004eae:	8526                	mv	a0,s1
    80004eb0:	00000097          	auipc	ra,0x0
    80004eb4:	3d8080e7          	jalr	984(ra) # 80005288 <brelse>
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80004eb8:	013d09bb          	addw	s3,s10,s3
    80004ebc:	012d093b          	addw	s2,s10,s2
    80004ec0:	9a6e                	add	s4,s4,s11
    80004ec2:	0569f663          	bgeu	s3,s6,80004f0e <writei+0xd6>
    uint addr = bmap(ip, off / BSIZE);
    80004ec6:	00a9559b          	srlw	a1,s2,0xa
    80004eca:	8556                	mv	a0,s5
    80004ecc:	00000097          	auipc	ra,0x0
    80004ed0:	822080e7          	jalr	-2014(ra) # 800046ee <bmap>
    80004ed4:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80004ed8:	c99d                	beqz	a1,80004f0e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004eda:	000aa503          	lw	a0,0(s5)
    80004ede:	00000097          	auipc	ra,0x0
    80004ee2:	27a080e7          	jalr	634(ra) # 80005158 <bread>
    80004ee6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80004ee8:	3ff97713          	and	a4,s2,1023
    80004eec:	40ec87bb          	subw	a5,s9,a4
    80004ef0:	413b06bb          	subw	a3,s6,s3
    80004ef4:	8d3e                	mv	s10,a5
    80004ef6:	2781                	sext.w	a5,a5
    80004ef8:	0006861b          	sext.w	a2,a3
    80004efc:	f8f674e3          	bgeu	a2,a5,80004e84 <writei+0x4c>
    80004f00:	8d36                	mv	s10,a3
    80004f02:	b749                	j	80004e84 <writei+0x4c>
      brelse(bp);
    80004f04:	8526                	mv	a0,s1
    80004f06:	00000097          	auipc	ra,0x0
    80004f0a:	382080e7          	jalr	898(ra) # 80005288 <brelse>
  }

  if (off > ip->size)
    80004f0e:	04caa783          	lw	a5,76(s5)
    80004f12:	0127f463          	bgeu	a5,s2,80004f1a <writei+0xe2>
    ip->size = off;
    80004f16:	052aa623          	sw	s2,76(s5)

  iupdate(ip);
    80004f1a:	8556                	mv	a0,s5
    80004f1c:	00000097          	auipc	ra,0x0
    80004f20:	aa4080e7          	jalr	-1372(ra) # 800049c0 <iupdate>

  return tot;
    80004f24:	0009851b          	sext.w	a0,s3
}
    80004f28:	70a6                	ld	ra,104(sp)
    80004f2a:	7406                	ld	s0,96(sp)
    80004f2c:	64e6                	ld	s1,88(sp)
    80004f2e:	6946                	ld	s2,80(sp)
    80004f30:	69a6                	ld	s3,72(sp)
    80004f32:	6a06                	ld	s4,64(sp)
    80004f34:	7ae2                	ld	s5,56(sp)
    80004f36:	7b42                	ld	s6,48(sp)
    80004f38:	7ba2                	ld	s7,40(sp)
    80004f3a:	7c02                	ld	s8,32(sp)
    80004f3c:	6ce2                	ld	s9,24(sp)
    80004f3e:	6d42                	ld	s10,16(sp)
    80004f40:	6da2                	ld	s11,8(sp)
    80004f42:	6165                	add	sp,sp,112
    80004f44:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80004f46:	89da                	mv	s3,s6
    80004f48:	bfc9                	j	80004f1a <writei+0xe2>
    return -1;
    80004f4a:	557d                	li	a0,-1
}
    80004f4c:	8082                	ret
    return -1;
    80004f4e:	557d                	li	a0,-1
    80004f50:	bfe1                	j	80004f28 <writei+0xf0>
    return -1;
    80004f52:	557d                	li	a0,-1
    80004f54:	bfd1                	j	80004f28 <writei+0xf0>

0000000080004f56 <inode_print>:

char *inode_types[] = { "unused", "dir", "file", "dev" };

void inode_print(struct inode* ip)
{
    80004f56:	7179                	add	sp,sp,-48
    80004f58:	f406                	sd	ra,40(sp)
    80004f5a:	f022                	sd	s0,32(sp)
    80004f5c:	ec26                	sd	s1,24(sp)
    80004f5e:	e84a                	sd	s2,16(sp)
    80004f60:	e44e                	sd	s3,8(sp)
    80004f62:	1800                	add	s0,sp,48
    80004f64:	892a                	mv	s2,a0
    assert(holdingsleep(&ip->lock), "inode_print: lk");
    80004f66:	0541                	add	a0,a0,16
    80004f68:	ffffe097          	auipc	ra,0xffffe
    80004f6c:	ea0080e7          	jalr	-352(ra) # 80002e08 <holdingsleep>
    80004f70:	00004597          	auipc	a1,0x4
    80004f74:	ad058593          	add	a1,a1,-1328 # 80008a40 <syscalls+0x2d8>
    80004f78:	00002097          	auipc	ra,0x2
    80004f7c:	900080e7          	jalr	-1792(ra) # 80006878 <assert>

    printf("\ninode information:\n");
    80004f80:	00004517          	auipc	a0,0x4
    80004f84:	ad050513          	add	a0,a0,-1328 # 80008a50 <syscalls+0x2e8>
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	2a2080e7          	jalr	674(ra) # 8000122a <printf>
    printf("num = %d, ref = %d, valid = %d\n", ip->inum, ip->ref, ip->valid);
    80004f90:	04092683          	lw	a3,64(s2)
    80004f94:	00892603          	lw	a2,8(s2)
    80004f98:	00492583          	lw	a1,4(s2)
    80004f9c:	00004517          	auipc	a0,0x4
    80004fa0:	acc50513          	add	a0,a0,-1332 # 80008a68 <syscalls+0x300>
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	286080e7          	jalr	646(ra) # 8000122a <printf>
    printf("type = %s, major = %d, minor = %d, nlink = %d\n", inode_types[ip->type], ip->major, ip->minor, ip->nlink);
    80004fac:	04491703          	lh	a4,68(s2)
    80004fb0:	070e                	sll	a4,a4,0x3
    80004fb2:	00004797          	auipc	a5,0x4
    80004fb6:	eae78793          	add	a5,a5,-338 # 80008e60 <inode_types>
    80004fba:	97ba                	add	a5,a5,a4
    80004fbc:	04a91703          	lh	a4,74(s2)
    80004fc0:	04891683          	lh	a3,72(s2)
    80004fc4:	04691603          	lh	a2,70(s2)
    80004fc8:	638c                	ld	a1,0(a5)
    80004fca:	00004517          	auipc	a0,0x4
    80004fce:	abe50513          	add	a0,a0,-1346 # 80008a88 <syscalls+0x320>
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	258080e7          	jalr	600(ra) # 8000122a <printf>
    printf("size = %d, addrs =", ip->size);
    80004fda:	04c92583          	lw	a1,76(s2)
    80004fde:	00004517          	auipc	a0,0x4
    80004fe2:	ada50513          	add	a0,a0,-1318 # 80008ab8 <syscalls+0x350>
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	244080e7          	jalr	580(ra) # 8000122a <printf>
    for(int i = 0; i < NDIRECT+1; i++)
    80004fee:	05090493          	add	s1,s2,80
    80004ff2:	08490913          	add	s2,s2,132
        printf(" %d", ip->addrs[i]);
    80004ff6:	00004997          	auipc	s3,0x4
    80004ffa:	ada98993          	add	s3,s3,-1318 # 80008ad0 <syscalls+0x368>
    80004ffe:	408c                	lw	a1,0(s1)
    80005000:	854e                	mv	a0,s3
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	228080e7          	jalr	552(ra) # 8000122a <printf>
    for(int i = 0; i < NDIRECT+1; i++)
    8000500a:	0491                	add	s1,s1,4
    8000500c:	ff2499e3          	bne	s1,s2,80004ffe <inode_print+0xa8>
    printf("\n");
    80005010:	00004517          	auipc	a0,0x4
    80005014:	c9850513          	add	a0,a0,-872 # 80008ca8 <syscalls+0x540>
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	212080e7          	jalr	530(ra) # 8000122a <printf>
}
    80005020:	70a2                	ld	ra,40(sp)
    80005022:	7402                	ld	s0,32(sp)
    80005024:	64e2                	ld	s1,24(sp)
    80005026:	6942                	ld	s2,16(sp)
    80005028:	69a2                	ld	s3,8(sp)
    8000502a:	6145                	add	sp,sp,48
    8000502c:	8082                	ret

000000008000502e <inode_create>:

struct inode* inode_create(short type, short major, short minor) {
    8000502e:	7179                	add	sp,sp,-48
    80005030:	f406                	sd	ra,40(sp)
    80005032:	f022                	sd	s0,32(sp)
    80005034:	ec26                	sd	s1,24(sp)
    80005036:	e84a                	sd	s2,16(sp)
    80005038:	e44e                	sd	s3,8(sp)
    8000503a:	1800                	add	s0,sp,48
    8000503c:	89ae                	mv	s3,a1
    8000503e:	8932                	mv	s2,a2
    struct inode *ip = ialloc(ROOTDEV, type);
    80005040:	85aa                	mv	a1,a0
    80005042:	4505                	li	a0,1
    80005044:	00000097          	auipc	ra,0x0
    80005048:	8b0080e7          	jalr	-1872(ra) # 800048f4 <ialloc>
    8000504c:	84aa                	mv	s1,a0
    if(ip == 0) return 0;
    8000504e:	c515                	beqz	a0,8000507a <inode_create+0x4c>
    ilock(ip);
    80005050:	00000097          	auipc	ra,0x0
    80005054:	a3c080e7          	jalr	-1476(ra) # 80004a8c <ilock>
    ip->major = major;
    80005058:	05349323          	sh	s3,70(s1)
    ip->minor = minor;
    8000505c:	05249423          	sh	s2,72(s1)
    ip->nlink = 1;
    80005060:	4785                	li	a5,1
    80005062:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    80005066:	8526                	mv	a0,s1
    80005068:	00000097          	auipc	ra,0x0
    8000506c:	958080e7          	jalr	-1704(ra) # 800049c0 <iupdate>
    iunlock(ip);
    80005070:	8526                	mv	a0,s1
    80005072:	00000097          	auipc	ra,0x0
    80005076:	adc080e7          	jalr	-1316(ra) # 80004b4e <iunlock>
    return ip;
}
    8000507a:	8526                	mv	a0,s1
    8000507c:	70a2                	ld	ra,40(sp)
    8000507e:	7402                	ld	s0,32(sp)
    80005080:	64e2                	ld	s1,24(sp)
    80005082:	6942                	ld	s2,16(sp)
    80005084:	69a2                	ld	s3,8(sp)
    80005086:	6145                	add	sp,sp,48
    80005088:	8082                	ret

000000008000508a <inode_lock>:

void inode_lock(struct inode *ip) {
    8000508a:	1141                	add	sp,sp,-16
    8000508c:	e406                	sd	ra,8(sp)
    8000508e:	e022                	sd	s0,0(sp)
    80005090:	0800                	add	s0,sp,16
    ilock(ip);
    80005092:	00000097          	auipc	ra,0x0
    80005096:	9fa080e7          	jalr	-1542(ra) # 80004a8c <ilock>
}
    8000509a:	60a2                	ld	ra,8(sp)
    8000509c:	6402                	ld	s0,0(sp)
    8000509e:	0141                	add	sp,sp,16
    800050a0:	8082                	ret

00000000800050a2 <inode_unlock_free>:

void inode_unlock_free(struct inode *ip) {
    800050a2:	1101                	add	sp,sp,-32
    800050a4:	ec06                	sd	ra,24(sp)
    800050a6:	e822                	sd	s0,16(sp)
    800050a8:	e426                	sd	s1,8(sp)
    800050aa:	1000                	add	s0,sp,32
    800050ac:	84aa                	mv	s1,a0
    iunlock(ip);
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	aa0080e7          	jalr	-1376(ra) # 80004b4e <iunlock>
    iput(ip);
    800050b6:	8526                	mv	a0,s1
    800050b8:	00000097          	auipc	ra,0x0
    800050bc:	b8e080e7          	jalr	-1138(ra) # 80004c46 <iput>
}
    800050c0:	60e2                	ld	ra,24(sp)
    800050c2:	6442                	ld	s0,16(sp)
    800050c4:	64a2                	ld	s1,8(sp)
    800050c6:	6105                	add	sp,sp,32
    800050c8:	8082                	ret

00000000800050ca <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800050ca:	7179                	add	sp,sp,-48
    800050cc:	f406                	sd	ra,40(sp)
    800050ce:	f022                	sd	s0,32(sp)
    800050d0:	ec26                	sd	s1,24(sp)
    800050d2:	e84a                	sd	s2,16(sp)
    800050d4:	e44e                	sd	s3,8(sp)
    800050d6:	e052                	sd	s4,0(sp)
    800050d8:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800050da:	00004597          	auipc	a1,0x4
    800050de:	a1658593          	add	a1,a1,-1514 # 80008af0 <syscalls+0x388>
    800050e2:	00014517          	auipc	a0,0x14
    800050e6:	a8650513          	add	a0,a0,-1402 # 80018b68 <bcache>
    800050ea:	ffffe097          	auipc	ra,0xffffe
    800050ee:	d74080e7          	jalr	-652(ra) # 80002e5e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800050f2:	0001c797          	auipc	a5,0x1c
    800050f6:	a7678793          	add	a5,a5,-1418 # 80020b68 <bcache+0x8000>
    800050fa:	0001c717          	auipc	a4,0x1c
    800050fe:	cd670713          	add	a4,a4,-810 # 80020dd0 <bcache+0x8268>
    80005102:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80005106:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000510a:	00014497          	auipc	s1,0x14
    8000510e:	a7648493          	add	s1,s1,-1418 # 80018b80 <bcache+0x18>
    b->next = bcache.head.next;
    80005112:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80005114:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80005116:	00004a17          	auipc	s4,0x4
    8000511a:	9e2a0a13          	add	s4,s4,-1566 # 80008af8 <syscalls+0x390>
    b->next = bcache.head.next;
    8000511e:	2b893783          	ld	a5,696(s2)
    80005122:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80005124:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80005128:	85d2                	mv	a1,s4
    8000512a:	01048513          	add	a0,s1,16
    8000512e:	ffffe097          	auipc	ra,0xffffe
    80005132:	c06080e7          	jalr	-1018(ra) # 80002d34 <initsleeplock>
    bcache.head.next->prev = b;
    80005136:	2b893783          	ld	a5,696(s2)
    8000513a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000513c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80005140:	45848493          	add	s1,s1,1112
    80005144:	fd349de3          	bne	s1,s3,8000511e <binit+0x54>
  }
}
    80005148:	70a2                	ld	ra,40(sp)
    8000514a:	7402                	ld	s0,32(sp)
    8000514c:	64e2                	ld	s1,24(sp)
    8000514e:	6942                	ld	s2,16(sp)
    80005150:	69a2                	ld	s3,8(sp)
    80005152:	6a02                	ld	s4,0(sp)
    80005154:	6145                	add	sp,sp,48
    80005156:	8082                	ret

0000000080005158 <bread>:
}

/// @brief 从指定设备和块号读取一个块，并返回指向该块的缓冲区指针。
struct buf*
bread(uint dev, uint blockno)
{
    80005158:	7179                	add	sp,sp,-48
    8000515a:	f406                	sd	ra,40(sp)
    8000515c:	f022                	sd	s0,32(sp)
    8000515e:	ec26                	sd	s1,24(sp)
    80005160:	e84a                	sd	s2,16(sp)
    80005162:	e44e                	sd	s3,8(sp)
    80005164:	1800                	add	s0,sp,48
    80005166:	892a                	mv	s2,a0
    80005168:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000516a:	00014517          	auipc	a0,0x14
    8000516e:	9fe50513          	add	a0,a0,-1538 # 80018b68 <bcache>
    80005172:	ffffe097          	auipc	ra,0xffffe
    80005176:	d7c080e7          	jalr	-644(ra) # 80002eee <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000517a:	0001c497          	auipc	s1,0x1c
    8000517e:	ca64b483          	ld	s1,-858(s1) # 80020e20 <bcache+0x82b8>
    80005182:	0001c797          	auipc	a5,0x1c
    80005186:	c4e78793          	add	a5,a5,-946 # 80020dd0 <bcache+0x8268>
    8000518a:	02f48f63          	beq	s1,a5,800051c8 <bread+0x70>
    8000518e:	873e                	mv	a4,a5
    80005190:	a021                	j	80005198 <bread+0x40>
    80005192:	68a4                	ld	s1,80(s1)
    80005194:	02e48a63          	beq	s1,a4,800051c8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80005198:	449c                	lw	a5,8(s1)
    8000519a:	ff279ce3          	bne	a5,s2,80005192 <bread+0x3a>
    8000519e:	44dc                	lw	a5,12(s1)
    800051a0:	ff3799e3          	bne	a5,s3,80005192 <bread+0x3a>
      b->refcnt++;
    800051a4:	40bc                	lw	a5,64(s1)
    800051a6:	2785                	addw	a5,a5,1
    800051a8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800051aa:	00014517          	auipc	a0,0x14
    800051ae:	9be50513          	add	a0,a0,-1602 # 80018b68 <bcache>
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	df0080e7          	jalr	-528(ra) # 80002fa2 <release>
      acquiresleep(&b->lock);
    800051ba:	01048513          	add	a0,s1,16
    800051be:	ffffe097          	auipc	ra,0xffffe
    800051c2:	bb0080e7          	jalr	-1104(ra) # 80002d6e <acquiresleep>
      return b;
    800051c6:	a8b9                	j	80005224 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800051c8:	0001c497          	auipc	s1,0x1c
    800051cc:	c504b483          	ld	s1,-944(s1) # 80020e18 <bcache+0x82b0>
    800051d0:	0001c797          	auipc	a5,0x1c
    800051d4:	c0078793          	add	a5,a5,-1024 # 80020dd0 <bcache+0x8268>
    800051d8:	00f48863          	beq	s1,a5,800051e8 <bread+0x90>
    800051dc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800051de:	40bc                	lw	a5,64(s1)
    800051e0:	cf81                	beqz	a5,800051f8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800051e2:	64a4                	ld	s1,72(s1)
    800051e4:	fee49de3          	bne	s1,a4,800051de <bread+0x86>
  panic("bget: no buffers");
    800051e8:	00004517          	auipc	a0,0x4
    800051ec:	91850513          	add	a0,a0,-1768 # 80008b00 <syscalls+0x398>
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	ff0080e7          	jalr	-16(ra) # 800011e0 <panic>
      b->dev = dev;
    800051f8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800051fc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80005200:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80005204:	4785                	li	a5,1
    80005206:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80005208:	00014517          	auipc	a0,0x14
    8000520c:	96050513          	add	a0,a0,-1696 # 80018b68 <bcache>
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	d92080e7          	jalr	-622(ra) # 80002fa2 <release>
      acquiresleep(&b->lock);
    80005218:	01048513          	add	a0,s1,16
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	b52080e7          	jalr	-1198(ra) # 80002d6e <acquiresleep>
  struct buf *b;
  // printf("bread: reading block %d from device %d\n", blockno, dev);
  
  b = bget(dev, blockno);
  // printf("bread: got buffer for block %d from device %d\n", blockno, dev);
  if(!b->valid) {
    80005224:	409c                	lw	a5,0(s1)
    80005226:	cb89                	beqz	a5,80005238 <bread+0xe0>
    virtio_disk_rw(b, 0);
    // printf("bread: block %d from device %d read from disk\n", blockno, dev);
    b->valid = 1;
  }
  return b;
}
    80005228:	8526                	mv	a0,s1
    8000522a:	70a2                	ld	ra,40(sp)
    8000522c:	7402                	ld	s0,32(sp)
    8000522e:	64e2                	ld	s1,24(sp)
    80005230:	6942                	ld	s2,16(sp)
    80005232:	69a2                	ld	s3,8(sp)
    80005234:	6145                	add	sp,sp,48
    80005236:	8082                	ret
    virtio_disk_rw(b, 0);
    80005238:	4581                	li	a1,0
    8000523a:	8526                	mv	a0,s1
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	a78080e7          	jalr	-1416(ra) # 80000cb4 <virtio_disk_rw>
    b->valid = 1;
    80005244:	4785                	li	a5,1
    80005246:	c09c                	sw	a5,0(s1)
  return b;
    80005248:	b7c5                	j	80005228 <bread+0xd0>

000000008000524a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000524a:	1101                	add	sp,sp,-32
    8000524c:	ec06                	sd	ra,24(sp)
    8000524e:	e822                	sd	s0,16(sp)
    80005250:	e426                	sd	s1,8(sp)
    80005252:	1000                	add	s0,sp,32
    80005254:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80005256:	0541                	add	a0,a0,16
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	bb0080e7          	jalr	-1104(ra) # 80002e08 <holdingsleep>
    80005260:	cd01                	beqz	a0,80005278 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80005262:	4585                	li	a1,1
    80005264:	8526                	mv	a0,s1
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	a4e080e7          	jalr	-1458(ra) # 80000cb4 <virtio_disk_rw>
}
    8000526e:	60e2                	ld	ra,24(sp)
    80005270:	6442                	ld	s0,16(sp)
    80005272:	64a2                	ld	s1,8(sp)
    80005274:	6105                	add	sp,sp,32
    80005276:	8082                	ret
    panic("bwrite");
    80005278:	00004517          	auipc	a0,0x4
    8000527c:	8a050513          	add	a0,a0,-1888 # 80008b18 <syscalls+0x3b0>
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	f60080e7          	jalr	-160(ra) # 800011e0 <panic>

0000000080005288 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80005288:	1101                	add	sp,sp,-32
    8000528a:	ec06                	sd	ra,24(sp)
    8000528c:	e822                	sd	s0,16(sp)
    8000528e:	e426                	sd	s1,8(sp)
    80005290:	e04a                	sd	s2,0(sp)
    80005292:	1000                	add	s0,sp,32
    80005294:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80005296:	01050913          	add	s2,a0,16
    8000529a:	854a                	mv	a0,s2
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	b6c080e7          	jalr	-1172(ra) # 80002e08 <holdingsleep>
    800052a4:	c925                	beqz	a0,80005314 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800052a6:	854a                	mv	a0,s2
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	b1c080e7          	jalr	-1252(ra) # 80002dc4 <releasesleep>

  acquire(&bcache.lock);
    800052b0:	00014517          	auipc	a0,0x14
    800052b4:	8b850513          	add	a0,a0,-1864 # 80018b68 <bcache>
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	c36080e7          	jalr	-970(ra) # 80002eee <acquire>
  b->refcnt--;
    800052c0:	40bc                	lw	a5,64(s1)
    800052c2:	37fd                	addw	a5,a5,-1
    800052c4:	0007871b          	sext.w	a4,a5
    800052c8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800052ca:	e71d                	bnez	a4,800052f8 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800052cc:	68b8                	ld	a4,80(s1)
    800052ce:	64bc                	ld	a5,72(s1)
    800052d0:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800052d2:	68b8                	ld	a4,80(s1)
    800052d4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800052d6:	0001c797          	auipc	a5,0x1c
    800052da:	89278793          	add	a5,a5,-1902 # 80020b68 <bcache+0x8000>
    800052de:	2b87b703          	ld	a4,696(a5)
    800052e2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800052e4:	0001c717          	auipc	a4,0x1c
    800052e8:	aec70713          	add	a4,a4,-1300 # 80020dd0 <bcache+0x8268>
    800052ec:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800052ee:	2b87b703          	ld	a4,696(a5)
    800052f2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800052f4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800052f8:	00014517          	auipc	a0,0x14
    800052fc:	87050513          	add	a0,a0,-1936 # 80018b68 <bcache>
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	ca2080e7          	jalr	-862(ra) # 80002fa2 <release>
}
    80005308:	60e2                	ld	ra,24(sp)
    8000530a:	6442                	ld	s0,16(sp)
    8000530c:	64a2                	ld	s1,8(sp)
    8000530e:	6902                	ld	s2,0(sp)
    80005310:	6105                	add	sp,sp,32
    80005312:	8082                	ret
    panic("brelse");
    80005314:	00004517          	auipc	a0,0x4
    80005318:	80c50513          	add	a0,a0,-2036 # 80008b20 <syscalls+0x3b8>
    8000531c:	ffffc097          	auipc	ra,0xffffc
    80005320:	ec4080e7          	jalr	-316(ra) # 800011e0 <panic>

0000000080005324 <bpin>:

void
bpin(struct buf *b) {
    80005324:	1101                	add	sp,sp,-32
    80005326:	ec06                	sd	ra,24(sp)
    80005328:	e822                	sd	s0,16(sp)
    8000532a:	e426                	sd	s1,8(sp)
    8000532c:	1000                	add	s0,sp,32
    8000532e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80005330:	00014517          	auipc	a0,0x14
    80005334:	83850513          	add	a0,a0,-1992 # 80018b68 <bcache>
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	bb6080e7          	jalr	-1098(ra) # 80002eee <acquire>
  b->refcnt++;
    80005340:	40bc                	lw	a5,64(s1)
    80005342:	2785                	addw	a5,a5,1
    80005344:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80005346:	00014517          	auipc	a0,0x14
    8000534a:	82250513          	add	a0,a0,-2014 # 80018b68 <bcache>
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	c54080e7          	jalr	-940(ra) # 80002fa2 <release>
}
    80005356:	60e2                	ld	ra,24(sp)
    80005358:	6442                	ld	s0,16(sp)
    8000535a:	64a2                	ld	s1,8(sp)
    8000535c:	6105                	add	sp,sp,32
    8000535e:	8082                	ret

0000000080005360 <bunpin>:

void
bunpin(struct buf *b) {
    80005360:	1101                	add	sp,sp,-32
    80005362:	ec06                	sd	ra,24(sp)
    80005364:	e822                	sd	s0,16(sp)
    80005366:	e426                	sd	s1,8(sp)
    80005368:	1000                	add	s0,sp,32
    8000536a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000536c:	00013517          	auipc	a0,0x13
    80005370:	7fc50513          	add	a0,a0,2044 # 80018b68 <bcache>
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	b7a080e7          	jalr	-1158(ra) # 80002eee <acquire>
  b->refcnt--;
    8000537c:	40bc                	lw	a5,64(s1)
    8000537e:	37fd                	addw	a5,a5,-1
    80005380:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80005382:	00013517          	auipc	a0,0x13
    80005386:	7e650513          	add	a0,a0,2022 # 80018b68 <bcache>
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	c18080e7          	jalr	-1000(ra) # 80002fa2 <release>
}
    80005392:	60e2                	ld	ra,24(sp)
    80005394:	6442                	ld	s0,16(sp)
    80005396:	64a2                	ld	s1,8(sp)
    80005398:	6105                	add	sp,sp,32
    8000539a:	8082                	ret

000000008000539c <buf_print>:


// 输出buf_cache的情况
void buf_print()
{
    8000539c:	7159                	add	sp,sp,-112
    8000539e:	f486                	sd	ra,104(sp)
    800053a0:	f0a2                	sd	s0,96(sp)
    800053a2:	eca6                	sd	s1,88(sp)
    800053a4:	e8ca                	sd	s2,80(sp)
    800053a6:	e4ce                	sd	s3,72(sp)
    800053a8:	e0d2                	sd	s4,64(sp)
    800053aa:	fc56                	sd	s5,56(sp)
    800053ac:	f85a                	sd	s6,48(sp)
    800053ae:	f45e                	sd	s7,40(sp)
    800053b0:	f062                	sd	s8,32(sp)
    800053b2:	ec66                	sd	s9,24(sp)
    800053b4:	e86a                	sd	s10,16(sp)
    800053b6:	e46e                	sd	s11,8(sp)
    800053b8:	1880                	add	s0,sp,112
    acquire(&bcache.lock);
    800053ba:	00013517          	auipc	a0,0x13
    800053be:	7ae50513          	add	a0,a0,1966 # 80018b68 <bcache>
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	b2c080e7          	jalr	-1236(ra) # 80002eee <acquire>
    printf("\nBuffer Cache (Index Order):\n");
    800053ca:	00003517          	auipc	a0,0x3
    800053ce:	75e50513          	add	a0,a0,1886 # 80008b28 <syscalls+0x3c0>
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	e58080e7          	jalr	-424(ra) # 8000122a <printf>
    printf("IDX  DEV  BLOCK  REF  VALID  DATA\n");
    800053da:	00003517          	auipc	a0,0x3
    800053de:	76e50513          	add	a0,a0,1902 # 80008b48 <syscalls+0x3e0>
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	e48080e7          	jalr	-440(ra) # 8000122a <printf>
    for(int i = 0; i < NBUF; i++){
    800053ea:	00013997          	auipc	s3,0x13
    800053ee:	7f698993          	add	s3,s3,2038 # 80018be0 <bcache+0x78>
    800053f2:	4b01                	li	s6,0
        struct buf *b = &bcache.buf[i];
        if(b->refcnt > 0 || b->valid || b->blockno != 0) {
            if(i < 10) printf(" ");
    800053f4:	4ca5                	li	s9,9
            printf("%d   ", i);
    800053f6:	00003d97          	auipc	s11,0x3
    800053fa:	782d8d93          	add	s11,s11,1922 # 80008b78 <syscalls+0x410>
            
            printf("%d    ", b->dev);
    800053fe:	00003c17          	auipc	s8,0x3
    80005402:	782c0c13          	add	s8,s8,1922 # 80008b80 <syscalls+0x418>
            
            printf("%d     ", b->blockno);
    80005406:	00003d17          	auipc	s10,0x3
    8000540a:	782d0d13          	add	s10,s10,1922 # 80008b88 <syscalls+0x420>
            printf("%d    ", b->refcnt);
            printf("%d      ", b->valid);
            
            for(int j = 0; j < 8; j++){
                int val = (unsigned char)b->data[j];
                if(val < 16) printf("0");
    8000540e:	4abd                	li	s5,15
    80005410:	00003b97          	auipc	s7,0x3
    80005414:	798b8b93          	add	s7,s7,1944 # 80008ba8 <syscalls+0x440>
                printf("%x ", val);
    80005418:	00003a17          	auipc	s4,0x3
    8000541c:	798a0a13          	add	s4,s4,1944 # 80008bb0 <syscalls+0x448>
    80005420:	a045                	j	800054c0 <buf_print+0x124>
            if(i < 10) printf(" ");
    80005422:	00003517          	auipc	a0,0x3
    80005426:	74e50513          	add	a0,a0,1870 # 80008b70 <syscalls+0x408>
    8000542a:	ffffc097          	auipc	ra,0xffffc
    8000542e:	e00080e7          	jalr	-512(ra) # 8000122a <printf>
    80005432:	a05d                	j	800054d8 <buf_print+0x13c>
            if(b->blockno < 10) printf("   ");
    80005434:	00003517          	auipc	a0,0x3
    80005438:	75c50513          	add	a0,a0,1884 # 80008b90 <syscalls+0x428>
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	dee080e7          	jalr	-530(ra) # 8000122a <printf>
            printf("%d    ", b->refcnt);
    80005444:	fe04a583          	lw	a1,-32(s1)
    80005448:	8562                	mv	a0,s8
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	de0080e7          	jalr	-544(ra) # 8000122a <printf>
            printf("%d      ", b->valid);
    80005452:	fa04a583          	lw	a1,-96(s1)
    80005456:	00003517          	auipc	a0,0x3
    8000545a:	74250513          	add	a0,a0,1858 # 80008b98 <syscalls+0x430>
    8000545e:	ffffc097          	auipc	ra,0xffffc
    80005462:	dcc080e7          	jalr	-564(ra) # 8000122a <printf>
            for(int j = 0; j < 8; j++){
    80005466:	ff898493          	add	s1,s3,-8
    8000546a:	a01d                	j	80005490 <buf_print+0xf4>
            else if(b->blockno < 100) printf("  ");
    8000546c:	00003517          	auipc	a0,0x3
    80005470:	e5c50513          	add	a0,a0,-420 # 800082c8 <digits+0xd8>
    80005474:	ffffc097          	auipc	ra,0xffffc
    80005478:	db6080e7          	jalr	-586(ra) # 8000122a <printf>
    8000547c:	b7e1                	j	80005444 <buf_print+0xa8>
                printf("%x ", val);
    8000547e:	85ca                	mv	a1,s2
    80005480:	8552                	mv	a0,s4
    80005482:	ffffc097          	auipc	ra,0xffffc
    80005486:	da8080e7          	jalr	-600(ra) # 8000122a <printf>
            for(int j = 0; j < 8; j++){
    8000548a:	0485                	add	s1,s1,1
    8000548c:	01348c63          	beq	s1,s3,800054a4 <buf_print+0x108>
                int val = (unsigned char)b->data[j];
    80005490:	0004c903          	lbu	s2,0(s1)
                if(val < 16) printf("0");
    80005494:	ff2ac5e3          	blt	s5,s2,8000547e <buf_print+0xe2>
    80005498:	855e                	mv	a0,s7
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	d90080e7          	jalr	-624(ra) # 8000122a <printf>
    800054a2:	bff1                	j	8000547e <buf_print+0xe2>
            }
            printf("\n");
    800054a4:	00004517          	auipc	a0,0x4
    800054a8:	80450513          	add	a0,a0,-2044 # 80008ca8 <syscalls+0x540>
    800054ac:	ffffc097          	auipc	ra,0xffffc
    800054b0:	d7e080e7          	jalr	-642(ra) # 8000122a <printf>
    for(int i = 0; i < NBUF; i++){
    800054b4:	2b05                	addw	s6,s6,1
    800054b6:	45898993          	add	s3,s3,1112
    800054ba:	47f9                	li	a5,30
    800054bc:	06fb0763          	beq	s6,a5,8000552a <buf_print+0x18e>
        if(b->refcnt > 0 || b->valid || b->blockno != 0) {
    800054c0:	84ce                	mv	s1,s3
    800054c2:	fe09a783          	lw	a5,-32(s3)
    800054c6:	e799                	bnez	a5,800054d4 <buf_print+0x138>
    800054c8:	fa09a783          	lw	a5,-96(s3)
    800054cc:	e781                	bnez	a5,800054d4 <buf_print+0x138>
    800054ce:	fac9a783          	lw	a5,-84(s3)
    800054d2:	d3ed                	beqz	a5,800054b4 <buf_print+0x118>
            if(i < 10) printf(" ");
    800054d4:	f56cd7e3          	bge	s9,s6,80005422 <buf_print+0x86>
            printf("%d   ", i);
    800054d8:	85da                	mv	a1,s6
    800054da:	856e                	mv	a0,s11
    800054dc:	ffffc097          	auipc	ra,0xffffc
    800054e0:	d4e080e7          	jalr	-690(ra) # 8000122a <printf>
            printf("%d    ", b->dev);
    800054e4:	fa84a583          	lw	a1,-88(s1)
    800054e8:	8562                	mv	a0,s8
    800054ea:	ffffc097          	auipc	ra,0xffffc
    800054ee:	d40080e7          	jalr	-704(ra) # 8000122a <printf>
            printf("%d     ", b->blockno);
    800054f2:	fac4a583          	lw	a1,-84(s1)
    800054f6:	856a                	mv	a0,s10
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	d32080e7          	jalr	-718(ra) # 8000122a <printf>
            if(b->blockno < 10) printf("   ");
    80005500:	fac4a783          	lw	a5,-84(s1)
    80005504:	f2fcf8e3          	bgeu	s9,a5,80005434 <buf_print+0x98>
            else if(b->blockno < 100) printf("  ");
    80005508:	06300713          	li	a4,99
    8000550c:	f6f770e3          	bgeu	a4,a5,8000546c <buf_print+0xd0>
            else if(b->blockno < 1000) printf(" ");
    80005510:	3e700713          	li	a4,999
    80005514:	f2f768e3          	bltu	a4,a5,80005444 <buf_print+0xa8>
    80005518:	00003517          	auipc	a0,0x3
    8000551c:	65850513          	add	a0,a0,1624 # 80008b70 <syscalls+0x408>
    80005520:	ffffc097          	auipc	ra,0xffffc
    80005524:	d0a080e7          	jalr	-758(ra) # 8000122a <printf>
    80005528:	bf31                	j	80005444 <buf_print+0xa8>
        }
    }
    release(&bcache.lock);
    8000552a:	00013517          	auipc	a0,0x13
    8000552e:	63e50513          	add	a0,a0,1598 # 80018b68 <bcache>
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	a70080e7          	jalr	-1424(ra) # 80002fa2 <release>
    8000553a:	70a6                	ld	ra,104(sp)
    8000553c:	7406                	ld	s0,96(sp)
    8000553e:	64e6                	ld	s1,88(sp)
    80005540:	6946                	ld	s2,80(sp)
    80005542:	69a6                	ld	s3,72(sp)
    80005544:	6a06                	ld	s4,64(sp)
    80005546:	7ae2                	ld	s5,56(sp)
    80005548:	7b42                	ld	s6,48(sp)
    8000554a:	7ba2                	ld	s7,40(sp)
    8000554c:	7c02                	ld	s8,32(sp)
    8000554e:	6ce2                	ld	s9,24(sp)
    80005550:	6d42                	ld	s10,16(sp)
    80005552:	6da2                	ld	s11,8(sp)
    80005554:	6165                	add	sp,sp,112
    80005556:	8082                	ret

0000000080005558 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80005558:	1101                	add	sp,sp,-32
    8000555a:	ec06                	sd	ra,24(sp)
    8000555c:	e822                	sd	s0,16(sp)
    8000555e:	e426                	sd	s1,8(sp)
    80005560:	e04a                	sd	s2,0(sp)
    80005562:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80005564:	0001c917          	auipc	s2,0x1c
    80005568:	cc490913          	add	s2,s2,-828 # 80021228 <log>
    8000556c:	01892583          	lw	a1,24(s2)
    80005570:	02892503          	lw	a0,40(s2)
    80005574:	00000097          	auipc	ra,0x0
    80005578:	be4080e7          	jalr	-1052(ra) # 80005158 <bread>
    8000557c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000557e:	02c92603          	lw	a2,44(s2)
    80005582:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80005584:	00c05f63          	blez	a2,800055a2 <write_head+0x4a>
    80005588:	0001c717          	auipc	a4,0x1c
    8000558c:	cd070713          	add	a4,a4,-816 # 80021258 <log+0x30>
    80005590:	87aa                	mv	a5,a0
    80005592:	060a                	sll	a2,a2,0x2
    80005594:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80005596:	4314                	lw	a3,0(a4)
    80005598:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000559a:	0711                	add	a4,a4,4
    8000559c:	0791                	add	a5,a5,4
    8000559e:	fec79ce3          	bne	a5,a2,80005596 <write_head+0x3e>
  }
  bwrite(buf);
    800055a2:	8526                	mv	a0,s1
    800055a4:	00000097          	auipc	ra,0x0
    800055a8:	ca6080e7          	jalr	-858(ra) # 8000524a <bwrite>
  brelse(buf);
    800055ac:	8526                	mv	a0,s1
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	cda080e7          	jalr	-806(ra) # 80005288 <brelse>
}
    800055b6:	60e2                	ld	ra,24(sp)
    800055b8:	6442                	ld	s0,16(sp)
    800055ba:	64a2                	ld	s1,8(sp)
    800055bc:	6902                	ld	s2,0(sp)
    800055be:	6105                	add	sp,sp,32
    800055c0:	8082                	ret

00000000800055c2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800055c2:	0001c797          	auipc	a5,0x1c
    800055c6:	c927a783          	lw	a5,-878(a5) # 80021254 <log+0x2c>
    800055ca:	0af05d63          	blez	a5,80005684 <install_trans+0xc2>
{
    800055ce:	7139                	add	sp,sp,-64
    800055d0:	fc06                	sd	ra,56(sp)
    800055d2:	f822                	sd	s0,48(sp)
    800055d4:	f426                	sd	s1,40(sp)
    800055d6:	f04a                	sd	s2,32(sp)
    800055d8:	ec4e                	sd	s3,24(sp)
    800055da:	e852                	sd	s4,16(sp)
    800055dc:	e456                	sd	s5,8(sp)
    800055de:	e05a                	sd	s6,0(sp)
    800055e0:	0080                	add	s0,sp,64
    800055e2:	8b2a                	mv	s6,a0
    800055e4:	0001ca97          	auipc	s5,0x1c
    800055e8:	c74a8a93          	add	s5,s5,-908 # 80021258 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800055ec:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800055ee:	0001c997          	auipc	s3,0x1c
    800055f2:	c3a98993          	add	s3,s3,-966 # 80021228 <log>
    800055f6:	a00d                	j	80005618 <install_trans+0x56>
    brelse(lbuf);
    800055f8:	854a                	mv	a0,s2
    800055fa:	00000097          	auipc	ra,0x0
    800055fe:	c8e080e7          	jalr	-882(ra) # 80005288 <brelse>
    brelse(dbuf);
    80005602:	8526                	mv	a0,s1
    80005604:	00000097          	auipc	ra,0x0
    80005608:	c84080e7          	jalr	-892(ra) # 80005288 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000560c:	2a05                	addw	s4,s4,1
    8000560e:	0a91                	add	s5,s5,4
    80005610:	02c9a783          	lw	a5,44(s3)
    80005614:	04fa5e63          	bge	s4,a5,80005670 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005618:	0189a583          	lw	a1,24(s3)
    8000561c:	014585bb          	addw	a1,a1,s4
    80005620:	2585                	addw	a1,a1,1
    80005622:	0289a503          	lw	a0,40(s3)
    80005626:	00000097          	auipc	ra,0x0
    8000562a:	b32080e7          	jalr	-1230(ra) # 80005158 <bread>
    8000562e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80005630:	000aa583          	lw	a1,0(s5)
    80005634:	0289a503          	lw	a0,40(s3)
    80005638:	00000097          	auipc	ra,0x0
    8000563c:	b20080e7          	jalr	-1248(ra) # 80005158 <bread>
    80005640:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80005642:	40000613          	li	a2,1024
    80005646:	05890593          	add	a1,s2,88
    8000564a:	05850513          	add	a0,a0,88
    8000564e:	ffffc097          	auipc	ra,0xffffc
    80005652:	9a6080e7          	jalr	-1626(ra) # 80000ff4 <memmove>
    bwrite(dbuf);  // write dst to disk
    80005656:	8526                	mv	a0,s1
    80005658:	00000097          	auipc	ra,0x0
    8000565c:	bf2080e7          	jalr	-1038(ra) # 8000524a <bwrite>
    if(recovering == 0)
    80005660:	f80b1ce3          	bnez	s6,800055f8 <install_trans+0x36>
      bunpin(dbuf);
    80005664:	8526                	mv	a0,s1
    80005666:	00000097          	auipc	ra,0x0
    8000566a:	cfa080e7          	jalr	-774(ra) # 80005360 <bunpin>
    8000566e:	b769                	j	800055f8 <install_trans+0x36>
}
    80005670:	70e2                	ld	ra,56(sp)
    80005672:	7442                	ld	s0,48(sp)
    80005674:	74a2                	ld	s1,40(sp)
    80005676:	7902                	ld	s2,32(sp)
    80005678:	69e2                	ld	s3,24(sp)
    8000567a:	6a42                	ld	s4,16(sp)
    8000567c:	6aa2                	ld	s5,8(sp)
    8000567e:	6b02                	ld	s6,0(sp)
    80005680:	6121                	add	sp,sp,64
    80005682:	8082                	ret
    80005684:	8082                	ret

0000000080005686 <initlog>:
{
    80005686:	7179                	add	sp,sp,-48
    80005688:	f406                	sd	ra,40(sp)
    8000568a:	f022                	sd	s0,32(sp)
    8000568c:	ec26                	sd	s1,24(sp)
    8000568e:	e84a                	sd	s2,16(sp)
    80005690:	e44e                	sd	s3,8(sp)
    80005692:	1800                	add	s0,sp,48
    80005694:	892a                	mv	s2,a0
    80005696:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80005698:	0001c497          	auipc	s1,0x1c
    8000569c:	b9048493          	add	s1,s1,-1136 # 80021228 <log>
    800056a0:	00003597          	auipc	a1,0x3
    800056a4:	51858593          	add	a1,a1,1304 # 80008bb8 <syscalls+0x450>
    800056a8:	8526                	mv	a0,s1
    800056aa:	ffffd097          	auipc	ra,0xffffd
    800056ae:	7b4080e7          	jalr	1972(ra) # 80002e5e <initlock>
  log.start = sb->logstart;
    800056b2:	0149a583          	lw	a1,20(s3)
    800056b6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800056b8:	0109a783          	lw	a5,16(s3)
    800056bc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800056be:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800056c2:	854a                	mv	a0,s2
    800056c4:	00000097          	auipc	ra,0x0
    800056c8:	a94080e7          	jalr	-1388(ra) # 80005158 <bread>
  log.lh.n = lh->n;
    800056cc:	4d30                	lw	a2,88(a0)
    800056ce:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800056d0:	00c05f63          	blez	a2,800056ee <initlog+0x68>
    800056d4:	87aa                	mv	a5,a0
    800056d6:	0001c717          	auipc	a4,0x1c
    800056da:	b8270713          	add	a4,a4,-1150 # 80021258 <log+0x30>
    800056de:	060a                	sll	a2,a2,0x2
    800056e0:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800056e2:	4ff4                	lw	a3,92(a5)
    800056e4:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800056e6:	0791                	add	a5,a5,4
    800056e8:	0711                	add	a4,a4,4
    800056ea:	fec79ce3          	bne	a5,a2,800056e2 <initlog+0x5c>
  brelse(buf);
    800056ee:	00000097          	auipc	ra,0x0
    800056f2:	b9a080e7          	jalr	-1126(ra) # 80005288 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800056f6:	4505                	li	a0,1
    800056f8:	00000097          	auipc	ra,0x0
    800056fc:	eca080e7          	jalr	-310(ra) # 800055c2 <install_trans>
  log.lh.n = 0;
    80005700:	0001c797          	auipc	a5,0x1c
    80005704:	b407aa23          	sw	zero,-1196(a5) # 80021254 <log+0x2c>
  write_head(); // clear the log
    80005708:	00000097          	auipc	ra,0x0
    8000570c:	e50080e7          	jalr	-432(ra) # 80005558 <write_head>
}
    80005710:	70a2                	ld	ra,40(sp)
    80005712:	7402                	ld	s0,32(sp)
    80005714:	64e2                	ld	s1,24(sp)
    80005716:	6942                	ld	s2,16(sp)
    80005718:	69a2                	ld	s3,8(sp)
    8000571a:	6145                	add	sp,sp,48
    8000571c:	8082                	ret

000000008000571e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000571e:	1101                	add	sp,sp,-32
    80005720:	ec06                	sd	ra,24(sp)
    80005722:	e822                	sd	s0,16(sp)
    80005724:	e426                	sd	s1,8(sp)
    80005726:	e04a                	sd	s2,0(sp)
    80005728:	1000                	add	s0,sp,32
  acquire(&log.lock);
    8000572a:	0001c517          	auipc	a0,0x1c
    8000572e:	afe50513          	add	a0,a0,-1282 # 80021228 <log>
    80005732:	ffffd097          	auipc	ra,0xffffd
    80005736:	7bc080e7          	jalr	1980(ra) # 80002eee <acquire>
  while(1){
    if(log.committing){
    8000573a:	0001c497          	auipc	s1,0x1c
    8000573e:	aee48493          	add	s1,s1,-1298 # 80021228 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005742:	4979                	li	s2,30
    80005744:	a039                	j	80005752 <begin_op+0x34>
      sleep(&log, &log.lock);
    80005746:	85a6                	mv	a1,s1
    80005748:	8526                	mv	a0,s1
    8000574a:	ffffd097          	auipc	ra,0xffffd
    8000574e:	0f2080e7          	jalr	242(ra) # 8000283c <sleep>
    if(log.committing){
    80005752:	50dc                	lw	a5,36(s1)
    80005754:	fbed                	bnez	a5,80005746 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005756:	5098                	lw	a4,32(s1)
    80005758:	2705                	addw	a4,a4,1
    8000575a:	0027179b          	sllw	a5,a4,0x2
    8000575e:	9fb9                	addw	a5,a5,a4
    80005760:	0017979b          	sllw	a5,a5,0x1
    80005764:	54d4                	lw	a3,44(s1)
    80005766:	9fb5                	addw	a5,a5,a3
    80005768:	00f95963          	bge	s2,a5,8000577a <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000576c:	85a6                	mv	a1,s1
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffd097          	auipc	ra,0xffffd
    80005774:	0cc080e7          	jalr	204(ra) # 8000283c <sleep>
    80005778:	bfe9                	j	80005752 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000577a:	0001c517          	auipc	a0,0x1c
    8000577e:	aae50513          	add	a0,a0,-1362 # 80021228 <log>
    80005782:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	81e080e7          	jalr	-2018(ra) # 80002fa2 <release>
      break;
    }
  }
}
    8000578c:	60e2                	ld	ra,24(sp)
    8000578e:	6442                	ld	s0,16(sp)
    80005790:	64a2                	ld	s1,8(sp)
    80005792:	6902                	ld	s2,0(sp)
    80005794:	6105                	add	sp,sp,32
    80005796:	8082                	ret

0000000080005798 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005798:	7139                	add	sp,sp,-64
    8000579a:	fc06                	sd	ra,56(sp)
    8000579c:	f822                	sd	s0,48(sp)
    8000579e:	f426                	sd	s1,40(sp)
    800057a0:	f04a                	sd	s2,32(sp)
    800057a2:	ec4e                	sd	s3,24(sp)
    800057a4:	e852                	sd	s4,16(sp)
    800057a6:	e456                	sd	s5,8(sp)
    800057a8:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800057aa:	0001c497          	auipc	s1,0x1c
    800057ae:	a7e48493          	add	s1,s1,-1410 # 80021228 <log>
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffd097          	auipc	ra,0xffffd
    800057b8:	73a080e7          	jalr	1850(ra) # 80002eee <acquire>
  log.outstanding -= 1;
    800057bc:	509c                	lw	a5,32(s1)
    800057be:	37fd                	addw	a5,a5,-1
    800057c0:	0007891b          	sext.w	s2,a5
    800057c4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800057c6:	50dc                	lw	a5,36(s1)
    800057c8:	e7b9                	bnez	a5,80005816 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800057ca:	04091e63          	bnez	s2,80005826 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800057ce:	0001c497          	auipc	s1,0x1c
    800057d2:	a5a48493          	add	s1,s1,-1446 # 80021228 <log>
    800057d6:	4785                	li	a5,1
    800057d8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffd097          	auipc	ra,0xffffd
    800057e0:	7c6080e7          	jalr	1990(ra) # 80002fa2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800057e4:	54dc                	lw	a5,44(s1)
    800057e6:	06f04763          	bgtz	a5,80005854 <end_op+0xbc>
    acquire(&log.lock);
    800057ea:	0001c497          	auipc	s1,0x1c
    800057ee:	a3e48493          	add	s1,s1,-1474 # 80021228 <log>
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	6fa080e7          	jalr	1786(ra) # 80002eee <acquire>
    log.committing = 0;
    800057fc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffd097          	auipc	ra,0xffffd
    80005806:	0a8080e7          	jalr	168(ra) # 800028aa <wakeup>
    release(&log.lock);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffd097          	auipc	ra,0xffffd
    80005810:	796080e7          	jalr	1942(ra) # 80002fa2 <release>
}
    80005814:	a03d                	j	80005842 <end_op+0xaa>
    panic("log.committing");
    80005816:	00003517          	auipc	a0,0x3
    8000581a:	3aa50513          	add	a0,a0,938 # 80008bc0 <syscalls+0x458>
    8000581e:	ffffc097          	auipc	ra,0xffffc
    80005822:	9c2080e7          	jalr	-1598(ra) # 800011e0 <panic>
    wakeup(&log);
    80005826:	0001c497          	auipc	s1,0x1c
    8000582a:	a0248493          	add	s1,s1,-1534 # 80021228 <log>
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffd097          	auipc	ra,0xffffd
    80005834:	07a080e7          	jalr	122(ra) # 800028aa <wakeup>
  release(&log.lock);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffd097          	auipc	ra,0xffffd
    8000583e:	768080e7          	jalr	1896(ra) # 80002fa2 <release>
}
    80005842:	70e2                	ld	ra,56(sp)
    80005844:	7442                	ld	s0,48(sp)
    80005846:	74a2                	ld	s1,40(sp)
    80005848:	7902                	ld	s2,32(sp)
    8000584a:	69e2                	ld	s3,24(sp)
    8000584c:	6a42                	ld	s4,16(sp)
    8000584e:	6aa2                	ld	s5,8(sp)
    80005850:	6121                	add	sp,sp,64
    80005852:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80005854:	0001ca97          	auipc	s5,0x1c
    80005858:	a04a8a93          	add	s5,s5,-1532 # 80021258 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000585c:	0001ca17          	auipc	s4,0x1c
    80005860:	9cca0a13          	add	s4,s4,-1588 # 80021228 <log>
    80005864:	018a2583          	lw	a1,24(s4)
    80005868:	012585bb          	addw	a1,a1,s2
    8000586c:	2585                	addw	a1,a1,1
    8000586e:	028a2503          	lw	a0,40(s4)
    80005872:	00000097          	auipc	ra,0x0
    80005876:	8e6080e7          	jalr	-1818(ra) # 80005158 <bread>
    8000587a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000587c:	000aa583          	lw	a1,0(s5)
    80005880:	028a2503          	lw	a0,40(s4)
    80005884:	00000097          	auipc	ra,0x0
    80005888:	8d4080e7          	jalr	-1836(ra) # 80005158 <bread>
    8000588c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000588e:	40000613          	li	a2,1024
    80005892:	05850593          	add	a1,a0,88
    80005896:	05848513          	add	a0,s1,88
    8000589a:	ffffb097          	auipc	ra,0xffffb
    8000589e:	75a080e7          	jalr	1882(ra) # 80000ff4 <memmove>
    bwrite(to);  // write the log
    800058a2:	8526                	mv	a0,s1
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	9a6080e7          	jalr	-1626(ra) # 8000524a <bwrite>
    brelse(from);
    800058ac:	854e                	mv	a0,s3
    800058ae:	00000097          	auipc	ra,0x0
    800058b2:	9da080e7          	jalr	-1574(ra) # 80005288 <brelse>
    brelse(to);
    800058b6:	8526                	mv	a0,s1
    800058b8:	00000097          	auipc	ra,0x0
    800058bc:	9d0080e7          	jalr	-1584(ra) # 80005288 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800058c0:	2905                	addw	s2,s2,1
    800058c2:	0a91                	add	s5,s5,4
    800058c4:	02ca2783          	lw	a5,44(s4)
    800058c8:	f8f94ee3          	blt	s2,a5,80005864 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800058cc:	00000097          	auipc	ra,0x0
    800058d0:	c8c080e7          	jalr	-884(ra) # 80005558 <write_head>
    install_trans(0); // Now install writes to home locations
    800058d4:	4501                	li	a0,0
    800058d6:	00000097          	auipc	ra,0x0
    800058da:	cec080e7          	jalr	-788(ra) # 800055c2 <install_trans>
    log.lh.n = 0;
    800058de:	0001c797          	auipc	a5,0x1c
    800058e2:	9607ab23          	sw	zero,-1674(a5) # 80021254 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800058e6:	00000097          	auipc	ra,0x0
    800058ea:	c72080e7          	jalr	-910(ra) # 80005558 <write_head>
    800058ee:	bdf5                	j	800057ea <end_op+0x52>

00000000800058f0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800058f0:	1101                	add	sp,sp,-32
    800058f2:	ec06                	sd	ra,24(sp)
    800058f4:	e822                	sd	s0,16(sp)
    800058f6:	e426                	sd	s1,8(sp)
    800058f8:	e04a                	sd	s2,0(sp)
    800058fa:	1000                	add	s0,sp,32
    800058fc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800058fe:	0001c917          	auipc	s2,0x1c
    80005902:	92a90913          	add	s2,s2,-1750 # 80021228 <log>
    80005906:	854a                	mv	a0,s2
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	5e6080e7          	jalr	1510(ra) # 80002eee <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80005910:	02c92603          	lw	a2,44(s2)
    80005914:	47f5                	li	a5,29
    80005916:	06c7c563          	blt	a5,a2,80005980 <log_write+0x90>
    8000591a:	0001c797          	auipc	a5,0x1c
    8000591e:	92a7a783          	lw	a5,-1750(a5) # 80021244 <log+0x1c>
    80005922:	37fd                	addw	a5,a5,-1
    80005924:	04f65e63          	bge	a2,a5,80005980 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005928:	0001c797          	auipc	a5,0x1c
    8000592c:	9207a783          	lw	a5,-1760(a5) # 80021248 <log+0x20>
    80005930:	06f05063          	blez	a5,80005990 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80005934:	4781                	li	a5,0
    80005936:	06c05563          	blez	a2,800059a0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000593a:	44cc                	lw	a1,12(s1)
    8000593c:	0001c717          	auipc	a4,0x1c
    80005940:	91c70713          	add	a4,a4,-1764 # 80021258 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80005944:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005946:	4314                	lw	a3,0(a4)
    80005948:	04b68c63          	beq	a3,a1,800059a0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000594c:	2785                	addw	a5,a5,1
    8000594e:	0711                	add	a4,a4,4
    80005950:	fef61be3          	bne	a2,a5,80005946 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80005954:	0621                	add	a2,a2,8
    80005956:	060a                	sll	a2,a2,0x2
    80005958:	0001c797          	auipc	a5,0x1c
    8000595c:	8d078793          	add	a5,a5,-1840 # 80021228 <log>
    80005960:	97b2                	add	a5,a5,a2
    80005962:	44d8                	lw	a4,12(s1)
    80005964:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005966:	8526                	mv	a0,s1
    80005968:	00000097          	auipc	ra,0x0
    8000596c:	9bc080e7          	jalr	-1604(ra) # 80005324 <bpin>
    log.lh.n++;
    80005970:	0001c717          	auipc	a4,0x1c
    80005974:	8b870713          	add	a4,a4,-1864 # 80021228 <log>
    80005978:	575c                	lw	a5,44(a4)
    8000597a:	2785                	addw	a5,a5,1
    8000597c:	d75c                	sw	a5,44(a4)
    8000597e:	a82d                	j	800059b8 <log_write+0xc8>
    panic("too big a transaction");
    80005980:	00003517          	auipc	a0,0x3
    80005984:	25050513          	add	a0,a0,592 # 80008bd0 <syscalls+0x468>
    80005988:	ffffc097          	auipc	ra,0xffffc
    8000598c:	858080e7          	jalr	-1960(ra) # 800011e0 <panic>
    panic("log_write outside of trans");
    80005990:	00003517          	auipc	a0,0x3
    80005994:	25850513          	add	a0,a0,600 # 80008be8 <syscalls+0x480>
    80005998:	ffffc097          	auipc	ra,0xffffc
    8000599c:	848080e7          	jalr	-1976(ra) # 800011e0 <panic>
  log.lh.block[i] = b->blockno;
    800059a0:	00878693          	add	a3,a5,8
    800059a4:	068a                	sll	a3,a3,0x2
    800059a6:	0001c717          	auipc	a4,0x1c
    800059aa:	88270713          	add	a4,a4,-1918 # 80021228 <log>
    800059ae:	9736                	add	a4,a4,a3
    800059b0:	44d4                	lw	a3,12(s1)
    800059b2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800059b4:	faf609e3          	beq	a2,a5,80005966 <log_write+0x76>
  }
  release(&log.lock);
    800059b8:	0001c517          	auipc	a0,0x1c
    800059bc:	87050513          	add	a0,a0,-1936 # 80021228 <log>
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	5e2080e7          	jalr	1506(ra) # 80002fa2 <release>
}
    800059c8:	60e2                	ld	ra,24(sp)
    800059ca:	6442                	ld	s0,16(sp)
    800059cc:	64a2                	ld	s1,8(sp)
    800059ce:	6902                	ld	s2,0(sp)
    800059d0:	6105                	add	sp,sp,32
    800059d2:	8082                	ret

00000000800059d4 <fileinit>:
} ftable;  //这是系统的全局打开文件表

/// @brief 初始化文件表
void
fileinit(void)
{
    800059d4:	1141                	add	sp,sp,-16
    800059d6:	e406                	sd	ra,8(sp)
    800059d8:	e022                	sd	s0,0(sp)
    800059da:	0800                	add	s0,sp,16
  // 初始化文件表锁
  initlock(&ftable.lock, "ftable");
    800059dc:	00003597          	auipc	a1,0x3
    800059e0:	22c58593          	add	a1,a1,556 # 80008c08 <syscalls+0x4a0>
    800059e4:	0001c517          	auipc	a0,0x1c
    800059e8:	98c50513          	add	a0,a0,-1652 # 80021370 <ftable>
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	472080e7          	jalr	1138(ra) # 80002e5e <initlock>
}
    800059f4:	60a2                	ld	ra,8(sp)
    800059f6:	6402                	ld	s0,0(sp)
    800059f8:	0141                	add	sp,sp,16
    800059fa:	8082                	ret

00000000800059fc <filealloc>:

/// @brief 分配一个文件结构体。
struct file*
filealloc(void)
{
    800059fc:	1101                	add	sp,sp,-32
    800059fe:	ec06                	sd	ra,24(sp)
    80005a00:	e822                	sd	s0,16(sp)
    80005a02:	e426                	sd	s1,8(sp)
    80005a04:	1000                	add	s0,sp,32
  struct file *f;

  // 获取文件表锁
  acquire(&ftable.lock);
    80005a06:	0001c517          	auipc	a0,0x1c
    80005a0a:	96a50513          	add	a0,a0,-1686 # 80021370 <ftable>
    80005a0e:	ffffd097          	auipc	ra,0xffffd
    80005a12:	4e0080e7          	jalr	1248(ra) # 80002eee <acquire>
  // 遍历文件表寻找空闲的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005a16:	0001c497          	auipc	s1,0x1c
    80005a1a:	97248493          	add	s1,s1,-1678 # 80021388 <ftable+0x18>
    80005a1e:	0001d717          	auipc	a4,0x1d
    80005a22:	90a70713          	add	a4,a4,-1782 # 80022328 <sb>
    if(f->ref == 0){
    80005a26:	40dc                	lw	a5,4(s1)
    80005a28:	cf99                	beqz	a5,80005a46 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005a2a:	02848493          	add	s1,s1,40
    80005a2e:	fee49ce3          	bne	s1,a4,80005a26 <filealloc+0x2a>
      release(&ftable.lock);
      return f;
    }
  }
  // 没有找到空闲的文件结构体
  release(&ftable.lock);
    80005a32:	0001c517          	auipc	a0,0x1c
    80005a36:	93e50513          	add	a0,a0,-1730 # 80021370 <ftable>
    80005a3a:	ffffd097          	auipc	ra,0xffffd
    80005a3e:	568080e7          	jalr	1384(ra) # 80002fa2 <release>
  return 0;
    80005a42:	4481                	li	s1,0
    80005a44:	a819                	j	80005a5a <filealloc+0x5e>
      f->ref = 1;
    80005a46:	4785                	li	a5,1
    80005a48:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005a4a:	0001c517          	auipc	a0,0x1c
    80005a4e:	92650513          	add	a0,a0,-1754 # 80021370 <ftable>
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	550080e7          	jalr	1360(ra) # 80002fa2 <release>
}
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	60e2                	ld	ra,24(sp)
    80005a5e:	6442                	ld	s0,16(sp)
    80005a60:	64a2                	ld	s1,8(sp)
    80005a62:	6105                	add	sp,sp,32
    80005a64:	8082                	ret

0000000080005a66 <filedup>:

/// @brief 增加文件f的引用计数。
struct file*
filedup(struct file *f)
{
    80005a66:	1101                	add	sp,sp,-32
    80005a68:	ec06                	sd	ra,24(sp)
    80005a6a:	e822                	sd	s0,16(sp)
    80005a6c:	e426                	sd	s1,8(sp)
    80005a6e:	1000                	add	s0,sp,32
    80005a70:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005a72:	0001c517          	auipc	a0,0x1c
    80005a76:	8fe50513          	add	a0,a0,-1794 # 80021370 <ftable>
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	474080e7          	jalr	1140(ra) # 80002eee <acquire>
  // 检查文件引用计数的有效性
  if(f->ref < 1)
    80005a82:	40dc                	lw	a5,4(s1)
    80005a84:	02f05263          	blez	a5,80005aa8 <filedup+0x42>
    panic("filedup");
  // 增加引用计数
  f->ref++;
    80005a88:	2785                	addw	a5,a5,1
    80005a8a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005a8c:	0001c517          	auipc	a0,0x1c
    80005a90:	8e450513          	add	a0,a0,-1820 # 80021370 <ftable>
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	50e080e7          	jalr	1294(ra) # 80002fa2 <release>
  return f;
}
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	60e2                	ld	ra,24(sp)
    80005aa0:	6442                	ld	s0,16(sp)
    80005aa2:	64a2                	ld	s1,8(sp)
    80005aa4:	6105                	add	sp,sp,32
    80005aa6:	8082                	ret
    panic("filedup");
    80005aa8:	00003517          	auipc	a0,0x3
    80005aac:	16850513          	add	a0,a0,360 # 80008c10 <syscalls+0x4a8>
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	730080e7          	jalr	1840(ra) # 800011e0 <panic>

0000000080005ab8 <fileclose>:

/// @brief 关闭文件f。（减少引用计数，当引用计数达到0时关闭。）
void
fileclose(struct file *f)
{
    80005ab8:	7139                	add	sp,sp,-64
    80005aba:	fc06                	sd	ra,56(sp)
    80005abc:	f822                	sd	s0,48(sp)
    80005abe:	f426                	sd	s1,40(sp)
    80005ac0:	f04a                	sd	s2,32(sp)
    80005ac2:	ec4e                	sd	s3,24(sp)
    80005ac4:	e852                	sd	s4,16(sp)
    80005ac6:	e456                	sd	s5,8(sp)
    80005ac8:	0080                	add	s0,sp,64
    80005aca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005acc:	0001c517          	auipc	a0,0x1c
    80005ad0:	8a450513          	add	a0,a0,-1884 # 80021370 <ftable>
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	41a080e7          	jalr	1050(ra) # 80002eee <acquire>
  // 检查文件引用计数的有效性
  if(f->ref < 1)
    80005adc:	40dc                	lw	a5,4(s1)
    80005ade:	06f05163          	blez	a5,80005b40 <fileclose+0x88>
    panic("fileclose");
  // 减少引用计数，如果仍有其他引用则直接返回
  if(--f->ref > 0){
    80005ae2:	37fd                	addw	a5,a5,-1
    80005ae4:	0007871b          	sext.w	a4,a5
    80005ae8:	c0dc                	sw	a5,4(s1)
    80005aea:	06e04363          	bgtz	a4,80005b50 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  // 保存文件信息的副本
  ff = *f;
    80005aee:	0004a903          	lw	s2,0(s1)
    80005af2:	0094ca83          	lbu	s5,9(s1)
    80005af6:	0104ba03          	ld	s4,16(s1)
    80005afa:	0184b983          	ld	s3,24(s1)
  // 清除文件表项
  f->ref = 0;
    80005afe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005b02:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005b06:	0001c517          	auipc	a0,0x1c
    80005b0a:	86a50513          	add	a0,a0,-1942 # 80021370 <ftable>
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	494080e7          	jalr	1172(ra) # 80002fa2 <release>

  // 根据文件类型进行相应的清理工作
  if(ff.type == FD_PIPE){
    80005b16:	4785                	li	a5,1
    80005b18:	04f90d63          	beq	s2,a5,80005b72 <fileclose+0xba>
    // 关闭管道
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005b1c:	3979                	addw	s2,s2,-2
    80005b1e:	4785                	li	a5,1
    80005b20:	0527e063          	bltu	a5,s2,80005b60 <fileclose+0xa8>
    // 释放inode引用
    //对于涉及文件系统的操作，还需要begin_op和end_op
    //在进行一个inode操作前后，必须添加这种资源获取与释放的对应操作
    //详情参看实验指导书8.6代码：日志（https://xv6.dgs.zone/tranlate_books/book-riscv-rev1/c8/s6.html）
    begin_op();
    80005b24:	00000097          	auipc	ra,0x0
    80005b28:	bfa080e7          	jalr	-1030(ra) # 8000571e <begin_op>
    iput(ff.ip);
    80005b2c:	854e                	mv	a0,s3
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	118080e7          	jalr	280(ra) # 80004c46 <iput>
    end_op();
    80005b36:	00000097          	auipc	ra,0x0
    80005b3a:	c62080e7          	jalr	-926(ra) # 80005798 <end_op>
    80005b3e:	a00d                	j	80005b60 <fileclose+0xa8>
    panic("fileclose");
    80005b40:	00003517          	auipc	a0,0x3
    80005b44:	0d850513          	add	a0,a0,216 # 80008c18 <syscalls+0x4b0>
    80005b48:	ffffb097          	auipc	ra,0xffffb
    80005b4c:	698080e7          	jalr	1688(ra) # 800011e0 <panic>
    release(&ftable.lock);
    80005b50:	0001c517          	auipc	a0,0x1c
    80005b54:	82050513          	add	a0,a0,-2016 # 80021370 <ftable>
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	44a080e7          	jalr	1098(ra) # 80002fa2 <release>
  }
}
    80005b60:	70e2                	ld	ra,56(sp)
    80005b62:	7442                	ld	s0,48(sp)
    80005b64:	74a2                	ld	s1,40(sp)
    80005b66:	7902                	ld	s2,32(sp)
    80005b68:	69e2                	ld	s3,24(sp)
    80005b6a:	6a42                	ld	s4,16(sp)
    80005b6c:	6aa2                	ld	s5,8(sp)
    80005b6e:	6121                	add	sp,sp,64
    80005b70:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005b72:	85d6                	mv	a1,s5
    80005b74:	8552                	mv	a0,s4
    80005b76:	00001097          	auipc	ra,0x1
    80005b7a:	8fc080e7          	jalr	-1796(ra) # 80006472 <pipeclose>
    80005b7e:	b7cd                	j	80005b60 <fileclose+0xa8>

0000000080005b80 <filestat>:

/// @brief 获取文件f的元数据。
/// addr是用户虚拟地址，指向struct stat。
int
filestat(struct file *f, uint64 addr)
{
    80005b80:	715d                	add	sp,sp,-80
    80005b82:	e486                	sd	ra,72(sp)
    80005b84:	e0a2                	sd	s0,64(sp)
    80005b86:	fc26                	sd	s1,56(sp)
    80005b88:	f84a                	sd	s2,48(sp)
    80005b8a:	f44e                	sd	s3,40(sp)
    80005b8c:	0880                	add	s0,sp,80
    80005b8e:	84aa                	mv	s1,a0
    80005b90:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	57c080e7          	jalr	1404(ra) # 8000210e <myproc>
  struct stat st;
  
  // 只有inode和设备文件支持stat操作
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005b9a:	409c                	lw	a5,0(s1)
    80005b9c:	37f9                	addw	a5,a5,-2
    80005b9e:	4705                	li	a4,1
    80005ba0:	04f76763          	bltu	a4,a5,80005bee <filestat+0x6e>
    80005ba4:	892a                	mv	s2,a0
    // 锁定inode并获取stat信息
    ilock(f->ip);
    80005ba6:	6c88                	ld	a0,24(s1)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	ee4080e7          	jalr	-284(ra) # 80004a8c <ilock>
    stati(f->ip, &st);
    80005bb0:	fb840593          	add	a1,s0,-72
    80005bb4:	6c88                	ld	a0,24(s1)
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	160080e7          	jalr	352(ra) # 80004d16 <stati>
    iunlock(f->ip);
    80005bbe:	6c88                	ld	a0,24(s1)
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	f8e080e7          	jalr	-114(ra) # 80004b4e <iunlock>
    // 将stat信息复制到用户空间
    if(copyout(p->pgtbl, addr, (char *)&st, sizeof(st)) < 0)
    80005bc8:	46e1                	li	a3,24
    80005bca:	fb840613          	add	a2,s0,-72
    80005bce:	85ce                	mv	a1,s3
    80005bd0:	04893503          	ld	a0,72(s2)
    80005bd4:	ffffc097          	auipc	ra,0xffffc
    80005bd8:	338080e7          	jalr	824(ra) # 80001f0c <copyout>
    80005bdc:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005be0:	60a6                	ld	ra,72(sp)
    80005be2:	6406                	ld	s0,64(sp)
    80005be4:	74e2                	ld	s1,56(sp)
    80005be6:	7942                	ld	s2,48(sp)
    80005be8:	79a2                	ld	s3,40(sp)
    80005bea:	6161                	add	sp,sp,80
    80005bec:	8082                	ret
  return -1;
    80005bee:	557d                	li	a0,-1
    80005bf0:	bfc5                	j	80005be0 <filestat+0x60>

0000000080005bf2 <fileread>:

/// @brief 从文件f读取数据。
/// addr是用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    80005bf2:	7179                	add	sp,sp,-48
    80005bf4:	f406                	sd	ra,40(sp)
    80005bf6:	f022                	sd	s0,32(sp)
    80005bf8:	ec26                	sd	s1,24(sp)
    80005bfa:	e84a                	sd	s2,16(sp)
    80005bfc:	e44e                	sd	s3,8(sp)
    80005bfe:	1800                	add	s0,sp,48
  int r = 0;

  // 检查文件是否可读
  if(f->readable == 0)
    80005c00:	00854783          	lbu	a5,8(a0)
    80005c04:	c3d5                	beqz	a5,80005ca8 <fileread+0xb6>
    80005c06:	84aa                	mv	s1,a0
    80005c08:	89ae                	mv	s3,a1
    80005c0a:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    80005c0c:	411c                	lw	a5,0(a0)
    80005c0e:	4705                	li	a4,1
    80005c10:	04e78963          	beq	a5,a4,80005c62 <fileread+0x70>
    // 从管道读取
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005c14:	470d                	li	a4,3
    80005c16:	04e78d63          	beq	a5,a4,80005c70 <fileread+0x7e>
    // 从设备读取
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005c1a:	4709                	li	a4,2
    80005c1c:	06e79e63          	bne	a5,a4,80005c98 <fileread+0xa6>
    // 从inode文件读取
    ilock(f->ip);
    80005c20:	6d08                	ld	a0,24(a0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	e6a080e7          	jalr	-406(ra) # 80004a8c <ilock>
    // 从当前偏移量处读取数据
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005c2a:	874a                	mv	a4,s2
    80005c2c:	5094                	lw	a3,32(s1)
    80005c2e:	864e                	mv	a2,s3
    80005c30:	4585                	li	a1,1
    80005c32:	6c88                	ld	a0,24(s1)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	10c080e7          	jalr	268(ra) # 80004d40 <readi>
    80005c3c:	892a                	mv	s2,a0
    80005c3e:	00a05563          	blez	a0,80005c48 <fileread+0x56>
      f->off += r; // 更新文件偏移量
    80005c42:	509c                	lw	a5,32(s1)
    80005c44:	9fa9                	addw	a5,a5,a0
    80005c46:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005c48:	6c88                	ld	a0,24(s1)
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	f04080e7          	jalr	-252(ra) # 80004b4e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005c52:	854a                	mv	a0,s2
    80005c54:	70a2                	ld	ra,40(sp)
    80005c56:	7402                	ld	s0,32(sp)
    80005c58:	64e2                	ld	s1,24(sp)
    80005c5a:	6942                	ld	s2,16(sp)
    80005c5c:	69a2                	ld	s3,8(sp)
    80005c5e:	6145                	add	sp,sp,48
    80005c60:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005c62:	6908                	ld	a0,16(a0)
    80005c64:	00001097          	auipc	ra,0x1
    80005c68:	978080e7          	jalr	-1672(ra) # 800065dc <piperead>
    80005c6c:	892a                	mv	s2,a0
    80005c6e:	b7d5                	j	80005c52 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005c70:	02451783          	lh	a5,36(a0)
    80005c74:	03079693          	sll	a3,a5,0x30
    80005c78:	92c1                	srl	a3,a3,0x30
    80005c7a:	4725                	li	a4,9
    80005c7c:	02d76863          	bltu	a4,a3,80005cac <fileread+0xba>
    80005c80:	0792                	sll	a5,a5,0x4
    80005c82:	0001b717          	auipc	a4,0x1b
    80005c86:	64e70713          	add	a4,a4,1614 # 800212d0 <devsw>
    80005c8a:	97ba                	add	a5,a5,a4
    80005c8c:	639c                	ld	a5,0(a5)
    80005c8e:	c38d                	beqz	a5,80005cb0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005c90:	4505                	li	a0,1
    80005c92:	9782                	jalr	a5
    80005c94:	892a                	mv	s2,a0
    80005c96:	bf75                	j	80005c52 <fileread+0x60>
    panic("fileread");
    80005c98:	00003517          	auipc	a0,0x3
    80005c9c:	f9050513          	add	a0,a0,-112 # 80008c28 <syscalls+0x4c0>
    80005ca0:	ffffb097          	auipc	ra,0xffffb
    80005ca4:	540080e7          	jalr	1344(ra) # 800011e0 <panic>
    return -1;
    80005ca8:	597d                	li	s2,-1
    80005caa:	b765                	j	80005c52 <fileread+0x60>
      return -1;
    80005cac:	597d                	li	s2,-1
    80005cae:	b755                	j	80005c52 <fileread+0x60>
    80005cb0:	597d                	li	s2,-1
    80005cb2:	b745                	j	80005c52 <fileread+0x60>

0000000080005cb4 <filewrite>:
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  // 检查文件是否可写
  if(f->writable == 0)
    80005cb4:	00954783          	lbu	a5,9(a0)
    80005cb8:	10078e63          	beqz	a5,80005dd4 <filewrite+0x120>
{
    80005cbc:	715d                	add	sp,sp,-80
    80005cbe:	e486                	sd	ra,72(sp)
    80005cc0:	e0a2                	sd	s0,64(sp)
    80005cc2:	fc26                	sd	s1,56(sp)
    80005cc4:	f84a                	sd	s2,48(sp)
    80005cc6:	f44e                	sd	s3,40(sp)
    80005cc8:	f052                	sd	s4,32(sp)
    80005cca:	ec56                	sd	s5,24(sp)
    80005ccc:	e85a                	sd	s6,16(sp)
    80005cce:	e45e                	sd	s7,8(sp)
    80005cd0:	e062                	sd	s8,0(sp)
    80005cd2:	0880                	add	s0,sp,80
    80005cd4:	892a                	mv	s2,a0
    80005cd6:	8b2e                	mv	s6,a1
    80005cd8:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    80005cda:	411c                	lw	a5,0(a0)
    80005cdc:	4705                	li	a4,1
    80005cde:	02e78263          	beq	a5,a4,80005d02 <filewrite+0x4e>
    // 向管道写入
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005ce2:	470d                	li	a4,3
    80005ce4:	02e78563          	beq	a5,a4,80005d0e <filewrite+0x5a>
    // 向设备写入
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005ce8:	4709                	li	a4,2
    80005cea:	0ce79d63          	bne	a5,a4,80005dc4 <filewrite+0x110>
    // 这实际上应该在更低层，因为writei()
    // 可能正在写入像控制台这样的设备。
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    // 分批写入数据
    while(i < n){
    80005cee:	0ac05b63          	blez	a2,80005da4 <filewrite+0xf0>
    int i = 0;
    80005cf2:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80005cf4:	6b85                	lui	s7,0x1
    80005cf6:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005cfa:	6c05                	lui	s8,0x1
    80005cfc:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005d00:	a851                	j	80005d94 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80005d02:	6908                	ld	a0,16(a0)
    80005d04:	00000097          	auipc	ra,0x0
    80005d08:	7e0080e7          	jalr	2016(ra) # 800064e4 <pipewrite>
    80005d0c:	a045                	j	80005dac <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005d0e:	02451783          	lh	a5,36(a0)
    80005d12:	03079693          	sll	a3,a5,0x30
    80005d16:	92c1                	srl	a3,a3,0x30
    80005d18:	4725                	li	a4,9
    80005d1a:	0ad76f63          	bltu	a4,a3,80005dd8 <filewrite+0x124>
    80005d1e:	0792                	sll	a5,a5,0x4
    80005d20:	0001b717          	auipc	a4,0x1b
    80005d24:	5b070713          	add	a4,a4,1456 # 800212d0 <devsw>
    80005d28:	97ba                	add	a5,a5,a4
    80005d2a:	679c                	ld	a5,8(a5)
    80005d2c:	cbc5                	beqz	a5,80005ddc <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80005d2e:	4505                	li	a0,1
    80005d30:	9782                	jalr	a5
    80005d32:	a8ad                	j	80005dac <filewrite+0xf8>
      if(n1 > max)
    80005d34:	00048a9b          	sext.w	s5,s1
        n1 = max;

      // 开始操作事务
      begin_op();
    80005d38:	00000097          	auipc	ra,0x0
    80005d3c:	9e6080e7          	jalr	-1562(ra) # 8000571e <begin_op>
      ilock(f->ip);
    80005d40:	01893503          	ld	a0,24(s2)
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	d48080e7          	jalr	-696(ra) # 80004a8c <ilock>
      // 写入数据并更新文件偏移量
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005d4c:	8756                	mv	a4,s5
    80005d4e:	02092683          	lw	a3,32(s2)
    80005d52:	01698633          	add	a2,s3,s6
    80005d56:	4585                	li	a1,1
    80005d58:	01893503          	ld	a0,24(s2)
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	0dc080e7          	jalr	220(ra) # 80004e38 <writei>
    80005d64:	84aa                	mv	s1,a0
    80005d66:	00a05763          	blez	a0,80005d74 <filewrite+0xc0>
        f->off += r;
    80005d6a:	02092783          	lw	a5,32(s2)
    80005d6e:	9fa9                	addw	a5,a5,a0
    80005d70:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005d74:	01893503          	ld	a0,24(s2)
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	dd6080e7          	jalr	-554(ra) # 80004b4e <iunlock>
      // 结束操作事务
      end_op();
    80005d80:	00000097          	auipc	ra,0x0
    80005d84:	a18080e7          	jalr	-1512(ra) # 80005798 <end_op>

      // 检查写入是否成功
      if(r != n1){
    80005d88:	009a9f63          	bne	s5,s1,80005da6 <filewrite+0xf2>
        // writei出错
        break;
      }
      i += r;
    80005d8c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005d90:	0149db63          	bge	s3,s4,80005da6 <filewrite+0xf2>
      int n1 = n - i;
    80005d94:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80005d98:	0004879b          	sext.w	a5,s1
    80005d9c:	f8fbdce3          	bge	s7,a5,80005d34 <filewrite+0x80>
    80005da0:	84e2                	mv	s1,s8
    80005da2:	bf49                	j	80005d34 <filewrite+0x80>
    int i = 0;
    80005da4:	4981                	li	s3,0
    }
    // 如果全部写入成功返回n，否则返回-1
    ret = (i == n ? n : -1);
    80005da6:	033a1d63          	bne	s4,s3,80005de0 <filewrite+0x12c>
    80005daa:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005dac:	60a6                	ld	ra,72(sp)
    80005dae:	6406                	ld	s0,64(sp)
    80005db0:	74e2                	ld	s1,56(sp)
    80005db2:	7942                	ld	s2,48(sp)
    80005db4:	79a2                	ld	s3,40(sp)
    80005db6:	7a02                	ld	s4,32(sp)
    80005db8:	6ae2                	ld	s5,24(sp)
    80005dba:	6b42                	ld	s6,16(sp)
    80005dbc:	6ba2                	ld	s7,8(sp)
    80005dbe:	6c02                	ld	s8,0(sp)
    80005dc0:	6161                	add	sp,sp,80
    80005dc2:	8082                	ret
    panic("filewrite");
    80005dc4:	00003517          	auipc	a0,0x3
    80005dc8:	e7450513          	add	a0,a0,-396 # 80008c38 <syscalls+0x4d0>
    80005dcc:	ffffb097          	auipc	ra,0xffffb
    80005dd0:	414080e7          	jalr	1044(ra) # 800011e0 <panic>
    return -1;
    80005dd4:	557d                	li	a0,-1
}
    80005dd6:	8082                	ret
      return -1;
    80005dd8:	557d                	li	a0,-1
    80005dda:	bfc9                	j	80005dac <filewrite+0xf8>
    80005ddc:	557d                	li	a0,-1
    80005dde:	b7f9                	j	80005dac <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80005de0:	557d                	li	a0,-1
    80005de2:	b7e9                	j	80005dac <filewrite+0xf8>

0000000080005de4 <file_lseek>:

// 修改file->offset (只针对FD_FILE类型的文件)
uint32 file_lseek(struct file* file , uint32 offset, int flags)
{
  if(file->type != FD_INODE){
    80005de4:	4118                	lw	a4,0(a0)
    80005de6:	4789                	li	a5,2
    80005de8:	00f70463          	beq	a4,a5,80005df0 <file_lseek+0xc>
    return -1;
    80005dec:	557d                	li	a0,-1
  }

  file->off = new_offset;
  iunlock(file->ip);
  return new_offset;
}
    80005dee:	8082                	ret
{
    80005df0:	7179                	add	sp,sp,-48
    80005df2:	f406                	sd	ra,40(sp)
    80005df4:	f022                	sd	s0,32(sp)
    80005df6:	ec26                	sd	s1,24(sp)
    80005df8:	e84a                	sd	s2,16(sp)
    80005dfa:	e44e                	sd	s3,8(sp)
    80005dfc:	1800                	add	s0,sp,48
    80005dfe:	89aa                	mv	s3,a0
    80005e00:	84ae                	mv	s1,a1
    80005e02:	8932                	mv	s2,a2
  ilock(file->ip);
    80005e04:	6d08                	ld	a0,24(a0)
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	c86080e7          	jalr	-890(ra) # 80004a8c <ilock>
  switch(flags){
    80005e0e:	4785                	li	a5,1
    80005e10:	00f90f63          	beq	s2,a5,80005e2e <file_lseek+0x4a>
    80005e14:	4789                	li	a5,2
    80005e16:	04f90263          	beq	s2,a5,80005e5a <file_lseek+0x76>
    80005e1a:	00090d63          	beqz	s2,80005e34 <file_lseek+0x50>
      iunlock(file->ip);
    80005e1e:	0189b503          	ld	a0,24(s3)
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	d2c080e7          	jalr	-724(ra) # 80004b4e <iunlock>
      return -1;
    80005e2a:	557d                	li	a0,-1
    80005e2c:	a005                	j	80005e4c <file_lseek+0x68>
      new_offset = file->off + offset;
    80005e2e:	0209a783          	lw	a5,32(s3)
    80005e32:	9cbd                	addw	s1,s1,a5
  if(new_offset > file->ip->size){
    80005e34:	0189b503          	ld	a0,24(s3)
    80005e38:	457c                	lw	a5,76(a0)
    80005e3a:	0297e563          	bltu	a5,s1,80005e64 <file_lseek+0x80>
  file->off = new_offset;
    80005e3e:	0299a023          	sw	s1,32(s3)
  iunlock(file->ip);
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	d0c080e7          	jalr	-756(ra) # 80004b4e <iunlock>
  return new_offset;
    80005e4a:	8526                	mv	a0,s1
}
    80005e4c:	70a2                	ld	ra,40(sp)
    80005e4e:	7402                	ld	s0,32(sp)
    80005e50:	64e2                	ld	s1,24(sp)
    80005e52:	6942                	ld	s2,16(sp)
    80005e54:	69a2                	ld	s3,8(sp)
    80005e56:	6145                	add	sp,sp,48
    80005e58:	8082                	ret
      new_offset = file->ip->size + offset;
    80005e5a:	0189b783          	ld	a5,24(s3)
    80005e5e:	47fc                	lw	a5,76(a5)
    80005e60:	9cbd                	addw	s1,s1,a5
      break;
    80005e62:	bfc9                	j	80005e34 <file_lseek+0x50>
    iunlock(file->ip);
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	cea080e7          	jalr	-790(ra) # 80004b4e <iunlock>
    return -1;
    80005e6c:	557d                	li	a0,-1
    80005e6e:	bff9                	j	80005e4c <file_lseek+0x68>

0000000080005e70 <namecmp>:
#include "fs.h"
#include "buf.h"
#include "file.h"

int namecmp(const char *s, const char *t)
{
    80005e70:	1141                	add	sp,sp,-16
    80005e72:	e406                	sd	ra,8(sp)
    80005e74:	e022                	sd	s0,0(sp)
    80005e76:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80005e78:	4639                	li	a2,14
    80005e7a:	ffffb097          	auipc	ra,0xffffb
    80005e7e:	1ee080e7          	jalr	494(ra) # 80001068 <strncmp>
}
    80005e82:	60a2                	ld	ra,8(sp)
    80005e84:	6402                	ld	s0,0(sp)
    80005e86:	0141                	add	sp,sp,16
    80005e88:	8082                	ret

0000000080005e8a <dirlookup>:

struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80005e8a:	7139                	add	sp,sp,-64
    80005e8c:	fc06                	sd	ra,56(sp)
    80005e8e:	f822                	sd	s0,48(sp)
    80005e90:	f426                	sd	s1,40(sp)
    80005e92:	f04a                	sd	s2,32(sp)
    80005e94:	ec4e                	sd	s3,24(sp)
    80005e96:	e852                	sd	s4,16(sp)
    80005e98:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if (dp->type != T_DIR)
    80005e9a:	04451703          	lh	a4,68(a0)
    80005e9e:	4785                	li	a5,1
    80005ea0:	00f71a63          	bne	a4,a5,80005eb4 <dirlookup+0x2a>
    80005ea4:	892a                	mv	s2,a0
    80005ea6:	89ae                	mv	s3,a1
    80005ea8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for (off = 0; off < dp->size; off += sizeof(de))
    80005eaa:	457c                	lw	a5,76(a0)
    80005eac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80005eae:	4501                	li	a0,0
  for (off = 0; off < dp->size; off += sizeof(de))
    80005eb0:	e79d                	bnez	a5,80005ede <dirlookup+0x54>
    80005eb2:	a8a5                	j	80005f2a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80005eb4:	00003517          	auipc	a0,0x3
    80005eb8:	d9450513          	add	a0,a0,-620 # 80008c48 <syscalls+0x4e0>
    80005ebc:	ffffb097          	auipc	ra,0xffffb
    80005ec0:	324080e7          	jalr	804(ra) # 800011e0 <panic>
      panic("dirlookup read");
    80005ec4:	00003517          	auipc	a0,0x3
    80005ec8:	d9c50513          	add	a0,a0,-612 # 80008c60 <syscalls+0x4f8>
    80005ecc:	ffffb097          	auipc	ra,0xffffb
    80005ed0:	314080e7          	jalr	788(ra) # 800011e0 <panic>
  for (off = 0; off < dp->size; off += sizeof(de))
    80005ed4:	24c1                	addw	s1,s1,16
    80005ed6:	04c92783          	lw	a5,76(s2)
    80005eda:	04f4f763          	bgeu	s1,a5,80005f28 <dirlookup+0x9e>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ede:	4741                	li	a4,16
    80005ee0:	86a6                	mv	a3,s1
    80005ee2:	fc040613          	add	a2,s0,-64
    80005ee6:	4581                	li	a1,0
    80005ee8:	854a                	mv	a0,s2
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	e56080e7          	jalr	-426(ra) # 80004d40 <readi>
    80005ef2:	47c1                	li	a5,16
    80005ef4:	fcf518e3          	bne	a0,a5,80005ec4 <dirlookup+0x3a>
    if (de.inum == 0)
    80005ef8:	fc045783          	lhu	a5,-64(s0)
    80005efc:	dfe1                	beqz	a5,80005ed4 <dirlookup+0x4a>
    if (namecmp(name, de.name) == 0)
    80005efe:	fc240593          	add	a1,s0,-62
    80005f02:	854e                	mv	a0,s3
    80005f04:	00000097          	auipc	ra,0x0
    80005f08:	f6c080e7          	jalr	-148(ra) # 80005e70 <namecmp>
    80005f0c:	f561                	bnez	a0,80005ed4 <dirlookup+0x4a>
      if (poff)
    80005f0e:	000a0463          	beqz	s4,80005f16 <dirlookup+0x8c>
        *poff = off;
    80005f12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80005f16:	fc045583          	lhu	a1,-64(s0)
    80005f1a:	00092503          	lw	a0,0(s2)
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	91a080e7          	jalr	-1766(ra) # 80004838 <iget>
    80005f26:	a011                	j	80005f2a <dirlookup+0xa0>
  return 0;
    80005f28:	4501                	li	a0,0
}
    80005f2a:	70e2                	ld	ra,56(sp)
    80005f2c:	7442                	ld	s0,48(sp)
    80005f2e:	74a2                	ld	s1,40(sp)
    80005f30:	7902                	ld	s2,32(sp)
    80005f32:	69e2                	ld	s3,24(sp)
    80005f34:	6a42                	ld	s4,16(sp)
    80005f36:	6121                	add	sp,sp,64
    80005f38:	8082                	ret

0000000080005f3a <namex>:
  return path;
}

static struct inode *
namex(char *path, int nameiparent, char *name)
{
    80005f3a:	711d                	add	sp,sp,-96
    80005f3c:	ec86                	sd	ra,88(sp)
    80005f3e:	e8a2                	sd	s0,80(sp)
    80005f40:	e4a6                	sd	s1,72(sp)
    80005f42:	e0ca                	sd	s2,64(sp)
    80005f44:	fc4e                	sd	s3,56(sp)
    80005f46:	f852                	sd	s4,48(sp)
    80005f48:	f456                	sd	s5,40(sp)
    80005f4a:	f05a                	sd	s6,32(sp)
    80005f4c:	ec5e                	sd	s7,24(sp)
    80005f4e:	e862                	sd	s8,16(sp)
    80005f50:	e466                	sd	s9,8(sp)
    80005f52:	1080                	add	s0,sp,96
    80005f54:	84aa                	mv	s1,a0
    80005f56:	8b2e                	mv	s6,a1
    80005f58:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if (*path == '/')
    80005f5a:	00054703          	lbu	a4,0(a0)
    80005f5e:	02f00793          	li	a5,47
    80005f62:	02f70163          	beq	a4,a5,80005f84 <namex+0x4a>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80005f66:	ffffc097          	auipc	ra,0xffffc
    80005f6a:	1a8080e7          	jalr	424(ra) # 8000210e <myproc>
    80005f6e:	7168                	ld	a0,224(a0)
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	ade080e7          	jalr	-1314(ra) # 80004a4e <idup>
    80005f78:	8a2a                	mv	s4,a0
  while (*path == '/')
    80005f7a:	02f00913          	li	s2,47
  if (len >= DIRSIZ)
    80005f7e:	4c35                	li	s8,13

  while ((path = skipelem(path, name)) != 0)
  {
    ilock(ip);
    if (ip->type != T_DIR)
    80005f80:	4b85                	li	s7,1
    80005f82:	a875                	j	8000603e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80005f84:	4585                	li	a1,1
    80005f86:	4505                	li	a0,1
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	8b0080e7          	jalr	-1872(ra) # 80004838 <iget>
    80005f90:	8a2a                	mv	s4,a0
    80005f92:	b7e5                	j	80005f7a <namex+0x40>
    {
      iunlockput(ip);
    80005f94:	8552                	mv	a0,s4
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	d58080e7          	jalr	-680(ra) # 80004cee <iunlockput>
      return 0;
    80005f9e:	4a01                	li	s4,0
  {
    iput(ip);
    return 0;
  }
  return ip;
}
    80005fa0:	8552                	mv	a0,s4
    80005fa2:	60e6                	ld	ra,88(sp)
    80005fa4:	6446                	ld	s0,80(sp)
    80005fa6:	64a6                	ld	s1,72(sp)
    80005fa8:	6906                	ld	s2,64(sp)
    80005faa:	79e2                	ld	s3,56(sp)
    80005fac:	7a42                	ld	s4,48(sp)
    80005fae:	7aa2                	ld	s5,40(sp)
    80005fb0:	7b02                	ld	s6,32(sp)
    80005fb2:	6be2                	ld	s7,24(sp)
    80005fb4:	6c42                	ld	s8,16(sp)
    80005fb6:	6ca2                	ld	s9,8(sp)
    80005fb8:	6125                	add	sp,sp,96
    80005fba:	8082                	ret
      iunlock(ip);
    80005fbc:	8552                	mv	a0,s4
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	b90080e7          	jalr	-1136(ra) # 80004b4e <iunlock>
      return ip;
    80005fc6:	bfe9                	j	80005fa0 <namex+0x66>
      iunlockput(ip);
    80005fc8:	8552                	mv	a0,s4
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	d24080e7          	jalr	-732(ra) # 80004cee <iunlockput>
      return 0;
    80005fd2:	8a4e                	mv	s4,s3
    80005fd4:	b7f1                	j	80005fa0 <namex+0x66>
  len = path - s;
    80005fd6:	40998633          	sub	a2,s3,s1
    80005fda:	00060c9b          	sext.w	s9,a2
  if (len >= DIRSIZ)
    80005fde:	099c5863          	bge	s8,s9,8000606e <namex+0x134>
    memmove(name, s, DIRSIZ);
    80005fe2:	4639                	li	a2,14
    80005fe4:	85a6                	mv	a1,s1
    80005fe6:	8556                	mv	a0,s5
    80005fe8:	ffffb097          	auipc	ra,0xffffb
    80005fec:	00c080e7          	jalr	12(ra) # 80000ff4 <memmove>
    80005ff0:	84ce                	mv	s1,s3
  while (*path == '/')
    80005ff2:	0004c783          	lbu	a5,0(s1)
    80005ff6:	01279763          	bne	a5,s2,80006004 <namex+0xca>
    path++;
    80005ffa:	0485                	add	s1,s1,1
  while (*path == '/')
    80005ffc:	0004c783          	lbu	a5,0(s1)
    80006000:	ff278de3          	beq	a5,s2,80005ffa <namex+0xc0>
    ilock(ip);
    80006004:	8552                	mv	a0,s4
    80006006:	fffff097          	auipc	ra,0xfffff
    8000600a:	a86080e7          	jalr	-1402(ra) # 80004a8c <ilock>
    if (ip->type != T_DIR)
    8000600e:	044a1783          	lh	a5,68(s4)
    80006012:	f97791e3          	bne	a5,s7,80005f94 <namex+0x5a>
    if (nameiparent && *path == '\0')
    80006016:	000b0563          	beqz	s6,80006020 <namex+0xe6>
    8000601a:	0004c783          	lbu	a5,0(s1)
    8000601e:	dfd9                	beqz	a5,80005fbc <namex+0x82>
    if ((next = dirlookup(ip, name, 0)) == 0)
    80006020:	4601                	li	a2,0
    80006022:	85d6                	mv	a1,s5
    80006024:	8552                	mv	a0,s4
    80006026:	00000097          	auipc	ra,0x0
    8000602a:	e64080e7          	jalr	-412(ra) # 80005e8a <dirlookup>
    8000602e:	89aa                	mv	s3,a0
    80006030:	dd41                	beqz	a0,80005fc8 <namex+0x8e>
    iunlockput(ip);
    80006032:	8552                	mv	a0,s4
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	cba080e7          	jalr	-838(ra) # 80004cee <iunlockput>
    ip = next;
    8000603c:	8a4e                	mv	s4,s3
  while (*path == '/')
    8000603e:	0004c783          	lbu	a5,0(s1)
    80006042:	01279763          	bne	a5,s2,80006050 <namex+0x116>
    path++;
    80006046:	0485                	add	s1,s1,1
  while (*path == '/')
    80006048:	0004c783          	lbu	a5,0(s1)
    8000604c:	ff278de3          	beq	a5,s2,80006046 <namex+0x10c>
  if (*path == 0)
    80006050:	cb9d                	beqz	a5,80006086 <namex+0x14c>
  while (*path != '/' && *path != 0)
    80006052:	0004c783          	lbu	a5,0(s1)
    80006056:	89a6                	mv	s3,s1
  len = path - s;
    80006058:	4c81                	li	s9,0
    8000605a:	4601                	li	a2,0
  while (*path != '/' && *path != 0)
    8000605c:	01278963          	beq	a5,s2,8000606e <namex+0x134>
    80006060:	dbbd                	beqz	a5,80005fd6 <namex+0x9c>
    path++;
    80006062:	0985                	add	s3,s3,1
  while (*path != '/' && *path != 0)
    80006064:	0009c783          	lbu	a5,0(s3)
    80006068:	ff279ce3          	bne	a5,s2,80006060 <namex+0x126>
    8000606c:	b7ad                	j	80005fd6 <namex+0x9c>
    memmove(name, s, len);
    8000606e:	2601                	sext.w	a2,a2
    80006070:	85a6                	mv	a1,s1
    80006072:	8556                	mv	a0,s5
    80006074:	ffffb097          	auipc	ra,0xffffb
    80006078:	f80080e7          	jalr	-128(ra) # 80000ff4 <memmove>
    name[len] = 0;
    8000607c:	9cd6                	add	s9,s9,s5
    8000607e:	000c8023          	sb	zero,0(s9)
    80006082:	84ce                	mv	s1,s3
    80006084:	b7bd                	j	80005ff2 <namex+0xb8>
  if (nameiparent)
    80006086:	f00b0de3          	beqz	s6,80005fa0 <namex+0x66>
    iput(ip);
    8000608a:	8552                	mv	a0,s4
    8000608c:	fffff097          	auipc	ra,0xfffff
    80006090:	bba080e7          	jalr	-1094(ra) # 80004c46 <iput>
    return 0;
    80006094:	4a01                	li	s4,0
    80006096:	b729                	j	80005fa0 <namex+0x66>

0000000080006098 <dirlink>:
{
    80006098:	7139                	add	sp,sp,-64
    8000609a:	fc06                	sd	ra,56(sp)
    8000609c:	f822                	sd	s0,48(sp)
    8000609e:	f426                	sd	s1,40(sp)
    800060a0:	f04a                	sd	s2,32(sp)
    800060a2:	ec4e                	sd	s3,24(sp)
    800060a4:	e852                	sd	s4,16(sp)
    800060a6:	0080                	add	s0,sp,64
    800060a8:	892a                	mv	s2,a0
    800060aa:	8a2e                	mv	s4,a1
    800060ac:	89b2                	mv	s3,a2
  if ((ip = dirlookup(dp, name, 0)) != 0)
    800060ae:	4601                	li	a2,0
    800060b0:	00000097          	auipc	ra,0x0
    800060b4:	dda080e7          	jalr	-550(ra) # 80005e8a <dirlookup>
    800060b8:	e93d                	bnez	a0,8000612e <dirlink+0x96>
  for (off = 0; off < dp->size; off += sizeof(de))
    800060ba:	04c92483          	lw	s1,76(s2)
    800060be:	c49d                	beqz	s1,800060ec <dirlink+0x54>
    800060c0:	4481                	li	s1,0
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060c2:	4741                	li	a4,16
    800060c4:	86a6                	mv	a3,s1
    800060c6:	fc040613          	add	a2,s0,-64
    800060ca:	4581                	li	a1,0
    800060cc:	854a                	mv	a0,s2
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	c72080e7          	jalr	-910(ra) # 80004d40 <readi>
    800060d6:	47c1                	li	a5,16
    800060d8:	06f51163          	bne	a0,a5,8000613a <dirlink+0xa2>
    if (de.inum == 0)
    800060dc:	fc045783          	lhu	a5,-64(s0)
    800060e0:	c791                	beqz	a5,800060ec <dirlink+0x54>
  for (off = 0; off < dp->size; off += sizeof(de))
    800060e2:	24c1                	addw	s1,s1,16
    800060e4:	04c92783          	lw	a5,76(s2)
    800060e8:	fcf4ede3          	bltu	s1,a5,800060c2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800060ec:	4639                	li	a2,14
    800060ee:	85d2                	mv	a1,s4
    800060f0:	fc240513          	add	a0,s0,-62
    800060f4:	ffffb097          	auipc	ra,0xffffb
    800060f8:	fb0080e7          	jalr	-80(ra) # 800010a4 <strncpy>
  de.inum = inum;
    800060fc:	fd341023          	sh	s3,-64(s0)
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006100:	4741                	li	a4,16
    80006102:	86a6                	mv	a3,s1
    80006104:	fc040613          	add	a2,s0,-64
    80006108:	4581                	li	a1,0
    8000610a:	854a                	mv	a0,s2
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	d2c080e7          	jalr	-724(ra) # 80004e38 <writei>
    80006114:	1541                	add	a0,a0,-16
    80006116:	00a03533          	snez	a0,a0
    8000611a:	40a00533          	neg	a0,a0
}
    8000611e:	70e2                	ld	ra,56(sp)
    80006120:	7442                	ld	s0,48(sp)
    80006122:	74a2                	ld	s1,40(sp)
    80006124:	7902                	ld	s2,32(sp)
    80006126:	69e2                	ld	s3,24(sp)
    80006128:	6a42                	ld	s4,16(sp)
    8000612a:	6121                	add	sp,sp,64
    8000612c:	8082                	ret
    iput(ip);
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	b18080e7          	jalr	-1256(ra) # 80004c46 <iput>
    return -1;
    80006136:	557d                	li	a0,-1
    80006138:	b7dd                	j	8000611e <dirlink+0x86>
      panic("dirlink read");
    8000613a:	00003517          	auipc	a0,0x3
    8000613e:	b3650513          	add	a0,a0,-1226 # 80008c70 <syscalls+0x508>
    80006142:	ffffb097          	auipc	ra,0xffffb
    80006146:	09e080e7          	jalr	158(ra) # 800011e0 <panic>

000000008000614a <namei>:

struct inode *
namei(char *path)
{
    8000614a:	1101                	add	sp,sp,-32
    8000614c:	ec06                	sd	ra,24(sp)
    8000614e:	e822                	sd	s0,16(sp)
    80006150:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80006152:	fe040613          	add	a2,s0,-32
    80006156:	4581                	li	a1,0
    80006158:	00000097          	auipc	ra,0x0
    8000615c:	de2080e7          	jalr	-542(ra) # 80005f3a <namex>
}
    80006160:	60e2                	ld	ra,24(sp)
    80006162:	6442                	ld	s0,16(sp)
    80006164:	6105                	add	sp,sp,32
    80006166:	8082                	ret

0000000080006168 <nameiparent>:

struct inode *
nameiparent(char *path, char *name)
{
    80006168:	1141                	add	sp,sp,-16
    8000616a:	e406                	sd	ra,8(sp)
    8000616c:	e022                	sd	s0,0(sp)
    8000616e:	0800                	add	s0,sp,16
    80006170:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80006172:	4585                	li	a1,1
    80006174:	00000097          	auipc	ra,0x0
    80006178:	dc6080e7          	jalr	-570(ra) # 80005f3a <namex>
}
    8000617c:	60a2                	ld	ra,8(sp)
    8000617e:	6402                	ld	s0,0(sp)
    80006180:	0141                	add	sp,sp,16
    80006182:	8082                	ret

0000000080006184 <dir_print>:

void dir_print(struct inode *pip)
{
    80006184:	7139                	add	sp,sp,-64
    80006186:	fc06                	sd	ra,56(sp)
    80006188:	f822                	sd	s0,48(sp)
    8000618a:	f426                	sd	s1,40(sp)
    8000618c:	f04a                	sd	s2,32(sp)
    8000618e:	ec4e                	sd	s3,24(sp)
    80006190:	0080                	add	s0,sp,64
    80006192:	892a                	mv	s2,a0
    assert(holdingsleep(&pip->lock), "dir_print: lock");
    80006194:	0541                	add	a0,a0,16
    80006196:	ffffd097          	auipc	ra,0xffffd
    8000619a:	c72080e7          	jalr	-910(ra) # 80002e08 <holdingsleep>
    8000619e:	00003597          	auipc	a1,0x3
    800061a2:	ae258593          	add	a1,a1,-1310 # 80008c80 <syscalls+0x518>
    800061a6:	00000097          	auipc	ra,0x0
    800061aa:	6d2080e7          	jalr	1746(ra) # 80006878 <assert>

    printf("\ninode_num = %d dirents:\n", pip->inum);
    800061ae:	00492583          	lw	a1,4(s2)
    800061b2:	00003517          	auipc	a0,0x3
    800061b6:	ade50513          	add	a0,a0,-1314 # 80008c90 <syscalls+0x528>
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	070080e7          	jalr	112(ra) # 8000122a <printf>

    struct dirent de;

    for (uint32 offset = 0; offset < pip->size; offset += sizeof(struct dirent))
    800061c2:	04c92783          	lw	a5,76(s2)
    800061c6:	cfa1                	beqz	a5,8000621e <dir_print+0x9a>
    800061c8:	4481                	li	s1,0
    {
        if (readi(pip, 0, (uint64)&de, offset, sizeof(de)) != sizeof(de))
            panic("dir_print read");
        if (de.inum != 0)
            printf("inum = %d dirent = %s\n", de.inum, de.name);
    800061ca:	00003997          	auipc	s3,0x3
    800061ce:	af698993          	add	s3,s3,-1290 # 80008cc0 <syscalls+0x558>
    800061d2:	a831                	j	800061ee <dir_print+0x6a>
            panic("dir_print read");
    800061d4:	00003517          	auipc	a0,0x3
    800061d8:	adc50513          	add	a0,a0,-1316 # 80008cb0 <syscalls+0x548>
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	004080e7          	jalr	4(ra) # 800011e0 <panic>
    for (uint32 offset = 0; offset < pip->size; offset += sizeof(struct dirent))
    800061e4:	24c1                	addw	s1,s1,16
    800061e6:	04c92783          	lw	a5,76(s2)
    800061ea:	02f4fa63          	bgeu	s1,a5,8000621e <dir_print+0x9a>
        if (readi(pip, 0, (uint64)&de, offset, sizeof(de)) != sizeof(de))
    800061ee:	4741                	li	a4,16
    800061f0:	86a6                	mv	a3,s1
    800061f2:	fc040613          	add	a2,s0,-64
    800061f6:	4581                	li	a1,0
    800061f8:	854a                	mv	a0,s2
    800061fa:	fffff097          	auipc	ra,0xfffff
    800061fe:	b46080e7          	jalr	-1210(ra) # 80004d40 <readi>
    80006202:	47c1                	li	a5,16
    80006204:	fcf518e3          	bne	a0,a5,800061d4 <dir_print+0x50>
        if (de.inum != 0)
    80006208:	fc045583          	lhu	a1,-64(s0)
    8000620c:	dde1                	beqz	a1,800061e4 <dir_print+0x60>
            printf("inum = %d dirent = %s\n", de.inum, de.name);
    8000620e:	fc240613          	add	a2,s0,-62
    80006212:	854e                	mv	a0,s3
    80006214:	ffffb097          	auipc	ra,0xffffb
    80006218:	016080e7          	jalr	22(ra) # 8000122a <printf>
    8000621c:	b7e1                	j	800061e4 <dir_print+0x60>
    }
}
    8000621e:	70e2                	ld	ra,56(sp)
    80006220:	7442                	ld	s0,48(sp)
    80006222:	74a2                	ld	s1,40(sp)
    80006224:	7902                	ld	s2,32(sp)
    80006226:	69e2                	ld	s3,24(sp)
    80006228:	6121                	add	sp,sp,64
    8000622a:	8082                	ret

000000008000622c <dir_unlink>:
  return 1;
}

int
dir_unlink(struct inode *dp, char *name)
{
    8000622c:	711d                	add	sp,sp,-96
    8000622e:	ec86                	sd	ra,88(sp)
    80006230:	e8a2                	sd	s0,80(sp)
    80006232:	e4a6                	sd	s1,72(sp)
    80006234:	e0ca                	sd	s2,64(sp)
    80006236:	fc4e                	sd	s3,56(sp)
    80006238:	1080                	add	s0,sp,96
    8000623a:	89aa                	mv	s3,a0
    8000623c:	84ae                	mv	s1,a1
  struct inode *ip;
  struct dirent de;
  uint off;

  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000623e:	00002597          	auipc	a1,0x2
    80006242:	64258593          	add	a1,a1,1602 # 80008880 <syscalls+0x118>
    80006246:	8526                	mv	a0,s1
    80006248:	00000097          	auipc	ra,0x0
    8000624c:	c28080e7          	jalr	-984(ra) # 80005e70 <namecmp>
    80006250:	12050663          	beqz	a0,8000637c <dir_unlink+0x150>
    80006254:	00002597          	auipc	a1,0x2
    80006258:	63458593          	add	a1,a1,1588 # 80008888 <syscalls+0x120>
    8000625c:	8526                	mv	a0,s1
    8000625e:	00000097          	auipc	ra,0x0
    80006262:	c12080e7          	jalr	-1006(ra) # 80005e70 <namecmp>
    80006266:	10050d63          	beqz	a0,80006380 <dir_unlink+0x154>
    return -1;

  if((ip = dirlookup(dp, name, &off)) == 0)
    8000626a:	fbc40613          	add	a2,s0,-68
    8000626e:	85a6                	mv	a1,s1
    80006270:	854e                	mv	a0,s3
    80006272:	00000097          	auipc	ra,0x0
    80006276:	c18080e7          	jalr	-1000(ra) # 80005e8a <dirlookup>
    8000627a:	84aa                	mv	s1,a0
    8000627c:	10050463          	beqz	a0,80006384 <dir_unlink+0x158>
    return -1;
  
  ilock(ip);
    80006280:	fffff097          	auipc	ra,0xfffff
    80006284:	80c080e7          	jalr	-2036(ra) # 80004a8c <ilock>

  if(ip->nlink < 1)
    80006288:	04a49783          	lh	a5,74(s1)
    8000628c:	06f05963          	blez	a5,800062fe <dir_unlink+0xd2>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006290:	04449703          	lh	a4,68(s1)
    80006294:	4785                	li	a5,1
    80006296:	06f70c63          	beq	a4,a5,8000630e <dir_unlink+0xe2>
    iunlockput(ip);
    return -1;
  }

  memset(&de, 0, sizeof(de));
    8000629a:	4641                	li	a2,16
    8000629c:	4581                	li	a1,0
    8000629e:	fc040513          	add	a0,s0,-64
    800062a2:	ffffb097          	auipc	ra,0xffffb
    800062a6:	cf6080e7          	jalr	-778(ra) # 80000f98 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800062aa:	4741                	li	a4,16
    800062ac:	fbc42683          	lw	a3,-68(s0)
    800062b0:	fc040613          	add	a2,s0,-64
    800062b4:	4581                	li	a1,0
    800062b6:	854e                	mv	a0,s3
    800062b8:	fffff097          	auipc	ra,0xfffff
    800062bc:	b80080e7          	jalr	-1152(ra) # 80004e38 <writei>
    800062c0:	47c1                	li	a5,16
    800062c2:	08f51a63          	bne	a0,a5,80006356 <dir_unlink+0x12a>
    panic("unlink: writei");
  
  if(ip->type == T_DIR){
    800062c6:	04449703          	lh	a4,68(s1)
    800062ca:	4785                	li	a5,1
    800062cc:	08f70d63          	beq	a4,a5,80006366 <dir_unlink+0x13a>
    dp->nlink--;
    iupdate(dp);
  }

  ip->nlink--;
    800062d0:	04a4d783          	lhu	a5,74(s1)
    800062d4:	37fd                	addw	a5,a5,-1
    800062d6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800062da:	8526                	mv	a0,s1
    800062dc:	ffffe097          	auipc	ra,0xffffe
    800062e0:	6e4080e7          	jalr	1764(ra) # 800049c0 <iupdate>
  iunlockput(ip);
    800062e4:	8526                	mv	a0,s1
    800062e6:	fffff097          	auipc	ra,0xfffff
    800062ea:	a08080e7          	jalr	-1528(ra) # 80004cee <iunlockput>

  return 0;
    800062ee:	4501                	li	a0,0
}
    800062f0:	60e6                	ld	ra,88(sp)
    800062f2:	6446                	ld	s0,80(sp)
    800062f4:	64a6                	ld	s1,72(sp)
    800062f6:	6906                	ld	s2,64(sp)
    800062f8:	79e2                	ld	s3,56(sp)
    800062fa:	6125                	add	sp,sp,96
    800062fc:	8082                	ret
    panic("unlink: nlink < 1");
    800062fe:	00002517          	auipc	a0,0x2
    80006302:	59250513          	add	a0,a0,1426 # 80008890 <syscalls+0x128>
    80006306:	ffffb097          	auipc	ra,0xffffb
    8000630a:	eda080e7          	jalr	-294(ra) # 800011e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000630e:	44f8                	lw	a4,76(s1)
    80006310:	02000793          	li	a5,32
    80006314:	f8e7f3e3          	bgeu	a5,a4,8000629a <dir_unlink+0x6e>
    80006318:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000631c:	4741                	li	a4,16
    8000631e:	86ca                	mv	a3,s2
    80006320:	fa840613          	add	a2,s0,-88
    80006324:	4581                	li	a1,0
    80006326:	8526                	mv	a0,s1
    80006328:	fffff097          	auipc	ra,0xfffff
    8000632c:	a18080e7          	jalr	-1512(ra) # 80004d40 <readi>
    80006330:	47c1                	li	a5,16
    80006332:	00f51a63          	bne	a0,a5,80006346 <dir_unlink+0x11a>
    if(de.inum != 0)
    80006336:	fa845783          	lhu	a5,-88(s0)
    8000633a:	e7b9                	bnez	a5,80006388 <dir_unlink+0x15c>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000633c:	2941                	addw	s2,s2,16
    8000633e:	44fc                	lw	a5,76(s1)
    80006340:	fcf96ee3          	bltu	s2,a5,8000631c <dir_unlink+0xf0>
    80006344:	bf99                	j	8000629a <dir_unlink+0x6e>
      panic("isdirempty: readi");
    80006346:	00002517          	auipc	a0,0x2
    8000634a:	56250513          	add	a0,a0,1378 # 800088a8 <syscalls+0x140>
    8000634e:	ffffb097          	auipc	ra,0xffffb
    80006352:	e92080e7          	jalr	-366(ra) # 800011e0 <panic>
    panic("unlink: writei");
    80006356:	00002517          	auipc	a0,0x2
    8000635a:	56a50513          	add	a0,a0,1386 # 800088c0 <syscalls+0x158>
    8000635e:	ffffb097          	auipc	ra,0xffffb
    80006362:	e82080e7          	jalr	-382(ra) # 800011e0 <panic>
    dp->nlink--;
    80006366:	04a9d783          	lhu	a5,74(s3)
    8000636a:	37fd                	addw	a5,a5,-1
    8000636c:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    80006370:	854e                	mv	a0,s3
    80006372:	ffffe097          	auipc	ra,0xffffe
    80006376:	64e080e7          	jalr	1614(ra) # 800049c0 <iupdate>
    8000637a:	bf99                	j	800062d0 <dir_unlink+0xa4>
    return -1;
    8000637c:	557d                	li	a0,-1
    8000637e:	bf8d                	j	800062f0 <dir_unlink+0xc4>
    80006380:	557d                	li	a0,-1
    80006382:	b7bd                	j	800062f0 <dir_unlink+0xc4>
    return -1;
    80006384:	557d                	li	a0,-1
    80006386:	b7ad                	j	800062f0 <dir_unlink+0xc4>
    iunlockput(ip);
    80006388:	8526                	mv	a0,s1
    8000638a:	fffff097          	auipc	ra,0xfffff
    8000638e:	964080e7          	jalr	-1692(ra) # 80004cee <iunlockput>
    return -1;
    80006392:	557d                	li	a0,-1
    80006394:	bfb1                	j	800062f0 <dir_unlink+0xc4>

0000000080006396 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80006396:	7179                	add	sp,sp,-48
    80006398:	f406                	sd	ra,40(sp)
    8000639a:	f022                	sd	s0,32(sp)
    8000639c:	ec26                	sd	s1,24(sp)
    8000639e:	e84a                	sd	s2,16(sp)
    800063a0:	e44e                	sd	s3,8(sp)
    800063a2:	e052                	sd	s4,0(sp)
    800063a4:	1800                	add	s0,sp,48
    800063a6:	84aa                	mv	s1,a0
    800063a8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800063aa:	0005b023          	sd	zero,0(a1)
    800063ae:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800063b2:	fffff097          	auipc	ra,0xfffff
    800063b6:	64a080e7          	jalr	1610(ra) # 800059fc <filealloc>
    800063ba:	e088                	sd	a0,0(s1)
    800063bc:	c559                	beqz	a0,8000644a <pipealloc+0xb4>
    800063be:	fffff097          	auipc	ra,0xfffff
    800063c2:	63e080e7          	jalr	1598(ra) # 800059fc <filealloc>
    800063c6:	00aa3023          	sd	a0,0(s4)
    800063ca:	c935                	beqz	a0,8000643e <pipealloc+0xa8>
    goto bad;
  if((pi = (struct pipe*)kalloc(1)) == 0)
    800063cc:	4505                	li	a0,1
    800063ce:	ffffb097          	auipc	ra,0xffffb
    800063d2:	16e080e7          	jalr	366(ra) # 8000153c <kalloc>
    800063d6:	892a                	mv	s2,a0
    800063d8:	c125                	beqz	a0,80006438 <pipealloc+0xa2>
    goto bad;
  pi->readopen = 1;
    800063da:	4985                	li	s3,1
    800063dc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800063e0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800063e4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800063e8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800063ec:	00003597          	auipc	a1,0x3
    800063f0:	8ec58593          	add	a1,a1,-1812 # 80008cd8 <syscalls+0x570>
    800063f4:	ffffd097          	auipc	ra,0xffffd
    800063f8:	a6a080e7          	jalr	-1430(ra) # 80002e5e <initlock>
  (*f0)->type = FD_PIPE;
    800063fc:	609c                	ld	a5,0(s1)
    800063fe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80006402:	609c                	ld	a5,0(s1)
    80006404:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80006408:	609c                	ld	a5,0(s1)
    8000640a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000640e:	609c                	ld	a5,0(s1)
    80006410:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80006414:	000a3783          	ld	a5,0(s4)
    80006418:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000641c:	000a3783          	ld	a5,0(s4)
    80006420:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80006424:	000a3783          	ld	a5,0(s4)
    80006428:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000642c:	000a3783          	ld	a5,0(s4)
    80006430:	0127b823          	sd	s2,16(a5)
  return 0;
    80006434:	4501                	li	a0,0
    80006436:	a025                	j	8000645e <pipealloc+0xc8>

 bad:
  if(pi)
    kfree((uint64)pi,1);
  if(*f0)
    80006438:	6088                	ld	a0,0(s1)
    8000643a:	e501                	bnez	a0,80006442 <pipealloc+0xac>
    8000643c:	a039                	j	8000644a <pipealloc+0xb4>
    8000643e:	6088                	ld	a0,0(s1)
    80006440:	c51d                	beqz	a0,8000646e <pipealloc+0xd8>
    fileclose(*f0);
    80006442:	fffff097          	auipc	ra,0xfffff
    80006446:	676080e7          	jalr	1654(ra) # 80005ab8 <fileclose>
  if(*f1)
    8000644a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000644e:	557d                	li	a0,-1
  if(*f1)
    80006450:	c799                	beqz	a5,8000645e <pipealloc+0xc8>
    fileclose(*f1);
    80006452:	853e                	mv	a0,a5
    80006454:	fffff097          	auipc	ra,0xfffff
    80006458:	664080e7          	jalr	1636(ra) # 80005ab8 <fileclose>
  return -1;
    8000645c:	557d                	li	a0,-1
}
    8000645e:	70a2                	ld	ra,40(sp)
    80006460:	7402                	ld	s0,32(sp)
    80006462:	64e2                	ld	s1,24(sp)
    80006464:	6942                	ld	s2,16(sp)
    80006466:	69a2                	ld	s3,8(sp)
    80006468:	6a02                	ld	s4,0(sp)
    8000646a:	6145                	add	sp,sp,48
    8000646c:	8082                	ret
  return -1;
    8000646e:	557d                	li	a0,-1
    80006470:	b7fd                	j	8000645e <pipealloc+0xc8>

0000000080006472 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80006472:	1101                	add	sp,sp,-32
    80006474:	ec06                	sd	ra,24(sp)
    80006476:	e822                	sd	s0,16(sp)
    80006478:	e426                	sd	s1,8(sp)
    8000647a:	e04a                	sd	s2,0(sp)
    8000647c:	1000                	add	s0,sp,32
    8000647e:	84aa                	mv	s1,a0
    80006480:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80006482:	ffffd097          	auipc	ra,0xffffd
    80006486:	a6c080e7          	jalr	-1428(ra) # 80002eee <acquire>
  if(writable){
    8000648a:	02090e63          	beqz	s2,800064c6 <pipeclose+0x54>
    pi->writeopen = 0;
    8000648e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80006492:	21848513          	add	a0,s1,536
    80006496:	ffffc097          	auipc	ra,0xffffc
    8000649a:	414080e7          	jalr	1044(ra) # 800028aa <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000649e:	2204b783          	ld	a5,544(s1)
    800064a2:	eb9d                	bnez	a5,800064d8 <pipeclose+0x66>
    release(&pi->lock);
    800064a4:	8526                	mv	a0,s1
    800064a6:	ffffd097          	auipc	ra,0xffffd
    800064aa:	afc080e7          	jalr	-1284(ra) # 80002fa2 <release>
    kfree((uint64)pi,1);
    800064ae:	4585                	li	a1,1
    800064b0:	8526                	mv	a0,s1
    800064b2:	ffffb097          	auipc	ra,0xffffb
    800064b6:	f8a080e7          	jalr	-118(ra) # 8000143c <kfree>
  } else
    release(&pi->lock);
}
    800064ba:	60e2                	ld	ra,24(sp)
    800064bc:	6442                	ld	s0,16(sp)
    800064be:	64a2                	ld	s1,8(sp)
    800064c0:	6902                	ld	s2,0(sp)
    800064c2:	6105                	add	sp,sp,32
    800064c4:	8082                	ret
    pi->readopen = 0;
    800064c6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800064ca:	21c48513          	add	a0,s1,540
    800064ce:	ffffc097          	auipc	ra,0xffffc
    800064d2:	3dc080e7          	jalr	988(ra) # 800028aa <wakeup>
    800064d6:	b7e1                	j	8000649e <pipeclose+0x2c>
    release(&pi->lock);
    800064d8:	8526                	mv	a0,s1
    800064da:	ffffd097          	auipc	ra,0xffffd
    800064de:	ac8080e7          	jalr	-1336(ra) # 80002fa2 <release>
}
    800064e2:	bfe1                	j	800064ba <pipeclose+0x48>

00000000800064e4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800064e4:	711d                	add	sp,sp,-96
    800064e6:	ec86                	sd	ra,88(sp)
    800064e8:	e8a2                	sd	s0,80(sp)
    800064ea:	e4a6                	sd	s1,72(sp)
    800064ec:	e0ca                	sd	s2,64(sp)
    800064ee:	fc4e                	sd	s3,56(sp)
    800064f0:	f852                	sd	s4,48(sp)
    800064f2:	f456                	sd	s5,40(sp)
    800064f4:	f05a                	sd	s6,32(sp)
    800064f6:	ec5e                	sd	s7,24(sp)
    800064f8:	e862                	sd	s8,16(sp)
    800064fa:	1080                	add	s0,sp,96
    800064fc:	84aa                	mv	s1,a0
    800064fe:	8aae                	mv	s5,a1
    80006500:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80006502:	ffffc097          	auipc	ra,0xffffc
    80006506:	c0c080e7          	jalr	-1012(ra) # 8000210e <myproc>
    8000650a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000650c:	8526                	mv	a0,s1
    8000650e:	ffffd097          	auipc	ra,0xffffd
    80006512:	9e0080e7          	jalr	-1568(ra) # 80002eee <acquire>
  while(i < n){
    80006516:	0b405663          	blez	s4,800065c2 <pipewrite+0xde>
  int i = 0;
    8000651a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pgtbl, &ch, addr + i, 1) == -1)
    8000651c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000651e:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80006522:	21c48b93          	add	s7,s1,540
    80006526:	a089                	j	80006568 <pipewrite+0x84>
      release(&pi->lock);
    80006528:	8526                	mv	a0,s1
    8000652a:	ffffd097          	auipc	ra,0xffffd
    8000652e:	a78080e7          	jalr	-1416(ra) # 80002fa2 <release>
      return -1;
    80006532:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80006534:	854a                	mv	a0,s2
    80006536:	60e6                	ld	ra,88(sp)
    80006538:	6446                	ld	s0,80(sp)
    8000653a:	64a6                	ld	s1,72(sp)
    8000653c:	6906                	ld	s2,64(sp)
    8000653e:	79e2                	ld	s3,56(sp)
    80006540:	7a42                	ld	s4,48(sp)
    80006542:	7aa2                	ld	s5,40(sp)
    80006544:	7b02                	ld	s6,32(sp)
    80006546:	6be2                	ld	s7,24(sp)
    80006548:	6c42                	ld	s8,16(sp)
    8000654a:	6125                	add	sp,sp,96
    8000654c:	8082                	ret
      wakeup(&pi->nread);
    8000654e:	8562                	mv	a0,s8
    80006550:	ffffc097          	auipc	ra,0xffffc
    80006554:	35a080e7          	jalr	858(ra) # 800028aa <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80006558:	85a6                	mv	a1,s1
    8000655a:	855e                	mv	a0,s7
    8000655c:	ffffc097          	auipc	ra,0xffffc
    80006560:	2e0080e7          	jalr	736(ra) # 8000283c <sleep>
  while(i < n){
    80006564:	07495063          	bge	s2,s4,800065c4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80006568:	2204a783          	lw	a5,544(s1)
    8000656c:	dfd5                	beqz	a5,80006528 <pipewrite+0x44>
    8000656e:	854e                	mv	a0,s3
    80006570:	ffffc097          	auipc	ra,0xffffc
    80006574:	468080e7          	jalr	1128(ra) # 800029d8 <killed>
    80006578:	f945                	bnez	a0,80006528 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000657a:	2184a783          	lw	a5,536(s1)
    8000657e:	21c4a703          	lw	a4,540(s1)
    80006582:	2007879b          	addw	a5,a5,512
    80006586:	fcf704e3          	beq	a4,a5,8000654e <pipewrite+0x6a>
      if(copyin(pr->pgtbl, &ch, addr + i, 1) == -1)
    8000658a:	4685                	li	a3,1
    8000658c:	01590633          	add	a2,s2,s5
    80006590:	faf40593          	add	a1,s0,-81
    80006594:	0489b503          	ld	a0,72(s3)
    80006598:	ffffc097          	auipc	ra,0xffffc
    8000659c:	a06080e7          	jalr	-1530(ra) # 80001f9e <copyin>
    800065a0:	03650263          	beq	a0,s6,800065c4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800065a4:	21c4a783          	lw	a5,540(s1)
    800065a8:	0017871b          	addw	a4,a5,1
    800065ac:	20e4ae23          	sw	a4,540(s1)
    800065b0:	1ff7f793          	and	a5,a5,511
    800065b4:	97a6                	add	a5,a5,s1
    800065b6:	faf44703          	lbu	a4,-81(s0)
    800065ba:	00e78c23          	sb	a4,24(a5)
      i++;
    800065be:	2905                	addw	s2,s2,1
    800065c0:	b755                	j	80006564 <pipewrite+0x80>
  int i = 0;
    800065c2:	4901                	li	s2,0
  wakeup(&pi->nread);
    800065c4:	21848513          	add	a0,s1,536
    800065c8:	ffffc097          	auipc	ra,0xffffc
    800065cc:	2e2080e7          	jalr	738(ra) # 800028aa <wakeup>
  release(&pi->lock);
    800065d0:	8526                	mv	a0,s1
    800065d2:	ffffd097          	auipc	ra,0xffffd
    800065d6:	9d0080e7          	jalr	-1584(ra) # 80002fa2 <release>
  return i;
    800065da:	bfa9                	j	80006534 <pipewrite+0x50>

00000000800065dc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800065dc:	715d                	add	sp,sp,-80
    800065de:	e486                	sd	ra,72(sp)
    800065e0:	e0a2                	sd	s0,64(sp)
    800065e2:	fc26                	sd	s1,56(sp)
    800065e4:	f84a                	sd	s2,48(sp)
    800065e6:	f44e                	sd	s3,40(sp)
    800065e8:	f052                	sd	s4,32(sp)
    800065ea:	ec56                	sd	s5,24(sp)
    800065ec:	e85a                	sd	s6,16(sp)
    800065ee:	0880                	add	s0,sp,80
    800065f0:	84aa                	mv	s1,a0
    800065f2:	892e                	mv	s2,a1
    800065f4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800065f6:	ffffc097          	auipc	ra,0xffffc
    800065fa:	b18080e7          	jalr	-1256(ra) # 8000210e <myproc>
    800065fe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80006600:	8526                	mv	a0,s1
    80006602:	ffffd097          	auipc	ra,0xffffd
    80006606:	8ec080e7          	jalr	-1812(ra) # 80002eee <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000660a:	2184a703          	lw	a4,536(s1)
    8000660e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006612:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006616:	02f71763          	bne	a4,a5,80006644 <piperead+0x68>
    8000661a:	2244a783          	lw	a5,548(s1)
    8000661e:	c39d                	beqz	a5,80006644 <piperead+0x68>
    if(killed(pr)){
    80006620:	8552                	mv	a0,s4
    80006622:	ffffc097          	auipc	ra,0xffffc
    80006626:	3b6080e7          	jalr	950(ra) # 800029d8 <killed>
    8000662a:	e949                	bnez	a0,800066bc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000662c:	85a6                	mv	a1,s1
    8000662e:	854e                	mv	a0,s3
    80006630:	ffffc097          	auipc	ra,0xffffc
    80006634:	20c080e7          	jalr	524(ra) # 8000283c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006638:	2184a703          	lw	a4,536(s1)
    8000663c:	21c4a783          	lw	a5,540(s1)
    80006640:	fcf70de3          	beq	a4,a5,8000661a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006644:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pgtbl, addr + i, &ch, 1) == -1)
    80006646:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006648:	05505463          	blez	s5,80006690 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000664c:	2184a783          	lw	a5,536(s1)
    80006650:	21c4a703          	lw	a4,540(s1)
    80006654:	02f70e63          	beq	a4,a5,80006690 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80006658:	0017871b          	addw	a4,a5,1
    8000665c:	20e4ac23          	sw	a4,536(s1)
    80006660:	1ff7f793          	and	a5,a5,511
    80006664:	97a6                	add	a5,a5,s1
    80006666:	0187c783          	lbu	a5,24(a5)
    8000666a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pgtbl, addr + i, &ch, 1) == -1)
    8000666e:	4685                	li	a3,1
    80006670:	fbf40613          	add	a2,s0,-65
    80006674:	85ca                	mv	a1,s2
    80006676:	048a3503          	ld	a0,72(s4)
    8000667a:	ffffc097          	auipc	ra,0xffffc
    8000667e:	892080e7          	jalr	-1902(ra) # 80001f0c <copyout>
    80006682:	01650763          	beq	a0,s6,80006690 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006686:	2985                	addw	s3,s3,1
    80006688:	0905                	add	s2,s2,1
    8000668a:	fd3a91e3          	bne	s5,s3,8000664c <piperead+0x70>
    8000668e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80006690:	21c48513          	add	a0,s1,540
    80006694:	ffffc097          	auipc	ra,0xffffc
    80006698:	216080e7          	jalr	534(ra) # 800028aa <wakeup>
  release(&pi->lock);
    8000669c:	8526                	mv	a0,s1
    8000669e:	ffffd097          	auipc	ra,0xffffd
    800066a2:	904080e7          	jalr	-1788(ra) # 80002fa2 <release>
  return i;
}
    800066a6:	854e                	mv	a0,s3
    800066a8:	60a6                	ld	ra,72(sp)
    800066aa:	6406                	ld	s0,64(sp)
    800066ac:	74e2                	ld	s1,56(sp)
    800066ae:	7942                	ld	s2,48(sp)
    800066b0:	79a2                	ld	s3,40(sp)
    800066b2:	7a02                	ld	s4,32(sp)
    800066b4:	6ae2                	ld	s5,24(sp)
    800066b6:	6b42                	ld	s6,16(sp)
    800066b8:	6161                	add	sp,sp,80
    800066ba:	8082                	ret
      release(&pi->lock);
    800066bc:	8526                	mv	a0,s1
    800066be:	ffffd097          	auipc	ra,0xffffd
    800066c2:	8e4080e7          	jalr	-1820(ra) # 80002fa2 <release>
      return -1;
    800066c6:	59fd                	li	s3,-1
    800066c8:	bff9                	j	800066a6 <piperead+0xca>

00000000800066ca <balloc>:
  brelse(bp);
}

uint
balloc(uint dev)
{
    800066ca:	711d                	add	sp,sp,-96
    800066cc:	ec86                	sd	ra,88(sp)
    800066ce:	e8a2                	sd	s0,80(sp)
    800066d0:	e4a6                	sd	s1,72(sp)
    800066d2:	e0ca                	sd	s2,64(sp)
    800066d4:	fc4e                	sd	s3,56(sp)
    800066d6:	f852                	sd	s4,48(sp)
    800066d8:	f456                	sd	s5,40(sp)
    800066da:	f05a                	sd	s6,32(sp)
    800066dc:	ec5e                	sd	s7,24(sp)
    800066de:	e862                	sd	s8,16(sp)
    800066e0:	e466                	sd	s9,8(sp)
    800066e2:	1080                	add	s0,sp,96
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for (b = 0; b < sb.size; b += BPB)
    800066e4:	0001c797          	auipc	a5,0x1c
    800066e8:	c487a783          	lw	a5,-952(a5) # 8002232c <sb+0x4>
    800066ec:	cff5                	beqz	a5,800067e8 <balloc+0x11e>
    800066ee:	8baa                	mv	s7,a0
    800066f0:	4a81                	li	s5,0
  {
    bp = bread(dev, BBLOCK(b, sb));
    800066f2:	0001cb17          	auipc	s6,0x1c
    800066f6:	c36b0b13          	add	s6,s6,-970 # 80022328 <sb>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800066fa:	4c01                	li	s8,0
    {
      m = 1 << (bi % 8);
    800066fc:	4985                	li	s3,1
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800066fe:	6a09                	lui	s4,0x2
  for (b = 0; b < sb.size; b += BPB)
    80006700:	6c89                	lui	s9,0x2
    80006702:	a061                	j	8000678a <balloc+0xc0>
      if ((bp->data[bi / 8] & m) == 0)
      {
        bp->data[bi / 8] |= m;
    80006704:	97ca                	add	a5,a5,s2
    80006706:	8e55                	or	a2,a2,a3
    80006708:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000670c:	854a                	mv	a0,s2
    8000670e:	fffff097          	auipc	ra,0xfffff
    80006712:	1e2080e7          	jalr	482(ra) # 800058f0 <log_write>
        brelse(bp);
    80006716:	854a                	mv	a0,s2
    80006718:	fffff097          	auipc	ra,0xfffff
    8000671c:	b70080e7          	jalr	-1168(ra) # 80005288 <brelse>
  bp = bread(dev, bno);
    80006720:	85a6                	mv	a1,s1
    80006722:	855e                	mv	a0,s7
    80006724:	fffff097          	auipc	ra,0xfffff
    80006728:	a34080e7          	jalr	-1484(ra) # 80005158 <bread>
    8000672c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000672e:	40000613          	li	a2,1024
    80006732:	4581                	li	a1,0
    80006734:	05850513          	add	a0,a0,88
    80006738:	ffffb097          	auipc	ra,0xffffb
    8000673c:	860080e7          	jalr	-1952(ra) # 80000f98 <memset>
  log_write(bp);
    80006740:	854a                	mv	a0,s2
    80006742:	fffff097          	auipc	ra,0xfffff
    80006746:	1ae080e7          	jalr	430(ra) # 800058f0 <log_write>
  brelse(bp);
    8000674a:	854a                	mv	a0,s2
    8000674c:	fffff097          	auipc	ra,0xfffff
    80006750:	b3c080e7          	jalr	-1220(ra) # 80005288 <brelse>
    }
    brelse(bp);
  }
  printf("balloc: out of blocks\n");
  return 0;
}
    80006754:	8526                	mv	a0,s1
    80006756:	60e6                	ld	ra,88(sp)
    80006758:	6446                	ld	s0,80(sp)
    8000675a:	64a6                	ld	s1,72(sp)
    8000675c:	6906                	ld	s2,64(sp)
    8000675e:	79e2                	ld	s3,56(sp)
    80006760:	7a42                	ld	s4,48(sp)
    80006762:	7aa2                	ld	s5,40(sp)
    80006764:	7b02                	ld	s6,32(sp)
    80006766:	6be2                	ld	s7,24(sp)
    80006768:	6c42                	ld	s8,16(sp)
    8000676a:	6ca2                	ld	s9,8(sp)
    8000676c:	6125                	add	sp,sp,96
    8000676e:	8082                	ret
    brelse(bp);
    80006770:	854a                	mv	a0,s2
    80006772:	fffff097          	auipc	ra,0xfffff
    80006776:	b16080e7          	jalr	-1258(ra) # 80005288 <brelse>
  for (b = 0; b < sb.size; b += BPB)
    8000677a:	015c87bb          	addw	a5,s9,s5
    8000677e:	00078a9b          	sext.w	s5,a5
    80006782:	004b2703          	lw	a4,4(s6)
    80006786:	06eaf163          	bgeu	s5,a4,800067e8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000678a:	41fad79b          	sraw	a5,s5,0x1f
    8000678e:	0137d79b          	srlw	a5,a5,0x13
    80006792:	015787bb          	addw	a5,a5,s5
    80006796:	40d7d79b          	sraw	a5,a5,0xd
    8000679a:	01cb2583          	lw	a1,28(s6)
    8000679e:	9dbd                	addw	a1,a1,a5
    800067a0:	855e                	mv	a0,s7
    800067a2:	fffff097          	auipc	ra,0xfffff
    800067a6:	9b6080e7          	jalr	-1610(ra) # 80005158 <bread>
    800067aa:	892a                	mv	s2,a0
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800067ac:	004b2503          	lw	a0,4(s6)
    800067b0:	000a849b          	sext.w	s1,s5
    800067b4:	8762                	mv	a4,s8
    800067b6:	faa4fde3          	bgeu	s1,a0,80006770 <balloc+0xa6>
      m = 1 << (bi % 8);
    800067ba:	00777693          	and	a3,a4,7
    800067be:	00d996bb          	sllw	a3,s3,a3
      if ((bp->data[bi / 8] & m) == 0)
    800067c2:	41f7579b          	sraw	a5,a4,0x1f
    800067c6:	01d7d79b          	srlw	a5,a5,0x1d
    800067ca:	9fb9                	addw	a5,a5,a4
    800067cc:	4037d79b          	sraw	a5,a5,0x3
    800067d0:	00f90633          	add	a2,s2,a5
    800067d4:	05864603          	lbu	a2,88(a2)
    800067d8:	00c6f5b3          	and	a1,a3,a2
    800067dc:	d585                	beqz	a1,80006704 <balloc+0x3a>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    800067de:	2705                	addw	a4,a4,1
    800067e0:	2485                	addw	s1,s1,1
    800067e2:	fd471ae3          	bne	a4,s4,800067b6 <balloc+0xec>
    800067e6:	b769                	j	80006770 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800067e8:	00002517          	auipc	a0,0x2
    800067ec:	4f850513          	add	a0,a0,1272 # 80008ce0 <syscalls+0x578>
    800067f0:	ffffb097          	auipc	ra,0xffffb
    800067f4:	a3a080e7          	jalr	-1478(ra) # 8000122a <printf>
  return 0;
    800067f8:	4481                	li	s1,0
    800067fa:	bfa9                	j	80006754 <balloc+0x8a>

00000000800067fc <bfree>:

void
bfree(int dev, uint b)
{
    800067fc:	1101                	add	sp,sp,-32
    800067fe:	ec06                	sd	ra,24(sp)
    80006800:	e822                	sd	s0,16(sp)
    80006802:	e426                	sd	s1,8(sp)
    80006804:	e04a                	sd	s2,0(sp)
    80006806:	1000                	add	s0,sp,32
    80006808:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;
  bp = bread(dev, BBLOCK(b, sb));
    8000680a:	00d5d59b          	srlw	a1,a1,0xd
    8000680e:	0001c797          	auipc	a5,0x1c
    80006812:	b367a783          	lw	a5,-1226(a5) # 80022344 <sb+0x1c>
    80006816:	9dbd                	addw	a1,a1,a5
    80006818:	fffff097          	auipc	ra,0xfffff
    8000681c:	940080e7          	jalr	-1728(ra) # 80005158 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80006820:	0074f713          	and	a4,s1,7
    80006824:	4785                	li	a5,1
    80006826:	00e797bb          	sllw	a5,a5,a4
  if ((bp->data[bi / 8] & m) == 0)
    8000682a:	14ce                	sll	s1,s1,0x33
    8000682c:	90d9                	srl	s1,s1,0x36
    8000682e:	00950733          	add	a4,a0,s1
    80006832:	05874703          	lbu	a4,88(a4)
    80006836:	00e7f6b3          	and	a3,a5,a4
    8000683a:	c69d                	beqz	a3,80006868 <bfree+0x6c>
    8000683c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi / 8] &= ~m;
    8000683e:	94aa                	add	s1,s1,a0
    80006840:	fff7c793          	not	a5,a5
    80006844:	8f7d                	and	a4,a4,a5
    80006846:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000684a:	fffff097          	auipc	ra,0xfffff
    8000684e:	0a6080e7          	jalr	166(ra) # 800058f0 <log_write>
  brelse(bp);
    80006852:	854a                	mv	a0,s2
    80006854:	fffff097          	auipc	ra,0xfffff
    80006858:	a34080e7          	jalr	-1484(ra) # 80005288 <brelse>
}
    8000685c:	60e2                	ld	ra,24(sp)
    8000685e:	6442                	ld	s0,16(sp)
    80006860:	64a2                	ld	s1,8(sp)
    80006862:	6902                	ld	s2,0(sp)
    80006864:	6105                	add	sp,sp,32
    80006866:	8082                	ret
    panic("freeing free block");
    80006868:	00002517          	auipc	a0,0x2
    8000686c:	49050513          	add	a0,a0,1168 # 80008cf8 <syscalls+0x590>
    80006870:	ffffb097          	auipc	ra,0xffffb
    80006874:	970080e7          	jalr	-1680(ra) # 800011e0 <panic>

0000000080006878 <assert>:
#include "cpu.h"

struct superblock sb;

void assert(int condition, char *msg) {
    if (!condition) panic(msg);
    80006878:	c111                	beqz	a0,8000687c <assert+0x4>
    8000687a:	8082                	ret
void assert(int condition, char *msg) {
    8000687c:	1141                	add	sp,sp,-16
    8000687e:	e406                	sd	ra,8(sp)
    80006880:	e022                	sd	s0,0(sp)
    80006882:	0800                	add	s0,sp,16
    if (!condition) panic(msg);
    80006884:	852e                	mv	a0,a1
    80006886:	ffffb097          	auipc	ra,0xffffb
    8000688a:	95a080e7          	jalr	-1702(ra) # 800011e0 <panic>

000000008000688e <blockcmp>:
  bp = bread(dev, 1);
  memmove(sb, bp->data, sizeof(*sb));
  brelse(bp);
}

bool blockcmp(void *a, void *b) {
    8000688e:	1141                	add	sp,sp,-16
    80006890:	e406                	sd	ra,8(sp)
    80006892:	e022                	sd	s0,0(sp)
    80006894:	0800                	add	s0,sp,16
    return memcmp(a, b, BSIZE * 2) == 0;
    80006896:	6605                	lui	a2,0x1
    80006898:	80060613          	add	a2,a2,-2048 # 800 <_entry-0x7ffff800>
    8000689c:	ffffa097          	auipc	ra,0xffffa
    800068a0:	71e080e7          	jalr	1822(ra) # 80000fba <memcmp>
}
    800068a4:	00153513          	seqz	a0,a0
    800068a8:	60a2                	ld	ra,8(sp)
    800068aa:	6402                	ld	s0,0(sp)
    800068ac:	0141                	add	sp,sp,16
    800068ae:	8082                	ret

00000000800068b0 <fsinit>:

void fsinit(int dev)
{
    800068b0:	7139                	add	sp,sp,-64
    800068b2:	fc06                	sd	ra,56(sp)
    800068b4:	f822                	sd	s0,48(sp)
    800068b6:	f426                	sd	s1,40(sp)
    800068b8:	f04a                	sd	s2,32(sp)
    800068ba:	ec4e                	sd	s3,24(sp)
    800068bc:	e852                	sd	s4,16(sp)
    800068be:	e456                	sd	s5,8(sp)
    800068c0:	e05a                	sd	s6,0(sp)
    800068c2:	0080                	add	s0,sp,64
    800068c4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800068c6:	0005099b          	sext.w	s3,a0
    800068ca:	4585                	li	a1,1
    800068cc:	854e                	mv	a0,s3
    800068ce:	fffff097          	auipc	ra,0xfffff
    800068d2:	88a080e7          	jalr	-1910(ra) # 80005158 <bread>
    800068d6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800068d8:	0001ca17          	auipc	s4,0x1c
    800068dc:	a50a0a13          	add	s4,s4,-1456 # 80022328 <sb>
    800068e0:	02000613          	li	a2,32
    800068e4:	05850593          	add	a1,a0,88
    800068e8:	8552                	mv	a0,s4
    800068ea:	ffffa097          	auipc	ra,0xffffa
    800068ee:	70a080e7          	jalr	1802(ra) # 80000ff4 <memmove>
  brelse(bp);
    800068f2:	8526                	mv	a0,s1
    800068f4:	fffff097          	auipc	ra,0xfffff
    800068f8:	994080e7          	jalr	-1644(ra) # 80005288 <brelse>
  readsb(dev, &sb);
  if (sb.magic != FSMAGIC)
    800068fc:	000a2703          	lw	a4,0(s4)
    80006900:	102037b7          	lui	a5,0x10203
    80006904:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80006908:	00f70a63          	beq	a4,a5,8000691c <fsinit+0x6c>
    panic("invalid file system");
    8000690c:	00002517          	auipc	a0,0x2
    80006910:	40450513          	add	a0,a0,1028 # 80008d10 <syscalls+0x5a8>
    80006914:	ffffb097          	auipc	ra,0xffffb
    80006918:	8cc080e7          	jalr	-1844(ra) # 800011e0 <panic>
  initlog(dev, &sb);
    8000691c:	0001c597          	auipc	a1,0x1c
    80006920:	a0c58593          	add	a1,a1,-1524 # 80022328 <sb>
    80006924:	854a                	mv	a0,s2
    80006926:	fffff097          	auipc	ra,0xfffff
    8000692a:	d60080e7          	jalr	-672(ra) # 80005686 <initlog>

  // 获取根目录
  printf("fsinit: starting directory test\n");
    8000692e:	00002517          	auipc	a0,0x2
    80006932:	3fa50513          	add	a0,a0,1018 # 80008d28 <syscalls+0x5c0>
    80006936:	ffffb097          	auipc	ra,0xffffb
    8000693a:	8f4080e7          	jalr	-1804(ra) # 8000122a <printf>

  begin_op();
    8000693e:	fffff097          	auipc	ra,0xfffff
    80006942:	de0080e7          	jalr	-544(ra) # 8000571e <begin_op>
  struct inode* ip = iget(dev, ROOTINO);
    80006946:	4585                	li	a1,1
    80006948:	854e                	mv	a0,s3
    8000694a:	ffffe097          	auipc	ra,0xffffe
    8000694e:	eee080e7          	jalr	-274(ra) # 80004838 <iget>
    80006952:	8b2a                	mv	s6,a0
  ilock(ip);
    80006954:	ffffe097          	auipc	ra,0xffffe
    80006958:	138080e7          	jalr	312(ra) # 80004a8c <ilock>

  // 第一次查看
  dir_print(ip);
    8000695c:	855a                	mv	a0,s6
    8000695e:	00000097          	auipc	ra,0x0
    80006962:	826080e7          	jalr	-2010(ra) # 80006184 <dir_print>

  // Allocate valid inodes for testing
  struct inode *ip_a = ialloc(dev, T_FILE);
    80006966:	4589                	li	a1,2
    80006968:	854e                	mv	a0,s3
    8000696a:	ffffe097          	auipc	ra,0xffffe
    8000696e:	f8a080e7          	jalr	-118(ra) # 800048f4 <ialloc>
    80006972:	84aa                	mv	s1,a0
  ilock(ip_a);
    80006974:	ffffe097          	auipc	ra,0xffffe
    80006978:	118080e7          	jalr	280(ra) # 80004a8c <ilock>
  ip_a->nlink = 1;
    8000697c:	4a85                	li	s5,1
    8000697e:	05549523          	sh	s5,74(s1)
  iupdate(ip_a);
    80006982:	8526                	mv	a0,s1
    80006984:	ffffe097          	auipc	ra,0xffffe
    80006988:	03c080e7          	jalr	60(ra) # 800049c0 <iupdate>
  iunlock(ip_a);
    8000698c:	8526                	mv	a0,s1
    8000698e:	ffffe097          	auipc	ra,0xffffe
    80006992:	1c0080e7          	jalr	448(ra) # 80004b4e <iunlock>
  
  struct inode *ip_b = ialloc(dev, T_FILE);
    80006996:	4589                	li	a1,2
    80006998:	854e                	mv	a0,s3
    8000699a:	ffffe097          	auipc	ra,0xffffe
    8000699e:	f5a080e7          	jalr	-166(ra) # 800048f4 <ialloc>
    800069a2:	892a                	mv	s2,a0
  ilock(ip_b);
    800069a4:	ffffe097          	auipc	ra,0xffffe
    800069a8:	0e8080e7          	jalr	232(ra) # 80004a8c <ilock>
  ip_b->nlink = 1;
    800069ac:	05591523          	sh	s5,74(s2)
  iupdate(ip_b);
    800069b0:	854a                	mv	a0,s2
    800069b2:	ffffe097          	auipc	ra,0xffffe
    800069b6:	00e080e7          	jalr	14(ra) # 800049c0 <iupdate>
  iunlock(ip_b);
    800069ba:	854a                	mv	a0,s2
    800069bc:	ffffe097          	auipc	ra,0xffffe
    800069c0:	192080e7          	jalr	402(ra) # 80004b4e <iunlock>

  struct inode *ip_c = ialloc(dev, T_FILE);
    800069c4:	4589                	li	a1,2
    800069c6:	854e                	mv	a0,s3
    800069c8:	ffffe097          	auipc	ra,0xffffe
    800069cc:	f2c080e7          	jalr	-212(ra) # 800048f4 <ialloc>
    800069d0:	8a2a                	mv	s4,a0
  ilock(ip_c);
    800069d2:	ffffe097          	auipc	ra,0xffffe
    800069d6:	0ba080e7          	jalr	186(ra) # 80004a8c <ilock>
  ip_c->nlink = 1;
    800069da:	055a1523          	sh	s5,74(s4)
  iupdate(ip_c);
    800069de:	8552                	mv	a0,s4
    800069e0:	ffffe097          	auipc	ra,0xffffe
    800069e4:	fe0080e7          	jalr	-32(ra) # 800049c0 <iupdate>
  iunlock(ip_c);
    800069e8:	8552                	mv	a0,s4
    800069ea:	ffffe097          	auipc	ra,0xffffe
    800069ee:	164080e7          	jalr	356(ra) # 80004b4e <iunlock>

  // add entry
  if(dirlink(ip, "a.txt", ip_a->inum) < 0) panic("dirlink a.txt failed");
    800069f2:	40d0                	lw	a2,4(s1)
    800069f4:	00002597          	auipc	a1,0x2
    800069f8:	35c58593          	add	a1,a1,860 # 80008d50 <syscalls+0x5e8>
    800069fc:	855a                	mv	a0,s6
    800069fe:	fffff097          	auipc	ra,0xfffff
    80006a02:	69a080e7          	jalr	1690(ra) # 80006098 <dirlink>
    80006a06:	06054963          	bltz	a0,80006a78 <fsinit+0x1c8>
  if(dirlink(ip, "b.txt", ip_b->inum) < 0) panic("dirlink b.txt failed");
    80006a0a:	00492603          	lw	a2,4(s2)
    80006a0e:	00002597          	auipc	a1,0x2
    80006a12:	36258593          	add	a1,a1,866 # 80008d70 <syscalls+0x608>
    80006a16:	855a                	mv	a0,s6
    80006a18:	fffff097          	auipc	ra,0xfffff
    80006a1c:	680080e7          	jalr	1664(ra) # 80006098 <dirlink>
    80006a20:	06054463          	bltz	a0,80006a88 <fsinit+0x1d8>
  if(dirlink(ip, "c.txt", ip_c->inum) < 0) panic("dirlink c.txt failed");
    80006a24:	004a2603          	lw	a2,4(s4)
    80006a28:	00002597          	auipc	a1,0x2
    80006a2c:	36858593          	add	a1,a1,872 # 80008d90 <syscalls+0x628>
    80006a30:	855a                	mv	a0,s6
    80006a32:	fffff097          	auipc	ra,0xfffff
    80006a36:	666080e7          	jalr	1638(ra) # 80006098 <dirlink>
    80006a3a:	04054f63          	bltz	a0,80006a98 <fsinit+0x1e8>

  // 第二次查看
  dir_print(ip);
    80006a3e:	855a                	mv	a0,s6
    80006a40:	fffff097          	auipc	ra,0xfffff
    80006a44:	744080e7          	jalr	1860(ra) # 80006184 <dir_print>

  // 第一次检查
  struct inode *tmp;
  if((tmp = dirlookup(ip, "b.txt", 0)) == 0) panic("dirlookup b.txt failed");
    80006a48:	4601                	li	a2,0
    80006a4a:	00002597          	auipc	a1,0x2
    80006a4e:	32658593          	add	a1,a1,806 # 80008d70 <syscalls+0x608>
    80006a52:	855a                	mv	a0,s6
    80006a54:	fffff097          	auipc	ra,0xfffff
    80006a58:	436080e7          	jalr	1078(ra) # 80005e8a <dirlookup>
    80006a5c:	c531                	beqz	a0,80006aa8 <fsinit+0x1f8>
  if(tmp->inum != ip_b->inum) panic("b.txt inum mismatch");
    80006a5e:	4158                	lw	a4,4(a0)
    80006a60:	00492783          	lw	a5,4(s2)
    80006a64:	04f70a63          	beq	a4,a5,80006ab8 <fsinit+0x208>
    80006a68:	00002517          	auipc	a0,0x2
    80006a6c:	36050513          	add	a0,a0,864 # 80008dc8 <syscalls+0x660>
    80006a70:	ffffa097          	auipc	ra,0xffffa
    80006a74:	770080e7          	jalr	1904(ra) # 800011e0 <panic>
  if(dirlink(ip, "a.txt", ip_a->inum) < 0) panic("dirlink a.txt failed");
    80006a78:	00002517          	auipc	a0,0x2
    80006a7c:	2e050513          	add	a0,a0,736 # 80008d58 <syscalls+0x5f0>
    80006a80:	ffffa097          	auipc	ra,0xffffa
    80006a84:	760080e7          	jalr	1888(ra) # 800011e0 <panic>
  if(dirlink(ip, "b.txt", ip_b->inum) < 0) panic("dirlink b.txt failed");
    80006a88:	00002517          	auipc	a0,0x2
    80006a8c:	2f050513          	add	a0,a0,752 # 80008d78 <syscalls+0x610>
    80006a90:	ffffa097          	auipc	ra,0xffffa
    80006a94:	750080e7          	jalr	1872(ra) # 800011e0 <panic>
  if(dirlink(ip, "c.txt", ip_c->inum) < 0) panic("dirlink c.txt failed");
    80006a98:	00002517          	auipc	a0,0x2
    80006a9c:	30050513          	add	a0,a0,768 # 80008d98 <syscalls+0x630>
    80006aa0:	ffffa097          	auipc	ra,0xffffa
    80006aa4:	740080e7          	jalr	1856(ra) # 800011e0 <panic>
  if((tmp = dirlookup(ip, "b.txt", 0)) == 0) panic("dirlookup b.txt failed");
    80006aa8:	00002517          	auipc	a0,0x2
    80006aac:	30850513          	add	a0,a0,776 # 80008db0 <syscalls+0x648>
    80006ab0:	ffffa097          	auipc	ra,0xffffa
    80006ab4:	730080e7          	jalr	1840(ra) # 800011e0 <panic>
  iput(tmp); 
    80006ab8:	ffffe097          	auipc	ra,0xffffe
    80006abc:	18e080e7          	jalr	398(ra) # 80004c46 <iput>

  // delete entry
  if(dir_unlink(ip, "a.txt") < 0) panic("dir_unlink a.txt failed");
    80006ac0:	00002597          	auipc	a1,0x2
    80006ac4:	29058593          	add	a1,a1,656 # 80008d50 <syscalls+0x5e8>
    80006ac8:	855a                	mv	a0,s6
    80006aca:	fffff097          	auipc	ra,0xfffff
    80006ace:	762080e7          	jalr	1890(ra) # 8000622c <dir_unlink>
    80006ad2:	08054563          	bltz	a0,80006b5c <fsinit+0x2ac>

  // 第三次查看
  dir_print(ip);
    80006ad6:	855a                	mv	a0,s6
    80006ad8:	fffff097          	auipc	ra,0xfffff
    80006adc:	6ac080e7          	jalr	1708(ra) # 80006184 <dir_print>

  // add entry
  struct inode *ip_d = ialloc(dev, T_FILE);
    80006ae0:	4589                	li	a1,2
    80006ae2:	854e                	mv	a0,s3
    80006ae4:	ffffe097          	auipc	ra,0xffffe
    80006ae8:	e10080e7          	jalr	-496(ra) # 800048f4 <ialloc>
    80006aec:	89aa                	mv	s3,a0
  ilock(ip_d);
    80006aee:	ffffe097          	auipc	ra,0xffffe
    80006af2:	f9e080e7          	jalr	-98(ra) # 80004a8c <ilock>
  ip_d->nlink = 1;
    80006af6:	4785                	li	a5,1
    80006af8:	04f99523          	sh	a5,74(s3)
  iupdate(ip_d);
    80006afc:	854e                	mv	a0,s3
    80006afe:	ffffe097          	auipc	ra,0xffffe
    80006b02:	ec2080e7          	jalr	-318(ra) # 800049c0 <iupdate>
  iunlock(ip_d);
    80006b06:	854e                	mv	a0,s3
    80006b08:	ffffe097          	auipc	ra,0xffffe
    80006b0c:	046080e7          	jalr	70(ra) # 80004b4e <iunlock>
  
  if(dirlink(ip, "d.txt", ip_d->inum) < 0) panic("dirlink d.txt failed");
    80006b10:	0049a603          	lw	a2,4(s3)
    80006b14:	00002597          	auipc	a1,0x2
    80006b18:	2e458593          	add	a1,a1,740 # 80008df8 <syscalls+0x690>
    80006b1c:	855a                	mv	a0,s6
    80006b1e:	fffff097          	auipc	ra,0xfffff
    80006b22:	57a080e7          	jalr	1402(ra) # 80006098 <dirlink>
    80006b26:	04054363          	bltz	a0,80006b6c <fsinit+0x2bc>

  // 第四次查看
  dir_print(ip);
    80006b2a:	855a                	mv	a0,s6
    80006b2c:	fffff097          	auipc	ra,0xfffff
    80006b30:	658080e7          	jalr	1624(ra) # 80006184 <dir_print>

  // 第二次检查
  // dirlink should fail if entry exists
  if(dirlink(ip, "d.txt", ip_d->inum) == 0) panic("dirlink d.txt should fail");
    80006b34:	0049a603          	lw	a2,4(s3)
    80006b38:	00002597          	auipc	a1,0x2
    80006b3c:	2c058593          	add	a1,a1,704 # 80008df8 <syscalls+0x690>
    80006b40:	855a                	mv	a0,s6
    80006b42:	fffff097          	auipc	ra,0xfffff
    80006b46:	556080e7          	jalr	1366(ra) # 80006098 <dirlink>
    80006b4a:	e90d                	bnez	a0,80006b7c <fsinit+0x2cc>
    80006b4c:	00002517          	auipc	a0,0x2
    80006b50:	2cc50513          	add	a0,a0,716 # 80008e18 <syscalls+0x6b0>
    80006b54:	ffffa097          	auipc	ra,0xffffa
    80006b58:	68c080e7          	jalr	1676(ra) # 800011e0 <panic>
  if(dir_unlink(ip, "a.txt") < 0) panic("dir_unlink a.txt failed");
    80006b5c:	00002517          	auipc	a0,0x2
    80006b60:	28450513          	add	a0,a0,644 # 80008de0 <syscalls+0x678>
    80006b64:	ffffa097          	auipc	ra,0xffffa
    80006b68:	67c080e7          	jalr	1660(ra) # 800011e0 <panic>
  if(dirlink(ip, "d.txt", ip_d->inum) < 0) panic("dirlink d.txt failed");
    80006b6c:	00002517          	auipc	a0,0x2
    80006b70:	29450513          	add	a0,a0,660 # 80008e00 <syscalls+0x698>
    80006b74:	ffffa097          	auipc	ra,0xffffa
    80006b78:	66c080e7          	jalr	1644(ra) # 800011e0 <panic>

  iunlockput(ip);
    80006b7c:	855a                	mv	a0,s6
    80006b7e:	ffffe097          	auipc	ra,0xffffe
    80006b82:	170080e7          	jalr	368(ra) # 80004cee <iunlockput>
  
  // Release references to allocated inodes
  iput(ip_a);
    80006b86:	8526                	mv	a0,s1
    80006b88:	ffffe097          	auipc	ra,0xffffe
    80006b8c:	0be080e7          	jalr	190(ra) # 80004c46 <iput>
  iput(ip_b);
    80006b90:	854a                	mv	a0,s2
    80006b92:	ffffe097          	auipc	ra,0xffffe
    80006b96:	0b4080e7          	jalr	180(ra) # 80004c46 <iput>
  iput(ip_c);
    80006b9a:	8552                	mv	a0,s4
    80006b9c:	ffffe097          	auipc	ra,0xffffe
    80006ba0:	0aa080e7          	jalr	170(ra) # 80004c46 <iput>
  iput(ip_d);
    80006ba4:	854e                	mv	a0,s3
    80006ba6:	ffffe097          	auipc	ra,0xffffe
    80006baa:	0a0080e7          	jalr	160(ra) # 80004c46 <iput>

  end_op();
    80006bae:	fffff097          	auipc	ra,0xfffff
    80006bb2:	bea080e7          	jalr	-1046(ra) # 80005798 <end_op>

  printf("dir test success\n");
    80006bb6:	00002517          	auipc	a0,0x2
    80006bba:	28250513          	add	a0,a0,642 # 80008e38 <syscalls+0x6d0>
    80006bbe:	ffffa097          	auipc	ra,0xffffa
    80006bc2:	66c080e7          	jalr	1644(ra) # 8000122a <printf>

  while (1);
    80006bc6:	a001                	j	80006bc6 <fsinit+0x316>

0000000080006bc8 <initcode_start>:
    80006bc8:	00000097          	.word	0x00000097
    80006bcc:	0bc080e7          	.word	0x0bc080e7
    80006bd0:	0000a001          	.word	0x0000a001
    80006bd4:	ff010113          	.word	0xff010113
    80006bd8:	00813423          	.word	0x00813423
    80006bdc:	01010413          	.word	0x01010413
    80006be0:	00000313          	.word	0x00000313
    80006be4:	08054a63          	.word	0x08054a63
    80006be8:	00058693          	.word	0x00058693
    80006bec:	00058613          	.word	0x00058613
    80006bf0:	00000793          	.word	0x00000793
    80006bf4:	00a00813          	.word	0x00a00813
    80006bf8:	00078893          	.word	0x00078893
    80006bfc:	0017879b          	.word	0x0017879b
    80006c00:	0305673b          	.word	0x0305673b
    80006c04:	0307071b          	.word	0x0307071b
    80006c08:	00e60023          	.word	0x00e60023
    80006c0c:	0305453b          	.word	0x0305453b
    80006c10:	00160613          	.word	0x00160613
    80006c14:	fe0512e3          	.word	0xfe0512e3
    80006c18:	00030a63          	.word	0x00030a63
    80006c1c:	00f587b3          	.word	0x00f587b3
    80006c20:	02d00713          	.word	0x02d00713
    80006c24:	00e78023          	.word	0x00e78023
    80006c28:	0028879b          	.word	0x0028879b
    80006c2c:	00f58733          	.word	0x00f58733
    80006c30:	00070023          	.word	0x00070023
    80006c34:	fff7871b          	.word	0xfff7871b
    80006c38:	02e05a63          	.word	0x02e05a63
    80006c3c:	00e585b3          	.word	0x00e585b3
    80006c40:	fff7879b          	.word	0xfff7879b
    80006c44:	0006c703          	.word	0x0006c703
    80006c48:	0005c603          	.word	0x0005c603
    80006c4c:	00c68023          	.word	0x00c68023
    80006c50:	00e58023          	.word	0x00e58023
    80006c54:	0015071b          	.word	0x0015071b
    80006c58:	0007051b          	.word	0x0007051b
    80006c5c:	00168693          	.word	0x00168693
    80006c60:	fff58593          	.word	0xfff58593
    80006c64:	40e7873b          	.word	0x40e7873b
    80006c68:	fce54ee3          	.word	0xfce54ee3
    80006c6c:	00813403          	.word	0x00813403
    80006c70:	01010113          	.word	0x01010113
    80006c74:	00008067          	.word	0x00008067
    80006c78:	40a0053b          	.word	0x40a0053b
    80006c7c:	00100313          	.word	0x00100313
    80006c80:	f69ff06f          	.word	0xf69ff06f
    80006c84:	ba010113          	.word	0xba010113
    80006c88:	44813c23          	.word	0x44813c23
    80006c8c:	46010413          	.word	0x46010413
    80006c90:	00000893          	.word	0x00000893
    80006c94:	00000517          	.word	0x00000517
    80006c98:	11c50513          	.word	0x11c50513
    80006c9c:	00000073          	.word	0x00000073
    80006ca0:	01600893          	.word	0x01600893
    80006ca4:	00000073          	.word	0x00000073
    80006ca8:	ba040713          	.word	0xba040713
    80006cac:	06400793          	.word	0x06400793
    80006cb0:	fff00813          	.word	0xfff00813
    80006cb4:	06a00613          	.word	0x06a00613
    80006cb8:	01400893          	.word	0x01400893
    80006cbc:	00078513          	.word	0x00078513
    80006cc0:	bf040593          	.word	0xbf040593
    80006cc4:	00000073          	.word	0x00000073
    80006cc8:	00a73023          	.word	0x00a73023
    80006ccc:	00f586b3          	.word	0x00f586b3
    80006cd0:	f9068e23          	.word	0xf9068e23
    80006cd4:	01700893          	.word	0x01700893
    80006cd8:	00000073          	.word	0x00000073
    80006cdc:	00178793          	.word	0x00178793
    80006ce0:	00870713          	.word	0x00870713
    80006ce4:	fcc79ae3          	.word	0xfcc79ae3
    80006ce8:	00000893          	.word	0x00000893
    80006cec:	00000517          	.word	0x00000517
    80006cf0:	0d450513          	.word	0x0d450513
    80006cf4:	00000073          	.word	0x00000073
    80006cf8:	01600893          	.word	0x01600893
    80006cfc:	00000073          	.word	0x00000073
    80006d00:	01500893          	.word	0x01500893
    80006d04:	bb843503          	.word	0xbb843503
    80006d08:	00000073          	.word	0x00000073
    80006d0c:	ba043503          	.word	0xba043503
    80006d10:	00000073          	.word	0x00000073
    80006d14:	00000893          	.word	0x00000893
    80006d18:	00000517          	.word	0x00000517
    80006d1c:	0b850513          	.word	0x0b850513
    80006d20:	00000073          	.word	0x00000073
    80006d24:	01600893          	.word	0x01600893
    80006d28:	00000073          	.word	0x00000073
    80006d2c:	01400893          	.word	0x01400893
    80006d30:	06a00513          	.word	0x06a00513
    80006d34:	00000073          	.word	0x00000073
    80006d38:	bca43823          	.word	0xbca43823
    80006d3c:	06700513          	.word	0x06700513
    80006d40:	00000073          	.word	0x00000073
    80006d44:	bca43c23          	.word	0xbca43c23
    80006d48:	00000893          	.word	0x00000893
    80006d4c:	00000517          	.word	0x00000517
    80006d50:	09450513          	.word	0x09450513
    80006d54:	00000073          	.word	0x00000073
    80006d58:	01600893          	.word	0x01600893
    80006d5c:	00000073          	.word	0x00000073
    80006d60:	01500893          	.word	0x01500893
    80006d64:	bd843503          	.word	0xbd843503
    80006d68:	00000073          	.word	0x00000073
    80006d6c:	bd043503          	.word	0xbd043503
    80006d70:	00000073          	.word	0x00000073
    80006d74:	bc843503          	.word	0xbc843503
    80006d78:	00000073          	.word	0x00000073
    80006d7c:	bc043503          	.word	0xbc043503
    80006d80:	00000073          	.word	0x00000073
    80006d84:	bb043503          	.word	0xbb043503
    80006d88:	00000073          	.word	0x00000073
    80006d8c:	ba843503          	.word	0xba843503
    80006d90:	00000073          	.word	0x00000073
    80006d94:	00000893          	.word	0x00000893
    80006d98:	00000517          	.word	0x00000517
    80006d9c:	05850513          	.word	0x05850513
    80006da0:	00000073          	.word	0x00000073
    80006da4:	01600893          	.word	0x01600893
    80006da8:	00000073          	.word	0x00000073
    80006dac:	0000006f          	.word	0x0000006f
    80006db0:	6174730a          	.word	0x6174730a
    80006db4:	312d6574          	.word	0x312d6574
    80006db8:	0000003a          	.word	0x0000003a
    80006dbc:	00000000          	.word	0x00000000
    80006dc0:	6174730a          	.word	0x6174730a
    80006dc4:	322d6574          	.word	0x322d6574
    80006dc8:	0000003a          	.word	0x0000003a
    80006dcc:	00000000          	.word	0x00000000
    80006dd0:	6174730a          	.word	0x6174730a
    80006dd4:	332d6574          	.word	0x332d6574
    80006dd8:	0000003a          	.word	0x0000003a
    80006ddc:	00000000          	.word	0x00000000
    80006de0:	6174730a          	.word	0x6174730a
    80006de4:	342d6574          	.word	0x342d6574
    80006de8:	0000003a          	.word	0x0000003a
    80006dec:	00000000          	.word	0x00000000
    80006df0:	6174730a          	.word	0x6174730a
    80006df4:	352d6574          	.word	0x352d6574
    80006df8:	003a                	.short	0x003a

0000000080006dfa <initcode_end>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    80006dfa:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    80006dfe:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    80006e02:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    80006e04:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    80006e06:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    80006e0a:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    80006e0e:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    80006e12:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    80006e16:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    80006e1a:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    80006e1e:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    80006e22:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    80006e26:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    80006e2a:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    80006e2e:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)      # 恢复栈指针
    80006e32:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    80006e36:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    80006e38:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    80006e3a:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    80006e3e:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    80006e42:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    80006e46:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    80006e4a:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    80006e4e:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    80006e52:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    80006e56:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    80006e5a:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    80006e5e:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    80006e62:	8082                	ret
	...

0000000080006e70 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    80006e70:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    80006e72:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80006e74:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80006e76:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80006e78:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80006e7a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    80006e7c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    80006e7e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    80006e80:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    80006e82:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    80006e84:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80006e86:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80006e88:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80006e8a:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80006e8c:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80006e8e:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    80006e90:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    80006e92:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    80006e94:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    80006e96:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    80006e98:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    80006e9a:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    80006e9c:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    80006e9e:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    80006ea0:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    80006ea2:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    80006ea4:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    80006ea6:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    80006ea8:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80006eaa:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80006eac:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80006eae:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    80006eb0:	ffffc097          	auipc	ra,0xffffc
    80006eb4:	21e080e7          	jalr	542(ra) # 800030ce <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    80006eb8:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    80006eba:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    80006ebc:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    80006ebe:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80006ec0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80006ec2:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    80006ec4:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    80006ec6:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    80006ec8:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80006eca:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80006ecc:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    80006ece:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    80006ed0:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    80006ed2:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80006ed4:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80006ed6:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    80006ed8:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    80006eda:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    80006edc:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    80006ede:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    80006ee0:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    80006ee2:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    80006ee4:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    80006ee6:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    80006ee8:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    80006eea:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    80006eec:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80006eee:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80006ef0:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80006ef2:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    80006ef4:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    80006ef6:	10200073          	sret
    80006efa:	0001                	nop
    80006efc:	00000013          	nop

0000000080006f00 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    80006f00:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    80006f04:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    80006f06:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    80006f08:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    80006f0a:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    80006f0c:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    80006f0e:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    80006f10:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    80006f12:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    80006f14:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    80006f16:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    80006f1a:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    80006f1c:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    80006f1e:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80006f20:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    80006f24:	30200073          	mret
    80006f28:	00000013          	nop
    80006f2c:	00000013          	nop
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	9282                	jalr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
