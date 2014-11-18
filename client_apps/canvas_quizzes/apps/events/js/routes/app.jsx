/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var Router = require('canvas_packages/react-router');
  var Actions = require('../actions');

  var AppRoute = React.createClass({
    componentDidUpdate: function(prevProps, prevState) {
      if (this.props.query.attempt) {
        Actions.setActiveAttempt(this.props.query.attempt);
      }
    },

    render: function() {
      return (
        <div id="ic-QuizInspector">
          {this.props.activeRouteHandler(this.state)}
        </div>
      )
    }
  });

  return AppRoute;
});