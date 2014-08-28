define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var QuizReport = require('../models/quiz_report');

  return Backbone.Collection.extend({
    model: QuizReport,
    parse: function(payload) {
      return payload.quiz_reports;
    }
  });
});