
{data} = require('../data/salsa20')
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

exports.run_tests = (T, cb) ->
  for test,i in data
    test_case T, i, test
  cb()