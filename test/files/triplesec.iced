{V,Encryptor,encrypt} = require '../../lib/enc'
{decrypt} = require '../../lib/dec'
spec = 
  v1 : require '../data/triplesec_spec_v1'
  v2 : require '../data/triplesec_spec_v2'
  v3 : require '../data/triplesec_spec_v3'
{WordArray} = require '../../lib/wordarray'

#-------------------------------------------------

exports.check_scrub_protection = (T,cb) ->
  key = new Buffer "this key is good"
  data = new Buffer "this is the data"
  e = new Encryptor { key, version : 3}
  await e.run {data}, defer err, ctext
  T.no_error err
  e.set_key new Buffer [0,0,0,0,0,0,0]
  await e.run {data}, defer err, ctext
  T.assert err?, "failed due to scrub protection"
  e.set_key()
  await e.run {data}, defer err, ctext
  T.assert err?, "failed due to scrub protection"
  cb()

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

run_test = (T, d, i, v, cb) ->
  orig = new Buffer d.data
  d.version = v
  await encrypt d, defer err, ct
  T.no_error err
  d.data = ct
  await decrypt d, defer err, pt
  T.no_error err
  T.equal (pt.toString 'hex'), (orig.toString 'hex'), "test vector #{i}"

  ct_orig_hex = ct.toString 'hex'
  p = ct.length - 10
  # Flip a bit in this byte
  ct.writeUInt8((ct.readUInt8(p) ^ 0x8), p);
  ct_corrupt_hex = ct.toString 'hex'

  T.assert (ct_orig_hex isnt ct_corrupt_hex), "failed to corrupt vector #{i}"
  await decrypt d, defer err, res
  T.assert err?, "should have failed"

  if T.is_ok()
    T.waypoint "test vector #{i} (version #{v})"
  cb()

#-------------------------------------------------


exports.run_test_vectors = (T,cb) ->
  for d,i in test_vectors
    for version, vobj of V
      await run_test T, d, i, version, defer()
  cb()

#-------------------------------------------------

check_randomness = (T, version, cb) ->
  tv = test_vectors[0]
  tv.version = version
  enc = new Encryptor tv
  found = {}
  for i in [0...100]
    await enc.run {data : tv.data}, defer err, ct
    T.no_error err
    ct = ct.toString 'hex'
    if found[ct]
      T.error "found a repeated cipher text -> #{ct}"
    else
      found[ct] = true
  cb()

#-------------------------------------------------

for version, vobj of V 
  exports["check_randomness_v#{version}"] = (T, cb) ->
    check_randomness T, version, cb
  
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
  for version, vobj of V
    data = spec["v#{version}"].data
    for v,i in data
      await check_spec T, version, v, i, defer()
    T.waypoint "checked spec version #{version}"
  cb()

check_spec = (T,version,v,i,cb) ->
  rng = new ReplayRng (new Buffer v.r, 'hex'), T
  d = 
    key : new Buffer v.key, 'hex'
    data : new Buffer v.pt, 'hex'
    version : version
  d.rng = (n,cb) -> rng.gen(n,cb)
  await encrypt d, defer err, ct
  T.assert not err?
  T.equal (ct.toString 'hex'), v.ct, "Ciphertexts match"
  d.data = ct
  await decrypt d, defer err, pt
  T.assert not err?
  T.equal (pt.toString 'hex'), v.pt, "decryption worked"
  if T.is_ok()
    T.waypoint "check spec test vector #{version}.#{i}"
  cb()

#-------------------------------------------------