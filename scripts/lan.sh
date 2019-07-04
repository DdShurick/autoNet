#!/bin/sh
#DdShurick GPL v2
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
	modprobe pppoe
	[ grep "$LOGIN" /etc/ppp/chap-secrets ] || echo "$LOGIN	*	$PASSWD	$IP" >> /etc/ppp/chap-secrets
	[ grep "$LOGIN" /etc/ppp/pap-secrets ] || /bin/echo "$LOGIN	*	$PASSWD	$IP" >> /etc/ppp/pap-secrets
	echo "plugin rp-pppoe.so
$AC
$SN
$IFACE
name \"$LOGIN\"
$DNS
persist
defaultroute
hide-password
noauth
" | tee /etc/ppp/peers/$NAME
	[ "$DNS1" != "" -o "$DNS1" != "0.0.0.0" ] && echo "nameserver $DNS1" | tee /etc/resolv.conf
	[ "$DNS2" != "" -o "$DNS2" != "0.0.0.0" ] && echo "nameserver $DNS2" | tee -a /etc/resolv.conf
	pppd call $NAME
	PID=$!
	sleep 3
	if [ -h /sys/class/net/ppp0 ]; then
		echo "pppoe connect" | tee -a /var/log/$IFACE.log
		cp /etc/ppp/resolv.conf /etc/resolv.conf
		IMG=connect
		msg "$IFACE PPPoE up"
		return 0
	else
		kill $PID
		echo "No PPPoE connect" | tee -a /var/log/${1}.log
		return 1
	fi
else
	return 1
fi
}

ifup && echo "$0: $IFACE up" | tee /var/log/${IFACE}.log

if [ "$(cat /sys/class/net/$IFACE/carrier)" = 1 ]; then
	echo "$0: carrier yes" | tee -a /var/log/${IFACE}.log
	if [ -s "${CONFDIR}${HWADDR}.pppoe.conf" -o "$2" = "pppoeup" ]; then
		pppoeup $IFACE
		ST=$?
		[ "$ST" = 1 ] && kill $(pidof pppd)
	fi
	if [ -s "${CONFDIR}${HWADDR}.conf" ]; then
		static
	else
		dhcpc
		if [ $? = 1 -a $ST = 1 ]; then
			ifconfig $IFACE down
			echo "$0: $IFACE down" | tee -a /var/log/$IFACE.log
			msg_err $IFACE "$IFACE down"
		fi
	fi
else
	echo "$0: $IFACE: No carrier" | echo tee -a /var/log/${1}.log
	msg_err $IFACE "No carrier"
	exit 1
fi

