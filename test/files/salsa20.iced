
data = 
  key128 : require('../data/salsa20_key128').data
  key256 : require('../data/salsa20_key256').data

{Salsa20} = require '../../lib/salsa20'
{WordArray} = require '../../lib/wordarray'

test_case = (T, i, test) ->
  key = WordArray.from_hex_le test.key
  iv = WordArray.from_hex_le test.IV
  stream = new Salsa20 key, iv
  i = 0
  for part in test.stream
    if i < part.low
      stream.getBytes(part.low - i)
    bytes = stream.getBytes(part.hi - part.low + 1)
    i = part.hi + 1
    T.equal bytes.toString('hex'), part.bytes.toLowerCase(), "Case #{i}: #{test.desc}"

run_tests = (T, which, cb) ->
  for test,i in data[which]
    test_case T, i, test
  cb()

exports.key256 = (T, cb) ->
  run_tests T, 'key256', cb
exports.key128 = (T, cb) ->
  run_tests T, 'key128', cb#

exports.nonce192 = (T, cb) ->
  # From here:
  #  https://code.google.com/p/go/source/browse/salsa20/salsa20_test.go?repo=crypto
  #
  v = 
    "nonce" : "24-byte nonce for xsalsa"
    "key" : "this is 32-byte key for xsalsa20"
    "ciphertext" : [ 0x48, 0x48, 0x29, 0x7f, 0xeb, 0x1f, 0xb5, 0x2f, 0xb6,
                    0x6d, 0x81, 0x60, 0x9b, 0xd5, 0x47, 0xfa, 0xbc, 0xbe, 0x70,
                    0x26, 0xed, 0xc8, 0xb5, 0xe5, 0xe4, 0x49, 0xd0, 0x88, 0xbf,
                    0xa6, 0x9c, 0x08, 0x8f, 0x5d, 0x8d, 0xa1, 0xd7, 0x91, 0x26,
                    0x7c, 0x2c, 0x19, 0x5a, 0x7f, 0x8c, 0xae, 0x9c, 0x4b, 0x40,
                    0x50, 0xd0, 0x8c, 0xe6, 0xd3, 0xa1, 0x51, 0xec, 0x26, 0x5f,
                    0x3a, 0x58, 0xe4, 0x76, 0x48 ]
  nonce = WordArray.from_utf8 v.nonce
  key = WordArray.from_utf8 v.key
  ctext = new Buffer(v.ciphertext).toString('hex')
  stream = new Salsa20 key, nonce
  bytes = stream.getBytes(ctext.length).toString('hex')
  T.equal bytes, ctext, "test from salsa20.go"
  cb()
