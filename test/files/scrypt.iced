
{Scrypt} = require '../../src/scrypt'

#====================================================================


exports.test_salsa20 = (T,cb) ->

  # From http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-00; Section 7
  input = """7e879a21 4f3ec986 7ca940e6 41718f26
   baee555b 8c61c1b5 0df84611 6dcd3b1d
   ee24f319 df9b3d85 14121e4b 5ac5aa32
   76021d29 09c74829 edebc68d b8b8c25e""".split(/\s+/).join("")
  output = """a41f859c 6608cc99 3b81cacb 020cef05
   044b2181 a2fd337d fd7b1c63 96682f29
   b4393168 e3c9e6bc fe6bc5b7 a06d96ba
   e424cc10 2c91745c 24ad673d c7618f81""".split(/\s+/).join("")
  input = new Uint8Array(new Buffer input, 'hex')
  scrypt = new Scrypt {}
  scrypt.salsa20_8(input)
  buf = new Buffer input
  T.equal buf.toString('hex'), output, "salsa20 subroutine works"
  cb()
