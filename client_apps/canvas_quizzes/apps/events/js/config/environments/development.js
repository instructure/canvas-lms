define(function(require) {
  var $ = require('canvas_packages/jquery');

  return {
    xhr: {
      timeout: 5000
    },

    pollingFrequency: 500,

    ajax: $.ajax,

    onError: function(message) {
      throw new Error(message);
    }
  };
});
