
{CryptoJS} = require 'cryptojs-2fish'
{TwoFish} = require '../lib/twofish'

P = (x) -> CryptoJS.enc.Hex.parse x

msg = P "00000000000000000000000000000000"
key = P "00000000000000000000000000000000"

tf = CryptoJS.algo.TwoFish.create 0, key, {}
console.log msg
tf.encryptBlock msg.words, 0
console.log msg
console.log msg.toString()
tf.decryptBlock msg.words, 0
console.log msg

tf2 = new TwoFish key
tf2.encryptBlock msg.words, 0
console.log msg
console.log msg.toString()
tf.decryptBlock msg.words, 0
console.log msg
