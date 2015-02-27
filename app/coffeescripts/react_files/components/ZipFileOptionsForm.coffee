define [
  'i18n!zip_file_options_form'
  'react'
  'compiled/react/shared/utils/withReactElement'
  './DialogAdapter'
  './DialogContent'
  './DialogButtons'
], (I18n, React, withReactElement, DialogAdapterComponent, DialogContentComponent, DialogButtonsComponent) ->

  DialogAdapter = React.createFactory DialogAdapterComponent
  DialogContent = React.createFactory DialogContentComponent
  DialogButtons = React.createFactory DialogButtonsComponent

  ZipFileOptionsForm = React.createClass

    displayName: 'ZipFileOptionsForm'

    propTypes:
      onZipOptionsResolved: React.PropTypes.func.isRequired

    handleExpandClick: ->
      @props.onZipOptionsResolved({file: @props.fileOptions.file, expandZip: true})

    handleUploadClick: ->
      @props.onZipOptionsResolved({file: @props.fileOptions.file, expandZip: false})

    buildMessage: (fileOptions) ->
      message = undefined
      if @props.fileOptions
        name = @props.fileOptions.file.name
        message = I18n.t('message', 'Would you like to expand the contents of "%{fileName}" into the current folder, or upload the zip file as is?', {fileName: name})
      message

    render: withReactElement ->

      DialogAdapter open: @props.fileOptions?, title: I18n.t('zip_options', 'Zip file options'), onClose: @props.onClose,
        DialogContent {},
          div {},
            p {}, @buildMessage()
        DialogButtons {},
          div {},
            button
              className: 'btn'
              onClick: @handleExpandClick,
                I18n.t('expand', 'Expand It')
            button
              className: 'btn btn-primary'
              onClick: @handleUploadClick,
                I18n.t('upload', 'Upload It')
