#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "proc.h"
#include "sleeplock.h"
#include "fs.h"
#include "buf.h"
#include "file.h"
#include "proc-h/proc.h"
#include "cpu.h"

struct superblock sb;

void assert(int condition, char *msg) {
    if (!condition) panic(msg);
}

static void
readsb(int dev, struct superblock *sb)
{
  struct buf *bp;
  bp = bread(dev, 1);
  memmove(sb, bp->data, sizeof(*sb));
  brelse(bp);
}

bool blockcmp(void *a, void *b) {
    return memcmp(a, b, BSIZE * 2) == 0;
}

void fsinit(int dev)
{
  readsb(dev, &sb);
  if (sb.magic != FSMAGIC)
    panic("invalid file system");
  initlog(dev, &sb);

  // 获取根目录
  printf("fsinit: starting directory test\n");

  begin_op();
  struct inode* ip = iget(dev, ROOTINO);
  ilock(ip);

  // 第一次查看
  dir_print(ip);

  // Allocate valid inodes for testing
  struct inode *ip_a = ialloc(dev, T_FILE);
  ilock(ip_a);
  ip_a->nlink = 1;
  iupdate(ip_a);
  iunlock(ip_a);
  
  struct inode *ip_b = ialloc(dev, T_FILE);
  ilock(ip_b);
  ip_b->nlink = 1;
  iupdate(ip_b);
  iunlock(ip_b);

  struct inode *ip_c = ialloc(dev, T_FILE);
  ilock(ip_c);
  ip_c->nlink = 1;
  iupdate(ip_c);
  iunlock(ip_c);

  // add entry
  if(dirlink(ip, "a.txt", ip_a->inum) < 0) panic("dirlink a.txt failed");
  if(dirlink(ip, "b.txt", ip_b->inum) < 0) panic("dirlink b.txt failed");
  if(dirlink(ip, "c.txt", ip_c->inum) < 0) panic("dirlink c.txt failed");

  // 第二次查看
  dir_print(ip);

  // 第一次检查
  struct inode *tmp;
  if((tmp = dirlookup(ip, "b.txt", 0)) == 0) panic("dirlookup b.txt failed");
  if(tmp->inum != ip_b->inum) panic("b.txt inum mismatch");
  iput(tmp); 

  // delete entry
  if(dir_unlink(ip, "a.txt") < 0) panic("dir_unlink a.txt failed");

  // 第三次查看
  dir_print(ip);

  // add entry
  struct inode *ip_d = ialloc(dev, T_FILE);
  ilock(ip_d);
  ip_d->nlink = 1;
  iupdate(ip_d);
  iunlock(ip_d);
  
  if(dirlink(ip, "d.txt", ip_d->inum) < 0) panic("dirlink d.txt failed");

  // 第四次查看
  dir_print(ip);

  // 第二次检查
  // dirlink should fail if entry exists
  if(dirlink(ip, "d.txt", ip_d->inum) == 0) panic("dirlink d.txt should fail");

  iunlockput(ip);
  
  // Release references to allocated inodes
  iput(ip_a);
  iput(ip_b);
  iput(ip_c);
  iput(ip_d);

  end_op();

  printf("dir test success\n");

  while (1);
}
