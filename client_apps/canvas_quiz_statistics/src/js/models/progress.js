define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('./common/pick_and_normalize');
  var K = require('../constants');

  return Backbone.Model.extend({
    url: function() {
      return this.get('url');
    },

    parse: function(payload) {
      return pickAndNormalize(payload, K.PROGRESS_ATTRS);
    },
  });
});