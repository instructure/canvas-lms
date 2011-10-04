(function() {
  Handlebars.registerHelper("t", function(key, defaultValue, options) {
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
  });
  Handlebars.registerHelper("hiddenIf", function(condition) {
    if (condition) {
      return " display:none; ";
    }
  });
  Handlebars.registerHelper("hiddenUnless", function(condition) {
    if (!condition) {
      return " display:none; ";
    }
  });
}).call(this);
