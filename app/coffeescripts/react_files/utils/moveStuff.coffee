define [
  'i18n!react_files'
  'jquery'
  'jsx/files/FileRenameForm'
  'react'
  'react-dom'
  '../modules/FileOptionsCollection'
], (I18n, $, FileRenameForm, React, ReactDOM, FileOptionsCollection) ->

  moveItem = (item, destinationFolder, options = {}) ->
    dfd = $.Deferred()
    item.moveTo(destinationFolder, options).then(
      # success
      (data) => dfd.resolve(data)
      # failure
      (jqXHR, textStatus, errorThrown) =>
        if jqXHR.status == 409
          # file already exists: prompt and retry
          ReactDOM.render(React.createFactory(FileRenameForm)(
            onClose: ->
            closeWithX: -> dfd.reject()
            closeOnResolve: true
            fileOptions: {name: item.attributes.display_name}
            onNameConflictResolved: (opts) =>
              moveItem(item, destinationFolder, opts).then(
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
