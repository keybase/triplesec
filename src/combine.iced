{HMAC} = require './hmac'
{SHA512} = require './sha512'
{SHA3} = require './sha3'

#=============================================

class Base

  @keySize : HMAC.keySize
  keySize : Base.keySize
  @outputSize : HMAC.outputSize
  outputSize : Base.outputSize

  constructor : (key, klasses = [ SHA512, SHA3 ] ) ->
    @hashers = (new HMAC(key, klass) for klass in klasses)
  reset : ->
    (h.reset() for h in @hashers)
    @
  update : (w) ->
    (h.update(w) for h in @hashers)
    @
  scrub : () ->
    (h.scrub() for h in @hasher)
    @
  finalize : (w) ->
    hashes = (h.finalize(w) for h in @hashers)
    out = hashes[0]
    for h in hashes[1...]
      @coalesce out, h
      h.scrub()
    out

#=============================================

exports.Concat = class Concat extends Base
  coalesce : (out, h) -> out.concat h
  @sign : ( { key , input } ) -> (new Concat key).finalize(input)

#=============================================

exports.XOR = class XOR extends Base
  coalesce : (out, h) -> out.xor h, {}
  @sign : ( { key , input } ) -> (new XOR key).finalize(input)

#=============================================

