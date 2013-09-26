raw = require '../json/SHA3_short.json'

vectors = raw[0].clusters
out = for v in vectors when ((l = parseInt(v.Len)) % 8 is 0)
  # Truncate the message so we don't have to encode length too
  v.Msg = v.Msg[0...(l*2)]
  v

console.log "exports.data = #{JSON.stringify out, null, 4};"
