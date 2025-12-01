
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
    80000004:	70010113          	add	sp,sp,1792 # 80004700 <stack0>
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
    8000001a:	69a50513          	add	a0,a0,1690 # 800046b0 <started>
    la a1, end
    8000001e:	00010597          	auipc	a1,0x10
    80000022:	59258593          	add	a1,a1,1426 # 800105b0 <end>

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
    80000046:	454080e7          	jalr	1108(ra) # 80001496 <cpuid>
    started = 1;         // 标记系统启动完成
    __sync_synchronize();

  } else {
    //其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000004a:	00004717          	auipc	a4,0x4
    8000004e:	66670713          	add	a4,a4,1638 # 800046b0 <started>
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
    80000062:	438080e7          	jalr	1080(ra) # 80001496 <cpuid>
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
    80000084:	0c6080e7          	jalr	198(ra) # 80002146 <trapinithart>
    plicinithart();   // 向PLIC请求设备中断
    80000088:	00000097          	auipc	ra,0x0
    8000008c:	414080e7          	jalr	1044(ra) # 8000049c <plicinithart>
  }
  // 所有CPU都进入调度器，开始调度用户进程
  scheduler(); 
    80000090:	00002097          	auipc	ra,0x2
    80000094:	220080e7          	jalr	544(ra) # 800022b0 <scheduler>
    initlock(&start_lock,"start_lock");
    80000098:	00004597          	auipc	a1,0x4
    8000009c:	f7858593          	add	a1,a1,-136 # 80004010 <etext+0x10>
    800000a0:	00004517          	auipc	a0,0x4
    800000a4:	64050513          	add	a0,a0,1600 # 800046e0 <start_lock>
    800000a8:	00002097          	auipc	ra,0x2
    800000ac:	eec080e7          	jalr	-276(ra) # 80001f94 <initlock>
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
    800000d4:	3c6080e7          	jalr	966(ra) # 80001496 <cpuid>
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
    80000106:	512080e7          	jalr	1298(ra) # 80001614 <procinit>
    timer_create();      // 陷阱向量(时钟中断）初始化
    8000010a:	00000097          	auipc	ra,0x0
    8000010e:	11c080e7          	jalr	284(ra) # 80000226 <timer_create>
    trapinithart();      // 安装内核陷阱向量
    80000112:	00002097          	auipc	ra,0x2
    80000116:	034080e7          	jalr	52(ra) # 80002146 <trapinithart>
    plicinit();          // 设置中断控制器
    8000011a:	00000097          	auipc	ra,0x0
    8000011e:	36c080e7          	jalr	876(ra) # 80000486 <plicinit>
    plicinithart();      // 向PLIC请求设备中断
    80000122:	00000097          	auipc	ra,0x0
    80000126:	37a080e7          	jalr	890(ra) # 8000049c <plicinithart>
    userinit();   // 创建第一个用户进程 userinit();   
    8000012a:	00001097          	auipc	ra,0x1
    8000012e:	7e0080e7          	jalr	2016(ra) # 8000190a <userinit>
    started = 1;         // 标记系统启动完成
    80000132:	4785                	li	a5,1
    80000134:	00004717          	auipc	a4,0x4
    80000138:	56f72e23          	sw	a5,1404(a4) # 800046b0 <started>
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
    80000150:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffee24f>
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
    800001ee:	51670713          	add	a4,a4,1302 # 8000c700 <timer_scratch>
    800001f2:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    800001f4:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    800001f6:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    800001f8:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    800001fc:	00003797          	auipc	a5,0x3
    80000200:	ac478793          	add	a5,a5,-1340 # 80002cc0 <timervec>
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
timer_t sys_timer;

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
    8000023a:	61250513          	add	a0,a0,1554 # 8000c848 <sys_timer+0x8>
    8000023e:	00002097          	auipc	ra,0x2
    80000242:	d56080e7          	jalr	-682(ra) # 80001f94 <initlock>
    sys_timer.ticks = 0;
    80000246:	0000c797          	auipc	a5,0xc
    8000024a:	5e07bd23          	sd	zero,1530(a5) # 8000c840 <sys_timer>
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
    80000266:	49e90913          	add	s2,s2,1182 # 8000c700 <timer_scratch>
    8000026a:	0000c497          	auipc	s1,0xc
    8000026e:	5de48493          	add	s1,s1,1502 # 8000c848 <sys_timer+0x8>
    80000272:	8526                	mv	a0,s1
    80000274:	00002097          	auipc	ra,0x2
    80000278:	db0080e7          	jalr	-592(ra) # 80002024 <acquire>
    sys_timer.ticks++;
    8000027c:	14093783          	ld	a5,320(s2)
    80000280:	0785                	add	a5,a5,1
    80000282:	14f93023          	sd	a5,320(s2)
    // printf("ticks: %d\n", sys_timer.ticks);
    release(&sys_timer.lk);
    80000286:	8526                	mv	a0,s1
    80000288:	00002097          	auipc	ra,0x2
    8000028c:	e50080e7          	jalr	-432(ra) # 800020d8 <release>
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
    800002ac:	5a048493          	add	s1,s1,1440 # 8000c848 <sys_timer+0x8>
    800002b0:	8526                	mv	a0,s1
    800002b2:	00002097          	auipc	ra,0x2
    800002b6:	d72080e7          	jalr	-654(ra) # 80002024 <acquire>
    xticks = sys_timer.ticks;
    800002ba:	0000c917          	auipc	s2,0xc
    800002be:	58693903          	ld	s2,1414(s2) # 8000c840 <sys_timer>
    release(&sys_timer.lk);
    800002c2:	8526                	mv	a0,s1
    800002c4:	00002097          	auipc	ra,0x2
    800002c8:	e14080e7          	jalr	-492(ra) # 800020d8 <release>
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
    80000316:	54e50513          	add	a0,a0,1358 # 8000c860 <uart_tx_lock>
    8000031a:	00002097          	auipc	ra,0x2
    8000031e:	c7a080e7          	jalr	-902(ra) # 80001f94 <initlock>
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
    80000336:	00002097          	auipc	ra,0x2
    8000033a:	ca2080e7          	jalr	-862(ra) # 80001fd8 <push_off>
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    8000033e:	00004797          	auipc	a5,0x4
    80000342:	38a7a783          	lw	a5,906(a5) # 800046c8 <panicked>
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
    80000364:	00002097          	auipc	ra,0x2
    80000368:	d14080e7          	jalr	-748(ra) # 80002078 <pop_off>
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
    8000046a:	43250513          	add	a0,a0,1074 # 8000c898 <cons>
    8000046e:	00002097          	auipc	ra,0x2
    80000472:	b26080e7          	jalr	-1242(ra) # 80001f94 <initlock>

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
    800004a8:	ff2080e7          	jalr	-14(ra) # 80001496 <cpuid>
  
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
    800004e0:	fba080e7          	jalr	-70(ra) # 80001496 <cpuid>
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
    80000508:	f92080e7          	jalr	-110(ra) # 80001496 <cpuid>
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
    8000077a:	1e07a123          	sw	zero,482(a5) # 8000c958 <pr+0x18>
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
    800007ae:	f0f72f23          	sw	a5,-226(a4) # 800046c8 <panicked>
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
    800007ea:	172dad83          	lw	s11,370(s11) # 8000c958 <pr+0x18>
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
    80000828:	11c50513          	add	a0,a0,284 # 8000c940 <pr>
    8000082c:	00001097          	auipc	ra,0x1
    80000830:	7f8080e7          	jalr	2040(ra) # 80002024 <acquire>
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
    80000986:	fbe50513          	add	a0,a0,-66 # 8000c940 <pr>
    8000098a:	00001097          	auipc	ra,0x1
    8000098e:	74e080e7          	jalr	1870(ra) # 800020d8 <release>
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
    800009a2:	fa248493          	add	s1,s1,-94 # 8000c940 <pr>
    800009a6:	00003597          	auipc	a1,0x3
    800009aa:	6d258593          	add	a1,a1,1746 # 80004078 <etext+0x78>
    800009ae:	8526                	mv	a0,s1
    800009b0:	00001097          	auipc	ra,0x1
    800009b4:	5e4080e7          	jalr	1508(ra) # 80001f94 <initlock>
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
    800009da:	00010797          	auipc	a5,0x10
    800009de:	bd678793          	add	a5,a5,-1066 # 800105b0 <end>
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
    800009fe:	f6690913          	add	s2,s2,-154 # 8000c960 <kmem>
    80000a02:	854a                	mv	a0,s2
    80000a04:	00001097          	auipc	ra,0x1
    80000a08:	620080e7          	jalr	1568(ra) # 80002024 <acquire>
  r->next = kmem.freelist;  //头插
    80000a0c:	01893783          	ld	a5,24(s2)
    80000a10:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a12:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a16:	854a                	mv	a0,s2
    80000a18:	00001097          	auipc	ra,0x1
    80000a1c:	6c0080e7          	jalr	1728(ra) # 800020d8 <release>
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
    80000a9e:	ec650513          	add	a0,a0,-314 # 8000c960 <kmem>
    80000aa2:	00001097          	auipc	ra,0x1
    80000aa6:	4f2080e7          	jalr	1266(ra) # 80001f94 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aaa:	45c5                	li	a1,17
    80000aac:	05ee                	sll	a1,a1,0x1b
    80000aae:	00010517          	auipc	a0,0x10
    80000ab2:	b0250513          	add	a0,a0,-1278 # 800105b0 <end>
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
    80000ad4:	e9048493          	add	s1,s1,-368 # 8000c960 <kmem>
    80000ad8:	8526                	mv	a0,s1
    80000ada:	00001097          	auipc	ra,0x1
    80000ade:	54a080e7          	jalr	1354(ra) # 80002024 <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80000ae2:	6c84                	ld	s1,24(s1)
  if(r)
    80000ae4:	c885                	beqz	s1,80000b14 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000ae6:	609c                	ld	a5,0(s1)
    80000ae8:	0000c517          	auipc	a0,0xc
    80000aec:	e7850513          	add	a0,a0,-392 # 8000c960 <kmem>
    80000af0:	ed1c                	sd	a5,24(a0)
  else 
    panic("kalloc: out of memory");
  release(&kmem.lock);
    80000af2:	00001097          	auipc	ra,0x1
    80000af6:	5e6080e7          	jalr	1510(ra) # 800020d8 <release>

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
    80000b32:	ba27b783          	ld	a5,-1118(a5) # 800046d0 <kernel_pagetable>
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
    80000bae:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffeea47>
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
  proc_mapstacks(kpgtbl);
    80000da8:	8526                	mv	a0,s1
    80000daa:	00000097          	auipc	ra,0x0
    80000dae:	7d2080e7          	jalr	2002(ra) # 8000157c <proc_mapstacks>
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
    80000dd4:	90a7b023          	sd	a0,-1792(a5) # 800046d0 <kernel_pagetable>
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

0000000080000e20 <freewalk>:
#define PAGE_TABLE_ENTRIES 512

// 递归释放页表页面
// 所有叶子映射必须已经被移除
void freewalk(pagetable_t pagetable)
{
    80000e20:	7179                	add	sp,sp,-48
    80000e22:	f406                	sd	ra,40(sp)
    80000e24:	f022                	sd	s0,32(sp)
    80000e26:	ec26                	sd	s1,24(sp)
    80000e28:	e84a                	sd	s2,16(sp)
    80000e2a:	e44e                	sd	s3,8(sp)
    80000e2c:	e052                	sd	s4,0(sp)
    80000e2e:	1800                	add	s0,sp,48
    80000e30:	8a2a                	mv	s4,a0
  // 遍历页表中的所有PTE
  for (int i = 0; i < PAGE_TABLE_ENTRIES; i++)
    80000e32:	6905                	lui	s2,0x1
    80000e34:	992a                	add	s2,s2,a0
{
    80000e36:	84aa                	mv	s1,a0
    80000e38:	a821                	j	80000e50 <freewalk+0x30>
      pagetable[i] = 0;
    }
    else if (is_pte_valid(pte))
    {
      // 发现叶子页面，应该已经被清理
      panic("freewalk: found unexpected leaf page");
    80000e3a:	00003517          	auipc	a0,0x3
    80000e3e:	2f650513          	add	a0,a0,758 # 80004130 <digits+0xb0>
    80000e42:	00000097          	auipc	ra,0x0
    80000e46:	928080e7          	jalr	-1752(ra) # 8000076a <panic>
  for (int i = 0; i < PAGE_TABLE_ENTRIES; i++)
    80000e4a:	04a1                	add	s1,s1,8
    80000e4c:	03248363          	beq	s1,s2,80000e72 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80000e50:	609c                	ld	a5,0(s1)
  return (pte & PTE_V) != 0;
    80000e52:	0017f713          	and	a4,a5,1
  return is_pte_valid(pte) && !is_pte_leaf(pte);
    80000e56:	db75                	beqz	a4,80000e4a <freewalk+0x2a>
  return (pte & (PTE_R | PTE_W | PTE_X)) != 0;
    80000e58:	00e7f713          	and	a4,a5,14
  return is_pte_valid(pte) && !is_pte_leaf(pte);
    80000e5c:	ff79                	bnez	a4,80000e3a <freewalk+0x1a>
  return PTE2PA(pte);
    80000e5e:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child_pa);
    80000e60:	00c79513          	sll	a0,a5,0xc
    80000e64:	00000097          	auipc	ra,0x0
    80000e68:	fbc080e7          	jalr	-68(ra) # 80000e20 <freewalk>
      pagetable[i] = 0;
    80000e6c:	0004b023          	sd	zero,0(s1)
    80000e70:	bfe9                	j	80000e4a <freewalk+0x2a>
    }
  }

  // 释放当前页表页面
  kfree((uint64)pagetable, true);
    80000e72:	4585                	li	a1,1
    80000e74:	8552                	mv	a0,s4
    80000e76:	00000097          	auipc	ra,0x0
    80000e7a:	b50080e7          	jalr	-1200(ra) # 800009c6 <kfree>
}
    80000e7e:	70a2                	ld	ra,40(sp)
    80000e80:	7402                	ld	s0,32(sp)
    80000e82:	64e2                	ld	s1,24(sp)
    80000e84:	6942                	ld	s2,16(sp)
    80000e86:	69a2                	ld	s3,8(sp)
    80000e88:	6a02                	ld	s4,0(sp)
    80000e8a:	6145                	add	sp,sp,48
    80000e8c:	8082                	ret

0000000080000e8e <print_pgtbl>:

void print_pgtbl(pagetable_t pagetable, int level) {
    80000e8e:	711d                	add	sp,sp,-96
    80000e90:	ec86                	sd	ra,88(sp)
    80000e92:	e8a2                	sd	s0,80(sp)
    80000e94:	e4a6                	sd	s1,72(sp)
    80000e96:	e0ca                	sd	s2,64(sp)
    80000e98:	fc4e                	sd	s3,56(sp)
    80000e9a:	f852                	sd	s4,48(sp)
    80000e9c:	f456                	sd	s5,40(sp)
    80000e9e:	f05a                	sd	s6,32(sp)
    80000ea0:	ec5e                	sd	s7,24(sp)
    80000ea2:	e862                	sd	s8,16(sp)
    80000ea4:	e466                	sd	s9,8(sp)
    80000ea6:	e06a                	sd	s10,0(sp)
    80000ea8:	1080                	add	s0,sp,96
    80000eaa:	8aae                	mv	s5,a1
  //递归打印页表
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000eac:	8a2a                	mv	s4,a0
    80000eae:	4981                	li	s3,0
    if(pte & PTE_V) {// 打印有效的页表项

      for(int j = 0; j < level; j++)
        printf("  ");

      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    80000eb0:	00003c17          	auipc	s8,0x3
    80000eb4:	2b0c0c13          	add	s8,s8,688 # 80004160 <digits+0xe0>

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
    80000eb8:	00003d17          	auipc	s10,0x3
    80000ebc:	2c0d0d13          	add	s10,s10,704 # 80004178 <digits+0xf8>
      for(int j = 0; j < level; j++)
    80000ec0:	4c81                	li	s9,0
        printf("  ");
    80000ec2:	00003b17          	auipc	s6,0x3
    80000ec6:	296b0b13          	add	s6,s6,662 # 80004158 <digits+0xd8>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000eca:	20000b93          	li	s7,512
    80000ece:	a025                	j	80000ef6 <print_pgtbl+0x68>
      } 
      else {
        printf("\n");
    80000ed0:	00003517          	auipc	a0,0x3
    80000ed4:	16050513          	add	a0,a0,352 # 80004030 <etext+0x30>
    80000ed8:	00000097          	auipc	ra,0x0
    80000edc:	8dc080e7          	jalr	-1828(ra) # 800007b4 <printf>
        print_pgtbl((pagetable_t)PTE2PA(pte), level + 1);
    80000ee0:	001a859b          	addw	a1,s5,1
    80000ee4:	8526                	mv	a0,s1
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	fa8080e7          	jalr	-88(ra) # 80000e8e <print_pgtbl>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000eee:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    80000ef0:	0a21                	add	s4,s4,8
    80000ef2:	05798763          	beq	s3,s7,80000f40 <print_pgtbl+0xb2>
    pte_t pte = pagetable[i];
    80000ef6:	000a3903          	ld	s2,0(s4)
    if(pte & PTE_V) {// 打印有效的页表项
    80000efa:	00197793          	and	a5,s2,1
    80000efe:	dbe5                	beqz	a5,80000eee <print_pgtbl+0x60>
      for(int j = 0; j < level; j++)
    80000f00:	01505b63          	blez	s5,80000f16 <print_pgtbl+0x88>
    80000f04:	84e6                	mv	s1,s9
        printf("  ");
    80000f06:	855a                	mv	a0,s6
    80000f08:	00000097          	auipc	ra,0x0
    80000f0c:	8ac080e7          	jalr	-1876(ra) # 800007b4 <printf>
      for(int j = 0; j < level; j++)
    80000f10:	2485                	addw	s1,s1,1
    80000f12:	fe9a9ae3          	bne	s5,s1,80000f06 <print_pgtbl+0x78>
      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    80000f16:	00a95493          	srl	s1,s2,0xa
    80000f1a:	04b2                	sll	s1,s1,0xc
    80000f1c:	86a6                	mv	a3,s1
    80000f1e:	864a                	mv	a2,s2
    80000f20:	85ce                	mv	a1,s3
    80000f22:	8562                	mv	a0,s8
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	890080e7          	jalr	-1904(ra) # 800007b4 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000f2c:	00e97913          	and	s2,s2,14
    80000f30:	fa0900e3          	beqz	s2,80000ed0 <print_pgtbl+0x42>
        printf(" [leaf]\n");
    80000f34:	856a                	mv	a0,s10
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	87e080e7          	jalr	-1922(ra) # 800007b4 <printf>
    80000f3e:	bf45                	j	80000eee <print_pgtbl+0x60>
      }
    }
  }
}
    80000f40:	60e6                	ld	ra,88(sp)
    80000f42:	6446                	ld	s0,80(sp)
    80000f44:	64a6                	ld	s1,72(sp)
    80000f46:	6906                	ld	s2,64(sp)
    80000f48:	79e2                	ld	s3,56(sp)
    80000f4a:	7a42                	ld	s4,48(sp)
    80000f4c:	7aa2                	ld	s5,40(sp)
    80000f4e:	7b02                	ld	s6,32(sp)
    80000f50:	6be2                	ld	s7,24(sp)
    80000f52:	6c42                	ld	s8,16(sp)
    80000f54:	6ca2                	ld	s9,8(sp)
    80000f56:	6d02                	ld	s10,0(sp)
    80000f58:	6125                	add	sp,sp,96
    80000f5a:	8082                	ret

0000000080000f5c <print_cur_pgtbl>:

void print_cur_pgtbl(pagetable_t pagetable) {
    80000f5c:	715d                	add	sp,sp,-80
    80000f5e:	e486                	sd	ra,72(sp)
    80000f60:	e0a2                	sd	s0,64(sp)
    80000f62:	fc26                	sd	s1,56(sp)
    80000f64:	f84a                	sd	s2,48(sp)
    80000f66:	f44e                	sd	s3,40(sp)
    80000f68:	f052                	sd	s4,32(sp)
    80000f6a:	ec56                	sd	s5,24(sp)
    80000f6c:	e85a                	sd	s6,16(sp)
    80000f6e:	e45e                	sd	s7,8(sp)
    80000f70:	0880                	add	s0,sp,80
    80000f72:	89aa                	mv	s3,a0
  //打印当前层页表
  printf("page table %p\n", pagetable);
    80000f74:	85aa                	mv	a1,a0
    80000f76:	00003517          	auipc	a0,0x3
    80000f7a:	21250513          	add	a0,a0,530 # 80004188 <digits+0x108>
    80000f7e:	00000097          	auipc	ra,0x0
    80000f82:	836080e7          	jalr	-1994(ra) # 800007b4 <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f86:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000f88:	00003a97          	auipc	s5,0x3
    80000f8c:	210a8a93          	add	s5,s5,528 # 80004198 <digits+0x118>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
    80000f90:	00003b97          	auipc	s7,0x3
    80000f94:	0a0b8b93          	add	s7,s7,160 # 80004030 <etext+0x30>
        printf(" [leaf]\n");
    80000f98:	00003b17          	auipc	s6,0x3
    80000f9c:	1e0b0b13          	add	s6,s6,480 # 80004178 <digits+0xf8>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000fa0:	20000a13          	li	s4,512
    80000fa4:	a811                	j	80000fb8 <print_cur_pgtbl+0x5c>
        printf("\n");
    80000fa6:	855e                	mv	a0,s7
    80000fa8:	00000097          	auipc	ra,0x0
    80000fac:	80c080e7          	jalr	-2036(ra) # 800007b4 <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000fb0:	2905                	addw	s2,s2,1 # 1001 <_entry-0x7fffefff>
    80000fb2:	09a1                	add	s3,s3,8
    80000fb4:	03490963          	beq	s2,s4,80000fe6 <print_cur_pgtbl+0x8a>
    pte_t pte = pagetable[i];
    80000fb8:	0009b483          	ld	s1,0(s3)
    if(pte & PTE_V) {// 打印有效的页表项
    80000fbc:	0014f793          	and	a5,s1,1
    80000fc0:	dbe5                	beqz	a5,80000fb0 <print_cur_pgtbl+0x54>
      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000fc2:	00a4d693          	srl	a3,s1,0xa
    80000fc6:	06b2                	sll	a3,a3,0xc
    80000fc8:	8626                	mv	a2,s1
    80000fca:	85ca                	mv	a1,s2
    80000fcc:	8556                	mv	a0,s5
    80000fce:	fffff097          	auipc	ra,0xfffff
    80000fd2:	7e6080e7          	jalr	2022(ra) # 800007b4 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000fd6:	88b9                	and	s1,s1,14
    80000fd8:	d4f9                	beqz	s1,80000fa6 <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80000fda:	855a                	mv	a0,s6
    80000fdc:	fffff097          	auipc	ra,0xfffff
    80000fe0:	7d8080e7          	jalr	2008(ra) # 800007b4 <printf>
    80000fe4:	b7f1                	j	80000fb0 <print_cur_pgtbl+0x54>
      }
    }
  }
    80000fe6:	60a6                	ld	ra,72(sp)
    80000fe8:	6406                	ld	s0,64(sp)
    80000fea:	74e2                	ld	s1,56(sp)
    80000fec:	7942                	ld	s2,48(sp)
    80000fee:	79a2                	ld	s3,40(sp)
    80000ff0:	7a02                	ld	s4,32(sp)
    80000ff2:	6ae2                	ld	s5,24(sp)
    80000ff4:	6b42                	ld	s6,16(sp)
    80000ff6:	6ba2                	ld	s7,8(sp)
    80000ff8:	6161                	add	sp,sp,80
    80000ffa:	8082                	ret

