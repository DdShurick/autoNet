#!/bin/sh
#DdShurick 19.12.15
[ $1 ] && IFACE=$1 || exit 1
CONFDIR="/etc/network-wizard/network/interfaces/"
HWCONF=$(/bin/cat /sys/class/net/$IFACE/address | /usr/bin/tr [a-f] [A-F]).conf

msg_ok () {
 export MSG="<window title=\"Интернет\"><vbox>
 <pixmap><input file>/usr/share/pixmaps/inet.png</input></pixmap>
 <text><label>Сеть $IFACE подключена</label></text>
 </vbox></window>"
 /usr/sbin/gtkdialog -c --display=:0 --program=MSG &
 pid=$!
 /bin/sleep 5 && kill $pid
 exit
}

msg_lan () {
 export MSG="<window title=\"Интернет\"><vbox>
 <pixmap><input file>/usr/share/pixmaps/inet.png</input></pixmap>
 <text><label>$IFACE подключен локально</label></text>
 </vbox></window>"
 /usr/sbin/gtkdialog -c --display=:0 --program=MSG &
 pid=$!
 /bin/sleep 5 && kill $pid
 exit
}

msg_err () {
 /sbin/ifconfig "$IFACE" down
 export MSG="<window title=\"Интернет\"><vbox>
 <pixmap><input file>/usr/share/pixmaps/inet_err.png</input></pixmap>
 <text><label>Нет подключения к $IFACE</label></text>
 </vbox></window>"
 /usr/sbin/gtkdialog -c --display=:0 --program=MSG &
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
			 /sbin/ifconfig "$IFACE" down
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

[ "$(/bin/cat /sys/class/net/$IFACE/operstate)" = "down" ] && (/sbin/ifconfig $IFACE up; /bin/sleep 3)
if [ "$(/bin/cat /sys/class/net/$IFACE/carrier)" = 1 ]; then
 /bin/echo "$IFACE up" >> /tmp/network.log #контроль

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
		 /sbin/ifconfig "$IFACE" down
		 /bin/echo "Нет DNS_SERVERS в $HWCONF" >> /tmp/network.log
		fi
		if [ "$GATEWAY" ]; then
		 /sbin/route add -net default gw "$GATEWAY" #dev $INTERFACE
			if [ $? -eq 0 ]; then #0=ok.
			 check_ping
			else
			 /bin/echo -e "Нет соединения с $GATEWAY." >> /tmp/network.log #dev $INTERFACE"
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
	 /bin/echo "udhcpc $IFACE" >> /tmp/network.log
	 IP=$(/sbin/udhcpc -i $IFACE -n | /bin/awk '/Lease/ {print $3}')
	 /sbin/ifconfig $IFACE $IP
	 /sbin/udhcpc -i $IFACE
	 GATEWAY=$(/bin/grep $IFACE /proc/net/arp | /usr/bin/cut -f1 -d' ')
		if [ "$GATEWAY" ]; then
		 /sbin/route add default gw $GATEWAY
		 /bin/echo "nameserver $GATEWAY">/etc/resolv.conf
		 check_ping
		else
		 /bin/echo "No GATEWAY on $IFACE">>/tmp/network.log
		 /sbin/ifconfig $IFACE down
		 exit 1
		fi
	fi
else
 /sbin/ifconfig $IFACE down
 /bin/echo "no connect $IFACE" >> /tmp/network.log
 exit 1
fi

