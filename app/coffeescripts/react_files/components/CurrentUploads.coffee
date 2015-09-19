define [
  'react'
  '../modules/UploadQueue'
  'jsx/files/UploadProgress'
  'compiled/jquery.rails_flash_notifications'
], (React, UploadQueue, UploadProgressComponent) ->

  CurrentUploads =
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
