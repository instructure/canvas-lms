define [
  'compiled/react_files/modules/FileUploader'
  'jquery'
  'jquery.ajaxJSON'
], (FileUploader, $) ->

  module 'FileUploader',
    setup: ->
      folder = {id: 1}
      fileOptions =
        file:
          size: 1
          name: 'foo'
          type: 'bar'
      @uploader = new FileUploader(fileOptions, folder)

    teardown: ->
      delete @uploader


  test 'posts to the files endpoint to kick off upload', ->
    sinon.stub($, 'ajaxJSON')

    @uploader.upload()
    equal($.ajaxJSON.calledWith('/api/v1/folders/1/files'), true, 'kicks off upload')

    $.ajaxJSON.restore()


  test 'uploads file with data returned from files endpoint', ->
    server = sinon.fakeServer.create()
    server.respondWith('POST',
                       '/api/v1/folders/1/files',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{"upload_url": "/upload/url", "upload_params": [{"key": "value"}] }'
                       ]
    )

    uploadStub = sinon.stub(@uploader, '_actualUpload')
    @uploader.upload()
    server.respond()
    ok uploadStub.calledWithMatch({upload_url: '/upload/url', upload_params: [{key: 'value'}]})

    server.restore()
