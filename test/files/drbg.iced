data =
  no_reseed : require('../data/drbg_hmac_no_reseed').data

{DRBG} = require '../../lib/drbg'
{WordArray} = require '../../lib/wordarray'

test_case = (T, which, i, test) ->
  entropy = WordArray.from_hex test.EntropyInput
  nonce = WordArray.from_hex test.Nonce
  personalization_string = WordArray.from_hex test.PersonalizationString
  returned_bits = test.ReturnedBits
  g = new DRBG entropy.concat(nonce), personalization_string
  out = g.generate(returned_bits.length/2).to_hex()
  T.equal out, returned_bits, "test vector #{which}/#{i}"

exports.first_case = (T,cb) ->
  test_case T, 'no_reseed', 0, data.no_reseed[1]
  cb()
