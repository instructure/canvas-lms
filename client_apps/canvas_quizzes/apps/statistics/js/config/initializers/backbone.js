define((require) => {
  const config = require('../../config');
  const CoreAdapter = require('canvas_quizzes/core/adapter');
  const Adapter = new CoreAdapter(config);
  const Backbone = require('canvas_packages/backbone');

  Backbone.ajax = function (options) {
    return Adapter.request(options);
  };
});
