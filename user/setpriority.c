#include "../kernel/types.h"
#include "user.h"

int main(int argc, char** argv){
    if(argc!=3){
        printf("setpriority: invalid number of arguments");
        exit(0);
    }
    set_priority(atoi(argv[1]),atoi(argv[2]));
    exit(0);
}