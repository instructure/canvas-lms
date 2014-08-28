define(function(require) {
  var Adapter = require('../../core/adapter');
  var Backbone = require('canvas_packages/backbone');

  Backbone.ajax = Adapter.request;
});