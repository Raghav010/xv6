#include "../kernel/types.h"
#include "user.h"

int main(int argc, char** argv){
    if(argc<=2){
        printf("strace: Too few arguments\n");
        return 1;
    }
    
    trace(atoi(argv[1]));

    exec(argv[2], (argv + 2));

    return 0;
}