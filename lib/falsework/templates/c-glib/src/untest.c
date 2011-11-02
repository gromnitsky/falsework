#include "untest.h"

/* A callback handler for g_test_log_set_fatal_handler(). */
gboolean
mylog_fatal_handler(const gchar *log_domain, GLogLevelFlags log_level,
					const gchar *message, gpointer user_data)
{
	return FALSE;
}
