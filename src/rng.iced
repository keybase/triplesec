
#===============================================

browser_rng = (n) ->
  v = new Uint8Array n
  window.crypto.getRandomValues v
  new Buffer v

#===============================================

if window?.crypto?.getRandomValues?
  exports.rng = browser_rng
else
  try
    {rng} = require('crypto')
    exports.rng = rng if rng?
  catch e
    # pass

if not exports.rng?
    throw new Error 'No rng found; tried requiring "crypto" and window.crypto'

#===============================================
