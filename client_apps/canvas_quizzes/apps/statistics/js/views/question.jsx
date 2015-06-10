/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var classSet = require('canvas_quizzes/util/class_set');

  var Question = React.createClass({
    getDefaultProps: function() {
      return {
        expanded: false,
        stretched: false
      };
    },

    render: function() {
      var className = classSet({
        'question-statistics': true,
        'with-details': !!this.props.expanded,
        'stretched-answer-distribution': !!this.props.stretched
      });

      return(
        <div className={className} children={this.props.children} />
      );
    }
  });

  return Question;
});