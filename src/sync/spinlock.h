// Simple spinlock with minimal dependencies.
#ifndef SPINLOCK_H
#define SPINLOCK_H

#include "types.h"   // for uint

struct cpu; // forward declaration

// Mutual exclusion lock.
typedef struct spinlock {
  uint locked;       // Is the lock held?

  // For debugging:
  char *name;        // Name of lock.
  struct cpu *cpu;   // The cpu holding the lock.
}spinlock_t;

#endif // SPINLOCK_H

