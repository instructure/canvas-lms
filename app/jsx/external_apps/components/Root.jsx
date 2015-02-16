/** @jsx React.DOM */

define([
  'react'
], function(React) {

  return React.createClass({
    displayName: 'Root',

    render() {
      return (
        <div className="ExternalAppsRoot">
          <this.props.activeRouteHandler />
        </div>
      );
    }
  });

});