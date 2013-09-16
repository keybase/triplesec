
enc = require '../src/enc'
{WordArray} = require '../src/wordarray'
{rng} = require 'crypto'
colors = require 'colors'

fake_rng = (n, cb) ->
  data = ((n & 0xff) for i in [0...n])
  buf = new Buffer data
  cb WordArray.from_buffer buf 

class GenerateSpec

  constructor : ->
    @version = 1
    @vectors = []

  gen_vector : (len, cb) ->
    key = rng len.key
    data = rng len.msg
    pt = new Buffer data # make a copy!
    await enc.encrypt { key, data, rng : fake_rng }, defer err, ct
    console.error "+ done with #{JSON.stringify len}".green
    ret = { key, pt, ct }
    (ret[k] = v.toString('hex') for k,v of ret)
    cb ret

  gen_vectors : (cb) ->
    params = [ { key : 10, msg : 100 },
               { key : 20, msg : 300 },
               { key : 40, msg : 1000 },
               { key : 100, msg : 10000 },
               { key : 250, msg : 50000 } ]
    for p in params
      await @gen_vector p, defer v
      @vectors.push v
    cb()

  output : () ->
    { @version, "generated" : (new Date()).toString(), @vectors }

gs = new GenerateSpec()
await gs.gen_vectors defer()
console.log JSON.stringify gs.output(), null, 4





