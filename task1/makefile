NASM = nasm
CC = gcc
LD = ld
CFLAGS = -m32 -Wall -ansi -c -nostdlib -fno-stack-protector
LDFLAGS = -m elf_i386
ASMFLAGS = -f elf32

all: task1

task1: start.o main.o util.o
	$(LD) $(LDFLAGS) start.o main.o util.o -o task1

start.o: start.s
	$(NASM) $(ASMFLAGS) start.s -o start.o

util.o: Util.c
	$(CC) $(CFLAGS) Util.c -o util.o

main.o: main.s
	$(NASM) $(ASMFLAGS) main.s -o main.o

clean:
	rm -f *.o task1
