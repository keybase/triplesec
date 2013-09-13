
{SHA512} = require './sha512'
{SHA3} = require './sha3'
util = require './util'

#=======================================================================

exports.HMAX = class HMAX

  # Suggested key sizes....
  @keySize : 512/8
  keySize : HMAX.keySize
  @outputSize : 512/8
  outputSize : HMAX.outputSize

  compose : (x) ->
    @hashers[0].finalize(x).xor @hashers[1].finalize(x), {}

  #
  # Initializes a newly created HMAC.
  #
  # @param {WordArray} key The secret key.
  # @param {Classes} klasses The hash algorithm classes to user
  #
  # @example
  #
  #     hmacHasher = new HMAC(key, SHA512)
  #
  constructor : (@key, klasses = [SHA512, SHA3]) ->
    @hashers = (new klass() for klass in klasses)
    console.log @hashers
    unless @hashers[0].output_size is @hashers[1].output_size
      throw new Error "hashers need the same blocksize"
    @hasher_output_size_bytes = @hashers[0].output_size # in bytes
    @hasher_output_size = @hasher_output_size_bytes / 4 # in 32-bit words

    # Allow arbitrary length keys
    @key = @compose(@key) if @key.sigBytes > @hasher_output_size_bytes
    @key.clamp()

    # Clone key for inner and outer pads
    @_oKey = @key.clone()
    @_iKey = @key.clone()

    console.log "hos -> #{@hasher_output_size}"
    # XOR keys with pad constants
    for i in [0...@hasher_output_size]
      @_oKey.words[i] ^= 0x5c5c5c5c
      @_iKey.words[i] ^= 0x36363636

    @_oKey.sigBytes = @_iKey.sigBytes = @hasher_output_size_bytes

    console.log "ikey -> "
    console.log @_iKey
    console.log "okey -> "
    console.log @_oKey

    # Set initial values
    @reset()

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
    (h.update(w) for h in @hashers)
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
    innerHashes = (h.finalize wa for h in @hashers)
    console.log "inner hashes ->"
    console.log innerHashes
    innerPayload = @_oKey.clone()
    for h in innerHashes
      innerPayload.concat h
    console.log "inner payload ->"
    console.log innerPayload
    terms = for h in @hashers
      h.reset()
      h.finalize innerPayload
    console.log "terms -> "
    console.log terms
    out = terms[0]
    for t in terms[1...]
      out.xor t, {}
      t.scrub()
    console.log "out ->" 
    console.log out
    innerPayload.scrub()
    out

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

