define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const K = require('../constants');
  const config = require('../config');
  const inflections = require('canvas_quizzes/util/inflections');
  const camelize = inflections.camelize;

  return Backbone.Model.extend({
    parse (payload) {
      let attrs;

      attrs = fromJSONAPI(payload, 'quiz_questions', true);
      attrs = pickAndNormalize(attrs, K.QUESTION_ATTRS);
      attrs.id = `${attrs.id}`;
      attrs.readableType = camelize(
        attrs.questionType
          .replace(/_question$/, '')
          .replace(/_/g, ' '),
        false
      );

      return attrs;
    }
  });
});
