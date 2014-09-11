define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/FileUploader'
  './ProgressBar'
], (React, withReactDOM, FileUploader, ProgressBar) ->

  UploadProgressView = React.createClass

    propTypes:
      uploader: React.PropTypes.instanceOf(FileUploader).isRequired

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
