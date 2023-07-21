/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {instanceOf, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {getCourseRootFolder, getFolderFiles} from './apiClient'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {IconUploadLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import BaseUploader from '@canvas/files/react/modules/BaseUploader'
import CurrentUploads from '@canvas/files/react/components/CurrentUploads'
import FilesystemObject from '@canvas/files/backbone/models/FilesystemObject'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import UploadForm from '@canvas/files/react/components/UploadForm'

const I18n = useI18nScope('modules')

export default class ModuleFileDrop extends React.Component {
  static propTypes = {
    courseId: string.isRequired,
    moduleId: string.isRequired,
    contextModules: instanceOf(Element),
  }

  static defaultProps = {
    contextModules: null,
  }

  static folderState = {}

  static activeDrops = new Set()

  constructor(props) {
    super(props)
    this.state = {
      hightlightUpload: false,
      isUploading: false,
      folder: null,
      contextType: null,
      contextId: null,
      interaction: true,
    }
  }

  componentDidMount() {
    if (Object.keys(ModuleFileDrop.folderState).length > 0) {
      this.setFolderState(ModuleFileDrop.folderState)
    }
    if (ModuleFileDrop.activeDrops.size === 0) {
      this.fetchRootFolder()
    }
    ModuleFileDrop.activeDrops.add(this)
  }

  fetchRootFolder() {
    return getCourseRootFolder(this.props.courseId)
      .then(rootFolder => {
        return getFolderFiles(rootFolder.id)
          .then(files => {
            rootFolder.files = files
            ModuleFileDrop.folderState = {
              contextId: rootFolder.context_id,
              contextType: rootFolder.context_type,
              folder: rootFolder,
            }
            ModuleFileDrop.activeDrops.forEach(drop => {
              drop.setFolderState(ModuleFileDrop.folderState)
            })
          })
          .catch(this.showAlert)
      })
      .catch(this.showAlert)
  }

  showAlert = () => {
    showFlashAlert({
      type: 'error',
      message: I18n.t('Unable to set up drag and drop for modules'),
    })
  }

  addFile(file) {
    ModuleFileDrop.folderState.folder.files = [
      ...ModuleFileDrop.folderState.folder.files,
      new FilesystemObject(file),
    ]
    ModuleFileDrop.activeDrops.forEach(drop => {
      drop.setFolderState(ModuleFileDrop.folderState)
    })
  }

  componentWillUnmount() {
    ModuleFileDrop.activeDrops.delete(this)
  }

  setFolderState(folderState) {
    this.setState(folderState)
  }

  handleDragEnter = () => {
    this.setState({hightlightUpload: true})
  }

  handleDragLeave = () => {
    this.setState({hightlightUpload: false})
  }

  handleDrop = files => {
    const {moduleId, contextModules} = this.props
    const {folder} = this.state
    this.setInteractionOnAll(false)
    // Setting the callback directly here (instead of the
    // constructor) because we may need to take back control
    // from select_content_dialog.js, which also uses this
    // callback to know when an upload is complete.
    BaseUploader.prototype.onUploadPosted = attachment => {
      this.addFile(attachment)
      if (contextModules) {
        const event = new Event('addFileToModule')
        event.moduleId = moduleId
        event.attachment = attachment
        contextModules.dispatchEvent(event)
      }
    }
    FileOptionsCollection.setUploadOptions({
      alwaysRename: false,
      alwaysUploadZips: true,
    })
    this.setState({hightlightUpload: false, isUploading: true}, () => {
      FileOptionsCollection.setFolder(folder)
      FileOptionsCollection.setOptionsFromFiles(files, true)
    })
  }

  renderHero(size) {
    const {hightlightUpload} = this.state
    return <IconUploadLine size={size} color={hightlightUpload ? 'brand' : 'primary'} />
  }

  renderBillboard() {
    const {folder} = this.state
    return (
      <Billboard
        heading={folder ? I18n.t('Drop files here to add to module') : I18n.t('Loading...')}
        headingLevel="h4"
        hero={size => this.renderHero(size)}
        message={
          <Text size="small" color="brand">
            {folder ? I18n.t('or choose files') : ''}
          </Text>
        }
      />
    )
  }

  setInteractionOnAll(interaction) {
    ModuleFileDrop.activeDrops.forEach(drop => drop.setInteraction(interaction))
  }

  setInteraction(interaction) {
    this.setState({interaction})
  }

  renderFileDrop() {
    const {interaction, folder} = this.state
    return (
      <FileDrop
        shouldAllowMultiple={true}
        renderLabel={this.renderBillboard()}
        onDragEnter={this.handleDragEnter}
        onDragLeave={this.handleDragLeave}
        onDrop={this.handleDrop}
        interaction={interaction && folder ? 'enabled' : 'disabled'}
      />
    )
  }

  handleEmptyUpload = () => {
    this.setState({isUploading: false})
    this.setInteractionOnAll(true)
  }

  renameFileMessage = nameToUse => {
    return I18n.t(
      'A file named "%{name}" already exists. Do you want to replace the existing file?',
      {name: nameToUse}
    )
  }

  lockFileMessage = nameToUse => {
    return I18n.t('A locked file named "%{name}" already exists. Please enter a new name.', {
      name: nameToUse,
    })
  }

  renderUploading() {
    const {folder, contextId, contextType} = this.state
    return (
      <>
        <UploadForm
          visible={false}
          currentFolder={folder}
          contextId={contextId}
          contextType={contextType}
          allowSkip={true}
          alwaysUploadZips={true}
          onEmptyOrClose={this.handleEmptyUpload}
          onRenameFileMessage={this.renameFileMessage}
          onLockFileMessage={this.lockFileMessage}
        />
        <CurrentUploads onUploadChange={this.handleUploadChange} />
      </>
    )
  }

  handleUploadChange = queueSize => {
    if (queueSize === 0) {
      this.setInteractionOnAll(true)
    }
    this.setState({isUploading: queueSize > 0})
  }

  render() {
    const {isUploading} = this.state
    return isUploading ? this.renderUploading() : this.renderFileDrop()
  }
}
