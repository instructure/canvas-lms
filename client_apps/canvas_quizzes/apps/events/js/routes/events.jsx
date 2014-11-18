/** @jsx React.DOM */
define(function(require) {
  var Events = require('jsx!../views/events');
  var Session = require('jsx!../views/session');
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');
  var I18n = require('i18n!quiz_inspector');

  var EventsRoute = React.createClass({
    mixins: [],

    getDefaultProps: function() {
      return {
      };
    },

    render: function() {
      var props = this.props;

      return(
        <div>
          <ScreenReaderContent tagName="h1">
            {I18n.t('title', 'Quiz Inspector')}
          </ScreenReaderContent>

          <Session
            submission={this.props.submission}
            attempt={this.props.attempt}
            availableAttempts={this.props.availableAttempts} />

          <Events
            submission={this.props.submission}
            events={this.props.events}
            questions={this.props.questions}
            currentEventId={this.props.currentEventId}
            inspectedQuestion={this.props.inspectedQuestion}
            isLoadingQuestion={this.props.isLoadingQuestion} />
        </div>
      );
    }
  });

  return EventsRoute;
});