#include <stdio.h>
#include <stdlib.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <glib/gstdio.h>
//GError *gerror;
//GdkPixbuf *hd_pixbuf;
GtkStatusIcon *tray_icon;

void  view_popup_menu_on_doc (GtkWidget *menuitem, gpointer userdata)
{ system("/usr/local/bin/defaulthtmlviewer -g /usr/share/doc/upNet/upNet.html & ");	}

void  view_popup_menu_on_PPPoE (GtkWidget *menuitem, gpointer userdata)
{ system("/usr/bin/pppoeconf & ");	}

void  view_popup_menu_on_StatIP (GtkWidget *menuitem, gpointer userdata)
{ system("/usr/bin/tunstatic");  }

static void tray_icon_on_menu(GtkStatusIcon *status_icon, guint button, guint activate_time, gpointer user_data)
{
	GtkWidget *menu, *menuitem;
    menu = gtk_menu_new();
	
	menuitem = gtk_menu_item_new_with_label("Руководство");
    g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_on_doc, status_icon);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
	
    menuitem = gtk_menu_item_new_with_label("Настроить PPPoE");
    g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_on_PPPoE, status_icon);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
    
    menuitem = gtk_menu_item_new_with_label("Настроить Static IP");
    g_signal_connect(menuitem, "activate", (GCallback) view_popup_menu_on_StatIP, status_icon);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), menuitem);
    
    gtk_widget_show_all(menu);
    gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL, button, gdk_event_get_time(NULL));
}
   
static void tray_icon_on_click(GtkStatusIcon *status_icon, gpointer user_data)
{
    system("connect");
}

static GtkStatusIcon *create_tray_icon() {

    tray_icon = gtk_status_icon_new();
    g_signal_connect(G_OBJECT(tray_icon), "activate", G_CALLBACK(tray_icon_on_click), NULL);
    g_signal_connect(G_OBJECT(tray_icon), "popup-menu", G_CALLBACK(tray_icon_on_menu), NULL);
	gtk_status_icon_set_from_stock(tray_icon,"gtk-network");
	gtk_status_icon_set_tooltip(tray_icon," Настроить интернет ");
    gtk_status_icon_set_visible(tray_icon, TRUE);
    return tray_icon;
} 
   
int main(int argc, char **argv) {
	
	gtk_init(&argc, &argv);
	tray_icon = create_tray_icon();
	gtk_main();
	
	return 0;
}
