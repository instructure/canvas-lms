/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var WithSidebar = require('jsx!../mixins/with_sidebar');
  var QuestionInspector = require('jsx!../views/question_inspector');
  var QuestionListing = require('jsx!../views/question_listing');

  var QuestionRoute = React.createClass({
    mixins: [ WithSidebar ],

    getDefaultProps: function() {
      return {
        questions: []
      };
    },

    renderContent: function() {
      var questionId = this.props.params.id;
      var question = this.props.questions.filter(function(question) {
        return question.id === questionId;
      })[0];

      return (
        <QuestionInspector
          loading={this.props.isLoading}
          question={question}
          currentEventId={this.props.query.event}
          inspectedQuestionId={questionId}
          events={this.props.events} />
      );
    },

    renderSidebar: function() {
      return (
        <QuestionListing
          activeQuestionId={this.props.params.id}
          activeEventId={this.props.query.event}
          questions={this.props.questions}
          query={this.props.query} />
      );
    },
  });

  return QuestionRoute;
});