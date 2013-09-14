
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
  @blockSize : SHA512.blockSize
  output_size : NullHash.output_size
  blockSize : NullHash.blockSize 
  update : ->
  finalize : -> new WordArray [], 0
  reset : -> @

#--------

exports.null_hash = (T,cb) ->
  mac_makers = [
    ((k) -> new hmax.HMAX k, [ SHA512, NullHash ], { skip_compose : 0 })
    ((k) -> new hmax.HMAX k, [ NullHash, SHA512 ], { skip_compose : 1 })
    ((k) -> new HMAC k, SHA512)
  ]
  for v,i in data
    key = WordArray.from_hex v.key
    input = WordArray.from_hex v.msg
    macs = (m key.clone() for m in mac_makers)
    s = (m.finalize input.clone() for m in macs)
    T.equal s[0].to_hex(), s[1].to_hex(), "null hash equality #{i} (compare orders)"
    T.equal s[1].to_hex(), s[2].to_hex(), "null hash equality #{i} (compare to HMAC)"
  cb()
