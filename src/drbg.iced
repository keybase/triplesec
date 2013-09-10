
hmac = require './hmac'
sha512 = require './sha512'

#====================================================================

# Implements an HMAC_DRBG (NIST SP 800-90A) based on HMAC_SHA512
# Supports security strengths up to 256 bits.
# Parameters are based on recommendations provided by Appendix D of NIST SP 800-90A.
exports.HMAC_DRBG = class HMAC_DRBG

  #-----------------

  check_entropy : (entropy) ->
    if (entropy.sigBytes * 8 * 2) < (3 * @security_strength)
      throw new Error "entropy must be at least %f bits." % (1.5 * @security_strength)
    else if entropy.SigBytes * 8 > 1000 
      # if too many bits, then just hash them down to size
      out = sha512.transform entropy
      entropy.scrub()
      out
    else entropy

  #-----------------

  constructor : (entropy, personalization_string) ->
    # Only run at the most secure strength
    @security_strength = 256
    entropy = @check_entropy entropy
    @_instantiate entropy, personalization_string

  #-----------------

  # Just for convenience and succinctness
  _hmac : (key, input) -> hmac.sign { key, input }

  #-----------------

  _update : (provided_data) ->
    V = new WordArray [0], 1
    V = V.concat provided_data if provided_data?
    @K = @_hmac @K, @V.concat V
    @V = @_hmac @K, @V

    if provided_data?
      @K = @_hmac @K, @V.concat(new WordArray [1], 1).concat(provided_data)
      @V = @_hmac @K, @V

    provided_data?.scrub()

  #-----------------

  _instantiate : (entropy, personalization_string) ->
    seed_material = entropy.concat personalization_string
    n = 32
    @K = WordArray.from_buffer new Buffer (0 for i in [0...n])
    @V = WordArray.from_buffer new Buffer (1 for i in [0...n])
    @_update seed_material
    entropy.scrub()
    @reseed_counter = 1
  
  #-----------------

  reseed : (entropy) ->
    @_update @check_entropy entropy
    @reseed_counter = 1

  #-----------------

  generate : (num_bytes) ->
    throw new Error "generate cannot generate > 7500 bits in 1 call." if (num_bytes * 8) > 7500
    throw new Error "Need a reseed!" if @reseed_counter >= 10000

    tmp = []
    while tmp.length is 0 or (tmp.length * tmp.length[0] * 4) < num_bytes:
      @V = @_hmac @K, @V
      temp.push @V.words
    @_update()
    @reseed_counter += 1
    new WordArray([].concat tmp...)

#====================================================================
