
{opts,data} = require '../data/pbkdf2'
{pbkdf2} = require '../../lib/pbkdf2'
{WordArray} = require '../../lib/wordarray'

exports.cryptojs_reference = (T,cb) ->
  for test,i in data
    run_test T, test, i
  cb()

run_test = (T, test, i) ->
  key = WordArray.from_hex test.password
  salt = WordArray.from_hex test.salt
  output_wa = pbkdf2 { key, salt, c : opts.c, dkLen : opts.dkLen }
  output = output_wa.to_hex()
  T.equal output, test.output, "Test #{i}"

