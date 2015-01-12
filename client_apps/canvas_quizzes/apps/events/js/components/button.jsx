/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var classSet = require('canvas_quizzes/util/class_set');

  /**
   * @class Events.Components.Button
   *
   * A wrapper for `<button type="button" />` that abstracts the bootstrap CSS
   * classes we need to specify for buttons.
   */
  var Button = React.createClass({
    getDefaultProps: function() {
      return {
        type: 'default'
      };
    },

    render: function() {
      var className = {};
      var type = this.props.type;

      className['btn'] = true;
      className['btn-default'] = type === 'default';
      className['btn-danger'] = type === 'danger';
      className['btn-success'] = type === 'success';

      return(
        <button
          onClick={this.props.onClick}
          type="button"
          className={classSet(className)}
          children={this.props.children} />
      );
    }
  });

  return Button;
});