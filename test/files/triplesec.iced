{rng}     = require '../../lib/rng'
{Encryptor,encrypt} = require '../../lib/enc'
{decrypt} = require '../../lib/dec'

#-------------------------------------------------

test_vectors = [
  { 
    key : new Buffer 'this be the password'
    salt : new Buffer 'you@example.com'
    data : new Buffer 'this be the secret message'
  },{
    key : new Buffer [0...127]
    salt : new Buffer [10...60]
    data : Buffer.concat ((new Buffer [0..255]) for i in [0..4])
  },{
    key : new Buffer [0...127]
    salt : new Buffer [10...60]
    data : Buffer.concat ((new Buffer [0..255]) for i in [0..40])
  }]

#-------------------------------------------------

run_test = (T, d, i) ->
  orig = new Buffer d.data
  d.rng = rng
  ct = encrypt d
  d.data = ct
  pt = decrypt d
  T.equal (pt.toString 'hex'), (orig.toString 'hex'), "test vector #{i}"

  ct_orig_hex = ct.toString 'hex'
  p = ct.length - 10
  ct.writeUInt8(ct.readUInt8(p) + 1, p);
  ct_corrupt_hex = ct.toString 'hex'

  T.assert (ct_orig_hex isnt ct_corrupt_hex), "failed to corrupt vector #{i}"
  try
    decrypt(d)
    T.error "Signature didn't fail in test vector #{i}"
  catch e
    #

  if T.is_ok()
    T.waypoint "test vector #{i}"

#-------------------------------------------------

exports.run_test_vectors = (T,cb) ->
  for v,i in test_vectors
    run_test T, v, i
  cb()

#-------------------------------------------------

exports.check_randomness = (T, cb) ->
  tv = test_vectors[0]
  tv.rng = rng
  enc = new Encryptor tv
  enc.init()
  found = {}
  for i in [0...1000]
    ct = enc.run(tv.data).toString 'hex'
    if found[ct]
      T.error "found a repeated cipher text -> #{ct}"
    else
      found[ct] = true
  cb()
  
#-------------------------------------------------

