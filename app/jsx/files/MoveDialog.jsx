define([
  'i18n!react_files',
  'react',
  'compiled/react_files/components/MoveDialog',
  'jsx/shared/modal',
  'jsx/shared/modal-content',
  'jsx/shared/modal-buttons',
  'jsx/files/BBTreeBrowser'
], function (I18n, React, MoveDialog, Modal, ModalContent, ModalButtons, BBTreeBrowser) {

  MoveDialog.renderMoveButton = function () {
    if (this.state.isCopyingFile) {
      return (
        <button
          type='submit'
          disabled={!this.state.destinationFolder}
          className='btn btn-primary'
          data-text-while-loading={I18n.t('Copying...')}
        >
          {I18n.t('Copy to Folder')}
        </button>
      );
    } else {
      return (
        <button
          type='submit'
          disabled={!this.state.destinationFolder}
          className='btn btn-primary'
          data-text-while-loading={I18n.t('Moving...')}
        >
          {I18n.t('Move')}
        </button>
      );
    }
  };

  MoveDialog.render = function () {
    return (
      <Modal
        className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
        ref='canvasModal'
        isOpen={this.state.isOpen}
        title={this.getTitle()}
        onRequestClose={this.closeDialog}
        onSubmit={this.submit}
      >
        <ModalContent>
          <BBTreeBrowser
            rootFoldersToShow={this.props.rootFoldersToShow}
            onSelectFolder={this.onSelectFolder}
          />
        </ModalContent>
        <ModalButtons>
          <button
            type='button'
            className='btn'
            onClick={this.closeDialog}
          >
            {I18n.t('Cancel')}
          </button>
          {this.renderMoveButton()}
        </ModalButtons>
      </Modal>
    );
  };

  return React.createClass(MoveDialog);

});
