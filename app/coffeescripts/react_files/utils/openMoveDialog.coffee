define [
  'underscore'
  'react'
  '../components/MoveDialog'
  '../modules/filesEnv'
  'jquery'
  'jqueryui/dialog'
], (_, React, MoveDialog, filesEnv, $) ->

  openMoveDialog = (thingsToMove, {contextType, contextId, returnFocusTo}) ->
    $dialog = $('<div>').dialog
      width: 600
      height: 300
      close: ->
        React.unmountComponentAtNode this
        $dialog.remove()
        $(returnFocusTo).focus()

    rootFolderToShow = _.find filesEnv.rootFolders, (folder) ->
      (folder.get('context_type').toLowerCase() + 's' is contextType) and (''+folder.get('context_id') is contextId)

    React.renderComponent(MoveDialog({
      thingsToMove: thingsToMove
      rootFoldersToShow: [rootFolderToShow]
      closeDialog: -> $dialog.dialog('close')
      setTitle: (title) -> $dialog.dialog('option', 'title', title)
    }), $dialog[0])
