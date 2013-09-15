##
##
## Forked from Jeff Mott's CryptoJS
##
##   https://code.google.com/p/crypto-js/
##

util = require './util'

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
    @

  # 
  # Removes insignificant bits.
  #
  clamp : ->
    @words[@sigBytes >>> 2] &= 0xffffffff << (32 - (@sigBytes % 4) * 8);
    @words.length = Math.ceil(@sigBytes / 4)
    @

  #
  # Creates a copy of this word array.
  #
  # @return {WordArray} The clone.
  #
  clone : ->
    new WordArray @words[0...], @sigBytes

  #--------------

  to_buffer : () ->
    out = new Buffer @sigBytes
    p = 0
    for w in @words when (@sigBytes - p) >= 4
      w = util.fixup_uint32 w
      out.writeUInt32BE w, p
      p += 4
    while p < @sigBytes
      ch = (@words[p >>> 2] >>> (24 - (p % 4) * 8)) & 0xff
      out.writeUInt8 ch, p
      p++
    out

  #--------------

  to_utf8 : () -> @to_buffer().toString 'utf8'
  to_hex : () -> @to_buffer().toString 'hex'
  to_uint8_array : () -> new Uint8Array @to_buffer()

  #--------------
  
  @from_buffer : (b) ->
    words = []
    p = 0
    while (b.length - p) >= 4
      words.push b.readUInt32BE p
      p += 4
    if p < b.length
      last = 0
      while p < b.length
        ch = b.readUInt8 p
        last |= (ch << (24 - (p%4) * 8))
        p++
      last = util.fixup_uint32 last
      words.push last
    new WordArray words, b.length

  #--------------
  
  @from_buffer_le : (b) ->
    words = []
    p = 0
    while (b.length - p) >= 4
      words.push b.readUInt32LE p
      p += 4
    if p < b.length
      last = 0
      while p < b.length
        ch = b.readUInt8 p
        last |= (ch << ((p%4) * 8))
        p++
      last = util.fixup_uint32 last
      words.push last
    new WordArray words, b.length

  #--------------

  @from_utf8 : (s) -> WordArray.from_buffer new Buffer(s, 'utf8')
  @from_utf8_le : (s) -> WordArray.from_buffer_le new Buffer(s, 'utf8')
  @from_hex : (s) -> WordArray.from_buffer new Buffer(s, 'hex')
  @from_hex_le = (s) -> WordArray.from_buffer_le new Buffer(s, 'hex')
  
  #--------------

  # Important! Don't short-circuit since that enables a
  # forging attack....
  equal : (wa) ->
    ret = true
    if wa.sigBytes isnt @sigBytes then ret = false
    else
      for w,i in @words
        ret = false unless util.fixup_uint32(w) is util.fixup_uint32(wa.words[i])
    ret

  #--------------

  xor : (wa2, { dst_offset, src_offset, n_words } ) ->
    dst_offset = 0 unless dst_offset
    src_offset = 0 unless src_offset
    n_words = wa2.words.length - src_offset unless n_words?

    if @words.length < dst_offset + n_words
      throw new Error "dest range exceeded (#{@words.length} < #{dst_offset + n_words})"
    if wa2.words.length <  src_offset + n_words
      throw new Error "source range exceeded"

    for i in [0...n_words]
      tmp = @words[dst_offset + i] ^ wa2.words[src_offset + i]
      @words[dst_offset+i] = util.fixup_uint32 tmp
    @

  #--------------

  truncate : (n_bytes) ->
    throw new Error "Cannot truncate: #{n_bytes} > #{@sigBytes}" unless n_bytes <= @sigBytes
    n_words = Math.ceil(n_bytes/4)
    new WordArray @words[0...n_words], n_bytes

  #--------------

  unshift : (n_words) ->
    if @words.length >= n_words
      ret = @words.splice 0, n_words
      @sigBytes -= n_words*4
      new WordArray ret
    else
      null

  #--------------

  is_scrubbed : () ->
    for w in @words when w isnt 0
      return false
    true
    
  #--------------

  scrub : () ->
    util.scrub_vec @words

  #--------------

  # @param{number} low The low word to include in the output slice
  # @param{number} hi The hi word to include in the output slice (exclusive)
  slice : (low, hi) ->
    n = @words.length
    unless (low < hi) and (hi <= n)
      throw new Error "Bad WordArray slice [#{low},#{hi})] when only #{n} avail"
    sb = (hi - low)*4
    if hi is n then sb -= (n*4 - @sigBytes)
    new WordArray @words[low...hi], sb

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
    new X64WordArray (w.clone() for w in @words), @sigBytes

#=======================================================================

