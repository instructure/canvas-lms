define(function(require) {
  var rawAjax = require('../util/xhr_request');
  var config = require('../config');
  var RSVP = require('rsvp');

  var Adapter = {
    request: function(options) {
      var ajax = config.ajax || rawAjax;

      options.headers = options.headers || {};
      options.headers['Content-Type'] = 'application/json';
      options.headers.Accept = 'application/vnd.api+json';

      if (config.apiToken) {
        options.headers.Authorization = 'Bearer ' + config.apiToken;
      }

      if (options.type !== 'GET' && options.data) {
        options.data = JSON.stringify(options.data);
      }

      //>>excludeStart("production", pragmas.production);
      if (config.fakeXHRDelay) {
        var svc = RSVP.defer();

        setTimeout(function() {
          RSVP.Promise.cast(ajax(options)).then(svc.resolve, svc.reject);
        }, config.fakeXHRDelay);

        return svc.promise;
      }
      //>>excludeEnd("production");

      return RSVP.Promise.cast(ajax(options));
    }
  };

  return Adapter;
});