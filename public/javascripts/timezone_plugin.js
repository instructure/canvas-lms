define({
  load: function(name, req, load, config) {
    req(["timezone_core"], function(tz) {
      if (typeof ENV == 'undefined') {
        load(tz);
      }
      else {
        var promises = [];
        if (ENV && ENV.TIMEZONE) { promises.push(tz.changeZone(ENV.TIMEZONE)); }
        if (ENV && ENV.CONTEXT_TIMEZONE) { promises.push(tz.preload(ENV.CONTEXT_TIMEZONE)); }
        if (ENV && ENV.LOCALE) { promises.push(tz.changeLocale(ENV.LOCALE.replace('-', '_'))); }
        $.when.apply($, promises).then(function() { load(tz); });
      }
    });
  }
});
