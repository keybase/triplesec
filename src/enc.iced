
{WordArray}   = require './wordarray'
salsa20       = require './salsa20'
{AES}         = require './aes'
{TwoFish}     = require './twofish'
ctr           = require './ctr'
hmac          = require './hmac'
{SHA512}      = require './sha512'
{pbkdf2}      = require './pbkdf2'
crypto        = require 'crypto'

#========================================================================

exports.V = V1 = 
  "1" : 
    header :
      [ 0x1c94d7de, 1 ]
    pbkdf2_iters : 1024

#========================================================================

#
# Encrypt the given data with the given key
#
#  @param {Buffer} key  A buffer with the keystream data in it
#  @param {Buffer} salt Salt for key derivation, should be the user's email address
#  @param {Function} rng Call it with the number of Rando bytes you need
#
#
class Encryptor 

  #---------------

  version : V.1

  #---------------
  
  constructor : ( { key, salt, @rng } ) ->
    @key = WordArray.from_buffer key
    @salt = WordArray.from_buffer salt

  #---------------

  pbkdf2 : () ->
    lens = 
      hmac    : hmac.HMAC.keySize
      aes     : AES.keySize
      twofish : TwoFish.keySize
      salsa20 : salsa20.Salsa20.keySize
    tot = 0
    for k,v of lens
      tot += v
    raw = pbkdf2 { @key, @salt, c : @version.pbkdf2_iters, dkLen : tot }
    keys = {}
    i = 0
    for k,v of lens
      len = v/4
      end = i + len
      keys[k] = new WordArray raw.words[i...end]
      i = end
    keys

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

  run_salsa20 : ({ input, key, iv }) ->
    iv.clone().concat salsa20.encrypt { input, key, iv }

  #---------------

  run_twofish : ({input, key, iv}) ->
    block_cipher = new TwoFish key
    iv.clone().concat ctr.encrypt { block_cipher, iv, input }

  #---------------

  run_aes : ({input, key, iv}) ->
    block_cipher = new AES key
    iv.clone().concat ctr.encrypt { block_cipher, iv, input }

  #---------------

  sign : ({input, key}) ->
    input = (new WordArray @version.header ).concat input
    hmac.sign { key, input }

  #---------------
 
  # @param {Buffer} data the data to encrypt 
  # @returns {Buffer} a buffer with the encrypted data
  run : ( data ) ->
    keys = @pbkdf2()
    ivs  = @pick_random_ivs()
    pt   = WordArray.from_buffer data
    ct1  = @run_salsa20 { input : pt,  key : keys.salsa20, iv : ivs.salsa20 }
    ct2  = @run_twofish { input : ct1, key : keys.twofish, iv : ivs.twofish }
    ct3  = @run_aes     { input : ct2, key : keys.aes,     iv : ivs.aes     }
    sig  = @sign        { input : ct3, key : keys.hmac                      }
    (new WordArray(@version.header)).concat(sig).concat(ct3).to_buffer()

#========================================================================

exports.encrypt = encrypt = ({ key, salt, data, rng}) ->
  (new Encryptor { key, salt, rng}).run(data)

#========================================================================

arg = 
  key : new Buffer 'this be the password'
  salt : new Buffer 'max@okcupid.com'
  data : new Buffer 'this be the secret message!'
  rng : crypto.rng

console.log encrypt(arg).toString 'hex'
