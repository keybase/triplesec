
argv = require('optimist').alias('b', 'browser').boolean('browser').argv

wl = if argv._.length > 0 then argv._ else null

if argv.browser
  buf = require '../lib/buffer'
  buf.force require('../lib/browser').PpBuffer

require('iced-test').run { mainfile : __filename, whitelist : wl, files_dir : "files" }
