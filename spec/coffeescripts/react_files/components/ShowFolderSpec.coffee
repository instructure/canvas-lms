define [
  'underscore'
  'old_unsupported_dont_use_react'
  'old_unsupported_dont_use_react-router'
  'compiled/react_files/components/ShowFolder'
  'compiled/models/Folder'
  'compiled/react_files/components/FolderChild'
  'compiled/react_files/routes'
], (_, React, Router, ShowFolder, Folder, FolderChild, routes) ->

  module 'ShowFolder',
    setup: ->
      @$container = $('<div>').appendTo(document.body)
      @renderedRoutes = React.renderComponent(routes, @$container[0])

    teardown: ->
      React.unmountComponentAtNode(@$container[0])


  asyncTest 'returns empty div if there is no currentFolder', ->
    expect(1)
    @renderedRoutes.dispatch '/courses/999/files', =>
      equal @$container.find('.ef-directory [role="grid"]').length, 0, "doesn't render the grid"
      start()


  # asyncTest 'displays empty text if the folder is empty', ->
  #   expect(1)
  #   folder = new Folder()
  #   folder.files.loadedAll = true
  #   folder.folders.loadedAll = true
  #   resolvePathPromise = $.Deferred()
  #   stubbedResolvePath = sinon.stub(Folder, 'resolvePath')
  #   stubbedResolvePath.withArgs('courses', '999', '').returns(resolvePathPromise)

  #   @renderedRoutes.dispatch '/courses/999/files', =>
  #     resolvePathPromise.then =>
  #       equal @$container.find('.ef-directory [role="grid"]').text(), 'This folder is empty'
  #       stubbedResolvePath.restore()
  #       start()
  #     resolvePathPromise.resolve([folder])


  # asyncTest 'when folder are present, FolderChild generates a line item', ->
  #   expect(1)
  #   folder = new Folder()
  #   folder.folders.add({})
  #   resolvePathPromise = $.Deferred()
  #   stubbedResolvePath = sinon.stub(Folder, 'resolvePath')
  #   stubbedResolvePath.withArgs('courses', '999', '').returns(resolvePathPromise)

  #   @renderedRoutes.dispatch '/courses/999/files', =>
  #     resolvePathPromise.then =>
  #       equal 1, @$container.find('.ef-item-row').length, 'generates an item row'
  #       stubbedResolvePath.restore()
  #       start()
  #     resolvePathPromise.resolve([folder])

  # asyncTest 'forces update if you update backbone model', ->
  #   expect(2)
  #   folder = new Folder()
  #   @makeComponent(currentFolder:folder)
  #   forceUpdateSpy = sinon.spy(@component, 'forceUpdate')
  #   folder.folders.trigger('some event')
  #   equal folder.folders._events.all[0].callback, @component.debouncedForceUpdate
  #   setTimeout ->
  #     ok forceUpdateSpy.calledOnce, 'eventually calls force update after some event was triggered on child collection'
  #     forceUpdateSpy.restore()
  #     start()

