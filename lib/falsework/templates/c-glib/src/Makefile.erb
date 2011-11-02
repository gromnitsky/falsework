gnome := glib-2.0

CFLAGS := -Wall -Wno-pointer-sign \
	-I/usr/local/include \
        $(shell pkg-config --cflags $(gnome) )

LDFLAGS := $(shell pkg-config --libs $(gnome) )

exe := <%= @project %>
obj := $(patsubst %.c,%.o,$(wildcard *.c))

.SECONDEXPANSION:

all: $(obj) $(exe)

$(obj): <%= @project %>.h

<%= @project %>.o: <%= @project %>.h

<%= @project %>: utils.o $$@.o
	$(CC) $^ -o $@ $(CFLAGS) $(LDFLAGS)

clean:
	rm -rf $(exe) $(obj) *.core

print-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
