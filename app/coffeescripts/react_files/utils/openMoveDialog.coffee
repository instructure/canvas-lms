define [
  'react'
  '../components/MoveDialog'
  'jquery'
  'jqueryui/dialog'
], (React, MoveDialog, $) ->

  openMoveDialog = (thingsToMove) ->
    $dialog = $('<div>').dialog
      width: 600
      height: 300
      close: ->
        React.unmountComponentAtNode this
        $dialog.remove()

    React.renderComponent(MoveDialog({
      thingsToMove: thingsToMove
      closeDialog: -> $dialog.dialog('close')
      setTitle: (title) -> $dialog.dialog('option', 'title', title)
    }), $dialog[0])

    $dialog.find(':tabbable:first').focus()

