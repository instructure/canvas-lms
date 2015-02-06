/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_log_auditing.table_view');
  var secondsToTime = require('canvas_quizzes/util/seconds_to_time');
  var Cell = require('jsx!./cell');

  /**
   * @class Events.Views.AnswerMatrix.Table
   *
   * A table displaying the sequence of answers the student has provided to all
   * the questions. The answer cells will variate in shape based on the presence
   * of the answer and its position.
   *
   * @see Events.Views.AnswerMatrix.Emblem
   *
   * @seed A table of 8 questions and 25 events.
   *   "apps/events/test/fixtures/loaded_table.json"
   */
  var Table = React.createClass({
    getInitialState: function() {
      return {
        activeEventId: null
      };
    },

    getDefaultProps: function() {
      return {
        questions: [],
        events: [],
        submission: {}
      };
    },

    render: function() {
      return (
        <table className="ic-AnswerMatrix__Table ic-Table ic-Table--hover-row  ic-Table--condensed">
          <thead>
            <tr className="ic-Table__row--bg-neutral">
              <th key="timestamp">
                <div>{I18n.t('headers.timestamp', 'Timestamp')}</div>
              </th>

              {this.props.questions.map(this.renderHeaderCell)}
            </tr>
          </thead>

          <tbody>
            {this.props.events.map(this.renderContentRow)}
          </tbody>
        </table>
      );
    },

    renderHeaderCell: function(question) {
      return (
        <th key={"question-"+question.id}>
          <div>
            {I18n.t('headers.question', 'Question %{position}', {
              position: question.position
            })}

            <small>({question.id})</small>
          </div>
        </th>
      )
    },

    renderContentRow: function(event) {
      var className;
      var expanded = this.props.expandAll || event.id === this.state.activeEventId;
      var shouldTruncate = this.props.shouldTruncate;
      var secondsSinceStart = (
        new Date(event.createdAt) - new Date(this.props.submission.startedAt)
      ) / 1000;

      if (this.props.activeEventId === event.id) {
        className = 'active';
      }

      return (
        <tr
          key={"event-"+event.id}
          className={className}
          onClick={this.toggleAnswerVisibility.bind(null, event)}>
          <td>{secondsToTime(secondsSinceStart)}</td>

          {this.props.questions.map(function(question) {
            return (
              <td key={[ 'q', question.id, 'e', event.id ].join('_')}>{
                Cell({
                  question: question,
                  event: event,
                  expanded: expanded,
                  shouldTruncate: shouldTruncate
                })
              }</td>
            );
          })}
        </tr>
      );
    },

    toggleAnswerVisibility: function(event) {
      this.setState({
        activeEventId: event.id === this.state.activeEventId ? null : event.id
      });
    },
  });

  return Table;
});