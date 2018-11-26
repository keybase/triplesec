
{opts,data} = require '../data/pbkdf2'
{pbkdf2} = require '../../lib/pbkdf2'
{WordArray} = require '../../lib/wordarray'
spec = require '../data/pbkdf2_sha512_sha3_spec'
{XOR} = require '../../lib/combine'

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

test_vector = (T, v, i, cb) ->
  v.key = WordArray.from_hex v.key
  v.salt = WordArray.from_hex v.salt
  v.klass = XOR
  await pbkdf2 v, defer dk
  T.equal v.dk, dk.to_hex(), "PBKDF Test vector #{i}"
  T.waypoint "PBKDF Test vector #{i}"
  cb()

exports.test_pbkdf2_sha512_sha3 = (T,cb) ->
  for v,i in spec.data
    await test_vector T,v,i,defer()
  cb()
