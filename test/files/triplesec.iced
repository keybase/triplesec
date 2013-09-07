{rng}     = require '../../lib/rng'
{encrypt} = require '../../lib/enc'
{decrypt} = require '../../lib/dec'

test_vectors = [
  { 
    key : 'this be the password'
    salt : 'you@example.com'
    data : 'this be the secret message'
  },{
    key : new Buffer [0...127]
    salt : new Buffer [10...60]
    data : Buffer.concat ((new Buffer [0..255]) for i in [0..4])
  },{
    key : new Buffer [0...127]
    salt : new Buffer [10...60]
    data : Buffer.concat ((new Buffer [0..255]) for i in [0..40])
  }]

run_test = (T, d, i) ->
  for k,v of d
    d[k] = new Buffer v
  orig = new Buffer d.data
  d.rng = rng
  ct = encrypt d
  d.data = ct
  pt = decrypt d
  T.equal (pt.toString 'hex'), (orig.toString 'hex'), "test vector #{i}"
  T.waypoint "test vector #{i}"

exports.run_test = (T,cb) ->
  for v,i in test_vectors
    run_test T, v, i
  cb()