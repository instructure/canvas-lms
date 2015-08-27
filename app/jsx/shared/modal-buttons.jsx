/** @jsx React.DOM */

define([
  'react',
], function(React){

  var ModalButtons = React.createClass({
    displayName: 'ModalButtons',
    getDefaultProps(){
      return {
        className: "ReactModal__Footer",
        footerClassName: "ReactModal__Footer-Actions"
      }
    },
    render() {
      return (
        <div className={this.props.className} >
          <div className={this.props.footerClassName}>
            {this.props.children}
          </div>
        </div>
      );
    }
  });

  return ModalButtons;
});
