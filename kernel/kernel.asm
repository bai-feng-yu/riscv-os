
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
    80000004:	51010113          	add	sp,sp,1296 # 80003510 <stack0>
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
    8000001a:	4aa50513          	add	a0,a0,1194 # 800034c0 <started>
    la a1, end
    8000001e:	0000c597          	auipc	a1,0xc
    80000022:	c2a58593          	add	a1,a1,-982 # 8000bc48 <end>

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
    80000034:	12a080e7          	jalr	298(ra) # 8000015a <start>

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
    80000046:	fc0080e7          	jalr	-64(ra) # 80001002 <cpuid>
        started = 1;         // 标记系统启动完成
    __sync_synchronize();

  } else {
    //其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000004a:	00003717          	auipc	a4,0x3
    8000004e:	47670713          	add	a4,a4,1142 # 800034c0 <started>
  if(cpuid() == 0){
    80000052:	c531                	beqz	a0,8000009e <main+0x64>
    while(started == 0)
    80000054:	431c                	lw	a5,0(a4)
    80000056:	2781                	sext.w	a5,a5
    80000058:	dff5                	beqz	a5,80000054 <main+0x1a>
      ;
    
    __sync_synchronize();
    8000005a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000005e:	00001097          	auipc	ra,0x1
    80000062:	fa4080e7          	jalr	-92(ra) # 80001002 <cpuid>
    80000066:	85aa                	mv	a1,a0
    80000068:	00003517          	auipc	a0,0x3
    8000006c:	fa850513          	add	a0,a0,-88 # 80003010 <etext+0x10>
    80000070:	00000097          	auipc	ra,0x0
    80000074:	75c080e7          	jalr	1884(ra) # 800007cc <printf>
    kvminithart();       // 开启分页机制
    80000078:	00001097          	auipc	ra,0x1
    8000007c:	af6080e7          	jalr	-1290(ra) # 80000b6e <kvminithart>
    trapinithart();   // 安装内核陷阱向量
    80000080:	00001097          	auipc	ra,0x1
    80000084:	3d2080e7          	jalr	978(ra) # 80001452 <trapinithart>
    plicinithart();   // 向PLIC请求设备中断
    80000088:	00000097          	auipc	ra,0x0
    8000008c:	42c080e7          	jalr	1068(ra) # 800004b4 <plicinithart>

static inline uint64
r_sstatus()
{
  uint64 x;
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000090:	100027f3          	csrr	a5,sstatus

// enable device interrupts
static inline void
intr_on()
{
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000094:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000098:	10079073          	csrw	sstatus,a5
  }
      intr_on();          // 启用中断
  // // 所有CPU都进入调度器，开始调度用户进程
  //  scheduler();  
  for(;;){}      
    8000009c:	a001                	j	8000009c <main+0x62>
    initlock(&start_lock,"start_lock");
    8000009e:	00003597          	auipc	a1,0x3
    800000a2:	f6258593          	add	a1,a1,-158 # 80003000 <etext>
    800000a6:	00003517          	auipc	a0,0x3
    800000aa:	44a50513          	add	a0,a0,1098 # 800034f0 <start_lock>
    800000ae:	00001097          	auipc	ra,0x1
    800000b2:	218080e7          	jalr	536(ra) # 800012c6 <initlock>
    consoleinit();       // 初始化控制台
    800000b6:	00000097          	auipc	ra,0x0
    800000ba:	3b8080e7          	jalr	952(ra) # 8000046e <consoleinit>
    printfinit();        // 初始化printf功能
    800000be:	00001097          	auipc	ra,0x1
    800000c2:	8ee080e7          	jalr	-1810(ra) # 800009ac <printfinit>
    printf("\n");
    800000c6:	00003517          	auipc	a0,0x3
    800000ca:	f5a50513          	add	a0,a0,-166 # 80003020 <etext+0x20>
    800000ce:	00000097          	auipc	ra,0x0
    800000d2:	6fe080e7          	jalr	1790(ra) # 800007cc <printf>
    printf("hart %d starting\n", cpuid());
    800000d6:	00001097          	auipc	ra,0x1
    800000da:	f2c080e7          	jalr	-212(ra) # 80001002 <cpuid>
    800000de:	85aa                	mv	a1,a0
    800000e0:	00003517          	auipc	a0,0x3
    800000e4:	f3050513          	add	a0,a0,-208 # 80003010 <etext+0x10>
    800000e8:	00000097          	auipc	ra,0x0
    800000ec:	6e4080e7          	jalr	1764(ra) # 800007cc <printf>
    kinit();             // 物理页面分配器初始化
    800000f0:	00001097          	auipc	ra,0x1
    800000f4:	9b2080e7          	jalr	-1614(ra) # 80000aa2 <kinit>
    kvminit();           // 创建内核页表
    800000f8:	00001097          	auipc	ra,0x1
    800000fc:	d08080e7          	jalr	-760(ra) # 80000e00 <kvminit>
    kvminithart();       // 开启分页机制
    80000100:	00001097          	auipc	ra,0x1
    80000104:	a6e080e7          	jalr	-1426(ra) # 80000b6e <kvminithart>
    timer_create();           // 陷阱向量(时钟中断）初始化
    80000108:	00000097          	auipc	ra,0x0
    8000010c:	136080e7          	jalr	310(ra) # 8000023e <timer_create>
    trapinithart();      // 安装内核陷阱向量
    80000110:	00001097          	auipc	ra,0x1
    80000114:	342080e7          	jalr	834(ra) # 80001452 <trapinithart>
    plicinit();          // 设置中断控制器
    80000118:	00000097          	auipc	ra,0x0
    8000011c:	386080e7          	jalr	902(ra) # 8000049e <plicinit>
    plicinithart();      // 向PLIC请求设备中断
    80000120:	00000097          	auipc	ra,0x0
    80000124:	394080e7          	jalr	916(ra) # 800004b4 <plicinithart>
    proc_make_fisrt();   // 创建第一个用户进程 userinit();       
    80000128:	00001097          	auipc	ra,0x1
    8000012c:	008080e7          	jalr	8(ra) # 80001130 <proc_make_fisrt>
    printf("hart %d proc fail\n", cpuid());
    80000130:	00001097          	auipc	ra,0x1
    80000134:	ed2080e7          	jalr	-302(ra) # 80001002 <cpuid>
    80000138:	85aa                	mv	a1,a0
    8000013a:	00003517          	auipc	a0,0x3
    8000013e:	eee50513          	add	a0,a0,-274 # 80003028 <etext+0x28>
    80000142:	00000097          	auipc	ra,0x0
    80000146:	68a080e7          	jalr	1674(ra) # 800007cc <printf>
        started = 1;         // 标记系统启动完成
    8000014a:	4785                	li	a5,1
    8000014c:	00003717          	auipc	a4,0x3
    80000150:	36f72a23          	sw	a5,884(a4) # 800034c0 <started>
    __sync_synchronize();
    80000154:	0ff0000f          	fence
    80000158:	bf25                	j	80000090 <main+0x56>

000000008000015a <start>:
extern void main();

__attribute__ ((aligned (16))) char stack0[4096 * NCPU];


void start() {
    8000015a:	1141                	add	sp,sp,-16
    8000015c:	e406                	sd	ra,8(sp)
    8000015e:	e022                	sd	s0,0(sp)
    80000160:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000162:	300027f3          	csrr	a5,mstatus
  // 设置M模式下的前一特权级为管理者模式(Supervisor)，供mret指令使用
  // 当mret执行时，会切换到管理者模式继续执行
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;  // 清除MPP位域
    80000166:	7779                	lui	a4,0xffffe
    80000168:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fff2bb7>
    8000016c:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;      // 设置MPP为管理者模式
    8000016e:	6705                	lui	a4,0x1
    80000170:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80000174:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000176:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    8000017a:	00000797          	auipc	a5,0x0
    8000017e:	ec078793          	add	a5,a5,-320 # 8000003a <main>
    80000182:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80000186:	4781                	li	a5,0
    80000188:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    8000018c:	67c1                	lui	a5,0x10
    8000018e:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000190:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000194:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000198:	104027f3          	csrr	a5,sie

  // 将所有中断和异常委托给管理者模式处理
  w_medeleg(0xffff);  // 异常委托
  w_mideleg(0xffff);  // 中断委托
  // 启用管理者模式的外部中断、定时器中断和软件中断
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    8000019c:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800001a0:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800001a4:	57fd                	li	a5,-1
    800001a6:	83a9                	srl	a5,a5,0xa
    800001a8:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800001ac:	47bd                	li	a5,15
    800001ae:	3a079073          	csrw	pmpcfg0,a5
  w_pmpaddr0(0x3fffffffffffffull);  // 设置PMP地址范围
  w_pmpcfg0(0xf);                   // 设置PMP配置(读写执行权限)

  
  // 请求时钟中断服务
  timer_init();
    800001b2:	00000097          	auipc	ra,0x0
    800001b6:	01c080e7          	jalr	28(ra) # 800001ce <timer_init>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800001ba:	f14027f3          	csrr	a5,mhartid

  // 将当前CPU的hartid保存到tp寄存器中，供cpuid()函数使用
  // 在进入管理者模式中, mhartid寄存器不可用
  int id = r_mhartid();
  w_tp(id);
    800001be:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800001c0:	823e                	mv	tp,a5


  // 切换到管理者模式并跳转到main()函数
  asm volatile("mret");
    800001c2:	30200073          	mret
}
    800001c6:	60a2                	ld	ra,8(sp)
    800001c8:	6402                	ld	s0,0(sp)
    800001ca:	0141                	add	sp,sp,16
    800001cc:	8082                	ret

00000000800001ce <timer_init>:
// 完成以下设置来接收M-Mode下的时钟中断
// 时钟中断会进入到kernelvec.S中的timervec
// 在这之后会将它们转化为软中断进而被trap.c中的devintr接管
void
timer_init()
{
    800001ce:	1141                	add	sp,sp,-16
    800001d0:	e422                	sd	s0,8(sp)
    800001d2:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800001d4:	f14027f3          	csrr	a5,mhartid
  // 每个CPU都有独立的定时器中断源
  int id = r_mhartid();
    800001d8:	0007859b          	sext.w	a1,a5

  // 向CLINT(核心本地中断控制器)请求定时器中断
  int interval = 1000000; // 周期数；在QEMU中大约是1/10秒
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    800001dc:	0037979b          	sllw	a5,a5,0x3
    800001e0:	02004737          	lui	a4,0x2004
    800001e4:	97ba                	add	a5,a5,a4
    800001e6:	0200c737          	lui	a4,0x200c
    800001ea:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    800001ee:	000f4637          	lui	a2,0xf4
    800001f2:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    800001f6:	9732                	add	a4,a4,a2
    800001f8:	e398                	sd	a4,0(a5)

  // 在scratch[]中为timervec准备信息
  // scratch[0..2] : timervec保存寄存器的空间
  // scratch[3] : CLINT MTIMECMP寄存器地址
  // scratch[4] : 定时器中断之间期望的间隔(周期数)
  uint64 *scratch = &timer_scratch[id][0];
    800001fa:	00259693          	sll	a3,a1,0x2
    800001fe:	96ae                	add	a3,a3,a1
    80000200:	068e                	sll	a3,a3,0x3
    80000202:	0000b717          	auipc	a4,0xb
    80000206:	30e70713          	add	a4,a4,782 # 8000b510 <timer_scratch>
    8000020a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000020c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000020e:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000210:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000214:	00001797          	auipc	a5,0x1
    80000218:	67c78793          	add	a5,a5,1660 # 80001890 <timervec>
    8000021c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000220:	300027f3          	csrr	a5,mstatus

  // 设置机器模式的陷阱处理程序
  w_mtvec((uint64)timervec);

  // 启用机器模式中断
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000224:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000228:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000022c:	304027f3          	csrr	a5,mie

  // 启用机器模式定时器中断
  w_mie(r_mie() | MIE_MTIE);
    80000230:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000234:	30479073          	csrw	mie,a5
}
    80000238:	6422                	ld	s0,8(sp)
    8000023a:	0141                	add	sp,sp,16
    8000023c:	8082                	ret

000000008000023e <timer_create>:
static timer_t sys_timer;

// 时钟创建(初始化系统时钟)
// 陷阱初始化函数
void timer_create()
{
    8000023e:	1141                	add	sp,sp,-16
    80000240:	e406                	sd	ra,8(sp)
    80000242:	e022                	sd	s0,0(sp)
    80000244:	0800                	add	s0,sp,16
    initlock(&sys_timer.lk, "sys_timer");
    80000246:	00003597          	auipc	a1,0x3
    8000024a:	dfa58593          	add	a1,a1,-518 # 80003040 <etext+0x40>
    8000024e:	0000b517          	auipc	a0,0xb
    80000252:	40a50513          	add	a0,a0,1034 # 8000b658 <sys_timer+0x8>
    80000256:	00001097          	auipc	ra,0x1
    8000025a:	070080e7          	jalr	112(ra) # 800012c6 <initlock>
    sys_timer.ticks = 0;
    8000025e:	0000b797          	auipc	a5,0xb
    80000262:	3e07b923          	sd	zero,1010(a5) # 8000b650 <sys_timer>
}
    80000266:	60a2                	ld	ra,8(sp)
    80000268:	6402                	ld	s0,0(sp)
    8000026a:	0141                	add	sp,sp,16
    8000026c:	8082                	ret

000000008000026e <timer_update>:

// 时钟更新(ticks++ with lock)
void timer_update()
{
    8000026e:	1101                	add	sp,sp,-32
    80000270:	ec06                	sd	ra,24(sp)
    80000272:	e822                	sd	s0,16(sp)
    80000274:	e426                	sd	s1,8(sp)
    80000276:	e04a                	sd	s2,0(sp)
    80000278:	1000                	add	s0,sp,32
    acquire(&sys_timer.lk);
    8000027a:	0000b917          	auipc	s2,0xb
    8000027e:	29690913          	add	s2,s2,662 # 8000b510 <timer_scratch>
    80000282:	0000b497          	auipc	s1,0xb
    80000286:	3d648493          	add	s1,s1,982 # 8000b658 <sys_timer+0x8>
    8000028a:	8526                	mv	a0,s1
    8000028c:	00001097          	auipc	ra,0x1
    80000290:	0ca080e7          	jalr	202(ra) # 80001356 <acquire>
    sys_timer.ticks++;
    80000294:	14093783          	ld	a5,320(s2)
    80000298:	0785                	add	a5,a5,1
    8000029a:	14f93023          	sd	a5,320(s2)
    // printf("ticks: %d\n", sys_timer.ticks);
    release(&sys_timer.lk);
    8000029e:	8526                	mv	a0,s1
    800002a0:	00001097          	auipc	ra,0x1
    800002a4:	16a080e7          	jalr	362(ra) # 8000140a <release>
}
    800002a8:	60e2                	ld	ra,24(sp)
    800002aa:	6442                	ld	s0,16(sp)
    800002ac:	64a2                	ld	s1,8(sp)
    800002ae:	6902                	ld	s2,0(sp)
    800002b0:	6105                	add	sp,sp,32
    800002b2:	8082                	ret

00000000800002b4 <timer_get_ticks>:

// 返回系统时钟ticks
uint64 timer_get_ticks()
{
    800002b4:	1101                	add	sp,sp,-32
    800002b6:	ec06                	sd	ra,24(sp)
    800002b8:	e822                	sd	s0,16(sp)
    800002ba:	e426                	sd	s1,8(sp)
    800002bc:	e04a                	sd	s2,0(sp)
    800002be:	1000                	add	s0,sp,32
    uint64 xticks;
    acquire(&sys_timer.lk);
    800002c0:	0000b497          	auipc	s1,0xb
    800002c4:	39848493          	add	s1,s1,920 # 8000b658 <sys_timer+0x8>
    800002c8:	8526                	mv	a0,s1
    800002ca:	00001097          	auipc	ra,0x1
    800002ce:	08c080e7          	jalr	140(ra) # 80001356 <acquire>
    xticks = sys_timer.ticks;
    800002d2:	0000b917          	auipc	s2,0xb
    800002d6:	37e93903          	ld	s2,894(s2) # 8000b650 <sys_timer>
    release(&sys_timer.lk);
    800002da:	8526                	mv	a0,s1
    800002dc:	00001097          	auipc	ra,0x1
    800002e0:	12e080e7          	jalr	302(ra) # 8000140a <release>
    return xticks;
    800002e4:	854a                	mv	a0,s2
    800002e6:	60e2                	ld	ra,24(sp)
    800002e8:	6442                	ld	s0,16(sp)
    800002ea:	64a2                	ld	s1,8(sp)
    800002ec:	6902                	ld	s2,0(sp)
    800002ee:	6105                	add	sp,sp,32
    800002f0:	8082                	ret

00000000800002f2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800002f2:	1141                	add	sp,sp,-16
    800002f4:	e406                	sd	ra,8(sp)
    800002f6:	e022                	sd	s0,0(sp)
    800002f8:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800002fa:	100007b7          	lui	a5,0x10000
    800002fe:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000302:	f8000713          	li	a4,-128
    80000306:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000030a:	470d                	li	a4,3
    8000030c:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000310:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000314:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000318:	469d                	li	a3,7
    8000031a:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000031e:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000322:	00003597          	auipc	a1,0x3
    80000326:	d2e58593          	add	a1,a1,-722 # 80003050 <etext+0x50>
    8000032a:	0000b517          	auipc	a0,0xb
    8000032e:	34650513          	add	a0,a0,838 # 8000b670 <uart_tx_lock>
    80000332:	00001097          	auipc	ra,0x1
    80000336:	f94080e7          	jalr	-108(ra) # 800012c6 <initlock>
}
    8000033a:	60a2                	ld	ra,8(sp)
    8000033c:	6402                	ld	s0,0(sp)
    8000033e:	0141                	add	sp,sp,16
    80000340:	8082                	ret

0000000080000342 <uartputc_sync>:
// 不使用中断的uartputc的替换版本
// 用于内核printf和回显字符
// 它会持续等待uart的输出寄存器为空(同步性、阻塞性)
void
uartputc_sync(int c)
{
    80000342:	1101                	add	sp,sp,-32
    80000344:	ec06                	sd	ra,24(sp)
    80000346:	e822                	sd	s0,16(sp)
    80000348:	e426                	sd	s1,8(sp)
    8000034a:	1000                	add	s0,sp,32
    8000034c:	84aa                	mv	s1,a0
  // 关中断，防止串口中断再次进入造成竞争
  push_off();
    8000034e:	00001097          	auipc	ra,0x1
    80000352:	fbc080e7          	jalr	-68(ra) # 8000130a <push_off>
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    80000356:	00003797          	auipc	a5,0x3
    8000035a:	1827a783          	lw	a5,386(a5) # 800034d8 <panicked>
    for(;;)
      ;
  }

  // 等待LSR中的发送寄存器为空标识被置位
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000035e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000362:	c391                	beqz	a5,80000366 <uartputc_sync+0x24>
    for(;;)
    80000364:	a001                	j	80000364 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000366:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000036a:	0207f793          	and	a5,a5,32
    8000036e:	dfe5                	beqz	a5,80000366 <uartputc_sync+0x24>
    ;
  
  // 立即通过UART发送字符
  WriteReg(THR, c);
    80000370:	0ff4f513          	zext.b	a0,s1
    80000374:	100007b7          	lui	a5,0x10000
    80000378:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
  
  // 恢复之前的中断状态
  pop_off();
    8000037c:	00001097          	auipc	ra,0x1
    80000380:	02e080e7          	jalr	46(ra) # 800013aa <pop_off>
}
    80000384:	60e2                	ld	ra,24(sp)
    80000386:	6442                	ld	s0,16(sp)
    80000388:	64a2                	ld	s1,8(sp)
    8000038a:	6105                	add	sp,sp,32
    8000038c:	8082                	ret

000000008000038e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000038e:	1141                	add	sp,sp,-16
    80000390:	e422                	sd	s0,8(sp)
    80000392:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000394:	100007b7          	lui	a5,0x10000
    80000398:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000039c:	8b85                	and	a5,a5,1
    8000039e:	cb81                	beqz	a5,800003ae <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800003a0:	100007b7          	lui	a5,0x10000
    800003a4:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800003a8:	6422                	ld	s0,8(sp)
    800003aa:	0141                	add	sp,sp,16
    800003ac:	8082                	ret
    return -1;
    800003ae:	557d                	li	a0,-1
    800003b0:	bfe5                	j	800003a8 <uartgetc+0x1a>

00000000800003b2 <uartintr>:
// 注意两种情况下会触发此函数：
// 1.输入通道RX为满(即键盘有数据输入)
// 2.输出通道TX为空
void
uartintr(void)
{
    800003b2:	1101                	add	sp,sp,-32
    800003b4:	ec06                	sd	ra,24(sp)
    800003b6:	e822                	sd	s0,16(sp)
    800003b8:	e426                	sd	s1,8(sp)
    800003ba:	1000                	add	s0,sp,32
  // release(&uart_tx_lock);
  
  while(1)
  {
    int c = uartgetc();
    if(c == -1) break;
    800003bc:	54fd                	li	s1,-1
    800003be:	a029                	j	800003c8 <uartintr+0x16>
    consputc(c);
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	06c080e7          	jalr	108(ra) # 8000042c <consputc>
    int c = uartgetc();
    800003c8:	00000097          	auipc	ra,0x0
    800003cc:	fc6080e7          	jalr	-58(ra) # 8000038e <uartgetc>
    if(c == -1) break;
    800003d0:	fe9518e3          	bne	a0,s1,800003c0 <uartintr+0xe>
  }
}
    800003d4:	60e2                	ld	ra,24(sp)
    800003d6:	6442                	ld	s0,16(sp)
    800003d8:	64a2                	ld	s1,8(sp)
    800003da:	6105                	add	sp,sp,32
    800003dc:	8082                	ret

00000000800003de <uart_putc>:


void uart_putc(char c) {
    800003de:	1141                	add	sp,sp,-16
    800003e0:	e422                	sd	s0,8(sp)
    800003e2:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    800003e4:	10000737          	lui	a4,0x10000
    800003e8:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800003ec:	0207f793          	and	a5,a5,32
    800003f0:	dfe5                	beqz	a5,800003e8 <uart_putc+0xa>
    uart[0] = c;
    800003f2:	100007b7          	lui	a5,0x10000
    800003f6:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    800003fa:	6422                	ld	s0,8(sp)
    800003fc:	0141                	add	sp,sp,16
    800003fe:	8082                	ret

0000000080000400 <uart_puts>:

void uart_puts(char *s) {
    80000400:	1101                	add	sp,sp,-32
    80000402:	ec06                	sd	ra,24(sp)
    80000404:	e822                	sd	s0,16(sp)
    80000406:	e426                	sd	s1,8(sp)
    80000408:	1000                	add	s0,sp,32
    8000040a:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    8000040c:	00054503          	lbu	a0,0(a0)
    80000410:	c909                	beqz	a0,80000422 <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    80000412:	00000097          	auipc	ra,0x0
    80000416:	fcc080e7          	jalr	-52(ra) # 800003de <uart_putc>
        s++;              // 移动到下一个字符
    8000041a:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    8000041c:	0004c503          	lbu	a0,0(s1)
    80000420:	f96d                	bnez	a0,80000412 <uart_puts+0x12>
    }
}
    80000422:	60e2                	ld	ra,24(sp)
    80000424:	6442                	ld	s0,16(sp)
    80000426:	64a2                	ld	s1,8(sp)
    80000428:	6105                	add	sp,sp,32
    8000042a:	8082                	ret

000000008000042c <consputc>:

// 发送一个字符到UART，被(内核)printf调用，以及回显输入字符
// 但不会被write()调用
void
consputc(int c)
{
    8000042c:	1141                	add	sp,sp,-16
    8000042e:	e406                	sd	ra,8(sp)
    80000430:	e022                	sd	s0,0(sp)
    80000432:	0800                	add	s0,sp,16
  // 如果当前字符是退格键
  if(c == BACKSPACE){
    80000434:	07f00793          	li	a5,127
    80000438:	00f50a63          	beq	a0,a5,8000044c <consputc+0x20>

    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    
    // 如果不是退格键，那么按照原样字符输出
    uartputc_sync(c);
    8000043c:	00000097          	auipc	ra,0x0
    80000440:	f06080e7          	jalr	-250(ra) # 80000342 <uartputc_sync>
  }
}
    80000444:	60a2                	ld	ra,8(sp)
    80000446:	6402                	ld	s0,0(sp)
    80000448:	0141                	add	sp,sp,16
    8000044a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000044c:	4521                	li	a0,8
    8000044e:	00000097          	auipc	ra,0x0
    80000452:	ef4080e7          	jalr	-268(ra) # 80000342 <uartputc_sync>
    80000456:	02000513          	li	a0,32
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	ee8080e7          	jalr	-280(ra) # 80000342 <uartputc_sync>
    80000462:	4521                	li	a0,8
    80000464:	00000097          	auipc	ra,0x0
    80000468:	ede080e7          	jalr	-290(ra) # 80000342 <uartputc_sync>
    8000046c:	bfe1                	j	80000444 <consputc+0x18>

000000008000046e <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    8000046e:	1141                	add	sp,sp,-16
    80000470:	e406                	sd	ra,8(sp)
    80000472:	e022                	sd	s0,0(sp)
    80000474:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000476:	00003597          	auipc	a1,0x3
    8000047a:	be258593          	add	a1,a1,-1054 # 80003058 <etext+0x58>
    8000047e:	0000b517          	auipc	a0,0xb
    80000482:	22a50513          	add	a0,a0,554 # 8000b6a8 <cons>
    80000486:	00001097          	auipc	ra,0x1
    8000048a:	e40080e7          	jalr	-448(ra) # 800012c6 <initlock>

  uartinit();
    8000048e:	00000097          	auipc	ra,0x0
    80000492:	e64080e7          	jalr	-412(ra) # 800002f2 <uartinit>

  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    80000496:	60a2                	ld	ra,8(sp)
    80000498:	6402                	ld	s0,0(sp)
    8000049a:	0141                	add	sp,sp,16
    8000049c:	8082                	ret

000000008000049e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000049e:	1141                	add	sp,sp,-16
    800004a0:	e422                	sd	s0,8(sp)
    800004a2:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800004a4:	0c0007b7          	lui	a5,0xc000
    800004a8:	4705                	li	a4,1
    800004aa:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800004ac:	c3d8                	sw	a4,4(a5)
}
    800004ae:	6422                	ld	s0,8(sp)
    800004b0:	0141                	add	sp,sp,16
    800004b2:	8082                	ret

00000000800004b4 <plicinithart>:

void
plicinithart(void)
{
    800004b4:	1141                	add	sp,sp,-16
    800004b6:	e406                	sd	ra,8(sp)
    800004b8:	e022                	sd	s0,0(sp)
    800004ba:	0800                	add	s0,sp,16
  int hart = cpuid();
    800004bc:	00001097          	auipc	ra,0x1
    800004c0:	b46080e7          	jalr	-1210(ra) # 80001002 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800004c4:	0085171b          	sllw	a4,a0,0x8
    800004c8:	0c0027b7          	lui	a5,0xc002
    800004cc:	97ba                	add	a5,a5,a4
    800004ce:	40200713          	li	a4,1026
    800004d2:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800004d6:	00d5151b          	sllw	a0,a0,0xd
    800004da:	0c2017b7          	lui	a5,0xc201
    800004de:	97aa                	add	a5,a5,a0
    800004e0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800004e4:	60a2                	ld	ra,8(sp)
    800004e6:	6402                	ld	s0,0(sp)
    800004e8:	0141                	add	sp,sp,16
    800004ea:	8082                	ret

00000000800004ec <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800004ec:	1141                	add	sp,sp,-16
    800004ee:	e406                	sd	ra,8(sp)
    800004f0:	e022                	sd	s0,0(sp)
    800004f2:	0800                	add	s0,sp,16
  int hart = cpuid();
    800004f4:	00001097          	auipc	ra,0x1
    800004f8:	b0e080e7          	jalr	-1266(ra) # 80001002 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800004fc:	00d5151b          	sllw	a0,a0,0xd
    80000500:	0c2017b7          	lui	a5,0xc201
    80000504:	97aa                	add	a5,a5,a0
  return irq;
}
    80000506:	43c8                	lw	a0,4(a5)
    80000508:	60a2                	ld	ra,8(sp)
    8000050a:	6402                	ld	s0,0(sp)
    8000050c:	0141                	add	sp,sp,16
    8000050e:	8082                	ret

0000000080000510 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80000510:	1101                	add	sp,sp,-32
    80000512:	ec06                	sd	ra,24(sp)
    80000514:	e822                	sd	s0,16(sp)
    80000516:	e426                	sd	s1,8(sp)
    80000518:	1000                	add	s0,sp,32
    8000051a:	84aa                	mv	s1,a0
  int hart = cpuid();
    8000051c:	00001097          	auipc	ra,0x1
    80000520:	ae6080e7          	jalr	-1306(ra) # 80001002 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80000524:	00d5151b          	sllw	a0,a0,0xd
    80000528:	0c2017b7          	lui	a5,0xc201
    8000052c:	97aa                	add	a5,a5,a0
    8000052e:	c3c4                	sw	s1,4(a5)
}
    80000530:	60e2                	ld	ra,24(sp)
    80000532:	6442                	ld	s0,16(sp)
    80000534:	64a2                	ld	s1,8(sp)
    80000536:	6105                	add	sp,sp,32
    80000538:	8082                	ret

