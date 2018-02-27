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

export default {
  displayName: 'FileRenameForm',

  // dialog for renaming

  propType: {
    fileOptions: PropTypes.object,
    onNameConflictResolved: PropTypes.func.isRequired
  },

  getInitialState() {
    return {
      isEditing: false,
      fileOptions: this.props.fileOptions
    }
  },

  componentWillReceiveProps(newProps) {
    this.setState({fileOptions: newProps.fileOptions, isEditing: false})
  },

  handleRenameClick() {
    this.setState({isEditing: true})
  },

  handleBackClick() {
    this.setState({isEditing: false})
  },

  // pass back expandZip to preserve options that was possibly already made
  // in a previous modal
  handleReplaceClick() {
    if (this.props.closeOnResolve) this.refs.canvasModal.closeModal()
    return this.props.onNameConflictResolved({
      file: this.state.fileOptions.file,
      dup: 'overwrite',
      name: this.state.fileOptions.name,
      expandZip: this.state.fileOptions.expandZip
    })
  },

  // pass back expandZip to preserve options that was possibly already made
  // in a previous modal
  handleChangeClick() {
    if (this.props.closeOnResolve) this.refs.canvasModal.closeModal()
    return this.props.onNameConflictResolved({
      file: this.state.fileOptions.file,
      dup: 'rename',
      name: ReactDOM.findDOMNode(this.refs.newName).value,
      expandZip: this.state.fileOptions.expandZip
    })
  },

  handleFormSubmit(e) {
    e.preventDefault()
    return this.handleChangeClick()
  }
}
