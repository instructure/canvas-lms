define [
  'i18n!react_files'
  'react'
  '../modules/FileUploader'
], (I18n, React, FileUploader) ->


  UploadProgress =
    displayName: 'UploadProgress'

    propTypes:
      uploader: React.PropTypes.shape({
        getFileName: React.PropTypes.func.isRequired
        roundProgress: React.PropTypes.func.isRequired
        cancel: React.PropTypes.func.isRequired
        file: React.PropTypes.instanceOf(File).isRequired
      })