000000008000053a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000053a:	1141                	add	sp,sp,-16
    8000053c:	e422                	sd	s0,8(sp)
    8000053e:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000540:	ca19                	beqz	a2,80000556 <memset+0x1c>
    80000542:	87aa                	mv	a5,a0
    80000544:	1602                	sll	a2,a2,0x20
    80000546:	9201                	srl	a2,a2,0x20
    80000548:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    8000054c:	00b78023          	sb	a1,0(a5) # c201000 <_entry-0x73dff000>
  for(i = 0; i < n; i++){
    80000550:	0785                	add	a5,a5,1
    80000552:	fee79de3          	bne	a5,a4,8000054c <memset+0x12>
  }
  return dst;
}
    80000556:	6422                	ld	s0,8(sp)
    80000558:	0141                	add	sp,sp,16
    8000055a:	8082                	ret

000000008000055c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    8000055c:	1141                	add	sp,sp,-16
    8000055e:	e422                	sd	s0,8(sp)
    80000560:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000562:	ca05                	beqz	a2,80000592 <memcmp+0x36>
    80000564:	fff6069b          	addw	a3,a2,-1
    80000568:	1682                	sll	a3,a3,0x20
    8000056a:	9281                	srl	a3,a3,0x20
    8000056c:	0685                	add	a3,a3,1
    8000056e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000570:	00054783          	lbu	a5,0(a0)
    80000574:	0005c703          	lbu	a4,0(a1)
    80000578:	00e79863          	bne	a5,a4,80000588 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000057c:	0505                	add	a0,a0,1
    8000057e:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000580:	fed518e3          	bne	a0,a3,80000570 <memcmp+0x14>
  }

  return 0;
    80000584:	4501                	li	a0,0
    80000586:	a019                	j	8000058c <memcmp+0x30>
      return *s1 - *s2;
    80000588:	40e7853b          	subw	a0,a5,a4
}
    8000058c:	6422                	ld	s0,8(sp)
    8000058e:	0141                	add	sp,sp,16
    80000590:	8082                	ret
  return 0;
    80000592:	4501                	li	a0,0
    80000594:	bfe5                	j	8000058c <memcmp+0x30>

