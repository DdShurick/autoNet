CC=gcc
FLAGS := $(shell pkg-config --cflags gtk+-2.0)
LIBS := $(shell pkg-config --libs gtk+-2.0)
INSTALL = /usr/bin/install
STRIP = /usr/bin/strip
prefix = /usr
bindir = ${prefix}/bin
sbindir = ${prefix}/sbin
datarootdir = ${prefix}/share
libdir = /lib
sysconfdir = /etc

all:
	$(CC) -o up3Gmodem src/up3Gmodem.c $(FLAGS) $(LIBS)
	$(CC) -o ussd src/ussd.c $(FLAGS) $(LIBS)
	$(CC) -o check3Gtty src/check3Gtty.c

install:
	$(INSTALL) -D -m 755 up3Gmodem $(DESTDIR)$(bindir)/up3Gmodem
	$(STRIP) $(DESTDIR)$(bindir)/up3Gmodem
	$(INSTALL) -D -m 755 ussd $(DESTDIR)$(bindir)/ussd
	$(STRIP) $(DESTDIR)$(bindir)/ussd
	$(INSTALL) -D -m 755 check3Gtty $(DESTDIR)/lib/udev/check3Gtty
	$(STRIP) $(DESTDIR)$(libdir)/udev/check3Gtty
	
	$(INSTALL) -D -m 755 scripts/connect $(DESTDIR)$(bindir)/connect
	$(INSTALL) -D -m 755 scripts/pppoeconf $(DESTDIR)$(bindir)/pppoeconf
	$(INSTALL) -D -m 755 scripts/tunstatic $(DESTDIR)$(bindir)/tunstatic
	$(INSTALL) -D -m 755 scripts/wifi $(DESTDIR)$(bindir)/wifi
	$(INSTALL) -D -m 755 scripts/upNet $(DESTDIR)/lib/udev/upNet
	$(INSTALL) -D -m 755 scripts/lan.sh $(DESTDIR)$(sbindir)/lan.sh
	$(INSTALL) -D -m 755 scripts/wlan.sh $(DESTDIR)$(sbindir)/wlan.sh
	$(INSTALL) -D -m 755 scripts/libupNet $(DESTDIR)$(prefix)$(libdir)/upNet/libupNet
	$(INSTALL) -D -m 644 rules.d/99-net_up.rules $(DESTDIR)/lib/udev/rules.d/99-net_up.rules
	$(INSTALL) -d $(DESTDIR)$(datarootdir)/
	cp -a applications/ $(DESTDIR)$(datarootdir)/
	cp -a pixmaps/ $(DESTDIR)$(datarootdir)/
	cp -a etc/ $(DESTDIR)/
	

clean:
	rm up3Gmodem ussd check3Gtty
