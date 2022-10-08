
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c5010113          	addi	sp,sp,-944 # 80008c50 <stack0>
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
    80000056:	abe70713          	addi	a4,a4,-1346 # 80008b10 <timer_scratch>
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
    80000068:	e4c78793          	addi	a5,a5,-436 # 80005eb0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc07f>
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
    80000130:	3bc080e7          	jalr	956(ra) # 800024e8 <either_copyin>
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
    80000190:	ac450513          	addi	a0,a0,-1340 # 80010c50 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ab448493          	addi	s1,s1,-1356 # 80010c50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b4290913          	addi	s2,s2,-1214 # 80010ce8 <cons+0x98>
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
    800001d0:	166080e7          	jalr	358(ra) # 80002332 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	eb0080e7          	jalr	-336(ra) # 8000208a <sleep>
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
    8000021a:	27c080e7          	jalr	636(ra) # 80002492 <either_copyout>
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
    8000022e:	a2650513          	addi	a0,a0,-1498 # 80010c50 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a1050513          	addi	a0,a0,-1520 # 80010c50 <cons>
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
    8000027c:	a6f72823          	sw	a5,-1424(a4) # 80010ce8 <cons+0x98>
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
    800002d6:	97e50513          	addi	a0,a0,-1666 # 80010c50 <cons>
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
    800002fc:	246080e7          	jalr	582(ra) # 8000253e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	95050513          	addi	a0,a0,-1712 # 80010c50 <cons>
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
    80000328:	92c70713          	addi	a4,a4,-1748 # 80010c50 <cons>
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
    80000352:	90278793          	addi	a5,a5,-1790 # 80010c50 <cons>
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
    80000380:	96c7a783          	lw	a5,-1684(a5) # 80010ce8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	8c070713          	addi	a4,a4,-1856 # 80010c50 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	8b048493          	addi	s1,s1,-1872 # 80010c50 <cons>
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
    800003e0:	87470713          	addi	a4,a4,-1932 # 80010c50 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	8ef72f23          	sw	a5,-1794(a4) # 80010cf0 <cons+0xa0>
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
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	83878793          	addi	a5,a5,-1992 # 80010c50 <cons>
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
    80000440:	8ac7a823          	sw	a2,-1872(a5) # 80010cec <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	8a450513          	addi	a0,a0,-1884 # 80010ce8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	ca2080e7          	jalr	-862(ra) # 800020ee <wakeup>
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
    8000046a:	7ea50513          	addi	a0,a0,2026 # 80010c50 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	16a78793          	addi	a5,a5,362 # 800215e8 <devsw>
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
    80000554:	7c07a023          	sw	zero,1984(a5) # 80010d10 <pr+0x18>
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
    80000588:	54f72623          	sw	a5,1356(a4) # 80008ad0 <panicked>
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
    800005c4:	750dad83          	lw	s11,1872(s11) # 80010d10 <pr+0x18>
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
    80000602:	6fa50513          	addi	a0,a0,1786 # 80010cf8 <pr>
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
    80000766:	59650513          	addi	a0,a0,1430 # 80010cf8 <pr>
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
    80000782:	57a48493          	addi	s1,s1,1402 # 80010cf8 <pr>
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
    800007e2:	53a50513          	addi	a0,a0,1338 # 80010d18 <uart_tx_lock>
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
    8000080e:	2c67a783          	lw	a5,710(a5) # 80008ad0 <panicked>
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
    8000084a:	29273703          	ld	a4,658(a4) # 80008ad8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2927b783          	ld	a5,658(a5) # 80008ae0 <uart_tx_w>
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
    80000874:	4a8a0a13          	addi	s4,s4,1192 # 80010d18 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	26048493          	addi	s1,s1,608 # 80008ad8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	26098993          	addi	s3,s3,608 # 80008ae0 <uart_tx_w>
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
    800008aa:	848080e7          	jalr	-1976(ra) # 800020ee <wakeup>
    
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
    800008e6:	43650513          	addi	a0,a0,1078 # 80010d18 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1de7a783          	lw	a5,478(a5) # 80008ad0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1e47b783          	ld	a5,484(a5) # 80008ae0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	1d473703          	ld	a4,468(a4) # 80008ad8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	408a0a13          	addi	s4,s4,1032 # 80010d18 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	1c048493          	addi	s1,s1,448 # 80008ad8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	1c090913          	addi	s2,s2,448 # 80008ae0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	75a080e7          	jalr	1882(ra) # 8000208a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	3d248493          	addi	s1,s1,978 # 80010d18 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	18f73323          	sd	a5,390(a4) # 80008ae0 <uart_tx_w>
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
    800009d4:	34848493          	addi	s1,s1,840 # 80010d18 <uart_tx_lock>
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
    80000a12:	00022797          	auipc	a5,0x22
    80000a16:	d6e78793          	addi	a5,a5,-658 # 80022780 <end>
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
    80000a36:	31e90913          	addi	s2,s2,798 # 80010d50 <kmem>
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
    80000ad2:	28250513          	addi	a0,a0,642 # 80010d50 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00022517          	auipc	a0,0x22
    80000ae6:	c9e50513          	addi	a0,a0,-866 # 80022780 <end>
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
    80000b08:	24c48493          	addi	s1,s1,588 # 80010d50 <kmem>
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
    80000b20:	23450513          	addi	a0,a0,564 # 80010d50 <kmem>
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
    80000b4c:	20850513          	addi	a0,a0,520 # 80010d50 <kmem>
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
    80000ea8:	c4470713          	addi	a4,a4,-956 # 80008ae8 <started>
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
    80000ede:	7a4080e7          	jalr	1956(ra) # 8000267e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	00e080e7          	jalr	14(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fee080e7          	jalr	-18(ra) # 80001ed8 <scheduler>
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
    80000f56:	704080e7          	jalr	1796(ra) # 80002656 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	724080e7          	jalr	1828(ra) # 8000267e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f78080e7          	jalr	-136(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	f86080e7          	jalr	-122(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	132080e7          	jalr	306(ra) # 800030a4 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	7d6080e7          	jalr	2006(ra) # 80003750 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	774080e7          	jalr	1908(ra) # 800046f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	06e080e7          	jalr	110(ra) # 80005ff8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d2c080e7          	jalr	-724(ra) # 80001cbe <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b4f72423          	sw	a5,-1208(a4) # 80008ae8 <started>
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
    80000fb8:	b3c7b783          	ld	a5,-1220(a5) # 80008af0 <kernel_pagetable>
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
    80001274:	88a7b023          	sd	a0,-1920(a5) # 80008af0 <kernel_pagetable>
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
    8000186a:	93a48493          	addi	s1,s1,-1734 # 800111a0 <proc>
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
    80001880:	00016a17          	auipc	s4,0x16
    80001884:	b20a0a13          	addi	s4,s4,-1248 # 800173a0 <tickslock>
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
    800018ba:	18848493          	addi	s1,s1,392
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
    80001906:	46e50513          	addi	a0,a0,1134 # 80010d70 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	46e50513          	addi	a0,a0,1134 # 80010d88 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	87648493          	addi	s1,s1,-1930 # 800111a0 <proc>
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
    8000194c:	00016997          	auipc	s3,0x16
    80001950:	a5498993          	addi	s3,s3,-1452 # 800173a0 <tickslock>
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
    8000197e:	18848493          	addi	s1,s1,392
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
    800019ba:	3ea50513          	addi	a0,a0,1002 # 80010da0 <cpus>
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
    800019e2:	39270713          	addi	a4,a4,914 # 80010d70 <pid_lock>
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
    80001a1a:	06a7a783          	lw	a5,106(a5) # 80008a80 <first.1684>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	c76080e7          	jalr	-906(ra) # 80002696 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	0407a823          	sw	zero,80(a5) # 80008a80 <first.1684>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	c96080e7          	jalr	-874(ra) # 800036d0 <fsinit>
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
    80001a54:	32090913          	addi	s2,s2,800 # 80010d70 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	02278793          	addi	a5,a5,34 # 80008a84 <nextpid>
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
    80001bae:	1604a423          	sw	zero,360(s1)
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
  p->nticks = 0;
    80001bc6:	1604a623          	sw	zero,364(s1)
  p->ticklim = 0;
    80001bca:	1604aa23          	sw	zero,372(s1)
  p->alarm_lock = 0;
    80001bce:	1604a823          	sw	zero,368(s1)
  p->state = UNUSED;
    80001bd2:	0004ac23          	sw	zero,24(s1)
}
    80001bd6:	60e2                	ld	ra,24(sp)
    80001bd8:	6442                	ld	s0,16(sp)
    80001bda:	64a2                	ld	s1,8(sp)
    80001bdc:	6105                	addi	sp,sp,32
    80001bde:	8082                	ret

0000000080001be0 <allocproc>:
{
    80001be0:	1101                	addi	sp,sp,-32
    80001be2:	ec06                	sd	ra,24(sp)
    80001be4:	e822                	sd	s0,16(sp)
    80001be6:	e426                	sd	s1,8(sp)
    80001be8:	e04a                	sd	s2,0(sp)
    80001bea:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bec:	0000f497          	auipc	s1,0xf
    80001bf0:	5b448493          	addi	s1,s1,1460 # 800111a0 <proc>
    80001bf4:	00015917          	auipc	s2,0x15
    80001bf8:	7ac90913          	addi	s2,s2,1964 # 800173a0 <tickslock>
    acquire(&p->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	fec080e7          	jalr	-20(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001c06:	4c9c                	lw	a5,24(s1)
    80001c08:	cf81                	beqz	a5,80001c20 <allocproc+0x40>
      release(&p->lock);
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	092080e7          	jalr	146(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c14:	18848493          	addi	s1,s1,392
    80001c18:	ff2492e3          	bne	s1,s2,80001bfc <allocproc+0x1c>
  return 0;
    80001c1c:	4481                	li	s1,0
    80001c1e:	a08d                	j	80001c80 <allocproc+0xa0>
  p->pid = allocpid();
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e24080e7          	jalr	-476(ra) # 80001a44 <allocpid>
    80001c28:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c2a:	4785                	li	a5,1
    80001c2c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	ecc080e7          	jalr	-308(ra) # 80000afa <kalloc>
    80001c36:	892a                	mv	s2,a0
    80001c38:	eca8                	sd	a0,88(s1)
    80001c3a:	c931                	beqz	a0,80001c8e <allocproc+0xae>
  p->pagetable = proc_pagetable(p);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	e4c080e7          	jalr	-436(ra) # 80001a8a <proc_pagetable>
    80001c46:	892a                	mv	s2,a0
    80001c48:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c4a:	cd31                	beqz	a0,80001ca6 <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001c4c:	07000613          	li	a2,112
    80001c50:	4581                	li	a1,0
    80001c52:	06048513          	addi	a0,s1,96
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	090080e7          	jalr	144(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c5e:	00000797          	auipc	a5,0x0
    80001c62:	da078793          	addi	a5,a5,-608 # 800019fe <forkret>
    80001c66:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c68:	60bc                	ld	a5,64(s1)
    80001c6a:	6705                	lui	a4,0x1
    80001c6c:	97ba                	add	a5,a5,a4
    80001c6e:	f4bc                	sd	a5,104(s1)
  p->trac_stat = 0;
    80001c70:	1604a423          	sw	zero,360(s1)
  p->nticks = 0;
    80001c74:	1604a623          	sw	zero,364(s1)
  p->ticklim = 0;
    80001c78:	1604aa23          	sw	zero,372(s1)
  p->alarm_lock = 0;
    80001c7c:	1604a823          	sw	zero,368(s1)
}
    80001c80:	8526                	mv	a0,s1
    80001c82:	60e2                	ld	ra,24(sp)
    80001c84:	6442                	ld	s0,16(sp)
    80001c86:	64a2                	ld	s1,8(sp)
    80001c88:	6902                	ld	s2,0(sp)
    80001c8a:	6105                	addi	sp,sp,32
    80001c8c:	8082                	ret
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
    80001ca4:	bff1                	j	80001c80 <allocproc+0xa0>
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	ed0080e7          	jalr	-304(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fec080e7          	jalr	-20(ra) # 80000c9e <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	b7d1                	j	80001c80 <allocproc+0xa0>

0000000080001cbe <userinit>:
{
    80001cbe:	1101                	addi	sp,sp,-32
    80001cc0:	ec06                	sd	ra,24(sp)
    80001cc2:	e822                	sd	s0,16(sp)
    80001cc4:	e426                	sd	s1,8(sp)
    80001cc6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	f18080e7          	jalr	-232(ra) # 80001be0 <allocproc>
    80001cd0:	84aa                	mv	s1,a0
  initproc = p;
    80001cd2:	00007797          	auipc	a5,0x7
    80001cd6:	e2a7b323          	sd	a0,-474(a5) # 80008af8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cda:	03400613          	li	a2,52
    80001cde:	00007597          	auipc	a1,0x7
    80001ce2:	db258593          	addi	a1,a1,-590 # 80008a90 <initcode>
    80001ce6:	6928                	ld	a0,80(a0)
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	68a080e7          	jalr	1674(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cf0:	6785                	lui	a5,0x1
    80001cf2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf4:	6cb8                	ld	a4,88(s1)
    80001cf6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cfa:	6cb8                	ld	a4,88(s1)
    80001cfc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfe:	4641                	li	a2,16
    80001d00:	00006597          	auipc	a1,0x6
    80001d04:	50058593          	addi	a1,a1,1280 # 80008200 <digits+0x1c0>
    80001d08:	15848513          	addi	a0,s1,344
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	12c080e7          	jalr	300(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d14:	00006517          	auipc	a0,0x6
    80001d18:	4fc50513          	addi	a0,a0,1276 # 80008210 <digits+0x1d0>
    80001d1c:	00002097          	auipc	ra,0x2
    80001d20:	3d6080e7          	jalr	982(ra) # 800040f2 <namei>
    80001d24:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d28:	478d                	li	a5,3
    80001d2a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f70080e7          	jalr	-144(ra) # 80000c9e <release>
}
    80001d36:	60e2                	ld	ra,24(sp)
    80001d38:	6442                	ld	s0,16(sp)
    80001d3a:	64a2                	ld	s1,8(sp)
    80001d3c:	6105                	addi	sp,sp,32
    80001d3e:	8082                	ret

0000000080001d40 <growproc>:
{
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	e04a                	sd	s2,0(sp)
    80001d4a:	1000                	addi	s0,sp,32
    80001d4c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	c78080e7          	jalr	-904(ra) # 800019c6 <myproc>
    80001d56:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d58:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d5a:	01204c63          	bgtz	s2,80001d72 <growproc+0x32>
  } else if(n < 0){
    80001d5e:	02094663          	bltz	s2,80001d8a <growproc+0x4a>
  p->sz = sz;
    80001d62:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d64:	4501                	li	a0,0
}
    80001d66:	60e2                	ld	ra,24(sp)
    80001d68:	6442                	ld	s0,16(sp)
    80001d6a:	64a2                	ld	s1,8(sp)
    80001d6c:	6902                	ld	s2,0(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d72:	4691                	li	a3,4
    80001d74:	00b90633          	add	a2,s2,a1
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	6b2080e7          	jalr	1714(ra) # 8000142c <uvmalloc>
    80001d82:	85aa                	mv	a1,a0
    80001d84:	fd79                	bnez	a0,80001d62 <growproc+0x22>
      return -1;
    80001d86:	557d                	li	a0,-1
    80001d88:	bff9                	j	80001d66 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8a:	00b90633          	add	a2,s2,a1
    80001d8e:	6928                	ld	a0,80(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	654080e7          	jalr	1620(ra) # 800013e4 <uvmdealloc>
    80001d98:	85aa                	mv	a1,a0
    80001d9a:	b7e1                	j	80001d62 <growproc+0x22>

0000000080001d9c <fork>:
{
    80001d9c:	7179                	addi	sp,sp,-48
    80001d9e:	f406                	sd	ra,40(sp)
    80001da0:	f022                	sd	s0,32(sp)
    80001da2:	ec26                	sd	s1,24(sp)
    80001da4:	e84a                	sd	s2,16(sp)
    80001da6:	e44e                	sd	s3,8(sp)
    80001da8:	e052                	sd	s4,0(sp)
    80001daa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	c1a080e7          	jalr	-998(ra) # 800019c6 <myproc>
    80001db4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	e2a080e7          	jalr	-470(ra) # 80001be0 <allocproc>
    80001dbe:	10050b63          	beqz	a0,80001ed4 <fork+0x138>
    80001dc2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc4:	04893603          	ld	a2,72(s2)
    80001dc8:	692c                	ld	a1,80(a0)
    80001dca:	05093503          	ld	a0,80(s2)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	7b2080e7          	jalr	1970(ra) # 80001580 <uvmcopy>
    80001dd6:	04054663          	bltz	a0,80001e22 <fork+0x86>
  np->sz = p->sz;
    80001dda:	04893783          	ld	a5,72(s2)
    80001dde:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001de2:	05893683          	ld	a3,88(s2)
    80001de6:	87b6                	mv	a5,a3
    80001de8:	0589b703          	ld	a4,88(s3)
    80001dec:	12068693          	addi	a3,a3,288
    80001df0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df4:	6788                	ld	a0,8(a5)
    80001df6:	6b8c                	ld	a1,16(a5)
    80001df8:	6f90                	ld	a2,24(a5)
    80001dfa:	01073023          	sd	a6,0(a4)
    80001dfe:	e708                	sd	a0,8(a4)
    80001e00:	eb0c                	sd	a1,16(a4)
    80001e02:	ef10                	sd	a2,24(a4)
    80001e04:	02078793          	addi	a5,a5,32
    80001e08:	02070713          	addi	a4,a4,32
    80001e0c:	fed792e3          	bne	a5,a3,80001df0 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e10:	0589b783          	ld	a5,88(s3)
    80001e14:	0607b823          	sd	zero,112(a5)
    80001e18:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e1c:	15000a13          	li	s4,336
    80001e20:	a03d                	j	80001e4e <fork+0xb2>
    freeproc(np);
    80001e22:	854e                	mv	a0,s3
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	d54080e7          	jalr	-684(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e2c:	854e                	mv	a0,s3
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	e70080e7          	jalr	-400(ra) # 80000c9e <release>
    return -1;
    80001e36:	5a7d                	li	s4,-1
    80001e38:	a069                	j	80001ec2 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3a:	00003097          	auipc	ra,0x3
    80001e3e:	94e080e7          	jalr	-1714(ra) # 80004788 <filedup>
    80001e42:	009987b3          	add	a5,s3,s1
    80001e46:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e48:	04a1                	addi	s1,s1,8
    80001e4a:	01448763          	beq	s1,s4,80001e58 <fork+0xbc>
    if(p->ofile[i])
    80001e4e:	009907b3          	add	a5,s2,s1
    80001e52:	6388                	ld	a0,0(a5)
    80001e54:	f17d                	bnez	a0,80001e3a <fork+0x9e>
    80001e56:	bfcd                	j	80001e48 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e58:	15093503          	ld	a0,336(s2)
    80001e5c:	00002097          	auipc	ra,0x2
    80001e60:	ab2080e7          	jalr	-1358(ra) # 8000390e <idup>
    80001e64:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e68:	4641                	li	a2,16
    80001e6a:	15890593          	addi	a1,s2,344
    80001e6e:	15898513          	addi	a0,s3,344
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	fc6080e7          	jalr	-58(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e7a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e1e080e7          	jalr	-482(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e88:	0000f497          	auipc	s1,0xf
    80001e8c:	f0048493          	addi	s1,s1,-256 # 80010d88 <wait_lock>
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	d58080e7          	jalr	-680(ra) # 80000bea <acquire>
  np->parent = p;
    80001e9a:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	dfe080e7          	jalr	-514(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001ea8:	854e                	mv	a0,s3
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	d40080e7          	jalr	-704(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001eb2:	478d                	li	a5,3
    80001eb4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb8:	854e                	mv	a0,s3
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	de4080e7          	jalr	-540(ra) # 80000c9e <release>
}
    80001ec2:	8552                	mv	a0,s4
    80001ec4:	70a2                	ld	ra,40(sp)
    80001ec6:	7402                	ld	s0,32(sp)
    80001ec8:	64e2                	ld	s1,24(sp)
    80001eca:	6942                	ld	s2,16(sp)
    80001ecc:	69a2                	ld	s3,8(sp)
    80001ece:	6a02                	ld	s4,0(sp)
    80001ed0:	6145                	addi	sp,sp,48
    80001ed2:	8082                	ret
    return -1;
    80001ed4:	5a7d                	li	s4,-1
    80001ed6:	b7f5                	j	80001ec2 <fork+0x126>

0000000080001ed8 <scheduler>:
{
    80001ed8:	7139                	addi	sp,sp,-64
    80001eda:	fc06                	sd	ra,56(sp)
    80001edc:	f822                	sd	s0,48(sp)
    80001ede:	f426                	sd	s1,40(sp)
    80001ee0:	f04a                	sd	s2,32(sp)
    80001ee2:	ec4e                	sd	s3,24(sp)
    80001ee4:	e852                	sd	s4,16(sp)
    80001ee6:	e456                	sd	s5,8(sp)
    80001ee8:	e05a                	sd	s6,0(sp)
    80001eea:	0080                	addi	s0,sp,64
    80001eec:	8792                	mv	a5,tp
  int id = r_tp();
    80001eee:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ef0:	00779a93          	slli	s5,a5,0x7
    80001ef4:	0000f717          	auipc	a4,0xf
    80001ef8:	e7c70713          	addi	a4,a4,-388 # 80010d70 <pid_lock>
    80001efc:	9756                	add	a4,a4,s5
    80001efe:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f02:	0000f717          	auipc	a4,0xf
    80001f06:	ea670713          	addi	a4,a4,-346 # 80010da8 <cpus+0x8>
    80001f0a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f0c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f0e:	4b11                	li	s6,4
        c->proc = p;
    80001f10:	079e                	slli	a5,a5,0x7
    80001f12:	0000fa17          	auipc	s4,0xf
    80001f16:	e5ea0a13          	addi	s4,s4,-418 # 80010d70 <pid_lock>
    80001f1a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f1c:	00015917          	auipc	s2,0x15
    80001f20:	48490913          	addi	s2,s2,1156 # 800173a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f28:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f2c:	10079073          	csrw	sstatus,a5
    80001f30:	0000f497          	auipc	s1,0xf
    80001f34:	27048493          	addi	s1,s1,624 # 800111a0 <proc>
    80001f38:	a03d                	j	80001f66 <scheduler+0x8e>
        p->state = RUNNING;
    80001f3a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f3e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f42:	06048593          	addi	a1,s1,96
    80001f46:	8556                	mv	a0,s5
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	6a4080e7          	jalr	1700(ra) # 800025ec <swtch>
        c->proc = 0;
    80001f50:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d48080e7          	jalr	-696(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5e:	18848493          	addi	s1,s1,392
    80001f62:	fd2481e3          	beq	s1,s2,80001f24 <scheduler+0x4c>
      acquire(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	c82080e7          	jalr	-894(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f70:	4c9c                	lw	a5,24(s1)
    80001f72:	ff3791e3          	bne	a5,s3,80001f54 <scheduler+0x7c>
    80001f76:	b7d1                	j	80001f3a <scheduler+0x62>

0000000080001f78 <sched>:
{
    80001f78:	7179                	addi	sp,sp,-48
    80001f7a:	f406                	sd	ra,40(sp)
    80001f7c:	f022                	sd	s0,32(sp)
    80001f7e:	ec26                	sd	s1,24(sp)
    80001f80:	e84a                	sd	s2,16(sp)
    80001f82:	e44e                	sd	s3,8(sp)
    80001f84:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f86:	00000097          	auipc	ra,0x0
    80001f8a:	a40080e7          	jalr	-1472(ra) # 800019c6 <myproc>
    80001f8e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	be0080e7          	jalr	-1056(ra) # 80000b70 <holding>
    80001f98:	c93d                	beqz	a0,8000200e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f9c:	2781                	sext.w	a5,a5
    80001f9e:	079e                	slli	a5,a5,0x7
    80001fa0:	0000f717          	auipc	a4,0xf
    80001fa4:	dd070713          	addi	a4,a4,-560 # 80010d70 <pid_lock>
    80001fa8:	97ba                	add	a5,a5,a4
    80001faa:	0a87a703          	lw	a4,168(a5)
    80001fae:	4785                	li	a5,1
    80001fb0:	06f71763          	bne	a4,a5,8000201e <sched+0xa6>
  if(p->state == RUNNING)
    80001fb4:	4c98                	lw	a4,24(s1)
    80001fb6:	4791                	li	a5,4
    80001fb8:	06f70b63          	beq	a4,a5,8000202e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fc0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fc2:	efb5                	bnez	a5,8000203e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fc6:	0000f917          	auipc	s2,0xf
    80001fca:	daa90913          	addi	s2,s2,-598 # 80010d70 <pid_lock>
    80001fce:	2781                	sext.w	a5,a5
    80001fd0:	079e                	slli	a5,a5,0x7
    80001fd2:	97ca                	add	a5,a5,s2
    80001fd4:	0ac7a983          	lw	s3,172(a5)
    80001fd8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fda:	2781                	sext.w	a5,a5
    80001fdc:	079e                	slli	a5,a5,0x7
    80001fde:	0000f597          	auipc	a1,0xf
    80001fe2:	dca58593          	addi	a1,a1,-566 # 80010da8 <cpus+0x8>
    80001fe6:	95be                	add	a1,a1,a5
    80001fe8:	06048513          	addi	a0,s1,96
    80001fec:	00000097          	auipc	ra,0x0
    80001ff0:	600080e7          	jalr	1536(ra) # 800025ec <swtch>
    80001ff4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ff6:	2781                	sext.w	a5,a5
    80001ff8:	079e                	slli	a5,a5,0x7
    80001ffa:	97ca                	add	a5,a5,s2
    80001ffc:	0b37a623          	sw	s3,172(a5)
}
    80002000:	70a2                	ld	ra,40(sp)
    80002002:	7402                	ld	s0,32(sp)
    80002004:	64e2                	ld	s1,24(sp)
    80002006:	6942                	ld	s2,16(sp)
    80002008:	69a2                	ld	s3,8(sp)
    8000200a:	6145                	addi	sp,sp,48
    8000200c:	8082                	ret
    panic("sched p->lock");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	20a50513          	addi	a0,a0,522 # 80008218 <digits+0x1d8>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	52e080e7          	jalr	1326(ra) # 80000544 <panic>
    panic("sched locks");
    8000201e:	00006517          	auipc	a0,0x6
    80002022:	20a50513          	addi	a0,a0,522 # 80008228 <digits+0x1e8>
    80002026:	ffffe097          	auipc	ra,0xffffe
    8000202a:	51e080e7          	jalr	1310(ra) # 80000544 <panic>
    panic("sched running");
    8000202e:	00006517          	auipc	a0,0x6
    80002032:	20a50513          	addi	a0,a0,522 # 80008238 <digits+0x1f8>
    80002036:	ffffe097          	auipc	ra,0xffffe
    8000203a:	50e080e7          	jalr	1294(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000203e:	00006517          	auipc	a0,0x6
    80002042:	20a50513          	addi	a0,a0,522 # 80008248 <digits+0x208>
    80002046:	ffffe097          	auipc	ra,0xffffe
    8000204a:	4fe080e7          	jalr	1278(ra) # 80000544 <panic>

000000008000204e <yield>:
{
    8000204e:	1101                	addi	sp,sp,-32
    80002050:	ec06                	sd	ra,24(sp)
    80002052:	e822                	sd	s0,16(sp)
    80002054:	e426                	sd	s1,8(sp)
    80002056:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	96e080e7          	jalr	-1682(ra) # 800019c6 <myproc>
    80002060:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	b88080e7          	jalr	-1144(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000206a:	478d                	li	a5,3
    8000206c:	cc9c                	sw	a5,24(s1)
  sched();
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	f0a080e7          	jalr	-246(ra) # 80001f78 <sched>
  release(&p->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	c26080e7          	jalr	-986(ra) # 80000c9e <release>
}
    80002080:	60e2                	ld	ra,24(sp)
    80002082:	6442                	ld	s0,16(sp)
    80002084:	64a2                	ld	s1,8(sp)
    80002086:	6105                	addi	sp,sp,32
    80002088:	8082                	ret

000000008000208a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000208a:	7179                	addi	sp,sp,-48
    8000208c:	f406                	sd	ra,40(sp)
    8000208e:	f022                	sd	s0,32(sp)
    80002090:	ec26                	sd	s1,24(sp)
    80002092:	e84a                	sd	s2,16(sp)
    80002094:	e44e                	sd	s3,8(sp)
    80002096:	1800                	addi	s0,sp,48
    80002098:	89aa                	mv	s3,a0
    8000209a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	92a080e7          	jalr	-1750(ra) # 800019c6 <myproc>
    800020a4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	b44080e7          	jalr	-1212(ra) # 80000bea <acquire>
  release(lk);
    800020ae:	854a                	mv	a0,s2
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	bee080e7          	jalr	-1042(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    800020b8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020bc:	4789                	li	a5,2
    800020be:	cc9c                	sw	a5,24(s1)

  sched();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	eb8080e7          	jalr	-328(ra) # 80001f78 <sched>

  // Tidy up.
  p->chan = 0;
    800020c8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020cc:	8526                	mv	a0,s1
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	bd0080e7          	jalr	-1072(ra) # 80000c9e <release>
  acquire(lk);
    800020d6:	854a                	mv	a0,s2
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	b12080e7          	jalr	-1262(ra) # 80000bea <acquire>
}
    800020e0:	70a2                	ld	ra,40(sp)
    800020e2:	7402                	ld	s0,32(sp)
    800020e4:	64e2                	ld	s1,24(sp)
    800020e6:	6942                	ld	s2,16(sp)
    800020e8:	69a2                	ld	s3,8(sp)
    800020ea:	6145                	addi	sp,sp,48
    800020ec:	8082                	ret

00000000800020ee <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020ee:	7139                	addi	sp,sp,-64
    800020f0:	fc06                	sd	ra,56(sp)
    800020f2:	f822                	sd	s0,48(sp)
    800020f4:	f426                	sd	s1,40(sp)
    800020f6:	f04a                	sd	s2,32(sp)
    800020f8:	ec4e                	sd	s3,24(sp)
    800020fa:	e852                	sd	s4,16(sp)
    800020fc:	e456                	sd	s5,8(sp)
    800020fe:	0080                	addi	s0,sp,64
    80002100:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002102:	0000f497          	auipc	s1,0xf
    80002106:	09e48493          	addi	s1,s1,158 # 800111a0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000210c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000210e:	00015917          	auipc	s2,0x15
    80002112:	29290913          	addi	s2,s2,658 # 800173a0 <tickslock>
    80002116:	a821                	j	8000212e <wakeup+0x40>
        p->state = RUNNABLE;
    80002118:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b80080e7          	jalr	-1152(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002126:	18848493          	addi	s1,s1,392
    8000212a:	03248463          	beq	s1,s2,80002152 <wakeup+0x64>
    if(p != myproc()){
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	898080e7          	jalr	-1896(ra) # 800019c6 <myproc>
    80002136:	fea488e3          	beq	s1,a0,80002126 <wakeup+0x38>
      acquire(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	aae080e7          	jalr	-1362(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002144:	4c9c                	lw	a5,24(s1)
    80002146:	fd379be3          	bne	a5,s3,8000211c <wakeup+0x2e>
    8000214a:	709c                	ld	a5,32(s1)
    8000214c:	fd4798e3          	bne	a5,s4,8000211c <wakeup+0x2e>
    80002150:	b7e1                	j	80002118 <wakeup+0x2a>
    }
  }
}
    80002152:	70e2                	ld	ra,56(sp)
    80002154:	7442                	ld	s0,48(sp)
    80002156:	74a2                	ld	s1,40(sp)
    80002158:	7902                	ld	s2,32(sp)
    8000215a:	69e2                	ld	s3,24(sp)
    8000215c:	6a42                	ld	s4,16(sp)
    8000215e:	6aa2                	ld	s5,8(sp)
    80002160:	6121                	addi	sp,sp,64
    80002162:	8082                	ret

0000000080002164 <reparent>:
{
    80002164:	7179                	addi	sp,sp,-48
    80002166:	f406                	sd	ra,40(sp)
    80002168:	f022                	sd	s0,32(sp)
    8000216a:	ec26                	sd	s1,24(sp)
    8000216c:	e84a                	sd	s2,16(sp)
    8000216e:	e44e                	sd	s3,8(sp)
    80002170:	e052                	sd	s4,0(sp)
    80002172:	1800                	addi	s0,sp,48
    80002174:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002176:	0000f497          	auipc	s1,0xf
    8000217a:	02a48493          	addi	s1,s1,42 # 800111a0 <proc>
      pp->parent = initproc;
    8000217e:	00007a17          	auipc	s4,0x7
    80002182:	97aa0a13          	addi	s4,s4,-1670 # 80008af8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002186:	00015997          	auipc	s3,0x15
    8000218a:	21a98993          	addi	s3,s3,538 # 800173a0 <tickslock>
    8000218e:	a029                	j	80002198 <reparent+0x34>
    80002190:	18848493          	addi	s1,s1,392
    80002194:	01348d63          	beq	s1,s3,800021ae <reparent+0x4a>
    if(pp->parent == p){
    80002198:	7c9c                	ld	a5,56(s1)
    8000219a:	ff279be3          	bne	a5,s2,80002190 <reparent+0x2c>
      pp->parent = initproc;
    8000219e:	000a3503          	ld	a0,0(s4)
    800021a2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	f4a080e7          	jalr	-182(ra) # 800020ee <wakeup>
    800021ac:	b7d5                	j	80002190 <reparent+0x2c>
}
    800021ae:	70a2                	ld	ra,40(sp)
    800021b0:	7402                	ld	s0,32(sp)
    800021b2:	64e2                	ld	s1,24(sp)
    800021b4:	6942                	ld	s2,16(sp)
    800021b6:	69a2                	ld	s3,8(sp)
    800021b8:	6a02                	ld	s4,0(sp)
    800021ba:	6145                	addi	sp,sp,48
    800021bc:	8082                	ret

00000000800021be <exit>:
{
    800021be:	7179                	addi	sp,sp,-48
    800021c0:	f406                	sd	ra,40(sp)
    800021c2:	f022                	sd	s0,32(sp)
    800021c4:	ec26                	sd	s1,24(sp)
    800021c6:	e84a                	sd	s2,16(sp)
    800021c8:	e44e                	sd	s3,8(sp)
    800021ca:	e052                	sd	s4,0(sp)
    800021cc:	1800                	addi	s0,sp,48
    800021ce:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	7f6080e7          	jalr	2038(ra) # 800019c6 <myproc>
    800021d8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021da:	00007797          	auipc	a5,0x7
    800021de:	91e7b783          	ld	a5,-1762(a5) # 80008af8 <initproc>
    800021e2:	0d050493          	addi	s1,a0,208
    800021e6:	15050913          	addi	s2,a0,336
    800021ea:	02a79363          	bne	a5,a0,80002210 <exit+0x52>
    panic("init exiting");
    800021ee:	00006517          	auipc	a0,0x6
    800021f2:	07250513          	addi	a0,a0,114 # 80008260 <digits+0x220>
    800021f6:	ffffe097          	auipc	ra,0xffffe
    800021fa:	34e080e7          	jalr	846(ra) # 80000544 <panic>
      fileclose(f);
    800021fe:	00002097          	auipc	ra,0x2
    80002202:	5dc080e7          	jalr	1500(ra) # 800047da <fileclose>
      p->ofile[fd] = 0;
    80002206:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000220a:	04a1                	addi	s1,s1,8
    8000220c:	01248563          	beq	s1,s2,80002216 <exit+0x58>
    if(p->ofile[fd]){
    80002210:	6088                	ld	a0,0(s1)
    80002212:	f575                	bnez	a0,800021fe <exit+0x40>
    80002214:	bfdd                	j	8000220a <exit+0x4c>
  begin_op();
    80002216:	00002097          	auipc	ra,0x2
    8000221a:	0f8080e7          	jalr	248(ra) # 8000430e <begin_op>
  iput(p->cwd);
    8000221e:	1509b503          	ld	a0,336(s3)
    80002222:	00002097          	auipc	ra,0x2
    80002226:	8e4080e7          	jalr	-1820(ra) # 80003b06 <iput>
  end_op();
    8000222a:	00002097          	auipc	ra,0x2
    8000222e:	164080e7          	jalr	356(ra) # 8000438e <end_op>
  p->cwd = 0;
    80002232:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002236:	0000f497          	auipc	s1,0xf
    8000223a:	b5248493          	addi	s1,s1,-1198 # 80010d88 <wait_lock>
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9aa080e7          	jalr	-1622(ra) # 80000bea <acquire>
  reparent(p);
    80002248:	854e                	mv	a0,s3
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	f1a080e7          	jalr	-230(ra) # 80002164 <reparent>
  wakeup(p->parent);
    80002252:	0389b503          	ld	a0,56(s3)
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	e98080e7          	jalr	-360(ra) # 800020ee <wakeup>
  acquire(&p->lock);
    8000225e:	854e                	mv	a0,s3
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	98a080e7          	jalr	-1654(ra) # 80000bea <acquire>
  p->xstate = status;
    80002268:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000226c:	4795                	li	a5,5
    8000226e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a2a080e7          	jalr	-1494(ra) # 80000c9e <release>
  sched();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	cfc080e7          	jalr	-772(ra) # 80001f78 <sched>
  panic("zombie exit");
    80002284:	00006517          	auipc	a0,0x6
    80002288:	fec50513          	addi	a0,a0,-20 # 80008270 <digits+0x230>
    8000228c:	ffffe097          	auipc	ra,0xffffe
    80002290:	2b8080e7          	jalr	696(ra) # 80000544 <panic>

0000000080002294 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002294:	7179                	addi	sp,sp,-48
    80002296:	f406                	sd	ra,40(sp)
    80002298:	f022                	sd	s0,32(sp)
    8000229a:	ec26                	sd	s1,24(sp)
    8000229c:	e84a                	sd	s2,16(sp)
    8000229e:	e44e                	sd	s3,8(sp)
    800022a0:	1800                	addi	s0,sp,48
    800022a2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022a4:	0000f497          	auipc	s1,0xf
    800022a8:	efc48493          	addi	s1,s1,-260 # 800111a0 <proc>
    800022ac:	00015997          	auipc	s3,0x15
    800022b0:	0f498993          	addi	s3,s3,244 # 800173a0 <tickslock>
    acquire(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	934080e7          	jalr	-1740(ra) # 80000bea <acquire>
    if(p->pid == pid){
    800022be:	589c                	lw	a5,48(s1)
    800022c0:	01278d63          	beq	a5,s2,800022da <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9d8080e7          	jalr	-1576(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ce:	18848493          	addi	s1,s1,392
    800022d2:	ff3491e3          	bne	s1,s3,800022b4 <kill+0x20>
  }
  return -1;
    800022d6:	557d                	li	a0,-1
    800022d8:	a829                	j	800022f2 <kill+0x5e>
      p->killed = 1;
    800022da:	4785                	li	a5,1
    800022dc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022de:	4c98                	lw	a4,24(s1)
    800022e0:	4789                	li	a5,2
    800022e2:	00f70f63          	beq	a4,a5,80002300 <kill+0x6c>
      release(&p->lock);
    800022e6:	8526                	mv	a0,s1
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9b6080e7          	jalr	-1610(ra) # 80000c9e <release>
      return 0;
    800022f0:	4501                	li	a0,0
}
    800022f2:	70a2                	ld	ra,40(sp)
    800022f4:	7402                	ld	s0,32(sp)
    800022f6:	64e2                	ld	s1,24(sp)
    800022f8:	6942                	ld	s2,16(sp)
    800022fa:	69a2                	ld	s3,8(sp)
    800022fc:	6145                	addi	sp,sp,48
    800022fe:	8082                	ret
        p->state = RUNNABLE;
    80002300:	478d                	li	a5,3
    80002302:	cc9c                	sw	a5,24(s1)
    80002304:	b7cd                	j	800022e6 <kill+0x52>

0000000080002306 <setkilled>:

void
setkilled(struct proc *p)
{
    80002306:	1101                	addi	sp,sp,-32
    80002308:	ec06                	sd	ra,24(sp)
    8000230a:	e822                	sd	s0,16(sp)
    8000230c:	e426                	sd	s1,8(sp)
    8000230e:	1000                	addi	s0,sp,32
    80002310:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	8d8080e7          	jalr	-1832(ra) # 80000bea <acquire>
  p->killed = 1;
    8000231a:	4785                	li	a5,1
    8000231c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	97e080e7          	jalr	-1666(ra) # 80000c9e <release>
}
    80002328:	60e2                	ld	ra,24(sp)
    8000232a:	6442                	ld	s0,16(sp)
    8000232c:	64a2                	ld	s1,8(sp)
    8000232e:	6105                	addi	sp,sp,32
    80002330:	8082                	ret

0000000080002332 <killed>:

int
killed(struct proc *p)
{
    80002332:	1101                	addi	sp,sp,-32
    80002334:	ec06                	sd	ra,24(sp)
    80002336:	e822                	sd	s0,16(sp)
    80002338:	e426                	sd	s1,8(sp)
    8000233a:	e04a                	sd	s2,0(sp)
    8000233c:	1000                	addi	s0,sp,32
    8000233e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	8aa080e7          	jalr	-1878(ra) # 80000bea <acquire>
  k = p->killed;
    80002348:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	950080e7          	jalr	-1712(ra) # 80000c9e <release>
  return k;
}
    80002356:	854a                	mv	a0,s2
    80002358:	60e2                	ld	ra,24(sp)
    8000235a:	6442                	ld	s0,16(sp)
    8000235c:	64a2                	ld	s1,8(sp)
    8000235e:	6902                	ld	s2,0(sp)
    80002360:	6105                	addi	sp,sp,32
    80002362:	8082                	ret

0000000080002364 <wait>:
{
    80002364:	715d                	addi	sp,sp,-80
    80002366:	e486                	sd	ra,72(sp)
    80002368:	e0a2                	sd	s0,64(sp)
    8000236a:	fc26                	sd	s1,56(sp)
    8000236c:	f84a                	sd	s2,48(sp)
    8000236e:	f44e                	sd	s3,40(sp)
    80002370:	f052                	sd	s4,32(sp)
    80002372:	ec56                	sd	s5,24(sp)
    80002374:	e85a                	sd	s6,16(sp)
    80002376:	e45e                	sd	s7,8(sp)
    80002378:	e062                	sd	s8,0(sp)
    8000237a:	0880                	addi	s0,sp,80
    8000237c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	648080e7          	jalr	1608(ra) # 800019c6 <myproc>
    80002386:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002388:	0000f517          	auipc	a0,0xf
    8000238c:	a0050513          	addi	a0,a0,-1536 # 80010d88 <wait_lock>
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	85a080e7          	jalr	-1958(ra) # 80000bea <acquire>
    havekids = 0;
    80002398:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000239a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000239c:	00015997          	auipc	s3,0x15
    800023a0:	00498993          	addi	s3,s3,4 # 800173a0 <tickslock>
        havekids = 1;
    800023a4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023a6:	0000fc17          	auipc	s8,0xf
    800023aa:	9e2c0c13          	addi	s8,s8,-1566 # 80010d88 <wait_lock>
    havekids = 0;
    800023ae:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b0:	0000f497          	auipc	s1,0xf
    800023b4:	df048493          	addi	s1,s1,-528 # 800111a0 <proc>
    800023b8:	a0bd                	j	80002426 <wait+0xc2>
          pid = pp->pid;
    800023ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023be:	000b0e63          	beqz	s6,800023da <wait+0x76>
    800023c2:	4691                	li	a3,4
    800023c4:	02c48613          	addi	a2,s1,44
    800023c8:	85da                	mv	a1,s6
    800023ca:	05093503          	ld	a0,80(s2)
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	2b6080e7          	jalr	694(ra) # 80001684 <copyout>
    800023d6:	02054563          	bltz	a0,80002400 <wait+0x9c>
          freeproc(pp);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	79c080e7          	jalr	1948(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8b8080e7          	jalr	-1864(ra) # 80000c9e <release>
          release(&wait_lock);
    800023ee:	0000f517          	auipc	a0,0xf
    800023f2:	99a50513          	addi	a0,a0,-1638 # 80010d88 <wait_lock>
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	8a8080e7          	jalr	-1880(ra) # 80000c9e <release>
          return pid;
    800023fe:	a0b5                	j	8000246a <wait+0x106>
            release(&pp->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	89c080e7          	jalr	-1892(ra) # 80000c9e <release>
            release(&wait_lock);
    8000240a:	0000f517          	auipc	a0,0xf
    8000240e:	97e50513          	addi	a0,a0,-1666 # 80010d88 <wait_lock>
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	88c080e7          	jalr	-1908(ra) # 80000c9e <release>
            return -1;
    8000241a:	59fd                	li	s3,-1
    8000241c:	a0b9                	j	8000246a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000241e:	18848493          	addi	s1,s1,392
    80002422:	03348463          	beq	s1,s3,8000244a <wait+0xe6>
      if(pp->parent == p){
    80002426:	7c9c                	ld	a5,56(s1)
    80002428:	ff279be3          	bne	a5,s2,8000241e <wait+0xba>
        acquire(&pp->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7bc080e7          	jalr	1980(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002436:	4c9c                	lw	a5,24(s1)
    80002438:	f94781e3          	beq	a5,s4,800023ba <wait+0x56>
        release(&pp->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	860080e7          	jalr	-1952(ra) # 80000c9e <release>
        havekids = 1;
    80002446:	8756                	mv	a4,s5
    80002448:	bfd9                	j	8000241e <wait+0xba>
    if(!havekids || killed(p)){
    8000244a:	c719                	beqz	a4,80002458 <wait+0xf4>
    8000244c:	854a                	mv	a0,s2
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	ee4080e7          	jalr	-284(ra) # 80002332 <killed>
    80002456:	c51d                	beqz	a0,80002484 <wait+0x120>
      release(&wait_lock);
    80002458:	0000f517          	auipc	a0,0xf
    8000245c:	93050513          	addi	a0,a0,-1744 # 80010d88 <wait_lock>
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	83e080e7          	jalr	-1986(ra) # 80000c9e <release>
      return -1;
    80002468:	59fd                	li	s3,-1
}
    8000246a:	854e                	mv	a0,s3
    8000246c:	60a6                	ld	ra,72(sp)
    8000246e:	6406                	ld	s0,64(sp)
    80002470:	74e2                	ld	s1,56(sp)
    80002472:	7942                	ld	s2,48(sp)
    80002474:	79a2                	ld	s3,40(sp)
    80002476:	7a02                	ld	s4,32(sp)
    80002478:	6ae2                	ld	s5,24(sp)
    8000247a:	6b42                	ld	s6,16(sp)
    8000247c:	6ba2                	ld	s7,8(sp)
    8000247e:	6c02                	ld	s8,0(sp)
    80002480:	6161                	addi	sp,sp,80
    80002482:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002484:	85e2                	mv	a1,s8
    80002486:	854a                	mv	a0,s2
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	c02080e7          	jalr	-1022(ra) # 8000208a <sleep>
    havekids = 0;
    80002490:	bf39                	j	800023ae <wait+0x4a>

0000000080002492 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002492:	7179                	addi	sp,sp,-48
    80002494:	f406                	sd	ra,40(sp)
    80002496:	f022                	sd	s0,32(sp)
    80002498:	ec26                	sd	s1,24(sp)
    8000249a:	e84a                	sd	s2,16(sp)
    8000249c:	e44e                	sd	s3,8(sp)
    8000249e:	e052                	sd	s4,0(sp)
    800024a0:	1800                	addi	s0,sp,48
    800024a2:	84aa                	mv	s1,a0
    800024a4:	892e                	mv	s2,a1
    800024a6:	89b2                	mv	s3,a2
    800024a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	51c080e7          	jalr	1308(ra) # 800019c6 <myproc>
  if(user_dst){
    800024b2:	c08d                	beqz	s1,800024d4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024b4:	86d2                	mv	a3,s4
    800024b6:	864e                	mv	a2,s3
    800024b8:	85ca                	mv	a1,s2
    800024ba:	6928                	ld	a0,80(a0)
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	1c8080e7          	jalr	456(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024c4:	70a2                	ld	ra,40(sp)
    800024c6:	7402                	ld	s0,32(sp)
    800024c8:	64e2                	ld	s1,24(sp)
    800024ca:	6942                	ld	s2,16(sp)
    800024cc:	69a2                	ld	s3,8(sp)
    800024ce:	6a02                	ld	s4,0(sp)
    800024d0:	6145                	addi	sp,sp,48
    800024d2:	8082                	ret
    memmove((char *)dst, src, len);
    800024d4:	000a061b          	sext.w	a2,s4
    800024d8:	85ce                	mv	a1,s3
    800024da:	854a                	mv	a0,s2
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	86a080e7          	jalr	-1942(ra) # 80000d46 <memmove>
    return 0;
    800024e4:	8526                	mv	a0,s1
    800024e6:	bff9                	j	800024c4 <either_copyout+0x32>

00000000800024e8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e8:	7179                	addi	sp,sp,-48
    800024ea:	f406                	sd	ra,40(sp)
    800024ec:	f022                	sd	s0,32(sp)
    800024ee:	ec26                	sd	s1,24(sp)
    800024f0:	e84a                	sd	s2,16(sp)
    800024f2:	e44e                	sd	s3,8(sp)
    800024f4:	e052                	sd	s4,0(sp)
    800024f6:	1800                	addi	s0,sp,48
    800024f8:	892a                	mv	s2,a0
    800024fa:	84ae                	mv	s1,a1
    800024fc:	89b2                	mv	s3,a2
    800024fe:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	4c6080e7          	jalr	1222(ra) # 800019c6 <myproc>
  if(user_src){
    80002508:	c08d                	beqz	s1,8000252a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000250a:	86d2                	mv	a3,s4
    8000250c:	864e                	mv	a2,s3
    8000250e:	85ca                	mv	a1,s2
    80002510:	6928                	ld	a0,80(a0)
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	1fe080e7          	jalr	510(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000251a:	70a2                	ld	ra,40(sp)
    8000251c:	7402                	ld	s0,32(sp)
    8000251e:	64e2                	ld	s1,24(sp)
    80002520:	6942                	ld	s2,16(sp)
    80002522:	69a2                	ld	s3,8(sp)
    80002524:	6a02                	ld	s4,0(sp)
    80002526:	6145                	addi	sp,sp,48
    80002528:	8082                	ret
    memmove(dst, (char*)src, len);
    8000252a:	000a061b          	sext.w	a2,s4
    8000252e:	85ce                	mv	a1,s3
    80002530:	854a                	mv	a0,s2
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	814080e7          	jalr	-2028(ra) # 80000d46 <memmove>
    return 0;
    8000253a:	8526                	mv	a0,s1
    8000253c:	bff9                	j	8000251a <either_copyin+0x32>

000000008000253e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000253e:	715d                	addi	sp,sp,-80
    80002540:	e486                	sd	ra,72(sp)
    80002542:	e0a2                	sd	s0,64(sp)
    80002544:	fc26                	sd	s1,56(sp)
    80002546:	f84a                	sd	s2,48(sp)
    80002548:	f44e                	sd	s3,40(sp)
    8000254a:	f052                	sd	s4,32(sp)
    8000254c:	ec56                	sd	s5,24(sp)
    8000254e:	e85a                	sd	s6,16(sp)
    80002550:	e45e                	sd	s7,8(sp)
    80002552:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002554:	00006517          	auipc	a0,0x6
    80002558:	b7450513          	addi	a0,a0,-1164 # 800080c8 <digits+0x88>
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	032080e7          	jalr	50(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002564:	0000f497          	auipc	s1,0xf
    80002568:	d9448493          	addi	s1,s1,-620 # 800112f8 <proc+0x158>
    8000256c:	00015917          	auipc	s2,0x15
    80002570:	f8c90913          	addi	s2,s2,-116 # 800174f8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002574:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002576:	00006997          	auipc	s3,0x6
    8000257a:	d0a98993          	addi	s3,s3,-758 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000257e:	00006a97          	auipc	s5,0x6
    80002582:	d0aa8a93          	addi	s5,s5,-758 # 80008288 <digits+0x248>
    printf("\n");
    80002586:	00006a17          	auipc	s4,0x6
    8000258a:	b42a0a13          	addi	s4,s4,-1214 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258e:	00006b97          	auipc	s7,0x6
    80002592:	d3ab8b93          	addi	s7,s7,-710 # 800082c8 <states.1728>
    80002596:	a00d                	j	800025b8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002598:	ed86a583          	lw	a1,-296(a3)
    8000259c:	8556                	mv	a0,s5
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	ff0080e7          	jalr	-16(ra) # 8000058e <printf>
    printf("\n");
    800025a6:	8552                	mv	a0,s4
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	fe6080e7          	jalr	-26(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b0:	18848493          	addi	s1,s1,392
    800025b4:	03248163          	beq	s1,s2,800025d6 <procdump+0x98>
    if(p->state == UNUSED)
    800025b8:	86a6                	mv	a3,s1
    800025ba:	ec04a783          	lw	a5,-320(s1)
    800025be:	dbed                	beqz	a5,800025b0 <procdump+0x72>
      state = "???";
    800025c0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c2:	fcfb6be3          	bltu	s6,a5,80002598 <procdump+0x5a>
    800025c6:	1782                	slli	a5,a5,0x20
    800025c8:	9381                	srli	a5,a5,0x20
    800025ca:	078e                	slli	a5,a5,0x3
    800025cc:	97de                	add	a5,a5,s7
    800025ce:	6390                	ld	a2,0(a5)
    800025d0:	f661                	bnez	a2,80002598 <procdump+0x5a>
      state = "???";
    800025d2:	864e                	mv	a2,s3
    800025d4:	b7d1                	j	80002598 <procdump+0x5a>
  }
}
    800025d6:	60a6                	ld	ra,72(sp)
    800025d8:	6406                	ld	s0,64(sp)
    800025da:	74e2                	ld	s1,56(sp)
    800025dc:	7942                	ld	s2,48(sp)
    800025de:	79a2                	ld	s3,40(sp)
    800025e0:	7a02                	ld	s4,32(sp)
    800025e2:	6ae2                	ld	s5,24(sp)
    800025e4:	6b42                	ld	s6,16(sp)
    800025e6:	6ba2                	ld	s7,8(sp)
    800025e8:	6161                	addi	sp,sp,80
    800025ea:	8082                	ret

00000000800025ec <swtch>:
    800025ec:	00153023          	sd	ra,0(a0)
    800025f0:	00253423          	sd	sp,8(a0)
    800025f4:	e900                	sd	s0,16(a0)
    800025f6:	ed04                	sd	s1,24(a0)
    800025f8:	03253023          	sd	s2,32(a0)
    800025fc:	03353423          	sd	s3,40(a0)
    80002600:	03453823          	sd	s4,48(a0)
    80002604:	03553c23          	sd	s5,56(a0)
    80002608:	05653023          	sd	s6,64(a0)
    8000260c:	05753423          	sd	s7,72(a0)
    80002610:	05853823          	sd	s8,80(a0)
    80002614:	05953c23          	sd	s9,88(a0)
    80002618:	07a53023          	sd	s10,96(a0)
    8000261c:	07b53423          	sd	s11,104(a0)
    80002620:	0005b083          	ld	ra,0(a1)
    80002624:	0085b103          	ld	sp,8(a1)
    80002628:	6980                	ld	s0,16(a1)
    8000262a:	6d84                	ld	s1,24(a1)
    8000262c:	0205b903          	ld	s2,32(a1)
    80002630:	0285b983          	ld	s3,40(a1)
    80002634:	0305ba03          	ld	s4,48(a1)
    80002638:	0385ba83          	ld	s5,56(a1)
    8000263c:	0405bb03          	ld	s6,64(a1)
    80002640:	0485bb83          	ld	s7,72(a1)
    80002644:	0505bc03          	ld	s8,80(a1)
    80002648:	0585bc83          	ld	s9,88(a1)
    8000264c:	0605bd03          	ld	s10,96(a1)
    80002650:	0685bd83          	ld	s11,104(a1)
    80002654:	8082                	ret

0000000080002656 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002656:	1141                	addi	sp,sp,-16
    80002658:	e406                	sd	ra,8(sp)
    8000265a:	e022                	sd	s0,0(sp)
    8000265c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000265e:	00006597          	auipc	a1,0x6
    80002662:	c9a58593          	addi	a1,a1,-870 # 800082f8 <states.1728+0x30>
    80002666:	00015517          	auipc	a0,0x15
    8000266a:	d3a50513          	addi	a0,a0,-710 # 800173a0 <tickslock>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	4ec080e7          	jalr	1260(ra) # 80000b5a <initlock>
}
    80002676:	60a2                	ld	ra,8(sp)
    80002678:	6402                	ld	s0,0(sp)
    8000267a:	0141                	addi	sp,sp,16
    8000267c:	8082                	ret

000000008000267e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000267e:	1141                	addi	sp,sp,-16
    80002680:	e422                	sd	s0,8(sp)
    80002682:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002684:	00003797          	auipc	a5,0x3
    80002688:	79c78793          	addi	a5,a5,1948 # 80005e20 <kernelvec>
    8000268c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002690:	6422                	ld	s0,8(sp)
    80002692:	0141                	addi	sp,sp,16
    80002694:	8082                	ret

0000000080002696 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002696:	1141                	addi	sp,sp,-16
    80002698:	e406                	sd	ra,8(sp)
    8000269a:	e022                	sd	s0,0(sp)
    8000269c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000269e:	fffff097          	auipc	ra,0xfffff
    800026a2:	328080e7          	jalr	808(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026a6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026aa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ac:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026b0:	00005617          	auipc	a2,0x5
    800026b4:	95060613          	addi	a2,a2,-1712 # 80007000 <_trampoline>
    800026b8:	00005697          	auipc	a3,0x5
    800026bc:	94868693          	addi	a3,a3,-1720 # 80007000 <_trampoline>
    800026c0:	8e91                	sub	a3,a3,a2
    800026c2:	040007b7          	lui	a5,0x4000
    800026c6:	17fd                	addi	a5,a5,-1
    800026c8:	07b2                	slli	a5,a5,0xc
    800026ca:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026cc:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026d0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026d2:	180026f3          	csrr	a3,satp
    800026d6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026d8:	6d38                	ld	a4,88(a0)
    800026da:	6134                	ld	a3,64(a0)
    800026dc:	6585                	lui	a1,0x1
    800026de:	96ae                	add	a3,a3,a1
    800026e0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026e2:	6d38                	ld	a4,88(a0)
    800026e4:	00000697          	auipc	a3,0x0
    800026e8:	13068693          	addi	a3,a3,304 # 80002814 <usertrap>
    800026ec:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ee:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026f0:	8692                	mv	a3,tp
    800026f2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026f8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026fc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002700:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002704:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002706:	6f18                	ld	a4,24(a4)
    80002708:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000270c:	6928                	ld	a0,80(a0)
    8000270e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002710:	00005717          	auipc	a4,0x5
    80002714:	98c70713          	addi	a4,a4,-1652 # 8000709c <userret>
    80002718:	8f11                	sub	a4,a4,a2
    8000271a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000271c:	577d                	li	a4,-1
    8000271e:	177e                	slli	a4,a4,0x3f
    80002720:	8d59                	or	a0,a0,a4
    80002722:	9782                	jalr	a5
}
    80002724:	60a2                	ld	ra,8(sp)
    80002726:	6402                	ld	s0,0(sp)
    80002728:	0141                	addi	sp,sp,16
    8000272a:	8082                	ret

000000008000272c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000272c:	1101                	addi	sp,sp,-32
    8000272e:	ec06                	sd	ra,24(sp)
    80002730:	e822                	sd	s0,16(sp)
    80002732:	e426                	sd	s1,8(sp)
    80002734:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002736:	00015497          	auipc	s1,0x15
    8000273a:	c6a48493          	addi	s1,s1,-918 # 800173a0 <tickslock>
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	4aa080e7          	jalr	1194(ra) # 80000bea <acquire>
  ticks++;
    80002748:	00006517          	auipc	a0,0x6
    8000274c:	3b850513          	addi	a0,a0,952 # 80008b00 <ticks>
    80002750:	411c                	lw	a5,0(a0)
    80002752:	2785                	addiw	a5,a5,1
    80002754:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002756:	00000097          	auipc	ra,0x0
    8000275a:	998080e7          	jalr	-1640(ra) # 800020ee <wakeup>
  release(&tickslock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	53e080e7          	jalr	1342(ra) # 80000c9e <release>
}
    80002768:	60e2                	ld	ra,24(sp)
    8000276a:	6442                	ld	s0,16(sp)
    8000276c:	64a2                	ld	s1,8(sp)
    8000276e:	6105                	addi	sp,sp,32
    80002770:	8082                	ret

0000000080002772 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002772:	1101                	addi	sp,sp,-32
    80002774:	ec06                	sd	ra,24(sp)
    80002776:	e822                	sd	s0,16(sp)
    80002778:	e426                	sd	s1,8(sp)
    8000277a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000277c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002780:	00074d63          	bltz	a4,8000279a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002784:	57fd                	li	a5,-1
    80002786:	17fe                	slli	a5,a5,0x3f
    80002788:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000278a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000278c:	06f70363          	beq	a4,a5,800027f2 <devintr+0x80>
  }
}
    80002790:	60e2                	ld	ra,24(sp)
    80002792:	6442                	ld	s0,16(sp)
    80002794:	64a2                	ld	s1,8(sp)
    80002796:	6105                	addi	sp,sp,32
    80002798:	8082                	ret
     (scause & 0xff) == 9){
    8000279a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000279e:	46a5                	li	a3,9
    800027a0:	fed792e3          	bne	a5,a3,80002784 <devintr+0x12>
    int irq = plic_claim();
    800027a4:	00003097          	auipc	ra,0x3
    800027a8:	784080e7          	jalr	1924(ra) # 80005f28 <plic_claim>
    800027ac:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027ae:	47a9                	li	a5,10
    800027b0:	02f50763          	beq	a0,a5,800027de <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027b4:	4785                	li	a5,1
    800027b6:	02f50963          	beq	a0,a5,800027e8 <devintr+0x76>
    return 1;
    800027ba:	4505                	li	a0,1
    } else if(irq){
    800027bc:	d8f1                	beqz	s1,80002790 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027be:	85a6                	mv	a1,s1
    800027c0:	00006517          	auipc	a0,0x6
    800027c4:	b4050513          	addi	a0,a0,-1216 # 80008300 <states.1728+0x38>
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	dc6080e7          	jalr	-570(ra) # 8000058e <printf>
      plic_complete(irq);
    800027d0:	8526                	mv	a0,s1
    800027d2:	00003097          	auipc	ra,0x3
    800027d6:	77a080e7          	jalr	1914(ra) # 80005f4c <plic_complete>
    return 1;
    800027da:	4505                	li	a0,1
    800027dc:	bf55                	j	80002790 <devintr+0x1e>
      uartintr();
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	1d0080e7          	jalr	464(ra) # 800009ae <uartintr>
    800027e6:	b7ed                	j	800027d0 <devintr+0x5e>
      virtio_disk_intr();
    800027e8:	00004097          	auipc	ra,0x4
    800027ec:	c8e080e7          	jalr	-882(ra) # 80006476 <virtio_disk_intr>
    800027f0:	b7c5                	j	800027d0 <devintr+0x5e>
    if(cpuid() == 0){
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	1a8080e7          	jalr	424(ra) # 8000199a <cpuid>
    800027fa:	c901                	beqz	a0,8000280a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027fc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002800:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002802:	14479073          	csrw	sip,a5
    return 2;
    80002806:	4509                	li	a0,2
    80002808:	b761                	j	80002790 <devintr+0x1e>
      clockintr();
    8000280a:	00000097          	auipc	ra,0x0
    8000280e:	f22080e7          	jalr	-222(ra) # 8000272c <clockintr>
    80002812:	b7ed                	j	800027fc <devintr+0x8a>

0000000080002814 <usertrap>:
{
    80002814:	1101                	addi	sp,sp,-32
    80002816:	ec06                	sd	ra,24(sp)
    80002818:	e822                	sd	s0,16(sp)
    8000281a:	e426                	sd	s1,8(sp)
    8000281c:	e04a                	sd	s2,0(sp)
    8000281e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002820:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002824:	1007f793          	andi	a5,a5,256
    80002828:	e3b1                	bnez	a5,8000286c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282a:	00003797          	auipc	a5,0x3
    8000282e:	5f678793          	addi	a5,a5,1526 # 80005e20 <kernelvec>
    80002832:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002836:	fffff097          	auipc	ra,0xfffff
    8000283a:	190080e7          	jalr	400(ra) # 800019c6 <myproc>
    8000283e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002840:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002842:	14102773          	csrr	a4,sepc
    80002846:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002848:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000284c:	47a1                	li	a5,8
    8000284e:	02f70763          	beq	a4,a5,8000287c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002852:	00000097          	auipc	ra,0x0
    80002856:	f20080e7          	jalr	-224(ra) # 80002772 <devintr>
    8000285a:	892a                	mv	s2,a0
    8000285c:	c92d                	beqz	a0,800028ce <usertrap+0xba>
  if(killed(p))
    8000285e:	8526                	mv	a0,s1
    80002860:	00000097          	auipc	ra,0x0
    80002864:	ad2080e7          	jalr	-1326(ra) # 80002332 <killed>
    80002868:	c555                	beqz	a0,80002914 <usertrap+0x100>
    8000286a:	a045                	j	8000290a <usertrap+0xf6>
    panic("usertrap: not from user mode");
    8000286c:	00006517          	auipc	a0,0x6
    80002870:	ab450513          	addi	a0,a0,-1356 # 80008320 <states.1728+0x58>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	cd0080e7          	jalr	-816(ra) # 80000544 <panic>
    if(killed(p))
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	ab6080e7          	jalr	-1354(ra) # 80002332 <killed>
    80002884:	ed1d                	bnez	a0,800028c2 <usertrap+0xae>
    p->trapframe->epc += 4;
    80002886:	6cb8                	ld	a4,88(s1)
    80002888:	6f1c                	ld	a5,24(a4)
    8000288a:	0791                	addi	a5,a5,4
    8000288c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002892:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002896:	10079073          	csrw	sstatus,a5
    syscall();
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	336080e7          	jalr	822(ra) # 80002bd0 <syscall>
  if(killed(p))
    800028a2:	8526                	mv	a0,s1
    800028a4:	00000097          	auipc	ra,0x0
    800028a8:	a8e080e7          	jalr	-1394(ra) # 80002332 <killed>
    800028ac:	ed31                	bnez	a0,80002908 <usertrap+0xf4>
  usertrapret();
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	de8080e7          	jalr	-536(ra) # 80002696 <usertrapret>
}
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6902                	ld	s2,0(sp)
    800028be:	6105                	addi	sp,sp,32
    800028c0:	8082                	ret
      exit(-1);
    800028c2:	557d                	li	a0,-1
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	8fa080e7          	jalr	-1798(ra) # 800021be <exit>
    800028cc:	bf6d                	j	80002886 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028d2:	5890                	lw	a2,48(s1)
    800028d4:	00006517          	auipc	a0,0x6
    800028d8:	a6c50513          	addi	a0,a0,-1428 # 80008340 <states.1728+0x78>
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	cb2080e7          	jalr	-846(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028e8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	a8450513          	addi	a0,a0,-1404 # 80008370 <states.1728+0xa8>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c9a080e7          	jalr	-870(ra) # 8000058e <printf>
    setkilled(p);
    800028fc:	8526                	mv	a0,s1
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	a08080e7          	jalr	-1528(ra) # 80002306 <setkilled>
    80002906:	bf71                	j	800028a2 <usertrap+0x8e>
  if(killed(p))
    80002908:	4901                	li	s2,0
    exit(-1);
    8000290a:	557d                	li	a0,-1
    8000290c:	00000097          	auipc	ra,0x0
    80002910:	8b2080e7          	jalr	-1870(ra) # 800021be <exit>
  if(which_dev == 2){
    80002914:	4789                	li	a5,2
    80002916:	f8f91ce3          	bne	s2,a5,800028ae <usertrap+0x9a>
    if(p->ticklim>0 && !p->alarm_lock){
    8000291a:	1744a783          	lw	a5,372(s1)
    8000291e:	00f05e63          	blez	a5,8000293a <usertrap+0x126>
    80002922:	1704a703          	lw	a4,368(s1)
    80002926:	eb11                	bnez	a4,8000293a <usertrap+0x126>
      p->nticks++;
    80002928:	16c4a703          	lw	a4,364(s1)
    8000292c:	2705                	addiw	a4,a4,1
    8000292e:	0007069b          	sext.w	a3,a4
    80002932:	16e4a623          	sw	a4,364(s1)
      if(p->nticks==p->ticklim){
    80002936:	00d78763          	beq	a5,a3,80002944 <usertrap+0x130>
    yield();
    8000293a:	fffff097          	auipc	ra,0xfffff
    8000293e:	714080e7          	jalr	1812(ra) # 8000204e <yield>
    80002942:	b7b5                	j	800028ae <usertrap+0x9a>
        p->alarm_lock = 1;
    80002944:	4785                	li	a5,1
    80002946:	16f4a823          	sw	a5,368(s1)
        p->nticks = 0;
    8000294a:	1604a623          	sw	zero,364(s1)
        p->trapframecpy = (struct trapframe *)kalloc();
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	1ac080e7          	jalr	428(ra) # 80000afa <kalloc>
    80002956:	18a4b023          	sd	a0,384(s1)
        *(p->trapframecpy) = *(p->trapframe);
    8000295a:	6cbc                	ld	a5,88(s1)
    8000295c:	12078813          	addi	a6,a5,288
    80002960:	638c                	ld	a1,0(a5)
    80002962:	6790                	ld	a2,8(a5)
    80002964:	6b94                	ld	a3,16(a5)
    80002966:	6f98                	ld	a4,24(a5)
    80002968:	e10c                	sd	a1,0(a0)
    8000296a:	e510                	sd	a2,8(a0)
    8000296c:	e914                	sd	a3,16(a0)
    8000296e:	ed18                	sd	a4,24(a0)
    80002970:	02078793          	addi	a5,a5,32
    80002974:	02050513          	addi	a0,a0,32
    80002978:	ff0794e3          	bne	a5,a6,80002960 <usertrap+0x14c>
        p->trapframe->epc = p->fn;
    8000297c:	6cbc                	ld	a5,88(s1)
    8000297e:	1784b703          	ld	a4,376(s1)
    80002982:	ef98                	sd	a4,24(a5)
    80002984:	bf5d                	j	8000293a <usertrap+0x126>

0000000080002986 <kerneltrap>:
{
    80002986:	7179                	addi	sp,sp,-48
    80002988:	f406                	sd	ra,40(sp)
    8000298a:	f022                	sd	s0,32(sp)
    8000298c:	ec26                	sd	s1,24(sp)
    8000298e:	e84a                	sd	s2,16(sp)
    80002990:	e44e                	sd	s3,8(sp)
    80002992:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002994:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002998:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029a0:	1004f793          	andi	a5,s1,256
    800029a4:	cb85                	beqz	a5,800029d4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029aa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ac:	ef85                	bnez	a5,800029e4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	dc4080e7          	jalr	-572(ra) # 80002772 <devintr>
    800029b6:	cd1d                	beqz	a0,800029f4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b8:	4789                	li	a5,2
    800029ba:	06f50a63          	beq	a0,a5,80002a2e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029be:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c2:	10049073          	csrw	sstatus,s1
}
    800029c6:	70a2                	ld	ra,40(sp)
    800029c8:	7402                	ld	s0,32(sp)
    800029ca:	64e2                	ld	s1,24(sp)
    800029cc:	6942                	ld	s2,16(sp)
    800029ce:	69a2                	ld	s3,8(sp)
    800029d0:	6145                	addi	sp,sp,48
    800029d2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9bc50513          	addi	a0,a0,-1604 # 80008390 <states.1728+0xc8>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	b68080e7          	jalr	-1176(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	9d450513          	addi	a0,a0,-1580 # 800083b8 <states.1728+0xf0>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b58080e7          	jalr	-1192(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800029f4:	85ce                	mv	a1,s3
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	9e250513          	addi	a0,a0,-1566 # 800083d8 <states.1728+0x110>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b90080e7          	jalr	-1136(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	9da50513          	addi	a0,a0,-1574 # 800083e8 <states.1728+0x120>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b78080e7          	jalr	-1160(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a1e:	00006517          	auipc	a0,0x6
    80002a22:	9e250513          	addi	a0,a0,-1566 # 80008400 <states.1728+0x138>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b1e080e7          	jalr	-1250(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	f98080e7          	jalr	-104(ra) # 800019c6 <myproc>
    80002a36:	d541                	beqz	a0,800029be <kerneltrap+0x38>
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	f8e080e7          	jalr	-114(ra) # 800019c6 <myproc>
    80002a40:	4d18                	lw	a4,24(a0)
    80002a42:	4791                	li	a5,4
    80002a44:	f6f71de3          	bne	a4,a5,800029be <kerneltrap+0x38>
    yield();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	606080e7          	jalr	1542(ra) # 8000204e <yield>
    80002a50:	b7bd                	j	800029be <kerneltrap+0x38>

0000000080002a52 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	1000                	addi	s0,sp,32
    80002a5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	f68080e7          	jalr	-152(ra) # 800019c6 <myproc>
  switch (n) {
    80002a66:	4795                	li	a5,5
    80002a68:	0497e163          	bltu	a5,s1,80002aaa <argraw+0x58>
    80002a6c:	048a                	slli	s1,s1,0x2
    80002a6e:	00006717          	auipc	a4,0x6
    80002a72:	aca70713          	addi	a4,a4,-1334 # 80008538 <states.1728+0x270>
    80002a76:	94ba                	add	s1,s1,a4
    80002a78:	409c                	lw	a5,0(s1)
    80002a7a:	97ba                	add	a5,a5,a4
    80002a7c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	64a2                	ld	s1,8(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
    return p->trapframe->a1;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	7fa8                	ld	a0,120(a5)
    80002a90:	bfcd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a2;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	63c8                	ld	a0,128(a5)
    80002a96:	b7f5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a3;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	67c8                	ld	a0,136(a5)
    80002a9c:	b7dd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a4;
    80002a9e:	6d3c                	ld	a5,88(a0)
    80002aa0:	6bc8                	ld	a0,144(a5)
    80002aa2:	b7c5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a5;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	6fc8                	ld	a0,152(a5)
    80002aa8:	bfe9                	j	80002a82 <argraw+0x30>
  panic("argraw");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	96650513          	addi	a0,a0,-1690 # 80008410 <states.1728+0x148>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a92080e7          	jalr	-1390(ra) # 80000544 <panic>

0000000080002aba <fetchaddr>:
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	e04a                	sd	s2,0(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84aa                	mv	s1,a0
    80002ac8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	efc080e7          	jalr	-260(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ad2:	653c                	ld	a5,72(a0)
    80002ad4:	02f4f863          	bgeu	s1,a5,80002b04 <fetchaddr+0x4a>
    80002ad8:	00848713          	addi	a4,s1,8
    80002adc:	02e7e663          	bltu	a5,a4,80002b08 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ae0:	46a1                	li	a3,8
    80002ae2:	8626                	mv	a2,s1
    80002ae4:	85ca                	mv	a1,s2
    80002ae6:	6928                	ld	a0,80(a0)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	c28080e7          	jalr	-984(ra) # 80001710 <copyin>
    80002af0:	00a03533          	snez	a0,a0
    80002af4:	40a00533          	neg	a0,a0
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6902                	ld	s2,0(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret
    return -1;
    80002b04:	557d                	li	a0,-1
    80002b06:	bfcd                	j	80002af8 <fetchaddr+0x3e>
    80002b08:	557d                	li	a0,-1
    80002b0a:	b7fd                	j	80002af8 <fetchaddr+0x3e>

0000000080002b0c <fetchstr>:
{
    80002b0c:	7179                	addi	sp,sp,-48
    80002b0e:	f406                	sd	ra,40(sp)
    80002b10:	f022                	sd	s0,32(sp)
    80002b12:	ec26                	sd	s1,24(sp)
    80002b14:	e84a                	sd	s2,16(sp)
    80002b16:	e44e                	sd	s3,8(sp)
    80002b18:	1800                	addi	s0,sp,48
    80002b1a:	892a                	mv	s2,a0
    80002b1c:	84ae                	mv	s1,a1
    80002b1e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	ea6080e7          	jalr	-346(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b28:	86ce                	mv	a3,s3
    80002b2a:	864a                	mv	a2,s2
    80002b2c:	85a6                	mv	a1,s1
    80002b2e:	6928                	ld	a0,80(a0)
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	c6c080e7          	jalr	-916(ra) # 8000179c <copyinstr>
    80002b38:	00054e63          	bltz	a0,80002b54 <fetchstr+0x48>
  return strlen(buf);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	32c080e7          	jalr	812(ra) # 80000e6a <strlen>
}
    80002b46:	70a2                	ld	ra,40(sp)
    80002b48:	7402                	ld	s0,32(sp)
    80002b4a:	64e2                	ld	s1,24(sp)
    80002b4c:	6942                	ld	s2,16(sp)
    80002b4e:	69a2                	ld	s3,8(sp)
    80002b50:	6145                	addi	sp,sp,48
    80002b52:	8082                	ret
    return -1;
    80002b54:	557d                	li	a0,-1
    80002b56:	bfc5                	j	80002b46 <fetchstr+0x3a>

0000000080002b58 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	1000                	addi	s0,sp,32
    80002b62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b64:	00000097          	auipc	ra,0x0
    80002b68:	eee080e7          	jalr	-274(ra) # 80002a52 <argraw>
    80002b6c:	c088                	sw	a0,0(s1)
}
    80002b6e:	60e2                	ld	ra,24(sp)
    80002b70:	6442                	ld	s0,16(sp)
    80002b72:	64a2                	ld	s1,8(sp)
    80002b74:	6105                	addi	sp,sp,32
    80002b76:	8082                	ret

0000000080002b78 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b78:	1101                	addi	sp,sp,-32
    80002b7a:	ec06                	sd	ra,24(sp)
    80002b7c:	e822                	sd	s0,16(sp)
    80002b7e:	e426                	sd	s1,8(sp)
    80002b80:	1000                	addi	s0,sp,32
    80002b82:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	ece080e7          	jalr	-306(ra) # 80002a52 <argraw>
    80002b8c:	e088                	sd	a0,0(s1)
}
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6105                	addi	sp,sp,32
    80002b96:	8082                	ret

0000000080002b98 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b98:	7179                	addi	sp,sp,-48
    80002b9a:	f406                	sd	ra,40(sp)
    80002b9c:	f022                	sd	s0,32(sp)
    80002b9e:	ec26                	sd	s1,24(sp)
    80002ba0:	e84a                	sd	s2,16(sp)
    80002ba2:	1800                	addi	s0,sp,48
    80002ba4:	84ae                	mv	s1,a1
    80002ba6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ba8:	fd840593          	addi	a1,s0,-40
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	fcc080e7          	jalr	-52(ra) # 80002b78 <argaddr>
  return fetchstr(addr, buf, max);
    80002bb4:	864a                	mv	a2,s2
    80002bb6:	85a6                	mv	a1,s1
    80002bb8:	fd843503          	ld	a0,-40(s0)
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	f50080e7          	jalr	-176(ra) # 80002b0c <fetchstr>
}
    80002bc4:	70a2                	ld	ra,40(sp)
    80002bc6:	7402                	ld	s0,32(sp)
    80002bc8:	64e2                	ld	s1,24(sp)
    80002bca:	6942                	ld	s2,16(sp)
    80002bcc:	6145                	addi	sp,sp,48
    80002bce:	8082                	ret

0000000080002bd0 <syscall>:

};

void
syscall(void)
{
    80002bd0:	7139                	addi	sp,sp,-64
    80002bd2:	fc06                	sd	ra,56(sp)
    80002bd4:	f822                	sd	s0,48(sp)
    80002bd6:	f426                	sd	s1,40(sp)
    80002bd8:	f04a                	sd	s2,32(sp)
    80002bda:	ec4e                	sd	s3,24(sp)
    80002bdc:	e852                	sd	s4,16(sp)
    80002bde:	e456                	sd	s5,8(sp)
    80002be0:	e05a                	sd	s6,0(sp)
    80002be2:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	de2080e7          	jalr	-542(ra) # 800019c6 <myproc>
    80002bec:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bee:	05853903          	ld	s2,88(a0)
    80002bf2:	0a893783          	ld	a5,168(s2)
    80002bf6:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bfa:	37fd                	addiw	a5,a5,-1
    80002bfc:	475d                	li	a4,23
    80002bfe:	18f76e63          	bltu	a4,a5,80002d9a <syscall+0x1ca>
    80002c02:	00399713          	slli	a4,s3,0x3
    80002c06:	00006797          	auipc	a5,0x6
    80002c0a:	94a78793          	addi	a5,a5,-1718 # 80008550 <syscalls>
    80002c0e:	97ba                	add	a5,a5,a4
    80002c10:	0007ba83          	ld	s5,0(a5)
    80002c14:	180a8363          	beqz	s5,80002d9a <syscall+0x1ca>
    //check if strace is activated or  not
    // printf("%d\n",p->trac_stat);

    // printf("%d %s\n",(p->trac_stat) , sysnames[num]);

    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002c18:	47d9                	li	a5,22
    80002c1a:	04f98a63          	beq	s3,a5,80002c6e <syscall+0x9e>
    80002c1e:	16852783          	lw	a5,360(a0)
    80002c22:	4137d7bb          	sraw	a5,a5,s3
    80002c26:	8b85                	andi	a5,a5,1
    80002c28:	e3c1                	bnez	a5,80002ca8 <syscall+0xd8>

      if(num==SYS_exit){
        printf("\n");
      }
    }
    p->trapframe->a0 = syscalls[num]();
    80002c2a:	9a82                	jalr	s5
    80002c2c:	06a93823          	sd	a0,112(s2)

    //printing return value
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002c30:	1684a783          	lw	a5,360(s1)
    80002c34:	4137d7bb          	sraw	a5,a5,s3
    80002c38:	8b85                	andi	a5,a5,1
    80002c3a:	cb99                	beqz	a5,80002c50 <syscall+0x80>
      printf(" -> %d\n",p->trapframe->a0);
    80002c3c:	6cbc                	ld	a5,88(s1)
    80002c3e:	7bac                	ld	a1,112(a5)
    80002c40:	00006517          	auipc	a0,0x6
    80002c44:	80850513          	addi	a0,a0,-2040 # 80008448 <states.1728+0x180>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	946080e7          	jalr	-1722(ra) # 8000058e <printf>
    }

    if(num==SYS_sigreturn){
    80002c50:	47e1                	li	a5,24
    80002c52:	16f99363          	bne	s3,a5,80002db8 <syscall+0x1e8>
      p->trapframe->a0 = p->trapframecpy->a0;
    80002c56:	6cbc                	ld	a5,88(s1)
    80002c58:	1804b703          	ld	a4,384(s1)
    80002c5c:	7b38                	ld	a4,112(a4)
    80002c5e:	fbb8                	sd	a4,112(a5)
      kfree((void*)p->trapframecpy);
    80002c60:	1804b503          	ld	a0,384(s1)
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	d9a080e7          	jalr	-614(ra) # 800009fe <kfree>
    80002c6c:	a2b1                	j	80002db8 <syscall+0x1e8>
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002c6e:	4501                	li	a0,0
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	de2080e7          	jalr	-542(ra) # 80002a52 <argraw>
    80002c78:	02951793          	slli	a5,a0,0x29
    80002c7c:	1407c863          	bltz	a5,80002dcc <syscall+0x1fc>
    80002c80:	1684a783          	lw	a5,360(s1)
    80002c84:	02979713          	slli	a4,a5,0x29
    80002c88:	16075163          	bgez	a4,80002dea <syscall+0x21a>
      printf("%d: syscall %s (",p->pid,sysnames[num]);
    80002c8c:	00005617          	auipc	a2,0x5
    80002c90:	7e460613          	addi	a2,a2,2020 # 80008470 <states.1728+0x1a8>
    80002c94:	588c                	lw	a1,48(s1)
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	78250513          	addi	a0,a0,1922 # 80008418 <states.1728+0x150>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8f0080e7          	jalr	-1808(ra) # 8000058e <printf>
      if(sysargs[num]==0){
    80002ca6:	a281                	j	80002de6 <syscall+0x216>
      printf("%d: syscall %s (",p->pid,sysnames[num]);
    80002ca8:	00006917          	auipc	s2,0x6
    80002cac:	8a890913          	addi	s2,s2,-1880 # 80008550 <syscalls>
    80002cb0:	00399793          	slli	a5,s3,0x3
    80002cb4:	97ca                	add	a5,a5,s2
    80002cb6:	67f0                	ld	a2,200(a5)
    80002cb8:	588c                	lw	a1,48(s1)
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	75e50513          	addi	a0,a0,1886 # 80008418 <states.1728+0x150>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8cc080e7          	jalr	-1844(ra) # 8000058e <printf>
      if(sysargs[num]==0){
    80002cca:	00299793          	slli	a5,s3,0x2
    80002cce:	993e                	add	s2,s2,a5
    80002cd0:	19092a03          	lw	s4,400(s2)
    80002cd4:	060a0a63          	beqz	s4,80002d48 <syscall+0x178>
        for(int i=0;i<sysargs[num];i++){
    80002cd8:	03405563          	blez	s4,80002d02 <syscall+0x132>
{
    80002cdc:	4901                	li	s2,0
          printf("%d ",argraw(i));
    80002cde:	00005b17          	auipc	s6,0x5
    80002ce2:	75ab0b13          	addi	s6,s6,1882 # 80008438 <states.1728+0x170>
    80002ce6:	854a                	mv	a0,s2
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	d6a080e7          	jalr	-662(ra) # 80002a52 <argraw>
    80002cf0:	85aa                	mv	a1,a0
    80002cf2:	855a                	mv	a0,s6
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	89a080e7          	jalr	-1894(ra) # 8000058e <printf>
        for(int i=0;i<sysargs[num];i++){
    80002cfc:	2905                	addiw	s2,s2,1
    80002cfe:	ff4914e3          	bne	s2,s4,80002ce6 <syscall+0x116>
        printf("\b)");
    80002d02:	00005517          	auipc	a0,0x5
    80002d06:	73e50513          	addi	a0,a0,1854 # 80008440 <states.1728+0x178>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	884080e7          	jalr	-1916(ra) # 8000058e <printf>
      if(num==SYS_exit){
    80002d12:	4789                	li	a5,2
    80002d14:	04f98b63          	beq	s3,a5,80002d6a <syscall+0x19a>
    p->trapframe->a0 = syscalls[num]();
    80002d18:	0584b903          	ld	s2,88(s1)
    80002d1c:	9a82                	jalr	s5
    80002d1e:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002d22:	47d9                	li	a5,22
    80002d24:	f0f996e3          	bne	s3,a5,80002c30 <syscall+0x60>
    80002d28:	4501                	li	a0,0
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	d28080e7          	jalr	-728(ra) # 80002a52 <argraw>
    80002d32:	02951793          	slli	a5,a0,0x29
    80002d36:	f007c3e3          	bltz	a5,80002c3c <syscall+0x6c>
    80002d3a:	1684a783          	lw	a5,360(s1)
    80002d3e:	02979713          	slli	a4,a5,0x29
    80002d42:	ee074de3          	bltz	a4,80002c3c <syscall+0x6c>
    80002d46:	a88d                	j	80002db8 <syscall+0x1e8>
        printf(")");
    80002d48:	00005517          	auipc	a0,0x5
    80002d4c:	6e850513          	addi	a0,a0,1768 # 80008430 <states.1728+0x168>
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	83e080e7          	jalr	-1986(ra) # 8000058e <printf>
      if(num==SYS_exit){
    80002d58:	4789                	li	a5,2
    80002d5a:	00f98863          	beq	s3,a5,80002d6a <syscall+0x19a>
    p->trapframe->a0 = syscalls[num]();
    80002d5e:	0584b903          	ld	s2,88(s1)
    80002d62:	9a82                	jalr	s5
    80002d64:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002d68:	b5e1                	j	80002c30 <syscall+0x60>
        printf("\n");
    80002d6a:	00005517          	auipc	a0,0x5
    80002d6e:	35e50513          	addi	a0,a0,862 # 800080c8 <digits+0x88>
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	81c080e7          	jalr	-2020(ra) # 8000058e <printf>
    p->trapframe->a0 = syscalls[num]();
    80002d7a:	0584b903          	ld	s2,88(s1)
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	078080e7          	jalr	120(ra) # 80002df6 <sys_exit>
    80002d86:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002d8a:	1684a783          	lw	a5,360(s1)
    80002d8e:	4137d7bb          	sraw	a5,a5,s3
    80002d92:	8b85                	andi	a5,a5,1
    80002d94:	ea0794e3          	bnez	a5,80002c3c <syscall+0x6c>
    80002d98:	a005                	j	80002db8 <syscall+0x1e8>
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d9a:	86ce                	mv	a3,s3
    80002d9c:	15848613          	addi	a2,s1,344
    80002da0:	588c                	lw	a1,48(s1)
    80002da2:	00005517          	auipc	a0,0x5
    80002da6:	6ae50513          	addi	a0,a0,1710 # 80008450 <states.1728+0x188>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	7e4080e7          	jalr	2020(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002db2:	6cbc                	ld	a5,88(s1)
    80002db4:	577d                	li	a4,-1
    80002db6:	fbb8                	sd	a4,112(a5)
  }
}
    80002db8:	70e2                	ld	ra,56(sp)
    80002dba:	7442                	ld	s0,48(sp)
    80002dbc:	74a2                	ld	s1,40(sp)
    80002dbe:	7902                	ld	s2,32(sp)
    80002dc0:	69e2                	ld	s3,24(sp)
    80002dc2:	6a42                	ld	s4,16(sp)
    80002dc4:	6aa2                	ld	s5,8(sp)
    80002dc6:	6b02                	ld	s6,0(sp)
    80002dc8:	6121                	addi	sp,sp,64
    80002dca:	8082                	ret
      printf("%d: syscall %s (",p->pid,sysnames[num]);
    80002dcc:	00005617          	auipc	a2,0x5
    80002dd0:	6a460613          	addi	a2,a2,1700 # 80008470 <states.1728+0x1a8>
    80002dd4:	588c                	lw	a1,48(s1)
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	64250513          	addi	a0,a0,1602 # 80008418 <states.1728+0x150>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	7b0080e7          	jalr	1968(ra) # 8000058e <printf>
{
    80002de6:	4a05                	li	s4,1
    80002de8:	bdd5                	j	80002cdc <syscall+0x10c>
    p->trapframe->a0 = syscalls[num]();
    80002dea:	0584b903          	ld	s2,88(s1)
    80002dee:	9a82                	jalr	s5
    80002df0:	06a93823          	sd	a0,112(s2)
    if((num==SYS_trace && (argraw(0) & 1<<num)) || (p->trac_stat & 1<<num)){
    80002df4:	bf15                	j	80002d28 <syscall+0x158>

0000000080002df6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002df6:	1101                	addi	sp,sp,-32
    80002df8:	ec06                	sd	ra,24(sp)
    80002dfa:	e822                	sd	s0,16(sp)
    80002dfc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dfe:	fec40593          	addi	a1,s0,-20
    80002e02:	4501                	li	a0,0
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	d54080e7          	jalr	-684(ra) # 80002b58 <argint>
  exit(n);
    80002e0c:	fec42503          	lw	a0,-20(s0)
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	3ae080e7          	jalr	942(ra) # 800021be <exit>
  return 0;  // not reached
}
    80002e18:	4501                	li	a0,0
    80002e1a:	60e2                	ld	ra,24(sp)
    80002e1c:	6442                	ld	s0,16(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret

0000000080002e22 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e22:	1141                	addi	sp,sp,-16
    80002e24:	e406                	sd	ra,8(sp)
    80002e26:	e022                	sd	s0,0(sp)
    80002e28:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	b9c080e7          	jalr	-1124(ra) # 800019c6 <myproc>
}
    80002e32:	5908                	lw	a0,48(a0)
    80002e34:	60a2                	ld	ra,8(sp)
    80002e36:	6402                	ld	s0,0(sp)
    80002e38:	0141                	addi	sp,sp,16
    80002e3a:	8082                	ret

0000000080002e3c <sys_fork>:

uint64
sys_fork(void)
{
    80002e3c:	1141                	addi	sp,sp,-16
    80002e3e:	e406                	sd	ra,8(sp)
    80002e40:	e022                	sd	s0,0(sp)
    80002e42:	0800                	addi	s0,sp,16
  return fork();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	f58080e7          	jalr	-168(ra) # 80001d9c <fork>
}
    80002e4c:	60a2                	ld	ra,8(sp)
    80002e4e:	6402                	ld	s0,0(sp)
    80002e50:	0141                	addi	sp,sp,16
    80002e52:	8082                	ret

0000000080002e54 <sys_wait>:

uint64
sys_wait(void)
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e5c:	fe840593          	addi	a1,s0,-24
    80002e60:	4501                	li	a0,0
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	d16080e7          	jalr	-746(ra) # 80002b78 <argaddr>
  return wait(p);
    80002e6a:	fe843503          	ld	a0,-24(s0)
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	4f6080e7          	jalr	1270(ra) # 80002364 <wait>
}
    80002e76:	60e2                	ld	ra,24(sp)
    80002e78:	6442                	ld	s0,16(sp)
    80002e7a:	6105                	addi	sp,sp,32
    80002e7c:	8082                	ret

0000000080002e7e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e7e:	7179                	addi	sp,sp,-48
    80002e80:	f406                	sd	ra,40(sp)
    80002e82:	f022                	sd	s0,32(sp)
    80002e84:	ec26                	sd	s1,24(sp)
    80002e86:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e88:	fdc40593          	addi	a1,s0,-36
    80002e8c:	4501                	li	a0,0
    80002e8e:	00000097          	auipc	ra,0x0
    80002e92:	cca080e7          	jalr	-822(ra) # 80002b58 <argint>
  addr = myproc()->sz;
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	b30080e7          	jalr	-1232(ra) # 800019c6 <myproc>
    80002e9e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002ea0:	fdc42503          	lw	a0,-36(s0)
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	e9c080e7          	jalr	-356(ra) # 80001d40 <growproc>
    80002eac:	00054863          	bltz	a0,80002ebc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002eb0:	8526                	mv	a0,s1
    80002eb2:	70a2                	ld	ra,40(sp)
    80002eb4:	7402                	ld	s0,32(sp)
    80002eb6:	64e2                	ld	s1,24(sp)
    80002eb8:	6145                	addi	sp,sp,48
    80002eba:	8082                	ret
    return -1;
    80002ebc:	54fd                	li	s1,-1
    80002ebe:	bfcd                	j	80002eb0 <sys_sbrk+0x32>

0000000080002ec0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ec0:	7139                	addi	sp,sp,-64
    80002ec2:	fc06                	sd	ra,56(sp)
    80002ec4:	f822                	sd	s0,48(sp)
    80002ec6:	f426                	sd	s1,40(sp)
    80002ec8:	f04a                	sd	s2,32(sp)
    80002eca:	ec4e                	sd	s3,24(sp)
    80002ecc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ece:	fcc40593          	addi	a1,s0,-52
    80002ed2:	4501                	li	a0,0
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	c84080e7          	jalr	-892(ra) # 80002b58 <argint>
  acquire(&tickslock);
    80002edc:	00014517          	auipc	a0,0x14
    80002ee0:	4c450513          	addi	a0,a0,1220 # 800173a0 <tickslock>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	d06080e7          	jalr	-762(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002eec:	00006917          	auipc	s2,0x6
    80002ef0:	c1492903          	lw	s2,-1004(s2) # 80008b00 <ticks>
  while(ticks - ticks0 < n){
    80002ef4:	fcc42783          	lw	a5,-52(s0)
    80002ef8:	cf9d                	beqz	a5,80002f36 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002efa:	00014997          	auipc	s3,0x14
    80002efe:	4a698993          	addi	s3,s3,1190 # 800173a0 <tickslock>
    80002f02:	00006497          	auipc	s1,0x6
    80002f06:	bfe48493          	addi	s1,s1,-1026 # 80008b00 <ticks>
    if(killed(myproc())){
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	abc080e7          	jalr	-1348(ra) # 800019c6 <myproc>
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	420080e7          	jalr	1056(ra) # 80002332 <killed>
    80002f1a:	ed15                	bnez	a0,80002f56 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f1c:	85ce                	mv	a1,s3
    80002f1e:	8526                	mv	a0,s1
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	16a080e7          	jalr	362(ra) # 8000208a <sleep>
  while(ticks - ticks0 < n){
    80002f28:	409c                	lw	a5,0(s1)
    80002f2a:	412787bb          	subw	a5,a5,s2
    80002f2e:	fcc42703          	lw	a4,-52(s0)
    80002f32:	fce7ece3          	bltu	a5,a4,80002f0a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f36:	00014517          	auipc	a0,0x14
    80002f3a:	46a50513          	addi	a0,a0,1130 # 800173a0 <tickslock>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	d60080e7          	jalr	-672(ra) # 80000c9e <release>
  return 0;
    80002f46:	4501                	li	a0,0
}
    80002f48:	70e2                	ld	ra,56(sp)
    80002f4a:	7442                	ld	s0,48(sp)
    80002f4c:	74a2                	ld	s1,40(sp)
    80002f4e:	7902                	ld	s2,32(sp)
    80002f50:	69e2                	ld	s3,24(sp)
    80002f52:	6121                	addi	sp,sp,64
    80002f54:	8082                	ret
      release(&tickslock);
    80002f56:	00014517          	auipc	a0,0x14
    80002f5a:	44a50513          	addi	a0,a0,1098 # 800173a0 <tickslock>
    80002f5e:	ffffe097          	auipc	ra,0xffffe
    80002f62:	d40080e7          	jalr	-704(ra) # 80000c9e <release>
      return -1;
    80002f66:	557d                	li	a0,-1
    80002f68:	b7c5                	j	80002f48 <sys_sleep+0x88>

0000000080002f6a <sys_kill>:

uint64
sys_kill(void)
{
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f72:	fec40593          	addi	a1,s0,-20
    80002f76:	4501                	li	a0,0
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	be0080e7          	jalr	-1056(ra) # 80002b58 <argint>
  return kill(pid);
    80002f80:	fec42503          	lw	a0,-20(s0)
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	310080e7          	jalr	784(ra) # 80002294 <kill>
}
    80002f8c:	60e2                	ld	ra,24(sp)
    80002f8e:	6442                	ld	s0,16(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret

0000000080002f94 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	e426                	sd	s1,8(sp)
    80002f9c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f9e:	00014517          	auipc	a0,0x14
    80002fa2:	40250513          	addi	a0,a0,1026 # 800173a0 <tickslock>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	c44080e7          	jalr	-956(ra) # 80000bea <acquire>
  xticks = ticks;
    80002fae:	00006497          	auipc	s1,0x6
    80002fb2:	b524a483          	lw	s1,-1198(s1) # 80008b00 <ticks>
  release(&tickslock);
    80002fb6:	00014517          	auipc	a0,0x14
    80002fba:	3ea50513          	addi	a0,a0,1002 # 800173a0 <tickslock>
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	ce0080e7          	jalr	-800(ra) # 80000c9e <release>
  return xticks;
}
    80002fc6:	02049513          	slli	a0,s1,0x20
    80002fca:	9101                	srli	a0,a0,0x20
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	64a2                	ld	s1,8(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret

0000000080002fd6 <sys_trace>:

uint64
sys_trace(void){
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	1000                	addi	s0,sp,32
  int x;
  argint(0,&x);
    80002fde:	fec40593          	addi	a1,s0,-20
    80002fe2:	4501                	li	a0,0
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	b74080e7          	jalr	-1164(ra) # 80002b58 <argint>
  // printf("Syscall number: %d \n",x);
  
  myproc()->trac_stat = x;
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	9da080e7          	jalr	-1574(ra) # 800019c6 <myproc>
    80002ff4:	fec42783          	lw	a5,-20(s0)
    80002ff8:	16f52423          	sw	a5,360(a0)
  
  return 0;
}
    80002ffc:	4501                	li	a0,0
    80002ffe:	60e2                	ld	ra,24(sp)
    80003000:	6442                	ld	s0,16(sp)
    80003002:	6105                	addi	sp,sp,32
    80003004:	8082                	ret

0000000080003006 <sys_sigalarm>:

uint64
sys_sigalarm(void){
    80003006:	7179                	addi	sp,sp,-48
    80003008:	f406                	sd	ra,40(sp)
    8000300a:	f022                	sd	s0,32(sp)
    8000300c:	ec26                	sd	s1,24(sp)
    8000300e:	1800                	addi	s0,sp,48

  // printf("Alarm handler called\n");

  struct proc* p = myproc();
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	9b6080e7          	jalr	-1610(ra) # 800019c6 <myproc>
    80003018:	84aa                	mv	s1,a0
  
  int n;
  uint64 fn;

  argint(0, &n);
    8000301a:	fdc40593          	addi	a1,s0,-36
    8000301e:	4501                	li	a0,0
    80003020:	00000097          	auipc	ra,0x0
    80003024:	b38080e7          	jalr	-1224(ra) # 80002b58 <argint>
  argaddr(1,&fn);
    80003028:	fd040593          	addi	a1,s0,-48
    8000302c:	4505                	li	a0,1
    8000302e:	00000097          	auipc	ra,0x0
    80003032:	b4a080e7          	jalr	-1206(ra) # 80002b78 <argaddr>

  p->ticklim = n;
    80003036:	fdc42783          	lw	a5,-36(s0)
    8000303a:	16f4aa23          	sw	a5,372(s1)
  p->nticks = 0;
    8000303e:	1604a623          	sw	zero,364(s1)
  p->fn = fn;
    80003042:	fd043783          	ld	a5,-48(s0)
    80003046:	16f4bc23          	sd	a5,376(s1)

  return 0;

}
    8000304a:	4501                	li	a0,0
    8000304c:	70a2                	ld	ra,40(sp)
    8000304e:	7402                	ld	s0,32(sp)
    80003050:	64e2                	ld	s1,24(sp)
    80003052:	6145                	addi	sp,sp,48
    80003054:	8082                	ret

0000000080003056 <sys_sigreturn>:

uint64
sys_sigreturn(void){
    80003056:	1141                	addi	sp,sp,-16
    80003058:	e406                	sd	ra,8(sp)
    8000305a:	e022                	sd	s0,0(sp)
    8000305c:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    8000305e:	fffff097          	auipc	ra,0xfffff
    80003062:	968080e7          	jalr	-1688(ra) # 800019c6 <myproc>
  *(p->trapframe) = *(p->trapframecpy);
    80003066:	18053683          	ld	a3,384(a0)
    8000306a:	87b6                	mv	a5,a3
    8000306c:	6d38                	ld	a4,88(a0)
    8000306e:	12068693          	addi	a3,a3,288
    80003072:	0007b883          	ld	a7,0(a5)
    80003076:	0087b803          	ld	a6,8(a5)
    8000307a:	6b8c                	ld	a1,16(a5)
    8000307c:	6f90                	ld	a2,24(a5)
    8000307e:	01173023          	sd	a7,0(a4)
    80003082:	01073423          	sd	a6,8(a4)
    80003086:	eb0c                	sd	a1,16(a4)
    80003088:	ef10                	sd	a2,24(a4)
    8000308a:	02078793          	addi	a5,a5,32
    8000308e:	02070713          	addi	a4,a4,32
    80003092:	fed790e3          	bne	a5,a3,80003072 <sys_sigreturn+0x1c>
  // kfree((void*)p->trapframecpy);
  p->alarm_lock = 0;
    80003096:	16052823          	sw	zero,368(a0)
  return 0;
    8000309a:	4501                	li	a0,0
    8000309c:	60a2                	ld	ra,8(sp)
    8000309e:	6402                	ld	s0,0(sp)
    800030a0:	0141                	addi	sp,sp,16
    800030a2:	8082                	ret

00000000800030a4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030a4:	7179                	addi	sp,sp,-48
    800030a6:	f406                	sd	ra,40(sp)
    800030a8:	f022                	sd	s0,32(sp)
    800030aa:	ec26                	sd	s1,24(sp)
    800030ac:	e84a                	sd	s2,16(sp)
    800030ae:	e44e                	sd	s3,8(sp)
    800030b0:	e052                	sd	s4,0(sp)
    800030b2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030b4:	00005597          	auipc	a1,0x5
    800030b8:	69458593          	addi	a1,a1,1684 # 80008748 <sysargs+0x68>
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	2fc50513          	addi	a0,a0,764 # 800173b8 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	a96080e7          	jalr	-1386(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030cc:	0001c797          	auipc	a5,0x1c
    800030d0:	2ec78793          	addi	a5,a5,748 # 8001f3b8 <bcache+0x8000>
    800030d4:	0001c717          	auipc	a4,0x1c
    800030d8:	54c70713          	addi	a4,a4,1356 # 8001f620 <bcache+0x8268>
    800030dc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030e0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e4:	00014497          	auipc	s1,0x14
    800030e8:	2ec48493          	addi	s1,s1,748 # 800173d0 <bcache+0x18>
    b->next = bcache.head.next;
    800030ec:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030ee:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030f0:	00005a17          	auipc	s4,0x5
    800030f4:	660a0a13          	addi	s4,s4,1632 # 80008750 <sysargs+0x70>
    b->next = bcache.head.next;
    800030f8:	2b893783          	ld	a5,696(s2)
    800030fc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030fe:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003102:	85d2                	mv	a1,s4
    80003104:	01048513          	addi	a0,s1,16
    80003108:	00001097          	auipc	ra,0x1
    8000310c:	4c4080e7          	jalr	1220(ra) # 800045cc <initsleeplock>
    bcache.head.next->prev = b;
    80003110:	2b893783          	ld	a5,696(s2)
    80003114:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003116:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000311a:	45848493          	addi	s1,s1,1112
    8000311e:	fd349de3          	bne	s1,s3,800030f8 <binit+0x54>
  }
}
    80003122:	70a2                	ld	ra,40(sp)
    80003124:	7402                	ld	s0,32(sp)
    80003126:	64e2                	ld	s1,24(sp)
    80003128:	6942                	ld	s2,16(sp)
    8000312a:	69a2                	ld	s3,8(sp)
    8000312c:	6a02                	ld	s4,0(sp)
    8000312e:	6145                	addi	sp,sp,48
    80003130:	8082                	ret

0000000080003132 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003132:	7179                	addi	sp,sp,-48
    80003134:	f406                	sd	ra,40(sp)
    80003136:	f022                	sd	s0,32(sp)
    80003138:	ec26                	sd	s1,24(sp)
    8000313a:	e84a                	sd	s2,16(sp)
    8000313c:	e44e                	sd	s3,8(sp)
    8000313e:	1800                	addi	s0,sp,48
    80003140:	89aa                	mv	s3,a0
    80003142:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003144:	00014517          	auipc	a0,0x14
    80003148:	27450513          	addi	a0,a0,628 # 800173b8 <bcache>
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	a9e080e7          	jalr	-1378(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003154:	0001c497          	auipc	s1,0x1c
    80003158:	51c4b483          	ld	s1,1308(s1) # 8001f670 <bcache+0x82b8>
    8000315c:	0001c797          	auipc	a5,0x1c
    80003160:	4c478793          	addi	a5,a5,1220 # 8001f620 <bcache+0x8268>
    80003164:	02f48f63          	beq	s1,a5,800031a2 <bread+0x70>
    80003168:	873e                	mv	a4,a5
    8000316a:	a021                	j	80003172 <bread+0x40>
    8000316c:	68a4                	ld	s1,80(s1)
    8000316e:	02e48a63          	beq	s1,a4,800031a2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003172:	449c                	lw	a5,8(s1)
    80003174:	ff379ce3          	bne	a5,s3,8000316c <bread+0x3a>
    80003178:	44dc                	lw	a5,12(s1)
    8000317a:	ff2799e3          	bne	a5,s2,8000316c <bread+0x3a>
      b->refcnt++;
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	2785                	addiw	a5,a5,1
    80003182:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	23450513          	addi	a0,a0,564 # 800173b8 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	b12080e7          	jalr	-1262(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003194:	01048513          	addi	a0,s1,16
    80003198:	00001097          	auipc	ra,0x1
    8000319c:	46e080e7          	jalr	1134(ra) # 80004606 <acquiresleep>
      return b;
    800031a0:	a8b9                	j	800031fe <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031a2:	0001c497          	auipc	s1,0x1c
    800031a6:	4c64b483          	ld	s1,1222(s1) # 8001f668 <bcache+0x82b0>
    800031aa:	0001c797          	auipc	a5,0x1c
    800031ae:	47678793          	addi	a5,a5,1142 # 8001f620 <bcache+0x8268>
    800031b2:	00f48863          	beq	s1,a5,800031c2 <bread+0x90>
    800031b6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031b8:	40bc                	lw	a5,64(s1)
    800031ba:	cf81                	beqz	a5,800031d2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031bc:	64a4                	ld	s1,72(s1)
    800031be:	fee49de3          	bne	s1,a4,800031b8 <bread+0x86>
  panic("bget: no buffers");
    800031c2:	00005517          	auipc	a0,0x5
    800031c6:	59650513          	addi	a0,a0,1430 # 80008758 <sysargs+0x78>
    800031ca:	ffffd097          	auipc	ra,0xffffd
    800031ce:	37a080e7          	jalr	890(ra) # 80000544 <panic>
      b->dev = dev;
    800031d2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031d6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031da:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031de:	4785                	li	a5,1
    800031e0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031e2:	00014517          	auipc	a0,0x14
    800031e6:	1d650513          	addi	a0,a0,470 # 800173b8 <bcache>
    800031ea:	ffffe097          	auipc	ra,0xffffe
    800031ee:	ab4080e7          	jalr	-1356(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800031f2:	01048513          	addi	a0,s1,16
    800031f6:	00001097          	auipc	ra,0x1
    800031fa:	410080e7          	jalr	1040(ra) # 80004606 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031fe:	409c                	lw	a5,0(s1)
    80003200:	cb89                	beqz	a5,80003212 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003202:	8526                	mv	a0,s1
    80003204:	70a2                	ld	ra,40(sp)
    80003206:	7402                	ld	s0,32(sp)
    80003208:	64e2                	ld	s1,24(sp)
    8000320a:	6942                	ld	s2,16(sp)
    8000320c:	69a2                	ld	s3,8(sp)
    8000320e:	6145                	addi	sp,sp,48
    80003210:	8082                	ret
    virtio_disk_rw(b, 0);
    80003212:	4581                	li	a1,0
    80003214:	8526                	mv	a0,s1
    80003216:	00003097          	auipc	ra,0x3
    8000321a:	fd2080e7          	jalr	-46(ra) # 800061e8 <virtio_disk_rw>
    b->valid = 1;
    8000321e:	4785                	li	a5,1
    80003220:	c09c                	sw	a5,0(s1)
  return b;
    80003222:	b7c5                	j	80003202 <bread+0xd0>

0000000080003224 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003224:	1101                	addi	sp,sp,-32
    80003226:	ec06                	sd	ra,24(sp)
    80003228:	e822                	sd	s0,16(sp)
    8000322a:	e426                	sd	s1,8(sp)
    8000322c:	1000                	addi	s0,sp,32
    8000322e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003230:	0541                	addi	a0,a0,16
    80003232:	00001097          	auipc	ra,0x1
    80003236:	46e080e7          	jalr	1134(ra) # 800046a0 <holdingsleep>
    8000323a:	cd01                	beqz	a0,80003252 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000323c:	4585                	li	a1,1
    8000323e:	8526                	mv	a0,s1
    80003240:	00003097          	auipc	ra,0x3
    80003244:	fa8080e7          	jalr	-88(ra) # 800061e8 <virtio_disk_rw>
}
    80003248:	60e2                	ld	ra,24(sp)
    8000324a:	6442                	ld	s0,16(sp)
    8000324c:	64a2                	ld	s1,8(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret
    panic("bwrite");
    80003252:	00005517          	auipc	a0,0x5
    80003256:	51e50513          	addi	a0,a0,1310 # 80008770 <sysargs+0x90>
    8000325a:	ffffd097          	auipc	ra,0xffffd
    8000325e:	2ea080e7          	jalr	746(ra) # 80000544 <panic>

0000000080003262 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003262:	1101                	addi	sp,sp,-32
    80003264:	ec06                	sd	ra,24(sp)
    80003266:	e822                	sd	s0,16(sp)
    80003268:	e426                	sd	s1,8(sp)
    8000326a:	e04a                	sd	s2,0(sp)
    8000326c:	1000                	addi	s0,sp,32
    8000326e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003270:	01050913          	addi	s2,a0,16
    80003274:	854a                	mv	a0,s2
    80003276:	00001097          	auipc	ra,0x1
    8000327a:	42a080e7          	jalr	1066(ra) # 800046a0 <holdingsleep>
    8000327e:	c92d                	beqz	a0,800032f0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003280:	854a                	mv	a0,s2
    80003282:	00001097          	auipc	ra,0x1
    80003286:	3da080e7          	jalr	986(ra) # 8000465c <releasesleep>

  acquire(&bcache.lock);
    8000328a:	00014517          	auipc	a0,0x14
    8000328e:	12e50513          	addi	a0,a0,302 # 800173b8 <bcache>
    80003292:	ffffe097          	auipc	ra,0xffffe
    80003296:	958080e7          	jalr	-1704(ra) # 80000bea <acquire>
  b->refcnt--;
    8000329a:	40bc                	lw	a5,64(s1)
    8000329c:	37fd                	addiw	a5,a5,-1
    8000329e:	0007871b          	sext.w	a4,a5
    800032a2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032a4:	eb05                	bnez	a4,800032d4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032a6:	68bc                	ld	a5,80(s1)
    800032a8:	64b8                	ld	a4,72(s1)
    800032aa:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032ac:	64bc                	ld	a5,72(s1)
    800032ae:	68b8                	ld	a4,80(s1)
    800032b0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032b2:	0001c797          	auipc	a5,0x1c
    800032b6:	10678793          	addi	a5,a5,262 # 8001f3b8 <bcache+0x8000>
    800032ba:	2b87b703          	ld	a4,696(a5)
    800032be:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032c0:	0001c717          	auipc	a4,0x1c
    800032c4:	36070713          	addi	a4,a4,864 # 8001f620 <bcache+0x8268>
    800032c8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032ca:	2b87b703          	ld	a4,696(a5)
    800032ce:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032d0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032d4:	00014517          	auipc	a0,0x14
    800032d8:	0e450513          	addi	a0,a0,228 # 800173b8 <bcache>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	9c2080e7          	jalr	-1598(ra) # 80000c9e <release>
}
    800032e4:	60e2                	ld	ra,24(sp)
    800032e6:	6442                	ld	s0,16(sp)
    800032e8:	64a2                	ld	s1,8(sp)
    800032ea:	6902                	ld	s2,0(sp)
    800032ec:	6105                	addi	sp,sp,32
    800032ee:	8082                	ret
    panic("brelse");
    800032f0:	00005517          	auipc	a0,0x5
    800032f4:	48850513          	addi	a0,a0,1160 # 80008778 <sysargs+0x98>
    800032f8:	ffffd097          	auipc	ra,0xffffd
    800032fc:	24c080e7          	jalr	588(ra) # 80000544 <panic>

0000000080003300 <bpin>:

void
bpin(struct buf *b) {
    80003300:	1101                	addi	sp,sp,-32
    80003302:	ec06                	sd	ra,24(sp)
    80003304:	e822                	sd	s0,16(sp)
    80003306:	e426                	sd	s1,8(sp)
    80003308:	1000                	addi	s0,sp,32
    8000330a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000330c:	00014517          	auipc	a0,0x14
    80003310:	0ac50513          	addi	a0,a0,172 # 800173b8 <bcache>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	8d6080e7          	jalr	-1834(ra) # 80000bea <acquire>
  b->refcnt++;
    8000331c:	40bc                	lw	a5,64(s1)
    8000331e:	2785                	addiw	a5,a5,1
    80003320:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003322:	00014517          	auipc	a0,0x14
    80003326:	09650513          	addi	a0,a0,150 # 800173b8 <bcache>
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	974080e7          	jalr	-1676(ra) # 80000c9e <release>
}
    80003332:	60e2                	ld	ra,24(sp)
    80003334:	6442                	ld	s0,16(sp)
    80003336:	64a2                	ld	s1,8(sp)
    80003338:	6105                	addi	sp,sp,32
    8000333a:	8082                	ret

000000008000333c <bunpin>:

void
bunpin(struct buf *b) {
    8000333c:	1101                	addi	sp,sp,-32
    8000333e:	ec06                	sd	ra,24(sp)
    80003340:	e822                	sd	s0,16(sp)
    80003342:	e426                	sd	s1,8(sp)
    80003344:	1000                	addi	s0,sp,32
    80003346:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003348:	00014517          	auipc	a0,0x14
    8000334c:	07050513          	addi	a0,a0,112 # 800173b8 <bcache>
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	89a080e7          	jalr	-1894(ra) # 80000bea <acquire>
  b->refcnt--;
    80003358:	40bc                	lw	a5,64(s1)
    8000335a:	37fd                	addiw	a5,a5,-1
    8000335c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000335e:	00014517          	auipc	a0,0x14
    80003362:	05a50513          	addi	a0,a0,90 # 800173b8 <bcache>
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	938080e7          	jalr	-1736(ra) # 80000c9e <release>
}
    8000336e:	60e2                	ld	ra,24(sp)
    80003370:	6442                	ld	s0,16(sp)
    80003372:	64a2                	ld	s1,8(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret

0000000080003378 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	e426                	sd	s1,8(sp)
    80003380:	e04a                	sd	s2,0(sp)
    80003382:	1000                	addi	s0,sp,32
    80003384:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003386:	00d5d59b          	srliw	a1,a1,0xd
    8000338a:	0001c797          	auipc	a5,0x1c
    8000338e:	70a7a783          	lw	a5,1802(a5) # 8001fa94 <sb+0x1c>
    80003392:	9dbd                	addw	a1,a1,a5
    80003394:	00000097          	auipc	ra,0x0
    80003398:	d9e080e7          	jalr	-610(ra) # 80003132 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000339c:	0074f713          	andi	a4,s1,7
    800033a0:	4785                	li	a5,1
    800033a2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033a6:	14ce                	slli	s1,s1,0x33
    800033a8:	90d9                	srli	s1,s1,0x36
    800033aa:	00950733          	add	a4,a0,s1
    800033ae:	05874703          	lbu	a4,88(a4)
    800033b2:	00e7f6b3          	and	a3,a5,a4
    800033b6:	c69d                	beqz	a3,800033e4 <bfree+0x6c>
    800033b8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033ba:	94aa                	add	s1,s1,a0
    800033bc:	fff7c793          	not	a5,a5
    800033c0:	8ff9                	and	a5,a5,a4
    800033c2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033c6:	00001097          	auipc	ra,0x1
    800033ca:	120080e7          	jalr	288(ra) # 800044e6 <log_write>
  brelse(bp);
    800033ce:	854a                	mv	a0,s2
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	e92080e7          	jalr	-366(ra) # 80003262 <brelse>
}
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	64a2                	ld	s1,8(sp)
    800033de:	6902                	ld	s2,0(sp)
    800033e0:	6105                	addi	sp,sp,32
    800033e2:	8082                	ret
    panic("freeing free block");
    800033e4:	00005517          	auipc	a0,0x5
    800033e8:	39c50513          	addi	a0,a0,924 # 80008780 <sysargs+0xa0>
    800033ec:	ffffd097          	auipc	ra,0xffffd
    800033f0:	158080e7          	jalr	344(ra) # 80000544 <panic>

00000000800033f4 <balloc>:
{
    800033f4:	711d                	addi	sp,sp,-96
    800033f6:	ec86                	sd	ra,88(sp)
    800033f8:	e8a2                	sd	s0,80(sp)
    800033fa:	e4a6                	sd	s1,72(sp)
    800033fc:	e0ca                	sd	s2,64(sp)
    800033fe:	fc4e                	sd	s3,56(sp)
    80003400:	f852                	sd	s4,48(sp)
    80003402:	f456                	sd	s5,40(sp)
    80003404:	f05a                	sd	s6,32(sp)
    80003406:	ec5e                	sd	s7,24(sp)
    80003408:	e862                	sd	s8,16(sp)
    8000340a:	e466                	sd	s9,8(sp)
    8000340c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000340e:	0001c797          	auipc	a5,0x1c
    80003412:	66e7a783          	lw	a5,1646(a5) # 8001fa7c <sb+0x4>
    80003416:	10078163          	beqz	a5,80003518 <balloc+0x124>
    8000341a:	8baa                	mv	s7,a0
    8000341c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000341e:	0001cb17          	auipc	s6,0x1c
    80003422:	65ab0b13          	addi	s6,s6,1626 # 8001fa78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003426:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003428:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000342a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000342c:	6c89                	lui	s9,0x2
    8000342e:	a061                	j	800034b6 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003430:	974a                	add	a4,a4,s2
    80003432:	8fd5                	or	a5,a5,a3
    80003434:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003438:	854a                	mv	a0,s2
    8000343a:	00001097          	auipc	ra,0x1
    8000343e:	0ac080e7          	jalr	172(ra) # 800044e6 <log_write>
        brelse(bp);
    80003442:	854a                	mv	a0,s2
    80003444:	00000097          	auipc	ra,0x0
    80003448:	e1e080e7          	jalr	-482(ra) # 80003262 <brelse>
  bp = bread(dev, bno);
    8000344c:	85a6                	mv	a1,s1
    8000344e:	855e                	mv	a0,s7
    80003450:	00000097          	auipc	ra,0x0
    80003454:	ce2080e7          	jalr	-798(ra) # 80003132 <bread>
    80003458:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000345a:	40000613          	li	a2,1024
    8000345e:	4581                	li	a1,0
    80003460:	05850513          	addi	a0,a0,88
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	882080e7          	jalr	-1918(ra) # 80000ce6 <memset>
  log_write(bp);
    8000346c:	854a                	mv	a0,s2
    8000346e:	00001097          	auipc	ra,0x1
    80003472:	078080e7          	jalr	120(ra) # 800044e6 <log_write>
  brelse(bp);
    80003476:	854a                	mv	a0,s2
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	dea080e7          	jalr	-534(ra) # 80003262 <brelse>
}
    80003480:	8526                	mv	a0,s1
    80003482:	60e6                	ld	ra,88(sp)
    80003484:	6446                	ld	s0,80(sp)
    80003486:	64a6                	ld	s1,72(sp)
    80003488:	6906                	ld	s2,64(sp)
    8000348a:	79e2                	ld	s3,56(sp)
    8000348c:	7a42                	ld	s4,48(sp)
    8000348e:	7aa2                	ld	s5,40(sp)
    80003490:	7b02                	ld	s6,32(sp)
    80003492:	6be2                	ld	s7,24(sp)
    80003494:	6c42                	ld	s8,16(sp)
    80003496:	6ca2                	ld	s9,8(sp)
    80003498:	6125                	addi	sp,sp,96
    8000349a:	8082                	ret
    brelse(bp);
    8000349c:	854a                	mv	a0,s2
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	dc4080e7          	jalr	-572(ra) # 80003262 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034a6:	015c87bb          	addw	a5,s9,s5
    800034aa:	00078a9b          	sext.w	s5,a5
    800034ae:	004b2703          	lw	a4,4(s6)
    800034b2:	06eaf363          	bgeu	s5,a4,80003518 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800034b6:	41fad79b          	sraiw	a5,s5,0x1f
    800034ba:	0137d79b          	srliw	a5,a5,0x13
    800034be:	015787bb          	addw	a5,a5,s5
    800034c2:	40d7d79b          	sraiw	a5,a5,0xd
    800034c6:	01cb2583          	lw	a1,28(s6)
    800034ca:	9dbd                	addw	a1,a1,a5
    800034cc:	855e                	mv	a0,s7
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	c64080e7          	jalr	-924(ra) # 80003132 <bread>
    800034d6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d8:	004b2503          	lw	a0,4(s6)
    800034dc:	000a849b          	sext.w	s1,s5
    800034e0:	8662                	mv	a2,s8
    800034e2:	faa4fde3          	bgeu	s1,a0,8000349c <balloc+0xa8>
      m = 1 << (bi % 8);
    800034e6:	41f6579b          	sraiw	a5,a2,0x1f
    800034ea:	01d7d69b          	srliw	a3,a5,0x1d
    800034ee:	00c6873b          	addw	a4,a3,a2
    800034f2:	00777793          	andi	a5,a4,7
    800034f6:	9f95                	subw	a5,a5,a3
    800034f8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034fc:	4037571b          	sraiw	a4,a4,0x3
    80003500:	00e906b3          	add	a3,s2,a4
    80003504:	0586c683          	lbu	a3,88(a3)
    80003508:	00d7f5b3          	and	a1,a5,a3
    8000350c:	d195                	beqz	a1,80003430 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000350e:	2605                	addiw	a2,a2,1
    80003510:	2485                	addiw	s1,s1,1
    80003512:	fd4618e3          	bne	a2,s4,800034e2 <balloc+0xee>
    80003516:	b759                	j	8000349c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003518:	00005517          	auipc	a0,0x5
    8000351c:	28050513          	addi	a0,a0,640 # 80008798 <sysargs+0xb8>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	06e080e7          	jalr	110(ra) # 8000058e <printf>
  return 0;
    80003528:	4481                	li	s1,0
    8000352a:	bf99                	j	80003480 <balloc+0x8c>

000000008000352c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	e052                	sd	s4,0(sp)
    8000353a:	1800                	addi	s0,sp,48
    8000353c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000353e:	47ad                	li	a5,11
    80003540:	02b7e763          	bltu	a5,a1,8000356e <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003544:	02059493          	slli	s1,a1,0x20
    80003548:	9081                	srli	s1,s1,0x20
    8000354a:	048a                	slli	s1,s1,0x2
    8000354c:	94aa                	add	s1,s1,a0
    8000354e:	0504a903          	lw	s2,80(s1)
    80003552:	06091e63          	bnez	s2,800035ce <bmap+0xa2>
      addr = balloc(ip->dev);
    80003556:	4108                	lw	a0,0(a0)
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	e9c080e7          	jalr	-356(ra) # 800033f4 <balloc>
    80003560:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003564:	06090563          	beqz	s2,800035ce <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003568:	0524a823          	sw	s2,80(s1)
    8000356c:	a08d                	j	800035ce <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000356e:	ff45849b          	addiw	s1,a1,-12
    80003572:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003576:	0ff00793          	li	a5,255
    8000357a:	08e7e563          	bltu	a5,a4,80003604 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000357e:	08052903          	lw	s2,128(a0)
    80003582:	00091d63          	bnez	s2,8000359c <bmap+0x70>
      addr = balloc(ip->dev);
    80003586:	4108                	lw	a0,0(a0)
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	e6c080e7          	jalr	-404(ra) # 800033f4 <balloc>
    80003590:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003594:	02090d63          	beqz	s2,800035ce <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003598:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000359c:	85ca                	mv	a1,s2
    8000359e:	0009a503          	lw	a0,0(s3)
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	b90080e7          	jalr	-1136(ra) # 80003132 <bread>
    800035aa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035ac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b0:	02049593          	slli	a1,s1,0x20
    800035b4:	9181                	srli	a1,a1,0x20
    800035b6:	058a                	slli	a1,a1,0x2
    800035b8:	00b784b3          	add	s1,a5,a1
    800035bc:	0004a903          	lw	s2,0(s1)
    800035c0:	02090063          	beqz	s2,800035e0 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035c4:	8552                	mv	a0,s4
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	c9c080e7          	jalr	-868(ra) # 80003262 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ce:	854a                	mv	a0,s2
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6942                	ld	s2,16(sp)
    800035d8:	69a2                	ld	s3,8(sp)
    800035da:	6a02                	ld	s4,0(sp)
    800035dc:	6145                	addi	sp,sp,48
    800035de:	8082                	ret
      addr = balloc(ip->dev);
    800035e0:	0009a503          	lw	a0,0(s3)
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	e10080e7          	jalr	-496(ra) # 800033f4 <balloc>
    800035ec:	0005091b          	sext.w	s2,a0
      if(addr){
    800035f0:	fc090ae3          	beqz	s2,800035c4 <bmap+0x98>
        a[bn] = addr;
    800035f4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035f8:	8552                	mv	a0,s4
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	eec080e7          	jalr	-276(ra) # 800044e6 <log_write>
    80003602:	b7c9                	j	800035c4 <bmap+0x98>
  panic("bmap: out of range");
    80003604:	00005517          	auipc	a0,0x5
    80003608:	1ac50513          	addi	a0,a0,428 # 800087b0 <sysargs+0xd0>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f38080e7          	jalr	-200(ra) # 80000544 <panic>

0000000080003614 <iget>:
{
    80003614:	7179                	addi	sp,sp,-48
    80003616:	f406                	sd	ra,40(sp)
    80003618:	f022                	sd	s0,32(sp)
    8000361a:	ec26                	sd	s1,24(sp)
    8000361c:	e84a                	sd	s2,16(sp)
    8000361e:	e44e                	sd	s3,8(sp)
    80003620:	e052                	sd	s4,0(sp)
    80003622:	1800                	addi	s0,sp,48
    80003624:	89aa                	mv	s3,a0
    80003626:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003628:	0001c517          	auipc	a0,0x1c
    8000362c:	47050513          	addi	a0,a0,1136 # 8001fa98 <itable>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	5ba080e7          	jalr	1466(ra) # 80000bea <acquire>
  empty = 0;
    80003638:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000363a:	0001c497          	auipc	s1,0x1c
    8000363e:	47648493          	addi	s1,s1,1142 # 8001fab0 <itable+0x18>
    80003642:	0001e697          	auipc	a3,0x1e
    80003646:	efe68693          	addi	a3,a3,-258 # 80021540 <log>
    8000364a:	a039                	j	80003658 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000364c:	02090b63          	beqz	s2,80003682 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003650:	08848493          	addi	s1,s1,136
    80003654:	02d48a63          	beq	s1,a3,80003688 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003658:	449c                	lw	a5,8(s1)
    8000365a:	fef059e3          	blez	a5,8000364c <iget+0x38>
    8000365e:	4098                	lw	a4,0(s1)
    80003660:	ff3716e3          	bne	a4,s3,8000364c <iget+0x38>
    80003664:	40d8                	lw	a4,4(s1)
    80003666:	ff4713e3          	bne	a4,s4,8000364c <iget+0x38>
      ip->ref++;
    8000366a:	2785                	addiw	a5,a5,1
    8000366c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000366e:	0001c517          	auipc	a0,0x1c
    80003672:	42a50513          	addi	a0,a0,1066 # 8001fa98 <itable>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	628080e7          	jalr	1576(ra) # 80000c9e <release>
      return ip;
    8000367e:	8926                	mv	s2,s1
    80003680:	a03d                	j	800036ae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003682:	f7f9                	bnez	a5,80003650 <iget+0x3c>
    80003684:	8926                	mv	s2,s1
    80003686:	b7e9                	j	80003650 <iget+0x3c>
  if(empty == 0)
    80003688:	02090c63          	beqz	s2,800036c0 <iget+0xac>
  ip->dev = dev;
    8000368c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003690:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003694:	4785                	li	a5,1
    80003696:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000369a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000369e:	0001c517          	auipc	a0,0x1c
    800036a2:	3fa50513          	addi	a0,a0,1018 # 8001fa98 <itable>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	5f8080e7          	jalr	1528(ra) # 80000c9e <release>
}
    800036ae:	854a                	mv	a0,s2
    800036b0:	70a2                	ld	ra,40(sp)
    800036b2:	7402                	ld	s0,32(sp)
    800036b4:	64e2                	ld	s1,24(sp)
    800036b6:	6942                	ld	s2,16(sp)
    800036b8:	69a2                	ld	s3,8(sp)
    800036ba:	6a02                	ld	s4,0(sp)
    800036bc:	6145                	addi	sp,sp,48
    800036be:	8082                	ret
    panic("iget: no inodes");
    800036c0:	00005517          	auipc	a0,0x5
    800036c4:	10850513          	addi	a0,a0,264 # 800087c8 <sysargs+0xe8>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	e7c080e7          	jalr	-388(ra) # 80000544 <panic>

00000000800036d0 <fsinit>:
fsinit(int dev) {
    800036d0:	7179                	addi	sp,sp,-48
    800036d2:	f406                	sd	ra,40(sp)
    800036d4:	f022                	sd	s0,32(sp)
    800036d6:	ec26                	sd	s1,24(sp)
    800036d8:	e84a                	sd	s2,16(sp)
    800036da:	e44e                	sd	s3,8(sp)
    800036dc:	1800                	addi	s0,sp,48
    800036de:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036e0:	4585                	li	a1,1
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	a50080e7          	jalr	-1456(ra) # 80003132 <bread>
    800036ea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036ec:	0001c997          	auipc	s3,0x1c
    800036f0:	38c98993          	addi	s3,s3,908 # 8001fa78 <sb>
    800036f4:	02000613          	li	a2,32
    800036f8:	05850593          	addi	a1,a0,88
    800036fc:	854e                	mv	a0,s3
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	648080e7          	jalr	1608(ra) # 80000d46 <memmove>
  brelse(bp);
    80003706:	8526                	mv	a0,s1
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	b5a080e7          	jalr	-1190(ra) # 80003262 <brelse>
  if(sb.magic != FSMAGIC)
    80003710:	0009a703          	lw	a4,0(s3)
    80003714:	102037b7          	lui	a5,0x10203
    80003718:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000371c:	02f71263          	bne	a4,a5,80003740 <fsinit+0x70>
  initlog(dev, &sb);
    80003720:	0001c597          	auipc	a1,0x1c
    80003724:	35858593          	addi	a1,a1,856 # 8001fa78 <sb>
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	b40080e7          	jalr	-1216(ra) # 8000426a <initlog>
}
    80003732:	70a2                	ld	ra,40(sp)
    80003734:	7402                	ld	s0,32(sp)
    80003736:	64e2                	ld	s1,24(sp)
    80003738:	6942                	ld	s2,16(sp)
    8000373a:	69a2                	ld	s3,8(sp)
    8000373c:	6145                	addi	sp,sp,48
    8000373e:	8082                	ret
    panic("invalid file system");
    80003740:	00005517          	auipc	a0,0x5
    80003744:	09850513          	addi	a0,a0,152 # 800087d8 <sysargs+0xf8>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	dfc080e7          	jalr	-516(ra) # 80000544 <panic>

0000000080003750 <iinit>:
{
    80003750:	7179                	addi	sp,sp,-48
    80003752:	f406                	sd	ra,40(sp)
    80003754:	f022                	sd	s0,32(sp)
    80003756:	ec26                	sd	s1,24(sp)
    80003758:	e84a                	sd	s2,16(sp)
    8000375a:	e44e                	sd	s3,8(sp)
    8000375c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000375e:	00005597          	auipc	a1,0x5
    80003762:	09258593          	addi	a1,a1,146 # 800087f0 <sysargs+0x110>
    80003766:	0001c517          	auipc	a0,0x1c
    8000376a:	33250513          	addi	a0,a0,818 # 8001fa98 <itable>
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	3ec080e7          	jalr	1004(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003776:	0001c497          	auipc	s1,0x1c
    8000377a:	34a48493          	addi	s1,s1,842 # 8001fac0 <itable+0x28>
    8000377e:	0001e997          	auipc	s3,0x1e
    80003782:	dd298993          	addi	s3,s3,-558 # 80021550 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003786:	00005917          	auipc	s2,0x5
    8000378a:	07290913          	addi	s2,s2,114 # 800087f8 <sysargs+0x118>
    8000378e:	85ca                	mv	a1,s2
    80003790:	8526                	mv	a0,s1
    80003792:	00001097          	auipc	ra,0x1
    80003796:	e3a080e7          	jalr	-454(ra) # 800045cc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000379a:	08848493          	addi	s1,s1,136
    8000379e:	ff3498e3          	bne	s1,s3,8000378e <iinit+0x3e>
}
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6145                	addi	sp,sp,48
    800037ae:	8082                	ret

00000000800037b0 <ialloc>:
{
    800037b0:	715d                	addi	sp,sp,-80
    800037b2:	e486                	sd	ra,72(sp)
    800037b4:	e0a2                	sd	s0,64(sp)
    800037b6:	fc26                	sd	s1,56(sp)
    800037b8:	f84a                	sd	s2,48(sp)
    800037ba:	f44e                	sd	s3,40(sp)
    800037bc:	f052                	sd	s4,32(sp)
    800037be:	ec56                	sd	s5,24(sp)
    800037c0:	e85a                	sd	s6,16(sp)
    800037c2:	e45e                	sd	s7,8(sp)
    800037c4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037c6:	0001c717          	auipc	a4,0x1c
    800037ca:	2be72703          	lw	a4,702(a4) # 8001fa84 <sb+0xc>
    800037ce:	4785                	li	a5,1
    800037d0:	04e7fa63          	bgeu	a5,a4,80003824 <ialloc+0x74>
    800037d4:	8aaa                	mv	s5,a0
    800037d6:	8bae                	mv	s7,a1
    800037d8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037da:	0001ca17          	auipc	s4,0x1c
    800037de:	29ea0a13          	addi	s4,s4,670 # 8001fa78 <sb>
    800037e2:	00048b1b          	sext.w	s6,s1
    800037e6:	0044d593          	srli	a1,s1,0x4
    800037ea:	018a2783          	lw	a5,24(s4)
    800037ee:	9dbd                	addw	a1,a1,a5
    800037f0:	8556                	mv	a0,s5
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	940080e7          	jalr	-1728(ra) # 80003132 <bread>
    800037fa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037fc:	05850993          	addi	s3,a0,88
    80003800:	00f4f793          	andi	a5,s1,15
    80003804:	079a                	slli	a5,a5,0x6
    80003806:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003808:	00099783          	lh	a5,0(s3)
    8000380c:	c3a1                	beqz	a5,8000384c <ialloc+0x9c>
    brelse(bp);
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	a54080e7          	jalr	-1452(ra) # 80003262 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003816:	0485                	addi	s1,s1,1
    80003818:	00ca2703          	lw	a4,12(s4)
    8000381c:	0004879b          	sext.w	a5,s1
    80003820:	fce7e1e3          	bltu	a5,a4,800037e2 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003824:	00005517          	auipc	a0,0x5
    80003828:	fdc50513          	addi	a0,a0,-36 # 80008800 <sysargs+0x120>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	d62080e7          	jalr	-670(ra) # 8000058e <printf>
  return 0;
    80003834:	4501                	li	a0,0
}
    80003836:	60a6                	ld	ra,72(sp)
    80003838:	6406                	ld	s0,64(sp)
    8000383a:	74e2                	ld	s1,56(sp)
    8000383c:	7942                	ld	s2,48(sp)
    8000383e:	79a2                	ld	s3,40(sp)
    80003840:	7a02                	ld	s4,32(sp)
    80003842:	6ae2                	ld	s5,24(sp)
    80003844:	6b42                	ld	s6,16(sp)
    80003846:	6ba2                	ld	s7,8(sp)
    80003848:	6161                	addi	sp,sp,80
    8000384a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000384c:	04000613          	li	a2,64
    80003850:	4581                	li	a1,0
    80003852:	854e                	mv	a0,s3
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	492080e7          	jalr	1170(ra) # 80000ce6 <memset>
      dip->type = type;
    8000385c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003860:	854a                	mv	a0,s2
    80003862:	00001097          	auipc	ra,0x1
    80003866:	c84080e7          	jalr	-892(ra) # 800044e6 <log_write>
      brelse(bp);
    8000386a:	854a                	mv	a0,s2
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	9f6080e7          	jalr	-1546(ra) # 80003262 <brelse>
      return iget(dev, inum);
    80003874:	85da                	mv	a1,s6
    80003876:	8556                	mv	a0,s5
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	d9c080e7          	jalr	-612(ra) # 80003614 <iget>
    80003880:	bf5d                	j	80003836 <ialloc+0x86>

0000000080003882 <iupdate>:
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	e04a                	sd	s2,0(sp)
    8000388c:	1000                	addi	s0,sp,32
    8000388e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003890:	415c                	lw	a5,4(a0)
    80003892:	0047d79b          	srliw	a5,a5,0x4
    80003896:	0001c597          	auipc	a1,0x1c
    8000389a:	1fa5a583          	lw	a1,506(a1) # 8001fa90 <sb+0x18>
    8000389e:	9dbd                	addw	a1,a1,a5
    800038a0:	4108                	lw	a0,0(a0)
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	890080e7          	jalr	-1904(ra) # 80003132 <bread>
    800038aa:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ac:	05850793          	addi	a5,a0,88
    800038b0:	40c8                	lw	a0,4(s1)
    800038b2:	893d                	andi	a0,a0,15
    800038b4:	051a                	slli	a0,a0,0x6
    800038b6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038b8:	04449703          	lh	a4,68(s1)
    800038bc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038c0:	04649703          	lh	a4,70(s1)
    800038c4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038c8:	04849703          	lh	a4,72(s1)
    800038cc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038d0:	04a49703          	lh	a4,74(s1)
    800038d4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038d8:	44f8                	lw	a4,76(s1)
    800038da:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038dc:	03400613          	li	a2,52
    800038e0:	05048593          	addi	a1,s1,80
    800038e4:	0531                	addi	a0,a0,12
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	460080e7          	jalr	1120(ra) # 80000d46 <memmove>
  log_write(bp);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00001097          	auipc	ra,0x1
    800038f4:	bf6080e7          	jalr	-1034(ra) # 800044e6 <log_write>
  brelse(bp);
    800038f8:	854a                	mv	a0,s2
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	968080e7          	jalr	-1688(ra) # 80003262 <brelse>
}
    80003902:	60e2                	ld	ra,24(sp)
    80003904:	6442                	ld	s0,16(sp)
    80003906:	64a2                	ld	s1,8(sp)
    80003908:	6902                	ld	s2,0(sp)
    8000390a:	6105                	addi	sp,sp,32
    8000390c:	8082                	ret

000000008000390e <idup>:
{
    8000390e:	1101                	addi	sp,sp,-32
    80003910:	ec06                	sd	ra,24(sp)
    80003912:	e822                	sd	s0,16(sp)
    80003914:	e426                	sd	s1,8(sp)
    80003916:	1000                	addi	s0,sp,32
    80003918:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000391a:	0001c517          	auipc	a0,0x1c
    8000391e:	17e50513          	addi	a0,a0,382 # 8001fa98 <itable>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	2c8080e7          	jalr	712(ra) # 80000bea <acquire>
  ip->ref++;
    8000392a:	449c                	lw	a5,8(s1)
    8000392c:	2785                	addiw	a5,a5,1
    8000392e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003930:	0001c517          	auipc	a0,0x1c
    80003934:	16850513          	addi	a0,a0,360 # 8001fa98 <itable>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	366080e7          	jalr	870(ra) # 80000c9e <release>
}
    80003940:	8526                	mv	a0,s1
    80003942:	60e2                	ld	ra,24(sp)
    80003944:	6442                	ld	s0,16(sp)
    80003946:	64a2                	ld	s1,8(sp)
    80003948:	6105                	addi	sp,sp,32
    8000394a:	8082                	ret

000000008000394c <ilock>:
{
    8000394c:	1101                	addi	sp,sp,-32
    8000394e:	ec06                	sd	ra,24(sp)
    80003950:	e822                	sd	s0,16(sp)
    80003952:	e426                	sd	s1,8(sp)
    80003954:	e04a                	sd	s2,0(sp)
    80003956:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003958:	c115                	beqz	a0,8000397c <ilock+0x30>
    8000395a:	84aa                	mv	s1,a0
    8000395c:	451c                	lw	a5,8(a0)
    8000395e:	00f05f63          	blez	a5,8000397c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003962:	0541                	addi	a0,a0,16
    80003964:	00001097          	auipc	ra,0x1
    80003968:	ca2080e7          	jalr	-862(ra) # 80004606 <acquiresleep>
  if(ip->valid == 0){
    8000396c:	40bc                	lw	a5,64(s1)
    8000396e:	cf99                	beqz	a5,8000398c <ilock+0x40>
}
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6902                	ld	s2,0(sp)
    80003978:	6105                	addi	sp,sp,32
    8000397a:	8082                	ret
    panic("ilock");
    8000397c:	00005517          	auipc	a0,0x5
    80003980:	e9c50513          	addi	a0,a0,-356 # 80008818 <sysargs+0x138>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	bc0080e7          	jalr	-1088(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000398c:	40dc                	lw	a5,4(s1)
    8000398e:	0047d79b          	srliw	a5,a5,0x4
    80003992:	0001c597          	auipc	a1,0x1c
    80003996:	0fe5a583          	lw	a1,254(a1) # 8001fa90 <sb+0x18>
    8000399a:	9dbd                	addw	a1,a1,a5
    8000399c:	4088                	lw	a0,0(s1)
    8000399e:	fffff097          	auipc	ra,0xfffff
    800039a2:	794080e7          	jalr	1940(ra) # 80003132 <bread>
    800039a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039a8:	05850593          	addi	a1,a0,88
    800039ac:	40dc                	lw	a5,4(s1)
    800039ae:	8bbd                	andi	a5,a5,15
    800039b0:	079a                	slli	a5,a5,0x6
    800039b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039b4:	00059783          	lh	a5,0(a1)
    800039b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039bc:	00259783          	lh	a5,2(a1)
    800039c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039c4:	00459783          	lh	a5,4(a1)
    800039c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039cc:	00659783          	lh	a5,6(a1)
    800039d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039d4:	459c                	lw	a5,8(a1)
    800039d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039d8:	03400613          	li	a2,52
    800039dc:	05b1                	addi	a1,a1,12
    800039de:	05048513          	addi	a0,s1,80
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	364080e7          	jalr	868(ra) # 80000d46 <memmove>
    brelse(bp);
    800039ea:	854a                	mv	a0,s2
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	876080e7          	jalr	-1930(ra) # 80003262 <brelse>
    ip->valid = 1;
    800039f4:	4785                	li	a5,1
    800039f6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039f8:	04449783          	lh	a5,68(s1)
    800039fc:	fbb5                	bnez	a5,80003970 <ilock+0x24>
      panic("ilock: no type");
    800039fe:	00005517          	auipc	a0,0x5
    80003a02:	e2250513          	addi	a0,a0,-478 # 80008820 <sysargs+0x140>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	b3e080e7          	jalr	-1218(ra) # 80000544 <panic>

0000000080003a0e <iunlock>:
{
    80003a0e:	1101                	addi	sp,sp,-32
    80003a10:	ec06                	sd	ra,24(sp)
    80003a12:	e822                	sd	s0,16(sp)
    80003a14:	e426                	sd	s1,8(sp)
    80003a16:	e04a                	sd	s2,0(sp)
    80003a18:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a1a:	c905                	beqz	a0,80003a4a <iunlock+0x3c>
    80003a1c:	84aa                	mv	s1,a0
    80003a1e:	01050913          	addi	s2,a0,16
    80003a22:	854a                	mv	a0,s2
    80003a24:	00001097          	auipc	ra,0x1
    80003a28:	c7c080e7          	jalr	-900(ra) # 800046a0 <holdingsleep>
    80003a2c:	cd19                	beqz	a0,80003a4a <iunlock+0x3c>
    80003a2e:	449c                	lw	a5,8(s1)
    80003a30:	00f05d63          	blez	a5,80003a4a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a34:	854a                	mv	a0,s2
    80003a36:	00001097          	auipc	ra,0x1
    80003a3a:	c26080e7          	jalr	-986(ra) # 8000465c <releasesleep>
}
    80003a3e:	60e2                	ld	ra,24(sp)
    80003a40:	6442                	ld	s0,16(sp)
    80003a42:	64a2                	ld	s1,8(sp)
    80003a44:	6902                	ld	s2,0(sp)
    80003a46:	6105                	addi	sp,sp,32
    80003a48:	8082                	ret
    panic("iunlock");
    80003a4a:	00005517          	auipc	a0,0x5
    80003a4e:	de650513          	addi	a0,a0,-538 # 80008830 <sysargs+0x150>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	af2080e7          	jalr	-1294(ra) # 80000544 <panic>

0000000080003a5a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a5a:	7179                	addi	sp,sp,-48
    80003a5c:	f406                	sd	ra,40(sp)
    80003a5e:	f022                	sd	s0,32(sp)
    80003a60:	ec26                	sd	s1,24(sp)
    80003a62:	e84a                	sd	s2,16(sp)
    80003a64:	e44e                	sd	s3,8(sp)
    80003a66:	e052                	sd	s4,0(sp)
    80003a68:	1800                	addi	s0,sp,48
    80003a6a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a6c:	05050493          	addi	s1,a0,80
    80003a70:	08050913          	addi	s2,a0,128
    80003a74:	a021                	j	80003a7c <itrunc+0x22>
    80003a76:	0491                	addi	s1,s1,4
    80003a78:	01248d63          	beq	s1,s2,80003a92 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a7c:	408c                	lw	a1,0(s1)
    80003a7e:	dde5                	beqz	a1,80003a76 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a80:	0009a503          	lw	a0,0(s3)
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	8f4080e7          	jalr	-1804(ra) # 80003378 <bfree>
      ip->addrs[i] = 0;
    80003a8c:	0004a023          	sw	zero,0(s1)
    80003a90:	b7dd                	j	80003a76 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a92:	0809a583          	lw	a1,128(s3)
    80003a96:	e185                	bnez	a1,80003ab6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a98:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a9c:	854e                	mv	a0,s3
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	de4080e7          	jalr	-540(ra) # 80003882 <iupdate>
}
    80003aa6:	70a2                	ld	ra,40(sp)
    80003aa8:	7402                	ld	s0,32(sp)
    80003aaa:	64e2                	ld	s1,24(sp)
    80003aac:	6942                	ld	s2,16(sp)
    80003aae:	69a2                	ld	s3,8(sp)
    80003ab0:	6a02                	ld	s4,0(sp)
    80003ab2:	6145                	addi	sp,sp,48
    80003ab4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ab6:	0009a503          	lw	a0,0(s3)
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	678080e7          	jalr	1656(ra) # 80003132 <bread>
    80003ac2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ac4:	05850493          	addi	s1,a0,88
    80003ac8:	45850913          	addi	s2,a0,1112
    80003acc:	a811                	j	80003ae0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ace:	0009a503          	lw	a0,0(s3)
    80003ad2:	00000097          	auipc	ra,0x0
    80003ad6:	8a6080e7          	jalr	-1882(ra) # 80003378 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ada:	0491                	addi	s1,s1,4
    80003adc:	01248563          	beq	s1,s2,80003ae6 <itrunc+0x8c>
      if(a[j])
    80003ae0:	408c                	lw	a1,0(s1)
    80003ae2:	dde5                	beqz	a1,80003ada <itrunc+0x80>
    80003ae4:	b7ed                	j	80003ace <itrunc+0x74>
    brelse(bp);
    80003ae6:	8552                	mv	a0,s4
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	77a080e7          	jalr	1914(ra) # 80003262 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003af0:	0809a583          	lw	a1,128(s3)
    80003af4:	0009a503          	lw	a0,0(s3)
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	880080e7          	jalr	-1920(ra) # 80003378 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b00:	0809a023          	sw	zero,128(s3)
    80003b04:	bf51                	j	80003a98 <itrunc+0x3e>

0000000080003b06 <iput>:
{
    80003b06:	1101                	addi	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	e426                	sd	s1,8(sp)
    80003b0e:	e04a                	sd	s2,0(sp)
    80003b10:	1000                	addi	s0,sp,32
    80003b12:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b14:	0001c517          	auipc	a0,0x1c
    80003b18:	f8450513          	addi	a0,a0,-124 # 8001fa98 <itable>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	0ce080e7          	jalr	206(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b24:	4498                	lw	a4,8(s1)
    80003b26:	4785                	li	a5,1
    80003b28:	02f70363          	beq	a4,a5,80003b4e <iput+0x48>
  ip->ref--;
    80003b2c:	449c                	lw	a5,8(s1)
    80003b2e:	37fd                	addiw	a5,a5,-1
    80003b30:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b32:	0001c517          	auipc	a0,0x1c
    80003b36:	f6650513          	addi	a0,a0,-154 # 8001fa98 <itable>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	164080e7          	jalr	356(ra) # 80000c9e <release>
}
    80003b42:	60e2                	ld	ra,24(sp)
    80003b44:	6442                	ld	s0,16(sp)
    80003b46:	64a2                	ld	s1,8(sp)
    80003b48:	6902                	ld	s2,0(sp)
    80003b4a:	6105                	addi	sp,sp,32
    80003b4c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b4e:	40bc                	lw	a5,64(s1)
    80003b50:	dff1                	beqz	a5,80003b2c <iput+0x26>
    80003b52:	04a49783          	lh	a5,74(s1)
    80003b56:	fbf9                	bnez	a5,80003b2c <iput+0x26>
    acquiresleep(&ip->lock);
    80003b58:	01048913          	addi	s2,s1,16
    80003b5c:	854a                	mv	a0,s2
    80003b5e:	00001097          	auipc	ra,0x1
    80003b62:	aa8080e7          	jalr	-1368(ra) # 80004606 <acquiresleep>
    release(&itable.lock);
    80003b66:	0001c517          	auipc	a0,0x1c
    80003b6a:	f3250513          	addi	a0,a0,-206 # 8001fa98 <itable>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	130080e7          	jalr	304(ra) # 80000c9e <release>
    itrunc(ip);
    80003b76:	8526                	mv	a0,s1
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	ee2080e7          	jalr	-286(ra) # 80003a5a <itrunc>
    ip->type = 0;
    80003b80:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b84:	8526                	mv	a0,s1
    80003b86:	00000097          	auipc	ra,0x0
    80003b8a:	cfc080e7          	jalr	-772(ra) # 80003882 <iupdate>
    ip->valid = 0;
    80003b8e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	ac8080e7          	jalr	-1336(ra) # 8000465c <releasesleep>
    acquire(&itable.lock);
    80003b9c:	0001c517          	auipc	a0,0x1c
    80003ba0:	efc50513          	addi	a0,a0,-260 # 8001fa98 <itable>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	046080e7          	jalr	70(ra) # 80000bea <acquire>
    80003bac:	b741                	j	80003b2c <iput+0x26>

0000000080003bae <iunlockput>:
{
    80003bae:	1101                	addi	sp,sp,-32
    80003bb0:	ec06                	sd	ra,24(sp)
    80003bb2:	e822                	sd	s0,16(sp)
    80003bb4:	e426                	sd	s1,8(sp)
    80003bb6:	1000                	addi	s0,sp,32
    80003bb8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	e54080e7          	jalr	-428(ra) # 80003a0e <iunlock>
  iput(ip);
    80003bc2:	8526                	mv	a0,s1
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	f42080e7          	jalr	-190(ra) # 80003b06 <iput>
}
    80003bcc:	60e2                	ld	ra,24(sp)
    80003bce:	6442                	ld	s0,16(sp)
    80003bd0:	64a2                	ld	s1,8(sp)
    80003bd2:	6105                	addi	sp,sp,32
    80003bd4:	8082                	ret

0000000080003bd6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bd6:	1141                	addi	sp,sp,-16
    80003bd8:	e422                	sd	s0,8(sp)
    80003bda:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bdc:	411c                	lw	a5,0(a0)
    80003bde:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003be0:	415c                	lw	a5,4(a0)
    80003be2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003be4:	04451783          	lh	a5,68(a0)
    80003be8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bec:	04a51783          	lh	a5,74(a0)
    80003bf0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bf4:	04c56783          	lwu	a5,76(a0)
    80003bf8:	e99c                	sd	a5,16(a1)
}
    80003bfa:	6422                	ld	s0,8(sp)
    80003bfc:	0141                	addi	sp,sp,16
    80003bfe:	8082                	ret

0000000080003c00 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c00:	457c                	lw	a5,76(a0)
    80003c02:	0ed7e963          	bltu	a5,a3,80003cf4 <readi+0xf4>
{
    80003c06:	7159                	addi	sp,sp,-112
    80003c08:	f486                	sd	ra,104(sp)
    80003c0a:	f0a2                	sd	s0,96(sp)
    80003c0c:	eca6                	sd	s1,88(sp)
    80003c0e:	e8ca                	sd	s2,80(sp)
    80003c10:	e4ce                	sd	s3,72(sp)
    80003c12:	e0d2                	sd	s4,64(sp)
    80003c14:	fc56                	sd	s5,56(sp)
    80003c16:	f85a                	sd	s6,48(sp)
    80003c18:	f45e                	sd	s7,40(sp)
    80003c1a:	f062                	sd	s8,32(sp)
    80003c1c:	ec66                	sd	s9,24(sp)
    80003c1e:	e86a                	sd	s10,16(sp)
    80003c20:	e46e                	sd	s11,8(sp)
    80003c22:	1880                	addi	s0,sp,112
    80003c24:	8b2a                	mv	s6,a0
    80003c26:	8bae                	mv	s7,a1
    80003c28:	8a32                	mv	s4,a2
    80003c2a:	84b6                	mv	s1,a3
    80003c2c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c2e:	9f35                	addw	a4,a4,a3
    return 0;
    80003c30:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c32:	0ad76063          	bltu	a4,a3,80003cd2 <readi+0xd2>
  if(off + n > ip->size)
    80003c36:	00e7f463          	bgeu	a5,a4,80003c3e <readi+0x3e>
    n = ip->size - off;
    80003c3a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c3e:	0a0a8963          	beqz	s5,80003cf0 <readi+0xf0>
    80003c42:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c44:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c48:	5c7d                	li	s8,-1
    80003c4a:	a82d                	j	80003c84 <readi+0x84>
    80003c4c:	020d1d93          	slli	s11,s10,0x20
    80003c50:	020ddd93          	srli	s11,s11,0x20
    80003c54:	05890613          	addi	a2,s2,88
    80003c58:	86ee                	mv	a3,s11
    80003c5a:	963a                	add	a2,a2,a4
    80003c5c:	85d2                	mv	a1,s4
    80003c5e:	855e                	mv	a0,s7
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	832080e7          	jalr	-1998(ra) # 80002492 <either_copyout>
    80003c68:	05850d63          	beq	a0,s8,80003cc2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c6c:	854a                	mv	a0,s2
    80003c6e:	fffff097          	auipc	ra,0xfffff
    80003c72:	5f4080e7          	jalr	1524(ra) # 80003262 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c76:	013d09bb          	addw	s3,s10,s3
    80003c7a:	009d04bb          	addw	s1,s10,s1
    80003c7e:	9a6e                	add	s4,s4,s11
    80003c80:	0559f763          	bgeu	s3,s5,80003cce <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c84:	00a4d59b          	srliw	a1,s1,0xa
    80003c88:	855a                	mv	a0,s6
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	8a2080e7          	jalr	-1886(ra) # 8000352c <bmap>
    80003c92:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c96:	cd85                	beqz	a1,80003cce <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c98:	000b2503          	lw	a0,0(s6)
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	496080e7          	jalr	1174(ra) # 80003132 <bread>
    80003ca4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca6:	3ff4f713          	andi	a4,s1,1023
    80003caa:	40ec87bb          	subw	a5,s9,a4
    80003cae:	413a86bb          	subw	a3,s5,s3
    80003cb2:	8d3e                	mv	s10,a5
    80003cb4:	2781                	sext.w	a5,a5
    80003cb6:	0006861b          	sext.w	a2,a3
    80003cba:	f8f679e3          	bgeu	a2,a5,80003c4c <readi+0x4c>
    80003cbe:	8d36                	mv	s10,a3
    80003cc0:	b771                	j	80003c4c <readi+0x4c>
      brelse(bp);
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	59e080e7          	jalr	1438(ra) # 80003262 <brelse>
      tot = -1;
    80003ccc:	59fd                	li	s3,-1
  }
  return tot;
    80003cce:	0009851b          	sext.w	a0,s3
}
    80003cd2:	70a6                	ld	ra,104(sp)
    80003cd4:	7406                	ld	s0,96(sp)
    80003cd6:	64e6                	ld	s1,88(sp)
    80003cd8:	6946                	ld	s2,80(sp)
    80003cda:	69a6                	ld	s3,72(sp)
    80003cdc:	6a06                	ld	s4,64(sp)
    80003cde:	7ae2                	ld	s5,56(sp)
    80003ce0:	7b42                	ld	s6,48(sp)
    80003ce2:	7ba2                	ld	s7,40(sp)
    80003ce4:	7c02                	ld	s8,32(sp)
    80003ce6:	6ce2                	ld	s9,24(sp)
    80003ce8:	6d42                	ld	s10,16(sp)
    80003cea:	6da2                	ld	s11,8(sp)
    80003cec:	6165                	addi	sp,sp,112
    80003cee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf0:	89d6                	mv	s3,s5
    80003cf2:	bff1                	j	80003cce <readi+0xce>
    return 0;
    80003cf4:	4501                	li	a0,0
}
    80003cf6:	8082                	ret

0000000080003cf8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cf8:	457c                	lw	a5,76(a0)
    80003cfa:	10d7e863          	bltu	a5,a3,80003e0a <writei+0x112>
{
    80003cfe:	7159                	addi	sp,sp,-112
    80003d00:	f486                	sd	ra,104(sp)
    80003d02:	f0a2                	sd	s0,96(sp)
    80003d04:	eca6                	sd	s1,88(sp)
    80003d06:	e8ca                	sd	s2,80(sp)
    80003d08:	e4ce                	sd	s3,72(sp)
    80003d0a:	e0d2                	sd	s4,64(sp)
    80003d0c:	fc56                	sd	s5,56(sp)
    80003d0e:	f85a                	sd	s6,48(sp)
    80003d10:	f45e                	sd	s7,40(sp)
    80003d12:	f062                	sd	s8,32(sp)
    80003d14:	ec66                	sd	s9,24(sp)
    80003d16:	e86a                	sd	s10,16(sp)
    80003d18:	e46e                	sd	s11,8(sp)
    80003d1a:	1880                	addi	s0,sp,112
    80003d1c:	8aaa                	mv	s5,a0
    80003d1e:	8bae                	mv	s7,a1
    80003d20:	8a32                	mv	s4,a2
    80003d22:	8936                	mv	s2,a3
    80003d24:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d26:	00e687bb          	addw	a5,a3,a4
    80003d2a:	0ed7e263          	bltu	a5,a3,80003e0e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d2e:	00043737          	lui	a4,0x43
    80003d32:	0ef76063          	bltu	a4,a5,80003e12 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d36:	0c0b0863          	beqz	s6,80003e06 <writei+0x10e>
    80003d3a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d40:	5c7d                	li	s8,-1
    80003d42:	a091                	j	80003d86 <writei+0x8e>
    80003d44:	020d1d93          	slli	s11,s10,0x20
    80003d48:	020ddd93          	srli	s11,s11,0x20
    80003d4c:	05848513          	addi	a0,s1,88
    80003d50:	86ee                	mv	a3,s11
    80003d52:	8652                	mv	a2,s4
    80003d54:	85de                	mv	a1,s7
    80003d56:	953a                	add	a0,a0,a4
    80003d58:	ffffe097          	auipc	ra,0xffffe
    80003d5c:	790080e7          	jalr	1936(ra) # 800024e8 <either_copyin>
    80003d60:	07850263          	beq	a0,s8,80003dc4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d64:	8526                	mv	a0,s1
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	780080e7          	jalr	1920(ra) # 800044e6 <log_write>
    brelse(bp);
    80003d6e:	8526                	mv	a0,s1
    80003d70:	fffff097          	auipc	ra,0xfffff
    80003d74:	4f2080e7          	jalr	1266(ra) # 80003262 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d78:	013d09bb          	addw	s3,s10,s3
    80003d7c:	012d093b          	addw	s2,s10,s2
    80003d80:	9a6e                	add	s4,s4,s11
    80003d82:	0569f663          	bgeu	s3,s6,80003dce <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d86:	00a9559b          	srliw	a1,s2,0xa
    80003d8a:	8556                	mv	a0,s5
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	7a0080e7          	jalr	1952(ra) # 8000352c <bmap>
    80003d94:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d98:	c99d                	beqz	a1,80003dce <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d9a:	000aa503          	lw	a0,0(s5)
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	394080e7          	jalr	916(ra) # 80003132 <bread>
    80003da6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da8:	3ff97713          	andi	a4,s2,1023
    80003dac:	40ec87bb          	subw	a5,s9,a4
    80003db0:	413b06bb          	subw	a3,s6,s3
    80003db4:	8d3e                	mv	s10,a5
    80003db6:	2781                	sext.w	a5,a5
    80003db8:	0006861b          	sext.w	a2,a3
    80003dbc:	f8f674e3          	bgeu	a2,a5,80003d44 <writei+0x4c>
    80003dc0:	8d36                	mv	s10,a3
    80003dc2:	b749                	j	80003d44 <writei+0x4c>
      brelse(bp);
    80003dc4:	8526                	mv	a0,s1
    80003dc6:	fffff097          	auipc	ra,0xfffff
    80003dca:	49c080e7          	jalr	1180(ra) # 80003262 <brelse>
  }

  if(off > ip->size)
    80003dce:	04caa783          	lw	a5,76(s5)
    80003dd2:	0127f463          	bgeu	a5,s2,80003dda <writei+0xe2>
    ip->size = off;
    80003dd6:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dda:	8556                	mv	a0,s5
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	aa6080e7          	jalr	-1370(ra) # 80003882 <iupdate>

  return tot;
    80003de4:	0009851b          	sext.w	a0,s3
}
    80003de8:	70a6                	ld	ra,104(sp)
    80003dea:	7406                	ld	s0,96(sp)
    80003dec:	64e6                	ld	s1,88(sp)
    80003dee:	6946                	ld	s2,80(sp)
    80003df0:	69a6                	ld	s3,72(sp)
    80003df2:	6a06                	ld	s4,64(sp)
    80003df4:	7ae2                	ld	s5,56(sp)
    80003df6:	7b42                	ld	s6,48(sp)
    80003df8:	7ba2                	ld	s7,40(sp)
    80003dfa:	7c02                	ld	s8,32(sp)
    80003dfc:	6ce2                	ld	s9,24(sp)
    80003dfe:	6d42                	ld	s10,16(sp)
    80003e00:	6da2                	ld	s11,8(sp)
    80003e02:	6165                	addi	sp,sp,112
    80003e04:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e06:	89da                	mv	s3,s6
    80003e08:	bfc9                	j	80003dda <writei+0xe2>
    return -1;
    80003e0a:	557d                	li	a0,-1
}
    80003e0c:	8082                	ret
    return -1;
    80003e0e:	557d                	li	a0,-1
    80003e10:	bfe1                	j	80003de8 <writei+0xf0>
    return -1;
    80003e12:	557d                	li	a0,-1
    80003e14:	bfd1                	j	80003de8 <writei+0xf0>

0000000080003e16 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e16:	1141                	addi	sp,sp,-16
    80003e18:	e406                	sd	ra,8(sp)
    80003e1a:	e022                	sd	s0,0(sp)
    80003e1c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e1e:	4639                	li	a2,14
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	f9e080e7          	jalr	-98(ra) # 80000dbe <strncmp>
}
    80003e28:	60a2                	ld	ra,8(sp)
    80003e2a:	6402                	ld	s0,0(sp)
    80003e2c:	0141                	addi	sp,sp,16
    80003e2e:	8082                	ret

0000000080003e30 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e30:	7139                	addi	sp,sp,-64
    80003e32:	fc06                	sd	ra,56(sp)
    80003e34:	f822                	sd	s0,48(sp)
    80003e36:	f426                	sd	s1,40(sp)
    80003e38:	f04a                	sd	s2,32(sp)
    80003e3a:	ec4e                	sd	s3,24(sp)
    80003e3c:	e852                	sd	s4,16(sp)
    80003e3e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e40:	04451703          	lh	a4,68(a0)
    80003e44:	4785                	li	a5,1
    80003e46:	00f71a63          	bne	a4,a5,80003e5a <dirlookup+0x2a>
    80003e4a:	892a                	mv	s2,a0
    80003e4c:	89ae                	mv	s3,a1
    80003e4e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e50:	457c                	lw	a5,76(a0)
    80003e52:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e54:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e56:	e79d                	bnez	a5,80003e84 <dirlookup+0x54>
    80003e58:	a8a5                	j	80003ed0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e5a:	00005517          	auipc	a0,0x5
    80003e5e:	9de50513          	addi	a0,a0,-1570 # 80008838 <sysargs+0x158>
    80003e62:	ffffc097          	auipc	ra,0xffffc
    80003e66:	6e2080e7          	jalr	1762(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003e6a:	00005517          	auipc	a0,0x5
    80003e6e:	9e650513          	addi	a0,a0,-1562 # 80008850 <sysargs+0x170>
    80003e72:	ffffc097          	auipc	ra,0xffffc
    80003e76:	6d2080e7          	jalr	1746(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7a:	24c1                	addiw	s1,s1,16
    80003e7c:	04c92783          	lw	a5,76(s2)
    80003e80:	04f4f763          	bgeu	s1,a5,80003ece <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e84:	4741                	li	a4,16
    80003e86:	86a6                	mv	a3,s1
    80003e88:	fc040613          	addi	a2,s0,-64
    80003e8c:	4581                	li	a1,0
    80003e8e:	854a                	mv	a0,s2
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	d70080e7          	jalr	-656(ra) # 80003c00 <readi>
    80003e98:	47c1                	li	a5,16
    80003e9a:	fcf518e3          	bne	a0,a5,80003e6a <dirlookup+0x3a>
    if(de.inum == 0)
    80003e9e:	fc045783          	lhu	a5,-64(s0)
    80003ea2:	dfe1                	beqz	a5,80003e7a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ea4:	fc240593          	addi	a1,s0,-62
    80003ea8:	854e                	mv	a0,s3
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	f6c080e7          	jalr	-148(ra) # 80003e16 <namecmp>
    80003eb2:	f561                	bnez	a0,80003e7a <dirlookup+0x4a>
      if(poff)
    80003eb4:	000a0463          	beqz	s4,80003ebc <dirlookup+0x8c>
        *poff = off;
    80003eb8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ebc:	fc045583          	lhu	a1,-64(s0)
    80003ec0:	00092503          	lw	a0,0(s2)
    80003ec4:	fffff097          	auipc	ra,0xfffff
    80003ec8:	750080e7          	jalr	1872(ra) # 80003614 <iget>
    80003ecc:	a011                	j	80003ed0 <dirlookup+0xa0>
  return 0;
    80003ece:	4501                	li	a0,0
}
    80003ed0:	70e2                	ld	ra,56(sp)
    80003ed2:	7442                	ld	s0,48(sp)
    80003ed4:	74a2                	ld	s1,40(sp)
    80003ed6:	7902                	ld	s2,32(sp)
    80003ed8:	69e2                	ld	s3,24(sp)
    80003eda:	6a42                	ld	s4,16(sp)
    80003edc:	6121                	addi	sp,sp,64
    80003ede:	8082                	ret

0000000080003ee0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ee0:	711d                	addi	sp,sp,-96
    80003ee2:	ec86                	sd	ra,88(sp)
    80003ee4:	e8a2                	sd	s0,80(sp)
    80003ee6:	e4a6                	sd	s1,72(sp)
    80003ee8:	e0ca                	sd	s2,64(sp)
    80003eea:	fc4e                	sd	s3,56(sp)
    80003eec:	f852                	sd	s4,48(sp)
    80003eee:	f456                	sd	s5,40(sp)
    80003ef0:	f05a                	sd	s6,32(sp)
    80003ef2:	ec5e                	sd	s7,24(sp)
    80003ef4:	e862                	sd	s8,16(sp)
    80003ef6:	e466                	sd	s9,8(sp)
    80003ef8:	1080                	addi	s0,sp,96
    80003efa:	84aa                	mv	s1,a0
    80003efc:	8b2e                	mv	s6,a1
    80003efe:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f00:	00054703          	lbu	a4,0(a0)
    80003f04:	02f00793          	li	a5,47
    80003f08:	02f70363          	beq	a4,a5,80003f2e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f0c:	ffffe097          	auipc	ra,0xffffe
    80003f10:	aba080e7          	jalr	-1350(ra) # 800019c6 <myproc>
    80003f14:	15053503          	ld	a0,336(a0)
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	9f6080e7          	jalr	-1546(ra) # 8000390e <idup>
    80003f20:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f22:	02f00913          	li	s2,47
  len = path - s;
    80003f26:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f28:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f2a:	4c05                	li	s8,1
    80003f2c:	a865                	j	80003fe4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f2e:	4585                	li	a1,1
    80003f30:	4505                	li	a0,1
    80003f32:	fffff097          	auipc	ra,0xfffff
    80003f36:	6e2080e7          	jalr	1762(ra) # 80003614 <iget>
    80003f3a:	89aa                	mv	s3,a0
    80003f3c:	b7dd                	j	80003f22 <namex+0x42>
      iunlockput(ip);
    80003f3e:	854e                	mv	a0,s3
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	c6e080e7          	jalr	-914(ra) # 80003bae <iunlockput>
      return 0;
    80003f48:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f4a:	854e                	mv	a0,s3
    80003f4c:	60e6                	ld	ra,88(sp)
    80003f4e:	6446                	ld	s0,80(sp)
    80003f50:	64a6                	ld	s1,72(sp)
    80003f52:	6906                	ld	s2,64(sp)
    80003f54:	79e2                	ld	s3,56(sp)
    80003f56:	7a42                	ld	s4,48(sp)
    80003f58:	7aa2                	ld	s5,40(sp)
    80003f5a:	7b02                	ld	s6,32(sp)
    80003f5c:	6be2                	ld	s7,24(sp)
    80003f5e:	6c42                	ld	s8,16(sp)
    80003f60:	6ca2                	ld	s9,8(sp)
    80003f62:	6125                	addi	sp,sp,96
    80003f64:	8082                	ret
      iunlock(ip);
    80003f66:	854e                	mv	a0,s3
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	aa6080e7          	jalr	-1370(ra) # 80003a0e <iunlock>
      return ip;
    80003f70:	bfe9                	j	80003f4a <namex+0x6a>
      iunlockput(ip);
    80003f72:	854e                	mv	a0,s3
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	c3a080e7          	jalr	-966(ra) # 80003bae <iunlockput>
      return 0;
    80003f7c:	89d2                	mv	s3,s4
    80003f7e:	b7f1                	j	80003f4a <namex+0x6a>
  len = path - s;
    80003f80:	40b48633          	sub	a2,s1,a1
    80003f84:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f88:	094cd463          	bge	s9,s4,80004010 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f8c:	4639                	li	a2,14
    80003f8e:	8556                	mv	a0,s5
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	db6080e7          	jalr	-586(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003f98:	0004c783          	lbu	a5,0(s1)
    80003f9c:	01279763          	bne	a5,s2,80003faa <namex+0xca>
    path++;
    80003fa0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fa2:	0004c783          	lbu	a5,0(s1)
    80003fa6:	ff278de3          	beq	a5,s2,80003fa0 <namex+0xc0>
    ilock(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	9a0080e7          	jalr	-1632(ra) # 8000394c <ilock>
    if(ip->type != T_DIR){
    80003fb4:	04499783          	lh	a5,68(s3)
    80003fb8:	f98793e3          	bne	a5,s8,80003f3e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fbc:	000b0563          	beqz	s6,80003fc6 <namex+0xe6>
    80003fc0:	0004c783          	lbu	a5,0(s1)
    80003fc4:	d3cd                	beqz	a5,80003f66 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fc6:	865e                	mv	a2,s7
    80003fc8:	85d6                	mv	a1,s5
    80003fca:	854e                	mv	a0,s3
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	e64080e7          	jalr	-412(ra) # 80003e30 <dirlookup>
    80003fd4:	8a2a                	mv	s4,a0
    80003fd6:	dd51                	beqz	a0,80003f72 <namex+0x92>
    iunlockput(ip);
    80003fd8:	854e                	mv	a0,s3
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	bd4080e7          	jalr	-1068(ra) # 80003bae <iunlockput>
    ip = next;
    80003fe2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fe4:	0004c783          	lbu	a5,0(s1)
    80003fe8:	05279763          	bne	a5,s2,80004036 <namex+0x156>
    path++;
    80003fec:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fee:	0004c783          	lbu	a5,0(s1)
    80003ff2:	ff278de3          	beq	a5,s2,80003fec <namex+0x10c>
  if(*path == 0)
    80003ff6:	c79d                	beqz	a5,80004024 <namex+0x144>
    path++;
    80003ff8:	85a6                	mv	a1,s1
  len = path - s;
    80003ffa:	8a5e                	mv	s4,s7
    80003ffc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ffe:	01278963          	beq	a5,s2,80004010 <namex+0x130>
    80004002:	dfbd                	beqz	a5,80003f80 <namex+0xa0>
    path++;
    80004004:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004006:	0004c783          	lbu	a5,0(s1)
    8000400a:	ff279ce3          	bne	a5,s2,80004002 <namex+0x122>
    8000400e:	bf8d                	j	80003f80 <namex+0xa0>
    memmove(name, s, len);
    80004010:	2601                	sext.w	a2,a2
    80004012:	8556                	mv	a0,s5
    80004014:	ffffd097          	auipc	ra,0xffffd
    80004018:	d32080e7          	jalr	-718(ra) # 80000d46 <memmove>
    name[len] = 0;
    8000401c:	9a56                	add	s4,s4,s5
    8000401e:	000a0023          	sb	zero,0(s4)
    80004022:	bf9d                	j	80003f98 <namex+0xb8>
  if(nameiparent){
    80004024:	f20b03e3          	beqz	s6,80003f4a <namex+0x6a>
    iput(ip);
    80004028:	854e                	mv	a0,s3
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	adc080e7          	jalr	-1316(ra) # 80003b06 <iput>
    return 0;
    80004032:	4981                	li	s3,0
    80004034:	bf19                	j	80003f4a <namex+0x6a>
  if(*path == 0)
    80004036:	d7fd                	beqz	a5,80004024 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004038:	0004c783          	lbu	a5,0(s1)
    8000403c:	85a6                	mv	a1,s1
    8000403e:	b7d1                	j	80004002 <namex+0x122>

0000000080004040 <dirlink>:
{
    80004040:	7139                	addi	sp,sp,-64
    80004042:	fc06                	sd	ra,56(sp)
    80004044:	f822                	sd	s0,48(sp)
    80004046:	f426                	sd	s1,40(sp)
    80004048:	f04a                	sd	s2,32(sp)
    8000404a:	ec4e                	sd	s3,24(sp)
    8000404c:	e852                	sd	s4,16(sp)
    8000404e:	0080                	addi	s0,sp,64
    80004050:	892a                	mv	s2,a0
    80004052:	8a2e                	mv	s4,a1
    80004054:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004056:	4601                	li	a2,0
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	dd8080e7          	jalr	-552(ra) # 80003e30 <dirlookup>
    80004060:	e93d                	bnez	a0,800040d6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004062:	04c92483          	lw	s1,76(s2)
    80004066:	c49d                	beqz	s1,80004094 <dirlink+0x54>
    80004068:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000406a:	4741                	li	a4,16
    8000406c:	86a6                	mv	a3,s1
    8000406e:	fc040613          	addi	a2,s0,-64
    80004072:	4581                	li	a1,0
    80004074:	854a                	mv	a0,s2
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	b8a080e7          	jalr	-1142(ra) # 80003c00 <readi>
    8000407e:	47c1                	li	a5,16
    80004080:	06f51163          	bne	a0,a5,800040e2 <dirlink+0xa2>
    if(de.inum == 0)
    80004084:	fc045783          	lhu	a5,-64(s0)
    80004088:	c791                	beqz	a5,80004094 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408a:	24c1                	addiw	s1,s1,16
    8000408c:	04c92783          	lw	a5,76(s2)
    80004090:	fcf4ede3          	bltu	s1,a5,8000406a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004094:	4639                	li	a2,14
    80004096:	85d2                	mv	a1,s4
    80004098:	fc240513          	addi	a0,s0,-62
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	d5e080e7          	jalr	-674(ra) # 80000dfa <strncpy>
  de.inum = inum;
    800040a4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a8:	4741                	li	a4,16
    800040aa:	86a6                	mv	a3,s1
    800040ac:	fc040613          	addi	a2,s0,-64
    800040b0:	4581                	li	a1,0
    800040b2:	854a                	mv	a0,s2
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	c44080e7          	jalr	-956(ra) # 80003cf8 <writei>
    800040bc:	1541                	addi	a0,a0,-16
    800040be:	00a03533          	snez	a0,a0
    800040c2:	40a00533          	neg	a0,a0
}
    800040c6:	70e2                	ld	ra,56(sp)
    800040c8:	7442                	ld	s0,48(sp)
    800040ca:	74a2                	ld	s1,40(sp)
    800040cc:	7902                	ld	s2,32(sp)
    800040ce:	69e2                	ld	s3,24(sp)
    800040d0:	6a42                	ld	s4,16(sp)
    800040d2:	6121                	addi	sp,sp,64
    800040d4:	8082                	ret
    iput(ip);
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	a30080e7          	jalr	-1488(ra) # 80003b06 <iput>
    return -1;
    800040de:	557d                	li	a0,-1
    800040e0:	b7dd                	j	800040c6 <dirlink+0x86>
      panic("dirlink read");
    800040e2:	00004517          	auipc	a0,0x4
    800040e6:	77e50513          	addi	a0,a0,1918 # 80008860 <sysargs+0x180>
    800040ea:	ffffc097          	auipc	ra,0xffffc
    800040ee:	45a080e7          	jalr	1114(ra) # 80000544 <panic>

00000000800040f2 <namei>:

struct inode*
namei(char *path)
{
    800040f2:	1101                	addi	sp,sp,-32
    800040f4:	ec06                	sd	ra,24(sp)
    800040f6:	e822                	sd	s0,16(sp)
    800040f8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040fa:	fe040613          	addi	a2,s0,-32
    800040fe:	4581                	li	a1,0
    80004100:	00000097          	auipc	ra,0x0
    80004104:	de0080e7          	jalr	-544(ra) # 80003ee0 <namex>
}
    80004108:	60e2                	ld	ra,24(sp)
    8000410a:	6442                	ld	s0,16(sp)
    8000410c:	6105                	addi	sp,sp,32
    8000410e:	8082                	ret

0000000080004110 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004110:	1141                	addi	sp,sp,-16
    80004112:	e406                	sd	ra,8(sp)
    80004114:	e022                	sd	s0,0(sp)
    80004116:	0800                	addi	s0,sp,16
    80004118:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000411a:	4585                	li	a1,1
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	dc4080e7          	jalr	-572(ra) # 80003ee0 <namex>
}
    80004124:	60a2                	ld	ra,8(sp)
    80004126:	6402                	ld	s0,0(sp)
    80004128:	0141                	addi	sp,sp,16
    8000412a:	8082                	ret

000000008000412c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000412c:	1101                	addi	sp,sp,-32
    8000412e:	ec06                	sd	ra,24(sp)
    80004130:	e822                	sd	s0,16(sp)
    80004132:	e426                	sd	s1,8(sp)
    80004134:	e04a                	sd	s2,0(sp)
    80004136:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004138:	0001d917          	auipc	s2,0x1d
    8000413c:	40890913          	addi	s2,s2,1032 # 80021540 <log>
    80004140:	01892583          	lw	a1,24(s2)
    80004144:	02892503          	lw	a0,40(s2)
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	fea080e7          	jalr	-22(ra) # 80003132 <bread>
    80004150:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004152:	02c92683          	lw	a3,44(s2)
    80004156:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004158:	02d05763          	blez	a3,80004186 <write_head+0x5a>
    8000415c:	0001d797          	auipc	a5,0x1d
    80004160:	41478793          	addi	a5,a5,1044 # 80021570 <log+0x30>
    80004164:	05c50713          	addi	a4,a0,92
    80004168:	36fd                	addiw	a3,a3,-1
    8000416a:	1682                	slli	a3,a3,0x20
    8000416c:	9281                	srli	a3,a3,0x20
    8000416e:	068a                	slli	a3,a3,0x2
    80004170:	0001d617          	auipc	a2,0x1d
    80004174:	40460613          	addi	a2,a2,1028 # 80021574 <log+0x34>
    80004178:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000417a:	4390                	lw	a2,0(a5)
    8000417c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000417e:	0791                	addi	a5,a5,4
    80004180:	0711                	addi	a4,a4,4
    80004182:	fed79ce3          	bne	a5,a3,8000417a <write_head+0x4e>
  }
  bwrite(buf);
    80004186:	8526                	mv	a0,s1
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	09c080e7          	jalr	156(ra) # 80003224 <bwrite>
  brelse(buf);
    80004190:	8526                	mv	a0,s1
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	0d0080e7          	jalr	208(ra) # 80003262 <brelse>
}
    8000419a:	60e2                	ld	ra,24(sp)
    8000419c:	6442                	ld	s0,16(sp)
    8000419e:	64a2                	ld	s1,8(sp)
    800041a0:	6902                	ld	s2,0(sp)
    800041a2:	6105                	addi	sp,sp,32
    800041a4:	8082                	ret

00000000800041a6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a6:	0001d797          	auipc	a5,0x1d
    800041aa:	3c67a783          	lw	a5,966(a5) # 8002156c <log+0x2c>
    800041ae:	0af05d63          	blez	a5,80004268 <install_trans+0xc2>
{
    800041b2:	7139                	addi	sp,sp,-64
    800041b4:	fc06                	sd	ra,56(sp)
    800041b6:	f822                	sd	s0,48(sp)
    800041b8:	f426                	sd	s1,40(sp)
    800041ba:	f04a                	sd	s2,32(sp)
    800041bc:	ec4e                	sd	s3,24(sp)
    800041be:	e852                	sd	s4,16(sp)
    800041c0:	e456                	sd	s5,8(sp)
    800041c2:	e05a                	sd	s6,0(sp)
    800041c4:	0080                	addi	s0,sp,64
    800041c6:	8b2a                	mv	s6,a0
    800041c8:	0001da97          	auipc	s5,0x1d
    800041cc:	3a8a8a93          	addi	s5,s5,936 # 80021570 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041d2:	0001d997          	auipc	s3,0x1d
    800041d6:	36e98993          	addi	s3,s3,878 # 80021540 <log>
    800041da:	a035                	j	80004206 <install_trans+0x60>
      bunpin(dbuf);
    800041dc:	8526                	mv	a0,s1
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	15e080e7          	jalr	350(ra) # 8000333c <bunpin>
    brelse(lbuf);
    800041e6:	854a                	mv	a0,s2
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	07a080e7          	jalr	122(ra) # 80003262 <brelse>
    brelse(dbuf);
    800041f0:	8526                	mv	a0,s1
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	070080e7          	jalr	112(ra) # 80003262 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fa:	2a05                	addiw	s4,s4,1
    800041fc:	0a91                	addi	s5,s5,4
    800041fe:	02c9a783          	lw	a5,44(s3)
    80004202:	04fa5963          	bge	s4,a5,80004254 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004206:	0189a583          	lw	a1,24(s3)
    8000420a:	014585bb          	addw	a1,a1,s4
    8000420e:	2585                	addiw	a1,a1,1
    80004210:	0289a503          	lw	a0,40(s3)
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	f1e080e7          	jalr	-226(ra) # 80003132 <bread>
    8000421c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000421e:	000aa583          	lw	a1,0(s5)
    80004222:	0289a503          	lw	a0,40(s3)
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	f0c080e7          	jalr	-244(ra) # 80003132 <bread>
    8000422e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004230:	40000613          	li	a2,1024
    80004234:	05890593          	addi	a1,s2,88
    80004238:	05850513          	addi	a0,a0,88
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	b0a080e7          	jalr	-1270(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004244:	8526                	mv	a0,s1
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	fde080e7          	jalr	-34(ra) # 80003224 <bwrite>
    if(recovering == 0)
    8000424e:	f80b1ce3          	bnez	s6,800041e6 <install_trans+0x40>
    80004252:	b769                	j	800041dc <install_trans+0x36>
}
    80004254:	70e2                	ld	ra,56(sp)
    80004256:	7442                	ld	s0,48(sp)
    80004258:	74a2                	ld	s1,40(sp)
    8000425a:	7902                	ld	s2,32(sp)
    8000425c:	69e2                	ld	s3,24(sp)
    8000425e:	6a42                	ld	s4,16(sp)
    80004260:	6aa2                	ld	s5,8(sp)
    80004262:	6b02                	ld	s6,0(sp)
    80004264:	6121                	addi	sp,sp,64
    80004266:	8082                	ret
    80004268:	8082                	ret

000000008000426a <initlog>:
{
    8000426a:	7179                	addi	sp,sp,-48
    8000426c:	f406                	sd	ra,40(sp)
    8000426e:	f022                	sd	s0,32(sp)
    80004270:	ec26                	sd	s1,24(sp)
    80004272:	e84a                	sd	s2,16(sp)
    80004274:	e44e                	sd	s3,8(sp)
    80004276:	1800                	addi	s0,sp,48
    80004278:	892a                	mv	s2,a0
    8000427a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000427c:	0001d497          	auipc	s1,0x1d
    80004280:	2c448493          	addi	s1,s1,708 # 80021540 <log>
    80004284:	00004597          	auipc	a1,0x4
    80004288:	5ec58593          	addi	a1,a1,1516 # 80008870 <sysargs+0x190>
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	8cc080e7          	jalr	-1844(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004296:	0149a583          	lw	a1,20(s3)
    8000429a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000429c:	0109a783          	lw	a5,16(s3)
    800042a0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042a2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042a6:	854a                	mv	a0,s2
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	e8a080e7          	jalr	-374(ra) # 80003132 <bread>
  log.lh.n = lh->n;
    800042b0:	4d3c                	lw	a5,88(a0)
    800042b2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042b4:	02f05563          	blez	a5,800042de <initlog+0x74>
    800042b8:	05c50713          	addi	a4,a0,92
    800042bc:	0001d697          	auipc	a3,0x1d
    800042c0:	2b468693          	addi	a3,a3,692 # 80021570 <log+0x30>
    800042c4:	37fd                	addiw	a5,a5,-1
    800042c6:	1782                	slli	a5,a5,0x20
    800042c8:	9381                	srli	a5,a5,0x20
    800042ca:	078a                	slli	a5,a5,0x2
    800042cc:	06050613          	addi	a2,a0,96
    800042d0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042d2:	4310                	lw	a2,0(a4)
    800042d4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042d6:	0711                	addi	a4,a4,4
    800042d8:	0691                	addi	a3,a3,4
    800042da:	fef71ce3          	bne	a4,a5,800042d2 <initlog+0x68>
  brelse(buf);
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	f84080e7          	jalr	-124(ra) # 80003262 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042e6:	4505                	li	a0,1
    800042e8:	00000097          	auipc	ra,0x0
    800042ec:	ebe080e7          	jalr	-322(ra) # 800041a6 <install_trans>
  log.lh.n = 0;
    800042f0:	0001d797          	auipc	a5,0x1d
    800042f4:	2607ae23          	sw	zero,636(a5) # 8002156c <log+0x2c>
  write_head(); // clear the log
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	e34080e7          	jalr	-460(ra) # 8000412c <write_head>
}
    80004300:	70a2                	ld	ra,40(sp)
    80004302:	7402                	ld	s0,32(sp)
    80004304:	64e2                	ld	s1,24(sp)
    80004306:	6942                	ld	s2,16(sp)
    80004308:	69a2                	ld	s3,8(sp)
    8000430a:	6145                	addi	sp,sp,48
    8000430c:	8082                	ret

000000008000430e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000430e:	1101                	addi	sp,sp,-32
    80004310:	ec06                	sd	ra,24(sp)
    80004312:	e822                	sd	s0,16(sp)
    80004314:	e426                	sd	s1,8(sp)
    80004316:	e04a                	sd	s2,0(sp)
    80004318:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000431a:	0001d517          	auipc	a0,0x1d
    8000431e:	22650513          	addi	a0,a0,550 # 80021540 <log>
    80004322:	ffffd097          	auipc	ra,0xffffd
    80004326:	8c8080e7          	jalr	-1848(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    8000432a:	0001d497          	auipc	s1,0x1d
    8000432e:	21648493          	addi	s1,s1,534 # 80021540 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004332:	4979                	li	s2,30
    80004334:	a039                	j	80004342 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004336:	85a6                	mv	a1,s1
    80004338:	8526                	mv	a0,s1
    8000433a:	ffffe097          	auipc	ra,0xffffe
    8000433e:	d50080e7          	jalr	-688(ra) # 8000208a <sleep>
    if(log.committing){
    80004342:	50dc                	lw	a5,36(s1)
    80004344:	fbed                	bnez	a5,80004336 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004346:	509c                	lw	a5,32(s1)
    80004348:	0017871b          	addiw	a4,a5,1
    8000434c:	0007069b          	sext.w	a3,a4
    80004350:	0027179b          	slliw	a5,a4,0x2
    80004354:	9fb9                	addw	a5,a5,a4
    80004356:	0017979b          	slliw	a5,a5,0x1
    8000435a:	54d8                	lw	a4,44(s1)
    8000435c:	9fb9                	addw	a5,a5,a4
    8000435e:	00f95963          	bge	s2,a5,80004370 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004362:	85a6                	mv	a1,s1
    80004364:	8526                	mv	a0,s1
    80004366:	ffffe097          	auipc	ra,0xffffe
    8000436a:	d24080e7          	jalr	-732(ra) # 8000208a <sleep>
    8000436e:	bfd1                	j	80004342 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004370:	0001d517          	auipc	a0,0x1d
    80004374:	1d050513          	addi	a0,a0,464 # 80021540 <log>
    80004378:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	924080e7          	jalr	-1756(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004382:	60e2                	ld	ra,24(sp)
    80004384:	6442                	ld	s0,16(sp)
    80004386:	64a2                	ld	s1,8(sp)
    80004388:	6902                	ld	s2,0(sp)
    8000438a:	6105                	addi	sp,sp,32
    8000438c:	8082                	ret

000000008000438e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000438e:	7139                	addi	sp,sp,-64
    80004390:	fc06                	sd	ra,56(sp)
    80004392:	f822                	sd	s0,48(sp)
    80004394:	f426                	sd	s1,40(sp)
    80004396:	f04a                	sd	s2,32(sp)
    80004398:	ec4e                	sd	s3,24(sp)
    8000439a:	e852                	sd	s4,16(sp)
    8000439c:	e456                	sd	s5,8(sp)
    8000439e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043a0:	0001d497          	auipc	s1,0x1d
    800043a4:	1a048493          	addi	s1,s1,416 # 80021540 <log>
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	840080e7          	jalr	-1984(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800043b2:	509c                	lw	a5,32(s1)
    800043b4:	37fd                	addiw	a5,a5,-1
    800043b6:	0007891b          	sext.w	s2,a5
    800043ba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043bc:	50dc                	lw	a5,36(s1)
    800043be:	efb9                	bnez	a5,8000441c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043c0:	06091663          	bnez	s2,8000442c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043c4:	0001d497          	auipc	s1,0x1d
    800043c8:	17c48493          	addi	s1,s1,380 # 80021540 <log>
    800043cc:	4785                	li	a5,1
    800043ce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043d0:	8526                	mv	a0,s1
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	8cc080e7          	jalr	-1844(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043da:	54dc                	lw	a5,44(s1)
    800043dc:	06f04763          	bgtz	a5,8000444a <end_op+0xbc>
    acquire(&log.lock);
    800043e0:	0001d497          	auipc	s1,0x1d
    800043e4:	16048493          	addi	s1,s1,352 # 80021540 <log>
    800043e8:	8526                	mv	a0,s1
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	800080e7          	jalr	-2048(ra) # 80000bea <acquire>
    log.committing = 0;
    800043f2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043f6:	8526                	mv	a0,s1
    800043f8:	ffffe097          	auipc	ra,0xffffe
    800043fc:	cf6080e7          	jalr	-778(ra) # 800020ee <wakeup>
    release(&log.lock);
    80004400:	8526                	mv	a0,s1
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	89c080e7          	jalr	-1892(ra) # 80000c9e <release>
}
    8000440a:	70e2                	ld	ra,56(sp)
    8000440c:	7442                	ld	s0,48(sp)
    8000440e:	74a2                	ld	s1,40(sp)
    80004410:	7902                	ld	s2,32(sp)
    80004412:	69e2                	ld	s3,24(sp)
    80004414:	6a42                	ld	s4,16(sp)
    80004416:	6aa2                	ld	s5,8(sp)
    80004418:	6121                	addi	sp,sp,64
    8000441a:	8082                	ret
    panic("log.committing");
    8000441c:	00004517          	auipc	a0,0x4
    80004420:	45c50513          	addi	a0,a0,1116 # 80008878 <sysargs+0x198>
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	120080e7          	jalr	288(ra) # 80000544 <panic>
    wakeup(&log);
    8000442c:	0001d497          	auipc	s1,0x1d
    80004430:	11448493          	addi	s1,s1,276 # 80021540 <log>
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	cb8080e7          	jalr	-840(ra) # 800020ee <wakeup>
  release(&log.lock);
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	85e080e7          	jalr	-1954(ra) # 80000c9e <release>
  if(do_commit){
    80004448:	b7c9                	j	8000440a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444a:	0001da97          	auipc	s5,0x1d
    8000444e:	126a8a93          	addi	s5,s5,294 # 80021570 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004452:	0001da17          	auipc	s4,0x1d
    80004456:	0eea0a13          	addi	s4,s4,238 # 80021540 <log>
    8000445a:	018a2583          	lw	a1,24(s4)
    8000445e:	012585bb          	addw	a1,a1,s2
    80004462:	2585                	addiw	a1,a1,1
    80004464:	028a2503          	lw	a0,40(s4)
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	cca080e7          	jalr	-822(ra) # 80003132 <bread>
    80004470:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004472:	000aa583          	lw	a1,0(s5)
    80004476:	028a2503          	lw	a0,40(s4)
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	cb8080e7          	jalr	-840(ra) # 80003132 <bread>
    80004482:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004484:	40000613          	li	a2,1024
    80004488:	05850593          	addi	a1,a0,88
    8000448c:	05848513          	addi	a0,s1,88
    80004490:	ffffd097          	auipc	ra,0xffffd
    80004494:	8b6080e7          	jalr	-1866(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004498:	8526                	mv	a0,s1
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	d8a080e7          	jalr	-630(ra) # 80003224 <bwrite>
    brelse(from);
    800044a2:	854e                	mv	a0,s3
    800044a4:	fffff097          	auipc	ra,0xfffff
    800044a8:	dbe080e7          	jalr	-578(ra) # 80003262 <brelse>
    brelse(to);
    800044ac:	8526                	mv	a0,s1
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	db4080e7          	jalr	-588(ra) # 80003262 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b6:	2905                	addiw	s2,s2,1
    800044b8:	0a91                	addi	s5,s5,4
    800044ba:	02ca2783          	lw	a5,44(s4)
    800044be:	f8f94ee3          	blt	s2,a5,8000445a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	c6a080e7          	jalr	-918(ra) # 8000412c <write_head>
    install_trans(0); // Now install writes to home locations
    800044ca:	4501                	li	a0,0
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	cda080e7          	jalr	-806(ra) # 800041a6 <install_trans>
    log.lh.n = 0;
    800044d4:	0001d797          	auipc	a5,0x1d
    800044d8:	0807ac23          	sw	zero,152(a5) # 8002156c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044dc:	00000097          	auipc	ra,0x0
    800044e0:	c50080e7          	jalr	-944(ra) # 8000412c <write_head>
    800044e4:	bdf5                	j	800043e0 <end_op+0x52>

00000000800044e6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	e04a                	sd	s2,0(sp)
    800044f0:	1000                	addi	s0,sp,32
    800044f2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044f4:	0001d917          	auipc	s2,0x1d
    800044f8:	04c90913          	addi	s2,s2,76 # 80021540 <log>
    800044fc:	854a                	mv	a0,s2
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	6ec080e7          	jalr	1772(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004506:	02c92603          	lw	a2,44(s2)
    8000450a:	47f5                	li	a5,29
    8000450c:	06c7c563          	blt	a5,a2,80004576 <log_write+0x90>
    80004510:	0001d797          	auipc	a5,0x1d
    80004514:	04c7a783          	lw	a5,76(a5) # 8002155c <log+0x1c>
    80004518:	37fd                	addiw	a5,a5,-1
    8000451a:	04f65e63          	bge	a2,a5,80004576 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000451e:	0001d797          	auipc	a5,0x1d
    80004522:	0427a783          	lw	a5,66(a5) # 80021560 <log+0x20>
    80004526:	06f05063          	blez	a5,80004586 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000452a:	4781                	li	a5,0
    8000452c:	06c05563          	blez	a2,80004596 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004530:	44cc                	lw	a1,12(s1)
    80004532:	0001d717          	auipc	a4,0x1d
    80004536:	03e70713          	addi	a4,a4,62 # 80021570 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000453a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000453c:	4314                	lw	a3,0(a4)
    8000453e:	04b68c63          	beq	a3,a1,80004596 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004542:	2785                	addiw	a5,a5,1
    80004544:	0711                	addi	a4,a4,4
    80004546:	fef61be3          	bne	a2,a5,8000453c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000454a:	0621                	addi	a2,a2,8
    8000454c:	060a                	slli	a2,a2,0x2
    8000454e:	0001d797          	auipc	a5,0x1d
    80004552:	ff278793          	addi	a5,a5,-14 # 80021540 <log>
    80004556:	963e                	add	a2,a2,a5
    80004558:	44dc                	lw	a5,12(s1)
    8000455a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000455c:	8526                	mv	a0,s1
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	da2080e7          	jalr	-606(ra) # 80003300 <bpin>
    log.lh.n++;
    80004566:	0001d717          	auipc	a4,0x1d
    8000456a:	fda70713          	addi	a4,a4,-38 # 80021540 <log>
    8000456e:	575c                	lw	a5,44(a4)
    80004570:	2785                	addiw	a5,a5,1
    80004572:	d75c                	sw	a5,44(a4)
    80004574:	a835                	j	800045b0 <log_write+0xca>
    panic("too big a transaction");
    80004576:	00004517          	auipc	a0,0x4
    8000457a:	31250513          	addi	a0,a0,786 # 80008888 <sysargs+0x1a8>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	fc6080e7          	jalr	-58(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004586:	00004517          	auipc	a0,0x4
    8000458a:	31a50513          	addi	a0,a0,794 # 800088a0 <sysargs+0x1c0>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	fb6080e7          	jalr	-74(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004596:	00878713          	addi	a4,a5,8
    8000459a:	00271693          	slli	a3,a4,0x2
    8000459e:	0001d717          	auipc	a4,0x1d
    800045a2:	fa270713          	addi	a4,a4,-94 # 80021540 <log>
    800045a6:	9736                	add	a4,a4,a3
    800045a8:	44d4                	lw	a3,12(s1)
    800045aa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ac:	faf608e3          	beq	a2,a5,8000455c <log_write+0x76>
  }
  release(&log.lock);
    800045b0:	0001d517          	auipc	a0,0x1d
    800045b4:	f9050513          	addi	a0,a0,-112 # 80021540 <log>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	6e6080e7          	jalr	1766(ra) # 80000c9e <release>
}
    800045c0:	60e2                	ld	ra,24(sp)
    800045c2:	6442                	ld	s0,16(sp)
    800045c4:	64a2                	ld	s1,8(sp)
    800045c6:	6902                	ld	s2,0(sp)
    800045c8:	6105                	addi	sp,sp,32
    800045ca:	8082                	ret

00000000800045cc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045cc:	1101                	addi	sp,sp,-32
    800045ce:	ec06                	sd	ra,24(sp)
    800045d0:	e822                	sd	s0,16(sp)
    800045d2:	e426                	sd	s1,8(sp)
    800045d4:	e04a                	sd	s2,0(sp)
    800045d6:	1000                	addi	s0,sp,32
    800045d8:	84aa                	mv	s1,a0
    800045da:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045dc:	00004597          	auipc	a1,0x4
    800045e0:	2e458593          	addi	a1,a1,740 # 800088c0 <sysargs+0x1e0>
    800045e4:	0521                	addi	a0,a0,8
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	574080e7          	jalr	1396(ra) # 80000b5a <initlock>
  lk->name = name;
    800045ee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f6:	0204a423          	sw	zero,40(s1)
}
    800045fa:	60e2                	ld	ra,24(sp)
    800045fc:	6442                	ld	s0,16(sp)
    800045fe:	64a2                	ld	s1,8(sp)
    80004600:	6902                	ld	s2,0(sp)
    80004602:	6105                	addi	sp,sp,32
    80004604:	8082                	ret

0000000080004606 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	e04a                	sd	s2,0(sp)
    80004610:	1000                	addi	s0,sp,32
    80004612:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004614:	00850913          	addi	s2,a0,8
    80004618:	854a                	mv	a0,s2
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	5d0080e7          	jalr	1488(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004622:	409c                	lw	a5,0(s1)
    80004624:	cb89                	beqz	a5,80004636 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004626:	85ca                	mv	a1,s2
    80004628:	8526                	mv	a0,s1
    8000462a:	ffffe097          	auipc	ra,0xffffe
    8000462e:	a60080e7          	jalr	-1440(ra) # 8000208a <sleep>
  while (lk->locked) {
    80004632:	409c                	lw	a5,0(s1)
    80004634:	fbed                	bnez	a5,80004626 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004636:	4785                	li	a5,1
    80004638:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000463a:	ffffd097          	auipc	ra,0xffffd
    8000463e:	38c080e7          	jalr	908(ra) # 800019c6 <myproc>
    80004642:	591c                	lw	a5,48(a0)
    80004644:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	656080e7          	jalr	1622(ra) # 80000c9e <release>
}
    80004650:	60e2                	ld	ra,24(sp)
    80004652:	6442                	ld	s0,16(sp)
    80004654:	64a2                	ld	s1,8(sp)
    80004656:	6902                	ld	s2,0(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret

000000008000465c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000465c:	1101                	addi	sp,sp,-32
    8000465e:	ec06                	sd	ra,24(sp)
    80004660:	e822                	sd	s0,16(sp)
    80004662:	e426                	sd	s1,8(sp)
    80004664:	e04a                	sd	s2,0(sp)
    80004666:	1000                	addi	s0,sp,32
    80004668:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000466a:	00850913          	addi	s2,a0,8
    8000466e:	854a                	mv	a0,s2
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	57a080e7          	jalr	1402(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004678:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000467c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004680:	8526                	mv	a0,s1
    80004682:	ffffe097          	auipc	ra,0xffffe
    80004686:	a6c080e7          	jalr	-1428(ra) # 800020ee <wakeup>
  release(&lk->lk);
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	612080e7          	jalr	1554(ra) # 80000c9e <release>
}
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6902                	ld	s2,0(sp)
    8000469c:	6105                	addi	sp,sp,32
    8000469e:	8082                	ret

00000000800046a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046a0:	7179                	addi	sp,sp,-48
    800046a2:	f406                	sd	ra,40(sp)
    800046a4:	f022                	sd	s0,32(sp)
    800046a6:	ec26                	sd	s1,24(sp)
    800046a8:	e84a                	sd	s2,16(sp)
    800046aa:	e44e                	sd	s3,8(sp)
    800046ac:	1800                	addi	s0,sp,48
    800046ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046b0:	00850913          	addi	s2,a0,8
    800046b4:	854a                	mv	a0,s2
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	534080e7          	jalr	1332(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046be:	409c                	lw	a5,0(s1)
    800046c0:	ef99                	bnez	a5,800046de <holdingsleep+0x3e>
    800046c2:	4481                	li	s1,0
  release(&lk->lk);
    800046c4:	854a                	mv	a0,s2
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5d8080e7          	jalr	1496(ra) # 80000c9e <release>
  return r;
}
    800046ce:	8526                	mv	a0,s1
    800046d0:	70a2                	ld	ra,40(sp)
    800046d2:	7402                	ld	s0,32(sp)
    800046d4:	64e2                	ld	s1,24(sp)
    800046d6:	6942                	ld	s2,16(sp)
    800046d8:	69a2                	ld	s3,8(sp)
    800046da:	6145                	addi	sp,sp,48
    800046dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046de:	0284a983          	lw	s3,40(s1)
    800046e2:	ffffd097          	auipc	ra,0xffffd
    800046e6:	2e4080e7          	jalr	740(ra) # 800019c6 <myproc>
    800046ea:	5904                	lw	s1,48(a0)
    800046ec:	413484b3          	sub	s1,s1,s3
    800046f0:	0014b493          	seqz	s1,s1
    800046f4:	bfc1                	j	800046c4 <holdingsleep+0x24>

00000000800046f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046f6:	1141                	addi	sp,sp,-16
    800046f8:	e406                	sd	ra,8(sp)
    800046fa:	e022                	sd	s0,0(sp)
    800046fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046fe:	00004597          	auipc	a1,0x4
    80004702:	1d258593          	addi	a1,a1,466 # 800088d0 <sysargs+0x1f0>
    80004706:	0001d517          	auipc	a0,0x1d
    8000470a:	f8250513          	addi	a0,a0,-126 # 80021688 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	44c080e7          	jalr	1100(ra) # 80000b5a <initlock>
}
    80004716:	60a2                	ld	ra,8(sp)
    80004718:	6402                	ld	s0,0(sp)
    8000471a:	0141                	addi	sp,sp,16
    8000471c:	8082                	ret

000000008000471e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000471e:	1101                	addi	sp,sp,-32
    80004720:	ec06                	sd	ra,24(sp)
    80004722:	e822                	sd	s0,16(sp)
    80004724:	e426                	sd	s1,8(sp)
    80004726:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004728:	0001d517          	auipc	a0,0x1d
    8000472c:	f6050513          	addi	a0,a0,-160 # 80021688 <ftable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4ba080e7          	jalr	1210(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004738:	0001d497          	auipc	s1,0x1d
    8000473c:	f6848493          	addi	s1,s1,-152 # 800216a0 <ftable+0x18>
    80004740:	0001e717          	auipc	a4,0x1e
    80004744:	f0070713          	addi	a4,a4,-256 # 80022640 <disk>
    if(f->ref == 0){
    80004748:	40dc                	lw	a5,4(s1)
    8000474a:	cf99                	beqz	a5,80004768 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000474c:	02848493          	addi	s1,s1,40
    80004750:	fee49ce3          	bne	s1,a4,80004748 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004754:	0001d517          	auipc	a0,0x1d
    80004758:	f3450513          	addi	a0,a0,-204 # 80021688 <ftable>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	542080e7          	jalr	1346(ra) # 80000c9e <release>
  return 0;
    80004764:	4481                	li	s1,0
    80004766:	a819                	j	8000477c <filealloc+0x5e>
      f->ref = 1;
    80004768:	4785                	li	a5,1
    8000476a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000476c:	0001d517          	auipc	a0,0x1d
    80004770:	f1c50513          	addi	a0,a0,-228 # 80021688 <ftable>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	52a080e7          	jalr	1322(ra) # 80000c9e <release>
}
    8000477c:	8526                	mv	a0,s1
    8000477e:	60e2                	ld	ra,24(sp)
    80004780:	6442                	ld	s0,16(sp)
    80004782:	64a2                	ld	s1,8(sp)
    80004784:	6105                	addi	sp,sp,32
    80004786:	8082                	ret

0000000080004788 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004788:	1101                	addi	sp,sp,-32
    8000478a:	ec06                	sd	ra,24(sp)
    8000478c:	e822                	sd	s0,16(sp)
    8000478e:	e426                	sd	s1,8(sp)
    80004790:	1000                	addi	s0,sp,32
    80004792:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004794:	0001d517          	auipc	a0,0x1d
    80004798:	ef450513          	addi	a0,a0,-268 # 80021688 <ftable>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	44e080e7          	jalr	1102(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800047a4:	40dc                	lw	a5,4(s1)
    800047a6:	02f05263          	blez	a5,800047ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047aa:	2785                	addiw	a5,a5,1
    800047ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ae:	0001d517          	auipc	a0,0x1d
    800047b2:	eda50513          	addi	a0,a0,-294 # 80021688 <ftable>
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	4e8080e7          	jalr	1256(ra) # 80000c9e <release>
  return f;
}
    800047be:	8526                	mv	a0,s1
    800047c0:	60e2                	ld	ra,24(sp)
    800047c2:	6442                	ld	s0,16(sp)
    800047c4:	64a2                	ld	s1,8(sp)
    800047c6:	6105                	addi	sp,sp,32
    800047c8:	8082                	ret
    panic("filedup");
    800047ca:	00004517          	auipc	a0,0x4
    800047ce:	10e50513          	addi	a0,a0,270 # 800088d8 <sysargs+0x1f8>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	d72080e7          	jalr	-654(ra) # 80000544 <panic>

00000000800047da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047da:	7139                	addi	sp,sp,-64
    800047dc:	fc06                	sd	ra,56(sp)
    800047de:	f822                	sd	s0,48(sp)
    800047e0:	f426                	sd	s1,40(sp)
    800047e2:	f04a                	sd	s2,32(sp)
    800047e4:	ec4e                	sd	s3,24(sp)
    800047e6:	e852                	sd	s4,16(sp)
    800047e8:	e456                	sd	s5,8(sp)
    800047ea:	0080                	addi	s0,sp,64
    800047ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047ee:	0001d517          	auipc	a0,0x1d
    800047f2:	e9a50513          	addi	a0,a0,-358 # 80021688 <ftable>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	3f4080e7          	jalr	1012(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800047fe:	40dc                	lw	a5,4(s1)
    80004800:	06f05163          	blez	a5,80004862 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004804:	37fd                	addiw	a5,a5,-1
    80004806:	0007871b          	sext.w	a4,a5
    8000480a:	c0dc                	sw	a5,4(s1)
    8000480c:	06e04363          	bgtz	a4,80004872 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004810:	0004a903          	lw	s2,0(s1)
    80004814:	0094ca83          	lbu	s5,9(s1)
    80004818:	0104ba03          	ld	s4,16(s1)
    8000481c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004820:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004824:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	e6050513          	addi	a0,a0,-416 # 80021688 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	46e080e7          	jalr	1134(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004838:	4785                	li	a5,1
    8000483a:	04f90d63          	beq	s2,a5,80004894 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000483e:	3979                	addiw	s2,s2,-2
    80004840:	4785                	li	a5,1
    80004842:	0527e063          	bltu	a5,s2,80004882 <fileclose+0xa8>
    begin_op();
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	ac8080e7          	jalr	-1336(ra) # 8000430e <begin_op>
    iput(ff.ip);
    8000484e:	854e                	mv	a0,s3
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	2b6080e7          	jalr	694(ra) # 80003b06 <iput>
    end_op();
    80004858:	00000097          	auipc	ra,0x0
    8000485c:	b36080e7          	jalr	-1226(ra) # 8000438e <end_op>
    80004860:	a00d                	j	80004882 <fileclose+0xa8>
    panic("fileclose");
    80004862:	00004517          	auipc	a0,0x4
    80004866:	07e50513          	addi	a0,a0,126 # 800088e0 <sysargs+0x200>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	cda080e7          	jalr	-806(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004872:	0001d517          	auipc	a0,0x1d
    80004876:	e1650513          	addi	a0,a0,-490 # 80021688 <ftable>
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	424080e7          	jalr	1060(ra) # 80000c9e <release>
  }
}
    80004882:	70e2                	ld	ra,56(sp)
    80004884:	7442                	ld	s0,48(sp)
    80004886:	74a2                	ld	s1,40(sp)
    80004888:	7902                	ld	s2,32(sp)
    8000488a:	69e2                	ld	s3,24(sp)
    8000488c:	6a42                	ld	s4,16(sp)
    8000488e:	6aa2                	ld	s5,8(sp)
    80004890:	6121                	addi	sp,sp,64
    80004892:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004894:	85d6                	mv	a1,s5
    80004896:	8552                	mv	a0,s4
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	34c080e7          	jalr	844(ra) # 80004be4 <pipeclose>
    800048a0:	b7cd                	j	80004882 <fileclose+0xa8>

00000000800048a2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048a2:	715d                	addi	sp,sp,-80
    800048a4:	e486                	sd	ra,72(sp)
    800048a6:	e0a2                	sd	s0,64(sp)
    800048a8:	fc26                	sd	s1,56(sp)
    800048aa:	f84a                	sd	s2,48(sp)
    800048ac:	f44e                	sd	s3,40(sp)
    800048ae:	0880                	addi	s0,sp,80
    800048b0:	84aa                	mv	s1,a0
    800048b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048b4:	ffffd097          	auipc	ra,0xffffd
    800048b8:	112080e7          	jalr	274(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048bc:	409c                	lw	a5,0(s1)
    800048be:	37f9                	addiw	a5,a5,-2
    800048c0:	4705                	li	a4,1
    800048c2:	04f76763          	bltu	a4,a5,80004910 <filestat+0x6e>
    800048c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800048c8:	6c88                	ld	a0,24(s1)
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	082080e7          	jalr	130(ra) # 8000394c <ilock>
    stati(f->ip, &st);
    800048d2:	fb840593          	addi	a1,s0,-72
    800048d6:	6c88                	ld	a0,24(s1)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	2fe080e7          	jalr	766(ra) # 80003bd6 <stati>
    iunlock(f->ip);
    800048e0:	6c88                	ld	a0,24(s1)
    800048e2:	fffff097          	auipc	ra,0xfffff
    800048e6:	12c080e7          	jalr	300(ra) # 80003a0e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048ea:	46e1                	li	a3,24
    800048ec:	fb840613          	addi	a2,s0,-72
    800048f0:	85ce                	mv	a1,s3
    800048f2:	05093503          	ld	a0,80(s2)
    800048f6:	ffffd097          	auipc	ra,0xffffd
    800048fa:	d8e080e7          	jalr	-626(ra) # 80001684 <copyout>
    800048fe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004902:	60a6                	ld	ra,72(sp)
    80004904:	6406                	ld	s0,64(sp)
    80004906:	74e2                	ld	s1,56(sp)
    80004908:	7942                	ld	s2,48(sp)
    8000490a:	79a2                	ld	s3,40(sp)
    8000490c:	6161                	addi	sp,sp,80
    8000490e:	8082                	ret
  return -1;
    80004910:	557d                	li	a0,-1
    80004912:	bfc5                	j	80004902 <filestat+0x60>

0000000080004914 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004914:	7179                	addi	sp,sp,-48
    80004916:	f406                	sd	ra,40(sp)
    80004918:	f022                	sd	s0,32(sp)
    8000491a:	ec26                	sd	s1,24(sp)
    8000491c:	e84a                	sd	s2,16(sp)
    8000491e:	e44e                	sd	s3,8(sp)
    80004920:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004922:	00854783          	lbu	a5,8(a0)
    80004926:	c3d5                	beqz	a5,800049ca <fileread+0xb6>
    80004928:	84aa                	mv	s1,a0
    8000492a:	89ae                	mv	s3,a1
    8000492c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000492e:	411c                	lw	a5,0(a0)
    80004930:	4705                	li	a4,1
    80004932:	04e78963          	beq	a5,a4,80004984 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004936:	470d                	li	a4,3
    80004938:	04e78d63          	beq	a5,a4,80004992 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000493c:	4709                	li	a4,2
    8000493e:	06e79e63          	bne	a5,a4,800049ba <fileread+0xa6>
    ilock(f->ip);
    80004942:	6d08                	ld	a0,24(a0)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	008080e7          	jalr	8(ra) # 8000394c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000494c:	874a                	mv	a4,s2
    8000494e:	5094                	lw	a3,32(s1)
    80004950:	864e                	mv	a2,s3
    80004952:	4585                	li	a1,1
    80004954:	6c88                	ld	a0,24(s1)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	2aa080e7          	jalr	682(ra) # 80003c00 <readi>
    8000495e:	892a                	mv	s2,a0
    80004960:	00a05563          	blez	a0,8000496a <fileread+0x56>
      f->off += r;
    80004964:	509c                	lw	a5,32(s1)
    80004966:	9fa9                	addw	a5,a5,a0
    80004968:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000496a:	6c88                	ld	a0,24(s1)
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	0a2080e7          	jalr	162(ra) # 80003a0e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004974:	854a                	mv	a0,s2
    80004976:	70a2                	ld	ra,40(sp)
    80004978:	7402                	ld	s0,32(sp)
    8000497a:	64e2                	ld	s1,24(sp)
    8000497c:	6942                	ld	s2,16(sp)
    8000497e:	69a2                	ld	s3,8(sp)
    80004980:	6145                	addi	sp,sp,48
    80004982:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004984:	6908                	ld	a0,16(a0)
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	3ce080e7          	jalr	974(ra) # 80004d54 <piperead>
    8000498e:	892a                	mv	s2,a0
    80004990:	b7d5                	j	80004974 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004992:	02451783          	lh	a5,36(a0)
    80004996:	03079693          	slli	a3,a5,0x30
    8000499a:	92c1                	srli	a3,a3,0x30
    8000499c:	4725                	li	a4,9
    8000499e:	02d76863          	bltu	a4,a3,800049ce <fileread+0xba>
    800049a2:	0792                	slli	a5,a5,0x4
    800049a4:	0001d717          	auipc	a4,0x1d
    800049a8:	c4470713          	addi	a4,a4,-956 # 800215e8 <devsw>
    800049ac:	97ba                	add	a5,a5,a4
    800049ae:	639c                	ld	a5,0(a5)
    800049b0:	c38d                	beqz	a5,800049d2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049b2:	4505                	li	a0,1
    800049b4:	9782                	jalr	a5
    800049b6:	892a                	mv	s2,a0
    800049b8:	bf75                	j	80004974 <fileread+0x60>
    panic("fileread");
    800049ba:	00004517          	auipc	a0,0x4
    800049be:	f3650513          	addi	a0,a0,-202 # 800088f0 <sysargs+0x210>
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	b82080e7          	jalr	-1150(ra) # 80000544 <panic>
    return -1;
    800049ca:	597d                	li	s2,-1
    800049cc:	b765                	j	80004974 <fileread+0x60>
      return -1;
    800049ce:	597d                	li	s2,-1
    800049d0:	b755                	j	80004974 <fileread+0x60>
    800049d2:	597d                	li	s2,-1
    800049d4:	b745                	j	80004974 <fileread+0x60>

00000000800049d6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049d6:	715d                	addi	sp,sp,-80
    800049d8:	e486                	sd	ra,72(sp)
    800049da:	e0a2                	sd	s0,64(sp)
    800049dc:	fc26                	sd	s1,56(sp)
    800049de:	f84a                	sd	s2,48(sp)
    800049e0:	f44e                	sd	s3,40(sp)
    800049e2:	f052                	sd	s4,32(sp)
    800049e4:	ec56                	sd	s5,24(sp)
    800049e6:	e85a                	sd	s6,16(sp)
    800049e8:	e45e                	sd	s7,8(sp)
    800049ea:	e062                	sd	s8,0(sp)
    800049ec:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049ee:	00954783          	lbu	a5,9(a0)
    800049f2:	10078663          	beqz	a5,80004afe <filewrite+0x128>
    800049f6:	892a                	mv	s2,a0
    800049f8:	8aae                	mv	s5,a1
    800049fa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049fc:	411c                	lw	a5,0(a0)
    800049fe:	4705                	li	a4,1
    80004a00:	02e78263          	beq	a5,a4,80004a24 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a04:	470d                	li	a4,3
    80004a06:	02e78663          	beq	a5,a4,80004a32 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a0a:	4709                	li	a4,2
    80004a0c:	0ee79163          	bne	a5,a4,80004aee <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a10:	0ac05d63          	blez	a2,80004aca <filewrite+0xf4>
    int i = 0;
    80004a14:	4981                	li	s3,0
    80004a16:	6b05                	lui	s6,0x1
    80004a18:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a1c:	6b85                	lui	s7,0x1
    80004a1e:	c00b8b9b          	addiw	s7,s7,-1024
    80004a22:	a861                	j	80004aba <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a24:	6908                	ld	a0,16(a0)
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	22e080e7          	jalr	558(ra) # 80004c54 <pipewrite>
    80004a2e:	8a2a                	mv	s4,a0
    80004a30:	a045                	j	80004ad0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a32:	02451783          	lh	a5,36(a0)
    80004a36:	03079693          	slli	a3,a5,0x30
    80004a3a:	92c1                	srli	a3,a3,0x30
    80004a3c:	4725                	li	a4,9
    80004a3e:	0cd76263          	bltu	a4,a3,80004b02 <filewrite+0x12c>
    80004a42:	0792                	slli	a5,a5,0x4
    80004a44:	0001d717          	auipc	a4,0x1d
    80004a48:	ba470713          	addi	a4,a4,-1116 # 800215e8 <devsw>
    80004a4c:	97ba                	add	a5,a5,a4
    80004a4e:	679c                	ld	a5,8(a5)
    80004a50:	cbdd                	beqz	a5,80004b06 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a52:	4505                	li	a0,1
    80004a54:	9782                	jalr	a5
    80004a56:	8a2a                	mv	s4,a0
    80004a58:	a8a5                	j	80004ad0 <filewrite+0xfa>
    80004a5a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a5e:	00000097          	auipc	ra,0x0
    80004a62:	8b0080e7          	jalr	-1872(ra) # 8000430e <begin_op>
      ilock(f->ip);
    80004a66:	01893503          	ld	a0,24(s2)
    80004a6a:	fffff097          	auipc	ra,0xfffff
    80004a6e:	ee2080e7          	jalr	-286(ra) # 8000394c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a72:	8762                	mv	a4,s8
    80004a74:	02092683          	lw	a3,32(s2)
    80004a78:	01598633          	add	a2,s3,s5
    80004a7c:	4585                	li	a1,1
    80004a7e:	01893503          	ld	a0,24(s2)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	276080e7          	jalr	630(ra) # 80003cf8 <writei>
    80004a8a:	84aa                	mv	s1,a0
    80004a8c:	00a05763          	blez	a0,80004a9a <filewrite+0xc4>
        f->off += r;
    80004a90:	02092783          	lw	a5,32(s2)
    80004a94:	9fa9                	addw	a5,a5,a0
    80004a96:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a9a:	01893503          	ld	a0,24(s2)
    80004a9e:	fffff097          	auipc	ra,0xfffff
    80004aa2:	f70080e7          	jalr	-144(ra) # 80003a0e <iunlock>
      end_op();
    80004aa6:	00000097          	auipc	ra,0x0
    80004aaa:	8e8080e7          	jalr	-1816(ra) # 8000438e <end_op>

      if(r != n1){
    80004aae:	009c1f63          	bne	s8,s1,80004acc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ab2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ab6:	0149db63          	bge	s3,s4,80004acc <filewrite+0xf6>
      int n1 = n - i;
    80004aba:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004abe:	84be                	mv	s1,a5
    80004ac0:	2781                	sext.w	a5,a5
    80004ac2:	f8fb5ce3          	bge	s6,a5,80004a5a <filewrite+0x84>
    80004ac6:	84de                	mv	s1,s7
    80004ac8:	bf49                	j	80004a5a <filewrite+0x84>
    int i = 0;
    80004aca:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004acc:	013a1f63          	bne	s4,s3,80004aea <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ad0:	8552                	mv	a0,s4
    80004ad2:	60a6                	ld	ra,72(sp)
    80004ad4:	6406                	ld	s0,64(sp)
    80004ad6:	74e2                	ld	s1,56(sp)
    80004ad8:	7942                	ld	s2,48(sp)
    80004ada:	79a2                	ld	s3,40(sp)
    80004adc:	7a02                	ld	s4,32(sp)
    80004ade:	6ae2                	ld	s5,24(sp)
    80004ae0:	6b42                	ld	s6,16(sp)
    80004ae2:	6ba2                	ld	s7,8(sp)
    80004ae4:	6c02                	ld	s8,0(sp)
    80004ae6:	6161                	addi	sp,sp,80
    80004ae8:	8082                	ret
    ret = (i == n ? n : -1);
    80004aea:	5a7d                	li	s4,-1
    80004aec:	b7d5                	j	80004ad0 <filewrite+0xfa>
    panic("filewrite");
    80004aee:	00004517          	auipc	a0,0x4
    80004af2:	e1250513          	addi	a0,a0,-494 # 80008900 <sysargs+0x220>
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	a4e080e7          	jalr	-1458(ra) # 80000544 <panic>
    return -1;
    80004afe:	5a7d                	li	s4,-1
    80004b00:	bfc1                	j	80004ad0 <filewrite+0xfa>
      return -1;
    80004b02:	5a7d                	li	s4,-1
    80004b04:	b7f1                	j	80004ad0 <filewrite+0xfa>
    80004b06:	5a7d                	li	s4,-1
    80004b08:	b7e1                	j	80004ad0 <filewrite+0xfa>

0000000080004b0a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b0a:	7179                	addi	sp,sp,-48
    80004b0c:	f406                	sd	ra,40(sp)
    80004b0e:	f022                	sd	s0,32(sp)
    80004b10:	ec26                	sd	s1,24(sp)
    80004b12:	e84a                	sd	s2,16(sp)
    80004b14:	e44e                	sd	s3,8(sp)
    80004b16:	e052                	sd	s4,0(sp)
    80004b18:	1800                	addi	s0,sp,48
    80004b1a:	84aa                	mv	s1,a0
    80004b1c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b1e:	0005b023          	sd	zero,0(a1)
    80004b22:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b26:	00000097          	auipc	ra,0x0
    80004b2a:	bf8080e7          	jalr	-1032(ra) # 8000471e <filealloc>
    80004b2e:	e088                	sd	a0,0(s1)
    80004b30:	c551                	beqz	a0,80004bbc <pipealloc+0xb2>
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	bec080e7          	jalr	-1044(ra) # 8000471e <filealloc>
    80004b3a:	00aa3023          	sd	a0,0(s4)
    80004b3e:	c92d                	beqz	a0,80004bb0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	fba080e7          	jalr	-70(ra) # 80000afa <kalloc>
    80004b48:	892a                	mv	s2,a0
    80004b4a:	c125                	beqz	a0,80004baa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b4c:	4985                	li	s3,1
    80004b4e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b52:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b56:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b5a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b5e:	00004597          	auipc	a1,0x4
    80004b62:	93258593          	addi	a1,a1,-1742 # 80008490 <states.1728+0x1c8>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	ff4080e7          	jalr	-12(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004b6e:	609c                	ld	a5,0(s1)
    80004b70:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b74:	609c                	ld	a5,0(s1)
    80004b76:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b7a:	609c                	ld	a5,0(s1)
    80004b7c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b80:	609c                	ld	a5,0(s1)
    80004b82:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b86:	000a3783          	ld	a5,0(s4)
    80004b8a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b8e:	000a3783          	ld	a5,0(s4)
    80004b92:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b96:	000a3783          	ld	a5,0(s4)
    80004b9a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b9e:	000a3783          	ld	a5,0(s4)
    80004ba2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ba6:	4501                	li	a0,0
    80004ba8:	a025                	j	80004bd0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004baa:	6088                	ld	a0,0(s1)
    80004bac:	e501                	bnez	a0,80004bb4 <pipealloc+0xaa>
    80004bae:	a039                	j	80004bbc <pipealloc+0xb2>
    80004bb0:	6088                	ld	a0,0(s1)
    80004bb2:	c51d                	beqz	a0,80004be0 <pipealloc+0xd6>
    fileclose(*f0);
    80004bb4:	00000097          	auipc	ra,0x0
    80004bb8:	c26080e7          	jalr	-986(ra) # 800047da <fileclose>
  if(*f1)
    80004bbc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bc0:	557d                	li	a0,-1
  if(*f1)
    80004bc2:	c799                	beqz	a5,80004bd0 <pipealloc+0xc6>
    fileclose(*f1);
    80004bc4:	853e                	mv	a0,a5
    80004bc6:	00000097          	auipc	ra,0x0
    80004bca:	c14080e7          	jalr	-1004(ra) # 800047da <fileclose>
  return -1;
    80004bce:	557d                	li	a0,-1
}
    80004bd0:	70a2                	ld	ra,40(sp)
    80004bd2:	7402                	ld	s0,32(sp)
    80004bd4:	64e2                	ld	s1,24(sp)
    80004bd6:	6942                	ld	s2,16(sp)
    80004bd8:	69a2                	ld	s3,8(sp)
    80004bda:	6a02                	ld	s4,0(sp)
    80004bdc:	6145                	addi	sp,sp,48
    80004bde:	8082                	ret
  return -1;
    80004be0:	557d                	li	a0,-1
    80004be2:	b7fd                	j	80004bd0 <pipealloc+0xc6>

0000000080004be4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004be4:	1101                	addi	sp,sp,-32
    80004be6:	ec06                	sd	ra,24(sp)
    80004be8:	e822                	sd	s0,16(sp)
    80004bea:	e426                	sd	s1,8(sp)
    80004bec:	e04a                	sd	s2,0(sp)
    80004bee:	1000                	addi	s0,sp,32
    80004bf0:	84aa                	mv	s1,a0
    80004bf2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	ff6080e7          	jalr	-10(ra) # 80000bea <acquire>
  if(writable){
    80004bfc:	02090d63          	beqz	s2,80004c36 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c00:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c04:	21848513          	addi	a0,s1,536
    80004c08:	ffffd097          	auipc	ra,0xffffd
    80004c0c:	4e6080e7          	jalr	1254(ra) # 800020ee <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c10:	2204b783          	ld	a5,544(s1)
    80004c14:	eb95                	bnez	a5,80004c48 <pipeclose+0x64>
    release(&pi->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	086080e7          	jalr	134(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	ddc080e7          	jalr	-548(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004c2a:	60e2                	ld	ra,24(sp)
    80004c2c:	6442                	ld	s0,16(sp)
    80004c2e:	64a2                	ld	s1,8(sp)
    80004c30:	6902                	ld	s2,0(sp)
    80004c32:	6105                	addi	sp,sp,32
    80004c34:	8082                	ret
    pi->readopen = 0;
    80004c36:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c3a:	21c48513          	addi	a0,s1,540
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	4b0080e7          	jalr	1200(ra) # 800020ee <wakeup>
    80004c46:	b7e9                	j	80004c10 <pipeclose+0x2c>
    release(&pi->lock);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	054080e7          	jalr	84(ra) # 80000c9e <release>
}
    80004c52:	bfe1                	j	80004c2a <pipeclose+0x46>

0000000080004c54 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c54:	7159                	addi	sp,sp,-112
    80004c56:	f486                	sd	ra,104(sp)
    80004c58:	f0a2                	sd	s0,96(sp)
    80004c5a:	eca6                	sd	s1,88(sp)
    80004c5c:	e8ca                	sd	s2,80(sp)
    80004c5e:	e4ce                	sd	s3,72(sp)
    80004c60:	e0d2                	sd	s4,64(sp)
    80004c62:	fc56                	sd	s5,56(sp)
    80004c64:	f85a                	sd	s6,48(sp)
    80004c66:	f45e                	sd	s7,40(sp)
    80004c68:	f062                	sd	s8,32(sp)
    80004c6a:	ec66                	sd	s9,24(sp)
    80004c6c:	1880                	addi	s0,sp,112
    80004c6e:	84aa                	mv	s1,a0
    80004c70:	8aae                	mv	s5,a1
    80004c72:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	d52080e7          	jalr	-686(ra) # 800019c6 <myproc>
    80004c7c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	f6a080e7          	jalr	-150(ra) # 80000bea <acquire>
  while(i < n){
    80004c88:	0d405463          	blez	s4,80004d50 <pipewrite+0xfc>
    80004c8c:	8ba6                	mv	s7,s1
  int i = 0;
    80004c8e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c90:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c92:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c96:	21c48c13          	addi	s8,s1,540
    80004c9a:	a08d                	j	80004cfc <pipewrite+0xa8>
      release(&pi->lock);
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	000080e7          	jalr	ra # 80000c9e <release>
      return -1;
    80004ca6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ca8:	854a                	mv	a0,s2
    80004caa:	70a6                	ld	ra,104(sp)
    80004cac:	7406                	ld	s0,96(sp)
    80004cae:	64e6                	ld	s1,88(sp)
    80004cb0:	6946                	ld	s2,80(sp)
    80004cb2:	69a6                	ld	s3,72(sp)
    80004cb4:	6a06                	ld	s4,64(sp)
    80004cb6:	7ae2                	ld	s5,56(sp)
    80004cb8:	7b42                	ld	s6,48(sp)
    80004cba:	7ba2                	ld	s7,40(sp)
    80004cbc:	7c02                	ld	s8,32(sp)
    80004cbe:	6ce2                	ld	s9,24(sp)
    80004cc0:	6165                	addi	sp,sp,112
    80004cc2:	8082                	ret
      wakeup(&pi->nread);
    80004cc4:	8566                	mv	a0,s9
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	428080e7          	jalr	1064(ra) # 800020ee <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cce:	85de                	mv	a1,s7
    80004cd0:	8562                	mv	a0,s8
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	3b8080e7          	jalr	952(ra) # 8000208a <sleep>
    80004cda:	a839                	j	80004cf8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cdc:	21c4a783          	lw	a5,540(s1)
    80004ce0:	0017871b          	addiw	a4,a5,1
    80004ce4:	20e4ae23          	sw	a4,540(s1)
    80004ce8:	1ff7f793          	andi	a5,a5,511
    80004cec:	97a6                	add	a5,a5,s1
    80004cee:	f9f44703          	lbu	a4,-97(s0)
    80004cf2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cf6:	2905                	addiw	s2,s2,1
  while(i < n){
    80004cf8:	05495063          	bge	s2,s4,80004d38 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004cfc:	2204a783          	lw	a5,544(s1)
    80004d00:	dfd1                	beqz	a5,80004c9c <pipewrite+0x48>
    80004d02:	854e                	mv	a0,s3
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	62e080e7          	jalr	1582(ra) # 80002332 <killed>
    80004d0c:	f941                	bnez	a0,80004c9c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d0e:	2184a783          	lw	a5,536(s1)
    80004d12:	21c4a703          	lw	a4,540(s1)
    80004d16:	2007879b          	addiw	a5,a5,512
    80004d1a:	faf705e3          	beq	a4,a5,80004cc4 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d1e:	4685                	li	a3,1
    80004d20:	01590633          	add	a2,s2,s5
    80004d24:	f9f40593          	addi	a1,s0,-97
    80004d28:	0509b503          	ld	a0,80(s3)
    80004d2c:	ffffd097          	auipc	ra,0xffffd
    80004d30:	9e4080e7          	jalr	-1564(ra) # 80001710 <copyin>
    80004d34:	fb6514e3          	bne	a0,s6,80004cdc <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d38:	21848513          	addi	a0,s1,536
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	3b2080e7          	jalr	946(ra) # 800020ee <wakeup>
  release(&pi->lock);
    80004d44:	8526                	mv	a0,s1
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	f58080e7          	jalr	-168(ra) # 80000c9e <release>
  return i;
    80004d4e:	bfa9                	j	80004ca8 <pipewrite+0x54>
  int i = 0;
    80004d50:	4901                	li	s2,0
    80004d52:	b7dd                	j	80004d38 <pipewrite+0xe4>

0000000080004d54 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d54:	715d                	addi	sp,sp,-80
    80004d56:	e486                	sd	ra,72(sp)
    80004d58:	e0a2                	sd	s0,64(sp)
    80004d5a:	fc26                	sd	s1,56(sp)
    80004d5c:	f84a                	sd	s2,48(sp)
    80004d5e:	f44e                	sd	s3,40(sp)
    80004d60:	f052                	sd	s4,32(sp)
    80004d62:	ec56                	sd	s5,24(sp)
    80004d64:	e85a                	sd	s6,16(sp)
    80004d66:	0880                	addi	s0,sp,80
    80004d68:	84aa                	mv	s1,a0
    80004d6a:	892e                	mv	s2,a1
    80004d6c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	c58080e7          	jalr	-936(ra) # 800019c6 <myproc>
    80004d76:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d78:	8b26                	mv	s6,s1
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	e6e080e7          	jalr	-402(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d84:	2184a703          	lw	a4,536(s1)
    80004d88:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d8c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d90:	02f71763          	bne	a4,a5,80004dbe <piperead+0x6a>
    80004d94:	2244a783          	lw	a5,548(s1)
    80004d98:	c39d                	beqz	a5,80004dbe <piperead+0x6a>
    if(killed(pr)){
    80004d9a:	8552                	mv	a0,s4
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	596080e7          	jalr	1430(ra) # 80002332 <killed>
    80004da4:	e941                	bnez	a0,80004e34 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004da6:	85da                	mv	a1,s6
    80004da8:	854e                	mv	a0,s3
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	2e0080e7          	jalr	736(ra) # 8000208a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db2:	2184a703          	lw	a4,536(s1)
    80004db6:	21c4a783          	lw	a5,540(s1)
    80004dba:	fcf70de3          	beq	a4,a5,80004d94 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dbe:	09505263          	blez	s5,80004e42 <piperead+0xee>
    80004dc2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dc6:	2184a783          	lw	a5,536(s1)
    80004dca:	21c4a703          	lw	a4,540(s1)
    80004dce:	02f70d63          	beq	a4,a5,80004e08 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dd2:	0017871b          	addiw	a4,a5,1
    80004dd6:	20e4ac23          	sw	a4,536(s1)
    80004dda:	1ff7f793          	andi	a5,a5,511
    80004dde:	97a6                	add	a5,a5,s1
    80004de0:	0187c783          	lbu	a5,24(a5)
    80004de4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004de8:	4685                	li	a3,1
    80004dea:	fbf40613          	addi	a2,s0,-65
    80004dee:	85ca                	mv	a1,s2
    80004df0:	050a3503          	ld	a0,80(s4)
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	890080e7          	jalr	-1904(ra) # 80001684 <copyout>
    80004dfc:	01650663          	beq	a0,s6,80004e08 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e00:	2985                	addiw	s3,s3,1
    80004e02:	0905                	addi	s2,s2,1
    80004e04:	fd3a91e3          	bne	s5,s3,80004dc6 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e08:	21c48513          	addi	a0,s1,540
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	2e2080e7          	jalr	738(ra) # 800020ee <wakeup>
  release(&pi->lock);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	e88080e7          	jalr	-376(ra) # 80000c9e <release>
  return i;
}
    80004e1e:	854e                	mv	a0,s3
    80004e20:	60a6                	ld	ra,72(sp)
    80004e22:	6406                	ld	s0,64(sp)
    80004e24:	74e2                	ld	s1,56(sp)
    80004e26:	7942                	ld	s2,48(sp)
    80004e28:	79a2                	ld	s3,40(sp)
    80004e2a:	7a02                	ld	s4,32(sp)
    80004e2c:	6ae2                	ld	s5,24(sp)
    80004e2e:	6b42                	ld	s6,16(sp)
    80004e30:	6161                	addi	sp,sp,80
    80004e32:	8082                	ret
      release(&pi->lock);
    80004e34:	8526                	mv	a0,s1
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	e68080e7          	jalr	-408(ra) # 80000c9e <release>
      return -1;
    80004e3e:	59fd                	li	s3,-1
    80004e40:	bff9                	j	80004e1e <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e42:	4981                	li	s3,0
    80004e44:	b7d1                	j	80004e08 <piperead+0xb4>

0000000080004e46 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e46:	1141                	addi	sp,sp,-16
    80004e48:	e422                	sd	s0,8(sp)
    80004e4a:	0800                	addi	s0,sp,16
    80004e4c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e4e:	8905                	andi	a0,a0,1
    80004e50:	c111                	beqz	a0,80004e54 <flags2perm+0xe>
      perm = PTE_X;
    80004e52:	4521                	li	a0,8
    if(flags & 0x2)
    80004e54:	8b89                	andi	a5,a5,2
    80004e56:	c399                	beqz	a5,80004e5c <flags2perm+0x16>
      perm |= PTE_W;
    80004e58:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e5c:	6422                	ld	s0,8(sp)
    80004e5e:	0141                	addi	sp,sp,16
    80004e60:	8082                	ret

0000000080004e62 <exec>:

int
exec(char *path, char **argv)
{
    80004e62:	df010113          	addi	sp,sp,-528
    80004e66:	20113423          	sd	ra,520(sp)
    80004e6a:	20813023          	sd	s0,512(sp)
    80004e6e:	ffa6                	sd	s1,504(sp)
    80004e70:	fbca                	sd	s2,496(sp)
    80004e72:	f7ce                	sd	s3,488(sp)
    80004e74:	f3d2                	sd	s4,480(sp)
    80004e76:	efd6                	sd	s5,472(sp)
    80004e78:	ebda                	sd	s6,464(sp)
    80004e7a:	e7de                	sd	s7,456(sp)
    80004e7c:	e3e2                	sd	s8,448(sp)
    80004e7e:	ff66                	sd	s9,440(sp)
    80004e80:	fb6a                	sd	s10,432(sp)
    80004e82:	f76e                	sd	s11,424(sp)
    80004e84:	0c00                	addi	s0,sp,528
    80004e86:	84aa                	mv	s1,a0
    80004e88:	dea43c23          	sd	a0,-520(s0)
    80004e8c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e90:	ffffd097          	auipc	ra,0xffffd
    80004e94:	b36080e7          	jalr	-1226(ra) # 800019c6 <myproc>
    80004e98:	892a                	mv	s2,a0

  begin_op();
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	474080e7          	jalr	1140(ra) # 8000430e <begin_op>

  if((ip = namei(path)) == 0){
    80004ea2:	8526                	mv	a0,s1
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	24e080e7          	jalr	590(ra) # 800040f2 <namei>
    80004eac:	c92d                	beqz	a0,80004f1e <exec+0xbc>
    80004eae:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	a9c080e7          	jalr	-1380(ra) # 8000394c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eb8:	04000713          	li	a4,64
    80004ebc:	4681                	li	a3,0
    80004ebe:	e5040613          	addi	a2,s0,-432
    80004ec2:	4581                	li	a1,0
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	fffff097          	auipc	ra,0xfffff
    80004eca:	d3a080e7          	jalr	-710(ra) # 80003c00 <readi>
    80004ece:	04000793          	li	a5,64
    80004ed2:	00f51a63          	bne	a0,a5,80004ee6 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ed6:	e5042703          	lw	a4,-432(s0)
    80004eda:	464c47b7          	lui	a5,0x464c4
    80004ede:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ee2:	04f70463          	beq	a4,a5,80004f2a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ee6:	8526                	mv	a0,s1
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	cc6080e7          	jalr	-826(ra) # 80003bae <iunlockput>
    end_op();
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	49e080e7          	jalr	1182(ra) # 8000438e <end_op>
  }
  return -1;
    80004ef8:	557d                	li	a0,-1
}
    80004efa:	20813083          	ld	ra,520(sp)
    80004efe:	20013403          	ld	s0,512(sp)
    80004f02:	74fe                	ld	s1,504(sp)
    80004f04:	795e                	ld	s2,496(sp)
    80004f06:	79be                	ld	s3,488(sp)
    80004f08:	7a1e                	ld	s4,480(sp)
    80004f0a:	6afe                	ld	s5,472(sp)
    80004f0c:	6b5e                	ld	s6,464(sp)
    80004f0e:	6bbe                	ld	s7,456(sp)
    80004f10:	6c1e                	ld	s8,448(sp)
    80004f12:	7cfa                	ld	s9,440(sp)
    80004f14:	7d5a                	ld	s10,432(sp)
    80004f16:	7dba                	ld	s11,424(sp)
    80004f18:	21010113          	addi	sp,sp,528
    80004f1c:	8082                	ret
    end_op();
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	470080e7          	jalr	1136(ra) # 8000438e <end_op>
    return -1;
    80004f26:	557d                	li	a0,-1
    80004f28:	bfc9                	j	80004efa <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f2a:	854a                	mv	a0,s2
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	b5e080e7          	jalr	-1186(ra) # 80001a8a <proc_pagetable>
    80004f34:	8baa                	mv	s7,a0
    80004f36:	d945                	beqz	a0,80004ee6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f38:	e7042983          	lw	s3,-400(s0)
    80004f3c:	e8845783          	lhu	a5,-376(s0)
    80004f40:	c7ad                	beqz	a5,80004faa <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f42:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f44:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f46:	6c85                	lui	s9,0x1
    80004f48:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f4c:	def43823          	sd	a5,-528(s0)
    80004f50:	ac0d                	j	80005182 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f52:	00004517          	auipc	a0,0x4
    80004f56:	9be50513          	addi	a0,a0,-1602 # 80008910 <sysargs+0x230>
    80004f5a:	ffffb097          	auipc	ra,0xffffb
    80004f5e:	5ea080e7          	jalr	1514(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f62:	8756                	mv	a4,s5
    80004f64:	012d86bb          	addw	a3,s11,s2
    80004f68:	4581                	li	a1,0
    80004f6a:	8526                	mv	a0,s1
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	c94080e7          	jalr	-876(ra) # 80003c00 <readi>
    80004f74:	2501                	sext.w	a0,a0
    80004f76:	1aaa9a63          	bne	s5,a0,8000512a <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004f7a:	6785                	lui	a5,0x1
    80004f7c:	0127893b          	addw	s2,a5,s2
    80004f80:	77fd                	lui	a5,0xfffff
    80004f82:	01478a3b          	addw	s4,a5,s4
    80004f86:	1f897563          	bgeu	s2,s8,80005170 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004f8a:	02091593          	slli	a1,s2,0x20
    80004f8e:	9181                	srli	a1,a1,0x20
    80004f90:	95ea                	add	a1,a1,s10
    80004f92:	855e                	mv	a0,s7
    80004f94:	ffffc097          	auipc	ra,0xffffc
    80004f98:	0e4080e7          	jalr	228(ra) # 80001078 <walkaddr>
    80004f9c:	862a                	mv	a2,a0
    if(pa == 0)
    80004f9e:	d955                	beqz	a0,80004f52 <exec+0xf0>
      n = PGSIZE;
    80004fa0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fa2:	fd9a70e3          	bgeu	s4,s9,80004f62 <exec+0x100>
      n = sz - i;
    80004fa6:	8ad2                	mv	s5,s4
    80004fa8:	bf6d                	j	80004f62 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004faa:	4a01                	li	s4,0
  iunlockput(ip);
    80004fac:	8526                	mv	a0,s1
    80004fae:	fffff097          	auipc	ra,0xfffff
    80004fb2:	c00080e7          	jalr	-1024(ra) # 80003bae <iunlockput>
  end_op();
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	3d8080e7          	jalr	984(ra) # 8000438e <end_op>
  p = myproc();
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	a08080e7          	jalr	-1528(ra) # 800019c6 <myproc>
    80004fc6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fc8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fcc:	6785                	lui	a5,0x1
    80004fce:	17fd                	addi	a5,a5,-1
    80004fd0:	9a3e                	add	s4,s4,a5
    80004fd2:	757d                	lui	a0,0xfffff
    80004fd4:	00aa77b3          	and	a5,s4,a0
    80004fd8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fdc:	4691                	li	a3,4
    80004fde:	6609                	lui	a2,0x2
    80004fe0:	963e                	add	a2,a2,a5
    80004fe2:	85be                	mv	a1,a5
    80004fe4:	855e                	mv	a0,s7
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	446080e7          	jalr	1094(ra) # 8000142c <uvmalloc>
    80004fee:	8b2a                	mv	s6,a0
  ip = 0;
    80004ff0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ff2:	12050c63          	beqz	a0,8000512a <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ff6:	75f9                	lui	a1,0xffffe
    80004ff8:	95aa                	add	a1,a1,a0
    80004ffa:	855e                	mv	a0,s7
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	656080e7          	jalr	1622(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005004:	7c7d                	lui	s8,0xfffff
    80005006:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005008:	e0043783          	ld	a5,-512(s0)
    8000500c:	6388                	ld	a0,0(a5)
    8000500e:	c535                	beqz	a0,8000507a <exec+0x218>
    80005010:	e9040993          	addi	s3,s0,-368
    80005014:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005018:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	e50080e7          	jalr	-432(ra) # 80000e6a <strlen>
    80005022:	2505                	addiw	a0,a0,1
    80005024:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005028:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000502c:	13896663          	bltu	s2,s8,80005158 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005030:	e0043d83          	ld	s11,-512(s0)
    80005034:	000dba03          	ld	s4,0(s11)
    80005038:	8552                	mv	a0,s4
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	e30080e7          	jalr	-464(ra) # 80000e6a <strlen>
    80005042:	0015069b          	addiw	a3,a0,1
    80005046:	8652                	mv	a2,s4
    80005048:	85ca                	mv	a1,s2
    8000504a:	855e                	mv	a0,s7
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	638080e7          	jalr	1592(ra) # 80001684 <copyout>
    80005054:	10054663          	bltz	a0,80005160 <exec+0x2fe>
    ustack[argc] = sp;
    80005058:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000505c:	0485                	addi	s1,s1,1
    8000505e:	008d8793          	addi	a5,s11,8
    80005062:	e0f43023          	sd	a5,-512(s0)
    80005066:	008db503          	ld	a0,8(s11)
    8000506a:	c911                	beqz	a0,8000507e <exec+0x21c>
    if(argc >= MAXARG)
    8000506c:	09a1                	addi	s3,s3,8
    8000506e:	fb3c96e3          	bne	s9,s3,8000501a <exec+0x1b8>
  sz = sz1;
    80005072:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005076:	4481                	li	s1,0
    80005078:	a84d                	j	8000512a <exec+0x2c8>
  sp = sz;
    8000507a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000507c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000507e:	00349793          	slli	a5,s1,0x3
    80005082:	f9040713          	addi	a4,s0,-112
    80005086:	97ba                	add	a5,a5,a4
    80005088:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000508c:	00148693          	addi	a3,s1,1
    80005090:	068e                	slli	a3,a3,0x3
    80005092:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005096:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000509a:	01897663          	bgeu	s2,s8,800050a6 <exec+0x244>
  sz = sz1;
    8000509e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a2:	4481                	li	s1,0
    800050a4:	a059                	j	8000512a <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050a6:	e9040613          	addi	a2,s0,-368
    800050aa:	85ca                	mv	a1,s2
    800050ac:	855e                	mv	a0,s7
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	5d6080e7          	jalr	1494(ra) # 80001684 <copyout>
    800050b6:	0a054963          	bltz	a0,80005168 <exec+0x306>
  p->trapframe->a1 = sp;
    800050ba:	058ab783          	ld	a5,88(s5)
    800050be:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050c2:	df843783          	ld	a5,-520(s0)
    800050c6:	0007c703          	lbu	a4,0(a5)
    800050ca:	cf11                	beqz	a4,800050e6 <exec+0x284>
    800050cc:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050ce:	02f00693          	li	a3,47
    800050d2:	a039                	j	800050e0 <exec+0x27e>
      last = s+1;
    800050d4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050d8:	0785                	addi	a5,a5,1
    800050da:	fff7c703          	lbu	a4,-1(a5)
    800050de:	c701                	beqz	a4,800050e6 <exec+0x284>
    if(*s == '/')
    800050e0:	fed71ce3          	bne	a4,a3,800050d8 <exec+0x276>
    800050e4:	bfc5                	j	800050d4 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800050e6:	4641                	li	a2,16
    800050e8:	df843583          	ld	a1,-520(s0)
    800050ec:	158a8513          	addi	a0,s5,344
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	d48080e7          	jalr	-696(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    800050f8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050fc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005100:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005104:	058ab783          	ld	a5,88(s5)
    80005108:	e6843703          	ld	a4,-408(s0)
    8000510c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000510e:	058ab783          	ld	a5,88(s5)
    80005112:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005116:	85ea                	mv	a1,s10
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	a0e080e7          	jalr	-1522(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005120:	0004851b          	sext.w	a0,s1
    80005124:	bbd9                	j	80004efa <exec+0x98>
    80005126:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000512a:	e0843583          	ld	a1,-504(s0)
    8000512e:	855e                	mv	a0,s7
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	9f6080e7          	jalr	-1546(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005138:	da0497e3          	bnez	s1,80004ee6 <exec+0x84>
  return -1;
    8000513c:	557d                	li	a0,-1
    8000513e:	bb75                	j	80004efa <exec+0x98>
    80005140:	e1443423          	sd	s4,-504(s0)
    80005144:	b7dd                	j	8000512a <exec+0x2c8>
    80005146:	e1443423          	sd	s4,-504(s0)
    8000514a:	b7c5                	j	8000512a <exec+0x2c8>
    8000514c:	e1443423          	sd	s4,-504(s0)
    80005150:	bfe9                	j	8000512a <exec+0x2c8>
    80005152:	e1443423          	sd	s4,-504(s0)
    80005156:	bfd1                	j	8000512a <exec+0x2c8>
  sz = sz1;
    80005158:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000515c:	4481                	li	s1,0
    8000515e:	b7f1                	j	8000512a <exec+0x2c8>
  sz = sz1;
    80005160:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005164:	4481                	li	s1,0
    80005166:	b7d1                	j	8000512a <exec+0x2c8>
  sz = sz1;
    80005168:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516c:	4481                	li	s1,0
    8000516e:	bf75                	j	8000512a <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005170:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005174:	2b05                	addiw	s6,s6,1
    80005176:	0389899b          	addiw	s3,s3,56
    8000517a:	e8845783          	lhu	a5,-376(s0)
    8000517e:	e2fb57e3          	bge	s6,a5,80004fac <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005182:	2981                	sext.w	s3,s3
    80005184:	03800713          	li	a4,56
    80005188:	86ce                	mv	a3,s3
    8000518a:	e1840613          	addi	a2,s0,-488
    8000518e:	4581                	li	a1,0
    80005190:	8526                	mv	a0,s1
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	a6e080e7          	jalr	-1426(ra) # 80003c00 <readi>
    8000519a:	03800793          	li	a5,56
    8000519e:	f8f514e3          	bne	a0,a5,80005126 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800051a2:	e1842783          	lw	a5,-488(s0)
    800051a6:	4705                	li	a4,1
    800051a8:	fce796e3          	bne	a5,a4,80005174 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800051ac:	e4043903          	ld	s2,-448(s0)
    800051b0:	e3843783          	ld	a5,-456(s0)
    800051b4:	f8f966e3          	bltu	s2,a5,80005140 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051b8:	e2843783          	ld	a5,-472(s0)
    800051bc:	993e                	add	s2,s2,a5
    800051be:	f8f964e3          	bltu	s2,a5,80005146 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800051c2:	df043703          	ld	a4,-528(s0)
    800051c6:	8ff9                	and	a5,a5,a4
    800051c8:	f3d1                	bnez	a5,8000514c <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051ca:	e1c42503          	lw	a0,-484(s0)
    800051ce:	00000097          	auipc	ra,0x0
    800051d2:	c78080e7          	jalr	-904(ra) # 80004e46 <flags2perm>
    800051d6:	86aa                	mv	a3,a0
    800051d8:	864a                	mv	a2,s2
    800051da:	85d2                	mv	a1,s4
    800051dc:	855e                	mv	a0,s7
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	24e080e7          	jalr	590(ra) # 8000142c <uvmalloc>
    800051e6:	e0a43423          	sd	a0,-504(s0)
    800051ea:	d525                	beqz	a0,80005152 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051ec:	e2843d03          	ld	s10,-472(s0)
    800051f0:	e2042d83          	lw	s11,-480(s0)
    800051f4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051f8:	f60c0ce3          	beqz	s8,80005170 <exec+0x30e>
    800051fc:	8a62                	mv	s4,s8
    800051fe:	4901                	li	s2,0
    80005200:	b369                	j	80004f8a <exec+0x128>

0000000080005202 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005202:	7179                	addi	sp,sp,-48
    80005204:	f406                	sd	ra,40(sp)
    80005206:	f022                	sd	s0,32(sp)
    80005208:	ec26                	sd	s1,24(sp)
    8000520a:	e84a                	sd	s2,16(sp)
    8000520c:	1800                	addi	s0,sp,48
    8000520e:	892e                	mv	s2,a1
    80005210:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005212:	fdc40593          	addi	a1,s0,-36
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	942080e7          	jalr	-1726(ra) # 80002b58 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000521e:	fdc42703          	lw	a4,-36(s0)
    80005222:	47bd                	li	a5,15
    80005224:	02e7eb63          	bltu	a5,a4,8000525a <argfd+0x58>
    80005228:	ffffc097          	auipc	ra,0xffffc
    8000522c:	79e080e7          	jalr	1950(ra) # 800019c6 <myproc>
    80005230:	fdc42703          	lw	a4,-36(s0)
    80005234:	01a70793          	addi	a5,a4,26
    80005238:	078e                	slli	a5,a5,0x3
    8000523a:	953e                	add	a0,a0,a5
    8000523c:	611c                	ld	a5,0(a0)
    8000523e:	c385                	beqz	a5,8000525e <argfd+0x5c>
    return -1;
  if(pfd)
    80005240:	00090463          	beqz	s2,80005248 <argfd+0x46>
    *pfd = fd;
    80005244:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005248:	4501                	li	a0,0
  if(pf)
    8000524a:	c091                	beqz	s1,8000524e <argfd+0x4c>
    *pf = f;
    8000524c:	e09c                	sd	a5,0(s1)
}
    8000524e:	70a2                	ld	ra,40(sp)
    80005250:	7402                	ld	s0,32(sp)
    80005252:	64e2                	ld	s1,24(sp)
    80005254:	6942                	ld	s2,16(sp)
    80005256:	6145                	addi	sp,sp,48
    80005258:	8082                	ret
    return -1;
    8000525a:	557d                	li	a0,-1
    8000525c:	bfcd                	j	8000524e <argfd+0x4c>
    8000525e:	557d                	li	a0,-1
    80005260:	b7fd                	j	8000524e <argfd+0x4c>

0000000080005262 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005262:	1101                	addi	sp,sp,-32
    80005264:	ec06                	sd	ra,24(sp)
    80005266:	e822                	sd	s0,16(sp)
    80005268:	e426                	sd	s1,8(sp)
    8000526a:	1000                	addi	s0,sp,32
    8000526c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	758080e7          	jalr	1880(ra) # 800019c6 <myproc>
    80005276:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005278:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdc950>
    8000527c:	4501                	li	a0,0
    8000527e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005280:	6398                	ld	a4,0(a5)
    80005282:	cb19                	beqz	a4,80005298 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005284:	2505                	addiw	a0,a0,1
    80005286:	07a1                	addi	a5,a5,8
    80005288:	fed51ce3          	bne	a0,a3,80005280 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000528c:	557d                	li	a0,-1
}
    8000528e:	60e2                	ld	ra,24(sp)
    80005290:	6442                	ld	s0,16(sp)
    80005292:	64a2                	ld	s1,8(sp)
    80005294:	6105                	addi	sp,sp,32
    80005296:	8082                	ret
      p->ofile[fd] = f;
    80005298:	01a50793          	addi	a5,a0,26
    8000529c:	078e                	slli	a5,a5,0x3
    8000529e:	963e                	add	a2,a2,a5
    800052a0:	e204                	sd	s1,0(a2)
      return fd;
    800052a2:	b7f5                	j	8000528e <fdalloc+0x2c>

00000000800052a4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052a4:	715d                	addi	sp,sp,-80
    800052a6:	e486                	sd	ra,72(sp)
    800052a8:	e0a2                	sd	s0,64(sp)
    800052aa:	fc26                	sd	s1,56(sp)
    800052ac:	f84a                	sd	s2,48(sp)
    800052ae:	f44e                	sd	s3,40(sp)
    800052b0:	f052                	sd	s4,32(sp)
    800052b2:	ec56                	sd	s5,24(sp)
    800052b4:	e85a                	sd	s6,16(sp)
    800052b6:	0880                	addi	s0,sp,80
    800052b8:	8b2e                	mv	s6,a1
    800052ba:	89b2                	mv	s3,a2
    800052bc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052be:	fb040593          	addi	a1,s0,-80
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	e4e080e7          	jalr	-434(ra) # 80004110 <nameiparent>
    800052ca:	84aa                	mv	s1,a0
    800052cc:	16050063          	beqz	a0,8000542c <create+0x188>
    return 0;

  ilock(dp);
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	67c080e7          	jalr	1660(ra) # 8000394c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052d8:	4601                	li	a2,0
    800052da:	fb040593          	addi	a1,s0,-80
    800052de:	8526                	mv	a0,s1
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	b50080e7          	jalr	-1200(ra) # 80003e30 <dirlookup>
    800052e8:	8aaa                	mv	s5,a0
    800052ea:	c931                	beqz	a0,8000533e <create+0x9a>
    iunlockput(dp);
    800052ec:	8526                	mv	a0,s1
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	8c0080e7          	jalr	-1856(ra) # 80003bae <iunlockput>
    ilock(ip);
    800052f6:	8556                	mv	a0,s5
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	654080e7          	jalr	1620(ra) # 8000394c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005300:	000b059b          	sext.w	a1,s6
    80005304:	4789                	li	a5,2
    80005306:	02f59563          	bne	a1,a5,80005330 <create+0x8c>
    8000530a:	044ad783          	lhu	a5,68(s5)
    8000530e:	37f9                	addiw	a5,a5,-2
    80005310:	17c2                	slli	a5,a5,0x30
    80005312:	93c1                	srli	a5,a5,0x30
    80005314:	4705                	li	a4,1
    80005316:	00f76d63          	bltu	a4,a5,80005330 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000531a:	8556                	mv	a0,s5
    8000531c:	60a6                	ld	ra,72(sp)
    8000531e:	6406                	ld	s0,64(sp)
    80005320:	74e2                	ld	s1,56(sp)
    80005322:	7942                	ld	s2,48(sp)
    80005324:	79a2                	ld	s3,40(sp)
    80005326:	7a02                	ld	s4,32(sp)
    80005328:	6ae2                	ld	s5,24(sp)
    8000532a:	6b42                	ld	s6,16(sp)
    8000532c:	6161                	addi	sp,sp,80
    8000532e:	8082                	ret
    iunlockput(ip);
    80005330:	8556                	mv	a0,s5
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	87c080e7          	jalr	-1924(ra) # 80003bae <iunlockput>
    return 0;
    8000533a:	4a81                	li	s5,0
    8000533c:	bff9                	j	8000531a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000533e:	85da                	mv	a1,s6
    80005340:	4088                	lw	a0,0(s1)
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	46e080e7          	jalr	1134(ra) # 800037b0 <ialloc>
    8000534a:	8a2a                	mv	s4,a0
    8000534c:	c921                	beqz	a0,8000539c <create+0xf8>
  ilock(ip);
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	5fe080e7          	jalr	1534(ra) # 8000394c <ilock>
  ip->major = major;
    80005356:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000535a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000535e:	4785                	li	a5,1
    80005360:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005364:	8552                	mv	a0,s4
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	51c080e7          	jalr	1308(ra) # 80003882 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000536e:	000b059b          	sext.w	a1,s6
    80005372:	4785                	li	a5,1
    80005374:	02f58b63          	beq	a1,a5,800053aa <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005378:	004a2603          	lw	a2,4(s4)
    8000537c:	fb040593          	addi	a1,s0,-80
    80005380:	8526                	mv	a0,s1
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	cbe080e7          	jalr	-834(ra) # 80004040 <dirlink>
    8000538a:	06054f63          	bltz	a0,80005408 <create+0x164>
  iunlockput(dp);
    8000538e:	8526                	mv	a0,s1
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	81e080e7          	jalr	-2018(ra) # 80003bae <iunlockput>
  return ip;
    80005398:	8ad2                	mv	s5,s4
    8000539a:	b741                	j	8000531a <create+0x76>
    iunlockput(dp);
    8000539c:	8526                	mv	a0,s1
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	810080e7          	jalr	-2032(ra) # 80003bae <iunlockput>
    return 0;
    800053a6:	8ad2                	mv	s5,s4
    800053a8:	bf8d                	j	8000531a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053aa:	004a2603          	lw	a2,4(s4)
    800053ae:	00003597          	auipc	a1,0x3
    800053b2:	58258593          	addi	a1,a1,1410 # 80008930 <sysargs+0x250>
    800053b6:	8552                	mv	a0,s4
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	c88080e7          	jalr	-888(ra) # 80004040 <dirlink>
    800053c0:	04054463          	bltz	a0,80005408 <create+0x164>
    800053c4:	40d0                	lw	a2,4(s1)
    800053c6:	00003597          	auipc	a1,0x3
    800053ca:	57258593          	addi	a1,a1,1394 # 80008938 <sysargs+0x258>
    800053ce:	8552                	mv	a0,s4
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	c70080e7          	jalr	-912(ra) # 80004040 <dirlink>
    800053d8:	02054863          	bltz	a0,80005408 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800053dc:	004a2603          	lw	a2,4(s4)
    800053e0:	fb040593          	addi	a1,s0,-80
    800053e4:	8526                	mv	a0,s1
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	c5a080e7          	jalr	-934(ra) # 80004040 <dirlink>
    800053ee:	00054d63          	bltz	a0,80005408 <create+0x164>
    dp->nlink++;  // for ".."
    800053f2:	04a4d783          	lhu	a5,74(s1)
    800053f6:	2785                	addiw	a5,a5,1
    800053f8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053fc:	8526                	mv	a0,s1
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	484080e7          	jalr	1156(ra) # 80003882 <iupdate>
    80005406:	b761                	j	8000538e <create+0xea>
  ip->nlink = 0;
    80005408:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000540c:	8552                	mv	a0,s4
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	474080e7          	jalr	1140(ra) # 80003882 <iupdate>
  iunlockput(ip);
    80005416:	8552                	mv	a0,s4
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	796080e7          	jalr	1942(ra) # 80003bae <iunlockput>
  iunlockput(dp);
    80005420:	8526                	mv	a0,s1
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	78c080e7          	jalr	1932(ra) # 80003bae <iunlockput>
  return 0;
    8000542a:	bdc5                	j	8000531a <create+0x76>
    return 0;
    8000542c:	8aaa                	mv	s5,a0
    8000542e:	b5f5                	j	8000531a <create+0x76>

0000000080005430 <sys_dup>:
{
    80005430:	7179                	addi	sp,sp,-48
    80005432:	f406                	sd	ra,40(sp)
    80005434:	f022                	sd	s0,32(sp)
    80005436:	ec26                	sd	s1,24(sp)
    80005438:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000543a:	fd840613          	addi	a2,s0,-40
    8000543e:	4581                	li	a1,0
    80005440:	4501                	li	a0,0
    80005442:	00000097          	auipc	ra,0x0
    80005446:	dc0080e7          	jalr	-576(ra) # 80005202 <argfd>
    return -1;
    8000544a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000544c:	02054363          	bltz	a0,80005472 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005450:	fd843503          	ld	a0,-40(s0)
    80005454:	00000097          	auipc	ra,0x0
    80005458:	e0e080e7          	jalr	-498(ra) # 80005262 <fdalloc>
    8000545c:	84aa                	mv	s1,a0
    return -1;
    8000545e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005460:	00054963          	bltz	a0,80005472 <sys_dup+0x42>
  filedup(f);
    80005464:	fd843503          	ld	a0,-40(s0)
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	320080e7          	jalr	800(ra) # 80004788 <filedup>
  return fd;
    80005470:	87a6                	mv	a5,s1
}
    80005472:	853e                	mv	a0,a5
    80005474:	70a2                	ld	ra,40(sp)
    80005476:	7402                	ld	s0,32(sp)
    80005478:	64e2                	ld	s1,24(sp)
    8000547a:	6145                	addi	sp,sp,48
    8000547c:	8082                	ret

000000008000547e <sys_read>:
{
    8000547e:	7179                	addi	sp,sp,-48
    80005480:	f406                	sd	ra,40(sp)
    80005482:	f022                	sd	s0,32(sp)
    80005484:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005486:	fd840593          	addi	a1,s0,-40
    8000548a:	4505                	li	a0,1
    8000548c:	ffffd097          	auipc	ra,0xffffd
    80005490:	6ec080e7          	jalr	1772(ra) # 80002b78 <argaddr>
  argint(2, &n);
    80005494:	fe440593          	addi	a1,s0,-28
    80005498:	4509                	li	a0,2
    8000549a:	ffffd097          	auipc	ra,0xffffd
    8000549e:	6be080e7          	jalr	1726(ra) # 80002b58 <argint>
  if(argfd(0, 0, &f) < 0)
    800054a2:	fe840613          	addi	a2,s0,-24
    800054a6:	4581                	li	a1,0
    800054a8:	4501                	li	a0,0
    800054aa:	00000097          	auipc	ra,0x0
    800054ae:	d58080e7          	jalr	-680(ra) # 80005202 <argfd>
    800054b2:	87aa                	mv	a5,a0
    return -1;
    800054b4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054b6:	0007cc63          	bltz	a5,800054ce <sys_read+0x50>
  return fileread(f, p, n);
    800054ba:	fe442603          	lw	a2,-28(s0)
    800054be:	fd843583          	ld	a1,-40(s0)
    800054c2:	fe843503          	ld	a0,-24(s0)
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	44e080e7          	jalr	1102(ra) # 80004914 <fileread>
}
    800054ce:	70a2                	ld	ra,40(sp)
    800054d0:	7402                	ld	s0,32(sp)
    800054d2:	6145                	addi	sp,sp,48
    800054d4:	8082                	ret

00000000800054d6 <sys_write>:
{
    800054d6:	7179                	addi	sp,sp,-48
    800054d8:	f406                	sd	ra,40(sp)
    800054da:	f022                	sd	s0,32(sp)
    800054dc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054de:	fd840593          	addi	a1,s0,-40
    800054e2:	4505                	li	a0,1
    800054e4:	ffffd097          	auipc	ra,0xffffd
    800054e8:	694080e7          	jalr	1684(ra) # 80002b78 <argaddr>
  argint(2, &n);
    800054ec:	fe440593          	addi	a1,s0,-28
    800054f0:	4509                	li	a0,2
    800054f2:	ffffd097          	auipc	ra,0xffffd
    800054f6:	666080e7          	jalr	1638(ra) # 80002b58 <argint>
  if(argfd(0, 0, &f) < 0)
    800054fa:	fe840613          	addi	a2,s0,-24
    800054fe:	4581                	li	a1,0
    80005500:	4501                	li	a0,0
    80005502:	00000097          	auipc	ra,0x0
    80005506:	d00080e7          	jalr	-768(ra) # 80005202 <argfd>
    8000550a:	87aa                	mv	a5,a0
    return -1;
    8000550c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000550e:	0007cc63          	bltz	a5,80005526 <sys_write+0x50>
  return filewrite(f, p, n);
    80005512:	fe442603          	lw	a2,-28(s0)
    80005516:	fd843583          	ld	a1,-40(s0)
    8000551a:	fe843503          	ld	a0,-24(s0)
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	4b8080e7          	jalr	1208(ra) # 800049d6 <filewrite>
}
    80005526:	70a2                	ld	ra,40(sp)
    80005528:	7402                	ld	s0,32(sp)
    8000552a:	6145                	addi	sp,sp,48
    8000552c:	8082                	ret

000000008000552e <sys_close>:
{
    8000552e:	1101                	addi	sp,sp,-32
    80005530:	ec06                	sd	ra,24(sp)
    80005532:	e822                	sd	s0,16(sp)
    80005534:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005536:	fe040613          	addi	a2,s0,-32
    8000553a:	fec40593          	addi	a1,s0,-20
    8000553e:	4501                	li	a0,0
    80005540:	00000097          	auipc	ra,0x0
    80005544:	cc2080e7          	jalr	-830(ra) # 80005202 <argfd>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000554a:	02054463          	bltz	a0,80005572 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000554e:	ffffc097          	auipc	ra,0xffffc
    80005552:	478080e7          	jalr	1144(ra) # 800019c6 <myproc>
    80005556:	fec42783          	lw	a5,-20(s0)
    8000555a:	07e9                	addi	a5,a5,26
    8000555c:	078e                	slli	a5,a5,0x3
    8000555e:	97aa                	add	a5,a5,a0
    80005560:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005564:	fe043503          	ld	a0,-32(s0)
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	272080e7          	jalr	626(ra) # 800047da <fileclose>
  return 0;
    80005570:	4781                	li	a5,0
}
    80005572:	853e                	mv	a0,a5
    80005574:	60e2                	ld	ra,24(sp)
    80005576:	6442                	ld	s0,16(sp)
    80005578:	6105                	addi	sp,sp,32
    8000557a:	8082                	ret

000000008000557c <sys_fstat>:
{
    8000557c:	1101                	addi	sp,sp,-32
    8000557e:	ec06                	sd	ra,24(sp)
    80005580:	e822                	sd	s0,16(sp)
    80005582:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005584:	fe040593          	addi	a1,s0,-32
    80005588:	4505                	li	a0,1
    8000558a:	ffffd097          	auipc	ra,0xffffd
    8000558e:	5ee080e7          	jalr	1518(ra) # 80002b78 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005592:	fe840613          	addi	a2,s0,-24
    80005596:	4581                	li	a1,0
    80005598:	4501                	li	a0,0
    8000559a:	00000097          	auipc	ra,0x0
    8000559e:	c68080e7          	jalr	-920(ra) # 80005202 <argfd>
    800055a2:	87aa                	mv	a5,a0
    return -1;
    800055a4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055a6:	0007ca63          	bltz	a5,800055ba <sys_fstat+0x3e>
  return filestat(f, st);
    800055aa:	fe043583          	ld	a1,-32(s0)
    800055ae:	fe843503          	ld	a0,-24(s0)
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	2f0080e7          	jalr	752(ra) # 800048a2 <filestat>
}
    800055ba:	60e2                	ld	ra,24(sp)
    800055bc:	6442                	ld	s0,16(sp)
    800055be:	6105                	addi	sp,sp,32
    800055c0:	8082                	ret

00000000800055c2 <sys_link>:
{
    800055c2:	7169                	addi	sp,sp,-304
    800055c4:	f606                	sd	ra,296(sp)
    800055c6:	f222                	sd	s0,288(sp)
    800055c8:	ee26                	sd	s1,280(sp)
    800055ca:	ea4a                	sd	s2,272(sp)
    800055cc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ce:	08000613          	li	a2,128
    800055d2:	ed040593          	addi	a1,s0,-304
    800055d6:	4501                	li	a0,0
    800055d8:	ffffd097          	auipc	ra,0xffffd
    800055dc:	5c0080e7          	jalr	1472(ra) # 80002b98 <argstr>
    return -1;
    800055e0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e2:	10054e63          	bltz	a0,800056fe <sys_link+0x13c>
    800055e6:	08000613          	li	a2,128
    800055ea:	f5040593          	addi	a1,s0,-176
    800055ee:	4505                	li	a0,1
    800055f0:	ffffd097          	auipc	ra,0xffffd
    800055f4:	5a8080e7          	jalr	1448(ra) # 80002b98 <argstr>
    return -1;
    800055f8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055fa:	10054263          	bltz	a0,800056fe <sys_link+0x13c>
  begin_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	d10080e7          	jalr	-752(ra) # 8000430e <begin_op>
  if((ip = namei(old)) == 0){
    80005606:	ed040513          	addi	a0,s0,-304
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	ae8080e7          	jalr	-1304(ra) # 800040f2 <namei>
    80005612:	84aa                	mv	s1,a0
    80005614:	c551                	beqz	a0,800056a0 <sys_link+0xde>
  ilock(ip);
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	336080e7          	jalr	822(ra) # 8000394c <ilock>
  if(ip->type == T_DIR){
    8000561e:	04449703          	lh	a4,68(s1)
    80005622:	4785                	li	a5,1
    80005624:	08f70463          	beq	a4,a5,800056ac <sys_link+0xea>
  ip->nlink++;
    80005628:	04a4d783          	lhu	a5,74(s1)
    8000562c:	2785                	addiw	a5,a5,1
    8000562e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	24e080e7          	jalr	590(ra) # 80003882 <iupdate>
  iunlock(ip);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	3d0080e7          	jalr	976(ra) # 80003a0e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005646:	fd040593          	addi	a1,s0,-48
    8000564a:	f5040513          	addi	a0,s0,-176
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	ac2080e7          	jalr	-1342(ra) # 80004110 <nameiparent>
    80005656:	892a                	mv	s2,a0
    80005658:	c935                	beqz	a0,800056cc <sys_link+0x10a>
  ilock(dp);
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	2f2080e7          	jalr	754(ra) # 8000394c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005662:	00092703          	lw	a4,0(s2)
    80005666:	409c                	lw	a5,0(s1)
    80005668:	04f71d63          	bne	a4,a5,800056c2 <sys_link+0x100>
    8000566c:	40d0                	lw	a2,4(s1)
    8000566e:	fd040593          	addi	a1,s0,-48
    80005672:	854a                	mv	a0,s2
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	9cc080e7          	jalr	-1588(ra) # 80004040 <dirlink>
    8000567c:	04054363          	bltz	a0,800056c2 <sys_link+0x100>
  iunlockput(dp);
    80005680:	854a                	mv	a0,s2
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	52c080e7          	jalr	1324(ra) # 80003bae <iunlockput>
  iput(ip);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	47a080e7          	jalr	1146(ra) # 80003b06 <iput>
  end_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	cfa080e7          	jalr	-774(ra) # 8000438e <end_op>
  return 0;
    8000569c:	4781                	li	a5,0
    8000569e:	a085                	j	800056fe <sys_link+0x13c>
    end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	cee080e7          	jalr	-786(ra) # 8000438e <end_op>
    return -1;
    800056a8:	57fd                	li	a5,-1
    800056aa:	a891                	j	800056fe <sys_link+0x13c>
    iunlockput(ip);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	500080e7          	jalr	1280(ra) # 80003bae <iunlockput>
    end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	cd8080e7          	jalr	-808(ra) # 8000438e <end_op>
    return -1;
    800056be:	57fd                	li	a5,-1
    800056c0:	a83d                	j	800056fe <sys_link+0x13c>
    iunlockput(dp);
    800056c2:	854a                	mv	a0,s2
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	4ea080e7          	jalr	1258(ra) # 80003bae <iunlockput>
  ilock(ip);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	27e080e7          	jalr	638(ra) # 8000394c <ilock>
  ip->nlink--;
    800056d6:	04a4d783          	lhu	a5,74(s1)
    800056da:	37fd                	addiw	a5,a5,-1
    800056dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	1a0080e7          	jalr	416(ra) # 80003882 <iupdate>
  iunlockput(ip);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	4c2080e7          	jalr	1218(ra) # 80003bae <iunlockput>
  end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	c9a080e7          	jalr	-870(ra) # 8000438e <end_op>
  return -1;
    800056fc:	57fd                	li	a5,-1
}
    800056fe:	853e                	mv	a0,a5
    80005700:	70b2                	ld	ra,296(sp)
    80005702:	7412                	ld	s0,288(sp)
    80005704:	64f2                	ld	s1,280(sp)
    80005706:	6952                	ld	s2,272(sp)
    80005708:	6155                	addi	sp,sp,304
    8000570a:	8082                	ret

000000008000570c <sys_unlink>:
{
    8000570c:	7151                	addi	sp,sp,-240
    8000570e:	f586                	sd	ra,232(sp)
    80005710:	f1a2                	sd	s0,224(sp)
    80005712:	eda6                	sd	s1,216(sp)
    80005714:	e9ca                	sd	s2,208(sp)
    80005716:	e5ce                	sd	s3,200(sp)
    80005718:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000571a:	08000613          	li	a2,128
    8000571e:	f3040593          	addi	a1,s0,-208
    80005722:	4501                	li	a0,0
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	474080e7          	jalr	1140(ra) # 80002b98 <argstr>
    8000572c:	18054163          	bltz	a0,800058ae <sys_unlink+0x1a2>
  begin_op();
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	bde080e7          	jalr	-1058(ra) # 8000430e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005738:	fb040593          	addi	a1,s0,-80
    8000573c:	f3040513          	addi	a0,s0,-208
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	9d0080e7          	jalr	-1584(ra) # 80004110 <nameiparent>
    80005748:	84aa                	mv	s1,a0
    8000574a:	c979                	beqz	a0,80005820 <sys_unlink+0x114>
  ilock(dp);
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	200080e7          	jalr	512(ra) # 8000394c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005754:	00003597          	auipc	a1,0x3
    80005758:	1dc58593          	addi	a1,a1,476 # 80008930 <sysargs+0x250>
    8000575c:	fb040513          	addi	a0,s0,-80
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	6b6080e7          	jalr	1718(ra) # 80003e16 <namecmp>
    80005768:	14050a63          	beqz	a0,800058bc <sys_unlink+0x1b0>
    8000576c:	00003597          	auipc	a1,0x3
    80005770:	1cc58593          	addi	a1,a1,460 # 80008938 <sysargs+0x258>
    80005774:	fb040513          	addi	a0,s0,-80
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	69e080e7          	jalr	1694(ra) # 80003e16 <namecmp>
    80005780:	12050e63          	beqz	a0,800058bc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005784:	f2c40613          	addi	a2,s0,-212
    80005788:	fb040593          	addi	a1,s0,-80
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	6a2080e7          	jalr	1698(ra) # 80003e30 <dirlookup>
    80005796:	892a                	mv	s2,a0
    80005798:	12050263          	beqz	a0,800058bc <sys_unlink+0x1b0>
  ilock(ip);
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	1b0080e7          	jalr	432(ra) # 8000394c <ilock>
  if(ip->nlink < 1)
    800057a4:	04a91783          	lh	a5,74(s2)
    800057a8:	08f05263          	blez	a5,8000582c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057ac:	04491703          	lh	a4,68(s2)
    800057b0:	4785                	li	a5,1
    800057b2:	08f70563          	beq	a4,a5,8000583c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057b6:	4641                	li	a2,16
    800057b8:	4581                	li	a1,0
    800057ba:	fc040513          	addi	a0,s0,-64
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	528080e7          	jalr	1320(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057c6:	4741                	li	a4,16
    800057c8:	f2c42683          	lw	a3,-212(s0)
    800057cc:	fc040613          	addi	a2,s0,-64
    800057d0:	4581                	li	a1,0
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	524080e7          	jalr	1316(ra) # 80003cf8 <writei>
    800057dc:	47c1                	li	a5,16
    800057de:	0af51563          	bne	a0,a5,80005888 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057e2:	04491703          	lh	a4,68(s2)
    800057e6:	4785                	li	a5,1
    800057e8:	0af70863          	beq	a4,a5,80005898 <sys_unlink+0x18c>
  iunlockput(dp);
    800057ec:	8526                	mv	a0,s1
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	3c0080e7          	jalr	960(ra) # 80003bae <iunlockput>
  ip->nlink--;
    800057f6:	04a95783          	lhu	a5,74(s2)
    800057fa:	37fd                	addiw	a5,a5,-1
    800057fc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005800:	854a                	mv	a0,s2
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	080080e7          	jalr	128(ra) # 80003882 <iupdate>
  iunlockput(ip);
    8000580a:	854a                	mv	a0,s2
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	3a2080e7          	jalr	930(ra) # 80003bae <iunlockput>
  end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	b7a080e7          	jalr	-1158(ra) # 8000438e <end_op>
  return 0;
    8000581c:	4501                	li	a0,0
    8000581e:	a84d                	j	800058d0 <sys_unlink+0x1c4>
    end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	b6e080e7          	jalr	-1170(ra) # 8000438e <end_op>
    return -1;
    80005828:	557d                	li	a0,-1
    8000582a:	a05d                	j	800058d0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000582c:	00003517          	auipc	a0,0x3
    80005830:	11450513          	addi	a0,a0,276 # 80008940 <sysargs+0x260>
    80005834:	ffffb097          	auipc	ra,0xffffb
    80005838:	d10080e7          	jalr	-752(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000583c:	04c92703          	lw	a4,76(s2)
    80005840:	02000793          	li	a5,32
    80005844:	f6e7f9e3          	bgeu	a5,a4,800057b6 <sys_unlink+0xaa>
    80005848:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000584c:	4741                	li	a4,16
    8000584e:	86ce                	mv	a3,s3
    80005850:	f1840613          	addi	a2,s0,-232
    80005854:	4581                	li	a1,0
    80005856:	854a                	mv	a0,s2
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	3a8080e7          	jalr	936(ra) # 80003c00 <readi>
    80005860:	47c1                	li	a5,16
    80005862:	00f51b63          	bne	a0,a5,80005878 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005866:	f1845783          	lhu	a5,-232(s0)
    8000586a:	e7a1                	bnez	a5,800058b2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000586c:	29c1                	addiw	s3,s3,16
    8000586e:	04c92783          	lw	a5,76(s2)
    80005872:	fcf9ede3          	bltu	s3,a5,8000584c <sys_unlink+0x140>
    80005876:	b781                	j	800057b6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005878:	00003517          	auipc	a0,0x3
    8000587c:	0e050513          	addi	a0,a0,224 # 80008958 <sysargs+0x278>
    80005880:	ffffb097          	auipc	ra,0xffffb
    80005884:	cc4080e7          	jalr	-828(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005888:	00003517          	auipc	a0,0x3
    8000588c:	0e850513          	addi	a0,a0,232 # 80008970 <sysargs+0x290>
    80005890:	ffffb097          	auipc	ra,0xffffb
    80005894:	cb4080e7          	jalr	-844(ra) # 80000544 <panic>
    dp->nlink--;
    80005898:	04a4d783          	lhu	a5,74(s1)
    8000589c:	37fd                	addiw	a5,a5,-1
    8000589e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	fde080e7          	jalr	-34(ra) # 80003882 <iupdate>
    800058ac:	b781                	j	800057ec <sys_unlink+0xe0>
    return -1;
    800058ae:	557d                	li	a0,-1
    800058b0:	a005                	j	800058d0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058b2:	854a                	mv	a0,s2
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	2fa080e7          	jalr	762(ra) # 80003bae <iunlockput>
  iunlockput(dp);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	2f0080e7          	jalr	752(ra) # 80003bae <iunlockput>
  end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	ac8080e7          	jalr	-1336(ra) # 8000438e <end_op>
  return -1;
    800058ce:	557d                	li	a0,-1
}
    800058d0:	70ae                	ld	ra,232(sp)
    800058d2:	740e                	ld	s0,224(sp)
    800058d4:	64ee                	ld	s1,216(sp)
    800058d6:	694e                	ld	s2,208(sp)
    800058d8:	69ae                	ld	s3,200(sp)
    800058da:	616d                	addi	sp,sp,240
    800058dc:	8082                	ret

00000000800058de <sys_open>:

uint64
sys_open(void)
{
    800058de:	7131                	addi	sp,sp,-192
    800058e0:	fd06                	sd	ra,184(sp)
    800058e2:	f922                	sd	s0,176(sp)
    800058e4:	f526                	sd	s1,168(sp)
    800058e6:	f14a                	sd	s2,160(sp)
    800058e8:	ed4e                	sd	s3,152(sp)
    800058ea:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058ec:	f4c40593          	addi	a1,s0,-180
    800058f0:	4505                	li	a0,1
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	266080e7          	jalr	614(ra) # 80002b58 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058fa:	08000613          	li	a2,128
    800058fe:	f5040593          	addi	a1,s0,-176
    80005902:	4501                	li	a0,0
    80005904:	ffffd097          	auipc	ra,0xffffd
    80005908:	294080e7          	jalr	660(ra) # 80002b98 <argstr>
    8000590c:	87aa                	mv	a5,a0
    return -1;
    8000590e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005910:	0a07c963          	bltz	a5,800059c2 <sys_open+0xe4>

  begin_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	9fa080e7          	jalr	-1542(ra) # 8000430e <begin_op>

  if(omode & O_CREATE){
    8000591c:	f4c42783          	lw	a5,-180(s0)
    80005920:	2007f793          	andi	a5,a5,512
    80005924:	cfc5                	beqz	a5,800059dc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005926:	4681                	li	a3,0
    80005928:	4601                	li	a2,0
    8000592a:	4589                	li	a1,2
    8000592c:	f5040513          	addi	a0,s0,-176
    80005930:	00000097          	auipc	ra,0x0
    80005934:	974080e7          	jalr	-1676(ra) # 800052a4 <create>
    80005938:	84aa                	mv	s1,a0
    if(ip == 0){
    8000593a:	c959                	beqz	a0,800059d0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000593c:	04449703          	lh	a4,68(s1)
    80005940:	478d                	li	a5,3
    80005942:	00f71763          	bne	a4,a5,80005950 <sys_open+0x72>
    80005946:	0464d703          	lhu	a4,70(s1)
    8000594a:	47a5                	li	a5,9
    8000594c:	0ce7ed63          	bltu	a5,a4,80005a26 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	dce080e7          	jalr	-562(ra) # 8000471e <filealloc>
    80005958:	89aa                	mv	s3,a0
    8000595a:	10050363          	beqz	a0,80005a60 <sys_open+0x182>
    8000595e:	00000097          	auipc	ra,0x0
    80005962:	904080e7          	jalr	-1788(ra) # 80005262 <fdalloc>
    80005966:	892a                	mv	s2,a0
    80005968:	0e054763          	bltz	a0,80005a56 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000596c:	04449703          	lh	a4,68(s1)
    80005970:	478d                	li	a5,3
    80005972:	0cf70563          	beq	a4,a5,80005a3c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005976:	4789                	li	a5,2
    80005978:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000597c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005980:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005984:	f4c42783          	lw	a5,-180(s0)
    80005988:	0017c713          	xori	a4,a5,1
    8000598c:	8b05                	andi	a4,a4,1
    8000598e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005992:	0037f713          	andi	a4,a5,3
    80005996:	00e03733          	snez	a4,a4
    8000599a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000599e:	4007f793          	andi	a5,a5,1024
    800059a2:	c791                	beqz	a5,800059ae <sys_open+0xd0>
    800059a4:	04449703          	lh	a4,68(s1)
    800059a8:	4789                	li	a5,2
    800059aa:	0af70063          	beq	a4,a5,80005a4a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059ae:	8526                	mv	a0,s1
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	05e080e7          	jalr	94(ra) # 80003a0e <iunlock>
  end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	9d6080e7          	jalr	-1578(ra) # 8000438e <end_op>

  return fd;
    800059c0:	854a                	mv	a0,s2
}
    800059c2:	70ea                	ld	ra,184(sp)
    800059c4:	744a                	ld	s0,176(sp)
    800059c6:	74aa                	ld	s1,168(sp)
    800059c8:	790a                	ld	s2,160(sp)
    800059ca:	69ea                	ld	s3,152(sp)
    800059cc:	6129                	addi	sp,sp,192
    800059ce:	8082                	ret
      end_op();
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	9be080e7          	jalr	-1602(ra) # 8000438e <end_op>
      return -1;
    800059d8:	557d                	li	a0,-1
    800059da:	b7e5                	j	800059c2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059dc:	f5040513          	addi	a0,s0,-176
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	712080e7          	jalr	1810(ra) # 800040f2 <namei>
    800059e8:	84aa                	mv	s1,a0
    800059ea:	c905                	beqz	a0,80005a1a <sys_open+0x13c>
    ilock(ip);
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	f60080e7          	jalr	-160(ra) # 8000394c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059f4:	04449703          	lh	a4,68(s1)
    800059f8:	4785                	li	a5,1
    800059fa:	f4f711e3          	bne	a4,a5,8000593c <sys_open+0x5e>
    800059fe:	f4c42783          	lw	a5,-180(s0)
    80005a02:	d7b9                	beqz	a5,80005950 <sys_open+0x72>
      iunlockput(ip);
    80005a04:	8526                	mv	a0,s1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	1a8080e7          	jalr	424(ra) # 80003bae <iunlockput>
      end_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	980080e7          	jalr	-1664(ra) # 8000438e <end_op>
      return -1;
    80005a16:	557d                	li	a0,-1
    80005a18:	b76d                	j	800059c2 <sys_open+0xe4>
      end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	974080e7          	jalr	-1676(ra) # 8000438e <end_op>
      return -1;
    80005a22:	557d                	li	a0,-1
    80005a24:	bf79                	j	800059c2 <sys_open+0xe4>
    iunlockput(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	186080e7          	jalr	390(ra) # 80003bae <iunlockput>
    end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	95e080e7          	jalr	-1698(ra) # 8000438e <end_op>
    return -1;
    80005a38:	557d                	li	a0,-1
    80005a3a:	b761                	j	800059c2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a3c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a40:	04649783          	lh	a5,70(s1)
    80005a44:	02f99223          	sh	a5,36(s3)
    80005a48:	bf25                	j	80005980 <sys_open+0xa2>
    itrunc(ip);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	00e080e7          	jalr	14(ra) # 80003a5a <itrunc>
    80005a54:	bfa9                	j	800059ae <sys_open+0xd0>
      fileclose(f);
    80005a56:	854e                	mv	a0,s3
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	d82080e7          	jalr	-638(ra) # 800047da <fileclose>
    iunlockput(ip);
    80005a60:	8526                	mv	a0,s1
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	14c080e7          	jalr	332(ra) # 80003bae <iunlockput>
    end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	924080e7          	jalr	-1756(ra) # 8000438e <end_op>
    return -1;
    80005a72:	557d                	li	a0,-1
    80005a74:	b7b9                	j	800059c2 <sys_open+0xe4>

0000000080005a76 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a76:	7175                	addi	sp,sp,-144
    80005a78:	e506                	sd	ra,136(sp)
    80005a7a:	e122                	sd	s0,128(sp)
    80005a7c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	890080e7          	jalr	-1904(ra) # 8000430e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a86:	08000613          	li	a2,128
    80005a8a:	f7040593          	addi	a1,s0,-144
    80005a8e:	4501                	li	a0,0
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	108080e7          	jalr	264(ra) # 80002b98 <argstr>
    80005a98:	02054963          	bltz	a0,80005aca <sys_mkdir+0x54>
    80005a9c:	4681                	li	a3,0
    80005a9e:	4601                	li	a2,0
    80005aa0:	4585                	li	a1,1
    80005aa2:	f7040513          	addi	a0,s0,-144
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	7fe080e7          	jalr	2046(ra) # 800052a4 <create>
    80005aae:	cd11                	beqz	a0,80005aca <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	0fe080e7          	jalr	254(ra) # 80003bae <iunlockput>
  end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	8d6080e7          	jalr	-1834(ra) # 8000438e <end_op>
  return 0;
    80005ac0:	4501                	li	a0,0
}
    80005ac2:	60aa                	ld	ra,136(sp)
    80005ac4:	640a                	ld	s0,128(sp)
    80005ac6:	6149                	addi	sp,sp,144
    80005ac8:	8082                	ret
    end_op();
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	8c4080e7          	jalr	-1852(ra) # 8000438e <end_op>
    return -1;
    80005ad2:	557d                	li	a0,-1
    80005ad4:	b7fd                	j	80005ac2 <sys_mkdir+0x4c>

0000000080005ad6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ad6:	7135                	addi	sp,sp,-160
    80005ad8:	ed06                	sd	ra,152(sp)
    80005ada:	e922                	sd	s0,144(sp)
    80005adc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	830080e7          	jalr	-2000(ra) # 8000430e <begin_op>
  argint(1, &major);
    80005ae6:	f6c40593          	addi	a1,s0,-148
    80005aea:	4505                	li	a0,1
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	06c080e7          	jalr	108(ra) # 80002b58 <argint>
  argint(2, &minor);
    80005af4:	f6840593          	addi	a1,s0,-152
    80005af8:	4509                	li	a0,2
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	05e080e7          	jalr	94(ra) # 80002b58 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b02:	08000613          	li	a2,128
    80005b06:	f7040593          	addi	a1,s0,-144
    80005b0a:	4501                	li	a0,0
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	08c080e7          	jalr	140(ra) # 80002b98 <argstr>
    80005b14:	02054b63          	bltz	a0,80005b4a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b18:	f6841683          	lh	a3,-152(s0)
    80005b1c:	f6c41603          	lh	a2,-148(s0)
    80005b20:	458d                	li	a1,3
    80005b22:	f7040513          	addi	a0,s0,-144
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	77e080e7          	jalr	1918(ra) # 800052a4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b2e:	cd11                	beqz	a0,80005b4a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	07e080e7          	jalr	126(ra) # 80003bae <iunlockput>
  end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	856080e7          	jalr	-1962(ra) # 8000438e <end_op>
  return 0;
    80005b40:	4501                	li	a0,0
}
    80005b42:	60ea                	ld	ra,152(sp)
    80005b44:	644a                	ld	s0,144(sp)
    80005b46:	610d                	addi	sp,sp,160
    80005b48:	8082                	ret
    end_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	844080e7          	jalr	-1980(ra) # 8000438e <end_op>
    return -1;
    80005b52:	557d                	li	a0,-1
    80005b54:	b7fd                	j	80005b42 <sys_mknod+0x6c>

0000000080005b56 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b56:	7135                	addi	sp,sp,-160
    80005b58:	ed06                	sd	ra,152(sp)
    80005b5a:	e922                	sd	s0,144(sp)
    80005b5c:	e526                	sd	s1,136(sp)
    80005b5e:	e14a                	sd	s2,128(sp)
    80005b60:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	e64080e7          	jalr	-412(ra) # 800019c6 <myproc>
    80005b6a:	892a                	mv	s2,a0
  
  begin_op();
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	7a2080e7          	jalr	1954(ra) # 8000430e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b74:	08000613          	li	a2,128
    80005b78:	f6040593          	addi	a1,s0,-160
    80005b7c:	4501                	li	a0,0
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	01a080e7          	jalr	26(ra) # 80002b98 <argstr>
    80005b86:	04054b63          	bltz	a0,80005bdc <sys_chdir+0x86>
    80005b8a:	f6040513          	addi	a0,s0,-160
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	564080e7          	jalr	1380(ra) # 800040f2 <namei>
    80005b96:	84aa                	mv	s1,a0
    80005b98:	c131                	beqz	a0,80005bdc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	db2080e7          	jalr	-590(ra) # 8000394c <ilock>
  if(ip->type != T_DIR){
    80005ba2:	04449703          	lh	a4,68(s1)
    80005ba6:	4785                	li	a5,1
    80005ba8:	04f71063          	bne	a4,a5,80005be8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	e60080e7          	jalr	-416(ra) # 80003a0e <iunlock>
  iput(p->cwd);
    80005bb6:	15093503          	ld	a0,336(s2)
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	f4c080e7          	jalr	-180(ra) # 80003b06 <iput>
  end_op();
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	7cc080e7          	jalr	1996(ra) # 8000438e <end_op>
  p->cwd = ip;
    80005bca:	14993823          	sd	s1,336(s2)
  return 0;
    80005bce:	4501                	li	a0,0
}
    80005bd0:	60ea                	ld	ra,152(sp)
    80005bd2:	644a                	ld	s0,144(sp)
    80005bd4:	64aa                	ld	s1,136(sp)
    80005bd6:	690a                	ld	s2,128(sp)
    80005bd8:	610d                	addi	sp,sp,160
    80005bda:	8082                	ret
    end_op();
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	7b2080e7          	jalr	1970(ra) # 8000438e <end_op>
    return -1;
    80005be4:	557d                	li	a0,-1
    80005be6:	b7ed                	j	80005bd0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005be8:	8526                	mv	a0,s1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	fc4080e7          	jalr	-60(ra) # 80003bae <iunlockput>
    end_op();
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	79c080e7          	jalr	1948(ra) # 8000438e <end_op>
    return -1;
    80005bfa:	557d                	li	a0,-1
    80005bfc:	bfd1                	j	80005bd0 <sys_chdir+0x7a>

0000000080005bfe <sys_exec>:

uint64
sys_exec(void)
{
    80005bfe:	7145                	addi	sp,sp,-464
    80005c00:	e786                	sd	ra,456(sp)
    80005c02:	e3a2                	sd	s0,448(sp)
    80005c04:	ff26                	sd	s1,440(sp)
    80005c06:	fb4a                	sd	s2,432(sp)
    80005c08:	f74e                	sd	s3,424(sp)
    80005c0a:	f352                	sd	s4,416(sp)
    80005c0c:	ef56                	sd	s5,408(sp)
    80005c0e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c10:	e3840593          	addi	a1,s0,-456
    80005c14:	4505                	li	a0,1
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	f62080e7          	jalr	-158(ra) # 80002b78 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c1e:	08000613          	li	a2,128
    80005c22:	f4040593          	addi	a1,s0,-192
    80005c26:	4501                	li	a0,0
    80005c28:	ffffd097          	auipc	ra,0xffffd
    80005c2c:	f70080e7          	jalr	-144(ra) # 80002b98 <argstr>
    80005c30:	87aa                	mv	a5,a0
    return -1;
    80005c32:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c34:	0c07c263          	bltz	a5,80005cf8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c38:	10000613          	li	a2,256
    80005c3c:	4581                	li	a1,0
    80005c3e:	e4040513          	addi	a0,s0,-448
    80005c42:	ffffb097          	auipc	ra,0xffffb
    80005c46:	0a4080e7          	jalr	164(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c4a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c4e:	89a6                	mv	s3,s1
    80005c50:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c52:	02000a13          	li	s4,32
    80005c56:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c5a:	00391513          	slli	a0,s2,0x3
    80005c5e:	e3040593          	addi	a1,s0,-464
    80005c62:	e3843783          	ld	a5,-456(s0)
    80005c66:	953e                	add	a0,a0,a5
    80005c68:	ffffd097          	auipc	ra,0xffffd
    80005c6c:	e52080e7          	jalr	-430(ra) # 80002aba <fetchaddr>
    80005c70:	02054a63          	bltz	a0,80005ca4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c74:	e3043783          	ld	a5,-464(s0)
    80005c78:	c3b9                	beqz	a5,80005cbe <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	e80080e7          	jalr	-384(ra) # 80000afa <kalloc>
    80005c82:	85aa                	mv	a1,a0
    80005c84:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c88:	cd11                	beqz	a0,80005ca4 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c8a:	6605                	lui	a2,0x1
    80005c8c:	e3043503          	ld	a0,-464(s0)
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	e7c080e7          	jalr	-388(ra) # 80002b0c <fetchstr>
    80005c98:	00054663          	bltz	a0,80005ca4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c9c:	0905                	addi	s2,s2,1
    80005c9e:	09a1                	addi	s3,s3,8
    80005ca0:	fb491be3          	bne	s2,s4,80005c56 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca4:	10048913          	addi	s2,s1,256
    80005ca8:	6088                	ld	a0,0(s1)
    80005caa:	c531                	beqz	a0,80005cf6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cac:	ffffb097          	auipc	ra,0xffffb
    80005cb0:	d52080e7          	jalr	-686(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb4:	04a1                	addi	s1,s1,8
    80005cb6:	ff2499e3          	bne	s1,s2,80005ca8 <sys_exec+0xaa>
  return -1;
    80005cba:	557d                	li	a0,-1
    80005cbc:	a835                	j	80005cf8 <sys_exec+0xfa>
      argv[i] = 0;
    80005cbe:	0a8e                	slli	s5,s5,0x3
    80005cc0:	fc040793          	addi	a5,s0,-64
    80005cc4:	9abe                	add	s5,s5,a5
    80005cc6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cca:	e4040593          	addi	a1,s0,-448
    80005cce:	f4040513          	addi	a0,s0,-192
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	190080e7          	jalr	400(ra) # 80004e62 <exec>
    80005cda:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cdc:	10048993          	addi	s3,s1,256
    80005ce0:	6088                	ld	a0,0(s1)
    80005ce2:	c901                	beqz	a0,80005cf2 <sys_exec+0xf4>
    kfree(argv[i]);
    80005ce4:	ffffb097          	auipc	ra,0xffffb
    80005ce8:	d1a080e7          	jalr	-742(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cec:	04a1                	addi	s1,s1,8
    80005cee:	ff3499e3          	bne	s1,s3,80005ce0 <sys_exec+0xe2>
  return ret;
    80005cf2:	854a                	mv	a0,s2
    80005cf4:	a011                	j	80005cf8 <sys_exec+0xfa>
  return -1;
    80005cf6:	557d                	li	a0,-1
}
    80005cf8:	60be                	ld	ra,456(sp)
    80005cfa:	641e                	ld	s0,448(sp)
    80005cfc:	74fa                	ld	s1,440(sp)
    80005cfe:	795a                	ld	s2,432(sp)
    80005d00:	79ba                	ld	s3,424(sp)
    80005d02:	7a1a                	ld	s4,416(sp)
    80005d04:	6afa                	ld	s5,408(sp)
    80005d06:	6179                	addi	sp,sp,464
    80005d08:	8082                	ret

0000000080005d0a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d0a:	7139                	addi	sp,sp,-64
    80005d0c:	fc06                	sd	ra,56(sp)
    80005d0e:	f822                	sd	s0,48(sp)
    80005d10:	f426                	sd	s1,40(sp)
    80005d12:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d14:	ffffc097          	auipc	ra,0xffffc
    80005d18:	cb2080e7          	jalr	-846(ra) # 800019c6 <myproc>
    80005d1c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d1e:	fd840593          	addi	a1,s0,-40
    80005d22:	4501                	li	a0,0
    80005d24:	ffffd097          	auipc	ra,0xffffd
    80005d28:	e54080e7          	jalr	-428(ra) # 80002b78 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d2c:	fc840593          	addi	a1,s0,-56
    80005d30:	fd040513          	addi	a0,s0,-48
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	dd6080e7          	jalr	-554(ra) # 80004b0a <pipealloc>
    return -1;
    80005d3c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d3e:	0c054463          	bltz	a0,80005e06 <sys_pipe+0xfc>
  fd0 = -1;
    80005d42:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d46:	fd043503          	ld	a0,-48(s0)
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	518080e7          	jalr	1304(ra) # 80005262 <fdalloc>
    80005d52:	fca42223          	sw	a0,-60(s0)
    80005d56:	08054b63          	bltz	a0,80005dec <sys_pipe+0xe2>
    80005d5a:	fc843503          	ld	a0,-56(s0)
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	504080e7          	jalr	1284(ra) # 80005262 <fdalloc>
    80005d66:	fca42023          	sw	a0,-64(s0)
    80005d6a:	06054863          	bltz	a0,80005dda <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d6e:	4691                	li	a3,4
    80005d70:	fc440613          	addi	a2,s0,-60
    80005d74:	fd843583          	ld	a1,-40(s0)
    80005d78:	68a8                	ld	a0,80(s1)
    80005d7a:	ffffc097          	auipc	ra,0xffffc
    80005d7e:	90a080e7          	jalr	-1782(ra) # 80001684 <copyout>
    80005d82:	02054063          	bltz	a0,80005da2 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d86:	4691                	li	a3,4
    80005d88:	fc040613          	addi	a2,s0,-64
    80005d8c:	fd843583          	ld	a1,-40(s0)
    80005d90:	0591                	addi	a1,a1,4
    80005d92:	68a8                	ld	a0,80(s1)
    80005d94:	ffffc097          	auipc	ra,0xffffc
    80005d98:	8f0080e7          	jalr	-1808(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d9c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d9e:	06055463          	bgez	a0,80005e06 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005da2:	fc442783          	lw	a5,-60(s0)
    80005da6:	07e9                	addi	a5,a5,26
    80005da8:	078e                	slli	a5,a5,0x3
    80005daa:	97a6                	add	a5,a5,s1
    80005dac:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005db0:	fc042503          	lw	a0,-64(s0)
    80005db4:	0569                	addi	a0,a0,26
    80005db6:	050e                	slli	a0,a0,0x3
    80005db8:	94aa                	add	s1,s1,a0
    80005dba:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dbe:	fd043503          	ld	a0,-48(s0)
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	a18080e7          	jalr	-1512(ra) # 800047da <fileclose>
    fileclose(wf);
    80005dca:	fc843503          	ld	a0,-56(s0)
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	a0c080e7          	jalr	-1524(ra) # 800047da <fileclose>
    return -1;
    80005dd6:	57fd                	li	a5,-1
    80005dd8:	a03d                	j	80005e06 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005dda:	fc442783          	lw	a5,-60(s0)
    80005dde:	0007c763          	bltz	a5,80005dec <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005de2:	07e9                	addi	a5,a5,26
    80005de4:	078e                	slli	a5,a5,0x3
    80005de6:	94be                	add	s1,s1,a5
    80005de8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dec:	fd043503          	ld	a0,-48(s0)
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	9ea080e7          	jalr	-1558(ra) # 800047da <fileclose>
    fileclose(wf);
    80005df8:	fc843503          	ld	a0,-56(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	9de080e7          	jalr	-1570(ra) # 800047da <fileclose>
    return -1;
    80005e04:	57fd                	li	a5,-1
}
    80005e06:	853e                	mv	a0,a5
    80005e08:	70e2                	ld	ra,56(sp)
    80005e0a:	7442                	ld	s0,48(sp)
    80005e0c:	74a2                	ld	s1,40(sp)
    80005e0e:	6121                	addi	sp,sp,64
    80005e10:	8082                	ret
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	b27fc0ef          	jal	ra,80002986 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	6d0c                	ld	a1,24(a0)
    80005ebc:	7110                	ld	a2,32(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	aa2080e7          	jalr	-1374(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	a6a080e7          	jalr	-1430(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	a42080e7          	jalr	-1470(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f84:	0001c797          	auipc	a5,0x1c
    80005f88:	6bc78793          	addi	a5,a5,1724 # 80022640 <disk>
    80005f8c:	97aa                	add	a5,a5,a0
    80005f8e:	0187c783          	lbu	a5,24(a5)
    80005f92:	ebb9                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f94:	00451613          	slli	a2,a0,0x4
    80005f98:	0001c797          	auipc	a5,0x1c
    80005f9c:	6a878793          	addi	a5,a5,1704 # 80022640 <disk>
    80005fa0:	6394                	ld	a3,0(a5)
    80005fa2:	96b2                	add	a3,a3,a2
    80005fa4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fa8:	6398                	ld	a4,0(a5)
    80005faa:	9732                	add	a4,a4,a2
    80005fac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fb0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fb4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fb8:	953e                	add	a0,a0,a5
    80005fba:	4785                	li	a5,1
    80005fbc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005fc0:	0001c517          	auipc	a0,0x1c
    80005fc4:	69850513          	addi	a0,a0,1688 # 80022658 <disk+0x18>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	126080e7          	jalr	294(ra) # 800020ee <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("free_desc 1");
    80005fd8:	00003517          	auipc	a0,0x3
    80005fdc:	9a850513          	addi	a0,a0,-1624 # 80008980 <sysargs+0x2a0>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005fe8:	00003517          	auipc	a0,0x3
    80005fec:	9a850513          	addi	a0,a0,-1624 # 80008990 <sysargs+0x2b0>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	554080e7          	jalr	1364(ra) # 80000544 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	e04a                	sd	s2,0(sp)
    80006002:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006004:	00003597          	auipc	a1,0x3
    80006008:	99c58593          	addi	a1,a1,-1636 # 800089a0 <sysargs+0x2c0>
    8000600c:	0001c517          	auipc	a0,0x1c
    80006010:	75c50513          	addi	a0,a0,1884 # 80022768 <disk+0x128>
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	b46080e7          	jalr	-1210(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601c:	100017b7          	lui	a5,0x10001
    80006020:	4398                	lw	a4,0(a5)
    80006022:	2701                	sext.w	a4,a4
    80006024:	747277b7          	lui	a5,0x74727
    80006028:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602c:	14f71e63          	bne	a4,a5,80006188 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006030:	100017b7          	lui	a5,0x10001
    80006034:	43dc                	lw	a5,4(a5)
    80006036:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006038:	4709                	li	a4,2
    8000603a:	14e79763          	bne	a5,a4,80006188 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603e:	100017b7          	lui	a5,0x10001
    80006042:	479c                	lw	a5,8(a5)
    80006044:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006046:	14e79163          	bne	a5,a4,80006188 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	12f71763          	bne	a4,a5,80006188 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	4705                	li	a4,1
    80006068:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000606a:	470d                	li	a4,3
    8000606c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006070:	c7ffe737          	lui	a4,0xc7ffe
    80006074:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbfdf>
    80006078:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000607a:	2701                	sext.w	a4,a4
    8000607c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	472d                	li	a4,11
    80006080:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006082:	0707a903          	lw	s2,112(a5)
    80006086:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006088:	00897793          	andi	a5,s2,8
    8000608c:	10078663          	beqz	a5,80006198 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006090:	100017b7          	lui	a5,0x10001
    80006094:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006098:	43fc                	lw	a5,68(a5)
    8000609a:	2781                	sext.w	a5,a5
    8000609c:	10079663          	bnez	a5,800061a8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060a0:	100017b7          	lui	a5,0x10001
    800060a4:	5bdc                	lw	a5,52(a5)
    800060a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060a8:	10078863          	beqz	a5,800061b8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800060ac:	471d                	li	a4,7
    800060ae:	10f77d63          	bgeu	a4,a5,800061c8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800060b2:	ffffb097          	auipc	ra,0xffffb
    800060b6:	a48080e7          	jalr	-1464(ra) # 80000afa <kalloc>
    800060ba:	0001c497          	auipc	s1,0x1c
    800060be:	58648493          	addi	s1,s1,1414 # 80022640 <disk>
    800060c2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	a36080e7          	jalr	-1482(ra) # 80000afa <kalloc>
    800060cc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ce:	ffffb097          	auipc	ra,0xffffb
    800060d2:	a2c080e7          	jalr	-1492(ra) # 80000afa <kalloc>
    800060d6:	87aa                	mv	a5,a0
    800060d8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060da:	6088                	ld	a0,0(s1)
    800060dc:	cd75                	beqz	a0,800061d8 <virtio_disk_init+0x1e0>
    800060de:	0001c717          	auipc	a4,0x1c
    800060e2:	56a73703          	ld	a4,1386(a4) # 80022648 <disk+0x8>
    800060e6:	cb6d                	beqz	a4,800061d8 <virtio_disk_init+0x1e0>
    800060e8:	cbe5                	beqz	a5,800061d8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800060ea:	6605                	lui	a2,0x1
    800060ec:	4581                	li	a1,0
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	bf8080e7          	jalr	-1032(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060f6:	0001c497          	auipc	s1,0x1c
    800060fa:	54a48493          	addi	s1,s1,1354 # 80022640 <disk>
    800060fe:	6605                	lui	a2,0x1
    80006100:	4581                	li	a1,0
    80006102:	6488                	ld	a0,8(s1)
    80006104:	ffffb097          	auipc	ra,0xffffb
    80006108:	be2080e7          	jalr	-1054(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000610c:	6605                	lui	a2,0x1
    8000610e:	4581                	li	a1,0
    80006110:	6888                	ld	a0,16(s1)
    80006112:	ffffb097          	auipc	ra,0xffffb
    80006116:	bd4080e7          	jalr	-1068(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000611a:	100017b7          	lui	a5,0x10001
    8000611e:	4721                	li	a4,8
    80006120:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006122:	4098                	lw	a4,0(s1)
    80006124:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006128:	40d8                	lw	a4,4(s1)
    8000612a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000612e:	6498                	ld	a4,8(s1)
    80006130:	0007069b          	sext.w	a3,a4
    80006134:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006138:	9701                	srai	a4,a4,0x20
    8000613a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000613e:	6898                	ld	a4,16(s1)
    80006140:	0007069b          	sext.w	a3,a4
    80006144:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006148:	9701                	srai	a4,a4,0x20
    8000614a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000614e:	4685                	li	a3,1
    80006150:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006152:	4705                	li	a4,1
    80006154:	00d48c23          	sb	a3,24(s1)
    80006158:	00e48ca3          	sb	a4,25(s1)
    8000615c:	00e48d23          	sb	a4,26(s1)
    80006160:	00e48da3          	sb	a4,27(s1)
    80006164:	00e48e23          	sb	a4,28(s1)
    80006168:	00e48ea3          	sb	a4,29(s1)
    8000616c:	00e48f23          	sb	a4,30(s1)
    80006170:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006174:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006178:	0727a823          	sw	s2,112(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6902                	ld	s2,0(sp)
    80006184:	6105                	addi	sp,sp,32
    80006186:	8082                	ret
    panic("could not find virtio disk");
    80006188:	00003517          	auipc	a0,0x3
    8000618c:	82850513          	addi	a0,a0,-2008 # 800089b0 <sysargs+0x2d0>
    80006190:	ffffa097          	auipc	ra,0xffffa
    80006194:	3b4080e7          	jalr	948(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006198:	00003517          	auipc	a0,0x3
    8000619c:	83850513          	addi	a0,a0,-1992 # 800089d0 <sysargs+0x2f0>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	3a4080e7          	jalr	932(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800061a8:	00003517          	auipc	a0,0x3
    800061ac:	84850513          	addi	a0,a0,-1976 # 800089f0 <sysargs+0x310>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	394080e7          	jalr	916(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800061b8:	00003517          	auipc	a0,0x3
    800061bc:	85850513          	addi	a0,a0,-1960 # 80008a10 <sysargs+0x330>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	384080e7          	jalr	900(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800061c8:	00003517          	auipc	a0,0x3
    800061cc:	86850513          	addi	a0,a0,-1944 # 80008a30 <sysargs+0x350>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	374080e7          	jalr	884(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800061d8:	00003517          	auipc	a0,0x3
    800061dc:	87850513          	addi	a0,a0,-1928 # 80008a50 <sysargs+0x370>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	364080e7          	jalr	868(ra) # 80000544 <panic>

00000000800061e8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061e8:	7159                	addi	sp,sp,-112
    800061ea:	f486                	sd	ra,104(sp)
    800061ec:	f0a2                	sd	s0,96(sp)
    800061ee:	eca6                	sd	s1,88(sp)
    800061f0:	e8ca                	sd	s2,80(sp)
    800061f2:	e4ce                	sd	s3,72(sp)
    800061f4:	e0d2                	sd	s4,64(sp)
    800061f6:	fc56                	sd	s5,56(sp)
    800061f8:	f85a                	sd	s6,48(sp)
    800061fa:	f45e                	sd	s7,40(sp)
    800061fc:	f062                	sd	s8,32(sp)
    800061fe:	ec66                	sd	s9,24(sp)
    80006200:	e86a                	sd	s10,16(sp)
    80006202:	1880                	addi	s0,sp,112
    80006204:	892a                	mv	s2,a0
    80006206:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006208:	00c52c83          	lw	s9,12(a0)
    8000620c:	001c9c9b          	slliw	s9,s9,0x1
    80006210:	1c82                	slli	s9,s9,0x20
    80006212:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006216:	0001c517          	auipc	a0,0x1c
    8000621a:	55250513          	addi	a0,a0,1362 # 80022768 <disk+0x128>
    8000621e:	ffffb097          	auipc	ra,0xffffb
    80006222:	9cc080e7          	jalr	-1588(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006226:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006228:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000622a:	0001cb17          	auipc	s6,0x1c
    8000622e:	416b0b13          	addi	s6,s6,1046 # 80022640 <disk>
  for(int i = 0; i < 3; i++){
    80006232:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006234:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006236:	0001cc17          	auipc	s8,0x1c
    8000623a:	532c0c13          	addi	s8,s8,1330 # 80022768 <disk+0x128>
    8000623e:	a8b5                	j	800062ba <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006240:	00fb06b3          	add	a3,s6,a5
    80006244:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006248:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000624a:	0207c563          	bltz	a5,80006274 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000624e:	2485                	addiw	s1,s1,1
    80006250:	0711                	addi	a4,a4,4
    80006252:	1f548a63          	beq	s1,s5,80006446 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006256:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006258:	0001c697          	auipc	a3,0x1c
    8000625c:	3e868693          	addi	a3,a3,1000 # 80022640 <disk>
    80006260:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006262:	0186c583          	lbu	a1,24(a3)
    80006266:	fde9                	bnez	a1,80006240 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006268:	2785                	addiw	a5,a5,1
    8000626a:	0685                	addi	a3,a3,1
    8000626c:	ff779be3          	bne	a5,s7,80006262 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006270:	57fd                	li	a5,-1
    80006272:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006274:	02905a63          	blez	s1,800062a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006278:	f9042503          	lw	a0,-112(s0)
    8000627c:	00000097          	auipc	ra,0x0
    80006280:	cfa080e7          	jalr	-774(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006284:	4785                	li	a5,1
    80006286:	0297d163          	bge	a5,s1,800062a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000628a:	f9442503          	lw	a0,-108(s0)
    8000628e:	00000097          	auipc	ra,0x0
    80006292:	ce8080e7          	jalr	-792(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006296:	4789                	li	a5,2
    80006298:	0097d863          	bge	a5,s1,800062a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000629c:	f9842503          	lw	a0,-104(s0)
    800062a0:	00000097          	auipc	ra,0x0
    800062a4:	cd6080e7          	jalr	-810(ra) # 80005f76 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a8:	85e2                	mv	a1,s8
    800062aa:	0001c517          	auipc	a0,0x1c
    800062ae:	3ae50513          	addi	a0,a0,942 # 80022658 <disk+0x18>
    800062b2:	ffffc097          	auipc	ra,0xffffc
    800062b6:	dd8080e7          	jalr	-552(ra) # 8000208a <sleep>
  for(int i = 0; i < 3; i++){
    800062ba:	f9040713          	addi	a4,s0,-112
    800062be:	84ce                	mv	s1,s3
    800062c0:	bf59                	j	80006256 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800062c2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800062c6:	00479693          	slli	a3,a5,0x4
    800062ca:	0001c797          	auipc	a5,0x1c
    800062ce:	37678793          	addi	a5,a5,886 # 80022640 <disk>
    800062d2:	97b6                	add	a5,a5,a3
    800062d4:	4685                	li	a3,1
    800062d6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062d8:	0001c597          	auipc	a1,0x1c
    800062dc:	36858593          	addi	a1,a1,872 # 80022640 <disk>
    800062e0:	00a60793          	addi	a5,a2,10
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	97ae                	add	a5,a5,a1
    800062e8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800062ec:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062f0:	f6070693          	addi	a3,a4,-160
    800062f4:	619c                	ld	a5,0(a1)
    800062f6:	97b6                	add	a5,a5,a3
    800062f8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062fa:	6188                	ld	a0,0(a1)
    800062fc:	96aa                	add	a3,a3,a0
    800062fe:	47c1                	li	a5,16
    80006300:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006302:	4785                	li	a5,1
    80006304:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006308:	f9442783          	lw	a5,-108(s0)
    8000630c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006310:	0792                	slli	a5,a5,0x4
    80006312:	953e                	add	a0,a0,a5
    80006314:	05890693          	addi	a3,s2,88
    80006318:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000631a:	6188                	ld	a0,0(a1)
    8000631c:	97aa                	add	a5,a5,a0
    8000631e:	40000693          	li	a3,1024
    80006322:	c794                	sw	a3,8(a5)
  if(write)
    80006324:	100d0d63          	beqz	s10,8000643e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006328:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000632c:	00c7d683          	lhu	a3,12(a5)
    80006330:	0016e693          	ori	a3,a3,1
    80006334:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006338:	f9842583          	lw	a1,-104(s0)
    8000633c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006340:	0001c697          	auipc	a3,0x1c
    80006344:	30068693          	addi	a3,a3,768 # 80022640 <disk>
    80006348:	00260793          	addi	a5,a2,2
    8000634c:	0792                	slli	a5,a5,0x4
    8000634e:	97b6                	add	a5,a5,a3
    80006350:	587d                	li	a6,-1
    80006352:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006356:	0592                	slli	a1,a1,0x4
    80006358:	952e                	add	a0,a0,a1
    8000635a:	f9070713          	addi	a4,a4,-112
    8000635e:	9736                	add	a4,a4,a3
    80006360:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006362:	6298                	ld	a4,0(a3)
    80006364:	972e                	add	a4,a4,a1
    80006366:	4585                	li	a1,1
    80006368:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000636a:	4509                	li	a0,2
    8000636c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006370:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006374:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006378:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000637c:	6698                	ld	a4,8(a3)
    8000637e:	00275783          	lhu	a5,2(a4)
    80006382:	8b9d                	andi	a5,a5,7
    80006384:	0786                	slli	a5,a5,0x1
    80006386:	97ba                	add	a5,a5,a4
    80006388:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000638c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006390:	6698                	ld	a4,8(a3)
    80006392:	00275783          	lhu	a5,2(a4)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000639c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063a0:	100017b7          	lui	a5,0x10001
    800063a4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a8:	00492703          	lw	a4,4(s2)
    800063ac:	4785                	li	a5,1
    800063ae:	02f71163          	bne	a4,a5,800063d0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800063b2:	0001c997          	auipc	s3,0x1c
    800063b6:	3b698993          	addi	s3,s3,950 # 80022768 <disk+0x128>
  while(b->disk == 1) {
    800063ba:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063bc:	85ce                	mv	a1,s3
    800063be:	854a                	mv	a0,s2
    800063c0:	ffffc097          	auipc	ra,0xffffc
    800063c4:	cca080e7          	jalr	-822(ra) # 8000208a <sleep>
  while(b->disk == 1) {
    800063c8:	00492783          	lw	a5,4(s2)
    800063cc:	fe9788e3          	beq	a5,s1,800063bc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800063d0:	f9042903          	lw	s2,-112(s0)
    800063d4:	00290793          	addi	a5,s2,2
    800063d8:	00479713          	slli	a4,a5,0x4
    800063dc:	0001c797          	auipc	a5,0x1c
    800063e0:	26478793          	addi	a5,a5,612 # 80022640 <disk>
    800063e4:	97ba                	add	a5,a5,a4
    800063e6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063ea:	0001c997          	auipc	s3,0x1c
    800063ee:	25698993          	addi	s3,s3,598 # 80022640 <disk>
    800063f2:	00491713          	slli	a4,s2,0x4
    800063f6:	0009b783          	ld	a5,0(s3)
    800063fa:	97ba                	add	a5,a5,a4
    800063fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006400:	854a                	mv	a0,s2
    80006402:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006406:	00000097          	auipc	ra,0x0
    8000640a:	b70080e7          	jalr	-1168(ra) # 80005f76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000640e:	8885                	andi	s1,s1,1
    80006410:	f0ed                	bnez	s1,800063f2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006412:	0001c517          	auipc	a0,0x1c
    80006416:	35650513          	addi	a0,a0,854 # 80022768 <disk+0x128>
    8000641a:	ffffb097          	auipc	ra,0xffffb
    8000641e:	884080e7          	jalr	-1916(ra) # 80000c9e <release>
}
    80006422:	70a6                	ld	ra,104(sp)
    80006424:	7406                	ld	s0,96(sp)
    80006426:	64e6                	ld	s1,88(sp)
    80006428:	6946                	ld	s2,80(sp)
    8000642a:	69a6                	ld	s3,72(sp)
    8000642c:	6a06                	ld	s4,64(sp)
    8000642e:	7ae2                	ld	s5,56(sp)
    80006430:	7b42                	ld	s6,48(sp)
    80006432:	7ba2                	ld	s7,40(sp)
    80006434:	7c02                	ld	s8,32(sp)
    80006436:	6ce2                	ld	s9,24(sp)
    80006438:	6d42                	ld	s10,16(sp)
    8000643a:	6165                	addi	sp,sp,112
    8000643c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000643e:	4689                	li	a3,2
    80006440:	00d79623          	sh	a3,12(a5)
    80006444:	b5e5                	j	8000632c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006446:	f9042603          	lw	a2,-112(s0)
    8000644a:	00a60713          	addi	a4,a2,10
    8000644e:	0712                	slli	a4,a4,0x4
    80006450:	0001c517          	auipc	a0,0x1c
    80006454:	1f850513          	addi	a0,a0,504 # 80022648 <disk+0x8>
    80006458:	953a                	add	a0,a0,a4
  if(write)
    8000645a:	e60d14e3          	bnez	s10,800062c2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000645e:	00a60793          	addi	a5,a2,10
    80006462:	00479693          	slli	a3,a5,0x4
    80006466:	0001c797          	auipc	a5,0x1c
    8000646a:	1da78793          	addi	a5,a5,474 # 80022640 <disk>
    8000646e:	97b6                	add	a5,a5,a3
    80006470:	0007a423          	sw	zero,8(a5)
    80006474:	b595                	j	800062d8 <virtio_disk_rw+0xf0>

0000000080006476 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006476:	1101                	addi	sp,sp,-32
    80006478:	ec06                	sd	ra,24(sp)
    8000647a:	e822                	sd	s0,16(sp)
    8000647c:	e426                	sd	s1,8(sp)
    8000647e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006480:	0001c497          	auipc	s1,0x1c
    80006484:	1c048493          	addi	s1,s1,448 # 80022640 <disk>
    80006488:	0001c517          	auipc	a0,0x1c
    8000648c:	2e050513          	addi	a0,a0,736 # 80022768 <disk+0x128>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	75a080e7          	jalr	1882(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006498:	10001737          	lui	a4,0x10001
    8000649c:	533c                	lw	a5,96(a4)
    8000649e:	8b8d                	andi	a5,a5,3
    800064a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064a6:	689c                	ld	a5,16(s1)
    800064a8:	0204d703          	lhu	a4,32(s1)
    800064ac:	0027d783          	lhu	a5,2(a5)
    800064b0:	04f70863          	beq	a4,a5,80006500 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064b4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064b8:	6898                	ld	a4,16(s1)
    800064ba:	0204d783          	lhu	a5,32(s1)
    800064be:	8b9d                	andi	a5,a5,7
    800064c0:	078e                	slli	a5,a5,0x3
    800064c2:	97ba                	add	a5,a5,a4
    800064c4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064c6:	00278713          	addi	a4,a5,2
    800064ca:	0712                	slli	a4,a4,0x4
    800064cc:	9726                	add	a4,a4,s1
    800064ce:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064d2:	e721                	bnez	a4,8000651a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064d4:	0789                	addi	a5,a5,2
    800064d6:	0792                	slli	a5,a5,0x4
    800064d8:	97a6                	add	a5,a5,s1
    800064da:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064dc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064e0:	ffffc097          	auipc	ra,0xffffc
    800064e4:	c0e080e7          	jalr	-1010(ra) # 800020ee <wakeup>

    disk.used_idx += 1;
    800064e8:	0204d783          	lhu	a5,32(s1)
    800064ec:	2785                	addiw	a5,a5,1
    800064ee:	17c2                	slli	a5,a5,0x30
    800064f0:	93c1                	srli	a5,a5,0x30
    800064f2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064f6:	6898                	ld	a4,16(s1)
    800064f8:	00275703          	lhu	a4,2(a4)
    800064fc:	faf71ce3          	bne	a4,a5,800064b4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006500:	0001c517          	auipc	a0,0x1c
    80006504:	26850513          	addi	a0,a0,616 # 80022768 <disk+0x128>
    80006508:	ffffa097          	auipc	ra,0xffffa
    8000650c:	796080e7          	jalr	1942(ra) # 80000c9e <release>
}
    80006510:	60e2                	ld	ra,24(sp)
    80006512:	6442                	ld	s0,16(sp)
    80006514:	64a2                	ld	s1,8(sp)
    80006516:	6105                	addi	sp,sp,32
    80006518:	8082                	ret
      panic("virtio_disk_intr status");
    8000651a:	00002517          	auipc	a0,0x2
    8000651e:	54e50513          	addi	a0,a0,1358 # 80008a68 <sysargs+0x388>
    80006522:	ffffa097          	auipc	ra,0xffffa
    80006526:	022080e7          	jalr	34(ra) # 80000544 <panic>
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
