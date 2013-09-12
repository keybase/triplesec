{Encryptor} = require '../lib/enc'
{Decryptor} = require '../lib/dec'
{rng} = require '../lib/rng'

key = new Buffer "this be the password"
data = new Buffer ("tihs be the secret message" for i in [0..100]).join ' + '

enc = new Encryptor { key, rng }
dec = new Decryptor { key }
for i in [0...100]
  await enc.run data, defer err, ct
  console.log ct.toString 'hex'
  await dec.run ct, defer err, pt
  console.log pt.toString()
