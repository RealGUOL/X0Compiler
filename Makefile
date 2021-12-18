all: prog clean

prog:   finalcompiler.l finalcompiler.y
	flex -L finalcompiler.l
	bison -d -l finalcompiler.y

clean:  
	rm lex.yy.c finalcompiler.tab.c finalcompiler.tab.h
