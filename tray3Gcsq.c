/*Based on a simple systray applet example by Rodrigo De Castro, 2007
GPL license /usr/share/doc/legal/gpl-2.0.txt.
tray3Dcsq GPL v2, DdShutick */

#include <string.h>
//#include <libintl.h>
//#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
//#define _(STRING)    gettext(STRING)

GtkStatusIcon *tray_icon;
unsigned int interval = 1000; /*update interval in milliseconds*/
FILE *fd;
char	dev[16]="/dev/";
int		c=-113;

gboolean Update(gpointer ptr) {
	
	char str[9]="", prc[4], infomsg[26];

//update icon...
    if ((fd = fopen(dev,"r+"))==NULL) { printf("Нет модема\n"); exit(1); }
	fputs("AT+CSQ\r\n",fd);
	while ((strstr(str,"+CSQ:"))==NULL) {
		fgets(str,9,fd);
		if ((strstr(str,"+CSQ:"))!=NULL) {
			int q=atoi(str+6);
			if (q==99) {
				gtk_status_icon_set_from_file(tray_icon,"/usr/share/pixmaps/no3g.png");
			}
			int l=(c + q * 2);
			printf("Сила %ddbm\n",l);
			int p=(q * 32258 / 10000);
			printf("Сигнал %d%\n",p);
			sprintf(prc,"%d",p);
			if(q<10) gtk_status_icon_set_from_file(tray_icon,"/usr/share/pixmaps/weak3g.png");
			if(q<=20) gtk_status_icon_set_from_file(tray_icon,"/usr/share/pixmaps/ok3g.png");
			else if(20<q) gtk_status_icon_set_from_file(tray_icon,"/usr/share/pixmaps/full3g.png");
		}
	} 
	fclose(fd);

//Infomsg
	infomsg[0]=0;
	strcat(infomsg,"Сигнал: ");
	strcat(infomsg,prc);
	strcat(infomsg,"% ");
	
//update tooltip...
	gtk_status_icon_set_tooltip(tray_icon,infomsg);
	return TRUE;
}

void  view_popup_menu_onAbout (GtkWidget *menuitem, gpointer userdata)
	{
		system("echo \"tray3Gcsq\"");
		GtkWidget *window, *button;

		window = gtk_window_new(GTK_WINDOW_POPUP);
		gtk_window_set_position(GTK_WINDOW(window),GTK_WIN_POS_CENTER);
		gtk_window_set_default_size(GTK_WINDOW(window), 200, 130);
		gtk_container_set_border_width (GTK_CONTAINER(window), 4);
		
		button = gtk_button_new_with_label("\"tray3Gcsq\"\n\n    GPL v2\n\n  DdShurick.");
		g_signal_connect_swapped(G_OBJECT(button),"clicked",G_CALLBACK(gtk_widget_destroy),G_OBJECT(window));
		gtk_container_add(GTK_CONTAINER(window), button);
		gtk_widget_show_all(window);

	}

void tray_icon_on_click(GtkStatusIcon *status_icon, gpointer user_data)
{
    system("/usr/bin/connect");
}

void tray_icon_on_menu(GtkStatusIcon *status_icon, guint button, guint activate_time, gpointer user_data)
{
	GtkWidget *menu, *menuitem;
    menu = gtk_menu_new();

    menuitem = gtk_menu_item_new_with_label("О программе");
    g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_onAbout, status_icon);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);

	gtk_widget_show_all(menu);
    gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL, button, gdk_event_get_time(NULL));
}

static GtkStatusIcon *create_tray_icon() {

    tray_icon = gtk_status_icon_new();
    g_signal_connect(G_OBJECT(tray_icon), "activate", G_CALLBACK(tray_icon_on_click), NULL);
    g_signal_connect(G_OBJECT(tray_icon), "popup-menu", G_CALLBACK(tray_icon_on_menu), NULL);
    gtk_status_icon_set_visible(tray_icon, TRUE);

    return tray_icon;
}

int main(int argc, char **argv) {
	
	if (!argv[1]) { printf("Пример: tray3Gcsq ttyUSB2\n"); exit(1); }
	
	gtk_init(&argc, &argv);
	strcat(dev,argv[1]);

    tray_icon = create_tray_icon();
    gtk_timeout_add(interval, Update, NULL);
    Update(NULL);

    gtk_main();

    return 0;
}

