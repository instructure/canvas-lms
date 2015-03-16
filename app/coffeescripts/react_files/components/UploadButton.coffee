define [
  'i18n!upload_button'
  'old_unsupported_dont_use_react'
  'compiled/react/shared/utils/withReactDOM'
  'underscore'
  './FileRenameForm'
  '../modules/customPropTypes'
  './ZipFileOptionsForm'
  '../modules/FileOptionsCollection'
], (I18n, React, withReactDOM, _, FileRenameForm, customPropTypes, ZipFileOptionsForm, FileOptionsCollection) ->

  resolvedUserAction = false

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
      resolvedUserAction = false
      files = this.refs.addFileInput.getDOMNode().files
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
      @refs.form.getDOMNode().reset()
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

    buildPotentialModal: ->
      if @state.zipOptions.length
        ZipFileOptionsForm
          fileOptions: @state.zipOptions[0]
          onZipOptionsResolved: @onZipOptionsResolved
          onClose: @onClose
      else if @state.nameCollisions.length
        FileRenameForm
          fileOptions: @state.nameCollisions[0]
          onNameConflictResolved: @onNameConflictResolved
          onClose: @onClose


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
          type: 'button'
          className:'btn btn-primary btn-upload'
          'aria-label': I18n.t('upload', 'Upload')
          onClick: @handleAddFilesClick,
            i className: 'icon-upload'
            span className: ('hidden-phone' if @props.showingButtons),
              I18n.t('upload', 'Upload')
        @buildPotentialModal()
