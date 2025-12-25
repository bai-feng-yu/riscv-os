
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
.global _entry
_entry:
    # 为C语言代码设置栈空间
    # stack0声明在start.c中，每个CPU分配4096字节的栈空间
    # 计算公式: sp = stack0基地址 + (硬件线程ID * 4096)
    la sp, stack0        # 加载stack0的基地址到栈指针sp
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	e4010113          	add	sp,sp,-448 # 80009e40 <stack0>
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
    80000016:	0000a517          	auipc	a0,0xa
    8000001a:	dda50513          	add	a0,a0,-550 # 80009df0 <started>
    la a1, end
    8000001e:	00023597          	auipc	a1,0x23
    80000022:	29a58593          	add	a1,a1,666 # 800232b8 <end>

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
    80000046:	0f6080e7          	jalr	246(ra) # 80002138 <cpuid>
    started = 1;         // 标记系统启动完成
    __sync_synchronize();

  } else {
    //其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000004a:	0000a717          	auipc	a4,0xa
    8000004e:	da670713          	add	a4,a4,-602 # 80009df0 <started>
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
    80000062:	0da080e7          	jalr	218(ra) # 80002138 <cpuid>
    80000066:	85aa                	mv	a1,a0
    80000068:	00009517          	auipc	a0,0x9
    8000006c:	fb850513          	add	a0,a0,-72 # 80009020 <etext+0x20>
    80000070:	00001097          	auipc	ra,0x1
    80000074:	1de080e7          	jalr	478(ra) # 8000124e <printf>
    kvminithart();       // 开启分页机制
    80000078:	00001097          	auipc	ra,0x1
    8000007c:	546080e7          	jalr	1350(ra) # 800015be <kvminithart>
    trapinithart();   // 安装内核陷阱向量
    80000080:	00003097          	auipc	ra,0x3
    80000084:	110080e7          	jalr	272(ra) # 80003190 <trapinithart>
    plicinithart();   // 向PLIC请求设备中断
    80000088:	00001097          	auipc	ra,0x1
    8000008c:	964080e7          	jalr	-1692(ra) # 800009ec <plicinithart>
  }
  // 所有CPU都进入调度器，开始调度用户进程
  scheduler(); 
    80000090:	00003097          	auipc	ra,0x3
    80000094:	2a4080e7          	jalr	676(ra) # 80003334 <scheduler>
    initlock(&start_lock,"start_lock");
    80000098:	00009597          	auipc	a1,0x9
    8000009c:	f7858593          	add	a1,a1,-136 # 80009010 <etext+0x10>
    800000a0:	0000a517          	auipc	a0,0xa
    800000a4:	d8050513          	add	a0,a0,-640 # 80009e20 <start_lock>
    800000a8:	00003097          	auipc	ra,0x3
    800000ac:	f36080e7          	jalr	-202(ra) # 80002fde <initlock>
    consoleinit();       // 初始化控制台
    800000b0:	00001097          	auipc	ra,0x1
    800000b4:	8da080e7          	jalr	-1830(ra) # 8000098a <consoleinit>
    printfinit();        // 初始化printf功能
    800000b8:	00001097          	auipc	ra,0x1
    800000bc:	376080e7          	jalr	886(ra) # 8000142e <printfinit>
    printf("\n");
    800000c0:	0000a517          	auipc	a0,0xa
    800000c4:	c7850513          	add	a0,a0,-904 # 80009d38 <syscalls+0x560>
    800000c8:	00001097          	auipc	ra,0x1
    800000cc:	186080e7          	jalr	390(ra) # 8000124e <printf>
    printf("hart %d starting\n", cpuid());
    800000d0:	00002097          	auipc	ra,0x2
    800000d4:	068080e7          	jalr	104(ra) # 80002138 <cpuid>
    800000d8:	85aa                	mv	a1,a0
    800000da:	00009517          	auipc	a0,0x9
    800000de:	f4650513          	add	a0,a0,-186 # 80009020 <etext+0x20>
    800000e2:	00001097          	auipc	ra,0x1
    800000e6:	16c080e7          	jalr	364(ra) # 8000124e <printf>
    kinit();             // 物理页面分配器初始化
    800000ea:	00001097          	auipc	ra,0x1
    800000ee:	43a080e7          	jalr	1082(ra) # 80001524 <kinit>
    kvminit();           // 创建内核页表
    800000f2:	00001097          	auipc	ra,0x1
    800000f6:	768080e7          	jalr	1896(ra) # 8000185a <kvminit>
    kvminithart();       // 开启分页机制
    800000fa:	00001097          	auipc	ra,0x1
    800000fe:	4c4080e7          	jalr	1220(ra) # 800015be <kvminithart>
    procinit();       // 进程表初始化
    80000102:	00002097          	auipc	ra,0x2
    80000106:	1fe080e7          	jalr	510(ra) # 80002300 <procinit>
    timer_create();      // 陷阱向量(时钟中断）初始化
    8000010a:	00000097          	auipc	ra,0x0
    8000010e:	13c080e7          	jalr	316(ra) # 80000246 <timer_create>
    trapinithart();      // 安装内核陷阱向量
    80000112:	00003097          	auipc	ra,0x3
    80000116:	07e080e7          	jalr	126(ra) # 80003190 <trapinithart>
    plicinit();          // 设置中断控制器
    8000011a:	00001097          	auipc	ra,0x1
    8000011e:	8bc080e7          	jalr	-1860(ra) # 800009d6 <plicinit>
    plicinithart();      // 向PLIC请求设备中断
    80000122:	00001097          	auipc	ra,0x1
    80000126:	8ca080e7          	jalr	-1846(ra) # 800009ec <plicinithart>
    binit();             // 缓冲区缓存初始化
    8000012a:	00005097          	auipc	ra,0x5
    8000012e:	5f4080e7          	jalr	1524(ra) # 8000571e <binit>
    iinit();             // inode表初始化
    80000132:	00005097          	auipc	ra,0x5
    80000136:	cfa080e7          	jalr	-774(ra) # 80004e2c <iinit>
    fileinit();          // 文件表初始化
    8000013a:	00006097          	auipc	ra,0x6
    8000013e:	eee080e7          	jalr	-274(ra) # 80006028 <fileinit>
    virtio_disk_init();  // 虚拟硬盘初始化
    80000142:	00001097          	auipc	ra,0x1
    80000146:	9b2080e7          	jalr	-1614(ra) # 80000af4 <virtio_disk_init>
    userinit();   // 创建第一个用户进程 userinit();   
    8000014a:	00002097          	auipc	ra,0x2
    8000014e:	4ae080e7          	jalr	1198(ra) # 800025f8 <userinit>
    started = 1;         // 标记系统启动完成
    80000152:	4785                	li	a5,1
    80000154:	0000a717          	auipc	a4,0xa
    80000158:	c8f72e23          	sw	a5,-868(a4) # 80009df0 <started>
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
    80000170:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb547>
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
    8000020a:	00012717          	auipc	a4,0x12
    8000020e:	c3670713          	add	a4,a4,-970 # 80011e40 <timer_scratch>
    80000212:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    80000214:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000216:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000218:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000021c:	00007797          	auipc	a5,0x7
    80000220:	0d478793          	add	a5,a5,212 # 800072f0 <timervec>
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
    8000024e:	00009597          	auipc	a1,0x9
    80000252:	dea58593          	add	a1,a1,-534 # 80009038 <etext+0x38>
    80000256:	00012517          	auipc	a0,0x12
    8000025a:	d3250513          	add	a0,a0,-718 # 80011f88 <sys_timer+0x8>
    8000025e:	00003097          	auipc	ra,0x3
    80000262:	d80080e7          	jalr	-640(ra) # 80002fde <initlock>
    sys_timer.ticks = 0;
    80000266:	00012797          	auipc	a5,0x12
    8000026a:	d007bd23          	sd	zero,-742(a5) # 80011f80 <sys_timer>
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
    80000282:	00012917          	auipc	s2,0x12
    80000286:	bbe90913          	add	s2,s2,-1090 # 80011e40 <timer_scratch>
    8000028a:	00012497          	auipc	s1,0x12
    8000028e:	cfe48493          	add	s1,s1,-770 # 80011f88 <sys_timer+0x8>
    80000292:	8526                	mv	a0,s1
    80000294:	00003097          	auipc	ra,0x3
    80000298:	dda080e7          	jalr	-550(ra) # 8000306e <acquire>
    sys_timer.ticks++;
    8000029c:	14093783          	ld	a5,320(s2)
    800002a0:	0785                	add	a5,a5,1
    800002a2:	14f93023          	sd	a5,320(s2)
    // printf("ticks: %d\n", sys_timer.ticks);
    release(&sys_timer.lk);
    800002a6:	8526                	mv	a0,s1
    800002a8:	00003097          	auipc	ra,0x3
    800002ac:	e7a080e7          	jalr	-390(ra) # 80003122 <release>
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
    800002c8:	00012497          	auipc	s1,0x12
    800002cc:	cc048493          	add	s1,s1,-832 # 80011f88 <sys_timer+0x8>
    800002d0:	8526                	mv	a0,s1
    800002d2:	00003097          	auipc	ra,0x3
    800002d6:	d9c080e7          	jalr	-612(ra) # 8000306e <acquire>
    xticks = sys_timer.ticks;
    800002da:	00012917          	auipc	s2,0x12
    800002de:	ca693903          	ld	s2,-858(s2) # 80011f80 <sys_timer>
    release(&sys_timer.lk);
    800002e2:	8526                	mv	a0,s1
    800002e4:	00003097          	auipc	ra,0x3
    800002e8:	e3e080e7          	jalr	-450(ra) # 80003122 <release>
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
    8000032a:	00009597          	auipc	a1,0x9
    8000032e:	d1e58593          	add	a1,a1,-738 # 80009048 <etext+0x48>
    80000332:	00012517          	auipc	a0,0x12
    80000336:	c6e50513          	add	a0,a0,-914 # 80011fa0 <uart_tx_lock>
    8000033a:	00003097          	auipc	ra,0x3
    8000033e:	ca4080e7          	jalr	-860(ra) # 80002fde <initlock>
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
    8000035a:	ccc080e7          	jalr	-820(ra) # 80003022 <push_off>
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    8000035e:	0000a797          	auipc	a5,0xa
    80000362:	aaa7a783          	lw	a5,-1366(a5) # 80009e08 <panicked>
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
    80000388:	d3e080e7          	jalr	-706(ra) # 800030c2 <pop_off>
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
    80000396:	0000a797          	auipc	a5,0xa
    8000039a:	a627b783          	ld	a5,-1438(a5) # 80009df8 <uart_tx_r>
    8000039e:	0000a717          	auipc	a4,0xa
    800003a2:	a6273703          	ld	a4,-1438(a4) # 80009e00 <uart_tx_w>
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
    800003c0:	00012a17          	auipc	s4,0x12
    800003c4:	be0a0a13          	add	s4,s4,-1056 # 80011fa0 <uart_tx_lock>
    uart_tx_r += 1;
    800003c8:	0000a497          	auipc	s1,0xa
    800003cc:	a3048493          	add	s1,s1,-1488 # 80009df8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800003d0:	0000a997          	auipc	s3,0xa
    800003d4:	a3098993          	add	s3,s3,-1488 # 80009e00 <uart_tx_w>
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
    800003f6:	59c080e7          	jalr	1436(ra) # 8000298e <wakeup>
    
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
    8000042e:	00012517          	auipc	a0,0x12
    80000432:	b7250513          	add	a0,a0,-1166 # 80011fa0 <uart_tx_lock>
    80000436:	00003097          	auipc	ra,0x3
    8000043a:	c38080e7          	jalr	-968(ra) # 8000306e <acquire>
  if(panicked){
    8000043e:	0000a797          	auipc	a5,0xa
    80000442:	9ca7a783          	lw	a5,-1590(a5) # 80009e08 <panicked>
    80000446:	e7c9                	bnez	a5,800004d0 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000448:	0000a717          	auipc	a4,0xa
    8000044c:	9b873703          	ld	a4,-1608(a4) # 80009e00 <uart_tx_w>
    80000450:	0000a797          	auipc	a5,0xa
    80000454:	9a87b783          	ld	a5,-1624(a5) # 80009df8 <uart_tx_r>
    80000458:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000045c:	00012997          	auipc	s3,0x12
    80000460:	b4498993          	add	s3,s3,-1212 # 80011fa0 <uart_tx_lock>
    80000464:	0000a497          	auipc	s1,0xa
    80000468:	99448493          	add	s1,s1,-1644 # 80009df8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000046c:	0000a917          	auipc	s2,0xa
    80000470:	99490913          	add	s2,s2,-1644 # 80009e00 <uart_tx_w>
    80000474:	00e79f63          	bne	a5,a4,80000492 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000478:	85ce                	mv	a1,s3
    8000047a:	8526                	mv	a0,s1
    8000047c:	00002097          	auipc	ra,0x2
    80000480:	4a4080e7          	jalr	1188(ra) # 80002920 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000484:	00093703          	ld	a4,0(s2)
    80000488:	609c                	ld	a5,0(s1)
    8000048a:	02078793          	add	a5,a5,32
    8000048e:	fee785e3          	beq	a5,a4,80000478 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000492:	00012497          	auipc	s1,0x12
    80000496:	b0e48493          	add	s1,s1,-1266 # 80011fa0 <uart_tx_lock>
    8000049a:	01f77793          	and	a5,a4,31
    8000049e:	97a6                	add	a5,a5,s1
    800004a0:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800004a4:	0705                	add	a4,a4,1
    800004a6:	0000a797          	auipc	a5,0xa
    800004aa:	94e7bd23          	sd	a4,-1702(a5) # 80009e00 <uart_tx_w>
  uartstart();
    800004ae:	00000097          	auipc	ra,0x0
    800004b2:	ee8080e7          	jalr	-280(ra) # 80000396 <uartstart>
  release(&uart_tx_lock);
    800004b6:	8526                	mv	a0,s1
    800004b8:	00003097          	auipc	ra,0x3
    800004bc:	c6a080e7          	jalr	-918(ra) # 80003122 <release>
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
  // RX: 将输入字节交给 console 子系统（它会负责回显、行缓冲、wakeup）。
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000500:	54fd                	li	s1,-1
    80000502:	a029                	j	8000050c <uartintr+0x16>
      break;
    consoleintr(c);
    80000504:	00000097          	auipc	ra,0x0
    80000508:	2f4080e7          	jalr	756(ra) # 800007f8 <consoleintr>
    int c = uartgetc();
    8000050c:	00000097          	auipc	ra,0x0
    80000510:	fc6080e7          	jalr	-58(ra) # 800004d2 <uartgetc>
    if(c == -1)
    80000514:	fe9518e3          	bne	a0,s1,80000504 <uartintr+0xe>
  }

  // TX: 发送输出缓冲区中的字符。
  acquire(&uart_tx_lock);
    80000518:	00012497          	auipc	s1,0x12
    8000051c:	a8848493          	add	s1,s1,-1400 # 80011fa0 <uart_tx_lock>
    80000520:	8526                	mv	a0,s1
    80000522:	00003097          	auipc	ra,0x3
    80000526:	b4c080e7          	jalr	-1204(ra) # 8000306e <acquire>
  uartstart();
    8000052a:	00000097          	auipc	ra,0x0
    8000052e:	e6c080e7          	jalr	-404(ra) # 80000396 <uartstart>
  release(&uart_tx_lock);
    80000532:	8526                	mv	a0,s1
    80000534:	00003097          	auipc	ra,0x3
    80000538:	bee080e7          	jalr	-1042(ra) # 80003122 <release>
}
    8000053c:	60e2                	ld	ra,24(sp)
    8000053e:	6442                	ld	s0,16(sp)
    80000540:	64a2                	ld	s1,8(sp)
    80000542:	6105                	add	sp,sp,32
    80000544:	8082                	ret

0000000080000546 <uart_putc>:


void uart_putc(char c) {
    80000546:	1141                	add	sp,sp,-16
    80000548:	e422                	sd	s0,8(sp)
    8000054a:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    8000054c:	10000737          	lui	a4,0x10000
    80000550:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000554:	0207f793          	and	a5,a5,32
    80000558:	dfe5                	beqz	a5,80000550 <uart_putc+0xa>
    uart[0] = c;
    8000055a:	100007b7          	lui	a5,0x10000
    8000055e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    80000562:	6422                	ld	s0,8(sp)
    80000564:	0141                	add	sp,sp,16
    80000566:	8082                	ret

0000000080000568 <uart_puts>:

void uart_puts(char *s) {
    80000568:	1101                	add	sp,sp,-32
    8000056a:	ec06                	sd	ra,24(sp)
    8000056c:	e822                	sd	s0,16(sp)
    8000056e:	e426                	sd	s1,8(sp)
    80000570:	1000                	add	s0,sp,32
    80000572:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000574:	00054503          	lbu	a0,0(a0)
    80000578:	c909                	beqz	a0,8000058a <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	fcc080e7          	jalr	-52(ra) # 80000546 <uart_putc>
        s++;              // 移动到下一个字符
    80000582:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000584:	0004c503          	lbu	a0,0(s1)
    80000588:	f96d                	bnez	a0,8000057a <uart_puts+0x12>
    }
}
    8000058a:	60e2                	ld	ra,24(sp)
    8000058c:	6442                	ld	s0,16(sp)
    8000058e:	64a2                	ld	s1,8(sp)
    80000590:	6105                	add	sp,sp,32
    80000592:	8082                	ret

0000000080000594 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000594:	715d                	add	sp,sp,-80
    80000596:	e486                	sd	ra,72(sp)
    80000598:	e0a2                	sd	s0,64(sp)
    8000059a:	fc26                	sd	s1,56(sp)
    8000059c:	f84a                	sd	s2,48(sp)
    8000059e:	f44e                	sd	s3,40(sp)
    800005a0:	f052                	sd	s4,32(sp)
    800005a2:	ec56                	sd	s5,24(sp)
    800005a4:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    800005a6:	04c05763          	blez	a2,800005f4 <consolewrite+0x60>
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	84ae                	mv	s1,a1
    800005ae:	89b2                	mv	s3,a2
    800005b0:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    800005b2:	5afd                	li	s5,-1
    800005b4:	4685                	li	a3,1
    800005b6:	8626                	mv	a2,s1
    800005b8:	85d2                	mv	a1,s4
    800005ba:	fbf40513          	add	a0,s0,-65
    800005be:	00003097          	auipc	ra,0x3
    800005c2:	804080e7          	jalr	-2044(ra) # 80002dc2 <either_copyin>
    800005c6:	01550d63          	beq	a0,s5,800005e0 <consolewrite+0x4c>
      break;
    uartputc(c);
    800005ca:	fbf44503          	lbu	a0,-65(s0)
    800005ce:	00000097          	auipc	ra,0x0
    800005d2:	e4e080e7          	jalr	-434(ra) # 8000041c <uartputc>
  for(i = 0; i < n; i++){
    800005d6:	2905                	addw	s2,s2,1
    800005d8:	0485                	add	s1,s1,1
    800005da:	fd299de3          	bne	s3,s2,800005b4 <consolewrite+0x20>
    800005de:	894e                	mv	s2,s3
  }

  return i;
}
    800005e0:	854a                	mv	a0,s2
    800005e2:	60a6                	ld	ra,72(sp)
    800005e4:	6406                	ld	s0,64(sp)
    800005e6:	74e2                	ld	s1,56(sp)
    800005e8:	7942                	ld	s2,48(sp)
    800005ea:	79a2                	ld	s3,40(sp)
    800005ec:	7a02                	ld	s4,32(sp)
    800005ee:	6ae2                	ld	s5,24(sp)
    800005f0:	6161                	add	sp,sp,80
    800005f2:	8082                	ret
  for(i = 0; i < n; i++){
    800005f4:	4901                	li	s2,0
    800005f6:	b7ed                	j	800005e0 <consolewrite+0x4c>

00000000800005f8 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    800005f8:	711d                	add	sp,sp,-96
    800005fa:	ec86                	sd	ra,88(sp)
    800005fc:	e8a2                	sd	s0,80(sp)
    800005fe:	e4a6                	sd	s1,72(sp)
    80000600:	e0ca                	sd	s2,64(sp)
    80000602:	fc4e                	sd	s3,56(sp)
    80000604:	f852                	sd	s4,48(sp)
    80000606:	f456                	sd	s5,40(sp)
    80000608:	f05a                	sd	s6,32(sp)
    8000060a:	ec5e                	sd	s7,24(sp)
    8000060c:	1080                	add	s0,sp,96
    8000060e:	8aaa                	mv	s5,a0
    80000610:	8a2e                	mv	s4,a1
    80000612:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000614:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000618:	00012517          	auipc	a0,0x12
    8000061c:	9c050513          	add	a0,a0,-1600 # 80011fd8 <cons>
    80000620:	00003097          	auipc	ra,0x3
    80000624:	a4e080e7          	jalr	-1458(ra) # 8000306e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000628:	00012497          	auipc	s1,0x12
    8000062c:	9b048493          	add	s1,s1,-1616 # 80011fd8 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000630:	00012917          	auipc	s2,0x12
    80000634:	a4090913          	add	s2,s2,-1472 # 80012070 <cons+0x98>
  while(n > 0){
    80000638:	09305263          	blez	s3,800006bc <consoleread+0xc4>
    while(cons.r == cons.w){
    8000063c:	0984a783          	lw	a5,152(s1)
    80000640:	09c4a703          	lw	a4,156(s1)
    80000644:	02f71763          	bne	a4,a5,80000672 <consoleread+0x7a>
      if(killed(myproc())){
    80000648:	00002097          	auipc	ra,0x2
    8000064c:	b1c080e7          	jalr	-1252(ra) # 80002164 <myproc>
    80000650:	00002097          	auipc	ra,0x2
    80000654:	46c080e7          	jalr	1132(ra) # 80002abc <killed>
    80000658:	ed2d                	bnez	a0,800006d2 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    8000065a:	85a6                	mv	a1,s1
    8000065c:	854a                	mv	a0,s2
    8000065e:	00002097          	auipc	ra,0x2
    80000662:	2c2080e7          	jalr	706(ra) # 80002920 <sleep>
    while(cons.r == cons.w){
    80000666:	0984a783          	lw	a5,152(s1)
    8000066a:	09c4a703          	lw	a4,156(s1)
    8000066e:	fcf70de3          	beq	a4,a5,80000648 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    80000672:	00012717          	auipc	a4,0x12
    80000676:	96670713          	add	a4,a4,-1690 # 80011fd8 <cons>
    8000067a:	0017869b          	addw	a3,a5,1
    8000067e:	08d72c23          	sw	a3,152(a4)
    80000682:	07f7f693          	and	a3,a5,127
    80000686:	9736                	add	a4,a4,a3
    80000688:	01874703          	lbu	a4,24(a4)
    8000068c:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000690:	4691                	li	a3,4
    80000692:	06db8463          	beq	s7,a3,800006fa <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000696:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000069a:	4685                	li	a3,1
    8000069c:	faf40613          	add	a2,s0,-81
    800006a0:	85d2                	mv	a1,s4
    800006a2:	8556                	mv	a0,s5
    800006a4:	00002097          	auipc	ra,0x2
    800006a8:	6c8080e7          	jalr	1736(ra) # 80002d6c <either_copyout>
    800006ac:	57fd                	li	a5,-1
    800006ae:	00f50763          	beq	a0,a5,800006bc <consoleread+0xc4>
      break;

    dst++;
    800006b2:	0a05                	add	s4,s4,1
    --n;
    800006b4:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    800006b6:	47a9                	li	a5,10
    800006b8:	f8fb90e3          	bne	s7,a5,80000638 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800006bc:	00012517          	auipc	a0,0x12
    800006c0:	91c50513          	add	a0,a0,-1764 # 80011fd8 <cons>
    800006c4:	00003097          	auipc	ra,0x3
    800006c8:	a5e080e7          	jalr	-1442(ra) # 80003122 <release>

  return target - n;
    800006cc:	413b053b          	subw	a0,s6,s3
    800006d0:	a811                	j	800006e4 <consoleread+0xec>
        release(&cons.lock);
    800006d2:	00012517          	auipc	a0,0x12
    800006d6:	90650513          	add	a0,a0,-1786 # 80011fd8 <cons>
    800006da:	00003097          	auipc	ra,0x3
    800006de:	a48080e7          	jalr	-1464(ra) # 80003122 <release>
        return -1;
    800006e2:	557d                	li	a0,-1
}
    800006e4:	60e6                	ld	ra,88(sp)
    800006e6:	6446                	ld	s0,80(sp)
    800006e8:	64a6                	ld	s1,72(sp)
    800006ea:	6906                	ld	s2,64(sp)
    800006ec:	79e2                	ld	s3,56(sp)
    800006ee:	7a42                	ld	s4,48(sp)
    800006f0:	7aa2                	ld	s5,40(sp)
    800006f2:	7b02                	ld	s6,32(sp)
    800006f4:	6be2                	ld	s7,24(sp)
    800006f6:	6125                	add	sp,sp,96
    800006f8:	8082                	ret
      if(n < target){
    800006fa:	0009871b          	sext.w	a4,s3
    800006fe:	fb677fe3          	bgeu	a4,s6,800006bc <consoleread+0xc4>
        cons.r--;
    80000702:	00012717          	auipc	a4,0x12
    80000706:	96f72723          	sw	a5,-1682(a4) # 80012070 <cons+0x98>
    8000070a:	bf4d                	j	800006bc <consoleread+0xc4>

000000008000070c <consputc>:
{
    8000070c:	1141                	add	sp,sp,-16
    8000070e:	e406                	sd	ra,8(sp)
    80000710:	e022                	sd	s0,0(sp)
    80000712:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000714:	07f00793          	li	a5,127
    80000718:	00f50a63          	beq	a0,a5,8000072c <consputc+0x20>
    uartputc_sync(c);
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	c2e080e7          	jalr	-978(ra) # 8000034a <uartputc_sync>
}
    80000724:	60a2                	ld	ra,8(sp)
    80000726:	6402                	ld	s0,0(sp)
    80000728:	0141                	add	sp,sp,16
    8000072a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000072c:	4521                	li	a0,8
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	c1c080e7          	jalr	-996(ra) # 8000034a <uartputc_sync>
    80000736:	02000513          	li	a0,32
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	c10080e7          	jalr	-1008(ra) # 8000034a <uartputc_sync>
    80000742:	4521                	li	a0,8
    80000744:	00000097          	auipc	ra,0x0
    80000748:	c06080e7          	jalr	-1018(ra) # 8000034a <uartputc_sync>
    8000074c:	bfe1                	j	80000724 <consputc+0x18>

000000008000074e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000074e:	715d                	add	sp,sp,-80
    80000750:	e486                	sd	ra,72(sp)
    80000752:	e0a2                	sd	s0,64(sp)
    80000754:	fc26                	sd	s1,56(sp)
    80000756:	f84a                	sd	s2,48(sp)
    80000758:	f44e                	sd	s3,40(sp)
    8000075a:	f052                	sd	s4,32(sp)
    8000075c:	ec56                	sd	s5,24(sp)
    8000075e:	e85a                	sd	s6,16(sp)
    80000760:	e45e                	sd	s7,8(sp)
    80000762:	0880                	add	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80000764:	00009517          	auipc	a0,0x9
    80000768:	5d450513          	add	a0,a0,1492 # 80009d38 <syscalls+0x560>
    8000076c:	00001097          	auipc	ra,0x1
    80000770:	ae2080e7          	jalr	-1310(ra) # 8000124e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80000774:	00012497          	auipc	s1,0x12
    80000778:	ea448493          	add	s1,s1,-348 # 80012618 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000077c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000077e:	00009997          	auipc	s3,0x9
    80000782:	8d298993          	add	s3,s3,-1838 # 80009050 <etext+0x50>
    // printf("%d %s %s", p->pid, state, p->name);
    printf("%d %s", p->pid, state);
    80000786:	00009a97          	auipc	s5,0x9
    8000078a:	8d2a8a93          	add	s5,s5,-1838 # 80009058 <etext+0x58>
    printf("\n");
    8000078e:	00009a17          	auipc	s4,0x9
    80000792:	5aaa0a13          	add	s4,s4,1450 # 80009d38 <syscalls+0x560>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80000796:	00009b97          	auipc	s7,0x9
    8000079a:	902b8b93          	add	s7,s7,-1790 # 80009098 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    8000079e:	00018917          	auipc	s2,0x18
    800007a2:	87a90913          	add	s2,s2,-1926 # 80018018 <wait_lock>
    800007a6:	a005                	j	800007c6 <procdump+0x78>
    printf("%d %s", p->pid, state);
    800007a8:	408c                	lw	a1,0(s1)
    800007aa:	8556                	mv	a0,s5
    800007ac:	00001097          	auipc	ra,0x1
    800007b0:	aa2080e7          	jalr	-1374(ra) # 8000124e <printf>
    printf("\n");
    800007b4:	8552                	mv	a0,s4
    800007b6:	00001097          	auipc	ra,0x1
    800007ba:	a98080e7          	jalr	-1384(ra) # 8000124e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800007be:	16848493          	add	s1,s1,360
    800007c2:	03248063          	beq	s1,s2,800007e2 <procdump+0x94>
    if(p->state == UNUSED)
    800007c6:	509c                	lw	a5,32(s1)
    800007c8:	dbfd                	beqz	a5,800007be <procdump+0x70>
      state = "???";
    800007ca:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800007cc:	fcfb6ee3          	bltu	s6,a5,800007a8 <procdump+0x5a>
    800007d0:	02079713          	sll	a4,a5,0x20
    800007d4:	01d75793          	srl	a5,a4,0x1d
    800007d8:	97de                	add	a5,a5,s7
    800007da:	6390                	ld	a2,0(a5)
    800007dc:	f671                	bnez	a2,800007a8 <procdump+0x5a>
      state = "???";
    800007de:	864e                	mv	a2,s3
    800007e0:	b7e1                	j	800007a8 <procdump+0x5a>
  }
}
    800007e2:	60a6                	ld	ra,72(sp)
    800007e4:	6406                	ld	s0,64(sp)
    800007e6:	74e2                	ld	s1,56(sp)
    800007e8:	7942                	ld	s2,48(sp)
    800007ea:	79a2                	ld	s3,40(sp)
    800007ec:	7a02                	ld	s4,32(sp)
    800007ee:	6ae2                	ld	s5,24(sp)
    800007f0:	6b42                	ld	s6,16(sp)
    800007f2:	6ba2                	ld	s7,8(sp)
    800007f4:	6161                	add	sp,sp,80
    800007f6:	8082                	ret

00000000800007f8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800007f8:	1101                	add	sp,sp,-32
    800007fa:	ec06                	sd	ra,24(sp)
    800007fc:	e822                	sd	s0,16(sp)
    800007fe:	e426                	sd	s1,8(sp)
    80000800:	e04a                	sd	s2,0(sp)
    80000802:	1000                	add	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    80000806:	00011517          	auipc	a0,0x11
    8000080a:	7d250513          	add	a0,a0,2002 # 80011fd8 <cons>
    8000080e:	00003097          	auipc	ra,0x3
    80000812:	860080e7          	jalr	-1952(ra) # 8000306e <acquire>

  switch(c){
    80000816:	47d5                	li	a5,21
    80000818:	0af48663          	beq	s1,a5,800008c4 <consoleintr+0xcc>
    8000081c:	0297ca63          	blt	a5,s1,80000850 <consoleintr+0x58>
    80000820:	47a1                	li	a5,8
    80000822:	0ef48763          	beq	s1,a5,80000910 <consoleintr+0x118>
    80000826:	47c1                	li	a5,16
    80000828:	10f49a63          	bne	s1,a5,8000093c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    8000082c:	00000097          	auipc	ra,0x0
    80000830:	f22080e7          	jalr	-222(ra) # 8000074e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000834:	00011517          	auipc	a0,0x11
    80000838:	7a450513          	add	a0,a0,1956 # 80011fd8 <cons>
    8000083c:	00003097          	auipc	ra,0x3
    80000840:	8e6080e7          	jalr	-1818(ra) # 80003122 <release>
}
    80000844:	60e2                	ld	ra,24(sp)
    80000846:	6442                	ld	s0,16(sp)
    80000848:	64a2                	ld	s1,8(sp)
    8000084a:	6902                	ld	s2,0(sp)
    8000084c:	6105                	add	sp,sp,32
    8000084e:	8082                	ret
  switch(c){
    80000850:	07f00793          	li	a5,127
    80000854:	0af48e63          	beq	s1,a5,80000910 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000858:	00011717          	auipc	a4,0x11
    8000085c:	78070713          	add	a4,a4,1920 # 80011fd8 <cons>
    80000860:	0a072783          	lw	a5,160(a4)
    80000864:	09872703          	lw	a4,152(a4)
    80000868:	9f99                	subw	a5,a5,a4
    8000086a:	07f00713          	li	a4,127
    8000086e:	fcf763e3          	bltu	a4,a5,80000834 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000872:	47b5                	li	a5,13
    80000874:	0cf48763          	beq	s1,a5,80000942 <consoleintr+0x14a>
      consputc(c);
    80000878:	8526                	mv	a0,s1
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	e92080e7          	jalr	-366(ra) # 8000070c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000882:	00011797          	auipc	a5,0x11
    80000886:	75678793          	add	a5,a5,1878 # 80011fd8 <cons>
    8000088a:	0a07a683          	lw	a3,160(a5)
    8000088e:	0016871b          	addw	a4,a3,1
    80000892:	0007061b          	sext.w	a2,a4
    80000896:	0ae7a023          	sw	a4,160(a5)
    8000089a:	07f6f693          	and	a3,a3,127
    8000089e:	97b6                	add	a5,a5,a3
    800008a0:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    800008a4:	47a9                	li	a5,10
    800008a6:	0cf48563          	beq	s1,a5,80000970 <consoleintr+0x178>
    800008aa:	4791                	li	a5,4
    800008ac:	0cf48263          	beq	s1,a5,80000970 <consoleintr+0x178>
    800008b0:	00011797          	auipc	a5,0x11
    800008b4:	7c07a783          	lw	a5,1984(a5) # 80012070 <cons+0x98>
    800008b8:	9f1d                	subw	a4,a4,a5
    800008ba:	08000793          	li	a5,128
    800008be:	f6f71be3          	bne	a4,a5,80000834 <consoleintr+0x3c>
    800008c2:	a07d                	j	80000970 <consoleintr+0x178>
    while(cons.e != cons.w &&
    800008c4:	00011717          	auipc	a4,0x11
    800008c8:	71470713          	add	a4,a4,1812 # 80011fd8 <cons>
    800008cc:	0a072783          	lw	a5,160(a4)
    800008d0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800008d4:	00011497          	auipc	s1,0x11
    800008d8:	70448493          	add	s1,s1,1796 # 80011fd8 <cons>
    while(cons.e != cons.w &&
    800008dc:	4929                	li	s2,10
    800008de:	f4f70be3          	beq	a4,a5,80000834 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800008e2:	37fd                	addw	a5,a5,-1
    800008e4:	07f7f713          	and	a4,a5,127
    800008e8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800008ea:	01874703          	lbu	a4,24(a4)
    800008ee:	f52703e3          	beq	a4,s2,80000834 <consoleintr+0x3c>
      cons.e--;
    800008f2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800008f6:	07f00513          	li	a0,127
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	e12080e7          	jalr	-494(ra) # 8000070c <consputc>
    while(cons.e != cons.w &&
    80000902:	0a04a783          	lw	a5,160(s1)
    80000906:	09c4a703          	lw	a4,156(s1)
    8000090a:	fcf71ce3          	bne	a4,a5,800008e2 <consoleintr+0xea>
    8000090e:	b71d                	j	80000834 <consoleintr+0x3c>
    if(cons.e != cons.w){
    80000910:	00011717          	auipc	a4,0x11
    80000914:	6c870713          	add	a4,a4,1736 # 80011fd8 <cons>
    80000918:	0a072783          	lw	a5,160(a4)
    8000091c:	09c72703          	lw	a4,156(a4)
    80000920:	f0f70ae3          	beq	a4,a5,80000834 <consoleintr+0x3c>
      cons.e--;
    80000924:	37fd                	addw	a5,a5,-1
    80000926:	00011717          	auipc	a4,0x11
    8000092a:	74f72923          	sw	a5,1874(a4) # 80012078 <cons+0xa0>
      consputc(BACKSPACE);
    8000092e:	07f00513          	li	a0,127
    80000932:	00000097          	auipc	ra,0x0
    80000936:	dda080e7          	jalr	-550(ra) # 8000070c <consputc>
    8000093a:	bded                	j	80000834 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000093c:	ee048ce3          	beqz	s1,80000834 <consoleintr+0x3c>
    80000940:	bf21                	j	80000858 <consoleintr+0x60>
      consputc(c);
    80000942:	4529                	li	a0,10
    80000944:	00000097          	auipc	ra,0x0
    80000948:	dc8080e7          	jalr	-568(ra) # 8000070c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000094c:	00011797          	auipc	a5,0x11
    80000950:	68c78793          	add	a5,a5,1676 # 80011fd8 <cons>
    80000954:	0a07a703          	lw	a4,160(a5)
    80000958:	0017069b          	addw	a3,a4,1
    8000095c:	0006861b          	sext.w	a2,a3
    80000960:	0ad7a023          	sw	a3,160(a5)
    80000964:	07f77713          	and	a4,a4,127
    80000968:	97ba                	add	a5,a5,a4
    8000096a:	4729                	li	a4,10
    8000096c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000970:	00011797          	auipc	a5,0x11
    80000974:	70c7a223          	sw	a2,1796(a5) # 80012074 <cons+0x9c>
        wakeup(&cons.r);
    80000978:	00011517          	auipc	a0,0x11
    8000097c:	6f850513          	add	a0,a0,1784 # 80012070 <cons+0x98>
    80000980:	00002097          	auipc	ra,0x2
    80000984:	00e080e7          	jalr	14(ra) # 8000298e <wakeup>
    80000988:	b575                	j	80000834 <consoleintr+0x3c>

000000008000098a <consoleinit>:

void
consoleinit(void)
{
    8000098a:	1141                	add	sp,sp,-16
    8000098c:	e406                	sd	ra,8(sp)
    8000098e:	e022                	sd	s0,0(sp)
    80000990:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000992:	00008597          	auipc	a1,0x8
    80000996:	6ce58593          	add	a1,a1,1742 # 80009060 <etext+0x60>
    8000099a:	00011517          	auipc	a0,0x11
    8000099e:	63e50513          	add	a0,a0,1598 # 80011fd8 <cons>
    800009a2:	00002097          	auipc	ra,0x2
    800009a6:	63c080e7          	jalr	1596(ra) # 80002fde <initlock>

  uartinit();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	950080e7          	jalr	-1712(ra) # 800002fa <uartinit>

  devsw[CONSOLE].read = consoleread;
    800009b2:	00022797          	auipc	a5,0x22
    800009b6:	88e78793          	add	a5,a5,-1906 # 80022240 <devsw>
    800009ba:	00000717          	auipc	a4,0x0
    800009be:	c3e70713          	add	a4,a4,-962 # 800005f8 <consoleread>
    800009c2:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800009c4:	00000717          	auipc	a4,0x0
    800009c8:	bd070713          	add	a4,a4,-1072 # 80000594 <consolewrite>
    800009cc:	ef98                	sd	a4,24(a5)
}
    800009ce:	60a2                	ld	ra,8(sp)
    800009d0:	6402                	ld	s0,0(sp)
    800009d2:	0141                	add	sp,sp,16
    800009d4:	8082                	ret

00000000800009d6 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800009d6:	1141                	add	sp,sp,-16
    800009d8:	e422                	sd	s0,8(sp)
    800009da:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800009dc:	0c0007b7          	lui	a5,0xc000
    800009e0:	4705                	li	a4,1
    800009e2:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800009e4:	c3d8                	sw	a4,4(a5)
}
    800009e6:	6422                	ld	s0,8(sp)
    800009e8:	0141                	add	sp,sp,16
    800009ea:	8082                	ret

00000000800009ec <plicinithart>:

void
plicinithart(void)
{
    800009ec:	1141                	add	sp,sp,-16
    800009ee:	e406                	sd	ra,8(sp)
    800009f0:	e022                	sd	s0,0(sp)
    800009f2:	0800                	add	s0,sp,16
  int hart = cpuid();
    800009f4:	00001097          	auipc	ra,0x1
    800009f8:	744080e7          	jalr	1860(ra) # 80002138 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800009fc:	0085171b          	sllw	a4,a0,0x8
    80000a00:	0c0027b7          	lui	a5,0xc002
    80000a04:	97ba                	add	a5,a5,a4
    80000a06:	40200713          	li	a4,1026
    80000a0a:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80000a0e:	00d5151b          	sllw	a0,a0,0xd
    80000a12:	0c2017b7          	lui	a5,0xc201
    80000a16:	97aa                	add	a5,a5,a0
    80000a18:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80000a1c:	60a2                	ld	ra,8(sp)
    80000a1e:	6402                	ld	s0,0(sp)
    80000a20:	0141                	add	sp,sp,16
    80000a22:	8082                	ret

0000000080000a24 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80000a24:	1141                	add	sp,sp,-16
    80000a26:	e406                	sd	ra,8(sp)
    80000a28:	e022                	sd	s0,0(sp)
    80000a2a:	0800                	add	s0,sp,16
  int hart = cpuid();
    80000a2c:	00001097          	auipc	ra,0x1
    80000a30:	70c080e7          	jalr	1804(ra) # 80002138 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80000a34:	00d5151b          	sllw	a0,a0,0xd
    80000a38:	0c2017b7          	lui	a5,0xc201
    80000a3c:	97aa                	add	a5,a5,a0
  return irq;
}
    80000a3e:	43c8                	lw	a0,4(a5)
    80000a40:	60a2                	ld	ra,8(sp)
    80000a42:	6402                	ld	s0,0(sp)
    80000a44:	0141                	add	sp,sp,16
    80000a46:	8082                	ret

0000000080000a48 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80000a48:	1101                	add	sp,sp,-32
    80000a4a:	ec06                	sd	ra,24(sp)
    80000a4c:	e822                	sd	s0,16(sp)
    80000a4e:	e426                	sd	s1,8(sp)
    80000a50:	1000                	add	s0,sp,32
    80000a52:	84aa                	mv	s1,a0
  int hart = cpuid();
    80000a54:	00001097          	auipc	ra,0x1
    80000a58:	6e4080e7          	jalr	1764(ra) # 80002138 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80000a5c:	00d5151b          	sllw	a0,a0,0xd
    80000a60:	0c2017b7          	lui	a5,0xc201
    80000a64:	97aa                	add	a5,a5,a0
    80000a66:	c3c4                	sw	s1,4(a5)
}
    80000a68:	60e2                	ld	ra,24(sp)
    80000a6a:	6442                	ld	s0,16(sp)
    80000a6c:	64a2                	ld	s1,8(sp)
    80000a6e:	6105                	add	sp,sp,32
    80000a70:	8082                	ret

0000000080000a72 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80000a72:	1141                	add	sp,sp,-16
    80000a74:	e406                	sd	ra,8(sp)
    80000a76:	e022                	sd	s0,0(sp)
    80000a78:	0800                	add	s0,sp,16
  if(i >= NUM)
    80000a7a:	479d                	li	a5,7
    80000a7c:	04a7cc63          	blt	a5,a0,80000ad4 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80000a80:	00011797          	auipc	a5,0x11
    80000a84:	60078793          	add	a5,a5,1536 # 80012080 <disk>
    80000a88:	97aa                	add	a5,a5,a0
    80000a8a:	0187c783          	lbu	a5,24(a5)
    80000a8e:	ebb9                	bnez	a5,80000ae4 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80000a90:	00451693          	sll	a3,a0,0x4
    80000a94:	00011797          	auipc	a5,0x11
    80000a98:	5ec78793          	add	a5,a5,1516 # 80012080 <disk>
    80000a9c:	6398                	ld	a4,0(a5)
    80000a9e:	9736                	add	a4,a4,a3
    80000aa0:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80000aa4:	6398                	ld	a4,0(a5)
    80000aa6:	9736                	add	a4,a4,a3
    80000aa8:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80000aac:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80000ab0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80000ab4:	97aa                	add	a5,a5,a0
    80000ab6:	4705                	li	a4,1
    80000ab8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80000abc:	00011517          	auipc	a0,0x11
    80000ac0:	5dc50513          	add	a0,a0,1500 # 80012098 <disk+0x18>
    80000ac4:	00002097          	auipc	ra,0x2
    80000ac8:	eca080e7          	jalr	-310(ra) # 8000298e <wakeup>
}
    80000acc:	60a2                	ld	ra,8(sp)
    80000ace:	6402                	ld	s0,0(sp)
    80000ad0:	0141                	add	sp,sp,16
    80000ad2:	8082                	ret
    panic("free_desc 1");
    80000ad4:	00008517          	auipc	a0,0x8
    80000ad8:	5f450513          	add	a0,a0,1524 # 800090c8 <states.0+0x30>
    80000adc:	00000097          	auipc	ra,0x0
    80000ae0:	728080e7          	jalr	1832(ra) # 80001204 <panic>
    panic("free_desc 2");
    80000ae4:	00008517          	auipc	a0,0x8
    80000ae8:	5f450513          	add	a0,a0,1524 # 800090d8 <states.0+0x40>
    80000aec:	00000097          	auipc	ra,0x0
    80000af0:	718080e7          	jalr	1816(ra) # 80001204 <panic>

0000000080000af4 <virtio_disk_init>:
{
    80000af4:	1101                	add	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	e04a                	sd	s2,0(sp)
    80000afe:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80000b00:	00008597          	auipc	a1,0x8
    80000b04:	5e858593          	add	a1,a1,1512 # 800090e8 <states.0+0x50>
    80000b08:	00011517          	auipc	a0,0x11
    80000b0c:	6a050513          	add	a0,a0,1696 # 800121a8 <disk+0x128>
    80000b10:	00002097          	auipc	ra,0x2
    80000b14:	4ce080e7          	jalr	1230(ra) # 80002fde <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80000b18:	100017b7          	lui	a5,0x10001
    80000b1c:	4398                	lw	a4,0(a5)
    80000b1e:	2701                	sext.w	a4,a4
    80000b20:	747277b7          	lui	a5,0x74727
    80000b24:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80000b28:	14f71863          	bne	a4,a5,80000c78 <virtio_disk_init+0x184>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80000b2c:	100017b7          	lui	a5,0x10001
    80000b30:	479c                	lw	a5,8(a5)
    80000b32:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80000b34:	4709                	li	a4,2
    80000b36:	14e79163          	bne	a5,a4,80000c78 <virtio_disk_init+0x184>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80000b3a:	100017b7          	lui	a5,0x10001
    80000b3e:	47d8                	lw	a4,12(a5)
    80000b40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80000b42:	554d47b7          	lui	a5,0x554d4
    80000b46:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80000b4a:	12f71763          	bne	a4,a5,80000c78 <virtio_disk_init+0x184>
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b4e:	100017b7          	lui	a5,0x10001
    80000b52:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b56:	4705                	li	a4,1
    80000b58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b5a:	470d                	li	a4,3
    80000b5c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80000b5e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80000b60:	c7ffe6b7          	lui	a3,0xc7ffe
    80000b64:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb4a7>
    80000b68:	8f75                	and	a4,a4,a3
    80000b6a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80000b6c:	472d                	li	a4,11
    80000b6e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80000b70:	5bbc                	lw	a5,112(a5)
    80000b72:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80000b76:	8ba1                	and	a5,a5,8
    80000b78:	10078863          	beqz	a5,80000c88 <virtio_disk_init+0x194>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80000b7c:	100017b7          	lui	a5,0x10001
    80000b80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80000b84:	43fc                	lw	a5,68(a5)
    80000b86:	2781                	sext.w	a5,a5
    80000b88:	10079863          	bnez	a5,80000c98 <virtio_disk_init+0x1a4>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80000b8c:	100017b7          	lui	a5,0x10001
    80000b90:	5bdc                	lw	a5,52(a5)
    80000b92:	2781                	sext.w	a5,a5
  if(max == 0)
    80000b94:	10078a63          	beqz	a5,80000ca8 <virtio_disk_init+0x1b4>
  if(max < NUM)
    80000b98:	471d                	li	a4,7
    80000b9a:	10f77f63          	bgeu	a4,a5,80000cb8 <virtio_disk_init+0x1c4>
  disk.desc = kalloc(1);
    80000b9e:	4505                	li	a0,1
    80000ba0:	00001097          	auipc	ra,0x1
    80000ba4:	9c0080e7          	jalr	-1600(ra) # 80001560 <kalloc>
    80000ba8:	00011497          	auipc	s1,0x11
    80000bac:	4d848493          	add	s1,s1,1240 # 80012080 <disk>
    80000bb0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc(1);
    80000bb2:	4505                	li	a0,1
    80000bb4:	00001097          	auipc	ra,0x1
    80000bb8:	9ac080e7          	jalr	-1620(ra) # 80001560 <kalloc>
    80000bbc:	e488                	sd	a0,8(s1)
  disk.used = kalloc(1);
    80000bbe:	4505                	li	a0,1
    80000bc0:	00001097          	auipc	ra,0x1
    80000bc4:	9a0080e7          	jalr	-1632(ra) # 80001560 <kalloc>
    80000bc8:	87aa                	mv	a5,a0
    80000bca:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80000bcc:	6088                	ld	a0,0(s1)
    80000bce:	cd6d                	beqz	a0,80000cc8 <virtio_disk_init+0x1d4>
    80000bd0:	00011717          	auipc	a4,0x11
    80000bd4:	4b873703          	ld	a4,1208(a4) # 80012088 <disk+0x8>
    80000bd8:	cb65                	beqz	a4,80000cc8 <virtio_disk_init+0x1d4>
    80000bda:	c7fd                	beqz	a5,80000cc8 <virtio_disk_init+0x1d4>
  memset(disk.desc, 0, PGSIZE);
    80000bdc:	6605                	lui	a2,0x1
    80000bde:	4581                	li	a1,0
    80000be0:	00000097          	auipc	ra,0x0
    80000be4:	3dc080e7          	jalr	988(ra) # 80000fbc <memset>
  memset(disk.avail, 0, PGSIZE);
    80000be8:	00011497          	auipc	s1,0x11
    80000bec:	49848493          	add	s1,s1,1176 # 80012080 <disk>
    80000bf0:	6605                	lui	a2,0x1
    80000bf2:	4581                	li	a1,0
    80000bf4:	6488                	ld	a0,8(s1)
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	3c6080e7          	jalr	966(ra) # 80000fbc <memset>
  memset(disk.used, 0, PGSIZE);
    80000bfe:	6605                	lui	a2,0x1
    80000c00:	4581                	li	a1,0
    80000c02:	6888                	ld	a0,16(s1)
    80000c04:	00000097          	auipc	ra,0x0
    80000c08:	3b8080e7          	jalr	952(ra) # 80000fbc <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80000c0c:	100017b7          	lui	a5,0x10001
    80000c10:	4721                	li	a4,8
    80000c12:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80000c14:	4098                	lw	a4,0(s1)
    80000c16:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80000c1a:	40d8                	lw	a4,4(s1)
    80000c1c:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80000c20:	6498                	ld	a4,8(s1)
    80000c22:	0007069b          	sext.w	a3,a4
    80000c26:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80000c2a:	9701                	sra	a4,a4,0x20
    80000c2c:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80000c30:	6898                	ld	a4,16(s1)
    80000c32:	0007069b          	sext.w	a3,a4
    80000c36:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80000c3a:	9701                	sra	a4,a4,0x20
    80000c3c:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80000c40:	4705                	li	a4,1
    80000c42:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80000c44:	00e48c23          	sb	a4,24(s1)
    80000c48:	00e48ca3          	sb	a4,25(s1)
    80000c4c:	00e48d23          	sb	a4,26(s1)
    80000c50:	00e48da3          	sb	a4,27(s1)
    80000c54:	00e48e23          	sb	a4,28(s1)
    80000c58:	00e48ea3          	sb	a4,29(s1)
    80000c5c:	00e48f23          	sb	a4,30(s1)
    80000c60:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80000c64:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80000c68:	0727a823          	sw	s2,112(a5)
}
    80000c6c:	60e2                	ld	ra,24(sp)
    80000c6e:	6442                	ld	s0,16(sp)
    80000c70:	64a2                	ld	s1,8(sp)
    80000c72:	6902                	ld	s2,0(sp)
    80000c74:	6105                	add	sp,sp,32
    80000c76:	8082                	ret
    panic("could not find virtio disk");
    80000c78:	00008517          	auipc	a0,0x8
    80000c7c:	48050513          	add	a0,a0,1152 # 800090f8 <states.0+0x60>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	584080e7          	jalr	1412(ra) # 80001204 <panic>
    panic("virtio disk FEATURES_OK unset");
    80000c88:	00008517          	auipc	a0,0x8
    80000c8c:	49050513          	add	a0,a0,1168 # 80009118 <states.0+0x80>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	574080e7          	jalr	1396(ra) # 80001204 <panic>
    panic("virtio disk should not be ready");
    80000c98:	00008517          	auipc	a0,0x8
    80000c9c:	4a050513          	add	a0,a0,1184 # 80009138 <states.0+0xa0>
    80000ca0:	00000097          	auipc	ra,0x0
    80000ca4:	564080e7          	jalr	1380(ra) # 80001204 <panic>
    panic("virtio disk has no queue 0");
    80000ca8:	00008517          	auipc	a0,0x8
    80000cac:	4b050513          	add	a0,a0,1200 # 80009158 <states.0+0xc0>
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	554080e7          	jalr	1364(ra) # 80001204 <panic>
    panic("virtio disk max queue too short");
    80000cb8:	00008517          	auipc	a0,0x8
    80000cbc:	4c050513          	add	a0,a0,1216 # 80009178 <states.0+0xe0>
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	544080e7          	jalr	1348(ra) # 80001204 <panic>
    panic("virtio disk kalloc");
    80000cc8:	00008517          	auipc	a0,0x8
    80000ccc:	4d050513          	add	a0,a0,1232 # 80009198 <states.0+0x100>
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	534080e7          	jalr	1332(ra) # 80001204 <panic>

0000000080000cd8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80000cd8:	7159                	add	sp,sp,-112
    80000cda:	f486                	sd	ra,104(sp)
    80000cdc:	f0a2                	sd	s0,96(sp)
    80000cde:	eca6                	sd	s1,88(sp)
    80000ce0:	e8ca                	sd	s2,80(sp)
    80000ce2:	e4ce                	sd	s3,72(sp)
    80000ce4:	e0d2                	sd	s4,64(sp)
    80000ce6:	fc56                	sd	s5,56(sp)
    80000ce8:	f85a                	sd	s6,48(sp)
    80000cea:	f45e                	sd	s7,40(sp)
    80000cec:	f062                	sd	s8,32(sp)
    80000cee:	ec66                	sd	s9,24(sp)
    80000cf0:	e86a                	sd	s10,16(sp)
    80000cf2:	1880                	add	s0,sp,112
    80000cf4:	8a2a                	mv	s4,a0
    80000cf6:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80000cf8:	00c52c83          	lw	s9,12(a0)
    80000cfc:	001c9c9b          	sllw	s9,s9,0x1
    80000d00:	1c82                	sll	s9,s9,0x20
    80000d02:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80000d06:	00011517          	auipc	a0,0x11
    80000d0a:	4a250513          	add	a0,a0,1186 # 800121a8 <disk+0x128>
    80000d0e:	00002097          	auipc	ra,0x2
    80000d12:	360080e7          	jalr	864(ra) # 8000306e <acquire>
  for(int i = 0; i < 3; i++){
    80000d16:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80000d18:	44a1                	li	s1,8
      disk.free[i] = 0;
    80000d1a:	00011b17          	auipc	s6,0x11
    80000d1e:	366b0b13          	add	s6,s6,870 # 80012080 <disk>
  for(int i = 0; i < 3; i++){
    80000d22:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80000d24:	00011c17          	auipc	s8,0x11
    80000d28:	484c0c13          	add	s8,s8,1156 # 800121a8 <disk+0x128>
    80000d2c:	a095                	j	80000d90 <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80000d2e:	00fb0733          	add	a4,s6,a5
    80000d32:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80000d36:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80000d38:	0207c563          	bltz	a5,80000d62 <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80000d3c:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80000d3e:	0591                	add	a1,a1,4
    80000d40:	05560d63          	beq	a2,s5,80000d9a <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80000d44:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80000d46:	00011717          	auipc	a4,0x11
    80000d4a:	33a70713          	add	a4,a4,826 # 80012080 <disk>
    80000d4e:	87ca                	mv	a5,s2
    if(disk.free[i]){
    80000d50:	01874683          	lbu	a3,24(a4)
    80000d54:	fee9                	bnez	a3,80000d2e <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80000d56:	2785                	addw	a5,a5,1
    80000d58:	0705                	add	a4,a4,1
    80000d5a:	fe979be3          	bne	a5,s1,80000d50 <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80000d5e:	57fd                	li	a5,-1
    80000d60:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    80000d62:	00c05e63          	blez	a2,80000d7e <virtio_disk_rw+0xa6>
    80000d66:	060a                	sll	a2,a2,0x2
    80000d68:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80000d6c:	0009a503          	lw	a0,0(s3)
    80000d70:	00000097          	auipc	ra,0x0
    80000d74:	d02080e7          	jalr	-766(ra) # 80000a72 <free_desc>
      for(int j = 0; j < i; j++)
    80000d78:	0991                	add	s3,s3,4
    80000d7a:	ffa999e3          	bne	s3,s10,80000d6c <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80000d7e:	85e2                	mv	a1,s8
    80000d80:	00011517          	auipc	a0,0x11
    80000d84:	31850513          	add	a0,a0,792 # 80012098 <disk+0x18>
    80000d88:	00002097          	auipc	ra,0x2
    80000d8c:	b98080e7          	jalr	-1128(ra) # 80002920 <sleep>
  for(int i = 0; i < 3; i++){
    80000d90:	f9040993          	add	s3,s0,-112
{
    80000d94:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80000d96:	864a                	mv	a2,s2
    80000d98:	b775                	j	80000d44 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80000d9a:	f9042503          	lw	a0,-112(s0)
    80000d9e:	00a50713          	add	a4,a0,10
    80000da2:	0712                	sll	a4,a4,0x4

  if(write)
    80000da4:	00011797          	auipc	a5,0x11
    80000da8:	2dc78793          	add	a5,a5,732 # 80012080 <disk>
    80000dac:	00e786b3          	add	a3,a5,a4
    80000db0:	01703633          	snez	a2,s7
    80000db4:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80000db6:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80000dba:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80000dbe:	f6070613          	add	a2,a4,-160
    80000dc2:	6394                	ld	a3,0(a5)
    80000dc4:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80000dc6:	00870593          	add	a1,a4,8
    80000dca:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80000dcc:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80000dce:	0007b803          	ld	a6,0(a5)
    80000dd2:	9642                	add	a2,a2,a6
    80000dd4:	46c1                	li	a3,16
    80000dd6:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80000dd8:	4585                	li	a1,1
    80000dda:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80000dde:	f9442683          	lw	a3,-108(s0)
    80000de2:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80000de6:	0692                	sll	a3,a3,0x4
    80000de8:	9836                	add	a6,a6,a3
    80000dea:	058a0613          	add	a2,s4,88
    80000dee:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    80000df2:	0007b803          	ld	a6,0(a5)
    80000df6:	96c2                	add	a3,a3,a6
    80000df8:	40000613          	li	a2,1024
    80000dfc:	c690                	sw	a2,8(a3)
  if(write)
    80000dfe:	001bb613          	seqz	a2,s7
    80000e02:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80000e06:	00166613          	or	a2,a2,1
    80000e0a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80000e0e:	f9842603          	lw	a2,-104(s0)
    80000e12:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80000e16:	00250693          	add	a3,a0,2
    80000e1a:	0692                	sll	a3,a3,0x4
    80000e1c:	96be                	add	a3,a3,a5
    80000e1e:	58fd                	li	a7,-1
    80000e20:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80000e24:	0612                	sll	a2,a2,0x4
    80000e26:	9832                	add	a6,a6,a2
    80000e28:	f9070713          	add	a4,a4,-112
    80000e2c:	973e                	add	a4,a4,a5
    80000e2e:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    80000e32:	6398                	ld	a4,0(a5)
    80000e34:	9732                	add	a4,a4,a2
    80000e36:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80000e38:	4609                	li	a2,2
    80000e3a:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80000e3e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80000e42:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80000e46:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80000e4a:	6794                	ld	a3,8(a5)
    80000e4c:	0026d703          	lhu	a4,2(a3)
    80000e50:	8b1d                	and	a4,a4,7
    80000e52:	0706                	sll	a4,a4,0x1
    80000e54:	96ba                	add	a3,a3,a4
    80000e56:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80000e5a:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80000e5e:	6798                	ld	a4,8(a5)
    80000e60:	00275783          	lhu	a5,2(a4)
    80000e64:	2785                	addw	a5,a5,1
    80000e66:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80000e6a:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80000e6e:	100017b7          	lui	a5,0x10001
    80000e72:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80000e76:	004a2783          	lw	a5,4(s4)
    // printf("virtio_disk_rw: sleeping on buf %p\n", b);
    sleep(b, &disk.vdisk_lock);
    80000e7a:	00011917          	auipc	s2,0x11
    80000e7e:	32e90913          	add	s2,s2,814 # 800121a8 <disk+0x128>
  while(b->disk == 1) {
    80000e82:	4485                	li	s1,1
    80000e84:	00b79c63          	bne	a5,a1,80000e9c <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80000e88:	85ca                	mv	a1,s2
    80000e8a:	8552                	mv	a0,s4
    80000e8c:	00002097          	auipc	ra,0x2
    80000e90:	a94080e7          	jalr	-1388(ra) # 80002920 <sleep>
  while(b->disk == 1) {
    80000e94:	004a2783          	lw	a5,4(s4)
    80000e98:	fe9788e3          	beq	a5,s1,80000e88 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80000e9c:	f9042903          	lw	s2,-112(s0)
    80000ea0:	00290713          	add	a4,s2,2
    80000ea4:	0712                	sll	a4,a4,0x4
    80000ea6:	00011797          	auipc	a5,0x11
    80000eaa:	1da78793          	add	a5,a5,474 # 80012080 <disk>
    80000eae:	97ba                	add	a5,a5,a4
    80000eb0:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80000eb4:	00011997          	auipc	s3,0x11
    80000eb8:	1cc98993          	add	s3,s3,460 # 80012080 <disk>
    80000ebc:	00491713          	sll	a4,s2,0x4
    80000ec0:	0009b783          	ld	a5,0(s3)
    80000ec4:	97ba                	add	a5,a5,a4
    80000ec6:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80000eca:	854a                	mv	a0,s2
    80000ecc:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80000ed0:	00000097          	auipc	ra,0x0
    80000ed4:	ba2080e7          	jalr	-1118(ra) # 80000a72 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80000ed8:	8885                	and	s1,s1,1
    80000eda:	f0ed                	bnez	s1,80000ebc <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80000edc:	00011517          	auipc	a0,0x11
    80000ee0:	2cc50513          	add	a0,a0,716 # 800121a8 <disk+0x128>
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	23e080e7          	jalr	574(ra) # 80003122 <release>
}
    80000eec:	70a6                	ld	ra,104(sp)
    80000eee:	7406                	ld	s0,96(sp)
    80000ef0:	64e6                	ld	s1,88(sp)
    80000ef2:	6946                	ld	s2,80(sp)
    80000ef4:	69a6                	ld	s3,72(sp)
    80000ef6:	6a06                	ld	s4,64(sp)
    80000ef8:	7ae2                	ld	s5,56(sp)
    80000efa:	7b42                	ld	s6,48(sp)
    80000efc:	7ba2                	ld	s7,40(sp)
    80000efe:	7c02                	ld	s8,32(sp)
    80000f00:	6ce2                	ld	s9,24(sp)
    80000f02:	6d42                	ld	s10,16(sp)
    80000f04:	6165                	add	sp,sp,112
    80000f06:	8082                	ret

0000000080000f08 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80000f08:	1101                	add	sp,sp,-32
    80000f0a:	ec06                	sd	ra,24(sp)
    80000f0c:	e822                	sd	s0,16(sp)
    80000f0e:	e426                	sd	s1,8(sp)
    80000f10:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    80000f12:	00011497          	auipc	s1,0x11
    80000f16:	16e48493          	add	s1,s1,366 # 80012080 <disk>
    80000f1a:	00011517          	auipc	a0,0x11
    80000f1e:	28e50513          	add	a0,a0,654 # 800121a8 <disk+0x128>
    80000f22:	00002097          	auipc	ra,0x2
    80000f26:	14c080e7          	jalr	332(ra) # 8000306e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80000f2a:	10001737          	lui	a4,0x10001
    80000f2e:	533c                	lw	a5,96(a4)
    80000f30:	8b8d                	and	a5,a5,3
    80000f32:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80000f34:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80000f38:	689c                	ld	a5,16(s1)
    80000f3a:	0204d703          	lhu	a4,32(s1)
    80000f3e:	0027d783          	lhu	a5,2(a5)
    80000f42:	04f70863          	beq	a4,a5,80000f92 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80000f46:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80000f4a:	6898                	ld	a4,16(s1)
    80000f4c:	0204d783          	lhu	a5,32(s1)
    80000f50:	8b9d                	and	a5,a5,7
    80000f52:	078e                	sll	a5,a5,0x3
    80000f54:	97ba                	add	a5,a5,a4
    80000f56:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80000f58:	00278713          	add	a4,a5,2
    80000f5c:	0712                	sll	a4,a4,0x4
    80000f5e:	9726                	add	a4,a4,s1
    80000f60:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80000f64:	e721                	bnez	a4,80000fac <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80000f66:	0789                	add	a5,a5,2
    80000f68:	0792                	sll	a5,a5,0x4
    80000f6a:	97a6                	add	a5,a5,s1
    80000f6c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80000f6e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	a1c080e7          	jalr	-1508(ra) # 8000298e <wakeup>

    disk.used_idx += 1;
    80000f7a:	0204d783          	lhu	a5,32(s1)
    80000f7e:	2785                	addw	a5,a5,1
    80000f80:	17c2                	sll	a5,a5,0x30
    80000f82:	93c1                	srl	a5,a5,0x30
    80000f84:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80000f88:	6898                	ld	a4,16(s1)
    80000f8a:	00275703          	lhu	a4,2(a4)
    80000f8e:	faf71ce3          	bne	a4,a5,80000f46 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80000f92:	00011517          	auipc	a0,0x11
    80000f96:	21650513          	add	a0,a0,534 # 800121a8 <disk+0x128>
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	188080e7          	jalr	392(ra) # 80003122 <release>
}
    80000fa2:	60e2                	ld	ra,24(sp)
    80000fa4:	6442                	ld	s0,16(sp)
    80000fa6:	64a2                	ld	s1,8(sp)
    80000fa8:	6105                	add	sp,sp,32
    80000faa:	8082                	ret
      panic("virtio_disk_intr status");
    80000fac:	00008517          	auipc	a0,0x8
    80000fb0:	20450513          	add	a0,a0,516 # 800091b0 <states.0+0x118>
    80000fb4:	00000097          	auipc	ra,0x0
    80000fb8:	250080e7          	jalr	592(ra) # 80001204 <panic>

0000000080000fbc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000fbc:	1141                	add	sp,sp,-16
    80000fbe:	e422                	sd	s0,8(sp)
    80000fc0:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000fc2:	ca19                	beqz	a2,80000fd8 <memset+0x1c>
    80000fc4:	87aa                	mv	a5,a0
    80000fc6:	1602                	sll	a2,a2,0x20
    80000fc8:	9201                	srl	a2,a2,0x20
    80000fca:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000fce:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000fd2:	0785                	add	a5,a5,1
    80000fd4:	fee79de3          	bne	a5,a4,80000fce <memset+0x12>
  }
  return dst;
}
    80000fd8:	6422                	ld	s0,8(sp)
    80000fda:	0141                	add	sp,sp,16
    80000fdc:	8082                	ret

0000000080000fde <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000fde:	1141                	add	sp,sp,-16
    80000fe0:	e422                	sd	s0,8(sp)
    80000fe2:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000fe4:	ca05                	beqz	a2,80001014 <memcmp+0x36>
    80000fe6:	fff6069b          	addw	a3,a2,-1
    80000fea:	1682                	sll	a3,a3,0x20
    80000fec:	9281                	srl	a3,a3,0x20
    80000fee:	0685                	add	a3,a3,1
    80000ff0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ff2:	00054783          	lbu	a5,0(a0)
    80000ff6:	0005c703          	lbu	a4,0(a1)
    80000ffa:	00e79863          	bne	a5,a4,8000100a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ffe:	0505                	add	a0,a0,1
    80001000:	0585                	add	a1,a1,1
  while(n-- > 0){
    80001002:	fed518e3          	bne	a0,a3,80000ff2 <memcmp+0x14>
  }

  return 0;
    80001006:	4501                	li	a0,0
    80001008:	a019                	j	8000100e <memcmp+0x30>
      return *s1 - *s2;
    8000100a:	40e7853b          	subw	a0,a5,a4
}
    8000100e:	6422                	ld	s0,8(sp)
    80001010:	0141                	add	sp,sp,16
    80001012:	8082                	ret
  return 0;
    80001014:	4501                	li	a0,0
    80001016:	bfe5                	j	8000100e <memcmp+0x30>

0000000080001018 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001018:	1141                	add	sp,sp,-16
    8000101a:	e422                	sd	s0,8(sp)
    8000101c:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000101e:	c205                	beqz	a2,8000103e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001020:	02a5e263          	bltu	a1,a0,80001044 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001024:	1602                	sll	a2,a2,0x20
    80001026:	9201                	srl	a2,a2,0x20
    80001028:	00c587b3          	add	a5,a1,a2
{
    8000102c:	872a                	mv	a4,a0
      *d++ = *s++;
    8000102e:	0585                	add	a1,a1,1
    80001030:	0705                	add	a4,a4,1
    80001032:	fff5c683          	lbu	a3,-1(a1)
    80001036:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    8000103a:	fef59ae3          	bne	a1,a5,8000102e <memmove+0x16>

  return dst;
}
    8000103e:	6422                	ld	s0,8(sp)
    80001040:	0141                	add	sp,sp,16
    80001042:	8082                	ret
  if(s < d && s + n > d){
    80001044:	02061693          	sll	a3,a2,0x20
    80001048:	9281                	srl	a3,a3,0x20
    8000104a:	00d58733          	add	a4,a1,a3
    8000104e:	fce57be3          	bgeu	a0,a4,80001024 <memmove+0xc>
    d += n;
    80001052:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80001054:	fff6079b          	addw	a5,a2,-1
    80001058:	1782                	sll	a5,a5,0x20
    8000105a:	9381                	srl	a5,a5,0x20
    8000105c:	fff7c793          	not	a5,a5
    80001060:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80001062:	177d                	add	a4,a4,-1
    80001064:	16fd                	add	a3,a3,-1
    80001066:	00074603          	lbu	a2,0(a4)
    8000106a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    8000106e:	fee79ae3          	bne	a5,a4,80001062 <memmove+0x4a>
    80001072:	b7f1                	j	8000103e <memmove+0x26>

0000000080001074 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001074:	1141                	add	sp,sp,-16
    80001076:	e406                	sd	ra,8(sp)
    80001078:	e022                	sd	s0,0(sp)
    8000107a:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	f9c080e7          	jalr	-100(ra) # 80001018 <memmove>
}
    80001084:	60a2                	ld	ra,8(sp)
    80001086:	6402                	ld	s0,0(sp)
    80001088:	0141                	add	sp,sp,16
    8000108a:	8082                	ret

000000008000108c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    8000108c:	1141                	add	sp,sp,-16
    8000108e:	e422                	sd	s0,8(sp)
    80001090:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001092:	ce11                	beqz	a2,800010ae <strncmp+0x22>
    80001094:	00054783          	lbu	a5,0(a0)
    80001098:	cf89                	beqz	a5,800010b2 <strncmp+0x26>
    8000109a:	0005c703          	lbu	a4,0(a1)
    8000109e:	00f71a63          	bne	a4,a5,800010b2 <strncmp+0x26>
    n--, p++, q++;
    800010a2:	367d                	addw	a2,a2,-1
    800010a4:	0505                	add	a0,a0,1
    800010a6:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800010a8:	f675                	bnez	a2,80001094 <strncmp+0x8>
  if(n == 0)
    return 0;
    800010aa:	4501                	li	a0,0
    800010ac:	a809                	j	800010be <strncmp+0x32>
    800010ae:	4501                	li	a0,0
    800010b0:	a039                	j	800010be <strncmp+0x32>
  if(n == 0)
    800010b2:	ca09                	beqz	a2,800010c4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800010b4:	00054503          	lbu	a0,0(a0)
    800010b8:	0005c783          	lbu	a5,0(a1)
    800010bc:	9d1d                	subw	a0,a0,a5
}
    800010be:	6422                	ld	s0,8(sp)
    800010c0:	0141                	add	sp,sp,16
    800010c2:	8082                	ret
    return 0;
    800010c4:	4501                	li	a0,0
    800010c6:	bfe5                	j	800010be <strncmp+0x32>

00000000800010c8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800010c8:	1141                	add	sp,sp,-16
    800010ca:	e422                	sd	s0,8(sp)
    800010cc:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800010ce:	87aa                	mv	a5,a0
    800010d0:	86b2                	mv	a3,a2
    800010d2:	367d                	addw	a2,a2,-1
    800010d4:	00d05963          	blez	a3,800010e6 <strncpy+0x1e>
    800010d8:	0785                	add	a5,a5,1
    800010da:	0005c703          	lbu	a4,0(a1)
    800010de:	fee78fa3          	sb	a4,-1(a5)
    800010e2:	0585                	add	a1,a1,1
    800010e4:	f775                	bnez	a4,800010d0 <strncpy+0x8>
    ;
  while(n-- > 0)
    800010e6:	873e                	mv	a4,a5
    800010e8:	9fb5                	addw	a5,a5,a3
    800010ea:	37fd                	addw	a5,a5,-1
    800010ec:	00c05963          	blez	a2,800010fe <strncpy+0x36>
    *s++ = 0;
    800010f0:	0705                	add	a4,a4,1
    800010f2:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    800010f6:	40e786bb          	subw	a3,a5,a4
    800010fa:	fed04be3          	bgtz	a3,800010f0 <strncpy+0x28>
  return os;
}
    800010fe:	6422                	ld	s0,8(sp)
    80001100:	0141                	add	sp,sp,16
    80001102:	8082                	ret

0000000080001104 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001104:	1141                	add	sp,sp,-16
    80001106:	e422                	sd	s0,8(sp)
    80001108:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000110a:	02c05363          	blez	a2,80001130 <safestrcpy+0x2c>
    8000110e:	fff6069b          	addw	a3,a2,-1
    80001112:	1682                	sll	a3,a3,0x20
    80001114:	9281                	srl	a3,a3,0x20
    80001116:	96ae                	add	a3,a3,a1
    80001118:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000111a:	00d58963          	beq	a1,a3,8000112c <safestrcpy+0x28>
    8000111e:	0585                	add	a1,a1,1
    80001120:	0785                	add	a5,a5,1
    80001122:	fff5c703          	lbu	a4,-1(a1)
    80001126:	fee78fa3          	sb	a4,-1(a5)
    8000112a:	fb65                	bnez	a4,8000111a <safestrcpy+0x16>
    ;
  *s = 0;
    8000112c:	00078023          	sb	zero,0(a5)
  return os;
}
    80001130:	6422                	ld	s0,8(sp)
    80001132:	0141                	add	sp,sp,16
    80001134:	8082                	ret

0000000080001136 <strlen>:

int
strlen(const char *s)
{
    80001136:	1141                	add	sp,sp,-16
    80001138:	e422                	sd	s0,8(sp)
    8000113a:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000113c:	00054783          	lbu	a5,0(a0)
    80001140:	cf91                	beqz	a5,8000115c <strlen+0x26>
    80001142:	0505                	add	a0,a0,1
    80001144:	87aa                	mv	a5,a0
    80001146:	86be                	mv	a3,a5
    80001148:	0785                	add	a5,a5,1
    8000114a:	fff7c703          	lbu	a4,-1(a5)
    8000114e:	ff65                	bnez	a4,80001146 <strlen+0x10>
    80001150:	40a6853b          	subw	a0,a3,a0
    80001154:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80001156:	6422                	ld	s0,8(sp)
    80001158:	0141                	add	sp,sp,16
    8000115a:	8082                	ret
  for(n = 0; s[n]; n++)
    8000115c:	4501                	li	a0,0
    8000115e:	bfe5                	j	80001156 <strlen+0x20>

0000000080001160 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80001160:	7179                	add	sp,sp,-48
    80001162:	f406                	sd	ra,40(sp)
    80001164:	f022                	sd	s0,32(sp)
    80001166:	ec26                	sd	s1,24(sp)
    80001168:	e84a                	sd	s2,16(sp)
    8000116a:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000116c:	c219                	beqz	a2,80001172 <printint+0x12>
    8000116e:	08054763          	bltz	a0,800011fc <printint+0x9c>
    x = -xx;
  else
    x = xx;
    80001172:	2501                	sext.w	a0,a0
    80001174:	4881                	li	a7,0
    80001176:	fd040693          	add	a3,s0,-48

  i = 0;
    8000117a:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    8000117c:	2581                	sext.w	a1,a1
    8000117e:	00008617          	auipc	a2,0x8
    80001182:	07260613          	add	a2,a2,114 # 800091f0 <digits>
    80001186:	883a                	mv	a6,a4
    80001188:	2705                	addw	a4,a4,1
    8000118a:	02b577bb          	remuw	a5,a0,a1
    8000118e:	1782                	sll	a5,a5,0x20
    80001190:	9381                	srl	a5,a5,0x20
    80001192:	97b2                	add	a5,a5,a2
    80001194:	0007c783          	lbu	a5,0(a5)
    80001198:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    8000119c:	0005079b          	sext.w	a5,a0
    800011a0:	02b5553b          	divuw	a0,a0,a1
    800011a4:	0685                	add	a3,a3,1
    800011a6:	feb7f0e3          	bgeu	a5,a1,80001186 <printint+0x26>

  if(sign)
    800011aa:	00088c63          	beqz	a7,800011c2 <printint+0x62>
    buf[i++] = '-';
    800011ae:	fe070793          	add	a5,a4,-32
    800011b2:	00878733          	add	a4,a5,s0
    800011b6:	02d00793          	li	a5,45
    800011ba:	fef70823          	sb	a5,-16(a4)
    800011be:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800011c2:	02e05763          	blez	a4,800011f0 <printint+0x90>
    800011c6:	fd040793          	add	a5,s0,-48
    800011ca:	00e784b3          	add	s1,a5,a4
    800011ce:	fff78913          	add	s2,a5,-1
    800011d2:	993a                	add	s2,s2,a4
    800011d4:	377d                	addw	a4,a4,-1
    800011d6:	1702                	sll	a4,a4,0x20
    800011d8:	9301                	srl	a4,a4,0x20
    800011da:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    800011de:	fff4c503          	lbu	a0,-1(s1)
    800011e2:	fffff097          	auipc	ra,0xfffff
    800011e6:	52a080e7          	jalr	1322(ra) # 8000070c <consputc>
  while(--i >= 0)
    800011ea:	14fd                	add	s1,s1,-1
    800011ec:	ff2499e3          	bne	s1,s2,800011de <printint+0x7e>
}
    800011f0:	70a2                	ld	ra,40(sp)
    800011f2:	7402                	ld	s0,32(sp)
    800011f4:	64e2                	ld	s1,24(sp)
    800011f6:	6942                	ld	s2,16(sp)
    800011f8:	6145                	add	sp,sp,48
    800011fa:	8082                	ret
    x = -xx;
    800011fc:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80001200:	4885                	li	a7,1
    x = -xx;
    80001202:	bf95                	j	80001176 <printint+0x16>

0000000080001204 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80001204:	1101                	add	sp,sp,-32
    80001206:	ec06                	sd	ra,24(sp)
    80001208:	e822                	sd	s0,16(sp)
    8000120a:	e426                	sd	s1,8(sp)
    8000120c:	1000                	add	s0,sp,32
    8000120e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80001210:	00011797          	auipc	a5,0x11
    80001214:	fc07a423          	sw	zero,-56(a5) # 800121d8 <pr+0x18>
  printf("panic: ");
    80001218:	00008517          	auipc	a0,0x8
    8000121c:	fb050513          	add	a0,a0,-80 # 800091c8 <states.0+0x130>
    80001220:	00000097          	auipc	ra,0x0
    80001224:	02e080e7          	jalr	46(ra) # 8000124e <printf>
  printf(s);
    80001228:	8526                	mv	a0,s1
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	024080e7          	jalr	36(ra) # 8000124e <printf>
  printf("\n");
    80001232:	00009517          	auipc	a0,0x9
    80001236:	b0650513          	add	a0,a0,-1274 # 80009d38 <syscalls+0x560>
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	014080e7          	jalr	20(ra) # 8000124e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80001242:	4785                	li	a5,1
    80001244:	00009717          	auipc	a4,0x9
    80001248:	bcf72223          	sw	a5,-1084(a4) # 80009e08 <panicked>
  for(;;)
    8000124c:	a001                	j	8000124c <panic+0x48>

000000008000124e <printf>:
{
    8000124e:	7131                	add	sp,sp,-192
    80001250:	fc86                	sd	ra,120(sp)
    80001252:	f8a2                	sd	s0,112(sp)
    80001254:	f4a6                	sd	s1,104(sp)
    80001256:	f0ca                	sd	s2,96(sp)
    80001258:	ecce                	sd	s3,88(sp)
    8000125a:	e8d2                	sd	s4,80(sp)
    8000125c:	e4d6                	sd	s5,72(sp)
    8000125e:	e0da                	sd	s6,64(sp)
    80001260:	fc5e                	sd	s7,56(sp)
    80001262:	f862                	sd	s8,48(sp)
    80001264:	f466                	sd	s9,40(sp)
    80001266:	f06a                	sd	s10,32(sp)
    80001268:	ec6e                	sd	s11,24(sp)
    8000126a:	0100                	add	s0,sp,128
    8000126c:	8a2a                	mv	s4,a0
    8000126e:	e40c                	sd	a1,8(s0)
    80001270:	e810                	sd	a2,16(s0)
    80001272:	ec14                	sd	a3,24(s0)
    80001274:	f018                	sd	a4,32(s0)
    80001276:	f41c                	sd	a5,40(s0)
    80001278:	03043823          	sd	a6,48(s0)
    8000127c:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80001280:	00011d97          	auipc	s11,0x11
    80001284:	f58dad83          	lw	s11,-168(s11) # 800121d8 <pr+0x18>
  if(locking)
    80001288:	020d9b63          	bnez	s11,800012be <printf+0x70>
  if (fmt == 0)
    8000128c:	040a0263          	beqz	s4,800012d0 <printf+0x82>
  va_start(ap, fmt);
    80001290:	00840793          	add	a5,s0,8
    80001294:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80001298:	000a4503          	lbu	a0,0(s4)
    8000129c:	14050f63          	beqz	a0,800013fa <printf+0x1ac>
    800012a0:	4981                	li	s3,0
    if(c != '%'){
    800012a2:	02500a93          	li	s5,37
    switch(c){
    800012a6:	07000b93          	li	s7,112
  consputc('x');
    800012aa:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800012ac:	00008b17          	auipc	s6,0x8
    800012b0:	f44b0b13          	add	s6,s6,-188 # 800091f0 <digits>
    switch(c){
    800012b4:	07300c93          	li	s9,115
    800012b8:	06400c13          	li	s8,100
    800012bc:	a82d                	j	800012f6 <printf+0xa8>
    acquire(&pr.lock);
    800012be:	00011517          	auipc	a0,0x11
    800012c2:	f0250513          	add	a0,a0,-254 # 800121c0 <pr>
    800012c6:	00002097          	auipc	ra,0x2
    800012ca:	da8080e7          	jalr	-600(ra) # 8000306e <acquire>
    800012ce:	bf7d                	j	8000128c <printf+0x3e>
    panic("null fmt");
    800012d0:	00008517          	auipc	a0,0x8
    800012d4:	f0850513          	add	a0,a0,-248 # 800091d8 <states.0+0x140>
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f2c080e7          	jalr	-212(ra) # 80001204 <panic>
      consputc(c);
    800012e0:	fffff097          	auipc	ra,0xfffff
    800012e4:	42c080e7          	jalr	1068(ra) # 8000070c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800012e8:	2985                	addw	s3,s3,1
    800012ea:	013a07b3          	add	a5,s4,s3
    800012ee:	0007c503          	lbu	a0,0(a5)
    800012f2:	10050463          	beqz	a0,800013fa <printf+0x1ac>
    if(c != '%'){
    800012f6:	ff5515e3          	bne	a0,s5,800012e0 <printf+0x92>
    c = fmt[++i] & 0xff;
    800012fa:	2985                	addw	s3,s3,1
    800012fc:	013a07b3          	add	a5,s4,s3
    80001300:	0007c783          	lbu	a5,0(a5)
    80001304:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80001308:	cbed                	beqz	a5,800013fa <printf+0x1ac>
    switch(c){
    8000130a:	05778a63          	beq	a5,s7,8000135e <printf+0x110>
    8000130e:	02fbf663          	bgeu	s7,a5,8000133a <printf+0xec>
    80001312:	09978863          	beq	a5,s9,800013a2 <printf+0x154>
    80001316:	07800713          	li	a4,120
    8000131a:	0ce79563          	bne	a5,a4,800013e4 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000131e:	f8843783          	ld	a5,-120(s0)
    80001322:	00878713          	add	a4,a5,8
    80001326:	f8e43423          	sd	a4,-120(s0)
    8000132a:	4605                	li	a2,1
    8000132c:	85ea                	mv	a1,s10
    8000132e:	4388                	lw	a0,0(a5)
    80001330:	00000097          	auipc	ra,0x0
    80001334:	e30080e7          	jalr	-464(ra) # 80001160 <printint>
      break;
    80001338:	bf45                	j	800012e8 <printf+0x9a>
    switch(c){
    8000133a:	09578f63          	beq	a5,s5,800013d8 <printf+0x18a>
    8000133e:	0b879363          	bne	a5,s8,800013e4 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80001342:	f8843783          	ld	a5,-120(s0)
    80001346:	00878713          	add	a4,a5,8
    8000134a:	f8e43423          	sd	a4,-120(s0)
    8000134e:	4605                	li	a2,1
    80001350:	45a9                	li	a1,10
    80001352:	4388                	lw	a0,0(a5)
    80001354:	00000097          	auipc	ra,0x0
    80001358:	e0c080e7          	jalr	-500(ra) # 80001160 <printint>
      break;
    8000135c:	b771                	j	800012e8 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000135e:	f8843783          	ld	a5,-120(s0)
    80001362:	00878713          	add	a4,a5,8
    80001366:	f8e43423          	sd	a4,-120(s0)
    8000136a:	0007b903          	ld	s2,0(a5)
  consputc('0');
    8000136e:	03000513          	li	a0,48
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	39a080e7          	jalr	922(ra) # 8000070c <consputc>
  consputc('x');
    8000137a:	07800513          	li	a0,120
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	38e080e7          	jalr	910(ra) # 8000070c <consputc>
    80001386:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80001388:	03c95793          	srl	a5,s2,0x3c
    8000138c:	97da                	add	a5,a5,s6
    8000138e:	0007c503          	lbu	a0,0(a5)
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	37a080e7          	jalr	890(ra) # 8000070c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000139a:	0912                	sll	s2,s2,0x4
    8000139c:	34fd                	addw	s1,s1,-1
    8000139e:	f4ed                	bnez	s1,80001388 <printf+0x13a>
    800013a0:	b7a1                	j	800012e8 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800013a2:	f8843783          	ld	a5,-120(s0)
    800013a6:	00878713          	add	a4,a5,8
    800013aa:	f8e43423          	sd	a4,-120(s0)
    800013ae:	6384                	ld	s1,0(a5)
    800013b0:	cc89                	beqz	s1,800013ca <printf+0x17c>
      for(; *s; s++)
    800013b2:	0004c503          	lbu	a0,0(s1)
    800013b6:	d90d                	beqz	a0,800012e8 <printf+0x9a>
        consputc(*s);
    800013b8:	fffff097          	auipc	ra,0xfffff
    800013bc:	354080e7          	jalr	852(ra) # 8000070c <consputc>
      for(; *s; s++)
    800013c0:	0485                	add	s1,s1,1
    800013c2:	0004c503          	lbu	a0,0(s1)
    800013c6:	f96d                	bnez	a0,800013b8 <printf+0x16a>
    800013c8:	b705                	j	800012e8 <printf+0x9a>
        s = "(null)";
    800013ca:	00008497          	auipc	s1,0x8
    800013ce:	e0648493          	add	s1,s1,-506 # 800091d0 <states.0+0x138>
      for(; *s; s++)
    800013d2:	02800513          	li	a0,40
    800013d6:	b7cd                	j	800013b8 <printf+0x16a>
      consputc('%');
    800013d8:	8556                	mv	a0,s5
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	332080e7          	jalr	818(ra) # 8000070c <consputc>
      break;
    800013e2:	b719                	j	800012e8 <printf+0x9a>
      consputc('%');
    800013e4:	8556                	mv	a0,s5
    800013e6:	fffff097          	auipc	ra,0xfffff
    800013ea:	326080e7          	jalr	806(ra) # 8000070c <consputc>
      consputc(c);
    800013ee:	8526                	mv	a0,s1
    800013f0:	fffff097          	auipc	ra,0xfffff
    800013f4:	31c080e7          	jalr	796(ra) # 8000070c <consputc>
      break;
    800013f8:	bdc5                	j	800012e8 <printf+0x9a>
  if(locking)
    800013fa:	020d9163          	bnez	s11,8000141c <printf+0x1ce>
}
    800013fe:	70e6                	ld	ra,120(sp)
    80001400:	7446                	ld	s0,112(sp)
    80001402:	74a6                	ld	s1,104(sp)
    80001404:	7906                	ld	s2,96(sp)
    80001406:	69e6                	ld	s3,88(sp)
    80001408:	6a46                	ld	s4,80(sp)
    8000140a:	6aa6                	ld	s5,72(sp)
    8000140c:	6b06                	ld	s6,64(sp)
    8000140e:	7be2                	ld	s7,56(sp)
    80001410:	7c42                	ld	s8,48(sp)
    80001412:	7ca2                	ld	s9,40(sp)
    80001414:	7d02                	ld	s10,32(sp)
    80001416:	6de2                	ld	s11,24(sp)
    80001418:	6129                	add	sp,sp,192
    8000141a:	8082                	ret
    release(&pr.lock);
    8000141c:	00011517          	auipc	a0,0x11
    80001420:	da450513          	add	a0,a0,-604 # 800121c0 <pr>
    80001424:	00002097          	auipc	ra,0x2
    80001428:	cfe080e7          	jalr	-770(ra) # 80003122 <release>
}
    8000142c:	bfc9                	j	800013fe <printf+0x1b0>

000000008000142e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000142e:	1101                	add	sp,sp,-32
    80001430:	ec06                	sd	ra,24(sp)
    80001432:	e822                	sd	s0,16(sp)
    80001434:	e426                	sd	s1,8(sp)
    80001436:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80001438:	00011497          	auipc	s1,0x11
    8000143c:	d8848493          	add	s1,s1,-632 # 800121c0 <pr>
    80001440:	00008597          	auipc	a1,0x8
    80001444:	da858593          	add	a1,a1,-600 # 800091e8 <states.0+0x150>
    80001448:	8526                	mv	a0,s1
    8000144a:	00002097          	auipc	ra,0x2
    8000144e:	b94080e7          	jalr	-1132(ra) # 80002fde <initlock>
  pr.locking = 1;
    80001452:	4785                	li	a5,1
    80001454:	cc9c                	sw	a5,24(s1)
}
    80001456:	60e2                	ld	ra,24(sp)
    80001458:	6442                	ld	s0,16(sp)
    8000145a:	64a2                	ld	s1,8(sp)
    8000145c:	6105                	add	sp,sp,32
    8000145e:	8082                	ret

0000000080001460 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(uint64 page, bool in_kernel)
{
    80001460:	1101                	add	sp,sp,-32
    80001462:	ec06                	sd	ra,24(sp)
    80001464:	e822                	sd	s0,16(sp)
    80001466:	e426                	sd	s1,8(sp)
    80001468:	e04a                	sd	s2,0(sp)
    8000146a:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)page % PGSIZE) != 0 || (char*)page < end || (uint64)page >= PHYSTOP) //检测合法性
    8000146c:	03451793          	sll	a5,a0,0x34
    80001470:	ebb9                	bnez	a5,800014c6 <kfree+0x66>
    80001472:	84aa                	mv	s1,a0
    80001474:	00022797          	auipc	a5,0x22
    80001478:	e4478793          	add	a5,a5,-444 # 800232b8 <end>
    8000147c:	04f56563          	bltu	a0,a5,800014c6 <kfree+0x66>
    80001480:	47c5                	li	a5,17
    80001482:	07ee                	sll	a5,a5,0x1b
    80001484:	04f57163          	bgeu	a0,a5,800014c6 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset((char*)page, 1, PGSIZE); 
    80001488:	6605                	lui	a2,0x1
    8000148a:	4585                	li	a1,1
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	b30080e7          	jalr	-1232(ra) # 80000fbc <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    80001494:	00011917          	auipc	s2,0x11
    80001498:	d4c90913          	add	s2,s2,-692 # 800121e0 <kmem>
    8000149c:	854a                	mv	a0,s2
    8000149e:	00002097          	auipc	ra,0x2
    800014a2:	bd0080e7          	jalr	-1072(ra) # 8000306e <acquire>
  r->next = kmem.freelist;  //头插
    800014a6:	01893783          	ld	a5,24(s2)
    800014aa:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    800014ac:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    800014b0:	854a                	mv	a0,s2
    800014b2:	00002097          	auipc	ra,0x2
    800014b6:	c70080e7          	jalr	-912(ra) # 80003122 <release>
}
    800014ba:	60e2                	ld	ra,24(sp)
    800014bc:	6442                	ld	s0,16(sp)
    800014be:	64a2                	ld	s1,8(sp)
    800014c0:	6902                	ld	s2,0(sp)
    800014c2:	6105                	add	sp,sp,32
    800014c4:	8082                	ret
    panic("kfree");
    800014c6:	00008517          	auipc	a0,0x8
    800014ca:	d4250513          	add	a0,a0,-702 # 80009208 <digits+0x18>
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	d36080e7          	jalr	-714(ra) # 80001204 <panic>

00000000800014d6 <freerange>:
{
    800014d6:	7179                	add	sp,sp,-48
    800014d8:	f406                	sd	ra,40(sp)
    800014da:	f022                	sd	s0,32(sp)
    800014dc:	ec26                	sd	s1,24(sp)
    800014de:	e84a                	sd	s2,16(sp)
    800014e0:	e44e                	sd	s3,8(sp)
    800014e2:	e052                	sd	s4,0(sp)
    800014e4:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start); //可用内存初始地址对齐4KB
    800014e6:	6785                	lui	a5,0x1
    800014e8:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    800014ec:	00e504b3          	add	s1,a0,a4
    800014f0:	777d                	lui	a4,0xfffff
    800014f2:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800014f4:	94be                	add	s1,s1,a5
    800014f6:	0095ef63          	bltu	a1,s1,80001514 <freerange+0x3e>
    800014fa:	892e                	mv	s2,a1
    kfree((uint64)p,true);
    800014fc:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    800014fe:	6985                	lui	s3,0x1
    kfree((uint64)p,true);
    80001500:	4585                	li	a1,1
    80001502:	01448533          	add	a0,s1,s4
    80001506:	00000097          	auipc	ra,0x0
    8000150a:	f5a080e7          	jalr	-166(ra) # 80001460 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    8000150e:	94ce                	add	s1,s1,s3
    80001510:	fe9978e3          	bgeu	s2,s1,80001500 <freerange+0x2a>
}
    80001514:	70a2                	ld	ra,40(sp)
    80001516:	7402                	ld	s0,32(sp)
    80001518:	64e2                	ld	s1,24(sp)
    8000151a:	6942                	ld	s2,16(sp)
    8000151c:	69a2                	ld	s3,8(sp)
    8000151e:	6a02                	ld	s4,0(sp)
    80001520:	6145                	add	sp,sp,48
    80001522:	8082                	ret

0000000080001524 <kinit>:
{
    80001524:	1141                	add	sp,sp,-16
    80001526:	e406                	sd	ra,8(sp)
    80001528:	e022                	sd	s0,0(sp)
    8000152a:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    8000152c:	00008597          	auipc	a1,0x8
    80001530:	ce458593          	add	a1,a1,-796 # 80009210 <digits+0x20>
    80001534:	00011517          	auipc	a0,0x11
    80001538:	cac50513          	add	a0,a0,-852 # 800121e0 <kmem>
    8000153c:	00002097          	auipc	ra,0x2
    80001540:	aa2080e7          	jalr	-1374(ra) # 80002fde <initlock>
  freerange(end, (void*)PHYSTOP);
    80001544:	45c5                	li	a1,17
    80001546:	05ee                	sll	a1,a1,0x1b
    80001548:	00022517          	auipc	a0,0x22
    8000154c:	d7050513          	add	a0,a0,-656 # 800232b8 <end>
    80001550:	00000097          	auipc	ra,0x0
    80001554:	f86080e7          	jalr	-122(ra) # 800014d6 <freerange>
}
    80001558:	60a2                	ld	ra,8(sp)
    8000155a:	6402                	ld	s0,0(sp)
    8000155c:	0141                	add	sp,sp,16
    8000155e:	8082                	ret

0000000080001560 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(bool in_kernel)
{
    80001560:	1101                	add	sp,sp,-32
    80001562:	ec06                	sd	ra,24(sp)
    80001564:	e822                	sd	s0,16(sp)
    80001566:	e426                	sd	s1,8(sp)
    80001568:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);  
    8000156a:	00011497          	auipc	s1,0x11
    8000156e:	c7648493          	add	s1,s1,-906 # 800121e0 <kmem>
    80001572:	8526                	mv	a0,s1
    80001574:	00002097          	auipc	ra,0x2
    80001578:	afa080e7          	jalr	-1286(ra) # 8000306e <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    8000157c:	6c84                	ld	s1,24(s1)
  if(r)
    8000157e:	c885                	beqz	s1,800015ae <kalloc+0x4e>
    kmem.freelist = r->next;
    80001580:	609c                	ld	a5,0(s1)
    80001582:	00011517          	auipc	a0,0x11
    80001586:	c5e50513          	add	a0,a0,-930 # 800121e0 <kmem>
    8000158a:	ed1c                	sd	a5,24(a0)
  else 
    panic("kalloc: out of memory");
  release(&kmem.lock);
    8000158c:	00002097          	auipc	ra,0x2
    80001590:	b96080e7          	jalr	-1130(ra) # 80003122 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80001594:	6605                	lui	a2,0x1
    80001596:	4595                	li	a1,5
    80001598:	8526                	mv	a0,s1
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	a22080e7          	jalr	-1502(ra) # 80000fbc <memset>
  return (void*)r;
}
    800015a2:	8526                	mv	a0,s1
    800015a4:	60e2                	ld	ra,24(sp)
    800015a6:	6442                	ld	s0,16(sp)
    800015a8:	64a2                	ld	s1,8(sp)
    800015aa:	6105                	add	sp,sp,32
    800015ac:	8082                	ret
    panic("kalloc: out of memory");
    800015ae:	00008517          	auipc	a0,0x8
    800015b2:	c6a50513          	add	a0,a0,-918 # 80009218 <digits+0x28>
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	c4e080e7          	jalr	-946(ra) # 80001204 <panic>

00000000800015be <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    800015be:	1141                	add	sp,sp,-16
    800015c0:	e422                	sd	s0,8(sp)
    800015c2:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800015c4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800015c8:	00009797          	auipc	a5,0x9
    800015cc:	8487b783          	ld	a5,-1976(a5) # 80009e10 <kernel_pagetable>
    800015d0:	83b1                	srl	a5,a5,0xc
    800015d2:	577d                	li	a4,-1
    800015d4:	177e                	sll	a4,a4,0x3f
    800015d6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800015d8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800015dc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800015e0:	6422                	ld	s0,8(sp)
    800015e2:	0141                	add	sp,sp,16
    800015e4:	8082                	ret

00000000800015e6 <walk>:
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc) 
// 虚拟映射查询与建立
// 输入虚拟地址与对应的页表，返回该虚拟地址对应的最低级页表项地址
// alloc为0只查询，为1表示允许在遍历过程中为缺失的中间级页表分配一页。
{
    800015e6:	7139                	add	sp,sp,-64
    800015e8:	fc06                	sd	ra,56(sp)
    800015ea:	f822                	sd	s0,48(sp)
    800015ec:	f426                	sd	s1,40(sp)
    800015ee:	f04a                	sd	s2,32(sp)
    800015f0:	ec4e                	sd	s3,24(sp)
    800015f2:	e852                	sd	s4,16(sp)
    800015f4:	e456                	sd	s5,8(sp)
    800015f6:	e05a                	sd	s6,0(sp)
    800015f8:	0080                	add	s0,sp,64
    800015fa:	84aa                	mv	s1,a0
    800015fc:	89ae                	mv	s3,a1
    800015fe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001600:	57fd                	li	a5,-1
    80001602:	83e9                	srl	a5,a5,0x1a
    80001604:	4a79                	li	s4,30
    panic("walk");
  for(int level = 2; level > 0; level--) {
    80001606:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001608:	04b7f363          	bgeu	a5,a1,8000164e <walk+0x68>
    panic("walk");
    8000160c:	00008517          	auipc	a0,0x8
    80001610:	c2450513          	add	a0,a0,-988 # 80009230 <digits+0x40>
    80001614:	00000097          	auipc	ra,0x0
    80001618:	bf0080e7          	jalr	-1040(ra) # 80001204 <panic>
    if(*pte & PTE_V) { // PTE有效
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
    } else {  // PTE无效，先判断是否可以写入
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
    8000161c:	060a8763          	beqz	s5,8000168a <walk+0xa4>
    80001620:	4505                	li	a0,1
    80001622:	00000097          	auipc	ra,0x0
    80001626:	f3e080e7          	jalr	-194(ra) # 80001560 <kalloc>
    8000162a:	84aa                	mv	s1,a0
    8000162c:	c529                	beqz	a0,80001676 <walk+0x90>
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
    8000162e:	6605                	lui	a2,0x1
    80001630:	4581                	li	a1,0
    80001632:	00000097          	auipc	ra,0x0
    80001636:	98a080e7          	jalr	-1654(ra) # 80000fbc <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    8000163a:	00c4d793          	srl	a5,s1,0xc
    8000163e:	07aa                	sll	a5,a5,0xa
    80001640:	0017e793          	or	a5,a5,1
    80001644:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001648:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdbd3f>
    8000164a:	036a0063          	beq	s4,s6,8000166a <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    8000164e:	0149d933          	srl	s2,s3,s4
    80001652:	1ff97913          	and	s2,s2,511
    80001656:	090e                	sll	s2,s2,0x3
    80001658:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) { // PTE有效
    8000165a:	00093483          	ld	s1,0(s2)
    8000165e:	0014f793          	and	a5,s1,1
    80001662:	dfcd                	beqz	a5,8000161c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte); 
    80001664:	80a9                	srl	s1,s1,0xa
    80001666:	04b2                	sll	s1,s1,0xc
    80001668:	b7c5                	j	80001648 <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];  
    8000166a:	00c9d513          	srl	a0,s3,0xc
    8000166e:	1ff57513          	and	a0,a0,511
    80001672:	050e                	sll	a0,a0,0x3
    80001674:	9526                	add	a0,a0,s1
}
    80001676:	70e2                	ld	ra,56(sp)
    80001678:	7442                	ld	s0,48(sp)
    8000167a:	74a2                	ld	s1,40(sp)
    8000167c:	7902                	ld	s2,32(sp)
    8000167e:	69e2                	ld	s3,24(sp)
    80001680:	6a42                	ld	s4,16(sp)
    80001682:	6aa2                	ld	s5,8(sp)
    80001684:	6b02                	ld	s6,0(sp)
    80001686:	6121                	add	sp,sp,64
    80001688:	8082                	ret
        return 0; // 失败返回0
    8000168a:	4501                	li	a0,0
    8000168c:	b7ed                	j	80001676 <walk+0x90>

000000008000168e <mappages>:
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
    8000168e:	715d                	add	sp,sp,-80
    80001690:	e486                	sd	ra,72(sp)
    80001692:	e0a2                	sd	s0,64(sp)
    80001694:	fc26                	sd	s1,56(sp)
    80001696:	f84a                	sd	s2,48(sp)
    80001698:	f44e                	sd	s3,40(sp)
    8000169a:	f052                	sd	s4,32(sp)
    8000169c:	ec56                	sd	s5,24(sp)
    8000169e:	e85a                	sd	s6,16(sp)
    800016a0:	e45e                	sd	s7,8(sp)
    800016a2:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800016a4:	03459793          	sll	a5,a1,0x34
    800016a8:	e7b9                	bnez	a5,800016f6 <mappages+0x68>
    800016aa:	8aaa                	mv	s5,a0
    800016ac:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    800016ae:	03461793          	sll	a5,a2,0x34
    800016b2:	ebb1                	bnez	a5,80001706 <mappages+0x78>
    panic("mappages: size not aligned");

  if(size == 0)
    800016b4:	c22d                	beqz	a2,80001716 <mappages+0x88>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
    800016b6:	77fd                	lui	a5,0xfffff
    800016b8:	963e                	add	a2,a2,a5
    800016ba:	00b609b3          	add	s3,a2,a1
  a = va;
    800016be:	892e                	mv	s2,a1
    800016c0:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    if(a == last)
      break;
    a += PGSIZE;
    800016c4:	6b85                	lui	s7,0x1
    800016c6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    800016ca:	4605                	li	a2,1
    800016cc:	85ca                	mv	a1,s2
    800016ce:	8556                	mv	a0,s5
    800016d0:	00000097          	auipc	ra,0x0
    800016d4:	f16080e7          	jalr	-234(ra) # 800015e6 <walk>
    800016d8:	cd39                	beqz	a0,80001736 <mappages+0xa8>
    if(*pte & PTE_V) // 重复映射
    800016da:	611c                	ld	a5,0(a0)
    800016dc:	8b85                	and	a5,a5,1
    800016de:	e7a1                	bnez	a5,80001726 <mappages+0x98>
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    800016e0:	80b1                	srl	s1,s1,0xc
    800016e2:	04aa                	sll	s1,s1,0xa
    800016e4:	0164e4b3          	or	s1,s1,s6
    800016e8:	0014e493          	or	s1,s1,1
    800016ec:	e104                	sd	s1,0(a0)
    if(a == last)
    800016ee:	07390063          	beq	s2,s3,8000174e <mappages+0xc0>
    a += PGSIZE;
    800016f2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    800016f4:	bfc9                	j	800016c6 <mappages+0x38>
    panic("mappages: va not aligned");
    800016f6:	00008517          	auipc	a0,0x8
    800016fa:	b4250513          	add	a0,a0,-1214 # 80009238 <digits+0x48>
    800016fe:	00000097          	auipc	ra,0x0
    80001702:	b06080e7          	jalr	-1274(ra) # 80001204 <panic>
    panic("mappages: size not aligned");
    80001706:	00008517          	auipc	a0,0x8
    8000170a:	b5250513          	add	a0,a0,-1198 # 80009258 <digits+0x68>
    8000170e:	00000097          	auipc	ra,0x0
    80001712:	af6080e7          	jalr	-1290(ra) # 80001204 <panic>
    panic("mappages: size");
    80001716:	00008517          	auipc	a0,0x8
    8000171a:	b6250513          	add	a0,a0,-1182 # 80009278 <digits+0x88>
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	ae6080e7          	jalr	-1306(ra) # 80001204 <panic>
      panic("mappages: remap");
    80001726:	00008517          	auipc	a0,0x8
    8000172a:	b6250513          	add	a0,a0,-1182 # 80009288 <digits+0x98>
    8000172e:	00000097          	auipc	ra,0x0
    80001732:	ad6080e7          	jalr	-1322(ra) # 80001204 <panic>
      return -1;
    80001736:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6161                	add	sp,sp,80
    8000174c:	8082                	ret
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	b7e5                	j	80001738 <mappages+0xaa>

0000000080001752 <kvmmap>:
{
    80001752:	1141                	add	sp,sp,-16
    80001754:	e406                	sd	ra,8(sp)
    80001756:	e022                	sd	s0,0(sp)
    80001758:	0800                	add	s0,sp,16
    8000175a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000175c:	86b2                	mv	a3,a2
    8000175e:	863e                	mv	a2,a5
    80001760:	00000097          	auipc	ra,0x0
    80001764:	f2e080e7          	jalr	-210(ra) # 8000168e <mappages>
    80001768:	e509                	bnez	a0,80001772 <kvmmap+0x20>
}
    8000176a:	60a2                	ld	ra,8(sp)
    8000176c:	6402                	ld	s0,0(sp)
    8000176e:	0141                	add	sp,sp,16
    80001770:	8082                	ret
    panic("kvmmap");
    80001772:	00008517          	auipc	a0,0x8
    80001776:	b2650513          	add	a0,a0,-1242 # 80009298 <digits+0xa8>
    8000177a:	00000097          	auipc	ra,0x0
    8000177e:	a8a080e7          	jalr	-1398(ra) # 80001204 <panic>

0000000080001782 <kvmmake>:
{
    80001782:	1101                	add	sp,sp,-32
    80001784:	ec06                	sd	ra,24(sp)
    80001786:	e822                	sd	s0,16(sp)
    80001788:	e426                	sd	s1,8(sp)
    8000178a:	e04a                	sd	s2,0(sp)
    8000178c:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc(true);
    8000178e:	4505                	li	a0,1
    80001790:	00000097          	auipc	ra,0x0
    80001794:	dd0080e7          	jalr	-560(ra) # 80001560 <kalloc>
    80001798:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE); //关键清零
    8000179a:	6605                	lui	a2,0x1
    8000179c:	4581                	li	a1,0
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	81e080e7          	jalr	-2018(ra) # 80000fbc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800017a6:	4719                	li	a4,6
    800017a8:	6685                	lui	a3,0x1
    800017aa:	10000637          	lui	a2,0x10000
    800017ae:	100005b7          	lui	a1,0x10000
    800017b2:	8526                	mv	a0,s1
    800017b4:	00000097          	auipc	ra,0x0
    800017b8:	f9e080e7          	jalr	-98(ra) # 80001752 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800017bc:	4719                	li	a4,6
    800017be:	6685                	lui	a3,0x1
    800017c0:	10001637          	lui	a2,0x10001
    800017c4:	100015b7          	lui	a1,0x10001
    800017c8:	8526                	mv	a0,s1
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	f88080e7          	jalr	-120(ra) # 80001752 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800017d2:	4719                	li	a4,6
    800017d4:	004006b7          	lui	a3,0x400
    800017d8:	0c000637          	lui	a2,0xc000
    800017dc:	0c0005b7          	lui	a1,0xc000
    800017e0:	8526                	mv	a0,s1
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	f70080e7          	jalr	-144(ra) # 80001752 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800017ea:	00008917          	auipc	s2,0x8
    800017ee:	81690913          	add	s2,s2,-2026 # 80009000 <etext>
    800017f2:	4729                	li	a4,10
    800017f4:	80008697          	auipc	a3,0x80008
    800017f8:	80c68693          	add	a3,a3,-2036 # 9000 <_entry-0x7fff7000>
    800017fc:	4605                	li	a2,1
    800017fe:	067e                	sll	a2,a2,0x1f
    80001800:	85b2                	mv	a1,a2
    80001802:	8526                	mv	a0,s1
    80001804:	00000097          	auipc	ra,0x0
    80001808:	f4e080e7          	jalr	-178(ra) # 80001752 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    8000180c:	4719                	li	a4,6
    8000180e:	46c5                	li	a3,17
    80001810:	06ee                	sll	a3,a3,0x1b
    80001812:	412686b3          	sub	a3,a3,s2
    80001816:	864a                	mv	a2,s2
    80001818:	85ca                	mv	a1,s2
    8000181a:	8526                	mv	a0,s1
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	f36080e7          	jalr	-202(ra) # 80001752 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001824:	4729                	li	a4,10
    80001826:	6685                	lui	a3,0x1
    80001828:	00006617          	auipc	a2,0x6
    8000182c:	7d860613          	add	a2,a2,2008 # 80008000 <_trampoline>
    80001830:	040005b7          	lui	a1,0x4000
    80001834:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001836:	05b2                	sll	a1,a1,0xc
    80001838:	8526                	mv	a0,s1
    8000183a:	00000097          	auipc	ra,0x0
    8000183e:	f18080e7          	jalr	-232(ra) # 80001752 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001842:	8526                	mv	a0,s1
    80001844:	00001097          	auipc	ra,0x1
    80001848:	a24080e7          	jalr	-1500(ra) # 80002268 <proc_mapstacks>
}
    8000184c:	8526                	mv	a0,s1
    8000184e:	60e2                	ld	ra,24(sp)
    80001850:	6442                	ld	s0,16(sp)
    80001852:	64a2                	ld	s1,8(sp)
    80001854:	6902                	ld	s2,0(sp)
    80001856:	6105                	add	sp,sp,32
    80001858:	8082                	ret

000000008000185a <kvminit>:
{
    8000185a:	1141                	add	sp,sp,-16
    8000185c:	e406                	sd	ra,8(sp)
    8000185e:	e022                	sd	s0,0(sp)
    80001860:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    80001862:	00000097          	auipc	ra,0x0
    80001866:	f20080e7          	jalr	-224(ra) # 80001782 <kvmmake>
    8000186a:	00008797          	auipc	a5,0x8
    8000186e:	5aa7b323          	sd	a0,1446(a5) # 80009e10 <kernel_pagetable>
}
    80001872:	60a2                	ld	ra,8(sp)
    80001874:	6402                	ld	s0,0(sp)
    80001876:	0141                	add	sp,sp,16
    80001878:	8082                	ret

000000008000187a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    8000187a:	57fd                	li	a5,-1
    8000187c:	83e9                	srl	a5,a5,0x1a
    8000187e:	00b7f463          	bgeu	a5,a1,80001886 <walkaddr+0xc>
    return 0;
    80001882:	4501                	li	a0,0
  if (!is_user_accessible_page(*pte))
    return 0;

  pa = PTE2PA(*pte);
  return pa;
}
    80001884:	8082                	ret
{
    80001886:	1141                	add	sp,sp,-16
    80001888:	e406                	sd	ra,8(sp)
    8000188a:	e022                	sd	s0,0(sp)
    8000188c:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000188e:	4601                	li	a2,0
    80001890:	00000097          	auipc	ra,0x0
    80001894:	d56080e7          	jalr	-682(ra) # 800015e6 <walk>
  if (pte == 0)
    80001898:	cd19                	beqz	a0,800018b6 <walkaddr+0x3c>
  if (!is_user_accessible_page(*pte))
    8000189a:	611c                	ld	a5,0(a0)
  return (pte & PTE_V) && (pte & PTE_U);
    8000189c:	0117f693          	and	a3,a5,17
  if (!is_user_accessible_page(*pte))
    800018a0:	4745                	li	a4,17
    return 0;
    800018a2:	4501                	li	a0,0
  if (!is_user_accessible_page(*pte))
    800018a4:	00e69563          	bne	a3,a4,800018ae <walkaddr+0x34>
  pa = PTE2PA(*pte);
    800018a8:	83a9                	srl	a5,a5,0xa
    800018aa:	00c79513          	sll	a0,a5,0xc
}
    800018ae:	60a2                	ld	ra,8(sp)
    800018b0:	6402                	ld	s0,0(sp)
    800018b2:	0141                	add	sp,sp,16
    800018b4:	8082                	ret
    return 0;
    800018b6:	4501                	li	a0,0
    800018b8:	bfdd                	j	800018ae <walkaddr+0x34>

00000000800018ba <freewalk>:
#define PAGE_TABLE_ENTRIES 512

// 递归释放页表页面
// 所有叶子映射必须已经被移除
void freewalk(pagetable_t pagetable)
{
    800018ba:	7179                	add	sp,sp,-48
    800018bc:	f406                	sd	ra,40(sp)
    800018be:	f022                	sd	s0,32(sp)
    800018c0:	ec26                	sd	s1,24(sp)
    800018c2:	e84a                	sd	s2,16(sp)
    800018c4:	e44e                	sd	s3,8(sp)
    800018c6:	e052                	sd	s4,0(sp)
    800018c8:	1800                	add	s0,sp,48
    800018ca:	8a2a                	mv	s4,a0
  // 遍历页表中的所有PTE
  for (int i = 0; i < PAGE_TABLE_ENTRIES; i++)
    800018cc:	6905                	lui	s2,0x1
    800018ce:	992a                	add	s2,s2,a0
{
    800018d0:	84aa                	mv	s1,a0
    800018d2:	a821                	j	800018ea <freewalk+0x30>
      pagetable[i] = 0;
    }
    else if (is_pte_valid(pte))
    {
      // 发现叶子页面，应该已经被清理
      panic("freewalk: found unexpected leaf page");
    800018d4:	00008517          	auipc	a0,0x8
    800018d8:	9cc50513          	add	a0,a0,-1588 # 800092a0 <digits+0xb0>
    800018dc:	00000097          	auipc	ra,0x0
    800018e0:	928080e7          	jalr	-1752(ra) # 80001204 <panic>
  for (int i = 0; i < PAGE_TABLE_ENTRIES; i++)
    800018e4:	04a1                	add	s1,s1,8
    800018e6:	03248363          	beq	s1,s2,8000190c <freewalk+0x52>
    pte_t pte = pagetable[i];
    800018ea:	609c                	ld	a5,0(s1)
  return (pte & PTE_V) != 0;
    800018ec:	0017f713          	and	a4,a5,1
  return is_pte_valid(pte) && !is_pte_leaf(pte);
    800018f0:	db75                	beqz	a4,800018e4 <freewalk+0x2a>
  return (pte & (PTE_R | PTE_W | PTE_X)) != 0;
    800018f2:	00e7f713          	and	a4,a5,14
  return is_pte_valid(pte) && !is_pte_leaf(pte);
    800018f6:	ff79                	bnez	a4,800018d4 <freewalk+0x1a>
  return PTE2PA(pte);
    800018f8:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child_pa);
    800018fa:	00c79513          	sll	a0,a5,0xc
    800018fe:	00000097          	auipc	ra,0x0
    80001902:	fbc080e7          	jalr	-68(ra) # 800018ba <freewalk>
      pagetable[i] = 0;
    80001906:	0004b023          	sd	zero,0(s1)
    8000190a:	bfe9                	j	800018e4 <freewalk+0x2a>
    }
  }

  // 释放当前页表页面
  kfree((uint64)pagetable, true);
    8000190c:	4585                	li	a1,1
    8000190e:	8552                	mv	a0,s4
    80001910:	00000097          	auipc	ra,0x0
    80001914:	b50080e7          	jalr	-1200(ra) # 80001460 <kfree>
}
    80001918:	70a2                	ld	ra,40(sp)
    8000191a:	7402                	ld	s0,32(sp)
    8000191c:	64e2                	ld	s1,24(sp)
    8000191e:	6942                	ld	s2,16(sp)
    80001920:	69a2                	ld	s3,8(sp)
    80001922:	6a02                	ld	s4,0(sp)
    80001924:	6145                	add	sp,sp,48
    80001926:	8082                	ret

0000000080001928 <print_pgtbl>:

void print_pgtbl(pagetable_t pagetable, int level) {
    80001928:	711d                	add	sp,sp,-96
    8000192a:	ec86                	sd	ra,88(sp)
    8000192c:	e8a2                	sd	s0,80(sp)
    8000192e:	e4a6                	sd	s1,72(sp)
    80001930:	e0ca                	sd	s2,64(sp)
    80001932:	fc4e                	sd	s3,56(sp)
    80001934:	f852                	sd	s4,48(sp)
    80001936:	f456                	sd	s5,40(sp)
    80001938:	f05a                	sd	s6,32(sp)
    8000193a:	ec5e                	sd	s7,24(sp)
    8000193c:	e862                	sd	s8,16(sp)
    8000193e:	e466                	sd	s9,8(sp)
    80001940:	e06a                	sd	s10,0(sp)
    80001942:	1080                	add	s0,sp,96
    80001944:	8aae                	mv	s5,a1
  //递归打印页表
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001946:	8a2a                	mv	s4,a0
    80001948:	4981                	li	s3,0
    if(pte & PTE_V) {// 打印有效的页表项

      for(int j = 0; j < level; j++)
        printf("  ");

      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    8000194a:	00008c17          	auipc	s8,0x8
    8000194e:	986c0c13          	add	s8,s8,-1658 # 800092d0 <digits+0xe0>

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
    80001952:	00008d17          	auipc	s10,0x8
    80001956:	996d0d13          	add	s10,s10,-1642 # 800092e8 <digits+0xf8>
      for(int j = 0; j < level; j++)
    8000195a:	4c81                	li	s9,0
        printf("  ");
    8000195c:	00008b17          	auipc	s6,0x8
    80001960:	96cb0b13          	add	s6,s6,-1684 # 800092c8 <digits+0xd8>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001964:	20000b93          	li	s7,512
    80001968:	a025                	j	80001990 <print_pgtbl+0x68>
      } 
      else {
        printf("\n");
    8000196a:	00008517          	auipc	a0,0x8
    8000196e:	3ce50513          	add	a0,a0,974 # 80009d38 <syscalls+0x560>
    80001972:	00000097          	auipc	ra,0x0
    80001976:	8dc080e7          	jalr	-1828(ra) # 8000124e <printf>
        print_pgtbl((pagetable_t)PTE2PA(pte), level + 1);
    8000197a:	001a859b          	addw	a1,s5,1
    8000197e:	8526                	mv	a0,s1
    80001980:	00000097          	auipc	ra,0x0
    80001984:	fa8080e7          	jalr	-88(ra) # 80001928 <print_pgtbl>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001988:	2985                	addw	s3,s3,1 # 1001 <_entry-0x7fffefff>
    8000198a:	0a21                	add	s4,s4,8
    8000198c:	05798763          	beq	s3,s7,800019da <print_pgtbl+0xb2>
    pte_t pte = pagetable[i];
    80001990:	000a3903          	ld	s2,0(s4)
    if(pte & PTE_V) {// 打印有效的页表项
    80001994:	00197793          	and	a5,s2,1
    80001998:	dbe5                	beqz	a5,80001988 <print_pgtbl+0x60>
      for(int j = 0; j < level; j++)
    8000199a:	01505b63          	blez	s5,800019b0 <print_pgtbl+0x88>
    8000199e:	84e6                	mv	s1,s9
        printf("  ");
    800019a0:	855a                	mv	a0,s6
    800019a2:	00000097          	auipc	ra,0x0
    800019a6:	8ac080e7          	jalr	-1876(ra) # 8000124e <printf>
      for(int j = 0; j < level; j++)
    800019aa:	2485                	addw	s1,s1,1
    800019ac:	fe9a9ae3          	bne	s5,s1,800019a0 <print_pgtbl+0x78>
      printf("%d: pte %p pa %p", i, pte, PTE2PA(pte));
    800019b0:	00a95493          	srl	s1,s2,0xa
    800019b4:	04b2                	sll	s1,s1,0xc
    800019b6:	86a6                	mv	a3,s1
    800019b8:	864a                	mv	a2,s2
    800019ba:	85ce                	mv	a1,s3
    800019bc:	8562                	mv	a0,s8
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	890080e7          	jalr	-1904(ra) # 8000124e <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    800019c6:	00e97913          	and	s2,s2,14
    800019ca:	fa0900e3          	beqz	s2,8000196a <print_pgtbl+0x42>
        printf(" [leaf]\n");
    800019ce:	856a                	mv	a0,s10
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	87e080e7          	jalr	-1922(ra) # 8000124e <printf>
    800019d8:	bf45                	j	80001988 <print_pgtbl+0x60>
      }
    }
  }
}
    800019da:	60e6                	ld	ra,88(sp)
    800019dc:	6446                	ld	s0,80(sp)
    800019de:	64a6                	ld	s1,72(sp)
    800019e0:	6906                	ld	s2,64(sp)
    800019e2:	79e2                	ld	s3,56(sp)
    800019e4:	7a42                	ld	s4,48(sp)
    800019e6:	7aa2                	ld	s5,40(sp)
    800019e8:	7b02                	ld	s6,32(sp)
    800019ea:	6be2                	ld	s7,24(sp)
    800019ec:	6c42                	ld	s8,16(sp)
    800019ee:	6ca2                	ld	s9,8(sp)
    800019f0:	6d02                	ld	s10,0(sp)
    800019f2:	6125                	add	sp,sp,96
    800019f4:	8082                	ret

00000000800019f6 <print_cur_pgtbl>:

void print_cur_pgtbl(pagetable_t pagetable) {
    800019f6:	715d                	add	sp,sp,-80
    800019f8:	e486                	sd	ra,72(sp)
    800019fa:	e0a2                	sd	s0,64(sp)
    800019fc:	fc26                	sd	s1,56(sp)
    800019fe:	f84a                	sd	s2,48(sp)
    80001a00:	f44e                	sd	s3,40(sp)
    80001a02:	f052                	sd	s4,32(sp)
    80001a04:	ec56                	sd	s5,24(sp)
    80001a06:	e85a                	sd	s6,16(sp)
    80001a08:	e45e                	sd	s7,8(sp)
    80001a0a:	0880                	add	s0,sp,80
    80001a0c:	89aa                	mv	s3,a0
  //打印当前层页表
  printf("page table %p\n", pagetable);
    80001a0e:	85aa                	mv	a1,a0
    80001a10:	00008517          	auipc	a0,0x8
    80001a14:	8e850513          	add	a0,a0,-1816 # 800092f8 <digits+0x108>
    80001a18:	00000097          	auipc	ra,0x0
    80001a1c:	836080e7          	jalr	-1994(ra) # 8000124e <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001a20:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80001a22:	00008a97          	auipc	s5,0x8
    80001a26:	8e6a8a93          	add	s5,s5,-1818 # 80009308 <digits+0x118>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
    80001a2a:	00008b97          	auipc	s7,0x8
    80001a2e:	30eb8b93          	add	s7,s7,782 # 80009d38 <syscalls+0x560>
        printf(" [leaf]\n");
    80001a32:	00008b17          	auipc	s6,0x8
    80001a36:	8b6b0b13          	add	s6,s6,-1866 # 800092e8 <digits+0xf8>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001a3a:	20000a13          	li	s4,512
    80001a3e:	a811                	j	80001a52 <print_cur_pgtbl+0x5c>
        printf("\n");
    80001a40:	855e                	mv	a0,s7
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	80c080e7          	jalr	-2036(ra) # 8000124e <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80001a4a:	2905                	addw	s2,s2,1 # 1001 <_entry-0x7fffefff>
    80001a4c:	09a1                	add	s3,s3,8
    80001a4e:	03490963          	beq	s2,s4,80001a80 <print_cur_pgtbl+0x8a>
    pte_t pte = pagetable[i];
    80001a52:	0009b483          	ld	s1,0(s3)
    if(pte & PTE_V) {// 打印有效的页表项
    80001a56:	0014f793          	and	a5,s1,1
    80001a5a:	dbe5                	beqz	a5,80001a4a <print_cur_pgtbl+0x54>
      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80001a5c:	00a4d693          	srl	a3,s1,0xa
    80001a60:	06b2                	sll	a3,a3,0xc
    80001a62:	8626                	mv	a2,s1
    80001a64:	85ca                	mv	a1,s2
    80001a66:	8556                	mv	a0,s5
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	7e6080e7          	jalr	2022(ra) # 8000124e <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80001a70:	88b9                	and	s1,s1,14
    80001a72:	d4f9                	beqz	s1,80001a40 <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80001a74:	855a                	mv	a0,s6
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	7d8080e7          	jalr	2008(ra) # 8000124e <printf>
    80001a7e:	b7f1                	j	80001a4a <print_cur_pgtbl+0x54>
      }
    }
  }
    80001a80:	60a6                	ld	ra,72(sp)
    80001a82:	6406                	ld	s0,64(sp)
    80001a84:	74e2                	ld	s1,56(sp)
    80001a86:	7942                	ld	s2,48(sp)
    80001a88:	79a2                	ld	s3,40(sp)
    80001a8a:	7a02                	ld	s4,32(sp)
    80001a8c:	6ae2                	ld	s5,24(sp)
    80001a8e:	6b42                	ld	s6,16(sp)
    80001a90:	6ba2                	ld	s7,8(sp)
    80001a92:	6161                	add	sp,sp,80
    80001a94:	8082                	ret

0000000080001a96 <uvmcreate>:


// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
    80001a96:	1101                	add	sp,sp,-32
    80001a98:	ec06                	sd	ra,24(sp)
    80001a9a:	e822                	sd	s0,16(sp)
    80001a9c:	e426                	sd	s1,8(sp)
    80001a9e:	1000                	add	s0,sp,32
  pagetable_t pagetable = (pagetable_t)kalloc(true);
    80001aa0:	4505                	li	a0,1
    80001aa2:	00000097          	auipc	ra,0x0
    80001aa6:	abe080e7          	jalr	-1346(ra) # 80001560 <kalloc>
    80001aaa:	84aa                	mv	s1,a0
  if(pagetable)
    80001aac:	c519                	beqz	a0,80001aba <uvmcreate+0x24>
    memset(pagetable, 0, PGSIZE);
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	4581                	li	a1,0
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	50a080e7          	jalr	1290(ra) # 80000fbc <memset>
  return pagetable;
}
    80001aba:	8526                	mv	a0,s1
    80001abc:	60e2                	ld	ra,24(sp)
    80001abe:	6442                	ld	s0,16(sp)
    80001ac0:	64a2                	ld	s1,8(sp)
    80001ac2:	6105                	add	sp,sp,32
    80001ac4:	8082                	ret

0000000080001ac6 <uvmfirst>:

void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001ac6:	7179                	add	sp,sp,-48
    80001ac8:	f406                	sd	ra,40(sp)
    80001aca:	f022                	sd	s0,32(sp)
    80001acc:	ec26                	sd	s1,24(sp)
    80001ace:	e84a                	sd	s2,16(sp)
    80001ad0:	e44e                	sd	s3,8(sp)
    80001ad2:	e052                	sd	s4,0(sp)
    80001ad4:	1800                	add	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001ad6:	6785                	lui	a5,0x1
    80001ad8:	04f67963          	bgeu	a2,a5,80001b2a <uvmfirst+0x64>
    80001adc:	8a2a                	mv	s4,a0
    80001ade:	89ae                	mv	s3,a1
    80001ae0:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc(1);
    80001ae2:	4505                	li	a0,1
    80001ae4:	00000097          	auipc	ra,0x0
    80001ae8:	a7c080e7          	jalr	-1412(ra) # 80001560 <kalloc>
    80001aec:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001aee:	6605                	lui	a2,0x1
    80001af0:	4581                	li	a1,0
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	4ca080e7          	jalr	1226(ra) # 80000fbc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001afa:	4779                	li	a4,30
    80001afc:	86ca                	mv	a3,s2
    80001afe:	6605                	lui	a2,0x1
    80001b00:	4581                	li	a1,0
    80001b02:	8552                	mv	a0,s4
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	b8a080e7          	jalr	-1142(ra) # 8000168e <mappages>
  memmove(mem, src, sz);
    80001b0c:	8626                	mv	a2,s1
    80001b0e:	85ce                	mv	a1,s3
    80001b10:	854a                	mv	a0,s2
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	506080e7          	jalr	1286(ra) # 80001018 <memmove>
}
    80001b1a:	70a2                	ld	ra,40(sp)
    80001b1c:	7402                	ld	s0,32(sp)
    80001b1e:	64e2                	ld	s1,24(sp)
    80001b20:	6942                	ld	s2,16(sp)
    80001b22:	69a2                	ld	s3,8(sp)
    80001b24:	6a02                	ld	s4,0(sp)
    80001b26:	6145                	add	sp,sp,48
    80001b28:	8082                	ret
    panic("uvmfirst: more than a page");
    80001b2a:	00007517          	auipc	a0,0x7
    80001b2e:	7fe50513          	add	a0,a0,2046 # 80009328 <digits+0x138>
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	6d2080e7          	jalr	1746(ra) # 80001204 <panic>

0000000080001b3a <uvmunmap>:

// 从va开始移除npages个映射。va必须是
// 页面对齐的。映射必须存在。
// 可选择释放物理内存
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001b3a:	715d                	add	sp,sp,-80
    80001b3c:	e486                	sd	ra,72(sp)
    80001b3e:	e0a2                	sd	s0,64(sp)
    80001b40:	fc26                	sd	s1,56(sp)
    80001b42:	f84a                	sd	s2,48(sp)
    80001b44:	f44e                	sd	s3,40(sp)
    80001b46:	f052                	sd	s4,32(sp)
    80001b48:	ec56                	sd	s5,24(sp)
    80001b4a:	e85a                	sd	s6,16(sp)
    80001b4c:	e45e                	sd	s7,8(sp)
    80001b4e:	0880                	add	s0,sp,80
  return (addr % PGSIZE) == 0;
    80001b50:	03459793          	sll	a5,a1,0x34
  uint64 current_va;
  pte_t *pte;

  if (!is_page_aligned(va))
    80001b54:	e795                	bnez	a5,80001b80 <uvmunmap+0x46>
    80001b56:	8a2a                	mv	s4,a0
    80001b58:	892e                	mv	s2,a1
    80001b5a:	8ab6                	mv	s5,a3
    panic("uvmunmap: address not page aligned");

  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    80001b5c:	0632                	sll	a2,a2,0xc
    80001b5e:	00b609b3          	add	s3,a2,a1
  if (PTE_FLAGS(pte) == PTE_V)
    80001b62:	4b05                	li	s6,1
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    80001b64:	6b85                	lui	s7,0x1
    80001b66:	0735e263          	bltu	a1,s3,80001bca <uvmunmap+0x90>
      free_physical_page_from_pte(*pte);
    }

    clear_pte(pte);
  }
}
    80001b6a:	60a6                	ld	ra,72(sp)
    80001b6c:	6406                	ld	s0,64(sp)
    80001b6e:	74e2                	ld	s1,56(sp)
    80001b70:	7942                	ld	s2,48(sp)
    80001b72:	79a2                	ld	s3,40(sp)
    80001b74:	7a02                	ld	s4,32(sp)
    80001b76:	6ae2                	ld	s5,24(sp)
    80001b78:	6b42                	ld	s6,16(sp)
    80001b7a:	6ba2                	ld	s7,8(sp)
    80001b7c:	6161                	add	sp,sp,80
    80001b7e:	8082                	ret
    panic("uvmunmap: address not page aligned");
    80001b80:	00007517          	auipc	a0,0x7
    80001b84:	7c850513          	add	a0,a0,1992 # 80009348 <digits+0x158>
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	67c080e7          	jalr	1660(ra) # 80001204 <panic>
      panic("uvmunmap: walk failed");
    80001b90:	00007517          	auipc	a0,0x7
    80001b94:	7e050513          	add	a0,a0,2016 # 80009370 <digits+0x180>
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	66c080e7          	jalr	1644(ra) # 80001204 <panic>
    panic("uvmunmap: page not mapped");
    80001ba0:	00007517          	auipc	a0,0x7
    80001ba4:	7e850513          	add	a0,a0,2024 # 80009388 <digits+0x198>
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	65c080e7          	jalr	1628(ra) # 80001204 <panic>
    panic("uvmunmap: not a leaf page");
    80001bb0:	00007517          	auipc	a0,0x7
    80001bb4:	7f850513          	add	a0,a0,2040 # 800093a8 <digits+0x1b8>
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	64c080e7          	jalr	1612(ra) # 80001204 <panic>
  *pte = 0;
    80001bc0:	0004b023          	sd	zero,0(s1)
  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
    80001bc4:	995e                	add	s2,s2,s7
    80001bc6:	fb3972e3          	bgeu	s2,s3,80001b6a <uvmunmap+0x30>
    pte = walk(pagetable, current_va, 0);
    80001bca:	4601                	li	a2,0
    80001bcc:	85ca                	mv	a1,s2
    80001bce:	8552                	mv	a0,s4
    80001bd0:	00000097          	auipc	ra,0x0
    80001bd4:	a16080e7          	jalr	-1514(ra) # 800015e6 <walk>
    80001bd8:	84aa                	mv	s1,a0
    if (pte == 0)
    80001bda:	d95d                	beqz	a0,80001b90 <uvmunmap+0x56>
    validate_page_mapping(*pte);
    80001bdc:	611c                	ld	a5,0(a0)
  return (pte & PTE_V) != 0;
    80001bde:	0017f713          	and	a4,a5,1
  if (!is_pte_valid(pte))
    80001be2:	df5d                	beqz	a4,80001ba0 <uvmunmap+0x66>
  if (PTE_FLAGS(pte) == PTE_V)
    80001be4:	3ff7f713          	and	a4,a5,1023
    80001be8:	fd6704e3          	beq	a4,s6,80001bb0 <uvmunmap+0x76>
    if (do_free)
    80001bec:	fc0a8ae3          	beqz	s5,80001bc0 <uvmunmap+0x86>
  uint64 pa = PTE2PA(pte);
    80001bf0:	83a9                	srl	a5,a5,0xa
  kfree(pa,0);
    80001bf2:	4581                	li	a1,0
    80001bf4:	00c79513          	sll	a0,a5,0xc
    80001bf8:	00000097          	auipc	ra,0x0
    80001bfc:	868080e7          	jalr	-1944(ra) # 80001460 <kfree>
}
    80001c00:	b7c1                	j	80001bc0 <uvmunmap+0x86>

0000000080001c02 <uvmdealloc>:
{
    80001c02:	1101                	add	sp,sp,-32
    80001c04:	ec06                	sd	ra,24(sp)
    80001c06:	e822                	sd	s0,16(sp)
    80001c08:	e426                	sd	s1,8(sp)
    80001c0a:	1000                	add	s0,sp,32
    return oldsz;
    80001c0c:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    80001c0e:	00b67d63          	bgeu	a2,a1,80001c28 <uvmdealloc+0x26>
    80001c12:	84b2                	mv	s1,a2
  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001c14:	6785                	lui	a5,0x1
    80001c16:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001c18:	00f60733          	add	a4,a2,a5
    80001c1c:	76fd                	lui	a3,0xfffff
    80001c1e:	8f75                	and	a4,a4,a3
    80001c20:	97ae                	add	a5,a5,a1
    80001c22:	8ff5                	and	a5,a5,a3
    80001c24:	00f76863          	bltu	a4,a5,80001c34 <uvmdealloc+0x32>
}
    80001c28:	8526                	mv	a0,s1
    80001c2a:	60e2                	ld	ra,24(sp)
    80001c2c:	6442                	ld	s0,16(sp)
    80001c2e:	64a2                	ld	s1,8(sp)
    80001c30:	6105                	add	sp,sp,32
    80001c32:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001c34:	8f99                	sub	a5,a5,a4
    80001c36:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001c38:	4685                	li	a3,1
    80001c3a:	0007861b          	sext.w	a2,a5
    80001c3e:	85ba                	mv	a1,a4
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	efa080e7          	jalr	-262(ra) # 80001b3a <uvmunmap>
    80001c48:	b7c5                	j	80001c28 <uvmdealloc+0x26>

0000000080001c4a <uvmalloc>:
  if (newsz < oldsz)
    80001c4a:	0ab66763          	bltu	a2,a1,80001cf8 <uvmalloc+0xae>
{
    80001c4e:	7139                	add	sp,sp,-64
    80001c50:	fc06                	sd	ra,56(sp)
    80001c52:	f822                	sd	s0,48(sp)
    80001c54:	f426                	sd	s1,40(sp)
    80001c56:	f04a                	sd	s2,32(sp)
    80001c58:	ec4e                	sd	s3,24(sp)
    80001c5a:	e852                	sd	s4,16(sp)
    80001c5c:	e456                	sd	s5,8(sp)
    80001c5e:	e05a                	sd	s6,0(sp)
    80001c60:	0080                	add	s0,sp,64
    80001c62:	8aaa                	mv	s5,a0
    80001c64:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001c66:	6785                	lui	a5,0x1
    80001c68:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001c6a:	95be                	add	a1,a1,a5
    80001c6c:	77fd                	lui	a5,0xfffff
    80001c6e:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001c72:	08c9f563          	bgeu	s3,a2,80001cfc <uvmalloc+0xb2>
    80001c76:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001c78:	0126eb13          	or	s6,a3,18
    mem = kalloc(0);
    80001c7c:	4501                	li	a0,0
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	8e2080e7          	jalr	-1822(ra) # 80001560 <kalloc>
    80001c86:	84aa                	mv	s1,a0
    if (mem == 0)
    80001c88:	c51d                	beqz	a0,80001cb6 <uvmalloc+0x6c>
    memset(mem, 0, PGSIZE);
    80001c8a:	6605                	lui	a2,0x1
    80001c8c:	4581                	li	a1,0
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	32e080e7          	jalr	814(ra) # 80000fbc <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001c96:	875a                	mv	a4,s6
    80001c98:	86a6                	mv	a3,s1
    80001c9a:	6605                	lui	a2,0x1
    80001c9c:	85ca                	mv	a1,s2
    80001c9e:	8556                	mv	a0,s5
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	9ee080e7          	jalr	-1554(ra) # 8000168e <mappages>
    80001ca8:	e90d                	bnez	a0,80001cda <uvmalloc+0x90>
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001caa:	6785                	lui	a5,0x1
    80001cac:	993e                	add	s2,s2,a5
    80001cae:	fd4967e3          	bltu	s2,s4,80001c7c <uvmalloc+0x32>
  return newsz;
    80001cb2:	8552                	mv	a0,s4
    80001cb4:	a809                	j	80001cc6 <uvmalloc+0x7c>
      uvmdealloc(pagetable, a, oldsz);
    80001cb6:	864e                	mv	a2,s3
    80001cb8:	85ca                	mv	a1,s2
    80001cba:	8556                	mv	a0,s5
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	f46080e7          	jalr	-186(ra) # 80001c02 <uvmdealloc>
      return 0;
    80001cc4:	4501                	li	a0,0
}
    80001cc6:	70e2                	ld	ra,56(sp)
    80001cc8:	7442                	ld	s0,48(sp)
    80001cca:	74a2                	ld	s1,40(sp)
    80001ccc:	7902                	ld	s2,32(sp)
    80001cce:	69e2                	ld	s3,24(sp)
    80001cd0:	6a42                	ld	s4,16(sp)
    80001cd2:	6aa2                	ld	s5,8(sp)
    80001cd4:	6b02                	ld	s6,0(sp)
    80001cd6:	6121                	add	sp,sp,64
    80001cd8:	8082                	ret
      kfree((uint64)mem,0);
    80001cda:	4581                	li	a1,0
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	782080e7          	jalr	1922(ra) # 80001460 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001ce6:	864e                	mv	a2,s3
    80001ce8:	85ca                	mv	a1,s2
    80001cea:	8556                	mv	a0,s5
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	f16080e7          	jalr	-234(ra) # 80001c02 <uvmdealloc>
      return 0;
    80001cf4:	4501                	li	a0,0
    80001cf6:	bfc1                	j	80001cc6 <uvmalloc+0x7c>
    return oldsz;
    80001cf8:	852e                	mv	a0,a1
}
    80001cfa:	8082                	ret
  return newsz;
    80001cfc:	8532                	mv	a0,a2
    80001cfe:	b7e1                	j	80001cc6 <uvmalloc+0x7c>

0000000080001d00 <uvm_copyin>:
// 成功返回0，失败返回-1
int uvm_copyin(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001d00:	cebd                	beqz	a3,80001d7e <uvm_copyin+0x7e>
{
    80001d02:	711d                	add	sp,sp,-96
    80001d04:	ec86                	sd	ra,88(sp)
    80001d06:	e8a2                	sd	s0,80(sp)
    80001d08:	e4a6                	sd	s1,72(sp)
    80001d0a:	e0ca                	sd	s2,64(sp)
    80001d0c:	fc4e                	sd	s3,56(sp)
    80001d0e:	f852                	sd	s4,48(sp)
    80001d10:	f456                	sd	s5,40(sp)
    80001d12:	f05a                	sd	s6,32(sp)
    80001d14:	ec5e                	sd	s7,24(sp)
    80001d16:	e862                	sd	s8,16(sp)
    80001d18:	e466                	sd	s9,8(sp)
    80001d1a:	e06a                	sd	s10,0(sp)
    80001d1c:	1080                	add	s0,sp,96
    80001d1e:	8b2a                	mv	s6,a0
    80001d20:	89ae                	mv	s3,a1
    80001d22:	84b2                	mv	s1,a2
    80001d24:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(srcva);
    80001d26:	7bfd                	lui	s7,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001d28:	6a85                	lui	s5,0x1
    80001d2a:	fffa8c13          	add	s8,s5,-1 # fff <_entry-0x7ffff001>
    80001d2e:	a015                	j	80001d52 <uvm_copyin+0x52>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove((void *)dst, (void *)(page_pa + src_offset), bytes_to_copy);
    80001d30:	000c8d1b          	sext.w	s10,s9
    80001d34:	866a                	mv	a2,s10
    80001d36:	009505b3          	add	a1,a0,s1
    80001d3a:	854e                	mv	a0,s3
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	2dc080e7          	jalr	732(ra) # 80001018 <memmove>

    len -= bytes_to_copy;
    80001d44:	41a9093b          	subw	s2,s2,s10
    dst += bytes_to_copy;
    80001d48:	99e6                	add	s3,s3,s9
    srcva = page_va + PGSIZE; // 移到下一页
    80001d4a:	015a04b3          	add	s1,s4,s5
  while (len > 0)
    80001d4e:	02090663          	beqz	s2,80001d7a <uvm_copyin+0x7a>
    page_va = PGROUNDDOWN(srcva);
    80001d52:	0174fa33          	and	s4,s1,s7
    page_pa = walkaddr(pgtbl, page_va);
    80001d56:	85d2                	mv	a1,s4
    80001d58:	855a                	mv	a0,s6
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	b20080e7          	jalr	-1248(ra) # 8000187a <walkaddr>
    if (page_pa == 0)
    80001d62:	c105                	beqz	a0,80001d82 <uvm_copyin+0x82>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001d64:	0184f4b3          	and	s1,s1,s8
    bytes_to_copy = bytes_to_copy_in_page(srcva, len);
    80001d68:	02091793          	sll	a5,s2,0x20
    80001d6c:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001d6e:	409a8cb3          	sub	s9,s5,s1
    80001d72:	fb97ffe3          	bgeu	a5,s9,80001d30 <uvm_copyin+0x30>
    80001d76:	8cbe                	mv	s9,a5
    80001d78:	bf65                	j	80001d30 <uvm_copyin+0x30>
  }
  return 0;
    80001d7a:	4501                	li	a0,0
    80001d7c:	a021                	j	80001d84 <uvm_copyin+0x84>
    80001d7e:	4501                	li	a0,0
}
    80001d80:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001d82:	557d                	li	a0,-1
}
    80001d84:	60e6                	ld	ra,88(sp)
    80001d86:	6446                	ld	s0,80(sp)
    80001d88:	64a6                	ld	s1,72(sp)
    80001d8a:	6906                	ld	s2,64(sp)
    80001d8c:	79e2                	ld	s3,56(sp)
    80001d8e:	7a42                	ld	s4,48(sp)
    80001d90:	7aa2                	ld	s5,40(sp)
    80001d92:	7b02                	ld	s6,32(sp)
    80001d94:	6be2                	ld	s7,24(sp)
    80001d96:	6c42                	ld	s8,16(sp)
    80001d98:	6ca2                	ld	s9,8(sp)
    80001d9a:	6d02                	ld	s10,0(sp)
    80001d9c:	6125                	add	sp,sp,96
    80001d9e:	8082                	ret

0000000080001da0 <uvm_copyout>:
// 成功返回0，失败返回-1
int uvm_copyout(pgtbl_t pgtbl, uint64 dstva, uint64 src, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001da0:	ceb5                	beqz	a3,80001e1c <uvm_copyout+0x7c>
{
    80001da2:	711d                	add	sp,sp,-96
    80001da4:	ec86                	sd	ra,88(sp)
    80001da6:	e8a2                	sd	s0,80(sp)
    80001da8:	e4a6                	sd	s1,72(sp)
    80001daa:	e0ca                	sd	s2,64(sp)
    80001dac:	fc4e                	sd	s3,56(sp)
    80001dae:	f852                	sd	s4,48(sp)
    80001db0:	f456                	sd	s5,40(sp)
    80001db2:	f05a                	sd	s6,32(sp)
    80001db4:	ec5e                	sd	s7,24(sp)
    80001db6:	e862                	sd	s8,16(sp)
    80001db8:	e466                	sd	s9,8(sp)
    80001dba:	e06a                	sd	s10,0(sp)
    80001dbc:	1080                	add	s0,sp,96
    80001dbe:	8baa                	mv	s7,a0
    80001dc0:	84ae                	mv	s1,a1
    80001dc2:	89b2                	mv	s3,a2
    80001dc4:	8936                	mv	s2,a3
  {
    page_va = PGROUNDDOWN(dstva);
    80001dc6:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001dc8:	6b05                	lui	s6,0x1
    80001dca:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    80001dce:	a00d                	j	80001df0 <uvm_copyout+0x50>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), (void *)src, bytes_to_copy);
    80001dd0:	000d0a9b          	sext.w	s5,s10
    80001dd4:	8656                	mv	a2,s5
    80001dd6:	85ce                	mv	a1,s3
    80001dd8:	9526                	add	a0,a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	23e080e7          	jalr	574(ra) # 80001018 <memmove>

    len -= bytes_to_copy;
    80001de2:	4159093b          	subw	s2,s2,s5
    src += bytes_to_copy;
    80001de6:	99ea                	add	s3,s3,s10
    dstva = page_va + PGSIZE; // 移到下一页
    80001de8:	016a04b3          	add	s1,s4,s6
  while (len > 0)
    80001dec:	02090663          	beqz	s2,80001e18 <uvm_copyout+0x78>
    page_va = PGROUNDDOWN(dstva);
    80001df0:	0184fa33          	and	s4,s1,s8
    page_pa = walkaddr(pgtbl, page_va);
    80001df4:	85d2                	mv	a1,s4
    80001df6:	855e                	mv	a0,s7
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	a82080e7          	jalr	-1406(ra) # 8000187a <walkaddr>
    if (page_pa == 0)
    80001e00:	c105                	beqz	a0,80001e20 <uvm_copyout+0x80>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001e02:	0194f4b3          	and	s1,s1,s9
    bytes_to_copy = bytes_to_copy_in_page(dstva, len);
    80001e06:	02091793          	sll	a5,s2,0x20
    80001e0a:	9381                	srl	a5,a5,0x20
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001e0c:	409b0d33          	sub	s10,s6,s1
    80001e10:	fda7f0e3          	bgeu	a5,s10,80001dd0 <uvm_copyout+0x30>
    80001e14:	8d3e                	mv	s10,a5
    80001e16:	bf6d                	j	80001dd0 <uvm_copyout+0x30>
  }
  return 0;
    80001e18:	4501                	li	a0,0
    80001e1a:	a021                	j	80001e22 <uvm_copyout+0x82>
    80001e1c:	4501                	li	a0,0
}
    80001e1e:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001e20:	557d                	li	a0,-1
}
    80001e22:	60e6                	ld	ra,88(sp)
    80001e24:	6446                	ld	s0,80(sp)
    80001e26:	64a6                	ld	s1,72(sp)
    80001e28:	6906                	ld	s2,64(sp)
    80001e2a:	79e2                	ld	s3,56(sp)
    80001e2c:	7a42                	ld	s4,48(sp)
    80001e2e:	7aa2                	ld	s5,40(sp)
    80001e30:	7b02                	ld	s6,32(sp)
    80001e32:	6be2                	ld	s7,24(sp)
    80001e34:	6c42                	ld	s8,16(sp)
    80001e36:	6ca2                	ld	s9,8(sp)
    80001e38:	6d02                	ld	s10,0(sp)
    80001e3a:	6125                	add	sp,sp,96
    80001e3c:	8082                	ret

0000000080001e3e <uvm_copyin_str>:
int uvm_copyin_str(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 maxlen)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && maxlen > 0)
    80001e3e:	c6dd                	beqz	a3,80001eec <uvm_copyin_str+0xae>
{
    80001e40:	715d                	add	sp,sp,-80
    80001e42:	e486                	sd	ra,72(sp)
    80001e44:	e0a2                	sd	s0,64(sp)
    80001e46:	fc26                	sd	s1,56(sp)
    80001e48:	f84a                	sd	s2,48(sp)
    80001e4a:	f44e                	sd	s3,40(sp)
    80001e4c:	f052                	sd	s4,32(sp)
    80001e4e:	ec56                	sd	s5,24(sp)
    80001e50:	e85a                	sd	s6,16(sp)
    80001e52:	e45e                	sd	s7,8(sp)
    80001e54:	0880                	add	s0,sp,80
    80001e56:	8aaa                	mv	s5,a0
    80001e58:	89ae                	mv	s3,a1
    80001e5a:	8bb2                	mv	s7,a2
    80001e5c:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001e5e:	7b7d                	lui	s6,0xfffff
    pa0 = walkaddr(pgtbl, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001e60:	6a05                	lui	s4,0x1
    80001e62:	a02d                	j	80001e8c <uvm_copyin_str+0x4e>
        *(char*)dst = *p;
      }
      --n;
      --maxlen;
      p++;
      dst++;
    80001e64:	87ba                	mv	a5,a4
      if (*p == '\0')
    80001e66:	00f60733          	add	a4,a2,a5
    80001e6a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdbd48>
    80001e6e:	cb31                	beqz	a4,80001ec2 <uvm_copyin_str+0x84>
        *(char*)dst = *p;
    80001e70:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      dst++;
    80001e74:	00178713          	add	a4,a5,1
    while (n > 0)
    80001e78:	fee696e3          	bne	a3,a4,80001e64 <uvm_copyin_str+0x26>
    80001e7c:	34fd                	addw	s1,s1,-1
    80001e7e:	013484bb          	addw	s1,s1,s3
      --maxlen;
    80001e82:	9c9d                	subw	s1,s1,a5
      dst++;
    80001e84:	89ba                	mv	s3,a4
    }

    srcva = va0 + PGSIZE;
    80001e86:	01490bb3          	add	s7,s2,s4
  while (got_null == 0 && maxlen > 0)
    80001e8a:	cca9                	beqz	s1,80001ee4 <uvm_copyin_str+0xa6>
    va0 = PGROUNDDOWN(srcva);
    80001e8c:	016bf933          	and	s2,s7,s6
    pa0 = walkaddr(pgtbl, va0);
    80001e90:	85ca                	mv	a1,s2
    80001e92:	8556                	mv	a0,s5
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	9e6080e7          	jalr	-1562(ra) # 8000187a <walkaddr>
    if (pa0 == 0)
    80001e9c:	c531                	beqz	a0,80001ee8 <uvm_copyin_str+0xaa>
    n = PGSIZE - (srcva - va0);
    80001e9e:	417906b3          	sub	a3,s2,s7
    if (n > maxlen)
    80001ea2:	02049793          	sll	a5,s1,0x20
    80001ea6:	9381                	srl	a5,a5,0x20
    80001ea8:	96d2                	add	a3,a3,s4
    80001eaa:	00d7f363          	bgeu	a5,a3,80001eb0 <uvm_copyin_str+0x72>
    80001eae:	86be                	mv	a3,a5
    char *p = (char *)(pa0 + (srcva - va0));
    80001eb0:	955e                	add	a0,a0,s7
    80001eb2:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001eb6:	dae1                	beqz	a3,80001e86 <uvm_copyin_str+0x48>
    80001eb8:	87ce                	mv	a5,s3
      if (*p == '\0')
    80001eba:	41350633          	sub	a2,a0,s3
    while (n > 0)
    80001ebe:	96ce                	add	a3,a3,s3
    80001ec0:	b75d                	j	80001e66 <uvm_copyin_str+0x28>
        *(char*)dst = '\0';
    80001ec2:	00078023          	sb	zero,0(a5)
    80001ec6:	4785                	li	a5,1
  }
  if (got_null)
    80001ec8:	37fd                	addw	a5,a5,-1
    80001eca:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001ece:	60a6                	ld	ra,72(sp)
    80001ed0:	6406                	ld	s0,64(sp)
    80001ed2:	74e2                	ld	s1,56(sp)
    80001ed4:	7942                	ld	s2,48(sp)
    80001ed6:	79a2                	ld	s3,40(sp)
    80001ed8:	7a02                	ld	s4,32(sp)
    80001eda:	6ae2                	ld	s5,24(sp)
    80001edc:	6b42                	ld	s6,16(sp)
    80001ede:	6ba2                	ld	s7,8(sp)
    80001ee0:	6161                	add	sp,sp,80
    80001ee2:	8082                	ret
    80001ee4:	4781                	li	a5,0
    80001ee6:	b7cd                	j	80001ec8 <uvm_copyin_str+0x8a>
      return -1;
    80001ee8:	557d                	li	a0,-1
    80001eea:	b7d5                	j	80001ece <uvm_copyin_str+0x90>
  int got_null = 0;
    80001eec:	4781                	li	a5,0
  if (got_null)
    80001eee:	37fd                	addw	a5,a5,-1
    80001ef0:	0007851b          	sext.w	a0,a5
}
    80001ef4:	8082                	ret

0000000080001ef6 <uvmfree>:
  return PGROUNDUP(size) / PGSIZE;
}

// 释放用户内存页面，然后释放页表页面
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001ef6:	1101                	add	sp,sp,-32
    80001ef8:	ec06                	sd	ra,24(sp)
    80001efa:	e822                	sd	s0,16(sp)
    80001efc:	e426                	sd	s1,8(sp)
    80001efe:	1000                	add	s0,sp,32
    80001f00:	84aa                	mv	s1,a0
  if (sz > 0)
    80001f02:	e999                	bnez	a1,80001f18 <uvmfree+0x22>
  {
    uint64 npages = calculate_pages_needed(sz);
    uvmunmap(pagetable, 0, npages, 1);
  }
  freewalk(pagetable);
    80001f04:	8526                	mv	a0,s1
    80001f06:	00000097          	auipc	ra,0x0
    80001f0a:	9b4080e7          	jalr	-1612(ra) # 800018ba <freewalk>
}
    80001f0e:	60e2                	ld	ra,24(sp)
    80001f10:	6442                	ld	s0,16(sp)
    80001f12:	64a2                	ld	s1,8(sp)
    80001f14:	6105                	add	sp,sp,32
    80001f16:	8082                	ret
  return PGROUNDUP(size) / PGSIZE;
    80001f18:	6785                	lui	a5,0x1
    80001f1a:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001f1c:	95be                	add	a1,a1,a5
    uvmunmap(pagetable, 0, npages, 1);
    80001f1e:	4685                	li	a3,1
    80001f20:	00c5d613          	srl	a2,a1,0xc
    80001f24:	4581                	li	a1,0
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	c14080e7          	jalr	-1004(ra) # 80001b3a <uvmunmap>
    80001f2e:	bfd9                	j	80001f04 <uvmfree+0xe>

0000000080001f30 <copyout>:
// 成功返回0，错误返回-1
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001f30:	caad                	beqz	a3,80001fa2 <copyout+0x72>
{
    80001f32:	711d                	add	sp,sp,-96
    80001f34:	ec86                	sd	ra,88(sp)
    80001f36:	e8a2                	sd	s0,80(sp)
    80001f38:	e4a6                	sd	s1,72(sp)
    80001f3a:	e0ca                	sd	s2,64(sp)
    80001f3c:	fc4e                	sd	s3,56(sp)
    80001f3e:	f852                	sd	s4,48(sp)
    80001f40:	f456                	sd	s5,40(sp)
    80001f42:	f05a                	sd	s6,32(sp)
    80001f44:	ec5e                	sd	s7,24(sp)
    80001f46:	e862                	sd	s8,16(sp)
    80001f48:	e466                	sd	s9,8(sp)
    80001f4a:	1080                	add	s0,sp,96
    80001f4c:	8baa                	mv	s7,a0
    80001f4e:	84ae                	mv	s1,a1
    80001f50:	8a32                	mv	s4,a2
    80001f52:	89b6                	mv	s3,a3
  {
    page_va = PGROUNDDOWN(dstva);
    80001f54:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001f56:	6b05                	lui	s6,0x1
    80001f58:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    80001f5c:	a005                	j	80001f7c <copyout+0x4c>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), src, bytes_to_copy);
    80001f5e:	0009061b          	sext.w	a2,s2
    80001f62:	85d2                	mv	a1,s4
    80001f64:	9526                	add	a0,a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	0b2080e7          	jalr	178(ra) # 80001018 <memmove>

    len -= bytes_to_copy;
    80001f6e:	412989b3          	sub	s3,s3,s2
    src += bytes_to_copy;
    80001f72:	9a4a                	add	s4,s4,s2
    dstva = page_va + PGSIZE; // 移到下一页
    80001f74:	016a84b3          	add	s1,s5,s6
  while (len > 0)
    80001f78:	02098363          	beqz	s3,80001f9e <copyout+0x6e>
    page_va = PGROUNDDOWN(dstva);
    80001f7c:	0184fab3          	and	s5,s1,s8
    page_pa = walkaddr(pagetable, page_va);
    80001f80:	85d6                	mv	a1,s5
    80001f82:	855e                	mv	a0,s7
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	8f6080e7          	jalr	-1802(ra) # 8000187a <walkaddr>
    if (page_pa == 0)
    80001f8c:	cd09                	beqz	a0,80001fa6 <copyout+0x76>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001f8e:	0194f4b3          	and	s1,s1,s9
  uint64 bytes_in_page = PGSIZE - page_offset;
    80001f92:	409b0933          	sub	s2,s6,s1
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    80001f96:	fd29f4e3          	bgeu	s3,s2,80001f5e <copyout+0x2e>
    80001f9a:	894e                	mv	s2,s3
    80001f9c:	b7c9                	j	80001f5e <copyout+0x2e>
  }
  return 0;
    80001f9e:	4501                	li	a0,0
    80001fa0:	a021                	j	80001fa8 <copyout+0x78>
    80001fa2:	4501                	li	a0,0
}
    80001fa4:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    80001fa6:	557d                	li	a0,-1
}
    80001fa8:	60e6                	ld	ra,88(sp)
    80001faa:	6446                	ld	s0,80(sp)
    80001fac:	64a6                	ld	s1,72(sp)
    80001fae:	6906                	ld	s2,64(sp)
    80001fb0:	79e2                	ld	s3,56(sp)
    80001fb2:	7a42                	ld	s4,48(sp)
    80001fb4:	7aa2                	ld	s5,40(sp)
    80001fb6:	7b02                	ld	s6,32(sp)
    80001fb8:	6be2                	ld	s7,24(sp)
    80001fba:	6c42                	ld	s8,16(sp)
    80001fbc:	6ca2                	ld	s9,8(sp)
    80001fbe:	6125                	add	sp,sp,96
    80001fc0:	8082                	ret

0000000080001fc2 <copyin>:
// 成功返回0，错误返回-1
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
    80001fc2:	cab5                	beqz	a3,80002036 <copyin+0x74>
{
    80001fc4:	711d                	add	sp,sp,-96
    80001fc6:	ec86                	sd	ra,88(sp)
    80001fc8:	e8a2                	sd	s0,80(sp)
    80001fca:	e4a6                	sd	s1,72(sp)
    80001fcc:	e0ca                	sd	s2,64(sp)
    80001fce:	fc4e                	sd	s3,56(sp)
    80001fd0:	f852                	sd	s4,48(sp)
    80001fd2:	f456                	sd	s5,40(sp)
    80001fd4:	f05a                	sd	s6,32(sp)
    80001fd6:	ec5e                	sd	s7,24(sp)
    80001fd8:	e862                	sd	s8,16(sp)
    80001fda:	e466                	sd	s9,8(sp)
    80001fdc:	1080                	add	s0,sp,96
    80001fde:	8baa                	mv	s7,a0
    80001fe0:	8a2e                	mv	s4,a1
    80001fe2:	84b2                	mv	s1,a2
    80001fe4:	89b6                	mv	s3,a3
  {
    page_va = PGROUNDDOWN(srcva);
    80001fe6:	7c7d                	lui	s8,0xfffff
  uint64 page_offset = va - PGROUNDDOWN(va);
    80001fe8:	6b05                	lui	s6,0x1
    80001fea:	fffb0c93          	add	s9,s6,-1 # fff <_entry-0x7ffff001>
    80001fee:	a00d                	j	80002010 <copyin+0x4e>
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove(dst, (void *)(page_pa + src_offset), bytes_to_copy);
    80001ff0:	0009061b          	sext.w	a2,s2
    80001ff4:	009505b3          	add	a1,a0,s1
    80001ff8:	8552                	mv	a0,s4
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	01e080e7          	jalr	30(ra) # 80001018 <memmove>

    len -= bytes_to_copy;
    80002002:	412989b3          	sub	s3,s3,s2
    dst += bytes_to_copy;
    80002006:	9a4a                	add	s4,s4,s2
    srcva = page_va + PGSIZE; // 移到下一页
    80002008:	016a84b3          	add	s1,s5,s6
  while (len > 0)
    8000200c:	02098363          	beqz	s3,80002032 <copyin+0x70>
    page_va = PGROUNDDOWN(srcva);
    80002010:	0184fab3          	and	s5,s1,s8
    page_pa = walkaddr(pagetable, page_va);
    80002014:	85d6                	mv	a1,s5
    80002016:	855e                	mv	a0,s7
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	862080e7          	jalr	-1950(ra) # 8000187a <walkaddr>
    if (page_pa == 0)
    80002020:	cd09                	beqz	a0,8000203a <copyin+0x78>
  uint64 page_offset = va - PGROUNDDOWN(va);
    80002022:	0194f4b3          	and	s1,s1,s9
  uint64 bytes_in_page = PGSIZE - page_offset;
    80002026:	409b0933          	sub	s2,s6,s1
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
    8000202a:	fd29f3e3          	bgeu	s3,s2,80001ff0 <copyin+0x2e>
    8000202e:	894e                	mv	s2,s3
    80002030:	b7c1                	j	80001ff0 <copyin+0x2e>
  }
  return 0;
    80002032:	4501                	li	a0,0
    80002034:	a021                	j	8000203c <copyin+0x7a>
    80002036:	4501                	li	a0,0
}
    80002038:	8082                	ret
      return -1; // 页面映射不存在或不可访问
    8000203a:	557d                	li	a0,-1
}
    8000203c:	60e6                	ld	ra,88(sp)
    8000203e:	6446                	ld	s0,80(sp)
    80002040:	64a6                	ld	s1,72(sp)
    80002042:	6906                	ld	s2,64(sp)
    80002044:	79e2                	ld	s3,56(sp)
    80002046:	7a42                	ld	s4,48(sp)
    80002048:	7aa2                	ld	s5,40(sp)
    8000204a:	7b02                	ld	s6,32(sp)
    8000204c:	6be2                	ld	s7,24(sp)
    8000204e:	6c42                	ld	s8,16(sp)
    80002050:	6ca2                	ld	s9,8(sp)
    80002052:	6125                	add	sp,sp,96
    80002054:	8082                	ret

0000000080002056 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80002056:	c2dd                	beqz	a3,800020fc <copyinstr+0xa6>
{
    80002058:	715d                	add	sp,sp,-80
    8000205a:	e486                	sd	ra,72(sp)
    8000205c:	e0a2                	sd	s0,64(sp)
    8000205e:	fc26                	sd	s1,56(sp)
    80002060:	f84a                	sd	s2,48(sp)
    80002062:	f44e                	sd	s3,40(sp)
    80002064:	f052                	sd	s4,32(sp)
    80002066:	ec56                	sd	s5,24(sp)
    80002068:	e85a                	sd	s6,16(sp)
    8000206a:	e45e                	sd	s7,8(sp)
    8000206c:	0880                	add	s0,sp,80
    8000206e:	8a2a                	mv	s4,a0
    80002070:	8b2e                	mv	s6,a1
    80002072:	8bb2                	mv	s7,a2
    80002074:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80002076:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80002078:	6985                	lui	s3,0x1
    8000207a:	a02d                	j	800020a4 <copyinstr+0x4e>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    8000207c:	00078023          	sb	zero,0(a5)
    80002080:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80002082:	37fd                	addw	a5,a5,-1
    80002084:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    80002088:	60a6                	ld	ra,72(sp)
    8000208a:	6406                	ld	s0,64(sp)
    8000208c:	74e2                	ld	s1,56(sp)
    8000208e:	7942                	ld	s2,48(sp)
    80002090:	79a2                	ld	s3,40(sp)
    80002092:	7a02                	ld	s4,32(sp)
    80002094:	6ae2                	ld	s5,24(sp)
    80002096:	6b42                	ld	s6,16(sp)
    80002098:	6ba2                	ld	s7,8(sp)
    8000209a:	6161                	add	sp,sp,80
    8000209c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000209e:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    800020a2:	c8a9                	beqz	s1,800020f4 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800020a4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800020a8:	85ca                	mv	a1,s2
    800020aa:	8552                	mv	a0,s4
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	7ce080e7          	jalr	1998(ra) # 8000187a <walkaddr>
    if (pa0 == 0)
    800020b4:	c131                	beqz	a0,800020f8 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800020b6:	417906b3          	sub	a3,s2,s7
    800020ba:	96ce                	add	a3,a3,s3
    800020bc:	00d4f363          	bgeu	s1,a3,800020c2 <copyinstr+0x6c>
    800020c0:	86a6                	mv	a3,s1
    char *p = (char *)(pa0 + (srcva - va0));
    800020c2:	955e                	add	a0,a0,s7
    800020c4:	41250533          	sub	a0,a0,s2
    while (n > 0)
    800020c8:	daf9                	beqz	a3,8000209e <copyinstr+0x48>
    800020ca:	87da                	mv	a5,s6
    800020cc:	885a                	mv	a6,s6
      if (*p == '\0')
    800020ce:	41650633          	sub	a2,a0,s6
    while (n > 0)
    800020d2:	96da                	add	a3,a3,s6
    800020d4:	85be                	mv	a1,a5
      if (*p == '\0')
    800020d6:	00f60733          	add	a4,a2,a5
    800020da:	00074703          	lbu	a4,0(a4)
    800020de:	df59                	beqz	a4,8000207c <copyinstr+0x26>
        *dst = *p;
    800020e0:	00e78023          	sb	a4,0(a5)
      dst++;
    800020e4:	0785                	add	a5,a5,1
    while (n > 0)
    800020e6:	fed797e3          	bne	a5,a3,800020d4 <copyinstr+0x7e>
    800020ea:	14fd                	add	s1,s1,-1
    800020ec:	94c2                	add	s1,s1,a6
      --max;
    800020ee:	8c8d                	sub	s1,s1,a1
      dst++;
    800020f0:	8b3e                	mv	s6,a5
    800020f2:	b775                	j	8000209e <copyinstr+0x48>
    800020f4:	4781                	li	a5,0
    800020f6:	b771                	j	80002082 <copyinstr+0x2c>
      return -1;
    800020f8:	557d                	li	a0,-1
    800020fa:	b779                	j	80002088 <copyinstr+0x32>
  int got_null = 0;
    800020fc:	4781                	li	a5,0
  if (got_null)
    800020fe:	37fd                	addw	a5,a5,-1
    80002100:	0007851b          	sext.w	a0,a5
}
    80002104:	8082                	ret

0000000080002106 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80002106:	1141                	add	sp,sp,-16
    80002108:	e406                	sd	ra,8(sp)
    8000210a:	e022                	sd	s0,0(sp)
    8000210c:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000210e:	4601                	li	a2,0
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	4d6080e7          	jalr	1238(ra) # 800015e6 <walk>
  if(pte == 0)
    80002118:	c901                	beqz	a0,80002128 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000211a:	611c                	ld	a5,0(a0)
    8000211c:	9bbd                	and	a5,a5,-17
    8000211e:	e11c                	sd	a5,0(a0)
    80002120:	60a2                	ld	ra,8(sp)
    80002122:	6402                	ld	s0,0(sp)
    80002124:	0141                	add	sp,sp,16
    80002126:	8082                	ret
    panic("uvmclear");
    80002128:	00007517          	auipc	a0,0x7
    8000212c:	2a050513          	add	a0,a0,672 # 800093c8 <digits+0x1d8>
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	0d4080e7          	jalr	212(ra) # 80001204 <panic>

0000000080002138 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80002138:	1141                	add	sp,sp,-16
    8000213a:	e422                	sd	s0,8(sp)
    8000213c:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000213e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80002140:	2501                	sext.w	a0,a0
    80002142:	6422                	ld	s0,8(sp)
    80002144:	0141                	add	sp,sp,16
    80002146:	8082                	ret

0000000080002148 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80002148:	1141                	add	sp,sp,-16
    8000214a:	e422                	sd	s0,8(sp)
    8000214c:	0800                	add	s0,sp,16
    8000214e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80002150:	2781                	sext.w	a5,a5
    80002152:	079e                	sll	a5,a5,0x7
  return c;
}
    80002154:	00010517          	auipc	a0,0x10
    80002158:	0ac50513          	add	a0,a0,172 # 80012200 <cpus>
    8000215c:	953e                	add	a0,a0,a5
    8000215e:	6422                	ld	s0,8(sp)
    80002160:	0141                	add	sp,sp,16
    80002162:	8082                	ret

0000000080002164 <myproc>:


proc_t* myproc(void)
{
    80002164:	1101                	add	sp,sp,-32
    80002166:	ec06                	sd	ra,24(sp)
    80002168:	e822                	sd	s0,16(sp)
    8000216a:	e426                	sd	s1,8(sp)
    8000216c:	1000                	add	s0,sp,32
  push_off();
    8000216e:	00001097          	auipc	ra,0x1
    80002172:	eb4080e7          	jalr	-332(ra) # 80003022 <push_off>
    80002176:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002178:	2781                	sext.w	a5,a5
    8000217a:	079e                	sll	a5,a5,0x7
    8000217c:	00010717          	auipc	a4,0x10
    80002180:	08470713          	add	a4,a4,132 # 80012200 <cpus>
    80002184:	97ba                	add	a5,a5,a4
    80002186:	6784                	ld	s1,8(a5)
  pop_off();
    80002188:	00001097          	auipc	ra,0x1
    8000218c:	f3a080e7          	jalr	-198(ra) # 800030c2 <pop_off>
  return p;
}
    80002190:	8526                	mv	a0,s1
    80002192:	60e2                	ld	ra,24(sp)
    80002194:	6442                	ld	s0,16(sp)
    80002196:	64a2                	ld	s1,8(sp)
    80002198:	6105                	add	sp,sp,32
    8000219a:	8082                	ret

000000008000219c <allocpid>:

int
allocpid()
{
    8000219c:	1101                	add	sp,sp,-32
    8000219e:	ec06                	sd	ra,24(sp)
    800021a0:	e822                	sd	s0,16(sp)
    800021a2:	e426                	sd	s1,8(sp)
    800021a4:	e04a                	sd	s2,0(sp)
    800021a6:	1000                	add	s0,sp,32
  int pid;
  
  acquire(&pid_lock);
    800021a8:	00010917          	auipc	s2,0x10
    800021ac:	45890913          	add	s2,s2,1112 # 80012600 <pid_lock>
    800021b0:	854a                	mv	a0,s2
    800021b2:	00001097          	auipc	ra,0x1
    800021b6:	ebc080e7          	jalr	-324(ra) # 8000306e <acquire>
  pid = nextpid;
    800021ba:	00008797          	auipc	a5,0x8
    800021be:	c0678793          	add	a5,a5,-1018 # 80009dc0 <nextpid>
    800021c2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800021c4:	0014871b          	addw	a4,s1,1
    800021c8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800021ca:	854a                	mv	a0,s2
    800021cc:	00001097          	auipc	ra,0x1
    800021d0:	f56080e7          	jalr	-170(ra) # 80003122 <release>

  return pid;
    800021d4:	8526                	mv	a0,s1
    800021d6:	60e2                	ld	ra,24(sp)
    800021d8:	6442                	ld	s0,16(sp)
    800021da:	64a2                	ld	s1,8(sp)
    800021dc:	6902                	ld	s2,0(sp)
    800021de:	6105                	add	sp,sp,32
    800021e0:	8082                	ret

00000000800021e2 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800021e2:	1101                	add	sp,sp,-32
    800021e4:	ec06                	sd	ra,24(sp)
    800021e6:	e822                	sd	s0,16(sp)
    800021e8:	e426                	sd	s1,8(sp)
    800021ea:	1000                	add	s0,sp,32
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	f78080e7          	jalr	-136(ra) # 80002164 <myproc>
    800021f4:	0521                	add	a0,a0,8
    800021f6:	00001097          	auipc	ra,0x1
    800021fa:	f2c080e7          	jalr	-212(ra) # 80003122 <release>

  if (first) {
    800021fe:	00008797          	auipc	a5,0x8
    80002202:	bc67a783          	lw	a5,-1082(a5) # 80009dc4 <first.0>
    80002206:	eb91                	bnez	a5,8000221a <forkret+0x38>
    dir_print(root);
    iunlockput(root);
    // printf("proc %d: first user process init done\n", myproc()->pid);
  }

  trap_user_return();
    80002208:	00001097          	auipc	ra,0x1
    8000220c:	2bc080e7          	jalr	700(ra) # 800034c4 <trap_user_return>
}
    80002210:	60e2                	ld	ra,24(sp)
    80002212:	6442                	ld	s0,16(sp)
    80002214:	64a2                	ld	s1,8(sp)
    80002216:	6105                	add	sp,sp,32
    80002218:	8082                	ret
    first = 0;
    8000221a:	00008797          	auipc	a5,0x8
    8000221e:	ba07a523          	sw	zero,-1110(a5) # 80009dc4 <first.0>
    fsinit(ROOTDEV); //初始化文件系统
    80002222:	4505                	li	a0,1
    80002224:	00005097          	auipc	ra,0x5
    80002228:	ce0080e7          	jalr	-800(ra) # 80006f04 <fsinit>
    struct inode *root = iget(ROOTDEV, ROOTINO);
    8000222c:	4585                	li	a1,1
    8000222e:	4505                	li	a0,1
    80002230:	00003097          	auipc	ra,0x3
    80002234:	c5c080e7          	jalr	-932(ra) # 80004e8c <iget>
    80002238:	84aa                	mv	s1,a0
    ilock(root);
    8000223a:	00003097          	auipc	ra,0x3
    8000223e:	ea6080e7          	jalr	-346(ra) # 800050e0 <ilock>
    printf("\n=== debug: root directory entries ===\n");
    80002242:	00007517          	auipc	a0,0x7
    80002246:	19650513          	add	a0,a0,406 # 800093d8 <digits+0x1e8>
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	004080e7          	jalr	4(ra) # 8000124e <printf>
    dir_print(root);
    80002252:	8526                	mv	a0,s1
    80002254:	00004097          	auipc	ra,0x4
    80002258:	584080e7          	jalr	1412(ra) # 800067d8 <dir_print>
    iunlockput(root);
    8000225c:	8526                	mv	a0,s1
    8000225e:	00003097          	auipc	ra,0x3
    80002262:	0e4080e7          	jalr	228(ra) # 80005342 <iunlockput>
    80002266:	b74d                	j	80002208 <forkret+0x26>

0000000080002268 <proc_mapstacks>:
{
    80002268:	7139                	add	sp,sp,-64
    8000226a:	fc06                	sd	ra,56(sp)
    8000226c:	f822                	sd	s0,48(sp)
    8000226e:	f426                	sd	s1,40(sp)
    80002270:	f04a                	sd	s2,32(sp)
    80002272:	ec4e                	sd	s3,24(sp)
    80002274:	e852                	sd	s4,16(sp)
    80002276:	e456                	sd	s5,8(sp)
    80002278:	e05a                	sd	s6,0(sp)
    8000227a:	0080                	add	s0,sp,64
    8000227c:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000227e:	00010497          	auipc	s1,0x10
    80002282:	39a48493          	add	s1,s1,922 # 80012618 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80002286:	8b26                	mv	s6,s1
    80002288:	00007a97          	auipc	s5,0x7
    8000228c:	d78a8a93          	add	s5,s5,-648 # 80009000 <etext>
    80002290:	04000937          	lui	s2,0x4000
    80002294:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80002296:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002298:	00016a17          	auipc	s4,0x16
    8000229c:	d80a0a13          	add	s4,s4,-640 # 80018018 <wait_lock>
    char *pa = kalloc(1);
    800022a0:	4505                	li	a0,1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	2be080e7          	jalr	702(ra) # 80001560 <kalloc>
    800022aa:	862a                	mv	a2,a0
    if(pa == 0)
    800022ac:	c131                	beqz	a0,800022f0 <proc_mapstacks+0x88>
    uint64 va = KSTACK((int) (p - proc));
    800022ae:	416485b3          	sub	a1,s1,s6
    800022b2:	858d                	sra	a1,a1,0x3
    800022b4:	000ab783          	ld	a5,0(s5)
    800022b8:	02f585b3          	mul	a1,a1,a5
    800022bc:	2585                	addw	a1,a1,1
    800022be:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800022c2:	4719                	li	a4,6
    800022c4:	6685                	lui	a3,0x1
    800022c6:	40b905b3          	sub	a1,s2,a1
    800022ca:	854e                	mv	a0,s3
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	486080e7          	jalr	1158(ra) # 80001752 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022d4:	16848493          	add	s1,s1,360
    800022d8:	fd4494e3          	bne	s1,s4,800022a0 <proc_mapstacks+0x38>
}
    800022dc:	70e2                	ld	ra,56(sp)
    800022de:	7442                	ld	s0,48(sp)
    800022e0:	74a2                	ld	s1,40(sp)
    800022e2:	7902                	ld	s2,32(sp)
    800022e4:	69e2                	ld	s3,24(sp)
    800022e6:	6a42                	ld	s4,16(sp)
    800022e8:	6aa2                	ld	s5,8(sp)
    800022ea:	6b02                	ld	s6,0(sp)
    800022ec:	6121                	add	sp,sp,64
    800022ee:	8082                	ret
      panic("kalloc");
    800022f0:	00007517          	auipc	a0,0x7
    800022f4:	11050513          	add	a0,a0,272 # 80009400 <digits+0x210>
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	f0c080e7          	jalr	-244(ra) # 80001204 <panic>

0000000080002300 <procinit>:
{
    80002300:	7139                	add	sp,sp,-64
    80002302:	fc06                	sd	ra,56(sp)
    80002304:	f822                	sd	s0,48(sp)
    80002306:	f426                	sd	s1,40(sp)
    80002308:	f04a                	sd	s2,32(sp)
    8000230a:	ec4e                	sd	s3,24(sp)
    8000230c:	e852                	sd	s4,16(sp)
    8000230e:	e456                	sd	s5,8(sp)
    80002310:	e05a                	sd	s6,0(sp)
    80002312:	0080                	add	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80002314:	00007597          	auipc	a1,0x7
    80002318:	0f458593          	add	a1,a1,244 # 80009408 <digits+0x218>
    8000231c:	00010517          	auipc	a0,0x10
    80002320:	2e450513          	add	a0,a0,740 # 80012600 <pid_lock>
    80002324:	00001097          	auipc	ra,0x1
    80002328:	cba080e7          	jalr	-838(ra) # 80002fde <initlock>
    initlock(&wait_lock, "wait_lock");
    8000232c:	00007597          	auipc	a1,0x7
    80002330:	0e458593          	add	a1,a1,228 # 80009410 <digits+0x220>
    80002334:	00016517          	auipc	a0,0x16
    80002338:	ce450513          	add	a0,a0,-796 # 80018018 <wait_lock>
    8000233c:	00001097          	auipc	ra,0x1
    80002340:	ca2080e7          	jalr	-862(ra) # 80002fde <initlock>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002344:	00010497          	auipc	s1,0x10
    80002348:	2d448493          	add	s1,s1,724 # 80012618 <proc>
      initlock(&p->lock, "proc");
    8000234c:	00007b17          	auipc	s6,0x7
    80002350:	0d4b0b13          	add	s6,s6,212 # 80009420 <digits+0x230>
      p->kstack = KSTACK((int) (p - proc));
    80002354:	8aa6                	mv	s5,s1
    80002356:	00007a17          	auipc	s4,0x7
    8000235a:	caaa0a13          	add	s4,s4,-854 # 80009000 <etext>
    8000235e:	04000937          	lui	s2,0x4000
    80002362:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80002364:	0932                	sll	s2,s2,0xc
    for(p = proc; p < &proc[NPROC]; p++) {
    80002366:	00016997          	auipc	s3,0x16
    8000236a:	cb298993          	add	s3,s3,-846 # 80018018 <wait_lock>
      initlock(&p->lock, "proc");
    8000236e:	85da                	mv	a1,s6
    80002370:	00848513          	add	a0,s1,8
    80002374:	00001097          	auipc	ra,0x1
    80002378:	c6a080e7          	jalr	-918(ra) # 80002fde <initlock>
      p->state = UNUSED;
    8000237c:	0204a023          	sw	zero,32(s1)
      p->kstack = KSTACK((int) (p - proc));
    80002380:	415487b3          	sub	a5,s1,s5
    80002384:	878d                	sra	a5,a5,0x3
    80002386:	000a3703          	ld	a4,0(s4)
    8000238a:	02e787b3          	mul	a5,a5,a4
    8000238e:	2785                	addw	a5,a5,1
    80002390:	00d7979b          	sllw	a5,a5,0xd
    80002394:	40f907b3          	sub	a5,s2,a5
    80002398:	f8fc                	sd	a5,240(s1)
    for(p = proc; p < &proc[NPROC]; p++) {
    8000239a:	16848493          	add	s1,s1,360
    8000239e:	fd3498e3          	bne	s1,s3,8000236e <procinit+0x6e>
}
    800023a2:	70e2                	ld	ra,56(sp)
    800023a4:	7442                	ld	s0,48(sp)
    800023a6:	74a2                	ld	s1,40(sp)
    800023a8:	7902                	ld	s2,32(sp)
    800023aa:	69e2                	ld	s3,24(sp)
    800023ac:	6a42                	ld	s4,16(sp)
    800023ae:	6aa2                	ld	s5,8(sp)
    800023b0:	6b02                	ld	s6,0(sp)
    800023b2:	6121                	add	sp,sp,64
    800023b4:	8082                	ret

00000000800023b6 <proc_freepagetable>:

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    800023b6:	1101                	add	sp,sp,-32
    800023b8:	ec06                	sd	ra,24(sp)
    800023ba:	e822                	sd	s0,16(sp)
    800023bc:	e426                	sd	s1,8(sp)
    800023be:	e04a                	sd	s2,0(sp)
    800023c0:	1000                	add	s0,sp,32
    800023c2:	84aa                	mv	s1,a0
    800023c4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0); 
    800023c6:	4681                	li	a3,0
    800023c8:	4605                	li	a2,1
    800023ca:	040005b7          	lui	a1,0x4000
    800023ce:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800023d0:	05b2                	sll	a1,a1,0xc
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	768080e7          	jalr	1896(ra) # 80001b3a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800023da:	4681                	li	a3,0
    800023dc:	4605                	li	a2,1
    800023de:	020005b7          	lui	a1,0x2000
    800023e2:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800023e4:	05b6                	sll	a1,a1,0xd
    800023e6:	8526                	mv	a0,s1
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	752080e7          	jalr	1874(ra) # 80001b3a <uvmunmap>
  uvmfree(pagetable, sz);
    800023f0:	85ca                	mv	a1,s2
    800023f2:	8526                	mv	a0,s1
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	b02080e7          	jalr	-1278(ra) # 80001ef6 <uvmfree>
}
    800023fc:	60e2                	ld	ra,24(sp)
    800023fe:	6442                	ld	s0,16(sp)
    80002400:	64a2                	ld	s1,8(sp)
    80002402:	6902                	ld	s2,0(sp)
    80002404:	6105                	add	sp,sp,32
    80002406:	8082                	ret

0000000080002408 <freeproc>:

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
void freeproc(struct proc *p)
{
    80002408:	1101                	add	sp,sp,-32
    8000240a:	ec06                	sd	ra,24(sp)
    8000240c:	e822                	sd	s0,16(sp)
    8000240e:	e426                	sd	s1,8(sp)
    80002410:	1000                	add	s0,sp,32
    80002412:	84aa                	mv	s1,a0
  if(p->tf)
    80002414:	6d28                	ld	a0,88(a0)
    80002416:	c511                	beqz	a0,80002422 <freeproc+0x1a>
    kfree((uint64)p->tf,1);
    80002418:	4585                	li	a1,1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	046080e7          	jalr	70(ra) # 80001460 <kfree>
  p->tf = 0;
    80002422:	0404bc23          	sd	zero,88(s1)
  if(p->pgtbl)
    80002426:	64a8                	ld	a0,72(s1)
    80002428:	c511                	beqz	a0,80002434 <freeproc+0x2c>
    proc_freepagetable(p->pgtbl, p->sz);
    8000242a:	74ec                	ld	a1,232(s1)
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	f8a080e7          	jalr	-118(ra) # 800023b6 <proc_freepagetable>

  p->pgtbl = 0;
    80002434:	0404b423          	sd	zero,72(s1)
  p->parent = 0;
    80002438:	0204b423          	sd	zero,40(s1)
  p->chan = 0;
    8000243c:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80002440:	0204ac23          	sw	zero,56(s1)
  p->exit_state = 0;
    80002444:	0204ae23          	sw	zero,60(s1)
  p->sleep_space = 0;
    80002448:	0404b023          	sd	zero,64(s1)
  p->ustack_pages = 0;
    8000244c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002450:	0e04b423          	sd	zero,232(s1)
  p->pid = 0;
    80002454:	0004a023          	sw	zero,0(s1)
  
  memset(&p->ctx, 0, sizeof(p->ctx));
    80002458:	07000613          	li	a2,112
    8000245c:	4581                	li	a1,0
    8000245e:	0f848513          	add	a0,s1,248
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	b5a080e7          	jalr	-1190(ra) # 80000fbc <memset>

  p->state = UNUSED;
    8000246a:	0204a023          	sw	zero,32(s1)
}
    8000246e:	60e2                	ld	ra,24(sp)
    80002470:	6442                	ld	s0,16(sp)
    80002472:	64a2                	ld	s1,8(sp)
    80002474:	6105                	add	sp,sp,32
    80002476:	8082                	ret

0000000080002478 <proc_pgtbl_init>:

// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
    80002478:	1101                	add	sp,sp,-32
    8000247a:	ec06                	sd	ra,24(sp)
    8000247c:	e822                	sd	s0,16(sp)
    8000247e:	e426                	sd	s1,8(sp)
    80002480:	e04a                	sd	s2,0(sp)
    80002482:	1000                	add	s0,sp,32
    80002484:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	610080e7          	jalr	1552(ra) # 80001a96 <uvmcreate>
    8000248e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002490:	cd1d                	beqz	a0,800024ce <proc_pgtbl_init+0x56>
    return 0;

  
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002492:	4729                	li	a4,10
    80002494:	00006697          	auipc	a3,0x6
    80002498:	b6c68693          	add	a3,a3,-1172 # 80008000 <_trampoline>
    8000249c:	6605                	lui	a2,0x1
    8000249e:	040005b7          	lui	a1,0x4000
    800024a2:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800024a4:	05b2                	sll	a1,a1,0xc
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	1e8080e7          	jalr	488(ra) # 8000168e <mappages>
    800024ae:	02054763          	bltz	a0,800024dc <proc_pgtbl_init+0x64>
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800024b2:	4719                	li	a4,6
    800024b4:	86ca                	mv	a3,s2
    800024b6:	6605                	lui	a2,0x1
    800024b8:	020005b7          	lui	a1,0x2000
    800024bc:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800024be:	05b6                	sll	a1,a1,0xd
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	1cc080e7          	jalr	460(ra) # 8000168e <mappages>
    800024ca:	02054163          	bltz	a0,800024ec <proc_pgtbl_init+0x74>
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}
    800024ce:	8526                	mv	a0,s1
    800024d0:	60e2                	ld	ra,24(sp)
    800024d2:	6442                	ld	s0,16(sp)
    800024d4:	64a2                	ld	s1,8(sp)
    800024d6:	6902                	ld	s2,0(sp)
    800024d8:	6105                	add	sp,sp,32
    800024da:	8082                	ret
    panic("proc_pgtbl_init: mappages trampoline failed");
    800024dc:	00007517          	auipc	a0,0x7
    800024e0:	f4c50513          	add	a0,a0,-180 # 80009428 <digits+0x238>
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	d20080e7          	jalr	-736(ra) # 80001204 <panic>
    panic("proc_pgtbl_init: mappages trapframe failed");
    800024ec:	00007517          	auipc	a0,0x7
    800024f0:	f6c50513          	add	a0,a0,-148 # 80009458 <digits+0x268>
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	d10080e7          	jalr	-752(ra) # 80001204 <panic>

00000000800024fc <allocproc>:
{
    800024fc:	7179                	add	sp,sp,-48
    800024fe:	f406                	sd	ra,40(sp)
    80002500:	f022                	sd	s0,32(sp)
    80002502:	ec26                	sd	s1,24(sp)
    80002504:	e84a                	sd	s2,16(sp)
    80002506:	e44e                	sd	s3,8(sp)
    80002508:	1800                	add	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    8000250a:	00010497          	auipc	s1,0x10
    8000250e:	10e48493          	add	s1,s1,270 # 80012618 <proc>
    80002512:	00016997          	auipc	s3,0x16
    80002516:	b0698993          	add	s3,s3,-1274 # 80018018 <wait_lock>
    acquire(&p->lock);
    8000251a:	00848913          	add	s2,s1,8
    8000251e:	854a                	mv	a0,s2
    80002520:	00001097          	auipc	ra,0x1
    80002524:	b4e080e7          	jalr	-1202(ra) # 8000306e <acquire>
    if(p->state == UNUSED) {
    80002528:	509c                	lw	a5,32(s1)
    8000252a:	cf81                	beqz	a5,80002542 <allocproc+0x46>
      release(&p->lock);
    8000252c:	854a                	mv	a0,s2
    8000252e:	00001097          	auipc	ra,0x1
    80002532:	bf4080e7          	jalr	-1036(ra) # 80003122 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002536:	16848493          	add	s1,s1,360
    8000253a:	ff3490e3          	bne	s1,s3,8000251a <allocproc+0x1e>
  return 0;
    8000253e:	4481                	li	s1,0
    80002540:	a8a1                	j	80002598 <allocproc+0x9c>
  p->pid = allocpid();
    80002542:	00000097          	auipc	ra,0x0
    80002546:	c5a080e7          	jalr	-934(ra) # 8000219c <allocpid>
    8000254a:	c088                	sw	a0,0(s1)
  p->state = USED;
    8000254c:	4785                	li	a5,1
    8000254e:	d09c                	sw	a5,32(s1)
  p->sz=4096;
    80002550:	6785                	lui	a5,0x1
    80002552:	f4fc                	sd	a5,232(s1)
  if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    80002554:	4505                	li	a0,1
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	00a080e7          	jalr	10(ra) # 80001560 <kalloc>
    8000255e:	89aa                	mv	s3,a0
    80002560:	eca8                	sd	a0,88(s1)
    80002562:	c139                	beqz	a0,800025a8 <allocproc+0xac>
  p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    80002564:	00000097          	auipc	ra,0x0
    80002568:	f14080e7          	jalr	-236(ra) # 80002478 <proc_pgtbl_init>
    8000256c:	89aa                	mv	s3,a0
    8000256e:	e4a8                	sd	a0,72(s1)
  if(p->pgtbl == 0){ 
    80002570:	c125                	beqz	a0,800025d0 <allocproc+0xd4>
  memset(&p->ctx, 0, sizeof(p->ctx));
    80002572:	07000613          	li	a2,112
    80002576:	4581                	li	a1,0
    80002578:	0f848513          	add	a0,s1,248
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	a40080e7          	jalr	-1472(ra) # 80000fbc <memset>
  p->ctx.ra = (uint64)forkret;
    80002584:	00000797          	auipc	a5,0x0
    80002588:	c5e78793          	add	a5,a5,-930 # 800021e2 <forkret>
    8000258c:	fcfc                	sd	a5,248(s1)
  p->ctx.sp = p->kstack+PGSIZE;
    8000258e:	78fc                	ld	a5,240(s1)
    80002590:	6705                	lui	a4,0x1
    80002592:	97ba                	add	a5,a5,a4
    80002594:	10f4b023          	sd	a5,256(s1)
}
    80002598:	8526                	mv	a0,s1
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6145                	add	sp,sp,48
    800025a6:	8082                	ret
    freeproc(p);
    800025a8:	8526                	mv	a0,s1
    800025aa:	00000097          	auipc	ra,0x0
    800025ae:	e5e080e7          	jalr	-418(ra) # 80002408 <freeproc>
    printf("allocproc: kalloc trapframe failed\n");
    800025b2:	00007517          	auipc	a0,0x7
    800025b6:	ed650513          	add	a0,a0,-298 # 80009488 <digits+0x298>
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	c94080e7          	jalr	-876(ra) # 8000124e <printf>
    release(&p->lock);
    800025c2:	854a                	mv	a0,s2
    800025c4:	00001097          	auipc	ra,0x1
    800025c8:	b5e080e7          	jalr	-1186(ra) # 80003122 <release>
    return 0;
    800025cc:	84ce                	mv	s1,s3
    800025ce:	b7e9                	j	80002598 <allocproc+0x9c>
    freeproc(p);
    800025d0:	8526                	mv	a0,s1
    800025d2:	00000097          	auipc	ra,0x0
    800025d6:	e36080e7          	jalr	-458(ra) # 80002408 <freeproc>
    printf("allocproc: proc_pgtbl_init failed\n");
    800025da:	00007517          	auipc	a0,0x7
    800025de:	ed650513          	add	a0,a0,-298 # 800094b0 <digits+0x2c0>
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	c6c080e7          	jalr	-916(ra) # 8000124e <printf>
    release(&p->lock);
    800025ea:	854a                	mv	a0,s2
    800025ec:	00001097          	auipc	ra,0x1
    800025f0:	b36080e7          	jalr	-1226(ra) # 80003122 <release>
    return 0;
    800025f4:	84ce                	mv	s1,s3
    800025f6:	b74d                	j	80002598 <allocproc+0x9c>

00000000800025f8 <userinit>:
//__attribute__ ((aligned (16))) char proc0stack[8192];

// Set up first user process.
void
userinit(void)
{
    800025f8:	7179                	add	sp,sp,-48
    800025fa:	f406                	sd	ra,40(sp)
    800025fc:	f022                	sd	s0,32(sp)
    800025fe:	ec26                	sd	s1,24(sp)
    80002600:	e84a                	sd	s2,16(sp)
    80002602:	e44e                	sd	s3,8(sp)
    80002604:	1800                	add	s0,sp,48
  struct proc *p;

  p = allocproc();
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	ef6080e7          	jalr	-266(ra) # 800024fc <allocproc>
    8000260e:	84aa                	mv	s1,a0
  proczero = p;
    80002610:	00008797          	auipc	a5,0x8
    80002614:	80a7b423          	sd	a0,-2040(a5) # 80009e18 <proczero>
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pgtbl, (uchar*)initcode_start, (uint64)(initcode_end - initcode_start));
    80002618:	00005597          	auipc	a1,0x5
    8000261c:	96c58593          	add	a1,a1,-1684 # 80006f84 <initcode_start>
    80002620:	00005617          	auipc	a2,0x5
    80002624:	bd460613          	add	a2,a2,-1068 # 800071f4 <initcode_end>
    80002628:	9e0d                	subw	a2,a2,a1
    8000262a:	6528                	ld	a0,72(a0)
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	49a080e7          	jalr	1178(ra) # 80001ac6 <uvmfirst>
  p->sz = PGSIZE;
    80002634:	6785                	lui	a5,0x1
    80002636:	f4fc                	sd	a5,232(s1)

  // prepare for the very first "return" from kernel to user.
  p->tf->epc = 0;      // user program counter
    80002638:	6cb8                	ld	a4,88(s1)
    8000263a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    8000263e:	6cb8                	ld	a4,88(s1)
    80002640:	fb1c                	sd	a5,48(a4)
  

  // safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
    80002642:	00007517          	auipc	a0,0x7
    80002646:	e9650513          	add	a0,a0,-362 # 800094d8 <digits+0x2e8>
    8000264a:	00004097          	auipc	ra,0x4
    8000264e:	154080e7          	jalr	340(ra) # 8000679e <namei>
    80002652:	f0e8                	sd	a0,224(s1)

  // 为 init 进程预置标准输入/输出/错误到 console。
  // 这样用户态的 read/write/printf 才能在没有 "init" 用户程序做 open/dup 的情况下工作。
  struct file *cf = filealloc();
    80002654:	00004097          	auipc	ra,0x4
    80002658:	9fc080e7          	jalr	-1540(ra) # 80006050 <filealloc>
  if(cf == 0)
    8000265c:	c539                	beqz	a0,800026aa <userinit+0xb2>
    8000265e:	892a                	mv	s2,a0
    panic("userinit: filealloc console");
  cf->type = FD_DEVICE;
    80002660:	498d                	li	s3,3
    80002662:	01352023          	sw	s3,0(a0)
  cf->major = CONSOLE;
    80002666:	4785                	li	a5,1
    80002668:	02f51223          	sh	a5,36(a0)
  cf->readable = 1;
    8000266c:	00f50423          	sb	a5,8(a0)
  cf->writable = 1;
    80002670:	00f504a3          	sb	a5,9(a0)
  p->ofile[0] = cf;
    80002674:	f0a8                	sd	a0,96(s1)
  p->ofile[1] = filedup(cf);
    80002676:	00004097          	auipc	ra,0x4
    8000267a:	a44080e7          	jalr	-1468(ra) # 800060ba <filedup>
    8000267e:	f4a8                	sd	a0,104(s1)
  p->ofile[2] = filedup(cf);
    80002680:	854a                	mv	a0,s2
    80002682:	00004097          	auipc	ra,0x4
    80002686:	a38080e7          	jalr	-1480(ra) # 800060ba <filedup>
    8000268a:	f8a8                	sd	a0,112(s1)

  p->state = RUNNABLE;
    8000268c:	0334a023          	sw	s3,32(s1)

  release(&p->lock);
    80002690:	00848513          	add	a0,s1,8
    80002694:	00001097          	auipc	ra,0x1
    80002698:	a8e080e7          	jalr	-1394(ra) # 80003122 <release>
}
    8000269c:	70a2                	ld	ra,40(sp)
    8000269e:	7402                	ld	s0,32(sp)
    800026a0:	64e2                	ld	s1,24(sp)
    800026a2:	6942                	ld	s2,16(sp)
    800026a4:	69a2                	ld	s3,8(sp)
    800026a6:	6145                	add	sp,sp,48
    800026a8:	8082                	ret
    panic("userinit: filealloc console");
    800026aa:	00007517          	auipc	a0,0x7
    800026ae:	e3650513          	add	a0,a0,-458 # 800094e0 <digits+0x2f0>
    800026b2:	fffff097          	auipc	ra,0xfffff
    800026b6:	b52080e7          	jalr	-1198(ra) # 80001204 <panic>

00000000800026ba <growproc>:

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
    800026ba:	1101                	add	sp,sp,-32
    800026bc:	ec06                	sd	ra,24(sp)
    800026be:	e822                	sd	s0,16(sp)
    800026c0:	e426                	sd	s1,8(sp)
    800026c2:	e04a                	sd	s2,0(sp)
    800026c4:	1000                	add	s0,sp,32
    800026c6:	892a                	mv	s2,a0
  uint64 sz;
  struct proc *p = myproc();
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	a9c080e7          	jalr	-1380(ra) # 80002164 <myproc>
    800026d0:	84aa                	mv	s1,a0

  sz = p->sz;
    800026d2:	756c                	ld	a1,232(a0)
  if(n > 0){
    800026d4:	01204c63          	bgtz	s2,800026ec <growproc+0x32>
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    800026d8:	02094663          	bltz	s2,80002704 <growproc+0x4a>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
  }
  p->sz = sz;
    800026dc:	f4ec                	sd	a1,232(s1)
  return 0;
    800026de:	4501                	li	a0,0
}
    800026e0:	60e2                	ld	ra,24(sp)
    800026e2:	6442                	ld	s0,16(sp)
    800026e4:	64a2                	ld	s1,8(sp)
    800026e6:	6902                	ld	s2,0(sp)
    800026e8:	6105                	add	sp,sp,32
    800026ea:	8082                	ret
    if((sz = uvmalloc(p->pgtbl, sz, sz + n, PTE_W)) == 0) {
    800026ec:	4691                	li	a3,4
    800026ee:	00b90633          	add	a2,s2,a1
    800026f2:	6528                	ld	a0,72(a0)
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	556080e7          	jalr	1366(ra) # 80001c4a <uvmalloc>
    800026fc:	85aa                	mv	a1,a0
    800026fe:	fd79                	bnez	a0,800026dc <growproc+0x22>
      return -1;
    80002700:	557d                	li	a0,-1
    80002702:	bff9                	j	800026e0 <growproc+0x26>
    sz = uvmdealloc(p->pgtbl, sz, sz + n);
    80002704:	00b90633          	add	a2,s2,a1
    80002708:	6528                	ld	a0,72(a0)
    8000270a:	fffff097          	auipc	ra,0xfffff
    8000270e:	4f8080e7          	jalr	1272(ra) # 80001c02 <uvmdealloc>
    80002712:	85aa                	mv	a1,a0
    80002714:	b7e1                	j	800026dc <growproc+0x22>

0000000080002716 <uvmcopy>:
  pte_t *pte;
  uint64 pa, current_va;
  uint flags;
  char *mem;

  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    80002716:	ca69                	beqz	a2,800027e8 <uvmcopy+0xd2>
{
    80002718:	715d                	add	sp,sp,-80
    8000271a:	e486                	sd	ra,72(sp)
    8000271c:	e0a2                	sd	s0,64(sp)
    8000271e:	fc26                	sd	s1,56(sp)
    80002720:	f84a                	sd	s2,48(sp)
    80002722:	f44e                	sd	s3,40(sp)
    80002724:	f052                	sd	s4,32(sp)
    80002726:	ec56                	sd	s5,24(sp)
    80002728:	e85a                	sd	s6,16(sp)
    8000272a:	e45e                	sd	s7,8(sp)
    8000272c:	0880                	add	s0,sp,80
    8000272e:	8b2a                	mv	s6,a0
    80002730:	8a2e                	mv	s4,a1
    80002732:	8ab2                	mv	s5,a2
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    80002734:	4981                	li	s3,0
  {
    pte = walk(old, current_va, 0);
    80002736:	4601                	li	a2,0
    80002738:	85ce                	mv	a1,s3
    8000273a:	855a                	mv	a0,s6
    8000273c:	fffff097          	auipc	ra,0xfffff
    80002740:	eaa080e7          	jalr	-342(ra) # 800015e6 <walk>
    if (pte == 0)
    80002744:	c539                	beqz	a0,80002792 <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");

    if (!is_pte_valid(*pte))
    80002746:	6118                	ld	a4,0(a0)
  return (pte & PTE_V) != 0;
    80002748:	00177793          	and	a5,a4,1
    if (!is_pte_valid(*pte))
    8000274c:	cbb9                	beqz	a5,800027a2 <uvmcopy+0x8c>
      panic("uvmcopy: page not present");

    pa = PTE2PA(*pte);
    8000274e:	00a75593          	srl	a1,a4,0xa
    80002752:	00c59b93          	sll	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80002756:	3ff77913          	and	s2,a4,1023
  *dest_mem = kalloc(1);
    8000275a:	4505                	li	a0,1
    8000275c:	fffff097          	auipc	ra,0xfffff
    80002760:	e04080e7          	jalr	-508(ra) # 80001560 <kalloc>
    80002764:	84aa                	mv	s1,a0
  if (*dest_mem == 0)
    80002766:	cd21                	beqz	a0,800027be <uvmcopy+0xa8>
  memmove(*dest_mem, (char *)src_pa, PGSIZE);
    80002768:	6605                	lui	a2,0x1
    8000276a:	85de                	mv	a1,s7
    8000276c:	fffff097          	auipc	ra,0xfffff
    80002770:	8ac080e7          	jalr	-1876(ra) # 80001018 <memmove>

    if (copy_physical_page(pa, &mem) != 0)
      goto err;

    if (mappages(new, current_va, PGSIZE, (uint64)mem, flags) != 0)
    80002774:	874a                	mv	a4,s2
    80002776:	86a6                	mv	a3,s1
    80002778:	6605                	lui	a2,0x1
    8000277a:	85ce                	mv	a1,s3
    8000277c:	8552                	mv	a0,s4
    8000277e:	fffff097          	auipc	ra,0xfffff
    80002782:	f10080e7          	jalr	-240(ra) # 8000168e <mappages>
    80002786:	e515                	bnez	a0,800027b2 <uvmcopy+0x9c>
  for (current_va = 0; current_va < sz; current_va += PGSIZE)
    80002788:	6785                	lui	a5,0x1
    8000278a:	99be                	add	s3,s3,a5
    8000278c:	fb59e5e3          	bltu	s3,s5,80002736 <uvmcopy+0x20>
    80002790:	a089                	j	800027d2 <uvmcopy+0xbc>
      panic("uvmcopy: pte should exist");
    80002792:	00007517          	auipc	a0,0x7
    80002796:	d6e50513          	add	a0,a0,-658 # 80009500 <digits+0x310>
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	a6a080e7          	jalr	-1430(ra) # 80001204 <panic>
      panic("uvmcopy: page not present");
    800027a2:	00007517          	auipc	a0,0x7
    800027a6:	d7e50513          	add	a0,a0,-642 # 80009520 <digits+0x330>
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	a5a080e7          	jalr	-1446(ra) # 80001204 <panic>
    {
      kfree((uint64)mem,1);
    800027b2:	4585                	li	a1,1
    800027b4:	8526                	mv	a0,s1
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	caa080e7          	jalr	-854(ra) # 80001460 <kfree>
  uvmunmap(new_table, 0, npages, 1);
    800027be:	4685                	li	a3,1
    800027c0:	00c9d613          	srl	a2,s3,0xc
    800027c4:	4581                	li	a1,0
    800027c6:	8552                	mv	a0,s4
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	372080e7          	jalr	882(ra) # 80001b3a <uvmunmap>
  }
  return 0;

err:
  cleanup_partial_copy(new, current_va);
  return -1;
    800027d0:	557d                	li	a0,-1
}
    800027d2:	60a6                	ld	ra,72(sp)
    800027d4:	6406                	ld	s0,64(sp)
    800027d6:	74e2                	ld	s1,56(sp)
    800027d8:	7942                	ld	s2,48(sp)
    800027da:	79a2                	ld	s3,40(sp)
    800027dc:	7a02                	ld	s4,32(sp)
    800027de:	6ae2                	ld	s5,24(sp)
    800027e0:	6b42                	ld	s6,16(sp)
    800027e2:	6ba2                	ld	s7,8(sp)
    800027e4:	6161                	add	sp,sp,80
    800027e6:	8082                	ret
  return 0;
    800027e8:	4501                	li	a0,0
}
    800027ea:	8082                	ret

00000000800027ec <fork>:

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
    800027ec:	7139                	add	sp,sp,-64
    800027ee:	fc06                	sd	ra,56(sp)
    800027f0:	f822                	sd	s0,48(sp)
    800027f2:	f426                	sd	s1,40(sp)
    800027f4:	f04a                	sd	s2,32(sp)
    800027f6:	ec4e                	sd	s3,24(sp)
    800027f8:	e852                	sd	s4,16(sp)
    800027fa:	e456                	sd	s5,8(sp)
    800027fc:	0080                	add	s0,sp,64
  int i; 
  int pid;
  struct proc *np;
  struct proc *p = myproc();
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	966080e7          	jalr	-1690(ra) # 80002164 <myproc>
    80002806:	8aaa                	mv	s5,a0

  // Allocate process.
  if((np = allocproc()) == 0){
    80002808:	00000097          	auipc	ra,0x0
    8000280c:	cf4080e7          	jalr	-780(ra) # 800024fc <allocproc>
    80002810:	10050663          	beqz	a0,8000291c <fork+0x130>
    80002814:	8a2a                	mv	s4,a0
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pgtbl, np->pgtbl, p->sz) < 0){
    80002816:	0e8ab603          	ld	a2,232(s5)
    8000281a:	652c                	ld	a1,72(a0)
    8000281c:	048ab503          	ld	a0,72(s5)
    80002820:	00000097          	auipc	ra,0x0
    80002824:	ef6080e7          	jalr	-266(ra) # 80002716 <uvmcopy>
    80002828:	04054863          	bltz	a0,80002878 <fork+0x8c>
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;
    8000282c:	0e8ab783          	ld	a5,232(s5)
    80002830:	0efa3423          	sd	a5,232(s4)

  // copy saved user registers.
  *(np->tf) = *(p->tf);
    80002834:	058ab683          	ld	a3,88(s5)
    80002838:	87b6                	mv	a5,a3
    8000283a:	058a3703          	ld	a4,88(s4)
    8000283e:	12068693          	add	a3,a3,288
    80002842:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002846:	6788                	ld	a0,8(a5)
    80002848:	6b8c                	ld	a1,16(a5)
    8000284a:	6f90                	ld	a2,24(a5)
    8000284c:	01073023          	sd	a6,0(a4)
    80002850:	e708                	sd	a0,8(a4)
    80002852:	eb0c                	sd	a1,16(a4)
    80002854:	ef10                	sd	a2,24(a4)
    80002856:	02078793          	add	a5,a5,32
    8000285a:	02070713          	add	a4,a4,32
    8000285e:	fed792e3          	bne	a5,a3,80002842 <fork+0x56>

  // Cause fork to return 0 in the child.
  np->tf->a0 = 0;
    80002862:	058a3783          	ld	a5,88(s4)
    80002866:	0607b823          	sd	zero,112(a5)

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++) 
    8000286a:	060a8493          	add	s1,s5,96
    8000286e:	060a0913          	add	s2,s4,96
    80002872:	0e0a8993          	add	s3,s5,224
    80002876:	a015                	j	8000289a <fork+0xae>
    freeproc(np);
    80002878:	8552                	mv	a0,s4
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	b8e080e7          	jalr	-1138(ra) # 80002408 <freeproc>
    release(&np->lock);
    80002882:	008a0513          	add	a0,s4,8
    80002886:	00001097          	auipc	ra,0x1
    8000288a:	89c080e7          	jalr	-1892(ra) # 80003122 <release>
    return -1;
    8000288e:	59fd                	li	s3,-1
    80002890:	a8a5                	j	80002908 <fork+0x11c>
  for(i = 0; i < NOFILE; i++) 
    80002892:	04a1                	add	s1,s1,8
    80002894:	0921                	add	s2,s2,8
    80002896:	01348b63          	beq	s1,s3,800028ac <fork+0xc0>
    if(p->ofile[i])
    8000289a:	6088                	ld	a0,0(s1)
    8000289c:	d97d                	beqz	a0,80002892 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    8000289e:	00004097          	auipc	ra,0x4
    800028a2:	81c080e7          	jalr	-2020(ra) # 800060ba <filedup>
    800028a6:	00a93023          	sd	a0,0(s2)
    800028aa:	b7e5                	j	80002892 <fork+0xa6>
  np->cwd = idup(p->cwd);
    800028ac:	0e0ab503          	ld	a0,224(s5)
    800028b0:	00002097          	auipc	ra,0x2
    800028b4:	7f2080e7          	jalr	2034(ra) # 800050a2 <idup>
    800028b8:	0eaa3023          	sd	a0,224(s4)

  //safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;
    800028bc:	000a2983          	lw	s3,0(s4)

  release(&np->lock);
    800028c0:	008a0493          	add	s1,s4,8
    800028c4:	8526                	mv	a0,s1
    800028c6:	00001097          	auipc	ra,0x1
    800028ca:	85c080e7          	jalr	-1956(ra) # 80003122 <release>

  acquire(&wait_lock);
    800028ce:	00015917          	auipc	s2,0x15
    800028d2:	74a90913          	add	s2,s2,1866 # 80018018 <wait_lock>
    800028d6:	854a                	mv	a0,s2
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	796080e7          	jalr	1942(ra) # 8000306e <acquire>
  np->parent = p;
    800028e0:	035a3423          	sd	s5,40(s4)
  release(&wait_lock);
    800028e4:	854a                	mv	a0,s2
    800028e6:	00001097          	auipc	ra,0x1
    800028ea:	83c080e7          	jalr	-1988(ra) # 80003122 <release>

  acquire(&np->lock);
    800028ee:	8526                	mv	a0,s1
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	77e080e7          	jalr	1918(ra) # 8000306e <acquire>
  np->state = RUNNABLE;
    800028f8:	478d                	li	a5,3
    800028fa:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    800028fe:	8526                	mv	a0,s1
    80002900:	00001097          	auipc	ra,0x1
    80002904:	822080e7          	jalr	-2014(ra) # 80003122 <release>

  return pid;
}
    80002908:	854e                	mv	a0,s3
    8000290a:	70e2                	ld	ra,56(sp)
    8000290c:	7442                	ld	s0,48(sp)
    8000290e:	74a2                	ld	s1,40(sp)
    80002910:	7902                	ld	s2,32(sp)
    80002912:	69e2                	ld	s3,24(sp)
    80002914:	6a42                	ld	s4,16(sp)
    80002916:	6aa2                	ld	s5,8(sp)
    80002918:	6121                	add	sp,sp,64
    8000291a:	8082                	ret
    return -1;
    8000291c:	59fd                	li	s3,-1
    8000291e:	b7ed                	j	80002908 <fork+0x11c>

0000000080002920 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002920:	7179                	add	sp,sp,-48
    80002922:	f406                	sd	ra,40(sp)
    80002924:	f022                	sd	s0,32(sp)
    80002926:	ec26                	sd	s1,24(sp)
    80002928:	e84a                	sd	s2,16(sp)
    8000292a:	e44e                	sd	s3,8(sp)
    8000292c:	e052                	sd	s4,0(sp)
    8000292e:	1800                	add	s0,sp,48
    80002930:	89aa                	mv	s3,a0
    80002932:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002934:	00000097          	auipc	ra,0x0
    80002938:	830080e7          	jalr	-2000(ra) # 80002164 <myproc>
    8000293c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000293e:	00850a13          	add	s4,a0,8
    80002942:	8552                	mv	a0,s4
    80002944:	00000097          	auipc	ra,0x0
    80002948:	72a080e7          	jalr	1834(ra) # 8000306e <acquire>
  release(lk);
    8000294c:	854a                	mv	a0,s2
    8000294e:	00000097          	auipc	ra,0x0
    80002952:	7d4080e7          	jalr	2004(ra) # 80003122 <release>

  // Go to sleep.
  p->chan = chan;
    80002956:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    8000295a:	4789                	li	a5,2
    8000295c:	d09c                	sw	a5,32(s1)

  sched();
    8000295e:	00001097          	auipc	ra,0x1
    80002962:	a62080e7          	jalr	-1438(ra) # 800033c0 <sched>

  // Tidy up.
  p->chan = 0;
    80002966:	0204b823          	sd	zero,48(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000296a:	8552                	mv	a0,s4
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	7b6080e7          	jalr	1974(ra) # 80003122 <release>
  acquire(lk);
    80002974:	854a                	mv	a0,s2
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	6f8080e7          	jalr	1784(ra) # 8000306e <acquire>
}
    8000297e:	70a2                	ld	ra,40(sp)
    80002980:	7402                	ld	s0,32(sp)
    80002982:	64e2                	ld	s1,24(sp)
    80002984:	6942                	ld	s2,16(sp)
    80002986:	69a2                	ld	s3,8(sp)
    80002988:	6a02                	ld	s4,0(sp)
    8000298a:	6145                	add	sp,sp,48
    8000298c:	8082                	ret

000000008000298e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000298e:	7139                	add	sp,sp,-64
    80002990:	fc06                	sd	ra,56(sp)
    80002992:	f822                	sd	s0,48(sp)
    80002994:	f426                	sd	s1,40(sp)
    80002996:	f04a                	sd	s2,32(sp)
    80002998:	ec4e                	sd	s3,24(sp)
    8000299a:	e852                	sd	s4,16(sp)
    8000299c:	e456                	sd	s5,8(sp)
    8000299e:	e05a                	sd	s6,0(sp)
    800029a0:	0080                	add	s0,sp,64
    800029a2:	8aaa                	mv	s5,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800029a4:	00010497          	auipc	s1,0x10
    800029a8:	c7448493          	add	s1,s1,-908 # 80012618 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800029ac:	4a09                	li	s4,2
        p->state = RUNNABLE;
    800029ae:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800029b0:	00015997          	auipc	s3,0x15
    800029b4:	66898993          	add	s3,s3,1640 # 80018018 <wait_lock>
    800029b8:	a811                	j	800029cc <wakeup+0x3e>
      }
      release(&p->lock);
    800029ba:	854a                	mv	a0,s2
    800029bc:	00000097          	auipc	ra,0x0
    800029c0:	766080e7          	jalr	1894(ra) # 80003122 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800029c4:	16848493          	add	s1,s1,360
    800029c8:	03348863          	beq	s1,s3,800029f8 <wakeup+0x6a>
    if(p != myproc()){
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	798080e7          	jalr	1944(ra) # 80002164 <myproc>
    800029d4:	fea488e3          	beq	s1,a0,800029c4 <wakeup+0x36>
      acquire(&p->lock);
    800029d8:	00848913          	add	s2,s1,8
    800029dc:	854a                	mv	a0,s2
    800029de:	00000097          	auipc	ra,0x0
    800029e2:	690080e7          	jalr	1680(ra) # 8000306e <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800029e6:	509c                	lw	a5,32(s1)
    800029e8:	fd4799e3          	bne	a5,s4,800029ba <wakeup+0x2c>
    800029ec:	789c                	ld	a5,48(s1)
    800029ee:	fd5796e3          	bne	a5,s5,800029ba <wakeup+0x2c>
        p->state = RUNNABLE;
    800029f2:	0364a023          	sw	s6,32(s1)
    800029f6:	b7d1                	j	800029ba <wakeup+0x2c>
    }
  }
}
    800029f8:	70e2                	ld	ra,56(sp)
    800029fa:	7442                	ld	s0,48(sp)
    800029fc:	74a2                	ld	s1,40(sp)
    800029fe:	7902                	ld	s2,32(sp)
    80002a00:	69e2                	ld	s3,24(sp)
    80002a02:	6a42                	ld	s4,16(sp)
    80002a04:	6aa2                	ld	s5,8(sp)
    80002a06:	6b02                	ld	s6,0(sp)
    80002a08:	6121                	add	sp,sp,64
    80002a0a:	8082                	ret

0000000080002a0c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a0c:	7179                	add	sp,sp,-48
    80002a0e:	f406                	sd	ra,40(sp)
    80002a10:	f022                	sd	s0,32(sp)
    80002a12:	ec26                	sd	s1,24(sp)
    80002a14:	e84a                	sd	s2,16(sp)
    80002a16:	e44e                	sd	s3,8(sp)
    80002a18:	e052                	sd	s4,0(sp)
    80002a1a:	1800                	add	s0,sp,48
    80002a1c:	89aa                	mv	s3,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a1e:	00010497          	auipc	s1,0x10
    80002a22:	bfa48493          	add	s1,s1,-1030 # 80012618 <proc>
    80002a26:	00015a17          	auipc	s4,0x15
    80002a2a:	5f2a0a13          	add	s4,s4,1522 # 80018018 <wait_lock>
    acquire(&p->lock);
    80002a2e:	00848913          	add	s2,s1,8
    80002a32:	854a                	mv	a0,s2
    80002a34:	00000097          	auipc	ra,0x0
    80002a38:	63a080e7          	jalr	1594(ra) # 8000306e <acquire>
    if(p->pid == pid){
    80002a3c:	409c                	lw	a5,0(s1)
    80002a3e:	01378d63          	beq	a5,s3,80002a58 <kill+0x4c>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a42:	854a                	mv	a0,s2
    80002a44:	00000097          	auipc	ra,0x0
    80002a48:	6de080e7          	jalr	1758(ra) # 80003122 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a4c:	16848493          	add	s1,s1,360
    80002a50:	fd449fe3          	bne	s1,s4,80002a2e <kill+0x22>
  }
  return -1;
    80002a54:	557d                	li	a0,-1
    80002a56:	a829                	j	80002a70 <kill+0x64>
      p->killed = 1;
    80002a58:	4785                	li	a5,1
    80002a5a:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002a5c:	5098                	lw	a4,32(s1)
    80002a5e:	4789                	li	a5,2
    80002a60:	02f70063          	beq	a4,a5,80002a80 <kill+0x74>
      release(&p->lock);
    80002a64:	854a                	mv	a0,s2
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	6bc080e7          	jalr	1724(ra) # 80003122 <release>
      return 0;
    80002a6e:	4501                	li	a0,0
}
    80002a70:	70a2                	ld	ra,40(sp)
    80002a72:	7402                	ld	s0,32(sp)
    80002a74:	64e2                	ld	s1,24(sp)
    80002a76:	6942                	ld	s2,16(sp)
    80002a78:	69a2                	ld	s3,8(sp)
    80002a7a:	6a02                	ld	s4,0(sp)
    80002a7c:	6145                	add	sp,sp,48
    80002a7e:	8082                	ret
        p->state = RUNNABLE;
    80002a80:	478d                	li	a5,3
    80002a82:	d09c                	sw	a5,32(s1)
    80002a84:	b7c5                	j	80002a64 <kill+0x58>

0000000080002a86 <setkilled>:

void
setkilled(struct proc *p)
{
    80002a86:	1101                	add	sp,sp,-32
    80002a88:	ec06                	sd	ra,24(sp)
    80002a8a:	e822                	sd	s0,16(sp)
    80002a8c:	e426                	sd	s1,8(sp)
    80002a8e:	e04a                	sd	s2,0(sp)
    80002a90:	1000                	add	s0,sp,32
    80002a92:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002a94:	00850913          	add	s2,a0,8
    80002a98:	854a                	mv	a0,s2
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	5d4080e7          	jalr	1492(ra) # 8000306e <acquire>
  p->killed = 1;
    80002aa2:	4785                	li	a5,1
    80002aa4:	dc9c                	sw	a5,56(s1)
  release(&p->lock);
    80002aa6:	854a                	mv	a0,s2
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	67a080e7          	jalr	1658(ra) # 80003122 <release>
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6902                	ld	s2,0(sp)
    80002ab8:	6105                	add	sp,sp,32
    80002aba:	8082                	ret

0000000080002abc <killed>:

int
killed(struct proc *p)
{
    80002abc:	1101                	add	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	e04a                	sd	s2,0(sp)
    80002ac6:	1000                	add	s0,sp,32
    80002ac8:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002aca:	00850913          	add	s2,a0,8
    80002ace:	854a                	mv	a0,s2
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	59e080e7          	jalr	1438(ra) # 8000306e <acquire>
  k = p->killed;
    80002ad8:	5c84                	lw	s1,56(s1)
  release(&p->lock);
    80002ada:	854a                	mv	a0,s2
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	646080e7          	jalr	1606(ra) # 80003122 <release>
  return k;
}
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	60e2                	ld	ra,24(sp)
    80002ae8:	6442                	ld	s0,16(sp)
    80002aea:	64a2                	ld	s1,8(sp)
    80002aec:	6902                	ld	s2,0(sp)
    80002aee:	6105                	add	sp,sp,32
    80002af0:	8082                	ret

0000000080002af2 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
    80002af2:	711d                	add	sp,sp,-96
    80002af4:	ec86                	sd	ra,88(sp)
    80002af6:	e8a2                	sd	s0,80(sp)
    80002af8:	e4a6                	sd	s1,72(sp)
    80002afa:	e0ca                	sd	s2,64(sp)
    80002afc:	fc4e                	sd	s3,56(sp)
    80002afe:	f852                	sd	s4,48(sp)
    80002b00:	f456                	sd	s5,40(sp)
    80002b02:	f05a                	sd	s6,32(sp)
    80002b04:	ec5e                	sd	s7,24(sp)
    80002b06:	e862                	sd	s8,16(sp)
    80002b08:	e466                	sd	s9,8(sp)
    80002b0a:	1080                	add	s0,sp,96
    80002b0c:	8baa                	mv	s7,a0
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	656080e7          	jalr	1622(ra) # 80002164 <myproc>
    80002b16:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002b18:	00015517          	auipc	a0,0x15
    80002b1c:	50050513          	add	a0,a0,1280 # 80018018 <wait_lock>
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	54e080e7          	jalr	1358(ra) # 8000306e <acquire>

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    80002b28:	4c01                	li	s8,0
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
    80002b2a:	4a95                	li	s5,5
        havekids = 1;
    80002b2c:	4b05                	li	s6,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b2e:	00015997          	auipc	s3,0x15
    80002b32:	4ea98993          	add	s3,s3,1258 # 80018018 <wait_lock>
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b36:	00015c97          	auipc	s9,0x15
    80002b3a:	4e2c8c93          	add	s9,s9,1250 # 80018018 <wait_lock>
    80002b3e:	a8f1                	j	80002c1a <wait+0x128>
          printf("wait: found zombie pid=%d\n", pp->pid);
    80002b40:	408c                	lw	a1,0(s1)
    80002b42:	00007517          	auipc	a0,0x7
    80002b46:	9fe50513          	add	a0,a0,-1538 # 80009540 <digits+0x350>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	704080e7          	jalr	1796(ra) # 8000124e <printf>
          pid = pp->pid;
    80002b52:	0004a983          	lw	s3,0(s1)
          if(addr != 0 && uvm_copyout(p->pgtbl, addr, (uint64)&pp->exit_state,
    80002b56:	000b8e63          	beqz	s7,80002b72 <wait+0x80>
    80002b5a:	4691                	li	a3,4
    80002b5c:	03c48613          	add	a2,s1,60
    80002b60:	85de                	mv	a1,s7
    80002b62:	04893503          	ld	a0,72(s2)
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	23a080e7          	jalr	570(ra) # 80001da0 <uvm_copyout>
    80002b6e:	04054263          	bltz	a0,80002bb2 <wait+0xc0>
          freeproc(pp);
    80002b72:	8526                	mv	a0,s1
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	894080e7          	jalr	-1900(ra) # 80002408 <freeproc>
          release(&pp->lock);
    80002b7c:	8552                	mv	a0,s4
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	5a4080e7          	jalr	1444(ra) # 80003122 <release>
          release(&wait_lock);
    80002b86:	00015517          	auipc	a0,0x15
    80002b8a:	49250513          	add	a0,a0,1170 # 80018018 <wait_lock>
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	594080e7          	jalr	1428(ra) # 80003122 <release>
  }
}
    80002b96:	854e                	mv	a0,s3
    80002b98:	60e6                	ld	ra,88(sp)
    80002b9a:	6446                	ld	s0,80(sp)
    80002b9c:	64a6                	ld	s1,72(sp)
    80002b9e:	6906                	ld	s2,64(sp)
    80002ba0:	79e2                	ld	s3,56(sp)
    80002ba2:	7a42                	ld	s4,48(sp)
    80002ba4:	7aa2                	ld	s5,40(sp)
    80002ba6:	7b02                	ld	s6,32(sp)
    80002ba8:	6be2                	ld	s7,24(sp)
    80002baa:	6c42                	ld	s8,16(sp)
    80002bac:	6ca2                	ld	s9,8(sp)
    80002bae:	6125                	add	sp,sp,96
    80002bb0:	8082                	ret
            release(&pp->lock);
    80002bb2:	8552                	mv	a0,s4
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	56e080e7          	jalr	1390(ra) # 80003122 <release>
            release(&wait_lock);
    80002bbc:	00015517          	auipc	a0,0x15
    80002bc0:	45c50513          	add	a0,a0,1116 # 80018018 <wait_lock>
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	55e080e7          	jalr	1374(ra) # 80003122 <release>
            return -1;
    80002bcc:	59fd                	li	s3,-1
    80002bce:	b7e1                	j	80002b96 <wait+0xa4>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bd0:	16848493          	add	s1,s1,360
    80002bd4:	03348663          	beq	s1,s3,80002c00 <wait+0x10e>
      if(pp->parent == p){
    80002bd8:	749c                	ld	a5,40(s1)
    80002bda:	ff279be3          	bne	a5,s2,80002bd0 <wait+0xde>
        acquire(&pp->lock);
    80002bde:	00848a13          	add	s4,s1,8
    80002be2:	8552                	mv	a0,s4
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	48a080e7          	jalr	1162(ra) # 8000306e <acquire>
        if(pp->state == ZOMBIE){
    80002bec:	509c                	lw	a5,32(s1)
    80002bee:	f55789e3          	beq	a5,s5,80002b40 <wait+0x4e>
        release(&pp->lock);
    80002bf2:	8552                	mv	a0,s4
    80002bf4:	00000097          	auipc	ra,0x0
    80002bf8:	52e080e7          	jalr	1326(ra) # 80003122 <release>
        havekids = 1;
    80002bfc:	875a                	mv	a4,s6
    80002bfe:	bfc9                	j	80002bd0 <wait+0xde>
    if(!havekids || killed(p)){
    80002c00:	c31d                	beqz	a4,80002c26 <wait+0x134>
    80002c02:	854a                	mv	a0,s2
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	eb8080e7          	jalr	-328(ra) # 80002abc <killed>
    80002c0c:	ed09                	bnez	a0,80002c26 <wait+0x134>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002c0e:	85e6                	mv	a1,s9
    80002c10:	854a                	mv	a0,s2
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	d0e080e7          	jalr	-754(ra) # 80002920 <sleep>
    havekids = 0;
    80002c1a:	8762                	mv	a4,s8
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c1c:	00010497          	auipc	s1,0x10
    80002c20:	9fc48493          	add	s1,s1,-1540 # 80012618 <proc>
    80002c24:	bf55                	j	80002bd8 <wait+0xe6>
      release(&wait_lock);
    80002c26:	00015517          	auipc	a0,0x15
    80002c2a:	3f250513          	add	a0,a0,1010 # 80018018 <wait_lock>
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	4f4080e7          	jalr	1268(ra) # 80003122 <release>
      return -1;
    80002c36:	59fd                	li	s3,-1
    80002c38:	bfb9                	j	80002b96 <wait+0xa4>

0000000080002c3a <reparent>:

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
    80002c3a:	7179                	add	sp,sp,-48
    80002c3c:	f406                	sd	ra,40(sp)
    80002c3e:	f022                	sd	s0,32(sp)
    80002c40:	ec26                	sd	s1,24(sp)
    80002c42:	e84a                	sd	s2,16(sp)
    80002c44:	e44e                	sd	s3,8(sp)
    80002c46:	e052                	sd	s4,0(sp)
    80002c48:	1800                	add	s0,sp,48
    80002c4a:	892a                	mv	s2,a0
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c4c:	00010497          	auipc	s1,0x10
    80002c50:	9cc48493          	add	s1,s1,-1588 # 80012618 <proc>
    if(pp->parent == p){
      pp->parent = proczero;
    80002c54:	00007a17          	auipc	s4,0x7
    80002c58:	1c4a0a13          	add	s4,s4,452 # 80009e18 <proczero>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c5c:	00015997          	auipc	s3,0x15
    80002c60:	3bc98993          	add	s3,s3,956 # 80018018 <wait_lock>
    80002c64:	a029                	j	80002c6e <reparent+0x34>
    80002c66:	16848493          	add	s1,s1,360
    80002c6a:	01348d63          	beq	s1,s3,80002c84 <reparent+0x4a>
    if(pp->parent == p){
    80002c6e:	749c                	ld	a5,40(s1)
    80002c70:	ff279be3          	bne	a5,s2,80002c66 <reparent+0x2c>
      pp->parent = proczero;
    80002c74:	000a3503          	ld	a0,0(s4)
    80002c78:	f488                	sd	a0,40(s1)
      wakeup(proczero);
    80002c7a:	00000097          	auipc	ra,0x0
    80002c7e:	d14080e7          	jalr	-748(ra) # 8000298e <wakeup>
    80002c82:	b7d5                	j	80002c66 <reparent+0x2c>
    }
  }
}
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6942                	ld	s2,16(sp)
    80002c8c:	69a2                	ld	s3,8(sp)
    80002c8e:	6a02                	ld	s4,0(sp)
    80002c90:	6145                	add	sp,sp,48
    80002c92:	8082                	ret

0000000080002c94 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
    80002c94:	7179                	add	sp,sp,-48
    80002c96:	f406                	sd	ra,40(sp)
    80002c98:	f022                	sd	s0,32(sp)
    80002c9a:	ec26                	sd	s1,24(sp)
    80002c9c:	e84a                	sd	s2,16(sp)
    80002c9e:	e44e                	sd	s3,8(sp)
    80002ca0:	e052                	sd	s4,0(sp)
    80002ca2:	1800                	add	s0,sp,48
    80002ca4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	4be080e7          	jalr	1214(ra) # 80002164 <myproc>
    80002cae:	89aa                	mv	s3,a0

  if(p == proczero)
    80002cb0:	00007797          	auipc	a5,0x7
    80002cb4:	1687b783          	ld	a5,360(a5) # 80009e18 <proczero>
    80002cb8:	06050493          	add	s1,a0,96
    80002cbc:	0e050913          	add	s2,a0,224
    80002cc0:	02a79363          	bne	a5,a0,80002ce6 <exit+0x52>
    panic("init exiting");
    80002cc4:	00007517          	auipc	a0,0x7
    80002cc8:	89c50513          	add	a0,a0,-1892 # 80009560 <digits+0x370>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	538080e7          	jalr	1336(ra) # 80001204 <panic>

  // Close all open files. 
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
    80002cd4:	00003097          	auipc	ra,0x3
    80002cd8:	438080e7          	jalr	1080(ra) # 8000610c <fileclose>
      p->ofile[fd] = 0;
    80002cdc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002ce0:	04a1                	add	s1,s1,8
    80002ce2:	01248563          	beq	s1,s2,80002cec <exit+0x58>
    if(p->ofile[fd]){
    80002ce6:	6088                	ld	a0,0(s1)
    80002ce8:	f575                	bnez	a0,80002cd4 <exit+0x40>
    80002cea:	bfdd                	j	80002ce0 <exit+0x4c>
    }
  }

  begin_op();
    80002cec:	00003097          	auipc	ra,0x3
    80002cf0:	086080e7          	jalr	134(ra) # 80005d72 <begin_op>
  iput(p->cwd);
    80002cf4:	0e09b503          	ld	a0,224(s3)
    80002cf8:	00002097          	auipc	ra,0x2
    80002cfc:	5a2080e7          	jalr	1442(ra) # 8000529a <iput>
  end_op();
    80002d00:	00003097          	auipc	ra,0x3
    80002d04:	0ec080e7          	jalr	236(ra) # 80005dec <end_op>
  p->cwd = 0;
    80002d08:	0e09b023          	sd	zero,224(s3)

  acquire(&wait_lock);
    80002d0c:	00015497          	auipc	s1,0x15
    80002d10:	30c48493          	add	s1,s1,780 # 80018018 <wait_lock>
    80002d14:	8526                	mv	a0,s1
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	358080e7          	jalr	856(ra) # 8000306e <acquire>

  // Give any children to init.
  reparent(p);
    80002d1e:	854e                	mv	a0,s3
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	f1a080e7          	jalr	-230(ra) # 80002c3a <reparent>

  // Parent might be sleeping in wait().
  wakeup(p->parent);
    80002d28:	0289b503          	ld	a0,40(s3)
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	c62080e7          	jalr	-926(ra) # 8000298e <wakeup>
  
  acquire(&p->lock);
    80002d34:	00898513          	add	a0,s3,8
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	336080e7          	jalr	822(ra) # 8000306e <acquire>

  p->exit_state = status;
    80002d40:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    80002d44:	4795                	li	a5,5
    80002d46:	02f9a023          	sw	a5,32(s3)

  release(&wait_lock);
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	3d6080e7          	jalr	982(ra) # 80003122 <release>

  // Jump into the scheduler, never to return.
  sched();
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	66c080e7          	jalr	1644(ra) # 800033c0 <sched>
  panic("zombie exit");
    80002d5c:	00007517          	auipc	a0,0x7
    80002d60:	81450513          	add	a0,a0,-2028 # 80009570 <digits+0x380>
    80002d64:	ffffe097          	auipc	ra,0xffffe
    80002d68:	4a0080e7          	jalr	1184(ra) # 80001204 <panic>

0000000080002d6c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002d6c:	7179                	add	sp,sp,-48
    80002d6e:	f406                	sd	ra,40(sp)
    80002d70:	f022                	sd	s0,32(sp)
    80002d72:	ec26                	sd	s1,24(sp)
    80002d74:	e84a                	sd	s2,16(sp)
    80002d76:	e44e                	sd	s3,8(sp)
    80002d78:	e052                	sd	s4,0(sp)
    80002d7a:	1800                	add	s0,sp,48
    80002d7c:	84aa                	mv	s1,a0
    80002d7e:	892e                	mv	s2,a1
    80002d80:	89b2                	mv	s3,a2
    80002d82:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	3e0080e7          	jalr	992(ra) # 80002164 <myproc>
  if(user_dst){
    80002d8c:	c08d                	beqz	s1,80002dae <either_copyout+0x42>
    return copyout(p->pgtbl, dst, src, len);
    80002d8e:	86d2                	mv	a3,s4
    80002d90:	864e                	mv	a2,s3
    80002d92:	85ca                	mv	a1,s2
    80002d94:	6528                	ld	a0,72(a0)
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	19a080e7          	jalr	410(ra) # 80001f30 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002d9e:	70a2                	ld	ra,40(sp)
    80002da0:	7402                	ld	s0,32(sp)
    80002da2:	64e2                	ld	s1,24(sp)
    80002da4:	6942                	ld	s2,16(sp)
    80002da6:	69a2                	ld	s3,8(sp)
    80002da8:	6a02                	ld	s4,0(sp)
    80002daa:	6145                	add	sp,sp,48
    80002dac:	8082                	ret
    memmove((char *)dst, src, len);
    80002dae:	000a061b          	sext.w	a2,s4
    80002db2:	85ce                	mv	a1,s3
    80002db4:	854a                	mv	a0,s2
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	262080e7          	jalr	610(ra) # 80001018 <memmove>
    return 0;
    80002dbe:	8526                	mv	a0,s1
    80002dc0:	bff9                	j	80002d9e <either_copyout+0x32>

0000000080002dc2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002dc2:	7179                	add	sp,sp,-48
    80002dc4:	f406                	sd	ra,40(sp)
    80002dc6:	f022                	sd	s0,32(sp)
    80002dc8:	ec26                	sd	s1,24(sp)
    80002dca:	e84a                	sd	s2,16(sp)
    80002dcc:	e44e                	sd	s3,8(sp)
    80002dce:	e052                	sd	s4,0(sp)
    80002dd0:	1800                	add	s0,sp,48
    80002dd2:	892a                	mv	s2,a0
    80002dd4:	84ae                	mv	s1,a1
    80002dd6:	89b2                	mv	s3,a2
    80002dd8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	38a080e7          	jalr	906(ra) # 80002164 <myproc>
  if(user_src){
    80002de2:	c08d                	beqz	s1,80002e04 <either_copyin+0x42>
    return copyin(p->pgtbl, dst, src, len);
    80002de4:	86d2                	mv	a3,s4
    80002de6:	864e                	mv	a2,s3
    80002de8:	85ca                	mv	a1,s2
    80002dea:	6528                	ld	a0,72(a0)
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	1d6080e7          	jalr	470(ra) # 80001fc2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002df4:	70a2                	ld	ra,40(sp)
    80002df6:	7402                	ld	s0,32(sp)
    80002df8:	64e2                	ld	s1,24(sp)
    80002dfa:	6942                	ld	s2,16(sp)
    80002dfc:	69a2                	ld	s3,8(sp)
    80002dfe:	6a02                	ld	s4,0(sp)
    80002e00:	6145                	add	sp,sp,48
    80002e02:	8082                	ret
    memmove(dst, (char*)src, len);
    80002e04:	000a061b          	sext.w	a2,s4
    80002e08:	85ce                	mv	a1,s3
    80002e0a:	854a                	mv	a0,s2
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	20c080e7          	jalr	524(ra) # 80001018 <memmove>
    return 0;
    80002e14:	8526                	mv	a0,s1
    80002e16:	bff9                	j	80002df4 <either_copyin+0x32>

0000000080002e18 <proc_pagetable>:
// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
    80002e18:	1101                	add	sp,sp,-32
    80002e1a:	ec06                	sd	ra,24(sp)
    80002e1c:	e822                	sd	s0,16(sp)
    80002e1e:	e426                	sd	s1,8(sp)
    80002e20:	e04a                	sd	s2,0(sp)
    80002e22:	1000                	add	s0,sp,32
    80002e24:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    80002e26:	fffff097          	auipc	ra,0xfffff
    80002e2a:	c70080e7          	jalr	-912(ra) # 80001a96 <uvmcreate>
    80002e2e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002e30:	c121                	beqz	a0,80002e70 <proc_pagetable+0x58>

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002e32:	4729                	li	a4,10
    80002e34:	00005697          	auipc	a3,0x5
    80002e38:	1cc68693          	add	a3,a3,460 # 80008000 <_trampoline>
    80002e3c:	6605                	lui	a2,0x1
    80002e3e:	040005b7          	lui	a1,0x4000
    80002e42:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80002e44:	05b2                	sll	a1,a1,0xc
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	848080e7          	jalr	-1976(ra) # 8000168e <mappages>
    80002e4e:	02054863          	bltz	a0,80002e7e <proc_pagetable+0x66>
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002e52:	4719                	li	a4,6
    80002e54:	05893683          	ld	a3,88(s2)
    80002e58:	6605                	lui	a2,0x1
    80002e5a:	020005b7          	lui	a1,0x2000
    80002e5e:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80002e60:	05b6                	sll	a1,a1,0xd
    80002e62:	8526                	mv	a0,s1
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	82a080e7          	jalr	-2006(ra) # 8000168e <mappages>
    80002e6c:	02054163          	bltz	a0,80002e8e <proc_pagetable+0x76>
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
    80002e70:	8526                	mv	a0,s1
    80002e72:	60e2                	ld	ra,24(sp)
    80002e74:	6442                	ld	s0,16(sp)
    80002e76:	64a2                	ld	s1,8(sp)
    80002e78:	6902                	ld	s2,0(sp)
    80002e7a:	6105                	add	sp,sp,32
    80002e7c:	8082                	ret
    uvmfree(pagetable, 0);
    80002e7e:	4581                	li	a1,0
    80002e80:	8526                	mv	a0,s1
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	074080e7          	jalr	116(ra) # 80001ef6 <uvmfree>
    return 0;
    80002e8a:	4481                	li	s1,0
    80002e8c:	b7d5                	j	80002e70 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002e8e:	4681                	li	a3,0
    80002e90:	4605                	li	a2,1
    80002e92:	040005b7          	lui	a1,0x4000
    80002e96:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80002e98:	05b2                	sll	a1,a1,0xc
    80002e9a:	8526                	mv	a0,s1
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	c9e080e7          	jalr	-866(ra) # 80001b3a <uvmunmap>
    uvmfree(pagetable, 0);
    80002ea4:	4581                	li	a1,0
    80002ea6:	8526                	mv	a0,s1
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	04e080e7          	jalr	78(ra) # 80001ef6 <uvmfree>
    return 0;
    80002eb0:	4481                	li	s1,0
    80002eb2:	bf7d                	j	80002e70 <proc_pagetable+0x58>

0000000080002eb4 <initsleeplock>:
#include "proc-h/proc.h"
#include "proc-h/cpu.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80002eb4:	1101                	add	sp,sp,-32
    80002eb6:	ec06                	sd	ra,24(sp)
    80002eb8:	e822                	sd	s0,16(sp)
    80002eba:	e426                	sd	s1,8(sp)
    80002ebc:	e04a                	sd	s2,0(sp)
    80002ebe:	1000                	add	s0,sp,32
    80002ec0:	84aa                	mv	s1,a0
    80002ec2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80002ec4:	00006597          	auipc	a1,0x6
    80002ec8:	6bc58593          	add	a1,a1,1724 # 80009580 <digits+0x390>
    80002ecc:	0521                	add	a0,a0,8
    80002ece:	00000097          	auipc	ra,0x0
    80002ed2:	110080e7          	jalr	272(ra) # 80002fde <initlock>
  lk->name = name;
    80002ed6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80002eda:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80002ede:	0204a423          	sw	zero,40(s1)
}
    80002ee2:	60e2                	ld	ra,24(sp)
    80002ee4:	6442                	ld	s0,16(sp)
    80002ee6:	64a2                	ld	s1,8(sp)
    80002ee8:	6902                	ld	s2,0(sp)
    80002eea:	6105                	add	sp,sp,32
    80002eec:	8082                	ret

0000000080002eee <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80002eee:	1101                	add	sp,sp,-32
    80002ef0:	ec06                	sd	ra,24(sp)
    80002ef2:	e822                	sd	s0,16(sp)
    80002ef4:	e426                	sd	s1,8(sp)
    80002ef6:	e04a                	sd	s2,0(sp)
    80002ef8:	1000                	add	s0,sp,32
    80002efa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80002efc:	00850913          	add	s2,a0,8
    80002f00:	854a                	mv	a0,s2
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	16c080e7          	jalr	364(ra) # 8000306e <acquire>

  // printf("acquiresleep: trying to acquire lock %p\n", lk);


  while (lk->locked) {
    80002f0a:	409c                	lw	a5,0(s1)
    80002f0c:	cb89                	beqz	a5,80002f1e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80002f0e:	85ca                	mv	a1,s2
    80002f10:	8526                	mv	a0,s1
    80002f12:	00000097          	auipc	ra,0x0
    80002f16:	a0e080e7          	jalr	-1522(ra) # 80002920 <sleep>
  while (lk->locked) {
    80002f1a:	409c                	lw	a5,0(s1)
    80002f1c:	fbed                	bnez	a5,80002f0e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80002f1e:	4785                	li	a5,1
    80002f20:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	242080e7          	jalr	578(ra) # 80002164 <myproc>
    80002f2a:	411c                	lw	a5,0(a0)
    80002f2c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80002f2e:	854a                	mv	a0,s2
    80002f30:	00000097          	auipc	ra,0x0
    80002f34:	1f2080e7          	jalr	498(ra) # 80003122 <release>
}
    80002f38:	60e2                	ld	ra,24(sp)
    80002f3a:	6442                	ld	s0,16(sp)
    80002f3c:	64a2                	ld	s1,8(sp)
    80002f3e:	6902                	ld	s2,0(sp)
    80002f40:	6105                	add	sp,sp,32
    80002f42:	8082                	ret

0000000080002f44 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80002f44:	1101                	add	sp,sp,-32
    80002f46:	ec06                	sd	ra,24(sp)
    80002f48:	e822                	sd	s0,16(sp)
    80002f4a:	e426                	sd	s1,8(sp)
    80002f4c:	e04a                	sd	s2,0(sp)
    80002f4e:	1000                	add	s0,sp,32
    80002f50:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80002f52:	00850913          	add	s2,a0,8
    80002f56:	854a                	mv	a0,s2
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	116080e7          	jalr	278(ra) # 8000306e <acquire>
  lk->locked = 0;
    80002f60:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80002f64:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80002f68:	8526                	mv	a0,s1
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	a24080e7          	jalr	-1500(ra) # 8000298e <wakeup>
  release(&lk->lk);
    80002f72:	854a                	mv	a0,s2
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	1ae080e7          	jalr	430(ra) # 80003122 <release>
}
    80002f7c:	60e2                	ld	ra,24(sp)
    80002f7e:	6442                	ld	s0,16(sp)
    80002f80:	64a2                	ld	s1,8(sp)
    80002f82:	6902                	ld	s2,0(sp)
    80002f84:	6105                	add	sp,sp,32
    80002f86:	8082                	ret

0000000080002f88 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80002f88:	7179                	add	sp,sp,-48
    80002f8a:	f406                	sd	ra,40(sp)
    80002f8c:	f022                	sd	s0,32(sp)
    80002f8e:	ec26                	sd	s1,24(sp)
    80002f90:	e84a                	sd	s2,16(sp)
    80002f92:	e44e                	sd	s3,8(sp)
    80002f94:	1800                	add	s0,sp,48
    80002f96:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80002f98:	00850913          	add	s2,a0,8
    80002f9c:	854a                	mv	a0,s2
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	0d0080e7          	jalr	208(ra) # 8000306e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80002fa6:	409c                	lw	a5,0(s1)
    80002fa8:	ef99                	bnez	a5,80002fc6 <holdingsleep+0x3e>
    80002faa:	4481                	li	s1,0
  release(&lk->lk);
    80002fac:	854a                	mv	a0,s2
    80002fae:	00000097          	auipc	ra,0x0
    80002fb2:	174080e7          	jalr	372(ra) # 80003122 <release>
  return r;
}
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	70a2                	ld	ra,40(sp)
    80002fba:	7402                	ld	s0,32(sp)
    80002fbc:	64e2                	ld	s1,24(sp)
    80002fbe:	6942                	ld	s2,16(sp)
    80002fc0:	69a2                	ld	s3,8(sp)
    80002fc2:	6145                	add	sp,sp,48
    80002fc4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80002fc6:	0284a983          	lw	s3,40(s1)
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	19a080e7          	jalr	410(ra) # 80002164 <myproc>
    80002fd2:	4104                	lw	s1,0(a0)
    80002fd4:	413484b3          	sub	s1,s1,s3
    80002fd8:	0014b493          	seqz	s1,s1
    80002fdc:	bfc1                	j	80002fac <holdingsleep+0x24>

0000000080002fde <initlock>:
#include "proc-h/cpu.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80002fde:	1141                	add	sp,sp,-16
    80002fe0:	e422                	sd	s0,8(sp)
    80002fe2:	0800                	add	s0,sp,16
  lk->name = name;
    80002fe4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80002fe6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80002fea:	00053823          	sd	zero,16(a0)
}
    80002fee:	6422                	ld	s0,8(sp)
    80002ff0:	0141                	add	sp,sp,16
    80002ff2:	8082                	ret

0000000080002ff4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80002ff4:	411c                	lw	a5,0(a0)
    80002ff6:	e399                	bnez	a5,80002ffc <holding+0x8>
    80002ff8:	4501                	li	a0,0
  return r;
}
    80002ffa:	8082                	ret
{
    80002ffc:	1101                	add	sp,sp,-32
    80002ffe:	ec06                	sd	ra,24(sp)
    80003000:	e822                	sd	s0,16(sp)
    80003002:	e426                	sd	s1,8(sp)
    80003004:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80003006:	6904                	ld	s1,16(a0)
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	140080e7          	jalr	320(ra) # 80002148 <mycpu>
    80003010:	40a48533          	sub	a0,s1,a0
    80003014:	00153513          	seqz	a0,a0
}
    80003018:	60e2                	ld	ra,24(sp)
    8000301a:	6442                	ld	s0,16(sp)
    8000301c:	64a2                	ld	s1,8(sp)
    8000301e:	6105                	add	sp,sp,32
    80003020:	8082                	ret

0000000080003022 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80003022:	1101                	add	sp,sp,-32
    80003024:	ec06                	sd	ra,24(sp)
    80003026:	e822                	sd	s0,16(sp)
    80003028:	e426                	sd	s1,8(sp)
    8000302a:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000302c:	100024f3          	csrr	s1,sstatus
    80003030:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003034:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003036:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	10e080e7          	jalr	270(ra) # 80002148 <mycpu>
    80003042:	411c                	lw	a5,0(a0)
    80003044:	cf89                	beqz	a5,8000305e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	102080e7          	jalr	258(ra) # 80002148 <mycpu>
    8000304e:	411c                	lw	a5,0(a0)
    80003050:	2785                	addw	a5,a5,1
    80003052:	c11c                	sw	a5,0(a0)
}
    80003054:	60e2                	ld	ra,24(sp)
    80003056:	6442                	ld	s0,16(sp)
    80003058:	64a2                	ld	s1,8(sp)
    8000305a:	6105                	add	sp,sp,32
    8000305c:	8082                	ret
    mycpu()->intena = old;
    8000305e:	fffff097          	auipc	ra,0xfffff
    80003062:	0ea080e7          	jalr	234(ra) # 80002148 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80003066:	8085                	srl	s1,s1,0x1
    80003068:	8885                	and	s1,s1,1
    8000306a:	c144                	sw	s1,4(a0)
    8000306c:	bfe9                	j	80003046 <push_off+0x24>

000000008000306e <acquire>:
{
    8000306e:	1101                	add	sp,sp,-32
    80003070:	ec06                	sd	ra,24(sp)
    80003072:	e822                	sd	s0,16(sp)
    80003074:	e426                	sd	s1,8(sp)
    80003076:	1000                	add	s0,sp,32
    80003078:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    8000307a:	00000097          	auipc	ra,0x0
    8000307e:	fa8080e7          	jalr	-88(ra) # 80003022 <push_off>
  if(holding(lk))
    80003082:	8526                	mv	a0,s1
    80003084:	00000097          	auipc	ra,0x0
    80003088:	f70080e7          	jalr	-144(ra) # 80002ff4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    8000308c:	4705                	li	a4,1
  if(holding(lk))
    8000308e:	e115                	bnez	a0,800030b2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80003090:	87ba                	mv	a5,a4
    80003092:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80003096:	2781                	sext.w	a5,a5
    80003098:	ffe5                	bnez	a5,80003090 <acquire+0x22>
  __sync_synchronize();
    8000309a:	0ff0000f          	fence
  lk->cpu = mycpu();
    8000309e:	fffff097          	auipc	ra,0xfffff
    800030a2:	0aa080e7          	jalr	170(ra) # 80002148 <mycpu>
    800030a6:	e888                	sd	a0,16(s1)
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6105                	add	sp,sp,32
    800030b0:	8082                	ret
    panic("acquire");
    800030b2:	00006517          	auipc	a0,0x6
    800030b6:	4de50513          	add	a0,a0,1246 # 80009590 <digits+0x3a0>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	14a080e7          	jalr	330(ra) # 80001204 <panic>

00000000800030c2 <pop_off>:

void
pop_off(void)
{
    800030c2:	1141                	add	sp,sp,-16
    800030c4:	e406                	sd	ra,8(sp)
    800030c6:	e022                	sd	s0,0(sp)
    800030c8:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	07e080e7          	jalr	126(ra) # 80002148 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030d2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030d6:	8b89                	and	a5,a5,2
  if(intr_get())
    800030d8:	e78d                	bnez	a5,80003102 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    800030da:	411c                	lw	a5,0(a0)
    800030dc:	02f05b63          	blez	a5,80003112 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    800030e0:	37fd                	addw	a5,a5,-1
    800030e2:	0007871b          	sext.w	a4,a5
    800030e6:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    800030e8:	eb09                	bnez	a4,800030fa <pop_off+0x38>
    800030ea:	415c                	lw	a5,4(a0)
    800030ec:	c799                	beqz	a5,800030fa <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030f2:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030f6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    800030fa:	60a2                	ld	ra,8(sp)
    800030fc:	6402                	ld	s0,0(sp)
    800030fe:	0141                	add	sp,sp,16
    80003100:	8082                	ret
    panic("pop_off - interruptible");
    80003102:	00006517          	auipc	a0,0x6
    80003106:	49650513          	add	a0,a0,1174 # 80009598 <digits+0x3a8>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	0fa080e7          	jalr	250(ra) # 80001204 <panic>
    panic("pop_off");
    80003112:	00006517          	auipc	a0,0x6
    80003116:	49e50513          	add	a0,a0,1182 # 800095b0 <digits+0x3c0>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	0ea080e7          	jalr	234(ra) # 80001204 <panic>

0000000080003122 <release>:
{
    80003122:	1101                	add	sp,sp,-32
    80003124:	ec06                	sd	ra,24(sp)
    80003126:	e822                	sd	s0,16(sp)
    80003128:	e426                	sd	s1,8(sp)
    8000312a:	e04a                	sd	s2,0(sp)
    8000312c:	1000                	add	s0,sp,32
    8000312e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80003130:	00000097          	auipc	ra,0x0
    80003134:	ec4080e7          	jalr	-316(ra) # 80002ff4 <holding>
    80003138:	c11d                	beqz	a0,8000315e <release+0x3c>
  lk->cpu = 0;
    8000313a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    8000313e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80003142:	0f50000f          	fence	iorw,ow
    80003146:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    8000314a:	00000097          	auipc	ra,0x0
    8000314e:	f78080e7          	jalr	-136(ra) # 800030c2 <pop_off>
}
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6902                	ld	s2,0(sp)
    8000315a:	6105                	add	sp,sp,32
    8000315c:	8082                	ret
    printf("release lock %s at %p, cpu%d\n", lk->name, lk, cpuid());
    8000315e:	0084b903          	ld	s2,8(s1)
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	fd6080e7          	jalr	-42(ra) # 80002138 <cpuid>
    8000316a:	86aa                	mv	a3,a0
    8000316c:	8626                	mv	a2,s1
    8000316e:	85ca                	mv	a1,s2
    80003170:	00006517          	auipc	a0,0x6
    80003174:	44850513          	add	a0,a0,1096 # 800095b8 <digits+0x3c8>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	0d6080e7          	jalr	214(ra) # 8000124e <printf>
    panic("release");
    80003180:	00006517          	auipc	a0,0x6
    80003184:	45850513          	add	a0,a0,1112 # 800095d8 <digits+0x3e8>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	07c080e7          	jalr	124(ra) # 80001204 <panic>

0000000080003190 <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    80003190:	1141                	add	sp,sp,-16
    80003192:	e422                	sd	s0,8(sp)
    80003194:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003196:	00004797          	auipc	a5,0x4
    8000319a:	0ca78793          	add	a5,a5,202 # 80007260 <kernelvec>
    8000319e:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    800031a2:	6422                	ld	s0,8(sp)
    800031a4:	0141                	add	sp,sp,16
    800031a6:	8082                	ret

00000000800031a8 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031a8:	142027f3          	csrr	a5,scause
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    800031ac:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800031ae:	0807df63          	bgez	a5,8000324c <devintr+0xa4>
{
    800031b2:	1101                	add	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    800031bc:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800031c0:	46a5                	li	a3,9
    800031c2:	00d70d63          	beq	a4,a3,800031dc <devintr+0x34>
  if(scause == 0x8000000000000001L){
    800031c6:	577d                	li	a4,-1
    800031c8:	177e                	sll	a4,a4,0x3f
    800031ca:	0705                	add	a4,a4,1
    return 0;  // 未识别的中断类型
    800031cc:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    800031ce:	04e78e63          	beq	a5,a4,8000322a <devintr+0x82>
  }
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	add	sp,sp,32
    800031da:	8082                	ret
    int irq = plic_claim();  // 获取中断请求号
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	848080e7          	jalr	-1976(ra) # 80000a24 <plic_claim>
    800031e4:	84aa                	mv	s1,a0
    switch(irq){
    800031e6:	4785                	li	a5,1
    800031e8:	02f50063          	beq	a0,a5,80003208 <devintr+0x60>
    800031ec:	47a9                	li	a5,10
    800031ee:	02f51263          	bne	a0,a5,80003212 <devintr+0x6a>
      uartintr();           // 处理串口中断
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	304080e7          	jalr	772(ra) # 800004f6 <uartintr>
      plic_complete(irq);
    800031fa:	8526                	mv	a0,s1
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	84c080e7          	jalr	-1972(ra) # 80000a48 <plic_complete>
    return 1;
    80003204:	4505                	li	a0,1
    80003206:	b7f1                	j	800031d2 <devintr+0x2a>
      virtio_disk_intr();   // 处理虚拟磁盘中断
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	d00080e7          	jalr	-768(ra) # 80000f08 <virtio_disk_intr>
    if(irq)
    80003210:	b7ed                	j	800031fa <devintr+0x52>
    return 1;
    80003212:	4505                	li	a0,1
      if(irq){
    80003214:	dcdd                	beqz	s1,800031d2 <devintr+0x2a>
        printf("unexpected interrupt irq=%d\n", irq);
    80003216:	85a6                	mv	a1,s1
    80003218:	00006517          	auipc	a0,0x6
    8000321c:	3c850513          	add	a0,a0,968 # 800095e0 <digits+0x3f0>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	02e080e7          	jalr	46(ra) # 8000124e <printf>
    if(irq)
    80003228:	bfc9                	j	800031fa <devintr+0x52>
    if(cpuid() == 0){
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	f0e080e7          	jalr	-242(ra) # 80002138 <cpuid>
    80003232:	c901                	beqz	a0,80003242 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003234:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003238:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000323a:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    8000323e:	4509                	li	a0,2
    80003240:	bf49                	j	800031d2 <devintr+0x2a>
      timer_update();
    80003242:	ffffd097          	auipc	ra,0xffffd
    80003246:	034080e7          	jalr	52(ra) # 80000276 <timer_update>
    8000324a:	b7ed                	j	80003234 <devintr+0x8c>
}
    8000324c:	8082                	ret

000000008000324e <kerneltrap>:
{
    8000324e:	7179                	add	sp,sp,-48
    80003250:	f406                	sd	ra,40(sp)
    80003252:	f022                	sd	s0,32(sp)
    80003254:	ec26                	sd	s1,24(sp)
    80003256:	e84a                	sd	s2,16(sp)
    80003258:	e44e                	sd	s3,8(sp)
    8000325a:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000325c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003260:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003264:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003268:	1004f793          	and	a5,s1,256
    8000326c:	cb85                	beqz	a5,8000329c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000326e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003272:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80003274:	ef85                	bnez	a5,800032ac <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	f32080e7          	jalr	-206(ra) # 800031a8 <devintr>
    8000327e:	cd1d                	beqz	a0,800032bc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003280:	4789                	li	a5,2
    80003282:	08f50763          	beq	a0,a5,80003310 <kerneltrap+0xc2>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003286:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000328a:	10049073          	csrw	sstatus,s1
}
    8000328e:	70a2                	ld	ra,40(sp)
    80003290:	7402                	ld	s0,32(sp)
    80003292:	64e2                	ld	s1,24(sp)
    80003294:	6942                	ld	s2,16(sp)
    80003296:	69a2                	ld	s3,8(sp)
    80003298:	6145                	add	sp,sp,48
    8000329a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000329c:	00006517          	auipc	a0,0x6
    800032a0:	36450513          	add	a0,a0,868 # 80009600 <digits+0x410>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	f60080e7          	jalr	-160(ra) # 80001204 <panic>
    panic("kerneltrap: interrupts enabled");
    800032ac:	00006517          	auipc	a0,0x6
    800032b0:	37c50513          	add	a0,a0,892 # 80009628 <digits+0x438>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	f50080e7          	jalr	-176(ra) # 80001204 <panic>
    printf("scause %p\n", scause);
    800032bc:	85ce                	mv	a1,s3
    800032be:	00006517          	auipc	a0,0x6
    800032c2:	38a50513          	add	a0,a0,906 # 80009648 <digits+0x458>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	f88080e7          	jalr	-120(ra) # 8000124e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032ce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032d2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032d6:	00006517          	auipc	a0,0x6
    800032da:	38250513          	add	a0,a0,898 # 80009658 <digits+0x468>
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	f70080e7          	jalr	-144(ra) # 8000124e <printf>
    printf("current process: %p\n", myproc());
    800032e6:	fffff097          	auipc	ra,0xfffff
    800032ea:	e7e080e7          	jalr	-386(ra) # 80002164 <myproc>
    800032ee:	85aa                	mv	a1,a0
    800032f0:	00006517          	auipc	a0,0x6
    800032f4:	38050513          	add	a0,a0,896 # 80009670 <digits+0x480>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	f56080e7          	jalr	-170(ra) # 8000124e <printf>
    panic("kerneltrap");
    80003300:	00006517          	auipc	a0,0x6
    80003304:	38850513          	add	a0,a0,904 # 80009688 <digits+0x498>
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	efc080e7          	jalr	-260(ra) # 80001204 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003310:	fffff097          	auipc	ra,0xfffff
    80003314:	e54080e7          	jalr	-428(ra) # 80002164 <myproc>
    80003318:	d53d                	beqz	a0,80003286 <kerneltrap+0x38>
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	e4a080e7          	jalr	-438(ra) # 80002164 <myproc>
    80003322:	5118                	lw	a4,32(a0)
    80003324:	4791                	li	a5,4
    80003326:	f6f710e3          	bne	a4,a5,80003286 <kerneltrap+0x38>
     yield();
    8000332a:	00000097          	auipc	ra,0x0
    8000332e:	154080e7          	jalr	340(ra) # 8000347e <yield>
    80003332:	bf91                	j	80003286 <kerneltrap+0x38>

0000000080003334 <scheduler>:
//  - 选择一个进程运行
//  - 通过swtch切换到该进程开始运行
//  - 最终该进程通过swtch将控制权交回给调度器
void
scheduler(void)
{
    80003334:	715d                	add	sp,sp,-80
    80003336:	e486                	sd	ra,72(sp)
    80003338:	e0a2                	sd	s0,64(sp)
    8000333a:	fc26                	sd	s1,56(sp)
    8000333c:	f84a                	sd	s2,48(sp)
    8000333e:	f44e                	sd	s3,40(sp)
    80003340:	f052                	sd	s4,32(sp)
    80003342:	ec56                	sd	s5,24(sp)
    80003344:	e85a                	sd	s6,16(sp)
    80003346:	e45e                	sd	s7,8(sp)
    80003348:	0880                	add	s0,sp,80
  struct proc *p;
  struct cpu *c = mycpu();
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	dfe080e7          	jalr	-514(ra) # 80002148 <mycpu>
    80003352:	8aaa                	mv	s5,a0
  
  c->proc = 0;
    80003354:	00053423          	sd	zero,8(a0)
    intr_on();

    // 遍历进程表，寻找可运行的进程
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
    80003358:	4a0d                	li	s4,3
        // printf(" running process %d\n", p->pid);
        // 切换到选中的进程。进程有责任释放其锁
        // 然后在跳回调度器之前重新获取锁
        p->state = RUNNING;
    8000335a:	4b91                	li	s7,4
        c->proc = p;
        
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    8000335c:	01050b13          	add	s6,a0,16
    for(p = proc; p < &proc[NPROC]; p++) {
    80003360:	00015997          	auipc	s3,0x15
    80003364:	cb898993          	add	s3,s3,-840 # 80018018 <wait_lock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003368:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000336c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003370:	10079073          	csrw	sstatus,a5
    80003374:	0000f497          	auipc	s1,0xf
    80003378:	2a448493          	add	s1,s1,676 # 80012618 <proc>
    8000337c:	a811                	j	80003390 <scheduler+0x5c>
        // 进程暂时运行完毕
        // 它应该在返回之前改变了p->state
        c->proc = 0;
        // printf(" process %d finished running\n", p->pid);
      }
      release(&p->lock);
    8000337e:	854a                	mv	a0,s2
    80003380:	00000097          	auipc	ra,0x0
    80003384:	da2080e7          	jalr	-606(ra) # 80003122 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80003388:	16848493          	add	s1,s1,360
    8000338c:	fd348ee3          	beq	s1,s3,80003368 <scheduler+0x34>
      acquire(&p->lock);
    80003390:	00848913          	add	s2,s1,8
    80003394:	854a                	mv	a0,s2
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	cd8080e7          	jalr	-808(ra) # 8000306e <acquire>
      if(p->state == RUNNABLE) {
    8000339e:	509c                	lw	a5,32(s1)
    800033a0:	fd479fe3          	bne	a5,s4,8000337e <scheduler+0x4a>
        p->state = RUNNING;
    800033a4:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800033a8:	009ab423          	sd	s1,8(s5)
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    800033ac:	0f848593          	add	a1,s1,248
    800033b0:	855a                	mv	a0,s6
    800033b2:	00004097          	auipc	ra,0x4
    800033b6:	e42080e7          	jalr	-446(ra) # 800071f4 <initcode_end>
        c->proc = 0;
    800033ba:	000ab423          	sd	zero,8(s5)
    800033be:	b7c1                	j	8000337e <scheduler+0x4a>

00000000800033c0 <sched>:
// 并且已经改变了proc->state。
// 因为intena是这个内核线程的属性，而不是这个CPU的属性。
// 因此此处需要保存和恢复intena
void
sched(void)
{
    800033c0:	1101                	add	sp,sp,-32
    800033c2:	ec06                	sd	ra,24(sp)
    800033c4:	e822                	sd	s0,16(sp)
    800033c6:	e426                	sd	s1,8(sp)
    800033c8:	e04a                	sd	s2,0(sp)
    800033ca:	1000                	add	s0,sp,32
  int intena;
  struct proc *p = myproc();
    800033cc:	fffff097          	auipc	ra,0xfffff
    800033d0:	d98080e7          	jalr	-616(ra) # 80002164 <myproc>
    800033d4:	84aa                	mv	s1,a0

  if(!holding(&p->lock))
    800033d6:	0521                	add	a0,a0,8
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	c1c080e7          	jalr	-996(ra) # 80002ff4 <holding>
    800033e0:	cd39                	beqz	a0,8000343e <sched+0x7e>
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    800033e2:	fffff097          	auipc	ra,0xfffff
    800033e6:	d66080e7          	jalr	-666(ra) # 80002148 <mycpu>
    800033ea:	4118                	lw	a4,0(a0)
    800033ec:	4785                	li	a5,1
    800033ee:	06f71063          	bne	a4,a5,8000344e <sched+0x8e>
    panic("sched locks");
  if(p->state == RUNNING)
    800033f2:	5098                	lw	a4,32(s1)
    800033f4:	4791                	li	a5,4
    800033f6:	06f70463          	beq	a4,a5,8000345e <sched+0x9e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033fa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800033fe:	8b89                	and	a5,a5,2
    panic("sched running");
  if(intr_get())
    80003400:	e7bd                	bnez	a5,8000346e <sched+0xae>
    panic("sched interruptible");

  intena = mycpu()->intena;
    80003402:	fffff097          	auipc	ra,0xfffff
    80003406:	d46080e7          	jalr	-698(ra) # 80002148 <mycpu>
    8000340a:	00452903          	lw	s2,4(a0)
  swtch(&p->ctx, &mycpu()->context);  // 切换到调度器上下文
    8000340e:	fffff097          	auipc	ra,0xfffff
    80003412:	d3a080e7          	jalr	-710(ra) # 80002148 <mycpu>
    80003416:	01050593          	add	a1,a0,16
    8000341a:	0f848513          	add	a0,s1,248
    8000341e:	00004097          	auipc	ra,0x4
    80003422:	dd6080e7          	jalr	-554(ra) # 800071f4 <initcode_end>
  mycpu()->intena = intena;
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	d22080e7          	jalr	-734(ra) # 80002148 <mycpu>
    8000342e:	01252223          	sw	s2,4(a0)
}
    80003432:	60e2                	ld	ra,24(sp)
    80003434:	6442                	ld	s0,16(sp)
    80003436:	64a2                	ld	s1,8(sp)
    80003438:	6902                	ld	s2,0(sp)
    8000343a:	6105                	add	sp,sp,32
    8000343c:	8082                	ret
    panic("sched p->lock");
    8000343e:	00006517          	auipc	a0,0x6
    80003442:	25a50513          	add	a0,a0,602 # 80009698 <digits+0x4a8>
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	dbe080e7          	jalr	-578(ra) # 80001204 <panic>
    panic("sched locks");
    8000344e:	00006517          	auipc	a0,0x6
    80003452:	25a50513          	add	a0,a0,602 # 800096a8 <digits+0x4b8>
    80003456:	ffffe097          	auipc	ra,0xffffe
    8000345a:	dae080e7          	jalr	-594(ra) # 80001204 <panic>
    panic("sched running");
    8000345e:	00006517          	auipc	a0,0x6
    80003462:	25a50513          	add	a0,a0,602 # 800096b8 <digits+0x4c8>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	d9e080e7          	jalr	-610(ra) # 80001204 <panic>
    panic("sched interruptible");
    8000346e:	00006517          	auipc	a0,0x6
    80003472:	25a50513          	add	a0,a0,602 # 800096c8 <digits+0x4d8>
    80003476:	ffffe097          	auipc	ra,0xffffe
    8000347a:	d8e080e7          	jalr	-626(ra) # 80001204 <panic>

000000008000347e <yield>:

// 用于进程放弃CPU, 重新进入调度
void
yield(void)
{
    8000347e:	1101                	add	sp,sp,-32
    80003480:	ec06                	sd	ra,24(sp)
    80003482:	e822                	sd	s0,16(sp)
    80003484:	e426                	sd	s1,8(sp)
    80003486:	e04a                	sd	s2,0(sp)
    80003488:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    8000348a:	fffff097          	auipc	ra,0xfffff
    8000348e:	cda080e7          	jalr	-806(ra) # 80002164 <myproc>
    80003492:	84aa                	mv	s1,a0
  acquire(&p->lock);     // 获取进程锁
    80003494:	00850913          	add	s2,a0,8
    80003498:	854a                	mv	a0,s2
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	bd4080e7          	jalr	-1068(ra) # 8000306e <acquire>
  p->state = RUNNABLE;   // 将进程状态设为可运行
    800034a2:	478d                	li	a5,3
    800034a4:	d09c                	sw	a5,32(s1)
  sched();               // 调用sched()切换到调度器
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	f1a080e7          	jalr	-230(ra) # 800033c0 <sched>
  release(&p->lock);     // 释放进程锁
    800034ae:	854a                	mv	a0,s2
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	c72080e7          	jalr	-910(ra) # 80003122 <release>
    800034b8:	60e2                	ld	ra,24(sp)
    800034ba:	6442                	ld	s0,16(sp)
    800034bc:	64a2                	ld	s1,8(sp)
    800034be:	6902                	ld	s2,0(sp)
    800034c0:	6105                	add	sp,sp,32
    800034c2:	8082                	ret

00000000800034c4 <trap_user_return>:
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
    800034c4:	1141                	add	sp,sp,-16
    800034c6:	e406                	sd	ra,8(sp)
    800034c8:	e022                	sd	s0,0(sp)
    800034ca:	0800                	add	s0,sp,16
  //printf("trap_user_return\n");
  struct proc *p = myproc();
    800034cc:	fffff097          	auipc	ra,0xfffff
    800034d0:	c98080e7          	jalr	-872(ra) # 80002164 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800034d8:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034da:	10079073          	csrw	sstatus,a5
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800034de:	00005697          	auipc	a3,0x5
    800034e2:	b2268693          	add	a3,a3,-1246 # 80008000 <_trampoline>
    800034e6:	00005717          	auipc	a4,0x5
    800034ea:	b1a70713          	add	a4,a4,-1254 # 80008000 <_trampoline>
    800034ee:	8f15                	sub	a4,a4,a3
    800034f0:	040007b7          	lui	a5,0x4000
    800034f4:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800034f6:	07b2                	sll	a5,a5,0xc
    800034f8:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800034fa:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
    800034fe:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003500:	18002673          	csrr	a2,satp
    80003504:	e310                	sd	a2,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
    80003506:	6d30                	ld	a2,88(a0)
    80003508:	7978                	ld	a4,240(a0)
    8000350a:	6585                	lui	a1,0x1
    8000350c:	972e                	add	a4,a4,a1
    8000350e:	e618                	sd	a4,8(a2)
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
    80003510:	6d38                	ld	a4,88(a0)
    80003512:	00000617          	auipc	a2,0x0
    80003516:	04860613          	add	a2,a2,72 # 8000355a <trap_user_handler>
    8000351a:	eb10                	sd	a2,16(a4)
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid
    8000351c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000351e:	8612                	mv	a2,tp
    80003520:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003522:	10002773          	csrr	a4,sstatus
  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
    80003526:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
    8000352a:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000352e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);
    80003532:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003534:	6f18                	ld	a4,24(a4)
    80003536:	14171073          	csrw	sepc,a4

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);
    8000353a:	6528                	ld	a0,72(a0)
    8000353c:	8131                	srl	a0,a0,0xc

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000353e:	00005717          	auipc	a4,0x5
    80003542:	b5e70713          	add	a4,a4,-1186 # 8000809c <userret>
    80003546:	8f15                	sub	a4,a4,a3
    80003548:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000354a:	577d                	li	a4,-1
    8000354c:	177e                	sll	a4,a4,0x3f
    8000354e:	8d59                	or	a0,a0,a4
    80003550:	9782                	jalr	a5
    80003552:	60a2                	ld	ra,8(sp)
    80003554:	6402                	ld	s0,0(sp)
    80003556:	0141                	add	sp,sp,16
    80003558:	8082                	ret

000000008000355a <trap_user_handler>:
{
    8000355a:	7139                	add	sp,sp,-64
    8000355c:	fc06                	sd	ra,56(sp)
    8000355e:	f822                	sd	s0,48(sp)
    80003560:	f426                	sd	s1,40(sp)
    80003562:	f04a                	sd	s2,32(sp)
    80003564:	ec4e                	sd	s3,24(sp)
    80003566:	e852                	sd	s4,16(sp)
    80003568:	e456                	sd	s5,8(sp)
    8000356a:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000356c:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003570:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003574:	14202a73          	csrr	s4,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003578:	14302af3          	csrr	s5,stval
    proc_t* p = myproc();
    8000357c:	fffff097          	auipc	ra,0xfffff
    80003580:	be8080e7          	jalr	-1048(ra) # 80002164 <myproc>
    if(sstatus & SSTATUS_SPP)
    80003584:	10097913          	and	s2,s2,256
    80003588:	04091b63          	bnez	s2,800035de <trap_user_handler+0x84>
    8000358c:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000358e:	00004797          	auipc	a5,0x4
    80003592:	cd278793          	add	a5,a5,-814 # 80007260 <kernelvec>
    80003596:	10579073          	csrw	stvec,a5
  p->tf->epc = sepc;
    8000359a:	6d3c                	ld	a5,88(a0)
    8000359c:	0137bc23          	sd	s3,24(a5)
  if(scause == 8){
    800035a0:	47a1                	li	a5,8
    800035a2:	04fa0663          	beq	s4,a5,800035ee <trap_user_handler+0x94>
  } else if((which_dev = devintr()) != 0){
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	c02080e7          	jalr	-1022(ra) # 800031a8 <devintr>
    800035ae:	892a                	mv	s2,a0
    800035b0:	c549                	beqz	a0,8000363a <trap_user_handler+0xe0>
  if(killed(p))
    800035b2:	8526                	mv	a0,s1
    800035b4:	fffff097          	auipc	ra,0xfffff
    800035b8:	508080e7          	jalr	1288(ra) # 80002abc <killed>
    800035bc:	e13d                	bnez	a0,80003622 <trap_user_handler+0xc8>
  if(which_dev == 2)
    800035be:	4789                	li	a5,2
    800035c0:	0af90963          	beq	s2,a5,80003672 <trap_user_handler+0x118>
  trap_user_return();
    800035c4:	00000097          	auipc	ra,0x0
    800035c8:	f00080e7          	jalr	-256(ra) # 800034c4 <trap_user_return>
}
    800035cc:	70e2                	ld	ra,56(sp)
    800035ce:	7442                	ld	s0,48(sp)
    800035d0:	74a2                	ld	s1,40(sp)
    800035d2:	7902                	ld	s2,32(sp)
    800035d4:	69e2                	ld	s3,24(sp)
    800035d6:	6a42                	ld	s4,16(sp)
    800035d8:	6aa2                	ld	s5,8(sp)
    800035da:	6121                	add	sp,sp,64
    800035dc:	8082                	ret
        panic("trap_user_handler: not from u-mode");
    800035de:	00006517          	auipc	a0,0x6
    800035e2:	10250513          	add	a0,a0,258 # 800096e0 <digits+0x4f0>
    800035e6:	ffffe097          	auipc	ra,0xffffe
    800035ea:	c1e080e7          	jalr	-994(ra) # 80001204 <panic>
    if(killed(p))
    800035ee:	fffff097          	auipc	ra,0xfffff
    800035f2:	4ce080e7          	jalr	1230(ra) # 80002abc <killed>
    800035f6:	ed05                	bnez	a0,8000362e <trap_user_handler+0xd4>
    p->tf->epc += 4;
    800035f8:	6cb8                	ld	a4,88(s1)
    800035fa:	6f1c                	ld	a5,24(a4)
    800035fc:	0791                	add	a5,a5,4
    800035fe:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003600:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003604:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003608:	10079073          	csrw	sstatus,a5
    syscall();
    8000360c:	00000097          	auipc	ra,0x0
    80003610:	0d8080e7          	jalr	216(ra) # 800036e4 <syscall>
  if(killed(p))
    80003614:	8526                	mv	a0,s1
    80003616:	fffff097          	auipc	ra,0xfffff
    8000361a:	4a6080e7          	jalr	1190(ra) # 80002abc <killed>
    8000361e:	d15d                	beqz	a0,800035c4 <trap_user_handler+0x6a>
    int which_dev = 0;  // 用于标识设备中断类型
    80003620:	4901                	li	s2,0
    exit(-1);
    80003622:	557d                	li	a0,-1
    80003624:	fffff097          	auipc	ra,0xfffff
    80003628:	670080e7          	jalr	1648(ra) # 80002c94 <exit>
    8000362c:	bf49                	j	800035be <trap_user_handler+0x64>
      exit(-1);
    8000362e:	557d                	li	a0,-1
    80003630:	fffff097          	auipc	ra,0xfffff
    80003634:	664080e7          	jalr	1636(ra) # 80002c94 <exit>
    80003638:	b7c1                	j	800035f8 <trap_user_handler+0x9e>
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    8000363a:	4090                	lw	a2,0(s1)
    8000363c:	85d2                	mv	a1,s4
    8000363e:	00006517          	auipc	a0,0x6
    80003642:	0ca50513          	add	a0,a0,202 # 80009708 <digits+0x518>
    80003646:	ffffe097          	auipc	ra,0xffffe
    8000364a:	c08080e7          	jalr	-1016(ra) # 8000124e <printf>
    printf("            sepc=%p stval=%p\n", sepc, stval);
    8000364e:	8656                	mv	a2,s5
    80003650:	85ce                	mv	a1,s3
    80003652:	00006517          	auipc	a0,0x6
    80003656:	0e650513          	add	a0,a0,230 # 80009738 <digits+0x548>
    8000365a:	ffffe097          	auipc	ra,0xffffe
    8000365e:	bf4080e7          	jalr	-1036(ra) # 8000124e <printf>
    panic("usertrap");
    80003662:	00006517          	auipc	a0,0x6
    80003666:	0f650513          	add	a0,a0,246 # 80009758 <digits+0x568>
    8000366a:	ffffe097          	auipc	ra,0xffffe
    8000366e:	b9a080e7          	jalr	-1126(ra) # 80001204 <panic>
    yield();  // 让出 CPU，调度其他进程
    80003672:	00000097          	auipc	ra,0x0
    80003676:	e0c080e7          	jalr	-500(ra) # 8000347e <yield>
    8000367a:	b7a9                	j	800035c4 <trap_user_handler+0x6a>

000000008000367c <arg_raw>:
    第二种使用uvm_copyin 和 uvm_copyinstr 进行传递
*/

// 读取 n 号参数,它放在 an 寄存器中
static uint64 arg_raw(int n)
{   
    8000367c:	1101                	add	sp,sp,-32
    8000367e:	ec06                	sd	ra,24(sp)
    80003680:	e822                	sd	s0,16(sp)
    80003682:	e426                	sd	s1,8(sp)
    80003684:	1000                	add	s0,sp,32
    80003686:	84aa                	mv	s1,a0
    proc_t* proc = myproc();
    80003688:	fffff097          	auipc	ra,0xfffff
    8000368c:	adc080e7          	jalr	-1316(ra) # 80002164 <myproc>
    switch(n) {
    80003690:	4795                	li	a5,5
    80003692:	0497e163          	bltu	a5,s1,800036d4 <arg_raw+0x58>
    80003696:	048a                	sll	s1,s1,0x2
    80003698:	00006717          	auipc	a4,0x6
    8000369c:	12870713          	add	a4,a4,296 # 800097c0 <digits+0x5d0>
    800036a0:	94ba                	add	s1,s1,a4
    800036a2:	409c                	lw	a5,0(s1)
    800036a4:	97ba                	add	a5,a5,a4
    800036a6:	8782                	jr	a5
        case 0:
            return proc->tf->a0;
    800036a8:	6d3c                	ld	a5,88(a0)
    800036aa:	7ba8                	ld	a0,112(a5)
            return proc->tf->a5;
        default:
            panic("arg_raw: illegal arg num");
            return -1;
    }
}
    800036ac:	60e2                	ld	ra,24(sp)
    800036ae:	6442                	ld	s0,16(sp)
    800036b0:	64a2                	ld	s1,8(sp)
    800036b2:	6105                	add	sp,sp,32
    800036b4:	8082                	ret
            return proc->tf->a1;
    800036b6:	6d3c                	ld	a5,88(a0)
    800036b8:	7fa8                	ld	a0,120(a5)
    800036ba:	bfcd                	j	800036ac <arg_raw+0x30>
            return proc->tf->a2;
    800036bc:	6d3c                	ld	a5,88(a0)
    800036be:	63c8                	ld	a0,128(a5)
    800036c0:	b7f5                	j	800036ac <arg_raw+0x30>
            return proc->tf->a3;
    800036c2:	6d3c                	ld	a5,88(a0)
    800036c4:	67c8                	ld	a0,136(a5)
    800036c6:	b7dd                	j	800036ac <arg_raw+0x30>
            return proc->tf->a4;
    800036c8:	6d3c                	ld	a5,88(a0)
    800036ca:	6bc8                	ld	a0,144(a5)
    800036cc:	b7c5                	j	800036ac <arg_raw+0x30>
            return proc->tf->a5;
    800036ce:	6d3c                	ld	a5,88(a0)
    800036d0:	6fc8                	ld	a0,152(a5)
    800036d2:	bfe9                	j	800036ac <arg_raw+0x30>
            panic("arg_raw: illegal arg num");
    800036d4:	00006517          	auipc	a0,0x6
    800036d8:	09450513          	add	a0,a0,148 # 80009768 <digits+0x578>
    800036dc:	ffffe097          	auipc	ra,0xffffe
    800036e0:	b28080e7          	jalr	-1240(ra) # 80001204 <panic>

00000000800036e4 <syscall>:
{
    800036e4:	1101                	add	sp,sp,-32
    800036e6:	ec06                	sd	ra,24(sp)
    800036e8:	e822                	sd	s0,16(sp)
    800036ea:	e426                	sd	s1,8(sp)
    800036ec:	1000                	add	s0,sp,32
    struct proc *p = myproc();
    800036ee:	fffff097          	auipc	ra,0xfffff
    800036f2:	a76080e7          	jalr	-1418(ra) # 80002164 <myproc>
    800036f6:	84aa                	mv	s1,a0
    num = p->tf->a7;
    800036f8:	6d3c                	ld	a5,88(a0)
    800036fa:	0a87a603          	lw	a2,168(a5)
    if(num >= 0 && num < NELEM(syscalls) && syscalls[num]) {
    800036fe:	47fd                	li	a5,31
    80003700:	02c7ee63          	bltu	a5,a2,8000373c <syscall+0x58>
    80003704:	00361713          	sll	a4,a2,0x3
    80003708:	00006797          	auipc	a5,0x6
    8000370c:	0d078793          	add	a5,a5,208 # 800097d8 <syscalls>
    80003710:	97ba                	add	a5,a5,a4
    80003712:	639c                	ld	a5,0(a5)
    80003714:	c785                	beqz	a5,8000373c <syscall+0x58>
        uint64 ret = syscalls[num]();
    80003716:	9782                	jalr	a5
    80003718:	84aa                	mv	s1,a0
        p = myproc();
    8000371a:	fffff097          	auipc	ra,0xfffff
    8000371e:	a4a080e7          	jalr	-1462(ra) # 80002164 <myproc>
        if(p == 0 || p->tf == 0)
    80003722:	c509                	beqz	a0,8000372c <syscall+0x48>
    80003724:	6d3c                	ld	a5,88(a0)
    80003726:	c399                	beqz	a5,8000372c <syscall+0x48>
        p->tf->a0 = ret;
    80003728:	fba4                	sd	s1,112(a5)
    if(num >= 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000372a:	a02d                	j	80003754 <syscall+0x70>
            panic("syscall: no proc/tf");
    8000372c:	00006517          	auipc	a0,0x6
    80003730:	05c50513          	add	a0,a0,92 # 80009788 <digits+0x598>
    80003734:	ffffe097          	auipc	ra,0xffffe
    80003738:	ad0080e7          	jalr	-1328(ra) # 80001204 <panic>
        printf("pid %d: unknown sys call %d\n",
    8000373c:	408c                	lw	a1,0(s1)
    8000373e:	00006517          	auipc	a0,0x6
    80003742:	06250513          	add	a0,a0,98 # 800097a0 <digits+0x5b0>
    80003746:	ffffe097          	auipc	ra,0xffffe
    8000374a:	b08080e7          	jalr	-1272(ra) # 8000124e <printf>
        p->tf->a0 = -1;
    8000374e:	6cbc                	ld	a5,88(s1)
    80003750:	577d                	li	a4,-1
    80003752:	fbb8                	sd	a4,112(a5)
}
    80003754:	60e2                	ld	ra,24(sp)
    80003756:	6442                	ld	s0,16(sp)
    80003758:	64a2                	ld	s1,8(sp)
    8000375a:	6105                	add	sp,sp,32
    8000375c:	8082                	ret

000000008000375e <arg_uint32>:

// 读取 n 号参数, 作为 uint32 存储
void arg_uint32(int n, uint32* ip)
{
    8000375e:	1101                	add	sp,sp,-32
    80003760:	ec06                	sd	ra,24(sp)
    80003762:	e822                	sd	s0,16(sp)
    80003764:	e426                	sd	s1,8(sp)
    80003766:	1000                	add	s0,sp,32
    80003768:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	f12080e7          	jalr	-238(ra) # 8000367c <arg_raw>
    80003772:	c088                	sw	a0,0(s1)
}
    80003774:	60e2                	ld	ra,24(sp)
    80003776:	6442                	ld	s0,16(sp)
    80003778:	64a2                	ld	s1,8(sp)
    8000377a:	6105                	add	sp,sp,32
    8000377c:	8082                	ret

000000008000377e <arg_uint64>:

// 读取 n 号参数, 作为 uint64 存储
void arg_uint64(int n, uint64* ip)
{
    8000377e:	1101                	add	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	1000                	add	s0,sp,32
    80003788:	84ae                	mv	s1,a1
    *ip = arg_raw(n);
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	ef2080e7          	jalr	-270(ra) # 8000367c <arg_raw>
    80003792:	e088                	sd	a0,0(s1)
}
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	64a2                	ld	s1,8(sp)
    8000379a:	6105                	add	sp,sp,32
    8000379c:	8082                	ret

000000008000379e <arg_str>:

// 读取 n 号参数指向的字符串到 buf, 字符串最大长度是 maxlen
void arg_str(int n, char* buf, int maxlen)
{
    8000379e:	7139                	add	sp,sp,-64
    800037a0:	fc06                	sd	ra,56(sp)
    800037a2:	f822                	sd	s0,48(sp)
    800037a4:	f426                	sd	s1,40(sp)
    800037a6:	f04a                	sd	s2,32(sp)
    800037a8:	ec4e                	sd	s3,24(sp)
    800037aa:	e852                	sd	s4,16(sp)
    800037ac:	0080                	add	s0,sp,64
    800037ae:	8a2a                	mv	s4,a0
    800037b0:	892e                	mv	s2,a1
    800037b2:	89b2                	mv	s3,a2
    proc_t* p = myproc();
    800037b4:	fffff097          	auipc	ra,0xfffff
    800037b8:	9b0080e7          	jalr	-1616(ra) # 80002164 <myproc>
    800037bc:	84aa                	mv	s1,a0
    uint64 addr;
    arg_uint64(n, &addr);
    800037be:	fc840593          	add	a1,s0,-56
    800037c2:	8552                	mv	a0,s4
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	fba080e7          	jalr	-70(ra) # 8000377e <arg_uint64>

    uvm_copyin_str(p->pgtbl, (uint64)buf, addr, maxlen);
    800037cc:	86ce                	mv	a3,s3
    800037ce:	fc843603          	ld	a2,-56(s0)
    800037d2:	85ca                	mv	a1,s2
    800037d4:	64a8                	ld	a0,72(s1)
    800037d6:	ffffe097          	auipc	ra,0xffffe
    800037da:	668080e7          	jalr	1640(ra) # 80001e3e <uvm_copyin_str>
}
    800037de:	70e2                	ld	ra,56(sp)
    800037e0:	7442                	ld	s0,48(sp)
    800037e2:	74a2                	ld	s1,40(sp)
    800037e4:	7902                	ld	s2,32(sp)
    800037e6:	69e2                	ld	s3,24(sp)
    800037e8:	6a42                	ld	s4,16(sp)
    800037ea:	6121                	add	sp,sp,64
    800037ec:	8082                	ret

00000000800037ee <fetchstr>:

int
fetchstr(uint64 addr, char *buf, int max)
{
    800037ee:	7179                	add	sp,sp,-48
    800037f0:	f406                	sd	ra,40(sp)
    800037f2:	f022                	sd	s0,32(sp)
    800037f4:	ec26                	sd	s1,24(sp)
    800037f6:	e84a                	sd	s2,16(sp)
    800037f8:	e44e                	sd	s3,8(sp)
    800037fa:	1800                	add	s0,sp,48
    800037fc:	892a                	mv	s2,a0
    800037fe:	84ae                	mv	s1,a1
    80003800:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003802:	fffff097          	auipc	ra,0xfffff
    80003806:	962080e7          	jalr	-1694(ra) # 80002164 <myproc>
  if(uvm_copyin_str(p->pgtbl, (uint64) buf, addr, max) < 0)
    8000380a:	86ce                	mv	a3,s3
    8000380c:	864a                	mv	a2,s2
    8000380e:	85a6                	mv	a1,s1
    80003810:	6528                	ld	a0,72(a0)
    80003812:	ffffe097          	auipc	ra,0xffffe
    80003816:	62c080e7          	jalr	1580(ra) # 80001e3e <uvm_copyin_str>
    8000381a:	00054e63          	bltz	a0,80003836 <fetchstr+0x48>
    return -1;
  return strlen(buf);
    8000381e:	8526                	mv	a0,s1
    80003820:	ffffe097          	auipc	ra,0xffffe
    80003824:	916080e7          	jalr	-1770(ra) # 80001136 <strlen>
}
    80003828:	70a2                	ld	ra,40(sp)
    8000382a:	7402                	ld	s0,32(sp)
    8000382c:	64e2                	ld	s1,24(sp)
    8000382e:	6942                	ld	s2,16(sp)
    80003830:	69a2                	ld	s3,8(sp)
    80003832:	6145                	add	sp,sp,48
    80003834:	8082                	ret
    return -1;
    80003836:	557d                	li	a0,-1
    80003838:	bfc5                	j	80003828 <fetchstr+0x3a>

000000008000383a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000383a:	7179                	add	sp,sp,-48
    8000383c:	f406                	sd	ra,40(sp)
    8000383e:	f022                	sd	s0,32(sp)
    80003840:	ec26                	sd	s1,24(sp)
    80003842:	e84a                	sd	s2,16(sp)
    80003844:	1800                	add	s0,sp,48
    80003846:	84ae                	mv	s1,a1
    80003848:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000384a:	fd840593          	add	a1,s0,-40
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	f30080e7          	jalr	-208(ra) # 8000377e <arg_uint64>
  return fetchstr(addr, buf, max);
    80003856:	864a                	mv	a2,s2
    80003858:	85a6                	mv	a1,s1
    8000385a:	fd843503          	ld	a0,-40(s0)
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	f90080e7          	jalr	-112(ra) # 800037ee <fetchstr>
}
    80003866:	70a2                	ld	ra,40(sp)
    80003868:	7402                	ld	s0,32(sp)
    8000386a:	64e2                	ld	s1,24(sp)
    8000386c:	6942                	ld	s2,16(sp)
    8000386e:	6145                	add	sp,sp,48
    80003870:	8082                	ret

0000000080003872 <sys_brk>:

// 堆伸缩
// uint64 new_heap_top 新的堆顶 (如果是0代表查询, 返回旧的堆顶)
// 成功返回新的堆顶 失败返回-1
uint64 sys_brk()
{
    80003872:	7179                	add	sp,sp,-48
    80003874:	f406                	sd	ra,40(sp)
    80003876:	f022                	sd	s0,32(sp)
    80003878:	ec26                	sd	s1,24(sp)
    8000387a:	1800                	add	s0,sp,48
    uint64 new_addr;
    uint64 old_addr = myproc()->sz;  // 保存原始堆顶
    8000387c:	fffff097          	auipc	ra,0xfffff
    80003880:	8e8080e7          	jalr	-1816(ra) # 80002164 <myproc>
    80003884:	7564                	ld	s1,232(a0)

    arg_uint64(0, &new_addr);  // 正确读取64位地址
    80003886:	fd840593          	add	a1,s0,-40
    8000388a:	4501                	li	a0,0
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	ef2080e7          	jalr	-270(ra) # 8000377e <arg_uint64>
    
    if(new_addr == old_addr || new_addr == 0) {
    80003894:	fd843783          	ld	a5,-40(s0)
    80003898:	00978963          	beq	a5,s1,800038aa <sys_brk+0x38>
    8000389c:	c799                	beqz	a5,800038aa <sys_brk+0x38>
        return old_addr;  // 无变化，返回当前堆顶
    }
    
    int diff = (int)(new_addr - old_addr);
    8000389e:	4097853b          	subw	a0,a5,s1
    
    // 检查是否溢出
    if((uint64)diff != (new_addr - old_addr)) {
    800038a2:	8f85                	sub	a5,a5,s1
        return -1;  // 差值太大，int无法表示
    800038a4:	54fd                	li	s1,-1
    if((uint64)diff != (new_addr - old_addr)) {
    800038a6:	00f50863          	beq	a0,a5,800038b6 <sys_brk+0x44>
    if(growproc(diff) < 0) {
        return -1;  // 扩展失败
    }
    
    return new_addr;  // 返回扩展前的地址
}
    800038aa:	8526                	mv	a0,s1
    800038ac:	70a2                	ld	ra,40(sp)
    800038ae:	7402                	ld	s0,32(sp)
    800038b0:	64e2                	ld	s1,24(sp)
    800038b2:	6145                	add	sp,sp,48
    800038b4:	8082                	ret
    if(growproc(diff) < 0) {
    800038b6:	fffff097          	auipc	ra,0xfffff
    800038ba:	e04080e7          	jalr	-508(ra) # 800026ba <growproc>
    800038be:	00054563          	bltz	a0,800038c8 <sys_brk+0x56>
    return new_addr;  // 返回扩展前的地址
    800038c2:	fd843483          	ld	s1,-40(s0)
    800038c6:	b7d5                	j	800038aa <sys_brk+0x38>
        return -1;  // 扩展失败
    800038c8:	54fd                	li	s1,-1
    800038ca:	b7c5                	j	800038aa <sys_brk+0x38>

00000000800038cc <sys_kill>:

uint64
sys_kill(void)
{
    800038cc:	1101                	add	sp,sp,-32
    800038ce:	ec06                	sd	ra,24(sp)
    800038d0:	e822                	sd	s0,16(sp)
    800038d2:	1000                	add	s0,sp,32
  uint64 pid;

  arg_uint64(0, &pid);
    800038d4:	fe840593          	add	a1,s0,-24
    800038d8:	4501                	li	a0,0
    800038da:	00000097          	auipc	ra,0x0
    800038de:	ea4080e7          	jalr	-348(ra) # 8000377e <arg_uint64>
  return kill(pid);
    800038e2:	fe842503          	lw	a0,-24(s0)
    800038e6:	fffff097          	auipc	ra,0xfffff
    800038ea:	126080e7          	jalr	294(ra) # 80002a0c <kill>
}
    800038ee:	60e2                	ld	ra,24(sp)
    800038f0:	6442                	ld	s0,16(sp)
    800038f2:	6105                	add	sp,sp,32
    800038f4:	8082                	ret

00000000800038f6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800038f6:	1141                	add	sp,sp,-16
    800038f8:	e406                	sd	ra,8(sp)
    800038fa:	e022                	sd	s0,0(sp)
    800038fc:	0800                	add	s0,sp,16
  return myproc()->pid;
    800038fe:	fffff097          	auipc	ra,0xfffff
    80003902:	866080e7          	jalr	-1946(ra) # 80002164 <myproc>
}
    80003906:	4108                	lw	a0,0(a0)
    80003908:	60a2                	ld	ra,8(sp)
    8000390a:	6402                	ld	s0,0(sp)
    8000390c:	0141                	add	sp,sp,16
    8000390e:	8082                	ret

0000000080003910 <sys_print>:
// 打印字符
// uint64 addr
uint64 sys_print()
{
    80003910:	7175                	add	sp,sp,-144
    80003912:	e506                	sd	ra,136(sp)
    80003914:	e122                	sd	s0,128(sp)
    80003916:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    80003918:	08000613          	li	a2,128
    8000391c:	f7040593          	add	a1,s0,-144
    80003920:	4501                	li	a0,0
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e7c080e7          	jalr	-388(ra) # 8000379e <arg_str>

    printf("%s", buf);
    8000392a:	f7040593          	add	a1,s0,-144
    8000392e:	00006517          	auipc	a0,0x6
    80003932:	faa50513          	add	a0,a0,-86 # 800098d8 <syscalls+0x100>
    80003936:	ffffe097          	auipc	ra,0xffffe
    8000393a:	918080e7          	jalr	-1768(ra) # 8000124e <printf>
    return 0;
}
    8000393e:	4501                	li	a0,0
    80003940:	60aa                	ld	ra,136(sp)
    80003942:	640a                	ld	s0,128(sp)
    80003944:	6149                	add	sp,sp,144
    80003946:	8082                	ret

0000000080003948 <sys_fork>:

// 进程复制
uint64 sys_fork()
{
    80003948:	1141                	add	sp,sp,-16
    8000394a:	e406                	sd	ra,8(sp)
    8000394c:	e022                	sd	s0,0(sp)
    8000394e:	0800                	add	s0,sp,16
    return fork();
    80003950:	fffff097          	auipc	ra,0xfffff
    80003954:	e9c080e7          	jalr	-356(ra) # 800027ec <fork>
}
    80003958:	60a2                	ld	ra,8(sp)
    8000395a:	6402                	ld	s0,0(sp)
    8000395c:	0141                	add	sp,sp,16
    8000395e:	8082                	ret

0000000080003960 <sys_wait>:

// 进程等待
// uint64 addr  子进程退出时的exit_state需要放到这里 
uint64 sys_wait()
{
    80003960:	1101                	add	sp,sp,-32
    80003962:	ec06                	sd	ra,24(sp)
    80003964:	e822                	sd	s0,16(sp)
    80003966:	1000                	add	s0,sp,32
    uint64 p;
    arg_uint64(0, &p);
    80003968:	fe840593          	add	a1,s0,-24
    8000396c:	4501                	li	a0,0
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	e10080e7          	jalr	-496(ra) # 8000377e <arg_uint64>
    return wait(p);
    80003976:	fe843503          	ld	a0,-24(s0)
    8000397a:	fffff097          	auipc	ra,0xfffff
    8000397e:	178080e7          	jalr	376(ra) # 80002af2 <wait>
}
    80003982:	60e2                	ld	ra,24(sp)
    80003984:	6442                	ld	s0,16(sp)
    80003986:	6105                	add	sp,sp,32
    80003988:	8082                	ret

000000008000398a <sys_exit>:

// 进程退出
// int exit_state
uint64 sys_exit()
{
    8000398a:	1101                	add	sp,sp,-32
    8000398c:	ec06                	sd	ra,24(sp)
    8000398e:	e822                	sd	s0,16(sp)
    80003990:	1000                	add	s0,sp,32
    uint64 n;
    arg_uint64(0, &n);
    80003992:	fe840593          	add	a1,s0,-24
    80003996:	4501                	li	a0,0
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	de6080e7          	jalr	-538(ra) # 8000377e <arg_uint64>
    exit(n);
    800039a0:	fe842503          	lw	a0,-24(s0)
    800039a4:	fffff097          	auipc	ra,0xfffff
    800039a8:	2f0080e7          	jalr	752(ra) # 80002c94 <exit>
    return 0;  // not reached
}
    800039ac:	4501                	li	a0,0
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	6105                	add	sp,sp,32
    800039b4:	8082                	ret

00000000800039b6 <sys_sleep>:

// 进程睡眠一段时间
// uint32 second 睡眠时间
// 成功返回0, 失败返回-1
uint64 sys_sleep()
{
    800039b6:	7139                	add	sp,sp,-64
    800039b8:	fc06                	sd	ra,56(sp)
    800039ba:	f822                	sd	s0,48(sp)
    800039bc:	f426                	sd	s1,40(sp)
    800039be:	f04a                	sd	s2,32(sp)
    800039c0:	ec4e                	sd	s3,24(sp)
    800039c2:	0080                	add	s0,sp,64
    uint64 n;
    uint ticks0;

    arg_uint64(0, &n);
    800039c4:	fc840593          	add	a1,s0,-56
    800039c8:	4501                	li	a0,0
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	db4080e7          	jalr	-588(ra) # 8000377e <arg_uint64>
    acquire(& sys_timer.lk);
    800039d2:	0000e517          	auipc	a0,0xe
    800039d6:	5b650513          	add	a0,a0,1462 # 80011f88 <sys_timer+0x8>
    800039da:	fffff097          	auipc	ra,0xfffff
    800039de:	694080e7          	jalr	1684(ra) # 8000306e <acquire>
    ticks0 = sys_timer.ticks;
    800039e2:	0000e797          	auipc	a5,0xe
    800039e6:	59e7b783          	ld	a5,1438(a5) # 80011f80 <sys_timer>
    while(sys_timer.ticks - ticks0 < n){
    800039ea:	02079913          	sll	s2,a5,0x20
    800039ee:	02095913          	srl	s2,s2,0x20
    800039f2:	412787b3          	sub	a5,a5,s2
    800039f6:	fc843703          	ld	a4,-56(s0)
    800039fa:	04e7f063          	bgeu	a5,a4,80003a3a <sys_sleep+0x84>
        if(killed(myproc())){
        release(&sys_timer.lk);
        return -1;
        }
        sleep(&sys_timer.ticks, &sys_timer.lk);
    800039fe:	0000e997          	auipc	s3,0xe
    80003a02:	58a98993          	add	s3,s3,1418 # 80011f88 <sys_timer+0x8>
    80003a06:	0000e497          	auipc	s1,0xe
    80003a0a:	57a48493          	add	s1,s1,1402 # 80011f80 <sys_timer>
        if(killed(myproc())){
    80003a0e:	ffffe097          	auipc	ra,0xffffe
    80003a12:	756080e7          	jalr	1878(ra) # 80002164 <myproc>
    80003a16:	fffff097          	auipc	ra,0xfffff
    80003a1a:	0a6080e7          	jalr	166(ra) # 80002abc <killed>
    80003a1e:	ed15                	bnez	a0,80003a5a <sys_sleep+0xa4>
        sleep(&sys_timer.ticks, &sys_timer.lk);
    80003a20:	85ce                	mv	a1,s3
    80003a22:	8526                	mv	a0,s1
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	efc080e7          	jalr	-260(ra) # 80002920 <sleep>
    while(sys_timer.ticks - ticks0 < n){
    80003a2c:	609c                	ld	a5,0(s1)
    80003a2e:	412787b3          	sub	a5,a5,s2
    80003a32:	fc843703          	ld	a4,-56(s0)
    80003a36:	fce7ece3          	bltu	a5,a4,80003a0e <sys_sleep+0x58>
    }
    release(& sys_timer.lk);
    80003a3a:	0000e517          	auipc	a0,0xe
    80003a3e:	54e50513          	add	a0,a0,1358 # 80011f88 <sys_timer+0x8>
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	6e0080e7          	jalr	1760(ra) # 80003122 <release>
    return 0;
    80003a4a:	4501                	li	a0,0
}
    80003a4c:	70e2                	ld	ra,56(sp)
    80003a4e:	7442                	ld	s0,48(sp)
    80003a50:	74a2                	ld	s1,40(sp)
    80003a52:	7902                	ld	s2,32(sp)
    80003a54:	69e2                	ld	s3,24(sp)
    80003a56:	6121                	add	sp,sp,64
    80003a58:	8082                	ret
        release(&sys_timer.lk);
    80003a5a:	0000e517          	auipc	a0,0xe
    80003a5e:	52e50513          	add	a0,a0,1326 # 80011f88 <sys_timer+0x8>
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	6c0080e7          	jalr	1728(ra) # 80003122 <release>
        return -1;
    80003a6a:	557d                	li	a0,-1
    80003a6c:	b7c5                	j	80003a4c <sys_sleep+0x96>

0000000080003a6e <sys_debug>:


uint64 sys_debug(void)
{
    80003a6e:	7175                	add	sp,sp,-144
    80003a70:	e506                	sd	ra,136(sp)
    80003a72:	e122                	sd	s0,128(sp)
    80003a74:	0900                	add	s0,sp,144
    char buf[128];

    // arg_str：从用户态参数中读到字符串内容复制到 buf
    arg_str(0, buf, sizeof(buf));
    80003a76:	08000613          	li	a2,128
    80003a7a:	f7040593          	add	a1,s0,-144
    80003a7e:	4501                	li	a0,0
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	d1e080e7          	jalr	-738(ra) # 8000379e <arg_str>

    printf("[debug] %s \n", buf);
    80003a88:	f7040593          	add	a1,s0,-144
    80003a8c:	00006517          	auipc	a0,0x6
    80003a90:	e5450513          	add	a0,a0,-428 # 800098e0 <syscalls+0x108>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	7ba080e7          	jalr	1978(ra) # 8000124e <printf>
    return 0;
}
    80003a9c:	4501                	li	a0,0
    80003a9e:	60aa                	ld	ra,136(sp)
    80003aa0:	640a                	ld	s0,128(sp)
    80003aa2:	6149                	add	sp,sp,144
    80003aa4:	8082                	ret

0000000080003aa6 <flags2perm>:
#define USERSTACK    1     // user stack pages
static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80003aa6:	1141                	add	sp,sp,-16
    80003aa8:	e422                	sd	s0,8(sp)
    80003aaa:	0800                	add	s0,sp,16
    80003aac:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80003aae:	8905                	and	a0,a0,1
    80003ab0:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80003ab2:	8b89                	and	a5,a5,2
    80003ab4:	c399                	beqz	a5,80003aba <flags2perm+0x14>
      perm |= PTE_W;
    80003ab6:	00456513          	or	a0,a0,4
    return perm;
}
    80003aba:	6422                	ld	s0,8(sp)
    80003abc:	0141                	add	sp,sp,16
    80003abe:	8082                	ret

0000000080003ac0 <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    80003ac0:	df010113          	add	sp,sp,-528
    80003ac4:	20113423          	sd	ra,520(sp)
    80003ac8:	20813023          	sd	s0,512(sp)
    80003acc:	ffa6                	sd	s1,504(sp)
    80003ace:	fbca                	sd	s2,496(sp)
    80003ad0:	f7ce                	sd	s3,488(sp)
    80003ad2:	f3d2                	sd	s4,480(sp)
    80003ad4:	efd6                	sd	s5,472(sp)
    80003ad6:	ebda                	sd	s6,464(sp)
    80003ad8:	e7de                	sd	s7,456(sp)
    80003ada:	e3e2                	sd	s8,448(sp)
    80003adc:	ff66                	sd	s9,440(sp)
    80003ade:	fb6a                	sd	s10,432(sp)
    80003ae0:	f76e                	sd	s11,424(sp)
    80003ae2:	0c00                	add	s0,sp,528
    80003ae4:	84aa                	mv	s1,a0
    80003ae6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = (struct proc * )myproc();
    80003aea:	ffffe097          	auipc	ra,0xffffe
    80003aee:	67a080e7          	jalr	1658(ra) # 80002164 <myproc>
    80003af2:	892a                	mv	s2,a0

  begin_op();
    80003af4:	00002097          	auipc	ra,0x2
    80003af8:	27e080e7          	jalr	638(ra) # 80005d72 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80003afc:	8526                	mv	a0,s1
    80003afe:	00003097          	auipc	ra,0x3
    80003b02:	ca0080e7          	jalr	-864(ra) # 8000679e <namei>
    80003b06:	c92d                	beqz	a0,80003b78 <kexec+0xb8>
    80003b08:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80003b0a:	00001097          	auipc	ra,0x1
    80003b0e:	5d6080e7          	jalr	1494(ra) # 800050e0 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80003b12:	04000713          	li	a4,64
    80003b16:	4681                	li	a3,0
    80003b18:	e5040613          	add	a2,s0,-432
    80003b1c:	4581                	li	a1,0
    80003b1e:	8552                	mv	a0,s4
    80003b20:	00002097          	auipc	ra,0x2
    80003b24:	874080e7          	jalr	-1932(ra) # 80005394 <readi>
    80003b28:	04000793          	li	a5,64
    80003b2c:	00f51a63          	bne	a0,a5,80003b40 <kexec+0x80>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    80003b30:	e5042703          	lw	a4,-432(s0)
    80003b34:	464c47b7          	lui	a5,0x464c4
    80003b38:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80003b3c:	04f70463          	beq	a4,a5,80003b84 <kexec+0xc4>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80003b40:	8552                	mv	a0,s4
    80003b42:	00002097          	auipc	ra,0x2
    80003b46:	800080e7          	jalr	-2048(ra) # 80005342 <iunlockput>
    end_op();
    80003b4a:	00002097          	auipc	ra,0x2
    80003b4e:	2a2080e7          	jalr	674(ra) # 80005dec <end_op>
  }
  return -1;
    80003b52:	557d                	li	a0,-1
}
    80003b54:	20813083          	ld	ra,520(sp)
    80003b58:	20013403          	ld	s0,512(sp)
    80003b5c:	74fe                	ld	s1,504(sp)
    80003b5e:	795e                	ld	s2,496(sp)
    80003b60:	79be                	ld	s3,488(sp)
    80003b62:	7a1e                	ld	s4,480(sp)
    80003b64:	6afe                	ld	s5,472(sp)
    80003b66:	6b5e                	ld	s6,464(sp)
    80003b68:	6bbe                	ld	s7,456(sp)
    80003b6a:	6c1e                	ld	s8,448(sp)
    80003b6c:	7cfa                	ld	s9,440(sp)
    80003b6e:	7d5a                	ld	s10,432(sp)
    80003b70:	7dba                	ld	s11,424(sp)
    80003b72:	21010113          	add	sp,sp,528
    80003b76:	8082                	ret
    end_op();
    80003b78:	00002097          	auipc	ra,0x2
    80003b7c:	274080e7          	jalr	628(ra) # 80005dec <end_op>
    return -1;
    80003b80:	557d                	li	a0,-1
    80003b82:	bfc9                	j	80003b54 <kexec+0x94>
  if((pagetable = proc_pagetable(p)) == 0)
    80003b84:	854a                	mv	a0,s2
    80003b86:	fffff097          	auipc	ra,0xfffff
    80003b8a:	292080e7          	jalr	658(ra) # 80002e18 <proc_pagetable>
    80003b8e:	8b2a                	mv	s6,a0
    80003b90:	d945                	beqz	a0,80003b40 <kexec+0x80>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80003b92:	e7042d03          	lw	s10,-400(s0)
    80003b96:	e8845783          	lhu	a5,-376(s0)
    80003b9a:	10078463          	beqz	a5,80003ca2 <kexec+0x1e2>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80003b9e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80003ba0:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80003ba2:	6c85                	lui	s9,0x1
    80003ba4:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80003ba8:	def43c23          	sd	a5,-520(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80003bac:	6a85                	lui	s5,0x1
    80003bae:	a0b5                	j	80003c1a <kexec+0x15a>
      panic("loadseg: address should exist");
    80003bb0:	00006517          	auipc	a0,0x6
    80003bb4:	d4050513          	add	a0,a0,-704 # 800098f0 <syscalls+0x118>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	64c080e7          	jalr	1612(ra) # 80001204 <panic>
    if(sz - i < PGSIZE)
    80003bc0:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80003bc2:	8726                	mv	a4,s1
    80003bc4:	012c06bb          	addw	a3,s8,s2
    80003bc8:	4581                	li	a1,0
    80003bca:	8552                	mv	a0,s4
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	7c8080e7          	jalr	1992(ra) # 80005394 <readi>
    80003bd4:	2501                	sext.w	a0,a0
    80003bd6:	20a49c63          	bne	s1,a0,80003dee <kexec+0x32e>
  for(i = 0; i < sz; i += PGSIZE){
    80003bda:	012a893b          	addw	s2,s5,s2
    80003bde:	03397563          	bgeu	s2,s3,80003c08 <kexec+0x148>
    pa = walkaddr(pagetable, va + i);
    80003be2:	02091593          	sll	a1,s2,0x20
    80003be6:	9181                	srl	a1,a1,0x20
    80003be8:	95de                	add	a1,a1,s7
    80003bea:	855a                	mv	a0,s6
    80003bec:	ffffe097          	auipc	ra,0xffffe
    80003bf0:	c8e080e7          	jalr	-882(ra) # 8000187a <walkaddr>
    80003bf4:	862a                	mv	a2,a0
    if(pa == 0)
    80003bf6:	dd4d                	beqz	a0,80003bb0 <kexec+0xf0>
    if(sz - i < PGSIZE)
    80003bf8:	412984bb          	subw	s1,s3,s2
    80003bfc:	0004879b          	sext.w	a5,s1
    80003c00:	fcfcf0e3          	bgeu	s9,a5,80003bc0 <kexec+0x100>
    80003c04:	84d6                	mv	s1,s5
    80003c06:	bf6d                	j	80003bc0 <kexec+0x100>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80003c08:	e0843483          	ld	s1,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80003c0c:	2d85                	addw	s11,s11,1
    80003c0e:	038d0d1b          	addw	s10,s10,56
    80003c12:	e8845783          	lhu	a5,-376(s0)
    80003c16:	08fdd763          	bge	s11,a5,80003ca4 <kexec+0x1e4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80003c1a:	2d01                	sext.w	s10,s10
    80003c1c:	03800713          	li	a4,56
    80003c20:	86ea                	mv	a3,s10
    80003c22:	e1840613          	add	a2,s0,-488
    80003c26:	4581                	li	a1,0
    80003c28:	8552                	mv	a0,s4
    80003c2a:	00001097          	auipc	ra,0x1
    80003c2e:	76a080e7          	jalr	1898(ra) # 80005394 <readi>
    80003c32:	03800793          	li	a5,56
    80003c36:	1af51a63          	bne	a0,a5,80003dea <kexec+0x32a>
    if(ph.type != ELF_PROG_LOAD)
    80003c3a:	e1842783          	lw	a5,-488(s0)
    80003c3e:	4705                	li	a4,1
    80003c40:	fce796e3          	bne	a5,a4,80003c0c <kexec+0x14c>
    if(ph.memsz < ph.filesz)
    80003c44:	e4043903          	ld	s2,-448(s0)
    80003c48:	e3843783          	ld	a5,-456(s0)
    80003c4c:	1af96c63          	bltu	s2,a5,80003e04 <kexec+0x344>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80003c50:	e2843783          	ld	a5,-472(s0)
    80003c54:	993e                	add	s2,s2,a5
    80003c56:	1af96a63          	bltu	s2,a5,80003e0a <kexec+0x34a>
    if(ph.vaddr % PGSIZE != 0)
    80003c5a:	df843703          	ld	a4,-520(s0)
    80003c5e:	8ff9                	and	a5,a5,a4
    80003c60:	1a079863          	bnez	a5,80003e10 <kexec+0x350>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80003c64:	e1c42503          	lw	a0,-484(s0)
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	e3e080e7          	jalr	-450(ra) # 80003aa6 <flags2perm>
    80003c70:	86aa                	mv	a3,a0
    80003c72:	864a                	mv	a2,s2
    80003c74:	85a6                	mv	a1,s1
    80003c76:	855a                	mv	a0,s6
    80003c78:	ffffe097          	auipc	ra,0xffffe
    80003c7c:	fd2080e7          	jalr	-46(ra) # 80001c4a <uvmalloc>
    80003c80:	e0a43423          	sd	a0,-504(s0)
    80003c84:	18050963          	beqz	a0,80003e16 <kexec+0x356>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80003c88:	e2843b83          	ld	s7,-472(s0)
    80003c8c:	e2042c03          	lw	s8,-480(s0)
    80003c90:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80003c94:	00098463          	beqz	s3,80003c9c <kexec+0x1dc>
    80003c98:	4901                	li	s2,0
    80003c9a:	b7a1                	j	80003be2 <kexec+0x122>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80003c9c:	e0843483          	ld	s1,-504(s0)
    80003ca0:	b7b5                	j	80003c0c <kexec+0x14c>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80003ca2:	4481                	li	s1,0
  iunlockput(ip);
    80003ca4:	8552                	mv	a0,s4
    80003ca6:	00001097          	auipc	ra,0x1
    80003caa:	69c080e7          	jalr	1692(ra) # 80005342 <iunlockput>
  end_op();
    80003cae:	00002097          	auipc	ra,0x2
    80003cb2:	13e080e7          	jalr	318(ra) # 80005dec <end_op>
  p = myproc();
    80003cb6:	ffffe097          	auipc	ra,0xffffe
    80003cba:	4ae080e7          	jalr	1198(ra) # 80002164 <myproc>
    80003cbe:	89aa                	mv	s3,a0
  uint64 oldsz = p->sz;
    80003cc0:	0e853a83          	ld	s5,232(a0)
  sz = PGROUNDUP(sz);
    80003cc4:	6b85                	lui	s7,0x1
    80003cc6:	1bfd                	add	s7,s7,-1 # fff <_entry-0x7ffff001>
    80003cc8:	9ba6                	add	s7,s7,s1
    80003cca:	77fd                	lui	a5,0xfffff
    80003ccc:	00fbfbb3          	and	s7,s7,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80003cd0:	4691                	li	a3,4
    80003cd2:	6609                	lui	a2,0x2
    80003cd4:	965e                	add	a2,a2,s7
    80003cd6:	85de                	mv	a1,s7
    80003cd8:	855a                	mv	a0,s6
    80003cda:	ffffe097          	auipc	ra,0xffffe
    80003cde:	f70080e7          	jalr	-144(ra) # 80001c4a <uvmalloc>
    80003ce2:	8c2a                	mv	s8,a0
    80003ce4:	e0a43423          	sd	a0,-504(s0)
    80003ce8:	e509                	bnez	a0,80003cf2 <kexec+0x232>
  if(pagetable)
    80003cea:	e1743423          	sd	s7,-504(s0)
    80003cee:	4a01                	li	s4,0
    80003cf0:	a8fd                	j	80003dee <kexec+0x32e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80003cf2:	75f9                	lui	a1,0xffffe
    80003cf4:	95aa                	add	a1,a1,a0
    80003cf6:	855a                	mv	a0,s6
    80003cf8:	ffffe097          	auipc	ra,0xffffe
    80003cfc:	40e080e7          	jalr	1038(ra) # 80002106 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80003d00:	7a7d                	lui	s4,0xfffff
    80003d02:	9a62                	add	s4,s4,s8
  for(argc = 0; argv[argc]; argc++) {
    80003d04:	e0043783          	ld	a5,-512(s0)
    80003d08:	6388                	ld	a0,0(a5)
    80003d0a:	c52d                	beqz	a0,80003d74 <kexec+0x2b4>
    80003d0c:	e9040913          	add	s2,s0,-368
    80003d10:	f9040b93          	add	s7,s0,-112
    80003d14:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	420080e7          	jalr	1056(ra) # 80001136 <strlen>
    80003d1e:	0015079b          	addw	a5,a0,1
    80003d22:	40fc07b3          	sub	a5,s8,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80003d26:	ff07fc13          	and	s8,a5,-16
    if(sp < stackbase)
    80003d2a:	0f4c6963          	bltu	s8,s4,80003e1c <kexec+0x35c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80003d2e:	e0043d03          	ld	s10,-512(s0)
    80003d32:	000d3c83          	ld	s9,0(s10)
    80003d36:	8566                	mv	a0,s9
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	3fe080e7          	jalr	1022(ra) # 80001136 <strlen>
    80003d40:	0015069b          	addw	a3,a0,1
    80003d44:	8666                	mv	a2,s9
    80003d46:	85e2                	mv	a1,s8
    80003d48:	855a                	mv	a0,s6
    80003d4a:	ffffe097          	auipc	ra,0xffffe
    80003d4e:	1e6080e7          	jalr	486(ra) # 80001f30 <copyout>
    80003d52:	0c054763          	bltz	a0,80003e20 <kexec+0x360>
    ustack[argc] = sp;
    80003d56:	01893023          	sd	s8,0(s2)
  for(argc = 0; argv[argc]; argc++) {
    80003d5a:	0485                	add	s1,s1,1
    80003d5c:	008d0793          	add	a5,s10,8
    80003d60:	e0f43023          	sd	a5,-512(s0)
    80003d64:	008d3503          	ld	a0,8(s10)
    80003d68:	c909                	beqz	a0,80003d7a <kexec+0x2ba>
    if(argc >= MAXARG)
    80003d6a:	0921                	add	s2,s2,8
    80003d6c:	fb7915e3          	bne	s2,s7,80003d16 <kexec+0x256>
  ip = 0;
    80003d70:	4a01                	li	s4,0
    80003d72:	a8b5                	j	80003dee <kexec+0x32e>
  sp = sz;
    80003d74:	e0843c03          	ld	s8,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80003d78:	4481                	li	s1,0
  ustack[argc] = 0;
    80003d7a:	00349793          	sll	a5,s1,0x3
    80003d7e:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdbcd8>
    80003d82:	97a2                	add	a5,a5,s0
    80003d84:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80003d88:	00148693          	add	a3,s1,1
    80003d8c:	068e                	sll	a3,a3,0x3
    80003d8e:	40dc0933          	sub	s2,s8,a3
  sp -= sp % 16;
    80003d92:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80003d96:	e0843c03          	ld	s8,-504(s0)
    80003d9a:	8be2                	mv	s7,s8
  if(sp < stackbase)
    80003d9c:	f54967e3          	bltu	s2,s4,80003cea <kexec+0x22a>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80003da0:	e9040613          	add	a2,s0,-368
    80003da4:	85ca                	mv	a1,s2
    80003da6:	855a                	mv	a0,s6
    80003da8:	ffffe097          	auipc	ra,0xffffe
    80003dac:	188080e7          	jalr	392(ra) # 80001f30 <copyout>
    80003db0:	06054a63          	bltz	a0,80003e24 <kexec+0x364>
  p->tf->a1 = sp;
    80003db4:	0589b783          	ld	a5,88(s3)
    80003db8:	0727bc23          	sd	s2,120(a5)
  oldpagetable = p->pgtbl;
    80003dbc:	0489b503          	ld	a0,72(s3)
  p->pgtbl = pagetable;
    80003dc0:	0569b423          	sd	s6,72(s3)
  p->sz = sz;
    80003dc4:	0f89b423          	sd	s8,232(s3)
  p->tf->epc = elf.entry;  // initial program counter = main
    80003dc8:	0589b783          	ld	a5,88(s3)
    80003dcc:	e6843703          	ld	a4,-408(s0)
    80003dd0:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    80003dd2:	0589b783          	ld	a5,88(s3)
    80003dd6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80003dda:	85d6                	mv	a1,s5
    80003ddc:	ffffe097          	auipc	ra,0xffffe
    80003de0:	5da080e7          	jalr	1498(ra) # 800023b6 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80003de4:	0004851b          	sext.w	a0,s1
    80003de8:	b3b5                	j	80003b54 <kexec+0x94>
    80003dea:	e0943423          	sd	s1,-504(s0)
    proc_freepagetable(pagetable, sz);
    80003dee:	e0843583          	ld	a1,-504(s0)
    80003df2:	855a                	mv	a0,s6
    80003df4:	ffffe097          	auipc	ra,0xffffe
    80003df8:	5c2080e7          	jalr	1474(ra) # 800023b6 <proc_freepagetable>
  return -1;
    80003dfc:	557d                	li	a0,-1
  if(ip){
    80003dfe:	d40a0be3          	beqz	s4,80003b54 <kexec+0x94>
    80003e02:	bb3d                	j	80003b40 <kexec+0x80>
    80003e04:	e0943423          	sd	s1,-504(s0)
    80003e08:	b7dd                	j	80003dee <kexec+0x32e>
    80003e0a:	e0943423          	sd	s1,-504(s0)
    80003e0e:	b7c5                	j	80003dee <kexec+0x32e>
    80003e10:	e0943423          	sd	s1,-504(s0)
    80003e14:	bfe9                	j	80003dee <kexec+0x32e>
    80003e16:	e0943423          	sd	s1,-504(s0)
    80003e1a:	bfd1                	j	80003dee <kexec+0x32e>
  ip = 0;
    80003e1c:	4a01                	li	s4,0
    80003e1e:	bfc1                	j	80003dee <kexec+0x32e>
    80003e20:	4a01                	li	s4,0
  if(pagetable)
    80003e22:	b7f1                	j	80003dee <kexec+0x32e>
  sz = sz1;
    80003e24:	e0843b83          	ld	s7,-504(s0)
    80003e28:	b5c9                	j	80003cea <kexec+0x22a>

0000000080003e2a <sys_exec>:
{
    80003e2a:	7145                	add	sp,sp,-464
    80003e2c:	e786                	sd	ra,456(sp)
    80003e2e:	e3a2                	sd	s0,448(sp)
    80003e30:	ff26                	sd	s1,440(sp)
    80003e32:	fb4a                	sd	s2,432(sp)
    80003e34:	f74e                	sd	s3,424(sp)
    80003e36:	f352                	sd	s4,416(sp)
    80003e38:	ef56                	sd	s5,408(sp)
    80003e3a:	0b80                	add	s0,sp,464
  uint64 uargv = 0;   // 用户态 argv[] 指针（指向指针数组）
    80003e3c:	f2043c23          	sd	zero,-200(s0)
  uint64 uarg = 0;    // 用户态单个 argv[i] 指针
    80003e40:	f2043823          	sd	zero,-208(s0)
  if(argstr(0, path, MAXPATH) < 0)
    80003e44:	08000613          	li	a2,128
    80003e48:	f4040593          	add	a1,s0,-192
    80003e4c:	4501                	li	a0,0
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	9ec080e7          	jalr	-1556(ra) # 8000383a <argstr>
    80003e56:	87aa                	mv	a5,a0
    return (uint64)-1;
    80003e58:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0)
    80003e5a:	0e07cb63          	bltz	a5,80003f50 <sys_exec+0x126>
  argaddr(1, &uargv);
    80003e5e:	f3840593          	add	a1,s0,-200
    80003e62:	4505                	li	a0,1
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	91a080e7          	jalr	-1766(ra) # 8000377e <arg_uint64>
  memset(argv, 0, sizeof(argv));
    80003e6c:	10000613          	li	a2,256
    80003e70:	4581                	li	a1,0
    80003e72:	e3040513          	add	a0,s0,-464
    80003e76:	ffffd097          	auipc	ra,0xffffd
    80003e7a:	146080e7          	jalr	326(ra) # 80000fbc <memset>
  for(i = 0; i < MAXARG; i++){
    80003e7e:	e3040493          	add	s1,s0,-464
  memset(argv, 0, sizeof(argv));
    80003e82:	8926                	mv	s2,s1
    80003e84:	4981                	li	s3,0
  for(i = 0; i < MAXARG; i++){
    80003e86:	4a01                	li	s4,0
    80003e88:	02000a93          	li	s5,32
    if(uvm_copyin(myproc()->pgtbl, (uint64)&uarg, uargv + sizeof(uint64) * i, sizeof(uarg)) < 0)
    80003e8c:	ffffe097          	auipc	ra,0xffffe
    80003e90:	2d8080e7          	jalr	728(ra) # 80002164 <myproc>
    80003e94:	46a1                	li	a3,8
    80003e96:	f3843603          	ld	a2,-200(s0)
    80003e9a:	964e                	add	a2,a2,s3
    80003e9c:	f3040593          	add	a1,s0,-208
    80003ea0:	6528                	ld	a0,72(a0)
    80003ea2:	ffffe097          	auipc	ra,0xffffe
    80003ea6:	e5e080e7          	jalr	-418(ra) # 80001d00 <uvm_copyin>
    80003eaa:	04054263          	bltz	a0,80003eee <sys_exec+0xc4>
    if(uarg == 0){
    80003eae:	f3043783          	ld	a5,-208(s0)
    80003eb2:	cfa1                	beqz	a5,80003f0a <sys_exec+0xe0>
    argv[i] = kalloc(1);
    80003eb4:	4505                	li	a0,1
    80003eb6:	ffffd097          	auipc	ra,0xffffd
    80003eba:	6aa080e7          	jalr	1706(ra) # 80001560 <kalloc>
    80003ebe:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80003ec2:	c515                	beqz	a0,80003eee <sys_exec+0xc4>
    if(uvm_copyin_str(myproc()->pgtbl, (uint64)argv[i], uarg, PGSIZE) < 0)
    80003ec4:	ffffe097          	auipc	ra,0xffffe
    80003ec8:	2a0080e7          	jalr	672(ra) # 80002164 <myproc>
    80003ecc:	6685                	lui	a3,0x1
    80003ece:	f3043603          	ld	a2,-208(s0)
    80003ed2:	00093583          	ld	a1,0(s2)
    80003ed6:	6528                	ld	a0,72(a0)
    80003ed8:	ffffe097          	auipc	ra,0xffffe
    80003edc:	f66080e7          	jalr	-154(ra) # 80001e3e <uvm_copyin_str>
    80003ee0:	00054763          	bltz	a0,80003eee <sys_exec+0xc4>
  for(i = 0; i < MAXARG; i++){
    80003ee4:	2a05                	addw	s4,s4,1 # fffffffffffff001 <end+0xffffffff7ffdbd49>
    80003ee6:	09a1                	add	s3,s3,8
    80003ee8:	0921                	add	s2,s2,8
    80003eea:	fb5a11e3          	bne	s4,s5,80003e8c <sys_exec+0x62>
  for(i = 0; i < MAXARG && argv[i] != 0; i++)
    80003eee:	f3040913          	add	s2,s0,-208
    80003ef2:	6088                	ld	a0,0(s1)
    80003ef4:	cd29                	beqz	a0,80003f4e <sys_exec+0x124>
    kfree((uint64)argv[i], 1);
    80003ef6:	4585                	li	a1,1
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	568080e7          	jalr	1384(ra) # 80001460 <kfree>
  for(i = 0; i < MAXARG && argv[i] != 0; i++)
    80003f00:	04a1                	add	s1,s1,8
    80003f02:	ff2498e3          	bne	s1,s2,80003ef2 <sys_exec+0xc8>
  return (uint64)-1;
    80003f06:	557d                	li	a0,-1
    80003f08:	a0a1                	j	80003f50 <sys_exec+0x126>
      argv[i] = 0;
    80003f0a:	003a1793          	sll	a5,s4,0x3
    80003f0e:	fc078793          	add	a5,a5,-64
    80003f12:	97a2                	add	a5,a5,s0
    80003f14:	e607b823          	sd	zero,-400(a5)
  if(i == MAXARG)
    80003f18:	02000793          	li	a5,32
    80003f1c:	fcfa09e3          	beq	s4,a5,80003eee <sys_exec+0xc4>
  int ret = kexec(path, argv);
    80003f20:	e3040593          	add	a1,s0,-464
    80003f24:	f4040513          	add	a0,s0,-192
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	b98080e7          	jalr	-1128(ra) # 80003ac0 <kexec>
    80003f30:	89aa                	mv	s3,a0
  for(i = 0; i < MAXARG && argv[i] != 0; i++)
    80003f32:	f3040913          	add	s2,s0,-208
    80003f36:	6088                	ld	a0,0(s1)
    80003f38:	c909                	beqz	a0,80003f4a <sys_exec+0x120>
    kfree((uint64)argv[i], 1);
    80003f3a:	4585                	li	a1,1
    80003f3c:	ffffd097          	auipc	ra,0xffffd
    80003f40:	524080e7          	jalr	1316(ra) # 80001460 <kfree>
  for(i = 0; i < MAXARG && argv[i] != 0; i++)
    80003f44:	04a1                	add	s1,s1,8
    80003f46:	ff2498e3          	bne	s1,s2,80003f36 <sys_exec+0x10c>
  return (uint64)ret;
    80003f4a:	854e                	mv	a0,s3
    80003f4c:	a011                	j	80003f50 <sys_exec+0x126>
  return (uint64)-1;
    80003f4e:	557d                	li	a0,-1
}
    80003f50:	60be                	ld	ra,456(sp)
    80003f52:	641e                	ld	s0,448(sp)
    80003f54:	74fa                	ld	s1,440(sp)
    80003f56:	795a                	ld	s2,432(sp)
    80003f58:	79ba                	ld	s3,424(sp)
    80003f5a:	7a1a                	ld	s4,416(sp)
    80003f5c:	6afa                	ld	s5,408(sp)
    80003f5e:	6179                	add	sp,sp,464
    80003f60:	8082                	ret

0000000080003f62 <argfd>:
#include "buf.h"
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80003f62:	7179                	add	sp,sp,-48
    80003f64:	f406                	sd	ra,40(sp)
    80003f66:	f022                	sd	s0,32(sp)
    80003f68:	ec26                	sd	s1,24(sp)
    80003f6a:	e84a                	sd	s2,16(sp)
    80003f6c:	1800                	add	s0,sp,48
    80003f6e:	892e                	mv	s2,a1
    80003f70:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80003f72:	fdc40593          	add	a1,s0,-36
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	808080e7          	jalr	-2040(ra) # 8000377e <arg_uint64>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80003f7e:	fdc42703          	lw	a4,-36(s0)
    80003f82:	47bd                	li	a5,15
    80003f84:	02e7eb63          	bltu	a5,a4,80003fba <argfd+0x58>
    80003f88:	ffffe097          	auipc	ra,0xffffe
    80003f8c:	1dc080e7          	jalr	476(ra) # 80002164 <myproc>
    80003f90:	fdc42703          	lw	a4,-36(s0)
    80003f94:	00c70793          	add	a5,a4,12
    80003f98:	078e                	sll	a5,a5,0x3
    80003f9a:	953e                	add	a0,a0,a5
    80003f9c:	611c                	ld	a5,0(a0)
    80003f9e:	c385                	beqz	a5,80003fbe <argfd+0x5c>
    return -1;
  if(pfd)
    80003fa0:	00090463          	beqz	s2,80003fa8 <argfd+0x46>
    *pfd = fd;
    80003fa4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80003fa8:	4501                	li	a0,0
  if(pf)
    80003faa:	c091                	beqz	s1,80003fae <argfd+0x4c>
    *pf = f;
    80003fac:	e09c                	sd	a5,0(s1)
}
    80003fae:	70a2                	ld	ra,40(sp)
    80003fb0:	7402                	ld	s0,32(sp)
    80003fb2:	64e2                	ld	s1,24(sp)
    80003fb4:	6942                	ld	s2,16(sp)
    80003fb6:	6145                	add	sp,sp,48
    80003fb8:	8082                	ret
    return -1;
    80003fba:	557d                	li	a0,-1
    80003fbc:	bfcd                	j	80003fae <argfd+0x4c>
    80003fbe:	557d                	li	a0,-1
    80003fc0:	b7fd                	j	80003fae <argfd+0x4c>

0000000080003fc2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80003fc2:	1101                	add	sp,sp,-32
    80003fc4:	ec06                	sd	ra,24(sp)
    80003fc6:	e822                	sd	s0,16(sp)
    80003fc8:	e426                	sd	s1,8(sp)
    80003fca:	1000                	add	s0,sp,32
    80003fcc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80003fce:	ffffe097          	auipc	ra,0xffffe
    80003fd2:	196080e7          	jalr	406(ra) # 80002164 <myproc>
    80003fd6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80003fd8:	06050793          	add	a5,a0,96
    80003fdc:	4501                	li	a0,0
    80003fde:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80003fe0:	6398                	ld	a4,0(a5)
    80003fe2:	cb19                	beqz	a4,80003ff8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80003fe4:	2505                	addw	a0,a0,1
    80003fe6:	07a1                	add	a5,a5,8
    80003fe8:	fed51ce3          	bne	a0,a3,80003fe0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80003fec:	557d                	li	a0,-1
}
    80003fee:	60e2                	ld	ra,24(sp)
    80003ff0:	6442                	ld	s0,16(sp)
    80003ff2:	64a2                	ld	s1,8(sp)
    80003ff4:	6105                	add	sp,sp,32
    80003ff6:	8082                	ret
      p->ofile[fd] = f;
    80003ff8:	00c50793          	add	a5,a0,12
    80003ffc:	078e                	sll	a5,a5,0x3
    80003ffe:	963e                	add	a2,a2,a5
    80004000:	e204                	sd	s1,0(a2)
      return fd;
    80004002:	b7f5                	j	80003fee <fdalloc+0x2c>

0000000080004004 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004004:	715d                	add	sp,sp,-80
    80004006:	e486                	sd	ra,72(sp)
    80004008:	e0a2                	sd	s0,64(sp)
    8000400a:	fc26                	sd	s1,56(sp)
    8000400c:	f84a                	sd	s2,48(sp)
    8000400e:	f44e                	sd	s3,40(sp)
    80004010:	f052                	sd	s4,32(sp)
    80004012:	ec56                	sd	s5,24(sp)
    80004014:	e85a                	sd	s6,16(sp)
    80004016:	0880                	add	s0,sp,80
    80004018:	8b2e                	mv	s6,a1
    8000401a:	89b2                	mv	s3,a2
    8000401c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000401e:	fb040593          	add	a1,s0,-80
    80004022:	00002097          	auipc	ra,0x2
    80004026:	79a080e7          	jalr	1946(ra) # 800067bc <nameiparent>
    8000402a:	84aa                	mv	s1,a0
    8000402c:	14050b63          	beqz	a0,80004182 <create+0x17e>
    return 0;

  ilock(dp);
    80004030:	00001097          	auipc	ra,0x1
    80004034:	0b0080e7          	jalr	176(ra) # 800050e0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004038:	4601                	li	a2,0
    8000403a:	fb040593          	add	a1,s0,-80
    8000403e:	8526                	mv	a0,s1
    80004040:	00002097          	auipc	ra,0x2
    80004044:	49e080e7          	jalr	1182(ra) # 800064de <dirlookup>
    80004048:	8aaa                	mv	s5,a0
    8000404a:	c921                	beqz	a0,8000409a <create+0x96>
    iunlockput(dp);
    8000404c:	8526                	mv	a0,s1
    8000404e:	00001097          	auipc	ra,0x1
    80004052:	2f4080e7          	jalr	756(ra) # 80005342 <iunlockput>
    ilock(ip);
    80004056:	8556                	mv	a0,s5
    80004058:	00001097          	auipc	ra,0x1
    8000405c:	088080e7          	jalr	136(ra) # 800050e0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004060:	4789                	li	a5,2
    80004062:	02fb1563          	bne	s6,a5,8000408c <create+0x88>
    80004066:	044ad783          	lhu	a5,68(s5) # 1044 <_entry-0x7fffefbc>
    8000406a:	37f9                	addw	a5,a5,-2
    8000406c:	17c2                	sll	a5,a5,0x30
    8000406e:	93c1                	srl	a5,a5,0x30
    80004070:	4705                	li	a4,1
    80004072:	00f76d63          	bltu	a4,a5,8000408c <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004076:	8556                	mv	a0,s5
    80004078:	60a6                	ld	ra,72(sp)
    8000407a:	6406                	ld	s0,64(sp)
    8000407c:	74e2                	ld	s1,56(sp)
    8000407e:	7942                	ld	s2,48(sp)
    80004080:	79a2                	ld	s3,40(sp)
    80004082:	7a02                	ld	s4,32(sp)
    80004084:	6ae2                	ld	s5,24(sp)
    80004086:	6b42                	ld	s6,16(sp)
    80004088:	6161                	add	sp,sp,80
    8000408a:	8082                	ret
    iunlockput(ip);
    8000408c:	8556                	mv	a0,s5
    8000408e:	00001097          	auipc	ra,0x1
    80004092:	2b4080e7          	jalr	692(ra) # 80005342 <iunlockput>
    return 0;
    80004096:	4a81                	li	s5,0
    80004098:	bff9                	j	80004076 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000409a:	85da                	mv	a1,s6
    8000409c:	4088                	lw	a0,0(s1)
    8000409e:	00001097          	auipc	ra,0x1
    800040a2:	eaa080e7          	jalr	-342(ra) # 80004f48 <ialloc>
    800040a6:	8a2a                	mv	s4,a0
    800040a8:	c529                	beqz	a0,800040f2 <create+0xee>
  ilock(ip);
    800040aa:	00001097          	auipc	ra,0x1
    800040ae:	036080e7          	jalr	54(ra) # 800050e0 <ilock>
  ip->major = major;
    800040b2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800040b6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800040ba:	4905                	li	s2,1
    800040bc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800040c0:	8552                	mv	a0,s4
    800040c2:	00001097          	auipc	ra,0x1
    800040c6:	f52080e7          	jalr	-174(ra) # 80005014 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800040ca:	032b0b63          	beq	s6,s2,80004100 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800040ce:	004a2603          	lw	a2,4(s4)
    800040d2:	fb040593          	add	a1,s0,-80
    800040d6:	8526                	mv	a0,s1
    800040d8:	00002097          	auipc	ra,0x2
    800040dc:	614080e7          	jalr	1556(ra) # 800066ec <dirlink>
    800040e0:	06054f63          	bltz	a0,8000415e <create+0x15a>
  iunlockput(dp);
    800040e4:	8526                	mv	a0,s1
    800040e6:	00001097          	auipc	ra,0x1
    800040ea:	25c080e7          	jalr	604(ra) # 80005342 <iunlockput>
  return ip;
    800040ee:	8ad2                	mv	s5,s4
    800040f0:	b759                	j	80004076 <create+0x72>
    iunlockput(dp);
    800040f2:	8526                	mv	a0,s1
    800040f4:	00001097          	auipc	ra,0x1
    800040f8:	24e080e7          	jalr	590(ra) # 80005342 <iunlockput>
    return 0;
    800040fc:	8ad2                	mv	s5,s4
    800040fe:	bfa5                	j	80004076 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004100:	004a2603          	lw	a2,4(s4)
    80004104:	00006597          	auipc	a1,0x6
    80004108:	80c58593          	add	a1,a1,-2036 # 80009910 <syscalls+0x138>
    8000410c:	8552                	mv	a0,s4
    8000410e:	00002097          	auipc	ra,0x2
    80004112:	5de080e7          	jalr	1502(ra) # 800066ec <dirlink>
    80004116:	04054463          	bltz	a0,8000415e <create+0x15a>
    8000411a:	40d0                	lw	a2,4(s1)
    8000411c:	00005597          	auipc	a1,0x5
    80004120:	7fc58593          	add	a1,a1,2044 # 80009918 <syscalls+0x140>
    80004124:	8552                	mv	a0,s4
    80004126:	00002097          	auipc	ra,0x2
    8000412a:	5c6080e7          	jalr	1478(ra) # 800066ec <dirlink>
    8000412e:	02054863          	bltz	a0,8000415e <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80004132:	004a2603          	lw	a2,4(s4)
    80004136:	fb040593          	add	a1,s0,-80
    8000413a:	8526                	mv	a0,s1
    8000413c:	00002097          	auipc	ra,0x2
    80004140:	5b0080e7          	jalr	1456(ra) # 800066ec <dirlink>
    80004144:	00054d63          	bltz	a0,8000415e <create+0x15a>
    dp->nlink++;  // for ".."
    80004148:	04a4d783          	lhu	a5,74(s1)
    8000414c:	2785                	addw	a5,a5,1
    8000414e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004152:	8526                	mv	a0,s1
    80004154:	00001097          	auipc	ra,0x1
    80004158:	ec0080e7          	jalr	-320(ra) # 80005014 <iupdate>
    8000415c:	b761                	j	800040e4 <create+0xe0>
  ip->nlink = 0;
    8000415e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004162:	8552                	mv	a0,s4
    80004164:	00001097          	auipc	ra,0x1
    80004168:	eb0080e7          	jalr	-336(ra) # 80005014 <iupdate>
  iunlockput(ip);
    8000416c:	8552                	mv	a0,s4
    8000416e:	00001097          	auipc	ra,0x1
    80004172:	1d4080e7          	jalr	468(ra) # 80005342 <iunlockput>
  iunlockput(dp);
    80004176:	8526                	mv	a0,s1
    80004178:	00001097          	auipc	ra,0x1
    8000417c:	1ca080e7          	jalr	458(ra) # 80005342 <iunlockput>
  return 0;
    80004180:	bddd                	j	80004076 <create+0x72>
    return 0;
    80004182:	8aaa                	mv	s5,a0
    80004184:	bdcd                	j	80004076 <create+0x72>

0000000080004186 <sys_dup>:
{
    80004186:	7179                	add	sp,sp,-48
    80004188:	f406                	sd	ra,40(sp)
    8000418a:	f022                	sd	s0,32(sp)
    8000418c:	ec26                	sd	s1,24(sp)
    8000418e:	e84a                	sd	s2,16(sp)
    80004190:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004192:	fd840613          	add	a2,s0,-40
    80004196:	4581                	li	a1,0
    80004198:	4501                	li	a0,0
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	dc8080e7          	jalr	-568(ra) # 80003f62 <argfd>
    return -1;
    800041a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800041a4:	02054363          	bltz	a0,800041ca <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800041a8:	fd843903          	ld	s2,-40(s0)
    800041ac:	854a                	mv	a0,s2
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	e14080e7          	jalr	-492(ra) # 80003fc2 <fdalloc>
    800041b6:	84aa                	mv	s1,a0
    return -1;
    800041b8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800041ba:	00054863          	bltz	a0,800041ca <sys_dup+0x44>
  filedup(f);
    800041be:	854a                	mv	a0,s2
    800041c0:	00002097          	auipc	ra,0x2
    800041c4:	efa080e7          	jalr	-262(ra) # 800060ba <filedup>
  return fd;
    800041c8:	87a6                	mv	a5,s1
}
    800041ca:	853e                	mv	a0,a5
    800041cc:	70a2                	ld	ra,40(sp)
    800041ce:	7402                	ld	s0,32(sp)
    800041d0:	64e2                	ld	s1,24(sp)
    800041d2:	6942                	ld	s2,16(sp)
    800041d4:	6145                	add	sp,sp,48
    800041d6:	8082                	ret

00000000800041d8 <sys_read>:
{
    800041d8:	7179                	add	sp,sp,-48
    800041da:	f406                	sd	ra,40(sp)
    800041dc:	f022                	sd	s0,32(sp)
    800041de:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800041e0:	fd840593          	add	a1,s0,-40
    800041e4:	4505                	li	a0,1
    800041e6:	fffff097          	auipc	ra,0xfffff
    800041ea:	598080e7          	jalr	1432(ra) # 8000377e <arg_uint64>
  argint(2, &n);
    800041ee:	fe440593          	add	a1,s0,-28
    800041f2:	4509                	li	a0,2
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	58a080e7          	jalr	1418(ra) # 8000377e <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    800041fc:	fe840613          	add	a2,s0,-24
    80004200:	4581                	li	a1,0
    80004202:	4501                	li	a0,0
    80004204:	00000097          	auipc	ra,0x0
    80004208:	d5e080e7          	jalr	-674(ra) # 80003f62 <argfd>
    8000420c:	87aa                	mv	a5,a0
    return -1;
    8000420e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004210:	0007cc63          	bltz	a5,80004228 <sys_read+0x50>
  return fileread(f, p, n);
    80004214:	fe442603          	lw	a2,-28(s0)
    80004218:	fd843583          	ld	a1,-40(s0)
    8000421c:	fe843503          	ld	a0,-24(s0)
    80004220:	00002097          	auipc	ra,0x2
    80004224:	026080e7          	jalr	38(ra) # 80006246 <fileread>
}
    80004228:	70a2                	ld	ra,40(sp)
    8000422a:	7402                	ld	s0,32(sp)
    8000422c:	6145                	add	sp,sp,48
    8000422e:	8082                	ret

0000000080004230 <sys_write>:
{
    80004230:	7179                	add	sp,sp,-48
    80004232:	f406                	sd	ra,40(sp)
    80004234:	f022                	sd	s0,32(sp)
    80004236:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80004238:	fd840593          	add	a1,s0,-40
    8000423c:	4505                	li	a0,1
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	540080e7          	jalr	1344(ra) # 8000377e <arg_uint64>
  argint(2, &n);
    80004246:	fe440593          	add	a1,s0,-28
    8000424a:	4509                	li	a0,2
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	532080e7          	jalr	1330(ra) # 8000377e <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    80004254:	fe840613          	add	a2,s0,-24
    80004258:	4581                	li	a1,0
    8000425a:	4501                	li	a0,0
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	d06080e7          	jalr	-762(ra) # 80003f62 <argfd>
    80004264:	87aa                	mv	a5,a0
    return -1;
    80004266:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004268:	0007cc63          	bltz	a5,80004280 <sys_write+0x50>
  return filewrite(f, p, n);
    8000426c:	fe442603          	lw	a2,-28(s0)
    80004270:	fd843583          	ld	a1,-40(s0)
    80004274:	fe843503          	ld	a0,-24(s0)
    80004278:	00002097          	auipc	ra,0x2
    8000427c:	090080e7          	jalr	144(ra) # 80006308 <filewrite>
}
    80004280:	70a2                	ld	ra,40(sp)
    80004282:	7402                	ld	s0,32(sp)
    80004284:	6145                	add	sp,sp,48
    80004286:	8082                	ret

0000000080004288 <sys_close>:
{
    80004288:	1101                	add	sp,sp,-32
    8000428a:	ec06                	sd	ra,24(sp)
    8000428c:	e822                	sd	s0,16(sp)
    8000428e:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004290:	fe040613          	add	a2,s0,-32
    80004294:	fec40593          	add	a1,s0,-20
    80004298:	4501                	li	a0,0
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	cc8080e7          	jalr	-824(ra) # 80003f62 <argfd>
    return -1;
    800042a2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800042a4:	02054463          	bltz	a0,800042cc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800042a8:	ffffe097          	auipc	ra,0xffffe
    800042ac:	ebc080e7          	jalr	-324(ra) # 80002164 <myproc>
    800042b0:	fec42783          	lw	a5,-20(s0)
    800042b4:	07b1                	add	a5,a5,12
    800042b6:	078e                	sll	a5,a5,0x3
    800042b8:	953e                	add	a0,a0,a5
    800042ba:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800042be:	fe043503          	ld	a0,-32(s0)
    800042c2:	00002097          	auipc	ra,0x2
    800042c6:	e4a080e7          	jalr	-438(ra) # 8000610c <fileclose>
  return 0;
    800042ca:	4781                	li	a5,0
}
    800042cc:	853e                	mv	a0,a5
    800042ce:	60e2                	ld	ra,24(sp)
    800042d0:	6442                	ld	s0,16(sp)
    800042d2:	6105                	add	sp,sp,32
    800042d4:	8082                	ret

00000000800042d6 <sys_fstat>:
{
    800042d6:	1101                	add	sp,sp,-32
    800042d8:	ec06                	sd	ra,24(sp)
    800042da:	e822                	sd	s0,16(sp)
    800042dc:	1000                	add	s0,sp,32
  argaddr(1, &st);
    800042de:	fe040593          	add	a1,s0,-32
    800042e2:	4505                	li	a0,1
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	49a080e7          	jalr	1178(ra) # 8000377e <arg_uint64>
  if(argfd(0, 0, &f) < 0)
    800042ec:	fe840613          	add	a2,s0,-24
    800042f0:	4581                	li	a1,0
    800042f2:	4501                	li	a0,0
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	c6e080e7          	jalr	-914(ra) # 80003f62 <argfd>
    800042fc:	87aa                	mv	a5,a0
    return -1;
    800042fe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004300:	0007ca63          	bltz	a5,80004314 <sys_fstat+0x3e>
  return filestat(f, st);
    80004304:	fe043583          	ld	a1,-32(s0)
    80004308:	fe843503          	ld	a0,-24(s0)
    8000430c:	00002097          	auipc	ra,0x2
    80004310:	ec8080e7          	jalr	-312(ra) # 800061d4 <filestat>
}
    80004314:	60e2                	ld	ra,24(sp)
    80004316:	6442                	ld	s0,16(sp)
    80004318:	6105                	add	sp,sp,32
    8000431a:	8082                	ret

000000008000431c <sys_link>:
{
    8000431c:	7169                	add	sp,sp,-304
    8000431e:	f606                	sd	ra,296(sp)
    80004320:	f222                	sd	s0,288(sp)
    80004322:	ee26                	sd	s1,280(sp)
    80004324:	ea4a                	sd	s2,272(sp)
    80004326:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004328:	08000613          	li	a2,128
    8000432c:	ed040593          	add	a1,s0,-304
    80004330:	4501                	li	a0,0
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	508080e7          	jalr	1288(ra) # 8000383a <argstr>
    return -1;
    8000433a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000433c:	10054e63          	bltz	a0,80004458 <sys_link+0x13c>
    80004340:	08000613          	li	a2,128
    80004344:	f5040593          	add	a1,s0,-176
    80004348:	4505                	li	a0,1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	4f0080e7          	jalr	1264(ra) # 8000383a <argstr>
    return -1;
    80004352:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004354:	10054263          	bltz	a0,80004458 <sys_link+0x13c>
  begin_op();
    80004358:	00002097          	auipc	ra,0x2
    8000435c:	a1a080e7          	jalr	-1510(ra) # 80005d72 <begin_op>
  if((ip = namei(old)) == 0){
    80004360:	ed040513          	add	a0,s0,-304
    80004364:	00002097          	auipc	ra,0x2
    80004368:	43a080e7          	jalr	1082(ra) # 8000679e <namei>
    8000436c:	84aa                	mv	s1,a0
    8000436e:	c551                	beqz	a0,800043fa <sys_link+0xde>
  ilock(ip);
    80004370:	00001097          	auipc	ra,0x1
    80004374:	d70080e7          	jalr	-656(ra) # 800050e0 <ilock>
  if(ip->type == T_DIR){
    80004378:	04449703          	lh	a4,68(s1)
    8000437c:	4785                	li	a5,1
    8000437e:	08f70463          	beq	a4,a5,80004406 <sys_link+0xea>
  ip->nlink++;
    80004382:	04a4d783          	lhu	a5,74(s1)
    80004386:	2785                	addw	a5,a5,1
    80004388:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000438c:	8526                	mv	a0,s1
    8000438e:	00001097          	auipc	ra,0x1
    80004392:	c86080e7          	jalr	-890(ra) # 80005014 <iupdate>
  iunlock(ip);
    80004396:	8526                	mv	a0,s1
    80004398:	00001097          	auipc	ra,0x1
    8000439c:	e0a080e7          	jalr	-502(ra) # 800051a2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800043a0:	fd040593          	add	a1,s0,-48
    800043a4:	f5040513          	add	a0,s0,-176
    800043a8:	00002097          	auipc	ra,0x2
    800043ac:	414080e7          	jalr	1044(ra) # 800067bc <nameiparent>
    800043b0:	892a                	mv	s2,a0
    800043b2:	c935                	beqz	a0,80004426 <sys_link+0x10a>
  ilock(dp);
    800043b4:	00001097          	auipc	ra,0x1
    800043b8:	d2c080e7          	jalr	-724(ra) # 800050e0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800043bc:	00092703          	lw	a4,0(s2)
    800043c0:	409c                	lw	a5,0(s1)
    800043c2:	04f71d63          	bne	a4,a5,8000441c <sys_link+0x100>
    800043c6:	40d0                	lw	a2,4(s1)
    800043c8:	fd040593          	add	a1,s0,-48
    800043cc:	854a                	mv	a0,s2
    800043ce:	00002097          	auipc	ra,0x2
    800043d2:	31e080e7          	jalr	798(ra) # 800066ec <dirlink>
    800043d6:	04054363          	bltz	a0,8000441c <sys_link+0x100>
  iunlockput(dp);
    800043da:	854a                	mv	a0,s2
    800043dc:	00001097          	auipc	ra,0x1
    800043e0:	f66080e7          	jalr	-154(ra) # 80005342 <iunlockput>
  iput(ip);
    800043e4:	8526                	mv	a0,s1
    800043e6:	00001097          	auipc	ra,0x1
    800043ea:	eb4080e7          	jalr	-332(ra) # 8000529a <iput>
  end_op();
    800043ee:	00002097          	auipc	ra,0x2
    800043f2:	9fe080e7          	jalr	-1538(ra) # 80005dec <end_op>
  return 0;
    800043f6:	4781                	li	a5,0
    800043f8:	a085                	j	80004458 <sys_link+0x13c>
    end_op();
    800043fa:	00002097          	auipc	ra,0x2
    800043fe:	9f2080e7          	jalr	-1550(ra) # 80005dec <end_op>
    return -1;
    80004402:	57fd                	li	a5,-1
    80004404:	a891                	j	80004458 <sys_link+0x13c>
    iunlockput(ip);
    80004406:	8526                	mv	a0,s1
    80004408:	00001097          	auipc	ra,0x1
    8000440c:	f3a080e7          	jalr	-198(ra) # 80005342 <iunlockput>
    end_op();
    80004410:	00002097          	auipc	ra,0x2
    80004414:	9dc080e7          	jalr	-1572(ra) # 80005dec <end_op>
    return -1;
    80004418:	57fd                	li	a5,-1
    8000441a:	a83d                	j	80004458 <sys_link+0x13c>
    iunlockput(dp);
    8000441c:	854a                	mv	a0,s2
    8000441e:	00001097          	auipc	ra,0x1
    80004422:	f24080e7          	jalr	-220(ra) # 80005342 <iunlockput>
  ilock(ip);
    80004426:	8526                	mv	a0,s1
    80004428:	00001097          	auipc	ra,0x1
    8000442c:	cb8080e7          	jalr	-840(ra) # 800050e0 <ilock>
  ip->nlink--;
    80004430:	04a4d783          	lhu	a5,74(s1)
    80004434:	37fd                	addw	a5,a5,-1
    80004436:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000443a:	8526                	mv	a0,s1
    8000443c:	00001097          	auipc	ra,0x1
    80004440:	bd8080e7          	jalr	-1064(ra) # 80005014 <iupdate>
  iunlockput(ip);
    80004444:	8526                	mv	a0,s1
    80004446:	00001097          	auipc	ra,0x1
    8000444a:	efc080e7          	jalr	-260(ra) # 80005342 <iunlockput>
  end_op();
    8000444e:	00002097          	auipc	ra,0x2
    80004452:	99e080e7          	jalr	-1634(ra) # 80005dec <end_op>
  return -1;
    80004456:	57fd                	li	a5,-1
}
    80004458:	853e                	mv	a0,a5
    8000445a:	70b2                	ld	ra,296(sp)
    8000445c:	7412                	ld	s0,288(sp)
    8000445e:	64f2                	ld	s1,280(sp)
    80004460:	6952                	ld	s2,272(sp)
    80004462:	6155                	add	sp,sp,304
    80004464:	8082                	ret

0000000080004466 <sys_unlink>:
{
    80004466:	7151                	add	sp,sp,-240
    80004468:	f586                	sd	ra,232(sp)
    8000446a:	f1a2                	sd	s0,224(sp)
    8000446c:	eda6                	sd	s1,216(sp)
    8000446e:	e9ca                	sd	s2,208(sp)
    80004470:	e5ce                	sd	s3,200(sp)
    80004472:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004474:	08000613          	li	a2,128
    80004478:	f3040593          	add	a1,s0,-208
    8000447c:	4501                	li	a0,0
    8000447e:	fffff097          	auipc	ra,0xfffff
    80004482:	3bc080e7          	jalr	956(ra) # 8000383a <argstr>
    80004486:	18054163          	bltz	a0,80004608 <sys_unlink+0x1a2>
  begin_op();
    8000448a:	00002097          	auipc	ra,0x2
    8000448e:	8e8080e7          	jalr	-1816(ra) # 80005d72 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004492:	fb040593          	add	a1,s0,-80
    80004496:	f3040513          	add	a0,s0,-208
    8000449a:	00002097          	auipc	ra,0x2
    8000449e:	322080e7          	jalr	802(ra) # 800067bc <nameiparent>
    800044a2:	84aa                	mv	s1,a0
    800044a4:	c979                	beqz	a0,8000457a <sys_unlink+0x114>
  ilock(dp);
    800044a6:	00001097          	auipc	ra,0x1
    800044aa:	c3a080e7          	jalr	-966(ra) # 800050e0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800044ae:	00005597          	auipc	a1,0x5
    800044b2:	46258593          	add	a1,a1,1122 # 80009910 <syscalls+0x138>
    800044b6:	fb040513          	add	a0,s0,-80
    800044ba:	00002097          	auipc	ra,0x2
    800044be:	00a080e7          	jalr	10(ra) # 800064c4 <namecmp>
    800044c2:	14050a63          	beqz	a0,80004616 <sys_unlink+0x1b0>
    800044c6:	00005597          	auipc	a1,0x5
    800044ca:	45258593          	add	a1,a1,1106 # 80009918 <syscalls+0x140>
    800044ce:	fb040513          	add	a0,s0,-80
    800044d2:	00002097          	auipc	ra,0x2
    800044d6:	ff2080e7          	jalr	-14(ra) # 800064c4 <namecmp>
    800044da:	12050e63          	beqz	a0,80004616 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800044de:	f2c40613          	add	a2,s0,-212
    800044e2:	fb040593          	add	a1,s0,-80
    800044e6:	8526                	mv	a0,s1
    800044e8:	00002097          	auipc	ra,0x2
    800044ec:	ff6080e7          	jalr	-10(ra) # 800064de <dirlookup>
    800044f0:	892a                	mv	s2,a0
    800044f2:	12050263          	beqz	a0,80004616 <sys_unlink+0x1b0>
  ilock(ip);
    800044f6:	00001097          	auipc	ra,0x1
    800044fa:	bea080e7          	jalr	-1046(ra) # 800050e0 <ilock>
  if(ip->nlink < 1)
    800044fe:	04a91783          	lh	a5,74(s2)
    80004502:	08f05263          	blez	a5,80004586 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004506:	04491703          	lh	a4,68(s2)
    8000450a:	4785                	li	a5,1
    8000450c:	08f70563          	beq	a4,a5,80004596 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80004510:	4641                	li	a2,16
    80004512:	4581                	li	a1,0
    80004514:	fc040513          	add	a0,s0,-64
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	aa4080e7          	jalr	-1372(ra) # 80000fbc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004520:	4741                	li	a4,16
    80004522:	f2c42683          	lw	a3,-212(s0)
    80004526:	fc040613          	add	a2,s0,-64
    8000452a:	4581                	li	a1,0
    8000452c:	8526                	mv	a0,s1
    8000452e:	00001097          	auipc	ra,0x1
    80004532:	f5e080e7          	jalr	-162(ra) # 8000548c <writei>
    80004536:	47c1                	li	a5,16
    80004538:	0af51563          	bne	a0,a5,800045e2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000453c:	04491703          	lh	a4,68(s2)
    80004540:	4785                	li	a5,1
    80004542:	0af70863          	beq	a4,a5,800045f2 <sys_unlink+0x18c>
  iunlockput(dp);
    80004546:	8526                	mv	a0,s1
    80004548:	00001097          	auipc	ra,0x1
    8000454c:	dfa080e7          	jalr	-518(ra) # 80005342 <iunlockput>
  ip->nlink--;
    80004550:	04a95783          	lhu	a5,74(s2)
    80004554:	37fd                	addw	a5,a5,-1
    80004556:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000455a:	854a                	mv	a0,s2
    8000455c:	00001097          	auipc	ra,0x1
    80004560:	ab8080e7          	jalr	-1352(ra) # 80005014 <iupdate>
  iunlockput(ip);
    80004564:	854a                	mv	a0,s2
    80004566:	00001097          	auipc	ra,0x1
    8000456a:	ddc080e7          	jalr	-548(ra) # 80005342 <iunlockput>
  end_op();
    8000456e:	00002097          	auipc	ra,0x2
    80004572:	87e080e7          	jalr	-1922(ra) # 80005dec <end_op>
  return 0;
    80004576:	4501                	li	a0,0
    80004578:	a84d                	j	8000462a <sys_unlink+0x1c4>
    end_op();
    8000457a:	00002097          	auipc	ra,0x2
    8000457e:	872080e7          	jalr	-1934(ra) # 80005dec <end_op>
    return -1;
    80004582:	557d                	li	a0,-1
    80004584:	a05d                	j	8000462a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80004586:	00005517          	auipc	a0,0x5
    8000458a:	39a50513          	add	a0,a0,922 # 80009920 <syscalls+0x148>
    8000458e:	ffffd097          	auipc	ra,0xffffd
    80004592:	c76080e7          	jalr	-906(ra) # 80001204 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004596:	04c92703          	lw	a4,76(s2)
    8000459a:	02000793          	li	a5,32
    8000459e:	f6e7f9e3          	bgeu	a5,a4,80004510 <sys_unlink+0xaa>
    800045a2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045a6:	4741                	li	a4,16
    800045a8:	86ce                	mv	a3,s3
    800045aa:	f1840613          	add	a2,s0,-232
    800045ae:	4581                	li	a1,0
    800045b0:	854a                	mv	a0,s2
    800045b2:	00001097          	auipc	ra,0x1
    800045b6:	de2080e7          	jalr	-542(ra) # 80005394 <readi>
    800045ba:	47c1                	li	a5,16
    800045bc:	00f51b63          	bne	a0,a5,800045d2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800045c0:	f1845783          	lhu	a5,-232(s0)
    800045c4:	e7a1                	bnez	a5,8000460c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800045c6:	29c1                	addw	s3,s3,16
    800045c8:	04c92783          	lw	a5,76(s2)
    800045cc:	fcf9ede3          	bltu	s3,a5,800045a6 <sys_unlink+0x140>
    800045d0:	b781                	j	80004510 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800045d2:	00005517          	auipc	a0,0x5
    800045d6:	36650513          	add	a0,a0,870 # 80009938 <syscalls+0x160>
    800045da:	ffffd097          	auipc	ra,0xffffd
    800045de:	c2a080e7          	jalr	-982(ra) # 80001204 <panic>
    panic("unlink: writei");
    800045e2:	00005517          	auipc	a0,0x5
    800045e6:	36e50513          	add	a0,a0,878 # 80009950 <syscalls+0x178>
    800045ea:	ffffd097          	auipc	ra,0xffffd
    800045ee:	c1a080e7          	jalr	-998(ra) # 80001204 <panic>
    dp->nlink--;
    800045f2:	04a4d783          	lhu	a5,74(s1)
    800045f6:	37fd                	addw	a5,a5,-1
    800045f8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800045fc:	8526                	mv	a0,s1
    800045fe:	00001097          	auipc	ra,0x1
    80004602:	a16080e7          	jalr	-1514(ra) # 80005014 <iupdate>
    80004606:	b781                	j	80004546 <sys_unlink+0xe0>
    return -1;
    80004608:	557d                	li	a0,-1
    8000460a:	a005                	j	8000462a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000460c:	854a                	mv	a0,s2
    8000460e:	00001097          	auipc	ra,0x1
    80004612:	d34080e7          	jalr	-716(ra) # 80005342 <iunlockput>
  iunlockput(dp);
    80004616:	8526                	mv	a0,s1
    80004618:	00001097          	auipc	ra,0x1
    8000461c:	d2a080e7          	jalr	-726(ra) # 80005342 <iunlockput>
  end_op();
    80004620:	00001097          	auipc	ra,0x1
    80004624:	7cc080e7          	jalr	1996(ra) # 80005dec <end_op>
  return -1;
    80004628:	557d                	li	a0,-1
}
    8000462a:	70ae                	ld	ra,232(sp)
    8000462c:	740e                	ld	s0,224(sp)
    8000462e:	64ee                	ld	s1,216(sp)
    80004630:	694e                	ld	s2,208(sp)
    80004632:	69ae                	ld	s3,200(sp)
    80004634:	616d                	add	sp,sp,240
    80004636:	8082                	ret

0000000080004638 <sys_open>:

uint64
sys_open(void)
{
    80004638:	7131                	add	sp,sp,-192
    8000463a:	fd06                	sd	ra,184(sp)
    8000463c:	f922                	sd	s0,176(sp)
    8000463e:	f526                	sd	s1,168(sp)
    80004640:	f14a                	sd	s2,160(sp)
    80004642:	ed4e                	sd	s3,152(sp)
    80004644:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004646:	f4c40593          	add	a1,s0,-180
    8000464a:	4505                	li	a0,1
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	132080e7          	jalr	306(ra) # 8000377e <arg_uint64>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004654:	08000613          	li	a2,128
    80004658:	f5040593          	add	a1,s0,-176
    8000465c:	4501                	li	a0,0
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	1dc080e7          	jalr	476(ra) # 8000383a <argstr>
    80004666:	87aa                	mv	a5,a0
    return -1;
    80004668:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000466a:	0a07c863          	bltz	a5,8000471a <sys_open+0xe2>

  begin_op();
    8000466e:	00001097          	auipc	ra,0x1
    80004672:	704080e7          	jalr	1796(ra) # 80005d72 <begin_op>

  if(omode & O_CREATE){
    80004676:	f4c42783          	lw	a5,-180(s0)
    8000467a:	2007f793          	and	a5,a5,512
    8000467e:	cbdd                	beqz	a5,80004734 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80004680:	4681                	li	a3,0
    80004682:	4601                	li	a2,0
    80004684:	4589                	li	a1,2
    80004686:	f5040513          	add	a0,s0,-176
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	97a080e7          	jalr	-1670(ra) # 80004004 <create>
    80004692:	84aa                	mv	s1,a0
    if(ip == 0){
    80004694:	c951                	beqz	a0,80004728 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004696:	04449703          	lh	a4,68(s1)
    8000469a:	478d                	li	a5,3
    8000469c:	00f71763          	bne	a4,a5,800046aa <sys_open+0x72>
    800046a0:	0464d703          	lhu	a4,70(s1)
    800046a4:	47a5                	li	a5,9
    800046a6:	0ce7ec63          	bltu	a5,a4,8000477e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800046aa:	00002097          	auipc	ra,0x2
    800046ae:	9a6080e7          	jalr	-1626(ra) # 80006050 <filealloc>
    800046b2:	892a                	mv	s2,a0
    800046b4:	c56d                	beqz	a0,8000479e <sys_open+0x166>
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	90c080e7          	jalr	-1780(ra) # 80003fc2 <fdalloc>
    800046be:	89aa                	mv	s3,a0
    800046c0:	0c054a63          	bltz	a0,80004794 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800046c4:	04449703          	lh	a4,68(s1)
    800046c8:	478d                	li	a5,3
    800046ca:	0ef70563          	beq	a4,a5,800047b4 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800046ce:	4789                	li	a5,2
    800046d0:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800046d4:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800046d8:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800046dc:	f4c42783          	lw	a5,-180(s0)
    800046e0:	0017c713          	xor	a4,a5,1
    800046e4:	8b05                	and	a4,a4,1
    800046e6:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800046ea:	0037f713          	and	a4,a5,3
    800046ee:	00e03733          	snez	a4,a4
    800046f2:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800046f6:	4007f793          	and	a5,a5,1024
    800046fa:	c791                	beqz	a5,80004706 <sys_open+0xce>
    800046fc:	04449703          	lh	a4,68(s1)
    80004700:	4789                	li	a5,2
    80004702:	0cf70063          	beq	a4,a5,800047c2 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80004706:	8526                	mv	a0,s1
    80004708:	00001097          	auipc	ra,0x1
    8000470c:	a9a080e7          	jalr	-1382(ra) # 800051a2 <iunlock>
  end_op();
    80004710:	00001097          	auipc	ra,0x1
    80004714:	6dc080e7          	jalr	1756(ra) # 80005dec <end_op>

  return fd;
    80004718:	854e                	mv	a0,s3
}
    8000471a:	70ea                	ld	ra,184(sp)
    8000471c:	744a                	ld	s0,176(sp)
    8000471e:	74aa                	ld	s1,168(sp)
    80004720:	790a                	ld	s2,160(sp)
    80004722:	69ea                	ld	s3,152(sp)
    80004724:	6129                	add	sp,sp,192
    80004726:	8082                	ret
      end_op();
    80004728:	00001097          	auipc	ra,0x1
    8000472c:	6c4080e7          	jalr	1732(ra) # 80005dec <end_op>
      return -1;
    80004730:	557d                	li	a0,-1
    80004732:	b7e5                	j	8000471a <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80004734:	f5040513          	add	a0,s0,-176
    80004738:	00002097          	auipc	ra,0x2
    8000473c:	066080e7          	jalr	102(ra) # 8000679e <namei>
    80004740:	84aa                	mv	s1,a0
    80004742:	c905                	beqz	a0,80004772 <sys_open+0x13a>
    ilock(ip);
    80004744:	00001097          	auipc	ra,0x1
    80004748:	99c080e7          	jalr	-1636(ra) # 800050e0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000474c:	04449703          	lh	a4,68(s1)
    80004750:	4785                	li	a5,1
    80004752:	f4f712e3          	bne	a4,a5,80004696 <sys_open+0x5e>
    80004756:	f4c42783          	lw	a5,-180(s0)
    8000475a:	dba1                	beqz	a5,800046aa <sys_open+0x72>
      iunlockput(ip);
    8000475c:	8526                	mv	a0,s1
    8000475e:	00001097          	auipc	ra,0x1
    80004762:	be4080e7          	jalr	-1052(ra) # 80005342 <iunlockput>
      end_op();
    80004766:	00001097          	auipc	ra,0x1
    8000476a:	686080e7          	jalr	1670(ra) # 80005dec <end_op>
      return -1;
    8000476e:	557d                	li	a0,-1
    80004770:	b76d                	j	8000471a <sys_open+0xe2>
      end_op();
    80004772:	00001097          	auipc	ra,0x1
    80004776:	67a080e7          	jalr	1658(ra) # 80005dec <end_op>
      return -1;
    8000477a:	557d                	li	a0,-1
    8000477c:	bf79                	j	8000471a <sys_open+0xe2>
    iunlockput(ip);
    8000477e:	8526                	mv	a0,s1
    80004780:	00001097          	auipc	ra,0x1
    80004784:	bc2080e7          	jalr	-1086(ra) # 80005342 <iunlockput>
    end_op();
    80004788:	00001097          	auipc	ra,0x1
    8000478c:	664080e7          	jalr	1636(ra) # 80005dec <end_op>
    return -1;
    80004790:	557d                	li	a0,-1
    80004792:	b761                	j	8000471a <sys_open+0xe2>
      fileclose(f);
    80004794:	854a                	mv	a0,s2
    80004796:	00002097          	auipc	ra,0x2
    8000479a:	976080e7          	jalr	-1674(ra) # 8000610c <fileclose>
    iunlockput(ip);
    8000479e:	8526                	mv	a0,s1
    800047a0:	00001097          	auipc	ra,0x1
    800047a4:	ba2080e7          	jalr	-1118(ra) # 80005342 <iunlockput>
    end_op();
    800047a8:	00001097          	auipc	ra,0x1
    800047ac:	644080e7          	jalr	1604(ra) # 80005dec <end_op>
    return -1;
    800047b0:	557d                	li	a0,-1
    800047b2:	b7a5                	j	8000471a <sys_open+0xe2>
    f->type = FD_DEVICE;
    800047b4:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800047b8:	04649783          	lh	a5,70(s1)
    800047bc:	02f91223          	sh	a5,36(s2)
    800047c0:	bf21                	j	800046d8 <sys_open+0xa0>
    itrunc(ip);
    800047c2:	8526                	mv	a0,s1
    800047c4:	00001097          	auipc	ra,0x1
    800047c8:	a2a080e7          	jalr	-1494(ra) # 800051ee <itrunc>
    800047cc:	bf2d                	j	80004706 <sys_open+0xce>

00000000800047ce <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800047ce:	7175                	add	sp,sp,-144
    800047d0:	e506                	sd	ra,136(sp)
    800047d2:	e122                	sd	s0,128(sp)
    800047d4:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800047d6:	00001097          	auipc	ra,0x1
    800047da:	59c080e7          	jalr	1436(ra) # 80005d72 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800047de:	08000613          	li	a2,128
    800047e2:	f7040593          	add	a1,s0,-144
    800047e6:	4501                	li	a0,0
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	052080e7          	jalr	82(ra) # 8000383a <argstr>
    800047f0:	02054963          	bltz	a0,80004822 <sys_mkdir+0x54>
    800047f4:	4681                	li	a3,0
    800047f6:	4601                	li	a2,0
    800047f8:	4585                	li	a1,1
    800047fa:	f7040513          	add	a0,s0,-144
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	806080e7          	jalr	-2042(ra) # 80004004 <create>
    80004806:	cd11                	beqz	a0,80004822 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004808:	00001097          	auipc	ra,0x1
    8000480c:	b3a080e7          	jalr	-1222(ra) # 80005342 <iunlockput>
  end_op();
    80004810:	00001097          	auipc	ra,0x1
    80004814:	5dc080e7          	jalr	1500(ra) # 80005dec <end_op>
  return 0;
    80004818:	4501                	li	a0,0
}
    8000481a:	60aa                	ld	ra,136(sp)
    8000481c:	640a                	ld	s0,128(sp)
    8000481e:	6149                	add	sp,sp,144
    80004820:	8082                	ret
    end_op();
    80004822:	00001097          	auipc	ra,0x1
    80004826:	5ca080e7          	jalr	1482(ra) # 80005dec <end_op>
    return -1;
    8000482a:	557d                	li	a0,-1
    8000482c:	b7fd                	j	8000481a <sys_mkdir+0x4c>

000000008000482e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000482e:	7135                	add	sp,sp,-160
    80004830:	ed06                	sd	ra,152(sp)
    80004832:	e922                	sd	s0,144(sp)
    80004834:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80004836:	00001097          	auipc	ra,0x1
    8000483a:	53c080e7          	jalr	1340(ra) # 80005d72 <begin_op>
  argint(1, &major);
    8000483e:	f6c40593          	add	a1,s0,-148
    80004842:	4505                	li	a0,1
    80004844:	fffff097          	auipc	ra,0xfffff
    80004848:	f3a080e7          	jalr	-198(ra) # 8000377e <arg_uint64>
  argint(2, &minor);
    8000484c:	f6840593          	add	a1,s0,-152
    80004850:	4509                	li	a0,2
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	f2c080e7          	jalr	-212(ra) # 8000377e <arg_uint64>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000485a:	08000613          	li	a2,128
    8000485e:	f7040593          	add	a1,s0,-144
    80004862:	4501                	li	a0,0
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	fd6080e7          	jalr	-42(ra) # 8000383a <argstr>
    8000486c:	02054b63          	bltz	a0,800048a2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80004870:	f6841683          	lh	a3,-152(s0)
    80004874:	f6c41603          	lh	a2,-148(s0)
    80004878:	458d                	li	a1,3
    8000487a:	f7040513          	add	a0,s0,-144
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	786080e7          	jalr	1926(ra) # 80004004 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80004886:	cd11                	beqz	a0,800048a2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80004888:	00001097          	auipc	ra,0x1
    8000488c:	aba080e7          	jalr	-1350(ra) # 80005342 <iunlockput>
  end_op();
    80004890:	00001097          	auipc	ra,0x1
    80004894:	55c080e7          	jalr	1372(ra) # 80005dec <end_op>
  return 0;
    80004898:	4501                	li	a0,0
}
    8000489a:	60ea                	ld	ra,152(sp)
    8000489c:	644a                	ld	s0,144(sp)
    8000489e:	610d                	add	sp,sp,160
    800048a0:	8082                	ret
    end_op();
    800048a2:	00001097          	auipc	ra,0x1
    800048a6:	54a080e7          	jalr	1354(ra) # 80005dec <end_op>
    return -1;
    800048aa:	557d                	li	a0,-1
    800048ac:	b7fd                	j	8000489a <sys_mknod+0x6c>

00000000800048ae <sys_chdir>:

uint64
sys_chdir(void)
{
    800048ae:	7135                	add	sp,sp,-160
    800048b0:	ed06                	sd	ra,152(sp)
    800048b2:	e922                	sd	s0,144(sp)
    800048b4:	e526                	sd	s1,136(sp)
    800048b6:	e14a                	sd	s2,128(sp)
    800048b8:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800048ba:	ffffe097          	auipc	ra,0xffffe
    800048be:	8aa080e7          	jalr	-1878(ra) # 80002164 <myproc>
    800048c2:	892a                	mv	s2,a0
  
  begin_op();
    800048c4:	00001097          	auipc	ra,0x1
    800048c8:	4ae080e7          	jalr	1198(ra) # 80005d72 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800048cc:	08000613          	li	a2,128
    800048d0:	f6040593          	add	a1,s0,-160
    800048d4:	4501                	li	a0,0
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	f64080e7          	jalr	-156(ra) # 8000383a <argstr>
    800048de:	04054b63          	bltz	a0,80004934 <sys_chdir+0x86>
    800048e2:	f6040513          	add	a0,s0,-160
    800048e6:	00002097          	auipc	ra,0x2
    800048ea:	eb8080e7          	jalr	-328(ra) # 8000679e <namei>
    800048ee:	84aa                	mv	s1,a0
    800048f0:	c131                	beqz	a0,80004934 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	7ee080e7          	jalr	2030(ra) # 800050e0 <ilock>
  if(ip->type != T_DIR){
    800048fa:	04449703          	lh	a4,68(s1)
    800048fe:	4785                	li	a5,1
    80004900:	04f71063          	bne	a4,a5,80004940 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80004904:	8526                	mv	a0,s1
    80004906:	00001097          	auipc	ra,0x1
    8000490a:	89c080e7          	jalr	-1892(ra) # 800051a2 <iunlock>
  iput(p->cwd);
    8000490e:	0e093503          	ld	a0,224(s2)
    80004912:	00001097          	auipc	ra,0x1
    80004916:	988080e7          	jalr	-1656(ra) # 8000529a <iput>
  end_op();
    8000491a:	00001097          	auipc	ra,0x1
    8000491e:	4d2080e7          	jalr	1234(ra) # 80005dec <end_op>
  p->cwd = ip;
    80004922:	0e993023          	sd	s1,224(s2)
  return 0;
    80004926:	4501                	li	a0,0
}
    80004928:	60ea                	ld	ra,152(sp)
    8000492a:	644a                	ld	s0,144(sp)
    8000492c:	64aa                	ld	s1,136(sp)
    8000492e:	690a                	ld	s2,128(sp)
    80004930:	610d                	add	sp,sp,160
    80004932:	8082                	ret
    end_op();
    80004934:	00001097          	auipc	ra,0x1
    80004938:	4b8080e7          	jalr	1208(ra) # 80005dec <end_op>
    return -1;
    8000493c:	557d                	li	a0,-1
    8000493e:	b7ed                	j	80004928 <sys_chdir+0x7a>
    iunlockput(ip);
    80004940:	8526                	mv	a0,s1
    80004942:	00001097          	auipc	ra,0x1
    80004946:	a00080e7          	jalr	-1536(ra) # 80005342 <iunlockput>
    end_op();
    8000494a:	00001097          	auipc	ra,0x1
    8000494e:	4a2080e7          	jalr	1186(ra) # 80005dec <end_op>
    return -1;
    80004952:	557d                	li	a0,-1
    80004954:	bfd1                	j	80004928 <sys_chdir+0x7a>

0000000080004956 <sys_pipe>:
//   return -1;
// }

uint64
sys_pipe(void)
{
    80004956:	7139                	add	sp,sp,-64
    80004958:	fc06                	sd	ra,56(sp)
    8000495a:	f822                	sd	s0,48(sp)
    8000495c:	f426                	sd	s1,40(sp)
    8000495e:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80004960:	ffffe097          	auipc	ra,0xffffe
    80004964:	804080e7          	jalr	-2044(ra) # 80002164 <myproc>
    80004968:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000496a:	fd840593          	add	a1,s0,-40
    8000496e:	4501                	li	a0,0
    80004970:	fffff097          	auipc	ra,0xfffff
    80004974:	e0e080e7          	jalr	-498(ra) # 8000377e <arg_uint64>
  if(pipealloc(&rf, &wf) < 0)
    80004978:	fc840593          	add	a1,s0,-56
    8000497c:	fd040513          	add	a0,s0,-48
    80004980:	00002097          	auipc	ra,0x2
    80004984:	06a080e7          	jalr	106(ra) # 800069ea <pipealloc>
    return -1;
    80004988:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000498a:	0c054463          	bltz	a0,80004a52 <sys_pipe+0xfc>
  fd0 = -1;
    8000498e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80004992:	fd043503          	ld	a0,-48(s0)
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	62c080e7          	jalr	1580(ra) # 80003fc2 <fdalloc>
    8000499e:	fca42223          	sw	a0,-60(s0)
    800049a2:	08054b63          	bltz	a0,80004a38 <sys_pipe+0xe2>
    800049a6:	fc843503          	ld	a0,-56(s0)
    800049aa:	fffff097          	auipc	ra,0xfffff
    800049ae:	618080e7          	jalr	1560(ra) # 80003fc2 <fdalloc>
    800049b2:	fca42023          	sw	a0,-64(s0)
    800049b6:	06054863          	bltz	a0,80004a26 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pgtbl, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800049ba:	4691                	li	a3,4
    800049bc:	fc440613          	add	a2,s0,-60
    800049c0:	fd843583          	ld	a1,-40(s0)
    800049c4:	64a8                	ld	a0,72(s1)
    800049c6:	ffffd097          	auipc	ra,0xffffd
    800049ca:	56a080e7          	jalr	1386(ra) # 80001f30 <copyout>
    800049ce:	02054063          	bltz	a0,800049ee <sys_pipe+0x98>
     copyout(p->pgtbl, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800049d2:	4691                	li	a3,4
    800049d4:	fc040613          	add	a2,s0,-64
    800049d8:	fd843583          	ld	a1,-40(s0)
    800049dc:	0591                	add	a1,a1,4
    800049de:	64a8                	ld	a0,72(s1)
    800049e0:	ffffd097          	auipc	ra,0xffffd
    800049e4:	550080e7          	jalr	1360(ra) # 80001f30 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800049e8:	4781                	li	a5,0
  if(copyout(p->pgtbl, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800049ea:	06055463          	bgez	a0,80004a52 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800049ee:	fc442783          	lw	a5,-60(s0)
    800049f2:	07b1                	add	a5,a5,12
    800049f4:	078e                	sll	a5,a5,0x3
    800049f6:	97a6                	add	a5,a5,s1
    800049f8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800049fc:	fc042783          	lw	a5,-64(s0)
    80004a00:	07b1                	add	a5,a5,12
    80004a02:	078e                	sll	a5,a5,0x3
    80004a04:	94be                	add	s1,s1,a5
    80004a06:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80004a0a:	fd043503          	ld	a0,-48(s0)
    80004a0e:	00001097          	auipc	ra,0x1
    80004a12:	6fe080e7          	jalr	1790(ra) # 8000610c <fileclose>
    fileclose(wf);
    80004a16:	fc843503          	ld	a0,-56(s0)
    80004a1a:	00001097          	auipc	ra,0x1
    80004a1e:	6f2080e7          	jalr	1778(ra) # 8000610c <fileclose>
    return -1;
    80004a22:	57fd                	li	a5,-1
    80004a24:	a03d                	j	80004a52 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80004a26:	fc442783          	lw	a5,-60(s0)
    80004a2a:	0007c763          	bltz	a5,80004a38 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80004a2e:	07b1                	add	a5,a5,12
    80004a30:	078e                	sll	a5,a5,0x3
    80004a32:	97a6                	add	a5,a5,s1
    80004a34:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80004a38:	fd043503          	ld	a0,-48(s0)
    80004a3c:	00001097          	auipc	ra,0x1
    80004a40:	6d0080e7          	jalr	1744(ra) # 8000610c <fileclose>
    fileclose(wf);
    80004a44:	fc843503          	ld	a0,-56(s0)
    80004a48:	00001097          	auipc	ra,0x1
    80004a4c:	6c4080e7          	jalr	1732(ra) # 8000610c <fileclose>
    return -1;
    80004a50:	57fd                	li	a5,-1
}
    80004a52:	853e                	mv	a0,a5
    80004a54:	70e2                	ld	ra,56(sp)
    80004a56:	7442                	ld	s0,48(sp)
    80004a58:	74a2                	ld	s1,40(sp)
    80004a5a:	6121                	add	sp,sp,64
    80004a5c:	8082                	ret

0000000080004a5e <sys_lseek>:
// int fd
// uint32 offset
// int flags (见LSEEK_xxx)
// 成功返回新的偏移量, 失败返回-1
uint64 sys_lseek()
{
    80004a5e:	1101                	add	sp,sp,-32
    80004a60:	ec06                	sd	ra,24(sp)
    80004a62:	e822                	sd	s0,16(sp)
    80004a64:	1000                	add	s0,sp,32
    struct file* file;
    uint32 offset;
    int flags;

    if(argfd(0, 0, &file) < 0)
    80004a66:	fe840613          	add	a2,s0,-24
    80004a6a:	4581                	li	a1,0
    80004a6c:	4501                	li	a0,0
    80004a6e:	fffff097          	auipc	ra,0xfffff
    80004a72:	4f4080e7          	jalr	1268(ra) # 80003f62 <argfd>
    80004a76:	87aa                	mv	a5,a0
        return -1;
    80004a78:	557d                	li	a0,-1
    if(argfd(0, 0, &file) < 0)
    80004a7a:	0207cc63          	bltz	a5,80004ab2 <sys_lseek+0x54>
    arg_uint32(1, &offset);
    80004a7e:	fe440593          	add	a1,s0,-28
    80004a82:	4505                	li	a0,1
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	cda080e7          	jalr	-806(ra) # 8000375e <arg_uint32>
    arg_uint32(2, (uint32*)(&flags));
    80004a8c:	fe040593          	add	a1,s0,-32
    80004a90:	4509                	li	a0,2
    80004a92:	fffff097          	auipc	ra,0xfffff
    80004a96:	ccc080e7          	jalr	-820(ra) # 8000375e <arg_uint32>

    return file_lseek(file, offset, flags);
    80004a9a:	fe042603          	lw	a2,-32(s0)
    80004a9e:	fe442583          	lw	a1,-28(s0)
    80004aa2:	fe843503          	ld	a0,-24(s0)
    80004aa6:	00002097          	auipc	ra,0x2
    80004aaa:	992080e7          	jalr	-1646(ra) # 80006438 <file_lseek>
    80004aae:	1502                	sll	a0,a0,0x20
    80004ab0:	9101                	srl	a0,a0,0x20
}
    80004ab2:	60e2                	ld	ra,24(sp)
    80004ab4:	6442                	ld	s0,16(sp)
    80004ab6:	6105                	add	sp,sp,32
    80004ab8:	8082                	ret

0000000080004aba <sys_alloc_block>:
//     inode_unlock(file->ip);

//     return len;
// }

uint64 sys_alloc_block(void) {
    80004aba:	1101                	add	sp,sp,-32
    80004abc:	ec06                	sd	ra,24(sp)
    80004abe:	e822                	sd	s0,16(sp)
    80004ac0:	e426                	sd	s1,8(sp)
    80004ac2:	e04a                	sd	s2,0(sp)
    80004ac4:	1000                	add	s0,sp,32
    begin_op();
    80004ac6:	00001097          	auipc	ra,0x1
    80004aca:	2ac080e7          	jalr	684(ra) # 80005d72 <begin_op>
    
    // 使用根目录而不是当前目录
    struct inode *root = namei("/");
    80004ace:	00005517          	auipc	a0,0x5
    80004ad2:	a0a50513          	add	a0,a0,-1526 # 800094d8 <digits+0x2e8>
    80004ad6:	00002097          	auipc	ra,0x2
    80004ada:	cc8080e7          	jalr	-824(ra) # 8000679e <namei>
    if(root == 0) {
    80004ade:	c921                	beqz	a0,80004b2e <sys_alloc_block+0x74>
    80004ae0:	84aa                	mv	s1,a0
        end_op();
        return -1;
    }
    
    ilock(root);  // 加锁
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	5fe080e7          	jalr	1534(ra) # 800050e0 <ilock>
    
    uint bn = balloc(root->dev);
    80004aea:	4088                	lw	a0,0(s1)
    80004aec:	00002097          	auipc	ra,0x2
    80004af0:	232080e7          	jalr	562(ra) # 80006d1e <balloc>
    80004af4:	0005091b          	sext.w	s2,a0
    printf(COLOR_GREEN "sys_alloc_block: allocated block %d\n" COLOR_RESET, bn);
    80004af8:	85ca                	mv	a1,s2
    80004afa:	00005517          	auipc	a0,0x5
    80004afe:	e6650513          	add	a0,a0,-410 # 80009960 <syscalls+0x188>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	74c080e7          	jalr	1868(ra) # 8000124e <printf>
    
    iunlockput(root);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	00001097          	auipc	ra,0x1
    80004b10:	836080e7          	jalr	-1994(ra) # 80005342 <iunlockput>
    end_op();
    80004b14:	00001097          	auipc	ra,0x1
    80004b18:	2d8080e7          	jalr	728(ra) # 80005dec <end_op>
    return bn;
    80004b1c:	02091513          	sll	a0,s2,0x20
    80004b20:	9101                	srl	a0,a0,0x20
}
    80004b22:	60e2                	ld	ra,24(sp)
    80004b24:	6442                	ld	s0,16(sp)
    80004b26:	64a2                	ld	s1,8(sp)
    80004b28:	6902                	ld	s2,0(sp)
    80004b2a:	6105                	add	sp,sp,32
    80004b2c:	8082                	ret
        end_op();
    80004b2e:	00001097          	auipc	ra,0x1
    80004b32:	2be080e7          	jalr	702(ra) # 80005dec <end_op>
        return -1;
    80004b36:	557d                	li	a0,-1
    80004b38:	b7ed                	j	80004b22 <sys_alloc_block+0x68>

0000000080004b3a <sys_free_block>:

// 释放一个数据块
uint64 sys_free_block(void) {
    80004b3a:	7179                	add	sp,sp,-48
    80004b3c:	f406                	sd	ra,40(sp)
    80004b3e:	f022                	sd	s0,32(sp)
    80004b40:	ec26                	sd	s1,24(sp)
    80004b42:	1800                	add	s0,sp,48
    uint bn;
    
    // 检查参数
    argint(0, (int*)&bn) ;
    80004b44:	fdc40593          	add	a1,s0,-36
    80004b48:	4501                	li	a0,0
    80004b4a:	fffff097          	auipc	ra,0xfffff
    80004b4e:	c34080e7          	jalr	-972(ra) # 8000377e <arg_uint64>
    
    printf(COLOR_GREEN "sys_free_block: freeing block %d\n" COLOR_RESET , bn);
    80004b52:	fdc42583          	lw	a1,-36(s0)
    80004b56:	00005517          	auipc	a0,0x5
    80004b5a:	e3a50513          	add	a0,a0,-454 # 80009990 <syscalls+0x1b8>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	6f0080e7          	jalr	1776(ra) # 8000124e <printf>
    
    begin_op();
    80004b66:	00001097          	auipc	ra,0x1
    80004b6a:	20c080e7          	jalr	524(ra) # 80005d72 <begin_op>
    
    // 使用根目录
    struct inode *root = namei("/");
    80004b6e:	00005517          	auipc	a0,0x5
    80004b72:	96a50513          	add	a0,a0,-1686 # 800094d8 <digits+0x2e8>
    80004b76:	00002097          	auipc	ra,0x2
    80004b7a:	c28080e7          	jalr	-984(ra) # 8000679e <namei>
    if(root == 0) {
    80004b7e:	cd05                	beqz	a0,80004bb6 <sys_free_block+0x7c>
    80004b80:	84aa                	mv	s1,a0
        end_op();
        return -1;
    }
    
    // 锁定根目录
    ilock(root);
    80004b82:	00000097          	auipc	ra,0x0
    80004b86:	55e080e7          	jalr	1374(ra) # 800050e0 <ilock>
    
    // 释放块
    bfree(root->dev, bn);
    80004b8a:	fdc42583          	lw	a1,-36(s0)
    80004b8e:	4088                	lw	a0,0(s1)
    80004b90:	00002097          	auipc	ra,0x2
    80004b94:	2c0080e7          	jalr	704(ra) # 80006e50 <bfree>
    
    // 解锁
    iunlockput(root);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	00000097          	auipc	ra,0x0
    80004b9e:	7a8080e7          	jalr	1960(ra) # 80005342 <iunlockput>
    
    end_op();
    80004ba2:	00001097          	auipc	ra,0x1
    80004ba6:	24a080e7          	jalr	586(ra) # 80005dec <end_op>
    
    return 0;
    80004baa:	4501                	li	a0,0
}
    80004bac:	70a2                	ld	ra,40(sp)
    80004bae:	7402                	ld	s0,32(sp)
    80004bb0:	64e2                	ld	s1,24(sp)
    80004bb2:	6145                	add	sp,sp,48
    80004bb4:	8082                	ret
        printf(COLOR_RED "sys_free_block: root not found\n" COLOR_RESET);
    80004bb6:	00005517          	auipc	a0,0x5
    80004bba:	e0a50513          	add	a0,a0,-502 # 800099c0 <syscalls+0x1e8>
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	690080e7          	jalr	1680(ra) # 8000124e <printf>
        end_op();
    80004bc6:	00001097          	auipc	ra,0x1
    80004bca:	226080e7          	jalr	550(ra) # 80005dec <end_op>
        return -1;
    80004bce:	557d                	li	a0,-1
    80004bd0:	bff1                	j	80004bac <sys_free_block+0x72>

0000000080004bd2 <sys_show_buf>:

uint64 sys_show_buf(void) {
    80004bd2:	1141                	add	sp,sp,-16
    80004bd4:	e406                	sd	ra,8(sp)
    80004bd6:	e022                	sd	s0,0(sp)
    80004bd8:	0800                	add	s0,sp,16
    buf_print();
    80004bda:	00001097          	auipc	ra,0x1
    80004bde:	e16080e7          	jalr	-490(ra) # 800059f0 <buf_print>
    return 0;
}
    80004be2:	4501                	li	a0,0
    80004be4:	60a2                	ld	ra,8(sp)
    80004be6:	6402                	ld	s0,0(sp)
    80004be8:	0141                	add	sp,sp,16
    80004bea:	8082                	ret

0000000080004bec <sys_write_block>:

uint64 sys_write_block(void) {
    80004bec:	7179                	add	sp,sp,-48
    80004bee:	f406                	sd	ra,40(sp)
    80004bf0:	f022                	sd	s0,32(sp)
    80004bf2:	ec26                	sd	s1,24(sp)
    80004bf4:	1800                	add	s0,sp,48
    uint64 buf_handle;
    uint64 addr;
    struct buf *b;

    argaddr(0, &buf_handle);
    80004bf6:	fd840593          	add	a1,s0,-40
    80004bfa:	4501                	li	a0,0
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	b82080e7          	jalr	-1150(ra) # 8000377e <arg_uint64>
    argaddr(1, &addr);
    80004c04:	fd040593          	add	a1,s0,-48
    80004c08:	4505                	li	a0,1
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	b74080e7          	jalr	-1164(ra) # 8000377e <arg_uint64>

    b = (struct buf*)buf_handle;
    80004c12:	fd843483          	ld	s1,-40(s0)
    if(b == 0) return -1;
    80004c16:	557d                	li	a0,-1
    80004c18:	c0a1                	beqz	s1,80004c58 <sys_write_block+0x6c>

    begin_op(); // Need op for bwrite? bwrite calls virtio_disk_rw. log_write calls bwrite.
    80004c1a:	00001097          	auipc	ra,0x1
    80004c1e:	158080e7          	jalr	344(ra) # 80005d72 <begin_op>
    // If we use logging, we should use log_write. But here we use bwrite directly.
    // bwrite expects b to be locked. It is locked.
    
    if(copyin(myproc()->pgtbl, (char*)b->data, addr, BSIZE) < 0){
    80004c22:	ffffd097          	auipc	ra,0xffffd
    80004c26:	542080e7          	jalr	1346(ra) # 80002164 <myproc>
    80004c2a:	40000693          	li	a3,1024
    80004c2e:	fd043603          	ld	a2,-48(s0)
    80004c32:	05848593          	add	a1,s1,88
    80004c36:	6528                	ld	a0,72(a0)
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	38a080e7          	jalr	906(ra) # 80001fc2 <copyin>
    80004c40:	02054163          	bltz	a0,80004c62 <sys_write_block+0x76>
        end_op();
        return -1;
    }
    bwrite(b);
    80004c44:	8526                	mv	a0,s1
    80004c46:	00001097          	auipc	ra,0x1
    80004c4a:	c58080e7          	jalr	-936(ra) # 8000589e <bwrite>
    end_op();
    80004c4e:	00001097          	auipc	ra,0x1
    80004c52:	19e080e7          	jalr	414(ra) # 80005dec <end_op>
    return 0;
    80004c56:	4501                	li	a0,0
}
    80004c58:	70a2                	ld	ra,40(sp)
    80004c5a:	7402                	ld	s0,32(sp)
    80004c5c:	64e2                	ld	s1,24(sp)
    80004c5e:	6145                	add	sp,sp,48
    80004c60:	8082                	ret
        end_op();
    80004c62:	00001097          	auipc	ra,0x1
    80004c66:	18a080e7          	jalr	394(ra) # 80005dec <end_op>
        return -1;
    80004c6a:	557d                	li	a0,-1
    80004c6c:	b7f5                	j	80004c58 <sys_write_block+0x6c>

0000000080004c6e <sys_read_block>:


uint64 sys_read_block(void) {
    80004c6e:	7179                	add	sp,sp,-48
    80004c70:	f406                	sd	ra,40(sp)
    80004c72:	f022                	sd	s0,32(sp)
    80004c74:	ec26                	sd	s1,24(sp)
    80004c76:	1800                	add	s0,sp,48
    uint64 blockno;
    uint64 addr;
    struct buf *b;
    
    argint(0, &blockno);
    80004c78:	fd840593          	add	a1,s0,-40
    80004c7c:	4501                	li	a0,0
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	b00080e7          	jalr	-1280(ra) # 8000377e <arg_uint64>
    argaddr(1, &addr);
    80004c86:	fd040593          	add	a1,s0,-48
    80004c8a:	4505                	li	a0,1
    80004c8c:	fffff097          	auipc	ra,0xfffff
    80004c90:	af2080e7          	jalr	-1294(ra) # 8000377e <arg_uint64>

    printf(COLOR_BLUE"sys_read_block: reading block %d into addr %p\n"COLOR_RESET, (int)blockno, (void*)addr);
    80004c94:	fd043603          	ld	a2,-48(s0)
    80004c98:	fd842583          	lw	a1,-40(s0)
    80004c9c:	00005517          	auipc	a0,0x5
    80004ca0:	d5450513          	add	a0,a0,-684 # 800099f0 <syscalls+0x218>
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	5aa080e7          	jalr	1450(ra) # 8000124e <printf>

    b = bread(ROOTDEV, (uint)blockno);
    80004cac:	fd842583          	lw	a1,-40(s0)
    80004cb0:	4505                	li	a0,1
    80004cb2:	00001097          	auipc	ra,0x1
    80004cb6:	afa080e7          	jalr	-1286(ra) # 800057ac <bread>
    80004cba:	84aa                	mv	s1,a0
    if(copyout(myproc()->pgtbl, addr, (char*)b->data, BSIZE) < 0) {
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	4a8080e7          	jalr	1192(ra) # 80002164 <myproc>
    80004cc4:	40000693          	li	a3,1024
    80004cc8:	05848613          	add	a2,s1,88
    80004ccc:	fd043583          	ld	a1,-48(s0)
    80004cd0:	6528                	ld	a0,72(a0)
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	25e080e7          	jalr	606(ra) # 80001f30 <copyout>
        brelse(b);
        return 0;
    }
    // Return buffer pointer to user, keeping it locked.
    return (uint64)b;
    80004cda:	87a6                	mv	a5,s1
    if(copyout(myproc()->pgtbl, addr, (char*)b->data, BSIZE) < 0) {
    80004cdc:	00054863          	bltz	a0,80004cec <sys_read_block+0x7e>
}
    80004ce0:	853e                	mv	a0,a5
    80004ce2:	70a2                	ld	ra,40(sp)
    80004ce4:	7402                	ld	s0,32(sp)
    80004ce6:	64e2                	ld	s1,24(sp)
    80004ce8:	6145                	add	sp,sp,48
    80004cea:	8082                	ret
        brelse(b);
    80004cec:	8526                	mv	a0,s1
    80004cee:	00001097          	auipc	ra,0x1
    80004cf2:	bee080e7          	jalr	-1042(ra) # 800058dc <brelse>
        return 0;
    80004cf6:	4781                	li	a5,0
    80004cf8:	b7e5                	j	80004ce0 <sys_read_block+0x72>

0000000080004cfa <sys_release_block>:

uint64 sys_release_block(void) {
    80004cfa:	7179                	add	sp,sp,-48
    80004cfc:	f406                	sd	ra,40(sp)
    80004cfe:	f022                	sd	s0,32(sp)
    80004d00:	ec26                	sd	s1,24(sp)
    80004d02:	1800                	add	s0,sp,48
    uint64 buf_handle;
    argaddr(0, &buf_handle);
    80004d04:	fd840593          	add	a1,s0,-40
    80004d08:	4501                	li	a0,0
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	a74080e7          	jalr	-1420(ra) # 8000377e <arg_uint64>
    
    struct buf *b = (struct buf*)buf_handle;
    80004d12:	fd843483          	ld	s1,-40(s0)
    if(b == 0) return -1;
    80004d16:	557d                	li	a0,-1
    80004d18:	c085                	beqz	s1,80004d38 <sys_release_block+0x3e>
    
    printf(COLOR_BLUE"sys_release_block: releasing buf_id=%p\n"COLOR_RESET, (void*)b);
    80004d1a:	85a6                	mv	a1,s1
    80004d1c:	00005517          	auipc	a0,0x5
    80004d20:	d0c50513          	add	a0,a0,-756 # 80009a28 <syscalls+0x250>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	52a080e7          	jalr	1322(ra) # 8000124e <printf>
    brelse(b);
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	00001097          	auipc	ra,0x1
    80004d32:	bae080e7          	jalr	-1106(ra) # 800058dc <brelse>
    return 0;
    80004d36:	4501                	li	a0,0
    80004d38:	70a2                	ld	ra,40(sp)
    80004d3a:	7402                	ld	s0,32(sp)
    80004d3c:	64e2                	ld	s1,24(sp)
    80004d3e:	6145                	add	sp,sp,48
    80004d40:	8082                	ret

0000000080004d42 <bmap>:
  iput(ip);
}

static uint
bmap(struct inode *ip, uint bn)
{
    80004d42:	7179                	add	sp,sp,-48
    80004d44:	f406                	sd	ra,40(sp)
    80004d46:	f022                	sd	s0,32(sp)
    80004d48:	ec26                	sd	s1,24(sp)
    80004d4a:	e84a                	sd	s2,16(sp)
    80004d4c:	e44e                	sd	s3,8(sp)
    80004d4e:	e052                	sd	s4,0(sp)
    80004d50:	1800                	add	s0,sp,48
    80004d52:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if (bn < NDIRECT)
    80004d54:	47ad                	li	a5,11
    80004d56:	02b7e863          	bltu	a5,a1,80004d86 <bmap+0x44>
  {
    if ((addr = ip->addrs[bn]) == 0)
    80004d5a:	02059793          	sll	a5,a1,0x20
    80004d5e:	01e7d593          	srl	a1,a5,0x1e
    80004d62:	00b504b3          	add	s1,a0,a1
    80004d66:	0504a903          	lw	s2,80(s1)
    80004d6a:	06091e63          	bnez	s2,80004de6 <bmap+0xa4>
    {
      addr = balloc(ip->dev);
    80004d6e:	4108                	lw	a0,0(a0)
    80004d70:	00002097          	auipc	ra,0x2
    80004d74:	fae080e7          	jalr	-82(ra) # 80006d1e <balloc>
    80004d78:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80004d7c:	06090563          	beqz	s2,80004de6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80004d80:	0524a823          	sw	s2,80(s1)
    80004d84:	a08d                	j	80004de6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80004d86:	ff45849b          	addw	s1,a1,-12
    80004d8a:	0004871b          	sext.w	a4,s1

  if (bn < NINDIRECT)
    80004d8e:	0ff00793          	li	a5,255
    80004d92:	08e7e563          	bltu	a5,a4,80004e1c <bmap+0xda>
  {
    if ((addr = ip->addrs[NDIRECT]) == 0)
    80004d96:	08052903          	lw	s2,128(a0)
    80004d9a:	00091d63          	bnez	s2,80004db4 <bmap+0x72>
    {
      addr = balloc(ip->dev);
    80004d9e:	4108                	lw	a0,0(a0)
    80004da0:	00002097          	auipc	ra,0x2
    80004da4:	f7e080e7          	jalr	-130(ra) # 80006d1e <balloc>
    80004da8:	0005091b          	sext.w	s2,a0
      if (addr == 0)
    80004dac:	02090d63          	beqz	s2,80004de6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80004db0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80004db4:	85ca                	mv	a1,s2
    80004db6:	0009a503          	lw	a0,0(s3)
    80004dba:	00001097          	auipc	ra,0x1
    80004dbe:	9f2080e7          	jalr	-1550(ra) # 800057ac <bread>
    80004dc2:	8a2a                	mv	s4,a0
    a = (uint *)bp->data;
    80004dc4:	05850793          	add	a5,a0,88
    if ((addr = a[bn]) == 0)
    80004dc8:	02049713          	sll	a4,s1,0x20
    80004dcc:	01e75593          	srl	a1,a4,0x1e
    80004dd0:	00b784b3          	add	s1,a5,a1
    80004dd4:	0004a903          	lw	s2,0(s1)
    80004dd8:	02090063          	beqz	s2,80004df8 <bmap+0xb6>
      {
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80004ddc:	8552                	mv	a0,s4
    80004dde:	00001097          	auipc	ra,0x1
    80004de2:	afe080e7          	jalr	-1282(ra) # 800058dc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004de6:	854a                	mv	a0,s2
    80004de8:	70a2                	ld	ra,40(sp)
    80004dea:	7402                	ld	s0,32(sp)
    80004dec:	64e2                	ld	s1,24(sp)
    80004dee:	6942                	ld	s2,16(sp)
    80004df0:	69a2                	ld	s3,8(sp)
    80004df2:	6a02                	ld	s4,0(sp)
    80004df4:	6145                	add	sp,sp,48
    80004df6:	8082                	ret
      addr = balloc(ip->dev);
    80004df8:	0009a503          	lw	a0,0(s3)
    80004dfc:	00002097          	auipc	ra,0x2
    80004e00:	f22080e7          	jalr	-222(ra) # 80006d1e <balloc>
    80004e04:	0005091b          	sext.w	s2,a0
      if (addr)
    80004e08:	fc090ae3          	beqz	s2,80004ddc <bmap+0x9a>
        a[bn] = addr;
    80004e0c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80004e10:	8552                	mv	a0,s4
    80004e12:	00001097          	auipc	ra,0x1
    80004e16:	132080e7          	jalr	306(ra) # 80005f44 <log_write>
    80004e1a:	b7c9                	j	80004ddc <bmap+0x9a>
  panic("bmap: out of range");
    80004e1c:	00005517          	auipc	a0,0x5
    80004e20:	c4450513          	add	a0,a0,-956 # 80009a60 <syscalls+0x288>
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	3e0080e7          	jalr	992(ra) # 80001204 <panic>

0000000080004e2c <iinit>:
{
    80004e2c:	7179                	add	sp,sp,-48
    80004e2e:	f406                	sd	ra,40(sp)
    80004e30:	f022                	sd	s0,32(sp)
    80004e32:	ec26                	sd	s1,24(sp)
    80004e34:	e84a                	sd	s2,16(sp)
    80004e36:	e44e                	sd	s3,8(sp)
    80004e38:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80004e3a:	00005597          	auipc	a1,0x5
    80004e3e:	c3e58593          	add	a1,a1,-962 # 80009a78 <syscalls+0x2a0>
    80004e42:	00013517          	auipc	a0,0x13
    80004e46:	1ee50513          	add	a0,a0,494 # 80018030 <itable>
    80004e4a:	ffffe097          	auipc	ra,0xffffe
    80004e4e:	194080e7          	jalr	404(ra) # 80002fde <initlock>
  for (i = 0; i < NINODE; i++)
    80004e52:	00013497          	auipc	s1,0x13
    80004e56:	20648493          	add	s1,s1,518 # 80018058 <itable+0x28>
    80004e5a:	00015997          	auipc	s3,0x15
    80004e5e:	c8e98993          	add	s3,s3,-882 # 80019ae8 <bcache+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004e62:	00005917          	auipc	s2,0x5
    80004e66:	c1e90913          	add	s2,s2,-994 # 80009a80 <syscalls+0x2a8>
    80004e6a:	85ca                	mv	a1,s2
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	ffffe097          	auipc	ra,0xffffe
    80004e72:	046080e7          	jalr	70(ra) # 80002eb4 <initsleeplock>
  for (i = 0; i < NINODE; i++)
    80004e76:	08848493          	add	s1,s1,136
    80004e7a:	ff3498e3          	bne	s1,s3,80004e6a <iinit+0x3e>
}
    80004e7e:	70a2                	ld	ra,40(sp)
    80004e80:	7402                	ld	s0,32(sp)
    80004e82:	64e2                	ld	s1,24(sp)
    80004e84:	6942                	ld	s2,16(sp)
    80004e86:	69a2                	ld	s3,8(sp)
    80004e88:	6145                	add	sp,sp,48
    80004e8a:	8082                	ret

0000000080004e8c <iget>:
{
    80004e8c:	7179                	add	sp,sp,-48
    80004e8e:	f406                	sd	ra,40(sp)
    80004e90:	f022                	sd	s0,32(sp)
    80004e92:	ec26                	sd	s1,24(sp)
    80004e94:	e84a                	sd	s2,16(sp)
    80004e96:	e44e                	sd	s3,8(sp)
    80004e98:	e052                	sd	s4,0(sp)
    80004e9a:	1800                	add	s0,sp,48
    80004e9c:	89aa                	mv	s3,a0
    80004e9e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004ea0:	00013517          	auipc	a0,0x13
    80004ea4:	19050513          	add	a0,a0,400 # 80018030 <itable>
    80004ea8:	ffffe097          	auipc	ra,0xffffe
    80004eac:	1c6080e7          	jalr	454(ra) # 8000306e <acquire>
  empty = 0;
    80004eb0:	4901                	li	s2,0
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80004eb2:	00013497          	auipc	s1,0x13
    80004eb6:	19648493          	add	s1,s1,406 # 80018048 <itable+0x18>
    80004eba:	00015697          	auipc	a3,0x15
    80004ebe:	c1e68693          	add	a3,a3,-994 # 80019ad8 <bcache>
    80004ec2:	a039                	j	80004ed0 <iget+0x44>
    if (empty == 0 && ip->ref == 0)
    80004ec4:	02090b63          	beqz	s2,80004efa <iget+0x6e>
  for (ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++)
    80004ec8:	08848493          	add	s1,s1,136
    80004ecc:	02d48a63          	beq	s1,a3,80004f00 <iget+0x74>
    if (ip->ref > 0 && ip->dev == dev && ip->inum == inum)
    80004ed0:	449c                	lw	a5,8(s1)
    80004ed2:	fef059e3          	blez	a5,80004ec4 <iget+0x38>
    80004ed6:	4098                	lw	a4,0(s1)
    80004ed8:	ff3716e3          	bne	a4,s3,80004ec4 <iget+0x38>
    80004edc:	40d8                	lw	a4,4(s1)
    80004ede:	ff4713e3          	bne	a4,s4,80004ec4 <iget+0x38>
      ip->ref++;
    80004ee2:	2785                	addw	a5,a5,1
    80004ee4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004ee6:	00013517          	auipc	a0,0x13
    80004eea:	14a50513          	add	a0,a0,330 # 80018030 <itable>
    80004eee:	ffffe097          	auipc	ra,0xffffe
    80004ef2:	234080e7          	jalr	564(ra) # 80003122 <release>
      return ip;
    80004ef6:	8926                	mv	s2,s1
    80004ef8:	a03d                	j	80004f26 <iget+0x9a>
    if (empty == 0 && ip->ref == 0)
    80004efa:	f7f9                	bnez	a5,80004ec8 <iget+0x3c>
    80004efc:	8926                	mv	s2,s1
    80004efe:	b7e9                	j	80004ec8 <iget+0x3c>
  if (empty == 0)
    80004f00:	02090c63          	beqz	s2,80004f38 <iget+0xac>
  ip->dev = dev;
    80004f04:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004f08:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004f0c:	4785                	li	a5,1
    80004f0e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004f12:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004f16:	00013517          	auipc	a0,0x13
    80004f1a:	11a50513          	add	a0,a0,282 # 80018030 <itable>
    80004f1e:	ffffe097          	auipc	ra,0xffffe
    80004f22:	204080e7          	jalr	516(ra) # 80003122 <release>
}
    80004f26:	854a                	mv	a0,s2
    80004f28:	70a2                	ld	ra,40(sp)
    80004f2a:	7402                	ld	s0,32(sp)
    80004f2c:	64e2                	ld	s1,24(sp)
    80004f2e:	6942                	ld	s2,16(sp)
    80004f30:	69a2                	ld	s3,8(sp)
    80004f32:	6a02                	ld	s4,0(sp)
    80004f34:	6145                	add	sp,sp,48
    80004f36:	8082                	ret
    panic("iget: no inodes");
    80004f38:	00005517          	auipc	a0,0x5
    80004f3c:	b5050513          	add	a0,a0,-1200 # 80009a88 <syscalls+0x2b0>
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	2c4080e7          	jalr	708(ra) # 80001204 <panic>

0000000080004f48 <ialloc>:
{
    80004f48:	7139                	add	sp,sp,-64
    80004f4a:	fc06                	sd	ra,56(sp)
    80004f4c:	f822                	sd	s0,48(sp)
    80004f4e:	f426                	sd	s1,40(sp)
    80004f50:	f04a                	sd	s2,32(sp)
    80004f52:	ec4e                	sd	s3,24(sp)
    80004f54:	e852                	sd	s4,16(sp)
    80004f56:	e456                	sd	s5,8(sp)
    80004f58:	e05a                	sd	s6,0(sp)
    80004f5a:	0080                	add	s0,sp,64
  for (inum = 1; inum < sb.ninodes; inum++)
    80004f5c:	0001e717          	auipc	a4,0x1e
    80004f60:	34872703          	lw	a4,840(a4) # 800232a4 <sb+0xc>
    80004f64:	4785                	li	a5,1
    80004f66:	04e7f863          	bgeu	a5,a4,80004fb6 <ialloc+0x6e>
    80004f6a:	8aaa                	mv	s5,a0
    80004f6c:	8b2e                	mv	s6,a1
    80004f6e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004f70:	0001ea17          	auipc	s4,0x1e
    80004f74:	328a0a13          	add	s4,s4,808 # 80023298 <sb>
    80004f78:	00495593          	srl	a1,s2,0x4
    80004f7c:	018a2783          	lw	a5,24(s4)
    80004f80:	9dbd                	addw	a1,a1,a5
    80004f82:	8556                	mv	a0,s5
    80004f84:	00001097          	auipc	ra,0x1
    80004f88:	828080e7          	jalr	-2008(ra) # 800057ac <bread>
    80004f8c:	84aa                	mv	s1,a0
    dip = (struct dinode *)bp->data + inum % IPB;
    80004f8e:	05850993          	add	s3,a0,88
    80004f92:	00f97793          	and	a5,s2,15
    80004f96:	079a                	sll	a5,a5,0x6
    80004f98:	99be                	add	s3,s3,a5
    if (dip->type == 0)
    80004f9a:	00099783          	lh	a5,0(s3)
    80004f9e:	cf9d                	beqz	a5,80004fdc <ialloc+0x94>
    brelse(bp);
    80004fa0:	00001097          	auipc	ra,0x1
    80004fa4:	93c080e7          	jalr	-1732(ra) # 800058dc <brelse>
  for (inum = 1; inum < sb.ninodes; inum++)
    80004fa8:	0905                	add	s2,s2,1
    80004faa:	00ca2703          	lw	a4,12(s4)
    80004fae:	0009079b          	sext.w	a5,s2
    80004fb2:	fce7e3e3          	bltu	a5,a4,80004f78 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80004fb6:	00005517          	auipc	a0,0x5
    80004fba:	ae250513          	add	a0,a0,-1310 # 80009a98 <syscalls+0x2c0>
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	290080e7          	jalr	656(ra) # 8000124e <printf>
  return 0;
    80004fc6:	4501                	li	a0,0
}
    80004fc8:	70e2                	ld	ra,56(sp)
    80004fca:	7442                	ld	s0,48(sp)
    80004fcc:	74a2                	ld	s1,40(sp)
    80004fce:	7902                	ld	s2,32(sp)
    80004fd0:	69e2                	ld	s3,24(sp)
    80004fd2:	6a42                	ld	s4,16(sp)
    80004fd4:	6aa2                	ld	s5,8(sp)
    80004fd6:	6b02                	ld	s6,0(sp)
    80004fd8:	6121                	add	sp,sp,64
    80004fda:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004fdc:	04000613          	li	a2,64
    80004fe0:	4581                	li	a1,0
    80004fe2:	854e                	mv	a0,s3
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	fd8080e7          	jalr	-40(ra) # 80000fbc <memset>
      dip->type = type;
    80004fec:	01699023          	sh	s6,0(s3)
      log_write(bp);
    80004ff0:	8526                	mv	a0,s1
    80004ff2:	00001097          	auipc	ra,0x1
    80004ff6:	f52080e7          	jalr	-174(ra) # 80005f44 <log_write>
      brelse(bp);
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	00001097          	auipc	ra,0x1
    80005000:	8e0080e7          	jalr	-1824(ra) # 800058dc <brelse>
      return iget(dev, inum);
    80005004:	0009059b          	sext.w	a1,s2
    80005008:	8556                	mv	a0,s5
    8000500a:	00000097          	auipc	ra,0x0
    8000500e:	e82080e7          	jalr	-382(ra) # 80004e8c <iget>
    80005012:	bf5d                	j	80004fc8 <ialloc+0x80>

0000000080005014 <iupdate>:
{
    80005014:	1101                	add	sp,sp,-32
    80005016:	ec06                	sd	ra,24(sp)
    80005018:	e822                	sd	s0,16(sp)
    8000501a:	e426                	sd	s1,8(sp)
    8000501c:	e04a                	sd	s2,0(sp)
    8000501e:	1000                	add	s0,sp,32
    80005020:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80005022:	415c                	lw	a5,4(a0)
    80005024:	0047d79b          	srlw	a5,a5,0x4
    80005028:	0001e597          	auipc	a1,0x1e
    8000502c:	2885a583          	lw	a1,648(a1) # 800232b0 <sb+0x18>
    80005030:	9dbd                	addw	a1,a1,a5
    80005032:	4108                	lw	a0,0(a0)
    80005034:	00000097          	auipc	ra,0x0
    80005038:	778080e7          	jalr	1912(ra) # 800057ac <bread>
    8000503c:	892a                	mv	s2,a0
  dip = (struct dinode *)bp->data + ip->inum % IPB;
    8000503e:	05850793          	add	a5,a0,88
    80005042:	40d8                	lw	a4,4(s1)
    80005044:	8b3d                	and	a4,a4,15
    80005046:	071a                	sll	a4,a4,0x6
    80005048:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000504a:	04449703          	lh	a4,68(s1)
    8000504e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80005052:	04649703          	lh	a4,70(s1)
    80005056:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000505a:	04849703          	lh	a4,72(s1)
    8000505e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80005062:	04a49703          	lh	a4,74(s1)
    80005066:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000506a:	44f8                	lw	a4,76(s1)
    8000506c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000506e:	03400613          	li	a2,52
    80005072:	05048593          	add	a1,s1,80
    80005076:	00c78513          	add	a0,a5,12
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	f9e080e7          	jalr	-98(ra) # 80001018 <memmove>
  log_write(bp);
    80005082:	854a                	mv	a0,s2
    80005084:	00001097          	auipc	ra,0x1
    80005088:	ec0080e7          	jalr	-320(ra) # 80005f44 <log_write>
  brelse(bp);
    8000508c:	854a                	mv	a0,s2
    8000508e:	00001097          	auipc	ra,0x1
    80005092:	84e080e7          	jalr	-1970(ra) # 800058dc <brelse>
}
    80005096:	60e2                	ld	ra,24(sp)
    80005098:	6442                	ld	s0,16(sp)
    8000509a:	64a2                	ld	s1,8(sp)
    8000509c:	6902                	ld	s2,0(sp)
    8000509e:	6105                	add	sp,sp,32
    800050a0:	8082                	ret

00000000800050a2 <idup>:
{
    800050a2:	1101                	add	sp,sp,-32
    800050a4:	ec06                	sd	ra,24(sp)
    800050a6:	e822                	sd	s0,16(sp)
    800050a8:	e426                	sd	s1,8(sp)
    800050aa:	1000                	add	s0,sp,32
    800050ac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800050ae:	00013517          	auipc	a0,0x13
    800050b2:	f8250513          	add	a0,a0,-126 # 80018030 <itable>
    800050b6:	ffffe097          	auipc	ra,0xffffe
    800050ba:	fb8080e7          	jalr	-72(ra) # 8000306e <acquire>
  ip->ref++;
    800050be:	449c                	lw	a5,8(s1)
    800050c0:	2785                	addw	a5,a5,1
    800050c2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800050c4:	00013517          	auipc	a0,0x13
    800050c8:	f6c50513          	add	a0,a0,-148 # 80018030 <itable>
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	056080e7          	jalr	86(ra) # 80003122 <release>
}
    800050d4:	8526                	mv	a0,s1
    800050d6:	60e2                	ld	ra,24(sp)
    800050d8:	6442                	ld	s0,16(sp)
    800050da:	64a2                	ld	s1,8(sp)
    800050dc:	6105                	add	sp,sp,32
    800050de:	8082                	ret

00000000800050e0 <ilock>:
{
    800050e0:	1101                	add	sp,sp,-32
    800050e2:	ec06                	sd	ra,24(sp)
    800050e4:	e822                	sd	s0,16(sp)
    800050e6:	e426                	sd	s1,8(sp)
    800050e8:	e04a                	sd	s2,0(sp)
    800050ea:	1000                	add	s0,sp,32
  if (ip == 0 || ip->ref < 1)
    800050ec:	c115                	beqz	a0,80005110 <ilock+0x30>
    800050ee:	84aa                	mv	s1,a0
    800050f0:	451c                	lw	a5,8(a0)
    800050f2:	00f05f63          	blez	a5,80005110 <ilock+0x30>
  acquiresleep(&ip->lock);
    800050f6:	0541                	add	a0,a0,16
    800050f8:	ffffe097          	auipc	ra,0xffffe
    800050fc:	df6080e7          	jalr	-522(ra) # 80002eee <acquiresleep>
  if (ip->valid == 0)
    80005100:	40bc                	lw	a5,64(s1)
    80005102:	cf99                	beqz	a5,80005120 <ilock+0x40>
}
    80005104:	60e2                	ld	ra,24(sp)
    80005106:	6442                	ld	s0,16(sp)
    80005108:	64a2                	ld	s1,8(sp)
    8000510a:	6902                	ld	s2,0(sp)
    8000510c:	6105                	add	sp,sp,32
    8000510e:	8082                	ret
    panic("ilock");
    80005110:	00005517          	auipc	a0,0x5
    80005114:	9a050513          	add	a0,a0,-1632 # 80009ab0 <syscalls+0x2d8>
    80005118:	ffffc097          	auipc	ra,0xffffc
    8000511c:	0ec080e7          	jalr	236(ra) # 80001204 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80005120:	40dc                	lw	a5,4(s1)
    80005122:	0047d79b          	srlw	a5,a5,0x4
    80005126:	0001e597          	auipc	a1,0x1e
    8000512a:	18a5a583          	lw	a1,394(a1) # 800232b0 <sb+0x18>
    8000512e:	9dbd                	addw	a1,a1,a5
    80005130:	4088                	lw	a0,0(s1)
    80005132:	00000097          	auipc	ra,0x0
    80005136:	67a080e7          	jalr	1658(ra) # 800057ac <bread>
    8000513a:	892a                	mv	s2,a0
    dip = (struct dinode *)bp->data + ip->inum % IPB;
    8000513c:	05850593          	add	a1,a0,88
    80005140:	40dc                	lw	a5,4(s1)
    80005142:	8bbd                	and	a5,a5,15
    80005144:	079a                	sll	a5,a5,0x6
    80005146:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80005148:	00059783          	lh	a5,0(a1)
    8000514c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80005150:	00259783          	lh	a5,2(a1)
    80005154:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80005158:	00459783          	lh	a5,4(a1)
    8000515c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80005160:	00659783          	lh	a5,6(a1)
    80005164:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80005168:	459c                	lw	a5,8(a1)
    8000516a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000516c:	03400613          	li	a2,52
    80005170:	05b1                	add	a1,a1,12
    80005172:	05048513          	add	a0,s1,80
    80005176:	ffffc097          	auipc	ra,0xffffc
    8000517a:	ea2080e7          	jalr	-350(ra) # 80001018 <memmove>
    brelse(bp);
    8000517e:	854a                	mv	a0,s2
    80005180:	00000097          	auipc	ra,0x0
    80005184:	75c080e7          	jalr	1884(ra) # 800058dc <brelse>
    ip->valid = 1;
    80005188:	4785                	li	a5,1
    8000518a:	c0bc                	sw	a5,64(s1)
    if (ip->type == 0)
    8000518c:	04449783          	lh	a5,68(s1)
    80005190:	fbb5                	bnez	a5,80005104 <ilock+0x24>
      panic("ilock: no type");
    80005192:	00005517          	auipc	a0,0x5
    80005196:	92650513          	add	a0,a0,-1754 # 80009ab8 <syscalls+0x2e0>
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	06a080e7          	jalr	106(ra) # 80001204 <panic>

00000000800051a2 <iunlock>:
{
    800051a2:	1101                	add	sp,sp,-32
    800051a4:	ec06                	sd	ra,24(sp)
    800051a6:	e822                	sd	s0,16(sp)
    800051a8:	e426                	sd	s1,8(sp)
    800051aa:	e04a                	sd	s2,0(sp)
    800051ac:	1000                	add	s0,sp,32
  if (ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800051ae:	c905                	beqz	a0,800051de <iunlock+0x3c>
    800051b0:	84aa                	mv	s1,a0
    800051b2:	01050913          	add	s2,a0,16
    800051b6:	854a                	mv	a0,s2
    800051b8:	ffffe097          	auipc	ra,0xffffe
    800051bc:	dd0080e7          	jalr	-560(ra) # 80002f88 <holdingsleep>
    800051c0:	cd19                	beqz	a0,800051de <iunlock+0x3c>
    800051c2:	449c                	lw	a5,8(s1)
    800051c4:	00f05d63          	blez	a5,800051de <iunlock+0x3c>
  releasesleep(&ip->lock);
    800051c8:	854a                	mv	a0,s2
    800051ca:	ffffe097          	auipc	ra,0xffffe
    800051ce:	d7a080e7          	jalr	-646(ra) # 80002f44 <releasesleep>
}
    800051d2:	60e2                	ld	ra,24(sp)
    800051d4:	6442                	ld	s0,16(sp)
    800051d6:	64a2                	ld	s1,8(sp)
    800051d8:	6902                	ld	s2,0(sp)
    800051da:	6105                	add	sp,sp,32
    800051dc:	8082                	ret
    panic("iunlock");
    800051de:	00005517          	auipc	a0,0x5
    800051e2:	8ea50513          	add	a0,a0,-1814 # 80009ac8 <syscalls+0x2f0>
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	01e080e7          	jalr	30(ra) # 80001204 <panic>

00000000800051ee <itrunc>:

void itrunc(struct inode *ip)
{
    800051ee:	7179                	add	sp,sp,-48
    800051f0:	f406                	sd	ra,40(sp)
    800051f2:	f022                	sd	s0,32(sp)
    800051f4:	ec26                	sd	s1,24(sp)
    800051f6:	e84a                	sd	s2,16(sp)
    800051f8:	e44e                	sd	s3,8(sp)
    800051fa:	e052                	sd	s4,0(sp)
    800051fc:	1800                	add	s0,sp,48
    800051fe:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for (i = 0; i < NDIRECT; i++)
    80005200:	05050493          	add	s1,a0,80
    80005204:	08050913          	add	s2,a0,128
    80005208:	a021                	j	80005210 <itrunc+0x22>
    8000520a:	0491                	add	s1,s1,4
    8000520c:	01248d63          	beq	s1,s2,80005226 <itrunc+0x38>
  {
    if (ip->addrs[i])
    80005210:	408c                	lw	a1,0(s1)
    80005212:	dde5                	beqz	a1,8000520a <itrunc+0x1c>
    {
      bfree(ip->dev, ip->addrs[i]);
    80005214:	0009a503          	lw	a0,0(s3)
    80005218:	00002097          	auipc	ra,0x2
    8000521c:	c38080e7          	jalr	-968(ra) # 80006e50 <bfree>
      ip->addrs[i] = 0;
    80005220:	0004a023          	sw	zero,0(s1)
    80005224:	b7dd                	j	8000520a <itrunc+0x1c>
    }
  }

  if (ip->addrs[NDIRECT])
    80005226:	0809a583          	lw	a1,128(s3)
    8000522a:	e185                	bnez	a1,8000524a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000522c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80005230:	854e                	mv	a0,s3
    80005232:	00000097          	auipc	ra,0x0
    80005236:	de2080e7          	jalr	-542(ra) # 80005014 <iupdate>
}
    8000523a:	70a2                	ld	ra,40(sp)
    8000523c:	7402                	ld	s0,32(sp)
    8000523e:	64e2                	ld	s1,24(sp)
    80005240:	6942                	ld	s2,16(sp)
    80005242:	69a2                	ld	s3,8(sp)
    80005244:	6a02                	ld	s4,0(sp)
    80005246:	6145                	add	sp,sp,48
    80005248:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000524a:	0009a503          	lw	a0,0(s3)
    8000524e:	00000097          	auipc	ra,0x0
    80005252:	55e080e7          	jalr	1374(ra) # 800057ac <bread>
    80005256:	8a2a                	mv	s4,a0
    for (j = 0; j < NINDIRECT; j++)
    80005258:	05850493          	add	s1,a0,88
    8000525c:	45850913          	add	s2,a0,1112
    80005260:	a021                	j	80005268 <itrunc+0x7a>
    80005262:	0491                	add	s1,s1,4
    80005264:	01248b63          	beq	s1,s2,8000527a <itrunc+0x8c>
      if (a[j])
    80005268:	408c                	lw	a1,0(s1)
    8000526a:	dde5                	beqz	a1,80005262 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000526c:	0009a503          	lw	a0,0(s3)
    80005270:	00002097          	auipc	ra,0x2
    80005274:	be0080e7          	jalr	-1056(ra) # 80006e50 <bfree>
    80005278:	b7ed                	j	80005262 <itrunc+0x74>
    brelse(bp);
    8000527a:	8552                	mv	a0,s4
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	660080e7          	jalr	1632(ra) # 800058dc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80005284:	0809a583          	lw	a1,128(s3)
    80005288:	0009a503          	lw	a0,0(s3)
    8000528c:	00002097          	auipc	ra,0x2
    80005290:	bc4080e7          	jalr	-1084(ra) # 80006e50 <bfree>
    ip->addrs[NDIRECT] = 0;
    80005294:	0809a023          	sw	zero,128(s3)
    80005298:	bf51                	j	8000522c <itrunc+0x3e>

000000008000529a <iput>:
{
    8000529a:	1101                	add	sp,sp,-32
    8000529c:	ec06                	sd	ra,24(sp)
    8000529e:	e822                	sd	s0,16(sp)
    800052a0:	e426                	sd	s1,8(sp)
    800052a2:	e04a                	sd	s2,0(sp)
    800052a4:	1000                	add	s0,sp,32
    800052a6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800052a8:	00013517          	auipc	a0,0x13
    800052ac:	d8850513          	add	a0,a0,-632 # 80018030 <itable>
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	dbe080e7          	jalr	-578(ra) # 8000306e <acquire>
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    800052b8:	4498                	lw	a4,8(s1)
    800052ba:	4785                	li	a5,1
    800052bc:	02f70363          	beq	a4,a5,800052e2 <iput+0x48>
  ip->ref--;
    800052c0:	449c                	lw	a5,8(s1)
    800052c2:	37fd                	addw	a5,a5,-1
    800052c4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800052c6:	00013517          	auipc	a0,0x13
    800052ca:	d6a50513          	add	a0,a0,-662 # 80018030 <itable>
    800052ce:	ffffe097          	auipc	ra,0xffffe
    800052d2:	e54080e7          	jalr	-428(ra) # 80003122 <release>
}
    800052d6:	60e2                	ld	ra,24(sp)
    800052d8:	6442                	ld	s0,16(sp)
    800052da:	64a2                	ld	s1,8(sp)
    800052dc:	6902                	ld	s2,0(sp)
    800052de:	6105                	add	sp,sp,32
    800052e0:	8082                	ret
  if (ip->ref == 1 && ip->valid && ip->nlink == 0)
    800052e2:	40bc                	lw	a5,64(s1)
    800052e4:	dff1                	beqz	a5,800052c0 <iput+0x26>
    800052e6:	04a49783          	lh	a5,74(s1)
    800052ea:	fbf9                	bnez	a5,800052c0 <iput+0x26>
    acquiresleep(&ip->lock);
    800052ec:	01048913          	add	s2,s1,16
    800052f0:	854a                	mv	a0,s2
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	bfc080e7          	jalr	-1028(ra) # 80002eee <acquiresleep>
    release(&itable.lock);
    800052fa:	00013517          	auipc	a0,0x13
    800052fe:	d3650513          	add	a0,a0,-714 # 80018030 <itable>
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	e20080e7          	jalr	-480(ra) # 80003122 <release>
    itrunc(ip);
    8000530a:	8526                	mv	a0,s1
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	ee2080e7          	jalr	-286(ra) # 800051ee <itrunc>
    ip->type = 0;
    80005314:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80005318:	8526                	mv	a0,s1
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	cfa080e7          	jalr	-774(ra) # 80005014 <iupdate>
    ip->valid = 0;
    80005322:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80005326:	854a                	mv	a0,s2
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	c1c080e7          	jalr	-996(ra) # 80002f44 <releasesleep>
    acquire(&itable.lock);
    80005330:	00013517          	auipc	a0,0x13
    80005334:	d0050513          	add	a0,a0,-768 # 80018030 <itable>
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	d36080e7          	jalr	-714(ra) # 8000306e <acquire>
    80005340:	b741                	j	800052c0 <iput+0x26>

0000000080005342 <iunlockput>:
{
    80005342:	1101                	add	sp,sp,-32
    80005344:	ec06                	sd	ra,24(sp)
    80005346:	e822                	sd	s0,16(sp)
    80005348:	e426                	sd	s1,8(sp)
    8000534a:	1000                	add	s0,sp,32
    8000534c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	e54080e7          	jalr	-428(ra) # 800051a2 <iunlock>
  iput(ip);
    80005356:	8526                	mv	a0,s1
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	f42080e7          	jalr	-190(ra) # 8000529a <iput>
}
    80005360:	60e2                	ld	ra,24(sp)
    80005362:	6442                	ld	s0,16(sp)
    80005364:	64a2                	ld	s1,8(sp)
    80005366:	6105                	add	sp,sp,32
    80005368:	8082                	ret

000000008000536a <stati>:

void stati(struct inode *ip, struct stat *st)
{
    8000536a:	1141                	add	sp,sp,-16
    8000536c:	e422                	sd	s0,8(sp)
    8000536e:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80005370:	411c                	lw	a5,0(a0)
    80005372:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80005374:	415c                	lw	a5,4(a0)
    80005376:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80005378:	04451783          	lh	a5,68(a0)
    8000537c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80005380:	04a51783          	lh	a5,74(a0)
    80005384:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80005388:	04c56783          	lwu	a5,76(a0)
    8000538c:	e99c                	sd	a5,16(a1)
}
    8000538e:	6422                	ld	s0,8(sp)
    80005390:	0141                	add	sp,sp,16
    80005392:	8082                	ret

0000000080005394 <readi>:
int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    80005394:	457c                	lw	a5,76(a0)
    80005396:	0ed7e963          	bltu	a5,a3,80005488 <readi+0xf4>
{
    8000539a:	7159                	add	sp,sp,-112
    8000539c:	f486                	sd	ra,104(sp)
    8000539e:	f0a2                	sd	s0,96(sp)
    800053a0:	eca6                	sd	s1,88(sp)
    800053a2:	e8ca                	sd	s2,80(sp)
    800053a4:	e4ce                	sd	s3,72(sp)
    800053a6:	e0d2                	sd	s4,64(sp)
    800053a8:	fc56                	sd	s5,56(sp)
    800053aa:	f85a                	sd	s6,48(sp)
    800053ac:	f45e                	sd	s7,40(sp)
    800053ae:	f062                	sd	s8,32(sp)
    800053b0:	ec66                	sd	s9,24(sp)
    800053b2:	e86a                	sd	s10,16(sp)
    800053b4:	e46e                	sd	s11,8(sp)
    800053b6:	1880                	add	s0,sp,112
    800053b8:	8b2a                	mv	s6,a0
    800053ba:	8bae                	mv	s7,a1
    800053bc:	8a32                	mv	s4,a2
    800053be:	84b6                	mv	s1,a3
    800053c0:	8aba                	mv	s5,a4
  if (off > ip->size || off + n < off)
    800053c2:	9f35                	addw	a4,a4,a3
    return 0;
    800053c4:	4501                	li	a0,0
  if (off > ip->size || off + n < off)
    800053c6:	0ad76063          	bltu	a4,a3,80005466 <readi+0xd2>
  if (off + n > ip->size)
    800053ca:	00e7f463          	bgeu	a5,a4,800053d2 <readi+0x3e>
    n = ip->size - off;
    800053ce:	40d78abb          	subw	s5,a5,a3

  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    800053d2:	0a0a8963          	beqz	s5,80005484 <readi+0xf0>
    800053d6:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    800053d8:	40000c93          	li	s9,1024
    if (either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1)
    800053dc:	5c7d                	li	s8,-1
    800053de:	a82d                	j	80005418 <readi+0x84>
    800053e0:	020d1d93          	sll	s11,s10,0x20
    800053e4:	020ddd93          	srl	s11,s11,0x20
    800053e8:	05890613          	add	a2,s2,88
    800053ec:	86ee                	mv	a3,s11
    800053ee:	963a                	add	a2,a2,a4
    800053f0:	85d2                	mv	a1,s4
    800053f2:	855e                	mv	a0,s7
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	978080e7          	jalr	-1672(ra) # 80002d6c <either_copyout>
    800053fc:	05850d63          	beq	a0,s8,80005456 <readi+0xc2>
    {
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80005400:	854a                	mv	a0,s2
    80005402:	00000097          	auipc	ra,0x0
    80005406:	4da080e7          	jalr	1242(ra) # 800058dc <brelse>
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    8000540a:	013d09bb          	addw	s3,s10,s3
    8000540e:	009d04bb          	addw	s1,s10,s1
    80005412:	9a6e                	add	s4,s4,s11
    80005414:	0559f763          	bgeu	s3,s5,80005462 <readi+0xce>
    uint addr = bmap(ip, off / BSIZE);
    80005418:	00a4d59b          	srlw	a1,s1,0xa
    8000541c:	855a                	mv	a0,s6
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	924080e7          	jalr	-1756(ra) # 80004d42 <bmap>
    80005426:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    8000542a:	cd85                	beqz	a1,80005462 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000542c:	000b2503          	lw	a0,0(s6)
    80005430:	00000097          	auipc	ra,0x0
    80005434:	37c080e7          	jalr	892(ra) # 800057ac <bread>
    80005438:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    8000543a:	3ff4f713          	and	a4,s1,1023
    8000543e:	40ec87bb          	subw	a5,s9,a4
    80005442:	413a86bb          	subw	a3,s5,s3
    80005446:	8d3e                	mv	s10,a5
    80005448:	2781                	sext.w	a5,a5
    8000544a:	0006861b          	sext.w	a2,a3
    8000544e:	f8f679e3          	bgeu	a2,a5,800053e0 <readi+0x4c>
    80005452:	8d36                	mv	s10,a3
    80005454:	b771                	j	800053e0 <readi+0x4c>
      brelse(bp);
    80005456:	854a                	mv	a0,s2
    80005458:	00000097          	auipc	ra,0x0
    8000545c:	484080e7          	jalr	1156(ra) # 800058dc <brelse>
      tot = -1;
    80005460:	59fd                	li	s3,-1
  }
  return tot;
    80005462:	0009851b          	sext.w	a0,s3
}
    80005466:	70a6                	ld	ra,104(sp)
    80005468:	7406                	ld	s0,96(sp)
    8000546a:	64e6                	ld	s1,88(sp)
    8000546c:	6946                	ld	s2,80(sp)
    8000546e:	69a6                	ld	s3,72(sp)
    80005470:	6a06                	ld	s4,64(sp)
    80005472:	7ae2                	ld	s5,56(sp)
    80005474:	7b42                	ld	s6,48(sp)
    80005476:	7ba2                	ld	s7,40(sp)
    80005478:	7c02                	ld	s8,32(sp)
    8000547a:	6ce2                	ld	s9,24(sp)
    8000547c:	6d42                	ld	s10,16(sp)
    8000547e:	6da2                	ld	s11,8(sp)
    80005480:	6165                	add	sp,sp,112
    80005482:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, dst += m)
    80005484:	89d6                	mv	s3,s5
    80005486:	bff1                	j	80005462 <readi+0xce>
    return 0;
    80005488:	4501                	li	a0,0
}
    8000548a:	8082                	ret

000000008000548c <writei>:
int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if (off > ip->size || off + n < off)
    8000548c:	457c                	lw	a5,76(a0)
    8000548e:	10d7e863          	bltu	a5,a3,8000559e <writei+0x112>
{
    80005492:	7159                	add	sp,sp,-112
    80005494:	f486                	sd	ra,104(sp)
    80005496:	f0a2                	sd	s0,96(sp)
    80005498:	eca6                	sd	s1,88(sp)
    8000549a:	e8ca                	sd	s2,80(sp)
    8000549c:	e4ce                	sd	s3,72(sp)
    8000549e:	e0d2                	sd	s4,64(sp)
    800054a0:	fc56                	sd	s5,56(sp)
    800054a2:	f85a                	sd	s6,48(sp)
    800054a4:	f45e                	sd	s7,40(sp)
    800054a6:	f062                	sd	s8,32(sp)
    800054a8:	ec66                	sd	s9,24(sp)
    800054aa:	e86a                	sd	s10,16(sp)
    800054ac:	e46e                	sd	s11,8(sp)
    800054ae:	1880                	add	s0,sp,112
    800054b0:	8aaa                	mv	s5,a0
    800054b2:	8bae                	mv	s7,a1
    800054b4:	8a32                	mv	s4,a2
    800054b6:	8936                	mv	s2,a3
    800054b8:	8b3a                	mv	s6,a4
  if (off > ip->size || off + n < off)
    800054ba:	00e687bb          	addw	a5,a3,a4
    800054be:	0ed7e263          	bltu	a5,a3,800055a2 <writei+0x116>
    return -1;
  if (off + n > MAXFILE * BSIZE)
    800054c2:	00043737          	lui	a4,0x43
    800054c6:	0ef76063          	bltu	a4,a5,800055a6 <writei+0x11a>
    return -1;

  for (tot = 0; tot < n; tot += m, off += m, src += m)
    800054ca:	0c0b0863          	beqz	s6,8000559a <writei+0x10e>
    800054ce:	4981                	li	s3,0
  {
    uint addr = bmap(ip, off / BSIZE);
    if (addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off % BSIZE);
    800054d0:	40000c93          	li	s9,1024
    if (either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1)
    800054d4:	5c7d                	li	s8,-1
    800054d6:	a091                	j	8000551a <writei+0x8e>
    800054d8:	020d1d93          	sll	s11,s10,0x20
    800054dc:	020ddd93          	srl	s11,s11,0x20
    800054e0:	05848513          	add	a0,s1,88
    800054e4:	86ee                	mv	a3,s11
    800054e6:	8652                	mv	a2,s4
    800054e8:	85de                	mv	a1,s7
    800054ea:	953a                	add	a0,a0,a4
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	8d6080e7          	jalr	-1834(ra) # 80002dc2 <either_copyin>
    800054f4:	07850263          	beq	a0,s8,80005558 <writei+0xcc>
    {
      brelse(bp);
      break;
    }
    log_write(bp);
    800054f8:	8526                	mv	a0,s1
    800054fa:	00001097          	auipc	ra,0x1
    800054fe:	a4a080e7          	jalr	-1462(ra) # 80005f44 <log_write>
    brelse(bp);
    80005502:	8526                	mv	a0,s1
    80005504:	00000097          	auipc	ra,0x0
    80005508:	3d8080e7          	jalr	984(ra) # 800058dc <brelse>
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    8000550c:	013d09bb          	addw	s3,s10,s3
    80005510:	012d093b          	addw	s2,s10,s2
    80005514:	9a6e                	add	s4,s4,s11
    80005516:	0569f663          	bgeu	s3,s6,80005562 <writei+0xd6>
    uint addr = bmap(ip, off / BSIZE);
    8000551a:	00a9559b          	srlw	a1,s2,0xa
    8000551e:	8556                	mv	a0,s5
    80005520:	00000097          	auipc	ra,0x0
    80005524:	822080e7          	jalr	-2014(ra) # 80004d42 <bmap>
    80005528:	0005059b          	sext.w	a1,a0
    if (addr == 0)
    8000552c:	c99d                	beqz	a1,80005562 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000552e:	000aa503          	lw	a0,0(s5)
    80005532:	00000097          	auipc	ra,0x0
    80005536:	27a080e7          	jalr	634(ra) # 800057ac <bread>
    8000553a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off % BSIZE);
    8000553c:	3ff97713          	and	a4,s2,1023
    80005540:	40ec87bb          	subw	a5,s9,a4
    80005544:	413b06bb          	subw	a3,s6,s3
    80005548:	8d3e                	mv	s10,a5
    8000554a:	2781                	sext.w	a5,a5
    8000554c:	0006861b          	sext.w	a2,a3
    80005550:	f8f674e3          	bgeu	a2,a5,800054d8 <writei+0x4c>
    80005554:	8d36                	mv	s10,a3
    80005556:	b749                	j	800054d8 <writei+0x4c>
      brelse(bp);
    80005558:	8526                	mv	a0,s1
    8000555a:	00000097          	auipc	ra,0x0
    8000555e:	382080e7          	jalr	898(ra) # 800058dc <brelse>
  }

  if (off > ip->size)
    80005562:	04caa783          	lw	a5,76(s5)
    80005566:	0127f463          	bgeu	a5,s2,8000556e <writei+0xe2>
    ip->size = off;
    8000556a:	052aa623          	sw	s2,76(s5)

  iupdate(ip);
    8000556e:	8556                	mv	a0,s5
    80005570:	00000097          	auipc	ra,0x0
    80005574:	aa4080e7          	jalr	-1372(ra) # 80005014 <iupdate>

  return tot;
    80005578:	0009851b          	sext.w	a0,s3
}
    8000557c:	70a6                	ld	ra,104(sp)
    8000557e:	7406                	ld	s0,96(sp)
    80005580:	64e6                	ld	s1,88(sp)
    80005582:	6946                	ld	s2,80(sp)
    80005584:	69a6                	ld	s3,72(sp)
    80005586:	6a06                	ld	s4,64(sp)
    80005588:	7ae2                	ld	s5,56(sp)
    8000558a:	7b42                	ld	s6,48(sp)
    8000558c:	7ba2                	ld	s7,40(sp)
    8000558e:	7c02                	ld	s8,32(sp)
    80005590:	6ce2                	ld	s9,24(sp)
    80005592:	6d42                	ld	s10,16(sp)
    80005594:	6da2                	ld	s11,8(sp)
    80005596:	6165                	add	sp,sp,112
    80005598:	8082                	ret
  for (tot = 0; tot < n; tot += m, off += m, src += m)
    8000559a:	89da                	mv	s3,s6
    8000559c:	bfc9                	j	8000556e <writei+0xe2>
    return -1;
    8000559e:	557d                	li	a0,-1
}
    800055a0:	8082                	ret
    return -1;
    800055a2:	557d                	li	a0,-1
    800055a4:	bfe1                	j	8000557c <writei+0xf0>
    return -1;
    800055a6:	557d                	li	a0,-1
    800055a8:	bfd1                	j	8000557c <writei+0xf0>

00000000800055aa <inode_print>:

char *inode_types[] = { "unused", "dir", "file", "dev" };

void inode_print(struct inode* ip)
{
    800055aa:	7179                	add	sp,sp,-48
    800055ac:	f406                	sd	ra,40(sp)
    800055ae:	f022                	sd	s0,32(sp)
    800055b0:	ec26                	sd	s1,24(sp)
    800055b2:	e84a                	sd	s2,16(sp)
    800055b4:	e44e                	sd	s3,8(sp)
    800055b6:	1800                	add	s0,sp,48
    800055b8:	892a                	mv	s2,a0
    assert(holdingsleep(&ip->lock), "inode_print: lk");
    800055ba:	0541                	add	a0,a0,16
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	9cc080e7          	jalr	-1588(ra) # 80002f88 <holdingsleep>
    800055c4:	00004597          	auipc	a1,0x4
    800055c8:	50c58593          	add	a1,a1,1292 # 80009ad0 <syscalls+0x2f8>
    800055cc:	00002097          	auipc	ra,0x2
    800055d0:	900080e7          	jalr	-1792(ra) # 80006ecc <assert>

    printf("\ninode information:\n");
    800055d4:	00004517          	auipc	a0,0x4
    800055d8:	50c50513          	add	a0,a0,1292 # 80009ae0 <syscalls+0x308>
    800055dc:	ffffc097          	auipc	ra,0xffffc
    800055e0:	c72080e7          	jalr	-910(ra) # 8000124e <printf>
    printf("num = %d, ref = %d, valid = %d\n", ip->inum, ip->ref, ip->valid);
    800055e4:	04092683          	lw	a3,64(s2)
    800055e8:	00892603          	lw	a2,8(s2)
    800055ec:	00492583          	lw	a1,4(s2)
    800055f0:	00004517          	auipc	a0,0x4
    800055f4:	50850513          	add	a0,a0,1288 # 80009af8 <syscalls+0x320>
    800055f8:	ffffc097          	auipc	ra,0xffffc
    800055fc:	c56080e7          	jalr	-938(ra) # 8000124e <printf>
    printf("type = %s, major = %d, minor = %d, nlink = %d\n", inode_types[ip->type], ip->major, ip->minor, ip->nlink);
    80005600:	04491703          	lh	a4,68(s2)
    80005604:	070e                	sll	a4,a4,0x3
    80005606:	00004797          	auipc	a5,0x4
    8000560a:	7ca78793          	add	a5,a5,1994 # 80009dd0 <inode_types>
    8000560e:	97ba                	add	a5,a5,a4
    80005610:	04a91703          	lh	a4,74(s2)
    80005614:	04891683          	lh	a3,72(s2)
    80005618:	04691603          	lh	a2,70(s2)
    8000561c:	638c                	ld	a1,0(a5)
    8000561e:	00004517          	auipc	a0,0x4
    80005622:	4fa50513          	add	a0,a0,1274 # 80009b18 <syscalls+0x340>
    80005626:	ffffc097          	auipc	ra,0xffffc
    8000562a:	c28080e7          	jalr	-984(ra) # 8000124e <printf>
    printf("size = %d, addrs =", ip->size);
    8000562e:	04c92583          	lw	a1,76(s2)
    80005632:	00004517          	auipc	a0,0x4
    80005636:	51650513          	add	a0,a0,1302 # 80009b48 <syscalls+0x370>
    8000563a:	ffffc097          	auipc	ra,0xffffc
    8000563e:	c14080e7          	jalr	-1004(ra) # 8000124e <printf>
    for(int i = 0; i < NDIRECT+1; i++)
    80005642:	05090493          	add	s1,s2,80
    80005646:	08490913          	add	s2,s2,132
        printf(" %d", ip->addrs[i]);
    8000564a:	00004997          	auipc	s3,0x4
    8000564e:	51698993          	add	s3,s3,1302 # 80009b60 <syscalls+0x388>
    80005652:	408c                	lw	a1,0(s1)
    80005654:	854e                	mv	a0,s3
    80005656:	ffffc097          	auipc	ra,0xffffc
    8000565a:	bf8080e7          	jalr	-1032(ra) # 8000124e <printf>
    for(int i = 0; i < NDIRECT+1; i++)
    8000565e:	0491                	add	s1,s1,4
    80005660:	ff2499e3          	bne	s1,s2,80005652 <inode_print+0xa8>
    printf("\n");
    80005664:	00004517          	auipc	a0,0x4
    80005668:	6d450513          	add	a0,a0,1748 # 80009d38 <syscalls+0x560>
    8000566c:	ffffc097          	auipc	ra,0xffffc
    80005670:	be2080e7          	jalr	-1054(ra) # 8000124e <printf>
}
    80005674:	70a2                	ld	ra,40(sp)
    80005676:	7402                	ld	s0,32(sp)
    80005678:	64e2                	ld	s1,24(sp)
    8000567a:	6942                	ld	s2,16(sp)
    8000567c:	69a2                	ld	s3,8(sp)
    8000567e:	6145                	add	sp,sp,48
    80005680:	8082                	ret

0000000080005682 <inode_create>:

struct inode* inode_create(short type, short major, short minor) {
    80005682:	7179                	add	sp,sp,-48
    80005684:	f406                	sd	ra,40(sp)
    80005686:	f022                	sd	s0,32(sp)
    80005688:	ec26                	sd	s1,24(sp)
    8000568a:	e84a                	sd	s2,16(sp)
    8000568c:	e44e                	sd	s3,8(sp)
    8000568e:	1800                	add	s0,sp,48
    80005690:	89ae                	mv	s3,a1
    80005692:	8932                	mv	s2,a2
    struct inode *ip = ialloc(ROOTDEV, type);
    80005694:	85aa                	mv	a1,a0
    80005696:	4505                	li	a0,1
    80005698:	00000097          	auipc	ra,0x0
    8000569c:	8b0080e7          	jalr	-1872(ra) # 80004f48 <ialloc>
    800056a0:	84aa                	mv	s1,a0
    if(ip == 0) return 0;
    800056a2:	c515                	beqz	a0,800056ce <inode_create+0x4c>
    ilock(ip);
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	a3c080e7          	jalr	-1476(ra) # 800050e0 <ilock>
    ip->major = major;
    800056ac:	05349323          	sh	s3,70(s1)
    ip->minor = minor;
    800056b0:	05249423          	sh	s2,72(s1)
    ip->nlink = 1;
    800056b4:	4785                	li	a5,1
    800056b6:	04f49523          	sh	a5,74(s1)
    iupdate(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	00000097          	auipc	ra,0x0
    800056c0:	958080e7          	jalr	-1704(ra) # 80005014 <iupdate>
    iunlock(ip);
    800056c4:	8526                	mv	a0,s1
    800056c6:	00000097          	auipc	ra,0x0
    800056ca:	adc080e7          	jalr	-1316(ra) # 800051a2 <iunlock>
    return ip;
}
    800056ce:	8526                	mv	a0,s1
    800056d0:	70a2                	ld	ra,40(sp)
    800056d2:	7402                	ld	s0,32(sp)
    800056d4:	64e2                	ld	s1,24(sp)
    800056d6:	6942                	ld	s2,16(sp)
    800056d8:	69a2                	ld	s3,8(sp)
    800056da:	6145                	add	sp,sp,48
    800056dc:	8082                	ret

00000000800056de <inode_lock>:

void inode_lock(struct inode *ip) {
    800056de:	1141                	add	sp,sp,-16
    800056e0:	e406                	sd	ra,8(sp)
    800056e2:	e022                	sd	s0,0(sp)
    800056e4:	0800                	add	s0,sp,16
    ilock(ip);
    800056e6:	00000097          	auipc	ra,0x0
    800056ea:	9fa080e7          	jalr	-1542(ra) # 800050e0 <ilock>
}
    800056ee:	60a2                	ld	ra,8(sp)
    800056f0:	6402                	ld	s0,0(sp)
    800056f2:	0141                	add	sp,sp,16
    800056f4:	8082                	ret

00000000800056f6 <inode_unlock_free>:

void inode_unlock_free(struct inode *ip) {
    800056f6:	1101                	add	sp,sp,-32
    800056f8:	ec06                	sd	ra,24(sp)
    800056fa:	e822                	sd	s0,16(sp)
    800056fc:	e426                	sd	s1,8(sp)
    800056fe:	1000                	add	s0,sp,32
    80005700:	84aa                	mv	s1,a0
    iunlock(ip);
    80005702:	00000097          	auipc	ra,0x0
    80005706:	aa0080e7          	jalr	-1376(ra) # 800051a2 <iunlock>
    iput(ip);
    8000570a:	8526                	mv	a0,s1
    8000570c:	00000097          	auipc	ra,0x0
    80005710:	b8e080e7          	jalr	-1138(ra) # 8000529a <iput>
}
    80005714:	60e2                	ld	ra,24(sp)
    80005716:	6442                	ld	s0,16(sp)
    80005718:	64a2                	ld	s1,8(sp)
    8000571a:	6105                	add	sp,sp,32
    8000571c:	8082                	ret

000000008000571e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000571e:	7179                	add	sp,sp,-48
    80005720:	f406                	sd	ra,40(sp)
    80005722:	f022                	sd	s0,32(sp)
    80005724:	ec26                	sd	s1,24(sp)
    80005726:	e84a                	sd	s2,16(sp)
    80005728:	e44e                	sd	s3,8(sp)
    8000572a:	e052                	sd	s4,0(sp)
    8000572c:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000572e:	00004597          	auipc	a1,0x4
    80005732:	45258593          	add	a1,a1,1106 # 80009b80 <syscalls+0x3a8>
    80005736:	00014517          	auipc	a0,0x14
    8000573a:	3a250513          	add	a0,a0,930 # 80019ad8 <bcache>
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	8a0080e7          	jalr	-1888(ra) # 80002fde <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80005746:	0001c797          	auipc	a5,0x1c
    8000574a:	39278793          	add	a5,a5,914 # 80021ad8 <bcache+0x8000>
    8000574e:	0001c717          	auipc	a4,0x1c
    80005752:	5f270713          	add	a4,a4,1522 # 80021d40 <bcache+0x8268>
    80005756:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000575a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000575e:	00014497          	auipc	s1,0x14
    80005762:	39248493          	add	s1,s1,914 # 80019af0 <bcache+0x18>
    b->next = bcache.head.next;
    80005766:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80005768:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000576a:	00004a17          	auipc	s4,0x4
    8000576e:	41ea0a13          	add	s4,s4,1054 # 80009b88 <syscalls+0x3b0>
    b->next = bcache.head.next;
    80005772:	2b893783          	ld	a5,696(s2)
    80005776:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80005778:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000577c:	85d2                	mv	a1,s4
    8000577e:	01048513          	add	a0,s1,16
    80005782:	ffffd097          	auipc	ra,0xffffd
    80005786:	732080e7          	jalr	1842(ra) # 80002eb4 <initsleeplock>
    bcache.head.next->prev = b;
    8000578a:	2b893783          	ld	a5,696(s2)
    8000578e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80005790:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80005794:	45848493          	add	s1,s1,1112
    80005798:	fd349de3          	bne	s1,s3,80005772 <binit+0x54>
  }
}
    8000579c:	70a2                	ld	ra,40(sp)
    8000579e:	7402                	ld	s0,32(sp)
    800057a0:	64e2                	ld	s1,24(sp)
    800057a2:	6942                	ld	s2,16(sp)
    800057a4:	69a2                	ld	s3,8(sp)
    800057a6:	6a02                	ld	s4,0(sp)
    800057a8:	6145                	add	sp,sp,48
    800057aa:	8082                	ret

00000000800057ac <bread>:
}

/// @brief 从指定设备和块号读取一个块，并返回指向该块的缓冲区指针。
struct buf*
bread(uint dev, uint blockno)
{
    800057ac:	7179                	add	sp,sp,-48
    800057ae:	f406                	sd	ra,40(sp)
    800057b0:	f022                	sd	s0,32(sp)
    800057b2:	ec26                	sd	s1,24(sp)
    800057b4:	e84a                	sd	s2,16(sp)
    800057b6:	e44e                	sd	s3,8(sp)
    800057b8:	1800                	add	s0,sp,48
    800057ba:	892a                	mv	s2,a0
    800057bc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800057be:	00014517          	auipc	a0,0x14
    800057c2:	31a50513          	add	a0,a0,794 # 80019ad8 <bcache>
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	8a8080e7          	jalr	-1880(ra) # 8000306e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800057ce:	0001c497          	auipc	s1,0x1c
    800057d2:	5c24b483          	ld	s1,1474(s1) # 80021d90 <bcache+0x82b8>
    800057d6:	0001c797          	auipc	a5,0x1c
    800057da:	56a78793          	add	a5,a5,1386 # 80021d40 <bcache+0x8268>
    800057de:	02f48f63          	beq	s1,a5,8000581c <bread+0x70>
    800057e2:	873e                	mv	a4,a5
    800057e4:	a021                	j	800057ec <bread+0x40>
    800057e6:	68a4                	ld	s1,80(s1)
    800057e8:	02e48a63          	beq	s1,a4,8000581c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800057ec:	449c                	lw	a5,8(s1)
    800057ee:	ff279ce3          	bne	a5,s2,800057e6 <bread+0x3a>
    800057f2:	44dc                	lw	a5,12(s1)
    800057f4:	ff3799e3          	bne	a5,s3,800057e6 <bread+0x3a>
      b->refcnt++;
    800057f8:	40bc                	lw	a5,64(s1)
    800057fa:	2785                	addw	a5,a5,1
    800057fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800057fe:	00014517          	auipc	a0,0x14
    80005802:	2da50513          	add	a0,a0,730 # 80019ad8 <bcache>
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	91c080e7          	jalr	-1764(ra) # 80003122 <release>
      acquiresleep(&b->lock);
    8000580e:	01048513          	add	a0,s1,16
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	6dc080e7          	jalr	1756(ra) # 80002eee <acquiresleep>
      return b;
    8000581a:	a8b9                	j	80005878 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000581c:	0001c497          	auipc	s1,0x1c
    80005820:	56c4b483          	ld	s1,1388(s1) # 80021d88 <bcache+0x82b0>
    80005824:	0001c797          	auipc	a5,0x1c
    80005828:	51c78793          	add	a5,a5,1308 # 80021d40 <bcache+0x8268>
    8000582c:	00f48863          	beq	s1,a5,8000583c <bread+0x90>
    80005830:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80005832:	40bc                	lw	a5,64(s1)
    80005834:	cf81                	beqz	a5,8000584c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80005836:	64a4                	ld	s1,72(s1)
    80005838:	fee49de3          	bne	s1,a4,80005832 <bread+0x86>
  panic("bget: no buffers");
    8000583c:	00004517          	auipc	a0,0x4
    80005840:	35450513          	add	a0,a0,852 # 80009b90 <syscalls+0x3b8>
    80005844:	ffffc097          	auipc	ra,0xffffc
    80005848:	9c0080e7          	jalr	-1600(ra) # 80001204 <panic>
      b->dev = dev;
    8000584c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80005850:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80005854:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80005858:	4785                	li	a5,1
    8000585a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000585c:	00014517          	auipc	a0,0x14
    80005860:	27c50513          	add	a0,a0,636 # 80019ad8 <bcache>
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	8be080e7          	jalr	-1858(ra) # 80003122 <release>
      acquiresleep(&b->lock);
    8000586c:	01048513          	add	a0,s1,16
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	67e080e7          	jalr	1662(ra) # 80002eee <acquiresleep>
  struct buf *b;
  // printf("bread: reading block %d from device %d\n", blockno, dev);
  
  b = bget(dev, blockno);
  // printf("bread: got buffer for block %d from device %d\n", blockno, dev);
  if(!b->valid) {
    80005878:	409c                	lw	a5,0(s1)
    8000587a:	cb89                	beqz	a5,8000588c <bread+0xe0>
    virtio_disk_rw(b, 0);
    // printf("bread: block %d from device %d read from disk\n", blockno, dev);
    b->valid = 1;
  }
  return b;
}
    8000587c:	8526                	mv	a0,s1
    8000587e:	70a2                	ld	ra,40(sp)
    80005880:	7402                	ld	s0,32(sp)
    80005882:	64e2                	ld	s1,24(sp)
    80005884:	6942                	ld	s2,16(sp)
    80005886:	69a2                	ld	s3,8(sp)
    80005888:	6145                	add	sp,sp,48
    8000588a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000588c:	4581                	li	a1,0
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffb097          	auipc	ra,0xffffb
    80005894:	448080e7          	jalr	1096(ra) # 80000cd8 <virtio_disk_rw>
    b->valid = 1;
    80005898:	4785                	li	a5,1
    8000589a:	c09c                	sw	a5,0(s1)
  return b;
    8000589c:	b7c5                	j	8000587c <bread+0xd0>

000000008000589e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000589e:	1101                	add	sp,sp,-32
    800058a0:	ec06                	sd	ra,24(sp)
    800058a2:	e822                	sd	s0,16(sp)
    800058a4:	e426                	sd	s1,8(sp)
    800058a6:	1000                	add	s0,sp,32
    800058a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800058aa:	0541                	add	a0,a0,16
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	6dc080e7          	jalr	1756(ra) # 80002f88 <holdingsleep>
    800058b4:	cd01                	beqz	a0,800058cc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800058b6:	4585                	li	a1,1
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffb097          	auipc	ra,0xffffb
    800058be:	41e080e7          	jalr	1054(ra) # 80000cd8 <virtio_disk_rw>
}
    800058c2:	60e2                	ld	ra,24(sp)
    800058c4:	6442                	ld	s0,16(sp)
    800058c6:	64a2                	ld	s1,8(sp)
    800058c8:	6105                	add	sp,sp,32
    800058ca:	8082                	ret
    panic("bwrite");
    800058cc:	00004517          	auipc	a0,0x4
    800058d0:	2dc50513          	add	a0,a0,732 # 80009ba8 <syscalls+0x3d0>
    800058d4:	ffffc097          	auipc	ra,0xffffc
    800058d8:	930080e7          	jalr	-1744(ra) # 80001204 <panic>

00000000800058dc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800058dc:	1101                	add	sp,sp,-32
    800058de:	ec06                	sd	ra,24(sp)
    800058e0:	e822                	sd	s0,16(sp)
    800058e2:	e426                	sd	s1,8(sp)
    800058e4:	e04a                	sd	s2,0(sp)
    800058e6:	1000                	add	s0,sp,32
    800058e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800058ea:	01050913          	add	s2,a0,16
    800058ee:	854a                	mv	a0,s2
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	698080e7          	jalr	1688(ra) # 80002f88 <holdingsleep>
    800058f8:	c925                	beqz	a0,80005968 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800058fa:	854a                	mv	a0,s2
    800058fc:	ffffd097          	auipc	ra,0xffffd
    80005900:	648080e7          	jalr	1608(ra) # 80002f44 <releasesleep>

  acquire(&bcache.lock);
    80005904:	00014517          	auipc	a0,0x14
    80005908:	1d450513          	add	a0,a0,468 # 80019ad8 <bcache>
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	762080e7          	jalr	1890(ra) # 8000306e <acquire>
  b->refcnt--;
    80005914:	40bc                	lw	a5,64(s1)
    80005916:	37fd                	addw	a5,a5,-1
    80005918:	0007871b          	sext.w	a4,a5
    8000591c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000591e:	e71d                	bnez	a4,8000594c <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80005920:	68b8                	ld	a4,80(s1)
    80005922:	64bc                	ld	a5,72(s1)
    80005924:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80005926:	68b8                	ld	a4,80(s1)
    80005928:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000592a:	0001c797          	auipc	a5,0x1c
    8000592e:	1ae78793          	add	a5,a5,430 # 80021ad8 <bcache+0x8000>
    80005932:	2b87b703          	ld	a4,696(a5)
    80005936:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80005938:	0001c717          	auipc	a4,0x1c
    8000593c:	40870713          	add	a4,a4,1032 # 80021d40 <bcache+0x8268>
    80005940:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80005942:	2b87b703          	ld	a4,696(a5)
    80005946:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80005948:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000594c:	00014517          	auipc	a0,0x14
    80005950:	18c50513          	add	a0,a0,396 # 80019ad8 <bcache>
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	7ce080e7          	jalr	1998(ra) # 80003122 <release>
}
    8000595c:	60e2                	ld	ra,24(sp)
    8000595e:	6442                	ld	s0,16(sp)
    80005960:	64a2                	ld	s1,8(sp)
    80005962:	6902                	ld	s2,0(sp)
    80005964:	6105                	add	sp,sp,32
    80005966:	8082                	ret
    panic("brelse");
    80005968:	00004517          	auipc	a0,0x4
    8000596c:	24850513          	add	a0,a0,584 # 80009bb0 <syscalls+0x3d8>
    80005970:	ffffc097          	auipc	ra,0xffffc
    80005974:	894080e7          	jalr	-1900(ra) # 80001204 <panic>

0000000080005978 <bpin>:

void
bpin(struct buf *b) {
    80005978:	1101                	add	sp,sp,-32
    8000597a:	ec06                	sd	ra,24(sp)
    8000597c:	e822                	sd	s0,16(sp)
    8000597e:	e426                	sd	s1,8(sp)
    80005980:	1000                	add	s0,sp,32
    80005982:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80005984:	00014517          	auipc	a0,0x14
    80005988:	15450513          	add	a0,a0,340 # 80019ad8 <bcache>
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	6e2080e7          	jalr	1762(ra) # 8000306e <acquire>
  b->refcnt++;
    80005994:	40bc                	lw	a5,64(s1)
    80005996:	2785                	addw	a5,a5,1
    80005998:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000599a:	00014517          	auipc	a0,0x14
    8000599e:	13e50513          	add	a0,a0,318 # 80019ad8 <bcache>
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	780080e7          	jalr	1920(ra) # 80003122 <release>
}
    800059aa:	60e2                	ld	ra,24(sp)
    800059ac:	6442                	ld	s0,16(sp)
    800059ae:	64a2                	ld	s1,8(sp)
    800059b0:	6105                	add	sp,sp,32
    800059b2:	8082                	ret

00000000800059b4 <bunpin>:

void
bunpin(struct buf *b) {
    800059b4:	1101                	add	sp,sp,-32
    800059b6:	ec06                	sd	ra,24(sp)
    800059b8:	e822                	sd	s0,16(sp)
    800059ba:	e426                	sd	s1,8(sp)
    800059bc:	1000                	add	s0,sp,32
    800059be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800059c0:	00014517          	auipc	a0,0x14
    800059c4:	11850513          	add	a0,a0,280 # 80019ad8 <bcache>
    800059c8:	ffffd097          	auipc	ra,0xffffd
    800059cc:	6a6080e7          	jalr	1702(ra) # 8000306e <acquire>
  b->refcnt--;
    800059d0:	40bc                	lw	a5,64(s1)
    800059d2:	37fd                	addw	a5,a5,-1
    800059d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800059d6:	00014517          	auipc	a0,0x14
    800059da:	10250513          	add	a0,a0,258 # 80019ad8 <bcache>
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	744080e7          	jalr	1860(ra) # 80003122 <release>
}
    800059e6:	60e2                	ld	ra,24(sp)
    800059e8:	6442                	ld	s0,16(sp)
    800059ea:	64a2                	ld	s1,8(sp)
    800059ec:	6105                	add	sp,sp,32
    800059ee:	8082                	ret

00000000800059f0 <buf_print>:


// 输出buf_cache的情况
void buf_print()
{
    800059f0:	7159                	add	sp,sp,-112
    800059f2:	f486                	sd	ra,104(sp)
    800059f4:	f0a2                	sd	s0,96(sp)
    800059f6:	eca6                	sd	s1,88(sp)
    800059f8:	e8ca                	sd	s2,80(sp)
    800059fa:	e4ce                	sd	s3,72(sp)
    800059fc:	e0d2                	sd	s4,64(sp)
    800059fe:	fc56                	sd	s5,56(sp)
    80005a00:	f85a                	sd	s6,48(sp)
    80005a02:	f45e                	sd	s7,40(sp)
    80005a04:	f062                	sd	s8,32(sp)
    80005a06:	ec66                	sd	s9,24(sp)
    80005a08:	e86a                	sd	s10,16(sp)
    80005a0a:	e46e                	sd	s11,8(sp)
    80005a0c:	1880                	add	s0,sp,112
    acquire(&bcache.lock);
    80005a0e:	00014517          	auipc	a0,0x14
    80005a12:	0ca50513          	add	a0,a0,202 # 80019ad8 <bcache>
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	658080e7          	jalr	1624(ra) # 8000306e <acquire>
    printf("\nBuffer Cache (Index Order):\n");
    80005a1e:	00004517          	auipc	a0,0x4
    80005a22:	19a50513          	add	a0,a0,410 # 80009bb8 <syscalls+0x3e0>
    80005a26:	ffffc097          	auipc	ra,0xffffc
    80005a2a:	828080e7          	jalr	-2008(ra) # 8000124e <printf>
    printf("IDX  DEV  BLOCK  REF  VALID  DATA\n");
    80005a2e:	00004517          	auipc	a0,0x4
    80005a32:	1aa50513          	add	a0,a0,426 # 80009bd8 <syscalls+0x400>
    80005a36:	ffffc097          	auipc	ra,0xffffc
    80005a3a:	818080e7          	jalr	-2024(ra) # 8000124e <printf>
    for(int i = 0; i < NBUF; i++){
    80005a3e:	00014997          	auipc	s3,0x14
    80005a42:	11298993          	add	s3,s3,274 # 80019b50 <bcache+0x78>
    80005a46:	4b01                	li	s6,0
        struct buf *b = &bcache.buf[i];
        if(b->refcnt > 0 || b->valid || b->blockno != 0) {
            if(i < 10) printf(" ");
    80005a48:	4ca5                	li	s9,9
            printf("%d   ", i);
    80005a4a:	00004d97          	auipc	s11,0x4
    80005a4e:	1bed8d93          	add	s11,s11,446 # 80009c08 <syscalls+0x430>
            
            printf("%d    ", b->dev);
    80005a52:	00004c17          	auipc	s8,0x4
    80005a56:	1bec0c13          	add	s8,s8,446 # 80009c10 <syscalls+0x438>
            
            printf("%d     ", b->blockno);
    80005a5a:	00004d17          	auipc	s10,0x4
    80005a5e:	1bed0d13          	add	s10,s10,446 # 80009c18 <syscalls+0x440>
            printf("%d    ", b->refcnt);
            printf("%d      ", b->valid);
            
            for(int j = 0; j < 8; j++){
                int val = (unsigned char)b->data[j];
                if(val < 16) printf("0");
    80005a62:	4abd                	li	s5,15
    80005a64:	00004b97          	auipc	s7,0x4
    80005a68:	1d4b8b93          	add	s7,s7,468 # 80009c38 <syscalls+0x460>
                printf("%x ", val);
    80005a6c:	00004a17          	auipc	s4,0x4
    80005a70:	1d4a0a13          	add	s4,s4,468 # 80009c40 <syscalls+0x468>
    80005a74:	a045                	j	80005b14 <buf_print+0x124>
            if(i < 10) printf(" ");
    80005a76:	00004517          	auipc	a0,0x4
    80005a7a:	18a50513          	add	a0,a0,394 # 80009c00 <syscalls+0x428>
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	7d0080e7          	jalr	2000(ra) # 8000124e <printf>
    80005a86:	a05d                	j	80005b2c <buf_print+0x13c>
            if(b->blockno < 10) printf("   ");
    80005a88:	00004517          	auipc	a0,0x4
    80005a8c:	19850513          	add	a0,a0,408 # 80009c20 <syscalls+0x448>
    80005a90:	ffffb097          	auipc	ra,0xffffb
    80005a94:	7be080e7          	jalr	1982(ra) # 8000124e <printf>
            printf("%d    ", b->refcnt);
    80005a98:	fe04a583          	lw	a1,-32(s1)
    80005a9c:	8562                	mv	a0,s8
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	7b0080e7          	jalr	1968(ra) # 8000124e <printf>
            printf("%d      ", b->valid);
    80005aa6:	fa04a583          	lw	a1,-96(s1)
    80005aaa:	00004517          	auipc	a0,0x4
    80005aae:	17e50513          	add	a0,a0,382 # 80009c28 <syscalls+0x450>
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	79c080e7          	jalr	1948(ra) # 8000124e <printf>
            for(int j = 0; j < 8; j++){
    80005aba:	ff898493          	add	s1,s3,-8
    80005abe:	a01d                	j	80005ae4 <buf_print+0xf4>
            else if(b->blockno < 100) printf("  ");
    80005ac0:	00004517          	auipc	a0,0x4
    80005ac4:	80850513          	add	a0,a0,-2040 # 800092c8 <digits+0xd8>
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	786080e7          	jalr	1926(ra) # 8000124e <printf>
    80005ad0:	b7e1                	j	80005a98 <buf_print+0xa8>
                printf("%x ", val);
    80005ad2:	85ca                	mv	a1,s2
    80005ad4:	8552                	mv	a0,s4
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	778080e7          	jalr	1912(ra) # 8000124e <printf>
            for(int j = 0; j < 8; j++){
    80005ade:	0485                	add	s1,s1,1
    80005ae0:	01348c63          	beq	s1,s3,80005af8 <buf_print+0x108>
                int val = (unsigned char)b->data[j];
    80005ae4:	0004c903          	lbu	s2,0(s1)
                if(val < 16) printf("0");
    80005ae8:	ff2ac5e3          	blt	s5,s2,80005ad2 <buf_print+0xe2>
    80005aec:	855e                	mv	a0,s7
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	760080e7          	jalr	1888(ra) # 8000124e <printf>
    80005af6:	bff1                	j	80005ad2 <buf_print+0xe2>
            }
            printf("\n");
    80005af8:	00004517          	auipc	a0,0x4
    80005afc:	24050513          	add	a0,a0,576 # 80009d38 <syscalls+0x560>
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	74e080e7          	jalr	1870(ra) # 8000124e <printf>
    for(int i = 0; i < NBUF; i++){
    80005b08:	2b05                	addw	s6,s6,1
    80005b0a:	45898993          	add	s3,s3,1112
    80005b0e:	47f9                	li	a5,30
    80005b10:	06fb0763          	beq	s6,a5,80005b7e <buf_print+0x18e>
        if(b->refcnt > 0 || b->valid || b->blockno != 0) {
    80005b14:	84ce                	mv	s1,s3
    80005b16:	fe09a783          	lw	a5,-32(s3)
    80005b1a:	e799                	bnez	a5,80005b28 <buf_print+0x138>
    80005b1c:	fa09a783          	lw	a5,-96(s3)
    80005b20:	e781                	bnez	a5,80005b28 <buf_print+0x138>
    80005b22:	fac9a783          	lw	a5,-84(s3)
    80005b26:	d3ed                	beqz	a5,80005b08 <buf_print+0x118>
            if(i < 10) printf(" ");
    80005b28:	f56cd7e3          	bge	s9,s6,80005a76 <buf_print+0x86>
            printf("%d   ", i);
    80005b2c:	85da                	mv	a1,s6
    80005b2e:	856e                	mv	a0,s11
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	71e080e7          	jalr	1822(ra) # 8000124e <printf>
            printf("%d    ", b->dev);
    80005b38:	fa84a583          	lw	a1,-88(s1)
    80005b3c:	8562                	mv	a0,s8
    80005b3e:	ffffb097          	auipc	ra,0xffffb
    80005b42:	710080e7          	jalr	1808(ra) # 8000124e <printf>
            printf("%d     ", b->blockno);
    80005b46:	fac4a583          	lw	a1,-84(s1)
    80005b4a:	856a                	mv	a0,s10
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	702080e7          	jalr	1794(ra) # 8000124e <printf>
            if(b->blockno < 10) printf("   ");
    80005b54:	fac4a783          	lw	a5,-84(s1)
    80005b58:	f2fcf8e3          	bgeu	s9,a5,80005a88 <buf_print+0x98>
            else if(b->blockno < 100) printf("  ");
    80005b5c:	06300713          	li	a4,99
    80005b60:	f6f770e3          	bgeu	a4,a5,80005ac0 <buf_print+0xd0>
            else if(b->blockno < 1000) printf(" ");
    80005b64:	3e700713          	li	a4,999
    80005b68:	f2f768e3          	bltu	a4,a5,80005a98 <buf_print+0xa8>
    80005b6c:	00004517          	auipc	a0,0x4
    80005b70:	09450513          	add	a0,a0,148 # 80009c00 <syscalls+0x428>
    80005b74:	ffffb097          	auipc	ra,0xffffb
    80005b78:	6da080e7          	jalr	1754(ra) # 8000124e <printf>
    80005b7c:	bf31                	j	80005a98 <buf_print+0xa8>
        }
    }
    release(&bcache.lock);
    80005b7e:	00014517          	auipc	a0,0x14
    80005b82:	f5a50513          	add	a0,a0,-166 # 80019ad8 <bcache>
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	59c080e7          	jalr	1436(ra) # 80003122 <release>
    80005b8e:	70a6                	ld	ra,104(sp)
    80005b90:	7406                	ld	s0,96(sp)
    80005b92:	64e6                	ld	s1,88(sp)
    80005b94:	6946                	ld	s2,80(sp)
    80005b96:	69a6                	ld	s3,72(sp)
    80005b98:	6a06                	ld	s4,64(sp)
    80005b9a:	7ae2                	ld	s5,56(sp)
    80005b9c:	7b42                	ld	s6,48(sp)
    80005b9e:	7ba2                	ld	s7,40(sp)
    80005ba0:	7c02                	ld	s8,32(sp)
    80005ba2:	6ce2                	ld	s9,24(sp)
    80005ba4:	6d42                	ld	s10,16(sp)
    80005ba6:	6da2                	ld	s11,8(sp)
    80005ba8:	6165                	add	sp,sp,112
    80005baa:	8082                	ret

0000000080005bac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80005bac:	1101                	add	sp,sp,-32
    80005bae:	ec06                	sd	ra,24(sp)
    80005bb0:	e822                	sd	s0,16(sp)
    80005bb2:	e426                	sd	s1,8(sp)
    80005bb4:	e04a                	sd	s2,0(sp)
    80005bb6:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80005bb8:	0001c917          	auipc	s2,0x1c
    80005bbc:	5e090913          	add	s2,s2,1504 # 80022198 <log>
    80005bc0:	01892583          	lw	a1,24(s2)
    80005bc4:	02892503          	lw	a0,40(s2)
    80005bc8:	00000097          	auipc	ra,0x0
    80005bcc:	be4080e7          	jalr	-1052(ra) # 800057ac <bread>
    80005bd0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80005bd2:	02c92603          	lw	a2,44(s2)
    80005bd6:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80005bd8:	00c05f63          	blez	a2,80005bf6 <write_head+0x4a>
    80005bdc:	0001c717          	auipc	a4,0x1c
    80005be0:	5ec70713          	add	a4,a4,1516 # 800221c8 <log+0x30>
    80005be4:	87aa                	mv	a5,a0
    80005be6:	060a                	sll	a2,a2,0x2
    80005be8:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80005bea:	4314                	lw	a3,0(a4)
    80005bec:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80005bee:	0711                	add	a4,a4,4
    80005bf0:	0791                	add	a5,a5,4
    80005bf2:	fec79ce3          	bne	a5,a2,80005bea <write_head+0x3e>
  }
  bwrite(buf);
    80005bf6:	8526                	mv	a0,s1
    80005bf8:	00000097          	auipc	ra,0x0
    80005bfc:	ca6080e7          	jalr	-858(ra) # 8000589e <bwrite>
  brelse(buf);
    80005c00:	8526                	mv	a0,s1
    80005c02:	00000097          	auipc	ra,0x0
    80005c06:	cda080e7          	jalr	-806(ra) # 800058dc <brelse>
}
    80005c0a:	60e2                	ld	ra,24(sp)
    80005c0c:	6442                	ld	s0,16(sp)
    80005c0e:	64a2                	ld	s1,8(sp)
    80005c10:	6902                	ld	s2,0(sp)
    80005c12:	6105                	add	sp,sp,32
    80005c14:	8082                	ret

0000000080005c16 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80005c16:	0001c797          	auipc	a5,0x1c
    80005c1a:	5ae7a783          	lw	a5,1454(a5) # 800221c4 <log+0x2c>
    80005c1e:	0af05d63          	blez	a5,80005cd8 <install_trans+0xc2>
{
    80005c22:	7139                	add	sp,sp,-64
    80005c24:	fc06                	sd	ra,56(sp)
    80005c26:	f822                	sd	s0,48(sp)
    80005c28:	f426                	sd	s1,40(sp)
    80005c2a:	f04a                	sd	s2,32(sp)
    80005c2c:	ec4e                	sd	s3,24(sp)
    80005c2e:	e852                	sd	s4,16(sp)
    80005c30:	e456                	sd	s5,8(sp)
    80005c32:	e05a                	sd	s6,0(sp)
    80005c34:	0080                	add	s0,sp,64
    80005c36:	8b2a                	mv	s6,a0
    80005c38:	0001ca97          	auipc	s5,0x1c
    80005c3c:	590a8a93          	add	s5,s5,1424 # 800221c8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005c40:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005c42:	0001c997          	auipc	s3,0x1c
    80005c46:	55698993          	add	s3,s3,1366 # 80022198 <log>
    80005c4a:	a00d                	j	80005c6c <install_trans+0x56>
    brelse(lbuf);
    80005c4c:	854a                	mv	a0,s2
    80005c4e:	00000097          	auipc	ra,0x0
    80005c52:	c8e080e7          	jalr	-882(ra) # 800058dc <brelse>
    brelse(dbuf);
    80005c56:	8526                	mv	a0,s1
    80005c58:	00000097          	auipc	ra,0x0
    80005c5c:	c84080e7          	jalr	-892(ra) # 800058dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005c60:	2a05                	addw	s4,s4,1
    80005c62:	0a91                	add	s5,s5,4
    80005c64:	02c9a783          	lw	a5,44(s3)
    80005c68:	04fa5e63          	bge	s4,a5,80005cc4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80005c6c:	0189a583          	lw	a1,24(s3)
    80005c70:	014585bb          	addw	a1,a1,s4
    80005c74:	2585                	addw	a1,a1,1
    80005c76:	0289a503          	lw	a0,40(s3)
    80005c7a:	00000097          	auipc	ra,0x0
    80005c7e:	b32080e7          	jalr	-1230(ra) # 800057ac <bread>
    80005c82:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80005c84:	000aa583          	lw	a1,0(s5)
    80005c88:	0289a503          	lw	a0,40(s3)
    80005c8c:	00000097          	auipc	ra,0x0
    80005c90:	b20080e7          	jalr	-1248(ra) # 800057ac <bread>
    80005c94:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80005c96:	40000613          	li	a2,1024
    80005c9a:	05890593          	add	a1,s2,88
    80005c9e:	05850513          	add	a0,a0,88
    80005ca2:	ffffb097          	auipc	ra,0xffffb
    80005ca6:	376080e7          	jalr	886(ra) # 80001018 <memmove>
    bwrite(dbuf);  // write dst to disk
    80005caa:	8526                	mv	a0,s1
    80005cac:	00000097          	auipc	ra,0x0
    80005cb0:	bf2080e7          	jalr	-1038(ra) # 8000589e <bwrite>
    if(recovering == 0)
    80005cb4:	f80b1ce3          	bnez	s6,80005c4c <install_trans+0x36>
      bunpin(dbuf);
    80005cb8:	8526                	mv	a0,s1
    80005cba:	00000097          	auipc	ra,0x0
    80005cbe:	cfa080e7          	jalr	-774(ra) # 800059b4 <bunpin>
    80005cc2:	b769                	j	80005c4c <install_trans+0x36>
}
    80005cc4:	70e2                	ld	ra,56(sp)
    80005cc6:	7442                	ld	s0,48(sp)
    80005cc8:	74a2                	ld	s1,40(sp)
    80005cca:	7902                	ld	s2,32(sp)
    80005ccc:	69e2                	ld	s3,24(sp)
    80005cce:	6a42                	ld	s4,16(sp)
    80005cd0:	6aa2                	ld	s5,8(sp)
    80005cd2:	6b02                	ld	s6,0(sp)
    80005cd4:	6121                	add	sp,sp,64
    80005cd6:	8082                	ret
    80005cd8:	8082                	ret

0000000080005cda <initlog>:
{
    80005cda:	7179                	add	sp,sp,-48
    80005cdc:	f406                	sd	ra,40(sp)
    80005cde:	f022                	sd	s0,32(sp)
    80005ce0:	ec26                	sd	s1,24(sp)
    80005ce2:	e84a                	sd	s2,16(sp)
    80005ce4:	e44e                	sd	s3,8(sp)
    80005ce6:	1800                	add	s0,sp,48
    80005ce8:	892a                	mv	s2,a0
    80005cea:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80005cec:	0001c497          	auipc	s1,0x1c
    80005cf0:	4ac48493          	add	s1,s1,1196 # 80022198 <log>
    80005cf4:	00004597          	auipc	a1,0x4
    80005cf8:	f5458593          	add	a1,a1,-172 # 80009c48 <syscalls+0x470>
    80005cfc:	8526                	mv	a0,s1
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	2e0080e7          	jalr	736(ra) # 80002fde <initlock>
  log.start = sb->logstart;
    80005d06:	0149a583          	lw	a1,20(s3)
    80005d0a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80005d0c:	0109a783          	lw	a5,16(s3)
    80005d10:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80005d12:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80005d16:	854a                	mv	a0,s2
    80005d18:	00000097          	auipc	ra,0x0
    80005d1c:	a94080e7          	jalr	-1388(ra) # 800057ac <bread>
  log.lh.n = lh->n;
    80005d20:	4d30                	lw	a2,88(a0)
    80005d22:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80005d24:	00c05f63          	blez	a2,80005d42 <initlog+0x68>
    80005d28:	87aa                	mv	a5,a0
    80005d2a:	0001c717          	auipc	a4,0x1c
    80005d2e:	49e70713          	add	a4,a4,1182 # 800221c8 <log+0x30>
    80005d32:	060a                	sll	a2,a2,0x2
    80005d34:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80005d36:	4ff4                	lw	a3,92(a5)
    80005d38:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80005d3a:	0791                	add	a5,a5,4
    80005d3c:	0711                	add	a4,a4,4
    80005d3e:	fec79ce3          	bne	a5,a2,80005d36 <initlog+0x5c>
  brelse(buf);
    80005d42:	00000097          	auipc	ra,0x0
    80005d46:	b9a080e7          	jalr	-1126(ra) # 800058dc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80005d4a:	4505                	li	a0,1
    80005d4c:	00000097          	auipc	ra,0x0
    80005d50:	eca080e7          	jalr	-310(ra) # 80005c16 <install_trans>
  log.lh.n = 0;
    80005d54:	0001c797          	auipc	a5,0x1c
    80005d58:	4607a823          	sw	zero,1136(a5) # 800221c4 <log+0x2c>
  write_head(); // clear the log
    80005d5c:	00000097          	auipc	ra,0x0
    80005d60:	e50080e7          	jalr	-432(ra) # 80005bac <write_head>
}
    80005d64:	70a2                	ld	ra,40(sp)
    80005d66:	7402                	ld	s0,32(sp)
    80005d68:	64e2                	ld	s1,24(sp)
    80005d6a:	6942                	ld	s2,16(sp)
    80005d6c:	69a2                	ld	s3,8(sp)
    80005d6e:	6145                	add	sp,sp,48
    80005d70:	8082                	ret

0000000080005d72 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80005d72:	1101                	add	sp,sp,-32
    80005d74:	ec06                	sd	ra,24(sp)
    80005d76:	e822                	sd	s0,16(sp)
    80005d78:	e426                	sd	s1,8(sp)
    80005d7a:	e04a                	sd	s2,0(sp)
    80005d7c:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80005d7e:	0001c517          	auipc	a0,0x1c
    80005d82:	41a50513          	add	a0,a0,1050 # 80022198 <log>
    80005d86:	ffffd097          	auipc	ra,0xffffd
    80005d8a:	2e8080e7          	jalr	744(ra) # 8000306e <acquire>
  while(1){
    if(log.committing){
    80005d8e:	0001c497          	auipc	s1,0x1c
    80005d92:	40a48493          	add	s1,s1,1034 # 80022198 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005d96:	4979                	li	s2,30
    80005d98:	a039                	j	80005da6 <begin_op+0x34>
      sleep(&log, &log.lock);
    80005d9a:	85a6                	mv	a1,s1
    80005d9c:	8526                	mv	a0,s1
    80005d9e:	ffffd097          	auipc	ra,0xffffd
    80005da2:	b82080e7          	jalr	-1150(ra) # 80002920 <sleep>
    if(log.committing){
    80005da6:	50dc                	lw	a5,36(s1)
    80005da8:	fbed                	bnez	a5,80005d9a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005daa:	5098                	lw	a4,32(s1)
    80005dac:	2705                	addw	a4,a4,1
    80005dae:	0027179b          	sllw	a5,a4,0x2
    80005db2:	9fb9                	addw	a5,a5,a4
    80005db4:	0017979b          	sllw	a5,a5,0x1
    80005db8:	54d4                	lw	a3,44(s1)
    80005dba:	9fb5                	addw	a5,a5,a3
    80005dbc:	00f95963          	bge	s2,a5,80005dce <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80005dc0:	85a6                	mv	a1,s1
    80005dc2:	8526                	mv	a0,s1
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	b5c080e7          	jalr	-1188(ra) # 80002920 <sleep>
    80005dcc:	bfe9                	j	80005da6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80005dce:	0001c517          	auipc	a0,0x1c
    80005dd2:	3ca50513          	add	a0,a0,970 # 80022198 <log>
    80005dd6:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	34a080e7          	jalr	842(ra) # 80003122 <release>
      break;
    }
  }
}
    80005de0:	60e2                	ld	ra,24(sp)
    80005de2:	6442                	ld	s0,16(sp)
    80005de4:	64a2                	ld	s1,8(sp)
    80005de6:	6902                	ld	s2,0(sp)
    80005de8:	6105                	add	sp,sp,32
    80005dea:	8082                	ret

0000000080005dec <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005dec:	7139                	add	sp,sp,-64
    80005dee:	fc06                	sd	ra,56(sp)
    80005df0:	f822                	sd	s0,48(sp)
    80005df2:	f426                	sd	s1,40(sp)
    80005df4:	f04a                	sd	s2,32(sp)
    80005df6:	ec4e                	sd	s3,24(sp)
    80005df8:	e852                	sd	s4,16(sp)
    80005dfa:	e456                	sd	s5,8(sp)
    80005dfc:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80005dfe:	0001c497          	auipc	s1,0x1c
    80005e02:	39a48493          	add	s1,s1,922 # 80022198 <log>
    80005e06:	8526                	mv	a0,s1
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	266080e7          	jalr	614(ra) # 8000306e <acquire>
  log.outstanding -= 1;
    80005e10:	509c                	lw	a5,32(s1)
    80005e12:	37fd                	addw	a5,a5,-1
    80005e14:	0007891b          	sext.w	s2,a5
    80005e18:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80005e1a:	50dc                	lw	a5,36(s1)
    80005e1c:	e7b9                	bnez	a5,80005e6a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80005e1e:	04091e63          	bnez	s2,80005e7a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80005e22:	0001c497          	auipc	s1,0x1c
    80005e26:	37648493          	add	s1,s1,886 # 80022198 <log>
    80005e2a:	4785                	li	a5,1
    80005e2c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80005e2e:	8526                	mv	a0,s1
    80005e30:	ffffd097          	auipc	ra,0xffffd
    80005e34:	2f2080e7          	jalr	754(ra) # 80003122 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005e38:	54dc                	lw	a5,44(s1)
    80005e3a:	06f04763          	bgtz	a5,80005ea8 <end_op+0xbc>
    acquire(&log.lock);
    80005e3e:	0001c497          	auipc	s1,0x1c
    80005e42:	35a48493          	add	s1,s1,858 # 80022198 <log>
    80005e46:	8526                	mv	a0,s1
    80005e48:	ffffd097          	auipc	ra,0xffffd
    80005e4c:	226080e7          	jalr	550(ra) # 8000306e <acquire>
    log.committing = 0;
    80005e50:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80005e54:	8526                	mv	a0,s1
    80005e56:	ffffd097          	auipc	ra,0xffffd
    80005e5a:	b38080e7          	jalr	-1224(ra) # 8000298e <wakeup>
    release(&log.lock);
    80005e5e:	8526                	mv	a0,s1
    80005e60:	ffffd097          	auipc	ra,0xffffd
    80005e64:	2c2080e7          	jalr	706(ra) # 80003122 <release>
}
    80005e68:	a03d                	j	80005e96 <end_op+0xaa>
    panic("log.committing");
    80005e6a:	00004517          	auipc	a0,0x4
    80005e6e:	de650513          	add	a0,a0,-538 # 80009c50 <syscalls+0x478>
    80005e72:	ffffb097          	auipc	ra,0xffffb
    80005e76:	392080e7          	jalr	914(ra) # 80001204 <panic>
    wakeup(&log);
    80005e7a:	0001c497          	auipc	s1,0x1c
    80005e7e:	31e48493          	add	s1,s1,798 # 80022198 <log>
    80005e82:	8526                	mv	a0,s1
    80005e84:	ffffd097          	auipc	ra,0xffffd
    80005e88:	b0a080e7          	jalr	-1270(ra) # 8000298e <wakeup>
  release(&log.lock);
    80005e8c:	8526                	mv	a0,s1
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	294080e7          	jalr	660(ra) # 80003122 <release>
}
    80005e96:	70e2                	ld	ra,56(sp)
    80005e98:	7442                	ld	s0,48(sp)
    80005e9a:	74a2                	ld	s1,40(sp)
    80005e9c:	7902                	ld	s2,32(sp)
    80005e9e:	69e2                	ld	s3,24(sp)
    80005ea0:	6a42                	ld	s4,16(sp)
    80005ea2:	6aa2                	ld	s5,8(sp)
    80005ea4:	6121                	add	sp,sp,64
    80005ea6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80005ea8:	0001ca97          	auipc	s5,0x1c
    80005eac:	320a8a93          	add	s5,s5,800 # 800221c8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005eb0:	0001ca17          	auipc	s4,0x1c
    80005eb4:	2e8a0a13          	add	s4,s4,744 # 80022198 <log>
    80005eb8:	018a2583          	lw	a1,24(s4)
    80005ebc:	012585bb          	addw	a1,a1,s2
    80005ec0:	2585                	addw	a1,a1,1
    80005ec2:	028a2503          	lw	a0,40(s4)
    80005ec6:	00000097          	auipc	ra,0x0
    80005eca:	8e6080e7          	jalr	-1818(ra) # 800057ac <bread>
    80005ece:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005ed0:	000aa583          	lw	a1,0(s5)
    80005ed4:	028a2503          	lw	a0,40(s4)
    80005ed8:	00000097          	auipc	ra,0x0
    80005edc:	8d4080e7          	jalr	-1836(ra) # 800057ac <bread>
    80005ee0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005ee2:	40000613          	li	a2,1024
    80005ee6:	05850593          	add	a1,a0,88
    80005eea:	05848513          	add	a0,s1,88
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	12a080e7          	jalr	298(ra) # 80001018 <memmove>
    bwrite(to);  // write the log
    80005ef6:	8526                	mv	a0,s1
    80005ef8:	00000097          	auipc	ra,0x0
    80005efc:	9a6080e7          	jalr	-1626(ra) # 8000589e <bwrite>
    brelse(from);
    80005f00:	854e                	mv	a0,s3
    80005f02:	00000097          	auipc	ra,0x0
    80005f06:	9da080e7          	jalr	-1574(ra) # 800058dc <brelse>
    brelse(to);
    80005f0a:	8526                	mv	a0,s1
    80005f0c:	00000097          	auipc	ra,0x0
    80005f10:	9d0080e7          	jalr	-1584(ra) # 800058dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005f14:	2905                	addw	s2,s2,1
    80005f16:	0a91                	add	s5,s5,4
    80005f18:	02ca2783          	lw	a5,44(s4)
    80005f1c:	f8f94ee3          	blt	s2,a5,80005eb8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80005f20:	00000097          	auipc	ra,0x0
    80005f24:	c8c080e7          	jalr	-884(ra) # 80005bac <write_head>
    install_trans(0); // Now install writes to home locations
    80005f28:	4501                	li	a0,0
    80005f2a:	00000097          	auipc	ra,0x0
    80005f2e:	cec080e7          	jalr	-788(ra) # 80005c16 <install_trans>
    log.lh.n = 0;
    80005f32:	0001c797          	auipc	a5,0x1c
    80005f36:	2807a923          	sw	zero,658(a5) # 800221c4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80005f3a:	00000097          	auipc	ra,0x0
    80005f3e:	c72080e7          	jalr	-910(ra) # 80005bac <write_head>
    80005f42:	bdf5                	j	80005e3e <end_op+0x52>

0000000080005f44 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005f44:	1101                	add	sp,sp,-32
    80005f46:	ec06                	sd	ra,24(sp)
    80005f48:	e822                	sd	s0,16(sp)
    80005f4a:	e426                	sd	s1,8(sp)
    80005f4c:	e04a                	sd	s2,0(sp)
    80005f4e:	1000                	add	s0,sp,32
    80005f50:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80005f52:	0001c917          	auipc	s2,0x1c
    80005f56:	24690913          	add	s2,s2,582 # 80022198 <log>
    80005f5a:	854a                	mv	a0,s2
    80005f5c:	ffffd097          	auipc	ra,0xffffd
    80005f60:	112080e7          	jalr	274(ra) # 8000306e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80005f64:	02c92603          	lw	a2,44(s2)
    80005f68:	47f5                	li	a5,29
    80005f6a:	06c7c563          	blt	a5,a2,80005fd4 <log_write+0x90>
    80005f6e:	0001c797          	auipc	a5,0x1c
    80005f72:	2467a783          	lw	a5,582(a5) # 800221b4 <log+0x1c>
    80005f76:	37fd                	addw	a5,a5,-1
    80005f78:	04f65e63          	bge	a2,a5,80005fd4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005f7c:	0001c797          	auipc	a5,0x1c
    80005f80:	23c7a783          	lw	a5,572(a5) # 800221b8 <log+0x20>
    80005f84:	06f05063          	blez	a5,80005fe4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80005f88:	4781                	li	a5,0
    80005f8a:	06c05563          	blez	a2,80005ff4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005f8e:	44cc                	lw	a1,12(s1)
    80005f90:	0001c717          	auipc	a4,0x1c
    80005f94:	23870713          	add	a4,a4,568 # 800221c8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80005f98:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005f9a:	4314                	lw	a3,0(a4)
    80005f9c:	04b68c63          	beq	a3,a1,80005ff4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80005fa0:	2785                	addw	a5,a5,1
    80005fa2:	0711                	add	a4,a4,4
    80005fa4:	fef61be3          	bne	a2,a5,80005f9a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80005fa8:	0621                	add	a2,a2,8 # 2008 <_entry-0x7fffdff8>
    80005faa:	060a                	sll	a2,a2,0x2
    80005fac:	0001c797          	auipc	a5,0x1c
    80005fb0:	1ec78793          	add	a5,a5,492 # 80022198 <log>
    80005fb4:	97b2                	add	a5,a5,a2
    80005fb6:	44d8                	lw	a4,12(s1)
    80005fb8:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80005fba:	8526                	mv	a0,s1
    80005fbc:	00000097          	auipc	ra,0x0
    80005fc0:	9bc080e7          	jalr	-1604(ra) # 80005978 <bpin>
    log.lh.n++;
    80005fc4:	0001c717          	auipc	a4,0x1c
    80005fc8:	1d470713          	add	a4,a4,468 # 80022198 <log>
    80005fcc:	575c                	lw	a5,44(a4)
    80005fce:	2785                	addw	a5,a5,1
    80005fd0:	d75c                	sw	a5,44(a4)
    80005fd2:	a82d                	j	8000600c <log_write+0xc8>
    panic("too big a transaction");
    80005fd4:	00004517          	auipc	a0,0x4
    80005fd8:	c8c50513          	add	a0,a0,-884 # 80009c60 <syscalls+0x488>
    80005fdc:	ffffb097          	auipc	ra,0xffffb
    80005fe0:	228080e7          	jalr	552(ra) # 80001204 <panic>
    panic("log_write outside of trans");
    80005fe4:	00004517          	auipc	a0,0x4
    80005fe8:	c9450513          	add	a0,a0,-876 # 80009c78 <syscalls+0x4a0>
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	218080e7          	jalr	536(ra) # 80001204 <panic>
  log.lh.block[i] = b->blockno;
    80005ff4:	00878693          	add	a3,a5,8
    80005ff8:	068a                	sll	a3,a3,0x2
    80005ffa:	0001c717          	auipc	a4,0x1c
    80005ffe:	19e70713          	add	a4,a4,414 # 80022198 <log>
    80006002:	9736                	add	a4,a4,a3
    80006004:	44d4                	lw	a3,12(s1)
    80006006:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80006008:	faf609e3          	beq	a2,a5,80005fba <log_write+0x76>
  }
  release(&log.lock);
    8000600c:	0001c517          	auipc	a0,0x1c
    80006010:	18c50513          	add	a0,a0,396 # 80022198 <log>
    80006014:	ffffd097          	auipc	ra,0xffffd
    80006018:	10e080e7          	jalr	270(ra) # 80003122 <release>
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6902                	ld	s2,0(sp)
    80006024:	6105                	add	sp,sp,32
    80006026:	8082                	ret

0000000080006028 <fileinit>:
} ftable;  //这是系统的全局打开文件表

/// @brief 初始化文件表
void
fileinit(void)
{
    80006028:	1141                	add	sp,sp,-16
    8000602a:	e406                	sd	ra,8(sp)
    8000602c:	e022                	sd	s0,0(sp)
    8000602e:	0800                	add	s0,sp,16
  // 初始化文件表锁
  initlock(&ftable.lock, "ftable");
    80006030:	00004597          	auipc	a1,0x4
    80006034:	c6858593          	add	a1,a1,-920 # 80009c98 <syscalls+0x4c0>
    80006038:	0001c517          	auipc	a0,0x1c
    8000603c:	2a850513          	add	a0,a0,680 # 800222e0 <ftable>
    80006040:	ffffd097          	auipc	ra,0xffffd
    80006044:	f9e080e7          	jalr	-98(ra) # 80002fde <initlock>
}
    80006048:	60a2                	ld	ra,8(sp)
    8000604a:	6402                	ld	s0,0(sp)
    8000604c:	0141                	add	sp,sp,16
    8000604e:	8082                	ret

0000000080006050 <filealloc>:

/// @brief 分配一个文件结构体。
struct file*
filealloc(void)
{
    80006050:	1101                	add	sp,sp,-32
    80006052:	ec06                	sd	ra,24(sp)
    80006054:	e822                	sd	s0,16(sp)
    80006056:	e426                	sd	s1,8(sp)
    80006058:	1000                	add	s0,sp,32
  struct file *f;

  // 获取文件表锁
  acquire(&ftable.lock);
    8000605a:	0001c517          	auipc	a0,0x1c
    8000605e:	28650513          	add	a0,a0,646 # 800222e0 <ftable>
    80006062:	ffffd097          	auipc	ra,0xffffd
    80006066:	00c080e7          	jalr	12(ra) # 8000306e <acquire>
  // 遍历文件表寻找空闲的文件结构体
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000606a:	0001c497          	auipc	s1,0x1c
    8000606e:	28e48493          	add	s1,s1,654 # 800222f8 <ftable+0x18>
    80006072:	0001d717          	auipc	a4,0x1d
    80006076:	22670713          	add	a4,a4,550 # 80023298 <sb>
    if(f->ref == 0){
    8000607a:	40dc                	lw	a5,4(s1)
    8000607c:	cf99                	beqz	a5,8000609a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000607e:	02848493          	add	s1,s1,40
    80006082:	fee49ce3          	bne	s1,a4,8000607a <filealloc+0x2a>
      release(&ftable.lock);
      return f;
    }
  }
  // 没有找到空闲的文件结构体
  release(&ftable.lock);
    80006086:	0001c517          	auipc	a0,0x1c
    8000608a:	25a50513          	add	a0,a0,602 # 800222e0 <ftable>
    8000608e:	ffffd097          	auipc	ra,0xffffd
    80006092:	094080e7          	jalr	148(ra) # 80003122 <release>
  return 0;
    80006096:	4481                	li	s1,0
    80006098:	a819                	j	800060ae <filealloc+0x5e>
      f->ref = 1;
    8000609a:	4785                	li	a5,1
    8000609c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000609e:	0001c517          	auipc	a0,0x1c
    800060a2:	24250513          	add	a0,a0,578 # 800222e0 <ftable>
    800060a6:	ffffd097          	auipc	ra,0xffffd
    800060aa:	07c080e7          	jalr	124(ra) # 80003122 <release>
}
    800060ae:	8526                	mv	a0,s1
    800060b0:	60e2                	ld	ra,24(sp)
    800060b2:	6442                	ld	s0,16(sp)
    800060b4:	64a2                	ld	s1,8(sp)
    800060b6:	6105                	add	sp,sp,32
    800060b8:	8082                	ret

00000000800060ba <filedup>:

/// @brief 增加文件f的引用计数。
struct file*
filedup(struct file *f)
{
    800060ba:	1101                	add	sp,sp,-32
    800060bc:	ec06                	sd	ra,24(sp)
    800060be:	e822                	sd	s0,16(sp)
    800060c0:	e426                	sd	s1,8(sp)
    800060c2:	1000                	add	s0,sp,32
    800060c4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800060c6:	0001c517          	auipc	a0,0x1c
    800060ca:	21a50513          	add	a0,a0,538 # 800222e0 <ftable>
    800060ce:	ffffd097          	auipc	ra,0xffffd
    800060d2:	fa0080e7          	jalr	-96(ra) # 8000306e <acquire>
  // 检查文件引用计数的有效性
  if(f->ref < 1)
    800060d6:	40dc                	lw	a5,4(s1)
    800060d8:	02f05263          	blez	a5,800060fc <filedup+0x42>
    panic("filedup");
  // 增加引用计数
  f->ref++;
    800060dc:	2785                	addw	a5,a5,1
    800060de:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800060e0:	0001c517          	auipc	a0,0x1c
    800060e4:	20050513          	add	a0,a0,512 # 800222e0 <ftable>
    800060e8:	ffffd097          	auipc	ra,0xffffd
    800060ec:	03a080e7          	jalr	58(ra) # 80003122 <release>
  return f;
}
    800060f0:	8526                	mv	a0,s1
    800060f2:	60e2                	ld	ra,24(sp)
    800060f4:	6442                	ld	s0,16(sp)
    800060f6:	64a2                	ld	s1,8(sp)
    800060f8:	6105                	add	sp,sp,32
    800060fa:	8082                	ret
    panic("filedup");
    800060fc:	00004517          	auipc	a0,0x4
    80006100:	ba450513          	add	a0,a0,-1116 # 80009ca0 <syscalls+0x4c8>
    80006104:	ffffb097          	auipc	ra,0xffffb
    80006108:	100080e7          	jalr	256(ra) # 80001204 <panic>

000000008000610c <fileclose>:

/// @brief 关闭文件f。（减少引用计数，当引用计数达到0时关闭。）
void
fileclose(struct file *f)
{
    8000610c:	7139                	add	sp,sp,-64
    8000610e:	fc06                	sd	ra,56(sp)
    80006110:	f822                	sd	s0,48(sp)
    80006112:	f426                	sd	s1,40(sp)
    80006114:	f04a                	sd	s2,32(sp)
    80006116:	ec4e                	sd	s3,24(sp)
    80006118:	e852                	sd	s4,16(sp)
    8000611a:	e456                	sd	s5,8(sp)
    8000611c:	0080                	add	s0,sp,64
    8000611e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80006120:	0001c517          	auipc	a0,0x1c
    80006124:	1c050513          	add	a0,a0,448 # 800222e0 <ftable>
    80006128:	ffffd097          	auipc	ra,0xffffd
    8000612c:	f46080e7          	jalr	-186(ra) # 8000306e <acquire>
  // 检查文件引用计数的有效性
  if(f->ref < 1)
    80006130:	40dc                	lw	a5,4(s1)
    80006132:	06f05163          	blez	a5,80006194 <fileclose+0x88>
    panic("fileclose");
  // 减少引用计数，如果仍有其他引用则直接返回
  if(--f->ref > 0){
    80006136:	37fd                	addw	a5,a5,-1
    80006138:	0007871b          	sext.w	a4,a5
    8000613c:	c0dc                	sw	a5,4(s1)
    8000613e:	06e04363          	bgtz	a4,800061a4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  // 保存文件信息的副本
  ff = *f;
    80006142:	0004a903          	lw	s2,0(s1)
    80006146:	0094ca83          	lbu	s5,9(s1)
    8000614a:	0104ba03          	ld	s4,16(s1)
    8000614e:	0184b983          	ld	s3,24(s1)
  // 清除文件表项
  f->ref = 0;
    80006152:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80006156:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000615a:	0001c517          	auipc	a0,0x1c
    8000615e:	18650513          	add	a0,a0,390 # 800222e0 <ftable>
    80006162:	ffffd097          	auipc	ra,0xffffd
    80006166:	fc0080e7          	jalr	-64(ra) # 80003122 <release>

  // 根据文件类型进行相应的清理工作
  if(ff.type == FD_PIPE){
    8000616a:	4785                	li	a5,1
    8000616c:	04f90d63          	beq	s2,a5,800061c6 <fileclose+0xba>
    // 关闭管道
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80006170:	3979                	addw	s2,s2,-2
    80006172:	4785                	li	a5,1
    80006174:	0527e063          	bltu	a5,s2,800061b4 <fileclose+0xa8>
    // 释放inode引用
    //对于涉及文件系统的操作，还需要begin_op和end_op
    //在进行一个inode操作前后，必须添加这种资源获取与释放的对应操作
    //详情参看实验指导书8.6代码：日志（https://xv6.dgs.zone/tranlate_books/book-riscv-rev1/c8/s6.html）
    begin_op();
    80006178:	00000097          	auipc	ra,0x0
    8000617c:	bfa080e7          	jalr	-1030(ra) # 80005d72 <begin_op>
    iput(ff.ip);
    80006180:	854e                	mv	a0,s3
    80006182:	fffff097          	auipc	ra,0xfffff
    80006186:	118080e7          	jalr	280(ra) # 8000529a <iput>
    end_op();
    8000618a:	00000097          	auipc	ra,0x0
    8000618e:	c62080e7          	jalr	-926(ra) # 80005dec <end_op>
    80006192:	a00d                	j	800061b4 <fileclose+0xa8>
    panic("fileclose");
    80006194:	00004517          	auipc	a0,0x4
    80006198:	b1450513          	add	a0,a0,-1260 # 80009ca8 <syscalls+0x4d0>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	068080e7          	jalr	104(ra) # 80001204 <panic>
    release(&ftable.lock);
    800061a4:	0001c517          	auipc	a0,0x1c
    800061a8:	13c50513          	add	a0,a0,316 # 800222e0 <ftable>
    800061ac:	ffffd097          	auipc	ra,0xffffd
    800061b0:	f76080e7          	jalr	-138(ra) # 80003122 <release>
  }
}
    800061b4:	70e2                	ld	ra,56(sp)
    800061b6:	7442                	ld	s0,48(sp)
    800061b8:	74a2                	ld	s1,40(sp)
    800061ba:	7902                	ld	s2,32(sp)
    800061bc:	69e2                	ld	s3,24(sp)
    800061be:	6a42                	ld	s4,16(sp)
    800061c0:	6aa2                	ld	s5,8(sp)
    800061c2:	6121                	add	sp,sp,64
    800061c4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800061c6:	85d6                	mv	a1,s5
    800061c8:	8552                	mv	a0,s4
    800061ca:	00001097          	auipc	ra,0x1
    800061ce:	8fc080e7          	jalr	-1796(ra) # 80006ac6 <pipeclose>
    800061d2:	b7cd                	j	800061b4 <fileclose+0xa8>

00000000800061d4 <filestat>:

/// @brief 获取文件f的元数据。
/// addr是用户虚拟地址，指向struct stat。
int
filestat(struct file *f, uint64 addr)
{
    800061d4:	715d                	add	sp,sp,-80
    800061d6:	e486                	sd	ra,72(sp)
    800061d8:	e0a2                	sd	s0,64(sp)
    800061da:	fc26                	sd	s1,56(sp)
    800061dc:	f84a                	sd	s2,48(sp)
    800061de:	f44e                	sd	s3,40(sp)
    800061e0:	0880                	add	s0,sp,80
    800061e2:	84aa                	mv	s1,a0
    800061e4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800061e6:	ffffc097          	auipc	ra,0xffffc
    800061ea:	f7e080e7          	jalr	-130(ra) # 80002164 <myproc>
  struct stat st;
  
  // 只有inode和设备文件支持stat操作
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800061ee:	409c                	lw	a5,0(s1)
    800061f0:	37f9                	addw	a5,a5,-2
    800061f2:	4705                	li	a4,1
    800061f4:	04f76763          	bltu	a4,a5,80006242 <filestat+0x6e>
    800061f8:	892a                	mv	s2,a0
    // 锁定inode并获取stat信息
    ilock(f->ip);
    800061fa:	6c88                	ld	a0,24(s1)
    800061fc:	fffff097          	auipc	ra,0xfffff
    80006200:	ee4080e7          	jalr	-284(ra) # 800050e0 <ilock>
    stati(f->ip, &st);
    80006204:	fb840593          	add	a1,s0,-72
    80006208:	6c88                	ld	a0,24(s1)
    8000620a:	fffff097          	auipc	ra,0xfffff
    8000620e:	160080e7          	jalr	352(ra) # 8000536a <stati>
    iunlock(f->ip);
    80006212:	6c88                	ld	a0,24(s1)
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	f8e080e7          	jalr	-114(ra) # 800051a2 <iunlock>
    // 将stat信息复制到用户空间
    if(copyout(p->pgtbl, addr, (char *)&st, sizeof(st)) < 0)
    8000621c:	46e1                	li	a3,24
    8000621e:	fb840613          	add	a2,s0,-72
    80006222:	85ce                	mv	a1,s3
    80006224:	04893503          	ld	a0,72(s2)
    80006228:	ffffc097          	auipc	ra,0xffffc
    8000622c:	d08080e7          	jalr	-760(ra) # 80001f30 <copyout>
    80006230:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80006234:	60a6                	ld	ra,72(sp)
    80006236:	6406                	ld	s0,64(sp)
    80006238:	74e2                	ld	s1,56(sp)
    8000623a:	7942                	ld	s2,48(sp)
    8000623c:	79a2                	ld	s3,40(sp)
    8000623e:	6161                	add	sp,sp,80
    80006240:	8082                	ret
  return -1;
    80006242:	557d                	li	a0,-1
    80006244:	bfc5                	j	80006234 <filestat+0x60>

0000000080006246 <fileread>:

/// @brief 从文件f读取数据。
/// addr是用户虚拟地址。
int
fileread(struct file *f, uint64 addr, int n)
{
    80006246:	7179                	add	sp,sp,-48
    80006248:	f406                	sd	ra,40(sp)
    8000624a:	f022                	sd	s0,32(sp)
    8000624c:	ec26                	sd	s1,24(sp)
    8000624e:	e84a                	sd	s2,16(sp)
    80006250:	e44e                	sd	s3,8(sp)
    80006252:	1800                	add	s0,sp,48
  int r = 0;

  // 检查文件是否可读
  if(f->readable == 0)
    80006254:	00854783          	lbu	a5,8(a0)
    80006258:	c3d5                	beqz	a5,800062fc <fileread+0xb6>
    8000625a:	84aa                	mv	s1,a0
    8000625c:	89ae                	mv	s3,a1
    8000625e:	8932                	mv	s2,a2
    return -1;

  // 根据文件类型执行不同的读取操作
  if(f->type == FD_PIPE){
    80006260:	411c                	lw	a5,0(a0)
    80006262:	4705                	li	a4,1
    80006264:	04e78963          	beq	a5,a4,800062b6 <fileread+0x70>
    // 从管道读取
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80006268:	470d                	li	a4,3
    8000626a:	04e78d63          	beq	a5,a4,800062c4 <fileread+0x7e>
    // 从设备读取
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000626e:	4709                	li	a4,2
    80006270:	06e79e63          	bne	a5,a4,800062ec <fileread+0xa6>
    // 从inode文件读取
    ilock(f->ip);
    80006274:	6d08                	ld	a0,24(a0)
    80006276:	fffff097          	auipc	ra,0xfffff
    8000627a:	e6a080e7          	jalr	-406(ra) # 800050e0 <ilock>
    // 从当前偏移量处读取数据
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000627e:	874a                	mv	a4,s2
    80006280:	5094                	lw	a3,32(s1)
    80006282:	864e                	mv	a2,s3
    80006284:	4585                	li	a1,1
    80006286:	6c88                	ld	a0,24(s1)
    80006288:	fffff097          	auipc	ra,0xfffff
    8000628c:	10c080e7          	jalr	268(ra) # 80005394 <readi>
    80006290:	892a                	mv	s2,a0
    80006292:	00a05563          	blez	a0,8000629c <fileread+0x56>
      f->off += r; // 更新文件偏移量
    80006296:	509c                	lw	a5,32(s1)
    80006298:	9fa9                	addw	a5,a5,a0
    8000629a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000629c:	6c88                	ld	a0,24(s1)
    8000629e:	fffff097          	auipc	ra,0xfffff
    800062a2:	f04080e7          	jalr	-252(ra) # 800051a2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800062a6:	854a                	mv	a0,s2
    800062a8:	70a2                	ld	ra,40(sp)
    800062aa:	7402                	ld	s0,32(sp)
    800062ac:	64e2                	ld	s1,24(sp)
    800062ae:	6942                	ld	s2,16(sp)
    800062b0:	69a2                	ld	s3,8(sp)
    800062b2:	6145                	add	sp,sp,48
    800062b4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800062b6:	6908                	ld	a0,16(a0)
    800062b8:	00001097          	auipc	ra,0x1
    800062bc:	978080e7          	jalr	-1672(ra) # 80006c30 <piperead>
    800062c0:	892a                	mv	s2,a0
    800062c2:	b7d5                	j	800062a6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800062c4:	02451783          	lh	a5,36(a0)
    800062c8:	03079693          	sll	a3,a5,0x30
    800062cc:	92c1                	srl	a3,a3,0x30
    800062ce:	4725                	li	a4,9
    800062d0:	02d76863          	bltu	a4,a3,80006300 <fileread+0xba>
    800062d4:	0792                	sll	a5,a5,0x4
    800062d6:	0001c717          	auipc	a4,0x1c
    800062da:	f6a70713          	add	a4,a4,-150 # 80022240 <devsw>
    800062de:	97ba                	add	a5,a5,a4
    800062e0:	639c                	ld	a5,0(a5)
    800062e2:	c38d                	beqz	a5,80006304 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800062e4:	4505                	li	a0,1
    800062e6:	9782                	jalr	a5
    800062e8:	892a                	mv	s2,a0
    800062ea:	bf75                	j	800062a6 <fileread+0x60>
    panic("fileread");
    800062ec:	00004517          	auipc	a0,0x4
    800062f0:	9cc50513          	add	a0,a0,-1588 # 80009cb8 <syscalls+0x4e0>
    800062f4:	ffffb097          	auipc	ra,0xffffb
    800062f8:	f10080e7          	jalr	-240(ra) # 80001204 <panic>
    return -1;
    800062fc:	597d                	li	s2,-1
    800062fe:	b765                	j	800062a6 <fileread+0x60>
      return -1;
    80006300:	597d                	li	s2,-1
    80006302:	b755                	j	800062a6 <fileread+0x60>
    80006304:	597d                	li	s2,-1
    80006306:	b745                	j	800062a6 <fileread+0x60>

0000000080006308 <filewrite>:
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  // 检查文件是否可写
  if(f->writable == 0)
    80006308:	00954783          	lbu	a5,9(a0)
    8000630c:	10078e63          	beqz	a5,80006428 <filewrite+0x120>
{
    80006310:	715d                	add	sp,sp,-80
    80006312:	e486                	sd	ra,72(sp)
    80006314:	e0a2                	sd	s0,64(sp)
    80006316:	fc26                	sd	s1,56(sp)
    80006318:	f84a                	sd	s2,48(sp)
    8000631a:	f44e                	sd	s3,40(sp)
    8000631c:	f052                	sd	s4,32(sp)
    8000631e:	ec56                	sd	s5,24(sp)
    80006320:	e85a                	sd	s6,16(sp)
    80006322:	e45e                	sd	s7,8(sp)
    80006324:	e062                	sd	s8,0(sp)
    80006326:	0880                	add	s0,sp,80
    80006328:	892a                	mv	s2,a0
    8000632a:	8b2e                	mv	s6,a1
    8000632c:	8a32                	mv	s4,a2
    return -1;

  // 根据文件类型执行不同的写入操作
  if(f->type == FD_PIPE){
    8000632e:	411c                	lw	a5,0(a0)
    80006330:	4705                	li	a4,1
    80006332:	02e78263          	beq	a5,a4,80006356 <filewrite+0x4e>
    // 向管道写入
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80006336:	470d                	li	a4,3
    80006338:	02e78563          	beq	a5,a4,80006362 <filewrite+0x5a>
    // 向设备写入
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000633c:	4709                	li	a4,2
    8000633e:	0ce79d63          	bne	a5,a4,80006418 <filewrite+0x110>
    // 这实际上应该在更低层，因为writei()
    // 可能正在写入像控制台这样的设备。
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    // 分批写入数据
    while(i < n){
    80006342:	0ac05b63          	blez	a2,800063f8 <filewrite+0xf0>
    int i = 0;
    80006346:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80006348:	6b85                	lui	s7,0x1
    8000634a:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000634e:	6c05                	lui	s8,0x1
    80006350:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80006354:	a851                	j	800063e8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80006356:	6908                	ld	a0,16(a0)
    80006358:	00000097          	auipc	ra,0x0
    8000635c:	7e0080e7          	jalr	2016(ra) # 80006b38 <pipewrite>
    80006360:	a045                	j	80006400 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80006362:	02451783          	lh	a5,36(a0)
    80006366:	03079693          	sll	a3,a5,0x30
    8000636a:	92c1                	srl	a3,a3,0x30
    8000636c:	4725                	li	a4,9
    8000636e:	0ad76f63          	bltu	a4,a3,8000642c <filewrite+0x124>
    80006372:	0792                	sll	a5,a5,0x4
    80006374:	0001c717          	auipc	a4,0x1c
    80006378:	ecc70713          	add	a4,a4,-308 # 80022240 <devsw>
    8000637c:	97ba                	add	a5,a5,a4
    8000637e:	679c                	ld	a5,8(a5)
    80006380:	cbc5                	beqz	a5,80006430 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80006382:	4505                	li	a0,1
    80006384:	9782                	jalr	a5
    80006386:	a8ad                	j	80006400 <filewrite+0xf8>
      if(n1 > max)
    80006388:	00048a9b          	sext.w	s5,s1
        n1 = max;

      // 开始操作事务
      begin_op();
    8000638c:	00000097          	auipc	ra,0x0
    80006390:	9e6080e7          	jalr	-1562(ra) # 80005d72 <begin_op>
      ilock(f->ip);
    80006394:	01893503          	ld	a0,24(s2)
    80006398:	fffff097          	auipc	ra,0xfffff
    8000639c:	d48080e7          	jalr	-696(ra) # 800050e0 <ilock>
      // 写入数据并更新文件偏移量
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800063a0:	8756                	mv	a4,s5
    800063a2:	02092683          	lw	a3,32(s2)
    800063a6:	01698633          	add	a2,s3,s6
    800063aa:	4585                	li	a1,1
    800063ac:	01893503          	ld	a0,24(s2)
    800063b0:	fffff097          	auipc	ra,0xfffff
    800063b4:	0dc080e7          	jalr	220(ra) # 8000548c <writei>
    800063b8:	84aa                	mv	s1,a0
    800063ba:	00a05763          	blez	a0,800063c8 <filewrite+0xc0>
        f->off += r;
    800063be:	02092783          	lw	a5,32(s2)
    800063c2:	9fa9                	addw	a5,a5,a0
    800063c4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800063c8:	01893503          	ld	a0,24(s2)
    800063cc:	fffff097          	auipc	ra,0xfffff
    800063d0:	dd6080e7          	jalr	-554(ra) # 800051a2 <iunlock>
      // 结束操作事务
      end_op();
    800063d4:	00000097          	auipc	ra,0x0
    800063d8:	a18080e7          	jalr	-1512(ra) # 80005dec <end_op>

      // 检查写入是否成功
      if(r != n1){
    800063dc:	009a9f63          	bne	s5,s1,800063fa <filewrite+0xf2>
        // writei出错
        break;
      }
      i += r;
    800063e0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800063e4:	0149db63          	bge	s3,s4,800063fa <filewrite+0xf2>
      int n1 = n - i;
    800063e8:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800063ec:	0004879b          	sext.w	a5,s1
    800063f0:	f8fbdce3          	bge	s7,a5,80006388 <filewrite+0x80>
    800063f4:	84e2                	mv	s1,s8
    800063f6:	bf49                	j	80006388 <filewrite+0x80>
    int i = 0;
    800063f8:	4981                	li	s3,0
    }
    // 如果全部写入成功返回n，否则返回-1
    ret = (i == n ? n : -1);
    800063fa:	033a1d63          	bne	s4,s3,80006434 <filewrite+0x12c>
    800063fe:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80006400:	60a6                	ld	ra,72(sp)
    80006402:	6406                	ld	s0,64(sp)
    80006404:	74e2                	ld	s1,56(sp)
    80006406:	7942                	ld	s2,48(sp)
    80006408:	79a2                	ld	s3,40(sp)
    8000640a:	7a02                	ld	s4,32(sp)
    8000640c:	6ae2                	ld	s5,24(sp)
    8000640e:	6b42                	ld	s6,16(sp)
    80006410:	6ba2                	ld	s7,8(sp)
    80006412:	6c02                	ld	s8,0(sp)
    80006414:	6161                	add	sp,sp,80
    80006416:	8082                	ret
    panic("filewrite");
    80006418:	00004517          	auipc	a0,0x4
    8000641c:	8b050513          	add	a0,a0,-1872 # 80009cc8 <syscalls+0x4f0>
    80006420:	ffffb097          	auipc	ra,0xffffb
    80006424:	de4080e7          	jalr	-540(ra) # 80001204 <panic>
    return -1;
    80006428:	557d                	li	a0,-1
}
    8000642a:	8082                	ret
      return -1;
    8000642c:	557d                	li	a0,-1
    8000642e:	bfc9                	j	80006400 <filewrite+0xf8>
    80006430:	557d                	li	a0,-1
    80006432:	b7f9                	j	80006400 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80006434:	557d                	li	a0,-1
    80006436:	b7e9                	j	80006400 <filewrite+0xf8>

0000000080006438 <file_lseek>:

// 修改file->offset (只针对FD_FILE类型的文件)
uint32 file_lseek(struct file* file , uint32 offset, int flags)
{
  if(file->type != FD_INODE){
    80006438:	4118                	lw	a4,0(a0)
    8000643a:	4789                	li	a5,2
    8000643c:	00f70463          	beq	a4,a5,80006444 <file_lseek+0xc>
    return -1;
    80006440:	557d                	li	a0,-1
  }

  file->off = new_offset;
  iunlock(file->ip);
  return new_offset;
}
    80006442:	8082                	ret
{
    80006444:	7179                	add	sp,sp,-48
    80006446:	f406                	sd	ra,40(sp)
    80006448:	f022                	sd	s0,32(sp)
    8000644a:	ec26                	sd	s1,24(sp)
    8000644c:	e84a                	sd	s2,16(sp)
    8000644e:	e44e                	sd	s3,8(sp)
    80006450:	1800                	add	s0,sp,48
    80006452:	89aa                	mv	s3,a0
    80006454:	84ae                	mv	s1,a1
    80006456:	8932                	mv	s2,a2
  ilock(file->ip);
    80006458:	6d08                	ld	a0,24(a0)
    8000645a:	fffff097          	auipc	ra,0xfffff
    8000645e:	c86080e7          	jalr	-890(ra) # 800050e0 <ilock>
  switch(flags){
    80006462:	4785                	li	a5,1
    80006464:	00f90f63          	beq	s2,a5,80006482 <file_lseek+0x4a>
    80006468:	4789                	li	a5,2
    8000646a:	04f90263          	beq	s2,a5,800064ae <file_lseek+0x76>
    8000646e:	00090d63          	beqz	s2,80006488 <file_lseek+0x50>
      iunlock(file->ip);
    80006472:	0189b503          	ld	a0,24(s3)
    80006476:	fffff097          	auipc	ra,0xfffff
    8000647a:	d2c080e7          	jalr	-724(ra) # 800051a2 <iunlock>
      return -1;
    8000647e:	557d                	li	a0,-1
    80006480:	a005                	j	800064a0 <file_lseek+0x68>
      new_offset = file->off + offset;
    80006482:	0209a783          	lw	a5,32(s3)
    80006486:	9cbd                	addw	s1,s1,a5
  if(new_offset > file->ip->size){
    80006488:	0189b503          	ld	a0,24(s3)
    8000648c:	457c                	lw	a5,76(a0)
    8000648e:	0297e563          	bltu	a5,s1,800064b8 <file_lseek+0x80>
  file->off = new_offset;
    80006492:	0299a023          	sw	s1,32(s3)
  iunlock(file->ip);
    80006496:	fffff097          	auipc	ra,0xfffff
    8000649a:	d0c080e7          	jalr	-756(ra) # 800051a2 <iunlock>
  return new_offset;
    8000649e:	8526                	mv	a0,s1
}
    800064a0:	70a2                	ld	ra,40(sp)
    800064a2:	7402                	ld	s0,32(sp)
    800064a4:	64e2                	ld	s1,24(sp)
    800064a6:	6942                	ld	s2,16(sp)
    800064a8:	69a2                	ld	s3,8(sp)
    800064aa:	6145                	add	sp,sp,48
    800064ac:	8082                	ret
      new_offset = file->ip->size + offset;
    800064ae:	0189b783          	ld	a5,24(s3)
    800064b2:	47fc                	lw	a5,76(a5)
    800064b4:	9cbd                	addw	s1,s1,a5
      break;
    800064b6:	bfc9                	j	80006488 <file_lseek+0x50>
    iunlock(file->ip);
    800064b8:	fffff097          	auipc	ra,0xfffff
    800064bc:	cea080e7          	jalr	-790(ra) # 800051a2 <iunlock>
    return -1;
    800064c0:	557d                	li	a0,-1
    800064c2:	bff9                	j	800064a0 <file_lseek+0x68>

00000000800064c4 <namecmp>:
#include "fs.h"
#include "buf.h"
#include "file.h"

int namecmp(const char *s, const char *t)
{
    800064c4:	1141                	add	sp,sp,-16
    800064c6:	e406                	sd	ra,8(sp)
    800064c8:	e022                	sd	s0,0(sp)
    800064ca:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800064cc:	4639                	li	a2,14
    800064ce:	ffffb097          	auipc	ra,0xffffb
    800064d2:	bbe080e7          	jalr	-1090(ra) # 8000108c <strncmp>
}
    800064d6:	60a2                	ld	ra,8(sp)
    800064d8:	6402                	ld	s0,0(sp)
    800064da:	0141                	add	sp,sp,16
    800064dc:	8082                	ret

00000000800064de <dirlookup>:

struct inode *
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800064de:	7139                	add	sp,sp,-64
    800064e0:	fc06                	sd	ra,56(sp)
    800064e2:	f822                	sd	s0,48(sp)
    800064e4:	f426                	sd	s1,40(sp)
    800064e6:	f04a                	sd	s2,32(sp)
    800064e8:	ec4e                	sd	s3,24(sp)
    800064ea:	e852                	sd	s4,16(sp)
    800064ec:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if (dp->type != T_DIR)
    800064ee:	04451703          	lh	a4,68(a0)
    800064f2:	4785                	li	a5,1
    800064f4:	00f71a63          	bne	a4,a5,80006508 <dirlookup+0x2a>
    800064f8:	892a                	mv	s2,a0
    800064fa:	89ae                	mv	s3,a1
    800064fc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for (off = 0; off < dp->size; off += sizeof(de))
    800064fe:	457c                	lw	a5,76(a0)
    80006500:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80006502:	4501                	li	a0,0
  for (off = 0; off < dp->size; off += sizeof(de))
    80006504:	e79d                	bnez	a5,80006532 <dirlookup+0x54>
    80006506:	a8a5                	j	8000657e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80006508:	00003517          	auipc	a0,0x3
    8000650c:	7d050513          	add	a0,a0,2000 # 80009cd8 <syscalls+0x500>
    80006510:	ffffb097          	auipc	ra,0xffffb
    80006514:	cf4080e7          	jalr	-780(ra) # 80001204 <panic>
      panic("dirlookup read");
    80006518:	00003517          	auipc	a0,0x3
    8000651c:	7d850513          	add	a0,a0,2008 # 80009cf0 <syscalls+0x518>
    80006520:	ffffb097          	auipc	ra,0xffffb
    80006524:	ce4080e7          	jalr	-796(ra) # 80001204 <panic>
  for (off = 0; off < dp->size; off += sizeof(de))
    80006528:	24c1                	addw	s1,s1,16
    8000652a:	04c92783          	lw	a5,76(s2)
    8000652e:	04f4f763          	bgeu	s1,a5,8000657c <dirlookup+0x9e>
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006532:	4741                	li	a4,16
    80006534:	86a6                	mv	a3,s1
    80006536:	fc040613          	add	a2,s0,-64
    8000653a:	4581                	li	a1,0
    8000653c:	854a                	mv	a0,s2
    8000653e:	fffff097          	auipc	ra,0xfffff
    80006542:	e56080e7          	jalr	-426(ra) # 80005394 <readi>
    80006546:	47c1                	li	a5,16
    80006548:	fcf518e3          	bne	a0,a5,80006518 <dirlookup+0x3a>
    if (de.inum == 0)
    8000654c:	fc045783          	lhu	a5,-64(s0)
    80006550:	dfe1                	beqz	a5,80006528 <dirlookup+0x4a>
    if (namecmp(name, de.name) == 0)
    80006552:	fc240593          	add	a1,s0,-62
    80006556:	854e                	mv	a0,s3
    80006558:	00000097          	auipc	ra,0x0
    8000655c:	f6c080e7          	jalr	-148(ra) # 800064c4 <namecmp>
    80006560:	f561                	bnez	a0,80006528 <dirlookup+0x4a>
      if (poff)
    80006562:	000a0463          	beqz	s4,8000656a <dirlookup+0x8c>
        *poff = off;
    80006566:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000656a:	fc045583          	lhu	a1,-64(s0)
    8000656e:	00092503          	lw	a0,0(s2)
    80006572:	fffff097          	auipc	ra,0xfffff
    80006576:	91a080e7          	jalr	-1766(ra) # 80004e8c <iget>
    8000657a:	a011                	j	8000657e <dirlookup+0xa0>
  return 0;
    8000657c:	4501                	li	a0,0
}
    8000657e:	70e2                	ld	ra,56(sp)
    80006580:	7442                	ld	s0,48(sp)
    80006582:	74a2                	ld	s1,40(sp)
    80006584:	7902                	ld	s2,32(sp)
    80006586:	69e2                	ld	s3,24(sp)
    80006588:	6a42                	ld	s4,16(sp)
    8000658a:	6121                	add	sp,sp,64
    8000658c:	8082                	ret

000000008000658e <namex>:
  return path;
}

static struct inode *
namex(char *path, int nameiparent, char *name)
{
    8000658e:	711d                	add	sp,sp,-96
    80006590:	ec86                	sd	ra,88(sp)
    80006592:	e8a2                	sd	s0,80(sp)
    80006594:	e4a6                	sd	s1,72(sp)
    80006596:	e0ca                	sd	s2,64(sp)
    80006598:	fc4e                	sd	s3,56(sp)
    8000659a:	f852                	sd	s4,48(sp)
    8000659c:	f456                	sd	s5,40(sp)
    8000659e:	f05a                	sd	s6,32(sp)
    800065a0:	ec5e                	sd	s7,24(sp)
    800065a2:	e862                	sd	s8,16(sp)
    800065a4:	e466                	sd	s9,8(sp)
    800065a6:	1080                	add	s0,sp,96
    800065a8:	84aa                	mv	s1,a0
    800065aa:	8b2e                	mv	s6,a1
    800065ac:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if (*path == '/')
    800065ae:	00054703          	lbu	a4,0(a0)
    800065b2:	02f00793          	li	a5,47
    800065b6:	02f70163          	beq	a4,a5,800065d8 <namex+0x4a>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800065ba:	ffffc097          	auipc	ra,0xffffc
    800065be:	baa080e7          	jalr	-1110(ra) # 80002164 <myproc>
    800065c2:	7168                	ld	a0,224(a0)
    800065c4:	fffff097          	auipc	ra,0xfffff
    800065c8:	ade080e7          	jalr	-1314(ra) # 800050a2 <idup>
    800065cc:	8a2a                	mv	s4,a0
  while (*path == '/')
    800065ce:	02f00913          	li	s2,47
  if (len >= DIRSIZ)
    800065d2:	4c35                	li	s8,13

  while ((path = skipelem(path, name)) != 0)
  {
    ilock(ip);
    if (ip->type != T_DIR)
    800065d4:	4b85                	li	s7,1
    800065d6:	a875                	j	80006692 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800065d8:	4585                	li	a1,1
    800065da:	4505                	li	a0,1
    800065dc:	fffff097          	auipc	ra,0xfffff
    800065e0:	8b0080e7          	jalr	-1872(ra) # 80004e8c <iget>
    800065e4:	8a2a                	mv	s4,a0
    800065e6:	b7e5                	j	800065ce <namex+0x40>
    {
      iunlockput(ip);
    800065e8:	8552                	mv	a0,s4
    800065ea:	fffff097          	auipc	ra,0xfffff
    800065ee:	d58080e7          	jalr	-680(ra) # 80005342 <iunlockput>
      return 0;
    800065f2:	4a01                	li	s4,0
  {
    iput(ip);
    return 0;
  }
  return ip;
}
    800065f4:	8552                	mv	a0,s4
    800065f6:	60e6                	ld	ra,88(sp)
    800065f8:	6446                	ld	s0,80(sp)
    800065fa:	64a6                	ld	s1,72(sp)
    800065fc:	6906                	ld	s2,64(sp)
    800065fe:	79e2                	ld	s3,56(sp)
    80006600:	7a42                	ld	s4,48(sp)
    80006602:	7aa2                	ld	s5,40(sp)
    80006604:	7b02                	ld	s6,32(sp)
    80006606:	6be2                	ld	s7,24(sp)
    80006608:	6c42                	ld	s8,16(sp)
    8000660a:	6ca2                	ld	s9,8(sp)
    8000660c:	6125                	add	sp,sp,96
    8000660e:	8082                	ret
      iunlock(ip);
    80006610:	8552                	mv	a0,s4
    80006612:	fffff097          	auipc	ra,0xfffff
    80006616:	b90080e7          	jalr	-1136(ra) # 800051a2 <iunlock>
      return ip;
    8000661a:	bfe9                	j	800065f4 <namex+0x66>
      iunlockput(ip);
    8000661c:	8552                	mv	a0,s4
    8000661e:	fffff097          	auipc	ra,0xfffff
    80006622:	d24080e7          	jalr	-732(ra) # 80005342 <iunlockput>
      return 0;
    80006626:	8a4e                	mv	s4,s3
    80006628:	b7f1                	j	800065f4 <namex+0x66>
  len = path - s;
    8000662a:	40998633          	sub	a2,s3,s1
    8000662e:	00060c9b          	sext.w	s9,a2
  if (len >= DIRSIZ)
    80006632:	099c5863          	bge	s8,s9,800066c2 <namex+0x134>
    memmove(name, s, DIRSIZ);
    80006636:	4639                	li	a2,14
    80006638:	85a6                	mv	a1,s1
    8000663a:	8556                	mv	a0,s5
    8000663c:	ffffb097          	auipc	ra,0xffffb
    80006640:	9dc080e7          	jalr	-1572(ra) # 80001018 <memmove>
    80006644:	84ce                	mv	s1,s3
  while (*path == '/')
    80006646:	0004c783          	lbu	a5,0(s1)
    8000664a:	01279763          	bne	a5,s2,80006658 <namex+0xca>
    path++;
    8000664e:	0485                	add	s1,s1,1
  while (*path == '/')
    80006650:	0004c783          	lbu	a5,0(s1)
    80006654:	ff278de3          	beq	a5,s2,8000664e <namex+0xc0>
    ilock(ip);
    80006658:	8552                	mv	a0,s4
    8000665a:	fffff097          	auipc	ra,0xfffff
    8000665e:	a86080e7          	jalr	-1402(ra) # 800050e0 <ilock>
    if (ip->type != T_DIR)
    80006662:	044a1783          	lh	a5,68(s4)
    80006666:	f97791e3          	bne	a5,s7,800065e8 <namex+0x5a>
    if (nameiparent && *path == '\0')
    8000666a:	000b0563          	beqz	s6,80006674 <namex+0xe6>
    8000666e:	0004c783          	lbu	a5,0(s1)
    80006672:	dfd9                	beqz	a5,80006610 <namex+0x82>
    if ((next = dirlookup(ip, name, 0)) == 0)
    80006674:	4601                	li	a2,0
    80006676:	85d6                	mv	a1,s5
    80006678:	8552                	mv	a0,s4
    8000667a:	00000097          	auipc	ra,0x0
    8000667e:	e64080e7          	jalr	-412(ra) # 800064de <dirlookup>
    80006682:	89aa                	mv	s3,a0
    80006684:	dd41                	beqz	a0,8000661c <namex+0x8e>
    iunlockput(ip);
    80006686:	8552                	mv	a0,s4
    80006688:	fffff097          	auipc	ra,0xfffff
    8000668c:	cba080e7          	jalr	-838(ra) # 80005342 <iunlockput>
    ip = next;
    80006690:	8a4e                	mv	s4,s3
  while (*path == '/')
    80006692:	0004c783          	lbu	a5,0(s1)
    80006696:	01279763          	bne	a5,s2,800066a4 <namex+0x116>
    path++;
    8000669a:	0485                	add	s1,s1,1
  while (*path == '/')
    8000669c:	0004c783          	lbu	a5,0(s1)
    800066a0:	ff278de3          	beq	a5,s2,8000669a <namex+0x10c>
  if (*path == 0)
    800066a4:	cb9d                	beqz	a5,800066da <namex+0x14c>
  while (*path != '/' && *path != 0)
    800066a6:	0004c783          	lbu	a5,0(s1)
    800066aa:	89a6                	mv	s3,s1
  len = path - s;
    800066ac:	4c81                	li	s9,0
    800066ae:	4601                	li	a2,0
  while (*path != '/' && *path != 0)
    800066b0:	01278963          	beq	a5,s2,800066c2 <namex+0x134>
    800066b4:	dbbd                	beqz	a5,8000662a <namex+0x9c>
    path++;
    800066b6:	0985                	add	s3,s3,1
  while (*path != '/' && *path != 0)
    800066b8:	0009c783          	lbu	a5,0(s3)
    800066bc:	ff279ce3          	bne	a5,s2,800066b4 <namex+0x126>
    800066c0:	b7ad                	j	8000662a <namex+0x9c>
    memmove(name, s, len);
    800066c2:	2601                	sext.w	a2,a2
    800066c4:	85a6                	mv	a1,s1
    800066c6:	8556                	mv	a0,s5
    800066c8:	ffffb097          	auipc	ra,0xffffb
    800066cc:	950080e7          	jalr	-1712(ra) # 80001018 <memmove>
    name[len] = 0;
    800066d0:	9cd6                	add	s9,s9,s5
    800066d2:	000c8023          	sb	zero,0(s9)
    800066d6:	84ce                	mv	s1,s3
    800066d8:	b7bd                	j	80006646 <namex+0xb8>
  if (nameiparent)
    800066da:	f00b0de3          	beqz	s6,800065f4 <namex+0x66>
    iput(ip);
    800066de:	8552                	mv	a0,s4
    800066e0:	fffff097          	auipc	ra,0xfffff
    800066e4:	bba080e7          	jalr	-1094(ra) # 8000529a <iput>
    return 0;
    800066e8:	4a01                	li	s4,0
    800066ea:	b729                	j	800065f4 <namex+0x66>

00000000800066ec <dirlink>:
{
    800066ec:	7139                	add	sp,sp,-64
    800066ee:	fc06                	sd	ra,56(sp)
    800066f0:	f822                	sd	s0,48(sp)
    800066f2:	f426                	sd	s1,40(sp)
    800066f4:	f04a                	sd	s2,32(sp)
    800066f6:	ec4e                	sd	s3,24(sp)
    800066f8:	e852                	sd	s4,16(sp)
    800066fa:	0080                	add	s0,sp,64
    800066fc:	892a                	mv	s2,a0
    800066fe:	8a2e                	mv	s4,a1
    80006700:	89b2                	mv	s3,a2
  if ((ip = dirlookup(dp, name, 0)) != 0)
    80006702:	4601                	li	a2,0
    80006704:	00000097          	auipc	ra,0x0
    80006708:	dda080e7          	jalr	-550(ra) # 800064de <dirlookup>
    8000670c:	e93d                	bnez	a0,80006782 <dirlink+0x96>
  for (off = 0; off < dp->size; off += sizeof(de))
    8000670e:	04c92483          	lw	s1,76(s2)
    80006712:	c49d                	beqz	s1,80006740 <dirlink+0x54>
    80006714:	4481                	li	s1,0
    if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006716:	4741                	li	a4,16
    80006718:	86a6                	mv	a3,s1
    8000671a:	fc040613          	add	a2,s0,-64
    8000671e:	4581                	li	a1,0
    80006720:	854a                	mv	a0,s2
    80006722:	fffff097          	auipc	ra,0xfffff
    80006726:	c72080e7          	jalr	-910(ra) # 80005394 <readi>
    8000672a:	47c1                	li	a5,16
    8000672c:	06f51163          	bne	a0,a5,8000678e <dirlink+0xa2>
    if (de.inum == 0)
    80006730:	fc045783          	lhu	a5,-64(s0)
    80006734:	c791                	beqz	a5,80006740 <dirlink+0x54>
  for (off = 0; off < dp->size; off += sizeof(de))
    80006736:	24c1                	addw	s1,s1,16
    80006738:	04c92783          	lw	a5,76(s2)
    8000673c:	fcf4ede3          	bltu	s1,a5,80006716 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80006740:	4639                	li	a2,14
    80006742:	85d2                	mv	a1,s4
    80006744:	fc240513          	add	a0,s0,-62
    80006748:	ffffb097          	auipc	ra,0xffffb
    8000674c:	980080e7          	jalr	-1664(ra) # 800010c8 <strncpy>
  de.inum = inum;
    80006750:	fd341023          	sh	s3,-64(s0)
  if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006754:	4741                	li	a4,16
    80006756:	86a6                	mv	a3,s1
    80006758:	fc040613          	add	a2,s0,-64
    8000675c:	4581                	li	a1,0
    8000675e:	854a                	mv	a0,s2
    80006760:	fffff097          	auipc	ra,0xfffff
    80006764:	d2c080e7          	jalr	-724(ra) # 8000548c <writei>
    80006768:	1541                	add	a0,a0,-16
    8000676a:	00a03533          	snez	a0,a0
    8000676e:	40a00533          	neg	a0,a0
}
    80006772:	70e2                	ld	ra,56(sp)
    80006774:	7442                	ld	s0,48(sp)
    80006776:	74a2                	ld	s1,40(sp)
    80006778:	7902                	ld	s2,32(sp)
    8000677a:	69e2                	ld	s3,24(sp)
    8000677c:	6a42                	ld	s4,16(sp)
    8000677e:	6121                	add	sp,sp,64
    80006780:	8082                	ret
    iput(ip);
    80006782:	fffff097          	auipc	ra,0xfffff
    80006786:	b18080e7          	jalr	-1256(ra) # 8000529a <iput>
    return -1;
    8000678a:	557d                	li	a0,-1
    8000678c:	b7dd                	j	80006772 <dirlink+0x86>
      panic("dirlink read");
    8000678e:	00003517          	auipc	a0,0x3
    80006792:	57250513          	add	a0,a0,1394 # 80009d00 <syscalls+0x528>
    80006796:	ffffb097          	auipc	ra,0xffffb
    8000679a:	a6e080e7          	jalr	-1426(ra) # 80001204 <panic>

000000008000679e <namei>:

struct inode *
namei(char *path)
{
    8000679e:	1101                	add	sp,sp,-32
    800067a0:	ec06                	sd	ra,24(sp)
    800067a2:	e822                	sd	s0,16(sp)
    800067a4:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800067a6:	fe040613          	add	a2,s0,-32
    800067aa:	4581                	li	a1,0
    800067ac:	00000097          	auipc	ra,0x0
    800067b0:	de2080e7          	jalr	-542(ra) # 8000658e <namex>
}
    800067b4:	60e2                	ld	ra,24(sp)
    800067b6:	6442                	ld	s0,16(sp)
    800067b8:	6105                	add	sp,sp,32
    800067ba:	8082                	ret

00000000800067bc <nameiparent>:

struct inode *
nameiparent(char *path, char *name)
{
    800067bc:	1141                	add	sp,sp,-16
    800067be:	e406                	sd	ra,8(sp)
    800067c0:	e022                	sd	s0,0(sp)
    800067c2:	0800                	add	s0,sp,16
    800067c4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800067c6:	4585                	li	a1,1
    800067c8:	00000097          	auipc	ra,0x0
    800067cc:	dc6080e7          	jalr	-570(ra) # 8000658e <namex>
}
    800067d0:	60a2                	ld	ra,8(sp)
    800067d2:	6402                	ld	s0,0(sp)
    800067d4:	0141                	add	sp,sp,16
    800067d6:	8082                	ret

00000000800067d8 <dir_print>:

void dir_print(struct inode *pip)
{
    800067d8:	7139                	add	sp,sp,-64
    800067da:	fc06                	sd	ra,56(sp)
    800067dc:	f822                	sd	s0,48(sp)
    800067de:	f426                	sd	s1,40(sp)
    800067e0:	f04a                	sd	s2,32(sp)
    800067e2:	ec4e                	sd	s3,24(sp)
    800067e4:	0080                	add	s0,sp,64
    800067e6:	892a                	mv	s2,a0
    assert(holdingsleep(&pip->lock), "dir_print: lock");
    800067e8:	0541                	add	a0,a0,16
    800067ea:	ffffc097          	auipc	ra,0xffffc
    800067ee:	79e080e7          	jalr	1950(ra) # 80002f88 <holdingsleep>
    800067f2:	00003597          	auipc	a1,0x3
    800067f6:	51e58593          	add	a1,a1,1310 # 80009d10 <syscalls+0x538>
    800067fa:	00000097          	auipc	ra,0x0
    800067fe:	6d2080e7          	jalr	1746(ra) # 80006ecc <assert>

    printf("\ninode_num = %d dirents:\n", pip->inum);
    80006802:	00492583          	lw	a1,4(s2)
    80006806:	00003517          	auipc	a0,0x3
    8000680a:	51a50513          	add	a0,a0,1306 # 80009d20 <syscalls+0x548>
    8000680e:	ffffb097          	auipc	ra,0xffffb
    80006812:	a40080e7          	jalr	-1472(ra) # 8000124e <printf>

    struct dirent de;

    for (uint32 offset = 0; offset < pip->size; offset += sizeof(struct dirent))
    80006816:	04c92783          	lw	a5,76(s2)
    8000681a:	cfa1                	beqz	a5,80006872 <dir_print+0x9a>
    8000681c:	4481                	li	s1,0
    {
        if (readi(pip, 0, (uint64)&de, offset, sizeof(de)) != sizeof(de))
            panic("dir_print read");
        if (de.inum != 0)
            printf("inum = %d dirent = %s\n", de.inum, de.name);
    8000681e:	00003997          	auipc	s3,0x3
    80006822:	53298993          	add	s3,s3,1330 # 80009d50 <syscalls+0x578>
    80006826:	a831                	j	80006842 <dir_print+0x6a>
            panic("dir_print read");
    80006828:	00003517          	auipc	a0,0x3
    8000682c:	51850513          	add	a0,a0,1304 # 80009d40 <syscalls+0x568>
    80006830:	ffffb097          	auipc	ra,0xffffb
    80006834:	9d4080e7          	jalr	-1580(ra) # 80001204 <panic>
    for (uint32 offset = 0; offset < pip->size; offset += sizeof(struct dirent))
    80006838:	24c1                	addw	s1,s1,16
    8000683a:	04c92783          	lw	a5,76(s2)
    8000683e:	02f4fa63          	bgeu	s1,a5,80006872 <dir_print+0x9a>
        if (readi(pip, 0, (uint64)&de, offset, sizeof(de)) != sizeof(de))
    80006842:	4741                	li	a4,16
    80006844:	86a6                	mv	a3,s1
    80006846:	fc040613          	add	a2,s0,-64
    8000684a:	4581                	li	a1,0
    8000684c:	854a                	mv	a0,s2
    8000684e:	fffff097          	auipc	ra,0xfffff
    80006852:	b46080e7          	jalr	-1210(ra) # 80005394 <readi>
    80006856:	47c1                	li	a5,16
    80006858:	fcf518e3          	bne	a0,a5,80006828 <dir_print+0x50>
        if (de.inum != 0)
    8000685c:	fc045583          	lhu	a1,-64(s0)
    80006860:	dde1                	beqz	a1,80006838 <dir_print+0x60>
            printf("inum = %d dirent = %s\n", de.inum, de.name);
    80006862:	fc240613          	add	a2,s0,-62
    80006866:	854e                	mv	a0,s3
    80006868:	ffffb097          	auipc	ra,0xffffb
    8000686c:	9e6080e7          	jalr	-1562(ra) # 8000124e <printf>
    80006870:	b7e1                	j	80006838 <dir_print+0x60>
    }
}
    80006872:	70e2                	ld	ra,56(sp)
    80006874:	7442                	ld	s0,48(sp)
    80006876:	74a2                	ld	s1,40(sp)
    80006878:	7902                	ld	s2,32(sp)
    8000687a:	69e2                	ld	s3,24(sp)
    8000687c:	6121                	add	sp,sp,64
    8000687e:	8082                	ret

0000000080006880 <dir_unlink>:
  return 1;
}

int
dir_unlink(struct inode *dp, char *name)
{
    80006880:	711d                	add	sp,sp,-96
    80006882:	ec86                	sd	ra,88(sp)
    80006884:	e8a2                	sd	s0,80(sp)
    80006886:	e4a6                	sd	s1,72(sp)
    80006888:	e0ca                	sd	s2,64(sp)
    8000688a:	fc4e                	sd	s3,56(sp)
    8000688c:	1080                	add	s0,sp,96
    8000688e:	89aa                	mv	s3,a0
    80006890:	84ae                	mv	s1,a1
  struct inode *ip;
  struct dirent de;
  uint off;

  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006892:	00003597          	auipc	a1,0x3
    80006896:	07e58593          	add	a1,a1,126 # 80009910 <syscalls+0x138>
    8000689a:	8526                	mv	a0,s1
    8000689c:	00000097          	auipc	ra,0x0
    800068a0:	c28080e7          	jalr	-984(ra) # 800064c4 <namecmp>
    800068a4:	12050663          	beqz	a0,800069d0 <dir_unlink+0x150>
    800068a8:	00003597          	auipc	a1,0x3
    800068ac:	07058593          	add	a1,a1,112 # 80009918 <syscalls+0x140>
    800068b0:	8526                	mv	a0,s1
    800068b2:	00000097          	auipc	ra,0x0
    800068b6:	c12080e7          	jalr	-1006(ra) # 800064c4 <namecmp>
    800068ba:	10050d63          	beqz	a0,800069d4 <dir_unlink+0x154>
    return -1;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800068be:	fbc40613          	add	a2,s0,-68
    800068c2:	85a6                	mv	a1,s1
    800068c4:	854e                	mv	a0,s3
    800068c6:	00000097          	auipc	ra,0x0
    800068ca:	c18080e7          	jalr	-1000(ra) # 800064de <dirlookup>
    800068ce:	84aa                	mv	s1,a0
    800068d0:	10050463          	beqz	a0,800069d8 <dir_unlink+0x158>
    return -1;
  
  ilock(ip);
    800068d4:	fffff097          	auipc	ra,0xfffff
    800068d8:	80c080e7          	jalr	-2036(ra) # 800050e0 <ilock>

  if(ip->nlink < 1)
    800068dc:	04a49783          	lh	a5,74(s1)
    800068e0:	06f05963          	blez	a5,80006952 <dir_unlink+0xd2>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800068e4:	04449703          	lh	a4,68(s1)
    800068e8:	4785                	li	a5,1
    800068ea:	06f70c63          	beq	a4,a5,80006962 <dir_unlink+0xe2>
    iunlockput(ip);
    return -1;
  }

  memset(&de, 0, sizeof(de));
    800068ee:	4641                	li	a2,16
    800068f0:	4581                	li	a1,0
    800068f2:	fc040513          	add	a0,s0,-64
    800068f6:	ffffa097          	auipc	ra,0xffffa
    800068fa:	6c6080e7          	jalr	1734(ra) # 80000fbc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800068fe:	4741                	li	a4,16
    80006900:	fbc42683          	lw	a3,-68(s0)
    80006904:	fc040613          	add	a2,s0,-64
    80006908:	4581                	li	a1,0
    8000690a:	854e                	mv	a0,s3
    8000690c:	fffff097          	auipc	ra,0xfffff
    80006910:	b80080e7          	jalr	-1152(ra) # 8000548c <writei>
    80006914:	47c1                	li	a5,16
    80006916:	08f51a63          	bne	a0,a5,800069aa <dir_unlink+0x12a>
    panic("unlink: writei");
  
  if(ip->type == T_DIR){
    8000691a:	04449703          	lh	a4,68(s1)
    8000691e:	4785                	li	a5,1
    80006920:	08f70d63          	beq	a4,a5,800069ba <dir_unlink+0x13a>
    dp->nlink--;
    iupdate(dp);
  }

  ip->nlink--;
    80006924:	04a4d783          	lhu	a5,74(s1)
    80006928:	37fd                	addw	a5,a5,-1
    8000692a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000692e:	8526                	mv	a0,s1
    80006930:	ffffe097          	auipc	ra,0xffffe
    80006934:	6e4080e7          	jalr	1764(ra) # 80005014 <iupdate>
  iunlockput(ip);
    80006938:	8526                	mv	a0,s1
    8000693a:	fffff097          	auipc	ra,0xfffff
    8000693e:	a08080e7          	jalr	-1528(ra) # 80005342 <iunlockput>

  return 0;
    80006942:	4501                	li	a0,0
}
    80006944:	60e6                	ld	ra,88(sp)
    80006946:	6446                	ld	s0,80(sp)
    80006948:	64a6                	ld	s1,72(sp)
    8000694a:	6906                	ld	s2,64(sp)
    8000694c:	79e2                	ld	s3,56(sp)
    8000694e:	6125                	add	sp,sp,96
    80006950:	8082                	ret
    panic("unlink: nlink < 1");
    80006952:	00003517          	auipc	a0,0x3
    80006956:	fce50513          	add	a0,a0,-50 # 80009920 <syscalls+0x148>
    8000695a:	ffffb097          	auipc	ra,0xffffb
    8000695e:	8aa080e7          	jalr	-1878(ra) # 80001204 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006962:	44f8                	lw	a4,76(s1)
    80006964:	02000793          	li	a5,32
    80006968:	f8e7f3e3          	bgeu	a5,a4,800068ee <dir_unlink+0x6e>
    8000696c:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006970:	4741                	li	a4,16
    80006972:	86ca                	mv	a3,s2
    80006974:	fa840613          	add	a2,s0,-88
    80006978:	4581                	li	a1,0
    8000697a:	8526                	mv	a0,s1
    8000697c:	fffff097          	auipc	ra,0xfffff
    80006980:	a18080e7          	jalr	-1512(ra) # 80005394 <readi>
    80006984:	47c1                	li	a5,16
    80006986:	00f51a63          	bne	a0,a5,8000699a <dir_unlink+0x11a>
    if(de.inum != 0)
    8000698a:	fa845783          	lhu	a5,-88(s0)
    8000698e:	e7b9                	bnez	a5,800069dc <dir_unlink+0x15c>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006990:	2941                	addw	s2,s2,16
    80006992:	44fc                	lw	a5,76(s1)
    80006994:	fcf96ee3          	bltu	s2,a5,80006970 <dir_unlink+0xf0>
    80006998:	bf99                	j	800068ee <dir_unlink+0x6e>
      panic("isdirempty: readi");
    8000699a:	00003517          	auipc	a0,0x3
    8000699e:	f9e50513          	add	a0,a0,-98 # 80009938 <syscalls+0x160>
    800069a2:	ffffb097          	auipc	ra,0xffffb
    800069a6:	862080e7          	jalr	-1950(ra) # 80001204 <panic>
    panic("unlink: writei");
    800069aa:	00003517          	auipc	a0,0x3
    800069ae:	fa650513          	add	a0,a0,-90 # 80009950 <syscalls+0x178>
    800069b2:	ffffb097          	auipc	ra,0xffffb
    800069b6:	852080e7          	jalr	-1966(ra) # 80001204 <panic>
    dp->nlink--;
    800069ba:	04a9d783          	lhu	a5,74(s3)
    800069be:	37fd                	addw	a5,a5,-1
    800069c0:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    800069c4:	854e                	mv	a0,s3
    800069c6:	ffffe097          	auipc	ra,0xffffe
    800069ca:	64e080e7          	jalr	1614(ra) # 80005014 <iupdate>
    800069ce:	bf99                	j	80006924 <dir_unlink+0xa4>
    return -1;
    800069d0:	557d                	li	a0,-1
    800069d2:	bf8d                	j	80006944 <dir_unlink+0xc4>
    800069d4:	557d                	li	a0,-1
    800069d6:	b7bd                	j	80006944 <dir_unlink+0xc4>
    return -1;
    800069d8:	557d                	li	a0,-1
    800069da:	b7ad                	j	80006944 <dir_unlink+0xc4>
    iunlockput(ip);
    800069dc:	8526                	mv	a0,s1
    800069de:	fffff097          	auipc	ra,0xfffff
    800069e2:	964080e7          	jalr	-1692(ra) # 80005342 <iunlockput>
    return -1;
    800069e6:	557d                	li	a0,-1
    800069e8:	bfb1                	j	80006944 <dir_unlink+0xc4>

00000000800069ea <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800069ea:	7179                	add	sp,sp,-48
    800069ec:	f406                	sd	ra,40(sp)
    800069ee:	f022                	sd	s0,32(sp)
    800069f0:	ec26                	sd	s1,24(sp)
    800069f2:	e84a                	sd	s2,16(sp)
    800069f4:	e44e                	sd	s3,8(sp)
    800069f6:	e052                	sd	s4,0(sp)
    800069f8:	1800                	add	s0,sp,48
    800069fa:	84aa                	mv	s1,a0
    800069fc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800069fe:	0005b023          	sd	zero,0(a1)
    80006a02:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80006a06:	fffff097          	auipc	ra,0xfffff
    80006a0a:	64a080e7          	jalr	1610(ra) # 80006050 <filealloc>
    80006a0e:	e088                	sd	a0,0(s1)
    80006a10:	c559                	beqz	a0,80006a9e <pipealloc+0xb4>
    80006a12:	fffff097          	auipc	ra,0xfffff
    80006a16:	63e080e7          	jalr	1598(ra) # 80006050 <filealloc>
    80006a1a:	00aa3023          	sd	a0,0(s4)
    80006a1e:	c935                	beqz	a0,80006a92 <pipealloc+0xa8>
    goto bad;
  if((pi = (struct pipe*)kalloc(1)) == 0)
    80006a20:	4505                	li	a0,1
    80006a22:	ffffb097          	auipc	ra,0xffffb
    80006a26:	b3e080e7          	jalr	-1218(ra) # 80001560 <kalloc>
    80006a2a:	892a                	mv	s2,a0
    80006a2c:	c125                	beqz	a0,80006a8c <pipealloc+0xa2>
    goto bad;
  pi->readopen = 1;
    80006a2e:	4985                	li	s3,1
    80006a30:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80006a34:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80006a38:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80006a3c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80006a40:	00003597          	auipc	a1,0x3
    80006a44:	32858593          	add	a1,a1,808 # 80009d68 <syscalls+0x590>
    80006a48:	ffffc097          	auipc	ra,0xffffc
    80006a4c:	596080e7          	jalr	1430(ra) # 80002fde <initlock>
  (*f0)->type = FD_PIPE;
    80006a50:	609c                	ld	a5,0(s1)
    80006a52:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80006a56:	609c                	ld	a5,0(s1)
    80006a58:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80006a5c:	609c                	ld	a5,0(s1)
    80006a5e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80006a62:	609c                	ld	a5,0(s1)
    80006a64:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80006a68:	000a3783          	ld	a5,0(s4)
    80006a6c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80006a70:	000a3783          	ld	a5,0(s4)
    80006a74:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80006a78:	000a3783          	ld	a5,0(s4)
    80006a7c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80006a80:	000a3783          	ld	a5,0(s4)
    80006a84:	0127b823          	sd	s2,16(a5)
  return 0;
    80006a88:	4501                	li	a0,0
    80006a8a:	a025                	j	80006ab2 <pipealloc+0xc8>

 bad:
  if(pi)
    kfree((uint64)pi,1);
  if(*f0)
    80006a8c:	6088                	ld	a0,0(s1)
    80006a8e:	e501                	bnez	a0,80006a96 <pipealloc+0xac>
    80006a90:	a039                	j	80006a9e <pipealloc+0xb4>
    80006a92:	6088                	ld	a0,0(s1)
    80006a94:	c51d                	beqz	a0,80006ac2 <pipealloc+0xd8>
    fileclose(*f0);
    80006a96:	fffff097          	auipc	ra,0xfffff
    80006a9a:	676080e7          	jalr	1654(ra) # 8000610c <fileclose>
  if(*f1)
    80006a9e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80006aa2:	557d                	li	a0,-1
  if(*f1)
    80006aa4:	c799                	beqz	a5,80006ab2 <pipealloc+0xc8>
    fileclose(*f1);
    80006aa6:	853e                	mv	a0,a5
    80006aa8:	fffff097          	auipc	ra,0xfffff
    80006aac:	664080e7          	jalr	1636(ra) # 8000610c <fileclose>
  return -1;
    80006ab0:	557d                	li	a0,-1
}
    80006ab2:	70a2                	ld	ra,40(sp)
    80006ab4:	7402                	ld	s0,32(sp)
    80006ab6:	64e2                	ld	s1,24(sp)
    80006ab8:	6942                	ld	s2,16(sp)
    80006aba:	69a2                	ld	s3,8(sp)
    80006abc:	6a02                	ld	s4,0(sp)
    80006abe:	6145                	add	sp,sp,48
    80006ac0:	8082                	ret
  return -1;
    80006ac2:	557d                	li	a0,-1
    80006ac4:	b7fd                	j	80006ab2 <pipealloc+0xc8>

0000000080006ac6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80006ac6:	1101                	add	sp,sp,-32
    80006ac8:	ec06                	sd	ra,24(sp)
    80006aca:	e822                	sd	s0,16(sp)
    80006acc:	e426                	sd	s1,8(sp)
    80006ace:	e04a                	sd	s2,0(sp)
    80006ad0:	1000                	add	s0,sp,32
    80006ad2:	84aa                	mv	s1,a0
    80006ad4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80006ad6:	ffffc097          	auipc	ra,0xffffc
    80006ada:	598080e7          	jalr	1432(ra) # 8000306e <acquire>
  if(writable){
    80006ade:	02090e63          	beqz	s2,80006b1a <pipeclose+0x54>
    pi->writeopen = 0;
    80006ae2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80006ae6:	21848513          	add	a0,s1,536
    80006aea:	ffffc097          	auipc	ra,0xffffc
    80006aee:	ea4080e7          	jalr	-348(ra) # 8000298e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80006af2:	2204b783          	ld	a5,544(s1)
    80006af6:	eb9d                	bnez	a5,80006b2c <pipeclose+0x66>
    release(&pi->lock);
    80006af8:	8526                	mv	a0,s1
    80006afa:	ffffc097          	auipc	ra,0xffffc
    80006afe:	628080e7          	jalr	1576(ra) # 80003122 <release>
    kfree((uint64)pi,1);
    80006b02:	4585                	li	a1,1
    80006b04:	8526                	mv	a0,s1
    80006b06:	ffffb097          	auipc	ra,0xffffb
    80006b0a:	95a080e7          	jalr	-1702(ra) # 80001460 <kfree>
  } else
    release(&pi->lock);
}
    80006b0e:	60e2                	ld	ra,24(sp)
    80006b10:	6442                	ld	s0,16(sp)
    80006b12:	64a2                	ld	s1,8(sp)
    80006b14:	6902                	ld	s2,0(sp)
    80006b16:	6105                	add	sp,sp,32
    80006b18:	8082                	ret
    pi->readopen = 0;
    80006b1a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80006b1e:	21c48513          	add	a0,s1,540
    80006b22:	ffffc097          	auipc	ra,0xffffc
    80006b26:	e6c080e7          	jalr	-404(ra) # 8000298e <wakeup>
    80006b2a:	b7e1                	j	80006af2 <pipeclose+0x2c>
    release(&pi->lock);
    80006b2c:	8526                	mv	a0,s1
    80006b2e:	ffffc097          	auipc	ra,0xffffc
    80006b32:	5f4080e7          	jalr	1524(ra) # 80003122 <release>
}
    80006b36:	bfe1                	j	80006b0e <pipeclose+0x48>

0000000080006b38 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80006b38:	711d                	add	sp,sp,-96
    80006b3a:	ec86                	sd	ra,88(sp)
    80006b3c:	e8a2                	sd	s0,80(sp)
    80006b3e:	e4a6                	sd	s1,72(sp)
    80006b40:	e0ca                	sd	s2,64(sp)
    80006b42:	fc4e                	sd	s3,56(sp)
    80006b44:	f852                	sd	s4,48(sp)
    80006b46:	f456                	sd	s5,40(sp)
    80006b48:	f05a                	sd	s6,32(sp)
    80006b4a:	ec5e                	sd	s7,24(sp)
    80006b4c:	e862                	sd	s8,16(sp)
    80006b4e:	1080                	add	s0,sp,96
    80006b50:	84aa                	mv	s1,a0
    80006b52:	8aae                	mv	s5,a1
    80006b54:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80006b56:	ffffb097          	auipc	ra,0xffffb
    80006b5a:	60e080e7          	jalr	1550(ra) # 80002164 <myproc>
    80006b5e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80006b60:	8526                	mv	a0,s1
    80006b62:	ffffc097          	auipc	ra,0xffffc
    80006b66:	50c080e7          	jalr	1292(ra) # 8000306e <acquire>
  while(i < n){
    80006b6a:	0b405663          	blez	s4,80006c16 <pipewrite+0xde>
  int i = 0;
    80006b6e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pgtbl, &ch, addr + i, 1) == -1)
    80006b70:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80006b72:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80006b76:	21c48b93          	add	s7,s1,540
    80006b7a:	a089                	j	80006bbc <pipewrite+0x84>
      release(&pi->lock);
    80006b7c:	8526                	mv	a0,s1
    80006b7e:	ffffc097          	auipc	ra,0xffffc
    80006b82:	5a4080e7          	jalr	1444(ra) # 80003122 <release>
      return -1;
    80006b86:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80006b88:	854a                	mv	a0,s2
    80006b8a:	60e6                	ld	ra,88(sp)
    80006b8c:	6446                	ld	s0,80(sp)
    80006b8e:	64a6                	ld	s1,72(sp)
    80006b90:	6906                	ld	s2,64(sp)
    80006b92:	79e2                	ld	s3,56(sp)
    80006b94:	7a42                	ld	s4,48(sp)
    80006b96:	7aa2                	ld	s5,40(sp)
    80006b98:	7b02                	ld	s6,32(sp)
    80006b9a:	6be2                	ld	s7,24(sp)
    80006b9c:	6c42                	ld	s8,16(sp)
    80006b9e:	6125                	add	sp,sp,96
    80006ba0:	8082                	ret
      wakeup(&pi->nread);
    80006ba2:	8562                	mv	a0,s8
    80006ba4:	ffffc097          	auipc	ra,0xffffc
    80006ba8:	dea080e7          	jalr	-534(ra) # 8000298e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80006bac:	85a6                	mv	a1,s1
    80006bae:	855e                	mv	a0,s7
    80006bb0:	ffffc097          	auipc	ra,0xffffc
    80006bb4:	d70080e7          	jalr	-656(ra) # 80002920 <sleep>
  while(i < n){
    80006bb8:	07495063          	bge	s2,s4,80006c18 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80006bbc:	2204a783          	lw	a5,544(s1)
    80006bc0:	dfd5                	beqz	a5,80006b7c <pipewrite+0x44>
    80006bc2:	854e                	mv	a0,s3
    80006bc4:	ffffc097          	auipc	ra,0xffffc
    80006bc8:	ef8080e7          	jalr	-264(ra) # 80002abc <killed>
    80006bcc:	f945                	bnez	a0,80006b7c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80006bce:	2184a783          	lw	a5,536(s1)
    80006bd2:	21c4a703          	lw	a4,540(s1)
    80006bd6:	2007879b          	addw	a5,a5,512
    80006bda:	fcf704e3          	beq	a4,a5,80006ba2 <pipewrite+0x6a>
      if(copyin(pr->pgtbl, &ch, addr + i, 1) == -1)
    80006bde:	4685                	li	a3,1
    80006be0:	01590633          	add	a2,s2,s5
    80006be4:	faf40593          	add	a1,s0,-81
    80006be8:	0489b503          	ld	a0,72(s3)
    80006bec:	ffffb097          	auipc	ra,0xffffb
    80006bf0:	3d6080e7          	jalr	982(ra) # 80001fc2 <copyin>
    80006bf4:	03650263          	beq	a0,s6,80006c18 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80006bf8:	21c4a783          	lw	a5,540(s1)
    80006bfc:	0017871b          	addw	a4,a5,1
    80006c00:	20e4ae23          	sw	a4,540(s1)
    80006c04:	1ff7f793          	and	a5,a5,511
    80006c08:	97a6                	add	a5,a5,s1
    80006c0a:	faf44703          	lbu	a4,-81(s0)
    80006c0e:	00e78c23          	sb	a4,24(a5)
      i++;
    80006c12:	2905                	addw	s2,s2,1
    80006c14:	b755                	j	80006bb8 <pipewrite+0x80>
  int i = 0;
    80006c16:	4901                	li	s2,0
  wakeup(&pi->nread);
    80006c18:	21848513          	add	a0,s1,536
    80006c1c:	ffffc097          	auipc	ra,0xffffc
    80006c20:	d72080e7          	jalr	-654(ra) # 8000298e <wakeup>
  release(&pi->lock);
    80006c24:	8526                	mv	a0,s1
    80006c26:	ffffc097          	auipc	ra,0xffffc
    80006c2a:	4fc080e7          	jalr	1276(ra) # 80003122 <release>
  return i;
    80006c2e:	bfa9                	j	80006b88 <pipewrite+0x50>

0000000080006c30 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80006c30:	715d                	add	sp,sp,-80
    80006c32:	e486                	sd	ra,72(sp)
    80006c34:	e0a2                	sd	s0,64(sp)
    80006c36:	fc26                	sd	s1,56(sp)
    80006c38:	f84a                	sd	s2,48(sp)
    80006c3a:	f44e                	sd	s3,40(sp)
    80006c3c:	f052                	sd	s4,32(sp)
    80006c3e:	ec56                	sd	s5,24(sp)
    80006c40:	e85a                	sd	s6,16(sp)
    80006c42:	0880                	add	s0,sp,80
    80006c44:	84aa                	mv	s1,a0
    80006c46:	892e                	mv	s2,a1
    80006c48:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80006c4a:	ffffb097          	auipc	ra,0xffffb
    80006c4e:	51a080e7          	jalr	1306(ra) # 80002164 <myproc>
    80006c52:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80006c54:	8526                	mv	a0,s1
    80006c56:	ffffc097          	auipc	ra,0xffffc
    80006c5a:	418080e7          	jalr	1048(ra) # 8000306e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006c5e:	2184a703          	lw	a4,536(s1)
    80006c62:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006c66:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006c6a:	02f71763          	bne	a4,a5,80006c98 <piperead+0x68>
    80006c6e:	2244a783          	lw	a5,548(s1)
    80006c72:	c39d                	beqz	a5,80006c98 <piperead+0x68>
    if(killed(pr)){
    80006c74:	8552                	mv	a0,s4
    80006c76:	ffffc097          	auipc	ra,0xffffc
    80006c7a:	e46080e7          	jalr	-442(ra) # 80002abc <killed>
    80006c7e:	e949                	bnez	a0,80006d10 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80006c80:	85a6                	mv	a1,s1
    80006c82:	854e                	mv	a0,s3
    80006c84:	ffffc097          	auipc	ra,0xffffc
    80006c88:	c9c080e7          	jalr	-868(ra) # 80002920 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80006c8c:	2184a703          	lw	a4,536(s1)
    80006c90:	21c4a783          	lw	a5,540(s1)
    80006c94:	fcf70de3          	beq	a4,a5,80006c6e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006c98:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pgtbl, addr + i, &ch, 1) == -1)
    80006c9a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006c9c:	05505463          	blez	s5,80006ce4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80006ca0:	2184a783          	lw	a5,536(s1)
    80006ca4:	21c4a703          	lw	a4,540(s1)
    80006ca8:	02f70e63          	beq	a4,a5,80006ce4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80006cac:	0017871b          	addw	a4,a5,1
    80006cb0:	20e4ac23          	sw	a4,536(s1)
    80006cb4:	1ff7f793          	and	a5,a5,511
    80006cb8:	97a6                	add	a5,a5,s1
    80006cba:	0187c783          	lbu	a5,24(a5)
    80006cbe:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pgtbl, addr + i, &ch, 1) == -1)
    80006cc2:	4685                	li	a3,1
    80006cc4:	fbf40613          	add	a2,s0,-65
    80006cc8:	85ca                	mv	a1,s2
    80006cca:	048a3503          	ld	a0,72(s4)
    80006cce:	ffffb097          	auipc	ra,0xffffb
    80006cd2:	262080e7          	jalr	610(ra) # 80001f30 <copyout>
    80006cd6:	01650763          	beq	a0,s6,80006ce4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80006cda:	2985                	addw	s3,s3,1
    80006cdc:	0905                	add	s2,s2,1
    80006cde:	fd3a91e3          	bne	s5,s3,80006ca0 <piperead+0x70>
    80006ce2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80006ce4:	21c48513          	add	a0,s1,540
    80006ce8:	ffffc097          	auipc	ra,0xffffc
    80006cec:	ca6080e7          	jalr	-858(ra) # 8000298e <wakeup>
  release(&pi->lock);
    80006cf0:	8526                	mv	a0,s1
    80006cf2:	ffffc097          	auipc	ra,0xffffc
    80006cf6:	430080e7          	jalr	1072(ra) # 80003122 <release>
  return i;
}
    80006cfa:	854e                	mv	a0,s3
    80006cfc:	60a6                	ld	ra,72(sp)
    80006cfe:	6406                	ld	s0,64(sp)
    80006d00:	74e2                	ld	s1,56(sp)
    80006d02:	7942                	ld	s2,48(sp)
    80006d04:	79a2                	ld	s3,40(sp)
    80006d06:	7a02                	ld	s4,32(sp)
    80006d08:	6ae2                	ld	s5,24(sp)
    80006d0a:	6b42                	ld	s6,16(sp)
    80006d0c:	6161                	add	sp,sp,80
    80006d0e:	8082                	ret
      release(&pi->lock);
    80006d10:	8526                	mv	a0,s1
    80006d12:	ffffc097          	auipc	ra,0xffffc
    80006d16:	410080e7          	jalr	1040(ra) # 80003122 <release>
      return -1;
    80006d1a:	59fd                	li	s3,-1
    80006d1c:	bff9                	j	80006cfa <piperead+0xca>

0000000080006d1e <balloc>:
  brelse(bp);
}

uint
balloc(uint dev)
{
    80006d1e:	711d                	add	sp,sp,-96
    80006d20:	ec86                	sd	ra,88(sp)
    80006d22:	e8a2                	sd	s0,80(sp)
    80006d24:	e4a6                	sd	s1,72(sp)
    80006d26:	e0ca                	sd	s2,64(sp)
    80006d28:	fc4e                	sd	s3,56(sp)
    80006d2a:	f852                	sd	s4,48(sp)
    80006d2c:	f456                	sd	s5,40(sp)
    80006d2e:	f05a                	sd	s6,32(sp)
    80006d30:	ec5e                	sd	s7,24(sp)
    80006d32:	e862                	sd	s8,16(sp)
    80006d34:	e466                	sd	s9,8(sp)
    80006d36:	1080                	add	s0,sp,96
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for (b = 0; b < sb.size; b += BPB)
    80006d38:	0001c797          	auipc	a5,0x1c
    80006d3c:	5647a783          	lw	a5,1380(a5) # 8002329c <sb+0x4>
    80006d40:	cff5                	beqz	a5,80006e3c <balloc+0x11e>
    80006d42:	8baa                	mv	s7,a0
    80006d44:	4a81                	li	s5,0
  {
    bp = bread(dev, BBLOCK(b, sb));
    80006d46:	0001cb17          	auipc	s6,0x1c
    80006d4a:	552b0b13          	add	s6,s6,1362 # 80023298 <sb>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006d4e:	4c01                	li	s8,0
    {
      m = 1 << (bi % 8);
    80006d50:	4985                	li	s3,1
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006d52:	6a09                	lui	s4,0x2
  for (b = 0; b < sb.size; b += BPB)
    80006d54:	6c89                	lui	s9,0x2
    80006d56:	a061                	j	80006dde <balloc+0xc0>
      if ((bp->data[bi / 8] & m) == 0)
      {
        bp->data[bi / 8] |= m;
    80006d58:	97ca                	add	a5,a5,s2
    80006d5a:	8e55                	or	a2,a2,a3
    80006d5c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80006d60:	854a                	mv	a0,s2
    80006d62:	fffff097          	auipc	ra,0xfffff
    80006d66:	1e2080e7          	jalr	482(ra) # 80005f44 <log_write>
        brelse(bp);
    80006d6a:	854a                	mv	a0,s2
    80006d6c:	fffff097          	auipc	ra,0xfffff
    80006d70:	b70080e7          	jalr	-1168(ra) # 800058dc <brelse>
  bp = bread(dev, bno);
    80006d74:	85a6                	mv	a1,s1
    80006d76:	855e                	mv	a0,s7
    80006d78:	fffff097          	auipc	ra,0xfffff
    80006d7c:	a34080e7          	jalr	-1484(ra) # 800057ac <bread>
    80006d80:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80006d82:	40000613          	li	a2,1024
    80006d86:	4581                	li	a1,0
    80006d88:	05850513          	add	a0,a0,88
    80006d8c:	ffffa097          	auipc	ra,0xffffa
    80006d90:	230080e7          	jalr	560(ra) # 80000fbc <memset>
  log_write(bp);
    80006d94:	854a                	mv	a0,s2
    80006d96:	fffff097          	auipc	ra,0xfffff
    80006d9a:	1ae080e7          	jalr	430(ra) # 80005f44 <log_write>
  brelse(bp);
    80006d9e:	854a                	mv	a0,s2
    80006da0:	fffff097          	auipc	ra,0xfffff
    80006da4:	b3c080e7          	jalr	-1220(ra) # 800058dc <brelse>
    }
    brelse(bp);
  }
  printf("balloc: out of blocks\n");
  return 0;
}
    80006da8:	8526                	mv	a0,s1
    80006daa:	60e6                	ld	ra,88(sp)
    80006dac:	6446                	ld	s0,80(sp)
    80006dae:	64a6                	ld	s1,72(sp)
    80006db0:	6906                	ld	s2,64(sp)
    80006db2:	79e2                	ld	s3,56(sp)
    80006db4:	7a42                	ld	s4,48(sp)
    80006db6:	7aa2                	ld	s5,40(sp)
    80006db8:	7b02                	ld	s6,32(sp)
    80006dba:	6be2                	ld	s7,24(sp)
    80006dbc:	6c42                	ld	s8,16(sp)
    80006dbe:	6ca2                	ld	s9,8(sp)
    80006dc0:	6125                	add	sp,sp,96
    80006dc2:	8082                	ret
    brelse(bp);
    80006dc4:	854a                	mv	a0,s2
    80006dc6:	fffff097          	auipc	ra,0xfffff
    80006dca:	b16080e7          	jalr	-1258(ra) # 800058dc <brelse>
  for (b = 0; b < sb.size; b += BPB)
    80006dce:	015c87bb          	addw	a5,s9,s5
    80006dd2:	00078a9b          	sext.w	s5,a5
    80006dd6:	004b2703          	lw	a4,4(s6)
    80006dda:	06eaf163          	bgeu	s5,a4,80006e3c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80006dde:	41fad79b          	sraw	a5,s5,0x1f
    80006de2:	0137d79b          	srlw	a5,a5,0x13
    80006de6:	015787bb          	addw	a5,a5,s5
    80006dea:	40d7d79b          	sraw	a5,a5,0xd
    80006dee:	01cb2583          	lw	a1,28(s6)
    80006df2:	9dbd                	addw	a1,a1,a5
    80006df4:	855e                	mv	a0,s7
    80006df6:	fffff097          	auipc	ra,0xfffff
    80006dfa:	9b6080e7          	jalr	-1610(ra) # 800057ac <bread>
    80006dfe:	892a                	mv	s2,a0
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006e00:	004b2503          	lw	a0,4(s6)
    80006e04:	000a849b          	sext.w	s1,s5
    80006e08:	8762                	mv	a4,s8
    80006e0a:	faa4fde3          	bgeu	s1,a0,80006dc4 <balloc+0xa6>
      m = 1 << (bi % 8);
    80006e0e:	00777693          	and	a3,a4,7
    80006e12:	00d996bb          	sllw	a3,s3,a3
      if ((bp->data[bi / 8] & m) == 0)
    80006e16:	41f7579b          	sraw	a5,a4,0x1f
    80006e1a:	01d7d79b          	srlw	a5,a5,0x1d
    80006e1e:	9fb9                	addw	a5,a5,a4
    80006e20:	4037d79b          	sraw	a5,a5,0x3
    80006e24:	00f90633          	add	a2,s2,a5
    80006e28:	05864603          	lbu	a2,88(a2)
    80006e2c:	00c6f5b3          	and	a1,a3,a2
    80006e30:	d585                	beqz	a1,80006d58 <balloc+0x3a>
    for (bi = 0; bi < BPB && b + bi < sb.size; bi++)
    80006e32:	2705                	addw	a4,a4,1
    80006e34:	2485                	addw	s1,s1,1
    80006e36:	fd471ae3          	bne	a4,s4,80006e0a <balloc+0xec>
    80006e3a:	b769                	j	80006dc4 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80006e3c:	00003517          	auipc	a0,0x3
    80006e40:	f3450513          	add	a0,a0,-204 # 80009d70 <syscalls+0x598>
    80006e44:	ffffa097          	auipc	ra,0xffffa
    80006e48:	40a080e7          	jalr	1034(ra) # 8000124e <printf>
  return 0;
    80006e4c:	4481                	li	s1,0
    80006e4e:	bfa9                	j	80006da8 <balloc+0x8a>

0000000080006e50 <bfree>:

void
bfree(int dev, uint b)
{
    80006e50:	1101                	add	sp,sp,-32
    80006e52:	ec06                	sd	ra,24(sp)
    80006e54:	e822                	sd	s0,16(sp)
    80006e56:	e426                	sd	s1,8(sp)
    80006e58:	e04a                	sd	s2,0(sp)
    80006e5a:	1000                	add	s0,sp,32
    80006e5c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;
  bp = bread(dev, BBLOCK(b, sb));
    80006e5e:	00d5d59b          	srlw	a1,a1,0xd
    80006e62:	0001c797          	auipc	a5,0x1c
    80006e66:	4527a783          	lw	a5,1106(a5) # 800232b4 <sb+0x1c>
    80006e6a:	9dbd                	addw	a1,a1,a5
    80006e6c:	fffff097          	auipc	ra,0xfffff
    80006e70:	940080e7          	jalr	-1728(ra) # 800057ac <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80006e74:	0074f713          	and	a4,s1,7
    80006e78:	4785                	li	a5,1
    80006e7a:	00e797bb          	sllw	a5,a5,a4
  if ((bp->data[bi / 8] & m) == 0)
    80006e7e:	14ce                	sll	s1,s1,0x33
    80006e80:	90d9                	srl	s1,s1,0x36
    80006e82:	00950733          	add	a4,a0,s1
    80006e86:	05874703          	lbu	a4,88(a4)
    80006e8a:	00e7f6b3          	and	a3,a5,a4
    80006e8e:	c69d                	beqz	a3,80006ebc <bfree+0x6c>
    80006e90:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi / 8] &= ~m;
    80006e92:	94aa                	add	s1,s1,a0
    80006e94:	fff7c793          	not	a5,a5
    80006e98:	8f7d                	and	a4,a4,a5
    80006e9a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80006e9e:	fffff097          	auipc	ra,0xfffff
    80006ea2:	0a6080e7          	jalr	166(ra) # 80005f44 <log_write>
  brelse(bp);
    80006ea6:	854a                	mv	a0,s2
    80006ea8:	fffff097          	auipc	ra,0xfffff
    80006eac:	a34080e7          	jalr	-1484(ra) # 800058dc <brelse>
}
    80006eb0:	60e2                	ld	ra,24(sp)
    80006eb2:	6442                	ld	s0,16(sp)
    80006eb4:	64a2                	ld	s1,8(sp)
    80006eb6:	6902                	ld	s2,0(sp)
    80006eb8:	6105                	add	sp,sp,32
    80006eba:	8082                	ret
    panic("freeing free block");
    80006ebc:	00003517          	auipc	a0,0x3
    80006ec0:	ecc50513          	add	a0,a0,-308 # 80009d88 <syscalls+0x5b0>
    80006ec4:	ffffa097          	auipc	ra,0xffffa
    80006ec8:	340080e7          	jalr	832(ra) # 80001204 <panic>

0000000080006ecc <assert>:
#include "cpu.h"

struct superblock sb;

void assert(int condition, char *msg) {
    if (!condition) panic(msg);
    80006ecc:	c111                	beqz	a0,80006ed0 <assert+0x4>
    80006ece:	8082                	ret
void assert(int condition, char *msg) {
    80006ed0:	1141                	add	sp,sp,-16
    80006ed2:	e406                	sd	ra,8(sp)
    80006ed4:	e022                	sd	s0,0(sp)
    80006ed6:	0800                	add	s0,sp,16
    if (!condition) panic(msg);
    80006ed8:	852e                	mv	a0,a1
    80006eda:	ffffa097          	auipc	ra,0xffffa
    80006ede:	32a080e7          	jalr	810(ra) # 80001204 <panic>

0000000080006ee2 <blockcmp>:
  bp = bread(dev, 1);
  memmove(sb, bp->data, sizeof(*sb));
  brelse(bp);
}

bool blockcmp(void *a, void *b) {
    80006ee2:	1141                	add	sp,sp,-16
    80006ee4:	e406                	sd	ra,8(sp)
    80006ee6:	e022                	sd	s0,0(sp)
    80006ee8:	0800                	add	s0,sp,16
    return memcmp(a, b, BSIZE * 2) == 0;
    80006eea:	6605                	lui	a2,0x1
    80006eec:	80060613          	add	a2,a2,-2048 # 800 <_entry-0x7ffff800>
    80006ef0:	ffffa097          	auipc	ra,0xffffa
    80006ef4:	0ee080e7          	jalr	238(ra) # 80000fde <memcmp>
}
    80006ef8:	00153513          	seqz	a0,a0
    80006efc:	60a2                	ld	ra,8(sp)
    80006efe:	6402                	ld	s0,0(sp)
    80006f00:	0141                	add	sp,sp,16
    80006f02:	8082                	ret

0000000080006f04 <fsinit>:

void fsinit(int dev)
{
    80006f04:	7179                	add	sp,sp,-48
    80006f06:	f406                	sd	ra,40(sp)
    80006f08:	f022                	sd	s0,32(sp)
    80006f0a:	ec26                	sd	s1,24(sp)
    80006f0c:	e84a                	sd	s2,16(sp)
    80006f0e:	e44e                	sd	s3,8(sp)
    80006f10:	1800                	add	s0,sp,48
    80006f12:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80006f14:	4585                	li	a1,1
    80006f16:	fffff097          	auipc	ra,0xfffff
    80006f1a:	896080e7          	jalr	-1898(ra) # 800057ac <bread>
    80006f1e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80006f20:	0001c997          	auipc	s3,0x1c
    80006f24:	37898993          	add	s3,s3,888 # 80023298 <sb>
    80006f28:	02000613          	li	a2,32
    80006f2c:	05850593          	add	a1,a0,88
    80006f30:	854e                	mv	a0,s3
    80006f32:	ffffa097          	auipc	ra,0xffffa
    80006f36:	0e6080e7          	jalr	230(ra) # 80001018 <memmove>
  brelse(bp);
    80006f3a:	8526                	mv	a0,s1
    80006f3c:	fffff097          	auipc	ra,0xfffff
    80006f40:	9a0080e7          	jalr	-1632(ra) # 800058dc <brelse>
  readsb(dev, &sb);
  if (sb.magic != FSMAGIC)
    80006f44:	0009a703          	lw	a4,0(s3)
    80006f48:	102037b7          	lui	a5,0x10203
    80006f4c:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80006f50:	02f71263          	bne	a4,a5,80006f74 <fsinit+0x70>
    panic("invalid file system");
  initlog(dev, &sb);
    80006f54:	0001c597          	auipc	a1,0x1c
    80006f58:	34458593          	add	a1,a1,836 # 80023298 <sb>
    80006f5c:	854a                	mv	a0,s2
    80006f5e:	fffff097          	auipc	ra,0xfffff
    80006f62:	d7c080e7          	jalr	-644(ra) # 80005cda <initlog>
}
    80006f66:	70a2                	ld	ra,40(sp)
    80006f68:	7402                	ld	s0,32(sp)
    80006f6a:	64e2                	ld	s1,24(sp)
    80006f6c:	6942                	ld	s2,16(sp)
    80006f6e:	69a2                	ld	s3,8(sp)
    80006f70:	6145                	add	sp,sp,48
    80006f72:	8082                	ret
    panic("invalid file system");
    80006f74:	00003517          	auipc	a0,0x3
    80006f78:	e2c50513          	add	a0,a0,-468 # 80009da0 <syscalls+0x5c8>
    80006f7c:	ffffa097          	auipc	ra,0xffffa
    80006f80:	288080e7          	jalr	648(ra) # 80001204 <panic>

0000000080006f84 <initcode_start>:
    80006f84:	00000097          	.word	0x00000097
    80006f88:	0bc080e7          	.word	0x0bc080e7
    80006f8c:	0000006f          	.word	0x0000006f
    80006f90:	ff010113          	.word	0xff010113
    80006f94:	00813423          	.word	0x00813423
    80006f98:	01010413          	.word	0x01010413
    80006f9c:	00000313          	.word	0x00000313
    80006fa0:	08054a63          	.word	0x08054a63
    80006fa4:	00058693          	.word	0x00058693
    80006fa8:	00058613          	.word	0x00058613
    80006fac:	00000793          	.word	0x00000793
    80006fb0:	00a00813          	.word	0x00a00813
    80006fb4:	00078893          	.word	0x00078893
    80006fb8:	0017879b          	.word	0x0017879b
    80006fbc:	0305673b          	.word	0x0305673b
    80006fc0:	0307071b          	.word	0x0307071b
    80006fc4:	00e60023          	.word	0x00e60023
    80006fc8:	0305453b          	.word	0x0305453b
    80006fcc:	00160613          	.word	0x00160613
    80006fd0:	fe0512e3          	.word	0xfe0512e3
    80006fd4:	00030a63          	.word	0x00030a63
    80006fd8:	00f587b3          	.word	0x00f587b3
    80006fdc:	02d00713          	.word	0x02d00713
    80006fe0:	00e78023          	.word	0x00e78023
    80006fe4:	0028879b          	.word	0x0028879b
    80006fe8:	00f58733          	.word	0x00f58733
    80006fec:	00070023          	.word	0x00070023
    80006ff0:	fff7871b          	.word	0xfff7871b
    80006ff4:	02e05a63          	.word	0x02e05a63
    80006ff8:	00e585b3          	.word	0x00e585b3
    80006ffc:	fff7879b          	.word	0xfff7879b
    80007000:	0006c703          	.word	0x0006c703
    80007004:	0005c603          	.word	0x0005c603
    80007008:	00c68023          	.word	0x00c68023
    8000700c:	00e58023          	.word	0x00e58023
    80007010:	0015071b          	.word	0x0015071b
    80007014:	0007051b          	.word	0x0007051b
    80007018:	00168693          	.word	0x00168693
    8000701c:	fff58593          	.word	0xfff58593
    80007020:	40e7873b          	.word	0x40e7873b
    80007024:	fce54ee3          	.word	0xfce54ee3
    80007028:	00813403          	.word	0x00813403
    8000702c:	01010113          	.word	0x01010113
    80007030:	00008067          	.word	0x00008067
    80007034:	40a0053b          	.word	0x40a0053b
    80007038:	00100313          	.word	0x00100313
    8000703c:	f69ff06f          	.word	0xf69ff06f
    80007040:	fc010113          	.word	0xfc010113
    80007044:	02813c23          	.word	0x02813c23
    80007048:	04010413          	.word	0x04010413
    8000704c:	736577b7          	.word	0x736577b7
    80007050:	42f78793          	.word	0x42f78793
    80007054:	fef42423          	.word	0xfef42423
    80007058:	07400793          	.word	0x07400793
    8000705c:	fef41623          	.word	0xfef41623
    80007060:	00000797          	.word	0x00000797
    80007064:	17478793          	.word	0x17478793
    80007068:	0007b603          	.word	0x0007b603
    8000706c:	0087b683          	.word	0x0087b683
    80007070:	0107b703          	.word	0x0107b703
    80007074:	0187b783          	.word	0x0187b783
    80007078:	fcc43423          	.word	0xfcc43423
    8000707c:	fcd43823          	.word	0xfcd43823
    80007080:	fce43c23          	.word	0xfce43c23
    80007084:	fef43023          	.word	0xfef43023
    80007088:	00400893          	.word	0x00400893
    8000708c:	00000073          	.word	0x00000073
    80007090:	0005051b          	.word	0x0005051b
    80007094:	04054463          	.word	0x04054463
    80007098:	08051463          	.word	0x08051463
    8000709c:	00b00893          	.word	0x00b00893
    800070a0:	00100513          	.word	0x00100513
    800070a4:	00000597          	.word	0x00000597
    800070a8:	0d058593          	.word	0x0d058593
    800070ac:	01600613          	.word	0x01600613
    800070b0:	00000073          	.word	0x00000073
    800070b4:	01800893          	.word	0x01800893
    800070b8:	fe840513          	.word	0xfe840513
    800070bc:	fc840593          	.word	0xfc840593
    800070c0:	00000073          	.word	0x00000073
    800070c4:	0005079b          	.word	0x0005079b
    800070c8:	0207ce63          	.word	0x0207ce63
    800070cc:	00600893          	.word	0x00600893
    800070d0:	00100513          	.word	0x00100513
    800070d4:	00000073          	.word	0x00000073
    800070d8:	01c0006f          	.word	0x01c0006f
    800070dc:	00b00893          	.word	0x00b00893
    800070e0:	00100513          	.word	0x00100513
    800070e4:	00000597          	.word	0x00000597
    800070e8:	07858593          	.word	0x07858593
    800070ec:	01400613          	.word	0x01400613
    800070f0:	00000073          	.word	0x00000073
    800070f4:	00000513          	.word	0x00000513
    800070f8:	03813403          	.word	0x03813403
    800070fc:	04010113          	.word	0x04010113
    80007100:	00008067          	.word	0x00008067
    80007104:	00b00893          	.word	0x00b00893
    80007108:	00100513          	.word	0x00100513
    8000710c:	00000597          	.word	0x00000597
    80007110:	08058593          	.word	0x08058593
    80007114:	01700613          	.word	0x01700613
    80007118:	00000073          	.word	0x00000073
    8000711c:	fb1ff06f          	.word	0xfb1ff06f
    80007120:	00500893          	.word	0x00500893
    80007124:	00000513          	.word	0x00000513
    80007128:	00000073          	.word	0x00000073
    8000712c:	00b00893          	.word	0x00b00893
    80007130:	00100513          	.word	0x00100513
    80007134:	00000597          	.word	0x00000597
    80007138:	07058593          	.word	0x07058593
    8000713c:	01500613          	.word	0x01500613
    80007140:	00000073          	.word	0x00000073
    80007144:	000f47b7          	.word	0x000f47b7
    80007148:	24078793          	.word	0x24078793
    8000714c:	00700893          	.word	0x00700893
    80007150:	00078513          	.word	0x00078513
    80007154:	00000073          	.word	0x00000073
    80007158:	ff5ff06f          	.word	0xff5ff06f
    8000715c:	74696e69          	.word	0x74696e69
    80007160:	65646f63          	.word	0x65646f63
    80007164:	6f66203a          	.word	0x6f66203a
    80007168:	66206b72          	.word	0x66206b72
    8000716c:	0a6c6961          	.word	0x0a6c6961
    80007170:	00000000          	.word	0x00000000
    80007174:	2d2d2d0a          	.word	0x2d2d2d0a
    80007178:	65742d2d          	.word	0x65742d2d
    8000717c:	73207473          	.word	0x73207473
    80007180:	74726174          	.word	0x74726174
    80007184:	2d2d2d2d          	.word	0x2d2d2d2d
    80007188:	00000a2d          	.word	0x00000a2d
    8000718c:	74696e69          	.word	0x74696e69
    80007190:	65646f63          	.word	0x65646f63
    80007194:	7865203a          	.word	0x7865203a
    80007198:	66206365          	.word	0x66206365
    8000719c:	656c6961          	.word	0x656c6961
    800071a0:	00000a64          	.word	0x00000a64
    800071a4:	2d2d2d0a          	.word	0x2d2d2d0a
    800071a8:	65742d2d          	.word	0x65742d2d
    800071ac:	6f207473          	.word	0x6f207473
    800071b0:	2d726576          	.word	0x2d726576
    800071b4:	2d2d2d2d          	.word	0x2d2d2d2d
    800071b8:	0000000a          	.word	0x0000000a
    800071bc:	74736574          	.word	0x74736574
    800071c0:	00000000          	.word	0x00000000
    800071c4:	6c6c6568          	.word	0x6c6c6568
    800071c8:	0000006f          	.word	0x0000006f
    800071cc:	6c726f77          	.word	0x6c726f77
    800071d0:	00000064          	.word	0x00000064
    800071d4:	00000238          	.word	0x00000238
    800071d8:	00000000          	.word	0x00000000
    800071dc:	00000240          	.word	0x00000240
    800071e0:	00000000          	.word	0x00000000
    800071e4:	00000248          	.word	0x00000248
	...

00000000800071f4 <initcode_end>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    800071f4:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    800071f8:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    800071fc:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    800071fe:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    80007200:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    80007204:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    80007208:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    8000720c:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    80007210:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    80007214:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    80007218:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    8000721c:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    80007220:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    80007224:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    80007228:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)      # 恢复栈指针
    8000722c:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    80007230:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    80007232:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    80007234:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    80007238:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    8000723c:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    80007240:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    80007244:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    80007248:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    8000724c:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    80007250:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    80007254:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    80007258:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    8000725c:	8082                	ret
	...

0000000080007260 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    80007260:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    80007262:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80007264:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80007266:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80007268:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    8000726a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000726c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000726e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    80007270:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    80007272:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    80007274:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80007276:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80007278:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    8000727a:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    8000727c:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    8000727e:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    80007280:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    80007282:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    80007284:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    80007286:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    80007288:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    8000728a:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    8000728c:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    8000728e:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    80007290:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    80007292:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    80007294:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    80007296:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    80007298:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    8000729a:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    8000729c:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    8000729e:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    800072a0:	ffffc097          	auipc	ra,0xffffc
    800072a4:	fae080e7          	jalr	-82(ra) # 8000324e <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    800072a8:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    800072aa:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    800072ac:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    800072ae:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800072b0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800072b2:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    800072b4:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    800072b6:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    800072b8:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800072ba:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800072bc:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800072be:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800072c0:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800072c2:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800072c4:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800072c6:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    800072c8:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    800072ca:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    800072cc:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    800072ce:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    800072d0:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    800072d2:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    800072d4:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    800072d6:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    800072d8:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    800072da:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    800072dc:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800072de:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800072e0:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800072e2:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    800072e4:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    800072e6:	10200073          	sret
    800072ea:	0001                	nop
    800072ec:	00000013          	nop

00000000800072f0 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    800072f0:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    800072f4:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    800072f6:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    800072f8:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    800072fa:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    800072fc:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    800072fe:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    80007300:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    80007302:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    80007304:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    80007306:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    8000730a:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    8000730c:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    8000730e:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80007310:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    80007314:	30200073          	mret
    80007318:	00000013          	nop
    8000731c:	00000013          	nop
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000800a:	0536                	sll	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0)
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	9282                	jalr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800080ae:	0536                	sll	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0)
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