0000000080000ffc <uvmcreate>:


// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
    80000ffc:	1101                	add	sp,sp,-32
    80000ffe:	ec06                	sd	ra,24(sp)
    80001000:	e822                	sd	s0,16(sp)
    80001002:	e426                	sd	s1,8(sp)
    80001004:	1000                	add	s0,sp,32
  pagetable_t pagetable = (pagetable_t)kalloc(true);
    80001006:	4505                	li	a0,1
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	abe080e7          	jalr	-1346(ra) # 80000ac6 <kalloc>
    80001010:	84aa                	mv	s1,a0
  if(pagetable)
    80001012:	c519                	beqz	a0,80001020 <uvmcreate+0x24>
    memset(pagetable, 0, PGSIZE);
    80001014:	6605                	lui	a2,0x1
    80001016:	4581                	li	a1,0
    80001018:	fffff097          	auipc	ra,0xfffff
    8000101c:	50a080e7          	jalr	1290(ra) # 80000522 <memset>
  return pagetable;
}
    80001020:	8526                	mv	a0,s1
    80001022:	60e2                	ld	ra,24(sp)
    80001024:	6442                	ld	s0,16(sp)
    80001026:	64a2                	ld	s1,8(sp)
    80001028:	6105                	add	sp,sp,32
    8000102a:	8082                	ret

000000008000102c <uvmfirst>:

void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000102c:	7179                	add	sp,sp,-48
    8000102e:	f406                	sd	ra,40(sp)
    80001030:	f022                	sd	s0,32(sp)
    80001032:	ec26                	sd	s1,24(sp)
    80001034:	e84a                	sd	s2,16(sp)
    80001036:	e44e                	sd	s3,8(sp)
    80001038:	e052                	sd	s4,0(sp)
    8000103a:	1800                	add	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    8000103c:	6785                	lui	a5,0x1
    8000103e:	04f67963          	bgeu	a2,a5,80001090 <uvmfirst+0x64>
    80001042:	8a2a                	mv	s4,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc(1);
    80001048:	4505                	li	a0,1
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	a7c080e7          	jalr	-1412(ra) # 80000ac6 <kalloc>
    80001052:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001054:	6605                	lui	a2,0x1
    80001056:	4581                	li	a1,0
    80001058:	fffff097          	auipc	ra,0xfffff
    8000105c:	4ca080e7          	jalr	1226(ra) # 80000522 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001060:	4779                	li	a4,30
    80001062:	86ca                	mv	a3,s2
    80001064:	6605                	lui	a2,0x1
    80001066:	4581                	li	a1,0
    80001068:	8552                	mv	a0,s4
    8000106a:	00000097          	auipc	ra,0x0
    8000106e:	b8a080e7          	jalr	-1142(ra) # 80000bf4 <mappages>
  memmove(mem, src, sz);
    80001072:	8626                	mv	a2,s1
    80001074:	85ce                	mv	a1,s3
    80001076:	854a                	mv	a0,s2
    80001078:	fffff097          	auipc	ra,0xfffff
    8000107c:	506080e7          	jalr	1286(ra) # 8000057e <memmove>
}
    80001080:	70a2                	ld	ra,40(sp)
    80001082:	7402                	ld	s0,32(sp)
    80001084:	64e2                	ld	s1,24(sp)
    80001086:	6942                	ld	s2,16(sp)
    80001088:	69a2                	ld	s3,8(sp)
    8000108a:	6a02                	ld	s4,0(sp)
    8000108c:	6145                	add	sp,sp,48
    8000108e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001090:	00003517          	auipc	a0,0x3
    80001094:	12850513          	add	a0,a0,296 # 800041b8 <digits+0x138>
    80001098:	fffff097          	auipc	ra,0xfffff
    8000109c:	6d2080e7          	jalr	1746(ra) # 8000076a <panic>

00000000800010a0 <uvmunmap>:

// 从va开始移除npages个映射。va必须是
// 页面对齐的。映射必须存在。
// 可选择释放物理内存
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800010a0:	715d                	add	sp,sp,-80
    800010a2:	e486                	sd	ra,72(sp)
    800010a4:	e0a2                	sd	s0,64(sp)
    800010a6:	fc26                	sd	s1,56(sp)
    800010a8:	f84a                	sd	s2,48(sp)
    800010aa:	f44e                	sd	s3,40(sp)
    800010ac:	f052                	sd	s4,32(sp)
    800010ae:	ec56                	sd	s5,24(sp)
    800010b0:	e85a                	sd	s6,16(sp)
    800010b2:	e45e                	sd	s7,8(sp)
    800010b4:	0880                	add	s0,sp,80
  return (addr % PGSIZE) == 0;
    800010b6:	03459793          	sll	a5,a1,0x34
  uint64 current_va;
  pte_t *pte;

  if (!is_page_aligned(va))
    800010ba:	e795                	bnez	a5,800010e6 <uvmunmap+0x46>
    800010bc:	8a2a                	mv	s4,a0
    800010be:	892e                	mv	s2,a1
    800010c0:	8ab6                	mv	s5,a3
    panic("uvmunmap: address not page aligned");

  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    800010c2:	0632                	sll	a2,a2,0xc
    800010c4:	00b609b3          	add	s3,a2,a1
  if (PTE_FLAGS(pte) == PTE_V)
    800010c8:	4b05                	li	s6,1
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    800010ca:	6b85                	lui	s7,0x1
    800010cc:	0735e263          	bltu	a1,s3,80001130 <uvmunmap+0x90>
      free_physical_page_from_pte(*pte);
    }

    clear_pte(pte);
  }
}
    800010d0:	60a6                	ld	ra,72(sp)
    800010d2:	6406                	ld	s0,64(sp)
    800010d4:	74e2                	ld	s1,56(sp)
    800010d6:	7942                	ld	s2,48(sp)
    800010d8:	79a2                	ld	s3,40(sp)
    800010da:	7a02                	ld	s4,32(sp)
    800010dc:	6ae2                	ld	s5,24(sp)
    800010de:	6b42                	ld	s6,16(sp)
    800010e0:	6ba2                	ld	s7,8(sp)
    800010e2:	6161                	add	sp,sp,80
    800010e4:	8082                	ret
    panic("uvmunmap: address not page aligned");
    800010e6:	00003517          	auipc	a0,0x3
    800010ea:	0f250513          	add	a0,a0,242 # 800041d8 <digits+0x158>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	67c080e7          	jalr	1660(ra) # 8000076a <panic>
      panic("uvmunmap: walk failed");
    800010f6:	00003517          	auipc	a0,0x3
    800010fa:	10a50513          	add	a0,a0,266 # 80004200 <digits+0x180>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	66c080e7          	jalr	1644(ra) # 8000076a <panic>
    panic("uvmunmap: page not mapped");
    80001106:	00003517          	auipc	a0,0x3
    8000110a:	11250513          	add	a0,a0,274 # 80004218 <digits+0x198>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	65c080e7          	jalr	1628(ra) # 8000076a <panic>
    panic("uvmunmap: not a leaf page");
    80001116:	00003517          	auipc	a0,0x3
    8000111a:	12250513          	add	a0,a0,290 # 80004238 <digits+0x1b8>
    8000111e:	fffff097          	auipc	ra,0xfffff
    80001122:	64c080e7          	jalr	1612(ra) # 8000076a <panic>
  *pte = 0;
    80001126:	0004b023          	sd	zero,0(s1)
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    8000112a:	995e                	add	s2,s2,s7
    8000112c:	fb3972e3          	bgeu	s2,s3,800010d0 <uvmunmap+0x30>
    pte = walk(pagetable, current_va, 0);
    80001130:	4601                	li	a2,0
    80001132:	85ca                	mv	a1,s2
    80001134:	8552                	mv	a0,s4
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	a16080e7          	jalr	-1514(ra) # 80000b4c <walk>
    8000113e:	84aa                	mv	s1,a0
    if (pte == 0)
    80001140:	d95d                	beqz	a0,800010f6 <uvmunmap+0x56>
    validate_page_mapping(*pte);
    80001142:	611c                	ld	a5,0(a0)
  return (pte & PTE_V) != 0;
    80001144:	0017f713          	and	a4,a5,1
  if (!is_pte_valid(pte))
    80001148:	df5d                	beqz	a4,80001106 <uvmunmap+0x66>
  if (PTE_FLAGS(pte) == PTE_V)
    8000114a:	3ff7f713          	and	a4,a5,1023
    8000114e:	fd6704e3          	beq	a4,s6,80001116 <uvmunmap+0x76>
    if (do_free)
    80001152:	fc0a8ae3          	beqz	s5,80001126 <uvmunmap+0x86>
  uint64 pa = PTE2PA(pte);
    80001156:	83a9                	srl	a5,a5,0xa
  kfree(pa,0);
    80001158:	4581                	li	a1,0
    8000115a:	00c79513          	sll	a0,a5,0xc
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	868080e7          	jalr	-1944(ra) # 800009c6 <kfree>
}
    80001166:	b7c1                	j	80001126 <uvmunmap+0x86>

0000000080001168 <uvmdealloc>:
{
    80001168:	1101                	add	sp,sp,-32
    8000116a:	ec06                	sd	ra,24(sp)
    8000116c:	e822                	sd	s0,16(sp)
    8000116e:	e426                	sd	s1,8(sp)
    80001170:	1000                	add	s0,sp,32
    return oldsz;
    80001172:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    80001174:	00b67d63          	bgeu	a2,a1,8000118e <uvmdealloc+0x26>
    80001178:	84b2                	mv	s1,a2
  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    8000117a:	6785                	lui	a5,0x1
    8000117c:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000117e:	00f60733          	add	a4,a2,a5
    80001182:	76fd                	lui	a3,0xfffff
    80001184:	8f75                	and	a4,a4,a3
    80001186:	97ae                	add	a5,a5,a1
    80001188:	8ff5                	and	a5,a5,a3
    8000118a:	00f76863          	bltu	a4,a5,8000119a <uvmdealloc+0x32>
}
    8000118e:	8526                	mv	a0,s1
    80001190:	60e2                	ld	ra,24(sp)
    80001192:	6442                	ld	s0,16(sp)
    80001194:	64a2                	ld	s1,8(sp)
    80001196:	6105                	add	sp,sp,32
    80001198:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000119a:	8f99                	sub	a5,a5,a4
    8000119c:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000119e:	4685                	li	a3,1
    800011a0:	0007861b          	sext.w	a2,a5
    800011a4:	85ba                	mv	a1,a4
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	efa080e7          	jalr	-262(ra) # 800010a0 <uvmunmap>
    800011ae:	b7c5                	j	8000118e <uvmdealloc+0x26>

00000000800011b0 <uvmalloc>:
  if (newsz < oldsz)
    800011b0:	0ab66763          	bltu	a2,a1,8000125e <uvmalloc+0xae>
{
    800011b4:	7139                	add	sp,sp,-64
    800011b6:	fc06                	sd	ra,56(sp)
    800011b8:	f822                	sd	s0,48(sp)
    800011ba:	f426                	sd	s1,40(sp)
    800011bc:	f04a                	sd	s2,32(sp)
    800011be:	ec4e                	sd	s3,24(sp)
    800011c0:	e852                	sd	s4,16(sp)
    800011c2:	e456                	sd	s5,8(sp)
    800011c4:	e05a                	sd	s6,0(sp)
    800011c6:	0080                	add	s0,sp,64
    800011c8:	8aaa                	mv	s5,a0
    800011ca:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800011cc:	6785                	lui	a5,0x1
    800011ce:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800011d0:	95be                	add	a1,a1,a5
    800011d2:	77fd                	lui	a5,0xfffff
    800011d4:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    800011d8:	08c9f563          	bgeu	s3,a2,80001262 <uvmalloc+0xb2>
    800011dc:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800011de:	0126eb13          	or	s6,a3,18
    mem = kalloc(0);
    800011e2:	4501                	li	a0,0
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	8e2080e7          	jalr	-1822(ra) # 80000ac6 <kalloc>
    800011ec:	84aa                	mv	s1,a0
    if (mem == 0)
    800011ee:	c51d                	beqz	a0,8000121c <uvmalloc+0x6c>
    memset(mem, 0, PGSIZE);
    800011f0:	6605                	lui	a2,0x1
    800011f2:	4581                	li	a1,0
    800011f4:	fffff097          	auipc	ra,0xfffff
    800011f8:	32e080e7          	jalr	814(ra) # 80000522 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800011fc:	875a                	mv	a4,s6
    800011fe:	86a6                	mv	a3,s1
    80001200:	6605                	lui	a2,0x1
    80001202:	85ca                	mv	a1,s2
    80001204:	8556                	mv	a0,s5
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	9ee080e7          	jalr	-1554(ra) # 80000bf4 <mappages>
    8000120e:	e90d                	bnez	a0,80001240 <uvmalloc+0x90>
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001210:	6785                	lui	a5,0x1
    80001212:	993e                	add	s2,s2,a5
    80001214:	fd4967e3          	bltu	s2,s4,800011e2 <uvmalloc+0x32>
  return newsz;
    80001218:	8552                	mv	a0,s4
    8000121a:	a809                	j	8000122c <uvmalloc+0x7c>
      uvmdealloc(pagetable, a, oldsz);
    8000121c:	864e                	mv	a2,s3
    8000121e:	85ca                	mv	a1,s2
    80001220:	8556                	mv	a0,s5
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f46080e7          	jalr	-186(ra) # 80001168 <uvmdealloc>
      return 0;
    8000122a:	4501                	li	a0,0
}
    8000122c:	70e2                	ld	ra,56(sp)
    8000122e:	7442                	ld	s0,48(sp)
    80001230:	74a2                	ld	s1,40(sp)
    80001232:	7902                	ld	s2,32(sp)
    80001234:	69e2                	ld	s3,24(sp)
    80001236:	6a42                	ld	s4,16(sp)
    80001238:	6aa2                	ld	s5,8(sp)
    8000123a:	6b02                	ld	s6,0(sp)
    8000123c:	6121                	add	sp,sp,64
    8000123e:	8082                	ret
      kfree((uint64)mem,0);
    80001240:	4581                	li	a1,0
    80001242:	8526                	mv	a0,s1
    80001244:	fffff097          	auipc	ra,0xfffff
    80001248:	782080e7          	jalr	1922(ra) # 800009c6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000124c:	864e                	mv	a2,s3
    8000124e:	85ca                	mv	a1,s2
    80001250:	8556                	mv	a0,s5
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f16080e7          	jalr	-234(ra) # 80001168 <uvmdealloc>
      return 0;
    8000125a:	4501                	li	a0,0
    8000125c:	bfc1                	j	8000122c <uvmalloc+0x7c>
    return oldsz;
    8000125e:	852e                	mv	a0,a1
}
    80001260:	8082                	ret
  return newsz;
    80001262:	8532                	mv	a0,a2
    80001264:	b7e1                	j	8000122c <uvmalloc+0x7c>

0000000080001266 <uvm_copyin>:
// 成功返回0，失败返回-1
int uvm_copyin(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001266:	cebd                	beqz	a3,800012e4 <uvm_copyin+0x7e>
{
    80001268:	711d                	add	sp,sp,-96
    8000126a:	ec86                	sd	ra,88(sp)
    8000126c:	e8a2                	sd	s0,80(sp)
    8000126e:	e4a6                	sd	s1,72(sp)
    80001270:	e0ca                	sd	s2,64(sp)
    80001272:	fc4e                	sd	s3,56(sp)
    80001274:	f852                	sd	s4,48(sp)
    80001276:	f456                	sd	s5,40(sp)
    80001278:	f05a                	sd	s6,32(sp)
    8000127a:	ec5e                	sd	s7,24(sp)
    8000127c:	e862                	sd	s8,16(sp)
    8000127e:	e466                	sd	s9,8(sp)
    80001280:	e06a                	sd	s10,0(sp)
    80001282:	1080                	add	s0,sp,96
    80001284:	8b2a                	mv	s6,a0
    80001286:	89ae                	mv	s3,a1
    80001288:	84b2                	mv	s1,a2
    8000128a:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(srcva);
    8000128c:	7bfd                	lui	s7,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    8000128e:	6a85                	lui	s5,0x1
    80001290:	fffa8c13          	add	s8,s5,-1 # fff <_entry-0x7ffff001>
    80001294:	a015                	j	800012b8 <uvm_copyin+0x52>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove((void *)dst, (void *)(page_pa + src_offset), bytes_to_copy);
    80001296:	000c8d1b          	sext.w	s10,s9
    8000129a:	866a                	mv	a2,s10
    8000129c:	009505b3          	add	a1,a0,s1
    800012a0:	854e                	mv	a0,s3
    800012a2:	fffff097          	auipc	ra,0xfffff
    800012a6:	2dc080e7          	jalr	732(ra) # 8000057e <memmove>

    len -= bytes_to_copy;
    800012aa:	41a9093b          	subw	s2,s2,s10
    dst += bytes_to_copy;
    800012ae:	99e6                	add	s3,s3,s9
    srcva = page_va + PGSIZE; // 移到下一页
    800012b0:	015a04b3          	add	s1,s4,s5
  while (len > 0)
    800012b4:	02090663          	beqz	s2,800012e0 <uvm_copyin+0x7a>
    page_va = PGROUNDDOWN(srcva);
    800012b8:	0174fa33          	and	s4,s1,s7
    page_pa = walkaddr(pgtbl, page_va);
    800012bc:	85d2                	mv	a1,s4
    800012be:	855a                	mv	a0,s6
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	b20080e7          	jalr	-1248(ra) # 80000de0 <walkaddr>
    if (page_pa == 0)
    800012c8:	c105                	beqz	a0,800012e8 <uvm_copyin+0x82>
  uint64 page_offset = va - PGROUNDDOWN(va);
    800012ca:	0184f4b3          	and	s1,s1,s8
    bytes_to_copy = bytes_to_copy_in_page(srcva, len);
    800012ce:	02091793          	sll	a5,s2,0x20
    800012d2:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    800012d4:	409a8cb3          	sub	s9,s5,s1
    800012d8:	fb97ffe3          	bgeu	a5,s9,80001296 <uvm_copyin+0x30>
    800012dc:	8cbe                	mv	s9,a5
    800012de:	bf65                	j	80001296 <uvm_copyin+0x30>
  }
  return 0;
    800012e0:	4501                	li	a0,0
    800012e2:	a021                	j	800012ea <uvm_copyin+0x84>
    800012e4:	4501                	li	a0,0
}
    800012e6:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    800012e8:	557d                	li	a0,-1
}
    800012ea:	60e6                	ld	ra,88(sp)
    800012ec:	6446                	ld	s0,80(sp)
    800012ee:	64a6                	ld	s1,72(sp)
    800012f0:	6906                	ld	s2,64(sp)
    800012f2:	79e2                	ld	s3,56(sp)
    800012f4:	7a42                	ld	s4,48(sp)
    800012f6:	7aa2                	ld	s5,40(sp)
    800012f8:	7b02                	ld	s6,32(sp)
    800012fa:	6be2                	ld	s7,24(sp)
    800012fc:	6c42                	ld	s8,16(sp)
    800012fe:	6ca2                	ld	s9,8(sp)
    80001300:	6d02                	ld	s10,0(sp)
    80001302:	6125                	add	sp,sp,96
    80001304:	8082                	ret

0000000080001306 <uvm_copyout>:
// 成功返回0，失败返回-1
int uvm_copyout(pgtbl_t pgtbl, uint64 dstva, uint64 src, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001306:	ceb5                	beqz	a3,80001382 <uvm_copyout+0x7c>
{
    80001308:	711d                	add	sp,sp,-96
    8000130a:	ec86                	sd	ra,88(sp)
    8000130c:	e8a2                	sd	s0,80(sp)
    8000130e:	e4a6                	sd	s1,72(sp)
    80001310:	e0ca                	sd	s2,64(sp)
    80001312:	fc4e                	sd	s3,56(sp)
    80001314:	f852                	sd	s4,48(sp)
    80001316:	f456                	sd	s5,40(sp)
    80001318:	f05a                	sd	s6,32(sp)
    8000131a:	ec5e                	sd	s7,24(sp)
    8000131c:	e862                	sd	s8,16(sp)
    8000131e:	e466                	sd	s9,8(sp)
    80001320:	e06a                	sd	s10,0(sp)
    80001322:	1080                	add	s0,sp,96
    80001324:	8baa                	mv	s7,a0
    80001326:	84ae                	mv	s1,a1
    80001328:	89b2                	mv	s3,a2
    8000132a:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(dstva);
    8000132c:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    8000132e:	6b05                	lui	s6,0x1
    80001330:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    80001334:	a00d                	j	80001356 <uvm_copyout+0x50>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), (void *)src, bytes_to_copy);
    80001336:	000d0a9b          	sext.w	s5,s10
    8000133a:	8656                	mv	a2,s5
    8000133c:	85ce                	mv	a1,s3
    8000133e:	9526                	add	a0,a0,s1
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	23e080e7          	jalr	574(ra) # 8000057e <memmove>

    len -= bytes_to_copy;
    80001348:	4159093b          	subw	s2,s2,s5
    src += bytes_to_copy;
    8000134c:	99ea                	add	s3,s3,s10
    dstva = page_va + PGSIZE; // 移到下一页
    8000134e:	016a04b3          	add	s1,s4,s6
  while (len > 0)
    80001352:	02090663          	beqz	s2,8000137e <uvm_copyout+0x78>
    page_va = PGROUNDDOWN(dstva);
    80001356:	0184fa33          	and	s4,s1,s8
    page_pa = walkaddr(pgtbl, page_va);
    8000135a:	85d2                	mv	a1,s4
    8000135c:	855e                	mv	a0,s7
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	a82080e7          	jalr	-1406(ra) # 80000de0 <walkaddr>
    if (page_pa == 0)
    80001366:	c105                	beqz	a0,80001386 <uvm_copyout+0x80>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001368:	0194f4b3          	and	s1,s1,s9
    bytes_to_copy = bytes_to_copy_in_page(dstva, len);
    8000136c:	02091793          	sll	a5,s2,0x20
    80001370:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001372:	409b0d33          	sub	s10,s6,s1
    80001376:	fda7f0e3          	bgeu	a5,s10,80001336 <uvm_copyout+0x30>
    8000137a:	8d3e                	mv	s10,a5
    8000137c:	bf6d                	j	80001336 <uvm_copyout+0x30>
  }
  return 0;
    8000137e:	4501                	li	a0,0
    80001380:	a021                	j	80001388 <uvm_copyout+0x82>
    80001382:	4501                	li	a0,0
}
    80001384:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001386:	557d                	li	a0,-1
}
    80001388:	60e6                	ld	ra,88(sp)
    8000138a:	6446                	ld	s0,80(sp)
    8000138c:	64a6                	ld	s1,72(sp)
    8000138e:	6906                	ld	s2,64(sp)
    80001390:	79e2                	ld	s3,56(sp)
    80001392:	7a42                	ld	s4,48(sp)
    80001394:	7aa2                	ld	s5,40(sp)
    80001396:	7b02                	ld	s6,32(sp)
    80001398:	6be2                	ld	s7,24(sp)
    8000139a:	6c42                	ld	s8,16(sp)
    8000139c:	6ca2                	ld	s9,8(sp)
    8000139e:	6d02                	ld	s10,0(sp)
    800013a0:	6125                	add	sp,sp,96
    800013a2:	8082                	ret

