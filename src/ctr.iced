
{WordArray} = require './wordarray'

#=========================================

exports.Counter = class Counter

  WORD_MAX : 0xffffffff

  #---------------------------

  constructor : ({ value, len }) ->
    @_value = if value? then value
    else
      len = 2 unless len?
      new WordArray (0 for i in[0...len]), len*4

  #---------------------------

  inc : () ->
    go = true
    i = @_value.words.length - 1
    while go and i >= 0
      if ((++@_value.words[i]) > Counter.WORD_MAX) then @_value.words[i] = 0
      else go = false
      i--
    true

  #---------------------------

  get : () -> @_value
  
#=========================================

