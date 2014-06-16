{WordArray} = require '../../lib/wordarray'
{data} = require '../data/ripemd160'
{RIPEMD160} = require '../../lib/ripemd160'

exports.test = (T,cb) ->
  for {input,output},i in data
    hash = new RIPEMD160
    console.log "fuuuck #{i}"
    console.log input
    iwa = WordArray.from_utf8 input
    console.log iwa
    console.log hash
    hash.update iwa
    console.log hash
    actual = hash.finalize().to_hex()
    T.equal actual, output, "test vector #{i} worked"
    T.waypoint "vector #{i}"
  cb()