0000000080000596 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000596:	1141                	add	sp,sp,-16
    80000598:	e422                	sd	s0,8(sp)
    8000059a:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000059c:	c205                	beqz	a2,800005bc <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000059e:	02a5e263          	bltu	a1,a0,800005c2 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800005a2:	1602                	sll	a2,a2,0x20
    800005a4:	9201                	srl	a2,a2,0x20
    800005a6:	00c587b3          	add	a5,a1,a2
{
    800005aa:	872a                	mv	a4,a0
      *d++ = *s++;
    800005ac:	0585                	add	a1,a1,1
    800005ae:	0705                	add	a4,a4,1
    800005b0:	fff5c683          	lbu	a3,-1(a1)
    800005b4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800005b8:	fef59ae3          	bne	a1,a5,800005ac <memmove+0x16>

  return dst;
}
    800005bc:	6422                	ld	s0,8(sp)
    800005be:	0141                	add	sp,sp,16
    800005c0:	8082                	ret
  if(s < d && s + n > d){
    800005c2:	02061693          	sll	a3,a2,0x20
    800005c6:	9281                	srl	a3,a3,0x20
    800005c8:	00d58733          	add	a4,a1,a3
    800005cc:	fce57be3          	bgeu	a0,a4,800005a2 <memmove+0xc>
    d += n;
    800005d0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800005d2:	fff6079b          	addw	a5,a2,-1
    800005d6:	1782                	sll	a5,a5,0x20
    800005d8:	9381                	srl	a5,a5,0x20
    800005da:	fff7c793          	not	a5,a5
    800005de:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800005e0:	177d                	add	a4,a4,-1
    800005e2:	16fd                	add	a3,a3,-1
    800005e4:	00074603          	lbu	a2,0(a4)
    800005e8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800005ec:	fee79ae3          	bne	a5,a4,800005e0 <memmove+0x4a>
    800005f0:	b7f1                	j	800005bc <memmove+0x26>

00000000800005f2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800005f2:	1141                	add	sp,sp,-16
    800005f4:	e406                	sd	ra,8(sp)
    800005f6:	e022                	sd	s0,0(sp)
    800005f8:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    800005fa:	00000097          	auipc	ra,0x0
    800005fe:	f9c080e7          	jalr	-100(ra) # 80000596 <memmove>
}
    80000602:	60a2                	ld	ra,8(sp)
    80000604:	6402                	ld	s0,0(sp)
    80000606:	0141                	add	sp,sp,16
    80000608:	8082                	ret

000000008000060a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    8000060a:	1141                	add	sp,sp,-16
    8000060c:	e422                	sd	s0,8(sp)
    8000060e:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000610:	ce11                	beqz	a2,8000062c <strncmp+0x22>
    80000612:	00054783          	lbu	a5,0(a0)
    80000616:	cf89                	beqz	a5,80000630 <strncmp+0x26>
    80000618:	0005c703          	lbu	a4,0(a1)
    8000061c:	00f71a63          	bne	a4,a5,80000630 <strncmp+0x26>
    n--, p++, q++;
    80000620:	367d                	addw	a2,a2,-1
    80000622:	0505                	add	a0,a0,1
    80000624:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000626:	f675                	bnez	a2,80000612 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000628:	4501                	li	a0,0
    8000062a:	a809                	j	8000063c <strncmp+0x32>
    8000062c:	4501                	li	a0,0
    8000062e:	a039                	j	8000063c <strncmp+0x32>
  if(n == 0)
    80000630:	ca09                	beqz	a2,80000642 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000632:	00054503          	lbu	a0,0(a0)
    80000636:	0005c783          	lbu	a5,0(a1)
    8000063a:	9d1d                	subw	a0,a0,a5
}
    8000063c:	6422                	ld	s0,8(sp)
    8000063e:	0141                	add	sp,sp,16
    80000640:	8082                	ret
    return 0;
    80000642:	4501                	li	a0,0
    80000644:	bfe5                	j	8000063c <strncmp+0x32>

0000000080000646 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000646:	1141                	add	sp,sp,-16
    80000648:	e422                	sd	s0,8(sp)
    8000064a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000064c:	87aa                	mv	a5,a0
    8000064e:	86b2                	mv	a3,a2
    80000650:	367d                	addw	a2,a2,-1
    80000652:	00d05963          	blez	a3,80000664 <strncpy+0x1e>
    80000656:	0785                	add	a5,a5,1
    80000658:	0005c703          	lbu	a4,0(a1)
    8000065c:	fee78fa3          	sb	a4,-1(a5)
    80000660:	0585                	add	a1,a1,1
    80000662:	f775                	bnez	a4,8000064e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000664:	873e                	mv	a4,a5
    80000666:	9fb5                	addw	a5,a5,a3
    80000668:	37fd                	addw	a5,a5,-1
    8000066a:	00c05963          	blez	a2,8000067c <strncpy+0x36>
    *s++ = 0;
    8000066e:	0705                	add	a4,a4,1
    80000670:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000674:	40e786bb          	subw	a3,a5,a4
    80000678:	fed04be3          	bgtz	a3,8000066e <strncpy+0x28>
  return os;
}
    8000067c:	6422                	ld	s0,8(sp)
    8000067e:	0141                	add	sp,sp,16
    80000680:	8082                	ret

0000000080000682 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000682:	1141                	add	sp,sp,-16
    80000684:	e422                	sd	s0,8(sp)
    80000686:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000688:	02c05363          	blez	a2,800006ae <safestrcpy+0x2c>
    8000068c:	fff6069b          	addw	a3,a2,-1
    80000690:	1682                	sll	a3,a3,0x20
    80000692:	9281                	srl	a3,a3,0x20
    80000694:	96ae                	add	a3,a3,a1
    80000696:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000698:	00d58963          	beq	a1,a3,800006aa <safestrcpy+0x28>
    8000069c:	0585                	add	a1,a1,1
    8000069e:	0785                	add	a5,a5,1
    800006a0:	fff5c703          	lbu	a4,-1(a1)
    800006a4:	fee78fa3          	sb	a4,-1(a5)
    800006a8:	fb65                	bnez	a4,80000698 <safestrcpy+0x16>
    ;
  *s = 0;
    800006aa:	00078023          	sb	zero,0(a5)
  return os;
}
    800006ae:	6422                	ld	s0,8(sp)
    800006b0:	0141                	add	sp,sp,16
    800006b2:	8082                	ret

00000000800006b4 <strlen>:

int
strlen(const char *s)
{
    800006b4:	1141                	add	sp,sp,-16
    800006b6:	e422                	sd	s0,8(sp)
    800006b8:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800006ba:	00054783          	lbu	a5,0(a0)
    800006be:	cf91                	beqz	a5,800006da <strlen+0x26>
    800006c0:	0505                	add	a0,a0,1
    800006c2:	87aa                	mv	a5,a0
    800006c4:	86be                	mv	a3,a5
    800006c6:	0785                	add	a5,a5,1
    800006c8:	fff7c703          	lbu	a4,-1(a5)
    800006cc:	ff65                	bnez	a4,800006c4 <strlen+0x10>
    800006ce:	40a6853b          	subw	a0,a3,a0
    800006d2:	2505                	addw	a0,a0,1
    ;
  return n;
}
    800006d4:	6422                	ld	s0,8(sp)
    800006d6:	0141                	add	sp,sp,16
    800006d8:	8082                	ret
  for(n = 0; s[n]; n++)
    800006da:	4501                	li	a0,0
    800006dc:	bfe5                	j	800006d4 <strlen+0x20>

00000000800006de <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800006de:	7179                	add	sp,sp,-48
    800006e0:	f406                	sd	ra,40(sp)
    800006e2:	f022                	sd	s0,32(sp)
    800006e4:	ec26                	sd	s1,24(sp)
    800006e6:	e84a                	sd	s2,16(sp)
    800006e8:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800006ea:	c219                	beqz	a2,800006f0 <printint+0x12>
    800006ec:	08054763          	bltz	a0,8000077a <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800006f0:	2501                	sext.w	a0,a0
    800006f2:	4881                	li	a7,0
    800006f4:	fd040693          	add	a3,s0,-48

  i = 0;
    800006f8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800006fa:	2581                	sext.w	a1,a1
    800006fc:	00003617          	auipc	a2,0x3
    80000700:	98c60613          	add	a2,a2,-1652 # 80003088 <digits>
    80000704:	883a                	mv	a6,a4
    80000706:	2705                	addw	a4,a4,1
    80000708:	02b577bb          	remuw	a5,a0,a1
    8000070c:	1782                	sll	a5,a5,0x20
    8000070e:	9381                	srl	a5,a5,0x20
    80000710:	97b2                	add	a5,a5,a2
    80000712:	0007c783          	lbu	a5,0(a5)
    80000716:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    8000071a:	0005079b          	sext.w	a5,a0
    8000071e:	02b5553b          	divuw	a0,a0,a1
    80000722:	0685                	add	a3,a3,1
    80000724:	feb7f0e3          	bgeu	a5,a1,80000704 <printint+0x26>

  if(sign)
    80000728:	00088c63          	beqz	a7,80000740 <printint+0x62>
    buf[i++] = '-';
    8000072c:	fe070793          	add	a5,a4,-32
    80000730:	00878733          	add	a4,a5,s0
    80000734:	02d00793          	li	a5,45
    80000738:	fef70823          	sb	a5,-16(a4)
    8000073c:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    80000740:	02e05763          	blez	a4,8000076e <printint+0x90>
    80000744:	fd040793          	add	a5,s0,-48
    80000748:	00e784b3          	add	s1,a5,a4
    8000074c:	fff78913          	add	s2,a5,-1
    80000750:	993a                	add	s2,s2,a4
    80000752:	377d                	addw	a4,a4,-1
    80000754:	1702                	sll	a4,a4,0x20
    80000756:	9301                	srl	a4,a4,0x20
    80000758:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000075c:	fff4c503          	lbu	a0,-1(s1)
    80000760:	00000097          	auipc	ra,0x0
    80000764:	ccc080e7          	jalr	-820(ra) # 8000042c <consputc>
  while(--i >= 0)
    80000768:	14fd                	add	s1,s1,-1
    8000076a:	ff2499e3          	bne	s1,s2,8000075c <printint+0x7e>
}
    8000076e:	70a2                	ld	ra,40(sp)
    80000770:	7402                	ld	s0,32(sp)
    80000772:	64e2                	ld	s1,24(sp)
    80000774:	6942                	ld	s2,16(sp)
    80000776:	6145                	add	sp,sp,48
    80000778:	8082                	ret
    x = -xx;
    8000077a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000077e:	4885                	li	a7,1
    x = -xx;
    80000780:	bf95                	j	800006f4 <printint+0x16>

0000000080000782 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000782:	1101                	add	sp,sp,-32
    80000784:	ec06                	sd	ra,24(sp)
    80000786:	e822                	sd	s0,16(sp)
    80000788:	e426                	sd	s1,8(sp)
    8000078a:	1000                	add	s0,sp,32
    8000078c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000078e:	0000b797          	auipc	a5,0xb
    80000792:	fc07ad23          	sw	zero,-38(a5) # 8000b768 <pr+0x18>
  printf("panic: ");
    80000796:	00003517          	auipc	a0,0x3
    8000079a:	8ca50513          	add	a0,a0,-1846 # 80003060 <etext+0x60>
    8000079e:	00000097          	auipc	ra,0x0
    800007a2:	02e080e7          	jalr	46(ra) # 800007cc <printf>
  printf(s);
    800007a6:	8526                	mv	a0,s1
    800007a8:	00000097          	auipc	ra,0x0
    800007ac:	024080e7          	jalr	36(ra) # 800007cc <printf>
  printf("\n");
    800007b0:	00003517          	auipc	a0,0x3
    800007b4:	87050513          	add	a0,a0,-1936 # 80003020 <etext+0x20>
    800007b8:	00000097          	auipc	ra,0x0
    800007bc:	014080e7          	jalr	20(ra) # 800007cc <printf>
  panicked = 1; // freeze uart output from other CPUs
    800007c0:	4785                	li	a5,1
    800007c2:	00003717          	auipc	a4,0x3
    800007c6:	d0f72b23          	sw	a5,-746(a4) # 800034d8 <panicked>
  for(;;)
    800007ca:	a001                	j	800007ca <panic+0x48>

