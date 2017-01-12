define [
  'i18n!react_files'
  'jquery'
  'react'
  'compiled/fn/preventDefault'
  '../modules/customPropTypes'
  '../utils/moveStuff'
  'compiled/str/splitAssetString'
], (I18n, $, React, preventDefault,  customPropTypes, moveStuff, splitAssetString) ->

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
      contextsAreEqual = sources.filter (source) ->
        [contextType, contextId] = if assetString = source.get("context_asset_string")
                                     splitAssetString(assetString, false)
                                   else
                                     [(source.collection?.parentFolder?.get("context_type") || source.get("context_type")), (source.collection?.parentFolder?.get("context_id")?.toString() || source.get("context_id").toString())]

        contextType.toLowerCase() is destination.get("context_type").toLowerCase() and
        contextId is destination.get("context_id")?.toString()

      !!contextsAreEqual.length

    onSelectFolder: (event, folder) ->
      event.preventDefault()
      if folder.get('for_submissions')
        @setState(destinationFolder: null)
      else
        @setState(destinationFolder: folder, isCopyingFile: !@contextsAreEqual(folder, @props.thingsToMove))

    submit: () ->
      modelsBeingMoved = @props.thingsToMove
      promise = moveStuff(modelsBeingMoved, @state.destinationFolder)
      promise.then =>
        @props.onMove(modelsBeingMoved)
        @closeDialog()

    closeDialog: ->
      @setState(isOpen: false, ->
        @props.onClose()
      )

    getTitle: ->
      I18n.t('move_question', {
        one: "Where would you like to move %{item}?",
        other: "Where would you like to move these %{count} items?"
      },{
        count: @props.thingsToMove.length
        item: @props.thingsToMove[0]?.displayName()
      })