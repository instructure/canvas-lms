#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!file_rename_form'
  'react'
  'react-dom',
  'prop-types'
], (I18n, React, ReactDOM, PropTypes) ->

  FileRenameForm =
    displayName: 'FileRenameForm'

    # dialog for renaming

    propType:
      fileOptions: PropTypes.object
      onNameConflictResolved: PropTypes.func.isRequired

    getInitialState: ->
      isEditing: false
      fileOptions: @props.fileOptions

    componentWillReceiveProps: (newProps) ->
      @setState(fileOptions: newProps.fileOptions, isEditing: false)

    handleRenameClick: ->
      @setState isEditing: true

    handleBackClick: ->
      @setState isEditing: false

    # pass back expandZip to preserve options that was possibly already made
    # in a previous modal
    handleReplaceClick: ->
      @refs.canvasModal.closeModal() if @props.closeOnResolve
      @props.onNameConflictResolved({
        file: @state.fileOptions.file
        dup: 'overwrite'
        name: @state.fileOptions.name
        expandZip: @state.fileOptions.expandZip
      })

    # pass back expandZip to preserve options that was possibly already made
    # in a previous modal
    handleChangeClick: ->
      @refs.canvasModal.closeModal() if @props.closeOnResolve
      @props.onNameConflictResolved({
        file: @state.fileOptions.file
        dup: 'rename'
        name: ReactDOM.findDOMNode(@refs.newName).value
        expandZip: @state.fileOptions.expandZip
      })

    handleFormSubmit: (e) ->
      e.preventDefault()
      @handleChangeClick()
