define [
  'react'
  'compiled/react/shared/utils/withReactElement'
  '../modules/UploadQueue'
  './UploadProgress'
  'compiled/jquery.rails_flash_notifications'
], (React, withReactElement, UploadQueue, UploadProgressComponent) ->

  UploadProgress = React.createFactory UploadProgressComponent

  CurrentUploads = React.createClass
    displayName: 'CurrentUploads'

    getInitialState: ->
      currentUploads: []

    componentWillMount: ->
      UploadQueue.onChange = =>
        @screenReaderUploadStatus()
        @setState(currentUploads: UploadQueue.getAllUploaders())

    componentWillUnmount: ->
      UploadQueue.onChange = -> #noop

    screenReaderUploadStatus: ->
      currentUploader = UploadQueue.getCurrentUploader()
      return if !currentUploader
      name = currentUploader.getFileName()
      percent = currentUploader.roundProgress()
      $.screenReaderFlashMessage "#{name} - #{percent}%"

    render: withReactElement ->
      div className: ('current_uploads' if @state.currentUploads.length),
        if @state.currentUploads.length
          div className: 'current_uploads__uploaders',
            @state.currentUploads.map (uploader) ->
              UploadProgress
                uploader: uploader
                key: uploader.getFileName()
