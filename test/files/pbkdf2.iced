
{opts,data} = require '../data/pbkdf2'
{pbkdf2} = require '../../lib/pbkdf2'
{WordArray} = require '../../lib/wordarray'

exports.cryptojs_reference = (T,cb) ->
  for test,i in data
    await run_test T, test, i, defer()
  cb()

run_test = (T, test, i, cb) ->
  key = WordArray.from_hex test.password
  salt = WordArray.from_hex test.salt
  await pbkdf2 { key, salt, c : opts.c, dkLen : opts.dkLen }, defer output_wa
  output = output_wa.to_hex()
  T.equal output, test.output, "Test #{i}"
  cb()

