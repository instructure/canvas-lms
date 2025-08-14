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
import createReactClass from 'create-react-class'
import FileRenameForm from './LegacyFileRenameForm'
import Modal from '@canvas/modal'
import ModalContent from '@canvas/modal/react/content'
import ModalButtons from '@canvas/modal/react/buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('file_rename_form')

// Use UNSAFE_componentWillMount to match React's migration path
// This will suppress the warning while maintaining the same behavior
FileRenameForm.UNSAFE_componentWillMount = function () {
  this.bodyContentRef = React.createRef()
  this.newNameRef = React.createRef()
  this.commitChangeBtnRef = React.createRef()
  this.renameBtnRef = React.createRef()
  this.replaceBtnRef = React.createRef()
  this.skipBtnRef = React.createRef()
  this.backBtnRef = React.createRef()
  this.canvasModalRef = React.createRef()
}

FileRenameForm.buildContent = function () {
  const {onRenameFileMessage, onLockFileMessage} = this.props
  const nameToUse = this.state.fileOptions.name || this.state.fileOptions.file.name
  let buildContentToRender
  if (!this.state.isEditing && !this.state.fileOptions.cannotOverwrite) {
    buildContentToRender = (
      <div ref={this.bodyContentRef}>
        <p id="renameFileMessage">
          {onRenameFileMessage?.(nameToUse) ||
            I18n.t(
              'An item named "%{name}" already exists in this location. Do you want to replace the existing file?',
              {name: nameToUse},
            )}
        </p>
      </div>
    )
  } else {
    let renameMessage
    if (this.state.fileOptions.cannotOverwrite) {
      renameMessage =
        onLockFileMessage?.(nameToUse) ||
        I18n.t(
          'A locked item named "%{name}" already exists in this location. Please enter a new name.',
          {name: nameToUse},
        )
    } else {
      renameMessage = I18n.t('Change "%{name}" to', {name: nameToUse})
    }

    buildContentToRender = (
      <div ref={this.bodyContentRef}>
        <p>{renameMessage}</p>
        <form onSubmit={this.handleFormSubmit}>
          <label className="file-rename-form__form-label" htmlFor="renameFileInput">
            {I18n.t('Name')}
          </label>
          <input
            id="renameFileInput"
            className="input-block-level"
            type="text"
            defaultValue={nameToUse}
            ref={this.newNameRef}
            aria-label={I18n.t('File name')}
          />
        </form>
      </div>
    )
  }

  return buildContentToRender
}

FileRenameForm.buildButtons = function () {
  let buildButtonsToRender
  if (this.state.fileOptions.cannotOverwrite) {
    buildButtonsToRender = [
      <button
        type="button"
        key="commitChangeBtn"
        ref={this.commitChangeBtnRef}
        className="btn btn-primary"
        onClick={this.handleChangeClick}
      >
        {I18n.t('Change')}
      </button>,
    ]
  } else if (!this.state.isEditing) {
    buildButtonsToRender = [
      <button
        type="button"
        key="renameBtn"
        ref={this.renameBtnRef}
        className="btn btn-default"
        onClick={this.handleRenameClick}
      >
        {I18n.t('Change Name')}
      </button>,
      <button
        type="button"
        key="replaceBtn"
        ref={this.replaceBtnRef}
        className="btn btn-primary"
        onClick={this.handleReplaceClick}
      >
        {I18n.t('Replace')}
      </button>,
    ]
    if (this.props.allowSkip) {
      buildButtonsToRender.unshift(
        <button
          type="button"
          key="skipBtn"
          ref={this.skipBtnRef}
          className="btn btn-default"
          onClick={this.handleSkipClick}
        >
          {I18n.t('Skip')}
        </button>,
      )
    }
  } else {
    buildButtonsToRender = [
      <button
        type="button"
        key="backBtn"
        ref={this.backBtnRef}
        className="btn btn-default"
        onClick={this.handleBackClick}
      >
        {I18n.t('Back')}
      </button>,
      <button
        type="button"
        key="commitChangeBtn"
        ref={this.commitChangeBtnRef}
        className="btn btn-primary"
        onClick={this.handleChangeClick}
      >
        {I18n.t('Change')}
      </button>,
    ]
  }

  return buildButtonsToRender
}

FileRenameForm.render = function () {
  return (
    <div>
      <Modal
        className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
        ref={this.canvasModalRef}
        isOpen={this.props.fileOptions}
        title={I18n.t('Copy')}
        onRequestClose={this.props.onClose}
        closeWithX={this.props.closeWithX}
      >
        <ModalContent>
          {this.buildContent()}
          <ModalButtons>{this.buildButtons()}</ModalButtons>
        </ModalContent>
      </Modal>
    </div>
  )
}

export default createReactClass(FileRenameForm)
