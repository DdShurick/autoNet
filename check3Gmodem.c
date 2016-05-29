#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>

char 	str[18]="", mnc[16]="", dev[16]="/dev/", mdir[42]="/sys/bus/usb-serial/devices/", cmd[48]="/bin/ln -s ", execmd[22]="wvdial ", pincmd[16]="AT+CPIN=", pinstr[4];
FILE	*fd, *fc;
DIR		*md;
struct	dirent *entry;
int n;

void	close() {
	
	fclose (fd);
	exit(0);
}

void	ops() {
	
	sleep(1);
	strcpy(str,"");
	fputs("AT+COPS?\r\n",fd);
	while (strstr(str,"COPS:")==NULL) {	
		fgets (str,sizeof(str),fd);
		if (strstr(str,": 0\n")!=NULL) close(); //No COPS, сделать уведомление
		if (strstr(str,": 0,")!=NULL) {
			fc=fopen("/etc/cops.lst","r");
			while (strstr(mnc,str+12)==NULL) {
				fgets (mnc,sizeof(mnc),fc);
			}
			strcat(execmd,mnc+6);
			printf(execmd);
			fclose(fc);
			system(execmd);
			close();
		}
	}
}

void	pin() {
	
	printf("Enter PIN: ");
	scanf("%s",pinstr);
	strcat(pincmd,pinstr);
	strcat(pincmd,"\r\n");
	fputs(pincmd,fd);
	sleep(3);
	ops();
	close();
}

int main(int argc, char **argv) {
	
	strcat(dev,argv[1]);
	strcat(cmd,dev);
	strcat(mdir,argv[1]);
	strcat(mdir,"/../");
	n=0;
	
	if ((fd = fopen(dev,"a+")) == NULL) exit(1);
	fputs("AT\r\n",fd);
	while (strstr(str,"OK")==NULL) {
		fgets (str,sizeof(str),fd);
		md=opendir(mdir);
		while ((entry = readdir(md))!=0) {
			if (strstr(entry->d_name,"ep_")!=0 ) {
				n = n + 1;
			}
		}
		if (n==2) {
			strcat(cmd," /dev/ttyUSB_utps_pcui");
			system(cmd);
			close();
		}
		if (n==3) {
			strcat(cmd," /dev/modem");
			system(cmd);
			
		}
		closedir(md);
	}
	
	strcpy(str,"");
	fputs("AT+CPIN?\r\n",fd);
	while (strstr(str,"CPIN:")==NULL) {		
		fgets (str,sizeof(str),fd);
		if (strstr(str,"ERROR")!=NULL) break;
		if (strstr(str,"SIM PIN")!=NULL) pin();
		if (strstr(str,"READY")!=NULL) ops();
	}	
	close();
}

