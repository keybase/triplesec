
{AES} = require '../../lib/aes'
{WordArray} = require '../../lib/wordarray'

test_vectors = [
  {
    desc : "fips-197 C.3"
    plaintext : "00112233445566778899aabbccddeeff"
    key : "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
    ciphertext : "8ea2b7ca516745bfeafc49904b496089"
  },
  {
    desc : "NIST 800-38a F.5.5 CTR-AES256.Encrypt Block #1"
    plaintext : "f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff"
    key : "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"
    ciphertext : "0bdf7df1591716335e9a8b15c860c502"
  },
  { 
    desc : "NIST 800-38a F.5.5 CTR-AES256.Encrypt Block #2"
    plaintext : "f0f1f2f3f4f5f6f7f8f9fafbfcfdff00"
    key : "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"
    ciphertext : "5a6e699d536119065433863c8f657b94"
  },
  { 
    desc : "NIST 800-38a F.5.5 CTR-AES256.Encrypt Block #3"
    plaintext : "f0f1f2f3f4f5f6f7f8f9fafbfcfdff01"
    key : "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"
    ciphertext : "1bc12c9c01610d5d0d8bd6a3378eca62"
  },
  { 
    desc : "NIST 800-38a F.5.5 CTR-AES256.Encrypt Block #4"
    plaintext : "f0f1f2f3f4f5f6f7f8f9fafbfcfdff02"
    key : "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"
    ciphertext : "2956e1c8693536b1bee99c73a31576b6"
  }
]

test_single = (T, v) ->
  aes = new AES WordArray.from_hex v.key
  block = WordArray.from_hex v.plaintext
  aes.encryptBlock block.words
  ctext_hex = block.to_hex()
  T.equal ctext_hex, v.ciphertext, "#{v.desc} -- correct encryption"
  aes.decryptBlock block.words
  ptext_hex = block.to_hex()
  T.equal ptext_hex, v.plaintext, "#{v.desc} -- correct decryption"

exports.test_aes = (T, cb) ->
  for v in test_vectors
    test_single T, v
  cb()
  