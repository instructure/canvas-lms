define [
  'i18n!upload_button'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/UploadQueue'
  'underscore'
  './FileRenameForm'
  './DialogAdapter'
], (I18n, React, withReactDOM, UploadQueue, _, FileRenameForm, DialogAdapter) ->

  UploadButton = React.createClass

    ###
    FileOption:
      file: <File>
      dup: how to handle duplicate names rename || overwrite (used in api call)
      name: name by which to upload the file
    ###

    propTypes:
      currentFolder: React.PropTypes.object # not required as we don't have it on the first render

    getInitialState: ->
      return {
        resolvedNames: []
        nameCollisions: []
      }

    queueUploads: ->
      @state.resolvedNames.forEach (f) =>
        UploadQueue.enqueue(f, @props.currentFolder)

    toFilesOptionArray: (fList) ->
      files = []
      i = 0
      while i < fList.length
        files.push {file: fList.item(i)}
        i++
      files

    fileNameExists: (name) ->
      found = _.find @props.currentFolder.files.models, (f) ->
        f.get('display_name') == name

    # divide into existing naming collisions and resolved ones
    segregateCollisions: (selectedFiles) ->
      i = 0
      collisions = []
      resolved = []
      while i < selectedFiles.length
        fileOptions = selectedFiles[i]
        nameToTest = fileOptions.name || fileOptions.file.name
        if @fileNameExists(nameToTest) && fileOptions.dup != 'overwrite'
          collisions.push fileOptions
        else
          resolved.push fileOptions
        i++
      {collisions:collisions, resolved:resolved}

    handleAddFilesClick: ->
      this.refs.addFileInput.getDOMNode().click()

    handleFilesInputChange: (e) ->
      selectedFiles = @toFilesOptionArray(this.refs.addFileInput.getDOMNode().files)
      {resolved, collisions} = @segregateCollisions(selectedFiles)
      @setState({nameCollisions: collisions, resolvedNames: resolved})

    onNameConflictResolved: (fileNameOptions) ->
      nameCollisions = @state.nameCollisions
      resolvedNames = @state.resolvedNames

      resolvedNames.push fileNameOptions
      nameCollisions.shift()

      # redo conflict resolution, new name from user could still conflict
      {resolved, collisions} = @segregateCollisions(resolvedNames.concat nameCollisions)
      @setState({nameCollisions: collisions, resolvedNames: resolved})

    onClose: ->
      @refs.form.getDOMNode().reset()

    componentDidUpdate: (prevState) ->
      if @state.nameCollisions.length == 0 && @state.resolvedNames.length > 0
        @queueUploads()

    render: withReactDOM ->
      div {},
        form
          ref: 'form'
          className: 'hidden',
          input
            type:'file'
            ref:'addFileInput'
            onChange: @handleFilesInputChange
            multiple: true
        button className:'btn btn-primary', onClick: @handleAddFilesClick,
          i className:'icon-plus'
          I18n.t('files', 'Files')
        DialogAdapter open: @state.nameCollisions[0]?, title: I18n.t('rename_title', 'Copy'), onClose: @onClose,
          FileRenameForm fileOptions: @state.nameCollisions[0], onNameConflictResolved: @onNameConflictResolved
