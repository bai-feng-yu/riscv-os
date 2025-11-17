
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
    80000004:	50010113          	add	sp,sp,1280 # 80003500 <stack0>
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
    8000001a:	49a50513          	add	a0,a0,1178 # 800034b0 <started>
    la a1, end
    8000001e:	0000f597          	auipc	a1,0xf
    80000022:	d7a58593          	add	a1,a1,-646 # 8000ed98 <end>

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
    80000046:	fc0080e7          	jalr	-64(ra) # 80001002 <cpuid>
    started = 1;         // 标记系统启动完成
    __sync_synchronize();

  } else {
    //其他CPU等待CPU 0完成初始化
    while(started == 0)
    8000004a:	00003717          	auipc	a4,0x3
    8000004e:	46670713          	add	a4,a4,1126 # 800034b0 <started>
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
    80000062:	fa4080e7          	jalr	-92(ra) # 80001002 <cpuid>
    80000066:	85aa                	mv	a1,a0
    80000068:	00003517          	auipc	a0,0x3
    8000006c:	fb850513          	add	a0,a0,-72 # 80003020 <etext+0x20>
    80000070:	00000097          	auipc	ra,0x0
    80000074:	754080e7          	jalr	1876(ra) # 800007c4 <printf>
    kvminithart();       // 开启分页机制
    80000078:	00001097          	auipc	ra,0x1
    8000007c:	aec080e7          	jalr	-1300(ra) # 80000b64 <kvminithart>
    trapinithart();   // 安装内核陷阱向量
    80000080:	00001097          	auipc	ra,0x1
    80000084:	572080e7          	jalr	1394(ra) # 800015f2 <trapinithart>
    plicinithart();   // 向PLIC请求设备中断
    80000088:	00000097          	auipc	ra,0x0
    8000008c:	424080e7          	jalr	1060(ra) # 800004ac <plicinithart>
  }
  // 所有CPU都进入调度器，开始调度用户进程
  scheduler(); 
    80000090:	00001097          	auipc	ra,0x1
    80000094:	6cc080e7          	jalr	1740(ra) # 8000175c <scheduler>
    initlock(&start_lock,"start_lock");
    80000098:	00003597          	auipc	a1,0x3
    8000009c:	f7858593          	add	a1,a1,-136 # 80003010 <etext+0x10>
    800000a0:	00003517          	auipc	a0,0x3
    800000a4:	44050513          	add	a0,a0,1088 # 800034e0 <start_lock>
    800000a8:	00001097          	auipc	ra,0x1
    800000ac:	398080e7          	jalr	920(ra) # 80001440 <initlock>
    consoleinit();       // 初始化控制台
    800000b0:	00000097          	auipc	ra,0x0
    800000b4:	3b6080e7          	jalr	950(ra) # 80000466 <consoleinit>
    printfinit();        // 初始化printf功能
    800000b8:	00001097          	auipc	ra,0x1
    800000bc:	8ec080e7          	jalr	-1812(ra) # 800009a4 <printfinit>
    printf("\n");
    800000c0:	00003517          	auipc	a0,0x3
    800000c4:	f7050513          	add	a0,a0,-144 # 80003030 <etext+0x30>
    800000c8:	00000097          	auipc	ra,0x0
    800000cc:	6fc080e7          	jalr	1788(ra) # 800007c4 <printf>
    printf("hart %d starting\n", cpuid());
    800000d0:	00001097          	auipc	ra,0x1
    800000d4:	f32080e7          	jalr	-206(ra) # 80001002 <cpuid>
    800000d8:	85aa                	mv	a1,a0
    800000da:	00003517          	auipc	a0,0x3
    800000de:	f4650513          	add	a0,a0,-186 # 80003020 <etext+0x20>
    800000e2:	00000097          	auipc	ra,0x0
    800000e6:	6e2080e7          	jalr	1762(ra) # 800007c4 <printf>
    kinit();             // 物理页面分配器初始化
    800000ea:	00001097          	auipc	ra,0x1
    800000ee:	9b0080e7          	jalr	-1616(ra) # 80000a9a <kinit>
    kvminit();           // 创建内核页表
    800000f2:	00001097          	auipc	ra,0x1
    800000f6:	d0e080e7          	jalr	-754(ra) # 80000e00 <kvminit>
    kvminithart();       // 开启分页机制
    800000fa:	00001097          	auipc	ra,0x1
    800000fe:	a6a080e7          	jalr	-1430(ra) # 80000b64 <kvminithart>
    procinit();       // 进程表初始化
    80000102:	00001097          	auipc	ra,0x1
    80000106:	07e080e7          	jalr	126(ra) # 80001180 <procinit>
    timer_create();      // 陷阱向量(时钟中断）初始化
    8000010a:	00000097          	auipc	ra,0x0
    8000010e:	11c080e7          	jalr	284(ra) # 80000226 <timer_create>
    trapinithart();      // 安装内核陷阱向量
    80000112:	00001097          	auipc	ra,0x1
    80000116:	4e0080e7          	jalr	1248(ra) # 800015f2 <trapinithart>
    plicinit();          // 设置中断控制器
    8000011a:	00000097          	auipc	ra,0x0
    8000011e:	37c080e7          	jalr	892(ra) # 80000496 <plicinit>
    plicinithart();      // 向PLIC请求设备中断
    80000122:	00000097          	auipc	ra,0x0
    80000126:	38a080e7          	jalr	906(ra) # 800004ac <plicinithart>
    userinit();   // 创建第一个用户进程 userinit();   
    8000012a:	00001097          	auipc	ra,0x1
    8000012e:	2c6080e7          	jalr	710(ra) # 800013f0 <userinit>
    started = 1;         // 标记系统启动完成
    80000132:	4785                	li	a5,1
    80000134:	00003717          	auipc	a4,0x3
    80000138:	36f72e23          	sw	a5,892(a4) # 800034b0 <started>
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
    80000150:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffefa67>
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
    800001ea:	0000b717          	auipc	a4,0xb
    800001ee:	31670713          	add	a4,a4,790 # 8000b500 <timer_scratch>
    800001f2:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    800001f4:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    800001f6:	f310                	sd	a2,32(a4)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    800001f8:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    800001fc:	00002797          	auipc	a5,0x2
    80000200:	99478793          	add	a5,a5,-1644 # 80001b90 <timervec>
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
    8000022e:	00003597          	auipc	a1,0x3
    80000232:	e0a58593          	add	a1,a1,-502 # 80003038 <etext+0x38>
    80000236:	0000b517          	auipc	a0,0xb
    8000023a:	41250513          	add	a0,a0,1042 # 8000b648 <sys_timer+0x8>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	202080e7          	jalr	514(ra) # 80001440 <initlock>
    sys_timer.ticks = 0;
    80000246:	0000b797          	auipc	a5,0xb
    8000024a:	3e07bd23          	sd	zero,1018(a5) # 8000b640 <sys_timer>
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
    80000262:	0000b917          	auipc	s2,0xb
    80000266:	29e90913          	add	s2,s2,670 # 8000b500 <timer_scratch>
    8000026a:	0000b497          	auipc	s1,0xb
    8000026e:	3de48493          	add	s1,s1,990 # 8000b648 <sys_timer+0x8>
    80000272:	8526                	mv	a0,s1
    80000274:	00001097          	auipc	ra,0x1
    80000278:	25c080e7          	jalr	604(ra) # 800014d0 <acquire>
    sys_timer.ticks++;
    8000027c:	14093583          	ld	a1,320(s2)
    80000280:	0585                	add	a1,a1,1
    80000282:	14b93023          	sd	a1,320(s2)
    printf("ticks: %d\n", sys_timer.ticks);
    80000286:	00003517          	auipc	a0,0x3
    8000028a:	dc250513          	add	a0,a0,-574 # 80003048 <etext+0x48>
    8000028e:	00000097          	auipc	ra,0x0
    80000292:	536080e7          	jalr	1334(ra) # 800007c4 <printf>
    release(&sys_timer.lk);
    80000296:	8526                	mv	a0,s1
    80000298:	00001097          	auipc	ra,0x1
    8000029c:	2ec080e7          	jalr	748(ra) # 80001584 <release>
}
    800002a0:	60e2                	ld	ra,24(sp)
    800002a2:	6442                	ld	s0,16(sp)
    800002a4:	64a2                	ld	s1,8(sp)
    800002a6:	6902                	ld	s2,0(sp)
    800002a8:	6105                	add	sp,sp,32
    800002aa:	8082                	ret

00000000800002ac <timer_get_ticks>:

// 返回系统时钟ticks
uint64 timer_get_ticks()
{
    800002ac:	1101                	add	sp,sp,-32
    800002ae:	ec06                	sd	ra,24(sp)
    800002b0:	e822                	sd	s0,16(sp)
    800002b2:	e426                	sd	s1,8(sp)
    800002b4:	e04a                	sd	s2,0(sp)
    800002b6:	1000                	add	s0,sp,32
    uint64 xticks;
    acquire(&sys_timer.lk);
    800002b8:	0000b497          	auipc	s1,0xb
    800002bc:	39048493          	add	s1,s1,912 # 8000b648 <sys_timer+0x8>
    800002c0:	8526                	mv	a0,s1
    800002c2:	00001097          	auipc	ra,0x1
    800002c6:	20e080e7          	jalr	526(ra) # 800014d0 <acquire>
    xticks = sys_timer.ticks;
    800002ca:	0000b917          	auipc	s2,0xb
    800002ce:	37693903          	ld	s2,886(s2) # 8000b640 <sys_timer>
    release(&sys_timer.lk);
    800002d2:	8526                	mv	a0,s1
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	2b0080e7          	jalr	688(ra) # 80001584 <release>
    return xticks;
    800002dc:	854a                	mv	a0,s2
    800002de:	60e2                	ld	ra,24(sp)
    800002e0:	6442                	ld	s0,16(sp)
    800002e2:	64a2                	ld	s1,8(sp)
    800002e4:	6902                	ld	s2,0(sp)
    800002e6:	6105                	add	sp,sp,32
    800002e8:	8082                	ret

00000000800002ea <uartinit>:

void uartstart();

void
uartinit(void)
{
    800002ea:	1141                	add	sp,sp,-16
    800002ec:	e406                	sd	ra,8(sp)
    800002ee:	e022                	sd	s0,0(sp)
    800002f0:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800002f2:	100007b7          	lui	a5,0x10000
    800002f6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800002fa:	f8000713          	li	a4,-128
    800002fe:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000302:	470d                	li	a4,3
    80000304:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000308:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000030c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000310:	469d                	li	a3,7
    80000312:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000316:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000031a:	00003597          	auipc	a1,0x3
    8000031e:	d3e58593          	add	a1,a1,-706 # 80003058 <etext+0x58>
    80000322:	0000b517          	auipc	a0,0xb
    80000326:	33e50513          	add	a0,a0,830 # 8000b660 <uart_tx_lock>
    8000032a:	00001097          	auipc	ra,0x1
    8000032e:	116080e7          	jalr	278(ra) # 80001440 <initlock>
}
    80000332:	60a2                	ld	ra,8(sp)
    80000334:	6402                	ld	s0,0(sp)
    80000336:	0141                	add	sp,sp,16
    80000338:	8082                	ret

000000008000033a <uartputc_sync>:
// 不使用中断的uartputc的替换版本
// 用于内核printf和回显字符
// 它会持续等待uart的输出寄存器为空(同步性、阻塞性)
void
uartputc_sync(int c)
{
    8000033a:	1101                	add	sp,sp,-32
    8000033c:	ec06                	sd	ra,24(sp)
    8000033e:	e822                	sd	s0,16(sp)
    80000340:	e426                	sd	s1,8(sp)
    80000342:	1000                	add	s0,sp,32
    80000344:	84aa                	mv	s1,a0
  // 关中断，防止串口中断再次进入造成竞争
  push_off();
    80000346:	00001097          	auipc	ra,0x1
    8000034a:	13e080e7          	jalr	318(ra) # 80001484 <push_off>
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    8000034e:	00003797          	auipc	a5,0x3
    80000352:	17a7a783          	lw	a5,378(a5) # 800034c8 <panicked>
    for(;;)
      ;
  }

  // 等待LSR中的发送寄存器为空标识被置位
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000356:	10000737          	lui	a4,0x10000
  if(panicked){
    8000035a:	c391                	beqz	a5,8000035e <uartputc_sync+0x24>
    for(;;)
    8000035c:	a001                	j	8000035c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000035e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000362:	0207f793          	and	a5,a5,32
    80000366:	dfe5                	beqz	a5,8000035e <uartputc_sync+0x24>
    ;
  
  // 立即通过UART发送字符
  WriteReg(THR, c);
    80000368:	0ff4f513          	zext.b	a0,s1
    8000036c:	100007b7          	lui	a5,0x10000
    80000370:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
  
  // 恢复之前的中断状态
  pop_off();
    80000374:	00001097          	auipc	ra,0x1
    80000378:	1b0080e7          	jalr	432(ra) # 80001524 <pop_off>
}
    8000037c:	60e2                	ld	ra,24(sp)
    8000037e:	6442                	ld	s0,16(sp)
    80000380:	64a2                	ld	s1,8(sp)
    80000382:	6105                	add	sp,sp,32
    80000384:	8082                	ret

0000000080000386 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000386:	1141                	add	sp,sp,-16
    80000388:	e422                	sd	s0,8(sp)
    8000038a:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000038c:	100007b7          	lui	a5,0x10000
    80000390:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000394:	8b85                	and	a5,a5,1
    80000396:	cb81                	beqz	a5,800003a6 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000398:	100007b7          	lui	a5,0x10000
    8000039c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800003a0:	6422                	ld	s0,8(sp)
    800003a2:	0141                	add	sp,sp,16
    800003a4:	8082                	ret
    return -1;
    800003a6:	557d                	li	a0,-1
    800003a8:	bfe5                	j	800003a0 <uartgetc+0x1a>

00000000800003aa <uartintr>:
// 注意两种情况下会触发此函数：
// 1.输入通道RX为满(即键盘有数据输入)
// 2.输出通道TX为空
void
uartintr(void)
{
    800003aa:	1101                	add	sp,sp,-32
    800003ac:	ec06                	sd	ra,24(sp)
    800003ae:	e822                	sd	s0,16(sp)
    800003b0:	e426                	sd	s1,8(sp)
    800003b2:	1000                	add	s0,sp,32
  // release(&uart_tx_lock);
  
  while(1)
  {
    int c = uartgetc();
    if(c == -1) break;
    800003b4:	54fd                	li	s1,-1
    800003b6:	a029                	j	800003c0 <uartintr+0x16>
    consputc(c);
    800003b8:	00000097          	auipc	ra,0x0
    800003bc:	06c080e7          	jalr	108(ra) # 80000424 <consputc>
    int c = uartgetc();
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	fc6080e7          	jalr	-58(ra) # 80000386 <uartgetc>
    if(c == -1) break;
    800003c8:	fe9518e3          	bne	a0,s1,800003b8 <uartintr+0xe>
  }
}
    800003cc:	60e2                	ld	ra,24(sp)
    800003ce:	6442                	ld	s0,16(sp)
    800003d0:	64a2                	ld	s1,8(sp)
    800003d2:	6105                	add	sp,sp,32
    800003d4:	8082                	ret

00000000800003d6 <uart_putc>:


void uart_putc(char c) {
    800003d6:	1141                	add	sp,sp,-16
    800003d8:	e422                	sd	s0,8(sp)
    800003da:	0800                	add	s0,sp,16
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    800003dc:	10000737          	lui	a4,0x10000
    800003e0:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800003e4:	0207f793          	and	a5,a5,32
    800003e8:	dfe5                	beqz	a5,800003e0 <uart_putc+0xa>
    uart[0] = c;
    800003ea:	100007b7          	lui	a5,0x10000
    800003ee:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    800003f2:	6422                	ld	s0,8(sp)
    800003f4:	0141                	add	sp,sp,16
    800003f6:	8082                	ret

00000000800003f8 <uart_puts>:

void uart_puts(char *s) {
    800003f8:	1101                	add	sp,sp,-32
    800003fa:	ec06                	sd	ra,24(sp)
    800003fc:	e822                	sd	s0,16(sp)
    800003fe:	e426                	sd	s1,8(sp)
    80000400:	1000                	add	s0,sp,32
    80000402:	84aa                	mv	s1,a0
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000404:	00054503          	lbu	a0,0(a0)
    80000408:	c909                	beqz	a0,8000041a <uart_puts+0x22>
        uart_putc(*s);    // 输出当前字符
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	fcc080e7          	jalr	-52(ra) # 800003d6 <uart_putc>
        s++;              // 移动到下一个字符
    80000412:	0485                	add	s1,s1,1
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
    80000414:	0004c503          	lbu	a0,0(s1)
    80000418:	f96d                	bnez	a0,8000040a <uart_puts+0x12>
    }
}
    8000041a:	60e2                	ld	ra,24(sp)
    8000041c:	6442                	ld	s0,16(sp)
    8000041e:	64a2                	ld	s1,8(sp)
    80000420:	6105                	add	sp,sp,32
    80000422:	8082                	ret

0000000080000424 <consputc>:

// 发送一个字符到UART，被(内核)printf调用，以及回显输入字符
// 但不会被write()调用
void
consputc(int c)
{
    80000424:	1141                	add	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	add	s0,sp,16
  // 如果当前字符是退格键
  if(c == BACKSPACE){
    8000042c:	07f00793          	li	a5,127
    80000430:	00f50a63          	beq	a0,a5,80000444 <consputc+0x20>

    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    
    // 如果不是退格键，那么按照原样字符输出
    uartputc_sync(c);
    80000434:	00000097          	auipc	ra,0x0
    80000438:	f06080e7          	jalr	-250(ra) # 8000033a <uartputc_sync>
  }
}
    8000043c:	60a2                	ld	ra,8(sp)
    8000043e:	6402                	ld	s0,0(sp)
    80000440:	0141                	add	sp,sp,16
    80000442:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000444:	4521                	li	a0,8
    80000446:	00000097          	auipc	ra,0x0
    8000044a:	ef4080e7          	jalr	-268(ra) # 8000033a <uartputc_sync>
    8000044e:	02000513          	li	a0,32
    80000452:	00000097          	auipc	ra,0x0
    80000456:	ee8080e7          	jalr	-280(ra) # 8000033a <uartputc_sync>
    8000045a:	4521                	li	a0,8
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	ede080e7          	jalr	-290(ra) # 8000033a <uartputc_sync>
    80000464:	bfe1                	j	8000043c <consputc+0x18>

0000000080000466 <consoleinit>:
//   release(&cons.lock);
// }

void
consoleinit(void)
{
    80000466:	1141                	add	sp,sp,-16
    80000468:	e406                	sd	ra,8(sp)
    8000046a:	e022                	sd	s0,0(sp)
    8000046c:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046e:	00003597          	auipc	a1,0x3
    80000472:	bf258593          	add	a1,a1,-1038 # 80003060 <etext+0x60>
    80000476:	0000b517          	auipc	a0,0xb
    8000047a:	22250513          	add	a0,a0,546 # 8000b698 <cons>
    8000047e:	00001097          	auipc	ra,0x1
    80000482:	fc2080e7          	jalr	-62(ra) # 80001440 <initlock>

  uartinit();
    80000486:	00000097          	auipc	ra,0x0
    8000048a:	e64080e7          	jalr	-412(ra) # 800002ea <uartinit>

  // devsw[CONSOLE].read = consoleread;
  // devsw[CONSOLE].write = consolewrite;
}
    8000048e:	60a2                	ld	ra,8(sp)
    80000490:	6402                	ld	s0,0(sp)
    80000492:	0141                	add	sp,sp,16
    80000494:	8082                	ret

0000000080000496 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80000496:	1141                	add	sp,sp,-16
    80000498:	e422                	sd	s0,8(sp)
    8000049a:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    8000049c:	0c0007b7          	lui	a5,0xc000
    800004a0:	4705                	li	a4,1
    800004a2:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800004a4:	c3d8                	sw	a4,4(a5)
}
    800004a6:	6422                	ld	s0,8(sp)
    800004a8:	0141                	add	sp,sp,16
    800004aa:	8082                	ret

