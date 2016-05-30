#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char	dev[15]="/dev/", dhcpcmd[25]="/usr/sbin/dhcpcd ", lancmd[26]="/usr/sbin/";
FILE	*fd;



int main(int argc, char **argv) {
	
	if (strstr(argv[1],"lo")) {
		system("/sbin/ifconfig lo  127.0.0.1 up");
		system("/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 lo");
	}
	if (strstr(argv[1],"cdc-wdm")) {
		sleep(10);
		strcat(dev,argv[1]);
		if ((fd=fopen(dev,"a+"))==NULL) exit(1);
		fputs("AT^NDISCONN=1,1\r\n",fd);
		fclose(fd);
	}
	if (strstr(argv[1],"usb")) {
//		chk_on();
		sleep(10);
		strcat(dhcpcmd,argv[1]);
		system(dhcpcmd);
//		printf("/usr/bin/curl http://192.168.0.1/goform/goform_set_cmd_process?goformId=CONNECT_NETWORK\n");
	}
	if (strstr(argv[1],"wwan")) {
//		chk_on();		
		sleep(1);
		strcat(dhcpcmd,argv[1]);
//		strcat(dhcpcmd,"\n");
		system(dhcpcmd);
	}
	if (strstr(argv[1],"eth")) {
//		chk_on();
		strcat(lancmd,"lan.sh ");
		strcat(lancmd,argv[1]);
//		strcat(lancmd,"\n");
		system(lancmd);
	}
	if (strstr(argv[1],"wlan")) {
//		chk_on();
		strcat(lancmd,"wlan.sh ");
		strcat(lancmd,argv[1]);
//		strcat(lancmd,"\n");
		system(lancmd);
	}
}
