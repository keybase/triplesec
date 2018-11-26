keccaklib = require './keccak'

# SHA3 is not the standardized SHA3 function, but the Keccak variant initially
# proposed. This alias is kept for backwards-compatibility purposes.
# Use SHA3STD in src/sha3std.iced for the standardized SHA3-512 function.
exports.SHA3 = keccaklib.KECCAK
exports.transform = keccaklib.transform

#================================================================