00000000800004ac <plicinithart>:

void
plicinithart(void)
{
    800004ac:	1141                	add	sp,sp,-16
    800004ae:	e406                	sd	ra,8(sp)
    800004b0:	e022                	sd	s0,0(sp)
    800004b2:	0800                	add	s0,sp,16
  int hart = cpuid();
    800004b4:	00001097          	auipc	ra,0x1
    800004b8:	b4e080e7          	jalr	-1202(ra) # 80001002 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800004bc:	0085171b          	sllw	a4,a0,0x8
    800004c0:	0c0027b7          	lui	a5,0xc002
    800004c4:	97ba                	add	a5,a5,a4
    800004c6:	40200713          	li	a4,1026
    800004ca:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800004ce:	00d5151b          	sllw	a0,a0,0xd
    800004d2:	0c2017b7          	lui	a5,0xc201
    800004d6:	97aa                	add	a5,a5,a0
    800004d8:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800004dc:	60a2                	ld	ra,8(sp)
    800004de:	6402                	ld	s0,0(sp)
    800004e0:	0141                	add	sp,sp,16
    800004e2:	8082                	ret

00000000800004e4 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800004e4:	1141                	add	sp,sp,-16
    800004e6:	e406                	sd	ra,8(sp)
    800004e8:	e022                	sd	s0,0(sp)
    800004ea:	0800                	add	s0,sp,16
  int hart = cpuid();
    800004ec:	00001097          	auipc	ra,0x1
    800004f0:	b16080e7          	jalr	-1258(ra) # 80001002 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800004f4:	00d5151b          	sllw	a0,a0,0xd
    800004f8:	0c2017b7          	lui	a5,0xc201
    800004fc:	97aa                	add	a5,a5,a0
  return irq;
}
    800004fe:	43c8                	lw	a0,4(a5)
    80000500:	60a2                	ld	ra,8(sp)
    80000502:	6402                	ld	s0,0(sp)
    80000504:	0141                	add	sp,sp,16
    80000506:	8082                	ret

0000000080000508 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80000508:	1101                	add	sp,sp,-32
    8000050a:	ec06                	sd	ra,24(sp)
    8000050c:	e822                	sd	s0,16(sp)
    8000050e:	e426                	sd	s1,8(sp)
    80000510:	1000                	add	s0,sp,32
    80000512:	84aa                	mv	s1,a0
  int hart = cpuid();
    80000514:	00001097          	auipc	ra,0x1
    80000518:	aee080e7          	jalr	-1298(ra) # 80001002 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000051c:	00d5151b          	sllw	a0,a0,0xd
    80000520:	0c2017b7          	lui	a5,0xc201
    80000524:	97aa                	add	a5,a5,a0
    80000526:	c3c4                	sw	s1,4(a5)
}
    80000528:	60e2                	ld	ra,24(sp)
    8000052a:	6442                	ld	s0,16(sp)
    8000052c:	64a2                	ld	s1,8(sp)
    8000052e:	6105                	add	sp,sp,32
    80000530:	8082                	ret

0000000080000532 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000532:	1141                	add	sp,sp,-16
    80000534:	e422                	sd	s0,8(sp)
    80000536:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000538:	ca19                	beqz	a2,8000054e <memset+0x1c>
    8000053a:	87aa                	mv	a5,a0
    8000053c:	1602                	sll	a2,a2,0x20
    8000053e:	9201                	srl	a2,a2,0x20
    80000540:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000544:	00b78023          	sb	a1,0(a5) # c201000 <_entry-0x73dff000>
  for(i = 0; i < n; i++){
    80000548:	0785                	add	a5,a5,1
    8000054a:	fee79de3          	bne	a5,a4,80000544 <memset+0x12>
  }
  return dst;
}
    8000054e:	6422                	ld	s0,8(sp)
    80000550:	0141                	add	sp,sp,16
    80000552:	8082                	ret

0000000080000554 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000554:	1141                	add	sp,sp,-16
    80000556:	e422                	sd	s0,8(sp)
    80000558:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    8000055a:	ca05                	beqz	a2,8000058a <memcmp+0x36>
    8000055c:	fff6069b          	addw	a3,a2,-1
    80000560:	1682                	sll	a3,a3,0x20
    80000562:	9281                	srl	a3,a3,0x20
    80000564:	0685                	add	a3,a3,1
    80000566:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000568:	00054783          	lbu	a5,0(a0)
    8000056c:	0005c703          	lbu	a4,0(a1)
    80000570:	00e79863          	bne	a5,a4,80000580 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000574:	0505                	add	a0,a0,1
    80000576:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000578:	fed518e3          	bne	a0,a3,80000568 <memcmp+0x14>
  }

  return 0;
    8000057c:	4501                	li	a0,0
    8000057e:	a019                	j	80000584 <memcmp+0x30>
      return *s1 - *s2;
    80000580:	40e7853b          	subw	a0,a5,a4
}
    80000584:	6422                	ld	s0,8(sp)
    80000586:	0141                	add	sp,sp,16
    80000588:	8082                	ret
  return 0;
    8000058a:	4501                	li	a0,0
    8000058c:	bfe5                	j	80000584 <memcmp+0x30>

000000008000058e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    8000058e:	1141                	add	sp,sp,-16
    80000590:	e422                	sd	s0,8(sp)
    80000592:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000594:	c205                	beqz	a2,800005b4 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000596:	02a5e263          	bltu	a1,a0,800005ba <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    8000059a:	1602                	sll	a2,a2,0x20
    8000059c:	9201                	srl	a2,a2,0x20
    8000059e:	00c587b3          	add	a5,a1,a2
{
    800005a2:	872a                	mv	a4,a0
      *d++ = *s++;
    800005a4:	0585                	add	a1,a1,1
    800005a6:	0705                	add	a4,a4,1
    800005a8:	fff5c683          	lbu	a3,-1(a1)
    800005ac:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    800005b0:	fef59ae3          	bne	a1,a5,800005a4 <memmove+0x16>

  return dst;
}
    800005b4:	6422                	ld	s0,8(sp)
    800005b6:	0141                	add	sp,sp,16
    800005b8:	8082                	ret
  if(s < d && s + n > d){
    800005ba:	02061693          	sll	a3,a2,0x20
    800005be:	9281                	srl	a3,a3,0x20
    800005c0:	00d58733          	add	a4,a1,a3
    800005c4:	fce57be3          	bgeu	a0,a4,8000059a <memmove+0xc>
    d += n;
    800005c8:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800005ca:	fff6079b          	addw	a5,a2,-1
    800005ce:	1782                	sll	a5,a5,0x20
    800005d0:	9381                	srl	a5,a5,0x20
    800005d2:	fff7c793          	not	a5,a5
    800005d6:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800005d8:	177d                	add	a4,a4,-1
    800005da:	16fd                	add	a3,a3,-1
    800005dc:	00074603          	lbu	a2,0(a4)
    800005e0:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800005e4:	fee79ae3          	bne	a5,a4,800005d8 <memmove+0x4a>
    800005e8:	b7f1                	j	800005b4 <memmove+0x26>

00000000800005ea <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800005ea:	1141                	add	sp,sp,-16
    800005ec:	e406                	sd	ra,8(sp)
    800005ee:	e022                	sd	s0,0(sp)
    800005f0:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	f9c080e7          	jalr	-100(ra) # 8000058e <memmove>
}
    800005fa:	60a2                	ld	ra,8(sp)
    800005fc:	6402                	ld	s0,0(sp)
    800005fe:	0141                	add	sp,sp,16
    80000600:	8082                	ret

0000000080000602 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000602:	1141                	add	sp,sp,-16
    80000604:	e422                	sd	s0,8(sp)
    80000606:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000608:	ce11                	beqz	a2,80000624 <strncmp+0x22>
    8000060a:	00054783          	lbu	a5,0(a0)
    8000060e:	cf89                	beqz	a5,80000628 <strncmp+0x26>
    80000610:	0005c703          	lbu	a4,0(a1)
    80000614:	00f71a63          	bne	a4,a5,80000628 <strncmp+0x26>
    n--, p++, q++;
    80000618:	367d                	addw	a2,a2,-1
    8000061a:	0505                	add	a0,a0,1
    8000061c:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000061e:	f675                	bnez	a2,8000060a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000620:	4501                	li	a0,0
    80000622:	a809                	j	80000634 <strncmp+0x32>
    80000624:	4501                	li	a0,0
    80000626:	a039                	j	80000634 <strncmp+0x32>
  if(n == 0)
    80000628:	ca09                	beqz	a2,8000063a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000062a:	00054503          	lbu	a0,0(a0)
    8000062e:	0005c783          	lbu	a5,0(a1)
    80000632:	9d1d                	subw	a0,a0,a5
}
    80000634:	6422                	ld	s0,8(sp)
    80000636:	0141                	add	sp,sp,16
    80000638:	8082                	ret
    return 0;
    8000063a:	4501                	li	a0,0
    8000063c:	bfe5                	j	80000634 <strncmp+0x32>

000000008000063e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    8000063e:	1141                	add	sp,sp,-16
    80000640:	e422                	sd	s0,8(sp)
    80000642:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000644:	87aa                	mv	a5,a0
    80000646:	86b2                	mv	a3,a2
    80000648:	367d                	addw	a2,a2,-1
    8000064a:	00d05963          	blez	a3,8000065c <strncpy+0x1e>
    8000064e:	0785                	add	a5,a5,1
    80000650:	0005c703          	lbu	a4,0(a1)
    80000654:	fee78fa3          	sb	a4,-1(a5)
    80000658:	0585                	add	a1,a1,1
    8000065a:	f775                	bnez	a4,80000646 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000065c:	873e                	mv	a4,a5
    8000065e:	9fb5                	addw	a5,a5,a3
    80000660:	37fd                	addw	a5,a5,-1
    80000662:	00c05963          	blez	a2,80000674 <strncpy+0x36>
    *s++ = 0;
    80000666:	0705                	add	a4,a4,1
    80000668:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    8000066c:	40e786bb          	subw	a3,a5,a4
    80000670:	fed04be3          	bgtz	a3,80000666 <strncpy+0x28>
  return os;
}
    80000674:	6422                	ld	s0,8(sp)
    80000676:	0141                	add	sp,sp,16
    80000678:	8082                	ret

000000008000067a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000067a:	1141                	add	sp,sp,-16
    8000067c:	e422                	sd	s0,8(sp)
    8000067e:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000680:	02c05363          	blez	a2,800006a6 <safestrcpy+0x2c>
    80000684:	fff6069b          	addw	a3,a2,-1
    80000688:	1682                	sll	a3,a3,0x20
    8000068a:	9281                	srl	a3,a3,0x20
    8000068c:	96ae                	add	a3,a3,a1
    8000068e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000690:	00d58963          	beq	a1,a3,800006a2 <safestrcpy+0x28>
    80000694:	0585                	add	a1,a1,1
    80000696:	0785                	add	a5,a5,1
    80000698:	fff5c703          	lbu	a4,-1(a1)
    8000069c:	fee78fa3          	sb	a4,-1(a5)
    800006a0:	fb65                	bnez	a4,80000690 <safestrcpy+0x16>
    ;
  *s = 0;
    800006a2:	00078023          	sb	zero,0(a5)
  return os;
}
    800006a6:	6422                	ld	s0,8(sp)
    800006a8:	0141                	add	sp,sp,16
    800006aa:	8082                	ret

00000000800006ac <strlen>:

int
strlen(const char *s)
{
    800006ac:	1141                	add	sp,sp,-16
    800006ae:	e422                	sd	s0,8(sp)
    800006b0:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800006b2:	00054783          	lbu	a5,0(a0)
    800006b6:	cf91                	beqz	a5,800006d2 <strlen+0x26>
    800006b8:	0505                	add	a0,a0,1
    800006ba:	87aa                	mv	a5,a0
    800006bc:	86be                	mv	a3,a5
    800006be:	0785                	add	a5,a5,1
    800006c0:	fff7c703          	lbu	a4,-1(a5)
    800006c4:	ff65                	bnez	a4,800006bc <strlen+0x10>
    800006c6:	40a6853b          	subw	a0,a3,a0
    800006ca:	2505                	addw	a0,a0,1
    ;
  return n;
}
    800006cc:	6422                	ld	s0,8(sp)
    800006ce:	0141                	add	sp,sp,16
    800006d0:	8082                	ret
  for(n = 0; s[n]; n++)
    800006d2:	4501                	li	a0,0
    800006d4:	bfe5                	j	800006cc <strlen+0x20>

00000000800006d6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800006d6:	7179                	add	sp,sp,-48
    800006d8:	f406                	sd	ra,40(sp)
    800006da:	f022                	sd	s0,32(sp)
    800006dc:	ec26                	sd	s1,24(sp)
    800006de:	e84a                	sd	s2,16(sp)
    800006e0:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800006e2:	c219                	beqz	a2,800006e8 <printint+0x12>
    800006e4:	08054763          	bltz	a0,80000772 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800006e8:	2501                	sext.w	a0,a0
    800006ea:	4881                	li	a7,0
    800006ec:	fd040693          	add	a3,s0,-48

  i = 0;
    800006f0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800006f2:	2581                	sext.w	a1,a1
    800006f4:	00003617          	auipc	a2,0x3
    800006f8:	99c60613          	add	a2,a2,-1636 # 80003090 <digits>
    800006fc:	883a                	mv	a6,a4
    800006fe:	2705                	addw	a4,a4,1
    80000700:	02b577bb          	remuw	a5,a0,a1
    80000704:	1782                	sll	a5,a5,0x20
    80000706:	9381                	srl	a5,a5,0x20
    80000708:	97b2                	add	a5,a5,a2
    8000070a:	0007c783          	lbu	a5,0(a5)
    8000070e:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000712:	0005079b          	sext.w	a5,a0
    80000716:	02b5553b          	divuw	a0,a0,a1
    8000071a:	0685                	add	a3,a3,1
    8000071c:	feb7f0e3          	bgeu	a5,a1,800006fc <printint+0x26>

  if(sign)
    80000720:	00088c63          	beqz	a7,80000738 <printint+0x62>
    buf[i++] = '-';
    80000724:	fe070793          	add	a5,a4,-32
    80000728:	00878733          	add	a4,a5,s0
    8000072c:	02d00793          	li	a5,45
    80000730:	fef70823          	sb	a5,-16(a4)
    80000734:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    80000738:	02e05763          	blez	a4,80000766 <printint+0x90>
    8000073c:	fd040793          	add	a5,s0,-48
    80000740:	00e784b3          	add	s1,a5,a4
    80000744:	fff78913          	add	s2,a5,-1
    80000748:	993a                	add	s2,s2,a4
    8000074a:	377d                	addw	a4,a4,-1
    8000074c:	1702                	sll	a4,a4,0x20
    8000074e:	9301                	srl	a4,a4,0x20
    80000750:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000754:	fff4c503          	lbu	a0,-1(s1)
    80000758:	00000097          	auipc	ra,0x0
    8000075c:	ccc080e7          	jalr	-820(ra) # 80000424 <consputc>
  while(--i >= 0)
    80000760:	14fd                	add	s1,s1,-1
    80000762:	ff2499e3          	bne	s1,s2,80000754 <printint+0x7e>
}
    80000766:	70a2                	ld	ra,40(sp)
    80000768:	7402                	ld	s0,32(sp)
    8000076a:	64e2                	ld	s1,24(sp)
    8000076c:	6942                	ld	s2,16(sp)
    8000076e:	6145                	add	sp,sp,48
    80000770:	8082                	ret
    x = -xx;
    80000772:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000776:	4885                	li	a7,1
    x = -xx;
    80000778:	bf95                	j	800006ec <printint+0x16>

