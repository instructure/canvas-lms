/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var Essay = require('jsx!./essay');

  var Calculated = React.createClass({
    render: Essay.type.prototype.render,
    renderAsideContent: function() {
      return false;
    }
  });

  return Calculated;
});