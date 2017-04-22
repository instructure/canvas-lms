/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var K = require('../../../constants');
  var NO_ANSWER = require('jsx!./no_answer');

  var Matching = React.createClass({
    statics: { questionTypes: [ K.Q_MATCHING ] },

    render: function() {
      var answer = this.props.answer;
      var question = this.props.question;

      return (
        <table>
          {
            question.answers.map(function(questionAnswer) {
              var match;
              var answerRecord = answer.filter(function(record) {
                return record.answer_id === questionAnswer.id+'';
              })[0];

              if (answerRecord) {
                match = question.matches.filter(function(match) {
                  return (''+match.match_id) === ''+answerRecord.match_id;
                })[0];
              }

              return (
                <tr key={"answer-"+questionAnswer.id}>
                  <th scope="col">{questionAnswer.left}</th>
                  <td>{match ? match.text : NO_ANSWER}</td>
                </tr>
              );
            })
          }
        </table>
      );
    }
  });

  return Matching;
});