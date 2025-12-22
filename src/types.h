#ifndef TYPES_H
#define TYPES_H
typedef unsigned int   uint;
typedef unsigned short ushort;
typedef unsigned char  uchar;

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int  uint32;
typedef unsigned long uint64;

typedef uint64 pde_t;
typedef enum {false = 0, true = 1} bool;

// 时间值结构体
// struct timeval {
//   uint64 tv_sec;   // 秒数
//   uint64 tv_usec;  // 微秒数
// };

//printf增强
#define COLOR_RED    "\033[31m"
#define COLOR_GREEN  "\033[32m"
#define COLOR_YELLOW "\033[33m"
#define COLOR_BLUE   "\033[34m"
#define COLOR_RESET  "\033[0m"

#define BOLD         "\033[1m"
#define UNDERLINE    "\033[4m"

#endif // TYPES_H
