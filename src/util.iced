
uint_max = Math.pow(2,32)

exports.fixup_uint32 = (x) ->
  ret = if x > uint_max or x < 0
    x_pos = (Math.abs(x) % uint_max)
    if x < 0 then uint_max - x_pos
    else x_pos
  else x
  ret

exports.scrub_buffer = (b) ->
  for i in [0...b.length]
    b.writeUInt8 0, i