
argv = require('optimist').argv
{Scrypt} = require '../src/scrypt'

scrypt = new Scrypt { N : (1 << argv.N), p : argv.p, r : argv.r }
mkbuf = (s) -> new Buffer(if s?.length then s else [])

await scrypt.run { 
  key : mkbuf(argv.P),
  salt : mkbuf(argv.s),
  dkLen : argv.d }, defer buf
console.log buf.toString('hex')