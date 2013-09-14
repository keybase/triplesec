data =
  short : require('../data/sha3_short').data
  long : require('../data/sha3_long').data

{SHA3} = require '../../lib/sha3'
{WordArray} = require '../../lib/wordarray'

test_case = (T, which, i, test) ->
  s = new SHA3()
  input = WordArray.from_hex test.Msg
  expected = test.MD.toLowerCase()
  s.update input
  output = s.finalize().to_hex()
  T.equal output, expected, "test vector #{which}/#{i}"

exports.short = (T,cb) ->
  test_cases T, 'short'
  cb()

exports.long = (T,cb) ->
  test_cases T, 'long'
  cb()

test_cases = (T, which) ->
  for v,i in data[which] when i < 5
    test_case T, which, i, v
