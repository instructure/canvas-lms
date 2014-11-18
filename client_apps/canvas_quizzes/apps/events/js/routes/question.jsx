/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var WithSidebar = require('jsx!../mixins/with_sidebar');
  var QuestionInspector = require('jsx!../views/question_inspector');
  var QuestionListing = require('jsx!../views/question_listing');
  var Actions = require('../actions');

  var QuestionRoute = React.createClass({
    mixins: [ WithSidebar ],
    statics: {
      willTransitionFrom: function() {
        Actions.stopInspectingQuestion();
      }
    },

    componentDidMount: function() {
      Actions.inspectQuestion(this.props.params.id);
    },

    renderContent: function() {
      return (
        <QuestionInspector
          loading={this.props.isLoadingQuestion}
          questions={this.props.questions}
          question={this.props.inspectedQuestion}
          currentEventId={this.props.currentEventId}
          inspectedQuestionId={this.props.inspectedQuestionId}
          events={this.props.events} />
      );
    },

    renderSidebar: function() {
      return (
        <QuestionListing
          activeId={this.props.inspectedQuestionId}
          questions={this.props.questions} />
      );
    },
  });

  return QuestionRoute;
});