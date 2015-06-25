define [
  'underscore'
  'react'
  '../components/MoveDialog'
  '../modules/filesEnv'
  'jquery'
], (_, React, MoveDialogComponent, filesEnv, $) ->

  MoveDialog = React.createFactory MoveDialogComponent

  openMoveDialog = (thingsToMove, {contextType, contextId, returnFocusTo, clearSelectedItems}) ->

    rootFolderToShow = _.find filesEnv.rootFolders, (folder) ->
      (folder.get('context_type').toLowerCase() + 's' is contextType) and (''+folder.get('context_id') is ''+contextId)

    $moveDialog = $('<div>').appendTo(document.body)
    React.render(MoveDialog({
      thingsToMove: thingsToMove
      rootFoldersToShow: if filesEnv.showingAllContexts then filesEnv.rootFolders else [rootFolderToShow]
      onClose: ->
        React.unmountComponentAtNode this
        $moveDialog.remove()
        $(returnFocusTo).focus()
      onMove: clearSelectedItems
    }), $moveDialog[0])
