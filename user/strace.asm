
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include <sys/types.h>
#include "user.h"

int main(int argc, char** argv){
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
    if(argc<=2){
   a:	4789                	li	a5,2
   c:	02a7d963          	bge	a5,a0,3e <main+0x3e>
  10:	84ae                	mv	s1,a1
        printf("strace: Too few arguments\n");
        return 1;
    }
    
    trace(atoi(argv[1]));
  12:	6588                	ld	a0,8(a1)
  14:	00000097          	auipc	ra,0x0
  18:	1ce080e7          	jalr	462(ra) # 1e2 <atoi>
  1c:	00000097          	auipc	ra,0x0
  20:	366080e7          	jalr	870(ra) # 382 <trace>

    exec(argv[2], (argv + 2));
  24:	01048593          	addi	a1,s1,16
  28:	6888                	ld	a0,16(s1)
  2a:	00000097          	auipc	ra,0x0
  2e:	2f0080e7          	jalr	752(ra) # 31a <exec>

    return 0;
  32:	4501                	li	a0,0
  34:	60e2                	ld	ra,24(sp)
  36:	6442                	ld	s0,16(sp)
  38:	64a2                	ld	s1,8(sp)
  3a:	6105                	addi	sp,sp,32
  3c:	8082                	ret
        printf("strace: Too few arguments\n");
  3e:	00000517          	auipc	a0,0x0
  42:	7d250513          	addi	a0,a0,2002 # 810 <malloc+0xf0>
  46:	00000097          	auipc	ra,0x0
  4a:	61c080e7          	jalr	1564(ra) # 662 <printf>
        return 1;
  4e:	4505                	li	a0,1
  50:	b7d5                	j	34 <main+0x34>

0000000000000052 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  52:	1141                	addi	sp,sp,-16
  54:	e406                	sd	ra,8(sp)
  56:	e022                	sd	s0,0(sp)
  58:	0800                	addi	s0,sp,16
  extern int main();
  main();
  5a:	00000097          	auipc	ra,0x0
  5e:	fa6080e7          	jalr	-90(ra) # 0 <main>
  exit(0);
  62:	4501                	li	a0,0
  64:	00000097          	auipc	ra,0x0
  68:	27e080e7          	jalr	638(ra) # 2e2 <exit>

000000000000006c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  6c:	1141                	addi	sp,sp,-16
  6e:	e422                	sd	s0,8(sp)
  70:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  72:	87aa                	mv	a5,a0
  74:	0585                	addi	a1,a1,1
  76:	0785                	addi	a5,a5,1
  78:	fff5c703          	lbu	a4,-1(a1)
  7c:	fee78fa3          	sb	a4,-1(a5)
  80:	fb75                	bnez	a4,74 <strcpy+0x8>
    ;
  return os;
}
  82:	6422                	ld	s0,8(sp)
  84:	0141                	addi	sp,sp,16
  86:	8082                	ret

0000000000000088 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  88:	1141                	addi	sp,sp,-16
  8a:	e422                	sd	s0,8(sp)
  8c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  8e:	00054783          	lbu	a5,0(a0)
  92:	cb91                	beqz	a5,a6 <strcmp+0x1e>
  94:	0005c703          	lbu	a4,0(a1)
  98:	00f71763          	bne	a4,a5,a6 <strcmp+0x1e>
    p++, q++;
  9c:	0505                	addi	a0,a0,1
  9e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  a0:	00054783          	lbu	a5,0(a0)
  a4:	fbe5                	bnez	a5,94 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  a6:	0005c503          	lbu	a0,0(a1)
}
  aa:	40a7853b          	subw	a0,a5,a0
  ae:	6422                	ld	s0,8(sp)
  b0:	0141                	addi	sp,sp,16
  b2:	8082                	ret

00000000000000b4 <strlen>:

uint
strlen(const char *s)
{
  b4:	1141                	addi	sp,sp,-16
  b6:	e422                	sd	s0,8(sp)
  b8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ba:	00054783          	lbu	a5,0(a0)
  be:	cf91                	beqz	a5,da <strlen+0x26>
  c0:	0505                	addi	a0,a0,1
  c2:	87aa                	mv	a5,a0
  c4:	4685                	li	a3,1
  c6:	9e89                	subw	a3,a3,a0
  c8:	00f6853b          	addw	a0,a3,a5
  cc:	0785                	addi	a5,a5,1
  ce:	fff7c703          	lbu	a4,-1(a5)
  d2:	fb7d                	bnez	a4,c8 <strlen+0x14>
    ;
  return n;
}
  d4:	6422                	ld	s0,8(sp)
  d6:	0141                	addi	sp,sp,16
  d8:	8082                	ret
  for(n = 0; s[n]; n++)
  da:	4501                	li	a0,0
  dc:	bfe5                	j	d4 <strlen+0x20>

00000000000000de <memset>:

