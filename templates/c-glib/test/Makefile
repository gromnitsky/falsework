# -*- makefile -*-

# All tests file names must be in test_xxx.c format. If your tests leave
# temporal files, add them to GARBAGE variable below.
#
# Any xxx.c file will be compiled in xxx file. If you need compile some
# xxx.c file before running tests, add xxx to TEST_UTILS variable below.
#
#
# Targets:
#
# test -- run tests
# tests -- compile tests
# exe -- compile *.c files except tests

where-am-i = $(CURDIR)/$(lastword $(MAKEFILE_LIST))
mk_location := $(realpath $(call where-am-i))
mk_dir := $(dir $(mk_location))

GARBAGE := 

gnome := glib-2.0

# main source tree
proj_src := $(mk_dir)../src
VPATH := $(proj_src)

CFLAGS := -Wall -Wno-pointer-sign -std=c99 -fPIC -pedantic \
	-I$(proj_src) \
	$(shell pkg-config --cflags $(gnome) ) \
	-I/usr/local/include

LDFLAGS := $(shell pkg-config --libs $(gnome) )

# in this dir
tests := $(basename $(wildcard test_*.c) )
exe := $(filter-out $(tests),$(basename $(wildcard *.c)) )

# in the source tree
obj_srcall := $(notdir $(patsubst %.c,%.o,$(wildcard $(proj_src)/*.c)) )
# c files with main function in them
src_exe = $(shell ruby -e 'ARGV.each {|i| print(File.basename(i)+" ") if File.read(i) =~ /[[:space:];]*(int|void)\s+main\s*\([^)(]*\)\s*{/ }' $(proj_src)/*.c )
# exclude $src_exe from to be compiled .o files
obj_srcexe := $(patsubst %.c,%.o,$(src_exe)) <%= @project %>.o
obj_src := $(filter-out $(obj_srcexe),$(obj_srcall))
src_h := $(patsubst %.c,%.o,$(wildcard $(proj_src)/*.h))

# generate test targets for glib test framework
TEST_PROGS := $(tests)
# execs required for tests
TEST_UTILS := mycat

.SECONDEXPANSION:

.PHONY: tests exe clean

all: tests

tests: $(tests)
exe: $(exe)

$(tests): $$@.o $(obj_src)
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS)

$(obj_src): $(src_h)

$(exe): $$@.o $(obj_src)
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS)

include $(mk_dir)/Makefile.test.mk

clean:
	rm -rf *.core $(tests) $(tests:=.o) \
		$(exe) $(exe:=.o) $(obj_src) $(GARBAGE)

print-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
