# 1. Ensamblar
as --32 -o kernel.o sin_macros_2.S

# 2. Enlazar (Linkear)
ld -m elf_i386 -Ttext 0x7c00 -N -e _start -o kernel.elf kernel.o

# 3. Crear imagen binaria
objcopy -O binary kernel.elf kernel.img

# 4. Probar en QEMU
#qemu-system-i386 -drive format=raw,file=kernel.img
qemu-system-i386 -s -S -drive format=raw,file=kernel.img