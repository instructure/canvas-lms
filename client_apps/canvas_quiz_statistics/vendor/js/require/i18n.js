define([], function() {
  var INTERPOLATER = /\%\{([^\}]+)\}/g;

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

    load : function(name, req, onLoad) {
      // Development only.
      // This gets replaced by Canvas I18n when embedded.
      //
      // Returns the defaultValue you provide with variables interpolated,
      // if specified.
      //
      // See the project README for i18n work.
      var t = function(__key__, defaultValue, options) {
        var value;

        if (arguments.length === 2) {
          if (typeof defaultValue === 'string') {
            options = { defaultValue: defaultValue };
          }
          else if (typeof defaultValue === 'object') {
            options = defaultValue;
          }
          else {
            throw new Error("Bad I18n.t() call, expected an options object or a defaultValue string.");
          }
        }
        else if (arguments.length === 3 && !options.defaultValue) {
          options.defaultValue = defaultValue;
        }

        if (options.hasOwnProperty('count') && typeof defaultValue === 'object') {
          switch(options.count) {
            case 0:
              if (defaultValue.zero) {
                options.defaultValue = defaultValue.zero;
              }
            break;

            case 1:
              if (defaultValue.one) {
                options.defaultValue = defaultValue.one;
              }
            break;

            default:
              if (defaultValue.other) {
                options.defaultValue = defaultValue.other;
              }
          }
        }

        value = i18n.interpolate(''+options.defaultValue, options);

        return value;
      };

      var l = function(scope, value) {
        return ''+value;
      };

      onLoad({
        t: t,
        l: l
      });
    }
  };

  return i18n;
});