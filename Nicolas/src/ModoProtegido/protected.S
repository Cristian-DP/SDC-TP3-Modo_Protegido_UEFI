# protected.S — Transición a modo protegido sin macros

.code16
.global _start

_start:
    cli                          # Deshabilitar interrupciones

    # Cargar la GDT
    lgdt gdt_descriptor

    # Activar modo protegido: setear bit PE (bit 0) en CR0
    mov  %cr0, %eax
    or   $0x1, %eax
    mov  %eax, %cr0

    # Far jump: vacía el pipeline y salta a código de 32 bits
    #    0x08 = selector del segmento de código en la GDT
    ljmp $0x08, $protected_mode

.code32
protected_mode:
    # Cargar registros de segmento con selector de datos (0x10)
    mov  $0x10, %ax
    mov  %ax, %ds
    mov  %ax, %es
    mov  %ax, %fs
    mov  %ax, %gs
    mov  %ax, %ss

    # Escribir 'P' en memoria de video VGA (0xB8000)
    movl $0x0F500000, 0xB8000
    movl $0xDEADBEEF, 0x00100000
    hlt

# ─────────────────────────────────────────────────
# GDT — Global Descriptor Table
# ─────────────────────────────────────────────────
.align 8
gdt_start:

# Descriptor 0: NULL (obligatorio)
gdt_null:
    .long 0x00000000
    .long 0x00000000

# Descriptor 1: Segmento de CÓDIGO (selector 0x08)
gdt_code:
    .word 0xFFFF
    .word 0x0000
    .byte 0x00
    .byte 0x9A
    .byte 0xCF
    .byte 0x00

# Descriptor 2: Segmento de DATOS (selector 0x10)
gdt_data:
    .word 0xFFFF
    .word 0x0000
    .byte 0x10
    .byte 0x90
    .byte 0xCF
    .byte 0x00

gdt_end:

# Descriptor de la GDT
gdt_descriptor:
    .word gdt_end - gdt_start - 1
    .long gdt_start

# Relleno y firma MBR
.fill 510-(.-_start), 1, 0
.word 0xAA55
