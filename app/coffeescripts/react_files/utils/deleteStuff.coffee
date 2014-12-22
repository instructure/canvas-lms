define [
  'i18n!react_files'
  'jquery'
], (I18n, $) ->

  deleteStuff = (filesAndFolders) ->
    isDeletingAnUnemptyFolder = filesAndFolders.some (item) ->
      item.get('folders_count') or item.get('files_count')
    message = if isDeletingAnUnemptyFolder
      I18n.t('confirm_delete_with_contents', {
        one: "Are you sure you want to delete %{name}? It is not empty, anything inside it will be deleted too.",
        other: "Are you sure you want to delete these %{count} items and everything inside them?"
      }, {
        count: filesAndFolders.length
        name: filesAndFolders[0]?.displayName()
      })
    else
      I18n.t({
        one: "Are you sure you want to delete %{name}?",
        other: "Are you sure you want to delete these %{count} items?"
      }, {
        count: filesAndFolders.length
        name: filesAndFolders[0]?.displayName()
      })
    return unless confirm(message)

    promises = filesAndFolders.map (item) ->
      item.destroy
        emulateJSON: true
        data:
          force: 'true'
        wait: true
        error: (model, response, options) ->
          reason = try
            $.parseJSON(response.responseText)?.message

          $.flashError I18n.t 'Error deleting %{name}: %{reason}',
            name: item.displayName()
            reason: reason

    $.when(promises...).then ->
      $.flashMessage(I18n.t({
        one: '%{name} deleted successfully.'
        other: '%{count} items deleted successfully.'
      }, {
        count: filesAndFolders.length
        name: filesAndFolders[0]?.displayName()
      }))
