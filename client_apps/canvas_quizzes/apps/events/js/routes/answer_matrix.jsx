/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var AnswerMatrix = require('jsx!../views/answer_matrix');
  var Config = require('../config');

  var AnswerMatrixRoute = React.createClass({
    statics: {
      willTransitionTo: function(transition, params) {
        if (!Config.allowMatrixView) {
          transition.abort();
        }
      }
    },

    render: function() {
      return (
        <AnswerMatrix
          loading={this.props.isLoading}
          questions={this.props.questions}
          events={this.props.events}
          submission={this.props.submission} />
      );
    }
  });

  return AnswerMatrixRoute;
});