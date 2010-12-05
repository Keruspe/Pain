all: bison
	@echo Compiling pascal
	@gcc -Wall -Wextra -std=gnu99 -pedantic -O3 -march=native pascal.tab.c -lfl -lm -o pascal -Wl,--as-needed -Wl,-O2
flex:
	@echo Flexing
	@flex pascal.lex
bison: flex
	@echo Bisoning
	@bison pascal.y
clean:
	@echo Cleaning files
	@rm -f lex.yy.c pascal.tab.c pascal
