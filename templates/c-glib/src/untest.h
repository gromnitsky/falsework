#ifndef UNTEST_H
#define UNTEST_H

/*
  Routines useful only for unit tests and glib's test framework.
 */

#include "<%= @project %>.h"

gboolean
mylog_fatal_handler(const gchar *log_domain, GLogLevelFlags log_level,
					const gchar *message, gpointer user_data);

#endif // UNTEST_H
