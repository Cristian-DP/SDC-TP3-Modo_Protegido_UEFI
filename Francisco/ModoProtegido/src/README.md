# Modo Protegido — código fuente

Bootloader que arranca en modo real (16 bits) y hace el switch manual a modo protegido (32 bits) sin macros, e imprime `"Sistemas de computacion"` en rojo en la memoria de video VGA.

## Archivos

| Archivo | Descripción |
|---|---|
| `main.S` | Código assembler (sintaxis AT&T / GAS). Contiene la rutina de switch a modo protegido y la GDT. |
| `link.ld` | Script del linker. Coloca `.text` en `0x7c00` y agrega la firma MBR (`0xAA55`) en el byte 510. |
| `Makefile` | Targets para compilar, ejecutar y depurar. |
| `main.img` | Imagen booteable de 512 bytes (generada). |

## Targets del Makefile

### `make` (o `make all`)

Limpia y reconstruye `main.img` desde cero:

1. `as -g -o main.o main.S` — ensambla con símbolos de debug.
2. `ld --oformat binary -o main.img -T link.ld main.o` — linkea aplicando `link.ld`. La opción `--oformat binary` produce un binario plano (sin headers ELF), apto para grabarse directo como sector de boot.

### `make run`

Ejecuta la imagen en QEMU sin opciones de debug:

```bash
qemu-system-x86_64 -hda main.img
```

Si todo funciona, en la esquina superior izquierda de la ventana de QEMU aparece `Sistemas de computacion` en rojo brillante.

### `make debug`

Arranca QEMU **pausado** con servidor GDB activo:

```bash
qemu-system-i386 -hda main.img -s -S -monitor stdio
```

- `-s`: abre el servidor GDB en `localhost:1234` (atajo de `-gdb tcp::1234`).
- `-S`: deja la CPU detenida antes de ejecutar la primera instrucción.
- `-monitor stdio`: redirige el monitor de QEMU a la terminal (útil para ver mensajes como `CPU Reset` ante un triple fault).

La VM queda esperando una conexión de GDB.

### `make gdb`

En **otra terminal**, conecta GDB al servidor que abrió `make debug` y deja un breakpoint listo en el punto de entrada del MBR:

```bash
gdb -ex "target remote localhost:1234" \
    -ex "set architecture i8086" \
    -ex "break *0x7c00" \
    -ex "continue"
```

- `target remote localhost:1234` — se conecta al gdbserver de QEMU.
- `set architecture i8086` — GDB interpreta las instrucciones como 16 bits (modo real).
- `break *0x7c00` — breakpoint en la dirección donde el BIOS entrega el control al MBR.
- `continue` — corre hasta ese breakpoint.

GDB devuelve el prompt `(gdb)` justo en la primera instrucción del programa. A partir de ahí se puede usar:

- `stepi` — ejecuta una instrucción.
- `info registers` — muestra el estado de los registros.
- `break *<dir>` — pone breakpoints adicionales (por ejemplo, en `protected_mode` después del `ljmp`).
- Después del `ljmp`, ejecutar `set architecture i386` para que GDB desensamble como 32 bits.

### `make clean`

Borra los artefactos generados (`main.o`, `main.img`).

## Flujo típico de depuración

```bash
# Terminal 1
make debug

# Terminal 2
make gdb
```

Desde el prompt de GDB:

```gdb
(gdb) stepi                     # avanza una instrucción
(gdb) break *0x7c15             # protected_mode (verificar dirección con objdump -d main.o)
(gdb) continue
(gdb) set architecture i386     # ya estamos en modo protegido, recargo arch
(gdb) stepi
```

Para terminar la sesión: cerrar la ventana de QEMU y `quit` en GDB.
