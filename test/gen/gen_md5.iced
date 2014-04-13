
{prng,createHash} = require 'crypto'

out = []

n = 1
for i in [0...14]
  dat = prng n
  h = createHash('MD5').update(dat).digest('hex')
  out.push { data : dat.toString('hex'), digest : h }
  n = n <<  1
  
console.log JSON.stringify out
