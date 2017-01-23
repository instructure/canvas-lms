define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const K = require('../constants');

  const QuizSubmissionEvent = Backbone.Model.extend({
    parse (payload) {
      let attrs;

      attrs = fromJSONAPI(payload, 'quiz_submission_events', true);
      attrs = pickAndNormalize(attrs, K.EVENT_ATTRS);
      attrs.type = attrs.eventType;
      attrs.data = attrs.eventData;

      delete attrs.eventType;
      delete attrs.eventData;

      if (attrs.type === K.EVT_QUESTION_ANSWERED) {
        attrs.data = attrs.data.map(record => pickAndNormalize(record, K.EVENT_DATA_ATTRS));
      }

      if (attrs.type === K.EVT_PAGE_BLURRED) {
        attrs.flag = K.EVT_FLAG_WARNING;
      } else if (attrs.type === K.EVT_PAGE_FOCUSED) {
        attrs.flag = K.EVT_FLAG_OK;
      }

      return attrs;
    },
  });

  return QuizSubmissionEvent;
});
