{WordArray} = require './wordarray'
{Hasher} = require './algbase'
{KECCAK} = require './keccak'

#================================================================

class SHA3STD extends KECCAK
  pad : 0x06

#================================================================

transform = (x) ->
  out = (new SHA3STD).finalize x
  x.scrub()
  out

#================================================================

exports.SHA3STD = SHA3STD
exports.transform = transform

#================================================================

