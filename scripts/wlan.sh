#!/bin/sh
#DdShurick 12.08.18
[ $1 ] && IFACE=$1 || exit 1
[ `id -u` = 0 ] && DISPLAY=":0" || sudo=sudo
. /usr/lib/upNet/libupNet
WPADIR="/etc/net/wpa_profiles/"
CONFDIR="/etc/net/interfaces/"
HWADDR=$(/usr/bin/cat /sys/class/net/$IFACE/address)
[ -f /tmp/iwopen ] && $sudo /usr/bin/rm /tmp/iwopen

ifdown () {
	$sudo /usr/bin/kill $(/usr/bin/pidof wpa_supplicant)
	$sudo /usr/bin/ifconfig $IFACE down
}

#Получаем список точек доступа и ищем файл конфигурации
ifup
$sudo /usr/bin/iwlist $IFACE scan | /usr/bin/egrep 'Address:|Channel:|Quality|Encryption key:|ESSID:' | $sudo /usr/bin/tee /tmp/iwlist
if [ ! -s /tmp/iwlist ]; then 
	/usr/local/bin/ntf -e $IFACE "Сети wifi не найдены"
	ifdown
fi
for WLNADDR in $(/usr/bin/awk '/Address:/ {print $5}' /tmp/iwlist)
do
	if [ "$(/usr/bin/grep -A 3 $WLNADDR /tmp/iwlist | /usr/bin/grep 'Encryption key:off')" ];then
	 /usr/bin/grep -A 4 $WLNADDR /tmp/iwlist | tee -a /tmp/iwopen #Запомним открытые
	else 
		if [ -f ${WPADIR}${WLNADDR}.wpa.conf ];then
			ESSID=$(/usr/bin/awk -F \" '/ESSID/ {print $2}' ${WPADIR}${WLNADDR}.wpa.conf)
			/usr/bin/echo ${WLNADDR}.wpa.conf | $sudo /usr/bin/tee -a /var/log/$IFACE.log
			if $sudo /usr/bin/wpa_supplicant -B -D nl80211 -i "$IFACE" -c "${WPADIR}${WLNADDR}.wpa.conf"; then
				echo "wpa_supplicant ok" | $sudo /usr/bin/tee -a /var/log/$IFACE.log 
				ST=ok
				break
			fi
		else
			continue
		fi
	fi 
	if [ -s /tmp/iwopen ]; then
	 MAXLEVEL=$(/usr/bin/grep -A 2 $WLNADDR /tmp/iwopen | /usr/bin/grep 'Quality' | cut -f2 -d '-' | sort | head -n 1)
	 ESSID=$(/usr/bin/grep -A 2 "$MAXLEVEL" /tmp/iwopen | /usr/bin/grep ESSID | cut -f2 -d ':' | tr -d '"')
	 CHANNEL=$(/usr/bin/grep -B 1 "$MAXLEVEL" /tmp/iwopen | /usr/bin/grep Channel | cut -f2 -d ':')
	 $sudo /usr/bin/iwconfig $IFACE essid $ESSID key off channel $CHANNEL && ST=ok
	 /usr/bin/echo "$IFACE essid $ESSID key off channel $CHANNEL" | $sudo /usr/bin/tee -a /var/log/$IFACE.log
	fi
done
if [ "$ST" = "" ]; then
	exec /usr/bin/wifi
else
 T=0
	until [ "$(/usr/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ]
	do
		/usr/bin/sleep 1
		T="$(/usr/bin/expr $T + 1)"
		if [ $T = 10 ]; then
			ifdown
			/usr/bin/echo "$0: Timeout, interface $IFACE down" | tee -a /var/log/$IFACE.log #контроль
			/usr/local/bin/ntf -e $IFACE "Timeout, interface $IFACE down"
			exit 1
		fi 
	done

	if [ -s ${CONFDIR}${HWADDR}.conf ]; then
		static
	else
		dhcpc $($sudo /usr/bin/udhcpc -i $IFACE -n 2>/dev/null) || ifdown
	fi
fi
