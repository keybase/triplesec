
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

  pbkdf2 : (salt) ->
    # Check the cache first
    salt_hex = salt.to_hex()
    return k if (k = @derived_keys[salt_hex])?

    lens = 
      hmac    : hmac.HMAC.keySize
      aes     : AES.keySize
      twofish : TwoFish.keySize
      salsa20 : salsa20.Salsa20.keySize
    tot = 0
    (tot += v for k,v of lens)

    # The key gets scrubbed by pbkdf2, so we need to clone our copy of it.
    key = @key.clone()
    raw = pbkdf2 { key, salt, c : @version.pbkdf2_iters, dkLen : tot }
    keys = {}
    i = 0
    for k,v of lens
      len = v/4
      end = i + len
      keys[k] = new WordArray raw.words[i...end]
      i = end
    @derived_keys[salt_hex] = keys
    keys

  #---------------

  sign : ({input, key, salt}) ->
    input = (new WordArray @version.header ).concat(salt).concat(input)
    out = hmac.sign { key, input }
    out

  #---------------

  run_salsa20 : ({ input, key, iv, output_iv }) ->
    ct = salsa20.encrypt { input, key, iv}
    if output_iv then iv.clone().concat ct
    else ct

  #---------------

  run_twofish : ({input, key, iv}) ->
    block_cipher = new TwoFish key
    iv.clone().concat ctr.encrypt { block_cipher, iv, input }

  #---------------

  run_aes : ({input, key, iv}) ->
    block_cipher = new AES key
    iv.clone().concat ctr.encrypt { block_cipher, iv, input }

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

  pick_random_ivs : () ->
    iv_lens =
      aes : AES.ivSize
      twofish : TwoFish.ivSize
      salsa20 : salsa20.Salsa20.ivSize
    ivs = {}
    for k,v of iv_lens
      ivs[k] = WordArray.from_buffer @rng(v)
    ivs

  #---------------

  # Regenerate the salt. Reinitialize the keys. You have to do this
  # once, but if you don't do it again, you'll just wind up using the
  # same salt.
  resalt : () ->
    @salt = WordArray.from_buffer @rng @version.salt_size
    @keys = @pbkdf2 @salt
    @ 
 
  #---------------

  # @param {Buffer} data the data to encrypt 
  # @returns {Buffer} a buffer with the encrypted data
  run : ( data ) ->
    @resalt() unless @salt?
    ivs  = @pick_random_ivs()
    pt   = WordArray.from_buffer data
    ct1  = @run_salsa20 { input : pt,  key : @keys.salsa20, iv : ivs.salsa20, output_iv : true }
    ct2  = @run_twofish { input : ct1, key : @keys.twofish, iv : ivs.twofish }
    ct3  = @run_aes     { input : ct2, key : @keys.aes,     iv : ivs.aes     }
    sig  = @sign        { input : ct3, key : @keys.hmac,    @salt }
    (new WordArray(@version.header)).concat(@salt).concat(sig).concat(ct3).to_buffer()

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
#
# @return {Buffer} The ciphertext.
#
exports.encrypt = encrypt = ({ key, data, rng}) ->
  enc = new Encryptor { key, rng}
  ret = enc.run(data)
  util.scrub_buffer data
  enc.scrub()
  ret

#========================================================================
