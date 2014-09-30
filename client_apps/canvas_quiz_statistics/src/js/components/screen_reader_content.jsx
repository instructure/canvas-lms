/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ScreenReaderContent = React.createClass({
    render: function() {
      return(
        <span className="screenreader-only">{this.props.children}</span>
      );
    }
  });

  return ScreenReaderContent;
});