define [
  'underscore'
  'react'
  'i18n!usage_rights_dialog'
  '../components/UsageRightsDialog'
  '../modules/filesEnv'
  'jquery'
  'jqueryui/dialog'
], (_, React, I18n, UsageRightsDialog, filesEnv, $) ->

  openUsageRightsDialog = (itemsToManage, {contextType, contextId, returnFocusTo}) ->
    $dialog = $('<div>').dialog
      width: 800
      height: 400
      title: I18n.t('Manage Usage Rights')
      close: ->
        React.unmountComponentAtNode this
        $dialog.remove()
        $(returnFocusTo).focus()


    React.renderComponent(UsageRightsDialog({
      closeDialog: -> $dialog.dialog('close')
      itemsToManage: itemsToManage
    }), $dialog[0])
