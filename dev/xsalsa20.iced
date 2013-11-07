
{Salsa20} = require '../src/salsa20'
{WordArray} = require '../src/wordarray'

argv = require('optimist').alias('n','nonce').alias('k','key').argv
A = "0123456789abcdef"
alpha = (n) -> (A for i in [0...n]).join("")
key = argv.k or alpha 4
nonce = argv.n or alpha 3

eng = new Salsa20 (WordArray.from_hex key), (WordArray.from_hex nonce)
pad = eng.getBytes 64
console.log pad.toString 'hex'

