.PHONY : clean

MAN_ASCIIDOC := $(wildcard *.1.asciidoc)
MAN := $(patsubst %.1.asciidoc,%.1,$(wildcard *.1.asciidoc))

all: $(MAN)

%.1: %.1.asciidoc
	a2x -f manpage $<

clean:
	rm -f $(MAN)

# Debug. Use 'gmake p-obj' to print $(obj) variable.
p-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