000000008000077a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000077a:	1101                	add	sp,sp,-32
    8000077c:	ec06                	sd	ra,24(sp)
    8000077e:	e822                	sd	s0,16(sp)
    80000780:	e426                	sd	s1,8(sp)
    80000782:	1000                	add	s0,sp,32
    80000784:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000786:	0000b797          	auipc	a5,0xb
    8000078a:	fc07a923          	sw	zero,-46(a5) # 8000b758 <pr+0x18>
  printf("panic: ");
    8000078e:	00003517          	auipc	a0,0x3
    80000792:	8da50513          	add	a0,a0,-1830 # 80003068 <etext+0x68>
    80000796:	00000097          	auipc	ra,0x0
    8000079a:	02e080e7          	jalr	46(ra) # 800007c4 <printf>
  printf(s);
    8000079e:	8526                	mv	a0,s1
    800007a0:	00000097          	auipc	ra,0x0
    800007a4:	024080e7          	jalr	36(ra) # 800007c4 <printf>
  printf("\n");
    800007a8:	00003517          	auipc	a0,0x3
    800007ac:	88850513          	add	a0,a0,-1912 # 80003030 <etext+0x30>
    800007b0:	00000097          	auipc	ra,0x0
    800007b4:	014080e7          	jalr	20(ra) # 800007c4 <printf>
  panicked = 1; // freeze uart output from other CPUs
    800007b8:	4785                	li	a5,1
    800007ba:	00003717          	auipc	a4,0x3
    800007be:	d0f72723          	sw	a5,-754(a4) # 800034c8 <panicked>
  for(;;)
    800007c2:	a001                	j	800007c2 <panic+0x48>

00000000800007c4 <printf>:
{
    800007c4:	7131                	add	sp,sp,-192
    800007c6:	fc86                	sd	ra,120(sp)
    800007c8:	f8a2                	sd	s0,112(sp)
    800007ca:	f4a6                	sd	s1,104(sp)
    800007cc:	f0ca                	sd	s2,96(sp)
    800007ce:	ecce                	sd	s3,88(sp)
    800007d0:	e8d2                	sd	s4,80(sp)
    800007d2:	e4d6                	sd	s5,72(sp)
    800007d4:	e0da                	sd	s6,64(sp)
    800007d6:	fc5e                	sd	s7,56(sp)
    800007d8:	f862                	sd	s8,48(sp)
    800007da:	f466                	sd	s9,40(sp)
    800007dc:	f06a                	sd	s10,32(sp)
    800007de:	ec6e                	sd	s11,24(sp)
    800007e0:	0100                	add	s0,sp,128
    800007e2:	8a2a                	mv	s4,a0
    800007e4:	e40c                	sd	a1,8(s0)
    800007e6:	e810                	sd	a2,16(s0)
    800007e8:	ec14                	sd	a3,24(s0)
    800007ea:	f018                	sd	a4,32(s0)
    800007ec:	f41c                	sd	a5,40(s0)
    800007ee:	03043823          	sd	a6,48(s0)
    800007f2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800007f6:	0000bd97          	auipc	s11,0xb
    800007fa:	f62dad83          	lw	s11,-158(s11) # 8000b758 <pr+0x18>
  if(locking)
    800007fe:	020d9b63          	bnez	s11,80000834 <printf+0x70>
  if (fmt == 0)
    80000802:	040a0263          	beqz	s4,80000846 <printf+0x82>
  va_start(ap, fmt);
    80000806:	00840793          	add	a5,s0,8
    8000080a:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000080e:	000a4503          	lbu	a0,0(s4)
    80000812:	14050f63          	beqz	a0,80000970 <printf+0x1ac>
    80000816:	4981                	li	s3,0
    if(c != '%'){
    80000818:	02500a93          	li	s5,37
    switch(c){
    8000081c:	07000b93          	li	s7,112
  consputc('x');
    80000820:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000822:	00003b17          	auipc	s6,0x3
    80000826:	86eb0b13          	add	s6,s6,-1938 # 80003090 <digits>
    switch(c){
    8000082a:	07300c93          	li	s9,115
    8000082e:	06400c13          	li	s8,100
    80000832:	a82d                	j	8000086c <printf+0xa8>
    acquire(&pr.lock);
    80000834:	0000b517          	auipc	a0,0xb
    80000838:	f0c50513          	add	a0,a0,-244 # 8000b740 <pr>
    8000083c:	00001097          	auipc	ra,0x1
    80000840:	c94080e7          	jalr	-876(ra) # 800014d0 <acquire>
    80000844:	bf7d                	j	80000802 <printf+0x3e>
    panic("null fmt");
    80000846:	00003517          	auipc	a0,0x3
    8000084a:	83250513          	add	a0,a0,-1998 # 80003078 <etext+0x78>
    8000084e:	00000097          	auipc	ra,0x0
    80000852:	f2c080e7          	jalr	-212(ra) # 8000077a <panic>
      consputc(c);
    80000856:	00000097          	auipc	ra,0x0
    8000085a:	bce080e7          	jalr	-1074(ra) # 80000424 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000085e:	2985                	addw	s3,s3,1
    80000860:	013a07b3          	add	a5,s4,s3
    80000864:	0007c503          	lbu	a0,0(a5)
    80000868:	10050463          	beqz	a0,80000970 <printf+0x1ac>
    if(c != '%'){
    8000086c:	ff5515e3          	bne	a0,s5,80000856 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000870:	2985                	addw	s3,s3,1
    80000872:	013a07b3          	add	a5,s4,s3
    80000876:	0007c783          	lbu	a5,0(a5)
    8000087a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000087e:	cbed                	beqz	a5,80000970 <printf+0x1ac>
    switch(c){
    80000880:	05778a63          	beq	a5,s7,800008d4 <printf+0x110>
    80000884:	02fbf663          	bgeu	s7,a5,800008b0 <printf+0xec>
    80000888:	09978863          	beq	a5,s9,80000918 <printf+0x154>
    8000088c:	07800713          	li	a4,120
    80000890:	0ce79563          	bne	a5,a4,8000095a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000894:	f8843783          	ld	a5,-120(s0)
    80000898:	00878713          	add	a4,a5,8
    8000089c:	f8e43423          	sd	a4,-120(s0)
    800008a0:	4605                	li	a2,1
    800008a2:	85ea                	mv	a1,s10
    800008a4:	4388                	lw	a0,0(a5)
    800008a6:	00000097          	auipc	ra,0x0
    800008aa:	e30080e7          	jalr	-464(ra) # 800006d6 <printint>
      break;
    800008ae:	bf45                	j	8000085e <printf+0x9a>
    switch(c){
    800008b0:	09578f63          	beq	a5,s5,8000094e <printf+0x18a>
    800008b4:	0b879363          	bne	a5,s8,8000095a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    800008b8:	f8843783          	ld	a5,-120(s0)
    800008bc:	00878713          	add	a4,a5,8
    800008c0:	f8e43423          	sd	a4,-120(s0)
    800008c4:	4605                	li	a2,1
    800008c6:	45a9                	li	a1,10
    800008c8:	4388                	lw	a0,0(a5)
    800008ca:	00000097          	auipc	ra,0x0
    800008ce:	e0c080e7          	jalr	-500(ra) # 800006d6 <printint>
      break;
    800008d2:	b771                	j	8000085e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800008d4:	f8843783          	ld	a5,-120(s0)
    800008d8:	00878713          	add	a4,a5,8
    800008dc:	f8e43423          	sd	a4,-120(s0)
    800008e0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800008e4:	03000513          	li	a0,48
    800008e8:	00000097          	auipc	ra,0x0
    800008ec:	b3c080e7          	jalr	-1220(ra) # 80000424 <consputc>
  consputc('x');
    800008f0:	07800513          	li	a0,120
    800008f4:	00000097          	auipc	ra,0x0
    800008f8:	b30080e7          	jalr	-1232(ra) # 80000424 <consputc>
    800008fc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800008fe:	03c95793          	srl	a5,s2,0x3c
    80000902:	97da                	add	a5,a5,s6
    80000904:	0007c503          	lbu	a0,0(a5)
    80000908:	00000097          	auipc	ra,0x0
    8000090c:	b1c080e7          	jalr	-1252(ra) # 80000424 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000910:	0912                	sll	s2,s2,0x4
    80000912:	34fd                	addw	s1,s1,-1
    80000914:	f4ed                	bnez	s1,800008fe <printf+0x13a>
    80000916:	b7a1                	j	8000085e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    80000918:	f8843783          	ld	a5,-120(s0)
    8000091c:	00878713          	add	a4,a5,8
    80000920:	f8e43423          	sd	a4,-120(s0)
    80000924:	6384                	ld	s1,0(a5)
    80000926:	cc89                	beqz	s1,80000940 <printf+0x17c>
      for(; *s; s++)
    80000928:	0004c503          	lbu	a0,0(s1)
    8000092c:	d90d                	beqz	a0,8000085e <printf+0x9a>
        consputc(*s);
    8000092e:	00000097          	auipc	ra,0x0
    80000932:	af6080e7          	jalr	-1290(ra) # 80000424 <consputc>
      for(; *s; s++)
    80000936:	0485                	add	s1,s1,1
    80000938:	0004c503          	lbu	a0,0(s1)
    8000093c:	f96d                	bnez	a0,8000092e <printf+0x16a>
    8000093e:	b705                	j	8000085e <printf+0x9a>
        s = "(null)";
    80000940:	00002497          	auipc	s1,0x2
    80000944:	73048493          	add	s1,s1,1840 # 80003070 <etext+0x70>
      for(; *s; s++)
    80000948:	02800513          	li	a0,40
    8000094c:	b7cd                	j	8000092e <printf+0x16a>
      consputc('%');
    8000094e:	8556                	mv	a0,s5
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ad4080e7          	jalr	-1324(ra) # 80000424 <consputc>
      break;
    80000958:	b719                	j	8000085e <printf+0x9a>
      consputc('%');
    8000095a:	8556                	mv	a0,s5
    8000095c:	00000097          	auipc	ra,0x0
    80000960:	ac8080e7          	jalr	-1336(ra) # 80000424 <consputc>
      consputc(c);
    80000964:	8526                	mv	a0,s1
    80000966:	00000097          	auipc	ra,0x0
    8000096a:	abe080e7          	jalr	-1346(ra) # 80000424 <consputc>
      break;
    8000096e:	bdc5                	j	8000085e <printf+0x9a>
  if(locking)
    80000970:	020d9163          	bnez	s11,80000992 <printf+0x1ce>
}
    80000974:	70e6                	ld	ra,120(sp)
    80000976:	7446                	ld	s0,112(sp)
    80000978:	74a6                	ld	s1,104(sp)
    8000097a:	7906                	ld	s2,96(sp)
    8000097c:	69e6                	ld	s3,88(sp)
    8000097e:	6a46                	ld	s4,80(sp)
    80000980:	6aa6                	ld	s5,72(sp)
    80000982:	6b06                	ld	s6,64(sp)
    80000984:	7be2                	ld	s7,56(sp)
    80000986:	7c42                	ld	s8,48(sp)
    80000988:	7ca2                	ld	s9,40(sp)
    8000098a:	7d02                	ld	s10,32(sp)
    8000098c:	6de2                	ld	s11,24(sp)
    8000098e:	6129                	add	sp,sp,192
    80000990:	8082                	ret
    release(&pr.lock);
    80000992:	0000b517          	auipc	a0,0xb
    80000996:	dae50513          	add	a0,a0,-594 # 8000b740 <pr>
    8000099a:	00001097          	auipc	ra,0x1
    8000099e:	bea080e7          	jalr	-1046(ra) # 80001584 <release>
}
    800009a2:	bfc9                	j	80000974 <printf+0x1b0>

00000000800009a4 <printfinit>:
    ;
}

void
printfinit(void)
{
    800009a4:	1101                	add	sp,sp,-32
    800009a6:	ec06                	sd	ra,24(sp)
    800009a8:	e822                	sd	s0,16(sp)
    800009aa:	e426                	sd	s1,8(sp)
    800009ac:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    800009ae:	0000b497          	auipc	s1,0xb
    800009b2:	d9248493          	add	s1,s1,-622 # 8000b740 <pr>
    800009b6:	00002597          	auipc	a1,0x2
    800009ba:	6d258593          	add	a1,a1,1746 # 80003088 <etext+0x88>
    800009be:	8526                	mv	a0,s1
    800009c0:	00001097          	auipc	ra,0x1
    800009c4:	a80080e7          	jalr	-1408(ra) # 80001440 <initlock>
  pr.locking = 1;
    800009c8:	4785                	li	a5,1
    800009ca:	cc9c                	sw	a5,24(s1)
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	add	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(uint64 page, bool in_kernel)
{
    800009d6:	1101                	add	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)page % PGSIZE) != 0 || (char*)page < end || (uint64)page >= PHYSTOP) //检测合法性
    800009e2:	03451793          	sll	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	0000e797          	auipc	a5,0xe
    800009ee:	3ae78793          	add	a5,a5,942 # 8000ed98 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	sll	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset((char*)page, 1, PGSIZE); 
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	b30080e7          	jalr	-1232(ra) # 80000532 <memset>

  r = (struct run*)page;  

  acquire(&kmem.lock);
    80000a0a:	0000b917          	auipc	s2,0xb
    80000a0e:	d5690913          	add	s2,s2,-682 # 8000b760 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00001097          	auipc	ra,0x1
    80000a18:	abc080e7          	jalr	-1348(ra) # 800014d0 <acquire>
  r->next = kmem.freelist;  //头插
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00001097          	auipc	ra,0x1
    80000a2c:	b5c080e7          	jalr	-1188(ra) # 80001584 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	add	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00002517          	auipc	a0,0x2
    80000a40:	66c50513          	add	a0,a0,1644 # 800030a8 <digits+0x18>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	d36080e7          	jalr	-714(ra) # 8000077a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	add	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start); //可用内存初始地址对齐4KB
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	00e504b3          	add	s1,a0,a4
    80000a66:	777d                	lui	a4,0xfffff
    80000a68:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a6a:	94be                	add	s1,s1,a5
    80000a6c:	0095ef63          	bltu	a1,s1,80000a8a <freerange+0x3e>
    80000a70:	892e                	mv	s2,a1
    kfree((uint64)p,true);
    80000a72:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a74:	6985                	lui	s3,0x1
    kfree((uint64)p,true);
    80000a76:	4585                	li	a1,1
    80000a78:	01448533          	add	a0,s1,s4
    80000a7c:	00000097          	auipc	ra,0x0
    80000a80:	f5a080e7          	jalr	-166(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE) //全部可用内存逐个页初始化
    80000a84:	94ce                	add	s1,s1,s3
    80000a86:	fe9978e3          	bgeu	s2,s1,80000a76 <freerange+0x2a>
}
    80000a8a:	70a2                	ld	ra,40(sp)
    80000a8c:	7402                	ld	s0,32(sp)
    80000a8e:	64e2                	ld	s1,24(sp)
    80000a90:	6942                	ld	s2,16(sp)
    80000a92:	69a2                	ld	s3,8(sp)
    80000a94:	6a02                	ld	s4,0(sp)
    80000a96:	6145                	add	sp,sp,48
    80000a98:	8082                	ret

0000000080000a9a <kinit>:
{
    80000a9a:	1141                	add	sp,sp,-16
    80000a9c:	e406                	sd	ra,8(sp)
    80000a9e:	e022                	sd	s0,0(sp)
    80000aa0:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aa2:	00002597          	auipc	a1,0x2
    80000aa6:	60e58593          	add	a1,a1,1550 # 800030b0 <digits+0x20>
    80000aaa:	0000b517          	auipc	a0,0xb
    80000aae:	cb650513          	add	a0,a0,-842 # 8000b760 <kmem>
    80000ab2:	00001097          	auipc	ra,0x1
    80000ab6:	98e080e7          	jalr	-1650(ra) # 80001440 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aba:	45c5                	li	a1,17
    80000abc:	05ee                	sll	a1,a1,0x1b
    80000abe:	0000e517          	auipc	a0,0xe
    80000ac2:	2da50513          	add	a0,a0,730 # 8000ed98 <end>
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f86080e7          	jalr	-122(ra) # 80000a4c <freerange>
}
    80000ace:	60a2                	ld	ra,8(sp)
    80000ad0:	6402                	ld	s0,0(sp)
    80000ad2:	0141                	add	sp,sp,16
    80000ad4:	8082                	ret

0000000080000ad6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(bool in_kernel)
{
    80000ad6:	1101                	add	sp,sp,-32
    80000ad8:	ec06                	sd	ra,24(sp)
    80000ada:	e822                	sd	s0,16(sp)
    80000adc:	e426                	sd	s1,8(sp)
    80000ade:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);  
    80000ae0:	0000b497          	auipc	s1,0xb
    80000ae4:	c8048493          	add	s1,s1,-896 # 8000b760 <kmem>
    80000ae8:	8526                	mv	a0,s1
    80000aea:	00001097          	auipc	ra,0x1
    80000aee:	9e6080e7          	jalr	-1562(ra) # 800014d0 <acquire>
  r = kmem.freelist;  //从头部获取空闲页
    80000af2:	6c84                	ld	s1,24(s1)
  if(r)
    80000af4:	c885                	beqz	s1,80000b24 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af6:	609c                	ld	a5,0(s1)
    80000af8:	0000b517          	auipc	a0,0xb
    80000afc:	c6850513          	add	a0,a0,-920 # 8000b760 <kmem>
    80000b00:	ed1c                	sd	a5,24(a0)
  else 
    panic("kalloc: out of memory");
  release(&kmem.lock);
    80000b02:	00001097          	auipc	ra,0x1
    80000b06:	a82080e7          	jalr	-1406(ra) # 80001584 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b0a:	6605                	lui	a2,0x1
    80000b0c:	4595                	li	a1,5
    80000b0e:	8526                	mv	a0,s1
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	a22080e7          	jalr	-1502(ra) # 80000532 <memset>
  return (void*)r;
}
    80000b18:	8526                	mv	a0,s1
    80000b1a:	60e2                	ld	ra,24(sp)
    80000b1c:	6442                	ld	s0,16(sp)
    80000b1e:	64a2                	ld	s1,8(sp)
    80000b20:	6105                	add	sp,sp,32
    80000b22:	8082                	ret
    panic("kalloc: out of memory");
    80000b24:	00002517          	auipc	a0,0x2
    80000b28:	59450513          	add	a0,a0,1428 # 800030b8 <digits+0x28>
    80000b2c:	00000097          	auipc	ra,0x0
    80000b30:	c4e080e7          	jalr	-946(ra) # 8000077a <panic>

0000000080000b34 <uvmcreate>:
}

// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
    80000b34:	1101                	add	sp,sp,-32
    80000b36:	ec06                	sd	ra,24(sp)
    80000b38:	e822                	sd	s0,16(sp)
    80000b3a:	e426                	sd	s1,8(sp)
    80000b3c:	1000                	add	s0,sp,32
  pagetable_t pagetable = (pagetable_t)kalloc(true);
    80000b3e:	4505                	li	a0,1
    80000b40:	00000097          	auipc	ra,0x0
    80000b44:	f96080e7          	jalr	-106(ra) # 80000ad6 <kalloc>
    80000b48:	84aa                	mv	s1,a0
  if(pagetable)
    80000b4a:	c519                	beqz	a0,80000b58 <uvmcreate+0x24>
    memset(pagetable, 0, PGSIZE);
    80000b4c:	6605                	lui	a2,0x1
    80000b4e:	4581                	li	a1,0
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	9e2080e7          	jalr	-1566(ra) # 80000532 <memset>
  return pagetable;
}
    80000b58:	8526                	mv	a0,s1
    80000b5a:	60e2                	ld	ra,24(sp)
    80000b5c:	6442                	ld	s0,16(sp)
    80000b5e:	64a2                	ld	s1,8(sp)
    80000b60:	6105                	add	sp,sp,32
    80000b62:	8082                	ret

0000000080000b64 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000b64:	1141                	add	sp,sp,-16
    80000b66:	e422                	sd	s0,8(sp)
    80000b68:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000b6a:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000b6e:	00003797          	auipc	a5,0x3
    80000b72:	9627b783          	ld	a5,-1694(a5) # 800034d0 <kernel_pagetable>
    80000b76:	83b1                	srl	a5,a5,0xc
    80000b78:	577d                	li	a4,-1
    80000b7a:	177e                	sll	a4,a4,0x3f
    80000b7c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000b7e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000b82:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000b86:	6422                	ld	s0,8(sp)
    80000b88:	0141                	add	sp,sp,16
    80000b8a:	8082                	ret

0000000080000b8c <walk>:
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc) 
// 虚拟映射查询与建立
// 输入虚拟地址与对应的页表，返回该虚拟地址对应的最低级页表项地址
// alloc为0只查询，为1表示允许在遍历过程中为缺失的中间级页表分配一页。
{
    80000b8c:	7139                	add	sp,sp,-64
    80000b8e:	fc06                	sd	ra,56(sp)
    80000b90:	f822                	sd	s0,48(sp)
    80000b92:	f426                	sd	s1,40(sp)
    80000b94:	f04a                	sd	s2,32(sp)
    80000b96:	ec4e                	sd	s3,24(sp)
    80000b98:	e852                	sd	s4,16(sp)
    80000b9a:	e456                	sd	s5,8(sp)
    80000b9c:	e05a                	sd	s6,0(sp)
    80000b9e:	0080                	add	s0,sp,64
    80000ba0:	84aa                	mv	s1,a0
    80000ba2:	89ae                	mv	s3,a1
    80000ba4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ba6:	57fd                	li	a5,-1
    80000ba8:	83e9                	srl	a5,a5,0x1a
    80000baa:	4a79                	li	s4,30
    panic("walk");
  for(int level = 2; level > 0; level--) {
    80000bac:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000bae:	04b7f363          	bgeu	a5,a1,80000bf4 <walk+0x68>
    panic("walk");
    80000bb2:	00002517          	auipc	a0,0x2
    80000bb6:	51e50513          	add	a0,a0,1310 # 800030d0 <digits+0x40>
    80000bba:	00000097          	auipc	ra,0x0
    80000bbe:	bc0080e7          	jalr	-1088(ra) # 8000077a <panic>
    if(*pte & PTE_V) { // PTE有效
      //获取下一层页表页的地址，并以页表指针类型返回。
      //循环结束后得到的就是最底层的页表项的地址，内部存储了具体的数据。
      pagetable = (pagetable_t)PTE2PA(*pte); 
    } else {  // PTE无效，先判断是否可以写入
      if(!alloc || (pagetable = (pde_t*)kalloc(true)) == 0 /* 无空闲物理页 */)
    80000bc2:	060a8763          	beqz	s5,80000c30 <walk+0xa4>
    80000bc6:	4505                	li	a0,1
    80000bc8:	00000097          	auipc	ra,0x0
    80000bcc:	f0e080e7          	jalr	-242(ra) # 80000ad6 <kalloc>
    80000bd0:	84aa                	mv	s1,a0
    80000bd2:	c529                	beqz	a0,80000c1c <walk+0x90>
        return 0; // 失败返回0
      memset(pagetable, 0, PGSIZE); // 确定分配，清理一下对应内存
    80000bd4:	6605                	lui	a2,0x1
    80000bd6:	4581                	li	a1,0
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	95a080e7          	jalr	-1702(ra) # 80000532 <memset>
      *pte = PA2PTE(pagetable) | PTE_V; // 设置有效位
    80000be0:	00c4d793          	srl	a5,s1,0xc
    80000be4:	07aa                	sll	a5,a5,0xa
    80000be6:	0017e793          	or	a5,a5,1
    80000bea:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000bee:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fff025f>
    80000bf0:	036a0063          	beq	s4,s6,80000c10 <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)]; //获取索引对应的页表项（虚拟）地址
    80000bf4:	0149d933          	srl	s2,s3,s4
    80000bf8:	1ff97913          	and	s2,s2,511
    80000bfc:	090e                	sll	s2,s2,0x3
    80000bfe:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) { // PTE有效
    80000c00:	00093483          	ld	s1,0(s2)
    80000c04:	0014f793          	and	a5,s1,1
    80000c08:	dfcd                	beqz	a5,80000bc2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte); 
    80000c0a:	80a9                	srl	s1,s1,0xa
    80000c0c:	04b2                	sll	s1,s1,0xc
    80000c0e:	b7c5                	j	80000bee <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];  
    80000c10:	00c9d513          	srl	a0,s3,0xc
    80000c14:	1ff57513          	and	a0,a0,511
    80000c18:	050e                	sll	a0,a0,0x3
    80000c1a:	9526                	add	a0,a0,s1
}
    80000c1c:	70e2                	ld	ra,56(sp)
    80000c1e:	7442                	ld	s0,48(sp)
    80000c20:	74a2                	ld	s1,40(sp)
    80000c22:	7902                	ld	s2,32(sp)
    80000c24:	69e2                	ld	s3,24(sp)
    80000c26:	6a42                	ld	s4,16(sp)
    80000c28:	6aa2                	ld	s5,8(sp)
    80000c2a:	6b02                	ld	s6,0(sp)
    80000c2c:	6121                	add	sp,sp,64
    80000c2e:	8082                	ret
        return 0; // 失败返回0
    80000c30:	4501                	li	a0,0
    80000c32:	b7ed                	j	80000c1c <walk+0x90>

0000000080000c34 <mappages>:
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
// 建立映射
{
    80000c34:	715d                	add	sp,sp,-80
    80000c36:	e486                	sd	ra,72(sp)
    80000c38:	e0a2                	sd	s0,64(sp)
    80000c3a:	fc26                	sd	s1,56(sp)
    80000c3c:	f84a                	sd	s2,48(sp)
    80000c3e:	f44e                	sd	s3,40(sp)
    80000c40:	f052                	sd	s4,32(sp)
    80000c42:	ec56                	sd	s5,24(sp)
    80000c44:	e85a                	sd	s6,16(sp)
    80000c46:	e45e                	sd	s7,8(sp)
    80000c48:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80000c4a:	03459793          	sll	a5,a1,0x34
    80000c4e:	e7b9                	bnez	a5,80000c9c <mappages+0x68>
    80000c50:	8aaa                	mv	s5,a0
    80000c52:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80000c54:	03461793          	sll	a5,a2,0x34
    80000c58:	ebb1                	bnez	a5,80000cac <mappages+0x78>
    panic("mappages: size not aligned");

  if(size == 0)
    80000c5a:	c22d                	beqz	a2,80000cbc <mappages+0x88>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE; // VA和size都是页对齐的
    80000c5c:	77fd                	lui	a5,0xfffff
    80000c5e:	963e                	add	a2,a2,a5
    80000c60:	00b609b3          	add	s3,a2,a1
  a = va;
    80000c64:	892e                	mv	s2,a1
    80000c66:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V) // 重复映射
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    if(a == last)
      break;
    a += PGSIZE;
    80000c6a:	6b85                	lui	s7,0x1
    80000c6c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    80000c70:	4605                	li	a2,1
    80000c72:	85ca                	mv	a1,s2
    80000c74:	8556                	mv	a0,s5
    80000c76:	00000097          	auipc	ra,0x0
    80000c7a:	f16080e7          	jalr	-234(ra) # 80000b8c <walk>
    80000c7e:	cd39                	beqz	a0,80000cdc <mappages+0xa8>
    if(*pte & PTE_V) // 重复映射
    80000c80:	611c                	ld	a5,0(a0)
    80000c82:	8b85                	and	a5,a5,1
    80000c84:	e7a1                	bnez	a5,80000ccc <mappages+0x98>
    *pte = PA2PTE(pa) | perm | PTE_V; //更新页表项，表示这是叶子页表
    80000c86:	80b1                	srl	s1,s1,0xc
    80000c88:	04aa                	sll	s1,s1,0xa
    80000c8a:	0164e4b3          	or	s1,s1,s6
    80000c8e:	0014e493          	or	s1,s1,1
    80000c92:	e104                	sd	s1,0(a0)
    if(a == last)
    80000c94:	07390063          	beq	s2,s3,80000cf4 <mappages+0xc0>
    a += PGSIZE;
    80000c98:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0) // 失败
    80000c9a:	bfc9                	j	80000c6c <mappages+0x38>
    panic("mappages: va not aligned");
    80000c9c:	00002517          	auipc	a0,0x2
    80000ca0:	43c50513          	add	a0,a0,1084 # 800030d8 <digits+0x48>
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ad6080e7          	jalr	-1322(ra) # 8000077a <panic>
    panic("mappages: size not aligned");
    80000cac:	00002517          	auipc	a0,0x2
    80000cb0:	44c50513          	add	a0,a0,1100 # 800030f8 <digits+0x68>
    80000cb4:	00000097          	auipc	ra,0x0
    80000cb8:	ac6080e7          	jalr	-1338(ra) # 8000077a <panic>
    panic("mappages: size");
    80000cbc:	00002517          	auipc	a0,0x2
    80000cc0:	45c50513          	add	a0,a0,1116 # 80003118 <digits+0x88>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	ab6080e7          	jalr	-1354(ra) # 8000077a <panic>
      panic("mappages: remap");
    80000ccc:	00002517          	auipc	a0,0x2
    80000cd0:	45c50513          	add	a0,a0,1116 # 80003128 <digits+0x98>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	aa6080e7          	jalr	-1370(ra) # 8000077a <panic>
      return -1;
    80000cdc:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80000cde:	60a6                	ld	ra,72(sp)
    80000ce0:	6406                	ld	s0,64(sp)
    80000ce2:	74e2                	ld	s1,56(sp)
    80000ce4:	7942                	ld	s2,48(sp)
    80000ce6:	79a2                	ld	s3,40(sp)
    80000ce8:	7a02                	ld	s4,32(sp)
    80000cea:	6ae2                	ld	s5,24(sp)
    80000cec:	6b42                	ld	s6,16(sp)
    80000cee:	6ba2                	ld	s7,8(sp)
    80000cf0:	6161                	add	sp,sp,80
    80000cf2:	8082                	ret
  return 0;
    80000cf4:	4501                	li	a0,0
    80000cf6:	b7e5                	j	80000cde <mappages+0xaa>

0000000080000cf8 <kvmmap>:
{
    80000cf8:	1141                	add	sp,sp,-16
    80000cfa:	e406                	sd	ra,8(sp)
    80000cfc:	e022                	sd	s0,0(sp)
    80000cfe:	0800                	add	s0,sp,16
    80000d00:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80000d02:	86b2                	mv	a3,a2
    80000d04:	863e                	mv	a2,a5
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	f2e080e7          	jalr	-210(ra) # 80000c34 <mappages>
    80000d0e:	e509                	bnez	a0,80000d18 <kvmmap+0x20>
}
    80000d10:	60a2                	ld	ra,8(sp)
    80000d12:	6402                	ld	s0,0(sp)
    80000d14:	0141                	add	sp,sp,16
    80000d16:	8082                	ret
    panic("kvmmap");
    80000d18:	00002517          	auipc	a0,0x2
    80000d1c:	42050513          	add	a0,a0,1056 # 80003138 <digits+0xa8>
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	a5a080e7          	jalr	-1446(ra) # 8000077a <panic>

