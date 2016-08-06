var tz = require("timezone_core");
if (typeof ENV != 'undefined'){
  var reqTz = require.context("./vendor/timezone", true, /.*\.js$/);

  if (ENV && ENV.TIMEZONE) {
    var timezoneData = reqTz("./" + ENV.TIMEZONE + ".js");
    tz.changeZone(timezoneData, ENV.TIMEZONE);
  }
  if (ENV && ENV.CONTEXT_TIMEZONE) {
    var contextTimezoneData = reqTz("./" + ENV.CONTEXT_TIMEZONE + ".js");
    tz.preload(ENV.CONTEXT_TIMEZONE, contextTimezoneData);
  }
  if (ENV && ENV.BIGEASY_LOCALE) {
    var localeData = reqTz("./" + ENV.BIGEASY_LOCALE + ".js");
    tz.applyFeature(localeData, ENV.BIGEASY_LOCALE);
  }
}
module.exports = tz;
