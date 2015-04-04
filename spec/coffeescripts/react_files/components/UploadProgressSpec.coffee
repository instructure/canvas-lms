define [
  'react'
  'jquery'
  'compiled/react_files/components/UploadProgress'
  'compiled/react_files/modules/FileUploader'
], (React, $, UploadProgress, FileUploader) ->

  Simulate = React.addons.TestUtils.Simulate

  mockUploader = (name, progress) ->
    uploader = new FileUploader({file: {}})
    sinon.stub(uploader, 'getFileName').returns(name)
    sinon.stub(uploader, 'roundProgress').returns(progress)
    uploader

  resetUploader = (uploader) ->
    uploader.getFileName.restore()
    uploader.roundProgress.restore()

  module 'UploadProgress',
    setup: ->
      @uploader = mockUploader('filename', 35)
      @prog = React.render(UploadProgress(uploader: @uploader), $('<div>').appendTo('body')[0])

    teardown: ->
      resetUploader(@uploader)
      React.unmountComponentAtNode(@prog.getDOMNode().parentNode)

  test 'getLabel displays file name', ->
    equal(@prog.refs.fileName.getDOMNode().textContent, 'filename')
