define([
  'vendor/i18n_js_extension',
  'jquery',
  'str/htmlEscape',
  'compiled/str/i18nLolcalize',
  'vendor/date' /* Date.parse, Date.UTC */
], function(I18n, $, htmlEscape, i18nLolcalize) {

I18n.locale = document.documentElement.getAttribute('lang');

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

// i18nliner-js overrides interpolate with a wrapper-and-html-safety-aware
// version, so we need to override the now-renamed original
I18n.interpolateWithoutHtmlSafety = function(message, options) {
  options = this.prepareOptions(options);
  var matches = message.match(this.PLACEHOLDER);

  if (!matches) {
    return message;
  }

  var placeholder, value, name;

  for (var i = 0; placeholder = matches[i]; i++) {
    name = placeholder.replace(this.PLACEHOLDER, "$1");

    // handle names like "foo.bar.baz"
    var nameParts = name.split('.');
    value = options;
    for (var j=0; j < nameParts.length; j++) {
      value = value[nameParts[j]];
    }

    if (!this.isValidNode(options, name)) {
      value = "[missing " + placeholder + " value]";
    }

    regex = new RegExp(placeholder.replace(/\{/gm, "\\{").replace(/\}/gm, "\\}"));
    message = message.replace(regex, value);
  }

  return message;
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

I18n.Utils.HtmlSafeString = htmlEscape.SafeString; // this is what we use elsewhere in canvas, so make i18nliner use it too
I18n.CallHelpers.keyPattern = /^\#?\w+(\.\w+)+$/ // handle our absolute keys
I18n.CallHelpers.normalizeKey = function(key, options) {
  if (key[0] === '#') {
    key = key.slice(1);
    delete options.scope;
  }
  return key;
}

if (window.ENV && window.ENV.lolcalize) {
  I18n.CallHelpers.normalizeDefault = i18nLolcalize;
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
  HtmlSafeString: I18n.HtmlSafeString,

  translate: function() {
    var args = [].slice.call(arguments);
    var options = args[args.length - 1];
    if (!(options instanceof Object)) {
      options = {}
      args.push(options);
    }
    options.scope = this.scope;
    return I18n.translate.apply(I18n, args);
  },
  localize: function(key, date) {
    if (key[0] === '#') key = key.slice(1);
    return I18n.localize(key, date);
  },
  beforeLabel: function(text) {
    return this.t("#before_label_wrapper", "%{text}:", {'text': text});
  },
  lookup:       I18n.lookup.bind(I18n),
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

