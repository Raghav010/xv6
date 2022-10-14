#include "queue.h"
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct q_node* q_node_init(struct proc* curr){
    struct q_node* node = (struct q_node*)kalloc();
    node->process = curr;
    node->next = 0;
    node->prev = 0;
    return node;
}

struct queue* queueinit(){
    struct queue* q = (struct queue*)kalloc();
    q->head = 0;
    q->tail = q->head;
    q->size = 0;
    return q;
}

struct q_node* q_pop(struct queue* q){
    q->size--;
    struct q_node* head = q->head;
    q->head = q->head->next;
    if(q->head != 0){
        q->head->prev = 0;
    }
    head->next = 0;
    return head;
}

void q_push_front(struct queue* q, struct q_node* curr){
    q->size++;
    if(q->size==1){
        q->head = curr;
        q->tail = curr;
        return;
    }
    q->head->prev = curr;
    curr->next = q->head;
    q->head = curr;
    return;
}

void q_push_back(struct queue* q, struct q_node* curr){
    q->size++;
    if(q->size==1){
        q->head = curr;
        q->tail = curr;
        return;
    }
    q->tail->next = curr;
    curr->prev = q->tail;
    q->tail = curr;
    return;
}

void free_q_node(struct q_node* node){
    if(node==0){
        return;
    }
    if(node->prev!=0){
        node->prev->next = node->next;
    }
    if(node->next!=0){
        node->next->prev = node->prev;
    }
    kfree((void*)node);
}

void free_q(struct queue* q){
    while(q->size!=0){
        free_q_node(q_pop(q));
        q->size--;
    }
    kfree((void*)q);
}