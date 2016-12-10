define([
  'react',
  'i18n!outcomes',
  'instructure-ui/Button',
  'instructure-ui/Modal',
  'instructure-ui/Heading',
  'instructure-ui/Typography',
], (React, I18n, { default: Button }, { default: Modal, ModalHeader, ModalBody, ModalFooter }, { default: Heading }, { default: Typography }) => {

  return React.createClass({
    proptypes: {
      onClose: React.PropTypes.func,
      onReady: React.PropTypes.func
    },
    getInitialState: function () {
      return {
        isOpen: false
      }
    },
    render: function () {
      return (
        <Modal
          isOpen={this.state.isOpen}
          shouldCloseOnOverlayClick={true}
          onRequestClose={this.close}
          transition="fade"
          size="auto"
          label={I18n.t("Modal Dialog: Add to course")}
          closeButtonLabel={I18n.t("Close")}
          zIndex="9999"
          ref={this._saveModal}
          onEntering={this._fixFocus}
          onClose={this.props.onClose}
          onReady={this.props.onReady}
        >
          <ModalHeader>
            <Heading>{I18n.t("Add to course...")}</Heading>
          </ModalHeader>
          <ModalBody>
            <Typography lineHeight="double">Add to course functionality goes here...</Typography>
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.close} variant="primary">{I18n.t("Close")}</Button>
          </ModalFooter>
        </Modal>
      );
    },
    close: function () {
      this.setState({ isOpen: false });
    },
    open: function () {
      this.setState({ isOpen: true });
    },
    //TODO Remove these next two functions once INSTUI fixes initial focus being set incorrectly when opening a modal
    //from a popovermenu
    _saveModal: function (modal) {
      this._modal = modal;
    },
    _fixFocus: function () {
      setTimeout(function() {
        this._modal._closeButton.focus();
      }.bind(this), 0);
    }
  });
});