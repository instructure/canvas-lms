define [
  'react'
  'jquery'
  'jsx/files/CurrentUploads'
  'compiled/react_files/modules/FileUploader'
  'compiled/react_files/modules/UploadQueue'
], (React, $, CurrentUploads, FileUploader, UploadQueue) ->

  Simulate = React.addons.TestUtils.Simulate

  module 'CurrentUploads',
    setup: ->
      @uploads = React.render(CurrentUploads(), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      React.unmountComponentAtNode(@uploads.getDOMNode().parentNode)
      $("#fixtures").empty()

    mockUploader: (name, progress) ->
      uploader = new FileUploader({file: {}})
      @stub(uploader, 'getFileName').returns(name)
      @stub(uploader, 'roundProgress').returns(progress)
      uploader

  test 'announces upload progress to screen reader when queue changes', ->
    @stub($, 'screenReaderFlashMessage')
    uploader = @mockUploader('filename', 25)
    @stub(UploadQueue, 'getCurrentUploader').returns(uploader)

    UploadQueue.onChange()
    equal($.screenReaderFlashMessage.calledWith('filename - 25%'), true)

  test 'does not announces upload progress to screen reader if no uploader present', ->
    @stub($, 'screenReaderFlashMessage')
    uploader = @mockUploader('filename', 25)
    @stub(UploadQueue, 'getCurrentUploader').returns(null)

    UploadQueue.onChange()
    equal($.screenReaderFlashMessage.called, false)

  test 'pulls FileUploaders from UploadQueue', ->
    allUploads = [@mockUploader('name', 0), @mockUploader('other', 0)]
    @stub(UploadQueue, 'getAllUploaders').returns(allUploads)

    UploadQueue.onChange()
    equal @uploads.state.currentUploads, allUploads
