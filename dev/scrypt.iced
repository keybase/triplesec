
argv = require('optimist').argv
{Scrypt} = require '../lib/scrypt'
{XOR} = require '../lib/combine'
{WordArray} = require '../lib/wordarray'
ProgressBar = require 'progress'

klass = if argv.x then XOR else null
scrypt = new Scrypt { N : argv.N, p : argv.p, r : argv.r , c1 : argv.c, klass }
mkbuf = (s) -> WordArray.from_utf8(if s?.length then s else '')
bar = null
last = 0
what_last = null
hit_lim = false

progress_hook = (o) -> 
  if o.what isnt what_last
    bar = new ProgressBar("#{o.what}> [:bar] :percent :etas", { 
      total : o.total
      complete : "="
      incomplete : ' '
      width : 50 })
    what_last = o.what
    last = 0
    hit_lim = false
  unless hit_lim
    bar.tick(o.i - last)
    last = o.i
    hit_lim = (o.i is o.total)

await scrypt.run { 
  key : mkbuf(argv.P),
  salt : mkbuf(argv.s),
  progress_hook : progress_hook,
  dkLen : argv.d }, defer wa
console.log wa.to_hex()
process.exit 0
