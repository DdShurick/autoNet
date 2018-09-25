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
	
	$(INSTALL) -D -m 644 pixmaps/connect-red.xpm  $(DESTDIR)$(datarootdir)/pixmaps/connect-red.xpm
	$(INSTALL) -D -m 644 pixmaps/connect.svg  $(DESTDIR)$(datarootdir)/pixmaps/connect.svg
	$(INSTALL) -D -m 644 pixmaps/connect_no.svg  $(DESTDIR)$(datarootdir)/pixmaps/connect_no.svg
	$(INSTALL) -D -m 644 pixmaps/network_err.svg  $(DESTDIR)$(datarootdir)/pixmaps/network_err.svg
	$(INSTALL) -D -m 644 pixmaps/network_lan.svg  $(DESTDIR)$(datarootdir)/pixmaps/network_lan.svg
	$(INSTALL) -D -m 644 pixmaps/network_off.svg  $(DESTDIR)$(datarootdir)/pixmaps/network_off.svg
	$(INSTALL) -D -m 644 pixmaps/network_on.svg  $(DESTDIR)$(datarootdir)/pixmaps/network_on.svg
	$(INSTALL) -D -m 644 pixmaps/search.svg  $(DESTDIR)$(datarootdir)/pixmaps/search.svg
	$(INSTALL) -D -m 644 pixmaps/usb_modem_4g.svg  $(DESTDIR)$(datarootdir)/pixmaps/usb_modem_4g.svg
	$(INSTALL) -D -m 644 pixmaps/usb_modem_off.svg  $(DESTDIR)$(datarootdir)/pixmaps/usb_modem_off.svg
	$(INSTALL) -D -m 644 pixmaps/usb_modem_on.svg  $(DESTDIR)$(datarootdir)/pixmaps/usb_modem_on.svg
	$(INSTALL) -D -m 644 pixmaps/wireless_err.svg  $(DESTDIR)$(datarootdir)/pixmaps/wireless_err.svg
	$(INSTALL) -D -m 644 pixmaps/wireless_lan.svg  $(DESTDIR)$(datarootdir)/pixmaps/wireless_lan.svg
	$(INSTALL) -D -m 644 pixmaps/wireless_off.svg  $(DESTDIR)$(datarootdir)/pixmaps/wireless_off.svg
	$(INSTALL) -D -m 644 pixmaps/wireless_on.svg  $(DESTDIR)$(datarootdir)/pixmaps/wireless_on.svg
	$(INSTALL) -D -m 755 scripts/connect $(DESTDIR)$(bindir)/connect
	$(INSTALL) -D -m 755 scripts/pppoeconf $(DESTDIR)$(bindir)/pppoeconf
	$(INSTALL) -D -m 755 scripts/tunstatic $(DESTDIR)$(bindir)/tunstatic
	$(INSTALL) -D -m 755 scripts/wifi $(DESTDIR)$(bindir)/wifi
	$(INSTALL) -D -m 755 scripts/upNet $(DESTDIR)/lib/udev/upNet
	$(INSTALL) -D -m 755 scripts/lan.sh $(DESTDIR)$(sbindir)/lan.sh
	$(INSTALL) -D -m 755 scripts/wlan.sh $(DESTDIR)$(sbindir)/wlan.sh
	$(INSTALL) -D -m 755 scripts/libupNet $(DESTDIR)$(prefix)$(libdir)/upNet/libupNet
	$(INSTALL) -D -m 644 rules.d/99-net_up.rules $(DESTDIR)/lib/udev/rules.d/99-net_up.rules
	$(INSTALL) -D -m 644 applications/connect.desktop $(DESTDIR)$(datarootdir)/applications/connect.desktop
	$(INSTALL) -D -m 644 applications/pppoe.desktop $(DESTDIR)$(datarootdir)/applications/pppoe.desktop
	$(INSTALL) -D -m 644 applications/wifi.desktop $(DESTDIR)$(datarootdir)/applications/wifi.desktop

clean:
	rm up3Gmodem ussd check3Gttywifi.desktop
