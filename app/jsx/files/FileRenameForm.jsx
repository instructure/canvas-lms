define([
  'react',
  'compiled/react_files/components/FileRenameForm',
  'jsx/shared/modal',
  'jsx/shared/modal-content',
  'jsx/shared/modal-buttons',
  'i18n!file_rename_form'

  ], function(React, FileRenameForm, Modal, ModalContent, ModalButtons, I18n) {


  FileRenameForm.buildContent = function () {
    var nameToUse = this.state.fileOptions.name || this.state.fileOptions.file.name;
    var buildContentToRender;
    if (!this.state.isEditing) {
      buildContentToRender = (
        <div ref='bodyContent'>
          <p id='renameFileMessage'>
            {I18n.t('An item named "%{name}" already exists in this location. Do you want to replace the existing file?', {name: nameToUse})}
          </p>
        </div>
      );
    } else {
      buildContentToRender = (
        <div ref='bodyContent'>
          <p>
            {I18n.t('Change "%{name}" to', {name: nameToUse})}
          </p>
          <form onSubmit={this.handleFormSubmit}>
            <label className='file-rename-form__form-label'>
              {I18n.t('Name')}
            </label>
            <input
              className='input-block-level'
              type='text'
              defaultValue={nameToUse}
              ref='newName'
            >
            </input>
          </form>
        </div>
      );
    }

    return buildContentToRender;
  };

  FileRenameForm.buildButtons = function () {
    var buildButtonsToRender;
    if (!this.state.isEditing) {
      buildButtonsToRender = (
        [
          <button
            ref='renameBtn'
            className='btn btn-default'
            onClick={this.handleRenameClick}
          >
            {I18n.t('Change Name')}
          </button>
         ,
          <button
            ref='replaceBtn'
            className='btn btn-primary'
            onClick={this.handleReplaceClick}
          >
            {I18n.t('Replace')}
          </button>
        ]
      );
    } else {
      buildButtonsToRender = (
        [
          <button
            ref='backBtn'
            className='btn btn-default'
            onClick={this.handleBackClick}
          >
            {I18n.t('Back')}
          </button>
        ,
          <button
            ref='commitChangeBtn'
            className='btn btn-primary'
            onClick={this.handleChangeClick}
          >
            {I18n.t('Change')}
          </button>
         ]
      );
    }

    return buildButtonsToRender;
  };

  FileRenameForm.render =  function () {
    return (
      <div>
        <Modal
          className='ReactModal__Content--canvas ReactModal__Content--mini-modal'
          ref='canvasModal'
          isOpen={this.props.fileOptions}
          title={I18n.t('Copy')}
          onRequestClose={this.props.onClose}
          closeWithX={this.props.closeWithX}
        >
          <ModalContent>
            {this.buildContent()}
            <ModalButtons>
              {this.buildButtons()}
            </ModalButtons>
          </ModalContent>
        </Modal>
      </div>
    );
  };

  return React.createClass(FileRenameForm);

});