/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var Spinner = React.createClass({
    render: function() {
      return(
        <div className="ic-Spinner">
          <div className="rect1"></div>
          <div className="rect2"></div>
          <div className="rect3"></div>
          <div className="rect4"></div>
          <div className="rect5"></div>
        </div>
      );
    }
  });

  return Spinner;
});