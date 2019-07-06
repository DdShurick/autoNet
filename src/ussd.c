/*DdShurick GPL v2 26.11.2017*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <wctype.h>
#include <wchar.h>
#include <locale.h>
#include <dirent.h>
#include <sys/types.h>
#include <signal.h>
#include <gtk/gtk.h>

#define UNICODE
#define USAGE(s) {printf("Usage:\n\tussd [-n] -i <device> -c <command>\nOptions:\n\t-h  Display help\n\t-i  modem device\n\t-c ussd command\n\t-n  not hex, text.\n"); exit(0);}
#define VERSION(s) {printf("Version 001 25.12.1016.\nDdShurick. GPL v2\n"); exit(0);}
char buf[84];//, dev[13]="/dev/";
const gchar *ussd;

char enter_callback(GtkWidget *widget, GtkWidget *entry) {

	ussd = gtk_entry_get_text(GTK_ENTRY(entry));
	gtk_main_quit ();
	
}

void septin(int num) {
	
	int i;
	char str[2]="";
	
	for(i=6; i>=0; --i) {
		sprintf(str,"%d",(num >> i)&1);
		strcat(buf,str);
	}
}

long bintohex(char *s) {
	
	long n;
	
	while (*s == '0') s++;
	
	if (strlen(s) > 32) return EOF;
	else if (*s == '\0') return 0;
	
	for (n = 0; *s != '\0'; s++) {
		if (*s == '0') continue;
		else if (*s != '1') return EOF;
		n += 01 << (strlen(s)-1);
    }
    return n;    
}

int main(int argc, char **argv) {
	
	wint_t s;
    FILE *fd, *fo;
	pid_t pid;
	setlocale(LC_ALL, "ru_RU.UTF-8");
	int c, e=0, i, n, p, l, arg=0;
	char str[11]="", str1[5]="", buf1[90]="", sussd[12]="", a[2], b[2], cmd[32]="AT+CUSD=1,";
	
	GtkWidget *window, *entry;

	gtk_init (&argc, &argv);

	window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_window_set_position(GTK_WINDOW(window),GTK_WIN_POS_CENTER);
	gtk_window_set_resizable(GTK_WINDOW(window),FALSE);
	gtk_window_set_title(GTK_WINDOW(window), "USSD --> Enter");
	
	entry = gtk_entry_new();
	gtk_entry_set_visibility(GTK_ENTRY(entry),TRUE);
	gtk_entry_set_max_length(GTK_ENTRY(entry),0);
	g_signal_connect(G_OBJECT(entry), "activate", G_CALLBACK(enter_callback), entry);
	
	gtk_container_add (GTK_CONTAINER (window), entry);
	gtk_container_set_border_width (GTK_CONTAINER (window), 7);
	
	gtk_widget_show_all (window);
	g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);
	
	gtk_main ();

	if(e==0) {
		p=strlen(ussd)-1;
//отправляем в буфер по 7 бит в обратном порядке.	
		for(p; p>=0; --p) {
			sscanf(ussd+p,"%c", &c);
			septin(c);
		}
//обнуляем переменную
		sussd[0]='\0';
//вычисляем количество недостающих бит и заполняем нулями до кратного 8	
		i = strlen(buf);
		n = 8-(i-((i/8) * 8));
		if(n!=0 && n!=8) { for(n; n>0; --n) strcat(buf1,"0"); }
		strcat(buf1,buf);
//читаем по 8 бит бит в обратном порядке, разбиваем пополам и по одному знаку перекодируем в hex	
		str[sizeof str-1] = '\0';
		l = strlen(buf1)-8;
		for(l; l>=0; l=l-8) {
			strncpy(str,buf1+l,8);
			strncpy(str1,str,4);
			sprintf(a,"%lX", bintohex(str1));
			strcat(sussd,a);
			sprintf(b,"%lX", bintohex(str+4));
			strcat(sussd,b);
		}
	}
//Отправляем команду
	if ((fd = fopen("/dev/modem_cli","r+"))==NULL) {
		if ((fd = fopen("/dev/modem","r+"))==NULL) {
			printf("Модем недоступен\n");
			exit(1);
		}
	}
	strcat(cmd,sussd);
	strcat(cmd,",15\n");
	fputs(cmd,fd);//AA18AC3602 - *105#; AA180C3602 - *100#; AA1C0CA682C546 - *900*01# СБРФ
//проверка портов на молчание.	
	switch(pid=fork()) {
		case -1:
			perror("fork");
			exit(1);
		case 0:
			sleep(5);
			fclose(fd);
			printf("Нет ответа\n");
			kill(getppid(),15);
			raise(15);
			exit (0);
		default:
			fo = fopen("/tmp/ussd_answer","w"); //
			while ((strstr(str,"\","))==NULL) {
				fgets(str,11,fd);
				if ((strstr(str,"+CUSD:"))!=NULL) {
					while ((strstr(str,"\","))==NULL) {
						fgets(str,5,fd);
						sscanf(str,"%x", &s);
						putwchar(s);
						putwc(s,fo);//
					}
					fclose(fd);
					putwchar('\n');
					fclose(fo); //
					kill(pid,15);
				}
			}
		
	}	
	system("/usr/bin/leafpad /tmp/ussd_answer & ");
//факт налицо :)
	return 0;
}
