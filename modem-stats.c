/* Send a command to a modem, and echo the modem's response.
 *
 * This program is typically used to document a modem's status after a
 * connection, and may also be used to gather accounting statistics.
 *
 * This program may also be used to reset a modem,
 * or send an initialization string to a modem.
 *
 * This program may be freely copied and used, as long as this header,
 * the accompanying documentation, and the author's name remain intact.
 *
 * Copyright (c) 1995, Kenneth J. Hendrickson
 *	kjh@usc.edu, kjh@seas.smu.edu
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

#define	USAGE		"Usage: %s [-c command] [-e end_string] device\n"

#define	STRLEN		80

char	command[STRLEN+1] = "AT I6\r";	/* command to feed to modem */
char	end_string[STRLEN+1] = "OK";	/* end of modem response */
char	response[STRLEN+1];		/* response from modem */

char	*progname;			/* this program */
char	*devname;			/* the modem name */
FILE	*device;			/* the modem itself */

#define	ALARM		5		/* modem must respond in ALARM secs */
int	alarms = 0;			/* number of times the alarm rang */

void	modem();			/* send command, print response */
void	no_response();			/* timeout alarm handler */

int	optind;				/* used for counting options */
char	*optarg;			/* used for holding option arguments */

int
main(argc, argv)
int	argc;
char	**argv;
{
	int	opt;

	progname = argv[0];		/* set the program name */

	/* Parse the options. */
	while ((opt = getopt(argc, argv, "c:e:")) != -1) {
		switch (opt) {
			case 'c':	/* modem command string */
				strncpy(command, optarg, STRLEN-1);
				strcat(command, "\r");
				break;
			case 'e':	/* end of modem response */
				strncpy(end_string, optarg, STRLEN);
				/*strcat(end_string, "\r");*/
				/*strcat(end_string, "\n");*/
				break;
			case ':':	/* missing option */
			case '?':	/* unknown option character */
			default:
				fprintf(stderr, USAGE, progname);
				exit(1);
				break;
		}
	}

	devname = argv[optind];		/* set the device name */
	if (!devname) {
		/* No device file was specified.  Give usage message. */
		fprintf(stderr, USAGE, progname);
		exit(1);
	}

	/* Can we read and write to the device file? */
	if ((device = fopen(devname, "r+")) == NULL) {
		fprintf(stderr,
			"%s: Can't open %s for reading and writing.\n",
			progname, devname);
		fprintf(stderr, USAGE, progname);
		exit(1);
	}

	/* Occasionally, after using the modem on a ppp or slip link,
	 * there will be garbage left over that may confuse modem-stats.
	 * Therefore, flush the garbage in a dry run with no output.
	 */
	modem(0);

	modem(1);			/* Now do it for real. */
	exit(0);			/* We succeeded. */
}

void
modem(print)
int	print;				/* 0=dry run, 1=the real thing */
{
	int	command_len = strlen(command)-1;	/* ignore the '\r' */
	int	end_len = strlen(end_string);
	int	scan = 0;

	/* Output the command to the device. */
	if (fputs(command, device) == EOF) {
		fprintf(stderr,
			"%s: Failure writing to %s.\n", progname, devname);
		exit(1);
	}
	fflush(device);

	/* Set the alarm, in case the device doesn't answer. */
	(void) signal(SIGALRM, no_response);
	(void) alarm(ALARM);

	/* Read the device's response, and echo to stdout. */
	while (fgets(response+scan, STRLEN-scan, device) != NULL) {
		scan = 0;
		/* Echo the response, up to and including end_string. */
		while (strlen(response)-scan >= end_len) {
			/* Remove any extra blank lines from output. */
			if (print && strncmp(response+scan, "\n\n", 2) == 0) {
				fputc('\n', stdout);
				scan += 2;
				continue;
			}
			if (print && strncmp(response+scan, "\n\r\n", 3) == 0) {
				fputc('\n', stdout);
				scan += 3;
				continue;
			}
			/* Check for an echo of the command. */
			if (strncmp(response+scan, command, command_len) == 0) {
				/* Ignore the echo of the command. */
				scan += command_len;
				if (response[scan] == '\r')
					scan++;
				if (response[scan] == '\n')
					scan++;
				continue;
			}
			/* Check for the terminating end_string */
			if (strncmp(response+scan, end_string, end_len) == 0 &&
			    (response[scan+end_len] == '\r' ||
			     response[scan+end_len] == '\n') &&
			    /* Don't be fooled by OFF HOOK messages. */
			    (scan == 0 || response[scan-1] == '\n')) {
				/* We found end_string.  We're done. */
				(void) alarm(0);	/* reset the alarm */
				/* Print the end_string. */
				if (print) {
					fputs(end_string, stdout);
					fputc('\n', stdout);
				} 
				return;
			}
			/* Response other than command echo or end_string */
			if (print && response[scan] != '\r') {
				fputc(response[scan], stdout);
			}
			scan++;
		}
		/* Save what we haven't yet been able to process. */
		memmove(response, response+scan, strlen(response+scan)+1);
		scan = strlen(response);
	}

	/* We encountered either EOF or an error.  Do nothing. */
}

void
no_response(i)
int	i;
{
	alarms++;			/* The alarm went off again. */

	/* The device didn't respond within ALARM seconds. */

	if (alarms < 2) {
		modem(1);		/* Try again, this time for real. */
		exit(0);		/* This time we succeeded. */
	} else {
		/* We failed too many times. */
		fprintf(stdout,
			"%s: No response from %s.\n", progname, devname);
		exit(3);
	}
}

