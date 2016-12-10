define [
  'react'
  'react-dom'
  'jquery'
  'jsx/files/CurrentUploads'
  'compiled/react_files/modules/FileUploader'
  'compiled/react_files/modules/UploadQueue'
], (React, ReactDOM, $, CurrentUploads, FileUploader, UploadQueue) ->

  module 'CurrentUploads',
    setup: ->
      @uploads = ReactDOM.render(React.createElement(CurrentUploads), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@uploads.getDOMNode().parentNode)
      $("#fixtures").empty()

    mockUploader: (name, progress) ->
      uploader = new FileUploader({file: {}})
      @stub(uploader, 'getFileName').returns(name)
      @stub(uploader, 'roundProgress').returns(progress)
      uploader

  test 'pulls FileUploaders from UploadQueue', ->
    allUploads = [@mockUploader('name', 0), @mockUploader('other', 0)]
    @stub(UploadQueue, 'getAllUploaders').returns(allUploads)

    UploadQueue.onChange()
    equal @uploads.state.currentUploads, allUploads
