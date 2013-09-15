
{SHA512} = require './sha512'
{SHA3} = require './sha3'
util = require './util'
{WordArray} = require './wordarray'

#=======================================================================

exports.HMAX = class HMAX

  @outputSize : 512/8
  outputSize : HMAX.outputSize

  #
  # Initializes a newly created HMAX.
  #
  # @param {WordArray} key The secret key.
  # @param {Classes} klasses The hash algorithm classes to user
  #
  # HMAX is our own invention, and it works as follows:
  #
  # HMAX(key,m) ->
  #   1. Derive ikey and okey from key as in HMAC
  #   2. Compute inner = (okey || H1(ikey || m) || H2(ikey || m))
  #   3. Output H1(1 || inner) XOR H2(2 || inner)
  #
  # Properties:
  #   1. If (H2 = (x) -> null), then HMAX = HMAC.
  #
  # @example
  #
  #     hmacHasher = new HMAX(key)
  #
  constructor : (@key, klasses = [SHA512, SHA3], @opts = {}) ->
    @hashers = (new klass() for klass in klasses)
    unless @hashers[0].output_size is @hashers[1].output_size
      throw new Error "hashers need the same blocksize"
    @hasher_output_size = @hashers[0].blockSize # in bytes
    @hasher_output_size_bytes = @hasher_output_size * 4 # in 32-bit words

    # Allow arbitrary length keys
    @key = @XOR_compose @key if @key.sigBytes > @hasher_output_size_bytes
    @key.clamp()

    # Clone key for inner and outer pads
    @_oKey = @key.clone()
    @_iKey = @key.clone()

    # XOR keys with pad constants
    for i in [0...@hasher_output_size]
      @_oKey.words[i] ^= 0x5c5c5c5c
      @_iKey.words[i] ^= 0x36363636

    @_oKey.sigBytes = @_iKey.sigBytes = @hasher_output_size_bytes

    # Set initial values
    @reset()

  # Combine hashes through XOR. By default, we chain the hashes
  # together, but 
  XOR_compose : (x) ->
    if (hn = @opts.skip_compose)?
      out = @hashers[hn].reset().finalize(x)
    else  
      x = (new WordArray [0]).concat x
      out = @hashers[0].reset().finalize x
      for h,i in @hashers[1...]
        x.words[0] = i
        tmp = h.reset().finalize x
        out.xor tmp, {}
        tmp.scrub()
      x.scrub()
    out

  #
  # get the output blocksize
  #
  get_output_size : () -> @hashers[0].output_size

  #
  # Resets this HMAC to its initial state.
  #
  reset : -> (h.reset().update @_iKey for h in @hashers)

  #
  # Updates this HMAC with a message.
  #
  # @param {WordArray} messageUpdate The message to append.
  #
  # @return {HMAC} This HMAC instance.
  #
  # @example
  #     hmacHasher.update(wordArray);
  #
  update : (wa) ->
    (h.update(wa) for h in @hashers)
    @

  #
  # Finalizes the HMAC computation.
  # Note that the finalize operation is effectively a destructive, read-once operation.
  #
  # @param {WordArray} messageUpdate (Optional) A final message update.
  #
  # @return {WordArray} The HMAC.
  #
  # @example
  #
  #     hmac = hmacHasher.finalize()
  #     hmac = hmacHasher.finalize(wordArray)
  #
  finalize : (wa) ->
    innerHashes = []
    for h,i in @hashers
      innerHashes.push h.finalize wa
    innerPayload = @_oKey.clone()
    for h in innerHashes
      innerPayload.concat h
      h.scrub()
    out = @XOR_compose innerPayload
    innerPayload.scrub()
    out

  scrub : ->
    @key.scrub()
    @_iKey.scrub()
    @_oKey.scrub()
    
#=======================================================================

exports.sign = ({key, input}) -> 
  (new HMAX key).finalize(input.clamp())

#=======================================================================

exports.bulk_sign = ({key, input, progress_hook}, cb) ->
  eng = new HMAX key
  input.clamp()
  slice_args = 
    update    : (lo,hi) -> eng.update input[lo...hi]
    finalize  : ()      -> eng.finalize()
    default_n : eng.hasher_output_size * 500
  async_args = {
    what : "hmax_sha512_sha3"
    progress_hook
    cb
  }
  util.bulk input.sigBytes, slice_args, async_args

#=======================================================================

