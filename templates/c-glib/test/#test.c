#include "untest.h"

typedef struct {
	gchar *s;
} <%= target_camelcase %>Fixture;

void
<%= target %>_fixture_setup(<%= target_camelcase %>Fixture *fix, gconstpointer test_file)
{
	// don't freak out on g_warning()
	g_test_log_set_fatal_handler(mylog_fatal_handler, NULL);

	fix->s = g_strdup("hey");
}

void
<%= target %>_fixture_teardown(<%= target_camelcase %>Fixture *fix, gconstpointer test_file)
{
	g_free(fix->s);
}

void
test_foo()
{
	g_test_log_set_fatal_handler(mylog_fatal_handler, NULL);

	g_assert_cmpstr("zzz", ==, "zzz");
}

void
test_bar(<%= target_camelcase %>Fixture *fix,
		 gconstpointer test_file)
{
	g_assert_cmpstr("hey", ==, fix->s);
}

int
main (int argc, char **argv)
{
	g_test_init(&argc, &argv, NULL);

	g_test_add_func("/<%= target %>/foo", test_foo);
	
	g_test_add("/<%= target %>/bar", <%= target_camelcase %>Fixture, "some data",
			   <%= target %>_fixture_setup, test_bar, <%= target %>_fixture_teardown);
	
	return g_test_run();
}
