define [
  'i18n!react_files'
  'jquery'
  'react'
  'compiled/fn/preventDefault'
  '../modules/customPropTypes'
  '../utils/moveStuff'
], (I18n, $, React, preventDefault,  customPropTypes, moveStuff) ->

  MoveDialog =
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