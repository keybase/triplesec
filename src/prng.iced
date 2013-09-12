
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
    d = date.now()
    ms = d % 1000
    s = d / 1000
    buf = new buffer 8
    buf.writeuint32be s, 0
    buf.writeuint32be ms, 4
    buf

  gen_seed : (nbits, cb) ->
    n_bytes = n_bits / 8
    bufs = []
    bufs.push @now_to_buffer()
    await @meg.generate_bits n_bits, words
    bufs.push @now_to_buffer()
    bufs.push new buffer words
    bufs.push native_rng n_bytes
    bufs.push @now_to_buffer()
    wa = wordarray.from_buffer [].concat bufs...
    cb wa

  generate : (n, cb) -> @adrbg n, cb

#===============================================

_prng = null
exports.generate_words = (n, cb) ->
  _prng = new PRNG() if not _prng?
  _prng.generate n, cb

#===============================================

