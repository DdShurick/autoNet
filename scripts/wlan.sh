#!/bin/sh
#DdShurick GPL v2
[ $1 ] && IFACE=$1 || exit 1
IMG="wireless_"
. /usr/lib64/upNet/libupNet
WPADIR="/etc/net/wpa_profiles/"
CONFDIR="/etc/net/interfaces/"
HWADDR=$(cat /sys/class/net/$IFACE/address)

[ -f /tmp/iwopen ] && rm /tmp/iwopen

ifdown () {
	kill $(/bin/pidof wpa_supplicant)
	ifconfig $IFACE down
}

#Получаем список точек доступа и ищем файл конфигурации
if ifup; then
	echo "$IFACE up" | tee /var/log/$IFACE.log
	iwlist $IFACE scan | egrep 'Address:|Channel:|Quality|Encryption key:|ESSID:' | tee /tmp/iwlist #контроль
fi
if [ ! -s /tmp/iwlist ]; then 
	IMG=wireless_err
	msg_err $IFACE "Сети wifi не найдены"
	ifdown
fi
for WLNADDR in $(awk '/Address:/ {print $5}' /tmp/iwlist)
do
	if [ "$(grep -A 3 $WLNADDR /tmp/iwlist | grep 'Encryption key:off')" ];then
	 grep -A 4 $WLNADDR /tmp/iwlist | tee -a /tmp/iwopen #Запомним открытые
	else 
		if [ -f ${WPADIR}${WLNADDR}.wpa.conf ];then
			WPA_CONF="$(ls ${WPADIR}${WLNADDR}.wpa.conf)" #???
			ESSID=$(awk -F \" '/ESSID/ {print $2}' $WPA_CONF)
			echo $WPA_CONF | tee -a /var/log/${IFACE}.log #контроль
			if wpa_supplicant -B -D nl80211 -i "$IFACE" -c "${WPADIR}${WLNADDR}.wpa.conf"; then
				echo "wpa_supplicant ok" | tee -a /var/log/$IFACE.log 
				ST=ok
				break
			fi
		else
			continue
		fi
	fi 
	if [ -s /tmp/iwopen ]; then
	 MAXLEVEL=$(grep -A 2 $WLNADDR /tmp/iwopen | grep 'Quality' | cut -f2 -d '-' | sort | head -n 1)
	 ESSID=$(grep -A 2 "$MAXLEVEL" /tmp/iwopen | grep ESSID | cut -f2 -d ':' | tr -d '"')
	 CHANNEL=$(grep -B 1 "$MAXLEVEL" /tmp/iwopen | grep Channel | cut -f2 -d ':')
	 iwconfig $IFACE essid $ESSID key off channel $CHANNEL && ST=ok
	 echo "$IFACE essid $ESSID key off channel $CHANNEL" | tee -a /var/log/$IFACE.log #контроль
	fi
done
if [ "$ST" = "" ]; then
	exec wifi
else
 T=0
	until [ "$(cat /sys/class/net/$IFACE/carrier)" = 1 ] #???
	do
		sleep 1
		T="$(expr $T + 1)"
	 	echo -n "$T " | tee -a /var/log/$IFACE.log #контроль
		if [ $T = 10 ]; then
			echo "$0: Timeout, interface $IFACE down" | tee -a /var/log/$IFACE.log контроль
			IMG=wireless_err
			msg_err "Timeout, interface $IFACE down"
		fi 
	done

	if [ -s ${CONFDIR}${HWADDR}.conf ]; then
		static
	else
		dhcpc
		if [ $? = 1 ]; then
			ifdown
			echo "$0: $IFACE down" | tee -a /var/log/$IFACE.log
			IMG=wireless_err
			msg_err $IFACE "$IFACE down"
		fi
	fi
fi
