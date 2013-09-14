{Encryptor} = require '../lib/enc'
{Decryptor} = require '../lib/dec'

key = new Buffer "this be the password"
data = new Buffer ("this be the secret message" for i in [0..500]).join " -> "

enc = new Encryptor { key }
dec = new Decryptor { key }
for i in [0...100]
  await enc.run { data : new Buffer data }, defer err, ct
  await dec.run { data : ct }, defer err, pt
  console.log pt.toString()
