define(function(require) {
  var rawAjax = require('../util/xhr_request');
  var config = require('../config');
  var RSVP = require('rsvp');

  var Adapter = {
    request: function(options) {
      var ajax = config.ajax || rawAjax;

      options.headers = options.headers || {};
      options.headers['Content-Type'] = 'application/json';
      options.headers['Accept'] = 'application/vnd.api+json';

      if (config.apiToken) {
        options.headers.Authorization = 'Bearer ' + config.apiToken;
      }

      return RSVP.Promise.cast(ajax(options));
    }
  };

  return Adapter;
});