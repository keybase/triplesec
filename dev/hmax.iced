
{HMAX} = require '../src/hmax'
{WordArray} = require '../src/wordarray'
{SHA512} = require '../src/sha512'
{HMAC} = require '../src/hmac'

#--------

class NullHash 
  constructor : ->
  @output_size : SHA512.output_size
  output_size : NullHash.output_size
  @blockSize : SHA512.blockSize
  blockSize : NullHash.blockSize
  update : ->
  finalize : -> new WordArray [], 0
  reset : -> @

#--------

key = WordArray.from_utf8 'this be the top secret key! shit yeah! sdf3 234 092i34 092i34 0923i'
input = WordArray.from_utf8 'this be the message dawg'
hmax = new HMAX key,  [ SHA512, NullHash ], { skip_compose : 0 }
hmax2 = new HMAX key,  [ NullHash, SHA512 ], { skip_compose : 1 }
hmac = new HMAC key, SHA512
hmax.finalize(input)
hmax2.finalize(input)
hmac.finalize(input)
