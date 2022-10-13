#ifndef _QUEUE_
#define _QUEUE_

#include "proc.h"

struct q_node{
    struct proc* process;
    struct q_node* next;
    struct q_node* prev;
};

struct queue{
    struct q_node* head;
    struct q_node* tail;
    int size;
};

struct q_node* q_node_init(struct proc* curr);
struct queue* queueinit();
struct q_node* q_pop(struct queue* q);
void q_push_front(struct queue* q, struct q_node* curr);
void q_push_back(struct queue* q, struct q_node* curr);
void free_q_node(struct q_node* node);
void free_q(struct queue* q);

#endif