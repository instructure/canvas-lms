define [
  'i18n!react_files'
  'jquery'
  '../components/FileRenameForm'
  'old_unsupported_dont_use_react'
  '../modules/FileOptionsCollection'
], (I18n, $, FileRenameForm, React, FileOptionsCollection) ->

  moveItem = (item, destinationFolder, options = {}) ->
    dfd = $.Deferred()
    item.moveTo(destinationFolder, options).then(
      # success
      (data) => dfd.resolve(data)
      # failure
      (jqXHR, textStatus, errorThrown) =>
        if jqXHR.status == 409
          # file already exists: prompt and retry
          React.renderComponent(FileRenameForm(
            closeOnResolve: true
            fileOptions: {name: item.attributes.display_name}
            onNameConflictResolved: (options) =>
              moveItem(item, destinationFolder, options).then(
                (data) => dfd.resolve(data)
                => dfd.reject()
              )
          ), $('<div>').appendTo('body')[0])
        else
          # some other error: fail
          dfd.reject()
    )
    dfd


  moveStuff = (filesAndFolders, destinationFolder) ->
    promises = filesAndFolders.map (item) => moveItem(item, destinationFolder)
    $.when(promises...).then =>
      $.flashMessage(I18n.t('move_success', {
        one: "%{item} moved to %{destinationFolder}",
        other: "%{count} items moved to %{destinationFolder}"
      }, {
        count: filesAndFolders.length
        item: filesAndFolders[0]?.displayName()
        destinationFolder: destinationFolder.displayName()
      }))