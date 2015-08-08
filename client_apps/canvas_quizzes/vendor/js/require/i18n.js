define([], function() {
  var INTERPOLATER = /\%\{([^\}]+)\}/g;
  var KEY_PATTERN = /^\#?\w+(\.\w+)+$/; // handle our absolute keys
  var COUNT_KEY_MAP = ["zero", "one"];

  var i18n = {
    interpolate: function(contents, options) {
      var variables = contents.match(INTERPOLATER);

      if (variables) {
        variables.forEach(function(variable) {
          var optionKey = variable.substr(2, variable.length - 3);
          contents = contents.replace(new RegExp(variable, 'g'), options[optionKey]);
        });
      }

      return contents;
    },

    isKeyProvided: function(keyOrDefault, defaultOrOptions, maybeOptions) {
      if (typeof keyOrDefault === 'object')
        return false;
      if (typeof defaultOrOptions === 'string')
        return true;
      if (maybeOptions)
        return true;
      if (typeof keyOrDefault === 'string' && keyOrDefault.match(this.keyPattern))
        return true;
      return false;
    },

    inferArguments: function(args) {
      var hasKey = this.isKeyProvided.apply(this, args);
      if (hasKey) args = args.slice(1);
      return args;
    },

    load: function(name, req, onLoad) {
      // Development only.
      // This gets replaced by Canvas I18n when embedded.
      //
      // Adapted/simplified from i18nliner-js and canvas' i18nObj
      //
      // Returns the defaultValue you provide with variables interpolated,
      // if specified.
      //
      // See the project README for i18n work.

      var t = function() {
        var args = i18n.inferArguments([].slice.call(arguments));
        var defaultValue = args[0];
        var options = args[1] || {};
        var countKey;

        if (typeof defaultValue !== 'string' && typeof defaultValue !== 'object') {
          throw new Error("Bad I18n.t() call, expected a default string or object.");
        }

        if (options.hasOwnProperty('count') && typeof defaultValue === 'object') {
          countKey = COUNT_KEY_MAP[options.count];
          defaultValue = defaultValue[countKey] || defaultValue.other;
        }

        return i18n.interpolate(''+defaultValue, options);
      };

      var l = function(scope, value) {
        return ''+value;
      };

      var beforeLabel = function(text) {
        return this.t("#before_label_wrapper", "%{text}:", {'text': text});
      };
      
      var lookup = function(scope, options) {
        return ["hello", "goodbye"];
      };
      
      onLoad({
        t: t,
        l: l,
        beforeLabel: beforeLabel,
        lookup: lookup
      });
    }
  };

  return i18n;
});
