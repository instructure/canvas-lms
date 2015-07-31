/** @jsx React.DOM */

define([
  'react',
  'react-modal'
], function (React, Modal) {

  var ReactModalExample = React.createClass({

    getInitialState() {
      return {
        modalIsOpen: false
      }
    },

    openModal() {
      this.setState({modalIsOpen: true});
    },

    closeModal() {
      this.setState({modalIsOpen: false});
    },

    handleSubmit(e) {
      e.preventDefault();
      this.setState({modalIsOpen: false});
      alert('Submitted');
    },

    render() {
      return (
        <div className="ReactModalExample">
          <button type="button" className="btn btn-primary" onClick={this.openModal}>{this.props.label || 'Trigger Modal'}</button>
          <Modal isOpen={this.state.modalIsOpen}
                 onRequestClose={this.closeModal}
                 className={this.props.className}
                 overlayClassName={this.props.overlayClassName}>
            <div className="ReactModal__Layout">
              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>Modal Title Goes Here</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>
              <div className="ReactModal__Body">
                Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus deserunt doloremque, explicabo illo
                ipsum libero magni odio officia optio perferendis ratione repellat suscipit tempore. Commodi hic sed.
                Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus deserunt doloremque, explicabo illo
                ipsum libero magni odio officia optio perferendis ratione repellat suscipit tempore. Commodi hic sed.
              </div>
              <div className="ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button type="button" className="btn btn-default" onClick={this.closeModal}>Cancel</button>
                  <button type="submit" className="btn btn-primary" onClick={this.handleSubmit}>Submit</button>
                </div>
              </div>
            </div>
          </Modal>
        </div>
      );
    }
  });
  return ReactModalExample;
});
