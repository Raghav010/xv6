#include "../kernel/types.h"
#include "user.h"

int main(int argc, char** argv){
    if(argc<=2){
        printf("strace: Too few arguments\n");
        exit(0);
    }

    int mask = atoi(argv[1]);
    // printf("%d\n",mask);

    if(argv[1][0]=='-'){
        printf("strace: Invalid bitmask\n");
        exit(0);
    }
    
    trace(mask);

    exec(argv[2], (argv + 2));

    exit(0);
}