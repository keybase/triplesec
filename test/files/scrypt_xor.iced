
{scrypt} = require '../../lib/scrypt'
{WordArray} = require '../../lib/wordarray'
spec = require '../data/scrypt_xor_spec'
{XOR} = require '../../lib/combine'

exports.test_spec = (T,cb) ->
  for v,i in spec.data
    v.key = WordArray.from_hex v.key
    v.salt = WordArray.from_hex v.salt
    v.klass = XOR
    await scrypt v, defer out
    T.equal out.to_hex(), v.dk, "Spec vector #{i}"
    T.waypoint "spec vector #{i}"
  cb()

