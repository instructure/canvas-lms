/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var K = require('../../../constants');
  var NO_ANSWER = require('jsx!./no_answer');
  var keys = Object.keys;

  var FIMB = React.createClass({
    statics: {
      questionTypes: [
        K.Q_FILL_IN_MULTIPLE_BLANKS
      ]
    },

    render: function() {
      var answer = this.props.answer;

      return (
        <table>
          {
            keys(answer).map(function(blank) {
              return (
                <tr key={'blank'+blank}>
                  <th scope="row">{blank}</th>
                  <td>{answer[blank] || NO_ANSWER}</td>
                </tr>
              );
            })
          }
        </table>
      );
    }
  });

  return FIMB;
});