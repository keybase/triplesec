
hmac = require '../../lib/hmac'
{SHA3} = require '../../lib/sha3'
{Concat,XOR} = require '../../lib/combine'
{data} = require '../fixed-data/combine'
{WordArray} = require '../../lib/wordarray'

test_concat = (T, d) ->
  arg = { key : d.key, input : d.msg }
  c = Concat.sign arg
  s5 = hmac.sign arg
  arg.klass = SHA3
  s3 = hmac.sign arg
  c2 = s5.clone().concat s3
  T.equal c.to_hex(), c2.to_hex(), "Concats work"

test_xor = (T, d) ->
  arg = { key : d.key, input : d.msg }
  x1 = XOR.sign arg
  m5 = (new hmac.HMAC d.key).update(new WordArray [0]).finalize(d.msg)
  m3 = (new hmac.HMAC d.key, SHA3).update(new WordArray [1]).finalize(d.msg)
  m5.xor m3, {}
  T.equal m5.to_hex(), x1.to_hex(), "XOR works"

exports.test_vectors = (T, cb) ->
  for d in data
    (d[k] = WordArray.from_hex(v) for k,v of d)
    test_concat T, d
    test_xor T, d
  cb()