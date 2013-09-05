
{WordArray} = require '../../lib/wordarray'
{AES} = require '../../lib/aes'
ctr = require '../../lib/ctr'

test_vec__nist_sp_800_38a__f_5_5 = 


# See http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
#  Section F5.5
exports.sp_nist_800_38a__f_5_5 = (T, cb) ->
  tv =
    key : [ '603deb1015ca71be2b73aef0857d7781'
            '1f352c073b6108d72d9810a30914dff4' ].join('')
    iv  :   'f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff'
    pt  : [ "6bc1bee22e409f96e93d7e117393172a",
            "ae2d8a571e03ac9c9eb76fac45af8e51",
            "30c81c46a35ce411e5fbc1191a0a52ef",
            "f69f2445df4f9b17ad2b417be66c3710" ].join('')
    ct  : [ "601ec313775789a5b7a7f504bbf3d228"
            "f443e3ca4d62b59aca84e990cacaf5c5"
            "2b0930daa23de94ce87017ba2d84988d"
            "dfc9c58db67aada613c2dd08457941a6" ].join("") 

  E = (input) -> ctr.encrypt {
    block_cipher : new AES(WordArray.from_hex tv.key)
    iv : WordArray.from_hex tv.iv
    input : input
  }
  out = E WordArray.from_hex tv.pt
  T.equal out.to_hex(), tv.ct, "Cipher text match"
  out = E out
  T.equal out.to_hex(), tv.pt, "Plaintext decryption match"
  cb()
