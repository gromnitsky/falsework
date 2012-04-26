#ifndef UTILS_H
#define UTILS_H

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/param.h>
#include <sys/uio.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>
#include <limits.h>

#include <glib.h>

/* Logging destination */
typedef enum _MyLogDest {
	MYLOG_CONSOLE,
	MYLOG_FILES,
	MYLOG_BITBUCKET
} MyLogDest;

/* Used with first(), because of its address is unique among other
   pointers. */
char sentinel; 

gchar *text2utf8(const gchar *buf, const gchar *from);
char *first(char *first, ...);
gchar* chan_read(int fd, gsize *len);

gboolean pr_exit_warn(const char *cmd, int status);

GString* my_strstrip(GString *s);
gboolean my_regsub(GString* s, const gchar *re, const gchar *sub);

void mylog_to(MyLogDest d);
void mylog_to_devnull(const gchar *log_domain, GLogLevelFlags log_levels,
					  const gchar *message, gpointer user_data);
void myerr(const gchar *format, ...);

ssize_t readn(int fd, void *vptr, size_t n);
ssize_t writen(int fd, const void *vptr, size_t n);

#endif // UTILS_H
