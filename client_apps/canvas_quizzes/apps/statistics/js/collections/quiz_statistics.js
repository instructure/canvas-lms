define((require) => {
  const Backbone = require('canvas_packages/backbone');
  const QuizStatistics = require('../models/quiz_statistics');
  const fromJSONAPI = require('canvas_quizzes/models/common/from_jsonapi');
  const config = require('../config');

  return Backbone.Collection.extend({
    model: QuizStatistics,

    url () {
      return config.quizStatisticsUrl;
    },

    parse (payload) {
      return fromJSONAPI(payload, 'quiz_statistics');
    }
  });
});
