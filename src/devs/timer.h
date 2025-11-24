#include "../sync/spinlock.h"

// 计时器
typedef struct timer {
    uint64 ticks;
    struct spinlock lk;
} timer_t;
