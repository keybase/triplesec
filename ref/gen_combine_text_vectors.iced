
{prng} = require 'crypto'
{sign} = require '../src/hmax'
{WordArray} = require '../src/wordarray'

out = []
for kl in [16...128] by 4
  for ml in [0...2048] by 256
    k = prng kl
    m = prng ml
    out.push { key : k.toString('hex'), msg : m.toString('hex') }

console.log "exports.data = #{JSON.stringify out, null, 4};"