00000000800007cc <printf>:
{
    800007cc:	7131                	add	sp,sp,-192
    800007ce:	fc86                	sd	ra,120(sp)
    800007d0:	f8a2                	sd	s0,112(sp)
    800007d2:	f4a6                	sd	s1,104(sp)
    800007d4:	f0ca                	sd	s2,96(sp)
    800007d6:	ecce                	sd	s3,88(sp)
    800007d8:	e8d2                	sd	s4,80(sp)
    800007da:	e4d6                	sd	s5,72(sp)
    800007dc:	e0da                	sd	s6,64(sp)
    800007de:	fc5e                	sd	s7,56(sp)
    800007e0:	f862                	sd	s8,48(sp)
    800007e2:	f466                	sd	s9,40(sp)
    800007e4:	f06a                	sd	s10,32(sp)
    800007e6:	ec6e                	sd	s11,24(sp)
    800007e8:	0100                	add	s0,sp,128
    800007ea:	8a2a                	mv	s4,a0
    800007ec:	e40c                	sd	a1,8(s0)
    800007ee:	e810                	sd	a2,16(s0)
    800007f0:	ec14                	sd	a3,24(s0)
    800007f2:	f018                	sd	a4,32(s0)
    800007f4:	f41c                	sd	a5,40(s0)
    800007f6:	03043823          	sd	a6,48(s0)
    800007fa:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800007fe:	0000bd97          	auipc	s11,0xb
    80000802:	f6adad83          	lw	s11,-150(s11) # 8000b768 <pr+0x18>
  if(locking)
    80000806:	020d9b63          	bnez	s11,8000083c <printf+0x70>
  if (fmt == 0)
    8000080a:	040a0263          	beqz	s4,8000084e <printf+0x82>
  va_start(ap, fmt);
    8000080e:	00840793          	add	a5,s0,8
    80000812:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000816:	000a4503          	lbu	a0,0(s4)
    8000081a:	14050f63          	beqz	a0,80000978 <printf+0x1ac>
    8000081e:	4981                	li	s3,0
    if(c != '%'){
    80000820:	02500a93          	li	s5,37
    switch(c){
    80000824:	07000b93          	li	s7,112
  consputc('x');
    80000828:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000082a:	00003b17          	auipc	s6,0x3
    8000082e:	85eb0b13          	add	s6,s6,-1954 # 80003088 <digits>
    switch(c){
    80000832:	07300c93          	li	s9,115
    80000836:	06400c13          	li	s8,100
    8000083a:	a82d                	j	80000874 <printf+0xa8>
    acquire(&pr.lock);
    8000083c:	0000b517          	auipc	a0,0xb
    80000840:	f1450513          	add	a0,a0,-236 # 8000b750 <pr>
    80000844:	00001097          	auipc	ra,0x1
    80000848:	b12080e7          	jalr	-1262(ra) # 80001356 <acquire>
    8000084c:	bf7d                	j	8000080a <printf+0x3e>
    panic("null fmt");
    8000084e:	00003517          	auipc	a0,0x3
    80000852:	82250513          	add	a0,a0,-2014 # 80003070 <etext+0x70>
    80000856:	00000097          	auipc	ra,0x0
    8000085a:	f2c080e7          	jalr	-212(ra) # 80000782 <panic>
      consputc(c);
    8000085e:	00000097          	auipc	ra,0x0
    80000862:	bce080e7          	jalr	-1074(ra) # 8000042c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000866:	2985                	addw	s3,s3,1
    80000868:	013a07b3          	add	a5,s4,s3
    8000086c:	0007c503          	lbu	a0,0(a5)
    80000870:	10050463          	beqz	a0,80000978 <printf+0x1ac>
    if(c != '%'){
    80000874:	ff5515e3          	bne	a0,s5,8000085e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000878:	2985                	addw	s3,s3,1
    8000087a:	013a07b3          	add	a5,s4,s3
    8000087e:	0007c783          	lbu	a5,0(a5)
    80000882:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000886:	cbed                	beqz	a5,80000978 <printf+0x1ac>
    switch(c){
    80000888:	05778a63          	beq	a5,s7,800008dc <printf+0x110>
    8000088c:	02fbf663          	bgeu	s7,a5,800008b8 <printf+0xec>
    80000890:	09978863          	beq	a5,s9,80000920 <printf+0x154>
    80000894:	07800713          	li	a4,120
    80000898:	0ce79563          	bne	a5,a4,80000962 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000089c:	f8843783          	ld	a5,-120(s0)
    800008a0:	00878713          	add	a4,a5,8
    800008a4:	f8e43423          	sd	a4,-120(s0)
    800008a8:	4605                	li	a2,1
    800008aa:	85ea                	mv	a1,s10
    800008ac:	4388                	lw	a0,0(a5)
    800008ae:	00000097          	auipc	ra,0x0
    800008b2:	e30080e7          	jalr	-464(ra) # 800006de <printint>
      break;
    800008b6:	bf45                	j	80000866 <printf+0x9a>
    switch(c){
    800008b8:	09578f63          	beq	a5,s5,80000956 <printf+0x18a>
    800008bc:	0b879363          	bne	a5,s8,80000962 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    800008c0:	f8843783          	ld	a5,-120(s0)
    800008c4:	00878713          	add	a4,a5,8
    800008c8:	f8e43423          	sd	a4,-120(s0)
    800008cc:	4605                	li	a2,1
    800008ce:	45a9                	li	a1,10
    800008d0:	4388                	lw	a0,0(a5)
    800008d2:	00000097          	auipc	ra,0x0
    800008d6:	e0c080e7          	jalr	-500(ra) # 800006de <printint>
      break;
    800008da:	b771                	j	80000866 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800008dc:	f8843783          	ld	a5,-120(s0)
    800008e0:	00878713          	add	a4,a5,8
    800008e4:	f8e43423          	sd	a4,-120(s0)
    800008e8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800008ec:	03000513          	li	a0,48
    800008f0:	00000097          	auipc	ra,0x0
    800008f4:	b3c080e7          	jalr	-1220(ra) # 8000042c <consputc>
  consputc('x');
    800008f8:	07800513          	li	a0,120
    800008fc:	00000097          	auipc	ra,0x0
    80000900:	b30080e7          	jalr	-1232(ra) # 8000042c <consputc>
    80000904:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000906:	03c95793          	srl	a5,s2,0x3c
    8000090a:	97da                	add	a5,a5,s6
    8000090c:	0007c503          	lbu	a0,0(a5)
    80000910:	00000097          	auipc	ra,0x0
    80000914:	b1c080e7          	jalr	-1252(ra) # 8000042c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000918:	0912                	sll	s2,s2,0x4
    8000091a:	34fd                	addw	s1,s1,-1
    8000091c:	f4ed                	bnez	s1,80000906 <printf+0x13a>
    8000091e:	b7a1                	j	80000866 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000920:	f8843783          	ld	a5,-120(s0)
    80000924:	00878713          	add	a4,a5,8
    80000928:	f8e43423          	sd	a4,-120(s0)
    8000092c:	6384                	ld	s1,0(a5)
    8000092e:	cc89                	beqz	s1,80000948 <printf+0x17c>
      for(; *s; s++)
    80000930:	0004c503          	lbu	a0,0(s1)
    80000934:	d90d                	beqz	a0,80000866 <printf+0x9a>
        consputc(*s);
    80000936:	00000097          	auipc	ra,0x0
    8000093a:	af6080e7          	jalr	-1290(ra) # 8000042c <consputc>
      for(; *s; s++)
    8000093e:	0485                	add	s1,s1,1
    80000940:	0004c503          	lbu	a0,0(s1)
    80000944:	f96d                	bnez	a0,80000936 <printf+0x16a>
    80000946:	b705                	j	80000866 <printf+0x9a>
        s = "(null)";
    80000948:	00002497          	auipc	s1,0x2
    8000094c:	72048493          	add	s1,s1,1824 # 80003068 <etext+0x68>
      for(; *s; s++)
    80000950:	02800513          	li	a0,40
    80000954:	b7cd                	j	80000936 <printf+0x16a>
      consputc('%');
    80000956:	8556                	mv	a0,s5
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	ad4080e7          	jalr	-1324(ra) # 8000042c <consputc>
      break;
    80000960:	b719                	j	80000866 <printf+0x9a>
      consputc('%');
    80000962:	8556                	mv	a0,s5
    80000964:	00000097          	auipc	ra,0x0
    80000968:	ac8080e7          	jalr	-1336(ra) # 8000042c <consputc>
      consputc(c);
    8000096c:	8526                	mv	a0,s1
    8000096e:	00000097          	auipc	ra,0x0
    80000972:	abe080e7          	jalr	-1346(ra) # 8000042c <consputc>
      break;
    80000976:	bdc5                	j	80000866 <printf+0x9a>
  if(locking)
    80000978:	020d9163          	bnez	s11,8000099a <printf+0x1ce>
}
    8000097c:	70e6                	ld	ra,120(sp)
    8000097e:	7446                	ld	s0,112(sp)
    80000980:	74a6                	ld	s1,104(sp)
    80000982:	7906                	ld	s2,96(sp)
    80000984:	69e6                	ld	s3,88(sp)
    80000986:	6a46                	ld	s4,80(sp)
    80000988:	6aa6                	ld	s5,72(sp)
    8000098a:	6b06                	ld	s6,64(sp)
    8000098c:	7be2                	ld	s7,56(sp)
    8000098e:	7c42                	ld	s8,48(sp)
    80000990:	7ca2                	ld	s9,40(sp)
    80000992:	7d02                	ld	s10,32(sp)
    80000994:	6de2                	ld	s11,24(sp)
    80000996:	6129                	add	sp,sp,192
    80000998:	8082                	ret
    release(&pr.lock);
    8000099a:	0000b517          	auipc	a0,0xb
    8000099e:	db650513          	add	a0,a0,-586 # 8000b750 <pr>
    800009a2:	00001097          	auipc	ra,0x1
    800009a6:	a68080e7          	jalr	-1432(ra) # 8000140a <release>
}
    800009aa:	bfc9                	j	8000097c <printf+0x1b0>

00000000800009ac <printfinit>:
    ;
}

void
printfinit(void)
{
    800009ac:	1101                	add	sp,sp,-32
    800009ae:	ec06                	sd	ra,24(sp)
    800009b0:	e822                	sd	s0,16(sp)
    800009b2:	e426                	sd	s1,8(sp)
    800009b4:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    800009b6:	0000b497          	auipc	s1,0xb
    800009ba:	d9a48493          	add	s1,s1,-614 # 8000b750 <pr>
    800009be:	00002597          	auipc	a1,0x2
    800009c2:	6c258593          	add	a1,a1,1730 # 80003080 <etext+0x80>
    800009c6:	8526                	mv	a0,s1
    800009c8:	00001097          	auipc	ra,0x1
    800009cc:	8fe080e7          	jalr	-1794(ra) # 800012c6 <initlock>
  pr.locking = 1;
    800009d0:	4785                	li	a5,1
    800009d2:	cc9c                	sw	a5,24(s1)
}
    800009d4:	60e2                	ld	ra,24(sp)
    800009d6:	6442                	ld	s0,16(sp)
    800009d8:	64a2                	ld	s1,8(sp)
    800009da:	6105                	add	sp,sp,32
    800009dc:	8082                	ret

00000000800009de <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(uint64 page, bool in_kernel)
{
    800009de:	1101                	add	sp,sp,-32
    800009e0:	ec06                	sd	ra,24(sp)
    800009e2:	e822                	sd	s0,16(sp)
    800009e4:	e426                	sd	s1,8(sp)
    800009e6:	e04a                	sd	s2,0(sp)
    800009e8:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)page % PGSIZE) != 0 || (char*)page < end || (uint64)page >= PHYSTOP) //检测合法性
    800009ea:	03451793          	sll	a5,a0,0x34
    800009ee:	ebb9                	bnez	a5,80000a44 <kfree+0x66>
    800009f0:	84aa                	mv	s1,a0
    800009f2:	0000b797          	auipc	a5,0xb
    800009f6:	25678793          	add	a5,a5,598 # 8000bc48 <end>
    800009fa:	04f56563          	bltu	a0,a5,80000a44 <kfree+0x66>
    800009fe:	47c5                	li	a5,17
    80000a00:	07ee                	sll	a5,a5,0x1b
    80000a02:	04f57163          	bgeu	a0,a5,80000a44 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset((char*)page, 1, PGSIZE); 
    80000a06:	6605                	lui	a2,0x1
    80000a08:	4585                	li	a1,1
    80000a0a:	00000097          	auipc	ra,0x0
    80000a0e:	b30080e7          	jalr	-1232(ra) # 8000053a <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    80000a12:	0000b917          	auipc	s2,0xb
    80000a16:	d5e90913          	add	s2,s2,-674 # 8000b770 <kmem>
    80000a1a:	854a                	mv	a0,s2
    80000a1c:	00001097          	auipc	ra,0x1
    80000a20:	93a080e7          	jalr	-1734(ra) # 80001356 <acquire>
  r->next = kmem.freelist;  //头插
    80000a24:	01893783          	ld	a5,24(s2)
    80000a28:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a2a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a2e:	854a                	mv	a0,s2
    80000a30:	00001097          	auipc	ra,0x1
    80000a34:	9da080e7          	jalr	-1574(ra) # 8000140a <release>
}
    80000a38:	60e2                	ld	ra,24(sp)
    80000a3a:	6442                	ld	s0,16(sp)
    80000a3c:	64a2                	ld	s1,8(sp)
    80000a3e:	6902                	ld	s2,0(sp)
    80000a40:	6105                	add	sp,sp,32
    80000a42:	8082                	ret
    panic("kfree");
    80000a44:	00002517          	auipc	a0,0x2
    80000a48:	65c50513          	add	a0,a0,1628 # 800030a0 <digits+0x18>
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	d36080e7          	jalr	-714(ra) # 80000782 <panic>

0000000080000a54 <freerange>:
{
    80000a54:	7179                	add	sp,sp,-48
    80000a56:	f406                	sd	ra,40(sp)
    80000a58:	f022                	sd	s0,32(sp)
    80000a5a:	ec26                	sd	s1,24(sp)
    80000a5c:	e84a                	sd	s2,16(sp)
    80000a5e:	e44e                	sd	s3,8(sp)
    80000a60:	e052                	sd	s4,0(sp)
    80000a62:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start); //可用内存初始地址对齐4KB
    80000a64:	6785                	lui	a5,0x1
    80000a66:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a6a:	00e504b3          	add	s1,a0,a4
    80000a6e:	777d                	lui	a4,0xfffff
    80000a70:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a72:	94be                	add	s1,s1,a5
    80000a74:	0095ef63          	bltu	a1,s1,80000a92 <freerange+0x3e>
    80000a78:	892e                	mv	s2,a1
    kfree((uint64)p,true);
    80000a7a:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a7c:	6985                	lui	s3,0x1
    kfree((uint64)p,true);
    80000a7e:	4585                	li	a1,1
    80000a80:	01448533          	add	a0,s1,s4
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	f5a080e7          	jalr	-166(ra) # 800009de <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a8c:	94ce                	add	s1,s1,s3
    80000a8e:	fe9978e3          	bgeu	s2,s1,80000a7e <freerange+0x2a>
}
    80000a92:	70a2                	ld	ra,40(sp)
    80000a94:	7402                	ld	s0,32(sp)
    80000a96:	64e2                	ld	s1,24(sp)
    80000a98:	6942                	ld	s2,16(sp)
    80000a9a:	69a2                	ld	s3,8(sp)
    80000a9c:	6a02                	ld	s4,0(sp)
    80000a9e:	6145                	add	sp,sp,48
    80000aa0:	8082                	ret

0000000080000aa2 <kinit>:
{
    80000aa2:	1141                	add	sp,sp,-16
    80000aa4:	e406                	sd	ra,8(sp)
    80000aa6:	e022                	sd	s0,0(sp)
    80000aa8:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aaa:	00002597          	auipc	a1,0x2
    80000aae:	5fe58593          	add	a1,a1,1534 # 800030a8 <digits+0x20>
    80000ab2:	0000b517          	auipc	a0,0xb
    80000ab6:	cbe50513          	add	a0,a0,-834 # 8000b770 <kmem>
    80000aba:	00001097          	auipc	ra,0x1
    80000abe:	80c080e7          	jalr	-2036(ra) # 800012c6 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac2:	45c5                	li	a1,17
    80000ac4:	05ee                	sll	a1,a1,0x1b
    80000ac6:	0000b517          	auipc	a0,0xb
    80000aca:	18250513          	add	a0,a0,386 # 8000bc48 <end>
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	f86080e7          	jalr	-122(ra) # 80000a54 <freerange>
}
    80000ad6:	60a2                	ld	ra,8(sp)
    80000ad8:	6402                	ld	s0,0(sp)
    80000ada:	0141                	add	sp,sp,16
    80000adc:	8082                	ret

0000000080000ade <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(bool in_kernel)
{
    80000ade:	1101                	add	sp,sp,-32
    80000ae0:	ec06                	sd	ra,24(sp)
    80000ae2:	e822                	sd	s0,16(sp)
    80000ae4:	e426                	sd	s1,8(sp)
    80000ae6:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);  
    80000ae8:	0000b497          	auipc	s1,0xb
    80000aec:	c8848493          	add	s1,s1,-888 # 8000b770 <kmem>
    80000af0:	8526                	mv	a0,s1
    80000af2:	00001097          	auipc	ra,0x1
    80000af6:	864080e7          	jalr	-1948(ra) # 80001356 <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80000afa:	6c84                	ld	s1,24(s1)
  if(r)
    80000afc:	c885                	beqz	s1,80000b2c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000afe:	609c                	ld	a5,0(s1)
    80000b00:	0000b517          	auipc	a0,0xb
    80000b04:	c7050513          	add	a0,a0,-912 # 8000b770 <kmem>
    80000b08:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0a:	00001097          	auipc	ra,0x1
    80000b0e:	900080e7          	jalr	-1792(ra) # 8000140a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b12:	6605                	lui	a2,0x1
    80000b14:	4595                	li	a1,5
    80000b16:	8526                	mv	a0,s1
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	a22080e7          	jalr	-1502(ra) # 8000053a <memset>
  return (void*)r;
}
    80000b20:	8526                	mv	a0,s1
    80000b22:	60e2                	ld	ra,24(sp)
    80000b24:	6442                	ld	s0,16(sp)
    80000b26:	64a2                	ld	s1,8(sp)
    80000b28:	6105                	add	sp,sp,32
    80000b2a:	8082                	ret
  release(&kmem.lock);
    80000b2c:	0000b517          	auipc	a0,0xb
    80000b30:	c4450513          	add	a0,a0,-956 # 8000b770 <kmem>
    80000b34:	00001097          	auipc	ra,0x1
    80000b38:	8d6080e7          	jalr	-1834(ra) # 8000140a <release>
  if(r)
    80000b3c:	b7d5                	j	80000b20 <kalloc+0x42>

0000000080000b3e <uvmcreate>:
}

// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
    80000b3e:	1101                	add	sp,sp,-32
    80000b40:	ec06                	sd	ra,24(sp)
    80000b42:	e822                	sd	s0,16(sp)
    80000b44:	e426                	sd	s1,8(sp)
    80000b46:	1000                	add	s0,sp,32
  pagetable_t pagetable = (pagetable_t)kalloc(true);
    80000b48:	4505                	li	a0,1
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	f94080e7          	jalr	-108(ra) # 80000ade <kalloc>
    80000b52:	84aa                	mv	s1,a0
  if(pagetable)
    80000b54:	c519                	beqz	a0,80000b62 <uvmcreate+0x24>
    memset(pagetable, 0, PGSIZE);
    80000b56:	6605                	lui	a2,0x1
    80000b58:	4581                	li	a1,0
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	9e0080e7          	jalr	-1568(ra) # 8000053a <memset>
  return pagetable;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	add	sp,sp,32
    80000b6c:	8082                	ret

