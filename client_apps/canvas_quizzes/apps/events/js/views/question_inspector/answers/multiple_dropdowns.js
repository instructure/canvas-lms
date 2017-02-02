/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var K = require('../../../constants');
  var NO_ANSWER = require('jsx!./no_answer');
  var keys = Object.keys;

  var MultipleDropdowns = React.createClass({
    statics: {
      questionTypes: [
        K.Q_MULTIPLE_DROPDOWNS
      ]
    },

    render: function() {
      var answer = this.props.answer;
      var question = this.props.question;
      var answers = this.props.question.answers;

      return (
        <table>
          {
            keys(answer).map(function(blank) {
              var answerText = answers.filter(function(originalAnswer) {
                return ''+originalAnswer.id === answer[blank];
              })[0] || {};

              return (
                <tr key={'blank'+blank}>
                  <th scope="row">{blank}</th>
                  <td>{answerText.text || NO_ANSWER}</td>
                </tr>
              );
            })
          }
        </table>
      );
    }
  });

  return MultipleDropdowns;
});