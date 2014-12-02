/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var EventStream = require('jsx!../views/event_stream');
  var Session = require('jsx!../views/session');

  var EventStreamRoute = React.createClass({
    mixins: [],

    getDefaultProps: function() {
      return {
      };
    },

    render: function() {
      var props = this.props;

      return(
        <div>
          <Session
            submission={this.props.submission}
            attempt={this.props.attempt}
            availableAttempts={this.props.availableAttempts} />

          <EventStream
            submission={this.props.submission}
            events={this.props.events}
            questions={this.props.questions}
            attempt={this.props.attempt} />
        </div>
      );
    }
  });

  return EventStreamRoute;
});