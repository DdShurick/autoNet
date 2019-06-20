#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

int main(int argc, char **argv) {
	char 	str[9]="", dev[16]="/dev/";
	FILE	*fd;
	pid_t pid;
	
	if (!argv[1]) exit(1);
	
	strcat(dev,argv[1]);
	
	if ((fd = fopen(dev,"r+"))==NULL) exit(1); 
	
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
				while (1) {
					fgets(str,9,fd);
					if (str[0] == '^') {
						unlink("/dev/modem_cli");
						symlink(dev,"/dev/modem_cli");
						break;
					}
					if ((strstr(str,"OK")) != NULL) {
						unlink("/dev/modem");
						symlink(dev,"/dev/modem");
						break;
					}
				}
				fclose(fd);
				kill(pid,15);
			}
	}
	exit (0);
}
