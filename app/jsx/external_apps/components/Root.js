import React from 'react'

export default React.createClass({
    displayName: 'Root',

    render() {
      return (
        <div className="ExternalAppsRoot">
          {React.cloneElement(this.props.children, {})}
        </div>
      );
    }
  });
