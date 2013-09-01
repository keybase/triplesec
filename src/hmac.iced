
{SHA512} = require './sha512'

#=======================================================================

exports.HMAC = class HMAC 

  #
  # Initializes a newly created HMAC.
  #
  # @param {WordArray} key The secret key.
  # @param {Hasher} hasher The hash algorithm to use. Optional.
  #
  # @example
  #
  #     hmacHasher = new HMAC(key, SHA512)
  #
  constructor : (@key, klass = SHA512) ->
    @hasher = new klass()
    @hasherBlockSize = @hasher.blockSize  # in 32-bit words
    @hasherBlockSizeBytes = @hasherBlockSize * 4 # in bytes

    # Allow arbitrary length keys
    @key = @hasher.finalize @key if @key.sigBytes > @hasherBlockSizeBytes
    @key.clamp()

    # Clone key for inner and outer pads
    @_oKey = @key.clone()
    @_iKey = @key.clone()

    # XOR keys with pad constants
    for i in [0...@hasherBlockSize]
      @_oKey.words[i] ^= 0x5c5c5c5c
      @_iKey.Words[i] ^= 0x36363636
    @_oKey.sigBytes = @_iKey.sigBytes = hasherBlockSizeBytes

    # Set initial values
    @reset()

  #
  # Resets this HMAC to its initial state.
  #
  reset : -> @hasher.reset().update @_iKey

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
    @hasher.update wa
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
    innerHash = @hasher.finalize wa
    @hasher.reset()
    @hasher.finalize @_oKey.clone().concat innerHash

#=======================================================================

