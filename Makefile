sources = parser.c scanner.c
objects = $(sources:.c=.o)
bin     = pain

CC      = gcc
RM      = rm -f
LEX     = flex
YACC    = bison -y

D_CFLAGS  = -g -ggdb3 -Wall -Wextra -pedantic -std=gnu99 -O3 -march=native
D_LDFLAGS = -Wl,-O3 -Wl,--as-needed
D_YFLAGS  = -d

CFLAGS  := $(D_CFLAGS) $(CFLAGS)
LDFLAGS := $(D_LDFLAGS) $(LDFLAGS)
YFLAGS  := $(D_YFLAGS) $(YFLAGS)


all: $(bin)

$(bin): $(objects)
	$(LINK.c) $^ $(LOADLIBES) $(LDLIBS) -o $@ -lm -lfl

parse.o: parser.y

scan.o: scanner.l parser.c y.tab.h

clean:
	$(RM) $(sources) $(objects) $(bin) y.tab.h
