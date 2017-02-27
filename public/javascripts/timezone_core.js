define([
  "jquery",
  "underscore",
  "require",
  "timezone/index",
  "i18nObj",
  "moment",
  "moment_formats"
], function($, _, require, _tz, I18n, moment, MomentFormats) {
  // start with the bare vendor-provided tz() function
  var currentLocale = "en_US" // default to US locale
  var momentLocale = "en"
  var _preloadedData = window.__PRELOADED_TIMEZONE_DATA__ || (window.__PRELOADED_TIMEZONE_DATA__ = {});

  // wrap it up in a set of methods that will always call the most up-to-date
  // version. each method is intended to act as a subset of bigeasy's generic
  // tz() functionality.
  var tz = {

    _preloadedData: _preloadedData,

    // wrap's moment() for parsing datetime strings. assumes the string to be
    // parsed is in the profile timezone unless if contains an offset string
    // *and* a format token to parse it, and unfudges the result.
    moment: function (input, format) {
      // ensure first argument is a string and second is a format or an array
      // of formats
      if (!_.isString(input) || !(_.isString(format) || _.isArray(format)))
        throw new Error("tz.moment only works on string+format(s). just use " +
                        "moment() directly for any other signature");

      // call out to moment, leaving the result alone if invalid
      var m = moment.apply(null, [input, format, momentLocale]);
      if (m._pf.unusedTokens.length > 0) {
        // we didn't use strict at first, because we want to accept when
        // there's unused input as long as we're using all tokens. but if the
        // best non-strict match has unused tokens, reparse with strict
        m = moment.apply(null, [input, format, momentLocale, true]);
      }
      if (!m.isValid()) return m;

      // unfudge the result unless an offset was both specified and used in the
      // parsed string.
      //
      // using moment internals here because I can't come up with any better
      // reliable way to test for this :( fortunately, both _f and
      // _pf.unusedTokens are always set as long as format is explicitly
      // specified as either a string or array (which we've already checked
      // for).
      //
      // _f lacking a 'Z' indicates that no offset token was specified in the
      // format string used in parsing. we check this instead of just format in
      // case format is an array, of which one contains a Z and the other
      // doesn't, and we don't know until after parsing which format would best
      // match the input.
      //
      // _pf.unusedTokens having a 'Z' token indicates that even though the
      // format used contained a 'Z' token (since the first condition wasn't
      // false), that token was not used during parsing; i.e. the input string
      // didn't provide a value for it.
      //
      if (!m._f.match(/Z/) || m._pf.unusedTokens.indexOf('Z') >= 0) {
        var l = m.locale();
        m = moment(tz.raw_parse(m.locale('en').format('YYYY-MM-DD HH:mm:ss')));
        m.locale(l);
      }

      return m;
    },

    // interprets a date value (string, integer, Date, date array, etc. -- see
    // bigeasy's tz() docs) according to _tz. returns null on parse failure.
    // otherwise returns a Date (rather than _tz()'s timestamp integer)
    // because, when treated correctly, they are interchangeable but the Date
    // is more convenient.
    raw_parse: function(value) {
      var timestamp = _tz(value);
      if (typeof timestamp === 'number') {
        return new Date(timestamp);
      }
      return null;
    },

    // parses a date value but more robustly. returns null on parse failure. if
    // the value is a string but does not look like an ISO8601 string
    // (loosely), or otherwise fails to be interpreted by raw_parse(), then
    // parsing will be attempted with tz.moment() according to the formats
    // defined in MomentFormats.getFormats(). also note that raw_parse('') will
    // return the epoch, but parse('') will return null.
    parse: function(value) {
      // hard code '' and null as unparseable
      if (value === '' || value == null) return null;

      if (!_.isString(value)) {
        // try and understand the value through _tz. if it doesn't work, we
        // don't know what else to do with it as a non-string
        return tz.raw_parse(value);
      }

      // only try _tz with strings looking loosely like an ISO8601 value. in
      // particular, we want to avoid parsing e.g. '2016' as 2,016 milliseconds
      // since the epoch
      if (value.match(/[-:]/)) {
        var result = tz.raw_parse(value);
        if (result) return result;
      }

      // _tz parsing failed or skipped. try moment parsing
      var formats = MomentFormats.getFormats()
      var cleanValue = this.removeUnwantedChars(value)
      var m = tz.moment(cleanValue, formats)
      return m.isValid() ? m.toDate() : null
    },

    removeUnwantedChars: function(value){
      return _.isString(value) ?
        value.replace(".","") :
        value
    },

    // format a date value (parsing it if necessary). returns null for parse
    // failure on the value or an unrecognized format string.
    format: function(value, format, otherZone) {
      var localTz = _tz;
      var usingOtherZone = (arguments.length == 3 && otherZone)
      if(usingOtherZone){
        if(!(otherZone in _preloadedData)) return null;
        localTz = _tz(_preloadedData[otherZone]);
      }
      // make sure we have a good value first
      var datetime = tz.parse(value);
      if (datetime == null) return null;

      // translate recognized 'date.formats.*' and 'time.formats.*' to
      // appropriate format strings according to locale.
      if (format.match(/^(date|time)\.formats\./)) {
        var locale_format = I18n.lookup(format);
        if (locale_format) {
          // in the process, turn %l, %k, and %e into %-l, %-k, and %-e
          // (respectively) to avoid extra unnecessary space characters
          //
          // javascript doesn't have lookbehind, so do the fixing on the reversed
          // string so we can use lookahead instead. the funky '(%%)*(?!%)' pattern
          // in all the regexes is to make sure we match (once unreversed), e.g.,
          // both %l and %%%l (literal-% + %l) but not %%l (literal-% + l).
          format = locale_format.
            split("").reverse().join("").
            replace(/([lke])(?=%(%%)*(?!%))/, '$1-').
            split("").reverse().join("");
        }
      }

      // some locales may not (according to bigeasy's localization files) use
      // an am/pm distinction, but could then be incorrectly used with 12-hour
      // format strings (e.g. %l:%M%P), whether by erroneous format strings in
      // canvas' localization files or by unlocalized format strings. as a
      // result, you might get 3am and 3pm both formatting to the same value.
      // to prevent this, 12-hour indicators with an am/pm indicator should be
      // promoted to the equivalent 24-hour indicator when the locale defines
      // %P as an empty string. ("reverse, look-ahead, reverse" pattern for
      // same reason as above)
      format = format.split("").reverse().join("");
      if (!tz.hasMeridian() &&
          ((format.match(/[lI][-_]?%(%%)*(?!%)/) &&
            format.match(/p%(%%)*(?!%)/i)) ||
           format.match(/r[-_]?%(%%)*(?!%)/))) {
        format = format.replace(/l(?=[-_]?%(%%)*(?!%))/, 'k');
        format = format.replace(/I(?=[-_]?%(%%)*(?!%))/, 'H');
        format = format.replace(/r(?=[-_]?%(%%)*(?!%))/, 'T');
      }
      format = format.split("").reverse().join("");

      // try and apply the format string to the datetime. if it succeeds, we'll
      // get a string; otherwise we'll get the (non-string) date back.
      var formatted = null;
      if (usingOtherZone){
        formatted = localTz(datetime, format, otherZone);
      } else {
        formatted = localTz(datetime, format);
      }

      if (typeof formatted !== 'string') return null;
      return formatted;
    },

    hasMeridian: function() {
      return _tz(new Date(), '%P') !== '';
    },

    useMeridian: function() {
      if (!this.hasMeridian()) return false;
      var tiny = I18n.lookup('time.formats.tiny');
      return tiny && tiny.match(/%-?l/);
    },

    // apply any number of non-format directives to the value (parsing it if
    // necessary). return null for parse failure on the value or if one of the
    // directives was mistakenly a format string. returns the modified Date
    // otherwise. typical directives will be for date math, e.g. '-3 days'.
    // non-format unrecognized directives are ignored.
    shift: function(value) {
      // make sure we have a good value first
      var datetime = tz.parse(value);
      if (datetime == null) return null;

      // no application strings given? just regurgitate the input (though
      // parsed now).
      if (arguments.length == 1) return datetime;

      // try and apply the directives to the datetime. if one was a format
      // string (unacceptable) we'll get a (non-integer) string back.
      // otherwise, we'll get a new timestamp integer back (even if some
      // unrecognized non-format applications were ignored).
      var args = [datetime].concat([].slice.apply(arguments, [1]))
      var timestamp = _tz.apply(null, args);
      if (typeof timestamp !== 'number') return null;
      return new Date(timestamp);
    },

    // allow snapshotting and restoration, and extending through the
    // vendor-provided tz()'s functional composition
    snapshot: function() {
      return [_tz, currentLocale, momentLocale];
    },

    restore: function(snapshot) {
      // we can't actually check that the snapshot has appropriate values, but
      // we can at least verify the shape of [function, string, string]
      if (!_.isArray(snapshot)) throw new Error('invalid tz() snapshot');
      if (typeof snapshot[0] !== 'function') throw new Error('invalid tz() snapshot');
      if (!_.isString(snapshot[1])) throw new Error('invalid tz() snapshot');
      if (!_.isString(snapshot[2])) throw new Error('invalid tz() snapshot');
      _tz = snapshot[0];
      currentLocale = snapshot[1];
      momentLocale = snapshot[2];
    },

    extendConfiguration: function() {
      var extended = _tz.apply(null, arguments);
      if (typeof extended !== 'function') throw new Error('invalid tz() extension');
      _tz = extended;
    },

    // apply a "feature" to tz (NOTE: persistent and shared). the provided
    // feature can be a chunk of previously loaded data, which is applied
    // immediately, or the name of a data file to load and then apply
    // asynchronously.
    applyFeature: function (data, name) {
      function extendConfig (preloadedData) {
        tz.extendConfiguration(preloadedData, name);
        return Promise.resolve();
      }
      if (arguments.length > 1) {
        this.preload(name, data);
        return extendConfig(data);
      }

      name = data;
      var preloadedData = this.preload(name);
      if (preloadedData instanceof Promise) {
        return preloadedData.then(extendConfig);
      }
      return extendConfig(preloadedData);
    },

    // preload a specific data file without having to actually
    // change the timezone to do it. Future "applyFeature" calls
    // will apply synchronously if their data is already preloaded.
    preload: function (name, data) {
      if (arguments.length > 1) {
        _preloadedData[name] = data;
        return _preloadedData[name];
      } else if (_preloadedData[name]) {
        return _preloadedData[name];
      } else {
        return new Promise(function(resolve, reject){
          if (window.USE_WEBPACK) {
            return reject(
              new Error('In webpack, loading timezones on-demand is not supported. "' +
                        name + '" should already be script tagged onto the page from Rails.')
            )
          } else {
            require(['timezone/' + name], function (timezoneData){
              _preloadedData[name] = timezoneData;
              resolve(timezoneData);
            });
          }
        });
      }
    },

    changeLocale: function () {
      if (arguments.length > 2) {
        currentLocale = arguments[1];
        momentLocale = arguments[2];
      } else {
        currentLocale = arguments[0];
        momentLocale = arguments[1];
      };
      // take off the momentLocale before passing up the chain
      var args = [].slice.apply(arguments).slice(0, arguments.length - 1);
      return this.applyFeature.apply(this, args);
    },

    isMidnight: function(date){
      if (date == null) { return false };
      return tz.format(date, '%R') == '00:00';
    },

    changeToTheSecondBeforeMidnight: function(date){
      return tz.parse(tz.format(date, "%F 23:59:59"));
    },

    // finds the given time of day on the given date ignoring dst conversion and such.
    // e.g. if time is 2016-05-20 14:00:00 and date is 2016-03-17 23:59:59, the result will
    // be 2016-03-17 14:00:00
    mergeTimeAndDate: function(time, date) {
      return tz.parse(tz.format(date, '%F ') + tz.format(time, '%T'));
    }
  };

  // changing zone and locale are just aliases for applying a feature
  tz.changeZone = tz.applyFeature;

  return tz;
});