0000000080000d28 <kvmmake>:
{
    80000d28:	1101                	add	sp,sp,-32
    80000d2a:	ec06                	sd	ra,24(sp)
    80000d2c:	e822                	sd	s0,16(sp)
    80000d2e:	e426                	sd	s1,8(sp)
    80000d30:	e04a                	sd	s2,0(sp)
    80000d32:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc(true);
    80000d34:	4505                	li	a0,1
    80000d36:	00000097          	auipc	ra,0x0
    80000d3a:	da0080e7          	jalr	-608(ra) # 80000ad6 <kalloc>
    80000d3e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE); //关键清零
    80000d40:	6605                	lui	a2,0x1
    80000d42:	4581                	li	a1,0
    80000d44:	fffff097          	auipc	ra,0xfffff
    80000d48:	7ee080e7          	jalr	2030(ra) # 80000532 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80000d4c:	4719                	li	a4,6
    80000d4e:	6685                	lui	a3,0x1
    80000d50:	10000637          	lui	a2,0x10000
    80000d54:	100005b7          	lui	a1,0x10000
    80000d58:	8526                	mv	a0,s1
    80000d5a:	00000097          	auipc	ra,0x0
    80000d5e:	f9e080e7          	jalr	-98(ra) # 80000cf8 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80000d62:	4719                	li	a4,6
    80000d64:	6685                	lui	a3,0x1
    80000d66:	10001637          	lui	a2,0x10001
    80000d6a:	100015b7          	lui	a1,0x10001
    80000d6e:	8526                	mv	a0,s1
    80000d70:	00000097          	auipc	ra,0x0
    80000d74:	f88080e7          	jalr	-120(ra) # 80000cf8 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80000d78:	4719                	li	a4,6
    80000d7a:	004006b7          	lui	a3,0x400
    80000d7e:	0c000637          	lui	a2,0xc000
    80000d82:	0c0005b7          	lui	a1,0xc000
    80000d86:	8526                	mv	a0,s1
    80000d88:	00000097          	auipc	ra,0x0
    80000d8c:	f70080e7          	jalr	-144(ra) # 80000cf8 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    80000d90:	00002917          	auipc	s2,0x2
    80000d94:	27090913          	add	s2,s2,624 # 80003000 <etext>
    80000d98:	4729                	li	a4,10
    80000d9a:	80002697          	auipc	a3,0x80002
    80000d9e:	26668693          	add	a3,a3,614 # 3000 <_entry-0x7fffd000>
    80000da2:	4605                	li	a2,1
    80000da4:	067e                	sll	a2,a2,0x1f
    80000da6:	85b2                	mv	a1,a2
    80000da8:	8526                	mv	a0,s1
    80000daa:	00000097          	auipc	ra,0x0
    80000dae:	f4e080e7          	jalr	-178(ra) # 80000cf8 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    80000db2:	4719                	li	a4,6
    80000db4:	46c5                	li	a3,17
    80000db6:	06ee                	sll	a3,a3,0x1b
    80000db8:	412686b3          	sub	a3,a3,s2
    80000dbc:	864a                	mv	a2,s2
    80000dbe:	85ca                	mv	a1,s2
    80000dc0:	8526                	mv	a0,s1
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f36080e7          	jalr	-202(ra) # 80000cf8 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80000dca:	4729                	li	a4,10
    80000dcc:	6685                	lui	a3,0x1
    80000dce:	00001617          	auipc	a2,0x1
    80000dd2:	23260613          	add	a2,a2,562 # 80002000 <_trampoline>
    80000dd6:	040005b7          	lui	a1,0x4000
    80000dda:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80000ddc:	05b2                	sll	a1,a1,0xc
    80000dde:	8526                	mv	a0,s1
    80000de0:	00000097          	auipc	ra,0x0
    80000de4:	f18080e7          	jalr	-232(ra) # 80000cf8 <kvmmap>
  proc_mapstacks(kpgtbl);//TODO
    80000de8:	8526                	mv	a0,s1
    80000dea:	00000097          	auipc	ra,0x0
    80000dee:	2fe080e7          	jalr	766(ra) # 800010e8 <proc_mapstacks>
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
    80000e0c:	f20080e7          	jalr	-224(ra) # 80000d28 <kvmmake>
    80000e10:	00002797          	auipc	a5,0x2
    80000e14:	6ca7b023          	sd	a0,1728(a5) # 800034d0 <kernel_pagetable>
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
    80000e46:	306c0c13          	add	s8,s8,774 # 80003148 <digits+0xb8>

      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
    80000e4a:	00002d17          	auipc	s10,0x2
    80000e4e:	316d0d13          	add	s10,s10,790 # 80003160 <digits+0xd0>
      for(int j = 0; j < level; j++)
    80000e52:	4c81                	li	s9,0
        printf("  ");
    80000e54:	00002b17          	auipc	s6,0x2
    80000e58:	2ecb0b13          	add	s6,s6,748 # 80003140 <digits+0xb0>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000e5c:	20000b93          	li	s7,512
    80000e60:	a025                	j	80000e88 <print_pgtbl+0x68>
      } 
      else {
        printf("\n");
    80000e62:	00002517          	auipc	a0,0x2
    80000e66:	1ce50513          	add	a0,a0,462 # 80003030 <etext+0x30>
    80000e6a:	00000097          	auipc	ra,0x0
    80000e6e:	95a080e7          	jalr	-1702(ra) # 800007c4 <printf>
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
    80000e9e:	92a080e7          	jalr	-1750(ra) # 800007c4 <printf>
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
    80000eba:	90e080e7          	jalr	-1778(ra) # 800007c4 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000ebe:	00e97913          	and	s2,s2,14
    80000ec2:	fa0900e3          	beqz	s2,80000e62 <print_pgtbl+0x42>
        printf(" [leaf]\n");
    80000ec6:	856a                	mv	a0,s10
    80000ec8:	00000097          	auipc	ra,0x0
    80000ecc:	8fc080e7          	jalr	-1796(ra) # 800007c4 <printf>
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
    80000f0c:	26850513          	add	a0,a0,616 # 80003170 <digits+0xe0>
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	8b4080e7          	jalr	-1868(ra) # 800007c4 <printf>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f18:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {// 打印有效的页表项

      printf("offset %d, pte %p, pa %p", i, pte, PTE2PA(pte));
    80000f1a:	00002a97          	auipc	s5,0x2
    80000f1e:	266a8a93          	add	s5,s5,614 # 80003180 <digits+0xf0>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
        // 叶子节点
        printf(" [leaf]\n");
      } 
      else {
        printf("\n");
    80000f22:	00002b97          	auipc	s7,0x2
    80000f26:	10eb8b93          	add	s7,s7,270 # 80003030 <etext+0x30>
        printf(" [leaf]\n");
    80000f2a:	00002b17          	auipc	s6,0x2
    80000f2e:	236b0b13          	add	s6,s6,566 # 80003160 <digits+0xd0>
  for(int i = 0; i < 512; i++) { // 512个页表项
    80000f32:	20000a13          	li	s4,512
    80000f36:	a811                	j	80000f4a <print_cur_pgtbl+0x5c>
        printf("\n");
    80000f38:	855e                	mv	a0,s7
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	88a080e7          	jalr	-1910(ra) # 800007c4 <printf>
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
    80000f64:	864080e7          	jalr	-1948(ra) # 800007c4 <printf>
      if(pte & (PTE_R | PTE_W | PTE_X)) {
    80000f68:	88b9                	and	s1,s1,14
    80000f6a:	d4f9                	beqz	s1,80000f38 <print_cur_pgtbl+0x4a>
        printf(" [leaf]\n");
    80000f6c:	855a                	mv	a0,s6
    80000f6e:	00000097          	auipc	ra,0x0
    80000f72:	856080e7          	jalr	-1962(ra) # 800007c4 <printf>
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
    80000fb0:	b2a080e7          	jalr	-1238(ra) # 80000ad6 <kalloc>
    80000fb4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80000fb6:	6605                	lui	a2,0x1
    80000fb8:	4581                	li	a1,0
    80000fba:	fffff097          	auipc	ra,0xfffff
    80000fbe:	578080e7          	jalr	1400(ra) # 80000532 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80000fc2:	4779                	li	a4,30
    80000fc4:	86ca                	mv	a3,s2
    80000fc6:	6605                	lui	a2,0x1
    80000fc8:	4581                	li	a1,0
    80000fca:	8552                	mv	a0,s4
    80000fcc:	00000097          	auipc	ra,0x0
    80000fd0:	c68080e7          	jalr	-920(ra) # 80000c34 <mappages>
  memmove(mem, src, sz);
    80000fd4:	8626                	mv	a2,s1
    80000fd6:	85ce                	mv	a1,s3
    80000fd8:	854a                	mv	a0,s2
    80000fda:	fffff097          	auipc	ra,0xfffff
    80000fde:	5b4080e7          	jalr	1460(ra) # 8000058e <memmove>
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
    80000ff6:	1ae50513          	add	a0,a0,430 # 800031a0 <digits+0x110>
    80000ffa:	fffff097          	auipc	ra,0xfffff
    80000ffe:	780080e7          	jalr	1920(ra) # 8000077a <panic>

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
    80001022:	76250513          	add	a0,a0,1890 # 8000b780 <cpus>
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
    8000103c:	44c080e7          	jalr	1100(ra) # 80001484 <push_off>
    80001040:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001042:	2781                	sext.w	a5,a5
    80001044:	079e                	sll	a5,a5,0x7
    80001046:	0000a717          	auipc	a4,0xa
    8000104a:	73a70713          	add	a4,a4,1850 # 8000b780 <cpus>
    8000104e:	97ba                	add	a5,a5,a4
    80001050:	6784                	ld	s1,8(a5)
  pop_off();
    80001052:	00000097          	auipc	ra,0x0
    80001056:	4d2080e7          	jalr	1234(ra) # 80001524 <pop_off>
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
    80001076:	b0e90913          	add	s2,s2,-1266 # 8000bb80 <pid_lock>
    8000107a:	854a                	mv	a0,s2
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	454080e7          	jalr	1108(ra) # 800014d0 <acquire>
  pid = nextpid;
    80001084:	00002797          	auipc	a5,0x2
    80001088:	3fc78793          	add	a5,a5,1020 # 80003480 <nextpid>
    8000108c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    8000108e:	0014871b          	addw	a4,s1,1
    80001092:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001094:	854a                	mv	a0,s2
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	4ee080e7          	jalr	1262(ra) # 80001584 <release>

  return pid;
    8000109e:	8526                	mv	a0,s1
    800010a0:	60e2                	ld	ra,24(sp)
    800010a2:	6442                	ld	s0,16(sp)
    800010a4:	64a2                	ld	s1,8(sp)
    800010a6:	6902                	ld	s2,0(sp)
    800010a8:	6105                	add	sp,sp,32
    800010aa:	8082                	ret

00000000800010ac <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800010ac:	1141                	add	sp,sp,-16
    800010ae:	e406                	sd	ra,8(sp)
    800010b0:	e022                	sd	s0,0(sp)
    800010b2:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f7a080e7          	jalr	-134(ra) # 8000102e <myproc>
    800010bc:	0521                	add	a0,a0,8
    800010be:	00000097          	auipc	ra,0x0
    800010c2:	4c6080e7          	jalr	1222(ra) # 80001584 <release>

  if (first) {
    800010c6:	00002797          	auipc	a5,0x2
    800010ca:	3be7a783          	lw	a5,958(a5) # 80003484 <first.0>
    800010ce:	c789                	beqz	a5,800010d8 <forkret+0x2c>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    800010d0:	00002797          	auipc	a5,0x2
    800010d4:	3a07aa23          	sw	zero,948(a5) # 80003484 <first.0>
    // fsinit(ROOTDEV); //初始化文件系统
  }

  trap_user_return();
    800010d8:	00001097          	auipc	ra,0x1
    800010dc:	81e080e7          	jalr	-2018(ra) # 800018f6 <trap_user_return>
}
    800010e0:	60a2                	ld	ra,8(sp)
    800010e2:	6402                	ld	s0,0(sp)
    800010e4:	0141                	add	sp,sp,16
    800010e6:	8082                	ret

00000000800010e8 <proc_mapstacks>:
{
    800010e8:	7139                	add	sp,sp,-64
    800010ea:	fc06                	sd	ra,56(sp)
    800010ec:	f822                	sd	s0,48(sp)
    800010ee:	f426                	sd	s1,40(sp)
    800010f0:	f04a                	sd	s2,32(sp)
    800010f2:	ec4e                	sd	s3,24(sp)
    800010f4:	e852                	sd	s4,16(sp)
    800010f6:	e456                	sd	s5,8(sp)
    800010f8:	e05a                	sd	s6,0(sp)
    800010fa:	0080                	add	s0,sp,64
    800010fc:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800010fe:	0000b497          	auipc	s1,0xb
    80001102:	a9a48493          	add	s1,s1,-1382 # 8000bb98 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80001106:	8b26                	mv	s6,s1
    80001108:	00002a97          	auipc	s5,0x2
    8000110c:	ef8a8a93          	add	s5,s5,-264 # 80003000 <etext>
    80001110:	04000937          	lui	s2,0x4000
    80001114:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001116:	0932                	sll	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001118:	0000ea17          	auipc	s4,0xe
    8000111c:	c80a0a13          	add	s4,s4,-896 # 8000ed98 <end>
    char *pa = kalloc(1);
    80001120:	4505                	li	a0,1
    80001122:	00000097          	auipc	ra,0x0
    80001126:	9b4080e7          	jalr	-1612(ra) # 80000ad6 <kalloc>
    8000112a:	862a                	mv	a2,a0
    if(pa == 0)
    8000112c:	c131                	beqz	a0,80001170 <proc_mapstacks+0x88>
    uint64 va = KSTACK((int) (p - proc));
    8000112e:	416485b3          	sub	a1,s1,s6
    80001132:	858d                	sra	a1,a1,0x3
    80001134:	000ab783          	ld	a5,0(s5)
    80001138:	02f585b3          	mul	a1,a1,a5
    8000113c:	2585                	addw	a1,a1,1
    8000113e:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001142:	4719                	li	a4,6
    80001144:	6685                	lui	a3,0x1
    80001146:	40b905b3          	sub	a1,s2,a1
    8000114a:	854e                	mv	a0,s3
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	bac080e7          	jalr	-1108(ra) # 80000cf8 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001154:	0c848493          	add	s1,s1,200
    80001158:	fd4494e3          	bne	s1,s4,80001120 <proc_mapstacks+0x38>
}
    8000115c:	70e2                	ld	ra,56(sp)
    8000115e:	7442                	ld	s0,48(sp)
    80001160:	74a2                	ld	s1,40(sp)
    80001162:	7902                	ld	s2,32(sp)
    80001164:	69e2                	ld	s3,24(sp)
    80001166:	6a42                	ld	s4,16(sp)
    80001168:	6aa2                	ld	s5,8(sp)
    8000116a:	6b02                	ld	s6,0(sp)
    8000116c:	6121                	add	sp,sp,64
    8000116e:	8082                	ret
      panic("kalloc");
    80001170:	00002517          	auipc	a0,0x2
    80001174:	05050513          	add	a0,a0,80 # 800031c0 <digits+0x130>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	602080e7          	jalr	1538(ra) # 8000077a <panic>

0000000080001180 <procinit>:
{
    80001180:	7139                	add	sp,sp,-64
    80001182:	fc06                	sd	ra,56(sp)
    80001184:	f822                	sd	s0,48(sp)
    80001186:	f426                	sd	s1,40(sp)
    80001188:	f04a                	sd	s2,32(sp)
    8000118a:	ec4e                	sd	s3,24(sp)
    8000118c:	e852                	sd	s4,16(sp)
    8000118e:	e456                	sd	s5,8(sp)
    80001190:	e05a                	sd	s6,0(sp)
    80001192:	0080                	add	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001194:	00002597          	auipc	a1,0x2
    80001198:	03458593          	add	a1,a1,52 # 800031c8 <digits+0x138>
    8000119c:	0000b517          	auipc	a0,0xb
    800011a0:	9e450513          	add	a0,a0,-1564 # 8000bb80 <pid_lock>
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	29c080e7          	jalr	668(ra) # 80001440 <initlock>
    for(p = proc; p < &proc[NPROC]; p++) {
    800011ac:	0000b497          	auipc	s1,0xb
    800011b0:	9ec48493          	add	s1,s1,-1556 # 8000bb98 <proc>
      initlock(&p->lock, "proc");
    800011b4:	00002b17          	auipc	s6,0x2
    800011b8:	01cb0b13          	add	s6,s6,28 # 800031d0 <digits+0x140>
      p->kstack = KSTACK((int) (p - proc));
    800011bc:	8aa6                	mv	s5,s1
    800011be:	00002a17          	auipc	s4,0x2
    800011c2:	e42a0a13          	add	s4,s4,-446 # 80003000 <etext>
    800011c6:	04000937          	lui	s2,0x4000
    800011ca:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800011cc:	0932                	sll	s2,s2,0xc
    for(p = proc; p < &proc[NPROC]; p++) {
    800011ce:	0000e997          	auipc	s3,0xe
    800011d2:	bca98993          	add	s3,s3,-1078 # 8000ed98 <end>
      initlock(&p->lock, "proc");
    800011d6:	85da                	mv	a1,s6
    800011d8:	00848513          	add	a0,s1,8
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	264080e7          	jalr	612(ra) # 80001440 <initlock>
      p->state = UNUSED;
    800011e4:	0204a023          	sw	zero,32(s1)
      p->kstack = KSTACK((int) (p - proc));
    800011e8:	415487b3          	sub	a5,s1,s5
    800011ec:	878d                	sra	a5,a5,0x3
    800011ee:	000a3703          	ld	a4,0(s4)
    800011f2:	02e787b3          	mul	a5,a5,a4
    800011f6:	2785                	addw	a5,a5,1
    800011f8:	00d7979b          	sllw	a5,a5,0xd
    800011fc:	40f907b3          	sub	a5,s2,a5
    80001200:	e8bc                	sd	a5,80(s1)
    for(p = proc; p < &proc[NPROC]; p++) {
    80001202:	0c848493          	add	s1,s1,200
    80001206:	fd3498e3          	bne	s1,s3,800011d6 <procinit+0x56>
}
    8000120a:	70e2                	ld	ra,56(sp)
    8000120c:	7442                	ld	s0,48(sp)
    8000120e:	74a2                	ld	s1,40(sp)
    80001210:	7902                	ld	s2,32(sp)
    80001212:	69e2                	ld	s3,24(sp)
    80001214:	6a42                	ld	s4,16(sp)
    80001216:	6aa2                	ld	s5,8(sp)
    80001218:	6b02                	ld	s6,0(sp)
    8000121a:	6121                	add	sp,sp,64
    8000121c:	8082                	ret

000000008000121e <proc_freepagetable>:

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    8000121e:	1141                	add	sp,sp,-16
    80001220:	e422                	sd	s0,8(sp)
    80001222:	0800                	add	s0,sp,16
  // uvmunmap(pagetable, TRAMPOLINE, 1, 0); //TODO
  // uvmunmap(pagetable, TRAPFRAME, 1, 0);
  // uvmfree(pagetable, sz);
}
    80001224:	6422                	ld	s0,8(sp)
    80001226:	0141                	add	sp,sp,16
    80001228:	8082                	ret

000000008000122a <freeproc>:

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
void freeproc(struct proc *p)
{
    8000122a:	1101                	add	sp,sp,-32
    8000122c:	ec06                	sd	ra,24(sp)
    8000122e:	e822                	sd	s0,16(sp)
    80001230:	e426                	sd	s1,8(sp)
    80001232:	1000                	add	s0,sp,32
    80001234:	84aa                	mv	s1,a0
  if(p->tf)
    80001236:	6128                	ld	a0,64(a0)
    80001238:	c511                	beqz	a0,80001244 <freeproc+0x1a>
    kfree((uint64)p->tf,1);
    8000123a:	4585                	li	a1,1
    8000123c:	fffff097          	auipc	ra,0xfffff
    80001240:	79a080e7          	jalr	1946(ra) # 800009d6 <kfree>
  p->tf = 0;
    80001244:	0404b023          	sd	zero,64(s1)
  if(p->pgtbl)
    proc_freepagetable(p->pgtbl, p->sz);
  if(p->kstack)
    80001248:	68a8                	ld	a0,80(s1)
    8000124a:	e105                	bnez	a0,8000126a <freeproc+0x40>
    kfree((uint64)p->kstack,1); 
  p->kstack = 0;
    8000124c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001250:	0404b423          	sd	zero,72(s1)
  p->pgtbl = 0;
    80001254:	0204b423          	sd	zero,40(s1)
  p->pid = 0;
    80001258:	0004a023          	sw	zero,0(s1)
  p->state = UNUSED;
    8000125c:	0204a023          	sw	zero,32(s1)
}
    80001260:	60e2                	ld	ra,24(sp)
    80001262:	6442                	ld	s0,16(sp)
    80001264:	64a2                	ld	s1,8(sp)
    80001266:	6105                	add	sp,sp,32
    80001268:	8082                	ret
    kfree((uint64)p->kstack,1); 
    8000126a:	4585                	li	a1,1
    8000126c:	fffff097          	auipc	ra,0xfffff
    80001270:	76a080e7          	jalr	1898(ra) # 800009d6 <kfree>
    80001274:	bfe1                	j	8000124c <freeproc+0x22>

0000000080001276 <proc_pgtbl_init>:

// 获得一个初始化过的用户页表
// 完成了trapframe 和 trampoline 的映射
pgtbl_t proc_pgtbl_init(uint64 trapframe_pa)
{
    80001276:	1101                	add	sp,sp,-32
    80001278:	ec06                	sd	ra,24(sp)
    8000127a:	e822                	sd	s0,16(sp)
    8000127c:	e426                	sd	s1,8(sp)
    8000127e:	e04a                	sd	s2,0(sp)
    80001280:	1000                	add	s0,sp,32
    80001282:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    80001284:	00000097          	auipc	ra,0x0
    80001288:	8b0080e7          	jalr	-1872(ra) # 80000b34 <uvmcreate>
    8000128c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000128e:	cd1d                	beqz	a0,800012cc <proc_pgtbl_init+0x56>
    return 0;

  
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001290:	4729                	li	a4,10
    80001292:	00001697          	auipc	a3,0x1
    80001296:	d6e68693          	add	a3,a3,-658 # 80002000 <_trampoline>
    8000129a:	6605                	lui	a2,0x1
    8000129c:	040005b7          	lui	a1,0x4000
    800012a0:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012a2:	05b2                	sll	a1,a1,0xc
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	990080e7          	jalr	-1648(ra) # 80000c34 <mappages>
    800012ac:	02054763          	bltz	a0,800012da <proc_pgtbl_init+0x64>
              (uint64)(trampoline), PTE_R | PTE_X) < 0){
    panic("proc_pgtbl_init: mappages trampoline failed");
    return 0;
  }

  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800012b0:	4719                	li	a4,6
    800012b2:	86ca                	mv	a3,s2
    800012b4:	6605                	lui	a2,0x1
    800012b6:	020005b7          	lui	a1,0x2000
    800012ba:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800012bc:	05b6                	sll	a1,a1,0xd
    800012be:	8526                	mv	a0,s1
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	974080e7          	jalr	-1676(ra) # 80000c34 <mappages>
    800012c8:	02054163          	bltz	a0,800012ea <proc_pgtbl_init+0x74>
    panic("proc_pgtbl_init: mappages trapframe failed");
    return 0;
  }

  return pagetable;
}
    800012cc:	8526                	mv	a0,s1
    800012ce:	60e2                	ld	ra,24(sp)
    800012d0:	6442                	ld	s0,16(sp)
    800012d2:	64a2                	ld	s1,8(sp)
    800012d4:	6902                	ld	s2,0(sp)
    800012d6:	6105                	add	sp,sp,32
    800012d8:	8082                	ret
    panic("proc_pgtbl_init: mappages trampoline failed");
    800012da:	00002517          	auipc	a0,0x2
    800012de:	efe50513          	add	a0,a0,-258 # 800031d8 <digits+0x148>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	498080e7          	jalr	1176(ra) # 8000077a <panic>
    panic("proc_pgtbl_init: mappages trapframe failed");
    800012ea:	00002517          	auipc	a0,0x2
    800012ee:	f1e50513          	add	a0,a0,-226 # 80003208 <digits+0x178>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	488080e7          	jalr	1160(ra) # 8000077a <panic>

00000000800012fa <allocproc>:
{
    800012fa:	7179                	add	sp,sp,-48
    800012fc:	f406                	sd	ra,40(sp)
    800012fe:	f022                	sd	s0,32(sp)
    80001300:	ec26                	sd	s1,24(sp)
    80001302:	e84a                	sd	s2,16(sp)
    80001304:	e44e                	sd	s3,8(sp)
    80001306:	1800                	add	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001308:	0000b497          	auipc	s1,0xb
    8000130c:	89048493          	add	s1,s1,-1904 # 8000bb98 <proc>
    80001310:	0000e997          	auipc	s3,0xe
    80001314:	a8898993          	add	s3,s3,-1400 # 8000ed98 <end>
    acquire(&p->lock);
    80001318:	00848913          	add	s2,s1,8
    8000131c:	854a                	mv	a0,s2
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	1b2080e7          	jalr	434(ra) # 800014d0 <acquire>
    if(p->state == UNUSED) {
    80001326:	509c                	lw	a5,32(s1)
    80001328:	cf81                	beqz	a5,80001340 <allocproc+0x46>
      release(&p->lock);
    8000132a:	854a                	mv	a0,s2
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	258080e7          	jalr	600(ra) # 80001584 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001334:	0c848493          	add	s1,s1,200
    80001338:	ff3490e3          	bne	s1,s3,80001318 <allocproc+0x1e>
  return 0;
    8000133c:	4481                	li	s1,0
    8000133e:	a889                	j	80001390 <allocproc+0x96>
  p->pid = allocpid();
    80001340:	00000097          	auipc	ra,0x0
    80001344:	d26080e7          	jalr	-730(ra) # 80001066 <allocpid>
    80001348:	c088                	sw	a0,0(s1)
  p->state = USED;
    8000134a:	4785                	li	a5,1
    8000134c:	d09c                	sw	a5,32(s1)
  if((p->tf = (struct trapframe *)kalloc(1)) == 0){
    8000134e:	4505                	li	a0,1
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	786080e7          	jalr	1926(ra) # 80000ad6 <kalloc>
    80001358:	89aa                	mv	s3,a0
    8000135a:	e0a8                	sd	a0,64(s1)
    8000135c:	c131                	beqz	a0,800013a0 <allocproc+0xa6>
  p->pgtbl = proc_pgtbl_init((uint64)(p->tf));
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	f18080e7          	jalr	-232(ra) # 80001276 <proc_pgtbl_init>
    80001366:	89aa                	mv	s3,a0
    80001368:	f488                	sd	a0,40(s1)
  if(p->pgtbl == 0){
    8000136a:	cd39                	beqz	a0,800013c8 <allocproc+0xce>
  memset(&p->ctx, 0, sizeof(p->ctx));
    8000136c:	07000613          	li	a2,112
    80001370:	4581                	li	a1,0
    80001372:	05848513          	add	a0,s1,88
    80001376:	fffff097          	auipc	ra,0xfffff
    8000137a:	1bc080e7          	jalr	444(ra) # 80000532 <memset>
  p->ctx.ra = (uint64)forkret;
    8000137e:	00000797          	auipc	a5,0x0
    80001382:	d2e78793          	add	a5,a5,-722 # 800010ac <forkret>
    80001386:	ecbc                	sd	a5,88(s1)
  p->ctx.sp = p->kstack+PGSIZE;
    80001388:	68bc                	ld	a5,80(s1)
    8000138a:	6705                	lui	a4,0x1
    8000138c:	97ba                	add	a5,a5,a4
    8000138e:	f0bc                	sd	a5,96(s1)
}
    80001390:	8526                	mv	a0,s1
    80001392:	70a2                	ld	ra,40(sp)
    80001394:	7402                	ld	s0,32(sp)
    80001396:	64e2                	ld	s1,24(sp)
    80001398:	6942                	ld	s2,16(sp)
    8000139a:	69a2                	ld	s3,8(sp)
    8000139c:	6145                	add	sp,sp,48
    8000139e:	8082                	ret
    freeproc(p);
    800013a0:	8526                	mv	a0,s1
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	e88080e7          	jalr	-376(ra) # 8000122a <freeproc>
    printf("allocproc: kalloc trapframe failed\n");
    800013aa:	00002517          	auipc	a0,0x2
    800013ae:	e8e50513          	add	a0,a0,-370 # 80003238 <digits+0x1a8>
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	412080e7          	jalr	1042(ra) # 800007c4 <printf>
    release(&p->lock);
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	1c8080e7          	jalr	456(ra) # 80001584 <release>
    return 0;
    800013c4:	84ce                	mv	s1,s3
    800013c6:	b7e9                	j	80001390 <allocproc+0x96>
    freeproc(p);
    800013c8:	8526                	mv	a0,s1
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	e60080e7          	jalr	-416(ra) # 8000122a <freeproc>
    printf("allocproc: proc_pgtbl_init failed\n");
    800013d2:	00002517          	auipc	a0,0x2
    800013d6:	e8e50513          	add	a0,a0,-370 # 80003260 <digits+0x1d0>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	3ea080e7          	jalr	1002(ra) # 800007c4 <printf>
    release(&p->lock);
    800013e2:	854a                	mv	a0,s2
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	1a0080e7          	jalr	416(ra) # 80001584 <release>
    return 0;
    800013ec:	84ce                	mv	s1,s3
    800013ee:	b74d                	j	80001390 <allocproc+0x96>

00000000800013f0 <userinit>:
//__attribute__ ((aligned (16))) char proc0stack[8192];

// Set up first user process.
void
userinit(void)
{
    800013f0:	1101                	add	sp,sp,-32
    800013f2:	ec06                	sd	ra,24(sp)
    800013f4:	e822                	sd	s0,16(sp)
    800013f6:	e426                	sd	s1,8(sp)
    800013f8:	1000                	add	s0,sp,32
  struct proc *p;

  p = allocproc();
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	f00080e7          	jalr	-256(ra) # 800012fa <allocproc>
    80001402:	84aa                	mv	s1,a0
  proczero = p;
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pgtbl, initcode, sizeof(initcode));
    80001404:	4671                	li	a2,28
    80001406:	00002597          	auipc	a1,0x2
    8000140a:	08a58593          	add	a1,a1,138 # 80003490 <initcode>
    8000140e:	7508                	ld	a0,40(a0)
    80001410:	00000097          	auipc	ra,0x0
    80001414:	b7e080e7          	jalr	-1154(ra) # 80000f8e <uvmfirst>
  p->sz = PGSIZE;
    80001418:	6785                	lui	a5,0x1
    8000141a:	e4bc                	sd	a5,72(s1)

  // prepare for the very first "return" from kernel to user.
  p->tf->epc = 0;      // user program counter
    8000141c:	60b8                	ld	a4,64(s1)
    8000141e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001422:	60b8                	ld	a4,64(s1)
    80001424:	fb1c                	sd	a5,48(a4)

  // safestrcpy(p->name, "initcode", sizeof(p->name));
  //p->cwd = namei("/");

  p->state = RUNNABLE;
    80001426:	478d                	li	a5,3
    80001428:	d09c                	sw	a5,32(s1)

  release(&p->lock);
    8000142a:	00848513          	add	a0,s1,8
    8000142e:	00000097          	auipc	ra,0x0
    80001432:	156080e7          	jalr	342(ra) # 80001584 <release>
}
    80001436:	60e2                	ld	ra,24(sp)
    80001438:	6442                	ld	s0,16(sp)
    8000143a:	64a2                	ld	s1,8(sp)
    8000143c:	6105                	add	sp,sp,32
    8000143e:	8082                	ret

0000000080001440 <initlock>:
#include "proc-h/cpu.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80001440:	1141                	add	sp,sp,-16
    80001442:	e422                	sd	s0,8(sp)
    80001444:	0800                	add	s0,sp,16
  lk->name = name;
    80001446:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80001448:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    8000144c:	00053823          	sd	zero,16(a0)
}
    80001450:	6422                	ld	s0,8(sp)
    80001452:	0141                	add	sp,sp,16
    80001454:	8082                	ret

0000000080001456 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80001456:	411c                	lw	a5,0(a0)
    80001458:	e399                	bnez	a5,8000145e <holding+0x8>
    8000145a:	4501                	li	a0,0
  return r;
}
    8000145c:	8082                	ret
{
    8000145e:	1101                	add	sp,sp,-32
    80001460:	ec06                	sd	ra,24(sp)
    80001462:	e822                	sd	s0,16(sp)
    80001464:	e426                	sd	s1,8(sp)
    80001466:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80001468:	6904                	ld	s1,16(a0)
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	ba8080e7          	jalr	-1112(ra) # 80001012 <mycpu>
    80001472:	40a48533          	sub	a0,s1,a0
    80001476:	00153513          	seqz	a0,a0
}
    8000147a:	60e2                	ld	ra,24(sp)
    8000147c:	6442                	ld	s0,16(sp)
    8000147e:	64a2                	ld	s1,8(sp)
    80001480:	6105                	add	sp,sp,32
    80001482:	8082                	ret

0000000080001484 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80001484:	1101                	add	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000148e:	100024f3          	csrr	s1,sstatus
    80001492:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001496:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001498:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	b76080e7          	jalr	-1162(ra) # 80001012 <mycpu>
    800014a4:	411c                	lw	a5,0(a0)
    800014a6:	cf89                	beqz	a5,800014c0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	b6a080e7          	jalr	-1174(ra) # 80001012 <mycpu>
    800014b0:	411c                	lw	a5,0(a0)
    800014b2:	2785                	addw	a5,a5,1 # 1001 <_entry-0x7fffefff>
    800014b4:	c11c                	sw	a5,0(a0)
}
    800014b6:	60e2                	ld	ra,24(sp)
    800014b8:	6442                	ld	s0,16(sp)
    800014ba:	64a2                	ld	s1,8(sp)
    800014bc:	6105                	add	sp,sp,32
    800014be:	8082                	ret
    mycpu()->intena = old;
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	b52080e7          	jalr	-1198(ra) # 80001012 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    800014c8:	8085                	srl	s1,s1,0x1
    800014ca:	8885                	and	s1,s1,1
    800014cc:	c144                	sw	s1,4(a0)
    800014ce:	bfe9                	j	800014a8 <push_off+0x24>

