/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!upload_button'
import React from 'react'
import createReactClass from 'create-react-class';
import FileRenameForm from '../files/FileRenameForm'
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

export default createReactClass(UploadButton);
