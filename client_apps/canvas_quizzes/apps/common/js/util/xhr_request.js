define(function(require) {
  var RSVP = require('rsvp');
  var successCodes = [ 200, 204 ];

  var parse = function(xhr) {
    var payload;

    if (xhr.responseJSON) {
      return xhr.responseJSON;
    }
    else if ((xhr.responseText || '').length) {
      payload = (xhr.responseText || '').replace('while(1);', '');

      try {
        payload = JSON.parse(payload);
      } catch(e) {
        payload = xhr.responseText;
      }
    }
    else {
      payload = undefined;
    }

    return payload;
  };

  return function xhrRequest(options) {
    var url = options.url;
    var method = options.type || 'GET';
    var async = options.async === undefined ? true : !!options.async;
    var data = options.data;

    return new RSVP.Promise(function(resolve, reject) {
      var xhr = new XMLHttpRequest();

      xhr.onreadystatechange = function() {
        // all is well
        if (xhr.readyState === 4) {
          if (successCodes.indexOf(xhr.status) > -1) {
            resolve(parse(xhr), xhr.status, xhr);
          }
          else {
            reject(parse(xhr), xhr.status, xhr);
          }
        }
      };

      xhr.open(method, url, async);

      if (options.headers) {
        Object.keys(options.headers).forEach(function(header) {
          xhr.setRequestHeader(header, options.headers[header]);
        });
      }

      xhr.send(JSON.stringify(data));
    });
  };
});
