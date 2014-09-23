define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/FileUploader'
  './ProgressBar'
], (React, withReactDOM, FileUploader, ProgressBar) ->

  UploadProgress = React.createClass
    displayName: 'UploadProgress'

    propTypes:
      uploader: React.PropTypes.shape({
        getFileName: React.PropTypes.func.isRequired
        roundProgress: React.PropTypes.func.inRequired
      })

    getLabel: withReactDOM ->
      span {},
        i className: 'icon-document'
        span ref: 'fileName', @props.uploader.getFileName()

    render: withReactDOM ->
      progress = @props.uploader.roundProgress()
      div className: 'upload-progress-view',
        div className: 'upload-progress-view__label',
          div {},
            @getLabel()
        ProgressBar progress: progress
