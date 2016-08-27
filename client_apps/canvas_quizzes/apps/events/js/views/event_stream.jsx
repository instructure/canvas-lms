/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var _ = require('lodash');
  var Actions = require('../actions');
  var I18n = require('i18n!quiz_log_auditing.event_stream');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var Event = require('jsx!./event_stream/event');
  var K = require('../constants');
  var visibleEventTypes = [
    K.EVT_SESSION_STARTED, K.EVT_QUESTION_ANSWERED, K.EVT_QUESTION_VIEWED,
    K.EVT_QUESTION_FLAGGED, K.EVT_PAGE_BLURRED, K.EVT_PAGE_FOCUSED
  ];

  var extend = _.extend;

  var EventStream = React.createClass({
    getDefaultProps: function() {
      return {
        events: [],
        submission: {},
        questions: []
      };
    },

    render: function() {
      var visibleEvents = this.getVisibleEvents(this.props.events);
      return(
        <div id="ic-EventStream">
          <h2>{I18n.t('headers.action_log', 'Action Log')}</h2>

          {visibleEvents.length === 0 &&
            <p>
              {I18n.t('notices.no_events_available',
                'There were no events logged during the quiz-taking session.'
              )}
            </p>
          }

          <ol id="ic-EventStream__ActionLog">
            {visibleEvents.map(this.renderEvent)}
          </ol>
        </div>
      );
    },

    renderEvent: function(e) {
      var props = extend({}, e, {
        startedAt: this.props.submission.startedAt,
        questions: this.props.questions,
        attempt: this.props.attempt
      });

      return Event(props);
    },

    getVisibleEvents: function(events) {
      return events.filter(function(e) {
        if(visibleEventTypes.indexOf(e.type) == -1) {
          return false
        }
        if(e.type != K.EVT_QUESTION_ANSWERED) {
          return true;
        }
        return _.any(e.data, function(i) {
          return (i.answer != null);
        });
      });
    }

  });

  return EventStream;
});