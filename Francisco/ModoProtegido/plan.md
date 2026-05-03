# Plan: Pasar a modo protegido (sin macros)

## Objetivo

Crear un programa assembler en sintaxis AT&T (GAS) que arranque desde el MBR en modo real y transicione manualmente a modo protegido siguiendo el proceso de la presentación, **sin usar macros**.

## Estructura de archivos

Carpeta nueva: `TP3/ModoProtegido/` (crear `src/` adentro para no mezclar con el PDF).

- `main.S` — código fuente assembler.
- `link.ld` — script del linker (mismo patrón que HelloWorld: `. = 0x7c00`, firma `0xAA55` en 0x1FE).
- `Makefile` — targets `all`, `clean` y `main.img` (sin qemu/gdb, igual que en HelloWorld después del último cambio).

## Diseño del código (main.S)

Pasos según las diapositivas "Modo protegido — Proceso simplificado":

1. **Sección 16 bits (`.code16`)** en `0x7c00`:
   - `cli` — deshabilitar interrupciones.
   - `lgdt gdt_descriptor` — cargar GDT.
   - Set CR0.PE = 1: `mov %cr0,%eax` / `or $0x1,%eax` / `mov %eax,%cr0`.
   - `ljmp $CODE_SEG, $protected_mode` — far jump al segmento de código de 32 bits para vaciar el pipeline y cargar CS.

2. **Sección 32 bits (`.code32`)** etiqueta `protected_mode`:
   - Cargar selectores de datos en DS, ES, FS, GS, SS con `$DATA_SEG` (forzar reload del descriptor cache, según diapo).
   - Setear ESP a un valor seguro (ej. 0x9000).
   - Escribir un carácter en la memoria de video VGA en `0xb8000` para verificar visualmente que llegamos a modo protegido (ej. la letra 'P' en blanco sobre negro).
   - `hlt` dentro de un loop infinito.

3. **GDT manual (sin macros)** — tres descriptores de 8 bytes cada uno, escritos byte a byte / qword a qword con `.quad` y constantes hex explícitas:
   - **Null descriptor** (8 bytes en cero): `.quad 0`.
   - **Code segment** (selector 0x08): base 0, límite 0xFFFFF, granularidad 4K, 32 bits, ejecutable, readable, ring 0, presente. → `.quad 0x00CF9A000000FFFF`.
   - **Data segment** (selector 0x10): mismas características pero tipo data, writable. → `.quad 0x00CF92000000FFFF`.

4. **GDT descriptor** (estructura para `lgdt`):
   - `.word` con `gdt_end - gdt_start - 1` (límite).
   - `.long` con dirección de `gdt_start`.

5. **Constantes** (sin `.macro`, solo `.set` o `.equ`, que son directivas estándar — no macros):
   - `.set CODE_SEG, 0x08`
   - `.set DATA_SEG, 0x10`

## Decisiones a confirmar

1. **¿`.set`/`.equ` cuenta como macro?** Mi lectura: NO, son directivas de constantes (equivalentes a `#define` simple), no macros con cuerpo (`.macro`/`.endm`). Pero si querés literalmente cero directivas auxiliares, reemplazo `$CODE_SEG` por `$0x08` directo.
2. **¿Qué hace el código en modo protegido?** Propongo escribir 'P' en VGA y `hlt` para tener evidencia visible. Alternativa: solo `hlt` sin output.
3. **¿Carpeta?** Propongo `TP3/ModoProtegido/src/` para que el PDF y el código convivan en `ModoProtegido/`. Alternativa: `TP3/ModoProtegido2/` o pisar.

## Tamaño estimado

~60 líneas de assembler, entra cómodo en los 510 bytes del MBR.

## Validación pendiente de tu parte

- ¿Confirmás `.set` como aceptable o lo querés todo con literales?
- ¿Querés output VGA o solo `hlt`?
- ¿Carpeta `src/` adentro de `ModoProtegido/` está bien?
