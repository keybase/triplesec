

#
# Encrypt the given data with the given key
#
#  @param {Buffer} key - A buffer with the keystream data in it
#  @param {Buffer} data - The data to encrypt
#
#  @returns {Buffer} a buffer with the encrypted data
#
exports.encrypt = ({ key, data}) ->