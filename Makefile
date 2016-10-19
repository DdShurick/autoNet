CC=gcc
FLAGS := $(shell pkg-config --cflags gtk+-2.0)
LIBS := $(shell pkg-config --libs gtk+-2.0)
SOURCES= up3Gmodem.c
up3Gm : $(SOURCES)
	$(CC) -o $@ $(SOURCES) $(FLAGS) $(LIBS)
