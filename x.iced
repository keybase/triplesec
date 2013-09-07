crypto        = require 'crypto'
{encrypt} = require './src/enc'
{decrypt} = require './src/dec'

arg = 
  key : new Buffer 'this be the password'
  salt : new Buffer 'max@okcupid.com'
  data : new Buffer 'this be the secret message!'
  rng : crypto.rng

ct = encrypt(arg)
console.log ct.toString 'hex'
arg.data = ct
pt = decrypt(arg)
console.log pt.toString 'hex'

{ words: 
   [ 479516638,
     1,
     2652852425,
     3111152706,
     846623373,
     2319973766,
     1178622632,
     835068810,
     -1165576059,
     1156147574,
     34703652,
     867553693,
     1376595221,
     1267995245,
     -854387479,
     -2091573799,
     1265912992,
     1635200001,
     1405741241,
     -1473154141,
     -1226745947,
     -518245623,
     -2085587496 ],
  sigBytes: 91 }


  { words: 
     [ 479516638,
       1,
       2652852425,
       3111152706,
       846623373,
       2319973766,
       1178622632,
       835068810,
       3129391237,
       1156147574,
       34703652,
       867553693,
       1376595221,
       1267995245,
       3440579817,
       2203393497,
       1265912992,
       1635200001,
       1405741241,
       2821813155,
       3068221349,
       3776721673,
       -2085587712 ],
    sigBytes: 91 }