00000000800013a4 <uvm_copyin_str>:
int uvm_copyin_str(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 maxlen)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && maxlen > 0)
    800013a4:	c6dd                	beqz	a3,80001452 <uvm_copyin_str+0xae>
{
    800013a6:	715d                	add	sp,sp,-80
    800013a8:	e486                	sd	ra,72(sp)
    800013aa:	e0a2                	sd	s0,64(sp)
    800013ac:	fc26                	sd	s1,56(sp)
    800013ae:	f84a                	sd	s2,48(sp)
    800013b0:	f44e                	sd	s3,40(sp)
    800013b2:	f052                	sd	s4,32(sp)
    800013b4:	ec56                	sd	s5,24(sp)
    800013b6:	e85a                	sd	s6,16(sp)
    800013b8:	e45e                	sd	s7,8(sp)
    800013ba:	0880                	add	s0,sp,80
    800013bc:	8aaa                	mv	s5,a0
    800013be:	89ae                	mv	s3,a1
    800013c0:	8bb2                	mv	s7,a2
    800013c2:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800013c4:	7b7d                	lui	s6,0xfffff
    pa0 = walkaddr(pgtbl, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800013c6:	6a05                	lui	s4,0x1
    800013c8:	a02d                	j	800013f2 <uvm_copyin_str+0x4e>
        *(char*)dst = *p;
      }
      --n;
      --maxlen;
      p++;
      dst++;
    800013ca:	87ba                	mv	a5,a4
      if (*p == '\0')
    800013cc:	00f60733          	add	a4,a2,a5
    800013d0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffeea50>
    800013d4:	cb31                	beqz	a4,80001428 <uvm_copyin_str+0x84>
        *(char*)dst = *p;
    800013d6:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      dst++;
    800013da:	00178713          	add	a4,a5,1
    while (n > 0)
    800013de:	fee696e3          	bne	a3,a4,800013ca <uvm_copyin_str+0x26>
    800013e2:	34fd                	addw	s1,s1,-1
    800013e4:	013484bb          	addw	s1,s1,s3
      --maxlen;
    800013e8:	9c9d                	subw	s1,s1,a5
      dst++;
    800013ea:	89ba                	mv	s3,a4
    }

    srcva = va0 + PGSIZE;
    800013ec:	01490bb3          	add	s7,s2,s4
  while (got_null == 0 && maxlen > 0)
    800013f0:	cca9                	beqz	s1,8000144a <uvm_copyin_str+0xa6>
    va0 = PGROUNDDOWN(srcva);
    800013f2:	016bf933          	and	s2,s7,s6
    pa0 = walkaddr(pgtbl, va0);
    800013f6:	85ca                	mv	a1,s2
    800013f8:	8556                	mv	a0,s5
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	9e6080e7          	jalr	-1562(ra) # 80000de0 <walkaddr>
    if (pa0 == 0)
    80001402:	c531                	beqz	a0,8000144e <uvm_copyin_str+0xaa>
    n = PGSIZE - (srcva - va0);
    80001404:	417906b3          	sub	a3,s2,s7
    if (n > maxlen)
    80001408:	02049793          	sll	a5,s1,0x20
    8000140c:	9381                	srl	a5,a5,0x20
    8000140e:	96d2                	add	a3,a3,s4
    80001410:	00d7f363          	bgeu	a5,a3,80001416 <uvm_copyin_str+0x72>
    80001414:	86be                	mv	a3,a5
    char *p = (char *)(pa0 + (srcva - va0));
    80001416:	955e                	add	a0,a0,s7
    80001418:	41250533          	sub	a0,a0,s2
    while (n > 0)
    8000141c:	dae1                	beqz	a3,800013ec <uvm_copyin_str+0x48>
    8000141e:	87ce                	mv	a5,s3
      if (*p == '\0')
    80001420:	41350633          	sub	a2,a0,s3
    while (n > 0)
    80001424:	96ce                	add	a3,a3,s3
    80001426:	b75d                	j	800013cc <uvm_copyin_str+0x28>
        *(char*)dst = '\0';
    80001428:	00078023          	sb	zero,0(a5)
    8000142c:	4785                	li	a5,1
  }
  if (got_null)
    8000142e:	37fd                	addw	a5,a5,-1
    80001430:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001434:	60a6                	ld	ra,72(sp)
    80001436:	6406                	ld	s0,64(sp)
    80001438:	74e2                	ld	s1,56(sp)
    8000143a:	7942                	ld	s2,48(sp)
    8000143c:	79a2                	ld	s3,40(sp)
    8000143e:	7a02                	ld	s4,32(sp)
    80001440:	6ae2                	ld	s5,24(sp)
    80001442:	6b42                	ld	s6,16(sp)
    80001444:	6ba2                	ld	s7,8(sp)
    80001446:	6161                	add	sp,sp,80
    80001448:	8082                	ret
    8000144a:	4781                	li	a5,0
    8000144c:	b7cd                	j	8000142e <uvm_copyin_str+0x8a>
      return -1;
    8000144e:	557d                	li	a0,-1
    80001450:	b7d5                	j	80001434 <uvm_copyin_str+0x90>
  int got_null = 0;
    80001452:	4781                	li	a5,0
  if (got_null)
    80001454:	37fd                	addw	a5,a5,-1
    80001456:	0007851b          	sext.w	a0,a5
}
    8000145a:	8082                	ret

000000008000145c <uvmfree>:
  return PGROUNDUP(size) / PGSIZE;
}

// 释放用户内存页面，然后释放页表页面
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000145c:	1101                	add	sp,sp,-32
    8000145e:	ec06                	sd	ra,24(sp)
    80001460:	e822                	sd	s0,16(sp)
    80001462:	e426                	sd	s1,8(sp)
    80001464:	1000                	add	s0,sp,32
    80001466:	84aa                	mv	s1,a0
  if (sz > 0)
    80001468:	e999                	bnez	a1,8000147e <uvmfree+0x22>
  {
    uint64 npages = calculate_pages_needed(sz);
    uvmunmap(pagetable, 0, npages, 1);
  }
  freewalk(pagetable);
    8000146a:	8526                	mv	a0,s1
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	9b4080e7          	jalr	-1612(ra) # 80000e20 <freewalk>
    80001474:	60e2                	ld	ra,24(sp)
    80001476:	6442                	ld	s0,16(sp)
    80001478:	64a2                	ld	s1,8(sp)
    8000147a:	6105                	add	sp,sp,32
    8000147c:	8082                	ret
  return PGROUNDUP(size) / PGSIZE;
    8000147e:	6785                	lui	a5,0x1
    80001480:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001482:	95be                	add	a1,a1,a5
    uvmunmap(pagetable, 0, npages, 1);
    80001484:	4685                	li	a3,1
    80001486:	00c5d613          	srl	a2,a1,0xc
    8000148a:	4581                	li	a1,0
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	c14080e7          	jalr	-1004(ra) # 800010a0 <uvmunmap>
    80001494:	bfd9                	j	8000146a <uvmfree+0xe>

0000000080001496 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001496:	1141                	add	sp,sp,-16
    80001498:	e422                	sd	s0,8(sp)
    8000149a:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000149c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000149e:	2501                	sext.w	a0,a0
    800014a0:	6422                	ld	s0,8(sp)
    800014a2:	0141                	add	sp,sp,16
    800014a4:	8082                	ret

00000000800014a6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800014a6:	1141                	add	sp,sp,-16
    800014a8:	e422                	sd	s0,8(sp)
    800014aa:	0800                	add	s0,sp,16
    800014ac:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800014ae:	2781                	sext.w	a5,a5
    800014b0:	079e                	sll	a5,a5,0x7
  return c;
}
    800014b2:	0000b517          	auipc	a0,0xb
    800014b6:	4ce50513          	add	a0,a0,1230 # 8000c980 <cpus>
    800014ba:	953e                	add	a0,a0,a5
    800014bc:	6422                	ld	s0,8(sp)
    800014be:	0141                	add	sp,sp,16
    800014c0:	8082                	ret

00000000800014c2 <myproc>:


proc_t* myproc(void)
{
    800014c2:	1101                	add	sp,sp,-32
    800014c4:	ec06                	sd	ra,24(sp)
    800014c6:	e822                	sd	s0,16(sp)
    800014c8:	e426                	sd	s1,8(sp)
    800014ca:	1000                	add	s0,sp,32
  push_off();
    800014cc:	00001097          	auipc	ra,0x1
    800014d0:	b0c080e7          	jalr	-1268(ra) # 80001fd8 <push_off>
    800014d4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800014d6:	2781                	sext.w	a5,a5
    800014d8:	079e                	sll	a5,a5,0x7
    800014da:	0000b717          	auipc	a4,0xb
    800014de:	4a670713          	add	a4,a4,1190 # 8000c980 <cpus>
    800014e2:	97ba                	add	a5,a5,a4
    800014e4:	6784                	ld	s1,8(a5)
  pop_off();
    800014e6:	00001097          	auipc	ra,0x1
    800014ea:	b92080e7          	jalr	-1134(ra) # 80002078 <pop_off>
  return p;
}
    800014ee:	8526                	mv	a0,s1
    800014f0:	60e2                	ld	ra,24(sp)
    800014f2:	6442                	ld	s0,16(sp)
    800014f4:	64a2                	ld	s1,8(sp)
    800014f6:	6105                	add	sp,sp,32
    800014f8:	8082                	ret

00000000800014fa <allocpid>:

int
allocpid()
{
    800014fa:	1101                	add	sp,sp,-32
    800014fc:	ec06                	sd	ra,24(sp)
    800014fe:	e822                	sd	s0,16(sp)
    80001500:	e426                	sd	s1,8(sp)
    80001502:	e04a                	sd	s2,0(sp)
    80001504:	1000                	add	s0,sp,32
  int pid;
  
  acquire(&pid_lock);
    80001506:	0000c917          	auipc	s2,0xc
    8000150a:	87a90913          	add	s2,s2,-1926 # 8000cd80 <pid_lock>
    8000150e:	854a                	mv	a0,s2
    80001510:	00001097          	auipc	ra,0x1
    80001514:	b14080e7          	jalr	-1260(ra) # 80002024 <acquire>
  pid = nextpid;
    80001518:	00003797          	auipc	a5,0x3
    8000151c:	18878793          	add	a5,a5,392 # 800046a0 <nextpid>
    80001520:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001522:	0014871b          	addw	a4,s1,1
    80001526:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001528:	854a                	mv	a0,s2
    8000152a:	00001097          	auipc	ra,0x1
    8000152e:	bae080e7          	jalr	-1106(ra) # 800020d8 <release>

  return pid;
    80001532:	8526                	mv	a0,s1
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6902                	ld	s2,0(sp)
    8000153c:	6105                	add	sp,sp,32
    8000153e:	8082                	ret

0000000080001540 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001540:	1141                	add	sp,sp,-16
    80001542:	e406                	sd	ra,8(sp)
    80001544:	e022                	sd	s0,0(sp)
    80001546:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	f7a080e7          	jalr	-134(ra) # 800014c2 <myproc>
    80001550:	0521                	add	a0,a0,8
    80001552:	00001097          	auipc	ra,0x1
    80001556:	b86080e7          	jalr	-1146(ra) # 800020d8 <release>

  if (first) {
    8000155a:	00003797          	auipc	a5,0x3
    8000155e:	14a7a783          	lw	a5,330(a5) # 800046a4 <first.0>
    80001562:	c789                	beqz	a5,8000156c <forkret+0x2c>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    80001564:	00003797          	auipc	a5,0x3
    80001568:	1407a023          	sw	zero,320(a5) # 800046a4 <first.0>
    // fsinit(ROOTDEV); //初始化文件系统//TODO
  }

  trap_user_return();
    8000156c:	00001097          	auipc	ra,0x1
    80001570:	ed4080e7          	jalr	-300(ra) # 80002440 <trap_user_return>
}
    80001574:	60a2                	ld	ra,8(sp)
    80001576:	6402                	ld	s0,0(sp)
    80001578:	0141                	add	sp,sp,16
    8000157a:	8082                	ret

000000008000157c <proc_mapstacks>:
{
    8000157c:	7139                	add	sp,sp,-64
    8000157e:	fc06                	sd	ra,56(sp)
    80001580:	f822                	sd	s0,48(sp)
    80001582:	f426                	sd	s1,40(sp)
    80001584:	f04a                	sd	s2,32(sp)
    80001586:	ec4e                	sd	s3,24(sp)
    80001588:	e852                	sd	s4,16(sp)
    8000158a:	e456                	sd	s5,8(sp)
    8000158c:	e05a                	sd	s6,0(sp)
    8000158e:	0080                	add	s0,sp,64
    80001590:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001592:	0000c497          	auipc	s1,0xc
    80001596:	80648493          	add	s1,s1,-2042 # 8000cd98 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000159a:	8b26                	mv	s6,s1
    8000159c:	00003a97          	auipc	s5,0x3
    800015a0:	a64a8a93          	add	s5,s5,-1436 # 80004000 <etext>
    800015a4:	04000937          	lui	s2,0x4000
    800015a8:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800015aa:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800015ac:	0000fa17          	auipc	s4,0xf
    800015b0:	feca0a13          	add	s4,s4,-20 # 80010598 <wait_lock>
    char *pa = kalloc(1);
    800015b4:	4505                	li	a0,1
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	510080e7          	jalr	1296(ra) # 80000ac6 <kalloc>
    800015be:	862a                	mv	a2,a0
    if(pa == 0)
    800015c0:	c131                	beqz	a0,80001604 <proc_mapstacks+0x88>
    uint64 va = KSTACK((int) (p - proc));
    800015c2:	416485b3          	sub	a1,s1,s6
    800015c6:	8595                	sra	a1,a1,0x5
    800015c8:	000ab783          	ld	a5,0(s5)
    800015cc:	02f585b3          	mul	a1,a1,a5
    800015d0:	2585                	addw	a1,a1,1
    800015d2:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800015d6:	4719                	li	a4,6
    800015d8:	6685                	lui	a3,0x1
    800015da:	40b905b3          	sub	a1,s2,a1
    800015de:	854e                	mv	a0,s3
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	6d8080e7          	jalr	1752(ra) # 80000cb8 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800015e8:	0e048493          	add	s1,s1,224
    800015ec:	fd4494e3          	bne	s1,s4,800015b4 <proc_mapstacks+0x38>
}
    800015f0:	70e2                	ld	ra,56(sp)
    800015f2:	7442                	ld	s0,48(sp)
    800015f4:	74a2                	ld	s1,40(sp)
    800015f6:	7902                	ld	s2,32(sp)
    800015f8:	69e2                	ld	s3,24(sp)
    800015fa:	6a42                	ld	s4,16(sp)
    800015fc:	6aa2                	ld	s5,8(sp)
    800015fe:	6b02                	ld	s6,0(sp)
    80001600:	6121                	add	sp,sp,64
    80001602:	8082                	ret
      panic("kalloc");
    80001604:	00003517          	auipc	a0,0x3
    80001608:	c5450513          	add	a0,a0,-940 # 80004258 <digits+0x1d8>
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	15e080e7          	jalr	350(ra) # 8000076a <panic>

0000000080001614 <procinit>:
{
    80001614:	7139                	add	sp,sp,-64
    80001616:	fc06                	sd	ra,56(sp)
    80001618:	f822                	sd	s0,48(sp)
    8000161a:	f426                	sd	s1,40(sp)
    8000161c:	f04a                	sd	s2,32(sp)
    8000161e:	ec4e                	sd	s3,24(sp)
    80001620:	e852                	sd	s4,16(sp)
    80001622:	e456                	sd	s5,8(sp)
    80001624:	e05a                	sd	s6,0(sp)
    80001626:	0080                	add	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001628:	00003597          	auipc	a1,0x3
    8000162c:	c3858593          	add	a1,a1,-968 # 80004260 <digits+0x1e0>
    80001630:	0000b517          	auipc	a0,0xb
    80001634:	75050513          	add	a0,a0,1872 # 8000cd80 <pid_lock>
    80001638:	00001097          	auipc	ra,0x1
    8000163c:	95c080e7          	jalr	-1700(ra) # 80001f94 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001640:	00003597          	auipc	a1,0x3
    80001644:	c2858593          	add	a1,a1,-984 # 80004268 <digits+0x1e8>
    80001648:	0000f517          	auipc	a0,0xf
    8000164c:	f5050513          	add	a0,a0,-176 # 80010598 <wait_lock>
    80001650:	00001097          	auipc	ra,0x1
    80001654:	944080e7          	jalr	-1724(ra) # 80001f94 <initlock>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001658:	0000b497          	auipc	s1,0xb
    8000165c:	74048493          	add	s1,s1,1856 # 8000cd98 <proc>
      initlock(&p->lock, "proc");
    80001660:	00003b17          	auipc	s6,0x3
    80001664:	c18b0b13          	add	s6,s6,-1000 # 80004278 <digits+0x1f8>
      p->kstack = KSTACK((int) (p - proc));
    80001668:	8aa6                	mv	s5,s1
    8000166a:	00003a17          	auipc	s4,0x3
    8000166e:	996a0a13          	add	s4,s4,-1642 # 80004000 <etext>
    80001672:	04000937          	lui	s2,0x4000
    80001676:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001678:	0932                	sll	s2,s2,0xc
    for(p = proc; p < &proc[NPROC]; p++) {
    8000167a:	0000f997          	auipc	s3,0xf
    8000167e:	f1e98993          	add	s3,s3,-226 # 80010598 <wait_lock>
      initlock(&p->lock, "proc");
    80001682:	85da                	mv	a1,s6
    80001684:	00848513          	add	a0,s1,8
    80001688:	00001097          	auipc	ra,0x1
    8000168c:	90c080e7          	jalr	-1780(ra) # 80001f94 <initlock>
      p->state = UNUSED;
    80001690:	0204a023          	sw	zero,32(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001694:	415487b3          	sub	a5,s1,s5
    80001698:	8795                	sra	a5,a5,0x5
    8000169a:	000a3703          	ld	a4,0(s4)
    8000169e:	02e787b3          	mul	a5,a5,a4
    800016a2:	2785                	addw	a5,a5,1
    800016a4:	00d7979b          	sllw	a5,a5,0xd
    800016a8:	40f907b3          	sub	a5,s2,a5
    800016ac:	f4bc                	sd	a5,104(s1)
    for(p = proc; p < &proc[NPROC]; p++) {
    800016ae:	0e048493          	add	s1,s1,224
    800016b2:	fd3498e3          	bne	s1,s3,80001682 <procinit+0x6e>
}
    800016b6:	70e2                	ld	ra,56(sp)
    800016b8:	7442                	ld	s0,48(sp)
    800016ba:	74a2                	ld	s1,40(sp)
    800016bc:	7902                	ld	s2,32(sp)
    800016be:	69e2                	ld	s3,24(sp)
    800016c0:	6a42                	ld	s4,16(sp)
    800016c2:	6aa2                	ld	s5,8(sp)
    800016c4:	6b02                	ld	s6,0(sp)
    800016c6:	6121                	add	sp,sp,64
    800016c8:	8082                	ret

00000000800016ca <proc_freepagetable>:

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    800016ca:	1101                	add	sp,sp,-32
    800016cc:	ec06                	sd	ra,24(sp)
    800016ce:	e822                	sd	s0,16(sp)
    800016d0:	e426                	sd	s1,8(sp)
    800016d2:	e04a                	sd	s2,0(sp)
    800016d4:	1000                	add	s0,sp,32
    800016d6:	84aa                	mv	s1,a0
    800016d8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0); 
    800016da:	4681                	li	a3,0
    800016dc:	4605                	li	a2,1
    800016de:	040005b7          	lui	a1,0x4000
    800016e2:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800016e4:	05b2                	sll	a1,a1,0xc
    800016e6:	00000097          	auipc	ra,0x0
    800016ea:	9ba080e7          	jalr	-1606(ra) # 800010a0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800016ee:	4681                	li	a3,0
    800016f0:	4605                	li	a2,1
    800016f2:	020005b7          	lui	a1,0x2000
    800016f6:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800016f8:	05b6                	sll	a1,a1,0xd
    800016fa:	8526                	mv	a0,s1
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	9a4080e7          	jalr	-1628(ra) # 800010a0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001704:	85ca                	mv	a1,s2
    80001706:	8526                	mv	a0,s1
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	d54080e7          	jalr	-684(ra) # 8000145c <uvmfree>
}
    80001710:	60e2                	ld	ra,24(sp)
    80001712:	6442                	ld	s0,16(sp)
    80001714:	64a2                	ld	s1,8(sp)
    80001716:	6902                	ld	s2,0(sp)
    80001718:	6105                	add	sp,sp,32
    8000171a:	8082                	ret

000000008000171c <freeproc>:

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
void freeproc(struct proc *p)
{
    8000171c:	1101                	add	sp,sp,-32
    8000171e:	ec06                	sd	ra,24(sp)
    80001720:	e822                	sd	s0,16(sp)
    80001722:	e426                	sd	s1,8(sp)
    80001724:	1000                	add	s0,sp,32
    80001726:	84aa                	mv	s1,a0
  if(p->tf)
    80001728:	6d28                	ld	a0,88(a0)
    8000172a:	c511                	beqz	a0,80001736 <freeproc+0x1a>
    kfree((uint64)p->tf,1);
    8000172c:	4585                	li	a1,1
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	298080e7          	jalr	664(ra) # 800009c6 <kfree>
  p->tf = 0;
    80001736:	0404bc23          	sd	zero,88(s1)
  if(p->pgtbl)
    8000173a:	64a8                	ld	a0,72(s1)
    8000173c:	c511                	beqz	a0,80001748 <freeproc+0x2c>
    proc_freepagetable(p->pgtbl, p->sz);
    8000173e:	70ac                	ld	a1,96(s1)
    80001740:	00000097          	auipc	ra,0x0
    80001744:	f8a080e7          	jalr	-118(ra) # 800016ca <proc_freepagetable>

  p->pgtbl = 0;
    80001748:	0404b423          	sd	zero,72(s1)
  p->parent = 0;
    8000174c:	0204b423          	sd	zero,40(s1)
  p->chan = 0;
    80001750:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001754:	0204ac23          	sw	zero,56(s1)
  p->exit_state = 0;
    80001758:	0204ae23          	sw	zero,60(s1)
  p->sleep_space = 0;
    8000175c:	0404b023          	sd	zero,64(s1)
  p->ustack_pages = 0;
    80001760:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001764:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001768:	0004a023          	sw	zero,0(s1)
  
  memset(&p->ctx, 0, sizeof(p->ctx));
    8000176c:	07000613          	li	a2,112
    80001770:	4581                	li	a1,0
    80001772:	07048513          	add	a0,s1,112
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	dac080e7          	jalr	-596(ra) # 80000522 <memset>

  p->state = UNUSED;
    8000177e:	0204a023          	sw	zero,32(s1)
}
    80001782:	60e2                	ld	ra,24(sp)
    80001784:	6442                	ld	s0,16(sp)
    80001786:	64a2                	ld	s1,8(sp)
    80001788:	6105                	add	sp,sp,32
    8000178a:	8082                	ret

000000008000178c <proc_pgtbl_init>:

// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
    8000178c:	1101                	add	sp,sp,-32
    8000178e:	ec06                	sd	ra,24(sp)
    80001790:	e822                	sd	s0,16(sp)
    80001792:	e426                	sd	s1,8(sp)
    80001794:	e04a                	sd	s2,0(sp)
    80001796:	1000                	add	s0,sp,32
    80001798:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    8000179a:	00000097          	auipc	ra,0x0
    8000179e:	862080e7          	jalr	-1950(ra) # 80000ffc <uvmcreate>
    800017a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800017a4:	cd1d                	beqz	a0,800017e2 <proc_pgtbl_init+0x56>
    return 0;

  
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800017a6:	4729                	li	a4,10
    800017a8:	00002697          	auipc	a3,0x2
    800017ac:	85868693          	add	a3,a3,-1960 # 80003000 <_trampoline>
    800017b0:	6605                	lui	a2,0x1
    800017b2:	040005b7          	lui	a1,0x4000
    800017b6:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800017b8:	05b2                	sll	a1,a1,0xc
    800017ba:	fffff097          	auipc	ra,0xfffff
    800017be:	43a080e7          	jalr	1082(ra) # 80000bf4 <mappages>
    800017c2:	02054763          	bltz	a0,800017f0 <proc_pgtbl_init+0x64>
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800017c6:	4719                	li	a4,6
    800017c8:	86ca                	mv	a3,s2
    800017ca:	6605                	lui	a2,0x1
    800017cc:	020005b7          	lui	a1,0x2000
    800017d0:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800017d2:	05b6                	sll	a1,a1,0xd
    800017d4:	8526                	mv	a0,s1
    800017d6:	fffff097          	auipc	ra,0xfffff
    800017da:	41e080e7          	jalr	1054(ra) # 80000bf4 <mappages>
    800017de:	02054163          	bltz	a0,80001800 <proc_pgtbl_init+0x74>
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}
    800017e2:	8526                	mv	a0,s1
    800017e4:	60e2                	ld	ra,24(sp)
    800017e6:	6442                	ld	s0,16(sp)
    800017e8:	64a2                	ld	s1,8(sp)
    800017ea:	6902                	ld	s2,0(sp)
    800017ec:	6105                	add	sp,sp,32
    800017ee:	8082                	ret
    panic("proc_pgtbl_init: mappages trampoline failed");
    800017f0:	00003517          	auipc	a0,0x3
    800017f4:	a9050513          	add	a0,a0,-1392 # 80004280 <digits+0x200>
    800017f8:	fffff097          	auipc	ra,0xfffff
    800017fc:	f72080e7          	jalr	-142(ra) # 8000076a <panic>
    panic("proc_pgtbl_init: mappages trapframe failed");
    80001800:	00003517          	auipc	a0,0x3
    80001804:	ab050513          	add	a0,a0,-1360 # 800042b0 <digits+0x230>
    80001808:	fffff097          	auipc	ra,0xfffff
    8000180c:	f62080e7          	jalr	-158(ra) # 8000076a <panic>

