
{CryptoJS} = require 'cryptojs-2fish'

msg = "cc"
wordArray = CryptoJS.enc.Hex.parse msg
x = CryptoJS.SHA3(wordArray)
console.log x
console.log x.toString()
