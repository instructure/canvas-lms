/** React.DOM */

define([
  'React',
  'react-modal'
], function(React, Modal) {

  Modal.injectCSS();

  var ReactModalExample = React.createClass({

    getInitialState () {
      return {
        modalIsOpen: false
      }
    },

    openModal (e) {
      e.preventDefault();
      this.setState({ modalIsOpen: true });
    },

    closeModal () {
      this.setState({ modalIsOpen: false });
    },

    handleSubmit () {
      alert('Submitted');
    },

    render () {
      return (
        <div className="ModalExample">
          <a href="#" role="button" aria-label="Trigger Modal" className="btn btn-primary" onClick={this.openModal}>Trigger Modal</a>
          <Modal isOpen={this.state.modalIsOpen} onRequestClose={this.closeModal}>
            
            <div className="ReactModal__Layout">

              <div className="ReactModal__InnerSection ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>Are you ready to submit?</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button className="Button Button--link Button--small" type="button" onClick={this.closeModal}>
                    <i className="icon-x"></i>
                  </button>
                </div>
              </div>

              <div className="ReactModal__InnerSection ReactModal__Body">
                This will be awesome.
              </div>
              
              <div className="ReactModal__InnerSection ReactModal__Footer">
                <div className="ReactModal__Footer-Actions">
                  <button type="button" className="Button" onClick={this.closeModal}>Cancel</button>
                  <button type="button" className="Button Button--primary" onClick={this.handleSubmit}>Submit</button>
                </div>
              </div>

            </div>
            
          </Modal>
        </div>
      );
    }

  });

  React.renderComponent(<ReactModalExample/>, document.getElementById('content'));
});
