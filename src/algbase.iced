##
##
## Forked from Jeff Mott's CryptoJS
##
##   https://code.google.com/p/crypto-js/
##

{WordArray} = require './wordarray'
util = require './util'

#=======================================================================

#
# Abstract buffered block algorithm template.
#
# The property blockSize must be implemented in a concrete subtype.
#
# @property {number} _minBufferSize The number of blocks that should be kept unprocessed in the buffer. Default: 0
#
exports.BufferedBlockAlgorithm = class BufferedBlockAlgorithm 

  _minBufferSize : 0

  constructor : () ->
    @reset()

  #
  # Resets this block algorithm's data buffer to its initial state.
  #
  reset : () ->
    @_data = new WordArray()
    @_nDataBytes = 0

  # Adds new data to this block algorithm's buffer.
  #
  # @param {WordArray} data The data to append. Strings are converted to a WordArray using UTF-8.
  #
  # @example
  #     bufferedBlockAlgorithm._append(wordArray);
  _append : (data) ->
    @_data.concat data
    @_nDataBytes += data.sigBytes

  #
  # Processes available data blocks.
  # 
  # This method invokes _doProcessBlock(offset), which must be implemented by a concrete subtype.
  #
  # @param {boolean} doFlush Whether all blocks and partial blocks should be processed.
  #
  # @return {WordArray} The processed data.
  #
  # @example
  # 
  #   processedData = bufferedBlockAlgorithm._process();
  #   processedData = bufferedBlockAlgorithm._process(!!'flush');
  #
  _process : (doFlush) ->
    data = @_data
    dataWords = data.words
    dataSigBytes = data.sigBytes
    blockSizeBytes = @blockSize * 4

    # Count blocks ready
    nBlocksReady = dataSigBytes / blockSizeBytes
    if doFlush
      # Round up to include partial blocks
      nBlocksReady = Math.ceil nBlocksReady
    else
      # Round down to include only full blocks,
      # less the number of blocks that must remain in the buffer
      nBlocksReady = Math.max((nBlocksReady | 0) - this._minBufferSize, 0);

    # Count words ready
    nWordsReady = nBlocksReady * @blockSize

    #Count bytes ready
    nBytesReady = Math.min(nWordsReady * 4, dataSigBytes)

    # Process blocks
    if nWordsReady
      for offset in [0...nWordsReady] by @blockSize 
        # Perform concrete-algorithm logic
        @_doProcessBlock dataWords, offset

      # Remove processed words
      processedWords = dataWords.splice 0, nWordsReady
      data.sigBytes -= nBytesReady

    # Return processed words
    new WordArray processedWords, nBytesReady

  #
  # Creates a copy of this object.
  #
  # @return {Object} The clone.
  #
  copy_to : (out) ->
    out._data = @_data.clone()
    out._nDataBytes = @_nDataBytes

  clone : ->
    obj = new BufferedBlockAlgorithm()
    @copy_to obj
    obj

#=======================================================================

#
# Abstract hasher template.
#
# @property {number} blockSize The number of 32-bit words this hasher 
#   operates on. Default: 16 (512 bits)
#
exports.Hasher = class Hasher extends BufferedBlockAlgorithm

  #
  # Initializes a newly created hasher.
  # 
  # @param {Object} cfg (Optional) The configuration options to use 
  #    for this hash computation.
  # 
  constructor : (@cfg) ->
    super()

  #
  # Resets this hasher to its initial state.
  #
  reset : () ->
    super()
    # Perform concrete-hasher logic
    @_doReset()
    @ 
  
  #
  # Updates this hasher with a message.
  #
  # @param {WordArray} messageUpdate The message to append.
  #
  # @return {Hasher} This hasher.
  #
  update : (messageUpdate) ->
    @_append(messageUpdate)
    @_process()
    @

  #
  # Finalizes the hash computation.
  # Note that the finalize operation is effectively a destructive, 
  #  read-once operation.
  #
  # @param {WordArray} messageUpdate (Optional) A final message update.
  #
  # @return {WordArray} The hash.
  #
  # @example
  #
  #     hash = hasher.finalize()
  #     hash = hasher.finalize(wordArray)
  #
  finalize : (messageUpdate) ->
    @_append messageUpdate if messageUpdate
    @_doFinalize()

#=======================================================================

exports.BlockCipher = class BlockCipheGr
  constructor : (key) ->
  encryptBlock : (M, offset) ->
    
#=======================================================================

exports.StreamCipher = class StreamCipher

  constructor : () ->

  # Encrypt one block's worth of data. Use the next block
  # in the keystream (order matters here!). Call into the 
  # virtual @get_pad() function to get the pad from the underlying
  # block cipher for this block.
  #
  #   @param {WordArray} word_array The WordArray to operator on
  #   @param {number} dst_offset The offset to operate on, in wordGs
  #   @returns {number} the number of blocks encrypted
  encryptBlock : (word_array, dst_offset = 0) ->
    pad = @get_pad()
    n_words = Math.min(word_array.words.length - dst_offset, @bsiw)
    word_array.xor pad, { dst_offset, n_words }
    pad.scrub()
    @bsiw

  #---------------------

  encrypt : (word_array) ->
    for i in [0...word_array.words.length] by @bsiw
      @encryptBlock word_array, i
    word_array

  #---------------------

  bulk_encrypt : ({input, progress_hook, what}, cb) ->
    slice_args = 
      update : (lo,hi) =>
        for i in [lo...hi] by @bsiw
          @encryptBlock input, i
      finalize : () -> input
      default_n : @bsiw * 1024
    async_args = {progress_hook, cb, what }
    util.bulk input.sigBytes, slice_args, async_args

#=======================================================================

