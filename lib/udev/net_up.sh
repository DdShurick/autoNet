#!/bin/sh
#DdShurick GPL3 29.12.14
[ $1 ] || exit
case $1 in
lo)
/sbin/ifconfig lo  127.0.0.1 up
/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 lo
;;
usb?)
/bin/sleep 10
/usr/sbin/dhcpcd $1
/usr/bin/curl http://192.168.0.1/goform/goform_set_cmd_process?goformId=CONNECT_NETWORK
;;
cdc-wdm?)
/bin/sleep 10
/usr/sbin/modem-stats -c AT^NDISCONN=1,1 /dev/$1
;;
wwan?)
/bin/sleep 1
/usr/sbin/dhcpcd $1
;;
*) 
if [ -h /sys/class/net/$1/phy80211 ]; then
exec /usr/sbin/wlan.sh $1
else
exec /usr/sbin/lan.sh $1
fi
;;
esac