0000000080001810 <allocproc>:
{
    80001810:	7179                	add	sp,sp,-48
    80001812:	f406                	sd	ra,40(sp)
    80001814:	f022                	sd	s0,32(sp)
    80001816:	ec26                	sd	s1,24(sp)
    80001818:	e84a                	sd	s2,16(sp)
    8000181a:	e44e                	sd	s3,8(sp)
    8000181c:	1800                	add	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    8000181e:	0000b497          	auipc	s1,0xb
    80001822:	57a48493          	add	s1,s1,1402 # 8000cd98 <proc>
    80001826:	0000f997          	auipc	s3,0xf
    8000182a:	d7298993          	add	s3,s3,-654 # 80010598 <wait_lock>
    acquire(&p->lock);
    8000182e:	00848913          	add	s2,s1,8
    80001832:	854a                	mv	a0,s2
    80001834:	00000097          	auipc	ra,0x0
    80001838:	7f0080e7          	jalr	2032(ra) # 80002024 <acquire>
    if(p->state == UNUSED) {
    8000183c:	509c                	lw	a5,32(s1)
    8000183e:	cf81                	beqz	a5,80001856 <allocproc+0x46>
      release(&p->lock);
    80001840:	854a                	mv	a0,s2
    80001842:	00001097          	auipc	ra,0x1
    80001846:	896080e7          	jalr	-1898(ra) # 800020d8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184a:	0e048493          	add	s1,s1,224
    8000184e:	ff3490e3          	bne	s1,s3,8000182e <allocproc+0x1e>
  return 0;
    80001852:	4481                	li	s1,0
    80001854:	a899                	j	800018aa <allocproc+0x9a>
  p->pid = allocpid();
    80001856:	00000097          	auipc	ra,0x0
    8000185a:	ca4080e7          	jalr	-860(ra) # 800014fa <allocpid>
    8000185e:	c088                	sw	a0,0(s1)
  p->state = USED;
    80001860:	4785                	li	a5,1
    80001862:	d09c                	sw	a5,32(s1)
  p->sz=4096;
    80001864:	6785                	lui	a5,0x1
    80001866:	f0bc                	sd	a5,96(s1)
  if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    80001868:	4505                	li	a0,1
    8000186a:	fffff097          	auipc	ra,0xfffff
    8000186e:	25c080e7          	jalr	604(ra) # 80000ac6 <kalloc>
    80001872:	89aa                	mv	s3,a0
    80001874:	eca8                	sd	a0,88(s1)
    80001876:	c131                	beqz	a0,800018ba <allocproc+0xaa>
  p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    80001878:	00000097          	auipc	ra,0x0
    8000187c:	f14080e7          	jalr	-236(ra) # 8000178c <proc_pgtbl_init>
    80001880:	89aa                	mv	s3,a0
    80001882:	e4a8                	sd	a0,72(s1)
  if(p->pgtbl == 0){ 
    80001884:	cd39                	beqz	a0,800018e2 <allocproc+0xd2>
  memset(&p->ctx, 0, sizeof(p->ctx));
    80001886:	07000613          	li	a2,112
    8000188a:	4581                	li	a1,0
    8000188c:	07048513          	add	a0,s1,112
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	c92080e7          	jalr	-878(ra) # 80000522 <memset>
  p->ctx.ra = (uint64)forkret;
    80001898:	00000797          	auipc	a5,0x0
    8000189c:	ca878793          	add	a5,a5,-856 # 80001540 <forkret>
    800018a0:	f8bc                	sd	a5,112(s1)
  p->ctx.sp = p->kstack+PGSIZE;
    800018a2:	74bc                	ld	a5,104(s1)
    800018a4:	6705                	lui	a4,0x1
    800018a6:	97ba                	add	a5,a5,a4
    800018a8:	fcbc                	sd	a5,120(s1)
}
    800018aa:	8526                	mv	a0,s1
    800018ac:	70a2                	ld	ra,40(sp)
    800018ae:	7402                	ld	s0,32(sp)
    800018b0:	64e2                	ld	s1,24(sp)
    800018b2:	6942                	ld	s2,16(sp)
    800018b4:	69a2                	ld	s3,8(sp)
    800018b6:	6145                	add	sp,sp,48
    800018b8:	8082                	ret
    freeproc(p);
    800018ba:	8526                	mv	a0,s1
    800018bc:	00000097          	auipc	ra,0x0
    800018c0:	e60080e7          	jalr	-416(ra) # 8000171c <freeproc>
    printf("allocproc: kalloc trapframe failed\n");
    800018c4:	00003517          	auipc	a0,0x3
    800018c8:	a1c50513          	add	a0,a0,-1508 # 800042e0 <digits+0x260>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	ee8080e7          	jalr	-280(ra) # 800007b4 <printf>
    release(&p->lock);
    800018d4:	854a                	mv	a0,s2
    800018d6:	00001097          	auipc	ra,0x1
    800018da:	802080e7          	jalr	-2046(ra) # 800020d8 <release>
    return 0;
    800018de:	84ce                	mv	s1,s3
    800018e0:	b7e9                	j	800018aa <allocproc+0x9a>
    freeproc(p);
    800018e2:	8526                	mv	a0,s1
    800018e4:	00000097          	auipc	ra,0x0
    800018e8:	e38080e7          	jalr	-456(ra) # 8000171c <freeproc>
    printf("allocproc: proc_pgtbl_init failed\n");
    800018ec:	00003517          	auipc	a0,0x3
    800018f0:	a1c50513          	add	a0,a0,-1508 # 80004308 <digits+0x288>
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	ec0080e7          	jalr	-320(ra) # 800007b4 <printf>
    release(&p->lock);
    800018fc:	854a                	mv	a0,s2
    800018fe:	00000097          	auipc	ra,0x0
    80001902:	7da080e7          	jalr	2010(ra) # 800020d8 <release>
    return 0;
    80001906:	84ce                	mv	s1,s3
    80001908:	b74d                	j	800018aa <allocproc+0x9a>

000000008000190a <userinit>:
//__attribute__ ((aligned (16))) char proc0stack[8192];

// Set up first user process.
void
userinit(void)
{
    8000190a:	1101                	add	sp,sp,-32
    8000190c:	ec06                	sd	ra,24(sp)
    8000190e:	e822                	sd	s0,16(sp)
    80001910:	e426                	sd	s1,8(sp)
    80001912:	1000                	add	s0,sp,32
  struct proc *p;

  p = allocproc();
    80001914:	00000097          	auipc	ra,0x0
    80001918:	efc080e7          	jalr	-260(ra) # 80001810 <allocproc>
    8000191c:	84aa                	mv	s1,a0
  proczero = p;
    8000191e:	00003797          	auipc	a5,0x3
    80001922:	daa7bd23          	sd	a0,-582(a5) # 800046d8 <proczero>
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pgtbl, (uchar*)initcode_start, (uint64)(initcode_end - initcode_start));
    80001926:	00001597          	auipc	a1,0x1
    8000192a:	06058593          	add	a1,a1,96 # 80002986 <initcode_start>
    8000192e:	00001617          	auipc	a2,0x1
    80001932:	28f60613          	add	a2,a2,655 # 80002bbd <initcode_end>
    80001936:	9e0d                	subw	a2,a2,a1
    80001938:	6528                	ld	a0,72(a0)
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	6f2080e7          	jalr	1778(ra) # 8000102c <uvmfirst>
  p->sz = PGSIZE;
    80001942:	6785                	lui	a5,0x1
    80001944:	f0bc                	sd	a5,96(s1)

  // prepare for the very first "return" from kernel to user.
  p->tf->epc = 0;      // user program counter
    80001946:	6cb8                	ld	a4,88(s1)
    80001948:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    8000194c:	6cb8                	ld	a4,88(s1)
    8000194e:	fb1c                	sd	a5,48(a4)
  

  // safestrcpy(p->name, "initcode", sizeof(p->name));
  //p->cwd = namei("/");

  p->state = RUNNABLE;
    80001950:	478d                	li	a5,3
    80001952:	d09c                	sw	a5,32(s1)

  release(&p->lock);
    80001954:	00848513          	add	a0,s1,8
    80001958:	00000097          	auipc	ra,0x0
    8000195c:	780080e7          	jalr	1920(ra) # 800020d8 <release>
}
    80001960:	60e2                	ld	ra,24(sp)
    80001962:	6442                	ld	s0,16(sp)
    80001964:	64a2                	ld	s1,8(sp)
    80001966:	6105                	add	sp,sp,32
    80001968:	8082                	ret

000000008000196a <growproc>:

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
    8000196a:	1101                	add	sp,sp,-32
    8000196c:	ec06                	sd	ra,24(sp)
    8000196e:	e822                	sd	s0,16(sp)
    80001970:	e426                	sd	s1,8(sp)
    80001972:	e04a                	sd	s2,0(sp)
    80001974:	1000                	add	s0,sp,32
    80001976:	892a                	mv	s2,a0
  uint64 sz;
  struct proc *p = myproc();
    80001978:	00000097          	auipc	ra,0x0
    8000197c:	b4a080e7          	jalr	-1206(ra) # 800014c2 <myproc>
    80001980:	84aa                	mv	s1,a0

  sz = p->sz;
    80001982:	712c                	ld	a1,96(a0)
  if(n > 0){
    80001984:	01204c63          	bgtz	s2,8000199c <growproc+0x32>
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    80001988:	02094663          	bltz	s2,800019b4 <growproc+0x4a>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
  }
  p->sz = sz;
    8000198c:	f0ac                	sd	a1,96(s1)
  return 0;
    8000198e:	4501                	li	a0,0
}
    80001990:	60e2                	ld	ra,24(sp)
    80001992:	6442                	ld	s0,16(sp)
    80001994:	64a2                	ld	s1,8(sp)
    80001996:	6902                	ld	s2,0(sp)
    80001998:	6105                	add	sp,sp,32
    8000199a:	8082                	ret
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
    8000199c:	4691                	li	a3,4
    8000199e:	00b90633          	add	a2,s2,a1
    800019a2:	6528                	ld	a0,72(a0)
    800019a4:	00000097          	auipc	ra,0x0
    800019a8:	80c080e7          	jalr	-2036(ra) # 800011b0 <uvmalloc>
    800019ac:	85aa                	mv	a1,a0
    800019ae:	fd79                	bnez	a0,8000198c <growproc+0x22>
      return -1;
    800019b0:	557d                	li	a0,-1
    800019b2:	bff9                	j	80001990 <growproc+0x26>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
    800019b4:	00b90633          	add	a2,s2,a1
    800019b8:	6528                	ld	a0,72(a0)
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	7ae080e7          	jalr	1966(ra) # 80001168 <uvmdealloc>
    800019c2:	85aa                	mv	a1,a0
    800019c4:	b7e1                	j	8000198c <growproc+0x22>

00000000800019c6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, current_va;
  uint flags;
  char *mem;

  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    800019c6:	ca69                	beqz	a2,80001a98 <uvmcopy+0xd2>
{
    800019c8:	715d                	add	sp,sp,-80
    800019ca:	e486                	sd	ra,72(sp)
    800019cc:	e0a2                	sd	s0,64(sp)
    800019ce:	fc26                	sd	s1,56(sp)
    800019d0:	f84a                	sd	s2,48(sp)
    800019d2:	f44e                	sd	s3,40(sp)
    800019d4:	f052                	sd	s4,32(sp)
    800019d6:	ec56                	sd	s5,24(sp)
    800019d8:	e85a                	sd	s6,16(sp)
    800019da:	e45e                	sd	s7,8(sp)
    800019dc:	0880                	add	s0,sp,80
    800019de:	8b2a                	mv	s6,a0
    800019e0:	8a2e                	mv	s4,a1
    800019e2:	8ab2                	mv	s5,a2
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    800019e4:	4981                	li	s3,0
  {
    pte = walk(old, current_va, 0);
    800019e6:	4601                	li	a2,0
    800019e8:	85ce                	mv	a1,s3
    800019ea:	855a                	mv	a0,s6
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	160080e7          	jalr	352(ra) # 80000b4c <walk>
    if (pte == 0)
    800019f4:	c539                	beqz	a0,80001a42 <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");

    if (!is_pte_valid(*pte))
    800019f6:	6118                	ld	a4,0(a0)
  return (pte & PTE_V) != 0;
    800019f8:	00177793          	and	a5,a4,1
    if (!is_pte_valid(*pte))
    800019fc:	cbb9                	beqz	a5,80001a52 <uvmcopy+0x8c>
      panic("uvmcopy: page not present");

    pa = PTE2PA(*pte);
    800019fe:	00a75593          	srl	a1,a4,0xa
    80001a02:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001a06:	3ff77913          	and	s2,a4,1023
  *dest_mem = kalloc(1);
    80001a0a:	4505                	li	a0,1
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	0ba080e7          	jalr	186(ra) # 80000ac6 <kalloc>
    80001a14:	84aa                	mv	s1,a0
  if (*dest_mem == 0)
    80001a16:	cd21                	beqz	a0,80001a6e <uvmcopy+0xa8>
  memmove(*dest_mem, (char *)src_pa, PGSIZE);
    80001a18:	6605                	lui	a2,0x1
    80001a1a:	85de                	mv	a1,s7
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	b62080e7          	jalr	-1182(ra) # 8000057e <memmove>

    if (copy_physical_page(pa, &mem) != 0)
      goto err;

    if (mappages(new, current_va, PGSIZE, (uint64)mem, flags) != 0)
    80001a24:	874a                	mv	a4,s2
    80001a26:	86a6                	mv	a3,s1
    80001a28:	6605                	lui	a2,0x1
    80001a2a:	85ce                	mv	a1,s3
    80001a2c:	8552                	mv	a0,s4
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1c6080e7          	jalr	454(ra) # 80000bf4 <mappages>
    80001a36:	e515                	bnez	a0,80001a62 <uvmcopy+0x9c>
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    80001a38:	6785                	lui	a5,0x1
    80001a3a:	99be                	add	s3,s3,a5
    80001a3c:	fb59e5e3          	bltu	s3,s5,800019e6 <uvmcopy+0x20>
    80001a40:	a089                	j	80001a82 <uvmcopy+0xbc>
      panic("uvmcopy: pte should exist");
    80001a42:	00003517          	auipc	a0,0x3
    80001a46:	8ee50513          	add	a0,a0,-1810 # 80004330 <digits+0x2b0>
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	d20080e7          	jalr	-736(ra) # 8000076a <panic>
      panic("uvmcopy: page not present");
    80001a52:	00003517          	auipc	a0,0x3
    80001a56:	8fe50513          	add	a0,a0,-1794 # 80004350 <digits+0x2d0>
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	d10080e7          	jalr	-752(ra) # 8000076a <panic>
    {
      kfree((uint64)mem,1);
    80001a62:	4585                	li	a1,1
    80001a64:	8526                	mv	a0,s1
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	f60080e7          	jalr	-160(ra) # 800009c6 <kfree>
  uvmunmap(new_table, 0, npages, 1);
    80001a6e:	4685                	li	a3,1
    80001a70:	00c9d613          	srl	a2,s3,0xc
    80001a74:	4581                	li	a1,0
    80001a76:	8552                	mv	a0,s4
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	628080e7          	jalr	1576(ra) # 800010a0 <uvmunmap>
  }
  return 0;

err:
  cleanup_partial_copy(new, current_va);
  return -1;
    80001a80:	557d                	li	a0,-1
}
    80001a82:	60a6                	ld	ra,72(sp)
    80001a84:	6406                	ld	s0,64(sp)
    80001a86:	74e2                	ld	s1,56(sp)
    80001a88:	7942                	ld	s2,48(sp)
    80001a8a:	79a2                	ld	s3,40(sp)
    80001a8c:	7a02                	ld	s4,32(sp)
    80001a8e:	6ae2                	ld	s5,24(sp)
    80001a90:	6b42                	ld	s6,16(sp)
    80001a92:	6ba2                	ld	s7,8(sp)
    80001a94:	6161                	add	sp,sp,80
    80001a96:	8082                	ret
  return 0;
    80001a98:	4501                	li	a0,0
}
    80001a9a:	8082                	ret

