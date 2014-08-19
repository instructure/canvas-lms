define(function(require) {
  var d3 = require('./initializers/d3');
  var RSVP = require('./initializers/rsvp');
  var Backbone = require('./initializers/backbone');

  return function initializeApp() {
    return RSVP.resolve();
  };
});