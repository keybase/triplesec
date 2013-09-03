#
# Copied from:
# 
#   https://gist.github.com/dchest/4582374
#   

{WordArray} = require './wordarray'

class Salsa20

  constructor : (@key, @nonce) ->
    # Constants.
    @rounds = 20   # number of Salsa rounds
    @sigmaWords = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]
    @_reset()


  _reset : () ->
    @counter = new WordArray([0,0], 2) 
    # Output buffer.
    @block = []        #output block of 64 bytes
    @blockUsed = 64    #number of block bytes used

  # getBytes returns the next numberOfBytes bytes of stream.
  getBytes : (numberOfBytes) ->
    out = new Buffer numberOfBytes
    for i in [0...numberOfBytes]
      if @blockUsed is 64
        @_generateBlock()
        @_incrementCounter()
        @blockUsed = 0
      out.writeUInt8 @block[@blockUsed++], i
    out

  _incrementCounter : () ->
    # Note: maximum 2^64 blocks.
    @counterWords[0] = (@counterWords[0] + 1) & 0xffffffff
    if @counterWords[0] = 
    if (this.counterWords[0] == 0) {
      this.counterWords[1] = (this.counterWords[1] + 1) & 0xffffffff;
    }
  };

  // _generateBlock generates 64 bytes from key, nonce, and counter,
  // and puts the result into this.block.
  Salsa20.prototype._generateBlock = function() {
    var j0 = this.sigmaWords[0],
      j1 = this.keyWords[0],
      j2 = this.keyWords[1],
      j3 = this.keyWords[2],
      j4 = this.keyWords[3],
      j5 = this.sigmaWords[1],
      j6 = this.nonceWords[0],
      j7 = this.nonceWords[1],
      j8 = this.counterWords[0],
      j9 = this.counterWords[1],
      j10 = this.sigmaWords[2],
      j11 = this.keyWords[4],
      j12 = this.keyWords[5],
      j13 = this.keyWords[6],
      j14 = this.keyWords[7],
      j15 = this.sigmaWords[3];

      var x0 = j0, x1 = j1, x2 = j2, x3 = j3, x4 = j4, x5 = j5, x6 = j6, x7 = j7,
        x8 = j8, x9 = j9, x10 = j10, x11 = j11, x12 = j12, x13 = j13, x14 = j14, x15 = j15;

      var u;

      for (var i = 0; i < this.rounds; i += 2) {
        u = x0 + x12;
        x4 ^= (u<<7) | (u>>>(32-7));
        u = x4 + x0;
        x8 ^= (u<<9) | (u>>>(32-9));
        u = x8 + x4;
        x12 ^= (u<<13) | (u>>>(32-13));
        u = x12 + x8;
        x0 ^= (u<<18) | (u>>>(32-18));

        u = x5 + x1;
        x9 ^= (u<<7) | (u>>>(32-7));
        u = x9 + x5;
        x13 ^= (u<<9) | (u>>>(32-9));
        u = x13 + x9;
        x1 ^= (u<<13) | (u>>>(32-13));
        u = x1 + x13;
        x5 ^= (u<<18) | (u>>>(32-18));

        u = x10 + x6;
        x14 ^= (u<<7) | (u>>>(32-7));
        u = x14 + x10;
        x2 ^= (u<<9) | (u>>>(32-9));
        u = x2 + x14;
        x6 ^= (u<<13) | (u>>>(32-13));
        u = x6 + x2;
        x10 ^= (u<<18) | (u>>>(32-18));

        u = x15 + x11;
        x3 ^= (u<<7) | (u>>>(32-7));
        u = x3 + x15;
        x7 ^= (u<<9) | (u>>>(32-9));
        u = x7 + x3;
        x11 ^= (u<<13) | (u>>>(32-13));
        u = x11 + x7;
        x15 ^= (u<<18) | (u>>>(32-18));

        u = x0 + x3;
        x1 ^= (u<<7) | (u>>>(32-7));
        u = x1 + x0;
        x2 ^= (u<<9) | (u>>>(32-9));
        u = x2 + x1;
        x3 ^= (u<<13) | (u>>>(32-13));
        u = x3 + x2;
        x0 ^= (u<<18) | (u>>>(32-18));

        u = x5 + x4;
        x6 ^= (u<<7) | (u>>>(32-7));
        u = x6 + x5;
        x7 ^= (u<<9) | (u>>>(32-9));
        u = x7 + x6;
        x4 ^= (u<<13) | (u>>>(32-13));
        u = x4 + x7;
        x5 ^= (u<<18) | (u>>>(32-18));

        u = x10 + x9;
        x11 ^= (u<<7) | (u>>>(32-7));
        u = x11 + x10;
        x8 ^= (u<<9) | (u>>>(32-9));
        u = x8 + x11;
        x9 ^= (u<<13) | (u>>>(32-13));
        u = x9 + x8;
        x10 ^= (u<<18) | (u>>>(32-18));

        u = x15 + x14;
        x12 ^= (u<<7) | (u>>>(32-7));
        u = x12 + x15;
        x13 ^= (u<<9) | (u>>>(32-9));
        u = x13 + x12;
        x14 ^= (u<<13) | (u>>>(32-13));
        u = x14 + x13;
        x15 ^= (u<<18) | (u>>>(32-18));
      }

      x0 += j0;
      x1 += j1;
      x2 += j2;
      x3 += j3;
      x4 += j4;
      x5 += j5;
      x6 += j6;
      x7 += j7;
      x8 += j8;
      x9 += j9;
      x10 += j10;
      x11 += j11;
      x12 += j12;
      x13 += j13;
      x14 += j14;
      x15 += j15;

      this.block[ 0] = ( x0 >>>  0) & 0xff; this.block[ 1] = ( x0 >>>  8) & 0xff;
      this.block[ 2] = ( x0 >>> 16) & 0xff; this.block[ 3] = ( x0 >>> 24) & 0xff;
      this.block[ 4] = ( x1 >>>  0) & 0xff; this.block[ 5] = ( x1 >>>  8) & 0xff;
      this.block[ 6] = ( x1 >>> 16) & 0xff; this.block[ 7] = ( x1 >>> 24) & 0xff;
      this.block[ 8] = ( x2 >>>  0) & 0xff; this.block[ 9] = ( x2 >>>  8) & 0xff;
      this.block[10] = ( x2 >>> 16) & 0xff; this.block[11] = ( x2 >>> 24) & 0xff;
      this.block[12] = ( x3 >>>  0) & 0xff; this.block[13] = ( x3 >>>  8) & 0xff;
      this.block[14] = ( x3 >>> 16) & 0xff; this.block[15] = ( x3 >>> 24) & 0xff;
      this.block[16] = ( x4 >>>  0) & 0xff; this.block[17] = ( x4 >>>  8) & 0xff;
      this.block[18] = ( x4 >>> 16) & 0xff; this.block[19] = ( x4 >>> 24) & 0xff;
      this.block[20] = ( x5 >>>  0) & 0xff; this.block[21] = ( x5 >>>  8) & 0xff;
      this.block[22] = ( x5 >>> 16) & 0xff; this.block[23] = ( x5 >>> 24) & 0xff;
      this.block[24] = ( x6 >>>  0) & 0xff; this.block[25] = ( x6 >>>  8) & 0xff;
      this.block[26] = ( x6 >>> 16) & 0xff; this.block[27] = ( x6 >>> 24) & 0xff;
      this.block[28] = ( x7 >>>  0) & 0xff; this.block[29] = ( x7 >>>  8) & 0xff;
      this.block[30] = ( x7 >>> 16) & 0xff; this.block[31] = ( x7 >>> 24) & 0xff;
      this.block[32] = ( x8 >>>  0) & 0xff; this.block[33] = ( x8 >>>  8) & 0xff;
      this.block[34] = ( x8 >>> 16) & 0xff; this.block[35] = ( x8 >>> 24) & 0xff;
      this.block[36] = ( x9 >>>  0) & 0xff; this.block[37] = ( x9 >>>  8) & 0xff;
      this.block[38] = ( x9 >>> 16) & 0xff; this.block[39] = ( x9 >>> 24) & 0xff;
      this.block[40] = (x10 >>>  0) & 0xff; this.block[41] = (x10 >>>  8) & 0xff;
      this.block[42] = (x10 >>> 16) & 0xff; this.block[43] = (x10 >>> 24) & 0xff;
      this.block[44] = (x11 >>>  0) & 0xff; this.block[45] = (x11 >>>  8) & 0xff;
      this.block[46] = (x11 >>> 16) & 0xff; this.block[47] = (x11 >>> 24) & 0xff;
      this.block[48] = (x12 >>>  0) & 0xff; this.block[49] = (x12 >>>  8) & 0xff;
      this.block[50] = (x12 >>> 16) & 0xff; this.block[51] = (x12 >>> 24) & 0xff;
      this.block[52] = (x13 >>>  0) & 0xff; this.block[53] = (x13 >>>  8) & 0xff;
      this.block[54] = (x13 >>> 16) & 0xff; this.block[55] = (x13 >>> 24) & 0xff;
      this.block[56] = (x14 >>>  0) & 0xff; this.block[57] = (x14 >>>  8) & 0xff;
      this.block[58] = (x14 >>> 16) & 0xff; this.block[59] = (x14 >>> 24) & 0xff;
      this.block[60] = (x15 >>>  0) & 0xff; this.block[61] = (x15 >>>  8) & 0xff;
      this.block[62] = (x15 >>> 16) & 0xff; this.block[63] = (x15 >>> 24) & 0xff;
  };


  return Salsa20;
})();


