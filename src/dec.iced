
{WordArray}   = require './wordarray'
salsa20       = require './salsa20'
{AES}         = require './aes'
{TwoFish}     = require './twofish'
ctr           = require './ctr'
hmac          = require './hmac'
{SHA512}      = require './sha512'
{pbkdf2}      = require './pbkdf2'
{Base,V}      = require './enc'

#========================================================================

#
# Decrypt the given data with the given key
#
#  @param {Buffer} key  A buffer with the keystream data in it
#  @param {Buffer} salt Salt for key derivation, should be the user's email address
#
class Decryptor extends Base

  #----------------------

  version : V[1]

  #----------------------

  constructor : ( { key, salt } ) ->
    super { key, salt }
    @_i = 0

  #----------------------

  read_header : () ->
    wa = @ct.unshift 2
    throw new Error "Cipher text underrun in header" unless wa?
    throw new Error "Bad header" unless wa.equal new WordArray @version.header

  #----------------------

  verify_sig : (key) ->
    received = @ct.unshift(hmac.HMAC.outputSize/4)
    throw new Error "Cipher text underrun in signature" unless received?
    computed = @sign { input : @ct, key }
    console.log computed
    console.log received
    throw new Error 'Signature mismatch!' unless received.equal computed

  #----------------------

  unshift_iv  : (n, which) ->
    throw new Error "Ciphertext underrun in #{which}" unless (iv = @ct.unshift n)?
    iv

  #----------------------

  run : ( data ) ->
    keys = @pbkdf2()
    @ct = WordArray.from_buffer data
    @read_header()
    @verify_sig keys.hmac
    ct2 = @run_aes     { iv : @unshift_iv(AES.ivSize),     input : @ct, key : keys.aes }
    ct1 = @run_twofish { iv : @unshift_iv(TwoFish.ivSize), input : @ct, key : keys.twofish }
    pt  = @run_salsa20 { iv : @unshift_iv(Salsa20.ivSize), input : @ct, key : keys.salsa }
    pt.to_buffer()

#========================================================================

exports.decrypt = decrypt = ( { key, salt, data } ) ->
  (new Decryptor { key, salt}).run(data)

#========================================================================

