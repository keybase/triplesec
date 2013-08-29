
ICED=node_modules/.bin/iced
BROWSERIFY=node_modules/.bin/browserify
BUILD_STAMP=build-stamp
WD=`pwd`


lib/%.js: src/%.iced
	$(ICED) -I none -c -o lib $<

$(BUILD_STAMP): \
	lib/main.js \
	lib/wordarray.js \
	lib/algbase.js \
	lib/sha512.js
	date > $@

build: $(BUILD_STAMP)

test-server: 
	$(ICED) test/run.iced

test-browser-buffer:
	$(ICED) test/run.iced -b 

test/browser/test.js: test/browser/main.iced $(BUILD_STAMP)
	$(BROWSERIFY) -t icsify $< > $@

test-browser: test/browser/test.js
	@echo "Please visit in your favorite browser --> file://$(WD)/test/browser/index.html"

test: test-server test-browser-buffer test-browser

clean:
	rm -f lib/*.js $(BUILD_STAMP)

default: build
all: build

setup:
	npm install -d

.PHONY: clean setup test test-browser-buffer
