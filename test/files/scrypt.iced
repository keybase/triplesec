
{Scrypt} = require '../../src/scrypt'


#====================================================================

strip = (x) -> x.split(/\s+/).join("")
hex_to_ui8a = (x) -> new Uint8Array(new Buffer (strip(x)), 'hex')
ui8a_to_hex = (v) -> (new Buffer v).toString 'hex'

#====================================================================

exports.test_salsa20 = (T,cb) ->

  # From http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-01; Section 7
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

  # From http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-01; Section 8
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

#====================================================================

exports.test_smix = (T,cb) ->

  # From http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-01; Section 9
  input = hex_to_ui8a """
       f7 ce 0b 65 3d 2d 72 a4 10 8c f5 ab e9 12 ff dd
       77 76 16 db bb 27 a7 0e 82 04 f3 ae 2d 0f 6f ad
       89 f6 8f 48 11 d1 e8 7b cc 3b d7 40 0a 9f fd 29
       09 4f 01 84 63 95 74 f3 9a e5 a1 31 52 17 bc d7
       89 49 91 44 72 13 bb 22 6c 25 b5 4d a8 63 70 fb
       cd 98 43 80 37 46 66 bb 8f fc b5 bf 40 c2 54 b0
       67 d2 7c 51 ce 4a d5 fe d8 29 c9 0b 50 5a 57 1b
       7f 4d 1c ad 6a 52 3c da 77 0e 67 bc ea af 7e 89"""
  output = strip """
       79 cc c1 93 62 9d eb ca 04 7f 0b 70 60 4b f6 b6
       2c e3 dd 4a 96 26 e3 55 fa fc 61 98 e6 ea 2b 46
       d5 84 13 67 3b 99 b0 29 d6 65 c3 57 60 1f b4 26
       a0 b2 f4 bb a2 00 ee 9f 0a 43 d1 9b 57 1a 9c 71
       ef 11 42 e6 5d 5a 26 6f dd ca 83 2c e5 9f aa 7c
       ac 0b 9c f1 be 2b ff ca 30 0d 01 ee 38 76 19 c4
       ae 12 fd 44 38 f2 03 a0 e4 e1 c4 7e c3 14 86 1f
       4e 90 87 cb 33 39 6a 68 73 e8 f9 d2 53 9a 4b 8e"""
  scrypt = new Scrypt { r : 1, p : 1, N : 16 }
  XY = new Uint8Array(256*scrypt.r)
  V = new Uint8Array(128*scrypt.r*scrypt.N)
  scrypt.smix { B : input, V, XY }
  T.equal ui8a_to_hex(input), output, "smix worked as advertised"
  cb()

#====================================================================

exports.test_pbkdf2 = (T, cb) ->
  # From http://tools.ietf.org/html/draft-josefsson-scrypt-kdf-01; Section 10
  arg = 
    key : (new Buffer "passwd")
    salt : (new Buffer "salt")
    c : 1
    dkLen : 64
  output = strip """
       55 ac 04 6e 56 e3 08 9f ec 16 91 c2 25 44 b6 05
       f9 41 85 21 6d de 04 65 e6 8b 9d 57 c2 0d ac bc
       49 ca 9c cc f1 79 b6 45 99 16 64 b3 9d 77 ef 31
       7c 71 b8 45 b1 e3 0b d5 09 11 20 41 d3 a1 97 83
      """
  scrypt = new Scrypt {}
  await scrypt.pbkdf2 arg, defer buf
  T.equal buf.toString('hex'), output, "pbkdf2 test vector"
  cb()

#====================================================================

exports.test_scrypt = (T,cb) ->
  test_vectors = [
    {
      key : new Buffer([])
      salt : new Buffer([])
      params : { N : 16, r: 1, p : 1 }
      dkLen : 64
      output : strip """
         77 d6 57 62 38 65 7b 20 3b 19 ca 42 c1 8a 04 97
         f1 6b 48 44 e3 07 4a e8 df df fa 3f ed e2 14 42
         fc d0 06 9d ed 09 48 f8 32 6a 75 3a 0f c8 1f 17
         e8 d3 e0 fb 2e 0d 36 28 cf 35 e2 0c 38 d1 89 06"""
    },{
      key : new Buffer("pleaseletmein"), 
      salt : new Buffer("SodiumChloride"),
      dkLen : 64,
      params : { N : 16384, r : 8, p : 1 },
      output : strip """
         70 23 bd cb 3a fd 73 48 46 1c 06 cd 81 fd 38 eb
         fd a8 fb ba 90 4f 8e 3e a9 b5 43 f6 54 5d a1 f2
         d5 43 29 55 61 3f 0f cf 62 d4 97 05 24 2a 9a f9
         e6 1e 85 dc 0d 65 1e 40 df cf 01 7b 45 57 58 87"""
    },
    {
      key : new Buffer("password"), 
      salt : new Buffer("NaCl"),
      params : { N:1024, r:8, p:16}, 
      dkLen : 64
      output : strip """
         fd ba be 1c 9d 34 72 00 78 56 e7 19 0d 01 e9 fe
         7c 6a d7 cb c8 23 78 30 e7 73 76 63 4b 37 31 62
         2e af 30 d9 2e 22 a3 88 6f f1 09 27 9d 98 30 da
         c7 27 af b9 4a 83 ee 6d 83 60 cb df a2 cc 06 40"""
    }
  ]
  progress_hook = (obj) ->
    if obj.what is 'scrypt'
      T.waypoint "scrypt: #{obj.i} / #{obj.total}"
  for v,i in test_vectors
    v.progress_hook = progress_hook
    scrypt = new Scrypt v.params
    await scrypt.run v, defer buf
    T.equal buf.toString('hex'), v.output, "test vector #{i}"
    T.waypoint "test vector #{i}"
  cb()
