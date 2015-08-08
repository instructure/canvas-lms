define [
  'i18n!react_files'
  'jquery'
  'react'
  'compiled/react/shared/utils/withReactElement'
  'compiled/fn/preventDefault'
  '../modules/customPropTypes'
  '../utils/moveStuff'
  'jsx/shared/modal'
  'jsx/shared/modal-content'
  'jsx/shared/modal-buttons'
  'jsx/files/BBTreeBrowser'
], (I18n, $, React, withReactElement, preventDefault,  customPropTypes, moveStuff, Modal, ModalContent, ModalButtons, BBTreeBrowser) ->

  Modal = React.createFactory(Modal)
  ModalContent = React.createFactory(ModalContent)
  ModalButtons = React.createFactory(ModalButtons)
  BBTreeBrowser = React.createFactory(BBTreeBrowser)

  MoveDialog = React.createClass
    displayName: 'MoveDialog'

    propTypes:
      rootFoldersToShow: React.PropTypes.arrayOf(customPropTypes.folder).isRequired
      thingsToMove: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
      onClose: React.PropTypes.func.isRequired
      onMove: React.PropTypes.func.isRequired

    getInitialState: ->
      destinationFolder: null
      isOpen: true

    contextsAreEqual: (destination = {}, sources = []) ->
      differentContexts = sources.filter (source) ->
        source.collection.parentFolder.get("context_type") is destination.get("context_type") and
        source.collection.parentFolder.get("context_id")?.toString() is destination.get("context_id")?.toString()

      !!differentContexts.length

    onSelectFolder: (event, folder) ->
      event.preventDefault()
      @setState(destinationFolder: folder, isCopyingFile: !@contextsAreEqual(folder, @props.thingsToMove))

    submit: () ->
      promise = moveStuff(@props.thingsToMove, @state.destinationFolder)
      promise.then =>
        @props.onMove()
        @closeDialog()

    closeDialog: ->
      @props.onClose()
      @setState isOpen: false

    getTitle: ->
      I18n.t('move_question', {
        one: "Where would you like to move %{item}?",
        other: "Where would you like to move these %{count} items?"
      },{
        count: @props.thingsToMove.length
        item: @props.thingsToMove[0]?.displayName()
      })

    render: withReactElement ->

      Modal {
        className: 'ReactModal__Content--canvas ReactModal__Content--mini-modal',
        ref: 'canvasModal',
        isOpen: @state.isOpen,
        title: @getTitle(),
        onRequestClose: @closeDialog,
        onSubmit: @submit
      },
        ModalContent {},
          BBTreeBrowser {
            rootFoldersToShow: @props.rootFoldersToShow
            onSelectFolder: @onSelectFolder
          }
        ModalButtons {},
          button {
            type: 'button'
            className: 'btn'
            onClick: @closeDialog
          }, I18n.t('cancel', 'Cancel')
          if @state.isCopyingFile
            button {
              type: 'submit'
              disabled: !@state.destinationFolder
              className: 'btn btn-primary'
              'data-text-while-loading': I18n.t('Copying...')
            }, I18n.t('Copy to Folder')
          else
            button {
              type: 'submit'
              disabled: !@state.destinationFolder
              className: 'btn btn-primary'
              'data-text-while-loading': I18n.t('Moving...')
            }, I18n.t('Move')
