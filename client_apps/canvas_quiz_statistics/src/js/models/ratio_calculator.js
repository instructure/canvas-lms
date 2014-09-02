define(function(require) {
  var _ = require('lodash');
  var extend = _.extend;

  var MULTIPLE_ANSWERS = 'multiple_answers_question';

  /**
   * @internal
   * @hide
   *
   * Calculates a similar ratio to #ratio but for questions that require a
   * student to choose more than one answer for their response to be considered
   * correct. As such, a "partially" correct response does not count towards
   * the correct response ratio.
   */
  var ratioForMultipleAnswers = function() {
    return this.correct / this.participantCount;
  };

  /**
   * @class RatioCalculator
   *
   * A utility class for calculating response ratios for a given question
   * statistics object.
   *
   * The ratio calculation may differ based on the question type, this class
   * takes care of it by exposing a single API #ratio() that hides those details
   * from you.
   */
  var RatioCalculator = function(questionType, options) {
    this.questionType = questionType;

    if (options) {
      this.setAnswerPool(options.answerPool);
      this.setParticipantCount(options.participantCount);
      this.setCorrectResponseCount(options.correctResponseCount);
    }

    return this;
  };

  extend(RatioCalculator.prototype, {
    participantCount: 0,

    setParticipantCount: function(count) {
      this.participantCount = count;
    },

    /**
     * @property {Object[]} answerPool
     * This is the set of answers that we'll use to calculate the ratio.
     *
     * Synopsis of the expected answer objects in the set:
     *
     *     {
     *       "responses": 0,
     *       "correct": true
     *     }
     *
     * Most question types will have these defined in the top-level "answers" set,
     * but for some others that support answer sets, these could be found in
     * `answer_sets.@each.answer_matches`.
     */
    answerPool: [],

    setAnswerPool: function(pool) {
      this.answerPool = pool;
    },

    setCorrectResponseCount: function(count) {
      this.correctResponseCount = count;
    },

    /**
     * Calculates the ratio of students who answered this question correctly
     * (partially correct answers do not count when applicable)
     *
     * @return {Number} A scalar, the ratio.
     */
    getRatio: function() {
      var participantCount = this.participantCount || 0;
      var correctResponseCount;

      if (participantCount <= 0) {
        return 0;
      }

      // Multiple-Answer question stats already come served with a "correct"
      // field that denotes the count of students who provided a fully correct
      // answer, so we don't have to calculate anything for it.
      if (MULTIPLE_ANSWERS === this.questionType) {
        correctResponseCount = this.correctResponseCount;
      }
      else {
        correctResponseCount = this.answerPool.reduce(function(sum, answer) {
          return (answer.correct) ? sum + answer.responses : sum;
        }, 0);
      }

      return parseFloat(correctResponseCount) / participantCount;
    }
  });

  return RatioCalculator;
});