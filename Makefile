all: bison
	@echo Compiling pain
	@gcc -Wall -Wextra -std=gnu99 -pedantic -O3 -march=native y.tab.c lex.yy.c -lfl -lm -o pain -Wl,--as-needed -Wl,-O2
flex:
	@echo Flexing
	@flex lexer.l
bison: flex
	@echo Bisoning
	@bison -ydt parser.y
clean:
	@echo Cleaning files
	@rm -f lex.yy.c y.tab.c y.tab.h pain
