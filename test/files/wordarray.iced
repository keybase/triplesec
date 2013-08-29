
{WordArray} = require '../../src/wordarray'

compare = (T, s) ->
  s2 = new WordArray.from_utf8(s).to_utf8()
  T.equal s, s2, "utf8 string: #{s}"

exports.compare_utf8 = (T,cb) ->
  strings = [
    "a"
    "ab"
    "abc"
    "abcd"
    "abcd1"
    "abcd12"
    "abcd123"
    "abcd1234"
    "hi"
    "bye"
    "the quick brown fox jumped over the lazy dog"
    "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c"
  ]
  for s in strings
    compare T, s
  cb()
