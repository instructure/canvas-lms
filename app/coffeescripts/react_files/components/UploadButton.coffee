define [
  'i18n!upload_button'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/UploadQueue'
  'underscore'
], (I18n, React, withReactDOM, UploadQueue, _) ->

  UploadButton = React.createClass

    propTypes:
      currentFolder: React.PropTypes.object # not required as we don't have it on the first render

    getDefaultState: ->
      return {
        filesToUpload: []
        nameCollisions: []
      }

    fileNameExists: (selectedFiles, name) ->
      found = _.find @props.currentFolder.files.models, (f) ->
        f.get('display_name') == name

    findNameCollisions: (selectedFiles) ->
      i = 0
      collisions = []
      while i < selectedFiles.length
        f = selectedFiles.item(i)
        if @fileNameExists selectedFiles, f.name
          collisions.push f
        i++
      collisions

    queueUploads: (selectedFiles) ->
      j = 0
      while j<selectedFiles.length
        UploadQueue.enqueue(selectedFiles.item(j), this.props.currentFolder)
        j++

    handleAddFilesClick: ->
      this.refs.addFileInput.getDOMNode().click()

    handleFilesInputChange: (e) ->
      selectedFiles = this.refs.addFileInput.getDOMNode().files
      collisions = @findNameCollisions(selectedFiles)
      if collisions.length > 0
        console.log(collisions.length + " file name collisions, uploading anyway for now")
      else
        # TODO:  only upload once naming collisions are resolved in CNVS-12667
      @queueUploads(selectedFiles)


    render: withReactDOM ->
      div {},
        input
          type:'file'
          className:'hidden'
          ref:'addFileInput'
          onChange: @handleFilesInputChange
          multiple: true
        button className:'btn btn-primary', onClick: @handleAddFilesClick,
          i className:'icon-plus'
          I18n.t('files', 'Files')