void*
memset(void *dst, int c, uint n)
{
  de:	1141                	addi	sp,sp,-16
  e0:	e422                	sd	s0,8(sp)
  e2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  e4:	ce09                	beqz	a2,fe <memset+0x20>
  e6:	87aa                	mv	a5,a0
  e8:	fff6071b          	addiw	a4,a2,-1
  ec:	1702                	slli	a4,a4,0x20
  ee:	9301                	srli	a4,a4,0x20
  f0:	0705                	addi	a4,a4,1
  f2:	972a                	add	a4,a4,a0
    cdst[i] = c;
  f4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  f8:	0785                	addi	a5,a5,1
  fa:	fee79de3          	bne	a5,a4,f4 <memset+0x16>
  }
  return dst;
}
  fe:	6422                	ld	s0,8(sp)
 100:	0141                	addi	sp,sp,16
 102:	8082                	ret

0000000000000104 <strchr>:

char*
strchr(const char *s, char c)
{
 104:	1141                	addi	sp,sp,-16
 106:	e422                	sd	s0,8(sp)
 108:	0800                	addi	s0,sp,16
  for(; *s; s++)
 10a:	00054783          	lbu	a5,0(a0)
 10e:	cb99                	beqz	a5,124 <strchr+0x20>
    if(*s == c)
 110:	00f58763          	beq	a1,a5,11e <strchr+0x1a>
  for(; *s; s++)
 114:	0505                	addi	a0,a0,1
 116:	00054783          	lbu	a5,0(a0)
 11a:	fbfd                	bnez	a5,110 <strchr+0xc>
      return (char*)s;
  return 0;
 11c:	4501                	li	a0,0
}
 11e:	6422                	ld	s0,8(sp)
 120:	0141                	addi	sp,sp,16
 122:	8082                	ret
  return 0;
 124:	4501                	li	a0,0
 126:	bfe5                	j	11e <strchr+0x1a>

0000000000000128 <gets>:

