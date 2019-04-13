#!/bin/sh
#DdShurick 12.04.19
if [ $(/usr/bin/id -u) != 0 ]; then echo "you must be root"; exit 1; fi
if [ $1 ]; then IFACE=$1; else echo "Не указан интерфейс"; exit 1; fi
[ "$(/bin/cat /sys/class/net/$IFACE/operstate)" = "up" ] && exit 0
[ "$(uname -m)" = "x86_64" -a -d /usr/lib64 ] && m=64

case $IFACE in
e[nt]*) IMG="/usr/share/pixmaps/network_" ;;
ww*|usb?) IMG="/usr/share/pixmaps/usb_modem_" ;;
esac

. /usr/lib${m}/upNet/libupNet
CONFDIR="/etc/net/interfaces/"
HWADDR=$(/bin/cat /sys/class/net/$IFACE/address)

pppoeup () {
if [ -f ${CONFDIR}${HWADDR}.pppoe.conf ]; then
	. ${CONFDIR}${HWADDR}.pppoe.conf
	/sbin/modprobe pppoe
	[ "$(/bin/grep $LOGIN /etc/ppp/chap-secrets)" ] || /bin/echo "$LOGIN	*	$PASSWD	$IP" | /usr/bin/tee -a /etc/ppp/chap-secrets
	[ "$(/bin/grep $LOGIN /etc/ppp/pap-secrets)" ] || /bin/echo "$LOGIN	*	$PASSWD	$IP" | /usr/bin/tee -a /etc/ppp/pap-secrets
	/bin/echo "plugin rp-pppoe.so
$AC
$SN
$1
name \"$LOGIN\"
$DNS
persist
defaultroute
hide-password
noauth
" | /usr/bin/tee /etc/ppp/peers/$NAME
	[ "$DNS1" != "" -o "$DNS1" != "0.0.0.0" ] && /bin/echo "nameserver $DNS1" | /usr/bin/tee /etc/resolv.conf
	[ "$DNS2" != "" -o "$DNS2" != "0.0.0.0" ] && /bin/echo "nameserver $DNS2" | /usr/bin/tee -a /etc/resolv.conf
	/usr/sbin/pppd call $NAME 
	/bin/sleep 3
	PID=$!
	if [ -h /sys/class/net/ppp0 ]; then
		/bin/echo "pppoe connect" | /usr/bin/tee -a /var/log/$IFACE.log
		msg "$1" "PPPoE Ok!"
		return 0
	else
		/bin/kill $PID
		echo "No PPPoE connect" | /usr/bin/tee -a /var/log/${1}.log
		return 1
	fi
else
	return 1
fi
}

ifup

if [ "$(/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ]; then
	/bin/echo "$0: carrier yes" | /usr/bin/tee -a /var/log/${IFACE}.log
	if [ -s "${CONFDIR}${HWADDR}.pppoe.conf" -o "$2" = "pppoeup" ]; then
		pppoeup $IFACE
		ST=$?
		[ "$ST" = 1 ] && /bin/kill $(/bin/pidof pppd)
	fi
	if [ -s "${CONFDIR}${HWADDR}.conf" ]; then
		static
	else
		dhcpc $(/sbin/udhcpc -i $IFACE -n 2>/dev/null)
		if [ $? = 1 -a $ST = 1 ]; then
			/sbin/ifconfig $IFACE down
			/bin/echo "$0: $IFACE down" | /usr/bin/tee -a /var/log/$IFACE.log
			msg_err $IFACE "$IFACE down"
		fi
	fi
else
	/bin/echo "$0: $IFACE: No carrier" | /usr/bin/tee -a /var/log/${IFACE}.log
	/sbin/ifconfig $IFACE down
	msg_err $IFACE "No carrier, $IFACE down"
	exit 1
fi

