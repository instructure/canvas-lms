define((require) => {
  const RSVP = require('rsvp');
  const successCodes = [200, 204];

  const parse = function (xhr) {
    let payload;

    if (xhr.responseJSON) {
      return xhr.responseJSON;
    } else if ((xhr.responseText || '').length) {
      payload = (xhr.responseText || '').replace('while(1);', '');

      try {
        payload = JSON.parse(payload);
      } catch (e) {
        payload = xhr.responseText;
      }
    } else {
      payload = undefined;
    }

    return payload;
  };

  return function xhrRequest (options) {
    const url = options.url;
    const method = options.type || 'GET';
    const async = options.async === undefined ? true : !!options.async;
    const data = options.data;

    return new RSVP.Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();

      xhr.onreadystatechange = function () {
        // all is well
        if (xhr.readyState === 4) {
          if (successCodes.indexOf(xhr.status) > -1) {
            resolve(parse(xhr), xhr.status, xhr);
          } else {
            reject(parse(xhr), xhr.status, xhr);
          }
        }
      };

      xhr.open(method, url, async);

      if (options.headers) {
        Object.keys(options.headers).forEach((header) => {
          xhr.setRequestHeader(header, options.headers[header]);
        });
      }

      xhr.send(JSON.stringify(data));
    });
  };
});
