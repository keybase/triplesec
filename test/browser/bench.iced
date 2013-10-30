
{Scrypt} = require '../../lib/scrypt'
{WordArray} = require '../../lib/wordarray'

mkbuf = (s) -> WordArray.from_utf8(if s?.length then s else '')

vectors = [
  { 
    N : 16,
    r : 8,
    p : 1,
    c : 1,
    d : 64,
    k : "hello",
    s : "salt"
  }]

bench_vector = (v, cb) ->
  scrypt = new Scrypt { N : v.N, p : v.p, r : v.r , c : v.c }
  start = Date.now()
  await scrypt.run { key : mkbuf(v.key), salt : mkbuf(v.salt), dkLen : v.d }, defer wa
  stop = Date.now()
  time = stop - start
  cb "#{JSON.stringify(v)} -> #{time}s"


main = (fn) ->
  for v in vectors
    await bench_vector v, defer time
    fn time

exports.main = main