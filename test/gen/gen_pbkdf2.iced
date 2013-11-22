
{CryptoJS} = require 'cryptojs-1sp'

opts = 
  hasher : CryptoJS.algo.SHA512
  iterations : 64
  keySize : (512*3)/32

inputs = [
  {
    password : "cats11"
    salt : "aabbccddeeff"
  },{
    password : "yo ho ho and a bottle of rum"
    salt : "1234abcd9876"
  },{
    password : "let me in!"
    salt : "0123456789"
  },{
    password : "password PASSWORD password PASSWORD"
    salt : "73616c7453414c5473616c7453414c5473616c7453414c54"
  }
]  

data = []

for {password,salt} in inputs
  password = CryptoJS.enc.Utf8.parse password
  salt = CryptoJS.enc.Hex.parse salt
  output = CryptoJS.PBKDF2 password, salt, opts
  d = { password, salt, output }
  for k,v of d
    d[k] = v.toString CryptoJS.enc.Hex
  data.push d

export_opts = 
  c : opts.iterations
  dkLen : opts.keySize * 4

console.log "exports.data = #{JSON.stringify data, null, 4};"
console.log "exports.opts = #{JSON.stringify export_opts, null, 4};"
