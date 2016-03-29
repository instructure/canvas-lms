define [
  'i18n!react_files'
  'react'
  'jquery'
  'compiled/jquery.rails_flash_notifications'
], (I18n, React, $) ->


  UploadProgress =
    displayName: 'UploadProgress'

    propTypes:
      uploader: React.PropTypes.shape({
        getFileName: React.PropTypes.func.isRequired
        roundProgress: React.PropTypes.func.isRequired
        cancel: React.PropTypes.func.isRequired
        file: React.PropTypes.instanceOf(File).isRequired
      })

    getInitialState: ->
      progress: 0
      messages: {}

    componentWillMount: ->
      @sendProgressUpdate @state.progress

    componentWillReceiveProps: (nextProps) ->
      newProgress = nextProps.uploader.roundProgress()

      if @state.progress isnt newProgress
        @sendProgressUpdate(newProgress)

    componentWillUnmount: ->
      @sendProgressUpdate @state.progress

    sendProgressUpdate: (progress) ->
      # Track which status updates have been sent to prevent duplicate messages
      messages = @state.messages

      unless progress of messages
        fileName = @props.uploader.getFileName()

        message = if progress < 100
                    I18n.t("%{fileName} - %{progress} percent uploaded", { fileName, progress })
                  else
                    I18n.t("%{fileName} uploaded successfully!", { fileName })

        $.screenReaderFlashMessage message
        messages[progress] = true

        @setState { messages, progress }