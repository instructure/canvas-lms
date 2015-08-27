/** @jsx React.DOM */

define([
  'react',
], function(React){

  var ModalContent = React.createClass({
    displayName: 'ModalContent',
    getDefaultProps(){
      return {
        className: "ReactModal__Body"
      }
    },
    render() {
      return (
        <div className={this.props.className}>
          {this.props.children}
        </div>
      );
    }
  });

  return ModalContent;
});
