
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 e0 11 f0       	mov    $0xf011e000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 6a 00 00 00       	call   f01000a8 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 be 22 f0 00 	cmpl   $0x0,0xf022be80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 be 22 f0    	mov    %esi,0xf022be80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 f5 60 00 00       	call   f0106159 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 40 68 10 f0 	movl   $0xf0106840,(%esp)
f010007d:	e8 79 3f 00 00       	call   f0103ffb <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 3a 3f 00 00       	call   f0103fc8 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 de 7c 10 f0 	movl   $0xf0107cde,(%esp)
f0100095:	e8 61 3f 00 00       	call   f0103ffb <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 82 09 00 00       	call   f0100a28 <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <i386_init>:
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	53                   	push   %ebx
f01000ac:	83 ec 14             	sub    $0x14,%esp
	cons_init();
f01000af:	e8 bb 05 00 00       	call   f010066f <cons_init>
	cprintf("444544 decimal is %o octal!\n", 444544);
f01000b4:	c7 44 24 04 80 c8 06 	movl   $0x6c880,0x4(%esp)
f01000bb:	00 
f01000bc:	c7 04 24 ac 68 10 f0 	movl   $0xf01068ac,(%esp)
f01000c3:	e8 33 3f 00 00       	call   f0103ffb <cprintf>
	mem_init();
f01000c8:	e8 d0 14 00 00       	call   f010159d <mem_init>
	env_init();
f01000cd:	e8 ce 36 00 00       	call   f01037a0 <env_init>
	trap_init();
f01000d2:	e8 2a 40 00 00       	call   f0104101 <trap_init>
	mp_init();
f01000d7:	e8 6e 5d 00 00       	call   f0105e4a <mp_init>
	lapic_init();
f01000dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01000e0:	e8 8f 60 00 00       	call   f0106174 <lapic_init>
	pic_init();
f01000e5:	e8 41 3e 00 00       	call   f0103f2b <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ea:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f01000f1:	e8 e1 62 00 00       	call   f01063d7 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f6:	83 3d 88 be 22 f0 07 	cmpl   $0x7,0xf022be88
f01000fd:	77 24                	ja     f0100123 <i386_init+0x7b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01000ff:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100106:	00 
f0100107:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f010010e:	f0 
f010010f:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100116:	00 
f0100117:	c7 04 24 c9 68 10 f0 	movl   $0xf01068c9,(%esp)
f010011e:	e8 1d ff ff ff       	call   f0100040 <_panic>
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100123:	b8 82 5d 10 f0       	mov    $0xf0105d82,%eax
f0100128:	2d 08 5d 10 f0       	sub    $0xf0105d08,%eax
f010012d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100131:	c7 44 24 04 08 5d 10 	movl   $0xf0105d08,0x4(%esp)
f0100138:	f0 
f0100139:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100140:	e8 0f 5a 00 00       	call   f0105b54 <memmove>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100145:	bb 20 c0 22 f0       	mov    $0xf022c020,%ebx
f010014a:	eb 4d                	jmp    f0100199 <i386_init+0xf1>
		if (c == cpus + cpunum())  // We've started already.
f010014c:	e8 08 60 00 00       	call   f0106159 <cpunum>
f0100151:	6b c0 74             	imul   $0x74,%eax,%eax
f0100154:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0100159:	39 c3                	cmp    %eax,%ebx
f010015b:	74 39                	je     f0100196 <i386_init+0xee>
f010015d:	89 d8                	mov    %ebx,%eax
f010015f:	2d 20 c0 22 f0       	sub    $0xf022c020,%eax
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100164:	c1 f8 02             	sar    $0x2,%eax
f0100167:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010016d:	c1 e0 0f             	shl    $0xf,%eax
f0100170:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f0100176:	a3 84 be 22 f0       	mov    %eax,0xf022be84
		lapic_startap(c->cpu_id, PADDR(code));
f010017b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f0100182:	00 
f0100183:	0f b6 03             	movzbl (%ebx),%eax
f0100186:	89 04 24             	mov    %eax,(%esp)
f0100189:	e8 36 61 00 00       	call   f01062c4 <lapic_startap>
		while(c->cpu_status != CPU_STARTED)
f010018e:	8b 43 04             	mov    0x4(%ebx),%eax
f0100191:	83 f8 01             	cmp    $0x1,%eax
f0100194:	75 f8                	jne    f010018e <i386_init+0xe6>
	for (c = cpus; c < cpus + ncpu; c++) {
f0100196:	83 c3 74             	add    $0x74,%ebx
f0100199:	6b 05 c4 c3 22 f0 74 	imul   $0x74,0xf022c3c4,%eax
f01001a0:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f01001a5:	39 c3                	cmp    %eax,%ebx
f01001a7:	72 a3                	jb     f010014c <i386_init+0xa4>
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001b0:	00 
f01001b1:	c7 04 24 08 0d 1a f0 	movl   $0xf01a0d08,(%esp)
f01001b8:	e8 24 38 00 00       	call   f01039e1 <env_create>
	sched_yield();
f01001bd:	e8 91 48 00 00       	call   f0104a53 <sched_yield>

f01001c2 <mp_main>:
{
f01001c2:	55                   	push   %ebp
f01001c3:	89 e5                	mov    %esp,%ebp
f01001c5:	83 ec 18             	sub    $0x18,%esp
	lcr3(PADDR(kern_pgdir));
f01001c8:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01001cd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001d2:	77 20                	ja     f01001f4 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001d8:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f01001df:	f0 
f01001e0:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
f01001e7:	00 
f01001e8:	c7 04 24 c9 68 10 f0 	movl   $0xf01068c9,(%esp)
f01001ef:	e8 4c fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01001f4:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001f9:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001fc:	e8 58 5f 00 00       	call   f0106159 <cpunum>
f0100201:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100205:	c7 04 24 d5 68 10 f0 	movl   $0xf01068d5,(%esp)
f010020c:	e8 ea 3d 00 00       	call   f0103ffb <cprintf>
	lapic_init();
f0100211:	e8 5e 5f 00 00       	call   f0106174 <lapic_init>
	env_init_percpu();
f0100216:	e8 5b 35 00 00       	call   f0103776 <env_init_percpu>
	trap_init_percpu();
f010021b:	90                   	nop
f010021c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100220:	e8 fb 3d 00 00       	call   f0104020 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100225:	e8 2f 5f 00 00       	call   f0106159 <cpunum>
f010022a:	6b d0 74             	imul   $0x74,%eax,%edx
f010022d:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100233:	b8 01 00 00 00       	mov    $0x1,%eax
f0100238:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010023c:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f0100243:	e8 8f 61 00 00       	call   f01063d7 <spin_lock>
	sched_yield();
f0100248:	e8 06 48 00 00       	call   f0104a53 <sched_yield>

f010024d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010024d:	55                   	push   %ebp
f010024e:	89 e5                	mov    %esp,%ebp
f0100250:	53                   	push   %ebx
f0100251:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100254:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100257:	8b 45 0c             	mov    0xc(%ebp),%eax
f010025a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010025e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100261:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100265:	c7 04 24 eb 68 10 f0 	movl   $0xf01068eb,(%esp)
f010026c:	e8 8a 3d 00 00       	call   f0103ffb <cprintf>
	vcprintf(fmt, ap);
f0100271:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100275:	8b 45 10             	mov    0x10(%ebp),%eax
f0100278:	89 04 24             	mov    %eax,(%esp)
f010027b:	e8 48 3d 00 00       	call   f0103fc8 <vcprintf>
	cprintf("\n");
f0100280:	c7 04 24 de 7c 10 f0 	movl   $0xf0107cde,(%esp)
f0100287:	e8 6f 3d 00 00       	call   f0103ffb <cprintf>
	va_end(ap);
}
f010028c:	83 c4 14             	add    $0x14,%esp
f010028f:	5b                   	pop    %ebx
f0100290:	5d                   	pop    %ebp
f0100291:	c3                   	ret    
f0100292:	66 90                	xchg   %ax,%ax
f0100294:	66 90                	xchg   %ax,%ax
f0100296:	66 90                	xchg   %ax,%ax
f0100298:	66 90                	xchg   %ax,%ax
f010029a:	66 90                	xchg   %ax,%ax
f010029c:	66 90                	xchg   %ax,%ax
f010029e:	66 90                	xchg   %ax,%ax

f01002a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002a9:	a8 01                	test   $0x1,%al
f01002ab:	74 08                	je     f01002b5 <serial_proc_data+0x15>
f01002ad:	b2 f8                	mov    $0xf8,%dl
f01002af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002b0:	0f b6 c0             	movzbl %al,%eax
f01002b3:	eb 05                	jmp    f01002ba <serial_proc_data+0x1a>
		return -1;
f01002b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01002ba:	5d                   	pop    %ebp
f01002bb:	c3                   	ret    

f01002bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002bc:	55                   	push   %ebp
f01002bd:	89 e5                	mov    %esp,%ebp
f01002bf:	53                   	push   %ebx
f01002c0:	83 ec 04             	sub    $0x4,%esp
f01002c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002c5:	eb 2a                	jmp    f01002f1 <cons_intr+0x35>
		if (c == 0)
f01002c7:	85 d2                	test   %edx,%edx
f01002c9:	74 26                	je     f01002f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002cb:	a1 24 b2 22 f0       	mov    0xf022b224,%eax
f01002d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002d3:	89 0d 24 b2 22 f0    	mov    %ecx,0xf022b224
f01002d9:	88 90 20 b0 22 f0    	mov    %dl,-0xfdd4fe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002e5:	75 0a                	jne    f01002f1 <cons_intr+0x35>
			cons.wpos = 0;
f01002e7:	c7 05 24 b2 22 f0 00 	movl   $0x0,0xf022b224
f01002ee:	00 00 00 
	while ((c = (*proc)()) != -1) {
f01002f1:	ff d3                	call   *%ebx
f01002f3:	89 c2                	mov    %eax,%edx
f01002f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002f8:	75 cd                	jne    f01002c7 <cons_intr+0xb>
	}
}
f01002fa:	83 c4 04             	add    $0x4,%esp
f01002fd:	5b                   	pop    %ebx
f01002fe:	5d                   	pop    %ebp
f01002ff:	c3                   	ret    

f0100300 <kbd_proc_data>:
f0100300:	ba 64 00 00 00       	mov    $0x64,%edx
f0100305:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100306:	a8 01                	test   $0x1,%al
f0100308:	0f 84 f7 00 00 00    	je     f0100405 <kbd_proc_data+0x105>
	if (stat & KBS_TERR)
f010030e:	a8 20                	test   $0x20,%al
f0100310:	0f 85 f5 00 00 00    	jne    f010040b <kbd_proc_data+0x10b>
f0100316:	b2 60                	mov    $0x60,%dl
f0100318:	ec                   	in     (%dx),%al
f0100319:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010031b:	3c e0                	cmp    $0xe0,%al
f010031d:	75 0d                	jne    f010032c <kbd_proc_data+0x2c>
		shift |= E0ESC;
f010031f:	83 0d 00 b0 22 f0 40 	orl    $0x40,0xf022b000
		return 0;
f0100326:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010032b:	c3                   	ret    
{
f010032c:	55                   	push   %ebp
f010032d:	89 e5                	mov    %esp,%ebp
f010032f:	53                   	push   %ebx
f0100330:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
f0100333:	84 c0                	test   %al,%al
f0100335:	79 37                	jns    f010036e <kbd_proc_data+0x6e>
		data = (shift & E0ESC ? data : data & 0x7F);
f0100337:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f010033d:	89 cb                	mov    %ecx,%ebx
f010033f:	83 e3 40             	and    $0x40,%ebx
f0100342:	83 e0 7f             	and    $0x7f,%eax
f0100345:	85 db                	test   %ebx,%ebx
f0100347:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010034a:	0f b6 d2             	movzbl %dl,%edx
f010034d:	0f b6 82 60 6a 10 f0 	movzbl -0xfef95a0(%edx),%eax
f0100354:	83 c8 40             	or     $0x40,%eax
f0100357:	0f b6 c0             	movzbl %al,%eax
f010035a:	f7 d0                	not    %eax
f010035c:	21 c1                	and    %eax,%ecx
f010035e:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
		return 0;
f0100364:	b8 00 00 00 00       	mov    $0x0,%eax
f0100369:	e9 a3 00 00 00       	jmp    f0100411 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010036e:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f0100374:	f6 c1 40             	test   $0x40,%cl
f0100377:	74 0e                	je     f0100387 <kbd_proc_data+0x87>
		data |= 0x80;
f0100379:	83 c8 80             	or     $0xffffff80,%eax
f010037c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010037e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100381:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
	shift |= shiftcode[data];
f0100387:	0f b6 d2             	movzbl %dl,%edx
f010038a:	0f b6 82 60 6a 10 f0 	movzbl -0xfef95a0(%edx),%eax
f0100391:	0b 05 00 b0 22 f0    	or     0xf022b000,%eax
	shift ^= togglecode[data];
f0100397:	0f b6 8a 60 69 10 f0 	movzbl -0xfef96a0(%edx),%ecx
f010039e:	31 c8                	xor    %ecx,%eax
f01003a0:	a3 00 b0 22 f0       	mov    %eax,0xf022b000
	c = charcode[shift & (CTL | SHIFT)][data];
f01003a5:	89 c1                	mov    %eax,%ecx
f01003a7:	83 e1 03             	and    $0x3,%ecx
f01003aa:	8b 0c 8d 40 69 10 f0 	mov    -0xfef96c0(,%ecx,4),%ecx
f01003b1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003b5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003b8:	a8 08                	test   $0x8,%al
f01003ba:	74 1b                	je     f01003d7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01003bc:	89 da                	mov    %ebx,%edx
f01003be:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003c1:	83 f9 19             	cmp    $0x19,%ecx
f01003c4:	77 05                	ja     f01003cb <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01003c6:	83 eb 20             	sub    $0x20,%ebx
f01003c9:	eb 0c                	jmp    f01003d7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01003cb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003ce:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003d1:	83 fa 19             	cmp    $0x19,%edx
f01003d4:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003d7:	f7 d0                	not    %eax
f01003d9:	89 c2                	mov    %eax,%edx
	return c;
f01003db:	89 d8                	mov    %ebx,%eax
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003dd:	f6 c2 06             	test   $0x6,%dl
f01003e0:	75 2f                	jne    f0100411 <kbd_proc_data+0x111>
f01003e2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003e8:	75 27                	jne    f0100411 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01003ea:	c7 04 24 05 69 10 f0 	movl   $0xf0106905,(%esp)
f01003f1:	e8 05 3c 00 00       	call   f0103ffb <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003f6:	ba 92 00 00 00       	mov    $0x92,%edx
f01003fb:	b8 03 00 00 00       	mov    $0x3,%eax
f0100400:	ee                   	out    %al,(%dx)
	return c;
f0100401:	89 d8                	mov    %ebx,%eax
f0100403:	eb 0c                	jmp    f0100411 <kbd_proc_data+0x111>
		return -1;
f0100405:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010040a:	c3                   	ret    
		return -1;
f010040b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100410:	c3                   	ret    
}
f0100411:	83 c4 14             	add    $0x14,%esp
f0100414:	5b                   	pop    %ebx
f0100415:	5d                   	pop    %ebp
f0100416:	c3                   	ret    

f0100417 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100417:	55                   	push   %ebp
f0100418:	89 e5                	mov    %esp,%ebp
f010041a:	57                   	push   %edi
f010041b:	56                   	push   %esi
f010041c:	53                   	push   %ebx
f010041d:	83 ec 1c             	sub    $0x1c,%esp
f0100420:	89 c7                	mov    %eax,%edi
f0100422:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100427:	be fd 03 00 00       	mov    $0x3fd,%esi
f010042c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100431:	eb 06                	jmp    f0100439 <cons_putc+0x22>
f0100433:	89 ca                	mov    %ecx,%edx
f0100435:	ec                   	in     (%dx),%al
f0100436:	ec                   	in     (%dx),%al
f0100437:	ec                   	in     (%dx),%al
f0100438:	ec                   	in     (%dx),%al
f0100439:	89 f2                	mov    %esi,%edx
f010043b:	ec                   	in     (%dx),%al
	for (i = 0;
f010043c:	a8 20                	test   $0x20,%al
f010043e:	75 05                	jne    f0100445 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100440:	83 eb 01             	sub    $0x1,%ebx
f0100443:	75 ee                	jne    f0100433 <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f0100445:	89 f8                	mov    %edi,%eax
f0100447:	0f b6 c0             	movzbl %al,%eax
f010044a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010044d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100452:	ee                   	out    %al,(%dx)
f0100453:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100458:	be 79 03 00 00       	mov    $0x379,%esi
f010045d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100462:	eb 06                	jmp    f010046a <cons_putc+0x53>
f0100464:	89 ca                	mov    %ecx,%edx
f0100466:	ec                   	in     (%dx),%al
f0100467:	ec                   	in     (%dx),%al
f0100468:	ec                   	in     (%dx),%al
f0100469:	ec                   	in     (%dx),%al
f010046a:	89 f2                	mov    %esi,%edx
f010046c:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010046d:	84 c0                	test   %al,%al
f010046f:	78 05                	js     f0100476 <cons_putc+0x5f>
f0100471:	83 eb 01             	sub    $0x1,%ebx
f0100474:	75 ee                	jne    f0100464 <cons_putc+0x4d>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100476:	ba 78 03 00 00       	mov    $0x378,%edx
f010047b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010047f:	ee                   	out    %al,(%dx)
f0100480:	b2 7a                	mov    $0x7a,%dl
f0100482:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100487:	ee                   	out    %al,(%dx)
f0100488:	b8 08 00 00 00       	mov    $0x8,%eax
f010048d:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010048e:	89 fa                	mov    %edi,%edx
f0100490:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100496:	89 f8                	mov    %edi,%eax
f0100498:	80 cc 07             	or     $0x7,%ah
f010049b:	85 d2                	test   %edx,%edx
f010049d:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f01004a0:	89 f8                	mov    %edi,%eax
f01004a2:	0f b6 c0             	movzbl %al,%eax
f01004a5:	83 f8 09             	cmp    $0x9,%eax
f01004a8:	74 78                	je     f0100522 <cons_putc+0x10b>
f01004aa:	83 f8 09             	cmp    $0x9,%eax
f01004ad:	7f 0a                	jg     f01004b9 <cons_putc+0xa2>
f01004af:	83 f8 08             	cmp    $0x8,%eax
f01004b2:	74 18                	je     f01004cc <cons_putc+0xb5>
f01004b4:	e9 9d 00 00 00       	jmp    f0100556 <cons_putc+0x13f>
f01004b9:	83 f8 0a             	cmp    $0xa,%eax
f01004bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01004c0:	74 3a                	je     f01004fc <cons_putc+0xe5>
f01004c2:	83 f8 0d             	cmp    $0xd,%eax
f01004c5:	74 3d                	je     f0100504 <cons_putc+0xed>
f01004c7:	e9 8a 00 00 00       	jmp    f0100556 <cons_putc+0x13f>
		if (crt_pos > 0) {
f01004cc:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f01004d3:	66 85 c0             	test   %ax,%ax
f01004d6:	0f 84 e5 00 00 00    	je     f01005c1 <cons_putc+0x1aa>
			crt_pos--;
f01004dc:	83 e8 01             	sub    $0x1,%eax
f01004df:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004e5:	0f b7 c0             	movzwl %ax,%eax
f01004e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01004ed:	83 cf 20             	or     $0x20,%edi
f01004f0:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f01004f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004fa:	eb 78                	jmp    f0100574 <cons_putc+0x15d>
		crt_pos += CRT_COLS;
f01004fc:	66 83 05 28 b2 22 f0 	addw   $0x50,0xf022b228
f0100503:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f0100504:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f010050b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100511:	c1 e8 16             	shr    $0x16,%eax
f0100514:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100517:	c1 e0 04             	shl    $0x4,%eax
f010051a:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
f0100520:	eb 52                	jmp    f0100574 <cons_putc+0x15d>
		cons_putc(' ');
f0100522:	b8 20 00 00 00       	mov    $0x20,%eax
f0100527:	e8 eb fe ff ff       	call   f0100417 <cons_putc>
		cons_putc(' ');
f010052c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100531:	e8 e1 fe ff ff       	call   f0100417 <cons_putc>
		cons_putc(' ');
f0100536:	b8 20 00 00 00       	mov    $0x20,%eax
f010053b:	e8 d7 fe ff ff       	call   f0100417 <cons_putc>
		cons_putc(' ');
f0100540:	b8 20 00 00 00       	mov    $0x20,%eax
f0100545:	e8 cd fe ff ff       	call   f0100417 <cons_putc>
		cons_putc(' ');
f010054a:	b8 20 00 00 00       	mov    $0x20,%eax
f010054f:	e8 c3 fe ff ff       	call   f0100417 <cons_putc>
f0100554:	eb 1e                	jmp    f0100574 <cons_putc+0x15d>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100556:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f010055d:	8d 50 01             	lea    0x1(%eax),%edx
f0100560:	66 89 15 28 b2 22 f0 	mov    %dx,0xf022b228
f0100567:	0f b7 c0             	movzwl %ax,%eax
f010056a:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f0100570:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
	if (crt_pos >= CRT_SIZE) {
f0100574:	66 81 3d 28 b2 22 f0 	cmpw   $0x7cf,0xf022b228
f010057b:	cf 07 
f010057d:	76 42                	jbe    f01005c1 <cons_putc+0x1aa>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010057f:	a1 2c b2 22 f0       	mov    0xf022b22c,%eax
f0100584:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010058b:	00 
f010058c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100592:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100596:	89 04 24             	mov    %eax,(%esp)
f0100599:	e8 b6 55 00 00       	call   f0105b54 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010059e:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005af:	83 c0 01             	add    $0x1,%eax
f01005b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005b7:	75 f0                	jne    f01005a9 <cons_putc+0x192>
		crt_pos -= CRT_COLS;
f01005b9:	66 83 2d 28 b2 22 f0 	subw   $0x50,0xf022b228
f01005c0:	50 
	outb(addr_6845, 14);
f01005c1:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f01005c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005cc:	89 ca                	mov    %ecx,%edx
f01005ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005cf:	0f b7 1d 28 b2 22 f0 	movzwl 0xf022b228,%ebx
f01005d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005d9:	89 d8                	mov    %ebx,%eax
f01005db:	66 c1 e8 08          	shr    $0x8,%ax
f01005df:	89 f2                	mov    %esi,%edx
f01005e1:	ee                   	out    %al,(%dx)
f01005e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005e7:	89 ca                	mov    %ecx,%edx
f01005e9:	ee                   	out    %al,(%dx)
f01005ea:	89 d8                	mov    %ebx,%eax
f01005ec:	89 f2                	mov    %esi,%edx
f01005ee:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005ef:	83 c4 1c             	add    $0x1c,%esp
f01005f2:	5b                   	pop    %ebx
f01005f3:	5e                   	pop    %esi
f01005f4:	5f                   	pop    %edi
f01005f5:	5d                   	pop    %ebp
f01005f6:	c3                   	ret    

f01005f7 <serial_intr>:
	if (serial_exists)
f01005f7:	80 3d 34 b2 22 f0 00 	cmpb   $0x0,0xf022b234
f01005fe:	74 11                	je     f0100611 <serial_intr+0x1a>
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100606:	b8 a0 02 10 f0       	mov    $0xf01002a0,%eax
f010060b:	e8 ac fc ff ff       	call   f01002bc <cons_intr>
}
f0100610:	c9                   	leave  
f0100611:	f3 c3                	repz ret 

f0100613 <kbd_intr>:
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
f0100616:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100619:	b8 00 03 10 f0       	mov    $0xf0100300,%eax
f010061e:	e8 99 fc ff ff       	call   f01002bc <cons_intr>
}
f0100623:	c9                   	leave  
f0100624:	c3                   	ret    

f0100625 <cons_getc>:
{
f0100625:	55                   	push   %ebp
f0100626:	89 e5                	mov    %esp,%ebp
f0100628:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010062b:	e8 c7 ff ff ff       	call   f01005f7 <serial_intr>
	kbd_intr();
f0100630:	e8 de ff ff ff       	call   f0100613 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100635:	a1 20 b2 22 f0       	mov    0xf022b220,%eax
f010063a:	3b 05 24 b2 22 f0    	cmp    0xf022b224,%eax
f0100640:	74 26                	je     f0100668 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100642:	8d 50 01             	lea    0x1(%eax),%edx
f0100645:	89 15 20 b2 22 f0    	mov    %edx,0xf022b220
f010064b:	0f b6 88 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ecx
		return c;
f0100652:	89 c8                	mov    %ecx,%eax
		if (cons.rpos == CONSBUFSIZE)
f0100654:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010065a:	75 11                	jne    f010066d <cons_getc+0x48>
			cons.rpos = 0;
f010065c:	c7 05 20 b2 22 f0 00 	movl   $0x0,0xf022b220
f0100663:	00 00 00 
f0100666:	eb 05                	jmp    f010066d <cons_getc+0x48>
	return 0;
f0100668:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010066d:	c9                   	leave  
f010066e:	c3                   	ret    

f010066f <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010066f:	55                   	push   %ebp
f0100670:	89 e5                	mov    %esp,%ebp
f0100672:	57                   	push   %edi
f0100673:	56                   	push   %esi
f0100674:	53                   	push   %ebx
f0100675:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100678:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010067f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100686:	5a a5 
	if (*cp != 0xA55A) {
f0100688:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010068f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100693:	74 11                	je     f01006a6 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100695:	c7 05 30 b2 22 f0 b4 	movl   $0x3b4,0xf022b230
f010069c:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010069f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006a4:	eb 16                	jmp    f01006bc <cons_init+0x4d>
		*cp = was;
f01006a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006ad:	c7 05 30 b2 22 f0 d4 	movl   $0x3d4,0xf022b230
f01006b4:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f01006bc:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f01006c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006c7:	89 ca                	mov    %ecx,%edx
f01006c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006ca:	8d 59 01             	lea    0x1(%ecx),%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006cd:	89 da                	mov    %ebx,%edx
f01006cf:	ec                   	in     (%dx),%al
f01006d0:	0f b6 f0             	movzbl %al,%esi
f01006d3:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006db:	89 ca                	mov    %ecx,%edx
f01006dd:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006de:	89 da                	mov    %ebx,%edx
f01006e0:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01006e1:	89 3d 2c b2 22 f0    	mov    %edi,0xf022b22c
	pos |= inb(addr_6845 + 1);
f01006e7:	0f b6 d8             	movzbl %al,%ebx
f01006ea:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f01006ec:	66 89 35 28 b2 22 f0 	mov    %si,0xf022b228
	kbd_intr();
f01006f3:	e8 1b ff ff ff       	call   f0100613 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006f8:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01006ff:	25 fd ff 00 00       	and    $0xfffd,%eax
f0100704:	89 04 24             	mov    %eax,(%esp)
f0100707:	e8 b0 37 00 00       	call   f0103ebc <irq_setmask_8259A>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010070c:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100711:	b8 00 00 00 00       	mov    $0x0,%eax
f0100716:	89 f2                	mov    %esi,%edx
f0100718:	ee                   	out    %al,(%dx)
f0100719:	b2 fb                	mov    $0xfb,%dl
f010071b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100720:	ee                   	out    %al,(%dx)
f0100721:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100726:	b8 0c 00 00 00       	mov    $0xc,%eax
f010072b:	89 da                	mov    %ebx,%edx
f010072d:	ee                   	out    %al,(%dx)
f010072e:	b2 f9                	mov    $0xf9,%dl
f0100730:	b8 00 00 00 00       	mov    $0x0,%eax
f0100735:	ee                   	out    %al,(%dx)
f0100736:	b2 fb                	mov    $0xfb,%dl
f0100738:	b8 03 00 00 00       	mov    $0x3,%eax
f010073d:	ee                   	out    %al,(%dx)
f010073e:	b2 fc                	mov    $0xfc,%dl
f0100740:	b8 00 00 00 00       	mov    $0x0,%eax
f0100745:	ee                   	out    %al,(%dx)
f0100746:	b2 f9                	mov    $0xf9,%dl
f0100748:	b8 01 00 00 00       	mov    $0x1,%eax
f010074d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010074e:	b2 fd                	mov    $0xfd,%dl
f0100750:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100751:	3c ff                	cmp    $0xff,%al
f0100753:	0f 95 c1             	setne  %cl
f0100756:	88 0d 34 b2 22 f0    	mov    %cl,0xf022b234
f010075c:	89 f2                	mov    %esi,%edx
f010075e:	ec                   	in     (%dx),%al
f010075f:	89 da                	mov    %ebx,%edx
f0100761:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100762:	84 c9                	test   %cl,%cl
f0100764:	75 0c                	jne    f0100772 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100766:	c7 04 24 11 69 10 f0 	movl   $0xf0106911,(%esp)
f010076d:	e8 89 38 00 00       	call   f0103ffb <cprintf>
}
f0100772:	83 c4 1c             	add    $0x1c,%esp
f0100775:	5b                   	pop    %ebx
f0100776:	5e                   	pop    %esi
f0100777:	5f                   	pop    %edi
f0100778:	5d                   	pop    %ebp
f0100779:	c3                   	ret    

f010077a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010077a:	55                   	push   %ebp
f010077b:	89 e5                	mov    %esp,%ebp
f010077d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100780:	8b 45 08             	mov    0x8(%ebp),%eax
f0100783:	e8 8f fc ff ff       	call   f0100417 <cons_putc>
}
f0100788:	c9                   	leave  
f0100789:	c3                   	ret    

f010078a <getchar>:

int
getchar(void)
{
f010078a:	55                   	push   %ebp
f010078b:	89 e5                	mov    %esp,%ebp
f010078d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100790:	e8 90 fe ff ff       	call   f0100625 <cons_getc>
f0100795:	85 c0                	test   %eax,%eax
f0100797:	74 f7                	je     f0100790 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100799:	c9                   	leave  
f010079a:	c3                   	ret    

f010079b <iscons>:

int
iscons(int fdnum)
{
f010079b:	55                   	push   %ebp
f010079c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010079e:	b8 01 00 00 00       	mov    $0x1,%eax
f01007a3:	5d                   	pop    %ebp
f01007a4:	c3                   	ret    
f01007a5:	66 90                	xchg   %ax,%ax
f01007a7:	66 90                	xchg   %ax,%ax
f01007a9:	66 90                	xchg   %ax,%ax
f01007ab:	66 90                	xchg   %ax,%ax
f01007ad:	66 90                	xchg   %ax,%ax
f01007af:	90                   	nop

f01007b0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007b0:	55                   	push   %ebp
f01007b1:	89 e5                	mov    %esp,%ebp
f01007b3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007b6:	c7 44 24 08 60 6b 10 	movl   $0xf0106b60,0x8(%esp)
f01007bd:	f0 
f01007be:	c7 44 24 04 7e 6b 10 	movl   $0xf0106b7e,0x4(%esp)
f01007c5:	f0 
f01007c6:	c7 04 24 83 6b 10 f0 	movl   $0xf0106b83,(%esp)
f01007cd:	e8 29 38 00 00       	call   f0103ffb <cprintf>
f01007d2:	c7 44 24 08 3c 6c 10 	movl   $0xf0106c3c,0x8(%esp)
f01007d9:	f0 
f01007da:	c7 44 24 04 8c 6b 10 	movl   $0xf0106b8c,0x4(%esp)
f01007e1:	f0 
f01007e2:	c7 04 24 83 6b 10 f0 	movl   $0xf0106b83,(%esp)
f01007e9:	e8 0d 38 00 00       	call   f0103ffb <cprintf>
f01007ee:	c7 44 24 08 64 6c 10 	movl   $0xf0106c64,0x8(%esp)
f01007f5:	f0 
f01007f6:	c7 44 24 04 95 6b 10 	movl   $0xf0106b95,0x4(%esp)
f01007fd:	f0 
f01007fe:	c7 04 24 83 6b 10 f0 	movl   $0xf0106b83,(%esp)
f0100805:	e8 f1 37 00 00       	call   f0103ffb <cprintf>
	return 0;
}
f010080a:	b8 00 00 00 00       	mov    $0x0,%eax
f010080f:	c9                   	leave  
f0100810:	c3                   	ret    

f0100811 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100811:	55                   	push   %ebp
f0100812:	89 e5                	mov    %esp,%ebp
f0100814:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100817:	c7 04 24 9f 6b 10 f0 	movl   $0xf0106b9f,(%esp)
f010081e:	e8 d8 37 00 00       	call   f0103ffb <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100823:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010082a:	00 
f010082b:	c7 04 24 88 6c 10 f0 	movl   $0xf0106c88,(%esp)
f0100832:	e8 c4 37 00 00       	call   f0103ffb <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100837:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010083e:	00 
f010083f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100846:	f0 
f0100847:	c7 04 24 b0 6c 10 f0 	movl   $0xf0106cb0,(%esp)
f010084e:	e8 a8 37 00 00       	call   f0103ffb <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100853:	c7 44 24 08 27 68 10 	movl   $0x106827,0x8(%esp)
f010085a:	00 
f010085b:	c7 44 24 04 27 68 10 	movl   $0xf0106827,0x4(%esp)
f0100862:	f0 
f0100863:	c7 04 24 d4 6c 10 f0 	movl   $0xf0106cd4,(%esp)
f010086a:	e8 8c 37 00 00       	call   f0103ffb <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010086f:	c7 44 24 08 00 b0 22 	movl   $0x22b000,0x8(%esp)
f0100876:	00 
f0100877:	c7 44 24 04 00 b0 22 	movl   $0xf022b000,0x4(%esp)
f010087e:	f0 
f010087f:	c7 04 24 f8 6c 10 f0 	movl   $0xf0106cf8,(%esp)
f0100886:	e8 70 37 00 00       	call   f0103ffb <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010088b:	c7 44 24 08 08 d0 26 	movl   $0x26d008,0x8(%esp)
f0100892:	00 
f0100893:	c7 44 24 04 08 d0 26 	movl   $0xf026d008,0x4(%esp)
f010089a:	f0 
f010089b:	c7 04 24 1c 6d 10 f0 	movl   $0xf0106d1c,(%esp)
f01008a2:	e8 54 37 00 00       	call   f0103ffb <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008a7:	b8 07 d4 26 f0       	mov    $0xf026d407,%eax
f01008ac:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008b1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008b6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008bc:	85 c0                	test   %eax,%eax
f01008be:	0f 48 c2             	cmovs  %edx,%eax
f01008c1:	c1 f8 0a             	sar    $0xa,%eax
f01008c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c8:	c7 04 24 40 6d 10 f0 	movl   $0xf0106d40,(%esp)
f01008cf:	e8 27 37 00 00       	call   f0103ffb <cprintf>
	return 0;
}
f01008d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008d9:	c9                   	leave  
f01008da:	c3                   	ret    

f01008db <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008db:	55                   	push   %ebp
f01008dc:	89 e5                	mov    %esp,%ebp
f01008de:	56                   	push   %esi
f01008df:	53                   	push   %ebx
f01008e0:	83 ec 30             	sub    $0x30,%esp
	// LAB 1: Your code here.
    // HINT 1: use read_ebp().
    // HINT 2: print the current ebp on the first line (not current_ebp[0])
    
    uint32_t ebp = read_ebp();
    uint32_t * p = (uint32_t*)ebp;
f01008e3:	89 eb                	mov    %ebp,%ebx
    struct Eipdebuginfo debug = {NULL};
f01008e5:	b9 00 00 00 00       	mov    $0x0,%ecx
f01008ea:	ba 18 00 00 00       	mov    $0x18,%edx
f01008ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f4:	89 4c 05 e0          	mov    %ecx,-0x20(%ebp,%eax,1)
f01008f8:	83 c0 04             	add    $0x4,%eax
f01008fb:	39 d0                	cmp    %edx,%eax
f01008fd:	72 f5                	jb     f01008f4 <mon_backtrace+0x19>
    cprintf("Stack backtrace:\n");
f01008ff:	c7 04 24 b8 6b 10 f0 	movl   $0xf0106bb8,(%esp)
f0100906:	e8 f0 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x ", p[3]);
    cprintf("%08x ", p[4]);
    cprintf("%08x ", p[5]);
    cprintf("%08x \n", p[6]);
    // Start getting our debug info, pass the address of our struct in along with the EIP.
    debuginfo_eip(p[1], &debug);
f010090b:	8d 75 e0             	lea    -0x20(%ebp),%esi
    while (p != 0) {
f010090e:	e9 01 01 00 00       	jmp    f0100a14 <mon_backtrace+0x139>
    cprintf("ebp ");
f0100913:	c7 04 24 ca 6b 10 f0 	movl   $0xf0106bca,(%esp)
f010091a:	e8 dc 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x " , p);
f010091f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100923:	c7 04 24 cf 6b 10 f0 	movl   $0xf0106bcf,(%esp)
f010092a:	e8 cc 36 00 00       	call   f0103ffb <cprintf>
    cprintf("eip ");
f010092f:	c7 04 24 d5 6b 10 f0 	movl   $0xf0106bd5,(%esp)
f0100936:	e8 c0 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x ", p[1]);
f010093b:	8b 43 04             	mov    0x4(%ebx),%eax
f010093e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100942:	c7 04 24 cf 6b 10 f0 	movl   $0xf0106bcf,(%esp)
f0100949:	e8 ad 36 00 00       	call   f0103ffb <cprintf>
    cprintf("args ");
f010094e:	c7 04 24 da 6b 10 f0 	movl   $0xf0106bda,(%esp)
f0100955:	e8 a1 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x ", p[2]);
f010095a:	8b 43 08             	mov    0x8(%ebx),%eax
f010095d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100961:	c7 04 24 cf 6b 10 f0 	movl   $0xf0106bcf,(%esp)
f0100968:	e8 8e 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x ", p[3]);
f010096d:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100970:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100974:	c7 04 24 cf 6b 10 f0 	movl   $0xf0106bcf,(%esp)
f010097b:	e8 7b 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x ", p[4]);
f0100980:	8b 43 10             	mov    0x10(%ebx),%eax
f0100983:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100987:	c7 04 24 cf 6b 10 f0 	movl   $0xf0106bcf,(%esp)
f010098e:	e8 68 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x ", p[5]);
f0100993:	8b 43 14             	mov    0x14(%ebx),%eax
f0100996:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099a:	c7 04 24 cf 6b 10 f0 	movl   $0xf0106bcf,(%esp)
f01009a1:	e8 55 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%08x \n", p[6]);
f01009a6:	8b 43 18             	mov    0x18(%ebx),%eax
f01009a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ad:	c7 04 24 e0 6b 10 f0 	movl   $0xf0106be0,(%esp)
f01009b4:	e8 42 36 00 00       	call   f0103ffb <cprintf>
    debuginfo_eip(p[1], &debug);
f01009b9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01009bd:	8b 43 04             	mov    0x4(%ebx),%eax
f01009c0:	89 04 24             	mov    %eax,(%esp)
f01009c3:	e8 ff 45 00 00       	call   f0104fc7 <debuginfo_eip>
    cprintf("    %s:%d: ", debug.eip_file, debug.eip_line);
f01009c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009cb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009d6:	c7 04 24 e7 6b 10 f0 	movl   $0xf0106be7,(%esp)
f01009dd:	e8 19 36 00 00       	call   f0103ffb <cprintf>
    cprintf("%.*s", debug.eip_fn_namelen, debug.eip_fn_name);
f01009e2:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01009e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009ec:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009f0:	c7 04 24 f3 6b 10 f0 	movl   $0xf0106bf3,(%esp)
f01009f7:	e8 ff 35 00 00       	call   f0103ffb <cprintf>
    // Calculate the offset and print it by subtracting the current ebp from the next ebp.
    cprintf("+%d \n", p[1] - debug.eip_fn_addr);
f01009fc:	8b 43 04             	mov    0x4(%ebx),%eax
f01009ff:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100a02:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a06:	c7 04 24 f8 6b 10 f0 	movl   $0xf0106bf8,(%esp)
f0100a0d:	e8 e9 35 00 00       	call   f0103ffb <cprintf>
    
    
    p = (uint32_t*) p[0];
f0100a12:	8b 1b                	mov    (%ebx),%ebx
    while (p != 0) {
f0100a14:	85 db                	test   %ebx,%ebx
f0100a16:	0f 85 f7 fe ff ff    	jne    f0100913 <mon_backtrace+0x38>
    // Once we hit 0, we know we're at the top of the stack and can stop backtracing.
    
    
    }
	return 0;
}
f0100a1c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a21:	83 c4 30             	add    $0x30,%esp
f0100a24:	5b                   	pop    %ebx
f0100a25:	5e                   	pop    %esi
f0100a26:	5d                   	pop    %ebp
f0100a27:	c3                   	ret    

f0100a28 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100a28:	55                   	push   %ebp
f0100a29:	89 e5                	mov    %esp,%ebp
f0100a2b:	57                   	push   %edi
f0100a2c:	56                   	push   %esi
f0100a2d:	53                   	push   %ebx
f0100a2e:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a31:	c7 04 24 6c 6d 10 f0 	movl   $0xf0106d6c,(%esp)
f0100a38:	e8 be 35 00 00       	call   f0103ffb <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a3d:	c7 04 24 90 6d 10 f0 	movl   $0xf0106d90,(%esp)
f0100a44:	e8 b2 35 00 00       	call   f0103ffb <cprintf>

	if (tf != NULL)
f0100a49:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100a4d:	74 0b                	je     f0100a5a <monitor+0x32>
		print_trapframe(tf);
f0100a4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a52:	89 04 24             	mov    %eax,(%esp)
f0100a55:	e8 8c 3a 00 00       	call   f01044e6 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a5a:	c7 04 24 fe 6b 10 f0 	movl   $0xf0106bfe,(%esp)
f0100a61:	e8 4a 4e 00 00       	call   f01058b0 <readline>
f0100a66:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100a68:	85 c0                	test   %eax,%eax
f0100a6a:	74 ee                	je     f0100a5a <monitor+0x32>
	argv[argc] = 0;
f0100a6c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a73:	be 00 00 00 00       	mov    $0x0,%esi
f0100a78:	eb 0a                	jmp    f0100a84 <monitor+0x5c>
			*buf++ = 0;
f0100a7a:	c6 03 00             	movb   $0x0,(%ebx)
f0100a7d:	89 f7                	mov    %esi,%edi
f0100a7f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100a82:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100a84:	0f b6 03             	movzbl (%ebx),%eax
f0100a87:	84 c0                	test   %al,%al
f0100a89:	74 63                	je     f0100aee <monitor+0xc6>
f0100a8b:	0f be c0             	movsbl %al,%eax
f0100a8e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a92:	c7 04 24 02 6c 10 f0 	movl   $0xf0106c02,(%esp)
f0100a99:	e8 2c 50 00 00       	call   f0105aca <strchr>
f0100a9e:	85 c0                	test   %eax,%eax
f0100aa0:	75 d8                	jne    f0100a7a <monitor+0x52>
		if (*buf == 0)
f0100aa2:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100aa5:	74 47                	je     f0100aee <monitor+0xc6>
		if (argc == MAXARGS-1) {
f0100aa7:	83 fe 0f             	cmp    $0xf,%esi
f0100aaa:	75 16                	jne    f0100ac2 <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100aac:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100ab3:	00 
f0100ab4:	c7 04 24 07 6c 10 f0 	movl   $0xf0106c07,(%esp)
f0100abb:	e8 3b 35 00 00       	call   f0103ffb <cprintf>
f0100ac0:	eb 98                	jmp    f0100a5a <monitor+0x32>
		argv[argc++] = buf;
f0100ac2:	8d 7e 01             	lea    0x1(%esi),%edi
f0100ac5:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100ac9:	eb 03                	jmp    f0100ace <monitor+0xa6>
			buf++;
f0100acb:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100ace:	0f b6 03             	movzbl (%ebx),%eax
f0100ad1:	84 c0                	test   %al,%al
f0100ad3:	74 ad                	je     f0100a82 <monitor+0x5a>
f0100ad5:	0f be c0             	movsbl %al,%eax
f0100ad8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100adc:	c7 04 24 02 6c 10 f0 	movl   $0xf0106c02,(%esp)
f0100ae3:	e8 e2 4f 00 00       	call   f0105aca <strchr>
f0100ae8:	85 c0                	test   %eax,%eax
f0100aea:	74 df                	je     f0100acb <monitor+0xa3>
f0100aec:	eb 94                	jmp    f0100a82 <monitor+0x5a>
	argv[argc] = 0;
f0100aee:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100af5:	00 
	if (argc == 0)
f0100af6:	85 f6                	test   %esi,%esi
f0100af8:	0f 84 5c ff ff ff    	je     f0100a5a <monitor+0x32>
f0100afe:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100b03:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b06:	8b 04 85 c0 6d 10 f0 	mov    -0xfef9240(,%eax,4),%eax
f0100b0d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b11:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b14:	89 04 24             	mov    %eax,(%esp)
f0100b17:	e8 50 4f 00 00       	call   f0105a6c <strcmp>
f0100b1c:	85 c0                	test   %eax,%eax
f0100b1e:	75 24                	jne    f0100b44 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100b20:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100b23:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b26:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b2a:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100b2d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100b31:	89 34 24             	mov    %esi,(%esp)
f0100b34:	ff 14 85 c8 6d 10 f0 	call   *-0xfef9238(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100b3b:	85 c0                	test   %eax,%eax
f0100b3d:	78 25                	js     f0100b64 <monitor+0x13c>
f0100b3f:	e9 16 ff ff ff       	jmp    f0100a5a <monitor+0x32>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100b44:	83 c3 01             	add    $0x1,%ebx
f0100b47:	83 fb 03             	cmp    $0x3,%ebx
f0100b4a:	75 b7                	jne    f0100b03 <monitor+0xdb>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b4c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b4f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b53:	c7 04 24 24 6c 10 f0 	movl   $0xf0106c24,(%esp)
f0100b5a:	e8 9c 34 00 00       	call   f0103ffb <cprintf>
f0100b5f:	e9 f6 fe ff ff       	jmp    f0100a5a <monitor+0x32>
				break;
	}
}
f0100b64:	83 c4 5c             	add    $0x5c,%esp
f0100b67:	5b                   	pop    %ebx
f0100b68:	5e                   	pop    %esi
f0100b69:	5f                   	pop    %edi
f0100b6a:	5d                   	pop    %ebp
f0100b6b:	c3                   	ret    
f0100b6c:	66 90                	xchg   %ax,%ax
f0100b6e:	66 90                	xchg   %ax,%ax

f0100b70 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100b70:	55                   	push   %ebp
f0100b71:	89 e5                	mov    %esp,%ebp
f0100b73:	56                   	push   %esi
f0100b74:	53                   	push   %ebx
f0100b75:	83 ec 10             	sub    $0x10,%esp
f0100b78:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b7a:	89 04 24             	mov    %eax,(%esp)
f0100b7d:	e8 10 33 00 00       	call   f0103e92 <mc146818_read>
f0100b82:	89 c6                	mov    %eax,%esi
f0100b84:	83 c3 01             	add    $0x1,%ebx
f0100b87:	89 1c 24             	mov    %ebx,(%esp)
f0100b8a:	e8 03 33 00 00       	call   f0103e92 <mc146818_read>
f0100b8f:	c1 e0 08             	shl    $0x8,%eax
f0100b92:	09 f0                	or     %esi,%eax
}
f0100b94:	83 c4 10             	add    $0x10,%esp
f0100b97:	5b                   	pop    %ebx
f0100b98:	5e                   	pop    %esi
f0100b99:	5d                   	pop    %ebp
f0100b9a:	c3                   	ret    

f0100b9b <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b9b:	55                   	push   %ebp
f0100b9c:	89 e5                	mov    %esp,%ebp
f0100b9e:	53                   	push   %ebx
f0100b9f:	83 ec 14             	sub    $0x14,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ba2:	83 3d 38 b2 22 f0 00 	cmpl   $0x0,0xf022b238
f0100ba9:	75 11                	jne    f0100bbc <boot_alloc+0x21>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100bab:	ba 07 e0 26 f0       	mov    $0xf026e007,%edx
f0100bb0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bb6:	89 15 38 b2 22 f0    	mov    %edx,0xf022b238

	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	result = nextfree;
f0100bbc:	8b 0d 38 b2 22 f0    	mov    0xf022b238,%ecx
  
  
  nextfree = ROUNDUP(result+n, PGSIZE); // Determine what the next free address is.
f0100bc2:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100bc9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bcf:	89 15 38 b2 22 f0    	mov    %edx,0xf022b238
  if ((uintptr_t) nextfree >= KERNBASE + (npages * PGSIZE))  { // Check to see if we've run out of memory
f0100bd5:	8b 1d 88 be 22 f0    	mov    0xf022be88,%ebx
f0100bdb:	81 c3 00 00 0f 00    	add    $0xf0000,%ebx
f0100be1:	c1 e3 0c             	shl    $0xc,%ebx
f0100be4:	39 da                	cmp    %ebx,%edx
f0100be6:	72 20                	jb     f0100c08 <boot_alloc+0x6d>
  
  panic("boot_alloc has failed to allocate %d bytes of memory.", n);
f0100be8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bec:	c7 44 24 08 e4 6d 10 	movl   $0xf0106de4,0x8(%esp)
f0100bf3:	f0 
f0100bf4:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
f0100bfb:	00 
f0100bfc:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100c03:	e8 38 f4 ff ff       	call   f0100040 <_panic>

  }

	return result;
 
}
f0100c08:	89 c8                	mov    %ecx,%eax
f0100c0a:	83 c4 14             	add    $0x14,%esp
f0100c0d:	5b                   	pop    %ebx
f0100c0e:	5d                   	pop    %ebp
f0100c0f:	c3                   	ret    

f0100c10 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c10:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0100c16:	c1 f8 03             	sar    $0x3,%eax
f0100c19:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100c1c:	89 c2                	mov    %eax,%edx
f0100c1e:	c1 ea 0c             	shr    $0xc,%edx
f0100c21:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0100c27:	72 26                	jb     f0100c4f <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100c29:	55                   	push   %ebp
f0100c2a:	89 e5                	mov    %esp,%ebp
f0100c2c:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c33:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0100c3a:	f0 
f0100c3b:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100c42:	00 
f0100c43:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f0100c4a:	e8 f1 f3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100c4f:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100c54:	c3                   	ret    

f0100c55 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100c55:	89 d1                	mov    %edx,%ecx
f0100c57:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100c5a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100c5d:	a8 01                	test   $0x1,%al
f0100c5f:	74 5d                	je     f0100cbe <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c61:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100c66:	89 c1                	mov    %eax,%ecx
f0100c68:	c1 e9 0c             	shr    $0xc,%ecx
f0100c6b:	3b 0d 88 be 22 f0    	cmp    0xf022be88,%ecx
f0100c71:	72 26                	jb     f0100c99 <check_va2pa+0x44>
{
f0100c73:	55                   	push   %ebp
f0100c74:	89 e5                	mov    %esp,%ebp
f0100c76:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c79:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c7d:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0100c84:	f0 
f0100c85:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f0100c8c:	00 
f0100c8d:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100c94:	e8 a7 f3 ff ff       	call   f0100040 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100c99:	c1 ea 0c             	shr    $0xc,%edx
f0100c9c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ca2:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100ca9:	89 c2                	mov    %eax,%edx
f0100cab:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100cae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cb3:	85 d2                	test   %edx,%edx
f0100cb5:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100cba:	0f 44 c2             	cmove  %edx,%eax
f0100cbd:	c3                   	ret    
		return ~0;
f0100cbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100cc3:	c3                   	ret    

f0100cc4 <check_page_free_list>:
{
f0100cc4:	55                   	push   %ebp
f0100cc5:	89 e5                	mov    %esp,%ebp
f0100cc7:	57                   	push   %edi
f0100cc8:	56                   	push   %esi
f0100cc9:	53                   	push   %ebx
f0100cca:	83 ec 4c             	sub    $0x4c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ccd:	84 c0                	test   %al,%al
f0100ccf:	0f 85 3f 03 00 00    	jne    f0101014 <check_page_free_list+0x350>
f0100cd5:	e9 4c 03 00 00       	jmp    f0101026 <check_page_free_list+0x362>
		panic("'page_free_list' is a null pointer!");
f0100cda:	c7 44 24 08 1c 6e 10 	movl   $0xf0106e1c,0x8(%esp)
f0100ce1:	f0 
f0100ce2:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0100ce9:	00 
f0100cea:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100cf1:	e8 4a f3 ff ff       	call   f0100040 <_panic>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100cf6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100cf9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100cfc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cff:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100d02:	89 c2                	mov    %eax,%edx
f0100d04:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d0a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100d10:	0f 95 c2             	setne  %dl
f0100d13:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100d16:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100d1a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100d1c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d20:	8b 00                	mov    (%eax),%eax
f0100d22:	85 c0                	test   %eax,%eax
f0100d24:	75 dc                	jne    f0100d02 <check_page_free_list+0x3e>
		*tp[1] = 0;
f0100d26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d29:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d2f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d32:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d35:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d37:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d3a:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d3f:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d44:	8b 1d 40 b2 22 f0    	mov    0xf022b240,%ebx
f0100d4a:	eb 63                	jmp    f0100daf <check_page_free_list+0xeb>
f0100d4c:	89 d8                	mov    %ebx,%eax
f0100d4e:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0100d54:	c1 f8 03             	sar    $0x3,%eax
f0100d57:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d5a:	89 c2                	mov    %eax,%edx
f0100d5c:	c1 ea 16             	shr    $0x16,%edx
f0100d5f:	39 f2                	cmp    %esi,%edx
f0100d61:	73 4a                	jae    f0100dad <check_page_free_list+0xe9>
	if (PGNUM(pa) >= npages)
f0100d63:	89 c2                	mov    %eax,%edx
f0100d65:	c1 ea 0c             	shr    $0xc,%edx
f0100d68:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0100d6e:	72 20                	jb     f0100d90 <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d70:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d74:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0100d7b:	f0 
f0100d7c:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100d83:	00 
f0100d84:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f0100d8b:	e8 b0 f2 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d90:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d97:	00 
f0100d98:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d9f:	00 
	return (void *)(pa + KERNBASE);
f0100da0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100da5:	89 04 24             	mov    %eax,(%esp)
f0100da8:	e8 5a 4d 00 00       	call   f0105b07 <memset>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dad:	8b 1b                	mov    (%ebx),%ebx
f0100daf:	85 db                	test   %ebx,%ebx
f0100db1:	75 99                	jne    f0100d4c <check_page_free_list+0x88>
	first_free_page = (char *) boot_alloc(0);
f0100db3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100db8:	e8 de fd ff ff       	call   f0100b9b <boot_alloc>
f0100dbd:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dc0:	8b 15 40 b2 22 f0    	mov    0xf022b240,%edx
		assert(pp >= pages);
f0100dc6:	8b 0d 90 be 22 f0    	mov    0xf022be90,%ecx
		assert(pp < pages + npages);
f0100dcc:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0100dd1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100dd4:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100dd7:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dda:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ddd:	bf 00 00 00 00       	mov    $0x0,%edi
f0100de2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100de5:	e9 c4 01 00 00       	jmp    f0100fae <check_page_free_list+0x2ea>
		assert(pp >= pages);
f0100dea:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100ded:	73 24                	jae    f0100e13 <check_page_free_list+0x14f>
f0100def:	c7 44 24 0c c3 77 10 	movl   $0xf01077c3,0xc(%esp)
f0100df6:	f0 
f0100df7:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100dfe:	f0 
f0100dff:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0100e06:	00 
f0100e07:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100e0e:	e8 2d f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100e13:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100e16:	72 24                	jb     f0100e3c <check_page_free_list+0x178>
f0100e18:	c7 44 24 0c e4 77 10 	movl   $0xf01077e4,0xc(%esp)
f0100e1f:	f0 
f0100e20:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100e27:	f0 
f0100e28:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0100e2f:	00 
f0100e30:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100e37:	e8 04 f2 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e3c:	89 d0                	mov    %edx,%eax
f0100e3e:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100e41:	a8 07                	test   $0x7,%al
f0100e43:	74 24                	je     f0100e69 <check_page_free_list+0x1a5>
f0100e45:	c7 44 24 0c 40 6e 10 	movl   $0xf0106e40,0xc(%esp)
f0100e4c:	f0 
f0100e4d:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100e54:	f0 
f0100e55:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0100e5c:	00 
f0100e5d:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100e64:	e8 d7 f1 ff ff       	call   f0100040 <_panic>
	return (pp - pages) << PGSHIFT;
f0100e69:	c1 f8 03             	sar    $0x3,%eax
f0100e6c:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100e6f:	85 c0                	test   %eax,%eax
f0100e71:	75 24                	jne    f0100e97 <check_page_free_list+0x1d3>
f0100e73:	c7 44 24 0c f8 77 10 	movl   $0xf01077f8,0xc(%esp)
f0100e7a:	f0 
f0100e7b:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100e82:	f0 
f0100e83:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0100e8a:	00 
f0100e8b:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100e92:	e8 a9 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e97:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e9c:	75 24                	jne    f0100ec2 <check_page_free_list+0x1fe>
f0100e9e:	c7 44 24 0c 09 78 10 	movl   $0xf0107809,0xc(%esp)
f0100ea5:	f0 
f0100ea6:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100ead:	f0 
f0100eae:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0100eb5:	00 
f0100eb6:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100ebd:	e8 7e f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ec2:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ec7:	75 24                	jne    f0100eed <check_page_free_list+0x229>
f0100ec9:	c7 44 24 0c 74 6e 10 	movl   $0xf0106e74,0xc(%esp)
f0100ed0:	f0 
f0100ed1:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100ed8:	f0 
f0100ed9:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0100ee0:	00 
f0100ee1:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100ee8:	e8 53 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100eed:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ef2:	75 24                	jne    f0100f18 <check_page_free_list+0x254>
f0100ef4:	c7 44 24 0c 22 78 10 	movl   $0xf0107822,0xc(%esp)
f0100efb:	f0 
f0100efc:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100f03:	f0 
f0100f04:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0100f0b:	00 
f0100f0c:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100f13:	e8 28 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f18:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f1d:	0f 86 2a 01 00 00    	jbe    f010104d <check_page_free_list+0x389>
	if (PGNUM(pa) >= npages)
f0100f23:	89 c1                	mov    %eax,%ecx
f0100f25:	c1 e9 0c             	shr    $0xc,%ecx
f0100f28:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100f2b:	77 20                	ja     f0100f4d <check_page_free_list+0x289>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f2d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f31:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0100f38:	f0 
f0100f39:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100f40:	00 
f0100f41:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f0100f48:	e8 f3 f0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100f4d:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100f53:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100f56:	0f 86 e1 00 00 00    	jbe    f010103d <check_page_free_list+0x379>
f0100f5c:	c7 44 24 0c 98 6e 10 	movl   $0xf0106e98,0xc(%esp)
f0100f63:	f0 
f0100f64:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100f6b:	f0 
f0100f6c:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0100f73:	00 
f0100f74:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100f7b:	e8 c0 f0 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100f80:	c7 44 24 0c 3c 78 10 	movl   $0xf010783c,0xc(%esp)
f0100f87:	f0 
f0100f88:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100f8f:	f0 
f0100f90:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0100f97:	00 
f0100f98:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100f9f:	e8 9c f0 ff ff       	call   f0100040 <_panic>
			++nfree_basemem;
f0100fa4:	83 c3 01             	add    $0x1,%ebx
f0100fa7:	eb 03                	jmp    f0100fac <check_page_free_list+0x2e8>
			++nfree_extmem;
f0100fa9:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fac:	8b 12                	mov    (%edx),%edx
f0100fae:	85 d2                	test   %edx,%edx
f0100fb0:	0f 85 34 fe ff ff    	jne    f0100dea <check_page_free_list+0x126>
	assert(nfree_basemem > 0);
f0100fb6:	85 db                	test   %ebx,%ebx
f0100fb8:	7f 24                	jg     f0100fde <check_page_free_list+0x31a>
f0100fba:	c7 44 24 0c 59 78 10 	movl   $0xf0107859,0xc(%esp)
f0100fc1:	f0 
f0100fc2:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100fc9:	f0 
f0100fca:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0100fd1:	00 
f0100fd2:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0100fd9:	e8 62 f0 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100fde:	85 ff                	test   %edi,%edi
f0100fe0:	7f 24                	jg     f0101006 <check_page_free_list+0x342>
f0100fe2:	c7 44 24 0c 6b 78 10 	movl   $0xf010786b,0xc(%esp)
f0100fe9:	f0 
f0100fea:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0100ff1:	f0 
f0100ff2:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0100ff9:	00 
f0100ffa:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101001:	e8 3a f0 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list() succeeded!\n");
f0101006:	c7 04 24 e0 6e 10 f0 	movl   $0xf0106ee0,(%esp)
f010100d:	e8 e9 2f 00 00       	call   f0103ffb <cprintf>
f0101012:	eb 49                	jmp    f010105d <check_page_free_list+0x399>
	if (!page_free_list)
f0101014:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f0101019:	85 c0                	test   %eax,%eax
f010101b:	0f 85 d5 fc ff ff    	jne    f0100cf6 <check_page_free_list+0x32>
f0101021:	e9 b4 fc ff ff       	jmp    f0100cda <check_page_free_list+0x16>
f0101026:	83 3d 40 b2 22 f0 00 	cmpl   $0x0,0xf022b240
f010102d:	0f 84 a7 fc ff ff    	je     f0100cda <check_page_free_list+0x16>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101033:	be 00 04 00 00       	mov    $0x400,%esi
f0101038:	e9 07 fd ff ff       	jmp    f0100d44 <check_page_free_list+0x80>
		assert(page2pa(pp) != MPENTRY_PADDR);
f010103d:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0101042:	0f 85 61 ff ff ff    	jne    f0100fa9 <check_page_free_list+0x2e5>
f0101048:	e9 33 ff ff ff       	jmp    f0100f80 <check_page_free_list+0x2bc>
f010104d:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0101052:	0f 85 4c ff ff ff    	jne    f0100fa4 <check_page_free_list+0x2e0>
f0101058:	e9 23 ff ff ff       	jmp    f0100f80 <check_page_free_list+0x2bc>
}
f010105d:	83 c4 4c             	add    $0x4c,%esp
f0101060:	5b                   	pop    %ebx
f0101061:	5e                   	pop    %esi
f0101062:	5f                   	pop    %edi
f0101063:	5d                   	pop    %ebp
f0101064:	c3                   	ret    

f0101065 <page_init>:
{
f0101065:	55                   	push   %ebp
f0101066:	89 e5                	mov    %esp,%ebp
f0101068:	56                   	push   %esi
f0101069:	53                   	push   %ebx
f010106a:	83 ec 10             	sub    $0x10,%esp
	pages[0].pp_link = NULL;
f010106d:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0101072:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pages[0].pp_ref = 1;
f0101078:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f010107d:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[PGNUM(MPENTRY_PADDR)].pp_ref = 1;
f0101083:	66 c7 40 3c 01 00    	movw   $0x1,0x3c(%eax)
	for (i = 1; i < npages_basemem; i++) {
f0101089:	8b 35 44 b2 22 f0    	mov    0xf022b244,%esi
f010108f:	8b 1d 40 b2 22 f0    	mov    0xf022b240,%ebx
f0101095:	b8 01 00 00 00       	mov    $0x1,%eax
f010109a:	eb 27                	jmp    f01010c3 <page_init+0x5e>
		if (i == PGNUM(MPENTRY_PADDR))
f010109c:	83 f8 07             	cmp    $0x7,%eax
f010109f:	74 1f                	je     f01010c0 <page_init+0x5b>
f01010a1:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f01010a8:	8b 0d 90 be 22 f0    	mov    0xf022be90,%ecx
f01010ae:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f01010b5:	89 1c c1             	mov    %ebx,(%ecx,%eax,8)
		page_free_list = &pages[i];
f01010b8:	89 d3                	mov    %edx,%ebx
f01010ba:	03 1d 90 be 22 f0    	add    0xf022be90,%ebx
	for (i = 1; i < npages_basemem; i++) {
f01010c0:	83 c0 01             	add    $0x1,%eax
f01010c3:	39 f0                	cmp    %esi,%eax
f01010c5:	72 d5                	jb     f010109c <page_init+0x37>
f01010c7:	89 1d 40 b2 22 f0    	mov    %ebx,0xf022b240
f01010cd:	b8 00 05 00 00       	mov    $0x500,%eax
		pages[i].pp_link = NULL;
f01010d2:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f01010d8:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
		pages[i].pp_ref = 1;
f01010df:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f01010e5:	66 c7 44 02 04 01 00 	movw   $0x1,0x4(%edx,%eax,1)
f01010ec:	83 c0 08             	add    $0x8,%eax
	for (i = (IOPHYSMEM / PGSIZE); i < (EXTPHYSMEM / PGSIZE); i++)	{
f01010ef:	3d 00 08 00 00       	cmp    $0x800,%eax
f01010f4:	75 dc                	jne    f01010d2 <page_init+0x6d>
	for (i = (PADDR(boot_alloc(0)) / PGSIZE); i < npages; i++)	{
f01010f6:	66 b8 00 00          	mov    $0x0,%ax
f01010fa:	e8 9c fa ff ff       	call   f0100b9b <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f01010ff:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101104:	77 20                	ja     f0101126 <page_init+0xc1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101106:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010110a:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0101111:	f0 
f0101112:	c7 44 24 04 58 01 00 	movl   $0x158,0x4(%esp)
f0101119:	00 
f010111a:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101121:	e8 1a ef ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101126:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010112c:	c1 ea 0c             	shr    $0xc,%edx
f010112f:	8b 1d 40 b2 22 f0    	mov    0xf022b240,%ebx
f0101135:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
f010113c:	eb 1e                	jmp    f010115c <page_init+0xf7>
		pages[i].pp_ref = 0;
f010113e:	89 c1                	mov    %eax,%ecx
f0101140:	03 0d 90 be 22 f0    	add    0xf022be90,%ecx
f0101146:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f010114c:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f010114e:	89 c3                	mov    %eax,%ebx
f0101150:	03 1d 90 be 22 f0    	add    0xf022be90,%ebx
	for (i = (PADDR(boot_alloc(0)) / PGSIZE); i < npages; i++)	{
f0101156:	83 c2 01             	add    $0x1,%edx
f0101159:	83 c0 08             	add    $0x8,%eax
f010115c:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101162:	72 da                	jb     f010113e <page_init+0xd9>
f0101164:	89 1d 40 b2 22 f0    	mov    %ebx,0xf022b240
}
f010116a:	83 c4 10             	add    $0x10,%esp
f010116d:	5b                   	pop    %ebx
f010116e:	5e                   	pop    %esi
f010116f:	5d                   	pop    %ebp
f0101170:	c3                   	ret    

f0101171 <page_alloc>:
{
f0101171:	55                   	push   %ebp
f0101172:	89 e5                	mov    %esp,%ebp
f0101174:	53                   	push   %ebx
f0101175:	83 ec 14             	sub    $0x14,%esp
	struct PageInfo* page_ptr = page_free_list; // Grab the head of our linked list and store it as a pointer.
f0101178:	8b 1d 40 b2 22 f0    	mov    0xf022b240,%ebx
	if (page_ptr == NULL) {
f010117e:	85 db                	test   %ebx,%ebx
f0101180:	74 6f                	je     f01011f1 <page_alloc+0x80>
	page_free_list = page_ptr->pp_link; // Crawl back up our list since this page is going to be allocated.
f0101182:	8b 03                	mov    (%ebx),%eax
f0101184:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
	page_ptr->pp_link = NULL; // Previous link becomes the new head, its link becomes NULL.
f0101189:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	return page_ptr;
f010118f:	89 d8                	mov    %ebx,%eax
	if (alloc_flags & ALLOC_ZERO) {
f0101191:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101195:	74 5f                	je     f01011f6 <page_alloc+0x85>
	return (pp - pages) << PGSHIFT;
f0101197:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f010119d:	c1 f8 03             	sar    $0x3,%eax
f01011a0:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01011a3:	89 c2                	mov    %eax,%edx
f01011a5:	c1 ea 0c             	shr    $0xc,%edx
f01011a8:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f01011ae:	72 20                	jb     f01011d0 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011b0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011b4:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f01011bb:	f0 
f01011bc:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01011c3:	00 
f01011c4:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f01011cb:	e8 70 ee ff ff       	call   f0100040 <_panic>
		memset(page2kva(page_ptr), 0, PGSIZE); // fill the page with 0s
f01011d0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01011d7:	00 
f01011d8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01011df:	00 
	return (void *)(pa + KERNBASE);
f01011e0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011e5:	89 04 24             	mov    %eax,(%esp)
f01011e8:	e8 1a 49 00 00       	call   f0105b07 <memset>
	return page_ptr;
f01011ed:	89 d8                	mov    %ebx,%eax
f01011ef:	eb 05                	jmp    f01011f6 <page_alloc+0x85>
		return NULL;
f01011f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01011f6:	83 c4 14             	add    $0x14,%esp
f01011f9:	5b                   	pop    %ebx
f01011fa:	5d                   	pop    %ebp
f01011fb:	c3                   	ret    

f01011fc <page_free>:
{
f01011fc:	55                   	push   %ebp
f01011fd:	89 e5                	mov    %esp,%ebp
f01011ff:	83 ec 18             	sub    $0x18,%esp
f0101202:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0){
f0101205:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010120a:	74 1c                	je     f0101228 <page_free+0x2c>
		panic("page_free: pp->ref does not equal 0.");
f010120c:	c7 44 24 08 04 6f 10 	movl   $0xf0106f04,0x8(%esp)
f0101213:	f0 
f0101214:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f010121b:	00 
f010121c:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101223:	e8 18 ee ff ff       	call   f0100040 <_panic>
	else if (pp->pp_link != NULL){
f0101228:	83 38 00             	cmpl   $0x0,(%eax)
f010122b:	74 1c                	je     f0101249 <page_free+0x4d>
		panic("page_free: pp->pp_link != NULL.");
f010122d:	c7 44 24 08 2c 6f 10 	movl   $0xf0106f2c,0x8(%esp)
f0101234:	f0 
f0101235:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
f010123c:	00 
f010123d:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101244:	e8 f7 ed ff ff       	call   f0100040 <_panic>
	pp->pp_link = page_free_list; // Set the link to this page to the head of the linked list.
f0101249:	8b 15 40 b2 22 f0    	mov    0xf022b240,%edx
f010124f:	89 10                	mov    %edx,(%eax)
	page_free_list = pp; // Set the page_free_list to be this link, making it the first unallocated page again.
f0101251:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
}
f0101256:	c9                   	leave  
f0101257:	c3                   	ret    

f0101258 <page_decref>:
{
f0101258:	55                   	push   %ebp
f0101259:	89 e5                	mov    %esp,%ebp
f010125b:	83 ec 18             	sub    $0x18,%esp
f010125e:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101261:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101265:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101268:	66 89 50 04          	mov    %dx,0x4(%eax)
f010126c:	66 85 d2             	test   %dx,%dx
f010126f:	75 08                	jne    f0101279 <page_decref+0x21>
		page_free(pp);
f0101271:	89 04 24             	mov    %eax,(%esp)
f0101274:	e8 83 ff ff ff       	call   f01011fc <page_free>
}
f0101279:	c9                   	leave  
f010127a:	c3                   	ret    

f010127b <pgdir_walk>:
{
f010127b:	55                   	push   %ebp
f010127c:	89 e5                	mov    %esp,%ebp
f010127e:	56                   	push   %esi
f010127f:	53                   	push   %ebx
f0101280:	83 ec 10             	sub    $0x10,%esp
f0101283:	8b 55 0c             	mov    0xc(%ebp),%edx
	pde_t pde = pgdir[PDX(va)];
f0101286:	89 d3                	mov    %edx,%ebx
f0101288:	c1 eb 16             	shr    $0x16,%ebx
f010128b:	c1 e3 02             	shl    $0x2,%ebx
f010128e:	03 5d 08             	add    0x8(%ebp),%ebx
f0101291:	8b 03                	mov    (%ebx),%eax
	int ptx = PTX(va);
f0101293:	c1 ea 0c             	shr    $0xc,%edx
f0101296:	89 d6                	mov    %edx,%esi
f0101298:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	if (!flag) // The page isn't there, and we want to make a new one.
f010129e:	a8 01                	test   $0x1,%al
f01012a0:	75 2c                	jne    f01012ce <pgdir_walk+0x53>
		if (create == 1)
f01012a2:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
f01012a6:	75 61                	jne    f0101309 <pgdir_walk+0x8e>
			struct PageInfo* page = page_alloc(ALLOC_ZERO);
f01012a8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01012af:	e8 bd fe ff ff       	call   f0101171 <page_alloc>
			if (page == NULL) {// If the page_alloc fails, return NULL 
f01012b4:	85 c0                	test   %eax,%eax
f01012b6:	74 58                	je     f0101310 <pgdir_walk+0x95>
			page->pp_ref++;
f01012b8:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01012bd:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f01012c3:	c1 f8 03             	sar    $0x3,%eax
f01012c6:	c1 e0 0c             	shl    $0xc,%eax
			pde = page2pa(page) | PTE_W | PTE_P | PTE_U;
f01012c9:	83 c8 07             	or     $0x7,%eax
			pgdir[pdx] = pde; // Store the new page in the pgdirectory
f01012cc:	89 03                	mov    %eax,(%ebx)
	physaddr_t table_phys_addr = PTE_ADDR(pde);
f01012ce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01012d3:	89 c2                	mov    %eax,%edx
f01012d5:	c1 ea 0c             	shr    $0xc,%edx
f01012d8:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f01012de:	72 20                	jb     f0101300 <pgdir_walk+0x85>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012e0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012e4:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f01012eb:	f0 
f01012ec:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
f01012f3:	00 
f01012f4:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01012fb:	e8 40 ed ff ff       	call   f0100040 <_panic>
	return &table_v_addr[ptx];
f0101300:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0101307:	eb 0c                	jmp    f0101315 <pgdir_walk+0x9a>
			return NULL;
f0101309:	b8 00 00 00 00       	mov    $0x0,%eax
f010130e:	eb 05                	jmp    f0101315 <pgdir_walk+0x9a>
				return NULL;
f0101310:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101315:	83 c4 10             	add    $0x10,%esp
f0101318:	5b                   	pop    %ebx
f0101319:	5e                   	pop    %esi
f010131a:	5d                   	pop    %ebp
f010131b:	c3                   	ret    

f010131c <boot_map_region>:
{
f010131c:	55                   	push   %ebp
f010131d:	89 e5                	mov    %esp,%ebp
f010131f:	57                   	push   %edi
f0101320:	56                   	push   %esi
f0101321:	53                   	push   %ebx
f0101322:	83 ec 2c             	sub    $0x2c,%esp
f0101325:	89 c7                	mov    %eax,%edi
	int pagecount = size / PGSIZE; // get the current number of pages, since size is PGSIZE aligned we can
f0101327:	c1 e9 0c             	shr    $0xc,%ecx
f010132a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (int i = 0; i < pagecount; i++) {
f010132d:	89 d3                	mov    %edx,%ebx
f010132f:	be 00 00 00 00       	mov    $0x0,%esi
		*p_pte = (pa + i * PGSIZE) | perm | PTE_P; // Move to the next physical address.
f0101334:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101337:	83 c8 01             	or     $0x1,%eax
f010133a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010133d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101340:	29 d0                	sub    %edx,%eax
f0101342:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (int i = 0; i < pagecount; i++) {
f0101345:	eb 28                	jmp    f010136f <boot_map_region+0x53>
		pte_t * p_pte = pgdir_walk(pgdir, (void*) (va + i * PGSIZE), 1);
f0101347:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010134e:	00 
f010134f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101353:	89 3c 24             	mov    %edi,(%esp)
f0101356:	e8 20 ff ff ff       	call   f010127b <pgdir_walk>
f010135b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010135e:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
		*p_pte = (pa + i * PGSIZE) | perm | PTE_P; // Move to the next physical address.
f0101361:	0b 55 e0             	or     -0x20(%ebp),%edx
f0101364:	89 10                	mov    %edx,(%eax)
	for (int i = 0; i < pagecount; i++) {
f0101366:	83 c6 01             	add    $0x1,%esi
f0101369:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010136f:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101372:	7c d3                	jl     f0101347 <boot_map_region+0x2b>
}
f0101374:	83 c4 2c             	add    $0x2c,%esp
f0101377:	5b                   	pop    %ebx
f0101378:	5e                   	pop    %esi
f0101379:	5f                   	pop    %edi
f010137a:	5d                   	pop    %ebp
f010137b:	c3                   	ret    

f010137c <page_lookup>:
{
f010137c:	55                   	push   %ebp
f010137d:	89 e5                	mov    %esp,%ebp
f010137f:	53                   	push   %ebx
f0101380:	83 ec 14             	sub    $0x14,%esp
f0101383:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *entry = pgdir_walk(pgdir, va, 0);
f0101386:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010138d:	00 
f010138e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101391:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101395:	8b 45 08             	mov    0x8(%ebp),%eax
f0101398:	89 04 24             	mov    %eax,(%esp)
f010139b:	e8 db fe ff ff       	call   f010127b <pgdir_walk>
	if (!flag)	{ // If nothings there, return null
f01013a0:	f6 00 01             	testb  $0x1,(%eax)
f01013a3:	74 3e                	je     f01013e3 <page_lookup+0x67>
	else if (entry == NULL)	{ // If the address is null, return null.
f01013a5:	85 c0                	test   %eax,%eax
f01013a7:	74 41                	je     f01013ea <page_lookup+0x6e>
	if (pte_store != 0)	{ 
f01013a9:	85 db                	test   %ebx,%ebx
f01013ab:	74 02                	je     f01013af <page_lookup+0x33>
		*pte_store = entry;
f01013ad:	89 03                	mov    %eax,(%ebx)
	result = pa2page(PTE_ADDR(*entry)); // Get the page associated with the physical address and return it.
f01013af:	8b 00                	mov    (%eax),%eax
	if (PGNUM(pa) >= npages)
f01013b1:	c1 e8 0c             	shr    $0xc,%eax
f01013b4:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f01013ba:	72 1c                	jb     f01013d8 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f01013bc:	c7 44 24 08 4c 6f 10 	movl   $0xf0106f4c,0x8(%esp)
f01013c3:	f0 
f01013c4:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f01013cb:	00 
f01013cc:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f01013d3:	e8 68 ec ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01013d8:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f01013de:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	return result;
f01013e1:	eb 0c                	jmp    f01013ef <page_lookup+0x73>
		return NULL;
f01013e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01013e8:	eb 05                	jmp    f01013ef <page_lookup+0x73>
		return NULL;
f01013ea:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013ef:	83 c4 14             	add    $0x14,%esp
f01013f2:	5b                   	pop    %ebx
f01013f3:	5d                   	pop    %ebp
f01013f4:	c3                   	ret    

f01013f5 <tlb_invalidate>:
{
f01013f5:	55                   	push   %ebp
f01013f6:	89 e5                	mov    %esp,%ebp
f01013f8:	83 ec 08             	sub    $0x8,%esp
	if (!curenv || curenv->env_pgdir == pgdir)
f01013fb:	e8 59 4d 00 00       	call   f0106159 <cpunum>
f0101400:	6b c0 74             	imul   $0x74,%eax,%eax
f0101403:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f010140a:	74 16                	je     f0101422 <tlb_invalidate+0x2d>
f010140c:	e8 48 4d 00 00       	call   f0106159 <cpunum>
f0101411:	6b c0 74             	imul   $0x74,%eax,%eax
f0101414:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010141a:	8b 55 08             	mov    0x8(%ebp),%edx
f010141d:	39 50 60             	cmp    %edx,0x60(%eax)
f0101420:	75 06                	jne    f0101428 <tlb_invalidate+0x33>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101422:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101425:	0f 01 38             	invlpg (%eax)
}
f0101428:	c9                   	leave  
f0101429:	c3                   	ret    

f010142a <page_remove>:
{
f010142a:	55                   	push   %ebp
f010142b:	89 e5                	mov    %esp,%ebp
f010142d:	57                   	push   %edi
f010142e:	56                   	push   %esi
f010142f:	53                   	push   %ebx
f0101430:	83 ec 2c             	sub    $0x2c,%esp
f0101433:	8b 75 08             	mov    0x8(%ebp),%esi
f0101436:	8b 7d 0c             	mov    0xc(%ebp),%edi
	page = page_lookup(pgdir, va, &buffer_addr);
f0101439:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010143c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101440:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101444:	89 34 24             	mov    %esi,(%esp)
f0101447:	e8 30 ff ff ff       	call   f010137c <page_lookup>
f010144c:	89 c3                	mov    %eax,%ebx
	if (page == NULL || buffer_addr == NULL) { // If there's nothing there, return early.
f010144e:	85 c0                	test   %eax,%eax
f0101450:	74 21                	je     f0101473 <page_remove+0x49>
f0101452:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101455:	85 c0                	test   %eax,%eax
f0101457:	74 1a                	je     f0101473 <page_remove+0x49>
		*buffer_addr = 0;
f0101459:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va); // invalidate the VR of the page
f010145f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101463:	89 34 24             	mov    %esi,(%esp)
f0101466:	e8 8a ff ff ff       	call   f01013f5 <tlb_invalidate>
		page_decref(page); // dereference the page
f010146b:	89 1c 24             	mov    %ebx,(%esp)
f010146e:	e8 e5 fd ff ff       	call   f0101258 <page_decref>
}
f0101473:	83 c4 2c             	add    $0x2c,%esp
f0101476:	5b                   	pop    %ebx
f0101477:	5e                   	pop    %esi
f0101478:	5f                   	pop    %edi
f0101479:	5d                   	pop    %ebp
f010147a:	c3                   	ret    

f010147b <page_insert>:
{
f010147b:	55                   	push   %ebp
f010147c:	89 e5                	mov    %esp,%ebp
f010147e:	57                   	push   %edi
f010147f:	56                   	push   %esi
f0101480:	53                   	push   %ebx
f0101481:	83 ec 1c             	sub    $0x1c,%esp
f0101484:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101487:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *address = pgdir_walk(pgdir, va, true);
f010148a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101491:	00 
f0101492:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101496:	8b 45 08             	mov    0x8(%ebp),%eax
f0101499:	89 04 24             	mov    %eax,(%esp)
f010149c:	e8 da fd ff ff       	call   f010127b <pgdir_walk>
f01014a1:	89 c3                	mov    %eax,%ebx
	if (address == NULL) { // if our walk comes up with nothing, page cannot be allocated.
f01014a3:	85 c0                	test   %eax,%eax
f01014a5:	74 36                	je     f01014dd <page_insert+0x62>
		pp->pp_ref++;
f01014a7:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		if (*address & PTE_P)
f01014ac:	f6 00 01             	testb  $0x1,(%eax)
f01014af:	74 0f                	je     f01014c0 <page_insert+0x45>
			page_remove(pgdir, va);
f01014b1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b8:	89 04 24             	mov    %eax,(%esp)
f01014bb:	e8 6a ff ff ff       	call   f010142a <page_remove>
		*address = page2pa(pp) | perm | PTE_P;
f01014c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01014c3:	83 c8 01             	or     $0x1,%eax
	return (pp - pages) << PGSHIFT;
f01014c6:	2b 35 90 be 22 f0    	sub    0xf022be90,%esi
f01014cc:	c1 fe 03             	sar    $0x3,%esi
f01014cf:	c1 e6 0c             	shl    $0xc,%esi
f01014d2:	09 c6                	or     %eax,%esi
f01014d4:	89 33                	mov    %esi,(%ebx)
		return 0;
f01014d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01014db:	eb 05                	jmp    f01014e2 <page_insert+0x67>
		return -E_NO_MEM;
f01014dd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f01014e2:	83 c4 1c             	add    $0x1c,%esp
f01014e5:	5b                   	pop    %ebx
f01014e6:	5e                   	pop    %esi
f01014e7:	5f                   	pop    %edi
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <mmio_map_region>:
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	57                   	push   %edi
f01014ee:	56                   	push   %esi
f01014ef:	53                   	push   %ebx
f01014f0:	83 ec 2c             	sub    $0x2c,%esp
f01014f3:	8b 45 08             	mov    0x8(%ebp),%eax
	uintptr_t pa_start = ROUNDDOWN(pa, PGSIZE);
f01014f6:	89 c6                	mov    %eax,%esi
f01014f8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uintptr_t pa_end = ROUNDUP(pa + size, PGSIZE);
f01014fe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101501:	8d 91 ff 0f 00 00    	lea    0xfff(%ecx),%edx
f0101507:	8d 3c 02             	lea    (%edx,%eax,1),%edi
f010150a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	uintptr_t pa_offset = (pa & 0xfff);
f0101510:	25 ff 0f 00 00       	and    $0xfff,%eax
f0101515:	89 45 e0             	mov    %eax,-0x20(%ebp)
	uintptr_t virt_start = base;
f0101518:	8b 1d 00 03 12 f0    	mov    0xf0120300,%ebx
	uintptr_t nubase = virt_start + (pa_end - pa_start);
f010151e:	89 d8                	mov    %ebx,%eax
f0101520:	29 f0                	sub    %esi,%eax
f0101522:	01 f8                	add    %edi,%eax
f0101524:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size = ROUNDUP (size, PGSIZE);
f0101527:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (base + size > MMIOLIM)
f010152d:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f0101530:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f0101535:	76 49                	jbe    f0101580 <mmio_map_region+0x96>
		panic("mmio_map_region: MMILOIM overflow!");
f0101537:	c7 44 24 08 6c 6f 10 	movl   $0xf0106f6c,0x8(%esp)
f010153e:	f0 
f010153f:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0101546:	00 
f0101547:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010154e:	e8 ed ea ff ff       	call   f0100040 <_panic>
		if (virt_start < nubase)
f0101553:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101556:	73 28                	jae    f0101580 <mmio_map_region+0x96>
			boot_map_region(kern_pgdir, virt_start, PGSIZE, pa_start, PTE_PCD | PTE_PWT | PTE_W);
f0101558:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
f010155f:	00 
f0101560:	89 34 24             	mov    %esi,(%esp)
f0101563:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0101568:	89 da                	mov    %ebx,%edx
f010156a:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010156f:	e8 a8 fd ff ff       	call   f010131c <boot_map_region>
			pa_start = PGSIZE + pa_start;
f0101574:	81 c6 00 10 00 00    	add    $0x1000,%esi
			virt_start = PGSIZE + virt_start; 
f010157a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	while (pa_start < pa_end)
f0101580:	39 f7                	cmp    %esi,%edi
f0101582:	77 cf                	ja     f0101553 <mmio_map_region+0x69>
	oldbase = base;
f0101584:	a1 00 03 12 f0       	mov    0xf0120300,%eax
	base = nubase;
f0101589:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010158c:	89 0d 00 03 12 f0    	mov    %ecx,0xf0120300
	return (void*) oldbase + pa_offset;
f0101592:	03 45 e0             	add    -0x20(%ebp),%eax
}
f0101595:	83 c4 2c             	add    $0x2c,%esp
f0101598:	5b                   	pop    %ebx
f0101599:	5e                   	pop    %esi
f010159a:	5f                   	pop    %edi
f010159b:	5d                   	pop    %ebp
f010159c:	c3                   	ret    

f010159d <mem_init>:
{
f010159d:	55                   	push   %ebp
f010159e:	89 e5                	mov    %esp,%ebp
f01015a0:	57                   	push   %edi
f01015a1:	56                   	push   %esi
f01015a2:	53                   	push   %ebx
f01015a3:	83 ec 4c             	sub    $0x4c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f01015a6:	b8 15 00 00 00       	mov    $0x15,%eax
f01015ab:	e8 c0 f5 ff ff       	call   f0100b70 <nvram_read>
f01015b0:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01015b2:	b8 17 00 00 00       	mov    $0x17,%eax
f01015b7:	e8 b4 f5 ff ff       	call   f0100b70 <nvram_read>
f01015bc:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01015be:	b8 34 00 00 00       	mov    $0x34,%eax
f01015c3:	e8 a8 f5 ff ff       	call   f0100b70 <nvram_read>
f01015c8:	c1 e0 06             	shl    $0x6,%eax
f01015cb:	89 c2                	mov    %eax,%edx
		totalmem = 16 * 1024 + ext16mem;
f01015cd:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	if (ext16mem)
f01015d3:	85 d2                	test   %edx,%edx
f01015d5:	75 0b                	jne    f01015e2 <mem_init+0x45>
		totalmem = 1 * 1024 + extmem;
f01015d7:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01015dd:	85 f6                	test   %esi,%esi
f01015df:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01015e2:	89 c2                	mov    %eax,%edx
f01015e4:	c1 ea 02             	shr    $0x2,%edx
f01015e7:	89 15 88 be 22 f0    	mov    %edx,0xf022be88
	npages_basemem = basemem / (PGSIZE / 1024);
f01015ed:	89 da                	mov    %ebx,%edx
f01015ef:	c1 ea 02             	shr    $0x2,%edx
f01015f2:	89 15 44 b2 22 f0    	mov    %edx,0xf022b244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01015f8:	89 c2                	mov    %eax,%edx
f01015fa:	29 da                	sub    %ebx,%edx
f01015fc:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101600:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101604:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101608:	c7 04 24 90 6f 10 f0 	movl   $0xf0106f90,(%esp)
f010160f:	e8 e7 29 00 00       	call   f0103ffb <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101614:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101619:	e8 7d f5 ff ff       	call   f0100b9b <boot_alloc>
f010161e:	a3 8c be 22 f0       	mov    %eax,0xf022be8c
	memset(kern_pgdir, 0, PGSIZE);
f0101623:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010162a:	00 
f010162b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101632:	00 
f0101633:	89 04 24             	mov    %eax,(%esp)
f0101636:	e8 cc 44 00 00       	call   f0105b07 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010163b:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0101640:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101645:	77 20                	ja     f0101667 <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101647:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010164b:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0101652:	f0 
f0101653:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f010165a:	00 
f010165b:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101662:	e8 d9 e9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101667:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010166d:	83 ca 05             	or     $0x5,%edx
f0101670:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
   pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo)); // Allocating the array, using boot_alloc to allocate
f0101676:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f010167b:	c1 e0 03             	shl    $0x3,%eax
f010167e:	e8 18 f5 ff ff       	call   f0100b9b <boot_alloc>
f0101683:	a3 90 be 22 f0       	mov    %eax,0xf022be90
   memset(pages, 0, npages * sizeof(struct PageInfo)); // Set all fields of PageInfo in pages to 0.
f0101688:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f010168e:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101695:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101699:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016a0:	00 
f01016a1:	89 04 24             	mov    %eax,(%esp)
f01016a4:	e8 5e 44 00 00       	call   f0105b07 <memset>
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f01016a9:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01016ae:	e8 e8 f4 ff ff       	call   f0100b9b <boot_alloc>
f01016b3:	a3 48 b2 22 f0       	mov    %eax,0xf022b248
	page_init();
f01016b8:	e8 a8 f9 ff ff       	call   f0101065 <page_init>
	check_page_free_list(1);
f01016bd:	b8 01 00 00 00       	mov    $0x1,%eax
f01016c2:	e8 fd f5 ff ff       	call   f0100cc4 <check_page_free_list>
	if (!pages)
f01016c7:	83 3d 90 be 22 f0 00 	cmpl   $0x0,0xf022be90
f01016ce:	75 1c                	jne    f01016ec <mem_init+0x14f>
		panic("'pages' is a null pointer!");
f01016d0:	c7 44 24 08 7c 78 10 	movl   $0xf010787c,0x8(%esp)
f01016d7:	f0 
f01016d8:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f01016df:	00 
f01016e0:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01016e7:	e8 54 e9 ff ff       	call   f0100040 <_panic>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016ec:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f01016f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016f6:	eb 05                	jmp    f01016fd <mem_init+0x160>
		++nfree;
f01016f8:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016fb:	8b 00                	mov    (%eax),%eax
f01016fd:	85 c0                	test   %eax,%eax
f01016ff:	75 f7                	jne    f01016f8 <mem_init+0x15b>
	assert((pp0 = page_alloc(0)));
f0101701:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101708:	e8 64 fa ff ff       	call   f0101171 <page_alloc>
f010170d:	89 c7                	mov    %eax,%edi
f010170f:	85 c0                	test   %eax,%eax
f0101711:	75 24                	jne    f0101737 <mem_init+0x19a>
f0101713:	c7 44 24 0c 97 78 10 	movl   $0xf0107897,0xc(%esp)
f010171a:	f0 
f010171b:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101722:	f0 
f0101723:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f010172a:	00 
f010172b:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101732:	e8 09 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101737:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010173e:	e8 2e fa ff ff       	call   f0101171 <page_alloc>
f0101743:	89 c6                	mov    %eax,%esi
f0101745:	85 c0                	test   %eax,%eax
f0101747:	75 24                	jne    f010176d <mem_init+0x1d0>
f0101749:	c7 44 24 0c ad 78 10 	movl   $0xf01078ad,0xc(%esp)
f0101750:	f0 
f0101751:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101758:	f0 
f0101759:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101760:	00 
f0101761:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101768:	e8 d3 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010176d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101774:	e8 f8 f9 ff ff       	call   f0101171 <page_alloc>
f0101779:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010177c:	85 c0                	test   %eax,%eax
f010177e:	75 24                	jne    f01017a4 <mem_init+0x207>
f0101780:	c7 44 24 0c c3 78 10 	movl   $0xf01078c3,0xc(%esp)
f0101787:	f0 
f0101788:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010178f:	f0 
f0101790:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101797:	00 
f0101798:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010179f:	e8 9c e8 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01017a4:	39 f7                	cmp    %esi,%edi
f01017a6:	75 24                	jne    f01017cc <mem_init+0x22f>
f01017a8:	c7 44 24 0c d9 78 10 	movl   $0xf01078d9,0xc(%esp)
f01017af:	f0 
f01017b0:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01017b7:	f0 
f01017b8:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f01017bf:	00 
f01017c0:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01017c7:	e8 74 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017cc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017cf:	39 c6                	cmp    %eax,%esi
f01017d1:	74 04                	je     f01017d7 <mem_init+0x23a>
f01017d3:	39 c7                	cmp    %eax,%edi
f01017d5:	75 24                	jne    f01017fb <mem_init+0x25e>
f01017d7:	c7 44 24 0c cc 6f 10 	movl   $0xf0106fcc,0xc(%esp)
f01017de:	f0 
f01017df:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01017e6:	f0 
f01017e7:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f01017ee:	00 
f01017ef:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01017f6:	e8 45 e8 ff ff       	call   f0100040 <_panic>
	return (pp - pages) << PGSHIFT;
f01017fb:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101801:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0101806:	c1 e0 0c             	shl    $0xc,%eax
f0101809:	89 f9                	mov    %edi,%ecx
f010180b:	29 d1                	sub    %edx,%ecx
f010180d:	c1 f9 03             	sar    $0x3,%ecx
f0101810:	c1 e1 0c             	shl    $0xc,%ecx
f0101813:	39 c1                	cmp    %eax,%ecx
f0101815:	72 24                	jb     f010183b <mem_init+0x29e>
f0101817:	c7 44 24 0c eb 78 10 	movl   $0xf01078eb,0xc(%esp)
f010181e:	f0 
f010181f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101826:	f0 
f0101827:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f010182e:	00 
f010182f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101836:	e8 05 e8 ff ff       	call   f0100040 <_panic>
f010183b:	89 f1                	mov    %esi,%ecx
f010183d:	29 d1                	sub    %edx,%ecx
f010183f:	c1 f9 03             	sar    $0x3,%ecx
f0101842:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101845:	39 c8                	cmp    %ecx,%eax
f0101847:	77 24                	ja     f010186d <mem_init+0x2d0>
f0101849:	c7 44 24 0c 08 79 10 	movl   $0xf0107908,0xc(%esp)
f0101850:	f0 
f0101851:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101858:	f0 
f0101859:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0101860:	00 
f0101861:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101868:	e8 d3 e7 ff ff       	call   f0100040 <_panic>
f010186d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101870:	29 d1                	sub    %edx,%ecx
f0101872:	89 ca                	mov    %ecx,%edx
f0101874:	c1 fa 03             	sar    $0x3,%edx
f0101877:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010187a:	39 d0                	cmp    %edx,%eax
f010187c:	77 24                	ja     f01018a2 <mem_init+0x305>
f010187e:	c7 44 24 0c 25 79 10 	movl   $0xf0107925,0xc(%esp)
f0101885:	f0 
f0101886:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010188d:	f0 
f010188e:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101895:	00 
f0101896:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010189d:	e8 9e e7 ff ff       	call   f0100040 <_panic>
	fl = page_free_list;
f01018a2:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f01018a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018aa:	c7 05 40 b2 22 f0 00 	movl   $0x0,0xf022b240
f01018b1:	00 00 00 
	assert(!page_alloc(0));
f01018b4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018bb:	e8 b1 f8 ff ff       	call   f0101171 <page_alloc>
f01018c0:	85 c0                	test   %eax,%eax
f01018c2:	74 24                	je     f01018e8 <mem_init+0x34b>
f01018c4:	c7 44 24 0c 42 79 10 	movl   $0xf0107942,0xc(%esp)
f01018cb:	f0 
f01018cc:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01018d3:	f0 
f01018d4:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01018db:	00 
f01018dc:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01018e3:	e8 58 e7 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01018e8:	89 3c 24             	mov    %edi,(%esp)
f01018eb:	e8 0c f9 ff ff       	call   f01011fc <page_free>
	page_free(pp1);
f01018f0:	89 34 24             	mov    %esi,(%esp)
f01018f3:	e8 04 f9 ff ff       	call   f01011fc <page_free>
	page_free(pp2);
f01018f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018fb:	89 04 24             	mov    %eax,(%esp)
f01018fe:	e8 f9 f8 ff ff       	call   f01011fc <page_free>
	assert((pp0 = page_alloc(0)));
f0101903:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010190a:	e8 62 f8 ff ff       	call   f0101171 <page_alloc>
f010190f:	89 c6                	mov    %eax,%esi
f0101911:	85 c0                	test   %eax,%eax
f0101913:	75 24                	jne    f0101939 <mem_init+0x39c>
f0101915:	c7 44 24 0c 97 78 10 	movl   $0xf0107897,0xc(%esp)
f010191c:	f0 
f010191d:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101924:	f0 
f0101925:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010192c:	00 
f010192d:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101934:	e8 07 e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101939:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101940:	e8 2c f8 ff ff       	call   f0101171 <page_alloc>
f0101945:	89 c7                	mov    %eax,%edi
f0101947:	85 c0                	test   %eax,%eax
f0101949:	75 24                	jne    f010196f <mem_init+0x3d2>
f010194b:	c7 44 24 0c ad 78 10 	movl   $0xf01078ad,0xc(%esp)
f0101952:	f0 
f0101953:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010195a:	f0 
f010195b:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101962:	00 
f0101963:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010196a:	e8 d1 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010196f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101976:	e8 f6 f7 ff ff       	call   f0101171 <page_alloc>
f010197b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010197e:	85 c0                	test   %eax,%eax
f0101980:	75 24                	jne    f01019a6 <mem_init+0x409>
f0101982:	c7 44 24 0c c3 78 10 	movl   $0xf01078c3,0xc(%esp)
f0101989:	f0 
f010198a:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101991:	f0 
f0101992:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101999:	00 
f010199a:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01019a1:	e8 9a e6 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f01019a6:	39 fe                	cmp    %edi,%esi
f01019a8:	75 24                	jne    f01019ce <mem_init+0x431>
f01019aa:	c7 44 24 0c d9 78 10 	movl   $0xf01078d9,0xc(%esp)
f01019b1:	f0 
f01019b2:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01019b9:	f0 
f01019ba:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01019c1:	00 
f01019c2:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01019c9:	e8 72 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019d1:	39 c7                	cmp    %eax,%edi
f01019d3:	74 04                	je     f01019d9 <mem_init+0x43c>
f01019d5:	39 c6                	cmp    %eax,%esi
f01019d7:	75 24                	jne    f01019fd <mem_init+0x460>
f01019d9:	c7 44 24 0c cc 6f 10 	movl   $0xf0106fcc,0xc(%esp)
f01019e0:	f0 
f01019e1:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01019e8:	f0 
f01019e9:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f01019f0:	00 
f01019f1:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01019f8:	e8 43 e6 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01019fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a04:	e8 68 f7 ff ff       	call   f0101171 <page_alloc>
f0101a09:	85 c0                	test   %eax,%eax
f0101a0b:	74 24                	je     f0101a31 <mem_init+0x494>
f0101a0d:	c7 44 24 0c 42 79 10 	movl   $0xf0107942,0xc(%esp)
f0101a14:	f0 
f0101a15:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101a1c:	f0 
f0101a1d:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0101a24:	00 
f0101a25:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101a2c:	e8 0f e6 ff ff       	call   f0100040 <_panic>
	cprintf("%08x\n", boot_alloc(0));
f0101a31:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a36:	e8 60 f1 ff ff       	call   f0100b9b <boot_alloc>
f0101a3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a3f:	c7 04 24 75 84 10 f0 	movl   $0xf0108475,(%esp)
f0101a46:	e8 b0 25 00 00       	call   f0103ffb <cprintf>
f0101a4b:	89 f0                	mov    %esi,%eax
f0101a4d:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101a53:	c1 f8 03             	sar    $0x3,%eax
f0101a56:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101a59:	89 c2                	mov    %eax,%edx
f0101a5b:	c1 ea 0c             	shr    $0xc,%edx
f0101a5e:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101a64:	72 20                	jb     f0101a86 <mem_init+0x4e9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a66:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a6a:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0101a71:	f0 
f0101a72:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101a79:	00 
f0101a7a:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f0101a81:	e8 ba e5 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
f0101a86:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a8d:	00 
f0101a8e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101a95:	00 
	return (void *)(pa + KERNBASE);
f0101a96:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a9b:	89 04 24             	mov    %eax,(%esp)
f0101a9e:	e8 64 40 00 00       	call   f0105b07 <memset>
	page_free(pp0);
f0101aa3:	89 34 24             	mov    %esi,(%esp)
f0101aa6:	e8 51 f7 ff ff       	call   f01011fc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101aab:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101ab2:	e8 ba f6 ff ff       	call   f0101171 <page_alloc>
f0101ab7:	85 c0                	test   %eax,%eax
f0101ab9:	75 24                	jne    f0101adf <mem_init+0x542>
f0101abb:	c7 44 24 0c 51 79 10 	movl   $0xf0107951,0xc(%esp)
f0101ac2:	f0 
f0101ac3:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101aca:	f0 
f0101acb:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0101ad2:	00 
f0101ad3:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101ada:	e8 61 e5 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101adf:	39 c6                	cmp    %eax,%esi
f0101ae1:	74 24                	je     f0101b07 <mem_init+0x56a>
f0101ae3:	c7 44 24 0c 6f 79 10 	movl   $0xf010796f,0xc(%esp)
f0101aea:	f0 
f0101aeb:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101af2:	f0 
f0101af3:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0101afa:	00 
f0101afb:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101b02:	e8 39 e5 ff ff       	call   f0100040 <_panic>
	return (pp - pages) << PGSHIFT;
f0101b07:	89 f0                	mov    %esi,%eax
f0101b09:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101b0f:	c1 f8 03             	sar    $0x3,%eax
f0101b12:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101b15:	89 c2                	mov    %eax,%edx
f0101b17:	c1 ea 0c             	shr    $0xc,%edx
f0101b1a:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101b20:	72 20                	jb     f0101b42 <mem_init+0x5a5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b22:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b26:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0101b2d:	f0 
f0101b2e:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101b35:	00 
f0101b36:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f0101b3d:	e8 fe e4 ff ff       	call   f0100040 <_panic>
f0101b42:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101b48:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
		assert(c[i] == 0);
f0101b4e:	80 38 00             	cmpb   $0x0,(%eax)
f0101b51:	74 24                	je     f0101b77 <mem_init+0x5da>
f0101b53:	c7 44 24 0c 7f 79 10 	movl   $0xf010797f,0xc(%esp)
f0101b5a:	f0 
f0101b5b:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101b62:	f0 
f0101b63:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101b6a:	00 
f0101b6b:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101b72:	e8 c9 e4 ff ff       	call   f0100040 <_panic>
f0101b77:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101b7a:	39 d0                	cmp    %edx,%eax
f0101b7c:	75 d0                	jne    f0101b4e <mem_init+0x5b1>
	page_free_list = fl;
f0101b7e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b81:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
	page_free(pp0);
f0101b86:	89 34 24             	mov    %esi,(%esp)
f0101b89:	e8 6e f6 ff ff       	call   f01011fc <page_free>
	page_free(pp1);
f0101b8e:	89 3c 24             	mov    %edi,(%esp)
f0101b91:	e8 66 f6 ff ff       	call   f01011fc <page_free>
	page_free(pp2);
f0101b96:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b99:	89 04 24             	mov    %eax,(%esp)
f0101b9c:	e8 5b f6 ff ff       	call   f01011fc <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ba1:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f0101ba6:	eb 05                	jmp    f0101bad <mem_init+0x610>
		--nfree;
f0101ba8:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bab:	8b 00                	mov    (%eax),%eax
f0101bad:	85 c0                	test   %eax,%eax
f0101baf:	75 f7                	jne    f0101ba8 <mem_init+0x60b>
	assert(nfree == 0);
f0101bb1:	85 db                	test   %ebx,%ebx
f0101bb3:	74 24                	je     f0101bd9 <mem_init+0x63c>
f0101bb5:	c7 44 24 0c 89 79 10 	movl   $0xf0107989,0xc(%esp)
f0101bbc:	f0 
f0101bbd:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101bc4:	f0 
f0101bc5:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101bcc:	00 
f0101bcd:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101bd4:	e8 67 e4 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_alloc() succeeded!\n");
f0101bd9:	c7 04 24 ec 6f 10 f0 	movl   $0xf0106fec,(%esp)
f0101be0:	e8 16 24 00 00       	call   f0103ffb <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101be5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bec:	e8 80 f5 ff ff       	call   f0101171 <page_alloc>
f0101bf1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101bf4:	85 c0                	test   %eax,%eax
f0101bf6:	75 24                	jne    f0101c1c <mem_init+0x67f>
f0101bf8:	c7 44 24 0c 97 78 10 	movl   $0xf0107897,0xc(%esp)
f0101bff:	f0 
f0101c00:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101c07:	f0 
f0101c08:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f0101c0f:	00 
f0101c10:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101c17:	e8 24 e4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c1c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c23:	e8 49 f5 ff ff       	call   f0101171 <page_alloc>
f0101c28:	89 c3                	mov    %eax,%ebx
f0101c2a:	85 c0                	test   %eax,%eax
f0101c2c:	75 24                	jne    f0101c52 <mem_init+0x6b5>
f0101c2e:	c7 44 24 0c ad 78 10 	movl   $0xf01078ad,0xc(%esp)
f0101c35:	f0 
f0101c36:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101c3d:	f0 
f0101c3e:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0101c45:	00 
f0101c46:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101c4d:	e8 ee e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c59:	e8 13 f5 ff ff       	call   f0101171 <page_alloc>
f0101c5e:	89 c6                	mov    %eax,%esi
f0101c60:	85 c0                	test   %eax,%eax
f0101c62:	75 24                	jne    f0101c88 <mem_init+0x6eb>
f0101c64:	c7 44 24 0c c3 78 10 	movl   $0xf01078c3,0xc(%esp)
f0101c6b:	f0 
f0101c6c:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101c73:	f0 
f0101c74:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f0101c7b:	00 
f0101c7c:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101c83:	e8 b8 e3 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c88:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101c8b:	75 24                	jne    f0101cb1 <mem_init+0x714>
f0101c8d:	c7 44 24 0c d9 78 10 	movl   $0xf01078d9,0xc(%esp)
f0101c94:	f0 
f0101c95:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101c9c:	f0 
f0101c9d:	c7 44 24 04 ed 03 00 	movl   $0x3ed,0x4(%esp)
f0101ca4:	00 
f0101ca5:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101cac:	e8 8f e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101cb1:	39 c3                	cmp    %eax,%ebx
f0101cb3:	74 05                	je     f0101cba <mem_init+0x71d>
f0101cb5:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101cb8:	75 24                	jne    f0101cde <mem_init+0x741>
f0101cba:	c7 44 24 0c cc 6f 10 	movl   $0xf0106fcc,0xc(%esp)
f0101cc1:	f0 
f0101cc2:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101cc9:	f0 
f0101cca:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f0101cd1:	00 
f0101cd2:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101cd9:	e8 62 e3 ff ff       	call   f0100040 <_panic>
	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101cde:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f0101ce3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101ce6:	c7 05 40 b2 22 f0 00 	movl   $0x0,0xf022b240
f0101ced:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101cf0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cf7:	e8 75 f4 ff ff       	call   f0101171 <page_alloc>
f0101cfc:	85 c0                	test   %eax,%eax
f0101cfe:	74 24                	je     f0101d24 <mem_init+0x787>
f0101d00:	c7 44 24 0c 42 79 10 	movl   $0xf0107942,0xc(%esp)
f0101d07:	f0 
f0101d08:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101d0f:	f0 
f0101d10:	c7 44 24 04 f4 03 00 	movl   $0x3f4,0x4(%esp)
f0101d17:	00 
f0101d18:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101d1f:	e8 1c e3 ff ff       	call   f0100040 <_panic>
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101d24:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101d27:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d2b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101d32:	00 
f0101d33:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101d38:	89 04 24             	mov    %eax,(%esp)
f0101d3b:	e8 3c f6 ff ff       	call   f010137c <page_lookup>
f0101d40:	85 c0                	test   %eax,%eax
f0101d42:	74 24                	je     f0101d68 <mem_init+0x7cb>
f0101d44:	c7 44 24 0c 0c 70 10 	movl   $0xf010700c,0xc(%esp)
f0101d4b:	f0 
f0101d4c:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101d53:	f0 
f0101d54:	c7 44 24 04 f6 03 00 	movl   $0x3f6,0x4(%esp)
f0101d5b:	00 
f0101d5c:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101d63:	e8 d8 e2 ff ff       	call   f0100040 <_panic>
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101d68:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d6f:	00 
f0101d70:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d77:	00 
f0101d78:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d7c:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101d81:	89 04 24             	mov    %eax,(%esp)
f0101d84:	e8 f2 f6 ff ff       	call   f010147b <page_insert>
f0101d89:	85 c0                	test   %eax,%eax
f0101d8b:	78 24                	js     f0101db1 <mem_init+0x814>
f0101d8d:	c7 44 24 0c 44 70 10 	movl   $0xf0107044,0xc(%esp)
f0101d94:	f0 
f0101d95:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101d9c:	f0 
f0101d9d:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0101da4:	00 
f0101da5:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101dac:	e8 8f e2 ff ff       	call   f0100040 <_panic>
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101db1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101db4:	89 04 24             	mov    %eax,(%esp)
f0101db7:	e8 40 f4 ff ff       	call   f01011fc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101dbc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101dc3:	00 
f0101dc4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dcb:	00 
f0101dcc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101dd0:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101dd5:	89 04 24             	mov    %eax,(%esp)
f0101dd8:	e8 9e f6 ff ff       	call   f010147b <page_insert>
f0101ddd:	85 c0                	test   %eax,%eax
f0101ddf:	74 24                	je     f0101e05 <mem_init+0x868>
f0101de1:	c7 44 24 0c 74 70 10 	movl   $0xf0107074,0xc(%esp)
f0101de8:	f0 
f0101de9:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101df0:	f0 
f0101df1:	c7 44 24 04 fb 03 00 	movl   $0x3fb,0x4(%esp)
f0101df8:	00 
f0101df9:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101e00:	e8 3b e2 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e05:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
	return (pp - pages) << PGSHIFT;
f0101e0b:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0101e10:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e13:	8b 17                	mov    (%edi),%edx
f0101e15:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e1b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e1e:	29 c1                	sub    %eax,%ecx
f0101e20:	89 c8                	mov    %ecx,%eax
f0101e22:	c1 f8 03             	sar    $0x3,%eax
f0101e25:	c1 e0 0c             	shl    $0xc,%eax
f0101e28:	39 c2                	cmp    %eax,%edx
f0101e2a:	74 24                	je     f0101e50 <mem_init+0x8b3>
f0101e2c:	c7 44 24 0c a4 70 10 	movl   $0xf01070a4,0xc(%esp)
f0101e33:	f0 
f0101e34:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101e3b:	f0 
f0101e3c:	c7 44 24 04 fc 03 00 	movl   $0x3fc,0x4(%esp)
f0101e43:	00 
f0101e44:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101e4b:	e8 f0 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e50:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e55:	89 f8                	mov    %edi,%eax
f0101e57:	e8 f9 ed ff ff       	call   f0100c55 <check_va2pa>
f0101e5c:	89 da                	mov    %ebx,%edx
f0101e5e:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101e61:	c1 fa 03             	sar    $0x3,%edx
f0101e64:	c1 e2 0c             	shl    $0xc,%edx
f0101e67:	39 d0                	cmp    %edx,%eax
f0101e69:	74 24                	je     f0101e8f <mem_init+0x8f2>
f0101e6b:	c7 44 24 0c cc 70 10 	movl   $0xf01070cc,0xc(%esp)
f0101e72:	f0 
f0101e73:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101e7a:	f0 
f0101e7b:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0101e82:	00 
f0101e83:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101e8a:	e8 b1 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101e8f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e94:	74 24                	je     f0101eba <mem_init+0x91d>
f0101e96:	c7 44 24 0c 94 79 10 	movl   $0xf0107994,0xc(%esp)
f0101e9d:	f0 
f0101e9e:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101ea5:	f0 
f0101ea6:	c7 44 24 04 fe 03 00 	movl   $0x3fe,0x4(%esp)
f0101ead:	00 
f0101eae:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101eb5:	e8 86 e1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101eba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ec2:	74 24                	je     f0101ee8 <mem_init+0x94b>
f0101ec4:	c7 44 24 0c a5 79 10 	movl   $0xf01079a5,0xc(%esp)
f0101ecb:	f0 
f0101ecc:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101ed3:	f0 
f0101ed4:	c7 44 24 04 ff 03 00 	movl   $0x3ff,0x4(%esp)
f0101edb:	00 
f0101edc:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101ee3:	e8 58 e1 ff ff       	call   f0100040 <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ee8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eef:	00 
f0101ef0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ef7:	00 
f0101ef8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101efc:	89 3c 24             	mov    %edi,(%esp)
f0101eff:	e8 77 f5 ff ff       	call   f010147b <page_insert>
f0101f04:	85 c0                	test   %eax,%eax
f0101f06:	74 24                	je     f0101f2c <mem_init+0x98f>
f0101f08:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0101f0f:	f0 
f0101f10:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101f17:	f0 
f0101f18:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
f0101f1f:	00 
f0101f20:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101f27:	e8 14 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f2c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f31:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101f36:	e8 1a ed ff ff       	call   f0100c55 <check_va2pa>
f0101f3b:	89 f2                	mov    %esi,%edx
f0101f3d:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0101f43:	c1 fa 03             	sar    $0x3,%edx
f0101f46:	c1 e2 0c             	shl    $0xc,%edx
f0101f49:	39 d0                	cmp    %edx,%eax
f0101f4b:	74 24                	je     f0101f71 <mem_init+0x9d4>
f0101f4d:	c7 44 24 0c 38 71 10 	movl   $0xf0107138,0xc(%esp)
f0101f54:	f0 
f0101f55:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101f5c:	f0 
f0101f5d:	c7 44 24 04 02 04 00 	movl   $0x402,0x4(%esp)
f0101f64:	00 
f0101f65:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101f6c:	e8 cf e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101f71:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f76:	74 24                	je     f0101f9c <mem_init+0x9ff>
f0101f78:	c7 44 24 0c b6 79 10 	movl   $0xf01079b6,0xc(%esp)
f0101f7f:	f0 
f0101f80:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101f87:	f0 
f0101f88:	c7 44 24 04 03 04 00 	movl   $0x403,0x4(%esp)
f0101f8f:	00 
f0101f90:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101f97:	e8 a4 e0 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f9c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fa3:	e8 c9 f1 ff ff       	call   f0101171 <page_alloc>
f0101fa8:	85 c0                	test   %eax,%eax
f0101faa:	74 24                	je     f0101fd0 <mem_init+0xa33>
f0101fac:	c7 44 24 0c 42 79 10 	movl   $0xf0107942,0xc(%esp)
f0101fb3:	f0 
f0101fb4:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0101fbb:	f0 
f0101fbc:	c7 44 24 04 06 04 00 	movl   $0x406,0x4(%esp)
f0101fc3:	00 
f0101fc4:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0101fcb:	e8 70 e0 ff ff       	call   f0100040 <_panic>
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101fd0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fd7:	00 
f0101fd8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fdf:	00 
f0101fe0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101fe4:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101fe9:	89 04 24             	mov    %eax,(%esp)
f0101fec:	e8 8a f4 ff ff       	call   f010147b <page_insert>
f0101ff1:	85 c0                	test   %eax,%eax
f0101ff3:	74 24                	je     f0102019 <mem_init+0xa7c>
f0101ff5:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0101ffc:	f0 
f0101ffd:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102004:	f0 
f0102005:	c7 44 24 04 08 04 00 	movl   $0x408,0x4(%esp)
f010200c:	00 
f010200d:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102014:	e8 27 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102019:	ba 00 10 00 00       	mov    $0x1000,%edx
f010201e:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102023:	e8 2d ec ff ff       	call   f0100c55 <check_va2pa>
f0102028:	89 f2                	mov    %esi,%edx
f010202a:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0102030:	c1 fa 03             	sar    $0x3,%edx
f0102033:	c1 e2 0c             	shl    $0xc,%edx
f0102036:	39 d0                	cmp    %edx,%eax
f0102038:	74 24                	je     f010205e <mem_init+0xac1>
f010203a:	c7 44 24 0c 38 71 10 	movl   $0xf0107138,0xc(%esp)
f0102041:	f0 
f0102042:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102049:	f0 
f010204a:	c7 44 24 04 09 04 00 	movl   $0x409,0x4(%esp)
f0102051:	00 
f0102052:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102059:	e8 e2 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010205e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102063:	74 24                	je     f0102089 <mem_init+0xaec>
f0102065:	c7 44 24 0c b6 79 10 	movl   $0xf01079b6,0xc(%esp)
f010206c:	f0 
f010206d:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102074:	f0 
f0102075:	c7 44 24 04 0a 04 00 	movl   $0x40a,0x4(%esp)
f010207c:	00 
f010207d:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102084:	e8 b7 df ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102089:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102090:	e8 dc f0 ff ff       	call   f0101171 <page_alloc>
f0102095:	85 c0                	test   %eax,%eax
f0102097:	74 24                	je     f01020bd <mem_init+0xb20>
f0102099:	c7 44 24 0c 42 79 10 	movl   $0xf0107942,0xc(%esp)
f01020a0:	f0 
f01020a1:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01020a8:	f0 
f01020a9:	c7 44 24 04 0e 04 00 	movl   $0x40e,0x4(%esp)
f01020b0:	00 
f01020b1:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01020b8:	e8 83 df ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01020bd:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f01020c3:	8b 02                	mov    (%edx),%eax
f01020c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01020ca:	89 c1                	mov    %eax,%ecx
f01020cc:	c1 e9 0c             	shr    $0xc,%ecx
f01020cf:	3b 0d 88 be 22 f0    	cmp    0xf022be88,%ecx
f01020d5:	72 20                	jb     f01020f7 <mem_init+0xb5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01020d7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01020db:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f01020e2:	f0 
f01020e3:	c7 44 24 04 11 04 00 	movl   $0x411,0x4(%esp)
f01020ea:	00 
f01020eb:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01020f2:	e8 49 df ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01020f7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01020ff:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102106:	00 
f0102107:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010210e:	00 
f010210f:	89 14 24             	mov    %edx,(%esp)
f0102112:	e8 64 f1 ff ff       	call   f010127b <pgdir_walk>
f0102117:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010211a:	8d 51 04             	lea    0x4(%ecx),%edx
f010211d:	39 d0                	cmp    %edx,%eax
f010211f:	74 24                	je     f0102145 <mem_init+0xba8>
f0102121:	c7 44 24 0c 68 71 10 	movl   $0xf0107168,0xc(%esp)
f0102128:	f0 
f0102129:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102130:	f0 
f0102131:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f0102138:	00 
f0102139:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102140:	e8 fb de ff ff       	call   f0100040 <_panic>
	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102145:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010214c:	00 
f010214d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102154:	00 
f0102155:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102159:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010215e:	89 04 24             	mov    %eax,(%esp)
f0102161:	e8 15 f3 ff ff       	call   f010147b <page_insert>
f0102166:	85 c0                	test   %eax,%eax
f0102168:	74 24                	je     f010218e <mem_init+0xbf1>
f010216a:	c7 44 24 0c a8 71 10 	movl   $0xf01071a8,0xc(%esp)
f0102171:	f0 
f0102172:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102179:	f0 
f010217a:	c7 44 24 04 14 04 00 	movl   $0x414,0x4(%esp)
f0102181:	00 
f0102182:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102189:	e8 b2 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010218e:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102194:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102199:	89 f8                	mov    %edi,%eax
f010219b:	e8 b5 ea ff ff       	call   f0100c55 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f01021a0:	89 f2                	mov    %esi,%edx
f01021a2:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01021a8:	c1 fa 03             	sar    $0x3,%edx
f01021ab:	c1 e2 0c             	shl    $0xc,%edx
f01021ae:	39 d0                	cmp    %edx,%eax
f01021b0:	74 24                	je     f01021d6 <mem_init+0xc39>
f01021b2:	c7 44 24 0c 38 71 10 	movl   $0xf0107138,0xc(%esp)
f01021b9:	f0 
f01021ba:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01021c1:	f0 
f01021c2:	c7 44 24 04 15 04 00 	movl   $0x415,0x4(%esp)
f01021c9:	00 
f01021ca:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01021d1:	e8 6a de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01021d6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01021db:	74 24                	je     f0102201 <mem_init+0xc64>
f01021dd:	c7 44 24 0c b6 79 10 	movl   $0xf01079b6,0xc(%esp)
f01021e4:	f0 
f01021e5:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01021ec:	f0 
f01021ed:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f01021f4:	00 
f01021f5:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01021fc:	e8 3f de ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102201:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102208:	00 
f0102209:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102210:	00 
f0102211:	89 3c 24             	mov    %edi,(%esp)
f0102214:	e8 62 f0 ff ff       	call   f010127b <pgdir_walk>
f0102219:	f6 00 04             	testb  $0x4,(%eax)
f010221c:	75 24                	jne    f0102242 <mem_init+0xca5>
f010221e:	c7 44 24 0c e8 71 10 	movl   $0xf01071e8,0xc(%esp)
f0102225:	f0 
f0102226:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010222d:	f0 
f010222e:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f0102235:	00 
f0102236:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010223d:	e8 fe dd ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102242:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102247:	f6 00 04             	testb  $0x4,(%eax)
f010224a:	75 24                	jne    f0102270 <mem_init+0xcd3>
f010224c:	c7 44 24 0c c7 79 10 	movl   $0xf01079c7,0xc(%esp)
f0102253:	f0 
f0102254:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010225b:	f0 
f010225c:	c7 44 24 04 18 04 00 	movl   $0x418,0x4(%esp)
f0102263:	00 
f0102264:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010226b:	e8 d0 dd ff ff       	call   f0100040 <_panic>
	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102270:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102277:	00 
f0102278:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010227f:	00 
f0102280:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102284:	89 04 24             	mov    %eax,(%esp)
f0102287:	e8 ef f1 ff ff       	call   f010147b <page_insert>
f010228c:	85 c0                	test   %eax,%eax
f010228e:	74 24                	je     f01022b4 <mem_init+0xd17>
f0102290:	c7 44 24 0c fc 70 10 	movl   $0xf01070fc,0xc(%esp)
f0102297:	f0 
f0102298:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010229f:	f0 
f01022a0:	c7 44 24 04 1a 04 00 	movl   $0x41a,0x4(%esp)
f01022a7:	00 
f01022a8:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01022af:	e8 8c dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01022b4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022bb:	00 
f01022bc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022c3:	00 
f01022c4:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01022c9:	89 04 24             	mov    %eax,(%esp)
f01022cc:	e8 aa ef ff ff       	call   f010127b <pgdir_walk>
f01022d1:	f6 00 02             	testb  $0x2,(%eax)
f01022d4:	75 24                	jne    f01022fa <mem_init+0xd5d>
f01022d6:	c7 44 24 0c 1c 72 10 	movl   $0xf010721c,0xc(%esp)
f01022dd:	f0 
f01022de:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01022e5:	f0 
f01022e6:	c7 44 24 04 1b 04 00 	movl   $0x41b,0x4(%esp)
f01022ed:	00 
f01022ee:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01022f5:	e8 46 dd ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022fa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102301:	00 
f0102302:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102309:	00 
f010230a:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010230f:	89 04 24             	mov    %eax,(%esp)
f0102312:	e8 64 ef ff ff       	call   f010127b <pgdir_walk>
f0102317:	f6 00 04             	testb  $0x4,(%eax)
f010231a:	74 24                	je     f0102340 <mem_init+0xda3>
f010231c:	c7 44 24 0c 50 72 10 	movl   $0xf0107250,0xc(%esp)
f0102323:	f0 
f0102324:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010232b:	f0 
f010232c:	c7 44 24 04 1c 04 00 	movl   $0x41c,0x4(%esp)
f0102333:	00 
f0102334:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010233b:	e8 00 dd ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102340:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102347:	00 
f0102348:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f010234f:	00 
f0102350:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102353:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102357:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010235c:	89 04 24             	mov    %eax,(%esp)
f010235f:	e8 17 f1 ff ff       	call   f010147b <page_insert>
f0102364:	85 c0                	test   %eax,%eax
f0102366:	78 24                	js     f010238c <mem_init+0xdef>
f0102368:	c7 44 24 0c 88 72 10 	movl   $0xf0107288,0xc(%esp)
f010236f:	f0 
f0102370:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102377:	f0 
f0102378:	c7 44 24 04 1f 04 00 	movl   $0x41f,0x4(%esp)
f010237f:	00 
f0102380:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102387:	e8 b4 dc ff ff       	call   f0100040 <_panic>
	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010238c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102393:	00 
f0102394:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010239b:	00 
f010239c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023a0:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01023a5:	89 04 24             	mov    %eax,(%esp)
f01023a8:	e8 ce f0 ff ff       	call   f010147b <page_insert>
f01023ad:	85 c0                	test   %eax,%eax
f01023af:	74 24                	je     f01023d5 <mem_init+0xe38>
f01023b1:	c7 44 24 0c c0 72 10 	movl   $0xf01072c0,0xc(%esp)
f01023b8:	f0 
f01023b9:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01023c0:	f0 
f01023c1:	c7 44 24 04 21 04 00 	movl   $0x421,0x4(%esp)
f01023c8:	00 
f01023c9:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01023d0:	e8 6b dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01023d5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01023dc:	00 
f01023dd:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01023e4:	00 
f01023e5:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01023ea:	89 04 24             	mov    %eax,(%esp)
f01023ed:	e8 89 ee ff ff       	call   f010127b <pgdir_walk>
f01023f2:	f6 00 04             	testb  $0x4,(%eax)
f01023f5:	74 24                	je     f010241b <mem_init+0xe7e>
f01023f7:	c7 44 24 0c 50 72 10 	movl   $0xf0107250,0xc(%esp)
f01023fe:	f0 
f01023ff:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102406:	f0 
f0102407:	c7 44 24 04 22 04 00 	movl   $0x422,0x4(%esp)
f010240e:	00 
f010240f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102416:	e8 25 dc ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010241b:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102421:	ba 00 00 00 00       	mov    $0x0,%edx
f0102426:	89 f8                	mov    %edi,%eax
f0102428:	e8 28 e8 ff ff       	call   f0100c55 <check_va2pa>
f010242d:	89 c1                	mov    %eax,%ecx
f010242f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102432:	89 d8                	mov    %ebx,%eax
f0102434:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f010243a:	c1 f8 03             	sar    $0x3,%eax
f010243d:	c1 e0 0c             	shl    $0xc,%eax
f0102440:	39 c1                	cmp    %eax,%ecx
f0102442:	74 24                	je     f0102468 <mem_init+0xecb>
f0102444:	c7 44 24 0c fc 72 10 	movl   $0xf01072fc,0xc(%esp)
f010244b:	f0 
f010244c:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102453:	f0 
f0102454:	c7 44 24 04 25 04 00 	movl   $0x425,0x4(%esp)
f010245b:	00 
f010245c:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102463:	e8 d8 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102468:	ba 00 10 00 00       	mov    $0x1000,%edx
f010246d:	89 f8                	mov    %edi,%eax
f010246f:	e8 e1 e7 ff ff       	call   f0100c55 <check_va2pa>
f0102474:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102477:	74 24                	je     f010249d <mem_init+0xf00>
f0102479:	c7 44 24 0c 28 73 10 	movl   $0xf0107328,0xc(%esp)
f0102480:	f0 
f0102481:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102488:	f0 
f0102489:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f0102490:	00 
f0102491:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102498:	e8 a3 db ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010249d:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01024a2:	74 24                	je     f01024c8 <mem_init+0xf2b>
f01024a4:	c7 44 24 0c dd 79 10 	movl   $0xf01079dd,0xc(%esp)
f01024ab:	f0 
f01024ac:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01024b3:	f0 
f01024b4:	c7 44 24 04 28 04 00 	movl   $0x428,0x4(%esp)
f01024bb:	00 
f01024bc:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01024c3:	e8 78 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01024c8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01024cd:	74 24                	je     f01024f3 <mem_init+0xf56>
f01024cf:	c7 44 24 0c ee 79 10 	movl   $0xf01079ee,0xc(%esp)
f01024d6:	f0 
f01024d7:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01024de:	f0 
f01024df:	c7 44 24 04 29 04 00 	movl   $0x429,0x4(%esp)
f01024e6:	00 
f01024e7:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01024ee:	e8 4d db ff ff       	call   f0100040 <_panic>
	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01024f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01024fa:	e8 72 ec ff ff       	call   f0101171 <page_alloc>
f01024ff:	85 c0                	test   %eax,%eax
f0102501:	74 04                	je     f0102507 <mem_init+0xf6a>
f0102503:	39 c6                	cmp    %eax,%esi
f0102505:	74 24                	je     f010252b <mem_init+0xf8e>
f0102507:	c7 44 24 0c 58 73 10 	movl   $0xf0107358,0xc(%esp)
f010250e:	f0 
f010250f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102516:	f0 
f0102517:	c7 44 24 04 2b 04 00 	movl   $0x42b,0x4(%esp)
f010251e:	00 
f010251f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102526:	e8 15 db ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010252b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102532:	00 
f0102533:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102538:	89 04 24             	mov    %eax,(%esp)
f010253b:	e8 ea ee ff ff       	call   f010142a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102540:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102546:	ba 00 00 00 00       	mov    $0x0,%edx
f010254b:	89 f8                	mov    %edi,%eax
f010254d:	e8 03 e7 ff ff       	call   f0100c55 <check_va2pa>
f0102552:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102555:	74 24                	je     f010257b <mem_init+0xfde>
f0102557:	c7 44 24 0c 7c 73 10 	movl   $0xf010737c,0xc(%esp)
f010255e:	f0 
f010255f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102566:	f0 
f0102567:	c7 44 24 04 2f 04 00 	movl   $0x42f,0x4(%esp)
f010256e:	00 
f010256f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102576:	e8 c5 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010257b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102580:	89 f8                	mov    %edi,%eax
f0102582:	e8 ce e6 ff ff       	call   f0100c55 <check_va2pa>
f0102587:	89 da                	mov    %ebx,%edx
f0102589:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f010258f:	c1 fa 03             	sar    $0x3,%edx
f0102592:	c1 e2 0c             	shl    $0xc,%edx
f0102595:	39 d0                	cmp    %edx,%eax
f0102597:	74 24                	je     f01025bd <mem_init+0x1020>
f0102599:	c7 44 24 0c 28 73 10 	movl   $0xf0107328,0xc(%esp)
f01025a0:	f0 
f01025a1:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01025a8:	f0 
f01025a9:	c7 44 24 04 30 04 00 	movl   $0x430,0x4(%esp)
f01025b0:	00 
f01025b1:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01025b8:	e8 83 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01025bd:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025c2:	74 24                	je     f01025e8 <mem_init+0x104b>
f01025c4:	c7 44 24 0c 94 79 10 	movl   $0xf0107994,0xc(%esp)
f01025cb:	f0 
f01025cc:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01025d3:	f0 
f01025d4:	c7 44 24 04 31 04 00 	movl   $0x431,0x4(%esp)
f01025db:	00 
f01025dc:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01025e3:	e8 58 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01025e8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025ed:	74 24                	je     f0102613 <mem_init+0x1076>
f01025ef:	c7 44 24 0c ee 79 10 	movl   $0xf01079ee,0xc(%esp)
f01025f6:	f0 
f01025f7:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01025fe:	f0 
f01025ff:	c7 44 24 04 32 04 00 	movl   $0x432,0x4(%esp)
f0102606:	00 
f0102607:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010260e:	e8 2d da ff ff       	call   f0100040 <_panic>
	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102613:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010261a:	00 
f010261b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102622:	00 
f0102623:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102627:	89 3c 24             	mov    %edi,(%esp)
f010262a:	e8 4c ee ff ff       	call   f010147b <page_insert>
f010262f:	85 c0                	test   %eax,%eax
f0102631:	74 24                	je     f0102657 <mem_init+0x10ba>
f0102633:	c7 44 24 0c a0 73 10 	movl   $0xf01073a0,0xc(%esp)
f010263a:	f0 
f010263b:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102642:	f0 
f0102643:	c7 44 24 04 34 04 00 	movl   $0x434,0x4(%esp)
f010264a:	00 
f010264b:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102652:	e8 e9 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102657:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010265c:	75 24                	jne    f0102682 <mem_init+0x10e5>
f010265e:	c7 44 24 0c ff 79 10 	movl   $0xf01079ff,0xc(%esp)
f0102665:	f0 
f0102666:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010266d:	f0 
f010266e:	c7 44 24 04 35 04 00 	movl   $0x435,0x4(%esp)
f0102675:	00 
f0102676:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010267d:	e8 be d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102682:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102685:	74 24                	je     f01026ab <mem_init+0x110e>
f0102687:	c7 44 24 0c 0b 7a 10 	movl   $0xf0107a0b,0xc(%esp)
f010268e:	f0 
f010268f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102696:	f0 
f0102697:	c7 44 24 04 36 04 00 	movl   $0x436,0x4(%esp)
f010269e:	00 
f010269f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01026a6:	e8 95 d9 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026ab:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026b2:	00 
f01026b3:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01026b8:	89 04 24             	mov    %eax,(%esp)
f01026bb:	e8 6a ed ff ff       	call   f010142a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026c0:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f01026c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01026cb:	89 f8                	mov    %edi,%eax
f01026cd:	e8 83 e5 ff ff       	call   f0100c55 <check_va2pa>
f01026d2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01026d5:	74 24                	je     f01026fb <mem_init+0x115e>
f01026d7:	c7 44 24 0c 7c 73 10 	movl   $0xf010737c,0xc(%esp)
f01026de:	f0 
f01026df:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01026e6:	f0 
f01026e7:	c7 44 24 04 3a 04 00 	movl   $0x43a,0x4(%esp)
f01026ee:	00 
f01026ef:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01026f6:	e8 45 d9 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01026fb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102700:	89 f8                	mov    %edi,%eax
f0102702:	e8 4e e5 ff ff       	call   f0100c55 <check_va2pa>
f0102707:	83 f8 ff             	cmp    $0xffffffff,%eax
f010270a:	74 24                	je     f0102730 <mem_init+0x1193>
f010270c:	c7 44 24 0c d8 73 10 	movl   $0xf01073d8,0xc(%esp)
f0102713:	f0 
f0102714:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010271b:	f0 
f010271c:	c7 44 24 04 3b 04 00 	movl   $0x43b,0x4(%esp)
f0102723:	00 
f0102724:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010272b:	e8 10 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102730:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102735:	74 24                	je     f010275b <mem_init+0x11be>
f0102737:	c7 44 24 0c 20 7a 10 	movl   $0xf0107a20,0xc(%esp)
f010273e:	f0 
f010273f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102746:	f0 
f0102747:	c7 44 24 04 3c 04 00 	movl   $0x43c,0x4(%esp)
f010274e:	00 
f010274f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102756:	e8 e5 d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010275b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102760:	74 24                	je     f0102786 <mem_init+0x11e9>
f0102762:	c7 44 24 0c ee 79 10 	movl   $0xf01079ee,0xc(%esp)
f0102769:	f0 
f010276a:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102771:	f0 
f0102772:	c7 44 24 04 3d 04 00 	movl   $0x43d,0x4(%esp)
f0102779:	00 
f010277a:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102781:	e8 ba d8 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102786:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010278d:	e8 df e9 ff ff       	call   f0101171 <page_alloc>
f0102792:	85 c0                	test   %eax,%eax
f0102794:	74 04                	je     f010279a <mem_init+0x11fd>
f0102796:	39 c3                	cmp    %eax,%ebx
f0102798:	74 24                	je     f01027be <mem_init+0x1221>
f010279a:	c7 44 24 0c 00 74 10 	movl   $0xf0107400,0xc(%esp)
f01027a1:	f0 
f01027a2:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01027a9:	f0 
f01027aa:	c7 44 24 04 40 04 00 	movl   $0x440,0x4(%esp)
f01027b1:	00 
f01027b2:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01027b9:	e8 82 d8 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01027be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027c5:	e8 a7 e9 ff ff       	call   f0101171 <page_alloc>
f01027ca:	85 c0                	test   %eax,%eax
f01027cc:	74 24                	je     f01027f2 <mem_init+0x1255>
f01027ce:	c7 44 24 0c 42 79 10 	movl   $0xf0107942,0xc(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01027dd:	f0 
f01027de:	c7 44 24 04 43 04 00 	movl   $0x443,0x4(%esp)
f01027e5:	00 
f01027e6:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01027ed:	e8 4e d8 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027f2:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01027f7:	8b 08                	mov    (%eax),%ecx
f01027f9:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01027ff:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102802:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0102808:	c1 fa 03             	sar    $0x3,%edx
f010280b:	c1 e2 0c             	shl    $0xc,%edx
f010280e:	39 d1                	cmp    %edx,%ecx
f0102810:	74 24                	je     f0102836 <mem_init+0x1299>
f0102812:	c7 44 24 0c a4 70 10 	movl   $0xf01070a4,0xc(%esp)
f0102819:	f0 
f010281a:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102821:	f0 
f0102822:	c7 44 24 04 46 04 00 	movl   $0x446,0x4(%esp)
f0102829:	00 
f010282a:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102831:	e8 0a d8 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102836:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010283c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010283f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102844:	74 24                	je     f010286a <mem_init+0x12cd>
f0102846:	c7 44 24 0c a5 79 10 	movl   $0xf01079a5,0xc(%esp)
f010284d:	f0 
f010284e:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102855:	f0 
f0102856:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f010285d:	00 
f010285e:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102865:	e8 d6 d7 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010286a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010286d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102873:	89 04 24             	mov    %eax,(%esp)
f0102876:	e8 81 e9 ff ff       	call   f01011fc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010287b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102882:	00 
f0102883:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010288a:	00 
f010288b:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102890:	89 04 24             	mov    %eax,(%esp)
f0102893:	e8 e3 e9 ff ff       	call   f010127b <pgdir_walk>
f0102898:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010289b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010289e:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f01028a4:	8b 7a 04             	mov    0x4(%edx),%edi
f01028a7:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	if (PGNUM(pa) >= npages)
f01028ad:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f01028b3:	89 f8                	mov    %edi,%eax
f01028b5:	c1 e8 0c             	shr    $0xc,%eax
f01028b8:	39 c8                	cmp    %ecx,%eax
f01028ba:	72 20                	jb     f01028dc <mem_init+0x133f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028bc:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01028c0:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f01028c7:	f0 
f01028c8:	c7 44 24 04 4f 04 00 	movl   $0x44f,0x4(%esp)
f01028cf:	00 
f01028d0:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01028d7:	e8 64 d7 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01028dc:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01028e2:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01028e5:	74 24                	je     f010290b <mem_init+0x136e>
f01028e7:	c7 44 24 0c 31 7a 10 	movl   $0xf0107a31,0xc(%esp)
f01028ee:	f0 
f01028ef:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01028f6:	f0 
f01028f7:	c7 44 24 04 50 04 00 	movl   $0x450,0x4(%esp)
f01028fe:	00 
f01028ff:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102906:	e8 35 d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010290b:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102912:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102915:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010291b:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0102921:	c1 f8 03             	sar    $0x3,%eax
f0102924:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102927:	89 c2                	mov    %eax,%edx
f0102929:	c1 ea 0c             	shr    $0xc,%edx
f010292c:	39 d1                	cmp    %edx,%ecx
f010292e:	77 20                	ja     f0102950 <mem_init+0x13b3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102930:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102934:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f010293b:	f0 
f010293c:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102943:	00 
f0102944:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f010294b:	e8 f0 d6 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102950:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102957:	00 
f0102958:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010295f:	00 
	return (void *)(pa + KERNBASE);
f0102960:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102965:	89 04 24             	mov    %eax,(%esp)
f0102968:	e8 9a 31 00 00       	call   f0105b07 <memset>
	page_free(pp0);
f010296d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102970:	89 3c 24             	mov    %edi,(%esp)
f0102973:	e8 84 e8 ff ff       	call   f01011fc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102978:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010297f:	00 
f0102980:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102987:	00 
f0102988:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010298d:	89 04 24             	mov    %eax,(%esp)
f0102990:	e8 e6 e8 ff ff       	call   f010127b <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102995:	89 fa                	mov    %edi,%edx
f0102997:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f010299d:	c1 fa 03             	sar    $0x3,%edx
f01029a0:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01029a3:	89 d0                	mov    %edx,%eax
f01029a5:	c1 e8 0c             	shr    $0xc,%eax
f01029a8:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f01029ae:	72 20                	jb     f01029d0 <mem_init+0x1433>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029b0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01029b4:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f01029bb:	f0 
f01029bc:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01029c3:	00 
f01029c4:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f01029cb:	e8 70 d6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01029d0:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01029d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01029d9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01029df:	f6 00 01             	testb  $0x1,(%eax)
f01029e2:	74 24                	je     f0102a08 <mem_init+0x146b>
f01029e4:	c7 44 24 0c 49 7a 10 	movl   $0xf0107a49,0xc(%esp)
f01029eb:	f0 
f01029ec:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01029f3:	f0 
f01029f4:	c7 44 24 04 5a 04 00 	movl   $0x45a,0x4(%esp)
f01029fb:	00 
f01029fc:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102a03:	e8 38 d6 ff ff       	call   f0100040 <_panic>
f0102a08:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102a0b:	39 d0                	cmp    %edx,%eax
f0102a0d:	75 d0                	jne    f01029df <mem_init+0x1442>
	kern_pgdir[0] = 0;
f0102a0f:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102a14:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102a1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a1d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102a23:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102a26:	89 0d 40 b2 22 f0    	mov    %ecx,0xf022b240

	// free the pages we took
	page_free(pp0);
f0102a2c:	89 04 24             	mov    %eax,(%esp)
f0102a2f:	e8 c8 e7 ff ff       	call   f01011fc <page_free>
	page_free(pp1);
f0102a34:	89 1c 24             	mov    %ebx,(%esp)
f0102a37:	e8 c0 e7 ff ff       	call   f01011fc <page_free>
	page_free(pp2);
f0102a3c:	89 34 24             	mov    %esi,(%esp)
f0102a3f:	e8 b8 e7 ff ff       	call   f01011fc <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102a44:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102a4b:	00 
f0102a4c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a53:	e8 92 ea ff ff       	call   f01014ea <mmio_map_region>
f0102a58:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102a5a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102a61:	00 
f0102a62:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a69:	e8 7c ea ff ff       	call   f01014ea <mmio_map_region>
f0102a6e:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0102a70:	8d 83 00 20 00 00    	lea    0x2000(%ebx),%eax
f0102a76:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102a7b:	77 08                	ja     f0102a85 <mem_init+0x14e8>
f0102a7d:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102a83:	77 24                	ja     f0102aa9 <mem_init+0x150c>
f0102a85:	c7 44 24 0c 24 74 10 	movl   $0xf0107424,0xc(%esp)
f0102a8c:	f0 
f0102a8d:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102a94:	f0 
f0102a95:	c7 44 24 04 6a 04 00 	movl   $0x46a,0x4(%esp)
f0102a9c:	00 
f0102a9d:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102aa4:	e8 97 d5 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0102aa9:	8d 96 00 20 00 00    	lea    0x2000(%esi),%edx
f0102aaf:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102ab5:	77 08                	ja     f0102abf <mem_init+0x1522>
f0102ab7:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102abd:	77 24                	ja     f0102ae3 <mem_init+0x1546>
f0102abf:	c7 44 24 0c 4c 74 10 	movl   $0xf010744c,0xc(%esp)
f0102ac6:	f0 
f0102ac7:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102ace:	f0 
f0102acf:	c7 44 24 04 6b 04 00 	movl   $0x46b,0x4(%esp)
f0102ad6:	00 
f0102ad7:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102ade:	e8 5d d5 ff ff       	call   f0100040 <_panic>
f0102ae3:	89 da                	mov    %ebx,%edx
f0102ae5:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102ae7:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102aed:	74 24                	je     f0102b13 <mem_init+0x1576>
f0102aef:	c7 44 24 0c 74 74 10 	movl   $0xf0107474,0xc(%esp)
f0102af6:	f0 
f0102af7:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102afe:	f0 
f0102aff:	c7 44 24 04 6d 04 00 	movl   $0x46d,0x4(%esp)
f0102b06:	00 
f0102b07:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102b0e:	e8 2d d5 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8192 <= mm2);
f0102b13:	39 c6                	cmp    %eax,%esi
f0102b15:	73 24                	jae    f0102b3b <mem_init+0x159e>
f0102b17:	c7 44 24 0c 60 7a 10 	movl   $0xf0107a60,0xc(%esp)
f0102b1e:	f0 
f0102b1f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102b26:	f0 
f0102b27:	c7 44 24 04 6f 04 00 	movl   $0x46f,0x4(%esp)
f0102b2e:	00 
f0102b2f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102b36:	e8 05 d5 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102b3b:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102b41:	89 da                	mov    %ebx,%edx
f0102b43:	89 f8                	mov    %edi,%eax
f0102b45:	e8 0b e1 ff ff       	call   f0100c55 <check_va2pa>
f0102b4a:	85 c0                	test   %eax,%eax
f0102b4c:	74 24                	je     f0102b72 <mem_init+0x15d5>
f0102b4e:	c7 44 24 0c 9c 74 10 	movl   $0xf010749c,0xc(%esp)
f0102b55:	f0 
f0102b56:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102b5d:	f0 
f0102b5e:	c7 44 24 04 71 04 00 	movl   $0x471,0x4(%esp)
f0102b65:	00 
f0102b66:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102b6d:	e8 ce d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102b72:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102b78:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102b7b:	89 c2                	mov    %eax,%edx
f0102b7d:	89 f8                	mov    %edi,%eax
f0102b7f:	e8 d1 e0 ff ff       	call   f0100c55 <check_va2pa>
f0102b84:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102b89:	74 24                	je     f0102baf <mem_init+0x1612>
f0102b8b:	c7 44 24 0c c0 74 10 	movl   $0xf01074c0,0xc(%esp)
f0102b92:	f0 
f0102b93:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102b9a:	f0 
f0102b9b:	c7 44 24 04 72 04 00 	movl   $0x472,0x4(%esp)
f0102ba2:	00 
f0102ba3:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102baa:	e8 91 d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102baf:	89 f2                	mov    %esi,%edx
f0102bb1:	89 f8                	mov    %edi,%eax
f0102bb3:	e8 9d e0 ff ff       	call   f0100c55 <check_va2pa>
f0102bb8:	85 c0                	test   %eax,%eax
f0102bba:	74 24                	je     f0102be0 <mem_init+0x1643>
f0102bbc:	c7 44 24 0c f0 74 10 	movl   $0xf01074f0,0xc(%esp)
f0102bc3:	f0 
f0102bc4:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102bcb:	f0 
f0102bcc:	c7 44 24 04 73 04 00 	movl   $0x473,0x4(%esp)
f0102bd3:	00 
f0102bd4:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102bdb:	e8 60 d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102be0:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102be6:	89 f8                	mov    %edi,%eax
f0102be8:	e8 68 e0 ff ff       	call   f0100c55 <check_va2pa>
f0102bed:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102bf0:	74 24                	je     f0102c16 <mem_init+0x1679>
f0102bf2:	c7 44 24 0c 14 75 10 	movl   $0xf0107514,0xc(%esp)
f0102bf9:	f0 
f0102bfa:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102c01:	f0 
f0102c02:	c7 44 24 04 74 04 00 	movl   $0x474,0x4(%esp)
f0102c09:	00 
f0102c0a:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102c11:	e8 2a d4 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102c16:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c1d:	00 
f0102c1e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c22:	89 3c 24             	mov    %edi,(%esp)
f0102c25:	e8 51 e6 ff ff       	call   f010127b <pgdir_walk>
f0102c2a:	f6 00 1a             	testb  $0x1a,(%eax)
f0102c2d:	75 24                	jne    f0102c53 <mem_init+0x16b6>
f0102c2f:	c7 44 24 0c 40 75 10 	movl   $0xf0107540,0xc(%esp)
f0102c36:	f0 
f0102c37:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102c3e:	f0 
f0102c3f:	c7 44 24 04 76 04 00 	movl   $0x476,0x4(%esp)
f0102c46:	00 
f0102c47:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102c4e:	e8 ed d3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102c53:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c5a:	00 
f0102c5b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c5f:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102c64:	89 04 24             	mov    %eax,(%esp)
f0102c67:	e8 0f e6 ff ff       	call   f010127b <pgdir_walk>
f0102c6c:	f6 00 04             	testb  $0x4,(%eax)
f0102c6f:	74 24                	je     f0102c95 <mem_init+0x16f8>
f0102c71:	c7 44 24 0c 84 75 10 	movl   $0xf0107584,0xc(%esp)
f0102c78:	f0 
f0102c79:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102c80:	f0 
f0102c81:	c7 44 24 04 77 04 00 	movl   $0x477,0x4(%esp)
f0102c88:	00 
f0102c89:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102c90:	e8 ab d3 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102c95:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c9c:	00 
f0102c9d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102ca1:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102ca6:	89 04 24             	mov    %eax,(%esp)
f0102ca9:	e8 cd e5 ff ff       	call   f010127b <pgdir_walk>
f0102cae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102cb4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102cbb:	00 
f0102cbc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cc3:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102cc8:	89 04 24             	mov    %eax,(%esp)
f0102ccb:	e8 ab e5 ff ff       	call   f010127b <pgdir_walk>
f0102cd0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102cd6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102cdd:	00 
f0102cde:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ce2:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102ce7:	89 04 24             	mov    %eax,(%esp)
f0102cea:	e8 8c e5 ff ff       	call   f010127b <pgdir_walk>
f0102cef:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102cf5:	c7 04 24 72 7a 10 f0 	movl   $0xf0107a72,(%esp)
f0102cfc:	e8 fa 12 00 00       	call   f0103ffb <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_W);
f0102d01:	a1 90 be 22 f0       	mov    0xf022be90,%eax
	if ((uint32_t)kva < KERNBASE)
f0102d06:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d0b:	77 20                	ja     f0102d2d <mem_init+0x1790>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d11:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0102d18:	f0 
f0102d19:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
f0102d20:	00 
f0102d21:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102d28:	e8 13 d3 ff ff       	call   f0100040 <_panic>
f0102d2d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d34:	00 
	return (physaddr_t)kva - KERNBASE;
f0102d35:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d3a:	89 04 24             	mov    %eax,(%esp)
f0102d3d:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102d42:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102d47:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d4c:	e8 cb e5 ff ff       	call   f010131c <boot_map_region>
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102d51:	a1 48 b2 22 f0       	mov    0xf022b248,%eax
	if ((uint32_t)kva < KERNBASE)
f0102d56:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d5b:	77 20                	ja     f0102d7d <mem_init+0x17e0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d5d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d61:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0102d68:	f0 
f0102d69:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f0102d70:	00 
f0102d71:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102d78:	e8 c3 d2 ff ff       	call   f0100040 <_panic>
f0102d7d:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102d84:	00 
	return (physaddr_t)kva - KERNBASE;
f0102d85:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d8a:	89 04 24             	mov    %eax,(%esp)
f0102d8d:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102d92:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102d97:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d9c:	e8 7b e5 ff ff       	call   f010131c <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102da1:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102da6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dab:	77 20                	ja     f0102dcd <mem_init+0x1830>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dad:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102db1:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0102db8:	f0 
f0102db9:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0102dc0:	00 
f0102dc1:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102dc8:	e8 73 d2 ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir, (KSTACKTOP - KSTKSIZE), KSTKSIZE, PADDR(bootstack) , PTE_W);
f0102dcd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102dd4:	00 
f0102dd5:	c7 04 24 00 60 11 00 	movl   $0x116000,(%esp)
f0102ddc:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102de1:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102de6:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102deb:	e8 2c e5 ff ff       	call   f010131c <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, endpoint, 0, PTE_W);
f0102df0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102df7:	00 
f0102df8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102dff:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e04:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e09:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102e0e:	e8 09 e5 ff ff       	call   f010131c <boot_map_region>
f0102e13:	bf 00 d0 26 f0       	mov    $0xf026d000,%edi
f0102e18:	bb 00 d0 22 f0       	mov    $0xf022d000,%ebx
f0102e1d:	be 00 80 ff ef       	mov    $0xefff8000,%esi
	if ((uint32_t)kva < KERNBASE)
f0102e22:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102e28:	77 20                	ja     f0102e4a <mem_init+0x18ad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e2a:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102e2e:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0102e35:	f0 
f0102e36:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
f0102e3d:	00 
f0102e3e:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102e45:	e8 f6 d1 ff ff       	call   f0100040 <_panic>
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W | PTE_P);
f0102e4a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e51:	00 
f0102e52:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102e58:	89 04 24             	mov    %eax,(%esp)
f0102e5b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e60:	89 f2                	mov    %esi,%edx
f0102e62:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102e67:	e8 b0 e4 ff ff       	call   f010131c <boot_map_region>
f0102e6c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102e72:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for (int i = 0; i < NCPU; i++)
f0102e78:	39 fb                	cmp    %edi,%ebx
f0102e7a:	75 a6                	jne    f0102e22 <mem_init+0x1885>
	pgdir = kern_pgdir;
f0102e7c:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102e82:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0102e87:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102e8a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102e91:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e96:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102e99:	8b 35 90 be 22 f0    	mov    0xf022be90,%esi
	if ((uint32_t)kva < KERNBASE)
f0102e9f:	89 75 cc             	mov    %esi,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102ea2:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102ea8:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102eab:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102eb0:	eb 6a                	jmp    f0102f1c <mem_init+0x197f>
f0102eb2:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102eb8:	89 f8                	mov    %edi,%eax
f0102eba:	e8 96 dd ff ff       	call   f0100c55 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102ebf:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102ec6:	77 20                	ja     f0102ee8 <mem_init+0x194b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ec8:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102ecc:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0102ed3:	f0 
f0102ed4:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102edb:	00 
f0102edc:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102ee3:	e8 58 d1 ff ff       	call   f0100040 <_panic>
f0102ee8:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102eeb:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102eee:	39 d0                	cmp    %edx,%eax
f0102ef0:	74 24                	je     f0102f16 <mem_init+0x1979>
f0102ef2:	c7 44 24 0c b8 75 10 	movl   $0xf01075b8,0xc(%esp)
f0102ef9:	f0 
f0102efa:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102f01:	f0 
f0102f02:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102f09:	00 
f0102f0a:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102f11:	e8 2a d1 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102f16:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f1c:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102f1f:	77 91                	ja     f0102eb2 <mem_init+0x1915>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102f21:	8b 1d 48 b2 22 f0    	mov    0xf022b248,%ebx
	if ((uint32_t)kva < KERNBASE)
f0102f27:	89 de                	mov    %ebx,%esi
f0102f29:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102f2e:	89 f8                	mov    %edi,%eax
f0102f30:	e8 20 dd ff ff       	call   f0100c55 <check_va2pa>
f0102f35:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102f3b:	77 20                	ja     f0102f5d <mem_init+0x19c0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f3d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102f41:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0102f48:	f0 
f0102f49:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102f50:	00 
f0102f51:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102f58:	e8 e3 d0 ff ff       	call   f0100040 <_panic>
	if ((uint32_t)kva < KERNBASE)
f0102f5d:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102f62:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102f68:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102f6b:	39 d0                	cmp    %edx,%eax
f0102f6d:	74 24                	je     f0102f93 <mem_init+0x19f6>
f0102f6f:	c7 44 24 0c ec 75 10 	movl   $0xf01075ec,0xc(%esp)
f0102f76:	f0 
f0102f77:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102f7e:	f0 
f0102f7f:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102f86:	00 
f0102f87:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102f8e:	e8 ad d0 ff ff       	call   f0100040 <_panic>
f0102f93:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
f0102f99:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102f9f:	0f 85 a8 05 00 00    	jne    f010354d <mem_init+0x1fb0>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102fa5:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102fa8:	c1 e6 0c             	shl    $0xc,%esi
f0102fab:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102fb0:	eb 3b                	jmp    f0102fed <mem_init+0x1a50>
f0102fb2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102fb8:	89 f8                	mov    %edi,%eax
f0102fba:	e8 96 dc ff ff       	call   f0100c55 <check_va2pa>
f0102fbf:	39 c3                	cmp    %eax,%ebx
f0102fc1:	74 24                	je     f0102fe7 <mem_init+0x1a4a>
f0102fc3:	c7 44 24 0c 20 76 10 	movl   $0xf0107620,0xc(%esp)
f0102fca:	f0 
f0102fcb:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0102fd2:	f0 
f0102fd3:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102fda:	00 
f0102fdb:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0102fe2:	e8 59 d0 ff ff       	call   f0100040 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102fe7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102fed:	39 f3                	cmp    %esi,%ebx
f0102fef:	72 c1                	jb     f0102fb2 <mem_init+0x1a15>
f0102ff1:	c7 45 d0 00 d0 22 f0 	movl   $0xf022d000,-0x30(%ebp)
f0102ff8:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0102fff:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0103004:	b8 00 d0 22 f0       	mov    $0xf022d000,%eax
f0103009:	05 00 80 00 20       	add    $0x20008000,%eax
f010300e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103011:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0103017:	89 45 cc             	mov    %eax,-0x34(%ebp)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010301a:	89 f2                	mov    %esi,%edx
f010301c:	89 f8                	mov    %edi,%eax
f010301e:	e8 32 dc ff ff       	call   f0100c55 <check_va2pa>
f0103023:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103026:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f010302c:	77 20                	ja     f010304e <mem_init+0x1ab1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010302e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103032:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0103039:	f0 
f010303a:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0103041:	00 
f0103042:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103049:	e8 f2 cf ff ff       	call   f0100040 <_panic>
	if ((uint32_t)kva < KERNBASE)
f010304e:	89 f3                	mov    %esi,%ebx
f0103050:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103053:	03 4d d4             	add    -0x2c(%ebp),%ecx
f0103056:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103059:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010305c:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f010305f:	39 c2                	cmp    %eax,%edx
f0103061:	74 24                	je     f0103087 <mem_init+0x1aea>
f0103063:	c7 44 24 0c 48 76 10 	movl   $0xf0107648,0xc(%esp)
f010306a:	f0 
f010306b:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103072:	f0 
f0103073:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f010307a:	00 
f010307b:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103082:	e8 b9 cf ff ff       	call   f0100040 <_panic>
f0103087:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010308d:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f0103090:	0f 85 a9 04 00 00    	jne    f010353f <mem_init+0x1fa2>
f0103096:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + i) == ~0);
f010309c:	89 da                	mov    %ebx,%edx
f010309e:	89 f8                	mov    %edi,%eax
f01030a0:	e8 b0 db ff ff       	call   f0100c55 <check_va2pa>
f01030a5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01030a8:	74 24                	je     f01030ce <mem_init+0x1b31>
f01030aa:	c7 44 24 0c 90 76 10 	movl   $0xf0107690,0xc(%esp)
f01030b1:	f0 
f01030b2:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01030b9:	f0 
f01030ba:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f01030c1:	00 
f01030c2:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01030c9:	e8 72 cf ff ff       	call   f0100040 <_panic>
f01030ce:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f01030d4:	39 de                	cmp    %ebx,%esi
f01030d6:	75 c4                	jne    f010309c <mem_init+0x1aff>
f01030d8:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f01030de:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f01030e5:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (n = 0; n < NCPU; n++) {
f01030ec:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f01030f2:	0f 85 19 ff ff ff    	jne    f0103011 <mem_init+0x1a74>
f01030f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01030fd:	e9 c2 00 00 00       	jmp    f01031c4 <mem_init+0x1c27>
		switch (i) {
f0103102:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0103108:	83 fa 04             	cmp    $0x4,%edx
f010310b:	77 2e                	ja     f010313b <mem_init+0x1b9e>
			assert(pgdir[i] & PTE_P);
f010310d:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0103111:	0f 85 aa 00 00 00    	jne    f01031c1 <mem_init+0x1c24>
f0103117:	c7 44 24 0c 8b 7a 10 	movl   $0xf0107a8b,0xc(%esp)
f010311e:	f0 
f010311f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103126:	f0 
f0103127:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f010312e:	00 
f010312f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103136:	e8 05 cf ff ff       	call   f0100040 <_panic>
			if (i >= PDX(KERNBASE)) {
f010313b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103140:	76 55                	jbe    f0103197 <mem_init+0x1bfa>
				assert(pgdir[i] & PTE_P);
f0103142:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103145:	f6 c2 01             	test   $0x1,%dl
f0103148:	75 24                	jne    f010316e <mem_init+0x1bd1>
f010314a:	c7 44 24 0c 8b 7a 10 	movl   $0xf0107a8b,0xc(%esp)
f0103151:	f0 
f0103152:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103159:	f0 
f010315a:	c7 44 24 04 bc 03 00 	movl   $0x3bc,0x4(%esp)
f0103161:	00 
f0103162:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103169:	e8 d2 ce ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010316e:	f6 c2 02             	test   $0x2,%dl
f0103171:	75 4e                	jne    f01031c1 <mem_init+0x1c24>
f0103173:	c7 44 24 0c 9c 7a 10 	movl   $0xf0107a9c,0xc(%esp)
f010317a:	f0 
f010317b:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103182:	f0 
f0103183:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f010318a:	00 
f010318b:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103192:	e8 a9 ce ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0103197:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010319b:	74 24                	je     f01031c1 <mem_init+0x1c24>
f010319d:	c7 44 24 0c ad 7a 10 	movl   $0xf0107aad,0xc(%esp)
f01031a4:	f0 
f01031a5:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01031ac:	f0 
f01031ad:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f01031b4:	00 
f01031b5:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01031bc:	e8 7f ce ff ff       	call   f0100040 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
f01031c1:	83 c0 01             	add    $0x1,%eax
f01031c4:	3d 00 04 00 00       	cmp    $0x400,%eax
f01031c9:	0f 85 33 ff ff ff    	jne    f0103102 <mem_init+0x1b65>
	cprintf("check_kern_pgdir() succeeded!\n");
f01031cf:	c7 04 24 b4 76 10 f0 	movl   $0xf01076b4,(%esp)
f01031d6:	e8 20 0e 00 00       	call   f0103ffb <cprintf>
	lcr3(PADDR(kern_pgdir));
f01031db:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01031e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031e5:	77 20                	ja     f0103207 <mem_init+0x1c6a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031eb:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f01031f2:	f0 
f01031f3:	c7 44 24 04 ef 00 00 	movl   $0xef,0x4(%esp)
f01031fa:	00 
f01031fb:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103202:	e8 39 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103207:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010320c:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f010320f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103214:	e8 ab da ff ff       	call   f0100cc4 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0103219:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f010321c:	83 e0 f3             	and    $0xfffffff3,%eax
f010321f:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0103224:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0103227:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010322e:	e8 3e df ff ff       	call   f0101171 <page_alloc>
f0103233:	89 c3                	mov    %eax,%ebx
f0103235:	85 c0                	test   %eax,%eax
f0103237:	75 24                	jne    f010325d <mem_init+0x1cc0>
f0103239:	c7 44 24 0c 97 78 10 	movl   $0xf0107897,0xc(%esp)
f0103240:	f0 
f0103241:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103248:	f0 
f0103249:	c7 44 24 04 8c 04 00 	movl   $0x48c,0x4(%esp)
f0103250:	00 
f0103251:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103258:	e8 e3 cd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010325d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103264:	e8 08 df ff ff       	call   f0101171 <page_alloc>
f0103269:	89 c7                	mov    %eax,%edi
f010326b:	85 c0                	test   %eax,%eax
f010326d:	75 24                	jne    f0103293 <mem_init+0x1cf6>
f010326f:	c7 44 24 0c ad 78 10 	movl   $0xf01078ad,0xc(%esp)
f0103276:	f0 
f0103277:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010327e:	f0 
f010327f:	c7 44 24 04 8d 04 00 	movl   $0x48d,0x4(%esp)
f0103286:	00 
f0103287:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010328e:	e8 ad cd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0103293:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010329a:	e8 d2 de ff ff       	call   f0101171 <page_alloc>
f010329f:	89 c6                	mov    %eax,%esi
f01032a1:	85 c0                	test   %eax,%eax
f01032a3:	75 24                	jne    f01032c9 <mem_init+0x1d2c>
f01032a5:	c7 44 24 0c c3 78 10 	movl   $0xf01078c3,0xc(%esp)
f01032ac:	f0 
f01032ad:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01032b4:	f0 
f01032b5:	c7 44 24 04 8e 04 00 	movl   $0x48e,0x4(%esp)
f01032bc:	00 
f01032bd:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01032c4:	e8 77 cd ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f01032c9:	89 1c 24             	mov    %ebx,(%esp)
f01032cc:	e8 2b df ff ff       	call   f01011fc <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01032d1:	89 f8                	mov    %edi,%eax
f01032d3:	e8 38 d9 ff ff       	call   f0100c10 <page2kva>
f01032d8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01032df:	00 
f01032e0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01032e7:	00 
f01032e8:	89 04 24             	mov    %eax,(%esp)
f01032eb:	e8 17 28 00 00       	call   f0105b07 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01032f0:	89 f0                	mov    %esi,%eax
f01032f2:	e8 19 d9 ff ff       	call   f0100c10 <page2kva>
f01032f7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01032fe:	00 
f01032ff:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103306:	00 
f0103307:	89 04 24             	mov    %eax,(%esp)
f010330a:	e8 f8 27 00 00       	call   f0105b07 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010330f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103316:	00 
f0103317:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010331e:	00 
f010331f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103323:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0103328:	89 04 24             	mov    %eax,(%esp)
f010332b:	e8 4b e1 ff ff       	call   f010147b <page_insert>
	assert(pp1->pp_ref == 1);
f0103330:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103335:	74 24                	je     f010335b <mem_init+0x1dbe>
f0103337:	c7 44 24 0c 94 79 10 	movl   $0xf0107994,0xc(%esp)
f010333e:	f0 
f010333f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103346:	f0 
f0103347:	c7 44 24 04 93 04 00 	movl   $0x493,0x4(%esp)
f010334e:	00 
f010334f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103356:	e8 e5 cc ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010335b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103362:	01 01 01 
f0103365:	74 24                	je     f010338b <mem_init+0x1dee>
f0103367:	c7 44 24 0c d4 76 10 	movl   $0xf01076d4,0xc(%esp)
f010336e:	f0 
f010336f:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103376:	f0 
f0103377:	c7 44 24 04 94 04 00 	movl   $0x494,0x4(%esp)
f010337e:	00 
f010337f:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103386:	e8 b5 cc ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010338b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103392:	00 
f0103393:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010339a:	00 
f010339b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010339f:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01033a4:	89 04 24             	mov    %eax,(%esp)
f01033a7:	e8 cf e0 ff ff       	call   f010147b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01033ac:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01033b3:	02 02 02 
f01033b6:	74 24                	je     f01033dc <mem_init+0x1e3f>
f01033b8:	c7 44 24 0c f8 76 10 	movl   $0xf01076f8,0xc(%esp)
f01033bf:	f0 
f01033c0:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01033c7:	f0 
f01033c8:	c7 44 24 04 96 04 00 	movl   $0x496,0x4(%esp)
f01033cf:	00 
f01033d0:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01033d7:	e8 64 cc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01033dc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01033e1:	74 24                	je     f0103407 <mem_init+0x1e6a>
f01033e3:	c7 44 24 0c b6 79 10 	movl   $0xf01079b6,0xc(%esp)
f01033ea:	f0 
f01033eb:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01033f2:	f0 
f01033f3:	c7 44 24 04 97 04 00 	movl   $0x497,0x4(%esp)
f01033fa:	00 
f01033fb:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f0103402:	e8 39 cc ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103407:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010340c:	74 24                	je     f0103432 <mem_init+0x1e95>
f010340e:	c7 44 24 0c 20 7a 10 	movl   $0xf0107a20,0xc(%esp)
f0103415:	f0 
f0103416:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010341d:	f0 
f010341e:	c7 44 24 04 98 04 00 	movl   $0x498,0x4(%esp)
f0103425:	00 
f0103426:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010342d:	e8 0e cc ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103432:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0103439:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010343c:	89 f0                	mov    %esi,%eax
f010343e:	e8 cd d7 ff ff       	call   f0100c10 <page2kva>
f0103443:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0103449:	74 24                	je     f010346f <mem_init+0x1ed2>
f010344b:	c7 44 24 0c 1c 77 10 	movl   $0xf010771c,0xc(%esp)
f0103452:	f0 
f0103453:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010345a:	f0 
f010345b:	c7 44 24 04 9a 04 00 	movl   $0x49a,0x4(%esp)
f0103462:	00 
f0103463:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010346a:	e8 d1 cb ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010346f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103476:	00 
f0103477:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010347c:	89 04 24             	mov    %eax,(%esp)
f010347f:	e8 a6 df ff ff       	call   f010142a <page_remove>
	assert(pp2->pp_ref == 0);
f0103484:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0103489:	74 24                	je     f01034af <mem_init+0x1f12>
f010348b:	c7 44 24 0c ee 79 10 	movl   $0xf01079ee,0xc(%esp)
f0103492:	f0 
f0103493:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010349a:	f0 
f010349b:	c7 44 24 04 9c 04 00 	movl   $0x49c,0x4(%esp)
f01034a2:	00 
f01034a3:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01034aa:	e8 91 cb ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01034af:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01034b4:	8b 08                	mov    (%eax),%ecx
f01034b6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	return (pp - pages) << PGSHIFT;
f01034bc:	89 da                	mov    %ebx,%edx
f01034be:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01034c4:	c1 fa 03             	sar    $0x3,%edx
f01034c7:	c1 e2 0c             	shl    $0xc,%edx
f01034ca:	39 d1                	cmp    %edx,%ecx
f01034cc:	74 24                	je     f01034f2 <mem_init+0x1f55>
f01034ce:	c7 44 24 0c a4 70 10 	movl   $0xf01070a4,0xc(%esp)
f01034d5:	f0 
f01034d6:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01034dd:	f0 
f01034de:	c7 44 24 04 9f 04 00 	movl   $0x49f,0x4(%esp)
f01034e5:	00 
f01034e6:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f01034ed:	e8 4e cb ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01034f2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01034f8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01034fd:	74 24                	je     f0103523 <mem_init+0x1f86>
f01034ff:	c7 44 24 0c a5 79 10 	movl   $0xf01079a5,0xc(%esp)
f0103506:	f0 
f0103507:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010350e:	f0 
f010350f:	c7 44 24 04 a1 04 00 	movl   $0x4a1,0x4(%esp)
f0103516:	00 
f0103517:	c7 04 24 a9 77 10 f0 	movl   $0xf01077a9,(%esp)
f010351e:	e8 1d cb ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0103523:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103529:	89 1c 24             	mov    %ebx,(%esp)
f010352c:	e8 cb dc ff ff       	call   f01011fc <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103531:	c7 04 24 48 77 10 f0 	movl   $0xf0107748,(%esp)
f0103538:	e8 be 0a 00 00       	call   f0103ffb <cprintf>
f010353d:	eb 1c                	jmp    f010355b <mem_init+0x1fbe>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010353f:	89 da                	mov    %ebx,%edx
f0103541:	89 f8                	mov    %edi,%eax
f0103543:	e8 0d d7 ff ff       	call   f0100c55 <check_va2pa>
f0103548:	e9 0c fb ff ff       	jmp    f0103059 <mem_init+0x1abc>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010354d:	89 da                	mov    %ebx,%edx
f010354f:	89 f8                	mov    %edi,%eax
f0103551:	e8 ff d6 ff ff       	call   f0100c55 <check_va2pa>
f0103556:	e9 0d fa ff ff       	jmp    f0102f68 <mem_init+0x19cb>
}
f010355b:	83 c4 4c             	add    $0x4c,%esp
f010355e:	5b                   	pop    %ebx
f010355f:	5e                   	pop    %esi
f0103560:	5f                   	pop    %edi
f0103561:	5d                   	pop    %ebp
f0103562:	c3                   	ret    

f0103563 <user_mem_check>:
{
f0103563:	55                   	push   %ebp
f0103564:	89 e5                	mov    %esp,%ebp
f0103566:	57                   	push   %edi
f0103567:	56                   	push   %esi
f0103568:	53                   	push   %ebx
f0103569:	83 ec 2c             	sub    $0x2c,%esp
f010356c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010356f:	8b 45 0c             	mov    0xc(%ebp),%eax
	uintptr_t top = (uintptr_t ) ROUNDDOWN(va, PGSIZE);
f0103572:	89 c3                	mov    %eax,%ebx
f0103574:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t bottom = (uintptr_t) ROUNDUP (va + len, PGSIZE); // Define the range we're walking up and down.
f010357a:	03 45 10             	add    0x10(%ebp),%eax
f010357d:	05 ff 0f 00 00       	add    $0xfff,%eax
f0103582:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103587:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pde_t *pte = NULL;
f010358a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		page = page_lookup(env->env_pgdir, (void *) top, &pte);
f0103591:	8d 75 e4             	lea    -0x1c(%ebp),%esi
	while (top < bottom)
f0103594:	eb 56                	jmp    f01035ec <user_mem_check+0x89>
		page = page_lookup(env->env_pgdir, (void *) top, &pte);
f0103596:	89 74 24 08          	mov    %esi,0x8(%esp)
f010359a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010359e:	8b 47 60             	mov    0x60(%edi),%eax
f01035a1:	89 04 24             	mov    %eax,(%esp)
f01035a4:	e8 d3 dd ff ff       	call   f010137c <page_lookup>
		if (page == NULL) // If we don't find a page at that address, return NULL
f01035a9:	85 c0                	test   %eax,%eax
f01035ab:	75 0d                	jne    f01035ba <user_mem_check+0x57>
			user_mem_check_addr = top;
f01035ad:	89 1d 3c b2 22 f0    	mov    %ebx,0xf022b23c
			return -E_FAULT;
f01035b3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01035b8:	eb 3c                	jmp    f01035f6 <user_mem_check+0x93>
		else if ((*pte & perm) == false) // If the perm isn't there, return -E_FAULT
f01035ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035bd:	8b 00                	mov    (%eax),%eax
f01035bf:	85 45 14             	test   %eax,0x14(%ebp)
f01035c2:	75 0d                	jne    f01035d1 <user_mem_check+0x6e>
			user_mem_check_addr = top;
f01035c4:	89 1d 3c b2 22 f0    	mov    %ebx,0xf022b23c
			return -E_FAULT;
f01035ca:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01035cf:	eb 25                	jmp    f01035f6 <user_mem_check+0x93>
		else if (top >= ULIM)
f01035d1:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01035d7:	76 0d                	jbe    f01035e6 <user_mem_check+0x83>
			user_mem_check_addr = top;
f01035d9:	89 1d 3c b2 22 f0    	mov    %ebx,0xf022b23c
			return -E_FAULT;
f01035df:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01035e4:	eb 10                	jmp    f01035f6 <user_mem_check+0x93>
		top = top + PGSIZE;
f01035e6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	while (top < bottom)
f01035ec:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01035ef:	72 a5                	jb     f0103596 <user_mem_check+0x33>
	return 0;
f01035f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01035f6:	83 c4 2c             	add    $0x2c,%esp
f01035f9:	5b                   	pop    %ebx
f01035fa:	5e                   	pop    %esi
f01035fb:	5f                   	pop    %edi
f01035fc:	5d                   	pop    %ebp
f01035fd:	c3                   	ret    

f01035fe <user_mem_assert>:
{
f01035fe:	55                   	push   %ebp
f01035ff:	89 e5                	mov    %esp,%ebp
f0103601:	53                   	push   %ebx
f0103602:	83 ec 14             	sub    $0x14,%esp
f0103605:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103608:	8b 45 14             	mov    0x14(%ebp),%eax
f010360b:	83 c8 04             	or     $0x4,%eax
f010360e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103612:	8b 45 10             	mov    0x10(%ebp),%eax
f0103615:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103619:	8b 45 0c             	mov    0xc(%ebp),%eax
f010361c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103620:	89 1c 24             	mov    %ebx,(%esp)
f0103623:	e8 3b ff ff ff       	call   f0103563 <user_mem_check>
f0103628:	85 c0                	test   %eax,%eax
f010362a:	79 24                	jns    f0103650 <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f010362c:	a1 3c b2 22 f0       	mov    0xf022b23c,%eax
f0103631:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103635:	8b 43 48             	mov    0x48(%ebx),%eax
f0103638:	89 44 24 04          	mov    %eax,0x4(%esp)
f010363c:	c7 04 24 74 77 10 f0 	movl   $0xf0107774,(%esp)
f0103643:	e8 b3 09 00 00       	call   f0103ffb <cprintf>
		env_destroy(env);	// may not return
f0103648:	89 1c 24             	mov    %ebx,(%esp)
f010364b:	e8 f2 06 00 00       	call   f0103d42 <env_destroy>
}
f0103650:	83 c4 14             	add    $0x14,%esp
f0103653:	5b                   	pop    %ebx
f0103654:	5d                   	pop    %ebp
f0103655:	c3                   	ret    

f0103656 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103656:	55                   	push   %ebp
f0103657:	89 e5                	mov    %esp,%ebp
f0103659:	57                   	push   %edi
f010365a:	56                   	push   %esi
f010365b:	53                   	push   %ebx
f010365c:	83 ec 1c             	sub    $0x1c,%esp
f010365f:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	// Calculate the start and end points of what we're allocating.
	void * start_ptr = ROUNDDOWN(va, PGSIZE);
f0103661:	89 d3                	mov    %edx,%ebx
f0103663:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void * end_ptr = ROUNDUP(va+len, PGSIZE); 
f0103669:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0103670:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo * page;
	
	while (start_ptr < end_ptr)
f0103676:	eb 55                	jmp    f01036cd <region_alloc+0x77>
	{
		page = page_alloc(0);
f0103678:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010367f:	e8 ed da ff ff       	call   f0101171 <page_alloc>
		assert(page != NULL);
f0103684:	85 c0                	test   %eax,%eax
f0103686:	75 24                	jne    f01036ac <region_alloc+0x56>
f0103688:	c7 44 24 0c bb 7a 10 	movl   $0xf0107abb,0xc(%esp)
f010368f:	f0 
f0103690:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f0103697:	f0 
f0103698:	c7 44 24 04 2d 01 00 	movl   $0x12d,0x4(%esp)
f010369f:	00 
f01036a0:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f01036a7:	e8 94 c9 ff ff       	call   f0100040 <_panic>
		page_insert(e->env_pgdir, page, start_ptr, PTE_W | PTE_U);
f01036ac:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01036b3:	00 
f01036b4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036bc:	8b 47 60             	mov    0x60(%edi),%eax
f01036bf:	89 04 24             	mov    %eax,(%esp)
f01036c2:	e8 b4 dd ff ff       	call   f010147b <page_insert>
		start_ptr = start_ptr + PGSIZE;
f01036c7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	while (start_ptr < end_ptr)
f01036cd:	39 f3                	cmp    %esi,%ebx
f01036cf:	72 a7                	jb     f0103678 <region_alloc+0x22>
	} 
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f01036d1:	83 c4 1c             	add    $0x1c,%esp
f01036d4:	5b                   	pop    %ebx
f01036d5:	5e                   	pop    %esi
f01036d6:	5f                   	pop    %edi
f01036d7:	5d                   	pop    %ebp
f01036d8:	c3                   	ret    

f01036d9 <envid2env>:
{
f01036d9:	55                   	push   %ebp
f01036da:	89 e5                	mov    %esp,%ebp
f01036dc:	56                   	push   %esi
f01036dd:	53                   	push   %ebx
f01036de:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e1:	8b 55 10             	mov    0x10(%ebp),%edx
	if (envid == 0) {
f01036e4:	85 c0                	test   %eax,%eax
f01036e6:	75 1a                	jne    f0103702 <envid2env+0x29>
		*env_store = curenv;
f01036e8:	e8 6c 2a 00 00       	call   f0106159 <cpunum>
f01036ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01036f0:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01036f6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01036f9:	89 01                	mov    %eax,(%ecx)
		return 0;
f01036fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103700:	eb 70                	jmp    f0103772 <envid2env+0x99>
	e = &envs[ENVX(envid)];
f0103702:	89 c3                	mov    %eax,%ebx
f0103704:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010370a:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010370d:	03 1d 48 b2 22 f0    	add    0xf022b248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103713:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103717:	74 05                	je     f010371e <envid2env+0x45>
f0103719:	39 43 48             	cmp    %eax,0x48(%ebx)
f010371c:	74 10                	je     f010372e <envid2env+0x55>
		*env_store = 0;
f010371e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103721:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103727:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010372c:	eb 44                	jmp    f0103772 <envid2env+0x99>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010372e:	84 d2                	test   %dl,%dl
f0103730:	74 36                	je     f0103768 <envid2env+0x8f>
f0103732:	e8 22 2a 00 00       	call   f0106159 <cpunum>
f0103737:	6b c0 74             	imul   $0x74,%eax,%eax
f010373a:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103740:	74 26                	je     f0103768 <envid2env+0x8f>
f0103742:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103745:	e8 0f 2a 00 00       	call   f0106159 <cpunum>
f010374a:	6b c0 74             	imul   $0x74,%eax,%eax
f010374d:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103753:	3b 70 48             	cmp    0x48(%eax),%esi
f0103756:	74 10                	je     f0103768 <envid2env+0x8f>
		*env_store = 0;
f0103758:	8b 45 0c             	mov    0xc(%ebp),%eax
f010375b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103761:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103766:	eb 0a                	jmp    f0103772 <envid2env+0x99>
	*env_store = e;
f0103768:	8b 45 0c             	mov    0xc(%ebp),%eax
f010376b:	89 18                	mov    %ebx,(%eax)
	return 0;
f010376d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103772:	5b                   	pop    %ebx
f0103773:	5e                   	pop    %esi
f0103774:	5d                   	pop    %ebp
f0103775:	c3                   	ret    

f0103776 <env_init_percpu>:
{
f0103776:	55                   	push   %ebp
f0103777:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f0103779:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f010377e:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103781:	b8 23 00 00 00       	mov    $0x23,%eax
f0103786:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103788:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010378a:	b0 10                	mov    $0x10,%al
f010378c:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f010378e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103790:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103792:	ea 99 37 10 f0 08 00 	ljmp   $0x8,$0xf0103799
	asm volatile("lldt %0" : : "r" (sel));
f0103799:	b0 00                	mov    $0x0,%al
f010379b:	0f 00 d0             	lldt   %ax
}
f010379e:	5d                   	pop    %ebp
f010379f:	c3                   	ret    

f01037a0 <env_init>:
{
f01037a0:	55                   	push   %ebp
f01037a1:	89 e5                	mov    %esp,%ebp
f01037a3:	56                   	push   %esi
f01037a4:	53                   	push   %ebx
		envs[i].env_id = 0; // Set the id to 0.
f01037a5:	8b 35 48 b2 22 f0    	mov    0xf022b248,%esi
f01037ab:	8b 0d 4c b2 22 f0    	mov    0xf022b24c,%ecx
f01037b1:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01037b7:	ba 00 04 00 00       	mov    $0x400,%edx
f01037bc:	89 c3                	mov    %eax,%ebx
f01037be:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE; // Set the status to free
f01037c5:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list; // Generating our linked list of envs
f01037cc:	89 48 44             	mov    %ecx,0x44(%eax)
f01037cf:	83 e8 7c             	sub    $0x7c,%eax
	for(int i = NENV-1; i >= 0; i--) {
f01037d2:	83 ea 01             	sub    $0x1,%edx
f01037d5:	74 04                	je     f01037db <env_init+0x3b>
		env_free_list = &envs[i];
f01037d7:	89 d9                	mov    %ebx,%ecx
f01037d9:	eb e1                	jmp    f01037bc <env_init+0x1c>
f01037db:	89 35 4c b2 22 f0    	mov    %esi,0xf022b24c
	envs[NENV - 1].env_link = NULL; // My loop should do this?  But just to be safe, set the link at the top to NULL.
f01037e1:	a1 48 b2 22 f0       	mov    0xf022b248,%eax
f01037e6:	c7 80 c8 ef 01 00 00 	movl   $0x0,0x1efc8(%eax)
f01037ed:	00 00 00 
	env_init_percpu();
f01037f0:	e8 81 ff ff ff       	call   f0103776 <env_init_percpu>
}
f01037f5:	5b                   	pop    %ebx
f01037f6:	5e                   	pop    %esi
f01037f7:	5d                   	pop    %ebp
f01037f8:	c3                   	ret    

f01037f9 <env_alloc>:
{
f01037f9:	55                   	push   %ebp
f01037fa:	89 e5                	mov    %esp,%ebp
f01037fc:	56                   	push   %esi
f01037fd:	53                   	push   %ebx
f01037fe:	83 ec 10             	sub    $0x10,%esp
	if (!(e = env_free_list))
f0103801:	8b 1d 4c b2 22 f0    	mov    0xf022b24c,%ebx
f0103807:	85 db                	test   %ebx,%ebx
f0103809:	0f 84 bf 01 00 00    	je     f01039ce <env_alloc+0x1d5>
	if (!(p = page_alloc(ALLOC_ZERO)))
f010380f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103816:	e8 56 d9 ff ff       	call   f0101171 <page_alloc>
f010381b:	89 c6                	mov    %eax,%esi
f010381d:	85 c0                	test   %eax,%eax
f010381f:	0f 84 b0 01 00 00    	je     f01039d5 <env_alloc+0x1dc>
	memcpy(page2kva(p), kern_pgdir, PGSIZE); // Copy our page over.
f0103825:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f010382b:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0103831:	c1 f8 03             	sar    $0x3,%eax
f0103834:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0103837:	89 c1                	mov    %eax,%ecx
f0103839:	c1 e9 0c             	shr    $0xc,%ecx
f010383c:	3b 0d 88 be 22 f0    	cmp    0xf022be88,%ecx
f0103842:	72 20                	jb     f0103864 <env_alloc+0x6b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103844:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103848:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f010384f:	f0 
f0103850:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0103857:	00 
f0103858:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f010385f:	e8 dc c7 ff ff       	call   f0100040 <_panic>
f0103864:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010386b:	00 
f010386c:	89 54 24 04          	mov    %edx,0x4(%esp)
	return (void *)(pa + KERNBASE);
f0103870:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103875:	89 04 24             	mov    %eax,(%esp)
f0103878:	e8 3f 23 00 00       	call   f0105bbc <memcpy>
	p->pp_ref++; // Increment env_pgdir's pp_ref.
f010387d:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return (pp - pages) << PGSHIFT;
f0103882:	2b 35 90 be 22 f0    	sub    0xf022be90,%esi
f0103888:	c1 fe 03             	sar    $0x3,%esi
f010388b:	c1 e6 0c             	shl    $0xc,%esi
	if (PGNUM(pa) >= npages)
f010388e:	89 f0                	mov    %esi,%eax
f0103890:	c1 e8 0c             	shr    $0xc,%eax
f0103893:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103899:	72 20                	jb     f01038bb <env_alloc+0xc2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010389b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010389f:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f01038a6:	f0 
f01038a7:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01038ae:	00 
f01038af:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f01038b6:	e8 85 c7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01038bb:	8d 86 00 00 00 f0    	lea    -0x10000000(%esi),%eax
	e->env_pgdir = (pde_t *) page2kva(p); 
f01038c1:	89 43 60             	mov    %eax,0x60(%ebx)
	if ((uint32_t)kva < KERNBASE)
f01038c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01038c9:	77 20                	ja     f01038eb <env_alloc+0xf2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01038cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038cf:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f01038d6:	f0 
f01038d7:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f01038de:	00 
f01038df:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f01038e6:	e8 55 c7 ff ff       	call   f0100040 <_panic>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01038eb:	83 ce 05             	or     $0x5,%esi
f01038ee:	89 b0 f4 0e 00 00    	mov    %esi,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01038f4:	8b 43 48             	mov    0x48(%ebx),%eax
f01038f7:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01038fc:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103901:	ba 00 10 00 00       	mov    $0x1000,%edx
f0103906:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103909:	89 da                	mov    %ebx,%edx
f010390b:	2b 15 48 b2 22 f0    	sub    0xf022b248,%edx
f0103911:	c1 fa 02             	sar    $0x2,%edx
f0103914:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f010391a:	09 d0                	or     %edx,%eax
f010391c:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f010391f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103922:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103925:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f010392c:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103933:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010393a:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103941:	00 
f0103942:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103949:	00 
f010394a:	89 1c 24             	mov    %ebx,(%esp)
f010394d:	e8 b5 21 00 00       	call   f0105b07 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103952:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103958:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010395e:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103964:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010396b:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	e->env_pgfault_upcall = 0;
f0103971:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f0103978:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f010397c:	8b 43 44             	mov    0x44(%ebx),%eax
f010397f:	a3 4c b2 22 f0       	mov    %eax,0xf022b24c
	*newenv_store = e;
f0103984:	8b 45 08             	mov    0x8(%ebp),%eax
f0103987:	89 18                	mov    %ebx,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103989:	8b 5b 48             	mov    0x48(%ebx),%ebx
f010398c:	e8 c8 27 00 00       	call   f0106159 <cpunum>
f0103991:	6b c0 74             	imul   $0x74,%eax,%eax
f0103994:	ba 00 00 00 00       	mov    $0x0,%edx
f0103999:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f01039a0:	74 11                	je     f01039b3 <env_alloc+0x1ba>
f01039a2:	e8 b2 27 00 00       	call   f0106159 <cpunum>
f01039a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01039aa:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01039b0:	8b 50 48             	mov    0x48(%eax),%edx
f01039b3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01039b7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01039bb:	c7 04 24 d3 7a 10 f0 	movl   $0xf0107ad3,(%esp)
f01039c2:	e8 34 06 00 00       	call   f0103ffb <cprintf>
	return 0;
f01039c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01039cc:	eb 0c                	jmp    f01039da <env_alloc+0x1e1>
		return -E_NO_FREE_ENV;
f01039ce:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01039d3:	eb 05                	jmp    f01039da <env_alloc+0x1e1>
		return -E_NO_MEM;
f01039d5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f01039da:	83 c4 10             	add    $0x10,%esp
f01039dd:	5b                   	pop    %ebx
f01039de:	5e                   	pop    %esi
f01039df:	5d                   	pop    %ebp
f01039e0:	c3                   	ret    

f01039e1 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01039e1:	55                   	push   %ebp
f01039e2:	89 e5                	mov    %esp,%ebp
f01039e4:	57                   	push   %edi
f01039e5:	56                   	push   %esi
f01039e6:	53                   	push   %ebx
f01039e7:	83 ec 3c             	sub    $0x3c,%esp
f01039ea:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *new; // Declare the env
	env_alloc(&new, 0); // Allocate the env
f01039ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01039f4:	00 
f01039f5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01039f8:	89 04 24             	mov    %eax,(%esp)
f01039fb:	e8 f9 fd ff ff       	call   f01037f9 <env_alloc>
	load_icode(new, binary); // Load in the binary
f0103a00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a03:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (header->e_magic != ELF_MAGIC) {
f0103a06:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103a0c:	74 1c                	je     f0103a2a <env_create+0x49>
		panic("no");
f0103a0e:	c7 44 24 08 e8 7a 10 	movl   $0xf0107ae8,0x8(%esp)
f0103a15:	f0 
f0103a16:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f0103a1d:	00 
f0103a1e:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103a25:	e8 16 c6 ff ff       	call   f0100040 <_panic>
	struct Proghdr *start = (struct Proghdr *) (header->e_phoff + binary);
f0103a2a:	89 fb                	mov    %edi,%ebx
f0103a2c:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *end = start + header->e_phnum;
f0103a2f:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103a33:	c1 e6 05             	shl    $0x5,%esi
f0103a36:	01 de                	add    %ebx,%esi
	lcr3(PADDR(e->env_pgdir)); // Update CR3
f0103a38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a3b:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103a3e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103a43:	77 20                	ja     f0103a65 <env_create+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a45:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a49:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0103a50:	f0 
f0103a51:	c7 44 24 04 77 01 00 	movl   $0x177,0x4(%esp)
f0103a58:	00 
f0103a59:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103a60:	e8 db c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103a65:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103a6a:	0f 22 d8             	mov    %eax,%cr3
f0103a6d:	89 7d 08             	mov    %edi,0x8(%ebp)
f0103a70:	eb 48                	jmp    f0103aba <env_create+0xd9>
		if (start->p_type == ELF_PROG_LOAD) // As specified, we're only loading stuff with p_type ELF_PROG_LOAD
f0103a72:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103a75:	75 40                	jne    f0103ab7 <env_create+0xd6>
			va = (void *) start->p_va; // store the VA, we're about to use it a bunch.
f0103a77:	8b 7b 08             	mov    0x8(%ebx),%edi
			region_alloc(e, va, start->p_memsz);
f0103a7a:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103a7d:	89 fa                	mov    %edi,%edx
f0103a7f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a82:	e8 cf fb ff ff       	call   f0103656 <region_alloc>
			memset(va, 0, start->p_memsz);
f0103a87:	8b 43 14             	mov    0x14(%ebx),%eax
f0103a8a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a8e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103a95:	00 
f0103a96:	89 3c 24             	mov    %edi,(%esp)
f0103a99:	e8 69 20 00 00       	call   f0105b07 <memset>
			memcpy(va, ((void * ) (start->p_offset + binary)), start->p_filesz);
f0103a9e:	8b 43 10             	mov    0x10(%ebx),%eax
f0103aa1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103aa5:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aa8:	03 43 04             	add    0x4(%ebx),%eax
f0103aab:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aaf:	89 3c 24             	mov    %edi,(%esp)
f0103ab2:	e8 05 21 00 00       	call   f0105bbc <memcpy>
		start++; // keep walkin'
f0103ab7:	83 c3 20             	add    $0x20,%ebx
	while (start < end) // Walking over the segment
f0103aba:	39 de                	cmp    %ebx,%esi
f0103abc:	77 b4                	ja     f0103a72 <env_create+0x91>
f0103abe:	8b 7d 08             	mov    0x8(%ebp),%edi
	region_alloc(e, (void *) (USTACKTOP - PGSIZE), PGSIZE);
f0103ac1:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103ac6:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103acb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103ace:	e8 83 fb ff ff       	call   f0103656 <region_alloc>
	memset((void*) (USTACKTOP-PGSIZE), 0, PGSIZE);
f0103ad3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103ada:	00 
f0103adb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103ae2:	00 
f0103ae3:	c7 04 24 00 d0 bf ee 	movl   $0xeebfd000,(%esp)
f0103aea:	e8 18 20 00 00       	call   f0105b07 <memset>
	lcr3(PADDR(kern_pgdir));
f0103aef:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103af4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103af9:	77 20                	ja     f0103b1b <env_create+0x13a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103afb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103aff:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0103b06:	f0 
f0103b07:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
f0103b0e:	00 
f0103b0f:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103b16:	e8 25 c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103b1b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103b20:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = header->e_entry;
f0103b23:	8b 47 18             	mov    0x18(%edi),%eax
f0103b26:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103b29:	89 42 30             	mov    %eax,0x30(%edx)
	new->env_type = type;// Set it to the envtype.
f0103b2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b2f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b32:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103b35:	83 c4 3c             	add    $0x3c,%esp
f0103b38:	5b                   	pop    %ebx
f0103b39:	5e                   	pop    %esi
f0103b3a:	5f                   	pop    %edi
f0103b3b:	5d                   	pop    %ebp
f0103b3c:	c3                   	ret    

f0103b3d <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103b3d:	55                   	push   %ebp
f0103b3e:	89 e5                	mov    %esp,%ebp
f0103b40:	57                   	push   %edi
f0103b41:	56                   	push   %esi
f0103b42:	53                   	push   %ebx
f0103b43:	83 ec 2c             	sub    $0x2c,%esp
f0103b46:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103b49:	e8 0b 26 00 00       	call   f0106159 <cpunum>
f0103b4e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b51:	39 b8 28 c0 22 f0    	cmp    %edi,-0xfdd3fd8(%eax)
f0103b57:	75 34                	jne    f0103b8d <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103b59:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103b5e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b63:	77 20                	ja     f0103b85 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b69:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0103b70:	f0 
f0103b71:	c7 44 24 04 ae 01 00 	movl   $0x1ae,0x4(%esp)
f0103b78:	00 
f0103b79:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103b80:	e8 bb c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103b85:	05 00 00 00 10       	add    $0x10000000,%eax
f0103b8a:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103b8d:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103b90:	e8 c4 25 00 00       	call   f0106159 <cpunum>
f0103b95:	6b d0 74             	imul   $0x74,%eax,%edx
f0103b98:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b9d:	83 ba 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%edx)
f0103ba4:	74 11                	je     f0103bb7 <env_free+0x7a>
f0103ba6:	e8 ae 25 00 00       	call   f0106159 <cpunum>
f0103bab:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bae:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103bb4:	8b 40 48             	mov    0x48(%eax),%eax
f0103bb7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103bbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bbf:	c7 04 24 eb 7a 10 f0 	movl   $0xf0107aeb,(%esp)
f0103bc6:	e8 30 04 00 00       	call   f0103ffb <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103bcb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103bd2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103bd5:	89 c8                	mov    %ecx,%eax
f0103bd7:	c1 e0 02             	shl    $0x2,%eax
f0103bda:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103bdd:	8b 47 60             	mov    0x60(%edi),%eax
f0103be0:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103be3:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103be9:	0f 84 b7 00 00 00    	je     f0103ca6 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103bef:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	if (PGNUM(pa) >= npages)
f0103bf5:	89 f0                	mov    %esi,%eax
f0103bf7:	c1 e8 0c             	shr    $0xc,%eax
f0103bfa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103bfd:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103c03:	72 20                	jb     f0103c25 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103c05:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103c09:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0103c10:	f0 
f0103c11:	c7 44 24 04 bd 01 00 	movl   $0x1bd,0x4(%esp)
f0103c18:	00 
f0103c19:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103c20:	e8 1b c4 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103c25:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c28:	c1 e0 16             	shl    $0x16,%eax
f0103c2b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103c2e:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103c33:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103c3a:	01 
f0103c3b:	74 17                	je     f0103c54 <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103c3d:	89 d8                	mov    %ebx,%eax
f0103c3f:	c1 e0 0c             	shl    $0xc,%eax
f0103c42:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103c45:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c49:	8b 47 60             	mov    0x60(%edi),%eax
f0103c4c:	89 04 24             	mov    %eax,(%esp)
f0103c4f:	e8 d6 d7 ff ff       	call   f010142a <page_remove>
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103c54:	83 c3 01             	add    $0x1,%ebx
f0103c57:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103c5d:	75 d4                	jne    f0103c33 <env_free+0xf6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103c5f:	8b 47 60             	mov    0x60(%edi),%eax
f0103c62:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103c65:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103c6c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103c6f:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103c75:	72 1c                	jb     f0103c93 <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103c77:	c7 44 24 08 4c 6f 10 	movl   $0xf0106f4c,0x8(%esp)
f0103c7e:	f0 
f0103c7f:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103c86:	00 
f0103c87:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f0103c8e:	e8 ad c3 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103c93:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0103c98:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103c9b:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103c9e:	89 04 24             	mov    %eax,(%esp)
f0103ca1:	e8 b2 d5 ff ff       	call   f0101258 <page_decref>
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103ca6:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103caa:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103cb1:	0f 85 1b ff ff ff    	jne    f0103bd2 <env_free+0x95>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103cb7:	8b 47 60             	mov    0x60(%edi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103cba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103cbf:	77 20                	ja     f0103ce1 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103cc1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103cc5:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0103ccc:	f0 
f0103ccd:	c7 44 24 04 cb 01 00 	movl   $0x1cb,0x4(%esp)
f0103cd4:	00 
f0103cd5:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103cdc:	e8 5f c3 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103ce1:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103ce8:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103ced:	c1 e8 0c             	shr    $0xc,%eax
f0103cf0:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103cf6:	72 1c                	jb     f0103d14 <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103cf8:	c7 44 24 08 4c 6f 10 	movl   $0xf0106f4c,0x8(%esp)
f0103cff:	f0 
f0103d00:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103d07:	00 
f0103d08:	c7 04 24 b5 77 10 f0 	movl   $0xf01077b5,(%esp)
f0103d0f:	e8 2c c3 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103d14:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f0103d1a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103d1d:	89 04 24             	mov    %eax,(%esp)
f0103d20:	e8 33 d5 ff ff       	call   f0101258 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103d25:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103d2c:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
f0103d31:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103d34:	89 3d 4c b2 22 f0    	mov    %edi,0xf022b24c
}
f0103d3a:	83 c4 2c             	add    $0x2c,%esp
f0103d3d:	5b                   	pop    %ebx
f0103d3e:	5e                   	pop    %esi
f0103d3f:	5f                   	pop    %edi
f0103d40:	5d                   	pop    %ebp
f0103d41:	c3                   	ret    

f0103d42 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103d42:	55                   	push   %ebp
f0103d43:	89 e5                	mov    %esp,%ebp
f0103d45:	53                   	push   %ebx
f0103d46:	83 ec 14             	sub    $0x14,%esp
f0103d49:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103d4c:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103d50:	75 19                	jne    f0103d6b <env_destroy+0x29>
f0103d52:	e8 02 24 00 00       	call   f0106159 <cpunum>
f0103d57:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d5a:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103d60:	74 09                	je     f0103d6b <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103d62:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103d69:	eb 2f                	jmp    f0103d9a <env_destroy+0x58>
	}

	env_free(e);
f0103d6b:	89 1c 24             	mov    %ebx,(%esp)
f0103d6e:	e8 ca fd ff ff       	call   f0103b3d <env_free>

	if (curenv == e) {
f0103d73:	e8 e1 23 00 00       	call   f0106159 <cpunum>
f0103d78:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d7b:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103d81:	75 17                	jne    f0103d9a <env_destroy+0x58>
		curenv = NULL;
f0103d83:	e8 d1 23 00 00       	call   f0106159 <cpunum>
f0103d88:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d8b:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f0103d92:	00 00 00 
		sched_yield();
f0103d95:	e8 b9 0c 00 00       	call   f0104a53 <sched_yield>
	}
}
f0103d9a:	83 c4 14             	add    $0x14,%esp
f0103d9d:	5b                   	pop    %ebx
f0103d9e:	5d                   	pop    %ebp
f0103d9f:	c3                   	ret    

f0103da0 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103da0:	55                   	push   %ebp
f0103da1:	89 e5                	mov    %esp,%ebp
f0103da3:	53                   	push   %ebx
f0103da4:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103da7:	e8 ad 23 00 00       	call   f0106159 <cpunum>
f0103dac:	6b c0 74             	imul   $0x74,%eax,%eax
f0103daf:	8b 98 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%ebx
f0103db5:	e8 9f 23 00 00       	call   f0106159 <cpunum>
f0103dba:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103dbd:	8b 65 08             	mov    0x8(%ebp),%esp
f0103dc0:	61                   	popa   
f0103dc1:	07                   	pop    %es
f0103dc2:	1f                   	pop    %ds
f0103dc3:	83 c4 08             	add    $0x8,%esp
f0103dc6:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103dc7:	c7 44 24 08 01 7b 10 	movl   $0xf0107b01,0x8(%esp)
f0103dce:	f0 
f0103dcf:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
f0103dd6:	00 
f0103dd7:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103dde:	e8 5d c2 ff ff       	call   f0100040 <_panic>

f0103de3 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103de3:	55                   	push   %ebp
f0103de4:	89 e5                	mov    %esp,%ebp
f0103de6:	53                   	push   %ebx
f0103de7:	83 ec 14             	sub    $0x14,%esp
f0103dea:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv != NULL)
f0103ded:	e8 67 23 00 00       	call   f0106159 <cpunum>
f0103df2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df5:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0103dfc:	74 15                	je     f0103e13 <env_run+0x30>
	{
		curenv->env_status = ENV_RUNNABLE; // set the current current environment to runnable to reflect that process is no longer active
f0103dfe:	e8 56 23 00 00       	call   f0106159 <cpunum>
f0103e03:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e06:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103e0c:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	
	if (curenv != e)	{
f0103e13:	e8 41 23 00 00       	call   f0106159 <cpunum>
f0103e18:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e1b:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103e21:	74 59                	je     f0103e7c <env_run+0x99>
		
		curenv = e; // Set it to the new enviornment
f0103e23:	e8 31 23 00 00       	call   f0106159 <cpunum>
f0103e28:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e2b:	89 98 28 c0 22 f0    	mov    %ebx,-0xfdd3fd8(%eax)
		e->env_status = ENV_RUNNING;
f0103e31:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
		e->env_runs++; // CAN YOU HEAR ME?
f0103e38:	83 43 58 01          	addl   $0x1,0x58(%ebx)

		/// CAN YOU HEAR ME RUNNING?
		lcr3(PADDR(curenv->env_pgdir));
f0103e3c:	e8 18 23 00 00       	call   f0106159 <cpunum>
f0103e41:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e44:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103e4a:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103e4d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103e52:	77 20                	ja     f0103e74 <env_run+0x91>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103e54:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e58:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f0103e5f:	f0 
f0103e60:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
f0103e67:	00 
f0103e68:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103e6f:	e8 cc c1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103e74:	05 00 00 00 10       	add    $0x10000000,%eax
f0103e79:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103e7c:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f0103e83:	e8 fb 25 00 00       	call   f0106483 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103e88:	f3 90                	pause  

		// CAN YOU HEAR ME RUNNING 
		// CAN YOU HEAR MY CALLING YOU?
	}
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f0103e8a:	89 1c 24             	mov    %ebx,(%esp)
f0103e8d:	e8 0e ff ff ff       	call   f0103da0 <env_pop_tf>

f0103e92 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103e92:	55                   	push   %ebp
f0103e93:	89 e5                	mov    %esp,%ebp
f0103e95:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103e99:	ba 70 00 00 00       	mov    $0x70,%edx
f0103e9e:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103e9f:	b2 71                	mov    $0x71,%dl
f0103ea1:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103ea2:	0f b6 c0             	movzbl %al,%eax
}
f0103ea5:	5d                   	pop    %ebp
f0103ea6:	c3                   	ret    

f0103ea7 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103ea7:	55                   	push   %ebp
f0103ea8:	89 e5                	mov    %esp,%ebp
f0103eaa:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103eae:	ba 70 00 00 00       	mov    $0x70,%edx
f0103eb3:	ee                   	out    %al,(%dx)
f0103eb4:	b2 71                	mov    $0x71,%dl
f0103eb6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103eb9:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103eba:	5d                   	pop    %ebp
f0103ebb:	c3                   	ret    

f0103ebc <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103ebc:	55                   	push   %ebp
f0103ebd:	89 e5                	mov    %esp,%ebp
f0103ebf:	56                   	push   %esi
f0103ec0:	53                   	push   %ebx
f0103ec1:	83 ec 10             	sub    $0x10,%esp
f0103ec4:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103ec7:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103ecd:	80 3d 50 b2 22 f0 00 	cmpb   $0x0,0xf022b250
f0103ed4:	74 4e                	je     f0103f24 <irq_setmask_8259A+0x68>
f0103ed6:	89 c6                	mov    %eax,%esi
f0103ed8:	ba 21 00 00 00       	mov    $0x21,%edx
f0103edd:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103ede:	66 c1 e8 08          	shr    $0x8,%ax
f0103ee2:	b2 a1                	mov    $0xa1,%dl
f0103ee4:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103ee5:	c7 04 24 0d 7b 10 f0 	movl   $0xf0107b0d,(%esp)
f0103eec:	e8 0a 01 00 00       	call   f0103ffb <cprintf>
	for (i = 0; i < 16; i++)
f0103ef1:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103ef6:	0f b7 f6             	movzwl %si,%esi
f0103ef9:	f7 d6                	not    %esi
f0103efb:	0f a3 de             	bt     %ebx,%esi
f0103efe:	73 10                	jae    f0103f10 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103f00:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103f04:	c7 04 24 cf 7f 10 f0 	movl   $0xf0107fcf,(%esp)
f0103f0b:	e8 eb 00 00 00       	call   f0103ffb <cprintf>
	for (i = 0; i < 16; i++)
f0103f10:	83 c3 01             	add    $0x1,%ebx
f0103f13:	83 fb 10             	cmp    $0x10,%ebx
f0103f16:	75 e3                	jne    f0103efb <irq_setmask_8259A+0x3f>
	cprintf("\n");
f0103f18:	c7 04 24 de 7c 10 f0 	movl   $0xf0107cde,(%esp)
f0103f1f:	e8 d7 00 00 00       	call   f0103ffb <cprintf>
}
f0103f24:	83 c4 10             	add    $0x10,%esp
f0103f27:	5b                   	pop    %ebx
f0103f28:	5e                   	pop    %esi
f0103f29:	5d                   	pop    %ebp
f0103f2a:	c3                   	ret    

f0103f2b <pic_init>:
	didinit = 1;
f0103f2b:	c6 05 50 b2 22 f0 01 	movb   $0x1,0xf022b250
f0103f32:	ba 21 00 00 00       	mov    $0x21,%edx
f0103f37:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103f3c:	ee                   	out    %al,(%dx)
f0103f3d:	b2 a1                	mov    $0xa1,%dl
f0103f3f:	ee                   	out    %al,(%dx)
f0103f40:	b2 20                	mov    $0x20,%dl
f0103f42:	b8 11 00 00 00       	mov    $0x11,%eax
f0103f47:	ee                   	out    %al,(%dx)
f0103f48:	b2 21                	mov    $0x21,%dl
f0103f4a:	b8 20 00 00 00       	mov    $0x20,%eax
f0103f4f:	ee                   	out    %al,(%dx)
f0103f50:	b8 04 00 00 00       	mov    $0x4,%eax
f0103f55:	ee                   	out    %al,(%dx)
f0103f56:	b8 03 00 00 00       	mov    $0x3,%eax
f0103f5b:	ee                   	out    %al,(%dx)
f0103f5c:	b2 a0                	mov    $0xa0,%dl
f0103f5e:	b8 11 00 00 00       	mov    $0x11,%eax
f0103f63:	ee                   	out    %al,(%dx)
f0103f64:	b2 a1                	mov    $0xa1,%dl
f0103f66:	b8 28 00 00 00       	mov    $0x28,%eax
f0103f6b:	ee                   	out    %al,(%dx)
f0103f6c:	b8 02 00 00 00       	mov    $0x2,%eax
f0103f71:	ee                   	out    %al,(%dx)
f0103f72:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f77:	ee                   	out    %al,(%dx)
f0103f78:	b2 20                	mov    $0x20,%dl
f0103f7a:	b8 68 00 00 00       	mov    $0x68,%eax
f0103f7f:	ee                   	out    %al,(%dx)
f0103f80:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f85:	ee                   	out    %al,(%dx)
f0103f86:	b2 a0                	mov    $0xa0,%dl
f0103f88:	b8 68 00 00 00       	mov    $0x68,%eax
f0103f8d:	ee                   	out    %al,(%dx)
f0103f8e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f93:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0103f94:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f0103f9b:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103f9f:	74 12                	je     f0103fb3 <pic_init+0x88>
{
f0103fa1:	55                   	push   %ebp
f0103fa2:	89 e5                	mov    %esp,%ebp
f0103fa4:	83 ec 18             	sub    $0x18,%esp
		irq_setmask_8259A(irq_mask_8259A);
f0103fa7:	0f b7 c0             	movzwl %ax,%eax
f0103faa:	89 04 24             	mov    %eax,(%esp)
f0103fad:	e8 0a ff ff ff       	call   f0103ebc <irq_setmask_8259A>
}
f0103fb2:	c9                   	leave  
f0103fb3:	f3 c3                	repz ret 

f0103fb5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103fb5:	55                   	push   %ebp
f0103fb6:	89 e5                	mov    %esp,%ebp
f0103fb8:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103fbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fbe:	89 04 24             	mov    %eax,(%esp)
f0103fc1:	e8 b4 c7 ff ff       	call   f010077a <cputchar>
	*cnt++;
}
f0103fc6:	c9                   	leave  
f0103fc7:	c3                   	ret    

f0103fc8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103fc8:	55                   	push   %ebp
f0103fc9:	89 e5                	mov    %esp,%ebp
f0103fcb:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103fce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103fd5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fd8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103fdc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fdf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fe3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103fe6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fea:	c7 04 24 b5 3f 10 f0 	movl   $0xf0103fb5,(%esp)
f0103ff1:	e8 58 14 00 00       	call   f010544e <vprintfmt>
	return cnt;
}
f0103ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103ff9:	c9                   	leave  
f0103ffa:	c3                   	ret    

f0103ffb <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103ffb:	55                   	push   %ebp
f0103ffc:	89 e5                	mov    %esp,%ebp
f0103ffe:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0104001:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0104004:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104008:	8b 45 08             	mov    0x8(%ebp),%eax
f010400b:	89 04 24             	mov    %eax,(%esp)
f010400e:	e8 b5 ff ff ff       	call   f0103fc8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0104013:	c9                   	leave  
f0104014:	c3                   	ret    
f0104015:	66 90                	xchg   %ax,%ax
f0104017:	66 90                	xchg   %ax,%ax
f0104019:	66 90                	xchg   %ax,%ax
f010401b:	66 90                	xchg   %ax,%ax
f010401d:	66 90                	xchg   %ax,%ax
f010401f:	90                   	nop

f0104020 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0104020:	55                   	push   %ebp
f0104021:	89 e5                	mov    %esp,%ebp
f0104023:	57                   	push   %edi
f0104024:	56                   	push   %esi
f0104025:	53                   	push   %ebx
f0104026:	83 ec 0c             	sub    $0xc,%esp
	// LAB 4: Your code here:


	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - cpunum() * (KSTKSIZE + KSTKGAP);
f0104029:	e8 2b 21 00 00       	call   f0106159 <cpunum>
f010402e:	89 c3                	mov    %eax,%ebx
f0104030:	e8 24 21 00 00       	call   f0106159 <cpunum>
f0104035:	6b db 74             	imul   $0x74,%ebx,%ebx
f0104038:	f7 d8                	neg    %eax
f010403a:	c1 e0 10             	shl    $0x10,%eax
f010403d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0104042:	89 83 30 c0 22 f0    	mov    %eax,-0xfdd3fd0(%ebx)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0104048:	e8 0c 21 00 00       	call   f0106159 <cpunum>
f010404d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104050:	66 c7 80 34 c0 22 f0 	movw   $0x10,-0xfdd3fcc(%eax)
f0104057:	10 00 
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);
f0104059:	e8 fb 20 00 00       	call   f0106159 <cpunum>
f010405e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104061:	66 c7 80 92 c0 22 f0 	movw   $0x68,-0xfdd3f6e(%eax)
f0104068:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cpunum()] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f010406a:	e8 ea 20 00 00       	call   f0106159 <cpunum>
f010406f:	8d 58 05             	lea    0x5(%eax),%ebx
f0104072:	e8 e2 20 00 00       	call   f0106159 <cpunum>
f0104077:	89 c7                	mov    %eax,%edi
f0104079:	e8 db 20 00 00       	call   f0106159 <cpunum>
f010407e:	89 c6                	mov    %eax,%esi
f0104080:	e8 d4 20 00 00       	call   f0106159 <cpunum>
f0104085:	66 c7 04 dd 40 03 12 	movw   $0x67,-0xfedfcc0(,%ebx,8)
f010408c:	f0 67 00 
f010408f:	6b ff 74             	imul   $0x74,%edi,%edi
f0104092:	81 c7 2c c0 22 f0    	add    $0xf022c02c,%edi
f0104098:	66 89 3c dd 42 03 12 	mov    %di,-0xfedfcbe(,%ebx,8)
f010409f:	f0 
f01040a0:	6b d6 74             	imul   $0x74,%esi,%edx
f01040a3:	81 c2 2c c0 22 f0    	add    $0xf022c02c,%edx
f01040a9:	c1 ea 10             	shr    $0x10,%edx
f01040ac:	88 14 dd 44 03 12 f0 	mov    %dl,-0xfedfcbc(,%ebx,8)
f01040b3:	c6 04 dd 45 03 12 f0 	movb   $0x99,-0xfedfcbb(,%ebx,8)
f01040ba:	99 
f01040bb:	c6 04 dd 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%ebx,8)
f01040c2:	40 
f01040c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01040c6:	05 2c c0 22 f0       	add    $0xf022c02c,%eax
f01040cb:	c1 e8 18             	shr    $0x18,%eax
f01040ce:	88 04 dd 47 03 12 f0 	mov    %al,-0xfedfcb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + cpunum()].sd_s = 0;
f01040d5:	e8 7f 20 00 00       	call   f0106159 <cpunum>
f01040da:	80 24 c5 6d 03 12 f0 	andb   $0xef,-0xfedfc93(,%eax,8)
f01040e1:	ef 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (cpunum() << 3));
f01040e2:	e8 72 20 00 00       	call   f0106159 <cpunum>
f01040e7:	8d 04 c5 28 00 00 00 	lea    0x28(,%eax,8),%eax
	asm volatile("ltr %0" : : "r" (sel));
f01040ee:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f01040f1:	b8 aa 03 12 f0       	mov    $0xf01203aa,%eax
f01040f6:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f01040f9:	83 c4 0c             	add    $0xc,%esp
f01040fc:	5b                   	pop    %ebx
f01040fd:	5e                   	pop    %esi
f01040fe:	5f                   	pop    %edi
f01040ff:	5d                   	pop    %ebp
f0104100:	c3                   	ret    

f0104101 <trap_init>:
{
f0104101:	55                   	push   %ebp
f0104102:	89 e5                	mov    %esp,%ebp
f0104104:	83 ec 08             	sub    $0x8,%esp
	SETGATE(idt[T_DIVIDE], 1, GD_KT, t_divide, 0);
f0104107:	b8 00 49 10 f0       	mov    $0xf0104900,%eax
f010410c:	66 a3 60 b2 22 f0    	mov    %ax,0xf022b260
f0104112:	66 c7 05 62 b2 22 f0 	movw   $0x8,0xf022b262
f0104119:	08 00 
f010411b:	c6 05 64 b2 22 f0 00 	movb   $0x0,0xf022b264
f0104122:	c6 05 65 b2 22 f0 8f 	movb   $0x8f,0xf022b265
f0104129:	c1 e8 10             	shr    $0x10,%eax
f010412c:	66 a3 66 b2 22 f0    	mov    %ax,0xf022b266
	SETGATE(idt[T_DEBUG], 1, GD_KT, t_debug, 0);
f0104132:	b8 06 49 10 f0       	mov    $0xf0104906,%eax
f0104137:	66 a3 68 b2 22 f0    	mov    %ax,0xf022b268
f010413d:	66 c7 05 6a b2 22 f0 	movw   $0x8,0xf022b26a
f0104144:	08 00 
f0104146:	c6 05 6c b2 22 f0 00 	movb   $0x0,0xf022b26c
f010414d:	c6 05 6d b2 22 f0 8f 	movb   $0x8f,0xf022b26d
f0104154:	c1 e8 10             	shr    $0x10,%eax
f0104157:	66 a3 6e b2 22 f0    	mov    %ax,0xf022b26e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f010415d:	b8 0c 49 10 f0       	mov    $0xf010490c,%eax
f0104162:	66 a3 70 b2 22 f0    	mov    %ax,0xf022b270
f0104168:	66 c7 05 72 b2 22 f0 	movw   $0x8,0xf022b272
f010416f:	08 00 
f0104171:	c6 05 74 b2 22 f0 00 	movb   $0x0,0xf022b274
f0104178:	c6 05 75 b2 22 f0 8e 	movb   $0x8e,0xf022b275
f010417f:	c1 e8 10             	shr    $0x10,%eax
f0104182:	66 a3 76 b2 22 f0    	mov    %ax,0xf022b276
	SETGATE(idt[T_BRKPT], 1, GD_KT, t_brkpt, 3);
f0104188:	b8 12 49 10 f0       	mov    $0xf0104912,%eax
f010418d:	66 a3 78 b2 22 f0    	mov    %ax,0xf022b278
f0104193:	66 c7 05 7a b2 22 f0 	movw   $0x8,0xf022b27a
f010419a:	08 00 
f010419c:	c6 05 7c b2 22 f0 00 	movb   $0x0,0xf022b27c
f01041a3:	c6 05 7d b2 22 f0 ef 	movb   $0xef,0xf022b27d
f01041aa:	c1 e8 10             	shr    $0x10,%eax
f01041ad:	66 a3 7e b2 22 f0    	mov    %ax,0xf022b27e
	SETGATE(idt[T_OFLOW], 1, GD_KT, t_oflow, 0);
f01041b3:	b8 18 49 10 f0       	mov    $0xf0104918,%eax
f01041b8:	66 a3 80 b2 22 f0    	mov    %ax,0xf022b280
f01041be:	66 c7 05 82 b2 22 f0 	movw   $0x8,0xf022b282
f01041c5:	08 00 
f01041c7:	c6 05 84 b2 22 f0 00 	movb   $0x0,0xf022b284
f01041ce:	c6 05 85 b2 22 f0 8f 	movb   $0x8f,0xf022b285
f01041d5:	c1 e8 10             	shr    $0x10,%eax
f01041d8:	66 a3 86 b2 22 f0    	mov    %ax,0xf022b286
	SETGATE(idt[T_BOUND], 1, GD_KT, t_bound, 0);
f01041de:	b8 1e 49 10 f0       	mov    $0xf010491e,%eax
f01041e3:	66 a3 88 b2 22 f0    	mov    %ax,0xf022b288
f01041e9:	66 c7 05 8a b2 22 f0 	movw   $0x8,0xf022b28a
f01041f0:	08 00 
f01041f2:	c6 05 8c b2 22 f0 00 	movb   $0x0,0xf022b28c
f01041f9:	c6 05 8d b2 22 f0 8f 	movb   $0x8f,0xf022b28d
f0104200:	c1 e8 10             	shr    $0x10,%eax
f0104203:	66 a3 8e b2 22 f0    	mov    %ax,0xf022b28e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0104209:	b8 24 49 10 f0       	mov    $0xf0104924,%eax
f010420e:	66 a3 90 b2 22 f0    	mov    %ax,0xf022b290
f0104214:	66 c7 05 92 b2 22 f0 	movw   $0x8,0xf022b292
f010421b:	08 00 
f010421d:	c6 05 94 b2 22 f0 00 	movb   $0x0,0xf022b294
f0104224:	c6 05 95 b2 22 f0 8e 	movb   $0x8e,0xf022b295
f010422b:	c1 e8 10             	shr    $0x10,%eax
f010422e:	66 a3 96 b2 22 f0    	mov    %ax,0xf022b296
	SETGATE(idt[T_DEVICE], 1, GD_KT, t_device, 0);
f0104234:	b8 2a 49 10 f0       	mov    $0xf010492a,%eax
f0104239:	66 a3 98 b2 22 f0    	mov    %ax,0xf022b298
f010423f:	66 c7 05 9a b2 22 f0 	movw   $0x8,0xf022b29a
f0104246:	08 00 
f0104248:	c6 05 9c b2 22 f0 00 	movb   $0x0,0xf022b29c
f010424f:	c6 05 9d b2 22 f0 8f 	movb   $0x8f,0xf022b29d
f0104256:	c1 e8 10             	shr    $0x10,%eax
f0104259:	66 a3 9e b2 22 f0    	mov    %ax,0xf022b29e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f010425f:	b8 30 49 10 f0       	mov    $0xf0104930,%eax
f0104264:	66 a3 a0 b2 22 f0    	mov    %ax,0xf022b2a0
f010426a:	66 c7 05 a2 b2 22 f0 	movw   $0x8,0xf022b2a2
f0104271:	08 00 
f0104273:	c6 05 a4 b2 22 f0 00 	movb   $0x0,0xf022b2a4
f010427a:	c6 05 a5 b2 22 f0 8e 	movb   $0x8e,0xf022b2a5
f0104281:	c1 e8 10             	shr    $0x10,%eax
f0104284:	66 a3 a6 b2 22 f0    	mov    %ax,0xf022b2a6
	SETGATE(idt[T_TSS], 1, GD_KT, t_tss, 0);
f010428a:	b8 48 49 10 f0       	mov    $0xf0104948,%eax
f010428f:	66 a3 b0 b2 22 f0    	mov    %ax,0xf022b2b0
f0104295:	66 c7 05 b2 b2 22 f0 	movw   $0x8,0xf022b2b2
f010429c:	08 00 
f010429e:	c6 05 b4 b2 22 f0 00 	movb   $0x0,0xf022b2b4
f01042a5:	c6 05 b5 b2 22 f0 8f 	movb   $0x8f,0xf022b2b5
f01042ac:	c1 e8 10             	shr    $0x10,%eax
f01042af:	66 a3 b6 b2 22 f0    	mov    %ax,0xf022b2b6
	SETGATE(idt[T_SEGNP], 1, GD_KT, t_segnp, 0);
f01042b5:	b8 34 49 10 f0       	mov    $0xf0104934,%eax
f01042ba:	66 a3 b8 b2 22 f0    	mov    %ax,0xf022b2b8
f01042c0:	66 c7 05 ba b2 22 f0 	movw   $0x8,0xf022b2ba
f01042c7:	08 00 
f01042c9:	c6 05 bc b2 22 f0 00 	movb   $0x0,0xf022b2bc
f01042d0:	c6 05 bd b2 22 f0 8f 	movb   $0x8f,0xf022b2bd
f01042d7:	c1 e8 10             	shr    $0x10,%eax
f01042da:	66 a3 be b2 22 f0    	mov    %ax,0xf022b2be
	SETGATE(idt[T_STACK], 1, GD_KT, t_stack, 0);
f01042e0:	b8 38 49 10 f0       	mov    $0xf0104938,%eax
f01042e5:	66 a3 c0 b2 22 f0    	mov    %ax,0xf022b2c0
f01042eb:	66 c7 05 c2 b2 22 f0 	movw   $0x8,0xf022b2c2
f01042f2:	08 00 
f01042f4:	c6 05 c4 b2 22 f0 00 	movb   $0x0,0xf022b2c4
f01042fb:	c6 05 c5 b2 22 f0 8f 	movb   $0x8f,0xf022b2c5
f0104302:	c1 e8 10             	shr    $0x10,%eax
f0104305:	66 a3 c6 b2 22 f0    	mov    %ax,0xf022b2c6
	SETGATE(idt[T_GPFLT], 1, GD_KT, t_gpflt, 0);
f010430b:	b8 3c 49 10 f0       	mov    $0xf010493c,%eax
f0104310:	66 a3 c8 b2 22 f0    	mov    %ax,0xf022b2c8
f0104316:	66 c7 05 ca b2 22 f0 	movw   $0x8,0xf022b2ca
f010431d:	08 00 
f010431f:	c6 05 cc b2 22 f0 00 	movb   $0x0,0xf022b2cc
f0104326:	c6 05 cd b2 22 f0 8f 	movb   $0x8f,0xf022b2cd
f010432d:	c1 e8 10             	shr    $0x10,%eax
f0104330:	66 a3 ce b2 22 f0    	mov    %ax,0xf022b2ce
	SETGATE(idt[T_PGFLT], 1, GD_KT, t_pgflt, 0);
f0104336:	b8 40 49 10 f0       	mov    $0xf0104940,%eax
f010433b:	66 a3 d0 b2 22 f0    	mov    %ax,0xf022b2d0
f0104341:	66 c7 05 d2 b2 22 f0 	movw   $0x8,0xf022b2d2
f0104348:	08 00 
f010434a:	c6 05 d4 b2 22 f0 00 	movb   $0x0,0xf022b2d4
f0104351:	c6 05 d5 b2 22 f0 8f 	movb   $0x8f,0xf022b2d5
f0104358:	c1 e8 10             	shr    $0x10,%eax
f010435b:	66 a3 d6 b2 22 f0    	mov    %ax,0xf022b2d6
	SETGATE(idt[T_FPERR], 1, GD_KT, t_fperr, 0);
f0104361:	b8 4c 49 10 f0       	mov    $0xf010494c,%eax
f0104366:	66 a3 e0 b2 22 f0    	mov    %ax,0xf022b2e0
f010436c:	66 c7 05 e2 b2 22 f0 	movw   $0x8,0xf022b2e2
f0104373:	08 00 
f0104375:	c6 05 e4 b2 22 f0 00 	movb   $0x0,0xf022b2e4
f010437c:	c6 05 e5 b2 22 f0 8f 	movb   $0x8f,0xf022b2e5
f0104383:	c1 e8 10             	shr    $0x10,%eax
f0104386:	66 a3 e6 b2 22 f0    	mov    %ax,0xf022b2e6
	SETGATE(idt[T_ALIGN], 1, GD_KT, t_align, 0);
f010438c:	b8 44 49 10 f0       	mov    $0xf0104944,%eax
f0104391:	66 a3 e8 b2 22 f0    	mov    %ax,0xf022b2e8
f0104397:	66 c7 05 ea b2 22 f0 	movw   $0x8,0xf022b2ea
f010439e:	08 00 
f01043a0:	c6 05 ec b2 22 f0 00 	movb   $0x0,0xf022b2ec
f01043a7:	c6 05 ed b2 22 f0 8f 	movb   $0x8f,0xf022b2ed
f01043ae:	c1 e8 10             	shr    $0x10,%eax
f01043b1:	66 a3 ee b2 22 f0    	mov    %ax,0xf022b2ee
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f01043b7:	b8 52 49 10 f0       	mov    $0xf0104952,%eax
f01043bc:	66 a3 f0 b2 22 f0    	mov    %ax,0xf022b2f0
f01043c2:	66 c7 05 f2 b2 22 f0 	movw   $0x8,0xf022b2f2
f01043c9:	08 00 
f01043cb:	c6 05 f4 b2 22 f0 00 	movb   $0x0,0xf022b2f4
f01043d2:	c6 05 f5 b2 22 f0 8e 	movb   $0x8e,0xf022b2f5
f01043d9:	c1 e8 10             	shr    $0x10,%eax
f01043dc:	66 a3 f6 b2 22 f0    	mov    %ax,0xf022b2f6
	SETGATE(idt[T_SIMDERR], 1, GD_KT, t_simderr, 0);
f01043e2:	b8 58 49 10 f0       	mov    $0xf0104958,%eax
f01043e7:	66 a3 f8 b2 22 f0    	mov    %ax,0xf022b2f8
f01043ed:	66 c7 05 fa b2 22 f0 	movw   $0x8,0xf022b2fa
f01043f4:	08 00 
f01043f6:	c6 05 fc b2 22 f0 00 	movb   $0x0,0xf022b2fc
f01043fd:	c6 05 fd b2 22 f0 8f 	movb   $0x8f,0xf022b2fd
f0104404:	c1 e8 10             	shr    $0x10,%eax
f0104407:	66 a3 fe b2 22 f0    	mov    %ax,0xf022b2fe
	SETGATE(idt[T_SYSCALL], 1, GD_KT, t_syscall, 3);
f010440d:	b8 5e 49 10 f0       	mov    $0xf010495e,%eax
f0104412:	66 a3 e0 b3 22 f0    	mov    %ax,0xf022b3e0
f0104418:	66 c7 05 e2 b3 22 f0 	movw   $0x8,0xf022b3e2
f010441f:	08 00 
f0104421:	c6 05 e4 b3 22 f0 00 	movb   $0x0,0xf022b3e4
f0104428:	c6 05 e5 b3 22 f0 ef 	movb   $0xef,0xf022b3e5
f010442f:	c1 e8 10             	shr    $0x10,%eax
f0104432:	66 a3 e6 b3 22 f0    	mov    %ax,0xf022b3e6
	trap_init_percpu();
f0104438:	e8 e3 fb ff ff       	call   f0104020 <trap_init_percpu>
}
f010443d:	c9                   	leave  
f010443e:	c3                   	ret    

f010443f <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010443f:	55                   	push   %ebp
f0104440:	89 e5                	mov    %esp,%ebp
f0104442:	53                   	push   %ebx
f0104443:	83 ec 14             	sub    $0x14,%esp
f0104446:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104449:	8b 03                	mov    (%ebx),%eax
f010444b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010444f:	c7 04 24 21 7b 10 f0 	movl   $0xf0107b21,(%esp)
f0104456:	e8 a0 fb ff ff       	call   f0103ffb <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010445b:	8b 43 04             	mov    0x4(%ebx),%eax
f010445e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104462:	c7 04 24 30 7b 10 f0 	movl   $0xf0107b30,(%esp)
f0104469:	e8 8d fb ff ff       	call   f0103ffb <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010446e:	8b 43 08             	mov    0x8(%ebx),%eax
f0104471:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104475:	c7 04 24 3f 7b 10 f0 	movl   $0xf0107b3f,(%esp)
f010447c:	e8 7a fb ff ff       	call   f0103ffb <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104481:	8b 43 0c             	mov    0xc(%ebx),%eax
f0104484:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104488:	c7 04 24 4e 7b 10 f0 	movl   $0xf0107b4e,(%esp)
f010448f:	e8 67 fb ff ff       	call   f0103ffb <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104494:	8b 43 10             	mov    0x10(%ebx),%eax
f0104497:	89 44 24 04          	mov    %eax,0x4(%esp)
f010449b:	c7 04 24 5d 7b 10 f0 	movl   $0xf0107b5d,(%esp)
f01044a2:	e8 54 fb ff ff       	call   f0103ffb <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01044a7:	8b 43 14             	mov    0x14(%ebx),%eax
f01044aa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044ae:	c7 04 24 6c 7b 10 f0 	movl   $0xf0107b6c,(%esp)
f01044b5:	e8 41 fb ff ff       	call   f0103ffb <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01044ba:	8b 43 18             	mov    0x18(%ebx),%eax
f01044bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044c1:	c7 04 24 7b 7b 10 f0 	movl   $0xf0107b7b,(%esp)
f01044c8:	e8 2e fb ff ff       	call   f0103ffb <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01044cd:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01044d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044d4:	c7 04 24 8a 7b 10 f0 	movl   $0xf0107b8a,(%esp)
f01044db:	e8 1b fb ff ff       	call   f0103ffb <cprintf>
}
f01044e0:	83 c4 14             	add    $0x14,%esp
f01044e3:	5b                   	pop    %ebx
f01044e4:	5d                   	pop    %ebp
f01044e5:	c3                   	ret    

f01044e6 <print_trapframe>:
{
f01044e6:	55                   	push   %ebp
f01044e7:	89 e5                	mov    %esp,%ebp
f01044e9:	56                   	push   %esi
f01044ea:	53                   	push   %ebx
f01044eb:	83 ec 10             	sub    $0x10,%esp
f01044ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f01044f1:	e8 63 1c 00 00       	call   f0106159 <cpunum>
f01044f6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044fa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01044fe:	c7 04 24 ee 7b 10 f0 	movl   $0xf0107bee,(%esp)
f0104505:	e8 f1 fa ff ff       	call   f0103ffb <cprintf>
	print_regs(&tf->tf_regs);
f010450a:	89 1c 24             	mov    %ebx,(%esp)
f010450d:	e8 2d ff ff ff       	call   f010443f <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0104512:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0104516:	89 44 24 04          	mov    %eax,0x4(%esp)
f010451a:	c7 04 24 0c 7c 10 f0 	movl   $0xf0107c0c,(%esp)
f0104521:	e8 d5 fa ff ff       	call   f0103ffb <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0104526:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f010452a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010452e:	c7 04 24 1f 7c 10 f0 	movl   $0xf0107c1f,(%esp)
f0104535:	e8 c1 fa ff ff       	call   f0103ffb <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010453a:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f010453d:	83 f8 13             	cmp    $0x13,%eax
f0104540:	77 09                	ja     f010454b <print_trapframe+0x65>
		return excnames[trapno];
f0104542:	8b 14 85 c0 7e 10 f0 	mov    -0xfef8140(,%eax,4),%edx
f0104549:	eb 1f                	jmp    f010456a <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f010454b:	83 f8 30             	cmp    $0x30,%eax
f010454e:	74 15                	je     f0104565 <print_trapframe+0x7f>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104550:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f0104553:	83 fa 0f             	cmp    $0xf,%edx
f0104556:	ba a5 7b 10 f0       	mov    $0xf0107ba5,%edx
f010455b:	b9 b8 7b 10 f0       	mov    $0xf0107bb8,%ecx
f0104560:	0f 47 d1             	cmova  %ecx,%edx
f0104563:	eb 05                	jmp    f010456a <print_trapframe+0x84>
		return "System call";
f0104565:	ba 99 7b 10 f0       	mov    $0xf0107b99,%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010456a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010456e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104572:	c7 04 24 32 7c 10 f0 	movl   $0xf0107c32,(%esp)
f0104579:	e8 7d fa ff ff       	call   f0103ffb <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010457e:	3b 1d 60 ba 22 f0    	cmp    0xf022ba60,%ebx
f0104584:	75 19                	jne    f010459f <print_trapframe+0xb9>
f0104586:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010458a:	75 13                	jne    f010459f <print_trapframe+0xb9>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010458c:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010458f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104593:	c7 04 24 44 7c 10 f0 	movl   $0xf0107c44,(%esp)
f010459a:	e8 5c fa ff ff       	call   f0103ffb <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f010459f:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01045a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045a6:	c7 04 24 53 7c 10 f0 	movl   $0xf0107c53,(%esp)
f01045ad:	e8 49 fa ff ff       	call   f0103ffb <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f01045b2:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01045b6:	75 51                	jne    f0104609 <print_trapframe+0x123>
			tf->tf_err & 1 ? "protection" : "not-present");
f01045b8:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f01045bb:	89 c2                	mov    %eax,%edx
f01045bd:	83 e2 01             	and    $0x1,%edx
f01045c0:	ba c7 7b 10 f0       	mov    $0xf0107bc7,%edx
f01045c5:	b9 d2 7b 10 f0       	mov    $0xf0107bd2,%ecx
f01045ca:	0f 45 ca             	cmovne %edx,%ecx
f01045cd:	89 c2                	mov    %eax,%edx
f01045cf:	83 e2 02             	and    $0x2,%edx
f01045d2:	ba de 7b 10 f0       	mov    $0xf0107bde,%edx
f01045d7:	be e4 7b 10 f0       	mov    $0xf0107be4,%esi
f01045dc:	0f 44 d6             	cmove  %esi,%edx
f01045df:	83 e0 04             	and    $0x4,%eax
f01045e2:	b8 e9 7b 10 f0       	mov    $0xf0107be9,%eax
f01045e7:	be 4b 7d 10 f0       	mov    $0xf0107d4b,%esi
f01045ec:	0f 44 c6             	cmove  %esi,%eax
f01045ef:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01045f3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01045f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045fb:	c7 04 24 61 7c 10 f0 	movl   $0xf0107c61,(%esp)
f0104602:	e8 f4 f9 ff ff       	call   f0103ffb <cprintf>
f0104607:	eb 0c                	jmp    f0104615 <print_trapframe+0x12f>
		cprintf("\n");
f0104609:	c7 04 24 de 7c 10 f0 	movl   $0xf0107cde,(%esp)
f0104610:	e8 e6 f9 ff ff       	call   f0103ffb <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0104615:	8b 43 30             	mov    0x30(%ebx),%eax
f0104618:	89 44 24 04          	mov    %eax,0x4(%esp)
f010461c:	c7 04 24 70 7c 10 f0 	movl   $0xf0107c70,(%esp)
f0104623:	e8 d3 f9 ff ff       	call   f0103ffb <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104628:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010462c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104630:	c7 04 24 7f 7c 10 f0 	movl   $0xf0107c7f,(%esp)
f0104637:	e8 bf f9 ff ff       	call   f0103ffb <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f010463c:	8b 43 38             	mov    0x38(%ebx),%eax
f010463f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104643:	c7 04 24 92 7c 10 f0 	movl   $0xf0107c92,(%esp)
f010464a:	e8 ac f9 ff ff       	call   f0103ffb <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010464f:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104653:	74 27                	je     f010467c <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104655:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104658:	89 44 24 04          	mov    %eax,0x4(%esp)
f010465c:	c7 04 24 a1 7c 10 f0 	movl   $0xf0107ca1,(%esp)
f0104663:	e8 93 f9 ff ff       	call   f0103ffb <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104668:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f010466c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104670:	c7 04 24 b0 7c 10 f0 	movl   $0xf0107cb0,(%esp)
f0104677:	e8 7f f9 ff ff       	call   f0103ffb <cprintf>
}
f010467c:	83 c4 10             	add    $0x10,%esp
f010467f:	5b                   	pop    %ebx
f0104680:	5e                   	pop    %esi
f0104681:	5d                   	pop    %ebp
f0104682:	c3                   	ret    

f0104683 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104683:	55                   	push   %ebp
f0104684:	89 e5                	mov    %esp,%ebp
f0104686:	57                   	push   %edi
f0104687:	56                   	push   %esi
f0104688:	53                   	push   %ebx
f0104689:	83 ec 1c             	sub    $0x1c,%esp
f010468c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010468f:	0f 20 d6             	mov    %cr2,%esi
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
    if ((tf->tf_cs&3) == 0)
f0104692:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104696:	75 1c                	jne    f01046b4 <page_fault_handler+0x31>
    {
        panic("Page fault in Kernel-Mode. \n");
f0104698:	c7 44 24 08 c3 7c 10 	movl   $0xf0107cc3,0x8(%esp)
f010469f:	f0 
f01046a0:	c7 44 24 04 4d 01 00 	movl   $0x14d,0x4(%esp)
f01046a7:	00 
f01046a8:	c7 04 24 e0 7c 10 f0 	movl   $0xf0107ce0,(%esp)
f01046af:	e8 8c b9 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01046b4:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01046b7:	e8 9d 1a 00 00       	call   f0106159 <cpunum>
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01046bc:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01046c0:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f01046c4:	6b c0 74             	imul   $0x74,%eax,%eax
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01046c7:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01046cd:	8b 40 48             	mov    0x48(%eax),%eax
f01046d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046d4:	c7 04 24 98 7e 10 f0 	movl   $0xf0107e98,(%esp)
f01046db:	e8 1b f9 ff ff       	call   f0103ffb <cprintf>
	print_trapframe(tf);
f01046e0:	89 1c 24             	mov    %ebx,(%esp)
f01046e3:	e8 fe fd ff ff       	call   f01044e6 <print_trapframe>
	env_destroy(curenv);
f01046e8:	e8 6c 1a 00 00       	call   f0106159 <cpunum>
f01046ed:	6b c0 74             	imul   $0x74,%eax,%eax
f01046f0:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01046f6:	89 04 24             	mov    %eax,(%esp)
f01046f9:	e8 44 f6 ff ff       	call   f0103d42 <env_destroy>
}
f01046fe:	83 c4 1c             	add    $0x1c,%esp
f0104701:	5b                   	pop    %ebx
f0104702:	5e                   	pop    %esi
f0104703:	5f                   	pop    %edi
f0104704:	5d                   	pop    %ebp
f0104705:	c3                   	ret    

f0104706 <trap>:
{
f0104706:	55                   	push   %ebp
f0104707:	89 e5                	mov    %esp,%ebp
f0104709:	57                   	push   %edi
f010470a:	56                   	push   %esi
f010470b:	83 ec 20             	sub    $0x20,%esp
f010470e:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104711:	fc                   	cld    
	if (panicstr)
f0104712:	83 3d 80 be 22 f0 00 	cmpl   $0x0,0xf022be80
f0104719:	74 01                	je     f010471c <trap+0x16>
		asm volatile("hlt");
f010471b:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f010471c:	e8 38 1a 00 00       	call   f0106159 <cpunum>
f0104721:	6b d0 74             	imul   $0x74,%eax,%edx
f0104724:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
	asm volatile("lock; xchgl %0, %1"
f010472a:	b8 01 00 00 00       	mov    $0x1,%eax
f010472f:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104733:	83 f8 02             	cmp    $0x2,%eax
f0104736:	75 0c                	jne    f0104744 <trap+0x3e>
	spin_lock(&kernel_lock);
f0104738:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f010473f:	e8 93 1c 00 00       	call   f01063d7 <spin_lock>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104744:	9c                   	pushf  
f0104745:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0104746:	f6 c4 02             	test   $0x2,%ah
f0104749:	74 24                	je     f010476f <trap+0x69>
f010474b:	c7 44 24 0c ec 7c 10 	movl   $0xf0107cec,0xc(%esp)
f0104752:	f0 
f0104753:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f010475a:	f0 
f010475b:	c7 44 24 04 1a 01 00 	movl   $0x11a,0x4(%esp)
f0104762:	00 
f0104763:	c7 04 24 e0 7c 10 f0 	movl   $0xf0107ce0,(%esp)
f010476a:	e8 d1 b8 ff ff       	call   f0100040 <_panic>
	if ((tf->tf_cs & 3) == 3) {
f010476f:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104773:	83 e0 03             	and    $0x3,%eax
f0104776:	66 83 f8 03          	cmp    $0x3,%ax
f010477a:	0f 85 a7 00 00 00    	jne    f0104827 <trap+0x121>
f0104780:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f0104787:	e8 4b 1c 00 00       	call   f01063d7 <spin_lock>
		assert(curenv);
f010478c:	e8 c8 19 00 00       	call   f0106159 <cpunum>
f0104791:	6b c0 74             	imul   $0x74,%eax,%eax
f0104794:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f010479b:	75 24                	jne    f01047c1 <trap+0xbb>
f010479d:	c7 44 24 0c 05 7d 10 	movl   $0xf0107d05,0xc(%esp)
f01047a4:	f0 
f01047a5:	c7 44 24 08 cf 77 10 	movl   $0xf01077cf,0x8(%esp)
f01047ac:	f0 
f01047ad:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
f01047b4:	00 
f01047b5:	c7 04 24 e0 7c 10 f0 	movl   $0xf0107ce0,(%esp)
f01047bc:	e8 7f b8 ff ff       	call   f0100040 <_panic>
		if (curenv->env_status == ENV_DYING) {
f01047c1:	e8 93 19 00 00       	call   f0106159 <cpunum>
f01047c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01047c9:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01047cf:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01047d3:	75 2d                	jne    f0104802 <trap+0xfc>
			env_free(curenv);
f01047d5:	e8 7f 19 00 00       	call   f0106159 <cpunum>
f01047da:	6b c0 74             	imul   $0x74,%eax,%eax
f01047dd:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01047e3:	89 04 24             	mov    %eax,(%esp)
f01047e6:	e8 52 f3 ff ff       	call   f0103b3d <env_free>
			curenv = NULL;
f01047eb:	e8 69 19 00 00       	call   f0106159 <cpunum>
f01047f0:	6b c0 74             	imul   $0x74,%eax,%eax
f01047f3:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f01047fa:	00 00 00 
			sched_yield();
f01047fd:	e8 51 02 00 00       	call   f0104a53 <sched_yield>
		curenv->env_tf = *tf;
f0104802:	e8 52 19 00 00       	call   f0106159 <cpunum>
f0104807:	6b c0 74             	imul   $0x74,%eax,%eax
f010480a:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104810:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104815:	89 c7                	mov    %eax,%edi
f0104817:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0104819:	e8 3b 19 00 00       	call   f0106159 <cpunum>
f010481e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104821:	8b b0 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%esi
	last_tf = tf;
f0104827:	89 35 60 ba 22 f0    	mov    %esi,0xf022ba60
	if (tf->tf_trapno == T_SYSCALL)
f010482d:	8b 46 28             	mov    0x28(%esi),%eax
f0104830:	83 f8 30             	cmp    $0x30,%eax
f0104833:	75 40                	jne    f0104875 <trap+0x16f>
		struct PushRegs *registers = &curenv->env_tf.tf_regs;
f0104835:	e8 1f 19 00 00       	call   f0106159 <cpunum>
f010483a:	6b c0 74             	imul   $0x74,%eax,%eax
f010483d:	8b b0 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%esi
		dump = syscall(registers->reg_eax, registers->reg_edx, registers->reg_ecx, registers->reg_ebx, registers->reg_edi, registers->reg_esi);
f0104843:	8b 46 04             	mov    0x4(%esi),%eax
f0104846:	89 44 24 14          	mov    %eax,0x14(%esp)
f010484a:	8b 06                	mov    (%esi),%eax
f010484c:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104850:	8b 46 10             	mov    0x10(%esi),%eax
f0104853:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104857:	8b 46 18             	mov    0x18(%esi),%eax
f010485a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010485e:	8b 46 14             	mov    0x14(%esi),%eax
f0104861:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104865:	8b 46 1c             	mov    0x1c(%esi),%eax
f0104868:	89 04 24             	mov    %eax,(%esp)
f010486b:	e8 a0 02 00 00       	call   f0104b10 <syscall>
		registers->reg_eax = dump; // Set
f0104870:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104873:	eb 75                	jmp    f01048ea <trap+0x1e4>
	else if (tf->tf_trapno == T_BRKPT)
f0104875:	83 f8 03             	cmp    $0x3,%eax
f0104878:	75 16                	jne    f0104890 <trap+0x18a>
		cprintf("Trap: Breakpoint. \n");
f010487a:	c7 04 24 0c 7d 10 f0 	movl   $0xf0107d0c,(%esp)
f0104881:	e8 75 f7 ff ff       	call   f0103ffb <cprintf>
		monitor(tf);
f0104886:	89 34 24             	mov    %esi,(%esp)
f0104889:	e8 9a c1 ff ff       	call   f0100a28 <monitor>
f010488e:	eb 19                	jmp    f01048a9 <trap+0x1a3>
    else if (tf->tf_trapno == T_PGFLT)
f0104890:	83 f8 0e             	cmp    $0xe,%eax
f0104893:	75 14                	jne    f01048a9 <trap+0x1a3>
        cprintf("Trap: Page Fault Error \n");
f0104895:	c7 04 24 20 7d 10 f0 	movl   $0xf0107d20,(%esp)
f010489c:	e8 5a f7 ff ff       	call   f0103ffb <cprintf>
        page_fault_handler(tf);
f01048a1:	89 34 24             	mov    %esi,(%esp)
f01048a4:	e8 da fd ff ff       	call   f0104683 <page_fault_handler>
	print_trapframe(tf);
f01048a9:	89 34 24             	mov    %esi,(%esp)
f01048ac:	e8 35 fc ff ff       	call   f01044e6 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f01048b1:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01048b6:	75 1c                	jne    f01048d4 <trap+0x1ce>
		panic("unhandled trap in kernel");
f01048b8:	c7 44 24 08 39 7d 10 	movl   $0xf0107d39,0x8(%esp)
f01048bf:	f0 
f01048c0:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
f01048c7:	00 
f01048c8:	c7 04 24 e0 7c 10 f0 	movl   $0xf0107ce0,(%esp)
f01048cf:	e8 6c b7 ff ff       	call   f0100040 <_panic>
		env_destroy(curenv);
f01048d4:	e8 80 18 00 00       	call   f0106159 <cpunum>
f01048d9:	6b c0 74             	imul   $0x74,%eax,%eax
f01048dc:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01048e2:	89 04 24             	mov    %eax,(%esp)
f01048e5:	e8 58 f4 ff ff       	call   f0103d42 <env_destroy>
	env_run(curenv);
f01048ea:	e8 6a 18 00 00       	call   f0106159 <cpunum>
f01048ef:	6b c0 74             	imul   $0x74,%eax,%eax
f01048f2:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01048f8:	89 04 24             	mov    %eax,(%esp)
f01048fb:	e8 e3 f4 ff ff       	call   f0103de3 <env_run>

f0104900 <t_divide>:
//          Do something like this if there is no error code for the trap
// HINT 2 : TRAPHANDLER(t_dblflt, T_DBLFLT);
//          Do something like this if the trap includes an error code..
// HINT 3 : READ Intel's manual to check if the trap includes an error code
//          or not...
	TRAPHANDLER_NOEC(t_divide, T_DIVIDE); // Divide Error
f0104900:	6a 00                	push   $0x0
f0104902:	6a 00                	push   $0x0
f0104904:	eb 67                	jmp    f010496d <_alltraps>

f0104906 <t_debug>:
	TRAPHANDLER_NOEC(t_debug, T_DEBUG); // Debug Exception
f0104906:	6a 00                	push   $0x0
f0104908:	6a 01                	push   $0x1
f010490a:	eb 61                	jmp    f010496d <_alltraps>

f010490c <t_nmi>:
	TRAPHANDLER_NOEC(t_nmi, T_NMI); // NMI interrupt
f010490c:	6a 00                	push   $0x0
f010490e:	6a 02                	push   $0x2
f0104910:	eb 5b                	jmp    f010496d <_alltraps>

f0104912 <t_brkpt>:
	TRAPHANDLER_NOEC(t_brkpt, T_BRKPT); // Breakpoint
f0104912:	6a 00                	push   $0x0
f0104914:	6a 03                	push   $0x3
f0104916:	eb 55                	jmp    f010496d <_alltraps>

f0104918 <t_oflow>:
	TRAPHANDLER_NOEC(t_oflow, T_OFLOW); // Overflow error
f0104918:	6a 00                	push   $0x0
f010491a:	6a 04                	push   $0x4
f010491c:	eb 4f                	jmp    f010496d <_alltraps>

f010491e <t_bound>:
	TRAPHANDLER_NOEC(t_bound, T_BOUND); // Out of bounds
f010491e:	6a 00                	push   $0x0
f0104920:	6a 05                	push   $0x5
f0104922:	eb 49                	jmp    f010496d <_alltraps>

f0104924 <t_illop>:
	TRAPHANDLER_NOEC(t_illop, T_ILLOP); //Invallid OPcode
f0104924:	6a 00                	push   $0x0
f0104926:	6a 06                	push   $0x6
f0104928:	eb 43                	jmp    f010496d <_alltraps>

f010492a <t_device>:
	TRAPHANDLER_NOEC(t_device, T_DEVICE); // Device Not Available
f010492a:	6a 00                	push   $0x0
f010492c:	6a 07                	push   $0x7
f010492e:	eb 3d                	jmp    f010496d <_alltraps>

f0104930 <t_dblflt>:
	
	// now we're at the bit of the table where we need to toss out error codes
	TRAPHANDLER(t_dblflt, T_DBLFLT); // double fault
f0104930:	6a 08                	push   $0x8
f0104932:	eb 39                	jmp    f010496d <_alltraps>

f0104934 <t_segnp>:
	TRAPHANDLER(t_segnp, T_SEGNP); // Segment Not Present
f0104934:	6a 0b                	push   $0xb
f0104936:	eb 35                	jmp    f010496d <_alltraps>

f0104938 <t_stack>:
	TRAPHANDLER(t_stack, T_STACK); // Stack segment fault
f0104938:	6a 0c                	push   $0xc
f010493a:	eb 31                	jmp    f010496d <_alltraps>

f010493c <t_gpflt>:
	TRAPHANDLER(t_gpflt, T_GPFLT); // General fault
f010493c:	6a 0d                	push   $0xd
f010493e:	eb 2d                	jmp    f010496d <_alltraps>

f0104940 <t_pgflt>:
	TRAPHANDLER(t_pgflt, T_PGFLT); // Page fault
f0104940:	6a 0e                	push   $0xe
f0104942:	eb 29                	jmp    f010496d <_alltraps>

f0104944 <t_align>:
	TRAPHANDLER(t_align, T_ALIGN); // Allignment check
f0104944:	6a 11                	push   $0x11
f0104946:	eb 25                	jmp    f010496d <_alltraps>

f0104948 <t_tss>:
	TRAPHANDLER(t_tss, T_TSS);
f0104948:	6a 0a                	push   $0xa
f010494a:	eb 21                	jmp    f010496d <_alltraps>

f010494c <t_fperr>:

	// back to no error codes
	TRAPHANDLER_NOEC(t_fperr, T_FPERR); // Floating point error
f010494c:	6a 00                	push   $0x0
f010494e:	6a 10                	push   $0x10
f0104950:	eb 1b                	jmp    f010496d <_alltraps>

f0104952 <t_mchk>:
	TRAPHANDLER_NOEC(t_mchk, T_MCHK); // Machine check
f0104952:	6a 00                	push   $0x0
f0104954:	6a 12                	push   $0x12
f0104956:	eb 15                	jmp    f010496d <_alltraps>

f0104958 <t_simderr>:
	TRAPHANDLER_NOEC(t_simderr, T_SIMDERR); // SIMD floating point exception
f0104958:	6a 00                	push   $0x0
f010495a:	6a 13                	push   $0x13
f010495c:	eb 0f                	jmp    f010496d <_alltraps>

f010495e <t_syscall>:
	TRAPHANDLER_NOEC(t_syscall, T_SYSCALL); // system call
f010495e:	6a 00                	push   $0x0
f0104960:	6a 30                	push   $0x30
f0104962:	eb 09                	jmp    f010496d <_alltraps>

f0104964 <t_default>:
	TRAPHANDLER_NOEC(t_default, T_DEFAULT); // catch all
f0104964:	6a 00                	push   $0x0
f0104966:	68 f4 01 00 00       	push   $0x1f4
f010496b:	eb 00                	jmp    f010496d <_alltraps>

f010496d <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds // push values to make the stack look like a struct Trapframe
f010496d:	1e                   	push   %ds
	pushl %es
f010496e:	06                   	push   %es
	pushal
f010496f:	60                   	pusha  
	movw $GD_KD, %ax
f0104970:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104974:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104976:	8e c0                	mov    %eax,%es
	pushl %esp
f0104978:	54                   	push   %esp
	call trap
f0104979:	e8 88 fd ff ff       	call   f0104706 <trap>

f010497e <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010497e:	55                   	push   %ebp
f010497f:	89 e5                	mov    %esp,%ebp
f0104981:	83 ec 18             	sub    $0x18,%esp
f0104984:	8b 15 48 b2 22 f0    	mov    0xf022b248,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010498a:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f010498f:	8b 4a 54             	mov    0x54(%edx),%ecx
f0104992:	83 e9 01             	sub    $0x1,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104995:	83 f9 02             	cmp    $0x2,%ecx
f0104998:	76 0f                	jbe    f01049a9 <sched_halt+0x2b>
	for (i = 0; i < NENV; i++) {
f010499a:	83 c0 01             	add    $0x1,%eax
f010499d:	83 c2 7c             	add    $0x7c,%edx
f01049a0:	3d 00 04 00 00       	cmp    $0x400,%eax
f01049a5:	75 e8                	jne    f010498f <sched_halt+0x11>
f01049a7:	eb 07                	jmp    f01049b0 <sched_halt+0x32>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f01049a9:	3d 00 04 00 00       	cmp    $0x400,%eax
f01049ae:	75 1a                	jne    f01049ca <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f01049b0:	c7 04 24 10 7f 10 f0 	movl   $0xf0107f10,(%esp)
f01049b7:	e8 3f f6 ff ff       	call   f0103ffb <cprintf>
		while (1)
			monitor(NULL);
f01049bc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01049c3:	e8 60 c0 ff ff       	call   f0100a28 <monitor>
f01049c8:	eb f2                	jmp    f01049bc <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f01049ca:	e8 8a 17 00 00       	call   f0106159 <cpunum>
f01049cf:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d2:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f01049d9:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01049dc:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01049e1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01049e6:	77 20                	ja     f0104a08 <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01049e8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01049ec:	c7 44 24 08 88 68 10 	movl   $0xf0106888,0x8(%esp)
f01049f3:	f0 
f01049f4:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
f01049fb:	00 
f01049fc:	c7 04 24 39 7f 10 f0 	movl   $0xf0107f39,(%esp)
f0104a03:	e8 38 b6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104a08:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104a0d:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104a10:	e8 44 17 00 00       	call   f0106159 <cpunum>
f0104a15:	6b d0 74             	imul   $0x74,%eax,%edx
f0104a18:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
	asm volatile("lock; xchgl %0, %1"
f0104a1e:	b8 02 00 00 00       	mov    $0x2,%eax
f0104a23:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
	spin_unlock(&kernel_lock);
f0104a27:	c7 04 24 c0 03 12 f0 	movl   $0xf01203c0,(%esp)
f0104a2e:	e8 50 1a 00 00       	call   f0106483 <spin_unlock>
	asm volatile("pause");
f0104a33:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		//"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104a35:	e8 1f 17 00 00       	call   f0106159 <cpunum>
f0104a3a:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f0104a3d:	8b 80 30 c0 22 f0    	mov    -0xfdd3fd0(%eax),%eax
f0104a43:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104a48:	89 c4                	mov    %eax,%esp
f0104a4a:	6a 00                	push   $0x0
f0104a4c:	6a 00                	push   $0x0
f0104a4e:	f4                   	hlt    
f0104a4f:	eb fd                	jmp    f0104a4e <sched_halt+0xd0>
}
f0104a51:	c9                   	leave  
f0104a52:	c3                   	ret    

f0104a53 <sched_yield>:
{
f0104a53:	55                   	push   %ebp
f0104a54:	89 e5                	mov    %esp,%ebp
f0104a56:	56                   	push   %esi
f0104a57:	53                   	push   %ebx
f0104a58:	83 ec 10             	sub    $0x10,%esp
	if (curenv)
f0104a5b:	e8 f9 16 00 00       	call   f0106159 <cpunum>
f0104a60:	6b c0 74             	imul   $0x74,%eax,%eax
	int current_id = 0;
f0104a63:	bb 00 00 00 00       	mov    $0x0,%ebx
	if (curenv)
f0104a68:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0104a6f:	74 17                	je     f0104a88 <sched_yield+0x35>
		current_id = ENVX(curenv->env_id);
f0104a71:	e8 e3 16 00 00       	call   f0106159 <cpunum>
f0104a76:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a79:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104a7f:	8b 58 48             	mov    0x48(%eax),%ebx
f0104a82:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
		if (envs[(current_id + i) % NENV].env_status == ENV_RUNNABLE)
f0104a88:	8b 35 48 b2 22 f0    	mov    0xf022b248,%esi
	for (int i = 1; i < NENV; i++) // cycle through environments
f0104a8e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104a93:	8d 0c 18             	lea    (%eax,%ebx,1),%ecx
		if (envs[(current_id + i) % NENV].env_status == ENV_RUNNABLE)
f0104a96:	89 ca                	mov    %ecx,%edx
f0104a98:	c1 fa 1f             	sar    $0x1f,%edx
f0104a9b:	c1 ea 16             	shr    $0x16,%edx
f0104a9e:	01 d1                	add    %edx,%ecx
f0104aa0:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0104aa6:	29 d1                	sub    %edx,%ecx
f0104aa8:	6b d1 7c             	imul   $0x7c,%ecx,%edx
f0104aab:	01 f2                	add    %esi,%edx
f0104aad:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104ab1:	75 08                	jne    f0104abb <sched_yield+0x68>
			env_run(&envs[(current_id + i) % NENV]);
f0104ab3:	89 14 24             	mov    %edx,(%esp)
f0104ab6:	e8 28 f3 ff ff       	call   f0103de3 <env_run>
	for (int i = 1; i < NENV; i++) // cycle through environments
f0104abb:	83 c0 01             	add    $0x1,%eax
f0104abe:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104ac3:	75 ce                	jne    f0104a93 <sched_yield+0x40>
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104ac5:	e8 8f 16 00 00       	call   f0106159 <cpunum>
f0104aca:	6b c0 74             	imul   $0x74,%eax,%eax
f0104acd:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0104ad4:	74 2a                	je     f0104b00 <sched_yield+0xad>
f0104ad6:	e8 7e 16 00 00       	call   f0106159 <cpunum>
f0104adb:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ade:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104ae4:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104ae8:	75 16                	jne    f0104b00 <sched_yield+0xad>
		env_run(curenv);
f0104aea:	e8 6a 16 00 00       	call   f0106159 <cpunum>
f0104aef:	6b c0 74             	imul   $0x74,%eax,%eax
f0104af2:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104af8:	89 04 24             	mov    %eax,(%esp)
f0104afb:	e8 e3 f2 ff ff       	call   f0103de3 <env_run>
	sched_halt();
f0104b00:	e8 79 fe ff ff       	call   f010497e <sched_halt>
}
f0104b05:	83 c4 10             	add    $0x10,%esp
f0104b08:	5b                   	pop    %ebx
f0104b09:	5e                   	pop    %esi
f0104b0a:	5d                   	pop    %ebp
f0104b0b:	c3                   	ret    
f0104b0c:	66 90                	xchg   %ax,%ax
f0104b0e:	66 90                	xchg   %ax,%ax

f0104b10 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104b10:	55                   	push   %ebp
f0104b11:	89 e5                	mov    %esp,%ebp
f0104b13:	57                   	push   %edi
f0104b14:	56                   	push   %esi
f0104b15:	53                   	push   %ebx
f0104b16:	83 ec 2c             	sub    $0x2c,%esp
f0104b19:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	switch (syscallno) {
f0104b1c:	83 f8 0a             	cmp    $0xa,%eax
f0104b1f:	0f 87 93 03 00 00    	ja     f0104eb8 <syscall+0x3a8>
f0104b25:	ff 24 85 7c 7f 10 f0 	jmp    *-0xfef8084(,%eax,4)
	user_mem_assert(curenv, s, len, PTE_U | PTE_P);
f0104b2c:	e8 28 16 00 00       	call   f0106159 <cpunum>
f0104b31:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104b38:	00 
f0104b39:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104b3c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104b40:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104b43:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104b47:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b4a:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104b50:	89 04 24             	mov    %eax,(%esp)
f0104b53:	e8 a6 ea ff ff       	call   f01035fe <user_mem_assert>
	cprintf("%.*s", len, s);
f0104b58:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b5b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104b5f:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b62:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b66:	c7 04 24 f3 6b 10 f0 	movl   $0xf0106bf3,(%esp)
f0104b6d:	e8 89 f4 ff ff       	call   f0103ffb <cprintf>
		case SYS_cputs:
			sys_cputs((const char*) a1, (size_t) a2);
			return 0;
f0104b72:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b77:	e9 41 03 00 00       	jmp    f0104ebd <syscall+0x3ad>
	return cons_getc();
f0104b7c:	e8 a4 ba ff ff       	call   f0100625 <cons_getc>
			break;
		case SYS_cgetc:
			return sys_cgetc();
f0104b81:	e9 37 03 00 00       	jmp    f0104ebd <syscall+0x3ad>
	return curenv->env_id;
f0104b86:	e8 ce 15 00 00       	call   f0106159 <cpunum>
f0104b8b:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b8e:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104b94:	8b 40 48             	mov    0x48(%eax),%eax
			break;
		case SYS_getenvid:
			return sys_getenvid();
f0104b97:	e9 21 03 00 00       	jmp    f0104ebd <syscall+0x3ad>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104b9c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104ba3:	00 
f0104ba4:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104ba7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bab:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bae:	89 04 24             	mov    %eax,(%esp)
f0104bb1:	e8 23 eb ff ff       	call   f01036d9 <envid2env>
f0104bb6:	85 c0                	test   %eax,%eax
f0104bb8:	78 69                	js     f0104c23 <syscall+0x113>
	if (e == curenv)
f0104bba:	e8 9a 15 00 00       	call   f0106159 <cpunum>
f0104bbf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104bc2:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bc5:	39 90 28 c0 22 f0    	cmp    %edx,-0xfdd3fd8(%eax)
f0104bcb:	75 23                	jne    f0104bf0 <syscall+0xe0>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104bcd:	e8 87 15 00 00       	call   f0106159 <cpunum>
f0104bd2:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bd5:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104bdb:	8b 40 48             	mov    0x48(%eax),%eax
f0104bde:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104be2:	c7 04 24 46 7f 10 f0 	movl   $0xf0107f46,(%esp)
f0104be9:	e8 0d f4 ff ff       	call   f0103ffb <cprintf>
f0104bee:	eb 28                	jmp    f0104c18 <syscall+0x108>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104bf0:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104bf3:	e8 61 15 00 00       	call   f0106159 <cpunum>
f0104bf8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104bfc:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bff:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104c05:	8b 40 48             	mov    0x48(%eax),%eax
f0104c08:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c0c:	c7 04 24 61 7f 10 f0 	movl   $0xf0107f61,(%esp)
f0104c13:	e8 e3 f3 ff ff       	call   f0103ffb <cprintf>
	env_destroy(e);
f0104c18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c1b:	89 04 24             	mov    %eax,(%esp)
f0104c1e:	e8 1f f1 ff ff       	call   f0103d42 <env_destroy>
			break;
		case SYS_env_destroy:
			sys_env_destroy(a1);
			return 0;
f0104c23:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c28:	e9 90 02 00 00       	jmp    f0104ebd <syscall+0x3ad>
	sched_yield();
f0104c2d:	e8 21 fe ff ff       	call   f0104a53 <sched_yield>
	flag = env_alloc(&env, curenv->env_id);
f0104c32:	e8 22 15 00 00       	call   f0106159 <cpunum>
f0104c37:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c3a:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104c40:	8b 40 48             	mov    0x48(%eax),%eax
f0104c43:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c47:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c4a:	89 04 24             	mov    %eax,(%esp)
f0104c4d:	e8 a7 eb ff ff       	call   f01037f9 <env_alloc>
		return flag;
f0104c52:	89 c2                	mov    %eax,%edx
	if (flag)
f0104c54:	85 c0                	test   %eax,%eax
f0104c56:	75 2e                	jne    f0104c86 <syscall+0x176>
		env->env_tf = curenv->env_tf;
f0104c58:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104c5b:	e8 f9 14 00 00       	call   f0106159 <cpunum>
f0104c60:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c63:	8b b0 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%esi
f0104c69:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104c6e:	89 df                	mov    %ebx,%edi
f0104c70:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		env->env_status = ENV_NOT_RUNNABLE;
f0104c72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c75:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
		env->env_tf.tf_regs.reg_eax = 0;
f0104c7c:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
		return env->env_id;
f0104c83:	8b 50 48             	mov    0x48(%eax),%edx
		case SYS_yield:
			sys_yield();
			return 0;
			break;
		case SYS_exofork:
			return sys_exofork();
f0104c86:	89 d0                	mov    %edx,%eax
f0104c88:	e9 30 02 00 00       	jmp    f0104ebd <syscall+0x3ad>
	ret = envid2env(envid, &env, 1);
f0104c8d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104c94:	00 
f0104c95:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c98:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c9c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c9f:	89 04 24             	mov    %eax,(%esp)
f0104ca2:	e8 32 ea ff ff       	call   f01036d9 <envid2env>
	if (ret) {return ret;}
f0104ca7:	89 c2                	mov    %eax,%edx
f0104ca9:	85 c0                	test   %eax,%eax
f0104cab:	75 22                	jne    f0104ccf <syscall+0x1bf>
	if (env->env_status == ENV_RUNNABLE || env->env_status == ENV_NOT_RUNNABLE) // Check if it's been set properly
f0104cad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104cb0:	8b 50 54             	mov    0x54(%eax),%edx
f0104cb3:	83 fa 04             	cmp    $0x4,%edx
f0104cb6:	74 05                	je     f0104cbd <syscall+0x1ad>
f0104cb8:	83 fa 02             	cmp    $0x2,%edx
f0104cbb:	75 0d                	jne    f0104cca <syscall+0x1ba>
		env->env_status = status; // If so, update its status
f0104cbd:	8b 75 10             	mov    0x10(%ebp),%esi
f0104cc0:	89 70 54             	mov    %esi,0x54(%eax)
		return 0;
f0104cc3:	ba 00 00 00 00       	mov    $0x0,%edx
f0104cc8:	eb 05                	jmp    f0104ccf <syscall+0x1bf>
		return -E_INVAL;
f0104cca:	ba fd ff ff ff       	mov    $0xfffffffd,%edx
			break;
		case SYS_env_set_status:
			return sys_env_set_status(a1, a2);
f0104ccf:	89 d0                	mov    %edx,%eax
f0104cd1:	e9 e7 01 00 00       	jmp    f0104ebd <syscall+0x3ad>
	if ((uint32_t) va >= UTOP) // check if we're in the size
f0104cd6:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104cdd:	77 6b                	ja     f0104d4a <syscall+0x23a>
	if ((uint32_t) va % PGSIZE) // check if we're aligned to page
f0104cdf:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104ce6:	75 6c                	jne    f0104d54 <syscall+0x244>
	ret = envid2env(envid, &env, 1);
f0104ce8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104cef:	00 
f0104cf0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104cf3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104cf7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104cfa:	89 04 24             	mov    %eax,(%esp)
f0104cfd:	e8 d7 e9 ff ff       	call   f01036d9 <envid2env>
f0104d02:	89 c2                	mov    %eax,%edx
	if (ret) { return ret;}
f0104d04:	85 d2                	test   %edx,%edx
f0104d06:	0f 85 b1 01 00 00    	jne    f0104ebd <syscall+0x3ad>
	if (!(perm & PTE_U) || !(perm & PTE_P) || (perm & ~PTE_SYSCALL))
f0104d0c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d0f:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f0104d14:	83 f8 05             	cmp    $0x5,%eax
f0104d17:	75 45                	jne    f0104d5e <syscall+0x24e>
	page = page_alloc(1);
f0104d19:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0104d20:	e8 4c c4 ff ff       	call   f0101171 <page_alloc>
	ret = page_insert(env->env_pgdir, page, va, perm);
f0104d25:	8b 75 14             	mov    0x14(%ebp),%esi
f0104d28:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104d2c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104d2f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104d33:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d37:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d3a:	8b 40 60             	mov    0x60(%eax),%eax
f0104d3d:	89 04 24             	mov    %eax,(%esp)
f0104d40:	e8 36 c7 ff ff       	call   f010147b <page_insert>
f0104d45:	e9 73 01 00 00       	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104d4a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d4f:	e9 69 01 00 00       	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104d54:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104d59:	e9 5f 01 00 00       	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104d5e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
			break;
		case SYS_page_alloc:
			return sys_page_alloc(a1, (void*) a2, a3);
f0104d63:	e9 55 01 00 00       	jmp    f0104ebd <syscall+0x3ad>
	if (((uint32_t) srcva >= UTOP) || ((uint32_t) dstva >= UTOP)) // check if its in range
f0104d68:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104d6f:	0f 87 c7 00 00 00    	ja     f0104e3c <syscall+0x32c>
f0104d75:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104d7c:	0f 87 ba 00 00 00    	ja     f0104e3c <syscall+0x32c>
f0104d82:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d85:	0b 45 18             	or     0x18(%ebp),%eax
	else if (((uint32_t) srcva % PGSIZE) || ((uint32_t) dstva % PGSIZE)) // check if its alligned to page
f0104d88:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0104d8d:	0f 85 b0 00 00 00    	jne    f0104e43 <syscall+0x333>
	ret = envid2env(srcenvid, &env_source, 0);
f0104d93:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0104d9a:	00 
f0104d9b:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104d9e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104da2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104da5:	89 04 24             	mov    %eax,(%esp)
f0104da8:	e8 2c e9 ff ff       	call   f01036d9 <envid2env>
f0104dad:	89 c2                	mov    %eax,%edx
	if (ret) { return ret; }
f0104daf:	85 d2                	test   %edx,%edx
f0104db1:	0f 85 06 01 00 00    	jne    f0104ebd <syscall+0x3ad>
	ret = envid2env(dstenvid, &env_destination, 0);
f0104db7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0104dbe:	00 
f0104dbf:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104dc2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104dc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dc9:	89 04 24             	mov    %eax,(%esp)
f0104dcc:	e8 08 e9 ff ff       	call   f01036d9 <envid2env>
f0104dd1:	89 c2                	mov    %eax,%edx
	if (ret) { return ret; }
f0104dd3:	85 d2                	test   %edx,%edx
f0104dd5:	0f 85 e2 00 00 00    	jne    f0104ebd <syscall+0x3ad>
	page = page_lookup(env_source->env_pgdir, srcva, &entry);
f0104ddb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104dde:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104de2:	8b 45 10             	mov    0x10(%ebp),%eax
f0104de5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104de9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104dec:	8b 40 60             	mov    0x60(%eax),%eax
f0104def:	89 04 24             	mov    %eax,(%esp)
f0104df2:	e8 85 c5 ff ff       	call   f010137c <page_lookup>
	if (page == NULL)
f0104df7:	85 c0                	test   %eax,%eax
f0104df9:	74 4f                	je     f0104e4a <syscall+0x33a>
	if (!(perm & PTE_U) || !(perm & PTE_P) || (perm & ~PTE_SYSCALL))
f0104dfb:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104dfe:	81 e2 fd f1 ff ff    	and    $0xfffff1fd,%edx
f0104e04:	83 fa 05             	cmp    $0x5,%edx
f0104e07:	75 48                	jne    f0104e51 <syscall+0x341>
	if ((perm & PTE_W) && !(*entry & PTE_W))
f0104e09:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104e0d:	74 08                	je     f0104e17 <syscall+0x307>
f0104e0f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e12:	f6 02 02             	testb  $0x2,(%edx)
f0104e15:	74 41                	je     f0104e58 <syscall+0x348>
	ret = page_insert(env_destination->env_pgdir, page, dstva, perm); // finally do our insertion
f0104e17:	8b 7d 1c             	mov    0x1c(%ebp),%edi
f0104e1a:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104e1e:	8b 7d 18             	mov    0x18(%ebp),%edi
f0104e21:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104e25:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e29:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e2c:	8b 40 60             	mov    0x60(%eax),%eax
f0104e2f:	89 04 24             	mov    %eax,(%esp)
f0104e32:	e8 44 c6 ff ff       	call   f010147b <page_insert>
f0104e37:	e9 81 00 00 00       	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104e3c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e41:	eb 7a                	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104e43:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e48:	eb 73                	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104e4a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e4f:	eb 6c                	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104e51:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e56:	eb 65                	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104e58:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
			break;
		case SYS_page_map:
			return sys_page_map(a1, (void*) a2, a3, (void*) a4, a5);
f0104e5d:	eb 5e                	jmp    f0104ebd <syscall+0x3ad>
	if ((uint32_t) va >= UTOP) // check if we're in the size
f0104e5f:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104e66:	77 42                	ja     f0104eaa <syscall+0x39a>
	if ((uint32_t) va % PGSIZE) // check if we're aligned to page
f0104e68:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104e6f:	75 40                	jne    f0104eb1 <syscall+0x3a1>
	ret = envid2env(envid, &env, 1);
f0104e71:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104e78:	00 
f0104e79:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104e7c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e80:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e83:	89 04 24             	mov    %eax,(%esp)
f0104e86:	e8 4e e8 ff ff       	call   f01036d9 <envid2env>
f0104e8b:	89 c3                	mov    %eax,%ebx
	if (ret) { return ret; }
f0104e8d:	85 db                	test   %ebx,%ebx
f0104e8f:	75 2c                	jne    f0104ebd <syscall+0x3ad>
	page_remove(env->env_pgdir, va);
f0104e91:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e98:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104e9b:	8b 40 60             	mov    0x60(%eax),%eax
f0104e9e:	89 04 24             	mov    %eax,(%esp)
f0104ea1:	e8 84 c5 ff ff       	call   f010142a <page_remove>
	return 0;
f0104ea6:	89 d8                	mov    %ebx,%eax
f0104ea8:	eb 13                	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104eaa:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104eaf:	eb 0c                	jmp    f0104ebd <syscall+0x3ad>
		return -E_INVAL;
f0104eb1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
			break;
		case SYS_page_unmap:
			return sys_page_unmap(a1, (void*) a2);
f0104eb6:	eb 05                	jmp    f0104ebd <syscall+0x3ad>
			break;
			
	default:
		return -E_INVAL;
f0104eb8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0104ebd:	83 c4 2c             	add    $0x2c,%esp
f0104ec0:	5b                   	pop    %ebx
f0104ec1:	5e                   	pop    %esi
f0104ec2:	5f                   	pop    %edi
f0104ec3:	5d                   	pop    %ebp
f0104ec4:	c3                   	ret    

f0104ec5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104ec5:	55                   	push   %ebp
f0104ec6:	89 e5                	mov    %esp,%ebp
f0104ec8:	57                   	push   %edi
f0104ec9:	56                   	push   %esi
f0104eca:	53                   	push   %ebx
f0104ecb:	83 ec 14             	sub    $0x14,%esp
f0104ece:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104ed1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104ed4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104ed7:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104eda:	8b 1a                	mov    (%edx),%ebx
f0104edc:	8b 01                	mov    (%ecx),%eax
f0104ede:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104ee1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104ee8:	e9 88 00 00 00       	jmp    f0104f75 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104eed:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104ef0:	01 d8                	add    %ebx,%eax
f0104ef2:	89 c7                	mov    %eax,%edi
f0104ef4:	c1 ef 1f             	shr    $0x1f,%edi
f0104ef7:	01 c7                	add    %eax,%edi
f0104ef9:	d1 ff                	sar    %edi
f0104efb:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104efe:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f01:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104f04:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104f06:	eb 03                	jmp    f0104f0b <stab_binsearch+0x46>
			m--;
f0104f08:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0104f0b:	39 c3                	cmp    %eax,%ebx
f0104f0d:	7f 1f                	jg     f0104f2e <stab_binsearch+0x69>
f0104f0f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104f13:	83 ea 0c             	sub    $0xc,%edx
f0104f16:	39 f1                	cmp    %esi,%ecx
f0104f18:	75 ee                	jne    f0104f08 <stab_binsearch+0x43>
f0104f1a:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104f1d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104f20:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104f23:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104f27:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104f2a:	76 18                	jbe    f0104f44 <stab_binsearch+0x7f>
f0104f2c:	eb 05                	jmp    f0104f33 <stab_binsearch+0x6e>
			l = true_m + 1;
f0104f2e:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104f31:	eb 42                	jmp    f0104f75 <stab_binsearch+0xb0>
			*region_left = m;
f0104f33:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104f36:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104f38:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0104f3b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f42:	eb 31                	jmp    f0104f75 <stab_binsearch+0xb0>
		} else if (stabs[m].n_value > addr) {
f0104f44:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104f47:	73 17                	jae    f0104f60 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104f49:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104f4c:	83 e8 01             	sub    $0x1,%eax
f0104f4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104f52:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104f55:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0104f57:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104f5e:	eb 15                	jmp    f0104f75 <stab_binsearch+0xb0>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104f60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f63:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0104f66:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0104f68:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104f6c:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0104f6e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104f75:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104f78:	0f 8e 6f ff ff ff    	jle    f0104eed <stab_binsearch+0x28>
		}
	}

	if (!any_matches)
f0104f7e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104f82:	75 0f                	jne    f0104f93 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104f84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104f87:	8b 00                	mov    (%eax),%eax
f0104f89:	83 e8 01             	sub    $0x1,%eax
f0104f8c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104f8f:	89 07                	mov    %eax,(%edi)
f0104f91:	eb 2c                	jmp    f0104fbf <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104f93:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104f96:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104f98:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f9b:	8b 0f                	mov    (%edi),%ecx
f0104f9d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104fa0:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104fa3:	8d 14 97             	lea    (%edi,%edx,4),%edx
		for (l = *region_right;
f0104fa6:	eb 03                	jmp    f0104fab <stab_binsearch+0xe6>
		     l--)
f0104fa8:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104fab:	39 c8                	cmp    %ecx,%eax
f0104fad:	7e 0b                	jle    f0104fba <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104faf:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104fb3:	83 ea 0c             	sub    $0xc,%edx
f0104fb6:	39 f3                	cmp    %esi,%ebx
f0104fb8:	75 ee                	jne    f0104fa8 <stab_binsearch+0xe3>
			/* do nothing */;
		*region_left = l;
f0104fba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104fbd:	89 07                	mov    %eax,(%edi)
	}
}
f0104fbf:	83 c4 14             	add    $0x14,%esp
f0104fc2:	5b                   	pop    %ebx
f0104fc3:	5e                   	pop    %esi
f0104fc4:	5f                   	pop    %edi
f0104fc5:	5d                   	pop    %ebp
f0104fc6:	c3                   	ret    

f0104fc7 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104fc7:	55                   	push   %ebp
f0104fc8:	89 e5                	mov    %esp,%ebp
f0104fca:	57                   	push   %edi
f0104fcb:	56                   	push   %esi
f0104fcc:	53                   	push   %ebx
f0104fcd:	83 ec 4c             	sub    $0x4c,%esp
f0104fd0:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104fd3:	8b 7d 0c             	mov    0xc(%ebp),%edi
	int lfile, rfile, lfun, rfun, lline, rline;
	int mem_check_flag = 0;
	int stabSize = sizeof(struct UserStabData); // Couple of variables to help us with our user_mem_check calls later

	// Initialize *info
	info->eip_file = "<unknown>";
f0104fd6:	c7 07 a8 7f 10 f0    	movl   $0xf0107fa8,(%edi)
	info->eip_line = 0;
f0104fdc:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0104fe3:	c7 47 08 a8 7f 10 f0 	movl   $0xf0107fa8,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104fea:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0104ff1:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0104ff4:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104ffb:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0105001:	0f 87 cf 00 00 00    	ja     f01050d6 <debuginfo_eip+0x10f>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		mem_check_flag = user_mem_check(curenv, (void *) usd, stabSize, PTE_U);
f0105007:	e8 4d 11 00 00       	call   f0106159 <cpunum>
f010500c:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0105013:	00 
f0105014:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f010501b:	00 
f010501c:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0105023:	00 
f0105024:	6b c0 74             	imul   $0x74,%eax,%eax
f0105027:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010502d:	89 04 24             	mov    %eax,(%esp)
f0105030:	e8 2e e5 ff ff       	call   f0103563 <user_mem_check>
		if (mem_check_flag != 0){
f0105035:	85 c0                	test   %eax,%eax
f0105037:	0f 85 5f 02 00 00    	jne    f010529c <debuginfo_eip+0x2d5>
			return -1;
		}
		stabs = usd->stabs;
f010503d:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0105042:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0105048:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010504e:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0105051:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0105057:	89 55 bc             	mov    %edx,-0x44(%ebp)
		
		int stab_length = (uintptr_t) stab_end - (uintptr_t) stabs;
f010505a:	89 f2                	mov    %esi,%edx
f010505c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010505f:	29 c2                	sub    %eax,%edx
f0105061:	89 55 b8             	mov    %edx,-0x48(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		mem_check_flag = user_mem_check(curenv, (void *) stabs, stab_length, PTE_U);
f0105064:	e8 f0 10 00 00       	call   f0106159 <cpunum>
f0105069:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0105070:	00 
f0105071:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0105074:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105078:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010507b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010507f:	6b c0 74             	imul   $0x74,%eax,%eax
f0105082:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0105088:	89 04 24             	mov    %eax,(%esp)
f010508b:	e8 d3 e4 ff ff       	call   f0103563 <user_mem_check>
		if (mem_check_flag != 0){
f0105090:	85 c0                	test   %eax,%eax
f0105092:	0f 85 0b 02 00 00    	jne    f01052a3 <debuginfo_eip+0x2dc>
			return -1;
		}

		int string_table_length = (uintptr_t) stabstr_end - (uintptr_t) stabstr;
f0105098:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010509b:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010509e:	89 55 b8             	mov    %edx,-0x48(%ebp)
		mem_check_flag = user_mem_check(curenv, (void *) stabstr, string_table_length, PTE_U);
f01050a1:	e8 b3 10 00 00       	call   f0106159 <cpunum>
f01050a6:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f01050ad:	00 
f01050ae:	8b 55 b8             	mov    -0x48(%ebp),%edx
f01050b1:	89 54 24 08          	mov    %edx,0x8(%esp)
f01050b5:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f01050b8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01050bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01050bf:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01050c5:	89 04 24             	mov    %eax,(%esp)
f01050c8:	e8 96 e4 ff ff       	call   f0103563 <user_mem_check>
		if (mem_check_flag != 0){
f01050cd:	85 c0                	test   %eax,%eax
f01050cf:	74 1f                	je     f01050f0 <debuginfo_eip+0x129>
f01050d1:	e9 d4 01 00 00       	jmp    f01052aa <debuginfo_eip+0x2e3>
		stabstr_end = __STABSTR_END__;
f01050d6:	c7 45 bc 3a 5f 11 f0 	movl   $0xf0115f3a,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f01050dd:	c7 45 c0 f1 27 11 f0 	movl   $0xf01127f1,-0x40(%ebp)
		stab_end = __STAB_END__;
f01050e4:	be f0 27 11 f0       	mov    $0xf01127f0,%esi
		stabs = __STAB_BEGIN__;
f01050e9:	c7 45 c4 94 84 10 f0 	movl   $0xf0108494,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01050f0:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01050f3:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f01050f6:	0f 83 b5 01 00 00    	jae    f01052b1 <debuginfo_eip+0x2ea>
f01050fc:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0105100:	0f 85 b2 01 00 00    	jne    f01052b8 <debuginfo_eip+0x2f1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0105106:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010510d:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0105110:	c1 fe 02             	sar    $0x2,%esi
f0105113:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0105119:	83 e8 01             	sub    $0x1,%eax
f010511c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010511f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105123:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010512a:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010512d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105130:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0105133:	89 f0                	mov    %esi,%eax
f0105135:	e8 8b fd ff ff       	call   f0104ec5 <stab_binsearch>
	if (lfile == 0)
f010513a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010513d:	85 c0                	test   %eax,%eax
f010513f:	0f 84 7a 01 00 00    	je     f01052bf <debuginfo_eip+0x2f8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0105145:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0105148:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010514b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010514e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105152:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0105159:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010515c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010515f:	89 f0                	mov    %esi,%eax
f0105161:	e8 5f fd ff ff       	call   f0104ec5 <stab_binsearch>

	if (lfun <= rfun) {
f0105166:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105169:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010516c:	39 f0                	cmp    %esi,%eax
f010516e:	7f 32                	jg     f01051a2 <debuginfo_eip+0x1db>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0105170:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105173:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0105176:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0105179:	8b 0a                	mov    (%edx),%ecx
f010517b:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f010517e:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0105181:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f0105184:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f0105187:	73 09                	jae    f0105192 <debuginfo_eip+0x1cb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0105189:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f010518c:	03 4d c0             	add    -0x40(%ebp),%ecx
f010518f:	89 4f 08             	mov    %ecx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0105192:	8b 52 08             	mov    0x8(%edx),%edx
f0105195:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0105198:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f010519a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010519d:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01051a0:	eb 0f                	jmp    f01051b1 <debuginfo_eip+0x1ea>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01051a2:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f01051a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051a8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01051ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01051ae:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01051b1:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01051b8:	00 
f01051b9:	8b 47 08             	mov    0x8(%edi),%eax
f01051bc:	89 04 24             	mov    %eax,(%esp)
f01051bf:	e8 27 09 00 00       	call   f0105aeb <strfind>
f01051c4:	2b 47 08             	sub    0x8(%edi),%eax
f01051c7:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
  stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01051ca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01051ce:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01051d5:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01051d8:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01051db:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01051de:	89 f0                	mov    %esi,%eax
f01051e0:	e8 e0 fc ff ff       	call   f0104ec5 <stab_binsearch>
  if (lline == rline) {
f01051e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01051e8:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01051eb:	0f 85 d5 00 00 00    	jne    f01052c6 <debuginfo_eip+0x2ff>
    info->eip_line = stabs[lline].n_desc;
f01051f1:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01051f4:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f01051f9:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01051fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051ff:	89 c3                	mov    %eax,%ebx
f0105201:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105204:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105207:	8d 14 96             	lea    (%esi,%edx,4),%edx
f010520a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010520d:	89 df                	mov    %ebx,%edi
f010520f:	eb 06                	jmp    f0105217 <debuginfo_eip+0x250>
f0105211:	83 e8 01             	sub    $0x1,%eax
f0105214:	83 ea 0c             	sub    $0xc,%edx
f0105217:	89 c6                	mov    %eax,%esi
f0105219:	39 c7                	cmp    %eax,%edi
f010521b:	7f 3c                	jg     f0105259 <debuginfo_eip+0x292>
	       && stabs[lline].n_type != N_SOL
f010521d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0105221:	80 f9 84             	cmp    $0x84,%cl
f0105224:	75 08                	jne    f010522e <debuginfo_eip+0x267>
f0105226:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105229:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010522c:	eb 11                	jmp    f010523f <debuginfo_eip+0x278>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010522e:	80 f9 64             	cmp    $0x64,%cl
f0105231:	75 de                	jne    f0105211 <debuginfo_eip+0x24a>
f0105233:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0105237:	74 d8                	je     f0105211 <debuginfo_eip+0x24a>
f0105239:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010523c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010523f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0105242:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0105245:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0105248:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010524b:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010524e:	39 d0                	cmp    %edx,%eax
f0105250:	73 0a                	jae    f010525c <debuginfo_eip+0x295>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0105252:	03 45 c0             	add    -0x40(%ebp),%eax
f0105255:	89 07                	mov    %eax,(%edi)
f0105257:	eb 03                	jmp    f010525c <debuginfo_eip+0x295>
f0105259:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010525c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010525f:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105262:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0105267:	39 da                	cmp    %ebx,%edx
f0105269:	7d 67                	jge    f01052d2 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
f010526b:	83 c2 01             	add    $0x1,%edx
f010526e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0105271:	89 d0                	mov    %edx,%eax
f0105273:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105276:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0105279:	8d 14 96             	lea    (%esi,%edx,4),%edx
f010527c:	eb 04                	jmp    f0105282 <debuginfo_eip+0x2bb>
			info->eip_fn_narg++;
f010527e:	83 47 14 01          	addl   $0x1,0x14(%edi)
		for (lline = lfun + 1;
f0105282:	39 c3                	cmp    %eax,%ebx
f0105284:	7e 47                	jle    f01052cd <debuginfo_eip+0x306>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105286:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010528a:	83 c0 01             	add    $0x1,%eax
f010528d:	83 c2 0c             	add    $0xc,%edx
f0105290:	80 f9 a0             	cmp    $0xa0,%cl
f0105293:	74 e9                	je     f010527e <debuginfo_eip+0x2b7>
	return 0;
f0105295:	b8 00 00 00 00       	mov    $0x0,%eax
f010529a:	eb 36                	jmp    f01052d2 <debuginfo_eip+0x30b>
			return -1;
f010529c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01052a1:	eb 2f                	jmp    f01052d2 <debuginfo_eip+0x30b>
			return -1;
f01052a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01052a8:	eb 28                	jmp    f01052d2 <debuginfo_eip+0x30b>
			return -1;
f01052aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01052af:	eb 21                	jmp    f01052d2 <debuginfo_eip+0x30b>
		return -1;
f01052b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01052b6:	eb 1a                	jmp    f01052d2 <debuginfo_eip+0x30b>
f01052b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01052bd:	eb 13                	jmp    f01052d2 <debuginfo_eip+0x30b>
		return -1;
f01052bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01052c4:	eb 0c                	jmp    f01052d2 <debuginfo_eip+0x30b>
    return -1;
f01052c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01052cb:	eb 05                	jmp    f01052d2 <debuginfo_eip+0x30b>
	return 0;
f01052cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01052d2:	83 c4 4c             	add    $0x4c,%esp
f01052d5:	5b                   	pop    %ebx
f01052d6:	5e                   	pop    %esi
f01052d7:	5f                   	pop    %edi
f01052d8:	5d                   	pop    %ebp
f01052d9:	c3                   	ret    
f01052da:	66 90                	xchg   %ax,%ax
f01052dc:	66 90                	xchg   %ax,%ax
f01052de:	66 90                	xchg   %ax,%ax

f01052e0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01052e0:	55                   	push   %ebp
f01052e1:	89 e5                	mov    %esp,%ebp
f01052e3:	57                   	push   %edi
f01052e4:	56                   	push   %esi
f01052e5:	53                   	push   %ebx
f01052e6:	83 ec 3c             	sub    $0x3c,%esp
f01052e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01052ec:	89 d7                	mov    %edx,%edi
f01052ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01052f1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01052f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01052f7:	89 c3                	mov    %eax,%ebx
f01052f9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01052fc:	8b 45 10             	mov    0x10(%ebp),%eax
f01052ff:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105302:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105307:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010530a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010530d:	39 d9                	cmp    %ebx,%ecx
f010530f:	72 05                	jb     f0105316 <printnum+0x36>
f0105311:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0105314:	77 69                	ja     f010537f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105316:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105319:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010531d:	83 ee 01             	sub    $0x1,%esi
f0105320:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105324:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105328:	8b 44 24 08          	mov    0x8(%esp),%eax
f010532c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105330:	89 c3                	mov    %eax,%ebx
f0105332:	89 d6                	mov    %edx,%esi
f0105334:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105337:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010533a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010533e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105342:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105345:	89 04 24             	mov    %eax,(%esp)
f0105348:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010534b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010534f:	e8 4c 12 00 00       	call   f01065a0 <__udivdi3>
f0105354:	89 d9                	mov    %ebx,%ecx
f0105356:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010535a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010535e:	89 04 24             	mov    %eax,(%esp)
f0105361:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105365:	89 fa                	mov    %edi,%edx
f0105367:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010536a:	e8 71 ff ff ff       	call   f01052e0 <printnum>
f010536f:	eb 1b                	jmp    f010538c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105371:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105375:	8b 45 18             	mov    0x18(%ebp),%eax
f0105378:	89 04 24             	mov    %eax,(%esp)
f010537b:	ff d3                	call   *%ebx
f010537d:	eb 03                	jmp    f0105382 <printnum+0xa2>
f010537f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while (--width > 0)
f0105382:	83 ee 01             	sub    $0x1,%esi
f0105385:	85 f6                	test   %esi,%esi
f0105387:	7f e8                	jg     f0105371 <printnum+0x91>
f0105389:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010538c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105390:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105394:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105397:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010539a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010539e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01053a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01053a5:	89 04 24             	mov    %eax,(%esp)
f01053a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01053ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053af:	e8 1c 13 00 00       	call   f01066d0 <__umoddi3>
f01053b4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01053b8:	0f be 80 b2 7f 10 f0 	movsbl -0xfef804e(%eax),%eax
f01053bf:	89 04 24             	mov    %eax,(%esp)
f01053c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01053c5:	ff d0                	call   *%eax
}
f01053c7:	83 c4 3c             	add    $0x3c,%esp
f01053ca:	5b                   	pop    %ebx
f01053cb:	5e                   	pop    %esi
f01053cc:	5f                   	pop    %edi
f01053cd:	5d                   	pop    %ebp
f01053ce:	c3                   	ret    

f01053cf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01053cf:	55                   	push   %ebp
f01053d0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01053d2:	83 fa 01             	cmp    $0x1,%edx
f01053d5:	7e 0e                	jle    f01053e5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01053d7:	8b 10                	mov    (%eax),%edx
f01053d9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01053dc:	89 08                	mov    %ecx,(%eax)
f01053de:	8b 02                	mov    (%edx),%eax
f01053e0:	8b 52 04             	mov    0x4(%edx),%edx
f01053e3:	eb 22                	jmp    f0105407 <getuint+0x38>
	else if (lflag)
f01053e5:	85 d2                	test   %edx,%edx
f01053e7:	74 10                	je     f01053f9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01053e9:	8b 10                	mov    (%eax),%edx
f01053eb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01053ee:	89 08                	mov    %ecx,(%eax)
f01053f0:	8b 02                	mov    (%edx),%eax
f01053f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01053f7:	eb 0e                	jmp    f0105407 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01053f9:	8b 10                	mov    (%eax),%edx
f01053fb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01053fe:	89 08                	mov    %ecx,(%eax)
f0105400:	8b 02                	mov    (%edx),%eax
f0105402:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105407:	5d                   	pop    %ebp
f0105408:	c3                   	ret    

f0105409 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105409:	55                   	push   %ebp
f010540a:	89 e5                	mov    %esp,%ebp
f010540c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010540f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105413:	8b 10                	mov    (%eax),%edx
f0105415:	3b 50 04             	cmp    0x4(%eax),%edx
f0105418:	73 0a                	jae    f0105424 <sprintputch+0x1b>
		*b->buf++ = ch;
f010541a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010541d:	89 08                	mov    %ecx,(%eax)
f010541f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105422:	88 02                	mov    %al,(%edx)
}
f0105424:	5d                   	pop    %ebp
f0105425:	c3                   	ret    

f0105426 <printfmt>:
{
f0105426:	55                   	push   %ebp
f0105427:	89 e5                	mov    %esp,%ebp
f0105429:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f010542c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010542f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105433:	8b 45 10             	mov    0x10(%ebp),%eax
f0105436:	89 44 24 08          	mov    %eax,0x8(%esp)
f010543a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010543d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105441:	8b 45 08             	mov    0x8(%ebp),%eax
f0105444:	89 04 24             	mov    %eax,(%esp)
f0105447:	e8 02 00 00 00       	call   f010544e <vprintfmt>
}
f010544c:	c9                   	leave  
f010544d:	c3                   	ret    

f010544e <vprintfmt>:
{
f010544e:	55                   	push   %ebp
f010544f:	89 e5                	mov    %esp,%ebp
f0105451:	57                   	push   %edi
f0105452:	56                   	push   %esi
f0105453:	53                   	push   %ebx
f0105454:	83 ec 3c             	sub    $0x3c,%esp
f0105457:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010545a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010545d:	eb 14                	jmp    f0105473 <vprintfmt+0x25>
			if (ch == '\0')
f010545f:	85 c0                	test   %eax,%eax
f0105461:	0f 84 b3 03 00 00    	je     f010581a <vprintfmt+0x3cc>
			putch(ch, putdat);
f0105467:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010546b:	89 04 24             	mov    %eax,(%esp)
f010546e:	ff 55 08             	call   *0x8(%ebp)
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105471:	89 f3                	mov    %esi,%ebx
f0105473:	8d 73 01             	lea    0x1(%ebx),%esi
f0105476:	0f b6 03             	movzbl (%ebx),%eax
f0105479:	83 f8 25             	cmp    $0x25,%eax
f010547c:	75 e1                	jne    f010545f <vprintfmt+0x11>
f010547e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0105482:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0105489:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105490:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105497:	ba 00 00 00 00       	mov    $0x0,%edx
f010549c:	eb 1d                	jmp    f01054bb <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f010549e:	89 de                	mov    %ebx,%esi
			padc = '-';
f01054a0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01054a4:	eb 15                	jmp    f01054bb <vprintfmt+0x6d>
		switch (ch = *(unsigned char *) fmt++) {
f01054a6:	89 de                	mov    %ebx,%esi
			padc = '0';
f01054a8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01054ac:	eb 0d                	jmp    f01054bb <vprintfmt+0x6d>
				width = precision, precision = -1;
f01054ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01054b1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01054b4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01054bb:	8d 5e 01             	lea    0x1(%esi),%ebx
f01054be:	0f b6 0e             	movzbl (%esi),%ecx
f01054c1:	0f b6 c1             	movzbl %cl,%eax
f01054c4:	83 e9 23             	sub    $0x23,%ecx
f01054c7:	80 f9 55             	cmp    $0x55,%cl
f01054ca:	0f 87 2a 03 00 00    	ja     f01057fa <vprintfmt+0x3ac>
f01054d0:	0f b6 c9             	movzbl %cl,%ecx
f01054d3:	ff 24 8d 80 80 10 f0 	jmp    *-0xfef7f80(,%ecx,4)
f01054da:	89 de                	mov    %ebx,%esi
f01054dc:	b9 00 00 00 00       	mov    $0x0,%ecx
				precision = precision * 10 + ch - '0';
f01054e1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01054e4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01054e8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01054eb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01054ee:	83 fb 09             	cmp    $0x9,%ebx
f01054f1:	77 36                	ja     f0105529 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f01054f3:	83 c6 01             	add    $0x1,%esi
			}
f01054f6:	eb e9                	jmp    f01054e1 <vprintfmt+0x93>
			precision = va_arg(ap, int);
f01054f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01054fb:	8d 48 04             	lea    0x4(%eax),%ecx
f01054fe:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105501:	8b 00                	mov    (%eax),%eax
f0105503:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0105506:	89 de                	mov    %ebx,%esi
			goto process_precision;
f0105508:	eb 22                	jmp    f010552c <vprintfmt+0xde>
f010550a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010550d:	85 c9                	test   %ecx,%ecx
f010550f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105514:	0f 49 c1             	cmovns %ecx,%eax
f0105517:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010551a:	89 de                	mov    %ebx,%esi
f010551c:	eb 9d                	jmp    f01054bb <vprintfmt+0x6d>
f010551e:	89 de                	mov    %ebx,%esi
			altflag = 1;
f0105520:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0105527:	eb 92                	jmp    f01054bb <vprintfmt+0x6d>
f0105529:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
			if (width < 0)
f010552c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105530:	79 89                	jns    f01054bb <vprintfmt+0x6d>
f0105532:	e9 77 ff ff ff       	jmp    f01054ae <vprintfmt+0x60>
			lflag++;
f0105537:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f010553a:	89 de                	mov    %ebx,%esi
			goto reswitch;
f010553c:	e9 7a ff ff ff       	jmp    f01054bb <vprintfmt+0x6d>
			putch(va_arg(ap, int), putdat);
f0105541:	8b 45 14             	mov    0x14(%ebp),%eax
f0105544:	8d 50 04             	lea    0x4(%eax),%edx
f0105547:	89 55 14             	mov    %edx,0x14(%ebp)
f010554a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010554e:	8b 00                	mov    (%eax),%eax
f0105550:	89 04 24             	mov    %eax,(%esp)
f0105553:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105556:	e9 18 ff ff ff       	jmp    f0105473 <vprintfmt+0x25>
			err = va_arg(ap, int);
f010555b:	8b 45 14             	mov    0x14(%ebp),%eax
f010555e:	8d 50 04             	lea    0x4(%eax),%edx
f0105561:	89 55 14             	mov    %edx,0x14(%ebp)
f0105564:	8b 00                	mov    (%eax),%eax
f0105566:	99                   	cltd   
f0105567:	31 d0                	xor    %edx,%eax
f0105569:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010556b:	83 f8 08             	cmp    $0x8,%eax
f010556e:	7f 0b                	jg     f010557b <vprintfmt+0x12d>
f0105570:	8b 14 85 e0 81 10 f0 	mov    -0xfef7e20(,%eax,4),%edx
f0105577:	85 d2                	test   %edx,%edx
f0105579:	75 20                	jne    f010559b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010557b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010557f:	c7 44 24 08 ca 7f 10 	movl   $0xf0107fca,0x8(%esp)
f0105586:	f0 
f0105587:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010558b:	8b 45 08             	mov    0x8(%ebp),%eax
f010558e:	89 04 24             	mov    %eax,(%esp)
f0105591:	e8 90 fe ff ff       	call   f0105426 <printfmt>
f0105596:	e9 d8 fe ff ff       	jmp    f0105473 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f010559b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010559f:	c7 44 24 08 e1 77 10 	movl   $0xf01077e1,0x8(%esp)
f01055a6:	f0 
f01055a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01055ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01055ae:	89 04 24             	mov    %eax,(%esp)
f01055b1:	e8 70 fe ff ff       	call   f0105426 <printfmt>
f01055b6:	e9 b8 fe ff ff       	jmp    f0105473 <vprintfmt+0x25>
		switch (ch = *(unsigned char *) fmt++) {
f01055bb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01055be:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01055c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f01055c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01055c7:	8d 50 04             	lea    0x4(%eax),%edx
f01055ca:	89 55 14             	mov    %edx,0x14(%ebp)
f01055cd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01055cf:	85 f6                	test   %esi,%esi
f01055d1:	b8 c3 7f 10 f0       	mov    $0xf0107fc3,%eax
f01055d6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01055d9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01055dd:	0f 84 97 00 00 00    	je     f010567a <vprintfmt+0x22c>
f01055e3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01055e7:	0f 8e 9b 00 00 00    	jle    f0105688 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01055ed:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01055f1:	89 34 24             	mov    %esi,(%esp)
f01055f4:	e8 9f 03 00 00       	call   f0105998 <strnlen>
f01055f9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01055fc:	29 c2                	sub    %eax,%edx
f01055fe:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105601:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105605:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105608:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010560b:	8b 75 08             	mov    0x8(%ebp),%esi
f010560e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105611:	89 d3                	mov    %edx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f0105613:	eb 0f                	jmp    f0105624 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105615:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105619:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010561c:	89 04 24             	mov    %eax,(%esp)
f010561f:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0105621:	83 eb 01             	sub    $0x1,%ebx
f0105624:	85 db                	test   %ebx,%ebx
f0105626:	7f ed                	jg     f0105615 <vprintfmt+0x1c7>
f0105628:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010562b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010562e:	85 d2                	test   %edx,%edx
f0105630:	b8 00 00 00 00       	mov    $0x0,%eax
f0105635:	0f 49 c2             	cmovns %edx,%eax
f0105638:	29 c2                	sub    %eax,%edx
f010563a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010563d:	89 d7                	mov    %edx,%edi
f010563f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105642:	eb 50                	jmp    f0105694 <vprintfmt+0x246>
				if (altflag && (ch < ' ' || ch > '~'))
f0105644:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105648:	74 1e                	je     f0105668 <vprintfmt+0x21a>
f010564a:	0f be d2             	movsbl %dl,%edx
f010564d:	83 ea 20             	sub    $0x20,%edx
f0105650:	83 fa 5e             	cmp    $0x5e,%edx
f0105653:	76 13                	jbe    f0105668 <vprintfmt+0x21a>
					putch('?', putdat);
f0105655:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105658:	89 44 24 04          	mov    %eax,0x4(%esp)
f010565c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0105663:	ff 55 08             	call   *0x8(%ebp)
f0105666:	eb 0d                	jmp    f0105675 <vprintfmt+0x227>
					putch(ch, putdat);
f0105668:	8b 55 0c             	mov    0xc(%ebp),%edx
f010566b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010566f:	89 04 24             	mov    %eax,(%esp)
f0105672:	ff 55 08             	call   *0x8(%ebp)
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105675:	83 ef 01             	sub    $0x1,%edi
f0105678:	eb 1a                	jmp    f0105694 <vprintfmt+0x246>
f010567a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010567d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105680:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105683:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105686:	eb 0c                	jmp    f0105694 <vprintfmt+0x246>
f0105688:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010568b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010568e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105691:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105694:	83 c6 01             	add    $0x1,%esi
f0105697:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010569b:	0f be c2             	movsbl %dl,%eax
f010569e:	85 c0                	test   %eax,%eax
f01056a0:	74 27                	je     f01056c9 <vprintfmt+0x27b>
f01056a2:	85 db                	test   %ebx,%ebx
f01056a4:	78 9e                	js     f0105644 <vprintfmt+0x1f6>
f01056a6:	83 eb 01             	sub    $0x1,%ebx
f01056a9:	79 99                	jns    f0105644 <vprintfmt+0x1f6>
f01056ab:	89 f8                	mov    %edi,%eax
f01056ad:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01056b0:	8b 75 08             	mov    0x8(%ebp),%esi
f01056b3:	89 c3                	mov    %eax,%ebx
f01056b5:	eb 1a                	jmp    f01056d1 <vprintfmt+0x283>
				putch(' ', putdat);
f01056b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01056bb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01056c2:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01056c4:	83 eb 01             	sub    $0x1,%ebx
f01056c7:	eb 08                	jmp    f01056d1 <vprintfmt+0x283>
f01056c9:	89 fb                	mov    %edi,%ebx
f01056cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01056ce:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01056d1:	85 db                	test   %ebx,%ebx
f01056d3:	7f e2                	jg     f01056b7 <vprintfmt+0x269>
f01056d5:	89 75 08             	mov    %esi,0x8(%ebp)
f01056d8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01056db:	e9 93 fd ff ff       	jmp    f0105473 <vprintfmt+0x25>
	if (lflag >= 2)
f01056e0:	83 fa 01             	cmp    $0x1,%edx
f01056e3:	7e 16                	jle    f01056fb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01056e5:	8b 45 14             	mov    0x14(%ebp),%eax
f01056e8:	8d 50 08             	lea    0x8(%eax),%edx
f01056eb:	89 55 14             	mov    %edx,0x14(%ebp)
f01056ee:	8b 50 04             	mov    0x4(%eax),%edx
f01056f1:	8b 00                	mov    (%eax),%eax
f01056f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01056f6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01056f9:	eb 32                	jmp    f010572d <vprintfmt+0x2df>
	else if (lflag)
f01056fb:	85 d2                	test   %edx,%edx
f01056fd:	74 18                	je     f0105717 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01056ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0105702:	8d 50 04             	lea    0x4(%eax),%edx
f0105705:	89 55 14             	mov    %edx,0x14(%ebp)
f0105708:	8b 30                	mov    (%eax),%esi
f010570a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010570d:	89 f0                	mov    %esi,%eax
f010570f:	c1 f8 1f             	sar    $0x1f,%eax
f0105712:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105715:	eb 16                	jmp    f010572d <vprintfmt+0x2df>
		return va_arg(*ap, int);
f0105717:	8b 45 14             	mov    0x14(%ebp),%eax
f010571a:	8d 50 04             	lea    0x4(%eax),%edx
f010571d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105720:	8b 30                	mov    (%eax),%esi
f0105722:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105725:	89 f0                	mov    %esi,%eax
f0105727:	c1 f8 1f             	sar    $0x1f,%eax
f010572a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			num = getint(&ap, lflag);
f010572d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105730:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			base = 10;
f0105733:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0105738:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010573c:	0f 89 80 00 00 00    	jns    f01057c2 <vprintfmt+0x374>
				putch('-', putdat);
f0105742:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105746:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010574d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0105750:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105753:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105756:	f7 d8                	neg    %eax
f0105758:	83 d2 00             	adc    $0x0,%edx
f010575b:	f7 da                	neg    %edx
			base = 10;
f010575d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105762:	eb 5e                	jmp    f01057c2 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f0105764:	8d 45 14             	lea    0x14(%ebp),%eax
f0105767:	e8 63 fc ff ff       	call   f01053cf <getuint>
			base = 10;
f010576c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105771:	eb 4f                	jmp    f01057c2 <vprintfmt+0x374>
      num = getuint(&ap, lflag);
f0105773:	8d 45 14             	lea    0x14(%ebp),%eax
f0105776:	e8 54 fc ff ff       	call   f01053cf <getuint>
      base = 8;
f010577b:	b9 08 00 00 00       	mov    $0x8,%ecx
      goto number;
f0105780:	eb 40                	jmp    f01057c2 <vprintfmt+0x374>
			putch('0', putdat);
f0105782:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105786:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010578d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105790:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105794:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010579b:	ff 55 08             	call   *0x8(%ebp)
				(uintptr_t) va_arg(ap, void *);
f010579e:	8b 45 14             	mov    0x14(%ebp),%eax
f01057a1:	8d 50 04             	lea    0x4(%eax),%edx
f01057a4:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01057a7:	8b 00                	mov    (%eax),%eax
f01057a9:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01057ae:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01057b3:	eb 0d                	jmp    f01057c2 <vprintfmt+0x374>
			num = getuint(&ap, lflag);
f01057b5:	8d 45 14             	lea    0x14(%ebp),%eax
f01057b8:	e8 12 fc ff ff       	call   f01053cf <getuint>
			base = 16;
f01057bd:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f01057c2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01057c6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01057ca:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01057cd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01057d1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01057d5:	89 04 24             	mov    %eax,(%esp)
f01057d8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01057dc:	89 fa                	mov    %edi,%edx
f01057de:	8b 45 08             	mov    0x8(%ebp),%eax
f01057e1:	e8 fa fa ff ff       	call   f01052e0 <printnum>
			break;
f01057e6:	e9 88 fc ff ff       	jmp    f0105473 <vprintfmt+0x25>
			putch(ch, putdat);
f01057eb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01057ef:	89 04 24             	mov    %eax,(%esp)
f01057f2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01057f5:	e9 79 fc ff ff       	jmp    f0105473 <vprintfmt+0x25>
			putch('%', putdat);
f01057fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01057fe:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105805:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105808:	89 f3                	mov    %esi,%ebx
f010580a:	eb 03                	jmp    f010580f <vprintfmt+0x3c1>
f010580c:	83 eb 01             	sub    $0x1,%ebx
f010580f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105813:	75 f7                	jne    f010580c <vprintfmt+0x3be>
f0105815:	e9 59 fc ff ff       	jmp    f0105473 <vprintfmt+0x25>
}
f010581a:	83 c4 3c             	add    $0x3c,%esp
f010581d:	5b                   	pop    %ebx
f010581e:	5e                   	pop    %esi
f010581f:	5f                   	pop    %edi
f0105820:	5d                   	pop    %ebp
f0105821:	c3                   	ret    

f0105822 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105822:	55                   	push   %ebp
f0105823:	89 e5                	mov    %esp,%ebp
f0105825:	83 ec 28             	sub    $0x28,%esp
f0105828:	8b 45 08             	mov    0x8(%ebp),%eax
f010582b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010582e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105831:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105835:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105838:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010583f:	85 c0                	test   %eax,%eax
f0105841:	74 30                	je     f0105873 <vsnprintf+0x51>
f0105843:	85 d2                	test   %edx,%edx
f0105845:	7e 2c                	jle    f0105873 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105847:	8b 45 14             	mov    0x14(%ebp),%eax
f010584a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010584e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105851:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105855:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105858:	89 44 24 04          	mov    %eax,0x4(%esp)
f010585c:	c7 04 24 09 54 10 f0 	movl   $0xf0105409,(%esp)
f0105863:	e8 e6 fb ff ff       	call   f010544e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105868:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010586b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010586e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105871:	eb 05                	jmp    f0105878 <vsnprintf+0x56>
		return -E_INVAL;
f0105873:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f0105878:	c9                   	leave  
f0105879:	c3                   	ret    

f010587a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010587a:	55                   	push   %ebp
f010587b:	89 e5                	mov    %esp,%ebp
f010587d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105880:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105883:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105887:	8b 45 10             	mov    0x10(%ebp),%eax
f010588a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010588e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105891:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105895:	8b 45 08             	mov    0x8(%ebp),%eax
f0105898:	89 04 24             	mov    %eax,(%esp)
f010589b:	e8 82 ff ff ff       	call   f0105822 <vsnprintf>
	va_end(ap);

	return rc;
}
f01058a0:	c9                   	leave  
f01058a1:	c3                   	ret    
f01058a2:	66 90                	xchg   %ax,%ax
f01058a4:	66 90                	xchg   %ax,%ax
f01058a6:	66 90                	xchg   %ax,%ax
f01058a8:	66 90                	xchg   %ax,%ax
f01058aa:	66 90                	xchg   %ax,%ax
f01058ac:	66 90                	xchg   %ax,%ax
f01058ae:	66 90                	xchg   %ax,%ax

f01058b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01058b0:	55                   	push   %ebp
f01058b1:	89 e5                	mov    %esp,%ebp
f01058b3:	57                   	push   %edi
f01058b4:	56                   	push   %esi
f01058b5:	53                   	push   %ebx
f01058b6:	83 ec 1c             	sub    $0x1c,%esp
f01058b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01058bc:	85 c0                	test   %eax,%eax
f01058be:	74 10                	je     f01058d0 <readline+0x20>
		cprintf("%s", prompt);
f01058c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01058c4:	c7 04 24 e1 77 10 f0 	movl   $0xf01077e1,(%esp)
f01058cb:	e8 2b e7 ff ff       	call   f0103ffb <cprintf>

	i = 0;
	echoing = iscons(0);
f01058d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01058d7:	e8 bf ae ff ff       	call   f010079b <iscons>
f01058dc:	89 c7                	mov    %eax,%edi
	i = 0;
f01058de:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01058e3:	e8 a2 ae ff ff       	call   f010078a <getchar>
f01058e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01058ea:	85 c0                	test   %eax,%eax
f01058ec:	79 17                	jns    f0105905 <readline+0x55>
			cprintf("read error: %e\n", c);
f01058ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01058f2:	c7 04 24 04 82 10 f0 	movl   $0xf0108204,(%esp)
f01058f9:	e8 fd e6 ff ff       	call   f0103ffb <cprintf>
			return NULL;
f01058fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0105903:	eb 6d                	jmp    f0105972 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105905:	83 f8 7f             	cmp    $0x7f,%eax
f0105908:	74 05                	je     f010590f <readline+0x5f>
f010590a:	83 f8 08             	cmp    $0x8,%eax
f010590d:	75 19                	jne    f0105928 <readline+0x78>
f010590f:	85 f6                	test   %esi,%esi
f0105911:	7e 15                	jle    f0105928 <readline+0x78>
			if (echoing)
f0105913:	85 ff                	test   %edi,%edi
f0105915:	74 0c                	je     f0105923 <readline+0x73>
				cputchar('\b');
f0105917:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010591e:	e8 57 ae ff ff       	call   f010077a <cputchar>
			i--;
f0105923:	83 ee 01             	sub    $0x1,%esi
f0105926:	eb bb                	jmp    f01058e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105928:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010592e:	7f 1c                	jg     f010594c <readline+0x9c>
f0105930:	83 fb 1f             	cmp    $0x1f,%ebx
f0105933:	7e 17                	jle    f010594c <readline+0x9c>
			if (echoing)
f0105935:	85 ff                	test   %edi,%edi
f0105937:	74 08                	je     f0105941 <readline+0x91>
				cputchar(c);
f0105939:	89 1c 24             	mov    %ebx,(%esp)
f010593c:	e8 39 ae ff ff       	call   f010077a <cputchar>
			buf[i++] = c;
f0105941:	88 9e 80 ba 22 f0    	mov    %bl,-0xfdd4580(%esi)
f0105947:	8d 76 01             	lea    0x1(%esi),%esi
f010594a:	eb 97                	jmp    f01058e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010594c:	83 fb 0d             	cmp    $0xd,%ebx
f010594f:	74 05                	je     f0105956 <readline+0xa6>
f0105951:	83 fb 0a             	cmp    $0xa,%ebx
f0105954:	75 8d                	jne    f01058e3 <readline+0x33>
			if (echoing)
f0105956:	85 ff                	test   %edi,%edi
f0105958:	74 0c                	je     f0105966 <readline+0xb6>
				cputchar('\n');
f010595a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0105961:	e8 14 ae ff ff       	call   f010077a <cputchar>
			buf[i] = 0;
f0105966:	c6 86 80 ba 22 f0 00 	movb   $0x0,-0xfdd4580(%esi)
			return buf;
f010596d:	b8 80 ba 22 f0       	mov    $0xf022ba80,%eax
		}
	}
}
f0105972:	83 c4 1c             	add    $0x1c,%esp
f0105975:	5b                   	pop    %ebx
f0105976:	5e                   	pop    %esi
f0105977:	5f                   	pop    %edi
f0105978:	5d                   	pop    %ebp
f0105979:	c3                   	ret    
f010597a:	66 90                	xchg   %ax,%ax
f010597c:	66 90                	xchg   %ax,%ax
f010597e:	66 90                	xchg   %ax,%ax

f0105980 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105980:	55                   	push   %ebp
f0105981:	89 e5                	mov    %esp,%ebp
f0105983:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105986:	b8 00 00 00 00       	mov    $0x0,%eax
f010598b:	eb 03                	jmp    f0105990 <strlen+0x10>
		n++;
f010598d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0105990:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105994:	75 f7                	jne    f010598d <strlen+0xd>
	return n;
}
f0105996:	5d                   	pop    %ebp
f0105997:	c3                   	ret    

f0105998 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105998:	55                   	push   %ebp
f0105999:	89 e5                	mov    %esp,%ebp
f010599b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010599e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01059a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01059a6:	eb 03                	jmp    f01059ab <strnlen+0x13>
		n++;
f01059a8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01059ab:	39 d0                	cmp    %edx,%eax
f01059ad:	74 06                	je     f01059b5 <strnlen+0x1d>
f01059af:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01059b3:	75 f3                	jne    f01059a8 <strnlen+0x10>
	return n;
}
f01059b5:	5d                   	pop    %ebp
f01059b6:	c3                   	ret    

f01059b7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01059b7:	55                   	push   %ebp
f01059b8:	89 e5                	mov    %esp,%ebp
f01059ba:	53                   	push   %ebx
f01059bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01059be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01059c1:	89 c2                	mov    %eax,%edx
f01059c3:	83 c2 01             	add    $0x1,%edx
f01059c6:	83 c1 01             	add    $0x1,%ecx
f01059c9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01059cd:	88 5a ff             	mov    %bl,-0x1(%edx)
f01059d0:	84 db                	test   %bl,%bl
f01059d2:	75 ef                	jne    f01059c3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01059d4:	5b                   	pop    %ebx
f01059d5:	5d                   	pop    %ebp
f01059d6:	c3                   	ret    

f01059d7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01059d7:	55                   	push   %ebp
f01059d8:	89 e5                	mov    %esp,%ebp
f01059da:	53                   	push   %ebx
f01059db:	83 ec 08             	sub    $0x8,%esp
f01059de:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01059e1:	89 1c 24             	mov    %ebx,(%esp)
f01059e4:	e8 97 ff ff ff       	call   f0105980 <strlen>
	strcpy(dst + len, src);
f01059e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01059ec:	89 54 24 04          	mov    %edx,0x4(%esp)
f01059f0:	01 d8                	add    %ebx,%eax
f01059f2:	89 04 24             	mov    %eax,(%esp)
f01059f5:	e8 bd ff ff ff       	call   f01059b7 <strcpy>
	return dst;
}
f01059fa:	89 d8                	mov    %ebx,%eax
f01059fc:	83 c4 08             	add    $0x8,%esp
f01059ff:	5b                   	pop    %ebx
f0105a00:	5d                   	pop    %ebp
f0105a01:	c3                   	ret    

f0105a02 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105a02:	55                   	push   %ebp
f0105a03:	89 e5                	mov    %esp,%ebp
f0105a05:	56                   	push   %esi
f0105a06:	53                   	push   %ebx
f0105a07:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a0a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105a0d:	89 f3                	mov    %esi,%ebx
f0105a0f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105a12:	89 f2                	mov    %esi,%edx
f0105a14:	eb 0f                	jmp    f0105a25 <strncpy+0x23>
		*dst++ = *src;
f0105a16:	83 c2 01             	add    $0x1,%edx
f0105a19:	0f b6 01             	movzbl (%ecx),%eax
f0105a1c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105a1f:	80 39 01             	cmpb   $0x1,(%ecx)
f0105a22:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0105a25:	39 da                	cmp    %ebx,%edx
f0105a27:	75 ed                	jne    f0105a16 <strncpy+0x14>
	}
	return ret;
}
f0105a29:	89 f0                	mov    %esi,%eax
f0105a2b:	5b                   	pop    %ebx
f0105a2c:	5e                   	pop    %esi
f0105a2d:	5d                   	pop    %ebp
f0105a2e:	c3                   	ret    

f0105a2f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105a2f:	55                   	push   %ebp
f0105a30:	89 e5                	mov    %esp,%ebp
f0105a32:	56                   	push   %esi
f0105a33:	53                   	push   %ebx
f0105a34:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a37:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a3a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105a3d:	89 f0                	mov    %esi,%eax
f0105a3f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105a43:	85 c9                	test   %ecx,%ecx
f0105a45:	75 0b                	jne    f0105a52 <strlcpy+0x23>
f0105a47:	eb 1d                	jmp    f0105a66 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105a49:	83 c0 01             	add    $0x1,%eax
f0105a4c:	83 c2 01             	add    $0x1,%edx
f0105a4f:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0105a52:	39 d8                	cmp    %ebx,%eax
f0105a54:	74 0b                	je     f0105a61 <strlcpy+0x32>
f0105a56:	0f b6 0a             	movzbl (%edx),%ecx
f0105a59:	84 c9                	test   %cl,%cl
f0105a5b:	75 ec                	jne    f0105a49 <strlcpy+0x1a>
f0105a5d:	89 c2                	mov    %eax,%edx
f0105a5f:	eb 02                	jmp    f0105a63 <strlcpy+0x34>
f0105a61:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f0105a63:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0105a66:	29 f0                	sub    %esi,%eax
}
f0105a68:	5b                   	pop    %ebx
f0105a69:	5e                   	pop    %esi
f0105a6a:	5d                   	pop    %ebp
f0105a6b:	c3                   	ret    

f0105a6c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105a6c:	55                   	push   %ebp
f0105a6d:	89 e5                	mov    %esp,%ebp
f0105a6f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a72:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105a75:	eb 06                	jmp    f0105a7d <strcmp+0x11>
		p++, q++;
f0105a77:	83 c1 01             	add    $0x1,%ecx
f0105a7a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0105a7d:	0f b6 01             	movzbl (%ecx),%eax
f0105a80:	84 c0                	test   %al,%al
f0105a82:	74 04                	je     f0105a88 <strcmp+0x1c>
f0105a84:	3a 02                	cmp    (%edx),%al
f0105a86:	74 ef                	je     f0105a77 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105a88:	0f b6 c0             	movzbl %al,%eax
f0105a8b:	0f b6 12             	movzbl (%edx),%edx
f0105a8e:	29 d0                	sub    %edx,%eax
}
f0105a90:	5d                   	pop    %ebp
f0105a91:	c3                   	ret    

f0105a92 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105a92:	55                   	push   %ebp
f0105a93:	89 e5                	mov    %esp,%ebp
f0105a95:	53                   	push   %ebx
f0105a96:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a99:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a9c:	89 c3                	mov    %eax,%ebx
f0105a9e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105aa1:	eb 06                	jmp    f0105aa9 <strncmp+0x17>
		n--, p++, q++;
f0105aa3:	83 c0 01             	add    $0x1,%eax
f0105aa6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105aa9:	39 d8                	cmp    %ebx,%eax
f0105aab:	74 15                	je     f0105ac2 <strncmp+0x30>
f0105aad:	0f b6 08             	movzbl (%eax),%ecx
f0105ab0:	84 c9                	test   %cl,%cl
f0105ab2:	74 04                	je     f0105ab8 <strncmp+0x26>
f0105ab4:	3a 0a                	cmp    (%edx),%cl
f0105ab6:	74 eb                	je     f0105aa3 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105ab8:	0f b6 00             	movzbl (%eax),%eax
f0105abb:	0f b6 12             	movzbl (%edx),%edx
f0105abe:	29 d0                	sub    %edx,%eax
f0105ac0:	eb 05                	jmp    f0105ac7 <strncmp+0x35>
		return 0;
f0105ac2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105ac7:	5b                   	pop    %ebx
f0105ac8:	5d                   	pop    %ebp
f0105ac9:	c3                   	ret    

f0105aca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105aca:	55                   	push   %ebp
f0105acb:	89 e5                	mov    %esp,%ebp
f0105acd:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ad0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105ad4:	eb 07                	jmp    f0105add <strchr+0x13>
		if (*s == c)
f0105ad6:	38 ca                	cmp    %cl,%dl
f0105ad8:	74 0f                	je     f0105ae9 <strchr+0x1f>
	for (; *s; s++)
f0105ada:	83 c0 01             	add    $0x1,%eax
f0105add:	0f b6 10             	movzbl (%eax),%edx
f0105ae0:	84 d2                	test   %dl,%dl
f0105ae2:	75 f2                	jne    f0105ad6 <strchr+0xc>
			return (char *) s;
	return 0;
f0105ae4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105ae9:	5d                   	pop    %ebp
f0105aea:	c3                   	ret    

f0105aeb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105aeb:	55                   	push   %ebp
f0105aec:	89 e5                	mov    %esp,%ebp
f0105aee:	8b 45 08             	mov    0x8(%ebp),%eax
f0105af1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105af5:	eb 07                	jmp    f0105afe <strfind+0x13>
		if (*s == c)
f0105af7:	38 ca                	cmp    %cl,%dl
f0105af9:	74 0a                	je     f0105b05 <strfind+0x1a>
	for (; *s; s++)
f0105afb:	83 c0 01             	add    $0x1,%eax
f0105afe:	0f b6 10             	movzbl (%eax),%edx
f0105b01:	84 d2                	test   %dl,%dl
f0105b03:	75 f2                	jne    f0105af7 <strfind+0xc>
			break;
	return (char *) s;
}
f0105b05:	5d                   	pop    %ebp
f0105b06:	c3                   	ret    

f0105b07 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105b07:	55                   	push   %ebp
f0105b08:	89 e5                	mov    %esp,%ebp
f0105b0a:	57                   	push   %edi
f0105b0b:	56                   	push   %esi
f0105b0c:	53                   	push   %ebx
f0105b0d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105b10:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105b13:	85 c9                	test   %ecx,%ecx
f0105b15:	74 36                	je     f0105b4d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105b17:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105b1d:	75 28                	jne    f0105b47 <memset+0x40>
f0105b1f:	f6 c1 03             	test   $0x3,%cl
f0105b22:	75 23                	jne    f0105b47 <memset+0x40>
		c &= 0xFF;
f0105b24:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105b28:	89 d3                	mov    %edx,%ebx
f0105b2a:	c1 e3 08             	shl    $0x8,%ebx
f0105b2d:	89 d6                	mov    %edx,%esi
f0105b2f:	c1 e6 18             	shl    $0x18,%esi
f0105b32:	89 d0                	mov    %edx,%eax
f0105b34:	c1 e0 10             	shl    $0x10,%eax
f0105b37:	09 f0                	or     %esi,%eax
f0105b39:	09 c2                	or     %eax,%edx
f0105b3b:	89 d0                	mov    %edx,%eax
f0105b3d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105b3f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105b42:	fc                   	cld    
f0105b43:	f3 ab                	rep stos %eax,%es:(%edi)
f0105b45:	eb 06                	jmp    f0105b4d <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105b47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105b4a:	fc                   	cld    
f0105b4b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105b4d:	89 f8                	mov    %edi,%eax
f0105b4f:	5b                   	pop    %ebx
f0105b50:	5e                   	pop    %esi
f0105b51:	5f                   	pop    %edi
f0105b52:	5d                   	pop    %ebp
f0105b53:	c3                   	ret    

f0105b54 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105b54:	55                   	push   %ebp
f0105b55:	89 e5                	mov    %esp,%ebp
f0105b57:	57                   	push   %edi
f0105b58:	56                   	push   %esi
f0105b59:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b5c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105b5f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105b62:	39 c6                	cmp    %eax,%esi
f0105b64:	73 35                	jae    f0105b9b <memmove+0x47>
f0105b66:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105b69:	39 d0                	cmp    %edx,%eax
f0105b6b:	73 2e                	jae    f0105b9b <memmove+0x47>
		s += n;
		d += n;
f0105b6d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105b70:	89 d6                	mov    %edx,%esi
f0105b72:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105b74:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105b7a:	75 13                	jne    f0105b8f <memmove+0x3b>
f0105b7c:	f6 c1 03             	test   $0x3,%cl
f0105b7f:	75 0e                	jne    f0105b8f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105b81:	83 ef 04             	sub    $0x4,%edi
f0105b84:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105b87:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105b8a:	fd                   	std    
f0105b8b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105b8d:	eb 09                	jmp    f0105b98 <memmove+0x44>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105b8f:	83 ef 01             	sub    $0x1,%edi
f0105b92:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105b95:	fd                   	std    
f0105b96:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105b98:	fc                   	cld    
f0105b99:	eb 1d                	jmp    f0105bb8 <memmove+0x64>
f0105b9b:	89 f2                	mov    %esi,%edx
f0105b9d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105b9f:	f6 c2 03             	test   $0x3,%dl
f0105ba2:	75 0f                	jne    f0105bb3 <memmove+0x5f>
f0105ba4:	f6 c1 03             	test   $0x3,%cl
f0105ba7:	75 0a                	jne    f0105bb3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105ba9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105bac:	89 c7                	mov    %eax,%edi
f0105bae:	fc                   	cld    
f0105baf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105bb1:	eb 05                	jmp    f0105bb8 <memmove+0x64>
		else
			asm volatile("cld; rep movsb\n"
f0105bb3:	89 c7                	mov    %eax,%edi
f0105bb5:	fc                   	cld    
f0105bb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105bb8:	5e                   	pop    %esi
f0105bb9:	5f                   	pop    %edi
f0105bba:	5d                   	pop    %ebp
f0105bbb:	c3                   	ret    

f0105bbc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105bbc:	55                   	push   %ebp
f0105bbd:	89 e5                	mov    %esp,%ebp
f0105bbf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105bc2:	8b 45 10             	mov    0x10(%ebp),%eax
f0105bc5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105bc9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105bcc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105bd0:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bd3:	89 04 24             	mov    %eax,(%esp)
f0105bd6:	e8 79 ff ff ff       	call   f0105b54 <memmove>
}
f0105bdb:	c9                   	leave  
f0105bdc:	c3                   	ret    

f0105bdd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105bdd:	55                   	push   %ebp
f0105bde:	89 e5                	mov    %esp,%ebp
f0105be0:	56                   	push   %esi
f0105be1:	53                   	push   %ebx
f0105be2:	8b 55 08             	mov    0x8(%ebp),%edx
f0105be5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105be8:	89 d6                	mov    %edx,%esi
f0105bea:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105bed:	eb 1a                	jmp    f0105c09 <memcmp+0x2c>
		if (*s1 != *s2)
f0105bef:	0f b6 02             	movzbl (%edx),%eax
f0105bf2:	0f b6 19             	movzbl (%ecx),%ebx
f0105bf5:	38 d8                	cmp    %bl,%al
f0105bf7:	74 0a                	je     f0105c03 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105bf9:	0f b6 c0             	movzbl %al,%eax
f0105bfc:	0f b6 db             	movzbl %bl,%ebx
f0105bff:	29 d8                	sub    %ebx,%eax
f0105c01:	eb 0f                	jmp    f0105c12 <memcmp+0x35>
		s1++, s2++;
f0105c03:	83 c2 01             	add    $0x1,%edx
f0105c06:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0105c09:	39 f2                	cmp    %esi,%edx
f0105c0b:	75 e2                	jne    f0105bef <memcmp+0x12>
	}

	return 0;
f0105c0d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c12:	5b                   	pop    %ebx
f0105c13:	5e                   	pop    %esi
f0105c14:	5d                   	pop    %ebp
f0105c15:	c3                   	ret    

f0105c16 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105c16:	55                   	push   %ebp
f0105c17:	89 e5                	mov    %esp,%ebp
f0105c19:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c1c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105c1f:	89 c2                	mov    %eax,%edx
f0105c21:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105c24:	eb 07                	jmp    f0105c2d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105c26:	38 08                	cmp    %cl,(%eax)
f0105c28:	74 07                	je     f0105c31 <memfind+0x1b>
	for (; s < ends; s++)
f0105c2a:	83 c0 01             	add    $0x1,%eax
f0105c2d:	39 d0                	cmp    %edx,%eax
f0105c2f:	72 f5                	jb     f0105c26 <memfind+0x10>
			break;
	return (void *) s;
}
f0105c31:	5d                   	pop    %ebp
f0105c32:	c3                   	ret    

f0105c33 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105c33:	55                   	push   %ebp
f0105c34:	89 e5                	mov    %esp,%ebp
f0105c36:	57                   	push   %edi
f0105c37:	56                   	push   %esi
f0105c38:	53                   	push   %ebx
f0105c39:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c3c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105c3f:	eb 03                	jmp    f0105c44 <strtol+0x11>
		s++;
f0105c41:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0105c44:	0f b6 0a             	movzbl (%edx),%ecx
f0105c47:	80 f9 09             	cmp    $0x9,%cl
f0105c4a:	74 f5                	je     f0105c41 <strtol+0xe>
f0105c4c:	80 f9 20             	cmp    $0x20,%cl
f0105c4f:	74 f0                	je     f0105c41 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0105c51:	80 f9 2b             	cmp    $0x2b,%cl
f0105c54:	75 0a                	jne    f0105c60 <strtol+0x2d>
		s++;
f0105c56:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0105c59:	bf 00 00 00 00       	mov    $0x0,%edi
f0105c5e:	eb 11                	jmp    f0105c71 <strtol+0x3e>
f0105c60:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f0105c65:	80 f9 2d             	cmp    $0x2d,%cl
f0105c68:	75 07                	jne    f0105c71 <strtol+0x3e>
		s++, neg = 1;
f0105c6a:	8d 52 01             	lea    0x1(%edx),%edx
f0105c6d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105c71:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105c76:	75 15                	jne    f0105c8d <strtol+0x5a>
f0105c78:	80 3a 30             	cmpb   $0x30,(%edx)
f0105c7b:	75 10                	jne    f0105c8d <strtol+0x5a>
f0105c7d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105c81:	75 0a                	jne    f0105c8d <strtol+0x5a>
		s += 2, base = 16;
f0105c83:	83 c2 02             	add    $0x2,%edx
f0105c86:	b8 10 00 00 00       	mov    $0x10,%eax
f0105c8b:	eb 10                	jmp    f0105c9d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0105c8d:	85 c0                	test   %eax,%eax
f0105c8f:	75 0c                	jne    f0105c9d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105c91:	b0 0a                	mov    $0xa,%al
	else if (base == 0 && s[0] == '0')
f0105c93:	80 3a 30             	cmpb   $0x30,(%edx)
f0105c96:	75 05                	jne    f0105c9d <strtol+0x6a>
		s++, base = 8;
f0105c98:	83 c2 01             	add    $0x1,%edx
f0105c9b:	b0 08                	mov    $0x8,%al
		base = 10;
f0105c9d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105ca2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105ca5:	0f b6 0a             	movzbl (%edx),%ecx
f0105ca8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0105cab:	89 f0                	mov    %esi,%eax
f0105cad:	3c 09                	cmp    $0x9,%al
f0105caf:	77 08                	ja     f0105cb9 <strtol+0x86>
			dig = *s - '0';
f0105cb1:	0f be c9             	movsbl %cl,%ecx
f0105cb4:	83 e9 30             	sub    $0x30,%ecx
f0105cb7:	eb 20                	jmp    f0105cd9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105cb9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0105cbc:	89 f0                	mov    %esi,%eax
f0105cbe:	3c 19                	cmp    $0x19,%al
f0105cc0:	77 08                	ja     f0105cca <strtol+0x97>
			dig = *s - 'a' + 10;
f0105cc2:	0f be c9             	movsbl %cl,%ecx
f0105cc5:	83 e9 57             	sub    $0x57,%ecx
f0105cc8:	eb 0f                	jmp    f0105cd9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0105cca:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0105ccd:	89 f0                	mov    %esi,%eax
f0105ccf:	3c 19                	cmp    $0x19,%al
f0105cd1:	77 16                	ja     f0105ce9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105cd3:	0f be c9             	movsbl %cl,%ecx
f0105cd6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105cd9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0105cdc:	7d 0f                	jge    f0105ced <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0105cde:	83 c2 01             	add    $0x1,%edx
f0105ce1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105ce5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105ce7:	eb bc                	jmp    f0105ca5 <strtol+0x72>
f0105ce9:	89 d8                	mov    %ebx,%eax
f0105ceb:	eb 02                	jmp    f0105cef <strtol+0xbc>
f0105ced:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0105cef:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105cf3:	74 05                	je     f0105cfa <strtol+0xc7>
		*endptr = (char *) s;
f0105cf5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105cf8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0105cfa:	f7 d8                	neg    %eax
f0105cfc:	85 ff                	test   %edi,%edi
f0105cfe:	0f 44 c3             	cmove  %ebx,%eax
}
f0105d01:	5b                   	pop    %ebx
f0105d02:	5e                   	pop    %esi
f0105d03:	5f                   	pop    %edi
f0105d04:	5d                   	pop    %ebp
f0105d05:	c3                   	ret    
f0105d06:	66 90                	xchg   %ax,%ax

f0105d08 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105d08:	fa                   	cli    

	xorw    %ax, %ax
f0105d09:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105d0b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d0d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d0f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105d11:	0f 01 16             	lgdtl  (%esi)
f0105d14:	74 70                	je     f0105d86 <mpentry_end+0x4>
	movl    %cr0, %eax
f0105d16:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105d19:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105d1d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105d20:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105d26:	08 00                	or     %al,(%eax)

f0105d28 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105d28:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105d2c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d2e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d30:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105d32:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105d36:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105d38:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105d3a:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f0105d3f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105d42:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105d45:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105d4a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105d4d:	8b 25 84 be 22 f0    	mov    0xf022be84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105d53:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105d58:	b8 c2 01 10 f0       	mov    $0xf01001c2,%eax
	call    *%eax
f0105d5d:	ff d0                	call   *%eax

f0105d5f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105d5f:	eb fe                	jmp    f0105d5f <spin>
f0105d61:	8d 76 00             	lea    0x0(%esi),%esi

f0105d64 <gdt>:
	...
f0105d6c:	ff                   	(bad)  
f0105d6d:	ff 00                	incl   (%eax)
f0105d6f:	00 00                	add    %al,(%eax)
f0105d71:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105d78:	00                   	.byte 0x0
f0105d79:	92                   	xchg   %eax,%edx
f0105d7a:	cf                   	iret   
	...

f0105d7c <gdtdesc>:
f0105d7c:	17                   	pop    %ss
f0105d7d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105d82 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105d82:	90                   	nop
f0105d83:	66 90                	xchg   %ax,%ax
f0105d85:	66 90                	xchg   %ax,%ax
f0105d87:	66 90                	xchg   %ax,%ax
f0105d89:	66 90                	xchg   %ax,%ax
f0105d8b:	66 90                	xchg   %ax,%ax
f0105d8d:	66 90                	xchg   %ax,%ax
f0105d8f:	90                   	nop

f0105d90 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105d90:	55                   	push   %ebp
f0105d91:	89 e5                	mov    %esp,%ebp
f0105d93:	56                   	push   %esi
f0105d94:	53                   	push   %ebx
f0105d95:	83 ec 10             	sub    $0x10,%esp
	if (PGNUM(pa) >= npages)
f0105d98:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f0105d9e:	89 c3                	mov    %eax,%ebx
f0105da0:	c1 eb 0c             	shr    $0xc,%ebx
f0105da3:	39 cb                	cmp    %ecx,%ebx
f0105da5:	72 20                	jb     f0105dc7 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105da7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105dab:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0105db2:	f0 
f0105db3:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105dba:	00 
f0105dbb:	c7 04 24 a1 83 10 f0 	movl   $0xf01083a1,(%esp)
f0105dc2:	e8 79 a2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105dc7:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105dcd:	01 d0                	add    %edx,%eax
	if (PGNUM(pa) >= npages)
f0105dcf:	89 c2                	mov    %eax,%edx
f0105dd1:	c1 ea 0c             	shr    $0xc,%edx
f0105dd4:	39 d1                	cmp    %edx,%ecx
f0105dd6:	77 20                	ja     f0105df8 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105dd8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105ddc:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0105de3:	f0 
f0105de4:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105deb:	00 
f0105dec:	c7 04 24 a1 83 10 f0 	movl   $0xf01083a1,(%esp)
f0105df3:	e8 48 a2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105df8:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105dfe:	eb 36                	jmp    f0105e36 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e00:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105e07:	00 
f0105e08:	c7 44 24 04 b1 83 10 	movl   $0xf01083b1,0x4(%esp)
f0105e0f:	f0 
f0105e10:	89 1c 24             	mov    %ebx,(%esp)
f0105e13:	e8 c5 fd ff ff       	call   f0105bdd <memcmp>
f0105e18:	85 c0                	test   %eax,%eax
f0105e1a:	75 17                	jne    f0105e33 <mpsearch1+0xa3>
	for (i = 0; i < len; i++)
f0105e1c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f0105e21:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0105e25:	01 c8                	add    %ecx,%eax
	for (i = 0; i < len; i++)
f0105e27:	83 c2 01             	add    $0x1,%edx
f0105e2a:	83 fa 10             	cmp    $0x10,%edx
f0105e2d:	75 f2                	jne    f0105e21 <mpsearch1+0x91>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e2f:	84 c0                	test   %al,%al
f0105e31:	74 0e                	je     f0105e41 <mpsearch1+0xb1>
	for (; mp < end; mp++)
f0105e33:	83 c3 10             	add    $0x10,%ebx
f0105e36:	39 f3                	cmp    %esi,%ebx
f0105e38:	72 c6                	jb     f0105e00 <mpsearch1+0x70>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105e3a:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e3f:	eb 02                	jmp    f0105e43 <mpsearch1+0xb3>
f0105e41:	89 d8                	mov    %ebx,%eax
}
f0105e43:	83 c4 10             	add    $0x10,%esp
f0105e46:	5b                   	pop    %ebx
f0105e47:	5e                   	pop    %esi
f0105e48:	5d                   	pop    %ebp
f0105e49:	c3                   	ret    

f0105e4a <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105e4a:	55                   	push   %ebp
f0105e4b:	89 e5                	mov    %esp,%ebp
f0105e4d:	57                   	push   %edi
f0105e4e:	56                   	push   %esi
f0105e4f:	53                   	push   %ebx
f0105e50:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105e53:	c7 05 c0 c3 22 f0 20 	movl   $0xf022c020,0xf022c3c0
f0105e5a:	c0 22 f0 
	if (PGNUM(pa) >= npages)
f0105e5d:	83 3d 88 be 22 f0 00 	cmpl   $0x0,0xf022be88
f0105e64:	75 24                	jne    f0105e8a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105e66:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0105e6d:	00 
f0105e6e:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0105e75:	f0 
f0105e76:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0105e7d:	00 
f0105e7e:	c7 04 24 a1 83 10 f0 	movl   $0xf01083a1,(%esp)
f0105e85:	e8 b6 a1 ff ff       	call   f0100040 <_panic>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105e8a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105e91:	85 c0                	test   %eax,%eax
f0105e93:	74 16                	je     f0105eab <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0105e95:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105e98:	ba 00 04 00 00       	mov    $0x400,%edx
f0105e9d:	e8 ee fe ff ff       	call   f0105d90 <mpsearch1>
f0105ea2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105ea5:	85 c0                	test   %eax,%eax
f0105ea7:	75 3c                	jne    f0105ee5 <mp_init+0x9b>
f0105ea9:	eb 20                	jmp    f0105ecb <mp_init+0x81>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105eab:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105eb2:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105eb5:	2d 00 04 00 00       	sub    $0x400,%eax
f0105eba:	ba 00 04 00 00       	mov    $0x400,%edx
f0105ebf:	e8 cc fe ff ff       	call   f0105d90 <mpsearch1>
f0105ec4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105ec7:	85 c0                	test   %eax,%eax
f0105ec9:	75 1a                	jne    f0105ee5 <mp_init+0x9b>
	return mpsearch1(0xF0000, 0x10000);
f0105ecb:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105ed0:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105ed5:	e8 b6 fe ff ff       	call   f0105d90 <mpsearch1>
f0105eda:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if ((mp = mpsearch()) == 0)
f0105edd:	85 c0                	test   %eax,%eax
f0105edf:	0f 84 54 02 00 00    	je     f0106139 <mp_init+0x2ef>
	if (mp->physaddr == 0 || mp->type != 0) {
f0105ee5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105ee8:	8b 70 04             	mov    0x4(%eax),%esi
f0105eeb:	85 f6                	test   %esi,%esi
f0105eed:	74 06                	je     f0105ef5 <mp_init+0xab>
f0105eef:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105ef3:	74 11                	je     f0105f06 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0105ef5:	c7 04 24 14 82 10 f0 	movl   $0xf0108214,(%esp)
f0105efc:	e8 fa e0 ff ff       	call   f0103ffb <cprintf>
f0105f01:	e9 33 02 00 00       	jmp    f0106139 <mp_init+0x2ef>
	if (PGNUM(pa) >= npages)
f0105f06:	89 f0                	mov    %esi,%eax
f0105f08:	c1 e8 0c             	shr    $0xc,%eax
f0105f0b:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0105f11:	72 20                	jb     f0105f33 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105f13:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105f17:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f0105f1e:	f0 
f0105f1f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0105f26:	00 
f0105f27:	c7 04 24 a1 83 10 f0 	movl   $0xf01083a1,(%esp)
f0105f2e:	e8 0d a1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105f33:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105f39:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105f40:	00 
f0105f41:	c7 44 24 04 b6 83 10 	movl   $0xf01083b6,0x4(%esp)
f0105f48:	f0 
f0105f49:	89 1c 24             	mov    %ebx,(%esp)
f0105f4c:	e8 8c fc ff ff       	call   f0105bdd <memcmp>
f0105f51:	85 c0                	test   %eax,%eax
f0105f53:	74 11                	je     f0105f66 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105f55:	c7 04 24 44 82 10 f0 	movl   $0xf0108244,(%esp)
f0105f5c:	e8 9a e0 ff ff       	call   f0103ffb <cprintf>
f0105f61:	e9 d3 01 00 00       	jmp    f0106139 <mp_init+0x2ef>
	if (sum(conf, conf->length) != 0) {
f0105f66:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105f6a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105f6e:	0f b7 f8             	movzwl %ax,%edi
	sum = 0;
f0105f71:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105f76:	b8 00 00 00 00       	mov    $0x0,%eax
f0105f7b:	eb 0d                	jmp    f0105f8a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f0105f7d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105f84:	f0 
f0105f85:	01 ca                	add    %ecx,%edx
	for (i = 0; i < len; i++)
f0105f87:	83 c0 01             	add    $0x1,%eax
f0105f8a:	39 c7                	cmp    %eax,%edi
f0105f8c:	7f ef                	jg     f0105f7d <mp_init+0x133>
	if (sum(conf, conf->length) != 0) {
f0105f8e:	84 d2                	test   %dl,%dl
f0105f90:	74 11                	je     f0105fa3 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105f92:	c7 04 24 78 82 10 f0 	movl   $0xf0108278,(%esp)
f0105f99:	e8 5d e0 ff ff       	call   f0103ffb <cprintf>
f0105f9e:	e9 96 01 00 00       	jmp    f0106139 <mp_init+0x2ef>
	if (conf->version != 1 && conf->version != 4) {
f0105fa3:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105fa7:	3c 04                	cmp    $0x4,%al
f0105fa9:	74 1f                	je     f0105fca <mp_init+0x180>
f0105fab:	3c 01                	cmp    $0x1,%al
f0105fad:	8d 76 00             	lea    0x0(%esi),%esi
f0105fb0:	74 18                	je     f0105fca <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105fb2:	0f b6 c0             	movzbl %al,%eax
f0105fb5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105fb9:	c7 04 24 9c 82 10 f0 	movl   $0xf010829c,(%esp)
f0105fc0:	e8 36 e0 ff ff       	call   f0103ffb <cprintf>
f0105fc5:	e9 6f 01 00 00       	jmp    f0106139 <mp_init+0x2ef>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105fca:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f0105fce:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0105fd2:	01 df                	add    %ebx,%edi
	sum = 0;
f0105fd4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105fd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0105fde:	eb 09                	jmp    f0105fe9 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0105fe0:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0105fe4:	01 ca                	add    %ecx,%edx
	for (i = 0; i < len; i++)
f0105fe6:	83 c0 01             	add    $0x1,%eax
f0105fe9:	39 c6                	cmp    %eax,%esi
f0105feb:	7f f3                	jg     f0105fe0 <mp_init+0x196>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105fed:	02 53 2a             	add    0x2a(%ebx),%dl
f0105ff0:	84 d2                	test   %dl,%dl
f0105ff2:	74 11                	je     f0106005 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105ff4:	c7 04 24 bc 82 10 f0 	movl   $0xf01082bc,(%esp)
f0105ffb:	e8 fb df ff ff       	call   f0103ffb <cprintf>
f0106000:	e9 34 01 00 00       	jmp    f0106139 <mp_init+0x2ef>
	if ((conf = mpconfig(&mp)) == 0)
f0106005:	85 db                	test   %ebx,%ebx
f0106007:	0f 84 2c 01 00 00    	je     f0106139 <mp_init+0x2ef>
		return;
	ismp = 1;
f010600d:	c7 05 00 c0 22 f0 01 	movl   $0x1,0xf022c000
f0106014:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0106017:	8b 43 24             	mov    0x24(%ebx),%eax
f010601a:	a3 00 d0 26 f0       	mov    %eax,0xf026d000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010601f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0106022:	be 00 00 00 00       	mov    $0x0,%esi
f0106027:	e9 86 00 00 00       	jmp    f01060b2 <mp_init+0x268>
		switch (*p) {
f010602c:	0f b6 07             	movzbl (%edi),%eax
f010602f:	84 c0                	test   %al,%al
f0106031:	74 06                	je     f0106039 <mp_init+0x1ef>
f0106033:	3c 04                	cmp    $0x4,%al
f0106035:	77 57                	ja     f010608e <mp_init+0x244>
f0106037:	eb 50                	jmp    f0106089 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0106039:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f010603d:	8d 76 00             	lea    0x0(%esi),%esi
f0106040:	74 11                	je     f0106053 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f0106042:	6b 05 c4 c3 22 f0 74 	imul   $0x74,0xf022c3c4,%eax
f0106049:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f010604e:	a3 c0 c3 22 f0       	mov    %eax,0xf022c3c0
			if (ncpu < NCPU) {
f0106053:	a1 c4 c3 22 f0       	mov    0xf022c3c4,%eax
f0106058:	83 f8 07             	cmp    $0x7,%eax
f010605b:	7f 13                	jg     f0106070 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f010605d:	6b d0 74             	imul   $0x74,%eax,%edx
f0106060:	88 82 20 c0 22 f0    	mov    %al,-0xfdd3fe0(%edx)
				ncpu++;
f0106066:	83 c0 01             	add    $0x1,%eax
f0106069:	a3 c4 c3 22 f0       	mov    %eax,0xf022c3c4
f010606e:	eb 14                	jmp    f0106084 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0106070:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0106074:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106078:	c7 04 24 ec 82 10 f0 	movl   $0xf01082ec,(%esp)
f010607f:	e8 77 df ff ff       	call   f0103ffb <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106084:	83 c7 14             	add    $0x14,%edi
			continue;
f0106087:	eb 26                	jmp    f01060af <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0106089:	83 c7 08             	add    $0x8,%edi
			continue;
f010608c:	eb 21                	jmp    f01060af <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010608e:	0f b6 c0             	movzbl %al,%eax
f0106091:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106095:	c7 04 24 14 83 10 f0 	movl   $0xf0108314,(%esp)
f010609c:	e8 5a df ff ff       	call   f0103ffb <cprintf>
			ismp = 0;
f01060a1:	c7 05 00 c0 22 f0 00 	movl   $0x0,0xf022c000
f01060a8:	00 00 00 
			i = conf->entry;
f01060ab:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01060af:	83 c6 01             	add    $0x1,%esi
f01060b2:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f01060b6:	39 c6                	cmp    %eax,%esi
f01060b8:	0f 82 6e ff ff ff    	jb     f010602c <mp_init+0x1e2>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01060be:	a1 c0 c3 22 f0       	mov    0xf022c3c0,%eax
f01060c3:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01060ca:	83 3d 00 c0 22 f0 00 	cmpl   $0x0,0xf022c000
f01060d1:	75 22                	jne    f01060f5 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01060d3:	c7 05 c4 c3 22 f0 01 	movl   $0x1,0xf022c3c4
f01060da:	00 00 00 
		lapicaddr = 0;
f01060dd:	c7 05 00 d0 26 f0 00 	movl   $0x0,0xf026d000
f01060e4:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01060e7:	c7 04 24 34 83 10 f0 	movl   $0xf0108334,(%esp)
f01060ee:	e8 08 df ff ff       	call   f0103ffb <cprintf>
		return;
f01060f3:	eb 44                	jmp    f0106139 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01060f5:	8b 15 c4 c3 22 f0    	mov    0xf022c3c4,%edx
f01060fb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01060ff:	0f b6 00             	movzbl (%eax),%eax
f0106102:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106106:	c7 04 24 bb 83 10 f0 	movl   $0xf01083bb,(%esp)
f010610d:	e8 e9 de ff ff       	call   f0103ffb <cprintf>

	if (mp->imcrp) {
f0106112:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106115:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106119:	74 1e                	je     f0106139 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010611b:	c7 04 24 60 83 10 f0 	movl   $0xf0108360,(%esp)
f0106122:	e8 d4 de ff ff       	call   f0103ffb <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106127:	ba 22 00 00 00       	mov    $0x22,%edx
f010612c:	b8 70 00 00 00       	mov    $0x70,%eax
f0106131:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0106132:	b2 23                	mov    $0x23,%dl
f0106134:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106135:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106138:	ee                   	out    %al,(%dx)
	}
}
f0106139:	83 c4 2c             	add    $0x2c,%esp
f010613c:	5b                   	pop    %ebx
f010613d:	5e                   	pop    %esi
f010613e:	5f                   	pop    %edi
f010613f:	5d                   	pop    %ebp
f0106140:	c3                   	ret    

f0106141 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0106141:	55                   	push   %ebp
f0106142:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0106144:	8b 0d 04 d0 26 f0    	mov    0xf026d004,%ecx
f010614a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010614d:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010614f:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0106154:	8b 40 20             	mov    0x20(%eax),%eax
}
f0106157:	5d                   	pop    %ebp
f0106158:	c3                   	ret    

f0106159 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0106159:	55                   	push   %ebp
f010615a:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010615c:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0106161:	85 c0                	test   %eax,%eax
f0106163:	74 08                	je     f010616d <cpunum+0x14>
		return lapic[ID] >> 24;
f0106165:	8b 40 20             	mov    0x20(%eax),%eax
f0106168:	c1 e8 18             	shr    $0x18,%eax
f010616b:	eb 05                	jmp    f0106172 <cpunum+0x19>
	return 0;
f010616d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106172:	5d                   	pop    %ebp
f0106173:	c3                   	ret    

f0106174 <lapic_init>:
	if (!lapicaddr)
f0106174:	a1 00 d0 26 f0       	mov    0xf026d000,%eax
f0106179:	85 c0                	test   %eax,%eax
f010617b:	0f 84 23 01 00 00    	je     f01062a4 <lapic_init+0x130>
{
f0106181:	55                   	push   %ebp
f0106182:	89 e5                	mov    %esp,%ebp
f0106184:	83 ec 18             	sub    $0x18,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f0106187:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010618e:	00 
f010618f:	89 04 24             	mov    %eax,(%esp)
f0106192:	e8 53 b3 ff ff       	call   f01014ea <mmio_map_region>
f0106197:	a3 04 d0 26 f0       	mov    %eax,0xf026d004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010619c:	ba 27 01 00 00       	mov    $0x127,%edx
f01061a1:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01061a6:	e8 96 ff ff ff       	call   f0106141 <lapicw>
	lapicw(TDCR, X1);
f01061ab:	ba 0b 00 00 00       	mov    $0xb,%edx
f01061b0:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01061b5:	e8 87 ff ff ff       	call   f0106141 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01061ba:	ba 20 00 02 00       	mov    $0x20020,%edx
f01061bf:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01061c4:	e8 78 ff ff ff       	call   f0106141 <lapicw>
	lapicw(TICR, 10000000); 
f01061c9:	ba 80 96 98 00       	mov    $0x989680,%edx
f01061ce:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01061d3:	e8 69 ff ff ff       	call   f0106141 <lapicw>
	if (thiscpu != bootcpu)
f01061d8:	e8 7c ff ff ff       	call   f0106159 <cpunum>
f01061dd:	6b c0 74             	imul   $0x74,%eax,%eax
f01061e0:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f01061e5:	39 05 c0 c3 22 f0    	cmp    %eax,0xf022c3c0
f01061eb:	74 0f                	je     f01061fc <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f01061ed:	ba 00 00 01 00       	mov    $0x10000,%edx
f01061f2:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01061f7:	e8 45 ff ff ff       	call   f0106141 <lapicw>
	lapicw(LINT1, MASKED);
f01061fc:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106201:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0106206:	e8 36 ff ff ff       	call   f0106141 <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010620b:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0106210:	8b 40 30             	mov    0x30(%eax),%eax
f0106213:	c1 e8 10             	shr    $0x10,%eax
f0106216:	3c 03                	cmp    $0x3,%al
f0106218:	76 0f                	jbe    f0106229 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f010621a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010621f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0106224:	e8 18 ff ff ff       	call   f0106141 <lapicw>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0106229:	ba 33 00 00 00       	mov    $0x33,%edx
f010622e:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0106233:	e8 09 ff ff ff       	call   f0106141 <lapicw>
	lapicw(ESR, 0);
f0106238:	ba 00 00 00 00       	mov    $0x0,%edx
f010623d:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106242:	e8 fa fe ff ff       	call   f0106141 <lapicw>
	lapicw(ESR, 0);
f0106247:	ba 00 00 00 00       	mov    $0x0,%edx
f010624c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106251:	e8 eb fe ff ff       	call   f0106141 <lapicw>
	lapicw(EOI, 0);
f0106256:	ba 00 00 00 00       	mov    $0x0,%edx
f010625b:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106260:	e8 dc fe ff ff       	call   f0106141 <lapicw>
	lapicw(ICRHI, 0);
f0106265:	ba 00 00 00 00       	mov    $0x0,%edx
f010626a:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010626f:	e8 cd fe ff ff       	call   f0106141 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0106274:	ba 00 85 08 00       	mov    $0x88500,%edx
f0106279:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010627e:	e8 be fe ff ff       	call   f0106141 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106283:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f0106289:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010628f:	f6 c4 10             	test   $0x10,%ah
f0106292:	75 f5                	jne    f0106289 <lapic_init+0x115>
	lapicw(TPR, 0);
f0106294:	ba 00 00 00 00       	mov    $0x0,%edx
f0106299:	b8 20 00 00 00       	mov    $0x20,%eax
f010629e:	e8 9e fe ff ff       	call   f0106141 <lapicw>
}
f01062a3:	c9                   	leave  
f01062a4:	f3 c3                	repz ret 

f01062a6 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01062a6:	83 3d 04 d0 26 f0 00 	cmpl   $0x0,0xf026d004
f01062ad:	74 13                	je     f01062c2 <lapic_eoi+0x1c>
{
f01062af:	55                   	push   %ebp
f01062b0:	89 e5                	mov    %esp,%ebp
		lapicw(EOI, 0);
f01062b2:	ba 00 00 00 00       	mov    $0x0,%edx
f01062b7:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01062bc:	e8 80 fe ff ff       	call   f0106141 <lapicw>
}
f01062c1:	5d                   	pop    %ebp
f01062c2:	f3 c3                	repz ret 

f01062c4 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01062c4:	55                   	push   %ebp
f01062c5:	89 e5                	mov    %esp,%ebp
f01062c7:	56                   	push   %esi
f01062c8:	53                   	push   %ebx
f01062c9:	83 ec 10             	sub    $0x10,%esp
f01062cc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01062cf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01062d2:	ba 70 00 00 00       	mov    $0x70,%edx
f01062d7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01062dc:	ee                   	out    %al,(%dx)
f01062dd:	b2 71                	mov    $0x71,%dl
f01062df:	b8 0a 00 00 00       	mov    $0xa,%eax
f01062e4:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f01062e5:	83 3d 88 be 22 f0 00 	cmpl   $0x0,0xf022be88
f01062ec:	75 24                	jne    f0106312 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01062ee:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f01062f5:	00 
f01062f6:	c7 44 24 08 64 68 10 	movl   $0xf0106864,0x8(%esp)
f01062fd:	f0 
f01062fe:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0106305:	00 
f0106306:	c7 04 24 d8 83 10 f0 	movl   $0xf01083d8,(%esp)
f010630d:	e8 2e 9d ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106312:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106319:	00 00 
	wrv[1] = addr >> 4;
f010631b:	89 f0                	mov    %esi,%eax
f010631d:	c1 e8 04             	shr    $0x4,%eax
f0106320:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106326:	c1 e3 18             	shl    $0x18,%ebx
f0106329:	89 da                	mov    %ebx,%edx
f010632b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106330:	e8 0c fe ff ff       	call   f0106141 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106335:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010633a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010633f:	e8 fd fd ff ff       	call   f0106141 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106344:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106349:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010634e:	e8 ee fd ff ff       	call   f0106141 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106353:	c1 ee 0c             	shr    $0xc,%esi
f0106356:	81 ce 00 06 00 00    	or     $0x600,%esi
		lapicw(ICRHI, apicid << 24);
f010635c:	89 da                	mov    %ebx,%edx
f010635e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106363:	e8 d9 fd ff ff       	call   f0106141 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106368:	89 f2                	mov    %esi,%edx
f010636a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010636f:	e8 cd fd ff ff       	call   f0106141 <lapicw>
		lapicw(ICRHI, apicid << 24);
f0106374:	89 da                	mov    %ebx,%edx
f0106376:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010637b:	e8 c1 fd ff ff       	call   f0106141 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106380:	89 f2                	mov    %esi,%edx
f0106382:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106387:	e8 b5 fd ff ff       	call   f0106141 <lapicw>
		microdelay(200);
	}
}
f010638c:	83 c4 10             	add    $0x10,%esp
f010638f:	5b                   	pop    %ebx
f0106390:	5e                   	pop    %esi
f0106391:	5d                   	pop    %ebp
f0106392:	c3                   	ret    

f0106393 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106393:	55                   	push   %ebp
f0106394:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106396:	8b 55 08             	mov    0x8(%ebp),%edx
f0106399:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010639f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063a4:	e8 98 fd ff ff       	call   f0106141 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f01063a9:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f01063af:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01063b5:	f6 c4 10             	test   $0x10,%ah
f01063b8:	75 f5                	jne    f01063af <lapic_ipi+0x1c>
		;
}
f01063ba:	5d                   	pop    %ebp
f01063bb:	c3                   	ret    

f01063bc <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01063bc:	55                   	push   %ebp
f01063bd:	89 e5                	mov    %esp,%ebp
f01063bf:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01063c2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01063c8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01063cb:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01063ce:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01063d5:	5d                   	pop    %ebp
f01063d6:	c3                   	ret    

f01063d7 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01063d7:	55                   	push   %ebp
f01063d8:	89 e5                	mov    %esp,%ebp
f01063da:	56                   	push   %esi
f01063db:	53                   	push   %ebx
f01063dc:	83 ec 20             	sub    $0x20,%esp
f01063df:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f01063e2:	83 3b 00             	cmpl   $0x0,(%ebx)
f01063e5:	75 07                	jne    f01063ee <spin_lock+0x17>
	asm volatile("lock; xchgl %0, %1"
f01063e7:	ba 01 00 00 00       	mov    $0x1,%edx
f01063ec:	eb 42                	jmp    f0106430 <spin_lock+0x59>
f01063ee:	8b 73 08             	mov    0x8(%ebx),%esi
f01063f1:	e8 63 fd ff ff       	call   f0106159 <cpunum>
f01063f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01063f9:	05 20 c0 22 f0       	add    $0xf022c020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01063fe:	39 c6                	cmp    %eax,%esi
f0106400:	75 e5                	jne    f01063e7 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106402:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106405:	e8 4f fd ff ff       	call   f0106159 <cpunum>
f010640a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f010640e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106412:	c7 44 24 08 e8 83 10 	movl   $0xf01083e8,0x8(%esp)
f0106419:	f0 
f010641a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f0106421:	00 
f0106422:	c7 04 24 4c 84 10 f0 	movl   $0xf010844c,(%esp)
f0106429:	e8 12 9c ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f010642e:	f3 90                	pause  
f0106430:	89 d0                	mov    %edx,%eax
f0106432:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f0106435:	85 c0                	test   %eax,%eax
f0106437:	75 f5                	jne    f010642e <spin_lock+0x57>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0106439:	e8 1b fd ff ff       	call   f0106159 <cpunum>
f010643e:	6b c0 74             	imul   $0x74,%eax,%eax
f0106441:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0106446:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0106449:	83 c3 0c             	add    $0xc,%ebx
	ebp = (uint32_t *)read_ebp();
f010644c:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f010644e:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106453:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0106459:	76 12                	jbe    f010646d <spin_lock+0x96>
		pcs[i] = ebp[1];          // saved %eip
f010645b:	8b 4a 04             	mov    0x4(%edx),%ecx
f010645e:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106461:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f0106463:	83 c0 01             	add    $0x1,%eax
f0106466:	83 f8 0a             	cmp    $0xa,%eax
f0106469:	75 e8                	jne    f0106453 <spin_lock+0x7c>
f010646b:	eb 0f                	jmp    f010647c <spin_lock+0xa5>
		pcs[i] = 0;
f010646d:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
	for (; i < 10; i++)
f0106474:	83 c0 01             	add    $0x1,%eax
f0106477:	83 f8 09             	cmp    $0x9,%eax
f010647a:	7e f1                	jle    f010646d <spin_lock+0x96>
#endif
}
f010647c:	83 c4 20             	add    $0x20,%esp
f010647f:	5b                   	pop    %ebx
f0106480:	5e                   	pop    %esi
f0106481:	5d                   	pop    %ebp
f0106482:	c3                   	ret    

f0106483 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106483:	55                   	push   %ebp
f0106484:	89 e5                	mov    %esp,%ebp
f0106486:	57                   	push   %edi
f0106487:	56                   	push   %esi
f0106488:	53                   	push   %ebx
f0106489:	83 ec 6c             	sub    $0x6c,%esp
f010648c:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f010648f:	83 3e 00             	cmpl   $0x0,(%esi)
f0106492:	74 18                	je     f01064ac <spin_unlock+0x29>
f0106494:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106497:	e8 bd fc ff ff       	call   f0106159 <cpunum>
f010649c:	6b c0 74             	imul   $0x74,%eax,%eax
f010649f:	05 20 c0 22 f0       	add    $0xf022c020,%eax
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f01064a4:	39 c3                	cmp    %eax,%ebx
f01064a6:	0f 84 ce 00 00 00    	je     f010657a <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f01064ac:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f01064b3:	00 
f01064b4:	8d 46 0c             	lea    0xc(%esi),%eax
f01064b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01064bb:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f01064be:	89 1c 24             	mov    %ebx,(%esp)
f01064c1:	e8 8e f6 ff ff       	call   f0105b54 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f01064c6:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f01064c9:	0f b6 38             	movzbl (%eax),%edi
f01064cc:	8b 76 04             	mov    0x4(%esi),%esi
f01064cf:	e8 85 fc ff ff       	call   f0106159 <cpunum>
f01064d4:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01064d8:	89 74 24 08          	mov    %esi,0x8(%esp)
f01064dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01064e0:	c7 04 24 14 84 10 f0 	movl   $0xf0108414,(%esp)
f01064e7:	e8 0f db ff ff       	call   f0103ffb <cprintf>
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01064ec:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01064ef:	eb 65                	jmp    f0106556 <spin_unlock+0xd3>
f01064f1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01064f5:	89 04 24             	mov    %eax,(%esp)
f01064f8:	e8 ca ea ff ff       	call   f0104fc7 <debuginfo_eip>
f01064fd:	85 c0                	test   %eax,%eax
f01064ff:	78 39                	js     f010653a <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106501:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106503:	89 c2                	mov    %eax,%edx
f0106505:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106508:	89 54 24 18          	mov    %edx,0x18(%esp)
f010650c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f010650f:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106513:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106516:	89 54 24 10          	mov    %edx,0x10(%esp)
f010651a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f010651d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0106521:	8b 55 a8             	mov    -0x58(%ebp),%edx
f0106524:	89 54 24 08          	mov    %edx,0x8(%esp)
f0106528:	89 44 24 04          	mov    %eax,0x4(%esp)
f010652c:	c7 04 24 5c 84 10 f0 	movl   $0xf010845c,(%esp)
f0106533:	e8 c3 da ff ff       	call   f0103ffb <cprintf>
f0106538:	eb 12                	jmp    f010654c <spin_unlock+0xc9>
			else
				cprintf("  %08x\n", pcs[i]);
f010653a:	8b 06                	mov    (%esi),%eax
f010653c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106540:	c7 04 24 73 84 10 f0 	movl   $0xf0108473,(%esp)
f0106547:	e8 af da ff ff       	call   f0103ffb <cprintf>
f010654c:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f010654f:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106552:	39 c3                	cmp    %eax,%ebx
f0106554:	74 08                	je     f010655e <spin_unlock+0xdb>
f0106556:	89 de                	mov    %ebx,%esi
f0106558:	8b 03                	mov    (%ebx),%eax
f010655a:	85 c0                	test   %eax,%eax
f010655c:	75 93                	jne    f01064f1 <spin_unlock+0x6e>
		}
		panic("spin_unlock");
f010655e:	c7 44 24 08 7b 84 10 	movl   $0xf010847b,0x8(%esp)
f0106565:	f0 
f0106566:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f010656d:	00 
f010656e:	c7 04 24 4c 84 10 f0 	movl   $0xf010844c,(%esp)
f0106575:	e8 c6 9a ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f010657a:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106581:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0106588:	b8 00 00 00 00       	mov    $0x0,%eax
f010658d:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0106590:	83 c4 6c             	add    $0x6c,%esp
f0106593:	5b                   	pop    %ebx
f0106594:	5e                   	pop    %esi
f0106595:	5f                   	pop    %edi
f0106596:	5d                   	pop    %ebp
f0106597:	c3                   	ret    
f0106598:	66 90                	xchg   %ax,%ax
f010659a:	66 90                	xchg   %ax,%ax
f010659c:	66 90                	xchg   %ax,%ax
f010659e:	66 90                	xchg   %ax,%ax

f01065a0 <__udivdi3>:
f01065a0:	55                   	push   %ebp
f01065a1:	57                   	push   %edi
f01065a2:	56                   	push   %esi
f01065a3:	83 ec 0c             	sub    $0xc,%esp
f01065a6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01065aa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01065ae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01065b2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01065b6:	85 c0                	test   %eax,%eax
f01065b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01065bc:	89 ea                	mov    %ebp,%edx
f01065be:	89 0c 24             	mov    %ecx,(%esp)
f01065c1:	75 2d                	jne    f01065f0 <__udivdi3+0x50>
f01065c3:	39 e9                	cmp    %ebp,%ecx
f01065c5:	77 61                	ja     f0106628 <__udivdi3+0x88>
f01065c7:	85 c9                	test   %ecx,%ecx
f01065c9:	89 ce                	mov    %ecx,%esi
f01065cb:	75 0b                	jne    f01065d8 <__udivdi3+0x38>
f01065cd:	b8 01 00 00 00       	mov    $0x1,%eax
f01065d2:	31 d2                	xor    %edx,%edx
f01065d4:	f7 f1                	div    %ecx
f01065d6:	89 c6                	mov    %eax,%esi
f01065d8:	31 d2                	xor    %edx,%edx
f01065da:	89 e8                	mov    %ebp,%eax
f01065dc:	f7 f6                	div    %esi
f01065de:	89 c5                	mov    %eax,%ebp
f01065e0:	89 f8                	mov    %edi,%eax
f01065e2:	f7 f6                	div    %esi
f01065e4:	89 ea                	mov    %ebp,%edx
f01065e6:	83 c4 0c             	add    $0xc,%esp
f01065e9:	5e                   	pop    %esi
f01065ea:	5f                   	pop    %edi
f01065eb:	5d                   	pop    %ebp
f01065ec:	c3                   	ret    
f01065ed:	8d 76 00             	lea    0x0(%esi),%esi
f01065f0:	39 e8                	cmp    %ebp,%eax
f01065f2:	77 24                	ja     f0106618 <__udivdi3+0x78>
f01065f4:	0f bd e8             	bsr    %eax,%ebp
f01065f7:	83 f5 1f             	xor    $0x1f,%ebp
f01065fa:	75 3c                	jne    f0106638 <__udivdi3+0x98>
f01065fc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106600:	39 34 24             	cmp    %esi,(%esp)
f0106603:	0f 86 9f 00 00 00    	jbe    f01066a8 <__udivdi3+0x108>
f0106609:	39 d0                	cmp    %edx,%eax
f010660b:	0f 82 97 00 00 00    	jb     f01066a8 <__udivdi3+0x108>
f0106611:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106618:	31 d2                	xor    %edx,%edx
f010661a:	31 c0                	xor    %eax,%eax
f010661c:	83 c4 0c             	add    $0xc,%esp
f010661f:	5e                   	pop    %esi
f0106620:	5f                   	pop    %edi
f0106621:	5d                   	pop    %ebp
f0106622:	c3                   	ret    
f0106623:	90                   	nop
f0106624:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106628:	89 f8                	mov    %edi,%eax
f010662a:	f7 f1                	div    %ecx
f010662c:	31 d2                	xor    %edx,%edx
f010662e:	83 c4 0c             	add    $0xc,%esp
f0106631:	5e                   	pop    %esi
f0106632:	5f                   	pop    %edi
f0106633:	5d                   	pop    %ebp
f0106634:	c3                   	ret    
f0106635:	8d 76 00             	lea    0x0(%esi),%esi
f0106638:	89 e9                	mov    %ebp,%ecx
f010663a:	8b 3c 24             	mov    (%esp),%edi
f010663d:	d3 e0                	shl    %cl,%eax
f010663f:	89 c6                	mov    %eax,%esi
f0106641:	b8 20 00 00 00       	mov    $0x20,%eax
f0106646:	29 e8                	sub    %ebp,%eax
f0106648:	89 c1                	mov    %eax,%ecx
f010664a:	d3 ef                	shr    %cl,%edi
f010664c:	89 e9                	mov    %ebp,%ecx
f010664e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0106652:	8b 3c 24             	mov    (%esp),%edi
f0106655:	09 74 24 08          	or     %esi,0x8(%esp)
f0106659:	89 d6                	mov    %edx,%esi
f010665b:	d3 e7                	shl    %cl,%edi
f010665d:	89 c1                	mov    %eax,%ecx
f010665f:	89 3c 24             	mov    %edi,(%esp)
f0106662:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106666:	d3 ee                	shr    %cl,%esi
f0106668:	89 e9                	mov    %ebp,%ecx
f010666a:	d3 e2                	shl    %cl,%edx
f010666c:	89 c1                	mov    %eax,%ecx
f010666e:	d3 ef                	shr    %cl,%edi
f0106670:	09 d7                	or     %edx,%edi
f0106672:	89 f2                	mov    %esi,%edx
f0106674:	89 f8                	mov    %edi,%eax
f0106676:	f7 74 24 08          	divl   0x8(%esp)
f010667a:	89 d6                	mov    %edx,%esi
f010667c:	89 c7                	mov    %eax,%edi
f010667e:	f7 24 24             	mull   (%esp)
f0106681:	39 d6                	cmp    %edx,%esi
f0106683:	89 14 24             	mov    %edx,(%esp)
f0106686:	72 30                	jb     f01066b8 <__udivdi3+0x118>
f0106688:	8b 54 24 04          	mov    0x4(%esp),%edx
f010668c:	89 e9                	mov    %ebp,%ecx
f010668e:	d3 e2                	shl    %cl,%edx
f0106690:	39 c2                	cmp    %eax,%edx
f0106692:	73 05                	jae    f0106699 <__udivdi3+0xf9>
f0106694:	3b 34 24             	cmp    (%esp),%esi
f0106697:	74 1f                	je     f01066b8 <__udivdi3+0x118>
f0106699:	89 f8                	mov    %edi,%eax
f010669b:	31 d2                	xor    %edx,%edx
f010669d:	e9 7a ff ff ff       	jmp    f010661c <__udivdi3+0x7c>
f01066a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01066a8:	31 d2                	xor    %edx,%edx
f01066aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01066af:	e9 68 ff ff ff       	jmp    f010661c <__udivdi3+0x7c>
f01066b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01066b8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01066bb:	31 d2                	xor    %edx,%edx
f01066bd:	83 c4 0c             	add    $0xc,%esp
f01066c0:	5e                   	pop    %esi
f01066c1:	5f                   	pop    %edi
f01066c2:	5d                   	pop    %ebp
f01066c3:	c3                   	ret    
f01066c4:	66 90                	xchg   %ax,%ax
f01066c6:	66 90                	xchg   %ax,%ax
f01066c8:	66 90                	xchg   %ax,%ax
f01066ca:	66 90                	xchg   %ax,%ax
f01066cc:	66 90                	xchg   %ax,%ax
f01066ce:	66 90                	xchg   %ax,%ax

f01066d0 <__umoddi3>:
f01066d0:	55                   	push   %ebp
f01066d1:	57                   	push   %edi
f01066d2:	56                   	push   %esi
f01066d3:	83 ec 14             	sub    $0x14,%esp
f01066d6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01066da:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01066de:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01066e2:	89 c7                	mov    %eax,%edi
f01066e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01066e8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01066ec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01066f0:	89 34 24             	mov    %esi,(%esp)
f01066f3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01066f7:	85 c0                	test   %eax,%eax
f01066f9:	89 c2                	mov    %eax,%edx
f01066fb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01066ff:	75 17                	jne    f0106718 <__umoddi3+0x48>
f0106701:	39 fe                	cmp    %edi,%esi
f0106703:	76 4b                	jbe    f0106750 <__umoddi3+0x80>
f0106705:	89 c8                	mov    %ecx,%eax
f0106707:	89 fa                	mov    %edi,%edx
f0106709:	f7 f6                	div    %esi
f010670b:	89 d0                	mov    %edx,%eax
f010670d:	31 d2                	xor    %edx,%edx
f010670f:	83 c4 14             	add    $0x14,%esp
f0106712:	5e                   	pop    %esi
f0106713:	5f                   	pop    %edi
f0106714:	5d                   	pop    %ebp
f0106715:	c3                   	ret    
f0106716:	66 90                	xchg   %ax,%ax
f0106718:	39 f8                	cmp    %edi,%eax
f010671a:	77 54                	ja     f0106770 <__umoddi3+0xa0>
f010671c:	0f bd e8             	bsr    %eax,%ebp
f010671f:	83 f5 1f             	xor    $0x1f,%ebp
f0106722:	75 5c                	jne    f0106780 <__umoddi3+0xb0>
f0106724:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0106728:	39 3c 24             	cmp    %edi,(%esp)
f010672b:	0f 87 e7 00 00 00    	ja     f0106818 <__umoddi3+0x148>
f0106731:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106735:	29 f1                	sub    %esi,%ecx
f0106737:	19 c7                	sbb    %eax,%edi
f0106739:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010673d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106741:	8b 44 24 08          	mov    0x8(%esp),%eax
f0106745:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0106749:	83 c4 14             	add    $0x14,%esp
f010674c:	5e                   	pop    %esi
f010674d:	5f                   	pop    %edi
f010674e:	5d                   	pop    %ebp
f010674f:	c3                   	ret    
f0106750:	85 f6                	test   %esi,%esi
f0106752:	89 f5                	mov    %esi,%ebp
f0106754:	75 0b                	jne    f0106761 <__umoddi3+0x91>
f0106756:	b8 01 00 00 00       	mov    $0x1,%eax
f010675b:	31 d2                	xor    %edx,%edx
f010675d:	f7 f6                	div    %esi
f010675f:	89 c5                	mov    %eax,%ebp
f0106761:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106765:	31 d2                	xor    %edx,%edx
f0106767:	f7 f5                	div    %ebp
f0106769:	89 c8                	mov    %ecx,%eax
f010676b:	f7 f5                	div    %ebp
f010676d:	eb 9c                	jmp    f010670b <__umoddi3+0x3b>
f010676f:	90                   	nop
f0106770:	89 c8                	mov    %ecx,%eax
f0106772:	89 fa                	mov    %edi,%edx
f0106774:	83 c4 14             	add    $0x14,%esp
f0106777:	5e                   	pop    %esi
f0106778:	5f                   	pop    %edi
f0106779:	5d                   	pop    %ebp
f010677a:	c3                   	ret    
f010677b:	90                   	nop
f010677c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106780:	8b 04 24             	mov    (%esp),%eax
f0106783:	be 20 00 00 00       	mov    $0x20,%esi
f0106788:	89 e9                	mov    %ebp,%ecx
f010678a:	29 ee                	sub    %ebp,%esi
f010678c:	d3 e2                	shl    %cl,%edx
f010678e:	89 f1                	mov    %esi,%ecx
f0106790:	d3 e8                	shr    %cl,%eax
f0106792:	89 e9                	mov    %ebp,%ecx
f0106794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106798:	8b 04 24             	mov    (%esp),%eax
f010679b:	09 54 24 04          	or     %edx,0x4(%esp)
f010679f:	89 fa                	mov    %edi,%edx
f01067a1:	d3 e0                	shl    %cl,%eax
f01067a3:	89 f1                	mov    %esi,%ecx
f01067a5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01067a9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01067ad:	d3 ea                	shr    %cl,%edx
f01067af:	89 e9                	mov    %ebp,%ecx
f01067b1:	d3 e7                	shl    %cl,%edi
f01067b3:	89 f1                	mov    %esi,%ecx
f01067b5:	d3 e8                	shr    %cl,%eax
f01067b7:	89 e9                	mov    %ebp,%ecx
f01067b9:	09 f8                	or     %edi,%eax
f01067bb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01067bf:	f7 74 24 04          	divl   0x4(%esp)
f01067c3:	d3 e7                	shl    %cl,%edi
f01067c5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01067c9:	89 d7                	mov    %edx,%edi
f01067cb:	f7 64 24 08          	mull   0x8(%esp)
f01067cf:	39 d7                	cmp    %edx,%edi
f01067d1:	89 c1                	mov    %eax,%ecx
f01067d3:	89 14 24             	mov    %edx,(%esp)
f01067d6:	72 2c                	jb     f0106804 <__umoddi3+0x134>
f01067d8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01067dc:	72 22                	jb     f0106800 <__umoddi3+0x130>
f01067de:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01067e2:	29 c8                	sub    %ecx,%eax
f01067e4:	19 d7                	sbb    %edx,%edi
f01067e6:	89 e9                	mov    %ebp,%ecx
f01067e8:	89 fa                	mov    %edi,%edx
f01067ea:	d3 e8                	shr    %cl,%eax
f01067ec:	89 f1                	mov    %esi,%ecx
f01067ee:	d3 e2                	shl    %cl,%edx
f01067f0:	89 e9                	mov    %ebp,%ecx
f01067f2:	d3 ef                	shr    %cl,%edi
f01067f4:	09 d0                	or     %edx,%eax
f01067f6:	89 fa                	mov    %edi,%edx
f01067f8:	83 c4 14             	add    $0x14,%esp
f01067fb:	5e                   	pop    %esi
f01067fc:	5f                   	pop    %edi
f01067fd:	5d                   	pop    %ebp
f01067fe:	c3                   	ret    
f01067ff:	90                   	nop
f0106800:	39 d7                	cmp    %edx,%edi
f0106802:	75 da                	jne    f01067de <__umoddi3+0x10e>
f0106804:	8b 14 24             	mov    (%esp),%edx
f0106807:	89 c1                	mov    %eax,%ecx
f0106809:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010680d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0106811:	eb cb                	jmp    f01067de <__umoddi3+0x10e>
f0106813:	90                   	nop
f0106814:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106818:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010681c:	0f 82 0f ff ff ff    	jb     f0106731 <__umoddi3+0x61>
f0106822:	e9 1a ff ff ff       	jmp    f0106741 <__umoddi3+0x71>
