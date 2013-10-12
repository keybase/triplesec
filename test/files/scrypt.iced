
{Scrypt} = require '../../src/scrypt'


#====================================================================

strip = (x) -> x.split(/\s+/).join("")
hex_to_ui8a = (x) -> new Uint8Array(new Buffer (strip(x)), 'hex')
ui8a_to_hex = (v) -> (new Buffer v).toString 'hex'

#====================================================================

exports.test_salsa20 = (T,cb) ->

  # From http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-00; Section 7
  input = strip """7e879a21 4f3ec986 7ca940e6 41718f26
   baee555b 8c61c1b5 0df84611 6dcd3b1d
   ee24f319 df9b3d85 14121e4b 5ac5aa32
   76021d29 09c74829 edebc68d b8b8c25e"""
  output = strip """a41f859c 6608cc99 3b81cacb 020cef05
   044b2181 a2fd337d fd7b1c63 96682f29
   b4393168 e3c9e6bc fe6bc5b7 a06d96ba
   e424cc10 2c91745c 24ad673d c7618f81"""
  input = new Uint8Array(new Buffer input, 'hex')
  scrypt = new Scrypt {}
  scrypt.salsa20_8(input)
  buf = new Buffer input
  T.equal buf.toString('hex'), output, "salsa20 subroutine works"
  cb()

#====================================================================

exports.test_blockmix = (T,cb) ->

  # From http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-00; Section 8
  input = hex_to_ui8a """f7 ce 0b 65 3d 2d 72 a4 10 8c f5 ab e9 12 ff dd
           77 76 16 db bb 27 a7 0e 82 04 f3 ae 2d 0f 6f ad
           89 f6 8f 48 11 d1 e8 7b cc 3b d7 40 0a 9f fd 29
           09 4f 01 84 63 95 74 f3 9a e5 a1 31 52 17 bc d7

           89 49 91 44 72 13 bb 22 6c 25 b5 4d a8 63 70 fb
           cd 98 43 80 37 46 66 bb 8f fc b5 bf 40 c2 54 b0
           67 d2 7c 51 ce 4a d5 fe d8 29 c9 0b 50 5a 57 1b
           7f 4d 1c ad 6a 52 3c da 77 0e 67 bc ea af 7e 89"""

  output = strip """a4 1f 85 9c 66 08 cc 99 3b 81 ca cb 02 0c ef 05
           04 4b 21 81 a2 fd 33 7d fd 7b 1c 63 96 68 2f 29
           b4 39 31 68 e3 c9 e6 bc fe 6b c5 b7 a0 6d 96 ba
           e4 24 cc 10 2c 91 74 5c 24 ad 67 3d c7 61 8f 81

           20 ed c9 75 32 38 81 a8 05 40 f6 4c 16 2d cd 3c
           21 07 7c fe 5f 8d 5f e2 b1 a4 16 8f 95 36 78 b7
           7d 3b 3d 80 3b 60 e4 ab 92 09 96 e5 9b 4d 53 b6
           5d 2a 22 58 77 d5 ed f5 84 2c b9 f1 4e ef e4 25"""

  scrypt = new Scrypt { r : 1, p : 1, N : 1}
  Y = new Uint8Array(128*scrypt.r)
  scrypt.blockmix_salsa8 input, Y
  T.equal ui8a_to_hex(input), output, "blockmix worked as advertised"
  cb()

