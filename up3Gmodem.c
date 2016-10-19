#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>
#include <unistd.h> 
#include <sys/types.h>
#include <gtk/gtk.h>

char 	str[]="", mnc[16]="", dev[16]="/dev/", mdir[42]="/sys/bus/usb-serial/devices/", lncmd[48]="/bin/ln -sf ", execmd[22]="wvdial ", pincmd[16]="AT+CPIN=";
const gchar *pin;
FILE	*fd, *fc;
DIR		*md;
struct	dirent *direntry;

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

void enter_callback(GtkWidget *widget, GtkWidget *entry) {

	pin = gtk_entry_get_text(GTK_ENTRY(entry));
//	printf("%s\n", pin);
	strcat(pincmd,pin);
	strcat(pincmd,"\r\n");
//	printf(pincmd);
	freopen(dev,"w+",fd);
	fputs(pincmd,fd);
	sleep(3);
	ops();
	gtk_main_quit ();
	
}

int main(int argc, char **argv) {
	
	int n=0;
	pid_t pid;
	GtkWidget *window, *vbox, *entry, *upperLabel;
	
	gtk_init (&argc, &argv);
	
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
		while ((direntry = readdir(md))!=0) {
			if (strstr(direntry->d_name,"ep_")!=0 ) {
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
//		gtk_init (&argc, &argv);

		window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
		gtk_window_set_position(GTK_WINDOW(window),GTK_WIN_POS_CENTER);
		gtk_container_set_border_width (GTK_CONTAINER (window), 7);
		g_signal_connect(G_OBJECT(window), "delete_event", G_CALLBACK(gtk_main_quit), NULL);

		vbox = gtk_vbox_new (FALSE, 3);
		gtk_container_add (GTK_CONTAINER (window), vbox);

		upperLabel = gtk_label_new ("Введите PIN:");
		gtk_box_pack_start (GTK_BOX (vbox), upperLabel, TRUE, TRUE, 0);

		entry = gtk_entry_new_with_max_length (4);
		gtk_entry_set_visibility(GTK_ENTRY(entry),FALSE);// password mode
		gtk_signal_connect(GTK_OBJECT(entry), "activate", GTK_SIGNAL_FUNC(enter_callback), entry);

		gtk_box_pack_start (GTK_BOX (vbox), entry, TRUE, TRUE, 0);
		gtk_entry_set_width_chars (GTK_ENTRY (entry), 4);

		gtk_widget_show_all (window);

		gtk_main ();
/*		printf("Введите PIN: ");
		scanf("%s",pinstr);
		strcat(pincmd,pinstr);
		strcat(pincmd,"\r\n");
		printf(pincmd);
		freopen(dev,"w+",fd);
		fputs(pincmd,fd);
		sleep(3);
		ops();*/
		
	}
	if (strstr(str,"READY")!=NULL) {
		printf(str+2);
		ops();
	}	
	fclose(fd);
	exit(0);
}

