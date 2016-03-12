#!/bin/sh
#DdShurick GPL3 06.03.16
[ $1 ] || exit

chk_on () {
	/bin/grep on$ /etc/network-wizard/network/interfaces/$(/bin/cat /sys/class/net/$1/address|/usr/bin/tr [a-z] [A-Z]).conf || exit
}

case $1 in
lo)
/sbin/ifconfig lo  127.0.0.1 up
/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 lo
;;
usb?)
chk_on $1
/bin/sleep 10
/usr/sbin/dhcpcd $1
/usr/bin/curl http://192.168.0.1/goform/goform_set_cmd_process?goformId=CONNECT_NETWORK
;;
cdc-wdm?)
/bin/sleep 10
/usr/sbin/modem-stats -c AT^NDISCONN=1,1 /dev/$1
;;
wwan?)
chk_on $1
/bin/sleep 1
/usr/sbin/dhcpcd $1
;;
*)
chk_on $1
if [ -h /sys/class/net/$1/phy80211 ]; then
exec /usr/sbin/wlan.sh $1
else
exec /usr/sbin/lan.sh $1
fi
;;
esac