00000000800014d0 <acquire>:
{
    800014d0:	1101                	add	sp,sp,-32
    800014d2:	ec06                	sd	ra,24(sp)
    800014d4:	e822                	sd	s0,16(sp)
    800014d6:	e426                	sd	s1,8(sp)
    800014d8:	1000                	add	s0,sp,32
    800014da:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	fa8080e7          	jalr	-88(ra) # 80001484 <push_off>
  if(holding(lk))
    800014e4:	8526                	mv	a0,s1
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	f70080e7          	jalr	-144(ra) # 80001456 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    800014ee:	4705                	li	a4,1
  if(holding(lk))
    800014f0:	e115                	bnez	a0,80001514 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    800014f2:	87ba                	mv	a5,a4
    800014f4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    800014f8:	2781                	sext.w	a5,a5
    800014fa:	ffe5                	bnez	a5,800014f2 <acquire+0x22>
  __sync_synchronize();
    800014fc:	0ff0000f          	fence
  lk->cpu = mycpu();
    80001500:	00000097          	auipc	ra,0x0
    80001504:	b12080e7          	jalr	-1262(ra) # 80001012 <mycpu>
    80001508:	e888                	sd	a0,16(s1)
}
    8000150a:	60e2                	ld	ra,24(sp)
    8000150c:	6442                	ld	s0,16(sp)
    8000150e:	64a2                	ld	s1,8(sp)
    80001510:	6105                	add	sp,sp,32
    80001512:	8082                	ret
    panic("acquire");
    80001514:	00002517          	auipc	a0,0x2
    80001518:	d7450513          	add	a0,a0,-652 # 80003288 <digits+0x1f8>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	25e080e7          	jalr	606(ra) # 8000077a <panic>

0000000080001524 <pop_off>:

void
pop_off(void)
{
    80001524:	1141                	add	sp,sp,-16
    80001526:	e406                	sd	ra,8(sp)
    80001528:	e022                	sd	s0,0(sp)
    8000152a:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	ae6080e7          	jalr	-1306(ra) # 80001012 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001534:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001538:	8b89                	and	a5,a5,2
  if(intr_get())
    8000153a:	e78d                	bnez	a5,80001564 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    8000153c:	411c                	lw	a5,0(a0)
    8000153e:	02f05b63          	blez	a5,80001574 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80001542:	37fd                	addw	a5,a5,-1
    80001544:	0007871b          	sext.w	a4,a5
    80001548:	c11c                	sw	a5,0(a0)
  if(c->noff == 0 && c->intena)
    8000154a:	eb09                	bnez	a4,8000155c <pop_off+0x38>
    8000154c:	415c                	lw	a5,4(a0)
    8000154e:	c799                	beqz	a5,8000155c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001550:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001554:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001558:	10079073          	csrw	sstatus,a5
    intr_on();
}
    8000155c:	60a2                	ld	ra,8(sp)
    8000155e:	6402                	ld	s0,0(sp)
    80001560:	0141                	add	sp,sp,16
    80001562:	8082                	ret
    panic("pop_off - interruptible");
    80001564:	00002517          	auipc	a0,0x2
    80001568:	d2c50513          	add	a0,a0,-724 # 80003290 <digits+0x200>
    8000156c:	fffff097          	auipc	ra,0xfffff
    80001570:	20e080e7          	jalr	526(ra) # 8000077a <panic>
    panic("pop_off");
    80001574:	00002517          	auipc	a0,0x2
    80001578:	d3450513          	add	a0,a0,-716 # 800032a8 <digits+0x218>
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	1fe080e7          	jalr	510(ra) # 8000077a <panic>

