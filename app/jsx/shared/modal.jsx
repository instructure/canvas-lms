define([
  'react',
  'jquery',
  'underscore',
  'compiled/fn/preventDefault',
  'react-modal',
  './modal-content',
  './modal-buttons',
], function (React, $, _, preventDefault,  ReactModal, ModalContent, ModalButtons) {

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.5)'
    },
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

  const Modal = React.createClass({

    getInitialState() {
      return {
        modalIsOpen: this.props.isOpen
      }
    },
    getDefaultProps(){
      return {
        className: "ReactModal__Content--canvas", // Override with "ReactModal__Content--canvas ReactModal__Content--mini-modal" for a mini modal
        style: {},
      };
    },
    componentWillReceiveProps(props){
      let callback
      if (this.props.isOpen && !props.isOpen) callback = this.cleanupAfterClose
      this.setState({modalIsOpen: props.isOpen}, callback);
    },

    openModal() {
      this.setState({modalIsOpen: true});
    },

    cleanupAfterClose () {
      if (this.props.onRequestClose) this.props.onRequestClose();
      $(this.getAppElement()).removeAttr('aria-hidden');
    },

    closeModal() {
      this.setState({modalIsOpen: false}, this.cleanupAfterClose);
    },

    closeWithX() {
      if(_.isFunction(this.props.closeWithX))
        this.props.closeWithX()
      this.closeModal();
    },
    onSubmit(){
      const promise = this.props.onSubmit();
      $(this.refs.modal.getDOMNode()).disableWhileLoading(promise);
    },
    getAppElement () {
      // Need to wait for the dom to load before we can get the default #application dom element
      return this.props.appElement || document.getElementById('application');
    },
    processMultipleChildren(props){
      let content = null;
      let buttons = null;

      React.Children.forEach(props.children, function(child){
        if(child.type == ModalContent){
          content = child;
        }
        if(child.type == ModalButtons){
          buttons = child;
        }
      });

      // Warning if you don't include a component of the right type
      if(content == null){
        console.warn('You should wrap your content in the modal-content component');
      }
      if(buttons == null){
        console.warn('You should wrap your buttons in the modal-buttons component');
      }

      if(this.props.onSubmit){
        return (
          <form className="ModalForm" onSubmit={preventDefault(this.onSubmit)}>
            { [content, buttons] }
          </form>
        )
      }
      else
      {
        return [content, buttons]; // This order needs to be maintained
      }
    },
    render() {
      return (
        <div className="canvasModal">
          <ReactModal
            ariaHideApp={!!this.state.modalIsOpen}
            isOpen={!!this.state.modalIsOpen}
            onRequestClose={this.closeModal}
            className={this.props.className}
            style={modalOverrides}
            overlayClassName={this.props.overlayClassName}
            appElement={this.getAppElement()}>
            <div ref="modal"
              className="ReactModal__Layout"
              style={this.props.style}
            >
              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{this.props.title}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button ref="closeWithX" className="Button Button--icon-action" type="button" onClick={this.closeWithX}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              {this.processMultipleChildren(this.props)}

            </div>
          </ReactModal>
        </div>
      );
    }

  });

  return Modal;
});
