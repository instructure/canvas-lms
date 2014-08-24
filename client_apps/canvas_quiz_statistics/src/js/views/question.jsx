/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var classSet = require('../util/class_set');
  var Question = React.createClass({
    getDefaultProps: function() {
      return {
        expanded: false
      };
    },
    render: function() {
      var className = classSet({
        'question-statistics': true,
        'with-details': !!this.props.expanded,
      });

      return(
        <div className={className} children={this.props.children} />
      );
    }
  });

  return Question;
});