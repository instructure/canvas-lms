/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var secondsToTime = require('canvas_quizzes/util/seconds_to_time');
  var classSet = require('canvas_quizzes/util/class_set');
  var Actions = require('../actions');
  var K = require('../constants');
  var I18n = require('i18n!quiz_log_auditing');

  var Events = React.createClass({
    getDefaultProps: function() {
      return {
        events: [],
        submission: {},
        questions: []
      };
    },

    render: function() {
      return(
        <div id="ic-QuizInspector__Events">
          <h2>{I18n.t('headers.action_log', 'Action Log')}</h2>

          {this.props.events.length === 0 &&
            <p>
              {I18n.t('notices.no_events_available',
                'There were no events logged during the quiz-taking session.'
              )}
            </p>
          }

          <div id="ic-QuizInspector__EventScroller">
            <table id="ic-QuizInspector__EventTable">
              <thead>
                <tr>
                  <th>{I18n.t('table_headers.timestamp', 'Timestamp')}</th>
                  <th>{I18n.t('table_headers.event', 'Event')}</th>
                </tr>
              </thead>

              <tbody>
                {this.props.events.map(this.renderEvent)}
              </tbody>
            </table>
          </div>
        </div>
      );
    },

    renderEvent: function(e) {
      var secondsSinceStart = (
        new Date(e.createdAt) - new Date(this.props.submission.startedAt)
      ) / 1000;

      var flag = classSet({
        'flag-warning': e.flag === K.EVT_FLAG_WARNING,
        'flag-ok': e.flag === K.EVT_FLAG_OK
      });

      var description = this.describeEvent(e);

      return (
        <tr className={flag} key={"event-"+e.id}>
          <td>{secondsToTime(secondsSinceStart)}</td>
          <td>{description}</td>
        </tr>
      );
    },

    describeEvent: function(event) {
      var description;

      this.currentEventId = event.id;

      switch(event.type) {
        case K.EVT_QUESTION_ANSWERED:
          if (event.data.length === 1) {
            description = (
              <div>
                Answered question
                {this.renderQuestionAnchor(event.data[0])}
                .
              </div>
            );
          }
          else {
            description = (
              <div>
                Answered the following questions:

                <div className="ic-QuizInspector__QuestionAnchors">
                  {event.data.map(this.renderQuestionAnchor)}
                </div>
              </div>
            );
          }
        break;

        case K.EVT_QUESTION_VIEWED:
          description = (
            <div>
              {
                I18n.t('viewed_questions', {
                  one: 'Viewed (and possibly read) question',
                  other: 'Viewed (and possibly read) the following questions:'
                }, { count: event.data.length })
              }
              <div className="ic-QuizInspector__QuestionAnchors">
                {event.data.map(this.renderQuestionAnchor)}
              </div>
              .
            </div>
          );
        break;

        case K.EVT_PAGE_BLURRED:
          description = 'Stopped viewing the Canvas quiz-taking page...';
        break;

        case K.EVT_PAGE_FOCUSED:
          description = 'Resumed.';
        break;
      }

      return description;
    },

    renderQuestionAnchor: function(record) {
      var id;
      var position;

      if (typeof record === 'object') {
        id = record.quizQuestionId;
      }
      else {
        id = record;
      }

      position = this.props.questions.filter(function(q) {
        return q.id === id;
      })[0].position;

      return (
        <a
          key={"question-anchor"+id}
          href={"#questions/"+id}
          className="ic-QuizInspector__QuestionAnchor"
          onClick={this.inspectQuestion.bind(null, id, this.currentEventId)}
          children={'#'+position} />
      );
    },

    inspectQuestion: function(questionId, eventId, e) {
      Actions.inspectQuestion(questionId, eventId);
    }
  });

  return Events;
});