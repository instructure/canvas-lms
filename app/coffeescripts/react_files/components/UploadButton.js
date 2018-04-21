/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import customPropTypes from '../modules/customPropTypes'
import FileOptionsCollection from '../modules/FileOptionsCollection'

let resolvedUserAction = false

export default {
  displayName: 'UploadButton',

  propTypes: {
    currentFolder: customPropTypes.folder, // not required as we don't have it on the first render
    contextId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    contextType: PropTypes.string
  },

  getInitialState() {
    return FileOptionsCollection.getState()
  },

  queueUploads() {
    ReactDOM.findDOMNode(this.refs.form).reset()
    return FileOptionsCollection.queueUploads(this.props.contextId, this.props.contextType)
  },

  handleAddFilesClick() {
    return ReactDOM.findDOMNode(this.refs.addFileInput).click()
  },

  handleFilesInputChange(e) {
    resolvedUserAction = false
    const {files} = ReactDOM.findDOMNode(this.refs.addFileInput)
    FileOptionsCollection.setFolder(this.props.currentFolder)
    FileOptionsCollection.setOptionsFromFiles(files)
    this.setState(FileOptionsCollection.getState())
  },

  onNameConflictResolved(fileNameOptions) {
    FileOptionsCollection.onNameConflictResolved(fileNameOptions)
    resolvedUserAction = true
    this.setState(FileOptionsCollection.getState())
  },

  onZipOptionsResolved(fileNameOptions) {
    FileOptionsCollection.onZipOptionsResolved(fileNameOptions)
    resolvedUserAction = true
    this.setState(FileOptionsCollection.getState())
  },

  onClose() {
    ReactDOM.findDOMNode(this.refs.form).reset()
    if (!resolvedUserAction) {
      // user dismissed zip or name conflict modal without resolving things
      // reset state to dump previously selected files
      FileOptionsCollection.resetState()
      this.setState(FileOptionsCollection.getState())
    }
    resolvedUserAction = false
  },

  componentDidUpdate(prevState) {
    if (
      this.state.zipOptions.length === 0 &&
      this.state.nameCollisions.length === 0 &&
      this.state.resolvedNames.length > 0 &&
      FileOptionsCollection.hasNewOptions()
    ) {
      this.queueUploads()
    } else {
      resolvedUserAction = false
    }
  },

  componentWillMount() {
    FileOptionsCollection.onChange = this.setStateFromOptions
  },

  componentWillUnMount() {
    FileOptionsCollection.onChange = null
  },

  setStateFromOptions() {
    this.setState(FileOptionsCollection.getState())
  }
}
