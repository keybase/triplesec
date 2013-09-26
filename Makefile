
ICED=node_modules/.bin/iced
RSP2JSON=node_modules/.bin/rsp2json
BROWSERIFY=node_modules/.bin/browserify
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp
UGLIFYJS=node_modules/.bin/uglifyjs
WD=`pwd`

BROWSER=browser/triplesec.js

default: build
all: build

lib/%.js: src/%.iced
	$(ICED) -I browserify -c -o lib $<

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
	lib/prng.js \
	lib/drbg.js \
	lib/lock.js \
	lib/sha3.js \
	lib/combine.js \
	lib/sha1.js
	date > $@

$(BROWSER): lib/main.js $(BUILD_STAMP)
	$(BROWSERIFY) -s triplesec $< > $@

build: $(BUILD_STAMP) $(BROWSER) site

site: site/js/site.js

site/js/site.js: site/iced/site.iced
	$(ICED) -I window --print $< > $@

test-server: $(TEST_STAMP) $(BUILD_STAMP)
	$(ICED) test/run.iced

test-browser-buffer: $(TEST_STAMP) $(BUILD_STAMP)
	$(ICED) test/run.iced -b 

test/browser/test.js: test/browser/main.iced $(BUILD_STAMP)
	$(BROWSERIFY) -t icsify $< > $@

test-browser: $(TEST_STAMP) $(BUILD_STAMP)
	@echo "Please visit in your favorite browser --> file://$(WD)/test/browser/index.html"

test/json/HMAC_DRBG_reseed.json: test/rsp/HMAC_DRBG_reseed.rsp
	@mkdir -p test/json/
	$(RSP2JSON) $< > $@

test/json/SHA3_short.json: test/rsp/SHA3_short.rsp
	@mkdir -p test/json/
	$(RSP2JSON) $< > $@
	
test/json/SHA3_long.json: test/rsp/SHA3_long.rsp
	@mkdir -p test/json/
	$(RSP2JSON) $< > $@

test/json/SHA1ShortMsg.json: test/rsp/SHA1ShortMsg.rsp
	@mkdir -p test/json/
	$(RSP2JSON) $< > $@
	
test/json/SHA1LongMsg.json: test/rsp/SHA1LongMsg.rsp
	@mkdir -p test/json/
	$(RSP2JSON) $< > $@

spec/triplesec.json: ref/gen_triplesec_spec.iced
	$(ICED) $< $ > $@
spec/pbkdf2_sha512_sha3.json: ref/gen_pbkdf2_sha512_sha3_spec.iced
	$(ICED) $< $ > $@

test/data/triplesec_spec.js: spec/triplesec.json 
	$(ICED) test/gen/spec2js.iced "../../spec/triplesec.json" > $@
test/data/pbkdf2_sha512_sha3_spec.js: spec/pbkdf2_sha512_sha3.json 
	$(ICED) test/gen/spec2js.iced "../../spec/pbkdf2_sha512_sha3.json" > $@

$(TEST_STAMP): test/data/sha512_short.js \
		test/data/sha512_long.js \
		test/data/twofish_ecb_tbl.js \
		test/data/salsa20_key128.js \
		test/data/salsa20_key256.js \
		test/data/pbkdf2.js \
		test/data/drbg_hmac_no_reseed.js \
		test/json/HMAC_DRBG_reseed.json \
		test/data/drbg_hmac_reseed.js \
		test/json/SHA3_short.json \
		test/data/sha3_short.js \
		test/json/SHA3_long.json \
		test/data/sha3_long.js \
		test/data/triplesec_spec.js \
		test/data/pbkdf2_sha512_sha3_spec.js \
		test/json/SHA1ShortMsg.json \
		test/json/SHA1LongMsg.json \
		test/data/sha1_short.js \
		test/data/sha1_long.js \
		test/browser/test.js 
	date > $@

release: browser/triplesec.js
	V=`jsonpipe < package.json | grep version | awk '{ print $$2 }' | sed -e s/\"//g` ; \
	cp $< rel/triplesec-$$V.js ; \
	$(UGLIFYJS) -c < rel/triplesec-$$V.js > rel/triplesec-$$V-min.js 

test/data/%.js: test/gen/gen_%.iced
	@mkdir -p test/data
	$(ICED) $< > $@

spec: spec/triplesec.json spec/pbkdf2_sha512_sha3.json

test: test-server test-browser

clean:
	rm -f lib/*.js $(BUILD_STAMP) $(TEST_STAMP)

doc:
	node_modules/.bin/codo

setup:
	npm install -d

.PHONY: clean setup test test-browser-buffer doc spec
