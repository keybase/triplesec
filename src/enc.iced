
{WordArray}   = require './wordarray'
salsa20       = require './salsa20'
{AES}         = require './aes'
{TwoFish}     = require './twofish'
ctr           = require './ctr'
{XOR,Concat}  = require './combine'
{SHA512}      = require './sha512'
{pbkdf2}      = require './pbkdf2'
util          = require './util'
prng          = require './prng'
{make_esc}    = require 'iced-error'

#========================================================================

# @property {Object} V A lookup table of all supported versions. Only v1 yet.
exports.V = V = 
  "1" : 
    header        : [ 0x1c94d7de, 1 ]  # The magic #, and also the version #
    pbkdf2_iters  : 1024               # Since we're using XOR, this is enough..
    salt_size     : 8                  # 8 bytes of salt is good enough!
    hmac_key_size : 512/8              # The size of the key to use for HMAC (our choice)

#========================================================================

exports.Base = class Base 

  #---------------
  
  constructor : ( { key } ) ->
    @key = WordArray.from_buffer key

    # A map from Salt -> KeySets
    @derived_keys = {}

  #---------------

  pbkdf2 : ({salt, progress_hook}, cb) ->
    # Check the cache first
    salt_hex = salt.to_hex()

    if not (keys = @derived_keys[salt_hex])?

      lens = 
        hmac    : @version.hmac_key_size
        aes     : AES.keySize
        twofish : TwoFish.keySize
        salsa20 : salsa20.Salsa20.keySize
      tot = 0
      (tot += v for k,v of lens)

      # The key gets scrubbed by pbkdf2, so we need to clone our copy of it.
      args = {
        key : @key.clone()
        c : @version.pbkdf2_iters
        klass : XOR
        dkLen : tot
        progress_hook
        salt 
      }
      await pbkdf2 args, defer raw
      keys = {}
      i = 0
      for k,v of lens
        len = v/4
        end = i + len
        keys[k] = new WordArray raw.words[i...end]
        i = end
      @derived_keys[salt_hex] = keys

    cb keys
 
  #---------------

  _check_scrubbed : (key, where, gcb, lcb) ->
    if not key.is_scrubbed() then lcb()
    else gcb (new Error "#{where}: Failed due to scrubbed key!"), null

  #---------------

  sign : ({input, key, salt, progress_hook}, cb) ->
    await @_check_scrubbed key, "HMAC", cb, defer()
    input = (new WordArray @version.header ).concat(salt).concat(input)
    await Concat.bulk_sign { key, input, progress_hook}, defer(out)
    cb null, out

  #---------------

  run_salsa20 : ({ input, key, iv, output_iv, progress_hook }, cb) ->
    await @_check_scrubbed key, "Salsa20", cb, defer()
    await salsa20.bulk_encrypt { input, key, iv, progress_hook}, defer ct
    ct = iv.clone().concat(ct) if output_iv
    cb null, ct

  #---------------

  run_twofish : ({input, key, iv, progress_hook}, cb) ->
    await @_check_scrubbed key, "Twofish", cb, defer()
    block_cipher = new TwoFish key
    await ctr.bulk_encrypt { block_cipher, iv, input, progress_hook, what : "twofish" }, defer ct
    block_cipher.scrub()
    cb null, iv.clone().concat(ct)

  #---------------

  run_aes : ({input, key, iv, progress_hook}, cb) ->
    await @_check_scrubbed key, "AES", cb, defer()
    block_cipher = new AES key
    await ctr.bulk_encrypt { block_cipher, iv, input, progress_hook, what : "aes" }, defer ct
    block_cipher.scrub()
    cb null, iv.clone().concat(ct)

  #---------------

  scrub : () ->
    @key.scrub()
    for salt,key_ring of @derived_keys
      for key in key_ring
        key.scrub()

#========================================================================

