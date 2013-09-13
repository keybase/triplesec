
{data} = require '../fixed-data/hmax'
{sign} = require '../../lib/hmax'
{WordArray} = require '../../lib/wordarray'

test_vector = (T,v, i) ->
  key = WordArray.from_hex v.key
  input = WordArray.from_hex v.msg
  sig = sign { key, input }
  T.equal v.sig, sig.to_hex(), "Test vector #{i} checks out"
  if key.sigBytes > 0
    key.words[0]++ 
    sig = sign { key, input }
    T.assert not (sig.to_hex() is v.sig), "test vector #{i} fails key mangling"
    key.words[0]--
  if input.sigBytes > 0
    input.words[0]++ 
    sig = sign { key, input }
    T.assert not (sig.to_hex() is v.sig), "test vector #{i} fails input mangling"
    input.words[0]--

exports.test_vectors = (T,cb) ->
  for v,i in data
    test_vector T, v, i
  cb()
