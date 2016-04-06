define([
  'react'
], function(React) {

  return React.createClass({
    displayName: 'Root',

    render() {
      return (
        <div className="ExternalAppsRoot">
          {React.cloneElement(this.props.children, {})}
        </div>
      );
    }
  });

});