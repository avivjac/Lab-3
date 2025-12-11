NASM = nasm
CC = gcc
LD = ld
CFLAGS = -m32 -Wall -ansi -c -nostdlib -fno-stack-protector
LDFLAGS = -m elf_i386
ASMFLAGS = -f elf32

all: task2

task2: start.o main.o util.o
	$(LD) $(LDFLAGS) start.o main.o util.o -o task2

start.o: start.s
	$(NASM) $(ASMFLAGS) start.s -o start.o

util.o: Util.c
	$(CC) $(CFLAGS) Util.c -o util.o

main.o: main.c
	$(CC) $(CFLAGS) main.c -o main.o

clean:
	rm -f *.o task2
