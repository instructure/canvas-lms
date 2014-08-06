define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('./common/pick_and_normalize');
  var K = require('../constants');
  var _ = require('lodash');
  var wrap = require('../util/array_wrap');
  var findWhere = _.findWhere;

  var QuizStatistics = Backbone.Model.extend({
    parse: function(payload) {
      var attrs = {};

      attrs = pickAndNormalize(payload, K.QUIZ_STATISTICS_ATTRS);

      attrs.submissionStatistics = pickAndNormalize(
        payload.submission_statistics,
        K.SUBMISSION_STATISTICS_ATTRS
      );

      attrs.questionStatistics = wrap(payload.question_statistics).map(function(questionStatistics) {
        var attrs = pickAndNormalize(
          questionStatistics,
          K.QUESTION_STATISTICS_ATTRS
        );

        if (attrs.pointBiserials) {
          attrs.pointBiserials = attrs.pointBiserials.map(function(pointBiserial) {
            return pickAndNormalize(pointBiserial, K.POINT_BISERIAL_ATTRS);
          });

          attrs.discriminationIndex = findWhere(attrs.pointBiserials, {
            correct: true
          }).pointBiserial;
        }

        return attrs;
      });

      return attrs;
    }
  });

  return QuizStatistics;
});