0000000080001a9c <fork>:

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
    80001a9c:	7139                	add	sp,sp,-64
    80001a9e:	fc06                	sd	ra,56(sp)
    80001aa0:	f822                	sd	s0,48(sp)
    80001aa2:	f426                	sd	s1,40(sp)
    80001aa4:	f04a                	sd	s2,32(sp)
    80001aa6:	ec4e                	sd	s3,24(sp)
    80001aa8:	e852                	sd	s4,16(sp)
    80001aaa:	e456                	sd	s5,8(sp)
    80001aac:	0080                	add	s0,sp,64
  // int i; //TODO
  int pid;
  struct proc *np;
  struct proc *p = myproc();
    80001aae:	00000097          	auipc	ra,0x0
    80001ab2:	a14080e7          	jalr	-1516(ra) # 800014c2 <myproc>
    80001ab6:	8aaa                	mv	s5,a0

  // Allocate process.
  if((np = allocproc()) == 0){
    80001ab8:	00000097          	auipc	ra,0x0
    80001abc:	d58080e7          	jalr	-680(ra) # 80001810 <allocproc>
    80001ac0:	c569                	beqz	a0,80001b8a <fork+0xee>
    80001ac2:	84aa                	mv	s1,a0
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pgtbl, np->pgtbl, p->sz) < 0){
    80001ac4:	060ab603          	ld	a2,96(s5)
    80001ac8:	652c                	ld	a1,72(a0)
    80001aca:	048ab503          	ld	a0,72(s5)
    80001ace:	00000097          	auipc	ra,0x0
    80001ad2:	ef8080e7          	jalr	-264(ra) # 800019c6 <uvmcopy>
    80001ad6:	08054d63          	bltz	a0,80001b70 <fork+0xd4>
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
    80001ada:	060ab783          	ld	a5,96(s5)
    80001ade:	f0bc                	sd	a5,96(s1)

  // copy saved user registers.
  *(np->tf) = *(p->tf);
    80001ae0:	058ab683          	ld	a3,88(s5)
    80001ae4:	87b6                	mv	a5,a3
    80001ae6:	6cb8                	ld	a4,88(s1)
    80001ae8:	12068693          	add	a3,a3,288
    80001aec:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001af0:	6788                	ld	a0,8(a5)
    80001af2:	6b8c                	ld	a1,16(a5)
    80001af4:	6f90                	ld	a2,24(a5)
    80001af6:	01073023          	sd	a6,0(a4)
    80001afa:	e708                	sd	a0,8(a4)
    80001afc:	eb0c                	sd	a1,16(a4)
    80001afe:	ef10                	sd	a2,24(a4)
    80001b00:	02078793          	add	a5,a5,32
    80001b04:	02070713          	add	a4,a4,32
    80001b08:	fed792e3          	bne	a5,a3,80001aec <fork+0x50>

  // Cause fork to return 0 in the child.
  np->tf->a0 = 0;
    80001b0c:	6cbc                	ld	a5,88(s1)
    80001b0e:	0607b823          	sd	zero,112(a5)
  //     np->ofile[i] = filedup(p->ofile[i]);
  // np->cwd = idup(p->cwd);

  //safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;
    80001b12:	0004aa03          	lw	s4,0(s1)

  release(&np->lock);
    80001b16:	00848913          	add	s2,s1,8
    80001b1a:	854a                	mv	a0,s2
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	5bc080e7          	jalr	1468(ra) # 800020d8 <release>

  acquire(&wait_lock);
    80001b24:	0000f997          	auipc	s3,0xf
    80001b28:	a7498993          	add	s3,s3,-1420 # 80010598 <wait_lock>
    80001b2c:	854e                	mv	a0,s3
    80001b2e:	00000097          	auipc	ra,0x0
    80001b32:	4f6080e7          	jalr	1270(ra) # 80002024 <acquire>
  np->parent = p;
    80001b36:	0354b423          	sd	s5,40(s1)
  release(&wait_lock);
    80001b3a:	854e                	mv	a0,s3
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	59c080e7          	jalr	1436(ra) # 800020d8 <release>

  acquire(&np->lock);
    80001b44:	854a                	mv	a0,s2
    80001b46:	00000097          	auipc	ra,0x0
    80001b4a:	4de080e7          	jalr	1246(ra) # 80002024 <acquire>
  np->state = RUNNABLE;
    80001b4e:	478d                	li	a5,3
    80001b50:	d09c                	sw	a5,32(s1)
  release(&np->lock);
    80001b52:	854a                	mv	a0,s2
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	584080e7          	jalr	1412(ra) # 800020d8 <release>

  return pid;
}
    80001b5c:	8552                	mv	a0,s4
    80001b5e:	70e2                	ld	ra,56(sp)
    80001b60:	7442                	ld	s0,48(sp)
    80001b62:	74a2                	ld	s1,40(sp)
    80001b64:	7902                	ld	s2,32(sp)
    80001b66:	69e2                	ld	s3,24(sp)
    80001b68:	6a42                	ld	s4,16(sp)
    80001b6a:	6aa2                	ld	s5,8(sp)
    80001b6c:	6121                	add	sp,sp,64
    80001b6e:	8082                	ret
    freeproc(np);
    80001b70:	8526                	mv	a0,s1
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	baa080e7          	jalr	-1110(ra) # 8000171c <freeproc>
    release(&np->lock);
    80001b7a:	00848513          	add	a0,s1,8
    80001b7e:	00000097          	auipc	ra,0x0
    80001b82:	55a080e7          	jalr	1370(ra) # 800020d8 <release>
    return -1;
    80001b86:	5a7d                	li	s4,-1
    80001b88:	bfd1                	j	80001b5c <fork+0xc0>
    return -1;
    80001b8a:	5a7d                	li	s4,-1
    80001b8c:	bfc1                	j	80001b5c <fork+0xc0>

0000000080001b8e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001b8e:	7179                	add	sp,sp,-48
    80001b90:	f406                	sd	ra,40(sp)
    80001b92:	f022                	sd	s0,32(sp)
    80001b94:	ec26                	sd	s1,24(sp)
    80001b96:	e84a                	sd	s2,16(sp)
    80001b98:	e44e                	sd	s3,8(sp)
    80001b9a:	e052                	sd	s4,0(sp)
    80001b9c:	1800                	add	s0,sp,48
    80001b9e:	89aa                	mv	s3,a0
    80001ba0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	920080e7          	jalr	-1760(ra) # 800014c2 <myproc>
    80001baa:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001bac:	00850a13          	add	s4,a0,8
    80001bb0:	8552                	mv	a0,s4
    80001bb2:	00000097          	auipc	ra,0x0
    80001bb6:	472080e7          	jalr	1138(ra) # 80002024 <acquire>
  release(lk);
    80001bba:	854a                	mv	a0,s2
    80001bbc:	00000097          	auipc	ra,0x0
    80001bc0:	51c080e7          	jalr	1308(ra) # 800020d8 <release>

  // Go to sleep.
  p->chan = chan;
    80001bc4:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80001bc8:	4789                	li	a5,2
    80001bca:	d09c                	sw	a5,32(s1)

  sched();
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	770080e7          	jalr	1904(ra) # 8000233c <sched>

  // Tidy up.
  p->chan = 0;
    80001bd4:	0204b823          	sd	zero,48(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001bd8:	8552                	mv	a0,s4
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	4fe080e7          	jalr	1278(ra) # 800020d8 <release>
  acquire(lk);
    80001be2:	854a                	mv	a0,s2
    80001be4:	00000097          	auipc	ra,0x0
    80001be8:	440080e7          	jalr	1088(ra) # 80002024 <acquire>
}
    80001bec:	70a2                	ld	ra,40(sp)
    80001bee:	7402                	ld	s0,32(sp)
    80001bf0:	64e2                	ld	s1,24(sp)
    80001bf2:	6942                	ld	s2,16(sp)
    80001bf4:	69a2                	ld	s3,8(sp)
    80001bf6:	6a02                	ld	s4,0(sp)
    80001bf8:	6145                	add	sp,sp,48
    80001bfa:	8082                	ret

0000000080001bfc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80001bfc:	7139                	add	sp,sp,-64
    80001bfe:	fc06                	sd	ra,56(sp)
    80001c00:	f822                	sd	s0,48(sp)
    80001c02:	f426                	sd	s1,40(sp)
    80001c04:	f04a                	sd	s2,32(sp)
    80001c06:	ec4e                	sd	s3,24(sp)
    80001c08:	e852                	sd	s4,16(sp)
    80001c0a:	e456                	sd	s5,8(sp)
    80001c0c:	e05a                	sd	s6,0(sp)
    80001c0e:	0080                	add	s0,sp,64
    80001c10:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001c12:	0000b497          	auipc	s1,0xb
    80001c16:	18648493          	add	s1,s1,390 # 8000cd98 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001c1a:	4a09                	li	s4,2
        p->state = RUNNABLE;
    80001c1c:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1e:	0000f997          	auipc	s3,0xf
    80001c22:	97a98993          	add	s3,s3,-1670 # 80010598 <wait_lock>
    80001c26:	a811                	j	80001c3a <wakeup+0x3e>
      }
      release(&p->lock);
    80001c28:	854a                	mv	a0,s2
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	4ae080e7          	jalr	1198(ra) # 800020d8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c32:	0e048493          	add	s1,s1,224
    80001c36:	03348863          	beq	s1,s3,80001c66 <wakeup+0x6a>
    if(p != myproc()){
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	888080e7          	jalr	-1912(ra) # 800014c2 <myproc>
    80001c42:	fea488e3          	beq	s1,a0,80001c32 <wakeup+0x36>
      acquire(&p->lock);
    80001c46:	00848913          	add	s2,s1,8
    80001c4a:	854a                	mv	a0,s2
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	3d8080e7          	jalr	984(ra) # 80002024 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001c54:	509c                	lw	a5,32(s1)
    80001c56:	fd4799e3          	bne	a5,s4,80001c28 <wakeup+0x2c>
    80001c5a:	789c                	ld	a5,48(s1)
    80001c5c:	fd5796e3          	bne	a5,s5,80001c28 <wakeup+0x2c>
        p->state = RUNNABLE;
    80001c60:	0364a023          	sw	s6,32(s1)
    80001c64:	b7d1                	j	80001c28 <wakeup+0x2c>
    }
  }
}
    80001c66:	70e2                	ld	ra,56(sp)
    80001c68:	7442                	ld	s0,48(sp)
    80001c6a:	74a2                	ld	s1,40(sp)
    80001c6c:	7902                	ld	s2,32(sp)
    80001c6e:	69e2                	ld	s3,24(sp)
    80001c70:	6a42                	ld	s4,16(sp)
    80001c72:	6aa2                	ld	s5,8(sp)
    80001c74:	6b02                	ld	s6,0(sp)
    80001c76:	6121                	add	sp,sp,64
    80001c78:	8082                	ret

0000000080001c7a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80001c7a:	7179                	add	sp,sp,-48
    80001c7c:	f406                	sd	ra,40(sp)
    80001c7e:	f022                	sd	s0,32(sp)
    80001c80:	ec26                	sd	s1,24(sp)
    80001c82:	e84a                	sd	s2,16(sp)
    80001c84:	e44e                	sd	s3,8(sp)
    80001c86:	e052                	sd	s4,0(sp)
    80001c88:	1800                	add	s0,sp,48
    80001c8a:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80001c8c:	0000b497          	auipc	s1,0xb
    80001c90:	10c48493          	add	s1,s1,268 # 8000cd98 <proc>
    80001c94:	0000fa17          	auipc	s4,0xf
    80001c98:	904a0a13          	add	s4,s4,-1788 # 80010598 <wait_lock>
    acquire(&p->lock);
    80001c9c:	00848913          	add	s2,s1,8
    80001ca0:	854a                	mv	a0,s2
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	382080e7          	jalr	898(ra) # 80002024 <acquire>
    if(p->pid == pid){
    80001caa:	409c                	lw	a5,0(s1)
    80001cac:	01378d63          	beq	a5,s3,80001cc6 <kill+0x4c>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80001cb0:	854a                	mv	a0,s2
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	426080e7          	jalr	1062(ra) # 800020d8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001cba:	0e048493          	add	s1,s1,224
    80001cbe:	fd449fe3          	bne	s1,s4,80001c9c <kill+0x22>
  }
  return -1;
    80001cc2:	557d                	li	a0,-1
    80001cc4:	a829                	j	80001cde <kill+0x64>
      p->killed = 1;
    80001cc6:	4785                	li	a5,1
    80001cc8:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80001cca:	5098                	lw	a4,32(s1)
    80001ccc:	4789                	li	a5,2
    80001cce:	02f70063          	beq	a4,a5,80001cee <kill+0x74>
      release(&p->lock);
    80001cd2:	854a                	mv	a0,s2
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	404080e7          	jalr	1028(ra) # 800020d8 <release>
      return 0;
    80001cdc:	4501                	li	a0,0
}
    80001cde:	70a2                	ld	ra,40(sp)
    80001ce0:	7402                	ld	s0,32(sp)
    80001ce2:	64e2                	ld	s1,24(sp)
    80001ce4:	6942                	ld	s2,16(sp)
    80001ce6:	69a2                	ld	s3,8(sp)
    80001ce8:	6a02                	ld	s4,0(sp)
    80001cea:	6145                	add	sp,sp,48
    80001cec:	8082                	ret
        p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	d09c                	sw	a5,32(s1)
    80001cf2:	b7c5                	j	80001cd2 <kill+0x58>

0000000080001cf4 <setkilled>:

void
setkilled(struct proc *p)
{
    80001cf4:	1101                	add	sp,sp,-32
    80001cf6:	ec06                	sd	ra,24(sp)
    80001cf8:	e822                	sd	s0,16(sp)
    80001cfa:	e426                	sd	s1,8(sp)
    80001cfc:	e04a                	sd	s2,0(sp)
    80001cfe:	1000                	add	s0,sp,32
    80001d00:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001d02:	00850913          	add	s2,a0,8
    80001d06:	854a                	mv	a0,s2
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	31c080e7          	jalr	796(ra) # 80002024 <acquire>
  p->killed = 1;
    80001d10:	4785                	li	a5,1
    80001d12:	dc9c                	sw	a5,56(s1)
  release(&p->lock);
    80001d14:	854a                	mv	a0,s2
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	3c2080e7          	jalr	962(ra) # 800020d8 <release>
}
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6902                	ld	s2,0(sp)
    80001d26:	6105                	add	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <killed>:

int
killed(struct proc *p)
{
    80001d2a:	1101                	add	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	e04a                	sd	s2,0(sp)
    80001d34:	1000                	add	s0,sp,32
    80001d36:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80001d38:	00850913          	add	s2,a0,8
    80001d3c:	854a                	mv	a0,s2
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	2e6080e7          	jalr	742(ra) # 80002024 <acquire>
  k = p->killed;
    80001d46:	5c84                	lw	s1,56(s1)
  release(&p->lock);
    80001d48:	854a                	mv	a0,s2
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	38e080e7          	jalr	910(ra) # 800020d8 <release>
  return k;
}
    80001d52:	8526                	mv	a0,s1
    80001d54:	60e2                	ld	ra,24(sp)
    80001d56:	6442                	ld	s0,16(sp)
    80001d58:	64a2                	ld	s1,8(sp)
    80001d5a:	6902                	ld	s2,0(sp)
    80001d5c:	6105                	add	sp,sp,32
    80001d5e:	8082                	ret

0000000080001d60 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
    80001d60:	711d                	add	sp,sp,-96
    80001d62:	ec86                	sd	ra,88(sp)
    80001d64:	e8a2                	sd	s0,80(sp)
    80001d66:	e4a6                	sd	s1,72(sp)
    80001d68:	e0ca                	sd	s2,64(sp)
    80001d6a:	fc4e                	sd	s3,56(sp)
    80001d6c:	f852                	sd	s4,48(sp)
    80001d6e:	f456                	sd	s5,40(sp)
    80001d70:	f05a                	sd	s6,32(sp)
    80001d72:	ec5e                	sd	s7,24(sp)
    80001d74:	e862                	sd	s8,16(sp)
    80001d76:	e466                	sd	s9,8(sp)
    80001d78:	1080                	add	s0,sp,96
    80001d7a:	8baa                	mv	s7,a0
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	746080e7          	jalr	1862(ra) # 800014c2 <myproc>
    80001d84:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80001d86:	0000f517          	auipc	a0,0xf
    80001d8a:	81250513          	add	a0,a0,-2030 # 80010598 <wait_lock>
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	296080e7          	jalr	662(ra) # 80002024 <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80001d96:	4c01                	li	s8,0
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
    80001d98:	4a95                	li	s5,5
        havekids = 1;
    80001d9a:	4b05                	li	s6,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001d9c:	0000e997          	auipc	s3,0xe
    80001da0:	7fc98993          	add	s3,s3,2044 # 80010598 <wait_lock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80001da4:	0000ec97          	auipc	s9,0xe
    80001da8:	7f4c8c93          	add	s9,s9,2036 # 80010598 <wait_lock>
    80001dac:	a8f1                	j	80001e88 <wait+0x128>
          printf("wait: found zombie pid=%d\n", pp->pid);
    80001dae:	408c                	lw	a1,0(s1)
    80001db0:	00002517          	auipc	a0,0x2
    80001db4:	5c050513          	add	a0,a0,1472 # 80004370 <digits+0x2f0>
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	9fc080e7          	jalr	-1540(ra) # 800007b4 <printf>
          pid = pp->pid;
    80001dc0:	0004a983          	lw	s3,0(s1)
          if(addr != 0 && uvm_copyout(p->pgtbl, addr, (uint64)&pp->exit_state,
    80001dc4:	000b8e63          	beqz	s7,80001de0 <wait+0x80>
    80001dc8:	4691                	li	a3,4
    80001dca:	03c48613          	add	a2,s1,60
    80001dce:	85de                	mv	a1,s7
    80001dd0:	04893503          	ld	a0,72(s2)
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	532080e7          	jalr	1330(ra) # 80001306 <uvm_copyout>
    80001ddc:	04054263          	bltz	a0,80001e20 <wait+0xc0>
          freeproc(pp);
    80001de0:	8526                	mv	a0,s1
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	93a080e7          	jalr	-1734(ra) # 8000171c <freeproc>
          release(&pp->lock);
    80001dea:	8552                	mv	a0,s4
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	2ec080e7          	jalr	748(ra) # 800020d8 <release>
          release(&wait_lock);
    80001df4:	0000e517          	auipc	a0,0xe
    80001df8:	7a450513          	add	a0,a0,1956 # 80010598 <wait_lock>
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	2dc080e7          	jalr	732(ra) # 800020d8 <release>
  }
}
    80001e04:	854e                	mv	a0,s3
    80001e06:	60e6                	ld	ra,88(sp)
    80001e08:	6446                	ld	s0,80(sp)
    80001e0a:	64a6                	ld	s1,72(sp)
    80001e0c:	6906                	ld	s2,64(sp)
    80001e0e:	79e2                	ld	s3,56(sp)
    80001e10:	7a42                	ld	s4,48(sp)
    80001e12:	7aa2                	ld	s5,40(sp)
    80001e14:	7b02                	ld	s6,32(sp)
    80001e16:	6be2                	ld	s7,24(sp)
    80001e18:	6c42                	ld	s8,16(sp)
    80001e1a:	6ca2                	ld	s9,8(sp)
    80001e1c:	6125                	add	sp,sp,96
    80001e1e:	8082                	ret
            release(&pp->lock);
    80001e20:	8552                	mv	a0,s4
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	2b6080e7          	jalr	694(ra) # 800020d8 <release>
            release(&wait_lock);
    80001e2a:	0000e517          	auipc	a0,0xe
    80001e2e:	76e50513          	add	a0,a0,1902 # 80010598 <wait_lock>
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	2a6080e7          	jalr	678(ra) # 800020d8 <release>
            return -1;
    80001e3a:	59fd                	li	s3,-1
    80001e3c:	b7e1                	j	80001e04 <wait+0xa4>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e3e:	0e048493          	add	s1,s1,224
    80001e42:	03348663          	beq	s1,s3,80001e6e <wait+0x10e>
      if(pp->parent == p){
    80001e46:	749c                	ld	a5,40(s1)
    80001e48:	ff279be3          	bne	a5,s2,80001e3e <wait+0xde>
        acquire(&pp->lock);
    80001e4c:	00848a13          	add	s4,s1,8
    80001e50:	8552                	mv	a0,s4
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	1d2080e7          	jalr	466(ra) # 80002024 <acquire>
        if(pp->state == ZOMBIE){
    80001e5a:	509c                	lw	a5,32(s1)
    80001e5c:	f55789e3          	beq	a5,s5,80001dae <wait+0x4e>
        release(&pp->lock);
    80001e60:	8552                	mv	a0,s4
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	276080e7          	jalr	630(ra) # 800020d8 <release>
        havekids = 1;
    80001e6a:	875a                	mv	a4,s6
    80001e6c:	bfc9                	j	80001e3e <wait+0xde>
    if(!havekids || killed(p)){
    80001e6e:	c31d                	beqz	a4,80001e94 <wait+0x134>
    80001e70:	854a                	mv	a0,s2
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	eb8080e7          	jalr	-328(ra) # 80001d2a <killed>
    80001e7a:	ed09                	bnez	a0,80001e94 <wait+0x134>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80001e7c:	85e6                	mv	a1,s9
    80001e7e:	854a                	mv	a0,s2
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	d0e080e7          	jalr	-754(ra) # 80001b8e <sleep>
    havekids = 0;
    80001e88:	8762                	mv	a4,s8
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e8a:	0000b497          	auipc	s1,0xb
    80001e8e:	f0e48493          	add	s1,s1,-242 # 8000cd98 <proc>
    80001e92:	bf55                	j	80001e46 <wait+0xe6>
      release(&wait_lock);
    80001e94:	0000e517          	auipc	a0,0xe
    80001e98:	70450513          	add	a0,a0,1796 # 80010598 <wait_lock>
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	23c080e7          	jalr	572(ra) # 800020d8 <release>
      return -1;
    80001ea4:	59fd                	li	s3,-1
    80001ea6:	bfb9                	j	80001e04 <wait+0xa4>

0000000080001ea8 <reparent>:

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
    80001ea8:	7179                	add	sp,sp,-48
    80001eaa:	f406                	sd	ra,40(sp)
    80001eac:	f022                	sd	s0,32(sp)
    80001eae:	ec26                	sd	s1,24(sp)
    80001eb0:	e84a                	sd	s2,16(sp)
    80001eb2:	e44e                	sd	s3,8(sp)
    80001eb4:	e052                	sd	s4,0(sp)
    80001eb6:	1800                	add	s0,sp,48
    80001eb8:	892a                	mv	s2,a0
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eba:	0000b497          	auipc	s1,0xb
    80001ebe:	ede48493          	add	s1,s1,-290 # 8000cd98 <proc>
    if(pp->parent == p){
      pp->parent = proczero;
    80001ec2:	00003a17          	auipc	s4,0x3
    80001ec6:	816a0a13          	add	s4,s4,-2026 # 800046d8 <proczero>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eca:	0000e997          	auipc	s3,0xe
    80001ece:	6ce98993          	add	s3,s3,1742 # 80010598 <wait_lock>
    80001ed2:	a029                	j	80001edc <reparent+0x34>
    80001ed4:	0e048493          	add	s1,s1,224
    80001ed8:	01348d63          	beq	s1,s3,80001ef2 <reparent+0x4a>
    if(pp->parent == p){
    80001edc:	749c                	ld	a5,40(s1)
    80001ede:	ff279be3          	bne	a5,s2,80001ed4 <reparent+0x2c>
      pp->parent = proczero;
    80001ee2:	000a3503          	ld	a0,0(s4)
    80001ee6:	f488                	sd	a0,40(s1)
      wakeup(proczero);
    80001ee8:	00000097          	auipc	ra,0x0
    80001eec:	d14080e7          	jalr	-748(ra) # 80001bfc <wakeup>
    80001ef0:	b7d5                	j	80001ed4 <reparent+0x2c>
    }
  }
}
    80001ef2:	70a2                	ld	ra,40(sp)
    80001ef4:	7402                	ld	s0,32(sp)
    80001ef6:	64e2                	ld	s1,24(sp)
    80001ef8:	6942                	ld	s2,16(sp)
    80001efa:	69a2                	ld	s3,8(sp)
    80001efc:	6a02                	ld	s4,0(sp)
    80001efe:	6145                	add	sp,sp,48
    80001f00:	8082                	ret

0000000080001f02 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
    80001f02:	7179                	add	sp,sp,-48
    80001f04:	f406                	sd	ra,40(sp)
    80001f06:	f022                	sd	s0,32(sp)
    80001f08:	ec26                	sd	s1,24(sp)
    80001f0a:	e84a                	sd	s2,16(sp)
    80001f0c:	e44e                	sd	s3,8(sp)
    80001f0e:	1800                	add	s0,sp,48
    80001f10:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	5b0080e7          	jalr	1456(ra) # 800014c2 <myproc>

  if(p == proczero)
    80001f1a:	00002797          	auipc	a5,0x2
    80001f1e:	7be7b783          	ld	a5,1982(a5) # 800046d8 <proczero>
    80001f22:	06a78163          	beq	a5,a0,80001f84 <exit+0x82>
    80001f26:	84aa                	mv	s1,a0
  // begin_op();
  // iput(p->cwd);
  // end_op();
  // p->cwd = 0;

  acquire(&wait_lock);
    80001f28:	0000e997          	auipc	s3,0xe
    80001f2c:	67098993          	add	s3,s3,1648 # 80010598 <wait_lock>
    80001f30:	854e                	mv	a0,s3
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	0f2080e7          	jalr	242(ra) # 80002024 <acquire>

  // Give any children to init.
  reparent(p);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	00000097          	auipc	ra,0x0
    80001f40:	f6c080e7          	jalr	-148(ra) # 80001ea8 <reparent>

  // Parent might be sleeping in wait().
  wakeup(p->parent);
    80001f44:	7488                	ld	a0,40(s1)
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	cb6080e7          	jalr	-842(ra) # 80001bfc <wakeup>
  
  acquire(&p->lock);
    80001f4e:	00848513          	add	a0,s1,8
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	0d2080e7          	jalr	210(ra) # 80002024 <acquire>

  p->exit_state = status;
    80001f5a:	0324ae23          	sw	s2,60(s1)
  p->state = ZOMBIE;
    80001f5e:	4795                	li	a5,5
    80001f60:	d09c                	sw	a5,32(s1)

  release(&wait_lock);
    80001f62:	854e                	mv	a0,s3
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	174080e7          	jalr	372(ra) # 800020d8 <release>

  // Jump into the scheduler, never to return.
  sched();
    80001f6c:	00000097          	auipc	ra,0x0
    80001f70:	3d0080e7          	jalr	976(ra) # 8000233c <sched>
  panic("zombie exit");
    80001f74:	00002517          	auipc	a0,0x2
    80001f78:	42c50513          	add	a0,a0,1068 # 800043a0 <digits+0x320>
    80001f7c:	ffffe097          	auipc	ra,0xffffe
    80001f80:	7ee080e7          	jalr	2030(ra) # 8000076a <panic>
    panic("init exiting");
    80001f84:	00002517          	auipc	a0,0x2
    80001f88:	40c50513          	add	a0,a0,1036 # 80004390 <digits+0x310>
    80001f8c:	ffffe097          	auipc	ra,0xffffe
    80001f90:	7de080e7          	jalr	2014(ra) # 8000076a <panic>

0000000080001f94 <initlock>:
#include "proc-h/cpu.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80001f94:	1141                	add	sp,sp,-16
    80001f96:	e422                	sd	s0,8(sp)
    80001f98:	0800                	add	s0,sp,16
  lk->name = name;
    80001f9a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80001f9c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80001fa0:	00053823          	sd	zero,16(a0)
}
    80001fa4:	6422                	ld	s0,8(sp)
    80001fa6:	0141                	add	sp,sp,16
    80001fa8:	8082                	ret

0000000080001faa <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80001faa:	411c                	lw	a5,0(a0)
    80001fac:	e399                	bnez	a5,80001fb2 <holding+0x8>
    80001fae:	4501                	li	a0,0
  return r;
}
    80001fb0:	8082                	ret
{
    80001fb2:	1101                	add	sp,sp,-32
    80001fb4:	ec06                	sd	ra,24(sp)
    80001fb6:	e822                	sd	s0,16(sp)
    80001fb8:	e426                	sd	s1,8(sp)
    80001fba:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80001fbc:	6904                	ld	s1,16(a0)
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	4e8080e7          	jalr	1256(ra) # 800014a6 <mycpu>
    80001fc6:	40a48533          	sub	a0,s1,a0
    80001fca:	00153513          	seqz	a0,a0
}
    80001fce:	60e2                	ld	ra,24(sp)
    80001fd0:	6442                	ld	s0,16(sp)
    80001fd2:	64a2                	ld	s1,8(sp)
    80001fd4:	6105                	add	sp,sp,32
    80001fd6:	8082                	ret

