data =
  no_reseed : require('../data/drbg_hmac_no_reseed').data
  reseed : require('../data/drbg_hmac_reseed').data

{DRBG} = require '../../lib/drbg'
{WordArray} = require '../../lib/wordarray'

test_case = (T, which, i, test) ->
  entropy = WordArray.from_hex test.EntropyInput
  nonce = WordArray.from_hex test.Nonce
  personalization_string = WordArray.from_hex test.PersonalizationString
  returned_bits = test.ReturnedBits
  g = new DRBG entropy.concat(nonce), personalization_string
  if (eirs = test.EntropyInputReseed)? 
    g.reseed WordArray.from_hex eirs
  for j in [0...2]
    out = g.generate(returned_bits.length/2).to_hex()
  T.equal out, returned_bits, "test vector #{which}/#{i}"

exports.no_reseed = (T,cb) ->
  test_cases T, 'no_reseed'
  cb()

exports.reseed = (T,cb) ->
  test_cases T, 'reseed'
  cb()

test_cases = (T, which) ->
  for v,i in data[which]
    test_case T, which, i, v
