define [
  'i18n!file_rename_form'
  'old_unsupported_dont_use_react'
  'compiled/react/shared/utils/withReactDOM'
  './DialogAdapter'
  './DialogContent'
  './DialogButtons'
], (I18n, React, withReactDOM, DialogAdapter, DialogContent, DialogButtons) ->

  FileRenameForm = React.createClass
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

    clearNameField: ->
      $nameTextField = $(@refs.newName.getDOMNode())
      $nameTextField.val('').focus()

    handleRenameClick: ->
      @setState isEditing: true

    handleBackClick: ->
      @setState isEditing: false

    # pass back expandZip to preserve options that was possibly already made
    # in a previous modal
    handleReplaceClick: ->
      @refs.dialogAdapter.close() if @props.closeOnResolve
      @props.onNameConflictResolved({
        file: @state.fileOptions.file
        dup: 'overwrite'
        expandZip: @state.fileOptions.expandZip
      })

    # pass back expandZip to preserve options that was possibly already made
    # in a previous modal
    handleChangeClick: ->
      @refs.dialogAdapter.close() if @props.closeOnResolve
      @props.onNameConflictResolved({
        file: @state.fileOptions.file
        dup: 'rename'
        name: @refs.newName.getDOMNode().value
        expandZip: @state.fileOptions.expandZip
      })

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
          form className: 'ef-edit-name-form', onSubmit: @handleFormSubmit,
            label className: 'file-rename-form__form-label',
              I18n.t('name', 'Name')
            input(classNae: 'input-block-level', type: 'text', defaultValue: nameToUse, ref: 'newName'),
            button {
              type: 'button'
              className: 'btn btn-link ef-edit-name-cancel form-control-feedback'
              ref: 'clearNameFieldButton'
              'aria-label': I18n.t('Clear file name text field')
              onClick: @clearNameField
            },
              i className: 'icon-x'

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
      DialogAdapter ref: 'dialogAdapter', open: @props.fileOptions?, title: I18n.t('rename_title', 'Copy'), onClose: @props.onClose,
        DialogContent {},
          @buildContent()
        DialogButtons {},
          @buildButtons()
