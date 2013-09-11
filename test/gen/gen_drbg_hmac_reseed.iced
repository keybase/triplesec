
data = require '../json/HMAC_DRBG_reseed.json'

out = []
for {header,clusters} in data
  if header["SHA-512"]? and header.AdditionalInputLen is '0'
    out = out.concat clusters

console.log "exports.data = #{JSON.stringify out, null, 4};"

