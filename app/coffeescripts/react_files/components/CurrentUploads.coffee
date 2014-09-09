define [
  'i18n!current_uploads'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/UploadQueue'
  './UploadProgress'
  'compiled/jquery.rails_flash_notifications'
], (I18n, React, withReactDOM, UploadQueue, UploadProgress) ->

  CurrentUploads = React.createClass

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

    buildInstructions: ->
      div className: 'current_uploads__instructions',
        a
          role: 'button'
          'aria-label': I18n.t('close', 'close')
          onClick: @handleCloseClick
          className: 'current_uploads__instructions__close',
            '\u2A09'
        i className: 'icon-upload current_uploads__instructions__icon-upload'
        div {},
          p className: 'current_uploads__instructions__drag',
            I18n.t('drag_files_here', 'Drag Folders and Files here')
          a
            role: 'button'
            onClick: @handleBrowseClick,
              I18n.t('click_to_browse', 'or click to browse your computer')

    shouldDisplay: ->
      !!@state.isOpen || @state.currentUploads.length

    buildProgressViews: ->
      progressBars = @state.currentUploads.map (uploader) ->
        UploadProgress uploader: uploader, key: uploader.getFileName()
      div className: 'current_uploads__uploaders',
        progressBars

    buildContent: ->
      if @state.currentUploads.length
        @buildProgressViews()
      else if !!@state.isOpen
        @buildInstructions()

    render: withReactDOM ->
      divName = ''
      divName = 'current_uploads' if @shouldDisplay()
      div className: divName,
        @buildContent()
