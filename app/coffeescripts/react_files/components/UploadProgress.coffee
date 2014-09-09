define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/FileUploader'
], (React, withReactDOM, FileUploader) ->

  UploadProgressView = React.createClass

    propTypes:
      uploader: React.PropTypes.instanceOf(FileUploader).isRequired

    getLabel: withReactDOM ->
      span {},
        i className: 'icon-document'
        span ref: 'fileName', @props.uploader.getFileName()

    createWidthStyle: ->
      width: "#{@props.uploader.roundProgress()}%"

    render: withReactDOM ->
      almostDone = ''
      almostDone = ' almost-done' if @props.uploader.roundProgress() == 100
      div className: 'upload-progress-view',
        div className: 'upload-progress-view__label',
          div {},
            @getLabel()
        div ref: 'container', className: 'upload-progress-view__bar-container' + almostDone,
          div
            ref: 'bar'
            className: 'upload-progress-view__bar' + almostDone
            ref: 'bar'
            style: @createWidthStyle()
