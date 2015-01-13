// Helper for use with sinon.server.respondWith() to save you from:
//
//   - JSON.stringifying() the body
//   - adding JSON response Content-Type headers
//   - remembering whether headers or body go first!
//
this.xhrResponse = function(statusCode, body, headers) {
  if (!headers) {
    headers = {};
  }

  if (!headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }

  return [ statusCode, headers, JSON.stringify(body) ];
};