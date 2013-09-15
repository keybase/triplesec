
hmac = require './hmac'
{XOR} = require './combine'
sha512 = require './sha512'
sha3 = require './sha3'
{WordArray} = require './wordarray'
{Lock} = require './lock'

#====================================================================

#
# Implements an HMAC_DRBG (NIST SP 800-90A) based on HMAC_SHA512
# Supports security strengths up to 256 bits.
# Parameters are based on recommendations provided by Appendix D of NIST SP 800-90A.
# Implementation ported from: https://github.com/fpgaminer/python-hmac-drbg
#
exports.DRBG = class DRBG

  #-----------------

  constructor : (entropy, personalization_string, hm) ->
    @hmac = hm or hmac.sign
    # Only run at the most secure strength
    @security_strength = 256
    entropy = @check_entropy entropy
    personalization_string or= new WordArray []
    @_instantiate entropy, personalization_string

  #-----------------

  check_entropy : (entropy, reseed = false) ->
    if (entropy.sigBytes * 8 * 2) < ((if reseed then 2 else 3) * @security_strength)
      throw new Error "entropy must be at least #{1.5 * @security_strength} bits."
    else if entropy.SigBytes * 8 > 1000 
      # if too many bits, then just hash them down to size
      # Hash with both SHAs and then XOR together.
      out = sha512.transform entropy
      tmp = sha3.transform entropy
      out.xor tmp, {}
      tmp.scrub()
      entropy.scrub()
      out
    else entropy

  #-----------------

  # Just for convenience and succinctness
  _hmac : (key, input) -> @hmac { key, input }

  #-----------------

  _update : (provided_data) ->
    V = new WordArray [0], 1
    V = V.concat provided_data if provided_data?
    V_in = @V.clone().concat(V)
    @K = @_hmac @K, V_in
    V_in.scrub()
    V.scrub()
    @V = @_hmac @K, @V

    if provided_data?
      V_in = @V.clone().concat(new WordArray [(1 << 24)], 1).concat(provided_data)
      @K = @_hmac @K, V_in
      V_in.scrub()
      @V = @_hmac @K, @V
    provided_data?.scrub()

  #-----------------

  _instantiate : (entropy, personalization_string) ->
    seed_material = entropy.concat personalization_string
    n = 64
    @K = WordArray.from_buffer new Buffer (0 for i in [0...n])
    @V = WordArray.from_buffer new Buffer (1 for i in [0...n])
    @_update seed_material
    entropy.scrub()
    @reseed_counter = 1
  
  #-----------------

  reseed : (entropy) ->
    @_update @check_entropy(entropy,true)
    @reseed_counter = 1

  #-----------------

  generate : (num_bytes) ->
    throw new Error "generate cannot generate > 7500 bits in 1 call." if (num_bytes * 8) > 7500
    throw new Error "Need a reseed!" if @reseed_counter >= 10000

    tmp = []
    i = 0
    while (tmp.length is 0) or (tmp.length * tmp[0].length * 4) < num_bytes
      @V = @_hmac @K, @V
      tmp.push @V.words
    @_update()
    @reseed_counter += 1
    (new WordArray([].concat tmp...)).truncate num_bytes

#====================================================================

exports.ADRBG = class ADRBG

  constructor : (@gen_seed, @hmac) ->
    @drbg = null
    @lock = new Lock()

  generate : (n, cb) ->
    await @lock.acquire defer()
    if not @drbg?
      await @gen_seed 256, defer seed
      @drbg = new DRBG seed, null, @hmac
    if @drbg.reseed_counter > 100
      await @gen_seed 256, defer seed
      @drbg.reseed seed
    ret = @drbg.generate n
    @lock.release()
    cb ret

#====================================================================
