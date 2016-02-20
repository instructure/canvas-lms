var tz = require("timezone_core");
if (typeof ENV != 'undefined'){
  var reqTz = require.context("./vendor/timezone", true, /.*\.js$/);

  if (ENV && ENV.TIMEZONE) {
    var timezoneData = reqTz("./" + ENV.TIMEZONE + ".js");
    tz.changeZone(timezoneData, ENV.TIMEZONE);
  }
  if (ENV && ENV.CONTEXT_TIMEZONE) {
    var contextTimezoneData = reqTz("./" + ENV.CONTEXT_TIMEZONE + ".js");
    tz.preload(contextTimezoneData, ENV.CONTEXT_TIMEZONE);
  }
  if (ENV && ENV.LOCALE) {
    var localeName = ENV.LOCALE.replace('-', '_');
    var localeData = reqTz("./" + localeName + ".js");
    tz.applyFeature(localeData, localeName);
  }
}
module.exports = tz;
