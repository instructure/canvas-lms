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
      @prog = React.renderComponent(UploadProgress(uploader: @uploader), $('<div>').appendTo('body')[0])

    teardown: ->
      resetUploader(@uploader)
      React.unmountComponentAtNode(@prog.getDOMNode().parentNode)

  test 'getProgressWithLabel concats file name and progress', ->
    equal(@prog.getProgressWithLabel(), 'filename - 35%')

  test 'createWidthStyle returns object with correct percentage from progress', ->
    equal(@prog.createWidthStyle().width, '35%')

  test 'sets width on progress bar', ->
    equal @prog.refs.bar.getDOMNode().style.width, '35%'

  test 'shows indeterminate loader when progress is 100 but not yet complete', ->
    ul = mockUploader('filename', 100)
    prog = React.renderComponent(UploadProgress(uploader: ul), $('<div>').appendTo('body')[0])
    equal $(prog.getDOMNode()).find('.upload-progress-view__indeterminate').length, 1
    resetUploader(ul)
    React.unmountComponentAtNode(prog.getDOMNode().parentNode)

