
{prng} = require 'crypto'
{sign} = require '../src/hmax'
{WordArray} = require '../src/wordarray'

out = []
for kl in [16...128] by 4
  for ml in [0...2048] by 256
    k = prng kl
    m = prng ml
    s = sign({ key : WordArray.from_buffer(k), input : WordArray.from_buffer(m) }).to_hex()
    out.push { key : k.toString('hex'), msg : m.toString('hex'), sig : s }

console.log "exports.data = #{JSON.stringify out, null, 4};"