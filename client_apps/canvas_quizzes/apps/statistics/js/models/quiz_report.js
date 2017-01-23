define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  const K = require('../constants');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const isGenerating = function (report) {
    const workflowState = report.progress.workflowState;
    return ['queued', 'running'].indexOf(workflowState) > -1;
  };

  return Backbone.Model.extend({
    parse (payload) {
      let attrs;

      payload = fromJSONAPI(payload, 'quiz_reports', true);
      attrs = pickAndNormalize(payload, K.QUIZ_REPORT_ATTRS);

      attrs.progress = pickAndNormalize(payload.progress, K.PROGRESS_ATTRS);
      attrs.file = pickAndNormalize(payload.file, K.ATTACHMENT_ATTRS);
      attrs.isGenerated = !!(attrs.file && attrs.file.url);
      attrs.isGenerating = !attrs.isGenerated && !!(attrs.progress && isGenerating(attrs));

      return attrs;
    }
  });
});
