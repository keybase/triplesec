{Decryptor} = require '../lib/dec'

key = new Buffer process.argv[2], 'hex'
data = new Buffer process.argv[3], 'hex'

dec = new Decryptor { key }
await dec.run { data }, defer err, pt
if err? then console.error err
else console.log pt.toString('utf8')