0000000080000b6e <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000b6e:	1141                	add	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000b74:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000b78:	00003797          	auipc	a5,0x3
    80000b7c:	9687b783          	ld	a5,-1688(a5) # 800034e0 <kernel_pagetable>
    80000b80:	83b1                	srl	a5,a5,0xc
    80000b82:	577d                	li	a4,-1
    80000b84:	177e                	sll	a4,a4,0x3f
    80000b86:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000b88:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000b8c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	add	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <walk>:
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc) 
// 虚拟映射查询与建立
// 输入虚拟地址与对应的页表，返回该虚拟地址对应的最低级页表项地址
// alloc为0只查询，为1表示允许在遍历过程中为缺失的中间级页表分配一页。
{
    80000b96:	7139                	add	sp,sp,-64
    80000b98:	fc06                	sd	ra,56(sp)
    80000b9a:	f822                	sd	s0,48(sp)
    80000b9c:	f426                	sd	s1,40(sp)
    80000b9e:	f04a                	sd	s2,32(sp)
    80000ba0:	ec4e                	sd	s3,24(sp)
    80000ba2:	e852                	sd	s4,16(sp)
    80000ba4:	e456                	sd	s5,8(sp)
    80000ba6:	e05a                	sd	s6,0(sp)
    80000ba8:	0080                	add	s0,sp,64
    80000baa:	84aa                	mv	s1,a0
    80000bac:	89ae                	mv	s3,a1
    80000bae:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000bb0:	57fd                	li	a5,-1
    80000bb2:	83e9                	srl	a5,a5,0x1a
    80000bb4:	4a79                	li	s4,30
    panic("walk");
  for(int level = 2; level > 0; level--) {
    80000bb6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000bb8:	04b7f363          	bgeu	a5,a1,80000bfe <walk+0x68>
    panic("walk");
    80000bbc:	00002517          	auipc	a0,0x2
    80000bc0:	4f450513          	add	a0,a0,1268 # 800030b0 <digits+0x28>
    80000bc4:	00000097          	auipc	ra,0x0
    80000bc8:	bbe080e7          	jalr	-1090(ra) # 80000782 <panic>
    if(*pte & PTE_V) { // PTE有效
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
    } else {  // PTE无效，先判断是否可以写入
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
    80000bcc:	060a8763          	beqz	s5,80000c3a <walk+0xa4>
    80000bd0:	4505                	li	a0,1
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	f0c080e7          	jalr	-244(ra) # 80000ade <kalloc>
    80000bda:	84aa                	mv	s1,a0
    80000bdc:	c529                	beqz	a0,80000c26 <walk+0x90>
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
    80000bde:	6605                	lui	a2,0x1
    80000be0:	4581                	li	a1,0
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	958080e7          	jalr	-1704(ra) # 8000053a <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    80000bea:	00c4d793          	srl	a5,s1,0xc
    80000bee:	07aa                	sll	a5,a5,0xa
    80000bf0:	0017e793          	or	a5,a5,1
    80000bf4:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000bf8:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fff33af>
    80000bfa:	036a0063          	beq	s4,s6,80000c1a <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    80000bfe:	0149d933          	srl	s2,s3,s4
    80000c02:	1ff97913          	and	s2,s2,511
    80000c06:	090e                	sll	s2,s2,0x3
    80000c08:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) { // PTE有效
    80000c0a:	00093483          	ld	s1,0(s2)
    80000c0e:	0014f793          	and	a5,s1,1
    80000c12:	dfcd                	beqz	a5,80000bcc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte); 
    80000c14:	80a9                	srl	s1,s1,0xa
    80000c16:	04b2                	sll	s1,s1,0xc
    80000c18:	b7c5                	j	80000bf8 <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];  
    80000c1a:	00c9d513          	srl	a0,s3,0xc
    80000c1e:	1ff57513          	and	a0,a0,511
    80000c22:	050e                	sll	a0,a0,0x3
    80000c24:	9526                	add	a0,a0,s1
}
    80000c26:	70e2                	ld	ra,56(sp)
    80000c28:	7442                	ld	s0,48(sp)
    80000c2a:	74a2                	ld	s1,40(sp)
    80000c2c:	7902                	ld	s2,32(sp)
    80000c2e:	69e2                	ld	s3,24(sp)
    80000c30:	6a42                	ld	s4,16(sp)
    80000c32:	6aa2                	ld	s5,8(sp)
    80000c34:	6b02                	ld	s6,0(sp)
    80000c36:	6121                	add	sp,sp,64
    80000c38:	8082                	ret
        return 0; // 失败返回0
    80000c3a:	4501                	li	a0,0
    80000c3c:	b7ed                	j	80000c26 <walk+0x90>

0000000080000c3e <mappages>:
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
    80000c3e:	715d                	add	sp,sp,-80
    80000c40:	e486                	sd	ra,72(sp)
    80000c42:	e0a2                	sd	s0,64(sp)
    80000c44:	fc26                	sd	s1,56(sp)
    80000c46:	f84a                	sd	s2,48(sp)
    80000c48:	f44e                	sd	s3,40(sp)
    80000c4a:	f052                	sd	s4,32(sp)
    80000c4c:	ec56                	sd	s5,24(sp)
    80000c4e:	e85a                	sd	s6,16(sp)
    80000c50:	e45e                	sd	s7,8(sp)
    80000c52:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80000c54:	03459793          	sll	a5,a1,0x34
    80000c58:	e7b9                	bnez	a5,80000ca6 <mappages+0x68>
    80000c5a:	8aaa                	mv	s5,a0
    80000c5c:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80000c5e:	03461793          	sll	a5,a2,0x34
    80000c62:	ebb1                	bnez	a5,80000cb6 <mappages+0x78>
    panic("mappages: size not aligned");

  if(size == 0)
    80000c64:	c22d                	beqz	a2,80000cc6 <mappages+0x88>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
    80000c66:	77fd                	lui	a5,0xfffff
    80000c68:	963e                	add	a2,a2,a5
    80000c6a:	00b609b3          	add	s3,a2,a1
  a = va;
    80000c6e:	892e                	mv	s2,a1
    80000c70:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    if(a == last)
      break;
    a += PGSIZE;
    80000c74:	6b85                	lui	s7,0x1
    80000c76:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    80000c7a:	4605                	li	a2,1
    80000c7c:	85ca                	mv	a1,s2
    80000c7e:	8556                	mv	a0,s5
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	f16080e7          	jalr	-234(ra) # 80000b96 <walk>
    80000c88:	cd39                	beqz	a0,80000ce6 <mappages+0xa8>
    if(*pte & PTE_V) // 重复映射
    80000c8a:	611c                	ld	a5,0(a0)
    80000c8c:	8b85                	and	a5,a5,1
    80000c8e:	e7a1                	bnez	a5,80000cd6 <mappages+0x98>
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    80000c90:	80b1                	srl	s1,s1,0xc
    80000c92:	04aa                	sll	s1,s1,0xa
    80000c94:	0164e4b3          	or	s1,s1,s6
    80000c98:	0014e493          	or	s1,s1,1
    80000c9c:	e104                	sd	s1,0(a0)
    if(a == last)
    80000c9e:	07390063          	beq	s2,s3,80000cfe <mappages+0xc0>
    a += PGSIZE;
    80000ca2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    80000ca4:	bfc9                	j	80000c76 <mappages+0x38>
    panic("mappages: va not aligned");
    80000ca6:	00002517          	auipc	a0,0x2
    80000caa:	41250513          	add	a0,a0,1042 # 800030b8 <digits+0x30>
    80000cae:	00000097          	auipc	ra,0x0
    80000cb2:	ad4080e7          	jalr	-1324(ra) # 80000782 <panic>
    panic("mappages: size not aligned");
    80000cb6:	00002517          	auipc	a0,0x2
    80000cba:	42250513          	add	a0,a0,1058 # 800030d8 <digits+0x50>
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	ac4080e7          	jalr	-1340(ra) # 80000782 <panic>
    panic("mappages: size");
    80000cc6:	00002517          	auipc	a0,0x2
    80000cca:	43250513          	add	a0,a0,1074 # 800030f8 <digits+0x70>
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	ab4080e7          	jalr	-1356(ra) # 80000782 <panic>
      panic("mappages: remap");
    80000cd6:	00002517          	auipc	a0,0x2
    80000cda:	43250513          	add	a0,a0,1074 # 80003108 <digits+0x80>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	aa4080e7          	jalr	-1372(ra) # 80000782 <panic>
      return -1;
    80000ce6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80000ce8:	60a6                	ld	ra,72(sp)
    80000cea:	6406                	ld	s0,64(sp)
    80000cec:	74e2                	ld	s1,56(sp)
    80000cee:	7942                	ld	s2,48(sp)
    80000cf0:	79a2                	ld	s3,40(sp)
    80000cf2:	7a02                	ld	s4,32(sp)
    80000cf4:	6ae2                	ld	s5,24(sp)
    80000cf6:	6b42                	ld	s6,16(sp)
    80000cf8:	6ba2                	ld	s7,8(sp)
    80000cfa:	6161                	add	sp,sp,80
    80000cfc:	8082                	ret
  return 0;
    80000cfe:	4501                	li	a0,0
    80000d00:	b7e5                	j	80000ce8 <mappages+0xaa>

0000000080000d02 <kvmmap>:
{
    80000d02:	1141                	add	sp,sp,-16
    80000d04:	e406                	sd	ra,8(sp)
    80000d06:	e022                	sd	s0,0(sp)
    80000d08:	0800                	add	s0,sp,16
    80000d0a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80000d0c:	86b2                	mv	a3,a2
    80000d0e:	863e                	mv	a2,a5
    80000d10:	00000097          	auipc	ra,0x0
    80000d14:	f2e080e7          	jalr	-210(ra) # 80000c3e <mappages>
    80000d18:	e509                	bnez	a0,80000d22 <kvmmap+0x20>
}
    80000d1a:	60a2                	ld	ra,8(sp)
    80000d1c:	6402                	ld	s0,0(sp)
    80000d1e:	0141                	add	sp,sp,16
    80000d20:	8082                	ret
    panic("kvmmap");
    80000d22:	00002517          	auipc	a0,0x2
    80000d26:	3f650513          	add	a0,a0,1014 # 80003118 <digits+0x90>
    80000d2a:	00000097          	auipc	ra,0x0
    80000d2e:	a58080e7          	jalr	-1448(ra) # 80000782 <panic>

0000000080000d32 <kvmmake>:
{
    80000d32:	1101                	add	sp,sp,-32
    80000d34:	ec06                	sd	ra,24(sp)
    80000d36:	e822                	sd	s0,16(sp)
    80000d38:	e426                	sd	s1,8(sp)
    80000d3a:	e04a                	sd	s2,0(sp)
    80000d3c:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc(true);
    80000d3e:	4505                	li	a0,1
    80000d40:	00000097          	auipc	ra,0x0
    80000d44:	d9e080e7          	jalr	-610(ra) # 80000ade <kalloc>
    80000d48:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE); //关键清零
    80000d4a:	6605                	lui	a2,0x1
    80000d4c:	4581                	li	a1,0
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7ec080e7          	jalr	2028(ra) # 8000053a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80000d56:	4719                	li	a4,6
    80000d58:	6685                	lui	a3,0x1
    80000d5a:	10000637          	lui	a2,0x10000
    80000d5e:	100005b7          	lui	a1,0x10000
    80000d62:	8526                	mv	a0,s1
    80000d64:	00000097          	auipc	ra,0x0
    80000d68:	f9e080e7          	jalr	-98(ra) # 80000d02 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80000d6c:	4719                	li	a4,6
    80000d6e:	6685                	lui	a3,0x1
    80000d70:	10001637          	lui	a2,0x10001
    80000d74:	100015b7          	lui	a1,0x10001
    80000d78:	8526                	mv	a0,s1
    80000d7a:	00000097          	auipc	ra,0x0
    80000d7e:	f88080e7          	jalr	-120(ra) # 80000d02 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80000d82:	4719                	li	a4,6
    80000d84:	004006b7          	lui	a3,0x400
    80000d88:	0c000637          	lui	a2,0xc000
    80000d8c:	0c0005b7          	lui	a1,0xc000
    80000d90:	8526                	mv	a0,s1
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f70080e7          	jalr	-144(ra) # 80000d02 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    80000d9a:	00002917          	auipc	s2,0x2
    80000d9e:	26690913          	add	s2,s2,614 # 80003000 <etext>
    80000da2:	4729                	li	a4,10
    80000da4:	80002697          	auipc	a3,0x80002
    80000da8:	25c68693          	add	a3,a3,604 # 3000 <_entry-0x7fffd000>
    80000dac:	4605                	li	a2,1
    80000dae:	067e                	sll	a2,a2,0x1f
    80000db0:	85b2                	mv	a1,a2
    80000db2:	8526                	mv	a0,s1
    80000db4:	00000097          	auipc	ra,0x0
    80000db8:	f4e080e7          	jalr	-178(ra) # 80000d02 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    80000dbc:	4719                	li	a4,6
    80000dbe:	46c5                	li	a3,17
    80000dc0:	06ee                	sll	a3,a3,0x1b
    80000dc2:	412686b3          	sub	a3,a3,s2
    80000dc6:	864a                	mv	a2,s2
    80000dc8:	85ca                	mv	a1,s2
    80000dca:	8526                	mv	a0,s1
    80000dcc:	00000097          	auipc	ra,0x0
    80000dd0:	f36080e7          	jalr	-202(ra) # 80000d02 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80000dd4:	4729                	li	a4,10
    80000dd6:	6685                	lui	a3,0x1
    80000dd8:	00001617          	auipc	a2,0x1
    80000ddc:	22860613          	add	a2,a2,552 # 80002000 <_trampoline>
    80000de0:	040005b7          	lui	a1,0x4000
    80000de4:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80000de6:	05b2                	sll	a1,a1,0xc
    80000de8:	8526                	mv	a0,s1
    80000dea:	00000097          	auipc	ra,0x0
    80000dee:	f18080e7          	jalr	-232(ra) # 80000d02 <kvmmap>
}
    80000df2:	8526                	mv	a0,s1
    80000df4:	60e2                	ld	ra,24(sp)
    80000df6:	6442                	ld	s0,16(sp)
    80000df8:	64a2                	ld	s1,8(sp)
    80000dfa:	6902                	ld	s2,0(sp)
    80000dfc:	6105                	add	sp,sp,32
    80000dfe:	8082                	ret

0000000080000e00 <kvminit>:
{
    80000e00:	1141                	add	sp,sp,-16
    80000e02:	e406                	sd	ra,8(sp)
    80000e04:	e022                	sd	s0,0(sp)
    80000e06:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80000e08:	00000097          	auipc	ra,0x0
    80000e0c:	f2a080e7          	jalr	-214(ra) # 80000d32 <kvmmake>
    80000e10:	00002797          	auipc	a5,0x2
    80000e14:	6ca7b823          	sd	a0,1744(a5) # 800034e0 <kernel_pagetable>
}
    80000e18:	60a2                	ld	ra,8(sp)
    80000e1a:	6402                	ld	s0,0(sp)
    80000e1c:	0141                	add	sp,sp,16
    80000e1e:	8082                	ret

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
    80000e42:	00002c17          	auipc	s8,0x2
    80000e46:	2e6c0c13          	add	s8,s8,742 # 80003128 <digits+0xa0>

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
    80000e4a:	00002d17          	auipc	s10,0x2
    80000e4e:	2f6d0d13          	add	s10,s10,758 # 80003140 <digits+0xb8>
      for(int j = 0; j < level; j++)
    80000e52:	4c81                	li	s9,0
        printf("  ");
    80000e54:	00002b17          	auipc	s6,0x2
    80000e58:	2ccb0b13          	add	s6,s6,716 # 80003120 <digits+0x98>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000e5c:	20000b93          	li	s7,512
    80000e60:	a025                	j	80000e88 <print_pgtbl+0x68>
      } 
      else {
        printf("\n");
    80000e62:	00002517          	auipc	a0,0x2
    80000e66:	1be50513          	add	a0,a0,446 # 80003020 <etext+0x20>
    80000e6a:	00000097          	auipc	ra,0x0
    80000e6e:	962080e7          	jalr	-1694(ra) # 800007cc <printf>
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
    80000e9e:	932080e7          	jalr	-1742(ra) # 800007cc <printf>
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
    80000eba:	916080e7          	jalr	-1770(ra) # 800007cc <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000ebe:	00e97913          	and	s2,s2,14
    80000ec2:	fa0900e3          	beqz	s2,80000e62 <print_pgtbl+0x42>
        printf(" [leaf]\n");
    80000ec6:	856a                	mv	a0,s10
    80000ec8:	00000097          	auipc	ra,0x0
    80000ecc:	904080e7          	jalr	-1788(ra) # 800007cc <printf>
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
    80000f08:	00002517          	auipc	a0,0x2
    80000f0c:	24850513          	add	a0,a0,584 # 80003150 <digits+0xc8>
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	8bc080e7          	jalr	-1860(ra) # 800007cc <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f18:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000f1a:	00002a97          	auipc	s5,0x2
    80000f1e:	246a8a93          	add	s5,s5,582 # 80003160 <digits+0xd8>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
    80000f22:	00002b97          	auipc	s7,0x2
    80000f26:	0feb8b93          	add	s7,s7,254 # 80003020 <etext+0x20>
        printf(" [leaf]\n");
    80000f2a:	00002b17          	auipc	s6,0x2
    80000f2e:	216b0b13          	add	s6,s6,534 # 80003140 <digits+0xb8>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f32:	20000a13          	li	s4,512
    80000f36:	a811                	j	80000f4a <print_cur_pgtbl+0x5c>
        printf("\n");
    80000f38:	855e                	mv	a0,s7
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	892080e7          	jalr	-1902(ra) # 800007cc <printf>
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
    80000f64:	86c080e7          	jalr	-1940(ra) # 800007cc <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000f68:	88b9                	and	s1,s1,14
    80000f6a:	d4f9                	beqz	s1,80000f38 <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80000f6c:	855a                	mv	a0,s6
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	85e080e7          	jalr	-1954(ra) # 800007cc <printf>
    80000f76:	b7f1                	j	80000f42 <print_cur_pgtbl+0x54>
      }
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

