
hmac = require '../../lib/hmac'
{SHA3} = require '../../lib/sha3'
{Concat,XOR} = require '../../lib/combine'
{data} = require '../fixed-data/combine'
{WordArray} = require '../../lib/wordarray'

test_vector = (T, d) ->
  (d[k] = WordArray.from_hex(v) for k,v of d)
  arg = { key : d.key, input : d.msg }
  c = Concat.sign arg
  x = XOR.sign arg
  s5 = hmac.sign arg
  arg.klass = SHA3
  s3 = hmac.sign arg
  c2 = s5.clone().concat s3
  T.equal c.to_hex(), c2.to_hex(), "Concats work"
  x2 = s5.xor s3, {}
  T.equal x.to_hex(), x2.to_hex(), "XORs works"

exports.test_vectors = (T, cb) ->
  for v in data
    test_vector T, v
  cb()