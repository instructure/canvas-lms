define [
  'react'
  'jquery'
  'jsx/files/UploadProgress'
  'compiled/react_files/modules/FileUploader'
], (React, $, UploadProgress, FileUploader) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'UploadProgress',
    setup: ->
      @uploader = @mockUploader('filename', 35)
      @prog = React.render(UploadProgress(uploader: @uploader), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@prog.getDOMNode().parentNode)
      $("#fixtures").empty()

    mockUploader: (name, progress) ->
      uploader = new FileUploader({file: {}})
      @stub(uploader, 'getFileName').returns(name)
      @stub(uploader, 'roundProgress').returns(progress)
      uploader

  test 'getLabel displays file name', ->
    equal(@prog.refs.fileName.getDOMNode().textContent, 'filename')
