define(function(require) {
  var config = require('../../config');
  var CoreAdapter = require('canvas_quizzes/core/adapter');
  var Adapter = new CoreAdapter(config);
  var Backbone = require('canvas_packages/backbone');

  Backbone.ajax = function(options){
    return Adapter.request(options);
  };
});
