
data = {}

data.short = require('../data/sha512_short').data
{SHA512} = require '../../lib/sha512'
{WordArray} = require '../../lib/wordarray'

do_test_vec = (T, which) ->
  vec = data[which]
  for {msg,md}, i in vec
    input = WordArray.from_hex msg
    output = (new SHA512).update(input).finalize().to_hex()
    T.equal md, output, "SHA512 #{which} test #{i}"

exports.short = (T,cb) ->
  do_test_vec T, 'short'
  cb()
