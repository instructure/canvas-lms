define([
  'react',
  'jsx/shared/modal',
  'jsx/shared/modal-content',
  'i18n!react_files'
], function(React, Modal, ModalContent, I18n) {
  var KeyboardShortcutModal = React.createClass({
    getInitialState() {
      return {
        isOpen: false
      }
    },
    componentDidMount() {
      document.addEventListener("keydown", this.handleKeydown);
    },
    componentWillUnmount() {
      document.removeEventListener("keydown", this.handleKeydown);
    },
    closeModal() {
      this.setState({isOpen: false});
    },
    handleKeydown(e) {
      // 188 is comma and 191 is forward slash
      var keyComboPressed = e.which === 188 || (e.which === 191 && e.shiftKey);
      if (keyComboPressed && e.target.nodeName !== "INPUT" && e.target.nodeName !== "TEXTAREA") {
        e.preventDefault();
        this.setState({isOpen: !this.state.isOpen});
      }
    },
    shortcuts() {
      if (this.props.shortcuts) {
        return this.props.shortcuts.map(function(shortcut) {
          return (
            <li>
              <span className="keycode">{shortcut.keycode}</span>
              <span className="colon">:</span>
              <span className="description">{shortcut.description}</span>
            </li>
          );
        })
      }
    },
    render() {
      var { title, className, styles, ...other } = this.props;
      return (
        <Modal isOpen={this.state.isOpen}
               title={I18n.t("Keyboard Shortcuts")}
               className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
               overlayClassName="ReactModal__Overlay--canvas"
               onRequestClose={this.closeModal}
               {...other}>
          <ModalContent>
            <div className="keyboard_navigation">
              <span className="screenreader-only">
                {I18n.t("Users of screen readers may need to turn off the virtual cursor in order to use these keyboard shortcuts")}
              </span>
              <ul className="navigation_list">
                {this.shortcuts()}
              </ul>
              <span className="screenreader-only">
                {I18n.t("Press the esc key to close this modal")}
              </span>
            </div>
          </ModalContent>
        </Modal>
      );
    }
  });

  return KeyboardShortcutModal;
});
