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
import PropTypes from 'prop-types'
import classnames from 'classnames'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {FileDrop} from '@instructure/ui-file-drop'
import {IconUploadLine} from '@instructure/ui-icons'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import Folder from '@canvas/files/backbone/models/Folder'
import '@canvas/rails-flash-notifications'
import CurrentUploads from '@canvas/files/react/components/CurrentUploads'

const I18n = useI18nScope('upload_drop_zone')

class FileUpload extends React.Component {
  static displayName = 'FileUpload'

  static propTypes = {
    currentFolder: PropTypes.instanceOf(Folder),
    filesDirectoryRef: PropTypes.oneOfType([
      PropTypes.func,
      PropTypes.shape({current: PropTypes.elementType}),
    ]),
  }

  state = {
    isUploading: false,
    isDragging: false,
  }

  componentDidMount() {
    this.getSurroundingBox().addEventListener('dragenter', this.handleDragEnter)
    // Capture dragleave events that occur outside of the window
    document.addEventListener('dragleave', this.handleDragLeave)
    document.addEventListener('dragenter', this.killWindowDrop)
    document.addEventListener('dragover', this.killWindowDrop)
    document.addEventListener('drop', this.killWindowDrop)
  }

  componentWillUnmount() {
    this.getSurroundingBox().removeEventListener('dragenter', this.handleDragEnter)
    document.removeEventListener('dragleave', this.handleDragLeave)
    document.removeEventListener('dragenter', this.killWindowDrop)
    document.removeEventListener('dragover', this.killWindowDrop)
    document.removeEventListener('drop', this.killWindowDrop)
  }

  killWindowDrop = e => {
    e.preventDefault()
  }

  getSurroundingBox = () => {
    // Return a ref of the file container here because that
    // gives a much more consistently sized container to start displaying
    // the file upload overlay with
    return this.props.filesDirectoryRef
  }

  handleDragEnter = e => {
    if (this.shouldAcceptDrop(e.dataTransfer)) {
      e.dataTransfer.dropEffect = 'copy'
      e.preventDefault()
      if (!(this.state.isDragging || this.state.isUploading)) {
        this.setState({isDragging: true})
      }
      return false
    } else {
      return true
    }
  }

  handleDragLeave = e => {
    const rect = this.getSurroundingBox().getBoundingClientRect()
    if (
      e.clientY < rect.top ||
      e.clientY >= rect.bottom ||
      e.clientX < rect.left ||
      e.clientX >= rect.right
    ) {
      this.setState({isDragging: false})
    }
  }

  handleParentDrop = e => {
    e.preventDefault()
    e.stopPropagation()
    this.handleDrop(e.dataTransfer.files)
  }

  handleDrop = files => {
    this.setState({isDragging: false})
    FileOptionsCollection.setFolder(this.props.currentFolder)
    FileOptionsCollection.setOptionsFromFiles(files, true)
  }

  shouldAcceptDrop = dataTransfer => {
    if (dataTransfer) {
      return dataTransfer.types.includes('Files')
    }
  }

  renderDropZone = () => {
    const {isDragging} = this.state
    const isEmpty = this.props.currentFolder.isEmpty()
    return (
      <FileDrop
        shouldAllowMultiple={true}
        // Called when dropping files or when clicking,
        // after the file dialog window exits successfully
        onDrop={this.handleDrop}
        renderLabel={
          <Billboard
            size="small"
            hero={<IconUploadLine color={isDragging ? `brand` : `primary`} />}
            as="div"
            headingAs="span"
            headingLevel="h2"
            heading={I18n.t('Drop files here to upload')}
            message={isEmpty && <Text color="brand">{I18n.t('or choose files')}</Text>}
          />
        }
      />
    )
  }

  handleUploadChange = queueSize => {
    this.setState({isUploading: queueSize > 0})
  }

  render() {
    const {isDragging, isUploading} = this.state
    const isEmptyFolder = this.props.currentFolder.isEmpty()
    const classes = classnames({
      FileUpload: true,
      FileUpload__full: isEmptyFolder && !isDragging,
      FileUpload__dragging: isDragging,
    })
    return (
      <>
        {isUploading || (
          <div className={classes} onDrop={this.handleParentDrop}>
            {this.renderDropZone()}
          </div>
        )}
        <CurrentUploads onUploadChange={this.handleUploadChange} />
      </>
    )
  }
}

export default FileUpload
