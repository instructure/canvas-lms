/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var classSet = require('canvas_quizzes/util/class_set');

  var Question = React.createClass({
    render: function() {
      var className = classSet({
        'question-statistics': true,
        'content-box': true
      });

      return(
        <div key={this.props.position} className={className} children={this.props.children} />
      );
    }
  });

  return Question;
});