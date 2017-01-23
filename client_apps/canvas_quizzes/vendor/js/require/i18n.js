define([], () => {
  const INTERPOLATER = /\%\{([^\}]+)\}/g;
  const KEY_PATTERN = /^\#?\w+(\.\w+)+$/; // handle our absolute keys
  const COUNT_KEY_MAP = ['zero', 'one'];

  var i18n = {
    interpolate (contents, options) {
      const variables = contents.match(INTERPOLATER);

      if (variables) {
        variables.forEach((variable) => {
          const optionKey = variable.substr(2, variable.length - 3);
          contents = contents.replace(new RegExp(variable, 'g'), options[optionKey]);
        });
      }

      return contents;
    },

    isKeyProvided (keyOrDefault, defaultOrOptions, maybeOptions) {
      if (typeof keyOrDefault === 'object') { return false; }
      if (typeof defaultOrOptions === 'string') { return true; }
      if (maybeOptions) { return true; }
      if (typeof keyOrDefault === 'string' && keyOrDefault.match(KEY_PATTERN)) { return true; }
      return false;
    },

    inferArguments (args) {
      const hasKey = this.isKeyProvided.apply(this, args);
      if (hasKey) args = args.slice(1);
      return args;
    },

    load (name, req, onLoad) {
      // Development only.
      // This gets replaced by Canvas I18n when embedded.
      //
      // Adapted/simplified from i18nliner-js and canvas' i18nObj
      //
      // Returns the defaultValue you provide with variables interpolated,
      // if specified.
      //
      // See the project README for i18n work.

      const t = function () {
        const args = i18n.inferArguments([].slice.call(arguments));
        let defaultValue = args[0];
        defaultValue = defaultValue || '';
        const options = args[1] || {};
        let countKey;

        if (typeof defaultValue !== 'string' && typeof defaultValue !== 'object') {
          throw new Error('Bad I18n.t() call, expected a default string or object.');
        }

        if (options.hasOwnProperty('count') && typeof defaultValue === 'object') {
          countKey = COUNT_KEY_MAP[options.count];
          defaultValue = defaultValue[countKey] || defaultValue.other;
        }

        return i18n.interpolate(`${defaultValue}`, options);
      };

      const l = function (scope, value) {
        return `${value}`;
      };

      const beforeLabel = function (text) {
        return this.t('#before_label_wrapper', '%{text}:', { text });
      };

      const lookup = function (scope, options) {
        return ['hello', 'goodbye'];
      };

      onLoad({
        t,
        l,
        beforeLabel,
        lookup
      });
    }
  };

  return i18n;
});
