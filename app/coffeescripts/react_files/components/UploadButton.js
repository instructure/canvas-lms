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
  'i18n!upload_button'
  'react'
  'react-dom'
  'prop-types'
  'underscore'
  '../modules/customPropTypes'
  '../modules/FileOptionsCollection'
], (I18n, React, ReactDOM, PropTypes, _, customPropTypes, FileOptionsCollection) ->

  resolvedUserAction = false

  UploadButton =
    displayName: 'UploadButton'

    propTypes:
      currentFolder: customPropTypes.folder # not required as we don't have it on the first render
      contextId: PropTypes.oneOfType [PropTypes.string, PropTypes.number]
      contextType: PropTypes.string

    getInitialState: ->
      return FileOptionsCollection.getState()

    queueUploads: ->
      ReactDOM.findDOMNode(@refs.form).reset()
      FileOptionsCollection.queueUploads(@props.contextId, @props.contextType)

    handleAddFilesClick: ->
      ReactDOM.findDOMNode(this.refs.addFileInput).click()

    handleFilesInputChange: (e) ->
      resolvedUserAction = false
      files = ReactDOM.findDOMNode(this.refs.addFileInput).files
      FileOptionsCollection.setFolder(@props.currentFolder)
      FileOptionsCollection.setOptionsFromFiles(files)
      @setState(FileOptionsCollection.getState())

    onNameConflictResolved: (fileNameOptions) ->
      FileOptionsCollection.onNameConflictResolved(fileNameOptions)
      resolvedUserAction = true
      @setState(FileOptionsCollection.getState())

    onZipOptionsResolved: (fileNameOptions) ->
      FileOptionsCollection.onZipOptionsResolved(fileNameOptions)
      resolvedUserAction = true
      @setState(FileOptionsCollection.getState())

    onClose: ->
      ReactDOM.findDOMNode(@refs.form).reset()
      if !resolvedUserAction
        # user dismissed zip or name conflict modal without resolving things
        # reset state to dump previously selected files
        FileOptionsCollection.resetState()
        @setState(FileOptionsCollection.getState())
      resolvedUserAction = false

    componentDidUpdate: (prevState) ->

      if @state.zipOptions.length == 0 && @state.nameCollisions.length == 0 && @state.resolvedNames.length > 0 && FileOptionsCollection.hasNewOptions()
        @queueUploads()
      else
        resolvedUserAction = false

    componentWillMount: ->
      FileOptionsCollection.onChange = @setStateFromOptions

    componentWillUnMount: ->
      FileOptionsCollection.onChange = null

    setStateFromOptions: ->
      @setState(FileOptionsCollection.getState())
