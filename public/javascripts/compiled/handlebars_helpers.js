(function() {
  define('compiled/handlebars_helpers', ['vendor/handlebars.vm', 'i18n'], function(Handlebars, I18n) {
    var fn, name, _ref;
    _ref = {
      'debugger': function(optionalValue) {
        console.log('this', this, 'arguments', arguments);
        debugger;
      },
      t: function(key, defaultValue, options) {
        var value, wrappers, _ref;
        wrappers = {};
        options = (_ref = options != null ? options.hash : void 0) != null ? _ref : {};
        for (key in options) {
          value = options[key];
          if (key.match(/^w\d+$/)) {
            wrappers[new Array(parseInt(key.replace('w', '')) + 2).join('*')] = value;
            delete options[key];
          }
        }
        if (wrappers['*']) {
          options.wrapper = wrappers;
        }
        if (!(this instanceof String || typeof this === 'string')) {
          options = $.extend(options, this);
        }
        return I18n.scoped(options.scope).t(key, defaultValue, options);
      },
      hiddenIf: function(condition) {
        if (condition) {
          return " display:none; ";
        }
      },
      hiddenUnless: function(condition) {
        if (!condition) {
          return " display:none; ";
        }
      },
      friendlyDatetime: function(datetime) {
        datetime = new Date(datetime);
        return new Handlebars.SafeString("<time title='" + datetime + "' datetime='" + (datetime.toISOString()) + "'>" + ($.friendlyDatetime(datetime)) + "</time>");
      },
      datetimeFormatted: function(isoString) {
        if (!isoString.datetime) {
          isoString = $.parseFromISO(isoString);
        }
        return isoString.datetime_formatted;
      },
      mimeClass: function(contentType) {
        return $.mimeClass(contentType);
      },
      newlinesToBreak: function(string) {
        return new Handlebars.SafeString($.htmlEscape(string).replace(/\n/g, "<br />"));
      },
      eachWithIndex: function(context, options) {
        var ctx, index, inverse, ret;
        fn = options.fn;
        inverse = options.inverse;
        ret = '';
        if (context && context.length > 0) {
          for (index in context) {
            ctx = context[index];
            ctx._index = index;
            ret += fn(ctx);
          }
        } else {
          ret = inverse(this);
        }
        return ret;
      }
    };
    for (name in _ref) {
      fn = _ref[name];
      Handlebars.registerHelper(name, fn);
    }
    return Handlebars;
  });
}).call(this);
