
{generate} = require '../src/prng'

await generate 10, defer x
console.log x
process.exit 0