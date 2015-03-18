define [
  'react'
  'react-router'
  'react-modal'
  'compiled/react_files/components/FilesApp'
  'compiled/react_files/modules/filesEnv'
  'compiled/react_files/components/FilePreview'
  'compiled/models/Folder'
  'compiled/models/File'
  'compiled/collections/FilesCollection'
  '../mockFilesENV'
  '../TestLocation'
  '../../helpers/stubRouterContext'
], (React, Router, Modal, FilesApp, filesEnv, FilePreviewComponent, Folder, File, FilesCollection, mockFilesENV, TestLocation, stubRouterContext) ->

  Simulate = React.addons.TestUtils.Simulate
  FilePreview = stubRouterContext FilePreviewComponent

  module 'File Preview Rendering',
    setup: ->
      # Initialize a few things to view in the preview.
      @filesCollection = new FilesCollection()
      @file1 = new File({
       id: '1'
       cid: 'c1'
       name:'Test File.file1'
       'content-type': 'unknown/unknown'
       size: 1000000
       created_at: +new Date()
       updated_at: +new Date()
       }, {preflightUrl: ''})
      @file2 = new File({
       id: '2'
       cid: 'c2'
       name:'Test File.file2'
       'content-type': 'unknown/unknown'
       size: 1000000
       created_at: +new Date()
       updated_at: +new Date()
       }, {preflightUrl: ''})
      @file3 = new File({
       id: '3'
       cid: 'c3'
       name:'Test File.file3'
       'content-type': 'image/png'
       'url': 'test/test/test.png'
       size: 1000000
       created_at: +new Date()
       updated_at: +new Date()
       }, {preflightUrl: ''})

      @filesCollection.add(@file1)
      @filesCollection.add(@file2)
      @filesCollection.add(@file3)
      @currentFolder = new Folder()
      @currentFolder.files = @filesCollection
      @div = $('<div>').appendTo('body')[0]

      Modal.setAppElement(@div)

      properties =
        currentFolder: @currentFolder
        collection: @filesCollection
        query: {}
        params:
          splat: '/courses/1/files'

      location = (path = '/courses/1/files?preview=2') ->
        new TestLocation([ path ])

      routes = [
        Router.Route path: filesEnv.baseUrl, handler: FilePreviewComponent, name: 'rootFolder'
      ]

      @runRouter = () ->
        if arguments.length > 1
          path = arguments[0]
          callback = arguments[1]
        else
          callback = arguments[0]

        Router.run routes, location(path), (Handler) =>
          React.render Handler(properties), @div, ->
            callback.call(null)



     teardown: ->
       React.unmountComponentAtNode(@div)



  test 'clicking the info button should render out the info panel', ->
    @runRouter ->
      $('.ef-file-preview-header-info').click()
      ok $('.ef-file-preview-information-container').length, 'The info panel did not show'

  test 'clicking the info button after the panel has been opened should hide the info panel', ->
    @runRouter ->
      $('.ef-file-preview-header-info').click()
      ok $('.ef-file-preview-information-container').length, 'The info panel did not show'
      $('.ef-file-preview-header-info').click()
      ok !$('.ef-file-preview-information-container').length, 'The info panel did not close'

  test 'opening the preview for one file should show navigation buttons for the previous and next files in the current folder', ->
    @runRouter ->
      ok $('.icon-arrow-open-left').length, 'The left arrow link was not shown'
      ok $('.icon-arrow-open-left').closest('a').attr('href').match("preview=1"), 'The left arrow link has an incorrect href (`preview` query string does not exist or points to the wrong id)'
      ok $('.icon-arrow-open-right').length, 'The right arrow link was not shown'
      ok $('.icon-arrow-open-right').closest('a').attr('href').match("preview=3"), 'The right arrow link has an incorrect href (`preview` query string does not exist or points to the wrong id)'

  test 'download button should be rendered on the file preview', ->
    @runRouter '/courses/1/files?preview=3',  =>
      ok $('.ef-file-preview-header-download').length, 'The download button was not shown'
      ok $('.ef-file-preview-header-download').attr('href').match(@file3.get('url')), 'The download button url is incorrect'
