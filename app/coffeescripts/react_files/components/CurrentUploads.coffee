define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/UploadQueue'
  './UploadProgress'
  'compiled/jquery.rails_flash_notifications'
], (React, withReactDOM, UploadQueue, UploadProgress) ->

  CurrentUploads = React.createClass
    displayName: 'CurrentUploads'

    getInitialState: ->
      currentUploads: []
      isOpen: false

    componentWillMount: ->
      UploadQueue.onChange = =>
        @screenReaderUploadStatus()
        @setState(currentUploads: UploadQueue.getAllUploaders())

    componentWillUnMount: ->
      UploadQueue.onChange = ->
        #noop
    handleCloseClick: ->
      @setState isOpen: false

    handleBrowseClick: ->
      console.log('browse click')

    screenReaderUploadStatus: ->
      currentUploader = UploadQueue.getCurrentUploader()
      return if !currentUploader
      name = currentUploader.getFileName()
      percent = currentUploader.roundProgress()
      $.screenReaderFlashMessage "#{name} - #{percent}%"

    shouldDisplay: ->
      !!@state.isOpen || @state.currentUploads.length

    buildProgressViews: ->
      progressBars = @state.currentUploads.map (uploader) ->
        UploadProgress uploader: uploader, key: uploader.getFileName(), removeUploader: UploadQueue.remove
      div className: 'current_uploads__uploaders',
        progressBars

    buildContent: ->
      if @state.currentUploads.length
        @buildProgressViews()
      else if !!@state.isOpen
        div {}, ''

    render: withReactDOM ->
      divName = ''
      divName = 'current_uploads' if @shouldDisplay()
      div className: divName,
        @buildContent()
