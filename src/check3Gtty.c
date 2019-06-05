/*check3Gtty GPL v2, DdShurick 06.12.2017*/
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>
#include <unistd.h> 
#include <sys/types.h>
#include <signal.h>

char 	str[32]="", dev[16]="/dev/", mdir[42]="/sys/bus/usb-serial/devices/";
FILE	*fd;
DIR		*md;
struct	dirent *entry;

int main(int argc, char **argv) {
	
	int n=0;
	pid_t pid;
	char buf[14]="";
	
	if (!argv[1]) exit(1);
	
	strcat(dev,argv[1]);
	strcat(mdir,argv[1]);
	strcat(mdir,"/../");
	
	if ((fd = fopen(dev,"r+"))==NULL) { 
		exit(1); 
	}
	
	sleep(1);
	fputs("AT\n",fd);
	
	switch(pid=fork()) {
		case -1:
			exit(1);
		case 0:
			sleep(1);
			fclose(fd);
			kill(getppid(),15);
			raise(15);
		default:
			if (fgetc(fd)) {
				fclose(fd);
				kill(pid,15);
			}	
	}
	
	md=opendir(mdir);
	while ((entry = readdir(md))!=0) {
		if (strstr(entry->d_name,"ep_")!=0 ) {
			n = n + 1;
		}
	}
	if (n==2) {
		closedir(md);
		printf("modem_cli\n");
		unlink("/dev/modem_cli");
		symlink(dev,"/dev/modem_cli");
		exit(0);
	} 
	if (n==3) {
		closedir(md);
		printf("modem\n");
		unlink("/dev/modem");
		symlink(dev,"/dev/modem");
		exit(0);
	}
}

