
{AES} = require '../../lib/aes'
{WordArray} = require '../../lib/wordarray'

test_vectors = [
  {
    desc : "fips-197 C.3"
    plaintext : "00112233445566778899aabbccddeeff"
    key : "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"
    ciphertext : "8ea2b7ca516745bfeafc49904b496089"
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
  