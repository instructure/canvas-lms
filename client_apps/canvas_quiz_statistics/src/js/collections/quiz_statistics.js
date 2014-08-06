define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var QuizStatistics = require('../models/quiz_statistics');

  return Backbone.Collection.extend({
    model: QuizStatistics,
    parse: function(payload) {
      return payload.quiz_statistics;
    }
  });
});