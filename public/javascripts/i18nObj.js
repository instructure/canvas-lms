define([
  'vendor/i18n',
  'jquery',
  'str/htmlEscape',
  'str/pluralize',
  'str/escapeRegex',
  'compiled/str/i18nLolcalize',
  'vendor/date' /* Date.parse, Date.UTC */
], function(I18n, $, htmlEscape, pluralize, escapeRegex, i18nLolcalize) {

// Export globally for tinymce/specs
window.I18n = I18n;

I18n.locale = document.documentElement.getAttribute('lang');

// Set the placeholder format. Accepts `%{placeholder}` and %h{placeholder}.
// %h{placeholder} indicate it is an htmlSafe value, (e.g. an input) and
// anything not already safe should be html-escaped
I18n.PLACEHOLDER = /%h?\{(.*?)\}/gm;

I18n.isValidNode = function(obj, node) {
  // handle names like "foo.bar.baz"
  var nameParts = node.split('.');
  for (var j=0; j < nameParts.length; j++) {
    obj = obj[nameParts[j]];
    if (typeof obj === 'undefined' || obj === null) return false;
  }
  return true;
};

I18n.lookup = function(scope, options) {
  var translations = this.prepareOptions(I18n.translations);
  var locales = [I18n.currentLocale()];
  if (I18n.currentLocale() != I18n.defaultLocale) {
      locales.push(I18n.defaultLocale);
  }
  options = this.prepareOptions(options);

  if (typeof(scope) == "object") {
    scope = scope.join(this.defaultSeparator);
  }

  if (options.scope) {
    scope = options.scope.toString() + this.defaultSeparator + scope;
  }

  var messages, scopes;
  while (!messages && locales.length > 0) {
    messages = translations[locales.shift()];
    scopes = scope.split(this.defaultSeparator);
    while (messages && scopes.length > 0) {
      var currentScope = scopes.shift();
      messages = messages[currentScope];
    }
  }

  if (!messages && this.isValidNode(options, "defaultValue")) {
    messages = options.defaultValue;
  }

  return messages;
};

I18n.interpolate = function(message, options) {
  var placeholder, value, name, matches, needsEscaping = false, htmlSafe;

  options = this.prepareOptions(options);
  if (options.wrapper) {
    needsEscaping = true;
    message = this.applyWrappers(message, options.wrapper);
  }
  if (options.needsEscaping) {
    needsEscaping = true;
  }

  matches = message.match(this.PLACEHOLDER) || [];

  for (var i = 0; placeholder = matches[i]; i++) {
    name = placeholder.replace(this.PLACEHOLDER, "$1");
    htmlSafe = (placeholder[1] === 'h'); // e.g. %h{input}

    // handle names like "foo.bar.baz"
    var nameParts = name.split('.');
    value = options;
    for (var j=0; j < nameParts.length; j++) {
      value = value[nameParts[j]];
    }

    if (!this.isValidNode(options, name)) {
      value = "[missing " + placeholder + " value]";
    }
    if (needsEscaping) {
      if (!value._icHTMLSafe && !htmlSafe) {
        value = htmlEscape(value);
      }
    } else if (value._icHTMLSafe || htmlSafe) {
      needsEscaping = true;
      message = htmlEscape(message);
    }

    regex = new RegExp(placeholder.replace(/\{/gm, "\\{").replace(/\}/gm, "\\}"));
    message = message.replace(regex, value);
  }

  return message;
};

I18n.wrapperRegexes = {};

I18n.applyWrappers = function(string, wrappers) {
  var keys = [];
  var key;

  string = htmlEscape(string);
  if (typeof(wrappers) == "string") {
    wrappers = {'*': wrappers};
  }
  for (key in wrappers) {
    keys.push(key);
  }
  keys.sort().reverse();
  for (var i=0, l=keys.length; i < l; i++) {
    key = keys[i];
    if (!this.wrapperRegexes[key]) {
      var escapedKey = escapeRegex(key);
      this.wrapperRegexes[key] = new RegExp(escapedKey + "([^" + escapedKey + "]*)" + escapedKey, "g");
    }
    string = string.replace(this.wrapperRegexes[key], wrappers[key]);
  }
  return string;
};

var _localize = I18n.localize;
I18n.localize = function(scope, value) {
  var result = _localize.call(this, scope, value);
  if (scope.match(/^(date|time)/))
    result = result.replace(/\s{2,}/, ' ');
  return result;
}

I18n.strftime = function(date, format) {
  var options = this.lookup("date");
  if (options) {
    options.meridian = options.meridian || ["AM", "PM"];
  }

  var weekDay = date.getDay();
  var day = date.getDate();
  var year = date.getFullYear();
  var month = date.getMonth() + 1;
  var dayOfYear = 1 + Math.round((new Date(year, month - 1, day) - new Date(year, 0, 1)) / 86400000);
  var hour = date.getHours();
  var hour12 = hour;
  var meridian = hour > 11 ? 1 : 0;
  var secs = date.getSeconds();
  var mils = date.getMilliseconds();
  var mins = date.getMinutes();
  var offset = date.getTimezoneOffset();
  var epochOffset = Math.floor(date.getTime() / 1000);
  var absOffsetHours = Math.floor(Math.abs(offset / 60));
  var absOffsetMinutes = Math.abs(offset) - (absOffsetHours * 60);
  var timezoneoffset = (offset > 0 ? "-" : "+") + (absOffsetHours.toString().length < 2 ? "0" + absOffsetHours : absOffsetHours) + (absOffsetMinutes.toString().length < 2 ? "0" + absOffsetMinutes : absOffsetMinutes);

  if (hour12 > 12) {
    hour12 = hour12 - 12;
  } else if (hour12 === 0) {
    hour12 = 12;
  }

  var padding = function(n, pad, len) {
    if (typeof(pad) == 'undefined') {
      pad = '00';
    }
    if (typeof(len) == 'undefined') {
      len = 2;
    }
    var s = pad + n.toString();
    return s.substr(s.length - len);
  };

  /*
    not implemented:
      %N  // nanoseconds
      %6N // microseconds
      %9N // nanoseconds
      %U  // week number of year, starting with the first Sunday as the first day of the 01st week (00..53)
      %V  // week number of year according to ISO 8601 (01..53) (week starts on Monday, week 01 is the one with the first Thursday of the year)
      %W  // week number of year, starting with the first Monday as the first day of the 01st week (00..53)
      %Z  // time zone name
  */
  var optionsNeeded = false;
  var f = format.replace(/%([DFrRTv])/g, function(str, p1) {
    return {
      D: '%m/%d/%y',
      F: '%Y-%m-%d',
      r: '%I:%M:%S %p',
      R: '%H:%M',
      T: '%H:%M:%S',
      v: '%e-%b-%Y'
    }[p1];
  }).replace(/%(%|\-?[a-zA-Z]|3N)/g, function(str, p1) {
    // check to see if we need an options object
    switch (p1) {
      case 'a':
      case 'A':
      case 'b':
      case 'B':
      case 'h':
      case 'p':
      case 'P':
        if (options == null) {
          optionsNeeded = true;
          return '';
        }
    }

    switch (p1) {
      case 'a':  return options.abbr_day_names[weekDay];
      case 'A':  return options.day_names[weekDay];
      case 'b':  return options.abbr_month_names[month];
      case 'B':  return options.month_names[month];
      case 'd':  return padding(day);
      case '-d': return day;
      case 'e':  return padding(day, ' ');
      case 'h':  return options.abbr_month_names[month];
      case 'H':  return padding(hour);
      case '-H': return hour;
      case 'I':  return padding(hour12);
      case '-I': return hour12;
      case 'j':  return padding(dayOfYear, '00', 3);
      case 'k':  return padding(hour, ' ');
      case 'l':  return padding(hour12, ' ');
      case 'L':  return padding(mils, '00', 3);
      case 'm':  return padding(month);
      case '-m': return month;
      case 'M':  return padding(mins);
      case '-M': return mins;
      case 'n':  return "\n";
      case '3N': return padding(mils, '00', 3);
      case 'p':  return options.meridian[meridian];
      case 'P':  return options.meridian[meridian].toLowerCase();
      case 's':  return epochOffset;
      case 'S':  return padding(secs);
      case '-S': return secs;
      case 't':  return "\t";
      case 'u':  return weekDay || weekDay + 7;
      case 'w':  return weekDay;
      case 'y':  return padding(year);
      case '-y': return padding(year).replace(/^0+/, "");
      case 'Y':  return year;
      case 'z':  return timezoneoffset;
      case '%':  return '%';
      default:   return str;
    }
  });

  if (optionsNeeded) {
    return date.toString();
  }

  return f;
};



var normalizeDefault = function(str) { return str };
if (window.ENV && window.ENV.lolcalize) {
  normalizeDefault = i18nLolcalize;
}

I18n.scoped = function(scope, callback) {
  var i18n_scope = new I18n.scope(scope);
  if (callback) {
    callback(i18n_scope);
  }
  return i18n_scope;
};
I18n.scope = function(scope) {
  this.scope = scope;
};
I18n.scope.prototype = {
  resolveScope: function(key) {
    if (typeof(key) == "object") {
      key = key.join(I18n.defaultSeparator);
    }
    if (key[0] == '#') {
      return key.replace(/^#/, '');
    } else {
      return this.scope + I18n.defaultSeparator + key;
    }
  },
  translate: function(scope, defaultValue, options) {
    options = options || {};
    if (typeof(options.count) != 'undefined' && typeof(defaultValue) == "string" && defaultValue.match(/^[\w\-]+$/)) {
      defaultValue = pluralize.withCount(options.count, defaultValue);
    }
    options.defaultValue = normalizeDefault(defaultValue);
    return I18n.translate(this.resolveScope(scope), options);
  },
  localize: function(scope, value) {
    return I18n.localize(this.resolveScope(scope), value);
  },
  pluralize: function(count, scope, options) {
    return I18n.pluralize(count, this.resolveScope(scope), options);
  },
  beforeLabel: function(text) {
    return this.t("#before_label_wrapper", "%{text}:", {'text': text});
  },
  lookup: function(scope, options) {
    return I18n.lookup(this.resolveScope(scope), options);
  },
  toTime:       I18n.toTime.bind(I18n),
  toNumber:     I18n.toNumber.bind(I18n),
  toCurrency:   I18n.toCurrency.bind(I18n),
  toHumanSize:  I18n.toHumanSize.bind(I18n),
  toPercentage: I18n.toPercentage.bind(I18n)
};
I18n.scope.prototype.t = I18n.scope.prototype.translate;
I18n.scope.prototype.l = I18n.scope.prototype.localize;
I18n.scope.prototype.p = I18n.scope.prototype.pluralize;


if (I18n.translations) {
  $.extend(true, I18n.translations, {en: {}});
} else {
  I18n.translations = {en: {}};
}

return I18n;

});

