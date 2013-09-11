{rng}     = require '../../lib/rng'
{Encryptor,encrypt} = require '../../lib/enc'
{decrypt} = require '../../lib/dec'

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
  d.rng = rng
  await encrypt d, defer err, ct
  T.assert not err?
  d.data = ct
  await decrypt d, defer err, pt
  T.assert not err?
  T.equal (pt.toString 'hex'), (orig.toString 'hex'), "test vector #{i}"

  ct_orig_hex = ct.toString 'hex'
  p = ct.length - 10
  ct.writeUInt8(ct.readUInt8(p) + 1, p);
  ct_corrupt_hex = ct.toString 'hex'

  T.assert (ct_orig_hex isnt ct_corrupt_hex), "failed to corrupt vector #{i}"
  await decrypt d, defer err, res
  T.assert err?

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
  tv.rng = rng
  enc = new Encryptor tv
  found = {}
  for i in [0...1000]
    ct = enc.run(tv.data).toString 'hex'
    if found[ct]
      T.error "found a repeated cipher text -> #{ct}"
    else
      found[ct] = true
  cb()
  
#-------------------------------------------------