0000000080001584 <release>:
{
    80001584:	1101                	add	sp,sp,-32
    80001586:	ec06                	sd	ra,24(sp)
    80001588:	e822                	sd	s0,16(sp)
    8000158a:	e426                	sd	s1,8(sp)
    8000158c:	e04a                	sd	s2,0(sp)
    8000158e:	1000                	add	s0,sp,32
    80001590:	84aa                	mv	s1,a0
  if(!holding(lk))
    80001592:	00000097          	auipc	ra,0x0
    80001596:	ec4080e7          	jalr	-316(ra) # 80001456 <holding>
    8000159a:	c11d                	beqz	a0,800015c0 <release+0x3c>
  lk->cpu = 0;
    8000159c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800015a0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800015a4:	0f50000f          	fence	iorw,ow
    800015a8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    800015ac:	00000097          	auipc	ra,0x0
    800015b0:	f78080e7          	jalr	-136(ra) # 80001524 <pop_off>
}
    800015b4:	60e2                	ld	ra,24(sp)
    800015b6:	6442                	ld	s0,16(sp)
    800015b8:	64a2                	ld	s1,8(sp)
    800015ba:	6902                	ld	s2,0(sp)
    800015bc:	6105                	add	sp,sp,32
    800015be:	8082                	ret
    printf("release lock %s at %p, cpu%d\n", lk->name, lk, cpuid());
    800015c0:	0084b903          	ld	s2,8(s1)
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	a3e080e7          	jalr	-1474(ra) # 80001002 <cpuid>
    800015cc:	86aa                	mv	a3,a0
    800015ce:	8626                	mv	a2,s1
    800015d0:	85ca                	mv	a1,s2
    800015d2:	00002517          	auipc	a0,0x2
    800015d6:	cde50513          	add	a0,a0,-802 # 800032b0 <digits+0x220>
    800015da:	fffff097          	auipc	ra,0xfffff
    800015de:	1ea080e7          	jalr	490(ra) # 800007c4 <printf>
    panic("release");
    800015e2:	00002517          	auipc	a0,0x2
    800015e6:	cee50513          	add	a0,a0,-786 # 800032d0 <digits+0x240>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	190080e7          	jalr	400(ra) # 8000077a <panic>

00000000800015f2 <trapinithart>:

// 设置在内核中接受异常和陷阱。
// 每个 CPU 核心都需要调用这个函数来设置陷阱处理
void
trapinithart(void)
{
    800015f2:	1141                	add	sp,sp,-16
    800015f4:	e422                	sd	s0,8(sp)
    800015f6:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800015f8:	00000797          	auipc	a5,0x0
    800015fc:	50878793          	add	a5,a5,1288 # 80001b00 <kernelvec>
    80001600:	10579073          	csrw	stvec,a5
  // 设置 stvec 寄存器指向 kernelvec 函数
  // 这样所有在内核态发生的陷阱都会跳转到 kernelvec
  w_stvec((uint64)kernelvec);
}
    80001604:	6422                	ld	s0,8(sp)
    80001606:	0141                	add	sp,sp,16
    80001608:	8082                	ret

000000008000160a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000160a:	142027f3          	csrr	a5,scause
    // 清除软件中断标志
    // 通过清除 sip 中的 SSIP 位来确认软件中断。
    w_sip(r_sip() & ~2);
    return 2;  // 表示定时器中断
  } else {
    return 0;  // 未识别的中断类型
    8000160e:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80001610:	0807d763          	bgez	a5,8000169e <devintr+0x94>
{
    80001614:	1101                	add	sp,sp,-32
    80001616:	ec06                	sd	ra,24(sp)
    80001618:	e822                	sd	s0,16(sp)
    8000161a:	e426                	sd	s1,8(sp)
    8000161c:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    8000161e:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80001622:	46a5                	li	a3,9
    80001624:	00d70d63          	beq	a4,a3,8000163e <devintr+0x34>
  if(scause == 0x8000000000000001L){
    80001628:	577d                	li	a4,-1
    8000162a:	177e                	sll	a4,a4,0x3f
    8000162c:	0705                	add	a4,a4,1
    return 0;  // 未识别的中断类型
    8000162e:	4501                	li	a0,0
  if(scause == 0x8000000000000001L){
    80001630:	04e78663          	beq	a5,a4,8000167c <devintr+0x72>
  }
}
    80001634:	60e2                	ld	ra,24(sp)
    80001636:	6442                	ld	s0,16(sp)
    80001638:	64a2                	ld	s1,8(sp)
    8000163a:	6105                	add	sp,sp,32
    8000163c:	8082                	ret
    int irq = plic_claim();  // 获取中断请求号
    8000163e:	fffff097          	auipc	ra,0xfffff
    80001642:	ea6080e7          	jalr	-346(ra) # 800004e4 <plic_claim>
    80001646:	84aa                	mv	s1,a0
    switch(irq){
    80001648:	47a9                	li	a5,10
    8000164a:	02f50463          	beq	a0,a5,80001672 <devintr+0x68>
    return 1;
    8000164e:	4505                	li	a0,1
      if(irq){
    80001650:	d0f5                	beqz	s1,80001634 <devintr+0x2a>
        printf("unexpected interrupt irq=%d\n", irq);
    80001652:	85a6                	mv	a1,s1
    80001654:	00002517          	auipc	a0,0x2
    80001658:	c8450513          	add	a0,a0,-892 # 800032d8 <digits+0x248>
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	168080e7          	jalr	360(ra) # 800007c4 <printf>
      plic_complete(irq);
    80001664:	8526                	mv	a0,s1
    80001666:	fffff097          	auipc	ra,0xfffff
    8000166a:	ea2080e7          	jalr	-350(ra) # 80000508 <plic_complete>
    return 1;
    8000166e:	4505                	li	a0,1
    80001670:	b7d1                	j	80001634 <devintr+0x2a>
      uartintr();           // 处理串口中断
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	d38080e7          	jalr	-712(ra) # 800003aa <uartintr>
    if(irq)
    8000167a:	b7ed                	j	80001664 <devintr+0x5a>
    if(cpuid() == 0){
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	986080e7          	jalr	-1658(ra) # 80001002 <cpuid>
    80001684:	c901                	beqz	a0,80001694 <devintr+0x8a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80001686:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000168a:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000168c:	14479073          	csrw	sip,a5
    return 2;  // 表示定时器中断
    80001690:	4509                	li	a0,2
    80001692:	b74d                	j	80001634 <devintr+0x2a>
      timer_update();
    80001694:	fffff097          	auipc	ra,0xfffff
    80001698:	bc2080e7          	jalr	-1086(ra) # 80000256 <timer_update>
    8000169c:	b7ed                	j	80001686 <devintr+0x7c>
}
    8000169e:	8082                	ret

00000000800016a0 <kerneltrap>:
{
    800016a0:	7179                	add	sp,sp,-48
    800016a2:	f406                	sd	ra,40(sp)
    800016a4:	f022                	sd	s0,32(sp)
    800016a6:	ec26                	sd	s1,24(sp)
    800016a8:	e84a                	sd	s2,16(sp)
    800016aa:	e44e                	sd	s3,8(sp)
    800016ac:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800016ae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800016b2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800016b6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800016ba:	1004f793          	and	a5,s1,256
    800016be:	cb85                	beqz	a5,800016ee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800016c0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800016c4:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    800016c6:	ef85                	bnez	a5,800016fe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800016c8:	00000097          	auipc	ra,0x0
    800016cc:	f42080e7          	jalr	-190(ra) # 8000160a <devintr>
    800016d0:	cd1d                	beqz	a0,8000170e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 /*&& myproc()->state == RUNNING*/)
    800016d2:	4789                	li	a5,2
    800016d4:	06f50a63          	beq	a0,a5,80001748 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800016d8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800016dc:	10049073          	csrw	sstatus,s1
}
    800016e0:	70a2                	ld	ra,40(sp)
    800016e2:	7402                	ld	s0,32(sp)
    800016e4:	64e2                	ld	s1,24(sp)
    800016e6:	6942                	ld	s2,16(sp)
    800016e8:	69a2                	ld	s3,8(sp)
    800016ea:	6145                	add	sp,sp,48
    800016ec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800016ee:	00002517          	auipc	a0,0x2
    800016f2:	c0a50513          	add	a0,a0,-1014 # 800032f8 <digits+0x268>
    800016f6:	fffff097          	auipc	ra,0xfffff
    800016fa:	084080e7          	jalr	132(ra) # 8000077a <panic>
    panic("kerneltrap: interrupts enabled");
    800016fe:	00002517          	auipc	a0,0x2
    80001702:	c2250513          	add	a0,a0,-990 # 80003320 <digits+0x290>
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	074080e7          	jalr	116(ra) # 8000077a <panic>
    printf("scause %p\n", scause);
    8000170e:	85ce                	mv	a1,s3
    80001710:	00002517          	auipc	a0,0x2
    80001714:	c3050513          	add	a0,a0,-976 # 80003340 <digits+0x2b0>
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	0ac080e7          	jalr	172(ra) # 800007c4 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001720:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001724:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80001728:	00002517          	auipc	a0,0x2
    8000172c:	c2850513          	add	a0,a0,-984 # 80003350 <digits+0x2c0>
    80001730:	fffff097          	auipc	ra,0xfffff
    80001734:	094080e7          	jalr	148(ra) # 800007c4 <printf>
    panic("kerneltrap");
    80001738:	00002517          	auipc	a0,0x2
    8000173c:	c3050513          	add	a0,a0,-976 # 80003368 <digits+0x2d8>
    80001740:	fffff097          	auipc	ra,0xfffff
    80001744:	03a080e7          	jalr	58(ra) # 8000077a <panic>
  if(which_dev == 2 && myproc() != 0 /*&& myproc()->state == RUNNING*/)
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	8e6080e7          	jalr	-1818(ra) # 8000102e <myproc>
    80001750:	d541                	beqz	a0,800016d8 <kerneltrap+0x38>
    yield();
    80001752:	00000097          	auipc	ra,0x0
    80001756:	15e080e7          	jalr	350(ra) # 800018b0 <yield>
    8000175a:	bfbd                	j	800016d8 <kerneltrap+0x38>

000000008000175c <scheduler>:
//  - 选择一个进程运行
//  - 通过swtch切换到该进程开始运行
//  - 最终该进程通过swtch将控制权交回给调度器
void
scheduler(void)
{
    8000175c:	715d                	add	sp,sp,-80
    8000175e:	e486                	sd	ra,72(sp)
    80001760:	e0a2                	sd	s0,64(sp)
    80001762:	fc26                	sd	s1,56(sp)
    80001764:	f84a                	sd	s2,48(sp)
    80001766:	f44e                	sd	s3,40(sp)
    80001768:	f052                	sd	s4,32(sp)
    8000176a:	ec56                	sd	s5,24(sp)
    8000176c:	e85a                	sd	s6,16(sp)
    8000176e:	e45e                	sd	s7,8(sp)
    80001770:	0880                	add	s0,sp,80
  struct proc *p;
  struct cpu *c = mycpu();
    80001772:	00000097          	auipc	ra,0x0
    80001776:	8a0080e7          	jalr	-1888(ra) # 80001012 <mycpu>
    8000177a:	8aaa                	mv	s5,a0
  
  c->proc = 0;
    8000177c:	00053423          	sd	zero,8(a0)
    intr_on();
    intr_off();  // 禁用中断
    // 遍历进程表，寻找可运行的进程
    for(p = proc; p < &proc[NPROC]; p++) {
      acquire(&p->lock);
      if(p->state == RUNNABLE) {
    80001780:	4a0d                	li	s4,3
        
        // 切换到选中的进程。进程有责任释放其锁
        // 然后在跳回调度器之前重新获取锁
        p->state = RUNNING;
    80001782:	4b91                	li	s7,4
        c->proc = p;
        
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    80001784:	01050b13          	add	s6,a0,16
    for(p = proc; p < &proc[NPROC]; p++) {
    80001788:	0000d997          	auipc	s3,0xd
    8000178c:	61098993          	add	s3,s3,1552 # 8000ed98 <end>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001790:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001794:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001798:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000179c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800017a0:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800017a2:	10079073          	csrw	sstatus,a5
    800017a6:	0000a497          	auipc	s1,0xa
    800017aa:	3f248493          	add	s1,s1,1010 # 8000bb98 <proc>
    800017ae:	a811                	j	800017c2 <scheduler+0x66>
        // 进程暂时运行完毕
        // 它应该在返回之前改变了p->state
        c->proc = 0;
      }
      release(&p->lock);
    800017b0:	854a                	mv	a0,s2
    800017b2:	00000097          	auipc	ra,0x0
    800017b6:	dd2080e7          	jalr	-558(ra) # 80001584 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800017ba:	0c848493          	add	s1,s1,200
    800017be:	fd3489e3          	beq	s1,s3,80001790 <scheduler+0x34>
      acquire(&p->lock);
    800017c2:	00848913          	add	s2,s1,8
    800017c6:	854a                	mv	a0,s2
    800017c8:	00000097          	auipc	ra,0x0
    800017cc:	d08080e7          	jalr	-760(ra) # 800014d0 <acquire>
      if(p->state == RUNNABLE) {
    800017d0:	509c                	lw	a5,32(s1)
    800017d2:	fd479fe3          	bne	a5,s4,800017b0 <scheduler+0x54>
        p->state = RUNNING;
    800017d6:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800017da:	009ab423          	sd	s1,8(s5)
        swtch(&c->context, &p->ctx);  // 上下文切换到进程
    800017de:	05848593          	add	a1,s1,88
    800017e2:	855a                	mv	a0,s6
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	2a4080e7          	jalr	676(ra) # 80001a88 <swtch>
        c->proc = 0;
    800017ec:	000ab423          	sd	zero,8(s5)
    800017f0:	b7c1                	j	800017b0 <scheduler+0x54>

00000000800017f2 <sched>:
// 并且已经改变了proc->state。
// 因为intena是这个内核线程的属性，而不是这个CPU的属性。
// 因此此处需要保存和恢复intena
void
sched(void)
{
    800017f2:	1101                	add	sp,sp,-32
    800017f4:	ec06                	sd	ra,24(sp)
    800017f6:	e822                	sd	s0,16(sp)
    800017f8:	e426                	sd	s1,8(sp)
    800017fa:	e04a                	sd	s2,0(sp)
    800017fc:	1000                	add	s0,sp,32
  int intena;
  struct proc *p = myproc();
    800017fe:	00000097          	auipc	ra,0x0
    80001802:	830080e7          	jalr	-2000(ra) # 8000102e <myproc>
    80001806:	84aa                	mv	s1,a0

  if(!holding(&p->lock))
    80001808:	0521                	add	a0,a0,8
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	c4c080e7          	jalr	-948(ra) # 80001456 <holding>
    80001812:	cd39                	beqz	a0,80001870 <sched+0x7e>
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    80001814:	fffff097          	auipc	ra,0xfffff
    80001818:	7fe080e7          	jalr	2046(ra) # 80001012 <mycpu>
    8000181c:	4118                	lw	a4,0(a0)
    8000181e:	4785                	li	a5,1
    80001820:	06f71063          	bne	a4,a5,80001880 <sched+0x8e>
    panic("sched locks");
  if(p->state == RUNNING)
    80001824:	5098                	lw	a4,32(s1)
    80001826:	4791                	li	a5,4
    80001828:	06f70463          	beq	a4,a5,80001890 <sched+0x9e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000182c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001830:	8b89                	and	a5,a5,2
    panic("sched running");
  if(intr_get())
    80001832:	e7bd                	bnez	a5,800018a0 <sched+0xae>
    panic("sched interruptible");

  intena = mycpu()->intena;
    80001834:	fffff097          	auipc	ra,0xfffff
    80001838:	7de080e7          	jalr	2014(ra) # 80001012 <mycpu>
    8000183c:	00452903          	lw	s2,4(a0)
  swtch(&p->ctx, &mycpu()->context);  // 切换到调度器上下文
    80001840:	fffff097          	auipc	ra,0xfffff
    80001844:	7d2080e7          	jalr	2002(ra) # 80001012 <mycpu>
    80001848:	01050593          	add	a1,a0,16
    8000184c:	05848513          	add	a0,s1,88
    80001850:	00000097          	auipc	ra,0x0
    80001854:	238080e7          	jalr	568(ra) # 80001a88 <swtch>
  mycpu()->intena = intena;
    80001858:	fffff097          	auipc	ra,0xfffff
    8000185c:	7ba080e7          	jalr	1978(ra) # 80001012 <mycpu>
    80001860:	01252223          	sw	s2,4(a0)
}
    80001864:	60e2                	ld	ra,24(sp)
    80001866:	6442                	ld	s0,16(sp)
    80001868:	64a2                	ld	s1,8(sp)
    8000186a:	6902                	ld	s2,0(sp)
    8000186c:	6105                	add	sp,sp,32
    8000186e:	8082                	ret
    panic("sched p->lock");
    80001870:	00002517          	auipc	a0,0x2
    80001874:	b0850513          	add	a0,a0,-1272 # 80003378 <digits+0x2e8>
    80001878:	fffff097          	auipc	ra,0xfffff
    8000187c:	f02080e7          	jalr	-254(ra) # 8000077a <panic>
    panic("sched locks");
    80001880:	00002517          	auipc	a0,0x2
    80001884:	b0850513          	add	a0,a0,-1272 # 80003388 <digits+0x2f8>
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	ef2080e7          	jalr	-270(ra) # 8000077a <panic>
    panic("sched running");
    80001890:	00002517          	auipc	a0,0x2
    80001894:	b0850513          	add	a0,a0,-1272 # 80003398 <digits+0x308>
    80001898:	fffff097          	auipc	ra,0xfffff
    8000189c:	ee2080e7          	jalr	-286(ra) # 8000077a <panic>
    panic("sched interruptible");
    800018a0:	00002517          	auipc	a0,0x2
    800018a4:	b0850513          	add	a0,a0,-1272 # 800033a8 <digits+0x318>
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	ed2080e7          	jalr	-302(ra) # 8000077a <panic>

00000000800018b0 <yield>:

// 用于进程放弃CPU, 重新进入调度
void
yield(void)
{
    800018b0:	1101                	add	sp,sp,-32
    800018b2:	ec06                	sd	ra,24(sp)
    800018b4:	e822                	sd	s0,16(sp)
    800018b6:	e426                	sd	s1,8(sp)
    800018b8:	e04a                	sd	s2,0(sp)
    800018ba:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    800018bc:	fffff097          	auipc	ra,0xfffff
    800018c0:	772080e7          	jalr	1906(ra) # 8000102e <myproc>
    800018c4:	84aa                	mv	s1,a0
  acquire(&p->lock);     // 获取进程锁
    800018c6:	00850913          	add	s2,a0,8
    800018ca:	854a                	mv	a0,s2
    800018cc:	00000097          	auipc	ra,0x0
    800018d0:	c04080e7          	jalr	-1020(ra) # 800014d0 <acquire>
  p->state = RUNNABLE;   // 将进程状态设为可运行
    800018d4:	478d                	li	a5,3
    800018d6:	d09c                	sw	a5,32(s1)
  sched();               // 调用sched()切换到调度器
    800018d8:	00000097          	auipc	ra,0x0
    800018dc:	f1a080e7          	jalr	-230(ra) # 800017f2 <sched>
  release(&p->lock);     // 释放进程锁
    800018e0:	854a                	mv	a0,s2
    800018e2:	00000097          	auipc	ra,0x0
    800018e6:	ca2080e7          	jalr	-862(ra) # 80001584 <release>
    800018ea:	60e2                	ld	ra,24(sp)
    800018ec:	6442                	ld	s0,16(sp)
    800018ee:	64a2                	ld	s1,8(sp)
    800018f0:	6902                	ld	s2,0(sp)
    800018f2:	6105                	add	sp,sp,32
    800018f4:	8082                	ret

00000000800018f6 <trap_user_return>:
}

// 调用user_return()
// 内核态返回用户态
void trap_user_return()
{
    800018f6:	1141                	add	sp,sp,-16
    800018f8:	e406                	sd	ra,8(sp)
    800018fa:	e022                	sd	s0,0(sp)
    800018fc:	0800                	add	s0,sp,16
  //printf("trap_user_return\n");
  struct proc *p = myproc();
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	730080e7          	jalr	1840(ra) # 8000102e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001906:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000190a:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000190c:	10079073          	csrw	sstatus,a5
  intr_off();

  // 设置用户态陷阱向量
  // 将系统调用、中断和异常发送到 trampoline.S 中的 uservec
  // 计算 uservec 在 trampoline 页面中的实际地址
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80001910:	00000697          	auipc	a3,0x0
    80001914:	6f068693          	add	a3,a3,1776 # 80002000 <_trampoline>
    80001918:	00000717          	auipc	a4,0x0
    8000191c:	6e870713          	add	a4,a4,1768 # 80002000 <_trampoline>
    80001920:	8f15                	sub	a4,a4,a3
    80001922:	040007b7          	lui	a5,0x4000
    80001926:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001928:	07b2                	sll	a5,a5,0xc
    8000192a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000192c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // 准备 trapframe，为下次用户陷阱做准备
  // 设置 uservec 在进程下次陷入内核时需要的 trapframe 值。
  p->tf->kernel_satp = r_satp();         // 内核页表
    80001930:	6138                	ld	a4,64(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80001932:	18002673          	csrr	a2,satp
    80001936:	e310                	sd	a2,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // 进程的内核栈
    80001938:	6130                	ld	a2,64(a0)
    8000193a:	6938                	ld	a4,80(a0)
    8000193c:	6585                	lui	a1,0x1
    8000193e:	972e                	add	a4,a4,a1
    80001940:	e618                	sd	a4,8(a2)
  p->tf->kernel_trap = (uint64)trap_user_handler; // 用户陷阱处理函数地址
    80001942:	6138                	ld	a4,64(a0)
    80001944:	00000617          	auipc	a2,0x0
    80001948:	04860613          	add	a2,a2,72 # 8000198c <trap_user_handler>
    8000194c:	eb10                	sd	a2,16(a4)
  p->tf->kernel_hartid = r_tp();         // cpuid() 的 hartid
    8000194e:	6138                	ld	a4,64(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80001950:	8612                	mv	a2,tp
    80001952:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001954:	10002773          	csrr	a4,sstatus
  // 设置处理器状态，准备返回用户模式
  // 设置 trampoline.S 的 sret 将用来进入用户空间的寄存器。
  
  // 将 S 先前特权模式设置为用户。
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // 将 SPP 清零，表示用户模式
    80001958:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // 在用户模式下启用中断
    8000195c:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001960:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // 设置返回地址
  // 将 S 异常程序计数器设置为保存的用户 pc。
  // 用户程序将从这个地址继续执行
  w_sepc(p->tf->epc);
    80001964:	6138                	ld	a4,64(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001966:	6f18                	ld	a4,24(a4)
    80001968:	14171073          	csrw	sepc,a4

  // 准备用户页表
  // 告诉 trampoline.S 要切换到的用户页表。
  uint64 satp = MAKE_SATP(p->pgtbl);
    8000196c:	7508                	ld	a0,40(a0)
    8000196e:	8131                	srl	a0,a0,0xc

  // 最后一步：跳转到 trampoline 代码完成用户空间切换
  // 跳转到内存顶部 trampoline.S 中的 userret，
  // 它切换到用户页表、恢复用户寄存器并通过 sret 切换到用户模式。
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001970:	00000717          	auipc	a4,0x0
    80001974:	72c70713          	add	a4,a4,1836 # 8000209c <userret>
    80001978:	8f15                	sub	a4,a4,a3
    8000197a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000197c:	577d                	li	a4,-1
    8000197e:	177e                	sll	a4,a4,0x3f
    80001980:	8d59                	or	a0,a0,a4
    80001982:	9782                	jalr	a5
    80001984:	60a2                	ld	ra,8(sp)
    80001986:	6402                	ld	s0,0(sp)
    80001988:	0141                	add	sp,sp,16
    8000198a:	8082                	ret

000000008000198c <trap_user_handler>:
{
    8000198c:	7139                	add	sp,sp,-64
    8000198e:	fc06                	sd	ra,56(sp)
    80001990:	f822                	sd	s0,48(sp)
    80001992:	f426                	sd	s1,40(sp)
    80001994:	f04a                	sd	s2,32(sp)
    80001996:	ec4e                	sd	s3,24(sp)
    80001998:	e852                	sd	s4,16(sp)
    8000199a:	e456                	sd	s5,8(sp)
    8000199c:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000199e:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800019a2:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800019a6:	14202a73          	csrr	s4,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    800019aa:	14302af3          	csrr	s5,stval
    proc_t* p = myproc();
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	680080e7          	jalr	1664(ra) # 8000102e <myproc>
    if(sstatus & SSTATUS_SPP)
    800019b6:	10097913          	and	s2,s2,256
    800019ba:	04091663          	bnez	s2,80001a06 <trap_user_handler+0x7a>
    800019be:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    800019c0:	00000797          	auipc	a5,0x0
    800019c4:	14078793          	add	a5,a5,320 # 80001b00 <kernelvec>
    800019c8:	10579073          	csrw	stvec,a5
  p->tf->epc = sepc;
    800019cc:	613c                	ld	a5,64(a0)
    800019ce:	0137bc23          	sd	s3,24(a5)
  if(scause == 8){
    800019d2:	47a1                	li	a5,8
    800019d4:	04fa0163          	beq	s4,a5,80001a16 <trap_user_handler+0x8a>
  } else if((which_dev = devintr()) != 0){
    800019d8:	00000097          	auipc	ra,0x0
    800019dc:	c32080e7          	jalr	-974(ra) # 8000160a <devintr>
    800019e0:	892a                	mv	s2,a0
    800019e2:	cd35                	beqz	a0,80001a5e <trap_user_handler+0xd2>
    printf("usertrap: devintr which_dev=%d\n", which_dev);
    800019e4:	85aa                	mv	a1,a0
    800019e6:	00002517          	auipc	a0,0x2
    800019ea:	a2250513          	add	a0,a0,-1502 # 80003408 <digits+0x378>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	dd6080e7          	jalr	-554(ra) # 800007c4 <printf>
  if(which_dev == 2)
    800019f6:	4789                	li	a5,2
    800019f8:	04f91663          	bne	s2,a5,80001a44 <trap_user_handler+0xb8>
    yield();  // 让出 CPU，调度其他进程
    800019fc:	00000097          	auipc	ra,0x0
    80001a00:	eb4080e7          	jalr	-332(ra) # 800018b0 <yield>
    80001a04:	a081                	j	80001a44 <trap_user_handler+0xb8>
        panic("trap_user_handler: not from u-mode");
    80001a06:	00002517          	auipc	a0,0x2
    80001a0a:	9ba50513          	add	a0,a0,-1606 # 800033c0 <digits+0x330>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	d6c080e7          	jalr	-660(ra) # 8000077a <panic>
    p->tf->epc += 4;
    80001a16:	6138                	ld	a4,64(a0)
    80001a18:	6f1c                	ld	a5,24(a4)
    80001a1a:	0791                	add	a5,a5,4
    80001a1c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001a1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001a22:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001a26:	10079073          	csrw	sstatus,a5
    printf("get a syscall from proc %d\n", myproc()->pid);
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	604080e7          	jalr	1540(ra) # 8000102e <myproc>
    80001a32:	410c                	lw	a1,0(a0)
    80001a34:	00002517          	auipc	a0,0x2
    80001a38:	9b450513          	add	a0,a0,-1612 # 800033e8 <digits+0x358>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	d88080e7          	jalr	-632(ra) # 800007c4 <printf>
  trap_user_return();
    80001a44:	00000097          	auipc	ra,0x0
    80001a48:	eb2080e7          	jalr	-334(ra) # 800018f6 <trap_user_return>
}
    80001a4c:	70e2                	ld	ra,56(sp)
    80001a4e:	7442                	ld	s0,48(sp)
    80001a50:	74a2                	ld	s1,40(sp)
    80001a52:	7902                	ld	s2,32(sp)
    80001a54:	69e2                	ld	s3,24(sp)
    80001a56:	6a42                	ld	s4,16(sp)
    80001a58:	6aa2                	ld	s5,8(sp)
    80001a5a:	6121                	add	sp,sp,64
    80001a5c:	8082                	ret
    printf("usertrap(): unexpected scause %p pid=%d\n", scause, p->pid);
    80001a5e:	4090                	lw	a2,0(s1)
    80001a60:	85d2                	mv	a1,s4
    80001a62:	00002517          	auipc	a0,0x2
    80001a66:	9c650513          	add	a0,a0,-1594 # 80003428 <digits+0x398>
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	d5a080e7          	jalr	-678(ra) # 800007c4 <printf>
    printf("            sepc=%p stval=%p\n", sepc, stval);
    80001a72:	8656                	mv	a2,s5
    80001a74:	85ce                	mv	a1,s3
    80001a76:	00002517          	auipc	a0,0x2
    80001a7a:	9e250513          	add	a0,a0,-1566 # 80003458 <digits+0x3c8>
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	d46080e7          	jalr	-698(ra) # 800007c4 <printf>
  if(which_dev == 2)
    80001a86:	bf7d                	j	80001a44 <trap_user_handler+0xb8>

0000000080001a88 <swtch>:


.globl swtch
swtch:
        # 保存当前上下文到old结构体中
        sd ra, 0(a0)      # 保存返回地址
    80001a88:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)      # 保存栈指针
    80001a8c:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)     # 保存s0寄存器
    80001a90:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)     # 保存s1寄存器
    80001a92:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)     # 保存s2寄存器
    80001a94:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)     # 保存s3寄存器
    80001a98:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)     # 保存s4寄存器
    80001a9c:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)     # 保存s5寄存器
    80001aa0:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)     # 保存s6寄存器
    80001aa4:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)     # 保存s7寄存器
    80001aa8:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)     # 保存s8寄存器
    80001aac:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)     # 保存s9寄存器
    80001ab0:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)    # 保存s10寄存器
    80001ab4:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)   # 保存s11寄存器
    80001ab8:	07b53423          	sd	s11,104(a0)

        # 从new结构体中恢复新上下文
        ld ra, 0(a1)      # 恢复返回地址
    80001abc:	0005b083          	ld	ra,0(a1) # 1000 <_entry-0x7ffff000>
        ld sp, 8(a1)      # 恢复栈指针
    80001ac0:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)     # 恢复s0寄存器
    80001ac4:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)     # 恢复s1寄存器
    80001ac6:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)     # 恢复s2寄存器
    80001ac8:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)     # 恢复s3寄存器
    80001acc:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)     # 恢复s4寄存器
    80001ad0:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)     # 恢复s5寄存器
    80001ad4:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)     # 恢复s6寄存器
    80001ad8:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)     # 恢复s7寄存器
    80001adc:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)     # 恢复s8寄存器
    80001ae0:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)     # 恢复s9寄存器
    80001ae4:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)    # 恢复s10寄存器
    80001ae8:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)   # 恢复s11寄存器
    80001aec:	0685bd83          	ld	s11,104(a1)
        
        ret               # 返回到新上下文的返回地址
    80001af0:	8082                	ret
	...

