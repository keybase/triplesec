
{WordArray}   = require './wordarray'
salsa20       = require './salsa20'
{AES}         = require './aes'
{TwoFish}     = require './twofish'
{Cipher}      = require './ctr'
{pack,unpack} = require 'purepack'

#========================================================================

#
# Encrypt the given data with the given key
#
#  @param {Buffer} key - A buffer with the keystream data in it
#  @param {Buffer} data - The data to encrypt
#
#  @returns {Buffer} a buffer with the encrypted data
#
class Encryptor 

  #---------------
  
  version : 1

  #---------------
  
  constructor : ( { @key, @rng } ) ->

  #---------------
  
  run : ( data ) ->
    keys = @pbkdf2()
    ivs  = @pick_random_ivs()
    pt   = WordArray.from_buffer data
    ct1  = @run_salsa20 { input : pt,  key : keys.salsa20, iv : ivs.salsa20 }
    ct2  = @run_twofish { input : ct1, key : keys.twofish, iv : ivs.twofish }
    ct3  = @run_aes     { input : ct2, key : keys.aes,     iv : ivs.aes     }
    sig  = @sign        { input : ct3, key : keys.hmac                      }
    obj  = [ @version, sig, ct3 ]
    ret  = new Buffer(pack(obj, 'buffer'))
    ret

#========================================================================

exports.encrypt = ({ key, data, rng}) ->
