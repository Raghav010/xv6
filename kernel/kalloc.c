// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

int n_using[(PGROUNDUP(PHYSTOP)/PGSIZE)];
struct spinlock n_using_lock;

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void increment_n_using(uint64 pno){
  acquire(&n_using_lock);
  if(n_using[pno]<0){
    release(&n_using_lock);
    panic("Increment problem");
  }
  else{
    n_using[pno]++;
    release(&n_using_lock);
  }

}

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  initlock(&n_using_lock,"n_using lock");
  acquire(&n_using_lock);
  for(int i=0; i<(PGROUNDUP(PHYSTOP)/PGSIZE); i++){
    n_using[i] = 1;
  }
  release(&n_using_lock);
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  // if(((uint64)pa % PGSIZE) != 0 )
  //   panic("kfree2");
  // else if((char*)pa < end)
  //   panic("kfree1");
  // else if((uint64)pa >= PHYSTOP){
  //   // printf("%d %d\n",(uint64)pa,PHYSTOP);
  //   panic("kfree");
  // }

  // If n_using of pa > 1, we cannot free that memory space
  acquire(&n_using_lock);
  if(n_using[(uint64)pa/PGSIZE]>1){
    if(n_using[(uint64)pa/PGSIZE]<=0){
      panic("What??3");
    }
    else{
      n_using[(uint64)pa/PGSIZE]--;
    }
    release(&n_using_lock);
    return;
  }

  if(n_using[(uint64)pa/PGSIZE]<=0){
    panic("What??2");
  }
  else{
    n_using[(uint64)pa/PGSIZE]--;
  }
  release(&n_using_lock);

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk

  if(r){
    increment_n_using((uint64)r/PGSIZE);
  }
  
  return (void*)r;
}
