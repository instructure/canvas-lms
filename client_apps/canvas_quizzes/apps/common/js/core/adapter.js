define((require) => {
  const rawAjax = require('../util/xhr_request');
  const RSVP = require('rsvp');

  const Adapter = function (inputConfig) {
    this.config = inputConfig;
  };

  Adapter.prototype.request = function (options) {
    const ajax = this.config.ajax || rawAjax;

    options.headers = options.headers || {};
    options.headers['Content-Type'] = 'application/json';
    options.headers.Accept = 'application/vnd.api+json';

    if (this.config.apiToken) {
      options.headers.Authorization = `Bearer ${this.config.apiToken}`;
    }

    if (options.type !== 'GET' && options.data) {
      options.data = JSON.stringify(options.data);
    }

    // >>excludeStart("production", pragmas.production);
    if (this.config.fakeXHRDelay) {
      const svc = RSVP.defer();

      setTimeout(() => {
        RSVP.Promise.cast(ajax(options)).then(svc.resolve, svc.reject);
      }, this.config.fakeXHRDelay);

      return svc.promise;
    }
    // >>excludeEnd("production");

    return RSVP.Promise.cast(ajax(options));
  }

  return Adapter;
});
