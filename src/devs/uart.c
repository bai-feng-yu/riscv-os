//
// low-level driver routines for 16550a UART.
//

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc-h/proc.h"
#include "defs.h"

// the UART control registers are memory-mapped
// at address UART0. this macro returns the
// address of one of the registers.
#define Reg(reg) ((volatile unsigned char *)(UART0 + reg))

// the UART control registers.
// some have different meanings for
// read vs write.
// see http://byterunner.com/16550.html
#define RHR 0                 // receive holding register (for input bytes)
#define THR 0                 // transmit holding register (for output bytes)
#define IER 1                 // interrupt enable register
#define IER_RX_ENABLE (1<<0)
#define IER_TX_ENABLE (1<<1)
#define FCR 2                 // FIFO control register
#define FCR_FIFO_ENABLE (1<<0)
#define FCR_FIFO_CLEAR (3<<1) // clear the content of the two FIFOs
#define ISR 2                 // interrupt status register
#define LCR 3                 // line control register
#define LCR_EIGHT_BITS (3<<0)
#define LCR_BAUD_LATCH (1<<7) // special mode to set baud rate
#define LSR 5                 // line status register
#define LSR_RX_READY (1<<0)   // input is waiting to be read from RHR
#define LSR_TX_IDLE (1<<5)    // THR can accept another character to send

#define ReadReg(reg) (*(Reg(reg)))
#define WriteReg(reg, v) (*(Reg(reg)) = (v))

// the transmit output buffer.
struct spinlock uart_tx_lock;
#define UART_TX_BUF_SIZE 32
char uart_tx_buf[UART_TX_BUF_SIZE];
uint64 uart_tx_w; // write next to uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE]
uint64 uart_tx_r; // read next from uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE]

extern volatile int panicked; // from printf.c

void uartstart();

void
uartinit(void)
{
  // disable interrupts.
  WriteReg(IER, 0x00);

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);

  initlock(&uart_tx_lock, "uart");
}

// add a character to the output buffer and tell the
// UART to start sending if it isn't already.
// blocks if the output buffer is full.
// because it may block, it can't be called
// from interrupts; it's only suitable for use
// by write().
// void
// uartputc(int c)
// {
//   acquire(&uart_tx_lock);

//   if(panicked){
//     for(;;)
//       ;
//   }
//   while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
//     // buffer is full.
//     // wait for uartstart() to open up space in the buffer.
//     sleep(&uart_tx_r, &uart_tx_lock);
//   }
//   uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
//   uart_tx_w += 1;
//   uartstart();
//   release(&uart_tx_lock);
// }


// 不使用中断的uartputc的替换版本
// 用于内核printf和回显字符
// 它会持续等待uart的输出寄存器为空(同步性、阻塞性)
void
uartputc_sync(int c)
{
  // 关中断，防止串口中断再次进入造成竞争
  push_off();
  
  // 如果内核已经崩溃则陷入死循环
  if(panicked){
    for(;;)
      ;
  }

  // 等待LSR中的发送寄存器为空标识被置位
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    ;
  
  // 立即通过UART发送字符
  WriteReg(THR, c);
  
  // 恢复之前的中断状态
  pop_off();
}

// if the UART is idle, and a character is waiting
// in the transmit buffer, send it.
// caller must hold uart_tx_lock.
// called from both the top- and bottom-half.
// void
// uartstart()
// {
//   while(1){
//     if(uart_tx_w == uart_tx_r){
//       // transmit buffer is empty.
//       return;
//     }
    
//     if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
//       // the UART transmit holding register is full,
//       // so we cannot give it another byte.
//       // it will interrupt when it's ready for a new byte.
//       return;
//     }
    
//     int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
//     uart_tx_r += 1;
    
//     // maybe uartputc() is waiting for space in the buffer.
//     wakeup(&uart_tx_r);
    
//     WriteReg(THR, c);
//   }
// }

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
  if(ReadReg(LSR) & 0x01){
    // input data is ready.
    return ReadReg(RHR);
  } else {
    return -1;
  }
}

// 处理一个uart中断，当有输入到来或者
// uart准备好发送更多输出时触发，或二者同时发生
// 此函数在trap.c中被调用
// 注意两种情况下会触发此函数：
// 1.输入通道RX为满(即键盘有数据输入)
// 2.输出通道TX为空
void
uartintr(void)
{
  // // 读取和处理到来的字符，对应RX为满的中断
  // while(1){
  // 	// 使用uartgetc获取字符
  // 	// 没有获取到时跳出循环
  //   int c = uartgetc();
  //   if(c == -1)
  //     break;
    
  //   // 调用consoleintr函数
  //   // 这个函数会负责将输入的字符放入console缓冲区
  //   // 并实时回显用户输入的字符
  //   // 如果一整行已经到达或者是EOF触发或者缓冲区满
  //   // 则更新写指针到编辑指针的位置，详情见下
  //   consoleintr(c);
  // }

  // // 异步发送缓冲区中的字符，对应TX为空的中断
  // acquire(&uart_tx_lock);
  // uartstart();
  // release(&uart_tx_lock);
  
  while(1)
  {
    int c = uartgetc();
    if(c == -1) break;
    consputc(c);
  }
}


void uart_putc(char c) {
    volatile char *uart = (volatile char *)0x10000000; // volatile的作用是阻止优化，强制每次访问都从内存读取/写入
    while ((uart[5] & 0x20) == 0); // 等待 UART 就绪
    uart[0] = c;
}

void uart_puts(char *s) {
    while (*s != '\0') {  // 遍历字符串直到遇到结束符 '\0'
        uart_putc(*s);    // 输出当前字符
        s++;              // 移动到下一个字符
    }
}
