define [
  'i18n!zip_file_options_form'
  'react'
  'compiled/react/shared/utils/withReactElement'
  'jsx/shared/modal'
  'jsx/shared/modal-content'
  'jsx/shared/modal-buttons'
], (I18n, React, withReactElement, Modal, ModalContent, ModalButtons) ->
  Modal = React.createFactory(Modal)

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

      Modal
        className: 'ReactModal__Content--canvas ReactModal__Content--mini-modal',
        isOpen: @props.fileOptions?,
        ref: 'canvasModal',
        title: I18n.t('zip_options', 'Zip file options'),
        onRequestClose: @props.onClose,
          ModalContent {},
            p {className: "modalMessage"}, @buildMessage()
          ModalButtons {},
            button
              className: 'btn'
              onClick: @handleExpandClick,
                I18n.t('expand', 'Expand It')
            button
              className: 'btn btn-primary'
              onClick: @handleUploadClick,
                I18n.t('upload', 'Upload It')
