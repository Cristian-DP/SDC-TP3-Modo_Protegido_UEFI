.PHONY: all clean

all: clean main.img

main.o: main.S
	as -g -o main.o main.S

main.img: main.o link.ld
	ld --oformat binary -o main.img -T link.ld main.o

clean:
	rm -f main.o main.img
