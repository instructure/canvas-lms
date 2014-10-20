define [
  'i18n!upload_button'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'underscore'
  './FileRenameForm'
  '../modules/customPropTypes'
  './ZipFileOptionsForm'
  '../modules/FileOptionsCollection'
], (I18n, React, withReactDOM, _, FileRenameForm, customPropTypes, ZipFileOptionsForm, FileOptionsCollection) ->

  UploadButton = React.createClass
    displayName: 'UploadButton'

    propTypes:
      currentFolder: customPropTypes.folder # not required as we don't have it on the first render
      contextId: React.PropTypes.string
      contextType: React.PropTypes.string

    getInitialState: ->
      return FileOptionsCollection.getState()

    queueUploads: ->
      @refs.form.getDOMNode().reset()
      FileOptionsCollection.queueUploads(@props.contextId, @props.contextType)

    handleAddFilesClick: ->
      this.refs.addFileInput.getDOMNode().click()

    handleFilesInputChange: (e) ->
      files = this.refs.addFileInput.getDOMNode().files
      FileOptionsCollection.setFolder(@props.currentFolder)
      FileOptionsCollection.setOptionsFromFiles(files)
      @setState(FileOptionsCollection.getState())

    onNameConflictResolved: (fileNameOptions) ->
      FileOptionsCollection.onNameConflictResolved(fileNameOptions)
      @setState(FileOptionsCollection.getState())

    onZipOptionsResolved: (fileNameOptions) ->
      FileOptionsCollection.onZipOptionsResolved(fileNameOptions)
      @setState(FileOptionsCollection.getState())

    onClose: ->
      @refs.form.getDOMNode().reset()

    componentDidUpdate: (prevState) ->
      if @state.nameCollisions.length == 0 && @state.resolvedNames.length > 0 && FileOptionsCollection.hasNewOptions()
        @queueUploads()

    render: withReactDOM ->
      span {},
        form
          ref: 'form'
          className: 'hidden',
          input
            type:'file'
            ref:'addFileInput'
            onChange: @handleFilesInputChange
            multiple: true
        button
          className:'btn btn-primary btn-upload'
          'aria-label': I18n.t('upload', 'Upload')
          onClick: @handleAddFilesClick,
            i className: 'icon-upload'
            span className: ('hidden-phone' if @props.showingButtons),
              I18n.t('upload', 'Upload')
        FileRenameForm
          fileOptions: @state.nameCollisions[0]
          onNameConflictResolved: @onNameConflictResolved
          onClose: @onClose
        ZipFileOptionsForm
          fileOptions: @state.zipOptions[0]
          onZipOptionsResolved: @onZipOptionsResolved
          onClose: @onClose
