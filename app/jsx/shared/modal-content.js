import React from 'react'

  var ModalContent = React.createClass({
    displayName: 'ModalContent',
    getDefaultProps(){
      return {
        className: "ReactModal__Body",
        style: {},
      };
    },
    render() {
      return (
        <div className={this.props.className} style={this.props.style}>
          {this.props.children}
        </div>
      );
    }
  });

export default ModalContent
