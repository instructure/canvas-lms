define(['bower/axios/dist/axios'], function (axios) {
  // Here we define some interceptors for requests to make Canvas happy when
  // we are making requests with axios

  // Add CSRF stuffs
  axios.interceptors.request.use(function (config) {
    // If the config already has one, use it.
    config.xsrfCookieName = config.xsrfCookieName || '_csrf_token';
    config.xsrfHeaderName = config.xsrfHeaderName || 'X-CSRF-Token';

    return config;
  });

  return axios;
});
