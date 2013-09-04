#
# Copied from:
# 
#   https://gist.github.com/dchest/4582374
#   http://cr.yp.to/snuffle/salsa20/ref/salsa20.c
#
#   

{WordArray} = require './wordarray'
{Counter} = require './ctr'
{fixup_uint32} = require './util'

#====================================================================

asum = (out, v) -> 
  (out[i] += e for e,i in v)
  false

#====================================================================

exports.Salsa20 = class Salsa20

  sigma : WordArray.from_buffer_le new Buffer "expand 32-byte k"
  tau : WordArray.from_buffer_le new Buffer "expand 16-byte k"
  block_size : 64
  rounds : 20

  #--------------

  constructor : (@key, @nonce) ->
    throw new Error "Bad key/none lengths" unless (
             ((@key.sigBytes is 16) and (@nonce.sigBytes is 8)) or
             ((@key.sigBytes is 32) and (@nonce.sigBytes in [8,24])))
    @nonce_setup() if @nonce.sigBytes is 24
    @input = @key_iv_setup @nonce, @key
    @_reset()

  #--------------

  nonce_setup : () ->
    n0 = new WordArray @nonce.words[0...4]
    n1 = new WordArray @nonce.words[4...]
    @key = @hsalsa20 n0, @key
    @nonce = n1

  #--------------

  hsalsa20 : (nonce, key) ->
    input = @key_iv_setup nonce, key
    input[8] = nonce.words[2]
    input[9] = nonce.words[3]
    v = @_core input
    v = (fixup_uint32 w for w in v)
    new WordArray v

  #--------------

  key_iv_setup : (nonce, key) ->
    out = []
    for i in [0...4]
      out[i+1] = key.words[i]
    [C,A] = if key.sigBytes is 32 then [ @sigma, key.words[4...] ]
    else [ @tau, key.words ]
    for i in [0...4]
      out[i+11] = A[i]
    for i in [0...4]
      out[i*5] = C.words[i]
    out[6] = nonce.words[0]
    out[7] = nonce.words[1]
    out
   
  #--------------

  counter_setup : () ->
    @input[8] = @counter.get().words[0]
    @input[9] = @counter.get().words[1]

  #--------------

  _reset : () ->
    @counter = new Counter { len : 2 }
    @block = new Buffer @block_size
    @_i = @block_size

  #--------------

  # getBytes returns the next numberOfBytes bytes of stream.
  getBytes : (needed) ->
    v = []
    bsz = @block_size
    while needed > 0
      if @_i is bsz
        @_generateBlock()
        @counter.inc_le()
        @_i = 0
      n = Math.min needed, (bsz - @_i)
      v.push (if (n is bsz) then @block else @block[(@_i)...(@_i + n)])
      @_i += n
      needed -= n
    Buffer.concat v

  #--------------

  # _generateBlock generates 64 bytes from key, nonce, and counter,
  # and puts the result into this.block.
  _generateBlock : ->
    @counter_setup()
    v = @_core @input
    asum v, @input
    @output_block @block, v

  #--------------

  output_block : (out, v) ->
    for e,i in v
      out.writeUInt32LE fixup_uint32(e), (i*4)

  #--------------

  _core : (v) ->
    [ x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 ] = v

    for i in [0...@rounds] by 2
      u = x0  + x12 ;   x4  ^= (u<<7)  | (u>>>(32-7))
      u = x4  + x0  ;   x8  ^= (u<<9)  | (u>>>(32-9))
      u = x8  + x4  ;   x12 ^= (u<<13) | (u>>>(32-13))
      u = x12 + x8  ;   x0  ^= (u<<18) | (u>>>(32-18))
      u = x5  + x1  ;   x9  ^= (u<<7)  | (u>>>(32-7))
      u = x9  + x5  ;   x13 ^= (u<<9)  | (u>>>(32-9))
      u = x13 + x9  ;   x1  ^= (u<<13) | (u>>>(32-13))
      u = x1  + x13 ;   x5  ^= (u<<18) | (u>>>(32-18))
      u = x10 + x6  ;   x14 ^= (u<<7)  | (u>>>(32-7))
      u = x14 + x10 ;   x2  ^= (u<<9)  | (u>>>(32-9))
      u = x2  + x14 ;   x6  ^= (u<<13) | (u>>>(32-13))
      u = x6  + x2  ;   x10 ^= (u<<18) | (u>>>(32-18))
      u = x15 + x11 ;   x3  ^= (u<<7)  | (u>>>(32-7))
      u = x3  + x15 ;   x7  ^= (u<<9)  | (u>>>(32-9))
      u = x7  + x3  ;   x11 ^= (u<<13) | (u>>>(32-13))
      u = x11 + x7  ;   x15 ^= (u<<18) | (u>>>(32-18))
      u = x0  + x3  ;   x1  ^= (u<<7)  | (u>>>(32-7))
      u = x1  + x0  ;   x2  ^= (u<<9)  | (u>>>(32-9))
      u = x2  + x1  ;   x3  ^= (u<<13) | (u>>>(32-13))
      u = x3  + x2  ;   x0  ^= (u<<18) | (u>>>(32-18))
      u = x5  + x4  ;   x6  ^= (u<<7)  | (u>>>(32-7))
      u = x6  + x5  ;   x7  ^= (u<<9)  | (u>>>(32-9))
      u = x7  + x6  ;   x4  ^= (u<<13) | (u>>>(32-13))
      u = x4  + x7  ;   x5  ^= (u<<18) | (u>>>(32-18))
      u = x10 + x9  ;   x11 ^= (u<<7)  | (u>>>(32-7))
      u = x11 + x10 ;   x8  ^= (u<<9)  | (u>>>(32-9))
      u = x8  + x11 ;   x9  ^= (u<<13) | (u>>>(32-13))
      u = x9  + x8  ;   x10 ^= (u<<18) | (u>>>(32-18))
      u = x15 + x14 ;   x12 ^= (u<<7)  | (u>>>(32-7))
      u = x12 + x15 ;   x13 ^= (u<<9)  | (u>>>(32-9))
      u = x13 + x12 ;   x14 ^= (u<<13) | (u>>>(32-13))
      u = x14 + x13 ;   x15 ^= (u<<18) | (u>>>(32-18))

    [ x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 ]
    

#====================================================================
