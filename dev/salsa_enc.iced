{WordArray} = require '../lib/wordarray'
salsa20 = require '../lib/salsa20'

key = WordArray.from_utf8 '11112222333344445555666677778888'
iv = WordArray.from_utf8 'aaaabbbbccccddddeeeeffff'
text = "hello my name is max and i work at crashmix LLC.  we don't have a product."
input = WordArray.from_utf8 text

console.log input.to_hex()
x = salsa20.encrypt { key, iv, input }
console.log x.to_hex()
y = salsa20.encrypt { key, iv, input : x }
console.log y.to_hex()
console.log y.to_utf8()
