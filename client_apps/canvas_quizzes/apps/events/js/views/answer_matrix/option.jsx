/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var Option = React.createClass({
    getDefaultProps: function() {
      return {
        checked: null
      };
    },

    render: function() {
      return (
        <label>
          <input
            type="checkbox"
            onChange={this.onChange}
            checked={this.props.checked} />

          {this.props.label}
        </label>
      );
    },

    onChange: function(e) {
      this.props.onChange(this.props.name, e.target.checked);
    }
  });


  return Option;
});