/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var _ = require('lodash');
  var Actions = require('../actions');
  var I18n = require('i18n!quiz_log_auditing.event_stream');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var Event = require('jsx!./event_stream/event');

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
      return(
        <div id="ic-EventStream">
          <h2>{I18n.t('headers.action_log', 'Action Log')}</h2>

          {this.props.events.length === 0 &&
            <p>
              {I18n.t('notices.no_events_available',
                'There were no events logged during the quiz-taking session.'
              )}
            </p>
          }

          <ol id="ic-EventStream__ActionLog">
            {this.props.events.map(this.renderEvent)}
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
    }
  });

  return EventStream;
});