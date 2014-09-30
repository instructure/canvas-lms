/* global launchTests: false */
localStorage.clear();

require([ 'config/initializer' ], function(initialize) {
  initialize().then(launchTests);
});