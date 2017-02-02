/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var secondsToTime = require('canvas_quizzes/util/seconds_to_time');
  var I18n = require('i18n!quiz_log_auditing.inverted_table_view');
  var Cell = require('jsx!./cell');

  /**
   * @class Events.Views.AnswerMatrix.InvertedTable
   *
   * A table displaying the event series on the X axis, and the questions
   * on the Y axis. This table is optimal for inspecting answer contents, while
   * the "normal" table is optimized for viewing the answer sequence.
   *
   * @seed A table of 8 questions and 25 events.
   *   "apps/events/test/fixtures/loaded_table.json"
   */
  var InvertedTable = React.createClass({
    getInitialState: function() {
      return {
        activeQuestionId: null
      };
    },

    render: function() {
      window.table = this;

      return (
        <table className="ic-AnswerMatrix__Table ic-Table ic-Table--hover-row ic-Table--striped">
          <thead>
            <tr className="ic-Table__row--bg-neutral">
              <th key="question">
                {I18n.t('headers.question', 'Question')}
              </th>

              {this.props.events.map(this.renderHeaderCell)}
            </tr>
          </thead>

          <tbody>
            {this.props.questions.map(this.renderContentRow)}
          </tbody>
        </table>
      );
    },

    renderHeaderCell: function(event) {
      var secondsSinceStart = (
        new Date(event.createdAt) - new Date(this.props.submission.startedAt)
      ) / 1000;

      return (
        <th key={"header-"+event.id}>
          {secondsToTime(secondsSinceStart)}
        </th>
      );
    },

    renderContentRow: function(question) {
      var expanded = this.props.expandAll || question.id === this.state.activeQuestionId;
      var shouldTruncate = this.props.shouldTruncate;

      return (
        <tr key={"question-"+question.id} onClick={this.toggleAnswerVisibility.bind(null, question)}>
          <td key="question">{question.id}</td>

          {this.props.events.map(function(event) {
            return (
              <td key={[ 'q', question.id, 'e', event.id ].join('_')}>
                {Cell({
                  question: question,
                  event: event,
                  expanded: expanded,
                  shouldTruncate: shouldTruncate
                })}
              </td>
            );
          })}
        </tr>
      );
    },

    toggleAnswerVisibility: function(question) {
      this.setState({
        activeQuestionId: question.id === this.state.activeQuestionId ? null : question.id
      });
    }
  });


  return InvertedTable;
});