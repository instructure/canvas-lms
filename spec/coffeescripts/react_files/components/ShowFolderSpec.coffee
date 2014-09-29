define [
  'underscore'
  'react'
  'react-router'
  'compiled/react_files/components/ShowFolder'
  'compiled/models/Folder'
  'compiled/react_files/components/FolderChild'
  'compiled/react_files/routes'
], (_, React, Router, ShowFolder, Folder, FolderChild, routes) ->

  module 'ShowFolder',
    setup: ->
      React.addons.TestUtils.renderIntoDocument(routes)
      @makeComponent = (props) =>
        props = _.extend({
          params: {}
          query: {}
          selectedItems: []
          onResolvePath: ->
          toggleItemSelected: ->
          toggleAllSelected: ->
          areAllItemsSelected: -> false
          dndOptions:
            onItemDragStart: ->
            onItemDragEnterOrOver: ->
            onItemDragLeaveOrEnd: ->
            onItemDrop: ->
        }, props)

        @component = React.renderComponent(ShowFolder(props), $('<div>').appendTo(document.body)[0])

    teardown: ->
      React.unmountComponentAtNode(@component.getDOMNode().parentNode)


  test 'returns empty div if there is no currentFolder', ->
    @makeComponent()
    ok @component.refs.emptyDiv, 'empty div displayed'

  test 'displays empty text if the folder is empty', ->
    folder = new Folder()
    folder.files.loadedAll = true
    folder.folders.loadedAll = true

    @makeComponent(currentFolder:folder)
    ok @component.refs.folderEmpty, 'displays the empty message'

  test 'when folder are present, FolderChild generates a line item', ->
    folder = new Folder()
    folder.folders.add({})

    @makeComponent(currentFolder:folder)
    ok $('.ef-item-row').length, 'generates an item row'

  asyncTest 'forces update if you update backbone model', ->
    expect(2)
    folder = new Folder()
    @makeComponent(currentFolder:folder)
    forceUpdateSpy = sinon.spy(@component, 'forceUpdate')
    folder.folders.trigger('some event')
    equal folder.folders._events.all[0].callback, @component.debouncedForceUpdate
    setTimeout ->
      ok forceUpdateSpy.calledOnce, 'eventually calls force update after some event was triggered on child collection'
      forceUpdateSpy.restore()
      start()

