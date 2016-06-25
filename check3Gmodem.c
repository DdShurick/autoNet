#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>
#include <unistd.h> 
#include <sys/types.h>

char 	str[]="", mnc[16]="", dev[16]="/dev/", mdir[42]="/sys/bus/usb-serial/devices/", lncmd[48]="/bin/ln -sf ", execmd[22]="wvdial ", pincmd[16]="AT+CPIN=", pinstr[6];
FILE	*fd, *fc;
DIR		*md;
struct	dirent *entry;

void	ops() {
	
	printf("Поиск сети\n");
	fputs("ATZ\r\n",fd);
	sleep(1);
	fputs("AT+COPS?\r\n",fd);
	while (strstr(str,"COPS:")==NULL) fgets(str,18,fd);
	if (strstr(str,"COPS: 0,")!=NULL) { 
		printf("%s\n",str+1); 
		fclose(fd); 
		strcat(execmd,str+12);
		strcat(execmd,"\n");
		system(execmd);
		exit(0); 
	} else {
		printf("Нет сети\n");
		fclose(fd);
		exit(0);
	}
}

int main(int argc, char **argv) {
	
	int n=0;
	pid_t pid;
	
	if (!argv[1]) { printf("Пример: up3Gmodem ttyUSB0\n"); exit(1); }
	
	strcat(dev,argv[1]);
	strcat(lncmd,dev);
	
	strcat(mdir,argv[1]);
	strcat(mdir,"/../");
	
	if ((fd = fopen(dev,"r+"))==NULL) { printf("Нет модема\n"); exit(1); }
	fputs("AT\r\n",fd);
	
	switch(pid=fork()) {
		case -1:
			exit(1);
		case 0:
			sleep(1);
			printf("Нет ответа\n");
			kill(getppid(),15);
			raise(15);
		default:
			if (fgetc(fd)) printf("Обнаружен %s\n",dev);
			kill(pid,15);
			
  }
	
	while (strstr(str,"OK")==NULL) fgets (str,4,fd);
	
		md=opendir(mdir);
		while ((entry = readdir(md))!=0) {
			if (strstr(entry->d_name,"ep_")!=0 ) {
				n = n + 1;
			}
		}
		if (n==2) {
			strcat(lncmd," /dev/ttyUSB_utps_pcui");
			system(lncmd);
			closedir(md);
			fclose(fd);
			exit(0);
		}
		if (n==3) {
			strcat(lncmd," /dev/modem");
			system(lncmd);
			closedir(md);
		}
	
	fputs("AT^CARDLOCK?\r\n",fd);
	while (strstr(str,"^CARDLOCK:")==NULL) fgets(str,32,fd);
	if (str[11]=='1') { printf("Модем не разлочен\n"); fclose(fd); exit(1); }
	
	fputs("AT+CPIN?\r\n",fd);
	while (strstr(str,"CPIN:")==NULL) fgets (str,15,fd);
	if (strstr(str,"SIM PIN")!=NULL) {
		printf("Введите PIN: ");
		scanf("%s",pinstr);
		strcat(pincmd,pinstr);
		strcat(pincmd,"\r\n");
		printf(pincmd);
		freopen(dev,"w+",fd);
		fputs(pincmd,fd);
		sleep(3);
		ops();
	}
	if (strstr(str,"READY")!=NULL) {
		printf(str+2);
		ops();
	}	
	fclose(fd);
	exit(0);
}

