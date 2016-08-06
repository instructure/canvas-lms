define [
  'i18n!file_rename_form'
  'react'
  'react-dom'
], (I18n, React, ReactDOM) ->

  FileRenameForm =
    displayName: 'FileRenameForm'

    # dialog for renaming

    propType:
      fileOptions: React.PropTypes.object
      onNameConflictResolved: React.PropTypes.func.isRequired

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
