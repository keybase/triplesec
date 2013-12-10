
{SHA3} = require '../src/sha3'
{WordArray} = require '../src/wordarray'
{sign} = require '../src/hmac'

key = WordArray.from_hex process.argv[2]
input = WordArray.from_hex process.argv[3]
sig = sign { key , input, hash_class : SHA3 }
console.log sig.to_hex()
