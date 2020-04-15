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
import {bool, func, number, object, oneOfType, string} from 'prop-types'
import FileRenameForm from './FileRenameForm'
import ZipFileOptionsForm from './ZipFileOptionsForm'
import FileOptionsCollection from 'compiled/react_files/modules/FileOptionsCollection'

export const UploadFormPropTypes = {
  contextId: oneOfType([string, number]).isRequired,
  contextType: string.isRequired,
  currentFolder: object, // could be instanceOf(Folder), but if I import 'compiled/models/Folder', jest fails to run
  visible: bool,
  inputId: string,
  inputName: string,
  autoUpload: bool,
  disabled: bool,
  onChange: func
}

class UploadForm extends React.Component {
  static propTypes = UploadFormPropTypes

  static defaultProps = {
    autoUpload: true,
    disabled: false
  }

  constructor(props) {
    super(props)

    this.formRef = React.createRef()
    this.addFileInputRef = React.createRef()
    this.resolvedUserAction = false
    this.state = {...FileOptionsCollection.getState()}
    this.setFolder(props.currentFolder)
  }

  setFolder(folder) {
    FileOptionsCollection.setFolder(folder)
  }

  getFolder() {
    return FileOptionsCollection.getFolder()
  }

  queueUploads() {
    this.formRef.current.reset()
    return FileOptionsCollection.queueUploads(this.props.contextId, this.props.contextType)
  }

  addFiles = () => {
    return this.addFileInputRef.current.click()
  }

  handleFilesInputChange = e => {
    if (this.props.onChange) {
      this.props.onChange(e)
    }
    this.resolvedUserAction = false
    FileOptionsCollection.setOptionsFromFiles(e.target.files)
    this.setState(FileOptionsCollection.getState())
  }

  onNameConflictResolved = fileNameOptions => {
    FileOptionsCollection.onNameConflictResolved(fileNameOptions)
    this.resolvedUserAction = true
    this.setState(FileOptionsCollection.getState())
  }

  onZipOptionsResolved = fileNameOptions => {
    FileOptionsCollection.onZipOptionsResolved(fileNameOptions)
    this.resolvedUserAction = true
    this.setState(FileOptionsCollection.getState())
  }

  onClose = () => {
    this.formRef.current.reset()
    if (!this.resolvedUserAction) {
      // user dismissed zip or name conflict modal without resolving things
      // reset state to dump previously selected files
      FileOptionsCollection.resetState()
      this.setState(FileOptionsCollection.getState())
    }
    this.resolvedUserAction = false
  }

  componentDidUpdate() {
    this.setFolder(this.props.currentFolder)

    if (
      this.props.autoUpload &&
      this.state.zipOptions.length === 0 &&
      this.state.nameCollisions.length === 0 &&
      this.state.resolvedNames.length > 0 &&
      FileOptionsCollection.hasNewOptions()
    ) {
      this.queueUploads()
    } else {
      this.resolvedUserAction = false
    }
  }

  UNSAFE_componentWillMount() {
    FileOptionsCollection.onChange = this.setStateFromOptions
  }

  componentWillUnMount() {
    FileOptionsCollection.onChange = null
  }

  setStateFromOptions = () => {
    this.setState(FileOptionsCollection.getState())
  }

  buildPotentialModal() {
    if (this.state.zipOptions.length) {
      return (
        <ZipFileOptionsForm
          fileOptions={this.state.zipOptions[0]}
          onZipOptionsResolved={this.onZipOptionsResolved}
          onClose={this.onClose}
        />
      )
    } else if (this.state.nameCollisions.length) {
      return (
        <FileRenameForm
          fileOptions={this.state.nameCollisions[0]}
          onNameConflictResolved={this.onNameConflictResolved}
          onClose={this.onClose}
          allowSkip={window?.ENV?.FEATURES?.files_dnd}
        />
      )
    }
  }

  render() {
    return (
      <span>
        <form ref={this.formRef} className={this.props.visible ? '' : 'hidden'}>
          <input
            id={this.props.inputId}
            name={this.props.inputName}
            type="file"
            ref={this.addFileInputRef}
            onChange={this.handleFilesInputChange}
            multiple
            data-testid="file-input"
            disabled={this.props.disabled}
          />
        </form>
        {this.buildPotentialModal()}
      </span>
    )
  }
}

export default UploadForm