0000000080000f8e <uvmfirst>:

void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80000f8e:	7179                	add	sp,sp,-48
    80000f90:	f406                	sd	ra,40(sp)
    80000f92:	f022                	sd	s0,32(sp)
    80000f94:	ec26                	sd	s1,24(sp)
    80000f96:	e84a                	sd	s2,16(sp)
    80000f98:	e44e                	sd	s3,8(sp)
    80000f9a:	e052                	sd	s4,0(sp)
    80000f9c:	1800                	add	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80000f9e:	6785                	lui	a5,0x1
    80000fa0:	04f67963          	bgeu	a2,a5,80000ff2 <uvmfirst+0x64>
    80000fa4:	8a2a                	mv	s4,a0
    80000fa6:	89ae                	mv	s3,a1
    80000fa8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc(1);
    80000faa:	4505                	li	a0,1
    80000fac:	00000097          	auipc	ra,0x0
    80000fb0:	b32080e7          	jalr	-1230(ra) # 80000ade <kalloc>
    80000fb4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80000fb6:	6605                	lui	a2,0x1
    80000fb8:	4581                	li	a1,0
    80000fba:	fffff097          	auipc	ra,0xfffff
    80000fbe:	580080e7          	jalr	1408(ra) # 8000053a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80000fc2:	4779                	li	a4,30
    80000fc4:	86ca                	mv	a3,s2
    80000fc6:	6605                	lui	a2,0x1
    80000fc8:	4581                	li	a1,0
    80000fca:	8552                	mv	a0,s4
    80000fcc:	00000097          	auipc	ra,0x0
    80000fd0:	c72080e7          	jalr	-910(ra) # 80000c3e <mappages>
  memmove(mem, src, sz);
    80000fd4:	8626                	mv	a2,s1
    80000fd6:	85ce                	mv	a1,s3
    80000fd8:	854a                	mv	a0,s2
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	5bc080e7          	jalr	1468(ra) # 80000596 <memmove>
    80000fe2:	70a2                	ld	ra,40(sp)
    80000fe4:	7402                	ld	s0,32(sp)
    80000fe6:	64e2                	ld	s1,24(sp)
    80000fe8:	6942                	ld	s2,16(sp)
    80000fea:	69a2                	ld	s3,8(sp)
    80000fec:	6a02                	ld	s4,0(sp)
    80000fee:	6145                	add	sp,sp,48
    80000ff0:	8082                	ret
    panic("uvmfirst: more than a page");
    80000ff2:	00002517          	auipc	a0,0x2
    80000ff6:	18e50513          	add	a0,a0,398 # 80003180 <digits+0xf8>
    80000ffa:	fffff097          	auipc	ra,0xfffff
    80000ffe:	788080e7          	jalr	1928(ra) # 80000782 <panic>

0000000080001002 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001002:	1141                	add	sp,sp,-16
    80001004:	e422                	sd	s0,8(sp)
    80001006:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001008:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000100a:	2501                	sext.w	a0,a0
    8000100c:	6422                	ld	s0,8(sp)
    8000100e:	0141                	add	sp,sp,16
    80001010:	8082                	ret

0000000080001012 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001012:	1141                	add	sp,sp,-16
    80001014:	e422                	sd	s0,8(sp)
    80001016:	0800                	add	s0,sp,16
    80001018:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000101a:	2781                	sext.w	a5,a5
    8000101c:	079e                	sll	a5,a5,0x7
  return c;
}
    8000101e:	0000a517          	auipc	a0,0xa
    80001022:	77250513          	add	a0,a0,1906 # 8000b790 <cpus>
    80001026:	953e                	add	a0,a0,a5
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	add	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <myproc>:


proc_t* myproc(void)
{
    8000102e:	1101                	add	sp,sp,-32
    80001030:	ec06                	sd	ra,24(sp)
    80001032:	e822                	sd	s0,16(sp)
    80001034:	e426                	sd	s1,8(sp)
    80001036:	1000                	add	s0,sp,32
  push_off();
    80001038:	00000097          	auipc	ra,0x0
    8000103c:	2d2080e7          	jalr	722(ra) # 8000130a <push_off>
    80001040:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001042:	2781                	sext.w	a5,a5
    80001044:	079e                	sll	a5,a5,0x7
    80001046:	0000a717          	auipc	a4,0xa
    8000104a:	74a70713          	add	a4,a4,1866 # 8000b790 <cpus>
    8000104e:	97ba                	add	a5,a5,a4
    80001050:	6784                	ld	s1,8(a5)
  pop_off();
    80001052:	00000097          	auipc	ra,0x0
    80001056:	358080e7          	jalr	856(ra) # 800013aa <pop_off>
  return p;
}
    8000105a:	8526                	mv	a0,s1
    8000105c:	60e2                	ld	ra,24(sp)
    8000105e:	6442                	ld	s0,16(sp)
    80001060:	64a2                	ld	s1,8(sp)
    80001062:	6105                	add	sp,sp,32
    80001064:	8082                	ret

0000000080001066 <allocpid>:

int
allocpid()
{
    80001066:	1101                	add	sp,sp,-32
    80001068:	ec06                	sd	ra,24(sp)
    8000106a:	e822                	sd	s0,16(sp)
    8000106c:	e426                	sd	s1,8(sp)
    8000106e:	e04a                	sd	s2,0(sp)
    80001070:	1000                	add	s0,sp,32
  int pid;
  
  acquire(&pid_lock);
    80001072:	0000b917          	auipc	s2,0xb
    80001076:	b1e90913          	add	s2,s2,-1250 # 8000bb90 <pid_lock>
    8000107a:	854a                	mv	a0,s2
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	2da080e7          	jalr	730(ra) # 80001356 <acquire>
  pid = nextpid;
    80001084:	00002797          	auipc	a5,0x2
    80001088:	40c78793          	add	a5,a5,1036 # 80003490 <nextpid>
    8000108c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    8000108e:	0014871b          	addw	a4,s1,1
    80001092:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001094:	854a                	mv	a0,s2
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	374080e7          	jalr	884(ra) # 8000140a <release>

  return pid;
    8000109e:	8526                	mv	a0,s1
    800010a0:	60e2                	ld	ra,24(sp)
    800010a2:	6442                	ld	s0,16(sp)
    800010a4:	64a2                	ld	s1,8(sp)
    800010a6:	6902                	ld	s2,0(sp)
    800010a8:	6105                	add	sp,sp,32
    800010aa:	8082                	ret

00000000800010ac <proc_pgtbl_init>:
// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
// 注意：参数 trapframe_pa 应该是 trapframe 的物理地址（PA），
// 调用处需传入 V2P(p->tf)（或你项目中的等价宏）。
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
    800010ac:	1101                	add	sp,sp,-32
    800010ae:	ec06                	sd	ra,24(sp)
    800010b0:	e822                	sd	s0,16(sp)
    800010b2:	e426                	sd	s1,8(sp)
    800010b4:	e04a                	sd	s2,0(sp)
    800010b6:	1000                	add	s0,sp,32
    800010b8:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    800010ba:	00000097          	auipc	ra,0x0
    800010be:	a84080e7          	jalr	-1404(ra) # 80000b3e <uvmcreate>
    800010c2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800010c4:	cd1d                	beqz	a0,80001102 <proc_pgtbl_init+0x56>
    return 0;

  // trampoline 映射必须用物理地址 (trampoline 是 kernel 符号，需 V2P)
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800010c6:	4729                	li	a4,10
    800010c8:	00001697          	auipc	a3,0x1
    800010cc:	f3868693          	add	a3,a3,-200 # 80002000 <_trampoline>
    800010d0:	6605                	lui	a2,0x1
    800010d2:	040005b7          	lui	a1,0x4000
    800010d6:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800010d8:	05b2                	sll	a1,a1,0xc
    800010da:	00000097          	auipc	ra,0x0
    800010de:	b64080e7          	jalr	-1180(ra) # 80000c3e <mappages>
    800010e2:	02054763          	bltz	a0,80001110 <proc_pgtbl_init+0x64>
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  // trapframe 映射必须用物理地址
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800010e6:	4719                	li	a4,6
    800010e8:	86ca                	mv	a3,s2
    800010ea:	6605                	lui	a2,0x1
    800010ec:	020005b7          	lui	a1,0x2000
    800010f0:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800010f2:	05b6                	sll	a1,a1,0xd
    800010f4:	8526                	mv	a0,s1
    800010f6:	00000097          	auipc	ra,0x0
    800010fa:	b48080e7          	jalr	-1208(ra) # 80000c3e <mappages>
    800010fe:	02054163          	bltz	a0,80001120 <proc_pgtbl_init+0x74>
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}
    80001102:	8526                	mv	a0,s1
    80001104:	60e2                	ld	ra,24(sp)
    80001106:	6442                	ld	s0,16(sp)
    80001108:	64a2                	ld	s1,8(sp)
    8000110a:	6902                	ld	s2,0(sp)
    8000110c:	6105                	add	sp,sp,32
    8000110e:	8082                	ret
    panic("proc_pgtbl_init: mappages trampoline failed");
    80001110:	00002517          	auipc	a0,0x2
    80001114:	09050513          	add	a0,a0,144 # 800031a0 <digits+0x118>
    80001118:	fffff097          	auipc	ra,0xfffff
    8000111c:	66a080e7          	jalr	1642(ra) # 80000782 <panic>
    panic("proc_pgtbl_init: mappages trapframe failed");
    80001120:	00002517          	auipc	a0,0x2
    80001124:	0b050513          	add	a0,a0,176 # 800031d0 <digits+0x148>
    80001128:	fffff097          	auipc	ra,0xfffff
    8000112c:	65a080e7          	jalr	1626(ra) # 80000782 <panic>

0000000080001130 <proc_make_fisrt>:
    page 2: ustack
    ... heap between code+data and ustack (heap_top = 2*PGSIZE)
    TRAPFRAME / TRAMPOLINE 映射在高地址 (TRAPFRAME/TRAMPOLINE 常量)
