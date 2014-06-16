{WordArray} = require '../../lib/wordarray'
{data} = require '../fixed-data/ripemd160.iced'
{RIPEMD160} = require '../../lib/ripemd160'

exports.test = (T,cb) ->
  for {input,output},i in data
    hash = new RIPEMD160
    iwa = WordArray.from_utf8 input
    hash.update iwa
    actual = hash.finalize().to_hex()
    T.equal actual, output, "test vector #{i} worked"
    T.waypoint "vector #{i}"
  cb()
