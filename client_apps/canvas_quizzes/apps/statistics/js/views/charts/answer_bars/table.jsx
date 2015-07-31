/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var _ = require('lodash');
  var I18n = require('i18n!quiz_statistics.answer_bars_chart');
  var Text = require('jsx!canvas_quizzes/components/text');
  var UserListDialog = require('jsx!../../questions/user_list_dialog');

  // A table for screen-readers that provides an alternative view of the data.
  var Table = React.createClass({
    getDefaultProps: function() {
      return {
        answers: []
      };
    },

    render: function() {
      return (
        <table>
          <caption>
            <Text phrase="audible_description">
              This table lists all the answers to the question, along with the
              number of responses they have received.
            </Text>
          </caption>

          <tbody>
            {this.props.answers.map(this.renderEntry)}
          </tbody>
        </table>
      );
    },

    renderEntry: function(answer, position) {
      return (
        <tr key={'answer-'+answer.id}>
          <td scope="col">
            {I18n.t('audible_answer_position', 'Answer %{position}:', { position: position+1 }) + ' '}

            {answer.text + '. ' /* make sure there's a sentence delimiter */}

            {answer.correct &&
              <em>
                {' '}
                {I18n.t('audible_correct_answer_indicator', 'This is a correct answer.')}
              </em>
            }
          </td>

          <td>
            {I18n.t('audible_answer_response_count', {
              zero: 'No responses.',
              one: 'One response.',
              other: '%{count} responses.'
            }, {
              count: answer.responses
            })}
            {this.renderRespondents(answer)}
          </td>
        </tr>
      );
    },

    renderRespondents: function (answer) {
      if (!_.isEmpty(answer.user_names)) {
        return(
          <div>
            <span className="screenreader-only">{I18n.t('Select for list of users who responded.')}</span>
            <UserListDialog answer_id={answer.id} user_names={answer.user_names} />
          </div>
        );
      }
    }
  });

  return Table;
});
