all: multi 

multi: multi.o
	gcc -m32 -o multi multi.o -lc

multi.o: multi.s
	nasm -g -F dwarf -felf32 -o multi.o multi.s

clean:
	rm -f  *.o multi