// ---------- Test -------------
var key = [0x80]; for (i = 1; i < 32; i++) key[i] = 0;
var nonce = [];   for (i = 0; i < 8; i++) nonce[i] = 0;

var good = [
  // 0..63
  "e3be8fdd8beca2e3ea8ef9475b29a6e7" +
  "003951e1097a5c38d23b7a5fad9f6844" +
  "b22c97559e2723c7cbbd3fe4fc8d9a07" +
  "44652a83e72a9c461876af4d7ef1a117", 
  // 192..255
  "57be81f47b17d9ae7c4ff15429a73e10" +
  "acf250ed3a90a93c711308a74c6216a9" +
  "ed84cd126da7f28e8abf8bb63517e1ca" +
  "98e712f4fb2e1a6aed9fdc73291faa17",
  // 256..319
  "958211c4ba2ebd5838c635edb81f513a" +
  "91a294e194f1c039aeec657dce40aa7e" +
  "7c0af57cacefa40c9f14b71a4b3456a6" +
  "3e162ec7d8d10b8ffb1810d71001b618",
  // 448..511
  "696afcfd0cddcc83c7e77f11a649d79a" +
  "cdc3354e9635ff137e929933a0bd6f53" +
  "77efa105a3a4266b7c0d089d08f1e855" +
  "cc32b15b93784a36e56a76cc64bc8477"
];

var state = new Salsa20(key, nonce);

// compare 0..63
if (state.getHexString(64) != good[0])
  console.log("BAD 0..63");
// discard 64..191
state.getBytes(128);
// compare 192..255
if (state.getHexString(64) != good[1])
  console.log("BAD 192..255");
// compare 256..319
if (state.getHexString(64) != good[2])
  console.log("BAD 256..319");
// discard 320..447
state.getBytes(128);
// compare 448..511
if (state.getHexString(64) != good[3])
  console.log("BAD 448..511");

console.log("done");
