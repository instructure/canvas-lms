/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var Question = React.createClass({
    render: function() {
      return(
        <div className="question-statistics" children={this.props.children} />
      );
    }
  });

  return Question;
});