/** @jsx React.DOM */

define([
  'i18n!zip_file_options_form',
  'react',
  'compiled/react/shared/utils/withReactElement',
  'jsx/shared/modal',
  'jsx/shared/modal-content',
  'jsx/shared/modal-buttons'
  ], function(I18n, React, withReactElement, Modal, ModalContent, ModalButtons) {

  var Modal = React.createFactory(Modal);



  var ZipFileOptionsForm = React.createClass({
    displayName: 'ZipFileOptionsForm',
    propTypes: {
      onZipOptionsResolved: React.PropTypes.func.isRequired
    },
    handleExpandClick: function () {
      this.props.onZipOptionsResolved({file: this.props.fileOptions.file, expandZip: true});
    },
    handleUploadClick: function () {
      this.props.onZipOptionsResolved({file: this.props.fileOptions.file, expandZip: false})
    },
    buildMessage: function (fileOptions) {
      var message = undefined
      if (this.props.fileOptions) {
        var name = this.props.fileOptions.file.name;
        message = I18n.t('message', 'Would you like to expand the contents of "%{fileName}" into the current folder, or upload the zip file as is?', {fileName: name});
      }
      return message;
    },
    render: function () {
      return (
        <Modal
          className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
          isOpen={this.props.fileOptions}
          ref='canvasModal'
          title= { I18n.t('zip_options', 'Zip file options') }
          onRequestClose = {this.props.onClose}
        >
          <ModalContent>
            <p className="modalMessage">
              { this.buildMessage() }
            </p>
          </ModalContent>
          <ModalButtons>
            <button
              className='btn'
              onClick= { this.handleExpandClick }
              >
              { I18n.t('expand', 'Expand It') }
            </button>
            <button
              className='btn btn-primary'
              onClick= { this.handleUploadClick }
            >
              { I18n.t('upload', 'Upload It') }
            </button>
          </ModalButtons>
        </Modal>
      );
    }
  });

  return ZipFileOptionsForm;
});