0000000080001fd8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80001fd8:	1101                	add	sp,sp,-32
    80001fda:	ec06                	sd	ra,24(sp)
    80001fdc:	e822                	sd	s0,16(sp)
    80001fde:	e426                	sd	s1,8(sp)
    80001fe0:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe2:	100024f3          	csrr	s1,sstatus
    80001fe6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001fea:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fec:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	4b6080e7          	jalr	1206(ra) # 800014a6 <mycpu>
    80001ff8:	411c                	lw	a5,0(a0)
    80001ffa:	cf89                	beqz	a5,80002014 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	4aa080e7          	jalr	1194(ra) # 800014a6 <mycpu>
    80002004:	411c                	lw	a5,0(a0)
    80002006:	2785                	addw	a5,a5,1
    80002008:	c11c                	sw	a5,0(a0)
}
    8000200a:	60e2                	ld	ra,24(sp)
    8000200c:	6442                	ld	s0,16(sp)
    8000200e:	64a2                	ld	s1,8(sp)
    80002010:	6105                	add	sp,sp,32
    80002012:	8082                	ret
    mycpu()->intena = old;
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	492080e7          	jalr	1170(ra) # 800014a6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    8000201c:	8085                	srl	s1,s1,0x1
    8000201e:	8885                	and	s1,s1,1
    80002020:	c144                	sw	s1,4(a0)
    80002022:	bfe9                	j	80001ffc <push_off+0x24>

0000000080002024 <acquire>:
{
    80002024:	1101                	add	sp,sp,-32
    80002026:	ec06                	sd	ra,24(sp)
    80002028:	e822                	sd	s0,16(sp)
    8000202a:	e426                	sd	s1,8(sp)
    8000202c:	1000                	add	s0,sp,32
    8000202e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80002030:	00000097          	auipc	ra,0x0
    80002034:	fa8080e7          	jalr	-88(ra) # 80001fd8 <push_off>
  if(holding(lk))
    80002038:	8526                	mv	a0,s1
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	f70080e7          	jalr	-144(ra) # 80001faa <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80002042:	4705                	li	a4,1
  if(holding(lk))
    80002044:	e115                	bnez	a0,80002068 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80002046:	87ba                	mv	a5,a4
    80002048:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    8000204c:	2781                	sext.w	a5,a5
    8000204e:	ffe5                	bnez	a5,80002046 <acquire+0x22>
  __sync_synchronize();
    80002050:	0ff0000f          	fence
  lk->cpu = mycpu();
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	452080e7          	jalr	1106(ra) # 800014a6 <mycpu>
    8000205c:	e888                	sd	a0,16(s1)
}
    8000205e:	60e2                	ld	ra,24(sp)
    80002060:	6442                	ld	s0,16(sp)
    80002062:	64a2                	ld	s1,8(sp)
    80002064:	6105                	add	sp,sp,32
    80002066:	8082                	ret
    panic("acquire");
    80002068:	00002517          	auipc	a0,0x2
    8000206c:	34850513          	add	a0,a0,840 # 800043b0 <digits+0x330>
    80002070:	ffffe097          	auipc	ra,0xffffe
    80002074:	6fa080e7          	jalr	1786(ra) # 8000076a <panic>

0000000080002078 <pop_off>:

