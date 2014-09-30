define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/FileUploader'
  'i18n!upload_progress_view'
], (React, withReactDOM, FileUploader, I18n) ->

  UploadProgressView = React.createClass

    propTypes:
      uploader: React.PropTypes.instanceOf(FileUploader).isRequired

    getProgressWithLabel: ->
      "#{@props.uploader.getFileName()} - #{@props.uploader.roundProgress()}%"

    createWidthStyle: ->
      width: "#{@props.uploader.roundProgress()}%"

    buildSpinner: withReactDOM ->
      img
        className: 'upload-progress-view__indeterminate'
        src:'/images/ajax-loader-black-on-white.gif'
        alt: I18n.t('processing', 'processing')

    render: withReactDOM ->
      div className: 'upload-progress-view',
        div className: 'upload-progress-view__label',
          div {},
            @getProgressWithLabel()
            @buildSpinner() if @props.uploader.roundProgress() == 100
        div className: 'upload-progress-view__bar-container',
          div
            className: 'upload-progress-view__bar'
            ref: 'bar'
            style: @createWidthStyle()