char*
gets(char *buf, int max)
{
 128:	711d                	addi	sp,sp,-96
 12a:	ec86                	sd	ra,88(sp)
 12c:	e8a2                	sd	s0,80(sp)
 12e:	e4a6                	sd	s1,72(sp)
 130:	e0ca                	sd	s2,64(sp)
 132:	fc4e                	sd	s3,56(sp)
 134:	f852                	sd	s4,48(sp)
 136:	f456                	sd	s5,40(sp)
 138:	f05a                	sd	s6,32(sp)
 13a:	ec5e                	sd	s7,24(sp)
 13c:	1080                	addi	s0,sp,96
 13e:	8baa                	mv	s7,a0
 140:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 142:	892a                	mv	s2,a0
 144:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 146:	4aa9                	li	s5,10
 148:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 14a:	89a6                	mv	s3,s1
 14c:	2485                	addiw	s1,s1,1
 14e:	0344d863          	bge	s1,s4,17e <gets+0x56>
    cc = read(0, &c, 1);
 152:	4605                	li	a2,1
 154:	faf40593          	addi	a1,s0,-81
 158:	4501                	li	a0,0
 15a:	00000097          	auipc	ra,0x0
 15e:	1a0080e7          	jalr	416(ra) # 2fa <read>
    if(cc < 1)
 162:	00a05e63          	blez	a0,17e <gets+0x56>
    buf[i++] = c;
 166:	faf44783          	lbu	a5,-81(s0)
 16a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 16e:	01578763          	beq	a5,s5,17c <gets+0x54>
 172:	0905                	addi	s2,s2,1
 174:	fd679be3          	bne	a5,s6,14a <gets+0x22>
  for(i=0; i+1 < max; ){
 178:	89a6                	mv	s3,s1
 17a:	a011                	j	17e <gets+0x56>
 17c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 17e:	99de                	add	s3,s3,s7
 180:	00098023          	sb	zero,0(s3)
  return buf;
}
 184:	855e                	mv	a0,s7
 186:	60e6                	ld	ra,88(sp)
 188:	6446                	ld	s0,80(sp)
 18a:	64a6                	ld	s1,72(sp)
 18c:	6906                	ld	s2,64(sp)
 18e:	79e2                	ld	s3,56(sp)
 190:	7a42                	ld	s4,48(sp)
 192:	7aa2                	ld	s5,40(sp)
 194:	7b02                	ld	s6,32(sp)
 196:	6be2                	ld	s7,24(sp)
 198:	6125                	addi	sp,sp,96
 19a:	8082                	ret

000000000000019c <stat>:

int
stat(const char *n, struct stat *st)
{
 19c:	1101                	addi	sp,sp,-32
 19e:	ec06                	sd	ra,24(sp)
 1a0:	e822                	sd	s0,16(sp)
 1a2:	e426                	sd	s1,8(sp)
 1a4:	e04a                	sd	s2,0(sp)
 1a6:	1000                	addi	s0,sp,32
 1a8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1aa:	4581                	li	a1,0
 1ac:	00000097          	auipc	ra,0x0
 1b0:	176080e7          	jalr	374(ra) # 322 <open>
  if(fd < 0)
 1b4:	02054563          	bltz	a0,1de <stat+0x42>
 1b8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ba:	85ca                	mv	a1,s2
 1bc:	00000097          	auipc	ra,0x0
 1c0:	17e080e7          	jalr	382(ra) # 33a <fstat>
 1c4:	892a                	mv	s2,a0
  close(fd);
 1c6:	8526                	mv	a0,s1
 1c8:	00000097          	auipc	ra,0x0
 1cc:	142080e7          	jalr	322(ra) # 30a <close>
  return r;
}
 1d0:	854a                	mv	a0,s2
 1d2:	60e2                	ld	ra,24(sp)
 1d4:	6442                	ld	s0,16(sp)
 1d6:	64a2                	ld	s1,8(sp)
 1d8:	6902                	ld	s2,0(sp)
 1da:	6105                	addi	sp,sp,32
 1dc:	8082                	ret
    return -1;
 1de:	597d                	li	s2,-1
 1e0:	bfc5                	j	1d0 <stat+0x34>

00000000000001e2 <atoi>:

int
atoi(const char *s)
{
 1e2:	1141                	addi	sp,sp,-16
 1e4:	e422                	sd	s0,8(sp)
 1e6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1e8:	00054603          	lbu	a2,0(a0)
 1ec:	fd06079b          	addiw	a5,a2,-48
 1f0:	0ff7f793          	andi	a5,a5,255
 1f4:	4725                	li	a4,9
 1f6:	02f76963          	bltu	a4,a5,228 <atoi+0x46>
 1fa:	86aa                	mv	a3,a0
  n = 0;
 1fc:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1fe:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 200:	0685                	addi	a3,a3,1
 202:	0025179b          	slliw	a5,a0,0x2
 206:	9fa9                	addw	a5,a5,a0
 208:	0017979b          	slliw	a5,a5,0x1
 20c:	9fb1                	addw	a5,a5,a2
 20e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 212:	0006c603          	lbu	a2,0(a3)
 216:	fd06071b          	addiw	a4,a2,-48
 21a:	0ff77713          	andi	a4,a4,255
 21e:	fee5f1e3          	bgeu	a1,a4,200 <atoi+0x1e>
  return n;
}
 222:	6422                	ld	s0,8(sp)
 224:	0141                	addi	sp,sp,16
 226:	8082                	ret
  n = 0;
 228:	4501                	li	a0,0
 22a:	bfe5                	j	222 <atoi+0x40>

000000000000022c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 22c:	1141                	addi	sp,sp,-16
 22e:	e422                	sd	s0,8(sp)
 230:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 232:	02b57663          	bgeu	a0,a1,25e <memmove+0x32>
    while(n-- > 0)
 236:	02c05163          	blez	a2,258 <memmove+0x2c>
 23a:	fff6079b          	addiw	a5,a2,-1
 23e:	1782                	slli	a5,a5,0x20
 240:	9381                	srli	a5,a5,0x20
 242:	0785                	addi	a5,a5,1
 244:	97aa                	add	a5,a5,a0
  dst = vdst;
 246:	872a                	mv	a4,a0
      *dst++ = *src++;
 248:	0585                	addi	a1,a1,1
 24a:	0705                	addi	a4,a4,1
 24c:	fff5c683          	lbu	a3,-1(a1)
 250:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 254:	fee79ae3          	bne	a5,a4,248 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 258:	6422                	ld	s0,8(sp)
 25a:	0141                	addi	sp,sp,16
 25c:	8082                	ret
    dst += n;
 25e:	00c50733          	add	a4,a0,a2
    src += n;
 262:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 264:	fec05ae3          	blez	a2,258 <memmove+0x2c>
 268:	fff6079b          	addiw	a5,a2,-1
 26c:	1782                	slli	a5,a5,0x20
 26e:	9381                	srli	a5,a5,0x20
 270:	fff7c793          	not	a5,a5
 274:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 276:	15fd                	addi	a1,a1,-1
 278:	177d                	addi	a4,a4,-1
 27a:	0005c683          	lbu	a3,0(a1)
 27e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 282:	fee79ae3          	bne	a5,a4,276 <memmove+0x4a>
 286:	bfc9                	j	258 <memmove+0x2c>

0000000000000288 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 288:	1141                	addi	sp,sp,-16
 28a:	e422                	sd	s0,8(sp)
 28c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 28e:	ca05                	beqz	a2,2be <memcmp+0x36>
 290:	fff6069b          	addiw	a3,a2,-1
 294:	1682                	slli	a3,a3,0x20
 296:	9281                	srli	a3,a3,0x20
 298:	0685                	addi	a3,a3,1
 29a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 29c:	00054783          	lbu	a5,0(a0)
 2a0:	0005c703          	lbu	a4,0(a1)
 2a4:	00e79863          	bne	a5,a4,2b4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2a8:	0505                	addi	a0,a0,1
    p2++;
 2aa:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2ac:	fed518e3          	bne	a0,a3,29c <memcmp+0x14>
  }
  return 0;
 2b0:	4501                	li	a0,0
 2b2:	a019                	j	2b8 <memcmp+0x30>
      return *p1 - *p2;
 2b4:	40e7853b          	subw	a0,a5,a4
}
 2b8:	6422                	ld	s0,8(sp)
 2ba:	0141                	addi	sp,sp,16
 2bc:	8082                	ret
  return 0;
 2be:	4501                	li	a0,0
 2c0:	bfe5                	j	2b8 <memcmp+0x30>

