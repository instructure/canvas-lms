define(['../../node_modules/axios'], function (axios) {
  // Add CSRF stuffs to make Canvas happy when we are making requests with axios
  axios.defaults.xsrfCookieName = '_csrf_token';
  axios.defaults.xsrfHeaderName = 'X-CSRF-Token';

  return axios;
});
