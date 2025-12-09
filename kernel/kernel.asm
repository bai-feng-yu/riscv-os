
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
    80000004:	bb010113          	add	sp,sp,-1104 # 80008bb0 <stack0>
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
    8000001a:	b4a50513          	add	a0,a0,-1206 # 80008b60 <started>
    la a1, end
    8000001e:	00022597          	auipc	a1,0x22
    80000022:	00a58593          	add	a1,a1,10 # 80022028 <end>

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
    8000004e:	b1670713          	add	a4,a4,-1258 # 80008b60 <started>
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
    80000084:	fde080e7          	jalr	-34(ra) # 8000305e <trapinithart>
    plicinithart();   // 向PLIC请求设备中断
    80000088:	00001097          	auipc	ra,0x1
    8000008c:	940080e7          	jalr	-1728(ra) # 800009c8 <plicinithart>
  }
  // 所有CPU都进入调度器，开始调度用户进程
  scheduler(); 
    80000090:	00003097          	auipc	ra,0x3
    80000094:	172080e7          	jalr	370(ra) # 80003202 <scheduler>
    initlock(&start_lock,"start_lock");
    80000098:	00008597          	auipc	a1,0x8
    8000009c:	f7858593          	add	a1,a1,-136 # 80008010 <etext+0x10>
    800000a0:	00009517          	auipc	a0,0x9
    800000a4:	af050513          	add	a0,a0,-1296 # 80008b90 <start_lock>
    800000a8:	00003097          	auipc	ra,0x3
    800000ac:	e04080e7          	jalr	-508(ra) # 80002eac <initlock>
    consoleinit();       // 初始化控制台
    800000b0:	00001097          	auipc	ra,0x1
    800000b4:	8b6080e7          	jalr	-1866(ra) # 80000966 <consoleinit>
    printfinit();        // 初始化printf功能
    800000b8:	00001097          	auipc	ra,0x1
    800000bc:	352080e7          	jalr	850(ra) # 8000140a <printfinit>
    printf("\n");
    800000c0:	00008517          	auipc	a0,0x8
    800000c4:	f7050513          	add	a0,a0,-144 # 80008030 <etext+0x30>
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
    80000106:	1b8080e7          	jalr	440(ra) # 800022ba <procinit>
    timer_create();      // 陷阱向量(时钟中断）初始化
    8000010a:	00000097          	auipc	ra,0x0
    8000010e:	13c080e7          	jalr	316(ra) # 80000246 <timer_create>
    trapinithart();      // 安装内核陷阱向量
    80000112:	00003097          	auipc	ra,0x3
    80000116:	f4c080e7          	jalr	-180(ra) # 8000305e <trapinithart>
    plicinit();          // 设置中断控制器
    8000011a:	00001097          	auipc	ra,0x1
    8000011e:	898080e7          	jalr	-1896(ra) # 800009b2 <plicinit>
    plicinithart();      // 向PLIC请求设备中断
    80000122:	00001097          	auipc	ra,0x1
    80000126:	8a6080e7          	jalr	-1882(ra) # 800009c8 <plicinithart>
    binit();             // 缓冲区缓存初始化
    8000012a:	00004097          	auipc	ra,0x4
    8000012e:	4a2080e7          	jalr	1186(ra) # 800045cc <binit>
    iinit();             // inode表初始化
    80000132:	00005097          	auipc	ra,0x5
    80000136:	78c080e7          	jalr	1932(ra) # 800058be <iinit>
    fileinit();          // 文件表初始化
    8000013a:	00005097          	auipc	ra,0x5
    8000013e:	be0080e7          	jalr	-1056(ra) # 80004d1a <fileinit>
    virtio_disk_init();  // 虚拟硬盘初始化
    80000142:	00001097          	auipc	ra,0x1
    80000146:	98e080e7          	jalr	-1650(ra) # 80000ad0 <virtio_disk_init>
    userinit();   // 创建第一个用户进程 userinit();   
    8000014a:	00002097          	auipc	ra,0x2
    8000014e:	468080e7          	jalr	1128(ra) # 800025b2 <userinit>
    started = 1;         // 标记系统启动完成
    80000152:	4785                	li	a5,1
    80000154:	00009717          	auipc	a4,0x9
    80000158:	a0f72623          	sw	a5,-1524(a4) # 80008b60 <started>
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
    80000170:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc7d7>
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
    8000020e:	9a670713          	add	a4,a4,-1626 # 80010bb0 <timer_scratch>
    80000212:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    80000214:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000216:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000218:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000021c:	00006797          	auipc	a5,0x6
    80000220:	28478793          	add	a5,a5,644 # 800064a0 <timervec>
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
    8000025a:	aa250513          	add	a0,a0,-1374 # 80010cf8 <sys_timer+0x8>
    8000025e:	00003097          	auipc	ra,0x3
    80000262:	c4e080e7          	jalr	-946(ra) # 80002eac <initlock>
    sys_timer.ticks = 0;
    80000266:	00011797          	auipc	a5,0x11
    8000026a:	a807b523          	sd	zero,-1398(a5) # 80010cf0 <sys_timer>
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
    80000286:	92e90913          	add	s2,s2,-1746 # 80010bb0 <timer_scratch>
    8000028a:	00011497          	auipc	s1,0x11
    8000028e:	a6e48493          	add	s1,s1,-1426 # 80010cf8 <sys_timer+0x8>
    80000292:	8526                	mv	a0,s1
    80000294:	00003097          	auipc	ra,0x3
    80000298:	ca8080e7          	jalr	-856(ra) # 80002f3c <acquire>
    sys_timer.ticks++;
    8000029c:	14093783          	ld	a5,320(s2)
    800002a0:	0785                	add	a5,a5,1
    800002a2:	14f93023          	sd	a5,320(s2)
    // printf("ticks: %d\n", sys_timer.ticks);
    release(&sys_timer.lk);
    800002a6:	8526                	mv	a0,s1
    800002a8:	00003097          	auipc	ra,0x3
    800002ac:	d48080e7          	jalr	-696(ra) # 80002ff0 <release>
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
    800002cc:	a3048493          	add	s1,s1,-1488 # 80010cf8 <sys_timer+0x8>
    800002d0:	8526                	mv	a0,s1
    800002d2:	00003097          	auipc	ra,0x3
    800002d6:	c6a080e7          	jalr	-918(ra) # 80002f3c <acquire>
    xticks = sys_timer.ticks;
    800002da:	00011917          	auipc	s2,0x11
    800002de:	a1693903          	ld	s2,-1514(s2) # 80010cf0 <sys_timer>
    release(&sys_timer.lk);
    800002e2:	8526                	mv	a0,s1
    800002e4:	00003097          	auipc	ra,0x3
    800002e8:	d0c080e7          	jalr	-756(ra) # 80002ff0 <release>
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
    80000336:	9de50513          	add	a0,a0,-1570 # 80010d10 <uart_tx_lock>
    8000033a:	00003097          	auipc	ra,0x3
    8000033e:	b72080e7          	jalr	-1166(ra) # 80002eac <initlock>
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
    8000035a:	b9a080e7          	jalr	-1126(ra) # 80002ef0 <push_off>
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    8000035e:	00009797          	auipc	a5,0x9
    80000362:	81a7a783          	lw	a5,-2022(a5) # 80008b78 <panicked>
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
    80000388:	c0c080e7          	jalr	-1012(ra) # 80002f90 <pop_off>
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
    80000396:	00008797          	auipc	a5,0x8
    8000039a:	7d27b783          	ld	a5,2002(a5) # 80008b68 <uart_tx_r>
    8000039e:	00008717          	auipc	a4,0x8
    800003a2:	7d273703          	ld	a4,2002(a4) # 80008b70 <uart_tx_w>
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
    800003c4:	950a0a13          	add	s4,s4,-1712 # 80010d10 <uart_tx_lock>
    uart_tx_r += 1;
    800003c8:	00008497          	auipc	s1,0x8
    800003cc:	7a048493          	add	s1,s1,1952 # 80008b68 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800003d0:	00008997          	auipc	s3,0x8
    800003d4:	7a098993          	add	s3,s3,1952 # 80008b70 <uart_tx_w>
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
    800003f6:	506080e7          	jalr	1286(ra) # 800028f8 <wakeup>
    
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
    80000432:	8e250513          	add	a0,a0,-1822 # 80010d10 <uart_tx_lock>
    80000436:	00003097          	auipc	ra,0x3
    8000043a:	b06080e7          	jalr	-1274(ra) # 80002f3c <acquire>
  if(panicked){
    8000043e:	00008797          	auipc	a5,0x8
    80000442:	73a7a783          	lw	a5,1850(a5) # 80008b78 <panicked>
    80000446:	e7c9                	bnez	a5,800004d0 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000448:	00008717          	auipc	a4,0x8
    8000044c:	72873703          	ld	a4,1832(a4) # 80008b70 <uart_tx_w>
    80000450:	00008797          	auipc	a5,0x8
    80000454:	7187b783          	ld	a5,1816(a5) # 80008b68 <uart_tx_r>
    80000458:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000045c:	00011997          	auipc	s3,0x11
    80000460:	8b498993          	add	s3,s3,-1868 # 80010d10 <uart_tx_lock>
    80000464:	00008497          	auipc	s1,0x8
    80000468:	70448493          	add	s1,s1,1796 # 80008b68 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000046c:	00008917          	auipc	s2,0x8
    80000470:	70490913          	add	s2,s2,1796 # 80008b70 <uart_tx_w>
    80000474:	00e79f63          	bne	a5,a4,80000492 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000478:	85ce                	mv	a1,s3
    8000047a:	8526                	mv	a0,s1
    8000047c:	00002097          	auipc	ra,0x2
    80000480:	40e080e7          	jalr	1038(ra) # 8000288a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000484:	00093703          	ld	a4,0(s2)
    80000488:	609c                	ld	a5,0(s1)
    8000048a:	02078793          	add	a5,a5,32
    8000048e:	fee785e3          	beq	a5,a4,80000478 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000492:	00011497          	auipc	s1,0x11
    80000496:	87e48493          	add	s1,s1,-1922 # 80010d10 <uart_tx_lock>
    8000049a:	01f77793          	and	a5,a4,31
    8000049e:	97a6                	add	a5,a5,s1
    800004a0:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800004a4:	0705                	add	a4,a4,1
    800004a6:	00008797          	auipc	a5,0x8
    800004aa:	6ce7b523          	sd	a4,1738(a5) # 80008b70 <uart_tx_w>
  uartstart();
    800004ae:	00000097          	auipc	ra,0x0
    800004b2:	ee8080e7          	jalr	-280(ra) # 80000396 <uartstart>
  release(&uart_tx_lock);
    800004b6:	8526                	mv	a0,s1
    800004b8:	00003097          	auipc	ra,0x3
    800004bc:	b38080e7          	jalr	-1224(ra) # 80002ff0 <release>
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
    8000059e:	792080e7          	jalr	1938(ra) # 80002d2c <either_copyin>
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
    800005f4:	00010517          	auipc	a0,0x10
    800005f8:	75450513          	add	a0,a0,1876 # 80010d48 <cons>
    800005fc:	00003097          	auipc	ra,0x3
    80000600:	940080e7          	jalr	-1728(ra) # 80002f3c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000604:	00010497          	auipc	s1,0x10
    80000608:	74448493          	add	s1,s1,1860 # 80010d48 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000060c:	00010917          	auipc	s2,0x10
    80000610:	7d490913          	add	s2,s2,2004 # 80010de0 <cons+0x98>
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
    80000630:	3fa080e7          	jalr	1018(ra) # 80002a26 <killed>
    80000634:	ed2d                	bnez	a0,800006ae <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    80000636:	85a6                	mv	a1,s1
    80000638:	854a                	mv	a0,s2
    8000063a:	00002097          	auipc	ra,0x2
    8000063e:	250080e7          	jalr	592(ra) # 8000288a <sleep>
    while(cons.r == cons.w){
    80000642:	0984a783          	lw	a5,152(s1)
    80000646:	09c4a703          	lw	a4,156(s1)
    8000064a:	fcf70de3          	beq	a4,a5,80000624 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    8000064e:	00010717          	auipc	a4,0x10
    80000652:	6fa70713          	add	a4,a4,1786 # 80010d48 <cons>
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
    80000684:	656080e7          	jalr	1622(ra) # 80002cd6 <either_copyout>
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
    80000698:	00010517          	auipc	a0,0x10
    8000069c:	6b050513          	add	a0,a0,1712 # 80010d48 <cons>
    800006a0:	00003097          	auipc	ra,0x3
    800006a4:	950080e7          	jalr	-1712(ra) # 80002ff0 <release>

  return target - n;
    800006a8:	413b053b          	subw	a0,s6,s3
    800006ac:	a811                	j	800006c0 <consoleread+0xec>
        release(&cons.lock);
    800006ae:	00010517          	auipc	a0,0x10
    800006b2:	69a50513          	add	a0,a0,1690 # 80010d48 <cons>
    800006b6:	00003097          	auipc	ra,0x3
    800006ba:	93a080e7          	jalr	-1734(ra) # 80002ff0 <release>
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
    800006de:	00010717          	auipc	a4,0x10
    800006e2:	70f72123          	sw	a5,1794(a4) # 80010de0 <cons+0x98>
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
    80000744:	8f050513          	add	a0,a0,-1808 # 80008030 <etext+0x30>
    80000748:	00001097          	auipc	ra,0x1
    8000074c:	ae2080e7          	jalr	-1310(ra) # 8000122a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80000750:	00011497          	auipc	s1,0x11
    80000754:	c3848493          	add	s1,s1,-968 # 80011388 <proc>
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
    8000076e:	8c6a0a13          	add	s4,s4,-1850 # 80008030 <etext+0x30>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80000772:	00008b97          	auipc	s7,0x8
    80000776:	926b8b93          	add	s7,s7,-1754 # 80008098 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    8000077a:	00016917          	auipc	s2,0x16
    8000077e:	60e90913          	add	s2,s2,1550 # 80016d88 <wait_lock>
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
    800007e2:	00010517          	auipc	a0,0x10
    800007e6:	56650513          	add	a0,a0,1382 # 80010d48 <cons>
    800007ea:	00002097          	auipc	ra,0x2
    800007ee:	752080e7          	jalr	1874(ra) # 80002f3c <acquire>

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
    80000810:	00010517          	auipc	a0,0x10
    80000814:	53850513          	add	a0,a0,1336 # 80010d48 <cons>
    80000818:	00002097          	auipc	ra,0x2
    8000081c:	7d8080e7          	jalr	2008(ra) # 80002ff0 <release>
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
    80000834:	00010717          	auipc	a4,0x10
    80000838:	51470713          	add	a4,a4,1300 # 80010d48 <cons>
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
    8000085e:	00010797          	auipc	a5,0x10
    80000862:	4ea78793          	add	a5,a5,1258 # 80010d48 <cons>
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
    8000088c:	00010797          	auipc	a5,0x10
    80000890:	5547a783          	lw	a5,1364(a5) # 80010de0 <cons+0x98>
    80000894:	9f1d                	subw	a4,a4,a5
    80000896:	08000793          	li	a5,128
    8000089a:	f6f71be3          	bne	a4,a5,80000810 <consoleintr+0x3c>
    8000089e:	a07d                	j	8000094c <consoleintr+0x178>
    while(cons.e != cons.w &&
    800008a0:	00010717          	auipc	a4,0x10
    800008a4:	4a870713          	add	a4,a4,1192 # 80010d48 <cons>
    800008a8:	0a072783          	lw	a5,160(a4)
    800008ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800008b0:	00010497          	auipc	s1,0x10
    800008b4:	49848493          	add	s1,s1,1176 # 80010d48 <cons>
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
    800008f0:	45c70713          	add	a4,a4,1116 # 80010d48 <cons>
    800008f4:	0a072783          	lw	a5,160(a4)
    800008f8:	09c72703          	lw	a4,156(a4)
    800008fc:	f0f70ae3          	beq	a4,a5,80000810 <consoleintr+0x3c>
      cons.e--;
    80000900:	37fd                	addw	a5,a5,-1
    80000902:	00010717          	auipc	a4,0x10
    80000906:	4ef72323          	sw	a5,1254(a4) # 80010de8 <cons+0xa0>
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
    8000092c:	42078793          	add	a5,a5,1056 # 80010d48 <cons>
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
    80000950:	48c7ac23          	sw	a2,1176(a5) # 80010de4 <cons+0x9c>
        wakeup(&cons.r);
    80000954:	00010517          	auipc	a0,0x10
    80000958:	48c50513          	add	a0,a0,1164 # 80010de0 <cons+0x98>
    8000095c:	00002097          	auipc	ra,0x2
    80000960:	f9c080e7          	jalr	-100(ra) # 800028f8 <wakeup>
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
    8000097a:	3d250513          	add	a0,a0,978 # 80010d48 <cons>
    8000097e:	00002097          	auipc	ra,0x2
    80000982:	52e080e7          	jalr	1326(ra) # 80002eac <initlock>

  uartinit();
    80000986:	00000097          	auipc	ra,0x0
    8000098a:	974080e7          	jalr	-1676(ra) # 800002fa <uartinit>

  devsw[CONSOLE].read = consoleread;
    8000098e:	0001f797          	auipc	a5,0x1f
    80000992:	b7a78793          	add	a5,a5,-1158 # 8001f508 <devsw>
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
    80000a60:	39478793          	add	a5,a5,916 # 80010df0 <disk>
    80000a64:	97aa                	add	a5,a5,a0
    80000a66:	0187c783          	lbu	a5,24(a5)
    80000a6a:	ebb9                	bnez	a5,80000ac0 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80000a6c:	00451693          	sll	a3,a0,0x4
    80000a70:	00010797          	auipc	a5,0x10
    80000a74:	38078793          	add	a5,a5,896 # 80010df0 <disk>
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
    80000a9c:	37050513          	add	a0,a0,880 # 80010e08 <disk+0x18>
    80000aa0:	00002097          	auipc	ra,0x2
    80000aa4:	e58080e7          	jalr	-424(ra) # 800028f8 <wakeup>
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
    80000ae8:	43450513          	add	a0,a0,1076 # 80010f18 <disk+0x128>
    80000aec:	00002097          	auipc	ra,0x2
    80000af0:	3c0080e7          	jalr	960(ra) # 80002eac <initlock>
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
    80000b40:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc737>
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
    80000b88:	26c48493          	add	s1,s1,620 # 80010df0 <disk>
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
    80000bb0:	24c73703          	ld	a4,588(a4) # 80010df8 <disk+0x8>
    80000bb4:	cb65                	beqz	a4,80000ca4 <virtio_disk_init+0x1d4>
    80000bb6:	c7fd                	beqz	a5,80000ca4 <virtio_disk_init+0x1d4>
  memset(disk.desc, 0, PGSIZE);
    80000bb8:	6605                	lui	a2,0x1
    80000bba:	4581                	li	a1,0
    80000bbc:	00000097          	auipc	ra,0x0
    80000bc0:	3dc080e7          	jalr	988(ra) # 80000f98 <memset>
  memset(disk.avail, 0, PGSIZE);
    80000bc4:	00010497          	auipc	s1,0x10
    80000bc8:	22c48493          	add	s1,s1,556 # 80010df0 <disk>
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
    80000ce6:	23650513          	add	a0,a0,566 # 80010f18 <disk+0x128>
    80000cea:	00002097          	auipc	ra,0x2
    80000cee:	252080e7          	jalr	594(ra) # 80002f3c <acquire>
  for(int i = 0; i < 3; i++){
    80000cf2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80000cf4:	44a1                	li	s1,8
      disk.free[i] = 0;
    80000cf6:	00010b17          	auipc	s6,0x10
    80000cfa:	0fab0b13          	add	s6,s6,250 # 80010df0 <disk>
  for(int i = 0; i < 3; i++){
    80000cfe:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80000d00:	00010c17          	auipc	s8,0x10
    80000d04:	218c0c13          	add	s8,s8,536 # 80010f18 <disk+0x128>
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
    80000d26:	0ce70713          	add	a4,a4,206 # 80010df0 <disk>
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
    80000d60:	0ac50513          	add	a0,a0,172 # 80010e08 <disk+0x18>
    80000d64:	00002097          	auipc	ra,0x2
    80000d68:	b26080e7          	jalr	-1242(ra) # 8000288a <sleep>
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
    80000d84:	07078793          	add	a5,a5,112 # 80010df0 <disk>
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
    80000e5a:	0c290913          	add	s2,s2,194 # 80010f18 <disk+0x128>
  while(b->disk == 1) {
    80000e5e:	4485                	li	s1,1
    80000e60:	00b79c63          	bne	a5,a1,80000e78 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80000e64:	85ca                	mv	a1,s2
    80000e66:	8552                	mv	a0,s4
    80000e68:	00002097          	auipc	ra,0x2
    80000e6c:	a22080e7          	jalr	-1502(ra) # 8000288a <sleep>
  while(b->disk == 1) {
    80000e70:	004a2783          	lw	a5,4(s4)
    80000e74:	fe9788e3          	beq	a5,s1,80000e64 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80000e78:	f9042903          	lw	s2,-112(s0)
    80000e7c:	00290713          	add	a4,s2,2
    80000e80:	0712                	sll	a4,a4,0x4
    80000e82:	00010797          	auipc	a5,0x10
    80000e86:	f6e78793          	add	a5,a5,-146 # 80010df0 <disk>
    80000e8a:	97ba                	add	a5,a5,a4
    80000e8c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80000e90:	00010997          	auipc	s3,0x10
    80000e94:	f6098993          	add	s3,s3,-160 # 80010df0 <disk>
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
    80000ebc:	06050513          	add	a0,a0,96 # 80010f18 <disk+0x128>
    80000ec0:	00002097          	auipc	ra,0x2
    80000ec4:	130080e7          	jalr	304(ra) # 80002ff0 <release>
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
    80000ef2:	f0248493          	add	s1,s1,-254 # 80010df0 <disk>
    80000ef6:	00010517          	auipc	a0,0x10
    80000efa:	02250513          	add	a0,a0,34 # 80010f18 <disk+0x128>
    80000efe:	00002097          	auipc	ra,0x2
    80000f02:	03e080e7          	jalr	62(ra) # 80002f3c <acquire>
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
    80000f52:	9aa080e7          	jalr	-1622(ra) # 800028f8 <wakeup>

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
    80000f72:	faa50513          	add	a0,a0,-86 # 80010f18 <disk+0x128>
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	07a080e7          	jalr	122(ra) # 80002ff0 <release>
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
    800011f0:	d407ae23          	sw	zero,-676(a5) # 80010f48 <pr+0x18>
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
    8000120e:	00007517          	auipc	a0,0x7
    80001212:	e2250513          	add	a0,a0,-478 # 80008030 <etext+0x30>
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	014080e7          	jalr	20(ra) # 8000122a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000121e:	4785                	li	a5,1
    80001220:	00008717          	auipc	a4,0x8
    80001224:	94f72c23          	sw	a5,-1704(a4) # 80008b78 <panicked>
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
    80001260:	cecdad83          	lw	s11,-788(s11) # 80010f48 <pr+0x18>
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
    8000129e:	c9650513          	add	a0,a0,-874 # 80010f30 <pr>
    800012a2:	00002097          	auipc	ra,0x2
    800012a6:	c9a080e7          	jalr	-870(ra) # 80002f3c <acquire>
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
    800013fc:	b3850513          	add	a0,a0,-1224 # 80010f30 <pr>
    80001400:	00002097          	auipc	ra,0x2
    80001404:	bf0080e7          	jalr	-1040(ra) # 80002ff0 <release>
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
    80001418:	b1c48493          	add	s1,s1,-1252 # 80010f30 <pr>
    8000141c:	00007597          	auipc	a1,0x7
    80001420:	dcc58593          	add	a1,a1,-564 # 800081e8 <states.0+0x150>
    80001424:	8526                	mv	a0,s1
    80001426:	00002097          	auipc	ra,0x2
    8000142a:	a86080e7          	jalr	-1402(ra) # 80002eac <initlock>
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
    80001454:	bd878793          	add	a5,a5,-1064 # 80022028 <end>
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
    80001474:	ae090913          	add	s2,s2,-1312 # 80010f50 <kmem>
    80001478:	854a                	mv	a0,s2
    8000147a:	00002097          	auipc	ra,0x2
    8000147e:	ac2080e7          	jalr	-1342(ra) # 80002f3c <acquire>
  r->next = kmem.freelist;  //头插
    80001482:	01893783          	ld	a5,24(s2)
    80001486:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80001488:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    8000148c:	854a                	mv	a0,s2
    8000148e:	00002097          	auipc	ra,0x2
    80001492:	b62080e7          	jalr	-1182(ra) # 80002ff0 <release>
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
    80001514:	a4050513          	add	a0,a0,-1472 # 80010f50 <kmem>
    80001518:	00002097          	auipc	ra,0x2
    8000151c:	994080e7          	jalr	-1644(ra) # 80002eac <initlock>
  freerange(end, (void*)PHYSTOP);
    80001520:	45c5                	li	a1,17
    80001522:	05ee                	sll	a1,a1,0x1b
    80001524:	00021517          	auipc	a0,0x21
    80001528:	b0450513          	add	a0,a0,-1276 # 80022028 <end>
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
    8000154a:	a0a48493          	add	s1,s1,-1526 # 80010f50 <kmem>
    8000154e:	8526                	mv	a0,s1
    80001550:	00002097          	auipc	ra,0x2
    80001554:	9ec080e7          	jalr	-1556(ra) # 80002f3c <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80001558:	6c84                	ld	s1,24(s1)
  if(r)
    8000155a:	c885                	beqz	s1,8000158a <kalloc+0x4e>
    kmem.freelist = r->next;
    8000155c:	609c                	ld	a5,0(s1)
    8000155e:	00010517          	auipc	a0,0x10
    80001562:	9f250513          	add	a0,a0,-1550 # 80010f50 <kmem>
    80001566:	ed1c                	sd	a5,24(a0)
  else 
    panic("kalloc: out of memory");
  release(&kmem.lock);
    80001568:	00002097          	auipc	ra,0x2
    8000156c:	a88080e7          	jalr	-1400(ra) # 80002ff0 <release>

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
    800015a4:	00007797          	auipc	a5,0x7
    800015a8:	5dc7b783          	ld	a5,1500(a5) # 80008b80 <kernel_pagetable>
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
    80001624:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcfcf>
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
    80001824:	a02080e7          	jalr	-1534(ra) # 80002222 <proc_mapstacks>
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
    8000184a:	32a7bd23          	sd	a0,826(a5) # 80008b80 <kernel_pagetable>
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
    80001946:	00006517          	auipc	a0,0x6
    8000194a:	6ea50513          	add	a0,a0,1770 # 80008030 <etext+0x30>
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
    80001a06:	00006b97          	auipc	s7,0x6
    80001a0a:	62ab8b93          	add	s7,s7,1578 # 80008030 <etext+0x30>
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
    80001e46:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcfd8>
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
    80002102:	e7250513          	add	a0,a0,-398 # 80010f70 <cpus>
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
    8000211c:	dd8080e7          	jalr	-552(ra) # 80002ef0 <push_off>
    80002120:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002122:	2781                	sext.w	a5,a5
    80002124:	079e                	sll	a5,a5,0x7
    80002126:	0000f717          	auipc	a4,0xf
    8000212a:	e4a70713          	add	a4,a4,-438 # 80010f70 <cpus>
    8000212e:	97ba                	add	a5,a5,a4
    80002130:	6784                	ld	s1,8(a5)
  pop_off();
    80002132:	00001097          	auipc	ra,0x1
    80002136:	e5e080e7          	jalr	-418(ra) # 80002f90 <pop_off>
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
    80002156:	21e90913          	add	s2,s2,542 # 80011370 <pid_lock>
    8000215a:	854a                	mv	a0,s2
    8000215c:	00001097          	auipc	ra,0x1
    80002160:	de0080e7          	jalr	-544(ra) # 80002f3c <acquire>
  pid = nextpid;
    80002164:	00007797          	auipc	a5,0x7
    80002168:	9ec78793          	add	a5,a5,-1556 # 80008b50 <nextpid>
    8000216c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    8000216e:	0014871b          	addw	a4,s1,1
    80002172:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80002174:	854a                	mv	a0,s2
    80002176:	00001097          	auipc	ra,0x1
    8000217a:	e7a080e7          	jalr	-390(ra) # 80002ff0 <release>

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
    800021a2:	e52080e7          	jalr	-430(ra) # 80002ff0 <release>

  if (first) {
    800021a6:	00007797          	auipc	a5,0x7
    800021aa:	9ae7a783          	lw	a5,-1618(a5) # 80008b54 <first.0>
    800021ae:	e795                	bnez	a5,800021da <forkret+0x4e>
    printf("proc %d: first user process init\n", myproc()->pid);
    first = 0;
    fsinit(ROOTDEV); //初始化文件系统
    printf("proc %d: first user process init done\n", myproc()->pid);
  }
  printf("proc %d: entering user space\n", myproc()->pid);
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	f5e080e7          	jalr	-162(ra) # 8000210e <myproc>
    800021b8:	410c                	lw	a1,0(a0)
    800021ba:	00006517          	auipc	a0,0x6
    800021be:	25e50513          	add	a0,a0,606 # 80008418 <digits+0x228>
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	068080e7          	jalr	104(ra) # 8000122a <printf>
  trap_user_return();
    800021ca:	00001097          	auipc	ra,0x1
    800021ce:	1c8080e7          	jalr	456(ra) # 80003392 <trap_user_return>
}
    800021d2:	60a2                	ld	ra,8(sp)
    800021d4:	6402                	ld	s0,0(sp)
    800021d6:	0141                	add	sp,sp,16
    800021d8:	8082                	ret
    printf("proc %d: first user process init\n", myproc()->pid);
    800021da:	00000097          	auipc	ra,0x0
    800021de:	f34080e7          	jalr	-204(ra) # 8000210e <myproc>
    800021e2:	410c                	lw	a1,0(a0)
    800021e4:	00006517          	auipc	a0,0x6
    800021e8:	1e450513          	add	a0,a0,484 # 800083c8 <digits+0x1d8>
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	03e080e7          	jalr	62(ra) # 8000122a <printf>
    first = 0;
    800021f4:	00007797          	auipc	a5,0x7
    800021f8:	9607a023          	sw	zero,-1696(a5) # 80008b54 <first.0>
    fsinit(ROOTDEV); //初始化文件系统
    800021fc:	4505                	li	a0,1
    800021fe:	00003097          	auipc	ra,0x3
    80002202:	3a8080e7          	jalr	936(ra) # 800055a6 <fsinit>
    printf("proc %d: first user process init done\n", myproc()->pid);
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	f08080e7          	jalr	-248(ra) # 8000210e <myproc>
    8000220e:	410c                	lw	a1,0(a0)
    80002210:	00006517          	auipc	a0,0x6
    80002214:	1e050513          	add	a0,a0,480 # 800083f0 <digits+0x200>
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	012080e7          	jalr	18(ra) # 8000122a <printf>
    80002220:	bf41                	j	800021b0 <forkret+0x24>

0000000080002222 <proc_mapstacks>:
{
    80002222:	7139                	add	sp,sp,-64
    80002224:	fc06                	sd	ra,56(sp)
    80002226:	f822                	sd	s0,48(sp)
    80002228:	f426                	sd	s1,40(sp)
    8000222a:	f04a                	sd	s2,32(sp)
    8000222c:	ec4e                	sd	s3,24(sp)
    8000222e:	e852                	sd	s4,16(sp)
    80002230:	e456                	sd	s5,8(sp)
    80002232:	e05a                	sd	s6,0(sp)
    80002234:	0080                	add	s0,sp,64
    80002236:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002238:	0000f497          	auipc	s1,0xf
    8000223c:	15048493          	add	s1,s1,336 # 80011388 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80002240:	8b26                	mv	s6,s1
    80002242:	00006a97          	auipc	s5,0x6
    80002246:	dbea8a93          	add	s5,s5,-578 # 80008000 <etext>
    8000224a:	04000937          	lui	s2,0x4000
    8000224e:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80002250:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002252:	00015a17          	auipc	s4,0x15
    80002256:	b36a0a13          	add	s4,s4,-1226 # 80016d88 <wait_lock>
    char *pa = kalloc(1);
    8000225a:	4505                	li	a0,1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	2e0080e7          	jalr	736(ra) # 8000153c <kalloc>
    80002264:	862a                	mv	a2,a0
    if(pa == 0)
    80002266:	c131                	beqz	a0,800022aa <proc_mapstacks+0x88>
    uint64 va = KSTACK((int) (p - proc));
    80002268:	416485b3          	sub	a1,s1,s6
    8000226c:	858d                	sra	a1,a1,0x3
    8000226e:	000ab783          	ld	a5,0(s5)
    80002272:	02f585b3          	mul	a1,a1,a5
    80002276:	2585                	addw	a1,a1,1
    80002278:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000227c:	4719                	li	a4,6
    8000227e:	6685                	lui	a3,0x1
    80002280:	40b905b3          	sub	a1,s2,a1
    80002284:	854e                	mv	a0,s3
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	4a8080e7          	jalr	1192(ra) # 8000172e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000228e:	16848493          	add	s1,s1,360
    80002292:	fd4494e3          	bne	s1,s4,8000225a <proc_mapstacks+0x38>
}
    80002296:	70e2                	ld	ra,56(sp)
    80002298:	7442                	ld	s0,48(sp)
    8000229a:	74a2                	ld	s1,40(sp)
    8000229c:	7902                	ld	s2,32(sp)
    8000229e:	69e2                	ld	s3,24(sp)
    800022a0:	6a42                	ld	s4,16(sp)
    800022a2:	6aa2                	ld	s5,8(sp)
    800022a4:	6b02                	ld	s6,0(sp)
    800022a6:	6121                	add	sp,sp,64
    800022a8:	8082                	ret
      panic("kalloc");
    800022aa:	00006517          	auipc	a0,0x6
    800022ae:	18e50513          	add	a0,a0,398 # 80008438 <digits+0x248>
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	f2e080e7          	jalr	-210(ra) # 800011e0 <panic>

00000000800022ba <procinit>:
{
    800022ba:	7139                	add	sp,sp,-64
    800022bc:	fc06                	sd	ra,56(sp)
    800022be:	f822                	sd	s0,48(sp)
    800022c0:	f426                	sd	s1,40(sp)
    800022c2:	f04a                	sd	s2,32(sp)
    800022c4:	ec4e                	sd	s3,24(sp)
    800022c6:	e852                	sd	s4,16(sp)
    800022c8:	e456                	sd	s5,8(sp)
    800022ca:	e05a                	sd	s6,0(sp)
    800022cc:	0080                	add	s0,sp,64
    initlock(&pid_lock, "nextpid");
    800022ce:	00006597          	auipc	a1,0x6
    800022d2:	17258593          	add	a1,a1,370 # 80008440 <digits+0x250>
    800022d6:	0000f517          	auipc	a0,0xf
    800022da:	09a50513          	add	a0,a0,154 # 80011370 <pid_lock>
    800022de:	00001097          	auipc	ra,0x1
    800022e2:	bce080e7          	jalr	-1074(ra) # 80002eac <initlock>
    initlock(&wait_lock, "wait_lock");
    800022e6:	00006597          	auipc	a1,0x6
    800022ea:	16258593          	add	a1,a1,354 # 80008448 <digits+0x258>
    800022ee:	00015517          	auipc	a0,0x15
    800022f2:	a9a50513          	add	a0,a0,-1382 # 80016d88 <wait_lock>
    800022f6:	00001097          	auipc	ra,0x1
    800022fa:	bb6080e7          	jalr	-1098(ra) # 80002eac <initlock>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022fe:	0000f497          	auipc	s1,0xf
    80002302:	08a48493          	add	s1,s1,138 # 80011388 <proc>
      initlock(&p->lock, "proc");
    80002306:	00006b17          	auipc	s6,0x6
    8000230a:	152b0b13          	add	s6,s6,338 # 80008458 <digits+0x268>
      p->kstack = KSTACK((int) (p - proc));
    8000230e:	8aa6                	mv	s5,s1
    80002310:	00006a17          	auipc	s4,0x6
    80002314:	cf0a0a13          	add	s4,s4,-784 # 80008000 <etext>
    80002318:	04000937          	lui	s2,0x4000
    8000231c:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000231e:	0932                	sll	s2,s2,0xc
    for(p = proc; p < &proc[NPROC]; p++) {
    80002320:	00015997          	auipc	s3,0x15
    80002324:	a6898993          	add	s3,s3,-1432 # 80016d88 <wait_lock>
      initlock(&p->lock, "proc");
    80002328:	85da                	mv	a1,s6
    8000232a:	00848513          	add	a0,s1,8
    8000232e:	00001097          	auipc	ra,0x1
    80002332:	b7e080e7          	jalr	-1154(ra) # 80002eac <initlock>
      p->state = UNUSED;
    80002336:	0204a023          	sw	zero,32(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000233a:	415487b3          	sub	a5,s1,s5
    8000233e:	878d                	sra	a5,a5,0x3
    80002340:	000a3703          	ld	a4,0(s4)
    80002344:	02e787b3          	mul	a5,a5,a4
    80002348:	2785                	addw	a5,a5,1
    8000234a:	00d7979b          	sllw	a5,a5,0xd
    8000234e:	40f907b3          	sub	a5,s2,a5
    80002352:	f8fc                	sd	a5,240(s1)
    for(p = proc; p < &proc[NPROC]; p++) {
    80002354:	16848493          	add	s1,s1,360
    80002358:	fd3498e3          	bne	s1,s3,80002328 <procinit+0x6e>
}
    8000235c:	70e2                	ld	ra,56(sp)
    8000235e:	7442                	ld	s0,48(sp)
    80002360:	74a2                	ld	s1,40(sp)
    80002362:	7902                	ld	s2,32(sp)
    80002364:	69e2                	ld	s3,24(sp)
    80002366:	6a42                	ld	s4,16(sp)
    80002368:	6aa2                	ld	s5,8(sp)
    8000236a:	6b02                	ld	s6,0(sp)
    8000236c:	6121                	add	sp,sp,64
    8000236e:	8082                	ret

0000000080002370 <proc_freepagetable>:

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    80002370:	1101                	add	sp,sp,-32
    80002372:	ec06                	sd	ra,24(sp)
    80002374:	e822                	sd	s0,16(sp)
    80002376:	e426                	sd	s1,8(sp)
    80002378:	e04a                	sd	s2,0(sp)
    8000237a:	1000                	add	s0,sp,32
    8000237c:	84aa                	mv	s1,a0
    8000237e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0); 
    80002380:	4681                	li	a3,0
    80002382:	4605                	li	a2,1
    80002384:	040005b7          	lui	a1,0x4000
    80002388:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000238a:	05b2                	sll	a1,a1,0xc
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	78a080e7          	jalr	1930(ra) # 80001b16 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002394:	4681                	li	a3,0
    80002396:	4605                	li	a2,1
    80002398:	020005b7          	lui	a1,0x2000
    8000239c:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    8000239e:	05b6                	sll	a1,a1,0xd
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	774080e7          	jalr	1908(ra) # 80001b16 <uvmunmap>
  uvmfree(pagetable, sz);
    800023aa:	85ca                	mv	a1,s2
    800023ac:	8526                	mv	a0,s1
    800023ae:	00000097          	auipc	ra,0x0
    800023b2:	b24080e7          	jalr	-1244(ra) # 80001ed2 <uvmfree>
}
    800023b6:	60e2                	ld	ra,24(sp)
    800023b8:	6442                	ld	s0,16(sp)
    800023ba:	64a2                	ld	s1,8(sp)
    800023bc:	6902                	ld	s2,0(sp)
    800023be:	6105                	add	sp,sp,32
    800023c0:	8082                	ret

00000000800023c2 <freeproc>:

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
void freeproc(struct proc *p)
{
    800023c2:	1101                	add	sp,sp,-32
    800023c4:	ec06                	sd	ra,24(sp)
    800023c6:	e822                	sd	s0,16(sp)
    800023c8:	e426                	sd	s1,8(sp)
    800023ca:	1000                	add	s0,sp,32
    800023cc:	84aa                	mv	s1,a0
  if(p->tf)
    800023ce:	6d28                	ld	a0,88(a0)
    800023d0:	c511                	beqz	a0,800023dc <freeproc+0x1a>
    kfree((uint64)p->tf,1);
    800023d2:	4585                	li	a1,1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	068080e7          	jalr	104(ra) # 8000143c <kfree>
  p->tf = 0;
    800023dc:	0404bc23          	sd	zero,88(s1)
  if(p->pgtbl)
    800023e0:	64a8                	ld	a0,72(s1)
    800023e2:	c511                	beqz	a0,800023ee <freeproc+0x2c>
    proc_freepagetable(p->pgtbl, p->sz);
    800023e4:	74ec                	ld	a1,232(s1)
    800023e6:	00000097          	auipc	ra,0x0
    800023ea:	f8a080e7          	jalr	-118(ra) # 80002370 <proc_freepagetable>

  p->pgtbl = 0;
    800023ee:	0404b423          	sd	zero,72(s1)
  p->parent = 0;
    800023f2:	0204b423          	sd	zero,40(s1)
  p->chan = 0;
    800023f6:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    800023fa:	0204ac23          	sw	zero,56(s1)
  p->exit_state = 0;
    800023fe:	0204ae23          	sw	zero,60(s1)
  p->sleep_space = 0;
    80002402:	0404b023          	sd	zero,64(s1)
  p->ustack_pages = 0;
    80002406:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    8000240a:	0e04b423          	sd	zero,232(s1)
  p->pid = 0;
    8000240e:	0004a023          	sw	zero,0(s1)
  
  memset(&p->ctx, 0, sizeof(p->ctx));
    80002412:	07000613          	li	a2,112
    80002416:	4581                	li	a1,0
    80002418:	0f848513          	add	a0,s1,248
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	b7c080e7          	jalr	-1156(ra) # 80000f98 <memset>

  p->state = UNUSED;
    80002424:	0204a023          	sw	zero,32(s1)
}
    80002428:	60e2                	ld	ra,24(sp)
    8000242a:	6442                	ld	s0,16(sp)
    8000242c:	64a2                	ld	s1,8(sp)
    8000242e:	6105                	add	sp,sp,32
    80002430:	8082                	ret

0000000080002432 <proc_pgtbl_init>:

// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
    80002432:	1101                	add	sp,sp,-32
    80002434:	ec06                	sd	ra,24(sp)
    80002436:	e822                	sd	s0,16(sp)
    80002438:	e426                	sd	s1,8(sp)
    8000243a:	e04a                	sd	s2,0(sp)
    8000243c:	1000                	add	s0,sp,32
    8000243e:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	632080e7          	jalr	1586(ra) # 80001a72 <uvmcreate>
    80002448:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000244a:	cd1d                	beqz	a0,80002488 <proc_pgtbl_init+0x56>
    return 0;

  
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    8000244c:	4729                	li	a4,10
    8000244e:	00005697          	auipc	a3,0x5
    80002452:	bb268693          	add	a3,a3,-1102 # 80007000 <_trampoline>
    80002456:	6605                	lui	a2,0x1
    80002458:	040005b7          	lui	a1,0x4000
    8000245c:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000245e:	05b2                	sll	a1,a1,0xc
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	20a080e7          	jalr	522(ra) # 8000166a <mappages>
    80002468:	02054763          	bltz	a0,80002496 <proc_pgtbl_init+0x64>
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000246c:	4719                	li	a4,6
    8000246e:	86ca                	mv	a3,s2
    80002470:	6605                	lui	a2,0x1
    80002472:	020005b7          	lui	a1,0x2000
    80002476:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80002478:	05b6                	sll	a1,a1,0xd
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	1ee080e7          	jalr	494(ra) # 8000166a <mappages>
    80002484:	02054163          	bltz	a0,800024a6 <proc_pgtbl_init+0x74>
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}
    80002488:	8526                	mv	a0,s1
    8000248a:	60e2                	ld	ra,24(sp)
    8000248c:	6442                	ld	s0,16(sp)
    8000248e:	64a2                	ld	s1,8(sp)
    80002490:	6902                	ld	s2,0(sp)
    80002492:	6105                	add	sp,sp,32
    80002494:	8082                	ret
    panic("proc_pgtbl_init: mappages trampoline failed");
    80002496:	00006517          	auipc	a0,0x6
    8000249a:	fca50513          	add	a0,a0,-54 # 80008460 <digits+0x270>
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	d42080e7          	jalr	-702(ra) # 800011e0 <panic>
    panic("proc_pgtbl_init: mappages trapframe failed");
    800024a6:	00006517          	auipc	a0,0x6
    800024aa:	fea50513          	add	a0,a0,-22 # 80008490 <digits+0x2a0>
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	d32080e7          	jalr	-718(ra) # 800011e0 <panic>

00000000800024b6 <allocproc>:
{
    800024b6:	7179                	add	sp,sp,-48
    800024b8:	f406                	sd	ra,40(sp)
    800024ba:	f022                	sd	s0,32(sp)
    800024bc:	ec26                	sd	s1,24(sp)
    800024be:	e84a                	sd	s2,16(sp)
    800024c0:	e44e                	sd	s3,8(sp)
    800024c2:	1800                	add	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c4:	0000f497          	auipc	s1,0xf
    800024c8:	ec448493          	add	s1,s1,-316 # 80011388 <proc>
    800024cc:	00015997          	auipc	s3,0x15
    800024d0:	8bc98993          	add	s3,s3,-1860 # 80016d88 <wait_lock>
    acquire(&p->lock);
    800024d4:	00848913          	add	s2,s1,8
    800024d8:	854a                	mv	a0,s2
    800024da:	00001097          	auipc	ra,0x1
    800024de:	a62080e7          	jalr	-1438(ra) # 80002f3c <acquire>
    if(p->state == UNUSED) {
    800024e2:	509c                	lw	a5,32(s1)
    800024e4:	cf81                	beqz	a5,800024fc <allocproc+0x46>
      release(&p->lock);
    800024e6:	854a                	mv	a0,s2
    800024e8:	00001097          	auipc	ra,0x1
    800024ec:	b08080e7          	jalr	-1272(ra) # 80002ff0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024f0:	16848493          	add	s1,s1,360
    800024f4:	ff3490e3          	bne	s1,s3,800024d4 <allocproc+0x1e>
  return 0;
    800024f8:	4481                	li	s1,0
    800024fa:	a8a1                	j	80002552 <allocproc+0x9c>
  p->pid = allocpid();
    800024fc:	00000097          	auipc	ra,0x0
    80002500:	c4a080e7          	jalr	-950(ra) # 80002146 <allocpid>
    80002504:	c088                	sw	a0,0(s1)
  p->state = USED;
    80002506:	4785                	li	a5,1
    80002508:	d09c                	sw	a5,32(s1)
  p->sz=4096;
    8000250a:	6785                	lui	a5,0x1
    8000250c:	f4fc                	sd	a5,232(s1)
  if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    8000250e:	4505                	li	a0,1
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	02c080e7          	jalr	44(ra) # 8000153c <kalloc>
    80002518:	89aa                	mv	s3,a0
    8000251a:	eca8                	sd	a0,88(s1)
    8000251c:	c139                	beqz	a0,80002562 <allocproc+0xac>
  p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	f14080e7          	jalr	-236(ra) # 80002432 <proc_pgtbl_init>
    80002526:	89aa                	mv	s3,a0
    80002528:	e4a8                	sd	a0,72(s1)
  if(p->pgtbl == 0){ 
    8000252a:	c125                	beqz	a0,8000258a <allocproc+0xd4>
  memset(&p->ctx, 0, sizeof(p->ctx));
    8000252c:	07000613          	li	a2,112
    80002530:	4581                	li	a1,0
    80002532:	0f848513          	add	a0,s1,248
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	a62080e7          	jalr	-1438(ra) # 80000f98 <memset>
  p->ctx.ra = (uint64)forkret;
    8000253e:	00000797          	auipc	a5,0x0
    80002542:	c4e78793          	add	a5,a5,-946 # 8000218c <forkret>
    80002546:	fcfc                	sd	a5,248(s1)
  p->ctx.sp = p->kstack+PGSIZE;
    80002548:	78fc                	ld	a5,240(s1)
    8000254a:	6705                	lui	a4,0x1
    8000254c:	97ba                	add	a5,a5,a4
    8000254e:	10f4b023          	sd	a5,256(s1)
}
    80002552:	8526                	mv	a0,s1
    80002554:	70a2                	ld	ra,40(sp)
    80002556:	7402                	ld	s0,32(sp)
    80002558:	64e2                	ld	s1,24(sp)
    8000255a:	6942                	ld	s2,16(sp)
    8000255c:	69a2                	ld	s3,8(sp)
    8000255e:	6145                	add	sp,sp,48
    80002560:	8082                	ret
    freeproc(p);
    80002562:	8526                	mv	a0,s1
    80002564:	00000097          	auipc	ra,0x0
    80002568:	e5e080e7          	jalr	-418(ra) # 800023c2 <freeproc>
    printf("allocproc: kalloc trapframe failed\n");
    8000256c:	00006517          	auipc	a0,0x6
    80002570:	f5450513          	add	a0,a0,-172 # 800084c0 <digits+0x2d0>
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	cb6080e7          	jalr	-842(ra) # 8000122a <printf>
    release(&p->lock);
    8000257c:	854a                	mv	a0,s2
    8000257e:	00001097          	auipc	ra,0x1
    80002582:	a72080e7          	jalr	-1422(ra) # 80002ff0 <release>
    return 0;
    80002586:	84ce                	mv	s1,s3
    80002588:	b7e9                	j	80002552 <allocproc+0x9c>
    freeproc(p);
    8000258a:	8526                	mv	a0,s1
    8000258c:	00000097          	auipc	ra,0x0
    80002590:	e36080e7          	jalr	-458(ra) # 800023c2 <freeproc>
    printf("allocproc: proc_pgtbl_init failed\n");
    80002594:	00006517          	auipc	a0,0x6
    80002598:	f5450513          	add	a0,a0,-172 # 800084e8 <digits+0x2f8>
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	c8e080e7          	jalr	-882(ra) # 8000122a <printf>
    release(&p->lock);
    800025a4:	854a                	mv	a0,s2
    800025a6:	00001097          	auipc	ra,0x1
    800025aa:	a4a080e7          	jalr	-1462(ra) # 80002ff0 <release>
    return 0;
    800025ae:	84ce                	mv	s1,s3
    800025b0:	b74d                	j	80002552 <allocproc+0x9c>

00000000800025b2 <userinit>:
//__attribute__ ((aligned (16))) char proc0stack[8192];

// Set up first user process.
void
userinit(void)
{
    800025b2:	1101                	add	sp,sp,-32
    800025b4:	ec06                	sd	ra,24(sp)
    800025b6:	e822                	sd	s0,16(sp)
    800025b8:	e426                	sd	s1,8(sp)
    800025ba:	1000                	add	s0,sp,32
  struct proc *p;

  p = allocproc();
    800025bc:	00000097          	auipc	ra,0x0
    800025c0:	efa080e7          	jalr	-262(ra) # 800024b6 <allocproc>
    800025c4:	84aa                	mv	s1,a0
  proczero = p;
    800025c6:	00006797          	auipc	a5,0x6
    800025ca:	5ca7b123          	sd	a0,1474(a5) # 80008b88 <proczero>
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pgtbl, (uchar*)initcode_start, (uint64)(initcode_end - initcode_start));
    800025ce:	00004597          	auipc	a1,0x4
    800025d2:	cc658593          	add	a1,a1,-826 # 80006294 <initcode_start>
    800025d6:	00004617          	auipc	a2,0x4
    800025da:	dc260613          	add	a2,a2,-574 # 80006398 <initcode_end>
    800025de:	9e0d                	subw	a2,a2,a1
    800025e0:	6528                	ld	a0,72(a0)
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	4c0080e7          	jalr	1216(ra) # 80001aa2 <uvmfirst>
  p->sz = PGSIZE;
    800025ea:	6785                	lui	a5,0x1
    800025ec:	f4fc                	sd	a5,232(s1)

  // prepare for the very first "return" from kernel to user.
  p->tf->epc = 0;      // user program counter
    800025ee:	6cb8                	ld	a4,88(s1)
    800025f0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    800025f4:	6cb8                	ld	a4,88(s1)
    800025f6:	fb1c                	sd	a5,48(a4)
  

  // safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
    800025f8:	00006517          	auipc	a0,0x6
    800025fc:	f1850513          	add	a0,a0,-232 # 80008510 <digits+0x320>
    80002600:	00004097          	auipc	ra,0x4
    80002604:	c5a080e7          	jalr	-934(ra) # 8000625a <namei>
    80002608:	f0e8                	sd	a0,224(s1)

  p->state = RUNNABLE;
    8000260a:	478d                	li	a5,3
    8000260c:	d09c                	sw	a5,32(s1)

  release(&p->lock);
    8000260e:	00848513          	add	a0,s1,8
    80002612:	00001097          	auipc	ra,0x1
    80002616:	9de080e7          	jalr	-1570(ra) # 80002ff0 <release>
}
    8000261a:	60e2                	ld	ra,24(sp)
    8000261c:	6442                	ld	s0,16(sp)
    8000261e:	64a2                	ld	s1,8(sp)
    80002620:	6105                	add	sp,sp,32
    80002622:	8082                	ret

0000000080002624 <growproc>:

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
    80002624:	1101                	add	sp,sp,-32
    80002626:	ec06                	sd	ra,24(sp)
    80002628:	e822                	sd	s0,16(sp)
    8000262a:	e426                	sd	s1,8(sp)
    8000262c:	e04a                	sd	s2,0(sp)
    8000262e:	1000                	add	s0,sp,32
    80002630:	892a                	mv	s2,a0
  uint64 sz;
  struct proc *p = myproc();
    80002632:	00000097          	auipc	ra,0x0
    80002636:	adc080e7          	jalr	-1316(ra) # 8000210e <myproc>
    8000263a:	84aa                	mv	s1,a0

  sz = p->sz;
    8000263c:	756c                	ld	a1,232(a0)
  if(n > 0){
    8000263e:	01204c63          	bgtz	s2,80002656 <growproc+0x32>
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    80002642:	02094663          	bltz	s2,8000266e <growproc+0x4a>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
  }
  p->sz = sz;
    80002646:	f4ec                	sd	a1,232(s1)
  return 0;
    80002648:	4501                	li	a0,0
}
    8000264a:	60e2                	ld	ra,24(sp)
    8000264c:	6442                	ld	s0,16(sp)
    8000264e:	64a2                	ld	s1,8(sp)
    80002650:	6902                	ld	s2,0(sp)
    80002652:	6105                	add	sp,sp,32
    80002654:	8082                	ret
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
    80002656:	4691                	li	a3,4
    80002658:	00b90633          	add	a2,s2,a1
    8000265c:	6528                	ld	a0,72(a0)
    8000265e:	fffff097          	auipc	ra,0xfffff
    80002662:	5c8080e7          	jalr	1480(ra) # 80001c26 <uvmalloc>
    80002666:	85aa                	mv	a1,a0
    80002668:	fd79                	bnez	a0,80002646 <growproc+0x22>
      return -1;
    8000266a:	557d                	li	a0,-1
    8000266c:	bff9                	j	8000264a <growproc+0x26>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
    8000266e:	00b90633          	add	a2,s2,a1
    80002672:	6528                	ld	a0,72(a0)
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	56a080e7          	jalr	1386(ra) # 80001bde <uvmdealloc>
    8000267c:	85aa                	mv	a1,a0
    8000267e:	b7e1                	j	80002646 <growproc+0x22>

0000000080002680 <uvmcopy>:
  pte_t *pte;
  uint64 pa, current_va;
  uint flags;
  char *mem;

  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    80002680:	ca69                	beqz	a2,80002752 <uvmcopy+0xd2>
{
    80002682:	715d                	add	sp,sp,-80
    80002684:	e486                	sd	ra,72(sp)
    80002686:	e0a2                	sd	s0,64(sp)
    80002688:	fc26                	sd	s1,56(sp)
    8000268a:	f84a                	sd	s2,48(sp)
    8000268c:	f44e                	sd	s3,40(sp)
    8000268e:	f052                	sd	s4,32(sp)
    80002690:	ec56                	sd	s5,24(sp)
    80002692:	e85a                	sd	s6,16(sp)
    80002694:	e45e                	sd	s7,8(sp)
    80002696:	0880                	add	s0,sp,80
    80002698:	8b2a                	mv	s6,a0
    8000269a:	8a2e                	mv	s4,a1
    8000269c:	8ab2                	mv	s5,a2
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    8000269e:	4981                	li	s3,0
  {
    pte = walk(old, current_va, 0);
    800026a0:	4601                	li	a2,0
    800026a2:	85ce                	mv	a1,s3
    800026a4:	855a                	mv	a0,s6
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	f1c080e7          	jalr	-228(ra) # 800015c2 <walk>
    if (pte == 0)
    800026ae:	c539                	beqz	a0,800026fc <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");

    if (!is_pte_valid(*pte))
    800026b0:	6118                	ld	a4,0(a0)
  return (pte & PTE_V) != 0;
    800026b2:	00177793          	and	a5,a4,1
    if (!is_pte_valid(*pte))
    800026b6:	cbb9                	beqz	a5,8000270c <uvmcopy+0x8c>
      panic("uvmcopy: page not present");

    pa = PTE2PA(*pte);
    800026b8:	00a75593          	srl	a1,a4,0xa
    800026bc:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800026c0:	3ff77913          	and	s2,a4,1023
  *dest_mem = kalloc(1);
    800026c4:	4505                	li	a0,1
    800026c6:	fffff097          	auipc	ra,0xfffff
    800026ca:	e76080e7          	jalr	-394(ra) # 8000153c <kalloc>
    800026ce:	84aa                	mv	s1,a0
  if (*dest_mem == 0)
    800026d0:	cd21                	beqz	a0,80002728 <uvmcopy+0xa8>
  memmove(*dest_mem, (char *)src_pa, PGSIZE);
    800026d2:	6605                	lui	a2,0x1
    800026d4:	85de                	mv	a1,s7
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	91e080e7          	jalr	-1762(ra) # 80000ff4 <memmove>

    if (copy_physical_page(pa, &mem) != 0)
      goto err;

    if (mappages(new, current_va, PGSIZE, (uint64)mem, flags) != 0)
    800026de:	874a                	mv	a4,s2
    800026e0:	86a6                	mv	a3,s1
    800026e2:	6605                	lui	a2,0x1
    800026e4:	85ce                	mv	a1,s3
    800026e6:	8552                	mv	a0,s4
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	f82080e7          	jalr	-126(ra) # 8000166a <mappages>
    800026f0:	e515                	bnez	a0,8000271c <uvmcopy+0x9c>
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    800026f2:	6785                	lui	a5,0x1
    800026f4:	99be                	add	s3,s3,a5
    800026f6:	fb59e5e3          	bltu	s3,s5,800026a0 <uvmcopy+0x20>
    800026fa:	a089                	j	8000273c <uvmcopy+0xbc>
      panic("uvmcopy: pte should exist");
    800026fc:	00006517          	auipc	a0,0x6
    80002700:	e1c50513          	add	a0,a0,-484 # 80008518 <digits+0x328>
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	adc080e7          	jalr	-1316(ra) # 800011e0 <panic>
      panic("uvmcopy: page not present");
    8000270c:	00006517          	auipc	a0,0x6
    80002710:	e2c50513          	add	a0,a0,-468 # 80008538 <digits+0x348>
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	acc080e7          	jalr	-1332(ra) # 800011e0 <panic>
    {
      kfree((uint64)mem,1);
    8000271c:	4585                	li	a1,1
    8000271e:	8526                	mv	a0,s1
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	d1c080e7          	jalr	-740(ra) # 8000143c <kfree>
  uvmunmap(new_table, 0, npages, 1);
    80002728:	4685                	li	a3,1
    8000272a:	00c9d613          	srl	a2,s3,0xc
    8000272e:	4581                	li	a1,0
    80002730:	8552                	mv	a0,s4
    80002732:	fffff097          	auipc	ra,0xfffff
    80002736:	3e4080e7          	jalr	996(ra) # 80001b16 <uvmunmap>
  }
  return 0;

err:
  cleanup_partial_copy(new, current_va);
  return -1;
    8000273a:	557d                	li	a0,-1
}
    8000273c:	60a6                	ld	ra,72(sp)
    8000273e:	6406                	ld	s0,64(sp)
    80002740:	74e2                	ld	s1,56(sp)
    80002742:	7942                	ld	s2,48(sp)
    80002744:	79a2                	ld	s3,40(sp)
    80002746:	7a02                	ld	s4,32(sp)
    80002748:	6ae2                	ld	s5,24(sp)
    8000274a:	6b42                	ld	s6,16(sp)
    8000274c:	6ba2                	ld	s7,8(sp)
    8000274e:	6161                	add	sp,sp,80
    80002750:	8082                	ret
  return 0;
    80002752:	4501                	li	a0,0
}
    80002754:	8082                	ret

0000000080002756 <fork>:

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
    80002756:	7139                	add	sp,sp,-64
    80002758:	fc06                	sd	ra,56(sp)
    8000275a:	f822                	sd	s0,48(sp)
    8000275c:	f426                	sd	s1,40(sp)
    8000275e:	f04a                	sd	s2,32(sp)
    80002760:	ec4e                	sd	s3,24(sp)
    80002762:	e852                	sd	s4,16(sp)
    80002764:	e456                	sd	s5,8(sp)
    80002766:	0080                	add	s0,sp,64
  int i; 
  int pid;
  struct proc *np;
  struct proc *p = myproc();
    80002768:	00000097          	auipc	ra,0x0
    8000276c:	9a6080e7          	jalr	-1626(ra) # 8000210e <myproc>
    80002770:	8aaa                	mv	s5,a0

  // Allocate process.
  if((np = allocproc()) == 0){
    80002772:	00000097          	auipc	ra,0x0
    80002776:	d44080e7          	jalr	-700(ra) # 800024b6 <allocproc>
    8000277a:	10050663          	beqz	a0,80002886 <fork+0x130>
    8000277e:	8a2a                	mv	s4,a0
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pgtbl, np->pgtbl, p->sz) < 0){
    80002780:	0e8ab603          	ld	a2,232(s5)
    80002784:	652c                	ld	a1,72(a0)
    80002786:	048ab503          	ld	a0,72(s5)
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	ef6080e7          	jalr	-266(ra) # 80002680 <uvmcopy>
    80002792:	04054863          	bltz	a0,800027e2 <fork+0x8c>
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
    80002796:	0e8ab783          	ld	a5,232(s5)
    8000279a:	0efa3423          	sd	a5,232(s4)

  // copy saved user registers.
  *(np->tf) = *(p->tf);
    8000279e:	058ab683          	ld	a3,88(s5)
    800027a2:	87b6                	mv	a5,a3
    800027a4:	058a3703          	ld	a4,88(s4)
    800027a8:	12068693          	add	a3,a3,288
    800027ac:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800027b0:	6788                	ld	a0,8(a5)
    800027b2:	6b8c                	ld	a1,16(a5)
    800027b4:	6f90                	ld	a2,24(a5)
    800027b6:	01073023          	sd	a6,0(a4)
    800027ba:	e708                	sd	a0,8(a4)
    800027bc:	eb0c                	sd	a1,16(a4)
    800027be:	ef10                	sd	a2,24(a4)
    800027c0:	02078793          	add	a5,a5,32
    800027c4:	02070713          	add	a4,a4,32
    800027c8:	fed792e3          	bne	a5,a3,800027ac <fork+0x56>

  // Cause fork to return 0 in the child.
  np->tf->a0 = 0;
    800027cc:	058a3783          	ld	a5,88(s4)
    800027d0:	0607b823          	sd	zero,112(a5)

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++) 
    800027d4:	060a8493          	add	s1,s5,96
    800027d8:	060a0913          	add	s2,s4,96
    800027dc:	0e0a8993          	add	s3,s5,224
    800027e0:	a015                	j	80002804 <fork+0xae>
    freeproc(np);
    800027e2:	8552                	mv	a0,s4
    800027e4:	00000097          	auipc	ra,0x0
    800027e8:	bde080e7          	jalr	-1058(ra) # 800023c2 <freeproc>
    release(&np->lock);
    800027ec:	008a0513          	add	a0,s4,8
    800027f0:	00001097          	auipc	ra,0x1
    800027f4:	800080e7          	jalr	-2048(ra) # 80002ff0 <release>
    return -1;
    800027f8:	59fd                	li	s3,-1
    800027fa:	a8a5                	j	80002872 <fork+0x11c>
  for(i = 0; i < NOFILE; i++) 
    800027fc:	04a1                	add	s1,s1,8
    800027fe:	0921                	add	s2,s2,8
    80002800:	01348b63          	beq	s1,s3,80002816 <fork+0xc0>
    if(p->ofile[i])
    80002804:	6088                	ld	a0,0(s1)
    80002806:	d97d                	beqz	a0,800027fc <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80002808:	00002097          	auipc	ra,0x2
    8000280c:	5a4080e7          	jalr	1444(ra) # 80004dac <filedup>
    80002810:	00a93023          	sd	a0,0(s2)
    80002814:	b7e5                	j	800027fc <fork+0xa6>
  np->cwd = idup(p->cwd);
    80002816:	0e0ab503          	ld	a0,224(s5)
    8000281a:	00003097          	auipc	ra,0x3
    8000281e:	25e080e7          	jalr	606(ra) # 80005a78 <idup>
    80002822:	0eaa3023          	sd	a0,224(s4)

  //safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;
    80002826:	000a2983          	lw	s3,0(s4)

  release(&np->lock);
    8000282a:	008a0493          	add	s1,s4,8
    8000282e:	8526                	mv	a0,s1
    80002830:	00000097          	auipc	ra,0x0
    80002834:	7c0080e7          	jalr	1984(ra) # 80002ff0 <release>

  acquire(&wait_lock);
    80002838:	00014917          	auipc	s2,0x14
    8000283c:	55090913          	add	s2,s2,1360 # 80016d88 <wait_lock>
    80002840:	854a                	mv	a0,s2
    80002842:	00000097          	auipc	ra,0x0
    80002846:	6fa080e7          	jalr	1786(ra) # 80002f3c <acquire>
  np->parent = p;
    8000284a:	035a3423          	sd	s5,40(s4)
  release(&wait_lock);
    8000284e:	854a                	mv	a0,s2
    80002850:	00000097          	auipc	ra,0x0
    80002854:	7a0080e7          	jalr	1952(ra) # 80002ff0 <release>

  acquire(&np->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	6e2080e7          	jalr	1762(ra) # 80002f3c <acquire>
  np->state = RUNNABLE;
    80002862:	478d                	li	a5,3
    80002864:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    80002868:	8526                	mv	a0,s1
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	786080e7          	jalr	1926(ra) # 80002ff0 <release>

  return pid;
}
    80002872:	854e                	mv	a0,s3
    80002874:	70e2                	ld	ra,56(sp)
    80002876:	7442                	ld	s0,48(sp)
    80002878:	74a2                	ld	s1,40(sp)
    8000287a:	7902                	ld	s2,32(sp)
    8000287c:	69e2                	ld	s3,24(sp)
    8000287e:	6a42                	ld	s4,16(sp)
    80002880:	6aa2                	ld	s5,8(sp)
    80002882:	6121                	add	sp,sp,64
    80002884:	8082                	ret
    return -1;
    80002886:	59fd                	li	s3,-1
    80002888:	b7ed                	j	80002872 <fork+0x11c>

000000008000288a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000288a:	7179                	add	sp,sp,-48
    8000288c:	f406                	sd	ra,40(sp)
    8000288e:	f022                	sd	s0,32(sp)
    80002890:	ec26                	sd	s1,24(sp)
    80002892:	e84a                	sd	s2,16(sp)
    80002894:	e44e                	sd	s3,8(sp)
    80002896:	e052                	sd	s4,0(sp)
    80002898:	1800                	add	s0,sp,48
    8000289a:	89aa                	mv	s3,a0
    8000289c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000289e:	00000097          	auipc	ra,0x0
    800028a2:	870080e7          	jalr	-1936(ra) # 8000210e <myproc>
    800028a6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800028a8:	00850a13          	add	s4,a0,8
    800028ac:	8552                	mv	a0,s4
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	68e080e7          	jalr	1678(ra) # 80002f3c <acquire>
  release(lk);
    800028b6:	854a                	mv	a0,s2
    800028b8:	00000097          	auipc	ra,0x0
    800028bc:	738080e7          	jalr	1848(ra) # 80002ff0 <release>

  // Go to sleep.
  p->chan = chan;
    800028c0:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    800028c4:	4789                	li	a5,2
    800028c6:	d09c                	sw	a5,32(s1)

  sched();
    800028c8:	00001097          	auipc	ra,0x1
    800028cc:	9c6080e7          	jalr	-1594(ra) # 8000328e <sched>

  // Tidy up.
  p->chan = 0;
    800028d0:	0204b823          	sd	zero,48(s1)

  // Reacquire original lock.
  release(&p->lock);
    800028d4:	8552                	mv	a0,s4
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	71a080e7          	jalr	1818(ra) # 80002ff0 <release>
  acquire(lk);
    800028de:	854a                	mv	a0,s2
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	65c080e7          	jalr	1628(ra) # 80002f3c <acquire>
}
    800028e8:	70a2                	ld	ra,40(sp)
    800028ea:	7402                	ld	s0,32(sp)
    800028ec:	64e2                	ld	s1,24(sp)
    800028ee:	6942                	ld	s2,16(sp)
    800028f0:	69a2                	ld	s3,8(sp)
    800028f2:	6a02                	ld	s4,0(sp)
    800028f4:	6145                	add	sp,sp,48
    800028f6:	8082                	ret

00000000800028f8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028f8:	7139                	add	sp,sp,-64
    800028fa:	fc06                	sd	ra,56(sp)
    800028fc:	f822                	sd	s0,48(sp)
    800028fe:	f426                	sd	s1,40(sp)
    80002900:	f04a                	sd	s2,32(sp)
    80002902:	ec4e                	sd	s3,24(sp)
    80002904:	e852                	sd	s4,16(sp)
    80002906:	e456                	sd	s5,8(sp)
    80002908:	e05a                	sd	s6,0(sp)
    8000290a:	0080                	add	s0,sp,64
    8000290c:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000290e:	0000f497          	auipc	s1,0xf
    80002912:	a7a48493          	add	s1,s1,-1414 # 80011388 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002916:	4a09                	li	s4,2
        p->state = RUNNABLE;
    80002918:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000291a:	00014997          	auipc	s3,0x14
    8000291e:	46e98993          	add	s3,s3,1134 # 80016d88 <wait_lock>
    80002922:	a811                	j	80002936 <wakeup+0x3e>
      }
      release(&p->lock);
    80002924:	854a                	mv	a0,s2
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	6ca080e7          	jalr	1738(ra) # 80002ff0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000292e:	16848493          	add	s1,s1,360
    80002932:	03348863          	beq	s1,s3,80002962 <wakeup+0x6a>
    if(p != myproc()){
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	7d8080e7          	jalr	2008(ra) # 8000210e <myproc>
    8000293e:	fea488e3          	beq	s1,a0,8000292e <wakeup+0x36>
      acquire(&p->lock);
    80002942:	00848913          	add	s2,s1,8
    80002946:	854a                	mv	a0,s2
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	5f4080e7          	jalr	1524(ra) # 80002f3c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002950:	509c                	lw	a5,32(s1)
    80002952:	fd4799e3          	bne	a5,s4,80002924 <wakeup+0x2c>
    80002956:	789c                	ld	a5,48(s1)
    80002958:	fd5796e3          	bne	a5,s5,80002924 <wakeup+0x2c>
        p->state = RUNNABLE;
    8000295c:	0364a023          	sw	s6,32(s1)
    80002960:	b7d1                	j	80002924 <wakeup+0x2c>
    }
  }
}
    80002962:	70e2                	ld	ra,56(sp)
    80002964:	7442                	ld	s0,48(sp)
    80002966:	74a2                	ld	s1,40(sp)
    80002968:	7902                	ld	s2,32(sp)
    8000296a:	69e2                	ld	s3,24(sp)
    8000296c:	6a42                	ld	s4,16(sp)
    8000296e:	6aa2                	ld	s5,8(sp)
    80002970:	6b02                	ld	s6,0(sp)
    80002972:	6121                	add	sp,sp,64
    80002974:	8082                	ret

0000000080002976 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002976:	7179                	add	sp,sp,-48
    80002978:	f406                	sd	ra,40(sp)
    8000297a:	f022                	sd	s0,32(sp)
    8000297c:	ec26                	sd	s1,24(sp)
    8000297e:	e84a                	sd	s2,16(sp)
    80002980:	e44e                	sd	s3,8(sp)
    80002982:	e052                	sd	s4,0(sp)
    80002984:	1800                	add	s0,sp,48
    80002986:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002988:	0000f497          	auipc	s1,0xf
    8000298c:	a0048493          	add	s1,s1,-1536 # 80011388 <proc>
    80002990:	00014a17          	auipc	s4,0x14
    80002994:	3f8a0a13          	add	s4,s4,1016 # 80016d88 <wait_lock>
    acquire(&p->lock);
    80002998:	00848913          	add	s2,s1,8
    8000299c:	854a                	mv	a0,s2
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	59e080e7          	jalr	1438(ra) # 80002f3c <acquire>
    if(p->pid == pid){
    800029a6:	409c                	lw	a5,0(s1)
    800029a8:	01378d63          	beq	a5,s3,800029c2 <kill+0x4c>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800029ac:	854a                	mv	a0,s2
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	642080e7          	jalr	1602(ra) # 80002ff0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800029b6:	16848493          	add	s1,s1,360
    800029ba:	fd449fe3          	bne	s1,s4,80002998 <kill+0x22>
  }
  return -1;
    800029be:	557d                	li	a0,-1
    800029c0:	a829                	j	800029da <kill+0x64>
      p->killed = 1;
    800029c2:	4785                	li	a5,1
    800029c4:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    800029c6:	5098                	lw	a4,32(s1)
    800029c8:	4789                	li	a5,2
    800029ca:	02f70063          	beq	a4,a5,800029ea <kill+0x74>
      release(&p->lock);
    800029ce:	854a                	mv	a0,s2
    800029d0:	00000097          	auipc	ra,0x0
    800029d4:	620080e7          	jalr	1568(ra) # 80002ff0 <release>
      return 0;
    800029d8:	4501                	li	a0,0
}
    800029da:	70a2                	ld	ra,40(sp)
    800029dc:	7402                	ld	s0,32(sp)
    800029de:	64e2                	ld	s1,24(sp)
    800029e0:	6942                	ld	s2,16(sp)
    800029e2:	69a2                	ld	s3,8(sp)
    800029e4:	6a02                	ld	s4,0(sp)
    800029e6:	6145                	add	sp,sp,48
    800029e8:	8082                	ret
        p->state = RUNNABLE;
    800029ea:	478d                	li	a5,3
    800029ec:	d09c                	sw	a5,32(s1)
    800029ee:	b7c5                	j	800029ce <kill+0x58>

00000000800029f0 <setkilled>:

void
setkilled(struct proc *p)
{
    800029f0:	1101                	add	sp,sp,-32
    800029f2:	ec06                	sd	ra,24(sp)
    800029f4:	e822                	sd	s0,16(sp)
    800029f6:	e426                	sd	s1,8(sp)
    800029f8:	e04a                	sd	s2,0(sp)
    800029fa:	1000                	add	s0,sp,32
    800029fc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800029fe:	00850913          	add	s2,a0,8
    80002a02:	854a                	mv	a0,s2
    80002a04:	00000097          	auipc	ra,0x0
    80002a08:	538080e7          	jalr	1336(ra) # 80002f3c <acquire>
  p->killed = 1;
    80002a0c:	4785                	li	a5,1
    80002a0e:	dc9c                	sw	a5,56(s1)
  release(&p->lock);
    80002a10:	854a                	mv	a0,s2
    80002a12:	00000097          	auipc	ra,0x0
    80002a16:	5de080e7          	jalr	1502(ra) # 80002ff0 <release>
}
    80002a1a:	60e2                	ld	ra,24(sp)
    80002a1c:	6442                	ld	s0,16(sp)
    80002a1e:	64a2                	ld	s1,8(sp)
    80002a20:	6902                	ld	s2,0(sp)
    80002a22:	6105                	add	sp,sp,32
    80002a24:	8082                	ret

0000000080002a26 <killed>:

int
killed(struct proc *p)
{
    80002a26:	1101                	add	sp,sp,-32
    80002a28:	ec06                	sd	ra,24(sp)
    80002a2a:	e822                	sd	s0,16(sp)
    80002a2c:	e426                	sd	s1,8(sp)
    80002a2e:	e04a                	sd	s2,0(sp)
    80002a30:	1000                	add	s0,sp,32
    80002a32:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002a34:	00850913          	add	s2,a0,8
    80002a38:	854a                	mv	a0,s2
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	502080e7          	jalr	1282(ra) # 80002f3c <acquire>
  k = p->killed;
    80002a42:	5c84                	lw	s1,56(s1)
  release(&p->lock);
    80002a44:	854a                	mv	a0,s2
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	5aa080e7          	jalr	1450(ra) # 80002ff0 <release>
  return k;
}
    80002a4e:	8526                	mv	a0,s1
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6902                	ld	s2,0(sp)
    80002a58:	6105                	add	sp,sp,32
    80002a5a:	8082                	ret

0000000080002a5c <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
    80002a5c:	711d                	add	sp,sp,-96
    80002a5e:	ec86                	sd	ra,88(sp)
    80002a60:	e8a2                	sd	s0,80(sp)
    80002a62:	e4a6                	sd	s1,72(sp)
    80002a64:	e0ca                	sd	s2,64(sp)
    80002a66:	fc4e                	sd	s3,56(sp)
    80002a68:	f852                	sd	s4,48(sp)
    80002a6a:	f456                	sd	s5,40(sp)
    80002a6c:	f05a                	sd	s6,32(sp)
    80002a6e:	ec5e                	sd	s7,24(sp)
    80002a70:	e862                	sd	s8,16(sp)
    80002a72:	e466                	sd	s9,8(sp)
    80002a74:	1080                	add	s0,sp,96
    80002a76:	8baa                	mv	s7,a0
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	696080e7          	jalr	1686(ra) # 8000210e <myproc>
    80002a80:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002a82:	00014517          	auipc	a0,0x14
    80002a86:	30650513          	add	a0,a0,774 # 80016d88 <wait_lock>
    80002a8a:	00000097          	auipc	ra,0x0
    80002a8e:	4b2080e7          	jalr	1202(ra) # 80002f3c <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002a92:	4c01                	li	s8,0
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
    80002a94:	4a95                	li	s5,5
        havekids = 1;
    80002a96:	4b05                	li	s6,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002a98:	00014997          	auipc	s3,0x14
    80002a9c:	2f098993          	add	s3,s3,752 # 80016d88 <wait_lock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002aa0:	00014c97          	auipc	s9,0x14
    80002aa4:	2e8c8c93          	add	s9,s9,744 # 80016d88 <wait_lock>
    80002aa8:	a8f1                	j	80002b84 <wait+0x128>
          printf("wait: found zombie pid=%d\n", pp->pid);
    80002aaa:	408c                	lw	a1,0(s1)
    80002aac:	00006517          	auipc	a0,0x6
    80002ab0:	aac50513          	add	a0,a0,-1364 # 80008558 <digits+0x368>
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	776080e7          	jalr	1910(ra) # 8000122a <printf>
          pid = pp->pid;
    80002abc:	0004a983          	lw	s3,0(s1)
          if(addr != 0 && uvm_copyout(p->pgtbl, addr, (uint64)&pp->exit_state,
    80002ac0:	000b8e63          	beqz	s7,80002adc <wait+0x80>
    80002ac4:	4691                	li	a3,4
    80002ac6:	03c48613          	add	a2,s1,60
    80002aca:	85de                	mv	a1,s7
    80002acc:	04893503          	ld	a0,72(s2)
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	2ac080e7          	jalr	684(ra) # 80001d7c <uvm_copyout>
    80002ad8:	04054263          	bltz	a0,80002b1c <wait+0xc0>
          freeproc(pp);
    80002adc:	8526                	mv	a0,s1
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	8e4080e7          	jalr	-1820(ra) # 800023c2 <freeproc>
          release(&pp->lock);
    80002ae6:	8552                	mv	a0,s4
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	508080e7          	jalr	1288(ra) # 80002ff0 <release>
          release(&wait_lock);
    80002af0:	00014517          	auipc	a0,0x14
    80002af4:	29850513          	add	a0,a0,664 # 80016d88 <wait_lock>
    80002af8:	00000097          	auipc	ra,0x0
    80002afc:	4f8080e7          	jalr	1272(ra) # 80002ff0 <release>
  }
}
    80002b00:	854e                	mv	a0,s3
    80002b02:	60e6                	ld	ra,88(sp)
    80002b04:	6446                	ld	s0,80(sp)
    80002b06:	64a6                	ld	s1,72(sp)
    80002b08:	6906                	ld	s2,64(sp)
    80002b0a:	79e2                	ld	s3,56(sp)
    80002b0c:	7a42                	ld	s4,48(sp)
    80002b0e:	7aa2                	ld	s5,40(sp)
    80002b10:	7b02                	ld	s6,32(sp)
    80002b12:	6be2                	ld	s7,24(sp)
    80002b14:	6c42                	ld	s8,16(sp)
    80002b16:	6ca2                	ld	s9,8(sp)
    80002b18:	6125                	add	sp,sp,96
    80002b1a:	8082                	ret
            release(&pp->lock);
    80002b1c:	8552                	mv	a0,s4
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	4d2080e7          	jalr	1234(ra) # 80002ff0 <release>
            release(&wait_lock);
    80002b26:	00014517          	auipc	a0,0x14
    80002b2a:	26250513          	add	a0,a0,610 # 80016d88 <wait_lock>
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	4c2080e7          	jalr	1218(ra) # 80002ff0 <release>
            return -1;
    80002b36:	59fd                	li	s3,-1
    80002b38:	b7e1                	j	80002b00 <wait+0xa4>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b3a:	16848493          	add	s1,s1,360
    80002b3e:	03348663          	beq	s1,s3,80002b6a <wait+0x10e>
      if(pp->parent == p){
    80002b42:	749c                	ld	a5,40(s1)
    80002b44:	ff279be3          	bne	a5,s2,80002b3a <wait+0xde>
        acquire(&pp->lock);
    80002b48:	00848a13          	add	s4,s1,8
    80002b4c:	8552                	mv	a0,s4
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	3ee080e7          	jalr	1006(ra) # 80002f3c <acquire>
        if(pp->state == ZOMBIE){
    80002b56:	509c                	lw	a5,32(s1)
    80002b58:	f55789e3          	beq	a5,s5,80002aaa <wait+0x4e>
        release(&pp->lock);
    80002b5c:	8552                	mv	a0,s4
    80002b5e:	00000097          	auipc	ra,0x0
    80002b62:	492080e7          	jalr	1170(ra) # 80002ff0 <release>
        havekids = 1;
    80002b66:	875a                	mv	a4,s6
    80002b68:	bfc9                	j	80002b3a <wait+0xde>
    if(!havekids || killed(p)){
    80002b6a:	c31d                	beqz	a4,80002b90 <wait+0x134>
    80002b6c:	854a                	mv	a0,s2
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	eb8080e7          	jalr	-328(ra) # 80002a26 <killed>
    80002b76:	ed09                	bnez	a0,80002b90 <wait+0x134>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b78:	85e6                	mv	a1,s9
    80002b7a:	854a                	mv	a0,s2
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	d0e080e7          	jalr	-754(ra) # 8000288a <sleep>
    havekids = 0;
    80002b84:	8762                	mv	a4,s8
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b86:	0000f497          	auipc	s1,0xf
    80002b8a:	80248493          	add	s1,s1,-2046 # 80011388 <proc>
    80002b8e:	bf55                	j	80002b42 <wait+0xe6>
      release(&wait_lock);
    80002b90:	00014517          	auipc	a0,0x14
    80002b94:	1f850513          	add	a0,a0,504 # 80016d88 <wait_lock>
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	458080e7          	jalr	1112(ra) # 80002ff0 <release>
      return -1;
    80002ba0:	59fd                	li	s3,-1
    80002ba2:	bfb9                	j	80002b00 <wait+0xa4>

0000000080002ba4 <reparent>:

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
    80002ba4:	7179                	add	sp,sp,-48
    80002ba6:	f406                	sd	ra,40(sp)
    80002ba8:	f022                	sd	s0,32(sp)
    80002baa:	ec26                	sd	s1,24(sp)
    80002bac:	e84a                	sd	s2,16(sp)
    80002bae:	e44e                	sd	s3,8(sp)
    80002bb0:	e052                	sd	s4,0(sp)
    80002bb2:	1800                	add	s0,sp,48
    80002bb4:	892a                	mv	s2,a0
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bb6:	0000e497          	auipc	s1,0xe
    80002bba:	7d248493          	add	s1,s1,2002 # 80011388 <proc>
    if(pp->parent == p){
      pp->parent = proczero;
    80002bbe:	00006a17          	auipc	s4,0x6
    80002bc2:	fcaa0a13          	add	s4,s4,-54 # 80008b88 <proczero>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bc6:	00014997          	auipc	s3,0x14
    80002bca:	1c298993          	add	s3,s3,450 # 80016d88 <wait_lock>
    80002bce:	a029                	j	80002bd8 <reparent+0x34>
    80002bd0:	16848493          	add	s1,s1,360
    80002bd4:	01348d63          	beq	s1,s3,80002bee <reparent+0x4a>
    if(pp->parent == p){
    80002bd8:	749c                	ld	a5,40(s1)
    80002bda:	ff279be3          	bne	a5,s2,80002bd0 <reparent+0x2c>
      pp->parent = proczero;
    80002bde:	000a3503          	ld	a0,0(s4)
    80002be2:	f488                	sd	a0,40(s1)
      wakeup(proczero);
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	d14080e7          	jalr	-748(ra) # 800028f8 <wakeup>
    80002bec:	b7d5                	j	80002bd0 <reparent+0x2c>
    }
  }
}
    80002bee:	70a2                	ld	ra,40(sp)
    80002bf0:	7402                	ld	s0,32(sp)
    80002bf2:	64e2                	ld	s1,24(sp)
    80002bf4:	6942                	ld	s2,16(sp)
    80002bf6:	69a2                	ld	s3,8(sp)
    80002bf8:	6a02                	ld	s4,0(sp)
    80002bfa:	6145                	add	sp,sp,48
    80002bfc:	8082                	ret

0000000080002bfe <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
    80002bfe:	7179                	add	sp,sp,-48
    80002c00:	f406                	sd	ra,40(sp)
    80002c02:	f022                	sd	s0,32(sp)
    80002c04:	ec26                	sd	s1,24(sp)
    80002c06:	e84a                	sd	s2,16(sp)
    80002c08:	e44e                	sd	s3,8(sp)
    80002c0a:	e052                	sd	s4,0(sp)
    80002c0c:	1800                	add	s0,sp,48
    80002c0e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	4fe080e7          	jalr	1278(ra) # 8000210e <myproc>
    80002c18:	89aa                	mv	s3,a0

  if(p == proczero)
    80002c1a:	00006797          	auipc	a5,0x6
    80002c1e:	f6e7b783          	ld	a5,-146(a5) # 80008b88 <proczero>
    80002c22:	06050493          	add	s1,a0,96
    80002c26:	0e050913          	add	s2,a0,224
    80002c2a:	02a79363          	bne	a5,a0,80002c50 <exit+0x52>
    panic("init exiting");
    80002c2e:	00006517          	auipc	a0,0x6
    80002c32:	94a50513          	add	a0,a0,-1718 # 80008578 <digits+0x388>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	5aa080e7          	jalr	1450(ra) # 800011e0 <panic>

  // Close all open files. 
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
    80002c3e:	00002097          	auipc	ra,0x2
    80002c42:	1c0080e7          	jalr	448(ra) # 80004dfe <fileclose>
      p->ofile[fd] = 0;
    80002c46:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002c4a:	04a1                	add	s1,s1,8
    80002c4c:	01248563          	beq	s1,s2,80002c56 <exit+0x58>
    if(p->ofile[fd]){
    80002c50:	6088                	ld	a0,0(s1)
    80002c52:	f575                	bnez	a0,80002c3e <exit+0x40>
    80002c54:	bfdd                	j	80002c4a <exit+0x4c>
    }
  }

  begin_op();
    80002c56:	00002097          	auipc	ra,0x2
    80002c5a:	e0e080e7          	jalr	-498(ra) # 80004a64 <begin_op>
  iput(p->cwd);
    80002c5e:	0e09b503          	ld	a0,224(s3)
    80002c62:	00003097          	auipc	ra,0x3
    80002c66:	00e080e7          	jalr	14(ra) # 80005c70 <iput>
  end_op();
    80002c6a:	00002097          	auipc	ra,0x2
    80002c6e:	e74080e7          	jalr	-396(ra) # 80004ade <end_op>
  p->cwd = 0;
    80002c72:	0e09b023          	sd	zero,224(s3)

  acquire(&wait_lock);
    80002c76:	00014497          	auipc	s1,0x14
    80002c7a:	11248493          	add	s1,s1,274 # 80016d88 <wait_lock>
    80002c7e:	8526                	mv	a0,s1
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	2bc080e7          	jalr	700(ra) # 80002f3c <acquire>

  // Give any children to init.
  reparent(p);
    80002c88:	854e                	mv	a0,s3
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	f1a080e7          	jalr	-230(ra) # 80002ba4 <reparent>

  // Parent might be sleeping in wait().
  wakeup(p->parent);
    80002c92:	0289b503          	ld	a0,40(s3)
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	c62080e7          	jalr	-926(ra) # 800028f8 <wakeup>
  
  acquire(&p->lock);
    80002c9e:	00898513          	add	a0,s3,8
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	29a080e7          	jalr	666(ra) # 80002f3c <acquire>

  p->exit_state = status;
    80002caa:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    80002cae:	4795                	li	a5,5
    80002cb0:	02f9a023          	sw	a5,32(s3)

  release(&wait_lock);
    80002cb4:	8526                	mv	a0,s1
    80002cb6:	00000097          	auipc	ra,0x0
    80002cba:	33a080e7          	jalr	826(ra) # 80002ff0 <release>

  // Jump into the scheduler, never to return.
  sched();
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	5d0080e7          	jalr	1488(ra) # 8000328e <sched>
  panic("zombie exit");
    80002cc6:	00006517          	auipc	a0,0x6
    80002cca:	8c250513          	add	a0,a0,-1854 # 80008588 <digits+0x398>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	512080e7          	jalr	1298(ra) # 800011e0 <panic>

0000000080002cd6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002cd6:	7179                	add	sp,sp,-48
    80002cd8:	f406                	sd	ra,40(sp)
    80002cda:	f022                	sd	s0,32(sp)
    80002cdc:	ec26                	sd	s1,24(sp)
    80002cde:	e84a                	sd	s2,16(sp)
    80002ce0:	e44e                	sd	s3,8(sp)
    80002ce2:	e052                	sd	s4,0(sp)
    80002ce4:	1800                	add	s0,sp,48
    80002ce6:	84aa                	mv	s1,a0
    80002ce8:	892e                	mv	s2,a1
    80002cea:	89b2                	mv	s3,a2
    80002cec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	420080e7          	jalr	1056(ra) # 8000210e <myproc>
  if(user_dst){
    80002cf6:	c08d                	beqz	s1,80002d18 <either_copyout+0x42>
    return copyout(p->pgtbl, dst, src, len);
    80002cf8:	86d2                	mv	a3,s4
    80002cfa:	864e                	mv	a2,s3
    80002cfc:	85ca                	mv	a1,s2
    80002cfe:	6528                	ld	a0,72(a0)
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	20c080e7          	jalr	524(ra) # 80001f0c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002d08:	70a2                	ld	ra,40(sp)
    80002d0a:	7402                	ld	s0,32(sp)
    80002d0c:	64e2                	ld	s1,24(sp)
    80002d0e:	6942                	ld	s2,16(sp)
    80002d10:	69a2                	ld	s3,8(sp)
    80002d12:	6a02                	ld	s4,0(sp)
    80002d14:	6145                	add	sp,sp,48
    80002d16:	8082                	ret
    memmove((char *)dst, src, len);
    80002d18:	000a061b          	sext.w	a2,s4
    80002d1c:	85ce                	mv	a1,s3
    80002d1e:	854a                	mv	a0,s2
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	2d4080e7          	jalr	724(ra) # 80000ff4 <memmove>
    return 0;
    80002d28:	8526                	mv	a0,s1
    80002d2a:	bff9                	j	80002d08 <either_copyout+0x32>

0000000080002d2c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002d2c:	7179                	add	sp,sp,-48
    80002d2e:	f406                	sd	ra,40(sp)
    80002d30:	f022                	sd	s0,32(sp)
    80002d32:	ec26                	sd	s1,24(sp)
    80002d34:	e84a                	sd	s2,16(sp)
    80002d36:	e44e                	sd	s3,8(sp)
    80002d38:	e052                	sd	s4,0(sp)
    80002d3a:	1800                	add	s0,sp,48
    80002d3c:	892a                	mv	s2,a0
    80002d3e:	84ae                	mv	s1,a1
    80002d40:	89b2                	mv	s3,a2
    80002d42:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	3ca080e7          	jalr	970(ra) # 8000210e <myproc>
  if(user_src){
    80002d4c:	c08d                	beqz	s1,80002d6e <either_copyin+0x42>
    return copyin(p->pgtbl, dst, src, len);
    80002d4e:	86d2                	mv	a3,s4
    80002d50:	864e                	mv	a2,s3
    80002d52:	85ca                	mv	a1,s2
    80002d54:	6528                	ld	a0,72(a0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	248080e7          	jalr	584(ra) # 80001f9e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002d5e:	70a2                	ld	ra,40(sp)
    80002d60:	7402                	ld	s0,32(sp)
    80002d62:	64e2                	ld	s1,24(sp)
    80002d64:	6942                	ld	s2,16(sp)
    80002d66:	69a2                	ld	s3,8(sp)
    80002d68:	6a02                	ld	s4,0(sp)
    80002d6a:	6145                	add	sp,sp,48
    80002d6c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002d6e:	000a061b          	sext.w	a2,s4
    80002d72:	85ce                	mv	a1,s3
    80002d74:	854a                	mv	a0,s2
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	27e080e7          	jalr	638(ra) # 80000ff4 <memmove>
    return 0;
    80002d7e:	8526                	mv	a0,s1
    80002d80:	bff9                	j	80002d5e <either_copyin+0x32>

0000000080002d82 <initsleeplock>:
#include "proc-h/proc.h"
#include "proc-h/cpu.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80002d82:	1101                	add	sp,sp,-32
    80002d84:	ec06                	sd	ra,24(sp)
    80002d86:	e822                	sd	s0,16(sp)
    80002d88:	e426                	sd	s1,8(sp)
    80002d8a:	e04a                	sd	s2,0(sp)
    80002d8c:	1000                	add	s0,sp,32
    80002d8e:	84aa                	mv	s1,a0
    80002d90:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80002d92:	00006597          	auipc	a1,0x6
    80002d96:	80658593          	add	a1,a1,-2042 # 80008598 <digits+0x3a8>
    80002d9a:	0521                	add	a0,a0,8
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	110080e7          	jalr	272(ra) # 80002eac <initlock>
  lk->name = name;
    80002da4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80002da8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80002dac:	0204a423          	sw	zero,40(s1)
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6902                	ld	s2,0(sp)
    80002db8:	6105                	add	sp,sp,32
    80002dba:	8082                	ret

0000000080002dbc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80002dbc:	1101                	add	sp,sp,-32
    80002dbe:	ec06                	sd	ra,24(sp)
    80002dc0:	e822                	sd	s0,16(sp)
    80002dc2:	e426                	sd	s1,8(sp)
    80002dc4:	e04a                	sd	s2,0(sp)
    80002dc6:	1000                	add	s0,sp,32
    80002dc8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80002dca:	00850913          	add	s2,a0,8
    80002dce:	854a                	mv	a0,s2
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	16c080e7          	jalr	364(ra) # 80002f3c <acquire>

  // printf("acquiresleep: trying to acquire lock %p\n", lk);


  while (lk->locked) {
    80002dd8:	409c                	lw	a5,0(s1)
    80002dda:	cb89                	beqz	a5,80002dec <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80002ddc:	85ca                	mv	a1,s2
    80002dde:	8526                	mv	a0,s1
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	aaa080e7          	jalr	-1366(ra) # 8000288a <sleep>
  while (lk->locked) {
    80002de8:	409c                	lw	a5,0(s1)
    80002dea:	fbed                	bnez	a5,80002ddc <acquiresleep+0x20>
  }
  lk->locked = 1;
    80002dec:	4785                	li	a5,1
    80002dee:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	31e080e7          	jalr	798(ra) # 8000210e <myproc>
    80002df8:	411c                	lw	a5,0(a0)
    80002dfa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80002dfc:	854a                	mv	a0,s2
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	1f2080e7          	jalr	498(ra) # 80002ff0 <release>
}
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	64a2                	ld	s1,8(sp)
    80002e0c:	6902                	ld	s2,0(sp)
    80002e0e:	6105                	add	sp,sp,32
    80002e10:	8082                	ret

0000000080002e12 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80002e12:	1101                	add	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	e04a                	sd	s2,0(sp)
    80002e1c:	1000                	add	s0,sp,32
    80002e1e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80002e20:	00850913          	add	s2,a0,8
    80002e24:	854a                	mv	a0,s2
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	116080e7          	jalr	278(ra) # 80002f3c <acquire>
  lk->locked = 0;
    80002e2e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80002e32:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80002e36:	8526                	mv	a0,s1
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	ac0080e7          	jalr	-1344(ra) # 800028f8 <wakeup>
  release(&lk->lk);
    80002e40:	854a                	mv	a0,s2
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	1ae080e7          	jalr	430(ra) # 80002ff0 <release>
}
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	64a2                	ld	s1,8(sp)
    80002e50:	6902                	ld	s2,0(sp)
    80002e52:	6105                	add	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80002e56:	7179                	add	sp,sp,-48
    80002e58:	f406                	sd	ra,40(sp)
    80002e5a:	f022                	sd	s0,32(sp)
    80002e5c:	ec26                	sd	s1,24(sp)
    80002e5e:	e84a                	sd	s2,16(sp)
    80002e60:	e44e                	sd	s3,8(sp)
    80002e62:	1800                	add	s0,sp,48
    80002e64:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80002e66:	00850913          	add	s2,a0,8
    80002e6a:	854a                	mv	a0,s2
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	0d0080e7          	jalr	208(ra) # 80002f3c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80002e74:	409c                	lw	a5,0(s1)
    80002e76:	ef99                	bnez	a5,80002e94 <holdingsleep+0x3e>
    80002e78:	4481                	li	s1,0
  release(&lk->lk);
    80002e7a:	854a                	mv	a0,s2
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	174080e7          	jalr	372(ra) # 80002ff0 <release>
  return r;
}
    80002e84:	8526                	mv	a0,s1
    80002e86:	70a2                	ld	ra,40(sp)
    80002e88:	7402                	ld	s0,32(sp)
    80002e8a:	64e2                	ld	s1,24(sp)
    80002e8c:	6942                	ld	s2,16(sp)
    80002e8e:	69a2                	ld	s3,8(sp)
    80002e90:	6145                	add	sp,sp,48
    80002e92:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80002e94:	0284a983          	lw	s3,40(s1)
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	276080e7          	jalr	630(ra) # 8000210e <myproc>
    80002ea0:	4104                	lw	s1,0(a0)
    80002ea2:	413484b3          	sub	s1,s1,s3
    80002ea6:	0014b493          	seqz	s1,s1
    80002eaa:	bfc1                	j	80002e7a <holdingsleep+0x24>

0000000080002eac <initlock>:
#include "proc-h/cpu.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80002eac:	1141                	add	sp,sp,-16
    80002eae:	e422                	sd	s0,8(sp)
    80002eb0:	0800                	add	s0,sp,16
  lk->name = name;
    80002eb2:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80002eb4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80002eb8:	00053823          	sd	zero,16(a0)
}
    80002ebc:	6422                	ld	s0,8(sp)
    80002ebe:	0141                	add	sp,sp,16
    80002ec0:	8082                	ret

0000000080002ec2 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80002ec2:	411c                	lw	a5,0(a0)
    80002ec4:	e399                	bnez	a5,80002eca <holding+0x8>
    80002ec6:	4501                	li	a0,0
  return r;
}
    80002ec8:	8082                	ret
{
    80002eca:	1101                	add	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	e426                	sd	s1,8(sp)
    80002ed2:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80002ed4:	6904                	ld	s1,16(a0)
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	21c080e7          	jalr	540(ra) # 800020f2 <mycpu>
    80002ede:	40a48533          	sub	a0,s1,a0
    80002ee2:	00153513          	seqz	a0,a0
}
    80002ee6:	60e2                	ld	ra,24(sp)
    80002ee8:	6442                	ld	s0,16(sp)
    80002eea:	64a2                	ld	s1,8(sp)
    80002eec:	6105                	add	sp,sp,32
    80002eee:	8082                	ret

0000000080002ef0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80002ef0:	1101                	add	sp,sp,-32
    80002ef2:	ec06                	sd	ra,24(sp)
    80002ef4:	e822                	sd	s0,16(sp)
    80002ef6:	e426                	sd	s1,8(sp)
    80002ef8:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002efa:	100024f3          	csrr	s1,sstatus
    80002efe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f02:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f04:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	1ea080e7          	jalr	490(ra) # 800020f2 <mycpu>
    80002f10:	411c                	lw	a5,0(a0)
    80002f12:	cf89                	beqz	a5,80002f2c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	1de080e7          	jalr	478(ra) # 800020f2 <mycpu>
    80002f1c:	411c                	lw	a5,0(a0)
    80002f1e:	2785                	addw	a5,a5,1
    80002f20:	c11c                	sw	a5,0(a0)
}
    80002f22:	60e2                	ld	ra,24(sp)
    80002f24:	6442                	ld	s0,16(sp)
    80002f26:	64a2                	ld	s1,8(sp)
    80002f28:	6105                	add	sp,sp,32
    80002f2a:	8082                	ret
    mycpu()->intena = old;
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	1c6080e7          	jalr	454(ra) # 800020f2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80002f34:	8085                	srl	s1,s1,0x1
    80002f36:	8885                	and	s1,s1,1
    80002f38:	c144                	sw	s1,4(a0)
    80002f3a:	bfe9                	j	80002f14 <push_off+0x24>

0000000080002f3c <acquire>:
{
    80002f3c:	1101                	add	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	1000                	add	s0,sp,32
    80002f46:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	fa8080e7          	jalr	-88(ra) # 80002ef0 <push_off>
  if(holding(lk))
    80002f50:	8526                	mv	a0,s1
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	f70080e7          	jalr	-144(ra) # 80002ec2 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80002f5a:	4705                	li	a4,1
  if(holding(lk))
    80002f5c:	e115                	bnez	a0,80002f80 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80002f5e:	87ba                	mv	a5,a4
    80002f60:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80002f64:	2781                	sext.w	a5,a5
    80002f66:	ffe5                	bnez	a5,80002f5e <acquire+0x22>
  __sync_synchronize();
    80002f68:	0ff0000f          	fence
  lk->cpu = mycpu();
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	186080e7          	jalr	390(ra) # 800020f2 <mycpu>
    80002f74:	e888                	sd	a0,16(s1)
}
    80002f76:	60e2                	ld	ra,24(sp)
    80002f78:	6442                	ld	s0,16(sp)
    80002f7a:	64a2                	ld	s1,8(sp)
    80002f7c:	6105                	add	sp,sp,32
    80002f7e:	8082                	ret
    panic("acquire");
    80002f80:	00005517          	auipc	a0,0x5
    80002f84:	62850513          	add	a0,a0,1576 # 800085a8 <digits+0x3b8>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	258080e7          	jalr	600(ra) # 800011e0 <panic>

0000000080002f90 <pop_off>:

void
pop_off(void)
{
    80002f90:	1141                	add	sp,sp,-16
    80002f92:	e406                	sd	ra,8(sp)
    80002f94:	e022                	sd	s0,0(sp)
    80002f96:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	15a080e7          	jalr	346(ra) # 800020f2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fa0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fa4:	8b89                	and	a5,a5,2
  if(intr_get())
    80002fa6:	e78d                	bnez	a5,80002fd0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80002fa8:	411c                	lw	a5,0(a0)
    80002faa:	02f05b63          	blez	a5,80002fe0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80002fae:	37fd                	addw	a5,a5,-1
    80002fb0:	0007871b          	sext.w	a4,a5
    80002fb4:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    80002fb6:	eb09                	bnez	a4,80002fc8 <pop_off+0x38>
    80002fb8:	415c                	lw	a5,4(a0)
    80002fba:	c799                	beqz	a5,80002fc8 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fc0:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fc4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80002fc8:	60a2                	ld	ra,8(sp)
    80002fca:	6402                	ld	s0,0(sp)
    80002fcc:	0141                	add	sp,sp,16
    80002fce:	8082                	ret
    panic("pop_off - interruptible");
    80002fd0:	00005517          	auipc	a0,0x5
    80002fd4:	5e050513          	add	a0,a0,1504 # 800085b0 <digits+0x3c0>
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	208080e7          	jalr	520(ra) # 800011e0 <panic>
    panic("pop_off");
    80002fe0:	00005517          	auipc	a0,0x5
    80002fe4:	5e850513          	add	a0,a0,1512 # 800085c8 <digits+0x3d8>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	1f8080e7          	jalr	504(ra) # 800011e0 <panic>

0000000080002ff0 <release>:
{
    80002ff0:	1101                	add	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	e426                	sd	s1,8(sp)
    80002ff8:	e04a                	sd	s2,0(sp)
    80002ffa:	1000                	add	s0,sp,32
    80002ffc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	ec4080e7          	jalr	-316(ra) # 80002ec2 <holding>
    80003006:	c11d                	beqz	a0,8000302c <release+0x3c>
  lk->cpu = 0;
    80003008:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    8000300c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80003010:	0f50000f          	fence	iorw,ow
    80003014:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80003018:	00000097          	auipc	ra,0x0
    8000301c:	f78080e7          	jalr	-136(ra) # 80002f90 <pop_off>
}
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	64a2                	ld	s1,8(sp)
    80003026:	6902                	ld	s2,0(sp)
    80003028:	6105                	add	sp,sp,32
    8000302a:	8082                	ret
    printf("release lock %s at %p, cpu%d\n", lk->name, lk, cpuid());
    8000302c:	0084b903          	ld	s2,8(s1)
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	0b2080e7          	jalr	178(ra) # 800020e2 <cpuid>
    80003038:	86aa                	mv	a3,a0
    8000303a:	8626                	mv	a2,s1
    8000303c:	85ca                	mv	a1,s2
    8000303e:	00005517          	auipc	a0,0x5
    80003042:	59250513          	add	a0,a0,1426 # 800085d0 <digits+0x3e0>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	1e4080e7          	jalr	484(ra) # 8000122a <printf>
    panic("release");
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	5a250513          	add	a0,a0,1442 # 800085f0 <digits+0x400>
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	18a080e7          	jalr	394(ra) # 800011e0 <panic>

000000008000305e <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    8000305e:	1141                	add	sp,sp,-16
    80003060:	e422                	sd	s0,8(sp)
    80003062:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003064:	00003797          	auipc	a5,0x3
    80003068:	3ac78793          	add	a5,a5,940 # 80006410 <kernelvec>
    8000306c:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    80003070:	6422                	ld	s0,8(sp)
    80003072:	0141                	add	sp,sp,16
    80003074:	8082                	ret

0000000080003076 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003076:	142027f3          	csrr	a5,scause
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    8000307a:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    8000307c:	0807df63          	bgez	a5,8000311a <devintr+0xa4>
{
    80003080:	1101                	add	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    8000308a:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    8000308e:	46a5                	li	a3,9
    80003090:	00d70d63          	beq	a4,a3,800030aa <devintr+0x34>
  if(scause == 0x8000000000000001L){
    80003094:	577d                	li	a4,-1
    80003096:	177e                	sll	a4,a4,0x3f
    80003098:	0705                	add	a4,a4,1
    return 0;  // 未识别的中断类型
    8000309a:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    8000309c:	04e78e63          	beq	a5,a4,800030f8 <devintr+0x82>
  }
}
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	64a2                	ld	s1,8(sp)
    800030a6:	6105                	add	sp,sp,32
    800030a8:	8082                	ret
    int irq = plic_claim();  // 获取中断请求号
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	956080e7          	jalr	-1706(ra) # 80000a00 <plic_claim>
    800030b2:	84aa                	mv	s1,a0
    switch(irq){
    800030b4:	4785                	li	a5,1
    800030b6:	02f50063          	beq	a0,a5,800030d6 <devintr+0x60>
    800030ba:	47a9                	li	a5,10
    800030bc:	02f51263          	bne	a0,a5,800030e0 <devintr+0x6a>
      uartintr();           // 处理串口中断
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	436080e7          	jalr	1078(ra) # 800004f6 <uartintr>
      plic_complete(irq);
    800030c8:	8526                	mv	a0,s1
    800030ca:	ffffe097          	auipc	ra,0xffffe
    800030ce:	95a080e7          	jalr	-1702(ra) # 80000a24 <plic_complete>
    return 1;
    800030d2:	4505                	li	a0,1
    800030d4:	b7f1                	j	800030a0 <devintr+0x2a>
      virtio_disk_intr();   // 处理虚拟磁盘中断
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	e0e080e7          	jalr	-498(ra) # 80000ee4 <virtio_disk_intr>
    if(irq)
    800030de:	b7ed                	j	800030c8 <devintr+0x52>
    return 1;
    800030e0:	4505                	li	a0,1
      if(irq){
    800030e2:	dcdd                	beqz	s1,800030a0 <devintr+0x2a>
        printf("unexpected interrupt irq=%d\n", irq);
    800030e4:	85a6                	mv	a1,s1
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	51250513          	add	a0,a0,1298 # 800085f8 <digits+0x408>
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	13c080e7          	jalr	316(ra) # 8000122a <printf>
    if(irq)
    800030f6:	bfc9                	j	800030c8 <devintr+0x52>
    if(cpuid() == 0){
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	fea080e7          	jalr	-22(ra) # 800020e2 <cpuid>
    80003100:	c901                	beqz	a0,80003110 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003102:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003106:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003108:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    8000310c:	4509                	li	a0,2
    8000310e:	bf49                	j	800030a0 <devintr+0x2a>
      timer_update();
    80003110:	ffffd097          	auipc	ra,0xffffd
    80003114:	166080e7          	jalr	358(ra) # 80000276 <timer_update>
    80003118:	b7ed                	j	80003102 <devintr+0x8c>
}
    8000311a:	8082                	ret

000000008000311c <kerneltrap>:
{
    8000311c:	7179                	add	sp,sp,-48
    8000311e:	f406                	sd	ra,40(sp)
    80003120:	f022                	sd	s0,32(sp)
    80003122:	ec26                	sd	s1,24(sp)
    80003124:	e84a                	sd	s2,16(sp)
    80003126:	e44e                	sd	s3,8(sp)
    80003128:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000312a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000312e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003132:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003136:	1004f793          	and	a5,s1,256
    8000313a:	cb85                	beqz	a5,8000316a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000313c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003140:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80003142:	ef85                	bnez	a5,8000317a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003144:	00000097          	auipc	ra,0x0
    80003148:	f32080e7          	jalr	-206(ra) # 80003076 <devintr>
    8000314c:	cd1d                	beqz	a0,8000318a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    8000314e:	4789                	li	a5,2
    80003150:	08f50763          	beq	a0,a5,800031de <kerneltrap+0xc2>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003154:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003158:	10049073          	csrw	sstatus,s1
}
    8000315c:	70a2                	ld	ra,40(sp)
    8000315e:	7402                	ld	s0,32(sp)
    80003160:	64e2                	ld	s1,24(sp)
    80003162:	6942                	ld	s2,16(sp)
    80003164:	69a2                	ld	s3,8(sp)
    80003166:	6145                	add	sp,sp,48
    80003168:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000316a:	00005517          	auipc	a0,0x5
    8000316e:	4ae50513          	add	a0,a0,1198 # 80008618 <digits+0x428>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	06e080e7          	jalr	110(ra) # 800011e0 <panic>
    panic("kerneltrap: interrupts enabled");
    8000317a:	00005517          	auipc	a0,0x5
    8000317e:	4c650513          	add	a0,a0,1222 # 80008640 <digits+0x450>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	05e080e7          	jalr	94(ra) # 800011e0 <panic>
    printf("scause %p\n", scause);
    8000318a:	85ce                	mv	a1,s3
    8000318c:	00005517          	auipc	a0,0x5
    80003190:	4d450513          	add	a0,a0,1236 # 80008660 <digits+0x470>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	096080e7          	jalr	150(ra) # 8000122a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000319c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031a0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031a4:	00005517          	auipc	a0,0x5
    800031a8:	4cc50513          	add	a0,a0,1228 # 80008670 <digits+0x480>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	07e080e7          	jalr	126(ra) # 8000122a <printf>
    printf("current process: %p\n", myproc());
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	f5a080e7          	jalr	-166(ra) # 8000210e <myproc>
    800031bc:	85aa                	mv	a1,a0
    800031be:	00005517          	auipc	a0,0x5
    800031c2:	4ca50513          	add	a0,a0,1226 # 80008688 <digits+0x498>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	064080e7          	jalr	100(ra) # 8000122a <printf>
    panic("kerneltrap");
    800031ce:	00005517          	auipc	a0,0x5
    800031d2:	4d250513          	add	a0,a0,1234 # 800086a0 <digits+0x4b0>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	00a080e7          	jalr	10(ra) # 800011e0 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	f30080e7          	jalr	-208(ra) # 8000210e <myproc>
    800031e6:	d53d                	beqz	a0,80003154 <kerneltrap+0x38>
    800031e8:	fffff097          	auipc	ra,0xfffff
    800031ec:	f26080e7          	jalr	-218(ra) # 8000210e <myproc>
    800031f0:	5118                	lw	a4,32(a0)
    800031f2:	4791                	li	a5,4
    800031f4:	f6f710e3          	bne	a4,a5,80003154 <kerneltrap+0x38>
     yield();
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	154080e7          	jalr	340(ra) # 8000334c <yield>
    80003200:	bf91                	j	80003154 <kerneltrap+0x38>

0000000080003202 <scheduler>:
//  - 选择一个进程运行
//  - 通过swtch切换到该进程开始运行
//  - 最终该进程通过swtch将控制权交回给调度器
void
scheduler(void)
{
    80003202:	715d                	add	sp,sp,-80
    80003204:	e486                	sd	ra,72(sp)
    80003206:	e0a2                	sd	s0,64(sp)
    80003208:	fc26                	sd	s1,56(sp)
    8000320a:	f84a                	sd	s2,48(sp)
    8000320c:	f44e                	sd	s3,40(sp)
    8000320e:	f052                	sd	s4,32(sp)
    80003210:	ec56                	sd	s5,24(sp)
    80003212:	e85a                	sd	s6,16(sp)
    80003214:	e45e                	sd	s7,8(sp)
    80003216:	0880                	add	s0,sp,80
  struct proc *p;
  struct cpu *c = mycpu();
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	eda080e7          	jalr	-294(ra) # 800020f2 <mycpu>
    80003220:	8aaa                	mv	s5,a0
  
  c->proc = 0;
    80003222:	00053423          	sd	zero,8(a0)
    intr_on();

    // 遍历进程表，寻找可运行的进程
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
    80003226:	4a0d                	li	s4,3
        // printf(" running process %d\n", p->pid);
        // 切换到选中的进程。进程有责任释放其锁
        // 然后在跳回调度器之前重新获取锁
        p->state = RUNNING;
    80003228:	4b91                	li	s7,4
        c->proc = p;
        
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    8000322a:	01050b13          	add	s6,a0,16
    for(p = proc; p < &proc[NPROC]; p++) {
    8000322e:	00014997          	auipc	s3,0x14
    80003232:	b5a98993          	add	s3,s3,-1190 # 80016d88 <wait_lock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003236:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000323a:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000323e:	10079073          	csrw	sstatus,a5
    80003242:	0000e497          	auipc	s1,0xe
    80003246:	14648493          	add	s1,s1,326 # 80011388 <proc>
    8000324a:	a811                	j	8000325e <scheduler+0x5c>
        // 进程暂时运行完毕
        // 它应该在返回之前改变了p->state
        c->proc = 0;
        // printf(" process %d finished running\n", p->pid);
      }
      release(&p->lock);
    8000324c:	854a                	mv	a0,s2
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	da2080e7          	jalr	-606(ra) # 80002ff0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80003256:	16848493          	add	s1,s1,360
    8000325a:	fd348ee3          	beq	s1,s3,80003236 <scheduler+0x34>
      acquire(&p->lock);
    8000325e:	00848913          	add	s2,s1,8
    80003262:	854a                	mv	a0,s2
    80003264:	00000097          	auipc	ra,0x0
    80003268:	cd8080e7          	jalr	-808(ra) # 80002f3c <acquire>
      if(p->state == RUNNABLE) {
    8000326c:	509c                	lw	a5,32(s1)
    8000326e:	fd479fe3          	bne	a5,s4,8000324c <scheduler+0x4a>
        p->state = RUNNING;
    80003272:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    80003276:	009ab423          	sd	s1,8(s5)
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    8000327a:	0f848593          	add	a1,s1,248
    8000327e:	855a                	mv	a0,s6
    80003280:	00003097          	auipc	ra,0x3
    80003284:	118080e7          	jalr	280(ra) # 80006398 <initcode_end>
        c->proc = 0;
    80003288:	000ab423          	sd	zero,8(s5)
    8000328c:	b7c1                	j	8000324c <scheduler+0x4a>

000000008000328e <sched>:
// 并且已经改变了proc->state。
// 因为intena是这个内核线程的属性，而不是这个CPU的属性。
// 因此此处需要保存和恢复intena
void
sched(void)
{
    8000328e:	1101                	add	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	e04a                	sd	s2,0(sp)
    80003298:	1000                	add	s0,sp,32
  int intena;
  struct proc *p = myproc();
    8000329a:	fffff097          	auipc	ra,0xfffff
    8000329e:	e74080e7          	jalr	-396(ra) # 8000210e <myproc>
    800032a2:	84aa                	mv	s1,a0

  if(!holding(&p->lock))
    800032a4:	0521                	add	a0,a0,8
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	c1c080e7          	jalr	-996(ra) # 80002ec2 <holding>
    800032ae:	cd39                	beqz	a0,8000330c <sched+0x7e>
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	e42080e7          	jalr	-446(ra) # 800020f2 <mycpu>
    800032b8:	4118                	lw	a4,0(a0)
    800032ba:	4785                	li	a5,1
    800032bc:	06f71063          	bne	a4,a5,8000331c <sched+0x8e>
    panic("sched locks");
  if(p->state == RUNNING)
    800032c0:	5098                	lw	a4,32(s1)
    800032c2:	4791                	li	a5,4
    800032c4:	06f70463          	beq	a4,a5,8000332c <sched+0x9e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032c8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800032cc:	8b89                	and	a5,a5,2
    panic("sched running");
  if(intr_get())
    800032ce:	e7bd                	bnez	a5,8000333c <sched+0xae>
    panic("sched interruptible");

  intena = mycpu()->intena;
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	e22080e7          	jalr	-478(ra) # 800020f2 <mycpu>
    800032d8:	00452903          	lw	s2,4(a0)
  swtch(&p->ctx, &mycpu()->context);  // 切换到调度器上下文
    800032dc:	fffff097          	auipc	ra,0xfffff
    800032e0:	e16080e7          	jalr	-490(ra) # 800020f2 <mycpu>
    800032e4:	01050593          	add	a1,a0,16
    800032e8:	0f848513          	add	a0,s1,248
    800032ec:	00003097          	auipc	ra,0x3
    800032f0:	0ac080e7          	jalr	172(ra) # 80006398 <initcode_end>
  mycpu()->intena = intena;
    800032f4:	fffff097          	auipc	ra,0xfffff
    800032f8:	dfe080e7          	jalr	-514(ra) # 800020f2 <mycpu>
    800032fc:	01252223          	sw	s2,4(a0)
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6902                	ld	s2,0(sp)
    80003308:	6105                	add	sp,sp,32
    8000330a:	8082                	ret
    panic("sched p->lock");
    8000330c:	00005517          	auipc	a0,0x5
    80003310:	3a450513          	add	a0,a0,932 # 800086b0 <digits+0x4c0>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	ecc080e7          	jalr	-308(ra) # 800011e0 <panic>
    panic("sched locks");
    8000331c:	00005517          	auipc	a0,0x5
    80003320:	3a450513          	add	a0,a0,932 # 800086c0 <digits+0x4d0>
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	ebc080e7          	jalr	-324(ra) # 800011e0 <panic>
    panic("sched running");
    8000332c:	00005517          	auipc	a0,0x5
    80003330:	3a450513          	add	a0,a0,932 # 800086d0 <digits+0x4e0>
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	eac080e7          	jalr	-340(ra) # 800011e0 <panic>
    panic("sched interruptible");
    8000333c:	00005517          	auipc	a0,0x5
    80003340:	3a450513          	add	a0,a0,932 # 800086e0 <digits+0x4f0>
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	e9c080e7          	jalr	-356(ra) # 800011e0 <panic>

000000008000334c <yield>:

// 用于进程放弃CPU, 重新进入调度
void
yield(void)
{
    8000334c:	1101                	add	sp,sp,-32
    8000334e:	ec06                	sd	ra,24(sp)
    80003350:	e822                	sd	s0,16(sp)
    80003352:	e426                	sd	s1,8(sp)
    80003354:	e04a                	sd	s2,0(sp)
    80003356:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80003358:	fffff097          	auipc	ra,0xfffff
    8000335c:	db6080e7          	jalr	-586(ra) # 8000210e <myproc>
    80003360:	84aa                	mv	s1,a0
  acquire(&p->lock);     // 获取进程锁
    80003362:	00850913          	add	s2,a0,8
    80003366:	854a                	mv	a0,s2
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	bd4080e7          	jalr	-1068(ra) # 80002f3c <acquire>
  p->state = RUNNABLE;   // 将进程状态设为可运行
    80003370:	478d                	li	a5,3
    80003372:	d09c                	sw	a5,32(s1)
  sched();               // 调用sched()切换到调度器
    80003374:	00000097          	auipc	ra,0x0
    80003378:	f1a080e7          	jalr	-230(ra) # 8000328e <sched>
  release(&p->lock);     // 释放进程锁
    8000337c:	854a                	mv	a0,s2
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	c72080e7          	jalr	-910(ra) # 80002ff0 <release>
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6902                	ld	s2,0(sp)
    8000338e:	6105                	add	sp,sp,32
    80003390:	8082                	ret

0000000080003392 <trap_user_return>:
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
    80003392:	1141                	add	sp,sp,-16
    80003394:	e406                	sd	ra,8(sp)
    80003396:	e022                	sd	s0,0(sp)
    80003398:	0800                	add	s0,sp,16
  //printf("trap_user_return\n");
  struct proc *p = myproc();
    8000339a:	fffff097          	auipc	ra,0xfffff
    8000339e:	d74080e7          	jalr	-652(ra) # 8000210e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800033a6:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033a8:	10079073          	csrw	sstatus,a5
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800033ac:	00004697          	auipc	a3,0x4
    800033b0:	c5468693          	add	a3,a3,-940 # 80007000 <_trampoline>
    800033b4:	00004717          	auipc	a4,0x4
    800033b8:	c4c70713          	add	a4,a4,-948 # 80007000 <_trampoline>
    800033bc:	8f15                	sub	a4,a4,a3
    800033be:	040007b7          	lui	a5,0x4000
    800033c2:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800033c4:	07b2                	sll	a5,a5,0xc
    800033c6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800033c8:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
    800033cc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800033ce:	18002673          	csrr	a2,satp
    800033d2:	e310                	sd	a2,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
    800033d4:	6d30                	ld	a2,88(a0)
    800033d6:	7978                	ld	a4,240(a0)
    800033d8:	6585                	lui	a1,0x1
    800033da:	972e                	add	a4,a4,a1
    800033dc:	e618                	sd	a4,8(a2)
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
    800033de:	6d38                	ld	a4,88(a0)
    800033e0:	00000617          	auipc	a2,0x0
    800033e4:	04860613          	add	a2,a2,72 # 80003428 <trap_user_handler>
    800033e8:	eb10                	sd	a2,16(a4)
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid
    800033ea:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800033ec:	8612                	mv	a2,tp
    800033ee:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033f0:	10002773          	csrr	a4,sstatus
  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
    800033f4:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
    800033f8:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033fc:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);
    80003400:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003402:	6f18                	ld	a4,24(a4)
    80003404:	14171073          	csrw	sepc,a4

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);
    80003408:	6528                	ld	a0,72(a0)
    8000340a:	8131                	srl	a0,a0,0xc

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000340c:	00004717          	auipc	a4,0x4
    80003410:	c9070713          	add	a4,a4,-880 # 8000709c <userret>
    80003414:	8f15                	sub	a4,a4,a3
    80003416:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80003418:	577d                	li	a4,-1
    8000341a:	177e                	sll	a4,a4,0x3f
    8000341c:	8d59                	or	a0,a0,a4
    8000341e:	9782                	jalr	a5
    80003420:	60a2                	ld	ra,8(sp)
    80003422:	6402                	ld	s0,0(sp)
    80003424:	0141                	add	sp,sp,16
    80003426:	8082                	ret

0000000080003428 <trap_user_handler>:
{
    80003428:	7139                	add	sp,sp,-64
    8000342a:	fc06                	sd	ra,56(sp)
    8000342c:	f822                	sd	s0,48(sp)
    8000342e:	f426                	sd	s1,40(sp)
    80003430:	f04a                	sd	s2,32(sp)
    80003432:	ec4e                	sd	s3,24(sp)
    80003434:	e852                	sd	s4,16(sp)
    80003436:	e456                	sd	s5,8(sp)
    80003438:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000343a:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000343e:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003442:	14202a73          	csrr	s4,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003446:	14302af3          	csrr	s5,stval
    proc_t* p = myproc();
    8000344a:	fffff097          	auipc	ra,0xfffff
    8000344e:	cc4080e7          	jalr	-828(ra) # 8000210e <myproc>
    if(sstatus & SSTATUS_SPP)
    80003452:	10097913          	and	s2,s2,256
    80003456:	04091b63          	bnez	s2,800034ac <trap_user_handler+0x84>
    8000345a:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000345c:	00003797          	auipc	a5,0x3
    80003460:	fb478793          	add	a5,a5,-76 # 80006410 <kernelvec>
    80003464:	10579073          	csrw	stvec,a5
  p->tf->epc = sepc;
    80003468:	6d3c                	ld	a5,88(a0)
    8000346a:	0137bc23          	sd	s3,24(a5)
  if(scause == 8){
    8000346e:	47a1                	li	a5,8
    80003470:	04fa0663          	beq	s4,a5,800034bc <trap_user_handler+0x94>
  } else if((which_dev = devintr()) != 0){
    80003474:	00000097          	auipc	ra,0x0
    80003478:	c02080e7          	jalr	-1022(ra) # 80003076 <devintr>
    8000347c:	892a                	mv	s2,a0
    8000347e:	c549                	beqz	a0,80003508 <trap_user_handler+0xe0>
  if(killed(p))
    80003480:	8526                	mv	a0,s1
    80003482:	fffff097          	auipc	ra,0xfffff
    80003486:	5a4080e7          	jalr	1444(ra) # 80002a26 <killed>
    8000348a:	e13d                	bnez	a0,800034f0 <trap_user_handler+0xc8>
  if(which_dev == 2)
    8000348c:	4789                	li	a5,2
    8000348e:	0af90963          	beq	s2,a5,80003540 <trap_user_handler+0x118>
  trap_user_return();
    80003492:	00000097          	auipc	ra,0x0
    80003496:	f00080e7          	jalr	-256(ra) # 80003392 <trap_user_return>
}
    8000349a:	70e2                	ld	ra,56(sp)
    8000349c:	7442                	ld	s0,48(sp)
    8000349e:	74a2                	ld	s1,40(sp)
    800034a0:	7902                	ld	s2,32(sp)
    800034a2:	69e2                	ld	s3,24(sp)
    800034a4:	6a42                	ld	s4,16(sp)
    800034a6:	6aa2                	ld	s5,8(sp)
    800034a8:	6121                	add	sp,sp,64
    800034aa:	8082                	ret
        panic("trap_user_handler: not from u-mode");
    800034ac:	00005517          	auipc	a0,0x5
    800034b0:	24c50513          	add	a0,a0,588 # 800086f8 <digits+0x508>
    800034b4:	ffffe097          	auipc	ra,0xffffe
    800034b8:	d2c080e7          	jalr	-724(ra) # 800011e0 <panic>
    if(killed(p))
    800034bc:	fffff097          	auipc	ra,0xfffff
    800034c0:	56a080e7          	jalr	1386(ra) # 80002a26 <killed>
    800034c4:	ed05                	bnez	a0,800034fc <trap_user_handler+0xd4>
    p->tf->epc += 4;
    800034c6:	6cb8                	ld	a4,88(s1)
    800034c8:	6f1c                	ld	a5,24(a4)
    800034ca:	0791                	add	a5,a5,4
    800034cc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800034d2:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034d6:	10079073          	csrw	sstatus,a5
    syscall();
    800034da:	00000097          	auipc	ra,0x0
    800034de:	0d8080e7          	jalr	216(ra) # 800035b2 <syscall>
  if(killed(p))
    800034e2:	8526                	mv	a0,s1
    800034e4:	fffff097          	auipc	ra,0xfffff
    800034e8:	542080e7          	jalr	1346(ra) # 80002a26 <killed>
    800034ec:	d15d                	beqz	a0,80003492 <trap_user_handler+0x6a>
    int which_dev = 0;  // 用于标识设备中断类型
    800034ee:	4901                	li	s2,0
    exit(-1);
    800034f0:	557d                	li	a0,-1
    800034f2:	fffff097          	auipc	ra,0xfffff
    800034f6:	70c080e7          	jalr	1804(ra) # 80002bfe <exit>
    800034fa:	bf49                	j	8000348c <trap_user_handler+0x64>
      exit(-1);
    800034fc:	557d                	li	a0,-1
    800034fe:	fffff097          	auipc	ra,0xfffff
    80003502:	700080e7          	jalr	1792(ra) # 80002bfe <exit>
    80003506:	b7c1                	j	800034c6 <trap_user_handler+0x9e>
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    80003508:	4090                	lw	a2,0(s1)
    8000350a:	85d2                	mv	a1,s4
    8000350c:	00005517          	auipc	a0,0x5
    80003510:	21450513          	add	a0,a0,532 # 80008720 <digits+0x530>
    80003514:	ffffe097          	auipc	ra,0xffffe
    80003518:	d16080e7          	jalr	-746(ra) # 8000122a <printf>
    printf("            sepc=%p stval=%p\n", sepc, stval);
    8000351c:	8656                	mv	a2,s5
    8000351e:	85ce                	mv	a1,s3
    80003520:	00005517          	auipc	a0,0x5
    80003524:	23050513          	add	a0,a0,560 # 80008750 <digits+0x560>
    80003528:	ffffe097          	auipc	ra,0xffffe
    8000352c:	d02080e7          	jalr	-766(ra) # 8000122a <printf>
    panic("usertrap");
    80003530:	00005517          	auipc	a0,0x5
    80003534:	24050513          	add	a0,a0,576 # 80008770 <digits+0x580>
    80003538:	ffffe097          	auipc	ra,0xffffe
    8000353c:	ca8080e7          	jalr	-856(ra) # 800011e0 <panic>
    yield();  // 让出 CPU，调度其他进程
    80003540:	00000097          	auipc	ra,0x0
    80003544:	e0c080e7          	jalr	-500(ra) # 8000334c <yield>
    80003548:	b7a9                	j	80003492 <trap_user_handler+0x6a>

000000008000354a <arg_raw>:
    第二种使用uvm_copyin 和 uvm_copyinstr 进行传递
*/

// 读取 n 号参数,它放在 an 寄存器中
static uint64 arg_raw(int n)
{   
    8000354a:	1101                	add	sp,sp,-32
    8000354c:	ec06                	sd	ra,24(sp)
    8000354e:	e822                	sd	s0,16(sp)
    80003550:	e426                	sd	s1,8(sp)
    80003552:	1000                	add	s0,sp,32
    80003554:	84aa                	mv	s1,a0
    proc_t* proc = myproc();
    80003556:	fffff097          	auipc	ra,0xfffff
    8000355a:	bb8080e7          	jalr	-1096(ra) # 8000210e <myproc>
    switch(n) {
    8000355e:	4795                	li	a5,5
    80003560:	0497e163          	bltu	a5,s1,800035a2 <arg_raw+0x58>
    80003564:	048a                	sll	s1,s1,0x2
    80003566:	00005717          	auipc	a4,0x5
    8000356a:	25a70713          	add	a4,a4,602 # 800087c0 <digits+0x5d0>
    8000356e:	94ba                	add	s1,s1,a4
    80003570:	409c                	lw	a5,0(s1)
    80003572:	97ba                	add	a5,a5,a4
    80003574:	8782                	jr	a5
        case 0:
            return proc->tf->a0;
    80003576:	6d3c                	ld	a5,88(a0)
    80003578:	7ba8                	ld	a0,112(a5)
            return proc->tf->a5;
        default:
            panic("arg_raw: illegal arg num");
            return -1;
    }
}
    8000357a:	60e2                	ld	ra,24(sp)
    8000357c:	6442                	ld	s0,16(sp)
    8000357e:	64a2                	ld	s1,8(sp)
    80003580:	6105                	add	sp,sp,32
    80003582:	8082                	ret
            return proc->tf->a1;
    80003584:	6d3c                	ld	a5,88(a0)
    80003586:	7fa8                	ld	a0,120(a5)
    80003588:	bfcd                	j	8000357a <arg_raw+0x30>
            return proc->tf->a2;
    8000358a:	6d3c                	ld	a5,88(a0)
    8000358c:	63c8                	ld	a0,128(a5)
    8000358e:	b7f5                	j	8000357a <arg_raw+0x30>
            return proc->tf->a3;
    80003590:	6d3c                	ld	a5,88(a0)
    80003592:	67c8                	ld	a0,136(a5)
    80003594:	b7dd                	j	8000357a <arg_raw+0x30>
            return proc->tf->a4;
    80003596:	6d3c                	ld	a5,88(a0)
    80003598:	6bc8                	ld	a0,144(a5)
    8000359a:	b7c5                	j	8000357a <arg_raw+0x30>
            return proc->tf->a5;
    8000359c:	6d3c                	ld	a5,88(a0)
    8000359e:	6fc8                	ld	a0,152(a5)
    800035a0:	bfe9                	j	8000357a <arg_raw+0x30>
            panic("arg_raw: illegal arg num");
    800035a2:	00005517          	auipc	a0,0x5
    800035a6:	1de50513          	add	a0,a0,478 # 80008780 <digits+0x590>
    800035aa:	ffffe097          	auipc	ra,0xffffe
    800035ae:	c36080e7          	jalr	-970(ra) # 800011e0 <panic>

00000000800035b2 <syscall>:
{
    800035b2:	1101                	add	sp,sp,-32
    800035b4:	ec06                	sd	ra,24(sp)
    800035b6:	e822                	sd	s0,16(sp)
    800035b8:	e426                	sd	s1,8(sp)
    800035ba:	e04a                	sd	s2,0(sp)
    800035bc:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    800035be:	fffff097          	auipc	ra,0xfffff
    800035c2:	b50080e7          	jalr	-1200(ra) # 8000210e <myproc>
    800035c6:	84aa                	mv	s1,a0
    num = p->tf->a7;
    800035c8:	05853903          	ld	s2,88(a0)
    800035cc:	0a892603          	lw	a2,168(s2)
    if(num >= 0 && num < NELEM(syscalls) && syscalls[num]) {
    800035d0:	47dd                	li	a5,23
    800035d2:	00c7ef63          	bltu	a5,a2,800035f0 <syscall+0x3e>
    800035d6:	00361713          	sll	a4,a2,0x3
    800035da:	00005797          	auipc	a5,0x5
    800035de:	1fe78793          	add	a5,a5,510 # 800087d8 <syscalls>
    800035e2:	97ba                	add	a5,a5,a4
    800035e4:	639c                	ld	a5,0(a5)
    800035e6:	c789                	beqz	a5,800035f0 <syscall+0x3e>
        p->tf->a0 = syscalls[num]();
    800035e8:	9782                	jalr	a5
    800035ea:	06a93823          	sd	a0,112(s2)
    800035ee:	a829                	j	80003608 <syscall+0x56>
        printf("pid %d: unknown sys call %d\n",
    800035f0:	408c                	lw	a1,0(s1)
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	1ae50513          	add	a0,a0,430 # 800087a0 <digits+0x5b0>
    800035fa:	ffffe097          	auipc	ra,0xffffe
    800035fe:	c30080e7          	jalr	-976(ra) # 8000122a <printf>
        p->tf->a0 = -1;
    80003602:	6cbc                	ld	a5,88(s1)
    80003604:	577d                	li	a4,-1
    80003606:	fbb8                	sd	a4,112(a5)
}
    80003608:	60e2                	ld	ra,24(sp)
    8000360a:	6442                	ld	s0,16(sp)
    8000360c:	64a2                	ld	s1,8(sp)
    8000360e:	6902                	ld	s2,0(sp)
    80003610:	6105                	add	sp,sp,32
    80003612:	8082                	ret

0000000080003614 <arg_uint32>:

// 读取 n 号参数, 作为 uint32 存储
void arg_uint32(int n, uint32* ip)
{
    80003614:	1101                	add	sp,sp,-32
    80003616:	ec06                	sd	ra,24(sp)
    80003618:	e822                	sd	s0,16(sp)
    8000361a:	e426                	sd	s1,8(sp)
    8000361c:	1000                	add	s0,sp,32
    8000361e:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    80003620:	00000097          	auipc	ra,0x0
    80003624:	f2a080e7          	jalr	-214(ra) # 8000354a <arg_raw>
    80003628:	c088                	sw	a0,0(s1)
}
    8000362a:	60e2                	ld	ra,24(sp)
    8000362c:	6442                	ld	s0,16(sp)
    8000362e:	64a2                	ld	s1,8(sp)
    80003630:	6105                	add	sp,sp,32
    80003632:	8082                	ret

0000000080003634 <arg_uint64>:

// 读取 n 号参数, 作为 uint64 存储
void arg_uint64(int n, uint64* ip)
{
    80003634:	1101                	add	sp,sp,-32
    80003636:	ec06                	sd	ra,24(sp)
    80003638:	e822                	sd	s0,16(sp)
    8000363a:	e426                	sd	s1,8(sp)
    8000363c:	1000                	add	s0,sp,32
    8000363e:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    80003640:	00000097          	auipc	ra,0x0
    80003644:	f0a080e7          	jalr	-246(ra) # 8000354a <arg_raw>
    80003648:	e088                	sd	a0,0(s1)
}
    8000364a:	60e2                	ld	ra,24(sp)
    8000364c:	6442                	ld	s0,16(sp)
    8000364e:	64a2                	ld	s1,8(sp)
    80003650:	6105                	add	sp,sp,32
    80003652:	8082                	ret

0000000080003654 <arg_str>:

// 读取 n 号参数指向的字符串到 buf, 字符串最大长度是 maxlen
void arg_str(int n, char* buf, int maxlen)
{
    80003654:	7139                	add	sp,sp,-64
    80003656:	fc06                	sd	ra,56(sp)
    80003658:	f822                	sd	s0,48(sp)
    8000365a:	f426                	sd	s1,40(sp)
    8000365c:	f04a                	sd	s2,32(sp)
    8000365e:	ec4e                	sd	s3,24(sp)
    80003660:	e852                	sd	s4,16(sp)
    80003662:	0080                	add	s0,sp,64
    80003664:	8a2a                	mv	s4,a0
    80003666:	892e                	mv	s2,a1
    80003668:	89b2                	mv	s3,a2
    proc_t* p = myproc();
    8000366a:	fffff097          	auipc	ra,0xfffff
    8000366e:	aa4080e7          	jalr	-1372(ra) # 8000210e <myproc>
    80003672:	84aa                	mv	s1,a0
    uint64 addr;
    arg_uint64(n, &addr);
    80003674:	fc840593          	add	a1,s0,-56
    80003678:	8552                	mv	a0,s4
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	fba080e7          	jalr	-70(ra) # 80003634 <arg_uint64>

    uvm_copyin_str(p->pgtbl, (uint64)buf, addr, maxlen);
    80003682:	86ce                	mv	a3,s3
    80003684:	fc843603          	ld	a2,-56(s0)
    80003688:	85ca                	mv	a1,s2
    8000368a:	64a8                	ld	a0,72(s1)
    8000368c:	ffffe097          	auipc	ra,0xffffe
    80003690:	78e080e7          	jalr	1934(ra) # 80001e1a <uvm_copyin_str>
}
    80003694:	70e2                	ld	ra,56(sp)
    80003696:	7442                	ld	s0,48(sp)
    80003698:	74a2                	ld	s1,40(sp)
    8000369a:	7902                	ld	s2,32(sp)
    8000369c:	69e2                	ld	s3,24(sp)
    8000369e:	6a42                	ld	s4,16(sp)
    800036a0:	6121                	add	sp,sp,64
    800036a2:	8082                	ret

00000000800036a4 <fetchstr>:

int
fetchstr(uint64 addr, char *buf, int max)
{
    800036a4:	7179                	add	sp,sp,-48
    800036a6:	f406                	sd	ra,40(sp)
    800036a8:	f022                	sd	s0,32(sp)
    800036aa:	ec26                	sd	s1,24(sp)
    800036ac:	e84a                	sd	s2,16(sp)
    800036ae:	e44e                	sd	s3,8(sp)
    800036b0:	1800                	add	s0,sp,48
    800036b2:	892a                	mv	s2,a0
    800036b4:	84ae                	mv	s1,a1
    800036b6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800036b8:	fffff097          	auipc	ra,0xfffff
    800036bc:	a56080e7          	jalr	-1450(ra) # 8000210e <myproc>
  if(uvm_copyin_str(p->pgtbl, (uint64) buf, addr, max) < 0)
    800036c0:	86ce                	mv	a3,s3
    800036c2:	864a                	mv	a2,s2
    800036c4:	85a6                	mv	a1,s1
    800036c6:	6528                	ld	a0,72(a0)
    800036c8:	ffffe097          	auipc	ra,0xffffe
    800036cc:	752080e7          	jalr	1874(ra) # 80001e1a <uvm_copyin_str>
    800036d0:	00054e63          	bltz	a0,800036ec <fetchstr+0x48>
    return -1;
  return strlen(buf);
    800036d4:	8526                	mv	a0,s1
    800036d6:	ffffe097          	auipc	ra,0xffffe
    800036da:	a3c080e7          	jalr	-1476(ra) # 80001112 <strlen>
}
    800036de:	70a2                	ld	ra,40(sp)
    800036e0:	7402                	ld	s0,32(sp)
    800036e2:	64e2                	ld	s1,24(sp)
    800036e4:	6942                	ld	s2,16(sp)
    800036e6:	69a2                	ld	s3,8(sp)
    800036e8:	6145                	add	sp,sp,48
    800036ea:	8082                	ret
    return -1;
    800036ec:	557d                	li	a0,-1
    800036ee:	bfc5                	j	800036de <fetchstr+0x3a>

00000000800036f0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800036f0:	7179                	add	sp,sp,-48
    800036f2:	f406                	sd	ra,40(sp)
    800036f4:	f022                	sd	s0,32(sp)
    800036f6:	ec26                	sd	s1,24(sp)
    800036f8:	e84a                	sd	s2,16(sp)
    800036fa:	1800                	add	s0,sp,48
    800036fc:	84ae                	mv	s1,a1
    800036fe:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003700:	fd840593          	add	a1,s0,-40
    80003704:	00000097          	auipc	ra,0x0
    80003708:	f30080e7          	jalr	-208(ra) # 80003634 <arg_uint64>
  return fetchstr(addr, buf, max);
    8000370c:	864a                	mv	a2,s2
    8000370e:	85a6                	mv	a1,s1
    80003710:	fd843503          	ld	a0,-40(s0)
    80003714:	00000097          	auipc	ra,0x0
    80003718:	f90080e7          	jalr	-112(ra) # 800036a4 <fetchstr>
    8000371c:	70a2                	ld	ra,40(sp)
    8000371e:	7402                	ld	s0,32(sp)
    80003720:	64e2                	ld	s1,24(sp)
    80003722:	6942                	ld	s2,16(sp)
    80003724:	6145                	add	sp,sp,48
    80003726:	8082                	ret

0000000080003728 <sys_brk>:

// 堆伸缩
// uint64 new_heap_top 新的堆顶 (如果是0代表查询, 返回旧的堆顶)
// 成功返回新的堆顶 失败返回-1
uint64 sys_brk()
{
    80003728:	7179                	add	sp,sp,-48
    8000372a:	f406                	sd	ra,40(sp)
    8000372c:	f022                	sd	s0,32(sp)
    8000372e:	ec26                	sd	s1,24(sp)
    80003730:	1800                	add	s0,sp,48
    uint64 new_addr;
    uint64 old_addr = myproc()->sz;  // 保存原始堆顶
    80003732:	fffff097          	auipc	ra,0xfffff
    80003736:	9dc080e7          	jalr	-1572(ra) # 8000210e <myproc>
    8000373a:	7564                	ld	s1,232(a0)

    arg_uint64(0, &new_addr);  // 正确读取64位地址
    8000373c:	fd840593          	add	a1,s0,-40
    80003740:	4501                	li	a0,0
    80003742:	00000097          	auipc	ra,0x0
    80003746:	ef2080e7          	jalr	-270(ra) # 80003634 <arg_uint64>
    
    if(new_addr == old_addr || new_addr == 0) {
    8000374a:	fd843783          	ld	a5,-40(s0)
    8000374e:	00978963          	beq	a5,s1,80003760 <sys_brk+0x38>
    80003752:	c799                	beqz	a5,80003760 <sys_brk+0x38>
        return old_addr;  // 无变化，返回当前堆顶
    }
    
    int diff = (int)(new_addr - old_addr);
    80003754:	4097853b          	subw	a0,a5,s1
    
    // 检查是否溢出
    if((uint64)diff != (new_addr - old_addr)) {
    80003758:	8f85                	sub	a5,a5,s1
        return -1;  // 差值太大，int无法表示
    8000375a:	54fd                	li	s1,-1
    if((uint64)diff != (new_addr - old_addr)) {
    8000375c:	00f50863          	beq	a0,a5,8000376c <sys_brk+0x44>
    if(growproc(diff) < 0) {
        return -1;  // 扩展失败
    }
    
    return new_addr;  // 返回扩展前的地址
}
    80003760:	8526                	mv	a0,s1
    80003762:	70a2                	ld	ra,40(sp)
    80003764:	7402                	ld	s0,32(sp)
    80003766:	64e2                	ld	s1,24(sp)
    80003768:	6145                	add	sp,sp,48
    8000376a:	8082                	ret
    if(growproc(diff) < 0) {
    8000376c:	fffff097          	auipc	ra,0xfffff
    80003770:	eb8080e7          	jalr	-328(ra) # 80002624 <growproc>
    80003774:	00054563          	bltz	a0,8000377e <sys_brk+0x56>
    return new_addr;  // 返回扩展前的地址
    80003778:	fd843483          	ld	s1,-40(s0)
    8000377c:	b7d5                	j	80003760 <sys_brk+0x38>
        return -1;  // 扩展失败
    8000377e:	54fd                	li	s1,-1
    80003780:	b7c5                	j	80003760 <sys_brk+0x38>

0000000080003782 <sys_kill>:

uint64
sys_kill(void)
{
    80003782:	1101                	add	sp,sp,-32
    80003784:	ec06                	sd	ra,24(sp)
    80003786:	e822                	sd	s0,16(sp)
    80003788:	1000                	add	s0,sp,32
  uint64 pid;

  arg_uint64(0, &pid);
    8000378a:	fe840593          	add	a1,s0,-24
    8000378e:	4501                	li	a0,0
    80003790:	00000097          	auipc	ra,0x0
    80003794:	ea4080e7          	jalr	-348(ra) # 80003634 <arg_uint64>
  return kill(pid);
    80003798:	fe842503          	lw	a0,-24(s0)
    8000379c:	fffff097          	auipc	ra,0xfffff
    800037a0:	1da080e7          	jalr	474(ra) # 80002976 <kill>
}
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	6105                	add	sp,sp,32
    800037aa:	8082                	ret

00000000800037ac <sys_getpid>:

uint64
sys_getpid(void)
{
    800037ac:	1141                	add	sp,sp,-16
    800037ae:	e406                	sd	ra,8(sp)
    800037b0:	e022                	sd	s0,0(sp)
    800037b2:	0800                	add	s0,sp,16
  return myproc()->pid;
    800037b4:	fffff097          	auipc	ra,0xfffff
    800037b8:	95a080e7          	jalr	-1702(ra) # 8000210e <myproc>
}
    800037bc:	4108                	lw	a0,0(a0)
    800037be:	60a2                	ld	ra,8(sp)
    800037c0:	6402                	ld	s0,0(sp)
    800037c2:	0141                	add	sp,sp,16
    800037c4:	8082                	ret

00000000800037c6 <sys_print>:
// 打印字符
// uint64 addr
uint64 sys_print()
{
    800037c6:	7175                	add	sp,sp,-144
    800037c8:	e506                	sd	ra,136(sp)
    800037ca:	e122                	sd	s0,128(sp)
    800037cc:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    800037ce:	08000613          	li	a2,128
    800037d2:	f7040593          	add	a1,s0,-144
    800037d6:	4501                	li	a0,0
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	e7c080e7          	jalr	-388(ra) # 80003654 <arg_str>

    printf("%s", buf);
    800037e0:	f7040593          	add	a1,s0,-144
    800037e4:	00005517          	auipc	a0,0x5
    800037e8:	0b450513          	add	a0,a0,180 # 80008898 <syscalls+0xc0>
    800037ec:	ffffe097          	auipc	ra,0xffffe
    800037f0:	a3e080e7          	jalr	-1474(ra) # 8000122a <printf>
    return 0;
}
    800037f4:	4501                	li	a0,0
    800037f6:	60aa                	ld	ra,136(sp)
    800037f8:	640a                	ld	s0,128(sp)
    800037fa:	6149                	add	sp,sp,144
    800037fc:	8082                	ret

00000000800037fe <sys_fork>:

// 进程复制
uint64 sys_fork()
{
    800037fe:	1141                	add	sp,sp,-16
    80003800:	e406                	sd	ra,8(sp)
    80003802:	e022                	sd	s0,0(sp)
    80003804:	0800                	add	s0,sp,16
    return fork();
    80003806:	fffff097          	auipc	ra,0xfffff
    8000380a:	f50080e7          	jalr	-176(ra) # 80002756 <fork>
}
    8000380e:	60a2                	ld	ra,8(sp)
    80003810:	6402                	ld	s0,0(sp)
    80003812:	0141                	add	sp,sp,16
    80003814:	8082                	ret

0000000080003816 <sys_wait>:

// 进程等待
// uint64 addr  子进程退出时的exit_state需要放到这里 
uint64 sys_wait()
{
    80003816:	1101                	add	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	1000                	add	s0,sp,32
    uint64 p;
    arg_uint64(0, &p);
    8000381e:	fe840593          	add	a1,s0,-24
    80003822:	4501                	li	a0,0
    80003824:	00000097          	auipc	ra,0x0
    80003828:	e10080e7          	jalr	-496(ra) # 80003634 <arg_uint64>
    return wait(p);
    8000382c:	fe843503          	ld	a0,-24(s0)
    80003830:	fffff097          	auipc	ra,0xfffff
    80003834:	22c080e7          	jalr	556(ra) # 80002a5c <wait>
}
    80003838:	60e2                	ld	ra,24(sp)
    8000383a:	6442                	ld	s0,16(sp)
    8000383c:	6105                	add	sp,sp,32
    8000383e:	8082                	ret

0000000080003840 <sys_exit>:

// 进程退出
// int exit_state
uint64 sys_exit()
{
    80003840:	1101                	add	sp,sp,-32
    80003842:	ec06                	sd	ra,24(sp)
    80003844:	e822                	sd	s0,16(sp)
    80003846:	1000                	add	s0,sp,32
    uint64 n;
    arg_uint64(0, &n);
    80003848:	fe840593          	add	a1,s0,-24
    8000384c:	4501                	li	a0,0
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	de6080e7          	jalr	-538(ra) # 80003634 <arg_uint64>
    exit(n);
    80003856:	fe842503          	lw	a0,-24(s0)
    8000385a:	fffff097          	auipc	ra,0xfffff
    8000385e:	3a4080e7          	jalr	932(ra) # 80002bfe <exit>
    return 0;  // not reached
}
    80003862:	4501                	li	a0,0
    80003864:	60e2                	ld	ra,24(sp)
    80003866:	6442                	ld	s0,16(sp)
    80003868:	6105                	add	sp,sp,32
    8000386a:	8082                	ret

000000008000386c <sys_sleep>:

// 进程睡眠一段时间
// uint32 second 睡眠时间
// 成功返回0, 失败返回-1
uint64 sys_sleep()
{
    8000386c:	7139                	add	sp,sp,-64
    8000386e:	fc06                	sd	ra,56(sp)
    80003870:	f822                	sd	s0,48(sp)
    80003872:	f426                	sd	s1,40(sp)
    80003874:	f04a                	sd	s2,32(sp)
    80003876:	ec4e                	sd	s3,24(sp)
    80003878:	0080                	add	s0,sp,64
    uint64 n;
    uint ticks0;

    arg_uint64(0, &n);
    8000387a:	fc840593          	add	a1,s0,-56
    8000387e:	4501                	li	a0,0
    80003880:	00000097          	auipc	ra,0x0
    80003884:	db4080e7          	jalr	-588(ra) # 80003634 <arg_uint64>
    acquire(& sys_timer.lk);
    80003888:	0000d517          	auipc	a0,0xd
    8000388c:	47050513          	add	a0,a0,1136 # 80010cf8 <sys_timer+0x8>
    80003890:	fffff097          	auipc	ra,0xfffff
    80003894:	6ac080e7          	jalr	1708(ra) # 80002f3c <acquire>
    ticks0 = sys_timer.ticks;
    80003898:	0000d797          	auipc	a5,0xd
    8000389c:	4587b783          	ld	a5,1112(a5) # 80010cf0 <sys_timer>
    while(sys_timer.ticks - ticks0 < n){
    800038a0:	02079913          	sll	s2,a5,0x20
    800038a4:	02095913          	srl	s2,s2,0x20
    800038a8:	412787b3          	sub	a5,a5,s2
    800038ac:	fc843703          	ld	a4,-56(s0)
    800038b0:	04e7f063          	bgeu	a5,a4,800038f0 <sys_sleep+0x84>
        if(killed(myproc())){
        release(&sys_timer.lk);
        return -1;
        }
        sleep(&sys_timer.ticks, &sys_timer.lk);
    800038b4:	0000d997          	auipc	s3,0xd
    800038b8:	44498993          	add	s3,s3,1092 # 80010cf8 <sys_timer+0x8>
    800038bc:	0000d497          	auipc	s1,0xd
    800038c0:	43448493          	add	s1,s1,1076 # 80010cf0 <sys_timer>
        if(killed(myproc())){
    800038c4:	fffff097          	auipc	ra,0xfffff
    800038c8:	84a080e7          	jalr	-1974(ra) # 8000210e <myproc>
    800038cc:	fffff097          	auipc	ra,0xfffff
    800038d0:	15a080e7          	jalr	346(ra) # 80002a26 <killed>
    800038d4:	ed15                	bnez	a0,80003910 <sys_sleep+0xa4>
        sleep(&sys_timer.ticks, &sys_timer.lk);
    800038d6:	85ce                	mv	a1,s3
    800038d8:	8526                	mv	a0,s1
    800038da:	fffff097          	auipc	ra,0xfffff
    800038de:	fb0080e7          	jalr	-80(ra) # 8000288a <sleep>
    while(sys_timer.ticks - ticks0 < n){
    800038e2:	609c                	ld	a5,0(s1)
    800038e4:	412787b3          	sub	a5,a5,s2
    800038e8:	fc843703          	ld	a4,-56(s0)
    800038ec:	fce7ece3          	bltu	a5,a4,800038c4 <sys_sleep+0x58>
    }
    release(& sys_timer.lk);
    800038f0:	0000d517          	auipc	a0,0xd
    800038f4:	40850513          	add	a0,a0,1032 # 80010cf8 <sys_timer+0x8>
    800038f8:	fffff097          	auipc	ra,0xfffff
    800038fc:	6f8080e7          	jalr	1784(ra) # 80002ff0 <release>
    return 0;
    80003900:	4501                	li	a0,0
}
    80003902:	70e2                	ld	ra,56(sp)
    80003904:	7442                	ld	s0,48(sp)
    80003906:	74a2                	ld	s1,40(sp)
    80003908:	7902                	ld	s2,32(sp)
    8000390a:	69e2                	ld	s3,24(sp)
    8000390c:	6121                	add	sp,sp,64
    8000390e:	8082                	ret
        release(&sys_timer.lk);
    80003910:	0000d517          	auipc	a0,0xd
    80003914:	3e850513          	add	a0,a0,1000 # 80010cf8 <sys_timer+0x8>
    80003918:	fffff097          	auipc	ra,0xfffff
    8000391c:	6d8080e7          	jalr	1752(ra) # 80002ff0 <release>
        return -1;
    80003920:	557d                	li	a0,-1
    80003922:	b7c5                	j	80003902 <sys_sleep+0x96>

0000000080003924 <sys_debug>:


uint64 sys_debug(void)
{
    80003924:	7175                	add	sp,sp,-144
    80003926:	e506                	sd	ra,136(sp)
    80003928:	e122                	sd	s0,128(sp)
    8000392a:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    8000392c:	08000613          	li	a2,128
    80003930:	f7040593          	add	a1,s0,-144
    80003934:	4501                	li	a0,0
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	d1e080e7          	jalr	-738(ra) # 80003654 <arg_str>

    printf("[debug] %s \n", buf);
    8000393e:	f7040593          	add	a1,s0,-144
    80003942:	00005517          	auipc	a0,0x5
    80003946:	f5e50513          	add	a0,a0,-162 # 800088a0 <syscalls+0xc8>
    8000394a:	ffffe097          	auipc	ra,0xffffe
    8000394e:	8e0080e7          	jalr	-1824(ra) # 8000122a <printf>
    return 0;
}
    80003952:	4501                	li	a0,0
    80003954:	60aa                	ld	ra,136(sp)
    80003956:	640a                	ld	s0,128(sp)
    80003958:	6149                	add	sp,sp,144
    8000395a:	8082                	ret

000000008000395c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000395c:	7179                	add	sp,sp,-48
    8000395e:	f406                	sd	ra,40(sp)
    80003960:	f022                	sd	s0,32(sp)
    80003962:	ec26                	sd	s1,24(sp)
    80003964:	e84a                	sd	s2,16(sp)
    80003966:	1800                	add	s0,sp,48
    80003968:	892e                	mv	s2,a1
    8000396a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000396c:	fdc40593          	add	a1,s0,-36
    80003970:	00000097          	auipc	ra,0x0
    80003974:	cc4080e7          	jalr	-828(ra) # 80003634 <arg_uint64>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80003978:	fdc42703          	lw	a4,-36(s0)
    8000397c:	47bd                	li	a5,15
    8000397e:	02e7eb63          	bltu	a5,a4,800039b4 <argfd+0x58>
    80003982:	ffffe097          	auipc	ra,0xffffe
    80003986:	78c080e7          	jalr	1932(ra) # 8000210e <myproc>
    8000398a:	fdc42703          	lw	a4,-36(s0)
    8000398e:	00c70793          	add	a5,a4,12
    80003992:	078e                	sll	a5,a5,0x3
    80003994:	953e                	add	a0,a0,a5
    80003996:	611c                	ld	a5,0(a0)
    80003998:	c385                	beqz	a5,800039b8 <argfd+0x5c>
    return -1;
  if(pfd)
    8000399a:	00090463          	beqz	s2,800039a2 <argfd+0x46>
    *pfd = fd;
    8000399e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800039a2:	4501                	li	a0,0
  if(pf)
    800039a4:	c091                	beqz	s1,800039a8 <argfd+0x4c>
    *pf = f;
    800039a6:	e09c                	sd	a5,0(s1)
}
    800039a8:	70a2                	ld	ra,40(sp)
    800039aa:	7402                	ld	s0,32(sp)
    800039ac:	64e2                	ld	s1,24(sp)
    800039ae:	6942                	ld	s2,16(sp)
    800039b0:	6145                	add	sp,sp,48
    800039b2:	8082                	ret
    return -1;
    800039b4:	557d                	li	a0,-1
    800039b6:	bfcd                	j	800039a8 <argfd+0x4c>
    800039b8:	557d                	li	a0,-1
    800039ba:	b7fd                	j	800039a8 <argfd+0x4c>

00000000800039bc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800039bc:	1101                	add	sp,sp,-32
    800039be:	ec06                	sd	ra,24(sp)
    800039c0:	e822                	sd	s0,16(sp)
    800039c2:	e426                	sd	s1,8(sp)
    800039c4:	1000                	add	s0,sp,32
    800039c6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800039c8:	ffffe097          	auipc	ra,0xffffe
    800039cc:	746080e7          	jalr	1862(ra) # 8000210e <myproc>
    800039d0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800039d2:	06050793          	add	a5,a0,96
    800039d6:	4501                	li	a0,0
    800039d8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800039da:	6398                	ld	a4,0(a5)
    800039dc:	cb19                	beqz	a4,800039f2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800039de:	2505                	addw	a0,a0,1
    800039e0:	07a1                	add	a5,a5,8
    800039e2:	fed51ce3          	bne	a0,a3,800039da <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800039e6:	557d                	li	a0,-1
}
    800039e8:	60e2                	ld	ra,24(sp)
    800039ea:	6442                	ld	s0,16(sp)
    800039ec:	64a2                	ld	s1,8(sp)
    800039ee:	6105                	add	sp,sp,32
    800039f0:	8082                	ret
      p->ofile[fd] = f;
    800039f2:	00c50793          	add	a5,a0,12
    800039f6:	078e                	sll	a5,a5,0x3
    800039f8:	963e                	add	a2,a2,a5
    800039fa:	e204                	sd	s1,0(a2)
      return fd;
    800039fc:	b7f5                	j	800039e8 <fdalloc+0x2c>

00000000800039fe <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800039fe:	715d                	add	sp,sp,-80
    80003a00:	e486                	sd	ra,72(sp)
    80003a02:	e0a2                	sd	s0,64(sp)
    80003a04:	fc26                	sd	s1,56(sp)
    80003a06:	f84a                	sd	s2,48(sp)
    80003a08:	f44e                	sd	s3,40(sp)
    80003a0a:	f052                	sd	s4,32(sp)
    80003a0c:	ec56                	sd	s5,24(sp)
    80003a0e:	e85a                	sd	s6,16(sp)
    80003a10:	0880                	add	s0,sp,80
    80003a12:	8b2e                	mv	s6,a1
    80003a14:	89b2                	mv	s3,a2
    80003a16:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80003a18:	fb040593          	add	a1,s0,-80
    80003a1c:	00003097          	auipc	ra,0x3
    80003a20:	85c080e7          	jalr	-1956(ra) # 80006278 <nameiparent>
    80003a24:	84aa                	mv	s1,a0
    80003a26:	14050b63          	beqz	a0,80003b7c <create+0x17e>
    return 0;

  ilock(dp);
    80003a2a:	00002097          	auipc	ra,0x2
    80003a2e:	08c080e7          	jalr	140(ra) # 80005ab6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80003a32:	4601                	li	a2,0
    80003a34:	fb040593          	add	a1,s0,-80
    80003a38:	8526                	mv	a0,s1
    80003a3a:	00002097          	auipc	ra,0x2
    80003a3e:	560080e7          	jalr	1376(ra) # 80005f9a <dirlookup>
    80003a42:	8aaa                	mv	s5,a0
    80003a44:	c921                	beqz	a0,80003a94 <create+0x96>
    iunlockput(dp);
    80003a46:	8526                	mv	a0,s1
    80003a48:	00002097          	auipc	ra,0x2
    80003a4c:	2d0080e7          	jalr	720(ra) # 80005d18 <iunlockput>
    ilock(ip);
    80003a50:	8556                	mv	a0,s5
    80003a52:	00002097          	auipc	ra,0x2
    80003a56:	064080e7          	jalr	100(ra) # 80005ab6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80003a5a:	4789                	li	a5,2
    80003a5c:	02fb1563          	bne	s6,a5,80003a86 <create+0x88>
    80003a60:	044ad783          	lhu	a5,68(s5)
    80003a64:	37f9                	addw	a5,a5,-2
    80003a66:	17c2                	sll	a5,a5,0x30
    80003a68:	93c1                	srl	a5,a5,0x30
    80003a6a:	4705                	li	a4,1
    80003a6c:	00f76d63          	bltu	a4,a5,80003a86 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80003a70:	8556                	mv	a0,s5
    80003a72:	60a6                	ld	ra,72(sp)
    80003a74:	6406                	ld	s0,64(sp)
    80003a76:	74e2                	ld	s1,56(sp)
    80003a78:	7942                	ld	s2,48(sp)
    80003a7a:	79a2                	ld	s3,40(sp)
    80003a7c:	7a02                	ld	s4,32(sp)
    80003a7e:	6ae2                	ld	s5,24(sp)
    80003a80:	6b42                	ld	s6,16(sp)
    80003a82:	6161                	add	sp,sp,80
    80003a84:	8082                	ret
    iunlockput(ip);
    80003a86:	8556                	mv	a0,s5
    80003a88:	00002097          	auipc	ra,0x2
    80003a8c:	290080e7          	jalr	656(ra) # 80005d18 <iunlockput>
    return 0;
    80003a90:	4a81                	li	s5,0
    80003a92:	bff9                	j	80003a70 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80003a94:	85da                	mv	a1,s6
    80003a96:	4088                	lw	a0,0(s1)
    80003a98:	00002097          	auipc	ra,0x2
    80003a9c:	e86080e7          	jalr	-378(ra) # 8000591e <ialloc>
    80003aa0:	8a2a                	mv	s4,a0
    80003aa2:	c529                	beqz	a0,80003aec <create+0xee>
  ilock(ip);
    80003aa4:	00002097          	auipc	ra,0x2
    80003aa8:	012080e7          	jalr	18(ra) # 80005ab6 <ilock>
  ip->major = major;
    80003aac:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80003ab0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80003ab4:	4905                	li	s2,1
    80003ab6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80003aba:	8552                	mv	a0,s4
    80003abc:	00002097          	auipc	ra,0x2
    80003ac0:	f2e080e7          	jalr	-210(ra) # 800059ea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80003ac4:	032b0b63          	beq	s6,s2,80003afa <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80003ac8:	004a2603          	lw	a2,4(s4)
    80003acc:	fb040593          	add	a1,s0,-80
    80003ad0:	8526                	mv	a0,s1
    80003ad2:	00002097          	auipc	ra,0x2
    80003ad6:	6d6080e7          	jalr	1750(ra) # 800061a8 <dirlink>
    80003ada:	06054f63          	bltz	a0,80003b58 <create+0x15a>
  iunlockput(dp);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	00002097          	auipc	ra,0x2
    80003ae4:	238080e7          	jalr	568(ra) # 80005d18 <iunlockput>
  return ip;
    80003ae8:	8ad2                	mv	s5,s4
    80003aea:	b759                	j	80003a70 <create+0x72>
    iunlockput(dp);
    80003aec:	8526                	mv	a0,s1
    80003aee:	00002097          	auipc	ra,0x2
    80003af2:	22a080e7          	jalr	554(ra) # 80005d18 <iunlockput>
    return 0;
    80003af6:	8ad2                	mv	s5,s4
    80003af8:	bfa5                	j	80003a70 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80003afa:	004a2603          	lw	a2,4(s4)
    80003afe:	00005597          	auipc	a1,0x5
    80003b02:	db258593          	add	a1,a1,-590 # 800088b0 <syscalls+0xd8>
    80003b06:	8552                	mv	a0,s4
    80003b08:	00002097          	auipc	ra,0x2
    80003b0c:	6a0080e7          	jalr	1696(ra) # 800061a8 <dirlink>
    80003b10:	04054463          	bltz	a0,80003b58 <create+0x15a>
    80003b14:	40d0                	lw	a2,4(s1)
    80003b16:	00005597          	auipc	a1,0x5
    80003b1a:	da258593          	add	a1,a1,-606 # 800088b8 <syscalls+0xe0>
    80003b1e:	8552                	mv	a0,s4
    80003b20:	00002097          	auipc	ra,0x2
    80003b24:	688080e7          	jalr	1672(ra) # 800061a8 <dirlink>
    80003b28:	02054863          	bltz	a0,80003b58 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80003b2c:	004a2603          	lw	a2,4(s4)
    80003b30:	fb040593          	add	a1,s0,-80
    80003b34:	8526                	mv	a0,s1
    80003b36:	00002097          	auipc	ra,0x2
    80003b3a:	672080e7          	jalr	1650(ra) # 800061a8 <dirlink>
    80003b3e:	00054d63          	bltz	a0,80003b58 <create+0x15a>
    dp->nlink++;  // for ".."
    80003b42:	04a4d783          	lhu	a5,74(s1)
    80003b46:	2785                	addw	a5,a5,1
    80003b48:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80003b4c:	8526                	mv	a0,s1
    80003b4e:	00002097          	auipc	ra,0x2
    80003b52:	e9c080e7          	jalr	-356(ra) # 800059ea <iupdate>
    80003b56:	b761                	j	80003ade <create+0xe0>
  ip->nlink = 0;
    80003b58:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80003b5c:	8552                	mv	a0,s4
    80003b5e:	00002097          	auipc	ra,0x2
    80003b62:	e8c080e7          	jalr	-372(ra) # 800059ea <iupdate>
  iunlockput(ip);
    80003b66:	8552                	mv	a0,s4
    80003b68:	00002097          	auipc	ra,0x2
    80003b6c:	1b0080e7          	jalr	432(ra) # 80005d18 <iunlockput>
  iunlockput(dp);
    80003b70:	8526                	mv	a0,s1
    80003b72:	00002097          	auipc	ra,0x2
    80003b76:	1a6080e7          	jalr	422(ra) # 80005d18 <iunlockput>
  return 0;
    80003b7a:	bddd                	j	80003a70 <create+0x72>
    return 0;
    80003b7c:	8aaa                	mv	s5,a0
    80003b7e:	bdcd                	j	80003a70 <create+0x72>

0000000080003b80 <sys_dup>:
{
    80003b80:	7179                	add	sp,sp,-48
    80003b82:	f406                	sd	ra,40(sp)
    80003b84:	f022                	sd	s0,32(sp)
    80003b86:	ec26                	sd	s1,24(sp)
    80003b88:	e84a                	sd	s2,16(sp)
    80003b8a:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80003b8c:	fd840613          	add	a2,s0,-40
    80003b90:	4581                	li	a1,0
    80003b92:	4501                	li	a0,0
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	dc8080e7          	jalr	-568(ra) # 8000395c <argfd>
    return -1;
    80003b9c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80003b9e:	02054363          	bltz	a0,80003bc4 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80003ba2:	fd843903          	ld	s2,-40(s0)
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	e14080e7          	jalr	-492(ra) # 800039bc <fdalloc>
    80003bb0:	84aa                	mv	s1,a0
    return -1;
    80003bb2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80003bb4:	00054863          	bltz	a0,80003bc4 <sys_dup+0x44>
  filedup(f);
    80003bb8:	854a                	mv	a0,s2
    80003bba:	00001097          	auipc	ra,0x1
    80003bbe:	1f2080e7          	jalr	498(ra) # 80004dac <filedup>
  return fd;
    80003bc2:	87a6                	mv	a5,s1
}
    80003bc4:	853e                	mv	a0,a5
    80003bc6:	70a2                	ld	ra,40(sp)
    80003bc8:	7402                	ld	s0,32(sp)
    80003bca:	64e2                	ld	s1,24(sp)
    80003bcc:	6942                	ld	s2,16(sp)
    80003bce:	6145                	add	sp,sp,48
    80003bd0:	8082                	ret

0000000080003bd2 <sys_read>:
{
    80003bd2:	7179                	add	sp,sp,-48
    80003bd4:	f406                	sd	ra,40(sp)
    80003bd6:	f022                	sd	s0,32(sp)
    80003bd8:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80003bda:	fd840593          	add	a1,s0,-40
    80003bde:	4505                	li	a0,1
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	a54080e7          	jalr	-1452(ra) # 80003634 <arg_uint64>
  argint(2, &n);
    80003be8:	fe440593          	add	a1,s0,-28
    80003bec:	4509                	li	a0,2
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	a46080e7          	jalr	-1466(ra) # 80003634 <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    80003bf6:	fe840613          	add	a2,s0,-24
    80003bfa:	4581                	li	a1,0
    80003bfc:	4501                	li	a0,0
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	d5e080e7          	jalr	-674(ra) # 8000395c <argfd>
    80003c06:	87aa                	mv	a5,a0
    return -1;
    80003c08:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80003c0a:	0007cc63          	bltz	a5,80003c22 <sys_read+0x50>
  return fileread(f, p, n);
    80003c0e:	fe442603          	lw	a2,-28(s0)
    80003c12:	fd843583          	ld	a1,-40(s0)
    80003c16:	fe843503          	ld	a0,-24(s0)
    80003c1a:	00001097          	auipc	ra,0x1
    80003c1e:	31e080e7          	jalr	798(ra) # 80004f38 <fileread>
}
    80003c22:	70a2                	ld	ra,40(sp)
    80003c24:	7402                	ld	s0,32(sp)
    80003c26:	6145                	add	sp,sp,48
    80003c28:	8082                	ret

0000000080003c2a <sys_write>:
{
    80003c2a:	7179                	add	sp,sp,-48
    80003c2c:	f406                	sd	ra,40(sp)
    80003c2e:	f022                	sd	s0,32(sp)
    80003c30:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80003c32:	fd840593          	add	a1,s0,-40
    80003c36:	4505                	li	a0,1
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	9fc080e7          	jalr	-1540(ra) # 80003634 <arg_uint64>
  argint(2, &n);
    80003c40:	fe440593          	add	a1,s0,-28
    80003c44:	4509                	li	a0,2
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	9ee080e7          	jalr	-1554(ra) # 80003634 <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    80003c4e:	fe840613          	add	a2,s0,-24
    80003c52:	4581                	li	a1,0
    80003c54:	4501                	li	a0,0
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	d06080e7          	jalr	-762(ra) # 8000395c <argfd>
    80003c5e:	87aa                	mv	a5,a0
    return -1;
    80003c60:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80003c62:	0007cc63          	bltz	a5,80003c7a <sys_write+0x50>
  return filewrite(f, p, n);
    80003c66:	fe442603          	lw	a2,-28(s0)
    80003c6a:	fd843583          	ld	a1,-40(s0)
    80003c6e:	fe843503          	ld	a0,-24(s0)
    80003c72:	00001097          	auipc	ra,0x1
    80003c76:	388080e7          	jalr	904(ra) # 80004ffa <filewrite>
}
    80003c7a:	70a2                	ld	ra,40(sp)
    80003c7c:	7402                	ld	s0,32(sp)
    80003c7e:	6145                	add	sp,sp,48
    80003c80:	8082                	ret

0000000080003c82 <sys_close>:
{
    80003c82:	1101                	add	sp,sp,-32
    80003c84:	ec06                	sd	ra,24(sp)
    80003c86:	e822                	sd	s0,16(sp)
    80003c88:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80003c8a:	fe040613          	add	a2,s0,-32
    80003c8e:	fec40593          	add	a1,s0,-20
    80003c92:	4501                	li	a0,0
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	cc8080e7          	jalr	-824(ra) # 8000395c <argfd>
    return -1;
    80003c9c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80003c9e:	02054463          	bltz	a0,80003cc6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80003ca2:	ffffe097          	auipc	ra,0xffffe
    80003ca6:	46c080e7          	jalr	1132(ra) # 8000210e <myproc>
    80003caa:	fec42783          	lw	a5,-20(s0)
    80003cae:	07b1                	add	a5,a5,12
    80003cb0:	078e                	sll	a5,a5,0x3
    80003cb2:	953e                	add	a0,a0,a5
    80003cb4:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80003cb8:	fe043503          	ld	a0,-32(s0)
    80003cbc:	00001097          	auipc	ra,0x1
    80003cc0:	142080e7          	jalr	322(ra) # 80004dfe <fileclose>
  return 0;
    80003cc4:	4781                	li	a5,0
}
    80003cc6:	853e                	mv	a0,a5
    80003cc8:	60e2                	ld	ra,24(sp)
    80003cca:	6442                	ld	s0,16(sp)
    80003ccc:	6105                	add	sp,sp,32
    80003cce:	8082                	ret

0000000080003cd0 <sys_fstat>:
{
    80003cd0:	1101                	add	sp,sp,-32
    80003cd2:	ec06                	sd	ra,24(sp)
    80003cd4:	e822                	sd	s0,16(sp)
    80003cd6:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80003cd8:	fe040593          	add	a1,s0,-32
    80003cdc:	4505                	li	a0,1
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	956080e7          	jalr	-1706(ra) # 80003634 <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    80003ce6:	fe840613          	add	a2,s0,-24
    80003cea:	4581                	li	a1,0
    80003cec:	4501                	li	a0,0
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	c6e080e7          	jalr	-914(ra) # 8000395c <argfd>
    80003cf6:	87aa                	mv	a5,a0
    return -1;
    80003cf8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80003cfa:	0007ca63          	bltz	a5,80003d0e <sys_fstat+0x3e>
  return filestat(f, st);
    80003cfe:	fe043583          	ld	a1,-32(s0)
    80003d02:	fe843503          	ld	a0,-24(s0)
    80003d06:	00001097          	auipc	ra,0x1
    80003d0a:	1c0080e7          	jalr	448(ra) # 80004ec6 <filestat>
}
    80003d0e:	60e2                	ld	ra,24(sp)
    80003d10:	6442                	ld	s0,16(sp)
    80003d12:	6105                	add	sp,sp,32
    80003d14:	8082                	ret

0000000080003d16 <sys_link>:
{
    80003d16:	7169                	add	sp,sp,-304
    80003d18:	f606                	sd	ra,296(sp)
    80003d1a:	f222                	sd	s0,288(sp)
    80003d1c:	ee26                	sd	s1,280(sp)
    80003d1e:	ea4a                	sd	s2,272(sp)
    80003d20:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80003d22:	08000613          	li	a2,128
    80003d26:	ed040593          	add	a1,s0,-304
    80003d2a:	4501                	li	a0,0
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	9c4080e7          	jalr	-1596(ra) # 800036f0 <argstr>
    return -1;
    80003d34:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80003d36:	10054e63          	bltz	a0,80003e52 <sys_link+0x13c>
    80003d3a:	08000613          	li	a2,128
    80003d3e:	f5040593          	add	a1,s0,-176
    80003d42:	4505                	li	a0,1
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	9ac080e7          	jalr	-1620(ra) # 800036f0 <argstr>
    return -1;
    80003d4c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80003d4e:	10054263          	bltz	a0,80003e52 <sys_link+0x13c>
  begin_op();
    80003d52:	00001097          	auipc	ra,0x1
    80003d56:	d12080e7          	jalr	-750(ra) # 80004a64 <begin_op>
  if((ip = namei(old)) == 0){
    80003d5a:	ed040513          	add	a0,s0,-304
    80003d5e:	00002097          	auipc	ra,0x2
    80003d62:	4fc080e7          	jalr	1276(ra) # 8000625a <namei>
    80003d66:	84aa                	mv	s1,a0
    80003d68:	c551                	beqz	a0,80003df4 <sys_link+0xde>
  ilock(ip);
    80003d6a:	00002097          	auipc	ra,0x2
    80003d6e:	d4c080e7          	jalr	-692(ra) # 80005ab6 <ilock>
  if(ip->type == T_DIR){
    80003d72:	04449703          	lh	a4,68(s1)
    80003d76:	4785                	li	a5,1
    80003d78:	08f70463          	beq	a4,a5,80003e00 <sys_link+0xea>
  ip->nlink++;
    80003d7c:	04a4d783          	lhu	a5,74(s1)
    80003d80:	2785                	addw	a5,a5,1
    80003d82:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80003d86:	8526                	mv	a0,s1
    80003d88:	00002097          	auipc	ra,0x2
    80003d8c:	c62080e7          	jalr	-926(ra) # 800059ea <iupdate>
  iunlock(ip);
    80003d90:	8526                	mv	a0,s1
    80003d92:	00002097          	auipc	ra,0x2
    80003d96:	de6080e7          	jalr	-538(ra) # 80005b78 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80003d9a:	fd040593          	add	a1,s0,-48
    80003d9e:	f5040513          	add	a0,s0,-176
    80003da2:	00002097          	auipc	ra,0x2
    80003da6:	4d6080e7          	jalr	1238(ra) # 80006278 <nameiparent>
    80003daa:	892a                	mv	s2,a0
    80003dac:	c935                	beqz	a0,80003e20 <sys_link+0x10a>
  ilock(dp);
    80003dae:	00002097          	auipc	ra,0x2
    80003db2:	d08080e7          	jalr	-760(ra) # 80005ab6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80003db6:	00092703          	lw	a4,0(s2)
    80003dba:	409c                	lw	a5,0(s1)
    80003dbc:	04f71d63          	bne	a4,a5,80003e16 <sys_link+0x100>
    80003dc0:	40d0                	lw	a2,4(s1)
    80003dc2:	fd040593          	add	a1,s0,-48
    80003dc6:	854a                	mv	a0,s2
    80003dc8:	00002097          	auipc	ra,0x2
    80003dcc:	3e0080e7          	jalr	992(ra) # 800061a8 <dirlink>
    80003dd0:	04054363          	bltz	a0,80003e16 <sys_link+0x100>
  iunlockput(dp);
    80003dd4:	854a                	mv	a0,s2
    80003dd6:	00002097          	auipc	ra,0x2
    80003dda:	f42080e7          	jalr	-190(ra) # 80005d18 <iunlockput>
  iput(ip);
    80003dde:	8526                	mv	a0,s1
    80003de0:	00002097          	auipc	ra,0x2
    80003de4:	e90080e7          	jalr	-368(ra) # 80005c70 <iput>
  end_op();
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	cf6080e7          	jalr	-778(ra) # 80004ade <end_op>
  return 0;
    80003df0:	4781                	li	a5,0
    80003df2:	a085                	j	80003e52 <sys_link+0x13c>
    end_op();
    80003df4:	00001097          	auipc	ra,0x1
    80003df8:	cea080e7          	jalr	-790(ra) # 80004ade <end_op>
    return -1;
    80003dfc:	57fd                	li	a5,-1
    80003dfe:	a891                	j	80003e52 <sys_link+0x13c>
    iunlockput(ip);
    80003e00:	8526                	mv	a0,s1
    80003e02:	00002097          	auipc	ra,0x2
    80003e06:	f16080e7          	jalr	-234(ra) # 80005d18 <iunlockput>
    end_op();
    80003e0a:	00001097          	auipc	ra,0x1
    80003e0e:	cd4080e7          	jalr	-812(ra) # 80004ade <end_op>
    return -1;
    80003e12:	57fd                	li	a5,-1
    80003e14:	a83d                	j	80003e52 <sys_link+0x13c>
    iunlockput(dp);
    80003e16:	854a                	mv	a0,s2
    80003e18:	00002097          	auipc	ra,0x2
    80003e1c:	f00080e7          	jalr	-256(ra) # 80005d18 <iunlockput>
  ilock(ip);
    80003e20:	8526                	mv	a0,s1
    80003e22:	00002097          	auipc	ra,0x2
    80003e26:	c94080e7          	jalr	-876(ra) # 80005ab6 <ilock>
  ip->nlink--;
    80003e2a:	04a4d783          	lhu	a5,74(s1)
    80003e2e:	37fd                	addw	a5,a5,-1
    80003e30:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80003e34:	8526                	mv	a0,s1
    80003e36:	00002097          	auipc	ra,0x2
    80003e3a:	bb4080e7          	jalr	-1100(ra) # 800059ea <iupdate>
  iunlockput(ip);
    80003e3e:	8526                	mv	a0,s1
    80003e40:	00002097          	auipc	ra,0x2
    80003e44:	ed8080e7          	jalr	-296(ra) # 80005d18 <iunlockput>
  end_op();
    80003e48:	00001097          	auipc	ra,0x1
    80003e4c:	c96080e7          	jalr	-874(ra) # 80004ade <end_op>
  return -1;
    80003e50:	57fd                	li	a5,-1
}
    80003e52:	853e                	mv	a0,a5
    80003e54:	70b2                	ld	ra,296(sp)
    80003e56:	7412                	ld	s0,288(sp)
    80003e58:	64f2                	ld	s1,280(sp)
    80003e5a:	6952                	ld	s2,272(sp)
    80003e5c:	6155                	add	sp,sp,304
    80003e5e:	8082                	ret

0000000080003e60 <sys_unlink>:
{
    80003e60:	7151                	add	sp,sp,-240
    80003e62:	f586                	sd	ra,232(sp)
    80003e64:	f1a2                	sd	s0,224(sp)
    80003e66:	eda6                	sd	s1,216(sp)
    80003e68:	e9ca                	sd	s2,208(sp)
    80003e6a:	e5ce                	sd	s3,200(sp)
    80003e6c:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80003e6e:	08000613          	li	a2,128
    80003e72:	f3040593          	add	a1,s0,-208
    80003e76:	4501                	li	a0,0
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	878080e7          	jalr	-1928(ra) # 800036f0 <argstr>
    80003e80:	18054163          	bltz	a0,80004002 <sys_unlink+0x1a2>
  begin_op();
    80003e84:	00001097          	auipc	ra,0x1
    80003e88:	be0080e7          	jalr	-1056(ra) # 80004a64 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80003e8c:	fb040593          	add	a1,s0,-80
    80003e90:	f3040513          	add	a0,s0,-208
    80003e94:	00002097          	auipc	ra,0x2
    80003e98:	3e4080e7          	jalr	996(ra) # 80006278 <nameiparent>
    80003e9c:	84aa                	mv	s1,a0
    80003e9e:	c979                	beqz	a0,80003f74 <sys_unlink+0x114>
  ilock(dp);
    80003ea0:	00002097          	auipc	ra,0x2
    80003ea4:	c16080e7          	jalr	-1002(ra) # 80005ab6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80003ea8:	00005597          	auipc	a1,0x5
    80003eac:	a0858593          	add	a1,a1,-1528 # 800088b0 <syscalls+0xd8>
    80003eb0:	fb040513          	add	a0,s0,-80
    80003eb4:	00002097          	auipc	ra,0x2
    80003eb8:	0cc080e7          	jalr	204(ra) # 80005f80 <namecmp>
    80003ebc:	14050a63          	beqz	a0,80004010 <sys_unlink+0x1b0>
    80003ec0:	00005597          	auipc	a1,0x5
    80003ec4:	9f858593          	add	a1,a1,-1544 # 800088b8 <syscalls+0xe0>
    80003ec8:	fb040513          	add	a0,s0,-80
    80003ecc:	00002097          	auipc	ra,0x2
    80003ed0:	0b4080e7          	jalr	180(ra) # 80005f80 <namecmp>
    80003ed4:	12050e63          	beqz	a0,80004010 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80003ed8:	f2c40613          	add	a2,s0,-212
    80003edc:	fb040593          	add	a1,s0,-80
    80003ee0:	8526                	mv	a0,s1
    80003ee2:	00002097          	auipc	ra,0x2
    80003ee6:	0b8080e7          	jalr	184(ra) # 80005f9a <dirlookup>
    80003eea:	892a                	mv	s2,a0
    80003eec:	12050263          	beqz	a0,80004010 <sys_unlink+0x1b0>
  ilock(ip);
    80003ef0:	00002097          	auipc	ra,0x2
    80003ef4:	bc6080e7          	jalr	-1082(ra) # 80005ab6 <ilock>
  if(ip->nlink < 1)
    80003ef8:	04a91783          	lh	a5,74(s2)
    80003efc:	08f05263          	blez	a5,80003f80 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80003f00:	04491703          	lh	a4,68(s2)
    80003f04:	4785                	li	a5,1
    80003f06:	08f70563          	beq	a4,a5,80003f90 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80003f0a:	4641                	li	a2,16
    80003f0c:	4581                	li	a1,0
    80003f0e:	fc040513          	add	a0,s0,-64
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	086080e7          	jalr	134(ra) # 80000f98 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f1a:	4741                	li	a4,16
    80003f1c:	f2c42683          	lw	a3,-212(s0)
    80003f20:	fc040613          	add	a2,s0,-64
    80003f24:	4581                	li	a1,0
    80003f26:	8526                	mv	a0,s1
    80003f28:	00002097          	auipc	ra,0x2
    80003f2c:	f3a080e7          	jalr	-198(ra) # 80005e62 <writei>
    80003f30:	47c1                	li	a5,16
    80003f32:	0af51563          	bne	a0,a5,80003fdc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80003f36:	04491703          	lh	a4,68(s2)
    80003f3a:	4785                	li	a5,1
    80003f3c:	0af70863          	beq	a4,a5,80003fec <sys_unlink+0x18c>
  iunlockput(dp);
    80003f40:	8526                	mv	a0,s1
    80003f42:	00002097          	auipc	ra,0x2
    80003f46:	dd6080e7          	jalr	-554(ra) # 80005d18 <iunlockput>
  ip->nlink--;
    80003f4a:	04a95783          	lhu	a5,74(s2)
    80003f4e:	37fd                	addw	a5,a5,-1
    80003f50:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80003f54:	854a                	mv	a0,s2
    80003f56:	00002097          	auipc	ra,0x2
    80003f5a:	a94080e7          	jalr	-1388(ra) # 800059ea <iupdate>
  iunlockput(ip);
    80003f5e:	854a                	mv	a0,s2
    80003f60:	00002097          	auipc	ra,0x2
    80003f64:	db8080e7          	jalr	-584(ra) # 80005d18 <iunlockput>
  end_op();
    80003f68:	00001097          	auipc	ra,0x1
    80003f6c:	b76080e7          	jalr	-1162(ra) # 80004ade <end_op>
  return 0;
    80003f70:	4501                	li	a0,0
    80003f72:	a84d                	j	80004024 <sys_unlink+0x1c4>
    end_op();
    80003f74:	00001097          	auipc	ra,0x1
    80003f78:	b6a080e7          	jalr	-1174(ra) # 80004ade <end_op>
    return -1;
    80003f7c:	557d                	li	a0,-1
    80003f7e:	a05d                	j	80004024 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80003f80:	00005517          	auipc	a0,0x5
    80003f84:	94050513          	add	a0,a0,-1728 # 800088c0 <syscalls+0xe8>
    80003f88:	ffffd097          	auipc	ra,0xffffd
    80003f8c:	258080e7          	jalr	600(ra) # 800011e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80003f90:	04c92703          	lw	a4,76(s2)
    80003f94:	02000793          	li	a5,32
    80003f98:	f6e7f9e3          	bgeu	a5,a4,80003f0a <sys_unlink+0xaa>
    80003f9c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa0:	4741                	li	a4,16
    80003fa2:	86ce                	mv	a3,s3
    80003fa4:	f1840613          	add	a2,s0,-232
    80003fa8:	4581                	li	a1,0
    80003faa:	854a                	mv	a0,s2
    80003fac:	00002097          	auipc	ra,0x2
    80003fb0:	dbe080e7          	jalr	-578(ra) # 80005d6a <readi>
    80003fb4:	47c1                	li	a5,16
    80003fb6:	00f51b63          	bne	a0,a5,80003fcc <sys_unlink+0x16c>
    if(de.inum != 0)
    80003fba:	f1845783          	lhu	a5,-232(s0)
    80003fbe:	e7a1                	bnez	a5,80004006 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80003fc0:	29c1                	addw	s3,s3,16
    80003fc2:	04c92783          	lw	a5,76(s2)
    80003fc6:	fcf9ede3          	bltu	s3,a5,80003fa0 <sys_unlink+0x140>
    80003fca:	b781                	j	80003f0a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80003fcc:	00005517          	auipc	a0,0x5
    80003fd0:	90c50513          	add	a0,a0,-1780 # 800088d8 <syscalls+0x100>
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	20c080e7          	jalr	524(ra) # 800011e0 <panic>
    panic("unlink: writei");
    80003fdc:	00005517          	auipc	a0,0x5
    80003fe0:	91450513          	add	a0,a0,-1772 # 800088f0 <syscalls+0x118>
    80003fe4:	ffffd097          	auipc	ra,0xffffd
    80003fe8:	1fc080e7          	jalr	508(ra) # 800011e0 <panic>
    dp->nlink--;
    80003fec:	04a4d783          	lhu	a5,74(s1)
    80003ff0:	37fd                	addw	a5,a5,-1
    80003ff2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	00002097          	auipc	ra,0x2
    80003ffc:	9f2080e7          	jalr	-1550(ra) # 800059ea <iupdate>
    80004000:	b781                	j	80003f40 <sys_unlink+0xe0>
    return -1;
    80004002:	557d                	li	a0,-1
    80004004:	a005                	j	80004024 <sys_unlink+0x1c4>
    iunlockput(ip);
    80004006:	854a                	mv	a0,s2
    80004008:	00002097          	auipc	ra,0x2
    8000400c:	d10080e7          	jalr	-752(ra) # 80005d18 <iunlockput>
  iunlockput(dp);
    80004010:	8526                	mv	a0,s1
    80004012:	00002097          	auipc	ra,0x2
    80004016:	d06080e7          	jalr	-762(ra) # 80005d18 <iunlockput>
  end_op();
    8000401a:	00001097          	auipc	ra,0x1
    8000401e:	ac4080e7          	jalr	-1340(ra) # 80004ade <end_op>
  return -1;
    80004022:	557d                	li	a0,-1
}
    80004024:	70ae                	ld	ra,232(sp)
    80004026:	740e                	ld	s0,224(sp)
    80004028:	64ee                	ld	s1,216(sp)
    8000402a:	694e                	ld	s2,208(sp)
    8000402c:	69ae                	ld	s3,200(sp)
    8000402e:	616d                	add	sp,sp,240
    80004030:	8082                	ret

0000000080004032 <sys_open>:

uint64
sys_open(void)
{
    80004032:	7131                	add	sp,sp,-192
    80004034:	fd06                	sd	ra,184(sp)
    80004036:	f922                	sd	s0,176(sp)
    80004038:	f526                	sd	s1,168(sp)
    8000403a:	f14a                	sd	s2,160(sp)
    8000403c:	ed4e                	sd	s3,152(sp)
    8000403e:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004040:	f4c40593          	add	a1,s0,-180
    80004044:	4505                	li	a0,1
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	5ee080e7          	jalr	1518(ra) # 80003634 <arg_uint64>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000404e:	08000613          	li	a2,128
    80004052:	f5040593          	add	a1,s0,-176
    80004056:	4501                	li	a0,0
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	698080e7          	jalr	1688(ra) # 800036f0 <argstr>
    80004060:	87aa                	mv	a5,a0
    return -1;
    80004062:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004064:	0a07c863          	bltz	a5,80004114 <sys_open+0xe2>

  begin_op();
    80004068:	00001097          	auipc	ra,0x1
    8000406c:	9fc080e7          	jalr	-1540(ra) # 80004a64 <begin_op>

  if(omode & O_CREATE){
    80004070:	f4c42783          	lw	a5,-180(s0)
    80004074:	2007f793          	and	a5,a5,512
    80004078:	cbdd                	beqz	a5,8000412e <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    8000407a:	4681                	li	a3,0
    8000407c:	4601                	li	a2,0
    8000407e:	4589                	li	a1,2
    80004080:	f5040513          	add	a0,s0,-176
    80004084:	00000097          	auipc	ra,0x0
    80004088:	97a080e7          	jalr	-1670(ra) # 800039fe <create>
    8000408c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000408e:	c951                	beqz	a0,80004122 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004090:	04449703          	lh	a4,68(s1)
    80004094:	478d                	li	a5,3
    80004096:	00f71763          	bne	a4,a5,800040a4 <sys_open+0x72>
    8000409a:	0464d703          	lhu	a4,70(s1)
    8000409e:	47a5                	li	a5,9
    800040a0:	0ce7ec63          	bltu	a5,a4,80004178 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800040a4:	00001097          	auipc	ra,0x1
    800040a8:	c9e080e7          	jalr	-866(ra) # 80004d42 <filealloc>
    800040ac:	892a                	mv	s2,a0
    800040ae:	c56d                	beqz	a0,80004198 <sys_open+0x166>
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	90c080e7          	jalr	-1780(ra) # 800039bc <fdalloc>
    800040b8:	89aa                	mv	s3,a0
    800040ba:	0c054a63          	bltz	a0,8000418e <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800040be:	04449703          	lh	a4,68(s1)
    800040c2:	478d                	li	a5,3
    800040c4:	0ef70563          	beq	a4,a5,800041ae <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800040c8:	4789                	li	a5,2
    800040ca:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800040ce:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800040d2:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800040d6:	f4c42783          	lw	a5,-180(s0)
    800040da:	0017c713          	xor	a4,a5,1
    800040de:	8b05                	and	a4,a4,1
    800040e0:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800040e4:	0037f713          	and	a4,a5,3
    800040e8:	00e03733          	snez	a4,a4
    800040ec:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800040f0:	4007f793          	and	a5,a5,1024
    800040f4:	c791                	beqz	a5,80004100 <sys_open+0xce>
    800040f6:	04449703          	lh	a4,68(s1)
    800040fa:	4789                	li	a5,2
    800040fc:	0cf70063          	beq	a4,a5,800041bc <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80004100:	8526                	mv	a0,s1
    80004102:	00002097          	auipc	ra,0x2
    80004106:	a76080e7          	jalr	-1418(ra) # 80005b78 <iunlock>
  end_op();
    8000410a:	00001097          	auipc	ra,0x1
    8000410e:	9d4080e7          	jalr	-1580(ra) # 80004ade <end_op>

  return fd;
    80004112:	854e                	mv	a0,s3
}
    80004114:	70ea                	ld	ra,184(sp)
    80004116:	744a                	ld	s0,176(sp)
    80004118:	74aa                	ld	s1,168(sp)
    8000411a:	790a                	ld	s2,160(sp)
    8000411c:	69ea                	ld	s3,152(sp)
    8000411e:	6129                	add	sp,sp,192
    80004120:	8082                	ret
      end_op();
    80004122:	00001097          	auipc	ra,0x1
    80004126:	9bc080e7          	jalr	-1604(ra) # 80004ade <end_op>
      return -1;
    8000412a:	557d                	li	a0,-1
    8000412c:	b7e5                	j	80004114 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    8000412e:	f5040513          	add	a0,s0,-176
    80004132:	00002097          	auipc	ra,0x2
    80004136:	128080e7          	jalr	296(ra) # 8000625a <namei>
    8000413a:	84aa                	mv	s1,a0
    8000413c:	c905                	beqz	a0,8000416c <sys_open+0x13a>
    ilock(ip);
    8000413e:	00002097          	auipc	ra,0x2
    80004142:	978080e7          	jalr	-1672(ra) # 80005ab6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80004146:	04449703          	lh	a4,68(s1)
    8000414a:	4785                	li	a5,1
    8000414c:	f4f712e3          	bne	a4,a5,80004090 <sys_open+0x5e>
    80004150:	f4c42783          	lw	a5,-180(s0)
    80004154:	dba1                	beqz	a5,800040a4 <sys_open+0x72>
      iunlockput(ip);
    80004156:	8526                	mv	a0,s1
    80004158:	00002097          	auipc	ra,0x2
    8000415c:	bc0080e7          	jalr	-1088(ra) # 80005d18 <iunlockput>
      end_op();
    80004160:	00001097          	auipc	ra,0x1
    80004164:	97e080e7          	jalr	-1666(ra) # 80004ade <end_op>
      return -1;
    80004168:	557d                	li	a0,-1
    8000416a:	b76d                	j	80004114 <sys_open+0xe2>
      end_op();
    8000416c:	00001097          	auipc	ra,0x1
    80004170:	972080e7          	jalr	-1678(ra) # 80004ade <end_op>
      return -1;
    80004174:	557d                	li	a0,-1
    80004176:	bf79                	j	80004114 <sys_open+0xe2>
    iunlockput(ip);
    80004178:	8526                	mv	a0,s1
    8000417a:	00002097          	auipc	ra,0x2
    8000417e:	b9e080e7          	jalr	-1122(ra) # 80005d18 <iunlockput>
    end_op();
    80004182:	00001097          	auipc	ra,0x1
    80004186:	95c080e7          	jalr	-1700(ra) # 80004ade <end_op>
    return -1;
    8000418a:	557d                	li	a0,-1
    8000418c:	b761                	j	80004114 <sys_open+0xe2>
      fileclose(f);
    8000418e:	854a                	mv	a0,s2
    80004190:	00001097          	auipc	ra,0x1
    80004194:	c6e080e7          	jalr	-914(ra) # 80004dfe <fileclose>
    iunlockput(ip);
    80004198:	8526                	mv	a0,s1
    8000419a:	00002097          	auipc	ra,0x2
    8000419e:	b7e080e7          	jalr	-1154(ra) # 80005d18 <iunlockput>
    end_op();
    800041a2:	00001097          	auipc	ra,0x1
    800041a6:	93c080e7          	jalr	-1732(ra) # 80004ade <end_op>
    return -1;
    800041aa:	557d                	li	a0,-1
    800041ac:	b7a5                	j	80004114 <sys_open+0xe2>
    f->type = FD_DEVICE;
    800041ae:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800041b2:	04649783          	lh	a5,70(s1)
    800041b6:	02f91223          	sh	a5,36(s2)
    800041ba:	bf21                	j	800040d2 <sys_open+0xa0>
    itrunc(ip);
    800041bc:	8526                	mv	a0,s1
    800041be:	00002097          	auipc	ra,0x2
    800041c2:	a06080e7          	jalr	-1530(ra) # 80005bc4 <itrunc>
    800041c6:	bf2d                	j	80004100 <sys_open+0xce>

00000000800041c8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800041c8:	7175                	add	sp,sp,-144
    800041ca:	e506                	sd	ra,136(sp)
    800041cc:	e122                	sd	s0,128(sp)
    800041ce:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800041d0:	00001097          	auipc	ra,0x1
    800041d4:	894080e7          	jalr	-1900(ra) # 80004a64 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800041d8:	08000613          	li	a2,128
    800041dc:	f7040593          	add	a1,s0,-144
    800041e0:	4501                	li	a0,0
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	50e080e7          	jalr	1294(ra) # 800036f0 <argstr>
    800041ea:	02054963          	bltz	a0,8000421c <sys_mkdir+0x54>
    800041ee:	4681                	li	a3,0
    800041f0:	4601                	li	a2,0
    800041f2:	4585                	li	a1,1
    800041f4:	f7040513          	add	a0,s0,-144
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	806080e7          	jalr	-2042(ra) # 800039fe <create>
    80004200:	cd11                	beqz	a0,8000421c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004202:	00002097          	auipc	ra,0x2
    80004206:	b16080e7          	jalr	-1258(ra) # 80005d18 <iunlockput>
  end_op();
    8000420a:	00001097          	auipc	ra,0x1
    8000420e:	8d4080e7          	jalr	-1836(ra) # 80004ade <end_op>
  return 0;
    80004212:	4501                	li	a0,0
}
    80004214:	60aa                	ld	ra,136(sp)
    80004216:	640a                	ld	s0,128(sp)
    80004218:	6149                	add	sp,sp,144
    8000421a:	8082                	ret
    end_op();
    8000421c:	00001097          	auipc	ra,0x1
    80004220:	8c2080e7          	jalr	-1854(ra) # 80004ade <end_op>
    return -1;
    80004224:	557d                	li	a0,-1
    80004226:	b7fd                	j	80004214 <sys_mkdir+0x4c>

0000000080004228 <sys_mknod>:

uint64
sys_mknod(void)
{
    80004228:	7135                	add	sp,sp,-160
    8000422a:	ed06                	sd	ra,152(sp)
    8000422c:	e922                	sd	s0,144(sp)
    8000422e:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80004230:	00001097          	auipc	ra,0x1
    80004234:	834080e7          	jalr	-1996(ra) # 80004a64 <begin_op>
  argint(1, &major);
    80004238:	f6c40593          	add	a1,s0,-148
    8000423c:	4505                	li	a0,1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	3f6080e7          	jalr	1014(ra) # 80003634 <arg_uint64>
  argint(2, &minor);
    80004246:	f6840593          	add	a1,s0,-152
    8000424a:	4509                	li	a0,2
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	3e8080e7          	jalr	1000(ra) # 80003634 <arg_uint64>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004254:	08000613          	li	a2,128
    80004258:	f7040593          	add	a1,s0,-144
    8000425c:	4501                	li	a0,0
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	492080e7          	jalr	1170(ra) # 800036f0 <argstr>
    80004266:	02054b63          	bltz	a0,8000429c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000426a:	f6841683          	lh	a3,-152(s0)
    8000426e:	f6c41603          	lh	a2,-148(s0)
    80004272:	458d                	li	a1,3
    80004274:	f7040513          	add	a0,s0,-144
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	786080e7          	jalr	1926(ra) # 800039fe <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004280:	cd11                	beqz	a0,8000429c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004282:	00002097          	auipc	ra,0x2
    80004286:	a96080e7          	jalr	-1386(ra) # 80005d18 <iunlockput>
  end_op();
    8000428a:	00001097          	auipc	ra,0x1
    8000428e:	854080e7          	jalr	-1964(ra) # 80004ade <end_op>
  return 0;
    80004292:	4501                	li	a0,0
}
    80004294:	60ea                	ld	ra,152(sp)
    80004296:	644a                	ld	s0,144(sp)
    80004298:	610d                	add	sp,sp,160
    8000429a:	8082                	ret
    end_op();
    8000429c:	00001097          	auipc	ra,0x1
    800042a0:	842080e7          	jalr	-1982(ra) # 80004ade <end_op>
    return -1;
    800042a4:	557d                	li	a0,-1
    800042a6:	b7fd                	j	80004294 <sys_mknod+0x6c>

00000000800042a8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800042a8:	7135                	add	sp,sp,-160
    800042aa:	ed06                	sd	ra,152(sp)
    800042ac:	e922                	sd	s0,144(sp)
    800042ae:	e526                	sd	s1,136(sp)
    800042b0:	e14a                	sd	s2,128(sp)
    800042b2:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800042b4:	ffffe097          	auipc	ra,0xffffe
    800042b8:	e5a080e7          	jalr	-422(ra) # 8000210e <myproc>
    800042bc:	892a                	mv	s2,a0
  
  begin_op();
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	7a6080e7          	jalr	1958(ra) # 80004a64 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800042c6:	08000613          	li	a2,128
    800042ca:	f6040593          	add	a1,s0,-160
    800042ce:	4501                	li	a0,0
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	420080e7          	jalr	1056(ra) # 800036f0 <argstr>
    800042d8:	04054b63          	bltz	a0,8000432e <sys_chdir+0x86>
    800042dc:	f6040513          	add	a0,s0,-160
    800042e0:	00002097          	auipc	ra,0x2
    800042e4:	f7a080e7          	jalr	-134(ra) # 8000625a <namei>
    800042e8:	84aa                	mv	s1,a0
    800042ea:	c131                	beqz	a0,8000432e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800042ec:	00001097          	auipc	ra,0x1
    800042f0:	7ca080e7          	jalr	1994(ra) # 80005ab6 <ilock>
  if(ip->type != T_DIR){
    800042f4:	04449703          	lh	a4,68(s1)
    800042f8:	4785                	li	a5,1
    800042fa:	04f71063          	bne	a4,a5,8000433a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800042fe:	8526                	mv	a0,s1
    80004300:	00002097          	auipc	ra,0x2
    80004304:	878080e7          	jalr	-1928(ra) # 80005b78 <iunlock>
  iput(p->cwd);
    80004308:	0e093503          	ld	a0,224(s2)
    8000430c:	00002097          	auipc	ra,0x2
    80004310:	964080e7          	jalr	-1692(ra) # 80005c70 <iput>
  end_op();
    80004314:	00000097          	auipc	ra,0x0
    80004318:	7ca080e7          	jalr	1994(ra) # 80004ade <end_op>
  p->cwd = ip;
    8000431c:	0e993023          	sd	s1,224(s2)
  return 0;
    80004320:	4501                	li	a0,0
}
    80004322:	60ea                	ld	ra,152(sp)
    80004324:	644a                	ld	s0,144(sp)
    80004326:	64aa                	ld	s1,136(sp)
    80004328:	690a                	ld	s2,128(sp)
    8000432a:	610d                	add	sp,sp,160
    8000432c:	8082                	ret
    end_op();
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	7b0080e7          	jalr	1968(ra) # 80004ade <end_op>
    return -1;
    80004336:	557d                	li	a0,-1
    80004338:	b7ed                	j	80004322 <sys_chdir+0x7a>
    iunlockput(ip);
    8000433a:	8526                	mv	a0,s1
    8000433c:	00002097          	auipc	ra,0x2
    80004340:	9dc080e7          	jalr	-1572(ra) # 80005d18 <iunlockput>
    end_op();
    80004344:	00000097          	auipc	ra,0x0
    80004348:	79a080e7          	jalr	1946(ra) # 80004ade <end_op>
    return -1;
    8000434c:	557d                	li	a0,-1
    8000434e:	bfd1                	j	80004322 <sys_chdir+0x7a>

0000000080004350 <sys_pipe>:
//   return -1;
// }

uint64
sys_pipe(void)
{
    80004350:	7139                	add	sp,sp,-64
    80004352:	fc06                	sd	ra,56(sp)
    80004354:	f822                	sd	s0,48(sp)
    80004356:	f426                	sd	s1,40(sp)
    80004358:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000435a:	ffffe097          	auipc	ra,0xffffe
    8000435e:	db4080e7          	jalr	-588(ra) # 8000210e <myproc>
    80004362:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80004364:	fd840593          	add	a1,s0,-40
    80004368:	4501                	li	a0,0
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	2ca080e7          	jalr	714(ra) # 80003634 <arg_uint64>
  if(pipealloc(&rf, &wf) < 0)
    80004372:	fc840593          	add	a1,s0,-56
    80004376:	fd040513          	add	a0,s0,-48
    8000437a:	00001097          	auipc	ra,0x1
    8000437e:	e3c080e7          	jalr	-452(ra) # 800051b6 <pipealloc>
    return -1;
    80004382:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80004384:	0c054463          	bltz	a0,8000444c <sys_pipe+0xfc>
  fd0 = -1;
    80004388:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000438c:	fd043503          	ld	a0,-48(s0)
    80004390:	fffff097          	auipc	ra,0xfffff
    80004394:	62c080e7          	jalr	1580(ra) # 800039bc <fdalloc>
    80004398:	fca42223          	sw	a0,-60(s0)
    8000439c:	08054b63          	bltz	a0,80004432 <sys_pipe+0xe2>
    800043a0:	fc843503          	ld	a0,-56(s0)
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	618080e7          	jalr	1560(ra) # 800039bc <fdalloc>
    800043ac:	fca42023          	sw	a0,-64(s0)
    800043b0:	06054863          	bltz	a0,80004420 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pgtbl, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800043b4:	4691                	li	a3,4
    800043b6:	fc440613          	add	a2,s0,-60
    800043ba:	fd843583          	ld	a1,-40(s0)
    800043be:	64a8                	ld	a0,72(s1)
    800043c0:	ffffe097          	auipc	ra,0xffffe
    800043c4:	b4c080e7          	jalr	-1204(ra) # 80001f0c <copyout>
    800043c8:	02054063          	bltz	a0,800043e8 <sys_pipe+0x98>
     copyout(p->pgtbl, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800043cc:	4691                	li	a3,4
    800043ce:	fc040613          	add	a2,s0,-64
    800043d2:	fd843583          	ld	a1,-40(s0)
    800043d6:	0591                	add	a1,a1,4
    800043d8:	64a8                	ld	a0,72(s1)
    800043da:	ffffe097          	auipc	ra,0xffffe
    800043de:	b32080e7          	jalr	-1230(ra) # 80001f0c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800043e2:	4781                	li	a5,0
  if(copyout(p->pgtbl, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800043e4:	06055463          	bgez	a0,8000444c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800043e8:	fc442783          	lw	a5,-60(s0)
    800043ec:	07b1                	add	a5,a5,12
    800043ee:	078e                	sll	a5,a5,0x3
    800043f0:	97a6                	add	a5,a5,s1
    800043f2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800043f6:	fc042783          	lw	a5,-64(s0)
    800043fa:	07b1                	add	a5,a5,12
    800043fc:	078e                	sll	a5,a5,0x3
    800043fe:	94be                	add	s1,s1,a5
    80004400:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80004404:	fd043503          	ld	a0,-48(s0)
    80004408:	00001097          	auipc	ra,0x1
    8000440c:	9f6080e7          	jalr	-1546(ra) # 80004dfe <fileclose>
    fileclose(wf);
    80004410:	fc843503          	ld	a0,-56(s0)
    80004414:	00001097          	auipc	ra,0x1
    80004418:	9ea080e7          	jalr	-1558(ra) # 80004dfe <fileclose>
    return -1;
    8000441c:	57fd                	li	a5,-1
    8000441e:	a03d                	j	8000444c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80004420:	fc442783          	lw	a5,-60(s0)
    80004424:	0007c763          	bltz	a5,80004432 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80004428:	07b1                	add	a5,a5,12
    8000442a:	078e                	sll	a5,a5,0x3
    8000442c:	97a6                	add	a5,a5,s1
    8000442e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80004432:	fd043503          	ld	a0,-48(s0)
    80004436:	00001097          	auipc	ra,0x1
    8000443a:	9c8080e7          	jalr	-1592(ra) # 80004dfe <fileclose>
    fileclose(wf);
    8000443e:	fc843503          	ld	a0,-56(s0)
    80004442:	00001097          	auipc	ra,0x1
    80004446:	9bc080e7          	jalr	-1604(ra) # 80004dfe <fileclose>
    return -1;
    8000444a:	57fd                	li	a5,-1
}
    8000444c:	853e                	mv	a0,a5
    8000444e:	70e2                	ld	ra,56(sp)
    80004450:	7442                	ld	s0,48(sp)
    80004452:	74a2                	ld	s1,40(sp)
    80004454:	6121                	add	sp,sp,64
    80004456:	8082                	ret

0000000080004458 <sys_lseek>:
// int fd
// uint32 offset
// int flags (见LSEEK_xxx)
// 成功返回新的偏移量, 失败返回-1
uint64 sys_lseek()
{
    80004458:	1101                	add	sp,sp,-32
    8000445a:	ec06                	sd	ra,24(sp)
    8000445c:	e822                	sd	s0,16(sp)
    8000445e:	1000                	add	s0,sp,32
    struct file* file;
    uint32 offset;
    int flags;

    if(argfd(0, 0, &file) < 0)
    80004460:	fe840613          	add	a2,s0,-24
    80004464:	4581                	li	a1,0
    80004466:	4501                	li	a0,0
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	4f4080e7          	jalr	1268(ra) # 8000395c <argfd>
    80004470:	87aa                	mv	a5,a0
        return -1;
    80004472:	557d                	li	a0,-1
    if(argfd(0, 0, &file) < 0)
    80004474:	0207cc63          	bltz	a5,800044ac <sys_lseek+0x54>
    arg_uint32(1, &offset);
    80004478:	fe440593          	add	a1,s0,-28
    8000447c:	4505                	li	a0,1
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	196080e7          	jalr	406(ra) # 80003614 <arg_uint32>
    arg_uint32(2, (uint32*)(&flags));
    80004486:	fe040593          	add	a1,s0,-32
    8000448a:	4509                	li	a0,2
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	188080e7          	jalr	392(ra) # 80003614 <arg_uint32>

    return file_lseek(file, offset, flags);
    80004494:	fe042603          	lw	a2,-32(s0)
    80004498:	fe442583          	lw	a1,-28(s0)
    8000449c:	fe843503          	ld	a0,-24(s0)
    800044a0:	00001097          	auipc	ra,0x1
    800044a4:	c8a080e7          	jalr	-886(ra) # 8000512a <file_lseek>
    800044a8:	1502                	sll	a0,a0,0x20
    800044aa:	9101                	srl	a0,a0,0x20
}
    800044ac:	60e2                	ld	ra,24(sp)
    800044ae:	6442                	ld	s0,16(sp)
    800044b0:	6105                	add	sp,sp,32
    800044b2:	8082                	ret

00000000800044b4 <sys_alloc_block>:
//     inode_unlock(file->ip);

//     return len;
// }

uint64 sys_alloc_block(void) {
    800044b4:	1101                	add	sp,sp,-32
    800044b6:	ec06                	sd	ra,24(sp)
    800044b8:	e822                	sd	s0,16(sp)
    800044ba:	e426                	sd	s1,8(sp)
    800044bc:	e04a                	sd	s2,0(sp)
    800044be:	1000                	add	s0,sp,32
    begin_op();
    800044c0:	00000097          	auipc	ra,0x0
    800044c4:	5a4080e7          	jalr	1444(ra) # 80004a64 <begin_op>
    
    // 使用根目录而不是当前目录
    struct inode *root = namei("/");
    800044c8:	00004517          	auipc	a0,0x4
    800044cc:	04850513          	add	a0,a0,72 # 80008510 <digits+0x320>
    800044d0:	00002097          	auipc	ra,0x2
    800044d4:	d8a080e7          	jalr	-630(ra) # 8000625a <namei>
    if(root == 0) {
    800044d8:	c921                	beqz	a0,80004528 <sys_alloc_block+0x74>
    800044da:	84aa                	mv	s1,a0
        end_op();
        return -1;
    }
    
    ilock(root);  // 加锁
    800044dc:	00001097          	auipc	ra,0x1
    800044e0:	5da080e7          	jalr	1498(ra) # 80005ab6 <ilock>
    
    uint bn = balloc(root->dev);
    800044e4:	4088                	lw	a0,0(s1)
    800044e6:	00001097          	auipc	ra,0x1
    800044ea:	140080e7          	jalr	320(ra) # 80005626 <balloc>
    800044ee:	0005091b          	sext.w	s2,a0
    printf(COLOR_GREEN "sys_alloc_block: allocated block %d\n" COLOR_RESET, bn);
    800044f2:	85ca                	mv	a1,s2
    800044f4:	00004517          	auipc	a0,0x4
    800044f8:	40c50513          	add	a0,a0,1036 # 80008900 <syscalls+0x128>
    800044fc:	ffffd097          	auipc	ra,0xffffd
    80004500:	d2e080e7          	jalr	-722(ra) # 8000122a <printf>
    
    iunlockput(root);
    80004504:	8526                	mv	a0,s1
    80004506:	00002097          	auipc	ra,0x2
    8000450a:	812080e7          	jalr	-2030(ra) # 80005d18 <iunlockput>
    end_op();
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	5d0080e7          	jalr	1488(ra) # 80004ade <end_op>
    return bn;
    80004516:	02091513          	sll	a0,s2,0x20
    8000451a:	9101                	srl	a0,a0,0x20
}
    8000451c:	60e2                	ld	ra,24(sp)
    8000451e:	6442                	ld	s0,16(sp)
    80004520:	64a2                	ld	s1,8(sp)
    80004522:	6902                	ld	s2,0(sp)
    80004524:	6105                	add	sp,sp,32
    80004526:	8082                	ret
        end_op();
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	5b6080e7          	jalr	1462(ra) # 80004ade <end_op>
        return -1;
    80004530:	557d                	li	a0,-1
    80004532:	b7ed                	j	8000451c <sys_alloc_block+0x68>

0000000080004534 <sys_free_block>:

// 释放一个数据块
uint64 sys_free_block(void) {
    80004534:	7179                	add	sp,sp,-48
    80004536:	f406                	sd	ra,40(sp)
    80004538:	f022                	sd	s0,32(sp)
    8000453a:	ec26                	sd	s1,24(sp)
    8000453c:	1800                	add	s0,sp,48
    uint bn;
    
    // 检查参数
    argint(0, (int*)&bn) ;
    8000453e:	fdc40593          	add	a1,s0,-36
    80004542:	4501                	li	a0,0
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	0f0080e7          	jalr	240(ra) # 80003634 <arg_uint64>
    
    printf(COLOR_GREEN "sys_free_block: freeing block %d\n" COLOR_RESET , bn);
    8000454c:	fdc42583          	lw	a1,-36(s0)
    80004550:	00004517          	auipc	a0,0x4
    80004554:	3e050513          	add	a0,a0,992 # 80008930 <syscalls+0x158>
    80004558:	ffffd097          	auipc	ra,0xffffd
    8000455c:	cd2080e7          	jalr	-814(ra) # 8000122a <printf>
    
    begin_op();
    80004560:	00000097          	auipc	ra,0x0
    80004564:	504080e7          	jalr	1284(ra) # 80004a64 <begin_op>
    
    // 使用根目录
    struct inode *root = namei("/");
    80004568:	00004517          	auipc	a0,0x4
    8000456c:	fa850513          	add	a0,a0,-88 # 80008510 <digits+0x320>
    80004570:	00002097          	auipc	ra,0x2
    80004574:	cea080e7          	jalr	-790(ra) # 8000625a <namei>
    if(root == 0) {
    80004578:	cd05                	beqz	a0,800045b0 <sys_free_block+0x7c>
    8000457a:	84aa                	mv	s1,a0
        end_op();
        return -1;
    }
    
    // 锁定根目录
    ilock(root);
    8000457c:	00001097          	auipc	ra,0x1
    80004580:	53a080e7          	jalr	1338(ra) # 80005ab6 <ilock>
    
    // 释放块
    bfree(root->dev, bn);
    80004584:	fdc42583          	lw	a1,-36(s0)
    80004588:	4088                	lw	a0,0(s1)
    8000458a:	00001097          	auipc	ra,0x1
    8000458e:	2b8080e7          	jalr	696(ra) # 80005842 <bfree>
    
    // 解锁
    iunlockput(root);
    80004592:	8526                	mv	a0,s1
    80004594:	00001097          	auipc	ra,0x1
    80004598:	784080e7          	jalr	1924(ra) # 80005d18 <iunlockput>
    
    end_op();
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	542080e7          	jalr	1346(ra) # 80004ade <end_op>
    
    return 0;
    800045a4:	4501                	li	a0,0
}
    800045a6:	70a2                	ld	ra,40(sp)
    800045a8:	7402                	ld	s0,32(sp)
    800045aa:	64e2                	ld	s1,24(sp)
    800045ac:	6145                	add	sp,sp,48
    800045ae:	8082                	ret
        printf(COLOR_RED "sys_free_block: root not found\n" COLOR_RESET);
    800045b0:	00004517          	auipc	a0,0x4
    800045b4:	3b050513          	add	a0,a0,944 # 80008960 <syscalls+0x188>
    800045b8:	ffffd097          	auipc	ra,0xffffd
    800045bc:	c72080e7          	jalr	-910(ra) # 8000122a <printf>
        end_op();
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	51e080e7          	jalr	1310(ra) # 80004ade <end_op>
        return -1;
    800045c8:	557d                	li	a0,-1
    800045ca:	bff1                	j	800045a6 <sys_free_block+0x72>

00000000800045cc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800045cc:	7179                	add	sp,sp,-48
    800045ce:	f406                	sd	ra,40(sp)
    800045d0:	f022                	sd	s0,32(sp)
    800045d2:	ec26                	sd	s1,24(sp)
    800045d4:	e84a                	sd	s2,16(sp)
    800045d6:	e44e                	sd	s3,8(sp)
    800045d8:	e052                	sd	s4,0(sp)
    800045da:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800045dc:	00004597          	auipc	a1,0x4
    800045e0:	3b458593          	add	a1,a1,948 # 80008990 <syscalls+0x1b8>
    800045e4:	00012517          	auipc	a0,0x12
    800045e8:	7bc50513          	add	a0,a0,1980 # 80016da0 <bcache>
    800045ec:	fffff097          	auipc	ra,0xfffff
    800045f0:	8c0080e7          	jalr	-1856(ra) # 80002eac <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800045f4:	0001a797          	auipc	a5,0x1a
    800045f8:	7ac78793          	add	a5,a5,1964 # 8001eda0 <bcache+0x8000>
    800045fc:	0001b717          	auipc	a4,0x1b
    80004600:	a0c70713          	add	a4,a4,-1524 # 8001f008 <bcache+0x8268>
    80004604:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80004608:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000460c:	00012497          	auipc	s1,0x12
    80004610:	7ac48493          	add	s1,s1,1964 # 80016db8 <bcache+0x18>
    b->next = bcache.head.next;
    80004614:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80004616:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80004618:	00004a17          	auipc	s4,0x4
    8000461c:	380a0a13          	add	s4,s4,896 # 80008998 <syscalls+0x1c0>
    b->next = bcache.head.next;
    80004620:	2b893783          	ld	a5,696(s2)
    80004624:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80004626:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000462a:	85d2                	mv	a1,s4
    8000462c:	01048513          	add	a0,s1,16
    80004630:	ffffe097          	auipc	ra,0xffffe
    80004634:	752080e7          	jalr	1874(ra) # 80002d82 <initsleeplock>
    bcache.head.next->prev = b;
    80004638:	2b893783          	ld	a5,696(s2)
    8000463c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000463e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80004642:	45848493          	add	s1,s1,1112
    80004646:	fd349de3          	bne	s1,s3,80004620 <binit+0x54>
  }
}
    8000464a:	70a2                	ld	ra,40(sp)
    8000464c:	7402                	ld	s0,32(sp)
    8000464e:	64e2                	ld	s1,24(sp)
    80004650:	6942                	ld	s2,16(sp)
    80004652:	69a2                	ld	s3,8(sp)
    80004654:	6a02                	ld	s4,0(sp)
    80004656:	6145                	add	sp,sp,48
    80004658:	8082                	ret

000000008000465a <bread>:
}

/// @brief 从指定设备和块号读取一个块，并返回指向该块的缓冲区指针。
struct buf*
bread(uint dev, uint blockno)
{
    8000465a:	7179                	add	sp,sp,-48
    8000465c:	f406                	sd	ra,40(sp)
    8000465e:	f022                	sd	s0,32(sp)
    80004660:	ec26                	sd	s1,24(sp)
    80004662:	e84a                	sd	s2,16(sp)
    80004664:	e44e                	sd	s3,8(sp)
    80004666:	1800                	add	s0,sp,48
    80004668:	892a                	mv	s2,a0
    8000466a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000466c:	00012517          	auipc	a0,0x12
    80004670:	73450513          	add	a0,a0,1844 # 80016da0 <bcache>
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	8c8080e7          	jalr	-1848(ra) # 80002f3c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000467c:	0001b497          	auipc	s1,0x1b
    80004680:	9dc4b483          	ld	s1,-1572(s1) # 8001f058 <bcache+0x82b8>
    80004684:	0001b797          	auipc	a5,0x1b
    80004688:	98478793          	add	a5,a5,-1660 # 8001f008 <bcache+0x8268>
    8000468c:	02f48f63          	beq	s1,a5,800046ca <bread+0x70>
    80004690:	873e                	mv	a4,a5
    80004692:	a021                	j	8000469a <bread+0x40>
    80004694:	68a4                	ld	s1,80(s1)
    80004696:	02e48a63          	beq	s1,a4,800046ca <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000469a:	449c                	lw	a5,8(s1)
    8000469c:	ff279ce3          	bne	a5,s2,80004694 <bread+0x3a>
    800046a0:	44dc                	lw	a5,12(s1)
    800046a2:	ff3799e3          	bne	a5,s3,80004694 <bread+0x3a>
      b->refcnt++;
    800046a6:	40bc                	lw	a5,64(s1)
    800046a8:	2785                	addw	a5,a5,1
    800046aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800046ac:	00012517          	auipc	a0,0x12
    800046b0:	6f450513          	add	a0,a0,1780 # 80016da0 <bcache>
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	93c080e7          	jalr	-1732(ra) # 80002ff0 <release>
      acquiresleep(&b->lock);
    800046bc:	01048513          	add	a0,s1,16
    800046c0:	ffffe097          	auipc	ra,0xffffe
    800046c4:	6fc080e7          	jalr	1788(ra) # 80002dbc <acquiresleep>
      return b;
    800046c8:	a8b9                	j	80004726 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800046ca:	0001b497          	auipc	s1,0x1b
    800046ce:	9864b483          	ld	s1,-1658(s1) # 8001f050 <bcache+0x82b0>
    800046d2:	0001b797          	auipc	a5,0x1b
    800046d6:	93678793          	add	a5,a5,-1738 # 8001f008 <bcache+0x8268>
    800046da:	00f48863          	beq	s1,a5,800046ea <bread+0x90>
    800046de:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800046e0:	40bc                	lw	a5,64(s1)
    800046e2:	cf81                	beqz	a5,800046fa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800046e4:	64a4                	ld	s1,72(s1)
    800046e6:	fee49de3          	bne	s1,a4,800046e0 <bread+0x86>
  panic("bget: no buffers");
    800046ea:	00004517          	auipc	a0,0x4
    800046ee:	2b650513          	add	a0,a0,694 # 800089a0 <syscalls+0x1c8>
    800046f2:	ffffd097          	auipc	ra,0xffffd
    800046f6:	aee080e7          	jalr	-1298(ra) # 800011e0 <panic>
      b->dev = dev;
    800046fa:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800046fe:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80004702:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80004706:	4785                	li	a5,1
    80004708:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000470a:	00012517          	auipc	a0,0x12
    8000470e:	69650513          	add	a0,a0,1686 # 80016da0 <bcache>
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	8de080e7          	jalr	-1826(ra) # 80002ff0 <release>
      acquiresleep(&b->lock);
    8000471a:	01048513          	add	a0,s1,16
    8000471e:	ffffe097          	auipc	ra,0xffffe
    80004722:	69e080e7          	jalr	1694(ra) # 80002dbc <acquiresleep>
  struct buf *b;
  // printf("bread: reading block %d from device %d\n", blockno, dev);
  
  b = bget(dev, blockno);
  // printf("bread: got buffer for block %d from device %d\n", blockno, dev);
  if(!b->valid) {
    80004726:	409c                	lw	a5,0(s1)
    80004728:	cb89                	beqz	a5,8000473a <bread+0xe0>
    virtio_disk_rw(b, 0);
    // printf("bread: block %d from device %d read from disk\n", blockno, dev);
    b->valid = 1;
  }
  return b;
}
    8000472a:	8526                	mv	a0,s1
    8000472c:	70a2                	ld	ra,40(sp)
    8000472e:	7402                	ld	s0,32(sp)
    80004730:	64e2                	ld	s1,24(sp)
    80004732:	6942                	ld	s2,16(sp)
    80004734:	69a2                	ld	s3,8(sp)
    80004736:	6145                	add	sp,sp,48
    80004738:	8082                	ret
    virtio_disk_rw(b, 0);
    8000473a:	4581                	li	a1,0
    8000473c:	8526                	mv	a0,s1
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	576080e7          	jalr	1398(ra) # 80000cb4 <virtio_disk_rw>
    b->valid = 1;
    80004746:	4785                	li	a5,1
    80004748:	c09c                	sw	a5,0(s1)
  return b;
    8000474a:	b7c5                	j	8000472a <bread+0xd0>

000000008000474c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000474c:	1101                	add	sp,sp,-32
    8000474e:	ec06                	sd	ra,24(sp)
    80004750:	e822                	sd	s0,16(sp)
    80004752:	e426                	sd	s1,8(sp)
    80004754:	1000                	add	s0,sp,32
    80004756:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004758:	0541                	add	a0,a0,16
    8000475a:	ffffe097          	auipc	ra,0xffffe
    8000475e:	6fc080e7          	jalr	1788(ra) # 80002e56 <holdingsleep>
    80004762:	cd01                	beqz	a0,8000477a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80004764:	4585                	li	a1,1
    80004766:	8526                	mv	a0,s1
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	54c080e7          	jalr	1356(ra) # 80000cb4 <virtio_disk_rw>
}
    80004770:	60e2                	ld	ra,24(sp)
    80004772:	6442                	ld	s0,16(sp)
    80004774:	64a2                	ld	s1,8(sp)
    80004776:	6105                	add	sp,sp,32
    80004778:	8082                	ret
    panic("bwrite");
    8000477a:	00004517          	auipc	a0,0x4
    8000477e:	23e50513          	add	a0,a0,574 # 800089b8 <syscalls+0x1e0>
    80004782:	ffffd097          	auipc	ra,0xffffd
    80004786:	a5e080e7          	jalr	-1442(ra) # 800011e0 <panic>

000000008000478a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000478a:	1101                	add	sp,sp,-32
    8000478c:	ec06                	sd	ra,24(sp)
    8000478e:	e822                	sd	s0,16(sp)
    80004790:	e426                	sd	s1,8(sp)
    80004792:	e04a                	sd	s2,0(sp)
    80004794:	1000                	add	s0,sp,32
    80004796:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004798:	01050913          	add	s2,a0,16
    8000479c:	854a                	mv	a0,s2
    8000479e:	ffffe097          	auipc	ra,0xffffe
    800047a2:	6b8080e7          	jalr	1720(ra) # 80002e56 <holdingsleep>
    800047a6:	c925                	beqz	a0,80004816 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800047a8:	854a                	mv	a0,s2
    800047aa:	ffffe097          	auipc	ra,0xffffe
    800047ae:	668080e7          	jalr	1640(ra) # 80002e12 <releasesleep>

  acquire(&bcache.lock);
    800047b2:	00012517          	auipc	a0,0x12
    800047b6:	5ee50513          	add	a0,a0,1518 # 80016da0 <bcache>
    800047ba:	ffffe097          	auipc	ra,0xffffe
    800047be:	782080e7          	jalr	1922(ra) # 80002f3c <acquire>
  b->refcnt--;
    800047c2:	40bc                	lw	a5,64(s1)
    800047c4:	37fd                	addw	a5,a5,-1
    800047c6:	0007871b          	sext.w	a4,a5
    800047ca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800047cc:	e71d                	bnez	a4,800047fa <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800047ce:	68b8                	ld	a4,80(s1)
    800047d0:	64bc                	ld	a5,72(s1)
    800047d2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800047d4:	68b8                	ld	a4,80(s1)
    800047d6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800047d8:	0001a797          	auipc	a5,0x1a
    800047dc:	5c878793          	add	a5,a5,1480 # 8001eda0 <bcache+0x8000>
    800047e0:	2b87b703          	ld	a4,696(a5)
    800047e4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800047e6:	0001b717          	auipc	a4,0x1b
    800047ea:	82270713          	add	a4,a4,-2014 # 8001f008 <bcache+0x8268>
    800047ee:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800047f0:	2b87b703          	ld	a4,696(a5)
    800047f4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800047f6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800047fa:	00012517          	auipc	a0,0x12
    800047fe:	5a650513          	add	a0,a0,1446 # 80016da0 <bcache>
    80004802:	ffffe097          	auipc	ra,0xffffe
    80004806:	7ee080e7          	jalr	2030(ra) # 80002ff0 <release>
}
    8000480a:	60e2                	ld	ra,24(sp)
    8000480c:	6442                	ld	s0,16(sp)
    8000480e:	64a2                	ld	s1,8(sp)
    80004810:	6902                	ld	s2,0(sp)
    80004812:	6105                	add	sp,sp,32
    80004814:	8082                	ret
    panic("brelse");
    80004816:	00004517          	auipc	a0,0x4
    8000481a:	1aa50513          	add	a0,a0,426 # 800089c0 <syscalls+0x1e8>
    8000481e:	ffffd097          	auipc	ra,0xffffd
    80004822:	9c2080e7          	jalr	-1598(ra) # 800011e0 <panic>

0000000080004826 <bpin>:

void
bpin(struct buf *b) {
    80004826:	1101                	add	sp,sp,-32
    80004828:	ec06                	sd	ra,24(sp)
    8000482a:	e822                	sd	s0,16(sp)
    8000482c:	e426                	sd	s1,8(sp)
    8000482e:	1000                	add	s0,sp,32
    80004830:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80004832:	00012517          	auipc	a0,0x12
    80004836:	56e50513          	add	a0,a0,1390 # 80016da0 <bcache>
    8000483a:	ffffe097          	auipc	ra,0xffffe
    8000483e:	702080e7          	jalr	1794(ra) # 80002f3c <acquire>
  b->refcnt++;
    80004842:	40bc                	lw	a5,64(s1)
    80004844:	2785                	addw	a5,a5,1
    80004846:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004848:	00012517          	auipc	a0,0x12
    8000484c:	55850513          	add	a0,a0,1368 # 80016da0 <bcache>
    80004850:	ffffe097          	auipc	ra,0xffffe
    80004854:	7a0080e7          	jalr	1952(ra) # 80002ff0 <release>
}
    80004858:	60e2                	ld	ra,24(sp)
    8000485a:	6442                	ld	s0,16(sp)
    8000485c:	64a2                	ld	s1,8(sp)
    8000485e:	6105                	add	sp,sp,32
    80004860:	8082                	ret

0000000080004862 <bunpin>:

void
bunpin(struct buf *b) {
    80004862:	1101                	add	sp,sp,-32
    80004864:	ec06                	sd	ra,24(sp)
    80004866:	e822                	sd	s0,16(sp)
    80004868:	e426                	sd	s1,8(sp)
    8000486a:	1000                	add	s0,sp,32
    8000486c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000486e:	00012517          	auipc	a0,0x12
    80004872:	53250513          	add	a0,a0,1330 # 80016da0 <bcache>
    80004876:	ffffe097          	auipc	ra,0xffffe
    8000487a:	6c6080e7          	jalr	1734(ra) # 80002f3c <acquire>
  b->refcnt--;
    8000487e:	40bc                	lw	a5,64(s1)
    80004880:	37fd                	addw	a5,a5,-1
    80004882:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004884:	00012517          	auipc	a0,0x12
    80004888:	51c50513          	add	a0,a0,1308 # 80016da0 <bcache>
    8000488c:	ffffe097          	auipc	ra,0xffffe
    80004890:	764080e7          	jalr	1892(ra) # 80002ff0 <release>
}
    80004894:	60e2                	ld	ra,24(sp)
    80004896:	6442                	ld	s0,16(sp)
    80004898:	64a2                	ld	s1,8(sp)
    8000489a:	6105                	add	sp,sp,32
    8000489c:	8082                	ret

000000008000489e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000489e:	1101                	add	sp,sp,-32
    800048a0:	ec06                	sd	ra,24(sp)
    800048a2:	e822                	sd	s0,16(sp)
    800048a4:	e426                	sd	s1,8(sp)
    800048a6:	e04a                	sd	s2,0(sp)
    800048a8:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800048aa:	0001b917          	auipc	s2,0x1b
    800048ae:	bb690913          	add	s2,s2,-1098 # 8001f460 <log>
    800048b2:	01892583          	lw	a1,24(s2)
    800048b6:	02892503          	lw	a0,40(s2)
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	da0080e7          	jalr	-608(ra) # 8000465a <bread>
    800048c2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800048c4:	02c92603          	lw	a2,44(s2)
    800048c8:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800048ca:	00c05f63          	blez	a2,800048e8 <write_head+0x4a>
    800048ce:	0001b717          	auipc	a4,0x1b
    800048d2:	bc270713          	add	a4,a4,-1086 # 8001f490 <log+0x30>
    800048d6:	87aa                	mv	a5,a0
    800048d8:	060a                	sll	a2,a2,0x2
    800048da:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800048dc:	4314                	lw	a3,0(a4)
    800048de:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800048e0:	0711                	add	a4,a4,4
    800048e2:	0791                	add	a5,a5,4
    800048e4:	fec79ce3          	bne	a5,a2,800048dc <write_head+0x3e>
  }
  bwrite(buf);
    800048e8:	8526                	mv	a0,s1
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	e62080e7          	jalr	-414(ra) # 8000474c <bwrite>
  brelse(buf);
    800048f2:	8526                	mv	a0,s1
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	e96080e7          	jalr	-362(ra) # 8000478a <brelse>
}
    800048fc:	60e2                	ld	ra,24(sp)
    800048fe:	6442                	ld	s0,16(sp)
    80004900:	64a2                	ld	s1,8(sp)
    80004902:	6902                	ld	s2,0(sp)
    80004904:	6105                	add	sp,sp,32
    80004906:	8082                	ret

0000000080004908 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004908:	0001b797          	auipc	a5,0x1b
    8000490c:	b847a783          	lw	a5,-1148(a5) # 8001f48c <log+0x2c>
    80004910:	0af05d63          	blez	a5,800049ca <install_trans+0xc2>
{
    80004914:	7139                	add	sp,sp,-64
    80004916:	fc06                	sd	ra,56(sp)
    80004918:	f822                	sd	s0,48(sp)
    8000491a:	f426                	sd	s1,40(sp)
    8000491c:	f04a                	sd	s2,32(sp)
    8000491e:	ec4e                	sd	s3,24(sp)
    80004920:	e852                	sd	s4,16(sp)
    80004922:	e456                	sd	s5,8(sp)
    80004924:	e05a                	sd	s6,0(sp)
    80004926:	0080                	add	s0,sp,64
    80004928:	8b2a                	mv	s6,a0
    8000492a:	0001ba97          	auipc	s5,0x1b
    8000492e:	b66a8a93          	add	s5,s5,-1178 # 8001f490 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004932:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004934:	0001b997          	auipc	s3,0x1b
    80004938:	b2c98993          	add	s3,s3,-1236 # 8001f460 <log>
    8000493c:	a00d                	j	8000495e <install_trans+0x56>
    brelse(lbuf);
    8000493e:	854a                	mv	a0,s2
    80004940:	00000097          	auipc	ra,0x0
    80004944:	e4a080e7          	jalr	-438(ra) # 8000478a <brelse>
    brelse(dbuf);
    80004948:	8526                	mv	a0,s1
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	e40080e7          	jalr	-448(ra) # 8000478a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004952:	2a05                	addw	s4,s4,1
    80004954:	0a91                	add	s5,s5,4
    80004956:	02c9a783          	lw	a5,44(s3)
    8000495a:	04fa5e63          	bge	s4,a5,800049b6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000495e:	0189a583          	lw	a1,24(s3)
    80004962:	014585bb          	addw	a1,a1,s4
    80004966:	2585                	addw	a1,a1,1
    80004968:	0289a503          	lw	a0,40(s3)
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	cee080e7          	jalr	-786(ra) # 8000465a <bread>
    80004974:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004976:	000aa583          	lw	a1,0(s5)
    8000497a:	0289a503          	lw	a0,40(s3)
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	cdc080e7          	jalr	-804(ra) # 8000465a <bread>
    80004986:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004988:	40000613          	li	a2,1024
    8000498c:	05890593          	add	a1,s2,88
    80004990:	05850513          	add	a0,a0,88
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	660080e7          	jalr	1632(ra) # 80000ff4 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000499c:	8526                	mv	a0,s1
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	dae080e7          	jalr	-594(ra) # 8000474c <bwrite>
    if(recovering == 0)
    800049a6:	f80b1ce3          	bnez	s6,8000493e <install_trans+0x36>
      bunpin(dbuf);
    800049aa:	8526                	mv	a0,s1
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	eb6080e7          	jalr	-330(ra) # 80004862 <bunpin>
    800049b4:	b769                	j	8000493e <install_trans+0x36>
}
    800049b6:	70e2                	ld	ra,56(sp)
    800049b8:	7442                	ld	s0,48(sp)
    800049ba:	74a2                	ld	s1,40(sp)
    800049bc:	7902                	ld	s2,32(sp)
    800049be:	69e2                	ld	s3,24(sp)
    800049c0:	6a42                	ld	s4,16(sp)
    800049c2:	6aa2                	ld	s5,8(sp)
    800049c4:	6b02                	ld	s6,0(sp)
    800049c6:	6121                	add	sp,sp,64
    800049c8:	8082                	ret
    800049ca:	8082                	ret

00000000800049cc <initlog>:
{
    800049cc:	7179                	add	sp,sp,-48
    800049ce:	f406                	sd	ra,40(sp)
    800049d0:	f022                	sd	s0,32(sp)
    800049d2:	ec26                	sd	s1,24(sp)
    800049d4:	e84a                	sd	s2,16(sp)
    800049d6:	e44e                	sd	s3,8(sp)
    800049d8:	1800                	add	s0,sp,48
    800049da:	892a                	mv	s2,a0
    800049dc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800049de:	0001b497          	auipc	s1,0x1b
    800049e2:	a8248493          	add	s1,s1,-1406 # 8001f460 <log>
    800049e6:	00004597          	auipc	a1,0x4
    800049ea:	fe258593          	add	a1,a1,-30 # 800089c8 <syscalls+0x1f0>
    800049ee:	8526                	mv	a0,s1
    800049f0:	ffffe097          	auipc	ra,0xffffe
    800049f4:	4bc080e7          	jalr	1212(ra) # 80002eac <initlock>
  log.start = sb->logstart;
    800049f8:	0149a583          	lw	a1,20(s3)
    800049fc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800049fe:	0109a783          	lw	a5,16(s3)
    80004a02:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004a04:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004a08:	854a                	mv	a0,s2
    80004a0a:	00000097          	auipc	ra,0x0
    80004a0e:	c50080e7          	jalr	-944(ra) # 8000465a <bread>
  log.lh.n = lh->n;
    80004a12:	4d30                	lw	a2,88(a0)
    80004a14:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004a16:	00c05f63          	blez	a2,80004a34 <initlog+0x68>
    80004a1a:	87aa                	mv	a5,a0
    80004a1c:	0001b717          	auipc	a4,0x1b
    80004a20:	a7470713          	add	a4,a4,-1420 # 8001f490 <log+0x30>
    80004a24:	060a                	sll	a2,a2,0x2
    80004a26:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004a28:	4ff4                	lw	a3,92(a5)
    80004a2a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a2c:	0791                	add	a5,a5,4
    80004a2e:	0711                	add	a4,a4,4
    80004a30:	fec79ce3          	bne	a5,a2,80004a28 <initlog+0x5c>
  brelse(buf);
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	d56080e7          	jalr	-682(ra) # 8000478a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004a3c:	4505                	li	a0,1
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	eca080e7          	jalr	-310(ra) # 80004908 <install_trans>
  log.lh.n = 0;
    80004a46:	0001b797          	auipc	a5,0x1b
    80004a4a:	a407a323          	sw	zero,-1466(a5) # 8001f48c <log+0x2c>
  write_head(); // clear the log
    80004a4e:	00000097          	auipc	ra,0x0
    80004a52:	e50080e7          	jalr	-432(ra) # 8000489e <write_head>
}
    80004a56:	70a2                	ld	ra,40(sp)
    80004a58:	7402                	ld	s0,32(sp)
    80004a5a:	64e2                	ld	s1,24(sp)
    80004a5c:	6942                	ld	s2,16(sp)
    80004a5e:	69a2                	ld	s3,8(sp)
    80004a60:	6145                	add	sp,sp,48
    80004a62:	8082                	ret

0000000080004a64 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a64:	1101                	add	sp,sp,-32
    80004a66:	ec06                	sd	ra,24(sp)
    80004a68:	e822                	sd	s0,16(sp)
    80004a6a:	e426                	sd	s1,8(sp)
    80004a6c:	e04a                	sd	s2,0(sp)
    80004a6e:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004a70:	0001b517          	auipc	a0,0x1b
    80004a74:	9f050513          	add	a0,a0,-1552 # 8001f460 <log>
    80004a78:	ffffe097          	auipc	ra,0xffffe
    80004a7c:	4c4080e7          	jalr	1220(ra) # 80002f3c <acquire>
  while(1){
    if(log.committing){
    80004a80:	0001b497          	auipc	s1,0x1b
    80004a84:	9e048493          	add	s1,s1,-1568 # 8001f460 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a88:	4979                	li	s2,30
    80004a8a:	a039                	j	80004a98 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a8c:	85a6                	mv	a1,s1
    80004a8e:	8526                	mv	a0,s1
    80004a90:	ffffe097          	auipc	ra,0xffffe
    80004a94:	dfa080e7          	jalr	-518(ra) # 8000288a <sleep>
    if(log.committing){
    80004a98:	50dc                	lw	a5,36(s1)
    80004a9a:	fbed                	bnez	a5,80004a8c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a9c:	5098                	lw	a4,32(s1)
    80004a9e:	2705                	addw	a4,a4,1
    80004aa0:	0027179b          	sllw	a5,a4,0x2
    80004aa4:	9fb9                	addw	a5,a5,a4
    80004aa6:	0017979b          	sllw	a5,a5,0x1
    80004aaa:	54d4                	lw	a3,44(s1)
    80004aac:	9fb5                	addw	a5,a5,a3
    80004aae:	00f95963          	bge	s2,a5,80004ac0 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004ab2:	85a6                	mv	a1,s1
    80004ab4:	8526                	mv	a0,s1
    80004ab6:	ffffe097          	auipc	ra,0xffffe
    80004aba:	dd4080e7          	jalr	-556(ra) # 8000288a <sleep>
    80004abe:	bfe9                	j	80004a98 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004ac0:	0001b517          	auipc	a0,0x1b
    80004ac4:	9a050513          	add	a0,a0,-1632 # 8001f460 <log>
    80004ac8:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004aca:	ffffe097          	auipc	ra,0xffffe
    80004ace:	526080e7          	jalr	1318(ra) # 80002ff0 <release>
      break;
    }
  }
}
    80004ad2:	60e2                	ld	ra,24(sp)
    80004ad4:	6442                	ld	s0,16(sp)
    80004ad6:	64a2                	ld	s1,8(sp)
    80004ad8:	6902                	ld	s2,0(sp)
    80004ada:	6105                	add	sp,sp,32
    80004adc:	8082                	ret

0000000080004ade <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004ade:	7139                	add	sp,sp,-64
    80004ae0:	fc06                	sd	ra,56(sp)
    80004ae2:	f822                	sd	s0,48(sp)
    80004ae4:	f426                	sd	s1,40(sp)
    80004ae6:	f04a                	sd	s2,32(sp)
    80004ae8:	ec4e                	sd	s3,24(sp)
    80004aea:	e852                	sd	s4,16(sp)
    80004aec:	e456                	sd	s5,8(sp)
    80004aee:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004af0:	0001b497          	auipc	s1,0x1b
    80004af4:	97048493          	add	s1,s1,-1680 # 8001f460 <log>
    80004af8:	8526                	mv	a0,s1
    80004afa:	ffffe097          	auipc	ra,0xffffe
    80004afe:	442080e7          	jalr	1090(ra) # 80002f3c <acquire>
  log.outstanding -= 1;
    80004b02:	509c                	lw	a5,32(s1)
    80004b04:	37fd                	addw	a5,a5,-1
    80004b06:	0007891b          	sext.w	s2,a5
    80004b0a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004b0c:	50dc                	lw	a5,36(s1)
    80004b0e:	e7b9                	bnez	a5,80004b5c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004b10:	04091e63          	bnez	s2,80004b6c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004b14:	0001b497          	auipc	s1,0x1b
    80004b18:	94c48493          	add	s1,s1,-1716 # 8001f460 <log>
    80004b1c:	4785                	li	a5,1
    80004b1e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffe097          	auipc	ra,0xffffe
    80004b26:	4ce080e7          	jalr	1230(ra) # 80002ff0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b2a:	54dc                	lw	a5,44(s1)
    80004b2c:	06f04763          	bgtz	a5,80004b9a <end_op+0xbc>
    acquire(&log.lock);
    80004b30:	0001b497          	auipc	s1,0x1b
    80004b34:	93048493          	add	s1,s1,-1744 # 8001f460 <log>
    80004b38:	8526                	mv	a0,s1
    80004b3a:	ffffe097          	auipc	ra,0xffffe
    80004b3e:	402080e7          	jalr	1026(ra) # 80002f3c <acquire>
    log.committing = 0;
    80004b42:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffe097          	auipc	ra,0xffffe
    80004b4c:	db0080e7          	jalr	-592(ra) # 800028f8 <wakeup>
    release(&log.lock);
    80004b50:	8526                	mv	a0,s1
    80004b52:	ffffe097          	auipc	ra,0xffffe
    80004b56:	49e080e7          	jalr	1182(ra) # 80002ff0 <release>
}
    80004b5a:	a03d                	j	80004b88 <end_op+0xaa>
    panic("log.committing");
    80004b5c:	00004517          	auipc	a0,0x4
    80004b60:	e7450513          	add	a0,a0,-396 # 800089d0 <syscalls+0x1f8>
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	67c080e7          	jalr	1660(ra) # 800011e0 <panic>
    wakeup(&log);
    80004b6c:	0001b497          	auipc	s1,0x1b
    80004b70:	8f448493          	add	s1,s1,-1804 # 8001f460 <log>
    80004b74:	8526                	mv	a0,s1
    80004b76:	ffffe097          	auipc	ra,0xffffe
    80004b7a:	d82080e7          	jalr	-638(ra) # 800028f8 <wakeup>
  release(&log.lock);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffe097          	auipc	ra,0xffffe
    80004b84:	470080e7          	jalr	1136(ra) # 80002ff0 <release>
}
    80004b88:	70e2                	ld	ra,56(sp)
    80004b8a:	7442                	ld	s0,48(sp)
    80004b8c:	74a2                	ld	s1,40(sp)
    80004b8e:	7902                	ld	s2,32(sp)
    80004b90:	69e2                	ld	s3,24(sp)
    80004b92:	6a42                	ld	s4,16(sp)
    80004b94:	6aa2                	ld	s5,8(sp)
    80004b96:	6121                	add	sp,sp,64
    80004b98:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b9a:	0001ba97          	auipc	s5,0x1b
    80004b9e:	8f6a8a93          	add	s5,s5,-1802 # 8001f490 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ba2:	0001ba17          	auipc	s4,0x1b
    80004ba6:	8bea0a13          	add	s4,s4,-1858 # 8001f460 <log>
    80004baa:	018a2583          	lw	a1,24(s4)
    80004bae:	012585bb          	addw	a1,a1,s2
    80004bb2:	2585                	addw	a1,a1,1
    80004bb4:	028a2503          	lw	a0,40(s4)
    80004bb8:	00000097          	auipc	ra,0x0
    80004bbc:	aa2080e7          	jalr	-1374(ra) # 8000465a <bread>
    80004bc0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004bc2:	000aa583          	lw	a1,0(s5)
    80004bc6:	028a2503          	lw	a0,40(s4)
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	a90080e7          	jalr	-1392(ra) # 8000465a <bread>
    80004bd2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004bd4:	40000613          	li	a2,1024
    80004bd8:	05850593          	add	a1,a0,88
    80004bdc:	05848513          	add	a0,s1,88
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	414080e7          	jalr	1044(ra) # 80000ff4 <memmove>
    bwrite(to);  // write the log
    80004be8:	8526                	mv	a0,s1
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	b62080e7          	jalr	-1182(ra) # 8000474c <bwrite>
    brelse(from);
    80004bf2:	854e                	mv	a0,s3
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	b96080e7          	jalr	-1130(ra) # 8000478a <brelse>
    brelse(to);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	00000097          	auipc	ra,0x0
    80004c02:	b8c080e7          	jalr	-1140(ra) # 8000478a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c06:	2905                	addw	s2,s2,1
    80004c08:	0a91                	add	s5,s5,4
    80004c0a:	02ca2783          	lw	a5,44(s4)
    80004c0e:	f8f94ee3          	blt	s2,a5,80004baa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004c12:	00000097          	auipc	ra,0x0
    80004c16:	c8c080e7          	jalr	-884(ra) # 8000489e <write_head>
    install_trans(0); // Now install writes to home locations
    80004c1a:	4501                	li	a0,0
    80004c1c:	00000097          	auipc	ra,0x0
    80004c20:	cec080e7          	jalr	-788(ra) # 80004908 <install_trans>
    log.lh.n = 0;
    80004c24:	0001b797          	auipc	a5,0x1b
    80004c28:	8607a423          	sw	zero,-1944(a5) # 8001f48c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	c72080e7          	jalr	-910(ra) # 8000489e <write_head>
    80004c34:	bdf5                	j	80004b30 <end_op+0x52>

0000000080004c36 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004c36:	1101                	add	sp,sp,-32
    80004c38:	ec06                	sd	ra,24(sp)
    80004c3a:	e822                	sd	s0,16(sp)
    80004c3c:	e426                	sd	s1,8(sp)
    80004c3e:	e04a                	sd	s2,0(sp)
    80004c40:	1000                	add	s0,sp,32
    80004c42:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004c44:	0001b917          	auipc	s2,0x1b
    80004c48:	81c90913          	add	s2,s2,-2020 # 8001f460 <log>
    80004c4c:	854a                	mv	a0,s2
    80004c4e:	ffffe097          	auipc	ra,0xffffe
    80004c52:	2ee080e7          	jalr	750(ra) # 80002f3c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c56:	02c92603          	lw	a2,44(s2)
    80004c5a:	47f5                	li	a5,29
    80004c5c:	06c7c563          	blt	a5,a2,80004cc6 <log_write+0x90>
    80004c60:	0001b797          	auipc	a5,0x1b
    80004c64:	81c7a783          	lw	a5,-2020(a5) # 8001f47c <log+0x1c>
    80004c68:	37fd                	addw	a5,a5,-1
    80004c6a:	04f65e63          	bge	a2,a5,80004cc6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c6e:	0001b797          	auipc	a5,0x1b
    80004c72:	8127a783          	lw	a5,-2030(a5) # 8001f480 <log+0x20>
    80004c76:	06f05063          	blez	a5,80004cd6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c7a:	4781                	li	a5,0
    80004c7c:	06c05563          	blez	a2,80004ce6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c80:	44cc                	lw	a1,12(s1)
    80004c82:	0001b717          	auipc	a4,0x1b
    80004c86:	80e70713          	add	a4,a4,-2034 # 8001f490 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c8a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c8c:	4314                	lw	a3,0(a4)
    80004c8e:	04b68c63          	beq	a3,a1,80004ce6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c92:	2785                	addw	a5,a5,1
    80004c94:	0711                	add	a4,a4,4
    80004c96:	fef61be3          	bne	a2,a5,80004c8c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c9a:	0621                	add	a2,a2,8
    80004c9c:	060a                	sll	a2,a2,0x2
    80004c9e:	0001a797          	auipc	a5,0x1a
    80004ca2:	7c278793          	add	a5,a5,1986 # 8001f460 <log>
    80004ca6:	97b2                	add	a5,a5,a2
    80004ca8:	44d8                	lw	a4,12(s1)
    80004caa:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004cac:	8526                	mv	a0,s1
    80004cae:	00000097          	auipc	ra,0x0
    80004cb2:	b78080e7          	jalr	-1160(ra) # 80004826 <bpin>
    log.lh.n++;
    80004cb6:	0001a717          	auipc	a4,0x1a
    80004cba:	7aa70713          	add	a4,a4,1962 # 8001f460 <log>
    80004cbe:	575c                	lw	a5,44(a4)
    80004cc0:	2785                	addw	a5,a5,1
    80004cc2:	d75c                	sw	a5,44(a4)
    80004cc4:	a82d                	j	80004cfe <log_write+0xc8>
    panic("too big a transaction");
    80004cc6:	00004517          	auipc	a0,0x4
    80004cca:	d1a50513          	add	a0,a0,-742 # 800089e0 <syscalls+0x208>
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	512080e7          	jalr	1298(ra) # 800011e0 <panic>
    panic("log_write outside of trans");
    80004cd6:	00004517          	auipc	a0,0x4
    80004cda:	d2250513          	add	a0,a0,-734 # 800089f8 <syscalls+0x220>
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	502080e7          	jalr	1282(ra) # 800011e0 <panic>
  log.lh.block[i] = b->blockno;
    80004ce6:	00878693          	add	a3,a5,8
    80004cea:	068a                	sll	a3,a3,0x2
    80004cec:	0001a717          	auipc	a4,0x1a
    80004cf0:	77470713          	add	a4,a4,1908 # 8001f460 <log>
    80004cf4:	9736                	add	a4,a4,a3
    80004cf6:	44d4                	lw	a3,12(s1)
    80004cf8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004cfa:	faf609e3          	beq	a2,a5,80004cac <log_write+0x76>
  }
  release(&log.lock);
    80004cfe:	0001a517          	auipc	a0,0x1a
    80004d02:	76250513          	add	a0,a0,1890 # 8001f460 <log>
    80004d06:	ffffe097          	auipc	ra,0xffffe
    80004d0a:	2ea080e7          	jalr	746(ra) # 80002ff0 <release>
}
    80004d0e:	60e2                	ld	ra,24(sp)
    80004d10:	6442                	ld	s0,16(sp)
    80004d12:	64a2                	ld	s1,8(sp)
    80004d14:	6902                	ld	s2,0(sp)
    80004d16:	6105                	add	sp,sp,32
    80004d18:	8082                	ret

0000000080004d1a <fileinit>:
} ftable;  //这是系统的全局打开文件表

/// @brief 初始化文件表
void
fileinit(void)
{
    80004d1a:	1141                	add	sp,sp,-16
    80004d1c:	e406                	sd	ra,8(sp)
    80004d1e:	e022                	sd	s0,0(sp)
    80004d20:	0800                	add	s0,sp,16
  // 初始化文件表锁
  initlock(&ftable.lock, "ftable");
    80004d22:	00004597          	auipc	a1,0x4
    80004d26:	cf658593          	add	a1,a1,-778 # 80008a18 <syscalls+0x240>
    80004d2a:	0001b517          	auipc	a0,0x1b
    80004d2e:	87e50513          	add	a0,a0,-1922 # 8001f5a8 <ftable>
    80004d32:	ffffe097          	auipc	ra,0xffffe
    80004d36:	17a080e7          	jalr	378(ra) # 80002eac <initlock>
}
    80004d3a:	60a2                	ld	ra,8(sp)
    80004d3c:	6402                	ld	s0,0(sp)
    80004d3e:	0141                	add	sp,sp,16
    80004d40:	8082                	ret

0000000080004d42 <filealloc>:

/// @brief 分配一个文件结构体。
struct file*
filealloc(void)
{
    80004d42:	1101                	add	sp,sp,-32
    80004d44:	ec06                	sd	ra,24(sp)
    80004d46:	e822                	sd	s0,16(sp)
    80004d48:	e426                	sd	s1,8(sp)
    80004d4a:	1000                	add	s0,sp,32
  struct file *f;

  // 获取文件表锁
  acquire(&ftable.lock);
    80004d4c:	0001b517          	auipc	a0,0x1b
    80004d50:	85c50513          	add	a0,a0,-1956 # 8001f5a8 <ftable>
    80004d54:	ffffe097          	auipc	ra,0xffffe
    80004d58:	1e8080e7          	jalr	488(ra) # 80002f3c <acquire>
  // 遍历文件表寻找空闲的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d5c:	0001b497          	auipc	s1,0x1b
    80004d60:	86448493          	add	s1,s1,-1948 # 8001f5c0 <ftable+0x18>
    80004d64:	0001b717          	auipc	a4,0x1b
    80004d68:	7fc70713          	add	a4,a4,2044 # 80020560 <sb>
    if(f->ref == 0){
    80004d6c:	40dc                	lw	a5,4(s1)
    80004d6e:	cf99                	beqz	a5,80004d8c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d70:	02848493          	add	s1,s1,40
    80004d74:	fee49ce3          	bne	s1,a4,80004d6c <filealloc+0x2a>
      release(&ftable.lock);
      return f;
    }
  }
  // 没有找到空闲的文件结构体
  release(&ftable.lock);
    80004d78:	0001b517          	auipc	a0,0x1b
    80004d7c:	83050513          	add	a0,a0,-2000 # 8001f5a8 <ftable>
    80004d80:	ffffe097          	auipc	ra,0xffffe
    80004d84:	270080e7          	jalr	624(ra) # 80002ff0 <release>
  return 0;
    80004d88:	4481                	li	s1,0
    80004d8a:	a819                	j	80004da0 <filealloc+0x5e>
      f->ref = 1;
    80004d8c:	4785                	li	a5,1
    80004d8e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d90:	0001b517          	auipc	a0,0x1b
    80004d94:	81850513          	add	a0,a0,-2024 # 8001f5a8 <ftable>
    80004d98:	ffffe097          	auipc	ra,0xffffe
    80004d9c:	258080e7          	jalr	600(ra) # 80002ff0 <release>
}
    80004da0:	8526                	mv	a0,s1
    80004da2:	60e2                	ld	ra,24(sp)
    80004da4:	6442                	ld	s0,16(sp)
    80004da6:	64a2                	ld	s1,8(sp)
    80004da8:	6105                	add	sp,sp,32
    80004daa:	8082                	ret

0000000080004dac <filedup>:

/// @brief 增加文件f的引用计数。
struct file*
filedup(struct file *f)
{
    80004dac:	1101                	add	sp,sp,-32
    80004dae:	ec06                	sd	ra,24(sp)
    80004db0:	e822                	sd	s0,16(sp)
    80004db2:	e426                	sd	s1,8(sp)
    80004db4:	1000                	add	s0,sp,32
    80004db6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004db8:	0001a517          	auipc	a0,0x1a
    80004dbc:	7f050513          	add	a0,a0,2032 # 8001f5a8 <ftable>
    80004dc0:	ffffe097          	auipc	ra,0xffffe
    80004dc4:	17c080e7          	jalr	380(ra) # 80002f3c <acquire>
  // 检查文件引用计数的有效性
  if(f->ref < 1)
    80004dc8:	40dc                	lw	a5,4(s1)
    80004dca:	02f05263          	blez	a5,80004dee <filedup+0x42>
    panic("filedup");
  // 增加引用计数
  f->ref++;
    80004dce:	2785                	addw	a5,a5,1
    80004dd0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004dd2:	0001a517          	auipc	a0,0x1a
    80004dd6:	7d650513          	add	a0,a0,2006 # 8001f5a8 <ftable>
    80004dda:	ffffe097          	auipc	ra,0xffffe
    80004dde:	216080e7          	jalr	534(ra) # 80002ff0 <release>
  return f;
}
    80004de2:	8526                	mv	a0,s1
    80004de4:	60e2                	ld	ra,24(sp)
    80004de6:	6442                	ld	s0,16(sp)
    80004de8:	64a2                	ld	s1,8(sp)
    80004dea:	6105                	add	sp,sp,32
    80004dec:	8082                	ret
    panic("filedup");
    80004dee:	00004517          	auipc	a0,0x4
    80004df2:	c3250513          	add	a0,a0,-974 # 80008a20 <syscalls+0x248>
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	3ea080e7          	jalr	1002(ra) # 800011e0 <panic>

0000000080004dfe <fileclose>:

/// @brief 关闭文件f。（减少引用计数，当引用计数达到0时关闭。）
void
fileclose(struct file *f)
{
    80004dfe:	7139                	add	sp,sp,-64
    80004e00:	fc06                	sd	ra,56(sp)
    80004e02:	f822                	sd	s0,48(sp)
    80004e04:	f426                	sd	s1,40(sp)
    80004e06:	f04a                	sd	s2,32(sp)
    80004e08:	ec4e                	sd	s3,24(sp)
    80004e0a:	e852                	sd	s4,16(sp)
    80004e0c:	e456                	sd	s5,8(sp)
    80004e0e:	0080                	add	s0,sp,64
    80004e10:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e12:	0001a517          	auipc	a0,0x1a
    80004e16:	79650513          	add	a0,a0,1942 # 8001f5a8 <ftable>
    80004e1a:	ffffe097          	auipc	ra,0xffffe
    80004e1e:	122080e7          	jalr	290(ra) # 80002f3c <acquire>
  // 检查文件引用计数的有效性
  if(f->ref < 1)
    80004e22:	40dc                	lw	a5,4(s1)
    80004e24:	06f05163          	blez	a5,80004e86 <fileclose+0x88>
    panic("fileclose");
  // 减少引用计数，如果仍有其他引用则直接返回
  if(--f->ref > 0){
    80004e28:	37fd                	addw	a5,a5,-1
    80004e2a:	0007871b          	sext.w	a4,a5
    80004e2e:	c0dc                	sw	a5,4(s1)
    80004e30:	06e04363          	bgtz	a4,80004e96 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  // 保存文件信息的副本
  ff = *f;
    80004e34:	0004a903          	lw	s2,0(s1)
    80004e38:	0094ca83          	lbu	s5,9(s1)
    80004e3c:	0104ba03          	ld	s4,16(s1)
    80004e40:	0184b983          	ld	s3,24(s1)
  // 清除文件表项
  f->ref = 0;
    80004e44:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e48:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e4c:	0001a517          	auipc	a0,0x1a
    80004e50:	75c50513          	add	a0,a0,1884 # 8001f5a8 <ftable>
    80004e54:	ffffe097          	auipc	ra,0xffffe
    80004e58:	19c080e7          	jalr	412(ra) # 80002ff0 <release>

  // 根据文件类型进行相应的清理工作
  if(ff.type == FD_PIPE){
    80004e5c:	4785                	li	a5,1
    80004e5e:	04f90d63          	beq	s2,a5,80004eb8 <fileclose+0xba>
    // 关闭管道
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e62:	3979                	addw	s2,s2,-2
    80004e64:	4785                	li	a5,1
    80004e66:	0527e063          	bltu	a5,s2,80004ea6 <fileclose+0xa8>
    // 释放inode引用
    //对于涉及文件系统的操作，还需要begin_op和end_op
    //在进行一个inode操作前后，必须添加这种资源获取与释放的对应操作
    //详情参看实验指导书8.6代码：日志（https://xv6.dgs.zone/tranlate_books/book-riscv-rev1/c8/s6.html）
    begin_op();
    80004e6a:	00000097          	auipc	ra,0x0
    80004e6e:	bfa080e7          	jalr	-1030(ra) # 80004a64 <begin_op>
    iput(ff.ip);
    80004e72:	854e                	mv	a0,s3
    80004e74:	00001097          	auipc	ra,0x1
    80004e78:	dfc080e7          	jalr	-516(ra) # 80005c70 <iput>
    end_op();
    80004e7c:	00000097          	auipc	ra,0x0
    80004e80:	c62080e7          	jalr	-926(ra) # 80004ade <end_op>
    80004e84:	a00d                	j	80004ea6 <fileclose+0xa8>
    panic("fileclose");
    80004e86:	00004517          	auipc	a0,0x4
    80004e8a:	ba250513          	add	a0,a0,-1118 # 80008a28 <syscalls+0x250>
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	352080e7          	jalr	850(ra) # 800011e0 <panic>
    release(&ftable.lock);
    80004e96:	0001a517          	auipc	a0,0x1a
    80004e9a:	71250513          	add	a0,a0,1810 # 8001f5a8 <ftable>
    80004e9e:	ffffe097          	auipc	ra,0xffffe
    80004ea2:	152080e7          	jalr	338(ra) # 80002ff0 <release>
  }
}
    80004ea6:	70e2                	ld	ra,56(sp)
    80004ea8:	7442                	ld	s0,48(sp)
    80004eaa:	74a2                	ld	s1,40(sp)
    80004eac:	7902                	ld	s2,32(sp)
    80004eae:	69e2                	ld	s3,24(sp)
    80004eb0:	6a42                	ld	s4,16(sp)
    80004eb2:	6aa2                	ld	s5,8(sp)
    80004eb4:	6121                	add	sp,sp,64
    80004eb6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004eb8:	85d6                	mv	a1,s5
    80004eba:	8552                	mv	a0,s4
    80004ebc:	00000097          	auipc	ra,0x0
    80004ec0:	3d6080e7          	jalr	982(ra) # 80005292 <pipeclose>
    80004ec4:	b7cd                	j	80004ea6 <fileclose+0xa8>

0000000080004ec6 <filestat>:

/// @brief 获取文件f的元数据。
/// addr是用户虚拟地址，指向struct stat。
int
filestat(struct file *f, uint64 addr)
{
    80004ec6:	715d                	add	sp,sp,-80
    80004ec8:	e486                	sd	ra,72(sp)
    80004eca:	e0a2                	sd	s0,64(sp)
    80004ecc:	fc26                	sd	s1,56(sp)
    80004ece:	f84a                	sd	s2,48(sp)
    80004ed0:	f44e                	sd	s3,40(sp)
    80004ed2:	0880                	add	s0,sp,80
    80004ed4:	84aa                	mv	s1,a0
    80004ed6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	236080e7          	jalr	566(ra) # 8000210e <myproc>
  struct stat st;
  
  // 只有inode和设备文件支持stat操作
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ee0:	409c                	lw	a5,0(s1)
    80004ee2:	37f9                	addw	a5,a5,-2
    80004ee4:	4705                	li	a4,1
    80004ee6:	04f76763          	bltu	a4,a5,80004f34 <filestat+0x6e>
    80004eea:	892a                	mv	s2,a0
    // 锁定inode并获取stat信息
    ilock(f->ip);
    80004eec:	6c88                	ld	a0,24(s1)
    80004eee:	00001097          	auipc	ra,0x1
    80004ef2:	bc8080e7          	jalr	-1080(ra) # 80005ab6 <ilock>
    stati(f->ip, &st);
    80004ef6:	fb840593          	add	a1,s0,-72
    80004efa:	6c88                	ld	a0,24(s1)
    80004efc:	00001097          	auipc	ra,0x1
    80004f00:	e44080e7          	jalr	-444(ra) # 80005d40 <stati>
    iunlock(f->ip);
    80004f04:	6c88                	ld	a0,24(s1)
    80004f06:	00001097          	auipc	ra,0x1
    80004f0a:	c72080e7          	jalr	-910(ra) # 80005b78 <iunlock>
    // 将stat信息复制到用户空间
    if(copyout(p->pgtbl, addr, (char *)&st, sizeof(st)) < 0)
    80004f0e:	46e1                	li	a3,24
    80004f10:	fb840613          	add	a2,s0,-72
    80004f14:	85ce                	mv	a1,s3
    80004f16:	04893503          	ld	a0,72(s2)
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	ff2080e7          	jalr	-14(ra) # 80001f0c <copyout>
    80004f22:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f26:	60a6                	ld	ra,72(sp)
    80004f28:	6406                	ld	s0,64(sp)
    80004f2a:	74e2                	ld	s1,56(sp)
    80004f2c:	7942                	ld	s2,48(sp)
    80004f2e:	79a2                	ld	s3,40(sp)
    80004f30:	6161                	add	sp,sp,80
    80004f32:	8082                	ret
  return -1;
    80004f34:	557d                	li	a0,-1
    80004f36:	bfc5                	j	80004f26 <filestat+0x60>

0000000080004f38 <fileread>:

/// @brief 从文件f读取数据。
/// addr是用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f38:	7179                	add	sp,sp,-48
    80004f3a:	f406                	sd	ra,40(sp)
    80004f3c:	f022                	sd	s0,32(sp)
    80004f3e:	ec26                	sd	s1,24(sp)
    80004f40:	e84a                	sd	s2,16(sp)
    80004f42:	e44e                	sd	s3,8(sp)
    80004f44:	1800                	add	s0,sp,48
  int r = 0;

  // 检查文件是否可读
  if(f->readable == 0)
    80004f46:	00854783          	lbu	a5,8(a0)
    80004f4a:	c3d5                	beqz	a5,80004fee <fileread+0xb6>
    80004f4c:	84aa                	mv	s1,a0
    80004f4e:	89ae                	mv	s3,a1
    80004f50:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    80004f52:	411c                	lw	a5,0(a0)
    80004f54:	4705                	li	a4,1
    80004f56:	04e78963          	beq	a5,a4,80004fa8 <fileread+0x70>
    // 从管道读取
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f5a:	470d                	li	a4,3
    80004f5c:	04e78d63          	beq	a5,a4,80004fb6 <fileread+0x7e>
    // 从设备读取
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f60:	4709                	li	a4,2
    80004f62:	06e79e63          	bne	a5,a4,80004fde <fileread+0xa6>
    // 从inode文件读取
    ilock(f->ip);
    80004f66:	6d08                	ld	a0,24(a0)
    80004f68:	00001097          	auipc	ra,0x1
    80004f6c:	b4e080e7          	jalr	-1202(ra) # 80005ab6 <ilock>
    // 从当前偏移量处读取数据
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f70:	874a                	mv	a4,s2
    80004f72:	5094                	lw	a3,32(s1)
    80004f74:	864e                	mv	a2,s3
    80004f76:	4585                	li	a1,1
    80004f78:	6c88                	ld	a0,24(s1)
    80004f7a:	00001097          	auipc	ra,0x1
    80004f7e:	df0080e7          	jalr	-528(ra) # 80005d6a <readi>
    80004f82:	892a                	mv	s2,a0
    80004f84:	00a05563          	blez	a0,80004f8e <fileread+0x56>
      f->off += r; // 更新文件偏移量
    80004f88:	509c                	lw	a5,32(s1)
    80004f8a:	9fa9                	addw	a5,a5,a0
    80004f8c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f8e:	6c88                	ld	a0,24(s1)
    80004f90:	00001097          	auipc	ra,0x1
    80004f94:	be8080e7          	jalr	-1048(ra) # 80005b78 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f98:	854a                	mv	a0,s2
    80004f9a:	70a2                	ld	ra,40(sp)
    80004f9c:	7402                	ld	s0,32(sp)
    80004f9e:	64e2                	ld	s1,24(sp)
    80004fa0:	6942                	ld	s2,16(sp)
    80004fa2:	69a2                	ld	s3,8(sp)
    80004fa4:	6145                	add	sp,sp,48
    80004fa6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004fa8:	6908                	ld	a0,16(a0)
    80004faa:	00000097          	auipc	ra,0x0
    80004fae:	452080e7          	jalr	1106(ra) # 800053fc <piperead>
    80004fb2:	892a                	mv	s2,a0
    80004fb4:	b7d5                	j	80004f98 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004fb6:	02451783          	lh	a5,36(a0)
    80004fba:	03079693          	sll	a3,a5,0x30
    80004fbe:	92c1                	srl	a3,a3,0x30
    80004fc0:	4725                	li	a4,9
    80004fc2:	02d76863          	bltu	a4,a3,80004ff2 <fileread+0xba>
    80004fc6:	0792                	sll	a5,a5,0x4
    80004fc8:	0001a717          	auipc	a4,0x1a
    80004fcc:	54070713          	add	a4,a4,1344 # 8001f508 <devsw>
    80004fd0:	97ba                	add	a5,a5,a4
    80004fd2:	639c                	ld	a5,0(a5)
    80004fd4:	c38d                	beqz	a5,80004ff6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fd6:	4505                	li	a0,1
    80004fd8:	9782                	jalr	a5
    80004fda:	892a                	mv	s2,a0
    80004fdc:	bf75                	j	80004f98 <fileread+0x60>
    panic("fileread");
    80004fde:	00004517          	auipc	a0,0x4
    80004fe2:	a5a50513          	add	a0,a0,-1446 # 80008a38 <syscalls+0x260>
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	1fa080e7          	jalr	506(ra) # 800011e0 <panic>
    return -1;
    80004fee:	597d                	li	s2,-1
    80004ff0:	b765                	j	80004f98 <fileread+0x60>
      return -1;
    80004ff2:	597d                	li	s2,-1
    80004ff4:	b755                	j	80004f98 <fileread+0x60>
    80004ff6:	597d                	li	s2,-1
    80004ff8:	b745                	j	80004f98 <fileread+0x60>

0000000080004ffa <filewrite>:
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  // 检查文件是否可写
  if(f->writable == 0)
    80004ffa:	00954783          	lbu	a5,9(a0)
    80004ffe:	10078e63          	beqz	a5,8000511a <filewrite+0x120>
{
    80005002:	715d                	add	sp,sp,-80
    80005004:	e486                	sd	ra,72(sp)
    80005006:	e0a2                	sd	s0,64(sp)
    80005008:	fc26                	sd	s1,56(sp)
    8000500a:	f84a                	sd	s2,48(sp)
    8000500c:	f44e                	sd	s3,40(sp)
    8000500e:	f052                	sd	s4,32(sp)
    80005010:	ec56                	sd	s5,24(sp)
    80005012:	e85a                	sd	s6,16(sp)
    80005014:	e45e                	sd	s7,8(sp)
    80005016:	e062                	sd	s8,0(sp)
    80005018:	0880                	add	s0,sp,80
    8000501a:	892a                	mv	s2,a0
    8000501c:	8b2e                	mv	s6,a1
    8000501e:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    80005020:	411c                	lw	a5,0(a0)
    80005022:	4705                	li	a4,1
    80005024:	02e78263          	beq	a5,a4,80005048 <filewrite+0x4e>
    // 向管道写入
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005028:	470d                	li	a4,3
    8000502a:	02e78563          	beq	a5,a4,80005054 <filewrite+0x5a>
    // 向设备写入
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000502e:	4709                	li	a4,2
    80005030:	0ce79d63          	bne	a5,a4,8000510a <filewrite+0x110>
    // 这实际上应该在更低层，因为writei()
    // 可能正在写入像控制台这样的设备。
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    // 分批写入数据
    while(i < n){
    80005034:	0ac05b63          	blez	a2,800050ea <filewrite+0xf0>
    int i = 0;
    80005038:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    8000503a:	6b85                	lui	s7,0x1
    8000503c:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005040:	6c05                	lui	s8,0x1
    80005042:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005046:	a851                	j	800050da <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80005048:	6908                	ld	a0,16(a0)
    8000504a:	00000097          	auipc	ra,0x0
    8000504e:	2ba080e7          	jalr	698(ra) # 80005304 <pipewrite>
    80005052:	a045                	j	800050f2 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005054:	02451783          	lh	a5,36(a0)
    80005058:	03079693          	sll	a3,a5,0x30
    8000505c:	92c1                	srl	a3,a3,0x30
    8000505e:	4725                	li	a4,9
    80005060:	0ad76f63          	bltu	a4,a3,8000511e <filewrite+0x124>
    80005064:	0792                	sll	a5,a5,0x4
    80005066:	0001a717          	auipc	a4,0x1a
    8000506a:	4a270713          	add	a4,a4,1186 # 8001f508 <devsw>
    8000506e:	97ba                	add	a5,a5,a4
    80005070:	679c                	ld	a5,8(a5)
    80005072:	cbc5                	beqz	a5,80005122 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80005074:	4505                	li	a0,1
    80005076:	9782                	jalr	a5
    80005078:	a8ad                	j	800050f2 <filewrite+0xf8>
      if(n1 > max)
    8000507a:	00048a9b          	sext.w	s5,s1
        n1 = max;

      // 开始操作事务
      begin_op();
    8000507e:	00000097          	auipc	ra,0x0
    80005082:	9e6080e7          	jalr	-1562(ra) # 80004a64 <begin_op>
      ilock(f->ip);
    80005086:	01893503          	ld	a0,24(s2)
    8000508a:	00001097          	auipc	ra,0x1
    8000508e:	a2c080e7          	jalr	-1492(ra) # 80005ab6 <ilock>
      // 写入数据并更新文件偏移量
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005092:	8756                	mv	a4,s5
    80005094:	02092683          	lw	a3,32(s2)
    80005098:	01698633          	add	a2,s3,s6
    8000509c:	4585                	li	a1,1
    8000509e:	01893503          	ld	a0,24(s2)
    800050a2:	00001097          	auipc	ra,0x1
    800050a6:	dc0080e7          	jalr	-576(ra) # 80005e62 <writei>
    800050aa:	84aa                	mv	s1,a0
    800050ac:	00a05763          	blez	a0,800050ba <filewrite+0xc0>
        f->off += r;
    800050b0:	02092783          	lw	a5,32(s2)
    800050b4:	9fa9                	addw	a5,a5,a0
    800050b6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050ba:	01893503          	ld	a0,24(s2)
    800050be:	00001097          	auipc	ra,0x1
    800050c2:	aba080e7          	jalr	-1350(ra) # 80005b78 <iunlock>
      // 结束操作事务
      end_op();
    800050c6:	00000097          	auipc	ra,0x0
    800050ca:	a18080e7          	jalr	-1512(ra) # 80004ade <end_op>

      // 检查写入是否成功
      if(r != n1){
    800050ce:	009a9f63          	bne	s5,s1,800050ec <filewrite+0xf2>
        // writei出错
        break;
      }
      i += r;
    800050d2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050d6:	0149db63          	bge	s3,s4,800050ec <filewrite+0xf2>
      int n1 = n - i;
    800050da:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800050de:	0004879b          	sext.w	a5,s1
    800050e2:	f8fbdce3          	bge	s7,a5,8000507a <filewrite+0x80>
    800050e6:	84e2                	mv	s1,s8
    800050e8:	bf49                	j	8000507a <filewrite+0x80>
    int i = 0;
    800050ea:	4981                	li	s3,0
    }
    // 如果全部写入成功返回n，否则返回-1
    ret = (i == n ? n : -1);
    800050ec:	033a1d63          	bne	s4,s3,80005126 <filewrite+0x12c>
    800050f0:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050f2:	60a6                	ld	ra,72(sp)
    800050f4:	6406                	ld	s0,64(sp)
    800050f6:	74e2                	ld	s1,56(sp)
    800050f8:	7942                	ld	s2,48(sp)
    800050fa:	79a2                	ld	s3,40(sp)
    800050fc:	7a02                	ld	s4,32(sp)
    800050fe:	6ae2                	ld	s5,24(sp)
    80005100:	6b42                	ld	s6,16(sp)
    80005102:	6ba2                	ld	s7,8(sp)
    80005104:	6c02                	ld	s8,0(sp)
    80005106:	6161                	add	sp,sp,80
    80005108:	8082                	ret
    panic("filewrite");
    8000510a:	00004517          	auipc	a0,0x4
    8000510e:	93e50513          	add	a0,a0,-1730 # 80008a48 <syscalls+0x270>
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	0ce080e7          	jalr	206(ra) # 800011e0 <panic>
    return -1;
    8000511a:	557d                	li	a0,-1
}
    8000511c:	8082                	ret
      return -1;
    8000511e:	557d                	li	a0,-1
    80005120:	bfc9                	j	800050f2 <filewrite+0xf8>
    80005122:	557d                	li	a0,-1
    80005124:	b7f9                	j	800050f2 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80005126:	557d                	li	a0,-1
    80005128:	b7e9                	j	800050f2 <filewrite+0xf8>

000000008000512a <file_lseek>:

// 修改file->offset (只针对FD_FILE类型的文件)
uint32 file_lseek(struct file* file , uint32 offset, int flags)
{
  if(file->type != FD_INODE){
    8000512a:	4118                	lw	a4,0(a0)
    8000512c:	4789                	li	a5,2
    8000512e:	00f70463          	beq	a4,a5,80005136 <file_lseek+0xc>
    return -1;
    80005132:	557d                	li	a0,-1
  }

  file->off = new_offset;
  iunlock(file->ip);
  return new_offset;
}
    80005134:	8082                	ret
{
    80005136:	7179                	add	sp,sp,-48
    80005138:	f406                	sd	ra,40(sp)
    8000513a:	f022                	sd	s0,32(sp)
    8000513c:	ec26                	sd	s1,24(sp)
    8000513e:	e84a                	sd	s2,16(sp)
    80005140:	e44e                	sd	s3,8(sp)
    80005142:	1800                	add	s0,sp,48
    80005144:	89aa                	mv	s3,a0
    80005146:	84ae                	mv	s1,a1
    80005148:	8932                	mv	s2,a2
  ilock(file->ip);
    8000514a:	6d08                	ld	a0,24(a0)
    8000514c:	00001097          	auipc	ra,0x1
    80005150:	96a080e7          	jalr	-1686(ra) # 80005ab6 <ilock>
  switch(flags){
    80005154:	4785                	li	a5,1
    80005156:	00f90f63          	beq	s2,a5,80005174 <file_lseek+0x4a>
    8000515a:	4789                	li	a5,2
    8000515c:	04f90263          	beq	s2,a5,800051a0 <file_lseek+0x76>
    80005160:	00090d63          	beqz	s2,8000517a <file_lseek+0x50>
      iunlock(file->ip);
    80005164:	0189b503          	ld	a0,24(s3)
    80005168:	00001097          	auipc	ra,0x1
    8000516c:	a10080e7          	jalr	-1520(ra) # 80005b78 <iunlock>
      return -1;
    80005170:	557d                	li	a0,-1
    80005172:	a005                	j	80005192 <file_lseek+0x68>
      new_offset = file->off + offset;
    80005174:	0209a783          	lw	a5,32(s3)
    80005178:	9cbd                	addw	s1,s1,a5
  if(new_offset > file->ip->size){
    8000517a:	0189b503          	ld	a0,24(s3)
    8000517e:	457c                	lw	a5,76(a0)
    80005180:	0297e563          	bltu	a5,s1,800051aa <file_lseek+0x80>
  file->off = new_offset;
    80005184:	0299a023          	sw	s1,32(s3)
  iunlock(file->ip);
    80005188:	00001097          	auipc	ra,0x1
    8000518c:	9f0080e7          	jalr	-1552(ra) # 80005b78 <iunlock>
  return new_offset;
    80005190:	8526                	mv	a0,s1
}
    80005192:	70a2                	ld	ra,40(sp)
    80005194:	7402                	ld	s0,32(sp)
    80005196:	64e2                	ld	s1,24(sp)
    80005198:	6942                	ld	s2,16(sp)
    8000519a:	69a2                	ld	s3,8(sp)
    8000519c:	6145                	add	sp,sp,48
    8000519e:	8082                	ret
      new_offset = file->ip->size + offset;
    800051a0:	0189b783          	ld	a5,24(s3)
    800051a4:	47fc                	lw	a5,76(a5)
    800051a6:	9cbd                	addw	s1,s1,a5
      break;
    800051a8:	bfc9                	j	8000517a <file_lseek+0x50>
    iunlock(file->ip);
    800051aa:	00001097          	auipc	ra,0x1
    800051ae:	9ce080e7          	jalr	-1586(ra) # 80005b78 <iunlock>
    return -1;
    800051b2:	557d                	li	a0,-1
    800051b4:	bff9                	j	80005192 <file_lseek+0x68>

00000000800051b6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800051b6:	7179                	add	sp,sp,-48
    800051b8:	f406                	sd	ra,40(sp)
    800051ba:	f022                	sd	s0,32(sp)
    800051bc:	ec26                	sd	s1,24(sp)
    800051be:	e84a                	sd	s2,16(sp)
    800051c0:	e44e                	sd	s3,8(sp)
    800051c2:	e052                	sd	s4,0(sp)
    800051c4:	1800                	add	s0,sp,48
    800051c6:	84aa                	mv	s1,a0
    800051c8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800051ca:	0005b023          	sd	zero,0(a1)
    800051ce:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800051d2:	00000097          	auipc	ra,0x0
    800051d6:	b70080e7          	jalr	-1168(ra) # 80004d42 <filealloc>
    800051da:	e088                	sd	a0,0(s1)
    800051dc:	c559                	beqz	a0,8000526a <pipealloc+0xb4>
    800051de:	00000097          	auipc	ra,0x0
    800051e2:	b64080e7          	jalr	-1180(ra) # 80004d42 <filealloc>
    800051e6:	00aa3023          	sd	a0,0(s4)
    800051ea:	c935                	beqz	a0,8000525e <pipealloc+0xa8>
    goto bad;
  if((pi = (struct pipe*)kalloc(1)) == 0)
    800051ec:	4505                	li	a0,1
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	34e080e7          	jalr	846(ra) # 8000153c <kalloc>
    800051f6:	892a                	mv	s2,a0
    800051f8:	c125                	beqz	a0,80005258 <pipealloc+0xa2>
    goto bad;
  pi->readopen = 1;
    800051fa:	4985                	li	s3,1
    800051fc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005200:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005204:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005208:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000520c:	00004597          	auipc	a1,0x4
    80005210:	84c58593          	add	a1,a1,-1972 # 80008a58 <syscalls+0x280>
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	c98080e7          	jalr	-872(ra) # 80002eac <initlock>
  (*f0)->type = FD_PIPE;
    8000521c:	609c                	ld	a5,0(s1)
    8000521e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005222:	609c                	ld	a5,0(s1)
    80005224:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005228:	609c                	ld	a5,0(s1)
    8000522a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000522e:	609c                	ld	a5,0(s1)
    80005230:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005234:	000a3783          	ld	a5,0(s4)
    80005238:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000523c:	000a3783          	ld	a5,0(s4)
    80005240:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005244:	000a3783          	ld	a5,0(s4)
    80005248:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000524c:	000a3783          	ld	a5,0(s4)
    80005250:	0127b823          	sd	s2,16(a5)
  return 0;
    80005254:	4501                	li	a0,0
    80005256:	a025                	j	8000527e <pipealloc+0xc8>

 bad:
  if(pi)
    kfree((uint64)pi,1);
  if(*f0)
    80005258:	6088                	ld	a0,0(s1)
    8000525a:	e501                	bnez	a0,80005262 <pipealloc+0xac>
    8000525c:	a039                	j	8000526a <pipealloc+0xb4>
    8000525e:	6088                	ld	a0,0(s1)
    80005260:	c51d                	beqz	a0,8000528e <pipealloc+0xd8>
    fileclose(*f0);
    80005262:	00000097          	auipc	ra,0x0
    80005266:	b9c080e7          	jalr	-1124(ra) # 80004dfe <fileclose>
  if(*f1)
    8000526a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000526e:	557d                	li	a0,-1
  if(*f1)
    80005270:	c799                	beqz	a5,8000527e <pipealloc+0xc8>
    fileclose(*f1);
    80005272:	853e                	mv	a0,a5
    80005274:	00000097          	auipc	ra,0x0
    80005278:	b8a080e7          	jalr	-1142(ra) # 80004dfe <fileclose>
  return -1;
    8000527c:	557d                	li	a0,-1
}
    8000527e:	70a2                	ld	ra,40(sp)
    80005280:	7402                	ld	s0,32(sp)
    80005282:	64e2                	ld	s1,24(sp)
    80005284:	6942                	ld	s2,16(sp)
    80005286:	69a2                	ld	s3,8(sp)
    80005288:	6a02                	ld	s4,0(sp)
    8000528a:	6145                	add	sp,sp,48
    8000528c:	8082                	ret
  return -1;
    8000528e:	557d                	li	a0,-1
    80005290:	b7fd                	j	8000527e <pipealloc+0xc8>

0000000080005292 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005292:	1101                	add	sp,sp,-32
    80005294:	ec06                	sd	ra,24(sp)
    80005296:	e822                	sd	s0,16(sp)
    80005298:	e426                	sd	s1,8(sp)
    8000529a:	e04a                	sd	s2,0(sp)
    8000529c:	1000                	add	s0,sp,32
    8000529e:	84aa                	mv	s1,a0
    800052a0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	c9a080e7          	jalr	-870(ra) # 80002f3c <acquire>
  if(writable){
    800052aa:	02090e63          	beqz	s2,800052e6 <pipeclose+0x54>
    pi->writeopen = 0;
    800052ae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800052b2:	21848513          	add	a0,s1,536
    800052b6:	ffffd097          	auipc	ra,0xffffd
    800052ba:	642080e7          	jalr	1602(ra) # 800028f8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800052be:	2204b783          	ld	a5,544(s1)
    800052c2:	eb9d                	bnez	a5,800052f8 <pipeclose+0x66>
    release(&pi->lock);
    800052c4:	8526                	mv	a0,s1
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	d2a080e7          	jalr	-726(ra) # 80002ff0 <release>
    kfree((uint64)pi,1);
    800052ce:	4585                	li	a1,1
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	16a080e7          	jalr	362(ra) # 8000143c <kfree>
  } else
    release(&pi->lock);
}
    800052da:	60e2                	ld	ra,24(sp)
    800052dc:	6442                	ld	s0,16(sp)
    800052de:	64a2                	ld	s1,8(sp)
    800052e0:	6902                	ld	s2,0(sp)
    800052e2:	6105                	add	sp,sp,32
    800052e4:	8082                	ret
    pi->readopen = 0;
    800052e6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800052ea:	21c48513          	add	a0,s1,540
    800052ee:	ffffd097          	auipc	ra,0xffffd
    800052f2:	60a080e7          	jalr	1546(ra) # 800028f8 <wakeup>
    800052f6:	b7e1                	j	800052be <pipeclose+0x2c>
    release(&pi->lock);
    800052f8:	8526                	mv	a0,s1
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	cf6080e7          	jalr	-778(ra) # 80002ff0 <release>
}
    80005302:	bfe1                	j	800052da <pipeclose+0x48>

0000000080005304 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005304:	711d                	add	sp,sp,-96
    80005306:	ec86                	sd	ra,88(sp)
    80005308:	e8a2                	sd	s0,80(sp)
    8000530a:	e4a6                	sd	s1,72(sp)
    8000530c:	e0ca                	sd	s2,64(sp)
    8000530e:	fc4e                	sd	s3,56(sp)
    80005310:	f852                	sd	s4,48(sp)
    80005312:	f456                	sd	s5,40(sp)
    80005314:	f05a                	sd	s6,32(sp)
    80005316:	ec5e                	sd	s7,24(sp)
    80005318:	e862                	sd	s8,16(sp)
    8000531a:	1080                	add	s0,sp,96
    8000531c:	84aa                	mv	s1,a0
    8000531e:	8aae                	mv	s5,a1
    80005320:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005322:	ffffd097          	auipc	ra,0xffffd
    80005326:	dec080e7          	jalr	-532(ra) # 8000210e <myproc>
    8000532a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000532c:	8526                	mv	a0,s1
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	c0e080e7          	jalr	-1010(ra) # 80002f3c <acquire>
  while(i < n){
    80005336:	0b405663          	blez	s4,800053e2 <pipewrite+0xde>
  int i = 0;
    8000533a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pgtbl, &ch, addr + i, 1) == -1)
    8000533c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000533e:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005342:	21c48b93          	add	s7,s1,540
    80005346:	a089                	j	80005388 <pipewrite+0x84>
      release(&pi->lock);
    80005348:	8526                	mv	a0,s1
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	ca6080e7          	jalr	-858(ra) # 80002ff0 <release>
      return -1;
    80005352:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005354:	854a                	mv	a0,s2
    80005356:	60e6                	ld	ra,88(sp)
    80005358:	6446                	ld	s0,80(sp)
    8000535a:	64a6                	ld	s1,72(sp)
    8000535c:	6906                	ld	s2,64(sp)
    8000535e:	79e2                	ld	s3,56(sp)
    80005360:	7a42                	ld	s4,48(sp)
    80005362:	7aa2                	ld	s5,40(sp)
    80005364:	7b02                	ld	s6,32(sp)
    80005366:	6be2                	ld	s7,24(sp)
    80005368:	6c42                	ld	s8,16(sp)
    8000536a:	6125                	add	sp,sp,96
    8000536c:	8082                	ret
      wakeup(&pi->nread);
    8000536e:	8562                	mv	a0,s8
    80005370:	ffffd097          	auipc	ra,0xffffd
    80005374:	588080e7          	jalr	1416(ra) # 800028f8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005378:	85a6                	mv	a1,s1
    8000537a:	855e                	mv	a0,s7
    8000537c:	ffffd097          	auipc	ra,0xffffd
    80005380:	50e080e7          	jalr	1294(ra) # 8000288a <sleep>
  while(i < n){
    80005384:	07495063          	bge	s2,s4,800053e4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005388:	2204a783          	lw	a5,544(s1)
    8000538c:	dfd5                	beqz	a5,80005348 <pipewrite+0x44>
    8000538e:	854e                	mv	a0,s3
    80005390:	ffffd097          	auipc	ra,0xffffd
    80005394:	696080e7          	jalr	1686(ra) # 80002a26 <killed>
    80005398:	f945                	bnez	a0,80005348 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000539a:	2184a783          	lw	a5,536(s1)
    8000539e:	21c4a703          	lw	a4,540(s1)
    800053a2:	2007879b          	addw	a5,a5,512
    800053a6:	fcf704e3          	beq	a4,a5,8000536e <pipewrite+0x6a>
      if(copyin(pr->pgtbl, &ch, addr + i, 1) == -1)
    800053aa:	4685                	li	a3,1
    800053ac:	01590633          	add	a2,s2,s5
    800053b0:	faf40593          	add	a1,s0,-81
    800053b4:	0489b503          	ld	a0,72(s3)
    800053b8:	ffffd097          	auipc	ra,0xffffd
    800053bc:	be6080e7          	jalr	-1050(ra) # 80001f9e <copyin>
    800053c0:	03650263          	beq	a0,s6,800053e4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800053c4:	21c4a783          	lw	a5,540(s1)
    800053c8:	0017871b          	addw	a4,a5,1
    800053cc:	20e4ae23          	sw	a4,540(s1)
    800053d0:	1ff7f793          	and	a5,a5,511
    800053d4:	97a6                	add	a5,a5,s1
    800053d6:	faf44703          	lbu	a4,-81(s0)
    800053da:	00e78c23          	sb	a4,24(a5)
      i++;
    800053de:	2905                	addw	s2,s2,1
    800053e0:	b755                	j	80005384 <pipewrite+0x80>
  int i = 0;
    800053e2:	4901                	li	s2,0
  wakeup(&pi->nread);
    800053e4:	21848513          	add	a0,s1,536
    800053e8:	ffffd097          	auipc	ra,0xffffd
    800053ec:	510080e7          	jalr	1296(ra) # 800028f8 <wakeup>
  release(&pi->lock);
    800053f0:	8526                	mv	a0,s1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	bfe080e7          	jalr	-1026(ra) # 80002ff0 <release>
  return i;
    800053fa:	bfa9                	j	80005354 <pipewrite+0x50>

00000000800053fc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800053fc:	715d                	add	sp,sp,-80
    800053fe:	e486                	sd	ra,72(sp)
    80005400:	e0a2                	sd	s0,64(sp)
    80005402:	fc26                	sd	s1,56(sp)
    80005404:	f84a                	sd	s2,48(sp)
    80005406:	f44e                	sd	s3,40(sp)
    80005408:	f052                	sd	s4,32(sp)
    8000540a:	ec56                	sd	s5,24(sp)
    8000540c:	e85a                	sd	s6,16(sp)
    8000540e:	0880                	add	s0,sp,80
    80005410:	84aa                	mv	s1,a0
    80005412:	892e                	mv	s2,a1
    80005414:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005416:	ffffd097          	auipc	ra,0xffffd
    8000541a:	cf8080e7          	jalr	-776(ra) # 8000210e <myproc>
    8000541e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005420:	8526                	mv	a0,s1
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	b1a080e7          	jalr	-1254(ra) # 80002f3c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000542a:	2184a703          	lw	a4,536(s1)
    8000542e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005432:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005436:	02f71763          	bne	a4,a5,80005464 <piperead+0x68>
    8000543a:	2244a783          	lw	a5,548(s1)
    8000543e:	c39d                	beqz	a5,80005464 <piperead+0x68>
    if(killed(pr)){
    80005440:	8552                	mv	a0,s4
    80005442:	ffffd097          	auipc	ra,0xffffd
    80005446:	5e4080e7          	jalr	1508(ra) # 80002a26 <killed>
    8000544a:	e949                	bnez	a0,800054dc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000544c:	85a6                	mv	a1,s1
    8000544e:	854e                	mv	a0,s3
    80005450:	ffffd097          	auipc	ra,0xffffd
    80005454:	43a080e7          	jalr	1082(ra) # 8000288a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005458:	2184a703          	lw	a4,536(s1)
    8000545c:	21c4a783          	lw	a5,540(s1)
    80005460:	fcf70de3          	beq	a4,a5,8000543a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005464:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pgtbl, addr + i, &ch, 1) == -1)
    80005466:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005468:	05505463          	blez	s5,800054b0 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    8000546c:	2184a783          	lw	a5,536(s1)
    80005470:	21c4a703          	lw	a4,540(s1)
    80005474:	02f70e63          	beq	a4,a5,800054b0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005478:	0017871b          	addw	a4,a5,1
    8000547c:	20e4ac23          	sw	a4,536(s1)
    80005480:	1ff7f793          	and	a5,a5,511
    80005484:	97a6                	add	a5,a5,s1
    80005486:	0187c783          	lbu	a5,24(a5)
    8000548a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pgtbl, addr + i, &ch, 1) == -1)
    8000548e:	4685                	li	a3,1
    80005490:	fbf40613          	add	a2,s0,-65
    80005494:	85ca                	mv	a1,s2
    80005496:	048a3503          	ld	a0,72(s4)
    8000549a:	ffffd097          	auipc	ra,0xffffd
    8000549e:	a72080e7          	jalr	-1422(ra) # 80001f0c <copyout>
    800054a2:	01650763          	beq	a0,s6,800054b0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054a6:	2985                	addw	s3,s3,1
    800054a8:	0905                	add	s2,s2,1
    800054aa:	fd3a91e3          	bne	s5,s3,8000546c <piperead+0x70>
    800054ae:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800054b0:	21c48513          	add	a0,s1,540
    800054b4:	ffffd097          	auipc	ra,0xffffd
    800054b8:	444080e7          	jalr	1092(ra) # 800028f8 <wakeup>
  release(&pi->lock);
    800054bc:	8526                	mv	a0,s1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	b32080e7          	jalr	-1230(ra) # 80002ff0 <release>
  return i;
}
    800054c6:	854e                	mv	a0,s3
    800054c8:	60a6                	ld	ra,72(sp)
    800054ca:	6406                	ld	s0,64(sp)
    800054cc:	74e2                	ld	s1,56(sp)
    800054ce:	7942                	ld	s2,48(sp)
    800054d0:	79a2                	ld	s3,40(sp)
    800054d2:	7a02                	ld	s4,32(sp)
    800054d4:	6ae2                	ld	s5,24(sp)
    800054d6:	6b42                	ld	s6,16(sp)
    800054d8:	6161                	add	sp,sp,80
    800054da:	8082                	ret
      release(&pi->lock);
    800054dc:	8526                	mv	a0,s1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	b12080e7          	jalr	-1262(ra) # 80002ff0 <release>
      return -1;
    800054e6:	59fd                	li	s3,-1
    800054e8:	bff9                	j	800054c6 <piperead+0xca>

00000000800054ea <iget>:
/// @param dev 设备号
/// @param inum inode编号
/// @return 返回指向内存中对应inode的指针，如果没有找到则返回NULL
static struct inode *
iget(uint dev, uint inum)
{
    800054ea:	7179                	add	sp,sp,-48
    800054ec:	f406                	sd	ra,40(sp)
    800054ee:	f022                	sd	s0,32(sp)
    800054f0:	ec26                	sd	s1,24(sp)
    800054f2:	e84a                	sd	s2,16(sp)
    800054f4:	e44e                	sd	s3,8(sp)
    800054f6:	e052                	sd	s4,0(sp)
    800054f8:	1800                	add	s0,sp,48
    800054fa:	89aa                	mv	s3,a0
    800054fc:	8a2e                	mv	s4,a1
  struct inode *ip, *empty;

  acquire(&itable.lock);
    800054fe:	0001b517          	auipc	a0,0x1b
    80005502:	08250513          	add	a0,a0,130 # 80020580 <itable>
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	a36080e7          	jalr	-1482(ra) # 80002f3c <acquire>

  // 检查inode是否已经在表中
  empty = 0;
    8000550e:	4901                	li	s2,0
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80005510:	0001b497          	auipc	s1,0x1b
    80005514:	08848493          	add	s1,s1,136 # 80020598 <itable+0x18>
    80005518:	0001d697          	auipc	a3,0x1d
    8000551c:	b1068693          	add	a3,a3,-1264 # 80022028 <end>
    80005520:	a039                	j	8000552e <iget+0x44>
      ip->ref++;
      release(&itable.lock);
      return ip;
    }
    // 记住空闲槽位
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    80005522:	02090b63          	beqz	s2,80005558 <iget+0x6e>
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80005526:	08848493          	add	s1,s1,136
    8000552a:	02d48a63          	beq	s1,a3,8000555e <iget+0x74>
    if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    8000552e:	449c                	lw	a5,8(s1)
    80005530:	fef059e3          	blez	a5,80005522 <iget+0x38>
    80005534:	4098                	lw	a4,0(s1)
    80005536:	ff3716e3          	bne	a4,s3,80005522 <iget+0x38>
    8000553a:	40d8                	lw	a4,4(s1)
    8000553c:	ff4713e3          	bne	a4,s4,80005522 <iget+0x38>
      ip->ref++;
    80005540:	2785                	addw	a5,a5,1
    80005542:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80005544:	0001b517          	auipc	a0,0x1b
    80005548:	03c50513          	add	a0,a0,60 # 80020580 <itable>
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	aa4080e7          	jalr	-1372(ra) # 80002ff0 <release>
      return ip;
    80005554:	8926                	mv	s2,s1
    80005556:	a03d                	j	80005584 <iget+0x9a>
    if (empty == 0 && ip->ref == 0) // Remember empty slot.
    80005558:	f7f9                	bnez	a5,80005526 <iget+0x3c>
    8000555a:	8926                	mv	s2,s1
    8000555c:	b7e9                	j	80005526 <iget+0x3c>
      empty = ip;
  }

  // 回收一个inode表项
  if (empty == 0)
    8000555e:	02090c63          	beqz	s2,80005596 <iget+0xac>
    panic("iget: no inodes");

  // 初始化新的inode表项
  ip = empty;
  ip->dev = dev;
    80005562:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80005566:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000556a:	4785                	li	a5,1
    8000556c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80005570:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80005574:	0001b517          	auipc	a0,0x1b
    80005578:	00c50513          	add	a0,a0,12 # 80020580 <itable>
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	a74080e7          	jalr	-1420(ra) # 80002ff0 <release>

  return ip;
}
    80005584:	854a                	mv	a0,s2
    80005586:	70a2                	ld	ra,40(sp)
    80005588:	7402                	ld	s0,32(sp)
    8000558a:	64e2                	ld	s1,24(sp)
    8000558c:	6942                	ld	s2,16(sp)
    8000558e:	69a2                	ld	s3,8(sp)
    80005590:	6a02                	ld	s4,0(sp)
    80005592:	6145                	add	sp,sp,48
    80005594:	8082                	ret
    panic("iget: no inodes");
    80005596:	00003517          	auipc	a0,0x3
    8000559a:	4ca50513          	add	a0,a0,1226 # 80008a60 <syscalls+0x288>
    8000559e:	ffffc097          	auipc	ra,0xffffc
    800055a2:	c42080e7          	jalr	-958(ra) # 800011e0 <panic>

00000000800055a6 <fsinit>:
{
    800055a6:	7179                	add	sp,sp,-48
    800055a8:	f406                	sd	ra,40(sp)
    800055aa:	f022                	sd	s0,32(sp)
    800055ac:	ec26                	sd	s1,24(sp)
    800055ae:	e84a                	sd	s2,16(sp)
    800055b0:	e44e                	sd	s3,8(sp)
    800055b2:	1800                	add	s0,sp,48
    800055b4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800055b6:	4585                	li	a1,1
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	0a2080e7          	jalr	162(ra) # 8000465a <bread>
    800055c0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800055c2:	0001b997          	auipc	s3,0x1b
    800055c6:	f9e98993          	add	s3,s3,-98 # 80020560 <sb>
    800055ca:	02000613          	li	a2,32
    800055ce:	05850593          	add	a1,a0,88
    800055d2:	854e                	mv	a0,s3
    800055d4:	ffffc097          	auipc	ra,0xffffc
    800055d8:	a20080e7          	jalr	-1504(ra) # 80000ff4 <memmove>
  brelse(bp);
    800055dc:	8526                	mv	a0,s1
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	1ac080e7          	jalr	428(ra) # 8000478a <brelse>
  if (sb.magic != FSMAGIC)
    800055e6:	0009a703          	lw	a4,0(s3)
    800055ea:	102037b7          	lui	a5,0x10203
    800055ee:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800055f2:	02f71263          	bne	a4,a5,80005616 <fsinit+0x70>
  initlog(dev, &sb);
    800055f6:	0001b597          	auipc	a1,0x1b
    800055fa:	f6a58593          	add	a1,a1,-150 # 80020560 <sb>
    800055fe:	854a                	mv	a0,s2
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	3cc080e7          	jalr	972(ra) # 800049cc <initlog>
}
    80005608:	70a2                	ld	ra,40(sp)
    8000560a:	7402                	ld	s0,32(sp)
    8000560c:	64e2                	ld	s1,24(sp)
    8000560e:	6942                	ld	s2,16(sp)
    80005610:	69a2                	ld	s3,8(sp)
    80005612:	6145                	add	sp,sp,48
    80005614:	8082                	ret
    panic("invalid file system");
    80005616:	00003517          	auipc	a0,0x3
    8000561a:	45a50513          	add	a0,a0,1114 # 80008a70 <syscalls+0x298>
    8000561e:	ffffc097          	auipc	ra,0xffffc
    80005622:	bc2080e7          	jalr	-1086(ra) # 800011e0 <panic>

0000000080005626 <balloc>:
{
    80005626:	711d                	add	sp,sp,-96
    80005628:	ec86                	sd	ra,88(sp)
    8000562a:	e8a2                	sd	s0,80(sp)
    8000562c:	e4a6                	sd	s1,72(sp)
    8000562e:	e0ca                	sd	s2,64(sp)
    80005630:	fc4e                	sd	s3,56(sp)
    80005632:	f852                	sd	s4,48(sp)
    80005634:	f456                	sd	s5,40(sp)
    80005636:	f05a                	sd	s6,32(sp)
    80005638:	ec5e                	sd	s7,24(sp)
    8000563a:	e862                	sd	s8,16(sp)
    8000563c:	e466                	sd	s9,8(sp)
    8000563e:	1080                	add	s0,sp,96
  for (b = 0; b < sb.size; b += BPB)
    80005640:	0001b797          	auipc	a5,0x1b
    80005644:	f247a783          	lw	a5,-220(a5) # 80020564 <sb+0x4>
    80005648:	cff5                	beqz	a5,80005744 <balloc+0x11e>
    8000564a:	8baa                	mv	s7,a0
    8000564c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000564e:	0001bb17          	auipc	s6,0x1b
    80005652:	f12b0b13          	add	s6,s6,-238 # 80020560 <sb>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80005656:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80005658:	4985                	li	s3,1
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    8000565a:	6a09                	lui	s4,0x2
  for (b = 0; b < sb.size; b += BPB)
    8000565c:	6c89                	lui	s9,0x2
    8000565e:	a061                	j	800056e6 <balloc+0xc0>
        bp->data[bi / 8] |= m; // 在data的相应位置上设置为1，表示该块已被分配
    80005660:	97ca                	add	a5,a5,s2
    80005662:	8e55                	or	a2,a2,a3
    80005664:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80005668:	854a                	mv	a0,s2
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	5cc080e7          	jalr	1484(ra) # 80004c36 <log_write>
        brelse(bp);
    80005672:	854a                	mv	a0,s2
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	116080e7          	jalr	278(ra) # 8000478a <brelse>
  bp = bread(dev, bno);
    8000567c:	85a6                	mv	a1,s1
    8000567e:	855e                	mv	a0,s7
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	fda080e7          	jalr	-38(ra) # 8000465a <bread>
    80005688:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000568a:	40000613          	li	a2,1024
    8000568e:	4581                	li	a1,0
    80005690:	05850513          	add	a0,a0,88
    80005694:	ffffc097          	auipc	ra,0xffffc
    80005698:	904080e7          	jalr	-1788(ra) # 80000f98 <memset>
  log_write(bp);
    8000569c:	854a                	mv	a0,s2
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	598080e7          	jalr	1432(ra) # 80004c36 <log_write>
  brelse(bp);
    800056a6:	854a                	mv	a0,s2
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	0e2080e7          	jalr	226(ra) # 8000478a <brelse>
}
    800056b0:	8526                	mv	a0,s1
    800056b2:	60e6                	ld	ra,88(sp)
    800056b4:	6446                	ld	s0,80(sp)
    800056b6:	64a6                	ld	s1,72(sp)
    800056b8:	6906                	ld	s2,64(sp)
    800056ba:	79e2                	ld	s3,56(sp)
    800056bc:	7a42                	ld	s4,48(sp)
    800056be:	7aa2                	ld	s5,40(sp)
    800056c0:	7b02                	ld	s6,32(sp)
    800056c2:	6be2                	ld	s7,24(sp)
    800056c4:	6c42                	ld	s8,16(sp)
    800056c6:	6ca2                	ld	s9,8(sp)
    800056c8:	6125                	add	sp,sp,96
    800056ca:	8082                	ret
    brelse(bp);
    800056cc:	854a                	mv	a0,s2
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	0bc080e7          	jalr	188(ra) # 8000478a <brelse>
  for (b = 0; b < sb.size; b += BPB)
    800056d6:	015c87bb          	addw	a5,s9,s5
    800056da:	00078a9b          	sext.w	s5,a5
    800056de:	004b2703          	lw	a4,4(s6)
    800056e2:	06eaf163          	bgeu	s5,a4,80005744 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800056e6:	41fad79b          	sraw	a5,s5,0x1f
    800056ea:	0137d79b          	srlw	a5,a5,0x13
    800056ee:	015787bb          	addw	a5,a5,s5
    800056f2:	40d7d79b          	sraw	a5,a5,0xd
    800056f6:	01cb2583          	lw	a1,28(s6)
    800056fa:	9dbd                	addw	a1,a1,a5
    800056fc:	855e                	mv	a0,s7
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	f5c080e7          	jalr	-164(ra) # 8000465a <bread>
    80005706:	892a                	mv	s2,a0
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80005708:	004b2503          	lw	a0,4(s6)
    8000570c:	000a849b          	sext.w	s1,s5
    80005710:	8762                	mv	a4,s8
    80005712:	faa4fde3          	bgeu	s1,a0,800056cc <balloc+0xa6>
      m = 1 << (bi % 8);
    80005716:	00777693          	and	a3,a4,7
    8000571a:	00d996bb          	sllw	a3,s3,a3
      if ((bp->data[bi / 8] & m) == 0)
    8000571e:	41f7579b          	sraw	a5,a4,0x1f
    80005722:	01d7d79b          	srlw	a5,a5,0x1d
    80005726:	9fb9                	addw	a5,a5,a4
    80005728:	4037d79b          	sraw	a5,a5,0x3
    8000572c:	00f90633          	add	a2,s2,a5
    80005730:	05864603          	lbu	a2,88(a2)
    80005734:	00c6f5b3          	and	a1,a3,a2
    80005738:	d585                	beqz	a1,80005660 <balloc+0x3a>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    8000573a:	2705                	addw	a4,a4,1
    8000573c:	2485                	addw	s1,s1,1
    8000573e:	fd471ae3          	bne	a4,s4,80005712 <balloc+0xec>
    80005742:	b769                	j	800056cc <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80005744:	00003517          	auipc	a0,0x3
    80005748:	34450513          	add	a0,a0,836 # 80008a88 <syscalls+0x2b0>
    8000574c:	ffffc097          	auipc	ra,0xffffc
    80005750:	ade080e7          	jalr	-1314(ra) # 8000122a <printf>
  return 0;
    80005754:	4481                	li	s1,0
    80005756:	bfa9                	j	800056b0 <balloc+0x8a>

0000000080005758 <bmap>:
/// @brief 返回inode ip中第n个块的磁盘块地址。
/// 如果没有这样的块，bmap会分配一个。
/// 如果磁盘空间不足则返回0。
static uint
bmap(struct inode *ip, uint bn)
{
    80005758:	7179                	add	sp,sp,-48
    8000575a:	f406                	sd	ra,40(sp)
    8000575c:	f022                	sd	s0,32(sp)
    8000575e:	ec26                	sd	s1,24(sp)
    80005760:	e84a                	sd	s2,16(sp)
    80005762:	e44e                	sd	s3,8(sp)
    80005764:	e052                	sd	s4,0(sp)
    80005766:	1800                	add	s0,sp,48
    80005768:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  // 直接块
  if (bn < NDIRECT)
    8000576a:	47ad                	li	a5,11
    8000576c:	02b7e863          	bltu	a5,a1,8000579c <bmap+0x44>
  {
    // 如果该直接块未分配，分配一个
    if ((addr = ip->addrs[bn]) == 0)
    80005770:	02059793          	sll	a5,a1,0x20
    80005774:	01e7d593          	srl	a1,a5,0x1e
    80005778:	00b504b3          	add	s1,a0,a1
    8000577c:	0504a903          	lw	s2,80(s1)
    80005780:	06091e63          	bnez	s2,800057fc <bmap+0xa4>
    {
      addr = balloc(ip->dev);
    80005784:	4108                	lw	a0,0(a0)
    80005786:	00000097          	auipc	ra,0x0
    8000578a:	ea0080e7          	jalr	-352(ra) # 80005626 <balloc>
    8000578e:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80005792:	06090563          	beqz	s2,800057fc <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80005796:	0524a823          	sw	s2,80(s1)
    8000579a:	a08d                	j	800057fc <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000579c:	ff45849b          	addw	s1,a1,-12
    800057a0:	0004871b          	sext.w	a4,s1

  // 间接块
  if (bn < NINDIRECT)
    800057a4:	0ff00793          	li	a5,255
    800057a8:	08e7e563          	bltu	a5,a4,80005832 <bmap+0xda>
  {
    // 加载间接块，如果需要则分配
    if ((addr = ip->addrs[NDIRECT]) == 0)
    800057ac:	08052903          	lw	s2,128(a0)
    800057b0:	00091d63          	bnez	s2,800057ca <bmap+0x72>
    {
      addr = balloc(ip->dev);
    800057b4:	4108                	lw	a0,0(a0)
    800057b6:	00000097          	auipc	ra,0x0
    800057ba:	e70080e7          	jalr	-400(ra) # 80005626 <balloc>
    800057be:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    800057c2:	02090d63          	beqz	s2,800057fc <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800057c6:	0929a023          	sw	s2,128(s3)
    }
    // 读取间接块
    bp = bread(ip->dev, addr);
    800057ca:	85ca                	mv	a1,s2
    800057cc:	0009a503          	lw	a0,0(s3)
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	e8a080e7          	jalr	-374(ra) # 8000465a <bread>
    800057d8:	8a2a                	mv	s4,a0
    a = (uint *)bp->data;
    800057da:	05850793          	add	a5,a0,88
    // 检查间接块中的目标块是否已分配
    if ((addr = a[bn]) == 0)
    800057de:	02049713          	sll	a4,s1,0x20
    800057e2:	01e75593          	srl	a1,a4,0x1e
    800057e6:	00b784b3          	add	s1,a5,a1
    800057ea:	0004a903          	lw	s2,0(s1)
    800057ee:	02090063          	beqz	s2,8000580e <bmap+0xb6>
        a[bn] = addr;
        log_write(bp);
      }
    }
    // 释放间接块缓冲区
    brelse(bp);
    800057f2:	8552                	mv	a0,s4
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	f96080e7          	jalr	-106(ra) # 8000478a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800057fc:	854a                	mv	a0,s2
    800057fe:	70a2                	ld	ra,40(sp)
    80005800:	7402                	ld	s0,32(sp)
    80005802:	64e2                	ld	s1,24(sp)
    80005804:	6942                	ld	s2,16(sp)
    80005806:	69a2                	ld	s3,8(sp)
    80005808:	6a02                	ld	s4,0(sp)
    8000580a:	6145                	add	sp,sp,48
    8000580c:	8082                	ret
      addr = balloc(ip->dev);
    8000580e:	0009a503          	lw	a0,0(s3)
    80005812:	00000097          	auipc	ra,0x0
    80005816:	e14080e7          	jalr	-492(ra) # 80005626 <balloc>
    8000581a:	0005091b          	sext.w	s2,a0
      if (addr)
    8000581e:	fc090ae3          	beqz	s2,800057f2 <bmap+0x9a>
        a[bn] = addr;
    80005822:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80005826:	8552                	mv	a0,s4
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	40e080e7          	jalr	1038(ra) # 80004c36 <log_write>
    80005830:	b7c9                	j	800057f2 <bmap+0x9a>
  panic("bmap: out of range");
    80005832:	00003517          	auipc	a0,0x3
    80005836:	26e50513          	add	a0,a0,622 # 80008aa0 <syscalls+0x2c8>
    8000583a:	ffffc097          	auipc	ra,0xffffc
    8000583e:	9a6080e7          	jalr	-1626(ra) # 800011e0 <panic>

0000000080005842 <bfree>:
{
    80005842:	1101                	add	sp,sp,-32
    80005844:	ec06                	sd	ra,24(sp)
    80005846:	e822                	sd	s0,16(sp)
    80005848:	e426                	sd	s1,8(sp)
    8000584a:	e04a                	sd	s2,0(sp)
    8000584c:	1000                	add	s0,sp,32
    8000584e:	84ae                	mv	s1,a1
  bp = bread(dev, BBLOCK(b, sb));
    80005850:	00d5d59b          	srlw	a1,a1,0xd
    80005854:	0001b797          	auipc	a5,0x1b
    80005858:	d287a783          	lw	a5,-728(a5) # 8002057c <sb+0x1c>
    8000585c:	9dbd                	addw	a1,a1,a5
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	dfc080e7          	jalr	-516(ra) # 8000465a <bread>
  m = 1 << (bi % 8);
    80005866:	0074f713          	and	a4,s1,7
    8000586a:	4785                	li	a5,1
    8000586c:	00e797bb          	sllw	a5,a5,a4
  if ((bp->data[bi / 8] & m) == 0)
    80005870:	14ce                	sll	s1,s1,0x33
    80005872:	90d9                	srl	s1,s1,0x36
    80005874:	00950733          	add	a4,a0,s1
    80005878:	05874703          	lbu	a4,88(a4)
    8000587c:	00e7f6b3          	and	a3,a5,a4
    80005880:	c69d                	beqz	a3,800058ae <bfree+0x6c>
    80005882:	892a                	mv	s2,a0
  bp->data[bi / 8] &= ~m;
    80005884:	94aa                	add	s1,s1,a0
    80005886:	fff7c793          	not	a5,a5
    8000588a:	8f7d                	and	a4,a4,a5
    8000588c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	3a6080e7          	jalr	934(ra) # 80004c36 <log_write>
  brelse(bp);
    80005898:	854a                	mv	a0,s2
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	ef0080e7          	jalr	-272(ra) # 8000478a <brelse>
}
    800058a2:	60e2                	ld	ra,24(sp)
    800058a4:	6442                	ld	s0,16(sp)
    800058a6:	64a2                	ld	s1,8(sp)
    800058a8:	6902                	ld	s2,0(sp)
    800058aa:	6105                	add	sp,sp,32
    800058ac:	8082                	ret
    panic("freeing free block");
    800058ae:	00003517          	auipc	a0,0x3
    800058b2:	20a50513          	add	a0,a0,522 # 80008ab8 <syscalls+0x2e0>
    800058b6:	ffffc097          	auipc	ra,0xffffc
    800058ba:	92a080e7          	jalr	-1750(ra) # 800011e0 <panic>

00000000800058be <iinit>:
{
    800058be:	7179                	add	sp,sp,-48
    800058c0:	f406                	sd	ra,40(sp)
    800058c2:	f022                	sd	s0,32(sp)
    800058c4:	ec26                	sd	s1,24(sp)
    800058c6:	e84a                	sd	s2,16(sp)
    800058c8:	e44e                	sd	s3,8(sp)
    800058ca:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    800058cc:	00003597          	auipc	a1,0x3
    800058d0:	20458593          	add	a1,a1,516 # 80008ad0 <syscalls+0x2f8>
    800058d4:	0001b517          	auipc	a0,0x1b
    800058d8:	cac50513          	add	a0,a0,-852 # 80020580 <itable>
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	5d0080e7          	jalr	1488(ra) # 80002eac <initlock>
  for (i = 0; i < NINODE; i++)
    800058e4:	0001b497          	auipc	s1,0x1b
    800058e8:	cc448493          	add	s1,s1,-828 # 800205a8 <itable+0x28>
    800058ec:	0001c997          	auipc	s3,0x1c
    800058f0:	74c98993          	add	s3,s3,1868 # 80022038 <end+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800058f4:	00003917          	auipc	s2,0x3
    800058f8:	1e490913          	add	s2,s2,484 # 80008ad8 <syscalls+0x300>
    800058fc:	85ca                	mv	a1,s2
    800058fe:	8526                	mv	a0,s1
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	482080e7          	jalr	1154(ra) # 80002d82 <initsleeplock>
  for (i = 0; i < NINODE; i++)
    80005908:	08848493          	add	s1,s1,136
    8000590c:	ff3498e3          	bne	s1,s3,800058fc <iinit+0x3e>
}
    80005910:	70a2                	ld	ra,40(sp)
    80005912:	7402                	ld	s0,32(sp)
    80005914:	64e2                	ld	s1,24(sp)
    80005916:	6942                	ld	s2,16(sp)
    80005918:	69a2                	ld	s3,8(sp)
    8000591a:	6145                	add	sp,sp,48
    8000591c:	8082                	ret

000000008000591e <ialloc>:
{
    8000591e:	7139                	add	sp,sp,-64
    80005920:	fc06                	sd	ra,56(sp)
    80005922:	f822                	sd	s0,48(sp)
    80005924:	f426                	sd	s1,40(sp)
    80005926:	f04a                	sd	s2,32(sp)
    80005928:	ec4e                	sd	s3,24(sp)
    8000592a:	e852                	sd	s4,16(sp)
    8000592c:	e456                	sd	s5,8(sp)
    8000592e:	e05a                	sd	s6,0(sp)
    80005930:	0080                	add	s0,sp,64
  for (inum = 1; inum < sb.ninodes; inum++)
    80005932:	0001b717          	auipc	a4,0x1b
    80005936:	c3a72703          	lw	a4,-966(a4) # 8002056c <sb+0xc>
    8000593a:	4785                	li	a5,1
    8000593c:	04e7f863          	bgeu	a5,a4,8000598c <ialloc+0x6e>
    80005940:	8aaa                	mv	s5,a0
    80005942:	8b2e                	mv	s6,a1
    80005944:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80005946:	0001ba17          	auipc	s4,0x1b
    8000594a:	c1aa0a13          	add	s4,s4,-998 # 80020560 <sb>
    8000594e:	00495593          	srl	a1,s2,0x4
    80005952:	018a2783          	lw	a5,24(s4)
    80005956:	9dbd                	addw	a1,a1,a5
    80005958:	8556                	mv	a0,s5
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	d00080e7          	jalr	-768(ra) # 8000465a <bread>
    80005962:	84aa                	mv	s1,a0
    dip = (struct dinode *)bp->data + inum % IPB;
    80005964:	05850993          	add	s3,a0,88
    80005968:	00f97793          	and	a5,s2,15
    8000596c:	079a                	sll	a5,a5,0x6
    8000596e:	99be                	add	s3,s3,a5
    if (dip->type == 0)
    80005970:	00099783          	lh	a5,0(s3)
    80005974:	cf9d                	beqz	a5,800059b2 <ialloc+0x94>
    brelse(bp);
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	e14080e7          	jalr	-492(ra) # 8000478a <brelse>
  for (inum = 1; inum < sb.ninodes; inum++)
    8000597e:	0905                	add	s2,s2,1
    80005980:	00ca2703          	lw	a4,12(s4)
    80005984:	0009079b          	sext.w	a5,s2
    80005988:	fce7e3e3          	bltu	a5,a4,8000594e <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000598c:	00003517          	auipc	a0,0x3
    80005990:	15450513          	add	a0,a0,340 # 80008ae0 <syscalls+0x308>
    80005994:	ffffc097          	auipc	ra,0xffffc
    80005998:	896080e7          	jalr	-1898(ra) # 8000122a <printf>
  return 0;
    8000599c:	4501                	li	a0,0
}
    8000599e:	70e2                	ld	ra,56(sp)
    800059a0:	7442                	ld	s0,48(sp)
    800059a2:	74a2                	ld	s1,40(sp)
    800059a4:	7902                	ld	s2,32(sp)
    800059a6:	69e2                	ld	s3,24(sp)
    800059a8:	6a42                	ld	s4,16(sp)
    800059aa:	6aa2                	ld	s5,8(sp)
    800059ac:	6b02                	ld	s6,0(sp)
    800059ae:	6121                	add	sp,sp,64
    800059b0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800059b2:	04000613          	li	a2,64
    800059b6:	4581                	li	a1,0
    800059b8:	854e                	mv	a0,s3
    800059ba:	ffffb097          	auipc	ra,0xffffb
    800059be:	5de080e7          	jalr	1502(ra) # 80000f98 <memset>
      dip->type = type;
    800059c2:	01699023          	sh	s6,0(s3)
      log_write(bp); // mark it allocated on the disk
    800059c6:	8526                	mv	a0,s1
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	26e080e7          	jalr	622(ra) # 80004c36 <log_write>
      brelse(bp);
    800059d0:	8526                	mv	a0,s1
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	db8080e7          	jalr	-584(ra) # 8000478a <brelse>
      return iget(dev, inum);
    800059da:	0009059b          	sext.w	a1,s2
    800059de:	8556                	mv	a0,s5
    800059e0:	00000097          	auipc	ra,0x0
    800059e4:	b0a080e7          	jalr	-1270(ra) # 800054ea <iget>
    800059e8:	bf5d                	j	8000599e <ialloc+0x80>

00000000800059ea <iupdate>:
{
    800059ea:	1101                	add	sp,sp,-32
    800059ec:	ec06                	sd	ra,24(sp)
    800059ee:	e822                	sd	s0,16(sp)
    800059f0:	e426                	sd	s1,8(sp)
    800059f2:	e04a                	sd	s2,0(sp)
    800059f4:	1000                	add	s0,sp,32
    800059f6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800059f8:	415c                	lw	a5,4(a0)
    800059fa:	0047d79b          	srlw	a5,a5,0x4
    800059fe:	0001b597          	auipc	a1,0x1b
    80005a02:	b7a5a583          	lw	a1,-1158(a1) # 80020578 <sb+0x18>
    80005a06:	9dbd                	addw	a1,a1,a5
    80005a08:	4108                	lw	a0,0(a0)
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	c50080e7          	jalr	-944(ra) # 8000465a <bread>
    80005a12:	892a                	mv	s2,a0
  dip = (struct dinode *)bp->data + ip->inum % IPB;
    80005a14:	05850793          	add	a5,a0,88
    80005a18:	40d8                	lw	a4,4(s1)
    80005a1a:	8b3d                	and	a4,a4,15
    80005a1c:	071a                	sll	a4,a4,0x6
    80005a1e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80005a20:	04449703          	lh	a4,68(s1)
    80005a24:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80005a28:	04649703          	lh	a4,70(s1)
    80005a2c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80005a30:	04849703          	lh	a4,72(s1)
    80005a34:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80005a38:	04a49703          	lh	a4,74(s1)
    80005a3c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80005a40:	44f8                	lw	a4,76(s1)
    80005a42:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80005a44:	03400613          	li	a2,52
    80005a48:	05048593          	add	a1,s1,80
    80005a4c:	00c78513          	add	a0,a5,12
    80005a50:	ffffb097          	auipc	ra,0xffffb
    80005a54:	5a4080e7          	jalr	1444(ra) # 80000ff4 <memmove>
  log_write(bp);
    80005a58:	854a                	mv	a0,s2
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	1dc080e7          	jalr	476(ra) # 80004c36 <log_write>
  brelse(bp);
    80005a62:	854a                	mv	a0,s2
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	d26080e7          	jalr	-730(ra) # 8000478a <brelse>
}
    80005a6c:	60e2                	ld	ra,24(sp)
    80005a6e:	6442                	ld	s0,16(sp)
    80005a70:	64a2                	ld	s1,8(sp)
    80005a72:	6902                	ld	s2,0(sp)
    80005a74:	6105                	add	sp,sp,32
    80005a76:	8082                	ret

0000000080005a78 <idup>:
{
    80005a78:	1101                	add	sp,sp,-32
    80005a7a:	ec06                	sd	ra,24(sp)
    80005a7c:	e822                	sd	s0,16(sp)
    80005a7e:	e426                	sd	s1,8(sp)
    80005a80:	1000                	add	s0,sp,32
    80005a82:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80005a84:	0001b517          	auipc	a0,0x1b
    80005a88:	afc50513          	add	a0,a0,-1284 # 80020580 <itable>
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	4b0080e7          	jalr	1200(ra) # 80002f3c <acquire>
  ip->ref++;
    80005a94:	449c                	lw	a5,8(s1)
    80005a96:	2785                	addw	a5,a5,1
    80005a98:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80005a9a:	0001b517          	auipc	a0,0x1b
    80005a9e:	ae650513          	add	a0,a0,-1306 # 80020580 <itable>
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	54e080e7          	jalr	1358(ra) # 80002ff0 <release>
}
    80005aaa:	8526                	mv	a0,s1
    80005aac:	60e2                	ld	ra,24(sp)
    80005aae:	6442                	ld	s0,16(sp)
    80005ab0:	64a2                	ld	s1,8(sp)
    80005ab2:	6105                	add	sp,sp,32
    80005ab4:	8082                	ret

0000000080005ab6 <ilock>:
{
    80005ab6:	1101                	add	sp,sp,-32
    80005ab8:	ec06                	sd	ra,24(sp)
    80005aba:	e822                	sd	s0,16(sp)
    80005abc:	e426                	sd	s1,8(sp)
    80005abe:	e04a                	sd	s2,0(sp)
    80005ac0:	1000                	add	s0,sp,32
  if (ip == 0 || ip->ref < 1)
    80005ac2:	c115                	beqz	a0,80005ae6 <ilock+0x30>
    80005ac4:	84aa                	mv	s1,a0
    80005ac6:	451c                	lw	a5,8(a0)
    80005ac8:	00f05f63          	blez	a5,80005ae6 <ilock+0x30>
  acquiresleep(&ip->lock);
    80005acc:	0541                	add	a0,a0,16
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	2ee080e7          	jalr	750(ra) # 80002dbc <acquiresleep>
  if (ip->valid == 0)
    80005ad6:	40bc                	lw	a5,64(s1)
    80005ad8:	cf99                	beqz	a5,80005af6 <ilock+0x40>
}
    80005ada:	60e2                	ld	ra,24(sp)
    80005adc:	6442                	ld	s0,16(sp)
    80005ade:	64a2                	ld	s1,8(sp)
    80005ae0:	6902                	ld	s2,0(sp)
    80005ae2:	6105                	add	sp,sp,32
    80005ae4:	8082                	ret
    panic("ilock");
    80005ae6:	00003517          	auipc	a0,0x3
    80005aea:	01250513          	add	a0,a0,18 # 80008af8 <syscalls+0x320>
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	6f2080e7          	jalr	1778(ra) # 800011e0 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80005af6:	40dc                	lw	a5,4(s1)
    80005af8:	0047d79b          	srlw	a5,a5,0x4
    80005afc:	0001b597          	auipc	a1,0x1b
    80005b00:	a7c5a583          	lw	a1,-1412(a1) # 80020578 <sb+0x18>
    80005b04:	9dbd                	addw	a1,a1,a5
    80005b06:	4088                	lw	a0,0(s1)
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	b52080e7          	jalr	-1198(ra) # 8000465a <bread>
    80005b10:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + ip->inum % IPB;
    80005b12:	05850593          	add	a1,a0,88
    80005b16:	40dc                	lw	a5,4(s1)
    80005b18:	8bbd                	and	a5,a5,15
    80005b1a:	079a                	sll	a5,a5,0x6
    80005b1c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80005b1e:	00059783          	lh	a5,0(a1)
    80005b22:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80005b26:	00259783          	lh	a5,2(a1)
    80005b2a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80005b2e:	00459783          	lh	a5,4(a1)
    80005b32:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80005b36:	00659783          	lh	a5,6(a1)
    80005b3a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80005b3e:	459c                	lw	a5,8(a1)
    80005b40:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80005b42:	03400613          	li	a2,52
    80005b46:	05b1                	add	a1,a1,12
    80005b48:	05048513          	add	a0,s1,80
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	4a8080e7          	jalr	1192(ra) # 80000ff4 <memmove>
    brelse(bp);
    80005b54:	854a                	mv	a0,s2
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	c34080e7          	jalr	-972(ra) # 8000478a <brelse>
    ip->valid = 1;
    80005b5e:	4785                	li	a5,1
    80005b60:	c0bc                	sw	a5,64(s1)
    if (ip->type == 0)
    80005b62:	04449783          	lh	a5,68(s1)
    80005b66:	fbb5                	bnez	a5,80005ada <ilock+0x24>
      panic("ilock: no type");
    80005b68:	00003517          	auipc	a0,0x3
    80005b6c:	f9850513          	add	a0,a0,-104 # 80008b00 <syscalls+0x328>
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	670080e7          	jalr	1648(ra) # 800011e0 <panic>

0000000080005b78 <iunlock>:
{
    80005b78:	1101                	add	sp,sp,-32
    80005b7a:	ec06                	sd	ra,24(sp)
    80005b7c:	e822                	sd	s0,16(sp)
    80005b7e:	e426                	sd	s1,8(sp)
    80005b80:	e04a                	sd	s2,0(sp)
    80005b82:	1000                	add	s0,sp,32
  if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80005b84:	c905                	beqz	a0,80005bb4 <iunlock+0x3c>
    80005b86:	84aa                	mv	s1,a0
    80005b88:	01050913          	add	s2,a0,16
    80005b8c:	854a                	mv	a0,s2
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	2c8080e7          	jalr	712(ra) # 80002e56 <holdingsleep>
    80005b96:	cd19                	beqz	a0,80005bb4 <iunlock+0x3c>
    80005b98:	449c                	lw	a5,8(s1)
    80005b9a:	00f05d63          	blez	a5,80005bb4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80005b9e:	854a                	mv	a0,s2
    80005ba0:	ffffd097          	auipc	ra,0xffffd
    80005ba4:	272080e7          	jalr	626(ra) # 80002e12 <releasesleep>
}
    80005ba8:	60e2                	ld	ra,24(sp)
    80005baa:	6442                	ld	s0,16(sp)
    80005bac:	64a2                	ld	s1,8(sp)
    80005bae:	6902                	ld	s2,0(sp)
    80005bb0:	6105                	add	sp,sp,32
    80005bb2:	8082                	ret
    panic("iunlock");
    80005bb4:	00003517          	auipc	a0,0x3
    80005bb8:	f5c50513          	add	a0,a0,-164 # 80008b10 <syscalls+0x338>
    80005bbc:	ffffb097          	auipc	ra,0xffffb
    80005bc0:	624080e7          	jalr	1572(ra) # 800011e0 <panic>

0000000080005bc4 <itrunc>:

/// @brief 截断inode（丢弃内容）。
/// 调用者必须持有ip->lock。
void itrunc(struct inode *ip)
{
    80005bc4:	7179                	add	sp,sp,-48
    80005bc6:	f406                	sd	ra,40(sp)
    80005bc8:	f022                	sd	s0,32(sp)
    80005bca:	ec26                	sd	s1,24(sp)
    80005bcc:	e84a                	sd	s2,16(sp)
    80005bce:	e44e                	sd	s3,8(sp)
    80005bd0:	e052                	sd	s4,0(sp)
    80005bd2:	1800                	add	s0,sp,48
    80005bd4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  // 释放所有直接块
  for (i = 0; i < NDIRECT; i++)
    80005bd6:	05050493          	add	s1,a0,80
    80005bda:	08050913          	add	s2,a0,128
    80005bde:	a021                	j	80005be6 <itrunc+0x22>
    80005be0:	0491                	add	s1,s1,4
    80005be2:	01248d63          	beq	s1,s2,80005bfc <itrunc+0x38>
  {
    if (ip->addrs[i])
    80005be6:	408c                	lw	a1,0(s1)
    80005be8:	dde5                	beqz	a1,80005be0 <itrunc+0x1c>
    {
      bfree(ip->dev, ip->addrs[i]);
    80005bea:	0009a503          	lw	a0,0(s3)
    80005bee:	00000097          	auipc	ra,0x0
    80005bf2:	c54080e7          	jalr	-940(ra) # 80005842 <bfree>
      ip->addrs[i] = 0;
    80005bf6:	0004a023          	sw	zero,0(s1)
    80005bfa:	b7dd                	j	80005be0 <itrunc+0x1c>
    }
  }

  // 如果有间接块，释放间接块中的所有块
  if (ip->addrs[NDIRECT])
    80005bfc:	0809a583          	lw	a1,128(s3)
    80005c00:	e185                	bnez	a1,80005c20 <itrunc+0x5c>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  // 重置文件大小并更新inode
  ip->size = 0;
    80005c02:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80005c06:	854e                	mv	a0,s3
    80005c08:	00000097          	auipc	ra,0x0
    80005c0c:	de2080e7          	jalr	-542(ra) # 800059ea <iupdate>
}
    80005c10:	70a2                	ld	ra,40(sp)
    80005c12:	7402                	ld	s0,32(sp)
    80005c14:	64e2                	ld	s1,24(sp)
    80005c16:	6942                	ld	s2,16(sp)
    80005c18:	69a2                	ld	s3,8(sp)
    80005c1a:	6a02                	ld	s4,0(sp)
    80005c1c:	6145                	add	sp,sp,48
    80005c1e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80005c20:	0009a503          	lw	a0,0(s3)
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	a36080e7          	jalr	-1482(ra) # 8000465a <bread>
    80005c2c:	8a2a                	mv	s4,a0
    for (j = 0; j < NINDIRECT; j++)
    80005c2e:	05850493          	add	s1,a0,88
    80005c32:	45850913          	add	s2,a0,1112
    80005c36:	a021                	j	80005c3e <itrunc+0x7a>
    80005c38:	0491                	add	s1,s1,4
    80005c3a:	01248b63          	beq	s1,s2,80005c50 <itrunc+0x8c>
      if (a[j])
    80005c3e:	408c                	lw	a1,0(s1)
    80005c40:	dde5                	beqz	a1,80005c38 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80005c42:	0009a503          	lw	a0,0(s3)
    80005c46:	00000097          	auipc	ra,0x0
    80005c4a:	bfc080e7          	jalr	-1028(ra) # 80005842 <bfree>
    80005c4e:	b7ed                	j	80005c38 <itrunc+0x74>
    brelse(bp);
    80005c50:	8552                	mv	a0,s4
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	b38080e7          	jalr	-1224(ra) # 8000478a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80005c5a:	0809a583          	lw	a1,128(s3)
    80005c5e:	0009a503          	lw	a0,0(s3)
    80005c62:	00000097          	auipc	ra,0x0
    80005c66:	be0080e7          	jalr	-1056(ra) # 80005842 <bfree>
    ip->addrs[NDIRECT] = 0;
    80005c6a:	0809a023          	sw	zero,128(s3)
    80005c6e:	bf51                	j	80005c02 <itrunc+0x3e>

0000000080005c70 <iput>:
{
    80005c70:	1101                	add	sp,sp,-32
    80005c72:	ec06                	sd	ra,24(sp)
    80005c74:	e822                	sd	s0,16(sp)
    80005c76:	e426                	sd	s1,8(sp)
    80005c78:	e04a                	sd	s2,0(sp)
    80005c7a:	1000                	add	s0,sp,32
    80005c7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80005c7e:	0001b517          	auipc	a0,0x1b
    80005c82:	90250513          	add	a0,a0,-1790 # 80020580 <itable>
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	2b6080e7          	jalr	694(ra) # 80002f3c <acquire>
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80005c8e:	4498                	lw	a4,8(s1)
    80005c90:	4785                	li	a5,1
    80005c92:	02f70363          	beq	a4,a5,80005cb8 <iput+0x48>
  ip->ref--;
    80005c96:	449c                	lw	a5,8(s1)
    80005c98:	37fd                	addw	a5,a5,-1
    80005c9a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80005c9c:	0001b517          	auipc	a0,0x1b
    80005ca0:	8e450513          	add	a0,a0,-1820 # 80020580 <itable>
    80005ca4:	ffffd097          	auipc	ra,0xffffd
    80005ca8:	34c080e7          	jalr	844(ra) # 80002ff0 <release>
}
    80005cac:	60e2                	ld	ra,24(sp)
    80005cae:	6442                	ld	s0,16(sp)
    80005cb0:	64a2                	ld	s1,8(sp)
    80005cb2:	6902                	ld	s2,0(sp)
    80005cb4:	6105                	add	sp,sp,32
    80005cb6:	8082                	ret
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    80005cb8:	40bc                	lw	a5,64(s1)
    80005cba:	dff1                	beqz	a5,80005c96 <iput+0x26>
    80005cbc:	04a49783          	lh	a5,74(s1)
    80005cc0:	fbf9                	bnez	a5,80005c96 <iput+0x26>
    acquiresleep(&ip->lock);
    80005cc2:	01048913          	add	s2,s1,16
    80005cc6:	854a                	mv	a0,s2
    80005cc8:	ffffd097          	auipc	ra,0xffffd
    80005ccc:	0f4080e7          	jalr	244(ra) # 80002dbc <acquiresleep>
    release(&itable.lock);
    80005cd0:	0001b517          	auipc	a0,0x1b
    80005cd4:	8b050513          	add	a0,a0,-1872 # 80020580 <itable>
    80005cd8:	ffffd097          	auipc	ra,0xffffd
    80005cdc:	318080e7          	jalr	792(ra) # 80002ff0 <release>
    itrunc(ip);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	00000097          	auipc	ra,0x0
    80005ce6:	ee2080e7          	jalr	-286(ra) # 80005bc4 <itrunc>
    ip->type = 0;
    80005cea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80005cee:	8526                	mv	a0,s1
    80005cf0:	00000097          	auipc	ra,0x0
    80005cf4:	cfa080e7          	jalr	-774(ra) # 800059ea <iupdate>
    ip->valid = 0;
    80005cf8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80005cfc:	854a                	mv	a0,s2
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	114080e7          	jalr	276(ra) # 80002e12 <releasesleep>
    acquire(&itable.lock);
    80005d06:	0001b517          	auipc	a0,0x1b
    80005d0a:	87a50513          	add	a0,a0,-1926 # 80020580 <itable>
    80005d0e:	ffffd097          	auipc	ra,0xffffd
    80005d12:	22e080e7          	jalr	558(ra) # 80002f3c <acquire>
    80005d16:	b741                	j	80005c96 <iput+0x26>

0000000080005d18 <iunlockput>:
{
    80005d18:	1101                	add	sp,sp,-32
    80005d1a:	ec06                	sd	ra,24(sp)
    80005d1c:	e822                	sd	s0,16(sp)
    80005d1e:	e426                	sd	s1,8(sp)
    80005d20:	1000                	add	s0,sp,32
    80005d22:	84aa                	mv	s1,a0
  iunlock(ip);
    80005d24:	00000097          	auipc	ra,0x0
    80005d28:	e54080e7          	jalr	-428(ra) # 80005b78 <iunlock>
  iput(ip);
    80005d2c:	8526                	mv	a0,s1
    80005d2e:	00000097          	auipc	ra,0x0
    80005d32:	f42080e7          	jalr	-190(ra) # 80005c70 <iput>
}
    80005d36:	60e2                	ld	ra,24(sp)
    80005d38:	6442                	ld	s0,16(sp)
    80005d3a:	64a2                	ld	s1,8(sp)
    80005d3c:	6105                	add	sp,sp,32
    80005d3e:	8082                	ret

0000000080005d40 <stati>:

/// @brief 从inode复制stat信息。
/// 调用者必须持有ip->lock。
void stati(struct inode *ip, struct stat *st)
{
    80005d40:	1141                	add	sp,sp,-16
    80005d42:	e422                	sd	s0,8(sp)
    80005d44:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80005d46:	411c                	lw	a5,0(a0)
    80005d48:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80005d4a:	415c                	lw	a5,4(a0)
    80005d4c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80005d4e:	04451783          	lh	a5,68(a0)
    80005d52:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80005d56:	04a51783          	lh	a5,74(a0)
    80005d5a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80005d5e:	04c56783          	lwu	a5,76(a0)
    80005d62:	e99c                	sd	a5,16(a1)
}
    80005d64:	6422                	ld	s0,8(sp)
    80005d66:	0141                	add	sp,sp,16
    80005d68:	8082                	ret

0000000080005d6a <readi>:
{
  uint tot, m;
  struct buf *bp;

  // 检查偏移量和大小是否有效
  if (off > ip->size || off + n < off)
    80005d6a:	457c                	lw	a5,76(a0)
    80005d6c:	0ed7e963          	bltu	a5,a3,80005e5e <readi+0xf4>
{
    80005d70:	7159                	add	sp,sp,-112
    80005d72:	f486                	sd	ra,104(sp)
    80005d74:	f0a2                	sd	s0,96(sp)
    80005d76:	eca6                	sd	s1,88(sp)
    80005d78:	e8ca                	sd	s2,80(sp)
    80005d7a:	e4ce                	sd	s3,72(sp)
    80005d7c:	e0d2                	sd	s4,64(sp)
    80005d7e:	fc56                	sd	s5,56(sp)
    80005d80:	f85a                	sd	s6,48(sp)
    80005d82:	f45e                	sd	s7,40(sp)
    80005d84:	f062                	sd	s8,32(sp)
    80005d86:	ec66                	sd	s9,24(sp)
    80005d88:	e86a                	sd	s10,16(sp)
    80005d8a:	e46e                	sd	s11,8(sp)
    80005d8c:	1880                	add	s0,sp,112
    80005d8e:	8b2a                	mv	s6,a0
    80005d90:	8bae                	mv	s7,a1
    80005d92:	8a32                	mv	s4,a2
    80005d94:	84b6                	mv	s1,a3
    80005d96:	8aba                	mv	s5,a4
  if (off > ip->size || off + n < off)
    80005d98:	9f35                	addw	a4,a4,a3
    return 0;
    80005d9a:	4501                	li	a0,0
  if (off > ip->size || off + n < off)
    80005d9c:	0ad76063          	bltu	a4,a3,80005e3c <readi+0xd2>
  // 调整读取大小以不超过文件大小
  if (off + n > ip->size)
    80005da0:	00e7f463          	bgeu	a5,a4,80005da8 <readi+0x3e>
    n = ip->size - off;
    80005da4:	40d78abb          	subw	s5,a5,a3

  // 逐块读取数据
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80005da8:	0a0a8963          	beqz	s5,80005e5a <readi+0xf0>
    80005dac:	4981                	li	s3,0
    if (addr == 0)
      break;
    // 读取块数据
    bp = bread(ip->dev, addr);
    // 计算本次读取的字节数
    m = min(n - tot, BSIZE - off % BSIZE);
    80005dae:	40000c93          	li	s9,1024
    // 复制数据到目标地址
    if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    80005db2:	5c7d                	li	s8,-1
    80005db4:	a82d                	j	80005dee <readi+0x84>
    80005db6:	020d1d93          	sll	s11,s10,0x20
    80005dba:	020ddd93          	srl	s11,s11,0x20
    80005dbe:	05890613          	add	a2,s2,88
    80005dc2:	86ee                	mv	a3,s11
    80005dc4:	963a                	add	a2,a2,a4
    80005dc6:	85d2                	mv	a1,s4
    80005dc8:	855e                	mv	a0,s7
    80005dca:	ffffd097          	auipc	ra,0xffffd
    80005dce:	f0c080e7          	jalr	-244(ra) # 80002cd6 <either_copyout>
    80005dd2:	05850d63          	beq	a0,s8,80005e2c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    // 释放缓冲区
    brelse(bp);
    80005dd6:	854a                	mv	a0,s2
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	9b2080e7          	jalr	-1614(ra) # 8000478a <brelse>
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80005de0:	013d09bb          	addw	s3,s10,s3
    80005de4:	009d04bb          	addw	s1,s10,s1
    80005de8:	9a6e                	add	s4,s4,s11
    80005dea:	0559f763          	bgeu	s3,s5,80005e38 <readi+0xce>
    uint addr = bmap(ip, off / BSIZE);
    80005dee:	00a4d59b          	srlw	a1,s1,0xa
    80005df2:	855a                	mv	a0,s6
    80005df4:	00000097          	auipc	ra,0x0
    80005df8:	964080e7          	jalr	-1692(ra) # 80005758 <bmap>
    80005dfc:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80005e00:	cd85                	beqz	a1,80005e38 <readi+0xce>
    bp = bread(ip->dev, addr);
    80005e02:	000b2503          	lw	a0,0(s6)
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	854080e7          	jalr	-1964(ra) # 8000465a <bread>
    80005e0e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80005e10:	3ff4f713          	and	a4,s1,1023
    80005e14:	40ec87bb          	subw	a5,s9,a4
    80005e18:	413a86bb          	subw	a3,s5,s3
    80005e1c:	8d3e                	mv	s10,a5
    80005e1e:	2781                	sext.w	a5,a5
    80005e20:	0006861b          	sext.w	a2,a3
    80005e24:	f8f679e3          	bgeu	a2,a5,80005db6 <readi+0x4c>
    80005e28:	8d36                	mv	s10,a3
    80005e2a:	b771                	j	80005db6 <readi+0x4c>
      brelse(bp);
    80005e2c:	854a                	mv	a0,s2
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	95c080e7          	jalr	-1700(ra) # 8000478a <brelse>
      tot = -1;
    80005e36:	59fd                	li	s3,-1
  }
  return tot;
    80005e38:	0009851b          	sext.w	a0,s3
}
    80005e3c:	70a6                	ld	ra,104(sp)
    80005e3e:	7406                	ld	s0,96(sp)
    80005e40:	64e6                	ld	s1,88(sp)
    80005e42:	6946                	ld	s2,80(sp)
    80005e44:	69a6                	ld	s3,72(sp)
    80005e46:	6a06                	ld	s4,64(sp)
    80005e48:	7ae2                	ld	s5,56(sp)
    80005e4a:	7b42                	ld	s6,48(sp)
    80005e4c:	7ba2                	ld	s7,40(sp)
    80005e4e:	7c02                	ld	s8,32(sp)
    80005e50:	6ce2                	ld	s9,24(sp)
    80005e52:	6d42                	ld	s10,16(sp)
    80005e54:	6da2                	ld	s11,8(sp)
    80005e56:	6165                	add	sp,sp,112
    80005e58:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80005e5a:	89d6                	mv	s3,s5
    80005e5c:	bff1                	j	80005e38 <readi+0xce>
    return 0;
    80005e5e:	4501                	li	a0,0
}
    80005e60:	8082                	ret

0000000080005e62 <writei>:
{
  uint tot, m;
  struct buf *bp;

  // 检查偏移量和大小是否有效
  if (off > ip->size || off + n < off)
    80005e62:	457c                	lw	a5,76(a0)
    80005e64:	10d7e863          	bltu	a5,a3,80005f74 <writei+0x112>
{
    80005e68:	7159                	add	sp,sp,-112
    80005e6a:	f486                	sd	ra,104(sp)
    80005e6c:	f0a2                	sd	s0,96(sp)
    80005e6e:	eca6                	sd	s1,88(sp)
    80005e70:	e8ca                	sd	s2,80(sp)
    80005e72:	e4ce                	sd	s3,72(sp)
    80005e74:	e0d2                	sd	s4,64(sp)
    80005e76:	fc56                	sd	s5,56(sp)
    80005e78:	f85a                	sd	s6,48(sp)
    80005e7a:	f45e                	sd	s7,40(sp)
    80005e7c:	f062                	sd	s8,32(sp)
    80005e7e:	ec66                	sd	s9,24(sp)
    80005e80:	e86a                	sd	s10,16(sp)
    80005e82:	e46e                	sd	s11,8(sp)
    80005e84:	1880                	add	s0,sp,112
    80005e86:	8aaa                	mv	s5,a0
    80005e88:	8bae                	mv	s7,a1
    80005e8a:	8a32                	mv	s4,a2
    80005e8c:	8936                	mv	s2,a3
    80005e8e:	8b3a                	mv	s6,a4
  if (off > ip->size || off + n < off)
    80005e90:	00e687bb          	addw	a5,a3,a4
    80005e94:	0ed7e263          	bltu	a5,a3,80005f78 <writei+0x116>
    return -1;
  // 检查是否超过最大文件大小
  if (off + n > MAXFILE * BSIZE)
    80005e98:	00043737          	lui	a4,0x43
    80005e9c:	0ef76063          	bltu	a4,a5,80005f7c <writei+0x11a>
    return -1;

  // 逐块写入数据
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80005ea0:	0c0b0863          	beqz	s6,80005f70 <writei+0x10e>
    80005ea4:	4981                	li	s3,0
    if (addr == 0)
      break;
    // 读取块数据
    bp = bread(ip->dev, addr);
    // 计算本次写入的字节数
    m = min(n - tot, BSIZE - off % BSIZE);
    80005ea6:	40000c93          	li	s9,1024
    // 从源地址复制数据到缓冲区
    if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    80005eaa:	5c7d                	li	s8,-1
    80005eac:	a091                	j	80005ef0 <writei+0x8e>
    80005eae:	020d1d93          	sll	s11,s10,0x20
    80005eb2:	020ddd93          	srl	s11,s11,0x20
    80005eb6:	05848513          	add	a0,s1,88
    80005eba:	86ee                	mv	a3,s11
    80005ebc:	8652                	mv	a2,s4
    80005ebe:	85de                	mv	a1,s7
    80005ec0:	953a                	add	a0,a0,a4
    80005ec2:	ffffd097          	auipc	ra,0xffffd
    80005ec6:	e6a080e7          	jalr	-406(ra) # 80002d2c <either_copyin>
    80005eca:	07850263          	beq	a0,s8,80005f2e <writei+0xcc>
    {
      brelse(bp);
      break;
    }
    // 写回磁盘
    log_write(bp);
    80005ece:	8526                	mv	a0,s1
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	d66080e7          	jalr	-666(ra) # 80004c36 <log_write>
    // 释放缓冲区
    brelse(bp);
    80005ed8:	8526                	mv	a0,s1
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	8b0080e7          	jalr	-1872(ra) # 8000478a <brelse>
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80005ee2:	013d09bb          	addw	s3,s10,s3
    80005ee6:	012d093b          	addw	s2,s10,s2
    80005eea:	9a6e                	add	s4,s4,s11
    80005eec:	0569f663          	bgeu	s3,s6,80005f38 <writei+0xd6>
    uint addr = bmap(ip, off / BSIZE);
    80005ef0:	00a9559b          	srlw	a1,s2,0xa
    80005ef4:	8556                	mv	a0,s5
    80005ef6:	00000097          	auipc	ra,0x0
    80005efa:	862080e7          	jalr	-1950(ra) # 80005758 <bmap>
    80005efe:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    80005f02:	c99d                	beqz	a1,80005f38 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80005f04:	000aa503          	lw	a0,0(s5)
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	752080e7          	jalr	1874(ra) # 8000465a <bread>
    80005f10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    80005f12:	3ff97713          	and	a4,s2,1023
    80005f16:	40ec87bb          	subw	a5,s9,a4
    80005f1a:	413b06bb          	subw	a3,s6,s3
    80005f1e:	8d3e                	mv	s10,a5
    80005f20:	2781                	sext.w	a5,a5
    80005f22:	0006861b          	sext.w	a2,a3
    80005f26:	f8f674e3          	bgeu	a2,a5,80005eae <writei+0x4c>
    80005f2a:	8d36                	mv	s10,a3
    80005f2c:	b749                	j	80005eae <writei+0x4c>
      brelse(bp);
    80005f2e:	8526                	mv	a0,s1
    80005f30:	fffff097          	auipc	ra,0xfffff
    80005f34:	85a080e7          	jalr	-1958(ra) # 8000478a <brelse>
  }

  // 如果写入位置超过原文件大小，更新文件大小
  if (off > ip->size)
    80005f38:	04caa783          	lw	a5,76(s5)
    80005f3c:	0127f463          	bgeu	a5,s2,80005f44 <writei+0xe2>
    ip->size = off;
    80005f40:	052aa623          	sw	s2,76(s5)

  // 写回inode到磁盘，即使大小没有改变
  // 因为上面的循环可能调用了bmap()并向ip->addrs[]添加了新块。
  iupdate(ip);
    80005f44:	8556                	mv	a0,s5
    80005f46:	00000097          	auipc	ra,0x0
    80005f4a:	aa4080e7          	jalr	-1372(ra) # 800059ea <iupdate>

  return tot;
    80005f4e:	0009851b          	sext.w	a0,s3
}
    80005f52:	70a6                	ld	ra,104(sp)
    80005f54:	7406                	ld	s0,96(sp)
    80005f56:	64e6                	ld	s1,88(sp)
    80005f58:	6946                	ld	s2,80(sp)
    80005f5a:	69a6                	ld	s3,72(sp)
    80005f5c:	6a06                	ld	s4,64(sp)
    80005f5e:	7ae2                	ld	s5,56(sp)
    80005f60:	7b42                	ld	s6,48(sp)
    80005f62:	7ba2                	ld	s7,40(sp)
    80005f64:	7c02                	ld	s8,32(sp)
    80005f66:	6ce2                	ld	s9,24(sp)
    80005f68:	6d42                	ld	s10,16(sp)
    80005f6a:	6da2                	ld	s11,8(sp)
    80005f6c:	6165                	add	sp,sp,112
    80005f6e:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    80005f70:	89da                	mv	s3,s6
    80005f72:	bfc9                	j	80005f44 <writei+0xe2>
    return -1;
    80005f74:	557d                	li	a0,-1
}
    80005f76:	8082                	ret
    return -1;
    80005f78:	557d                	li	a0,-1
    80005f7a:	bfe1                	j	80005f52 <writei+0xf0>
    return -1;
    80005f7c:	557d                	li	a0,-1
    80005f7e:	bfd1                	j	80005f52 <writei+0xf0>

0000000080005f80 <namecmp>:

// 目录

int namecmp(const char *s, const char *t)
{
    80005f80:	1141                	add	sp,sp,-16
    80005f82:	e406                	sd	ra,8(sp)
    80005f84:	e022                	sd	s0,0(sp)
    80005f86:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80005f88:	4639                	li	a2,14
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	0de080e7          	jalr	222(ra) # 80001068 <strncmp>
}
    80005f92:	60a2                	ld	ra,8(sp)
    80005f94:	6402                	ld	s0,0(sp)
    80005f96:	0141                	add	sp,sp,16
    80005f98:	8082                	ret

0000000080005f9a <dirlookup>:

/// @brief 在目录中查找目录项。
/// 如果找到，将*poff设置为目录项的字节偏移量。
struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80005f9a:	7139                	add	sp,sp,-64
    80005f9c:	fc06                	sd	ra,56(sp)
    80005f9e:	f822                	sd	s0,48(sp)
    80005fa0:	f426                	sd	s1,40(sp)
    80005fa2:	f04a                	sd	s2,32(sp)
    80005fa4:	ec4e                	sd	s3,24(sp)
    80005fa6:	e852                	sd	s4,16(sp)
    80005fa8:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  // 检查是否为目录
  if (dp->type != T_DIR)
    80005faa:	04451703          	lh	a4,68(a0)
    80005fae:	4785                	li	a5,1
    80005fb0:	00f71a63          	bne	a4,a5,80005fc4 <dirlookup+0x2a>
    80005fb4:	892a                	mv	s2,a0
    80005fb6:	89ae                	mv	s3,a1
    80005fb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  // 遍历目录中的所有目录项
  for (off = 0; off < dp->size; off += sizeof(de))
    80005fba:	457c                	lw	a5,76(a0)
    80005fbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80005fbe:	4501                	li	a0,0
  for (off = 0; off < dp->size; off += sizeof(de))
    80005fc0:	e79d                	bnez	a5,80005fee <dirlookup+0x54>
    80005fc2:	a8a5                	j	8000603a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80005fc4:	00003517          	auipc	a0,0x3
    80005fc8:	b5450513          	add	a0,a0,-1196 # 80008b18 <syscalls+0x340>
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	214080e7          	jalr	532(ra) # 800011e0 <panic>
      panic("dirlookup read");
    80005fd4:	00003517          	auipc	a0,0x3
    80005fd8:	b5c50513          	add	a0,a0,-1188 # 80008b30 <syscalls+0x358>
    80005fdc:	ffffb097          	auipc	ra,0xffffb
    80005fe0:	204080e7          	jalr	516(ra) # 800011e0 <panic>
  for (off = 0; off < dp->size; off += sizeof(de))
    80005fe4:	24c1                	addw	s1,s1,16
    80005fe6:	04c92783          	lw	a5,76(s2)
    80005fea:	04f4f763          	bgeu	s1,a5,80006038 <dirlookup+0x9e>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005fee:	4741                	li	a4,16
    80005ff0:	86a6                	mv	a3,s1
    80005ff2:	fc040613          	add	a2,s0,-64
    80005ff6:	4581                	li	a1,0
    80005ff8:	854a                	mv	a0,s2
    80005ffa:	00000097          	auipc	ra,0x0
    80005ffe:	d70080e7          	jalr	-656(ra) # 80005d6a <readi>
    80006002:	47c1                	li	a5,16
    80006004:	fcf518e3          	bne	a0,a5,80005fd4 <dirlookup+0x3a>
    if (de.inum == 0)
    80006008:	fc045783          	lhu	a5,-64(s0)
    8000600c:	dfe1                	beqz	a5,80005fe4 <dirlookup+0x4a>
    if (namecmp(name, de.name) == 0)
    8000600e:	fc240593          	add	a1,s0,-62
    80006012:	854e                	mv	a0,s3
    80006014:	00000097          	auipc	ra,0x0
    80006018:	f6c080e7          	jalr	-148(ra) # 80005f80 <namecmp>
    8000601c:	f561                	bnez	a0,80005fe4 <dirlookup+0x4a>
      if (poff)
    8000601e:	000a0463          	beqz	s4,80006026 <dirlookup+0x8c>
        *poff = off;
    80006022:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80006026:	fc045583          	lhu	a1,-64(s0)
    8000602a:	00092503          	lw	a0,0(s2)
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	4bc080e7          	jalr	1212(ra) # 800054ea <iget>
    80006036:	a011                	j	8000603a <dirlookup+0xa0>
  return 0;
    80006038:	4501                	li	a0,0
}
    8000603a:	70e2                	ld	ra,56(sp)
    8000603c:	7442                	ld	s0,48(sp)
    8000603e:	74a2                	ld	s1,40(sp)
    80006040:	7902                	ld	s2,32(sp)
    80006042:	69e2                	ld	s3,24(sp)
    80006044:	6a42                	ld	s4,16(sp)
    80006046:	6121                	add	sp,sp,64
    80006048:	8082                	ret

000000008000604a <namex>:
/// 如果parent != 0，返回父目录的inode并将最终路径元素复制到name中，
/// name必须有DIRSIZ字节的空间。
/// 必须在文件系统事务内（iget后）调用，因为它调用iput()，会释放inode的引用。
static struct inode *
namex(char *path, int nameiparent, char *name)
{
    8000604a:	711d                	add	sp,sp,-96
    8000604c:	ec86                	sd	ra,88(sp)
    8000604e:	e8a2                	sd	s0,80(sp)
    80006050:	e4a6                	sd	s1,72(sp)
    80006052:	e0ca                	sd	s2,64(sp)
    80006054:	fc4e                	sd	s3,56(sp)
    80006056:	f852                	sd	s4,48(sp)
    80006058:	f456                	sd	s5,40(sp)
    8000605a:	f05a                	sd	s6,32(sp)
    8000605c:	ec5e                	sd	s7,24(sp)
    8000605e:	e862                	sd	s8,16(sp)
    80006060:	e466                	sd	s9,8(sp)
    80006062:	1080                	add	s0,sp,96
    80006064:	84aa                	mv	s1,a0
    80006066:	8b2e                	mv	s6,a1
    80006068:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  // 根据路径是否以'/'开头，选择起始inode
  if (*path == '/')
    8000606a:	00054703          	lbu	a4,0(a0)
    8000606e:	02f00793          	li	a5,47
    80006072:	02f70163          	beq	a4,a5,80006094 <namex+0x4a>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80006076:	ffffc097          	auipc	ra,0xffffc
    8000607a:	098080e7          	jalr	152(ra) # 8000210e <myproc>
    8000607e:	7168                	ld	a0,224(a0)
    80006080:	00000097          	auipc	ra,0x0
    80006084:	9f8080e7          	jalr	-1544(ra) # 80005a78 <idup>
    80006088:	8a2a                	mv	s4,a0
  while (*path == '/')
    8000608a:	02f00913          	li	s2,47
  if (len >= DIRSIZ)
    8000608e:	4c35                	li	s8,13
  // 逐个处理路径元素
  while ((path = skipelem(path, name)) != 0)
  {
    ilock(ip);
    // 检查当前inode是否为目录
    if (ip->type != T_DIR)
    80006090:	4b85                	li	s7,1
    80006092:	a875                	j	8000614e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80006094:	4585                	li	a1,1
    80006096:	4505                	li	a0,1
    80006098:	fffff097          	auipc	ra,0xfffff
    8000609c:	452080e7          	jalr	1106(ra) # 800054ea <iget>
    800060a0:	8a2a                	mv	s4,a0
    800060a2:	b7e5                	j	8000608a <namex+0x40>
    {
      iunlockput(ip);
    800060a4:	8552                	mv	a0,s4
    800060a6:	00000097          	auipc	ra,0x0
    800060aa:	c72080e7          	jalr	-910(ra) # 80005d18 <iunlockput>
      return 0;
    800060ae:	4a01                	li	s4,0
  {
    iput(ip);
    return 0;
  }
  return ip;
}
    800060b0:	8552                	mv	a0,s4
    800060b2:	60e6                	ld	ra,88(sp)
    800060b4:	6446                	ld	s0,80(sp)
    800060b6:	64a6                	ld	s1,72(sp)
    800060b8:	6906                	ld	s2,64(sp)
    800060ba:	79e2                	ld	s3,56(sp)
    800060bc:	7a42                	ld	s4,48(sp)
    800060be:	7aa2                	ld	s5,40(sp)
    800060c0:	7b02                	ld	s6,32(sp)
    800060c2:	6be2                	ld	s7,24(sp)
    800060c4:	6c42                	ld	s8,16(sp)
    800060c6:	6ca2                	ld	s9,8(sp)
    800060c8:	6125                	add	sp,sp,96
    800060ca:	8082                	ret
      iunlock(ip);
    800060cc:	8552                	mv	a0,s4
    800060ce:	00000097          	auipc	ra,0x0
    800060d2:	aaa080e7          	jalr	-1366(ra) # 80005b78 <iunlock>
      return ip;
    800060d6:	bfe9                	j	800060b0 <namex+0x66>
      iunlockput(ip);
    800060d8:	8552                	mv	a0,s4
    800060da:	00000097          	auipc	ra,0x0
    800060de:	c3e080e7          	jalr	-962(ra) # 80005d18 <iunlockput>
      return 0;
    800060e2:	8a4e                	mv	s4,s3
    800060e4:	b7f1                	j	800060b0 <namex+0x66>
  len = path - s;
    800060e6:	40998633          	sub	a2,s3,s1
    800060ea:	00060c9b          	sext.w	s9,a2
  if (len >= DIRSIZ)
    800060ee:	099c5863          	bge	s8,s9,8000617e <namex+0x134>
    memmove(name, s, DIRSIZ);
    800060f2:	4639                	li	a2,14
    800060f4:	85a6                	mv	a1,s1
    800060f6:	8556                	mv	a0,s5
    800060f8:	ffffb097          	auipc	ra,0xffffb
    800060fc:	efc080e7          	jalr	-260(ra) # 80000ff4 <memmove>
    80006100:	84ce                	mv	s1,s3
  while (*path == '/')
    80006102:	0004c783          	lbu	a5,0(s1)
    80006106:	01279763          	bne	a5,s2,80006114 <namex+0xca>
    path++;
    8000610a:	0485                	add	s1,s1,1
  while (*path == '/')
    8000610c:	0004c783          	lbu	a5,0(s1)
    80006110:	ff278de3          	beq	a5,s2,8000610a <namex+0xc0>
    ilock(ip);
    80006114:	8552                	mv	a0,s4
    80006116:	00000097          	auipc	ra,0x0
    8000611a:	9a0080e7          	jalr	-1632(ra) # 80005ab6 <ilock>
    if (ip->type != T_DIR)
    8000611e:	044a1783          	lh	a5,68(s4)
    80006122:	f97791e3          	bne	a5,s7,800060a4 <namex+0x5a>
    if (nameiparent && *path == '\0')
    80006126:	000b0563          	beqz	s6,80006130 <namex+0xe6>
    8000612a:	0004c783          	lbu	a5,0(s1)
    8000612e:	dfd9                	beqz	a5,800060cc <namex+0x82>
    if ((next = dirlookup(ip, name, 0)) == 0)
    80006130:	4601                	li	a2,0
    80006132:	85d6                	mv	a1,s5
    80006134:	8552                	mv	a0,s4
    80006136:	00000097          	auipc	ra,0x0
    8000613a:	e64080e7          	jalr	-412(ra) # 80005f9a <dirlookup>
    8000613e:	89aa                	mv	s3,a0
    80006140:	dd41                	beqz	a0,800060d8 <namex+0x8e>
    iunlockput(ip);
    80006142:	8552                	mv	a0,s4
    80006144:	00000097          	auipc	ra,0x0
    80006148:	bd4080e7          	jalr	-1068(ra) # 80005d18 <iunlockput>
    ip = next;
    8000614c:	8a4e                	mv	s4,s3
  while (*path == '/')
    8000614e:	0004c783          	lbu	a5,0(s1)
    80006152:	01279763          	bne	a5,s2,80006160 <namex+0x116>
    path++;
    80006156:	0485                	add	s1,s1,1
  while (*path == '/')
    80006158:	0004c783          	lbu	a5,0(s1)
    8000615c:	ff278de3          	beq	a5,s2,80006156 <namex+0x10c>
  if (*path == 0)
    80006160:	cb9d                	beqz	a5,80006196 <namex+0x14c>
  while (*path != '/' && *path != 0)
    80006162:	0004c783          	lbu	a5,0(s1)
    80006166:	89a6                	mv	s3,s1
  len = path - s;
    80006168:	4c81                	li	s9,0
    8000616a:	4601                	li	a2,0
  while (*path != '/' && *path != 0)
    8000616c:	01278963          	beq	a5,s2,8000617e <namex+0x134>
    80006170:	dbbd                	beqz	a5,800060e6 <namex+0x9c>
    path++;
    80006172:	0985                	add	s3,s3,1
  while (*path != '/' && *path != 0)
    80006174:	0009c783          	lbu	a5,0(s3)
    80006178:	ff279ce3          	bne	a5,s2,80006170 <namex+0x126>
    8000617c:	b7ad                	j	800060e6 <namex+0x9c>
    memmove(name, s, len);
    8000617e:	2601                	sext.w	a2,a2
    80006180:	85a6                	mv	a1,s1
    80006182:	8556                	mv	a0,s5
    80006184:	ffffb097          	auipc	ra,0xffffb
    80006188:	e70080e7          	jalr	-400(ra) # 80000ff4 <memmove>
    name[len] = 0;
    8000618c:	9cd6                	add	s9,s9,s5
    8000618e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80006192:	84ce                	mv	s1,s3
    80006194:	b7bd                	j	80006102 <namex+0xb8>
  if (nameiparent)
    80006196:	f00b0de3          	beqz	s6,800060b0 <namex+0x66>
    iput(ip);
    8000619a:	8552                	mv	a0,s4
    8000619c:	00000097          	auipc	ra,0x0
    800061a0:	ad4080e7          	jalr	-1324(ra) # 80005c70 <iput>
    return 0;
    800061a4:	4a01                	li	s4,0
    800061a6:	b729                	j	800060b0 <namex+0x66>

00000000800061a8 <dirlink>:
{
    800061a8:	7139                	add	sp,sp,-64
    800061aa:	fc06                	sd	ra,56(sp)
    800061ac:	f822                	sd	s0,48(sp)
    800061ae:	f426                	sd	s1,40(sp)
    800061b0:	f04a                	sd	s2,32(sp)
    800061b2:	ec4e                	sd	s3,24(sp)
    800061b4:	e852                	sd	s4,16(sp)
    800061b6:	0080                	add	s0,sp,64
    800061b8:	892a                	mv	s2,a0
    800061ba:	8a2e                	mv	s4,a1
    800061bc:	89b2                	mv	s3,a2
  if ((ip = dirlookup(dp, name, 0)) != 0)
    800061be:	4601                	li	a2,0
    800061c0:	00000097          	auipc	ra,0x0
    800061c4:	dda080e7          	jalr	-550(ra) # 80005f9a <dirlookup>
    800061c8:	e93d                	bnez	a0,8000623e <dirlink+0x96>
  for (off = 0; off < dp->size; off += sizeof(de))
    800061ca:	04c92483          	lw	s1,76(s2)
    800061ce:	c49d                	beqz	s1,800061fc <dirlink+0x54>
    800061d0:	4481                	li	s1,0
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061d2:	4741                	li	a4,16
    800061d4:	86a6                	mv	a3,s1
    800061d6:	fc040613          	add	a2,s0,-64
    800061da:	4581                	li	a1,0
    800061dc:	854a                	mv	a0,s2
    800061de:	00000097          	auipc	ra,0x0
    800061e2:	b8c080e7          	jalr	-1140(ra) # 80005d6a <readi>
    800061e6:	47c1                	li	a5,16
    800061e8:	06f51163          	bne	a0,a5,8000624a <dirlink+0xa2>
    if (de.inum == 0)
    800061ec:	fc045783          	lhu	a5,-64(s0)
    800061f0:	c791                	beqz	a5,800061fc <dirlink+0x54>
  for (off = 0; off < dp->size; off += sizeof(de))
    800061f2:	24c1                	addw	s1,s1,16
    800061f4:	04c92783          	lw	a5,76(s2)
    800061f8:	fcf4ede3          	bltu	s1,a5,800061d2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800061fc:	4639                	li	a2,14
    800061fe:	85d2                	mv	a1,s4
    80006200:	fc240513          	add	a0,s0,-62
    80006204:	ffffb097          	auipc	ra,0xffffb
    80006208:	ea0080e7          	jalr	-352(ra) # 800010a4 <strncpy>
  de.inum = inum;
    8000620c:	fd341023          	sh	s3,-64(s0)
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006210:	4741                	li	a4,16
    80006212:	86a6                	mv	a3,s1
    80006214:	fc040613          	add	a2,s0,-64
    80006218:	4581                	li	a1,0
    8000621a:	854a                	mv	a0,s2
    8000621c:	00000097          	auipc	ra,0x0
    80006220:	c46080e7          	jalr	-954(ra) # 80005e62 <writei>
    80006224:	1541                	add	a0,a0,-16
    80006226:	00a03533          	snez	a0,a0
    8000622a:	40a00533          	neg	a0,a0
}
    8000622e:	70e2                	ld	ra,56(sp)
    80006230:	7442                	ld	s0,48(sp)
    80006232:	74a2                	ld	s1,40(sp)
    80006234:	7902                	ld	s2,32(sp)
    80006236:	69e2                	ld	s3,24(sp)
    80006238:	6a42                	ld	s4,16(sp)
    8000623a:	6121                	add	sp,sp,64
    8000623c:	8082                	ret
    iput(ip);
    8000623e:	00000097          	auipc	ra,0x0
    80006242:	a32080e7          	jalr	-1486(ra) # 80005c70 <iput>
    return -1;
    80006246:	557d                	li	a0,-1
    80006248:	b7dd                	j	8000622e <dirlink+0x86>
      panic("dirlink read");
    8000624a:	00003517          	auipc	a0,0x3
    8000624e:	8f650513          	add	a0,a0,-1802 # 80008b40 <syscalls+0x368>
    80006252:	ffffb097          	auipc	ra,0xffffb
    80006256:	f8e080e7          	jalr	-114(ra) # 800011e0 <panic>

000000008000625a <namei>:

/// @brief 查找路径名对应的inode。
/// 返回该inode的引用（未锁定）。
struct inode *
namei(char *path)
{
    8000625a:	1101                	add	sp,sp,-32
    8000625c:	ec06                	sd	ra,24(sp)
    8000625e:	e822                	sd	s0,16(sp)
    80006260:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80006262:	fe040613          	add	a2,s0,-32
    80006266:	4581                	li	a1,0
    80006268:	00000097          	auipc	ra,0x0
    8000626c:	de2080e7          	jalr	-542(ra) # 8000604a <namex>
}
    80006270:	60e2                	ld	ra,24(sp)
    80006272:	6442                	ld	s0,16(sp)
    80006274:	6105                	add	sp,sp,32
    80006276:	8082                	ret

0000000080006278 <nameiparent>:
/// @brief 查找路径名对应的父目录的inode，并将最终路径元素复制到name中。
/// name必须有DIRSIZ字节的空间。
/// 返回父目录的inode引用（未锁定）。
struct inode *
nameiparent(char *path, char *name)
{
    80006278:	1141                	add	sp,sp,-16
    8000627a:	e406                	sd	ra,8(sp)
    8000627c:	e022                	sd	s0,0(sp)
    8000627e:	0800                	add	s0,sp,16
    80006280:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80006282:	4585                	li	a1,1
    80006284:	00000097          	auipc	ra,0x0
    80006288:	dc6080e7          	jalr	-570(ra) # 8000604a <namex>
}
    8000628c:	60a2                	ld	ra,8(sp)
    8000628e:	6402                	ld	s0,0(sp)
    80006290:	0141                	add	sp,sp,16
    80006292:	8082                	ret

0000000080006294 <initcode_start>:
    80006294:	00000097          	.word	0x00000097
    80006298:	0bc080e7          	.word	0x0bc080e7
    8000629c:	0000a001          	.word	0x0000a001
    800062a0:	ff010113          	.word	0xff010113
    800062a4:	00813423          	.word	0x00813423
    800062a8:	01010413          	.word	0x01010413
    800062ac:	00000313          	.word	0x00000313
    800062b0:	08054a63          	.word	0x08054a63
    800062b4:	00058693          	.word	0x00058693
    800062b8:	00058613          	.word	0x00058613
    800062bc:	00000793          	.word	0x00000793
    800062c0:	00a00813          	.word	0x00a00813
    800062c4:	00078893          	.word	0x00078893
    800062c8:	0017879b          	.word	0x0017879b
    800062cc:	0305673b          	.word	0x0305673b
    800062d0:	0307071b          	.word	0x0307071b
    800062d4:	00e60023          	.word	0x00e60023
    800062d8:	0305453b          	.word	0x0305453b
    800062dc:	00160613          	.word	0x00160613
    800062e0:	fe0512e3          	.word	0xfe0512e3
    800062e4:	00030a63          	.word	0x00030a63
    800062e8:	00f587b3          	.word	0x00f587b3
    800062ec:	02d00713          	.word	0x02d00713
    800062f0:	00e78023          	.word	0x00e78023
    800062f4:	0028879b          	.word	0x0028879b
    800062f8:	00f58733          	.word	0x00f58733
    800062fc:	00070023          	.word	0x00070023
    80006300:	fff7871b          	.word	0xfff7871b
    80006304:	02e05a63          	.word	0x02e05a63
    80006308:	00e585b3          	.word	0x00e585b3
    8000630c:	fff7879b          	.word	0xfff7879b
    80006310:	0006c703          	.word	0x0006c703
    80006314:	0005c603          	.word	0x0005c603
    80006318:	00c68023          	.word	0x00c68023
    8000631c:	00e58023          	.word	0x00e58023
    80006320:	0015071b          	.word	0x0015071b
    80006324:	0007051b          	.word	0x0007051b
    80006328:	00168693          	.word	0x00168693
    8000632c:	fff58593          	.word	0xfff58593
    80006330:	40e7873b          	.word	0x40e7873b
    80006334:	fce54ee3          	.word	0xfce54ee3
    80006338:	00813403          	.word	0x00813403
    8000633c:	01010113          	.word	0x01010113
    80006340:	00008067          	.word	0x00008067
    80006344:	40a0053b          	.word	0x40a0053b
    80006348:	00100313          	.word	0x00100313
    8000634c:	f69ff06f          	.word	0xf69ff06f
    80006350:	ff010113          	.word	0xff010113
    80006354:	00813423          	.word	0x00813423
    80006358:	01010413          	.word	0x01010413
    8000635c:	01400893          	.word	0x01400893
    80006360:	00000073          	.word	0x00000073
    80006364:	00050713          	.word	0x00050713
    80006368:	00000073          	.word	0x00000073
    8000636c:	00050693          	.word	0x00050693
    80006370:	00000073          	.word	0x00000073
    80006374:	00050793          	.word	0x00050793
    80006378:	01500893          	.word	0x01500893
    8000637c:	00068513          	.word	0x00068513
    80006380:	00000073          	.word	0x00000073
    80006384:	00070513          	.word	0x00070513
    80006388:	00000073          	.word	0x00000073
    8000638c:	00078513          	.word	0x00078513
    80006390:	00000073          	.word	0x00000073
    80006394:	0000006f          	.word	0x0000006f

0000000080006398 <initcode_end>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    80006398:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    8000639c:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    800063a0:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    800063a2:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    800063a4:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    800063a8:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    800063ac:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    800063b0:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    800063b4:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    800063b8:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    800063bc:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    800063c0:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    800063c4:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    800063c8:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    800063cc:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)      # 恢复栈指针
    800063d0:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    800063d4:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    800063d6:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    800063d8:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    800063dc:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    800063e0:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    800063e4:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    800063e8:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    800063ec:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    800063f0:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    800063f4:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    800063f8:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    800063fc:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    80006400:	8082                	ret
	...

0000000080006410 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    80006410:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    80006412:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80006414:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80006416:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80006418:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    8000641a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000641c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000641e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    80006420:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    80006422:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    80006424:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80006426:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80006428:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    8000642a:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    8000642c:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    8000642e:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    80006430:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    80006432:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    80006434:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    80006436:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    80006438:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    8000643a:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    8000643c:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    8000643e:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    80006440:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    80006442:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    80006444:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    80006446:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    80006448:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    8000644a:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    8000644c:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    8000644e:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    80006450:	ffffd097          	auipc	ra,0xffffd
    80006454:	ccc080e7          	jalr	-820(ra) # 8000311c <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    80006458:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    8000645a:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    8000645c:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    8000645e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80006460:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80006462:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    80006464:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    80006466:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    80006468:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    8000646a:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    8000646c:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000646e:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    80006470:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    80006472:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80006474:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80006476:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    80006478:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    8000647a:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    8000647c:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    8000647e:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    80006480:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    80006482:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    80006484:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    80006486:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    80006488:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    8000648a:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    8000648c:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    8000648e:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80006490:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80006492:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    80006494:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    80006496:	10200073          	sret
    8000649a:	0001                	nop
    8000649c:	00000013          	nop

00000000800064a0 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    800064a0:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    800064a4:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    800064a6:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    800064a8:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    800064aa:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    800064ac:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    800064ae:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    800064b0:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    800064b2:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    800064b4:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    800064b6:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    800064ba:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    800064bc:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    800064be:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    800064c0:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    800064c4:	30200073          	mret
    800064c8:	00000013          	nop
    800064cc:	00000013          	nop
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
