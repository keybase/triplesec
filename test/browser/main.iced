
mods =  
  sha512 : require '../files/sha512.iced'
  wordarray : require '../files/wordarray.iced'
  hmac : require '../files/hmac.iced'
  aes : require '../files/aes.iced'

{BrowserRunner} = require('iced-test')

window.onload = () ->
  br = new BrowserRunner { log : "log", rc : "rc" }
  await br.run mods, defer rc
