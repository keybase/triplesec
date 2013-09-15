{HMAC,bulk_sign} = require './hmac'
{SHA512} = require './sha512'
{SHA3} = require './sha3'

#=============================================

class CombineBase

  @keySize : HMAC.keySize
  keySize : CombineBase.keySize

  constructor : (key, klasses = [ SHA512, SHA3 ] ) ->
    @hashers = (new HMAC(key, klass) for klass in klasses)
    @hasherBlockSize = @hashers[0].hasherBlockSize
    @hasherBlockSizeBytes = @hasherBlockSize * 4
  reset : ->
    (h.reset() for h in @hashers)
    @
  update : (w) ->
    (h.update(w) for h in @hashers)
    @
  scrub : () ->
    (h.scrub() for h in @hashers)
    @
  finalize : (w) ->
    hashes = (h.finalize(w) for h in @hashers)
    out = hashes[0]
    for h in hashes[1...]
      @coalesce out, h
      h.scrub()
    out

#=============================================

exports.Concat = class Concat extends CombineBase
  @outputSize : HMAC.outputSize*2
  outputSize : Concat.outputSize
  coalesce : (out, h) -> out.concat h
  get_output_size : () -> @outputSize
  @sign : ( { key , input } ) -> (new Concat key).finalize(input)
  @bulk_sign : (args, cb) ->
    args.klass = Concat
    bulk_sign args, cb

#=============================================

exports.XOR = class XOR extends CombineBase
  @outputSize : HMAC.outputSize
  outputSize : XOR.outputSize
  coalesce : (out, h) -> out.xor h, {}
  get_output_size : () -> @outputSize
  @sign : ( { key , input } ) -> (new XOR key).finalize(input)
  @bulk_sign : (args, cb) ->
    args.klass = XOR
    bulk_sign args, cb

#=============================================

