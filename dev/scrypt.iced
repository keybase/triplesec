
argv = require('optimist').argv
{Scrypt} = require '../lib/scrypt'
{XOR} = require '../lib/combine'
{WordArray} = require '../lib/wordarray'
ProgressBar = require 'progress'

klass = if argv.x then XOR else null
scrypt = new Scrypt { N : argv.N, p : argv.p, r : argv.r , c : argv.c, klass }
mkbuf = (s) -> WordArray.from_utf8(if s?.length then s else '')
bar = null
last = 0
progress_hook = (o) -> 
  if o.what is 'scrypt'
    if not bar then bar = new ProgressBar("Scrypt> [:bar] :percent :etas", { 
      total : o.total
      complete : "="
      incomplete : ' '
      width : 50 })
    bar.tick(o.i - last)
    last = o.i

await scrypt.run { 
  key : mkbuf(argv.P),
  salt : mkbuf(argv.s),
  progress_hook : progress_hook,
  dkLen : argv.d }, defer wa
console.log wa.to_hex()
