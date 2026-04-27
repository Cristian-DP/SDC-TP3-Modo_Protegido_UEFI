# Tell the assembler to generate 16-bit real-mode code.
# When the BIOS hands control to our boot sector, the CPU is in 16-bit
# real mode, so every instruction here must be encoded for that mode.
.code16

    # Load the address of our string "hello world" into SI.
    # SI is the "source index" register: the lodsb instruction below
    # will read bytes from the address that SI points to.
    mov $msg, %si

    # Set AH = 0x0E. This selects BIOS function "teletype output".
    # When we later call int 0x10, the BIOS looks at AH to know which
    # video function we want; 0x0E means "print the character in AL".
    mov $0x0e, %ah

loop:
    # lodsb = "load string byte":
    #   1) Read the byte at DS:SI into AL.
    #   2) Increment SI by 1 so the next call reads the next character.
    lodsb

    # OR AL with itself. The result is the same value, but this updates
    # the CPU flags. We use it as a cheap way to test "is AL zero?".
    # A zero byte marks the end of our .asciz string.
    or %al, %al

    # If the zero flag is set (AL was 0), jump to the halt label:
    # we have reached the end of the string, so stop printing.
    jz halt

    # Call BIOS interrupt 0x10 (video services). Combined with AH=0x0E
    # set above, this prints the character currently in AL on screen.
    int $0x10

    # Go back and process the next character.
    jmp loop

halt:
    # hlt stops the CPU until the next interrupt. With nothing else
    # going on, this effectively freezes the machine after printing.
    hlt

msg:
    # .asciz writes the string into the binary AND appends a 0 byte
    # at the end. That trailing zero is what the loop above checks for
    # to know when to stop.
    .asciz "hello world"
