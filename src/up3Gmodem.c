/*up3Gmodem GPL v2, DdShurick 08.12.2017*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h> 
#include <sys/types.h>
#include <gtk/gtk.h>

char 	str[24]="", cops[24]="", cmd[36]="exec /usr/sbin/pppd call ", pincmd[16]="AT+CPIN=";
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
	GtkWidget *window, *entry;
	
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

		window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
		gtk_window_set_position(GTK_WINDOW(window),GTK_WIN_POS_CENTER);
		gtk_window_set_resizable(GTK_WINDOW(window),FALSE);
		gtk_window_set_title(GTK_WINDOW(window), "Введите PIN:");
		
		entry = gtk_entry_new();
		gtk_entry_set_visibility(GTK_ENTRY(entry),FALSE);// password mode
		gtk_entry_set_max_length(GTK_ENTRY(entry),4);
		g_signal_connect(G_OBJECT(entry), "activate", G_CALLBACK(enter_callback), entry);
		
		gtk_container_add (GTK_CONTAINER (window), entry);
		gtk_container_set_border_width (GTK_CONTAINER (window), 7);
		
		gtk_widget_show_all (window);
		g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);
		
		gtk_main ();
	}	
	fclose(fd);
	fclose(fl);
	exit(0);
}

