define(function(require) {
  var Adapter = require('canvas_quizzes/core/adapter');
  var Backbone = require('canvas_packages/backbone');

  Backbone.ajax = Adapter.request;
});