0000000080001b00 <kernelvec>:
kernelvec:
        # 内核中断/异常处理入口点
        # 为保存寄存器腾出空间。
        # 在栈上分配 256 字节空间来保存所有寄存器
        # RISC-V 有 32 个寄存器，每个 8 字节，共需要 256 字节
        addi sp, sp, -256
    80001b00:	7111                	add	sp,sp,-256

        # 保存所有通用寄存器到栈上
        # 这样 C 代码就可以自由使用这些寄存器
        # 保存寄存器。
        sd ra, 0(sp)
    80001b02:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80001b04:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80001b06:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80001b08:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80001b0a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    80001b0c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    80001b0e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    80001b10:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    80001b12:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    80001b14:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80001b16:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80001b18:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80001b1a:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80001b1c:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80001b1e:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    80001b20:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    80001b22:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    80001b24:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    80001b26:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    80001b28:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    80001b2a:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    80001b2c:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    80001b2e:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    80001b30:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    80001b32:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    80001b34:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    80001b36:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    80001b38:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80001b3a:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80001b3c:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80001b3e:	f9fe                	sd	t6,240(sp)

        # 调用 C 语言的陷阱处理函数
        # 调用 trap.c 中的 C 陷阱处理程序
        # 这个函数会识别中断类型并进行相应处理
        call kerneltrap
    80001b40:	00000097          	auipc	ra,0x0
    80001b44:	b60080e7          	jalr	-1184(ra) # 800016a0 <kerneltrap>

        # 从 C 函数返回后，恢复所有寄存器
        # 恢复寄存器。
        ld ra, 0(sp)
    80001b48:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    80001b4a:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    80001b4c:	61c2                	ld	gp,16(sp)
        # 特别注意：不恢复 tp（包含 hartid），以防 CPU 变更
        # tp 寄存器包含当前 CPU 核心的 ID，如果在处理过程中进程被调度到其他核心，
        # 我们不应该恢复旧的 tp 值
        ld t0, 32(sp)
    80001b4e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80001b50:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80001b52:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    80001b54:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    80001b56:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    80001b58:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80001b5a:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80001b5c:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    80001b5e:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    80001b60:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    80001b62:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80001b64:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80001b66:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    80001b68:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    80001b6a:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    80001b6c:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    80001b6e:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    80001b70:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    80001b72:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    80001b74:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    80001b76:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    80001b78:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    80001b7a:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    80001b7c:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80001b7e:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80001b80:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    80001b82:	7fce                	ld	t6,240(sp)

        # 恢复栈指针，释放之前分配的 256 字节空间
        addi sp, sp, 256
    80001b84:	6111                	add	sp,sp,256

        # 返回到被中断的内核代码
        # 返回到我们在内核中正在做的任何事情。
        # sret 会恢复之前的执行状态
        sret
    80001b86:	10200073          	sret
    80001b8a:	0001                	nop
    80001b8c:	00000013          	nop

0000000080001b90 <timervec>:
        #
        # CLINT (Core Local Interruptor) 是 RISC-V 的定时器硬件
        # MTIMECMP 是定时器比较寄存器，当 mtime >= mtimecmp 时产生中断
        
        # 保存寄存器到 scratch 区域（机器模式下的临时存储）
        csrrw a0, mscratch, a0
    80001b90:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    80001b94:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    80001b96:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    80001b98:	e914                	sd	a3,16(a0)

        # 设置下一次定时器中断
        # 通过将间隔添加到 mtimecmp 来调度下一个定时器中断。
        ld a1, 24(a0) # CLINT_MTIMECMP(hart) - 加载定时器比较寄存器地址
    80001b9a:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval - 加载时间间隔
    80001b9c:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)  # 读取当前的 mtimecmp 值
    80001b9e:	6194                	ld	a3,0(a1)
        add a3, a3, a2 # 加上间隔，得到下一次中断时间
    80001ba0:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)   # 写回 mtimecmp 寄存器
    80001ba2:	e194                	sd	a3,0(a1)

        # 触发软件中断给管理员模式处理
        # 在此处理程序返回后触发一个软件中断。
        # 这样管理员模式的内核可以处理定时器事件
        li a1, 2
    80001ba4:	4589                	li	a1,2
        csrw sip, a1  # 设置管理员模式软件中断位
    80001ba6:	14459073          	csrw	sip,a1

        # 恢复寄存器并返回
        ld a3, 16(a0)
    80001baa:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    80001bac:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    80001bae:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80001bb0:	34051573          	csrrw	a0,mscratch,a0

        # 从机器模式中断返回
        mret
    80001bb4:	30200073          	mret
    80001bb8:	00000013          	nop
    80001bbc:	00000013          	nop
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
