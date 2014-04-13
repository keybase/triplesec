{WordArray} = require '../../lib/wordarray'

# need to be explicit for browserify
data_mods =
  sha1 :
    long : require '../data/sha1_long'
    short : require '../data/sha1_short'
  sha224 :
    long : require '../data/sha224_long'
    short : require '../data/sha224_short'
  sha256 :
    long : require '../data/sha256_long'
    short : require '../data/sha256_short'
  sha384 :
    long : require '../data/sha384_long'
    short : require '../data/sha384_short'
  sha512:
    long : require '../data/sha512_long'
    short : require '../data/sha512_short'
  sha3:
    long : require '../data/sha3_long'
    short : require '../data/sha3_short'

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

exports.test_sha224 = (T,cb) ->
  run_test T, require('../../lib/sha224').SHA224, 'sha224'
  cb()

exports.test_sha384 = (T,cb) ->
  run_test T, require('../../lib/sha384').SHA384, 'sha384'
  cb()

run_test = (T, klass, alg) ->
  for type in [ 'short', 'long' ]
    data = data_mods[alg][type].data
    for test,i in data
      hash = new klass()
      input = WordArray.from_hex test.Msg
      expected = test.MD.toLowerCase()
      hash.update input
      output = hash.finalize().to_hex()
      T.equal output, expected, "test vector #{alg}/#{type}/#{i}"

