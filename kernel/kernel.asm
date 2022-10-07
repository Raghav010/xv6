
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c1010113          	addi	sp,sp,-1008 # 80008c10 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	a7e70713          	addi	a4,a4,-1410 # 80008ad0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cec78793          	addi	a5,a5,-788 # 80005d50 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc8bf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3a4080e7          	jalr	932(ra) # 800024d0 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	a8450513          	addi	a0,a0,-1404 # 80010c10 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	a7448493          	addi	s1,s1,-1420 # 80010c10 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b0290913          	addi	s2,s2,-1278 # 80010ca8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	14e080e7          	jalr	334(ra) # 8000231a <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	e98080e7          	jalr	-360(ra) # 80002072 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	264080e7          	jalr	612(ra) # 8000247a <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	9e650513          	addi	a0,a0,-1562 # 80010c10 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	9d050513          	addi	a0,a0,-1584 # 80010c10 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	a2f72823          	sw	a5,-1488(a4) # 80010ca8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	93e50513          	addi	a0,a0,-1730 # 80010c10 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	22e080e7          	jalr	558(ra) # 80002526 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	91050513          	addi	a0,a0,-1776 # 80010c10 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	8ec70713          	addi	a4,a4,-1812 # 80010c10 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	8c278793          	addi	a5,a5,-1854 # 80010c10 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	92c7a783          	lw	a5,-1748(a5) # 80010ca8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	88070713          	addi	a4,a4,-1920 # 80010c10 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	87048493          	addi	s1,s1,-1936 # 80010c10 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	83470713          	addi	a4,a4,-1996 # 80010c10 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	8af72f23          	sw	a5,-1858(a4) # 80010cb0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	7f878793          	addi	a5,a5,2040 # 80010c10 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	86c7a823          	sw	a2,-1936(a5) # 80010cac <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	86450513          	addi	a0,a0,-1948 # 80010ca8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	c8a080e7          	jalr	-886(ra) # 800020d6 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	7aa50513          	addi	a0,a0,1962 # 80010c10 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	92a78793          	addi	a5,a5,-1750 # 80020da8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	7807a023          	sw	zero,1920(a5) # 80010cd0 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	50f72623          	sw	a5,1292(a4) # 80008a90 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	710dad83          	lw	s11,1808(s11) # 80010cd0 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	6ba50513          	addi	a0,a0,1722 # 80010cb8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	55650513          	addi	a0,a0,1366 # 80010cb8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	53a48493          	addi	s1,s1,1338 # 80010cb8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	4fa50513          	addi	a0,a0,1274 # 80010cd8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	2867a783          	lw	a5,646(a5) # 80008a90 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	25273703          	ld	a4,594(a4) # 80008a98 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2527b783          	ld	a5,594(a5) # 80008aa0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	468a0a13          	addi	s4,s4,1128 # 80010cd8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	22048493          	addi	s1,s1,544 # 80008a98 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	22098993          	addi	s3,s3,544 # 80008aa0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	830080e7          	jalr	-2000(ra) # 800020d6 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	3f650513          	addi	a0,a0,1014 # 80010cd8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	19e7a783          	lw	a5,414(a5) # 80008a90 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1a47b783          	ld	a5,420(a5) # 80008aa0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	19473703          	ld	a4,404(a4) # 80008a98 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	3c8a0a13          	addi	s4,s4,968 # 80010cd8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	18048493          	addi	s1,s1,384 # 80008a98 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	18090913          	addi	s2,s2,384 # 80008aa0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	742080e7          	jalr	1858(ra) # 80002072 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	39248493          	addi	s1,s1,914 # 80010cd8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	14f73323          	sd	a5,326(a4) # 80008aa0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	30848493          	addi	s1,s1,776 # 80010cd8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	52e78793          	addi	a5,a5,1326 # 80021f40 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	2de90913          	addi	s2,s2,734 # 80010d10 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	24250513          	addi	a0,a0,578 # 80010d10 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	45e50513          	addi	a0,a0,1118 # 80021f40 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	20c48493          	addi	s1,s1,524 # 80010d10 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	1f450513          	addi	a0,a0,500 # 80010d10 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	1c850513          	addi	a0,a0,456 # 80010d10 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	c0470713          	addi	a4,a4,-1020 # 80008aa8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	78c080e7          	jalr	1932(ra) # 80002666 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	eae080e7          	jalr	-338(ra) # 80005d90 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fd6080e7          	jalr	-42(ra) # 80001ec0 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	6ec080e7          	jalr	1772(ra) # 8000263e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	70c080e7          	jalr	1804(ra) # 80002666 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e18080e7          	jalr	-488(ra) # 80005d7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	e26080e7          	jalr	-474(ra) # 80005d90 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	fe0080e7          	jalr	-32(ra) # 80002f52 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	684080e7          	jalr	1668(ra) # 800035fe <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	622080e7          	jalr	1570(ra) # 800045a4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	f0e080e7          	jalr	-242(ra) # 80005e98 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d14080e7          	jalr	-748(ra) # 80001ca6 <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b0f72423          	sw	a5,-1272(a4) # 80008aa8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	afc7b783          	ld	a5,-1284(a5) # 80008ab0 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00008797          	auipc	a5,0x8
    80001274:	84a7b023          	sd	a0,-1984(a5) # 80008ab0 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	8fa48493          	addi	s1,s1,-1798 # 80011160 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	2e0a0a13          	addi	s4,s4,736 # 80016b60 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	16848493          	addi	s1,s1,360
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	42e50513          	addi	a0,a0,1070 # 80010d30 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	42e50513          	addi	a0,a0,1070 # 80010d48 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	83648493          	addi	s1,s1,-1994 # 80011160 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	21498993          	addi	s3,s3,532 # 80016b60 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	16848493          	addi	s1,s1,360
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	3aa50513          	addi	a0,a0,938 # 80010d60 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	35270713          	addi	a4,a4,850 # 80010d30 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	02a7a783          	lw	a5,42(a5) # 80008a40 <first.1679>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	c5e080e7          	jalr	-930(ra) # 8000267e <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	0007a823          	sw	zero,16(a5) # 80008a40 <first.1679>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	b44080e7          	jalr	-1212(ra) # 8000357e <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	2e090913          	addi	s2,s2,736 # 80010d30 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	fe278793          	addi	a5,a5,-30 # 80008a44 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->trac_stat = 0;
    80001bae:	0204aa23          	sw	zero,52(s1)
  p->parent = 0;
    80001bb2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bba:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bbe:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc6:	0004ac23          	sw	zero,24(s1)
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6105                	addi	sp,sp,32
    80001bd2:	8082                	ret

0000000080001bd4 <allocproc>:
{
    80001bd4:	1101                	addi	sp,sp,-32
    80001bd6:	ec06                	sd	ra,24(sp)
    80001bd8:	e822                	sd	s0,16(sp)
    80001bda:	e426                	sd	s1,8(sp)
    80001bdc:	e04a                	sd	s2,0(sp)
    80001bde:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be0:	0000f497          	auipc	s1,0xf
    80001be4:	58048493          	addi	s1,s1,1408 # 80011160 <proc>
    80001be8:	00015917          	auipc	s2,0x15
    80001bec:	f7890913          	addi	s2,s2,-136 # 80016b60 <tickslock>
    acquire(&p->lock);
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	ff8080e7          	jalr	-8(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bfa:	4c9c                	lw	a5,24(s1)
    80001bfc:	cf81                	beqz	a5,80001c14 <allocproc+0x40>
      release(&p->lock);
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	09e080e7          	jalr	158(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c08:	16848493          	addi	s1,s1,360
    80001c0c:	ff2492e3          	bne	s1,s2,80001bf0 <allocproc+0x1c>
  return 0;
    80001c10:	4481                	li	s1,0
    80001c12:	a899                	j	80001c68 <allocproc+0x94>
  p->pid = allocpid();
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e30080e7          	jalr	-464(ra) # 80001a44 <allocpid>
    80001c1c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1e:	4785                	li	a5,1
    80001c20:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	ed8080e7          	jalr	-296(ra) # 80000afa <kalloc>
    80001c2a:	892a                	mv	s2,a0
    80001c2c:	eca8                	sd	a0,88(s1)
    80001c2e:	c521                	beqz	a0,80001c76 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    80001c30:	8526                	mv	a0,s1
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	e58080e7          	jalr	-424(ra) # 80001a8a <proc_pagetable>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3e:	c921                	beqz	a0,80001c8e <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c40:	07000613          	li	a2,112
    80001c44:	4581                	li	a1,0
    80001c46:	06048513          	addi	a0,s1,96
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	09c080e7          	jalr	156(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c52:	00000797          	auipc	a5,0x0
    80001c56:	dac78793          	addi	a5,a5,-596 # 800019fe <forkret>
    80001c5a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5c:	60bc                	ld	a5,64(s1)
    80001c5e:	6705                	lui	a4,0x1
    80001c60:	97ba                	add	a5,a5,a4
    80001c62:	f4bc                	sd	a5,104(s1)
  p->trac_stat = 0;
    80001c64:	0204aa23          	sw	zero,52(s1)
}
    80001c68:	8526                	mv	a0,s1
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6902                	ld	s2,0(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret
    freeproc(p);
    80001c76:	8526                	mv	a0,s1
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f00080e7          	jalr	-256(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	01c080e7          	jalr	28(ra) # 80000c9e <release>
    return 0;
    80001c8a:	84ca                	mv	s1,s2
    80001c8c:	bff1                	j	80001c68 <allocproc+0x94>
    freeproc(p);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	ee8080e7          	jalr	-280(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	004080e7          	jalr	4(ra) # 80000c9e <release>
    return 0;
    80001ca2:	84ca                	mv	s1,s2
    80001ca4:	b7d1                	j	80001c68 <allocproc+0x94>

0000000080001ca6 <userinit>:
{
    80001ca6:	1101                	addi	sp,sp,-32
    80001ca8:	ec06                	sd	ra,24(sp)
    80001caa:	e822                	sd	s0,16(sp)
    80001cac:	e426                	sd	s1,8(sp)
    80001cae:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	f24080e7          	jalr	-220(ra) # 80001bd4 <allocproc>
    80001cb8:	84aa                	mv	s1,a0
  initproc = p;
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	dea7bf23          	sd	a0,-514(a5) # 80008ab8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc2:	03400613          	li	a2,52
    80001cc6:	00007597          	auipc	a1,0x7
    80001cca:	d8a58593          	addi	a1,a1,-630 # 80008a50 <initcode>
    80001cce:	6928                	ld	a0,80(a0)
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	6a2080e7          	jalr	1698(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cd8:	6785                	lui	a5,0x1
    80001cda:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cdc:	6cb8                	ld	a4,88(s1)
    80001cde:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce2:	6cb8                	ld	a4,88(s1)
    80001ce4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce6:	4641                	li	a2,16
    80001ce8:	00006597          	auipc	a1,0x6
    80001cec:	51858593          	addi	a1,a1,1304 # 80008200 <digits+0x1c0>
    80001cf0:	15848513          	addi	a0,s1,344
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	144080e7          	jalr	324(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001cfc:	00006517          	auipc	a0,0x6
    80001d00:	51450513          	addi	a0,a0,1300 # 80008210 <digits+0x1d0>
    80001d04:	00002097          	auipc	ra,0x2
    80001d08:	29c080e7          	jalr	668(ra) # 80003fa0 <namei>
    80001d0c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d10:	478d                	li	a5,3
    80001d12:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	f88080e7          	jalr	-120(ra) # 80000c9e <release>
}
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6105                	addi	sp,sp,32
    80001d26:	8082                	ret

0000000080001d28 <growproc>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	e04a                	sd	s2,0(sp)
    80001d32:	1000                	addi	s0,sp,32
    80001d34:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	c90080e7          	jalr	-880(ra) # 800019c6 <myproc>
    80001d3e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d40:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d42:	01204c63          	bgtz	s2,80001d5a <growproc+0x32>
  } else if(n < 0){
    80001d46:	02094663          	bltz	s2,80001d72 <growproc+0x4a>
  p->sz = sz;
    80001d4a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d5a:	4691                	li	a3,4
    80001d5c:	00b90633          	add	a2,s2,a1
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	6ca080e7          	jalr	1738(ra) # 8000142c <uvmalloc>
    80001d6a:	85aa                	mv	a1,a0
    80001d6c:	fd79                	bnez	a0,80001d4a <growproc+0x22>
      return -1;
    80001d6e:	557d                	li	a0,-1
    80001d70:	bff9                	j	80001d4e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d72:	00b90633          	add	a2,s2,a1
    80001d76:	6928                	ld	a0,80(a0)
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	66c080e7          	jalr	1644(ra) # 800013e4 <uvmdealloc>
    80001d80:	85aa                	mv	a1,a0
    80001d82:	b7e1                	j	80001d4a <growproc+0x22>

0000000080001d84 <fork>:
{
    80001d84:	7179                	addi	sp,sp,-48
    80001d86:	f406                	sd	ra,40(sp)
    80001d88:	f022                	sd	s0,32(sp)
    80001d8a:	ec26                	sd	s1,24(sp)
    80001d8c:	e84a                	sd	s2,16(sp)
    80001d8e:	e44e                	sd	s3,8(sp)
    80001d90:	e052                	sd	s4,0(sp)
    80001d92:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	c32080e7          	jalr	-974(ra) # 800019c6 <myproc>
    80001d9c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d9e:	00000097          	auipc	ra,0x0
    80001da2:	e36080e7          	jalr	-458(ra) # 80001bd4 <allocproc>
    80001da6:	10050b63          	beqz	a0,80001ebc <fork+0x138>
    80001daa:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dac:	04893603          	ld	a2,72(s2)
    80001db0:	692c                	ld	a1,80(a0)
    80001db2:	05093503          	ld	a0,80(s2)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	7ca080e7          	jalr	1994(ra) # 80001580 <uvmcopy>
    80001dbe:	04054663          	bltz	a0,80001e0a <fork+0x86>
  np->sz = p->sz;
    80001dc2:	04893783          	ld	a5,72(s2)
    80001dc6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dca:	05893683          	ld	a3,88(s2)
    80001dce:	87b6                	mv	a5,a3
    80001dd0:	0589b703          	ld	a4,88(s3)
    80001dd4:	12068693          	addi	a3,a3,288
    80001dd8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ddc:	6788                	ld	a0,8(a5)
    80001dde:	6b8c                	ld	a1,16(a5)
    80001de0:	6f90                	ld	a2,24(a5)
    80001de2:	01073023          	sd	a6,0(a4)
    80001de6:	e708                	sd	a0,8(a4)
    80001de8:	eb0c                	sd	a1,16(a4)
    80001dea:	ef10                	sd	a2,24(a4)
    80001dec:	02078793          	addi	a5,a5,32
    80001df0:	02070713          	addi	a4,a4,32
    80001df4:	fed792e3          	bne	a5,a3,80001dd8 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df8:	0589b783          	ld	a5,88(s3)
    80001dfc:	0607b823          	sd	zero,112(a5)
    80001e00:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e04:	15000a13          	li	s4,336
    80001e08:	a03d                	j	80001e36 <fork+0xb2>
    freeproc(np);
    80001e0a:	854e                	mv	a0,s3
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	d6c080e7          	jalr	-660(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e14:	854e                	mv	a0,s3
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	e88080e7          	jalr	-376(ra) # 80000c9e <release>
    return -1;
    80001e1e:	5a7d                	li	s4,-1
    80001e20:	a069                	j	80001eaa <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e22:	00003097          	auipc	ra,0x3
    80001e26:	814080e7          	jalr	-2028(ra) # 80004636 <filedup>
    80001e2a:	009987b3          	add	a5,s3,s1
    80001e2e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e30:	04a1                	addi	s1,s1,8
    80001e32:	01448763          	beq	s1,s4,80001e40 <fork+0xbc>
    if(p->ofile[i])
    80001e36:	009907b3          	add	a5,s2,s1
    80001e3a:	6388                	ld	a0,0(a5)
    80001e3c:	f17d                	bnez	a0,80001e22 <fork+0x9e>
    80001e3e:	bfcd                	j	80001e30 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e40:	15093503          	ld	a0,336(s2)
    80001e44:	00002097          	auipc	ra,0x2
    80001e48:	978080e7          	jalr	-1672(ra) # 800037bc <idup>
    80001e4c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e50:	4641                	li	a2,16
    80001e52:	15890593          	addi	a1,s2,344
    80001e56:	15898513          	addi	a0,s3,344
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	fde080e7          	jalr	-34(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e62:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e66:	854e                	mv	a0,s3
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e36080e7          	jalr	-458(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e70:	0000f497          	auipc	s1,0xf
    80001e74:	ed848493          	addi	s1,s1,-296 # 80010d48 <wait_lock>
    80001e78:	8526                	mv	a0,s1
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	d70080e7          	jalr	-656(ra) # 80000bea <acquire>
  np->parent = p;
    80001e82:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e16080e7          	jalr	-490(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e90:	854e                	mv	a0,s3
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d58080e7          	jalr	-680(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001e9a:	478d                	li	a5,3
    80001e9c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	dfc080e7          	jalr	-516(ra) # 80000c9e <release>
}
    80001eaa:	8552                	mv	a0,s4
    80001eac:	70a2                	ld	ra,40(sp)
    80001eae:	7402                	ld	s0,32(sp)
    80001eb0:	64e2                	ld	s1,24(sp)
    80001eb2:	6942                	ld	s2,16(sp)
    80001eb4:	69a2                	ld	s3,8(sp)
    80001eb6:	6a02                	ld	s4,0(sp)
    80001eb8:	6145                	addi	sp,sp,48
    80001eba:	8082                	ret
    return -1;
    80001ebc:	5a7d                	li	s4,-1
    80001ebe:	b7f5                	j	80001eaa <fork+0x126>

0000000080001ec0 <scheduler>:
{
    80001ec0:	7139                	addi	sp,sp,-64
    80001ec2:	fc06                	sd	ra,56(sp)
    80001ec4:	f822                	sd	s0,48(sp)
    80001ec6:	f426                	sd	s1,40(sp)
    80001ec8:	f04a                	sd	s2,32(sp)
    80001eca:	ec4e                	sd	s3,24(sp)
    80001ecc:	e852                	sd	s4,16(sp)
    80001ece:	e456                	sd	s5,8(sp)
    80001ed0:	e05a                	sd	s6,0(sp)
    80001ed2:	0080                	addi	s0,sp,64
    80001ed4:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed8:	00779a93          	slli	s5,a5,0x7
    80001edc:	0000f717          	auipc	a4,0xf
    80001ee0:	e5470713          	addi	a4,a4,-428 # 80010d30 <pid_lock>
    80001ee4:	9756                	add	a4,a4,s5
    80001ee6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001eea:	0000f717          	auipc	a4,0xf
    80001eee:	e7e70713          	addi	a4,a4,-386 # 80010d68 <cpus+0x8>
    80001ef2:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ef4:	498d                	li	s3,3
        p->state = RUNNING;
    80001ef6:	4b11                	li	s6,4
        c->proc = p;
    80001ef8:	079e                	slli	a5,a5,0x7
    80001efa:	0000fa17          	auipc	s4,0xf
    80001efe:	e36a0a13          	addi	s4,s4,-458 # 80010d30 <pid_lock>
    80001f02:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f04:	00015917          	auipc	s2,0x15
    80001f08:	c5c90913          	addi	s2,s2,-932 # 80016b60 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f10:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f14:	10079073          	csrw	sstatus,a5
    80001f18:	0000f497          	auipc	s1,0xf
    80001f1c:	24848493          	addi	s1,s1,584 # 80011160 <proc>
    80001f20:	a03d                	j	80001f4e <scheduler+0x8e>
        p->state = RUNNING;
    80001f22:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f26:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2a:	06048593          	addi	a1,s1,96
    80001f2e:	8556                	mv	a0,s5
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	6a4080e7          	jalr	1700(ra) # 800025d4 <swtch>
        c->proc = 0;
    80001f38:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d60080e7          	jalr	-672(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f46:	16848493          	addi	s1,s1,360
    80001f4a:	fd2481e3          	beq	s1,s2,80001f0c <scheduler+0x4c>
      acquire(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	c9a080e7          	jalr	-870(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f58:	4c9c                	lw	a5,24(s1)
    80001f5a:	ff3791e3          	bne	a5,s3,80001f3c <scheduler+0x7c>
    80001f5e:	b7d1                	j	80001f22 <scheduler+0x62>

0000000080001f60 <sched>:
{
    80001f60:	7179                	addi	sp,sp,-48
    80001f62:	f406                	sd	ra,40(sp)
    80001f64:	f022                	sd	s0,32(sp)
    80001f66:	ec26                	sd	s1,24(sp)
    80001f68:	e84a                	sd	s2,16(sp)
    80001f6a:	e44e                	sd	s3,8(sp)
    80001f6c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	a58080e7          	jalr	-1448(ra) # 800019c6 <myproc>
    80001f76:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	bf8080e7          	jalr	-1032(ra) # 80000b70 <holding>
    80001f80:	c93d                	beqz	a0,80001ff6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f82:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f84:	2781                	sext.w	a5,a5
    80001f86:	079e                	slli	a5,a5,0x7
    80001f88:	0000f717          	auipc	a4,0xf
    80001f8c:	da870713          	addi	a4,a4,-600 # 80010d30 <pid_lock>
    80001f90:	97ba                	add	a5,a5,a4
    80001f92:	0a87a703          	lw	a4,168(a5)
    80001f96:	4785                	li	a5,1
    80001f98:	06f71763          	bne	a4,a5,80002006 <sched+0xa6>
  if(p->state == RUNNING)
    80001f9c:	4c98                	lw	a4,24(s1)
    80001f9e:	4791                	li	a5,4
    80001fa0:	06f70b63          	beq	a4,a5,80002016 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001faa:	efb5                	bnez	a5,80002026 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fac:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fae:	0000f917          	auipc	s2,0xf
    80001fb2:	d8290913          	addi	s2,s2,-638 # 80010d30 <pid_lock>
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	97ca                	add	a5,a5,s2
    80001fbc:	0ac7a983          	lw	s3,172(a5)
    80001fc0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fc2:	2781                	sext.w	a5,a5
    80001fc4:	079e                	slli	a5,a5,0x7
    80001fc6:	0000f597          	auipc	a1,0xf
    80001fca:	da258593          	addi	a1,a1,-606 # 80010d68 <cpus+0x8>
    80001fce:	95be                	add	a1,a1,a5
    80001fd0:	06048513          	addi	a0,s1,96
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	600080e7          	jalr	1536(ra) # 800025d4 <swtch>
    80001fdc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fde:	2781                	sext.w	a5,a5
    80001fe0:	079e                	slli	a5,a5,0x7
    80001fe2:	97ca                	add	a5,a5,s2
    80001fe4:	0b37a623          	sw	s3,172(a5)
}
    80001fe8:	70a2                	ld	ra,40(sp)
    80001fea:	7402                	ld	s0,32(sp)
    80001fec:	64e2                	ld	s1,24(sp)
    80001fee:	6942                	ld	s2,16(sp)
    80001ff0:	69a2                	ld	s3,8(sp)
    80001ff2:	6145                	addi	sp,sp,48
    80001ff4:	8082                	ret
    panic("sched p->lock");
    80001ff6:	00006517          	auipc	a0,0x6
    80001ffa:	22250513          	addi	a0,a0,546 # 80008218 <digits+0x1d8>
    80001ffe:	ffffe097          	auipc	ra,0xffffe
    80002002:	546080e7          	jalr	1350(ra) # 80000544 <panic>
    panic("sched locks");
    80002006:	00006517          	auipc	a0,0x6
    8000200a:	22250513          	addi	a0,a0,546 # 80008228 <digits+0x1e8>
    8000200e:	ffffe097          	auipc	ra,0xffffe
    80002012:	536080e7          	jalr	1334(ra) # 80000544 <panic>
    panic("sched running");
    80002016:	00006517          	auipc	a0,0x6
    8000201a:	22250513          	addi	a0,a0,546 # 80008238 <digits+0x1f8>
    8000201e:	ffffe097          	auipc	ra,0xffffe
    80002022:	526080e7          	jalr	1318(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002026:	00006517          	auipc	a0,0x6
    8000202a:	22250513          	addi	a0,a0,546 # 80008248 <digits+0x208>
    8000202e:	ffffe097          	auipc	ra,0xffffe
    80002032:	516080e7          	jalr	1302(ra) # 80000544 <panic>

0000000080002036 <yield>:
{
    80002036:	1101                	addi	sp,sp,-32
    80002038:	ec06                	sd	ra,24(sp)
    8000203a:	e822                	sd	s0,16(sp)
    8000203c:	e426                	sd	s1,8(sp)
    8000203e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002040:	00000097          	auipc	ra,0x0
    80002044:	986080e7          	jalr	-1658(ra) # 800019c6 <myproc>
    80002048:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	ba0080e7          	jalr	-1120(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002052:	478d                	li	a5,3
    80002054:	cc9c                	sw	a5,24(s1)
  sched();
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	f0a080e7          	jalr	-246(ra) # 80001f60 <sched>
  release(&p->lock);
    8000205e:	8526                	mv	a0,s1
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	c3e080e7          	jalr	-962(ra) # 80000c9e <release>
}
    80002068:	60e2                	ld	ra,24(sp)
    8000206a:	6442                	ld	s0,16(sp)
    8000206c:	64a2                	ld	s1,8(sp)
    8000206e:	6105                	addi	sp,sp,32
    80002070:	8082                	ret

0000000080002072 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002072:	7179                	addi	sp,sp,-48
    80002074:	f406                	sd	ra,40(sp)
    80002076:	f022                	sd	s0,32(sp)
    80002078:	ec26                	sd	s1,24(sp)
    8000207a:	e84a                	sd	s2,16(sp)
    8000207c:	e44e                	sd	s3,8(sp)
    8000207e:	1800                	addi	s0,sp,48
    80002080:	89aa                	mv	s3,a0
    80002082:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002084:	00000097          	auipc	ra,0x0
    80002088:	942080e7          	jalr	-1726(ra) # 800019c6 <myproc>
    8000208c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	b5c080e7          	jalr	-1188(ra) # 80000bea <acquire>
  release(lk);
    80002096:	854a                	mv	a0,s2
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	c06080e7          	jalr	-1018(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020a0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020a4:	4789                	li	a5,2
    800020a6:	cc9c                	sw	a5,24(s1)

  sched();
    800020a8:	00000097          	auipc	ra,0x0
    800020ac:	eb8080e7          	jalr	-328(ra) # 80001f60 <sched>

  // Tidy up.
  p->chan = 0;
    800020b0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	be8080e7          	jalr	-1048(ra) # 80000c9e <release>
  acquire(lk);
    800020be:	854a                	mv	a0,s2
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b2a080e7          	jalr	-1238(ra) # 80000bea <acquire>
}
    800020c8:	70a2                	ld	ra,40(sp)
    800020ca:	7402                	ld	s0,32(sp)
    800020cc:	64e2                	ld	s1,24(sp)
    800020ce:	6942                	ld	s2,16(sp)
    800020d0:	69a2                	ld	s3,8(sp)
    800020d2:	6145                	addi	sp,sp,48
    800020d4:	8082                	ret

00000000800020d6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020d6:	7139                	addi	sp,sp,-64
    800020d8:	fc06                	sd	ra,56(sp)
    800020da:	f822                	sd	s0,48(sp)
    800020dc:	f426                	sd	s1,40(sp)
    800020de:	f04a                	sd	s2,32(sp)
    800020e0:	ec4e                	sd	s3,24(sp)
    800020e2:	e852                	sd	s4,16(sp)
    800020e4:	e456                	sd	s5,8(sp)
    800020e6:	0080                	addi	s0,sp,64
    800020e8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020ea:	0000f497          	auipc	s1,0xf
    800020ee:	07648493          	addi	s1,s1,118 # 80011160 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020f2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020f4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020f6:	00015917          	auipc	s2,0x15
    800020fa:	a6a90913          	addi	s2,s2,-1430 # 80016b60 <tickslock>
    800020fe:	a821                	j	80002116 <wakeup+0x40>
        p->state = RUNNABLE;
    80002100:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b98080e7          	jalr	-1128(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000210e:	16848493          	addi	s1,s1,360
    80002112:	03248463          	beq	s1,s2,8000213a <wakeup+0x64>
    if(p != myproc()){
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	8b0080e7          	jalr	-1872(ra) # 800019c6 <myproc>
    8000211e:	fea488e3          	beq	s1,a0,8000210e <wakeup+0x38>
      acquire(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	ac6080e7          	jalr	-1338(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000212c:	4c9c                	lw	a5,24(s1)
    8000212e:	fd379be3          	bne	a5,s3,80002104 <wakeup+0x2e>
    80002132:	709c                	ld	a5,32(s1)
    80002134:	fd4798e3          	bne	a5,s4,80002104 <wakeup+0x2e>
    80002138:	b7e1                	j	80002100 <wakeup+0x2a>
    }
  }
}
    8000213a:	70e2                	ld	ra,56(sp)
    8000213c:	7442                	ld	s0,48(sp)
    8000213e:	74a2                	ld	s1,40(sp)
    80002140:	7902                	ld	s2,32(sp)
    80002142:	69e2                	ld	s3,24(sp)
    80002144:	6a42                	ld	s4,16(sp)
    80002146:	6aa2                	ld	s5,8(sp)
    80002148:	6121                	addi	sp,sp,64
    8000214a:	8082                	ret

000000008000214c <reparent>:
{
    8000214c:	7179                	addi	sp,sp,-48
    8000214e:	f406                	sd	ra,40(sp)
    80002150:	f022                	sd	s0,32(sp)
    80002152:	ec26                	sd	s1,24(sp)
    80002154:	e84a                	sd	s2,16(sp)
    80002156:	e44e                	sd	s3,8(sp)
    80002158:	e052                	sd	s4,0(sp)
    8000215a:	1800                	addi	s0,sp,48
    8000215c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000215e:	0000f497          	auipc	s1,0xf
    80002162:	00248493          	addi	s1,s1,2 # 80011160 <proc>
      pp->parent = initproc;
    80002166:	00007a17          	auipc	s4,0x7
    8000216a:	952a0a13          	addi	s4,s4,-1710 # 80008ab8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000216e:	00015997          	auipc	s3,0x15
    80002172:	9f298993          	addi	s3,s3,-1550 # 80016b60 <tickslock>
    80002176:	a029                	j	80002180 <reparent+0x34>
    80002178:	16848493          	addi	s1,s1,360
    8000217c:	01348d63          	beq	s1,s3,80002196 <reparent+0x4a>
    if(pp->parent == p){
    80002180:	7c9c                	ld	a5,56(s1)
    80002182:	ff279be3          	bne	a5,s2,80002178 <reparent+0x2c>
      pp->parent = initproc;
    80002186:	000a3503          	ld	a0,0(s4)
    8000218a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	f4a080e7          	jalr	-182(ra) # 800020d6 <wakeup>
    80002194:	b7d5                	j	80002178 <reparent+0x2c>
}
    80002196:	70a2                	ld	ra,40(sp)
    80002198:	7402                	ld	s0,32(sp)
    8000219a:	64e2                	ld	s1,24(sp)
    8000219c:	6942                	ld	s2,16(sp)
    8000219e:	69a2                	ld	s3,8(sp)
    800021a0:	6a02                	ld	s4,0(sp)
    800021a2:	6145                	addi	sp,sp,48
    800021a4:	8082                	ret

00000000800021a6 <exit>:
{
    800021a6:	7179                	addi	sp,sp,-48
    800021a8:	f406                	sd	ra,40(sp)
    800021aa:	f022                	sd	s0,32(sp)
    800021ac:	ec26                	sd	s1,24(sp)
    800021ae:	e84a                	sd	s2,16(sp)
    800021b0:	e44e                	sd	s3,8(sp)
    800021b2:	e052                	sd	s4,0(sp)
    800021b4:	1800                	addi	s0,sp,48
    800021b6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021b8:	00000097          	auipc	ra,0x0
    800021bc:	80e080e7          	jalr	-2034(ra) # 800019c6 <myproc>
    800021c0:	89aa                	mv	s3,a0
  if(p == initproc)
    800021c2:	00007797          	auipc	a5,0x7
    800021c6:	8f67b783          	ld	a5,-1802(a5) # 80008ab8 <initproc>
    800021ca:	0d050493          	addi	s1,a0,208
    800021ce:	15050913          	addi	s2,a0,336
    800021d2:	02a79363          	bne	a5,a0,800021f8 <exit+0x52>
    panic("init exiting");
    800021d6:	00006517          	auipc	a0,0x6
    800021da:	08a50513          	addi	a0,a0,138 # 80008260 <digits+0x220>
    800021de:	ffffe097          	auipc	ra,0xffffe
    800021e2:	366080e7          	jalr	870(ra) # 80000544 <panic>
      fileclose(f);
    800021e6:	00002097          	auipc	ra,0x2
    800021ea:	4a2080e7          	jalr	1186(ra) # 80004688 <fileclose>
      p->ofile[fd] = 0;
    800021ee:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021f2:	04a1                	addi	s1,s1,8
    800021f4:	01248563          	beq	s1,s2,800021fe <exit+0x58>
    if(p->ofile[fd]){
    800021f8:	6088                	ld	a0,0(s1)
    800021fa:	f575                	bnez	a0,800021e6 <exit+0x40>
    800021fc:	bfdd                	j	800021f2 <exit+0x4c>
  begin_op();
    800021fe:	00002097          	auipc	ra,0x2
    80002202:	fbe080e7          	jalr	-66(ra) # 800041bc <begin_op>
  iput(p->cwd);
    80002206:	1509b503          	ld	a0,336(s3)
    8000220a:	00001097          	auipc	ra,0x1
    8000220e:	7aa080e7          	jalr	1962(ra) # 800039b4 <iput>
  end_op();
    80002212:	00002097          	auipc	ra,0x2
    80002216:	02a080e7          	jalr	42(ra) # 8000423c <end_op>
  p->cwd = 0;
    8000221a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000221e:	0000f497          	auipc	s1,0xf
    80002222:	b2a48493          	addi	s1,s1,-1238 # 80010d48 <wait_lock>
    80002226:	8526                	mv	a0,s1
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9c2080e7          	jalr	-1598(ra) # 80000bea <acquire>
  reparent(p);
    80002230:	854e                	mv	a0,s3
    80002232:	00000097          	auipc	ra,0x0
    80002236:	f1a080e7          	jalr	-230(ra) # 8000214c <reparent>
  wakeup(p->parent);
    8000223a:	0389b503          	ld	a0,56(s3)
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	e98080e7          	jalr	-360(ra) # 800020d6 <wakeup>
  acquire(&p->lock);
    80002246:	854e                	mv	a0,s3
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	9a2080e7          	jalr	-1630(ra) # 80000bea <acquire>
  p->xstate = status;
    80002250:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002254:	4795                	li	a5,5
    80002256:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	a42080e7          	jalr	-1470(ra) # 80000c9e <release>
  sched();
    80002264:	00000097          	auipc	ra,0x0
    80002268:	cfc080e7          	jalr	-772(ra) # 80001f60 <sched>
  panic("zombie exit");
    8000226c:	00006517          	auipc	a0,0x6
    80002270:	00450513          	addi	a0,a0,4 # 80008270 <digits+0x230>
    80002274:	ffffe097          	auipc	ra,0xffffe
    80002278:	2d0080e7          	jalr	720(ra) # 80000544 <panic>

000000008000227c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000227c:	7179                	addi	sp,sp,-48
    8000227e:	f406                	sd	ra,40(sp)
    80002280:	f022                	sd	s0,32(sp)
    80002282:	ec26                	sd	s1,24(sp)
    80002284:	e84a                	sd	s2,16(sp)
    80002286:	e44e                	sd	s3,8(sp)
    80002288:	1800                	addi	s0,sp,48
    8000228a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000228c:	0000f497          	auipc	s1,0xf
    80002290:	ed448493          	addi	s1,s1,-300 # 80011160 <proc>
    80002294:	00015997          	auipc	s3,0x15
    80002298:	8cc98993          	addi	s3,s3,-1844 # 80016b60 <tickslock>
    acquire(&p->lock);
    8000229c:	8526                	mv	a0,s1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	94c080e7          	jalr	-1716(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800022a6:	589c                	lw	a5,48(s1)
    800022a8:	01278d63          	beq	a5,s2,800022c2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	9f0080e7          	jalr	-1552(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022b6:	16848493          	addi	s1,s1,360
    800022ba:	ff3491e3          	bne	s1,s3,8000229c <kill+0x20>
  }
  return -1;
    800022be:	557d                	li	a0,-1
    800022c0:	a829                	j	800022da <kill+0x5e>
      p->killed = 1;
    800022c2:	4785                	li	a5,1
    800022c4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022c6:	4c98                	lw	a4,24(s1)
    800022c8:	4789                	li	a5,2
    800022ca:	00f70f63          	beq	a4,a5,800022e8 <kill+0x6c>
      release(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	9ce080e7          	jalr	-1586(ra) # 80000c9e <release>
      return 0;
    800022d8:	4501                	li	a0,0
}
    800022da:	70a2                	ld	ra,40(sp)
    800022dc:	7402                	ld	s0,32(sp)
    800022de:	64e2                	ld	s1,24(sp)
    800022e0:	6942                	ld	s2,16(sp)
    800022e2:	69a2                	ld	s3,8(sp)
    800022e4:	6145                	addi	sp,sp,48
    800022e6:	8082                	ret
        p->state = RUNNABLE;
    800022e8:	478d                	li	a5,3
    800022ea:	cc9c                	sw	a5,24(s1)
    800022ec:	b7cd                	j	800022ce <kill+0x52>

00000000800022ee <setkilled>:

void
setkilled(struct proc *p)
{
    800022ee:	1101                	addi	sp,sp,-32
    800022f0:	ec06                	sd	ra,24(sp)
    800022f2:	e822                	sd	s0,16(sp)
    800022f4:	e426                	sd	s1,8(sp)
    800022f6:	1000                	addi	s0,sp,32
    800022f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8f0080e7          	jalr	-1808(ra) # 80000bea <acquire>
  p->killed = 1;
    80002302:	4785                	li	a5,1
    80002304:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80002310:	60e2                	ld	ra,24(sp)
    80002312:	6442                	ld	s0,16(sp)
    80002314:	64a2                	ld	s1,8(sp)
    80002316:	6105                	addi	sp,sp,32
    80002318:	8082                	ret

000000008000231a <killed>:

int
killed(struct proc *p)
{
    8000231a:	1101                	addi	sp,sp,-32
    8000231c:	ec06                	sd	ra,24(sp)
    8000231e:	e822                	sd	s0,16(sp)
    80002320:	e426                	sd	s1,8(sp)
    80002322:	e04a                	sd	s2,0(sp)
    80002324:	1000                	addi	s0,sp,32
    80002326:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8c2080e7          	jalr	-1854(ra) # 80000bea <acquire>
  k = p->killed;
    80002330:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	968080e7          	jalr	-1688(ra) # 80000c9e <release>
  return k;
}
    8000233e:	854a                	mv	a0,s2
    80002340:	60e2                	ld	ra,24(sp)
    80002342:	6442                	ld	s0,16(sp)
    80002344:	64a2                	ld	s1,8(sp)
    80002346:	6902                	ld	s2,0(sp)
    80002348:	6105                	addi	sp,sp,32
    8000234a:	8082                	ret

000000008000234c <wait>:
{
    8000234c:	715d                	addi	sp,sp,-80
    8000234e:	e486                	sd	ra,72(sp)
    80002350:	e0a2                	sd	s0,64(sp)
    80002352:	fc26                	sd	s1,56(sp)
    80002354:	f84a                	sd	s2,48(sp)
    80002356:	f44e                	sd	s3,40(sp)
    80002358:	f052                	sd	s4,32(sp)
    8000235a:	ec56                	sd	s5,24(sp)
    8000235c:	e85a                	sd	s6,16(sp)
    8000235e:	e45e                	sd	s7,8(sp)
    80002360:	e062                	sd	s8,0(sp)
    80002362:	0880                	addi	s0,sp,80
    80002364:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	660080e7          	jalr	1632(ra) # 800019c6 <myproc>
    8000236e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002370:	0000f517          	auipc	a0,0xf
    80002374:	9d850513          	addi	a0,a0,-1576 # 80010d48 <wait_lock>
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	872080e7          	jalr	-1934(ra) # 80000bea <acquire>
    havekids = 0;
    80002380:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002382:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002384:	00014997          	auipc	s3,0x14
    80002388:	7dc98993          	addi	s3,s3,2012 # 80016b60 <tickslock>
        havekids = 1;
    8000238c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000238e:	0000fc17          	auipc	s8,0xf
    80002392:	9bac0c13          	addi	s8,s8,-1606 # 80010d48 <wait_lock>
    havekids = 0;
    80002396:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002398:	0000f497          	auipc	s1,0xf
    8000239c:	dc848493          	addi	s1,s1,-568 # 80011160 <proc>
    800023a0:	a0bd                	j	8000240e <wait+0xc2>
          pid = pp->pid;
    800023a2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023a6:	000b0e63          	beqz	s6,800023c2 <wait+0x76>
    800023aa:	4691                	li	a3,4
    800023ac:	02c48613          	addi	a2,s1,44
    800023b0:	85da                	mv	a1,s6
    800023b2:	05093503          	ld	a0,80(s2)
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	2ce080e7          	jalr	718(ra) # 80001684 <copyout>
    800023be:	02054563          	bltz	a0,800023e8 <wait+0x9c>
          freeproc(pp);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	7b4080e7          	jalr	1972(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8d0080e7          	jalr	-1840(ra) # 80000c9e <release>
          release(&wait_lock);
    800023d6:	0000f517          	auipc	a0,0xf
    800023da:	97250513          	addi	a0,a0,-1678 # 80010d48 <wait_lock>
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8c0080e7          	jalr	-1856(ra) # 80000c9e <release>
          return pid;
    800023e6:	a0b5                	j	80002452 <wait+0x106>
            release(&pp->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8b4080e7          	jalr	-1868(ra) # 80000c9e <release>
            release(&wait_lock);
    800023f2:	0000f517          	auipc	a0,0xf
    800023f6:	95650513          	addi	a0,a0,-1706 # 80010d48 <wait_lock>
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	8a4080e7          	jalr	-1884(ra) # 80000c9e <release>
            return -1;
    80002402:	59fd                	li	s3,-1
    80002404:	a0b9                	j	80002452 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002406:	16848493          	addi	s1,s1,360
    8000240a:	03348463          	beq	s1,s3,80002432 <wait+0xe6>
      if(pp->parent == p){
    8000240e:	7c9c                	ld	a5,56(s1)
    80002410:	ff279be3          	bne	a5,s2,80002406 <wait+0xba>
        acquire(&pp->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	7d4080e7          	jalr	2004(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    8000241e:	4c9c                	lw	a5,24(s1)
    80002420:	f94781e3          	beq	a5,s4,800023a2 <wait+0x56>
        release(&pp->lock);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	878080e7          	jalr	-1928(ra) # 80000c9e <release>
        havekids = 1;
    8000242e:	8756                	mv	a4,s5
    80002430:	bfd9                	j	80002406 <wait+0xba>
    if(!havekids || killed(p)){
    80002432:	c719                	beqz	a4,80002440 <wait+0xf4>
    80002434:	854a                	mv	a0,s2
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	ee4080e7          	jalr	-284(ra) # 8000231a <killed>
    8000243e:	c51d                	beqz	a0,8000246c <wait+0x120>
      release(&wait_lock);
    80002440:	0000f517          	auipc	a0,0xf
    80002444:	90850513          	addi	a0,a0,-1784 # 80010d48 <wait_lock>
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	856080e7          	jalr	-1962(ra) # 80000c9e <release>
      return -1;
    80002450:	59fd                	li	s3,-1
}
    80002452:	854e                	mv	a0,s3
    80002454:	60a6                	ld	ra,72(sp)
    80002456:	6406                	ld	s0,64(sp)
    80002458:	74e2                	ld	s1,56(sp)
    8000245a:	7942                	ld	s2,48(sp)
    8000245c:	79a2                	ld	s3,40(sp)
    8000245e:	7a02                	ld	s4,32(sp)
    80002460:	6ae2                	ld	s5,24(sp)
    80002462:	6b42                	ld	s6,16(sp)
    80002464:	6ba2                	ld	s7,8(sp)
    80002466:	6c02                	ld	s8,0(sp)
    80002468:	6161                	addi	sp,sp,80
    8000246a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000246c:	85e2                	mv	a1,s8
    8000246e:	854a                	mv	a0,s2
    80002470:	00000097          	auipc	ra,0x0
    80002474:	c02080e7          	jalr	-1022(ra) # 80002072 <sleep>
    havekids = 0;
    80002478:	bf39                	j	80002396 <wait+0x4a>

000000008000247a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247a:	7179                	addi	sp,sp,-48
    8000247c:	f406                	sd	ra,40(sp)
    8000247e:	f022                	sd	s0,32(sp)
    80002480:	ec26                	sd	s1,24(sp)
    80002482:	e84a                	sd	s2,16(sp)
    80002484:	e44e                	sd	s3,8(sp)
    80002486:	e052                	sd	s4,0(sp)
    80002488:	1800                	addi	s0,sp,48
    8000248a:	84aa                	mv	s1,a0
    8000248c:	892e                	mv	s2,a1
    8000248e:	89b2                	mv	s3,a2
    80002490:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	534080e7          	jalr	1332(ra) # 800019c6 <myproc>
  if(user_dst){
    8000249a:	c08d                	beqz	s1,800024bc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000249c:	86d2                	mv	a3,s4
    8000249e:	864e                	mv	a2,s3
    800024a0:	85ca                	mv	a1,s2
    800024a2:	6928                	ld	a0,80(a0)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	1e0080e7          	jalr	480(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ac:	70a2                	ld	ra,40(sp)
    800024ae:	7402                	ld	s0,32(sp)
    800024b0:	64e2                	ld	s1,24(sp)
    800024b2:	6942                	ld	s2,16(sp)
    800024b4:	69a2                	ld	s3,8(sp)
    800024b6:	6a02                	ld	s4,0(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
    memmove((char *)dst, src, len);
    800024bc:	000a061b          	sext.w	a2,s4
    800024c0:	85ce                	mv	a1,s3
    800024c2:	854a                	mv	a0,s2
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	882080e7          	jalr	-1918(ra) # 80000d46 <memmove>
    return 0;
    800024cc:	8526                	mv	a0,s1
    800024ce:	bff9                	j	800024ac <either_copyout+0x32>

00000000800024d0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	e052                	sd	s4,0(sp)
    800024de:	1800                	addi	s0,sp,48
    800024e0:	892a                	mv	s2,a0
    800024e2:	84ae                	mv	s1,a1
    800024e4:	89b2                	mv	s3,a2
    800024e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	4de080e7          	jalr	1246(ra) # 800019c6 <myproc>
  if(user_src){
    800024f0:	c08d                	beqz	s1,80002512 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f2:	86d2                	mv	a3,s4
    800024f4:	864e                	mv	a2,s3
    800024f6:	85ca                	mv	a1,s2
    800024f8:	6928                	ld	a0,80(a0)
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	216080e7          	jalr	534(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6a02                	ld	s4,0(sp)
    8000250e:	6145                	addi	sp,sp,48
    80002510:	8082                	ret
    memmove(dst, (char*)src, len);
    80002512:	000a061b          	sext.w	a2,s4
    80002516:	85ce                	mv	a1,s3
    80002518:	854a                	mv	a0,s2
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	82c080e7          	jalr	-2004(ra) # 80000d46 <memmove>
    return 0;
    80002522:	8526                	mv	a0,s1
    80002524:	bff9                	j	80002502 <either_copyin+0x32>

0000000080002526 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002526:	715d                	addi	sp,sp,-80
    80002528:	e486                	sd	ra,72(sp)
    8000252a:	e0a2                	sd	s0,64(sp)
    8000252c:	fc26                	sd	s1,56(sp)
    8000252e:	f84a                	sd	s2,48(sp)
    80002530:	f44e                	sd	s3,40(sp)
    80002532:	f052                	sd	s4,32(sp)
    80002534:	ec56                	sd	s5,24(sp)
    80002536:	e85a                	sd	s6,16(sp)
    80002538:	e45e                	sd	s7,8(sp)
    8000253a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000253c:	00006517          	auipc	a0,0x6
    80002540:	b8c50513          	addi	a0,a0,-1140 # 800080c8 <digits+0x88>
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	04a080e7          	jalr	74(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000254c:	0000f497          	auipc	s1,0xf
    80002550:	d6c48493          	addi	s1,s1,-660 # 800112b8 <proc+0x158>
    80002554:	00014917          	auipc	s2,0x14
    80002558:	76490913          	addi	s2,s2,1892 # 80016cb8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000255e:	00006997          	auipc	s3,0x6
    80002562:	d2298993          	addi	s3,s3,-734 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002566:	00006a97          	auipc	s5,0x6
    8000256a:	d22a8a93          	addi	s5,s5,-734 # 80008288 <digits+0x248>
    printf("\n");
    8000256e:	00006a17          	auipc	s4,0x6
    80002572:	b5aa0a13          	addi	s4,s4,-1190 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002576:	00006b97          	auipc	s7,0x6
    8000257a:	d52b8b93          	addi	s7,s7,-686 # 800082c8 <states.1723>
    8000257e:	a00d                	j	800025a0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002580:	ed86a583          	lw	a1,-296(a3)
    80002584:	8556                	mv	a0,s5
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	008080e7          	jalr	8(ra) # 8000058e <printf>
    printf("\n");
    8000258e:	8552                	mv	a0,s4
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	ffe080e7          	jalr	-2(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002598:	16848493          	addi	s1,s1,360
    8000259c:	03248163          	beq	s1,s2,800025be <procdump+0x98>
    if(p->state == UNUSED)
    800025a0:	86a6                	mv	a3,s1
    800025a2:	ec04a783          	lw	a5,-320(s1)
    800025a6:	dbed                	beqz	a5,80002598 <procdump+0x72>
      state = "???";
    800025a8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025aa:	fcfb6be3          	bltu	s6,a5,80002580 <procdump+0x5a>
    800025ae:	1782                	slli	a5,a5,0x20
    800025b0:	9381                	srli	a5,a5,0x20
    800025b2:	078e                	slli	a5,a5,0x3
    800025b4:	97de                	add	a5,a5,s7
    800025b6:	6390                	ld	a2,0(a5)
    800025b8:	f661                	bnez	a2,80002580 <procdump+0x5a>
      state = "???";
    800025ba:	864e                	mv	a2,s3
    800025bc:	b7d1                	j	80002580 <procdump+0x5a>
  }
}
    800025be:	60a6                	ld	ra,72(sp)
    800025c0:	6406                	ld	s0,64(sp)
    800025c2:	74e2                	ld	s1,56(sp)
    800025c4:	7942                	ld	s2,48(sp)
    800025c6:	79a2                	ld	s3,40(sp)
    800025c8:	7a02                	ld	s4,32(sp)
    800025ca:	6ae2                	ld	s5,24(sp)
    800025cc:	6b42                	ld	s6,16(sp)
    800025ce:	6ba2                	ld	s7,8(sp)
    800025d0:	6161                	addi	sp,sp,80
    800025d2:	8082                	ret

00000000800025d4 <swtch>:
    800025d4:	00153023          	sd	ra,0(a0)
    800025d8:	00253423          	sd	sp,8(a0)
    800025dc:	e900                	sd	s0,16(a0)
    800025de:	ed04                	sd	s1,24(a0)
    800025e0:	03253023          	sd	s2,32(a0)
    800025e4:	03353423          	sd	s3,40(a0)
    800025e8:	03453823          	sd	s4,48(a0)
    800025ec:	03553c23          	sd	s5,56(a0)
    800025f0:	05653023          	sd	s6,64(a0)
    800025f4:	05753423          	sd	s7,72(a0)
    800025f8:	05853823          	sd	s8,80(a0)
    800025fc:	05953c23          	sd	s9,88(a0)
    80002600:	07a53023          	sd	s10,96(a0)
    80002604:	07b53423          	sd	s11,104(a0)
    80002608:	0005b083          	ld	ra,0(a1)
    8000260c:	0085b103          	ld	sp,8(a1)
    80002610:	6980                	ld	s0,16(a1)
    80002612:	6d84                	ld	s1,24(a1)
    80002614:	0205b903          	ld	s2,32(a1)
    80002618:	0285b983          	ld	s3,40(a1)
    8000261c:	0305ba03          	ld	s4,48(a1)
    80002620:	0385ba83          	ld	s5,56(a1)
    80002624:	0405bb03          	ld	s6,64(a1)
    80002628:	0485bb83          	ld	s7,72(a1)
    8000262c:	0505bc03          	ld	s8,80(a1)
    80002630:	0585bc83          	ld	s9,88(a1)
    80002634:	0605bd03          	ld	s10,96(a1)
    80002638:	0685bd83          	ld	s11,104(a1)
    8000263c:	8082                	ret

000000008000263e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000263e:	1141                	addi	sp,sp,-16
    80002640:	e406                	sd	ra,8(sp)
    80002642:	e022                	sd	s0,0(sp)
    80002644:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002646:	00006597          	auipc	a1,0x6
    8000264a:	cb258593          	addi	a1,a1,-846 # 800082f8 <states.1723+0x30>
    8000264e:	00014517          	auipc	a0,0x14
    80002652:	51250513          	addi	a0,a0,1298 # 80016b60 <tickslock>
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	504080e7          	jalr	1284(ra) # 80000b5a <initlock>
}
    8000265e:	60a2                	ld	ra,8(sp)
    80002660:	6402                	ld	s0,0(sp)
    80002662:	0141                	addi	sp,sp,16
    80002664:	8082                	ret

0000000080002666 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002666:	1141                	addi	sp,sp,-16
    80002668:	e422                	sd	s0,8(sp)
    8000266a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000266c:	00003797          	auipc	a5,0x3
    80002670:	65478793          	addi	a5,a5,1620 # 80005cc0 <kernelvec>
    80002674:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002678:	6422                	ld	s0,8(sp)
    8000267a:	0141                	addi	sp,sp,16
    8000267c:	8082                	ret

000000008000267e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000267e:	1141                	addi	sp,sp,-16
    80002680:	e406                	sd	ra,8(sp)
    80002682:	e022                	sd	s0,0(sp)
    80002684:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	340080e7          	jalr	832(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000268e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002692:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002694:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002698:	00005617          	auipc	a2,0x5
    8000269c:	96860613          	addi	a2,a2,-1688 # 80007000 <_trampoline>
    800026a0:	00005697          	auipc	a3,0x5
    800026a4:	96068693          	addi	a3,a3,-1696 # 80007000 <_trampoline>
    800026a8:	8e91                	sub	a3,a3,a2
    800026aa:	040007b7          	lui	a5,0x4000
    800026ae:	17fd                	addi	a5,a5,-1
    800026b0:	07b2                	slli	a5,a5,0xc
    800026b2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b4:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026b8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ba:	180026f3          	csrr	a3,satp
    800026be:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026c0:	6d38                	ld	a4,88(a0)
    800026c2:	6134                	ld	a3,64(a0)
    800026c4:	6585                	lui	a1,0x1
    800026c6:	96ae                	add	a3,a3,a1
    800026c8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ca:	6d38                	ld	a4,88(a0)
    800026cc:	00000697          	auipc	a3,0x0
    800026d0:	13068693          	addi	a3,a3,304 # 800027fc <usertrap>
    800026d4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026d6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026d8:	8692                	mv	a3,tp
    800026da:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026dc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026e0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026e4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026ec:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026ee:	6f18                	ld	a4,24(a4)
    800026f0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026f4:	6928                	ld	a0,80(a0)
    800026f6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800026f8:	00005717          	auipc	a4,0x5
    800026fc:	9a470713          	addi	a4,a4,-1628 # 8000709c <userret>
    80002700:	8f11                	sub	a4,a4,a2
    80002702:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002704:	577d                	li	a4,-1
    80002706:	177e                	slli	a4,a4,0x3f
    80002708:	8d59                	or	a0,a0,a4
    8000270a:	9782                	jalr	a5
}
    8000270c:	60a2                	ld	ra,8(sp)
    8000270e:	6402                	ld	s0,0(sp)
    80002710:	0141                	addi	sp,sp,16
    80002712:	8082                	ret

0000000080002714 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002714:	1101                	addi	sp,sp,-32
    80002716:	ec06                	sd	ra,24(sp)
    80002718:	e822                	sd	s0,16(sp)
    8000271a:	e426                	sd	s1,8(sp)
    8000271c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000271e:	00014497          	auipc	s1,0x14
    80002722:	44248493          	addi	s1,s1,1090 # 80016b60 <tickslock>
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	4c2080e7          	jalr	1218(ra) # 80000bea <acquire>
  ticks++;
    80002730:	00006517          	auipc	a0,0x6
    80002734:	39050513          	addi	a0,a0,912 # 80008ac0 <ticks>
    80002738:	411c                	lw	a5,0(a0)
    8000273a:	2785                	addiw	a5,a5,1
    8000273c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000273e:	00000097          	auipc	ra,0x0
    80002742:	998080e7          	jalr	-1640(ra) # 800020d6 <wakeup>
  release(&tickslock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	556080e7          	jalr	1366(ra) # 80000c9e <release>
}
    80002750:	60e2                	ld	ra,24(sp)
    80002752:	6442                	ld	s0,16(sp)
    80002754:	64a2                	ld	s1,8(sp)
    80002756:	6105                	addi	sp,sp,32
    80002758:	8082                	ret

000000008000275a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000275a:	1101                	addi	sp,sp,-32
    8000275c:	ec06                	sd	ra,24(sp)
    8000275e:	e822                	sd	s0,16(sp)
    80002760:	e426                	sd	s1,8(sp)
    80002762:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002764:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002768:	00074d63          	bltz	a4,80002782 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000276c:	57fd                	li	a5,-1
    8000276e:	17fe                	slli	a5,a5,0x3f
    80002770:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002772:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002774:	06f70363          	beq	a4,a5,800027da <devintr+0x80>
  }
}
    80002778:	60e2                	ld	ra,24(sp)
    8000277a:	6442                	ld	s0,16(sp)
    8000277c:	64a2                	ld	s1,8(sp)
    8000277e:	6105                	addi	sp,sp,32
    80002780:	8082                	ret
     (scause & 0xff) == 9){
    80002782:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002786:	46a5                	li	a3,9
    80002788:	fed792e3          	bne	a5,a3,8000276c <devintr+0x12>
    int irq = plic_claim();
    8000278c:	00003097          	auipc	ra,0x3
    80002790:	63c080e7          	jalr	1596(ra) # 80005dc8 <plic_claim>
    80002794:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002796:	47a9                	li	a5,10
    80002798:	02f50763          	beq	a0,a5,800027c6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000279c:	4785                	li	a5,1
    8000279e:	02f50963          	beq	a0,a5,800027d0 <devintr+0x76>
    return 1;
    800027a2:	4505                	li	a0,1
    } else if(irq){
    800027a4:	d8f1                	beqz	s1,80002778 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027a6:	85a6                	mv	a1,s1
    800027a8:	00006517          	auipc	a0,0x6
    800027ac:	b5850513          	addi	a0,a0,-1192 # 80008300 <states.1723+0x38>
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	dde080e7          	jalr	-546(ra) # 8000058e <printf>
      plic_complete(irq);
    800027b8:	8526                	mv	a0,s1
    800027ba:	00003097          	auipc	ra,0x3
    800027be:	632080e7          	jalr	1586(ra) # 80005dec <plic_complete>
    return 1;
    800027c2:	4505                	li	a0,1
    800027c4:	bf55                	j	80002778 <devintr+0x1e>
      uartintr();
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	1e8080e7          	jalr	488(ra) # 800009ae <uartintr>
    800027ce:	b7ed                	j	800027b8 <devintr+0x5e>
      virtio_disk_intr();
    800027d0:	00004097          	auipc	ra,0x4
    800027d4:	b46080e7          	jalr	-1210(ra) # 80006316 <virtio_disk_intr>
    800027d8:	b7c5                	j	800027b8 <devintr+0x5e>
    if(cpuid() == 0){
    800027da:	fffff097          	auipc	ra,0xfffff
    800027de:	1c0080e7          	jalr	448(ra) # 8000199a <cpuid>
    800027e2:	c901                	beqz	a0,800027f2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027e4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027e8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ea:	14479073          	csrw	sip,a5
    return 2;
    800027ee:	4509                	li	a0,2
    800027f0:	b761                	j	80002778 <devintr+0x1e>
      clockintr();
    800027f2:	00000097          	auipc	ra,0x0
    800027f6:	f22080e7          	jalr	-222(ra) # 80002714 <clockintr>
    800027fa:	b7ed                	j	800027e4 <devintr+0x8a>

00000000800027fc <usertrap>:
{
    800027fc:	1101                	addi	sp,sp,-32
    800027fe:	ec06                	sd	ra,24(sp)
    80002800:	e822                	sd	s0,16(sp)
    80002802:	e426                	sd	s1,8(sp)
    80002804:	e04a                	sd	s2,0(sp)
    80002806:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002808:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000280c:	1007f793          	andi	a5,a5,256
    80002810:	e3b1                	bnez	a5,80002854 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002812:	00003797          	auipc	a5,0x3
    80002816:	4ae78793          	addi	a5,a5,1198 # 80005cc0 <kernelvec>
    8000281a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	1a8080e7          	jalr	424(ra) # 800019c6 <myproc>
    80002826:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002828:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000282a:	14102773          	csrr	a4,sepc
    8000282e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002830:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002834:	47a1                	li	a5,8
    80002836:	02f70763          	beq	a4,a5,80002864 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	f20080e7          	jalr	-224(ra) # 8000275a <devintr>
    80002842:	892a                	mv	s2,a0
    80002844:	c151                	beqz	a0,800028c8 <usertrap+0xcc>
  if(killed(p))
    80002846:	8526                	mv	a0,s1
    80002848:	00000097          	auipc	ra,0x0
    8000284c:	ad2080e7          	jalr	-1326(ra) # 8000231a <killed>
    80002850:	c929                	beqz	a0,800028a2 <usertrap+0xa6>
    80002852:	a099                	j	80002898 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002854:	00006517          	auipc	a0,0x6
    80002858:	acc50513          	addi	a0,a0,-1332 # 80008320 <states.1723+0x58>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	ce8080e7          	jalr	-792(ra) # 80000544 <panic>
    if(killed(p))
    80002864:	00000097          	auipc	ra,0x0
    80002868:	ab6080e7          	jalr	-1354(ra) # 8000231a <killed>
    8000286c:	e921                	bnez	a0,800028bc <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000286e:	6cb8                	ld	a4,88(s1)
    80002870:	6f1c                	ld	a5,24(a4)
    80002872:	0791                	addi	a5,a5,4
    80002874:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002876:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000287a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000287e:	10079073          	csrw	sstatus,a5
    syscall();
    80002882:	00000097          	auipc	ra,0x0
    80002886:	2d4080e7          	jalr	724(ra) # 80002b56 <syscall>
  if(killed(p))
    8000288a:	8526                	mv	a0,s1
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	a8e080e7          	jalr	-1394(ra) # 8000231a <killed>
    80002894:	c911                	beqz	a0,800028a8 <usertrap+0xac>
    80002896:	4901                	li	s2,0
    exit(-1);
    80002898:	557d                	li	a0,-1
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	90c080e7          	jalr	-1780(ra) # 800021a6 <exit>
  if(which_dev == 2)
    800028a2:	4789                	li	a5,2
    800028a4:	04f90f63          	beq	s2,a5,80002902 <usertrap+0x106>
  usertrapret();
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	dd6080e7          	jalr	-554(ra) # 8000267e <usertrapret>
}
    800028b0:	60e2                	ld	ra,24(sp)
    800028b2:	6442                	ld	s0,16(sp)
    800028b4:	64a2                	ld	s1,8(sp)
    800028b6:	6902                	ld	s2,0(sp)
    800028b8:	6105                	addi	sp,sp,32
    800028ba:	8082                	ret
      exit(-1);
    800028bc:	557d                	li	a0,-1
    800028be:	00000097          	auipc	ra,0x0
    800028c2:	8e8080e7          	jalr	-1816(ra) # 800021a6 <exit>
    800028c6:	b765                	j	8000286e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028cc:	5890                	lw	a2,48(s1)
    800028ce:	00006517          	auipc	a0,0x6
    800028d2:	a7250513          	addi	a0,a0,-1422 # 80008340 <states.1723+0x78>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	cb8080e7          	jalr	-840(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028de:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028e6:	00006517          	auipc	a0,0x6
    800028ea:	a8a50513          	addi	a0,a0,-1398 # 80008370 <states.1723+0xa8>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	ca0080e7          	jalr	-864(ra) # 8000058e <printf>
    setkilled(p);
    800028f6:	8526                	mv	a0,s1
    800028f8:	00000097          	auipc	ra,0x0
    800028fc:	9f6080e7          	jalr	-1546(ra) # 800022ee <setkilled>
    80002900:	b769                	j	8000288a <usertrap+0x8e>
    yield();
    80002902:	fffff097          	auipc	ra,0xfffff
    80002906:	734080e7          	jalr	1844(ra) # 80002036 <yield>
    8000290a:	bf79                	j	800028a8 <usertrap+0xac>

000000008000290c <kerneltrap>:
{
    8000290c:	7179                	addi	sp,sp,-48
    8000290e:	f406                	sd	ra,40(sp)
    80002910:	f022                	sd	s0,32(sp)
    80002912:	ec26                	sd	s1,24(sp)
    80002914:	e84a                	sd	s2,16(sp)
    80002916:	e44e                	sd	s3,8(sp)
    80002918:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000291a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002922:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002926:	1004f793          	andi	a5,s1,256
    8000292a:	cb85                	beqz	a5,8000295a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002930:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002932:	ef85                	bnez	a5,8000296a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002934:	00000097          	auipc	ra,0x0
    80002938:	e26080e7          	jalr	-474(ra) # 8000275a <devintr>
    8000293c:	cd1d                	beqz	a0,8000297a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000293e:	4789                	li	a5,2
    80002940:	06f50a63          	beq	a0,a5,800029b4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002944:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002948:	10049073          	csrw	sstatus,s1
}
    8000294c:	70a2                	ld	ra,40(sp)
    8000294e:	7402                	ld	s0,32(sp)
    80002950:	64e2                	ld	s1,24(sp)
    80002952:	6942                	ld	s2,16(sp)
    80002954:	69a2                	ld	s3,8(sp)
    80002956:	6145                	addi	sp,sp,48
    80002958:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000295a:	00006517          	auipc	a0,0x6
    8000295e:	a3650513          	addi	a0,a0,-1482 # 80008390 <states.1723+0xc8>
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	be2080e7          	jalr	-1054(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	a4e50513          	addi	a0,a0,-1458 # 800083b8 <states.1723+0xf0>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	bd2080e7          	jalr	-1070(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    8000297a:	85ce                	mv	a1,s3
    8000297c:	00006517          	auipc	a0,0x6
    80002980:	a5c50513          	addi	a0,a0,-1444 # 800083d8 <states.1723+0x110>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	c0a080e7          	jalr	-1014(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002990:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002994:	00006517          	auipc	a0,0x6
    80002998:	a5450513          	addi	a0,a0,-1452 # 800083e8 <states.1723+0x120>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	bf2080e7          	jalr	-1038(ra) # 8000058e <printf>
    panic("kerneltrap");
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	a5c50513          	addi	a0,a0,-1444 # 80008400 <states.1723+0x138>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	b98080e7          	jalr	-1128(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	012080e7          	jalr	18(ra) # 800019c6 <myproc>
    800029bc:	d541                	beqz	a0,80002944 <kerneltrap+0x38>
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	008080e7          	jalr	8(ra) # 800019c6 <myproc>
    800029c6:	4d18                	lw	a4,24(a0)
    800029c8:	4791                	li	a5,4
    800029ca:	f6f71de3          	bne	a4,a5,80002944 <kerneltrap+0x38>
    yield();
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	668080e7          	jalr	1640(ra) # 80002036 <yield>
    800029d6:	b7bd                	j	80002944 <kerneltrap+0x38>

00000000800029d8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029d8:	1101                	addi	sp,sp,-32
    800029da:	ec06                	sd	ra,24(sp)
    800029dc:	e822                	sd	s0,16(sp)
    800029de:	e426                	sd	s1,8(sp)
    800029e0:	1000                	addi	s0,sp,32
    800029e2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	fe2080e7          	jalr	-30(ra) # 800019c6 <myproc>
  switch (n) {
    800029ec:	4795                	li	a5,5
    800029ee:	0497e163          	bltu	a5,s1,80002a30 <argraw+0x58>
    800029f2:	048a                	slli	s1,s1,0x2
    800029f4:	00006717          	auipc	a4,0x6
    800029f8:	b2470713          	addi	a4,a4,-1244 # 80008518 <states.1723+0x250>
    800029fc:	94ba                	add	s1,s1,a4
    800029fe:	409c                	lw	a5,0(s1)
    80002a00:	97ba                	add	a5,a5,a4
    80002a02:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a04:	6d3c                	ld	a5,88(a0)
    80002a06:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a08:	60e2                	ld	ra,24(sp)
    80002a0a:	6442                	ld	s0,16(sp)
    80002a0c:	64a2                	ld	s1,8(sp)
    80002a0e:	6105                	addi	sp,sp,32
    80002a10:	8082                	ret
    return p->trapframe->a1;
    80002a12:	6d3c                	ld	a5,88(a0)
    80002a14:	7fa8                	ld	a0,120(a5)
    80002a16:	bfcd                	j	80002a08 <argraw+0x30>
    return p->trapframe->a2;
    80002a18:	6d3c                	ld	a5,88(a0)
    80002a1a:	63c8                	ld	a0,128(a5)
    80002a1c:	b7f5                	j	80002a08 <argraw+0x30>
    return p->trapframe->a3;
    80002a1e:	6d3c                	ld	a5,88(a0)
    80002a20:	67c8                	ld	a0,136(a5)
    80002a22:	b7dd                	j	80002a08 <argraw+0x30>
    return p->trapframe->a4;
    80002a24:	6d3c                	ld	a5,88(a0)
    80002a26:	6bc8                	ld	a0,144(a5)
    80002a28:	b7c5                	j	80002a08 <argraw+0x30>
    return p->trapframe->a5;
    80002a2a:	6d3c                	ld	a5,88(a0)
    80002a2c:	6fc8                	ld	a0,152(a5)
    80002a2e:	bfe9                	j	80002a08 <argraw+0x30>
  panic("argraw");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	9e050513          	addi	a0,a0,-1568 # 80008410 <states.1723+0x148>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b0c080e7          	jalr	-1268(ra) # 80000544 <panic>

0000000080002a40 <fetchaddr>:
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	e04a                	sd	s2,0(sp)
    80002a4a:	1000                	addi	s0,sp,32
    80002a4c:	84aa                	mv	s1,a0
    80002a4e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	f76080e7          	jalr	-138(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a58:	653c                	ld	a5,72(a0)
    80002a5a:	02f4f863          	bgeu	s1,a5,80002a8a <fetchaddr+0x4a>
    80002a5e:	00848713          	addi	a4,s1,8
    80002a62:	02e7e663          	bltu	a5,a4,80002a8e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a66:	46a1                	li	a3,8
    80002a68:	8626                	mv	a2,s1
    80002a6a:	85ca                	mv	a1,s2
    80002a6c:	6928                	ld	a0,80(a0)
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	ca2080e7          	jalr	-862(ra) # 80001710 <copyin>
    80002a76:	00a03533          	snez	a0,a0
    80002a7a:	40a00533          	neg	a0,a0
}
    80002a7e:	60e2                	ld	ra,24(sp)
    80002a80:	6442                	ld	s0,16(sp)
    80002a82:	64a2                	ld	s1,8(sp)
    80002a84:	6902                	ld	s2,0(sp)
    80002a86:	6105                	addi	sp,sp,32
    80002a88:	8082                	ret
    return -1;
    80002a8a:	557d                	li	a0,-1
    80002a8c:	bfcd                	j	80002a7e <fetchaddr+0x3e>
    80002a8e:	557d                	li	a0,-1
    80002a90:	b7fd                	j	80002a7e <fetchaddr+0x3e>

0000000080002a92 <fetchstr>:
{
    80002a92:	7179                	addi	sp,sp,-48
    80002a94:	f406                	sd	ra,40(sp)
    80002a96:	f022                	sd	s0,32(sp)
    80002a98:	ec26                	sd	s1,24(sp)
    80002a9a:	e84a                	sd	s2,16(sp)
    80002a9c:	e44e                	sd	s3,8(sp)
    80002a9e:	1800                	addi	s0,sp,48
    80002aa0:	892a                	mv	s2,a0
    80002aa2:	84ae                	mv	s1,a1
    80002aa4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	f20080e7          	jalr	-224(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002aae:	86ce                	mv	a3,s3
    80002ab0:	864a                	mv	a2,s2
    80002ab2:	85a6                	mv	a1,s1
    80002ab4:	6928                	ld	a0,80(a0)
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	ce6080e7          	jalr	-794(ra) # 8000179c <copyinstr>
    80002abe:	00054e63          	bltz	a0,80002ada <fetchstr+0x48>
  return strlen(buf);
    80002ac2:	8526                	mv	a0,s1
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	3a6080e7          	jalr	934(ra) # 80000e6a <strlen>
}
    80002acc:	70a2                	ld	ra,40(sp)
    80002ace:	7402                	ld	s0,32(sp)
    80002ad0:	64e2                	ld	s1,24(sp)
    80002ad2:	6942                	ld	s2,16(sp)
    80002ad4:	69a2                	ld	s3,8(sp)
    80002ad6:	6145                	addi	sp,sp,48
    80002ad8:	8082                	ret
    return -1;
    80002ada:	557d                	li	a0,-1
    80002adc:	bfc5                	j	80002acc <fetchstr+0x3a>

0000000080002ade <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	1000                	addi	s0,sp,32
    80002ae8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aea:	00000097          	auipc	ra,0x0
    80002aee:	eee080e7          	jalr	-274(ra) # 800029d8 <argraw>
    80002af2:	c088                	sw	a0,0(s1)
}
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret

0000000080002afe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	1000                	addi	s0,sp,32
    80002b08:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0a:	00000097          	auipc	ra,0x0
    80002b0e:	ece080e7          	jalr	-306(ra) # 800029d8 <argraw>
    80002b12:	e088                	sd	a0,0(s1)
}
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6105                	addi	sp,sp,32
    80002b1c:	8082                	ret

0000000080002b1e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b1e:	7179                	addi	sp,sp,-48
    80002b20:	f406                	sd	ra,40(sp)
    80002b22:	f022                	sd	s0,32(sp)
    80002b24:	ec26                	sd	s1,24(sp)
    80002b26:	e84a                	sd	s2,16(sp)
    80002b28:	1800                	addi	s0,sp,48
    80002b2a:	84ae                	mv	s1,a1
    80002b2c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b2e:	fd840593          	addi	a1,s0,-40
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	fcc080e7          	jalr	-52(ra) # 80002afe <argaddr>
  return fetchstr(addr, buf, max);
    80002b3a:	864a                	mv	a2,s2
    80002b3c:	85a6                	mv	a1,s1
    80002b3e:	fd843503          	ld	a0,-40(s0)
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	f50080e7          	jalr	-176(ra) # 80002a92 <fetchstr>
}
    80002b4a:	70a2                	ld	ra,40(sp)
    80002b4c:	7402                	ld	s0,32(sp)
    80002b4e:	64e2                	ld	s1,24(sp)
    80002b50:	6942                	ld	s2,16(sp)
    80002b52:	6145                	addi	sp,sp,48
    80002b54:	8082                	ret

0000000080002b56 <syscall>:

};

void
syscall(void)
{
    80002b56:	7139                	addi	sp,sp,-64
    80002b58:	fc06                	sd	ra,56(sp)
    80002b5a:	f822                	sd	s0,48(sp)
    80002b5c:	f426                	sd	s1,40(sp)
    80002b5e:	f04a                	sd	s2,32(sp)
    80002b60:	ec4e                	sd	s3,24(sp)
    80002b62:	e852                	sd	s4,16(sp)
    80002b64:	e456                	sd	s5,8(sp)
    80002b66:	e05a                	sd	s6,0(sp)
    80002b68:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	e5c080e7          	jalr	-420(ra) # 800019c6 <myproc>
    80002b72:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b74:	05853903          	ld	s2,88(a0)
    80002b78:	0a893783          	ld	a5,168(s2)
    80002b7c:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b80:	37fd                	addiw	a5,a5,-1
    80002b82:	4755                	li	a4,21
    80002b84:	16f76263          	bltu	a4,a5,80002ce8 <syscall+0x192>
    80002b88:	00399713          	slli	a4,s3,0x3
    80002b8c:	00006797          	auipc	a5,0x6
    80002b90:	9a478793          	addi	a5,a5,-1628 # 80008530 <syscalls>
    80002b94:	97ba                	add	a5,a5,a4
    80002b96:	0007ba83          	ld	s5,0(a5)
    80002b9a:	140a8763          	beqz	s5,80002ce8 <syscall+0x192>
    //check if strace is activated or  not
    // printf("%d\n",p->trac_stat);

    // printf("%d %s\n",(p->trac_stat) , sysnames[num]);

    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002b9e:	47d9                	li	a5,22
    80002ba0:	02f98c63          	beq	s3,a5,80002bd8 <syscall+0x82>
    80002ba4:	595c                	lw	a5,52(a0)
    80002ba6:	4137d7bb          	sraw	a5,a5,s3
    80002baa:	8b85                	andi	a5,a5,1
    80002bac:	e3b5                	bnez	a5,80002c10 <syscall+0xba>

      if(num==SYS_exit){
        printf("\n");
      }
    }
    p->trapframe->a0 = syscalls[num]();
    80002bae:	9a82                	jalr	s5
    80002bb0:	06a93823          	sd	a0,112(s2)

    //printing return value
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002bb4:	58dc                	lw	a5,52(s1)
    80002bb6:	4137d9bb          	sraw	s3,a5,s3
    80002bba:	0019f993          	andi	s3,s3,1
    80002bbe:	14098463          	beqz	s3,80002d06 <syscall+0x1b0>
      printf(" -> %d\n",p->trapframe->a0);
    80002bc2:	6cbc                	ld	a5,88(s1)
    80002bc4:	7bac                	ld	a1,112(a5)
    80002bc6:	00006517          	auipc	a0,0x6
    80002bca:	88250513          	addi	a0,a0,-1918 # 80008448 <states.1723+0x180>
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	9c0080e7          	jalr	-1600(ra) # 8000058e <printf>
    80002bd6:	aa05                	j	80002d06 <syscall+0x1b0>
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002bd8:	4501                	li	a0,0
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	dfe080e7          	jalr	-514(ra) # 800029d8 <argraw>
    80002be2:	02951793          	slli	a5,a0,0x29
    80002be6:	1207ca63          	bltz	a5,80002d1a <syscall+0x1c4>
    80002bea:	58dc                	lw	a5,52(s1)
    80002bec:	02979713          	slli	a4,a5,0x29
    80002bf0:	14075463          	bgez	a4,80002d38 <syscall+0x1e2>
      printf("%d: syscall %s (",p->pid,sysnames[num]);
    80002bf4:	00006617          	auipc	a2,0x6
    80002bf8:	87c60613          	addi	a2,a2,-1924 # 80008470 <states.1723+0x1a8>
    80002bfc:	588c                	lw	a1,48(s1)
    80002bfe:	00006517          	auipc	a0,0x6
    80002c02:	81a50513          	addi	a0,a0,-2022 # 80008418 <states.1723+0x150>
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	988080e7          	jalr	-1656(ra) # 8000058e <printf>
      if(sysargs[num]==0){
    80002c0e:	a21d                	j	80002d34 <syscall+0x1de>
      printf("%d: syscall %s (",p->pid,sysnames[num]);
    80002c10:	00006917          	auipc	s2,0x6
    80002c14:	92090913          	addi	s2,s2,-1760 # 80008530 <syscalls>
    80002c18:	00399793          	slli	a5,s3,0x3
    80002c1c:	97ca                	add	a5,a5,s2
    80002c1e:	7fd0                	ld	a2,184(a5)
    80002c20:	588c                	lw	a1,48(s1)
    80002c22:	00005517          	auipc	a0,0x5
    80002c26:	7f650513          	addi	a0,a0,2038 # 80008418 <states.1723+0x150>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	964080e7          	jalr	-1692(ra) # 8000058e <printf>
      if(sysargs[num]==0){
    80002c32:	00299793          	slli	a5,s3,0x2
    80002c36:	993e                	add	s2,s2,a5
    80002c38:	17092a03          	lw	s4,368(s2)
    80002c3c:	060a0463          	beqz	s4,80002ca4 <syscall+0x14e>
        for(int i=0;i<sysargs[num];i++){
    80002c40:	03405563          	blez	s4,80002c6a <syscall+0x114>
{
    80002c44:	4901                	li	s2,0
          printf("%d ",argraw(i));
    80002c46:	00005b17          	auipc	s6,0x5
    80002c4a:	7f2b0b13          	addi	s6,s6,2034 # 80008438 <states.1723+0x170>
    80002c4e:	854a                	mv	a0,s2
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	d88080e7          	jalr	-632(ra) # 800029d8 <argraw>
    80002c58:	85aa                	mv	a1,a0
    80002c5a:	855a                	mv	a0,s6
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	932080e7          	jalr	-1742(ra) # 8000058e <printf>
        for(int i=0;i<sysargs[num];i++){
    80002c64:	2905                	addiw	s2,s2,1
    80002c66:	ff4914e3          	bne	s2,s4,80002c4e <syscall+0xf8>
        printf("\b)");
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	7d650513          	addi	a0,a0,2006 # 80008440 <states.1723+0x178>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	91c080e7          	jalr	-1764(ra) # 8000058e <printf>
      if(num==SYS_exit){
    80002c7a:	4789                	li	a5,2
    80002c7c:	04f98563          	beq	s3,a5,80002cc6 <syscall+0x170>
    p->trapframe->a0 = syscalls[num]();
    80002c80:	0584b903          	ld	s2,88(s1)
    80002c84:	9a82                	jalr	s5
    80002c86:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002c8a:	47d9                	li	a5,22
    80002c8c:	f2f994e3          	bne	s3,a5,80002bb4 <syscall+0x5e>
    80002c90:	4501                	li	a0,0
    80002c92:	00000097          	auipc	ra,0x0
    80002c96:	d46080e7          	jalr	-698(ra) # 800029d8 <argraw>
    80002c9a:	02951793          	slli	a5,a0,0x29
    80002c9e:	f207c2e3          	bltz	a5,80002bc2 <syscall+0x6c>
    80002ca2:	bf09                	j	80002bb4 <syscall+0x5e>
        printf(")");
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	78c50513          	addi	a0,a0,1932 # 80008430 <states.1723+0x168>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	8e2080e7          	jalr	-1822(ra) # 8000058e <printf>
      if(num==SYS_exit){
    80002cb4:	4789                	li	a5,2
    80002cb6:	00f98863          	beq	s3,a5,80002cc6 <syscall+0x170>
    p->trapframe->a0 = syscalls[num]();
    80002cba:	0584b903          	ld	s2,88(s1)
    80002cbe:	9a82                	jalr	s5
    80002cc0:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002cc4:	bdc5                	j	80002bb4 <syscall+0x5e>
        printf("\n");
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	40250513          	addi	a0,a0,1026 # 800080c8 <digits+0x88>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	8c0080e7          	jalr	-1856(ra) # 8000058e <printf>
    p->trapframe->a0 = syscalls[num]();
    80002cd6:	0584b903          	ld	s2,88(s1)
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	06a080e7          	jalr	106(ra) # 80002d44 <sys_exit>
    80002ce2:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002ce6:	b5f9                	j	80002bb4 <syscall+0x5e>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ce8:	86ce                	mv	a3,s3
    80002cea:	15848613          	addi	a2,s1,344
    80002cee:	588c                	lw	a1,48(s1)
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	76050513          	addi	a0,a0,1888 # 80008450 <states.1723+0x188>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	896080e7          	jalr	-1898(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d00:	6cbc                	ld	a5,88(s1)
    80002d02:	577d                	li	a4,-1
    80002d04:	fbb8                	sd	a4,112(a5)
  }
}
    80002d06:	70e2                	ld	ra,56(sp)
    80002d08:	7442                	ld	s0,48(sp)
    80002d0a:	74a2                	ld	s1,40(sp)
    80002d0c:	7902                	ld	s2,32(sp)
    80002d0e:	69e2                	ld	s3,24(sp)
    80002d10:	6a42                	ld	s4,16(sp)
    80002d12:	6aa2                	ld	s5,8(sp)
    80002d14:	6b02                	ld	s6,0(sp)
    80002d16:	6121                	addi	sp,sp,64
    80002d18:	8082                	ret
      printf("%d: syscall %s (",p->pid,sysnames[num]);
    80002d1a:	00005617          	auipc	a2,0x5
    80002d1e:	75660613          	addi	a2,a2,1878 # 80008470 <states.1723+0x1a8>
    80002d22:	588c                	lw	a1,48(s1)
    80002d24:	00005517          	auipc	a0,0x5
    80002d28:	6f450513          	addi	a0,a0,1780 # 80008418 <states.1723+0x150>
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	862080e7          	jalr	-1950(ra) # 8000058e <printf>
{
    80002d34:	4a05                	li	s4,1
    80002d36:	b739                	j	80002c44 <syscall+0xee>
    p->trapframe->a0 = syscalls[num]();
    80002d38:	0584b903          	ld	s2,88(s1)
    80002d3c:	9a82                	jalr	s5
    80002d3e:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002d42:	b7b9                	j	80002c90 <syscall+0x13a>

0000000080002d44 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d4c:	fec40593          	addi	a1,s0,-20
    80002d50:	4501                	li	a0,0
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	d8c080e7          	jalr	-628(ra) # 80002ade <argint>
  exit(n);
    80002d5a:	fec42503          	lw	a0,-20(s0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	448080e7          	jalr	1096(ra) # 800021a6 <exit>
  return 0;  // not reached
}
    80002d66:	4501                	li	a0,0
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	6105                	addi	sp,sp,32
    80002d6e:	8082                	ret

0000000080002d70 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d70:	1141                	addi	sp,sp,-16
    80002d72:	e406                	sd	ra,8(sp)
    80002d74:	e022                	sd	s0,0(sp)
    80002d76:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	c4e080e7          	jalr	-946(ra) # 800019c6 <myproc>
}
    80002d80:	5908                	lw	a0,48(a0)
    80002d82:	60a2                	ld	ra,8(sp)
    80002d84:	6402                	ld	s0,0(sp)
    80002d86:	0141                	addi	sp,sp,16
    80002d88:	8082                	ret

0000000080002d8a <sys_fork>:

uint64
sys_fork(void)
{
    80002d8a:	1141                	addi	sp,sp,-16
    80002d8c:	e406                	sd	ra,8(sp)
    80002d8e:	e022                	sd	s0,0(sp)
    80002d90:	0800                	addi	s0,sp,16
  return fork();
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	ff2080e7          	jalr	-14(ra) # 80001d84 <fork>
}
    80002d9a:	60a2                	ld	ra,8(sp)
    80002d9c:	6402                	ld	s0,0(sp)
    80002d9e:	0141                	addi	sp,sp,16
    80002da0:	8082                	ret

0000000080002da2 <sys_wait>:

uint64
sys_wait(void)
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002daa:	fe840593          	addi	a1,s0,-24
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	d4e080e7          	jalr	-690(ra) # 80002afe <argaddr>
  return wait(p);
    80002db8:	fe843503          	ld	a0,-24(s0)
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	590080e7          	jalr	1424(ra) # 8000234c <wait>
}
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dcc:	7179                	addi	sp,sp,-48
    80002dce:	f406                	sd	ra,40(sp)
    80002dd0:	f022                	sd	s0,32(sp)
    80002dd2:	ec26                	sd	s1,24(sp)
    80002dd4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002dd6:	fdc40593          	addi	a1,s0,-36
    80002dda:	4501                	li	a0,0
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	d02080e7          	jalr	-766(ra) # 80002ade <argint>
  addr = myproc()->sz;
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	be2080e7          	jalr	-1054(ra) # 800019c6 <myproc>
    80002dec:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002dee:	fdc42503          	lw	a0,-36(s0)
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	f36080e7          	jalr	-202(ra) # 80001d28 <growproc>
    80002dfa:	00054863          	bltz	a0,80002e0a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dfe:	8526                	mv	a0,s1
    80002e00:	70a2                	ld	ra,40(sp)
    80002e02:	7402                	ld	s0,32(sp)
    80002e04:	64e2                	ld	s1,24(sp)
    80002e06:	6145                	addi	sp,sp,48
    80002e08:	8082                	ret
    return -1;
    80002e0a:	54fd                	li	s1,-1
    80002e0c:	bfcd                	j	80002dfe <sys_sbrk+0x32>

0000000080002e0e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e0e:	7139                	addi	sp,sp,-64
    80002e10:	fc06                	sd	ra,56(sp)
    80002e12:	f822                	sd	s0,48(sp)
    80002e14:	f426                	sd	s1,40(sp)
    80002e16:	f04a                	sd	s2,32(sp)
    80002e18:	ec4e                	sd	s3,24(sp)
    80002e1a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e1c:	fcc40593          	addi	a1,s0,-52
    80002e20:	4501                	li	a0,0
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	cbc080e7          	jalr	-836(ra) # 80002ade <argint>
  acquire(&tickslock);
    80002e2a:	00014517          	auipc	a0,0x14
    80002e2e:	d3650513          	addi	a0,a0,-714 # 80016b60 <tickslock>
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	db8080e7          	jalr	-584(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002e3a:	00006917          	auipc	s2,0x6
    80002e3e:	c8692903          	lw	s2,-890(s2) # 80008ac0 <ticks>
  while(ticks - ticks0 < n){
    80002e42:	fcc42783          	lw	a5,-52(s0)
    80002e46:	cf9d                	beqz	a5,80002e84 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e48:	00014997          	auipc	s3,0x14
    80002e4c:	d1898993          	addi	s3,s3,-744 # 80016b60 <tickslock>
    80002e50:	00006497          	auipc	s1,0x6
    80002e54:	c7048493          	addi	s1,s1,-912 # 80008ac0 <ticks>
    if(killed(myproc())){
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	b6e080e7          	jalr	-1170(ra) # 800019c6 <myproc>
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	4ba080e7          	jalr	1210(ra) # 8000231a <killed>
    80002e68:	ed15                	bnez	a0,80002ea4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e6a:	85ce                	mv	a1,s3
    80002e6c:	8526                	mv	a0,s1
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	204080e7          	jalr	516(ra) # 80002072 <sleep>
  while(ticks - ticks0 < n){
    80002e76:	409c                	lw	a5,0(s1)
    80002e78:	412787bb          	subw	a5,a5,s2
    80002e7c:	fcc42703          	lw	a4,-52(s0)
    80002e80:	fce7ece3          	bltu	a5,a4,80002e58 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e84:	00014517          	auipc	a0,0x14
    80002e88:	cdc50513          	addi	a0,a0,-804 # 80016b60 <tickslock>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	e12080e7          	jalr	-494(ra) # 80000c9e <release>
  return 0;
    80002e94:	4501                	li	a0,0
}
    80002e96:	70e2                	ld	ra,56(sp)
    80002e98:	7442                	ld	s0,48(sp)
    80002e9a:	74a2                	ld	s1,40(sp)
    80002e9c:	7902                	ld	s2,32(sp)
    80002e9e:	69e2                	ld	s3,24(sp)
    80002ea0:	6121                	addi	sp,sp,64
    80002ea2:	8082                	ret
      release(&tickslock);
    80002ea4:	00014517          	auipc	a0,0x14
    80002ea8:	cbc50513          	addi	a0,a0,-836 # 80016b60 <tickslock>
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	df2080e7          	jalr	-526(ra) # 80000c9e <release>
      return -1;
    80002eb4:	557d                	li	a0,-1
    80002eb6:	b7c5                	j	80002e96 <sys_sleep+0x88>

0000000080002eb8 <sys_kill>:

uint64
sys_kill(void)
{
    80002eb8:	1101                	addi	sp,sp,-32
    80002eba:	ec06                	sd	ra,24(sp)
    80002ebc:	e822                	sd	s0,16(sp)
    80002ebe:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ec0:	fec40593          	addi	a1,s0,-20
    80002ec4:	4501                	li	a0,0
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	c18080e7          	jalr	-1000(ra) # 80002ade <argint>
  return kill(pid);
    80002ece:	fec42503          	lw	a0,-20(s0)
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	3aa080e7          	jalr	938(ra) # 8000227c <kill>
}
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	6105                	addi	sp,sp,32
    80002ee0:	8082                	ret

0000000080002ee2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ee2:	1101                	addi	sp,sp,-32
    80002ee4:	ec06                	sd	ra,24(sp)
    80002ee6:	e822                	sd	s0,16(sp)
    80002ee8:	e426                	sd	s1,8(sp)
    80002eea:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eec:	00014517          	auipc	a0,0x14
    80002ef0:	c7450513          	addi	a0,a0,-908 # 80016b60 <tickslock>
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	cf6080e7          	jalr	-778(ra) # 80000bea <acquire>
  xticks = ticks;
    80002efc:	00006497          	auipc	s1,0x6
    80002f00:	bc44a483          	lw	s1,-1084(s1) # 80008ac0 <ticks>
  release(&tickslock);
    80002f04:	00014517          	auipc	a0,0x14
    80002f08:	c5c50513          	addi	a0,a0,-932 # 80016b60 <tickslock>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	d92080e7          	jalr	-622(ra) # 80000c9e <release>
  return xticks;
}
    80002f14:	02049513          	slli	a0,s1,0x20
    80002f18:	9101                	srli	a0,a0,0x20
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6105                	addi	sp,sp,32
    80002f22:	8082                	ret

0000000080002f24 <sys_trace>:

uint64
sys_trace(void){
    80002f24:	1101                	addi	sp,sp,-32
    80002f26:	ec06                	sd	ra,24(sp)
    80002f28:	e822                	sd	s0,16(sp)
    80002f2a:	1000                	addi	s0,sp,32
  int x;
  argint(0,&x);
    80002f2c:	fec40593          	addi	a1,s0,-20
    80002f30:	4501                	li	a0,0
    80002f32:	00000097          	auipc	ra,0x0
    80002f36:	bac080e7          	jalr	-1108(ra) # 80002ade <argint>
  // printf("Syscall number: %d \n",x);
  myproc()->trac_stat = x;
    80002f3a:	fffff097          	auipc	ra,0xfffff
    80002f3e:	a8c080e7          	jalr	-1396(ra) # 800019c6 <myproc>
    80002f42:	fec42783          	lw	a5,-20(s0)
    80002f46:	d95c                	sw	a5,52(a0)
  return 1;
    80002f48:	4505                	li	a0,1
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f52:	7179                	addi	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	e84a                	sd	s2,16(sp)
    80002f5c:	e44e                	sd	s3,8(sp)
    80002f5e:	e052                	sd	s4,0(sp)
    80002f60:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f62:	00005597          	auipc	a1,0x5
    80002f66:	79e58593          	addi	a1,a1,1950 # 80008700 <sysargs+0x60>
    80002f6a:	00014517          	auipc	a0,0x14
    80002f6e:	c0e50513          	addi	a0,a0,-1010 # 80016b78 <bcache>
    80002f72:	ffffe097          	auipc	ra,0xffffe
    80002f76:	be8080e7          	jalr	-1048(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f7a:	0001c797          	auipc	a5,0x1c
    80002f7e:	bfe78793          	addi	a5,a5,-1026 # 8001eb78 <bcache+0x8000>
    80002f82:	0001c717          	auipc	a4,0x1c
    80002f86:	e5e70713          	addi	a4,a4,-418 # 8001ede0 <bcache+0x8268>
    80002f8a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f8e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f92:	00014497          	auipc	s1,0x14
    80002f96:	bfe48493          	addi	s1,s1,-1026 # 80016b90 <bcache+0x18>
    b->next = bcache.head.next;
    80002f9a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f9c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f9e:	00005a17          	auipc	s4,0x5
    80002fa2:	76aa0a13          	addi	s4,s4,1898 # 80008708 <sysargs+0x68>
    b->next = bcache.head.next;
    80002fa6:	2b893783          	ld	a5,696(s2)
    80002faa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fac:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fb0:	85d2                	mv	a1,s4
    80002fb2:	01048513          	addi	a0,s1,16
    80002fb6:	00001097          	auipc	ra,0x1
    80002fba:	4c4080e7          	jalr	1220(ra) # 8000447a <initsleeplock>
    bcache.head.next->prev = b;
    80002fbe:	2b893783          	ld	a5,696(s2)
    80002fc2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fc4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc8:	45848493          	addi	s1,s1,1112
    80002fcc:	fd349de3          	bne	s1,s3,80002fa6 <binit+0x54>
  }
}
    80002fd0:	70a2                	ld	ra,40(sp)
    80002fd2:	7402                	ld	s0,32(sp)
    80002fd4:	64e2                	ld	s1,24(sp)
    80002fd6:	6942                	ld	s2,16(sp)
    80002fd8:	69a2                	ld	s3,8(sp)
    80002fda:	6a02                	ld	s4,0(sp)
    80002fdc:	6145                	addi	sp,sp,48
    80002fde:	8082                	ret

0000000080002fe0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fe0:	7179                	addi	sp,sp,-48
    80002fe2:	f406                	sd	ra,40(sp)
    80002fe4:	f022                	sd	s0,32(sp)
    80002fe6:	ec26                	sd	s1,24(sp)
    80002fe8:	e84a                	sd	s2,16(sp)
    80002fea:	e44e                	sd	s3,8(sp)
    80002fec:	1800                	addi	s0,sp,48
    80002fee:	89aa                	mv	s3,a0
    80002ff0:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002ff2:	00014517          	auipc	a0,0x14
    80002ff6:	b8650513          	addi	a0,a0,-1146 # 80016b78 <bcache>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	bf0080e7          	jalr	-1040(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003002:	0001c497          	auipc	s1,0x1c
    80003006:	e2e4b483          	ld	s1,-466(s1) # 8001ee30 <bcache+0x82b8>
    8000300a:	0001c797          	auipc	a5,0x1c
    8000300e:	dd678793          	addi	a5,a5,-554 # 8001ede0 <bcache+0x8268>
    80003012:	02f48f63          	beq	s1,a5,80003050 <bread+0x70>
    80003016:	873e                	mv	a4,a5
    80003018:	a021                	j	80003020 <bread+0x40>
    8000301a:	68a4                	ld	s1,80(s1)
    8000301c:	02e48a63          	beq	s1,a4,80003050 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003020:	449c                	lw	a5,8(s1)
    80003022:	ff379ce3          	bne	a5,s3,8000301a <bread+0x3a>
    80003026:	44dc                	lw	a5,12(s1)
    80003028:	ff2799e3          	bne	a5,s2,8000301a <bread+0x3a>
      b->refcnt++;
    8000302c:	40bc                	lw	a5,64(s1)
    8000302e:	2785                	addiw	a5,a5,1
    80003030:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	b4650513          	addi	a0,a0,-1210 # 80016b78 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c64080e7          	jalr	-924(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003042:	01048513          	addi	a0,s1,16
    80003046:	00001097          	auipc	ra,0x1
    8000304a:	46e080e7          	jalr	1134(ra) # 800044b4 <acquiresleep>
      return b;
    8000304e:	a8b9                	j	800030ac <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003050:	0001c497          	auipc	s1,0x1c
    80003054:	dd84b483          	ld	s1,-552(s1) # 8001ee28 <bcache+0x82b0>
    80003058:	0001c797          	auipc	a5,0x1c
    8000305c:	d8878793          	addi	a5,a5,-632 # 8001ede0 <bcache+0x8268>
    80003060:	00f48863          	beq	s1,a5,80003070 <bread+0x90>
    80003064:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003066:	40bc                	lw	a5,64(s1)
    80003068:	cf81                	beqz	a5,80003080 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000306a:	64a4                	ld	s1,72(s1)
    8000306c:	fee49de3          	bne	s1,a4,80003066 <bread+0x86>
  panic("bget: no buffers");
    80003070:	00005517          	auipc	a0,0x5
    80003074:	6a050513          	addi	a0,a0,1696 # 80008710 <sysargs+0x70>
    80003078:	ffffd097          	auipc	ra,0xffffd
    8000307c:	4cc080e7          	jalr	1228(ra) # 80000544 <panic>
      b->dev = dev;
    80003080:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003084:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003088:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000308c:	4785                	li	a5,1
    8000308e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003090:	00014517          	auipc	a0,0x14
    80003094:	ae850513          	addi	a0,a0,-1304 # 80016b78 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	c06080e7          	jalr	-1018(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800030a0:	01048513          	addi	a0,s1,16
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	410080e7          	jalr	1040(ra) # 800044b4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030ac:	409c                	lw	a5,0(s1)
    800030ae:	cb89                	beqz	a5,800030c0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030b0:	8526                	mv	a0,s1
    800030b2:	70a2                	ld	ra,40(sp)
    800030b4:	7402                	ld	s0,32(sp)
    800030b6:	64e2                	ld	s1,24(sp)
    800030b8:	6942                	ld	s2,16(sp)
    800030ba:	69a2                	ld	s3,8(sp)
    800030bc:	6145                	addi	sp,sp,48
    800030be:	8082                	ret
    virtio_disk_rw(b, 0);
    800030c0:	4581                	li	a1,0
    800030c2:	8526                	mv	a0,s1
    800030c4:	00003097          	auipc	ra,0x3
    800030c8:	fc4080e7          	jalr	-60(ra) # 80006088 <virtio_disk_rw>
    b->valid = 1;
    800030cc:	4785                	li	a5,1
    800030ce:	c09c                	sw	a5,0(s1)
  return b;
    800030d0:	b7c5                	j	800030b0 <bread+0xd0>

00000000800030d2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030d2:	1101                	addi	sp,sp,-32
    800030d4:	ec06                	sd	ra,24(sp)
    800030d6:	e822                	sd	s0,16(sp)
    800030d8:	e426                	sd	s1,8(sp)
    800030da:	1000                	addi	s0,sp,32
    800030dc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030de:	0541                	addi	a0,a0,16
    800030e0:	00001097          	auipc	ra,0x1
    800030e4:	46e080e7          	jalr	1134(ra) # 8000454e <holdingsleep>
    800030e8:	cd01                	beqz	a0,80003100 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030ea:	4585                	li	a1,1
    800030ec:	8526                	mv	a0,s1
    800030ee:	00003097          	auipc	ra,0x3
    800030f2:	f9a080e7          	jalr	-102(ra) # 80006088 <virtio_disk_rw>
}
    800030f6:	60e2                	ld	ra,24(sp)
    800030f8:	6442                	ld	s0,16(sp)
    800030fa:	64a2                	ld	s1,8(sp)
    800030fc:	6105                	addi	sp,sp,32
    800030fe:	8082                	ret
    panic("bwrite");
    80003100:	00005517          	auipc	a0,0x5
    80003104:	62850513          	addi	a0,a0,1576 # 80008728 <sysargs+0x88>
    80003108:	ffffd097          	auipc	ra,0xffffd
    8000310c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>

0000000080003110 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003110:	1101                	addi	sp,sp,-32
    80003112:	ec06                	sd	ra,24(sp)
    80003114:	e822                	sd	s0,16(sp)
    80003116:	e426                	sd	s1,8(sp)
    80003118:	e04a                	sd	s2,0(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311e:	01050913          	addi	s2,a0,16
    80003122:	854a                	mv	a0,s2
    80003124:	00001097          	auipc	ra,0x1
    80003128:	42a080e7          	jalr	1066(ra) # 8000454e <holdingsleep>
    8000312c:	c92d                	beqz	a0,8000319e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000312e:	854a                	mv	a0,s2
    80003130:	00001097          	auipc	ra,0x1
    80003134:	3da080e7          	jalr	986(ra) # 8000450a <releasesleep>

  acquire(&bcache.lock);
    80003138:	00014517          	auipc	a0,0x14
    8000313c:	a4050513          	addi	a0,a0,-1472 # 80016b78 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	aaa080e7          	jalr	-1366(ra) # 80000bea <acquire>
  b->refcnt--;
    80003148:	40bc                	lw	a5,64(s1)
    8000314a:	37fd                	addiw	a5,a5,-1
    8000314c:	0007871b          	sext.w	a4,a5
    80003150:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003152:	eb05                	bnez	a4,80003182 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003154:	68bc                	ld	a5,80(s1)
    80003156:	64b8                	ld	a4,72(s1)
    80003158:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000315a:	64bc                	ld	a5,72(s1)
    8000315c:	68b8                	ld	a4,80(s1)
    8000315e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003160:	0001c797          	auipc	a5,0x1c
    80003164:	a1878793          	addi	a5,a5,-1512 # 8001eb78 <bcache+0x8000>
    80003168:	2b87b703          	ld	a4,696(a5)
    8000316c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000316e:	0001c717          	auipc	a4,0x1c
    80003172:	c7270713          	addi	a4,a4,-910 # 8001ede0 <bcache+0x8268>
    80003176:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003178:	2b87b703          	ld	a4,696(a5)
    8000317c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000317e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	9f650513          	addi	a0,a0,-1546 # 80016b78 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	b14080e7          	jalr	-1260(ra) # 80000c9e <release>
}
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	64a2                	ld	s1,8(sp)
    80003198:	6902                	ld	s2,0(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret
    panic("brelse");
    8000319e:	00005517          	auipc	a0,0x5
    800031a2:	59250513          	addi	a0,a0,1426 # 80008730 <sysargs+0x90>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	39e080e7          	jalr	926(ra) # 80000544 <panic>

00000000800031ae <bpin>:

void
bpin(struct buf *b) {
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	1000                	addi	s0,sp,32
    800031b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ba:	00014517          	auipc	a0,0x14
    800031be:	9be50513          	addi	a0,a0,-1602 # 80016b78 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	a28080e7          	jalr	-1496(ra) # 80000bea <acquire>
  b->refcnt++;
    800031ca:	40bc                	lw	a5,64(s1)
    800031cc:	2785                	addiw	a5,a5,1
    800031ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031d0:	00014517          	auipc	a0,0x14
    800031d4:	9a850513          	addi	a0,a0,-1624 # 80016b78 <bcache>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	ac6080e7          	jalr	-1338(ra) # 80000c9e <release>
}
    800031e0:	60e2                	ld	ra,24(sp)
    800031e2:	6442                	ld	s0,16(sp)
    800031e4:	64a2                	ld	s1,8(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret

00000000800031ea <bunpin>:

void
bunpin(struct buf *b) {
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f6:	00014517          	auipc	a0,0x14
    800031fa:	98250513          	addi	a0,a0,-1662 # 80016b78 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	9ec080e7          	jalr	-1556(ra) # 80000bea <acquire>
  b->refcnt--;
    80003206:	40bc                	lw	a5,64(s1)
    80003208:	37fd                	addiw	a5,a5,-1
    8000320a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000320c:	00014517          	auipc	a0,0x14
    80003210:	96c50513          	addi	a0,a0,-1684 # 80016b78 <bcache>
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	a8a080e7          	jalr	-1398(ra) # 80000c9e <release>
}
    8000321c:	60e2                	ld	ra,24(sp)
    8000321e:	6442                	ld	s0,16(sp)
    80003220:	64a2                	ld	s1,8(sp)
    80003222:	6105                	addi	sp,sp,32
    80003224:	8082                	ret

0000000080003226 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003226:	1101                	addi	sp,sp,-32
    80003228:	ec06                	sd	ra,24(sp)
    8000322a:	e822                	sd	s0,16(sp)
    8000322c:	e426                	sd	s1,8(sp)
    8000322e:	e04a                	sd	s2,0(sp)
    80003230:	1000                	addi	s0,sp,32
    80003232:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003234:	00d5d59b          	srliw	a1,a1,0xd
    80003238:	0001c797          	auipc	a5,0x1c
    8000323c:	01c7a783          	lw	a5,28(a5) # 8001f254 <sb+0x1c>
    80003240:	9dbd                	addw	a1,a1,a5
    80003242:	00000097          	auipc	ra,0x0
    80003246:	d9e080e7          	jalr	-610(ra) # 80002fe0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000324a:	0074f713          	andi	a4,s1,7
    8000324e:	4785                	li	a5,1
    80003250:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003254:	14ce                	slli	s1,s1,0x33
    80003256:	90d9                	srli	s1,s1,0x36
    80003258:	00950733          	add	a4,a0,s1
    8000325c:	05874703          	lbu	a4,88(a4)
    80003260:	00e7f6b3          	and	a3,a5,a4
    80003264:	c69d                	beqz	a3,80003292 <bfree+0x6c>
    80003266:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003268:	94aa                	add	s1,s1,a0
    8000326a:	fff7c793          	not	a5,a5
    8000326e:	8ff9                	and	a5,a5,a4
    80003270:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003274:	00001097          	auipc	ra,0x1
    80003278:	120080e7          	jalr	288(ra) # 80004394 <log_write>
  brelse(bp);
    8000327c:	854a                	mv	a0,s2
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	e92080e7          	jalr	-366(ra) # 80003110 <brelse>
}
    80003286:	60e2                	ld	ra,24(sp)
    80003288:	6442                	ld	s0,16(sp)
    8000328a:	64a2                	ld	s1,8(sp)
    8000328c:	6902                	ld	s2,0(sp)
    8000328e:	6105                	addi	sp,sp,32
    80003290:	8082                	ret
    panic("freeing free block");
    80003292:	00005517          	auipc	a0,0x5
    80003296:	4a650513          	addi	a0,a0,1190 # 80008738 <sysargs+0x98>
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	2aa080e7          	jalr	682(ra) # 80000544 <panic>

00000000800032a2 <balloc>:
{
    800032a2:	711d                	addi	sp,sp,-96
    800032a4:	ec86                	sd	ra,88(sp)
    800032a6:	e8a2                	sd	s0,80(sp)
    800032a8:	e4a6                	sd	s1,72(sp)
    800032aa:	e0ca                	sd	s2,64(sp)
    800032ac:	fc4e                	sd	s3,56(sp)
    800032ae:	f852                	sd	s4,48(sp)
    800032b0:	f456                	sd	s5,40(sp)
    800032b2:	f05a                	sd	s6,32(sp)
    800032b4:	ec5e                	sd	s7,24(sp)
    800032b6:	e862                	sd	s8,16(sp)
    800032b8:	e466                	sd	s9,8(sp)
    800032ba:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032bc:	0001c797          	auipc	a5,0x1c
    800032c0:	f807a783          	lw	a5,-128(a5) # 8001f23c <sb+0x4>
    800032c4:	10078163          	beqz	a5,800033c6 <balloc+0x124>
    800032c8:	8baa                	mv	s7,a0
    800032ca:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032cc:	0001cb17          	auipc	s6,0x1c
    800032d0:	f6cb0b13          	addi	s6,s6,-148 # 8001f238 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032d6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032da:	6c89                	lui	s9,0x2
    800032dc:	a061                	j	80003364 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032de:	974a                	add	a4,a4,s2
    800032e0:	8fd5                	or	a5,a5,a3
    800032e2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032e6:	854a                	mv	a0,s2
    800032e8:	00001097          	auipc	ra,0x1
    800032ec:	0ac080e7          	jalr	172(ra) # 80004394 <log_write>
        brelse(bp);
    800032f0:	854a                	mv	a0,s2
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	e1e080e7          	jalr	-482(ra) # 80003110 <brelse>
  bp = bread(dev, bno);
    800032fa:	85a6                	mv	a1,s1
    800032fc:	855e                	mv	a0,s7
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	ce2080e7          	jalr	-798(ra) # 80002fe0 <bread>
    80003306:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003308:	40000613          	li	a2,1024
    8000330c:	4581                	li	a1,0
    8000330e:	05850513          	addi	a0,a0,88
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	9d4080e7          	jalr	-1580(ra) # 80000ce6 <memset>
  log_write(bp);
    8000331a:	854a                	mv	a0,s2
    8000331c:	00001097          	auipc	ra,0x1
    80003320:	078080e7          	jalr	120(ra) # 80004394 <log_write>
  brelse(bp);
    80003324:	854a                	mv	a0,s2
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	dea080e7          	jalr	-534(ra) # 80003110 <brelse>
}
    8000332e:	8526                	mv	a0,s1
    80003330:	60e6                	ld	ra,88(sp)
    80003332:	6446                	ld	s0,80(sp)
    80003334:	64a6                	ld	s1,72(sp)
    80003336:	6906                	ld	s2,64(sp)
    80003338:	79e2                	ld	s3,56(sp)
    8000333a:	7a42                	ld	s4,48(sp)
    8000333c:	7aa2                	ld	s5,40(sp)
    8000333e:	7b02                	ld	s6,32(sp)
    80003340:	6be2                	ld	s7,24(sp)
    80003342:	6c42                	ld	s8,16(sp)
    80003344:	6ca2                	ld	s9,8(sp)
    80003346:	6125                	addi	sp,sp,96
    80003348:	8082                	ret
    brelse(bp);
    8000334a:	854a                	mv	a0,s2
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	dc4080e7          	jalr	-572(ra) # 80003110 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003354:	015c87bb          	addw	a5,s9,s5
    80003358:	00078a9b          	sext.w	s5,a5
    8000335c:	004b2703          	lw	a4,4(s6)
    80003360:	06eaf363          	bgeu	s5,a4,800033c6 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003364:	41fad79b          	sraiw	a5,s5,0x1f
    80003368:	0137d79b          	srliw	a5,a5,0x13
    8000336c:	015787bb          	addw	a5,a5,s5
    80003370:	40d7d79b          	sraiw	a5,a5,0xd
    80003374:	01cb2583          	lw	a1,28(s6)
    80003378:	9dbd                	addw	a1,a1,a5
    8000337a:	855e                	mv	a0,s7
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	c64080e7          	jalr	-924(ra) # 80002fe0 <bread>
    80003384:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003386:	004b2503          	lw	a0,4(s6)
    8000338a:	000a849b          	sext.w	s1,s5
    8000338e:	8662                	mv	a2,s8
    80003390:	faa4fde3          	bgeu	s1,a0,8000334a <balloc+0xa8>
      m = 1 << (bi % 8);
    80003394:	41f6579b          	sraiw	a5,a2,0x1f
    80003398:	01d7d69b          	srliw	a3,a5,0x1d
    8000339c:	00c6873b          	addw	a4,a3,a2
    800033a0:	00777793          	andi	a5,a4,7
    800033a4:	9f95                	subw	a5,a5,a3
    800033a6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033aa:	4037571b          	sraiw	a4,a4,0x3
    800033ae:	00e906b3          	add	a3,s2,a4
    800033b2:	0586c683          	lbu	a3,88(a3)
    800033b6:	00d7f5b3          	and	a1,a5,a3
    800033ba:	d195                	beqz	a1,800032de <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033bc:	2605                	addiw	a2,a2,1
    800033be:	2485                	addiw	s1,s1,1
    800033c0:	fd4618e3          	bne	a2,s4,80003390 <balloc+0xee>
    800033c4:	b759                	j	8000334a <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	38a50513          	addi	a0,a0,906 # 80008750 <sysargs+0xb0>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	1c0080e7          	jalr	448(ra) # 8000058e <printf>
  return 0;
    800033d6:	4481                	li	s1,0
    800033d8:	bf99                	j	8000332e <balloc+0x8c>

00000000800033da <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033da:	7179                	addi	sp,sp,-48
    800033dc:	f406                	sd	ra,40(sp)
    800033de:	f022                	sd	s0,32(sp)
    800033e0:	ec26                	sd	s1,24(sp)
    800033e2:	e84a                	sd	s2,16(sp)
    800033e4:	e44e                	sd	s3,8(sp)
    800033e6:	e052                	sd	s4,0(sp)
    800033e8:	1800                	addi	s0,sp,48
    800033ea:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033ec:	47ad                	li	a5,11
    800033ee:	02b7e763          	bltu	a5,a1,8000341c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800033f2:	02059493          	slli	s1,a1,0x20
    800033f6:	9081                	srli	s1,s1,0x20
    800033f8:	048a                	slli	s1,s1,0x2
    800033fa:	94aa                	add	s1,s1,a0
    800033fc:	0504a903          	lw	s2,80(s1)
    80003400:	06091e63          	bnez	s2,8000347c <bmap+0xa2>
      addr = balloc(ip->dev);
    80003404:	4108                	lw	a0,0(a0)
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e9c080e7          	jalr	-356(ra) # 800032a2 <balloc>
    8000340e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003412:	06090563          	beqz	s2,8000347c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003416:	0524a823          	sw	s2,80(s1)
    8000341a:	a08d                	j	8000347c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000341c:	ff45849b          	addiw	s1,a1,-12
    80003420:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003424:	0ff00793          	li	a5,255
    80003428:	08e7e563          	bltu	a5,a4,800034b2 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000342c:	08052903          	lw	s2,128(a0)
    80003430:	00091d63          	bnez	s2,8000344a <bmap+0x70>
      addr = balloc(ip->dev);
    80003434:	4108                	lw	a0,0(a0)
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	e6c080e7          	jalr	-404(ra) # 800032a2 <balloc>
    8000343e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003442:	02090d63          	beqz	s2,8000347c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003446:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000344a:	85ca                	mv	a1,s2
    8000344c:	0009a503          	lw	a0,0(s3)
    80003450:	00000097          	auipc	ra,0x0
    80003454:	b90080e7          	jalr	-1136(ra) # 80002fe0 <bread>
    80003458:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000345a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000345e:	02049593          	slli	a1,s1,0x20
    80003462:	9181                	srli	a1,a1,0x20
    80003464:	058a                	slli	a1,a1,0x2
    80003466:	00b784b3          	add	s1,a5,a1
    8000346a:	0004a903          	lw	s2,0(s1)
    8000346e:	02090063          	beqz	s2,8000348e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003472:	8552                	mv	a0,s4
    80003474:	00000097          	auipc	ra,0x0
    80003478:	c9c080e7          	jalr	-868(ra) # 80003110 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000347c:	854a                	mv	a0,s2
    8000347e:	70a2                	ld	ra,40(sp)
    80003480:	7402                	ld	s0,32(sp)
    80003482:	64e2                	ld	s1,24(sp)
    80003484:	6942                	ld	s2,16(sp)
    80003486:	69a2                	ld	s3,8(sp)
    80003488:	6a02                	ld	s4,0(sp)
    8000348a:	6145                	addi	sp,sp,48
    8000348c:	8082                	ret
      addr = balloc(ip->dev);
    8000348e:	0009a503          	lw	a0,0(s3)
    80003492:	00000097          	auipc	ra,0x0
    80003496:	e10080e7          	jalr	-496(ra) # 800032a2 <balloc>
    8000349a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000349e:	fc090ae3          	beqz	s2,80003472 <bmap+0x98>
        a[bn] = addr;
    800034a2:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034a6:	8552                	mv	a0,s4
    800034a8:	00001097          	auipc	ra,0x1
    800034ac:	eec080e7          	jalr	-276(ra) # 80004394 <log_write>
    800034b0:	b7c9                	j	80003472 <bmap+0x98>
  panic("bmap: out of range");
    800034b2:	00005517          	auipc	a0,0x5
    800034b6:	2b650513          	addi	a0,a0,694 # 80008768 <sysargs+0xc8>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	08a080e7          	jalr	138(ra) # 80000544 <panic>

00000000800034c2 <iget>:
{
    800034c2:	7179                	addi	sp,sp,-48
    800034c4:	f406                	sd	ra,40(sp)
    800034c6:	f022                	sd	s0,32(sp)
    800034c8:	ec26                	sd	s1,24(sp)
    800034ca:	e84a                	sd	s2,16(sp)
    800034cc:	e44e                	sd	s3,8(sp)
    800034ce:	e052                	sd	s4,0(sp)
    800034d0:	1800                	addi	s0,sp,48
    800034d2:	89aa                	mv	s3,a0
    800034d4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034d6:	0001c517          	auipc	a0,0x1c
    800034da:	d8250513          	addi	a0,a0,-638 # 8001f258 <itable>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	70c080e7          	jalr	1804(ra) # 80000bea <acquire>
  empty = 0;
    800034e6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034e8:	0001c497          	auipc	s1,0x1c
    800034ec:	d8848493          	addi	s1,s1,-632 # 8001f270 <itable+0x18>
    800034f0:	0001e697          	auipc	a3,0x1e
    800034f4:	81068693          	addi	a3,a3,-2032 # 80020d00 <log>
    800034f8:	a039                	j	80003506 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034fa:	02090b63          	beqz	s2,80003530 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034fe:	08848493          	addi	s1,s1,136
    80003502:	02d48a63          	beq	s1,a3,80003536 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003506:	449c                	lw	a5,8(s1)
    80003508:	fef059e3          	blez	a5,800034fa <iget+0x38>
    8000350c:	4098                	lw	a4,0(s1)
    8000350e:	ff3716e3          	bne	a4,s3,800034fa <iget+0x38>
    80003512:	40d8                	lw	a4,4(s1)
    80003514:	ff4713e3          	bne	a4,s4,800034fa <iget+0x38>
      ip->ref++;
    80003518:	2785                	addiw	a5,a5,1
    8000351a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000351c:	0001c517          	auipc	a0,0x1c
    80003520:	d3c50513          	addi	a0,a0,-708 # 8001f258 <itable>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	77a080e7          	jalr	1914(ra) # 80000c9e <release>
      return ip;
    8000352c:	8926                	mv	s2,s1
    8000352e:	a03d                	j	8000355c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003530:	f7f9                	bnez	a5,800034fe <iget+0x3c>
    80003532:	8926                	mv	s2,s1
    80003534:	b7e9                	j	800034fe <iget+0x3c>
  if(empty == 0)
    80003536:	02090c63          	beqz	s2,8000356e <iget+0xac>
  ip->dev = dev;
    8000353a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000353e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003542:	4785                	li	a5,1
    80003544:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003548:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000354c:	0001c517          	auipc	a0,0x1c
    80003550:	d0c50513          	addi	a0,a0,-756 # 8001f258 <itable>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	74a080e7          	jalr	1866(ra) # 80000c9e <release>
}
    8000355c:	854a                	mv	a0,s2
    8000355e:	70a2                	ld	ra,40(sp)
    80003560:	7402                	ld	s0,32(sp)
    80003562:	64e2                	ld	s1,24(sp)
    80003564:	6942                	ld	s2,16(sp)
    80003566:	69a2                	ld	s3,8(sp)
    80003568:	6a02                	ld	s4,0(sp)
    8000356a:	6145                	addi	sp,sp,48
    8000356c:	8082                	ret
    panic("iget: no inodes");
    8000356e:	00005517          	auipc	a0,0x5
    80003572:	21250513          	addi	a0,a0,530 # 80008780 <sysargs+0xe0>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	fce080e7          	jalr	-50(ra) # 80000544 <panic>

000000008000357e <fsinit>:
fsinit(int dev) {
    8000357e:	7179                	addi	sp,sp,-48
    80003580:	f406                	sd	ra,40(sp)
    80003582:	f022                	sd	s0,32(sp)
    80003584:	ec26                	sd	s1,24(sp)
    80003586:	e84a                	sd	s2,16(sp)
    80003588:	e44e                	sd	s3,8(sp)
    8000358a:	1800                	addi	s0,sp,48
    8000358c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000358e:	4585                	li	a1,1
    80003590:	00000097          	auipc	ra,0x0
    80003594:	a50080e7          	jalr	-1456(ra) # 80002fe0 <bread>
    80003598:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000359a:	0001c997          	auipc	s3,0x1c
    8000359e:	c9e98993          	addi	s3,s3,-866 # 8001f238 <sb>
    800035a2:	02000613          	li	a2,32
    800035a6:	05850593          	addi	a1,a0,88
    800035aa:	854e                	mv	a0,s3
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	79a080e7          	jalr	1946(ra) # 80000d46 <memmove>
  brelse(bp);
    800035b4:	8526                	mv	a0,s1
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	b5a080e7          	jalr	-1190(ra) # 80003110 <brelse>
  if(sb.magic != FSMAGIC)
    800035be:	0009a703          	lw	a4,0(s3)
    800035c2:	102037b7          	lui	a5,0x10203
    800035c6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035ca:	02f71263          	bne	a4,a5,800035ee <fsinit+0x70>
  initlog(dev, &sb);
    800035ce:	0001c597          	auipc	a1,0x1c
    800035d2:	c6a58593          	addi	a1,a1,-918 # 8001f238 <sb>
    800035d6:	854a                	mv	a0,s2
    800035d8:	00001097          	auipc	ra,0x1
    800035dc:	b40080e7          	jalr	-1216(ra) # 80004118 <initlog>
}
    800035e0:	70a2                	ld	ra,40(sp)
    800035e2:	7402                	ld	s0,32(sp)
    800035e4:	64e2                	ld	s1,24(sp)
    800035e6:	6942                	ld	s2,16(sp)
    800035e8:	69a2                	ld	s3,8(sp)
    800035ea:	6145                	addi	sp,sp,48
    800035ec:	8082                	ret
    panic("invalid file system");
    800035ee:	00005517          	auipc	a0,0x5
    800035f2:	1a250513          	addi	a0,a0,418 # 80008790 <sysargs+0xf0>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	f4e080e7          	jalr	-178(ra) # 80000544 <panic>

00000000800035fe <iinit>:
{
    800035fe:	7179                	addi	sp,sp,-48
    80003600:	f406                	sd	ra,40(sp)
    80003602:	f022                	sd	s0,32(sp)
    80003604:	ec26                	sd	s1,24(sp)
    80003606:	e84a                	sd	s2,16(sp)
    80003608:	e44e                	sd	s3,8(sp)
    8000360a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000360c:	00005597          	auipc	a1,0x5
    80003610:	19c58593          	addi	a1,a1,412 # 800087a8 <sysargs+0x108>
    80003614:	0001c517          	auipc	a0,0x1c
    80003618:	c4450513          	addi	a0,a0,-956 # 8001f258 <itable>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	53e080e7          	jalr	1342(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003624:	0001c497          	auipc	s1,0x1c
    80003628:	c5c48493          	addi	s1,s1,-932 # 8001f280 <itable+0x28>
    8000362c:	0001d997          	auipc	s3,0x1d
    80003630:	6e498993          	addi	s3,s3,1764 # 80020d10 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003634:	00005917          	auipc	s2,0x5
    80003638:	17c90913          	addi	s2,s2,380 # 800087b0 <sysargs+0x110>
    8000363c:	85ca                	mv	a1,s2
    8000363e:	8526                	mv	a0,s1
    80003640:	00001097          	auipc	ra,0x1
    80003644:	e3a080e7          	jalr	-454(ra) # 8000447a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003648:	08848493          	addi	s1,s1,136
    8000364c:	ff3498e3          	bne	s1,s3,8000363c <iinit+0x3e>
}
    80003650:	70a2                	ld	ra,40(sp)
    80003652:	7402                	ld	s0,32(sp)
    80003654:	64e2                	ld	s1,24(sp)
    80003656:	6942                	ld	s2,16(sp)
    80003658:	69a2                	ld	s3,8(sp)
    8000365a:	6145                	addi	sp,sp,48
    8000365c:	8082                	ret

000000008000365e <ialloc>:
{
    8000365e:	715d                	addi	sp,sp,-80
    80003660:	e486                	sd	ra,72(sp)
    80003662:	e0a2                	sd	s0,64(sp)
    80003664:	fc26                	sd	s1,56(sp)
    80003666:	f84a                	sd	s2,48(sp)
    80003668:	f44e                	sd	s3,40(sp)
    8000366a:	f052                	sd	s4,32(sp)
    8000366c:	ec56                	sd	s5,24(sp)
    8000366e:	e85a                	sd	s6,16(sp)
    80003670:	e45e                	sd	s7,8(sp)
    80003672:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003674:	0001c717          	auipc	a4,0x1c
    80003678:	bd072703          	lw	a4,-1072(a4) # 8001f244 <sb+0xc>
    8000367c:	4785                	li	a5,1
    8000367e:	04e7fa63          	bgeu	a5,a4,800036d2 <ialloc+0x74>
    80003682:	8aaa                	mv	s5,a0
    80003684:	8bae                	mv	s7,a1
    80003686:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003688:	0001ca17          	auipc	s4,0x1c
    8000368c:	bb0a0a13          	addi	s4,s4,-1104 # 8001f238 <sb>
    80003690:	00048b1b          	sext.w	s6,s1
    80003694:	0044d593          	srli	a1,s1,0x4
    80003698:	018a2783          	lw	a5,24(s4)
    8000369c:	9dbd                	addw	a1,a1,a5
    8000369e:	8556                	mv	a0,s5
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	940080e7          	jalr	-1728(ra) # 80002fe0 <bread>
    800036a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036aa:	05850993          	addi	s3,a0,88
    800036ae:	00f4f793          	andi	a5,s1,15
    800036b2:	079a                	slli	a5,a5,0x6
    800036b4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036b6:	00099783          	lh	a5,0(s3)
    800036ba:	c3a1                	beqz	a5,800036fa <ialloc+0x9c>
    brelse(bp);
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	a54080e7          	jalr	-1452(ra) # 80003110 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036c4:	0485                	addi	s1,s1,1
    800036c6:	00ca2703          	lw	a4,12(s4)
    800036ca:	0004879b          	sext.w	a5,s1
    800036ce:	fce7e1e3          	bltu	a5,a4,80003690 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800036d2:	00005517          	auipc	a0,0x5
    800036d6:	0e650513          	addi	a0,a0,230 # 800087b8 <sysargs+0x118>
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	eb4080e7          	jalr	-332(ra) # 8000058e <printf>
  return 0;
    800036e2:	4501                	li	a0,0
}
    800036e4:	60a6                	ld	ra,72(sp)
    800036e6:	6406                	ld	s0,64(sp)
    800036e8:	74e2                	ld	s1,56(sp)
    800036ea:	7942                	ld	s2,48(sp)
    800036ec:	79a2                	ld	s3,40(sp)
    800036ee:	7a02                	ld	s4,32(sp)
    800036f0:	6ae2                	ld	s5,24(sp)
    800036f2:	6b42                	ld	s6,16(sp)
    800036f4:	6ba2                	ld	s7,8(sp)
    800036f6:	6161                	addi	sp,sp,80
    800036f8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036fa:	04000613          	li	a2,64
    800036fe:	4581                	li	a1,0
    80003700:	854e                	mv	a0,s3
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	5e4080e7          	jalr	1508(ra) # 80000ce6 <memset>
      dip->type = type;
    8000370a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000370e:	854a                	mv	a0,s2
    80003710:	00001097          	auipc	ra,0x1
    80003714:	c84080e7          	jalr	-892(ra) # 80004394 <log_write>
      brelse(bp);
    80003718:	854a                	mv	a0,s2
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	9f6080e7          	jalr	-1546(ra) # 80003110 <brelse>
      return iget(dev, inum);
    80003722:	85da                	mv	a1,s6
    80003724:	8556                	mv	a0,s5
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	d9c080e7          	jalr	-612(ra) # 800034c2 <iget>
    8000372e:	bf5d                	j	800036e4 <ialloc+0x86>

0000000080003730 <iupdate>:
{
    80003730:	1101                	addi	sp,sp,-32
    80003732:	ec06                	sd	ra,24(sp)
    80003734:	e822                	sd	s0,16(sp)
    80003736:	e426                	sd	s1,8(sp)
    80003738:	e04a                	sd	s2,0(sp)
    8000373a:	1000                	addi	s0,sp,32
    8000373c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000373e:	415c                	lw	a5,4(a0)
    80003740:	0047d79b          	srliw	a5,a5,0x4
    80003744:	0001c597          	auipc	a1,0x1c
    80003748:	b0c5a583          	lw	a1,-1268(a1) # 8001f250 <sb+0x18>
    8000374c:	9dbd                	addw	a1,a1,a5
    8000374e:	4108                	lw	a0,0(a0)
    80003750:	00000097          	auipc	ra,0x0
    80003754:	890080e7          	jalr	-1904(ra) # 80002fe0 <bread>
    80003758:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000375a:	05850793          	addi	a5,a0,88
    8000375e:	40c8                	lw	a0,4(s1)
    80003760:	893d                	andi	a0,a0,15
    80003762:	051a                	slli	a0,a0,0x6
    80003764:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003766:	04449703          	lh	a4,68(s1)
    8000376a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000376e:	04649703          	lh	a4,70(s1)
    80003772:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003776:	04849703          	lh	a4,72(s1)
    8000377a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000377e:	04a49703          	lh	a4,74(s1)
    80003782:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003786:	44f8                	lw	a4,76(s1)
    80003788:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000378a:	03400613          	li	a2,52
    8000378e:	05048593          	addi	a1,s1,80
    80003792:	0531                	addi	a0,a0,12
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	5b2080e7          	jalr	1458(ra) # 80000d46 <memmove>
  log_write(bp);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	bf6080e7          	jalr	-1034(ra) # 80004394 <log_write>
  brelse(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	968080e7          	jalr	-1688(ra) # 80003110 <brelse>
}
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6902                	ld	s2,0(sp)
    800037b8:	6105                	addi	sp,sp,32
    800037ba:	8082                	ret

00000000800037bc <idup>:
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	1000                	addi	s0,sp,32
    800037c6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037c8:	0001c517          	auipc	a0,0x1c
    800037cc:	a9050513          	addi	a0,a0,-1392 # 8001f258 <itable>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	41a080e7          	jalr	1050(ra) # 80000bea <acquire>
  ip->ref++;
    800037d8:	449c                	lw	a5,8(s1)
    800037da:	2785                	addiw	a5,a5,1
    800037dc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037de:	0001c517          	auipc	a0,0x1c
    800037e2:	a7a50513          	addi	a0,a0,-1414 # 8001f258 <itable>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	4b8080e7          	jalr	1208(ra) # 80000c9e <release>
}
    800037ee:	8526                	mv	a0,s1
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	64a2                	ld	s1,8(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret

00000000800037fa <ilock>:
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	e04a                	sd	s2,0(sp)
    80003804:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003806:	c115                	beqz	a0,8000382a <ilock+0x30>
    80003808:	84aa                	mv	s1,a0
    8000380a:	451c                	lw	a5,8(a0)
    8000380c:	00f05f63          	blez	a5,8000382a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003810:	0541                	addi	a0,a0,16
    80003812:	00001097          	auipc	ra,0x1
    80003816:	ca2080e7          	jalr	-862(ra) # 800044b4 <acquiresleep>
  if(ip->valid == 0){
    8000381a:	40bc                	lw	a5,64(s1)
    8000381c:	cf99                	beqz	a5,8000383a <ilock+0x40>
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6902                	ld	s2,0(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret
    panic("ilock");
    8000382a:	00005517          	auipc	a0,0x5
    8000382e:	fa650513          	addi	a0,a0,-90 # 800087d0 <sysargs+0x130>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	d12080e7          	jalr	-750(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000383a:	40dc                	lw	a5,4(s1)
    8000383c:	0047d79b          	srliw	a5,a5,0x4
    80003840:	0001c597          	auipc	a1,0x1c
    80003844:	a105a583          	lw	a1,-1520(a1) # 8001f250 <sb+0x18>
    80003848:	9dbd                	addw	a1,a1,a5
    8000384a:	4088                	lw	a0,0(s1)
    8000384c:	fffff097          	auipc	ra,0xfffff
    80003850:	794080e7          	jalr	1940(ra) # 80002fe0 <bread>
    80003854:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003856:	05850593          	addi	a1,a0,88
    8000385a:	40dc                	lw	a5,4(s1)
    8000385c:	8bbd                	andi	a5,a5,15
    8000385e:	079a                	slli	a5,a5,0x6
    80003860:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003862:	00059783          	lh	a5,0(a1)
    80003866:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000386a:	00259783          	lh	a5,2(a1)
    8000386e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003872:	00459783          	lh	a5,4(a1)
    80003876:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000387a:	00659783          	lh	a5,6(a1)
    8000387e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003882:	459c                	lw	a5,8(a1)
    80003884:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003886:	03400613          	li	a2,52
    8000388a:	05b1                	addi	a1,a1,12
    8000388c:	05048513          	addi	a0,s1,80
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	4b6080e7          	jalr	1206(ra) # 80000d46 <memmove>
    brelse(bp);
    80003898:	854a                	mv	a0,s2
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	876080e7          	jalr	-1930(ra) # 80003110 <brelse>
    ip->valid = 1;
    800038a2:	4785                	li	a5,1
    800038a4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038a6:	04449783          	lh	a5,68(s1)
    800038aa:	fbb5                	bnez	a5,8000381e <ilock+0x24>
      panic("ilock: no type");
    800038ac:	00005517          	auipc	a0,0x5
    800038b0:	f2c50513          	addi	a0,a0,-212 # 800087d8 <sysargs+0x138>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	c90080e7          	jalr	-880(ra) # 80000544 <panic>

00000000800038bc <iunlock>:
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	e04a                	sd	s2,0(sp)
    800038c6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038c8:	c905                	beqz	a0,800038f8 <iunlock+0x3c>
    800038ca:	84aa                	mv	s1,a0
    800038cc:	01050913          	addi	s2,a0,16
    800038d0:	854a                	mv	a0,s2
    800038d2:	00001097          	auipc	ra,0x1
    800038d6:	c7c080e7          	jalr	-900(ra) # 8000454e <holdingsleep>
    800038da:	cd19                	beqz	a0,800038f8 <iunlock+0x3c>
    800038dc:	449c                	lw	a5,8(s1)
    800038de:	00f05d63          	blez	a5,800038f8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00001097          	auipc	ra,0x1
    800038e8:	c26080e7          	jalr	-986(ra) # 8000450a <releasesleep>
}
    800038ec:	60e2                	ld	ra,24(sp)
    800038ee:	6442                	ld	s0,16(sp)
    800038f0:	64a2                	ld	s1,8(sp)
    800038f2:	6902                	ld	s2,0(sp)
    800038f4:	6105                	addi	sp,sp,32
    800038f6:	8082                	ret
    panic("iunlock");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	ef050513          	addi	a0,a0,-272 # 800087e8 <sysargs+0x148>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c44080e7          	jalr	-956(ra) # 80000544 <panic>

0000000080003908 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003908:	7179                	addi	sp,sp,-48
    8000390a:	f406                	sd	ra,40(sp)
    8000390c:	f022                	sd	s0,32(sp)
    8000390e:	ec26                	sd	s1,24(sp)
    80003910:	e84a                	sd	s2,16(sp)
    80003912:	e44e                	sd	s3,8(sp)
    80003914:	e052                	sd	s4,0(sp)
    80003916:	1800                	addi	s0,sp,48
    80003918:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000391a:	05050493          	addi	s1,a0,80
    8000391e:	08050913          	addi	s2,a0,128
    80003922:	a021                	j	8000392a <itrunc+0x22>
    80003924:	0491                	addi	s1,s1,4
    80003926:	01248d63          	beq	s1,s2,80003940 <itrunc+0x38>
    if(ip->addrs[i]){
    8000392a:	408c                	lw	a1,0(s1)
    8000392c:	dde5                	beqz	a1,80003924 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000392e:	0009a503          	lw	a0,0(s3)
    80003932:	00000097          	auipc	ra,0x0
    80003936:	8f4080e7          	jalr	-1804(ra) # 80003226 <bfree>
      ip->addrs[i] = 0;
    8000393a:	0004a023          	sw	zero,0(s1)
    8000393e:	b7dd                	j	80003924 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003940:	0809a583          	lw	a1,128(s3)
    80003944:	e185                	bnez	a1,80003964 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003946:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000394a:	854e                	mv	a0,s3
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	de4080e7          	jalr	-540(ra) # 80003730 <iupdate>
}
    80003954:	70a2                	ld	ra,40(sp)
    80003956:	7402                	ld	s0,32(sp)
    80003958:	64e2                	ld	s1,24(sp)
    8000395a:	6942                	ld	s2,16(sp)
    8000395c:	69a2                	ld	s3,8(sp)
    8000395e:	6a02                	ld	s4,0(sp)
    80003960:	6145                	addi	sp,sp,48
    80003962:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003964:	0009a503          	lw	a0,0(s3)
    80003968:	fffff097          	auipc	ra,0xfffff
    8000396c:	678080e7          	jalr	1656(ra) # 80002fe0 <bread>
    80003970:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003972:	05850493          	addi	s1,a0,88
    80003976:	45850913          	addi	s2,a0,1112
    8000397a:	a811                	j	8000398e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000397c:	0009a503          	lw	a0,0(s3)
    80003980:	00000097          	auipc	ra,0x0
    80003984:	8a6080e7          	jalr	-1882(ra) # 80003226 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003988:	0491                	addi	s1,s1,4
    8000398a:	01248563          	beq	s1,s2,80003994 <itrunc+0x8c>
      if(a[j])
    8000398e:	408c                	lw	a1,0(s1)
    80003990:	dde5                	beqz	a1,80003988 <itrunc+0x80>
    80003992:	b7ed                	j	8000397c <itrunc+0x74>
    brelse(bp);
    80003994:	8552                	mv	a0,s4
    80003996:	fffff097          	auipc	ra,0xfffff
    8000399a:	77a080e7          	jalr	1914(ra) # 80003110 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000399e:	0809a583          	lw	a1,128(s3)
    800039a2:	0009a503          	lw	a0,0(s3)
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	880080e7          	jalr	-1920(ra) # 80003226 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ae:	0809a023          	sw	zero,128(s3)
    800039b2:	bf51                	j	80003946 <itrunc+0x3e>

00000000800039b4 <iput>:
{
    800039b4:	1101                	addi	sp,sp,-32
    800039b6:	ec06                	sd	ra,24(sp)
    800039b8:	e822                	sd	s0,16(sp)
    800039ba:	e426                	sd	s1,8(sp)
    800039bc:	e04a                	sd	s2,0(sp)
    800039be:	1000                	addi	s0,sp,32
    800039c0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039c2:	0001c517          	auipc	a0,0x1c
    800039c6:	89650513          	addi	a0,a0,-1898 # 8001f258 <itable>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	220080e7          	jalr	544(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d2:	4498                	lw	a4,8(s1)
    800039d4:	4785                	li	a5,1
    800039d6:	02f70363          	beq	a4,a5,800039fc <iput+0x48>
  ip->ref--;
    800039da:	449c                	lw	a5,8(s1)
    800039dc:	37fd                	addiw	a5,a5,-1
    800039de:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039e0:	0001c517          	auipc	a0,0x1c
    800039e4:	87850513          	addi	a0,a0,-1928 # 8001f258 <itable>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	2b6080e7          	jalr	694(ra) # 80000c9e <release>
}
    800039f0:	60e2                	ld	ra,24(sp)
    800039f2:	6442                	ld	s0,16(sp)
    800039f4:	64a2                	ld	s1,8(sp)
    800039f6:	6902                	ld	s2,0(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039fc:	40bc                	lw	a5,64(s1)
    800039fe:	dff1                	beqz	a5,800039da <iput+0x26>
    80003a00:	04a49783          	lh	a5,74(s1)
    80003a04:	fbf9                	bnez	a5,800039da <iput+0x26>
    acquiresleep(&ip->lock);
    80003a06:	01048913          	addi	s2,s1,16
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	aa8080e7          	jalr	-1368(ra) # 800044b4 <acquiresleep>
    release(&itable.lock);
    80003a14:	0001c517          	auipc	a0,0x1c
    80003a18:	84450513          	addi	a0,a0,-1980 # 8001f258 <itable>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	282080e7          	jalr	642(ra) # 80000c9e <release>
    itrunc(ip);
    80003a24:	8526                	mv	a0,s1
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	ee2080e7          	jalr	-286(ra) # 80003908 <itrunc>
    ip->type = 0;
    80003a2e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a32:	8526                	mv	a0,s1
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	cfc080e7          	jalr	-772(ra) # 80003730 <iupdate>
    ip->valid = 0;
    80003a3c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	ac8080e7          	jalr	-1336(ra) # 8000450a <releasesleep>
    acquire(&itable.lock);
    80003a4a:	0001c517          	auipc	a0,0x1c
    80003a4e:	80e50513          	addi	a0,a0,-2034 # 8001f258 <itable>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	198080e7          	jalr	408(ra) # 80000bea <acquire>
    80003a5a:	b741                	j	800039da <iput+0x26>

0000000080003a5c <iunlockput>:
{
    80003a5c:	1101                	addi	sp,sp,-32
    80003a5e:	ec06                	sd	ra,24(sp)
    80003a60:	e822                	sd	s0,16(sp)
    80003a62:	e426                	sd	s1,8(sp)
    80003a64:	1000                	addi	s0,sp,32
    80003a66:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	e54080e7          	jalr	-428(ra) # 800038bc <iunlock>
  iput(ip);
    80003a70:	8526                	mv	a0,s1
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	f42080e7          	jalr	-190(ra) # 800039b4 <iput>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6105                	addi	sp,sp,32
    80003a82:	8082                	ret

0000000080003a84 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a84:	1141                	addi	sp,sp,-16
    80003a86:	e422                	sd	s0,8(sp)
    80003a88:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a8a:	411c                	lw	a5,0(a0)
    80003a8c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a8e:	415c                	lw	a5,4(a0)
    80003a90:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a92:	04451783          	lh	a5,68(a0)
    80003a96:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a9a:	04a51783          	lh	a5,74(a0)
    80003a9e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003aa2:	04c56783          	lwu	a5,76(a0)
    80003aa6:	e99c                	sd	a5,16(a1)
}
    80003aa8:	6422                	ld	s0,8(sp)
    80003aaa:	0141                	addi	sp,sp,16
    80003aac:	8082                	ret

0000000080003aae <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aae:	457c                	lw	a5,76(a0)
    80003ab0:	0ed7e963          	bltu	a5,a3,80003ba2 <readi+0xf4>
{
    80003ab4:	7159                	addi	sp,sp,-112
    80003ab6:	f486                	sd	ra,104(sp)
    80003ab8:	f0a2                	sd	s0,96(sp)
    80003aba:	eca6                	sd	s1,88(sp)
    80003abc:	e8ca                	sd	s2,80(sp)
    80003abe:	e4ce                	sd	s3,72(sp)
    80003ac0:	e0d2                	sd	s4,64(sp)
    80003ac2:	fc56                	sd	s5,56(sp)
    80003ac4:	f85a                	sd	s6,48(sp)
    80003ac6:	f45e                	sd	s7,40(sp)
    80003ac8:	f062                	sd	s8,32(sp)
    80003aca:	ec66                	sd	s9,24(sp)
    80003acc:	e86a                	sd	s10,16(sp)
    80003ace:	e46e                	sd	s11,8(sp)
    80003ad0:	1880                	addi	s0,sp,112
    80003ad2:	8b2a                	mv	s6,a0
    80003ad4:	8bae                	mv	s7,a1
    80003ad6:	8a32                	mv	s4,a2
    80003ad8:	84b6                	mv	s1,a3
    80003ada:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003adc:	9f35                	addw	a4,a4,a3
    return 0;
    80003ade:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ae0:	0ad76063          	bltu	a4,a3,80003b80 <readi+0xd2>
  if(off + n > ip->size)
    80003ae4:	00e7f463          	bgeu	a5,a4,80003aec <readi+0x3e>
    n = ip->size - off;
    80003ae8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aec:	0a0a8963          	beqz	s5,80003b9e <readi+0xf0>
    80003af0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003af6:	5c7d                	li	s8,-1
    80003af8:	a82d                	j	80003b32 <readi+0x84>
    80003afa:	020d1d93          	slli	s11,s10,0x20
    80003afe:	020ddd93          	srli	s11,s11,0x20
    80003b02:	05890613          	addi	a2,s2,88
    80003b06:	86ee                	mv	a3,s11
    80003b08:	963a                	add	a2,a2,a4
    80003b0a:	85d2                	mv	a1,s4
    80003b0c:	855e                	mv	a0,s7
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	96c080e7          	jalr	-1684(ra) # 8000247a <either_copyout>
    80003b16:	05850d63          	beq	a0,s8,80003b70 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b1a:	854a                	mv	a0,s2
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	5f4080e7          	jalr	1524(ra) # 80003110 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b24:	013d09bb          	addw	s3,s10,s3
    80003b28:	009d04bb          	addw	s1,s10,s1
    80003b2c:	9a6e                	add	s4,s4,s11
    80003b2e:	0559f763          	bgeu	s3,s5,80003b7c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b32:	00a4d59b          	srliw	a1,s1,0xa
    80003b36:	855a                	mv	a0,s6
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	8a2080e7          	jalr	-1886(ra) # 800033da <bmap>
    80003b40:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b44:	cd85                	beqz	a1,80003b7c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b46:	000b2503          	lw	a0,0(s6)
    80003b4a:	fffff097          	auipc	ra,0xfffff
    80003b4e:	496080e7          	jalr	1174(ra) # 80002fe0 <bread>
    80003b52:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b54:	3ff4f713          	andi	a4,s1,1023
    80003b58:	40ec87bb          	subw	a5,s9,a4
    80003b5c:	413a86bb          	subw	a3,s5,s3
    80003b60:	8d3e                	mv	s10,a5
    80003b62:	2781                	sext.w	a5,a5
    80003b64:	0006861b          	sext.w	a2,a3
    80003b68:	f8f679e3          	bgeu	a2,a5,80003afa <readi+0x4c>
    80003b6c:	8d36                	mv	s10,a3
    80003b6e:	b771                	j	80003afa <readi+0x4c>
      brelse(bp);
    80003b70:	854a                	mv	a0,s2
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	59e080e7          	jalr	1438(ra) # 80003110 <brelse>
      tot = -1;
    80003b7a:	59fd                	li	s3,-1
  }
  return tot;
    80003b7c:	0009851b          	sext.w	a0,s3
}
    80003b80:	70a6                	ld	ra,104(sp)
    80003b82:	7406                	ld	s0,96(sp)
    80003b84:	64e6                	ld	s1,88(sp)
    80003b86:	6946                	ld	s2,80(sp)
    80003b88:	69a6                	ld	s3,72(sp)
    80003b8a:	6a06                	ld	s4,64(sp)
    80003b8c:	7ae2                	ld	s5,56(sp)
    80003b8e:	7b42                	ld	s6,48(sp)
    80003b90:	7ba2                	ld	s7,40(sp)
    80003b92:	7c02                	ld	s8,32(sp)
    80003b94:	6ce2                	ld	s9,24(sp)
    80003b96:	6d42                	ld	s10,16(sp)
    80003b98:	6da2                	ld	s11,8(sp)
    80003b9a:	6165                	addi	sp,sp,112
    80003b9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b9e:	89d6                	mv	s3,s5
    80003ba0:	bff1                	j	80003b7c <readi+0xce>
    return 0;
    80003ba2:	4501                	li	a0,0
}
    80003ba4:	8082                	ret

0000000080003ba6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ba6:	457c                	lw	a5,76(a0)
    80003ba8:	10d7e863          	bltu	a5,a3,80003cb8 <writei+0x112>
{
    80003bac:	7159                	addi	sp,sp,-112
    80003bae:	f486                	sd	ra,104(sp)
    80003bb0:	f0a2                	sd	s0,96(sp)
    80003bb2:	eca6                	sd	s1,88(sp)
    80003bb4:	e8ca                	sd	s2,80(sp)
    80003bb6:	e4ce                	sd	s3,72(sp)
    80003bb8:	e0d2                	sd	s4,64(sp)
    80003bba:	fc56                	sd	s5,56(sp)
    80003bbc:	f85a                	sd	s6,48(sp)
    80003bbe:	f45e                	sd	s7,40(sp)
    80003bc0:	f062                	sd	s8,32(sp)
    80003bc2:	ec66                	sd	s9,24(sp)
    80003bc4:	e86a                	sd	s10,16(sp)
    80003bc6:	e46e                	sd	s11,8(sp)
    80003bc8:	1880                	addi	s0,sp,112
    80003bca:	8aaa                	mv	s5,a0
    80003bcc:	8bae                	mv	s7,a1
    80003bce:	8a32                	mv	s4,a2
    80003bd0:	8936                	mv	s2,a3
    80003bd2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bd4:	00e687bb          	addw	a5,a3,a4
    80003bd8:	0ed7e263          	bltu	a5,a3,80003cbc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bdc:	00043737          	lui	a4,0x43
    80003be0:	0ef76063          	bltu	a4,a5,80003cc0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be4:	0c0b0863          	beqz	s6,80003cb4 <writei+0x10e>
    80003be8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bea:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bee:	5c7d                	li	s8,-1
    80003bf0:	a091                	j	80003c34 <writei+0x8e>
    80003bf2:	020d1d93          	slli	s11,s10,0x20
    80003bf6:	020ddd93          	srli	s11,s11,0x20
    80003bfa:	05848513          	addi	a0,s1,88
    80003bfe:	86ee                	mv	a3,s11
    80003c00:	8652                	mv	a2,s4
    80003c02:	85de                	mv	a1,s7
    80003c04:	953a                	add	a0,a0,a4
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	8ca080e7          	jalr	-1846(ra) # 800024d0 <either_copyin>
    80003c0e:	07850263          	beq	a0,s8,80003c72 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c12:	8526                	mv	a0,s1
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	780080e7          	jalr	1920(ra) # 80004394 <log_write>
    brelse(bp);
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	4f2080e7          	jalr	1266(ra) # 80003110 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c26:	013d09bb          	addw	s3,s10,s3
    80003c2a:	012d093b          	addw	s2,s10,s2
    80003c2e:	9a6e                	add	s4,s4,s11
    80003c30:	0569f663          	bgeu	s3,s6,80003c7c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c34:	00a9559b          	srliw	a1,s2,0xa
    80003c38:	8556                	mv	a0,s5
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	7a0080e7          	jalr	1952(ra) # 800033da <bmap>
    80003c42:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c46:	c99d                	beqz	a1,80003c7c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c48:	000aa503          	lw	a0,0(s5)
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	394080e7          	jalr	916(ra) # 80002fe0 <bread>
    80003c54:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c56:	3ff97713          	andi	a4,s2,1023
    80003c5a:	40ec87bb          	subw	a5,s9,a4
    80003c5e:	413b06bb          	subw	a3,s6,s3
    80003c62:	8d3e                	mv	s10,a5
    80003c64:	2781                	sext.w	a5,a5
    80003c66:	0006861b          	sext.w	a2,a3
    80003c6a:	f8f674e3          	bgeu	a2,a5,80003bf2 <writei+0x4c>
    80003c6e:	8d36                	mv	s10,a3
    80003c70:	b749                	j	80003bf2 <writei+0x4c>
      brelse(bp);
    80003c72:	8526                	mv	a0,s1
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	49c080e7          	jalr	1180(ra) # 80003110 <brelse>
  }

  if(off > ip->size)
    80003c7c:	04caa783          	lw	a5,76(s5)
    80003c80:	0127f463          	bgeu	a5,s2,80003c88 <writei+0xe2>
    ip->size = off;
    80003c84:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c88:	8556                	mv	a0,s5
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	aa6080e7          	jalr	-1370(ra) # 80003730 <iupdate>

  return tot;
    80003c92:	0009851b          	sext.w	a0,s3
}
    80003c96:	70a6                	ld	ra,104(sp)
    80003c98:	7406                	ld	s0,96(sp)
    80003c9a:	64e6                	ld	s1,88(sp)
    80003c9c:	6946                	ld	s2,80(sp)
    80003c9e:	69a6                	ld	s3,72(sp)
    80003ca0:	6a06                	ld	s4,64(sp)
    80003ca2:	7ae2                	ld	s5,56(sp)
    80003ca4:	7b42                	ld	s6,48(sp)
    80003ca6:	7ba2                	ld	s7,40(sp)
    80003ca8:	7c02                	ld	s8,32(sp)
    80003caa:	6ce2                	ld	s9,24(sp)
    80003cac:	6d42                	ld	s10,16(sp)
    80003cae:	6da2                	ld	s11,8(sp)
    80003cb0:	6165                	addi	sp,sp,112
    80003cb2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb4:	89da                	mv	s3,s6
    80003cb6:	bfc9                	j	80003c88 <writei+0xe2>
    return -1;
    80003cb8:	557d                	li	a0,-1
}
    80003cba:	8082                	ret
    return -1;
    80003cbc:	557d                	li	a0,-1
    80003cbe:	bfe1                	j	80003c96 <writei+0xf0>
    return -1;
    80003cc0:	557d                	li	a0,-1
    80003cc2:	bfd1                	j	80003c96 <writei+0xf0>

0000000080003cc4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cc4:	1141                	addi	sp,sp,-16
    80003cc6:	e406                	sd	ra,8(sp)
    80003cc8:	e022                	sd	s0,0(sp)
    80003cca:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ccc:	4639                	li	a2,14
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	0f0080e7          	jalr	240(ra) # 80000dbe <strncmp>
}
    80003cd6:	60a2                	ld	ra,8(sp)
    80003cd8:	6402                	ld	s0,0(sp)
    80003cda:	0141                	addi	sp,sp,16
    80003cdc:	8082                	ret

0000000080003cde <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cde:	7139                	addi	sp,sp,-64
    80003ce0:	fc06                	sd	ra,56(sp)
    80003ce2:	f822                	sd	s0,48(sp)
    80003ce4:	f426                	sd	s1,40(sp)
    80003ce6:	f04a                	sd	s2,32(sp)
    80003ce8:	ec4e                	sd	s3,24(sp)
    80003cea:	e852                	sd	s4,16(sp)
    80003cec:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cee:	04451703          	lh	a4,68(a0)
    80003cf2:	4785                	li	a5,1
    80003cf4:	00f71a63          	bne	a4,a5,80003d08 <dirlookup+0x2a>
    80003cf8:	892a                	mv	s2,a0
    80003cfa:	89ae                	mv	s3,a1
    80003cfc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfe:	457c                	lw	a5,76(a0)
    80003d00:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d02:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d04:	e79d                	bnez	a5,80003d32 <dirlookup+0x54>
    80003d06:	a8a5                	j	80003d7e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d08:	00005517          	auipc	a0,0x5
    80003d0c:	ae850513          	addi	a0,a0,-1304 # 800087f0 <sysargs+0x150>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	834080e7          	jalr	-1996(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003d18:	00005517          	auipc	a0,0x5
    80003d1c:	af050513          	addi	a0,a0,-1296 # 80008808 <sysargs+0x168>
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	824080e7          	jalr	-2012(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d28:	24c1                	addiw	s1,s1,16
    80003d2a:	04c92783          	lw	a5,76(s2)
    80003d2e:	04f4f763          	bgeu	s1,a5,80003d7c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d32:	4741                	li	a4,16
    80003d34:	86a6                	mv	a3,s1
    80003d36:	fc040613          	addi	a2,s0,-64
    80003d3a:	4581                	li	a1,0
    80003d3c:	854a                	mv	a0,s2
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	d70080e7          	jalr	-656(ra) # 80003aae <readi>
    80003d46:	47c1                	li	a5,16
    80003d48:	fcf518e3          	bne	a0,a5,80003d18 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d4c:	fc045783          	lhu	a5,-64(s0)
    80003d50:	dfe1                	beqz	a5,80003d28 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d52:	fc240593          	addi	a1,s0,-62
    80003d56:	854e                	mv	a0,s3
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	f6c080e7          	jalr	-148(ra) # 80003cc4 <namecmp>
    80003d60:	f561                	bnez	a0,80003d28 <dirlookup+0x4a>
      if(poff)
    80003d62:	000a0463          	beqz	s4,80003d6a <dirlookup+0x8c>
        *poff = off;
    80003d66:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d6a:	fc045583          	lhu	a1,-64(s0)
    80003d6e:	00092503          	lw	a0,0(s2)
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	750080e7          	jalr	1872(ra) # 800034c2 <iget>
    80003d7a:	a011                	j	80003d7e <dirlookup+0xa0>
  return 0;
    80003d7c:	4501                	li	a0,0
}
    80003d7e:	70e2                	ld	ra,56(sp)
    80003d80:	7442                	ld	s0,48(sp)
    80003d82:	74a2                	ld	s1,40(sp)
    80003d84:	7902                	ld	s2,32(sp)
    80003d86:	69e2                	ld	s3,24(sp)
    80003d88:	6a42                	ld	s4,16(sp)
    80003d8a:	6121                	addi	sp,sp,64
    80003d8c:	8082                	ret

0000000080003d8e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d8e:	711d                	addi	sp,sp,-96
    80003d90:	ec86                	sd	ra,88(sp)
    80003d92:	e8a2                	sd	s0,80(sp)
    80003d94:	e4a6                	sd	s1,72(sp)
    80003d96:	e0ca                	sd	s2,64(sp)
    80003d98:	fc4e                	sd	s3,56(sp)
    80003d9a:	f852                	sd	s4,48(sp)
    80003d9c:	f456                	sd	s5,40(sp)
    80003d9e:	f05a                	sd	s6,32(sp)
    80003da0:	ec5e                	sd	s7,24(sp)
    80003da2:	e862                	sd	s8,16(sp)
    80003da4:	e466                	sd	s9,8(sp)
    80003da6:	1080                	addi	s0,sp,96
    80003da8:	84aa                	mv	s1,a0
    80003daa:	8b2e                	mv	s6,a1
    80003dac:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dae:	00054703          	lbu	a4,0(a0)
    80003db2:	02f00793          	li	a5,47
    80003db6:	02f70363          	beq	a4,a5,80003ddc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dba:	ffffe097          	auipc	ra,0xffffe
    80003dbe:	c0c080e7          	jalr	-1012(ra) # 800019c6 <myproc>
    80003dc2:	15053503          	ld	a0,336(a0)
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	9f6080e7          	jalr	-1546(ra) # 800037bc <idup>
    80003dce:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dd0:	02f00913          	li	s2,47
  len = path - s;
    80003dd4:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dd6:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dd8:	4c05                	li	s8,1
    80003dda:	a865                	j	80003e92 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ddc:	4585                	li	a1,1
    80003dde:	4505                	li	a0,1
    80003de0:	fffff097          	auipc	ra,0xfffff
    80003de4:	6e2080e7          	jalr	1762(ra) # 800034c2 <iget>
    80003de8:	89aa                	mv	s3,a0
    80003dea:	b7dd                	j	80003dd0 <namex+0x42>
      iunlockput(ip);
    80003dec:	854e                	mv	a0,s3
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	c6e080e7          	jalr	-914(ra) # 80003a5c <iunlockput>
      return 0;
    80003df6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003df8:	854e                	mv	a0,s3
    80003dfa:	60e6                	ld	ra,88(sp)
    80003dfc:	6446                	ld	s0,80(sp)
    80003dfe:	64a6                	ld	s1,72(sp)
    80003e00:	6906                	ld	s2,64(sp)
    80003e02:	79e2                	ld	s3,56(sp)
    80003e04:	7a42                	ld	s4,48(sp)
    80003e06:	7aa2                	ld	s5,40(sp)
    80003e08:	7b02                	ld	s6,32(sp)
    80003e0a:	6be2                	ld	s7,24(sp)
    80003e0c:	6c42                	ld	s8,16(sp)
    80003e0e:	6ca2                	ld	s9,8(sp)
    80003e10:	6125                	addi	sp,sp,96
    80003e12:	8082                	ret
      iunlock(ip);
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	aa6080e7          	jalr	-1370(ra) # 800038bc <iunlock>
      return ip;
    80003e1e:	bfe9                	j	80003df8 <namex+0x6a>
      iunlockput(ip);
    80003e20:	854e                	mv	a0,s3
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	c3a080e7          	jalr	-966(ra) # 80003a5c <iunlockput>
      return 0;
    80003e2a:	89d2                	mv	s3,s4
    80003e2c:	b7f1                	j	80003df8 <namex+0x6a>
  len = path - s;
    80003e2e:	40b48633          	sub	a2,s1,a1
    80003e32:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e36:	094cd463          	bge	s9,s4,80003ebe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e3a:	4639                	li	a2,14
    80003e3c:	8556                	mv	a0,s5
    80003e3e:	ffffd097          	auipc	ra,0xffffd
    80003e42:	f08080e7          	jalr	-248(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e46:	0004c783          	lbu	a5,0(s1)
    80003e4a:	01279763          	bne	a5,s2,80003e58 <namex+0xca>
    path++;
    80003e4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e50:	0004c783          	lbu	a5,0(s1)
    80003e54:	ff278de3          	beq	a5,s2,80003e4e <namex+0xc0>
    ilock(ip);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	9a0080e7          	jalr	-1632(ra) # 800037fa <ilock>
    if(ip->type != T_DIR){
    80003e62:	04499783          	lh	a5,68(s3)
    80003e66:	f98793e3          	bne	a5,s8,80003dec <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e6a:	000b0563          	beqz	s6,80003e74 <namex+0xe6>
    80003e6e:	0004c783          	lbu	a5,0(s1)
    80003e72:	d3cd                	beqz	a5,80003e14 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e74:	865e                	mv	a2,s7
    80003e76:	85d6                	mv	a1,s5
    80003e78:	854e                	mv	a0,s3
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	e64080e7          	jalr	-412(ra) # 80003cde <dirlookup>
    80003e82:	8a2a                	mv	s4,a0
    80003e84:	dd51                	beqz	a0,80003e20 <namex+0x92>
    iunlockput(ip);
    80003e86:	854e                	mv	a0,s3
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	bd4080e7          	jalr	-1068(ra) # 80003a5c <iunlockput>
    ip = next;
    80003e90:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e92:	0004c783          	lbu	a5,0(s1)
    80003e96:	05279763          	bne	a5,s2,80003ee4 <namex+0x156>
    path++;
    80003e9a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	ff278de3          	beq	a5,s2,80003e9a <namex+0x10c>
  if(*path == 0)
    80003ea4:	c79d                	beqz	a5,80003ed2 <namex+0x144>
    path++;
    80003ea6:	85a6                	mv	a1,s1
  len = path - s;
    80003ea8:	8a5e                	mv	s4,s7
    80003eaa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003eac:	01278963          	beq	a5,s2,80003ebe <namex+0x130>
    80003eb0:	dfbd                	beqz	a5,80003e2e <namex+0xa0>
    path++;
    80003eb2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	ff279ce3          	bne	a5,s2,80003eb0 <namex+0x122>
    80003ebc:	bf8d                	j	80003e2e <namex+0xa0>
    memmove(name, s, len);
    80003ebe:	2601                	sext.w	a2,a2
    80003ec0:	8556                	mv	a0,s5
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	e84080e7          	jalr	-380(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003eca:	9a56                	add	s4,s4,s5
    80003ecc:	000a0023          	sb	zero,0(s4)
    80003ed0:	bf9d                	j	80003e46 <namex+0xb8>
  if(nameiparent){
    80003ed2:	f20b03e3          	beqz	s6,80003df8 <namex+0x6a>
    iput(ip);
    80003ed6:	854e                	mv	a0,s3
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	adc080e7          	jalr	-1316(ra) # 800039b4 <iput>
    return 0;
    80003ee0:	4981                	li	s3,0
    80003ee2:	bf19                	j	80003df8 <namex+0x6a>
  if(*path == 0)
    80003ee4:	d7fd                	beqz	a5,80003ed2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ee6:	0004c783          	lbu	a5,0(s1)
    80003eea:	85a6                	mv	a1,s1
    80003eec:	b7d1                	j	80003eb0 <namex+0x122>

0000000080003eee <dirlink>:
{
    80003eee:	7139                	addi	sp,sp,-64
    80003ef0:	fc06                	sd	ra,56(sp)
    80003ef2:	f822                	sd	s0,48(sp)
    80003ef4:	f426                	sd	s1,40(sp)
    80003ef6:	f04a                	sd	s2,32(sp)
    80003ef8:	ec4e                	sd	s3,24(sp)
    80003efa:	e852                	sd	s4,16(sp)
    80003efc:	0080                	addi	s0,sp,64
    80003efe:	892a                	mv	s2,a0
    80003f00:	8a2e                	mv	s4,a1
    80003f02:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f04:	4601                	li	a2,0
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	dd8080e7          	jalr	-552(ra) # 80003cde <dirlookup>
    80003f0e:	e93d                	bnez	a0,80003f84 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f10:	04c92483          	lw	s1,76(s2)
    80003f14:	c49d                	beqz	s1,80003f42 <dirlink+0x54>
    80003f16:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f18:	4741                	li	a4,16
    80003f1a:	86a6                	mv	a3,s1
    80003f1c:	fc040613          	addi	a2,s0,-64
    80003f20:	4581                	li	a1,0
    80003f22:	854a                	mv	a0,s2
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	b8a080e7          	jalr	-1142(ra) # 80003aae <readi>
    80003f2c:	47c1                	li	a5,16
    80003f2e:	06f51163          	bne	a0,a5,80003f90 <dirlink+0xa2>
    if(de.inum == 0)
    80003f32:	fc045783          	lhu	a5,-64(s0)
    80003f36:	c791                	beqz	a5,80003f42 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f38:	24c1                	addiw	s1,s1,16
    80003f3a:	04c92783          	lw	a5,76(s2)
    80003f3e:	fcf4ede3          	bltu	s1,a5,80003f18 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f42:	4639                	li	a2,14
    80003f44:	85d2                	mv	a1,s4
    80003f46:	fc240513          	addi	a0,s0,-62
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	eb0080e7          	jalr	-336(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f52:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f56:	4741                	li	a4,16
    80003f58:	86a6                	mv	a3,s1
    80003f5a:	fc040613          	addi	a2,s0,-64
    80003f5e:	4581                	li	a1,0
    80003f60:	854a                	mv	a0,s2
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	c44080e7          	jalr	-956(ra) # 80003ba6 <writei>
    80003f6a:	1541                	addi	a0,a0,-16
    80003f6c:	00a03533          	snez	a0,a0
    80003f70:	40a00533          	neg	a0,a0
}
    80003f74:	70e2                	ld	ra,56(sp)
    80003f76:	7442                	ld	s0,48(sp)
    80003f78:	74a2                	ld	s1,40(sp)
    80003f7a:	7902                	ld	s2,32(sp)
    80003f7c:	69e2                	ld	s3,24(sp)
    80003f7e:	6a42                	ld	s4,16(sp)
    80003f80:	6121                	addi	sp,sp,64
    80003f82:	8082                	ret
    iput(ip);
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	a30080e7          	jalr	-1488(ra) # 800039b4 <iput>
    return -1;
    80003f8c:	557d                	li	a0,-1
    80003f8e:	b7dd                	j	80003f74 <dirlink+0x86>
      panic("dirlink read");
    80003f90:	00005517          	auipc	a0,0x5
    80003f94:	88850513          	addi	a0,a0,-1912 # 80008818 <sysargs+0x178>
    80003f98:	ffffc097          	auipc	ra,0xffffc
    80003f9c:	5ac080e7          	jalr	1452(ra) # 80000544 <panic>

0000000080003fa0 <namei>:

struct inode*
namei(char *path)
{
    80003fa0:	1101                	addi	sp,sp,-32
    80003fa2:	ec06                	sd	ra,24(sp)
    80003fa4:	e822                	sd	s0,16(sp)
    80003fa6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fa8:	fe040613          	addi	a2,s0,-32
    80003fac:	4581                	li	a1,0
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	de0080e7          	jalr	-544(ra) # 80003d8e <namex>
}
    80003fb6:	60e2                	ld	ra,24(sp)
    80003fb8:	6442                	ld	s0,16(sp)
    80003fba:	6105                	addi	sp,sp,32
    80003fbc:	8082                	ret

0000000080003fbe <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fbe:	1141                	addi	sp,sp,-16
    80003fc0:	e406                	sd	ra,8(sp)
    80003fc2:	e022                	sd	s0,0(sp)
    80003fc4:	0800                	addi	s0,sp,16
    80003fc6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fc8:	4585                	li	a1,1
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	dc4080e7          	jalr	-572(ra) # 80003d8e <namex>
}
    80003fd2:	60a2                	ld	ra,8(sp)
    80003fd4:	6402                	ld	s0,0(sp)
    80003fd6:	0141                	addi	sp,sp,16
    80003fd8:	8082                	ret

0000000080003fda <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	e426                	sd	s1,8(sp)
    80003fe2:	e04a                	sd	s2,0(sp)
    80003fe4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fe6:	0001d917          	auipc	s2,0x1d
    80003fea:	d1a90913          	addi	s2,s2,-742 # 80020d00 <log>
    80003fee:	01892583          	lw	a1,24(s2)
    80003ff2:	02892503          	lw	a0,40(s2)
    80003ff6:	fffff097          	auipc	ra,0xfffff
    80003ffa:	fea080e7          	jalr	-22(ra) # 80002fe0 <bread>
    80003ffe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004000:	02c92683          	lw	a3,44(s2)
    80004004:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004006:	02d05763          	blez	a3,80004034 <write_head+0x5a>
    8000400a:	0001d797          	auipc	a5,0x1d
    8000400e:	d2678793          	addi	a5,a5,-730 # 80020d30 <log+0x30>
    80004012:	05c50713          	addi	a4,a0,92
    80004016:	36fd                	addiw	a3,a3,-1
    80004018:	1682                	slli	a3,a3,0x20
    8000401a:	9281                	srli	a3,a3,0x20
    8000401c:	068a                	slli	a3,a3,0x2
    8000401e:	0001d617          	auipc	a2,0x1d
    80004022:	d1660613          	addi	a2,a2,-746 # 80020d34 <log+0x34>
    80004026:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004028:	4390                	lw	a2,0(a5)
    8000402a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000402c:	0791                	addi	a5,a5,4
    8000402e:	0711                	addi	a4,a4,4
    80004030:	fed79ce3          	bne	a5,a3,80004028 <write_head+0x4e>
  }
  bwrite(buf);
    80004034:	8526                	mv	a0,s1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	09c080e7          	jalr	156(ra) # 800030d2 <bwrite>
  brelse(buf);
    8000403e:	8526                	mv	a0,s1
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	0d0080e7          	jalr	208(ra) # 80003110 <brelse>
}
    80004048:	60e2                	ld	ra,24(sp)
    8000404a:	6442                	ld	s0,16(sp)
    8000404c:	64a2                	ld	s1,8(sp)
    8000404e:	6902                	ld	s2,0(sp)
    80004050:	6105                	addi	sp,sp,32
    80004052:	8082                	ret

0000000080004054 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004054:	0001d797          	auipc	a5,0x1d
    80004058:	cd87a783          	lw	a5,-808(a5) # 80020d2c <log+0x2c>
    8000405c:	0af05d63          	blez	a5,80004116 <install_trans+0xc2>
{
    80004060:	7139                	addi	sp,sp,-64
    80004062:	fc06                	sd	ra,56(sp)
    80004064:	f822                	sd	s0,48(sp)
    80004066:	f426                	sd	s1,40(sp)
    80004068:	f04a                	sd	s2,32(sp)
    8000406a:	ec4e                	sd	s3,24(sp)
    8000406c:	e852                	sd	s4,16(sp)
    8000406e:	e456                	sd	s5,8(sp)
    80004070:	e05a                	sd	s6,0(sp)
    80004072:	0080                	addi	s0,sp,64
    80004074:	8b2a                	mv	s6,a0
    80004076:	0001da97          	auipc	s5,0x1d
    8000407a:	cbaa8a93          	addi	s5,s5,-838 # 80020d30 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004080:	0001d997          	auipc	s3,0x1d
    80004084:	c8098993          	addi	s3,s3,-896 # 80020d00 <log>
    80004088:	a035                	j	800040b4 <install_trans+0x60>
      bunpin(dbuf);
    8000408a:	8526                	mv	a0,s1
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	15e080e7          	jalr	350(ra) # 800031ea <bunpin>
    brelse(lbuf);
    80004094:	854a                	mv	a0,s2
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	07a080e7          	jalr	122(ra) # 80003110 <brelse>
    brelse(dbuf);
    8000409e:	8526                	mv	a0,s1
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	070080e7          	jalr	112(ra) # 80003110 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a8:	2a05                	addiw	s4,s4,1
    800040aa:	0a91                	addi	s5,s5,4
    800040ac:	02c9a783          	lw	a5,44(s3)
    800040b0:	04fa5963          	bge	s4,a5,80004102 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040b4:	0189a583          	lw	a1,24(s3)
    800040b8:	014585bb          	addw	a1,a1,s4
    800040bc:	2585                	addiw	a1,a1,1
    800040be:	0289a503          	lw	a0,40(s3)
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	f1e080e7          	jalr	-226(ra) # 80002fe0 <bread>
    800040ca:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040cc:	000aa583          	lw	a1,0(s5)
    800040d0:	0289a503          	lw	a0,40(s3)
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	f0c080e7          	jalr	-244(ra) # 80002fe0 <bread>
    800040dc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040de:	40000613          	li	a2,1024
    800040e2:	05890593          	addi	a1,s2,88
    800040e6:	05850513          	addi	a0,a0,88
    800040ea:	ffffd097          	auipc	ra,0xffffd
    800040ee:	c5c080e7          	jalr	-932(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040f2:	8526                	mv	a0,s1
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	fde080e7          	jalr	-34(ra) # 800030d2 <bwrite>
    if(recovering == 0)
    800040fc:	f80b1ce3          	bnez	s6,80004094 <install_trans+0x40>
    80004100:	b769                	j	8000408a <install_trans+0x36>
}
    80004102:	70e2                	ld	ra,56(sp)
    80004104:	7442                	ld	s0,48(sp)
    80004106:	74a2                	ld	s1,40(sp)
    80004108:	7902                	ld	s2,32(sp)
    8000410a:	69e2                	ld	s3,24(sp)
    8000410c:	6a42                	ld	s4,16(sp)
    8000410e:	6aa2                	ld	s5,8(sp)
    80004110:	6b02                	ld	s6,0(sp)
    80004112:	6121                	addi	sp,sp,64
    80004114:	8082                	ret
    80004116:	8082                	ret

0000000080004118 <initlog>:
{
    80004118:	7179                	addi	sp,sp,-48
    8000411a:	f406                	sd	ra,40(sp)
    8000411c:	f022                	sd	s0,32(sp)
    8000411e:	ec26                	sd	s1,24(sp)
    80004120:	e84a                	sd	s2,16(sp)
    80004122:	e44e                	sd	s3,8(sp)
    80004124:	1800                	addi	s0,sp,48
    80004126:	892a                	mv	s2,a0
    80004128:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000412a:	0001d497          	auipc	s1,0x1d
    8000412e:	bd648493          	addi	s1,s1,-1066 # 80020d00 <log>
    80004132:	00004597          	auipc	a1,0x4
    80004136:	6f658593          	addi	a1,a1,1782 # 80008828 <sysargs+0x188>
    8000413a:	8526                	mv	a0,s1
    8000413c:	ffffd097          	auipc	ra,0xffffd
    80004140:	a1e080e7          	jalr	-1506(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004144:	0149a583          	lw	a1,20(s3)
    80004148:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000414a:	0109a783          	lw	a5,16(s3)
    8000414e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004150:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004154:	854a                	mv	a0,s2
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	e8a080e7          	jalr	-374(ra) # 80002fe0 <bread>
  log.lh.n = lh->n;
    8000415e:	4d3c                	lw	a5,88(a0)
    80004160:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004162:	02f05563          	blez	a5,8000418c <initlog+0x74>
    80004166:	05c50713          	addi	a4,a0,92
    8000416a:	0001d697          	auipc	a3,0x1d
    8000416e:	bc668693          	addi	a3,a3,-1082 # 80020d30 <log+0x30>
    80004172:	37fd                	addiw	a5,a5,-1
    80004174:	1782                	slli	a5,a5,0x20
    80004176:	9381                	srli	a5,a5,0x20
    80004178:	078a                	slli	a5,a5,0x2
    8000417a:	06050613          	addi	a2,a0,96
    8000417e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004180:	4310                	lw	a2,0(a4)
    80004182:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004184:	0711                	addi	a4,a4,4
    80004186:	0691                	addi	a3,a3,4
    80004188:	fef71ce3          	bne	a4,a5,80004180 <initlog+0x68>
  brelse(buf);
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	f84080e7          	jalr	-124(ra) # 80003110 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004194:	4505                	li	a0,1
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	ebe080e7          	jalr	-322(ra) # 80004054 <install_trans>
  log.lh.n = 0;
    8000419e:	0001d797          	auipc	a5,0x1d
    800041a2:	b807a723          	sw	zero,-1138(a5) # 80020d2c <log+0x2c>
  write_head(); // clear the log
    800041a6:	00000097          	auipc	ra,0x0
    800041aa:	e34080e7          	jalr	-460(ra) # 80003fda <write_head>
}
    800041ae:	70a2                	ld	ra,40(sp)
    800041b0:	7402                	ld	s0,32(sp)
    800041b2:	64e2                	ld	s1,24(sp)
    800041b4:	6942                	ld	s2,16(sp)
    800041b6:	69a2                	ld	s3,8(sp)
    800041b8:	6145                	addi	sp,sp,48
    800041ba:	8082                	ret

00000000800041bc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041bc:	1101                	addi	sp,sp,-32
    800041be:	ec06                	sd	ra,24(sp)
    800041c0:	e822                	sd	s0,16(sp)
    800041c2:	e426                	sd	s1,8(sp)
    800041c4:	e04a                	sd	s2,0(sp)
    800041c6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041c8:	0001d517          	auipc	a0,0x1d
    800041cc:	b3850513          	addi	a0,a0,-1224 # 80020d00 <log>
    800041d0:	ffffd097          	auipc	ra,0xffffd
    800041d4:	a1a080e7          	jalr	-1510(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800041d8:	0001d497          	auipc	s1,0x1d
    800041dc:	b2848493          	addi	s1,s1,-1240 # 80020d00 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041e0:	4979                	li	s2,30
    800041e2:	a039                	j	800041f0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041e4:	85a6                	mv	a1,s1
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	e8a080e7          	jalr	-374(ra) # 80002072 <sleep>
    if(log.committing){
    800041f0:	50dc                	lw	a5,36(s1)
    800041f2:	fbed                	bnez	a5,800041e4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041f4:	509c                	lw	a5,32(s1)
    800041f6:	0017871b          	addiw	a4,a5,1
    800041fa:	0007069b          	sext.w	a3,a4
    800041fe:	0027179b          	slliw	a5,a4,0x2
    80004202:	9fb9                	addw	a5,a5,a4
    80004204:	0017979b          	slliw	a5,a5,0x1
    80004208:	54d8                	lw	a4,44(s1)
    8000420a:	9fb9                	addw	a5,a5,a4
    8000420c:	00f95963          	bge	s2,a5,8000421e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004210:	85a6                	mv	a1,s1
    80004212:	8526                	mv	a0,s1
    80004214:	ffffe097          	auipc	ra,0xffffe
    80004218:	e5e080e7          	jalr	-418(ra) # 80002072 <sleep>
    8000421c:	bfd1                	j	800041f0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000421e:	0001d517          	auipc	a0,0x1d
    80004222:	ae250513          	addi	a0,a0,-1310 # 80020d00 <log>
    80004226:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	a76080e7          	jalr	-1418(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004230:	60e2                	ld	ra,24(sp)
    80004232:	6442                	ld	s0,16(sp)
    80004234:	64a2                	ld	s1,8(sp)
    80004236:	6902                	ld	s2,0(sp)
    80004238:	6105                	addi	sp,sp,32
    8000423a:	8082                	ret

000000008000423c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000423c:	7139                	addi	sp,sp,-64
    8000423e:	fc06                	sd	ra,56(sp)
    80004240:	f822                	sd	s0,48(sp)
    80004242:	f426                	sd	s1,40(sp)
    80004244:	f04a                	sd	s2,32(sp)
    80004246:	ec4e                	sd	s3,24(sp)
    80004248:	e852                	sd	s4,16(sp)
    8000424a:	e456                	sd	s5,8(sp)
    8000424c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000424e:	0001d497          	auipc	s1,0x1d
    80004252:	ab248493          	addi	s1,s1,-1358 # 80020d00 <log>
    80004256:	8526                	mv	a0,s1
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	992080e7          	jalr	-1646(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004260:	509c                	lw	a5,32(s1)
    80004262:	37fd                	addiw	a5,a5,-1
    80004264:	0007891b          	sext.w	s2,a5
    80004268:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000426a:	50dc                	lw	a5,36(s1)
    8000426c:	efb9                	bnez	a5,800042ca <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000426e:	06091663          	bnez	s2,800042da <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004272:	0001d497          	auipc	s1,0x1d
    80004276:	a8e48493          	addi	s1,s1,-1394 # 80020d00 <log>
    8000427a:	4785                	li	a5,1
    8000427c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000427e:	8526                	mv	a0,s1
    80004280:	ffffd097          	auipc	ra,0xffffd
    80004284:	a1e080e7          	jalr	-1506(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004288:	54dc                	lw	a5,44(s1)
    8000428a:	06f04763          	bgtz	a5,800042f8 <end_op+0xbc>
    acquire(&log.lock);
    8000428e:	0001d497          	auipc	s1,0x1d
    80004292:	a7248493          	addi	s1,s1,-1422 # 80020d00 <log>
    80004296:	8526                	mv	a0,s1
    80004298:	ffffd097          	auipc	ra,0xffffd
    8000429c:	952080e7          	jalr	-1710(ra) # 80000bea <acquire>
    log.committing = 0;
    800042a0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffe097          	auipc	ra,0xffffe
    800042aa:	e30080e7          	jalr	-464(ra) # 800020d6 <wakeup>
    release(&log.lock);
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	9ee080e7          	jalr	-1554(ra) # 80000c9e <release>
}
    800042b8:	70e2                	ld	ra,56(sp)
    800042ba:	7442                	ld	s0,48(sp)
    800042bc:	74a2                	ld	s1,40(sp)
    800042be:	7902                	ld	s2,32(sp)
    800042c0:	69e2                	ld	s3,24(sp)
    800042c2:	6a42                	ld	s4,16(sp)
    800042c4:	6aa2                	ld	s5,8(sp)
    800042c6:	6121                	addi	sp,sp,64
    800042c8:	8082                	ret
    panic("log.committing");
    800042ca:	00004517          	auipc	a0,0x4
    800042ce:	56650513          	addi	a0,a0,1382 # 80008830 <sysargs+0x190>
    800042d2:	ffffc097          	auipc	ra,0xffffc
    800042d6:	272080e7          	jalr	626(ra) # 80000544 <panic>
    wakeup(&log);
    800042da:	0001d497          	auipc	s1,0x1d
    800042de:	a2648493          	addi	s1,s1,-1498 # 80020d00 <log>
    800042e2:	8526                	mv	a0,s1
    800042e4:	ffffe097          	auipc	ra,0xffffe
    800042e8:	df2080e7          	jalr	-526(ra) # 800020d6 <wakeup>
  release(&log.lock);
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	9b0080e7          	jalr	-1616(ra) # 80000c9e <release>
  if(do_commit){
    800042f6:	b7c9                	j	800042b8 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f8:	0001da97          	auipc	s5,0x1d
    800042fc:	a38a8a93          	addi	s5,s5,-1480 # 80020d30 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004300:	0001da17          	auipc	s4,0x1d
    80004304:	a00a0a13          	addi	s4,s4,-1536 # 80020d00 <log>
    80004308:	018a2583          	lw	a1,24(s4)
    8000430c:	012585bb          	addw	a1,a1,s2
    80004310:	2585                	addiw	a1,a1,1
    80004312:	028a2503          	lw	a0,40(s4)
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	cca080e7          	jalr	-822(ra) # 80002fe0 <bread>
    8000431e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004320:	000aa583          	lw	a1,0(s5)
    80004324:	028a2503          	lw	a0,40(s4)
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	cb8080e7          	jalr	-840(ra) # 80002fe0 <bread>
    80004330:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004332:	40000613          	li	a2,1024
    80004336:	05850593          	addi	a1,a0,88
    8000433a:	05848513          	addi	a0,s1,88
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	a08080e7          	jalr	-1528(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004346:	8526                	mv	a0,s1
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	d8a080e7          	jalr	-630(ra) # 800030d2 <bwrite>
    brelse(from);
    80004350:	854e                	mv	a0,s3
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	dbe080e7          	jalr	-578(ra) # 80003110 <brelse>
    brelse(to);
    8000435a:	8526                	mv	a0,s1
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	db4080e7          	jalr	-588(ra) # 80003110 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004364:	2905                	addiw	s2,s2,1
    80004366:	0a91                	addi	s5,s5,4
    80004368:	02ca2783          	lw	a5,44(s4)
    8000436c:	f8f94ee3          	blt	s2,a5,80004308 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004370:	00000097          	auipc	ra,0x0
    80004374:	c6a080e7          	jalr	-918(ra) # 80003fda <write_head>
    install_trans(0); // Now install writes to home locations
    80004378:	4501                	li	a0,0
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	cda080e7          	jalr	-806(ra) # 80004054 <install_trans>
    log.lh.n = 0;
    80004382:	0001d797          	auipc	a5,0x1d
    80004386:	9a07a523          	sw	zero,-1622(a5) # 80020d2c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	c50080e7          	jalr	-944(ra) # 80003fda <write_head>
    80004392:	bdf5                	j	8000428e <end_op+0x52>

0000000080004394 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004394:	1101                	addi	sp,sp,-32
    80004396:	ec06                	sd	ra,24(sp)
    80004398:	e822                	sd	s0,16(sp)
    8000439a:	e426                	sd	s1,8(sp)
    8000439c:	e04a                	sd	s2,0(sp)
    8000439e:	1000                	addi	s0,sp,32
    800043a0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043a2:	0001d917          	auipc	s2,0x1d
    800043a6:	95e90913          	addi	s2,s2,-1698 # 80020d00 <log>
    800043aa:	854a                	mv	a0,s2
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	83e080e7          	jalr	-1986(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043b4:	02c92603          	lw	a2,44(s2)
    800043b8:	47f5                	li	a5,29
    800043ba:	06c7c563          	blt	a5,a2,80004424 <log_write+0x90>
    800043be:	0001d797          	auipc	a5,0x1d
    800043c2:	95e7a783          	lw	a5,-1698(a5) # 80020d1c <log+0x1c>
    800043c6:	37fd                	addiw	a5,a5,-1
    800043c8:	04f65e63          	bge	a2,a5,80004424 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043cc:	0001d797          	auipc	a5,0x1d
    800043d0:	9547a783          	lw	a5,-1708(a5) # 80020d20 <log+0x20>
    800043d4:	06f05063          	blez	a5,80004434 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043d8:	4781                	li	a5,0
    800043da:	06c05563          	blez	a2,80004444 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043de:	44cc                	lw	a1,12(s1)
    800043e0:	0001d717          	auipc	a4,0x1d
    800043e4:	95070713          	addi	a4,a4,-1712 # 80020d30 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043e8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043ea:	4314                	lw	a3,0(a4)
    800043ec:	04b68c63          	beq	a3,a1,80004444 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043f0:	2785                	addiw	a5,a5,1
    800043f2:	0711                	addi	a4,a4,4
    800043f4:	fef61be3          	bne	a2,a5,800043ea <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043f8:	0621                	addi	a2,a2,8
    800043fa:	060a                	slli	a2,a2,0x2
    800043fc:	0001d797          	auipc	a5,0x1d
    80004400:	90478793          	addi	a5,a5,-1788 # 80020d00 <log>
    80004404:	963e                	add	a2,a2,a5
    80004406:	44dc                	lw	a5,12(s1)
    80004408:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000440a:	8526                	mv	a0,s1
    8000440c:	fffff097          	auipc	ra,0xfffff
    80004410:	da2080e7          	jalr	-606(ra) # 800031ae <bpin>
    log.lh.n++;
    80004414:	0001d717          	auipc	a4,0x1d
    80004418:	8ec70713          	addi	a4,a4,-1812 # 80020d00 <log>
    8000441c:	575c                	lw	a5,44(a4)
    8000441e:	2785                	addiw	a5,a5,1
    80004420:	d75c                	sw	a5,44(a4)
    80004422:	a835                	j	8000445e <log_write+0xca>
    panic("too big a transaction");
    80004424:	00004517          	auipc	a0,0x4
    80004428:	41c50513          	addi	a0,a0,1052 # 80008840 <sysargs+0x1a0>
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	118080e7          	jalr	280(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004434:	00004517          	auipc	a0,0x4
    80004438:	42450513          	addi	a0,a0,1060 # 80008858 <sysargs+0x1b8>
    8000443c:	ffffc097          	auipc	ra,0xffffc
    80004440:	108080e7          	jalr	264(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004444:	00878713          	addi	a4,a5,8
    80004448:	00271693          	slli	a3,a4,0x2
    8000444c:	0001d717          	auipc	a4,0x1d
    80004450:	8b470713          	addi	a4,a4,-1868 # 80020d00 <log>
    80004454:	9736                	add	a4,a4,a3
    80004456:	44d4                	lw	a3,12(s1)
    80004458:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000445a:	faf608e3          	beq	a2,a5,8000440a <log_write+0x76>
  }
  release(&log.lock);
    8000445e:	0001d517          	auipc	a0,0x1d
    80004462:	8a250513          	addi	a0,a0,-1886 # 80020d00 <log>
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	838080e7          	jalr	-1992(ra) # 80000c9e <release>
}
    8000446e:	60e2                	ld	ra,24(sp)
    80004470:	6442                	ld	s0,16(sp)
    80004472:	64a2                	ld	s1,8(sp)
    80004474:	6902                	ld	s2,0(sp)
    80004476:	6105                	addi	sp,sp,32
    80004478:	8082                	ret

000000008000447a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
    80004486:	84aa                	mv	s1,a0
    80004488:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000448a:	00004597          	auipc	a1,0x4
    8000448e:	3ee58593          	addi	a1,a1,1006 # 80008878 <sysargs+0x1d8>
    80004492:	0521                	addi	a0,a0,8
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	6c6080e7          	jalr	1734(ra) # 80000b5a <initlock>
  lk->name = name;
    8000449c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a4:	0204a423          	sw	zero,40(s1)
}
    800044a8:	60e2                	ld	ra,24(sp)
    800044aa:	6442                	ld	s0,16(sp)
    800044ac:	64a2                	ld	s1,8(sp)
    800044ae:	6902                	ld	s2,0(sp)
    800044b0:	6105                	addi	sp,sp,32
    800044b2:	8082                	ret

00000000800044b4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044b4:	1101                	addi	sp,sp,-32
    800044b6:	ec06                	sd	ra,24(sp)
    800044b8:	e822                	sd	s0,16(sp)
    800044ba:	e426                	sd	s1,8(sp)
    800044bc:	e04a                	sd	s2,0(sp)
    800044be:	1000                	addi	s0,sp,32
    800044c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c2:	00850913          	addi	s2,a0,8
    800044c6:	854a                	mv	a0,s2
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	722080e7          	jalr	1826(ra) # 80000bea <acquire>
  while (lk->locked) {
    800044d0:	409c                	lw	a5,0(s1)
    800044d2:	cb89                	beqz	a5,800044e4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044d4:	85ca                	mv	a1,s2
    800044d6:	8526                	mv	a0,s1
    800044d8:	ffffe097          	auipc	ra,0xffffe
    800044dc:	b9a080e7          	jalr	-1126(ra) # 80002072 <sleep>
  while (lk->locked) {
    800044e0:	409c                	lw	a5,0(s1)
    800044e2:	fbed                	bnez	a5,800044d4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044e4:	4785                	li	a5,1
    800044e6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	4de080e7          	jalr	1246(ra) # 800019c6 <myproc>
    800044f0:	591c                	lw	a5,48(a0)
    800044f2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	7a8080e7          	jalr	1960(ra) # 80000c9e <release>
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000450a:	1101                	addi	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	e04a                	sd	s2,0(sp)
    80004514:	1000                	addi	s0,sp,32
    80004516:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004518:	00850913          	addi	s2,a0,8
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	6cc080e7          	jalr	1740(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004526:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000452a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffe097          	auipc	ra,0xffffe
    80004534:	ba6080e7          	jalr	-1114(ra) # 800020d6 <wakeup>
  release(&lk->lk);
    80004538:	854a                	mv	a0,s2
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	764080e7          	jalr	1892(ra) # 80000c9e <release>
}
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6902                	ld	s2,0(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000454e:	7179                	addi	sp,sp,-48
    80004550:	f406                	sd	ra,40(sp)
    80004552:	f022                	sd	s0,32(sp)
    80004554:	ec26                	sd	s1,24(sp)
    80004556:	e84a                	sd	s2,16(sp)
    80004558:	e44e                	sd	s3,8(sp)
    8000455a:	1800                	addi	s0,sp,48
    8000455c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000455e:	00850913          	addi	s2,a0,8
    80004562:	854a                	mv	a0,s2
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	686080e7          	jalr	1670(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000456c:	409c                	lw	a5,0(s1)
    8000456e:	ef99                	bnez	a5,8000458c <holdingsleep+0x3e>
    80004570:	4481                	li	s1,0
  release(&lk->lk);
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	72a080e7          	jalr	1834(ra) # 80000c9e <release>
  return r;
}
    8000457c:	8526                	mv	a0,s1
    8000457e:	70a2                	ld	ra,40(sp)
    80004580:	7402                	ld	s0,32(sp)
    80004582:	64e2                	ld	s1,24(sp)
    80004584:	6942                	ld	s2,16(sp)
    80004586:	69a2                	ld	s3,8(sp)
    80004588:	6145                	addi	sp,sp,48
    8000458a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000458c:	0284a983          	lw	s3,40(s1)
    80004590:	ffffd097          	auipc	ra,0xffffd
    80004594:	436080e7          	jalr	1078(ra) # 800019c6 <myproc>
    80004598:	5904                	lw	s1,48(a0)
    8000459a:	413484b3          	sub	s1,s1,s3
    8000459e:	0014b493          	seqz	s1,s1
    800045a2:	bfc1                	j	80004572 <holdingsleep+0x24>

00000000800045a4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045a4:	1141                	addi	sp,sp,-16
    800045a6:	e406                	sd	ra,8(sp)
    800045a8:	e022                	sd	s0,0(sp)
    800045aa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045ac:	00004597          	auipc	a1,0x4
    800045b0:	2dc58593          	addi	a1,a1,732 # 80008888 <sysargs+0x1e8>
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	89450513          	addi	a0,a0,-1900 # 80020e48 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	59e080e7          	jalr	1438(ra) # 80000b5a <initlock>
}
    800045c4:	60a2                	ld	ra,8(sp)
    800045c6:	6402                	ld	s0,0(sp)
    800045c8:	0141                	addi	sp,sp,16
    800045ca:	8082                	ret

00000000800045cc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045d6:	0001d517          	auipc	a0,0x1d
    800045da:	87250513          	addi	a0,a0,-1934 # 80020e48 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	60c080e7          	jalr	1548(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045e6:	0001d497          	auipc	s1,0x1d
    800045ea:	87a48493          	addi	s1,s1,-1926 # 80020e60 <ftable+0x18>
    800045ee:	0001e717          	auipc	a4,0x1e
    800045f2:	81270713          	addi	a4,a4,-2030 # 80021e00 <disk>
    if(f->ref == 0){
    800045f6:	40dc                	lw	a5,4(s1)
    800045f8:	cf99                	beqz	a5,80004616 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045fa:	02848493          	addi	s1,s1,40
    800045fe:	fee49ce3          	bne	s1,a4,800045f6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004602:	0001d517          	auipc	a0,0x1d
    80004606:	84650513          	addi	a0,a0,-1978 # 80020e48 <ftable>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	694080e7          	jalr	1684(ra) # 80000c9e <release>
  return 0;
    80004612:	4481                	li	s1,0
    80004614:	a819                	j	8000462a <filealloc+0x5e>
      f->ref = 1;
    80004616:	4785                	li	a5,1
    80004618:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000461a:	0001d517          	auipc	a0,0x1d
    8000461e:	82e50513          	addi	a0,a0,-2002 # 80020e48 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	67c080e7          	jalr	1660(ra) # 80000c9e <release>
}
    8000462a:	8526                	mv	a0,s1
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6105                	addi	sp,sp,32
    80004634:	8082                	ret

0000000080004636 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004636:	1101                	addi	sp,sp,-32
    80004638:	ec06                	sd	ra,24(sp)
    8000463a:	e822                	sd	s0,16(sp)
    8000463c:	e426                	sd	s1,8(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004642:	0001d517          	auipc	a0,0x1d
    80004646:	80650513          	addi	a0,a0,-2042 # 80020e48 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	5a0080e7          	jalr	1440(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004652:	40dc                	lw	a5,4(s1)
    80004654:	02f05263          	blez	a5,80004678 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004658:	2785                	addiw	a5,a5,1
    8000465a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000465c:	0001c517          	auipc	a0,0x1c
    80004660:	7ec50513          	addi	a0,a0,2028 # 80020e48 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	63a080e7          	jalr	1594(ra) # 80000c9e <release>
  return f;
}
    8000466c:	8526                	mv	a0,s1
    8000466e:	60e2                	ld	ra,24(sp)
    80004670:	6442                	ld	s0,16(sp)
    80004672:	64a2                	ld	s1,8(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret
    panic("filedup");
    80004678:	00004517          	auipc	a0,0x4
    8000467c:	21850513          	addi	a0,a0,536 # 80008890 <sysargs+0x1f0>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	ec4080e7          	jalr	-316(ra) # 80000544 <panic>

0000000080004688 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004688:	7139                	addi	sp,sp,-64
    8000468a:	fc06                	sd	ra,56(sp)
    8000468c:	f822                	sd	s0,48(sp)
    8000468e:	f426                	sd	s1,40(sp)
    80004690:	f04a                	sd	s2,32(sp)
    80004692:	ec4e                	sd	s3,24(sp)
    80004694:	e852                	sd	s4,16(sp)
    80004696:	e456                	sd	s5,8(sp)
    80004698:	0080                	addi	s0,sp,64
    8000469a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000469c:	0001c517          	auipc	a0,0x1c
    800046a0:	7ac50513          	addi	a0,a0,1964 # 80020e48 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	546080e7          	jalr	1350(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800046ac:	40dc                	lw	a5,4(s1)
    800046ae:	06f05163          	blez	a5,80004710 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046b2:	37fd                	addiw	a5,a5,-1
    800046b4:	0007871b          	sext.w	a4,a5
    800046b8:	c0dc                	sw	a5,4(s1)
    800046ba:	06e04363          	bgtz	a4,80004720 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046be:	0004a903          	lw	s2,0(s1)
    800046c2:	0094ca83          	lbu	s5,9(s1)
    800046c6:	0104ba03          	ld	s4,16(s1)
    800046ca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046ce:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046d2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046d6:	0001c517          	auipc	a0,0x1c
    800046da:	77250513          	addi	a0,a0,1906 # 80020e48 <ftable>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	5c0080e7          	jalr	1472(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800046e6:	4785                	li	a5,1
    800046e8:	04f90d63          	beq	s2,a5,80004742 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ec:	3979                	addiw	s2,s2,-2
    800046ee:	4785                	li	a5,1
    800046f0:	0527e063          	bltu	a5,s2,80004730 <fileclose+0xa8>
    begin_op();
    800046f4:	00000097          	auipc	ra,0x0
    800046f8:	ac8080e7          	jalr	-1336(ra) # 800041bc <begin_op>
    iput(ff.ip);
    800046fc:	854e                	mv	a0,s3
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	2b6080e7          	jalr	694(ra) # 800039b4 <iput>
    end_op();
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	b36080e7          	jalr	-1226(ra) # 8000423c <end_op>
    8000470e:	a00d                	j	80004730 <fileclose+0xa8>
    panic("fileclose");
    80004710:	00004517          	auipc	a0,0x4
    80004714:	18850513          	addi	a0,a0,392 # 80008898 <sysargs+0x1f8>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	e2c080e7          	jalr	-468(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004720:	0001c517          	auipc	a0,0x1c
    80004724:	72850513          	addi	a0,a0,1832 # 80020e48 <ftable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	576080e7          	jalr	1398(ra) # 80000c9e <release>
  }
}
    80004730:	70e2                	ld	ra,56(sp)
    80004732:	7442                	ld	s0,48(sp)
    80004734:	74a2                	ld	s1,40(sp)
    80004736:	7902                	ld	s2,32(sp)
    80004738:	69e2                	ld	s3,24(sp)
    8000473a:	6a42                	ld	s4,16(sp)
    8000473c:	6aa2                	ld	s5,8(sp)
    8000473e:	6121                	addi	sp,sp,64
    80004740:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004742:	85d6                	mv	a1,s5
    80004744:	8552                	mv	a0,s4
    80004746:	00000097          	auipc	ra,0x0
    8000474a:	34c080e7          	jalr	844(ra) # 80004a92 <pipeclose>
    8000474e:	b7cd                	j	80004730 <fileclose+0xa8>

0000000080004750 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004750:	715d                	addi	sp,sp,-80
    80004752:	e486                	sd	ra,72(sp)
    80004754:	e0a2                	sd	s0,64(sp)
    80004756:	fc26                	sd	s1,56(sp)
    80004758:	f84a                	sd	s2,48(sp)
    8000475a:	f44e                	sd	s3,40(sp)
    8000475c:	0880                	addi	s0,sp,80
    8000475e:	84aa                	mv	s1,a0
    80004760:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004762:	ffffd097          	auipc	ra,0xffffd
    80004766:	264080e7          	jalr	612(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000476a:	409c                	lw	a5,0(s1)
    8000476c:	37f9                	addiw	a5,a5,-2
    8000476e:	4705                	li	a4,1
    80004770:	04f76763          	bltu	a4,a5,800047be <filestat+0x6e>
    80004774:	892a                	mv	s2,a0
    ilock(f->ip);
    80004776:	6c88                	ld	a0,24(s1)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	082080e7          	jalr	130(ra) # 800037fa <ilock>
    stati(f->ip, &st);
    80004780:	fb840593          	addi	a1,s0,-72
    80004784:	6c88                	ld	a0,24(s1)
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	2fe080e7          	jalr	766(ra) # 80003a84 <stati>
    iunlock(f->ip);
    8000478e:	6c88                	ld	a0,24(s1)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	12c080e7          	jalr	300(ra) # 800038bc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004798:	46e1                	li	a3,24
    8000479a:	fb840613          	addi	a2,s0,-72
    8000479e:	85ce                	mv	a1,s3
    800047a0:	05093503          	ld	a0,80(s2)
    800047a4:	ffffd097          	auipc	ra,0xffffd
    800047a8:	ee0080e7          	jalr	-288(ra) # 80001684 <copyout>
    800047ac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047b0:	60a6                	ld	ra,72(sp)
    800047b2:	6406                	ld	s0,64(sp)
    800047b4:	74e2                	ld	s1,56(sp)
    800047b6:	7942                	ld	s2,48(sp)
    800047b8:	79a2                	ld	s3,40(sp)
    800047ba:	6161                	addi	sp,sp,80
    800047bc:	8082                	ret
  return -1;
    800047be:	557d                	li	a0,-1
    800047c0:	bfc5                	j	800047b0 <filestat+0x60>

00000000800047c2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047c2:	7179                	addi	sp,sp,-48
    800047c4:	f406                	sd	ra,40(sp)
    800047c6:	f022                	sd	s0,32(sp)
    800047c8:	ec26                	sd	s1,24(sp)
    800047ca:	e84a                	sd	s2,16(sp)
    800047cc:	e44e                	sd	s3,8(sp)
    800047ce:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047d0:	00854783          	lbu	a5,8(a0)
    800047d4:	c3d5                	beqz	a5,80004878 <fileread+0xb6>
    800047d6:	84aa                	mv	s1,a0
    800047d8:	89ae                	mv	s3,a1
    800047da:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047dc:	411c                	lw	a5,0(a0)
    800047de:	4705                	li	a4,1
    800047e0:	04e78963          	beq	a5,a4,80004832 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e4:	470d                	li	a4,3
    800047e6:	04e78d63          	beq	a5,a4,80004840 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ea:	4709                	li	a4,2
    800047ec:	06e79e63          	bne	a5,a4,80004868 <fileread+0xa6>
    ilock(f->ip);
    800047f0:	6d08                	ld	a0,24(a0)
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	008080e7          	jalr	8(ra) # 800037fa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047fa:	874a                	mv	a4,s2
    800047fc:	5094                	lw	a3,32(s1)
    800047fe:	864e                	mv	a2,s3
    80004800:	4585                	li	a1,1
    80004802:	6c88                	ld	a0,24(s1)
    80004804:	fffff097          	auipc	ra,0xfffff
    80004808:	2aa080e7          	jalr	682(ra) # 80003aae <readi>
    8000480c:	892a                	mv	s2,a0
    8000480e:	00a05563          	blez	a0,80004818 <fileread+0x56>
      f->off += r;
    80004812:	509c                	lw	a5,32(s1)
    80004814:	9fa9                	addw	a5,a5,a0
    80004816:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004818:	6c88                	ld	a0,24(s1)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	0a2080e7          	jalr	162(ra) # 800038bc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004822:	854a                	mv	a0,s2
    80004824:	70a2                	ld	ra,40(sp)
    80004826:	7402                	ld	s0,32(sp)
    80004828:	64e2                	ld	s1,24(sp)
    8000482a:	6942                	ld	s2,16(sp)
    8000482c:	69a2                	ld	s3,8(sp)
    8000482e:	6145                	addi	sp,sp,48
    80004830:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004832:	6908                	ld	a0,16(a0)
    80004834:	00000097          	auipc	ra,0x0
    80004838:	3ce080e7          	jalr	974(ra) # 80004c02 <piperead>
    8000483c:	892a                	mv	s2,a0
    8000483e:	b7d5                	j	80004822 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004840:	02451783          	lh	a5,36(a0)
    80004844:	03079693          	slli	a3,a5,0x30
    80004848:	92c1                	srli	a3,a3,0x30
    8000484a:	4725                	li	a4,9
    8000484c:	02d76863          	bltu	a4,a3,8000487c <fileread+0xba>
    80004850:	0792                	slli	a5,a5,0x4
    80004852:	0001c717          	auipc	a4,0x1c
    80004856:	55670713          	addi	a4,a4,1366 # 80020da8 <devsw>
    8000485a:	97ba                	add	a5,a5,a4
    8000485c:	639c                	ld	a5,0(a5)
    8000485e:	c38d                	beqz	a5,80004880 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004860:	4505                	li	a0,1
    80004862:	9782                	jalr	a5
    80004864:	892a                	mv	s2,a0
    80004866:	bf75                	j	80004822 <fileread+0x60>
    panic("fileread");
    80004868:	00004517          	auipc	a0,0x4
    8000486c:	04050513          	addi	a0,a0,64 # 800088a8 <sysargs+0x208>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	cd4080e7          	jalr	-812(ra) # 80000544 <panic>
    return -1;
    80004878:	597d                	li	s2,-1
    8000487a:	b765                	j	80004822 <fileread+0x60>
      return -1;
    8000487c:	597d                	li	s2,-1
    8000487e:	b755                	j	80004822 <fileread+0x60>
    80004880:	597d                	li	s2,-1
    80004882:	b745                	j	80004822 <fileread+0x60>

0000000080004884 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004884:	715d                	addi	sp,sp,-80
    80004886:	e486                	sd	ra,72(sp)
    80004888:	e0a2                	sd	s0,64(sp)
    8000488a:	fc26                	sd	s1,56(sp)
    8000488c:	f84a                	sd	s2,48(sp)
    8000488e:	f44e                	sd	s3,40(sp)
    80004890:	f052                	sd	s4,32(sp)
    80004892:	ec56                	sd	s5,24(sp)
    80004894:	e85a                	sd	s6,16(sp)
    80004896:	e45e                	sd	s7,8(sp)
    80004898:	e062                	sd	s8,0(sp)
    8000489a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000489c:	00954783          	lbu	a5,9(a0)
    800048a0:	10078663          	beqz	a5,800049ac <filewrite+0x128>
    800048a4:	892a                	mv	s2,a0
    800048a6:	8aae                	mv	s5,a1
    800048a8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048aa:	411c                	lw	a5,0(a0)
    800048ac:	4705                	li	a4,1
    800048ae:	02e78263          	beq	a5,a4,800048d2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048b2:	470d                	li	a4,3
    800048b4:	02e78663          	beq	a5,a4,800048e0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048b8:	4709                	li	a4,2
    800048ba:	0ee79163          	bne	a5,a4,8000499c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048be:	0ac05d63          	blez	a2,80004978 <filewrite+0xf4>
    int i = 0;
    800048c2:	4981                	li	s3,0
    800048c4:	6b05                	lui	s6,0x1
    800048c6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048ca:	6b85                	lui	s7,0x1
    800048cc:	c00b8b9b          	addiw	s7,s7,-1024
    800048d0:	a861                	j	80004968 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048d2:	6908                	ld	a0,16(a0)
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	22e080e7          	jalr	558(ra) # 80004b02 <pipewrite>
    800048dc:	8a2a                	mv	s4,a0
    800048de:	a045                	j	8000497e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048e0:	02451783          	lh	a5,36(a0)
    800048e4:	03079693          	slli	a3,a5,0x30
    800048e8:	92c1                	srli	a3,a3,0x30
    800048ea:	4725                	li	a4,9
    800048ec:	0cd76263          	bltu	a4,a3,800049b0 <filewrite+0x12c>
    800048f0:	0792                	slli	a5,a5,0x4
    800048f2:	0001c717          	auipc	a4,0x1c
    800048f6:	4b670713          	addi	a4,a4,1206 # 80020da8 <devsw>
    800048fa:	97ba                	add	a5,a5,a4
    800048fc:	679c                	ld	a5,8(a5)
    800048fe:	cbdd                	beqz	a5,800049b4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004900:	4505                	li	a0,1
    80004902:	9782                	jalr	a5
    80004904:	8a2a                	mv	s4,a0
    80004906:	a8a5                	j	8000497e <filewrite+0xfa>
    80004908:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	8b0080e7          	jalr	-1872(ra) # 800041bc <begin_op>
      ilock(f->ip);
    80004914:	01893503          	ld	a0,24(s2)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	ee2080e7          	jalr	-286(ra) # 800037fa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004920:	8762                	mv	a4,s8
    80004922:	02092683          	lw	a3,32(s2)
    80004926:	01598633          	add	a2,s3,s5
    8000492a:	4585                	li	a1,1
    8000492c:	01893503          	ld	a0,24(s2)
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	276080e7          	jalr	630(ra) # 80003ba6 <writei>
    80004938:	84aa                	mv	s1,a0
    8000493a:	00a05763          	blez	a0,80004948 <filewrite+0xc4>
        f->off += r;
    8000493e:	02092783          	lw	a5,32(s2)
    80004942:	9fa9                	addw	a5,a5,a0
    80004944:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004948:	01893503          	ld	a0,24(s2)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	f70080e7          	jalr	-144(ra) # 800038bc <iunlock>
      end_op();
    80004954:	00000097          	auipc	ra,0x0
    80004958:	8e8080e7          	jalr	-1816(ra) # 8000423c <end_op>

      if(r != n1){
    8000495c:	009c1f63          	bne	s8,s1,8000497a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004960:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004964:	0149db63          	bge	s3,s4,8000497a <filewrite+0xf6>
      int n1 = n - i;
    80004968:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000496c:	84be                	mv	s1,a5
    8000496e:	2781                	sext.w	a5,a5
    80004970:	f8fb5ce3          	bge	s6,a5,80004908 <filewrite+0x84>
    80004974:	84de                	mv	s1,s7
    80004976:	bf49                	j	80004908 <filewrite+0x84>
    int i = 0;
    80004978:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000497a:	013a1f63          	bne	s4,s3,80004998 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000497e:	8552                	mv	a0,s4
    80004980:	60a6                	ld	ra,72(sp)
    80004982:	6406                	ld	s0,64(sp)
    80004984:	74e2                	ld	s1,56(sp)
    80004986:	7942                	ld	s2,48(sp)
    80004988:	79a2                	ld	s3,40(sp)
    8000498a:	7a02                	ld	s4,32(sp)
    8000498c:	6ae2                	ld	s5,24(sp)
    8000498e:	6b42                	ld	s6,16(sp)
    80004990:	6ba2                	ld	s7,8(sp)
    80004992:	6c02                	ld	s8,0(sp)
    80004994:	6161                	addi	sp,sp,80
    80004996:	8082                	ret
    ret = (i == n ? n : -1);
    80004998:	5a7d                	li	s4,-1
    8000499a:	b7d5                	j	8000497e <filewrite+0xfa>
    panic("filewrite");
    8000499c:	00004517          	auipc	a0,0x4
    800049a0:	f1c50513          	addi	a0,a0,-228 # 800088b8 <sysargs+0x218>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	ba0080e7          	jalr	-1120(ra) # 80000544 <panic>
    return -1;
    800049ac:	5a7d                	li	s4,-1
    800049ae:	bfc1                	j	8000497e <filewrite+0xfa>
      return -1;
    800049b0:	5a7d                	li	s4,-1
    800049b2:	b7f1                	j	8000497e <filewrite+0xfa>
    800049b4:	5a7d                	li	s4,-1
    800049b6:	b7e1                	j	8000497e <filewrite+0xfa>

00000000800049b8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049b8:	7179                	addi	sp,sp,-48
    800049ba:	f406                	sd	ra,40(sp)
    800049bc:	f022                	sd	s0,32(sp)
    800049be:	ec26                	sd	s1,24(sp)
    800049c0:	e84a                	sd	s2,16(sp)
    800049c2:	e44e                	sd	s3,8(sp)
    800049c4:	e052                	sd	s4,0(sp)
    800049c6:	1800                	addi	s0,sp,48
    800049c8:	84aa                	mv	s1,a0
    800049ca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049cc:	0005b023          	sd	zero,0(a1)
    800049d0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	bf8080e7          	jalr	-1032(ra) # 800045cc <filealloc>
    800049dc:	e088                	sd	a0,0(s1)
    800049de:	c551                	beqz	a0,80004a6a <pipealloc+0xb2>
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	bec080e7          	jalr	-1044(ra) # 800045cc <filealloc>
    800049e8:	00aa3023          	sd	a0,0(s4)
    800049ec:	c92d                	beqz	a0,80004a5e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	10c080e7          	jalr	268(ra) # 80000afa <kalloc>
    800049f6:	892a                	mv	s2,a0
    800049f8:	c125                	beqz	a0,80004a58 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049fa:	4985                	li	s3,1
    800049fc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a00:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a04:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a08:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a0c:	00004597          	auipc	a1,0x4
    80004a10:	a8458593          	addi	a1,a1,-1404 # 80008490 <states.1723+0x1c8>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	146080e7          	jalr	326(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004a1c:	609c                	ld	a5,0(s1)
    80004a1e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a22:	609c                	ld	a5,0(s1)
    80004a24:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a28:	609c                	ld	a5,0(s1)
    80004a2a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a2e:	609c                	ld	a5,0(s1)
    80004a30:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a34:	000a3783          	ld	a5,0(s4)
    80004a38:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a3c:	000a3783          	ld	a5,0(s4)
    80004a40:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a44:	000a3783          	ld	a5,0(s4)
    80004a48:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a4c:	000a3783          	ld	a5,0(s4)
    80004a50:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a54:	4501                	li	a0,0
    80004a56:	a025                	j	80004a7e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a58:	6088                	ld	a0,0(s1)
    80004a5a:	e501                	bnez	a0,80004a62 <pipealloc+0xaa>
    80004a5c:	a039                	j	80004a6a <pipealloc+0xb2>
    80004a5e:	6088                	ld	a0,0(s1)
    80004a60:	c51d                	beqz	a0,80004a8e <pipealloc+0xd6>
    fileclose(*f0);
    80004a62:	00000097          	auipc	ra,0x0
    80004a66:	c26080e7          	jalr	-986(ra) # 80004688 <fileclose>
  if(*f1)
    80004a6a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a6e:	557d                	li	a0,-1
  if(*f1)
    80004a70:	c799                	beqz	a5,80004a7e <pipealloc+0xc6>
    fileclose(*f1);
    80004a72:	853e                	mv	a0,a5
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	c14080e7          	jalr	-1004(ra) # 80004688 <fileclose>
  return -1;
    80004a7c:	557d                	li	a0,-1
}
    80004a7e:	70a2                	ld	ra,40(sp)
    80004a80:	7402                	ld	s0,32(sp)
    80004a82:	64e2                	ld	s1,24(sp)
    80004a84:	6942                	ld	s2,16(sp)
    80004a86:	69a2                	ld	s3,8(sp)
    80004a88:	6a02                	ld	s4,0(sp)
    80004a8a:	6145                	addi	sp,sp,48
    80004a8c:	8082                	ret
  return -1;
    80004a8e:	557d                	li	a0,-1
    80004a90:	b7fd                	j	80004a7e <pipealloc+0xc6>

0000000080004a92 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a92:	1101                	addi	sp,sp,-32
    80004a94:	ec06                	sd	ra,24(sp)
    80004a96:	e822                	sd	s0,16(sp)
    80004a98:	e426                	sd	s1,8(sp)
    80004a9a:	e04a                	sd	s2,0(sp)
    80004a9c:	1000                	addi	s0,sp,32
    80004a9e:	84aa                	mv	s1,a0
    80004aa0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	148080e7          	jalr	328(ra) # 80000bea <acquire>
  if(writable){
    80004aaa:	02090d63          	beqz	s2,80004ae4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004aae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ab2:	21848513          	addi	a0,s1,536
    80004ab6:	ffffd097          	auipc	ra,0xffffd
    80004aba:	620080e7          	jalr	1568(ra) # 800020d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004abe:	2204b783          	ld	a5,544(s1)
    80004ac2:	eb95                	bnez	a5,80004af6 <pipeclose+0x64>
    release(&pi->lock);
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	1d8080e7          	jalr	472(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	f2e080e7          	jalr	-210(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004ad8:	60e2                	ld	ra,24(sp)
    80004ada:	6442                	ld	s0,16(sp)
    80004adc:	64a2                	ld	s1,8(sp)
    80004ade:	6902                	ld	s2,0(sp)
    80004ae0:	6105                	addi	sp,sp,32
    80004ae2:	8082                	ret
    pi->readopen = 0;
    80004ae4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ae8:	21c48513          	addi	a0,s1,540
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	5ea080e7          	jalr	1514(ra) # 800020d6 <wakeup>
    80004af4:	b7e9                	j	80004abe <pipeclose+0x2c>
    release(&pi->lock);
    80004af6:	8526                	mv	a0,s1
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	1a6080e7          	jalr	422(ra) # 80000c9e <release>
}
    80004b00:	bfe1                	j	80004ad8 <pipeclose+0x46>

0000000080004b02 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b02:	7159                	addi	sp,sp,-112
    80004b04:	f486                	sd	ra,104(sp)
    80004b06:	f0a2                	sd	s0,96(sp)
    80004b08:	eca6                	sd	s1,88(sp)
    80004b0a:	e8ca                	sd	s2,80(sp)
    80004b0c:	e4ce                	sd	s3,72(sp)
    80004b0e:	e0d2                	sd	s4,64(sp)
    80004b10:	fc56                	sd	s5,56(sp)
    80004b12:	f85a                	sd	s6,48(sp)
    80004b14:	f45e                	sd	s7,40(sp)
    80004b16:	f062                	sd	s8,32(sp)
    80004b18:	ec66                	sd	s9,24(sp)
    80004b1a:	1880                	addi	s0,sp,112
    80004b1c:	84aa                	mv	s1,a0
    80004b1e:	8aae                	mv	s5,a1
    80004b20:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	ea4080e7          	jalr	-348(ra) # 800019c6 <myproc>
    80004b2a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	0bc080e7          	jalr	188(ra) # 80000bea <acquire>
  while(i < n){
    80004b36:	0d405463          	blez	s4,80004bfe <pipewrite+0xfc>
    80004b3a:	8ba6                	mv	s7,s1
  int i = 0;
    80004b3c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b40:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b44:	21c48c13          	addi	s8,s1,540
    80004b48:	a08d                	j	80004baa <pipewrite+0xa8>
      release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	152080e7          	jalr	338(ra) # 80000c9e <release>
      return -1;
    80004b54:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b56:	854a                	mv	a0,s2
    80004b58:	70a6                	ld	ra,104(sp)
    80004b5a:	7406                	ld	s0,96(sp)
    80004b5c:	64e6                	ld	s1,88(sp)
    80004b5e:	6946                	ld	s2,80(sp)
    80004b60:	69a6                	ld	s3,72(sp)
    80004b62:	6a06                	ld	s4,64(sp)
    80004b64:	7ae2                	ld	s5,56(sp)
    80004b66:	7b42                	ld	s6,48(sp)
    80004b68:	7ba2                	ld	s7,40(sp)
    80004b6a:	7c02                	ld	s8,32(sp)
    80004b6c:	6ce2                	ld	s9,24(sp)
    80004b6e:	6165                	addi	sp,sp,112
    80004b70:	8082                	ret
      wakeup(&pi->nread);
    80004b72:	8566                	mv	a0,s9
    80004b74:	ffffd097          	auipc	ra,0xffffd
    80004b78:	562080e7          	jalr	1378(ra) # 800020d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b7c:	85de                	mv	a1,s7
    80004b7e:	8562                	mv	a0,s8
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	4f2080e7          	jalr	1266(ra) # 80002072 <sleep>
    80004b88:	a839                	j	80004ba6 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b8a:	21c4a783          	lw	a5,540(s1)
    80004b8e:	0017871b          	addiw	a4,a5,1
    80004b92:	20e4ae23          	sw	a4,540(s1)
    80004b96:	1ff7f793          	andi	a5,a5,511
    80004b9a:	97a6                	add	a5,a5,s1
    80004b9c:	f9f44703          	lbu	a4,-97(s0)
    80004ba0:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ba4:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ba6:	05495063          	bge	s2,s4,80004be6 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004baa:	2204a783          	lw	a5,544(s1)
    80004bae:	dfd1                	beqz	a5,80004b4a <pipewrite+0x48>
    80004bb0:	854e                	mv	a0,s3
    80004bb2:	ffffd097          	auipc	ra,0xffffd
    80004bb6:	768080e7          	jalr	1896(ra) # 8000231a <killed>
    80004bba:	f941                	bnez	a0,80004b4a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bbc:	2184a783          	lw	a5,536(s1)
    80004bc0:	21c4a703          	lw	a4,540(s1)
    80004bc4:	2007879b          	addiw	a5,a5,512
    80004bc8:	faf705e3          	beq	a4,a5,80004b72 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bcc:	4685                	li	a3,1
    80004bce:	01590633          	add	a2,s2,s5
    80004bd2:	f9f40593          	addi	a1,s0,-97
    80004bd6:	0509b503          	ld	a0,80(s3)
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	b36080e7          	jalr	-1226(ra) # 80001710 <copyin>
    80004be2:	fb6514e3          	bne	a0,s6,80004b8a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004be6:	21848513          	addi	a0,s1,536
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	4ec080e7          	jalr	1260(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	0aa080e7          	jalr	170(ra) # 80000c9e <release>
  return i;
    80004bfc:	bfa9                	j	80004b56 <pipewrite+0x54>
  int i = 0;
    80004bfe:	4901                	li	s2,0
    80004c00:	b7dd                	j	80004be6 <pipewrite+0xe4>

0000000080004c02 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c02:	715d                	addi	sp,sp,-80
    80004c04:	e486                	sd	ra,72(sp)
    80004c06:	e0a2                	sd	s0,64(sp)
    80004c08:	fc26                	sd	s1,56(sp)
    80004c0a:	f84a                	sd	s2,48(sp)
    80004c0c:	f44e                	sd	s3,40(sp)
    80004c0e:	f052                	sd	s4,32(sp)
    80004c10:	ec56                	sd	s5,24(sp)
    80004c12:	e85a                	sd	s6,16(sp)
    80004c14:	0880                	addi	s0,sp,80
    80004c16:	84aa                	mv	s1,a0
    80004c18:	892e                	mv	s2,a1
    80004c1a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	daa080e7          	jalr	-598(ra) # 800019c6 <myproc>
    80004c24:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c26:	8b26                	mv	s6,s1
    80004c28:	8526                	mv	a0,s1
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	fc0080e7          	jalr	-64(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c32:	2184a703          	lw	a4,536(s1)
    80004c36:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c3a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c3e:	02f71763          	bne	a4,a5,80004c6c <piperead+0x6a>
    80004c42:	2244a783          	lw	a5,548(s1)
    80004c46:	c39d                	beqz	a5,80004c6c <piperead+0x6a>
    if(killed(pr)){
    80004c48:	8552                	mv	a0,s4
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	6d0080e7          	jalr	1744(ra) # 8000231a <killed>
    80004c52:	e941                	bnez	a0,80004ce2 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c54:	85da                	mv	a1,s6
    80004c56:	854e                	mv	a0,s3
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	41a080e7          	jalr	1050(ra) # 80002072 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c60:	2184a703          	lw	a4,536(s1)
    80004c64:	21c4a783          	lw	a5,540(s1)
    80004c68:	fcf70de3          	beq	a4,a5,80004c42 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6c:	09505263          	blez	s5,80004cf0 <piperead+0xee>
    80004c70:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c72:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c74:	2184a783          	lw	a5,536(s1)
    80004c78:	21c4a703          	lw	a4,540(s1)
    80004c7c:	02f70d63          	beq	a4,a5,80004cb6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c80:	0017871b          	addiw	a4,a5,1
    80004c84:	20e4ac23          	sw	a4,536(s1)
    80004c88:	1ff7f793          	andi	a5,a5,511
    80004c8c:	97a6                	add	a5,a5,s1
    80004c8e:	0187c783          	lbu	a5,24(a5)
    80004c92:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c96:	4685                	li	a3,1
    80004c98:	fbf40613          	addi	a2,s0,-65
    80004c9c:	85ca                	mv	a1,s2
    80004c9e:	050a3503          	ld	a0,80(s4)
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	9e2080e7          	jalr	-1566(ra) # 80001684 <copyout>
    80004caa:	01650663          	beq	a0,s6,80004cb6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cae:	2985                	addiw	s3,s3,1
    80004cb0:	0905                	addi	s2,s2,1
    80004cb2:	fd3a91e3          	bne	s5,s3,80004c74 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cb6:	21c48513          	addi	a0,s1,540
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	41c080e7          	jalr	1052(ra) # 800020d6 <wakeup>
  release(&pi->lock);
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	fda080e7          	jalr	-38(ra) # 80000c9e <release>
  return i;
}
    80004ccc:	854e                	mv	a0,s3
    80004cce:	60a6                	ld	ra,72(sp)
    80004cd0:	6406                	ld	s0,64(sp)
    80004cd2:	74e2                	ld	s1,56(sp)
    80004cd4:	7942                	ld	s2,48(sp)
    80004cd6:	79a2                	ld	s3,40(sp)
    80004cd8:	7a02                	ld	s4,32(sp)
    80004cda:	6ae2                	ld	s5,24(sp)
    80004cdc:	6b42                	ld	s6,16(sp)
    80004cde:	6161                	addi	sp,sp,80
    80004ce0:	8082                	ret
      release(&pi->lock);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	fba080e7          	jalr	-70(ra) # 80000c9e <release>
      return -1;
    80004cec:	59fd                	li	s3,-1
    80004cee:	bff9                	j	80004ccc <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf0:	4981                	li	s3,0
    80004cf2:	b7d1                	j	80004cb6 <piperead+0xb4>

0000000080004cf4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cf4:	1141                	addi	sp,sp,-16
    80004cf6:	e422                	sd	s0,8(sp)
    80004cf8:	0800                	addi	s0,sp,16
    80004cfa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cfc:	8905                	andi	a0,a0,1
    80004cfe:	c111                	beqz	a0,80004d02 <flags2perm+0xe>
      perm = PTE_X;
    80004d00:	4521                	li	a0,8
    if(flags & 0x2)
    80004d02:	8b89                	andi	a5,a5,2
    80004d04:	c399                	beqz	a5,80004d0a <flags2perm+0x16>
      perm |= PTE_W;
    80004d06:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d0a:	6422                	ld	s0,8(sp)
    80004d0c:	0141                	addi	sp,sp,16
    80004d0e:	8082                	ret

0000000080004d10 <exec>:

int
exec(char *path, char **argv)
{
    80004d10:	df010113          	addi	sp,sp,-528
    80004d14:	20113423          	sd	ra,520(sp)
    80004d18:	20813023          	sd	s0,512(sp)
    80004d1c:	ffa6                	sd	s1,504(sp)
    80004d1e:	fbca                	sd	s2,496(sp)
    80004d20:	f7ce                	sd	s3,488(sp)
    80004d22:	f3d2                	sd	s4,480(sp)
    80004d24:	efd6                	sd	s5,472(sp)
    80004d26:	ebda                	sd	s6,464(sp)
    80004d28:	e7de                	sd	s7,456(sp)
    80004d2a:	e3e2                	sd	s8,448(sp)
    80004d2c:	ff66                	sd	s9,440(sp)
    80004d2e:	fb6a                	sd	s10,432(sp)
    80004d30:	f76e                	sd	s11,424(sp)
    80004d32:	0c00                	addi	s0,sp,528
    80004d34:	84aa                	mv	s1,a0
    80004d36:	dea43c23          	sd	a0,-520(s0)
    80004d3a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	c88080e7          	jalr	-888(ra) # 800019c6 <myproc>
    80004d46:	892a                	mv	s2,a0

  begin_op();
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	474080e7          	jalr	1140(ra) # 800041bc <begin_op>

  if((ip = namei(path)) == 0){
    80004d50:	8526                	mv	a0,s1
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	24e080e7          	jalr	590(ra) # 80003fa0 <namei>
    80004d5a:	c92d                	beqz	a0,80004dcc <exec+0xbc>
    80004d5c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	a9c080e7          	jalr	-1380(ra) # 800037fa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d66:	04000713          	li	a4,64
    80004d6a:	4681                	li	a3,0
    80004d6c:	e5040613          	addi	a2,s0,-432
    80004d70:	4581                	li	a1,0
    80004d72:	8526                	mv	a0,s1
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	d3a080e7          	jalr	-710(ra) # 80003aae <readi>
    80004d7c:	04000793          	li	a5,64
    80004d80:	00f51a63          	bne	a0,a5,80004d94 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d84:	e5042703          	lw	a4,-432(s0)
    80004d88:	464c47b7          	lui	a5,0x464c4
    80004d8c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d90:	04f70463          	beq	a4,a5,80004dd8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d94:	8526                	mv	a0,s1
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	cc6080e7          	jalr	-826(ra) # 80003a5c <iunlockput>
    end_op();
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	49e080e7          	jalr	1182(ra) # 8000423c <end_op>
  }
  return -1;
    80004da6:	557d                	li	a0,-1
}
    80004da8:	20813083          	ld	ra,520(sp)
    80004dac:	20013403          	ld	s0,512(sp)
    80004db0:	74fe                	ld	s1,504(sp)
    80004db2:	795e                	ld	s2,496(sp)
    80004db4:	79be                	ld	s3,488(sp)
    80004db6:	7a1e                	ld	s4,480(sp)
    80004db8:	6afe                	ld	s5,472(sp)
    80004dba:	6b5e                	ld	s6,464(sp)
    80004dbc:	6bbe                	ld	s7,456(sp)
    80004dbe:	6c1e                	ld	s8,448(sp)
    80004dc0:	7cfa                	ld	s9,440(sp)
    80004dc2:	7d5a                	ld	s10,432(sp)
    80004dc4:	7dba                	ld	s11,424(sp)
    80004dc6:	21010113          	addi	sp,sp,528
    80004dca:	8082                	ret
    end_op();
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	470080e7          	jalr	1136(ra) # 8000423c <end_op>
    return -1;
    80004dd4:	557d                	li	a0,-1
    80004dd6:	bfc9                	j	80004da8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dd8:	854a                	mv	a0,s2
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	cb0080e7          	jalr	-848(ra) # 80001a8a <proc_pagetable>
    80004de2:	8baa                	mv	s7,a0
    80004de4:	d945                	beqz	a0,80004d94 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de6:	e7042983          	lw	s3,-400(s0)
    80004dea:	e8845783          	lhu	a5,-376(s0)
    80004dee:	c7ad                	beqz	a5,80004e58 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004df0:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df2:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004df4:	6c85                	lui	s9,0x1
    80004df6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dfa:	def43823          	sd	a5,-528(s0)
    80004dfe:	ac0d                	j	80005030 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e00:	00004517          	auipc	a0,0x4
    80004e04:	ac850513          	addi	a0,a0,-1336 # 800088c8 <sysargs+0x228>
    80004e08:	ffffb097          	auipc	ra,0xffffb
    80004e0c:	73c080e7          	jalr	1852(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e10:	8756                	mv	a4,s5
    80004e12:	012d86bb          	addw	a3,s11,s2
    80004e16:	4581                	li	a1,0
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	c94080e7          	jalr	-876(ra) # 80003aae <readi>
    80004e22:	2501                	sext.w	a0,a0
    80004e24:	1aaa9a63          	bne	s5,a0,80004fd8 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004e28:	6785                	lui	a5,0x1
    80004e2a:	0127893b          	addw	s2,a5,s2
    80004e2e:	77fd                	lui	a5,0xfffff
    80004e30:	01478a3b          	addw	s4,a5,s4
    80004e34:	1f897563          	bgeu	s2,s8,8000501e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004e38:	02091593          	slli	a1,s2,0x20
    80004e3c:	9181                	srli	a1,a1,0x20
    80004e3e:	95ea                	add	a1,a1,s10
    80004e40:	855e                	mv	a0,s7
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	236080e7          	jalr	566(ra) # 80001078 <walkaddr>
    80004e4a:	862a                	mv	a2,a0
    if(pa == 0)
    80004e4c:	d955                	beqz	a0,80004e00 <exec+0xf0>
      n = PGSIZE;
    80004e4e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e50:	fd9a70e3          	bgeu	s4,s9,80004e10 <exec+0x100>
      n = sz - i;
    80004e54:	8ad2                	mv	s5,s4
    80004e56:	bf6d                	j	80004e10 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e58:	4a01                	li	s4,0
  iunlockput(ip);
    80004e5a:	8526                	mv	a0,s1
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	c00080e7          	jalr	-1024(ra) # 80003a5c <iunlockput>
  end_op();
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	3d8080e7          	jalr	984(ra) # 8000423c <end_op>
  p = myproc();
    80004e6c:	ffffd097          	auipc	ra,0xffffd
    80004e70:	b5a080e7          	jalr	-1190(ra) # 800019c6 <myproc>
    80004e74:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e76:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e7a:	6785                	lui	a5,0x1
    80004e7c:	17fd                	addi	a5,a5,-1
    80004e7e:	9a3e                	add	s4,s4,a5
    80004e80:	757d                	lui	a0,0xfffff
    80004e82:	00aa77b3          	and	a5,s4,a0
    80004e86:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e8a:	4691                	li	a3,4
    80004e8c:	6609                	lui	a2,0x2
    80004e8e:	963e                	add	a2,a2,a5
    80004e90:	85be                	mv	a1,a5
    80004e92:	855e                	mv	a0,s7
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	598080e7          	jalr	1432(ra) # 8000142c <uvmalloc>
    80004e9c:	8b2a                	mv	s6,a0
  ip = 0;
    80004e9e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ea0:	12050c63          	beqz	a0,80004fd8 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ea4:	75f9                	lui	a1,0xffffe
    80004ea6:	95aa                	add	a1,a1,a0
    80004ea8:	855e                	mv	a0,s7
    80004eaa:	ffffc097          	auipc	ra,0xffffc
    80004eae:	7a8080e7          	jalr	1960(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004eb2:	7c7d                	lui	s8,0xfffff
    80004eb4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eb6:	e0043783          	ld	a5,-512(s0)
    80004eba:	6388                	ld	a0,0(a5)
    80004ebc:	c535                	beqz	a0,80004f28 <exec+0x218>
    80004ebe:	e9040993          	addi	s3,s0,-368
    80004ec2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ec6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	fa2080e7          	jalr	-94(ra) # 80000e6a <strlen>
    80004ed0:	2505                	addiw	a0,a0,1
    80004ed2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ed6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eda:	13896663          	bltu	s2,s8,80005006 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ede:	e0043d83          	ld	s11,-512(s0)
    80004ee2:	000dba03          	ld	s4,0(s11)
    80004ee6:	8552                	mv	a0,s4
    80004ee8:	ffffc097          	auipc	ra,0xffffc
    80004eec:	f82080e7          	jalr	-126(ra) # 80000e6a <strlen>
    80004ef0:	0015069b          	addiw	a3,a0,1
    80004ef4:	8652                	mv	a2,s4
    80004ef6:	85ca                	mv	a1,s2
    80004ef8:	855e                	mv	a0,s7
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	78a080e7          	jalr	1930(ra) # 80001684 <copyout>
    80004f02:	10054663          	bltz	a0,8000500e <exec+0x2fe>
    ustack[argc] = sp;
    80004f06:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f0a:	0485                	addi	s1,s1,1
    80004f0c:	008d8793          	addi	a5,s11,8
    80004f10:	e0f43023          	sd	a5,-512(s0)
    80004f14:	008db503          	ld	a0,8(s11)
    80004f18:	c911                	beqz	a0,80004f2c <exec+0x21c>
    if(argc >= MAXARG)
    80004f1a:	09a1                	addi	s3,s3,8
    80004f1c:	fb3c96e3          	bne	s9,s3,80004ec8 <exec+0x1b8>
  sz = sz1;
    80004f20:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f24:	4481                	li	s1,0
    80004f26:	a84d                	j	80004fd8 <exec+0x2c8>
  sp = sz;
    80004f28:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f2a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f2c:	00349793          	slli	a5,s1,0x3
    80004f30:	f9040713          	addi	a4,s0,-112
    80004f34:	97ba                	add	a5,a5,a4
    80004f36:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f3a:	00148693          	addi	a3,s1,1
    80004f3e:	068e                	slli	a3,a3,0x3
    80004f40:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f44:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f48:	01897663          	bgeu	s2,s8,80004f54 <exec+0x244>
  sz = sz1;
    80004f4c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f50:	4481                	li	s1,0
    80004f52:	a059                	j	80004fd8 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f54:	e9040613          	addi	a2,s0,-368
    80004f58:	85ca                	mv	a1,s2
    80004f5a:	855e                	mv	a0,s7
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	728080e7          	jalr	1832(ra) # 80001684 <copyout>
    80004f64:	0a054963          	bltz	a0,80005016 <exec+0x306>
  p->trapframe->a1 = sp;
    80004f68:	058ab783          	ld	a5,88(s5)
    80004f6c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f70:	df843783          	ld	a5,-520(s0)
    80004f74:	0007c703          	lbu	a4,0(a5)
    80004f78:	cf11                	beqz	a4,80004f94 <exec+0x284>
    80004f7a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f7c:	02f00693          	li	a3,47
    80004f80:	a039                	j	80004f8e <exec+0x27e>
      last = s+1;
    80004f82:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f86:	0785                	addi	a5,a5,1
    80004f88:	fff7c703          	lbu	a4,-1(a5)
    80004f8c:	c701                	beqz	a4,80004f94 <exec+0x284>
    if(*s == '/')
    80004f8e:	fed71ce3          	bne	a4,a3,80004f86 <exec+0x276>
    80004f92:	bfc5                	j	80004f82 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f94:	4641                	li	a2,16
    80004f96:	df843583          	ld	a1,-520(s0)
    80004f9a:	158a8513          	addi	a0,s5,344
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	e9a080e7          	jalr	-358(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fa6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004faa:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fae:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fb2:	058ab783          	ld	a5,88(s5)
    80004fb6:	e6843703          	ld	a4,-408(s0)
    80004fba:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fbc:	058ab783          	ld	a5,88(s5)
    80004fc0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fc4:	85ea                	mv	a1,s10
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	b60080e7          	jalr	-1184(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fce:	0004851b          	sext.w	a0,s1
    80004fd2:	bbd9                	j	80004da8 <exec+0x98>
    80004fd4:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fd8:	e0843583          	ld	a1,-504(s0)
    80004fdc:	855e                	mv	a0,s7
    80004fde:	ffffd097          	auipc	ra,0xffffd
    80004fe2:	b48080e7          	jalr	-1208(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004fe6:	da0497e3          	bnez	s1,80004d94 <exec+0x84>
  return -1;
    80004fea:	557d                	li	a0,-1
    80004fec:	bb75                	j	80004da8 <exec+0x98>
    80004fee:	e1443423          	sd	s4,-504(s0)
    80004ff2:	b7dd                	j	80004fd8 <exec+0x2c8>
    80004ff4:	e1443423          	sd	s4,-504(s0)
    80004ff8:	b7c5                	j	80004fd8 <exec+0x2c8>
    80004ffa:	e1443423          	sd	s4,-504(s0)
    80004ffe:	bfe9                	j	80004fd8 <exec+0x2c8>
    80005000:	e1443423          	sd	s4,-504(s0)
    80005004:	bfd1                	j	80004fd8 <exec+0x2c8>
  sz = sz1;
    80005006:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500a:	4481                	li	s1,0
    8000500c:	b7f1                	j	80004fd8 <exec+0x2c8>
  sz = sz1;
    8000500e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005012:	4481                	li	s1,0
    80005014:	b7d1                	j	80004fd8 <exec+0x2c8>
  sz = sz1;
    80005016:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501a:	4481                	li	s1,0
    8000501c:	bf75                	j	80004fd8 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000501e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005022:	2b05                	addiw	s6,s6,1
    80005024:	0389899b          	addiw	s3,s3,56
    80005028:	e8845783          	lhu	a5,-376(s0)
    8000502c:	e2fb57e3          	bge	s6,a5,80004e5a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005030:	2981                	sext.w	s3,s3
    80005032:	03800713          	li	a4,56
    80005036:	86ce                	mv	a3,s3
    80005038:	e1840613          	addi	a2,s0,-488
    8000503c:	4581                	li	a1,0
    8000503e:	8526                	mv	a0,s1
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	a6e080e7          	jalr	-1426(ra) # 80003aae <readi>
    80005048:	03800793          	li	a5,56
    8000504c:	f8f514e3          	bne	a0,a5,80004fd4 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005050:	e1842783          	lw	a5,-488(s0)
    80005054:	4705                	li	a4,1
    80005056:	fce796e3          	bne	a5,a4,80005022 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000505a:	e4043903          	ld	s2,-448(s0)
    8000505e:	e3843783          	ld	a5,-456(s0)
    80005062:	f8f966e3          	bltu	s2,a5,80004fee <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005066:	e2843783          	ld	a5,-472(s0)
    8000506a:	993e                	add	s2,s2,a5
    8000506c:	f8f964e3          	bltu	s2,a5,80004ff4 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005070:	df043703          	ld	a4,-528(s0)
    80005074:	8ff9                	and	a5,a5,a4
    80005076:	f3d1                	bnez	a5,80004ffa <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005078:	e1c42503          	lw	a0,-484(s0)
    8000507c:	00000097          	auipc	ra,0x0
    80005080:	c78080e7          	jalr	-904(ra) # 80004cf4 <flags2perm>
    80005084:	86aa                	mv	a3,a0
    80005086:	864a                	mv	a2,s2
    80005088:	85d2                	mv	a1,s4
    8000508a:	855e                	mv	a0,s7
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	3a0080e7          	jalr	928(ra) # 8000142c <uvmalloc>
    80005094:	e0a43423          	sd	a0,-504(s0)
    80005098:	d525                	beqz	a0,80005000 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000509a:	e2843d03          	ld	s10,-472(s0)
    8000509e:	e2042d83          	lw	s11,-480(s0)
    800050a2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050a6:	f60c0ce3          	beqz	s8,8000501e <exec+0x30e>
    800050aa:	8a62                	mv	s4,s8
    800050ac:	4901                	li	s2,0
    800050ae:	b369                	j	80004e38 <exec+0x128>

00000000800050b0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050b0:	7179                	addi	sp,sp,-48
    800050b2:	f406                	sd	ra,40(sp)
    800050b4:	f022                	sd	s0,32(sp)
    800050b6:	ec26                	sd	s1,24(sp)
    800050b8:	e84a                	sd	s2,16(sp)
    800050ba:	1800                	addi	s0,sp,48
    800050bc:	892e                	mv	s2,a1
    800050be:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050c0:	fdc40593          	addi	a1,s0,-36
    800050c4:	ffffe097          	auipc	ra,0xffffe
    800050c8:	a1a080e7          	jalr	-1510(ra) # 80002ade <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050cc:	fdc42703          	lw	a4,-36(s0)
    800050d0:	47bd                	li	a5,15
    800050d2:	02e7eb63          	bltu	a5,a4,80005108 <argfd+0x58>
    800050d6:	ffffd097          	auipc	ra,0xffffd
    800050da:	8f0080e7          	jalr	-1808(ra) # 800019c6 <myproc>
    800050de:	fdc42703          	lw	a4,-36(s0)
    800050e2:	01a70793          	addi	a5,a4,26
    800050e6:	078e                	slli	a5,a5,0x3
    800050e8:	953e                	add	a0,a0,a5
    800050ea:	611c                	ld	a5,0(a0)
    800050ec:	c385                	beqz	a5,8000510c <argfd+0x5c>
    return -1;
  if(pfd)
    800050ee:	00090463          	beqz	s2,800050f6 <argfd+0x46>
    *pfd = fd;
    800050f2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050f6:	4501                	li	a0,0
  if(pf)
    800050f8:	c091                	beqz	s1,800050fc <argfd+0x4c>
    *pf = f;
    800050fa:	e09c                	sd	a5,0(s1)
}
    800050fc:	70a2                	ld	ra,40(sp)
    800050fe:	7402                	ld	s0,32(sp)
    80005100:	64e2                	ld	s1,24(sp)
    80005102:	6942                	ld	s2,16(sp)
    80005104:	6145                	addi	sp,sp,48
    80005106:	8082                	ret
    return -1;
    80005108:	557d                	li	a0,-1
    8000510a:	bfcd                	j	800050fc <argfd+0x4c>
    8000510c:	557d                	li	a0,-1
    8000510e:	b7fd                	j	800050fc <argfd+0x4c>

0000000080005110 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005110:	1101                	addi	sp,sp,-32
    80005112:	ec06                	sd	ra,24(sp)
    80005114:	e822                	sd	s0,16(sp)
    80005116:	e426                	sd	s1,8(sp)
    80005118:	1000                	addi	s0,sp,32
    8000511a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000511c:	ffffd097          	auipc	ra,0xffffd
    80005120:	8aa080e7          	jalr	-1878(ra) # 800019c6 <myproc>
    80005124:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005126:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd190>
    8000512a:	4501                	li	a0,0
    8000512c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000512e:	6398                	ld	a4,0(a5)
    80005130:	cb19                	beqz	a4,80005146 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005132:	2505                	addiw	a0,a0,1
    80005134:	07a1                	addi	a5,a5,8
    80005136:	fed51ce3          	bne	a0,a3,8000512e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000513a:	557d                	li	a0,-1
}
    8000513c:	60e2                	ld	ra,24(sp)
    8000513e:	6442                	ld	s0,16(sp)
    80005140:	64a2                	ld	s1,8(sp)
    80005142:	6105                	addi	sp,sp,32
    80005144:	8082                	ret
      p->ofile[fd] = f;
    80005146:	01a50793          	addi	a5,a0,26
    8000514a:	078e                	slli	a5,a5,0x3
    8000514c:	963e                	add	a2,a2,a5
    8000514e:	e204                	sd	s1,0(a2)
      return fd;
    80005150:	b7f5                	j	8000513c <fdalloc+0x2c>

0000000080005152 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005152:	715d                	addi	sp,sp,-80
    80005154:	e486                	sd	ra,72(sp)
    80005156:	e0a2                	sd	s0,64(sp)
    80005158:	fc26                	sd	s1,56(sp)
    8000515a:	f84a                	sd	s2,48(sp)
    8000515c:	f44e                	sd	s3,40(sp)
    8000515e:	f052                	sd	s4,32(sp)
    80005160:	ec56                	sd	s5,24(sp)
    80005162:	e85a                	sd	s6,16(sp)
    80005164:	0880                	addi	s0,sp,80
    80005166:	8b2e                	mv	s6,a1
    80005168:	89b2                	mv	s3,a2
    8000516a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000516c:	fb040593          	addi	a1,s0,-80
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	e4e080e7          	jalr	-434(ra) # 80003fbe <nameiparent>
    80005178:	84aa                	mv	s1,a0
    8000517a:	16050063          	beqz	a0,800052da <create+0x188>
    return 0;

  ilock(dp);
    8000517e:	ffffe097          	auipc	ra,0xffffe
    80005182:	67c080e7          	jalr	1660(ra) # 800037fa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005186:	4601                	li	a2,0
    80005188:	fb040593          	addi	a1,s0,-80
    8000518c:	8526                	mv	a0,s1
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	b50080e7          	jalr	-1200(ra) # 80003cde <dirlookup>
    80005196:	8aaa                	mv	s5,a0
    80005198:	c931                	beqz	a0,800051ec <create+0x9a>
    iunlockput(dp);
    8000519a:	8526                	mv	a0,s1
    8000519c:	fffff097          	auipc	ra,0xfffff
    800051a0:	8c0080e7          	jalr	-1856(ra) # 80003a5c <iunlockput>
    ilock(ip);
    800051a4:	8556                	mv	a0,s5
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	654080e7          	jalr	1620(ra) # 800037fa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051ae:	000b059b          	sext.w	a1,s6
    800051b2:	4789                	li	a5,2
    800051b4:	02f59563          	bne	a1,a5,800051de <create+0x8c>
    800051b8:	044ad783          	lhu	a5,68(s5)
    800051bc:	37f9                	addiw	a5,a5,-2
    800051be:	17c2                	slli	a5,a5,0x30
    800051c0:	93c1                	srli	a5,a5,0x30
    800051c2:	4705                	li	a4,1
    800051c4:	00f76d63          	bltu	a4,a5,800051de <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051c8:	8556                	mv	a0,s5
    800051ca:	60a6                	ld	ra,72(sp)
    800051cc:	6406                	ld	s0,64(sp)
    800051ce:	74e2                	ld	s1,56(sp)
    800051d0:	7942                	ld	s2,48(sp)
    800051d2:	79a2                	ld	s3,40(sp)
    800051d4:	7a02                	ld	s4,32(sp)
    800051d6:	6ae2                	ld	s5,24(sp)
    800051d8:	6b42                	ld	s6,16(sp)
    800051da:	6161                	addi	sp,sp,80
    800051dc:	8082                	ret
    iunlockput(ip);
    800051de:	8556                	mv	a0,s5
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	87c080e7          	jalr	-1924(ra) # 80003a5c <iunlockput>
    return 0;
    800051e8:	4a81                	li	s5,0
    800051ea:	bff9                	j	800051c8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051ec:	85da                	mv	a1,s6
    800051ee:	4088                	lw	a0,0(s1)
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	46e080e7          	jalr	1134(ra) # 8000365e <ialloc>
    800051f8:	8a2a                	mv	s4,a0
    800051fa:	c921                	beqz	a0,8000524a <create+0xf8>
  ilock(ip);
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	5fe080e7          	jalr	1534(ra) # 800037fa <ilock>
  ip->major = major;
    80005204:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005208:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000520c:	4785                	li	a5,1
    8000520e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005212:	8552                	mv	a0,s4
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	51c080e7          	jalr	1308(ra) # 80003730 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000521c:	000b059b          	sext.w	a1,s6
    80005220:	4785                	li	a5,1
    80005222:	02f58b63          	beq	a1,a5,80005258 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005226:	004a2603          	lw	a2,4(s4)
    8000522a:	fb040593          	addi	a1,s0,-80
    8000522e:	8526                	mv	a0,s1
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	cbe080e7          	jalr	-834(ra) # 80003eee <dirlink>
    80005238:	06054f63          	bltz	a0,800052b6 <create+0x164>
  iunlockput(dp);
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	81e080e7          	jalr	-2018(ra) # 80003a5c <iunlockput>
  return ip;
    80005246:	8ad2                	mv	s5,s4
    80005248:	b741                	j	800051c8 <create+0x76>
    iunlockput(dp);
    8000524a:	8526                	mv	a0,s1
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	810080e7          	jalr	-2032(ra) # 80003a5c <iunlockput>
    return 0;
    80005254:	8ad2                	mv	s5,s4
    80005256:	bf8d                	j	800051c8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005258:	004a2603          	lw	a2,4(s4)
    8000525c:	00003597          	auipc	a1,0x3
    80005260:	68c58593          	addi	a1,a1,1676 # 800088e8 <sysargs+0x248>
    80005264:	8552                	mv	a0,s4
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	c88080e7          	jalr	-888(ra) # 80003eee <dirlink>
    8000526e:	04054463          	bltz	a0,800052b6 <create+0x164>
    80005272:	40d0                	lw	a2,4(s1)
    80005274:	00003597          	auipc	a1,0x3
    80005278:	67c58593          	addi	a1,a1,1660 # 800088f0 <sysargs+0x250>
    8000527c:	8552                	mv	a0,s4
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	c70080e7          	jalr	-912(ra) # 80003eee <dirlink>
    80005286:	02054863          	bltz	a0,800052b6 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000528a:	004a2603          	lw	a2,4(s4)
    8000528e:	fb040593          	addi	a1,s0,-80
    80005292:	8526                	mv	a0,s1
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	c5a080e7          	jalr	-934(ra) # 80003eee <dirlink>
    8000529c:	00054d63          	bltz	a0,800052b6 <create+0x164>
    dp->nlink++;  // for ".."
    800052a0:	04a4d783          	lhu	a5,74(s1)
    800052a4:	2785                	addiw	a5,a5,1
    800052a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052aa:	8526                	mv	a0,s1
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	484080e7          	jalr	1156(ra) # 80003730 <iupdate>
    800052b4:	b761                	j	8000523c <create+0xea>
  ip->nlink = 0;
    800052b6:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052ba:	8552                	mv	a0,s4
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	474080e7          	jalr	1140(ra) # 80003730 <iupdate>
  iunlockput(ip);
    800052c4:	8552                	mv	a0,s4
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	796080e7          	jalr	1942(ra) # 80003a5c <iunlockput>
  iunlockput(dp);
    800052ce:	8526                	mv	a0,s1
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	78c080e7          	jalr	1932(ra) # 80003a5c <iunlockput>
  return 0;
    800052d8:	bdc5                	j	800051c8 <create+0x76>
    return 0;
    800052da:	8aaa                	mv	s5,a0
    800052dc:	b5f5                	j	800051c8 <create+0x76>

00000000800052de <sys_dup>:
{
    800052de:	7179                	addi	sp,sp,-48
    800052e0:	f406                	sd	ra,40(sp)
    800052e2:	f022                	sd	s0,32(sp)
    800052e4:	ec26                	sd	s1,24(sp)
    800052e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052e8:	fd840613          	addi	a2,s0,-40
    800052ec:	4581                	li	a1,0
    800052ee:	4501                	li	a0,0
    800052f0:	00000097          	auipc	ra,0x0
    800052f4:	dc0080e7          	jalr	-576(ra) # 800050b0 <argfd>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052fa:	02054363          	bltz	a0,80005320 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052fe:	fd843503          	ld	a0,-40(s0)
    80005302:	00000097          	auipc	ra,0x0
    80005306:	e0e080e7          	jalr	-498(ra) # 80005110 <fdalloc>
    8000530a:	84aa                	mv	s1,a0
    return -1;
    8000530c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000530e:	00054963          	bltz	a0,80005320 <sys_dup+0x42>
  filedup(f);
    80005312:	fd843503          	ld	a0,-40(s0)
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	320080e7          	jalr	800(ra) # 80004636 <filedup>
  return fd;
    8000531e:	87a6                	mv	a5,s1
}
    80005320:	853e                	mv	a0,a5
    80005322:	70a2                	ld	ra,40(sp)
    80005324:	7402                	ld	s0,32(sp)
    80005326:	64e2                	ld	s1,24(sp)
    80005328:	6145                	addi	sp,sp,48
    8000532a:	8082                	ret

000000008000532c <sys_read>:
{
    8000532c:	7179                	addi	sp,sp,-48
    8000532e:	f406                	sd	ra,40(sp)
    80005330:	f022                	sd	s0,32(sp)
    80005332:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005334:	fd840593          	addi	a1,s0,-40
    80005338:	4505                	li	a0,1
    8000533a:	ffffd097          	auipc	ra,0xffffd
    8000533e:	7c4080e7          	jalr	1988(ra) # 80002afe <argaddr>
  argint(2, &n);
    80005342:	fe440593          	addi	a1,s0,-28
    80005346:	4509                	li	a0,2
    80005348:	ffffd097          	auipc	ra,0xffffd
    8000534c:	796080e7          	jalr	1942(ra) # 80002ade <argint>
  if(argfd(0, 0, &f) < 0)
    80005350:	fe840613          	addi	a2,s0,-24
    80005354:	4581                	li	a1,0
    80005356:	4501                	li	a0,0
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	d58080e7          	jalr	-680(ra) # 800050b0 <argfd>
    80005360:	87aa                	mv	a5,a0
    return -1;
    80005362:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005364:	0007cc63          	bltz	a5,8000537c <sys_read+0x50>
  return fileread(f, p, n);
    80005368:	fe442603          	lw	a2,-28(s0)
    8000536c:	fd843583          	ld	a1,-40(s0)
    80005370:	fe843503          	ld	a0,-24(s0)
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	44e080e7          	jalr	1102(ra) # 800047c2 <fileread>
}
    8000537c:	70a2                	ld	ra,40(sp)
    8000537e:	7402                	ld	s0,32(sp)
    80005380:	6145                	addi	sp,sp,48
    80005382:	8082                	ret

0000000080005384 <sys_write>:
{
    80005384:	7179                	addi	sp,sp,-48
    80005386:	f406                	sd	ra,40(sp)
    80005388:	f022                	sd	s0,32(sp)
    8000538a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000538c:	fd840593          	addi	a1,s0,-40
    80005390:	4505                	li	a0,1
    80005392:	ffffd097          	auipc	ra,0xffffd
    80005396:	76c080e7          	jalr	1900(ra) # 80002afe <argaddr>
  argint(2, &n);
    8000539a:	fe440593          	addi	a1,s0,-28
    8000539e:	4509                	li	a0,2
    800053a0:	ffffd097          	auipc	ra,0xffffd
    800053a4:	73e080e7          	jalr	1854(ra) # 80002ade <argint>
  if(argfd(0, 0, &f) < 0)
    800053a8:	fe840613          	addi	a2,s0,-24
    800053ac:	4581                	li	a1,0
    800053ae:	4501                	li	a0,0
    800053b0:	00000097          	auipc	ra,0x0
    800053b4:	d00080e7          	jalr	-768(ra) # 800050b0 <argfd>
    800053b8:	87aa                	mv	a5,a0
    return -1;
    800053ba:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053bc:	0007cc63          	bltz	a5,800053d4 <sys_write+0x50>
  return filewrite(f, p, n);
    800053c0:	fe442603          	lw	a2,-28(s0)
    800053c4:	fd843583          	ld	a1,-40(s0)
    800053c8:	fe843503          	ld	a0,-24(s0)
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	4b8080e7          	jalr	1208(ra) # 80004884 <filewrite>
}
    800053d4:	70a2                	ld	ra,40(sp)
    800053d6:	7402                	ld	s0,32(sp)
    800053d8:	6145                	addi	sp,sp,48
    800053da:	8082                	ret

00000000800053dc <sys_close>:
{
    800053dc:	1101                	addi	sp,sp,-32
    800053de:	ec06                	sd	ra,24(sp)
    800053e0:	e822                	sd	s0,16(sp)
    800053e2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053e4:	fe040613          	addi	a2,s0,-32
    800053e8:	fec40593          	addi	a1,s0,-20
    800053ec:	4501                	li	a0,0
    800053ee:	00000097          	auipc	ra,0x0
    800053f2:	cc2080e7          	jalr	-830(ra) # 800050b0 <argfd>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053f8:	02054463          	bltz	a0,80005420 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053fc:	ffffc097          	auipc	ra,0xffffc
    80005400:	5ca080e7          	jalr	1482(ra) # 800019c6 <myproc>
    80005404:	fec42783          	lw	a5,-20(s0)
    80005408:	07e9                	addi	a5,a5,26
    8000540a:	078e                	slli	a5,a5,0x3
    8000540c:	97aa                	add	a5,a5,a0
    8000540e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005412:	fe043503          	ld	a0,-32(s0)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	272080e7          	jalr	626(ra) # 80004688 <fileclose>
  return 0;
    8000541e:	4781                	li	a5,0
}
    80005420:	853e                	mv	a0,a5
    80005422:	60e2                	ld	ra,24(sp)
    80005424:	6442                	ld	s0,16(sp)
    80005426:	6105                	addi	sp,sp,32
    80005428:	8082                	ret

000000008000542a <sys_fstat>:
{
    8000542a:	1101                	addi	sp,sp,-32
    8000542c:	ec06                	sd	ra,24(sp)
    8000542e:	e822                	sd	s0,16(sp)
    80005430:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005432:	fe040593          	addi	a1,s0,-32
    80005436:	4505                	li	a0,1
    80005438:	ffffd097          	auipc	ra,0xffffd
    8000543c:	6c6080e7          	jalr	1734(ra) # 80002afe <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005440:	fe840613          	addi	a2,s0,-24
    80005444:	4581                	li	a1,0
    80005446:	4501                	li	a0,0
    80005448:	00000097          	auipc	ra,0x0
    8000544c:	c68080e7          	jalr	-920(ra) # 800050b0 <argfd>
    80005450:	87aa                	mv	a5,a0
    return -1;
    80005452:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005454:	0007ca63          	bltz	a5,80005468 <sys_fstat+0x3e>
  return filestat(f, st);
    80005458:	fe043583          	ld	a1,-32(s0)
    8000545c:	fe843503          	ld	a0,-24(s0)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	2f0080e7          	jalr	752(ra) # 80004750 <filestat>
}
    80005468:	60e2                	ld	ra,24(sp)
    8000546a:	6442                	ld	s0,16(sp)
    8000546c:	6105                	addi	sp,sp,32
    8000546e:	8082                	ret

0000000080005470 <sys_link>:
{
    80005470:	7169                	addi	sp,sp,-304
    80005472:	f606                	sd	ra,296(sp)
    80005474:	f222                	sd	s0,288(sp)
    80005476:	ee26                	sd	s1,280(sp)
    80005478:	ea4a                	sd	s2,272(sp)
    8000547a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547c:	08000613          	li	a2,128
    80005480:	ed040593          	addi	a1,s0,-304
    80005484:	4501                	li	a0,0
    80005486:	ffffd097          	auipc	ra,0xffffd
    8000548a:	698080e7          	jalr	1688(ra) # 80002b1e <argstr>
    return -1;
    8000548e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005490:	10054e63          	bltz	a0,800055ac <sys_link+0x13c>
    80005494:	08000613          	li	a2,128
    80005498:	f5040593          	addi	a1,s0,-176
    8000549c:	4505                	li	a0,1
    8000549e:	ffffd097          	auipc	ra,0xffffd
    800054a2:	680080e7          	jalr	1664(ra) # 80002b1e <argstr>
    return -1;
    800054a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a8:	10054263          	bltz	a0,800055ac <sys_link+0x13c>
  begin_op();
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	d10080e7          	jalr	-752(ra) # 800041bc <begin_op>
  if((ip = namei(old)) == 0){
    800054b4:	ed040513          	addi	a0,s0,-304
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	ae8080e7          	jalr	-1304(ra) # 80003fa0 <namei>
    800054c0:	84aa                	mv	s1,a0
    800054c2:	c551                	beqz	a0,8000554e <sys_link+0xde>
  ilock(ip);
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	336080e7          	jalr	822(ra) # 800037fa <ilock>
  if(ip->type == T_DIR){
    800054cc:	04449703          	lh	a4,68(s1)
    800054d0:	4785                	li	a5,1
    800054d2:	08f70463          	beq	a4,a5,8000555a <sys_link+0xea>
  ip->nlink++;
    800054d6:	04a4d783          	lhu	a5,74(s1)
    800054da:	2785                	addiw	a5,a5,1
    800054dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	24e080e7          	jalr	590(ra) # 80003730 <iupdate>
  iunlock(ip);
    800054ea:	8526                	mv	a0,s1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	3d0080e7          	jalr	976(ra) # 800038bc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054f4:	fd040593          	addi	a1,s0,-48
    800054f8:	f5040513          	addi	a0,s0,-176
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	ac2080e7          	jalr	-1342(ra) # 80003fbe <nameiparent>
    80005504:	892a                	mv	s2,a0
    80005506:	c935                	beqz	a0,8000557a <sys_link+0x10a>
  ilock(dp);
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	2f2080e7          	jalr	754(ra) # 800037fa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005510:	00092703          	lw	a4,0(s2)
    80005514:	409c                	lw	a5,0(s1)
    80005516:	04f71d63          	bne	a4,a5,80005570 <sys_link+0x100>
    8000551a:	40d0                	lw	a2,4(s1)
    8000551c:	fd040593          	addi	a1,s0,-48
    80005520:	854a                	mv	a0,s2
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	9cc080e7          	jalr	-1588(ra) # 80003eee <dirlink>
    8000552a:	04054363          	bltz	a0,80005570 <sys_link+0x100>
  iunlockput(dp);
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	52c080e7          	jalr	1324(ra) # 80003a5c <iunlockput>
  iput(ip);
    80005538:	8526                	mv	a0,s1
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	47a080e7          	jalr	1146(ra) # 800039b4 <iput>
  end_op();
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	cfa080e7          	jalr	-774(ra) # 8000423c <end_op>
  return 0;
    8000554a:	4781                	li	a5,0
    8000554c:	a085                	j	800055ac <sys_link+0x13c>
    end_op();
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	cee080e7          	jalr	-786(ra) # 8000423c <end_op>
    return -1;
    80005556:	57fd                	li	a5,-1
    80005558:	a891                	j	800055ac <sys_link+0x13c>
    iunlockput(ip);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	500080e7          	jalr	1280(ra) # 80003a5c <iunlockput>
    end_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	cd8080e7          	jalr	-808(ra) # 8000423c <end_op>
    return -1;
    8000556c:	57fd                	li	a5,-1
    8000556e:	a83d                	j	800055ac <sys_link+0x13c>
    iunlockput(dp);
    80005570:	854a                	mv	a0,s2
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	4ea080e7          	jalr	1258(ra) # 80003a5c <iunlockput>
  ilock(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	27e080e7          	jalr	638(ra) # 800037fa <ilock>
  ip->nlink--;
    80005584:	04a4d783          	lhu	a5,74(s1)
    80005588:	37fd                	addiw	a5,a5,-1
    8000558a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	1a0080e7          	jalr	416(ra) # 80003730 <iupdate>
  iunlockput(ip);
    80005598:	8526                	mv	a0,s1
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	4c2080e7          	jalr	1218(ra) # 80003a5c <iunlockput>
  end_op();
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	c9a080e7          	jalr	-870(ra) # 8000423c <end_op>
  return -1;
    800055aa:	57fd                	li	a5,-1
}
    800055ac:	853e                	mv	a0,a5
    800055ae:	70b2                	ld	ra,296(sp)
    800055b0:	7412                	ld	s0,288(sp)
    800055b2:	64f2                	ld	s1,280(sp)
    800055b4:	6952                	ld	s2,272(sp)
    800055b6:	6155                	addi	sp,sp,304
    800055b8:	8082                	ret

00000000800055ba <sys_unlink>:
{
    800055ba:	7151                	addi	sp,sp,-240
    800055bc:	f586                	sd	ra,232(sp)
    800055be:	f1a2                	sd	s0,224(sp)
    800055c0:	eda6                	sd	s1,216(sp)
    800055c2:	e9ca                	sd	s2,208(sp)
    800055c4:	e5ce                	sd	s3,200(sp)
    800055c6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055c8:	08000613          	li	a2,128
    800055cc:	f3040593          	addi	a1,s0,-208
    800055d0:	4501                	li	a0,0
    800055d2:	ffffd097          	auipc	ra,0xffffd
    800055d6:	54c080e7          	jalr	1356(ra) # 80002b1e <argstr>
    800055da:	18054163          	bltz	a0,8000575c <sys_unlink+0x1a2>
  begin_op();
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	bde080e7          	jalr	-1058(ra) # 800041bc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055e6:	fb040593          	addi	a1,s0,-80
    800055ea:	f3040513          	addi	a0,s0,-208
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	9d0080e7          	jalr	-1584(ra) # 80003fbe <nameiparent>
    800055f6:	84aa                	mv	s1,a0
    800055f8:	c979                	beqz	a0,800056ce <sys_unlink+0x114>
  ilock(dp);
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	200080e7          	jalr	512(ra) # 800037fa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005602:	00003597          	auipc	a1,0x3
    80005606:	2e658593          	addi	a1,a1,742 # 800088e8 <sysargs+0x248>
    8000560a:	fb040513          	addi	a0,s0,-80
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	6b6080e7          	jalr	1718(ra) # 80003cc4 <namecmp>
    80005616:	14050a63          	beqz	a0,8000576a <sys_unlink+0x1b0>
    8000561a:	00003597          	auipc	a1,0x3
    8000561e:	2d658593          	addi	a1,a1,726 # 800088f0 <sysargs+0x250>
    80005622:	fb040513          	addi	a0,s0,-80
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	69e080e7          	jalr	1694(ra) # 80003cc4 <namecmp>
    8000562e:	12050e63          	beqz	a0,8000576a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005632:	f2c40613          	addi	a2,s0,-212
    80005636:	fb040593          	addi	a1,s0,-80
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	6a2080e7          	jalr	1698(ra) # 80003cde <dirlookup>
    80005644:	892a                	mv	s2,a0
    80005646:	12050263          	beqz	a0,8000576a <sys_unlink+0x1b0>
  ilock(ip);
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	1b0080e7          	jalr	432(ra) # 800037fa <ilock>
  if(ip->nlink < 1)
    80005652:	04a91783          	lh	a5,74(s2)
    80005656:	08f05263          	blez	a5,800056da <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000565a:	04491703          	lh	a4,68(s2)
    8000565e:	4785                	li	a5,1
    80005660:	08f70563          	beq	a4,a5,800056ea <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005664:	4641                	li	a2,16
    80005666:	4581                	li	a1,0
    80005668:	fc040513          	addi	a0,s0,-64
    8000566c:	ffffb097          	auipc	ra,0xffffb
    80005670:	67a080e7          	jalr	1658(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005674:	4741                	li	a4,16
    80005676:	f2c42683          	lw	a3,-212(s0)
    8000567a:	fc040613          	addi	a2,s0,-64
    8000567e:	4581                	li	a1,0
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	524080e7          	jalr	1316(ra) # 80003ba6 <writei>
    8000568a:	47c1                	li	a5,16
    8000568c:	0af51563          	bne	a0,a5,80005736 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005690:	04491703          	lh	a4,68(s2)
    80005694:	4785                	li	a5,1
    80005696:	0af70863          	beq	a4,a5,80005746 <sys_unlink+0x18c>
  iunlockput(dp);
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	3c0080e7          	jalr	960(ra) # 80003a5c <iunlockput>
  ip->nlink--;
    800056a4:	04a95783          	lhu	a5,74(s2)
    800056a8:	37fd                	addiw	a5,a5,-1
    800056aa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056ae:	854a                	mv	a0,s2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	080080e7          	jalr	128(ra) # 80003730 <iupdate>
  iunlockput(ip);
    800056b8:	854a                	mv	a0,s2
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	3a2080e7          	jalr	930(ra) # 80003a5c <iunlockput>
  end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	b7a080e7          	jalr	-1158(ra) # 8000423c <end_op>
  return 0;
    800056ca:	4501                	li	a0,0
    800056cc:	a84d                	j	8000577e <sys_unlink+0x1c4>
    end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	b6e080e7          	jalr	-1170(ra) # 8000423c <end_op>
    return -1;
    800056d6:	557d                	li	a0,-1
    800056d8:	a05d                	j	8000577e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056da:	00003517          	auipc	a0,0x3
    800056de:	21e50513          	addi	a0,a0,542 # 800088f8 <sysargs+0x258>
    800056e2:	ffffb097          	auipc	ra,0xffffb
    800056e6:	e62080e7          	jalr	-414(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ea:	04c92703          	lw	a4,76(s2)
    800056ee:	02000793          	li	a5,32
    800056f2:	f6e7f9e3          	bgeu	a5,a4,80005664 <sys_unlink+0xaa>
    800056f6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056fa:	4741                	li	a4,16
    800056fc:	86ce                	mv	a3,s3
    800056fe:	f1840613          	addi	a2,s0,-232
    80005702:	4581                	li	a1,0
    80005704:	854a                	mv	a0,s2
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	3a8080e7          	jalr	936(ra) # 80003aae <readi>
    8000570e:	47c1                	li	a5,16
    80005710:	00f51b63          	bne	a0,a5,80005726 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005714:	f1845783          	lhu	a5,-232(s0)
    80005718:	e7a1                	bnez	a5,80005760 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000571a:	29c1                	addiw	s3,s3,16
    8000571c:	04c92783          	lw	a5,76(s2)
    80005720:	fcf9ede3          	bltu	s3,a5,800056fa <sys_unlink+0x140>
    80005724:	b781                	j	80005664 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005726:	00003517          	auipc	a0,0x3
    8000572a:	1ea50513          	addi	a0,a0,490 # 80008910 <sysargs+0x270>
    8000572e:	ffffb097          	auipc	ra,0xffffb
    80005732:	e16080e7          	jalr	-490(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005736:	00003517          	auipc	a0,0x3
    8000573a:	1f250513          	addi	a0,a0,498 # 80008928 <sysargs+0x288>
    8000573e:	ffffb097          	auipc	ra,0xffffb
    80005742:	e06080e7          	jalr	-506(ra) # 80000544 <panic>
    dp->nlink--;
    80005746:	04a4d783          	lhu	a5,74(s1)
    8000574a:	37fd                	addiw	a5,a5,-1
    8000574c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005750:	8526                	mv	a0,s1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	fde080e7          	jalr	-34(ra) # 80003730 <iupdate>
    8000575a:	b781                	j	8000569a <sys_unlink+0xe0>
    return -1;
    8000575c:	557d                	li	a0,-1
    8000575e:	a005                	j	8000577e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005760:	854a                	mv	a0,s2
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	2fa080e7          	jalr	762(ra) # 80003a5c <iunlockput>
  iunlockput(dp);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	2f0080e7          	jalr	752(ra) # 80003a5c <iunlockput>
  end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	ac8080e7          	jalr	-1336(ra) # 8000423c <end_op>
  return -1;
    8000577c:	557d                	li	a0,-1
}
    8000577e:	70ae                	ld	ra,232(sp)
    80005780:	740e                	ld	s0,224(sp)
    80005782:	64ee                	ld	s1,216(sp)
    80005784:	694e                	ld	s2,208(sp)
    80005786:	69ae                	ld	s3,200(sp)
    80005788:	616d                	addi	sp,sp,240
    8000578a:	8082                	ret

000000008000578c <sys_open>:

uint64
sys_open(void)
{
    8000578c:	7131                	addi	sp,sp,-192
    8000578e:	fd06                	sd	ra,184(sp)
    80005790:	f922                	sd	s0,176(sp)
    80005792:	f526                	sd	s1,168(sp)
    80005794:	f14a                	sd	s2,160(sp)
    80005796:	ed4e                	sd	s3,152(sp)
    80005798:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000579a:	f4c40593          	addi	a1,s0,-180
    8000579e:	4505                	li	a0,1
    800057a0:	ffffd097          	auipc	ra,0xffffd
    800057a4:	33e080e7          	jalr	830(ra) # 80002ade <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057a8:	08000613          	li	a2,128
    800057ac:	f5040593          	addi	a1,s0,-176
    800057b0:	4501                	li	a0,0
    800057b2:	ffffd097          	auipc	ra,0xffffd
    800057b6:	36c080e7          	jalr	876(ra) # 80002b1e <argstr>
    800057ba:	87aa                	mv	a5,a0
    return -1;
    800057bc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057be:	0a07c963          	bltz	a5,80005870 <sys_open+0xe4>

  begin_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	9fa080e7          	jalr	-1542(ra) # 800041bc <begin_op>

  if(omode & O_CREATE){
    800057ca:	f4c42783          	lw	a5,-180(s0)
    800057ce:	2007f793          	andi	a5,a5,512
    800057d2:	cfc5                	beqz	a5,8000588a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057d4:	4681                	li	a3,0
    800057d6:	4601                	li	a2,0
    800057d8:	4589                	li	a1,2
    800057da:	f5040513          	addi	a0,s0,-176
    800057de:	00000097          	auipc	ra,0x0
    800057e2:	974080e7          	jalr	-1676(ra) # 80005152 <create>
    800057e6:	84aa                	mv	s1,a0
    if(ip == 0){
    800057e8:	c959                	beqz	a0,8000587e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057ea:	04449703          	lh	a4,68(s1)
    800057ee:	478d                	li	a5,3
    800057f0:	00f71763          	bne	a4,a5,800057fe <sys_open+0x72>
    800057f4:	0464d703          	lhu	a4,70(s1)
    800057f8:	47a5                	li	a5,9
    800057fa:	0ce7ed63          	bltu	a5,a4,800058d4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	dce080e7          	jalr	-562(ra) # 800045cc <filealloc>
    80005806:	89aa                	mv	s3,a0
    80005808:	10050363          	beqz	a0,8000590e <sys_open+0x182>
    8000580c:	00000097          	auipc	ra,0x0
    80005810:	904080e7          	jalr	-1788(ra) # 80005110 <fdalloc>
    80005814:	892a                	mv	s2,a0
    80005816:	0e054763          	bltz	a0,80005904 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000581a:	04449703          	lh	a4,68(s1)
    8000581e:	478d                	li	a5,3
    80005820:	0cf70563          	beq	a4,a5,800058ea <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005824:	4789                	li	a5,2
    80005826:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000582a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000582e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005832:	f4c42783          	lw	a5,-180(s0)
    80005836:	0017c713          	xori	a4,a5,1
    8000583a:	8b05                	andi	a4,a4,1
    8000583c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005840:	0037f713          	andi	a4,a5,3
    80005844:	00e03733          	snez	a4,a4
    80005848:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000584c:	4007f793          	andi	a5,a5,1024
    80005850:	c791                	beqz	a5,8000585c <sys_open+0xd0>
    80005852:	04449703          	lh	a4,68(s1)
    80005856:	4789                	li	a5,2
    80005858:	0af70063          	beq	a4,a5,800058f8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	05e080e7          	jalr	94(ra) # 800038bc <iunlock>
  end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	9d6080e7          	jalr	-1578(ra) # 8000423c <end_op>

  return fd;
    8000586e:	854a                	mv	a0,s2
}
    80005870:	70ea                	ld	ra,184(sp)
    80005872:	744a                	ld	s0,176(sp)
    80005874:	74aa                	ld	s1,168(sp)
    80005876:	790a                	ld	s2,160(sp)
    80005878:	69ea                	ld	s3,152(sp)
    8000587a:	6129                	addi	sp,sp,192
    8000587c:	8082                	ret
      end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	9be080e7          	jalr	-1602(ra) # 8000423c <end_op>
      return -1;
    80005886:	557d                	li	a0,-1
    80005888:	b7e5                	j	80005870 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000588a:	f5040513          	addi	a0,s0,-176
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	712080e7          	jalr	1810(ra) # 80003fa0 <namei>
    80005896:	84aa                	mv	s1,a0
    80005898:	c905                	beqz	a0,800058c8 <sys_open+0x13c>
    ilock(ip);
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	f60080e7          	jalr	-160(ra) # 800037fa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058a2:	04449703          	lh	a4,68(s1)
    800058a6:	4785                	li	a5,1
    800058a8:	f4f711e3          	bne	a4,a5,800057ea <sys_open+0x5e>
    800058ac:	f4c42783          	lw	a5,-180(s0)
    800058b0:	d7b9                	beqz	a5,800057fe <sys_open+0x72>
      iunlockput(ip);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	1a8080e7          	jalr	424(ra) # 80003a5c <iunlockput>
      end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	980080e7          	jalr	-1664(ra) # 8000423c <end_op>
      return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	b76d                	j	80005870 <sys_open+0xe4>
      end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	974080e7          	jalr	-1676(ra) # 8000423c <end_op>
      return -1;
    800058d0:	557d                	li	a0,-1
    800058d2:	bf79                	j	80005870 <sys_open+0xe4>
    iunlockput(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	186080e7          	jalr	390(ra) # 80003a5c <iunlockput>
    end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	95e080e7          	jalr	-1698(ra) # 8000423c <end_op>
    return -1;
    800058e6:	557d                	li	a0,-1
    800058e8:	b761                	j	80005870 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058ea:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058ee:	04649783          	lh	a5,70(s1)
    800058f2:	02f99223          	sh	a5,36(s3)
    800058f6:	bf25                	j	8000582e <sys_open+0xa2>
    itrunc(ip);
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	00e080e7          	jalr	14(ra) # 80003908 <itrunc>
    80005902:	bfa9                	j	8000585c <sys_open+0xd0>
      fileclose(f);
    80005904:	854e                	mv	a0,s3
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	d82080e7          	jalr	-638(ra) # 80004688 <fileclose>
    iunlockput(ip);
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	14c080e7          	jalr	332(ra) # 80003a5c <iunlockput>
    end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	924080e7          	jalr	-1756(ra) # 8000423c <end_op>
    return -1;
    80005920:	557d                	li	a0,-1
    80005922:	b7b9                	j	80005870 <sys_open+0xe4>

0000000080005924 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005924:	7175                	addi	sp,sp,-144
    80005926:	e506                	sd	ra,136(sp)
    80005928:	e122                	sd	s0,128(sp)
    8000592a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	890080e7          	jalr	-1904(ra) # 800041bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005934:	08000613          	li	a2,128
    80005938:	f7040593          	addi	a1,s0,-144
    8000593c:	4501                	li	a0,0
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	1e0080e7          	jalr	480(ra) # 80002b1e <argstr>
    80005946:	02054963          	bltz	a0,80005978 <sys_mkdir+0x54>
    8000594a:	4681                	li	a3,0
    8000594c:	4601                	li	a2,0
    8000594e:	4585                	li	a1,1
    80005950:	f7040513          	addi	a0,s0,-144
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	7fe080e7          	jalr	2046(ra) # 80005152 <create>
    8000595c:	cd11                	beqz	a0,80005978 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	0fe080e7          	jalr	254(ra) # 80003a5c <iunlockput>
  end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	8d6080e7          	jalr	-1834(ra) # 8000423c <end_op>
  return 0;
    8000596e:	4501                	li	a0,0
}
    80005970:	60aa                	ld	ra,136(sp)
    80005972:	640a                	ld	s0,128(sp)
    80005974:	6149                	addi	sp,sp,144
    80005976:	8082                	ret
    end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	8c4080e7          	jalr	-1852(ra) # 8000423c <end_op>
    return -1;
    80005980:	557d                	li	a0,-1
    80005982:	b7fd                	j	80005970 <sys_mkdir+0x4c>

0000000080005984 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005984:	7135                	addi	sp,sp,-160
    80005986:	ed06                	sd	ra,152(sp)
    80005988:	e922                	sd	s0,144(sp)
    8000598a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	830080e7          	jalr	-2000(ra) # 800041bc <begin_op>
  argint(1, &major);
    80005994:	f6c40593          	addi	a1,s0,-148
    80005998:	4505                	li	a0,1
    8000599a:	ffffd097          	auipc	ra,0xffffd
    8000599e:	144080e7          	jalr	324(ra) # 80002ade <argint>
  argint(2, &minor);
    800059a2:	f6840593          	addi	a1,s0,-152
    800059a6:	4509                	li	a0,2
    800059a8:	ffffd097          	auipc	ra,0xffffd
    800059ac:	136080e7          	jalr	310(ra) # 80002ade <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b0:	08000613          	li	a2,128
    800059b4:	f7040593          	addi	a1,s0,-144
    800059b8:	4501                	li	a0,0
    800059ba:	ffffd097          	auipc	ra,0xffffd
    800059be:	164080e7          	jalr	356(ra) # 80002b1e <argstr>
    800059c2:	02054b63          	bltz	a0,800059f8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059c6:	f6841683          	lh	a3,-152(s0)
    800059ca:	f6c41603          	lh	a2,-148(s0)
    800059ce:	458d                	li	a1,3
    800059d0:	f7040513          	addi	a0,s0,-144
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	77e080e7          	jalr	1918(ra) # 80005152 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059dc:	cd11                	beqz	a0,800059f8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	07e080e7          	jalr	126(ra) # 80003a5c <iunlockput>
  end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	856080e7          	jalr	-1962(ra) # 8000423c <end_op>
  return 0;
    800059ee:	4501                	li	a0,0
}
    800059f0:	60ea                	ld	ra,152(sp)
    800059f2:	644a                	ld	s0,144(sp)
    800059f4:	610d                	addi	sp,sp,160
    800059f6:	8082                	ret
    end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	844080e7          	jalr	-1980(ra) # 8000423c <end_op>
    return -1;
    80005a00:	557d                	li	a0,-1
    80005a02:	b7fd                	j	800059f0 <sys_mknod+0x6c>

0000000080005a04 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a04:	7135                	addi	sp,sp,-160
    80005a06:	ed06                	sd	ra,152(sp)
    80005a08:	e922                	sd	s0,144(sp)
    80005a0a:	e526                	sd	s1,136(sp)
    80005a0c:	e14a                	sd	s2,128(sp)
    80005a0e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a10:	ffffc097          	auipc	ra,0xffffc
    80005a14:	fb6080e7          	jalr	-74(ra) # 800019c6 <myproc>
    80005a18:	892a                	mv	s2,a0
  
  begin_op();
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	7a2080e7          	jalr	1954(ra) # 800041bc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a22:	08000613          	li	a2,128
    80005a26:	f6040593          	addi	a1,s0,-160
    80005a2a:	4501                	li	a0,0
    80005a2c:	ffffd097          	auipc	ra,0xffffd
    80005a30:	0f2080e7          	jalr	242(ra) # 80002b1e <argstr>
    80005a34:	04054b63          	bltz	a0,80005a8a <sys_chdir+0x86>
    80005a38:	f6040513          	addi	a0,s0,-160
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	564080e7          	jalr	1380(ra) # 80003fa0 <namei>
    80005a44:	84aa                	mv	s1,a0
    80005a46:	c131                	beqz	a0,80005a8a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	db2080e7          	jalr	-590(ra) # 800037fa <ilock>
  if(ip->type != T_DIR){
    80005a50:	04449703          	lh	a4,68(s1)
    80005a54:	4785                	li	a5,1
    80005a56:	04f71063          	bne	a4,a5,80005a96 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	e60080e7          	jalr	-416(ra) # 800038bc <iunlock>
  iput(p->cwd);
    80005a64:	15093503          	ld	a0,336(s2)
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	f4c080e7          	jalr	-180(ra) # 800039b4 <iput>
  end_op();
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	7cc080e7          	jalr	1996(ra) # 8000423c <end_op>
  p->cwd = ip;
    80005a78:	14993823          	sd	s1,336(s2)
  return 0;
    80005a7c:	4501                	li	a0,0
}
    80005a7e:	60ea                	ld	ra,152(sp)
    80005a80:	644a                	ld	s0,144(sp)
    80005a82:	64aa                	ld	s1,136(sp)
    80005a84:	690a                	ld	s2,128(sp)
    80005a86:	610d                	addi	sp,sp,160
    80005a88:	8082                	ret
    end_op();
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	7b2080e7          	jalr	1970(ra) # 8000423c <end_op>
    return -1;
    80005a92:	557d                	li	a0,-1
    80005a94:	b7ed                	j	80005a7e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	fc4080e7          	jalr	-60(ra) # 80003a5c <iunlockput>
    end_op();
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	79c080e7          	jalr	1948(ra) # 8000423c <end_op>
    return -1;
    80005aa8:	557d                	li	a0,-1
    80005aaa:	bfd1                	j	80005a7e <sys_chdir+0x7a>

0000000080005aac <sys_exec>:

uint64
sys_exec(void)
{
    80005aac:	7145                	addi	sp,sp,-464
    80005aae:	e786                	sd	ra,456(sp)
    80005ab0:	e3a2                	sd	s0,448(sp)
    80005ab2:	ff26                	sd	s1,440(sp)
    80005ab4:	fb4a                	sd	s2,432(sp)
    80005ab6:	f74e                	sd	s3,424(sp)
    80005ab8:	f352                	sd	s4,416(sp)
    80005aba:	ef56                	sd	s5,408(sp)
    80005abc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005abe:	e3840593          	addi	a1,s0,-456
    80005ac2:	4505                	li	a0,1
    80005ac4:	ffffd097          	auipc	ra,0xffffd
    80005ac8:	03a080e7          	jalr	58(ra) # 80002afe <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005acc:	08000613          	li	a2,128
    80005ad0:	f4040593          	addi	a1,s0,-192
    80005ad4:	4501                	li	a0,0
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	048080e7          	jalr	72(ra) # 80002b1e <argstr>
    80005ade:	87aa                	mv	a5,a0
    return -1;
    80005ae0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ae2:	0c07c263          	bltz	a5,80005ba6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ae6:	10000613          	li	a2,256
    80005aea:	4581                	li	a1,0
    80005aec:	e4040513          	addi	a0,s0,-448
    80005af0:	ffffb097          	auipc	ra,0xffffb
    80005af4:	1f6080e7          	jalr	502(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005af8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005afc:	89a6                	mv	s3,s1
    80005afe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b00:	02000a13          	li	s4,32
    80005b04:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b08:	00391513          	slli	a0,s2,0x3
    80005b0c:	e3040593          	addi	a1,s0,-464
    80005b10:	e3843783          	ld	a5,-456(s0)
    80005b14:	953e                	add	a0,a0,a5
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	f2a080e7          	jalr	-214(ra) # 80002a40 <fetchaddr>
    80005b1e:	02054a63          	bltz	a0,80005b52 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b22:	e3043783          	ld	a5,-464(s0)
    80005b26:	c3b9                	beqz	a5,80005b6c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b28:	ffffb097          	auipc	ra,0xffffb
    80005b2c:	fd2080e7          	jalr	-46(ra) # 80000afa <kalloc>
    80005b30:	85aa                	mv	a1,a0
    80005b32:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b36:	cd11                	beqz	a0,80005b52 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b38:	6605                	lui	a2,0x1
    80005b3a:	e3043503          	ld	a0,-464(s0)
    80005b3e:	ffffd097          	auipc	ra,0xffffd
    80005b42:	f54080e7          	jalr	-172(ra) # 80002a92 <fetchstr>
    80005b46:	00054663          	bltz	a0,80005b52 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b4a:	0905                	addi	s2,s2,1
    80005b4c:	09a1                	addi	s3,s3,8
    80005b4e:	fb491be3          	bne	s2,s4,80005b04 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b52:	10048913          	addi	s2,s1,256
    80005b56:	6088                	ld	a0,0(s1)
    80005b58:	c531                	beqz	a0,80005ba4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b5a:	ffffb097          	auipc	ra,0xffffb
    80005b5e:	ea4080e7          	jalr	-348(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b62:	04a1                	addi	s1,s1,8
    80005b64:	ff2499e3          	bne	s1,s2,80005b56 <sys_exec+0xaa>
  return -1;
    80005b68:	557d                	li	a0,-1
    80005b6a:	a835                	j	80005ba6 <sys_exec+0xfa>
      argv[i] = 0;
    80005b6c:	0a8e                	slli	s5,s5,0x3
    80005b6e:	fc040793          	addi	a5,s0,-64
    80005b72:	9abe                	add	s5,s5,a5
    80005b74:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b78:	e4040593          	addi	a1,s0,-448
    80005b7c:	f4040513          	addi	a0,s0,-192
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	190080e7          	jalr	400(ra) # 80004d10 <exec>
    80005b88:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8a:	10048993          	addi	s3,s1,256
    80005b8e:	6088                	ld	a0,0(s1)
    80005b90:	c901                	beqz	a0,80005ba0 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b92:	ffffb097          	auipc	ra,0xffffb
    80005b96:	e6c080e7          	jalr	-404(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9a:	04a1                	addi	s1,s1,8
    80005b9c:	ff3499e3          	bne	s1,s3,80005b8e <sys_exec+0xe2>
  return ret;
    80005ba0:	854a                	mv	a0,s2
    80005ba2:	a011                	j	80005ba6 <sys_exec+0xfa>
  return -1;
    80005ba4:	557d                	li	a0,-1
}
    80005ba6:	60be                	ld	ra,456(sp)
    80005ba8:	641e                	ld	s0,448(sp)
    80005baa:	74fa                	ld	s1,440(sp)
    80005bac:	795a                	ld	s2,432(sp)
    80005bae:	79ba                	ld	s3,424(sp)
    80005bb0:	7a1a                	ld	s4,416(sp)
    80005bb2:	6afa                	ld	s5,408(sp)
    80005bb4:	6179                	addi	sp,sp,464
    80005bb6:	8082                	ret

0000000080005bb8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bb8:	7139                	addi	sp,sp,-64
    80005bba:	fc06                	sd	ra,56(sp)
    80005bbc:	f822                	sd	s0,48(sp)
    80005bbe:	f426                	sd	s1,40(sp)
    80005bc0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bc2:	ffffc097          	auipc	ra,0xffffc
    80005bc6:	e04080e7          	jalr	-508(ra) # 800019c6 <myproc>
    80005bca:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005bcc:	fd840593          	addi	a1,s0,-40
    80005bd0:	4501                	li	a0,0
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	f2c080e7          	jalr	-212(ra) # 80002afe <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bda:	fc840593          	addi	a1,s0,-56
    80005bde:	fd040513          	addi	a0,s0,-48
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	dd6080e7          	jalr	-554(ra) # 800049b8 <pipealloc>
    return -1;
    80005bea:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bec:	0c054463          	bltz	a0,80005cb4 <sys_pipe+0xfc>
  fd0 = -1;
    80005bf0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bf4:	fd043503          	ld	a0,-48(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	518080e7          	jalr	1304(ra) # 80005110 <fdalloc>
    80005c00:	fca42223          	sw	a0,-60(s0)
    80005c04:	08054b63          	bltz	a0,80005c9a <sys_pipe+0xe2>
    80005c08:	fc843503          	ld	a0,-56(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	504080e7          	jalr	1284(ra) # 80005110 <fdalloc>
    80005c14:	fca42023          	sw	a0,-64(s0)
    80005c18:	06054863          	bltz	a0,80005c88 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c1c:	4691                	li	a3,4
    80005c1e:	fc440613          	addi	a2,s0,-60
    80005c22:	fd843583          	ld	a1,-40(s0)
    80005c26:	68a8                	ld	a0,80(s1)
    80005c28:	ffffc097          	auipc	ra,0xffffc
    80005c2c:	a5c080e7          	jalr	-1444(ra) # 80001684 <copyout>
    80005c30:	02054063          	bltz	a0,80005c50 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c34:	4691                	li	a3,4
    80005c36:	fc040613          	addi	a2,s0,-64
    80005c3a:	fd843583          	ld	a1,-40(s0)
    80005c3e:	0591                	addi	a1,a1,4
    80005c40:	68a8                	ld	a0,80(s1)
    80005c42:	ffffc097          	auipc	ra,0xffffc
    80005c46:	a42080e7          	jalr	-1470(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c4a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c4c:	06055463          	bgez	a0,80005cb4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c50:	fc442783          	lw	a5,-60(s0)
    80005c54:	07e9                	addi	a5,a5,26
    80005c56:	078e                	slli	a5,a5,0x3
    80005c58:	97a6                	add	a5,a5,s1
    80005c5a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c5e:	fc042503          	lw	a0,-64(s0)
    80005c62:	0569                	addi	a0,a0,26
    80005c64:	050e                	slli	a0,a0,0x3
    80005c66:	94aa                	add	s1,s1,a0
    80005c68:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c6c:	fd043503          	ld	a0,-48(s0)
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	a18080e7          	jalr	-1512(ra) # 80004688 <fileclose>
    fileclose(wf);
    80005c78:	fc843503          	ld	a0,-56(s0)
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	a0c080e7          	jalr	-1524(ra) # 80004688 <fileclose>
    return -1;
    80005c84:	57fd                	li	a5,-1
    80005c86:	a03d                	j	80005cb4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c88:	fc442783          	lw	a5,-60(s0)
    80005c8c:	0007c763          	bltz	a5,80005c9a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c90:	07e9                	addi	a5,a5,26
    80005c92:	078e                	slli	a5,a5,0x3
    80005c94:	94be                	add	s1,s1,a5
    80005c96:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c9a:	fd043503          	ld	a0,-48(s0)
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	9ea080e7          	jalr	-1558(ra) # 80004688 <fileclose>
    fileclose(wf);
    80005ca6:	fc843503          	ld	a0,-56(s0)
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	9de080e7          	jalr	-1570(ra) # 80004688 <fileclose>
    return -1;
    80005cb2:	57fd                	li	a5,-1
}
    80005cb4:	853e                	mv	a0,a5
    80005cb6:	70e2                	ld	ra,56(sp)
    80005cb8:	7442                	ld	s0,48(sp)
    80005cba:	74a2                	ld	s1,40(sp)
    80005cbc:	6121                	addi	sp,sp,64
    80005cbe:	8082                	ret

0000000080005cc0 <kernelvec>:
    80005cc0:	7111                	addi	sp,sp,-256
    80005cc2:	e006                	sd	ra,0(sp)
    80005cc4:	e40a                	sd	sp,8(sp)
    80005cc6:	e80e                	sd	gp,16(sp)
    80005cc8:	ec12                	sd	tp,24(sp)
    80005cca:	f016                	sd	t0,32(sp)
    80005ccc:	f41a                	sd	t1,40(sp)
    80005cce:	f81e                	sd	t2,48(sp)
    80005cd0:	fc22                	sd	s0,56(sp)
    80005cd2:	e0a6                	sd	s1,64(sp)
    80005cd4:	e4aa                	sd	a0,72(sp)
    80005cd6:	e8ae                	sd	a1,80(sp)
    80005cd8:	ecb2                	sd	a2,88(sp)
    80005cda:	f0b6                	sd	a3,96(sp)
    80005cdc:	f4ba                	sd	a4,104(sp)
    80005cde:	f8be                	sd	a5,112(sp)
    80005ce0:	fcc2                	sd	a6,120(sp)
    80005ce2:	e146                	sd	a7,128(sp)
    80005ce4:	e54a                	sd	s2,136(sp)
    80005ce6:	e94e                	sd	s3,144(sp)
    80005ce8:	ed52                	sd	s4,152(sp)
    80005cea:	f156                	sd	s5,160(sp)
    80005cec:	f55a                	sd	s6,168(sp)
    80005cee:	f95e                	sd	s7,176(sp)
    80005cf0:	fd62                	sd	s8,184(sp)
    80005cf2:	e1e6                	sd	s9,192(sp)
    80005cf4:	e5ea                	sd	s10,200(sp)
    80005cf6:	e9ee                	sd	s11,208(sp)
    80005cf8:	edf2                	sd	t3,216(sp)
    80005cfa:	f1f6                	sd	t4,224(sp)
    80005cfc:	f5fa                	sd	t5,232(sp)
    80005cfe:	f9fe                	sd	t6,240(sp)
    80005d00:	c0dfc0ef          	jal	ra,8000290c <kerneltrap>
    80005d04:	6082                	ld	ra,0(sp)
    80005d06:	6122                	ld	sp,8(sp)
    80005d08:	61c2                	ld	gp,16(sp)
    80005d0a:	7282                	ld	t0,32(sp)
    80005d0c:	7322                	ld	t1,40(sp)
    80005d0e:	73c2                	ld	t2,48(sp)
    80005d10:	7462                	ld	s0,56(sp)
    80005d12:	6486                	ld	s1,64(sp)
    80005d14:	6526                	ld	a0,72(sp)
    80005d16:	65c6                	ld	a1,80(sp)
    80005d18:	6666                	ld	a2,88(sp)
    80005d1a:	7686                	ld	a3,96(sp)
    80005d1c:	7726                	ld	a4,104(sp)
    80005d1e:	77c6                	ld	a5,112(sp)
    80005d20:	7866                	ld	a6,120(sp)
    80005d22:	688a                	ld	a7,128(sp)
    80005d24:	692a                	ld	s2,136(sp)
    80005d26:	69ca                	ld	s3,144(sp)
    80005d28:	6a6a                	ld	s4,152(sp)
    80005d2a:	7a8a                	ld	s5,160(sp)
    80005d2c:	7b2a                	ld	s6,168(sp)
    80005d2e:	7bca                	ld	s7,176(sp)
    80005d30:	7c6a                	ld	s8,184(sp)
    80005d32:	6c8e                	ld	s9,192(sp)
    80005d34:	6d2e                	ld	s10,200(sp)
    80005d36:	6dce                	ld	s11,208(sp)
    80005d38:	6e6e                	ld	t3,216(sp)
    80005d3a:	7e8e                	ld	t4,224(sp)
    80005d3c:	7f2e                	ld	t5,232(sp)
    80005d3e:	7fce                	ld	t6,240(sp)
    80005d40:	6111                	addi	sp,sp,256
    80005d42:	10200073          	sret
    80005d46:	00000013          	nop
    80005d4a:	00000013          	nop
    80005d4e:	0001                	nop

0000000080005d50 <timervec>:
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	e10c                	sd	a1,0(a0)
    80005d56:	e510                	sd	a2,8(a0)
    80005d58:	e914                	sd	a3,16(a0)
    80005d5a:	6d0c                	ld	a1,24(a0)
    80005d5c:	7110                	ld	a2,32(a0)
    80005d5e:	6194                	ld	a3,0(a1)
    80005d60:	96b2                	add	a3,a3,a2
    80005d62:	e194                	sd	a3,0(a1)
    80005d64:	4589                	li	a1,2
    80005d66:	14459073          	csrw	sip,a1
    80005d6a:	6914                	ld	a3,16(a0)
    80005d6c:	6510                	ld	a2,8(a0)
    80005d6e:	610c                	ld	a1,0(a0)
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	30200073          	mret
	...

0000000080005d7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d7a:	1141                	addi	sp,sp,-16
    80005d7c:	e422                	sd	s0,8(sp)
    80005d7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d80:	0c0007b7          	lui	a5,0xc000
    80005d84:	4705                	li	a4,1
    80005d86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d88:	c3d8                	sw	a4,4(a5)
}
    80005d8a:	6422                	ld	s0,8(sp)
    80005d8c:	0141                	addi	sp,sp,16
    80005d8e:	8082                	ret

0000000080005d90 <plicinithart>:

void
plicinithart(void)
{
    80005d90:	1141                	addi	sp,sp,-16
    80005d92:	e406                	sd	ra,8(sp)
    80005d94:	e022                	sd	s0,0(sp)
    80005d96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	c02080e7          	jalr	-1022(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005da0:	0085171b          	slliw	a4,a0,0x8
    80005da4:	0c0027b7          	lui	a5,0xc002
    80005da8:	97ba                	add	a5,a5,a4
    80005daa:	40200713          	li	a4,1026
    80005dae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005db2:	00d5151b          	slliw	a0,a0,0xd
    80005db6:	0c2017b7          	lui	a5,0xc201
    80005dba:	953e                	add	a0,a0,a5
    80005dbc:	00052023          	sw	zero,0(a0)
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret

0000000080005dc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dc8:	1141                	addi	sp,sp,-16
    80005dca:	e406                	sd	ra,8(sp)
    80005dcc:	e022                	sd	s0,0(sp)
    80005dce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	bca080e7          	jalr	-1078(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dd8:	00d5179b          	slliw	a5,a0,0xd
    80005ddc:	0c201537          	lui	a0,0xc201
    80005de0:	953e                	add	a0,a0,a5
  return irq;
}
    80005de2:	4148                	lw	a0,4(a0)
    80005de4:	60a2                	ld	ra,8(sp)
    80005de6:	6402                	ld	s0,0(sp)
    80005de8:	0141                	addi	sp,sp,16
    80005dea:	8082                	ret

0000000080005dec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dec:	1101                	addi	sp,sp,-32
    80005dee:	ec06                	sd	ra,24(sp)
    80005df0:	e822                	sd	s0,16(sp)
    80005df2:	e426                	sd	s1,8(sp)
    80005df4:	1000                	addi	s0,sp,32
    80005df6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	ba2080e7          	jalr	-1118(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e00:	00d5151b          	slliw	a0,a0,0xd
    80005e04:	0c2017b7          	lui	a5,0xc201
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	c3c4                	sw	s1,4(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret

0000000080005e16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e16:	1141                	addi	sp,sp,-16
    80005e18:	e406                	sd	ra,8(sp)
    80005e1a:	e022                	sd	s0,0(sp)
    80005e1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e1e:	479d                	li	a5,7
    80005e20:	04a7cc63          	blt	a5,a0,80005e78 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e24:	0001c797          	auipc	a5,0x1c
    80005e28:	fdc78793          	addi	a5,a5,-36 # 80021e00 <disk>
    80005e2c:	97aa                	add	a5,a5,a0
    80005e2e:	0187c783          	lbu	a5,24(a5)
    80005e32:	ebb9                	bnez	a5,80005e88 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e34:	00451613          	slli	a2,a0,0x4
    80005e38:	0001c797          	auipc	a5,0x1c
    80005e3c:	fc878793          	addi	a5,a5,-56 # 80021e00 <disk>
    80005e40:	6394                	ld	a3,0(a5)
    80005e42:	96b2                	add	a3,a3,a2
    80005e44:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e48:	6398                	ld	a4,0(a5)
    80005e4a:	9732                	add	a4,a4,a2
    80005e4c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e50:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e54:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e58:	953e                	add	a0,a0,a5
    80005e5a:	4785                	li	a5,1
    80005e5c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e60:	0001c517          	auipc	a0,0x1c
    80005e64:	fb850513          	addi	a0,a0,-72 # 80021e18 <disk+0x18>
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	26e080e7          	jalr	622(ra) # 800020d6 <wakeup>
}
    80005e70:	60a2                	ld	ra,8(sp)
    80005e72:	6402                	ld	s0,0(sp)
    80005e74:	0141                	addi	sp,sp,16
    80005e76:	8082                	ret
    panic("free_desc 1");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	ac050513          	addi	a0,a0,-1344 # 80008938 <sysargs+0x298>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6c4080e7          	jalr	1732(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	ac050513          	addi	a0,a0,-1344 # 80008948 <sysargs+0x2a8>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	6b4080e7          	jalr	1716(ra) # 80000544 <panic>

0000000080005e98 <virtio_disk_init>:
{
    80005e98:	1101                	addi	sp,sp,-32
    80005e9a:	ec06                	sd	ra,24(sp)
    80005e9c:	e822                	sd	s0,16(sp)
    80005e9e:	e426                	sd	s1,8(sp)
    80005ea0:	e04a                	sd	s2,0(sp)
    80005ea2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ea4:	00003597          	auipc	a1,0x3
    80005ea8:	ab458593          	addi	a1,a1,-1356 # 80008958 <sysargs+0x2b8>
    80005eac:	0001c517          	auipc	a0,0x1c
    80005eb0:	07c50513          	addi	a0,a0,124 # 80021f28 <disk+0x128>
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	ca6080e7          	jalr	-858(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ebc:	100017b7          	lui	a5,0x10001
    80005ec0:	4398                	lw	a4,0(a5)
    80005ec2:	2701                	sext.w	a4,a4
    80005ec4:	747277b7          	lui	a5,0x74727
    80005ec8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ecc:	14f71e63          	bne	a4,a5,80006028 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ed0:	100017b7          	lui	a5,0x10001
    80005ed4:	43dc                	lw	a5,4(a5)
    80005ed6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ed8:	4709                	li	a4,2
    80005eda:	14e79763          	bne	a5,a4,80006028 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	479c                	lw	a5,8(a5)
    80005ee4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ee6:	14e79163          	bne	a5,a4,80006028 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eea:	100017b7          	lui	a5,0x10001
    80005eee:	47d8                	lw	a4,12(a5)
    80005ef0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ef2:	554d47b7          	lui	a5,0x554d4
    80005ef6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005efa:	12f71763          	bne	a4,a5,80006028 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f06:	4705                	li	a4,1
    80005f08:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0a:	470d                	li	a4,3
    80005f0c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f0e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f10:	c7ffe737          	lui	a4,0xc7ffe
    80005f14:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc81f>
    80005f18:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f1a:	2701                	sext.w	a4,a4
    80005f1c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1e:	472d                	li	a4,11
    80005f20:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f22:	0707a903          	lw	s2,112(a5)
    80005f26:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f28:	00897793          	andi	a5,s2,8
    80005f2c:	10078663          	beqz	a5,80006038 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f30:	100017b7          	lui	a5,0x10001
    80005f34:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f38:	43fc                	lw	a5,68(a5)
    80005f3a:	2781                	sext.w	a5,a5
    80005f3c:	10079663          	bnez	a5,80006048 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f40:	100017b7          	lui	a5,0x10001
    80005f44:	5bdc                	lw	a5,52(a5)
    80005f46:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f48:	10078863          	beqz	a5,80006058 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f4c:	471d                	li	a4,7
    80005f4e:	10f77d63          	bgeu	a4,a5,80006068 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f52:	ffffb097          	auipc	ra,0xffffb
    80005f56:	ba8080e7          	jalr	-1112(ra) # 80000afa <kalloc>
    80005f5a:	0001c497          	auipc	s1,0x1c
    80005f5e:	ea648493          	addi	s1,s1,-346 # 80021e00 <disk>
    80005f62:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	b96080e7          	jalr	-1130(ra) # 80000afa <kalloc>
    80005f6c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	b8c080e7          	jalr	-1140(ra) # 80000afa <kalloc>
    80005f76:	87aa                	mv	a5,a0
    80005f78:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f7a:	6088                	ld	a0,0(s1)
    80005f7c:	cd75                	beqz	a0,80006078 <virtio_disk_init+0x1e0>
    80005f7e:	0001c717          	auipc	a4,0x1c
    80005f82:	e8a73703          	ld	a4,-374(a4) # 80021e08 <disk+0x8>
    80005f86:	cb6d                	beqz	a4,80006078 <virtio_disk_init+0x1e0>
    80005f88:	cbe5                	beqz	a5,80006078 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f8a:	6605                	lui	a2,0x1
    80005f8c:	4581                	li	a1,0
    80005f8e:	ffffb097          	auipc	ra,0xffffb
    80005f92:	d58080e7          	jalr	-680(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f96:	0001c497          	auipc	s1,0x1c
    80005f9a:	e6a48493          	addi	s1,s1,-406 # 80021e00 <disk>
    80005f9e:	6605                	lui	a2,0x1
    80005fa0:	4581                	li	a1,0
    80005fa2:	6488                	ld	a0,8(s1)
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	d42080e7          	jalr	-702(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005fac:	6605                	lui	a2,0x1
    80005fae:	4581                	li	a1,0
    80005fb0:	6888                	ld	a0,16(s1)
    80005fb2:	ffffb097          	auipc	ra,0xffffb
    80005fb6:	d34080e7          	jalr	-716(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	4721                	li	a4,8
    80005fc0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fc2:	4098                	lw	a4,0(s1)
    80005fc4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fc8:	40d8                	lw	a4,4(s1)
    80005fca:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fce:	6498                	ld	a4,8(s1)
    80005fd0:	0007069b          	sext.w	a3,a4
    80005fd4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fd8:	9701                	srai	a4,a4,0x20
    80005fda:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fde:	6898                	ld	a4,16(s1)
    80005fe0:	0007069b          	sext.w	a3,a4
    80005fe4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fe8:	9701                	srai	a4,a4,0x20
    80005fea:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fee:	4685                	li	a3,1
    80005ff0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005ff2:	4705                	li	a4,1
    80005ff4:	00d48c23          	sb	a3,24(s1)
    80005ff8:	00e48ca3          	sb	a4,25(s1)
    80005ffc:	00e48d23          	sb	a4,26(s1)
    80006000:	00e48da3          	sb	a4,27(s1)
    80006004:	00e48e23          	sb	a4,28(s1)
    80006008:	00e48ea3          	sb	a4,29(s1)
    8000600c:	00e48f23          	sb	a4,30(s1)
    80006010:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006014:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006018:	0727a823          	sw	s2,112(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6902                	ld	s2,0(sp)
    80006024:	6105                	addi	sp,sp,32
    80006026:	8082                	ret
    panic("could not find virtio disk");
    80006028:	00003517          	auipc	a0,0x3
    8000602c:	94050513          	addi	a0,a0,-1728 # 80008968 <sysargs+0x2c8>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006038:	00003517          	auipc	a0,0x3
    8000603c:	95050513          	addi	a0,a0,-1712 # 80008988 <sysargs+0x2e8>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006048:	00003517          	auipc	a0,0x3
    8000604c:	96050513          	addi	a0,a0,-1696 # 800089a8 <sysargs+0x308>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006058:	00003517          	auipc	a0,0x3
    8000605c:	97050513          	addi	a0,a0,-1680 # 800089c8 <sysargs+0x328>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006068:	00003517          	auipc	a0,0x3
    8000606c:	98050513          	addi	a0,a0,-1664 # 800089e8 <sysargs+0x348>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4d4080e7          	jalr	1236(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006078:	00003517          	auipc	a0,0x3
    8000607c:	99050513          	addi	a0,a0,-1648 # 80008a08 <sysargs+0x368>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4c4080e7          	jalr	1220(ra) # 80000544 <panic>

0000000080006088 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006088:	7159                	addi	sp,sp,-112
    8000608a:	f486                	sd	ra,104(sp)
    8000608c:	f0a2                	sd	s0,96(sp)
    8000608e:	eca6                	sd	s1,88(sp)
    80006090:	e8ca                	sd	s2,80(sp)
    80006092:	e4ce                	sd	s3,72(sp)
    80006094:	e0d2                	sd	s4,64(sp)
    80006096:	fc56                	sd	s5,56(sp)
    80006098:	f85a                	sd	s6,48(sp)
    8000609a:	f45e                	sd	s7,40(sp)
    8000609c:	f062                	sd	s8,32(sp)
    8000609e:	ec66                	sd	s9,24(sp)
    800060a0:	e86a                	sd	s10,16(sp)
    800060a2:	1880                	addi	s0,sp,112
    800060a4:	892a                	mv	s2,a0
    800060a6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060a8:	00c52c83          	lw	s9,12(a0)
    800060ac:	001c9c9b          	slliw	s9,s9,0x1
    800060b0:	1c82                	slli	s9,s9,0x20
    800060b2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060b6:	0001c517          	auipc	a0,0x1c
    800060ba:	e7250513          	addi	a0,a0,-398 # 80021f28 <disk+0x128>
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	b2c080e7          	jalr	-1236(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800060c6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060c8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800060ca:	0001cb17          	auipc	s6,0x1c
    800060ce:	d36b0b13          	addi	s6,s6,-714 # 80021e00 <disk>
  for(int i = 0; i < 3; i++){
    800060d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060d4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060d6:	0001cc17          	auipc	s8,0x1c
    800060da:	e52c0c13          	addi	s8,s8,-430 # 80021f28 <disk+0x128>
    800060de:	a8b5                	j	8000615a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800060e0:	00fb06b3          	add	a3,s6,a5
    800060e4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060e8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060ea:	0207c563          	bltz	a5,80006114 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060ee:	2485                	addiw	s1,s1,1
    800060f0:	0711                	addi	a4,a4,4
    800060f2:	1f548a63          	beq	s1,s5,800062e6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800060f6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060f8:	0001c697          	auipc	a3,0x1c
    800060fc:	d0868693          	addi	a3,a3,-760 # 80021e00 <disk>
    80006100:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006102:	0186c583          	lbu	a1,24(a3)
    80006106:	fde9                	bnez	a1,800060e0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006108:	2785                	addiw	a5,a5,1
    8000610a:	0685                	addi	a3,a3,1
    8000610c:	ff779be3          	bne	a5,s7,80006102 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006110:	57fd                	li	a5,-1
    80006112:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006114:	02905a63          	blez	s1,80006148 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006118:	f9042503          	lw	a0,-112(s0)
    8000611c:	00000097          	auipc	ra,0x0
    80006120:	cfa080e7          	jalr	-774(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006124:	4785                	li	a5,1
    80006126:	0297d163          	bge	a5,s1,80006148 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000612a:	f9442503          	lw	a0,-108(s0)
    8000612e:	00000097          	auipc	ra,0x0
    80006132:	ce8080e7          	jalr	-792(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006136:	4789                	li	a5,2
    80006138:	0097d863          	bge	a5,s1,80006148 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000613c:	f9842503          	lw	a0,-104(s0)
    80006140:	00000097          	auipc	ra,0x0
    80006144:	cd6080e7          	jalr	-810(ra) # 80005e16 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006148:	85e2                	mv	a1,s8
    8000614a:	0001c517          	auipc	a0,0x1c
    8000614e:	cce50513          	addi	a0,a0,-818 # 80021e18 <disk+0x18>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	f20080e7          	jalr	-224(ra) # 80002072 <sleep>
  for(int i = 0; i < 3; i++){
    8000615a:	f9040713          	addi	a4,s0,-112
    8000615e:	84ce                	mv	s1,s3
    80006160:	bf59                	j	800060f6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006162:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006166:	00479693          	slli	a3,a5,0x4
    8000616a:	0001c797          	auipc	a5,0x1c
    8000616e:	c9678793          	addi	a5,a5,-874 # 80021e00 <disk>
    80006172:	97b6                	add	a5,a5,a3
    80006174:	4685                	li	a3,1
    80006176:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006178:	0001c597          	auipc	a1,0x1c
    8000617c:	c8858593          	addi	a1,a1,-888 # 80021e00 <disk>
    80006180:	00a60793          	addi	a5,a2,10
    80006184:	0792                	slli	a5,a5,0x4
    80006186:	97ae                	add	a5,a5,a1
    80006188:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000618c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006190:	f6070693          	addi	a3,a4,-160
    80006194:	619c                	ld	a5,0(a1)
    80006196:	97b6                	add	a5,a5,a3
    80006198:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000619a:	6188                	ld	a0,0(a1)
    8000619c:	96aa                	add	a3,a3,a0
    8000619e:	47c1                	li	a5,16
    800061a0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061a2:	4785                	li	a5,1
    800061a4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800061a8:	f9442783          	lw	a5,-108(s0)
    800061ac:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061b0:	0792                	slli	a5,a5,0x4
    800061b2:	953e                	add	a0,a0,a5
    800061b4:	05890693          	addi	a3,s2,88
    800061b8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800061ba:	6188                	ld	a0,0(a1)
    800061bc:	97aa                	add	a5,a5,a0
    800061be:	40000693          	li	a3,1024
    800061c2:	c794                	sw	a3,8(a5)
  if(write)
    800061c4:	100d0d63          	beqz	s10,800062de <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061cc:	00c7d683          	lhu	a3,12(a5)
    800061d0:	0016e693          	ori	a3,a3,1
    800061d4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800061d8:	f9842583          	lw	a1,-104(s0)
    800061dc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061e0:	0001c697          	auipc	a3,0x1c
    800061e4:	c2068693          	addi	a3,a3,-992 # 80021e00 <disk>
    800061e8:	00260793          	addi	a5,a2,2
    800061ec:	0792                	slli	a5,a5,0x4
    800061ee:	97b6                	add	a5,a5,a3
    800061f0:	587d                	li	a6,-1
    800061f2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061f6:	0592                	slli	a1,a1,0x4
    800061f8:	952e                	add	a0,a0,a1
    800061fa:	f9070713          	addi	a4,a4,-112
    800061fe:	9736                	add	a4,a4,a3
    80006200:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006202:	6298                	ld	a4,0(a3)
    80006204:	972e                	add	a4,a4,a1
    80006206:	4585                	li	a1,1
    80006208:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000620a:	4509                	li	a0,2
    8000620c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006210:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006214:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006218:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000621c:	6698                	ld	a4,8(a3)
    8000621e:	00275783          	lhu	a5,2(a4)
    80006222:	8b9d                	andi	a5,a5,7
    80006224:	0786                	slli	a5,a5,0x1
    80006226:	97ba                	add	a5,a5,a4
    80006228:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000622c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006230:	6698                	ld	a4,8(a3)
    80006232:	00275783          	lhu	a5,2(a4)
    80006236:	2785                	addiw	a5,a5,1
    80006238:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000623c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006240:	100017b7          	lui	a5,0x10001
    80006244:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006248:	00492703          	lw	a4,4(s2)
    8000624c:	4785                	li	a5,1
    8000624e:	02f71163          	bne	a4,a5,80006270 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006252:	0001c997          	auipc	s3,0x1c
    80006256:	cd698993          	addi	s3,s3,-810 # 80021f28 <disk+0x128>
  while(b->disk == 1) {
    8000625a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000625c:	85ce                	mv	a1,s3
    8000625e:	854a                	mv	a0,s2
    80006260:	ffffc097          	auipc	ra,0xffffc
    80006264:	e12080e7          	jalr	-494(ra) # 80002072 <sleep>
  while(b->disk == 1) {
    80006268:	00492783          	lw	a5,4(s2)
    8000626c:	fe9788e3          	beq	a5,s1,8000625c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006270:	f9042903          	lw	s2,-112(s0)
    80006274:	00290793          	addi	a5,s2,2
    80006278:	00479713          	slli	a4,a5,0x4
    8000627c:	0001c797          	auipc	a5,0x1c
    80006280:	b8478793          	addi	a5,a5,-1148 # 80021e00 <disk>
    80006284:	97ba                	add	a5,a5,a4
    80006286:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000628a:	0001c997          	auipc	s3,0x1c
    8000628e:	b7698993          	addi	s3,s3,-1162 # 80021e00 <disk>
    80006292:	00491713          	slli	a4,s2,0x4
    80006296:	0009b783          	ld	a5,0(s3)
    8000629a:	97ba                	add	a5,a5,a4
    8000629c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062a0:	854a                	mv	a0,s2
    800062a2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062a6:	00000097          	auipc	ra,0x0
    800062aa:	b70080e7          	jalr	-1168(ra) # 80005e16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ae:	8885                	andi	s1,s1,1
    800062b0:	f0ed                	bnez	s1,80006292 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062b2:	0001c517          	auipc	a0,0x1c
    800062b6:	c7650513          	addi	a0,a0,-906 # 80021f28 <disk+0x128>
    800062ba:	ffffb097          	auipc	ra,0xffffb
    800062be:	9e4080e7          	jalr	-1564(ra) # 80000c9e <release>
}
    800062c2:	70a6                	ld	ra,104(sp)
    800062c4:	7406                	ld	s0,96(sp)
    800062c6:	64e6                	ld	s1,88(sp)
    800062c8:	6946                	ld	s2,80(sp)
    800062ca:	69a6                	ld	s3,72(sp)
    800062cc:	6a06                	ld	s4,64(sp)
    800062ce:	7ae2                	ld	s5,56(sp)
    800062d0:	7b42                	ld	s6,48(sp)
    800062d2:	7ba2                	ld	s7,40(sp)
    800062d4:	7c02                	ld	s8,32(sp)
    800062d6:	6ce2                	ld	s9,24(sp)
    800062d8:	6d42                	ld	s10,16(sp)
    800062da:	6165                	addi	sp,sp,112
    800062dc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062de:	4689                	li	a3,2
    800062e0:	00d79623          	sh	a3,12(a5)
    800062e4:	b5e5                	j	800061cc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062e6:	f9042603          	lw	a2,-112(s0)
    800062ea:	00a60713          	addi	a4,a2,10
    800062ee:	0712                	slli	a4,a4,0x4
    800062f0:	0001c517          	auipc	a0,0x1c
    800062f4:	b1850513          	addi	a0,a0,-1256 # 80021e08 <disk+0x8>
    800062f8:	953a                	add	a0,a0,a4
  if(write)
    800062fa:	e60d14e3          	bnez	s10,80006162 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062fe:	00a60793          	addi	a5,a2,10
    80006302:	00479693          	slli	a3,a5,0x4
    80006306:	0001c797          	auipc	a5,0x1c
    8000630a:	afa78793          	addi	a5,a5,-1286 # 80021e00 <disk>
    8000630e:	97b6                	add	a5,a5,a3
    80006310:	0007a423          	sw	zero,8(a5)
    80006314:	b595                	j	80006178 <virtio_disk_rw+0xf0>

0000000080006316 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006316:	1101                	addi	sp,sp,-32
    80006318:	ec06                	sd	ra,24(sp)
    8000631a:	e822                	sd	s0,16(sp)
    8000631c:	e426                	sd	s1,8(sp)
    8000631e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006320:	0001c497          	auipc	s1,0x1c
    80006324:	ae048493          	addi	s1,s1,-1312 # 80021e00 <disk>
    80006328:	0001c517          	auipc	a0,0x1c
    8000632c:	c0050513          	addi	a0,a0,-1024 # 80021f28 <disk+0x128>
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	8ba080e7          	jalr	-1862(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006338:	10001737          	lui	a4,0x10001
    8000633c:	533c                	lw	a5,96(a4)
    8000633e:	8b8d                	andi	a5,a5,3
    80006340:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006342:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006346:	689c                	ld	a5,16(s1)
    80006348:	0204d703          	lhu	a4,32(s1)
    8000634c:	0027d783          	lhu	a5,2(a5)
    80006350:	04f70863          	beq	a4,a5,800063a0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006354:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006358:	6898                	ld	a4,16(s1)
    8000635a:	0204d783          	lhu	a5,32(s1)
    8000635e:	8b9d                	andi	a5,a5,7
    80006360:	078e                	slli	a5,a5,0x3
    80006362:	97ba                	add	a5,a5,a4
    80006364:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006366:	00278713          	addi	a4,a5,2
    8000636a:	0712                	slli	a4,a4,0x4
    8000636c:	9726                	add	a4,a4,s1
    8000636e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006372:	e721                	bnez	a4,800063ba <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006374:	0789                	addi	a5,a5,2
    80006376:	0792                	slli	a5,a5,0x4
    80006378:	97a6                	add	a5,a5,s1
    8000637a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000637c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006380:	ffffc097          	auipc	ra,0xffffc
    80006384:	d56080e7          	jalr	-682(ra) # 800020d6 <wakeup>

    disk.used_idx += 1;
    80006388:	0204d783          	lhu	a5,32(s1)
    8000638c:	2785                	addiw	a5,a5,1
    8000638e:	17c2                	slli	a5,a5,0x30
    80006390:	93c1                	srli	a5,a5,0x30
    80006392:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006396:	6898                	ld	a4,16(s1)
    80006398:	00275703          	lhu	a4,2(a4)
    8000639c:	faf71ce3          	bne	a4,a5,80006354 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063a0:	0001c517          	auipc	a0,0x1c
    800063a4:	b8850513          	addi	a0,a0,-1144 # 80021f28 <disk+0x128>
    800063a8:	ffffb097          	auipc	ra,0xffffb
    800063ac:	8f6080e7          	jalr	-1802(ra) # 80000c9e <release>
}
    800063b0:	60e2                	ld	ra,24(sp)
    800063b2:	6442                	ld	s0,16(sp)
    800063b4:	64a2                	ld	s1,8(sp)
    800063b6:	6105                	addi	sp,sp,32
    800063b8:	8082                	ret
      panic("virtio_disk_intr status");
    800063ba:	00002517          	auipc	a0,0x2
    800063be:	66650513          	addi	a0,a0,1638 # 80008a20 <sysargs+0x380>
    800063c2:	ffffa097          	auipc	ra,0xffffa
    800063c6:	182080e7          	jalr	386(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
