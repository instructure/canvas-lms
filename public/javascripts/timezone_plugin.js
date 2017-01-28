define({
  load: function (name, req, load /* , config */) {
    req(['timezone_core'], function (tz) {
      if (typeof ENV === 'undefined') {
        load(tz)
      } else {
        Promise.all([
          ENV.TIMEZONE && tz.changeZone(ENV.TIMEZONE),
          ENV.CONTEXT_TIMEZONE && tz.preload(ENV.CONTEXT_TIMEZONE),
          ENV.BIGEASY_LOCALE && tz.changeLocale(ENV.BIGEASY_LOCALE, ENV.MOMENT_LOCALE)
        ]).then(function () {
          load(tz)
        })
      }
    })
  }
})
