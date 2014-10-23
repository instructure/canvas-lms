define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('./common/pick_and_normalize');
  var K = require('../constants');
  var _ = require('lodash');
  var wrap = require('../util/array_wrap');
  var round = require('../util/round');
  var I18n = require('i18n!quiz_statistics');

  var findWhere = _.findWhere;
  var parseQuestion, decorateAnswer, decorateAnswerSet;

  var QuizStatistics = Backbone.Model.extend({
    parse: function(payload) {
      var attrs = {};
      var participantCount;

      attrs = pickAndNormalize(payload, K.QUIZ_STATISTICS_ATTRS);

      attrs.submissionStatistics = pickAndNormalize(
        payload.submission_statistics,
        K.SUBMISSION_STATISTICS_ATTRS
      );

      participantCount = attrs.submissionStatistics.uniqueCount;

      attrs.questionStatistics = wrap(payload.question_statistics)
        .map(parseQuestion.bind(null, participantCount));

      return attrs;
    },
  });

  parseQuestion = function(participantCount, question) {
    var attrs = pickAndNormalize(question, K.QUESTION_STATISTICS_ATTRS);
    var correctAnswerPointBiserials;

    wrap(attrs.answers).forEach(decorateAnswer.bind(null, participantCount));
    wrap(attrs.answerSets).forEach(decorateAnswerSet.bind(null, participantCount));

    if (attrs.pointBiserials) {
      attrs.pointBiserials = attrs.pointBiserials.map(function(pointBiserial) {
        return pickAndNormalize(pointBiserial, K.POINT_BISERIAL_ATTRS);
      });

      correctAnswerPointBiserials = findWhere(attrs.pointBiserials, {
        correct: true
      }) || {};

      attrs.discriminationIndex = correctAnswerPointBiserials.pointBiserial;
    }

    if (attrs.pointDistribution) {
      attrs.pointDistribution.forEach(function(point) {
        if (participantCount <= 0) {
          point.ratio = 0;
        }
        else {
          point.ratio = round(point.count / participantCount * 100.0);
        }
      });
    }

    return attrs;
  };

  decorateAnswer = function(participantCount, answer) {
    answer.ratio = participantCount > 0 ?
      round(answer.responses / participantCount * 100) :
      0;

    if (answer.id === 'none') {
      answer.text = I18n.t('no_answer', 'No Answer');
    } else if (answer.id === 'other') {
      answer.text = I18n.t('unknown_answer', 'Something Else');
    }
  };

  decorateAnswerSet = function(participantCount, answerSet) {
    wrap(answerSet.answers).forEach(decorateAnswer.bind(null, participantCount));
  };

  return QuizStatistics;
});
