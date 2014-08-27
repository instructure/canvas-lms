define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/UploadQueue'
  './UploadProgress'
  'compiled/jquery.rails_flash_notifications'
], (React, withReactDOM, UploadQueue, UploadProgress) ->

  CurrentUploads = React.createClass

    getInitialState: ->
      {currentUploads: []}

    componentWillMount: ->
      UploadQueue.onChange = =>
        @screenReaderUploadStatus()
        @setState(currentUploads: UploadQueue.getAllUploaders())

    componentWillUnMount: ->
      UploadQueue.onChange = ->
        #noop

    screenReaderUploadStatus: ->
      currentUploader = UploadQueue.getCurrentUploader()
      return if !currentUploader
      name = currentUploader.getFileName()
      percent = currentUploader.roundProgress()
      $.screenReaderFlashMessage "#{name} - #{percent}%"

    buildProgressViews: ->
      @state.currentUploads.map (uploader) ->
        UploadProgress uploader: uploader, key: uploader.getFileName()

    render: withReactDOM ->
      div className:'react_files_uploads',
        div className: 'react-files-uploads__uploaders',
          @buildProgressViews()
