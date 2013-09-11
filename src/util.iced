
uint_max = Math.pow(2,32)

#----------------------------------------------

exports.fixup_uint32 = (x) ->
  ret = if x > uint_max or x < 0
    x_pos = (Math.abs(x) % uint_max)
    if x < 0 then uint_max - x_pos
    else x_pos
  else x
  ret

#----------------------------------------------

exports.scrub_buffer = (b) ->
  for i in [0...b.length]
    b.writeUInt8 0, i

#----------------------------------------------

exports.scrub_vec = (v) ->
  for i in [0...v.length]
    v[i] = 0

#----------------------------------------------

exports.default_delay = default_delay = (i, n, cb) ->
  setTimeout cb, 2

#----------------------------------------------

# Perform a bulk crypto operation, inserting delay slots as
# needs be.
#
# @param {number} n_input_bytes The number of bytes in the input
# @param {Function} update Function to call to update internal state. Call with a lo
#    and high position **in words**, for which window of the input to operate on.
# @param {Function} finalize Function to call to finalize computation 
#    and yield a result.
# @param {number} default_n The default number of words per batch to operate
#    on if none is given explicitly as n
# @param {number} n The number of words per batch
# @param {Function} delay The function to call in each delay slot
# @param {Callback} cb The callback to call upon completion, with
#    a result (and no error, since no errors can be generated in a correct
#    implementation).
exports.bulk = (n_input_bytes, {update, finalize, default_n}, {delay, n, cb}) ->
  i = 0
  left = 0
  total_words = n_input_bytes / 4
  delay or= default_delay
  n or= default_n
  while (left = (total_words - i)) > 0
    n_words = Math.min n, left
    update i, i + n_words
    await delay i, total_words, defer()
    i += n_words
  ret = finalize()
  cb ret



