# REPORT

##  Specification 1

### Implementing strace:
1. Added syscall (`trace`) definitions (in the same format as the other syscalls given) to:
    * `syscall.h`
    * `syscall.c`
    * `usys.pl`
2. Added syscall (`trace`) definition with 2 arguments to `user.h`
3. Added arrays for easy access to syscall names (`char* sysnames`) and no of arguments(`int sysargs`) in the `syscall` function to be able to trace properly
4. Added `p->trac_stat` to `struct proc` in order to detect if the `trace` syscall was called and changed `procalloc` and `freeproc` to initialize and decomission, respectively, `p->trac_stat` to 0.
5. Added the code for the `trace` syscall to sysproc:
    ```C
    uint64
    sys_trace(void){
    int x;
    argint(0,&x);
    // printf("Syscall number: %d \n",x);
  
    myproc()->trac_stat = x;
  
    return 0;
    }
    ```
    If trace is called, it changes  `p->trac_stat` to the argument passed in trace (if it is a valid argument).
6. Added the code to print the syscall (according to the given instructions in the assignment) in the `syscall` function as that is what handles calling of all syscalls.
    Updated part of the function:
    ```C
    if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {

    // prints the function before executing (to take care of printing exit, as it doesn't return), and also taking care of printing trace as p->trac_stat hasn't been changed yet 
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
      printf("%d: syscall %s (",p->pid,sysnames[num]);
      if(sysargs[num]==0){
        printf(")");
      }
      else{
        for(int i=0;i<sysargs[num];i++){
          printf("%d ",argraw(i));
        }
        printf("\b)");
      }

      if(num==SYS_exit){
        printf("\n");
      }
    }

    //executes the syscall function
    p->trapframe->a0 = syscalls[num]();

    //printing return value
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
      printf(" -> %d\n",p->trapframe->a0);
    }
    ```
7. Added `strace.c` user program to user.h and made corresponding change in the makefile

    <b>strace.h</b>
    ```C
    #include "../kernel/types.h"
    #include "user.h"

    int main(int argc, char** argv){
        if(argc<=2){
            printf("strace: Too few arguments\n");
            return -1;
        }

        int mask = atoi(argv[1]);
        // printf("%d\n",mask);

        //if mask is negative
        if(argv[1][0]=='-'){
            printf("strace: Invalid bitmask\n");
            return -1;
        }
        
        trace(mask);

        exec(argv[2], (argv + 2));

        return 0;
    }
    ```

    <b>change in makefile</b>
    ```S
    $U/_strace\
    ```


### Implementing sigalarm and sigreturn:

1. Added syscalls (`sigalarm` & `sigreturn`) definitions (in the same format as the other syscalls given) to:
    * `syscall.h`
    * `syscall.c`
    * `usys.pl`
2. Added syscall (`sigalarm`) with 2 arguments and syscall (`sigreturn`) with no arguments' definitions to `user.h`
3. Added the following values to `struct proc`:
    * `int nticks` : stores the number of ticks the process has gone through since calling the alarm function / alarm handler (it gets reset after calling the handler)
    * `int alarm_lock` : ensures that nticks isn't incremented while the alarm handler is running (may cause an infinite recursion)
    * `int ticklim` : stores the first argument of the sigalarm syscall, the number of ticks after which the handler must be called
    * `uint64 fn` : stores the pointer to the alarm handler - must be uint64 since we will be adding it to the program counter of the current process (to run it immediately after it gets allocated to some processor), and the pc only takes uint64 values.
    * `struct trapframe *trapframecpy` : stores a copy of the registers of the process before adding the alarm handler to the pc in order to be able to restore it when sigreturn is called.
4. Made corresponding changes to the `procalloc` and `freeproc` functions, in order to initialize and decomission the above variables.
5. Added the `sigalarm` function to `sysproc`:
    ```C
    uint64
    sys_sigalarm(void){

    // printf("Alarm handler called\n");

    struct proc* p = myproc();
    
    int n;
    uint64 fn;

    argint(0, &n);
    argaddr(1,&fn);

    p->ticklim = n;
    p->nticks = 0;
    p->fn = fn;

    return 0;

    }
    ```
6. Added the `sigreturn` function to `sysproc`:
    ```C
    uint64
    sys_sigreturn(void){
    struct proc* p = myproc();
    *(p->trapframe) = *(p->trapframecpy);
    // kfree((void*)p->trapframecpy);
    p->alarm_lock = 0;
    return 0;
    }
    ```
    **Note:** we need to make a change in the `syscall` function too, as sigreturn edits trapframe->a0 to store the return value, which we must restore to `p->trapframecpy->a0` before freeing it:
    ```C
    if(num==SYS_sigreturn){
      p->trapframe->a0 = p->trapframecpy->a0;
      kfree((void*)p->trapframecpy);
    }
    ```
7. Added the following code under `if(which_dev==2)` (a timer interrupt was raised) under `usertrap` (user functions are the only ones calling sigalarm and sigreturn) in order to take care of incrementing `p->nticks` and adding the handler function to the pc if required:
    ```C
    if(which_dev == 2){
        if(p->ticklim>0 && !p->alarm_lock){
            p->nticks++;
            // p->ticks_prev = ticks;
            if(p->nticks==p->ticklim){
                // printf("Executing function\n");
                // printf("%d\n",p->nticks);
                p->alarm_lock = 1;
                p->nticks = 0;
                p->trapframecpy = (struct trapframe *)kalloc();
                *(p->trapframecpy) = *(p->trapframe);
                p->trapframe->epc = p->fn;
                // printf("Function finished executing\n");
            }
        }
        // printf("Yielded\n");
        yield();
    }
    ```