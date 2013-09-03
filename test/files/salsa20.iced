
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
#exports.key128 = (T, cb) ->
#  run_tests T, 'key128', cb