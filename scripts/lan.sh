#!/bin/ash
#DdShurick 25.08.18
[ $1 ] && IFACE=$1 || exit 1

case $IFACE in
e[nt]*) IMG="/usr/share/pixmaps/network_" ;;
ww*|usb?) IMG="/usr/share/pixmaps/usb_modem_" ;;
esac

[ `/usr/bin/id -u` = 0 ] || sudo=sudo
. /usr/lib/upNet/libupNet
CONFDIR="/etc/net/interfaces/"
HWADDR=$(/usr/bin/cat /sys/class/net/$IFACE/address)

pppoeup () {
if [ -f ${CONFDIR}${HWADDR}.pppoe.conf ]; then
	. ${CONFDIR}${HWADDR}.pppoe.conf
	$sudo /usr/bin/modprobe pppoe
	[ "$($sudo /usr/bin/grep $LOGIN /etc/ppp/chap-secrets)" ] || /usr/bin/echo "$LOGIN	*	$PASSWD	$IP" | $sudo /usr/bin/tee -a /etc/ppp/chap-secrets
	[ "$($sudo /usr/bin/grep $LOGIN /etc/ppp/pap-secrets)" ] || /usr/bin/echo "$LOGIN	*	$PASSWD	$IP" | $sudo  /usr/bin/tee -a /etc/ppp/pap-secrets
	/usr/bin/echo "plugin rp-pppoe.so
$AC
$SN
$1
name \"$LOGIN\"
$DNS
persist
defaultroute
hide-password
noauth
" | $sudo /usr/bin/tee /etc/ppp/peers/$NAME
	[ "$DNS1" != "" -o "$DNS1" != "0.0.0.0" ] && /usr/bin/echo "nameserver $DNS1" | $sudo /usr/bin/tee /etc/resolv.conf
	[ "$DNS2" != "" -o "$DNS2" != "0.0.0.0" ] && /usr/bin/echo "nameserver $DNS2" | $sudo /usr/bin/tee -a /etc/resolv.conf
	$sudo /usr/bin/pppd call $NAME 
	/usr/bin/sleep 3
	PID=$!
	if [ -h /sys/class/net/ppp0 ]; then
		/usr/bin/echo "pppoe connect" | $sudo tee -a /var/log/$IFACE.log
		/usr/local/bin/ntf -i "$1" "PPPoE Ok!"
		return 0
	else
		$sudo /usr/bin/kill $PID
		echo "No PPPoE connect" | $sudo /usr/bin/tee -a /var/log/${1}.log
		return 1
	fi
else
	return 1
fi
}

ifup

if [ "$(/usr/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ]; then
	/usr/bin/echo "$0: carrier yes" | $sudo /usr/bin/tee -a /var/log/${IFACE}.log
	if [ -s "${CONFDIR}${HWADDR}.pppoe.conf" -o "$2" = "pppoeup" ]; then
		pppoeup $IFACE
		ST=$?
		[ "$ST" = 1 ] && $sudo /usr/bin/kill $(/usr/bin/pidof pppd)
	fi
	if [ -s "${CONFDIR}${HWADDR}.conf" ]; then
		static
	else
		dhcpc $($sudo /usr/bin/udhcpc -i $IFACE -n 2>/dev/null)
		if [ $? = 1 -a $ST = 1 ]; then
			$sudo /usr/bin/ifconfig $IFACE down
			/usr/bin/echo "$0: $IFACE down" | $sudo /usr/bin/tee -a /var/log/$IFACE.log
			/usr/local/bin/ntf -e $IFACE "$IFACE down"
		fi
	fi
else
	/usr/bin/echo "$0: $IFACE: No carrier" | $sudo  /usr/bin/tee -a /var/log/${IFACE}.log
	/usr/local/bin/ntf -e $IFACE "No carrier"
	$sudo /usr/bin/ifconfig $IFACE down
	/usr/local/bin/ntf -e $IFACE "$IFACE down"
	exit 1
fi

