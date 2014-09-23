define [
  'i18n!file_rename_form'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  './DialogAdapter'
  './DialogContent'
  './DialogButtons'
], (I18n, React, withReactDOM, DialogAdapter, DialogContent, DialogButtons) ->

  FileRenameForm = React.createClass

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

    handleReplaceClick: ->
      @props.onNameConflictResolved({file: @state.fileOptions.file, dup: 'overwrite'})

    handleChangeClick: ->
      @props.onNameConflictResolved({file: @state.fileOptions.file, dup: 'rename', name: @refs.newName.getDOMNode().value})

    handleFormSubmit: (e) ->
      e.preventDefault()
      @handleChangeClick()

    buildContent: withReactDOM ->
      nameToUse = @state.fileOptions?.name || @state.fileOptions?.file.name
      if !@state.isEditing
        div {},
          p {}, I18n.t('message','An item named "%{name}" already exists in this location. Do you want to replace the existing file?', {name: nameToUse})
      else
        div {},
          p {}, I18n.t('prompt', 'Change "%{name}" to', {name: nameToUse})
          form onSubmit: @handleFormSubmit,
            label className: 'file-rename-form__form-label',
              I18n.t('name', 'Name')
            input type: 'text', defaultValue: nameToUse, ref: 'newName'

    buildButtons: withReactDOM ->
      if !@state.isEditing
        div {},
          button
            ref: 'renameBtn'
            className: 'btn'
            onClick: @handleRenameClick,
              (I18n.t('change_name', 'Change Name'))
          button
            ref: 'replaceBtn'
            className: 'btn btn-primary'
            onClick: @handleReplaceClick,
              (I18n.t('replace', 'Replace'))
      else
        div {},
          button
            ref: 'backBtn'
            className: 'btn'
            onClick: @handleBackClick,
              I18n.t('back', 'Back')
          button
            ref: 'commitChangeBtn'
            className: 'btn btn-primary'
            onClick: @handleChangeClick,
              I18n.t('change', 'Change')



    render: withReactDOM ->
      DialogAdapter open: @props.fileOptions?, title: I18n.t('rename_title', 'Copy'), onClose: @props.onClose,
        DialogContent {},
          @buildContent()
        DialogButtons {},
          @buildButtons()
