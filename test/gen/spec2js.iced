
spec = require process.argv[2]

console.log "exports.data = #{JSON.stringify spec.vectors, null, 4};"