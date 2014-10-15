define([
  'jquery',
  'str/htmlEscape',
  'str/pluralize',
  'str/escapeRegex',
  'compiled/str/i18nLolcalize',
  'vendor/date' /* Date.parse, Date.UTC */
], function($, htmlEscape, pluralize, escapeRegex, i18nLolcalize) {

// Instantiate the object, export globally for tinymce/specs
var I18n = window.I18n = {};

// Set default locale to english
I18n.defaultLocale = "en";

// Set default separator
I18n.defaultSeparator = ".";

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

// Merge serveral hash options, checking if value is set before
// overwriting any value. The precedence is from left to right.
//
//   I18n.prepareOptions({name: "John Doe"}, {name: "Mary Doe", role: "user"});
//   #=> {name: "John Doe", role: "user"}
//
I18n.prepareOptions = function() {
  var options = {};
  var opts;
  var count = arguments.length;

  for (var i = 0; i < count; i++) {
    opts = arguments[i];

    if (!opts) {
      continue;
    }

    for (var key in opts) {
      if (!this.isValidNode(options, key)) {
        options[key] = opts[key];
      }
    }
  }

  return options;
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

I18n.translate = function(scope, options) {
  options = this.prepareOptions(options);
  var translation = this.lookup(scope, options);

  try {
    if (typeof(translation) == "object") {
      if (typeof(options.count) == "number") {
        return this.pluralize(options.count, scope, options);
      } else {
        return translation;
      }
    } else {
      return this.interpolate(translation, options);
    }
  } catch(err) {
    return this.missingTranslation(scope);
  }
};

I18n.localize = function(scope, value) {
  switch (scope) {
    case "currency":
      return this.toCurrency(value);
    case "number":
      scope = this.lookup("number.format");
      return this.toNumber(value, scope);
    case "percentage":
      return this.toPercentage(value);
    default:
      if (scope.match(/^(date|time)/)) {
        return this.toTime(scope, value).replace(/\s{2,}/, ' ');
      } else {
        return value.toString();
      }
  }
};

I18n.parseDate = function(d) {
  var matches, date;
  matches = d.toString().match(/(\d{4})-(\d{2})-(\d{2})(?:[ |T](\d{2}):(\d{2}):(\d{2}))?(Z)?/);

  if (matches) {
    // date/time strings: yyyy-mm-dd hh:mm:ss or yyyy-mm-dd or yyyy-mm-ddThh:mm:ssZ
    for (var i = 1; i <= 6; i++) {
      matches[i] = parseInt(matches[i], 10) || 0;
    }

    // month starts on 0
    matches[2] -= 1;

    if (matches[7]) {
      date = new Date(Date.UTC(matches[1], matches[2], matches[3], matches[4], matches[5], matches[6]));
    } else {
      date = new Date(matches[1], matches[2], matches[3], matches[4], matches[5], matches[6]);
    }
  } else if (typeof(d) == "number") {
    // UNIX timestamp
    date = new Date();
    date.setTime(d);
  } else {
    // an arbitrary javascript string
    date = new Date();
    date.setTime(Date.parse(d));
  }

  return date;
};

I18n.toTime = function(scope, d) {
  var date = this.parseDate(d);
  var format = this.lookup(scope);

  if (date.toString().match(/invalid/i)) {
    return date.toString();
  }

  if (!format) {
    return date.toString();
  }

  return this.strftime(date, format);
};

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

I18n.toNumber = function(number, options) {
  options = this.prepareOptions(
    options,
    this.lookup("number.format"),
    {precision: 3, separator: ".", delimiter: ",", strip_insignificant_zeros: false}
  );

  var negative = number < 0;
  var string = Math.abs(number).toFixed(options.precision).toString();
  var parts = string.split(".");

  number = parts[0];
  var precision = parts[1];

  var n = [];

  while (number.length > 0) {
    n.unshift(number.substr(Math.max(0, number.length - 3), 3));
    number = number.substr(0, number.length -3);
  }

  var formattedNumber = n.join(options.delimiter);

  if (options.precision > 0) {
    formattedNumber += options.separator + parts[1];
  }

  if (negative) {
    formattedNumber = "-" + formattedNumber;
  }

  if (options.strip_insignificant_zeros) {
    var regex = {
        separator: new RegExp(options.separator.replace(/\./, "\\.") + "$")
      , zeros: /0+$/
    };

    formattedNumber = formattedNumber
      .replace(regex.zeros, "")
      .replace(regex.separator, "");
  }

  return formattedNumber;
};

I18n.toCurrency = function(number, options) {
  options = this.prepareOptions(
    options,
    this.lookup("number.currency.format"),
    this.lookup("number.format"),
    {unit: "$", precision: 2, format: "%u%n", delimiter: ",", separator: "."}
  );

  number = this.toNumber(number, options);
  number = options.format
    .replace("%u", options.unit)
    .replace("%n", number);

  return number;
};

I18n.toHumanSize = function(number, options) {
  var kb = 1024
    , size = number
    , iterations = 0
    , unit
    , precision
  ;

  while (size >= kb && iterations < 4) {
    size = size / kb;
    iterations += 1;
  }

  if (iterations === 0) {
    unit = this.t("number.human.storage_units.units.byte", {count: size});
    precision = 0;
  } else {
    unit = this.t("number.human.storage_units.units." + [null, "kb", "mb", "gb", "tb"][iterations]);
    precision = (size - Math.floor(size) === 0) ? 0 : 1;
  }

  options = this.prepareOptions(
    options,
    {precision: precision, format: "%n%u", delimiter: ""}
  );

  number = this.toNumber(size, options);
  number = options.format
    .replace("%u", unit)
    .replace("%n", number);

  return number;
};

I18n.toPercentage = function(number, options) {
  options = this.prepareOptions(
    options,
    this.lookup("number.percentage.format"),
    this.lookup("number.format"),
    {precision: 3, separator: ".", delimiter: ""}
  );

  number = this.toNumber(number, options);
  return number + "%";
};

I18n.pluralize = function(count, scope, options) {
  var translation;

  try {
    translation = this.lookup(scope, options);
  } catch (error) {}

  if (!translation) {
    return this.missingTranslation(scope);
  }

  var message;
  options = this.prepareOptions(options);
  options.count = count.toString();

  switch(Math.abs(count)) {
    case 0:
      message = this.isValidNode(translation, "zero") ? translation.zero :
                this.isValidNode(translation, "none") ? translation.none :
                this.isValidNode(translation, "other") ? translation.other :
                this.missingTranslation(scope, "zero");
      break;
    case 1:
      message = this.isValidNode(translation, "one") ? translation.one : this.missingTranslation(scope, "one");
      break;
    default:
      message = this.isValidNode(translation, "other") ? translation.other : this.missingTranslation(scope, "other");
  }

  return this.interpolate(message, options);
};

I18n.missingTranslation = function() {
  var message = '[missing "' + this.currentLocale();
  var count = arguments.length;

  for (var i = 0; i < count; i++) {
    message += "." + arguments[i];
  }

  message += '" translation]';

  return message;
};

I18n.currentLocale = function() {
  return (I18n.locale || I18n.defaultLocale);
};

// shortcuts
I18n.t = I18n.translate;
I18n.l = I18n.localize;
I18n.p = I18n.pluralize;


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
  toTime: function(scope, d) {
    return I18n.toTime(scope, d);
  },
  toNumber: function(number, options) {
    return I18n.toNumber(number, options);
  },
  toCurrency: function(number, options) {
    return I18n.toCurrency(number, options);
  },
  toHumanSize: function(number, options) {
    return I18n.toHumanSize(number, options);
  },
  toPercentage: function(number, options) {
    return I18n.toPercentage(number, options);
  },
  lookup: function(scope, options) {
    return I18n.lookup(this.resolveScope(scope), options);
  }
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

