#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "spinlock.h"
#include "proc-h/proc.h"


// Create an empty user page table (just a zeroed root page-table page).
pagetable_t
uvmcreate(void)
{
  pagetable_t pagetable = (pagetable_t)kalloc(true);
  if(pagetable)
    memset(pagetable, 0, PGSIZE);
  return pagetable;
}

void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if (sz >= PGSIZE)
    panic("uvmfirst: more than a page");
  mem = kalloc(1);
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
  memmove(mem, src, sz);
}

// 检查虚拟地址是否页对齐
static inline int
is_page_aligned(uint64 addr)
{
  return (addr % PGSIZE) == 0;
}


// 检查PTE是否有效
static inline int
is_pte_valid(pte_t pte)
{
  return (pte & PTE_V) != 0;
}

// 验证页面映射的完整性
static inline void
validate_page_mapping(pte_t pte)
{
  if (!is_pte_valid(pte))
    panic("uvmunmap: page not mapped");
  if (PTE_FLAGS(pte) == PTE_V)
    panic("uvmunmap: not a leaf page");
}

// 从PTE获取物理地址并释放对应的物理页面
static inline void
free_physical_page_from_pte(pte_t pte)
{
  uint64 pa = PTE2PA(pte);
  kfree(pa,0);
}

// 清除PTE，使其无效
static inline void
clear_pte(pte_t *pte)
{
  *pte = 0;
}

// 分配PTE和物理内存以将进程从oldsz增长到
// newsz，不需要页面对齐。返回新大小或错误时返回0
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz, int xperm)
{
  char *mem;
  uint64 a;

  if (newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for (a = oldsz; a < newsz; a += PGSIZE)
  {
    mem = kalloc(0);
    if (mem == 0)
    {
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    {
      kfree((uint64)mem,0);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}

// 释放用户页面以将进程大小从oldsz减少到
// newsz。oldsz和newsz不需要页面对齐，newsz也
// 不需要小于oldsz。oldsz可以大于实际
// 进程大小。返回新的进程大小
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if (newsz >= oldsz)
    return oldsz;

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
  {
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// 从va开始移除npages个映射。va必须是
// 页面对齐的。映射必须存在。
// 可选择释放物理内存
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 current_va;
  pte_t *pte;

  if (!is_page_aligned(va))
    panic("uvmunmap: address not page aligned");

  for (current_va = va; current_va < va + npages * PGSIZE; current_va += PGSIZE)
  {
    pte = walk(pagetable, current_va, 0);
    if (pte == 0)
      panic("uvmunmap: walk failed");

    validate_page_mapping(*pte);

    if (do_free)
    {
      free_physical_page_from_pte(*pte);
    }

    clear_pte(pte);
  }
}

static inline uint64
bytes_to_copy_in_page(uint64 va, uint64 remaining_len)
{
  uint64 page_offset = va - PGROUNDDOWN(va);
  uint64 bytes_in_page = PGSIZE - page_offset;
  return (bytes_in_page > remaining_len) ? remaining_len : bytes_in_page;
}

// 用户态地址空间[src, src+len) 拷贝至 内核态地址空间[dst, dst+len)
// 注意: src dst 不一定是 page-aligned
// 成功返回0，失败返回-1
int uvm_copyin(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
  {
    page_va = PGROUNDDOWN(srcva);
    page_pa = walkaddr(pgtbl, page_va);
    if (page_pa == 0)
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove((void *)dst, (void *)(page_pa + src_offset), bytes_to_copy);

    len -= bytes_to_copy;
    dst += bytes_to_copy;
    srcva = page_va + PGSIZE; // 移到下一页
  }
  return 0;
}

// 内核态地址空间[src, src+len） 拷贝至 用户态地址空间[dst, dst+len)
// 成功返回0，失败返回-1
int uvm_copyout(pgtbl_t pgtbl, uint64 dstva, uint64 src, uint32 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
  {
    page_va = PGROUNDDOWN(dstva);
    page_pa = walkaddr(pgtbl, page_va);
    if (page_pa == 0)
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), (void *)src, bytes_to_copy);

    len -= bytes_to_copy;
    src += bytes_to_copy;
    dstva = page_va + PGSIZE; // 移到下一页
  }
  return 0;
}

// 用户态字符串拷贝到内核态
// 最多拷贝maxlen字节, 中途遇到'\0'则终止
// 注意: src dst 不一定是 page-aligned
// 成功返回0，失败返回-1
int uvm_copyin_str(pgtbl_t pgtbl, uint64 dst, uint64 srcva, uint32 maxlen)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && maxlen > 0)
  {
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pgtbl, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if (n > maxlen)
      n = maxlen;

    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *(char*)dst = '\0';
        got_null = 1;
        break;
      }
      else
      {
        *(char*)dst = *p;
      }
      --n;
      --maxlen;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
  {
    return 0;
  }
  else
  {
    return -1;
  }
}

// 计算给定大小需要的页面数量
static inline uint64
calculate_pages_needed(uint64 size)
{
  return PGROUNDUP(size) / PGSIZE;
}

// 释放用户内存页面，然后释放页表页面
void uvmfree(pagetable_t pagetable, uint64 sz)
{
  if (sz > 0)
  {
    uint64 npages = calculate_pages_needed(sz);
    uvmunmap(pagetable, 0, npages, 1);
  }
  freewalk(pagetable);
}


// 从内核复制到用户
// 将len字节从src复制到给定页表中的虚拟地址dstva
// 成功返回0，错误返回-1
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
  {
    page_va = PGROUNDDOWN(dstva);
    page_pa = walkaddr(pagetable, page_va);
    if (page_pa == 0)
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(dstva, len);

    uint64 dest_offset = dstva - page_va;
    memmove((void *)(page_pa + dest_offset), src, bytes_to_copy);

    len -= bytes_to_copy;
    src += bytes_to_copy;
    dstva = page_va + PGSIZE; // 移到下一页
  }
  return 0;
}

// 从用户复制到内核
// 将len字节从给定页表中的虚拟地址srcva复制到dst
// 成功返回0，错误返回-1
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 bytes_to_copy, page_va, page_pa;

  while (len > 0)
  {
    page_va = PGROUNDDOWN(srcva);
    page_pa = walkaddr(pagetable, page_va);
    if (page_pa == 0)
      return -1; // 页面映射不存在或不可访问

    bytes_to_copy = bytes_to_copy_in_page(srcva, len);

    uint64 src_offset = srcva - page_va;
    memmove(dst, (void *)(page_pa + src_offset), bytes_to_copy);

    len -= bytes_to_copy;
    dst += bytes_to_copy;
    srcva = page_va + PGSIZE; // 移到下一页
  }
  return 0;
}

// 从用户复制一个以null结尾的字符串到内核
// 将字节从给定页表中的虚拟地址srcva复制到dst，
// 直到遇到'\0'或达到max
// 成功返回0，错误返回-1
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
  {
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if (n > max)
      n = max;

    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
        got_null = 1;
        break;
      }
      else
      {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
  {
    return 0;
  }
  else
  {
    return -1;
  }
}
