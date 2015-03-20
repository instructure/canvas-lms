define [
  'react'
  'react-router'
  'react-modal'
  'compiled/react_files/components/FilePreview'
  'compiled/models/Folder'
  'compiled/models/File'
  'compiled/collections/FilesCollection'
  'compiled/react_files/components/FolderChild'
], (React, Router, Modal, FilePreview, Folder, File, FilesCollection, FolderChild) ->

  Simulate = React.addons.TestUtils.Simulate

  # TODO: These tests should be re-implemented after we have figured out testing with react-router

  # module 'File Preview Rendering',
  #   setup: ->

  #     #window.React = React

  #     sinon.stub(Router, 'Link').returns('some link')
  #     sinon.stub(Folder, 'resolvePath').returns($.Deferred())



  #     # Initialize a few things to view in the preview.
  #     @filesCollection = new FilesCollection()
  #     @file1 = new File({
  #       id: '1'
  #       cid: 'c1'
  #       name:'Test File.file1'
  #       'content-type': 'unknown/unknown'
  #       }, {preflightUrl: ''})
  #     @file2 = new File({
  #       id: '2'
  #       cid: 'c2'
  #       name:'Test File.file2'
  #       'content-type': 'unknown/unknown'
  #       }, {preflightUrl: ''})
  #     @file3 = new File({
  #       id: '3'
  #       cid: 'c3'
  #       name:'Test File.file3'
  #       'content-type': 'image/png',
  #       'url': 'test/test/test.png'
  #       }, {preflightUrl: ''})

  #     @filesCollection.add(@file1)
  #     @filesCollection.add(@file2)
  #     @filesCollection.add(@file3)
  #     @currentFolder = new Folder(files: @filesCollection)

  #     Modal.setAppElement($('#fixtures').get(0))

  #     properties =
  #       currentFolder: @currentFolder
  #       params: {splat: "test/test/test/"}
  #       appElement: $('#fixtures').get(0)
  #       query: {preview: "1"}


  #     @filePreview = React.renderComponent(FilePreview(properties), $('#fixtures')[0])


  #   teardown: ->
  #     Router.Link.restore()
  #     Folder.resolvePath.restore()
  #     React.unmountComponentAtNode($('#fixtures')[0])


  ########
  # TODO: Consider This - All of these tests are fairly pointless... do we need them?
  ########

  # test 'clicking the info button should render out the info panel', ->
  #   infoButton = $('.ef-file-preview-header-info').get(0)
  #   Simulate.click(infoButton)
  #   ok $('.ef-file-preview-information').length, 'The info panel did not show'

  # test 'clicking the Show button should render out the footer', ->
  #   showButton = $('.ef-file-preview-toggle').get(0)
  #   Simulate.click(showButton)
  #   ok $('.ef-file-preview-footer').length, 'The footer did not show'

  # test 'clicking the Show button should change the text to Hide', ->
  #   showButton = $('.ef-file-preview-toggle').get(0)
  #   Simulate.click(showButton)
  #   ok $('.ef-file-preview-toggle').text().trim() is "Hide", 'The button text did not become Hide'


  #####
  ## The next tests should be fixed once Simulate.keyDown is working properly.
  #####

  # test 'pressing the left arrow should navigate to the previous item', ->
  #   modal = $('.ReactModal__Overlay').get(0)
  #   Simulate.keyDown(modal, {keyCode: 37})
  #   expected = @file1.get 'name'
  #   actual = $('.ef-file-preview-header-filename').text()
  #   ok actual is expected, 'The previous item did not load'


  # test 'pressing the left arrow should navigate to the last item if you are at the beginning', ->
  #   ok false

  # test 'pressing the right arrow should navigate to the next item', ->
  #   ok false

  # test 'pressing the right arrow should navigate to the first item if you are at the end.', ->
  #   ok false

