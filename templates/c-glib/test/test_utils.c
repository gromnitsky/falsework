#include "untest.h"

void test_text2utf8()
{
	char *ru_utf8 = "\u0430\u0439\u043D\u044D\u043D\u044D";
	char *ru_1251 = "\xE0\xE9\xED\xFD\xED\xFD";

	char *r = text2utf8(ru_1251, "windows-1251");
	g_assert(strcmp(r, ru_utf8) == 0);
	g_free(r);

	r = text2utf8(ru_utf8, "UTF-8");
	g_assert(strcmp(r, ru_utf8) == 0);
	g_free(r);

	g_assert_cmpstr(ru_1251, ==, text2utf8(ru_1251, NULL));
	g_assert_cmpstr(NULL, ==, text2utf8(NULL, "windows-1251"));
	g_assert_cmpstr(NULL, ==, text2utf8(NULL, NULL));
}

void
test_my_strstrip()
{
	GString *s = g_string_new("");

	g_assert(!my_strstrip(NULL));

	char *t1[] = { "q", "\t  q\t", "\t\n\n  q\t\n\r", NULL };
	char **p;
	for (p = t1; *p; ++p) {
		g_string_assign(s, *p);
		my_strstrip(s);
		g_assert_cmpstr(s->str, ==, "q");
		g_assert_cmpint(s->len, ==, strlen("q"));
	}

	char *t2[] = { "", "\t  \t", " ", NULL };
	for (p = t2; *p; ++p) {
		g_string_assign(s, *p);
		my_strstrip(s);
		g_assert_cmpstr(s->str, ==, "");
		g_assert_cmpint(s->len, ==, 0);
	}

	g_string_assign(s, "This is\na text & only text.");
	my_strstrip(s);
	g_assert_cmpstr("This is a text & only text.", ==, s->str);

	g_string_free(s, TRUE);
}

void
test_first()
{
	char *q = NULL;
	char *w = NULL;
	char *e = "zzz";
	char *r = NULL;

	g_assert(first(q, w, e, r, &sentinel) == e);
	g_assert(first(r, e, w, q, &sentinel) == e); // reverse
	g_assert(first(e, &sentinel) == e);
	g_assert(first(e, q, w, r, &sentinel) == e);
	g_assert(first(q, w, r, e, &sentinel) == e);
	g_assert(first(q, w, r, &sentinel) == NULL);
	g_assert(first(q, &sentinel) == NULL);
	g_assert(first(NULL, &sentinel) == NULL);
	g_assert(first(NULL, NULL, &sentinel) == NULL);
}

void
test_chan_read()
{
	struct Cmd {
		char *c;
		gsize bytes;
		char *md5;
	} cmd[] = {
		{ "./mycat < semis/text/empty.txt", 0, "d41d8cd98f00b204e9800998ecf8427e" },
		{ "./mycat < Makefile.test.mk", 2753, "f25fbc27b05cf7a33b6d01eb5a0bedb9" },
		// delete this line if you don't have wordnet installed
//		{ "./mycat < /usr/share/wordnet-3.0/dict/data.noun", 15300280, "a51f8a16db5be01db3ae95367469c6c7" },
		{ NULL, -1, NULL }
	};

	struct Cmd *p;
	for (p = cmd; p->c; ++p) {
		FILE* f = popen(p->c, "r");
		g_assert(f);

		char buf[p->bytes];
		gsize bytes = readn(fileno(f), buf, p->bytes);
		pclose(f);

		g_assert_cmpint(p->bytes, ==, bytes);
		gchar *md5 = g_compute_checksum_for_string(G_CHECKSUM_MD5, buf, p->bytes);
		g_assert_cmpstr(p->md5, ==, md5);
		g_free(md5);
	}
}

void
test_mylog_set()
{
	mylog_to(MYLOG_BITBUCKET);
	if (g_test_trap_fork(0, G_TEST_TRAP_SILENCE_STDERR)) {
		g_message("so you say you like logs");
		exit(0); // successful test run
    }
	g_test_trap_assert_passed();
	g_test_trap_assert_stderr(NULL);

	mylog_to(MYLOG_CONSOLE);
	if (g_test_trap_fork(0, G_TEST_TRAP_SILENCE_STDERR)) {
		g_message("so you say you like logs");
		exit(0); // successful test run
    }
	g_test_trap_assert_passed();
	g_test_trap_assert_stderr("*so you say you like logs*");
}

int
main (int argc, char **argv)
{
	g_test_init (&argc, &argv, NULL);

	g_test_add_func("/utils/text2utf8", test_text2utf8);
	g_test_add_func("/utils/my_strstrip", test_my_strstrip);
	g_test_add_func("/utils/first", test_first);
	g_test_add_func("/utils/chan_read", test_chan_read);
	g_test_add_func("/utils/mylog_set", test_mylog_set);

	return g_test_run();
}
