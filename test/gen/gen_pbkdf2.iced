
{CryptoJS} = require 'cryptojs-2fish'

opts = 
  hasher : CryptoJS.algo.SHA512
  iterations : 16
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
    salt : "012345678"
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

console.log "exports.data = #{JSON.stringify data, null, 4};"