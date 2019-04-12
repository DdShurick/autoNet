#!/bin/sh
#DdShurick 12.04.19
if [ $(/usr/bin/id -u) != 0 ]; then echo "you must be root"; exit 1; fi
if [ $1 ]; then IFACE=$1; else echo "Не указан интерфейс"; exit 1; fi
if [ ! -d /sys/class/net/$IFACE/phy80211 ]; then echo "Интерфейс не wifi"; exit 1; fi
[ "$(cat /sys/class/net/$IFACE/operstate)" = "up" ] && exit 0
[ "$(uname -m)" = "x86_64" -a -d /usr/lib64 ] && m=64
. /usr/lib${m}/upNet/libupNet
WPADIR="/etc/net/wpa_profiles/"
CONFDIR="/etc/net/interfaces/"
HWADDR=$(/bin/cat /sys/class/net/$IFACE/address)
[ -f /tmp/iwopen ] && /bin/rm /tmp/iwopen

ifdown () {
	/bin/kill $(/usr/bin/pidof wpa_supplicant)
	/sbin/ifconfig $IFACE down
}

#Получаем список точек доступа и ищем файл конфигурации
ifup
/usr/bin/iwlist $IFACE scan | /bin/egrep 'Address:|Channel:|Quality|Encryption key:|ESSID:' | /usr/bin/tee /tmp/iwlist
if [ ! -s /tmp/iwlist ]; then 
#	/usr/local/bin/ntf -e $IFACE "Сети wifi не найдены"
	ifdown
fi
for WLNADDR in $(/usr/bin/awk '/Address:/ {print $5}' /tmp/iwlist)
do
	if [ "$(/bin/grep -A 3 $WLNADDR /tmp/iwlist | /bin/grep 'Encryption key:off')" ];then
	 /bin/grep -A 4 $WLNADDR /tmp/iwlist | /usr/bin/tee -a /tmp/iwopen #Запомним открытые
	else 
		if [ -f ${WPADIR}${WLNADDR}.wpa.conf ];then
			ESSID=$(/usr/bin/awk -F \" '/ESSID/ {print $2}' ${WPADIR}${WLNADDR}.wpa.conf)
			/bin/echo ${WLNADDR}.wpa.conf | /usr/bin/tee -a /var/log/$IFACE.log
			if /usr/sbin/wpa_supplicant -B -D nl80211 -i "$IFACE" -c "${WPADIR}${WLNADDR}.wpa.conf"; then
				/bin/echo "wpa_supplicant ok" | /usr/bin/tee -a /var/log/$IFACE.log 
				ST=ok
				break
			fi
		else
			continue
		fi
	fi 
	if [ -s /tmp/iwopen ]; then
	 MAXLEVEL=$(/bin/grep -A 2 $WLNADDR /tmp/iwopen | /bin/grep 'Quality' | /usr/bin/cut -f2 -d '-' | /usr/bin/sort | /usr/bin/head -n 1)
	 ESSID=$(/bin/grep -A 2 "$MAXLEVEL" /tmp/iwopen | /bin/grep ESSID | cut -f2 -d ':' | tr -d '"')
	 CHANNEL=$(/bin/grep -B 1 "$MAXLEVEL" /tmp/iwopen | /bin/grep Channel | cut -f2 -d ':')
	 /usr/bin/iwconfig $IFACE essid $ESSID key off channel $CHANNEL && ST=ok
	 /bin/echo "$IFACE essid $ESSID key off channel $CHANNEL" | /usr/bin/tee -a /var/log/$IFACE.log
	fi
done
if [ "$ST" = "" ]; then
	exec /usr/bin/wifi
else
 T=0
	until [ "$(/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ]
	do
		/bin/sleep 1
		T="$(/usr/bin/expr $T + 1)"
		if [ $T = 10 ]; then
			ifdown
			/bin/echo "$0: Timeout, interface $IFACE down" | /usr/bin/tee -a /var/log/$IFACE.log #контроль
#			/usr/local/bin/ntf -e $IFACE "Timeout, interface $IFACE down"
			exit 1
		fi 
	done

	if [ -s ${CONFDIR}${HWADDR}.conf ]; then
		static
	else
		dhcpc $(/sbin/udhcpc -i $IFACE -n 2>/dev/null) || ifdown
	fi
fi
