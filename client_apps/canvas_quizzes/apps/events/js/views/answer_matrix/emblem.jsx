/** @jsx React.DOM */
define(function(require) {
  var React = require('react');

  /**
   * @class Events.Views.AnswerMatrix.Emblem
   *
   * Woop.
   *
   * @seed An emblem for an empty answer.
   *  {}
   *
   * @seed An emblem for some answer.
   *  { "answered": true }
   *
   * @seed An emblem for the final answer.
   *  { "answered": true, "last": true }
   */
  var Emblem = React.createClass({
    getDefaultProps: function() {
      return {};
    },

    shouldComponentUpdate: function(nextProps, nextState) {
      return false;
    },

    render: function() {
      var record = this.props;
      var className = 'ic-AnswerMatrix__Emblem';

      if (record.answered && record.last) {
        className += ' is-answered is-last';
      }
      else if (record.answered) {
        className += ' is-answered';
      }
      else {
        className += ' is-empty';
      }

      return <i className={className} />;
    }
  });

  return Emblem;
});