*/
void proc_make_fisrt()
{
    80001130:	1101                	add	sp,sp,-32
    80001132:	ec06                	sd	ra,24(sp)
    80001134:	e822                	sd	s0,16(sp)
    80001136:	e426                	sd	s1,8(sp)
    80001138:	e04a                	sd	s2,0(sp)
    8000113a:	1000                	add	s0,sp,32
    struct proc *p = &proczero;
    memset(p, 0, sizeof(*p));
    8000113c:	0000b497          	auipc	s1,0xb
    80001140:	a6c48493          	add	s1,s1,-1428 # 8000bba8 <proczero>
    80001144:	0a000613          	li	a2,160
    80001148:	4581                	li	a1,0
    8000114a:	8526                	mv	a0,s1
    8000114c:	fffff097          	auipc	ra,0xfffff
    80001150:	3ee080e7          	jalr	1006(ra) # 8000053a <memset>

    p->pid = allocpid();
    80001154:	00000097          	auipc	ra,0x0
    80001158:	f12080e7          	jalr	-238(ra) # 80001066 <allocpid>
    8000115c:	c088                	sw	a0,0(s1)

    // Allocate a trapframe page. （注意：确认你的 kalloc 接口是 kalloc(1) 还是 kalloc()）
    if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    8000115e:	4505                	li	a0,1
    80001160:	00000097          	auipc	ra,0x0
    80001164:	97e080e7          	jalr	-1666(ra) # 80000ade <kalloc>
    80001168:	f088                	sd	a0,32(s1)
    8000116a:	10050663          	beqz	a0,80001276 <proc_make_fisrt+0x146>
        panic("proc_make_first: kalloc trapframe failed");
        return ;
    }
    // 清零整页（trapframe 占一页）
    memset(p->tf, 0, PGSIZE);
    8000116e:	6605                	lui	a2,0x1
    80001170:	4581                	li	a1,0
    80001172:	fffff097          	auipc	ra,0xfffff
    80001176:	3c8080e7          	jalr	968(ra) # 8000053a <memset>

    // prepare for the very first "return" from kernel to user.
    p->tf->epc = 0;      // user program counter
    8000117a:	0000b497          	auipc	s1,0xb
    8000117e:	a2e48493          	add	s1,s1,-1490 # 8000bba8 <proczero>
    80001182:	709c                	ld	a5,32(s1)
    80001184:	0007bc23          	sd	zero,24(a5)

    // pagetable 初始化：传入 trapframe 的物理地址
    p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    80001188:	7088                	ld	a0,32(s1)
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	f22080e7          	jalr	-222(ra) # 800010ac <proc_pgtbl_init>
    80001192:	e488                	sd	a0,8(s1)
    if (p->pgtbl == 0) {
    80001194:	c96d                	beqz	a0,80001286 <proc_make_fisrt+0x156>
        panic("proc_make_first: proc_pgtbl_init failed");
    }

    // ---- 用户栈映射 ----
    uint64 ustack_va = 2 * PGSIZE;          // virtual address of stack page base
    char *ustack_pa = kalloc(1);
    80001196:	4505                	li	a0,1
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	946080e7          	jalr	-1722(ra) # 80000ade <kalloc>
    800011a0:	84aa                	mv	s1,a0
    if (ustack_pa == 0) {
    800011a2:	c975                	beqz	a0,80001296 <proc_make_fisrt+0x166>
        panic("proc_make_first: kalloc ustack failed");
    }
    // zero the newly allocated physical page
    memset(ustack_pa, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	392080e7          	jalr	914(ra) # 8000053a <memset>

    // 注意：mappages 期望的 pa 是物理地址，因此传 V2P(ustack_pa)
    if (mappages(p->pgtbl, ustack_va, PGSIZE, (uint64)(ustack_pa), PTE_R | PTE_W | PTE_U) < 0) {
    800011b0:	4759                	li	a4,22
    800011b2:	86a6                	mv	a3,s1
    800011b4:	6605                	lui	a2,0x1
    800011b6:	6589                	lui	a1,0x2
    800011b8:	0000b517          	auipc	a0,0xb
    800011bc:	9f853503          	ld	a0,-1544(a0) # 8000bbb0 <proczero+0x8>
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	a7e080e7          	jalr	-1410(ra) # 80000c3e <mappages>
    800011c8:	0c054f63          	bltz	a0,800012a6 <proc_make_fisrt+0x176>
        panic("proc_make_first: mappages ustack failed");
    }
    p->ustack_pages = 1;
    800011cc:	0000b717          	auipc	a4,0xb
    800011d0:	9dc70713          	add	a4,a4,-1572 # 8000bba8 <proczero>
    800011d4:	4785                	li	a5,1
    800011d6:	ef1c                	sd	a5,24(a4)

    // kernel stack
    p->kstack = KSTACK(0);
    800011d8:	040007b7          	lui	a5,0x4000
    800011dc:	17f5                	add	a5,a5,-3 # 3fffffd <_entry-0x7c000003>
    800011de:	07b2                	sll	a5,a5,0xc
    800011e0:	f71c                	sd	a5,40(a4)

    // user stack pointer：栈顶在 ustack_va + PGSIZE
    p->tf->sp = ustack_va + PGSIZE; // = 3 * PGSIZE
    800011e2:	731c                	ld	a5,32(a4)
    800011e4:	668d                	lui	a3,0x3
    800011e6:	fb94                	sd	a3,48(a5)

    // data + code 映射：用 initcode_len 作为长度（比 sizeof(initcode) 更保险）
    uvmfirst(p->pgtbl, initcode, initcode_len);
    800011e8:	00002497          	auipc	s1,0x2
    800011ec:	2ac48493          	add	s1,s1,684 # 80003494 <initcode_len>
    800011f0:	4090                	lw	a2,0(s1)
    800011f2:	00002597          	auipc	a1,0x2
    800011f6:	2ae58593          	add	a1,a1,686 # 800034a0 <initcode>
    800011fa:	6708                	ld	a0,8(a4)
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	d92080e7          	jalr	-622(ra) # 80000f8e <uvmfirst>

    if(initcode_len > PGSIZE){
    80001204:	4098                	lw	a4,0(s1)
    80001206:	6785                	lui	a5,0x1
    80001208:	0ae7e763          	bltu	a5,a4,800012b6 <proc_make_fisrt+0x186>
        panic("proc_make_first: initcode too big\n");
    }

    // 设置 heap_top / p->sz，供 sbrk/growproc 使用
    p->heap_top = 2 * PGSIZE;
    8000120c:	0000b497          	auipc	s1,0xb
    80001210:	99c48493          	add	s1,s1,-1636 # 8000bba8 <proczero>
    80001214:	6789                	lui	a5,0x2
    80001216:	e89c                	sd	a5,16(s1)

    // 初始化上下文
    memset(&p->ctx, 0, sizeof(p->ctx));
    80001218:	0000b917          	auipc	s2,0xb
    8000121c:	9c090913          	add	s2,s2,-1600 # 8000bbd8 <proczero+0x30>
    80001220:	07000613          	li	a2,112
    80001224:	4581                	li	a1,0
    80001226:	854a                	mv	a0,s2
    80001228:	fffff097          	auipc	ra,0xfffff
    8000122c:	312080e7          	jalr	786(ra) # 8000053a <memset>
    printf("[proc_make_first] first process created: pid=%d\n", p->pid);
    80001230:	408c                	lw	a1,0(s1)
    80001232:	00002517          	auipc	a0,0x2
    80001236:	09e50513          	add	a0,a0,158 # 800032d0 <digits+0x248>
    8000123a:	fffff097          	auipc	ra,0xfffff
    8000123e:	592080e7          	jalr	1426(ra) # 800007cc <printf>

    // 上下文返回点设置为 trap_user_return
    p->ctx.ra = (uint64)trap_user_return;
    80001242:	00000797          	auipc	a5,0x0
    80001246:	3ca78793          	add	a5,a5,970 # 8000160c <trap_user_return>
    8000124a:	f89c                	sd	a5,48(s1)
    p->ctx.sp = p->kstack + PGSIZE;
    8000124c:	749c                	ld	a5,40(s1)
    8000124e:	6705                	lui	a4,0x1
    80001250:	97ba                	add	a5,a5,a4
    80001252:	fc9c                	sd	a5,56(s1)


    // 把该进程关联到当前 CPU 并切换上下文
    struct cpu* c = mycpu();
    80001254:	00000097          	auipc	ra,0x0
    80001258:	dbe080e7          	jalr	-578(ra) # 80001012 <mycpu>
    c->proc = p;
    8000125c:	e504                	sd	s1,8(a0)
    swtch(&c->context, &p->ctx);
    8000125e:	85ca                	mv	a1,s2
    80001260:	0541                	add	a0,a0,16
    80001262:	00000097          	auipc	ra,0x0
    80001266:	526080e7          	jalr	1318(ra) # 80001788 <swtch>

    // 当该进程回到内核（exit/yield）时，调度器/其他代码应清理 c->proc
}
    8000126a:	60e2                	ld	ra,24(sp)
    8000126c:	6442                	ld	s0,16(sp)
    8000126e:	64a2                	ld	s1,8(sp)
    80001270:	6902                	ld	s2,0(sp)
    80001272:	6105                	add	sp,sp,32
    80001274:	8082                	ret
        panic("proc_make_first: kalloc trapframe failed");
    80001276:	00002517          	auipc	a0,0x2
    8000127a:	f8a50513          	add	a0,a0,-118 # 80003200 <digits+0x178>
    8000127e:	fffff097          	auipc	ra,0xfffff
    80001282:	504080e7          	jalr	1284(ra) # 80000782 <panic>
        panic("proc_make_first: proc_pgtbl_init failed");
    80001286:	00002517          	auipc	a0,0x2
    8000128a:	faa50513          	add	a0,a0,-86 # 80003230 <digits+0x1a8>
    8000128e:	fffff097          	auipc	ra,0xfffff
    80001292:	4f4080e7          	jalr	1268(ra) # 80000782 <panic>
        panic("proc_make_first: kalloc ustack failed");
    80001296:	00002517          	auipc	a0,0x2
    8000129a:	fc250513          	add	a0,a0,-62 # 80003258 <digits+0x1d0>
    8000129e:	fffff097          	auipc	ra,0xfffff
    800012a2:	4e4080e7          	jalr	1252(ra) # 80000782 <panic>
        panic("proc_make_first: mappages ustack failed");
    800012a6:	00002517          	auipc	a0,0x2
    800012aa:	fda50513          	add	a0,a0,-38 # 80003280 <digits+0x1f8>
    800012ae:	fffff097          	auipc	ra,0xfffff
    800012b2:	4d4080e7          	jalr	1236(ra) # 80000782 <panic>
        panic("proc_make_first: initcode too big\n");
    800012b6:	00002517          	auipc	a0,0x2
    800012ba:	ff250513          	add	a0,a0,-14 # 800032a8 <digits+0x220>
    800012be:	fffff097          	auipc	ra,0xfffff
    800012c2:	4c4080e7          	jalr	1220(ra) # 80000782 <panic>

00000000800012c6 <initlock>:
#include "proc-h/cpu.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    800012c6:	1141                	add	sp,sp,-16
    800012c8:	e422                	sd	s0,8(sp)
    800012ca:	0800                	add	s0,sp,16
  lk->name = name;
    800012cc:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800012ce:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    800012d2:	00053823          	sd	zero,16(a0)
}
    800012d6:	6422                	ld	s0,8(sp)
    800012d8:	0141                	add	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    800012dc:	411c                	lw	a5,0(a0)
    800012de:	e399                	bnez	a5,800012e4 <holding+0x8>
    800012e0:	4501                	li	a0,0
  return r;
}
    800012e2:	8082                	ret
{
    800012e4:	1101                	add	sp,sp,-32
    800012e6:	ec06                	sd	ra,24(sp)
    800012e8:	e822                	sd	s0,16(sp)
    800012ea:	e426                	sd	s1,8(sp)
    800012ec:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    800012ee:	6904                	ld	s1,16(a0)
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	d22080e7          	jalr	-734(ra) # 80001012 <mycpu>
    800012f8:	40a48533          	sub	a0,s1,a0
    800012fc:	00153513          	seqz	a0,a0
}
    80001300:	60e2                	ld	ra,24(sp)
    80001302:	6442                	ld	s0,16(sp)
    80001304:	64a2                	ld	s1,8(sp)
    80001306:	6105                	add	sp,sp,32
    80001308:	8082                	ret

000000008000130a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    8000130a:	1101                	add	sp,sp,-32
    8000130c:	ec06                	sd	ra,24(sp)
    8000130e:	e822                	sd	s0,16(sp)
    80001310:	e426                	sd	s1,8(sp)
    80001312:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001314:	100024f3          	csrr	s1,sstatus
    80001318:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000131c:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000131e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cf0080e7          	jalr	-784(ra) # 80001012 <mycpu>
    8000132a:	411c                	lw	a5,0(a0)
    8000132c:	cf89                	beqz	a5,80001346 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    8000132e:	00000097          	auipc	ra,0x0
    80001332:	ce4080e7          	jalr	-796(ra) # 80001012 <mycpu>
    80001336:	411c                	lw	a5,0(a0)
    80001338:	2785                	addw	a5,a5,1
    8000133a:	c11c                	sw	a5,0(a0)
}
    8000133c:	60e2                	ld	ra,24(sp)
    8000133e:	6442                	ld	s0,16(sp)
    80001340:	64a2                	ld	s1,8(sp)
    80001342:	6105                	add	sp,sp,32
    80001344:	8082                	ret
    mycpu()->intena = old;
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	ccc080e7          	jalr	-820(ra) # 80001012 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    8000134e:	8085                	srl	s1,s1,0x1
    80001350:	8885                	and	s1,s1,1
    80001352:	c144                	sw	s1,4(a0)
    80001354:	bfe9                	j	8000132e <push_off+0x24>

0000000080001356 <acquire>:
{
    80001356:	1101                	add	sp,sp,-32
    80001358:	ec06                	sd	ra,24(sp)
    8000135a:	e822                	sd	s0,16(sp)
    8000135c:	e426                	sd	s1,8(sp)
    8000135e:	1000                	add	s0,sp,32
    80001360:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80001362:	00000097          	auipc	ra,0x0
    80001366:	fa8080e7          	jalr	-88(ra) # 8000130a <push_off>
  if(holding(lk))
    8000136a:	8526                	mv	a0,s1
    8000136c:	00000097          	auipc	ra,0x0
    80001370:	f70080e7          	jalr	-144(ra) # 800012dc <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80001374:	4705                	li	a4,1
  if(holding(lk))
    80001376:	e115                	bnez	a0,8000139a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80001378:	87ba                	mv	a5,a4
    8000137a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    8000137e:	2781                	sext.w	a5,a5
    80001380:	ffe5                	bnez	a5,80001378 <acquire+0x22>
  __sync_synchronize();
    80001382:	0ff0000f          	fence
  lk->cpu = mycpu();
    80001386:	00000097          	auipc	ra,0x0
    8000138a:	c8c080e7          	jalr	-884(ra) # 80001012 <mycpu>
    8000138e:	e888                	sd	a0,16(s1)
}
    80001390:	60e2                	ld	ra,24(sp)
    80001392:	6442                	ld	s0,16(sp)
    80001394:	64a2                	ld	s1,8(sp)
    80001396:	6105                	add	sp,sp,32
    80001398:	8082                	ret
    panic("acquire");
    8000139a:	00002517          	auipc	a0,0x2
    8000139e:	f6e50513          	add	a0,a0,-146 # 80003308 <digits+0x280>
    800013a2:	fffff097          	auipc	ra,0xfffff
    800013a6:	3e0080e7          	jalr	992(ra) # 80000782 <panic>

00000000800013aa <pop_off>:

