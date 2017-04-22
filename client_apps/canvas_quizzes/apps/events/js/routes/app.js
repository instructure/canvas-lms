/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var Actions = require('../actions');
  var I18n = require('i18n!quiz_log_auditing');

  var AppRoute = React.createClass({
    getInitialState: function() {
      return {
        isLoading: false
      };
    },

    componentDidUpdate: function(prevProps, prevState) {
      if (this.props.query.attempt) {
        Actions.setActiveAttempt(this.props.query.attempt);
      }
    },

    render: function() {
      return (
        <div id="ic-QuizInspector">
          {this.state.isLoading && <p>{I18n.t('loading', 'Loading...')}</p>}
          {this.props.activeRouteHandler(this.state)}
        </div>
      )
    }
  });

  return AppRoute;
});