void
pop_off(void)
{
    80002078:	1141                	add	sp,sp,-16
    8000207a:	e406                	sd	ra,8(sp)
    8000207c:	e022                	sd	s0,0(sp)
    8000207e:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	426080e7          	jalr	1062(ra) # 800014a6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208c:	8b89                	and	a5,a5,2
  if(intr_get())
    8000208e:	e78d                	bnez	a5,800020b8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80002090:	411c                	lw	a5,0(a0)
    80002092:	02f05b63          	blez	a5,800020c8 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80002096:	37fd                	addw	a5,a5,-1
    80002098:	0007871b          	sext.w	a4,a5
    8000209c:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    8000209e:	eb09                	bnez	a4,800020b0 <pop_off+0x38>
    800020a0:	415c                	lw	a5,4(a0)
    800020a2:	c799                	beqz	a5,800020b0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020a8:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ac:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800020b0:	60a2                	ld	ra,8(sp)
    800020b2:	6402                	ld	s0,0(sp)
    800020b4:	0141                	add	sp,sp,16
    800020b6:	8082                	ret
    panic("pop_off - interruptible");
    800020b8:	00002517          	auipc	a0,0x2
    800020bc:	30050513          	add	a0,a0,768 # 800043b8 <digits+0x338>
    800020c0:	ffffe097          	auipc	ra,0xffffe
    800020c4:	6aa080e7          	jalr	1706(ra) # 8000076a <panic>
    panic("pop_off");
    800020c8:	00002517          	auipc	a0,0x2
    800020cc:	30850513          	add	a0,a0,776 # 800043d0 <digits+0x350>
    800020d0:	ffffe097          	auipc	ra,0xffffe
    800020d4:	69a080e7          	jalr	1690(ra) # 8000076a <panic>

00000000800020d8 <release>:
{
    800020d8:	1101                	add	sp,sp,-32
    800020da:	ec06                	sd	ra,24(sp)
    800020dc:	e822                	sd	s0,16(sp)
    800020de:	e426                	sd	s1,8(sp)
    800020e0:	e04a                	sd	s2,0(sp)
    800020e2:	1000                	add	s0,sp,32
    800020e4:	84aa                	mv	s1,a0
  if(!holding(lk))
    800020e6:	00000097          	auipc	ra,0x0
    800020ea:	ec4080e7          	jalr	-316(ra) # 80001faa <holding>
    800020ee:	c11d                	beqz	a0,80002114 <release+0x3c>
  lk->cpu = 0;
    800020f0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800020f4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800020f8:	0f50000f          	fence	iorw,ow
    800020fc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	f78080e7          	jalr	-136(ra) # 80002078 <pop_off>
}
    80002108:	60e2                	ld	ra,24(sp)
    8000210a:	6442                	ld	s0,16(sp)
    8000210c:	64a2                	ld	s1,8(sp)
    8000210e:	6902                	ld	s2,0(sp)
    80002110:	6105                	add	sp,sp,32
    80002112:	8082                	ret
    printf("release lock %s at %p, cpu%d\n", lk->name, lk, cpuid());
    80002114:	0084b903          	ld	s2,8(s1)
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	37e080e7          	jalr	894(ra) # 80001496 <cpuid>
    80002120:	86aa                	mv	a3,a0
    80002122:	8626                	mv	a2,s1
    80002124:	85ca                	mv	a1,s2
    80002126:	00002517          	auipc	a0,0x2
    8000212a:	2b250513          	add	a0,a0,690 # 800043d8 <digits+0x358>
    8000212e:	ffffe097          	auipc	ra,0xffffe
    80002132:	686080e7          	jalr	1670(ra) # 800007b4 <printf>
    panic("release");
    80002136:	00002517          	auipc	a0,0x2
    8000213a:	2c250513          	add	a0,a0,706 # 800043f8 <digits+0x378>
    8000213e:	ffffe097          	auipc	ra,0xffffe
    80002142:	62c080e7          	jalr	1580(ra) # 8000076a <panic>

0000000080002146 <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    80002146:	1141                	add	sp,sp,-16
    80002148:	e422                	sd	s0,8(sp)
    8000214a:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000214c:	00001797          	auipc	a5,0x1
    80002150:	ae478793          	add	a5,a5,-1308 # 80002c30 <kernelvec>
    80002154:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    80002158:	6422                	ld	s0,8(sp)
    8000215a:	0141                	add	sp,sp,16
    8000215c:	8082                	ret

000000008000215e <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000215e:	142027f3          	csrr	a5,scause
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    80002162:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002164:	0807d763          	bgez	a5,800021f2 <devintr+0x94>
{
    80002168:	1101                	add	sp,sp,-32
    8000216a:	ec06                	sd	ra,24(sp)
    8000216c:	e822                	sd	s0,16(sp)
    8000216e:	e426                	sd	s1,8(sp)
    80002170:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002172:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002176:	46a5                	li	a3,9
    80002178:	00d70d63          	beq	a4,a3,80002192 <devintr+0x34>
  if(scause == 0x8000000000000001L){
    8000217c:	577d                	li	a4,-1
    8000217e:	177e                	sll	a4,a4,0x3f
    80002180:	0705                	add	a4,a4,1
    return 0;  // 未识别的中断类型
    80002182:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    80002184:	04e78663          	beq	a5,a4,800021d0 <devintr+0x72>
  }
}
    80002188:	60e2                	ld	ra,24(sp)
    8000218a:	6442                	ld	s0,16(sp)
    8000218c:	64a2                	ld	s1,8(sp)
    8000218e:	6105                	add	sp,sp,32
    80002190:	8082                	ret
    int irq = plic_claim();  // 获取中断请求号
    80002192:	ffffe097          	auipc	ra,0xffffe
    80002196:	342080e7          	jalr	834(ra) # 800004d4 <plic_claim>
    8000219a:	84aa                	mv	s1,a0
    switch(irq){
    8000219c:	47a9                	li	a5,10
    8000219e:	02f50463          	beq	a0,a5,800021c6 <devintr+0x68>
    return 1;
    800021a2:	4505                	li	a0,1
      if(irq){
    800021a4:	d0f5                	beqz	s1,80002188 <devintr+0x2a>
        printf("unexpected interrupt irq=%d\n", irq);
    800021a6:	85a6                	mv	a1,s1
    800021a8:	00002517          	auipc	a0,0x2
    800021ac:	25850513          	add	a0,a0,600 # 80004400 <digits+0x380>
    800021b0:	ffffe097          	auipc	ra,0xffffe
    800021b4:	604080e7          	jalr	1540(ra) # 800007b4 <printf>
      plic_complete(irq);
    800021b8:	8526                	mv	a0,s1
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	33e080e7          	jalr	830(ra) # 800004f8 <plic_complete>
    return 1;
    800021c2:	4505                	li	a0,1
    800021c4:	b7d1                	j	80002188 <devintr+0x2a>
      uartintr();           // 处理串口中断
    800021c6:	ffffe097          	auipc	ra,0xffffe
    800021ca:	1d4080e7          	jalr	468(ra) # 8000039a <uartintr>
    if(irq)
    800021ce:	b7ed                	j	800021b8 <devintr+0x5a>
    if(cpuid() == 0){
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	2c6080e7          	jalr	710(ra) # 80001496 <cpuid>
    800021d8:	c901                	beqz	a0,800021e8 <devintr+0x8a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800021da:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800021de:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800021e0:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    800021e4:	4509                	li	a0,2
    800021e6:	b74d                	j	80002188 <devintr+0x2a>
      timer_update();
    800021e8:	ffffe097          	auipc	ra,0xffffe
    800021ec:	06e080e7          	jalr	110(ra) # 80000256 <timer_update>
    800021f0:	b7ed                	j	800021da <devintr+0x7c>
}
    800021f2:	8082                	ret

00000000800021f4 <kerneltrap>:
{
    800021f4:	7179                	add	sp,sp,-48
    800021f6:	f406                	sd	ra,40(sp)
    800021f8:	f022                	sd	s0,32(sp)
    800021fa:	ec26                	sd	s1,24(sp)
    800021fc:	e84a                	sd	s2,16(sp)
    800021fe:	e44e                	sd	s3,8(sp)
    80002200:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002202:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002206:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000220a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000220e:	1004f793          	and	a5,s1,256
    80002212:	cb85                	beqz	a5,80002242 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002214:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002218:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    8000221a:	ef85                	bnez	a5,80002252 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	f42080e7          	jalr	-190(ra) # 8000215e <devintr>
    80002224:	cd1d                	beqz	a0,80002262 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 /*&& myproc()->state == RUNNING*/)
    80002226:	4789                	li	a5,2
    80002228:	06f50a63          	beq	a0,a5,8000229c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000222c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002230:	10049073          	csrw	sstatus,s1
}
    80002234:	70a2                	ld	ra,40(sp)
    80002236:	7402                	ld	s0,32(sp)
    80002238:	64e2                	ld	s1,24(sp)
    8000223a:	6942                	ld	s2,16(sp)
    8000223c:	69a2                	ld	s3,8(sp)
    8000223e:	6145                	add	sp,sp,48
    80002240:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002242:	00002517          	auipc	a0,0x2
    80002246:	1de50513          	add	a0,a0,478 # 80004420 <digits+0x3a0>
    8000224a:	ffffe097          	auipc	ra,0xffffe
    8000224e:	520080e7          	jalr	1312(ra) # 8000076a <panic>
    panic("kerneltrap: interrupts enabled");
    80002252:	00002517          	auipc	a0,0x2
    80002256:	1f650513          	add	a0,a0,502 # 80004448 <digits+0x3c8>
    8000225a:	ffffe097          	auipc	ra,0xffffe
    8000225e:	510080e7          	jalr	1296(ra) # 8000076a <panic>
    printf("scause %p\n", scause);
    80002262:	85ce                	mv	a1,s3
    80002264:	00002517          	auipc	a0,0x2
    80002268:	20450513          	add	a0,a0,516 # 80004468 <digits+0x3e8>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	548080e7          	jalr	1352(ra) # 800007b4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002274:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002278:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000227c:	00002517          	auipc	a0,0x2
    80002280:	1fc50513          	add	a0,a0,508 # 80004478 <digits+0x3f8>
    80002284:	ffffe097          	auipc	ra,0xffffe
    80002288:	530080e7          	jalr	1328(ra) # 800007b4 <printf>
    panic("kerneltrap");
    8000228c:	00002517          	auipc	a0,0x2
    80002290:	20450513          	add	a0,a0,516 # 80004490 <digits+0x410>
    80002294:	ffffe097          	auipc	ra,0xffffe
    80002298:	4d6080e7          	jalr	1238(ra) # 8000076a <panic>
  if(which_dev == 2 && myproc() != 0 /*&& myproc()->state == RUNNING*/)
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	226080e7          	jalr	550(ra) # 800014c2 <myproc>
    800022a4:	d541                	beqz	a0,8000222c <kerneltrap+0x38>
    yield();
    800022a6:	00000097          	auipc	ra,0x0
    800022aa:	154080e7          	jalr	340(ra) # 800023fa <yield>
    800022ae:	bfbd                	j	8000222c <kerneltrap+0x38>

00000000800022b0 <scheduler>:
//  - 选择一个进程运行
//  - 通过swtch切换到该进程开始运行
//  - 最终该进程通过swtch将控制权交回给调度器
void
scheduler(void)
{
    800022b0:	715d                	add	sp,sp,-80
    800022b2:	e486                	sd	ra,72(sp)
    800022b4:	e0a2                	sd	s0,64(sp)
    800022b6:	fc26                	sd	s1,56(sp)
    800022b8:	f84a                	sd	s2,48(sp)
    800022ba:	f44e                	sd	s3,40(sp)
    800022bc:	f052                	sd	s4,32(sp)
    800022be:	ec56                	sd	s5,24(sp)
    800022c0:	e85a                	sd	s6,16(sp)
    800022c2:	e45e                	sd	s7,8(sp)
    800022c4:	0880                	add	s0,sp,80
  struct proc *p;
  struct cpu *c = mycpu();
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	1e0080e7          	jalr	480(ra) # 800014a6 <mycpu>
    800022ce:	8aaa                	mv	s5,a0
  
  c->proc = 0;
    800022d0:	00053423          	sd	zero,8(a0)
    intr_on();

    // 遍历进程表，寻找可运行的进程
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
    800022d4:	4a0d                	li	s4,3
        
        // 切换到选中的进程。进程有责任释放其锁
        // 然后在跳回调度器之前重新获取锁
        p->state = RUNNING;
    800022d6:	4b91                	li	s7,4
        c->proc = p;
        
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    800022d8:	01050b13          	add	s6,a0,16
    for(p = proc; p < &proc[NPROC]; p++) {
    800022dc:	0000e997          	auipc	s3,0xe
    800022e0:	2bc98993          	add	s3,s3,700 # 80010598 <wait_lock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022e8:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022ec:	10079073          	csrw	sstatus,a5
    800022f0:	0000b497          	auipc	s1,0xb
    800022f4:	aa848493          	add	s1,s1,-1368 # 8000cd98 <proc>
    800022f8:	a811                	j	8000230c <scheduler+0x5c>
        // 进程暂时运行完毕
        // 它应该在返回之前改变了p->state
        c->proc = 0;
      }
      release(&p->lock);
    800022fa:	854a                	mv	a0,s2
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	ddc080e7          	jalr	-548(ra) # 800020d8 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002304:	0e048493          	add	s1,s1,224
    80002308:	fd348ee3          	beq	s1,s3,800022e4 <scheduler+0x34>
      acquire(&p->lock);
    8000230c:	00848913          	add	s2,s1,8
    80002310:	854a                	mv	a0,s2
    80002312:	00000097          	auipc	ra,0x0
    80002316:	d12080e7          	jalr	-750(ra) # 80002024 <acquire>
      if(p->state == RUNNABLE) {
    8000231a:	509c                	lw	a5,32(s1)
    8000231c:	fd479fe3          	bne	a5,s4,800022fa <scheduler+0x4a>
        p->state = RUNNING;
    80002320:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    80002324:	009ab423          	sd	s1,8(s5)
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    80002328:	07048593          	add	a1,s1,112
    8000232c:	855a                	mv	a0,s6
    8000232e:	00001097          	auipc	ra,0x1
    80002332:	890080e7          	jalr	-1904(ra) # 80002bbe <swtch>
        c->proc = 0;
    80002336:	000ab423          	sd	zero,8(s5)
    8000233a:	b7c1                	j	800022fa <scheduler+0x4a>

000000008000233c <sched>:
// 并且已经改变了proc->state。
// 因为intena是这个内核线程的属性，而不是这个CPU的属性。
// 因此此处需要保存和恢复intena
void
sched(void)
{
    8000233c:	1101                	add	sp,sp,-32
    8000233e:	ec06                	sd	ra,24(sp)
    80002340:	e822                	sd	s0,16(sp)
    80002342:	e426                	sd	s1,8(sp)
    80002344:	e04a                	sd	s2,0(sp)
    80002346:	1000                	add	s0,sp,32
  int intena;
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	17a080e7          	jalr	378(ra) # 800014c2 <myproc>
    80002350:	84aa                	mv	s1,a0

  if(!holding(&p->lock))
    80002352:	0521                	add	a0,a0,8
    80002354:	00000097          	auipc	ra,0x0
    80002358:	c56080e7          	jalr	-938(ra) # 80001faa <holding>
    8000235c:	cd39                	beqz	a0,800023ba <sched+0x7e>
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	148080e7          	jalr	328(ra) # 800014a6 <mycpu>
    80002366:	4118                	lw	a4,0(a0)
    80002368:	4785                	li	a5,1
    8000236a:	06f71063          	bne	a4,a5,800023ca <sched+0x8e>
    panic("sched locks");
  if(p->state == RUNNING)
    8000236e:	5098                	lw	a4,32(s1)
    80002370:	4791                	li	a5,4
    80002372:	06f70463          	beq	a4,a5,800023da <sched+0x9e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002376:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000237a:	8b89                	and	a5,a5,2
    panic("sched running");
  if(intr_get())
    8000237c:	e7bd                	bnez	a5,800023ea <sched+0xae>
    panic("sched interruptible");

  intena = mycpu()->intena;
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	128080e7          	jalr	296(ra) # 800014a6 <mycpu>
    80002386:	00452903          	lw	s2,4(a0)
  swtch(&p->ctx, &mycpu()->context);  // 切换到调度器上下文
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	11c080e7          	jalr	284(ra) # 800014a6 <mycpu>
    80002392:	01050593          	add	a1,a0,16
    80002396:	07048513          	add	a0,s1,112
    8000239a:	00001097          	auipc	ra,0x1
    8000239e:	824080e7          	jalr	-2012(ra) # 80002bbe <swtch>
  mycpu()->intena = intena;
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	104080e7          	jalr	260(ra) # 800014a6 <mycpu>
    800023aa:	01252223          	sw	s2,4(a0)
}
    800023ae:	60e2                	ld	ra,24(sp)
    800023b0:	6442                	ld	s0,16(sp)
    800023b2:	64a2                	ld	s1,8(sp)
    800023b4:	6902                	ld	s2,0(sp)
    800023b6:	6105                	add	sp,sp,32
    800023b8:	8082                	ret
    panic("sched p->lock");
    800023ba:	00002517          	auipc	a0,0x2
    800023be:	0e650513          	add	a0,a0,230 # 800044a0 <digits+0x420>
    800023c2:	ffffe097          	auipc	ra,0xffffe
    800023c6:	3a8080e7          	jalr	936(ra) # 8000076a <panic>
    panic("sched locks");
    800023ca:	00002517          	auipc	a0,0x2
    800023ce:	0e650513          	add	a0,a0,230 # 800044b0 <digits+0x430>
    800023d2:	ffffe097          	auipc	ra,0xffffe
    800023d6:	398080e7          	jalr	920(ra) # 8000076a <panic>
    panic("sched running");
    800023da:	00002517          	auipc	a0,0x2
    800023de:	0e650513          	add	a0,a0,230 # 800044c0 <digits+0x440>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	388080e7          	jalr	904(ra) # 8000076a <panic>
    panic("sched interruptible");
    800023ea:	00002517          	auipc	a0,0x2
    800023ee:	0e650513          	add	a0,a0,230 # 800044d0 <digits+0x450>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	378080e7          	jalr	888(ra) # 8000076a <panic>

00000000800023fa <yield>:

// 用于进程放弃CPU, 重新进入调度
void
yield(void)
{
    800023fa:	1101                	add	sp,sp,-32
    800023fc:	ec06                	sd	ra,24(sp)
    800023fe:	e822                	sd	s0,16(sp)
    80002400:	e426                	sd	s1,8(sp)
    80002402:	e04a                	sd	s2,0(sp)
    80002404:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	0bc080e7          	jalr	188(ra) # 800014c2 <myproc>
    8000240e:	84aa                	mv	s1,a0
  acquire(&p->lock);     // 获取进程锁
    80002410:	00850913          	add	s2,a0,8
    80002414:	854a                	mv	a0,s2
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	c0e080e7          	jalr	-1010(ra) # 80002024 <acquire>
  p->state = RUNNABLE;   // 将进程状态设为可运行
    8000241e:	478d                	li	a5,3
    80002420:	d09c                	sw	a5,32(s1)
  sched();               // 调用sched()切换到调度器
    80002422:	00000097          	auipc	ra,0x0
    80002426:	f1a080e7          	jalr	-230(ra) # 8000233c <sched>
  release(&p->lock);     // 释放进程锁
    8000242a:	854a                	mv	a0,s2
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	cac080e7          	jalr	-852(ra) # 800020d8 <release>
    80002434:	60e2                	ld	ra,24(sp)
    80002436:	6442                	ld	s0,16(sp)
    80002438:	64a2                	ld	s1,8(sp)
    8000243a:	6902                	ld	s2,0(sp)
    8000243c:	6105                	add	sp,sp,32
    8000243e:	8082                	ret

0000000080002440 <trap_user_return>:
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
    80002440:	1141                	add	sp,sp,-16
    80002442:	e406                	sd	ra,8(sp)
    80002444:	e022                	sd	s0,0(sp)
    80002446:	0800                	add	s0,sp,16
  //printf("trap_user_return\n");
  struct proc *p = myproc();
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	07a080e7          	jalr	122(ra) # 800014c2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002450:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002454:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002456:	10079073          	csrw	sstatus,a5
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000245a:	00001697          	auipc	a3,0x1
    8000245e:	ba668693          	add	a3,a3,-1114 # 80003000 <_trampoline>
    80002462:	00001717          	auipc	a4,0x1
    80002466:	b9e70713          	add	a4,a4,-1122 # 80003000 <_trampoline>
    8000246a:	8f15                	sub	a4,a4,a3
    8000246c:	040007b7          	lui	a5,0x4000
    80002470:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002472:	07b2                	sll	a5,a5,0xc
    80002474:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002476:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
    8000247a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000247c:	18002673          	csrr	a2,satp
    80002480:	e310                	sd	a2,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
    80002482:	6d30                	ld	a2,88(a0)
    80002484:	7538                	ld	a4,104(a0)
    80002486:	6585                	lui	a1,0x1
    80002488:	972e                	add	a4,a4,a1
    8000248a:	e618                	sd	a4,8(a2)
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
    8000248c:	6d38                	ld	a4,88(a0)
    8000248e:	00000617          	auipc	a2,0x0
    80002492:	04860613          	add	a2,a2,72 # 800024d6 <trap_user_handler>
    80002496:	eb10                	sd	a2,16(a4)
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid
    80002498:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000249a:	8612                	mv	a2,tp
    8000249c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000249e:	10002773          	csrr	a4,sstatus
  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
    800024a2:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
    800024a6:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024aa:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);
    800024ae:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800024b0:	6f18                	ld	a4,24(a4)
    800024b2:	14171073          	csrw	sepc,a4

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);
    800024b6:	6528                	ld	a0,72(a0)
    800024b8:	8131                	srl	a0,a0,0xc

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800024ba:	00001717          	auipc	a4,0x1
    800024be:	be270713          	add	a4,a4,-1054 # 8000309c <userret>
    800024c2:	8f15                	sub	a4,a4,a3
    800024c4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800024c6:	577d                	li	a4,-1
    800024c8:	177e                	sll	a4,a4,0x3f
    800024ca:	8d59                	or	a0,a0,a4
    800024cc:	9782                	jalr	a5
    800024ce:	60a2                	ld	ra,8(sp)
    800024d0:	6402                	ld	s0,0(sp)
    800024d2:	0141                	add	sp,sp,16
    800024d4:	8082                	ret

00000000800024d6 <trap_user_handler>:
{
    800024d6:	7139                	add	sp,sp,-64
    800024d8:	fc06                	sd	ra,56(sp)
    800024da:	f822                	sd	s0,48(sp)
    800024dc:	f426                	sd	s1,40(sp)
    800024de:	f04a                	sd	s2,32(sp)
    800024e0:	ec4e                	sd	s3,24(sp)
    800024e2:	e852                	sd	s4,16(sp)
    800024e4:	e456                	sd	s5,8(sp)
    800024e6:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800024e8:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024ec:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800024f0:	14202a73          	csrr	s4,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    800024f4:	14302af3          	csrr	s5,stval
    proc_t* p = myproc();
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	fca080e7          	jalr	-54(ra) # 800014c2 <myproc>
    if(sstatus & SSTATUS_SPP)
    80002500:	10097913          	and	s2,s2,256
    80002504:	04091b63          	bnez	s2,8000255a <trap_user_handler+0x84>
    80002508:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000250a:	00000797          	auipc	a5,0x0
    8000250e:	72678793          	add	a5,a5,1830 # 80002c30 <kernelvec>
    80002512:	10579073          	csrw	stvec,a5
  p->tf->epc = sepc;
    80002516:	6d3c                	ld	a5,88(a0)
    80002518:	0137bc23          	sd	s3,24(a5)
  if(scause == 8){
    8000251c:	47a1                	li	a5,8
    8000251e:	04fa0663          	beq	s4,a5,8000256a <trap_user_handler+0x94>
  } else if((which_dev = devintr()) != 0){
    80002522:	00000097          	auipc	ra,0x0
    80002526:	c3c080e7          	jalr	-964(ra) # 8000215e <devintr>
    8000252a:	892a                	mv	s2,a0
    8000252c:	c549                	beqz	a0,800025b6 <trap_user_handler+0xe0>
  if(killed(p))
    8000252e:	8526                	mv	a0,s1
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	7fa080e7          	jalr	2042(ra) # 80001d2a <killed>
    80002538:	e13d                	bnez	a0,8000259e <trap_user_handler+0xc8>
  if(which_dev == 2)
    8000253a:	4789                	li	a5,2
    8000253c:	0af90963          	beq	s2,a5,800025ee <trap_user_handler+0x118>
  trap_user_return();
    80002540:	00000097          	auipc	ra,0x0
    80002544:	f00080e7          	jalr	-256(ra) # 80002440 <trap_user_return>
}
    80002548:	70e2                	ld	ra,56(sp)
    8000254a:	7442                	ld	s0,48(sp)
    8000254c:	74a2                	ld	s1,40(sp)
    8000254e:	7902                	ld	s2,32(sp)
    80002550:	69e2                	ld	s3,24(sp)
    80002552:	6a42                	ld	s4,16(sp)
    80002554:	6aa2                	ld	s5,8(sp)
    80002556:	6121                	add	sp,sp,64
    80002558:	8082                	ret
        panic("trap_user_handler: not from u-mode");
    8000255a:	00002517          	auipc	a0,0x2
    8000255e:	f8e50513          	add	a0,a0,-114 # 800044e8 <digits+0x468>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	208080e7          	jalr	520(ra) # 8000076a <panic>
    if(killed(p))
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	7c0080e7          	jalr	1984(ra) # 80001d2a <killed>
    80002572:	ed05                	bnez	a0,800025aa <trap_user_handler+0xd4>
    p->tf->epc += 4;
    80002574:	6cb8                	ld	a4,88(s1)
    80002576:	6f1c                	ld	a5,24(a4)
    80002578:	0791                	add	a5,a5,4
    8000257a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000257c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002580:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002584:	10079073          	csrw	sstatus,a5
    syscall();
    80002588:	00000097          	auipc	ra,0x0
    8000258c:	0d8080e7          	jalr	216(ra) # 80002660 <syscall>
  if(killed(p))
    80002590:	8526                	mv	a0,s1
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	798080e7          	jalr	1944(ra) # 80001d2a <killed>
    8000259a:	d15d                	beqz	a0,80002540 <trap_user_handler+0x6a>
    int which_dev = 0;  // 用于标识设备中断类型
    8000259c:	4901                	li	s2,0
    exit(-1);
    8000259e:	557d                	li	a0,-1
    800025a0:	00000097          	auipc	ra,0x0
    800025a4:	962080e7          	jalr	-1694(ra) # 80001f02 <exit>
    800025a8:	bf49                	j	8000253a <trap_user_handler+0x64>
      exit(-1);
    800025aa:	557d                	li	a0,-1
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	956080e7          	jalr	-1706(ra) # 80001f02 <exit>
    800025b4:	b7c1                	j	80002574 <trap_user_handler+0x9e>
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    800025b6:	4090                	lw	a2,0(s1)
    800025b8:	85d2                	mv	a1,s4
    800025ba:	00002517          	auipc	a0,0x2
    800025be:	f5650513          	add	a0,a0,-170 # 80004510 <digits+0x490>
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	1f2080e7          	jalr	498(ra) # 800007b4 <printf>
    printf("            sepc=%p stval=%p\n", sepc, stval);
    800025ca:	8656                	mv	a2,s5
    800025cc:	85ce                	mv	a1,s3
    800025ce:	00002517          	auipc	a0,0x2
    800025d2:	f7250513          	add	a0,a0,-142 # 80004540 <digits+0x4c0>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	1de080e7          	jalr	478(ra) # 800007b4 <printf>
    panic("usertrap");
    800025de:	00002517          	auipc	a0,0x2
    800025e2:	f8250513          	add	a0,a0,-126 # 80004560 <digits+0x4e0>
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	184080e7          	jalr	388(ra) # 8000076a <panic>
    yield();  // 让出 CPU，调度其他进程
    800025ee:	00000097          	auipc	ra,0x0
    800025f2:	e0c080e7          	jalr	-500(ra) # 800023fa <yield>
    800025f6:	b7a9                	j	80002540 <trap_user_handler+0x6a>

00000000800025f8 <arg_raw>:
    第二种使用uvm_copyin 和 uvm_copyinstr 进行传递
*/

// 读取 n 号参数,它放在 an 寄存器中
static uint64 arg_raw(int n)
{   
    800025f8:	1101                	add	sp,sp,-32
    800025fa:	ec06                	sd	ra,24(sp)
    800025fc:	e822                	sd	s0,16(sp)
    800025fe:	e426                	sd	s1,8(sp)
    80002600:	1000                	add	s0,sp,32
    80002602:	84aa                	mv	s1,a0
    proc_t* proc = myproc();
    80002604:	fffff097          	auipc	ra,0xfffff
    80002608:	ebe080e7          	jalr	-322(ra) # 800014c2 <myproc>
    switch(n) {
    8000260c:	4795                	li	a5,5
    8000260e:	0497e163          	bltu	a5,s1,80002650 <arg_raw+0x58>
    80002612:	048a                	sll	s1,s1,0x2
    80002614:	00002717          	auipc	a4,0x2
    80002618:	f9c70713          	add	a4,a4,-100 # 800045b0 <digits+0x530>
    8000261c:	94ba                	add	s1,s1,a4
    8000261e:	409c                	lw	a5,0(s1)
    80002620:	97ba                	add	a5,a5,a4
    80002622:	8782                	jr	a5
        case 0:
            return proc->tf->a0;
    80002624:	6d3c                	ld	a5,88(a0)
    80002626:	7ba8                	ld	a0,112(a5)
            return proc->tf->a5;
        default:
            panic("arg_raw: illegal arg num");
            return -1;
    }
}
    80002628:	60e2                	ld	ra,24(sp)
    8000262a:	6442                	ld	s0,16(sp)
    8000262c:	64a2                	ld	s1,8(sp)
    8000262e:	6105                	add	sp,sp,32
    80002630:	8082                	ret
            return proc->tf->a1;
    80002632:	6d3c                	ld	a5,88(a0)
    80002634:	7fa8                	ld	a0,120(a5)
    80002636:	bfcd                	j	80002628 <arg_raw+0x30>
            return proc->tf->a2;
    80002638:	6d3c                	ld	a5,88(a0)
    8000263a:	63c8                	ld	a0,128(a5)
    8000263c:	b7f5                	j	80002628 <arg_raw+0x30>
            return proc->tf->a3;
    8000263e:	6d3c                	ld	a5,88(a0)
    80002640:	67c8                	ld	a0,136(a5)
    80002642:	b7dd                	j	80002628 <arg_raw+0x30>
            return proc->tf->a4;
    80002644:	6d3c                	ld	a5,88(a0)
    80002646:	6bc8                	ld	a0,144(a5)
    80002648:	b7c5                	j	80002628 <arg_raw+0x30>
            return proc->tf->a5;
    8000264a:	6d3c                	ld	a5,88(a0)
    8000264c:	6fc8                	ld	a0,152(a5)
    8000264e:	bfe9                	j	80002628 <arg_raw+0x30>
            panic("arg_raw: illegal arg num");
    80002650:	00002517          	auipc	a0,0x2
    80002654:	f2050513          	add	a0,a0,-224 # 80004570 <digits+0x4f0>
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	112080e7          	jalr	274(ra) # 8000076a <panic>

0000000080002660 <syscall>:
{
    80002660:	1101                	add	sp,sp,-32
    80002662:	ec06                	sd	ra,24(sp)
    80002664:	e822                	sd	s0,16(sp)
    80002666:	e426                	sd	s1,8(sp)
    80002668:	e04a                	sd	s2,0(sp)
    8000266a:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	e56080e7          	jalr	-426(ra) # 800014c2 <myproc>
    80002674:	84aa                	mv	s1,a0
    num = p->tf->a7;
    80002676:	05853903          	ld	s2,88(a0)
    8000267a:	0a892603          	lw	a2,168(s2)
    if(num >= 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000267e:	47dd                	li	a5,23
    80002680:	00c7ef63          	bltu	a5,a2,8000269e <syscall+0x3e>
    80002684:	00361713          	sll	a4,a2,0x3
    80002688:	00002797          	auipc	a5,0x2
    8000268c:	f4078793          	add	a5,a5,-192 # 800045c8 <syscalls>
    80002690:	97ba                	add	a5,a5,a4
    80002692:	639c                	ld	a5,0(a5)
    80002694:	c789                	beqz	a5,8000269e <syscall+0x3e>
        p->tf->a0 = syscalls[num]();
    80002696:	9782                	jalr	a5
    80002698:	06a93823          	sd	a0,112(s2)
    8000269c:	a829                	j	800026b6 <syscall+0x56>
        printf("pid %d: unknown sys call %d\n",
    8000269e:	408c                	lw	a1,0(s1)
    800026a0:	00002517          	auipc	a0,0x2
    800026a4:	ef050513          	add	a0,a0,-272 # 80004590 <digits+0x510>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	10c080e7          	jalr	268(ra) # 800007b4 <printf>
        p->tf->a0 = -1;
    800026b0:	6cbc                	ld	a5,88(s1)
    800026b2:	577d                	li	a4,-1
    800026b4:	fbb8                	sd	a4,112(a5)
}
    800026b6:	60e2                	ld	ra,24(sp)
    800026b8:	6442                	ld	s0,16(sp)
    800026ba:	64a2                	ld	s1,8(sp)
    800026bc:	6902                	ld	s2,0(sp)
    800026be:	6105                	add	sp,sp,32
    800026c0:	8082                	ret

00000000800026c2 <arg_uint32>:

// 读取 n 号参数, 作为 uint32 存储
void arg_uint32(int n, uint32* ip)
{
    800026c2:	1101                	add	sp,sp,-32
    800026c4:	ec06                	sd	ra,24(sp)
    800026c6:	e822                	sd	s0,16(sp)
    800026c8:	e426                	sd	s1,8(sp)
    800026ca:	1000                	add	s0,sp,32
    800026cc:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    800026ce:	00000097          	auipc	ra,0x0
    800026d2:	f2a080e7          	jalr	-214(ra) # 800025f8 <arg_raw>
    800026d6:	c088                	sw	a0,0(s1)
}
    800026d8:	60e2                	ld	ra,24(sp)
    800026da:	6442                	ld	s0,16(sp)
    800026dc:	64a2                	ld	s1,8(sp)
    800026de:	6105                	add	sp,sp,32
    800026e0:	8082                	ret

00000000800026e2 <arg_uint64>:

// 读取 n 号参数, 作为 uint64 存储
void arg_uint64(int n, uint64* ip)
{
    800026e2:	1101                	add	sp,sp,-32
    800026e4:	ec06                	sd	ra,24(sp)
    800026e6:	e822                	sd	s0,16(sp)
    800026e8:	e426                	sd	s1,8(sp)
    800026ea:	1000                	add	s0,sp,32
    800026ec:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    800026ee:	00000097          	auipc	ra,0x0
    800026f2:	f0a080e7          	jalr	-246(ra) # 800025f8 <arg_raw>
    800026f6:	e088                	sd	a0,0(s1)
}
    800026f8:	60e2                	ld	ra,24(sp)
    800026fa:	6442                	ld	s0,16(sp)
    800026fc:	64a2                	ld	s1,8(sp)
    800026fe:	6105                	add	sp,sp,32
    80002700:	8082                	ret

0000000080002702 <arg_str>:

// 读取 n 号参数指向的字符串到 buf, 字符串最大长度是 maxlen
void arg_str(int n, char* buf, int maxlen)
{
    80002702:	7139                	add	sp,sp,-64
    80002704:	fc06                	sd	ra,56(sp)
    80002706:	f822                	sd	s0,48(sp)
    80002708:	f426                	sd	s1,40(sp)
    8000270a:	f04a                	sd	s2,32(sp)
    8000270c:	ec4e                	sd	s3,24(sp)
    8000270e:	e852                	sd	s4,16(sp)
    80002710:	0080                	add	s0,sp,64
    80002712:	8a2a                	mv	s4,a0
    80002714:	892e                	mv	s2,a1
    80002716:	89b2                	mv	s3,a2
    proc_t* p = myproc();
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	daa080e7          	jalr	-598(ra) # 800014c2 <myproc>
    80002720:	84aa                	mv	s1,a0
    uint64 addr;
    arg_uint64(n, &addr);
    80002722:	fc840593          	add	a1,s0,-56
    80002726:	8552                	mv	a0,s4
    80002728:	00000097          	auipc	ra,0x0
    8000272c:	fba080e7          	jalr	-70(ra) # 800026e2 <arg_uint64>

    uvm_copyin_str(p->pgtbl, (uint64)buf, addr, maxlen);
    80002730:	86ce                	mv	a3,s3
    80002732:	fc843603          	ld	a2,-56(s0)
    80002736:	85ca                	mv	a1,s2
    80002738:	64a8                	ld	a0,72(s1)
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	c6a080e7          	jalr	-918(ra) # 800013a4 <uvm_copyin_str>
    80002742:	70e2                	ld	ra,56(sp)
    80002744:	7442                	ld	s0,48(sp)
    80002746:	74a2                	ld	s1,40(sp)
    80002748:	7902                	ld	s2,32(sp)
    8000274a:	69e2                	ld	s3,24(sp)
    8000274c:	6a42                	ld	s4,16(sp)
    8000274e:	6121                	add	sp,sp,64
    80002750:	8082                	ret

0000000080002752 <sys_brk>:

// 堆伸缩
// uint64 new_heap_top 新的堆顶 (如果是0代表查询, 返回旧的堆顶)
// 成功返回新的堆顶 失败返回-1
uint64 sys_brk()
{
    80002752:	7179                	add	sp,sp,-48
    80002754:	f406                	sd	ra,40(sp)
    80002756:	f022                	sd	s0,32(sp)
    80002758:	ec26                	sd	s1,24(sp)
    8000275a:	1800                	add	s0,sp,48
    uint64 new_addr;
    uint64 old_addr = myproc()->sz;  // 保存原始堆顶
    8000275c:	fffff097          	auipc	ra,0xfffff
    80002760:	d66080e7          	jalr	-666(ra) # 800014c2 <myproc>
    80002764:	7124                	ld	s1,96(a0)

    arg_uint64(0, &new_addr);  // 正确读取64位地址
    80002766:	fd840593          	add	a1,s0,-40
    8000276a:	4501                	li	a0,0
    8000276c:	00000097          	auipc	ra,0x0
    80002770:	f76080e7          	jalr	-138(ra) # 800026e2 <arg_uint64>
    
    if(new_addr == old_addr || new_addr == 0) {
    80002774:	fd843783          	ld	a5,-40(s0)
    80002778:	00978963          	beq	a5,s1,8000278a <sys_brk+0x38>
    8000277c:	c799                	beqz	a5,8000278a <sys_brk+0x38>
        return old_addr;  // 无变化，返回当前堆顶
    }
    
    int diff = (int)(new_addr - old_addr);
    8000277e:	4097853b          	subw	a0,a5,s1
    
    // 检查是否溢出
    if((uint64)diff != (new_addr - old_addr)) {
    80002782:	8f85                	sub	a5,a5,s1
        return -1;  // 差值太大，int无法表示
    80002784:	54fd                	li	s1,-1
    if((uint64)diff != (new_addr - old_addr)) {
    80002786:	00f50863          	beq	a0,a5,80002796 <sys_brk+0x44>
    if(growproc(diff) < 0) {
        return -1;  // 扩展失败
    }
    
    return new_addr;  // 返回扩展前的地址
}
    8000278a:	8526                	mv	a0,s1
    8000278c:	70a2                	ld	ra,40(sp)
    8000278e:	7402                	ld	s0,32(sp)
    80002790:	64e2                	ld	s1,24(sp)
    80002792:	6145                	add	sp,sp,48
    80002794:	8082                	ret
    if(growproc(diff) < 0) {
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	1d4080e7          	jalr	468(ra) # 8000196a <growproc>
    8000279e:	00054563          	bltz	a0,800027a8 <sys_brk+0x56>
    return new_addr;  // 返回扩展前的地址
    800027a2:	fd843483          	ld	s1,-40(s0)
    800027a6:	b7d5                	j	8000278a <sys_brk+0x38>
        return -1;  // 扩展失败
    800027a8:	54fd                	li	s1,-1
    800027aa:	b7c5                	j	8000278a <sys_brk+0x38>

00000000800027ac <sys_kill>:

uint64
sys_kill(void)
{
    800027ac:	1101                	add	sp,sp,-32
    800027ae:	ec06                	sd	ra,24(sp)
    800027b0:	e822                	sd	s0,16(sp)
    800027b2:	1000                	add	s0,sp,32
  uint64 pid;

  arg_uint64(0, &pid);
    800027b4:	fe840593          	add	a1,s0,-24
    800027b8:	4501                	li	a0,0
    800027ba:	00000097          	auipc	ra,0x0
    800027be:	f28080e7          	jalr	-216(ra) # 800026e2 <arg_uint64>
  return kill(pid);
    800027c2:	fe842503          	lw	a0,-24(s0)
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	4b4080e7          	jalr	1204(ra) # 80001c7a <kill>
}
    800027ce:	60e2                	ld	ra,24(sp)
    800027d0:	6442                	ld	s0,16(sp)
    800027d2:	6105                	add	sp,sp,32
    800027d4:	8082                	ret

00000000800027d6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800027d6:	1141                	add	sp,sp,-16
    800027d8:	e406                	sd	ra,8(sp)
    800027da:	e022                	sd	s0,0(sp)
    800027dc:	0800                	add	s0,sp,16
  return myproc()->pid;
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	ce4080e7          	jalr	-796(ra) # 800014c2 <myproc>
}
    800027e6:	4108                	lw	a0,0(a0)
    800027e8:	60a2                	ld	ra,8(sp)
    800027ea:	6402                	ld	s0,0(sp)
    800027ec:	0141                	add	sp,sp,16
    800027ee:	8082                	ret

00000000800027f0 <sys_print>:
// 打印字符
// uint64 addr
uint64 sys_print()
{
    800027f0:	7175                	add	sp,sp,-144
    800027f2:	e506                	sd	ra,136(sp)
    800027f4:	e122                	sd	s0,128(sp)
    800027f6:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    800027f8:	08000613          	li	a2,128
    800027fc:	f7040593          	add	a1,s0,-144
    80002800:	4501                	li	a0,0
    80002802:	00000097          	auipc	ra,0x0
    80002806:	f00080e7          	jalr	-256(ra) # 80002702 <arg_str>

    printf("%s", buf);
    8000280a:	f7040593          	add	a1,s0,-144
    8000280e:	00002517          	auipc	a0,0x2
    80002812:	e7a50513          	add	a0,a0,-390 # 80004688 <syscalls+0xc0>
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	f9e080e7          	jalr	-98(ra) # 800007b4 <printf>
    return 0;
}
    8000281e:	4501                	li	a0,0
    80002820:	60aa                	ld	ra,136(sp)
    80002822:	640a                	ld	s0,128(sp)
    80002824:	6149                	add	sp,sp,144
    80002826:	8082                	ret

0000000080002828 <sys_fork>:

// 进程复制
uint64 sys_fork()
{
    80002828:	1141                	add	sp,sp,-16
    8000282a:	e406                	sd	ra,8(sp)
    8000282c:	e022                	sd	s0,0(sp)
    8000282e:	0800                	add	s0,sp,16
    return fork();
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	26c080e7          	jalr	620(ra) # 80001a9c <fork>
}
    80002838:	60a2                	ld	ra,8(sp)
    8000283a:	6402                	ld	s0,0(sp)
    8000283c:	0141                	add	sp,sp,16
    8000283e:	8082                	ret

0000000080002840 <sys_wait>:

// 进程等待
// uint64 addr  子进程退出时的exit_state需要放到这里 
uint64 sys_wait()
{
    80002840:	1101                	add	sp,sp,-32
    80002842:	ec06                	sd	ra,24(sp)
    80002844:	e822                	sd	s0,16(sp)
    80002846:	1000                	add	s0,sp,32
    uint64 p;
    arg_uint64(0, &p);
    80002848:	fe840593          	add	a1,s0,-24
    8000284c:	4501                	li	a0,0
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	e94080e7          	jalr	-364(ra) # 800026e2 <arg_uint64>
    return wait(p);
    80002856:	fe843503          	ld	a0,-24(s0)
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	506080e7          	jalr	1286(ra) # 80001d60 <wait>
}
    80002862:	60e2                	ld	ra,24(sp)
    80002864:	6442                	ld	s0,16(sp)
    80002866:	6105                	add	sp,sp,32
    80002868:	8082                	ret

000000008000286a <sys_exit>:

// 进程退出
// int exit_state
uint64 sys_exit()
{
    8000286a:	1101                	add	sp,sp,-32
    8000286c:	ec06                	sd	ra,24(sp)
    8000286e:	e822                	sd	s0,16(sp)
    80002870:	1000                	add	s0,sp,32
    uint64 n;
    arg_uint64(0, &n);
    80002872:	fe840593          	add	a1,s0,-24
    80002876:	4501                	li	a0,0
    80002878:	00000097          	auipc	ra,0x0
    8000287c:	e6a080e7          	jalr	-406(ra) # 800026e2 <arg_uint64>
    exit(n);
    80002880:	fe842503          	lw	a0,-24(s0)
    80002884:	fffff097          	auipc	ra,0xfffff
    80002888:	67e080e7          	jalr	1662(ra) # 80001f02 <exit>
    return 0;  // not reached
}
    8000288c:	4501                	li	a0,0
    8000288e:	60e2                	ld	ra,24(sp)
    80002890:	6442                	ld	s0,16(sp)
    80002892:	6105                	add	sp,sp,32
    80002894:	8082                	ret

0000000080002896 <sys_sleep>:

// 进程睡眠一段时间
// uint32 second 睡眠时间
// 成功返回0, 失败返回-1
uint64 sys_sleep()
{
    80002896:	7139                	add	sp,sp,-64
    80002898:	fc06                	sd	ra,56(sp)
    8000289a:	f822                	sd	s0,48(sp)
    8000289c:	f426                	sd	s1,40(sp)
    8000289e:	f04a                	sd	s2,32(sp)
    800028a0:	ec4e                	sd	s3,24(sp)
    800028a2:	0080                	add	s0,sp,64
    uint64 n;
    uint ticks0;

    arg_uint64(0, &n);
    800028a4:	fc840593          	add	a1,s0,-56
    800028a8:	4501                	li	a0,0
    800028aa:	00000097          	auipc	ra,0x0
    800028ae:	e38080e7          	jalr	-456(ra) # 800026e2 <arg_uint64>
    acquire(& sys_timer.lk);
    800028b2:	0000a517          	auipc	a0,0xa
    800028b6:	f9650513          	add	a0,a0,-106 # 8000c848 <sys_timer+0x8>
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	76a080e7          	jalr	1898(ra) # 80002024 <acquire>
    ticks0 = sys_timer.ticks;
    800028c2:	0000a797          	auipc	a5,0xa
    800028c6:	f7e7b783          	ld	a5,-130(a5) # 8000c840 <sys_timer>
    while(sys_timer.ticks - ticks0 < n){
    800028ca:	02079913          	sll	s2,a5,0x20
    800028ce:	02095913          	srl	s2,s2,0x20
    800028d2:	412787b3          	sub	a5,a5,s2
    800028d6:	fc843703          	ld	a4,-56(s0)
    800028da:	04e7f063          	bgeu	a5,a4,8000291a <sys_sleep+0x84>
        if(killed(myproc())){
        release(&sys_timer.lk);
        return -1;
        }
        sleep(&sys_timer.ticks, &sys_timer.lk);
    800028de:	0000a997          	auipc	s3,0xa
    800028e2:	f6a98993          	add	s3,s3,-150 # 8000c848 <sys_timer+0x8>
    800028e6:	0000a497          	auipc	s1,0xa
    800028ea:	f5a48493          	add	s1,s1,-166 # 8000c840 <sys_timer>
        if(killed(myproc())){
    800028ee:	fffff097          	auipc	ra,0xfffff
    800028f2:	bd4080e7          	jalr	-1068(ra) # 800014c2 <myproc>
    800028f6:	fffff097          	auipc	ra,0xfffff
    800028fa:	434080e7          	jalr	1076(ra) # 80001d2a <killed>
    800028fe:	ed15                	bnez	a0,8000293a <sys_sleep+0xa4>
        sleep(&sys_timer.ticks, &sys_timer.lk);
    80002900:	85ce                	mv	a1,s3
    80002902:	8526                	mv	a0,s1
    80002904:	fffff097          	auipc	ra,0xfffff
    80002908:	28a080e7          	jalr	650(ra) # 80001b8e <sleep>
    while(sys_timer.ticks - ticks0 < n){
    8000290c:	609c                	ld	a5,0(s1)
    8000290e:	412787b3          	sub	a5,a5,s2
    80002912:	fc843703          	ld	a4,-56(s0)
    80002916:	fce7ece3          	bltu	a5,a4,800028ee <sys_sleep+0x58>
    }
    release(& sys_timer.lk);
    8000291a:	0000a517          	auipc	a0,0xa
    8000291e:	f2e50513          	add	a0,a0,-210 # 8000c848 <sys_timer+0x8>
    80002922:	fffff097          	auipc	ra,0xfffff
    80002926:	7b6080e7          	jalr	1974(ra) # 800020d8 <release>
    return 0;
    8000292a:	4501                	li	a0,0
}
    8000292c:	70e2                	ld	ra,56(sp)
    8000292e:	7442                	ld	s0,48(sp)
    80002930:	74a2                	ld	s1,40(sp)
    80002932:	7902                	ld	s2,32(sp)
    80002934:	69e2                	ld	s3,24(sp)
    80002936:	6121                	add	sp,sp,64
    80002938:	8082                	ret
        release(&sys_timer.lk);
    8000293a:	0000a517          	auipc	a0,0xa
    8000293e:	f0e50513          	add	a0,a0,-242 # 8000c848 <sys_timer+0x8>
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	796080e7          	jalr	1942(ra) # 800020d8 <release>
        return -1;
    8000294a:	557d                	li	a0,-1
    8000294c:	b7c5                	j	8000292c <sys_sleep+0x96>

000000008000294e <sys_debug>:


uint64 sys_debug(void)
{
    8000294e:	7175                	add	sp,sp,-144
    80002950:	e506                	sd	ra,136(sp)
    80002952:	e122                	sd	s0,128(sp)
    80002954:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    80002956:	08000613          	li	a2,128
    8000295a:	f7040593          	add	a1,s0,-144
    8000295e:	4501                	li	a0,0
    80002960:	00000097          	auipc	ra,0x0
    80002964:	da2080e7          	jalr	-606(ra) # 80002702 <arg_str>

    printf("[debug] %s \n", buf);
    80002968:	f7040593          	add	a1,s0,-144
    8000296c:	00002517          	auipc	a0,0x2
    80002970:	d2450513          	add	a0,a0,-732 # 80004690 <syscalls+0xc8>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	e40080e7          	jalr	-448(ra) # 800007b4 <printf>
    return 0;
}
    8000297c:	4501                	li	a0,0
    8000297e:	60aa                	ld	ra,136(sp)
    80002980:	640a                	ld	s0,128(sp)
    80002982:	6149                	add	sp,sp,144
    80002984:	8082                	ret

0000000080002986 <initcode_start>:
    80002986:	00000097          	.word	0x00000097
    8000298a:	0bc080e7          	.word	0x0bc080e7
    8000298e:	0000a001          	.word	0x0000a001
    80002992:	ff010113          	.word	0xff010113
    80002996:	00813423          	.word	0x00813423
    8000299a:	01010413          	.word	0x01010413
    8000299e:	00000313          	.word	0x00000313
    800029a2:	08054a63          	.word	0x08054a63
    800029a6:	00058693          	.word	0x00058693
    800029aa:	00058613          	.word	0x00058613
    800029ae:	00000793          	.word	0x00000793
    800029b2:	00a00813          	.word	0x00a00813
    800029b6:	00078893          	.word	0x00078893
    800029ba:	0017879b          	.word	0x0017879b
    800029be:	0305673b          	.word	0x0305673b
    800029c2:	0307071b          	.word	0x0307071b
    800029c6:	00e60023          	.word	0x00e60023
    800029ca:	0305453b          	.word	0x0305453b
    800029ce:	00160613          	.word	0x00160613
    800029d2:	fe0512e3          	.word	0xfe0512e3
    800029d6:	00030a63          	.word	0x00030a63
    800029da:	00f587b3          	.word	0x00f587b3
    800029de:	02d00713          	.word	0x02d00713
    800029e2:	00e78023          	.word	0x00e78023
    800029e6:	0028879b          	.word	0x0028879b
    800029ea:	00f58733          	.word	0x00f58733
    800029ee:	00070023          	.word	0x00070023
    800029f2:	fff7871b          	.word	0xfff7871b
    800029f6:	02e05a63          	.word	0x02e05a63
    800029fa:	00e585b3          	.word	0x00e585b3
    800029fe:	fff7879b          	.word	0xfff7879b
    80002a02:	0006c703          	.word	0x0006c703
    80002a06:	0005c603          	.word	0x0005c603
    80002a0a:	00c68023          	.word	0x00c68023
    80002a0e:	00e58023          	.word	0x00e58023
    80002a12:	0015071b          	.word	0x0015071b
    80002a16:	0007051b          	.word	0x0007051b
    80002a1a:	00168693          	.word	0x00168693
    80002a1e:	fff58593          	.word	0xfff58593
    80002a22:	40e7873b          	.word	0x40e7873b
    80002a26:	fce54ee3          	.word	0xfce54ee3
    80002a2a:	00813403          	.word	0x00813403
    80002a2e:	01010113          	.word	0x01010113
    80002a32:	00008067          	.word	0x00008067
    80002a36:	40a0053b          	.word	0x40a0053b
    80002a3a:	00100313          	.word	0x00100313
    80002a3e:	f69ff06f          	.word	0xf69ff06f
    80002a42:	00000893          	.word	0x00000893
    80002a46:	00000517          	.word	0x00000517
    80002a4a:	12050513          	.word	0x12050513
    80002a4e:	00000073          	.word	0x00000073
    80002a52:	00100893          	.word	0x00100893
    80002a56:	00000513          	.word	0x00000513
    80002a5a:	00000073          	.word	0x00000073
    80002a5e:	00000797          	.word	0x00000797
    80002a62:	16078793          	.word	0x16078793
    80002a66:	00a7b023          	.word	0x00a7b023
    80002a6a:	00001737          	.word	0x00001737
    80002a6e:	00e50533          	.word	0x00e50533
    80002a72:	00000073          	.word	0x00000073
    80002a76:	0007b703          	.word	0x0007b703
    80002a7a:	04800693          	.word	0x04800693
    80002a7e:	00d70023          	.word	0x00d70023
    80002a82:	0007b703          	.word	0x0007b703
    80002a86:	04500693          	.word	0x04500693
    80002a8a:	00d700a3          	.word	0x00d700a3
    80002a8e:	0007b703          	.word	0x0007b703
    80002a92:	04100693          	.word	0x04100693
    80002a96:	00d70123          	.word	0x00d70123
    80002a9a:	0007b703          	.word	0x0007b703
    80002a9e:	05000693          	.word	0x05000693
    80002aa2:	00d701a3          	.word	0x00d701a3
    80002aa6:	0007b703          	.word	0x0007b703
    80002aaa:	00a00693          	.word	0x00a00693
    80002aae:	00d70223          	.word	0x00d70223
    80002ab2:	0007b783          	.word	0x0007b783
    80002ab6:	000782a3          	.word	0x000782a3
    80002aba:	00400893          	.word	0x00400893
    80002abe:	00000073          	.word	0x00000073
    80002ac2:	0005079b          	.word	0x0005079b
    80002ac6:	04079a63          	.word	0x04079a63
    80002aca:	05f5e7b7          	.word	0x05f5e7b7
    80002ace:	10078793          	.word	0x10078793
    80002ad2:	fff7879b          	.word	0xfff7879b
    80002ad6:	fe079ee3          	.word	0xfe079ee3
    80002ada:	00000893          	.word	0x00000893
    80002ade:	00000517          	.word	0x00000517
    80002ae2:	09850513          	.word	0x09850513
    80002ae6:	00000073          	.word	0x00000073
    80002aea:	00000517          	.word	0x00000517
    80002aee:	0d453503          	.word	0x0d453503
    80002af2:	00000073          	.word	0x00000073
    80002af6:	00300893          	.word	0x00300893
    80002afa:	00000073          	.word	0x00000073
    80002afe:	00200893          	.word	0x00200893
    80002b02:	00000073          	.word	0x00000073
    80002b06:	00000893          	.word	0x00000893
    80002b0a:	00000517          	.word	0x00000517
    80002b0e:	07c50513          	.word	0x07c50513
    80002b12:	00000073          	.word	0x00000073
    80002b16:	0000006f          	.word	0x0000006f
    80002b1a:	fe010113          	.word	0xfe010113
    80002b1e:	00813c23          	.word	0x00813c23
    80002b22:	02010413          	.word	0x02010413
    80002b26:	00500893          	.word	0x00500893
    80002b2a:	fec40513          	.word	0xfec40513
    80002b2e:	00000073          	.word	0x00000073
    80002b32:	fec42703          	.word	0xfec42703
    80002b36:	00100793          	.word	0x00100793
    80002b3a:	00f70c63          	.word	0x00f70c63
    80002b3e:	00000893          	.word	0x00000893
    80002b42:	00000517          	.word	0x00000517
    80002b46:	06c50513          	.word	0x06c50513
    80002b4a:	00000073          	.word	0x00000073
    80002b4e:	0000006f          	.word	0x0000006f
    80002b52:	00000893          	.word	0x00000893
    80002b56:	00000517          	.word	0x00000517
    80002b5a:	04850513          	.word	0x04850513
    80002b5e:	00000073          	.word	0x00000073
    80002b62:	fedff06f          	.word	0xfedff06f
    80002b66:	6573750a          	.word	0x6573750a
    80002b6a:	65622072          	.word	0x65622072
    80002b6e:	0a6e6967          	.word	0x0a6e6967
    80002b72:	00000000          	.word	0x00000000
    80002b76:	6c696863          	.word	0x6c696863
    80002b7a:	68203a64          	.word	0x68203a64
    80002b7e:	6f6c6c65          	.word	0x6f6c6c65
    80002b82:	0000000a          	.word	0x0000000a
    80002b86:	6c696863          	.word	0x6c696863
    80002b8a:	6e203a64          	.word	0x6e203a64
    80002b8e:	72657665          	.word	0x72657665
    80002b92:	63616220          	.word	0x63616220
    80002b96:	00000a6b          	.word	0x00000a6b
    80002b9a:	00000000          	.word	0x00000000
    80002b9e:	65726170          	.word	0x65726170
    80002ba2:	203a746e          	.word	0x203a746e
    80002ba6:	6c6c6568          	.word	0x6c6c6568
    80002baa:	00000a6f          	.word	0x00000a6f
    80002bae:	65726170          	.word	0x65726170
    80002bb2:	203a746e          	.word	0x203a746e
    80002bb6:	6f727265          	.word	0x6f727265
    80002bba:	0a72                	.short	0x0a72
	...

0000000080002bbd <initcode_end>:
	...

0000000080002bbe <swtch>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    80002bbe:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    80002bc2:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    80002bc6:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    80002bc8:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    80002bca:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    80002bce:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    80002bd2:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    80002bd6:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    80002bda:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    80002bde:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    80002be2:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    80002be6:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    80002bea:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    80002bee:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    80002bf2:	0005b083          	ld	ra,0(a1) # 1000 <_entry-0x7ffff000>
        ld sp, 8(a1)      # 恢复栈指针
    80002bf6:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    80002bfa:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    80002bfc:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    80002bfe:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    80002c02:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    80002c06:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    80002c0a:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    80002c0e:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    80002c12:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    80002c16:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    80002c1a:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    80002c1e:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    80002c22:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    80002c26:	8082                	ret
	...

0000000080002c30 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    80002c30:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    80002c32:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80002c34:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80002c36:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80002c38:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80002c3a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    80002c3c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    80002c3e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    80002c40:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    80002c42:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    80002c44:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80002c46:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80002c48:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80002c4a:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80002c4c:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80002c4e:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    80002c50:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    80002c52:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    80002c54:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    80002c56:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    80002c58:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    80002c5a:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    80002c5c:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    80002c5e:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    80002c60:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    80002c62:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    80002c64:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    80002c66:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    80002c68:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80002c6a:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80002c6c:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80002c6e:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	584080e7          	jalr	1412(ra) # 800021f4 <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    80002c78:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    80002c7a:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    80002c7c:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    80002c7e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80002c80:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80002c82:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    80002c84:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    80002c86:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    80002c88:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80002c8a:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80002c8c:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    80002c8e:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    80002c90:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    80002c92:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80002c94:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80002c96:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    80002c98:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    80002c9a:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    80002c9c:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    80002c9e:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    80002ca0:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    80002ca2:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    80002ca4:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    80002ca6:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    80002ca8:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    80002caa:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    80002cac:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80002cae:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80002cb0:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80002cb2:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    80002cb4:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    80002cb6:	10200073          	sret
    80002cba:	0001                	nop
    80002cbc:	00000013          	nop

0000000080002cc0 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    80002cc0:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    80002cc4:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    80002cc6:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    80002cc8:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    80002cca:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    80002ccc:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    80002cce:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    80002cd0:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    80002cd2:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    80002cd4:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    80002cd6:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    80002cda:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    80002cdc:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    80002cde:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80002ce0:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    80002ce4:	30200073          	mret
    80002ce8:	00000013          	nop
    80002cec:	00000013          	nop
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
