{Encryptor} = require '../lib/enc'
{Decryptor} = require '../lib/dec'

argv = require('optimist').alias('e', 'extra_bytes')
   .usage("usage: $0 -e <extra bytes> [<key-in-hex>] [<data-in-hex>] ").argv

key = if argv._.length > 0 then (new Buffer argv._[0], 'hex') 
else (new Buffer "this be the password")

data = if argv._.length > 1 then (new Buffer argv._[1], 'hex')
else (new Buffer ("this be the secret message" for i in [0..5]).join " -> ")

enc = new Encryptor { key, version : 3 }
if argv.e?
  await enc.resalt { extra_keymaterial : argv.e }, defer err, keys
  console.log "extra: #{keys.extra.toString('hex')}"
await enc.run { data : new Buffer data }, defer err, ct
console.log "key: #{key.toString('hex')}"
console.log "ciphertext: #{ct.toString('hex')}"
process.exit(0)
