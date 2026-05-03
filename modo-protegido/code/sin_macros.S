.code16
.global _start

_start:
    # ---------------------------------------------------------
    # 1. BEGIN: Configuración inicial (Modo Real)
    # ---------------------------------------------------------
    cli                         # Deshabilitar interrupciones
    xor %ax, %ax                # Limpiar registros de segmento
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $0x7c00, %sp            # Configurar el stack debajo del código

    # ---------------------------------------------------------
    # 2. CLEAR: Limpiar la pantalla (Usando interrupción BIOS)
    # ---------------------------------------------------------
    mov $0x0003, %ax            # Función 0x00, modo video 0x03 (80x25 texto)
    int $0x10

    # ---------------------------------------------------------
    # 3. PROTECTED_MODE: El salto al modo de 32 bits
    # ---------------------------------------------------------
    lgdt gdt_descriptor         # Cargar la tabla de descriptores

    mov %cr0, %eax
    or $0x1, %eax               # Activar el bit PE (Protection Enable)
    mov %eax, %cr0

    # Far jump para limpiar el pipeline de instrucciones de 16 bits
    # 0x08 es el selector del segmento de código en nuestra GDT
    ljmp $0x08, $start_protected

.code32
start_protected:
    # Actualizar registros de datos con el selector 0x10 (Data Segment)
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    # ---------------------------------------------------------
    # 4. VGA_PRINT_STRING: Escribir directo en memoria de video
    # ---------------------------------------------------------
    # En modo protegido, la BIOS no existe. Escribimos en 0xB8000.
    mov $message, %esi
    mov $0xb8000, %edi          # Dirección base de la memoria de video VGA
    mov $0x0f, %ah              # Atributo: Fondo negro, letras blancas

print_loop:
    lodsb                       # Carga el siguiente byte de ESI en AL
    test %al, %al               # ¿Es el final de la cadena (\0)?
    jz done
    mov %al, (%edi)             # Escribe el carácter
    mov %ah, 1(%edi)            # Escribe el atributo (color)
    add $2, %edi                # Siguiente posición en pantalla (2 bytes por char)
    jmp print_loop

done:
    hlt                         # Detener el procesador
    jmp .

# ---------------------------------------------------------
# 5. GDT (Global Descriptor Table)
# ---------------------------------------------------------
.align 4
gdt_start:
    .quad 0x0000000000000000    # Descriptor Nulo

gdt_code:                       # Selector 0x08
    .word 0xffff, 0x0000, 0x9a00, 0x00cf

gdt_data:                       # Selector 0x10
    .word 0xffff, 0x0000, 0x9200, 0x00cf
gdt_end:

gdt_descriptor:
    .word gdt_end - gdt_start - 1
    .long gdt_start

message:
    .asciz "hello AC/sDC from protected mode"

# Relleno hasta 510 bytes y firma de arranque
.org 510
.word 0xaa55
