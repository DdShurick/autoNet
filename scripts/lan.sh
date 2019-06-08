#!/bin/sh
#DdShurick 25.08.18
[ $1 ] && IFACE=$1 || exit 1

case $IFACE in
e[nt]*) IMG="network_" ;;
ww*|usb?) IMG="usb_modem_" ;;
esac

. /usr/lib64/upNet/libupNet
CONFDIR="/etc/net/interfaces/"
HWADDR=$(/bin/cat /sys/class/net/$IFACE/address)

pppoeup () {
if [ -f ${CONFDIR}${HWADDR}.pppoe.conf ]; then
	. ${CONFDIR}${HWADDR}.pppoe.conf
	/sbin/modprobe pppoe
	[ /bin/grep "$LOGIN" /etc/ppp/chap-secrets ] || /bin/echo "$LOGIN	*	$PASSWD	$IP" >> /etc/ppp/chap-secrets
	[ /bin/grep "$LOGIN" /etc/ppp/pap-secrets ] || /bin/echo "$LOGIN	*	$PASSWD	$IP" >> /etc/ppp/pap-secrets
	/bin/echo "plugin rp-pppoe.so
$AC
$SN
$IFACE
name \"$LOGIN\"
$DNS
persist
defaultroute
hide-password
noauth
" | /usr/bin/tee /etc/ppp/peers/$NAME
	[ "$DNS1" != "" -o "$DNS1" != "0.0.0.0" ] && /bin/echo "nameserver $DNS1" | tee /etc/resolv.conf
	[ "$DNS2" != "" -o "$DNS2" != "0.0.0.0" ] && /bin/echo "nameserver $DNS2" | tee -a /etc/resolv.conf
	/usr/sbin/pppd call $NAME
	PID=$!
	/bin/sleep 3
	if [ -h /sys/class/net/ppp0 ]; then
		/bin/echo "pppoe connect" | /usr/bin/tee -a /var/log/$IFACE.log
		/bin/cp /etc/ppp/resolv.conf /etc/resolv.conf
		IMG=connect
		msg "$IFACE PPPoE up"
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

ifup && /bin/echo "$0: $IFACE up" | /usr/bin/tee /var/log/${IFACE}.log

if [ "$(/usr/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ]; then
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
	"$0: $IFACE: No carrier" | echo tee -a /var/log/${1}.log
	msg_err $IFACE "No carrier"
	exit 1
fi

