{WordArray} = require '../../lib/wordarray'

exports.test_sha1 = (T,cb) ->
  run_test T, require('../../lib/sha1').SHA1, 'sha1'
  cb()

exports.test_sha512 = (T,cb) ->
  run_test T, require('../../lib/sha512').SHA512, 'sha512'
  cb()

exports.test_sha3 = (T,cb) ->
  run_test T, require('../../lib/sha3').SHA3, 'sha3'
  cb()

exports.test_sha256 = (T,cb) ->
  run_test T, require('../../lib/sha256').SHA256, 'sha256'
  cb()

run_test = (T, klass, alg) ->
  for type in [ 'short', 'long' ]
    data = require("../data/#{alg}_#{type}").data
    for test,i in data
      hash = new klass()
      input = WordArray.from_hex test.Msg
      expected = test.MD.toLowerCase()
      hash.update input
      output = hash.finalize().to_hex()
      T.equal output, expected, "test vector #{alg}/#{type}/#{i}"

