/* global launchTests: false */
localStorage.clear();

this.__TESTING__ = true;

require([ 'config/initializer' ], function(initialize) {
  initialize().then(launchTests);
});