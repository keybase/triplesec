#  = "========================"
# "
# From here: http://www.schneier.com/code/twofish-kat.zip"
# FILENAME:  "ecb_e_m.txt""
# "
# Electronic Codebook (ECB) Mode - ENCRYPTION"
# Monte Carlo Test"
# "
# Algorithm Name:       TWOFISH"
# Principal Submitter:  Bruce Schneier, Counterpane Systems"
# "
#  = "========="

out = []
f = () ->
  out.push { key : KEY, plaintext : PT, ciphertext : CT } 

KEY = "00000000000000000000000000000000"
PT = "00000000000000000000000000000000"
CT = "282BE7E4FA1FBDC29661286F1F310B7E"
f()
KEY = "282BE7E4FA1FBDC29661286F1F310B7E"
PT = "282BE7E4FA1FBDC29661286F1F310B7E"
CT = "C8E1D477621ACC37742BD16032075654"
f()
