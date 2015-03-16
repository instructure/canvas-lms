define [
  'old_unsupported_dont_use_react'
  'jquery'
  'compiled/react_files/components/CurrentUploads'
  'compiled/react_files/modules/FileUploader'
  'compiled/react_files/modules/UploadQueue'
], (React, $, CurrentUploads, FileUploader, UploadQueue) ->

  Simulate = React.addons.TestUtils.Simulate

  mockUploader = (name, progress) ->
    uploader = new FileUploader({file: {}})
    sinon.stub(uploader, 'getFileName').returns(name)
    sinon.stub(uploader, 'roundProgress').returns(progress)
    uploader

  resetUploader = (uploader) ->
    uploader.getFileName.restore()
    uploader.roundProgress.restore()

  module 'CurrentUploads',
    setup: ->
      @uploads = React.renderComponent(CurrentUploads(), $('<div>').appendTo('body')[0])

    teardown: ->
      React.unmountComponentAtNode(@uploads.getDOMNode().parentNode)

  test 'announces upload progress to screen reader when queue changes', ->
    sinon.stub($, 'screenReaderFlashMessage')
    uploader = mockUploader('filename', 25)
    sinon.stub(UploadQueue, 'getCurrentUploader').returns(uploader)

    UploadQueue.onChange()
    equal($.screenReaderFlashMessage.calledWith('filename - 25%'), true)

    resetUploader(uploader)
    UploadQueue.getCurrentUploader.restore()
    $.screenReaderFlashMessage.restore()

  test 'does not announces upload progress to screen reader if no uploader present', ->
    sinon.stub($, 'screenReaderFlashMessage')
    uploader = mockUploader('filename', 25)
    sinon.stub(UploadQueue, 'getCurrentUploader').returns(null)

    UploadQueue.onChange()
    equal($.screenReaderFlashMessage.called, false)

    resetUploader(uploader)
    UploadQueue.getCurrentUploader.restore()
    $.screenReaderFlashMessage.restore()

  test 'pulls FileUploaders from UploadQueue', ->
    allUploads = [mockUploader('name', 0), mockUploader('other', 0)]
    sinon.stub(UploadQueue, 'getAllUploaders').returns(allUploads)
    UploadQueue.onChange()
    equal @uploads.state.currentUploads, allUploads
    UploadQueue.getAllUploaders.restore()
