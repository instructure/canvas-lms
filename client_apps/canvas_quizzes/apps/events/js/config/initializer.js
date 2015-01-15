define(function(require) {
  var RSVP = require('./initializers/rsvp');
  var Backbone = require('./initializers/backbone');

  return function initializeApp() {
    return RSVP.resolve();
  };
});