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

        if (arguments.length === 2 && typeof defaultValue === 'string') {
          options = { defaultValue: defaultValue };
        }
        else if (arguments.length === 3 && !options.defaultValue) {
          options.defaultValue = defaultValue;
        }

        value = i18n.interpolate(''+options.defaultValue, options);

        return value;
      };

      onLoad({ t: t });
    }
  };

  return i18n;
});