
{HMAC_SHA256} = require './hmac'
{pbkdf2} = require './pbkdf2'
{Salsa20InnerCore} = require './salsa20'
{ui8a_to_buffer,WordArray} = require './wordarray'
{default_delay,scrub_vec} = require './util'

#====================================================================

blkcpy = (D,S,d_offset,s_offset,len) -> 
  D.set(S.subarray(0x40*s_offset, 0x40*(s_offset + len)), 0x40*d_offset)

#----------

blkxor = (D,S,s_offset,len) ->
  s_offset <<= 6
  len <<= 6
  for i in [0...len]
    D[i] ^= S[i + s_offset]
  true 

#----------

# @param {Uint8Array} B
le32dec = (B) -> ((B[0] | (B[1] << 8) | (B[2] << 16))) + (B[3] * 0x1000000) 

#----------

# @param {Uint8Array} B the target array
# @param {number} w the intput word 
le32enc = (B,w) ->
  B[0] = (w & 0xff)
  B[1] = (w >> 8) & 0xff
  B[2] = (w >> 16) & 0xff
  B[3] = (w >> 24) & 0xff


#====================================================================

class Scrypt

  #------------

  constructor : ({@N,@r,@p,@c,@klass}) ->
    @N or= Math.pow(2,8)
    @r or= 16
    @p or= 2
    @c or= 1 # the number of times to run PBKDF2
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
    await pbkdf2 { key, salt, c, dkLen, @klass, progress_hook }, defer wa
    cb wa

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
  integerify : (B) -> le32dec(B) & (@N - 1)

  #------------

  # smix(B, V, XY):
  # Compute B = SMix_r(B, N).  The input B must be 128r bytes in length; the
  # temporary storage V must be 128rN bytes in length; the temporary storage
  # XY must be 256r bytes in length.  The value N must be a power of 2.
  smix : ({B, V, XY, progress_hook}, cb) ->
    X = XY
    lim = 2*@r
    Y = XY.subarray(0x40*lim)

    blkcpy X, B, 0, 0, lim

    i = 0
    while i < @N
      stop = Math.min(@N, i+128)
      while i < stop
        # /* 3: V_i <-- X */
        blkcpy V, X, (lim*i), 0, lim

        # /* 4: X <-- H(X) */
        @blockmix_salsa8(X,Y)
        i++

      progress_hook? i
      await default_delay 0, 0, defer()

    i = 0
    while i < @N
      stop = Math.min(@N, i+128)

      while i < stop
        j = @integerify X.subarray(0x40*(lim - 1))

        # /* 8: X <-- H(X \xor V_j) */
        blkxor X, V, j*lim, lim
        @blockmix_salsa8 X, Y

        i++

      progress_hook? i+@N
      await default_delay 0, 0, defer()

    # /* 10: B' <-- X */
    blkcpy B, X, 0, 0, lim
    cb()

  #------------

  # Run Scrypt on the given key and salt to get dKLen of data out.
  #
  # @param {WordArray} key the Passphrase or key to work on
  # @param {WordArray} salt the random salt to prevent rainbow tables
  # @param {number} dkLen the length of data required out of the key stretcher
  # @param {callback} cb the callback to callback when done, called with a {WordArray}
  #    containing the output key material bytes.
  #
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

    await @pbkdf2 { key : key.clone(), salt, @c, dkLen : lim*@p }, defer B
    B = B.to_ui8a()

    lph = (j) => (i) => progress_hook? {  i: (i + j*@N*2), what : "scrypt", total : @p*@N*2}
    for j in [0...@p]
      await @smix { B : B.subarray(lim*j), V, XY, progress_hook : lph(j) }, defer()

    await @pbkdf2 { key, salt : WordArray.from_ui8a(B), @c, dkLen }, defer out
    scrub_vec(B)
    scrub_vec(XY)
    scrub_vec(V)
    key.scrub()

    cb out

#====================================================================

# @method scrypt
#
# A convenience method to make a new Scrypt object, and then run it just
# once.
#
# @param {WordArray} key The secret/passphrase
# @param {WordArray} salt Salt to add to the intput to prevent rainbow-tables
# @param {number} r The r (memory size) parameter for scrypt [default: 8]
# @param {number} N The N (computational factor) parameter for scrypt [default : 2^10]
# @param {number} p The p (parallellism) factor for scrypt [default : 1]
# @param {number} c The number of times to run PBKDF2 [default: 1]
# @param {Class} klass The PRF to use as a subroutine in PBKDF2 [default : HMAC-SHA256]
# @param {function} progress_hook A Standard progress hook
# @param {number} dkLen the length of the derived key.
# @param {calllback} cb Calls back with a {WordArray} of key-material
#
scrypt = ({key, salt, r, N, p, c, klass, progress_hook, dkLen}, cb) ->
  eng = new Scrypt { r, N, p, c, klass }
  await eng.run { key, salt, progress_hook, dkLen }, defer wa
  cb wa

#====================================================================

exports.Scrypt = Scrypt
exports.scrypt = scrypt

#====================================================================
