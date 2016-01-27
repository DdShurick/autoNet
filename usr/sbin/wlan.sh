#!/bin/sh
#DdShurick 08.12.15
[ $1 ] && IFACE=$1 || exit 1
WPADIR="/etc/network-wizard/wireless/wpa_profiles/"
CONFDIR="/etc/network-wizard/network/interfaces/"
HWCONF=$(/bin/cat /sys/class/net/$IFACE/address | /usr/bin/tr [a-f] [A-F]).conf
[ -f /tmp/iwopen ] && /bin/rm /tmp/iwopen

msg_ok () {
 export MSG="<window title=\"Wi-Fi\"><vbox>
 <pixmap><input file>/usr/share/pixmaps/wifi7.png</input></pixmap>
 <text><label>Wi-Fi сеть $ESSID подключена</label></text>
 </vbox></window>"
 /usr/sbin/gtkdialog -c --display=:0 --program=MSG &
 pid=$!
 /bin/sleep 5 && kill $pid
}

msg_lan () {
 export MSG="<window title=\"Wi-Fi\"><vbox>
 <pixmap><input file>/usr/share/pixmaps/wifi7.png</input></pixmap>
 <text><label>Wi-Fi $ESSID поключена локально</label></text>
 </vbox></window>"
 /usr/sbin/gtkdialog -c --display=:0 --program=MSG &
 pid=$!
 /bin/sleep 5 && kill $pid
}

msg_err () {
 [ "$(/bin/pidof wpa_supplicant)" ] && /bin/kill $(/bin/pidof wpa_supplicant)
 /sbin/ifconfig "$IFACE" down
 export MSG="<window title=\"Wi-Fi\"><vbox>
 <pixmap><input file>/usr/share/pixmaps/wifi_err.png</input></pixmap>
 <text><label>Нет подключения Wi-Fi $ESSID</label></text>
 </vbox></window>"
 /usr/sbin/gtkdialog -c --display=:0 --program=MSG &
 exit 1
}

check_ping () {
			if [ "$(/bin/ping -c 1 -W 2 $GATEWAY)" ]; then #Проверка. DdShurick add.
				if [ "$(/bin/ping -c 1 -W 2 8.8.8.8)" ]; then
				 /bin/echo "Default route set through $GATEWAY. Connect network" >> /tmp/network.log
				 msg_ok
				else
				 /sbin/route del default $IFACE
				 /bin/echo "Connect LAN" >> /tmp/network.log
				 msg_lan 
				fi
			else
			 /bin/echo "No ping $GATEWAY" >> /tmp/network.log
			 msg_err
			fi
}

#отключение файлом конфигурации
if [ -f ${CONFDIR}${HWCONF} ]; then
. ${CONFDIR}${HWCONF} 2>/dev/null
	if [ "$(grep ^$IFACE ${CONFDIR}${HWCONF} | grep off)" ]; then
	 /bin/echo "$IFACE down from configfile" >> /tmp/network.log
	 exit
	fi
fi

