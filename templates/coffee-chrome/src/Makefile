BROWSERIFY := ../node_modules/.bin/browserify
COFFEE := ../node_modules/.bin/coffee

out := ../lib
html := $(wildcard *.html)
out_html := $(patsubst %.html,$(out)/%.html,$(html))

# compiled & bundled this will go to $(out)
coffee := background.coffee

out_js := $(patsubst %.coffee,$(out)/%.js,$(coffee))
temp_js := $(patsubst %.coffee,%.js,$(wildcard *.coffee))

.PHONY: compile clean

all: compile

#$(out)/background.js: foo.js

%.js: %.coffee
	$(COFFEE) -c $<

$(out)/%.js: %.js
	@mkdir -p `dirname $@`
	$(BROWSERIFY) $< -o $@

$(out)/%.html: %.html
	cp $< $@

compile: $(temp_js) $(out_js) $(out_html)

clean:
	rm -f $(out_js) $(temp_js) $(out_html)

# Debug. Use 'gmake p-obj' to print $(obj) variable.
p-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)
