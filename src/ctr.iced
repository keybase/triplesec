
{WordArray} = require './wordarray'
{StreamCipher} = require './algbase'

#=========================================

exports.Counter = class Counter

  WORD_MAX : 0xffffffff

  #---------------------------

  constructor : ({ value, len }) ->
    @_value = if value? then value.clone()
    else
      len = 2 unless len?
      new WordArray (0 for i in[0...len])

  #---------------------------

  inc : () ->
    go = true
    i = @_value.words.length - 1
    while go and i >= 0
      if ((++@_value.words[i]) > Counter.WORD_MAX) then @_value.words[i] = 0
      else go = false
      i--
    @

  #---------------------------

  # increment little-endian style, meaning, increment the leftmost byte
  # first, and then go left-to-right
  inc_le : () ->
    go = true
    i = 0
    while go and i < @_value.words.length
      if ((++@_value.words[i]) > Counter.WORD_MAX) then @_value.words[i] = 0
      else go = false
      i++
    @

  #---------------------------

  get : () -> @_value
  
  #---------------------------

  copy : () -> @_value.clone()

#=========================================

class KeyStream

  constructor : ({@block_cipher, @iv, @len}) ->
    unless (@iv.sigBytes is @block_cipher.blockSize)
      throw new Error "IV is wrong length (#{@iv.sigBytes})"

  generate_input : () ->
    @nblocks = Math.ceil @len / @block_cipher.blockSize
    ctr = new Counter { value : @iv }
    pad_words = (ctr.inc().copy().words for i in [0...nblocks])
    flat = [].concat pad_words...
    @keystream = new WordArray flat, @len

  encrypt : () ->
    for i in [0...@len] by @block_cipher.blockSize
      @block_cipher.encryptBlock @pad.words, i

  run : () ->
    @generate_input()
    @encrypt()
    @keystream

#---------------

exports.gen_keystream = ({block_cipher, iv, len} ) ->
  (new KeyStream { block_cipher, iv, len}).run()

#=========================================

exports.Cipher = class Cipher extends StreamCipher

  constructor :( { @block_cipher, @iv } ) ->
    super()
    @bsiw = @block_cipher.blockSize / 4 # block size in words
    unless (@iv.sigBytes is @block_cipher.blockSize)
      throw new Error "IV is wrong length (#{@iv.sigBytes})"
    @ctr = new Counter { value : @iv }   

  get_pad : () ->
    pad = @ctr.copy()
    @ctr.inc()
    @block_cipher.encryptBlock pad.words

#---------------

exports.encrypt = encrypt = ({block_cipher, iv, input}) ->
  (new Cipher { block_cipher, iv}).encrypt input

#=========================================
