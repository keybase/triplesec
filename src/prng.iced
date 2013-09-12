
more_entropy = require 'more-entropy'
{ADRBG} = require './drbg'
{WordArray} = require './wordarray'

#===============================================

browser_rng = (n) ->
  v = new Uint8Array n
  window.crypto.getRandomValues v
  new Buffer v

#===============================================

if window?.crypto?.getRandomValues?
  native_rng = browser_rng
else
  try
    {rng} = require('crypto')
    native_rng = rng if rng?
  catch e
    # pass

if not native_rng?
    throw new Error 'No rng found; tried requiring "crypto" and window.crypto'

#===============================================

exports.PRNG = class PRNG

  constructor : () ->
    @meg = new more_entropy.Generator()
    @adrbg = new ADRBG (n,cb) => @gen_seed n, cb

  now_to_buffer : () ->
    d = Date.now()
    ms = d % 1000
    s = Math.floor d / 1000
    buf = new Buffer 8
    buf.writeUInt32BE s, 0
    buf.writeUInt32BE ms, 4
    buf

  gen_seed : (nbits, cb) ->
    nbytes = nbits / 8
    bufs = []
    bufs.push @now_to_buffer()
    await @meg.generate nbits, defer words
    bufs.push @now_to_buffer()
    bufs.push new Buffer words
    bufs.push native_rng nbytes
    bufs.push @now_to_buffer()
    wa = WordArray.from_buffer Buffer.concat bufs
    cb wa

  generate : (n, cb) -> @adrbg.generate n, cb

#===============================================

_prng = null
exports.generate = (n, cb) ->
  _prng = new PRNG() if not _prng?
  _prng.generate n, cb

#===============================================

