define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('./common/pick_and_normalize');
  var K = require('../constants');

  return Backbone.Model.extend({
    parse: function(payload) {
      var attrs = pickAndNormalize(payload, K.QUIZ_REPORT_ATTRS);

      attrs.progress = pickAndNormalize(payload.progress, K.PROGRESS_ATTRS);
      attrs.file = pickAndNormalize(payload.file, K.ATTACHMENT_ATTRS);

      return attrs;
    }
  });
});