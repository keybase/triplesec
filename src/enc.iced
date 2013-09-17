
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
V = 
  "1" : 
    header        : [ 0x1c94d7de, 1 ]  # The magic #, and also the version #
    pbkdf2_iters  : 1024               # Since we're using XOR, this is enough..
    salt_size     : 8                  # 8 bytes of salt is good enough!
    hmac_key_size : 768/8              # The size of the key to use for HMAC (our choice)

#========================================================================

# A base class for the {Encryptor} and {Decryptor} classes.
# Handles a lot of the particulars of signing, key generation,
# and encryption/decryption.
class Base 

  #---------------

  # @param {WordArray} key The private encryption key  
  constructor : ( { key } ) ->
    @key = WordArray.from_buffer key

    # A map from Salt -> KeySets
    @derived_keys = {}

  #---------------

  # @method pbkdf2
  #
  # Run PBKDF2 to yield the encryption and signing keys, given the
  # input `key` and the randomly-generated salt.
  #
  # @param {WordArray} salt The salt to use for key generation.
  # @param {Function} progress_hook A standard progress hook (optional).
  # @param {callback} cb Callback with an {Object} after completion.
  #   The object will map cipher-name to a {WordArray} that is the generated key.
  #
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

  # @private
  # 
  # Check that a key isn't scrubbed. If it is, it's a huge problem, and we should short-circuit
  # encryption.
  # 
  # @param {WordArray} key The key to check for having been scrubbed.
  # @param {String} where Where the check is happening.
  # @param {callback} ecb The callback to fire with an Error, in the case of a scrubbed key.
  # @param {callback} okcb The callback to fire if we're OK to proceed.
  # 
  _check_scrubbed : (key, where, ecb, okcb) ->
    if not key.is_scrubbed() then okcb()
    else ecb (new Error "#{where}: Failed due to scrubbed key!"), null

  #---------------

  # Sign with HMAC-SHA512-SHA-3
  #
  # @param {WordArray} input The text to sign.
  # @param {WordArray} key The signing key
  # @param {WordArray} salt The salt used to generate the derived keys.
  # @param {Function} progress_hook A standard progress hook (optional).
  # @param {callback} cb Call back with `(err,res)` upon completion,
  #   with `res` of type {WordArray} and containing the signature.
  #
  sign : ({input, key, salt, progress_hook}, cb) ->
    await @_check_scrubbed key, "HMAC", cb, defer()
    input = (new WordArray @version.header ).concat(salt).concat(input)
    await Concat.bulk_sign { key, input, progress_hook}, defer(out)
    input.scrub()
    cb null, out

  #---------------

  # Run SALSA20, output (IV || ciphertext)
  #
  # @param {WordArray} input The input plaintext
  # @param {WordArray} key The Salsa20-specific encryption key (32 bytes)
  # @param {WordArray} iv The Salsa20-specific IV (24 bytes as per XSalsa20)
  # @param {bool} output_iv Whether or not to output the IV with the ciphertext
  # @param {callback} cb Callback on completion with `(err, res)`.  `res` will
  #   be a {WordArray} of the ciphertext or a concatenation of the IV and 
  #   the ciphertext, depending on the `output_iv` option.
  run_salsa20 : ({ input, key, iv, output_iv, progress_hook }, cb) ->
    await @_check_scrubbed key, "Salsa20", cb, defer()
    await salsa20.bulk_encrypt { input, key, iv, progress_hook}, defer ct
    ct = iv.clone().concat(ct) if output_iv
    cb null, ct

  #---------------

  # Run Twofish, output (IV || ciphertext).
  #
  # @param {WordArray} input The input plaintext
  # @param {WordArray} key The Twofish-specific encryption key (32 bytes)
  # @param {WordArray} iv The Twofish-specific IV (16 bytes)
  # @param {callback} cb Callback on completion with `(err, res)`.  `res` will
  #   be a {WordArray} of the concatenation of the IV and 
  #   the ciphertext.
  run_twofish : ({input, key, iv, progress_hook}, cb) ->
    await @_check_scrubbed key, "Twofish", cb, defer()
    block_cipher = new TwoFish key
    await ctr.bulk_encrypt { block_cipher, iv, input, progress_hook, what : "twofish" }, defer ct
    block_cipher.scrub()
    cb null, iv.clone().concat(ct)

  #---------------

  # Run AES, output (IV || ciphertext).
  #
  # @param {WordArray} input The input plaintext
  # @param {WordArray} key The AES-specific encryption key (32 bytes)
  # @param {WordArray} iv The AES-specific IV (16 bytes)
  # @param {callback} cb Callback on completion with `(err, res)`.  `res` will
  #   be a {WordArray} of the concatenation of the IV and 
  #   the ciphertext.
  run_aes : ({input, key, iv, progress_hook}, cb) ->
    await @_check_scrubbed key, "AES", cb, defer()
    block_cipher = new AES key
    await ctr.bulk_encrypt { block_cipher, iv, input, progress_hook, what : "aes" }, defer ct
    block_cipher.scrub()
    cb null, iv.clone().concat(ct)

  #---------------

  # Scrub all internal state that may be sensitive.  Use it after you're done
  # with the Encryptor.
  scrub : () ->
    @key.scrub()
    for salt,key_ring of @derived_keys
      for key in key_ring
        key.scrub()

