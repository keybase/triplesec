(function() {
  var __slice = [].slice;

  window.iced = {
    Deferrals: (function() {
      function _Class(_arg) {
        this.continuation = _arg;
        this.count = 1;
        this.ret = null;
      }

      _Class.prototype._fulfill = function() {
        if (!--this.count) {
          return this.continuation(this.ret);
        }
      };

      _Class.prototype.defer = function(defer_params) {
        var _this = this;
        ++this.count;
        return function() {
          var inner_params, _ref;
          inner_params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (defer_params != null) {
            if ((_ref = defer_params.assign_fn) != null) {
              _ref.apply(null, inner_params);
            }
          }
          return _this._fulfill();
        };
      };

      return _Class;

    })(),
    findDeferral: function() {
      return null;
    },
    trampoline: function(_fn) {
      return _fn();
    }
  };
  window.__iced_k = window.__iced_k_noop = function() {};

  $(function() {
    var input_change, progress, progress_hook, reset_progress, textarea_auto,
      _this = this;
    if (window.location.href.indexOf('now_in_python.html') === -1) {
      window.location = './triplesec_now_in_python.html';
    }
    textarea_auto = function(ta) {
      ta.style.overflow = 'hidden';
      ta.style.height = 0;
      return ta.style.height = "" + (25 + Math.min(600, Math.max(ta.scrollHeight, 50))) + "px";
    };
    input_change = function() {
      var k, v;
      textarea_auto($('#demo-input-data')[0]);
      v = $('#demo-input-data').val();
      k = $('#demo-input-key').val();
      $('.btn-encrypt, .btn-decrypt').prop('disabled', true);
      if (v && v.length && k && k.length) {
        $('.btn-encrypt').prop('disabled', false);
        if ((v.match(/^[a-f0-9]+$/i)) && !(v.length % 2)) {
          return $('.btn-decrypt').prop('disabled', false);
        }
      }
    };
    progress = [];
    reset_progress = function(msg) {
      progress = [];
      return $("#progress-summary").html(msg || '');
    };
    progress_hook = function(p) {
      var h, pr, _i, _len;
      if (progress.length && (progress[progress.length - 1].what === p.what)) {
        progress[progress.length - 1] = p;
      } else {
        progress.push(p);
      }
      h = "";
      for (_i = 0, _len = progress.length; _i < _len; _i++) {
        pr = progress[_i];
        h += "<li>" + pr.what + " " + pr.i + "/" + pr.total + "</li>";
      }
      return $("#progress-summary").html(h);
    };
    $('#demo-input-data').on('change', function() {
      return input_change();
    });
    $('#demo-input-data').on('keyup', function() {
      return input_change();
    });
    $('#demo-input-key').on('change', function() {
      return input_change();
    });
    $('#demo-input-key').on('keyup', function() {
      return input_change();
    });
    $('.btn-encrypt').on('click', function() {
      var data, err, hex, key, out, ___iced_passed_deferral, __iced_deferrals, __iced_k;
      __iced_k = __iced_k_noop;
      ___iced_passed_deferral = iced.findDeferral(arguments);
      reset_progress();
      $('.btn-encrypt, .btn-decrypt').prop('disabled', true);
      data = new triplesec.Buffer($('#demo-input-data').val());
      key = new triplesec.Buffer($('#demo-input-key').val());
      (function(__iced_k) {
        __iced_deferrals = new iced.Deferrals(__iced_k, {
          parent: ___iced_passed_deferral,
          filename: "site/iced/site.iced"
        });
        triplesec.encrypt({
          data: data,
          key: key,
          rng: triplesec.rng,
          progress_hook: progress_hook,
          version: 3
        }, __iced_deferrals.defer({
          assign_fn: (function() {
            return function() {
              err = arguments[0];
              return out = arguments[1];
            };
          })(),
          lineno: 51
        }));
        __iced_deferrals._fulfill();
      })(function() {
        (function(__iced_k) {
          __iced_deferrals = new iced.Deferrals(__iced_k, {
            parent: ___iced_passed_deferral,
            filename: "site/iced/site.iced"
          });
          setTimeout(__iced_deferrals.defer({
            lineno: 52
          }), 5);
          __iced_deferrals._fulfill();
        })(function() {
          if (err) {
            reset_progress("<li>" + err + "</li>");
          } else {
            hex = out.toString('hex');
            $("#demo-input-data").val(hex);
            textarea_auto($("#demo-input-data")[0]);
          }
          return input_change();
        });
      });
    });
    $('.btn-decrypt').on('click', function() {
      var data, err, key, out, txt, ___iced_passed_deferral, __iced_deferrals, __iced_k;
      __iced_k = __iced_k_noop;
      ___iced_passed_deferral = iced.findDeferral(arguments);
      reset_progress();
      $('.btn-encrypt, .btn-decrypt').prop('disabled', true);
      data = new triplesec.Buffer($('#demo-input-data').val(), 'hex');
      key = new triplesec.Buffer($('#demo-input-key').val());
      (function(__iced_k) {
        __iced_deferrals = new iced.Deferrals(__iced_k, {
          parent: ___iced_passed_deferral,
          filename: "site/iced/site.iced"
        });
        triplesec.decrypt({
          data: data,
          key: key,
          progress_hook: progress_hook
        }, __iced_deferrals.defer({
          assign_fn: (function() {
            return function() {
              err = arguments[0];
              return out = arguments[1];
            };
          })(),
          lineno: 70
        }));
        __iced_deferrals._fulfill();
      })(function() {
        (function(__iced_k) {
          __iced_deferrals = new iced.Deferrals(__iced_k, {
            parent: ___iced_passed_deferral,
            filename: "site/iced/site.iced"
          });
          setTimeout(__iced_deferrals.defer({
            lineno: 71
          }), 5);
          __iced_deferrals._fulfill();
        })(function() {
          if (err) {
            reset_progress("<li>" + err + "</li>");
          } else {
            txt = out.toString();
            $("#demo-input-data").val(txt);
            textarea_auto($("#demo-input-data")[0]);
          }
          return input_change();
        });
      });
    });
    return textarea_auto($("#demo-input-data")[0]);
  });

}).call(this);
