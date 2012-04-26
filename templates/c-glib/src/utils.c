#include <iconv.h>

#include "utils.h"

/* The result should be freed with g_free(). */
gchar *
text2utf8(const gchar *buf, const gchar *from) {
	gsize br, bw;
	if (!buf) return NULL;
	if (!from) return (gchar*)buf;

	if (g_regex_match_simple("utf.?8", from, G_REGEX_CASELESS, 0))
		return g_strdup(buf); // prevent converting from utf8 to utf8
	else 
		return g_convert_with_fallback(buf, -1, "UTF-8", from,
									   NULL, &br, &bw, NULL);
}

/*
  Take a variable number of arguments and return the pointer to the
  first non-NULL one. The argument list must end with &sentinel.
 */
char
*first(char *first, ...)
{
	va_list ap;
    char *r = first;

    va_start(ap, first);
    while (!r) {
        r = va_arg(ap, char*);
    }
	va_end(ap);

    return r == &sentinel ? NULL : r;
}

/*
  Read @fd till EOF and return the a null-terminated result with the
  size of the string in @len (pass NULL if you're not interested).

  The result should be freed with g_free().
 */
gchar*
chan_read(int fd, gsize *len)
{
	gsize n;
	gchar buf[BUFSIZ];
	gsize size = 0;
	gchar *r = g_malloc((BUFSIZ+1) * sizeof *buf);
	
	while ( (n = readn(fd, buf, BUFSIZ)) > 0) {
		memmove(r+size, buf, n);
		size += n;
		
		gchar *tmp = g_realloc(r, (size+BUFSIZ+1) * sizeof *tmp);
		if (!tmp) {
			g_free(r);
			g_warning("realloc failed");
			size -= n;
			break;
		}
		r = tmp;
	}
	r[size] = '\0';
	if (len) *len = size;
	return r;
}

gboolean
pr_exit_warn(const char *cmd, int status)
{
	gboolean ok = TRUE;
	
    if (WIFEXITED(status)) {
		if (WEXITSTATUS(status) != 0) {
			g_warning("%s: unexpected termination, exit status %d",
					  cmd, WEXITSTATUS(status));
			ok = FALSE;
		}
	} else if (WIFSIGNALED(status)) {
        g_warning("%s: abnormal termination, signal number %d",
				  cmd, WTERMSIG(status));
		ok = FALSE;
	} else if (WIFSTOPPED(status)) {
        printf("%s: child stopped, signal number %d",
			   cmd, WSTOPSIG(status));
		ok = FALSE;
	}

	return ok;
}

ssize_t						/* Read "n" bytes from a descriptor. */
readn(int fd, void *vptr, size_t n)
{
	size_t	nleft;
	ssize_t	nread;
	char	*ptr;

	ptr = vptr;
	nleft = n;
	while (nleft > 0) {
		if ( (nread = read(fd, ptr, nleft)) < 0) {
			if (errno == EINTR)
				nread = 0;		/* and call read() again */
			else
				return(-1);
		} else if (nread == 0)
			break;				/* EOF */

		nleft -= nread;
		ptr   += nread;
	}
	return(n - nleft);		/* return >= 0 */
}

ssize_t						/* Write "n" bytes to a descriptor. */
writen(int fd, const void *vptr, size_t n)
{
	size_t		nleft;
	ssize_t		nwritten;
	const char	*ptr;

	ptr = vptr;
	nleft = n;
	while (nleft > 0) {
		if ( (nwritten = write(fd, ptr, nleft)) <= 0) {
			if (nwritten < 0 && errno == EINTR)
				nwritten = 0;		/* and call write() again */
			else
				return(-1);			/* error */
		}

		nleft -= nwritten;
		ptr   += nwritten;
	}
	return(n);
}

/*
  Removes all leading & trailing whitespace + replaces \n, \t, \r to 1
  space. Modifies @s in place.
 */
GString*
my_strstrip(GString *s)
{
	if (!s) return NULL;
	GRegex *re = g_regex_new("[\n\r\t]+", 0, 0, NULL);
	char *tmp = g_regex_replace_literal(re, s->str, s->len, 0, " ", 0, NULL);
	g_regex_unref(re);
	
	if (!tmp) return s;
	g_strstrip(tmp);
	g_string_assign(s, tmp);
	g_free(tmp);
	return s;
}

/* A callback handler for mylog_to(). */
void
mylog_to_devnull(const gchar *log_domain, GLogLevelFlags log_levels,
				 const gchar *message, gpointer user_data)
{
	/* do nothing, eat all messages */
}

/*
  Same as g_warning() + exit(1).
 */
void myerr(const gchar *format, ...)
{
	if (!format) {
		g_warning("unspecified error");
		exit(1);
	}

	va_list args;
	va_start(args, format);
	g_logv(G_LOG_DOMAIN, G_LOG_LEVEL_WARNING, format, args);
	va_end (args);

	exit(1);
}

/*
  Switch destination of logs according to @d.
 */
void
mylog_to(MyLogDest d)
{
	switch (d) {
	case MYLOG_BITBUCKET:
		g_log_set_handler(NULL, G_LOG_LEVEL_WARNING|G_LOG_LEVEL_CRITICAL,
						  mylog_to_devnull, NULL);
		break;
	case MYLOG_FILES:
		g_error("MYLOG_FILES is unimplemented");
		break;
	default:
		// reset ot glib's default
		g_log_set_handler(NULL, G_LOG_LEVEL_WARNING|G_LOG_LEVEL_CRITICAL,
						  g_log_default_handler, NULL);
		break;
	}
}

/*
  Do case insensitive regexp replace in @s in place.

  Return FALSE on error. Warning: TRUE doens't mean that something was
  actually replaced.
 */
gboolean
my_regsub(GString* s, const gchar *re, const gchar *sub)
{
	if (!s || !re || !sub) return FALSE;
	gboolean r = FALSE;
	GError *e = NULL;
	
	GRegex *pattern = g_regex_new(re, G_REGEX_CASELESS|G_REGEX_MULTILINE, 0, NULL);
	char *t = g_regex_replace(pattern, s->str, -1, 0, sub, 0, &e);
	if (e == NULL && t) {
		g_string_assign(s, t);
		r = TRUE;
	}
	
	g_regex_unref(pattern);
	g_free(t);
	g_clear_error(&e);
	return r;
}
