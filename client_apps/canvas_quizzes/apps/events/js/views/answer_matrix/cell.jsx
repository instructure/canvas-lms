/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var _ = require('lodash');
  var K = require('../../constants');
  var Emblem = require('jsx!./emblem');
  var findWhere = _.findWhere;

  // These questions types will have their answer cells truncated if it goes
  // over the character visibility threshold:
  var FREE_FORM_QUESTION_TYPES = [
    K.Q_ESSAY,
    K.Q_SHORT_ANSWER
  ];

  var MAX_VISIBLE_CHARS = K.MAX_VISIBLE_CHARS;

  /**
   * @class Cell
   * @memberOf Views.AnswerMatrix
   *
   * A table cell that renders an answer to a question, based on the question
   * type, the table options, and other things.
   */
  var Cell = React.createClass({
    getDefaultProps: function() {
      return {
        expanded: false,
        shouldTruncate: false,
        event: {},
        question: {}
      };
    },

    render: function() {
      var contents, formattedAnswer, answerSz, encodeAsJson;
      var props = this.props;
      var record = findWhere(props.event.data, {
        quizQuestionId: props.question.id
      });

      if (record) {
        formattedAnswer = record.answer;
        encodeAsJson = true;

        // show the answer only if the expandAll option is turned on, or the
        // current event is activated (i.e, the row was clicked):
        if (props.expanded) {
          if (FREE_FORM_QUESTION_TYPES.indexOf(props.question.questionType) > -1) {
            encodeAsJson = false;

            if (props.shouldTruncate) {
              formattedAnswer = record.answer || '';
              answerSz = formattedAnswer.length;

              if (answerSz > MAX_VISIBLE_CHARS) {
                formattedAnswer = formattedAnswer.substr(0, MAX_VISIBLE_CHARS);
                formattedAnswer += '...';
              }
            }
          }

          return (
            <pre>
              {encodeAsJson ?
                JSON.stringify(formattedAnswer, null, 2) :
                formattedAnswer
              }
            </pre>
          );
        }
        else {
          return Emblem(record);
        }
      }

      return null;
    }
  });

  return Cell;
});