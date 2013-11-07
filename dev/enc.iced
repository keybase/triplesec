{Encryptor} = require '../lib/enc'
{Decryptor} = require '../lib/dec'

key = new Buffer "this be the password"
data = new Buffer ("this be the secret message" for i in [0..5]).join " -> "

enc = new Encryptor { key, version : 3 }
dec = new Decryptor { key }
await enc.run { data : new Buffer data }, defer err, ct
console.log key.toString('hex')
console.log ct.toString('hex')
process.exit(0)
