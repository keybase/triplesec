
{HMAC} = require './hmac'

#=========================================================

exports.PBKDF2 = class PBKDF2

  # @param {WordArray} key
  # @param {WordArray} salt
  # @param {number} c the number of iterations
  # @param {number} dkLen the needed length of output data
  #
  #
  constructor : ({@key, @salt, @c}) ->
    @prf = new HMAC @key

  #-----------

  PRF : (input) -> 
    @prf.reset()
    @prf.finalize input

  #-----------
  
  gen_T_i : (i) ->
    U = @PRF (@salt.clone().concat new WordArray [i])
    ret = U.clone()
    for i in [1..@c]
      U = @PRF U
      ret.xor U
    ret

  #-----------
  
  gen : (len) ->
    bs = @prf.get_block_size()
    n = Math.ceil(len/ bs)
    words = (@gen_T_i i for i in [1..n])
    flat = [].concat words...
    new WordArray flat, len

#=========================================================

exports.pbkdf2 = pkbdf2 = ({key, salt, c, dkLen}) ->
  (new PBKDF2 { key, salt, c}).gen dkLen

#=========================================================

