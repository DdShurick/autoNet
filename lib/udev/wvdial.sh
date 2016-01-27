#!/bin/sh
#DdShurick GPL 04.02.14
export DISPLAY=:0
[ $(/bin/pidof wvdial) ] && exit

[ -x /usr/bin/xpupsay ] && MSG=xpupsay || MSG=echo

error () {
$MSG "$1
Попробуйте ещё раз" 
exit 1	
}

name () {
case $1 in
"") error "Ошибка, не определился оператор" ;;
25001) OPS=MTS ;;
25002) OPS=MegaFon ;;	
25099) OPS=Beeline ;;
25020) OPS=tele2 ;;
*) OPS=$1 ;;
esac
}

M=$(cat $(dirname $(dirname $(realpath /sys/bus/usb-serial/devices/ttyUSB0)))/product)
$MSG "Запускается $M модем..." &
[ -f /etc/ppp/peers/wvdial -a -f /etc/ppp/peers/wvdial-pipe ] || /bin/ln -s /etc/ppp/wvdial* /etc/ppp/peers/
/bin/sleep 12
if [ -h /dev/ttyUSB_utps_pcui ]; then
/bin/echo AT+COPS? > /dev/ttyUSB_utps_pcui
OPS=$(/bin/grep -m2 COPS /dev/ttyUSB_utps_pcui | /bin/awk -F \" '/COPS:/ {print $2}')
#[ "$OPS" ] || error "Ошибка, не определился оператор"
name $OPS
fi
$MSG "Подключаем сеть $OPS"
/usr/bin/wvdial $OPS 2>/tmp/wvdial.log &
/bin/sleep 12
[ $(/bin/pidof wvdial) ] && exit
/usr/bin/leafpad /tmp/wvdial.log
