define(function(require) {
  var $ = require('canvas_packages/jquery');

  // We're already logging errors in config/initializers/rsvp.js
  jasmine.RSVP.logRSVPErrors = false;

  return {
    ajax: $.ajax,

    xhr: {
      timeout: 25
    },

    onError: function(message) {
      throw new Error(message);
    }
  };
});
