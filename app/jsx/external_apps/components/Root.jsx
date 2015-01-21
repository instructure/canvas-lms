/** @jsx React.DOM */

define([
  'old_unsupported_dont_use_react'
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