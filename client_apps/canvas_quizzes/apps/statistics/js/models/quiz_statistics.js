define(function(require) {
  var Backbone = require('canvas_packages/backbone');
  var pickAndNormalize = require('canvas_quizzes/models/common/pick_and_normalize');
  var K = require('../constants');
  var _ = require('lodash');
  var wrap = require('canvas_quizzes/util/array_wrap');
  var round = require('canvas_quizzes/util/round');
  var I18n = require('i18n!quiz_statistics');

  var findWhere = _.findWhere;
  var parseQuestion;

  var QuizStatistics = Backbone.Model.extend({
    parse: function(payload) {
      var attrs = pickAndNormalize(payload, K.QUIZ_STATISTICS_ATTRS);

      attrs.submissionStatistics = pickAndNormalize(
        payload.submission_statistics,
        K.SUBMISSION_STATISTICS_ATTRS
      );

      attrs.questionStatistics = wrap(payload.question_statistics).
        map(parseQuestion);

      return attrs;
    }
  });

  // @return {Number}
  //  Count of participants who were presented with this question and provided
  //  any sort of response (even if it's a blank/no response.)
  var calculateParticipantCount = function(question) {
    var answerPool;

    // pick any answer set; they will all have the same response count, only
    // distributed differently:
    if (question.answerSets && question.answerSets.length > 0) {
      answerPool = question.answerSets[0].answers;
    }
    else {
      answerPool = question.answers;
    }
    if (question.questionType === 'multiple_answers_question') {
      return question.responses;  // This will not indicate a response for blank responses
    }
    return wrap(answerPool).reduce(function(sum, answer) {
      return sum + (answer.responses || 0);
    }, 0);
  };

  parseQuestion = function(question) {
    var correctAnswerPointBiserials;
    var attrs = pickAndNormalize(question, K.QUESTION_STATISTICS_ATTRS);
    var participantCount = calculateParticipantCount(attrs);
    var decorateAnswer = function(answer) {
      if (answer.id === 'none') {
        answer.text = I18n.t('no_answer', 'No Answer');
      }
      else if (answer.id === 'other') {
        answer.text = I18n.t('unknown_answer', 'Something Else'); // This is where we need to handle the answer changed thing
      }

      if (participantCount > 0) {
        answer.ratio = round(answer.responses / participantCount * 100.0);
      }
      else {
        answer.ratio = 0;
      }
    };

    // This value along with attrs['responses'] will allow us to display how
    // many students who were presented with this question actually left any
    // response.
    //
    // The only thing worth noting here is that attrs['responses'] denotes the
    // number of students who provided _some_ response. Blanks/no responses do
    // not count in that number!
    attrs.participantCount = participantCount;

    if (attrs.answers) {
      attrs.answers.forEach(decorateAnswer);
    }
    else if (attrs.answerSets) {
      attrs.answerSets.forEach(function(answerSet) {
        wrap(answerSet.answers).forEach(decorateAnswer);
      });
    }

    // Extract the discrimination index from the point biserial record for the
    // correct answer. Applies only to MC/TF questions.
    if (attrs.pointBiserials) {
      attrs.pointBiserials = attrs.pointBiserials.map(function(pointBiserial) {
        return pickAndNormalize(pointBiserial, K.POINT_BISERIAL_ATTRS);
      });

      correctAnswerPointBiserials = findWhere(attrs.pointBiserials, {
        correct: true
      }) || {};

      attrs.discriminationIndex = correctAnswerPointBiserials.pointBiserial;
    }

    // Calculate the score<>student ratio for Essay (and friends) using the
    // score distribution vector so that we can say "X% of students received a
    // score of Y".
    if (attrs.pointDistribution) {
      attrs.pointDistribution.forEach(function(point) {
        if (participantCount > 0) {
          point.ratio = round(point.count / participantCount * 100.0);
        }
        else {
          point.ratio = 0;
        }
      });
    }

    return attrs;
  };

  return QuizStatistics;
});
