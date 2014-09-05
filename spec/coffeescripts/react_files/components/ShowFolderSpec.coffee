define [
  'react'
  'react-router'
  'compiled/react_files/components/ShowFolder'
  'compiled/models/Folder'
  'compiled/react_files/components/FolderChild'
], (React, Router, ShowFolder, Folder, FolderChild) ->

  showFolderTest = (properties, test) ->
    # Setup
    sinon.stub(Router, 'Link').returns('some link')
    sinon.stub(Folder, 'resolvePath').returns($.Deferred())
    @showFolder = React.renderComponent(ShowFolder(properties), $('#fixtures')[0])

    test()

  module 'ShowFolder Rendering',
    setup: ->
    teardown: ->
      Folder.resolvePath.restore()
      Router.Link.restore()
      React.unmountComponentAtNode($('#fixtures')[0])

  test 'returns empty div if there is no currentFolder', ->
    folderObject =
      params: {}
      onResolvePath: ->

    showFolderTest folderObject, ->
      ok @showFolder.refs.emptyDiv, "empty div displayed"

  test 'displays empty text if the folder is empty', ->
    folder = new Folder()
    folder.files.loadedAll = true
    folder.folders.loadedAll = true

    folderObject =
      params: {}
      onResolvePath: ->
      currentFolder: folder
      query: ''

    showFolderTest folderObject, ->
      equal @showFolder.refs.folderEmpty.getDOMNode().textContent, 'This folder is empty', 'displays the empty message'

  test 'when folder are present, FolderChild generates a line item', ->
    # this test should stub out FolderChild and just see if it was passed the correct props but
    # I can't figure out how to do that. This is the next best thing
    folder = new Folder()
    folder.children = -> [new Folder(cid: '1')]
    folderObject =
      params: {}
      onResolvePath: ->
      currentFolder: folder
      query: ''
      toggleItemSelected: ->
      selectedItems: []

    showFolderTest folderObject, ->
      ok $('.ef-item-row').length, 'generates an item row'

  module 'ShowFolder#registerListeners',
    setup: ->
    teardown: ->
      Folder.resolvePath.restore()
      Router.Link.restore()
      React.unmountComponentAtNode($('#fixtures')[0])
  
  test 'does nothing if there is no currentFolder', ->
    mockProps = sinon.mock()
    folder = new Folder()
    folder.children = -> [new Folder(cid: '1')]
    folderObject =
      params: {}
      onResolvePath: ->
      currentFolder: folder
      query: ''
      toggleItemSelected: ->
      selectedItems: []

    showFolderTest folderObject, ->
      @showFolder.registerListeners(mockProps)
      ok mockProps.never(), "doesn't call methods in the mock"

  test 'applies change handlers to folder when currentFolder exists', ->
    folder = new Folder()
    sinon.spy(folder, 'on')
    mockProps = {currentFolder: {folders: folder, files: folder}}

    folder.children = -> [new Folder(cid: '1')]
    folderObject =
      params: {}
      onResolvePath: ->
      currentFolder: folder
      query: ''
      toggleItemSelected: ->
      selectedItems: []

    showFolderTest folderObject, ->
      @showFolder.registerListeners(mockProps)
      ok folder.on.calledTwice, 'Calls "on" twice'
    folder.on.restore()
