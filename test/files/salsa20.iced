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
  run_tests T, 'key128', cb

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
  nonce = WordArray.from_utf8_le v.nonce
  key = WordArray.from_utf8_le v.key
  ctext = new Buffer(v.ciphertext).toString('hex')
  stream = new Salsa20 key, nonce
  bytes = stream.getBytes(v.ciphertext.length).toString('hex')
  T.equal bytes, ctext, "test from salsa20.go"
  cb()

exports.test_slicing = (T,cb) ->
  v = data.key256[data.key256.length - 1]
  key = WordArray.from_hex_le v.key
  iv = WordArray.from_hex_le v.IV
  n = 64
  stream = new Salsa20 key, iv
  reference = (stream.getBytes().toString('hex') for i in [0...n]).join('')
  stream = new Salsa20 key, iv
  big = stream.getBytes(n*n).toString('hex')
  T.equal big, reference, 'all at once works'
  stream = new Salsa20 key, iv
  sz = 8
  nibbles = (stream.getBytes(sz).toString('hex') for i in [0...(n*64/sz)]).join('')
  T.equal big, nibbles, 'works in small nibbles'
  stream = new Salsa20 key, iv
  odd = (stream.getBytes(7).toString('hex') for i in [0...100]).join('')
  T.equal odd, reference[0...(odd.length)], "on odd boundaries of 7"
  stream = new Salsa20 key, iv
  odd = (stream.getBytes(17).toString('hex') for i in [0...100]).join('')
  T.equal odd, reference[0...(odd.length)], "on odd boundaries of 17"
  randos = [
    [56,207,186,128,22,145,254,246,71,12,102,103,91,204,61,143,146,192,80],
    [252,226,56,65,10,74,108,3,153,154,92,230,195,180,124,146,215,180,170],
    [202,154,234,221,147,25,114,50,232,160,201,71,146,74,77,153,122,136,241],
    [106,120,187,8,144,131,101,195,208,146,113,28,124,203,90,39,126,106,181],
    [143,113,158,148,76,135,91,102,175,112,102,189,148,41,155,197,58,101,142],
    [5,249,193,54,187,73,62,83,201,127,238,210,118,248,165,112,105,21,136],
    [2,218,113,183,85,132,159,132,90,181,89,62,185,175,253,38,15,35,149],
    [126,128,107,160,167,17,239,187,106,42,175,97,49,10,229,150,200,236,227],
    [224,176,32,105,156,180,238,208,74,24,19,131,29,138,35,244,223,87,232],
    [221,254,40,17,232,82,246,126,94,18,122,48,66,2,223,117,85,97,20]
  ]
  for seq in randos
    stream = new Salsa20 key, iv
    rand = (stream.getBytes(i).toString('hex') for i in seq).join('')
    T.equal rand, reference[0...(rand.length)], "on random boundaries"
  cb()
