/* jshint node:true */

var K = require('./constants');
var config;

/**
 * Extract the r.js config we use in development, which includes paths and maps
 * that we will need for building.
 *
 * Note that that script expects a browser/rjs runtime environment as it calls
 * requirejs.config() so we have to hack around it.
 *
 * See /config/requirejs/development.js
 *
 * @return {Object}
 *         Object passed to requirejs.config() in that file.
 */
module.exports = function() {
  var noConflict = global.requirejs;

  if (config) { // cache
    return config;
  }

  global.requirejs = {
    config: function(inConfig) {
      config = inConfig;
    }
  };

  K.require('config/requirejs/development');

  global.requirejs = noConflict;

  return config;
};