/*
 * Linker script for a tiny x86 MBR boot sector.
 *
 * The linker normally decides where code and data live in memory.
 * For a boot sector we need full control over those addresses, so
 * we describe the layout by hand here and pass this file to ld with
 * the -T flag.
 */
SECTIONS
{
    /*
     * The BIOS always loads the first 512 bytes of the boot disk
     * into physical memory at address 0x7C00 and then jumps there.
     * We must tell the linker to compute all addresses as if the
     * code were going to run at 0x7C00, otherwise labels like `msg`
     * would point to the wrong place at runtime.
     */
    . = 0x7c00;

    /* Define the .text output section (code + read-only data). */
    .text :
    {
        /* Mark the very first byte of our code as `__start`.
         * This is just a convenient label; it is also where the
         * BIOS will start executing. */
        __start = .;

        /* Pull in the .text section from every input object file
         * (in our case just main.o). This is the actual program. */
        *(.text)

        /*
         * The BIOS only treats a sector as bootable if its last
         * two bytes are 0x55 0xAA (the "boot signature"), located
         * at offset 510-511 inside the 512-byte sector.
         *
         * 0x1FE = 510 in decimal. We move the location counter
         * forward to that offset (the gap is filled with zeros)
         * and then emit the magic 16-bit value 0xAA55.
         *
         * SHORT writes 2 bytes in little-endian order, so on disk
         * we get 0x55 followed by 0xAA — exactly what the BIOS
         * expects.
         */
        . = 0x1FE;
        SHORT(0xAA55)
    }
}