00000000000002c2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2c2:	1141                	addi	sp,sp,-16
 2c4:	e406                	sd	ra,8(sp)
 2c6:	e022                	sd	s0,0(sp)
 2c8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2ca:	00000097          	auipc	ra,0x0
 2ce:	f62080e7          	jalr	-158(ra) # 22c <memmove>
}
 2d2:	60a2                	ld	ra,8(sp)
 2d4:	6402                	ld	s0,0(sp)
 2d6:	0141                	addi	sp,sp,16
 2d8:	8082                	ret

00000000000002da <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2da:	4885                	li	a7,1
 ecall
 2dc:	00000073          	ecall
 ret
 2e0:	8082                	ret

00000000000002e2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2e2:	4889                	li	a7,2
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ea:	488d                	li	a7,3
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2f2:	4891                	li	a7,4
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <read>:
.global read
read:
 li a7, SYS_read
 2fa:	4895                	li	a7,5
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <write>:
.global write
write:
 li a7, SYS_write
 302:	48c1                	li	a7,16
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <close>:
.global close
close:
 li a7, SYS_close
 30a:	48d5                	li	a7,21
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <kill>:
.global kill
kill:
 li a7, SYS_kill
 312:	4899                	li	a7,6
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <exec>:
.global exec
exec:
 li a7, SYS_exec
 31a:	489d                	li	a7,7
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <open>:
.global open
open:
 li a7, SYS_open
 322:	48bd                	li	a7,15
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 32a:	48c5                	li	a7,17
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 332:	48c9                	li	a7,18
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 33a:	48a1                	li	a7,8
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <link>:
.global link
link:
 li a7, SYS_link
 342:	48cd                	li	a7,19
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 34a:	48d1                	li	a7,20
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 352:	48a5                	li	a7,9
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <dup>:
.global dup
dup:
 li a7, SYS_dup
 35a:	48a9                	li	a7,10
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 362:	48ad                	li	a7,11
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 36a:	48b1                	li	a7,12
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 372:	48b5                	li	a7,13
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 37a:	48b9                	li	a7,14
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <trace>:
.global trace
trace:
 li a7, SYS_trace
 382:	48d9                	li	a7,22
 ecall
 384:	00000073          	ecall
 388:	8082                	ret

000000000000038a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 38a:	1101                	addi	sp,sp,-32
 38c:	ec06                	sd	ra,24(sp)
 38e:	e822                	sd	s0,16(sp)
 390:	1000                	addi	s0,sp,32
 392:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 396:	4605                	li	a2,1
 398:	fef40593          	addi	a1,s0,-17
 39c:	00000097          	auipc	ra,0x0
 3a0:	f66080e7          	jalr	-154(ra) # 302 <write>
}
 3a4:	60e2                	ld	ra,24(sp)
 3a6:	6442                	ld	s0,16(sp)
 3a8:	6105                	addi	sp,sp,32
 3aa:	8082                	ret

00000000000003ac <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ac:	7139                	addi	sp,sp,-64
 3ae:	fc06                	sd	ra,56(sp)
 3b0:	f822                	sd	s0,48(sp)
 3b2:	f426                	sd	s1,40(sp)
 3b4:	f04a                	sd	s2,32(sp)
 3b6:	ec4e                	sd	s3,24(sp)
 3b8:	0080                	addi	s0,sp,64
 3ba:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3bc:	c299                	beqz	a3,3c2 <printint+0x16>
 3be:	0805c863          	bltz	a1,44e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3c2:	2581                	sext.w	a1,a1
  neg = 0;
 3c4:	4881                	li	a7,0
 3c6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3ca:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3cc:	2601                	sext.w	a2,a2
 3ce:	00000517          	auipc	a0,0x0
 3d2:	46a50513          	addi	a0,a0,1130 # 838 <digits>
 3d6:	883a                	mv	a6,a4
 3d8:	2705                	addiw	a4,a4,1
 3da:	02c5f7bb          	remuw	a5,a1,a2
 3de:	1782                	slli	a5,a5,0x20
 3e0:	9381                	srli	a5,a5,0x20
 3e2:	97aa                	add	a5,a5,a0
 3e4:	0007c783          	lbu	a5,0(a5)
 3e8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ec:	0005879b          	sext.w	a5,a1
 3f0:	02c5d5bb          	divuw	a1,a1,a2
 3f4:	0685                	addi	a3,a3,1
 3f6:	fec7f0e3          	bgeu	a5,a2,3d6 <printint+0x2a>
  if(neg)
 3fa:	00088b63          	beqz	a7,410 <printint+0x64>
    buf[i++] = '-';
 3fe:	fd040793          	addi	a5,s0,-48
 402:	973e                	add	a4,a4,a5
 404:	02d00793          	li	a5,45
 408:	fef70823          	sb	a5,-16(a4)
 40c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 410:	02e05863          	blez	a4,440 <printint+0x94>
 414:	fc040793          	addi	a5,s0,-64
 418:	00e78933          	add	s2,a5,a4
 41c:	fff78993          	addi	s3,a5,-1
 420:	99ba                	add	s3,s3,a4
 422:	377d                	addiw	a4,a4,-1
 424:	1702                	slli	a4,a4,0x20
 426:	9301                	srli	a4,a4,0x20
 428:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 42c:	fff94583          	lbu	a1,-1(s2)
 430:	8526                	mv	a0,s1
 432:	00000097          	auipc	ra,0x0
 436:	f58080e7          	jalr	-168(ra) # 38a <putc>
  while(--i >= 0)
 43a:	197d                	addi	s2,s2,-1
 43c:	ff3918e3          	bne	s2,s3,42c <printint+0x80>
}
 440:	70e2                	ld	ra,56(sp)
 442:	7442                	ld	s0,48(sp)
 444:	74a2                	ld	s1,40(sp)
 446:	7902                	ld	s2,32(sp)
 448:	69e2                	ld	s3,24(sp)
 44a:	6121                	addi	sp,sp,64
 44c:	8082                	ret
    x = -xx;
 44e:	40b005bb          	negw	a1,a1
    neg = 1;
 452:	4885                	li	a7,1
    x = -xx;
 454:	bf8d                	j	3c6 <printint+0x1a>

