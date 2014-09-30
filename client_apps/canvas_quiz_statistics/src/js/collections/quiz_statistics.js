define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var QuizStatistics = require('../models/quiz_statistics');
  var fromJSONAPI = require('../models/common/from_jsonapi');
  var config = require('../config');

  return Backbone.Collection.extend({
    model: QuizStatistics,

    url: function() {
      return config.quizStatisticsUrl;
    },

    parse: function(payload) {
      return fromJSONAPI(payload, 'quiz_statistics');
    }
  });
});