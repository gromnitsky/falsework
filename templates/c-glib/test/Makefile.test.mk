# -*- makefile -*-

GARBAGE += test-report.xml full-report.html full-report.xml

GTESTER = gtester
GTESTER_REPORT = gtester-report

# initialize variables for unconditional += appending
EXTRA_DIST +=
TEST_PROGS +=

### testing rules

# test: run all tests in cwd and subdirs
test: $(TEST_UTILS) $(tests) test-nonrecursive
	@ for subdir in $(SUBDIRS) . ; do \
		test "$$subdir" = "." -o "$$subdir" = "po" || \
		( cd $$subdir && $(MAKE) $(AM_MAKEFLAGS) $@ ) || exit $? ; \
	done

# test-nonrecursive: run tests only in cwd
test-nonrecursive: ${TEST_PROGS}
	@test -z "${TEST_PROGS}" || MALLOC_CHECK_=2 MALLOC_PERTURB_=$$(($${RANDOM:-256} % 256)) ${GTESTER} --verbose ${TEST_PROGS}

# test-report: run tests in subdirs and generate report
# perf-report: run tests in subdirs with -m perf and generate report
# full-report: like test-report: with -m perf and -m slow
test-report perf-report full-report:	${TEST_PROGS}
	@test -z "${TEST_PROGS}" || { \
	  case $@ in \
	  test-report) test_options="-k";; \
	  perf-report) test_options="-k -m=perf";; \
	  full-report) test_options="-k -m=perf -m=slow";; \
	  esac ; \
	  if test -z "$$GTESTER_LOGDIR" ; then	\
	    ${GTESTER} --verbose $$test_options -o test-report.xml ${TEST_PROGS} ; \
	  elif test -n "${TEST_PROGS}" ; then \
	    ${GTESTER} --verbose $$test_options -o `mktemp "$$GTESTER_LOGDIR/log-XXXXXX"` ${TEST_PROGS} ; \
	  fi ; \
	}
	@ ignore_logdir=true ; \
	  if test -z "$$GTESTER_LOGDIR" ; then \
	    GTESTER_LOGDIR=`mktemp -d "\`pwd\`/.testlogs-XXXXXX"`; export GTESTER_LOGDIR ; \
	    ignore_logdir=false ; \
	  fi ; \
	  if test -d "$(top_srcdir)/.git" ; then \
	    REVISION=`git describe` ; \
	  else \
	    REVISION=$(VERSION) ; \
	  fi ; \
	  for subdir in $(SUBDIRS) . ; do \
	    test "$$subdir" = "." -o "$$subdir" = "po" || \
	    ( cd $$subdir && $(MAKE) $(AM_MAKEFLAGS) $@ ) || exit $? ; \
	  done ; \
	  $$ignore_logdir || { \
	    echo '<?xml version="1.0"?>'              > $@.xml ; \
	    echo '<report-collection>'               >> $@.xml ; \
	    echo '<info>'                            >> $@.xml ; \
	    echo '  <package>$(PACKAGE)</package>'   >> $@.xml ; \
	    echo '  <version>$(VERSION)</version>'   >> $@.xml ; \
	    echo "  <revision>$$REVISION</revision>" >> $@.xml ; \
	    echo '</info>'                           >> $@.xml ; \
	    for lf in `ls -L "$$GTESTER_LOGDIR"/.` ; do \
	      sed '1,1s/^<?xml\b[^>?]*?>//' <"$$GTESTER_LOGDIR"/"$$lf" >> $@.xml ; \
	    done ; \
	    echo >> $@.xml ; \
	    echo '</report-collection>' >> $@.xml ; \
	    rm -rf "$$GTESTER_LOGDIR"/ ; \
	    ${GTESTER_REPORT} --version 2>/dev/null 1>&2 ; test "$$?" != 0 || ${GTESTER_REPORT} $@.xml >$@.html ; \
	  }

.PHONY: test test-report perf-report full-report test-nonrecursive