0000000000000456 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 456:	7119                	addi	sp,sp,-128
 458:	fc86                	sd	ra,120(sp)
 45a:	f8a2                	sd	s0,112(sp)
 45c:	f4a6                	sd	s1,104(sp)
 45e:	f0ca                	sd	s2,96(sp)
 460:	ecce                	sd	s3,88(sp)
 462:	e8d2                	sd	s4,80(sp)
 464:	e4d6                	sd	s5,72(sp)
 466:	e0da                	sd	s6,64(sp)
 468:	fc5e                	sd	s7,56(sp)
 46a:	f862                	sd	s8,48(sp)
 46c:	f466                	sd	s9,40(sp)
 46e:	f06a                	sd	s10,32(sp)
 470:	ec6e                	sd	s11,24(sp)
 472:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 474:	0005c903          	lbu	s2,0(a1)
 478:	18090f63          	beqz	s2,616 <vprintf+0x1c0>
 47c:	8aaa                	mv	s5,a0
 47e:	8b32                	mv	s6,a2
 480:	00158493          	addi	s1,a1,1
  state = 0;
 484:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 486:	02500a13          	li	s4,37
      if(c == 'd'){
 48a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 48e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 492:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 496:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 49a:	00000b97          	auipc	s7,0x0
 49e:	39eb8b93          	addi	s7,s7,926 # 838 <digits>
 4a2:	a839                	j	4c0 <vprintf+0x6a>
        putc(fd, c);
 4a4:	85ca                	mv	a1,s2
 4a6:	8556                	mv	a0,s5
 4a8:	00000097          	auipc	ra,0x0
 4ac:	ee2080e7          	jalr	-286(ra) # 38a <putc>
 4b0:	a019                	j	4b6 <vprintf+0x60>
    } else if(state == '%'){
 4b2:	01498f63          	beq	s3,s4,4d0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4b6:	0485                	addi	s1,s1,1
 4b8:	fff4c903          	lbu	s2,-1(s1)
 4bc:	14090d63          	beqz	s2,616 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4c0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4c4:	fe0997e3          	bnez	s3,4b2 <vprintf+0x5c>
      if(c == '%'){
 4c8:	fd479ee3          	bne	a5,s4,4a4 <vprintf+0x4e>
        state = '%';
 4cc:	89be                	mv	s3,a5
 4ce:	b7e5                	j	4b6 <vprintf+0x60>
      if(c == 'd'){
 4d0:	05878063          	beq	a5,s8,510 <vprintf+0xba>
      } else if(c == 'l') {
 4d4:	05978c63          	beq	a5,s9,52c <vprintf+0xd6>
      } else if(c == 'x') {
 4d8:	07a78863          	beq	a5,s10,548 <vprintf+0xf2>
      } else if(c == 'p') {
 4dc:	09b78463          	beq	a5,s11,564 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4e0:	07300713          	li	a4,115
 4e4:	0ce78663          	beq	a5,a4,5b0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4e8:	06300713          	li	a4,99
 4ec:	0ee78e63          	beq	a5,a4,5e8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4f0:	11478863          	beq	a5,s4,600 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4f4:	85d2                	mv	a1,s4
 4f6:	8556                	mv	a0,s5
 4f8:	00000097          	auipc	ra,0x0
 4fc:	e92080e7          	jalr	-366(ra) # 38a <putc>
        putc(fd, c);
 500:	85ca                	mv	a1,s2
 502:	8556                	mv	a0,s5
 504:	00000097          	auipc	ra,0x0
 508:	e86080e7          	jalr	-378(ra) # 38a <putc>
      }
      state = 0;
 50c:	4981                	li	s3,0
 50e:	b765                	j	4b6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 510:	008b0913          	addi	s2,s6,8
 514:	4685                	li	a3,1
 516:	4629                	li	a2,10
 518:	000b2583          	lw	a1,0(s6)
 51c:	8556                	mv	a0,s5
 51e:	00000097          	auipc	ra,0x0
 522:	e8e080e7          	jalr	-370(ra) # 3ac <printint>
 526:	8b4a                	mv	s6,s2
      state = 0;
 528:	4981                	li	s3,0
 52a:	b771                	j	4b6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 52c:	008b0913          	addi	s2,s6,8
 530:	4681                	li	a3,0
 532:	4629                	li	a2,10
 534:	000b2583          	lw	a1,0(s6)
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	e72080e7          	jalr	-398(ra) # 3ac <printint>
 542:	8b4a                	mv	s6,s2
      state = 0;
 544:	4981                	li	s3,0
 546:	bf85                	j	4b6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 548:	008b0913          	addi	s2,s6,8
 54c:	4681                	li	a3,0
 54e:	4641                	li	a2,16
 550:	000b2583          	lw	a1,0(s6)
 554:	8556                	mv	a0,s5
 556:	00000097          	auipc	ra,0x0
 55a:	e56080e7          	jalr	-426(ra) # 3ac <printint>
 55e:	8b4a                	mv	s6,s2
      state = 0;
 560:	4981                	li	s3,0
 562:	bf91                	j	4b6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 564:	008b0793          	addi	a5,s6,8
 568:	f8f43423          	sd	a5,-120(s0)
 56c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 570:	03000593          	li	a1,48
 574:	8556                	mv	a0,s5
 576:	00000097          	auipc	ra,0x0
 57a:	e14080e7          	jalr	-492(ra) # 38a <putc>
  putc(fd, 'x');
 57e:	85ea                	mv	a1,s10
 580:	8556                	mv	a0,s5
 582:	00000097          	auipc	ra,0x0
 586:	e08080e7          	jalr	-504(ra) # 38a <putc>
 58a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 58c:	03c9d793          	srli	a5,s3,0x3c
 590:	97de                	add	a5,a5,s7
 592:	0007c583          	lbu	a1,0(a5)
 596:	8556                	mv	a0,s5
 598:	00000097          	auipc	ra,0x0
 59c:	df2080e7          	jalr	-526(ra) # 38a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5a0:	0992                	slli	s3,s3,0x4
 5a2:	397d                	addiw	s2,s2,-1
 5a4:	fe0914e3          	bnez	s2,58c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5a8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5ac:	4981                	li	s3,0
 5ae:	b721                	j	4b6 <vprintf+0x60>
        s = va_arg(ap, char*);
 5b0:	008b0993          	addi	s3,s6,8
 5b4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5b8:	02090163          	beqz	s2,5da <vprintf+0x184>
        while(*s != 0){
 5bc:	00094583          	lbu	a1,0(s2)
 5c0:	c9a1                	beqz	a1,610 <vprintf+0x1ba>
          putc(fd, *s);
 5c2:	8556                	mv	a0,s5
 5c4:	00000097          	auipc	ra,0x0
 5c8:	dc6080e7          	jalr	-570(ra) # 38a <putc>
          s++;
 5cc:	0905                	addi	s2,s2,1
        while(*s != 0){
 5ce:	00094583          	lbu	a1,0(s2)
 5d2:	f9e5                	bnez	a1,5c2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 5d4:	8b4e                	mv	s6,s3
      state = 0;
 5d6:	4981                	li	s3,0
 5d8:	bdf9                	j	4b6 <vprintf+0x60>
          s = "(null)";
 5da:	00000917          	auipc	s2,0x0
 5de:	25690913          	addi	s2,s2,598 # 830 <malloc+0x110>
        while(*s != 0){
 5e2:	02800593          	li	a1,40
 5e6:	bff1                	j	5c2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5e8:	008b0913          	addi	s2,s6,8
 5ec:	000b4583          	lbu	a1,0(s6)
 5f0:	8556                	mv	a0,s5
 5f2:	00000097          	auipc	ra,0x0
 5f6:	d98080e7          	jalr	-616(ra) # 38a <putc>
 5fa:	8b4a                	mv	s6,s2
      state = 0;
 5fc:	4981                	li	s3,0
 5fe:	bd65                	j	4b6 <vprintf+0x60>
        putc(fd, c);
 600:	85d2                	mv	a1,s4
 602:	8556                	mv	a0,s5
 604:	00000097          	auipc	ra,0x0
 608:	d86080e7          	jalr	-634(ra) # 38a <putc>
      state = 0;
 60c:	4981                	li	s3,0
 60e:	b565                	j	4b6 <vprintf+0x60>
        s = va_arg(ap, char*);
 610:	8b4e                	mv	s6,s3
      state = 0;
 612:	4981                	li	s3,0
 614:	b54d                	j	4b6 <vprintf+0x60>
    }
  }
}
 616:	70e6                	ld	ra,120(sp)
 618:	7446                	ld	s0,112(sp)
 61a:	74a6                	ld	s1,104(sp)
 61c:	7906                	ld	s2,96(sp)
 61e:	69e6                	ld	s3,88(sp)
 620:	6a46                	ld	s4,80(sp)
 622:	6aa6                	ld	s5,72(sp)
 624:	6b06                	ld	s6,64(sp)
 626:	7be2                	ld	s7,56(sp)
 628:	7c42                	ld	s8,48(sp)
 62a:	7ca2                	ld	s9,40(sp)
 62c:	7d02                	ld	s10,32(sp)
 62e:	6de2                	ld	s11,24(sp)
 630:	6109                	addi	sp,sp,128
 632:	8082                	ret

0000000000000634 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 634:	715d                	addi	sp,sp,-80
 636:	ec06                	sd	ra,24(sp)
 638:	e822                	sd	s0,16(sp)
 63a:	1000                	addi	s0,sp,32
 63c:	e010                	sd	a2,0(s0)
 63e:	e414                	sd	a3,8(s0)
 640:	e818                	sd	a4,16(s0)
 642:	ec1c                	sd	a5,24(s0)
 644:	03043023          	sd	a6,32(s0)
 648:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 64c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 650:	8622                	mv	a2,s0
 652:	00000097          	auipc	ra,0x0
 656:	e04080e7          	jalr	-508(ra) # 456 <vprintf>
}
 65a:	60e2                	ld	ra,24(sp)
 65c:	6442                	ld	s0,16(sp)
 65e:	6161                	addi	sp,sp,80
 660:	8082                	ret

0000000000000662 <printf>:

void
printf(const char *fmt, ...)
{
 662:	711d                	addi	sp,sp,-96
 664:	ec06                	sd	ra,24(sp)
 666:	e822                	sd	s0,16(sp)
 668:	1000                	addi	s0,sp,32
 66a:	e40c                	sd	a1,8(s0)
 66c:	e810                	sd	a2,16(s0)
 66e:	ec14                	sd	a3,24(s0)
 670:	f018                	sd	a4,32(s0)
 672:	f41c                	sd	a5,40(s0)
 674:	03043823          	sd	a6,48(s0)
 678:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 67c:	00840613          	addi	a2,s0,8
 680:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 684:	85aa                	mv	a1,a0
 686:	4505                	li	a0,1
 688:	00000097          	auipc	ra,0x0
 68c:	dce080e7          	jalr	-562(ra) # 456 <vprintf>
}
 690:	60e2                	ld	ra,24(sp)
 692:	6442                	ld	s0,16(sp)
 694:	6125                	addi	sp,sp,96
 696:	8082                	ret

0000000000000698 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 698:	1141                	addi	sp,sp,-16
 69a:	e422                	sd	s0,8(sp)
 69c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 69e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a2:	00001797          	auipc	a5,0x1
 6a6:	95e7b783          	ld	a5,-1698(a5) # 1000 <freep>
 6aa:	a805                	j	6da <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6ac:	4618                	lw	a4,8(a2)
 6ae:	9db9                	addw	a1,a1,a4
 6b0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6b4:	6398                	ld	a4,0(a5)
 6b6:	6318                	ld	a4,0(a4)
 6b8:	fee53823          	sd	a4,-16(a0)
 6bc:	a091                	j	700 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6be:	ff852703          	lw	a4,-8(a0)
 6c2:	9e39                	addw	a2,a2,a4
 6c4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6c6:	ff053703          	ld	a4,-16(a0)
 6ca:	e398                	sd	a4,0(a5)
 6cc:	a099                	j	712 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ce:	6398                	ld	a4,0(a5)
 6d0:	00e7e463          	bltu	a5,a4,6d8 <free+0x40>
 6d4:	00e6ea63          	bltu	a3,a4,6e8 <free+0x50>
{
 6d8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6da:	fed7fae3          	bgeu	a5,a3,6ce <free+0x36>
 6de:	6398                	ld	a4,0(a5)
 6e0:	00e6e463          	bltu	a3,a4,6e8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6e4:	fee7eae3          	bltu	a5,a4,6d8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6e8:	ff852583          	lw	a1,-8(a0)
 6ec:	6390                	ld	a2,0(a5)
 6ee:	02059713          	slli	a4,a1,0x20
 6f2:	9301                	srli	a4,a4,0x20
 6f4:	0712                	slli	a4,a4,0x4
 6f6:	9736                	add	a4,a4,a3
 6f8:	fae60ae3          	beq	a2,a4,6ac <free+0x14>
    bp->s.ptr = p->s.ptr;
 6fc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 700:	4790                	lw	a2,8(a5)
 702:	02061713          	slli	a4,a2,0x20
 706:	9301                	srli	a4,a4,0x20
 708:	0712                	slli	a4,a4,0x4
 70a:	973e                	add	a4,a4,a5
 70c:	fae689e3          	beq	a3,a4,6be <free+0x26>
  } else
    p->s.ptr = bp;
 710:	e394                	sd	a3,0(a5)
  freep = p;
 712:	00001717          	auipc	a4,0x1
 716:	8ef73723          	sd	a5,-1810(a4) # 1000 <freep>
}
 71a:	6422                	ld	s0,8(sp)
 71c:	0141                	addi	sp,sp,16
 71e:	8082                	ret

