/*
 * Paso de modo real a modo protegido (sin macros).
 *
 * El BIOS carga estos 512 bytes en 0x7c00 y arranca en modo real
 * de 16 bits. Acá hacemos el switch manual a modo protegido de 32 bits.
 *
 * GDT con DOS DESCRIPTORES EN ESPACIOS DE MEMORIA DIFERENCIADOS:
 *  - Code: base=0,         límite=64 KiB   -> cubre el sector de boot.
 *  - Data: base=0xB8000,   límite=4 KiB    -> apunta directo a VGA.
 * Las dos regiones no se solapan: code vive en [0, 0xFFFF] y data en
 * [0xB8000, 0xB8FFF].
 */

/* Selectores de la GDT: el offset (en bytes) del descriptor dentro de la tabla.
 * Code segment es el segundo descriptor -> offset 8.
 * Data segment es el tercero            -> offset 16. */
.set CODE_SEG, 0x08
.set DATA_SEG, 0x10

/* ---------------- Código de 16 bits (modo real) ---------------- */
.code16
.global _start

_start:
	/* Apagamos las interrupciones: la IDT del BIOS no sirve en modo
	 * protegido, así que cualquier IRQ ahora colgaría la CPU. */
	cli

	/* Le decimos a la CPU dónde está nuestra GDT (dirección + tamaño). */
	lgdt gdt_descriptor

	/* Encendemos el bit PE (Protection Enable, bit 0) de CR0.
	 * No se puede escribir CR0 directamente con un inmediato:
	 * primero lo leemos a EAX, lo modificamos, y lo volvemos a escribir. */
	mov %cr0, %eax
	or  $0x1, %eax
	mov %eax, %cr0

	/* Far jump al segmento de código de 32 bits.
	 * Sirve para dos cosas:
	 *  1. Vacía el pipeline (que tenía instrucciones decodificadas como 16 bits).
	 *  2. Carga CS con el selector CODE_SEG, activando el descriptor de la GDT. */
	ljmp $CODE_SEG, $protected_mode

/* ---------------- Código de 32 bits (modo protegido) ---------------- */
.code32
protected_mode:
	/* CS ya quedó cargado por el ljmp. Ahora hay que recargar el resto
	 * de los registros de segmento con el selector de datos para que
	 * apunten al descriptor correcto en la GDT.
	 *
	 * En modo real los registros de segmento se usaban como direcciones
	 * base que la CPU multiplicaba por 16 (dir_física = segmento*16 + offset).
	 * En modo protegido cambia totalmente: ahora son SELECTORES, o sea un
	 * índice a un descriptor de la GDT que define base, límite y permisos.
	 *
	 * Acá DATA_SEG apunta directo a la memoria de video (base=0xB8000),
	 * así que cualquier acceso a través de DS/ES/... cae en VGA. */
	mov $DATA_SEG, %ax    /* cargo 0x10 en AX (no se puede mover un inmediato directo a un segment register) */
	mov %ax, %ds          /* DS ahora apunta al descriptor de datos (VGA) */
	mov %ax, %es          /* idem ES */
	mov %ax, %fs          /* idem FS */
	mov %ax, %gs          /* idem GS */
	/* OJO: SS no se carga a propósito.
	 * Cargar SS exige que el descriptor sea writable (la CPU chequea ese
	 * bit explícitamente en "mov %ax, %ss"). Si después se cambia el
	 * descriptor de datos a read-only para forzar un #GP en el write a VGA,
	 * una línea "mov %ax, %ss" acá faltaría ANTES, escondiendo la falla
	 * que queremos observar en (%edi). Como no hacemos push/pop, dejamos
	 * SS en lo que quedó del modo real. */

	/* Imprime el string en VGA. Como los descriptores ahora viven en
	 * espacios distintos, hay que ser explícito con qué segmento se usa
	 * para leer y para escribir:
	 *   - LECTURA del string -> SEGMENTO DE CÓDIGO. El string vive en .text
	 *     (linker lo puso a partir de 0x7c00), o sea dentro del code segment.
	 *     Se accede con override "%cs:" en el mov.
	 *   - ESCRITURA a VGA   -> SEGMENTO DE DATOS. Los mov sin override usan
	 *     DS por default; como DS tiene base=0xB8000, escribir en (%edi)
	 *     con EDI=0 cae directo en la primera celda de VGA.
	 * AH = atributo (0x0C = rojo brillante sobre negro). */
	mov $message, %esi    /* dirección lineal del string (~0x7c00 + offset) */
	mov $0, %edi          /* offset 0 dentro de DS = dirección lineal 0xB8000 */
	mov $0x0C, %ah

print_loop:
	mov %cs:(%esi), %al   /* CS:(ESI)   — lee el char desde el segmento de código */
	inc %esi
	test %al, %al         /* ¿llegamos al '\0' final? */
	jz halt
	mov %al, (%edi)       /* DS:(EDI)   — escribe el char en el segmento de datos */
	mov %ah, 1(%edi)      /* DS:(EDI+1) — escribe el atributo en el segmento de datos */
	add $2, %edi
	jmp print_loop

message:
	.asciz "Sistemas de computacion"

halt:
	/* Loop infinito con hlt: la CPU se duerme hasta una interrupción,
	 * pero como están deshabilitadas (cli) se queda quieta para siempre. */
	hlt
	jmp halt

/* ---------------- Global Descriptor Table ---------------- */
/* Cada entrada son 8 bytes. Los campos (base, límite, flags) están
 * codificados a mano en hexadecimal en lugar de armarlos con macros.
 * Los dos descriptores apuntan a regiones físicas DISTINTAS:
 * code en [0, 0xFFFF] y data en [0xB8000, 0xB8FFF]. */
gdt_start:
	/* Descriptor null: obligatorio como primera entrada de la GDT. */
	.quad 0x0000000000000000

	/* Code segment: base=0x00000000, límite=0xFFFF (64 KiB, sin granularidad),
	 * 32 bits, ejecutable, readable, ring 0, presente.
	 * | Base 24:31 | Flags+Limit 16:19 | Access | Base 16:23 | Base 0:15 | Limit 0:15 |
	 * |    0x00    |       0x40        |  0x9A  |    0x00    |   0x0000  |   0xFFFF   | */
	.quad 0x00409A000000FFFF

	/* Data segment: base=0x000B8000, límite=0x0FFF (4 KiB, sin granularidad),
	 * 32 bits, read/write, ring 0, presente. Apunta directo a VGA.
	 * | Base 24:31 | Flags+Limit 16:19 | Access | Base 16:23 | Base 0:15 | Limit 0:15 |
	 * |    0x00    |       0x40        |  0x92  |    0x0B    |   0x8000  |   0x0FFF   | */
	.quad 0x0040900B80000FFF
gdt_end:

/* GDT descriptor: lo que recibe lgdt. 6 bytes en total:
 *  - 2 bytes: límite (tamaño de la GDT - 1)
 *  - 4 bytes: dirección base de la GDT */
gdt_descriptor:
	.word gdt_end - gdt_start - 1
	.long gdt_start
