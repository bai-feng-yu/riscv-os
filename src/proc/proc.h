// Per-CPU state.
struct cpu {
    int noff;       // 关中断的深度
    int intena;     // 第一次关中断前的状态
};