// This file has a bad name, it's really a webpack loader, but
// in order to let webpack build everything without changing any of the
// app javascript, we're giving it the name to match the existing
// require statements.

module.exports = function(input){
  throw "Should not ever make it to the actual fullcalendar loader because those resources don't exist";
}


// This adapts the functionality of an old fullcalendar_plugin.js that would load
// the lib with it's languages on board.  We're keeping
// it as a loader for now to avoid changing the existing app javascripts
// while transitioning to webpack
module.exports.pitch = function(remainingRequest, precedingRequest, data) {
  this.cacheable();
  return "" +
    "define([\"bower/fullcalendar/dist/fullcalendar\", \"bower/fullcalendar/dist/lang-all\"], function(fc, lang){\n " +
    "  return fc;\n" +
    "});";
};
