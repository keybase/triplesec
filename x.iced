crypto        = require 'crypto'
{encrypt} = require './src/enc'
{decrypt} = require './src/dec'

arg = 
  key : new Buffer 'this be the password'
  salt : new Buffer 'max@okcupid.com'
  data : new Buffer 'this be the secret message! dibbly dibble doo doo shit bag bing' + "this be the secret message! dibbly dibble doo doo shit bag bing" + "this be the secret message! dibbly dibble doo doo shit bag bing"
  rng : crypto.rng

ct = encrypt(arg)
console.log ct.toString 'hex'
console.log ct.length
arg.data = ct
pt = decrypt(arg)
console.log pt.toString 'hex'
console.log pt.toString()