#
# Encrypt the given data with the given key
#
#  @param {Buffer} key  A buffer with the keystream data in it
#  @param {Buffer} salt Salt for key derivation, should be the user's email address
#  @param {Function} rng Call it with the number of Rando bytes you need. It should
#    callback with a WordArray of random bytes
#
exports.Encryptor = class Encryptor extends Base

  #---------------

  version : V[1]

  #---------------
  
  constructor : ( { key, rng } ) ->
    super { key }
    @rng = rng or prng.generate
    @last_salt = null

  #---------------

  pick_random_ivs : ({progress_hook}, cb) ->
    iv_lens =
      aes : AES.ivSize
      twofish : TwoFish.ivSize
      salsa20 : salsa20.Salsa20.ivSize
    ivs = {}
    for k,v of iv_lens
      await @rng v, defer ivs[k]
    cb ivs

  #---------------

  # Regenerate the salt. Reinitialize the keys. You have to do this
  # once, but if you don't do it again, you'll just wind up using the
  # same salt.
  resalt : ({progress_hook}, cb) ->
    await @rng @version.salt_size, defer @salt
    await @pbkdf2 {progress_hook, @salt}, defer @keys
    cb()
 
  #---------------

  # @method run
  #
  # The main point of entry into the TripleSec Encryption system.  The 
  # steps of the algorithm are:
  #
  #  1. Encrypt PT with Salsa20
  #  1. Encrypt the result of 1 with 2Fish-256-CTR
  #  1. Encrypt the result of 2 with AES-256-CTR
  #  1. MAC with (HMAC-SHA512 || HMAC-SHA3)
  #
  # @param {Buffer} data the data to encrypt 
  # @param {Function} progress_hook Call this to update the U/I about progress
  # @param {callback} cb With an (err,res) pair, res is the buffer with the encrypted data
  #
  run : ( { data, progress_hook }, cb ) ->

    # esc = "Error Short-Circuiter".  In the case of an error,
    # we'll forget about the rest of the function and just call back
    # the outer-level cb with the error.  If no error, then proceed as normal.
    esc = make_esc cb, "Encryptor::run"

    await @resalt { progress_hook }, defer() unless @salt?
    await @pick_random_ivs { progress_hook }, defer ivs
    pt   = WordArray.from_buffer data
    await @run_salsa20 { input : pt,  key : @keys.salsa20, progress_hook, iv : ivs.salsa20, output_iv : true }, esc defer ct1
    await @run_twofish { input : ct1, key : @keys.twofish, progress_hook, iv : ivs.twofish }, esc defer ct2
    await @run_aes     { input : ct2, key : @keys.aes,     progress_hook, iv : ivs.aes     }, esc defer ct3
    await @sign        { input : ct3, key : @keys.hmac,    progress_hook, @salt            }, esc defer sig
    ret = (new WordArray(@version.header)).concat(@salt).concat(sig).concat(ct3).to_buffer()
    util.scrub_buffer data
    cb null, ret

#========================================================================

#
# @method encrypt
# 
# A convenience wrapper for:
#
# 1. Creating a new Encryptor instance with the given key
# 1. Calling `run` just once.
# 1. Scrubbing and deleting all state.
#
# @param {Buffer} key The secret key.  This data is scrubbed after use, so copy it
#   if you want to keep track of it.
# @param {Buffer} data The data to encrypt.  Again, this data is scrubber after
#   use, so copy it if you need it later.
# @param {Function} rng A function that takes as input n and outputs n truly
#   random bytes.  You must give a real RNG here and not something fake.
#   You can try require('./prng').generate_words for starters.
# @param {callback} cb Callback with an (err,res) pair. The err is an Error object
#   (if encountered), and res is a Buffer object (on success).
#
exports.encrypt = ({ key, data, rng, progress_hook}, cb) ->
  enc = new Encryptor { key, rng }
  await enc.run { data, progress_hook }, defer err, ret
  enc.scrub()
  cb err, ret

#========================================================================
