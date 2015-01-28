/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var K = require('../../../constants');

  var MultipleAnswers = React.createClass({
    statics: {
      questionTypes: [ K.Q_MULTIPLE_ANSWERS ]
    },

    getDefaultProps: function() {
      return {
        answer: [],
        question: { answers: [] }
      };
    },

    render: function() {
      return (
        <div className="ic-QuestionInspector__MultipleAnswers">
          {this.props.question.answers.map(this.renderAnswer)}
        </div>
      );
    },

    renderAnswer: function(answer) {
      var isSelected = this.props.answer.indexOf(''+answer.id) > -1;

      return (
        <div key={'answer'+answer.id}>
          <input
            type="checkbox"
            readOnly
            disabled={!isSelected}
            checked={isSelected} />

          {answer.text}
        </div>
      )
    }
  });

  return MultipleAnswers;
});