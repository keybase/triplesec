
hmac = require './hmac'

#====================================================================

# Implements an HMAC_DRBG (NIST SP 800-90A) based on HMAC_SHA512
# Supports security strengths up to 256 bits.
# Parameters are based on recommendations provided by Appendix D of NIST SP 800-90A.
exports.HMAC_DRBG = class HMAC_DRBG

	check_entropy : (entropy) ->
		if (entropy.sigBytes * 8 * 2) < (3 * @security_strength)
			throw new Error "entropy must be at least %f bits." % (1.5 * @security_strength)
		else if entropy.SigBytes * 8 > 1000
			new WordArray entropy.words[0...31]

	constructor : (entropy, personalization_string) ->
		# Only run at the most secure strength
		@security_strength = 256
		entropy = @check_entropy entropy
		@_instantiate entropy, personalization_string

	# Just for convenience and succinctness
	_hmac : (key, input) -> hmac.sign { key, input }

	_update : (provided_data) ->
		V = new WordArray [0], 1
		V = V.concat provided_data if provided_data?
		@K = @_hmac @K, @V.concat V
		@V = @_hmac @K, @V

		if provided_data?
			@K = @_hmac @K, @V.concat(new WordArray [1], 1).concat(provided_data)
			@V = @_hmac @K, @V

	_instantiate : (entropy, personalization_string) ->
		seed_material = entropy.concat personalization_string
		n = 32
		@K = WordArray.from_buffer new Buffer (0 for i in [0...n])
		@V = WordArray.from_buffer new Buffer (1 for i in [0...n])
		@_update seed_material
		@reseed_counter = 1
	
	reseed : (entropy) ->
		entropy = @check_entropy entropy
		@_update entropy
		@reseed_counter = 1
	

	generate : (num_bytes) ->
		if (num_bytes * 8) > 7500
			throw new Error "generate cannot generate more than 7500 bits in a single call."

		if @reseed_counter >= 10000
			throw new Error "Need a reseed!"

		temp = []

		while temp.length*4 < num_bytes:
			@V = @_hmac @K, @V
			temp.push @V.words

		@_update()
		@reseed_counter += 1

		return temp[:num_bytes]
