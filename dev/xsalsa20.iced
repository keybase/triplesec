
{Salsa20} = require '../src/salsa20'
{WordArray} = require '../src/wordarray'

argv = require('optimist').alias('n','nonce').alias('k','key').argv

eng = new Salsa20 (WordArray.from_hex argv.k), (WordArray.from_hex argv.n)
pad = eng.getBytes 64
console.log pad.toString 'hex'

