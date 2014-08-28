define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('./common/pick_and_normalize');
  var K = require('../constants');
  var fromJSONAPI = require('./common/from_jsonapi');
  var isGenerating = function(report) {
    var workflowState = report.progress.workflowState;
    return [ 'queued', 'running' ].indexOf(workflowState) > -1;
  };

  return Backbone.Model.extend({
    parse: function(payload) {
      var attrs;

      payload = fromJSONAPI(payload, 'quiz_reports', true);
      attrs = pickAndNormalize(payload, K.QUIZ_REPORT_ATTRS);

      attrs.progress = pickAndNormalize(payload.progress, K.PROGRESS_ATTRS);
      attrs.file = pickAndNormalize(payload.file, K.ATTACHMENT_ATTRS);
      attrs.isGenerated = !!(attrs.file && attrs.file.url);
      attrs.isGenerating = !!(attrs.progress && isGenerating(attrs));

      return attrs;
    }
  });
});