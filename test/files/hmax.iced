
{data} = require '../fixed-data/hmax'
hmax = require '../../lib/hmax'
{HMAC} = require '../../lib/hmac'
{WordArray} = require '../../lib/wordarray'
{SHA3} = require '../../lib/sha3'
{SHA512} = require '../../lib/sha512'

test_vector = (T,v, i) ->
  key = WordArray.from_hex v.key
  input = WordArray.from_hex v.msg
  sig = hmax.sign { key, input }
  T.equal v.sig, sig.to_hex(), "Test vector #{i} checks out"
  if key.sigBytes > 0
    key.words[0]++ 
    sig = hmax.sign { key, input }
    T.assert not (sig.to_hex() is v.sig), "test vector #{i} fails key mangling"
    key.words[0]--
  if input.sigBytes > 0
    input.words[0]++ 
    sig = hmax.sign { key, input }
    T.assert not (sig.to_hex() is v.sig), "test vector #{i} fails input mangling"
    input.words[0]--

#--------

exports.test_vectors = (T,cb) ->
  for v,i in data
    test_vector T, v, i
  cb()

#--------

class NullHash 
  constructor : ->
  @output_size : SHA512.output_size
  output_size : NullHash.output_size
  update : ->
  finalize : -> new WordArray [], 0
  reset : -> @

console.log SHA512.output_size
console.log NullHash.output_size

#--------

exports.null_hash = (T,cb) ->
  new_h0 = (k) -> new hmax.HMAX k, [ SHA512, NullHash ]
  new_h1 = (k) -> new HMAC k, SHA512
  for v,i in data
    key = WordArray.from_hex v.key
    input = WordArray.from_hex v.msg
    h0 = new_h0 key
    h1 = new_h1 key
    s0 = h0.finalize input
    s1 = h1.finalize input
    T.equal s0.to_hex(), s1.to_hex(), "null hash equality #{i} w/ Null,SHA-512"
