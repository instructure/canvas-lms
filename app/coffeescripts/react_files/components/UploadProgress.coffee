define [
  'i18n!react_files'
  'react'
  'compiled/react/shared/utils/withReactDOM'
  '../modules/FileUploader'
  './ProgressBar'
], (I18n, React, withReactDOM, FileUploader, ProgressBar) ->

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

    handleCancelUpload: (event) ->
      event.preventDefault()
      alert('Cancel this upload: Completed in 16087')

    render: withReactDOM ->
      progress = @props.uploader.roundProgress()
      div className: 'upload-progress-view',
        div className: 'upload-progress-view__label',
          div {},
            @getLabel()
        ProgressBar progress: progress
        button onClick: @handleCancelUpload, 'aria-label': I18n.t('cancel_button.label', "Cancel %{fileName} from uploading", fileName: @props.uploader.getFileName()), className: 'btn-link upload-progress-view__button', 'x',
    displayName: I18n.t('name', 'Name')
