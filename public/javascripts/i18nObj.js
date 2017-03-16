define([
  'vendor/i18n_js_extension',
  'jquery',
  'underscore',
  'str/htmlEscape',
  'compiled/str/i18nLolcalize',
  'vendor/date' /* Date.parse, Date.UTC */
], function(I18n, $, _, htmlEscape, i18nLolcalize) {

/*
 * Overridden interpolator that localizes any interpolated numbers.
 * Defaults to localizeNumber behavior (precision 9, but strips
 * insignificant digits). If you want a different format, do it
 * before you interpolate.
 */
var interpolate = I18n.interpolate;
I18n.interpolate = function(message, origOptions) {
  var options = $.extend(true, {}, origOptions);
  var matches = message.match(this.PLACEHOLDER) || [];

  var placeholder, name;

  for (var i = 0; placeholder = matches[i]; i++) {
    name = placeholder.replace(this.PLACEHOLDER, '$1');
    if (typeof options[name] === 'number') {
      options[name] = this.localizeNumber(options[name]);
    }
  }
  return interpolate.call(this, message, options);
};

I18n.locale = document.documentElement.getAttribute('lang');

I18n.lookup = function(scope, options) {
  var translations = this.prepareOptions(I18n.translations);
  var locales = I18n.getLocaleAndFallbacks(I18n.currentLocale());
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

I18n.getLocaleAndFallbacks = function(locale) {
  if (!I18n.fallbacksMap) {
    I18n.fallbacksMap = I18n.computeFallbacks();
  }
  return (I18n.fallbacksMap[locale] || [I18n.defaultLocale]).slice();
};

I18n.computeFallbacks = function() {
  var map = {};
  Object.keys(I18n.translations).forEach(function(locale) {
    var locales = [];
    var parts = locale.split(/-/);
    for (var i = parts.length; i > 0; i--) {
      var candidateLocale = parts.slice(0, i).join("-");
      if (candidateLocale in I18n.translations) {
        locales.push(candidateLocale);
      }
    }
    if (locales.indexOf(I18n.defaultLocale) === -1) {
      locales.push(I18n.defaultLocale);
    }
    map[locale] = locales;
  });
  return map;
};

var _localize = I18n.localize;
I18n.localize = function(scope, value) {
  var result = _localize.call(this, scope, value);
  if (scope.match(/^(date|time)/))
    result = result.replace(/\s{2,}/, ' ');
  return result;
}

I18n.localizeNumber = function (value, options) {
  if (options == null) {
    options = {}
  }
  var format = _.extend({}, I18n.lookup('number.format'), {
    // use a high precision and strip zeros if no precision is provided
    // 5 is as high as we want to go without causing precision issues
    // when used with toFixed() and large numbers
    strip_insignificant_zeros: options.strip_insignificant_zeros || options.precision == null,
    precision: options.precision != null ? options.precision : 5
  })
  var method = options.percentage ? 'toPercentage' : 'toNumber'
  return I18n[method](value, format)
}
I18n.n = I18n.localizeNumber

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

// like the original, except it formats count
I18n.pluralize = function(count, scope, options) {
  var translation;

  try {
    translation = this.lookup(scope, options);
  } catch (error) {}

  if (!translation) {
    return this.missingTranslation(scope);
  }

  var message;
  options = this.prepareOptions(options, {precision: 0});
  options.count = this.localizeNumber(count, options);

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

I18n.Utils.HtmlSafeString = htmlEscape.SafeString; // this is what we use elsewhere in canvas, so make i18nliner use it too
I18n.CallHelpers.keyPattern = /^\#?\w+(\.\w+)+$/ // handle our absolute keys

// when inferring the key at runtime (i.e. js/coffee or inline hbs `t`
// call), signal to normalizeKey that it shouldn't be scoped.
// TODO: make i18nliner-js set i18n_inferred_key, which will DRY things up
// slightly
var origInferKey = I18n.CallHelpers.inferKey;
I18n.CallHelpers.inferKey = function() {
  return "#" + origInferKey.apply(this, arguments);
};

I18n.CallHelpers.normalizeKey = function(key, options) {
  if (key[0] === '#') {
    key = key.slice(1);
    delete options.scope;
  }
  return key;
};

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
  toPercentage: I18n.toPercentage.bind(I18n),
  localizeNumber: I18n.n.bind(I18n),
  currentLocale: I18n.currentLocale.bind(I18n)
};
I18n.scope.prototype.t = I18n.scope.prototype.translate;
I18n.scope.prototype.l = I18n.scope.prototype.localize;
I18n.scope.prototype.n = I18n.scope.prototype.localizeNumber;
I18n.scope.prototype.p = I18n.scope.prototype.pluralize;

if (I18n.translations) {
  $.extend(true, I18n.translations, {en: {}});
} else {
  I18n.translations = {en: {}};
}

return I18n;

});
