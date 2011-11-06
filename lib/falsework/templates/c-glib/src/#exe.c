#include "<%= target %>.h"

int main(int argc, char **argv)
{
	g_set_prgname(basename(argv[0]));
	
	int exit_code = 0, ch;

	while ((ch = getopt(argc, argv, "qh")) != -1) {
		switch (ch) {
		case 'q':
			mylog_to(MYLOG_BITBUCKET);
			break;
		default:
			printf("Usage: %s [-q]\n", argv[0]);
			exit(1);
		}
	}
	argc -= optind;
	argv += optind;
	
	return exit_code;
}
