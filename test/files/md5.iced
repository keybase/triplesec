{WordArray} = require '../../lib/wordarray'
{MD5} = require '../../lib/md5'
vectors = require('../json/md5.json')

exports.run = (T,cb) ->
  for row, i in vectors
    hasher = new MD5()
    input = WordArray.from_hex row.data
    hasher.update input
    output = hasher.finalize().to_hex()
    T.equal output, row.digest, "test vector MD5/#{i}"
  cb()