#========================================================================

# ### Encryptor
#
# The high-level Encryption engine for TripleSec.  You should allocate one
# instance of this object for each secret key you are dealing with.  Reusing
# the same Encryptor object will allow you to avoid rerunning PBKDF2 with
# each encryption.  If you want to use new salt with every encryption,
# you can call `resalt` as needed.   The `run` method is called to 
# run the encryption engine.
#
# Here is an example of multiple encryptions with salt reuse, in CoffeeScript:
# @example 
# ```coffeescript
# key = new Buffer "pitying web andiron impacts bought"
# data = new Buffer "this is my secret data"
# eng = new Encryptor { key } 
# eng.run { data }, (err, res) ->
#    console.log "Ciphertext 1: " + res.toString('hex')
#    data = Buffer.concat data, new Buffer " which just got bigger"
#    eng.run { data }, (err, res) ->
#      console.log "Ciphertext 2: " + res.toString('hex')
#```
# 
# Or equivalently in JavaScript:
# @example 
# ```javascript
# var key = new Buffer("pitying web andiron impacts bought");
# var data = new Buffer("this is my secret data");
# var eng = new Encryptor({ key : key });
# eng.run({ data : data }, function (err, res) {
#    console.log("Ciphertext 1: " + res.toString('hex'));
#    data = Buffer.concat(data, new Buffer(" which just got bigger"));
#    eng.run({ data : data }), function (err, res) {
#      console.log("Ciphertext 2: " + res.toString('hex'));
#    });
# });
# ```
#
# In the previous two examples, the same salt was used for both ciphertexts.
# To resalt (and regenerate encryption keys):
# @example 
# ```coffeescript
# key = new Buffer "pitying web andiron impacts bought"
# data = new Buffer "this is my secret data"
# eng = new Encryptor { key } 
# eng.run { data }, (err, res) ->
#    console.log "Ciphertext 1: " + res.toString('hex')
#    data = Buffer.concat data, new Buffer " which just got bigger"
#    eng.resalt {}, () ->
#      eng.run { data }, (err, res) ->
#        console.log "Ciphertext 2: " + res.toString('hex')
#```
# 
#
class Encryptor extends Base

  #---------------

  # @property {Object} version The version to encrypt with (only V1 now works).
  version : V[1]

  #---------------
 
  # @param {Buffer} key The secret key
  # @param {Function} rng Call it with the number of Rando bytes you need. It should callback with a WordArray of random bytes
  constructor : ( { key, rng } ) ->
    super { key }
    @rng = rng or prng.generate
    @last_salt = null

  #---------------

  # @private
  # 
  # Pick random IVS, one for each crypto algoritm. Call back
  # with an Object, mapping cipher engine name to a {WordArray}
  # containing the IV.
  #
  # @param {Function} progress_hook A standard progress hook.
  # @param {callback} cb Called back when the resalting completes.
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
  #
  # @param {Function} progress_hook A standard progress hook.
  # @param {callback} cb Called back when the resalting completes.
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
encrypt = ({ key, data, rng, progress_hook}, cb) ->
  enc = new Encryptor { key, rng }
  await enc.run { data, progress_hook }, defer err, ret
  enc.scrub()
  cb err, ret

#========================================================================

exports.V = V
exports.encrypt = encrypt
exports.Base = Base 
exports.Encryptor = Encryptor 

#========================================================================
