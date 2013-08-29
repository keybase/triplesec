##
##
## Forked from Jeff Mott's CryptoJS
##
##   https://code.google.com/p/crypto-js/
##

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
