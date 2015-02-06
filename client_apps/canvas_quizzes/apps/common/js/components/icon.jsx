/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ScreenReaderContent = require('jsx!./screen_reader_content');
  var SightedUserContent = require('jsx!./sighted_user_content');
  var Icon = React.createClass({
    getDefaultProps: function() {
      return {
        icon: '',
        alt: null
      };
    },

    render: function() {
      var isAccessible = !!this.props.alt;
      var className = 'ic-Icon ' + this.props.icon;

      if (isAccessible) {
        content = (
          <span>
            <ScreenReaderContent>{this.props.alt}</ScreenReaderContent>
            <SightedUserContent tagName="i" className={className} />
          </span>
        );
      }
      else {
        content = <i className={className} />;
      }

      return content;
    }
  });

  return Icon;
});