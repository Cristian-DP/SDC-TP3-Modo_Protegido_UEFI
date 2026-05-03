.PHONY: all run debug gdb clean

all: clean main.img

main.o: main.S
	as -g -o main.o main.S

main.img: main.o link.ld
	ld --oformat binary -o main.img -T link.ld main.o

run: main.img
	qemu-system-x86_64 -hda main.img

debug: main.img
	qemu-system-i386 -hda main.img -s -S -monitor stdio

gdb:
	gdb -ex "target remote localhost:1234" \
	    -ex "set architecture i8086" 

clean:
	rm -f main.o main.img
