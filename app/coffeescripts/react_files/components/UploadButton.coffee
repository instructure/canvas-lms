define [
  'i18n!upload_button'
  'react'
  'underscore'
  '../modules/customPropTypes'
  '../modules/FileOptionsCollection'
], (I18n, React, _, customPropTypes, FileOptionsCollection) ->

  resolvedUserAction = false

  UploadButton =
    displayName: 'UploadButton'

    propTypes:
      currentFolder: customPropTypes.folder # not required as we don't have it on the first render
      contextId: React.PropTypes.oneOfType [React.PropTypes.string, React.PropTypes.number]
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
