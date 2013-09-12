
{WordArray}   = require './wordarray'
salsa20       = require './salsa20'
{AES}         = require './aes'
{TwoFish}     = require './twofish'
ctr           = require './ctr'
hmac          = require './hmac'
{SHA512}      = require './sha512'
{pbkdf2}      = require './pbkdf2'
{Salsa20}     = require './salsa20'
{Base,V}      = require './enc'
{make_esc}    = require 'iced-error'

#========================================================================

#
# Decrypt the given data with the given key
#
#  @param {Buffer} key  A buffer with the keystream data in it
#  @param {Buffer} salt Salt for key derivation, should be the user's email address
#
exports.Decryptor = class Decryptor extends Base

  #----------------------

  version : V[1]

  #----------------------

  constructor : ( { key } ) ->
    super { key }
    @_i = 0

  #----------------------

  read_header : (cb) ->
    err = if not (wa = @ct.unshift 2)?
      new Error "Ciphertext underrun in header"
    else if not (wa.equal new WordArray @version.header)
      new Error "Bad header"
    else null
    cb err

  #----------------------

  verify_sig : (key, cb) ->
    if not (received = @ct.unshift(hmac.HMAC.outputSize/4))?
      err = new Error "Ciphertext underrun in signature"
    else
      await @sign { input : @ct, key, @salt }, defer computed
      err = if received.equal computed then null
      else new Error 'Signature mismatch!'
    cb err

  #----------------------

  unshift_iv  : (n_bytes, which, cb) ->
    err = if (iv = @ct.unshift(n_bytes/4))? then null
    else new Error "Ciphertext underrun in #{which}"
    cb err, iv

  #----------------------

  read_salt : (cb) ->
    err = if not (@salt = @ct.unshift 2)?
      new Error "Ciphertext underrrun in read_salt"
    else
      null
    cb err

  #----------------------

  generate_keys : (cb) ->
    await @pbkdf2 @salt, defer keys
    cb keys

  #----------------------

  run : (data, cb) ->
    # esc = "Error Short-Circuiter".  In the case of an error,
    # we'll forget about the rest of the function and just call back
    # with the error.  If no error, the proceed as normal
    esc = make_esc cb, "Decryptor::run"
    @ct = WordArray.from_buffer data
    await @read_header esc defer()
    await @read_salt esc defer()
    await @generate_keys defer @keys
    await @verify_sig @keys.hmac, esc defer()
    await @unshift_iv AES.ivSize, "AES", esc defer iv
    await @run_aes { iv, input : @ct, key : @keys.aes }, defer ct2
    await @unshift_iv TwoFish.ivSize, "2fish", esc defer iv
    await @run_twofish { iv, input : @ct, key : @keys.twofish }, defer ct1
    await @unshift_iv Salsa20.ivSize, "Salsa", esc defer iv
    await @run_salsa20 { iv, input : @ct, key : @keys.salsa20, output_iv : false }, defer pt
    cb null, pt.to_buffer()

#========================================================================

exports.decrypt = decrypt = ( { key, data } , cb) ->
  dec = (new Decryptor { key })
  await dec.run data, defer err, pt
  dec.scrub()
  cb err, pt

#========================================================================

