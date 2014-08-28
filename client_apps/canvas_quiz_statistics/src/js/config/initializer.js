define(function(require) {
  var d3 = require('./initializers/d3');
  var RSVP = require('./initializers/rsvp');

  return function initializeApp() {
    return RSVP.resolve();
  };
});