{Encryptor,encrypt} = require '../../lib/enc'
{decrypt} = require '../../lib/dec'
spec = require '../data/triplesec_spec'
{WordArray} = require '../../lib/wordarray'

#-------------------------------------------------

test_vectors = [
  { 
    key : new Buffer 'this be the password'
    data : new Buffer 'this be the secret message'
  },{
    key : new Buffer [0...127]
    data : Buffer.concat ((new Buffer [0..255]) for i in [0..4])
  },{
    key : new Buffer [0...127]
    data : Buffer.concat ((new Buffer [0..255]) for i in [0..40])
  }]

#-------------------------------------------------

run_test = (T, d, i, cb) ->
  orig = new Buffer d.data
  await encrypt d, defer err, ct
  T.no_error err
  d.data = ct
  await decrypt d, defer err, pt
  T.no_error err
  T.equal (pt.toString 'hex'), (orig.toString 'hex'), "test vector #{i}"

  ct_orig_hex = ct.toString 'hex'
  p = ct.length - 10
  ct.writeUInt8(ct.readUInt8(p) + 1, p);
  ct_corrupt_hex = ct.toString 'hex'

  T.assert (ct_orig_hex isnt ct_corrupt_hex), "failed to corrupt vector #{i}"
  await decrypt d, defer err, res
  T.assert err?, "should have failed"

  if T.is_ok()
    T.waypoint "test vector #{i}"
  cb()

#-------------------------------------------------


exports.run_test_vectors = (T,cb) ->
  for v,i in test_vectors
    await run_test T, v, i, defer()
  cb()

#-------------------------------------------------

exports.check_randomness = (T, cb) ->
  tv = test_vectors[0]
  enc = new Encryptor tv
  found = {}
  for i in [0...100]
    await enc.run {data : tv.data}, defer err, ct
    T.assert not err?
    ct = ct.toString 'hex'
    if found[ct]
      T.error "found a repeated cipher text -> #{ct}"
    else
      found[ct] = true
  cb()
  
#-------------------------------------------------

class ReplayRng

  constructor : (@buffer, @T) ->
    @i = 0

  gen : (n, cb) ->
    end = @i + n
    if end > @buffer.length
      @T.error "Rng underflow @ #{@i} -> #{n}"
    else
      bytes = @buffer[@i...end]
      wa = WordArray.from_buffer bytes
      @i = end
      cb wa

#-------------------------------------------------

exports.check_spec = (T,cb) ->
  for v,i in spec.data
    await check_spec T, v, i, defer()
  cb()

check_spec = (T,v,i,cb) ->
  rng = new ReplayRng (new Buffer v.r, 'hex'), T
  d = 
    key : new Buffer v.key, 'hex'
    data : new Buffer v.pt, 'hex'
  d.rng = (n,cb) -> rng.gen(n,cb)
  await encrypt d, defer err, ct
  T.assert not err?
  T.equal (ct.toString 'hex'), v.ct, "Ciphertexts match"
  d.data = ct
  await decrypt d, defer err, pt
  T.assert not err?
  T.equal (pt.toString 'hex'), v.pt, "decryption worked"
  if T.is_ok()
    T.waypoint "check test vector #{i}"
  cb()


#-------------------------------------------------

