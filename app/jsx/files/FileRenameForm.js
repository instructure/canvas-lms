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

import React from 'react'
import FileRenameForm from 'compiled/react_files/components/FileRenameForm'
import Modal from '../shared/modal'
import ModalContent from '../shared/modal-content'
import ModalButtons from '../shared/modal-buttons'
import I18n from 'i18n!file_rename_form'

  FileRenameForm.buildContent = function () {
    var nameToUse = this.state.fileOptions.name || this.state.fileOptions.file.name;
    var buildContentToRender;
    if (!this.state.isEditing && !this.state.fileOptions.cannotOverwrite) {
      buildContentToRender = (
        <div ref='bodyContent'>
          <p id='renameFileMessage'>
            {I18n.t('An item named "%{name}" already exists in this location. Do you want to replace the existing file?', {name: nameToUse})}
          </p>
        </div>
      );
    } else {
      var renameMessage;
      if (this.state.fileOptions.cannotOverwrite) {
        renameMessage = I18n.t('A locked item named "%{name}" already exists in this location. Please enter a new name.', {name: nameToUse});
      } else {
        renameMessage = I18n.t('Change "%{name}" to', {name: nameToUse});
      }

      buildContentToRender = (
        <div ref='bodyContent'>
          <p>
            {renameMessage}
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
    if (this.state.fileOptions.cannotOverwrite) {
      buildButtonsToRender = (
        [
          <button
            key='commitChangeBtn'
            ref='commitChangeBtn'
            className='btn btn-primary'
            onClick={this.handleChangeClick}
          >
            {I18n.t('Change')}
          </button>
        ]
      );
    } else if (!this.state.isEditing) {
      buildButtonsToRender = (
        [
          <button
            key='renameBtn'
            ref='renameBtn'
            className='btn btn-default'
            onClick={this.handleRenameClick}
          >
            {I18n.t('Change Name')}
          </button>
         ,
          <button
            key='replaceBtn'
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
            key='backBtn'
            ref='backBtn'
            className='btn btn-default'
            onClick={this.handleBackClick}
          >
            {I18n.t('Back')}
          </button>
        ,
          <button
            key='commitChangeBtn'
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

export default React.createClass(FileRenameForm)
