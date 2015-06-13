define [
  'i18n!react_files'
  'react'
  'compiled/react/shared/utils/withReactElement'
  '../modules/FileUploader'
  './ProgressBar'
  'compiled/util/mimeClass'
], (I18n, React, withReactElement, FileUploader, ProgressBarComponent, mimeClass) ->

  ProgressBar = React.createFactory ProgressBarComponent

  UploadProgress = React.createClass
    displayName: 'UploadProgress'

    propTypes:
      uploader: React.PropTypes.shape({
        getFileName: React.PropTypes.func.isRequired
        roundProgress: React.PropTypes.func.isRequired
        cancel: React.PropTypes.func.isRequired
        file: React.PropTypes.instanceOf(File).isRequired
      })

    render: withReactElement ->
      div className: "ef-item-row #{'text-error' if @props.uploader.error}",
        div className: 'col-xs-6',
          div className: 'media ellipsis',
            span className: 'pull-left',
              i className: "media-object mimeClass-#{mimeClass(@props.uploader.file.type)}"
            span className: 'media-body', ref: 'fileName',
              @props.uploader.getFileName()

        div className: 'col-xs-5',
          if @props.uploader.error
            span {},
              (
                if @props.uploader.error.message
                  I18n.t('Error: %{message}', {message: @props.uploader.error.message})
                else
                  I18n.t('Error uploading file.')
              ),
              button {
                className: 'btn-link'
                type: 'button'
                onClick: => @props.uploader.upload()
              },
                I18n.t('retry', 'Retry')
          else
            ProgressBar progress: @props.uploader.roundProgress()

        button {
          type: 'button'
          onClick: @props.uploader.cancel
          'aria-label': I18n.t('cancel', 'Cancel')
          className: 'btn-link upload-progress-view__button'
        },
          'x'
