// Generated by IcedCoffeeScript 1.6.3-f
(function() {
  var uint_max;



  uint_max = Math.pow(2, 32);

  exports.fixup_uint32 = function(x) {
    var ret;
    ret = x > uint_max ? x % uint_max : x < 0 ? uint_max + x : x;
    return ret;
  };

}).call(this);