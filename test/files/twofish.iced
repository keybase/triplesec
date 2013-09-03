
data = {}

data.ecb_ival = require('../data/twofish_ecb_ival').data

{TwoFish} = require '../../lib/twofish'
{WordArray} = require '../../lib/wordarray'

do_test_vec = (T, which) ->
  vec = data[which]
  for d,i in vec
    (d[k] = v.toLowerCase() for k,v of d)
    key_wa = WordArray.from_hex d.key
    block = WordArray.from_hex d.plaintext
    tf = new TwoFish key_wa
    tf.encryptBlock block.words
    ctext_hex = block.to_hex()
    T.equal ctext_hex, d.ciphertext, "Test vector #{i} enc: #{JSON.stringify d}"
    tf.decryptBlock block.words
    ptext_hex = block.to_hex()
    T.equal ptext_hex, d.plaintext, "Test vector #{i} dec: #{JSON.stringify d}"

exports.ecb_ival = (T, cb) ->
  do_test_vec T, 'ecb_ival'
  cb()