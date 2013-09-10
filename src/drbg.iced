
{HMAC} = require './hmac'


# Implements an HMAC_DRBG (NIST SP 800-90A) based on HMAC_SHA512
# Supports security strengths up to 256 bits.
# Parameters are based on recommendations provided by Appendix D of NIST SP 800-90A.
exports.HMAC_DRBG = class HMAC_DRBG

	constructor : (entropy, personalization_string) ->
		# Only run at the most secure strength
		@security_strength = 256

		if (entropy.length * 8 * 2) < (3 * @security_strength):
			throw new Error "entropy must be at least %f bits." % (1.5 * @security_strength)

		if entropy.length * 8 > 1000:
			throw new Error "entropy cannot exceed 1000 bits"

		@_instantiate entropy, personalization_string
	

	# Just for convenience and succinctness
	def _hmac (self, key, data):
		return hmac.new (key, data, hashlib.sha256).digest ()
	

	def _update (self, provided_data=None):
		self.K = self._hmac (self.K, self.V + "\x00" + ("" if provided_data is None else provided_data))
		self.V = self._hmac (self.K, self.V)

		if provided_data is not None:
			self.K = self._hmac (self.K, self.V + "\x01" + provided_data)
			self.V = self._hmac (self.K, self.V)
	

	_instantiate : (self, entropy, personalization_string) ->
		seed_material = entropy + personalization_string
		n = 32
		@K = WordArray.from_buffer new Buffer (0 for i in [0...n])
		@V = WordArray.from_buffer new Buffer (1 for i in [0...n])
		@_update seed_material
		@reseed_counter = 1
	
	
	def reseed (self, entropy):
		if (len (entropy) * 8) < self.security_strength:
			raise RuntimeError, "entropy must be at least %f bits." % (self.security_strength)

		if len (entropy) * 8 > 1000:
			raise RuntimeError, "entropy cannot exceed 1000 bits."

		self._update (entropy)
		self.reseed_counter = 1
	

	def generate (self, num_bytes, requested_security_strength=256):
		if (num_bytes * 8) > 7500:
			raise RuntimeError, "generate cannot generate more than 7500 bits in a single call."

		if requested_security_strength > self.security_strength:
			raise RuntimeError, "requested_security_strength exceeds this instance's security_strength (%d)" % self.security_strength

		if self.reseed_counter >= 10000:
			return None

		temp = ""

		while len (temp) < num_bytes:
			self.V = self._hmac (self.K, self.V)
			temp += self.V

		self._update (None)
		self.reseed_counter += 1

		return temp[:num_bytes]
