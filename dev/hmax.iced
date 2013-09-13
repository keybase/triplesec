
hmax = require '../src/hmax'
{WordArray} = require '../src/wordarray'

key = WordArray.from_utf8 'this be the top secret key! shit yeah! sdf3 234 092i34 092i34 0923i'
input = WordArray.from_utf8 'this be the message dawg'
res = hmax.sign { key, input }
console.log res
