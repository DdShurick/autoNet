/*up3Gmodem GPL v2, DdShurick 08.12.2017*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h> 
#include <sys/types.h>
#include <gtk/gtk.h>

char 	str[24]="", cops[24]="", cmd[36]="exec /usr/sbin/pppd call ", pincmd[16]="AT+CPIN=";//, mdir[42]="/sys/bus/usb-serial/devices/", lncmd[48]="/bin/ln -sf ", traycmd[34]="exec /usr/bin/tray3Gcsq ", dev[16]="/dev/", mnc[16]=""; cmd[36]="exec /usr/bin/wvdial "
const gchar *pin;
FILE	*fd, *fl;

void	ops() {
	
//	fputs("ATZ\n",fd);
	printf("Поиск сети\n");
	fprintf(fl,"Поиск сети\n");
//	system("/usr/local/bin/ntf -i Поиск сети & \n");
	
	if (fputs("AT+COPS?\n",fd)) {
		printf("Оператор: ");
		fprintf(fl,"Оператор: ");
	}
	str[0]=0;
	while ((strstr(str,"COPS:"))==NULL) {
		fgets(str,24,fd); //
		if (strstr(str,"COPS: 0,")) { //
			int n=strlen(str)-4;
			strncpy(cops,str,n);
			printf("%s\n",cops+12);
			fprintf(fl,"%s\n",cops+12);
			fclose(fd); 
			strcat(cmd,cops+12);
			strcat(cmd," &\n");
			fprintf(fl,"Start pppd...");
			system(cmd);
			fprintf(fl,"Ok\n");
			fclose(fl);
			exit(0); 
		}
		if (strstr(str,"+COPS: 0\n")) {
			printf("Нет сети\n");
			fclose(fd);
//			system("/usr/local/bin/ntf -e \"Нет сети\" & \n");
			fclose(fl);
			exit(0);
		}
	}
}

void enter_callback(GtkWidget *widget, GtkWidget *entry) {

	pin = gtk_entry_get_text(GTK_ENTRY(entry));
//	printf("%s\n", pin);
	strcat(pincmd,pin);
	strcat(pincmd,"\n");
//	printf(pincmd);
	freopen("/dev/modem_cli","r+",fd);
	fputs(pincmd,fd);
	sleep(3);
	ops();
	gtk_main_quit ();
	
}

int main(int argc, char **argv) {
	
	char	route[5];
	FILE	*fr;
	GtkWidget *window, *vbox, *entry, *upperLabel;
	
	fl = fopen("/var/log/up3G.log","w");
	
	if ((fd = fopen("/dev/modem","r+"))==NULL) {
		printf("Нет модема\n");
		fprintf(fl,"Нет модема\n");
		exit(1);
	}
	
	fprintf(fl,"Check PIN\n");
	fputs("AT+CPIN?\n",fd);
	printf("CPIN? ");
	while ((strstr(str,"+CPIN:"))==NULL) fgets (str,15,fd);
	if ((strstr(str,"READY"))!=NULL) {
		printf(str+2);
		ops();
	}
	if ((strstr(str,"SIM PIN"))!=NULL) {
		
		gtk_init (&argc, &argv);

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
	}	
	fclose(fd);
	fclose(fl);
	exit(0);
}

