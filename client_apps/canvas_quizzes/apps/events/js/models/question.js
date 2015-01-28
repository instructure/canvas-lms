define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  var fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  var K = require('../constants');
  var config = require('../config');
  var inflections = require('canvas_quizzes/util/inflections');
  var camelize = inflections.camelize;

  return Backbone.Model.extend({
    parse: function(payload) {
      var attrs;

      attrs = fromJSONAPI(payload, 'quiz_questions', true);
      attrs = pickAndNormalize(attrs, K.QUESTION_ATTRS);
      attrs.id = ''+attrs.id;
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