0000000000000720 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 720:	7139                	addi	sp,sp,-64
 722:	fc06                	sd	ra,56(sp)
 724:	f822                	sd	s0,48(sp)
 726:	f426                	sd	s1,40(sp)
 728:	f04a                	sd	s2,32(sp)
 72a:	ec4e                	sd	s3,24(sp)
 72c:	e852                	sd	s4,16(sp)
 72e:	e456                	sd	s5,8(sp)
 730:	e05a                	sd	s6,0(sp)
 732:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 734:	02051493          	slli	s1,a0,0x20
 738:	9081                	srli	s1,s1,0x20
 73a:	04bd                	addi	s1,s1,15
 73c:	8091                	srli	s1,s1,0x4
 73e:	0014899b          	addiw	s3,s1,1
 742:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 744:	00001517          	auipc	a0,0x1
 748:	8bc53503          	ld	a0,-1860(a0) # 1000 <freep>
 74c:	c515                	beqz	a0,778 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 74e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 750:	4798                	lw	a4,8(a5)
 752:	02977f63          	bgeu	a4,s1,790 <malloc+0x70>
 756:	8a4e                	mv	s4,s3
 758:	0009871b          	sext.w	a4,s3
 75c:	6685                	lui	a3,0x1
 75e:	00d77363          	bgeu	a4,a3,764 <malloc+0x44>
 762:	6a05                	lui	s4,0x1
 764:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 768:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 76c:	00001917          	auipc	s2,0x1
 770:	89490913          	addi	s2,s2,-1900 # 1000 <freep>
  if(p == (char*)-1)
 774:	5afd                	li	s5,-1
 776:	a88d                	j	7e8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 778:	00001797          	auipc	a5,0x1
 77c:	89878793          	addi	a5,a5,-1896 # 1010 <base>
 780:	00001717          	auipc	a4,0x1
 784:	88f73023          	sd	a5,-1920(a4) # 1000 <freep>
 788:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 78a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 78e:	b7e1                	j	756 <malloc+0x36>
      if(p->s.size == nunits)
 790:	02e48b63          	beq	s1,a4,7c6 <malloc+0xa6>
        p->s.size -= nunits;
 794:	4137073b          	subw	a4,a4,s3
 798:	c798                	sw	a4,8(a5)
        p += p->s.size;
 79a:	1702                	slli	a4,a4,0x20
 79c:	9301                	srli	a4,a4,0x20
 79e:	0712                	slli	a4,a4,0x4
 7a0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7a2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7a6:	00001717          	auipc	a4,0x1
 7aa:	84a73d23          	sd	a0,-1958(a4) # 1000 <freep>
      return (void*)(p + 1);
 7ae:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7b2:	70e2                	ld	ra,56(sp)
 7b4:	7442                	ld	s0,48(sp)
 7b6:	74a2                	ld	s1,40(sp)
 7b8:	7902                	ld	s2,32(sp)
 7ba:	69e2                	ld	s3,24(sp)
 7bc:	6a42                	ld	s4,16(sp)
 7be:	6aa2                	ld	s5,8(sp)
 7c0:	6b02                	ld	s6,0(sp)
 7c2:	6121                	addi	sp,sp,64
 7c4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7c6:	6398                	ld	a4,0(a5)
 7c8:	e118                	sd	a4,0(a0)
 7ca:	bff1                	j	7a6 <malloc+0x86>
  hp->s.size = nu;
 7cc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7d0:	0541                	addi	a0,a0,16
 7d2:	00000097          	auipc	ra,0x0
 7d6:	ec6080e7          	jalr	-314(ra) # 698 <free>
  return freep;
 7da:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7de:	d971                	beqz	a0,7b2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e2:	4798                	lw	a4,8(a5)
 7e4:	fa9776e3          	bgeu	a4,s1,790 <malloc+0x70>
    if(p == freep)
 7e8:	00093703          	ld	a4,0(s2)
 7ec:	853e                	mv	a0,a5
 7ee:	fef719e3          	bne	a4,a5,7e0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7f2:	8552                	mv	a0,s4
 7f4:	00000097          	auipc	ra,0x0
 7f8:	b76080e7          	jalr	-1162(ra) # 36a <sbrk>
  if(p == (char*)-1)
 7fc:	fd5518e3          	bne	a0,s5,7cc <malloc+0xac>
        return 0;
 800:	4501                	li	a0,0
 802:	bf45                	j	7b2 <malloc+0x92>