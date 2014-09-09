/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ScreenReaderContent = React.createClass({
    getDefaultProps: function() {
      return {
        tagName: 'span'
      };
    },

    render: function() {
      var tag = React.DOM[this.props.tagName];

      return this.transferPropsTo(
        <tag className="screenreader-only" children={this.props.children} />
      );
    }
  });

  return ScreenReaderContent;
});