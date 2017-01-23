define((require) => {
  const $ = require('canvas_packages/jquery');

  return {
    xhr: {
      timeout: 5000
    },

    pollingFrequency: 500,

    ajax: $.ajax,

    onError (message) {
      throw new Error(message);
    }
  };
});
