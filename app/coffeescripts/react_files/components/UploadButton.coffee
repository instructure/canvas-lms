define [
  'i18n!upload_button'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/UploadQueue'
  'underscore'
  './FileRenameForm'
  './DialogAdapter'
  '../modules/customPropTypes'
], (I18n, React, withReactDOM, UploadQueue, _, FileRenameForm, DialogAdapter, customPropTypes) ->

  UploadButton = React.createClass
    displayName: 'UploadButton'

    ###
    FileOption:
      file: <File>
      dup: how to handle duplicate names rename || overwrite (used in api call)
      name: name by which to upload the file
    ###

    propTypes:
      currentFolder: customPropTypes.folder # not required as we don't have it on the first render

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
      span {},
        form
          ref: 'form'
          className: 'hidden',
          input
            type:'file'
            ref:'addFileInput'
            onChange: @handleFilesInputChange
            multiple: true
        button className:'btn btn-primary btn-upload', onClick: @handleAddFilesClick,
          i className: 'icon-upload'
          span className: ('hidden-phone' if @props.showingButtons),
            I18n.t('upload', 'Upload')
        FileRenameForm fileOptions: @state.nameCollisions[0], onNameConflictResolved: @onNameConflictResolved, onClose: @onClose
