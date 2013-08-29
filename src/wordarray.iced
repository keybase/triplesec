##
##
## Forked from Jeff Mott's CryptoJS
##
##   https://code.google.com/p/crypto-js/
##

#=======================================================================

exports.WordArray = class WordArray

  # Initializes a newly created word array.
  #
  #  @param {Array} words (Optional) An array of 32-bit words.
  #  @param {number} sigBytes (Optional) The number of significant bytes in the words.
  #
  # @example
  #
  #   wordArray = new WordArray
  #   wordArray = new WordArray [0x00010203, 0x04050607]
  #   wordArray = new WordArray [0x00010203, 0x04050607], 6
  #
  constructor : (words, sigBytes) ->
    @words = words || []
    @sigBytes = if sigBytes? then sigBytes else @words.length * 4

  # 
  # Concatenates a word array to this word array.
  # 
  # @param {WordArray} wordArray The word array to append.
  #
  # @return {WordArray} This word array.
  #
  # @example
  # 
  #     wordArray1.concat(wordArray2)
  #
  concat : (wordArray) ->
    # Shortcuts
    thatWords = wordArray.words;
    thatSigBytes = wordArray.sigBytes;

    # Clamp excess bits
    @clamp()

    # Concat
    if @sigBytes % 4
      # Copy one byte at a time
      for i in [0...thatSigBytes] 
        thatByte = (thatWords[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff
        @words[(@sigBytes + i) >>> 2] |= thatByte << (24 - ((@sigBytes + i) % 4) * 8)
    else
      @words = @words.concat thatWords

    @sigBytes += thatSigBytes

    # Chainable
    @

  # 
  # Removes insignificant bits.
  #
  clamp : ->
    @words[@sigBytes >>> 2] &= 0xffffffff << (32 - (@sigBytes % 4) * 8);
    @words.length = Math.ceil(@sigBytes / 4)

  #
  # Creates a copy of this word array.
  #
  # @return {WordArray} The clone.
  #
  clone : ->
    new WordArray @words[0...], @sigBytes

#=======================================================================

exports.X64Word = class X64Word
  constructor : (@high, @low) ->
  clone : -> new X64Word @high, @low

#=======================================================================

# An array of 64-bit words
#  @property {Array} words The array of CryptoJS.x64.Word objects.
#  @property {number} sigBytes The number of significant bytes in this word array.
exports.X64WordArray = class X64WordArray

  #
  # @param {array} words (optional) an array of X64Word objects.
  # @param {number} sigbytes (optional) the number of significant bytes in the words.
  #
  # @example
  #
  #     wordarray = new X64WordArray()
  #
  #     wordarray = new X64WordArray([
  #         new X64Word(0x00010203, 0x04050607),
  #         new X64Word (0x18191a1b, 0x1c1d1e1f)
  #     ])
  #     wordarray = new X64WordArray([
  #         new X64Word(0x00010203, 0x04050607),
  #         new X64Word (0x18191a1b, 0x1c1d1e1f)
  #     ],10)
  #
  #
  constructor : (words, @sigBytes) ->
    @words = words or []
    @sigBytes = @words.length * 8 unless @sigBytes

  #
  # Converts this 64-bit word array to a 32-bit word array.
  #
  # @return {CryptoJS.lib.WordArray} This word array's data as a 32-bit word array.
  #
  toX32 : ->
    v = []
    for w in @words
      v.push w.high
      v.push w.low
    new WordArray v, @sigBytes

  clone : -> 
    new WordArray (w.clone for w in @words), @word.sigBytes

#=======================================================================

