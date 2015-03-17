/** @jsx React.DOM */

define([
  'react',
  'react-router'
], function(React, { RouteHandler }) {

  return React.createClass({
    displayName: 'Root',

    render() {
      return (
        <div className="ExternalAppsRoot">
          <RouteHandler/>
        </div>
      );
    }
  });

});