
{WordArray} = require '../../lib/wordarray'

compare = (T, s) ->
  s2 = WordArray.from_utf8(s).to_utf8()
  T.equal s, s2, "utf8 string: #{s}"

#------------------------------------------------------------

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

#------------------------------------------------------------

test_cmp = (T,a,b) ->
  T.equal a.cmp_ule(b), "-1", "< worked"
  T.equal b.cmp_ule(a), "1", "> worked"

#------------------------------------------------------------

exports.test_cmp_ule_1 = (T,cb) ->
  b0 = WordArray.from_hex "00abcd"
  b1 = WordArray.from_hex "abcdef"
  b2 = WordArray.from_hex "000abcdef00122344556"
  b3 = WordArray.from_hex "999999999999999999"
  b4 = WordArray.from_hex "99999999999999999a"
  test_cmp T, b0, b1
  test_cmp T, b0, b2
  test_cmp T, b3, b4
  test_cmp T, b2, b4
  cb()

