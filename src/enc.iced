
{WordArray}   = require './wordarray'
salsa20       = require './salsa20'
{AES}         = require './aes'
{TwoFish}     = require './twofish'
ctr           = require './ctr'
hmac          = require './hmac'
{SHA512}      = require './sha512'
{pbkdf2}      = require './pbkdf2'
util          = require './util'

#========================================================================

exports.V = V = 
  "1" : 
    header :
      [ 0x1c94d7de, 1 ]
    pbkdf2_iters : 2048
    salt_size : 8 # 8 bytes of salt is good enough!

#========================================================================

exports.Base = class Base 

  #---------------
  
  constructor : ( { key } ) ->
    @key = WordArray.from_buffer key

    # A map from Salt -> KeySets
    @derived_keys = {}

  #---------------

  pbkdf2 : (salt, cb) ->
    # Check the cache first
    salt_hex = salt.to_hex()

    unless (keys = @derived_keys[salt_hex])?

      lens = 
        hmac    : hmac.HMAC.keySize
        aes     : AES.keySize
        twofish : TwoFish.keySize
        salsa20 : salsa20.Salsa20.keySize
      tot = 0
      (tot += v for k,v of lens)

      # The key gets scrubbed by pbkdf2, so we need to clone our copy of it.
      key = @key.clone()
      await pbkdf2 { key, salt, c : @version.pbkdf2_iters, dkLen : tot }, defer raw
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

  sign : ({input, key, salt}, cb) ->
    input = (new WordArray @version.header ).concat(salt).concat(input)
    await hmac.sign { key, input }, defer out
    cb out

  #---------------

  run_salsa20 : ({ input, key, iv, output_iv }, cb) ->
    await salsa20.encrypt { input, key, iv}, defer ct
    ct = iv.clone().concat(ct) if output_iv
    cb ct

  #---------------

  run_twofish : ({input, key, iv}, cb) ->
    block_cipher = new TwoFish key
    await ctr.encrypt { block_cipher, iv, input }, defer ct
    cb iv.clone().concat(ct)

  #---------------

  run_aes : ({input, key, iv}, cb) ->
    block_cipher = new AES key
    await ctr.encrypt { block_cipher, iv, input }, defer ct
    cb iv.clone().concat(ct)

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
#  @param {Function} rng Call it with the number of Rando bytes you need
#
#
exports.Encryptor = class Encryptor extends Base

  #---------------

  version : V[1]

  #---------------
  
  constructor : ( { key, @rng } ) ->
    super { key }
    @last_salt = null

  #---------------

  pick_random_ivs : (cb) ->
    iv_lens =
      aes : AES.ivSize
      twofish : TwoFish.ivSize
      salsa20 : salsa20.Salsa20.ivSize
    ivs = {}
    for k,v of iv_lens
      ivs[k] = WordArray.from_buffer @rng(v)
    cb ivs

  #---------------

  # Regenerate the salt. Reinitialize the keys. You have to do this
  # once, but if you don't do it again, you'll just wind up using the
  # same salt.
  resalt : () ->
    @salt = WordArray.from_buffer @rng @version.salt_size
    await @pbkdf2 @salt, defer @keys
 
  #---------------

  # @param {Buffer} data the data to encrypt 
  # @param {callback} cb With an (err,res) pair, res is the buffer with the encrypted data
  run : ( data, cb ) ->
    await @resalt defer() unless @salt?
    await @pick_random_ivs defer ivs
    pt   = WordArray.from_buffer data
    await @run_salsa20 { input : pt,  key : @keys.salsa20, iv : ivs.salsa20, output_iv : true }, defer ct1
    await @run_twofish { input : ct1, key : @keys.twofish, iv : ivs.twofish }, defer ct2
    await @run_aes     { input : ct2, key : @keys.aes,     iv : ivs.aes     }, defer ct3
    await @sign        { input : ct3, key : @keys.hmac,    @salt            }, defer sig
    ret = (new WordArray(@version.header)).concat(@salt).concat(sig).concat(ct3).to_buffer()
    cb null, ret

#========================================================================

# 
# encrypt data using the triple-sec 3x security engine, which is:
#
#      1. Encrypt PT with Salsa20
#      2. Encrypt the result of 1 with 2Fish-256-CTR
#      3. Encrypt the result of 2 with AES-256-CTR
#      4. MAC with HMAC-SHA512.  
#
# @param {Buffer} key The secret key.  This data is scrubbed after use, so copy it
#   if you want to keep track of it.
# @param {Buffer} data The data to encrypt.  Again, this data is scrubber after
#   use, so copy it if you need it later.
# @param {Function} rng A function that takes as input n and outputs n truly
#   random bytes.  You must give a real RNG here and not something fake.
#   You can try require('./rng').rng for starters.
# @param {callback} cb Callback with an (err,res) pair.
#
exports.encrypt = encrypt = ({ key, data, rng}, cb) ->
  enc = new Encryptor { key, rng}
  await enc.run data, defer err, ret
  util.scrub_buffer data
  enc.scrub()
  cb err, ret

#========================================================================
