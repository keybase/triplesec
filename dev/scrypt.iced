
argv = require('optimist').argv
{Scrypt} = require '../lib/scrypt'
{XOR} = require '../lib/combine'
{WordArray} = require '../lib/wordarray'

klass = if argv.x then XOR else null
scrypt = new Scrypt { N : N, p : argv.p, r : argv.r , c : argv.c, klass }
mkbuf = (s) -> WordArray.from_utf8(if s?.length then s else '')

await scrypt.run { 
  key : mkbuf(argv.P),
  salt : mkbuf(argv.s),
  dkLen : argv.d }, defer wa
console.log wa.to_hex()