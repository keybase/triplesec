
{WordArray}   = require './wordarray'
salsa20       = require './salsa20'
{AES}         = require './aes'
{TwoFish}     = require './twofish'
ctr           = require './ctr'
{Concat}      = require './combine'
{SHA512}      = require './sha512'
{pbkdf2}      = require './pbkdf2'
{Salsa20}     = require './salsa20'
{Base,V}      = require './enc'
{make_esc}    = require 'iced-error'

#========================================================================

# The Decryptor class is the high-level access to the TripleSec decryption
# system.
class Decryptor extends Base

  #----------------------

  # @property {Object} version Right now we only support version 1 of the algorithm
  # (since there is only one version)
  version : V[1]

  #----------------------

  # @param {Buffer} key The input key to use for decryption. Hopefully it's the same
  # key that was used for encryption! If not, we'll get a signature failure.
  constructor : ( { key } ) ->
    super { key }
    @_i = 0

  #----------------------

  # @private
  # 
  # Read the header of the ciphertext. 
  # @param {callback} cb Callback with `null` on success and an {Error} object
  # if there was an error.
  #
  read_header : (cb) ->
    err = if not (wa = @ct.unshift 2)?
      new Error "Ciphertext underrun in header"
    else if not (wa.equal new WordArray @version.header)
      new Error "Bad header"
    else null
    cb err

  #----------------------

  # @private
  #
  # Given an HMAC key, verify that the ciphertext wasn't corrupted int
  # transit and that we're using the right decryption key.
  #
  # @param {WordArray} key The expanded HMAC key
  # @param {callback} cb A callback to call when completed. Callback
  # with null in the case of success, or an {Error} object in the case
  # of failure.
  # 
  verify_sig : (key, cb) ->
    if not (received = @ct.unshift(Concat.get_output_size()/4))?
      err = new Error "Ciphertext underrun in signature"
    else
      await @sign { input : @ct, key, @salt }, defer err, computed
      err = if err? then err
      else if received.equal computed then null
      else new Error 'Signature mismatch or bad decryption key'
    cb err

  #----------------------

  # @private
  #
  # Unshift n_bytes off of the ciphertext to be treated as an IV
  #
  # @param {number} n_bytes The number of bytes to seek.
  # @param {String} which Which encryption primitive it's for.
  # @param {callback} cb Callback on completion with `(err,iv)`.
  # In the case of an error, `err` will be non-null, and otherwise,
  # `iv` will be nonull. Errors are caused by overruning the end
  # of the ciphtertext.
  unshift_iv  : (n_bytes, which, cb) ->
    err = if (iv = @ct.unshift(n_bytes/4))? then null
    else new Error "Ciphertext underrun in #{which}"
    cb err, iv

  #----------------------

  # @private
  #
  # Read the salt of of the ciphertext.  Much like reading an IV
  # out of the ciphertext.
  #
  # @param {callback} cb A callback to call when completed. Call
  # with `null` if there's a success (and `@salt`) is set, or 
  # an {Error} if there was a problem.
  #
  read_salt : (cb) ->
    err = if not (@salt = @ct.unshift 2)?
      new Error "Ciphertext underrrun in read_salt"
    else
      null
    cb err

  #----------------------

  generate_keys : ({progress_hook}, cb) ->
    await @pbkdf2 { @salt, progress_hook }, defer keys
    cb keys

  #----------------------

  run : ({data, progress_hook}, cb) ->
    
    # esc = "Error Short-Circuiter".  In the case of an error,
    # we'll forget about the rest of the function and just call back
    # the outer-level cb with the error.  If no error, then proceed as normal.
    esc = make_esc cb, "Decryptor::run"

    @ct = WordArray.from_buffer data
    await @read_header esc defer()
    await @read_salt esc defer()
    await @generate_keys { progress_hook }, defer @keys
    await @verify_sig @keys.hmac, esc defer()
    await @unshift_iv AES.ivSize, "AES", esc defer iv
    await @run_aes { iv, input : @ct, key : @keys.aes, progress_hook }, esc defer ct2
    await @unshift_iv TwoFish.ivSize, "2fish", esc defer iv
    await @run_twofish { iv, input : @ct, key : @keys.twofish, progress_hook }, esc defer ct1
    await @unshift_iv Salsa20.ivSize, "Salsa", esc defer iv
    await @run_salsa20 { iv, input : @ct, key : @keys.salsa20, output_iv : false, progress_hook }, esc defer pt
    cb null, pt.to_buffer()

#========================================================================

decrypt = ( { key, data, progress_hook } , cb) ->
  dec = (new Decryptor { key })
  await dec.run { data, progress_hook }, defer err, pt
  dec.scrub()
  cb err, pt

#========================================================================

exports.Decryptor = Decryptor
exports.decrypt = decrypt