#Получаем список точек доступа и ищем файл конфигурации
/sbin/ifconfig $IFACE up && /usr/sbin/iwlist $IFACE sc | /bin/egrep 'Address:|Channel:|Quality|Encryption key:|ESSID:' > /tmp/iwlist && /bin/echo "$IFACE up" >> /tmp/network.log #контроль
[ -s /tmp/iwlist ] || exit 1
for WLNADDR in $(/bin/awk '/Address:/ {print $5}' /tmp/iwlist)
do
	if [ "$(/bin/grep -A 3 $WLNADDR /tmp/iwlist | /bin/grep 'Encryption key:off')" ];then
	 /bin/grep -A 4 $WLNADDR /tmp/iwlist >> /tmp/iwopen #Запомним открытые
	else 
		if WPA_CONF="$(/bin/ls ${WPADIR}${WLNADDR}*.conf)";then
		 ESSID=$(/bin/awk -F \= '/ssid/ {print $2}' $WPA_CONF)
		 /bin/echo $WPA_CONF >> /tmp/network.log #контроль
		 /usr/sbin/wpa_supplicant -B -D nl80211 -i "$IFACE" -c "$WPA_CONF" && ST=ok
		 break
		else
		 continue
		fi
	fi 
	if [ -s /tmp/iwopen ]; then
	 MAXLEVEL=$(/bin/grep -A 2 $WLNADDR /tmp/iwopen | /bin/grep 'Quality' | cut -f2 -d '-' | sort | head -n 1)
	 ESSID=$(/bin/grep -A 2 "$MAXLEVEL" /tmp/iwopen | /bin/grep ESSID | cut -f2 -d ':' | tr -d '"')
	 CHANNEL=$(/bin/grep -B 1 "$MAXLEVEL" /tmp/iwopen | /bin/grep Channel | cut -f2 -d ':')
	 /usr/sbin/iwconfig $IFACE essid $ESSID key off channel $CHANNEL && ST=ok
	 /bin/echo "$IFACE essid $ESSID key off channel $CHANNEL" >> /tmp/network.log #контроль
	fi
done
if [ "$ST" = "" ]; then
 /usr/bin/wifi
else
 T=0
	until [ "$(/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ]
	do
	 /bin/sleep 1
	 T="$(/usr/bin/expr $T + 1)"
	 /bin/echo -n "$T " >> /tmp/network.log #контроль
		if [ $T = 10 ]; then
		 /bin/echo "interface $IFACE down" >> /tmp/network.log #контроль
		 msg_err
		 exit
		fi 
	done
#[ $T = 10 ] && exit

	if [ "$STATIC_IP" = "yes" ]; then
#Далее участок старого кода из rc.network
	 /sbin/ifconfig "$IFACE" "$IP_ADDRESS"
		if [ "$DNS_SERVER1" -a "$DNS_SERVER1" != "0.0.0.0" ]; then
		 /bin/mv -f /etc/resolv.conf /etc/resolv.conf.old
		 /bin/echo "nameserver $DNS_SERVER1" > /etc/resolv.conf
			if [ "$DNS_SERVER2" -a "$DNS_SERVER2" != "0.0.0.0" ]; then
			 /bin/echo "nameserver $DNS_SERVER2" >> /etc/resolv.conf
			fi
		else
		 /bin/echo "Нет DNS_SERVERS в $HWCONF" >> /tmp/network.log
		 msg_err
		fi
		if [ "$GATEWAY" ]; then
		 /sbin/route add -net default gw "$GATEWAY"
			if [ $? -eq 0 ]; then #0=ok.
			 check_ping
			else
			 /bin/echo -e "Нет соединения с $GATEWAY." >> /tmp/network.log
			 msg_err
			fi
		else
		 /bin/echo -e "Не указан GATEWAY в $HWCONF" >> /tmp/network.log
		 msg_err
		fi
#Конец старого кода
#Редактировать файл конфигурации
	/bin/echo "# Укажите параметры сети. Если \"$IFACE=off\" сеть будет отключена." > ${CONFDIR}${HWCONF}
	 /bin/echo "$IFACE=on" >> ${CONFDIR}${HWCONF}
	 /bin/echo 'STATIC_IP=yes' >> ${CONFDIR}${HWCONF}
	 /bin/echo 'DNS_SERVER1=' >> ${CONFDIR}${HWCONF}
	 /bin/echo 'DNS_SERVER2=' >> ${CONFDIR}${HWCONF}
	 /bin/echo 'GATEWAY=' >> ${CONFDIR}${HWCONF}
	 /usr/bin/leafpad --display=:0 ${CONFDIR}${HWCONF}
	else
	 /bin/echo "dhcpcd $IFACE" >> /tmp/network.log
	 /usr/sbin/dhcpcd $IFACE > /tmp/dhcpcd.log
	 GATEWAY=$(/bin/awk '/offered/ {print $5}' /tmp/dhcpcd.log)
	 check_ping
	fi
fi
