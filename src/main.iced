exports[k]      = v for k,v of require './enc'
exports[k]      = v for k,v of require './dec'
exports.rng     = require('./rng').rng
exports.Buffer  = Buffer