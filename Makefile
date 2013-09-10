
ICED=node_modules/.bin/iced
BROWSERIFY=node_modules/.bin/browserify
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp
WD=`pwd`

BROWSER=browser/triplesec.js

default: build
all: build

lib/%.js: src/%.iced
	$(ICED) -I none -c -o lib $<

$(BUILD_STAMP): \
	lib/main.js \
	lib/wordarray.js \
	lib/algbase.js \
	lib/sha512.js \
	lib/util.js \
	lib/hmac.js \
	lib/aes.js \
	lib/twofish.js \
	lib/ctr.js \
	lib/salsa20.js \
	lib/pbkdf2.js \
	lib/enc.js \
	lib/dec.js \
	lib/rng.js \
	lib/drbg.js
	date > $@

$(BROWSER): lib/main.js $(BUILD_STAMP)
	$(BROWSERIFY) -s triplesec $< > $@

build: $(BUILD_STAMP) $(BROWSER)

test-server: $(TEST_STAMP) $(BUILD_STAMP)
	$(ICED) test/run.iced

test-browser-buffer: $(TEST_STAMP) $(BUILD_STAMP)
	$(ICED) test/run.iced -b 

test/browser/test.js: test/browser/main.iced $(BUILD_STAMP)
	$(BROWSERIFY) -t icsify $< > $@

test-browser: $(TEST_STAMP) $(BUILD_STAMP)
	@echo "Please visit in your favorite browser --> file://$(WD)/test/browser/index.html"

$(TEST_STAMP): test/data/sha512_short.js \
		test/data/sha512_long.js \
		test/data/twofish_ecb_tbl.js \
		test/data/salsa20_key128.js \
		test/data/salsa20_key256.js \
		test/data/pbkdf2.js \
		test/data/drbg_hmac_no_reseed.js \
		test/browser/test.js 
	date > $@

test/data/%.js: test/gen/gen_%.iced
	@mkdir -p test/data
	$(ICED) $< > $@

test: test-server test-browser-buffer test-browser

clean:
	rm -f lib/*.js $(BUILD_STAMP) $(TEST_STAMP)


setup:
	npm install -d

.PHONY: clean setup test test-browser-buffer
