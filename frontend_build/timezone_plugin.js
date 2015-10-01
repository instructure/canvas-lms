// This file has a bad name, it's really a webpack loader, but
// in order to let webpack build everything without changing any of the
// app javascript, we're giving it the name to match the existing
// require statements.

module.exports = function(input){
  throw "Should not ever make it to the actual timezone loader because those resources don't exist";
}


// This adapts the functionality of an old timezone_plugin.js that would load
// in items off the env before loading timezone_core.  We're keeping
// it as a loader for now to avoid changing the existing app javascripts
// while transitioning to webpack
module.exports.pitch = function(remainingRequest, precedingRequest, data) {
  this.cacheable();
  // TODO: don't return tz until after all the promises have run
  return "" +
    "define([\"jquery\", \"timezone_core\"], function($, tz) {\n" +
    "  if (typeof ENV == 'undefined') {\n" +
    "    return tz;\n" +
    "  } else { \n" +
    "    var promises = [];\n" +
    "    if (ENV && ENV.TIMEZONE) { promises.push(tz.changeZone(ENV.TIMEZONE)); }\n" +
    "    if (ENV && ENV.CONTEXT_TIMEZONE) { promises.push(tz.preload(ENV.CONTEXT_TIMEZONE)); }\n" +
    "    if (ENV && ENV.LOCALE) { promises.push(tz.changeLocale(ENV.LOCALE.replace('-', '_'))); }\n" +
    "    var loadedTz = null;\n" +
    "    $.when.apply($, promises).then(function(){ loadedTz = tz; });\n" +
    "    return tz;\n" +
    "  }\n" +
    "});";
};
