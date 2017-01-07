define(['../../node_modules/axios'], function (axios) {
  // Add CSRF stuffs to make Canvas happy when we are making requests with axios
  axios.defaults.xsrfCookieName = '_csrf_token';
  axios.defaults.xsrfHeaderName = 'X-CSRF-Token';

  // Handle stringified IDs for JSON responses
  var originalDefaults = axios.defaults.headers.common['Accept'];
  axios.defaults.headers.common['Accept'] = 'application/json+canvas-string-ids, ' + originalDefaults;

  return axios;
});
