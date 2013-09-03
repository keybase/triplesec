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

  sigma : WordArray.from_buffer_le(new Buffer("expand 32-byte k"), 16)
  tau : WordArray.from_buffer_le(new Buffer("expand 16-byte-k"), 16)
  block_size : 64
  rounds : 20

  #--------------

  constructor : (@key, @nonce) ->
    @input = []
    @key_setup()
    @iv_setup()
    @_reset()

  #--------------

  key_setup : () ->
    for i in [0...4]
      @input[i+1] = @key.words[i]
    [C,A] = if @key.sigBytes is 32 then [ @sigma, @key.words[4...] ]
    else [ @tau, @key.words ]
    for i in [0...4]
      @input[i+11] = A[i]
    for i in [0...4]
      @input[i*5] = C.words[i]

  #--------------

  iv_setup : () ->
    @input[6] = @nonce.words[0]
    @input[7] = @nonce.words[1]
   
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
    [ x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 ] = @input

    for i in [0...@rounds] by 2
      u = x0 + x12;    x4  ^= (u<<7)  | (u>>>(32-7))
      u = x4 + x0;     x8  ^= (u<<9)  | (u>>>(32-9))
      u = x8 + x4;     x12 ^= (u<<13) | (u>>>(32-13))
      u = x12 + x8;    x0  ^= (u<<18) | (u>>>(32-18))
      u = x5 + x1;     x9  ^= (u<<7)  | (u>>>(32-7))
      u = x9 + x5;     x13 ^= (u<<9)  | (u>>>(32-9))
      u = x13 + x9;    x1  ^= (u<<13) | (u>>>(32-13))
      u = x1 + x13;    x5  ^= (u<<18) | (u>>>(32-18))
      u = x10 + x6;    x14 ^= (u<<7)  | (u>>>(32-7))
      u = x14 + x10;   x2  ^= (u<<9)  | (u>>>(32-9))
      u = x2 + x14;    x6  ^= (u<<13) | (u>>>(32-13))
      u = x6 + x2;     x10 ^= (u<<18) | (u>>>(32-18))
      u = x15 + x11;   x3  ^= (u<<7)  | (u>>>(32-7))
      u = x3 + x15;    x7  ^= (u<<9)  | (u>>>(32-9))
      u = x7 + x3;     x11 ^= (u<<13) | (u>>>(32-13))
      u = x11 + x7;    x15 ^= (u<<18) | (u>>>(32-18))
      u = x0 + x3;     x1  ^= (u<<7)  | (u>>>(32-7))
      u = x1 + x0;     x2  ^= (u<<9)  | (u>>>(32-9))
      u = x2 + x1;     x3  ^= (u<<13) | (u>>>(32-13))
      u = x3 + x2;     x0  ^= (u<<18) | (u>>>(32-18))
      u = x5 + x4;     x6  ^= (u<<7)  | (u>>>(32-7))
      u = x6 + x5;     x7  ^= (u<<9)  | (u>>>(32-9))
      u = x7 + x6;     x4  ^= (u<<13) | (u>>>(32-13))
      u = x4 + x7;     x5  ^= (u<<18) | (u>>>(32-18))
      u = x10 + x9;    x11 ^= (u<<7)  | (u>>>(32-7))
      u = x11 + x10;   x8  ^= (u<<9)  | (u>>>(32-9))
      u = x8 + x11;    x9  ^= (u<<13) | (u>>>(32-13))
      u = x9 + x8;     x10 ^= (u<<18) | (u>>>(32-18))
      u = x15 + x14;   x12 ^= (u<<7)  | (u>>>(32-7))
      u = x12 + x15;   x13 ^= (u<<9)  | (u>>>(32-9))
      u = x13 + x12;   x14 ^= (u<<13) | (u>>>(32-13))
      u = x14 + x13;   x15 ^= (u<<18) | (u>>>(32-18))

    v = [ x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 ]
    asum v, @input
    for e,i in v
      @block.writeUInt32LE fixup_uint32(e), (i*4)

#====================================================================
