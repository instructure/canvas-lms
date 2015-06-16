define(function(require) {
  var _ = require('lodash');
  var K = require('../constants');
  var findWhere = _.findWhere;
  var keys = Object.keys;
  var QuestionAnsweredEventDecorator = {};

  QuestionAnsweredEventDecorator.decorateAnswerRecord = function(question, record) {
    var answered = false;
    var answer = record.answer;
    var blank;

    switch(question.questionType) {
      case K.Q_NUMERICAL:
      case K.Q_CALCULATED:
      case K.Q_MULTIPLE_CHOICE:
      case K.Q_SHORT_ANSWER:
      case K.Q_ESSAY:
        answered = answer !== null;
        break;

      case K.Q_FILL_IN_MULTIPLE_BLANKS:
      case K.Q_MULTIPLE_DROPDOWNS:
        for (blank in answer) {
          if (answer.hasOwnProperty(blank)) {
            answered = answer[blank] !== null;
          }

          if (answered) {
            break;
          }
        }
        break;

      case K.Q_MATCHING:
        if (answer instanceof Array && answer.length > 0) {
          // watch out that at this point, the attributes are not normalized
          // and not camelCased:
          answered = answer.some(function(pair) {
            return pair.match_id !== null;
          });
        }

        break;
      case K.Q_MULTIPLE_ANSWERS:
      case K.Q_FILE_UPLOAD:
        answered = answer instanceof Array && answer.length > 0;
        break;

      default:
        answered = answer !== null;
    }

    record.answered = answered;
  };

  /**
   * Extend the raw event attributes as received from the API with some stuff
   * that we'll need when rendering the views.
   *
   * This "decoration" could be done once after the payload is received and it
   * is not necessary to re-perform them, unless the event answer data has been
   * mutated.
   *
   * The decorations are:
   *
   * 1. `answered`
   *    This is applied on the answer records inside the model's "data" attr.
   *    ---
   *    A boolean indicating whether an answer is present. This
   *    differs in semantics based on the question type and that's why we can't
   *    simply test for "answer" to be null or "".
   *
   * 2. `last`
   *    This is applied on the answer records inside the model's "data" attr.
   *    ---
   *    A boolean indicating whether this answer record is the final answer
   *    provided to the referenced question.
   *
   * @param  {Models.Event[]} events
   *         An array of Event instances of type EVT_QUESTION_ANSWERED.
   *
   * @param  {Object[]} questions
   *         An array of question data; this must contain all the questions
   *         referenced by the event set above.
   *
   * @return {null}
   *         Nothing is returned as the decoration is done in-place on the model
   *         attributes.
   */
  QuestionAnsweredEventDecorator.run = function(events, questions) {
    var finalAnswerEvents = {};

    events.forEach(function(event) {
      event.attributes.data.forEach(function(record) {
        var question = questions.filter(function(question) {
          return question.id === record.quizQuestionId;
        })[0];

        finalAnswerEvents[question.id] = event;

        QuestionAnsweredEventDecorator.decorateAnswerRecord(question, record);
      });
    });

    keys(finalAnswerEvents).forEach(function(quizQuestionId) {
      var event = finalAnswerEvents[quizQuestionId];

      findWhere(event.attributes.data, {
        quizQuestionId: quizQuestionId
      }).last = true;
    });

    finalAnswerEvents = null;
  };

  return QuestionAnsweredEventDecorator;
});