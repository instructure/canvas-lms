import I18n from 'i18n!upload_button'
import React from 'react'
import FileRenameForm from 'jsx/files/FileRenameForm'
import ZipFileOptionsForm from './ZipFileOptionsForm'
import UploadButton from 'compiled/react_files/components/UploadButton'
  UploadButton.buildPotentialModal = function () {
    if (this.state.zipOptions.length) {
      return (
        <ZipFileOptionsForm
          fileOptions= {this.state.zipOptions[0]}
          onZipOptionsResolved= {this.onZipOptionsResolved}
          onClose={this.onClose}
        />
      );
    } else if (this.state.nameCollisions.length) {
      return (
        <FileRenameForm
          fileOptions= {this.state.nameCollisions[0]}
          onNameConflictResolved= {this.onNameConflictResolved}
          onClose= {this.onClose}
        />
      );
    }
  }

  UploadButton.hiddenPhoneClassname = function () {
    if (this.props.showingButtons) {
      return('hidden-phone');
    }
  }

  UploadButton.render = function () {
    return (
      <span>
        <form
          ref= 'form'
          className= 'hidden'
        >
          <input
            type='file'
            ref='addFileInput'
            onChange= {this.handleFilesInputChange}
            multiple= {true}
          />
        </form>
        <button
          type= 'button'
          className= 'btn btn-primary btn-upload'
          onClick= {this.handleAddFilesClick}
        >
          <i className='icon-upload' aria-hidden />&nbsp;
          <span className= {this.hiddenPhoneClassname()} >
            { I18n.t('Upload') }
          </span>
        </button>
        { this.buildPotentialModal() }
      </span>
    );
  }

export default React.createClass(UploadButton)
