
{HMAC_SHA256} = require './hmac'
{pbkdf2} = require './pbkdf2'
{Salsa20InnerCore} = require './salsa20'
{WordArray} = require './wordarray'

#====================================================================

blkcpy = (D,S,d_offset,s_offset,len) -> 
  D.set(S.subarray(0x40*s_offset, 0x40*(s_offset + len)), 0x40*d_offset)

blkxor = (D,S,s_offset,len) ->
  s_offset <<= 6
  len <<= 6
  for i in [0...len]
    D[i] ^= S[i + s_offset]
  true 

# @param {Uint8Array} B
le32dec = (B) -> (B[0] | (B[1] << 8) | (B[2] << 16) | (B[3] << 24))

# @param {Uint8Array} B the target array
# @param {number} w the intput word 
le32enc = (B,w) ->
  B[0] = (w & 0xff)
  B[1] = (w >> 8) & 0xff
  B[2] = (w >> 16) & 0xff
  B[3] = (w >> 24) & 0xff

buffer_to_ui8a = (b) ->
  ret = new Uint8Array b.length
  for i in [0...b.length]
    ret[i] = b.readUInt8(i)
  ret

#====================================================================

class Scrypt

  #------------

  constructor : ({@N,@r,@p, @prng, @klass}) ->
    @N or= Math.pow(2,8)
    @r or= 16
    @p or= 2
    @klass or= HMAC_SHA256
    @X64_tmp = new Uint8Array(64)
    @s20ic = new Salsa20InnerCore(8)

  #------------

  # @param {Uint8Array} B that is 64 bytes length
  salsa20_8 : (B) ->
    B32 = (le32dec(B.subarray(i*4)) for i in [0...16])
    X = @s20ic._core B32
    (B32[i] += x for x,i in X)
    le32enc(B.subarray(i*4), b) for b,i in B32

  #------------

  pbkdf2 : ({key, salt, c, dkLen, progress_hook}, cb) ->
    key = WordArray.from_buffer key
    salt = WordArray.from_buffer salt
    await pbkdf2 { key, salt, c, dkLen, @klass, progress_hook }, defer buf
    cb buf.to_buffer()

  #------------

  blockmix_salsa8 : (B, Y) ->
    X = @X64_tmp

    # blkcpy(X, &B[(2 * r - 1) * 64], 64);
    blkcpy X,B,0,(2*@r-1), 1

    for i in [0...(2*@r)]
      # /* 3: X <-- H(X \xor B_i) */
      # blkxor(X, &B[i * 64], 64);
      blkxor X, B, i, 1
      @salsa20_8 X

      # /* 4: Y_i <-- X */
      # blkcpy(&Y[i * 64], X, 64);
      blkcpy Y, X, i, 0, 1

    # 6: B' <-- (Y_0, Y_2 ... Y_{2r-2}, Y_1, Y_3 ... Y_{2r-1}) */
    for i in [0...@r]
      blkcpy B, Y, i, (i*2), 1
    for i in [0...@r]
      blkcpy B, Y, (i+@r), (i*2+1), 1

  #------------

  # Return the result of parsing B as a 64-bit little-endian integer
  # modulo @N (since we can't fit it into a 32-bit integer).
  #
  # Let's say we can read B as 2 subsequent uint32s --- x, y
  # Then the desired result is (x + y*2^32)%N.  But of course
  # 2^32%N is 0, so we can just throw that half out. So x%N is good
  # enough.
  #
  # @param {Uint8Array} B An array to ready 8 bytes out of.
  # @return {Number} a Uint32 % (N) that's the integer we need
  integerify : (B) -> le32dec(B) & (@N-1)

  #------------

  # smix(B, V, XY):
  # Compute B = SMix_r(B, N).  The input B must be 128r bytes in length; the
  # temporary storage V must be 128rN bytes in length; the temporary storage
  # XY must be 256r bytes in length.  The value N must be a power of 2.
  smix : ({B, V, XY }) ->
    X = XY
    lim = 2*@r
    Y = XY.subarray(0x40*lim)

    blkcpy X, B, 0, 0, lim

    for i in [0...@N]
      # /* 3: V_i <-- X */
      blkcpy V, X, (2*@r*i), 0, 2*@r

      # /* 4: X <-- H(X) */
      @blockmix_salsa8(X,Y)

    for i in [0...@N]
      j = @integerify X.subarray(0x40*(lim - 1))

      # /* 8: X <-- H(X \xor V_j) */
      blkxor X, V, j*lim, lim
      @blockmix_salsa8 X, V

    # /* 10: B' <-- X */
    blkcpy B, X, 0, 0, lim

  #------------

  run : ({key, salt, dkLen, progress_hook}, cb) ->
    MAX = 0xffffffff
    err = ret = null
    err = if dkLen > MAX then err = new Error "asked for too much data"
    else if @r*@p >= (1 << 30) then new Error "r & p are too big"
    else if (@r > MAX / 128 / @p) or (@r > MAX / 256) or (@N > MAX / 128 / @r) then new Error "N is too big"
    else null

    XY = new Uint8Array(256*@r)
    V = new Uint8Array(128*@r*@N)

    lim = 128*@r
    c = 1

    await @pbkdf2 { progress_hook, key, salt, c, dkLen : lim*@p }, defer B
    B = buffer_to_ui8a B

    for i in [0...@p]
      progress_hook? { what : "scrypt", total : @p, i }
      @smix { B : B.subarray(lim*i), V, XY }

    await @pbkdf2 { progress_hook, key, salt : (new Buffer B) , c, dkLen }, defer out

    cb out

#====================================================================

exports.Scrypt = Scrypt

#====================================================================


progress_hook = (obj) ->
  console.log obj
# key = new Buffer "weriojwreoiwjreowij"
# {rng} = require 'crypto'
# salt = new Buffer 'weroiwjroiwjreowijrwoirjweoir'
# scrypt = new Scrypt { N : Math.pow(2,9), p : 1, r : 16 }
# await scrypt.run { progress_hook, key, salt, dkLen : 64 }, defer out
# console.log out

#B = new Uint8Array(new Buffer "7e879a214f3ec9867ca940e641718f26baee555b8c61c1b50df846116dcd3b1dee24f319df9b3d8514121e4b5ac5aa3276021d2909c74829edebc68db8b8c25e", "hex")
#console.log B.length
#scrypt.salsa20_8(B)
#console.log (new Buffer B).toString 'hex'
#console.log B

