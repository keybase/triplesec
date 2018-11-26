{WordArray} = require './wordarray'
{Hasher} = require './algbase'
sha3lib = require 'sha3'

#================================================================

class SHA3STD extends Hasher

  @outputLength : 512                               # in bits!
  outputLength : SHA3STD.outputLength               # in bits
  @blockSize : (1600 - 2 * SHA3STD.outputLength)/32 # in # of 32-bit words
  blockSize : SHA3STD.blockSize                     # in # of 32-bit words
  @output_size : SHA3STD.outputLength / 8           # in bytes
  output_size : SHA3STD.output_size                 # in bytes

  reset : () ->
    @_hash = new sha3lib.SHA3(512)
    @

  get_output_size : () -> @output_size

  update : (messageUpdate) ->
    @_hash.update(messageUpdate.to_buffer())
    @

  finalize : (messageUpdate) ->
    @_hash.update(messageUpdate.to_buffer()) if messageUpdate
    WordArray.from_buffer(@_hash.digest())

  scrub : () ->
    @reset()
    @

  copy_to : (obj) ->
    super obj
    obj._hash = @_hash

  clone: () ->
    out = new SHA3STD()
    @copy_to out
    out

#================================================================

transform = (x) ->
  out = (new SHA3STD).finalize x
  x.scrub()
  out

#================================================================

exports.SHA3STD = SHA3STD
exports.transform = transform

#================================================================