void
pop_off(void)
{
    800013aa:	1141                	add	sp,sp,-16
    800013ac:	e406                	sd	ra,8(sp)
    800013ae:	e022                	sd	s0,0(sp)
    800013b0:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	c60080e7          	jalr	-928(ra) # 80001012 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800013ba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800013be:	8b89                	and	a5,a5,2
  if(intr_get())
    800013c0:	e78d                	bnez	a5,800013ea <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    800013c2:	411c                	lw	a5,0(a0)
    800013c4:	02f05b63          	blez	a5,800013fa <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    800013c8:	37fd                	addw	a5,a5,-1
    800013ca:	0007871b          	sext.w	a4,a5
    800013ce:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    800013d0:	eb09                	bnez	a4,800013e2 <pop_off+0x38>
    800013d2:	415c                	lw	a5,4(a0)
    800013d4:	c799                	beqz	a5,800013e2 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800013d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800013da:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800013de:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800013e2:	60a2                	ld	ra,8(sp)
    800013e4:	6402                	ld	s0,0(sp)
    800013e6:	0141                	add	sp,sp,16
    800013e8:	8082                	ret
    panic("pop_off - interruptible");
    800013ea:	00002517          	auipc	a0,0x2
    800013ee:	f2650513          	add	a0,a0,-218 # 80003310 <digits+0x288>
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	390080e7          	jalr	912(ra) # 80000782 <panic>
    panic("pop_off");
    800013fa:	00002517          	auipc	a0,0x2
    800013fe:	f2e50513          	add	a0,a0,-210 # 80003328 <digits+0x2a0>
    80001402:	fffff097          	auipc	ra,0xfffff
    80001406:	380080e7          	jalr	896(ra) # 80000782 <panic>

000000008000140a <release>:
{
    8000140a:	1101                	add	sp,sp,-32
    8000140c:	ec06                	sd	ra,24(sp)
    8000140e:	e822                	sd	s0,16(sp)
    80001410:	e426                	sd	s1,8(sp)
    80001412:	1000                	add	s0,sp,32
    80001414:	84aa                	mv	s1,a0
  if(!holding(lk))
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	ec6080e7          	jalr	-314(ra) # 800012dc <holding>
    8000141e:	c115                	beqz	a0,80001442 <release+0x38>
  lk->cpu = 0;
    80001420:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80001424:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80001428:	0f50000f          	fence	iorw,ow
    8000142c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80001430:	00000097          	auipc	ra,0x0
    80001434:	f7a080e7          	jalr	-134(ra) # 800013aa <pop_off>
}
    80001438:	60e2                	ld	ra,24(sp)
    8000143a:	6442                	ld	s0,16(sp)
    8000143c:	64a2                	ld	s1,8(sp)
    8000143e:	6105                	add	sp,sp,32
    80001440:	8082                	ret
    panic("release");
    80001442:	00002517          	auipc	a0,0x2
    80001446:	eee50513          	add	a0,a0,-274 # 80003330 <digits+0x2a8>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	338080e7          	jalr	824(ra) # 80000782 <panic>

0000000080001452 <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    80001452:	1141                	add	sp,sp,-16
    80001454:	e422                	sd	s0,8(sp)
    80001456:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001458:	00000797          	auipc	a5,0x0
    8000145c:	3a878793          	add	a5,a5,936 # 80001800 <kernelvec>
    80001460:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    80001464:	6422                	ld	s0,8(sp)
    80001466:	0141                	add	sp,sp,16
    80001468:	8082                	ret

000000008000146a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000146a:	142027f3          	csrr	a5,scause
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    8000146e:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80001470:	0807d763          	bgez	a5,800014fe <devintr+0x94>
{
    80001474:	1101                	add	sp,sp,-32
    80001476:	ec06                	sd	ra,24(sp)
    80001478:	e822                	sd	s0,16(sp)
    8000147a:	e426                	sd	s1,8(sp)
    8000147c:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    8000147e:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80001482:	46a5                	li	a3,9
    80001484:	00d70d63          	beq	a4,a3,8000149e <devintr+0x34>
  if(scause == 0x8000000000000001L){
    80001488:	577d                	li	a4,-1
    8000148a:	177e                	sll	a4,a4,0x3f
    8000148c:	0705                	add	a4,a4,1 # 1001 <_entry-0x7fffefff>
    return 0;  // 未识别的中断类型
    8000148e:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    80001490:	04e78663          	beq	a5,a4,800014dc <devintr+0x72>
  }
}
    80001494:	60e2                	ld	ra,24(sp)
    80001496:	6442                	ld	s0,16(sp)
    80001498:	64a2                	ld	s1,8(sp)
    8000149a:	6105                	add	sp,sp,32
    8000149c:	8082                	ret
    int irq = plic_claim();  // 获取中断请求号
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	04e080e7          	jalr	78(ra) # 800004ec <plic_claim>
    800014a6:	84aa                	mv	s1,a0
    switch(irq){
    800014a8:	47a9                	li	a5,10
    800014aa:	02f50463          	beq	a0,a5,800014d2 <devintr+0x68>
    return 1;
    800014ae:	4505                	li	a0,1
      if(irq){
    800014b0:	d0f5                	beqz	s1,80001494 <devintr+0x2a>
        printf("unexpected interrupt irq=%d\n", irq);
    800014b2:	85a6                	mv	a1,s1
    800014b4:	00002517          	auipc	a0,0x2
    800014b8:	e8450513          	add	a0,a0,-380 # 80003338 <digits+0x2b0>
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	310080e7          	jalr	784(ra) # 800007cc <printf>
      plic_complete(irq);
    800014c4:	8526                	mv	a0,s1
    800014c6:	fffff097          	auipc	ra,0xfffff
    800014ca:	04a080e7          	jalr	74(ra) # 80000510 <plic_complete>
    return 1;
    800014ce:	4505                	li	a0,1
    800014d0:	b7d1                	j	80001494 <devintr+0x2a>
      uartintr();           // 处理串口中断
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	ee0080e7          	jalr	-288(ra) # 800003b2 <uartintr>
    if(irq)
    800014da:	b7ed                	j	800014c4 <devintr+0x5a>
    if(cpuid() == 0){
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	b26080e7          	jalr	-1242(ra) # 80001002 <cpuid>
    800014e4:	c901                	beqz	a0,800014f4 <devintr+0x8a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800014e6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800014ea:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800014ec:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    800014f0:	4509                	li	a0,2
    800014f2:	b74d                	j	80001494 <devintr+0x2a>
      timer_update();
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	d7a080e7          	jalr	-646(ra) # 8000026e <timer_update>
    800014fc:	b7ed                	j	800014e6 <devintr+0x7c>
}
    800014fe:	8082                	ret

0000000080001500 <kerneltrap>:
{
    80001500:	7179                	add	sp,sp,-48
    80001502:	f406                	sd	ra,40(sp)
    80001504:	f022                	sd	s0,32(sp)
    80001506:	ec26                	sd	s1,24(sp)
    80001508:	e84a                	sd	s2,16(sp)
    8000150a:	e44e                	sd	s3,8(sp)
    8000150c:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000150e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001512:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001516:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000151a:	1004f793          	and	a5,s1,256
    8000151e:	c78d                	beqz	a5,80001548 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001520:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001524:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80001526:	eb8d                	bnez	a5,80001558 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80001528:	00000097          	auipc	ra,0x0
    8000152c:	f42080e7          	jalr	-190(ra) # 8000146a <devintr>
    80001530:	cd05                	beqz	a0,80001568 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001532:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001536:	10049073          	csrw	sstatus,s1
}
    8000153a:	70a2                	ld	ra,40(sp)
    8000153c:	7402                	ld	s0,32(sp)
    8000153e:	64e2                	ld	s1,24(sp)
    80001540:	6942                	ld	s2,16(sp)
    80001542:	69a2                	ld	s3,8(sp)
    80001544:	6145                	add	sp,sp,48
    80001546:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80001548:	00002517          	auipc	a0,0x2
    8000154c:	e1050513          	add	a0,a0,-496 # 80003358 <digits+0x2d0>
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	232080e7          	jalr	562(ra) # 80000782 <panic>
    panic("kerneltrap: interrupts enabled");
    80001558:	00002517          	auipc	a0,0x2
    8000155c:	e2850513          	add	a0,a0,-472 # 80003380 <digits+0x2f8>
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	222080e7          	jalr	546(ra) # 80000782 <panic>
    printf("scause %p\n", scause);
    80001568:	85ce                	mv	a1,s3
    8000156a:	00002517          	auipc	a0,0x2
    8000156e:	e3650513          	add	a0,a0,-458 # 800033a0 <digits+0x318>
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	25a080e7          	jalr	602(ra) # 800007cc <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000157a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000157e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80001582:	00002517          	auipc	a0,0x2
    80001586:	e2e50513          	add	a0,a0,-466 # 800033b0 <digits+0x328>
    8000158a:	fffff097          	auipc	ra,0xfffff
    8000158e:	242080e7          	jalr	578(ra) # 800007cc <printf>
    panic("kerneltrap");
    80001592:	00002517          	auipc	a0,0x2
    80001596:	e3650513          	add	a0,a0,-458 # 800033c8 <digits+0x340>
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	1e8080e7          	jalr	488(ra) # 80000782 <panic>

00000000800015a2 <sched>:
// 并且已经改变了proc->state。
// 因为intena是这个内核线程的属性，而不是这个CPU的属性。
// 因此此处需要保存和恢复intena
void
sched(void)
{
    800015a2:	1101                	add	sp,sp,-32
    800015a4:	ec06                	sd	ra,24(sp)
    800015a6:	e822                	sd	s0,16(sp)
    800015a8:	e426                	sd	s1,8(sp)
    800015aa:	e04a                	sd	s2,0(sp)
    800015ac:	1000                	add	s0,sp,32
  int intena;
  struct proc *p = myproc();
    800015ae:	00000097          	auipc	ra,0x0
    800015b2:	a80080e7          	jalr	-1408(ra) # 8000102e <myproc>
    800015b6:	84aa                	mv	s1,a0
  // if(p->state == RUNNING)
  //   panic("sched running");
  // if(intr_get())
  //   panic("sched interruptible");

  intena = mycpu()->intena;
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	a5a080e7          	jalr	-1446(ra) # 80001012 <mycpu>
    800015c0:	00452903          	lw	s2,4(a0)
  swtch(&p->ctx, &mycpu()->context);  // 切换到调度器上下文
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	a4e080e7          	jalr	-1458(ra) # 80001012 <mycpu>
    800015cc:	01050593          	add	a1,a0,16
    800015d0:	03048513          	add	a0,s1,48
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	1b4080e7          	jalr	436(ra) # 80001788 <swtch>
  mycpu()->intena = intena;
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	a36080e7          	jalr	-1482(ra) # 80001012 <mycpu>
    800015e4:	01252223          	sw	s2,4(a0)
}
    800015e8:	60e2                	ld	ra,24(sp)
    800015ea:	6442                	ld	s0,16(sp)
    800015ec:	64a2                	ld	s1,8(sp)
    800015ee:	6902                	ld	s2,0(sp)
    800015f0:	6105                	add	sp,sp,32
    800015f2:	8082                	ret

00000000800015f4 <yield>:

// 用于进程放弃CPU, 重新进入调度
void
yield(void)
{
    800015f4:	1141                	add	sp,sp,-16
    800015f6:	e406                	sd	ra,8(sp)
    800015f8:	e022                	sd	s0,0(sp)
    800015fa:	0800                	add	s0,sp,16
  // struct proc *p = myproc();
  // acquire(&p->lock);     // 获取进程锁
  // p->state = RUNNABLE;   // 将进程状态设为可运行
  sched();               // 调用sched()切换到调度器
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	fa6080e7          	jalr	-90(ra) # 800015a2 <sched>
  // release(&p->lock);     // 释放进程锁
    80001604:	60a2                	ld	ra,8(sp)
    80001606:	6402                	ld	s0,0(sp)
    80001608:	0141                	add	sp,sp,16
    8000160a:	8082                	ret

000000008000160c <trap_user_return>:
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
    8000160c:	1141                	add	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	add	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001614:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001618:	8b89                	and	a5,a5,2
  if(intr_get())
    8000161a:	ebc1                	bnez	a5,800016aa <trap_user_return+0x9e>
    panic("trap_user_return: interrupts enabled (SIE=1) on entry");
        
  struct proc *p = myproc();
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	a12080e7          	jalr	-1518(ra) # 8000102e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001624:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001628:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000162a:	10079073          	csrw	sstatus,a5
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000162e:	00001697          	auipc	a3,0x1
    80001632:	9d268693          	add	a3,a3,-1582 # 80002000 <_trampoline>
    80001636:	00001717          	auipc	a4,0x1
    8000163a:	9ca70713          	add	a4,a4,-1590 # 80002000 <_trampoline>
    8000163e:	8f15                	sub	a4,a4,a3
    80001640:	040007b7          	lui	a5,0x4000
    80001644:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001646:	07b2                	sll	a5,a5,0xc
    80001648:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000164a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
    8000164e:	7118                	ld	a4,32(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80001650:	18002673          	csrr	a2,satp
    80001654:	e310                	sd	a2,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
    80001656:	7110                	ld	a2,32(a0)
    80001658:	7518                	ld	a4,40(a0)
    8000165a:	6585                	lui	a1,0x1
    8000165c:	972e                	add	a4,a4,a1
    8000165e:	e618                	sd	a4,8(a2)
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
    80001660:	7118                	ld	a4,32(a0)
    80001662:	00000617          	auipc	a2,0x0
    80001666:	05860613          	add	a2,a2,88 # 800016ba <trap_user_handler>
    8000166a:	eb10                	sd	a2,16(a4)
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid
    8000166c:	7118                	ld	a4,32(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000166e:	8612                	mv	a2,tp
    80001670:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001672:	10002773          	csrr	a4,sstatus
  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
    80001676:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
    8000167a:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000167e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);
    80001682:	7118                	ld	a4,32(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001684:	6f18                	ld	a4,24(a4)
    80001686:	14171073          	csrw	sepc,a4

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);
    8000168a:	6508                	ld	a0,8(a0)
    8000168c:	8131                	srl	a0,a0,0xc

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000168e:	00001717          	auipc	a4,0x1
    80001692:	a0e70713          	add	a4,a4,-1522 # 8000209c <userret>
    80001696:	8f15                	sub	a4,a4,a3
    80001698:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000169a:	577d                	li	a4,-1
    8000169c:	177e                	sll	a4,a4,0x3f
    8000169e:	8d59                	or	a0,a0,a4
    800016a0:	9782                	jalr	a5
    800016a2:	60a2                	ld	ra,8(sp)
    800016a4:	6402                	ld	s0,0(sp)
    800016a6:	0141                	add	sp,sp,16
    800016a8:	8082                	ret
    panic("trap_user_return: interrupts enabled (SIE=1) on entry");
    800016aa:	00002517          	auipc	a0,0x2
    800016ae:	d2e50513          	add	a0,a0,-722 # 800033d8 <digits+0x350>
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	0d0080e7          	jalr	208(ra) # 80000782 <panic>

00000000800016ba <trap_user_handler>:
{
    800016ba:	7139                	add	sp,sp,-64
    800016bc:	fc06                	sd	ra,56(sp)
    800016be:	f822                	sd	s0,48(sp)
    800016c0:	f426                	sd	s1,40(sp)
    800016c2:	f04a                	sd	s2,32(sp)
    800016c4:	ec4e                	sd	s3,24(sp)
    800016c6:	e852                	sd	s4,16(sp)
    800016c8:	e456                	sd	s5,8(sp)
    800016ca:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800016cc:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800016d0:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800016d4:	14202a73          	csrr	s4,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    800016d8:	14302af3          	csrr	s5,stval
    proc_t* p = myproc();
    800016dc:	00000097          	auipc	ra,0x0
    800016e0:	952080e7          	jalr	-1710(ra) # 8000102e <myproc>
    if(sstatus & SSTATUS_SPP)
    800016e4:	10097913          	and	s2,s2,256
    800016e8:	04091663          	bnez	s2,80001734 <trap_user_handler+0x7a>
    800016ec:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    800016ee:	00000797          	auipc	a5,0x0
    800016f2:	11278793          	add	a5,a5,274 # 80001800 <kernelvec>
    800016f6:	10579073          	csrw	stvec,a5
  p->tf->epc = sepc;
    800016fa:	711c                	ld	a5,32(a0)
    800016fc:	0137bc23          	sd	s3,24(a5)
  if(scause == 8){
    80001700:	47a1                	li	a5,8
    80001702:	04fa1163          	bne	s4,a5,80001744 <trap_user_handler+0x8a>
    p->tf->epc += 4;
    80001706:	7118                	ld	a4,32(a0)
    80001708:	6f1c                	ld	a5,24(a4)
    8000170a:	0791                	add	a5,a5,4
    8000170c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000170e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001712:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001716:	10079073          	csrw	sstatus,a5
  trap_user_return();
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	ef2080e7          	jalr	-270(ra) # 8000160c <trap_user_return>
}
    80001722:	70e2                	ld	ra,56(sp)
    80001724:	7442                	ld	s0,48(sp)
    80001726:	74a2                	ld	s1,40(sp)
    80001728:	7902                	ld	s2,32(sp)
    8000172a:	69e2                	ld	s3,24(sp)
    8000172c:	6a42                	ld	s4,16(sp)
    8000172e:	6aa2                	ld	s5,8(sp)
    80001730:	6121                	add	sp,sp,64
    80001732:	8082                	ret
        panic("trap_user_handler: not from u-mode");
    80001734:	00002517          	auipc	a0,0x2
    80001738:	cdc50513          	add	a0,a0,-804 # 80003410 <digits+0x388>
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	046080e7          	jalr	70(ra) # 80000782 <panic>
  } else if((which_dev = devintr()) != 0){
    80001744:	00000097          	auipc	ra,0x0
    80001748:	d26080e7          	jalr	-730(ra) # 8000146a <devintr>
    8000174c:	c909                	beqz	a0,8000175e <trap_user_handler+0xa4>
  if(which_dev == 2)
    8000174e:	4789                	li	a5,2
    80001750:	fcf515e3          	bne	a0,a5,8000171a <trap_user_handler+0x60>
    yield();  // 让出 CPU，调度其他进程
    80001754:	00000097          	auipc	ra,0x0
    80001758:	ea0080e7          	jalr	-352(ra) # 800015f4 <yield>
    8000175c:	bf7d                	j	8000171a <trap_user_handler+0x60>
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    8000175e:	4090                	lw	a2,0(s1)
    80001760:	85d2                	mv	a1,s4
    80001762:	00002517          	auipc	a0,0x2
    80001766:	cd650513          	add	a0,a0,-810 # 80003438 <digits+0x3b0>
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	062080e7          	jalr	98(ra) # 800007cc <printf>
    printf("            sepc=%p stval=%p\n", sepc, stval);
    80001772:	8656                	mv	a2,s5
    80001774:	85ce                	mv	a1,s3
    80001776:	00002517          	auipc	a0,0x2
    8000177a:	cf250513          	add	a0,a0,-782 # 80003468 <digits+0x3e0>
    8000177e:	fffff097          	auipc	ra,0xfffff
    80001782:	04e080e7          	jalr	78(ra) # 800007cc <printf>
  if(which_dev == 2)
    80001786:	bf51                	j	8000171a <trap_user_handler+0x60>

0000000080001788 <swtch>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    80001788:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    8000178c:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    80001790:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    80001792:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    80001794:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    80001798:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    8000179c:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    800017a0:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    800017a4:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    800017a8:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    800017ac:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    800017b0:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    800017b4:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    800017b8:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    800017bc:	0005b083          	ld	ra,0(a1) # 1000 <_entry-0x7ffff000>
        ld sp, 8(a1)      # 恢复栈指针
    800017c0:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    800017c4:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    800017c6:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    800017c8:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    800017cc:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    800017d0:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    800017d4:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    800017d8:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    800017dc:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    800017e0:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    800017e4:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    800017e8:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    800017ec:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    800017f0:	8082                	ret
	...

0000000080001800 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    80001800:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    80001802:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80001804:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80001806:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80001808:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    8000180a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000180c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000180e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    80001810:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    80001812:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    80001814:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80001816:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80001818:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    8000181a:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    8000181c:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    8000181e:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    80001820:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    80001822:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    80001824:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    80001826:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    80001828:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    8000182a:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    8000182c:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    8000182e:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    80001830:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    80001832:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    80001834:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    80001836:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    80001838:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    8000183a:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    8000183c:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    8000183e:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    80001840:	00000097          	auipc	ra,0x0
    80001844:	cc0080e7          	jalr	-832(ra) # 80001500 <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    80001848:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    8000184a:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    8000184c:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    8000184e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80001850:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80001852:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    80001854:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    80001856:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    80001858:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    8000185a:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    8000185c:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000185e:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    80001860:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    80001862:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80001864:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80001866:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    80001868:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    8000186a:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    8000186c:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    8000186e:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    80001870:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    80001872:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    80001874:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    80001876:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    80001878:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    8000187a:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    8000187c:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    8000187e:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80001880:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80001882:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    80001884:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    80001886:	10200073          	sret
    8000188a:	0001                	nop
    8000188c:	00000013          	nop

0000000080001890 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    80001890:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    80001894:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    80001896:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    80001898:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    8000189a:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    8000189c:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    8000189e:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    800018a0:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    800018a2:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    800018a4:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    800018a6:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    800018aa:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    800018ac:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    800018ae:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    800018b0:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    800018b4:	30200073          	mret
    800018b8:	00000013          	nop
    800018bc:	00000013          	nop
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
