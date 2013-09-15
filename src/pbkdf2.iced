
{HMAC} = require './hmac'
{WordArray} = require './wordarray'
util = require './util'

#=========================================================

#
# Standard PBKDF2, as per RFC 2898 and/or PKCS #5 v2
# 
class PBKDF2

  # @param {WordArray} key Will be destroyed after it's used
  # @param {WordArray} salt
  # @param {number} c the number of iterations
  # @param {number} dkLen the needed length of output data
  # @param {Class} klass The klass of the HMAC to use. Default it is HMAC-SHA512.
  constructor : ({@key, @salt, @c, klass}) ->
    klass or= HMAC
    @prf = new klass @key

  #-----------

  PRF : (input) -> 
    @prf.reset()
    @prf.finalize input

  #-----------
  
  gen_T_i : ({i, progress_hook}, cb) ->
    progress_hook 0
    seed = @salt.clone().concat new WordArray [i]
    U = @PRF seed
    ret = U.clone()
    i = 1
    while i < @c
      stop = Math.min(@c, i + 128)
      while i < stop
        U = @PRF U
        ret.xor U, {}
        i++
      progress_hook i
      await util.default_delay 0, 0, defer()
    progress_hook i
    cb ret

  #-----------
  
  gen : ({dkLen, progress_hook}, cb) ->
    bs = @prf.get_output_size()
    n = Math.ceil(dkLen / bs)
    words = []
    tph = null
    ph = (block) => (iter) => progress_hook? { what : "pbkdf2", total : n * @c, i : block*@c + iter }
    ph(0)(0)
    for i in [1..n]
      await @gen_T_i {i, progress_hook : ph(i-1) }, defer tmp
      words.push tmp.words
    ph(n)(0)
    flat = [].concat words...
    @key.scrub()
    @prf.scrub()
    cb new WordArray flat, dkLen

exports.PBKDF2 = PBKDF2

#=========================================================

exports.pbkdf2 = pkbdf2 = ({key, salt, c, dkLen, progress_hook, klass}, cb) ->
  eng = new PBKDF2 { key, salt, c, klass}
  await eng.gen { dkLen, progress_hook }, defer out
  cb out

#=========================================================

