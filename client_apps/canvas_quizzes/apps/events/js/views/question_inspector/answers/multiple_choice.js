/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var K = require('../../../constants');

  var MultipleChoice = React.createClass({
    statics: {
      questionTypes: [ K.Q_MULTIPLE_CHOICE, K.Q_TRUE_FALSE ]
    },

    getDefaultProps: function() {
      return {
        answer: [],
        question: { answers: [] }
      };
    },

    render: function() {
      return (
        <div className="ic-QuestionInspector__MultipleChoice">
          {this.props.question.answers.map(this.renderAnswer)}
        </div>
      );
    },

    renderAnswer: function(answer) {
      var isSelected = this.props.answer.indexOf(''+answer.id) > -1;

      return (
        <div key={'answer'+answer.id}>
          <input
            type="radio"
            readOnly
            disabled={!isSelected}
            checked={isSelected} />

          {answer.text}
        </div>
      )
    }
  });

  return MultipleChoice;
});