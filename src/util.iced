
uint_max = Math.pow(2,32)

exports.fixup_uint32 = (x) ->
  ret = if x > uint_max then x % uint_max
  else if x < 0 then (uint_max + x)
  else x
  ret
