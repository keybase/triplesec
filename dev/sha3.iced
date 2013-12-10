
{transform} = require '../src/sha3'
{WordArray} = require '../src/wordarray'

inp = WordArray.from_hex process.argv[2]
console.log transform(inp).to_hex()
