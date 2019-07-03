#!/bin/sh
#DdShurick 12.08.18
[ $1 ] && IFACE=$1 || exit 1
IMG="wireless_"
. /usr/lib64/upNet/libupNet
WPADIR="/etc/net/wpa_profiles/"
CONFDIR="/etc/net/interfaces/"
HWADDR=$(/bin/cat /sys/class/net/$IFACE/address)

[ -f /tmp/iwopen ] && /bin/rm /tmp/iwopen

ifdown () {
	/bin/kill $(/bin/pidof wpa_supplicant)
	/sbin/ifconfig $IFACE down
}

#Получаем список точек доступа и ищем файл конфигурации
if ifup; then
	/bin/echo "$IFACE up" | tee /var/log/$IFACE.log
	/usr/bin/iwlist $IFACE scan | /bin/egrep 'Address:|Channel:|Quality|Encryption key:|ESSID:' | /usr/bin/tee /tmp/iwlist #контроль
fi
if [ ! -s /tmp/iwlist ]; then 
	IMG=wireless_err
	msg_err $IFACE "Сети wifi не найдены"
	ifdown
fi
for WLNADDR in $(/usr/bin/awk '/Address:/ {print $5}' /tmp/iwlist)
do
	if [ "$(/bin/grep -A 3 $WLNADDR /tmp/iwlist | /bin/grep 'Encryption key:off')" ];then
	 /bin/grep -A 4 $WLNADDR /tmp/iwlist | tee -a /tmp/iwopen #Запомним открытые
	else 
		if [ -f ${WPADIR}${WLNADDR}.wpa.conf ];then
			WPA_CONF="$(/bin/ls ${WPADIR}${WLNADDR}.wpa.conf)" #???
			ESSID=$(/usr/bin/awk -F \" '/ESSID/ {print $2}' $WPA_CONF)
			/bin/echo $WPA_CONF | tee -a /var/log/${IFACE}.log #контроль
			if /usr/sbin/wpa_supplicant -B -D nl80211 -i "$IFACE" -c "${WPADIR}${WLNADDR}.wpa.conf"; then
				echo "wpa_supplicant ok" | /usr/bin/tee -a /var/log/$IFACE.log 
				ST=ok
				break
			fi
		else
			continue
		fi
	fi 
	if [ -s /tmp/iwopen ]; then
	 MAXLEVEL=$(/bin/grep -A 2 $WLNADDR /tmp/iwopen | /bin/grep 'Quality' | cut -f2 -d '-' | sort | head -n 1)
	 ESSID=$(/bin/grep -A 2 "$MAXLEVEL" /tmp/iwopen | /bin/grep ESSID | cut -f2 -d ':' | tr -d '"')
	 CHANNEL=$(/bin/grep -B 1 "$MAXLEVEL" /tmp/iwopen | /bin/grep Channel | cut -f2 -d ':')
	 /usr/bin/iwconfig $IFACE essid $ESSID key off channel $CHANNEL && ST=ok
	 /bin/echo "$IFACE essid $ESSID key off channel $CHANNEL" | tee -a /var/log/$IFACE.log #контроль
	fi
done
if [ "$ST" = "" ]; then
	exec /usr/bin/wifi
else
 T=0
	until [ "$(/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ] #???
	do
		/bin/sleep 1
		T="$(/usr/bin/expr $T + 1)"
	 	/bin/echo -n "$T " | tee -a /var/log/$IFACE.log #контроль
		if [ $T = 10 ]; then
			/bin/echo "$0: Timeout, interface $IFACE down" | tee -a /var/log/$IFACE.log контроль
			IMG=wireless_err
			msg_err "Timeout, interface $IFACE down"
		fi 
	done

	if [ -s ${CONFDIR}${HWADDR}.conf ]; then
		static
	else
		dhcpc #$(/sbin/udhcpc -i $IFACE -n 2>/dev/null)
#		/sbin/udhcpc -n -i $IFACE | /usr/bin/tee -a /var/log/$IFACE.log
		if [ $? = 1 ]; then
			ifdown
			/bin/echo "$0: $IFACE down" | tee -a /var/log/$IFACE.log
			IMG=wireless_err
			msg_err $IFACE "$IFACE down"
		fi
	fi
fi
