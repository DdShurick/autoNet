
BINDIR	= /usr/bin
MANDIR	= /usr/man

CC	= gcc
CFLAGS	= -O2  

INSTALL	= install

all:	modem-stats

clean:
	rm modem-stats *.o

modem-stats:	modem-stats.c

install:	modem-stats
	$(INSTALL) -s -m 755 modem-stats $(BINDIR)/modem-stats

install.man:
	$(INSTALL) -m 644 modem-stats.1 $(MANDIR)/man1/modem-stats.1

