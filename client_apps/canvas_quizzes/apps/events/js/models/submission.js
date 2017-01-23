define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const K = require('../constants');
  const config = require('../config');

  return Backbone.Model.extend({
    url () {
      return config.submissionUrl;
    },

    parse (payload) {
      let attrs;

      attrs = fromJSONAPI(payload, 'quiz_submissions', true);
      attrs = pickAndNormalize(attrs, K.SUBMISSION_ATTRS);

      return attrs;
    }
  });
});
