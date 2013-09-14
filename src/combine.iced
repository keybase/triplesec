
#=============================================

class Base

  @keySize : HMAC.keySize
  keySize : Base.keySize
  @outputSize : HMAC.outputSize
  outputSize : Base.outputSize

  constructor : (key, klasses = [ SHA512, SHA3 ] ) ->
    @hashers = (new HMAC(klass, key) for klass in klasses)
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
exports.XOR = class XOR extends Base
  coalesce : (out, h) -> out.xor h, {}
  
#=============================================

