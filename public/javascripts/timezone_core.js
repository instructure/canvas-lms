define([
  "jquery",
  "underscore",
  "require",
  "vendor/timezone"
], function($, _, require, tz) {
  // start with the bare vendor-provided tz() function
  var _tz = tz;
  var _preloadedData = {};

  // wrap it up in a set of methods that will always call the most up-to-date
  // version. each method is intended to act as a subset of bigeasy's generic
  // tz() functionality.
  tz = {
    // parses a date value (string, integer, Date, date array, etc. -- see
    // bigeasy's tz() docs). returns null on parse failure. otherwise returns a
    // Date (rather than _tz()'s timestamp integer) because, when treated
    // correctly, they are interchangeable but the Date is more convenient.
    // note that tz('') will return null, rather than the epoch start that
    // _tz('') returns.
    parse: function(value) {
      // don't parse '' as 0, don't bother trying with null. but *do* accept 0
      // as a value.
      if (value === '' || value == null) return null;

      // try and parse the value. if it succeeds, _tz() will return a timestamp
      // integer. otherwise, it'll assume we mean to curry and give back a
      // (non-integer) function.
      var timestamp = _tz(value);
      if (typeof timestamp !== 'number') return null;
      return new Date(timestamp);
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
      return _tz;
    },

    restore: function(snapshot) {
      // we can't actually check that the snapshot is an appropriate function,
      // but we can at least verify it's a function.
      if (typeof snapshot !== 'function') throw 'invalid tz() snapshot';
      _tz = snapshot;
    },

    extendConfiguration: function() {
      var extended = _tz.apply(null, arguments);
      if (typeof extended !== 'function') throw 'invalid tz() extension';
      _tz = extended;
    },

    // apply a "feature" to tz (NOTE: persistent and shared). the provided
    // feature can be a chunk of previously loaded data, which is applied
    // immediately, or the name of a data file to load and then apply
    // asynchronously.
    applyFeature: function(data, name) {
      var promise = $.Deferred();
      if (arguments.length > 1) {
        this.preload(name, data);
        tz.extendConfiguration(data, name);
        promise.resolve();
        return promise;
      }

      name = data;
      this.preload(name).then(function(preloadedData){
        tz.extendConfiguration(preloadedData, name);
        promise.resolve();
      });

      return promise;
    },

    // preload a specific data file without having to actually
    // change the timezone to do it. Future "applyFeature" calls
    // will apply synchronously if their data is already preloaded.
    preload: function(name, data) {
      var promise = $.Deferred();
      if (arguments.length > 1){
        _preloadedData[name] = data;
        promise.resolve(data);
      } else if(_preloadedData[name]){
        promise.resolve(_preloadedData[name]);
      } else {
        require(["vendor/timezone/" + name], function(data){
          _preloadedData[name] = data;
          promise.resolve(data);
        });
      }
      return promise;
    }
  };

  // changing zone and locale are just aliases for applying a feature
  tz.changeZone = tz.changeLocale = tz.applyFeature;

  return tz;
});
