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

import _ from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import I18n from 'i18n!upload_drop_zone'
import FileOptionsCollection from 'compiled/react_files/modules/FileOptionsCollection'
import Folder from 'compiled/models/Folder'
import 'compiled/jquery.rails_flash_notifications'

class UploadDropZone extends React.Component {
  static displayName = 'UploadDropZone'

  static propTypes = {
    currentFolder: PropTypes.instanceOf(Folder)
  }

  state = {active: false}

  componentDidMount() {
    this.getParent().addEventListener('dragenter', this.onParentDragEnter)
    document.addEventListener('dragenter', this.killWindowDropDisplay)
    document.addEventListener('dragover', this.killWindowDropDisplay)
    document.addEventListener('drop', this.killWindowDrop)
  }

  componentWillUnmount() {
    this.getParent().removeEventListener('dragenter', this.onParentDragEnter)
    document.removeEventListener('dragenter', this.killWindowDropDisplay)
    document.removeEventListener('dragover', this.killWindowDropDisplay)
    document.removeEventListener('drop', this.killWindowDrop)
  }

  onDragEnter = e => {
    if (this.shouldAcceptDrop(e.dataTransfer)) {
      this.setState({active: true})
      e.dataTransfer.dropEffect = 'copy'
      e.preventDefault()
      e.stopPropagation() // keep event from getting to document
      return false
    } else {
      return true
    }
  }

  onDragLeave = e => {
    this.setState({active: false})
  }

  onDrop = e => {
    this.setState({active: false})
    FileOptionsCollection.setFolder(this.props.currentFolder)
    FileOptionsCollection.setOptionsFromFiles(e.dataTransfer.files, true)
    e.preventDefault()
    e.stopPropagation()
    return false
  }

  /* when you drag a file over the parent, make drop zone active
  # remainder of drag-n-drop events happen on dropzone
  */
  onParentDragEnter = e => {
    if (this.shouldAcceptDrop(e.dataTransfer)) {
      if (!this.state.active) {
        this.setState({active: true})
      }
    }
  }

  killWindowDropDisplay = e => {
    if (e.target != this.getParent()) {
      e.preventDefault()
    }
  }

  killWindowDrop = e => {
    e.preventDefault()
  }

  shouldAcceptDrop = dataTransfer => {
    if (dataTransfer) {
      return _.indexOf(dataTransfer.types, 'Files') >= 0
    }
  }

  getParent = () =>
    // We are actually returning the parent's parent here because that
    // gives a much more consistently sized container to start displaying
    // the drop zone overlay with.
    ReactDOM.findDOMNode(this).parentElement.parentElement

  buildNonActiveDropZone = () => <div className="UploadDropZone" />

  buildInstructions = () => (
    <div className="UploadDropZone__instructions">
      <i className="icon-upload UploadDropZone__instructions--icon-upload" />
      <div>
        <p className="UploadDropZone__instructions--drag">
          {I18n.t('drop_to_upload', 'Drop items to upload')}
        </p>
      </div>
    </div>
  )

  buildDropZone = () => (
    <div
      className="UploadDropZone UploadDropZone__active"
      onDrop={this.onDrop}
      onDragLeave={this.onDragLeave}
      onDragOver={this.onDragEnter}
      onDragEnter={this.onDragEnter}
    >
      {this.buildInstructions()}
    </div>
  )

  render() {
    if (this.state.active) {
      return this.buildDropZone()
    } else {
      return this.buildNonActiveDropZone()
    }
  }
}

export default UploadDropZone
