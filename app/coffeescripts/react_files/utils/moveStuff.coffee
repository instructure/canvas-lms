define [
  'i18n!react_files'
  'jquery'
], (I18n, $) ->

  moveStuff = (filesAndFolders, destinationFolder) ->
    promises = filesAndFolders.map (item) => item.moveTo(destinationFolder)
    $.when(promises...).then =>
      $.flashMessage(I18n.t('move_success', {
        one: "%{item} moved to %{destinationFolder}",
        other: "%{count} items moved to %{destinationFolder}"
      }, {
        count: filesAndFolders.length
        item: filesAndFolders[0]?.displayName()
        destinationFolder: destinationFolder.displayName()
      }))